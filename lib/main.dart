import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:english_words/english_words.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class Pair {
  WordPair word;
  bool favorite;

  Pair(this.word, this.favorite);
} 

class MyAppState extends ChangeNotifier {
  var pairs = <Pair>[];
  var index = -1;
  var current = Pair(WordPair.random(), false);

  GlobalKey? historyListKey;

  void getPrev() {
    if (index <= 0) {
      current = pairs[0];
    } else {
      current = pairs[index];
      index--;
    }
    notifyListeners();
  }

  void getNext() {
    index++;
    if (index < pairs.length) {
      current = pairs[index];
    } else {
      current = Pair(WordPair.random(), false);
      pairs.add(current);
    }
    notifyListeners();
  }

  void toggleFavortie(Pair pair) {
    pair.favorite = !pair.favorite;
    notifyListeners();
  }
  
  void removeFavorite(Pair pair) {
    pair.favorite = false;
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// private class
class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
        break;
      case 1:
        page = FavoritesPage();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    var mainArea = ColoredBox(
      color: colorScheme.surfaceVariant,
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 200),
        child: page,
      ),
    );

    return Scaffold(
      body: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth < 450) {
          return Column(
            children: [
              Expanded(child: mainArea),
              SafeArea(
                child: BottomNavigationBar(
                  items: [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.favorite),
                      label: 'Favorites',
                    ),
                  ],
                  currentIndex: selectedIndex,
                  onTap: (value) {
                    setState(() {
                      selectedIndex = value;
                    });
                  },
                )
              )
            ],
          );
        } else {
          return Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  extended: constraints.maxWidth >= 600,
                  destinations: [
                    NavigationRailDestination(
                      icon: Icon(Icons.home), 
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.favorite), 
                      label: Text('Favorites'),
                    ),
                  ], 
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (value) {
                    setState(() {
                      selectedIndex = value;
                    });
                  },
                ),
              ),
              Expanded(child: mainArea),
            ],
          );
        }
      }),
    );
  }
}

class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: HistoryListView(),
          ),
          SizedBox(height: 10,),
          BigCard(pair: pair),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleFavortie(pair);
                },
                label: Text('Like'),
                icon: Icon(pair.favorite ? Icons.favorite : Icons.favorite_border),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.getPrev();
                },
                child: Text('Prev'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.getNext();
                },
                child: Text('Next'),
              ),
            ],
          ),
          Spacer(flex: 2,),
        ],
      ),
    );
  }
}

class HistoryListView extends StatefulWidget {
  const HistoryListView({super.key});

  @override
  State<HistoryListView> createState() => _HistoryListViewState();
}

class _HistoryListViewState extends State<HistoryListView> {
  final _key = GlobalKey();

  static const Gradient _maskingGradient = LinearGradient(
    colors: [Colors.transparent, Colors.black],
    stops: [0.0, 0.5],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();
    appState.historyListKey = _key;

    return ShaderMask(
      shaderCallback: (bounds) => _maskingGradient.createShader(bounds),
      blendMode: BlendMode.dstIn,
      child: AnimatedList(
        key: _key,
        reverse: false,
        padding: EdgeInsets.only(top: 100),
        initialItemCount: appState.pairs.length,
        itemBuilder: (context, index, animation) {
          final pair = appState.pairs[index];

          return SizeTransition(
            sizeFactor: animation,
            child: Center(
              child: TextButton.icon(
                onPressed: () {
                  appState.toggleFavortie(pair);
                },
                icon: pair.favorite ? Icon(Icons.favorite, size: 12,) : Icon(Icons.favorite_border, size: 12,),
                label: Text(pair.word.asLowerCase, semanticsLabel: pair.word.asPascalCase,),
              ), 
            ),
          );
        }
      ),
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({super.key, required this.pair});

  final Pair pair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: AnimatedSize(
          duration: Duration(milliseconds: 200),
          child: MergeSemantics(
            child: Wrap(
              children: [
                Text(
                  pair.word.first,
                  style: style.copyWith(fontWeight: FontWeight.w200),
                ),
                Text(
                  pair.word.second,
                  style: style.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var appState = context.watch<MyAppState>();

    var favorites = appState.pairs.where((p) => p.favorite).toList();
    if (favorites.isEmpty) {
      return Center(child: Text('No favorites yet.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(30),
          child: Text('You have ${favorites.length} favorites:'),
        ),
        Expanded(
          child: GridView(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400, 
              childAspectRatio: 400 / 80,
            ),
            children: [
              for (var pair in favorites)
                ListTile(
                  leading: IconButton(
                    icon: Icon(Icons.delete_outline, semanticLabel: 'Delete'), 
                    color: theme.colorScheme.primary,
                    onPressed: () => appState.removeFavorite(pair),
                  ),
                  title: Text(pair.word.asLowerCase, semanticsLabel: pair.word.asPascalCase,),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
