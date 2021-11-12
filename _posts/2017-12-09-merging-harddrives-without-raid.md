---
title:  "Merging hard drives without RAID?"
date:   2017-12-09 21:00:00 +0100
categories: IT Linux
---

Some time ago, I noticed that the harddisk of my home server filled up more and more and I needed to add some more space. As this server is made to be as energy-efficient as possible, I don’t use a RAID which I can extend easily. Additionally I don’t like some facts about RAID, e.g. that I can not pull out a single drive and read the data on it on another machine – or that you need to e.g. add four drives to fulfill the requirements for your RAID level. But how can I "merge" multiple drives without a RAID transparently and without much effort?

## Requirements
What I was looking for:
* Beeing able to add disks very easy. Adding disks of different sizes must be possible.
* No "RAID overhead".
* Every disk should be some kind of independent: No distribution of a single file over multiple disks. If I plug in a disk from my array to another computer, I want to be able to read all files on this disk.
* Automatic distribution of writes to the disks. If a disk is full, further writes should go to the other disks.

So effectively, I want to be able to plug in a new disk, format it with any filesystem I like, and add it to my array. The resulting "merged" view should just let me read/write any file on any disk.

You might think: "Hey, these are very special requirements? Is this useful?" But in my case, I think it is useful. Before upgrading the server, it had just one drive with about 2TB (Western Digital Red series – IMHO perfect for 24/7 home servers or NASand very reliable). As I already said, I don’t use a RAID for energy efficiency. I am doing regular backups on an external drive, which gives me the necessary security in case of a hardware failure, that I need. At the moment of writing this, the drive has 40674 power-on hours, which are 4.6 years! Therefore, I must expect it to fail in the near futur – but until then, I don’t want to exchange it but instead still use it. Therefore I just want to add some more space to keep the whole server running, by adding a new drive.

## Things I tried ...
After some googling, I found some merging file systems like aufs; but unfortunately most of them can’t handle writes in the way that I needed it. Imagine the following scenario: A file is located on a disk, that is nearly full. If you write to this file and append more data, than the disk the file is located on can hold, the write will fail. This is of course not the kind of transparency that I was looking for. I needed a file system, that abstracts such kind of issues from the application that is writing the file, and automatically moves the file to another disk of my array, that can hold the whole big file.

After some more googling 😉 I stumbled across [mhddfs](http://svn.uvw.ru/mhddfs/trunk/README) (I think there is no official website?), which seems to do exactly what I wanted. So I installed it and gave it a try. My setup is currently a 2TB plus a 4TB drive. mhddfs simply merged the contents of the drives; writing to this "merged view" is also possible with a transparent move of files from one drive to another, in case one drive gets full.

Hey, everything is fine and exactly what I wanted 🙂

The solution
 

But after some time using it, I noticed that not "everything was fine". Occasionally and without a real reason, mhddfs crashed which leaves the server in a pretty ugly state: Reading or writing to it was not possible. But more worse: A re-mount was also not possible as even `umount -f` didn’t succeed. So the only way was to reboot the server 🙁

I searched for an alternative to mhddfs and came across [mergerfs](https://github.com/trapexit/mergerfs). This filesystem seems to have the exact same functionality, that I needed, and has even more in case I want to tweak it some day (mergerfs is very well documented!). Additionally, this filesystem is under current development – in contrast to mhddfs.

Merging from mhddfs to mergerfs was pretty easy in my case: Editing the `/etc/fstab`

```
# Old:
mhddfs#/mnt/disk1,/mnt/disk2 /mnt/disks fuse defaults,allow_other 0 0
# New:
/mnt/disk1:/mnt/disk2 /mnt/disks fuse.mergerfs defaults,allow_other,dropcacheonclose=true,use_ino,category.create=ff,moveonenospc=true,minfreespace=20G,fsname=mergerfsPool 0 0
```

Please note, that the mergerfs version 2.21.0-1 from the Ubuntu artful repositories does have a bug. If you try the following example with this version, mergerfs will crash at the point, when a move from one drive to another is required. You have to download a newer version from the [github download page](https://github.com/trapexit/mergerfs/releases) and install it (in my case 2.23.1~ubuntu-xenial).

Example
This is a complete example for the "transparent move feature" of mergerfs:

```
# Create some file systems with limited space and merge them with mergerfs
andreas{2007}$> mkdir -p mnt1 mnt2 merged
andreas{2008}$> sudo mount -t tmpfs -o size=10M none mnt1
andreas{2009}$> sudo mount -t tmpfs -o size=100M none mnt2
andreas{2010}$> sudo mergerfs -o defaults,allow_other,minfreespace=1M,moveonenospc=true $PWD/mnt1:$PWD/mnt2 merged/

# Create some files in the filesystem - for simplicity of this example directly in the underlying filesystems
andreas{2011}$> dd if=/dev/zero of=mnt1/output1.dat bs=1M count=5
andreas{2012}$> dd if=/dev/zero of=mnt1/output2.dat bs=1M count=2

# Resulting view
andreas{2013}$> ls -l *
merged:
total 7168
-rw-rw-r-- 1 andreas andreas 5242880 Dec  9 10:06 output1.dat
-rw-rw-r-- 1 andreas andreas 2097152 Dec  9 10:06 output2.dat
mnt1:
total 7168
-rw-rw-r-- 1 andreas andreas 5242880 Dec  9 10:06 output1.dat
-rw-rw-r-- 1 andreas andreas 2097152 Dec  9 10:06 output2.dat
mnt2:
total 0

# Write again to output2.dat but now use mergerfs
andreas{2014}$> dd if=/dev/zero of=merged/output2.dat bs=1M count=5

# As you can see, the file is still in mnt1 but got bigger
andreas{2015}$> ls -l *
merged:
total 10240
-rw-rw-r-- 1 andreas andreas 5242880 Dec  9 10:06 output1.dat
-rw-rw-r-- 1 andreas andreas 5242880 Dec  9 10:07 output2.dat
mnt1:
total 10240
-rw-rw-r-- 1 andreas andreas 5242880 Dec  9 10:06 output1.dat
-rw-rw-r-- 1 andreas andreas 5242880 Dec  9 10:07 output2.dat
mnt2:
total 0

# mnt1 is now completely full
andreas{2016}$> df -h
Filesystem      Size    Used Avail  Use% Mounted on
none            100M       0  100M    0% /home/andreas/test/mnt2
none             10M     10M     0  100% /home/andreas/test/mnt1
1:2             110M     10M  100M   10% /home/andreas/test/merged

# Write again to output2.dat using mergerfs - and write more data than mnt1 can hold
andreas{2017}$> dd if=/dev/zero of=merged/output2.dat bs=1M count=7
7+0 records in
7+0 records out
7340032 bytes (7.3 MB, 7.0 MiB) copied, 0.0146047 s, 503 MB/s

# Result: mergerfs transparently moved outpu2.dat to mnt2. dd didn't notice this move in any way
andreas{2018}$> ls -l *
merged:
total 12288
-rw-rw-r-- 1 andreas andreas 5242880 Dec  9 10:06 output1.dat
-rw-rw-r-- 1 andreas andreas 7340032 Dec  9 10:07 output2.dat
mnt1:
total 5120
-rw-rw-r-- 1 andreas andreas 5242880 Dec  9 10:06 output1.dat
mnt2:
total 7168
-rw-rw-r-- 1 andreas andreas 7340032 Dec  9 10:07 output2.dat
andreas{2019}$> df -h
Filesystem    Size  Used Avail Use% Mounted on
none          100M  7.0M   93M   7% /home/andreas/test/mnt2
none           10M  5.0M  5.0M  50% /home/andreas/test/mnt1
1:2           110M   12M   98M  11% /home/andreas/test/merged
``` 

## Further enhancement
If you need RAID-functionality (e.g. easy disaster recovery), without some of the drawbacks of RAID 🙂 , you potentially could give SnapRAID a try. I read about it in [other blogs](https://zackreed.me/mergerfs-another-good-option-to-pool-your-snapraid-disks/) while searching for mergerfs, but didn’t got into it.