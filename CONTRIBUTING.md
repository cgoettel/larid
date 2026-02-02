# Contributing to LarID

Thank you for your interest in contributing to LarID! This document provides guidelines for contributing to the project.

## Code of Conduct

Be respectful and constructive in all interactions. We're here to build a useful tool for the birding community.

## Getting Started

### Development Environment Setup

1. **Install Flutter SDK**
   ```bash
   # Follow instructions at https://docs.flutter.dev/get-started/install
   flutter doctor  # Verify installation
   ```

2. **Clone the repository**
   ```bash
   git clone git@gitlab.com:colby.goettel/gull-id.git
   cd gull-id
   ```

3. **Install dependencies**
   ```bash
   make deps
   # or: flutter pub get
   ```

4. **Run the app**

   We provide a Makefile for common tasks. See all available commands with:
   ```bash
   make help
   ```

   **Recommended workflow (iOS):**
   ```bash
   make run-ios
   ```
   This automatically:
   - Launches the iOS Simulator if not running
   - Waits for it to boot
   - Finds the device ID
   - Runs the app

   **Other platforms:**
   ```bash
   # Web (Chrome)
   make run

   # Android emulator
   make run-android

   # Manual device selection
   make devices              # List available devices
   flutter run -d <device-id>
   ```

5. **Run tests**
   ```bash
   make test
   # or: flutter test
   ```

### Development Workflow

**Hot Reload** - When the app is running, press `r` in the terminal to hot reload changes instantly (preserves app state).

**Hot Restart** - Press `R` to restart the app from scratch (clears state).

**Pro tip:** Run Flutter in a separate terminal so you can easily press `r` for hot reload while making changes in your editor.

### VS Code Setup

Recommended extensions:
- Flutter (includes Dart extension)
- GitLab Workflow (optional)

## Project Structure

```
gull-id/
├── lib/                    # Dart source code
│   ├── main.dart          # App entry point
│   ├── models/            # Data models
│   ├── services/          # Business logic (database, filtering)
│   ├── screens/           # UI screens
│   └── widgets/           # Reusable UI components
├── assets/
│   └── database/          # SQLite schema and data
├── test/                  # Unit and widget tests
├── android/               # Android-specific code
├── ios/                   # iOS-specific code
├── web/                   # Web-specific code
└── docs/                  # Documentation
```

## How to Contribute

### Reporting Bugs

Open an issue with:
- Clear description of the problem
- Steps to reproduce
- Expected vs actual behavior
- Platform (Android/iOS/web)
- Screenshots if applicable

### Suggesting Features

Open an issue with:
- Clear description of the feature
- Use case: why would this be valuable?
- Optional: proposed implementation approach

### Submitting Code

1. **Create a branch**
   ```bash
   git checkout -b feat/your-feature-name
   # or
   git checkout -b fix/bug-description
   ```

2. **Make your changes**
   - Write clear, focused commits
   - Add tests for new functionality
   - Update documentation if needed

3. **Test your changes**
   ```bash
   flutter test
   flutter analyze  # Check for issues
   ```

4. **Commit with conventional format**
   ```bash
   git commit -m "feat: add species comparison view"
   # or
   git commit -m "fix: correct leg color filtering logic"
   ```

5. **Push and create merge request**
   ```bash
   git push origin feat/your-feature-name
   ```
   Then create a merge request in GitLab.

## Commit Message Convention

Use conventional commit format:

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `refactor:` Code refactoring (no functional changes)
- `test:` Adding or updating tests
- `chore:` Maintenance tasks (dependencies, build config)
- `perf:` Performance improvements

Examples:
```
feat: add seasonal plumage filtering
fix: resolve database query crash on empty filters
docs: update API documentation for filtering service
test: add unit tests for characteristic validation
```

Include a list of changes and reasoning in the commit body:
```
feat: add seasonal plumage filtering

- Add season parameter to filtering logic
- Update UI to include season selector
- Add unit tests for seasonal queries

This allows users to narrow results by breeding vs non-breeding plumage,
which is especially useful during migration periods.
```

## Code Style

### Dart Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `flutter format .` to format code
- Run `flutter analyze` to catch issues

### Documentation

- Use `///` for doc comments (like Rust's `///`)
- Document public APIs and complex logic
- Keep comments focused on "why", not "what"

Example:
```dart
/// Filters gulls by selected characteristics.
///
/// Returns plumages that match ALL selected characteristic values.
/// Unselected characteristics are ignored (not filtered).
///
/// Returns empty list if no matches found.
List<Plumage> filterPlumages(Map<Characteristic, String> filters) {
  // Implementation
}
```

## Adding Species Data

### Data Requirements

All species data must include:
- Common name and scientific name
- At least one plumage variation (age/season)
- Observable characteristics for each plumage
- At least one openly licensed photo per plumage
- Regional occurrence data

### Photo Licensing

**Only use photos with open licenses:**
- Creative Commons BY or BY-SA
- Public Domain
- Explicitly permitted for educational use

**Always record:**
- Photographer name
- Exact license (e.g., "CC BY 4.0")
- Source (e.g., "Macaulay Library", "iNaturalist")

### Recommended Photo Sources

- [Macaulay Library](https://www.macaulaylibrary.org/) - Filter by CC licenses
- [iNaturalist](https://www.inaturalist.org/) - Check individual photo licenses
- [Wikimedia Commons](https://commons.wikimedia.org/) - Verify licenses

### Data Entry Process

1. **Research the species**
   - Use field guides, eBird, and expert resources
   - Document age/season plumage variations
   - Note observable characteristics for each plumage

2. **Create SQL file**
   ```sql
   -- File: assets/database/species/ring_billed_gull.sql

   INSERT INTO species (common_name, scientific_name, taxonomic_order)
   VALUES ('Ring-billed Gull', 'Larus delawarensis', 3);

   -- Continue with plumages, characteristics, photos...
   ```

3. **Validate data**
   - Every plumage has at least one photo
   - All characteristics are defined
   - Foreign keys are valid
   - Photo licenses verified

4. **Test locally**
   ```bash
   sqlite3 assets/database/gull_id.db < species/ring_billed_gull.sql
   # Run app and verify species appears correctly
   ```

5. **Submit merge request**
   - Include references to data sources
   - Document any uncertainties or decisions made

## Testing Guidelines

### Unit Tests

Write unit tests for:
- Database operations
- Filtering logic
- Data validation

```dart
test('filters plumages by leg color', () {
  final result = filterService.filter({'leg_color': 'pink'});
  expect(result.every((p) => p.legColor == 'pink'), isTrue);
});
```

### Widget Tests

Write widget tests for:
- UI components
- User interactions
- State changes

```dart
testWidgets('filter chip updates results', (tester) async {
  await tester.pumpWidget(MyApp());
  await tester.tap(find.text('Pink'));
  await tester.pump();
  expect(find.text('Western Gull'), findsOneWidget);
});
```

## Documentation

When adding features:
- Update relevant README sections
- Add inline documentation for complex logic
- Update design docs if architecture changes
- Add examples for new APIs

## Getting Help

- Check [existing issues](https://gitlab.com/colby.goettel/gull-id/-/issues)
- Read the [design document](docs/plans/2026-01-25-gull-id-design.md)
- Ask questions in issue comments

## License

By contributing, you agree that your contributions will be licensed under the GNU General Public License v3.0 (GPL-3.0). See the [LICENSE](LICENSE) file for details.

This ensures that LarID and all derivative works remain free and open source for the birding community.

## Recognition

Contributors will be recognized in the app's About section and in the repository.

Thank you for helping make gull identification easier for birders everywhere!
