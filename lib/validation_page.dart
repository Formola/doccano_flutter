import 'package:doccano_flutter/components/span_to_validate.dart';
import 'package:doccano_flutter/components/user_data.dart';
import 'package:doccano_flutter/components/validation_card.dart';
import 'package:doccano_flutter/constants/logo_animation.dart';
import 'package:doccano_flutter/globals.dart';
import 'package:doccano_flutter/menu_page.dart';
import 'package:doccano_flutter/models/examples.dart';
import 'package:doccano_flutter/models/label.dart';
import 'package:doccano_flutter/models/span.dart';
import 'package:doccano_flutter/utils/doccano_api.dart';
import 'package:doccano_flutter/utils/dont_ask_dialog.dart';
import 'package:doccano_flutter/utils/utilities.dart';
import 'package:float_column/float_column.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'components/circular_progress_indicator_with_text.dart';

import 'package:flutter_card_swiper/flutter_card_swiper.dart';

class ValidationPage extends StatefulWidget {
  const ValidationPage({Key? key, required this.passedExample})
      : super(key: key);

  final Example passedExample;

  @override
  State<ValidationPage> createState() => _ValidationPageState();
}

class _ValidationPageState extends State<ValidationPage> {
  late Future<Map<String, dynamic>> _future;
  List<Span>? fetchedSpans;
  List<Label>? fetchedLabels;
  List<InlineSpan>? _spans;
  ExampleMetadata? metaData;
  late Map<String, dynamic> commentMap;

  List<SpanToValidate>? validatedSpans;

  late bool endOfCards;
  late bool allSpansValidate = false;
  List<SpanToValidate>? validatingSpans = [];
  List<Span>? deletingSpans = [];
  List<Span>? ignoringSpans = [];

  List<ValidationCard?> cards = [];

  Future<Map<String, dynamic>> getData() async {
    if (dotenv.get("ENV") == "development") {
      await login(dotenv.get("USERNAME"), dotenv.get("PASSWORD"));
    }

    List<Label> labels = await getLabels();
    List<Span>? spans = await getSpans(widget.passedExample.id!);

    spans!.sort(((a, b) => a.startOffset.compareTo(b.startOffset)));

    ExampleMetadata? metaData = await getExampleMetaData(
        Example.fromJson(widget.passedExample.toJson()).id!);

    List<SpanToValidate>? valSpans;

    var boxUsers = await Hive.openBox('UTENTI');
    print(
        'apro la box da validation page allo start -> ${boxUsers.get('Examples')?.examples}');

    Map<String, List<SpanToValidate>?> spanMap =
        boxUsers.get('Examples')?.examples;

    if (spanMap.containsKey('${widget.passedExample.id}')) {
      valSpans = spanMap["${widget.passedExample.id}"];
    } else {
      valSpans = [];
    }

    Map<String, dynamic> data = {
      "fetchedLabels": labels,
      "fetchedSpans": spans,
      "fetchedMetaData": metaData,
      "fetchedValidatedSpans": valSpans
    };

    return data;
  }

  @override
  void initState() {
    endOfCards = false;

    super.initState();
    _future = getData().then((data) {
      setState(() {
        fetchedSpans = data["fetchedSpans"];
        fetchedLabels = data["fetchedLabels"];
        _spans = [TextSpan(text: widget.passedExample.text)];
        metaData = data["fetchedMetaData"];
        commentMap = buildComments(metaData);
        validatedSpans = data["fetchedValidatedSpans"];
      });
      buildCards();
      allSpansValidate = checkNumberSpansValidated();
      print(allSpansValidate);
      return data;
    });
  }

  bool checkNumberSpansValidated(){

    if (fetchedSpans?.isNotEmpty ?? false) {
      if(validatedSpans?.isNotEmpty ?? false){
        if(validatedSpans!.length == fetchedSpans!.length){
          return true;
        } else{
          return false;
        }
      } else {
        return false;
      }
    } else {
      return true;
    }
  }

  void buildCards() {
    for (int i = 0; i < fetchedSpans!.length; i++) {
      List<InlineSpan> inlineSpanList = buildSpan(fetchedSpans![i]);
      SpanToValidate spanToValidate = SpanToValidate(
          span: fetchedSpans![i],
          label: fetchedLabels!
              .firstWhere((label) => fetchedSpans![i].label == label.id),
          validated: false);
      updateTextSpan(inlineSpanList);
      if (validatedSpans!.isNotEmpty) {
        bool isValid = false;
        for (int j = 0; j < validatedSpans!.length; j++) {
          if (validatedSpans![j].span.id == spanToValidate.span.id) {
            isValid = true;
          }
        }
        if (!isValid) {
          cards.add(ValidationCard(
            spanToValidate: spanToValidate,
            inlineSpanList: inlineSpanList,
            commentMap: commentMap,
          ));
        }
      } else {
        cards.add(ValidationCard(
          spanToValidate: spanToValidate,
          inlineSpanList: inlineSpanList,
          commentMap: commentMap,
        ));
      }
    }
  }

  int offsetTextToShow = 40;

  List<InlineSpan> getValidationText(Span span, List<InlineSpan> text) {
    List<List<InlineSpan>> result1 = text.splitAtCharacterIndex(
        SplitAtIndex(span.startOffset - offsetTextToShow));
    List<List<InlineSpan>> result2 = result1.last.splitAtCharacterIndex(
        SplitAtIndex(span.endOffset - span.startOffset + 2 * offsetTextToShow));

    return result2.first;
  }

  List<InlineSpan> buildSpan(Span span) {
    List<InlineSpan> temporarySpans = _spans!;
    Label spanLabel =
        fetchedLabels!.firstWhere((label) => label.id == span.label);

    final startIndex = span.startOffset;
    final endIndex = span.endOffset;
    final result1 =
        temporarySpans.splitAtCharacterIndex(SplitAtIndex(startIndex));
    final result2 =
        result1.last.splitAtCharacterIndex(SplitAtIndex(endIndex - startIndex));

    TextSpan labelTextSpan = TextSpan(
      style: TextStyle(
          backgroundColor: Color(hexStringToInt(spanLabel.backgroundColor!)),
          color: Color(hexStringToInt(spanLabel.textColor!))),
      text:
          result2.first.fold('', (prev, curr) => '$prev${curr.toPlainText()}'),
    );

    // Update the state with the new spans.
    temporarySpans = [
      if (result1.length > 1) ...result1.first,
      labelTextSpan,
      if (result2.length > 1) ...result2.last,
    ];

    return getValidationText(span, temporarySpans);
  }

  Map<String, dynamic> buildComments(ExampleMetadata? metaData) {
    String commentString = metaData!.comment!;
    Map<String, dynamic> commentMap = {};

    commentString.split(',').forEach((element) {
      final parts = element.split(':');
      commentMap[parts[0].trim()] = parts[1].trim();
    });

    fixData(commentMap);
    return commentMap;
  }

  @override
  Widget build(BuildContext context) {
    Example example = widget.passedExample;
    bool? checkBoxdontAskValue = false;
    final CardSwiperController controller = CardSwiperController();

    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
          appBar: AppBar(
            title: Text('Example ID: ${example.id}'),
            leading: BackButton(
              onPressed: () async {
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
                // ignore: use_build_context_synchronously
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const MenuPage()));
              },
            ),
          ),
          body: FutureBuilder(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasData) {


                  void swipe(int index, CardSwiperDirection direction) async {

                    SpanToValidate spanToValidate = cards[index]!.spanToValidate;

                    if (direction.name == 'right') {
                      validatingSpans?.add(spanToValidate);
                    }

                    if (direction.name == 'left') {
                      deletingSpans?.add(cards[index]!.spanToValidate.span);
                    }

                    if (direction.name == 'top') {
                      ignoringSpans?.add(fetchedSpans![index]);
                    }

                    if (direction.name == 'bottom') {
                      ignoringSpans?.add(fetchedSpans![index]);
                    }
                  }

                  
                   return SafeArea(
                     child: allSpansValidate ? Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                       children: [
                        const Padding(
                          padding:  EdgeInsets.all(8.0),
                          child: LogoAnimation(),
                        ),
                         Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(50),
                                      ),
                                      fixedSize: const Size(250 ,70),
                                      backgroundColor:
                                          Colors.lightBlue[400],
                                ),
                                onPressed: () async {
                                  Navigator.pop(context);
                                }, 
                                child: const Text('ALL SPAN ALREADY VALIDATED',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                            ),
                              ),
                            ),
                          ),
                       ],
                     ) :Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                            flex: 1,
                            child: (endOfCards
                                ? Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: SizedBox(
                                                height: 100,
                                                child: Card(
                                                  elevation: 8,
                                                  color: Colors.red,
                                                  child: Column(
                                                    children: [
                                                      const Padding(
                                                        padding:
                                                            EdgeInsets.all(8.0),
                                                        child: Text(
                                                          'DELETE',
                                                          style: TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 20,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.all(
                                                                8.0),
                                                        child: Text(
                                                          'You are deleting ${deletingSpans?.length} Span',
                                                          style: const TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 18),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: SizedBox(
                                                height: 100,
                                                child: Card(
                                                  elevation: 8,
                                                  color: Colors.grey,
                                                  child: Column(
                                                    children: [
                                                      const Padding(
                                                        padding:
                                                            EdgeInsets.all(8.0),
                                                        child: Text(
                                                          'IGNORE',
                                                          style: TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 20,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.all(
                                                                8.0),
                                                        child: Text(
                                                          'You are ignoring ${ignoringSpans?.length} Span',
                                                          style: const TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 18),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: SizedBox(
                                                height: 100,
                                                child: Card(
                                                  elevation: 8,
                                                  color: Colors.green,
                                                  child: Column(
                                                    children: [
                                                      const Padding(
                                                        padding:
                                                            EdgeInsets.all(8.0),
                                                        child: Text(
                                                          'VALIDATE',
                                                          style: TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 20,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.all(
                                                                8.0),
                                                        child: Text(
                                                          'You are validating ${validatingSpans?.length} Span',
                                                          style: const TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 18),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 80.0),
                                            child: Center(
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(50),
                                                  ),
                                                  fixedSize: const Size(150, 70),
                                                  backgroundColor: Colors.red,
                                                ),
                                                onPressed: () {
                                                  showDialog(
                                                      context: context,
                                                      builder: (context) {
                                                        return AlertDialog(
                                                          title: const Text(
                                                              'ANNULLA VALIDAZIONE...'),
                                                          content:
                                                              StatefulBuilder(
                                                            builder: (BuildContext
                                                                    context,
                                                                StateSetter
                                                                    setState) {
                                                              return const SizedBox(
                                                                height: 60,
                                                                child: Padding(
                                                                  padding: EdgeInsets
                                                                      .only(
                                                                          top:
                                                                              16.0),
                                                                  child: Text(
                                                                    'Stai annullando la validazione...sei sicuro??',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            18,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .bold),
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () {
                                                                Navigator.of(
                                                                        context)
                                                                    .pop();
                                                              },
                                                              child: const Text(
                                                                  'NO'),
                                                            ),
                                                            TextButton(
                                                              onPressed: () {
                                                                Navigator.of(
                                                                        context)
                                                                    .pop();
                   
                                                                Navigator.pop(
                                                                    context);
                                                                Navigator.pop(
                                                                    context);
                                                                Navigator.push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                        builder:
                                                                            (context) =>
                                                                                const MenuPage()));
                                                              },
                                                              child: const Text(
                                                                  'OK'),
                                                            ),
                                                          ],
                                                        );
                                                      });
                                                },
                                                child: const Text(
                                                  'ANNULLA',
                                                  style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 20),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 80.0),
                                            child: Center(
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(50),
                                                  ),
                                                  fixedSize: const Size(150, 70),
                                                  backgroundColor:
                                                      Colors.green[400],
                                                ),
                                                onPressed: () {
                                                  showDialog(
                                                      context: context,
                                                      builder: (context) {
                                                        return AlertDialog(
                                                          title: const Text(
                                                              'CONFERMA VALIDAZIONE...'),
                                                          content:
                                                              StatefulBuilder(
                                                            builder: (BuildContext
                                                                    context,
                                                                StateSetter
                                                                    setState) {
                                                              return const SizedBox(
                                                                height: 60,
                                                                child: Padding(
                                                                  padding: EdgeInsets
                                                                      .only(
                                                                          top:
                                                                              16.0),
                                                                  child: Text(
                                                                    'Stai sincronizzando la validazione con il webserver...sei sicuro??',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            18,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .bold),
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () {
                                                                Navigator.of(
                                                                        context)
                                                                    .pop();
                                                              },
                                                              child: const Text(
                                                                  'NO'),
                                                            ),
                                                            TextButton(
                                                              //conferma e sync col webserver
                                                              onPressed:
                                                                  () async {
                                                                    if(deletingSpans?.isNotEmpty ?? false){
                                                                      for(int i = 0; i < deletingSpans!.length; i++){
                                                                        deleteSpan(widget.passedExample.id!, deletingSpans![i].id);
                                                                      }
                                                                      debugPrint("Spans $deletingSpans from example ${widget.passedExample.id}  successfully deleted.");
                   
                                                                    }
                                                                    
                   
                                                                validatingSpans
                                                                    ?.forEach((span) {span.validated =true;
                                                                });
                   
                                                                if (validatedSpans
                                                                        ?.isNotEmpty ??
                                                                    false) {
                                                                  validatingSpans
                                                                      ?.addAll(
                                                                          validatedSpans!);
                                                                }
                   
                                                                var boxUsers =
                                                                    await Hive
                                                                        .openBox(
                                                                            'UTENTI');
                   
                                                                boxUsers.put(
                                                                    'Examples',
                                                                    UserData(
                                                                        examples: {
                                                                          widget
                                                                              .passedExample
                                                                              .id
                                                                              .toString(): validatingSpans
                                                                        }));
                   
                                                                print(
                                                                    'apro la box da validation page sync server-> ${boxUsers.get('Examples').examples}');
                   
                                                                if(!mounted) return;
                                                                Navigator.of(
                                                                        context)
                                                                    .pop();
                   
                                                                Navigator.pop(
                                                                    context);
                                                                Navigator.pop(
                                                                    context);
                                                                Navigator.push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                        builder:
                                                                            (context) =>
                                                                                const MenuPage()));
                                                              },
                                                              child: const Text(
                                                                  'OK'),
                                                            ),
                                                          ],
                                                        );
                                                      });
                                                },
                                                child: const Text(
                                                  'CONFERMA',
                                                  style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 20),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                    ],
                                  )
                                : CardSwiper(
                                    isDisabled: false,
                                    controller: controller,
                                    cards: cards,
                                    onSwipe: swipe,
                                    onEnd: () async {
                                      setState(() {
                                        endOfCards = true;
                                      });
                                    },
                                  ))),
                   
                        (endOfCards
                            ? const SizedBox()
                            : Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                   
                                        CircleAvatar(
                                          radius: 40,
                                          backgroundColor: Colors.red,
                                          child: IconButton(
                                            onPressed: () {
                                              (prefs.getBool("DELETE_SPAN")!)
                                                  ? controller.swipeLeft()
                                                  : {
                                                      showDialog(
                                                        context: context,
                                                        builder: ((context) {
                                                          return DontAskDialog(
                                                            checkBoxdontAskValue:
                                                                checkBoxdontAskValue,
                                                            swipeController:
                                                                controller,
                                                          );
                                                        }),
                                                      ),
                                                    };
                                            },
                                            icon: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                   
                                        CircleAvatar(
                                          radius: 40,
                                          backgroundColor: Colors.grey,
                                          child: IconButton(
                                            onPressed: () {
                                              controllerRandomTopBottom(controller);
                                            },
                                            icon: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                   
                                        CircleAvatar(
                                          radius: 40,
                                          backgroundColor: Colors.green[300],
                                          child: IconButton(
                                            onPressed: () {
                                              controller.swipeRight();
                                            },
                                            icon: const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 30,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Center(
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(50),
                                                  ),
                                                  fixedSize: const Size(250 ,70),
                                                  backgroundColor:
                                                      Colors.lightBlue[400],
                                                ),
                                            onPressed: () async {
                                              var boxUsers = await Hive.openBox('UTENTI');
                                              boxUsers.put('Examples',UserData( examples: {widget.passedExample.id.toString(): []}));
                   
                                              print('apro la box da validation page sync server-> ${boxUsers.get('Examples').examples}');
                   
                                          }, 
                                          child: const Text('CLEAR VALIDATED SPAN',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),)),
                                        ),
                                      ),
                                  ],
                                ),
                                
                              )),
                        //CommentWidget(comment: comment),
                      ],
                                     ),
                   ); 
                }
                
              } else if (snapshot.hasError) {
                return Text("${snapshot.error}");
              }

              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicatorWithText(
                      "Fetching labels and examples..."),
                ),
              );
            },
          )),
    );
  }
}
