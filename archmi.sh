#!/bin/bash

# Verificação de privilégios
if [ "$(id -u)" -ne 0 ]; then
    echo "Este script deve ser executado como root!"
    exit 1
fi

echo "Bem-vindo ao instalador automatizado do Arch Linux!"

# Configuração de partições
echo "Antes de continuar, configure suas partições. Escolha uma ferramenta para gerenciar as partições:"
echo "1) fdisk"
echo "2) parted"
read -p "Escolha uma opção (1 ou 2): " partition_tool

case $partition_tool in
    1)
        echo "Abrindo o fdisk..."
        read -p "Informe o disco (ex.: /dev/sda): " drive
        fdisk "$drive"
        ;;
    2)
        echo "Abrindo o parted..."
        read -p "Informe o disco (ex.: /dev/sda): " drive
        parted "$drive"
        ;;
    *)
        echo "Opção inválida. Saindo do script."
        exit 1
        ;;
esac

# Montagem das partições
echo "Certifique-se de ter criado e formatado as partições."
read -p "Informe a partição raiz (ex.: /dev/sda1): " root_partition
mount "$root_partition" /mnt

read -p "Deseja configurar uma partição /boot separada? (s/n): " boot_choice
if [ "$boot_choice" == "s" ]; then
    read -p "Informe a partição /boot (ex.: /dev/sda2): " boot_partition
    mkdir /mnt/boot
    mount "$boot_partition" /mnt/boot
fi

read -p "Deseja configurar uma partição /home separada? (s/n): " home_choice
if [ "$home_choice" == "s" ]; then
    read -p "Informe a partição /home (ex.: /dev/sda3): " home_partition
    mkdir /mnt/home
    mount "$home_partition" /mnt/home
fi

# Configuração de swap
echo "Configuração de swap:"
echo "1) Usar uma partição de swap"
echo "2) Criar um arquivo de swap"
echo "3) Não configurar swap"
read -p "Escolha uma opção (1, 2 ou 3): " swap_option

case $swap_option in
    1)
        echo "Configuração de partição de swap."
        read -p "Informe a partição de swap (ex.: /dev/sdaX): " swap_partition
        mkswap "$swap_partition"
        swapon "$swap_partition"
        echo "$swap_partition none swap defaults 0 0" >> /mnt/etc/fstab
        ;;
    2)
        echo "Criando um arquivo de swap."
        read -p "Informe o tamanho do arquivo de swap em GB (ex.: 2): " swap_size
        fallocate -l "${swap_size}G" /mnt/swapfile
        chmod 600 /mnt/swapfile
        mkswap /mnt/swapfile
        swapon /mnt/swapfile
        echo "/swapfile none swap defaults 0 0" >> /mnt/etc/fstab
        ;;
    3)
        echo "Swap não será configurado."
        ;;
    *)
        echo "Opção inválida. Nenhuma configuração de swap será feita."
        ;;
esac

# Instalação do sistema base
echo "Instalando o sistema base..."
pacstrap /mnt base linux linux-firmware

# Gerar fstab
echo "Gerando fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# Entrando no ambiente chroot
echo "Entrando no ambiente chroot..."
arch-chroot /mnt /bin/bash <<EOF

# Configurações de sistema dentro do chroot

# Definir zona de tempo
echo "Configurando fuso horário..."
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc

# Configuração de localidade
echo "Configurando localidade..."
echo "pt_BR.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=pt_BR.UTF-8" > /etc/locale.conf

# Configuração do teclado
echo "Configurando layout do teclado..."
echo "KEYMAP=br-abnt2" > /etc/vconsole.conf

# Configuração do hostname
echo "Defina o nome do seu computador:"
read hostname
echo "$hostname" > /etc/hostname
cat << HOSTS > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   $hostname.localdomain $hostname
HOSTS

# Atualização e instalação de pacotes básicos
echo "Instalando pacotes básicos..."
pacman -Syu --noconfirm vim networkmanager grub

# Configuração de rede
echo "Habilitando o NetworkManager..."
systemctl enable NetworkManager

# Configuração de GRUB
echo "Instalando o GRUB..."
read -p "Informe o disco para instalar o GRUB (ex.: /dev/sda): " grub_drive
grub-install --target=i386-pc "$grub_drive"
grub-mkconfig -o /boot/grub/grub.cfg

# Configuração de usuário
echo "Criando usuário padrão..."
read -p "Digite o nome do usuário: " user
useradd -m -G wheel -s /bin/bash "$user"
echo "Defina a senha para o usuário $user:"
passwd "$user"

# Configurar senha do root
echo "Defina a senha do root:"
passwd

# Permitir sudo para o usuário
echo "Configurando sudo para o usuário..."
sed -i '/%wheel ALL=(ALL:ALL) ALL/s/^# //' /etc/sudoers

EOF

# Finalização
echo "Instalação concluída! Reinicie o sistema para começar a usar seu Arch Linux."
