# Planios

Planios is a native iOS productivity app built with SwiftUI. It is designed around realistic planning, focused execution, and visible daily progress through tasks, reminders, focus sessions, and lightweight statistics.

## Overview

Planios helps users:

- plan tasks for today, tomorrow, and the week ahead
- assign time blocks, priorities, and repeat rules
- stay on track with local reminder notifications
- run dedicated focus sessions with a countdown timer
- measure consistency with completion metrics and streaks

The project is currently structured as a lightweight MVP with local-first storage and a clean SwiftUI architecture.

## Features

- `Dashboard`: quick view of progress, priorities, and daily momentum
- `Tasks`: create, edit, filter, complete, and manage scheduled tasks
- `Focus Mode`: distraction-resistant countdown session tied to a task
- `Statistics`: weekly completion data, today rate, and streak tracking
- `Settings`: notification permission handling and demo data reset

## Tech Stack

- `Swift`
- `SwiftUI`
- `UserDefaults` for local persistence
- `UserNotifications` for reminder scheduling
- `XcodeGen` via [`project.yml`](./project.yml) for project generation

## Project Structure

```text
Planios/
|- App/           # App entry point, root navigation, tab structure
|- Components/    # Reusable UI components
|- Managers/      # Notifications and storage logic
|- Models/        # Domain models and enums
|- Resources/     # Assets and app resources
|- Theme/         # Colors and visual styling
|- ViewModels/    # Screen state and presentation logic
|- Views/         # Feature screens
`- Docs/          # Product and release preparation notes
```

## Getting Started

### Requirements

- macOS
- Xcode 15 or later
- Homebrew
- XcodeGen

### Run Locally

1. Install XcodeGen:

```bash
brew install xcodegen
```

2. Generate the Xcode project from the repository root:

```bash
xcodegen generate
```

3. Open the generated project in Xcode:

```bash
open Planios.xcodeproj
```

4. Select an iOS Simulator or physical device and run the app.

## Architecture Notes

- The app entry point lives in [`Planios/App/PlaniosApp.swift`](./Planios/App/PlaniosApp.swift).
- Task data is stored locally through [`Planios/Managers/StorageManager.swift`](./Planios/Managers/StorageManager.swift).
- Notification scheduling is managed in [`Planios/Managers/NotificationManager.swift`](./Planios/Managers/NotificationManager.swift).
- Project generation is configured in [`project.yml`](./project.yml).

## Current MVP Scope

- local-only task storage
- local notifications before and after tasks
- onboarding and tab-based app flow
- seeded demo data for first launch
- completion analytics for the current week

## Roadmap Ideas

- iCloud sync or backend sync
- calendar integration
- widgets and Live Activities
- richer task recurrence options
- App Store release assets and localization

## Repository Notes

- This repository contains source files and XcodeGen configuration.
- Generated Xcode user data and build artifacts are intentionally excluded through [`.gitignore`](./.gitignore).

## License

No license has been added yet. If this repository will be published publicly, add a license before distribution.
