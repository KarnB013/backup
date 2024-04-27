# Backup
A shell script that takes system backups at regular intervals

It also keeps a backup log (sample included) in same directory as shell script which tracks if a backup was created or not (in case no files were created/modified)

To run the backup in background, use _./lcbackup &_

Step 1 : On execution, the script will take a complete backup of all files in home directory and will store it in ~/home/backup/cbw24

(2 minute interval)

Step 2 : Any newly created/modified files after Step 1 are added to incremental backup and saved in ~/home/backup/ib24

(2 minute interval)

Step 3 : Any newly created/modified files after Step 2 are added to incremental backup and saved in ~/home/backup/ib24

(2 minute interval)

Step 4 : Any newly created/modified files after Step 1 (which means it'll include Step 1 and Step 2 file/s (if any) along with files created/modified after those 2 steps) are added to differential backup and saved in ~/home/backup/db24

(2 minute interval)

Step 5 : Any newly created/modified files after Step 4 are added to incremental backup and saved in ~/home/backup/ib24

Go back to Step 1
