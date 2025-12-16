# MathArena Project

MathArena is a Flutter application designed to provide an engaging platform for competitive math games. This project follows Clean Architecture principles to ensure a scalable and maintainable codebase.

## 🎮 Features

- **Solo Training Mode**: Practice mental math with customizable difficulty
- **Ranked Mode**: Compete for ELO rating
- **Multiplayer (Online/Offline)**: Play against AI bots or real players
- **ELO Rating System**: Track your progress
- **Multiple Game Modes**:
  - Basic arithmetic puzzles
  - Complex calculations
  - Game24 challenges
  - Matador (use all numbers)

## 🚀 Quick Start

### Prerequisites
- Flutter SDK installed
- Chrome browser (for web development)

### Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd MathArena
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the application**:
   ```bash
   flutter run -d chrome --web-port 8080
   ```

## 🎯 Multiplayer Setup (5 minutes)

The multiplayer mode works in **offline mode by default** (against AI bots). To enable online multiplayer:

📖 **Follow the guide**: [QUICK_SETUP_MULTIPLAYER.md](QUICK_SETUP_MULTIPLAYER.md)

Quick steps:
1. Enable Anonymous Authentication in Firebase Console
2. Configure Security Rules
3. Done! Multiplayer works automatically

**Troubleshooting**: See [MULTIPLAYER_DEBUG.md](MULTIPLAYER_DEBUG.md)

## Project Structure

The project is organized into several directories, each serving a specific purpose:

- **lib/**: Contains the main application code.
  - **config/**: Configuration files for routing and theming.
    - **router/**: Contains routing configuration using GoRouter.
    - **theme/**: Defines the application's dark theme.
  - **core/**: Core functionalities and utilities.
    - **constants/**: Holds constant values used throughout the application.
    - **utils/**: Utility functions for logging and other common tasks.
  - **features/**: Contains the main features of the application.
    - **auth/**: Authentication feature, including data, domain, and presentation layers.
    - **game/**: Game feature, including data, domain, and presentation layers.
    - **leaderboard/**: Leaderboard feature, including data, domain, and presentation layers.
  - **shared/**: Shared components across features.
    - **providers/**: Shared providers for state management.
    - **widgets/**: Common UI widgets for reuse.

## Setup Instructions

1. **Clone the repository**:
   ```
   git clone <repository-url>
   ```

2. **Navigate to the project directory**:
   ```
   cd MathArena
   ```

3. **Install dependencies**:
   ```
   flutter pub get
   ```

4. **Run the application**:
   ```
   flutter run
   ```

## Features

- **Authentication**: Secure user login and registration.
- **Game Mechanics**: Interactive math games to enhance learning.
- **Leaderboard**: Track and display user scores and achievements.

## Usage Guidelines

- Follow the Clean Architecture principles to add new features or modify existing ones.
- Use the shared components in the `lib/shared/` directory to maintain consistency across the application.
- Ensure to document any new features or changes made to the project.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any enhancements or bug fixes.