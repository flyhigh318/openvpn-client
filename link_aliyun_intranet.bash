#!/bin/bash
# Author: Abner.W
# function: it can start openvpn and link aliyun net.

set -e

log='/tmp/link_aliyun_openvpn_data.log'

function exportPath() {

    export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin

}


function getPid() {

    pid_file='/home/devops/pid/link_aliyun_openvpn_pid'

    
    pid_jiekuan_file='/home/devops/pid/aliyun_openvpn_jiekuan_pid'

    ps -ef | grep -i dfxk_tt_jiekuan.ovpn | grep -v grep >/dev/null
    if [ $? -eq 0 ]
    then

        if [  -f $pid_jiekuan_file ]
        then
            ps -ef | grep -i dfxk_tt_jiekuan.ovpn | grep -v grep | awk '{print $2}' > $pid_jiekuan_file
        fi

        echo  `date +"%F %T"` link_aliyun_openvpn_jiekuan process is running...
        exit 1

    fi


    
    pid_qiandai_file='/home/devops/pid/aliyun_openvpn_qiandai_pid' 

    ps -ef | grep -i dfxk_tt_qiandai.ovpn | grep -v grep >/dev/null
    if [ $? -eq 0 ]
    then

        if [ -f $pid_qiandai_file ]
        then
            ps -ef | grep -i dfxk_tt_qiandai.ovpn | grep -v grep | awk '{print $2}' > $pid_qiandai_file
        fi

        echo  `date +"%F %T"` link_aliyun_openvpn_qiandai process is running...
        exit 2

    fi




    if [ -f $pid_file ]
    then

        echo `date +"%F %T"` link_aliyun_openvpn process is running... >> $log
        exit 1

    else
        
        echo $$ >> $pid_file
        echo `date +"%F %T"` write pid $$ to $pid_file >> $log

    fi    

}

function configIprule() {

    echo `date +"%F %T"` start to config ip table jiekuan route and rule. >> $log

    ip route add default via 192.168.105.5 dev tun0  table jiekuan
    ip route add 172.18.16.0/20 via 192.168.105.5 dev tun0 table jiekuan 
    ip route add 192.168.105.1 via 192.168.105.5 dev tun0 table jiekuan

    ip rule show | grep -i 'to 172.18.16.0/20 lookup jiekuan'
    [ $? -eq 1 ] && ip rule add to 172.18.16.0/20 table jiekuan

    echo `date +"%F %T"` finish configing ip table jiekuan route and rule. >> $log

    sleep 2

    echo `date +"%F %T"` start to config ip table qiandai route and rule. >> $log

    ip route add default via 192.168.106.6 dev tun1 table qiandai 
    ip route add 172.18.144.0/20 via 192.168.106.6 dev tun1 table qiandai
    ip route add 192.168.106.1 via 192.168.106.6 dev tun1 table qiandai

    ip rule show | grep -i 'to 172.18.144.0/20 lookup qiandai'
    [ $? -eq 1 ] && ip rule add to 172.18.144.0/20 table qiandai

    echo `date +"%F %T"` finish  configing ip table qiandai route and rule. >> $log


    echo `date +"%F %T"` start to clear ip table main route of relating to tun0[jiekuan] and tun1[qiandai] interface. >> $log
    ip route show table main | grep -iE 'tun0|tun1' | while read rt;do ip route delete $rt;done
    echo `date +"%F %T"` finish to clear ip table main route of relating to tun0[jiekuan] and tun1[qiandai] interface. >> $log

}



function startOpenvpn() {

    cd /home/openvpn/openvpn-link-aliyun/ttjiekuan && nohup openvpn dfxk_tt_jiekuan.ovpn >/dev/null 2>&1 & 

    sleep 2 && echo `date +"%F %T"` start linking aliyun openvpn of jiekuan process.>> $log

    ps -ef | grep -i dfxk_tt_jiekuan.ovpn | grep -v grep | awk '{print $2}' > $pid_jiekuan_file

    cd /home/openvpn/openvpn-link-aliyun/ttqiandai && nohup openvpn dfxk_tt_qiandai.ovpn >/dev/null 2>&1 & 

    sleep 2 && echo `date +"%F %T"` start linking aliyun openvpn of qiandai process.>> $log

    ps -ef | grep -i dfxk_tt_qiandai.ovpn | grep -v grep | awk '{print $2}' > $pid_qiandai_file

}

function configIPtables() {

    iptables_log='/tmp/iptables.config.for.openvpn'

cat > $iptables_log << EOF
    iptables -A FORWARD -d 172.18.144.0/20 -i enp0s31f6 -o tun1 -j ACCEPT
    iptables -A FORWARD -d 172.18.16.0/20 -i enp0s31f6 -o tun0 -j ACCEPT
    iptables  -t nat -A POSTROUTING -s 192.168.103.0/24 -d 172.18.252.104/32 -o tun1 -j MASQUERADE
    iptables  -t nat -A POSTROUTING -s 192.168.102.0/24 -d 172.18.252.104/32 -o tun1 -j MASQUERADE
    iptables  -t nat -A POSTROUTING -s 192.168.102.0/24 -d 172.18.144.0/20 -o tun1 -j MASQUERADE
    iptables  -t nat -A POSTROUTING -s 192.168.103.0/24 -d 172.18.144.0/20 -o tun1 -j MASQUERADE
    iptables  -t nat -A POSTROUTING -s 192.168.103.0/24 -d 172.18.72.12/32 -o tun0 -j MASQUERADE
    iptables  -t nat -A POSTROUTING -s 192.168.102.0/24 -d 172.18.72.12/32 -o tun0 -j MASQUERADE
    iptables  -t nat -A POSTROUTING -s 192.168.103.0/24 -d 172.18.16.0/20 -o tun0 -j MASQUERADE
    iptables  -t nat -A POSTROUTING -s 192.168.102.0/24 -d 172.18.16.0/20 -o tun0 -j MASQUERADE
EOF

    if [ -f $iptables_log ]
    then

        while read line
        do
            echo $line | grep -i forward 
            if [ $? -eq 0 ]
            then
                match=$(echo $line | awk -F'-A' '{print $2}')
                iptables -t filter -S | grep -i "$match" 
                [ $? -eq 1 ] && $line
                continue
            fi

            echo $line | grep -i POSTROUTING
            if [ $? -eq 0 ]
            then
                match=$(echo $line | awk -F'-A' '{print $2}')
                iptables -t filter -S | grep -i "$match"
                [ $? -eq 1 ] && $line
            fi

        done < $iptables_log

    fi

}


function deletePidFile() {
 
   pid_file='/home/devops/pid/link_aliyun_openvpn_pid'

   rm -rf $pid_file 

   echo  $(date +"%F %T") delete $pid_file >> $log

}

function deleteOpenvpnPidFile() {

    pid_jiekuan_file='/home/devops/pid/aliyun_openvpn_jiekuan_pid'

    pid_qiandai_file='/home/devops/pid/aliyun_openvpn_qiandai_pid'

    if [ -f $pid_jiekuan_file -o -f $pid_qiandai_file ]

    then
        rm -rf $pid_jiekuan_file $pid_qiandai_file

    fi

}


function killOpenvpn() {

   if [ $1 == 'stop' ]
   then
       ps -ef | grep -i openvpn | grep -iE 'dfxk_tt_jiekuan|dfxk_tt_qiandai' | grep -v grep | awk '{print $2}' | xargs kill -9 
       echo $(date +"%F %T") kill openvpn process
   fi

}


function main() {

   if [ $1 == 'start' ]
   then
       exportPath
       getPid
       startOpenvpn
       configIprule
       configIPtables
       deletePidFile
   fi

}

case $1 in

    start )

    main start
    ;;

    stop )

    exportPath
    killOpenvpn stop >/dev/null 2>&1 
    deleteOpenvpnPidFile
    deletePidFile
    ;;
    
    restart )
    
    killOpenvpn stop >/dev/null 2>&1 
    deleteOpenvpnPidFile
    deletePidFile
    main start

    ;;

    
    *)
    
    echo "$0 [start|stop|restart]"
    exit 0
    ;;
esac
