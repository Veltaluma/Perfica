# Security Policy

## Supported versions

Until Perfica establishes a broader stable-release support policy, security
maintenance is focused on the latest official upstream release and the current
development line preparing the next release.

Old releases may not receive separate security patches.

## Reporting a vulnerability

Do not publish exploit details, credentials, sensitive diagnostics, or a working
proof of concept in a normal public issue.

Prefer GitHub Private Vulnerability Reporting / Security Advisories when that
facility is enabled for the canonical repository:

```text
https://github.com/Veltaluma/Perfica
```

If no private reporting facility is available, open a minimal issue asking
maintainers for a private security contact channel. Do not include vulnerability
details in that public issue.

## What to include

A useful private report should include:

- affected Perfica version or revision;
- affected platform;
- vulnerability description;
- reproduction conditions;
- security impact;
- proof of concept when safe to provide privately;
- suggested mitigation if known.

## Sensitive areas

Security-sensitive components include:

- backup archive parsing and extraction;
- attachment file handling;
- database restore;
- bug-report diagnostics;
- deep-link handling;
- update-check networking;
- notification actions;
- Android widget/background components.

## Disclosure

Please allow maintainers a reasonable opportunity to investigate and prepare a
fix before public disclosure.

Perfica does not currently promise a bug bounty, financial reward, or formal
response-time SLA.
