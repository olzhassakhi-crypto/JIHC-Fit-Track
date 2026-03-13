import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'firebase_options.dart';

final firestore = FirebaseFirestore.instance;

Future<void> addExercise() async {
  await firestore.collection('exercises').add({
    'name': 'Берпи',
    'category': 'Кардио',
    'durationMinutes': 12,
    'level': 'Средний',
    'rounds': 6,
    'reps': 12,
    'kcal': 125,
    'equipment': 'Вес тела',
    'description': 'Общая выносливость',
    'coachTip': 'Приземляйтесь мягко и держите ровный ритм.',
    'videoUrl': 'https://your-video-link',
    'isFavorite': false,
    'createdAt': FieldValue.serverTimestamp(),
  });
}

Future<void> updateExercise(String docId) async {
  await firestore.collection('exercises').doc(docId).update({
    'isFavorite': true,
    'level': 'Продвинутый',
    'updatedAt': FieldValue.serverTimestamp(),
  });
}

Future<void> saveWorkoutSession() async {
  await firestore.collection('workout_sessions').add({
    'exerciseName': 'Берпи',
    'category': 'Кардио',
    'status': 'completed',
    'round': 2,
    'totalRounds': 8,
    'timerSeconds': 16,
    'createdAt': FieldValue.serverTimestamp(),
  });
}

// ============================================================
// ENTRY POINT
// ============================================================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const JIHCFitTrackApp());
}

// ============================================================
// APP ROOT
// ============================================================
class JIHCFitTrackApp extends StatefulWidget {
  const JIHCFitTrackApp({super.key});

  @override
  State<JIHCFitTrackApp> createState() => _JIHCFitTrackAppState();
}

class _JIHCFitTrackAppState extends State<JIHCFitTrackApp> {
  late final UserProfile _profile;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _profile = UserProfile();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    await _profile.loadFromStorage();
    if (!mounted) return;
    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return AnimatedBuilder(
      animation: _profile,
      builder: (context, _) {
        AppTheme.setDarkMode(_profile.isDarkMode);
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: _profile.isDarkMode
                ? Brightness.light
                : Brightness.dark,
            systemNavigationBarColor: AppTheme.background,
            systemNavigationBarIconBrightness: _profile.isDarkMode
                ? Brightness.light
                : Brightness.dark,
          ),
        );

        return MaterialApp(
          title: 'JIHC FitTrack',
          debugShowCheckedModeBanner: false,
          themeMode: _profile.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: _profile.onboardingCompleted
              ? HomeScreen(profile: _profile)
              : OnboardingFlow(profile: _profile),
        );
      },
    );
  }
}

// ============================================================
// THEME
// ============================================================
class AppPalette {
  final Color background;
  final Color surface;
  final Color surfaceVar;
  final Color accent;
  final Color onAccent;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color border;

  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceVar,
    required this.accent,
    required this.onAccent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
  });
}

class AppTheme {
  static const AppPalette dark = AppPalette(
    background: Color(0xFF000000),
    surface: Color(0xFF1C1C1E),
    surfaceVar: Color(0xFF2C2C2E),
    accent: Color(0xFF3B82F6),
    onAccent: Colors.white,
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF8E8E93),
    textTertiary: Color(0xFF636366),
    border: Color(0xFF38383A),
  );

  // Light mode is intentionally slightly darker than pure white to reduce eye strain.
  static const AppPalette light = AppPalette(
    background: Color(0xFFF2F4F8),
    surface: Color(0xFFE5EAF2),
    surfaceVar: Color(0xFFD8DEE8),
    accent: Color(0xFF2F6EEB),
    onAccent: Colors.white,
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF4B5565),
    textTertiary: Color(0xFF6E7888),
    border: Color(0xFFC6CEDA),
  );

  static bool _isDarkMode = true;

  static void setDarkMode(bool isDark) {
    _isDarkMode = isDark;
  }

  static AppPalette get _palette => _isDarkMode ? dark : light;

  static Color get background => _palette.background;
  static Color get surface => _palette.surface;
  static Color get surfaceVar => _palette.surfaceVar;
  static Color get accent => _palette.accent;
  static Color get onAccent => _palette.onAccent;
  static Color get textPrimary => _palette.textPrimary;
  static Color get textSecondary => _palette.textSecondary;
  static Color get textTertiary => _palette.textTertiary;
  static Color get border => _palette.border;

  static ThemeData get darkTheme => _themeFromPalette(dark, Brightness.dark);
  static ThemeData get lightTheme => _themeFromPalette(light, Brightness.light);

  static ThemeData _themeFromPalette(
    AppPalette palette,
    Brightness brightness,
  ) {
    final ColorScheme scheme =
        ColorScheme.fromSeed(
          seedColor: palette.accent,
          brightness: brightness,
        ).copyWith(
          primary: palette.accent,
          onPrimary: palette.onAccent,
          secondary: palette.accent,
          onSecondary: palette.onAccent,
          surface: palette.surface,
          onSurface: palette.textPrimary,
          outline: palette.border,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: palette.background,
      colorScheme: scheme,
    );
  }
}

// ============================================================
// MODEL
// ============================================================
enum WeightUnit { kg }

enum DistanceUnit { km }

enum BodyUnit { cm }

enum Gender { male, female }

enum FitnessGoal { buildMuscle, buildStrength, loseFat }

enum ExperienceLevel { beginner, intermediate, advanced }

enum WorkoutPref { selfMade, guided }

enum TrainingPlace { dormitory, home, gym }

enum AppLanguage { english, russian, kazakh }

class AppI18n {
  static const Map<AppLanguage, Map<String, String>> _texts = {
    AppLanguage.english: {
      'continue': 'Continue',
      'skip': 'Skip',
      'save_program': 'Save Program',
      'your_data_private': 'Your data is private and secure.',
      'select_units': 'Select Units',
      'weight': 'Weight',
      'height': 'Height',
      'gender': 'Gender',
      'birthday': 'Birthday',
      'distance': 'Distance',
      'body_measurements': 'Body measurements',
      'kg': 'kg',
      'kilometers': 'kilometers',
      'cm': 'cm',
      'gender_title': "What's your gender?",
      'male': 'Male',
      'female': 'Female',
      'birthday_title': "When's your birthday?",
      'weight_title': "What's your weight?",
      'height_title': "What's your height?",
      'kilograms': 'Kilograms',
      'centimeters': 'Centimeters',
      'goal_title': 'What is your\nmain goal?',
      'build_muscle': 'Build Muscle',
      'build_strength': 'Build Strength',
      'lose_fat': 'Weight Loss',
      'experience_title': 'What is your\ntraining experience?',
      'beginner': 'Beginner',
      'intermediate': 'Intermediate',
      'advanced': 'Advanced',
      'experience_0_1': '0-1 year',
      'experience_1_3': '1-3 years',
      'experience_3_plus': 'More than 3 years',
      'workout_pref_title':
          'Do you want to\ncreate your own\nworkouts or get\nguidance?',
      'workout_self_made': 'I want to create my own workouts',
      'workout_guided': 'I want guided workouts',
      'equipment_title': 'What equipment\ndo you have?',
      'select_all_apply': 'Select all that apply',
      'full_gym': 'Full Gym',
      'barbell': 'Barbell',
      'dumbbells': 'Dumbbells',
      'machine': 'Machine',
      'resistance_bands': 'Resistance Bands',
      'bodyweight': 'Bodyweight',
      'place_title': 'Where do you usually train?',
      'dormitory': 'Dormitory',
      'home': 'Home',
      'gym': 'Gym',
      'training_style': 'Training Style',
      'style_dormitory_title': 'Compact bodyweight plan',
      'style_dormitory_desc':
          'Low-noise circuits with bodyweight and mobility work.',
      'style_home_title': 'Home hybrid plan',
      'style_home_desc': 'Dumbbell + bodyweight supersets for limited space.',
      'style_gym_title': 'Gym performance plan',
      'style_gym_desc': 'Strength-focused workouts using full gym equipment.',
      'frequency_title': 'How often do you\nwant to train?',
      'days_per_week': '{days} per week',
      'recommended': 'Recommended',
      'duration_title': 'How long would\nyou like to train?',
      'duration_40': '40 min',
      'duration_60': '1h 0min',
      'duration_80': '1h 20min',
      'muscle_focus_title': 'Which muscle group\ndo you want to\nfocus on?',
      'muscle_focus_subtitle':
          'Program will be full-body but you can highlight one area.',
      'balanced_program': 'Balanced Program',
      'core': 'Core',
      'chest': 'Chest',
      'arms': 'Arms',
      'back': 'Back',
      'shoulders': 'Shoulders',
      'legs': 'Legs',
      'glutes': 'Glutes',
      'generating_program': 'We are preparing\nyour personalized\nprogram',
      'recommended_program': 'Recommended Program',
      'your_personal_program': 'Your Personal\nWorkout Program',
      'boost_goal':
          'Boost your {goal} with a personalized program tailored to your experience level.',
      'goal': 'Goal',
      'equipment': 'Equipment',
      'level': 'Level',
      'workouts_week': 'Workouts /\nweek',
      'training_strategy': 'Training Strategy',
      'progressive_overload': 'Progressive Overload',
      'progressive_desc': 'To achieve consistent progress',
      'welcome_title': 'Welcome to\nJIHC FitTrack!',
      'welcome_subtitle': 'Easily log your workouts,\ntracking every set.',
      'welcome_mock_title': 'Bench Press (Barbell)',
      'welcome_mock_note': 'Feeling stronger! Great session today',
      'rest_timer': 'Rest Timer: 2min 30s',
      'sets': 'SETS',
      'reps': 'REPS',
      'tab_home': 'Home',
      'tab_workouts': 'Workouts',
      'tab_progress': 'Progress',
      'tab_profile': 'Profile',
      'good_morning': 'Good morning!',
      'this_week': 'This Week',
      'workouts': 'workouts',
      'your_program': 'Your Program',
      'per_week_short': 'Per Week',
      'duration': 'Duration',
      'completed': 'Completed',
      'calories': 'Calories',
      'today_plan': 'Today Plan',
      'complete_onboarding_plan':
          'Complete onboarding preferences to generate a plan.',
      'no_plan_yet': 'No Plan Yet',
      'today_plan_done': 'Today plan completed',
      'start_with': 'Start: {title}',
      'open_library': 'Open full exercise library and categories',
      'exercise_library': 'Exercise Library',
      'exercise_library_desc':
          'Categories, guided videos, and equipment-based recommendations.',
      'search_hint': 'Search exercise or muscle...',
      'show_available': 'Showing only available equipment',
      'show_all': 'Showing all exercises',
      'smart_recommended': 'Smart Recommended',
      'no_filter_match':
          'No exercises match your current filter.\nTry another category or disable equipment filtering.',
      'not_in_equipment': 'Not in your equipment setup',
      'match': 'Match {value}',
      'done_x': 'Done {value}x',
      'done': 'Done',
      'video': 'Video',
      'progress_desc':
          'Track completed exercises, weekly targets, and category stats.',
      'weekly_target': '{completed}/{target} weekly target',
      'minutes': 'Minutes',
      'favorites': 'Favorites',
      'streak': 'Streak',
      'consistency': 'Consistency',
      'days': '{value} days',
      'category_breakdown': 'Category Breakdown',
      'complete_for_stats': 'Complete an exercise to see category stats.',
      'most_trained': 'Most Trained Exercises',
      'no_frequency_data': 'No exercise frequency data yet.',
      'recent_sessions': 'Recent Sessions',
      'no_sessions': 'No completed sessions yet.',
      'times_done': '{value} done',
      'profile': 'Profile',
      'appearance': 'Appearance',
      'dark_mode': 'Dark mode',
      'light_mode': 'Light mode',
      'language': 'Language',
      'training_place': 'Training Place',
      'account': 'Account',
      'english': 'English',
      'russian': 'Russian',
      'kazakh': 'Kazakh',
      'email': 'Email',
      'password': 'Password',
      'confirm_password': 'Confirm Password',
      'first_name': 'First name',
      'last_name': 'Last name',
      'login': 'Log In',
      'create_account': 'Create Account',
      'switch_to_login': 'Already have an account? Log in',
      'switch_to_register': 'No account yet? Create one',
      'auth_title': 'Welcome back',
      'auth_subtitle': 'Log in to continue your training.',
      'register_title': 'Create your account',
      'register_subtitle': 'Enter your details to start training.',
      'invalid_credentials': 'Incorrect email or password.',
      'empty_credentials': 'Enter both email and password.',
      'fill_all_fields': 'Fill in all required fields.',
      'passwords_not_match': 'Passwords do not match.',
      'account_created': 'Account created. You are now logged in.',
      'logout': 'Log Out',
      'logout_desc': 'Sign out and reset progress results',
      'logout_confirm_title': 'Log out from account?',
      'logout_confirm_message':
          'You will sign out and your workout results will be reset.',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'none': 'None',
      'days_week': 'Days/week',
      'workout_timer': 'Workout Timer',
      'round': 'Round',
      'work': 'Work',
      'rest': 'Rest',
      'session_complete': 'Session complete',
      'start': 'Start',
      'pause': 'Pause',
      'reset': 'Reset',
      'next_phase': 'Next',
      'mark_completed': 'Mark as Completed',
      'session_saved': 'Session saved to progress',
      'session_saved_once': 'Session already saved',
      'prescription': 'Prescription: {sets} • {reps}',
      'coach_tip': 'Coach tip: {tip}',
      'timer_auto_saved': 'Timer complete, session saved',
      'video_embed_failed':
          'Video could not be loaded on this device. Please retry.',
      'retry_video': 'Retry Video',
      'delete': 'Delete',
      'category_all': 'All',
      'month_1': 'January',
      'month_2': 'February',
      'month_3': 'March',
      'month_4': 'April',
      'month_5': 'May',
      'month_6': 'June',
      'month_7': 'July',
      'month_8': 'August',
      'month_9': 'September',
      'month_10': 'October',
      'month_11': 'November',
      'month_12': 'December',
      'strength': 'Strength',
      'cardio': 'Cardio',
      'mobility': 'Mobility',
      'private_mode': 'Private',
    },
    AppLanguage.russian: {
      'continue': 'Продолжить',
      'skip': 'Пропустить',
      'save_program': 'Сохранить программу',
      'your_data_private': 'Ваши данные защищены и конфиденциальны.',
      'select_units': 'Выберите единицы',
      'weight': 'Вес',
      'height': 'Рост',
      'gender': 'Пол',
      'birthday': 'Дата рождения',
      'distance': 'Дистанция',
      'body_measurements': 'Измерения тела',
      'kg': 'кг',
      'kilometers': 'километры',
      'cm': 'см',
      'gender_title': 'Ваш пол?',
      'male': 'Мужской',
      'female': 'Женский',
      'birthday_title': 'Когда у вас день рождения?',
      'weight_title': 'Какой у вас вес?',
      'height_title': 'Какой у вас рост?',
      'kilograms': 'Килограммы',
      'centimeters': 'Сантиметры',
      'goal_title': 'Какая ваша\nглавная цель?',
      'build_muscle': 'Набор мышц',
      'build_strength': 'Развитие силы',
      'lose_fat': 'Похудение',
      'experience_title': 'Какой у вас\nтренировочный опыт?',
      'beginner': 'Новичок',
      'intermediate': 'Средний',
      'advanced': 'Продвинутый',
      'experience_0_1': '0-1 год',
      'experience_1_3': '1-3 года',
      'experience_3_plus': 'Более 3 лет',
      'workout_pref_title':
          'Хотите создавать\nсвои тренировки\nили получить\nготовые планы?',
      'workout_self_made': 'Хочу составлять тренировки сам',
      'workout_guided': 'Хочу тренировки с подсказками',
      'equipment_title': 'Какое оборудование\nу вас есть?',
      'select_all_apply': 'Выберите все подходящие варианты',
      'full_gym': 'Полный зал',
      'barbell': 'Штанга',
      'dumbbells': 'Гантели',
      'machine': 'Тренажеры',
      'resistance_bands': 'Резинки',
      'bodyweight': 'Вес тела',
      'place_title': 'Где вы чаще всего тренируетесь?',
      'dormitory': 'Общежитие',
      'home': 'Дом',
      'gym': 'Зал',
      'training_style': 'Стиль тренировки',
      'style_dormitory_title': 'Компактный план без шума',
      'style_dormitory_desc':
          'Тихие круговые тренировки с весом тела и мобилити.',
      'style_home_title': 'Домашний гибридный план',
      'style_home_desc':
          'Суперсеты гантели + вес тела для малого пространства.',
      'style_gym_title': 'План для зала',
      'style_gym_desc': 'Силовой фокус с использованием оборудования зала.',
      'frequency_title': 'Как часто вы\nхотите тренироваться?',
      'days_per_week': '{days} раз в неделю',
      'recommended': 'Рекомендуется',
      'duration_title': 'Сколько времени\nхотите тренироваться?',
      'duration_40': '40 мин',
      'duration_60': '1ч 0мин',
      'duration_80': '1ч 20мин',
      'muscle_focus_title': 'На какую группу\nмышц хотите\nсделать акцент?',
      'muscle_focus_subtitle':
          'Программа будет на все тело, но можно выделить одну зону.',
      'balanced_program': 'Сбалансированная программа',
      'core': 'Кор',
      'chest': 'Грудь',
      'arms': 'Руки',
      'back': 'Спина',
      'shoulders': 'Плечи',
      'legs': 'Ноги',
      'glutes': 'Ягодицы',
      'generating_program': 'Мы готовим вашу\nперсональную\nпрограмму',
      'recommended_program': 'Рекомендуемая программа',
      'your_personal_program': 'Ваша персональная\nпрограмма тренировок',
      'boost_goal':
          'Усильте цель "{goal}" с персональной программой под ваш уровень.',
      'goal': 'Цель',
      'equipment': 'Оборудование',
      'level': 'Уровень',
      'workouts_week': 'Тренировок /\nнеделя',
      'training_strategy': 'Стратегия тренировок',
      'progressive_overload': 'Прогрессивная нагрузка',
      'progressive_desc': 'Для стабильного прогресса',
      'welcome_title': 'Добро пожаловать\nв JIHC FitTrack!',
      'welcome_subtitle':
          'Удобно записывайте тренировки,\nотслеживайте каждый подход.',
      'welcome_mock_title': 'Жим штанги лежа',
      'welcome_mock_note': 'Чувствую прогресс! Отличная тренировка сегодня',
      'rest_timer': 'Таймер отдыха: 2мин 30с',
      'sets': 'ПОДХОДЫ',
      'reps': 'ПОВТОРЫ',
      'tab_home': 'Главная',
      'tab_workouts': 'Тренировки',
      'tab_progress': 'Прогресс',
      'tab_profile': 'Профиль',
      'good_morning': 'Доброе утро!',
      'this_week': 'Эта неделя',
      'workouts': 'тренировок',
      'your_program': 'Ваша программа',
      'per_week_short': 'В неделю',
      'duration': 'Длительность',
      'completed': 'Выполнено',
      'calories': 'Калории',
      'today_plan': 'План на сегодня',
      'complete_onboarding_plan':
          'Завершите настройку, чтобы сформировать план.',
      'no_plan_yet': 'Плана пока нет',
      'today_plan_done': 'План на сегодня выполнен',
      'start_with': 'Начать: {title}',
      'open_library': 'Открыть библиотеку упражнений и категории',
      'exercise_library': 'Библиотека упражнений',
      'exercise_library_desc':
          'Категории, обучающие видео и рекомендации по оборудованию.',
      'search_hint': 'Поиск упражнения или мышцы...',
      'show_available': 'Показывать только доступное оборудование',
      'show_all': 'Показывать все упражнения',
      'smart_recommended': 'Умный подбор',
      'no_filter_match':
          'По текущим фильтрам ничего не найдено.\nВыберите другую категорию или отключите фильтр оборудования.',
      'not_in_equipment': 'Нет в вашем наборе оборудования',
      'match': 'Совпадение {value}',
      'done_x': 'Сделано {value}x',
      'done': 'Готово',
      'video': 'Видео',
      'progress_desc':
          'Отслеживайте выполненные упражнения, недельные цели и статистику.',
      'weekly_target': '{completed}/{target} недельная цель',
      'minutes': 'Минуты',
      'favorites': 'Избранное',
      'streak': 'Серия',
      'consistency': 'Стабильность',
      'days': '{value} дн.',
      'category_breakdown': 'Статистика по категориям',
      'complete_for_stats': 'Выполните упражнение, чтобы увидеть статистику.',
      'most_trained': 'Самые частые упражнения',
      'no_frequency_data': 'Пока нет данных по частоте упражнений.',
      'recent_sessions': 'Последние сессии',
      'no_sessions': 'Пока нет завершенных сессий.',
      'times_done': '{value} выполнено',
      'profile': 'Профиль',
      'appearance': 'Внешний вид',
      'dark_mode': 'Темная тема',
      'light_mode': 'Светлая тема',
      'language': 'Язык',
      'training_place': 'Место тренировки',
      'account': 'Аккаунт',
      'english': 'Английский',
      'russian': 'Русский',
      'kazakh': 'Казахский',
      'email': 'Email',
      'password': 'Пароль',
      'confirm_password': 'Повторите пароль',
      'first_name': 'Имя',
      'last_name': 'Фамилия',
      'login': 'Войти',
      'create_account': 'Создать аккаунт',
      'switch_to_login': 'Уже есть аккаунт? Войти',
      'switch_to_register': 'Нет аккаунта? Создать',
      'auth_title': 'С возвращением',
      'auth_subtitle': 'Войдите, чтобы продолжить тренировки.',
      'register_title': 'Создайте аккаунт',
      'register_subtitle': 'Введите данные, чтобы начать тренировки.',
      'invalid_credentials': 'Неверный email или пароль.',
      'empty_credentials': 'Введите email и пароль.',
      'fill_all_fields': 'Заполните все обязательные поля.',
      'passwords_not_match': 'Пароли не совпадают.',
      'account_created': 'Аккаунт создан. Вы вошли в систему.',
      'logout': 'Выйти',
      'logout_desc': 'Выйти и сбросить результаты прогресса',
      'logout_confirm_title': 'Выйти из аккаунта?',
      'logout_confirm_message':
          'Вы выйдете из аккаунта, а результаты тренировок будут сброшены.',
      'cancel': 'Отмена',
      'confirm': 'Подтвердить',
      'none': 'Нет',
      'days_week': 'Дней/неделя',
      'workout_timer': 'Таймер тренировки',
      'round': 'Раунд',
      'work': 'Работа',
      'rest': 'Отдых',
      'session_complete': 'Сессия завершена',
      'start': 'Старт',
      'pause': 'Пауза',
      'reset': 'Сброс',
      'next_phase': 'Далее',
      'mark_completed': 'Отметить как выполнено',
      'session_saved': 'Сессия сохранена в прогрессе',
      'session_saved_once': 'Сессия уже сохранена',
      'prescription': 'План: {sets} • {reps}',
      'coach_tip': 'Совет тренера: {tip}',
      'timer_auto_saved': 'Таймер завершен, сессия сохранена',
      'video_embed_failed':
          'Видео не удалось загрузить на этом устройстве. Повторите попытку.',
      'retry_video': 'Повторить видео',
      'delete': 'Удалить',
      'category_all': 'Все',
      'month_1': 'Январь',
      'month_2': 'Февраль',
      'month_3': 'Март',
      'month_4': 'Апрель',
      'month_5': 'Май',
      'month_6': 'Июнь',
      'month_7': 'Июль',
      'month_8': 'Август',
      'month_9': 'Сентябрь',
      'month_10': 'Октябрь',
      'month_11': 'Ноябрь',
      'month_12': 'Декабрь',
      'strength': 'Сила',
      'cardio': 'Кардио',
      'mobility': 'Мобилити',
      'private_mode': 'Приватный',
    },
    AppLanguage.kazakh: {
      'continue': 'Жалғастыру',
      'skip': 'Өткізу',
      'save_program': 'Бағдарламаны сақтау',
      'your_data_private': 'Деректеріңіз қауіпсіз және құпия.',
      'select_units': 'Өлшем бірліктері',
      'weight': 'Салмақ',
      'height': 'Бой',
      'gender': 'Жыныс',
      'birthday': 'Туған күн',
      'distance': 'Қашықтық',
      'body_measurements': 'Дене өлшемдері',
      'kg': 'кг',
      'kilometers': 'километр',
      'cm': 'см',
      'gender_title': 'Жынысыңыз?',
      'male': 'Ер',
      'female': 'Әйел',
      'birthday_title': 'Туған күніңіз қашан?',
      'weight_title': 'Салмағыңыз қанша?',
      'height_title': 'Бойыңыз қанша?',
      'kilograms': 'Килограмм',
      'centimeters': 'Сантиметр',
      'goal_title': 'Негізгі\nмақсатыңыз қандай?',
      'build_muscle': 'Бұлшықет жинау',
      'build_strength': 'Күшті арттыру',
      'lose_fat': 'Салмақ тастау',
      'experience_title': 'Жаттығу\nтәжірибеңіз қандай?',
      'beginner': 'Бастаушы',
      'intermediate': 'Орташа',
      'advanced': 'Жоғары',
      'experience_0_1': '0-1 жыл',
      'experience_1_3': '1-3 жыл',
      'experience_3_plus': '3 жылдан көп',
      'workout_pref_title':
          'Өз жаттығуыңызды\nжасайсыз ба\nәлде дайын\nнұсқау керек пе?',
      'workout_self_made': 'Жаттығуды өзім құрамын',
      'workout_guided': 'Бағытталған жаттығу керек',
      'equipment_title': 'Қандай жабдық\nбар?',
      'select_all_apply': 'Сәйкесінің бәрін таңдаңыз',
      'full_gym': 'Толық зал',
      'barbell': 'Штанга',
      'dumbbells': 'Гантель',
      'machine': 'Тренажер',
      'resistance_bands': 'Резеңке таспа',
      'bodyweight': 'Өз салмағы',
      'place_title': 'Көбіне қай жерде жаттығасыз?',
      'dormitory': 'Жатақхана',
      'home': 'Үй',
      'gym': 'Зал',
      'training_style': 'Жаттығу стилі',
      'style_dormitory_title': 'Ықшам, дыбыссыз жоспар',
      'style_dormitory_desc':
          'Тыныш шеңберлік жаттығу: өз салмағы және мобилити.',
      'style_home_title': 'Үйге арналған аралас жоспар',
      'style_home_desc':
          'Кіші кеңістікке лайық гантель + өз салмақ суперсеттері.',
      'style_gym_title': 'Залға арналған өнімді жоспар',
      'style_gym_desc': 'Зал жабдығымен күшке бағытталған бағдарлама.',
      'frequency_title': 'Аптасына қанша\nрет жаттығасыз?',
      'days_per_week': 'Аптасына {days} рет',
      'recommended': 'Ұсынылады',
      'duration_title': 'Жаттығу уақыты\nқанша болсын?',
      'duration_40': '40 мин',
      'duration_60': '1сағ 0мин',
      'duration_80': '1сағ 20мин',
      'muscle_focus_title': 'Қай бұлшықет\nтобына басымдық\nбересіз?',
      'muscle_focus_subtitle':
          'Бағдарлама толық денеге, бірақ бір аймақты таңдауға болады.',
      'balanced_program': 'Теңгерімді бағдарлама',
      'core': 'Кор',
      'chest': 'Кеуде',
      'arms': 'Қол',
      'back': 'Арқа',
      'shoulders': 'Иық',
      'legs': 'Аяқ',
      'glutes': 'Бөксе',
      'generating_program':
          'Сізге арналған\nжеке бағдарламаны\nдайындап жатырмыз',
      'recommended_program': 'Ұсынылған бағдарлама',
      'your_personal_program': 'Сіздің жеке\nжаттығу бағдарламаңыз',
      'boost_goal':
          '"{goal}" мақсатына деңгейіңізге сай жеке бағдарламамен тез жетіңіз.',
      'goal': 'Мақсат',
      'equipment': 'Жабдық',
      'level': 'Деңгей',
      'workouts_week': 'Жаттығу /\nапта',
      'training_strategy': 'Жаттығу стратегиясы',
      'progressive_overload': 'Прогрессивті жүктеме',
      'progressive_desc': 'Тұрақты прогреске жету үшін',
      'welcome_title': 'JIHC FitTrack-ке\nқош келдіңіз!',
      'welcome_subtitle': 'Жаттығуды оңай тіркеп,\nәр қайталауды бақылаңыз.',
      'welcome_mock_title': 'Штангамен жатып сығымдау',
      'welcome_mock_note': 'Күш артып жатыр! Бүгінгі жаттығу өте жақсы өтті',
      'rest_timer': 'Демалыс таймері: 2мин 30с',
      'sets': 'СЕТТЕР',
      'reps': 'ҚАЙТАЛАУ',
      'tab_home': 'Басты',
      'tab_workouts': 'Жаттығу',
      'tab_progress': 'Прогресс',
      'tab_profile': 'Профиль',
      'good_morning': 'Қайырлы таң!',
      'this_week': 'Осы апта',
      'workouts': 'жаттығу',
      'your_program': 'Сіздің бағдарлама',
      'per_week_short': 'Аптасына',
      'duration': 'Ұзақтығы',
      'completed': 'Орындалды',
      'calories': 'Калория',
      'today_plan': 'Бүгінгі жоспар',
      'complete_onboarding_plan':
          'Жоспар құру үшін бастапқы баптауды аяқтаңыз.',
      'no_plan_yet': 'Жоспар әлі жоқ',
      'today_plan_done': 'Бүгінгі жоспар орындалды',
      'start_with': 'Бастау: {title}',
      'open_library': 'Толық жаттығу кітапханасын және санаттарды ашу',
      'exercise_library': 'Жаттығу кітапханасы',
      'exercise_library_desc':
          'Санаттар, видео-нұсқаулар және жабдыққа сай ұсыныстар.',
      'search_hint': 'Жаттығу немесе бұлшықет іздеу...',
      'show_available': 'Тек қолжетімді жабдықты көрсету',
      'show_all': 'Барлық жаттығуды көрсету',
      'smart_recommended': 'Ақылды ұсыныс',
      'no_filter_match':
          'Ағымдағы сүзгімен ештеңе табылмады.\nБасқа санатты таңдаңыз немесе жабдық сүзгісін өшіріңіз.',
      'not_in_equipment': 'Сіздің жабдықта жоқ',
      'match': 'Сәйкестік {value}',
      'done_x': 'Орындалды {value}x',
      'done': 'Дайын',
      'video': 'Видео',
      'progress_desc':
          'Орындалған жаттығуларды, апталық мақсатты және статистиканы бақылаңыз.',
      'weekly_target': '{completed}/{target} апталық мақсат',
      'minutes': 'Минут',
      'favorites': 'Таңдаулы',
      'streak': 'Серия',
      'consistency': 'Тұрақтылық',
      'days': '{value} күн',
      'category_breakdown': 'Санат бойынша статистика',
      'complete_for_stats': 'Статистиканы көру үшін жаттығуды орындаңыз.',
      'most_trained': 'Ең жиі орындалатын жаттығулар',
      'no_frequency_data': 'Жаттығу жиілігі туралы дерек әлі жоқ.',
      'recent_sessions': 'Соңғы сессиялар',
      'no_sessions': 'Әзірге аяқталған сессия жоқ.',
      'times_done': '{value} орындалды',
      'profile': 'Профиль',
      'appearance': 'Көрініс',
      'dark_mode': 'Қараңғы режим',
      'light_mode': 'Жарық режим',
      'language': 'Тіл',
      'training_place': 'Жаттығу орны',
      'account': 'Аккаунт',
      'english': 'Ағылшын',
      'russian': 'Орыс',
      'kazakh': 'Қазақ',
      'email': 'Email',
      'password': 'Құпиясөз',
      'confirm_password': 'Құпиясөзді қайталау',
      'first_name': 'Аты',
      'last_name': 'Тегі',
      'login': 'Кіру',
      'create_account': 'Аккаунт ашу',
      'switch_to_login': 'Аккаунт бар ма? Кіру',
      'switch_to_register': 'Аккаунт жоқ па? Құру',
      'auth_title': 'Қайта қош келдіңіз',
      'auth_subtitle': 'Жаттығуды жалғастыру үшін кіріңіз.',
      'register_title': 'Аккаунт ашыңыз',
      'register_subtitle': 'Жаттығуды бастау үшін деректерді енгізіңіз.',
      'invalid_credentials': 'Email немесе құпиясөз қате.',
      'empty_credentials': 'Email және құпиясөзді енгізіңіз.',
      'fill_all_fields': 'Барлық міндетті өрісті толтырыңыз.',
      'passwords_not_match': 'Құпиясөздер сәйкес емес.',
      'account_created': 'Аккаунт құрылды. Сіз жүйеге кірдіңіз.',
      'logout': 'Шығу',
      'logout_desc': 'Жүйеден шығып, прогресс нәтижесін тазалау',
      'logout_confirm_title': 'Аккаунттан шығасыз ба?',
      'logout_confirm_message':
          'Аккаунттан шығасыз, жаттығу нәтижелері қайта басталады.',
      'cancel': 'Бас тарту',
      'confirm': 'Растау',
      'none': 'Жоқ',
      'days_week': 'Күн/апта',
      'workout_timer': 'Жаттығу таймері',
      'round': 'Раунд',
      'work': 'Жұмыс',
      'rest': 'Демалыс',
      'session_complete': 'Сессия аяқталды',
      'start': 'Бастау',
      'pause': 'Тоқтату',
      'reset': 'Қалпына келтіру',
      'next_phase': 'Келесі',
      'mark_completed': 'Орындалды деп белгілеу',
      'session_saved': 'Сессия прогреске сақталды',
      'session_saved_once': 'Сессия бұрын сақталған',
      'prescription': 'Жоспар: {sets} • {reps}',
      'coach_tip': 'Жаттықтырушы кеңесі: {tip}',
      'timer_auto_saved': 'Таймер аяқталды, сессия сақталды',
      'video_embed_failed':
          'Бұл құрылғыда видеоны жүктеу мүмкін болмады. Қайталап көріңіз.',
      'retry_video': 'Видеоны қайта жүктеу',
      'delete': 'Жою',
      'category_all': 'Барлығы',
      'month_1': 'Қаңтар',
      'month_2': 'Ақпан',
      'month_3': 'Наурыз',
      'month_4': 'Сәуір',
      'month_5': 'Мамыр',
      'month_6': 'Маусым',
      'month_7': 'Шілде',
      'month_8': 'Тамыз',
      'month_9': 'Қыркүйек',
      'month_10': 'Қазан',
      'month_11': 'Қараша',
      'month_12': 'Желтоқсан',
      'strength': 'Күш',
      'cardio': 'Кардио',
      'mobility': 'Қозғалғыштық',
      'private_mode': 'Жеке',
    },
  };

  static String t(
    AppLanguage lang,
    String key, {
    Map<String, String> args = const {},
  }) {
    var text = _texts[lang]?[key] ?? _texts[AppLanguage.english]?[key] ?? key;
    for (final entry in args.entries) {
      text = text.replaceAll('{${entry.key}}', entry.value);
    }
    return text;
  }

  static String monthName(AppLanguage lang, int month) {
    return t(lang, 'month_$month');
  }

  static String languageName(AppLanguage lang, AppLanguage value) {
    switch (value) {
      case AppLanguage.english:
        return t(lang, 'english');
      case AppLanguage.russian:
        return t(lang, 'russian');
      case AppLanguage.kazakh:
        return t(lang, 'kazakh');
    }
  }

  static String genderName(AppLanguage lang, Gender? gender) {
    switch (gender) {
      case Gender.male:
        return t(lang, 'male');
      case Gender.female:
        return t(lang, 'female');
      default:
        return '-';
    }
  }

  static String placeName(AppLanguage lang, TrainingPlace place) {
    switch (place) {
      case TrainingPlace.dormitory:
        return t(lang, 'dormitory');
      case TrainingPlace.home:
        return t(lang, 'home');
      case TrainingPlace.gym:
        return t(lang, 'gym');
    }
  }

  static String goalName(AppLanguage lang, FitnessGoal? goal) {
    switch (goal) {
      case FitnessGoal.buildMuscle:
        return t(lang, 'build_muscle');
      case FitnessGoal.buildStrength:
        return t(lang, 'build_strength');
      case FitnessGoal.loseFat:
        return t(lang, 'lose_fat');
      default:
        return t(lang, 'none');
    }
  }

  static String levelName(AppLanguage lang, ExperienceLevel? level) {
    switch (level) {
      case ExperienceLevel.beginner:
        return t(lang, 'beginner');
      case ExperienceLevel.intermediate:
        return t(lang, 'intermediate');
      case ExperienceLevel.advanced:
        return t(lang, 'advanced');
      default:
        return t(lang, 'none');
    }
  }

  static String categoryName(AppLanguage lang, String category) {
    switch (category) {
      case 'All':
        return t(lang, 'category_all');
      case 'Strength':
        return t(lang, 'strength');
      case 'Legs':
        return t(lang, 'legs');
      case 'Back':
        return t(lang, 'back');
      case 'Bodyweight':
        return t(lang, 'bodyweight');
      case 'Core':
        return t(lang, 'core');
      case 'Cardio':
        return t(lang, 'cardio');
      case 'Mobility':
        return t(lang, 'mobility');
      default:
        return category;
    }
  }

  static String equipmentName(AppLanguage lang, String equipment) {
    switch (equipment) {
      case 'Full Gym':
        return t(lang, 'full_gym');
      case 'Barbell':
        return t(lang, 'barbell');
      case 'Dumbbells':
        return t(lang, 'dumbbells');
      case 'Machine':
        return t(lang, 'machine');
      case 'Resistance Bands':
        return t(lang, 'resistance_bands');
      case 'Bodyweight':
        return t(lang, 'bodyweight');
      default:
        return equipment;
    }
  }

  static String muscleName(AppLanguage lang, String muscle) {
    switch (muscle) {
      case 'Core':
        return t(lang, 'core');
      case 'Chest':
        return t(lang, 'chest');
      case 'Arms':
        return t(lang, 'arms');
      case 'Back':
        return t(lang, 'back');
      case 'Shoulders':
        return t(lang, 'shoulders');
      case 'Legs':
        return t(lang, 'legs');
      case 'Glutes':
        return t(lang, 'glutes');
      default:
        return muscle;
    }
  }

  static String exerciseLevelName(AppLanguage lang, String levelRaw) {
    switch (levelRaw.toLowerCase()) {
      case 'beginner':
        return t(lang, 'beginner');
      case 'intermediate':
        return t(lang, 'intermediate');
      case 'advanced':
        return t(lang, 'advanced');
      default:
        return levelRaw;
    }
  }

  static String setsText(AppLanguage lang, String raw) {
    if (lang == AppLanguage.english) return raw;
    if (lang == AppLanguage.russian) {
      return raw
          .replaceAll(' sets', ' подхода')
          .replaceAll(' rounds', ' раундов');
    }
    return raw.replaceAll(' sets', ' сет').replaceAll(' rounds', ' раунд');
  }

  static String repsText(AppLanguage lang, String raw) {
    if (lang == AppLanguage.english) return raw;
    if (lang == AppLanguage.russian) {
      return raw
          .replaceAll(' reps/side', ' повт./сторона')
          .replaceAll(' reps each drill', ' повт. каждый элемент')
          .replaceAll(' reps', ' повт.')
          .replaceAll(' sec hold', ' сек удержание')
          .replaceAll(' sec work', ' сек работа')
          .replaceAll(' sec each move', ' сек каждое движение');
    }
    return raw
        .replaceAll(' reps/side', ' қайт./жақ')
        .replaceAll(' reps each drill', ' қайт. әр қозғалыс')
        .replaceAll(' reps', ' қайт.')
        .replaceAll(' sec hold', ' сек ұстау')
        .replaceAll(' sec work', ' сек жұмыс')
        .replaceAll(' sec each move', ' сек әр қозғалыс');
  }

  static String exerciseTitle(AppLanguage lang, ExerciseItem item) {
    final id = item.id;
    if (lang == AppLanguage.english) return item.title;

    final ru = <String, String>{
      'db_bench_press': 'Жим гантелей лежа',
      'db_rows': 'Тяга гантели одной рукой',
      'db_goblet_squat': 'Гоблет-присед',
      'db_shoulder_press': 'Жим гантелей сидя',
      'barbell_back_squat': 'Присед со штангой',
      'barbell_deadlift': 'Становая тяга',
      'bench_press': 'Жим штанги лежа',
      'machine_leg_press': 'Жим ногами в тренажере',
      'lat_pulldown': 'Тяга верхнего блока',
      'machine_chest_press': 'Жим от груди в тренажере',
      'bodyweight_pushups': 'Лестница отжиманий',
      'bodyweight_plank': 'Планка',
      'mountain_climbers': 'Альпинист',
      'burpees': 'Берпи',
      'mobility_hips': 'Мобилити для тазобедренных',
      'shoulder_mobility': 'Мобилити плеч',
    };

    final kz = <String, String>{
      'db_bench_press': 'Гантельмен жатып сығымдау',
      'db_rows': 'Бір қолмен гантель тарту',
      'db_goblet_squat': 'Гоблет отырып-тұру',
      'db_shoulder_press': 'Отырып гантель итеру',
      'barbell_back_squat': 'Штангамен отырып-тұру',
      'barbell_deadlift': 'Становая тарту',
      'bench_press': 'Штангамен жатып сығымдау',
      'machine_leg_press': 'Тренажерде аяқ сығымдау',
      'lat_pulldown': 'Жоғарғы блок тарту',
      'machine_chest_press': 'Тренажерде кеуде сығымдау',
      'bodyweight_pushups': 'Отжимание сатысы',
      'bodyweight_plank': 'Планка',
      'mountain_climbers': 'Альпинист',
      'burpees': 'Берпи',
      'mobility_hips': 'Жамбас мобилити',
      'shoulder_mobility': 'Иық мобилити',
    };

    return lang == AppLanguage.russian
        ? (ru[id] ?? item.title)
        : (kz[id] ?? item.title);
  }

  static String exerciseFocus(AppLanguage lang, ExerciseItem item) {
    if (lang == AppLanguage.english) return item.focus;

    final ru = <String, String>{
      'db_bench_press': 'Грудь, плечи, трицепс',
      'db_rows': 'Широчайшие и верх спины',
      'db_goblet_squat': 'Квадрицепс, ягодицы, кор',
      'db_shoulder_press': 'Плечи и трицепс',
      'barbell_back_squat': 'Сила и мощность ног',
      'barbell_deadlift': 'Задняя цепь',
      'bench_press': 'Грудь и трицепс',
      'machine_leg_press': 'Квадрицепс и ягодицы',
      'lat_pulldown': 'Широчайшие и верх спины',
      'machine_chest_press': 'Грудь и трицепс',
      'bodyweight_pushups': 'Грудь, кор, плечи',
      'bodyweight_plank': 'Стабильность кора',
      'mountain_climbers': 'Кардио и кор',
      'burpees': 'Общая выносливость',
      'mobility_hips': 'Тазобедренные и поясница',
      'shoulder_mobility': 'Здоровье плеч',
    };

    final kz = <String, String>{
      'db_bench_press': 'Кеуде, иық, трицепс',
      'db_rows': 'Арқа ені және жоғарғы арқа',
      'db_goblet_squat': 'Квадрицепс, бөксе, кор',
      'db_shoulder_press': 'Иық және трицепс',
      'barbell_back_squat': 'Аяқ күші мен қуаты',
      'barbell_deadlift': 'Артқы бұлшықет тізбегі',
      'bench_press': 'Кеуде және трицепс',
      'machine_leg_press': 'Квадрицепс және бөксе',
      'lat_pulldown': 'Арқа ені және жоғарғы арқа',
      'machine_chest_press': 'Кеуде және трицепс',
      'bodyweight_pushups': 'Кеуде, кор, иық',
      'bodyweight_plank': 'Кор тұрақтылығы',
      'mountain_climbers': 'Кардио және кор',
      'burpees': 'Толық дене төзімділігі',
      'mobility_hips': 'Жамбас және бел',
      'shoulder_mobility': 'Иық саулығы',
    };

    return lang == AppLanguage.russian
        ? (ru[item.id] ?? item.focus)
        : (kz[item.id] ?? item.focus);
  }

  static String exerciseTip(AppLanguage lang, ExerciseItem item) {
    if (lang == AppLanguage.english) return item.coachTip;

    final ru = <String, String>{
      'db_bench_press': 'Упритесь стопами в пол и держите лопатки сведенными.',
      'db_rows': 'Тяните локоть к бедру и не разворачивайте корпус.',
      'db_goblet_squat': 'Держите грудь высоко, колени направляйте по носкам.',
      'db_shoulder_press': 'Жмите по дуге и не переразгибайте поясницу.',
      'barbell_back_squat':
          'Напрягайте кор перед движением вниз и держите штангу над серединой стопы.',
      'barbell_deadlift':
          'Отталкивайте пол ногами и держите штангу близко к голени.',
      'bench_press':
          'Используйте упор ногами и сохраняйте небольшой прогиб спины.',
      'machine_leg_press':
          'Опускайте платформу подконтрольно и не выпрямляйте колени резко.',
      'lat_pulldown': 'Тяните локти вниз, а не назад, и избегайте раскачки.',
      'machine_chest_press':
          'Держите лопатки сведенными на протяжении подхода.',
      'bodyweight_pushups':
          'Держите тело ровно и опускайте грудь между ладонями.',
      'bodyweight_plank': 'Сжимайте ягодицы и не провисайте в тазу.',
      'mountain_climbers': 'Двигайтесь быстро, но держите плечи над кистями.',
      'burpees': 'Приземляйтесь мягко и держите ровный ритм.',
      'mobility_hips': 'Двигайтесь медленно и дышите глубоко в каждом повторе.',
      'shoulder_mobility':
          'Держите ребра опущенными и работайте только в безболезненном диапазоне.',
    };

    final kz = <String, String>{
      'db_bench_press': 'Аяқты жерге тіреп, жауырынды жинап ұстаңыз.',
      'db_rows': 'Шынтақты жамбасқа тартып, денені бұрмаңыз.',
      'db_goblet_squat':
          'Кеудені тік ұстап, тізені башпай бағытымен жүргізіңіз.',
      'db_shoulder_press':
          'Итеруді доға бойымен жасап, белді артық қайырмаңыз.',
      'barbell_back_squat':
          'Түсер алдында корды бекітіп, штанганы аяқ ортасында ұстаңыз.',
      'barbell_deadlift':
          'Еденді аяқпен итеріп, штанганы жіліншікке жақын ұстаңыз.',
      'bench_press': 'Аяқ тірегін қолданып, арқада сәл доға сақтаңыз.',
      'machine_leg_press':
          'Қозғалысты бақылап түсіріңіз, тізені күрт құлыптамаңыз.',
      'lat_pulldown': 'Шынтақты төмен тартыңыз, артқа сермеуді азайтыңыз.',
      'machine_chest_press': 'Сет бойы жауырынды жинап ұстаңыз.',
      'bodyweight_pushups':
          'Денені түзу ұстап, кеудені алақан арасына түсіріңіз.',
      'bodyweight_plank': 'Бөксені қысып, белдің түсіп кетуіне жол бермеңіз.',
      'mountain_climbers':
          'Жылдам қимылдаңыз, бірақ иық білектің үстінде болсын.',
      'burpees': 'Жұмсақ қонып, бірқалыпты ырғақты сақтаңыз.',
      'mobility_hips': 'Баяу қозғалып, әр қайталауда терең тыныстаңыз.',
      'shoulder_mobility':
          'Қабырғаны төмен ұстап, тек ауырсынусыз амплитудада жұмыс істеңіз.',
    };

    return lang == AppLanguage.russian
        ? (ru[item.id] ?? item.coachTip)
        : (kz[item.id] ?? item.coachTip);
  }
}

class ExerciseItem {
  final String id;
  final String title;
  final String category;
  final String focus;
  final String level;
  final int durationMinutes;
  final int calories;
  final String sets;
  final String reps;
  final List<String> equipment;
  final String coachTip;
  final String videoId;
  final int workSeconds;
  final int restSeconds;
  final int rounds;

  const ExerciseItem({
    required this.id,
    required this.title,
    required this.category,
    required this.focus,
    required this.level,
    required this.durationMinutes,
    required this.calories,
    required this.sets,
    required this.reps,
    required this.equipment,
    required this.coachTip,
    required this.videoId,
    required this.workSeconds,
    required this.restSeconds,
    required this.rounds,
  });
}

class ExerciseSession {
  final String exerciseId;
  final String title;
  final String category;
  final int durationMinutes;
  final int calories;
  final DateTime completedAt;

  const ExerciseSession({
    required this.exerciseId,
    required this.title,
    required this.category,
    required this.durationMinutes,
    required this.calories,
    required this.completedAt,
  });
}

const List<ExerciseItem> kExerciseLibrary = <ExerciseItem>[
  ExerciseItem(
    id: 'db_bench_press',
    title: 'Dumbbell Bench Press',
    category: 'Strength',
    focus: 'Chest, shoulders, triceps',
    level: 'Beginner',
    durationMinutes: 18,
    calories: 120,
    sets: '4 sets',
    reps: '10 reps',
    equipment: <String>['Dumbbells'],
    coachTip: 'Drive feet into floor and keep shoulder blades packed.',
    videoId: 'VmB1G1K7v94',
    workSeconds: 45,
    restSeconds: 20,
    rounds: 8,
  ),
  ExerciseItem(
    id: 'db_rows',
    title: 'One-Arm Dumbbell Row',
    category: 'Strength',
    focus: 'Lats and upper back',
    level: 'Beginner',
    durationMinutes: 16,
    calories: 105,
    sets: '4 sets',
    reps: '12 reps/side',
    equipment: <String>['Dumbbells'],
    coachTip: 'Pull elbow toward your hip and avoid torso rotation.',
    videoId: 'pYcpY20QaE8',
    workSeconds: 40,
    restSeconds: 20,
    rounds: 8,
  ),
  ExerciseItem(
    id: 'db_goblet_squat',
    title: 'Goblet Squat',
    category: 'Legs',
    focus: 'Quads, glutes, core',
    level: 'Beginner',
    durationMinutes: 15,
    calories: 115,
    sets: '4 sets',
    reps: '12 reps',
    equipment: <String>['Dumbbells'],
    coachTip: 'Keep chest tall and knees tracking over toes.',
    videoId: 'MeIiIdhvXT4',
    workSeconds: 45,
    restSeconds: 20,
    rounds: 8,
  ),
  ExerciseItem(
    id: 'db_shoulder_press',
    title: 'Seated Dumbbell Shoulder Press',
    category: 'Strength',
    focus: 'Shoulders and triceps',
    level: 'Intermediate',
    durationMinutes: 14,
    calories: 100,
    sets: '3 sets',
    reps: '10 reps',
    equipment: <String>['Dumbbells'],
    coachTip: 'Press up in an arc and avoid overextending lower back.',
    videoId: 'qEwKCR5JCog',
    workSeconds: 40,
    restSeconds: 20,
    rounds: 7,
  ),
  ExerciseItem(
    id: 'barbell_back_squat',
    title: 'Barbell Back Squat',
    category: 'Legs',
    focus: 'Leg strength and power',
    level: 'Intermediate',
    durationMinutes: 22,
    calories: 170,
    sets: '5 sets',
    reps: '5 reps',
    equipment: <String>['Barbell'],
    coachTip: 'Brace core before descent and keep bar over mid-foot.',
    videoId: 'ultWZbUMPL8',
    workSeconds: 50,
    restSeconds: 30,
    rounds: 8,
  ),
  ExerciseItem(
    id: 'barbell_deadlift',
    title: 'Barbell Deadlift',
    category: 'Strength',
    focus: 'Posterior chain',
    level: 'Intermediate',
    durationMinutes: 20,
    calories: 165,
    sets: '5 sets',
    reps: '5 reps',
    equipment: <String>['Barbell'],
    coachTip: 'Push the floor away and keep bar close to shins.',
    videoId: 'ytGaGIn3SjE',
    workSeconds: 50,
    restSeconds: 30,
    rounds: 7,
  ),
  ExerciseItem(
    id: 'bench_press',
    title: 'Barbell Bench Press',
    category: 'Strength',
    focus: 'Chest and triceps',
    level: 'Intermediate',
    durationMinutes: 18,
    calories: 140,
    sets: '5 sets',
    reps: '6 reps',
    equipment: <String>['Barbell'],
    coachTip: 'Use leg drive and maintain slight upper-back arch.',
    videoId: 'SCVCLChPQFY',
    workSeconds: 45,
    restSeconds: 25,
    rounds: 8,
  ),
  ExerciseItem(
    id: 'machine_leg_press',
    title: 'Machine Leg Press',
    category: 'Legs',
    focus: 'Quads and glutes',
    level: 'Beginner',
    durationMinutes: 14,
    calories: 110,
    sets: '4 sets',
    reps: '12 reps',
    equipment: <String>['Machine'],
    coachTip: 'Lower with control and do not lock knees hard.',
    videoId: 'IZxyjW7MPJQ',
    workSeconds: 45,
    restSeconds: 20,
    rounds: 7,
  ),
  ExerciseItem(
    id: 'lat_pulldown',
    title: 'Lat Pulldown',
    category: 'Back',
    focus: 'Lats and upper back',
    level: 'Beginner',
    durationMinutes: 13,
    calories: 90,
    sets: '4 sets',
    reps: '12 reps',
    equipment: <String>['Machine'],
    coachTip: 'Pull elbows down, not backward, and avoid swinging.',
    videoId: 'CAwf7n6Luuc',
    workSeconds: 40,
    restSeconds: 20,
    rounds: 7,
  ),
  ExerciseItem(
    id: 'machine_chest_press',
    title: 'Machine Chest Press',
    category: 'Strength',
    focus: 'Chest and triceps',
    level: 'Beginner',
    durationMinutes: 12,
    calories: 85,
    sets: '3 sets',
    reps: '12 reps',
    equipment: <String>['Machine'],
    coachTip: 'Keep shoulder blades retracted throughout the set.',
    videoId: 'xUm0BiZCWlQ',
    workSeconds: 40,
    restSeconds: 20,
    rounds: 6,
  ),
  ExerciseItem(
    id: 'bodyweight_pushups',
    title: 'Push-Up Ladder',
    category: 'Bodyweight',
    focus: 'Chest, core, shoulders',
    level: 'Beginner',
    durationMinutes: 10,
    calories: 75,
    sets: '5 rounds',
    reps: 'AMRAP',
    equipment: <String>['Bodyweight'],
    coachTip: 'Keep body straight and lower chest between hands.',
    videoId: 'IODxDxX7oi4',
    workSeconds: 35,
    restSeconds: 20,
    rounds: 8,
  ),
  ExerciseItem(
    id: 'bodyweight_plank',
    title: 'Plank Hold Circuit',
    category: 'Core',
    focus: 'Core stability',
    level: 'Beginner',
    durationMinutes: 9,
    calories: 50,
    sets: '4 rounds',
    reps: '45 sec hold',
    equipment: <String>['Bodyweight'],
    coachTip: 'Squeeze glutes and avoid hips dropping.',
    videoId: 'pSHjTRCQxIw',
    workSeconds: 40,
    restSeconds: 15,
    rounds: 6,
  ),
  ExerciseItem(
    id: 'mountain_climbers',
    title: 'Mountain Climbers',
    category: 'Cardio',
    focus: 'Cardio and core',
    level: 'Beginner',
    durationMinutes: 8,
    calories: 70,
    sets: '6 rounds',
    reps: '30 sec work',
    equipment: <String>['Bodyweight'],
    coachTip: 'Move fast but keep shoulders over wrists.',
    videoId: 'nmwgirgXLYM',
    workSeconds: 30,
    restSeconds: 15,
    rounds: 8,
  ),
  ExerciseItem(
    id: 'burpees',
    title: 'Burpee Blast',
    category: 'Cardio',
    focus: 'Full body conditioning',
    level: 'Intermediate',
    durationMinutes: 12,
    calories: 125,
    sets: '6 rounds',
    reps: '12 reps',
    equipment: <String>['Bodyweight'],
    coachTip: 'Land softly and keep rhythm consistent.',
    videoId: 'dZgVxmf6jkA',
    workSeconds: 35,
    restSeconds: 20,
    rounds: 8,
  ),
  ExerciseItem(
    id: 'mobility_hips',
    title: 'Hip Mobility Flow',
    category: 'Mobility',
    focus: 'Hips and lower back',
    level: 'Beginner',
    durationMinutes: 10,
    calories: 40,
    sets: '3 rounds',
    reps: '60 sec each move',
    equipment: <String>['Bodyweight'],
    coachTip: 'Move slowly and breathe deeply through each rep.',
    videoId: 'jj2AAH6jbHk',
    workSeconds: 50,
    restSeconds: 15,
    rounds: 5,
  ),
  ExerciseItem(
    id: 'shoulder_mobility',
    title: 'Shoulder Mobility Reset',
    category: 'Mobility',
    focus: 'Shoulder health',
    level: 'Beginner',
    durationMinutes: 9,
    calories: 35,
    sets: '3 rounds',
    reps: '8 reps each drill',
    equipment: <String>['Bodyweight'],
    coachTip: 'Keep ribs down and move through pain-free range only.',
    videoId: 'C6sYjDFuq9I',
    workSeconds: 45,
    restSeconds: 15,
    rounds: 5,
  ),
];

class UserProfile extends ChangeNotifier {
  static const String _storageKey = 'jihc_fittrack_profile_v2';

  ThemeMode themeMode = ThemeMode.dark;
  WeightUnit weightUnit = WeightUnit.kg;
  DistanceUnit distanceUnit = DistanceUnit.km;
  BodyUnit bodyUnit = BodyUnit.cm;
  AppLanguage language = AppLanguage.english;
  bool onboardingCompleted = false;
  String firstName = '';
  String lastName = '';
  String accountEmail = '';
  String accountPassword = '';
  Gender? gender;
  DateTime birthday = DateTime(2000, 6, 15);
  double weightKg = 60.0;
  int heightCm = 170;
  FitnessGoal? fitnessGoal;
  ExperienceLevel? experience;
  WorkoutPref workoutPref = WorkoutPref.guided;
  TrainingPlace trainingPlace = TrainingPlace.home;
  Set<String> equipment = {'Barbell', 'Dumbbells'};
  int daysPerWeek = 4;
  int durationMins = 60;
  String? muscleFocus;
  final Set<String> _favoriteExerciseIds = <String>{};
  final List<ExerciseSession> _completedSessions = <ExerciseSession>[];

  String tr(String key, {Map<String, String> args = const {}}) {
    return AppI18n.t(language, key, args: args);
  }

  bool get hasAccount {
    return accountEmail.trim().isNotEmpty && accountPassword.isNotEmpty;
  }

  void _notifyAndSave() {
    notifyListeners();
    unawaited(_saveToStorage());
  }

  T? _enumFromName<T extends Enum>(List<T> values, dynamic raw) {
    if (raw is! String) return null;
    for (final value in values) {
      if (value.name == raw) return value;
    }
    return null;
  }

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = prefs.getString(_storageKey);
    if (payload == null || payload.isEmpty) return;

    try {
      final data = jsonDecode(payload);
      if (data is! Map<String, dynamic>) return;

      themeMode =
          _enumFromName(ThemeMode.values, data['themeMode']) ?? ThemeMode.dark;
      weightUnit =
          _enumFromName(WeightUnit.values, data['weightUnit']) ?? WeightUnit.kg;
      distanceUnit =
          _enumFromName(DistanceUnit.values, data['distanceUnit']) ??
          DistanceUnit.km;
      bodyUnit =
          _enumFromName(BodyUnit.values, data['bodyUnit']) ?? BodyUnit.cm;
      language =
          _enumFromName(AppLanguage.values, data['language']) ??
          AppLanguage.english;
      firstName = (data['firstName'] as String? ?? '').trim();
      lastName = (data['lastName'] as String? ?? '').trim();
      accountEmail =
          (data['accountEmail'] as String? ?? data['email'] as String? ?? '')
              .trim();
      accountPassword =
          data['accountPassword'] as String? ??
          data['password'] as String? ??
          '';
      gender = _enumFromName(Gender.values, data['gender']);
      fitnessGoal = _enumFromName(FitnessGoal.values, data['fitnessGoal']);
      experience = _enumFromName(ExperienceLevel.values, data['experience']);
      workoutPref =
          _enumFromName(WorkoutPref.values, data['workoutPref']) ??
          WorkoutPref.guided;
      trainingPlace =
          _enumFromName(TrainingPlace.values, data['trainingPlace']) ??
          TrainingPlace.home;

      final birthdayRaw = data['birthday'];
      if (birthdayRaw is String) {
        final parsed = DateTime.tryParse(birthdayRaw);
        if (parsed != null) {
          birthday = parsed;
        }
      }

      final weightRaw = data['weightKg'];
      if (weightRaw is num) {
        weightKg = weightRaw.toDouble();
      }

      final heightRaw = data['heightCm'];
      if (heightRaw is num) {
        heightCm = heightRaw.toInt();
      }

      final daysRaw = data['daysPerWeek'];
      if (daysRaw is num) {
        daysPerWeek = daysRaw.toInt().clamp(1, 7);
      }

      final durationRaw = data['durationMins'];
      if (durationRaw is num) {
        durationMins = durationRaw.toInt().clamp(10, 180);
      }

      muscleFocus = data['muscleFocus'] as String?;
      onboardingCompleted = data['onboardingCompleted'] == true;

      final equipmentRaw = data['equipment'];
      if (equipmentRaw is List) {
        equipment = equipmentRaw.whereType<String>().toSet();
      }
      if (equipment.isEmpty) {
        equipment = <String>{'Barbell', 'Dumbbells'};
      }
      _normalizeEquipmentForPlace();

      _favoriteExerciseIds
        ..clear()
        ..addAll(
          (data['favorites'] as List?)?.whereType<String>() ?? <String>[],
        );

      _completedSessions.clear();
      final sessionsRaw = data['completedSessions'];
      if (sessionsRaw is List) {
        for (final raw in sessionsRaw) {
          if (raw is! Map) continue;
          final exerciseId = raw['exerciseId'];
          final title = raw['title'];
          final category = raw['category'];
          final duration = raw['durationMinutes'];
          final calories = raw['calories'];
          final completedAt = raw['completedAt'];
          if (exerciseId is! String ||
              title is! String ||
              category is! String ||
              duration is! num ||
              calories is! num ||
              completedAt is! String) {
            continue;
          }
          final parsedDate = DateTime.tryParse(completedAt);
          if (parsedDate == null) continue;
          _completedSessions.add(
            ExerciseSession(
              exerciseId: exerciseId,
              title: title,
              category: category,
              durationMinutes: duration.toInt(),
              calories: calories.toInt(),
              completedAt: parsedDate,
            ),
          );
        }
      }
    } catch (_) {
      // Keep defaults when saved data is corrupted or from older versions.
    }

    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final data = <String, dynamic>{
      'themeMode': themeMode.name,
      'weightUnit': weightUnit.name,
      'distanceUnit': distanceUnit.name,
      'bodyUnit': bodyUnit.name,
      'language': language.name,
      'onboardingCompleted': onboardingCompleted,
      'firstName': firstName,
      'lastName': lastName,
      'accountEmail': accountEmail,
      'accountPassword': accountPassword,
      'gender': gender?.name,
      'birthday': birthday.toIso8601String(),
      'weightKg': weightKg,
      'heightCm': heightCm,
      'fitnessGoal': fitnessGoal?.name,
      'experience': experience?.name,
      'workoutPref': workoutPref.name,
      'trainingPlace': trainingPlace.name,
      'equipment': equipment.toList(),
      'daysPerWeek': daysPerWeek,
      'durationMins': durationMins,
      'muscleFocus': muscleFocus,
      'favorites': _favoriteExerciseIds.toList(),
      'completedSessions': _completedSessions
          .map(
            (s) => <String, dynamic>{
              'exerciseId': s.exerciseId,
              'title': s.title,
              'category': s.category,
              'durationMinutes': s.durationMinutes,
              'calories': s.calories,
              'completedAt': s.completedAt.toIso8601String(),
            },
          )
          .toList(),
    };
    await prefs.setString(_storageKey, jsonEncode(data));
  }

  bool get isDarkMode => themeMode == ThemeMode.dark;

  void _resetWorkoutResults() {
    _favoriteExerciseIds.clear();
    _completedSessions.clear();
  }

  Future<void> logoutToOnboarding() async {
    _resetWorkoutResults();
    onboardingCompleted = false;
    gender = null;
    birthday = DateTime(2000, 6, 15);
    weightKg = 60.0;
    heightCm = 170;
    fitnessGoal = null;
    experience = null;
    workoutPref = WorkoutPref.guided;
    trainingPlace = TrainingPlace.home;
    equipment = <String>{'Barbell', 'Dumbbells'};
    daysPerWeek = 4;
    durationMins = 60;
    muscleFocus = null;
    notifyListeners();
    await _saveToStorage();
  }

  void setLanguage(AppLanguage value) {
    language = value;
    _notifyAndSave();
  }

  void completeOnboarding() {
    onboardingCompleted = true;
    _notifyAndSave();
  }

  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
    _notifyAndSave();
  }

  void setTrainingPlace(TrainingPlace value) {
    trainingPlace = value;
    _normalizeEquipmentForPlace();
    _notifyAndSave();
  }

  void _normalizeEquipmentForPlace() {
    switch (trainingPlace) {
      case TrainingPlace.dormitory:
        equipment.remove('Full Gym');
        equipment.remove('Barbell');
        equipment.remove('Machine');
        if (equipment.isEmpty) {
          equipment = {'Bodyweight', 'Resistance Bands'};
        }
        break;
      case TrainingPlace.home:
        equipment.remove('Full Gym');
        if (equipment.isEmpty) {
          equipment = {'Bodyweight', 'Dumbbells'};
        }
        break;
      case TrainingPlace.gym:
        if (equipment.isEmpty) {
          equipment = {'Full Gym', 'Barbell', 'Dumbbells', 'Machine'};
        }
        break;
    }
  }

  void setWeightUnit(WeightUnit v) {
    weightUnit = v;
    _notifyAndSave();
  }

  void setDistanceUnit(DistanceUnit v) {
    distanceUnit = v;
    _notifyAndSave();
  }

  void setBodyUnit(BodyUnit v) {
    bodyUnit = v;
    _notifyAndSave();
  }

  void registerAccount({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) {
    this.firstName = firstName.trim();
    this.lastName = lastName.trim();
    accountEmail = email.trim().toLowerCase();
    accountPassword = password;
    _notifyAndSave();
  }

  bool isValidLogin({required String email, required String password}) {
    if (!hasAccount) return false;
    return accountEmail.toLowerCase() == email.trim().toLowerCase() &&
        accountPassword == password;
  }

  void setGender(Gender v) {
    gender = v;
    _notifyAndSave();
  }

  void setBirthday(DateTime v) {
    birthday = v;
    _notifyAndSave();
  }

  void setWeight(double v) {
    weightKg = v;
    _notifyAndSave();
  }

  void setHeight(int v) {
    heightCm = v;
    _notifyAndSave();
  }

  void setGoal(FitnessGoal v) {
    fitnessGoal = v;
    _notifyAndSave();
  }

  void setExperience(ExperienceLevel v) {
    experience = v;
    _notifyAndSave();
  }

  void setWorkoutPref(WorkoutPref v) {
    workoutPref = v;
    _notifyAndSave();
  }

  void setDays(int v) {
    daysPerWeek = v;
    _notifyAndSave();
  }

  void setDuration(int v) {
    durationMins = v;
    _notifyAndSave();
  }

  void setMuscleFocus(String? v) {
    muscleFocus = v;
    _notifyAndSave();
  }

  void toggleEquipment(String item) {
    if (equipment.contains(item)) {
      equipment.remove(item);
    } else {
      equipment.add(item);
    }
    _notifyAndSave();
  }

  void selectAllEquipment() {
    switch (trainingPlace) {
      case TrainingPlace.dormitory:
        equipment = {'Bodyweight', 'Resistance Bands', 'Dumbbells'};
        break;
      case TrainingPlace.home:
        equipment = {'Bodyweight', 'Resistance Bands', 'Dumbbells'};
        break;
      case TrainingPlace.gym:
        equipment = {
          'Full Gym',
          'Barbell',
          'Dumbbells',
          'Machine',
          'Resistance Bands',
          'Bodyweight',
        };
        break;
    }
    _notifyAndSave();
  }

  void clearEquipment() {
    equipment.clear();
    _notifyAndSave();
  }

  String get goalLabel {
    return AppI18n.goalName(language, fitnessGoal);
  }

  String get levelLabel {
    return AppI18n.levelName(language, experience);
  }

  int get levelIndex {
    switch (experience) {
      case ExperienceLevel.beginner:
        return 1;
      case ExperienceLevel.intermediate:
        return 2;
      case ExperienceLevel.advanced:
        return 3;
      default:
        return 0;
    }
  }

  String get equipmentSummary {
    if (equipment.isEmpty) return tr('none');
    final list = equipment.toList()..sort();
    final first = AppI18n.equipmentName(language, list.first);
    final extra = equipment.length - 1;
    return extra > 0 ? '$first +$extra' : first;
  }

  String get trainingPlaceLabel {
    return AppI18n.placeName(language, trainingPlace);
  }

  String get trainingStyleTitle {
    switch (trainingPlace) {
      case TrainingPlace.dormitory:
        return tr('style_dormitory_title');
      case TrainingPlace.home:
        return tr('style_home_title');
      case TrainingPlace.gym:
        return tr('style_gym_title');
    }
  }

  String get trainingStyleDescription {
    switch (trainingPlace) {
      case TrainingPlace.dormitory:
        return tr('style_dormitory_desc');
      case TrainingPlace.home:
        return tr('style_home_desc');
      case TrainingPlace.gym:
        return tr('style_gym_desc');
    }
  }

  String localizedCategory(String category) {
    return AppI18n.categoryName(language, category);
  }

  String localizedLevel(String levelRaw) {
    return AppI18n.exerciseLevelName(language, levelRaw);
  }

  String localizedEquipment(String equipmentRaw) {
    return AppI18n.equipmentName(language, equipmentRaw);
  }

  String localizedMuscle(String muscleRaw) {
    return AppI18n.muscleName(language, muscleRaw);
  }

  String localizedExerciseTitle(ExerciseItem item) {
    return AppI18n.exerciseTitle(language, item);
  }

  String localizedExerciseFocus(ExerciseItem item) {
    return AppI18n.exerciseFocus(language, item);
  }

  String localizedExerciseTip(ExerciseItem item) {
    return AppI18n.exerciseTip(language, item);
  }

  String localizedSets(String raw) {
    return AppI18n.setsText(language, raw);
  }

  String localizedReps(String raw) {
    return AppI18n.repsText(language, raw);
  }

  String localizedExerciseTitleById(String id) {
    for (final item in kExerciseLibrary) {
      if (item.id == id) {
        return localizedExerciseTitle(item);
      }
    }
    return id;
  }

  List<ExerciseSession> get completedSessions =>
      List<ExerciseSession>.unmodifiable(_completedSessions);

  bool isExerciseFavorite(String exerciseId) {
    return _favoriteExerciseIds.contains(exerciseId);
  }

  void toggleExerciseFavorite(String exerciseId) {
    if (!_favoriteExerciseIds.add(exerciseId)) {
      _favoriteExerciseIds.remove(exerciseId);
    }
    _notifyAndSave();
  }

  void markExerciseCompleted(ExerciseItem item) {
    _completedSessions.insert(
      0,
      ExerciseSession(
        exerciseId: item.id,
        title: item.title,
        category: item.category,
        durationMinutes: item.durationMinutes,
        calories: item.calories,
        completedAt: DateTime.now(),
      ),
    );
    _notifyAndSave();
  }

  void removeCompletedSession(ExerciseSession session) {
    _completedSessions.remove(session);
    _notifyAndSave();
  }

  void clearCompletedSessions() {
    _completedSessions.clear();
    _notifyAndSave();
  }

  int get completedWorkoutCount => _completedSessions.length;

  int get totalCompletedMinutes =>
      _completedSessions.fold<int>(0, (total, e) => total + e.durationMinutes);

  int get totalBurnedCalories =>
      _completedSessions.fold<int>(0, (total, e) => total + e.calories);

  int get weeklyCompletedCount {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return _completedSessions
        .where((e) => e.completedAt.isAfter(weekAgo))
        .length;
  }

  double get weeklyTargetProgress {
    return (weeklyCompletedCount / max(1, daysPerWeek)).clamp(0, 1).toDouble();
  }

  Map<String, int> get categoryProgress {
    final map = <String, int>{};
    for (final s in _completedSessions) {
      map.update(s.category, (v) => v + 1, ifAbsent: () => 1);
    }
    return map;
  }

  Map<String, int> get exerciseCompletionCount {
    final map = <String, int>{};
    for (final s in _completedSessions) {
      map.update(s.exerciseId, (v) => v + 1, ifAbsent: () => 1);
    }
    return map;
  }

  int completionCountForExercise(String exerciseId) {
    return exerciseCompletionCount[exerciseId] ?? 0;
  }

  bool isExerciseCompletedToday(String exerciseId) {
    final now = DateTime.now();
    return _completedSessions.any((s) {
      if (s.exerciseId != exerciseId) return false;
      return s.completedAt.year == now.year &&
          s.completedAt.month == now.month &&
          s.completedAt.day == now.day;
    });
  }

  bool isExerciseAvailable(ExerciseItem item) {
    if (!isPlaceFriendly(item)) return false;
    if (equipment.contains('Full Gym')) return true;
    if (item.equipment.contains('Bodyweight')) return true;
    return item.equipment.any(equipment.contains);
  }

  bool isPlaceFriendly(ExerciseItem item) {
    switch (trainingPlace) {
      case TrainingPlace.dormitory:
        if (item.equipment.contains('Barbell') ||
            item.equipment.contains('Machine')) {
          return false;
        }
        return item.durationMinutes <= 20;
      case TrainingPlace.home:
        if (item.equipment.contains('Machine')) return false;
        return true;
      case TrainingPlace.gym:
        return true;
    }
  }

  bool _isPlaceAligned(ExerciseItem item) {
    switch (trainingPlace) {
      case TrainingPlace.dormitory:
        return item.equipment.contains('Bodyweight') ||
            item.equipment.contains('Resistance Bands') ||
            item.category == 'Mobility' ||
            item.category == 'Core' ||
            item.category == 'Cardio';
      case TrainingPlace.home:
        return item.equipment.contains('Dumbbells') ||
            item.equipment.contains('Bodyweight') ||
            item.equipment.contains('Resistance Bands');
      case TrainingPlace.gym:
        return item.equipment.contains('Barbell') ||
            item.equipment.contains('Machine') ||
            item.category == 'Strength' ||
            item.category == 'Legs' ||
            item.category == 'Back';
    }
  }

  bool _isGoalAligned(ExerciseItem item) {
    final category = item.category.toLowerCase();
    switch (fitnessGoal) {
      case FitnessGoal.buildMuscle:
        return category == 'strength' ||
            category == 'legs' ||
            category == 'back';
      case FitnessGoal.buildStrength:
        return category == 'strength' || category == 'legs';
      case FitnessGoal.loseFat:
        return category == 'cardio' ||
            category == 'bodyweight' ||
            category == 'mobility' ||
            category == 'core';
      default:
        return true;
    }
  }

  bool _isFocusAligned(ExerciseItem item) {
    if (muscleFocus == null) return false;
    final focus = item.focus.toLowerCase();
    final target = muscleFocus!.toLowerCase();
    if (target == 'arms') {
      return focus.contains('triceps') || focus.contains('biceps');
    }
    if (target == 'glutes') return focus.contains('glute');
    return focus.contains(target);
  }

  int _exerciseLevelRank(ExerciseItem item) {
    switch (item.level.toLowerCase()) {
      case 'beginner':
        return 1;
      case 'intermediate':
        return 2;
      case 'advanced':
        return 3;
      default:
        return 1;
    }
  }

  int recommendationScore(ExerciseItem item) {
    var score = 0;

    if (isExerciseAvailable(item)) {
      score += 40;
    } else {
      score -= 25;
    }

    if (_isGoalAligned(item)) score += 20;
    if (_isFocusAligned(item)) score += 14;
    if (_isPlaceAligned(item)) {
      score += 16;
    } else {
      score -= 10;
    }
    if (isExerciseFavorite(item.id)) score += 10;

    final levelGap = (levelIndex - _exerciseLevelRank(item)).abs();
    score += max(0, 15 - (levelGap * 7));

    final completionCount = completionCountForExercise(item.id);
    score += max(0, 10 - (completionCount * 2));

    if (item.durationMinutes <= durationMins) {
      score += 6;
    } else {
      score -= 4;
    }

    return score;
  }

  List<ExerciseItem> get recommendedExercises {
    final list = List<ExerciseItem>.from(kExerciseLibrary);
    list.sort((a, b) {
      final scoreCompare = recommendationScore(
        b,
      ).compareTo(recommendationScore(a));
      if (scoreCompare != 0) return scoreCompare;
      return a.durationMinutes.compareTo(b.durationMinutes);
    });
    return list;
  }

  List<ExerciseItem> get todayPlan {
    final candidates = recommendedExercises.where(isExerciseAvailable).toList();
    if (candidates.isEmpty) {
      return recommendedExercises.take(3).toList();
    }

    final plan = <ExerciseItem>[];
    final usedCategories = <String>{};
    final targetMinutes = max(24, durationMins);
    var total = 0;

    for (final item in candidates) {
      final wantsDiversity = usedCategories.length < 3;
      if (wantsDiversity && usedCategories.contains(item.category)) {
        continue;
      }
      plan.add(item);
      usedCategories.add(item.category);
      total += item.durationMinutes;
      if (plan.length >= 4 || total >= targetMinutes) break;
    }

    if (plan.length < 3) {
      for (final item in candidates) {
        if (plan.any((e) => e.id == item.id)) continue;
        plan.add(item);
        total += item.durationMinutes;
        if (plan.length >= 4 || total >= targetMinutes) break;
      }
    }

    return plan.take(4).toList();
  }

  ExerciseItem? get todayMainExercise {
    final plan = todayPlan;
    return plan.isEmpty ? null : plan.first;
  }

  int get todayPlanMinutes {
    return todayPlan.fold<int>(0, (total, e) => total + e.durationMinutes);
  }

  int get todayPlanCalories {
    return todayPlan.fold<int>(0, (total, e) => total + e.calories);
  }

  int get currentStreakDays {
    if (_completedSessions.isEmpty) return 0;

    final completedDays = _completedSessions
        .map(
          (s) => DateTime(
            s.completedAt.year,
            s.completedAt.month,
            s.completedAt.day,
          ),
        )
        .toSet();

    var streak = 0;
    var cursor = DateTime.now();
    cursor = DateTime(cursor.year, cursor.month, cursor.day);

    if (!completedDays.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    while (completedDays.contains(cursor)) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  double get consistencyScore {
    final weekly = weeklyTargetProgress * 70;
    final streak = min(30, currentStreakDays * 5).toDouble();
    return (weekly + streak).clamp(0, 100);
  }
}

// ============================================================
// SHARED WIDGETS
// ============================================================

/// Primary blue button
class FitButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool enabled;
  const FitButton({
    super.key,
    required this.label,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: enabled
              ? AppTheme.accent
              : AppTheme.accent.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: AppTheme.onAccent,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Segmented toggle control.
class SegmentToggle extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  const SegmentToggle({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final sel = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[i],
                  style: TextStyle(
                    color: sel ? AppTheme.onAccent : AppTheme.textSecondary,
                    fontSize: 15,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Single-select card with radio circle
class SelectCard extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? leading;
  const SelectCard({
    super.key,
    required this.label,
    this.subtitle,
    required this.isSelected,
    required this.onTap,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accent.withValues(alpha: 0.08)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.accent : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 14)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _RadioDot(isSelected: isSelected),
          ],
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  final bool isSelected;
  const _RadioDot({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppTheme.accent : AppTheme.textTertiary,
          width: 2,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accent,
                ),
              ),
            )
          : null,
    );
  }
}

/// Multi-select card with checkmark
class CheckCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? leading;
  const CheckCard({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accent.withValues(alpha: 0.08)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.accent : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 14)],
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isSelected) Icon(Icons.check, color: AppTheme.accent, size: 22),
          ],
        ),
      ),
    );
  }
}

/// 4-segment step progress bar
class StepBar extends StatelessWidget {
  final int total;
  final int current;
  const StepBar({super.key, required this.total, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(left: i == 0 ? 0 : 4),
            height: 4,
            decoration: BoxDecoration(
              color: i < current ? AppTheme.accent : AppTheme.surfaceVar,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

/// Standard onboarding page wrapper
class OBScaffold extends StatelessWidget {
  final AppLanguage language;
  final String? title;
  final String? subtitle;
  final Widget child;
  final String btnLabel;
  final VoidCallback onNext;
  final bool showBack;
  final VoidCallback? onBack;
  final String? skipLabel;
  final VoidCallback? onSkip;
  final Widget? progressBar;
  final bool btnEnabled;
  final bool showPrivacy;

  const OBScaffold({
    super.key,
    this.language = AppLanguage.english,
    this.title,
    this.subtitle,
    required this.child,
    required this.btnLabel,
    required this.onNext,
    this.showBack = true,
    this.onBack,
    this.skipLabel,
    this.onSkip,
    this.progressBar,
    this.btnEnabled = true,
    this.showPrivacy = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  if (showBack)
                    GestureDetector(
                      onTap: onBack ?? () => Navigator.of(context).pop(),
                      child: Icon(
                        Icons.arrow_back,
                        color: AppTheme.textPrimary,
                        size: 24,
                      ),
                    )
                  else
                    const SizedBox(width: 24),
                  if (progressBar != null)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: progressBar!,
                      ),
                    )
                  else
                    const Spacer(),
                  if (skipLabel != null)
                    GestureDetector(
                      onTap: onSkip,
                      child: Text(
                        skipLabel!,
                        style: TextStyle(
                          color: AppTheme.accent,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 40),
                ],
              ),
            ),

            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: Text(
                  title!,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ),

            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Text(
                  subtitle!,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
              ),

            Expanded(child: child),

            // Bottom
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: Column(
                children: [
                  if (showPrivacy) ...[
                    Text(
                      AppI18n.t(language, 'your_data_private'),
                      style: TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  FitButton(
                    label: btnLabel,
                    onTap: onNext,
                    enabled: btnEnabled,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ONBOARDING FLOW CONTROLLER
// ============================================================
enum _Step {
  auth,
  gender,
  birthday,
  weight,
  height,
  goal,
  experience,
  workoutPref,
  equipment,
  place,
  frequency,
  duration,
  muscleFocus,
  generating,
  programResult,
  welcome,
}

class OnboardingFlow extends StatefulWidget {
  final UserProfile profile;
  const OnboardingFlow({super.key, required this.profile});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  _Step _step = _Step.auth;

  void _next() {
    final idx = _step.index + 1;
    if (idx < _Step.values.length) {
      setState(() => _step = _Step.values[idx]);
    } else {
      _goHome();
    }
  }

  void _back() {
    if (_step.index > 0) {
      setState(() => _step = _Step.values[_step.index - 1]);
    }
  }

  void _goHome() {
    widget.profile.completeOnboarding();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomeScreen(profile: widget.profile)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == _Step.auth,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step != _Step.auth) {
          _back();
        }
      },
      child: SizedBox.expand(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              fit: StackFit.expand,
              children: [
                ...previousChildren,
                // ignore: use_null_aware_elements
                if (currentChild != null) currentChild,
              ],
            );
          },
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0.06, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                  ),
              child: child,
            ),
          ),
          child: KeyedSubtree(key: ValueKey(_step), child: _build()),
        ),
      ),
    );
  }

  Widget _build() {
    final p = widget.profile;
    switch (_step) {
      case _Step.auth:
        return _AuthScreen(profile: p, onNext: _next);
      case _Step.gender:
        return _GenderScreen(profile: p, onNext: _next, onBack: _back);
      case _Step.birthday:
        return _BirthdayScreen(profile: p, onNext: _next, onBack: _back);
      case _Step.weight:
        return _WeightScreen(profile: p, onNext: _next, onBack: _back);
      case _Step.height:
        return _HeightScreen(profile: p, onNext: _next, onBack: _back);
      case _Step.goal:
        return _GoalScreen(profile: p, onNext: _next, onBack: _back);
      case _Step.experience:
        return _ExperienceScreen(profile: p, onNext: _next, onBack: _back);
      case _Step.workoutPref:
        return _WorkoutPrefScreen(
          profile: p,
          onNext: _next,
          onBack: _back,
          onSkip: _next,
        );
      case _Step.equipment:
        return _EquipmentScreen(profile: p, onNext: _next, onBack: _back);
      case _Step.place:
        return _PlaceScreen(profile: p, onNext: _next, onBack: _back);
      case _Step.frequency:
        return _FrequencyScreen(profile: p, onNext: _next, onBack: _back);
      case _Step.duration:
        return _DurationScreen(profile: p, onNext: _next, onBack: _back);
      case _Step.muscleFocus:
        return _MuscleFocusScreen(profile: p, onNext: _next, onBack: _back);
      case _Step.generating:
        return _GeneratingScreen(language: p.language, onComplete: _next);
      case _Step.programResult:
        return _ProgramResultScreen(profile: p, onSave: _next);
      case _Step.welcome:
        return _WelcomeScreen(language: p.language, onContinue: _goHome);
    }
  }
}

// ============================================================
// SCREEN 1 – AUTH
// ============================================================
class _AuthScreen extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onNext;
  const _AuthScreen({required this.profile, required this.onNext});

  @override
  State<_AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<_AuthScreen> {
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _confirmPasswordCtrl;
  late bool _isLogin;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _isLogin = p.hasAccount;
    _firstNameCtrl = TextEditingController(text: p.firstName);
    _lastNameCtrl = TextEditingController(text: p.lastName);
    _emailCtrl = TextEditingController(text: p.accountEmail);
    _passwordCtrl = TextEditingController();
    _confirmPasswordCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (_isLogin) {
      return email.isNotEmpty && password.isNotEmpty;
    }
    return _firstNameCtrl.text.trim().isNotEmpty &&
        _lastNameCtrl.text.trim().isNotEmpty &&
        email.isNotEmpty &&
        password.isNotEmpty &&
        _confirmPasswordCtrl.text.isNotEmpty;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _submit() {
    final p = widget.profile;
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (_isLogin) {
      if (email.isEmpty || password.isEmpty) {
        _showSnack(p.tr('empty_credentials'));
        return;
      }
      if (!p.isValidLogin(email: email, password: password)) {
        _showSnack(p.tr('invalid_credentials'));
        return;
      }
      widget.onNext();
      return;
    }

    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final confirmPassword = _confirmPasswordCtrl.text;

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showSnack(p.tr('fill_all_fields'));
      return;
    }

    if (password != confirmPassword) {
      _showSnack(p.tr('passwords_not_match'));
      return;
    }

    p.registerAccount(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
    );
    _showSnack(p.tr('account_created'));
    widget.onNext();
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _passwordCtrl.clear();
      _confirmPasswordCtrl.clear();
    });
  }

  Widget _authField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: (_) => setState(() {}),
      style: TextStyle(color: AppTheme.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppTheme.textSecondary),
        filled: true,
        fillColor: AppTheme.surface,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    return OBScaffold(
      language: p.language,
      title: _isLogin ? p.tr('auth_title') : p.tr('register_title'),
      subtitle: _isLogin ? p.tr('auth_subtitle') : p.tr('register_subtitle'),
      btnLabel: _isLogin ? p.tr('login') : p.tr('create_account'),
      onNext: _submit,
      showBack: false,
      btnEnabled: _canSubmit,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 150,
                child: SegmentToggle(
                  labels: const ['EN', 'RU', 'KZ'],
                  selectedIndex: p.language.index,
                  onChanged: (i) => p.setLanguage(AppLanguage.values[i]),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (!_isLogin) ...[
              _authField(
                label: p.tr('first_name'),
                controller: _firstNameCtrl,
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 12),
              _authField(
                label: p.tr('last_name'),
                controller: _lastNameCtrl,
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 12),
            ],
            _authField(
              label: p.tr('email'),
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            _authField(
              label: p.tr('password'),
              controller: _passwordCtrl,
              obscureText: _hidePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _hidePassword ? Icons.visibility_off : Icons.visibility,
                  color: AppTheme.textSecondary,
                ),
                onPressed: () {
                  setState(() => _hidePassword = !_hidePassword);
                },
              ),
            ),
            if (!_isLogin) ...[
              const SizedBox(height: 12),
              _authField(
                label: p.tr('confirm_password'),
                controller: _confirmPasswordCtrl,
                obscureText: _hideConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _hideConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: () {
                    setState(
                      () => _hideConfirmPassword = !_hideConfirmPassword,
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: _toggleMode,
                child: Text(
                  _isLogin
                      ? p.tr('switch_to_register')
                      : p.tr('switch_to_login'),
                  style: TextStyle(
                    color: AppTheme.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SCREEN 2 – GENDER
// ============================================================
class _GenderScreen extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onNext, onBack;
  const _GenderScreen({
    required this.profile,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<_GenderScreen> createState() => _GenderScreenState();
}

class _GenderScreenState extends State<_GenderScreen> {
  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    return OBScaffold(
      language: p.language,
      title: p.tr('gender_title'),
      btnLabel: p.tr('continue'),
      onNext: widget.onNext,
      onBack: widget.onBack,
      btnEnabled: p.gender != null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
        child: Column(
          children: [
            SelectCard(
              label: p.tr('male'),
              isSelected: p.gender == Gender.male,
              onTap: () => setState(() => p.setGender(Gender.male)),
              leading: Icon(
                Icons.male,
                color: AppTheme.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            SelectCard(
              label: p.tr('female'),
              isSelected: p.gender == Gender.female,
              onTap: () => setState(() => p.setGender(Gender.female)),
              leading: Icon(
                Icons.female,
                color: AppTheme.textSecondary,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SCREEN 3 – BIRTHDAY
// ============================================================
class _BirthdayScreen extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onNext, onBack;
  const _BirthdayScreen({
    required this.profile,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<_BirthdayScreen> createState() => _BirthdayScreenState();
}

class _BirthdayScreenState extends State<_BirthdayScreen> {
  late int _day, _month, _year;

  @override
  void initState() {
    super.initState();
    _day = widget.profile.birthday.day;
    _month = widget.profile.birthday.month;
    _year = widget.profile.birthday.year;
  }

  void _save() {
    final maxDay = DateUtils.getDaysInMonth(_year, _month);
    if (_day > maxDay) _day = maxDay;
    widget.profile.setBirthday(DateTime(_year, _month, _day));
  }

  List<int> get _days =>
      List.generate(DateUtils.getDaysInMonth(_year, _month), (i) => i + 1);
  List<int> get _years {
    final now = DateTime.now().year;
    return List.generate(now - 1919, (i) => now - i - 4).reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    return OBScaffold(
      language: p.language,
      title: p.tr('birthday_title'),
      btnLabel: p.tr('continue'),
      onNext: widget.onNext,
      onBack: widget.onBack,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: _picker(
                _days,
                _day,
                (v) => setState(() {
                  _day = v;
                  _save();
                }),
                (v) => v.toString(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: _picker(
                List.generate(12, (i) => i + 1),
                _month,
                (v) => setState(() {
                  _month = v;
                  _save();
                }),
                (v) => AppI18n.monthName(p.language, v),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: _picker(
                _years,
                _year,
                (v) => setState(() {
                  _year = v;
                  _save();
                }),
                (v) => v.toString(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _picker<T>(
    List<T> items,
    T selected,
    ValueChanged<T> onChanged,
    String Function(T) label,
  ) {
    final idx = items.indexOf(selected).clamp(0, items.length - 1);
    final ctrl = FixedExtentScrollController(initialItem: idx);
    return SizedBox(
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVar,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          ListWheelScrollView.useDelegate(
            controller: ctrl,
            itemExtent: 52,
            perspective: 0.003,
            diameterRatio: 1.6,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (i) => onChanged(items[i]),
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: items.length,
              builder: (ctx, i) {
                final isSel = items[i] == selected;
                return Center(
                  child: Text(
                    label(items[i]),
                    style: TextStyle(
                      color: isSel ? Colors.white : AppTheme.textTertiary,
                      fontSize: isSel ? 20 : 17,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SCREEN 4 – WEIGHT
// ============================================================
class _WeightScreen extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onNext, onBack;
  const _WeightScreen({
    required this.profile,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<_WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<_WeightScreen> {
  late int _whole, _dec;
  late FixedExtentScrollController _wCtrl, _dCtrl;

  List<int> get _wholes => List.generate(281, (i) => i + 20);
  List<int> get _decs => List.generate(10, (i) => i);

  @override
  void initState() {
    super.initState();
    final w = widget.profile.weightKg;
    _whole = w.floor();
    _dec = ((w - _whole) * 10).round();
    _wCtrl = FixedExtentScrollController(initialItem: _whole - 20);
    _dCtrl = FixedExtentScrollController(initialItem: _dec);
  }

  @override
  void dispose() {
    _wCtrl.dispose();
    _dCtrl.dispose();
    super.dispose();
  }

  void _save() => widget.profile.setWeight(_whole + _dec / 10.0);

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    return OBScaffold(
      language: p.language,
      title: p.tr('weight_title'),
      btnLabel: p.tr('continue'),
      onNext: widget.onNext,
      onBack: widget.onBack,
      child: Column(
        children: [
          const Spacer(),
          SizedBox(
            height: 260,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _pickerBox(
                  _wCtrl,
                  _wholes,
                  _whole,
                  (i) {
                    setState(() => _whole = _wholes[i]);
                    _save();
                  },
                  (v) => v.toString(),
                  130,
                ),
                const SizedBox(width: 12),
                _pickerBox(
                  _dCtrl,
                  _decs,
                  _dec,
                  (i) {
                    setState(() => _dec = _decs[i]);
                    _save();
                  },
                  (v) => '.$v ${p.tr("kg")}',
                  120,
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _pickerBox<T>(
    FixedExtentScrollController ctrl,
    List<T> items,
    T selected,
    ValueChanged<int> onIdx,
    String Function(T) label,
    double width,
  ) {
    return SizedBox(
      width: width,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVar,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          ListWheelScrollView.useDelegate(
            controller: ctrl,
            itemExtent: 56,
            perspective: 0.003,
            diameterRatio: 1.8,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: onIdx,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: items.length,
              builder: (ctx, i) {
                final isSel = items[i] == selected;
                return Center(
                  child: Text(
                    label(items[i]),
                    style: TextStyle(
                      color: isSel ? Colors.white : AppTheme.textTertiary,
                      fontSize: isSel ? 22 : 17,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SCREEN 5 – HEIGHT
// ============================================================
class _HeightScreen extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onNext, onBack;
  const _HeightScreen({
    required this.profile,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<_HeightScreen> createState() => _HeightScreenState();
}

class _HeightScreenState extends State<_HeightScreen> {
  late int _cm;
  late FixedExtentScrollController _ctrl;
  final List<int> _values = List.generate(171, (i) => i + 100);

  @override
  void initState() {
    super.initState();
    _cm = widget.profile.heightCm;
    final idx = _values.indexOf(_cm).clamp(0, _values.length - 1);
    _ctrl = FixedExtentScrollController(initialItem: idx);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    return OBScaffold(
      language: p.language,
      title: p.tr('height_title'),
      btnLabel: p.tr('continue'),
      onNext: widget.onNext,
      onBack: widget.onBack,
      child: Column(
        children: [
          const Spacer(),
          SizedBox(
            height: 280,
            child: Center(
              child: SizedBox(
                width: 240,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVar,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    ListWheelScrollView.useDelegate(
                      controller: _ctrl,
                      itemExtent: 60,
                      perspective: 0.003,
                      diameterRatio: 1.8,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (i) {
                        setState(() => _cm = _values[i]);
                        widget.profile.setHeight(_values[i]);
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: _values.length,
                        builder: (ctx, i) {
                          final isSel = _values[i] == _cm;
                          return Center(
                            child: Text(
                              '${_values[i]} ${p.tr("cm")}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isSel
                                    ? Colors.white
                                    : AppTheme.textTertiary,
                                fontSize: isSel ? 22 : 17,
                                fontWeight: isSel
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

// ============================================================
// SCREEN 6 – MAIN GOAL
// ============================================================
class _GoalScreen extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onNext, onBack;
  const _GoalScreen({
    required this.profile,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<_GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<_GoalScreen> {
  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    return OBScaffold(
      language: p.language,
      title: p.tr('goal_title'),
      btnLabel: p.tr('continue'),
      onNext: widget.onNext,
      onBack: widget.onBack,
      btnEnabled: p.fitnessGoal != null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
        child: Column(
          children: [
            SelectCard(
              label: p.tr('build_muscle'),
              isSelected: p.fitnessGoal == FitnessGoal.buildMuscle,
              onTap: () => setState(() => p.setGoal(FitnessGoal.buildMuscle)),
              leading: Icon(
                Icons.fitness_center,
                color: AppTheme.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            SelectCard(
              label: p.tr('build_strength'),
              isSelected: p.fitnessGoal == FitnessGoal.buildStrength,
              onTap: () => setState(() => p.setGoal(FitnessGoal.buildStrength)),
              leading: Icon(
                Icons.sports_gymnastics,
                color: AppTheme.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            SelectCard(
              label: p.tr('lose_fat'),
              isSelected: p.fitnessGoal == FitnessGoal.loseFat,
              onTap: () => setState(() => p.setGoal(FitnessGoal.loseFat)),
              leading: Icon(
                Icons.monitor_weight_outlined,
                color: AppTheme.textSecondary,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SCREEN 7 – EXPERIENCE
// ============================================================
class _ExperienceScreen extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onNext, onBack;
  const _ExperienceScreen({
    required this.profile,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<_ExperienceScreen> createState() => _ExperienceScreenState();
}

class _ExperienceScreenState extends State<_ExperienceScreen> {
  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    return OBScaffold(
      language: p.language,
      title: p.tr('experience_title'),
      btnLabel: p.tr('continue'),
      onNext: widget.onNext,
      onBack: widget.onBack,
      btnEnabled: p.experience != null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
        child: Column(
          children: [
            SelectCard(
              label: p.tr('beginner'),
              subtitle: p.tr('experience_0_1'),
              isSelected: p.experience == ExperienceLevel.beginner,
              onTap: () =>
                  setState(() => p.setExperience(ExperienceLevel.beginner)),
            ),
            const SizedBox(height: 12),
            SelectCard(
              label: p.tr('intermediate'),
              subtitle: p.tr('experience_1_3'),
              isSelected: p.experience == ExperienceLevel.intermediate,
              onTap: () =>
                  setState(() => p.setExperience(ExperienceLevel.intermediate)),
            ),
            const SizedBox(height: 12),
            SelectCard(
              label: p.tr('advanced'),
              subtitle: p.tr('experience_3_plus'),
              isSelected: p.experience == ExperienceLevel.advanced,
              onTap: () =>
                  setState(() => p.setExperience(ExperienceLevel.advanced)),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SCREEN 8 – WORKOUT PREFERENCE
// ============================================================
class _WorkoutPrefScreen extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onNext, onBack, onSkip;
  const _WorkoutPrefScreen({
    required this.profile,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
  });

  @override
  State<_WorkoutPrefScreen> createState() => _WorkoutPrefScreenState();
}

class _WorkoutPrefScreenState extends State<_WorkoutPrefScreen> {
  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    return OBScaffold(
      language: p.language,
      title: p.tr('workout_pref_title'),
      btnLabel: p.tr('continue'),
      onNext: widget.onNext,
      onBack: widget.onBack,
      skipLabel: p.tr('skip'),
      onSkip: widget.onSkip,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
        child: Column(
          children: [
            SelectCard(
              label: p.tr('workout_self_made'),
              isSelected: p.workoutPref == WorkoutPref.selfMade,
              onTap: () =>
                  setState(() => p.setWorkoutPref(WorkoutPref.selfMade)),
            ),
            const SizedBox(height: 12),
            SelectCard(
              label: p.tr('workout_guided'),
              isSelected: p.workoutPref == WorkoutPref.guided,
              onTap: () => setState(() => p.setWorkoutPref(WorkoutPref.guided)),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SCREEN 9 – EQUIPMENT
// ============================================================
class _EquipmentScreen extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onNext, onBack;
  const _EquipmentScreen({
    required this.profile,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<_EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<_EquipmentScreen> {
  static const _items = [
    ('Full Gym', Icons.warehouse_outlined),
    ('Barbell', Icons.fitness_center),
    ('Dumbbells', Icons.sports_handball),
    ('Machine', Icons.precision_manufacturing_outlined),
    ('Resistance Bands', Icons.loop),
    ('Bodyweight', Icons.accessibility_new),
  ];

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final items = p.trainingPlace == TrainingPlace.gym
        ? _items
        : _items.where((e) => e.$1 != 'Full Gym').toList();
    return OBScaffold(
      language: p.language,
      title: p.tr('equipment_title'),
      subtitle: p.tr('select_all_apply'),
      btnLabel: p.tr('continue'),
      onNext: widget.onNext,
      onBack: widget.onBack,
      btnEnabled: p.equipment.isNotEmpty,
      progressBar: const StepBar(total: 5, current: 1),
      showPrivacy: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: ListView(
          children: items.map((e) {
            final isFullGym = e.$1 == 'Full Gym';
            final isSel = isFullGym
                ? p.equipment.contains('Full Gym')
                : p.equipment.contains(e.$1);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CheckCard(
                label: AppI18n.equipmentName(p.language, e.$1),
                isSelected: isSel,
                onTap: () => setState(() {
                  if (isFullGym) {
                    isSel ? p.clearEquipment() : p.selectAllEquipment();
                  } else {
                    p.toggleEquipment(e.$1);
                  }
                }),
                leading: Icon(e.$2, color: AppTheme.textSecondary, size: 24),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ============================================================
// SCREEN 10 – TRAINING PLACE
// ============================================================
class _PlaceScreen extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onNext, onBack;
  const _PlaceScreen({
    required this.profile,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<_PlaceScreen> createState() => _PlaceScreenState();
}

class _PlaceScreenState extends State<_PlaceScreen> {
  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    return OBScaffold(
      language: p.language,
      title: p.tr('place_title'),
      btnLabel: p.tr('continue'),
      onNext: widget.onNext,
      onBack: widget.onBack,
      progressBar: const StepBar(total: 5, current: 2),
      showPrivacy: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: Column(
          children: [
            SelectCard(
              label: p.tr('dormitory'),
              subtitle: p.tr('style_dormitory_desc'),
              isSelected: p.trainingPlace == TrainingPlace.dormitory,
              onTap: () =>
                  setState(() => p.setTrainingPlace(TrainingPlace.dormitory)),
              leading: Icon(
                Icons.apartment_outlined,
                color: AppTheme.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(height: 10),
            SelectCard(
              label: p.tr('home'),
              subtitle: p.tr('style_home_desc'),
              isSelected: p.trainingPlace == TrainingPlace.home,
              onTap: () =>
                  setState(() => p.setTrainingPlace(TrainingPlace.home)),
              leading: Icon(
                Icons.home_outlined,
                color: AppTheme.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(height: 10),
            SelectCard(
              label: p.tr('gym'),
              subtitle: p.tr('style_gym_desc'),
              isSelected: p.trainingPlace == TrainingPlace.gym,
              onTap: () =>
                  setState(() => p.setTrainingPlace(TrainingPlace.gym)),
              leading: Icon(
                Icons.fitness_center,
                color: AppTheme.textSecondary,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SCREEN 11 – FREQUENCY
// ============================================================
class _FrequencyScreen extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onNext, onBack;
  const _FrequencyScreen({
    required this.profile,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<_FrequencyScreen> createState() => _FrequencyScreenState();
}

class _FrequencyScreenState extends State<_FrequencyScreen> {
  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    return OBScaffold(
      language: p.language,
      title: p.tr('frequency_title'),
      btnLabel: p.tr('continue'),
      onNext: widget.onNext,
      onBack: widget.onBack,
      progressBar: const StepBar(total: 5, current: 3),
      showPrivacy: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: ListView(
          children: List.generate(6, (i) {
            final days = i + 1;
            final isSel = p.daysPerWeek == days;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => setState(() => p.setDays(days)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: isSel
                        ? AppTheme.accent.withValues(alpha: 0.08)
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSel ? AppTheme.accent : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        p.tr('days_per_week', args: {'days': '$days'}),
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (days == 4) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppTheme.accent,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            p.tr('recommended'),
                            style: TextStyle(
                              color: AppTheme.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      _RadioDot(isSelected: isSel),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ============================================================
// SCREEN 12 – DURATION
// ============================================================
class _DurationScreen extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onNext, onBack;
  const _DurationScreen({
    required this.profile,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<_DurationScreen> createState() => _DurationScreenState();
}

class _DurationScreenState extends State<_DurationScreen> {
  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final options = [
      (40, p.tr('duration_40')),
      (60, p.tr('duration_60')),
      (80, p.tr('duration_80')),
    ];
    return OBScaffold(
      language: p.language,
      title: p.tr('duration_title'),
      btnLabel: p.tr('continue'),
      onNext: widget.onNext,
      onBack: widget.onBack,
      progressBar: const StepBar(total: 5, current: 4),
      showPrivacy: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: Column(
          children: options.map((opt) {
            final isSel = p.durationMins == opt.$1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => setState(() => p.setDuration(opt.$1)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: isSel
                        ? AppTheme.accent.withValues(alpha: 0.08)
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSel ? AppTheme.accent : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        opt.$2,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (opt.$1 == 60) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppTheme.accent,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            p.tr('recommended'),
                            style: TextStyle(
                              color: AppTheme.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      _RadioDot(isSelected: isSel),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ============================================================
// SCREEN 13 – MUSCLE FOCUS
// ============================================================
class _MuscleFocusScreen extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onNext, onBack;
  const _MuscleFocusScreen({
    required this.profile,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<_MuscleFocusScreen> createState() => _MuscleFocusScreenState();
}

class _MuscleFocusScreenState extends State<_MuscleFocusScreen> {
  static const _muscles = [
    'Core',
    'Chest',
    'Arms',
    'Back',
    'Shoulders',
    'Legs',
    'Glutes',
  ];

  IconData _icon(String m) {
    switch (m) {
      case 'Core':
        return Icons.grid_3x3;
      case 'Chest':
        return Icons.self_improvement;
      case 'Arms':
        return Icons.sports_handball;
      case 'Back':
        return Icons.accessibility;
      case 'Shoulders':
        return Icons.expand;
      case 'Legs':
        return Icons.directions_walk;
      case 'Glutes':
        return Icons.directions_run;
      default:
        return Icons.fitness_center;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    return OBScaffold(
      language: p.language,
      title: p.tr('muscle_focus_title'),
      subtitle: p.tr('muscle_focus_subtitle'),
      btnLabel: p.tr('continue'),
      onNext: widget.onNext,
      onBack: widget.onBack,
      progressBar: const StepBar(total: 5, current: 5),
      showPrivacy: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: ListView(
          children: [
            // Balanced option
            GestureDetector(
              onTap: () => setState(() => p.setMuscleFocus(null)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: p.muscleFocus == null
                      ? AppTheme.accent.withValues(alpha: 0.15)
                      : AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: p.muscleFocus == null
                        ? AppTheme.accent
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Text(
                  p.tr('balanced_program'),
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  '+',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 20),
                ),
              ),
            ),
            ..._muscles.map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SelectCard(
                  label: AppI18n.muscleName(p.language, m),
                  isSelected: p.muscleFocus == m,
                  onTap: () => setState(() => p.setMuscleFocus(m)),
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVar,
                      borderRadius: BorderRadius.circular(21),
                    ),
                    child: Icon(
                      _icon(m),
                      color: AppTheme.textSecondary,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SCREEN 13 – GENERATING (animated loading)
// ============================================================
class _GeneratingScreen extends StatefulWidget {
  final AppLanguage language;
  final VoidCallback onComplete;
  const _GeneratingScreen({required this.language, required this.onComplete});

  @override
  State<_GeneratingScreen> createState() => _GeneratingScreenState();
}

class _GeneratingScreenState extends State<_GeneratingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _ctrl.addListener(() => setState(() => _progress = _ctrl.value));
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 400), widget.onComplete);
      }
    });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppI18n.t(widget.language, 'generating_program'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 56),
            SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(160, 160),
                    painter: _CirclePainter(progress: _progress),
                  ),
                  Text(
                    '${(_progress * 100).round()}%',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  final double progress;
  const _CirclePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 8;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = AppTheme.surfaceVar
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..color = AppTheme.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_CirclePainter old) => old.progress != progress;
}

// ============================================================
// SCREEN 14 – PROGRAM RESULT
// ============================================================
class _ProgramResultScreen extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onSave;
  const _ProgramResultScreen({required this.profile, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final p = profile;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.tr('recommended_program'),
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      p.tr('your_personal_program'),
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      p.tr('boost_goal', args: {'goal': p.goalLabel}),
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Grid
                    Row(
                      children: [
                        Expanded(
                          child: _InfoCard(
                            label: p.tr('goal'),
                            value: p.goalLabel,
                            icon: Icons.flag_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InfoCard(
                            label: p.tr('equipment'),
                            value: p.equipmentSummary,
                            icon: Icons.fitness_center,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _LevelCard(p: p)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _FreqCard(p: p, days: p.daysPerWeek),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.place_outlined,
                            color: AppTheme.accent,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${p.tr('training_place')}: ${p.trainingPlaceLabel}',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  p.trainingStyleDescription,
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      p.tr('training_strategy'),
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceVar,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Icon(
                              Icons.trending_up,
                              color: AppTheme.accent,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.tr('progressive_overload'),
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  p.tr('progressive_desc'),
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: FitButton(label: p.tr('save_program'), onTap: onSave),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _InfoCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Icon(icon, color: AppTheme.textSecondary, size: 26),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final UserProfile p;
  const _LevelCard({required this.p});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.tr('level'),
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            p.levelLabel,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(
              3,
              (i) => Container(
                width: 28,
                height: 14,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: i < p.levelIndex
                      ? AppTheme.accent
                      : AppTheme.surfaceVar,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FreqCard extends StatelessWidget {
  final UserProfile p;
  final int days;
  const _FreqCard({required this.p, required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.tr('workouts_week'),
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$days',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(
              6,
              (i) => Container(
                width: 16,
                height: 14,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: i < days ? AppTheme.accent : AppTheme.surfaceVar,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SCREEN 15 – WELCOME TO JIHC FITTRACK
// ============================================================
class _WelcomeScreen extends StatelessWidget {
  final AppLanguage language;
  final VoidCallback onContinue;
  const _WelcomeScreen({required this.language, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 20, 0),
                child: GestureDetector(
                  onTap: onContinue,
                  child: Text(
                    AppI18n.t(language, 'skip'),
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppI18n.t(language, 'welcome_title'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              AppI18n.t(language, 'welcome_subtitle'),
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 28),
            // Phone mockup
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppTheme.border),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceVar,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Icon(
                              Icons.fitness_center,
                              color: AppTheme.accent,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppI18n.t(language, 'welcome_mock_title'),
                            style: TextStyle(
                              color: AppTheme.accent,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        AppI18n.t(language, 'welcome_mock_note'),
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            color: AppTheme.accent,
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Text(
                            AppI18n.t(language, 'rest_timer'),
                            style: TextStyle(
                              color: AppTheme.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          SizedBox(
                            width: 36,
                            child: Text(
                              AppI18n.t(language, 'sets'),
                              style: TextStyle(
                                color: AppTheme.textTertiary,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              AppI18n.t(language, 'kg').toUpperCase(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.textTertiary,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              AppI18n.t(language, 'reps'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.textTertiary,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          SizedBox(width: 28),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _SetRow(
                        label: 'W',
                        kg: 20,
                        reps: 10,
                        warmup: true,
                        done: true,
                      ),
                      _SetRow(label: '1', kg: 40, reps: 8),
                      _SetRow(label: '2', kg: 40, reps: 8),
                    ],
                  ),
                ),
              ),
            ),
            // Dots
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  4,
                  (i) => Container(
                    width: i == 0 ? 20 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i == 0 ? AppTheme.accent : AppTheme.surfaceVar,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: FitButton(
                label: AppI18n.t(language, 'continue'),
                onTap: onContinue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  final String label;
  final int kg, reps;
  final bool warmup, done;
  const _SetRow({
    required this.label,
    required this.kg,
    required this.reps,
    this.warmup = false,
    this.done = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: warmup && done ? const Color(0xFF1E4620) : AppTheme.surfaceVar,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              label,
              style: TextStyle(
                color: warmup
                    ? const Color(0xFF4CAF50)
                    : AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '$kg',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              '$reps',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
            ),
          ),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: done ? const Color(0xFF4CAF50) : AppTheme.surface,
              borderRadius: BorderRadius.circular(5),
            ),
            child: done
                ? Icon(Icons.check, color: Colors.white, size: 14)
                : null,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HOME SCREEN
// ============================================================
class HomeScreen extends StatefulWidget {
  final UserProfile profile;
  const HomeScreen({super.key, required this.profile});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.profile,
      builder: (context, _) {
        final p = widget.profile;
        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(child: _buildTab()),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border(
                top: BorderSide(color: AppTheme.border, width: 0.5),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _tab,
              onTap: (i) => setState(() => _tab = i),
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppTheme.accent,
              unselectedItemColor: AppTheme.textTertiary,
              selectedLabelStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              items: [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: p.tr('tab_home'),
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.fitness_center_outlined),
                  activeIcon: Icon(Icons.fitness_center),
                  label: p.tr('tab_workouts'),
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart_outlined),
                  activeIcon: Icon(Icons.bar_chart),
                  label: p.tr('tab_progress'),
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: p.tr('tab_profile'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openWorkoutsTab() {
    setState(() => _tab = 1);
  }

  void _openExerciseVideo(ExerciseItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            _ExerciseVideoScreen(profile: widget.profile, item: item),
      ),
    );
  }

  Future<void> _logoutToOnboarding() async {
    await widget.profile.logoutToOnboarding();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => OnboardingFlow(profile: widget.profile),
      ),
      (route) => false,
    );
  }

  Widget _buildTab() {
    switch (_tab) {
      case 0:
        return _Dashboard(
          p: widget.profile,
          onOpenWorkouts: _openWorkoutsTab,
          onOpenExercise: _openExerciseVideo,
        );
      case 1:
        return _WorkoutsTab(p: widget.profile);
      case 2:
        return _ProgressTab(p: widget.profile);
      case 3:
        return _ProfileTab(
          p: widget.profile,
          onLogout: () => unawaited(_logoutToOnboarding()),
        );
      default:
        return const SizedBox();
    }
  }
}

class _Dashboard extends StatelessWidget {
  final UserProfile p;
  final VoidCallback onOpenWorkouts;
  final ValueChanged<ExerciseItem> onOpenExercise;
  const _Dashboard({
    required this.p,
    required this.onOpenWorkouts,
    required this.onOpenExercise,
  });

  @override
  Widget build(BuildContext context) {
    final todayPlan = p.todayPlan;
    ExerciseItem? startExercise;
    for (final exercise in todayPlan) {
      if (!p.isExerciseCompletedToday(exercise.id)) {
        startExercise = exercise;
        break;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${p.tr('good_morning')} 👋',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'JIHC FitTrack',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(Icons.bolt, color: AppTheme.onAccent, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.accent.withValues(alpha: 0.8),
                  AppTheme.accent.withValues(alpha: 0.4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.tr('this_week'),
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${p.weeklyCompletedCount} / ${p.daysPerWeek}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      p.tr('workouts'),
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: List.generate(
                    p.daysPerWeek,
                    (i) => Container(
                      width: 32,
                      height: 8,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: i < p.weeklyCompletedCount
                            ? AppTheme.onAccent
                            : AppTheme.onAccent.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            p.tr('your_program'),
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatMini(
                label: p.tr('goal'),
                value: p.goalLabel,
                icon: Icons.flag,
                color: AppTheme.accent,
              ),
              const SizedBox(width: 12),
              _StatMini(
                label: p.tr('level'),
                value: p.levelLabel,
                icon: Icons.bar_chart,
                color: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatMini(
                label: p.tr('per_week_short'),
                value: p.tr('days', args: {'value': '${p.daysPerWeek}'}),
                icon: Icons.calendar_today,
                color: Colors.green,
              ),
              const SizedBox(width: 12),
              _StatMini(
                label: p.tr('duration'),
                value: '${p.durationMins} ${p.tr("minutes").toLowerCase()}',
                icon: Icons.timer,
                color: Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatMini(
                label: p.tr('completed'),
                value: '${p.completedWorkoutCount}',
                icon: Icons.check_circle,
                color: AppTheme.accent,
              ),
              const SizedBox(width: 12),
              _StatMini(
                label: p.tr('calories'),
                value: '${p.totalBurnedCalories}',
                icon: Icons.local_fire_department,
                color: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      p.tr('today_plan'),
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${p.todayPlanMinutes} ${p.tr("minutes").toLowerCase()} • ${p.todayPlanCalories} kcal',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (todayPlan.isEmpty)
                  Text(
                    p.tr('complete_onboarding_plan'),
                    style: TextStyle(color: AppTheme.textSecondary),
                  )
                else
                  ...todayPlan.take(4).map((e) {
                    final doneToday = p.isExerciseCompletedToday(e.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(
                            doneToday
                                ? Icons.check_circle
                                : Icons.fitness_center,
                            color: doneToday ? Colors.green : AppTheme.accent,
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${p.localizedExerciseTitle(e)} (${e.durationMinutes} ${p.tr("minutes").toLowerCase()})',
                              style: TextStyle(
                                color: doneToday
                                    ? AppTheme.textSecondary
                                    : AppTheme.textPrimary,
                                fontSize: 13,
                                decoration: doneToday
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 6),
                FilledButton(
                  onPressed: startExercise == null
                      ? null
                      : () => onOpenExercise(startExercise!),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: AppTheme.onAccent,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  child: Text(
                    startExercise == null
                        ? (todayPlan.isEmpty
                              ? p.tr('no_plan_yet')
                              : p.tr('today_plan_done'))
                        : p.tr(
                            'start_with',
                            args: {
                              'title': p.localizedExerciseTitle(startExercise),
                            },
                          ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${p.tr('training_style')} • ${p.trainingPlaceLabel}',
                  style: TextStyle(
                    color: AppTheme.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  p.trainingStyleTitle,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  p.trainingStyleDescription,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: onOpenWorkouts,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.video_library, color: AppTheme.accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      p.tr('open_library'),
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppTheme.textTertiary,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutsTab extends StatefulWidget {
  final UserProfile p;
  const _WorkoutsTab({required this.p});

  @override
  State<_WorkoutsTab> createState() => _WorkoutsTabState();
}

class _WorkoutsTabState extends State<_WorkoutsTab> {
  String _selectedCategory = 'All';
  bool _onlyMyEquipment = true;
  bool _recommendedOnly = false;
  String _search = '';

  List<String> get _categories {
    final categories = kExerciseLibrary.map((e) => e.category).toSet().toList();
    categories.sort();
    return <String>['All', ...categories];
  }

  List<ExerciseItem> get _filtered {
    final query = _search.trim().toLowerCase();
    final base = _recommendedOnly
        ? widget.p.recommendedExercises
        : List<ExerciseItem>.from(kExerciseLibrary);

    final result = base.where((item) {
      if (_selectedCategory != 'All' && item.category != _selectedCategory) {
        return false;
      }
      if (_onlyMyEquipment && !widget.p.isExerciseAvailable(item)) {
        return false;
      }
      if (query.isEmpty) return true;
      return widget.p
              .localizedExerciseTitle(item)
              .toLowerCase()
              .contains(query) ||
          widget.p.localizedExerciseFocus(item).toLowerCase().contains(query) ||
          item.equipment.any(
            (eq) =>
                widget.p.localizedEquipment(eq).toLowerCase().contains(query),
          );
    }).toList();

    result.sort((a, b) {
      final scoreCompare = widget.p
          .recommendationScore(b)
          .compareTo(widget.p.recommendationScore(a));
      if (scoreCompare != 0) return scoreCompare;
      return a.durationMinutes.compareTo(b.durationMinutes);
    });

    return result;
  }

  void _markCompleted(ExerciseItem item) {
    widget.p.markExerciseCompleted(item);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.p.tr('session_saved')),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.p.tr('exercise_library'),
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.p.tr('exercise_library_desc'),
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                '${widget.p.tr('training_style')}: ${widget.p.trainingStyleTitle}',
                style: TextStyle(
                  color: AppTheme.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                onChanged: (v) => setState(() => _search = v),
                style: TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: widget.p.tr('search_hint'),
                  hintStyle: TextStyle(color: AppTheme.textTertiary),
                  prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _onlyMyEquipment
                          ? widget.p.tr('show_available')
                          : widget.p.tr('show_all'),
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Switch(
                    value: _onlyMyEquipment,
                    onChanged: (v) => setState(() => _onlyMyEquipment = v),
                    activeThumbColor: AppTheme.accent,
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: Text(widget.p.tr('smart_recommended')),
                    selected: _recommendedOnly,
                    onSelected: (v) => setState(() => _recommendedOnly = v),
                    selectedColor: AppTheme.accent,
                    backgroundColor: AppTheme.surface,
                    side: BorderSide(color: AppTheme.border),
                    labelStyle: TextStyle(
                      color: _recommendedOnly
                          ? AppTheme.onAccent
                          : AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final c = _categories[index];
                    final selected = c == _selectedCategory;
                    return ChoiceChip(
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedCategory = c),
                      label: Text(widget.p.localizedCategory(c)),
                      selectedColor: AppTheme.accent,
                      labelStyle: TextStyle(
                        color: selected
                            ? AppTheme.onAccent
                            : AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      backgroundColor: AppTheme.surface,
                      side: BorderSide(color: AppTheme.border),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      widget.p.tr('no_filter_match'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final available = widget.p.isExerciseAvailable(item);
                    final score = widget.p.recommendationScore(item);
                    final doneCount = widget.p.completionCountForExercise(
                      item.id,
                    );
                    return _ExerciseCard(
                      p: widget.p,
                      item: item,
                      available: available,
                      score: score,
                      doneCount: doneCount,
                      favorite: widget.p.isExerciseFavorite(item.id),
                      onFavorite: () =>
                          widget.p.toggleExerciseFavorite(item.id),
                      onDone: () => _markCompleted(item),
                      onVideo: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => _ExerciseVideoScreen(
                              profile: widget.p,
                              item: item,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final UserProfile p;
  final ExerciseItem item;
  final bool available;
  final int score;
  final int doneCount;
  final bool favorite;
  final VoidCallback onFavorite;
  final VoidCallback onDone;
  final VoidCallback onVideo;

  const _ExerciseCard({
    required this.p,
    required this.item,
    required this.available,
    required this.score,
    required this.doneCount,
    required this.favorite,
    required this.onFavorite,
    required this.onDone,
    required this.onVideo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.ondemand_video, color: AppTheme.accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.localizedExerciseTitle(item),
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${p.localizedCategory(item.category)} • ${item.durationMinutes} ${p.tr("minutes").toLowerCase()} • ${p.localizedLevel(item.level)}',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      children: [
                        _tag(
                          p.tr(
                            'match',
                            args: {'value': '${score.clamp(0, 100)}'},
                          ),
                        ),
                        if (doneCount > 0)
                          _tag(p.tr('done_x', args: {'value': '$doneCount'})),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onFavorite,
                icon: Icon(
                  favorite ? Icons.favorite : Icons.favorite_border,
                  color: favorite ? AppTheme.accent : AppTheme.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            p.localizedExerciseFocus(item),
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _tag(p.localizedSets(item.sets)),
              _tag(p.localizedReps(item.reps)),
              _tag('${item.calories} kcal'),
              ...item.equipment.map(p.localizedEquipment).map(_tag),
            ],
          ),
          if (!available) ...[
            const SizedBox(height: 8),
            Text(
              p.tr('not_in_equipment'),
              style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDone,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: BorderSide(color: AppTheme.border),
                    minimumSize: const Size.fromHeight(44),
                  ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(p.tr('done')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onVideo,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: AppTheme.onAccent,
                    minimumSize: const Size.fromHeight(44),
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(p.tr('video')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVar,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ProgressTab extends StatelessWidget {
  final UserProfile p;
  const _ProgressTab({required this.p});

  @override
  Widget build(BuildContext context) {
    final byCategory = p.categoryProgress.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topExercises = p.exerciseCompletionCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    String exerciseTitle(String id) {
      return p.localizedExerciseTitleById(id);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.tr('tab_progress'),
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            p.tr('progress_desc'),
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: p.weeklyTargetProgress,
              minHeight: 8,
              backgroundColor: AppTheme.surfaceVar,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            p.tr(
              'weekly_target',
              args: {
                'completed': '${p.weeklyCompletedCount}',
                'target': '${p.daysPerWeek}',
              },
            ),
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatMini(
                label: p.tr('completed'),
                value: '${p.completedWorkoutCount}',
                icon: Icons.check_circle,
                color: AppTheme.accent,
              ),
              const SizedBox(width: 10),
              _StatMini(
                label: p.tr('minutes'),
                value: '${p.totalCompletedMinutes}',
                icon: Icons.schedule,
                color: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatMini(
                label: p.tr('calories'),
                value: '${p.totalBurnedCalories}',
                icon: Icons.local_fire_department,
                color: Colors.orange,
              ),
              const SizedBox(width: 10),
              _StatMini(
                label: p.tr('favorites'),
                value:
                    '${kExerciseLibrary.where((e) => p.isExerciseFavorite(e.id)).length}',
                icon: Icons.favorite,
                color: AppTheme.accent,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatMini(
                label: p.tr('streak'),
                value: p.tr('days', args: {'value': '${p.currentStreakDays}'}),
                icon: Icons.local_fire_department,
                color: Colors.orange,
              ),
              const SizedBox(width: 10),
              _StatMini(
                label: p.tr('consistency'),
                value: '${p.consistencyScore.round()}%',
                icon: Icons.trending_up,
                color: AppTheme.accent,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            p.tr('category_breakdown'),
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (byCategory.isEmpty)
            _emptyTile(p.tr('complete_for_stats'))
          else
            ...byCategory.map(
              (entry) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        p.localizedCategory(entry.key),
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      p.tr('times_done', args: {'value': '${entry.value}'}),
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            p.tr('most_trained'),
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (topExercises.isEmpty)
            _emptyTile(p.tr('no_frequency_data'))
          else
            ...topExercises
                .take(5)
                .map(
                  (entry) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.bar_chart, color: AppTheme.accent, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            exerciseTitle(entry.key),
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${entry.value}x',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          const SizedBox(height: 12),
          Text(
            p.tr('recent_sessions'),
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (p.completedSessions.isEmpty)
            _emptyTile(p.tr('no_sessions'))
          else
            ...p.completedSessions
                .take(8)
                .map(
                  (s) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppTheme.accent,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.localizedExerciseTitleById(s.exerciseId),
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${p.localizedCategory(s.category)} • ${s.durationMinutes} ${p.tr("minutes").toLowerCase()} • ${s.calories} kcal',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => p.removeCompletedSession(s),
                          icon: Icon(
                            Icons.delete_outline,
                            color: AppTheme.textTertiary,
                          ),
                          tooltip: p.tr('delete'),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _emptyTile(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message, style: TextStyle(color: AppTheme.textSecondary)),
    );
  }
}

class _ExerciseVideoScreen extends StatefulWidget {
  final UserProfile profile;
  final ExerciseItem item;

  const _ExerciseVideoScreen({required this.profile, required this.item});

  @override
  State<_ExerciseVideoScreen> createState() => _ExerciseVideoScreenState();
}

class _ExerciseVideoScreenState extends State<_ExerciseVideoScreen>
    with WidgetsBindingObserver {
  VideoPlayerController? _videoController;
  Timer? _ticker;
  bool _isRunning = false;
  bool _isRestPhase = false;
  bool _sessionComplete = false;
  bool _sessionSaved = false;
  bool _videoLoading = true;
  bool _videoFailed = false;
  bool _videoPlaying = false;
  int _currentRound = 1;
  late int _secondsRemaining;

  String get _assetVideoPath => 'assets/videos/${widget.item.id}.mp4';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _secondsRemaining = widget.item.workSeconds;
    unawaited(_initializeVideo());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    final controller = _videoController;
    _videoController = null;
    if (controller != null) {
      controller.removeListener(_onVideoValueChanged);
      unawaited(controller.dispose());
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _videoController;
    if (controller == null) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      unawaited(controller.pause());
      return;
    }
    if (state == AppLifecycleState.resumed && !_videoFailed) {
      if (controller.value.isInitialized && !_sessionComplete) {
        unawaited(controller.play());
      } else {
        unawaited(_initializeVideo());
      }
    }
  }

  void _onVideoValueChanged() {
    final controller = _videoController;
    if (!mounted || controller == null) return;
    final value = controller.value;
    final hasError = value.hasError;
    final isPlaying = value.isPlaying;
    if (hasError && !_videoFailed) {
      setState(() {
        _videoFailed = true;
        _videoLoading = false;
        _videoPlaying = false;
      });
      return;
    }
    if (_videoPlaying != isPlaying) {
      setState(() => _videoPlaying = isPlaying);
    }
  }

  Future<void> _initializeVideo() async {
    setState(() {
      _videoLoading = true;
      _videoFailed = false;
      _videoPlaying = false;
    });

    final controller = VideoPlayerController.asset(_assetVideoPath);
    controller.addListener(_onVideoValueChanged);
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      if (!mounted) {
        controller.removeListener(_onVideoValueChanged);
        await controller.dispose();
        return;
      }

      final oldController = _videoController;
      setState(() {
        _videoController = controller;
        _videoLoading = false;
        _videoFailed = false;
        _videoPlaying = true;
      });
      if (oldController != null) {
        oldController.removeListener(_onVideoValueChanged);
        unawaited(oldController.dispose());
      }
    } catch (_) {
      controller.removeListener(_onVideoValueChanged);
      await controller.dispose();
      if (!mounted) return;
      setState(() {
        _videoLoading = false;
        _videoFailed = true;
        _videoPlaying = false;
      });
    }
  }

  Future<void> _toggleVideoPlayback() async {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;

    if (controller.value.isPlaying) {
      await controller.pause();
      if (!mounted) return;
      setState(() => _videoPlaying = false);
      return;
    }

    await controller.play();
    if (!mounted) return;
    setState(() => _videoPlaying = true);
  }

  Future<void> _restartVideo() async {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;

    await controller.seekTo(Duration.zero);
    await controller.play();
    if (!mounted) return;
    setState(() => _videoPlaying = true);
  }

  void _toggleTimer() {
    if (_sessionComplete) return;
    if (_isRunning) {
      _ticker?.cancel();
      _isRunning = false;
      setState(() {});
      return;
    }

    _isRunning = true;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_secondsRemaining <= 1) {
        _advancePhase();
      } else {
        setState(() => _secondsRemaining -= 1);
      }
    });
    setState(() {});
  }

  void _advancePhase() {
    if (_sessionComplete) return;
    final item = widget.item;

    if (_isRestPhase) {
      if (_currentRound >= item.rounds) {
        _completeSession();
        return;
      }
      setState(() {
        _currentRound += 1;
        _isRestPhase = false;
        _secondsRemaining = item.workSeconds;
      });
      return;
    }

    if (item.restSeconds <= 0) {
      if (_currentRound >= item.rounds) {
        _completeSession();
      } else {
        setState(() {
          _currentRound += 1;
          _secondsRemaining = item.workSeconds;
        });
      }
      return;
    }

    setState(() {
      _isRestPhase = true;
      _secondsRemaining = item.restSeconds;
    });
  }

  void _completeSession() {
    _ticker?.cancel();
    final video = _videoController;
    if (video != null && video.value.isPlaying) {
      unawaited(video.pause());
    }
    setState(() {
      _isRunning = false;
      _sessionComplete = true;
      _isRestPhase = false;
      _secondsRemaining = 0;
      _videoPlaying = false;
    });
    _saveSession(fromTimer: true);
  }

  void _resetTimer() {
    _ticker?.cancel();
    setState(() {
      _isRunning = false;
      _isRestPhase = false;
      _sessionComplete = false;
      _sessionSaved = false;
      _currentRound = 1;
      _secondsRemaining = widget.item.workSeconds;
    });
  }

  void _skipPhase() {
    _advancePhase();
  }

  void _saveSession({bool fromTimer = false}) {
    if (_sessionSaved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.profile.tr('session_saved_once'))),
      );
      return;
    }
    widget.profile.markExerciseCompleted(widget.item);
    _sessionSaved = true;
    final key = fromTimer ? 'timer_auto_saved' : 'session_saved';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(widget.profile.tr(key))));
  }

  String _formatTimer(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final m = minutes.toString().padLeft(2, '0');
    final s = seconds.toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _progressValue {
    if (_sessionComplete) return 1;
    final total =
        widget.item.rounds *
        (widget.item.workSeconds + widget.item.restSeconds);
    if (total <= 0) return 0;

    final perRound = widget.item.workSeconds + widget.item.restSeconds;
    var elapsed = (_currentRound - 1) * perRound;
    if (_isRestPhase) {
      elapsed +=
          widget.item.workSeconds +
          (widget.item.restSeconds - _secondsRemaining);
    } else {
      elapsed += widget.item.workSeconds - _secondsRemaining;
    }

    return (elapsed / total).clamp(0, 1);
  }

  Widget _buildVideoCard(UserProfile p) {
    final controller = _videoController;
    final initialized = controller != null && controller.value.isInitialized;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 240,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(color: AppTheme.surfaceVar),
            if (initialized)
              Center(
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio <= 0
                      ? (16 / 9)
                      : controller.value.aspectRatio,
                  child: VideoPlayer(controller),
                ),
              ),
            if (initialized)
              Positioned(
                left: 12,
                bottom: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: _toggleVideoPlayback,
                        tooltip: _videoPlaying ? p.tr('pause') : p.tr('start'),
                        icon: Icon(
                          _videoPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: _restartVideo,
                        tooltip: p.tr('reset'),
                        icon: const Icon(Icons.replay, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            if (_videoFailed)
              Container(
                color: AppTheme.surface,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppTheme.textSecondary,
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      p.tr('video_embed_failed'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _initializeVideo,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary,
                        side: BorderSide(color: AppTheme.border),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: Text(p.tr('retry_video')),
                    ),
                  ],
                ),
              ),
            if (!initialized && !_videoLoading && !_videoFailed)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.ondemand_video_outlined,
                    color: AppTheme.textSecondary,
                    size: 30,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.tr('video'),
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            if (_videoLoading)
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final item = widget.item;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(p.localizedExerciseTitle(item)),
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.textPrimary,
        actions: [
          IconButton(
            onPressed: () => setState(
              () => widget.profile.toggleExerciseFavorite(widget.item.id),
            ),
            icon: Icon(
              widget.profile.isExerciseFavorite(widget.item.id)
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: AppTheme.accent,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        children: [
          _buildVideoCard(p),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.tr('workout_timer'),
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${p.tr('round')} $_currentRound/${item.rounds}',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _sessionComplete
                            ? p.tr('session_complete')
                            : (_isRestPhase ? p.tr('rest') : p.tr('work')),
                        style: TextStyle(
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      _formatTimer(_secondsRemaining),
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: _progressValue,
                    backgroundColor: AppTheme.surfaceVar,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _sessionComplete ? null : _toggleTimer,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          foregroundColor: AppTheme.onAccent,
                          minimumSize: const Size.fromHeight(42),
                        ),
                        icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                        label: Text(_isRunning ? p.tr('pause') : p.tr('start')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _resetTimer,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textPrimary,
                          side: BorderSide(color: AppTheme.border),
                          minimumSize: const Size.fromHeight(42),
                        ),
                        icon: const Icon(Icons.refresh),
                        label: Text(p.tr('reset')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _sessionComplete ? null : _skipPhase,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textPrimary,
                          side: BorderSide(color: AppTheme.border),
                          minimumSize: const Size.fromHeight(42),
                        ),
                        icon: const Icon(Icons.skip_next),
                        label: Text(p.tr('next_phase')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.localizedCategory(item.category),
                  style: TextStyle(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  p.localizedExerciseFocus(item),
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                ),
                const SizedBox(height: 10),
                Text(
                  p.tr(
                    'prescription',
                    args: {
                      'sets': p.localizedSets(item.sets),
                      'reps': p.localizedReps(item.reps),
                    },
                  ),
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 6),
                Text(
                  p.tr(
                    'coach_tip',
                    args: {'tip': p.localizedExerciseTip(item)},
                  ),
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FitButton(label: p.tr('mark_completed'), onTap: _saveSession),
        ],
      ),
    );
  }
}

class _StatMini extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatMini({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  final UserProfile p;
  final VoidCallback onLogout;
  const _ProfileTab({required this.p, required this.onLogout});

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.surface,
            title: Text(
              p.tr('logout_confirm_title'),
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            content: Text(
              p.tr('logout_confirm_message'),
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(p.tr('cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(p.tr('confirm')),
              ),
            ],
          ),
        ) ??
        false;

    if (shouldLogout) {
      onLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final weightText = '${p.weightKg.toStringAsFixed(1)} ${p.tr('kg')}';
    final heightText = '${p.heightCm} ${p.tr('cm')}';
    final firstNameText = p.firstName.isEmpty ? '-' : p.firstName;
    final lastNameText = p.lastName.isEmpty ? '-' : p.lastName;
    final emailText = p.accountEmail.isEmpty ? '-' : p.accountEmail;
    final birthdayText =
        '${p.birthday.day}/${p.birthday.month}/${p.birthday.year}';
    final weeklyTargetText = p.tr(
      'weekly_target',
      args: {
        'completed': '${p.weeklyCompletedCount}',
        'target': '${p.daysPerWeek}',
      },
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.tr('tab_profile'),
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  p.isDarkMode
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  color: AppTheme.accent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.tr('appearance'),
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        p.isDarkMode ? p.tr('dark_mode') : p.tr('light_mode'),
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: p.isDarkMode,
                  onChanged: (v) =>
                      p.setThemeMode(v ? ThemeMode.dark : ThemeMode.light),
                  activeThumbColor: AppTheme.accent,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.language, color: AppTheme.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.tr('language'),
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppI18n.languageName(p.language, p.language),
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: SegmentToggle(
                    labels: const ['EN', 'RU', 'KZ'],
                    selectedIndex: p.language.index,
                    onChanged: (i) => p.setLanguage(AppLanguage.values[i]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.place_outlined, color: AppTheme.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.tr('training_place'),
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        p.trainingStyleTitle,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                DropdownButton<TrainingPlace>(
                  value: p.trainingPlace,
                  dropdownColor: AppTheme.surfaceVar,
                  underline: const SizedBox.shrink(),
                  style: TextStyle(color: AppTheme.textPrimary),
                  onChanged: (value) {
                    if (value != null) p.setTrainingPlace(value);
                  },
                  items: TrainingPlace.values
                      .map(
                        (place) => DropdownMenuItem<TrainingPlace>(
                          value: place,
                          child: Text(AppI18n.placeName(p.language, place)),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            p.tr('account'),
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _ProfileGridCard(
            rows: [
              _ProfileFieldPair(
                left: _ProfileFieldData(p.tr('first_name'), firstNameText),
                right: _ProfileFieldData(p.tr('last_name'), lastNameText),
              ),
              _ProfileFieldPair(
                left: _ProfileFieldData(p.tr('email'), emailText),
                right: _ProfileFieldData(
                  p.tr('gender'),
                  AppI18n.genderName(p.language, p.gender),
                ),
              ),
              _ProfileFieldPair(
                left: _ProfileFieldData(p.tr('birthday'), birthdayText),
                right: _ProfileFieldData(p.tr('height'), heightText),
              ),
              _ProfileFieldPair(
                left: _ProfileFieldData(p.tr('weight'), weightText),
                right: _ProfileFieldData(p.tr('goal'), p.goalLabel),
              ),
              _ProfileFieldPair(
                left: _ProfileFieldData(p.tr('level'), p.levelLabel),
                right: _ProfileFieldData(
                  p.tr('training_place'),
                  p.trainingPlaceLabel,
                ),
              ),
              _ProfileFieldPair(
                left: _ProfileFieldData(
                  p.tr('training_style'),
                  p.trainingStyleTitle,
                ),
                right: _ProfileFieldData(p.tr('equipment'), p.equipmentSummary),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            p.tr('tab_progress'),
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _ProfileGridCard(
            rows: [
              _ProfileFieldPair(
                left: _ProfileFieldData(
                  p.tr('completed'),
                  '${p.completedWorkoutCount}',
                ),
                right: _ProfileFieldData(
                  p.tr('minutes'),
                  '${p.totalCompletedMinutes}',
                ),
              ),
              _ProfileFieldPair(
                left: _ProfileFieldData(
                  p.tr('calories'),
                  '${p.totalBurnedCalories}',
                ),
                right: _ProfileFieldData(
                  p.tr('streak'),
                  '${p.currentStreakDays}',
                ),
              ),
              _ProfileFieldPair(
                left: _ProfileFieldData(
                  p.tr('consistency'),
                  '${p.consistencyScore.round()}%',
                ),
                right: _ProfileFieldData(
                  p.tr('days_week'),
                  '${p.weeklyCompletedCount}/${p.daysPerWeek}',
                ),
              ),
            ],
            footer: weeklyTargetText,
          ),
          const SizedBox(height: 18),
          FitButton(
            label: p.tr('logout'),
            onTap: () => unawaited(_handleLogout(context)),
          ),
          const SizedBox(height: 10),
          Text(
            p.tr('logout_desc'),
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ProfileGridCard extends StatelessWidget {
  final List<_ProfileFieldPair> rows;
  final String? footer;
  const _ProfileGridCard({required this.rows, this.footer});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: AppTheme.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _ProfileField(data: rows[i].left)),
                  Container(width: 1, height: 48, color: AppTheme.border),
                  const SizedBox(width: 12),
                  Expanded(child: _ProfileField(data: rows[i].right)),
                ],
              ),
            ),
          ],
          if (footer != null) ...[
            Divider(height: 1, thickness: 1, color: AppTheme.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  footer!,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileFieldPair {
  final _ProfileFieldData left;
  final _ProfileFieldData right;
  const _ProfileFieldPair({required this.left, required this.right});
}

class _ProfileFieldData {
  final String label;
  final String value;
  const _ProfileFieldData(this.label, this.value);
}

class _ProfileField extends StatelessWidget {
  final _ProfileFieldData data;
  const _ProfileField({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          data.value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
