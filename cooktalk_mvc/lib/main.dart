import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_theme.dart';
import 'controllers/app_controller.dart';
import 'controllers/recipe_controller.dart';
import 'controllers/cooking_assistant_controller.dart';
import 'controllers/auth_controller.dart';
import 'views/home_view.dart';
import 'core/config/app_config.dart';
import 'core/config/firebase_options.dart';
import 'core/utils/logger.dart';
import 'core/providers/repository_providers.dart';
import 'data/services/firestore_service.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/recipe_repository.dart';
import 'data/repositories/feed_repository.dart';
import 'data/repositories/cooking_session_repository.dart';
import 'data/services/gemini_service.dart';
import 'data/services/voice_orchestrator.dart';
import 'data/services/youtube_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await AppConfig.initialize();
    AppConfig.validateConfig();
    Logger.info('App configuration initialized successfully');
  } catch (e) {
    Logger.error('Failed to initialize app config', e);
  }
  
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      Logger.info('Firebase initialized successfully');

      final firestoreService = FirestoreService();
      await firestoreService.enableOfflinePersistence();
    } else {
      Logger.info('Firebase already initialized');
    }

    // 자동 익명 로그인 - 사용자가 로그인하지 않은 경우
    final auth = firebase_auth.FirebaseAuth.instance;
    if (auth.currentUser == null) {
      try {
        final userCredential = await auth.signInAnonymously();
        Logger.info('Auto signed in anonymously: ${userCredential.user?.uid}');
        
        // Create user document if it doesn't exist
        if (userCredential.user != null) {
          try {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(userCredential.user!.uid)
                .get();
            
            if (!userDoc.exists) {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userCredential.user!.uid)
                  .set({
                'uid': userCredential.user!.uid,
                'displayName': '익명 사용자',
                'email': '',
                'photoURL': '',
                'bio': '',
                'followerCount': 0,
                'followingCount': 0,
                'createdRecipeCount': 0,
                'likedRecipeCount': 0,
                'bookmarkedRecipeCount': 0,
                'preferences': {
                  'locale': 'ko-KR',
                  'favoriteTags': <String>[],
                  'weeklyGoal': 3,
                },
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              });
              Logger.info('User document created for anonymous user');
            }
          } catch (e) {
            Logger.warning('Failed to create user document: $e');
          }
        }
        
        // Wait a bit to ensure auth state propagates
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        Logger.error('Failed to auto sign in anonymously', e);
        // 익명 로그인 실패해도 앱은 계속 작동
        // Firebase Console에서 Anonymous Authentication을 활성화하세요
        Logger.warning('⚠️  IMPORTANT: Enable Anonymous Authentication in Firebase Console');
        Logger.warning('   Go to: Firebase Console > Authentication > Sign-in method > Anonymous');
        Logger.info('App will continue without authentication (limited functionality)');
      }
    } else {
      Logger.info('User already signed in: ${auth.currentUser?.uid} (isAnonymous: ${auth.currentUser?.isAnonymous})');
      
      // Ensure user document exists for already signed-in user
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(auth.currentUser!.uid)
            .get();
        
        if (!userDoc.exists) {
          Logger.warning('User document missing for ${auth.currentUser!.uid}, creating...');
          await FirebaseFirestore.instance
              .collection('users')
              .doc(auth.currentUser!.uid)
              .set({
            'uid': auth.currentUser!.uid,
            'displayName': auth.currentUser!.displayName ?? '사용자',
            'email': auth.currentUser!.email ?? '',
            'photoURL': auth.currentUser!.photoURL ?? '',
            'bio': '',
            'followerCount': 0,
            'followingCount': 0,
            'createdRecipeCount': 0,
            'likedRecipeCount': 0,
            'bookmarkedRecipeCount': 0,
            'preferences': {
              'locale': 'ko-KR',
              'favoriteTags': <String>[],
              'weeklyGoal': 3,
            },
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          Logger.info('User document created');
        }
      } catch (e) {
        Logger.warning('Failed to ensure user document exists: $e');
      }
    }
  } catch (e) {
    Logger.error('Failed to initialize Firebase', e);
  }
  
  runApp(const CookTalkApp());
}

class CookTalkApp extends StatelessWidget {
  const CookTalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ========== Repositories & Services (Layer 1) ==========
        ...RepositoryProviders.providers,
        
        // ========== Firebase Auth Stream (Layer 2) ==========
        StreamProvider<firebase_auth.User?>(
          create: (_) => firebase_auth.FirebaseAuth.instance.authStateChanges(),
          initialData: null,
        ),
        
        // ========== Controllers with Dependency Injection (Layer 3) ==========
        
        // AppController - 단순 상태 관리 (의존성 없음)
        ChangeNotifierProvider<AppController>(
          create: (_) => AppController()..initialize(),
        ),
        
        // AuthController - AuthRepository 의존성 주입
        ChangeNotifierProxyProvider<AuthRepository, AuthController>(
          create: (context) => AuthController(
            context.read<AuthRepository>(),
          ),
          update: (context, authRepo, previous) {
            if (previous == null) {
              return AuthController(authRepo);
            }
            previous.updateRepository(authRepo);
            return previous;
          },
        ),
        
        // RecipeController - RecipeRepository, FeedRepository, YouTubeService 의존성 주입
        ChangeNotifierProxyProvider3<RecipeRepository, FeedRepository, YouTubeService, RecipeController>(
          create: (context) => RecipeController(
            context.read<RecipeRepository>(),
            context.read<FeedRepository>(),
            context.read<YouTubeService>(),
          )..bootstrap(),
          update: (context, recipeRepo, feedRepo, youtube, previous) {
            if (previous == null) {
              return RecipeController(recipeRepo, feedRepo, youtube)..bootstrap();
            }
            previous.updateRepositories(
              recipeRepo: recipeRepo,
              feedRepo: feedRepo,
              youtube: youtube,
            );
            return previous;
          },
        ),
        
        // CookingAssistantController - GeminiService, CookingSessionRepository, VoiceOrchestrator 의존성 주입
        ChangeNotifierProxyProvider3<GeminiService, CookingSessionRepository, VoiceOrchestrator, CookingAssistantController>(
          create: (context) => CookingAssistantController(
            context.read<GeminiService>(),
            context.read<CookingSessionRepository>(),
            context.read<VoiceOrchestrator>(),
          )..initialize(),
          update: (context, gemini, sessionRepo, voiceOrch, previous) {
            if (previous == null) {
              return CookingAssistantController(gemini, sessionRepo, voiceOrch)..initialize();
            }
            previous.updateServices(
              gemini: gemini,
              sessionRepo: sessionRepo,
              voiceOrchestrator: voiceOrch,
            );
            return previous;
          },
        ),
      ],
      child: Builder(
        builder: (context) {
          final app = context.watch<AppController>();
          return MaterialApp(
            title: 'CookTalk',
            debugShowCheckedModeBanner: false,
            themeMode: app.themeMode,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            locale: const Locale('ko', 'KR'),
            supportedLocales: const [
              Locale('ko', 'KR'),
              Locale('en', 'US'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const HomeView(),
          );
        },
      ),
    );
  }
}
