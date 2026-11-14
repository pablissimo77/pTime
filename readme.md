# pTime

`pTime` is a portable desktop time-tracking application for recording time spent on projects. It is written in Object Pascal with Lazarus and Free Pascal.

## Features

- Create and manage a project list.
- Mark projects as active or inactive and optionally show only active projects.
- Start a timer for the selected project.
- Switch between projects or use `PAUSE`.
- Display the current project and elapsed time in a floating panel.
- View daily and monthly statistics with project filtering.
- Optionally limit statistics to active projects.
- See the reporting period, project, and duration directly in the report.
- Monthly reports are broken down by day and project.
- Sort statistics by project name or duration.
- Copy statistics as tab-separated text to the clipboard for pasting into Excel or another spreadsheet application.
- Delete a project together with its time history after confirmation.
- Configure the panel font, colors, size, and position.

The application does not require an installer, the Windows registry, or a separate database server. All required files are kept next to the executable.

Only one copy of pTime can run at a time. A second launch shows a message and
exits before opening the SQLite database. This prevents concurrent writes and
avoids database access errors.

On Linux, a temporary `ptime.lock` file is created beside the executable while
the program is running. It is only a lock handle and does not contain user data;
the lock is released automatically when the process exits.

## Technology

- Language: **Object Pascal**
- IDE and application framework: **Lazarus LCL**
- Compiler: **Free Pascal Compiler (FPC)**
- GUI: **Lazarus Component Library**
- Database: **SQLite** through `SQLite3Conn` and `SQLDB`
- Forms: Lazarus `.lfm` files
- Supported architecture: **64-bit only**

Project dependencies are listed in `ptime.lpi`: `FCL`, `LCL`, `SQLDBLaz`, and `DateTimeCtrls`.

## Supported platforms

### Linux x86_64

The application directory must contain:

```text
ptime
libsqlite3.so
```

The Linux build has been verified with Lazarus/FPC.

### Windows x64

The application directory must contain:

```text
ptime.exe
sqlite3.dll
```

The application requires the 64-bit SQLite DLL. 32-bit Windows is not supported.

The official SQLite download page is available at [sqlite.org/download.html](https://www.sqlite.org/download.html). For Windows, use the `sqlite-dll-win-x64-*.zip` package from **Precompiled Binaries for Windows**. The `sqlite-dll-win-x86` and `sqlite-tools-win-x64` packages are not required by pTime.

## Portable distribution

Example Windows x64 distribution:

```text
pTime/
├── ptime.exe
├── sqlite3.dll
└── ptime.sqlite3       (created automatically when needed)
```

Example Linux x86_64 distribution:

```text
pTime/
├── ptime
├── libsqlite3.so
└── ptime.sqlite3       (created automatically when needed)
```

SQLite is loaded from the application directory. It does not need to be copied to `System32`, added to the system `PATH`, or installed separately.

For the Windows ZIP and Linux `tar.gz` packages, the database is stored next to the executable, so that directory must be writable. The AppImage launcher keeps its writable copy and database under `${XDG_DATA_HOME:-~/.local/share}/pTime`, because an AppImage itself is mounted read-only.

## Automated releases

GitHub Actions builds the release packages automatically when a version tag is pushed. To create a release, use a tag such as:

```bash
git tag v1.0.0
git push origin v1.0.0
```

The workflow in `.github/workflows/release.yml` creates:

- `pTime-1.0.0-windows-x64.zip`;
- `pTime-1.0.0-linux-x86_64.AppImage`;
- `pTime-1.0.0-linux-x86_64.AppImage.zsync`;
- `pTime-1.0.0-linux-x86_64.tar.gz`;
- `SHA256SUMS.txt`.

The release is then published automatically on GitHub. The workflow generates
`version.inc` from the version in `ptime.lpi` before compiling, so the version
shown in the About window and the version embedded in the binary are identical.

The AppImage contains GitHub Releases update information and can be checked
for updates by compatible AppImage managers. The corresponding `.zsync` file
is published next to the AppImage. The AppImage also includes AppStream
metadata and is categorized as an Office application.

The release description is controlled by a separate Markdown file in
`release-notes/`. For example, the text for tag `v1.0.0` is stored in
`release-notes/v1.0.0.md`.

The release version is configured in the Lazarus project settings in
`ptime.lpi`: `MajorVersionNr`, `MinorVersionNr`, and `RevisionNr`. The `BuildNr`
field is kept at `0` and is not used. The version is therefore `MAJOR.MINOR.PATCH`
(for example, `1.2.3`).

Before compiling locally from the Lazarus IDE, configure one compiler command
in **Project Options → Compiler Options → Compilation and Linking → Compiler
Commands → Execute before**:

- Linux: `bash scripts/generate-version.sh ptime.lpi`
- Windows: `powershell -ExecutionPolicy Bypass -File scripts\generate-version.ps1 -ProjectFile ptime.lpi`

Enable this command for both **Compile** and **Build**. It regenerates
`version.inc` from the current Lazarus project settings, so the About window
and the compiled binary use the same version. The release workflow performs
the same step automatically and verifies that the Git tag matches the project
version. For example, project version `1.2.3` must be released with tag
`v1.2.3`.

## Project modules

`ptime.lpr` is the application entry point and creates the forms.

`unit_info.pas` implements the main information panel. It displays the current project and elapsed time, updates once per second, handles project switching, and sends timing records to the database module.

`unit_options.pas` implements the options window. It manages projects, panel appearance and position, statistics reports, project filtering, sorting, and clipboard copy.

`unit_database.pas` owns the SQLite connection, transactions, schema creation,
project operations, settings, timing records, and statistics queries.

`unit_about.pas` implements the About dialog and provides the author's contact email address.

## Data storage

The main database file is `ptime.sqlite3`.

The `timing` table stores the project name, date, start time, end time, and duration in seconds. The database also contains:

- `projects` — the project list, display order, and active/inactive state;
- `settings` — the panel font, colors, size, and position.

Project data, time records, and application settings are stored in SQLite. The application does not use or create the legacy `projects`, `option`, or date-based text log files.

Monthly statistics filter by both year and month, so the same month in different years is not mixed together.

## License

pTime source code is distributed under the [MIT License](./LICENSE).

The bundled SQLite libraries are third-party components. SQLite is in the public domain; see the [SQLite copyright page](https://www.sqlite.org/copyright.html) for details.

The [EULA](./EULA.md) contains additional terms for distributing compiled copies of pTime.

## Additional notes

- The panel stays above other windows (`fsSystemStayOnTop`).
- System tray support was considered, but the corresponding code is currently commented out.
- The database and settings are stored in the portable distribution directory.
- Windows uses `sqlite3.dll`; Linux uses `libsqlite3.so`.
- 32-bit builds are not planned.
