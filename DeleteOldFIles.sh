#!/bin/bash
DIRECTORY="/media/storage/audio"
CAPACITY=80
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
LOGFILE="$SCRIPTPATH/DeleteOldFiles.log"
#
# To prevent multiple instances of a script from executing concurrently,
# include this function, and a statement to invoke it, at the top of any
# ksh/bash script.  This function will check for other instances of the
# same script that are executing by the same user.  If any are found, then
# this instance terminates immediately.
#
# When scripts are invoked in a repetitive manner (cron or other scheduler),
# it's possible that an instance can still be running when the time arrives
# to start a new instance.  For example, suppose that you schedule a script
# to run every 15 minutes, but one run takes 20 minutes?  You may not want
# 2 (or more) concurrent instances of the script to run.
#
function TerminateIfAlreadyRunning
{
##
## Terminate if another instance of this script is already running.
##
SCRIPT_NAME=`/bin/basename $1`
echo "`/bin/date +%Y%m%d.%H%M%S:` This instance of $SCRIPT_NAME is PID $$" >> $LOGFILE
for PID in `/bin/ps -fC $SCRIPT_NAME | /bin/grep "^$USER" | /usr/bin/awk '{print $2}'`
do
        ALIVE=`/bin/ps -p $PID -o pid=`
        if [[ "$PID" != "$$"  &&  "$ALIVE" != "" ]]
        then
                echo "WARNING: $SCRIPT_NAME is already running as process $PID!" >> $LOGFILE
                echo "Terminating..." >> $LOGFILE
                exit 0
        fi
done
}
TerminateIfAlreadyRunning $0
# Optional spinner if running in console instead of CRON to indicate processing.
spinner() {
  local s="|/-\\"
  local -i i=0
  while :; do
    printf "%s\\r" "${s:$((i++%4)):1}" >&2
    sleep .05
  done
}

# Start the spinner in the background
#spinner &

# Get the spinner PID
#spinner_pid=$!
#echo $LOGFILE
while [[ $(df $DIRECTORY | awk 'NR==2 && gsub("%","") {print$5}') -ge $CAPACITY ]];do
        find $DIRECTORY -mindepth 1 -type f -printf '%T+ %p\n' | sort | awk 'NR==1 {first = $1; $1=""; print $0}' | sed 's/^ //g' | tee -a $LOGFILE | xargs -d '\n' rm
        #find $DIRECTORY -mindepth 1 -type f -printf '%T+ %p\n' | sort | awk 'NR==1 {first = $1; $1=""; print $0}' | sed 's/^ //g'
done

# Terminate the background running spinner
#kill $spinner_pid