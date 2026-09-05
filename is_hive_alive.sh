#!/bin/bash
#
# is_hive_alive.sh
#
# Purpose:
#   Health-check utility for the Hive metastore. Runs a test Hive query
#   with a configurable timeout. If Hive does not respond within that
#   window, the script assumes the metastore is down/unreachable and
#   sends an email alert to the administrator.
#
# Usage:
#   ./is_hive_alive.sh <threshold_in_seconds> <password>
#
# Typically scheduled via cron for periodic monitoring.
#
# Note on the password parameter:
#   Passed in rather than hardcoded, and exported as SERVICE_PASSWORD
#   (see main()) instead of embedded directly in a command string. This
#   keeps the script service-agnostic, so it can later be adapted to
#   health-check other password-protected services beyond Hive.

# ---------------------------------------------------------------------------
# usage()
# Prints command-line usage instructions to the screen.
# Called when the script is invoked with the wrong number of arguments.
# ---------------------------------------------------------------------------
usage()
{
cat << EOF
usage: $0 <threshold in seconds> <password>
EOF
}

# ---------------------------------------------------------------------------
# timeout()
# Runs a shell command and enforces a maximum execution time on it.
#
# Arguments:
#   $1 - timeout duration, in seconds
#   $2 - the shell command to execute
#
# Returns:
#   0 - command completed within the timeout
#   1 - command was still running when the timeout was reached (killed)
#
# Implementation notes:
#   Bash has no native per-command timeout, so this wraps the command
#   using `expect`, which can watch for either the timeout event or the
#   command exiting (eof) and react accordingly.
# ---------------------------------------------------------------------------
timeout() {
    # Timeout duration in seconds (first argument)
    time=$1
    # Command to run, wrapped so it executes via /bin/sh (second argument)
    command="/bin/sh -c \"$2\""

    # Spawn the command under `expect`:
    #   - set echo "-noecho": suppress echoing of input
    #   - set timeout $time: how long to wait before giving up
    #   - spawn -noecho $command: start the command silently
    #   - expect timeout { exit 1 }: if time runs out first, exit with code 1
    #   - eof { exit 0 }: if the command finishes first, exit with code 0
    expect -c "set echo \"-noecho\"; set timeout $time; spawn -noecho $command; expect timeout { exit 1 } eof { exit 0 }"

    # Translate the expect script's exit code into this function's return value
    if [ $? = 1 ] ; then
	return 1;
    fi
    return 0;
}

# ---------------------------------------------------------------------------
# main()
# Entry point. Validates arguments, runs the Hive health check, and sends
# an email alert if the check times out.
#
# Arguments:
#   $1 - timeout threshold in seconds
#   $2 - password to use when authenticating to the target service
#
# Note:
#   The password is exported as an environment variable (SERVICE_PASSWORD)
#   rather than baked into a hardcoded command string. This keeps the
#   script generic: any command invoked from within (Hive today, other
#   services later) can read it from the environment without the script
#   itself needing to know how each service's auth flow works.
# ---------------------------------------------------------------------------
main() {
    # Require exactly two arguments; otherwise show usage and abort
    if [ $# != 2 ] ; then
        usage ; exit 1
    fi

    TIMEOUT_IN_SECONDS=$1

    # Export the password so any command spawned by this script (directly,
    # or via the timeout()/expect wrapper) can pick it up from its
    # environment, e.g. `hive --hiveconf password=$SERVICE_PASSWORD` or
    # a future non-Hive service reading the same variable.
    export SERVICE_PASSWORD=$2

    echo "Timeout: $TIMEOUT_IN_SECONDS"

    # Attempt to run a Hive query (from a file of pre-defined commands)
    # and bail out if it doesn't complete within the timeout window
    timeout $TIMEOUT_IN_SECONDS "hive -f /apps/scripts/file_containing_command.hive"

    if [ $? = 1 ] ; then
        # Hive query did not finish in time -> assume metastore is down
        # and prepare an alert email

        MAIL_FILE="/tmp/mail_hive_down.txt"
        SUBJECT="ALERT from `hostname` - Connection to Hive metastore timed out."
        EMAIL="administrators_email_address"
        FORMATTED_LINE="Hive metastore is unreachable. Waited $TIMEOUT_IN_SECONDS seconds. Please verify ASAP. "

        # Write the alert message to a temp file to use as the email body
        echo $FORMATTED_LINE > $MAIL_FILE

        # Send the alert email to the administrator
        mail -E -c "$CC_EMAIL" -s "$SUBJECT" "$EMAIL" < "$MAIL_FILE"
    fi
}

# Kick off execution, passing through all command-line arguments
main "$@"
