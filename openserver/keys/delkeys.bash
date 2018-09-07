#!/bin/bash


function exportPATH() {

    PATH=/usr/lib64/qt-3.3/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
    export PATH

}

function delkeys() {
    
    user=$1

    openvpnKeys=/etc/openvpn/easy-rsa/2.0/keys
    cd $openvpnKeys
    cat index.txt | grep  "\b$user\b" | awk '{print $3}' | xargs -i -n 1 rm -rf {}.pem
    sed -i "/\b$user\b/d" index.txt
    if [ -f "$user.crt" -o -f "$user.csr" -o -f "$user.key" ]; then 
        rm -rf $user.crt $user.csr $user.key 
    else 
        echo "`date +'%Y-%m-%d %H:%M:%S'` there is no openvpn keys, program exit 2 " >>/tmp/openvpnDeleteUser.log
        exit 2
    fi 
    checkRmResult=`ls * | grep -E "$user.(crt|csr|key)" | wc -l`
    echo $checkRmResult
    if [ $checkRmResult -eq 0 ]; then
        echo "`date +'%Y-%m-%d %H:%M:%S'` delete $user openvpn keys successfully" >>/tmp/openvpnDeleteUser.log
    else 
        echo "`date +'%Y-%m-%d %H:%M:%S'` delete $user openvpn keys failed" >>/tmp/openvpnDeleteUser.log
    fi

    cd /root/keys && rm -rf $user.ovpn

}

function helpDoc() {

   echo "$0 [username]"
   exit 1
}

function main() {

   user=$1
   delkeys $user 

}

case $# in
   1)
       case $1 in
          -h|-H|--help|--HELP)
             helpDoc
          ;;
          *)
            user=$1
            main $user
          ;;
       esac
   ;;
   *)
      helpDoc
   ;;
esac

