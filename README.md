# is_hive_alive.sh

A Bash utility that checks whether the Hive metastore is responsive by
running a test Hive query with a configurable timeout. If the query
doesn't complete in time, the script assumes the metastore is down or
unreachable and emails an alert to an administrator. Designed to be
scheduled via `crontab` for periodic health monitoring.

## Requirements

- Bash
- `expect` (used internally to enforce the timeout on the Hive command)
- `hive` CLI available and configured on the host running the script
- A local `mail` command capable of sending email (e.g. `mailx`/`sendmail`)

## Usage

```bash
./is_hive_alive.sh <threshold_in_seconds> <password>
```

- `<threshold_in_seconds>` — how long to wait for the Hive query to
  complete before treating the metastore as unreachable.
- `<password>` — password used to authenticate to the target service.
  It is exported as the `SERVICE_PASSWORD` environment variable rather
  than hardcoded, so it can be picked up by whatever command the script
  invokes (currently Hive, potentially other services in the future).

## Setup

Update the following directly in the script for your environment:
- The Hive command being health-checked (currently
  `hive -f /apps/scripts/file_containing_command.hive`)
- `EMAIL` — administrator email address to alert on failure
- `$CC_EMAIL` — optional CC recipient (currently referenced but not set
  anywhere in the script; set it as an environment variable or hardcode
  it if you want a CC recipient, or remove the `-c` flag if you don't)

## How it works

1. `main()` validates arguments and exports the password.
2. `timeout()` wraps the Hive command using `expect`, which watches for
   either the timeout expiring or the command finishing.
3. If the Hive command doesn't finish within the threshold, the script
   writes an alert message to `/tmp/mail_hive_down.txt` and emails it to
   the administrator via the `mail` command.

## Known limitations

- The `SERVICE_PASSWORD` environment variable is currently exported but
  not yet wired into the actual `hive -f ...` command — that integration
  depends on how your specific Hive setup expects credentials (e.g.
  `--hiveconf`, a JDBC connection string, etc.).
- Passing the password as a command-line argument means it may briefly
  appear in `ps` output or shell history on some systems. For stricter
  environments, consider reading it from a protected file or secrets
  manager instead.
