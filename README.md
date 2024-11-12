## Arch_linux_mi

An bash script to install Arch Linux

## 1 - First download archlinux image

## 2 - After that you need to disable secure boot on your BIOS(don´t worry its just temporary)

## 3 - Connect ArchLinux to wifi(if you dont have a wired connection to your computer)

When you boot your machine it will show something like this

```bash
root@archiso ~ #
```

So to show your ip adress (you need the interface name of your wifi adapter)

```bash
root@archiso ~ # ip addr show
```

Setting up wifi

```bash
root@archiso ~ # iwctl
```

This command is gonna activate another command prompt that is specific to wifi it would look like this

```bash
[iwd]#
```

After that type this command

```bash
[iwd]# station nameofyourwifi get-networks
```

what this should do tell which wifi work on your area

Then you exit from this prompt

```bash
[iwd]# exit
```

Thereafter you should be back to archlinux prompt, so type

```bash
root@archiso ~ # iwctl --passphrase "yourwifipassphrase" station interfacename connect nameofwifinetwork
```

To test if this was sucessful do

```bash
root@archiso ~ # ip addr show
```

## 4 - SSH to make installation easier(optional)

In order for you to use SSH you have to enable it

```bash
root@archiso ~ # systemctl status sshd
```

if nothing come to do with the ssh server itself you can continue

```bash
root@archiso ~ # systemctl start sshd
```

that command it would make sure that ssh its listening for connections

As a result you will need to set a root password(by default ssh will not allow to connect with a root without password)

```bash
root@archiso ~ # passwd
```

note:This root password its just for the installer not the operating system

## 5 - Installing Arch via the archinstall method(Less complicated)

First start the arch linux installer

```bash
root@archiso ~ # archinstall
```

Now you just need to go each section one by one to configure your installation

1 - Archinstall language(installer language not the operating system language)

2 - Mirrors

A mirror its where our software come from

So select your region its closer to you

3 - Locales

Review the options

4 - Disk Configuration

So use the option("Use a best-effort default partition layout")

Next choose the hardware you want to install arch linux to

So choose the filesystem(I recommend ext4)

Subsequently it will ask if you want a separate partition for /home so choose yes

This will make sure that your own personal data are their own folder

5 - Disk encryption

Leave at it is

6 - Bootloader

Leave at it is

7 - Unified kernel images

Leave at it is

8 - Swap

Leave at it is

9 - Root Password 

Set your root password

10 - User Account

Create your own user account

11 - Profile

So choose what type of installation is this

After that choose the graphics driver(choose your gpu driver)

Next choose Greeter gdm

12 - Audio

Afterwards on audio choose Pipewire

13 - Kernels

Following that you need to choose the kernel on your system(I recommend 2 kernels)

14 - Additional packages

Leave at it is

15 - Network Configuration

Next choose Use NetworkManager

16 - Timezone

Consecutively find your desired Timezone

17 - Automatic time sync

It is import that this is enable if your gonna use sync utilities

18 - Optional repositories

Leave at it is

Finally you can go to the install option to install the arch linux

it will show the output of the settings you choosed if you want to automate in the future

you installed via archinstall

now youre ready to go

## 6 - Manual Method(More Complicated)


If need any help you can go to archwiki
