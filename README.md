# ScoreFlow - PDF Viewer for Sheet Music

A macOS PDF viewer application built with Flutter, focused on displaying sheet music with simple and efficient navigation.

## Features

- **PDF File Opening**: Open PDF files using native macOS file picker
- **Recent Files**: Automatically track and display recently opened files
- **Multi-Page View**: View previous, current, and next pages simultaneously for better context
- **Keyboard Navigation**: Navigate through pages using arrow keys and Page Up/Down
- **Page Navigation**: Navigate through PDF pages with previous/next buttons or jump to a specific page
- **Clean UI**: Simple, distraction-free interface optimized for viewing sheet music
- **State Management**: Built with Flutter Bloc for predictable state management

## Architecture

The application follows a clean architecture pattern with feature-based organization:

```
lib/
├── main.dart                          # App entry point
└── features/
    └── pdf_viewer/
        ├── bloc/                      # State management
        │   ├── pdf_viewer_bloc.dart
        │   ├── pdf_viewer_event.dart
        │   └── pdf_viewer_state.dart
        ├── models/                    # Data models
        │   └── recent_file.dart
        ├── repositories/              # Data persistence
        │   └── recent_files_repository.dart
        └── ui/                        # User interface
            ├── home_screen.dart
            ├── pdf_viewer_screen.dart
            └── widgets/
                ├── multi_page_viewer.dart
                ├── pdf_page_widget.dart
                ├── pdf_display_widget.dart
                ├── page_navigation_controls.dart
                └── recent_files_list.dart
```

## Key Technologies

- **Flutter**: Cross-platform UI framework
- **flutter_bloc**: State management solution
- **pdfx**: Native PDF rendering with good performance
- **file_picker**: Native file selection dialogs
- **shared_preferences**: Local storage for recent files
- **equatable**: Value equality for better state management

## Running the Application

### Prerequisites

- Flutter SDK (3.10.1 or higher)
- macOS development environment
- Xcode (for macOS builds)

### Installation

1. Install dependencies:
```bash
flutter pub get
```

2. Run on macOS:
```bash
flutter run -d macos
```

### Building for Release

```bash
flutter build macos --release
```

The built app will be available at:
`build/macos/Build/Products/Release/scoreflow.app`

## Usage

### Opening a PDF

- Click the "Open PDF" button on the home screen
- Select a PDF file from your file system
- The file will open in the viewer

### Navigating Pages

**Keyboard Shortcuts:**
- **Arrow Keys**: Left/Up for previous page, Right/Down for next page
- **Page Up**: Go to previous page
- **Page Down**: Go to next page

**Mouse/Trackpad:**
- Use the Previous/Next buttons at the bottom
- Click on the page number field to jump to a specific page
- Swipe horizontally to scroll between pages

### Multi-Page View

The viewer displays pages optimally based on the document:
- **Single page PDFs**: Page is centered on screen
- **Multi-page PDFs**: Two pages displayed side by side (like a book)

When navigating:
- **Next/Previous buttons or arrow keys**: Advance by one spread (2 pages)
- **Swipe left/right**: Navigate between spreads
- **Page number input**: Jump to any specific page

This two-page spread layout is perfect for sheet music where you want to see both pages of a score simultaneously.

### Recent Files

- Recently opened files appear on the home screen
- Click any recent file to open it quickly
- Recent files persist across app restarts
- Up to 10 recent files are tracked

### Closing a PDF

- Click the back arrow in the top-left corner
- Returns to the home screen showing recent files

## File Permissions

The app requires file access permissions to open PDF files. These are configured in:
- `macos/Runner/DebugProfile.entitlements`
- `macos/Runner/Release.entitlements`

The app uses:
- `com.apple.security.files.user-selected.read-only` and `com.apple.security.files.user-selected.read-write` entitlements for file picker access
- **Security-scoped bookmarks** to persist file access permissions across app launches

### How File Access Works

1. **First Open**: When you open a PDF via the file picker, macOS grants permission and the app creates a security-scoped bookmark
2. **Recent Files**: The bookmark is stored with the file path, allowing persistent access
3. **Future Opens**: The app uses the bookmark to restore access permissions automatically

This ensures that files in cloud storage locations (like Google Drive) can be opened reliably from the recent files list.

## Testing

Run tests with:
```bash
flutter test
```

Run analysis:
```bash
flutter analyze
```

## New Features in Latest Update

### 1. Keyboard Navigation
All arrow keys and Page Up/Down now work for navigation:
- **Left Arrow / Up Arrow / Page Up**: Previous page
- **Right Arrow / Down Arrow / Page Down**: Next page

### 2. Multi-Page Horizontal View
- See three pages at once (previous, current, next)
- Current page is centered and highlighted with a shadow
- Adjacent pages are partially visible for context
- Smooth swiping between pages with gesture support
- Navigation controls stay synchronized with swipes

## Future Enhancements

Potential features for future versions:
- Zoom controls (zoom in/out, fit to width/height)
- Thumbnail sidebar for quick page navigation
- Annotations and markup tools
- Full-screen mode
- More keyboard shortcuts (Home, End, etc.)
- Search within PDF
- Print support
- Multiple document tabs
- Customizable page gap spacing
- Dark mode support

## License

This project is created as a demonstration application.
