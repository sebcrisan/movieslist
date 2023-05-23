import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// provider scope
void main() {
  runApp(const ProviderScope(
    child: MyApp(),
  ));
}

// Film class
@immutable
class Film {
  final String id;
  final String title;
  final String description;
  final bool isFavorite;

  const Film({
    required this.id,
    required this.title,
    required this.description,
    required this.isFavorite,
  });

  Film copy({
    required bool isFavorite,
  }) =>
      Film(
        id: id,
        title: title,
        description: description,
        isFavorite: isFavorite,
      );

  // toString
  @override
  String toString() => 'Film(id: $id, '
      'title: $title, '
      'description: $description, '
      'isFavorite: $isFavorite)';

  // equality
  @override
  bool operator ==(covariant Film other) =>
      id == other.id && isFavorite == other.isFavorite;

  @override
  int get hashCode => Object.hashAll([id, isFavorite]);
}

// List of films hardcoded
const allFilms = [
  Film(
    id: '1',
    title: 'The Shawshank Redemption',
    description: 'Description for The Shawshank Redemption',
    isFavorite: false,
  ),
  Film(
    id: '2',
    title: 'The Godfather',
    description: 'Description for The Godfather',
    isFavorite: false,
  ),
  Film(
    id: '3',
    title: 'The Godfather Part II',
    description: 'Description for The Godfather Part II',
    isFavorite: false,
  ),
  Film(
    id: '4',
    title: 'The Dark Knight',
    description: 'Description for The Dark Knight',
    isFavorite: false,
  ),
];

// Films notifier that has a list of films and allows to update any given film with a favorite flag
class FilmsNotifier extends StateNotifier<List<Film>> {
  /// By default is is populated with a list of all films
  FilmsNotifier() : super(allFilms);

  /// Update film state
  void update(Film film, bool isFavorite) {
    /// Loop through all films, if id matches we can update it
    /// map => toList() is rly nice
    state = state
        .map((thisFilm) => thisFilm.id == film.id
            ? thisFilm.copy(isFavorite: isFavorite)
            : thisFilm)
        .toList();
  }
}

// Different status possibilities
enum FavoriteStatus { all, favorite, notFavorite }

// Favorite status provider that refers to all different status possibilities
final favoriteStatusProvider = StateProvider<FavoriteStatus>(
  (ref) => FavoriteStatus.all,
);

// All films provider
final allFilmsProvider = StateNotifierProvider<FilmsNotifier, List<Film>>(
  (ref) => FilmsNotifier(),
);

// Favorite films provider, utilizes the providers already available to us
// so it can afford to be a regular provider
final favoriteFilmsProvider = Provider<Iterable<Film>>(
  (ref) => ref.watch(allFilmsProvider).where(
        (film) => film.isFavorite,
      ),
);

// Not favorite films
final notFavoriteFilmsProvider = Provider<Iterable<Film>>(
  (ref) => ref.watch(allFilmsProvider).where(
        (film) => !film.isFavorite,
      ),
);

// Films list widget
class FilmsWidget extends ConsumerWidget {
  // AlwaysAliveProvider is a mixin, shared by Provider and StateNotifierProvider
  final AlwaysAliveProviderBase<Iterable<Film>> provider;

  const FilmsWidget({required this.provider, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final films = ref.watch(provider);
    return Expanded(
        child: ListView.builder(
      itemCount: films.length,
      itemBuilder: (context, index) {
        final film = films.elementAt(index);
        final favoriteIcon = film.isFavorite
            ? const Icon(Icons.favorite)
            : const Icon(Icons.favorite_border);
        return ListTile(
          title: Text(film.title),
          subtitle: Text(film.description),
          trailing: IconButton(
            icon: favoriteIcon,
            onPressed: () {
              final isFavorite = !film.isFavorite;
              ref.read(allFilmsProvider.notifier).update(film, isFavorite);
            },
          ),
        );
      },
    ));
  }
}

// Filter widget
class FilterWidget extends StatelessWidget {
  const FilterWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        // enum split returns favoritestatus.all, movies.all, etc so we split by the dot
        return DropdownButton(
          value: ref.watch(favoriteStatusProvider),
          items: FavoriteStatus.values
              .map(
                (fs) => DropdownMenuItem(
                  value: fs,
                  child: Text(fs.toString().split('.').last),
                ),
              )
              .toList(),
          onChanged: (fs) {
            ref.read(favoriteStatusProvider.notifier).state = fs!;
          },
        );
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movies App',
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(title: 'Movies App'),
    );
  }
}

// Home page screen
class MyHomePage extends ConsumerWidget {
  /// Init homepage
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  /// The title of the homepage
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movies'),
      ),
    );
  }
}
