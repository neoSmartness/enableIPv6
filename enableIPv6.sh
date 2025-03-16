#!/bin/bash

declare -A lang_en lang_es lang_fr lang_it lang_zh

lang_en=(
    [NO_ROOT]="Please run this script as root or with sudo."
    [INSTALLING]="Installing"
    [IPV6_ENABLED]="IPv6 is already enabled. Skipping configuration..."
    [KERNEL_CONFIG]="Enabling IPv6 in kernel..."
    [UNSUPPORTED_DISTRO]="Unsupported distribution. Attempting generic configuration..."
    [NETPLAN_INSTALL]="Installing netplan..."
    [NM_INSTALL]="Installing NetworkManager..."
    [NS_INSTALL]="Installing network-scripts..."
    [IPV6_SUCCESS]="IPv6 successfully enabled. IPv6 address(es):"
    [IPV6_WARNING]="Warning: IPv6 not fully activated.\nManual reboot might be required."
    [RETRY_MSG]="Attempt %d: Waiting for IPv6 configuration..."
    [PKG_MANAGER_ERROR]="Package manager not recognized!"
    [NETPLAN_ERROR]="Failed to apply network configuration"
    [MISSING_DEPS]="Missing critical dependencies after installation attempt"
)

lang_es=(
    [NO_ROOT]="Ejecute este script como root o con sudo."
    [INSTALLING]="Instalando"
    [IPV6_ENABLED]="IPv6 ya está habilitado. Saltando configuración..."
    [KERNEL_CONFIG]="Habilitando IPv6 en el kernel..."
    [UNSUPPORTED_DISTRO]="Distribución no soportada. Intentando configuración genérica..."
    [NETPLAN_INSTALL]="Instalando netplan..."
    [NM_INSTALL]="Instalando NetworkManager..."
    [NS_INSTALL]="Instalando network-scripts..."
    [IPV6_SUCCESS]="IPv6 habilitado correctamente. Dirección(es) IPv6:"
    [IPV6_WARNING]="Advertencia: IPv6 no se ha activado completamente.\nPuede ser necesario reiniciar manualmente."
    [RETRY_MSG]="Intento %d: Esperando configuración IPv6..."
    [PKG_MANAGER_ERROR]="Gestor de paquetes no reconocido!"
    [NETPLAN_ERROR]="Error al aplicar configuración de red"
    [MISSING_DEPS]="Faltan dependencias críticas después del intento de instalación"
)

lang_fr=(
    [NO_ROOT]="Veuillez exécuter ce script en tant que root ou avec sudo."
    [INSTALLING]="Installation de"
    [IPV6_ENABLED]="IPv6 est déjà activé. Configuration ignorée..."
    [KERNEL_CONFIG]="Activation d'IPv6 dans le kernel..."
    [UNSUPPORTED_DISTRO]="Distribution non prise en charge. Tentative de configuration générique..."
    [NETPLAN_INSTALL]="Installation de netplan..."
    [NM_INSTALL]="Installation de NetworkManager..."
    [NS_INSTALL]="Installation de network-scripts..."
    [IPV6_SUCCESS]="IPv6 activé avec succès. Adresse(s) IPv6 :"
    [IPV6_WARNING]="Avertissement : IPv6 n'est pas entièrement activé.\nUn redémarrage manuel pourrait être nécessaire."
    [RETRY_MSG]="Tentative %d : Attente de configuration IPv6..."
    [PKG_MANAGER_ERROR]="Gestionnaire de paquets non reconnu !"
    [NETPLAN_ERROR]="Échec de l'application de la configuration réseau"
    [MISSING_DEPS]="Dépendances critiques manquantes après tentative d'installation"
)

lang_it=(
    [NO_ROOT]="Esegui questo script come root o con sudo."
    [INSTALLING]="Installazione di"
    [IPV6_ENABLED]="IPv6 è già abilitato. Configurazione saltata..."
    [KERNEL_CONFIG]="Abilitazione IPv6 nel kernel..."
    [UNSUPPORTED_DISTRO]="Distribuzione non supportata. Tentativo di configurazione generica..."
    [NETPLAN_INSTALL]="Installazione di netplan..."
    [NM_INSTALL]="Installazione di NetworkManager..."
    [NS_INSTALL]="Installazione di network-scripts..."
    [IPV6_SUCCESS]="IPv6 abilitato correttamente. Indirizzo(i) IPv6:"
    [IPV6_WARNING]="Avviso: IPv6 non completamente attivato.\nPotrebbe essere necessario il riavvio manuale."
    [RETRY_MSG]="Tentativo %d: Attesa configurazione IPv6..."
    [PKG_MANAGER_ERROR]="Gestore di pacchetti non riconosciuto!"
    [NETPLAN_ERROR]="Errore durante l'applicazione della configurazione di rete"
    [MISSING_DEPS]="Dipendenze critiche mancanti dopo il tentativo di installazione"
)

lang_zh=(
    [NO_ROOT]="请以 root 用户或使用 sudo 运行此脚本。"
    [INSTALLING]="正在安装"
    [IPV6_ENABLED]="IPv6 已启用。跳过配置..."
    [KERNEL_CONFIG]="在内核中启用 IPv6..."
    [UNSUPPORTED_DISTRO]="不支持的分发版。尝试通用配置..."
    [NETPLAN_INSTALL]="正在安装 netplan..."
    [NM_INSTALL]="正在安装 NetworkManager..."
    [NS_INSTALL]="正在安装 network-scripts..."
    [IPV6_SUCCESS]="已成功启用 IPv6。IPv6 地址："
    [IPV6_WARNING]="警告：IPv6 未完全激活。\n可能需要手动重启。"
    [RETRY_MSG]="尝试 %d：等待 IPv6 配置..."
    [PKG_MANAGER_ERROR]="无法识别软件包管理器!"
    [NETPLAN_ERROR]="应用网络配置失败"
    [MISSING_DEPS]="尝试安装后仍缺少关键依赖项"
)

LANG="en"
while [[ $# -gt 0 ]]; do
    case $1 in
        -l|--lang) LANG="$2"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

case $LANG in
    en) declare -n MSG=lang_en ;;
    es) declare -n MSG=lang_es ;;
    fr) declare -n MSG=lang_fr ;;
    it) declare -n MSG=lang_it ;;
    zh) declare -n MSG=lang_zh ;;
    *) echo "Unsupported language. Using English."; declare -n MSG=lang_en ;;
esac

if [ "$(id -u)" -ne 0 ]; then
    echo "${MSG[NO_ROOT]}" >&2
    exit 1
fi

install_packages() {
    local status=0
    echo "${MSG[INSTALLING]} $*..."
    
    if command -v apt &>/dev/null; then
        apt update -qq && apt install -y "$@" || status=$?
    elif command -v dnf &>/dev/null; then
        dnf install -y "$@" || status=$?
    elif command -v yum &>/dev/null; then
        yum install -y "$@" || status=$?
    else
        echo "${MSG[PKG_MANAGER_ERROR]}" >&2
        exit 1
    fi
    
    if [ $status -ne 0 ]; then
        echo "${MSG[MISSING_DEPS]}" >&2
        exit 1
    fi
}

check_ipv6() {
    ip -6 addr show | grep -q 'inet6.*global'
}

if check_ipv6; then
    echo "${MSG[IPV6_ENABLED]}"
    exit 0
fi

command -v ip &>/dev/null || install_packages iproute2
command -v awk &>/dev/null || install_packages gawk

if [ -f /etc/os-release ]; then
    source /etc/os-release
    DISTRO="${ID}"
else
    DISTRO=$(uname -s)
fi

case $DISTRO in
    debian|ubuntu)
        [ ! -d /etc/netplan ] && [ ! -f /etc/network/interfaces ] && install_packages netplan.io
        ;;
    centos|rhel)
        if ! { [ -d /etc/sysconfig/network-scripts ] || rpm -q NetworkManager &>/dev/null; }; then
            if [[ $(rpm -E %{rhel}) -ge 8 ]]; then
                install_packages NetworkManager
            else
                install_packages network-scripts
            fi
        fi
        ;;
    fedora)
        rpm -q NetworkManager &>/dev/null || install_packages NetworkManager
        ;;
esac

sed -i '/disable_ipv6/d' /etc/sysctl.conf
echo -e "net.ipv6.conf.all.disable_ipv6 = 0\nnet.ipv6.conf.default.disable_ipv6 = 0" >> /etc/sysctl.conf
sysctl -p >/dev/null

case $DISTRO in
    debian|ubuntu)
        if [ -d /etc/netplan ]; then
            CONFIG_FILE=$(find /etc/netplan -maxdepth 1 -name '*.yaml' -print -quit)
            [ -z "$CONFIG_FILE" ] && { echo "${MSG[NETPLAN_ERROR]}" >&2; exit 1; }
            
            awk -i inplace '
                /ethernets:/ {
                    print $0
                    print "        dhcp6: true"
                    print "        accept-ra: true"
                    next
                }
                { print }
            ' "$CONFIG_FILE"
            
            if ! netplan apply; then
                echo "${MSG[NETPLAN_ERROR]}" >&2
                exit 1
            fi
        else
            INTERFACE=$(ip route | awk '/default/{print $5; exit}')
            sed -i '/iface.*inet6/d' /etc/network/interfaces
            echo "iface $INTERFACE inet6 auto" >> /etc/network/interfaces
            systemctl restart networking
        fi
        ;;
    centos|rhel|fedora|almalinux|rocky)
        INTERFACE=$(ip route | awk '/default/{print $5; exit}')
        CFG_FILE="/etc/sysconfig/network-scripts/ifcfg-$INTERFACE"
        [ -f "$CFG_FILE" ] || { echo "${MSG[NETPLAN_ERROR]}" >&2; exit 1; }
        
        sed -i '/IPV6INIT/d' "$CFG_FILE"
        echo "IPV6INIT=yes" >> "$CFG_FILE"
        systemctl restart NetworkManager
        ;;
    *)
        echo "${MSG[UNSUPPORTED_DISTRO]}" >&2
        ;;
esac

for ((i=1; i<=3; i++)); do
    if check_ipv6; then
        echo -e "\n${MSG[IPV6_SUCCESS]}"
        ip -6 addr show | awk '/inet6 .* global/{print $2}' | cut -d'/' -f1
        exit 0
    fi
    printf "${MSG[RETRY_MSG]}\n" "$i"
    sleep 5
done

echo -e "\n${MSG[IPV6_WARNING]}" >&2
ip -6 addr show >&2
exit 1