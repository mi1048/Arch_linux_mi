#!/bin/bash
#
# Verificar privilégios de root
if [ "$(id -u)" -ne 0 ]; then
    echo "Este script deve ser executado como root!"
    exit 1
fi

# Solicitar o disco
read -p "Informe o disco para particionar automaticamente (ex.: /dev/sda): " drive
if [[ ! -b "$drive" ]]; then
    echo "Dispositivo inválido. Verifique o nome do disco."
    exit 1
fi

# Verificar se o disco possui partições antigas
echo "Verificando partições existentes no disco..."
fdisk -l "$drive" || { echo "Erro ao listar partições."; exit 1; }

# Limpar o disco e criar uma tabela GPT
echo "Limpar o disco e criar tabela GPT..."
wipefs -a "$drive" || { echo "Erro ao limpar o disco."; exit 1; }
parted "$drive" --script mklabel gpt || { echo "Erro ao criar tabela GPT."; exit 1; }

# Criar partições com sfdisk
echo "Criando partições no $drive..."
sfdisk "$drive" <<EOF || { echo "Erro ao criar partições."; exit 1; }
,300M,ef00
,2G,82
,,8300
EOF

# Mapear partições
if [[ "$drive" =~ "nvme" ]]; then
    part1="${drive}p1"   # Partição EFI
    part2="${drive}p2"   # Partição swap
    part3="${drive}p3"   # Partição Linux
else
    part1="${drive}1"
    part2="${drive}2"
    part3="${drive}3"
fi

# Verificar se as partições foram criadas corretamente
for part in "$part1" "$part2" "$part3"; do
    if [[ ! -b "$part" ]]; then
        echo "Partição $part não encontrada. Verifique o particionamento."
        exit 1
    fi
done

echo "Partições criadas com sucesso!"

# Formatar as partições
echo "Formatando as partições..."
mkfs.fat -F32 "$part1" || { echo "Erro ao formatar $part1."; exit 1; }  # Partição EFI (FAT32)
mkswap "$part2" || { echo "Erro ao formatar $part2."; exit 1; }         # Swap
mkfs.ext4 "$part3" || { echo "Erro ao formatar $part3."; exit 1; }       # Linux (ext4)

# Ativar swap
swapon "$part2" || { echo "Erro ao ativar swap."; exit 1; }

# Montar as partições
echo "Montando as partições..."
mount "$part3" /mnt || { echo "Erro ao montar $part3."; exit 1; }
mkdir -p /mnt/boot/efi || { echo "Erro ao criar diretório /mnt/boot/efi."; exit 1; }
mount "$part1" /mnt/boot/efi || { echo "Erro ao montar $part1."; exit 1; }

echo "Particionamento e montagem concluídos com sucesso!"


# Instalar o sistema base
echo "Instalando o sistema base..."
pacstrap /mnt base linux linux-firmware || { echo "Erro ao instalar o sistema base."; exit 1; }

# Gerar fstab
echo "Gerando o arquivo fstab..."
genfstab -U /mnt >> /mnt/etc/fstab || { echo "Erro ao gerar o fstab."; exit 1; }

# Instalar o GRUB (Bootloader) em sistemas UEFI
echo "Instalando o bootloader (GRUB)..."
pacstrap /mnt grub os-prober || { echo "Erro ao instalar o GRUB."; exit 1; }

# Instalar o GRUB no disco
echo "Instalando o GRUB no disco $drive..."
if [[ "$drive" =~ "nvme" ]]; then
    grub-install --target=x86_64-efi --efi-directory=/mnt/boot/efi --bootloader-id=grub --recheck || { echo "Erro ao instalar GRUB no disco $drive."; exit 1; }
else
    grub-install --target=i386-pc --recheck --bootloader-id=grub $drive || { echo "Erro ao instalar GRUB no disco $drive."; exit 1; }
fi

# Gerar a configuração do GRUB
echo "Gerando a configuração do GRUB..."
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg || { echo "Erro ao gerar a configuração do GRUB."; exit 1; }


# Entrar no ambiente chroot
echo "Entrando no ambiente chroot..."
arch-chroot /mnt /bin/bash <<EOF || { echo "Erro ao entrar no ambiente chroot."; exit 1; }

# Instalar e configurar NetworkManager
pacman -S --noconfirm networkmanager || { echo "Erro ao instalar NetworkManager."; exit 1; }
systemctl enable NetworkManager || { echo "Erro ao habilitar NetworkManager."; exit 1; }

# Instalação de drivers gráficos
echo "Detectando drivers necessários..."
if lspci | grep -i 'nvidia'; then
    pacman -S --noconfirm nvidia nvidia-utils nvidia-settings || { echo "Erro ao instalar drivers NVIDIA."; exit 1; }
elif lspci | grep -i 'amd'; then
    pacman -S --noconfirm xf86-video-amdgpu || { echo "Erro ao instalar drivers AMD."; exit 1; }
elif lspci | grep -i 'intel'; then
    pacman -S --noconfirm xf86-video-intel || { echo "Erro ao instalar drivers Intel."; exit 1; }
else
    pacman -S --noconfirm xf86-video-vesa || { echo "Erro ao instalar drivers genéricos."; exit 1; }
fi

EOF

echo "Instalação concluída! Reinicie o sistema para começar a usar seu Arch Linux."
