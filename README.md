# ont_auto_rsync
Automatically rsync ONT sequencing data on a Mk1c or similar sequencing host to the HPC cluster

This repo is expected to be cloned into MK1C:/data/user-scripts

* rsync_reads.sh](rsync_reads.sh) SRCDIR DESTDIR [rsync_flags] 
   * scans SRCDIR for sequencing runs, which are located by looking for "fast5_fail" directory. 
   * MD5 check sums are computed for all files, and a roll-up "md5sum" text file is created
   * The files are then rsync'ed to DESTDIR
      * the admin should create a public/private keypair, or add a password to .netrc to allow this
      * it is advisable to block non-rsync ssh commands on the source computer for this account.
   * if rsync succeeds, and "final_summary*.txt" exists, then "rsync.done" is created, and that sequencing directory will be skipped in the future
   * this script should be added to crontab using run-one (which may need to be installed ```apt install run-one```
      * run-one skips the next call, if the previous is still running (transfering data)
      * crontab entry ```0,30 * * * * run-one /data/user_scripts/rsync_reads.sh /data USER@HOST:/TARGET_PATH```



* Makefile](Makefile)
   * target: "md5sum" 
      * computes .md5 files for sequencing and metadata files
      * creates roll-up "md5sum" 
