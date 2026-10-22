import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:work_flow/core/auth/session_manager.dart';
import 'package:work_flow/core/auth/token_store.dart';
import 'package:work_flow/core/outbox/outbox_processor.dart';

class MockDio extends Mock implements Dio {}

class MemoryTokens implements TokenStore {
  SessionTokens? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<SessionTokens?> read() async => value;

  @override
  Future<void> write(SessionTokens tokens) async => value = tokens;
}

Response<dynamic> res(String path, int status, [dynamic data]) =>
    Response(requestOptions: RequestOptions(path: path), statusCode: status, data: data);

DioException http(String path, int? status) => DioException(
      requestOptions: RequestOptions(path: path),
      response: status == null ? null : res(path, status, {'message': 'x'}),
      type: status == null ? DioExceptionType.connectionError : DioExceptionType.badResponse,
    );

void main() {
  late MockDio dio;
  late MemoryTokens tokens;
  late DateTime now;
  late SessionManager session;

  setUp(() {
    dio = MockDio();
    tokens = MemoryTokens();
    now = DateTime.utc(2026, 10, 22, 12);
    session = SessionManager(authDio: dio, tokens: tokens, clock: () => now);
  });

  void refreshReturns(String access, String refresh) {
    when(() => dio.post<dynamic>('/auth/refresh', data: any(named: 'data'))).thenAnswer(
      (_) async => res('/auth/refresh', 200, {
        'data': {'accessToken': access, 'refreshToken': refresh, 'expiresIn': 900},
      }),
    );
  }

  test('login de campo guarda el par de tokens', () async {
    when(() => dio.post<dynamic>('/auth/login', data: any(named: 'data'), options: any(named: 'options')))
        .thenAnswer((_) async => res('/auth/login', 200, {
              'data': {
                'accessToken': 'a1',
                'refreshToken': 'r1',
                'expiresIn': 900,
                'memberships': [
                  {'tenantId': 't1', 'tenantName': 'Arq&Top'},
                ],
              },
            }));

    final m = await session.loginField(cuit: '30123456789', documentNumber: '30111222', pin: '1234');

    expect(m.single.tenantName, 'Arq&Top');
    expect(tokens.value!.refreshToken, 'r1');
    expect(tokens.value!.accessExpiresAt, now.add(const Duration(minutes: 15)));
  });

  test('access vigente: no refresca', () async {
    tokens.value = SessionTokens(accessToken: 'a', refreshToken: 'r', accessExpiresAt: now.add(const Duration(minutes: 10)));
    expect(await session.ensureFresh(), RefreshOutcome.ok);
    verifyNever(() => dio.post<dynamic>(any(), data: any(named: 'data')));
  });

  test('access por vencer: refresca y guarda el refresh rotado', () async {
    tokens.value = SessionTokens(accessToken: 'a', refreshToken: 'r1', accessExpiresAt: now.add(const Duration(seconds: 30)));
    refreshReturns('a2', 'r2');

    expect(await session.ensureFresh(), RefreshOutcome.ok);
    expect(tokens.value!.accessToken, 'a2');
    expect(tokens.value!.refreshToken, 'r2');
  });

  test('refrescos simultáneos usan una sola llamada (el refresh rota)', () async {
    tokens.value = SessionTokens(accessToken: 'a', refreshToken: 'r1', accessExpiresAt: now);
    refreshReturns('a2', 'r2');

    final r = await Future.wait([session.forceRefresh(), session.forceRefresh(), session.ensureFresh()]);

    expect(r, everyElement(RefreshOutcome.ok));
    verify(() => dio.post<dynamic>('/auth/refresh', data: {'refreshToken': 'r1'})).called(1);
  });

  test('sin señal la sesión NO se cierra (RN-28)', () async {
    tokens.value = SessionTokens(accessToken: 'a', refreshToken: 'r1', accessExpiresAt: now);
    when(() => dio.post<dynamic>('/auth/refresh', data: any(named: 'data'))).thenThrow(http('/auth/refresh', null));

    expect(await session.forceRefresh(), RefreshOutcome.offline);
    expect(tokens.value, isNotNull);
  });

  test('API caída (5xx) tampoco cierra la sesión', () async {
    tokens.value = SessionTokens(accessToken: 'a', refreshToken: 'r1', accessExpiresAt: now);
    when(() => dio.post<dynamic>('/auth/refresh', data: any(named: 'data'))).thenThrow(http('/auth/refresh', 503));

    expect(await session.forceRefresh(), RefreshOutcome.offline);
    expect(tokens.value, isNotNull);
  });

  test('refresh rechazado (401): sesión vencida y aviso', () async {
    tokens.value = SessionTokens(accessToken: 'a', refreshToken: 'viejo', accessExpiresAt: now);
    when(() => dio.post<dynamic>('/auth/refresh', data: any(named: 'data'))).thenThrow(http('/auth/refresh', 401));
    final expired = expectLater(session.onExpired, emits(null));

    expect(await session.forceRefresh(), RefreshOutcome.expired);
    expect(tokens.value, isNull);
    await expired;
  });
}
