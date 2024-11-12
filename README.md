## Arch_linux_mi

An bash script to install Arch Linux

## 1 - First download archlinux image

## 2 - After that you need to disable secure boot on your BIOS(don´t worry its just temporary)

## 3 - Connect ArchLinux to wifi(if you dont have a wired connection to your computer)

when you boot your machine it will show something like this

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

this command is gonna activate another command prompt that is specific to wifi


If need any help you can go to archwiki
