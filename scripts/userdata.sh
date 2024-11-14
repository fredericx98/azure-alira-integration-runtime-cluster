#!/bin/bash
# User Data script

# Actualizar los paquetes e instalar iptables-persistent
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y iptables-persistent

# Crear el archivo ip_fwd.sh en el directorio /root/ con el contenido especificado
cat << 'EOF' > /root/ip_fwd.sh
#!/bin/bash

#-------------------------------------------------------------------------

usage() {
    echo -e "\e[33m"
    echo "usage: ${0} [-i <eth_interface>] [-f <frontend_port>] [-a <dest_ip_addr>] [-b <dest_port>]" 1>&2
    echo -e "\e[0m"
}

while getopts 'i:f:a:b:' OPTS; do
    case "${OPTS}" in
        i) ETH_IF=${OPTARG} ;;
        f) FE_PORT=${OPTARG} ;;
        a) DEST_HOST=${OPTARG} ;;
        b) DEST_PORT=${OPTARG} ;;
        *) usage; exit 1 ;;
    esac
done

if [ -z ${ETH_IF} ] || [ -z ${FE_PORT} ] || [ -z ${DEST_HOST} ] || [ -z ${DEST_PORT} ]; then
    usage
    exit 1
fi

# Enable IP forwarding
echo "1" > /proc/sys/net/ipv4/ip_forward

# Get destination IP
if [[ ${DEST_HOST} =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    DEST_IP=${DEST_HOST}
else
    DEST_IP=$(host ${DEST_HOST} | grep "has address" | awk '{print $NF}')
fi

# Get local IP
LOCAL_IP=$(ip addr ls ${ETH_IF} | grep -w inet | awk '{print $2}' | awk -F/ '{print $1}')

# Add DNAT and SNAT rules
iptables -t nat -A PREROUTING -p tcp -i ${ETH_IF} --dport ${FE_PORT} -j DNAT --to ${DEST_IP}:${DEST_PORT}
iptables -t nat -A POSTROUTING -o ${ETH_IF} -j MASQUERADE
EOF

# Hacer ejecutable el archivo
chmod +x /root/ip_fwd.sh

# Ejecutar el script con los parámetros proporcionados
/root/ip_fwd.sh -i eth0 -f 5432 -a 172.30.35.17 -b 5432  ### development    - 172.30.35.0/26
/root/ip_fwd.sh -i eth0 -f 5433 -a 172.30.51.44 -b 5432  ### qa             - 172.30.51.0/2
/root/ip_fwd.sh -i eth0 -f 5434 -a 172.30.41.83 -b 5432  ### production     - 172.30.40.0/23

# Guardar las reglas de iptables de forma permanente
iptables-save > /etc/iptables/rules.v4

# Guardar las reglas en iptables-persistent
netfilter-persistent save
