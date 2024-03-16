#!/bin/sh

# the below consist the entrypoint.sh in nginx default image

# vim:sw=4:ts=4:et

set -e

entrypoint_log() {
    # if [ -z "${NGINX_ENTRYPOINT_QUIET_LOGS:-}" ]; then
        echo "$@"
    # fi
}

if [ "$1" = "nginx" ] || [ "$1" = "nginx-debug" ]; then
    if /usr/bin/find "/docker-entrypoint.d/" -mindepth 1 -maxdepth 1 -type f -print -quit 2>/dev/null | read v; then
        entrypoint_log "$0: /docker-entrypoint.d/ is not empty, will attempt to perform configuration"

        entrypoint_log "$0: Looking for shell scripts in /docker-entrypoint.d/"
        find "/docker-entrypoint.d/" -follow -type f -print | sort -V | while read -r f; do
            case "$f" in
                *.envsh)
                    if [ -x "$f" ]; then
                        entrypoint_log "$0: Sourcing $f";
                        . "$f"
                    else
                        # warn on shell scripts without exec bit
                        entrypoint_log "$0: Ignoring $f, not executable";
                    fi
                    ;;
                *.sh)
                    if [ -x "$f" ]; then
                        entrypoint_log "$0: Launching $f";
                        "$f"
                    else
                        # warn on shell scripts without exec bit
                        entrypoint_log "$0: Ignoring $f, not executable";
                    fi
                    ;;
                *) entrypoint_log "$0: Ignoring $f";;
            esac
        done

        entrypoint_log "$0: Configuration complete; ready for start up"
    else
        entrypoint_log "$0: No files found in /docker-entrypoint.d/, skipping configuration"
    fi
fi

# set up ip tables
echo "Setting up iptables...."
iptables -I INPUT -j NFQUEUE --queue-num 0
iptables -I OUTPUT -j NFQUEUE --queue-num 0

# run suricata
echo "Starting suricata...."
/usr/bin/suricata -c /etc/suricata/suricata.yaml -q 0 &
exec "$@"


