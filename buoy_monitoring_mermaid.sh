#!/bin/bash

DIR="$HOME"
PERIOD_s=300
BASE="452"
EXT=".vit"
LIST="$HOME/.buoy_monitoring_mermaid.list"
EMAIL="email@domain.com"

###############################################################################
_is_known () {
    if [ ! -f "$LIST" ]; then
        echo 0
    else
        found=`grep $1 "$LIST"`
        if [ -z "$found" ]; then
            echo 0
        else
            echo "$found" | awk '{print $2}'
        fi
    fi
}

###############################################################################
_on_emergency () {
    buoy="$1"
    if [ -f "$DIR""/emergency.cmd" ]; then
        if [ -h "$DIR""/""$buoy"".cmd" ]; then
            echo "$DIR""/""$buoy"".cmd is a link, nothing done"
            cat "$DIR""/""$buoy"".cmd"
        else
            if [ -f "$DIR""/""$buoy"".cmd" ]; then
                echo "$DIR""/""$buoy"".cmd exists, backing up"
                mv "$DIR""/""$buoy"".cmd" "$DIR""/""$buoy"".back"
            fi
            ln -s "$DIR""/emergency.cmd" "$DIR""/""$buoy"".cmd"
        fi
    else
        echo "$DIR""/emergency.cmd does not exist, do nothing for $buoy"
    fi
}

###############################################################################
_send_email () {
    buoy="$1"
    if [ ! -z "$2" ]; then
        msg=`tail -n $2 $buoy`
    else
        msg=`cat $buoy`
    fi
    msg=`echo "$msg" | sed -e "s/mn$/'/g"`
    msg=`echo "$msg" | sed -e "s/mn,/'/g"`
    msg=`echo "$msg" | sed -e "s/deg/°/g"`
    echo "$msg" | mail -s "$buoy" $EMAIL
}

###############################################################################
# TODO we receive the signal when the main loop is not sleeping
_reload_cfg () {
    echo "Loading parameters from file $CONF"
    . "$CONF"
}

###############################################################################
if [ ! -z $1 ]; then
    CONF="$1"
fi
if [ -f "$CONF" ]; then
    _reload_cfg
else
    echo "File $CONF not found, using default parameters"
fi
if [ -f "$LIST" ]; then
    echo "$LIST exists, use it"
    cat "$LIST"
fi
if [ -f "$DIR/emergency.cmd" ]; then
    chmod a-w "$DIR/emergency.cmd"
    echo "$DIR/emergency.cmd exists"
    cat "$DIR/emergency.cmd"
else
    echo "$DIR/emergency.cmd does not exist"
    #echo "stage del" > "$DIR/emergency.cmd"
    #echo "stage store" >> "$DIR/emergency.cmd"
    #echo "upload 1" >> "$DIR/emergency.cmd"
    #cat "$DIR/emergency.cmd"
fi

echo "\"kill -1 $$\" to reload configuration file"
trap _reload_cfg HUP

echo "Start monitoring on $DIR for any buoy connections"
while [ 1 ] ; do
    ls -1 "$DIR"/"$BASE"*"$EXT" | while read buoy_file; do
        buoy=`echo "$buoy_file" | awk -F'/' '{ printf $NF }'`
        sz=`wc -l "$buoy_file" | awk '{print $1}'`
        known=`_is_known "$buoy_file"`
        if [ $known -eq 0 ]; then
            echo "New buoy $buoy detected"
            # append the buoy and its file size at the end of the list
            echo "$buoy_file $sz" >> "$LIST"
            # check for EMERGENCY in the new buoy file
            EMERGENCY=`grep EMERGENCY "$buoy_file"`
            if [ ! -z "$EMERGENCY" ]; then
                echo "!!! buoy $buoy in EMERGENCY !!!"
                _on_emergency $buoy
            fi
            # send the whole file by email
            _send_email "$buoy_file"
        elif [ ! $known -eq $sz ]; then
            echo "buoy $buoy connection detected"
            # update the buoy file size in the list
            sed -i "s/$buoy $known/$buoy $sz/" "$LIST"
            # check for EMERGENCY at the end of the buoy file
            EMERGENCY=`tail -n $(( $known - $sz )) $buoy_file | grep EMERGENCY`
            if [ ! -z "$EMERGENCY" ]; then
                echo "!!! buoy $buoy in EMERGENCY !!!"
                _on_emergency $buoy
            fi
            # send the new lines only
            _send_email "$buoy_file" $(( $known - $sz ))
        fi
    done
    sleep $PERIOD_s
done
