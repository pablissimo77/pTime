# pTime End User License Agreement

Version 1.0 — 2026

This agreement applies to compiled copies of pTime (the "Software")
distributed by pablissimo77 (the "Author"). By using or redistributing the
Software, you accept these terms.

## 1. Use and redistribution

You may use pTime for personal, educational, or commercial purposes. You may
also copy and redistribute the original compiled Software, provided that you
keep the following files and notices with it:

- the copyright and license notices;
- this EULA;
- the [MIT License](./LICENSE);
- the required third-party SQLite library and its applicable notices.

No payment or additional permission is required for this use or redistribution.

## 2. Preservation of authorship

The original author of pTime is **pablissimo77**. You must not remove,
replace, or obscure the author's name, copyright notices, license notices, or
the attribution in the About dialog and project documentation.

If you publish a modified version, you must clearly identify the modifications
and must not present that version as the official pTime release or imply that
it is endorsed by the Author.

The MIT License permits modification and redistribution of the source code.
This EULA only defines the attribution and redistribution requirements for
compiled copies; it does not replace or restrict the MIT License.

## 3. Third-party components

pTime uses SQLite. The bundled SQLite libraries are third-party components and
remain subject to their own terms. SQLite is in the public domain. See the
[SQLite copyright page](https://www.sqlite.org/copyright.html) for details.

## 4. Local data

pTime stores projects, time records, and settings in the local `ptime.sqlite3`
file. In the Windows ZIP and Linux `tar.gz` packages, it is stored next to the
executable. In the AppImage package, the writable runtime copy and database
are stored under `${XDG_DATA_HOME:-~/.local/share}/pTime`. The application does
not send this data to the Author.

## 5. Disclaimer

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED. THE AUTHOR SHALL NOT BE LIABLE FOR LOSS OF DATA OR ANY DAMAGES
RESULTING FROM THE USE OF THE SOFTWARE, TO THE MAXIMUM EXTENT PERMITTED BY
APPLICABLE LAW.

## 6. Contact

For questions about pTime or attribution, contact pablissimo77@gmail.com.
