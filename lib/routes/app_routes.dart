abstract class Routes {
  static const init = _Paths.init;
  static const language = _Paths.language; // Added
  static const onboarding = _Paths.onboarding; // Maps to Character Selector
  static const home = _Paths.home;

  Routes._();
}

abstract class _Paths {
  static const init = "/";
  static const language = '/language-selector'; // Added
  static const onboarding = '/onboarding';
  static const home = '/home';
  _Paths._();
}

abstract class Names {
  static const init = _Names.init;
  static const language = _Names.language; // Added
  static const onboarding = _Names.onboarding;
  static const home = _Names.home;
  Names._();
}

abstract class _Names {
  static const init = 'init';
  static const language = 'language'; // Added
  static const onboarding = 'onboarding';
  static const home = 'home';
  _Names._();
}
