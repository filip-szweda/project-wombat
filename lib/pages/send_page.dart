import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class SendPage extends StatelessWidget {
  SendPage({super.key});

  static const String routeName = '/send';

  final TextEditingController _controller = TextEditingController();
  final _channel = WebSocketChannel.connect(
    Uri.parse('wss://echo.websocket.events'),
  );

  //TcpConnection tcpConnection;

  @override
  Widget build(BuildContext context) {
    //tcpConnection = ModalRoute.of(context)!.settings.arguments as TcpConnection;
    return Scaffold(
      appBar: AppBar(
        title: Text("Send Messages"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ReceiveMessagesWidget(),
            SendMessagesWidget(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _sendMessage,
        tooltip: 'Send message',
        child: const Icon(Icons.send),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      _channel.sink.add(_controller.text);
    }
  }

  void dispose() {
    _channel.sink.close();
    _controller.dispose();
  }
}

class ReceiveMessagesWidget extends StatefulWidget {
  const ReceiveMessagesWidget({Key? key}) : super(key: key);

  @override
  State<ReceiveMessagesWidget> createState() => _ReceiveMessagesWidgetState();
}

class _ReceiveMessagesWidgetState extends State<ReceiveMessagesWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Form(
          child: TextFormField(
            decoration: const InputDecoration(labelText: 'Send a message'),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class SendMessagesWidget extends StatelessWidget {
  const SendMessagesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Flexible(
          flex: 6,
          child: TextField(
            keyboardType: TextInputType.multiline,
            minLines: 8,
            maxLines: 8,
            decoration: const InputDecoration(
              alignLabelWithHint: true,
              labelText: 'Type a message',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Flexible(
          flex: 1,
          child: SizedBox(),
        ),
        Flexible(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () {},
                child: Text("Send"),
              ),
              SizedBox(
                height: 10,
              ),
              ElevatedButton(
                onPressed: () {},
                child: Text("Send file"),
              )
            ],
          ),
        )
      ],
    );
  }
}
