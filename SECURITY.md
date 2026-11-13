# Security and responsible reporting

`epochutc` is a local timestamp formatter. It is not an intrusion detector,
an evidence validator, or a mechanism for checking whether a capture clock is
correct. Treat the original logs as authoritative evidence and document any
transformations you perform.

Review scripts before installing them. Run the converter unprivileged; root
is only relevant when choosing a system-wide installation path. Use a trusted
destination directory. Never pipe an unreviewed downloaded script into a shell.

If you find a security issue, do not publish credentials, private logs, or
unredacted exploit-sensitive details. When GitHub private vulnerability
reporting is enabled for the repository, use that route. Otherwise, open a
minimal issue requesting a private contact method, without sensitive details.
Private reporting is not assumed to be enabled merely because this file exists.

Security fixes will be documented in the changelog. This community project
has no guaranteed response-time or long-term-support commitment.
