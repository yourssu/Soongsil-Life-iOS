# Local LmsApi binary

This package contains the iOS client binary built from LMS-API `1.6.6.3`,
upstream revision `64ecd286ff1cc022e25cd96e96ace99b400cd7d7`.

The binary is kept local because the upstream release crashes in Kotlin/Native
while scanning large single-line Web Dynpro HTML. The local client-only patch:

- replaces recursive control-search regular expressions with a linear scanner;
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
`51bf41d867c3a511c5f0fd4497c167eb4e3ddaef7be8eb548d64d1b56dbcf6de`.

## Rebuilding

Checkout upstream tag `1.6.6.3`, apply
[`patches/1.6.6.3-client-stability.patch`](patches/1.6.6.3-client-stability.patch),
run the upstream JVM tests, and build `:library:assembleLmsApiReleaseXCFramework`.
The generated `library/build/XCFrameworks/release/LmsApi.xcframework` is the
artifact wrapped by this local Swift package.
