import 'package:flutter/material.dart';



class WarehouseSubCell {
  final String id;
  final double volume;

  WarehouseSubCell({required this.id, required this.volume});
}



class WarehouseCell {
  final int shelfId;
  final int sectionIndex;
  final int rowIndex;
  final double maxCapacity;

  List<WarehouseSubCell> subCells;

  WarehouseCell({
    required this.shelfId,
    required this.sectionIndex,
    required this.rowIndex,
    required this.maxCapacity,
    required this.subCells,
  });

  String get cellCode => "$shelfId$sectionIndex$rowIndex";

  double get usedCapacity => subCells.fold(0.0, (sum, e) => sum + e.volume);

  bool get isFull => usedCapacity >= maxCapacity;

  bool get hasItems => subCells.isNotEmpty;
}



class WarehouseShelf {
  final int shelfNumber;
  final double length;
  final double width;
  final double height;
  final List<WarehouseCell> cells;

  WarehouseShelf({
    required this.shelfNumber,
    required this.length,
    required this.width,
    required this.height,
    required this.cells,
  });
}


void main() {
  runApp(const WarehouseApp());
}

class WarehouseApp extends StatelessWidget {
  const WarehouseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WarehouseScreen(),
    );
  }
}



class WarehouseScreen extends StatefulWidget {
  const WarehouseScreen({super.key});

  @override
  State<WarehouseScreen> createState() => _WarehouseScreenState();
}

class _WarehouseScreenState extends State<WarehouseScreen> {
  List<WarehouseShelf> shelves = [];

  final shelfCountController = TextEditingController();
  final sectionCountController = TextEditingController();
  final lengthController = TextEditingController();
  final widthController = TextEditingController();
  final heightController = TextEditingController();
  final capacityController = TextEditingController();

  int sectionCount = 6;
  static const int rowCount = 5;



  List<WarehouseShelf> generateShelves({
    required int count,
    required double length,
    required double width,
    required double height,
    required double capacity,
  }) {
    final result = <WarehouseShelf>[];

    for (int s = 1; s <= count; s++) {
      final cells = <WarehouseCell>[];

      for (int sec = 1; sec <= sectionCount; sec++) {
        for (int row = 1; row <= rowCount; row++) {
          cells.add(
            WarehouseCell(
              shelfId: s,
              sectionIndex: sec,
              rowIndex: row,
              maxCapacity: capacity,
              subCells: [],
            ),
          );
        }
      }

      result.add(
        WarehouseShelf(
          shelfNumber: s,
          length: length,
          width: width,
          height: height,
          cells: cells,
        ),
      );
    }

    return result;
  }

  void createShelves() {
    final count = int.tryParse(shelfCountController.text.trim()) ?? 0;
    final sections = int.tryParse(sectionCountController.text.trim()) ?? 6;

    final length = double.tryParse(lengthController.text.trim()) ?? 0;
    final width = double.tryParse(widthController.text.trim()) ?? 0;
    final height = double.tryParse(heightController.text.trim()) ?? 0;
    final capacity = double.tryParse(capacityController.text.trim()) ?? 100;


    debugPrint("count=$count sections=$sections");

    if (count == 0) {
      debugPrint("❌ count = 0 → нічого не створено");
      return;
    }

    setState(() {
      sectionCount = sections;

      shelves = generateShelves(
        count: count,
        length: length,
        width: width,
        height: height,
        capacity: capacity,
      );
    });

    debugPrint("✅ shelves created: ${shelves.length}");
  }


  List<WarehouseCell> snakeOrder(WarehouseShelf shelf) {
    final result = <WarehouseCell>[];

    for (int section = 1; section <= sectionCount; section++) {
      final column = shelf.cells
          .where((c) => c.sectionIndex == section)
          .toList();

      column.sort((a, b) => a.rowIndex.compareTo(b.rowIndex));

      if (shelf.shelfNumber % 2 == 0) {
        result.addAll(column.reversed);
      } else {
        result.addAll(column);
      }
    }

    return result;
  }

 

  String subCellId(WarehouseCell cell) {
    final i = cell.subCells.length + 1;
    return "${cell.cellCode}.${i.toString().padLeft(2, '0')}";
  }

  void addSub(WarehouseCell cell) {
    final c = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Додати об’єм"),
        content: TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Скасувати"),
          ),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(c.text) ?? 0;

              if (v > 0 && cell.usedCapacity + v <= cell.maxCapacity) {
                setState(() {
                  cell.subCells.add(
                    WarehouseSubCell(id: subCellId(cell), volume: v),
                  );
                });
              }

              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void removeSub(WarehouseCell cell) {
    if (cell.subCells.isEmpty) return;
    setState(() => cell.subCells.removeLast());
  }



  Widget buildCell(WarehouseCell cell) {
  return Container(
    width: 180,
    height: 120,
    margin: const EdgeInsets.all(3),
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: cell.isFull
          ? Colors.orange
          : (cell.hasItems ? Colors.red : Colors.green),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, // 🔥 FIX
      children: [
        Text(
          cell.cellCode,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),

        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            child: cell.subCells.isEmpty
                ? const SizedBox()
                : ListView.builder(
                    itemCount: cell.subCells.length,
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemBuilder: (context, i) {
                      final s = cell.subCells[i];

                      return Text(
                        "${s.id} ${s.volume.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 8,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
          ),
        ),


        Text(
          "${cell.usedCapacity.toStringAsFixed(2)}/${cell.maxCapacity.toStringAsFixed(2)}",
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [

            GestureDetector(
              onTap: () => addSub(cell),
              child: const Icon(Icons.add, size: 16, color: Colors.white),
            ),
            GestureDetector(
              onTap: () => removeSub(cell),
              child: const Icon(Icons.delete, size: 16, color: Colors.white),
            ),
          ],
        ),
      ],
    ),
  );
}

 
  Widget buildShelf(WarehouseShelf shelf) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "Стелаж ${shelf.shelfNumber}",
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),

      const SizedBox(height: 10),

      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(sectionCount, (index) {
            final isEvenShelf = shelf.shelfNumber % 2 == 0;


            final section = isEvenShelf
                ? (sectionCount - index)
                : (index + 1);

            final cells = shelf.cells
                .where((c) => c.sectionIndex == section)
                .toList()
              ..sort((a, b) => a.rowIndex.compareTo(b.rowIndex));

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text("Секція $section"),


                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: cells.reversed.map(buildCell).toList(),
                  ),
                ],
              ),
            );
          }),
        ),
      ),

      const Divider(),
    ],
  );
}


  Widget input(String label, TextEditingController c, {double w = 80}) {
    return SizedBox(
      width: w,
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Warehouse System"),

        actions: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  input("Стелажі", shelfCountController),
                  const SizedBox(width: 8),
                  input("Секції", sectionCountController),
                  const SizedBox(width: 8),
                  input("Довжина", lengthController),
                  const SizedBox(width: 8),
                  input("Ширина", widthController),
                  const SizedBox(width: 8),
                  input("Висота", heightController),
                  const SizedBox(width: 8),
                  input("Об’єм", capacityController, w: 100),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      FocusScope.of(
                        context,
                      ).unfocus(); // 
                      createShelves();
                    },
                    child: const Text("Створити"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1500),
            child: shelves.isEmpty
                ? const Text("Немає даних")
                : Column(children: shelves.map(buildShelf).toList()),
          ),
        ),
      ),
    );
  }
}
