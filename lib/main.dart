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
  final BookRouterDelegate _routerDelegate = BookRouterDelegate();
  final BookRouteInformationParser _routeInformationParser =
      BookRouteInformationParser();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Books App',
      routerDelegate: _routerDelegate,
      routeInformationParser: _routeInformationParser,
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

  TransitionDelegate transitionDelegate = NoAnimationTransitionDelegate();

  BookRouterDelegate() : navigatorKey = GlobalKey<NavigatorState>();

  void _handleBookTapped(Book book) {
    _selectedBook = book;
    notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      transitionDelegate: transitionDelegate,
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

class BookRouteInformationParser extends RouteInformationParser<BookRoutePath> {
  @override
  Future<BookRoutePath> parseRouteInformation(
      RouteInformation routeInformation) async {
    final uri = Uri.parse(routeInformation.location!);
    // Handle '/'
    if (uri.pathSegments.isEmpty) {
      return BookRoutePath.home();
    }

    // Handle '/book/:id'
    if (uri.pathSegments.length == 2) {
      if (uri.pathSegments[0] != 'book') return BookRoutePath.unknown();

      final remaining = uri.pathSegments[1];
      final id = int.tryParse(remaining);

      if (id == null) return BookRoutePath.unknown();

      return BookRoutePath.details(id);
    }

    // Handle unknown routes
    return BookRoutePath.unknown();
  }

  @override
  RouteInformation? restoreRouteInformation(BookRoutePath configuration) {
    if (configuration.isUnknown) {
      return const RouteInformation(location: '/404');
    }
    if (configuration.isHomePage) {
      return const RouteInformation(location: '/');
    }
    if (configuration.isDetailsPage) {
      return RouteInformation(location: '/book/${configuration.id}');
    }
    return null;
  }
}

// This class only affects the declarative API, which is why the back button
// still displays a transition animation.
class NoAnimationTransitionDelegate extends TransitionDelegate<void> {
  @override
  Iterable<RouteTransitionRecord> resolve({
    required List<RouteTransitionRecord> newPageRouteHistory,
    required Map<RouteTransitionRecord?, RouteTransitionRecord>
        locationToExitingPageRoute,
    required Map<RouteTransitionRecord?, List<RouteTransitionRecord>>
        pageRouteToPagelessRoutes,
  }) {
    final results = <RouteTransitionRecord>[];

    for (final pageRoute in newPageRouteHistory) {
      if (pageRoute.isWaitingForEnteringDecision) {
        pageRoute.markForAdd();
      }
      results.add(pageRoute);
    }

    for (final exitingPageRoute in locationToExitingPageRoute.values) {
      if (exitingPageRoute.isWaitingForExitingDecision) {
        exitingPageRoute.markForRemove();
        final pagelessRoutes = pageRouteToPagelessRoutes[exitingPageRoute];
        if (pagelessRoutes != null) {
          for (final pagelessRoute in pagelessRoutes) {
            pagelessRoute.markForRemove();
          }
        }
      }

      results.add(exitingPageRoute);
    }
    return results;
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
