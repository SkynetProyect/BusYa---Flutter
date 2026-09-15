import 'package:flutter_application_1/service/StreamingService.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;
  final _streaming = StreamingService.getInstance();

  void connect() {
    socket = IO.io(
      'http://localhost:5000', // use 10.0.2.2 on Android emulator, localhost on web/desktop
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket.onConnect((_) {
      print('connected: ${socket.id}');
    });

    socket.onDisconnect((_) => print('disconnected'));

    socket.on('server_message', (data) {
      _streaming.agregar(data);
    });

    socket.connect();
  }

  void dispose() {
    _streaming.cerrar();
    socket.disconnect();
  }

  void disconnect() => socket.disconnect();
}
