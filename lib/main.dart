import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'dart:collection';

// provider scope
void main() {
  runApp(const ProviderScope(
    child: MyApp(),
  ));
}

// The person class
@immutable
class Person {
  final String name;
  final int age;
  final String uuid;

  /// If no uuid, we get default uuid from package
  Person({
    required this.name,
    required this.age,
    String? uuid,
  }) : uuid = uuid ?? const Uuid().v4();

  /// Creates a new person upon updating a person
  Person updated([String? name, int? age]) => Person(
    name: name ?? this.name,
    age: age ?? this.age,
    uuid: uuid,
  );

  /// Returns the display name for a person
  String get displayName => '$name is ($age years old)';

  /// If we do this, we can compare equality of persons
  @override
  bool operator ==(covariant Person other) => uuid == other.uuid;

  /// We also need to be able to provide the hashcode of the uuid in order to compare them
  @override
  int get hashCode => uuid.hashCode;

  /// Alternatively, we could compare multiple fields like this:
  /// @override
  /// int get hashCode => Object.hash(name, age, uuid);

  /// toString for a person returns their name, age and uuid in a string
  @override
  String toString() => 'Person(name: $name, age: $age, uuid: $uuid)';
}

// Data model that manages a list of persons
class DataModel extends ChangeNotifier {
  /// Private list of people
  final List<Person> _people = [];

  /// Display the amount of people
  int get count => _people.length;

  /// People getter, list is unmodifiable
  UnmodifiableListView<Person> get people => UnmodifiableListView(_people);

  /// Add a person to the list of people
  void add(Person person) {
    _people.add(person);
    notifyListeners();
  }

  /// Remove a person from the list of people
  void remove(Person person) {
    _people.remove(person);
    notifyListeners();
  }

  void update(Person updatedPerson) {
    /// Uses the hashes and equitable overrides we created earlier in order to easily
    /// check if a person is already in the list of people
    final index = _people.indexOf(updatedPerson);
    final oldPerson = _people[index];

    /// If the old person's name or age is different from the name or age that
    /// the UI is giving us, we update the old person with the new name and age
    if (oldPerson.name != updatedPerson.name ||
        oldPerson.age != updatedPerson.age) {
      _people[index] = oldPerson.updated(
        updatedPerson.name,
        updatedPerson.age,
      );
      notifyListeners();
    }
  }
}

// People provider
final peopleProvider = ChangeNotifierProvider((ref) => DataModel());

// Controllers
final nameController = TextEditingController();
final ageController = TextEditingController();

// Person creation / updating dialog
Future<Person?> createOrUpdatePersonDialog(BuildContext context,
    [Person? existingPerson]) {
  String? name = existingPerson?.name;
  int? age = existingPerson?.age;

  nameController.text = name ?? '';
  ageController.text = age?.toString() ?? '';

  return showDialog<Person?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create a person'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Enter name here...',
                ),
                onChanged: (value) => name = value,
              ),
              TextField(
                controller: ageController,
                decoration:
                const InputDecoration(labelText: 'Enter age here...'),
                onChanged: (value) => age = int.tryParse(value),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                if (name != null && age != null) {
                  /// We have an existing person
                  if (existingPerson != null) {
                    final newPerson = existingPerson.updated(
                      name,
                      age,
                    );
                    Navigator.of(context).pop(newPerson);
                  } else {
                    /// No existing person, create a new one
                    Navigator.of(context).pop(Person(age: age!, name: name!));
                  }
                } else {
                  /// No name, age or both
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Persons App',
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(title: 'Persons App'),
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
        title: const Text('Persons'),
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final dataModel = ref.watch(peopleProvider);
          return ListView.builder(
            itemCount: dataModel.count,
            itemBuilder: (context, index) {
              final person = dataModel.people[index];
              return ListTile(
                title: GestureDetector(
                  onTap: () async {
                    final updatedPerson =
                    await createOrUpdatePersonDialog(context, person);
                    if (updatedPerson != null) {
                      dataModel.update(updatedPerson);
                    }
                  },
                  child: Text(person.displayName),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final person = await createOrUpdatePersonDialog(
            context,
          );
          if (person != null) {
            final dataModel = ref.read(peopleProvider);
            dataModel.add(person);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
