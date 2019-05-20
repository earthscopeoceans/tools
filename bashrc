###############################################################################
PATH="$HOME/tools:$HOME/tools/log:""$PATH"

###############################################################################
_check_and_start () {
    cmd="$1"
    pid=`ps aux | grep "$cmd" | grep -v 'grep' | awk '{print $2}'`
    if [ -z "$pid" ]; then
        echo "$cmd is not running" 1>&2
        nohup "$cmd" > "$HOME/.$cmd.nohup" &
    else
        echo "$cmd is running on PID $pid" 1>&2
    fi
}

###############################################################################
# following line reflect the tty config once logged
#stty cr0 nl0 -ocrnl onlcr -onlret -onocr echo

###############################################################################
#TODAY=`date +%s`
#UPID=`ps -o ppid -p $$ | tail -n 1 | sed 's/ //g'`
#PCMD=`ps -ocommand= -p $UPID | awk -F: '{print $1}' | awk '{print $1}'`
#TTY=`tty | awk -F'/' '{printf $NF}'`
#FFFF="sessions.logs"/$TODAY"-"$PCMD"-"$UPID"-"$TTY".session"
#if [[ $PCMD != "script" && $PCMD != "sshd" ]]; then
#    echo "session $TODAY, cmd $PCMD ($UPID), recorded in $FFFF"
#    script -c bash -a -f $FFFF
#fi
#
###############################################################################
case $- in
    *i* ) _check_and_start buoy_monitoring_osean.sh ;;
    * ) ;;
esac
