# Pantry

A Flutter mobile client for [Nextcloud Pantry](https://github.com/chenasraf/nextcloud-pantry) —
household management for your self-hosted Nextcloud.

## Features

- **Checklists**: Shared checklists with categories, quantities, images, and recurring items.
- **Photo Board**: Upload and organize shared photos in folders with captions.
- **Notes Wall**: Color-coded shared notes for household reminders.
- **Drag-and-drop reordering** everywhere.
- **Multi-select** for bulk actions.
- **Offline caching** for fast loading.
- **Material Design 3** with dark mode.
- **Self-hosted** — connects directly to your own Nextcloud server via Login Flow v2.

## Requirements

A Nextcloud server with the [Pantry server app](https://github.com/chenasraf/nextcloud-pantry)
installed.

## Installation

### Google Play

[Install from Google Play](https://play.google.com/store/apps/details?id=dev.casraf.pantry)

### Beta testing

Want early access to new features? Join the beta program:

1. Visit the [beta opt-in page](https://play.google.com/apps/testing/dev.casraf.pantry) on your
   Android device.
2. Tap **Become a tester**.
3. Install or update Pantry from the
   [Play Store listing](https://play.google.com/store/apps/details?id=dev.casraf.pantry) — you'll
   automatically receive beta builds.

It may take a few minutes for your tester status to propagate.

### Manual (APK)

Download the latest APK from the
[releases page](https://github.com/chenasraf/pantry-flutter/releases) and sideload onto your device.

### App Store (iOS)

[Install from the App Store](https://apps.apple.com/us/app/pantry-for-nextcloud/id6762161619)

## Development

### Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) (stable channel)
- Android Studio / Xcode for platform builds
- A Nextcloud instance with the Pantry server app for testing

### Quick Start

```bash
make get            # install dependencies
make i18n           # generate i18n code
make run            # run in debug mode
```

### Common Tasks

```bash
make analyze        # analyze staged files
make format         # format staged files
make check          # analyze + format check
make test           # run tests
```

See `make help` for the full list.

### Project Layout

```
lib/
├─ main.dart               # App entry + theming
├─ models/                 # Data models (Photo, Note, Checklist, etc.)
├─ services/               # API clients, cache, auth
├─ utils/                  # Pure utilities (rrule, icons)
├─ widgets/                # Reusable widgets (recurrence dialog, category picker)
└─ views/
   ├─ checklists/
   ├─ photos/
   ├─ notes/
   ├─ home/
   └─ login/
```

### API

The app consumes the Nextcloud Pantry OCS API. The OpenAPI spec is kept in sync via:

```bash
make fetch-openapi
```

## Privacy

Pantry is a self-hosted client. Your data never leaves your Nextcloud server. See the
[privacy policy](https://casraf.dev/pantry-privacy-policy) for details.

## Contributing

I am developing this app on my free time, so any support, whether code, issues, or just stars is
very helpful to sustaining its life. If you are feeling incredibly generous and would like to donate
just a small amount to help sustain this project, I would be very very thankful!

<a href='https://ko-fi.com/casraf' target='_blank'>
  <img height='36' style='border:0px;height:36px;'
    src='https://cdn.ko-fi.com/cdn/kofi1.png?v=3'
    alt='Buy Me a Coffee at ko-fi.com' />
</a>

I welcome any issues or pull requests on GitHub. If you find a bug, or would like a new feature,
don't hesitate to open an appropriate issue and I will do my best to reply promptly.

## License

This app is licensed under the [MIT](LICENSE) license.
