import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FoodTrackingPage extends StatefulWidget {
  @override
  _FoodTrackingPageState createState() => _FoodTrackingPageState();
}

class _FoodTrackingPageState extends State<FoodTrackingPage> {
  List<FoodEntry> _todayEntries = [];
  List<FoodEntry> _recentFoods = [];
  final TextEditingController _foodNameController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  int _waterGlasses = 0;

  @override
  void initState() {
    super.initState();
    _loadEntries();
    _loadRecentFoods();
    _loadWaterIntake();
  }

  Future<void> _loadEntries() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String dateKey = _getDateKey(_selectedDate);
    List<String>? entriesJson = prefs.getStringList(dateKey);

    if (entriesJson != null) {
      setState(() {
        _todayEntries = entriesJson
            .map((json) => FoodEntry.fromJson(jsonDecode(json)))
            .toList();
      });
    } else {
      setState(() {
        _todayEntries = [];
      });
    }
  }

  Future<void> _loadRecentFoods() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? recentJson = prefs.getStringList('recent_foods');

    if (recentJson != null) {
      setState(() {
        _recentFoods = recentJson
            .map((json) => FoodEntry.fromJson(jsonDecode(json)))
            .toList();
      });
    }
  }

  Future<void> _loadWaterIntake() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String dateKey = 'water_${_getDateKey(_selectedDate)}';
    int? glasses = prefs.getInt(dateKey);

    if (glasses != null) {
      setState(() {
        _waterGlasses = glasses;
      });
    } else {
      setState(() {
        _waterGlasses = 0;
      });
    }
  }

  Future<void> _saveEntries() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String dateKey = _getDateKey(_selectedDate);
    List<String> entriesJson =
        _todayEntries.map((entry) => jsonEncode(entry.toJson())).toList();

    await prefs.setStringList(dateKey, entriesJson);
  }

  Future<void> _saveRecentFoods() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Son 10 yiyeceği sakla
    List<FoodEntry> uniqueFoods = [];
    for (var food in _recentFoods) {
      if (!uniqueFoods.any((f) => f.name == food.name)) {
        uniqueFoods.add(food);
        if (uniqueFoods.length >= 10) break;
      }
    }

    List<String> recentJson =
        uniqueFoods.map((entry) => jsonEncode(entry.toJson())).toList();

    await prefs.setStringList('recent_foods', recentJson);
  }

  Future<void> _saveWaterIntake() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String dateKey = 'water_${_getDateKey(_selectedDate)}';
    await prefs.setInt(dateKey, _waterGlasses);
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  void _addFoodEntry() {
    if (_foodNameController.text.isEmpty || _caloriesController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen yiyecek adı ve kalori girin')),
      );
      return;
    }

    int? calories = int.tryParse(_caloriesController.text);
    if (calories == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen geçerli bir kalori değeri girin')),
      );
      return;
    }

    FoodEntry newEntry = FoodEntry(
      name: _foodNameController.text,
      calories: calories,
      time: TimeOfDay.now(),
    );

    setState(() {
      _todayEntries.add(newEntry);
      _recentFoods.insert(0, newEntry); // En son yiyeceği başa ekle
    });

    _saveEntries();
    _saveRecentFoods();

    _foodNameController.clear();
    _caloriesController.clear();

    Navigator.pop(context); // Dialog'u kapat
  }

  void _showAddFoodDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Yemek Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _foodNameController,
              decoration: InputDecoration(labelText: 'Yiyecek Adı'),
            ),
            TextField(
              controller: _caloriesController,
              decoration: InputDecoration(labelText: 'Kaloriler'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: _addFoodEntry,
            child: Text('Ekle'),
          ),
        ],
      ),
    );
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2025),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadEntries();
      _loadWaterIntake();
    }
  }

  void _increaseWater() {
    setState(() {
      _waterGlasses++;
    });
    _saveWaterIntake();
  }

  void _decreaseWater() {
    if (_waterGlasses > 0) {
      setState(() {
        _waterGlasses--;
      });
      _saveWaterIntake();
    }
  }

  void _deleteFoodEntry(int index) {
    setState(() {
      _todayEntries.removeAt(index);
    });
    _saveEntries();
  }

  void _addRecentFood(FoodEntry food) {
    setState(() {
      _todayEntries.add(food);
    });
    _saveEntries();
    Navigator.pop(context); // Dialog'u kapat
  }

  void _showRecentFoodsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Son Eklenen Yiyecekler'),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _recentFoods.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(_recentFoods[index].name),
                subtitle: Text('${_recentFoods[index].calories} kalori'),
                onTap: () => _addRecentFood(_recentFoods[index]),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Kapat'),
          ),
        ],
      ),
    );
  }

  int _calculateTotalCalories() {
    return _todayEntries.fold(0, (sum, entry) => sum + entry.calories);
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate =
        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
    int totalCalories = _calculateTotalCalories();

    return Scaffold(
      appBar: AppBar(
        title: Text('Yemek Takibi'),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formattedDate,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Toplam: $totalCalories kalori',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // Su takibi
          Card(
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Su Takibi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline),
                        onPressed: _decreaseWater,
                      ),
                      SizedBox(width: 10),
                      ...List.generate(
                        8,
                        (index) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Icon(
                            Icons.local_drink,
                            color: index < _waterGlasses
                                ? Colors.blue
                                : Colors.grey.shade300,
                            size: 24,
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline),
                        onPressed: _increaseWater,
                      ),
                    ],
                  ),
                  Text('$_waterGlasses bardak'),
                ],
              ),
            ),
          ),
          // Yemek listesi
          Expanded(
            child: _todayEntries.isEmpty
                ? Center(
                    child: Text('Bugün için yemek kaydı yok'),
                  )
                : ListView.builder(
                    itemCount: _todayEntries.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_todayEntries[index].name),
                        subtitle: Text(
                            '${_todayEntries[index].calories} kalori • ${_todayEntries[index].time.format(context)}'),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _deleteFoodEntry(index),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'recent',
            mini: true,
            onPressed: _showRecentFoodsDialog,
            child: Icon(Icons.history),
            tooltip: 'Son Eklenenler',
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: _showAddFoodDialog,
            child: Icon(Icons.add),
            tooltip: 'Yemek Ekle',
          ),
        ],
      ),
    );
  }
}

class FoodEntry {
  final String name;
  final int calories;
  final TimeOfDay time;

  FoodEntry({
    required this.name,
    required this.calories,
    required this.time,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'calories': calories,
      'hour': time.hour,
      'minute': time.minute,
    };
  }

  factory FoodEntry.fromJson(Map<String, dynamic> json) {
    return FoodEntry(
      name: json['name'],
      calories: json['calories'],
      time: TimeOfDay(hour: json['hour'], minute: json['minute']),
    );
  }
}
