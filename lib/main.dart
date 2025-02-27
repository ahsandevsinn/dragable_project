// import 'package:dragable_project/DragAbleWidget.dart';
import 'package:dragable_project/DargAbleWidget.dart';
import 'package:dragable_project/DragDropScreen.dart';
import 'package:dragable_project/DragDropScreentest.dart';
import 'package:dragable_project/DragDropScreentestrotate.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home:  DragAbleWidget(),
      // home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class DragDropScreen extends StatefulWidget {
  @override
  _DragDropScreenState createState() => _DragDropScreenState();
}

class _DragDropScreenState extends State<DragDropScreen> {
  List<DraggableItem> droppedItems = [];
  List<String> draggableItems = ["🔵", "🔺", "🟢", "🟠"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Drag & Drop Canvas")),
        body: Column(
          children: [
            // Drag Target Canvas with fixed height
            SizedBox(
              height: 300, // Fixed height for the canvas
              child: DragTarget<String>(
                onAcceptWithDetails: (details) {
                  setState(() {
                    draggableItems.remove(details.data);
                    droppedItems.add(DraggableItem(
                      icon: details.data,
                      position: details.offset,
                    ));
                  });
                },
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: Stack(
                      children: droppedItems.map((item) {
                        return Positioned(
                          left: item.position.dx - 25,
                          top: item.position.dy - 25,
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              setState(() {
                                double newX =
                                    item.position.dx + details.delta.dx;
                                double newY =
                                    item.position.dy + details.delta.dy;

                                // Constrain within the 300 height canvas
                                if (newY < 0) newY = 0;
                                if (newY > 300 - 50) newY = 300 - 50;

                                item.position = Offset(newX, newY);
                              });
                            },
                            onLongPress: () {
                              setState(() {
                                droppedItems.remove(item);
                                draggableItems.add(item.icon);
                              });
                            },
                            child: Text(item.icon,
                                style: const TextStyle(fontSize: 40)),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),

            // Draggable Items Row
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 100,
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: draggableItems
                        .map(
                          (item) => Draggable<String>(
                            data: item,
                            feedback: Material(
                              color: Colors.transparent,
                              child: Text(item,
                                  style: const TextStyle(fontSize: 40)),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.5,
                              child: Text(item,
                                  style: const TextStyle(fontSize: 40)),
                            ),
                            child: Text(item,
                                style: const TextStyle(fontSize: 40)),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ],
        ));
  }
}

// Class to store each dropped item and its position
class DraggableItem {
  String icon;
  Offset position;

  DraggableItem({required this.icon, required this.position});
}
