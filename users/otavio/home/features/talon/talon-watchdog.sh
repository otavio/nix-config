#!/usr/bin/env bash
set -euo pipefail

LOG_FILE=$HOME/.talon/talon.log
NOTIFY_THRESHOLD=10
RESTART_THRESHOLD=60

notified=false
while true; do
	inotifywait -e modify "${LOG_FILE}" >/dev/null 2>&1

	tail -n 10 "${LOG_FILE}" | while read -r line; do
		if [[ ${line} == *"(stalled)"* ]]; then
			count=$(echo "${line}" | cut -d@ -f2 | cut -ds -f1 | cut -d. -f1)
			# Keep the count high in case we are running certain scripts
			if [[ ${count} -ge $RESTART_THRESHOLD ]]; then
				talon-notify "Talon auto-restarting"
				systemctl --user restart talon
				sleep 5
				notified=false
			elif [[ ${count} -ge $NOTIFY_THRESHOLD ]] && [[ $notified == false ]]; then
				talon-notify "Talon stalled. Will auto-restart after ${RESTART_THRESHOLD}s"
				# FIXME: We should use a notification that allows you to collect yes or no to restart
				# gnome-shell doesn't support expiry time, so we can rely on an action for now, unless we used
				# something like dunst
				sleep 5
				notified=true
			fi
		fi
	done

	# This $? comes from exit in the read line while loop above
	if [[ $? == 1 ]]; then
		exit 1
	fi
done
