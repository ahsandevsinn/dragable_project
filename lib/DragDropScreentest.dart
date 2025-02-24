import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';

class DragAndDropScreenTest extends StatefulWidget {
  const DragAndDropScreenTest({super.key});

  @override
  State<DragAndDropScreenTest> createState() => _DragAndDropScreenTestState();
}

class _DragAndDropScreenTestState extends State<DragAndDropScreenTest> {
  List<List<DraggableItem>> history = [[]];
  int historyIndex = 0;
  ScreenshotController screenshotController = ScreenshotController();

  List<Map<String, String>> draggableImages = [
    {"image": "assets/images/a1.png", "name": "USPSA"},
    {"image": "assets/images/a2.png", "name": "IPSC"},
    {"image": "assets/images/a3.png", "name": "STEEL"},
    {"image": "assets/images/a4.png", "name": "POPPER"},
    {"image": "assets/images/a5.png", "name": "TEXAS STAR"},
    {"image": "assets/images/a6.png", "name": "PLATE RACK"},

  ];

  List<DraggableItem> get droppedItems => history[historyIndex];

  void saveToHistory(List<DraggableItem> newItems) {
    setState(() {
      if (historyIndex < history.length - 1) {
        history = history.sublist(0, historyIndex + 1);
      }
      history.add(List.from(newItems));
      historyIndex++;
    });
  }

  void _addItemToCenter(String imagePath) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Size size = renderBox.size;

    final newItem = DraggableItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: imagePath,
      position: Offset(size.width / 2 - 25,
          200 - 25), // Centering (assuming container height is 400)
    );

    final newItems = List<DraggableItem>.from(droppedItems)..add(newItem);
    saveToHistory(newItems);
  }

  void undo() {
    if (historyIndex > 0) {
      setState(() {
        historyIndex--;
      });
    }
  }

  void redo() {
    if (historyIndex < history.length - 1) {
      setState(() {
        historyIndex++;
      });
    }
  }

  void _deleteAll() {
    setState(() {
      history = [[]];
      historyIndex = 0;
    });
  }

  void _captureCanvas() async {
    screenshotController.capture().then((Uint8List? image) async {
      if (image != null) {
        Directory? directory = Directory(
            '/storage/emulated/0/Pictures'); // Internal Storage Pictures Folder

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('STAGE CREATOR',
            style: TextStyle(
                color: Color(0xffceff51),
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        actions: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 150,
            height: 150,
            decoration: const BoxDecoration(
              color: Color(0xff484444),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.0),
                topRight: Radius.circular(20.0),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                    icon: const Icon(Icons.rotate_left_rounded,
                        color: Color(0xffceff51)),
                    onPressed: undo),
                IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xffceff51)),
                    onPressed: redo),
                IconButton(
                    icon: const Icon(Icons.delete, color: Color(0xffceff51)),
                    onPressed: _deleteAll),
              ],
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Screenshot(
            controller: screenshotController,
            child: SizedBox(
              height:350,
              child: Container(
                decoration: const BoxDecoration(color: Color(0xff484444)),
                child: Stack(
                  children: droppedItems.map((item) {
                    return Positioned(
                      left: item.position.dx - 10,
                      top: item.position.dy - 10,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          final newItems =
                              List<DraggableItem>.from(droppedItems);
                          int index =
                              newItems.indexWhere((i) => i.id == item.id);

                          if (index != -1) {
                            double newX = item.position.dx + details.delta.dx;
                            double newY = item.position.dy + details.delta.dy;
                            newX = newX.clamp(0, 300 - 60);
                            newY = newY.clamp(0, 300 - 60);

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
                        child:
                            Image.asset(item.imagePath, width: 50, height: 50),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          const TargetsCard(),
          Container(
            height: 250,
            color: const Color(0xff484444),
            child: Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: draggableImages.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => _addItemToCenter(item["image"]!),
                          child: Image.asset(item["image"]!, width: 60, height: 60),
                        ),
                        const SizedBox(height: 5),
                        Text(item["name"]!,
                            style:
                                const TextStyle(fontSize: 14, color: Colors.white)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomButton(
                borerColor: Colors.black,
                width: 140.0,
                height: 50.0,
                color: const Color(0xffceff51),
                text: "SAVE",
                onPressed: _captureCanvas,
                textColor: Colors.black,
              ),
              CustomButton(
                borerColor: Colors.white,
                textColor: Colors.white,
                width: 140.0,
                height: 50.0,
                color: const Color(0xff686868),
                text: "Delete",
                onPressed: _deleteAll,
              )
            ],
          ),
          const SizedBox(height: 20),
          CustomButton(
            borerColor: Colors.white,
            textColor: Colors.white,
            width: 140.0,
            height: 50.0,
            color: const Color(0xff686868),
            text: "reset",
            onPressed: _deleteAll,
          )
        ],
      ),
    );
  }
}

class NotchedRectangle extends ShapeBorder {
  final double notchSize;
  final Color borderColor;
  final double borderWidth;

  NotchedRectangle({
    this.notchSize = 10.0,
    this.borderColor = Colors.black, // Default border color
    this.borderWidth = 2.0, // Default border width
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(borderWidth);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    rect = Rect.fromLTWH(
        rect.left + borderWidth / 2,
        rect.top + borderWidth / 2,
        rect.width - borderWidth,
        rect.height - borderWidth); // Adjust rect for border width
    Path path = Path()
      ..moveTo(rect.left, rect.top)
      ..lineTo(rect.right, rect.top)
      ..lineTo(rect.right, rect.bottom - notchSize)
      ..lineTo(rect.right - notchSize, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..close();
    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    // First draw the border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    final borderPath = getOuterPath(rect, textDirection: textDirection);
    canvas.drawPath(borderPath, borderPaint);

    // Optionally fill the shape with a color
    final fillPaint = Paint()
      ..color = borderColor
          .withAlpha(0) // Use transparent if you don't want to fill the shape
      ..style = PaintingStyle.fill;
    canvas.drawPath(borderPath, fillPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return NotchedRectangle(
      notchSize: notchSize * t,
      borderColor: borderColor,
      borderWidth: borderWidth * t,
    );
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    // TODO: implement getInnerPath
    throw UnimplementedError();
  }
}

class CustomButton extends StatelessWidget {
  final double? height, width;
  final Color? color;
  final Color? textColor;
  final Color? borerColor;

  final String? text;
  final VoidCallback? onPressed;

  CustomButton({
    super.key,
    this.height,
    this.width,
    this.color = Colors.green,
    this.textColor = Colors.black,
    this.borerColor = Colors.black,
    this.text,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        height: height ?? 40.0,
        width: width ?? 150.0,
        decoration: ShapeDecoration(
          color: color,
          shape: NotchedRectangle(
            notchSize: 10.0,
            borderColor: borerColor ?? Colors.black,
            borderWidth: borerColor == Colors.black ? 0.0 : 1.5,
          ),
        ),
        child: Center(
          child: Text(
            text!.toUpperCase(),
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class DraggableItem {
  final String id;
  final String imagePath;
  final Offset position;

  DraggableItem(
      {required this.id, required this.imagePath, required this.position});
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
