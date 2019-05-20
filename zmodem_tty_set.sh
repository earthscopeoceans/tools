#!/bin/sh

stty eof ^- eol ^- erase ^- intr ^- kill ^- quit ^- start ^- stop ^- susp ^- eol2 ^- lnext ^- rprnt ^- swtch ^- werase ^-
stty -ignbrk brkint -ignpar -parmrk -inpck -istrip -inlcr -igncr -icrnl -ixon -ixoff -iuclc -ixany -iutf8 -imaxbel
stty -opost -olcuc -ocrnl -onlcr -onocr -onlret -ofill -ofdel
stty nl0 cr0 tab0 bs0 vt0 ff0
stty -echoe -echok -echonl -isig -icanon -iexten -noflsh -xcase -tostop -echoprt -echoctl -echoke
stty min 1 time 1
stty -echo

