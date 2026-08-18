# Developing Pantry

Thanks for your interest in improving Pantry! This guide covers setting up a local development
environment, the day-to-day workflow, project conventions, and how to get your changes merged.

For anything specific to the FLOSS/F-Droid build variant, see
[`fdroid/README.md`](fdroid/README.md).

## Contents

- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Running the app](#running-the-app)
- [Common tasks](#common-tasks)
- [Project layout](#project-layout)
- [API / OpenAPI](#api--openapi)
- [Internationalization (i18n)](#internationalization-i18n)
- [Testing](#testing)
- [Submitting changes](#submitting-changes)

## Prerequisites

- **[Flutter](https://docs.flutter.dev/get-started/install)** on the **stable** channel. The exact
  version is pinned in [`.flutter-version`](.flutter-version); using that version avoids
  formatter/analyzer drift. The Dart SDK constraint is `^3.11.1`.
- **[Node.js](https://nodejs.org/)** with **[pnpm](https://pnpm.io/)** — used by the dev tooling
  (Prettier formats the YAML/Markdown, and i18n/hooks rely on it).
- An IDE such as **Android Studio** and/or **Xcode** for building and running on Android / iOS /
  macOS.
- A **Nextcloud instance** running the
  [Pantry server app](https://github.com/chenasraf/nextcloud-pantry) to log in and test against.

> Most tasks are wrapped in `make` targets. Prefer `make <target>` over the raw commands — run
> `make help` to see everything available.

## Setup

```bash
git clone https://github.com/chenasraf/pantry-flutter.git
cd pantry-flutter

make get            # flutter pub get + pnpm install
make install-hooks  # install the lefthook git hooks (format + analyze on commit)
make i18n           # generate the i18n Dart code
```

The pre-commit hook (via [lefthook](https://github.com/evilmartians/lefthook)) formats and analyzes
staged Dart files and formats staged YAML, so CI rarely fails on formatting. Install it once with
`make install-hooks`.

## Running the app

```bash
make run            # flutter run in debug mode
```

On first launch you'll be asked for your Nextcloud server URL and taken through Login Flow v2 in the
browser. Point it at a server that has the Pantry server app installed.

## Common tasks

```bash
make analyze        # analyze the project
make format         # format all Dart + YAML/Markdown files
make check          # format + analyze without writing changes (what CI runs)
make test           # run the test suite
make i18n           # regenerate i18n Dart from the YAML sources
make i18n-watch     # regenerate i18n on change
make fetch-openapi  # sync the OpenAPI spec from the server repo
```

See `make help` for the complete list, including the per-platform build, release, and deploy
targets.

## Project layout

```
lib/
├─ main.dart      # App entry + theming
├─ models/        # Data models (Photo, Note, Checklist, …)
├─ services/      # API clients, cache, auth, locale
├─ sync/          # Offline sync + local persistence
├─ utils/         # Pure utilities (rrule, icons, text direction)
├─ widgets/       # Reusable widgets (recurrence dialog, category picker, …)
├─ i18n/          # Translation sources (messages*.i18n.yaml) + generated Dart
└─ views/         # Feature screens
   ├─ checklists/  photos/  notes/  shopping/  stores/  categories/
   ├─ home/  login/  onboarding/  settings/  about/  share/
   └─ notifications/  notifications_intro/
```

The `fdroid/` directory holds the FLOSS scanner variant that gets swapped in for F-Droid builds —
see [`fdroid/README.md`](fdroid/README.md).

## API / OpenAPI

The app consumes the Nextcloud Pantry OCS API. The OpenAPI spec is kept in sync from the
[server repo](https://github.com/chenasraf/nextcloud-pantry):

```bash
make fetch-openapi                  # latest
make fetch-openapi REF=<branch/sha> # a specific ref
```

## Internationalization (i18n)

Translations live in `lib/i18n/`, one YAML file per language:

- `messages.i18n.yaml` — the base file (English), the source of truth for all keys.
- `messages_<langCode>.i18n.yaml` — one per language (e.g. `messages_de.i18n.yaml`,
  `messages_fr.i18n.yaml`, `messages_he.i18n.yaml`).

After editing any translation file, run `make i18n` to regenerate the accompanying Dart code.

**To improve an existing translation**, edit the values in that language's file. Keep the **keys
identical** to the base file — translate only the values.

**To add a new language:**

1. Copy `lib/i18n/messages.i18n.yaml` to `lib/i18n/messages_<langCode>.i18n.yaml` and translate the
   values.
2. Add the locale to `supportedLocales` and its native name to `languageNativeNames` (the endonym
   shown in the language picker) in `lib/services/locale_service.dart`.
3. Run `make i18n` to regenerate the Dart code.

**Reuse translations from the Nextcloud app.** Many strings already exist in the
[Pantry Nextcloud app](https://github.com/chenasraf/nextcloud-pantry). You can auto-populate a
language file from the Nextcloud app's translations instead of translating those strings by hand:

```bash
make i18n-from-nextcloud \
  NC_JSON=~/Dev/nextcloud-pantry/l10n/nn_NO.json \
  TARGET=lib/i18n/messages_nn.i18n.yaml
```

`NC_JSON` is the path to the language's JSON file in the Nextcloud app's `l10n/` directory, and
`TARGET` is the Flutter language file to fill in. It only replaces values that still match the
English base (case-insensitively), so already-translated strings are left untouched. Run `make i18n`
afterwards.

A few rules to keep translations working:

- **Don't rename keys** — they must match the base file exactly. Any key you don't translate falls
  back to English.
- **Preserve placeholders and parameters.** If a string is defined as
  `stepLabel(int current, int total): "Step ${current} of ${total}"`, keep the `(...)` signature and
  the `${current}` / `${total}` placeholders intact — only translate the surrounding words.
- **RTL languages** (like Hebrew) are supported automatically; the app mirrors its layout based on
  the active locale.

Contributions of new or improved translations are very welcome — open a pull request.

## Testing

```bash
make test                       # run everything
make test FILES=test/foo_test.dart   # run a subset
make test-coverage              # run with a coverage report
```

Please add or update tests when you change behavior, and make sure `make check` and `make test` pass
before opening a pull request.

## Submitting changes

1. Fork the repo and create a branch off `master`.
2. Make your change, keeping commits focused and following the conventions above.
3. Run `make check` and `make test` locally (the git hooks help with formatting).
4. Open a pull request describing what changed and why. Link any related issue.

If you find a bug or want a new feature, please
[open an issue](https://github.com/chenasraf/pantry-flutter/issues) first so we can discuss the
approach — it saves everyone time. Bugs in the core Nextcloud app belong in the
[server repo](https://github.com/chenasraf/nextcloud-pantry) instead.

Thanks for contributing! ❤️
