#!/bin/bash

# counter for complete backup
i=1

# counter for incremental backup
j=1

# counter for differential backup
k=1

# to store complete backup time
complete_backup_time=0

# stores time for different backups (more info on usage where used)
comparison_time=0

# stores incremental backup time
incremental_backup_time=0

# stores differential backup time
differential_backup_time=0

# creating paths for backup
mkdir -p $HOME/home/backup/cbw24
mkdir -p $HOME/home/backup/ib24
mkdir -p $HOME/home/backup/db24

# stores path to store complete backup
tar_path_complete_backup="$HOME/home/backup/cbw24/cbw24-"

# stores path to store incremental backup
tar_path_incremental_backup="$HOME/home/backup/ib24/ib24-"

# stores path to store differential backup
tar_path_differential_backup="$HOME/home/backup/db24/db24-"

# used to append .tar when saving backup
ending=".tar"

# raised when incremental backup is created
flag_incremental=0

# raised when differential backup is created
flag_differential=0

# logic for complete backup
complete_backup() {
	# this function accepts path as argument, so, we use $1 to refer to path and /* includes all sub directories and files using a for loop
	for x in "$1"/*; do
		# if we get a directory, then recursively call the same function to get all files
		if [ -d "$x" ]; then
			complete_backup "$x"
		# if we get a file, then add it to the tar archive (adding just the file and not the whole file structure)
		elif [ -f "$x" ]; then
			(cd "$(dirname "$x")" && tar -rvf "${tar_path_complete_backup}${i}${ending}" "$(basename "$x")" 2>/dev/null 1>/dev/null) 
		fi
	done
}

# logic for incremental backup
incremental_backup() {
	# this function accepts path as argument, so, we use $1 to refer to path and /* includes all sub directories and files using a for loop
	for x in "$1"/*; do
		# if we get a directory, then recursively call the same function to get all files
		if [ -d "$x" ]; then
			incremental_backup "$x"
		# if we get a file, then add it to the tar archive (adding just the file and not the whole file structure)
		elif [ -f "$x" ]; then
			# we need to check if the file was modified after the previous backup was created
			mod_time=$(stat -c %Y "$x")
			# if the file was modified/created after last backup, we raise the flag to indicate that incremental backup is successful and add the file to tar archive
			if [ $mod_time -gt $comparison_time ]; then
				flag_incremental=1
				(cd "$(dirname "$x")" && tar -rvf "${tar_path_incremental_backup}${j}${ending}" "$(basename "$x")" 2>/dev/null 1>/dev/null)
			fi
		fi
	done
}

# logic for incremental backup
differential_backup() {
	# this function accepts path as argument, so, we use $1 to refer to path and /* includes all sub directories and files using a for loop
	for x in "$1"/*; do
		# if we get a directory, then recursively call the same function to get all files
		if [ -d "$x" ]; then
			differential_backup "$x"
		# if we get a file, then add it to the tar archive (adding just the file and not the whole file structure)
		elif [ -f "$x" ]; then
			# we need to check if the file was modified after the previous backup was created
			mod_time=$(stat -c %Y "$x")
			# if the file was modified/created after complete backup, we raise the flag to indicate that differential backup is successful and add the file to tar archive
			if [ $mod_time -gt $complete_backup_time ]; then
				flag_differential=1
				(cd "$(dirname "$x")" && tar -rvf "${tar_path_differential_backup}${k}${ending}" "$(basename "$x")" 2>/dev/null 1>/dev/null)
			fi
		fi
	done
}

# helper function to run complete backup
run_complete_backup(){
	# create an empty tar archive for complete backup
	tar -cvf "${tar_path_complete_backup}${i}${ending}" --files-from /dev/null
	# call the function complete_backup with target path as argument to create complete backup
	complete_backup $HOME
	# store complete backup time
	complete_backup_time=$(date +%s)
	# append date and archive name in backup log
	echo "$(date "+%a %d %b %Y %I:%M:%S %p %Z")" "cbw24-${i}${ending}" "was created" >> backup.log
	# increment complete backup counter for next backup
 	((i++))
}

# helper function to run incremental backup
run_incremental_backup(){
	# create an empty tar archive for incremental backup
	tar -cvf "${tar_path_incremental_backup}${j}${ending}" --files-from /dev/null
	# call the function incremental_backup with target path as argument to create incremental backup
	incremental_backup $HOME
	# store incremental backup time
	incremental_backup_time=$(date +%s)
	# if incremental backup was successful, then append date and archive name in backup log
	if [ $flag_incremental -eq 1 ]; then
		echo "$(date "+%a %d %b %Y %I:%M:%S %p %Z")" "ib24-${j}${ending}" "was created" >> backup.log
		# increment incremental backup counter for next backup
 		((j++))
	# in case incremental backup is not created
	else
			# remove the empty archive
			rm "${tar_path_incremental_backup}${j}${ending}"
			# append date with appropriate message in backup log
			echo "$(date "+%a %d %b %Y %I:%M:%S %p %Z")" "No changes-Incremental backup was not created" >> backup.log
	fi		
}

# helper function to run differential backup
run_differential_backup(){
	# create an empty tar archive for differential backup
	tar -cvf "${tar_path_differential_backup}${k}${ending}" --files-from /dev/null
	# call the function differential_backup with target path as argument to create differential backup
	differential_backup $HOME
	# store differential backup time
	differential_backup_time=$(date +%s)
	# if differential backup was successful, then append date and archive name in backup log
	if [ $flag_differential -eq 1 ]; then
		echo "$(date "+%a %d %b %Y %I:%M:%S %p %Z")" "db24-${k}${ending}" "was created" >> backup.log
		# increment differential backup counter for next backup
 		((k++))
	# in case differential backup is not created
	else
			# remove the empty archive
			rm "${tar_path_differential_backup}${k}${ending}"
			# append date with appropriate message in backup log
			echo "$(date "+%a %d %b %Y %I:%M:%S %p %Z")" "No changes-Differential backup was not created" >> backup.log
	fi		
}

# continuous loop
while [ 1 ]
do
	# perform complete backup
	run_complete_backup
	# 2 minute interval
	sleep 120
	# change comparison time to complete backup time because we want next backup to refer to changes made in complete backup
	comparison_time=$complete_backup_time
	# perform incremental backup
	run_incremental_backup
	# 2 minute interval
	sleep 120
	# change comparison time to incremental backup time because we want next backup to refer to changes made in this incremental backup
	comparison_time=$incremental_backup_time
	# reset the incremental flag which might be raised during previous backups
	flag_incremental=0
	# perform incremental backup
	run_incremental_backup
	# 2 minute interval
	sleep 120
	# perform differential backup
	run_differential_backup
	# 2 minute interval
	sleep 120
	# change comparison time to differential backup time because we want next backup to refer to changes made in differential backup
	comparison_time=$differential_backup_time
	# reset the incremental flag which might be raised during previous backups
	flag_incremental=0
	# perform incremental backup
	run_incremental_backup
	# reset all flags for next iteration of backups
	flag_incremental=0
	flag_differential=0
done
