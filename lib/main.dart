import 'package:flutter/material.dart';

void main() {
  runApp(const BooksApp());
}

class Book {
  final String title;
  final String author;

  Book(this.title, this.author);
}

class BooksApp extends StatefulWidget {
  const BooksApp({super.key});

  @override
  State<StatefulWidget> createState() => _BooksAppState();
}

class _BooksAppState extends State<BooksApp> {
  Book? _selectedBook;

  List<Book> books = [
    Book('Left Hand of Darkness', 'Ursula K. Le Guin'),
    Book('Too Like the Lightning', 'Ada Palmer'),
    Book('Kindred', 'Octavia E. Butler'),
  ];

  void _handleBookTapped(Book book) {
    setState(() {
      _selectedBook = book;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Books App',
      home: Navigator(
        pages: [
          MaterialPage(
            key: const ValueKey('BooksListPage'),
            child: BooksListScreen(
              books: books,
              onTapped: _handleBookTapped,
            ),
          ),
          if (_selectedBook != null) BookDetailsPage(book: _selectedBook)
        ],
        onPopPage: (route, result) {
          if (!route.didPop(result)) {
            return false;
          }

          // Update the list of pages by setting _selectedBook to null
          setState(() {
            _selectedBook = null;
          });

          return true;
        },
      ),
    );
  }
}

class BooksListScreen extends StatelessWidget {
  final List<Book> books;
  final ValueChanged<Book> onTapped;

  const BooksListScreen({
    super.key,
    required this.books,
    required this.onTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        children: [
          for (Book book in books)
            ListTile(
              title: Text(book.title),
              subtitle: Text(book.author),
              onTap: () => onTapped(book),
            )
        ],
      ),
    );
  }
}

class BookDetailsPage extends Page {
  final Book? book;

  BookDetailsPage({
    required this.book,
  }) : super(key: ValueKey(book));

  @override
  Route createRoute(BuildContext context) {
    return MaterialPageRoute(
      settings: this,
      builder: (BuildContext context) {
        return BookDetailsScreen(book: book);
      },
    );
  }
}

class BookDetailsScreen extends StatelessWidget {
  final Book? book;

  const BookDetailsScreen({
    super.key,
    required this.book,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (book != null) ...[
              Text(
                book!.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                book!.author,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class BookRoutePath {
  final int? id;
  final bool isUnknown;

  BookRoutePath.home()
      : id = null,
        isUnknown = false;

  BookRoutePath.details(this.id) : isUnknown = false;

  BookRoutePath.unknown()
      : id = null,
        isUnknown = true;

  bool get isHomePage => id == null;

  bool get isDetailsPage => id != null;
}

class BookRouterDelegate extends RouterDelegate<BookRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<BookRoutePath> {
  Book? _selectedBook;
  bool show404 = false;

  List<Book> books = [
    Book('Left Hand of Darkness', 'Ursula K. Le Guin'),
    Book('Too Like the Lightning', 'Ada Palmer'),
    Book('Kindred', 'Octavia E. Butler'),
  ];

  BookRouterDelegate() : navigatorKey = GlobalKey<NavigatorState>();

  void _handleBookTapped(Book book) {
    _selectedBook = book;
    notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: [
        MaterialPage(
          key: const ValueKey('BooksListPage'),
          child: BooksListScreen(
            books: books,
            onTapped: _handleBookTapped,
          ),
        ),
        if (show404)
          const MaterialPage(
            key: ValueKey('UnknownPage'),
            child: UnknownScreen(),
          )
        else if (_selectedBook != null)
          BookDetailsPage(book: _selectedBook)
      ],
      onPopPage: (route, result) {
        if (!route.didPop(result)) {
          return false;
        }

        // Update the list of pages by setting _selectedBook to null
        _selectedBook = null;
        show404 = false;
        notifyListeners();

        return true;
      },
    );
  }

  @override
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  BookRoutePath get currentConfiguration {
    if (show404) {
      return BookRoutePath.unknown();
    }

    return _selectedBook == null
        ? BookRoutePath.home()
        : BookRoutePath.details(books.indexOf(_selectedBook!));
  }

  @override
  Future<void> setNewRoutePath(BookRoutePath configuration) async {
    if (configuration.isUnknown) {
      _selectedBook = null;
      show404 = true;
      return;
    }

    if (configuration.isDetailsPage) {
      if (configuration.id! < 0 || configuration.id! > books.length - 1) {
        show404 = true;
        return;
      }

      _selectedBook = books[configuration.id!];
    } else {
      _selectedBook = null;
    }

    show404 = false;
  }
}

class UnknownScreen extends StatelessWidget {
  const UnknownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Center(
        child: Text('404!'),
      ),
    );
  }
}
