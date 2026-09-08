# Local LmsApi binary

This package contains the iOS client binary built from LMS-API `1.6.6.3`,
upstream revision `64ecd286ff1cc022e25cd96e96ace99b400cd7d7`.

The binary is kept local because the upstream release crashes in Kotlin/Native
while scanning large single-line Web Dynpro HTML. The local client-only patch:

- replaces recursive timetable control, header, row/cell, and nested-table
  regular expressions with a non-recursive linear scanner;
- preserves nested Web Dynpro layout/result tables and split timetable
  header/body tables while scanning grade, timetable, and chapel pages;
- ignores fake markup inside script/style blocks and preserves literal `<`
  text without losing later cells or line breaks;
- uses the same scanner for grade and chapel control/row parsing and common
  year/semester parsing, preventing the same Kotlin/Native stack overflow on
  large single-line Web Dynpro responses;
- returns the separately labeled academic-record GPA, certificate GPA, and
  certificate earned credits instead of forcing clients to infer cumulative
  values from per-semester rows;
- returns the base graduation-audit table when the optional detail action is
  unavailable or its response cannot be parsed;
- accepts graduation-audit rows both with and without the optional used-subject
  column while preserving the server's `충족` / `부족` result contract;
- forces SAP Web Dynpro initial and event requests to use `sap-language=KO`
  and an explicit Korean `Accept-Language`, so parsing does not depend on the
  review device's language setting.

It does not contain or replace an LMS server, credentials, signing settings, or
provisioning assets. The official LMS-API repository is not modified by this
app package.

The bundled framework binary SHA-256 is
`8ab86b81e9cea0069b5529d873dd7962824351f827a425ef96870e4f7648c085`.

## Rebuilding

Checkout upstream tag `1.6.6.3`, apply
[`patches/1.6.6.3-client-stability.patch`](patches/1.6.6.3-client-stability.patch)
and then [`patches/1.6.6.3-certificate-gpa.patch`](patches/1.6.6.3-certificate-gpa.patch),
run the upstream JVM tests, and build `:library:assembleLmsApiReleaseXCFramework`.
The generated `library/build/XCFrameworks/release/LmsApi.xcframework` is the
artifact wrapped by this local Swift package.
