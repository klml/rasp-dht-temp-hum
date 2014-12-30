#!/bin/bash

LOGFILE=temphumdity.csv
ADAFRUITDHTDRIVER=~/adafruit/Adafruit-Raspberry-Pi-Python-Code-master/Adafruit_DHT_Driver/
TEMPDIFFVARIANCE=1
HUMIDITYDIFFVARIANCE=1
SLEEP=2

# use paramater from cli or set it here
LOGFILE=${1-$LOGFILE}

date=$(date +"%Y-%m-%d %H:%M")


# create logfile with table head
if [ ! -f $LOGFILE ]; then
    echo "Date,temp,hum" > $LOGFILE
fi

function readcurrent {

    RAWTEMPHUM=$($ADAFRUITDHTDRIVER/Adafruit_DHT 22 4)
    TEMP=( $(echo $RAWTEMPHUM | awk '{print $13}'))
    HUMIDITY=( $(echo $RAWTEMPHUM | awk '{print $17}'))

    # proof if you get a useful value from sensor or try ist again
    if  [[ -z "$TEMP" ]] ; then
        sleep $SLEEP
        readcurrent
    fi

}
readcurrent

LOGLASTVALUES=( $( tail -n 1 $LOGFILE | sed  's/.*,\(.*\),\(.*\)/\1 \2/' ))

# remove decimale to calculate
# there is mostly no bc or locale on rasperry
# TODO function
TEMP100=( $( echo $TEMP | sed  's/\.//' ))
HUMIDITY100=( $( echo $HUMIDITY | sed  's/\.//' ))
OLDTEMP100=( $( echo ${LOGLASTVALUES[0]} | sed  's/\.//' ))
OLDHUMI100=( $( echo ${LOGLASTVALUES[1]} | sed  's/\.//' ))

let HUMIDITYDIFF=$HUMIDITY100-$OLDHUMI100
let TEMPDIFF=$TEMP100-$OLDTEMP100

# get absolute value
if [ $TEMPDIFF -lt 0 ] ; then
    let TEMPDIFF=$TEMPDIFF*-1
fi
if [ $HUMIDITYDIFF -lt 0 ] ; then
    let HUMIDITYDIFF=$HUMIDITYDIFF*-1
fi

# only write if value has changed
if [ $TEMPDIFF -gt $TEMPDIFFVARIANCE ]  || [ $HUMIDITYDIFF -gt $HUMIDITYDIFFVARIANCE  ] ; then
    echo "$date,$TEMP,$HUMIDITY" >> $LOGFILE
fi

