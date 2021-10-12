#!/bin/bash

# set debug to "yes" for more logging
VERBOSE=

# 
# parse args
#
if [[ "$1" == -*log ]]; then 
    LOG=$2 
    if [ ! -z "$LOG" ]; then echo $(date) ": $0 $*" >> $LOG; fi
    shift 2
fi
if [[ "$1" == -*v* ]]; then 
    VERBOSE=yes
    shift 1
fi
SRCDIR=$1
DESTDIR=$2
shift 2
RSYNC_ARGS="$*"

if [[ -z "$SRCDIR" || -z "$DESTDIR" ]]; then 
	echo "SYNTAX: $0 [-log logfile] SRC_DIR DEST_DIR [RSYNC_ARGS]"
	exit 1
fi

#
# constants
#
# Makefile is in the same dir as this script
MAKEFILE="$(dirname $0)/Makefile"
# make target and file name for combined run md5sums
MD5SUM="md5sum"
# use only 1 core, unless we know there is nothing running and can be greedier
MD5SUM_CORES=1  
# file to mark when a run is completely transfered and can be skipped in the future
DONE="rsync.done"
# file to mark that a run should be skipped, for example if it will never be completed or is corrupt.
SKIP="rsync.skip"

#
# find sequencing runs
#
pushd $SRCDIR > /dev/null
SEQ_RUNS=$(find . -type d -name "fast5_fail" )
for src in $SEQ_RUNS; do
	srcd=$(dirname $src)
	echo -e "\n\n##### checking $srcd ######"
    	if [[ ! -z "$VERBOSE" &&  ! -z "$LOG" ]]; then echo " ---------" LOGGING SCAN to $LOG; echo SCAN $srcd >> $LOG; fi
	FINAL_SUMMARY=$( echo $srcd/final_summary*.txt )

	# 
	# skip if completely transfered
	#
	if [[ -f $srcd/$DONE && -f $FINAL_SUMMARY ]]; then
		if [[ $srcd/$DONE -nt $FINAL_SUMMARY ]]; then  
			if [[ ! -z "$VERBOSE" && ! -z "$LOG" ]]; then echo DONE $srcd >> $LOG; fi
			echo COMPLETED $srcd
			continue
		fi
	fi
	if [[ -f $srcd/$SKIP ]]; then
		if [[ ! -z "$VERBOSE" && ! -z "$LOG" ]]; then echo SKIP $srcd $(head -1 $srcd/$SKIP) >> $LOG; fi
		echo SKIP $srcd
		continue
	fi
	if [ ! -z "$LOG" ]; then echo SYNC $srcd >> $LOG; fi

	# 
	# generate/update md5 sums
	#
	pushd $srcd > /dev/null
	echo "## update md5 sums $srcd"
	make -j $MD5SUM_CORES -f $MAKEFILE $MD5SUM
	popd > /dev/null
	# 
	# rsync 
	#
	echo "## rsync in $srcd"
	echo rsync $RSYNC_ARGS -hav --partial --relative --exclude "**/.md5" --exclude "devices "$srcd "$DESTDIR"
	rsync $RSYNC_ARGS -hav --partial --relative --exclude "**/*.md5" --exclude "devices" $srcd "$DESTDIR"
	RSYNC_RC=$?
	#
	# is that run completely xfered? 
	#
	if [ $RSYNC_RC == "0" ]; then
		echo "## RSYNC_RC=$RSYNC_RC"
		if [[ -f $srcd/$MD5SUM && -f $FINAL_SUMMARY ]]; then 
			echo "## exist: $MD5SUM $FINAL_SUMMARY"
			if [[ $srcd/$MD5SUM -nt $FINAL_SUMMARY ]]; then
                        	echo "## COMPLETED $srcd"
                        	if [ ! -z "$LOG" ]; then echo "MARK DONE $srcd" >> $LOG; fi
				date > $srcd/$DONE
			fi
		else
			echo "## NOT exist: $MD5SUM $FINAL_SUMMARY"
		fi
	fi	
done

