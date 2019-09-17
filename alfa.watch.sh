#!/bin/bash
###################################################
#                                                 #
#  Author: saint                                  #
#                                                 #
#  Usage: alfa.watch [iface]                      #
#                                                 #
# Since the AWUS036ACH seems to go down sometimes #
# This script will watch it, and turn it back on  #
#                                                 #
# Version: 0.1                                    #
#                                                 #
###################################################

# check root
if [ $EUID -ne 0 ]; then
    echo "Execute as root"
    exit 1
fi

# catch argument
if [ -z "$1" ]; then
	echo "Arguments expected : <interface> (wlx<mac>)"
	echo "Sample : wlx00c0ca966342 or wlx00c0ca966352"
	exit 1
fi


iface=$1
ifacemon="mon0"
mac=DE:AD:C0:DE:CA:FE

# Flow in this order :
# check it's up, OR
# disconnected ==> present down ==> up ==> mon0



i=1
while [ true ]
do

	ifconfig | grep $ifacemon &>/dev/null

	if [ $? -ne 0 ] ; then # mon0 is down
		echo
		echo -e "[STATUS]	$ifacemon is \033[31m\033[1mDOWN\033[0m, checking if present..." ; sleep .1


		ifconfig -a | grep $ifacemon &>/dev/null
		if [ $? -eq 0 ] ; then # interfacemon is down but present
	        	echo -e ">>>            $ifacemon is \033[33m\033[1mDETECTED\033[0m, turning it up..." ; sleep .1
			ip link set $ifacemon up
                else
                        echo -e ">>>		$ifacemon \033[31m\033[1mNOT FOUND\033[0m" ; sleep .1
			echo ">>>		looking for interface $iface..." ; sleep .1


			ifconfig | grep $iface &>/dev/null
	        	if [ $? -eq 0 ] ; then # interface is up
				echo -e ">>>		$iface is \033[33m\033[1mDUP\033[0m, shutting it and restoring monitor..." ; sleep .1
				ip link set $iface down
				iw dev $iface set type monitor
				ip link set $iface name $ifacemon
				macchanger -m $mac $ifacemon
				ip link set $ifacemon up
			else
				echo -e ">>>		$iface is \033[31m\033[1mDOWN\033[0m, checking if present..." ; sleep .1


				ifconfig -a | grep $iface &>/dev/null
        		        if [ $? -eq 0 ] ; then # interface is down but present
       			                echo -e ">>>		$iface is \033[33m\033[1mDETECTED\033[0m, restoring monitor..." ; sleep .1
               			        iw dev $iface set type monitor
               		        	ip link set $iface name $ifacemon
					macchanger -m $mac $ifacemon
               		        	ip link set $ifacemon up
        		     	else
        		                echo -e ">>>		$iface seems to be \033[31m\033[1mDISCONNECTED\033[0m" ; sleep .5
				fi
			fi
		fi


	else
		mod=$(($i %2))
		if [ $mod == 1 ] ; then
        		echo -ne "\033[0K\r[STATUS]	$ifacemon is \033[32m\033[1mUP\033[0m ❤ " ; sleep .5
		else
			echo -ne "\033[0K\r[STATUS]	$ifacemon is \033[32m\033[1mUP\033[0m   " ; sleep .5
		fi
	fi

#	echo "watched $i sec"
#	sleep 1 &&
((i++))

done

