# Setup
This client uses Flutter to support frontends on iOS, Android, and web.

## Install Flutter
https://docs.flutter.dev/get-started/install/macos

## Fix platform dependencies
`flutter doctor`

## Setup vim Flutter and Dart plugins
1. https://github.com/dart-lang/dart-vim-plugin
2. https://github.com/thosakwe/vim-flutter

## Init project
`flutter create .`

## Init FlutterFire
This lets us attach to Firebase.
First, make sure you've got a non-system Ruby and cocoapods installed.
Next, run the following, reproduced here verbatim from the fireflutter docs:
```bash
# Install the CLI if not already done so
dart pub global activate flutterfire_cli

# Run the `configure` command, select a Firebase project and platforms
flutterfire configure
```
This will generate `lib/firebase_options.dart`.

### Install cocoapods
The `flutterfire configure` will barf unless you install xcodeproj beforehand:
```bash
gem install xcodeproj cocoapods
```

### Install your own Ruby
Don't use system Ruby, that's a no-no.
1. `brew install ruby`
2. Update the path env var to have `/usr/local/opt/ruby/bin`
3. Update the path env var to have `(gem environment gemdir)/bin`

### Sources
1. https://mac.install.guide/faq/do-not-use-mac-system-ruby/index.html
2. https://mac.install.guide/ruby/13.html

## Sources
1. https://codelabs.developers.google.com/codelabs/flutter-codelab-first?continue=https%3A%2F%2Fdevelopers.google.com%2Flearn%2Fpathways%2Fintro-to-flutter%23codelab-https%3A%2F%2Fcodelabs.developers.google.com%2Fcodelabs%2Fflutter-codelab-first#2
2. https://firebase.flutter.dev/docs/overview/#initialization

# Run

## ios
```
open -a Simulator
flutter run
```

# Dev

## On write in vim, hot reload flutter
In vim,
`:FlutterRun -d chrome`

## Code organization
https://medium.com/flutter-community/flutter-code-organization-revised-b09ad5cef7f6
