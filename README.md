# Workout Planner

A Flutter web app for managing workout programs. (The user-facing UI is in Turkish.)

## Features

- **Create/edit daily programs:** Exercise name, sets, reps, weight, rest and note.
  Add/remove rows and reorder them via drag-and-drop.
- **Keep old programs / recreate:** Every program is stored with its history.
  "Duplicate" copies an old program so you can quickly build a new one. Archiving supported.
- **Weekly plan:** Assign 2-4 daily programs to days of the week.
- **PDF / Excel export:** For both a single program and a weekly plan.
- **Import:** Extract a program from pasted text, CSV, Excel (.xlsx/.xls) and PDF files;
  save after an editable preview.
- **Local storage:** Data is kept in the browser (IndexedDB / Hive); no backend required.

## Tech

- Flutter (web) · Riverpod (state) · Hive CE (storage)
- `pdf` + `printing` (PDF) · `excel` + `file_saver` (Excel)
- `file_picker` · `csv` · `syncfusion_flutter_pdf` (PDF text extraction)

## Development

```bash
flutter pub get
flutter run -d chrome
```

## Production build

```bash
flutter build web --release
# Output: build/web
```

## Deploying to Vercel

The repo includes `vercel.json`. During the build, Vercel clones Flutter stable,
runs `flutter build web`, and serves the `build/web` directory.

- **With GitHub (recommended):** Push the repo to GitHub (`main` branch) and import
  the project in Vercel. Every push to `main` triggers an automatic deployment.
- **With the CLI:** `vercel` (preview) / `vercel --prod` (production).
