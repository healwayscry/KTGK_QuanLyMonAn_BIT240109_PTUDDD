import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String mssv = 'BIT240109';

// All table and column names stored in SQLite start with BIT240109_.
const String categoryTable = 'BIT240109_DishCategory';
const String dishTable = 'BIT240109_Dish';
const String imageTable = 'BIT240109_DishImage';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FoodDatabase.instance.database;
  runApp(const FoodManagerApp());
}

class DishCategory {
  final int? id;
  final String name;
  final String description;

  DishCategory({this.id, required this.name, required this.description});

  Map<String, Object?> toMap() => {
        'BIT240109_Id': id,
        'BIT240109_Name': name,
        'BIT240109_Description': description,
      };

  factory DishCategory.fromMap(Map<String, Object?> map) => DishCategory(
        id: map['BIT240109_Id'] as int,
        name: map['BIT240109_Name'] as String,
        description: map['BIT240109_Description'] as String? ?? '',
      );
}

class DishImage {
  final int? id;
  final int dishId;
  final String imageUrl;
  final bool isThumbnail;

  DishImage({
    this.id,
    required this.dishId,
    required this.imageUrl,
    required this.isThumbnail,
  });

  Map<String, Object?> toMap() => {
        'BIT240109_Id': id,
        'BIT240109_DishId': dishId,
        'BIT240109_ImageUrl': imageUrl,
        'BIT240109_IsThumbnail': isThumbnail ? 1 : 0,
      };

  factory DishImage.fromMap(Map<String, Object?> map) => DishImage(
        id: map['BIT240109_Id'] as int,
        dishId: map['BIT240109_DishId'] as int,
        imageUrl: map['BIT240109_ImageUrl'] as String,
        isThumbnail: (map['BIT240109_IsThumbnail'] as int) == 1,
      );
}

class Dish {
  final int? id;
  final String name;
  final double price;
  final int preparationTime;
  final bool isAvailable;
  final String description;
  final int categoryId;
  final String categoryName;
  final List<DishImage> images;

  Dish({
    this.id,
    required this.name,
    required this.price,
    required this.preparationTime,
    required this.isAvailable,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    required this.images,
  });

  String get thumbnailUrl {
    for (final image in images) {
      if (image.isThumbnail) return image.imageUrl;
    }
    return images.isEmpty ? '' : images.first.imageUrl;
  }
}

class FoodDatabase {
  FoodDatabase._();
  static final FoodDatabase instance = FoodDatabase._();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final dbPath = await getDatabasesPath();
    _database = await openDatabase(
      p.join(dbPath, 'BIT240109_FoodManager.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $categoryTable (
            BIT240109_Id INTEGER PRIMARY KEY AUTOINCREMENT,
            BIT240109_Name TEXT NOT NULL,
            BIT240109_Description TEXT NOT NULL DEFAULT ''
          )
        ''');
        await db.execute('''
          CREATE TABLE $dishTable (
            BIT240109_Id INTEGER PRIMARY KEY AUTOINCREMENT,
            BIT240109_Name TEXT NOT NULL,
            BIT240109_Price REAL NOT NULL CHECK (BIT240109_Price > 0),
            BIT240109_PreparationTime INTEGER NOT NULL CHECK (BIT240109_PreparationTime > 0),
            BIT240109_IsAvailable INTEGER NOT NULL DEFAULT 1,
            BIT240109_Description TEXT NOT NULL DEFAULT '',
            BIT240109_DishCategoryId INTEGER NOT NULL,
            FOREIGN KEY (BIT240109_DishCategoryId)
              REFERENCES $categoryTable(BIT240109_Id)
          )
        ''');
        await db.execute('''
          CREATE TABLE $imageTable (
            BIT240109_Id INTEGER PRIMARY KEY AUTOINCREMENT,
            BIT240109_DishId INTEGER NOT NULL,
            BIT240109_ImageUrl TEXT NOT NULL,
            BIT240109_IsThumbnail INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (BIT240109_DishId)
              REFERENCES $dishTable(BIT240109_Id) ON DELETE CASCADE
          )
        ''');
        await _insertSampleData(db);
      },
    );
    return _database!;
  }

  Future<void> _insertSampleData(Database db) async {
    final categories = [
      ['Main dishes', 'Rice, noodles and main meals'],
      ['Drinks', 'Hot and cold drinks'],
      ['Desserts', 'Sweet dishes and snacks'],
    ];
    for (final c in categories) {
      await db.insert(categoryTable, {
        'BIT240109_Name': c[0],
        'BIT240109_Description': c[1],
      });
    }

    final samples = [
      ['Chicken rice', 45000.0, 20, 1, 'Rice served with grilled chicken.', 1,
        'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=800'],
      ['Beef pho', 55000.0, 25, 1, 'Vietnamese beef noodle soup.', 1,
        'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=800'],
      ['Milk tea', 30000.0, 10, 1, 'Milk tea with chewy pearls.', 2,
        'https://images.unsplash.com/photo-1558857563-b371033873b8?w=800'],
      ['Orange juice', 25000.0, 5, 1, 'Fresh orange juice.', 2,
        'https://images.unsplash.com/photo-1600271886742-f049cd451bba?w=800'],
      ['Cheesecake', 40000.0, 15, 1, 'Creamy baked cheesecake.', 3,
        'https://images.unsplash.com/photo-1533134242443-d4fd215305ad?w=800'],
    ];
    for (final s in samples) {
      final id = await db.insert(dishTable, {
        'BIT240109_Name': s[0],
        'BIT240109_Price': s[1],
        'BIT240109_PreparationTime': s[2],
        'BIT240109_IsAvailable': s[3],
        'BIT240109_Description': s[4],
        'BIT240109_DishCategoryId': s[5],
      });
      await db.insert(imageTable, {
        'BIT240109_DishId': id,
        'BIT240109_ImageUrl': s[6],
        'BIT240109_IsThumbnail': 1,
      });
    }
  }

  Future<List<DishCategory>> getCategories() async {
    final db = await database;
    final rows = await db.query(categoryTable, orderBy: 'BIT240109_Name ASC');
    return rows.map(DishCategory.fromMap).toList();
  }

  Future<List<Dish>> getDishes({
    String search = '',
    int? categoryId,
    bool? available,
    double? minPrice,
    double? maxPrice,
    String sort = 'name',
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <Object?>[];

    if (search.trim().isNotEmpty) {
      where.add('d.BIT240109_Name LIKE ?');
      args.add('%${search.trim()}%');
    }
    if (categoryId != null) {
      where.add('d.BIT240109_DishCategoryId = ?');
      args.add(categoryId);
    }
    if (available != null) {
      where.add('d.BIT240109_IsAvailable = ?');
      args.add(available ? 1 : 0);
    }
    if (minPrice != null) {
      where.add('d.BIT240109_Price >= ?');
      args.add(minPrice);
    }
    if (maxPrice != null) {
      where.add('d.BIT240109_Price <= ?');
      args.add(maxPrice);
    }

    String orderBy;
    switch (sort) {
      case 'priceAsc':
        orderBy = 'd.BIT240109_Price ASC';
        break;
      case 'priceDesc':
        orderBy = 'd.BIT240109_Price DESC';
        break;
      case 'timeAsc':
        orderBy = 'd.BIT240109_PreparationTime ASC';
        break;
      default:
        orderBy = 'd.BIT240109_Name COLLATE NOCASE ASC';
    }

    final rows = await db.rawQuery('''
      SELECT d.*, c.BIT240109_Name AS category_name
      FROM $dishTable d
      INNER JOIN $categoryTable c
      ON c.BIT240109_Id = d.BIT240109_DishCategoryId
      ${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'}
      ORDER BY $orderBy
    ''', args);

    final result = <Dish>[];
    for (final row in rows) {
      final dishId = row['BIT240109_Id'] as int;
      final imageRows = await db.query(
        imageTable,
        where: 'BIT240109_DishId = ?',
        whereArgs: [dishId],
        orderBy: 'BIT240109_Id ASC',
      );
      result.add(Dish(
        id: dishId,
        name: row['BIT240109_Name'] as String,
        price: (row['BIT240109_Price'] as num).toDouble(),
        preparationTime: row['BIT240109_PreparationTime'] as int,
        isAvailable: (row['BIT240109_IsAvailable'] as int) == 1,
        description: row['BIT240109_Description'] as String? ?? '',
        categoryId: row['BIT240109_DishCategoryId'] as int,
        categoryName: row['category_name'] as String,
        images: imageRows.map(DishImage.fromMap).toList(),
      ));
    }
    return result;
  }

  Future<Dish?> getDishById(int id) async {
    final dishes = await getDishes();
    for (final dish in dishes) {
      if (dish.id == id) return dish;
    }
    return null;
  }

  Future<void> saveDish({
    int? id,
    required String name,
    required double price,
    required int preparationTime,
    required bool isAvailable,
    required String description,
    required int categoryId,
    required List<String> imageUrls,
    required int thumbnailIndex,
  }) async {
    final db = await database;
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw Exception('Name cannot be empty.');
    if (price <= 0) throw Exception('Price must be greater than zero.');
    if (preparationTime <= 0) {
      throw Exception('Preparation time must be greater than zero.');
    }
    final categoryRows = await db.query(categoryTable,
        where: 'BIT240109_Id = ?', whereArgs: [categoryId]);
    if (categoryRows.isEmpty) throw Exception('Please choose a valid category.');

    final duplicateRows = await db.query(dishTable,
        where: 'BIT240109_DishCategoryId = ? AND BIT240109_Name = ? AND BIT240109_Id != ?',
        whereArgs: [categoryId, cleanName, id ?? -1]);
    if (duplicateRows.isNotEmpty) {
      throw Exception('A dish with this name already exists in this category.');
    }

    await db.transaction((txn) async {
      final values = {
        'BIT240109_Name': cleanName,
        'BIT240109_Price': price,
        'BIT240109_PreparationTime': preparationTime,
        'BIT240109_IsAvailable': isAvailable ? 1 : 0,
        'BIT240109_Description': description.trim(),
        'BIT240109_DishCategoryId': categoryId,
      };
      int savedId;
      if (id == null) {
        savedId = await txn.insert(dishTable, values);
      } else {
        await txn.update(dishTable, values,
            where: 'BIT240109_Id = ?', whereArgs: [id]);
        savedId = id;
        await txn.delete(imageTable,
            where: 'BIT240109_DishId = ?', whereArgs: [id]);
      }

      final urls = imageUrls.map((u) => u.trim()).where((u) => u.isNotEmpty).toList();
      for (int i = 0; i < urls.length; i++) {
        await txn.insert(imageTable, {
          'BIT240109_DishId': savedId,
          'BIT240109_ImageUrl': urls[i],
          'BIT240109_IsThumbnail': i == thumbnailIndex ? 1 : 0,
        });
      }
      // Guarantee exactly one thumbnail when there is at least one image.
      if (urls.isNotEmpty && thumbnailIndex >= urls.length) {
        await txn.update(imageTable, {'BIT240109_IsThumbnail': 1},
            where: 'BIT240109_DishId = ?', whereArgs: [savedId]);
      }
    });
  }

  Future<void> deleteDish(int id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(imageTable,
          where: 'BIT240109_DishId = ?', whereArgs: [id]);
      await txn.delete(dishTable,
          where: 'BIT240109_Id = ?', whereArgs: [id]);
    });
  }
}

class FoodManagerApp extends StatefulWidget {
  const FoodManagerApp({super.key});

  @override
  State<FoodManagerApp> createState() => _FoodManagerAppState();
}

class _FoodManagerAppState extends State<FoodManagerApp> {
  bool vietnamese = false;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => vietnamese = prefs.getBool('BIT240109_vietnamese') ?? false);
  }

  Future<void> _setLanguage(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('BIT240109_vietnamese', value);
    setState(() => vietnamese = value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FoodManager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: DishListPage(
        vietnamese: vietnamese,
        onLanguageChanged: _setLanguage,
      ),
    );
  }
}

String tr(bool vi, String en, String vn) => vi ? vn : en;

class DishListPage extends StatefulWidget {
  final bool vietnamese;
  final Future<void> Function(bool) onLanguageChanged;

  const DishListPage({
    super.key,
    required this.vietnamese,
    required this.onLanguageChanged,
  });

  @override
  State<DishListPage> createState() => _DishListPageState();
}

class _DishListPageState extends State<DishListPage> {
  List<Dish> dishes = [];
  List<DishCategory> categories = [];
  bool loading = true;
  String search = '';
  int? categoryId;
  String availability = 'all';
  String sort = 'name';
  final minPriceController = TextEditingController();
  final maxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant DishListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vietnamese != widget.vietnamese) _load();
  }

  @override
  void dispose() {
    minPriceController.dispose();
    maxPriceController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      categories = await FoodDatabase.instance.getCategories();
      final minText = minPriceController.text.trim();
      final maxText = maxPriceController.text.trim();
      final minValue = minText.isEmpty ? null : double.tryParse(minText);
      final maxValue = maxText.isEmpty ? null : double.tryParse(maxText);
      if ((minText.isNotEmpty && minValue == null) ||
          (maxText.isNotEmpty && maxValue == null) ||
          (minValue != null && maxValue != null && minValue > maxValue)) {
        dishes = [];
      } else {
        dishes = await FoodDatabase.instance.getDishes(
          search: search,
          categoryId: categoryId,
          available: availability == 'all' ? null : availability == 'yes',
          minPrice: minValue,
          maxPrice: maxValue,
          sort: sort,
        );
      }
    } catch (e) {
      if (mounted) _message('${tr(widget.vietnamese, 'Error', 'Lỗi')}: $e');
    }
    if (mounted) setState(() => loading = false);
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _openForm([Dish? dish]) async {
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => DishFormPage(
        vietnamese: widget.vietnamese,
        categories: categories,
        dish: dish,
      ),
    ));
    _load(); // Search, filters and sorting remain in this page's state.
  }

  Future<void> _delete(Dish dish) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(widget.vietnamese, 'Delete dish?', 'Xóa món ăn?')),
        content: Text(tr(widget.vietnamese,
            'This action cannot be undone.', 'Bạn không thể hoàn tác thao tác này.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text(tr(widget.vietnamese, 'Cancel', 'Hủy'))),
          FilledButton(onPressed: () => Navigator.pop(context, true),
              child: Text(tr(widget.vietnamese, 'Delete', 'Xóa'))),
        ],
      ),
    );
    if (yes == true && dish.id != null) {
      await FoodDatabase.instance.deleteDish(dish.id!);
      _message(tr(widget.vietnamese, 'Dish deleted.', 'Đã xóa món ăn.'));
      _load();
    }
  }

  Future<void> _openDetails(Dish dish) async {
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => DishDetailPage(dishId: dish.id!, vietnamese: widget.vietnamese),
    ));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final vi = widget.vietnamese;
    return Scaffold(
      appBar: AppBar(
        title: const Text('FoodManager'),
        actions: [
          TextButton(
            onPressed: () => widget.onLanguageChanged(!vi),
            child: Text(vi ? 'English' : 'Tiếng Việt'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: Text(tr(vi, 'Add dish', 'Thêm món')),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              labelText: tr(vi, 'Search dish name', 'Tìm theo tên món'),
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              search = value;
              _load();
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(children: [
            Expanded(
              child: DropdownButtonFormField<int?>(
                value: categoryId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: tr(vi, 'Category', 'Loại món'),
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem<int?>(value: null,
                    child: Text(tr(vi, 'All categories', 'Tất cả loại'))),
                  ...categories.map((c) => DropdownMenuItem<int?>(
                    value: c.id, child: Text(c.name))),
                ],
                onChanged: (v) { categoryId = v; _load(); },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: availability,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: tr(vi, 'Availability', 'Trạng thái'),
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'all', child: Text(tr(vi, 'All', 'Tất cả'))),
                  DropdownMenuItem(value: 'yes', child: Text(tr(vi, 'Available', 'Đang bán'))),
                  DropdownMenuItem(value: 'no', child: Text(tr(vi, 'Unavailable', 'Ngừng bán'))),
                ],
                onChanged: (v) { availability = v ?? 'all'; _load(); },
              ),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(children: [
            Expanded(child: TextField(
              controller: minPriceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: tr(vi, 'Min price', 'Giá từ'),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => _load(),
            )),
            const SizedBox(width: 8),
            Expanded(child: TextField(
              controller: maxPriceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: tr(vi, 'Max price', 'Giá đến'),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => _load(),
            )),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: DropdownButtonFormField<String>(
            value: sort,
            decoration: InputDecoration(
              labelText: tr(vi, 'Sort by', 'Sắp xếp'),
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(value: 'name', child: Text(tr(vi, 'Name A-Z', 'Tên A-Z'))),
              DropdownMenuItem(value: 'priceAsc', child: Text(tr(vi, 'Price low to high', 'Giá tăng dần'))),
              DropdownMenuItem(value: 'priceDesc', child: Text(tr(vi, 'Price high to low', 'Giá giảm dần'))),
              DropdownMenuItem(value: 'timeAsc', child: Text(tr(vi, 'Preparation time', 'Thời gian chế biến'))),
            ],
            onChanged: (v) { sort = v ?? 'name'; _load(); },
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : dishes.isEmpty
                  ? Center(child: Text(tr(vi, 'No dishes found. Check your filters.',
                      'Không có món phù hợp. Hãy kiểm tra bộ lọc.')))
                  : ListView.builder(
                      itemCount: dishes.length,
                      itemBuilder: (context, index) {
                        final dish = dishes[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          child: ListTile(
                            leading: dish.thumbnailUrl.isEmpty
                                ? const CircleAvatar(child: Icon(Icons.restaurant))
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      dish.thumbnailUrl,
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const SizedBox(width: 64, child: Icon(Icons.broken_image)),
                                    ),
                                  ),
                            title: Text(dish.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                              '${dish.categoryName} • ${dish.price.toStringAsFixed(0)} VND\n'
                              '${dish.preparationTime <= 15 ? 'Quick / Nhanh' : 'Regular / Thông thường'} • '
                              '${dish.isAvailable ? tr(vi, 'Available', 'Đang bán') : tr(vi, 'Unavailable', 'Ngừng bán')}',
                            ),
                            isThreeLine: true,
                            onTap: () => _openDetails(dish),
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'edit') _openForm(dish);
                                if (v == 'delete') _delete(dish);
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(value: 'edit',
                                  child: Text(tr(vi, 'Edit', 'Sửa'))),
                                PopupMenuItem(value: 'delete',
                                  child: Text(tr(vi, 'Delete', 'Xóa'))),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ]),
    );
  }
}

class DishDetailPage extends StatefulWidget {
  final int dishId;
  final bool vietnamese;
  const DishDetailPage({super.key, required this.dishId, required this.vietnamese});

  @override
  State<DishDetailPage> createState() => _DishDetailPageState();
}

class _DishDetailPageState extends State<DishDetailPage> {
  Dish? dish;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await FoodDatabase.instance.getDishById(widget.dishId);
    if (!mounted) return;
    setState(() { dish = result; loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final vi = widget.vietnamese;
    return Scaffold(
      appBar: AppBar(title: Text(tr(vi, 'Dish details', 'Chi tiết món ăn'))),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : dish == null
              ? Center(child: Text(tr(vi, 'Dish not found.', 'Không tìm thấy món ăn.')))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(dish!.name, style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text('${tr(vi, 'Category', 'Loại món')}: ${dish!.categoryName}'),
                    Text('${tr(vi, 'Price', 'Giá')}: ${dish!.price.toStringAsFixed(0)} VND'),
                    Text('${tr(vi, 'Preparation time', 'Thời gian chế biến')}: ${dish!.preparationTime} minutes'),
                    Text('${tr(vi, 'Class', 'Phân loại')}: ${dish!.preparationTime <= 15 ? 'Quick / Nhanh' : 'Regular / Thông thường'}'),
                    Text('${tr(vi, 'Status', 'Trạng thái')}: ${dish!.isAvailable ? tr(vi, 'Available', 'Đang bán') : tr(vi, 'Unavailable', 'Ngừng bán')}'),
                    const SizedBox(height: 12),
                    Text(dish!.description),
                    const SizedBox(height: 16),
                    Text(tr(vi, 'Images', 'Hình ảnh'), style: Theme.of(context).textTheme.titleLarge),
                    if (dish!.images.isEmpty)
                      Text(tr(vi, 'No images added.', 'Chưa có ảnh.')),
                    ...dish!.images.map((image) => Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Image.network(
                          image.imageUrl,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 100, alignment: Alignment.center,
                            color: Colors.black12,
                            child: const Icon(Icons.broken_image, size: 40),
                          ),
                        ),
                        Row(children: [
                          Expanded(child: Text(image.imageUrl, maxLines: 1, overflow: TextOverflow.ellipsis)),
                          if (image.isThumbnail)
                            Chip(label: Text(tr(vi, 'Thumbnail', 'Ảnh đại diện'))),
                        ]),
                      ]),
                    )),
                  ],
                ),
    );
  }
}

class DishFormPage extends StatefulWidget {
  final bool vietnamese;
  final List<DishCategory> categories;
  final Dish? dish;

  const DishFormPage({
    super.key,
    required this.vietnamese,
    required this.categories,
    this.dish,
  });

  @override
  State<DishFormPage> createState() => _DishFormPageState();
}

class _DishFormPageState extends State<DishFormPage> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final timeController = TextEditingController();
  final descriptionController = TextEditingController();
  final imagesController = TextEditingController();
  int? categoryId;
  bool available = true;
  int thumbnailIndex = 0;
  bool saving = false;

  bool get vi => widget.vietnamese;

  @override
  void initState() {
    super.initState();
    final dish = widget.dish;
    if (dish != null) {
      nameController.text = dish.name;
      priceController.text = dish.price.toStringAsFixed(0);
      timeController.text = dish.preparationTime.toString();
      descriptionController.text = dish.description;
      categoryId = dish.categoryId;
      available = dish.isAvailable;
      imagesController.text = dish.images.map((e) => e.imageUrl).join('\n');
      final index = dish.images.indexWhere((e) => e.isThumbnail);
      thumbnailIndex = index < 0 ? 0 : index;
    } else if (widget.categories.isNotEmpty) {
      categoryId = widget.categories.first.id;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    timeController.dispose();
    descriptionController.dispose();
    imagesController.dispose();
    super.dispose();
  }

  String? requiredText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return tr(vi, 'This field is required.', 'Không được để trống.');
    }
    return null;
  }

  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;
    final price = double.tryParse(priceController.text.trim());
    final time = int.tryParse(timeController.text.trim());
    if (price == null || price <= 0) {
      _message(tr(vi, 'Price must be greater than zero.', 'Giá phải lớn hơn 0.'));
      return;
    }
    if (time == null || time <= 0) {
      _message(tr(vi, 'Time must be a positive whole number.', 'Thời gian phải là số nguyên lớn hơn 0.'));
      return;
    }
    if (categoryId == null) {
      _message(tr(vi, 'Please choose a category.', 'Vui lòng chọn loại món.'));
      return;
    }
    final urls = imagesController.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (urls.any((url) => !url.startsWith('http://') && !url.startsWith('https://'))) {
      _message(tr(vi, 'Each image must be an http(s) URL.', 'Mỗi ảnh phải là URL http(s).'));
      return;
    }
    if (urls.isNotEmpty && thumbnailIndex >= urls.length) thumbnailIndex = 0;

    setState(() => saving = true);
    try {
      await FoodDatabase.instance.saveDish(
        id: widget.dish?.id,
        name: nameController.text,
        price: price,
        preparationTime: time,
        isAvailable: available,
        description: descriptionController.text,
        categoryId: categoryId!,
        imageUrls: urls,
        thumbnailIndex: thumbnailIndex,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _message(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.dish == null
          ? tr(vi, 'Add dish', 'Thêm món')
          : tr(vi, 'Edit dish', 'Sửa món'))),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: tr(vi, 'Dish name *', 'Tên món *'),
                border: const OutlineInputBorder(),
              ),
              validator: requiredText,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: tr(vi, 'Price (VND) *', 'Giá (VND) *'),
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                final value = double.tryParse((v ?? '').trim());
                if (value == null || value <= 0) {
                  return tr(vi, 'Enter a price greater than zero.', 'Nhập giá lớn hơn 0.');
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: timeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: tr(vi, 'Preparation time (minutes) *', 'Thời gian chế biến (phút) *'),
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                final value = int.tryParse((v ?? '').trim());
                if (value == null || value <= 0) {
                  return tr(vi, 'Enter whole minutes greater than zero.', 'Nhập số phút nguyên lớn hơn 0.');
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: categoryId,
              decoration: InputDecoration(
                labelText: tr(vi, 'Category *', 'Loại món *'),
                border: const OutlineInputBorder(),
              ),
              items: widget.categories.map((c) =>
                DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
              onChanged: (v) => setState(() => categoryId = v),
              validator: (v) => v == null
                  ? tr(vi, 'Choose a category.', 'Hãy chọn loại món.')
                  : null,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(tr(vi, 'Available for sale', 'Đang bán')),
              value: available,
              onChanged: (v) => setState(() => available = v),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: tr(vi, 'Description', 'Mô tả'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: imagesController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: tr(vi, 'Image URLs (one URL per line)', 'URL ảnh (mỗi dòng một URL)'),
                helperText: tr(vi, 'First URL is selected as thumbnail by default. For another thumbnail, move its URL to the first line.',
                    'Mặc định URL đầu tiên là ảnh đại diện. Muốn đổi ảnh đại diện, đưa URL đó lên dòng đầu tiên.'),
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: saving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(saving
                  ? tr(vi, 'Saving...', 'Đang lưu...')
                  : tr(vi, 'Save dish', 'Lưu món ăn')),
            ),
          ],
        ),
      ),
    );
  }
}
