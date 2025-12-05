class RecipeValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const RecipeValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  bool get hasWarnings => warnings.isNotEmpty;
}

class RecipeValidator {
  static RecipeValidationResult validate({
    required String title,
    required List<String> ingredients,
    required List<String> steps,
    int? durationMinutes,
    int? servings,
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    if (title.trim().isEmpty) {
      errors.add('레시피 제목을 입력해주세요');
    } else if (title.trim().length < 2) {
      errors.add('레시피 제목은 2자 이상이어야 합니다');
    } else if (title.length > 100) {
      warnings.add('레시피 제목이 너무 깁니다 (100자 이하 권장)');
    }

    if (ingredients.isEmpty) {
      errors.add('최소 1개 이상의 재료를 추가해주세요');
    } else {
      final validIngredients = ingredients.where((i) => i.trim().isNotEmpty).toList();
      if (validIngredients.isEmpty) {
        errors.add('유효한 재료를 입력해주세요');
      } else if (validIngredients.length > 50) {
        warnings.add('재료가 너무 많습니다 (${validIngredients.length}개). 정말 필요한지 확인해주세요');
      }
    }

    if (steps.isEmpty) {
      errors.add('최소 1개 이상의 조리 단계를 추가해주세요');
    } else {
      final validSteps = steps.where((s) => s.trim().isNotEmpty).toList();
      if (validSteps.isEmpty) {
        errors.add('유효한 조리 단계를 입력해주세요');
      } else if (validSteps.length > 30) {
        warnings.add('조리 단계가 너무 많습니다 (${validSteps.length}개). 간결하게 정리해보세요');
      }
      
      for (int i = 0; i < validSteps.length; i++) {
        if (validSteps[i].length < 5) {
          warnings.add('${i + 1}번째 단계가 너무 짧습니다. 자세한 설명을 추가해주세요');
        }
      }
    }

    if (durationMinutes != null) {
      if (durationMinutes <= 0) {
        errors.add('소요 시간은 1분 이상이어야 합니다');
      } else if (durationMinutes > 600) {
        warnings.add('소요 시간이 10시간을 초과합니다. 정확한지 확인해주세요');
      }
    }

    if (servings != null) {
      if (servings <= 0) {
        errors.add('인분은 1인분 이상이어야 합니다');
      } else if (servings > 100) {
        warnings.add('인분이 100인분을 초과합니다. 정확한지 확인해주세요');
      }
    }

    return RecipeValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  static bool isValidTitle(String title) {
    return title.trim().length >= 2 && title.length <= 100;
  }

  static bool hasMinimumIngredients(List<String> ingredients) {
    return ingredients.where((i) => i.trim().isNotEmpty).isNotEmpty;
  }

  static bool hasMinimumSteps(List<String> steps) {
    return steps.where((s) => s.trim().isNotEmpty).isNotEmpty;
  }
}
