# Local LmsApi binary

This package contains the iOS client binary built from upstream revision
`014b325fea9bcd234a21edaf0f8e41b0debadcba`.

The binary is kept local because the upstream release crashes in Kotlin/Native
while scanning large single-line Web Dynpro HTML. The local client-only patch:

- replaces recursive control-search regular expressions with a linear scanner;
- returns the base graduation-audit table when the optional detail action is
  unavailable or its response cannot be parsed;
- accepts graduation-audit rows both with and without the optional used-subject
  column while preserving the server's `충족` / `부족` result contract.

It does not contain or replace an LMS server, credentials, signing settings, or
provisioning assets. The official LMS-API repository is not modified by this
app package.
