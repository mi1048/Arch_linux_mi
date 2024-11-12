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



If need any help you can go to archwiki
