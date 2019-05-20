#!/bin/bash

################################################################################
CMD_FILE="$1"
if [ -z $2 ]; then
    # TODO can not be stderr since it looks like IRIDIUM connection redirect it
    # on the remote stdin, maybe by default a file would be better ?
    #OUT_FILE="/dev/null"
    OUT_FILE="/dev/stderr"
else
    OUT_FILE="$2"
fi
################################################################################
### Remove trailing spaces ###
sed -i 's/ *$//' $CMD_FILE

################################################################################
_send_one() {
    CMD=`nmea_csum "$*"`
    CSUM=`echo "$CMD" | awk -F'*' '{print $2}'`
    echo "Tx: \"$CMD\"" >> "$OUT_FILE"
    echo -e "$CMD\r\n"
    line=0
    while [ $line -lt 1000 ] && read -t 30 ANS; do
        #echo "$ANS" | hexdump >> "$OUT_FILE"
        line=$(( $line + 1 ))
        TOK=${ANS:(-3):1}
        if [ "$TOK" == '*' ]; then
            ACK=${ANS:(-2)}
            if [ "$ACK" == "$CSUM" ]; then
                #echo "csum match" >> "$OUT_FILE"
                return 0
            elif [ "${ACK:0:1}" == 'X' ]; then
                echo "Rx: error code $ACK" >> "$OUT_FILE"
                return ${ACK:1:1}
            fi
            echo "Rx: csum mismatch $ACK instead of $CSUM" >> "$OUT_FILE"
            # csum mismatch is X2 (see src/cmd.h)
            return +2
        fi
        if [ ! -z "$ANS" ]; then
            echo "Rx: \"$ANS\"" >> "$OUT_FILE"
        fi
    done
    if [ $line -ge 1000 ]; then
        echo "Rx: $(line) received, exiting" >> "$OUT_FILE"
    else
        echo "Rx: no answer, exiting" >> "$OUT_FILE"
    fi
    return 255
}

################################################################################
_send_file() {
    if [ ! -f "$1" ]; then
        echo "### no cmd $1" >> "$OUT_FILE"
        return 0
    fi
    NB=`wc -l "$1" | awk '{print $1}'`
    for n in `seq 1 $NB`; do
        aline=`head -n $n "$1" | tail -n 1`
        if [[ ! -z "$aline"  && ${aline:0:1} != '#' ]]; then
            _send_one "$aline"
            res="$?"
            if [ ! $res -eq +0 ]; then
                if [ $res -eq +255 ]; then
                    echo "### cmd timeout" >> "$OUT_FILE"
                else
                    echo "### cmd error $res" >> "$OUT_FILE"
                fi
                return $res
            fi
        fi
    done
    return 0
}

################################################################################
TRY=0
DATE=`date -u "+%Y%m%d-%Hh%Mmn%S"`
echo "***$DATE: sending cmd from $CMD_FILE" >> "$OUT_FILE"
while [ $TRY -lt 3 ]; do
    _send_file "$CMD_FILE"
    res="$?"
    if [ $res -eq 0 ]; then
        echo "*** file $CMD_FILE content sent" >> "$OUT_FILE"
        echo "*** Clear request commands ***" >> "$OUT_FILE"
        sed -i '{s/^mermaid REQUEST/#mermaid REQUEST/g}' "$CMD_FILE"
        echo >> "$OUT_FILE" 
        exit 0
    fi
    TRY=$(( $TRY + 1 ))
    echo "*** try $TRY/3 failed for file $CMD_FILE" >> "$OUT_FILE"
done
echo "*** too many errors, skeeping file $CMD_FILE" >> "$OUT_FILE"
echo >> "$OUT_FILE" 
exit 1

