/// Centralized string constants for FitGenie app.
///
/// This class provides a single source of truth for all user-facing text,
/// enabling consistency and future localization support.
///
/// Organization:
/// - App-wide constants (name, taglines)
/// - Feature-specific sections (auth, onboarding, dashboard, etc.)
/// - Error messages
/// - Success messages
/// - Validation messages
///
/// All strings are static const for compile-time optimization.
class AppStrings {
  AppStrings._(); // Private constructor to prevent instantiation

  // ============================================================================
  // APP BRANDING
  // ============================================================================

  static const String appName = 'FitGenie';
  static const String appTagline = 'Your AI Personal Trainer & Nutritionist';
  static const String appTaglineShort = 'AI-Powered Fitness & Nutrition';

  // ============================================================================
  // AUTHENTICATION
  // ============================================================================

  // Screen titles
  static const String loginTitle = 'Welcome Back';
  static const String registerTitle = 'Create Account';
  static const String forgotPasswordTitle = 'Reset Password';
  static const String forgotPasswordEmailSentTitle = 'Email Sent!';

  // Screen subtitles
  static const String loginSubtitle =
      'Sign in to continue your fitness journey';
  static const String registerSubtitle =
      'Start your personalized fitness journey';
  static const String forgotPasswordEnterEmailSubtitle =
      'Enter your email to receive a password reset link';
  static const String forgotPasswordCheckInboxSubtitle =
      'Check your inbox for password reset instructions';

  // Labels
  static const String labelEmail = 'Email';
  static const String labelPassword = 'Password';
  static const String labelConfirmPassword = 'Confirm Password';
  static const String labelName = 'Name';

  // Placeholders and hints
  static const String placeholderEmail = 'your.email@example.com';
  static const String placeholderPassword = '••••••••';
  static const String placeholderName = 'John Doe';
  static const String hintEnterEmail = 'Enter your email';
  static const String hintEnterPassword = 'Enter your password';
  static const String hintCreatePassword = 'Create a password';

  // Buttons
  static const String buttonLogin = 'Login';
  static const String buttonRegister = 'Register';
  static const String buttonLogout = 'Logout';
  static const String buttonForgotPassword = 'Forgot password?';
  static const String buttonResetPassword = 'Reset Password';
  static const String buttonSendResetLink = 'Send Reset Link';
  static const String buttonReturnToLogin = 'Return to Login';
  static const String buttonSignIn = 'Sign in';
  static const String buttonSignUp = 'Sign up';

  // Messages
  static const String messageAlreadyHaveAccount = 'Already have an account? ';
  static const String messageDontHaveAccount = "Don't have an account? ";
  static const String messageResetPasswordSent =
      'Password reset link sent to your email';
  static const String messageLoginSuccess = 'Welcome back!';
  static const String messageRegisterSuccess = 'Account created successfully!';

  // Forgot Password specific messages
  static const String forgotPasswordResetLinkSentPrefix =
      'We\'ve sent a password reset link to:';
  static const String forgotPasswordInstructions =
      'Please check your inbox and follow the instructions to reset your password.';
  static const String forgotPasswordSpamFolderHelp =
      'If you don\'t receive an email within a few minutes, '
      'check your spam folder or try again.';

  // Terms and Privacy
  static const String termsAcceptancePrefix = 'I agree to the ';
  static const String termsOfService = 'Terms of Service';
  static const String termsConnector = ' and ';
  static const String privacyPolicy = 'Privacy Policy';

  // Validation hints
  static const String hintPasswordRequirements =
      'Password must be at least 8 characters';

  // ============================================================================
  // ONBOARDING
  // ============================================================================

  // Welcome step
  static const String onboardingWelcomeTitle = 'Welcome to FitGenie';
  static const String onboardingWelcomeDescription =
      'Let\'s create your personalized fitness and nutrition plan. This will only take a minute.';
  static const String buttonGetStarted = 'Get Started';

  // Age & Weight step
  static const String onboardingAgeTitle = 'Tell us about yourself';
  static const String onboardingAgeDescription =
      'This helps us create a safe and effective plan for you.';
  static const String labelAge = 'Age';
  static const String labelWeight = 'Weight';
  static const String labelWeightUnit = 'Unit';
  static const String unitKg = 'kg';
  static const String unitLbs = 'lbs';

  // Height step
  static const String onboardingHeightTitle = 'Your height';
  static const String onboardingHeightDescription =
      'We\'ll use this to calculate your fitness metrics.';
  static const String labelHeight = 'Height';
  static const String labelHeightUnit = 'Unit';
  static const String unitCm = 'cm';
  static const String unitFtIn = 'ft/in';

  // Goal step
  static const String onboardingGoalTitle = 'What\'s your goal?';
  static const String onboardingGoalDescription =
      'Choose the fitness goal that matters most to you right now.';
  static const String goalMuscleGain = 'Build Muscle';
  static const String goalWeightLoss = 'Lose Weight';
  static const String goalGeneralFitness = 'General Fitness';
  static const String goalEndurance = 'Improve Endurance';

  // Equipment step
  static const String onboardingEquipmentTitle = 'Available equipment';
  static const String onboardingEquipmentDescription =
      'Select what equipment you have access to. We\'ll create workouts using only these.';
  static const String equipmentFullGym = 'Full Gym Access';
  static const String equipmentHomeGym = 'Home Gym';
  static const String equipmentBodyweight = 'Bodyweight Only';
  static const String equipmentMixed = 'Mixed/Custom';
  static const String labelEquipmentDetails = 'Specify your equipment';
  static const String placeholderEquipmentDetails =
      'e.g., dumbbells, pull-up bar, yoga mat';

  // Dietary step
  static const String onboardingDietaryTitle = 'Dietary preferences';
  static const String onboardingDietaryDescription =
      'Select any dietary restrictions. All meals will respect these choices.';
  static const String labelDietaryNotes = 'Additional notes (optional)';
  static const String placeholderDietaryNotes =
      'e.g., allergies, food preferences, meal timing';

  // Review step
  static const String onboardingReviewTitle = 'Review your profile';
  static const String onboardingReviewDescription =
      'Everything look good? You can always update this later.';
  static const String buttonEditProfile = 'Edit';
  static const String buttonGeneratePlan = 'Generate My Plan';

  // Navigation
  static const String buttonNext = 'Next';
  static const String buttonBack = 'Back';
  static const String buttonSkip = 'Skip';

  // ============================================================================
  // PLAN GENERATION
  // ============================================================================

  static const String planGenerationTitle = 'Creating Your Plan';
  static const String planGenerationDescription =
      'Our AI is analyzing your profile and generating a personalized 7-day plan...';
  static const String planGenerationStatusAnalyzing = 'Analyzing your profile';
  static const String planGenerationStatusCreatingWorkouts =
      'Creating custom workouts';
  static const String planGenerationStatusCreatingMeals = 'Planning your meals';
  static const String planGenerationStatusFinalizing = 'Finalizing your plan';
  static const String planGenerationComplete = 'Your plan is ready!';
  static const String buttonViewPlan = 'View My Plan';

  // ============================================================================
  // DASHBOARD
  // ============================================================================

  // Navigation
  static const String navPlan = 'Plan';
  static const String navChat = 'Chat';
  static const String navProfile = 'Profile';

  // Today's plan
  static const String todayTitle = 'Today\'s Plan';
  static const String noPlanTitle = 'No Plan Yet';
  static const String noPlanDescription =
      'Generate your first personalized plan to get started!';
  static const String buttonGenerate = 'Generate Plan';

  // Days of week
  static const String monday = 'Monday';
  static const String tuesday = 'Tuesday';
  static const String wednesday = 'Wednesday';
  static const String thursday = 'Thursday';
  static const String friday = 'Friday';
  static const String saturday = 'Saturday';
  static const String sunday = 'Sunday';

  // Short days
  static const String mon = 'Mon';
  static const String tue = 'Tue';
  static const String wed = 'Wed';
  static const String thu = 'Thu';
  static const String fri = 'Fri';
  static const String sat = 'Sat';
  static const String sun = 'Sun';

  // Tasks
  static const String taskBreakfast = 'Breakfast';
  static const String taskLunch = 'Lunch';
  static const String taskDinner = 'Dinner';
  static const String taskWorkout = 'Workout';

  // Workout details
  static const String labelDuration = 'Duration';
  static const String labelWarmup = 'Warm-up';
  static const String labelExercises = 'Exercises';
  static const String labelCooldown = 'Cool-down';
  static const String labelSets = 'Sets';
  static const String labelReps = 'Reps';
  static const String labelRest = 'Rest';
  static const String labelInstructions = 'Instructions';

  // Meal details
  static const String labelIngredients = 'Ingredients';
  static const String labelCalories = 'Calories';
  static const String labelProtein = 'Protein';
  static const String labelCarbs = 'Carbs';
  static const String labelFat = 'Fat';

  // Completion
  static const String messageTaskComplete = 'Great work!';
  static const String messageAllTasksComplete = 'All done for today! 🎉';
  static const String messageDayComplete =
      'You\'ve completed everything today. Keep it up!';

  // Streak
  static const String streakLabel = 'Day Streak';
  static const String streakDays = 'days';
  static const String streakLongest = 'Longest';

  // ============================================================================
  // CHAT & MODIFICATIONS
  // ============================================================================

  static const String chatTitle = 'Modify Your Plan';
  static const String chatDescription =
      'Ask me to adjust your workouts or meals. I\'ll update your plan instantly!';
  static const String chatPlaceholder = 'Type your request...';
  static const String buttonSend = 'Send';

  // Quick modification chips
  static const String chipSkipWorkout = 'Skip today\'s workout';
  static const String chipEasierWorkout = 'Make workout easier';
  static const String chipHarderWorkout = 'Make workout harder';
  static const String chipSwapMeal = 'Swap a meal';
  static const String chipVegetarianMeal = 'Make meal vegetarian';
  static const String chipQuickerMeal = 'Simpler recipe';

  // Chat status
  static const String chatStatusThinking = 'Thinking...';
  static const String chatStatusUpdating = 'Updating your plan...';
  static const String chatStatusComplete = 'Plan updated!';

  // ============================================================================
  // PROFILE
  // ============================================================================

  static const String profileTitle = 'Profile';
  static const String profileEditTitle = 'Edit Profile';
  static const String profileStatsTitle = 'Your Progress';

  // Sections
  static const String sectionPersonalInfo = 'Personal Information';
  static const String sectionGoal = 'Fitness Goal';
  static const String sectionEquipment = 'Equipment';
  static const String sectionDietary = 'Dietary Restrictions';
  static const String sectionAccount = 'Account';
  static const String sectionSettings = 'Settings';

  // Stats
  static const String statCurrentStreak = 'Current Streak';
  static const String statLongestStreak = 'Longest Streak';
  static const String statTotalWorkouts = 'Total Workouts';
  static const String statTotalMeals = 'Meals Completed';
  static const String statPlansGenerated = 'Plans Generated';

  // Settings
  static const String settingNotifications = 'Notifications';
  static const String settingDarkMode = 'Dark Mode';
  static const String settingUnits = 'Measurement Units';

  // Actions
  static const String buttonSave = 'Save Changes';
  static const String buttonCancel = 'Cancel';
  static const String buttonDeleteAccount = 'Delete Account';
  static const String buttonSignOut = 'Sign Out';

  // ============================================================================
  // ERROR MESSAGES
  // ============================================================================

  // Authentication errors (user-friendly versions)
  static const String errorInvalidEmail = 'Please enter a valid email address';
  static const String errorWeakPassword =
      'Password must be at least 6 characters';
  static const String errorPasswordMismatch = 'Passwords don\'t match';
  static const String errorWrongPassword =
      'Incorrect password. Please try again.';
  static const String errorUserNotFound = 'No account found with this email';
  static const String errorEmailInUse = 'This email is already registered';
  static const String errorRequiredField = 'This field is required';
  static const String errorSendResetFailed =
      'Failed to send reset email. Please try again.';
  static const String errorTermsAcceptanceRequired =
      'Please accept the Terms of Service to continue.';

  // Network errors
  static const String errorNoConnection =
      'No internet connection. Please check your network.';
  static const String errorTimeout = 'Request timed out. Please try again.';
  static const String errorServerError =
      'Server error. Please try again later.';
  static const String errorUnknown = 'Something went wrong. Please try again.';

  // AI errors
  static const String errorAiRateLimited =
      'Our AI is taking a short break. Please wait a moment.';
  static const String errorAiInvalidResponse =
      'Unable to generate plan. Retrying...';
  static const String errorAiTimeout =
      'AI request timed out. Please try again.';
  static const String errorAiGeneration =
      'Couldn\'t generate plan. Please try again.';

  // Sync errors
  static const String errorSyncFailed = 'Sync failed. Will retry when online.';
  static const String errorSyncConflict =
      'Data conflict detected. Using most recent version.';
  static const String errorOfflineMode =
      'You\'re offline. Changes will sync when connected.';

  // Onboarding repository errors
  static const String errorSaveProfileFailed =
      'Failed to save profile. Please try again.';
  static const String errorLoadProfileFailed =
      'Failed to load profile. Please try again.';
  static const String errorDeleteProfileFailed =
      'Failed to delete profile. Please try again.';
  static const String errorClearCacheFailed =
      'Failed to clear cache. Please try again.';
  static const String errorCompleteOnboardingFailed =
      'Failed to complete onboarding. Please try again.';

  // Validation errors
  static const String errorAlphabeticOnly =
      'This field accepts alphabetic characters only';
  static const String errorNumericOnly =
      'This field accepts numeric characters only';
  static const String errorInvalidAge = 'Please enter a valid age (13-120)';
  static const String errorInvalidWeight =
      'Please enter a valid weight (30-500)';
  static const String errorInvalidHeight =
      'Please enter a valid height (100-250 cm)';
  static const String errorNoGoalSelected = 'Please select a fitness goal';
  static const String errorNoEquipmentSelected = 'Please select your equipment';

  // Generic errors
  static const String errorGeneric =
      'An unexpected error occurred. Please try again later or contact support.';

  // ============================================================================
  // SUCCESS MESSAGES
  // ============================================================================

  static const String successProfileUpdated = 'Profile updated successfully!';
  static const String successPlanGenerated = 'Your plan is ready!';
  static const String successTaskCompleted = 'Task completed!';
  static const String successPlanModified = 'Plan updated successfully!';
  static const String successPasswordReset = 'Password reset email sent!';

  // ============================================================================
  // CONFIRMATION MESSAGES
  // ============================================================================

  static const String confirmDeleteAccount =
      'Are you sure you want to delete your account? This cannot be undone.';
  static const String confirmSignOut = 'Are you sure you want to sign out?';
  static const String confirmSkipWorkout =
      'Skip today\'s workout? This won\'t affect your streak.';

  // ============================================================================
  // GENERAL UI
  // ============================================================================

  static const String buttonOk = 'OK';
  static const String buttonYes = 'Yes';
  static const String buttonNo = 'No';
  static const String buttonRetry = 'Retry';
  static const String buttonClose = 'Close';
  static const String buttonUndo = 'Undo';

  static const String labelLoading = 'Loading...';
  static const String labelOffline = 'Offline';
  static const String labelOnline = 'Connected';

  static const String emptyStateTitle = 'Nothing here yet';
  static const String emptyStateDescription =
      'Content will appear here once you get started.';

  // ============================================================================
  // WELCOME BACK MESSAGES
  // ============================================================================

  static const String welcomeBack = 'Welcome back!';
  static const String welcomeBackMorning = 'Good morning!';
  static const String welcomeBackAfternoon = 'Good afternoon!';
  static const String welcomeBackEvening = 'Good evening!';
  static const String welcomeBackLapsed =
      'Great to see you again! Ready to pick up where you left off?';

  // ============================================================================
  // MOTIVATION MESSAGES
  // ============================================================================

  static const String motivationConsistency = 'Consistency is key! Keep it up.';
  static const String motivationStreak = 'Amazing streak! You\'re on fire! 🔥';
  static const String motivationFirstDay = 'Great start! Come back tomorrow.';
  static const String motivationWeekComplete = 'Week complete! Fantastic work!';
  static const String motivationMilestone =
      'Milestone reached! You\'re amazing!';
}
