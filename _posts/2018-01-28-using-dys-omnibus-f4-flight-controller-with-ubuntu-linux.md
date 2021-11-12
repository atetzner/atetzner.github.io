---
title:  "Using DYS Omnibus F4 Flight Controller with Ubuntu Linux"
date:   2018-01-28 21:00:00 +0100
categories: Drone Linux
---

I recently built up a FPV quadcopter model with a DYS Omnibus F4 FC (see bottom of post for full part list). Since the first time, I had some strange problems connecting to the FC as I could not connect to the flight controller sporadically using Betaflight and I had to reconnect the FC to the computer. To make it worse, I could not connect to the FC at all, after I reinstalled my system (due to another problem). Fortunately I found the caus(es) for my problems.


## Problem 1: The modemmanager
My first problem after I reinstalled my system was, that I could not connect to the FC at all. Nevertheless, I knew it was possible since connecting to it with Betaflight worked beforehand. I had a look into the kernel log and saw, that the controller was correctly recognized, and a second later it rebooted in bootloader mode making it impossible to connect normally to it. The syslog contained a hint for the problem:

```
Jan 26 14:55:39 andreas-xmg kernel: [   22.500039] usb 3-2: new full-speed USB device number 6 using xhci_hcd
Jan 26 14:55:40 andreas-xmg kernel: [   22.641315] usb 3-2: New USB device found, idVendor=0483, idProduct=5740
Jan 26 14:55:40 andreas-xmg kernel: [   22.641318] usb 3-2: New USB device strings: Mfr=1, Product=2, SerialNumber=3
Jan 26 14:55:40 andreas-xmg kernel: [   22.641320] usb 3-2: Product: OmnibusF4
Jan 26 14:55:40 andreas-xmg kernel: [   22.641322] usb 3-2: Manufacturer: Betaflight
Jan 26 14:55:40 andreas-xmg kernel: [   22.641324] usb 3-2: SerialNumber: 
Jan 26 14:55:40 andreas-xmg mtp-probe: checking bus 3, device 6: "/sys/devices/pci0000:00/0000:00:14.0/usb3/3-2"
Jan 26 14:55:40 andreas-xmg mtp-probe: bus: 3, device: 6 was not an MTP device
Jan 26 14:55:40 andreas-xmg laptop-mode: enabled, not active
Jan 26 14:55:40 andreas-xmg systemd[1]: Started Session c1 of user andreas.
Jan 26 14:55:40 andreas-xmg kernel: [   22.802127] cdc_acm 3-2:1.0: ttyACM0: USB ACM device
Jan 26 14:55:40 andreas-xmg kernel: [   22.802362] usbcore: registered new interface driver cdc_acm
Jan 26 14:55:40 andreas-xmg kernel: [   22.802362] cdc_acm: USB Abstract Control Model driver for USB modems and ISDN adapters
Jan 26 14:55:42 andreas-xmg ModemManager[2487]: <warn>  (ttyACM0) could not open serial device (2)
Jan 26 14:55:42 andreas-xmg ModemManager[2487]: <warn>  [plugin manager] task 2,ttyACM0: error when checking support with plugin 'Nokia': '(tty/ttyACM0) failed to open port: Could not open serial device ttyACM0: No such file or directory'
Jan 26 14:55:42 andreas-xmg ModemManager[2487]: <warn>  (ttyACM0) could not open serial device (2)
Jan 26 14:55:42 andreas-xmg ModemManager[2487]: <warn>  [plugin manager] task 2,ttyACM0: error when checking support with plugin 'Iridium': '(tty/ttyACM0) failed to open port: Could not open serial device ttyACM0: No such file or directory'
Jan 26 14:55:42 andreas-xmg ModemManager[2487]: <warn>  (ttyACM0) could not open serial device (2)
Jan 26 14:55:42 andreas-xmg ModemManager[2487]: <warn>  [plugin manager] task 2,ttyACM0: error when checking support with plugin 'Via CBP7': '(tty/ttyACM0) failed to open port: Could not open serial device ttyACM0: No such file or directory'
Jan 26 14:55:42 andreas-xmg ModemManager[2487]: <warn>  (ttyACM0) could not open serial device (2)
Jan 26 14:55:42 andreas-xmg ModemManager[2487]: <warn>  [plugin manager] task 2,ttyACM0: error when checking support with plugin 'Generic': '(tty/ttyACM0) failed to open port: Could not open serial device ttyACM0: No such file or directory'
Jan 26 14:55:42 andreas-xmg ModemManager[2487]: <info>  Couldn't check support for device at '/sys/devices/pci0000:00/0000:00:14.0/usb3/3-2': not supported by any plugin
Jan 26 14:55:42 andreas-xmg ModemManager[2487]: <info>  (tty/ttyACM0): released by modem /sys/devices/pci0000:00/0000:00:14.0/usb3/3-2
Jan 26 14:55:42 andreas-xmg kernel: [   25.356323] usb 3-2: USB disconnect, device number 6
Jan 26 14:55:42 andreas-xmg kernel: [   25.356387] cdc_acm 3-2:1.0: failed to set dtr/rts
Jan 26 14:55:43 andreas-xmg kernel: [   25.656064] usb 3-2: new full-speed USB device number 7 using xhci_hcd
Jan 26 14:55:43 andreas-xmg mtp-probe: checking bus 3, device 7: "/sys/devices/pci0000:00/0000:00:14.0/usb3/3-2"
Jan 26 14:55:43 andreas-xmg kernel: [   25.800836] usb 3-2: New USB device found, idVendor=0483, idProduct=df11
Jan 26 14:55:43 andreas-xmg kernel: [   25.800838] usb 3-2: New USB device strings: Mfr=1, Product=2, SerialNumber=3
Jan 26 14:55:43 andreas-xmg kernel: [   25.800839] usb 3-2: Product: STM32  BOOTLOADER
Jan 26 14:55:43 andreas-xmg kernel: [   25.800840] usb 3-2: Manufacturer: STMicroelectronics
Jan 26 14:55:43 andreas-xmg kernel: [   25.800841] usb 3-2: SerialNumber:
```

As you can see, the modemmanger tried to use the FC as a modem and whatever modemmanger sent to the controller, it caused it to reboot in bootloader / DFU mode. Uninstalling modemmanger helped me, so that the FC did not reboot to bootloader and I could generally connect to the FC in Betaflight.

## Problem 2: mtp-probe
Nevertheless I had the problem, that I could sporadically not connect to the FC. To be more precise, in four of five connects of the FC, the connection the FC in Betaflight failed. The solution for this was also in the logs above: As you can see, directly after connecting the FC, mtp-probe tries to find out if the device can be used with MTP – which causes the flight controller to get in some state, that Betaflight can not connect to it.

This can be solved by telling libmtp to ignore the FC for mtp probing. For this, extend the udev configuration and copy `/lib/udev/rules.d/69-libmtp.rules` to `/etc/udev/rules.d/69-libmtp.rules`. When you open this file, you will find some lines at the beginning of the file, that will cause libmtp to ignore a device `(GOTO="libmtp_rules_end")`. You simply need to add such a line for you flight controller with the correct vendor- and device-id. For this, simply execute `tail -f /var/log/kern.log`, connect your FC to your computer and wait for the kernel to recognize it. With the information from the log, add a line to `/etc/udev/rules.d/69-libmtp.rules` – in my case:

```
ATTR{idVendor}=="0483", ATTR{idProduct}=="5740", GOTO="libmtp_rules_end"
```

## Part list of my quadcopter model
DYS Omnibus F4 FC
DYS Aria BLHeli_32bit 35A ESCs (3-6S, DShot 1200)
BrotherHobby Returner R5 2306 2450kv (4-5S)
RunCam Eagle 2
Tramp HV Vtx
Martian_S frame
