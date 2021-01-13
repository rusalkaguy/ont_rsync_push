#!/bin/bash

SRCDIR=$1
DESTDIR=$2
shift 2
RSYNC_ARGS="$*"
#
# constants
#
MAKEFILE="/data/user_scripts/Makefile"
MD5SUM="md5sum"
MD5SUM_CORES=6
DONE="rsync.done"

if [[ -z "$SRCDIR" || -z "$DESTDIR" ]]; then 
	echo "SYNTAX: $0 SRC_DIR DEST_DIR [RSYNC_ARGS]"
	exit 1
fi

#
# find sequencing runs
#
pushd $SRCDIR > /dev/null
SEQ_RUNS=$(find . -type d -name "fast5_fail" )
for src in $SEQ_RUNS; do
	srcd=$(dirname $src)
	echo -e "\n\n##### checking $srcd ######"
	FINAL_SUMMARY=$( echo $srcd/final_summary*.txt )

	# 
	# skip if completely transfered
	#
	if [[ -f $srcd/$DONE && -f $FINAL_SUMMARY ]]; then
		if [[ $srcd/$DONE -nt $FINAL_SUMMARY ]]; then  
			echo SKIP $srcd
			continue
		fi
	fi

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
	echo rsync $RSYNC_ARGS -hav --partial --relative --exclude "**/.md5" $srcd "$DESTDIR"
	rsync $RSYNC_ARGS -hav --partial --relative --exclude "**/*.md5" $srcd "$DESTDIR"
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
				date > $srcd/$DONE
			fi
		else
			echo "## NOT exist: $MD5SUM $FINAL_SUMMARY"
		fi
	fi	
done

