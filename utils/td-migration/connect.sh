#!/bin/bash
set -e

TYPE="local"
DEST_IP=""
TCP_PORT=9009
VSOCK_PORT_A=1235
VSOCK_PORT_B=1234

usage() {
    cat << EOM
Usage: $(basename "$0") [OPTION]...
  -i <dest ip>              Destination platform ip address
  -t <local|remote>         Use single or cross host live migration
  -p <tcp port>             TCP port
  -a <vsock port A>         VSOCK port A
  -b <vsock port B>         VSOCK port B
  -h                        Show this help
EOM
}

process_args() {
    while getopts "i:t:p:a:b:h" option; do
        case "${option}" in
            i) DEST_IP=$OPTARG;;
            t) TYPE=$OPTARG;;
            p) TCP_PORT=$OPTARG;;
            a) VSOCK_PORT_A=$OPTARG;;
            b) VSOCK_PORT_B=$OPTARG;;
            h) usage
               exit 0
               ;;
            *)
               echo "Invalid option '-$OPTARG'"
               usage
               exit 1
               ;;
        esac
    done

    case ${TYPE} in
        "local");;
        "remote")
            if [[ -z ${DEST_IP} ]]; then
                error "Please use -i specify DEST_IP in remote type"
            fi
            ;;
        *)
            error "Invalid ${TYPE}, must be [local|remote]"
            ;;
    esac
}

error() {
    echo -e "\e[1;31mERROR: $*\e[0;0m"
    exit 1
}

connect() {
    modprobe vhost_vsock
    if [[ ${TYPE} == "local" ]]; then
        socat TCP4-LISTEN:${TCP_PORT},reuseaddr VSOCK-LISTEN:${VSOCK_PORT_A},fork &
        sleep 3
        socat TCP4-CONNECT:127.0.0.1:${TCP_PORT},reuseaddr VSOCK-LISTEN:${VSOCK_PORT_B},fork &
    else
        ssh root@"${DEST_IP}" -o ConnectTimeout=30 "modprobe vhost_vsock; nohup socat TCP4-LISTEN:${TCP_PORT},reuseaddr VSOCK-LISTEN:${VSOCK_PORT_A},fork > foo.out 2> foo.err < /dev/null &"
        sleep 3
        socat TCP4-CONNECT:"${DEST_IP}":${TCP_PORT},reuseaddr VSOCK-LISTEN:${VSOCK_PORT_B},fork &
    fi
}

process_args "$@"
connect
