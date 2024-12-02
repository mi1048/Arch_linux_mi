#!/bin/bash

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

# Confirmar destruição de dados
read -p "Isso APAGARÁ TODOS os dados no disco $drive. Deseja continuar? (s/n): " confirm
if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
    echo "Operação cancelada."
    exit 0
fi

# Limpar o disco e criar tabela GPT
echo "Preparando o disco $drive..."
wipefs -a "$drive" # Apaga assinaturas antigas no disco
parted "$drive" --script mklabel gpt # Cria a tabela GPT

# Criar partições com sfdisk
echo "Criando partições no $drive..."
sfdisk "$drive" <<EOF
,30G,L
,2G,S
,,L
EOF

# Mapear partições
if [[ "$drive" =~ "nvme" ]]; then
    part1="${drive}p1"
    part2="${drive}p2"
    part3="${drive}p3"
else
    part1="${drive}1"
    part2="${drive}2"
    part3="${drive}3"
fi

# Verificar se as partições foram criadas corretamente
if [[ ! -b "$part1" || ! -b "$part2" || ! -b "$part3" ]]; then
    echo "Erro ao criar partições. Verifique o disco."
    exit 1
fi

# Formatar partições
echo "Formatando as partições..."
mkfs.ext4 "$part1" # Partição ROOT
mkswap "$part2"    # Partição SWAP
mkfs.ext4 "$part3" # Partição HOME

# Ativar SWAP
swapon "$part2"

# Montar partições
echo "Montando as partições..."
mount "$part1" /mnt
mkdir -p /mnt/home
mount "$part3" /mnt/home

echo "Particionamento e montagem concluídos com sucesso!"

# Instalar o sistema base
echo "Instalando o sistema base..."
pacstrap /mnt base linux linux-firmware

# Gerar fstab
echo "Gerando o arquivo fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

echo "Sistema base instalado e fstab gerado. Prossiga com a configuração."


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

EOF

echo "Instalação concluída! Reinicie o sistema para começar a usar seu Arch Linux."
