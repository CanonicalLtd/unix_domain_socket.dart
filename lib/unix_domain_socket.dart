library unix_domain_socket;

import "dart:convert";
import "dart:io";
import "dart:typed_data";
import 'dart:ffi';
import 'package:ffi/ffi.dart';

typedef _CreateC = Int32 Function();
typedef _CreateDart = int Function();
typedef _ConnectC = Int32 Function(Int32 fd, Pointer<Utf8> path);
typedef _ConnectDart = int Function(int fd, Pointer<Utf8> path);
typedef _WriteC = Int32 Function(Int32 fd, Pointer<Uint8> data, Int32 data_length);
typedef _WriteDart = int Function(int fd, Pointer<Uint8> data, int data_length);
typedef _ReadC = Int32 Function(Int32 fd, Pointer<Uint8> data, Int32 data_length);
typedef _ReadDart = int Function(int fd, Pointer<Uint8> data, int data_length);
typedef _SendCredentialsC = Int32 Function(Int32 fd);
typedef _SendCredentialsDart = int Function(int fd);
typedef _CloseC = Int32 Function(Int32 fd);
typedef _CloseDart = int Function(int fd);
typedef _GetErrorC = Int32 Function();
typedef _GetErrorDart = int Function();
typedef _StrerrorC = Pointer<Utf8> Function(Int32 errnum);
typedef _StrerrorDart = Pointer<Utf8> Function(int errnum);

class UnixDomainSocket {
  int _fd = -1;

  static UnixDomainSocket create(String path) {
    var socket = UnixDomainSocket();

    final dylib = DynamicLibrary.open('libunixdomainsocket.so');

    final createP = dylib.lookupFunction<_CreateC, _CreateDart>('UnixDomainSocket_Create');
    socket._fd = createP();

    final connectP = dylib.lookupFunction<_ConnectC, _ConnectDart>('UnixDomainSocket_Connect');
    final pathP = Utf8.toUtf8(path);
    connectP(socket._fd, pathP);

    return socket;
  }

  int write(List<int> buffer) {
    final dylib = DynamicLibrary.open('libc.so.6');
    final writeP = dylib.lookupFunction<_WriteC, _WriteDart>('write');
    final bufferP = allocate<Uint8>(count: buffer.length);
    for (int i = 0; i < buffer.length; i++)
      bufferP[i] = buffer[i];
    int result = writeP(_fd, bufferP, buffer.length);
    free(bufferP);
    return result;
  }

  List<int> read(int len) {
    final dylib = DynamicLibrary.open('libc.so.6');
    final readP = dylib.lookupFunction<_ReadC, _ReadDart>('read');
    final bufferP = allocate<Uint8>(count: len);
    int readCount = readP(_fd, bufferP, len);
    if (readCount < 0) {
      var error_text = _strerror(_errno());
      print("Failed to read from socket: ${error_text}");
      free(bufferP);
      return new List(0);
    }

    List<int> result = new List(readCount);
    for (int i = 0; i < readCount; i++)
      result[i] = bufferP[i];
    free(bufferP);
    return result;
  }

  int sendCredentials() {
    final dylib = DynamicLibrary.open('libunixdomainsocket.so');
    final sendCredentialsP = dylib.lookupFunction<_SendCredentialsC, _SendCredentialsDart>('UnixDomainSocket_SendCredentials');
    return sendCredentialsP(_fd);
  }

  close() {
    final dylib = DynamicLibrary.open('libc.so.6');
    final closeP = dylib.lookupFunction<_CloseC, _CloseDart>('close');
    closeP(_fd);
  }

  int _errno() {
    final dylib = DynamicLibrary.open('libunixdomainsocket.so');
    final getErrorP = dylib.lookupFunction<_GetErrorC, _GetErrorDart>('UnixDomainSocket_GetError');
    return getErrorP();
  }

  String _strerror(int errnum){
    final dylib = DynamicLibrary.open('libc.so.6');
    final strerrorP = dylib.lookupFunction<_StrerrorC, _StrerrorDart>('strerror');
    var errorString = strerrorP(errnum);
    return Utf8.fromUtf8(errorString);
  }
}
