# ont_rsync_push
Automatically rsync ONT sequencing data on a Mk1c or similar sequencing host to the HPC cluster

This repo is expected to be cloned into MK1C:/data/user-scripts

* [rsync_reads.sh](rsync_reads.sh) [--log LOGFILE [-v]] SRCDIR DESTDIR [rsync_flags] 
   * scans SRCDIR for sequencing runs, which are located by looking for "fast5_fail" directory. 
   * MD5 check sums are computed for all files, and a roll-up "md5sum" text file is created
   * The files are then rsync'ed to DESTDIR
      * the admin should create a public/private keypair, or add a password to .netrc to allow this
      * it is advisable to block non-rsync ssh commands on the source computer for this account.
   * if rsync succeeds, and "final_summary*.txt" exists, then "rsync.done" is created, and that sequencing directory will be skipped in the future
   * this script should be added to crontab using run-one (which may need to be installed ```apt install run-one```
      * run-one skips the next call, if the previous is still running (transfering data)
      * crontab entry 
```
# copy seq results to HPC cluster
0,30 * * * * run-one /data/user_scripts/rsync_reads.sh --log /data/user_scripts/rsync_reads.log /data USER@HOST:/TARGET_PATH
```
   * if ```--log``` is given, logs concise messags to that file (one line per directory rsync'ed)
      * -v increases the level of logging - adds SCAN, DONE, SKIP notifications



* [Makefile](Makefile)
   * target: "md5sum" 
      * computes .md5 files for sequencing and metadata files
      * creates roll-up "md5sum" 

# Thoughts pull vs push

If I had time to re-write this from scratch, I would change the paradigm and have the cluster pull from the sequencer, or a hybrid model that computes md5s on the sequencer, then a cluster-based pull process that pulls over all file with md5 sums. 

I find the pull approach superior because:  
* security: would be a much simpler, and more robust, security setup (the current script requires the minuit account to be able to rsync to my account on the cluster, which is done with a public/private key pair plus an ssh authorization script).
* email: it would allow the system to send email when a sequencing run is completely transferred, or if an problem was encountered, such as the sequencer going off line. It is not easy to send email from the sequencer, though I’m sure that could be set up, and would not work for reporting when the sequencer goes off-line. 
