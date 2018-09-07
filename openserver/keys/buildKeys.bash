#!/bin/bash

function exportPATH() {

    PATH=/usr/lib64/qt-3.3/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
    export PATH

}

function buildKeys() {
   
   user=$1
   keyPath=/root/keys/
   easyRsaPath=/etc/openvpn/easy-rsa/2.0
   
   cd $easyRsaPath
   . ./vars
   ./build-key --batch $user
   cp keys/{$user.key,$user.crt} $keyPath
   cd $keyPath
   cat ovpn1 $user.crt ovpn2 $user.key ovpn3 > $user.ovpn
   rm $user.crt $user.key

}

function helpDoc() {

   echo "$0 [username]"
   exit 1
}

function main() {

   user=$1
   buildKeys $user 

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

