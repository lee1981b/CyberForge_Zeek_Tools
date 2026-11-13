# Using epochutc

## One timestamp

```bash
epochutc 1762865412.453821
```

```text
2025-11-11 12:50:12.453821 UTC
```

Output always uses UTC, regardless of your machine's local time zone.

## Several timestamps

```bash
epochutc 0 1.25 -1
```

```text
1970-01-01 00:00:00.000000 UTC
1970-01-01 00:00:01.250000 UTC
1969-12-31 23:59:59.000000 UTC
```

The output order matches the input order. Negative seconds represent dates
before the Unix epoch, subject to the range supported by your date command.

## Precision

By default the display has **six fractional digits** (microseconds), matching
the original CyberForge helper. Whole seconds are padded with zeroes.

```bash
epochutc 0.123456789
epochutc --nanoseconds 0.123456789
```

```text
1970-01-01 00:00:00.123456 UTC
1970-01-01 00:00:00.123456789 UTC
```

The shorter display truncates the UTC fractional field instead of rounding.
For negative timestamps, GNU date first normalizes the timestamp to its
calendar second and fractional part: `-0.1` becomes
`1969-12-31 23:59:59.900000 UTC`.

`--nanoseconds` preserves up to nine input fractional digits in the output;
it does not make the original capture more accurate. Output precision is not
evidence of capture-clock accuracy. Keep original logs as your source evidence.

## Read a timestamp stream

Use `--stdin` explicitly. Provide **one decimal timestamp per line**:

```bash
printf '%s\n' 0 1.25 1762865412.453821 | epochutc --stdin
epochutc --stdin < timestamps.txt
```

`-s` and `-` are aliases for `--stdin`. Empty or whitespace-only lines are
skipped; CRLF input and a final line without a newline are supported. Numbers
with leading/trailing spaces are rejected rather than silently repaired.

Do not mix `--stdin` with timestamp arguments. Running without either mode
prints usage and exits with status `2`; it does not wait unexpectedly for input.

## With Zeek TSV logs

Extract the field by name with Zeek's own `zeek-cut`:

```bash
zeek-cut ts < conn.log | epochutc --stdin
zeek-cut ts < http.log | epochutc --stdin
```

Do not pipe an entire `conn.log` directly into the converter: it does not parse
headers or multi-column Zeek rows. `zeek-cut` is needed only for this optional
workflow, not for normal timestamp conversion.

When pipeline failure detection matters, enable Bash's `pipefail` so failure
in `zeek-cut` is not masked by the final command:

```bash
set -o pipefail
zeek-cut ts < conn.log | epochutc --stdin > conn-timestamps-utc.txt
```

The output file contains timestamps only. It is a derived view, not a
replacement for the original log. Invalid values are reported to stderr and
omitted from stdout, so do not assume line-for-line alignment after errors.

Zeek can also do its own UTC formatting:

```bash
zeek-cut -u ts < conn.log
```

`epochutc` is an additional standalone convenience, not a replacement for
Zeek's log tooling. For JSON logs, extract decimal `ts` values with a suitable
JSON parser first; the converter does not accept JSON directly. Be aware of
the numeric precision of whichever parser you choose.

## Accepted input

The accepted form is:

```text
[optional + or -]integer[optional .fraction]
```

Fractions must contain between one and nine digits. Examples: `0`, `+1`,
`-1`, `1762865412.453821`.

The following are rejected: an empty string, `.5`, `1.`, scientific notation,
comma decimals, whitespace around a number, and more than nine fractional
digits. Values outside GNU date's representable range also fail.

**Units are always seconds.** Millisecond/microsecond integers are not detected
or divided automatically. A large integer may be a valid timestamp far in the
future, so the tool cannot safely guess that a different unit was intended.

## Errors and exit codes

```bash
epochutc 0 not-a-timestamp 1
printf 'Exit code: %s\n' "$?"
```

The two valid timestamps go to stdout, the invalid-value diagnostic goes to
stderr, and the command exits with status `1`. It does not stop at the first
bad timestamp.

| Status | Meaning |
| :--- | :--- |
| `0` | All requested conversions succeeded, or help/version was shown |
| `1` | At least one timestamp was invalid or could not be represented |
| `2` | Invalid invocation, conflicting input modes, or no input |
| `3` | No compatible GNU `date` / `gdate` was found |

Use flags before timestamp arguments:

```bash
epochutc --nanoseconds 0.123456789
epochutc -- -1
```

## Limits

A separate GNU date process is started for each timestamp. This is a practical
interactive/small-stream helper, not a benchmarked bulk analytics engine.
Unix seconds do not encode every leap second as a distinct timestamp on the
usual POSIX time scale. See the [GNU references](../../docs/REFERENCES.md).

No capture files, source logs, shell profiles, system clocks, or Zeek settings
are changed. The converter makes no network requests.

[Installation](INSTALL.md) | [Tool overview](README.md)
