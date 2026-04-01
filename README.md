# Planios

Planios is a productivity app focused on realistic planning, protected focus time, and visible progress. This repository contains:

- `Planios/`: the original native iOS SwiftUI app
- `planios_expo/`: the new Expo / React Native app for Android emulator and physical Android devices

## Repository Layout

```text
Planios/
|- Planios/        # Native iOS SwiftUI source
|- planios_expo/   # Expo / React Native app
|- project.yml     # XcodeGen config for the iOS app
|- README.md
`- .gitignore
```

## Expo Version

The Expo app includes:

- dashboard with progress and weekly average
- task creation, editing, completion, and deletion
- filters for today, tomorrow, and this week
- focus mode with countdown timer and guarded exit
- weekly statistics and streak tracking
- local persistence with AsyncStorage
- onboarding overlay for first launch

### Stack

- `Expo`
- `React Native`
- `AsyncStorage`
- `JavaScript`

### Run On Android Emulator

1. Install Android Studio and create an Android emulator.
2. Install Node.js if needed.
3. Open terminal in `planios_expo/`.
4. Install dependencies:

```bash
npm install
```

5. Start Expo:

```bash
npx expo start --android
```

If PowerShell blocks `npm`, use:

```bash
npm.cmd install
npx.cmd expo start --android
```

## Native iOS Version

The original iOS app remains available in `Planios/` for Xcode-based development on macOS.

## Push To GitHub

```bash
git add .
git commit -m "Replace Flutter app with Expo React Native version"
git push origin main
```

## License

No license has been added yet. Add one before public distribution.