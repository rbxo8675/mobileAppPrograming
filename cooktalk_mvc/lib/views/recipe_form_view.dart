import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/recipe.dart';
import '../controllers/recipe_controller.dart';

class RecipeFormView extends StatefulWidget {
  final Recipe? recipe;

  const RecipeFormView({super.key, this.recipe});

  @override
  State<RecipeFormView> createState() => _RecipeFormViewState();
}

class _RecipeFormViewState extends State<RecipeFormView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _title;
  late TextEditingController _desc;
  late TextEditingController _duration;
  late TextEditingController _servings;
  late TextEditingController _ingredients;
  late TextEditingController _steps;
  late String _difficulty;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    final r = widget.recipe;
    _title = TextEditingController(text: r?.title ?? '');
    _desc = TextEditingController(text: r?.description ?? '');
    _duration = TextEditingController(text: r?.durationMinutes.toString() ?? '30');
    _servings = TextEditingController(text: r?.servings?.toString() ?? '2');
    _ingredients = TextEditingController(text: r?.ingredients.join('\n') ?? '');
    _steps = TextEditingController(text: r?.stepsAsStrings.join('\n') ?? '');
    _difficulty = r?.difficulty ?? 'Medium';
    _imagePath = r?.imagePath;
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _duration.dispose();
    _servings.dispose();
    _ingredients.dispose();
    _steps.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.recipe != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Recipe' : 'Add Recipe'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title *', hintText: 'Delicious recipe name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter title' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _desc,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 12),
              _ImagePickerTile(
                path: _imagePath,
                onPick: () async {
                  final res = await FilePicker.platform.pickFiles(type: FileType.image);
                  if (res != null && res.files.single.path != null) {
                    setState(() => _imagePath = res.files.single.path);
                  }
                },
                onClear: () => setState(() => _imagePath = null),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _duration,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Duration (min)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _servings,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Servings'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _difficulty,
                items: const [
                  DropdownMenuItem(value: 'Easy', child: Text('Easy')),
                  DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'Hard', child: Text('Hard')),
                ],
                onChanged: (v) => setState(() => _difficulty = v ?? 'Medium'),
                decoration: const InputDecoration(labelText: 'Difficulty'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ingredients,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Ingredients',
                  hintText: 'Comma or newline separated',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _steps,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Steps',
                  hintText: 'Each line is one step',
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      child: Text(isEditing ? 'Update' : 'Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    List<String> _splitLinesOrComma(String raw) {
      if (raw.contains(',')) {
        return raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
      return raw.split(RegExp(r'[\r\n]+')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }

    final ingredients = _splitLinesOrComma(_ingredients.text);
    final steps = _splitLinesOrComma(_steps.text);
    final controller = context.read<RecipeController>();

    if (widget.recipe != null) {
      // Update existing recipe
      final updatedRecipe = widget.recipe!.copyWith(
        title: _title.text.trim(),
        durationMinutes: int.tryParse(_duration.text) ?? 30,
        ingredients: ingredients,
        steps: steps.map((s) => RecipeStep(instruction: s)).toList(), // Re-create steps
        imagePath: _imagePath,
        description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        servings: int.tryParse(_servings.text),
        difficulty: _difficulty,
      );
      
      controller.updateRecipe(updatedRecipe);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe updated')),
      );
    } else {
      // Add new recipe
      controller.addManualRecipe(
        title: _title.text.trim(),
        durationMinutes: int.tryParse(_duration.text) ?? 30,
        ingredients: ingredients,
        steps: steps,
        imagePath: _imagePath,
        description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe added')),
      );
    }

    Navigator.pop(context);
  }
}

class _ImagePickerTile extends StatelessWidget {
  const _ImagePickerTile({required this.path, required this.onPick, required this.onClear});
  final String? path; final VoidCallback onPick; final VoidCallback onClear;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant),
        ),
        alignment: Alignment.center,
        child: path == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.upload, size: 28),
                  SizedBox(height: 8),
                  Text('Tap to upload image'),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.image),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      path!,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(onPressed: onClear, icon: const Icon(Icons.close)),
                ],
              ),
      ),
    );
  }
}