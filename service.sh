#!/usr/bin/env bash
### BEGIN INIT INFO
# Provides:          aria2 is a lightweight multi-protocol & multi-source command-line download utility.
# Required-Start:    $network $local_fs $remote_fs
# Required-Stop:     $network $local_fs $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: aria2 is a lightweight multi-protocol & multi-source command-line download utility.
# Description:       Start or stop the Aria2
### END INIT INFO

NAME="Aria2"
NAME_BIN="aria2c"
CONFIG_DIR="/home/steamdeck/aria2.conf"
CONFIG="${CONFIG_DIR}/aria2.conf"
LOG="${CONFIG_DIR}/aria2.log"

Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Green_background_prefix="\033[42;37m"
Red_background_prefix="\033[41;37m"
Font_color_suffix="\033[0m"
Info="[${Green_font_prefix}信息${Font_color_suffix}]"
Error="[${Red_font_prefix}错误${Font_color_suffix}]"
RETVAL=0

check_running() {
	PID=$(ps -ef | grep "${NAME_BIN}" | grep -v "grep" | grep -v "aria2.sh" | grep -v "init.d" | grep -v "service" | awk '{print $2}')
	if [[ ! -z ${PID} ]]; then
		return 0
	else
		return 1
	fi
}
Read_config() {
	[[ ! -e ${CONFIG} ]] && echo -e "${Error} ${NAME} 配置文件不存在 !" && exit 1
	Download_dir=$(cat ${CONFIG} | grep -v '#' | grep "dir=")
	[[ ! -z "${Download_dir}" ]] && Download_dir=$(echo "${Download_dir}" | awk -F '=' '{print $2}')
	RPC_listen_port=$(cat ${CONFIG} | grep -v '#' | grep "rpc-listen-port=")
	[[ ! -z "${RPC_listen_port}" ]] && RPC_listen_port=$(echo "${RPC_listen_port}" | awk -F '=' '{print $2}')
	RPC_secret=$(cat ${CONFIG} | grep -v '#' | grep "rpc-secret=")
	[[ ! -z "${RPC_secret}" ]] && RPC_secret=$(echo "${RPC_secret}" | awk -F '=' '{print $2}')
}
View_Config() {
	Read_config
    IPV4=$(
        wget -qO- -t1 -T2 -4 api.ip.sb/ip ||
            wget -qO- -t1 -T2 -4 ifconfig.io/ip ||
            wget -qO- -t1 -T2 -4 www.trackip.net/ip
    )
    IPV6=$(
        wget -qO- -t1 -T2 -6 api.ip.sb/ip ||
            wget -qO- -t1 -T2 -6 ifconfig.io/ip ||
            wget -qO- -t1 -T2 -6 www.trackip.net/ip
    )
	[[ -z "${IPV4}" ]] && IPV4="IPv4 地址检测失败"
	[[ -z "${IPV6}" ]] && IPV6="IPv6 地址检测失败"
	[[ -z "${Download_dir}" ]] && Download_dir="找不到配置参数"
	[[ -z "${RPC_listen_port}" ]] && RPC_listen_port="找不到配置参数"
	[[ -z "${RPC_secret}" ]] && RPC_secret="找不到配置参数(或无密钥)"
    if [[ -z "${IPV4}" || -z "${RPC_listen_port}" ]]; then
        AriaNg_URL="null"
    else
        AriaNg_API="/#!/settings/rpc/set/ws/${IPV4}/${RPC_listen_port}/jsonrpc/$(echo -n ${RPC_secret} | base64)"
        AriaNg_URL="http://ariang.js.org${AriaNg_API}"
    fi
	clear
	echo -e "\nAria2 简单配置信息：\n
 IPv4 地址\t: ${Green_font_prefix}${IPV4}${Font_color_suffix}
 IPv6 地址\t: ${Green_font_prefix}${IPV6}${Font_color_suffix}
 RPC 端口\t: ${Green_font_prefix}${RPC_listen_port}${Font_color_suffix}
 RPC 密钥\t: ${Green_font_prefix}${RPC_secret}${Font_color_suffix}
 下载目录\t: ${Green_font_prefix}${Download_dir}${Font_color_suffix}
 AriaNg 链接\t: ${Green_font_prefix}${AriaNg_URL}${Font_color_suffix}\n"
}
do_start() {
	check_running
	if [[ $? -eq 0 ]]; then
		echo -e "${Info} $NAME (PID ${PID}) 正在运行..." && exit 0
	else
		echo -e "${Info} $NAME 启动中..."
		ulimit -n 51200
		nohup /usr/sbin/aria2c --conf-path="${CONFIG}" >>"${LOG}" 2>&1 &
		sleep 2s
		check_running
		if [[ $? -eq 0 ]]; then
			View_Config
			echo -e "${Info} $NAME 启动成功 !"
		else
			echo -e "${Error} $NAME 启动失败 !"
		fi
	fi
}
do_stop() {
	check_running
	if [[ $? -eq 0 ]]; then
		kill -9 ${PID}
		RETVAL=$?
		if [[ $RETVAL -eq 0 ]]; then
			echo -e "${Info} $NAME 停止成功 !"
		else
			echo -e "${Error} $NAME 停止失败 !"
		fi
	else
		echo -e "${Info} $NAME 未运行"
		RETVAL=1
	fi
}
do_status() {
	check_running
	if [[ $? -eq 0 ]]; then
		View_Config
		echo -e "${Info} $NAME (PID $(echo ${PID})) 正在运行..."
	else
		echo -e "${Info} $NAME 未运行 !"
		RETVAL=1
	fi
}
do_restart() {
	do_stop
	do_start
}
case "$1" in
start | stop | restart | status)
	do_$1
	;;
*)
	echo "使用方法: $0 { start | stop | restart | status }"
	RETVAL=1
	;;
esac
exit $RETVAL