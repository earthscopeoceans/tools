#!/bin/bash

FILE="$1"
if [ -z $2 ]; then 
    RECIPIENT="881631589412@msg.iridium.com"
else
    RECIPIENT="$2"
fi

LATPAT="[NS][0-9]\{2\}deg[0-9]\{2\}.[0-9]\+mn"
LONGPAT="[EW][0-9]\{3\}deg[0-9]\{2\}.[0-9]\+mn"

# 1st evaluates the file length (in lines) and send the last coordinates
LINE_NB=`wc -l "$FILE" | awk '{print $1}'`
LINE=`grep "$LATPAT, $LONGPAT" "$FILE" | tail -n 1`
DATE=`echo "$LINE" | awk -F':' '{print $1}'`
COORD=`echo "$LINE" | awk -F':' '{print $NF}'`
LAT=`echo "$COORD" | awk -F',' '{print $1}' | sed 's/^ \+//'`
LONG=`echo "$COORD" | awk -F',' '{print $2}' | sed 's/^ \+//'`
N0=$LINE_NB
sz=`echo -e "$DATE\n$FILE\n$LAT\n$LONG" | wc -c`
echo -e "$DATE, $FILE, $LAT, $LONG ($sz bytes)"
if [ ! -z $RECIPIENT ]; then
    # TODO set the nb of lines depending on the display size
    echo -e "$DATE\n$FILE\n$LAT\n$LONG" \
         | mail -s "$FILE" "$RECIPIENT"
fi
# then periodically check for any new lines that content coordinates
while [ 1 ]; do
    LINE_NB=`wc -l "$FILE" | awk '{print $1}'`
    if [ $LINE_NB -gt $N0 ]; then
        # new lines, search for coordinates
        LINE=`tail -n $(( $LINE_NB - $N0 )) "$FILE" | grep "$LATPAT, $LONGPAT"`
        DATE=`echo "$LINE" | awk -F':' '{print $1}'`
        COORD=`echo "$LINE" | awk -F':' '{print $NF}'`
        LAT=`echo "$COORD" | awk -F',' '{print $1}' | sed 's/^ \+//'`
        LONG=`echo "$COORD" | awk -F',' '{print $2}' | sed 's/^ \+//'`
        if [[ ! -z $COORD ]]; then
            # coordinates found
            echo -e "$DATE, $FILE, $LAT, $LONG"
            if [[ ! -z $RECIPIENT ]]; then
                # TODO set the nb of lines depending on the display size
                echo -e "$DATE\n$FILE\n$LAT\n$LONG" \
                      | mail -s "$FILE" "$RECIPIENT"
            fi
        fi
        N0=$LINE_NB
    elif [ $LINE_NB -lt $N0 ]; then
        # some lines have disappeared
        N0=$LINE_NB
    fi
    sleep 1
done

