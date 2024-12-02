#!/bin/bash

# Verificação de privilégios
if [ "$(id -u)" -ne 0 ]; then
    echo "Este script deve ser executado como root!"
    exit 1
fi

echo "Bem-vindo ao instalador automatizado do Arch Linux!"

# Função para validação de entradas
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

# Particionamento automatizado
read -p "Informe o disco para particionar automaticamente (ex.: /dev/sda): " drive
if [[ ! -b "$drive" ]]; then
    echo "Dispositivo inválido. Saindo."
    exit 1
fi

echo "Iniciando particionamento automatizado no $drive..."

# Confirmar antes de apagar tudo
read -p "Isso irá apagar todos os dados no disco $drive. Deseja continuar? (s/n): " confirm
if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
    echo "Operação cancelada."
    exit 0
fi

# Comandos para criar partições automaticamente
fdisk "$drive" <<EOF
g       # Cria uma tabela de partição GPT
n       # Nova partição (raiz)
1       # Número da partição
        # Setor inicial (padrão)
+20G    # Tamanho da partição (20GB para raiz)
n       # Nova partição (swap)
2       # Número da partição
        # Setor inicial (padrão)
+2G     # Tamanho da partição (2GB para swap)
n       # Nova partição (home)
3       # Número da partição
        # Setor inicial (padrão)
        # Resto do disco
w       # Escreve as alterações no disco
EOF

echo "Partições criadas com sucesso!"

# Formatação das partições
echo "Formatando as partições..."
mkfs.ext4 "${drive}1"
mkswap "${drive}2"
mkfs.ext4 "${drive}3"

# Ativação da swap
swapon "${drive}2"

# Montagem das partições
echo "Montando as partições..."
mount "${drive}1" /mnt
mkdir /mnt/home
mount "${drive}3" /mnt/home

echo "Particionamento e montagem concluídos."

# Continuar com o restante do script
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

EOF

echo "Instalação concluída! Reinicie o sistema para começar a usar seu Arch Linux."
