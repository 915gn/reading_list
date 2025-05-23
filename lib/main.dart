import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
}

class Book {
  String title;
  bool isRead;

  Book({required this.title, this.isRead = false});

  Map<String, dynamic> toMap() => {'title': title, 'isRead': isRead};
  factory Book.fromMap(Map<String, dynamic> map) =>
      Book(title: map['title'], isRead: map['isRead']);
}

enum Filter { all, active, completed }

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reading List',
      theme: ThemeData(
        scaffoldBackgroundColor: Color(0xFFFFF1E6),
        primarySwatch: Colors.orange,
        cardColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFFFFE0B2),
          foregroundColor: Colors.black,
        ),
      ),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: ReadingListPage(
        isDarkMode: _themeMode == ThemeMode.dark,
        onToggleTheme: () {
          setState(() {
            _themeMode = _themeMode == ThemeMode.light
                ? ThemeMode.dark
                : ThemeMode.light;
          });
        },
      ),
    );
  }
}

class ReadingListPage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  ReadingListPage({required this.onToggleTheme, required this.isDarkMode});

  @override
  _ReadingListPageState createState() => _ReadingListPageState();
}

class _ReadingListPageState extends State<ReadingListPage> {
  List<Book> books = [];
  final TextEditingController controller = TextEditingController();
  Filter _filter = Filter.all;

  @override
  void initState() {
    super.initState();
    loadBooks();
  }

  Future<void> loadBooks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('books');
    if (data != null) {
      final List list = jsonDecode(data);
      setState(() {
        books = list.map((e) => Book.fromMap(e)).toList();
      });
    }
  }

  Future<void> saveBooks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(books.map((b) => b.toMap()).toList());
    await prefs.setString('books', data);
  }

  void addBook(String title) {
    setState(() {
      books.add(Book(title: title));
      saveBooks();
    });
    controller.clear();
  }

  void editBook(int index) {
    controller.text = books[index].title;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit Book'),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                books[index].title = controller.text;
                saveBooks();
                controller.clear();
                Navigator.pop(context);
              });
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void searchBook(String title) async {
    final url = Uri.parse(
      'https://www.google.com/search?q=${Uri.encodeComponent(title)}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  } //for google search

  List<Book> get filteredBooks {
    switch (_filter) {
      case Filter.active:
        return books.where((b) => !b.isRead).toList();
      case Filter.completed:
        return books.where((b) => b.isRead).toList();
      default:
        return books;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reading List'),
        actions: [
          PopupMenuButton<Filter>(
            onSelected: (f) => setState(() => _filter = f),
            itemBuilder: (_) => [
              PopupMenuItem(value: Filter.all, child: Text('All')),
              PopupMenuItem(value: Filter.active, child: Text('Active')),
              PopupMenuItem(value: Filter.completed, child: Text('Completed')),
            ],
          ),
          Row(
            children: [
              Text('Dark', style: TextStyle(fontSize: 12)),
              Switch(
                value: widget.isDarkMode,
                onChanged: (_) => widget.onToggleTheme(),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(labelText: 'Add a book'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () => addBook(controller.text),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredBooks.length,
              itemBuilder: (context, i) {
                final book = filteredBooks[i];
                final actualIndex = books.indexOf(book);
                return GestureDetector(
                  onLongPress: () => editBook(actualIndex),
                  child: Card(
                    margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: Checkbox(
                        value: book.isRead,
                        onChanged: (val) {
                          setState(() {
                            books[actualIndex].isRead = val!;
                            saveBooks();
                          });
                        },
                      ),
                      title: Text(book.title),
                      trailing: IconButton(
                        icon: Icon(Icons.search),
                        onPressed: () => searchBook(book.title),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
