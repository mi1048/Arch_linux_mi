#!/bin/bash

# Verificação de privilégios
if [ "$(id -u)" -ne 0 ]; then
    echo "Este script deve ser executado como root!"
    exit 1
fi

echo "Bem-vindo ao instalador automatizado do Arch Linux!"

# Função para validação de opções
validate_option() {
    local input="$1"
    local options=("${!2}")
    for opt in "${options[@]}"; do
        if [ "$input" == "$opt" ]; then
            return 0
        fi
    done
    return 1
}

# Configuração de partições
echo "Antes de continuar, configure suas partições. Escolha uma ferramenta para gerenciar as partições:"
partition_tools=("fdisk" "parted")
PS3="Escolha uma opção (1-${#partition_tools[@]}): "
select partition_tool in "${partition_tools[@]}"; do
    if validate_option "$partition_tool" partition_tools[@]; then
        echo "Abrindo o $partition_tool..."
        read -p "Informe o disco (ex.: /dev/sda): " drive
        if [[ ! -b "$drive" ]]; then
            echo "Dispositivo inválido. Saindo."
            exit 1
        fi
        "$partition_tool" "$drive"
        break
    else
        echo "Opção inválida. Tente novamente."
    fi
done

# Montagem das partições
echo "Certifique-se de ter criado e formatado as partições."
read -p "Informe a partição raiz (ex.: /dev/sda1): " root_partition
if [[ ! -b "$root_partition" ]]; then
    echo "Partição raiz inválida. Saindo."
    exit 1
fi
mount "$root_partition" /mnt

read -p "Deseja configurar uma partição /boot separada? (s/n): " boot_choice
if [[ "$boot_choice" =~ ^[Ss]$ ]]; then
    read -p "Informe a partição /boot (ex.: /dev/sda2): " boot_partition
    if [[ -b "$boot_partition" ]]; then
        mkdir /mnt/boot
        mount "$boot_partition" /mnt/boot
    else
        echo "Partição /boot inválida. Ignorando configuração."
    fi
fi

read -p "Deseja configurar uma partição /home separada? (s/n): " home_choice
if [[ "$home_choice" =~ ^[Ss]$ ]]; then
    read -p "Informe a partição /home (ex.: /dev/sda3): " home_partition
    if [[ -b "$home_partition" ]]; then
        mkdir /mnt/home
        mount "$home_partition" /mnt/home
    else
        echo "Partição /home inválida. Ignorando configuração."
    fi
fi

# Configuração de swap (manter a configuração existente do exemplo anterior)

# Instalação do sistema base
echo "Instalando o sistema base..."
pacstrap /mnt base linux linux-firmware

# Gerar fstab
echo "Gerando fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# Entrando no ambiente chroot
echo "Entrando no ambiente chroot..."
arch-chroot /mnt /bin/bash <<EOF

# Configuração de rede
echo "Configurando rede. Escolha o gerenciador de rede:"
network_tools=("NetworkManager" "iwd (Wi-Fi apenas)" "Nenhum")
PS3="Escolha uma opção (1-${#network_tools[@]}): "
select network_tool in "\${network_tools[@]}"; do
    if validate_option "\$network_tool" network_tools[@]; then
        case \$REPLY in
            1)
                echo "Instalando NetworkManager..."
                pacman -S --noconfirm networkmanager
                systemctl enable NetworkManager
                ;;
            2)
                echo "Instalando iwd para Wi-Fi..."
                pacman -S --noconfirm iwd
                systemctl enable iwd
                ;;
            3)
                echo "Nenhum gerenciador de rede será configurado."
                ;;
        esac
        break
    else
        echo "Opção inválida. Tente novamente."
    fi
done

# Instalação de drivers proprietários
echo "Detectando drivers necessários..."
if lspci | grep -i 'nvidia'; then
    echo "NVIDIA detectada. Instalando drivers proprietários..."
    pacman -S --noconfirm nvidia nvidia-utils nvidia-settings
elif lspci | grep -i 'amd'; then
    echo "AMD detectada. Instalando drivers de vídeo..."
    pacman -S --noconfirm xf86-video-amdgpu
elif lspci | grep -i 'intel'; then
    echo "Intel detectada. Instalando drivers de vídeo..."
    pacman -S --noconfirm xf86-video-intel
else
    echo "Nenhuma placa gráfica dedicada detectada. Usando drivers padrão."
    pacman -S --noconfirm xf86-video-vesa
fi

# Instalação de ambiente gráfico (manter configuração existente do exemplo anterior)

EOF

# Finalização
echo "Instalação concluída! Reinicie o sistema para começar a usar seu Arch Linux."
