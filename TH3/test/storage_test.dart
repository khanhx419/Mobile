import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:english_discipline/storage.dart';
import 'package:english_discipline/learning.dart';

void main() {
  late Store store;
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });
  setUp(() async {
    store = await Store.open(path: inMemoryDatabasePath);
  });
  tearDown(() async {
    await store.db.close();
  });
  test('profiles isolate practice data, goals and active user', () async {
    final first = await store.activeId();
    await store.save(
      userId: first,
      lessonIndex: 1,
      transcript: 'tank you',
      seconds: 4,
      result: assess('thank you', 'tank you'),
      now: DateTime(2026, 10, 31, 10),
    );
    await store.updateUser(first, {'goal_minutes': 10});
    await store.addUser('Người học B');
    final second = await store.activeId();
    expect(second, isNot(first));
    expect(await store.history(second), isEmpty);
    final rows = await store.history(first);
    expect(rows.single['seconds'], 4);
    expect(rows.single['local_day'], '2026-10-31');
    final feedback = jsonDecode(rows.single['analysis_json'] as String);
    expect(feedback['pairs'], isNotEmpty);
    expect((await store.users()).last['goal_minutes'], 5);
    await store.activate(first);
    expect(await store.activeId(), first);
  });
  test('constraints reject orphan sessions and nonpositive time', () async {
    Future<void> insert(int id, int seconds) => store.save(
      userId: id,
      lessonIndex: 0,
      transcript: 'hello',
      seconds: seconds,
      result: assess('hello world', 'hello'),
    );
    await expectLater(insert(999, 3), throwsA(isA<DatabaseException>()));
    await expectLater(
      insert(await store.activeId(), 0),
      throwsA(isA<DatabaseException>()),
    );
  });
  test('unknown words persist unscored, with feedback', () async {
    await store.save(
      userId: await store.activeId(),
      lessonIndex: 0,
      transcript: 'unknown',
      seconds: 2,
      result: assess('hello world', 'unknown'),
    );
    final row = (await store.history(await store.activeId())).single;
    expect(row['score'], isNull);
    expect(row['confidence'], isNull);
    expect(jsonDecode(row['analysis_json'] as String)['unknown'], ['unknown']);
  });
  test('data survives database reopen', () async {
    // Use a separate file database, not an in-memory object, to test persistence.
    final dir = await databaseFactory.getDatabasesPath();
    final path = '$dir/th3_persistence_test.db';
    await databaseFactory.deleteDatabase(path);
    final fileStore = await Store.open(path: path);
    await fileStore.addUser('Persisted learner');
    final id = await fileStore.activeId();
    await fileStore.save(
      userId: id,
      lessonIndex: 0,
      transcript: 'hello world',
      seconds: 5,
      result: assess('hello world', 'hello world'),
    );
    await fileStore.db.close();
    final reopened = await Store.open(path: path);
    expect(await reopened.activeId(), id);
    expect((await reopened.history(id)).single['score'], 100);
    await reopened.db.close();
    await databaseFactory.deleteDatabase(path);
  });
}
