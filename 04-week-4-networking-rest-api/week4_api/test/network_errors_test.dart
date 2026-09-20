import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/network_errors.dart';

void main() {
  group('friendlyErrorMessage Test', () {
    test('memetakan connectionTimeout dengan benar', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/posts'),
        type: DioExceptionType.connectionTimeout,
      );

      final message = friendlyErrorMessage(dioError);

      expect(
        message,
        contains('Koneksi lambat atau timeout'),
      );
    });

    test('memetakan connectionError dengan benar', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/posts'),
        type: DioExceptionType.connectionError,
      );

      final message = friendlyErrorMessage(dioError);

      expect(
        message,
        contains('Tidak dapat terhubung ke server'),
      );
    });

    test('memetakan HTTP 404 Bad Response dengan benar', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/posts'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/posts'),
          statusCode: 404,
        ),
      );

      final message = friendlyErrorMessage(dioError);

      expect(
        message,
        contains('Data tidak ditemukan (404)'),
      );
    });

    test('memetakan HTTP 401 / 403 Akses Ditolak dengan benar', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/posts'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/posts'),
          statusCode: 401,
        ),
      );

      final message = friendlyErrorMessage(dioError);

      expect(
        message,
        contains('Akses ditolak (401)'),
      );
    });

    test('memetakan HTTP 500 Server Error dengan benar', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/posts'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/posts'),
          statusCode: 500,
        ),
      );

      final message = friendlyErrorMessage(dioError);

      expect(
        message,
        contains('Server bermasalah (500)'),
      );
    });

    test('memetakan error non-DioException dengan benar', () {
      final genericError = Exception('Error manual dari sistem');

      final message = friendlyErrorMessage(genericError);

      expect(
        message,
        contains('Terjadi kesalahan tak terduga'),
      );
    });
  });
}