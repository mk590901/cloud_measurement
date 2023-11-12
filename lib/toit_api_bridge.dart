import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';
import 'package:toit_api/toit/api/auth.pbgrpc.dart'
    show AuthClient, LoginRequest;
import 'package:toit_api/toit/api/pubsub/publish.pbgrpc.dart'
    show PublishClient, PublishRequest;
import 'package:toit_api/toit/api/pubsub/subscribe.pbgrpc.dart';
import 'igui_adapter.dart';

class ToitBridge {
  var token_;
  var channel_;
  var subscribeStub_;
  var mainTopicInpName_;
  var options_;
  var mainTopicInp_;
  var mainTopicOutName_;
  var mainTopicOut_;
  var existingSubscriptions_;
  var inpSubscription_;
  var publishStub_;
  var fetchFuture_;
  var before;
  IGUIAdapter guiAdapter_;

  ToitBridge(this.guiAdapter_, this.mainTopicInpName_, this.mainTopicInp_, this.mainTopicOutName_, this.mainTopicOut_);

  void login(var username, var password, BuildContext context) async {
    channel_ = ClientChannel('api.toit.io');
    try {
      print('Login...');
      var authClient = AuthClient(channel_);
      var resp = await authClient
          .login(LoginRequest(username: username, password: password));
      var tokenBytes = resp.accessToken;
      token_ = utf8.decode(tokenBytes);
      print('Access token->[$token_]');

      guiAdapter_.onLogged();  // Create ToitBridge

    }
    catch (exception) {
      guiAdapter_.onError(exception.toString());
    }
    finally {
      guiAdapter_.onStop();
    }
  }

  void create() async {
    try {
      options_ = CallOptions(metadata: {'Authorization': 'Bearer $token_'});
      print('PubSub...');
      print('Listing existing subscriptions...');
      subscribeStub_ = SubscribeClient(channel_, options: options_);
      existingSubscriptions_ = (await subscribeStub_.listSubscriptions(ListSubscriptionsRequest())).subscriptions;
      existingSubscriptions_.forEach((sub) {
        print('\t${sub.name}: ${sub.topic}');
      });
      runReceiver(mainTopicOutName_, mainTopicOut_, subscribeStub_, channel_);
      prepareSend(mainTopicInpName_, options_);
    }
    catch(exception) {
      guiAdapter_.onError(exception.toString());
    }
  }

  void runReceiver(var topicName, var topic, SubscribeClient stub, ClientChannel channel) async {
    print('receiveMessages.streaming->[$topic]');
    try {
      var subscription = Subscription(name: topicName, topic: topic);
      var stream = stub.stream(StreamRequest(subscription: subscription));
      print('receiveMessages.streaming');
      await stream.forEach((response) {
        var envelopes = response.messages;
        for (var message in envelopes) {
          //Envelope env = message;
          //print('receiveMessages.Received message');
          // We know the data is utf8. That doesn't need to be the case.
          // The data could be binary.
          var str = utf8.decode(message.message.data);
          // if (before != null) {
          //   Duration duration = DateTime.now().difference(before);
          //   print('receiveMessages.Message data: $str ${duration.inMilliseconds} ms');
          //   str += ' [${duration.inMilliseconds} ms]';
          // }
          // Acknowledge each message individually.
          // We could also just send one request to handle them all.
          stub.acknowledge(AcknowledgeRequest(
              subscription: subscription, envelopeIds: [message.id]));
          guiAdapter_.onReceive(str);
        }
      });
      print('receiveMessages.done');
    }
    catch (exception) {
      print ('receiveMessages.exception->[${exception.toString()}]');
      guiAdapter_.onError(exception.toString());
    } finally {
      print('receiveMessages.shutting down');
      print('receiveMessages.shutdown complete');
    }
  }

  void shutdown() {
    print('shutdown start');
    if (channel_ == null) {
      print('shutdown final (null)');
      return;
    }
    channel_.shutdown();
    print('shutdown final');
  }

  void prepareSend(var topicName, CallOptions options) {
    if (existingSubscriptions_.any((sub) => sub.name == topicName)) {
      // Selected subscription exists
      inpSubscription_ = getSubscription(existingSubscriptions_, topicName);
      print('InpSubscription>  ${inpSubscription_.name}');
      fetchFuture_ = subscribeStub_.fetch(
          FetchRequest(subscription: inpSubscription_));
      publishStub_ = PublishClient(channel_, options: options);
    }
  }

  void send(String message) async {
    before = DateTime.now();
    await sendMessages(message);
  }

  Future<void> sendMessages(var sendMessage) async {
      await publishStub_.publish(PublishRequest(
          topic: mainTopicInp_,
          publisherName: 'dart toit-api demo',
          data: [utf8.encode(sendMessage)]));
      print('Waiting for the published value to reach the subscription...');
      var fetch = await fetchFuture_;
      printFetch(fetch);
      print('Acknowledging...');
      if (fetch.messages != null && fetch.messages.length > 0) {
        await subscribeStub_.acknowledge(AcknowledgeRequest(
            subscription: inpSubscription_,
            envelopeIds: [fetch.messages.first.id]));
      }
      print('Quit...');
  }

  Subscription getSubscription(List<Subscription> list, String topicName) {
    var result = Subscription();
    if (list.isEmpty) {
      return result;
    }
    for (var i = 0; i < list.length; i++) {
      var sub = list[i];
      if (sub.name == topicName) {
        result = sub;
        break;
      }
    }
    return result;
  }

  void printFetch(FetchResponse fetchResponse) {
    print ('printFetch.start');
    var list = fetchResponse.messages;
    print ('printFetch.length-> ${list.length}');
    list.forEach((element) {
      print ('element.id.length->(${element.id.length})\n');
      var listData = element.id;
      var out = '';
      for (var i = 0; i < listData.length; i++) {
        out += String.fromCharCode(listData[i]);
      }
      print ('out->($out)');
    });
    print ('printFetch.final');
  }

}