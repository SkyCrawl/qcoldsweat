#!/bin/sh

# Apache info:
# 1) Web server configuration file: /etc/config/apache/apache.conf
# 2) Web server distro root: /usr/local/apache
# 3) Web server content root: use the below APACHE_ROOT variable
#
# The worst comes when trying to make CGI work - QNAP is not helping with that at all. Notes:
# - Add our custom 'cgi-bin' path to the existing 'ScriptAlias' in config?
# - chmod g+x? (we need 775)
#
# I tried but gave up. But then, I don't really need a Web UI.
# 

# declare variables
# APACHE_ROOT="/share/$(/sbin/getcfg SHARE_DEF defWeb -d Qweb -f /etc/config/def_share.info)"
QPKG_CONF="/etc/config/qpkg.conf"
QPKG_NAME="QColdsweat"
QPKG_ROOT="$(/sbin/getcfg $QPKG_NAME Install_Path -f $QPKG_CONF)"
QPKG_PORT="$(/sbin/getcfg $QPKG_NAME Service_Port -f $QPKG_CONF)"
APP_NAME="Coldsweat"

ENTWARE_NAME="Entware"
ENTWARE_ROOT="$(/sbin/getcfg $ENTWARE_NAME Install_Path -f $QPKG_CONF)"

## Coldsweat data folder.
CS_DIST_ROOT="$QPKG_ROOT/coldsweat"
CS_DATA_FOLDER="$QPKG_ROOT/../.coldsweat"
CS_LOG_ACCESS="$CS_DATA_FOLDER/log-access"
CS_PID_FILE="$CS_DATA_FOLDER/pid"

# declare commands
# Note: we MUST use "/opt/bin/python" as the "ps" command somehow truncates lines
# of output to 80 characters and our grep pattern will not be matched by a thin
# margin if "$ENTWARE_ROOT/bin/python" is used instead. This only happens when
# disabling the QPKG though - when enabling, the limit seems to be larger. Weird,
# QNAP... weird. As such, successful launch of Coldsweat depends on previous successful
# launch of entware. That's why the RC_NUMBER is set to 102 (entware is 101).
CMD_PYTHON="/opt/bin/python"
CMD_GREP="/opt/bin/grep"

# allow "Resource Monitor" to monitor the process
export QNAP_QPKG=$QPKG_NAME

# a helper function
function is_coldsweat_running()
{
	# basic check
	if [ ! -f "$CS_PID_FILE" ]; then
		echo "0"
		# DEBUG msg: echo "PID file doesn't exist" >> "$LOG_FILE"
		return
	fi

	# "$()" spawns a new process - must use `` instead (PID would be incorrect otherwise)
	PID=`cat "$CS_PID_FILE"`
	# DEBUG msg: ps | $CMD_GREP -e "^\s*$PID admin.*sweat.py serve.*$" >> "$LOG_FILE"
	# DEBUG msg: ps >> "$LOG_FILE"
	PID_INFO=`ps | $CMD_GREP -e "^\s*$PID.*sweat.py serve.*$"`
	
	# and finally...
	if [ -z "$PID_INFO" ]; then
		echo "0"
		# DEBUG msg: echo "The $PID PID could not be matched against a running instance" >> "$LOG_FILE"
	else
		echo "1"
	fi
}

# just some code for testing...
<<COMMENT
FILE="/share/Public/test.pid"
if [ -f "$FILE" ]
then
	FILE="/share/Public/test1.pid"
fi
if [ -f "$FILE" ]
then
	FILE="/share/Public/test2.pid"
fi

touch "$FILE"
echo "$*" > "$FILE"

# create or truncate the log file
LOG_FILE="$CS_DATA_FOLDER/ffs.log"
> "$LOG_FILE"

# redirect stdout and stderr of this script to the above log file
# Note: eventually, restore the original state with 'exec &>/dev/tty'
exec >> "$LOG_FILE"
exec 2>&1

COMMENT

# perform the given action
case "$1" in
	start)
		# disabled QPKG has no right to start...
		ENABLED="$(/sbin/getcfg $QPKG_NAME Enable -u -d FALSE -f $QPKG_CONF)"
		if [ "$ENABLED" != "TRUE" ]; then
			echo "$QPKG_NAME is disabled."
			exit 1
		fi
		
		# shutdown the running instance first
		# Note: with this, we're covering potential bugs or problems. But if we don't do it,
		# the next block of code will cause a mismatch between saved PID and actual process.
		# Luckily, Coldsweat is smart enough to automatically eliminate subsequent running
		# instances.
		if [ "$(is_coldsweat_running)" == "1" ]; then
			echo "Stopping the current instance..."
			./$0 stop
			# Note: doesn't work properly without these additional commands...
			/bin/sleep 5
			/bin/sync
		fi
		
		# we should never launch multiple instances
		if [ "$(is_coldsweat_running)" == "0" ]; then
			# v0.9.6 to v0.9.7 contains a bug that prevents Coldsweat from being launched from a different folder...
			cd "$CS_DIST_ROOT"
			$CMD_PYTHON "sweat.py" serve -r -p "$QPKG_PORT" &> "$CS_LOG_ACCESS" &
			echo $! > "$CS_PID_FILE"
		else
			echo "$APP_NAME is already running."
			exit 1
		fi
		;;

	stop)
		# shutdown the running instance
		if [ "$(is_coldsweat_running)" == "1" ]; then
			# "$()" spawns a new process - must use `` instead (PID would be incorrect otherwise)
			PID=`cat "$CS_PID_FILE"`
		    kill $PID
		else
			echo "$APP_NAME is not running."
			exit 1
		fi
		;;
		
	test)
		# test whether the service is running
		if [ "$(is_coldsweat_running)" == "1" ]; then
			echo "$APP_NAME is running."
		else
			echo "$APP_NAME is NOT running."
		fi
		;;

	restart)
		./$0 stop
		# Note: doesn't work properly without these additional commands...
		/bin/sleep 5
		/bin/sync
		./$0 start
		;;

	*)
		echo "Usage: $0 {start|stop|restart|test}"
		exit 1
esac

# if everything goes well...
exit 0
