set TODAY = `date +%s`
set PPID = `ps -o ppid -p $$ | tail -n 1 | sed 's/ //g'`
set PCMD = `ps -ocommand= -p $PPID | awk -F: '{print $1}' | awk '{print $1}'`
set FFFF = $TODAY"-"$PCMD"-"$PPID".session"
if ( $PCMD != script && $PCMD != sshd ) then
    echo "session $TODAY, cmd $PCMD ($PPID), recorded in $FFFF"
    script -c csh -a -f $FFFF
endif
