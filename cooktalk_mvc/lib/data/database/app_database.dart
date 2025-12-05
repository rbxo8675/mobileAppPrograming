import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/recipe.dart';
import '../../core/utils/logger.dart';

class AppDatabase {
  static Database? _database;
  static const String _dbName = 'cooktalk.db';
  static const int _dbVersion = 1;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _dbName);

      Logger.info('Initializing database at: $path');

      return await openDatabase(
        path,
        version: _dbVersion,
        onCreate: _createTables,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      );
    } catch (e) {
      Logger.error('Failed to initialize database', e);
      rethrow;
    }
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE recipes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL,
        image_path TEXT,
        description TEXT,
        servings INTEGER,
        difficulty TEXT,
        rating REAL,
        bookmarked INTEGER DEFAULT 0,
        liked INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ingredients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipe_id TEXT NOT NULL,
        name TEXT NOT NULL,
        FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE recipe_steps (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipe_id TEXT NOT NULL,
        step_number INTEGER NOT NULL,
        instruction TEXT NOT NULL,
        timer_minutes INTEGER,
        auto_start INTEGER DEFAULT 0,
        FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE recipe_tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipe_id TEXT NOT NULL,
        tag TEXT NOT NULL,
        FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE cooking_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipe_id TEXT NOT NULL,
        completed_at INTEGER NOT NULL,
        photo_path TEXT,
        rating INTEGER,
        notes TEXT,
        FOREIGN KEY (recipe_id) REFERENCES recipes(id)
      )
    ''');

    await db.execute('CREATE INDEX idx_recipes_created_at ON recipes(created_at DESC)');
    await db.execute('CREATE INDEX idx_cooking_history_completed_at ON cooking_history(completed_at DESC)');

    Logger.info('Database tables created successfully');
  }

  Future<void> insertRecipe(Recipe recipe) async {
    final db = await database;
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    try {
      await db.transaction((txn) async {
        await txn.insert(
          'recipes',
          {
            'id': recipe.id,
            'title': recipe.title,
            'duration_minutes': recipe.durationMinutes,
            'image_path': recipe.imagePath,
            'description': recipe.description,
            'servings': recipe.servings,
            'difficulty': recipe.difficulty,
            'rating': recipe.rating,
            'bookmarked': recipe.bookmarked ? 1 : 0,
            'liked': recipe.liked ? 1 : 0,
            'created_at': timestamp,
            'updated_at': timestamp,
          },
          conflictAlgorithm: ConflictAlgorithm.fail,
        );

        for (final ingredient in recipe.ingredients) {
          await txn.insert('ingredients', {
            'recipe_id': recipe.id,
            'name': ingredient,
          });
        }

        for (var i = 0; i < recipe.steps.length; i++) {
          final step = recipe.steps[i];
          await txn.insert('recipe_steps', {
            'recipe_id': recipe.id,
            'step_number': i + 1,
            'instruction': step.instruction,
            'timer_minutes': step.timerMinutes,
            'auto_start': step.autoStart ? 1 : 0,
          });
        }

        for (final tag in recipe.tags) {
          await txn.insert('recipe_tags', {
            'recipe_id': recipe.id,
            'tag': tag,
          });
        }
      });

      Logger.info('Recipe inserted: ${recipe.title}');
    } catch (e) {
      Logger.error('Failed to insert recipe', e);
      rethrow;
    }
  }

  Future<void> upsertRecipe(Recipe recipe) async {
    final db = await database;
    
    try {
      // Check if recipe exists
      final existing = await db.query(
        'recipes',
        where: 'id = ?',
        whereArgs: [recipe.id],
        limit: 1,
      );

      if (existing.isEmpty) {
        await insertRecipe(recipe);
      } else {
        await updateRecipe(recipe);
      }
    } catch (e) {
      Logger.error('Failed to upsert recipe', e);
      rethrow;
    }
  }

  Future<List<Recipe>> getAllRecipes() async {
    final db = await database;

    try {
      final recipeMaps = await db.query(
        'recipes',
        orderBy: 'created_at DESC',
      );

      final recipes = await Future.wait(recipeMaps.map((map) async {
        final ingredients = await db.query(
          'ingredients',
          where: 'recipe_id = ?',
          whereArgs: [map['id']],
        );

        final steps = await db.query(
          'recipe_steps',
          where: 'recipe_id = ?',
          whereArgs: [map['id']],
          orderBy: 'step_number ASC',
        );

        final tags = await db.query(
          'recipe_tags',
          where: 'recipe_id = ?',
          whereArgs: [map['id']],
        );

        return Recipe(
          id: map['id'] as String,
          title: map['title'] as String,
          durationMinutes: map['duration_minutes'] as int,
          imagePath: map['image_path'] as String?,
          description: map['description'] as String?,
          servings: map['servings'] as int?,
          difficulty: map['difficulty'] as String?,
          rating: map['rating'] as double?,
          bookmarked: (map['bookmarked'] as int) == 1,
          liked: (map['liked'] as int) == 1,
          ingredients: ingredients.map((i) => i['name'] as String).toList(),
          steps: steps.map((s) => RecipeStep(
            instruction: s['instruction'] as String,
            timerMinutes: s['timer_minutes'] as int?,
            autoStart: (s['auto_start'] as int) == 1,
          )).toList(),
          tags: tags.map((t) => t['tag'] as String).toList(),
        );
      }));

      Logger.info('Loaded ${recipes.length} recipes from database');
      return recipes;
    } catch (e) {
      Logger.error('Failed to load recipes', e);
      return [];
    }
  }

  Future<Recipe?> getRecipeById(String id) async {
    final db = await database;

    try {
      final recipeMaps = await db.query(
        'recipes',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (recipeMaps.isEmpty) return null;

      final map = recipeMaps.first;
      final ingredients = await db.query(
        'ingredients',
        where: 'recipe_id = ?',
        whereArgs: [id],
      );

      final steps = await db.query(
        'recipe_steps',
        where: 'recipe_id = ?',
        whereArgs: [id],
        orderBy: 'step_number ASC',
      );

      final tags = await db.query(
        'recipe_tags',
        where: 'recipe_id = ?',
        whereArgs: [id],
      );

      return Recipe(
        id: map['id'] as String,
        title: map['title'] as String,
        durationMinutes: map['duration_minutes'] as int,
        imagePath: map['image_path'] as String?,
        description: map['description'] as String?,
        servings: map['servings'] as int?,
        difficulty: map['difficulty'] as String?,
        rating: map['rating'] as double?,
        bookmarked: (map['bookmarked'] as int) == 1,
        liked: (map['liked'] as int) == 1,
        ingredients: ingredients.map((i) => i['name'] as String).toList(),
        steps: steps.map((s) => RecipeStep(
          instruction: s['instruction'] as String,
          timerMinutes: s['timer_minutes'] as int?,
          autoStart: (s['auto_start'] as int) == 1,
        )).toList(),
        tags: tags.map((t) => t['tag'] as String).toList(),
      );
    } catch (e) {
      Logger.error('Failed to get recipe by id: $id', e);
      return null;
    }
  }

  Future<void> updateRecipe(Recipe recipe) async {
    final db = await database;
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    try {
      await db.transaction((txn) async {
        await txn.update(
          'recipes',
          {
            'title': recipe.title,
            'duration_minutes': recipe.durationMinutes,
            'image_path': recipe.imagePath,
            'description': recipe.description,
            'servings': recipe.servings,
            'difficulty': recipe.difficulty,
            'rating': recipe.rating,
            'bookmarked': recipe.bookmarked ? 1 : 0,
            'liked': recipe.liked ? 1 : 0,
            'updated_at': timestamp,
          },
          where: 'id = ?',
          whereArgs: [recipe.id],
        );

        await txn.delete('ingredients', where: 'recipe_id = ?', whereArgs: [recipe.id]);
        await txn.delete('recipe_steps', where: 'recipe_id = ?', whereArgs: [recipe.id]);
        await txn.delete('recipe_tags', where: 'recipe_id = ?', whereArgs: [recipe.id]);

        for (final ingredient in recipe.ingredients) {
          await txn.insert('ingredients', {
            'recipe_id': recipe.id,
            'name': ingredient,
          });
        }

        for (var i = 0; i < recipe.steps.length; i++) {
          final step = recipe.steps[i];
          await txn.insert('recipe_steps', {
            'recipe_id': recipe.id,
            'step_number': i + 1,
            'instruction': step.instruction,
            'timer_minutes': step.timerMinutes,
            'auto_start': step.autoStart ? 1 : 0,
          });
        }

        for (final tag in recipe.tags) {
          await txn.insert('recipe_tags', {
            'recipe_id': recipe.id,
            'tag': tag,
          });
        }
      });

      Logger.info('Recipe updated: ${recipe.title}');
    } catch (e) {
      Logger.error('Failed to update recipe', e);
      rethrow;
    }
  }

  Future<void> deleteRecipe(String id) async {
    final db = await database;

    try {
      await db.delete('recipes', where: 'id = ?', whereArgs: [id]);
      Logger.info('Recipe deleted: $id');
    } catch (e) {
      Logger.error('Failed to delete recipe', e);
      rethrow;
    }
  }

  Future<void> toggleBookmark(String id, bool bookmarked) async {
    final db = await database;

    try {
      await db.update(
        'recipes',
        {'bookmarked': bookmarked ? 1 : 0},
        where: 'id = ?',
        whereArgs: [id],
      );
      Logger.info('Bookmark toggled for recipe: $id');
    } catch (e) {
      Logger.error('Failed to toggle bookmark', e);
      rethrow;
    }
  }

  Future<void> toggleLike(String id, bool liked) async {
    final db = await database;

    try {
      await db.update(
        'recipes',
        {'liked': liked ? 1 : 0},
        where: 'id = ?',
        whereArgs: [id],
      );
      Logger.info('Like toggled for recipe: $id');
    } catch (e) {
      Logger.error('Failed to toggle like', e);
      rethrow;
    }
  }

  Future<List<Recipe>> searchRecipes(String query) async {
    final db = await database;

    try {
      final recipeMaps = await db.rawQuery('''
        SELECT DISTINCT r.* FROM recipes r
        LEFT JOIN ingredients i ON r.id = i.recipe_id
        LEFT JOIN recipe_tags t ON r.id = t.recipe_id
        WHERE r.title LIKE ? OR i.name LIKE ? OR t.tag LIKE ?
        ORDER BY r.created_at DESC
      ''', ['%$query%', '%$query%', '%$query%']);

      final recipes = await Future.wait(recipeMaps.map((map) async {
        final ingredients = await db.query(
          'ingredients',
          where: 'recipe_id = ?',
          whereArgs: [map['id']],
        );

        final steps = await db.query(
          'recipe_steps',
          where: 'recipe_id = ?',
          whereArgs: [map['id']],
          orderBy: 'step_number ASC',
        );

        final tags = await db.query(
          'recipe_tags',
          where: 'recipe_id = ?',
          whereArgs: [map['id']],
        );

        return Recipe(
          id: map['id'] as String,
          title: map['title'] as String,
          durationMinutes: map['duration_minutes'] as int,
          imagePath: map['image_path'] as String?,
          description: map['description'] as String?,
          servings: map['servings'] as int?,
          difficulty: map['difficulty'] as String?,
          rating: map['rating'] as double?,
          bookmarked: (map['bookmarked'] as int) == 1,
          liked: (map['liked'] as int) == 1,
          ingredients: ingredients.map((i) => i['name'] as String).toList(),
          steps: steps.map((s) => RecipeStep(
            instruction: s['instruction'] as String,
            timerMinutes: s['timer_minutes'] as int?,
            autoStart: (s['auto_start'] as int) == 1,
          )).toList(),
          tags: tags.map((t) => t['tag'] as String).toList(),
        );
      }));

      Logger.info('Search found ${recipes.length} recipes');
      return recipes;
    } catch (e) {
      Logger.error('Failed to search recipes', e);
      return [];
    }
  }

  Future<void> addCookingHistory({
    required String recipeId,
    String? photoPath,
    int? rating,
    String? notes,
  }) async {
    final db = await database;

    try {
      await db.insert('cooking_history', {
        'recipe_id': recipeId,
        'completed_at': DateTime.now().millisecondsSinceEpoch,
        'photo_path': photoPath,
        'rating': rating,
        'notes': notes,
      });

      Logger.info('Cooking history added for recipe: $recipeId');
    } catch (e) {
      Logger.error('Failed to add cooking history', e);
      rethrow;
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    Logger.info('Database closed');
  }
}
