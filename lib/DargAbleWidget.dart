import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';

class DragAbleWidget extends StatefulWidget {
  const DragAbleWidget({super.key});

  @override
  State<DragAbleWidget> createState() => _DragAbleWidgetState();
}

class _DragAbleWidgetState extends State<DragAbleWidget> {
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
    if (history.isEmpty || _isSignificantChange(newItems, history.last)) {
      history = history.sublist(0, historyIndex + 1);
      history.add(List<DraggableItem>.from(newItems));
      historyIndex++;
    }
  }

  bool _isSignificantChange(
      List<DraggableItem> current, List<DraggableItem> previous) {
    if (current.length != previous.length) return true;
    for (int i = 0; i < current.length; i++) {
      if ((current[i].position - previous[i].position).distance > 5 ||
          (current[i].rotation - previous[i].rotation).abs() > 0.01) {
        return true;
      }
    }
    return false;
  }

  void _deleteSelectedItem() {
    if (selectedItemId == null) return;

    setState(() {
      droppedItems.removeWhere((item) => item.id == selectedItemId);
      saveToHistory(droppedItems);
      selectedItemId = null; // Clear selection after deletion
    });
  }

  void addItemToCenter(String? imagePath) {
    if (imagePath == null) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Size size = renderBox.size;

    final newItem = DraggableItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: imagePath,
      position: Offset(size.width / 2 - 25, 200 - 25),
    );

    final newItems = List<DraggableItem>.from(droppedItems)..add(newItem);
    saveToHistory(newItems);
    setState(() {});
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
        Directory? directory = Directory('/storage/emulated/0/Pictures');

        if (!directory.existsSync()) {
          directory.createSync(recursive: true);
        }

        final filePath = '${directory.path}/canvas_screenshot.png';
        File file = File(filePath);

        await file.writeAsBytes(image);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Screenshot saved: $filePath")),
        );
      }
    }).catchError((onError) {
      print(onError);
    });
  }

  String? selectedItemId;

  void _selectItem(String itemId) {
    setState(() {
      selectedItemId = itemId;
    });
  }

  void _rotateSelectedItem() {
    if (selectedItemId == null) return;

    final index = droppedItems.indexWhere((item) => item.id == selectedItemId);
    if (index != -1) {
      setState(() {
        droppedItems[index] = DraggableItem(
          id: droppedItems[index].id,
          imagePath: droppedItems[index].imagePath,
          position: droppedItems[index].position,
          rotation: droppedItems[index].rotation + 0.9, // 5.7°
        );
        saveToHistory(droppedItems);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('STAGE CREATOR',
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
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                    style: ButtonStyle(
                      shadowColor:
                          MaterialStateProperty.all(Colors.transparent),
                      overlayColor: MaterialStateProperty.all(
                          Colors.transparent), // Removes hover/click effect
                      splashFactory:
                          NoSplash.splashFactory, // Removes press effect
                    ),
                    icon: const Icon(Icons.rotate_left_rounded,
                        color: Color(0xffceff51)),
                    onPressed: undo),
                IconButton(
                    style: ButtonStyle(
                      shadowColor:
                          MaterialStateProperty.all(Colors.transparent),
                      overlayColor: MaterialStateProperty.all(
                          Colors.transparent), // Removes hover/click effect
                      splashFactory:
                          NoSplash.splashFactory, // Removes press effect
                    ),
                    icon: const Icon(Icons.refresh, color: Color(0xffceff51)),
                    onPressed: redo),
                IconButton(
                    style: ButtonStyle(
                      shadowColor:
                          MaterialStateProperty.all(Colors.transparent),
                      overlayColor: MaterialStateProperty.all(
                          Colors.transparent), // Removes hover/click effect
                      splashFactory:
                          NoSplash.splashFactory, // Removes press effect
                    ),
                    icon: const Icon(Icons.delete, color: Color(0xffceff51)),
                    onPressed: _deleteAll),
              ],
            ),
        

          )
        ],
      ),
      body: SingleChildScrollView(
          child: DefaultTabController(
        length: 3, // Targets, No Shoots, Misc
        child: Column(
          children: [
            Screenshot(
              controller: screenshotController,
              child: SizedBox(
                height: 350,
                child: Container(
                  decoration: const BoxDecoration(color: Color(0xff484444)),
                  child: DragTarget<DraggableItem>(
                    onAccept: (item) {
                      setState(() {
                        droppedItems.add(item);
                      });
                    },
                    builder: (context, candidateData, rejectedData) {
                      return Stack(
                        children: droppedItems
                            .map((item) => _buildDraggableItem(item))
                            .toList(),
                      );
                    },
                  ),
                ),
              ),
            ),
            TabBar(
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.black,
              indicatorWeight: 5.0,
              indicator: BoxDecoration(
                color: Colors.black,
              ),
              tabs: [
                Tab(
                    child: CustomTabItem(
                  text: "TARGETS",
                )),
                Tab(
                    child: CustomTabItem(
                  text: "NO SHOOTS",
                )),
                Tab(
                  child: CustomTabItem(
                    text: "MiSC",
                  ),
                ),
              ],
            ),
            Container(
              height: 250,
              child: TabBarView(
                children: [
                  _buildTargetImages(),
                  _buildNoShootImages(),
                  _buildMiscImages(),
                ],
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
                  onPressed: _deleteSelectedItem,
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
              text: "Reset",
              onPressed: _deleteAll,
            ),
            const SizedBox(height: 20),
          ],
        ),
      )),
    
    
    );
  }

  Widget _buildDraggableItem(DraggableItem item) {
    final bool isSelected = item.id == selectedItemId;
    return Positioned(
      left: item.position.dx,
      top: item.position.dy,
      child: GestureDetector(
        onTap: () => _selectItem(item.id),
        // Allow dragging the item
        onPanUpdate: (details) {
          setState(() {
            item.position += details.delta;
          });
          saveToHistory(droppedItems);
        },

        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Blue border/background when selected
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                border: isSelected
                    ? Border.all(color: Colors.blue, width: 3)
                    : null,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            // The draggable image with applied rotation
            Transform.rotate(
              angle: item.rotation,
              child: Image.asset(
                item.imagePath,
                width: 50,
                height: 50,
              ),
            ),
            // Show rotate button if this item is selected
            if (isSelected)
              Positioned(
                top: -15,
                right: -15,
                child: GestureDetector(
                  // onLongPress: _rotateSelectedItem,
                  onTap: _rotateSelectedItem,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.rotate_right,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid(List<Map<String, String>> images) {
    return Container(
      width: 250,
      color: const Color(0xff484444),
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: images.map((item) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => addItemToCenter(item["image"]!),
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
    );
  }

  Widget _buildTargetImages() {
    return _buildImageGrid(draggableImages);
  }

  Widget _buildNoShootImages() {
    return _buildImageGrid(draggableImages);
  }

  Widget _buildMiscImages() {
    return _buildImageGrid(draggableImages);
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
  Offset position;
  double rotation;
  bool isSelected;

  DraggableItem({
    required this.id,
    required this.imagePath,
    required this.position,
    this.rotation = 0.0,
    this.isSelected = false,
  });

  // To clone the DraggableItem
  DraggableItem copyWith({Offset? position}) {
    return DraggableItem(
      id: id,
      imagePath: imagePath,
      position: position ?? this.position,
      rotation: rotation,
      isSelected: isSelected,
    );
  }
}

// class TargetsCard extends StatelessWidget {
//   const TargetsCard({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         // Generated code for this Container Widget...
//         Expanded(
//           child: InkWell(
//             splashColor: Colors.transparent,
//             focusColor: Colors.transparent,
//             hoverColor: Colors.transparent,
//             highlightColor: Colors.transparent,
//             child: Container(
//               decoration: const BoxDecoration(
//                   color: Colors.white,
//                   border: Border(
//                       right: BorderSide(
//                     color: Color(0xff484444),
//                   ))),
//               child: const Align(
//                 alignment: AlignmentDirectional(0, 0),
//                 child: Padding(
//                   padding: EdgeInsetsDirectional.fromSTEB(0, 4, 0, 4),
//                   child: Text(
//                     'TARGETS',
//                     style: TextStyle(
//                       fontFamily: 'Inter',
//                       letterSpacing: 0.0,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//         Expanded(
//           child: InkWell(
//             splashColor: Colors.transparent,
//             focusColor: Colors.transparent,
//             hoverColor: Colors.transparent,
//             highlightColor: Colors.transparent,
//             child: Container(
//               decoration: const BoxDecoration(
//                   color: Colors.white,
//                   border: Border(
//                       right: BorderSide(
//                     color: Color(0xff484444),
//                   ))),
//               child: const Align(
//                 alignment: AlignmentDirectional(0, 0),
//                 child: Padding(
//                   padding: EdgeInsetsDirectional.fromSTEB(0, 4, 0, 4),
//                   child: Text(
//                     'NO SHOOTS',
//                     style: TextStyle(
//                       fontFamily: 'Inter',
//                       letterSpacing: 0.0,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//         Expanded(
//           child: InkWell(
//             splashColor: Colors.transparent,
//             focusColor: Colors.transparent,
//             hoverColor: Colors.transparent,
//             highlightColor: Colors.transparent,
//             child: Container(
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//               ),
//               child: const Align(
//                 alignment: AlignmentDirectional(0, 0),
//                 child: Padding(
//                   padding: EdgeInsetsDirectional.fromSTEB(0, 4, 0, 4),
//                   child: Text(
//                     'MISC',
//                     style: TextStyle(
//                       fontFamily: 'Inter',
//                       letterSpacing: 0.0,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         )
//       ],
//     );
//   }
// }

class CustomTabItem extends StatelessWidget {
  final String text;

  const CustomTabItem({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xff484444))),
      ),
      child: Align(
        alignment: AlignmentDirectional(0, 0),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Inter',
              letterSpacing: 0.0,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}

