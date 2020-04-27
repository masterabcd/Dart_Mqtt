import 'dart:async';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class myMqtt {
  String server;
  int port;
  String clientIdentifier;
  // String subTopic = '/a1kst7zcrDS/app_/user/s_data';
  // String publishTopic = '/a1kst7zcrDS/app_/user/p_data';
  MqttQos qos = MqttQos.atMostOnce;

  MqttServerClient client;

  myMqtt(this.server, this.clientIdentifier, this.port) {
    client = MqttServerClient.withPort(server, clientIdentifier, port);

    client.keepAlivePeriod = 80;

    client.onDisconnected = _onDisconnected;

    client.onConnected = _onConnected;

    client.onSubscribed = _onSubscribed;

    client.pongCallback = _pong;
  }

  mqttConnect(String username, String password, String subtopic) async {
    try {
      //连接
      await client.connect(username, password);
//判断连接状态
      if (client.connectionStatus.state == MqttConnectionState.connected) {
        print('=>client connected');
        print('=>Subscribing to the topic');
        client.subscribe(subtopic, MqttQos.atMostOnce);
      } else {
        /// Use status here rather than state if you also want the broker return code.
        print(
            '--connection failed - disconnecting, status is ${client.connectionStatus}');
        client.disconnect();
        exit(-1);
      }
    } on Exception catch (e) {
      print('--client exception - $e');
      client.disconnect();
    }
  }

  // If needed you can listen for published messages that have completed the publishing
  // handshake which is Qos dependant. Any message received on this stream has completed its
  // publishing handshake with the broker.

  // client.published.listen((MqttPublishMessage message) {
  //   print(
  //       'Published--topic:${message.variableHeader.topicName},Qos:${message.header.qos}');
  // });

  mqttPub(String publishTopic, String pubdata) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(pubdata);
    client.publishMessage(publishTopic, MqttQos.exactlyOnce, builder.payload);
  }

  /// Ok, we will now sleep a while, in this gap you will see ping request/response
  /// messages being exchanged by the keep alive mechanism.
  // print('=>Sleeping....');
  // await MqttUtilities.asyncSleep(120);

  // /// Finally, unsubscribe and exit gracefully
  // print('Unsubscribing');
  // client.unsubscribe(topic);

  // /// Wait for the unsubscribe message from the broker if you wish.
  // await MqttUtilities.asyncSleep(2);
  // print('Disconnecting');
  // client.disconnect();

  /// The subscribed callback
  void _onSubscribed(String topic) {
    print('=>Sucess Subscription topic $topic');
    client.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage recMess = c[0].payload;
      final pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      /// The above may seem a little convoluted for users only interested in the
      /// payload, some users however may be interested in the received publish message,
      /// lets not constrain ourselves yet until the package has been in the wild
      /// for a while.
      /// The payload is a byte buffer, this will be specific to the topic
      print('=>RE--topic is <${c[0].topic}>, payload is <-- $pt -->');
      print('');
    });
  }

  /// The unsolicited disconnect callback
  void _onDisconnected() {
    print('Client disconnection');
    if (client.connectionStatus.returnCode == MqttConnectReturnCode.solicited) {
      print('EXAMPLE::OnDisconnected callback is solicited, this is correct');
    }
    exit(-1);
  }

  _onConnected() {
    print('=>connection was sucessful');
  }

  void _pong() {
    print('=>Ping response');
  }
}
