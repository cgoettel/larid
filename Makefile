.PHONY: help test run run-ios run-android build clean deps lint format check devices sim-ios

# Default target - show available commands
help:
	@echo "LarID - Available Commands"
	@echo ""
	@echo "Development:"
	@echo "  make run-ios       - Launch iOS simulator and run app"
	@echo "  make run-android   - Launch Android emulator and run app"
	@echo "  make run           - Run app on Chrome (web)"
	@echo "  make sim-ios       - Just launch iOS simulator"
	@echo "  make devices       - Show connected devices"
	@echo ""
	@echo "Quality:"
	@echo "  make test          - Run all tests"
	@echo "  make lint          - Run linter"
	@echo "  make format        - Format all Dart code"
	@echo "  make check         - Run linter + tests (pre-commit)"
	@echo ""
	@echo "Build:"
	@echo "  make build         - Build release APK (Android)"
	@echo "  make build-web     - Build for web"
	@echo ""
	@echo "Maintenance:"
	@echo "  make deps          - Install/update dependencies"
	@echo "  make clean         - Clean build artifacts"
	@echo ""

# Run all tests
test:
	flutter test

# Run app in debug mode (defaults to Chrome for web)
run:
	flutter run -d chrome

# Build release APK for Android
build:
	flutter build apk --release

# Build for web
build-web:
	flutter build web

# Clean build artifacts
clean:
	flutter clean
	rm -rf build/

# Install/update dependencies
deps:
	flutter pub get

# Run linter
lint:
	flutter analyze

# Format all Dart code
format:
	dart format lib/ test/

# Pre-commit check: lint + tests
check: lint test
	@echo "✅ All checks passed!"

# Just launch iOS simulator without running app
sim-ios:
	@if xcrun simctl list devices | grep -q "(Booted)"; then \
		echo "✅ Simulator already running"; \
	else \
		echo "🚀 Launching iOS Simulator..."; \
		open -a Simulator; \
		echo "⏳ Waiting for simulator to boot..."; \
		while ! xcrun simctl list devices | grep -q "(Booted)"; do \
			sleep 1; \
		done; \
		echo "✅ Simulator ready!"; \
	fi

# Run app on iOS simulator (macOS only)
# Launches simulator if not running, waits for boot, then runs app
run-ios:
	@if xcrun simctl list devices | grep -q "(Booted)"; then \
		echo "✅ Simulator already running"; \
	else \
		echo "🚀 Launching iOS Simulator..."; \
		open -a Simulator 2>/dev/null || true; \
		echo "⏳ Waiting for simulator to boot..."; \
		while ! xcrun simctl list devices | grep -q "(Booted)"; do \
			sleep 1; \
		done; \
		echo "✅ Simulator ready!"; \
	fi
	@echo "📱 Finding iOS device..."
	@DEVICE_ID=$$(flutter devices --machine | jq -r '.[] | select(.targetPlatform == "ios") | .id' | head -1); \
	if [ -z "$$DEVICE_ID" ]; then \
		echo "❌ No iOS simulator found. Try running 'make sim-ios' first."; \
		exit 1; \
	fi; \
	echo "✅ Found device: $$DEVICE_ID"; \
	echo "🏃 Running app..."; \
	flutter run -d "$$DEVICE_ID"

# Run app on Android emulator
run-android:
	flutter run -d emulator

# Show connected devices
devices:
	@flutter devices

# Upgrade Flutter SDK
upgrade-flutter:
	flutter upgrade
