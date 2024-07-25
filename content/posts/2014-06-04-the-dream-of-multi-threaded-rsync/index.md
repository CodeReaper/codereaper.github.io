---
title: The dream of multi-threaded rsync
date: 2014-06-04T00:00:00+02:00
draft: false
---

As a former maintainer of a rather large datastore I know the problems of maintaining a backup of your datastore.

The common approach is to use [rsync](http://en.wikipedia.org/wiki/Rsync) on a regular basis to keep your backup up to date. If you have a few millions files to keep backups of, then each rsync session will take much longer than when you only had a few thousand files.

Keeping the backup window as small as possible is key when you want to limit the loss of data when disaster strikes.

If you are like me, you will have found through trial and error that multiple rsync sessions each taking a specific ranges of files will complete much faster. Rsync is not multithreaded, but for the longest time I sure wished it was.

## An idea was born
I was reading about some shell programming somewhere online and found the missing tool I needed to make rsync "threaded". The missing tool was [wait](http://en.wikipedia.org/wiki/Wait_(command)) which waits for the current forked processes to complete.

The idea is to create a bunch of forked processes to act as threads for the backup process. There are a few prerequisites for the way I have chosen to implement what I dubbed `megasync`. They are:

- The primary server and backup server must be running a Linux or Unix system.
- A few commands and paths might need to be changed if your primary server is not running [FreeBSD](https://www.freebsd.org/).
- The user running `megasync` is set up with passwordless ssh access to the backup server.
- The files should be divided into many directories with a similiar amount of files in each.
- The directories containing the files must have a single shared parent directory.
- There should only be files in directories that are a certain deepth into the directory structure.

## Putting theory into action
The lazy reader may skip the theory and explainations and go direct to the [megasync.sh](megasync.sh.txt) file.

To put the theory into actually code I will make a few assumtions for the purposes of explaining:

- The data is located in a directory named `/data/` on both the primary and backup server.
- The data is divided using the following pattern `/data/​<department>​/<client id>​/<short hash>​/<short hash>/` for example.
- You feel that 6 thread is the right number for you.

Given the prerequisites and the assumtions the execution plan is as follows:

List every directory from `/data/` with a deepth of 4.
1. Divide the list into 6 equal parts.
1. Fork and wait for 6 processes that creates all the output directories on the backup server.
1. Fork and wait for 6 processes that rsync each of the directories to the backup server.

## Step 1 - listing
Use the find command with parameters defining a maxdepth of 4 and type of directories. This will give a list of directories, but it will include paths to directories that are just one, two and three levels in. We can fix this by using a regex grep. So the commands that will create the basis for `megasync` is:

```sh
depth=4
localpath=/data/
tmpdir=/tmp/rsync.$$

regex=""
for i in $(jot - 1 $depth); do
  regex="$regex[^/]*/"
done

find $localpath -maxdepth $depth -type d | grep "$regex" > $tmpdir/dirlist
```

This is why it is important that there should only be files in directories that are a certain deepth into the directory structure.

## Step 2 - dividing
Now that we have a list of the directory that needs to be backed up, we need to divide it into six equal parts. Naturally we create a convoluted while loop to make number named files with an extension of .dirlist.

```sh
rsyncs=6
tmpdir=/tmp/rsync.$$

total=$(wc -l $tmpdir/dirlist|cut -d\/ -f1|tr -d ' ')
n=$(expr $total / $rsyncs)

if [ "$total" = "0" ]; then
  echo "No directories to sync you dumbass.";
  exit 1;
fi

offset=$n
i=0
while true; do
  tail=$(expr $total + $n - $offset)
  if [ $tail -gt $n ]; then
    tail=$n
  fi
  head -n $offset $tmpdir/dirlist | tail -n $tail > $tmpdir/$i.dirlist
  c=$(wc -l $tmpdir/$i.dirlist|cut -d\/ -f1|tr -d ' ')
  if [ "$c" = "0" ]; then
    rm $tmpdir/$i.dirlist
    break
  elif [ $c -lt $n ]; then
    break
  fi
  i=$(expr $i + 1)
  offset=$(expr $offset + $n)
done
```

Yawn... Is the math over, yet? Good. Moving on.

## Step 3 & 4 - forking

Before we can backup using rsync this way, we need to ensure the destination directories exists on the backup server. Really it is simply a mkdir command for each directory, but let us do it threaded anyway. Forking a while loop making the actual directories from inside a for loop and then using the wait command to make sure all the directories are created before continueing. The wait command is just awesome.

```sh
rsyncs=6
tmpdir=/tmp/rsync.$$
userandhost=backup@backup.example.com
remotepath=/data/
rsyncopts="-a"

for i in $(jot - 1 $rsyncs); do
  while read r; do ssh $userandhost "mkdir -p $remotepath$r" ; done < $tmpdir/$i.dirlist &
done
wait
for i in $(jot - 1 $rsyncs); do
  while read r; do /usr/local/bin/rsync $rsyncopts $r $userandhost:$remotepath$r 2>&1 | tee $tmpdir/$i.dirlist.log ; done < $tmpdir/$i.dirlist &
done
wait
```

The actual rsync commands are forked in the same way as creating the directories, so I will spare you the same explaination twice.

## Usage

Grab your copy of [megasync.sh](megasync.sh.txt) now and place it somewhere handy.

You can use it like so:

```sh
#!/bin/sh
sh megasync.sh /data/ 4 6 "-a" backup@backup.example.com /data/
```

If, by chance, anything goes wrong, here is a kill script:

```sh
#!/bin/sh
ps auxww | grep megasync.sh | grep -v grep | awk '{print $2}' | xargs kill
killall rsync
```
