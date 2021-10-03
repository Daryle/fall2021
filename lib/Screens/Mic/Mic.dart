import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:untitled3/Model/LexResponse.dart';
import 'package:untitled3/Model/NLUAction.dart';
import 'package:untitled3/Model/NLUResponse.dart';
import 'package:untitled3/Observables/MicObservable.dart';
import 'package:untitled3/Screens/Mic/ChatBubble.dart';
import 'package:untitled3/Services/NoteService.dart';
import 'package:untitled3/generated/i18n.dart';
import 'package:flutter_tts/flutter_tts.dart';


final recordNoteScaffoldKey = GlobalKey<ScaffoldState>();

class SpeechScreen extends StatefulWidget {
  @override
  _SpeechScreenState createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
  
  final textController = TextEditingController();
  bool _getChat = false;

  bool get getChat => _getChat;


  SpeechToText _speech = SpeechToText();
  late FlutterTts flutterTts;

  bool _isListening = false;
  String _textSpeech = '';

  String get textSpeech => _textSpeech;
  String speechBubbleText =
      'Press the mic to speak';
  List<Widget> actions = [];
  bool alreadyDelayed = false;

  /// Text note service to use for I/O operations against local system
  final TextNoteService textNoteService = new TextNoteService();

 
  void onListen() async {
    if (!_isListening) {
      _textSpeech = "";

      bool available = await _speech.initialize(
        onStatus: (val) => {
          if (val == 'notListening') {print('onStatus: $val')}
        },
        onError: (val) => print('onError: $val'),
        debugLogging: true,
      );
      if (available) {
        setState(() {
          _isListening = true;
        });
        _speech.listen(
            onResult: (val) => setState(() {
                  _textSpeech = val.recognizedWords;
                }));
      }
    } else {
      setState(() {
        _isListening = false;
        _speech.stop();
        // check to see if any text was transcribed
        if (_textSpeech != '' &&
            _textSpeech != 'Press the mic button to start') {
          // if it was, then save it as a note
          setState(() {
            //getChat = true;
          });
          initTts();
        }
      });
    }
  }


  void voiceHandler(Map<String, dynamic> inference) {
    if (inference['isUnderstood']) {
      if (inference['intent'] == 'startTranscription') {
        print('start recording');
        onListen();
      }
      if (inference['intent'] == 'searchNotes') {
        print('Searching notes');
        Navigator.pushNamed(context, '/view-notes');
      }
      if (inference['intent'] == 'searchDetails') {
        print('Searching for personal detail');
        Navigator.pushNamed(context, '/view-details');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Sorry, I did not understand'),
          backgroundColor: Colors.deepOrange,
          duration: const Duration(seconds: 1)));
    }
  }

  @override
  void initState() {
    super.initState();
    _isListening = false;
    _speech = SpeechToText();
    initTts();
  }
  initTts() async {
    flutterTts = FlutterTts();

    await flutterTts.awaitSpeakCompletion(true);
    await _speak();
  }
  Future<void> _speak() async {
    await flutterTts.speak(speechBubbleText);
  }

  @override
  Widget build(BuildContext context) {
    //final noteObserver = Provider.of<NoteObserver>(context);
      ScrollController _controller = new ScrollController();

    MicObserver micObserver = MicObserver();

    return Scaffold(
      key: recordNoteScaffoldKey,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: AvatarGlow(
          animate: _isListening,
          glowColor: Theme.of(context).primaryColor,
          endRadius: 80,
          duration: Duration(milliseconds: 2000),
          repeatPauseDuration: const Duration(milliseconds: 100),
          repeat: true,
          child: Container(
            width: 200.0,
            height: 200.0,
            child: new RawMaterialButton(
              shape: new CircleBorder(),
              elevation: 0.0,
              child: Column(children: [
                Image(
                  image: AssetImage("assets/images/mic.png"),
                  color: Color(0xFF33ACE3),
                  height: 100,
                  width: 100.82,
                ),
                Text(I18n.of(context)!.notesScreenName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ))
              ]),
              onPressed: ()=> micObserver.mockInteraction(),
            ),
          )),

      body: Column(children: <Widget>[
         Container(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 15),
              child: Observer(
              builder: (_) => Text( 
                micObserver.messageInputText,
                style: TextStyle(
                    fontSize: 24,
                    color: Colors.black,
                    fontWeight: FontWeight.w500)),
            )),
        
        //if (getChat)
         Expanded ( 
           child:Observer(
              builder: (_) => ListView.builder(
            shrinkWrap: true,
            physics: const AlwaysScrollableScrollPhysics(),
            controller: _controller,
            itemCount: micObserver.systemUserMessage.length,
            itemBuilder: (BuildContext context, int index){
                dynamic chatObj =  micObserver.systemUserMessage[index];
                //Display text at the top before moving it to the chat bubble
                if(chatObj is String){
                  
                 return ChatMsgBubble(message:chatObj.toString(), isSender: true );
                }
                NLUResponse nluResponse =  (chatObj as NLUResponse);

                //YES_OR_NO Inqueries.
                if(nluResponse.actionType ==ActionType.InComplete){
                    return ChatMsgBubble(message:nluResponse.outputText, hasAction: true);
                }

                return ChatMsgBubble(message:nluResponse.outputText);
            }
          ))
          ),
        
      ])
    );
  }

  
}
