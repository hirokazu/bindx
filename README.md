# bindx

`bindx` is a CLI utility for macOS that allows you to check and list file extension associations using the Launch Services API.

## Features

- **Check Extension**: Find out which application is set as the default handler for a specific file extension.
- **List All Associations**: Export all registered file extension associations as JSON.
- **Filter by Application**: List all extensions associated with a specific application.

## Usage

### Check a specific extension

```bash
swift run bindx <extension>
```

Example:
```bash
swift run bindx txt
# Output:
# Bundle ID: com.apple.TextEdit
# Application: /System/Applications/TextEdit.app
```

### List all associations (JSON)

```bash
swift run bindx --json
```

### Filter by Application

List extensions associated with a specific application (case-insensitive):

```bash
swift run bindx --app "TextEdit"
# Output:
# rtf
# text
# txt
```

Get the output in JSON format:

```bash
swift run bindx --app "TextEdit" --json
```

## Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd bindx
   ```

2. Build using Swift Package Manager:
   ```bash
   swift build -c release
   ```

3. (Optional) Install to your path:
   ```bash
   cp .build/release/bindx /usr/local/bin/
   ```

## Requirements

- macOS 11.0 or later
- Swift 5.5 or later
