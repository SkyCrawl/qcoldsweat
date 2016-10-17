#!/bin/sh

# setup basic variables
CONF="/etc/config/qpkg.conf"
QPKG_NAME="Coldsweat"
QPKG_ROOT=`/sbin/getcfg $QPKG_NAME Install_Path -f ${CONF}`
APACHE_ROOT=/share/`/sbin/getcfg SHARE_DEF defWeb -d Qweb -f /etc/config/def_share.info`

# perform the given action
case "$1" in
  start)
  	# basic handling
    ENABLED=$(/sbin/getcfg $QPKG_NAME Enable -u -d FALSE -f $CONF)
    if [ "$ENABLED" != "TRUE" ]; then
        echo "$QPKG_NAME is disabled."
        exit 1
    fi
    
    # TODO: configure the port in web UI
    # /opt/bin/python2.7 "$QPKG_ROOT/sweat.py" serve -p 5678
    ;;

  stop)
	# for MY_PCS in `ps -Ar | grep "sweat.py serve"`; do
	# only kill the coldsweat's process (command starts with "python"), not the above "ps" command
    #    if [[ $MY_PCS == *"python"* ]]
    #    then
    #        MY_PID=`echo $MY_PCS | awk '{print $1}'` # first word of process info is PID
    #        kill $MY_PID 2> /dev/null
    #    fi
    # done
    ;;

  restart)
    $0 stop
    $0 start
    ;;

  *)
    echo "Usage: $0 {start|stop|restart}"
    exit 1
esac

exit 0
