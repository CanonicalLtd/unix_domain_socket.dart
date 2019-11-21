import 'package:unix_domain_socket/unix_domain_socket.dart';

import "dart:convert";

void main()
{
  var socket = UnixDomainSocket.create("/run/cups/cups.sock");

  var request = Utf8Encoder().convert("GET / HTTP/1.1\r\nHost: 127.0.0.1:631\r\nConnection: close\r\n\r\n");
  var n_written = socket.write(request);
  print("wrote $n_written");

  var response = socket.read(1024);
  var text = Utf8Decoder().convert(response);
  print("read $text");
}
