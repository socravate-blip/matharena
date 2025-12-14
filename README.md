# MathArena Project

MathArena is a Flutter application designed to provide an engaging platform for math-related games and activities. This project follows Clean Architecture principles to ensure a scalable and maintainable codebase.

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