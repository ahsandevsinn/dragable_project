import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';

class DragAndDropScreen extends StatefulWidget {
  const DragAndDropScreen({super.key});

  @override
  State<DragAndDropScreen> createState() => _DragAndDropScreenState();
}

class _DragAndDropScreenState extends State<DragAndDropScreen> {
  List<List<DraggableItem>> history = [[]]; // Store history of dropped items
  int historyIndex = 0; // Tracks current position in history
  GlobalKey _canvasKey = GlobalKey(); // Key for capturing screenshot

  List<Map<String, String>> draggableImages = [
    {"image": "assets/images/a1.png", "name": "USPSA"},
    {"image": "assets/images/a2.png", "name": "IPSC"},
    {"image": "assets/images/a3.png", "name": "STEEL"},
    {"image": "assets/images/a4.png", "name": "POPPER"},
    {"image": "assets/images/a5.png", "name": "TEXAS STAR"},
  ];

  // Get the current state of dropped items
  List<DraggableItem> get droppedItems => history[historyIndex];

  // Save a new state to history
  void saveToHistory(List<DraggableItem> newItems) {
    setState(() {
      if (historyIndex < history.length - 1) {
        history = history.sublist(0, historyIndex + 1);
      }
      history.add(List.from(newItems)); // Store a copy of the current state
      historyIndex++;
    });
  }
  ScreenshotController screenshotController = ScreenshotController(); // Initialize screenshot controller

  void _captureCanvas() async {
    screenshotController.capture().then((Uint8List? image) async {
      if (image != null) {
         Directory? directory = Directory('/storage/emulated/0/Pictures'); // Internal Storage Pictures Folder

    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }

    final filePath = '${directory.path}/canvas_screenshot.png';
    File file = File(filePath);

    await file.writeAsBytes(image);
    //     final directory = await getApplicationDocumentsDirectory();
    //     final filePath = '${directory.path}/canvas_screenshot.png';
    //     File file = File(filePath);
    //     await file.writeAsBytes(image);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Screenshot saved: $filePath")),
        );
      }
    }).catchError((onError) {
      print(onError);
    });
  }

  // Undo function
  void undo() {
    if (historyIndex > 0) {
      setState(() {
        historyIndex--;
      });
    }
  }

  // Redo function
  void redo() {
    if (historyIndex < history.length - 1) {
      setState(() {
        historyIndex++;
      });
    }
  }

  // Delete all dropped items
  void _deleteAll() {
    setState(() {
      history = [[]]; // Reset history
      historyIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'STAGE CREATOR',
          style: TextStyle(
            fontFamily: 'Inter',
            color: Color(0xffceff51),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            width: 150,
            height: 50,
            decoration: const BoxDecoration(
              color: Color(0xff484444),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10.0),
                bottomLeft: Radius.circular(10.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  iconSize: 20,
                  icon: const Icon(Icons.rotate_left_rounded,
                      color: Color(0xffceff51)),
                  onPressed: undo,
                ),
                IconButton(
                  iconSize: 20,
                  icon: const Icon(Icons.refresh, color: Color(0xffceff51)),
                  onPressed: redo,
                ),
                IconButton(
                  iconSize: 20,
                  icon: const Icon(Icons.delete, color: Color(0xffceff51)),
                  onPressed: _deleteAll,
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Screenshot(
            controller: screenshotController, // Wrap the canvas in Screenshot widget
            child: SizedBox(
              height: 400,
              child: DragTarget<String>(
                onAcceptWithDetails: (details) {
                  final newItem = DraggableItem(
                    id: DateTime.now()
                        .millisecondsSinceEpoch
                        .toString(), // Unique ID
                    imagePath: details.data,
                    position: details.offset,
                  );
            
                  final newItems = List<DraggableItem>.from(droppedItems)
                    ..add(newItem);
                  saveToHistory(newItems);
                },
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    height: 400,
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xff484444),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: Stack(
                      children: droppedItems.map((item) {
                        return Positioned(
                          left: item.position.dx - 25,
                          top: item.position.dy - 25,
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              final newItems =
                                  List<DraggableItem>.from(droppedItems);
                              int index =
                                  newItems.indexWhere((i) => i.id == item.id);
            
                              if (index != -1) {
                                double newX = item.position.dx + details.delta.dx;
                                double newY = item.position.dy + details.delta.dy;
            
                                // Constrain movement inside canvas
                                newX = newX.clamp(0, 300 - 50);
                                newY = newY.clamp(0, 300 - 50);
            
                                newItems[index] = DraggableItem(
                                  id: item.id,
                                  imagePath: item.imagePath,
                                  position: Offset(newX, newY),
                                );
            
                                saveToHistory(newItems);
                              }
                            },
                            onLongPress: () {
                              final newItems =
                                  List<DraggableItem>.from(droppedItems);
                              newItems.removeWhere((i) => i.id == item.id);
                              saveToHistory(newItems);
                            },
                            child: Image.asset(item.imagePath,
                                width: 50, height: 50),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            height: 100,
            color: const Color(0xff484444),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: draggableImages
                  .map(
                    (item) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Draggable<String>(
                          data: item["image"]!,
                          feedback: Material(
                            color: Colors.transparent,
                            child: Image.asset(item["image"]!,
                                width: 50, height: 50),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.5,
                            child: Image.asset(item["image"]!,
                                width: 50, height: 50),
                          ),
                          child: Image.asset(item["image"]!,
                              width: 50, height: 50),
                        ),
                        const SizedBox(height: 5),
                        Text(item["name"]!,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.white)),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
          Row(children: [
            CustomButton(width: 100.0,height: 50.0,color:const Color(0xffceff51),text: "SAVE", onPressed:_captureCanvas,textColor: Colors.black,)
          ],)
        ],
      ),
    );
  
  }
}



class DraggableItem {
  final String id; // Unique identifier for each draggable item
  final String imagePath;
  final Offset position;

  DraggableItem(
      {required this.id, required this.imagePath, required this.position});
}

class CustomButton extends StatelessWidget {
  final double? height, width;
  final Color? color;
  final Color? textColor;
  final String? text;
  final onPressed;


   CustomButton({
    super.key,
    this.color,
    this.height,
    this.width,
    this.text,
    this.onPressed,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: color, // ✅ Moved color inside BoxDecoration
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Center(
          child: Text(
            text ?? '',
            style:  TextStyle(color: textColor, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
class TargetsCard extends StatelessWidget {
  const TargetsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Generated code for this Container Widget...
        Expanded(
          child: InkWell(
            splashColor: Colors.transparent,
            focusColor: Colors.transparent,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Container(
              decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                      right: BorderSide(
                    color: Color(0xff484444),
                  ))),
              child: const Align(
                alignment: AlignmentDirectional(0, 0),
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0, 4, 0, 4),
                  child: Text(
                    'TARGETS',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      letterSpacing: 0.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: InkWell(
            splashColor: Colors.transparent,
            focusColor: Colors.transparent,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Container(
              decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                      right: BorderSide(
                    color: Color(0xff484444),
                  ))),
              child: const Align(
                alignment: AlignmentDirectional(0, 0),
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0, 4, 0, 4),
                  child: Text(
                    'NO SHOOTS',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      letterSpacing: 0.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: InkWell(
            splashColor: Colors.transparent,
            focusColor: Colors.transparent,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: const Align(
                alignment: AlignmentDirectional(0, 0),
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0, 4, 0, 4),
                  child: Text(
                    'MISC',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      letterSpacing: 0.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}
