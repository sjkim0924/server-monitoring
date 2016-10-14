####################################################################################################
#                                   server-monitoring-sjkim.sh                                     #
#                                                                                                  #
#                        This script was created by modified to suit the needs                     #
#                      based on the "https://github.com/atarallo/TECMINT_MONITOR"                  #
####################################################################################################

#! /bin/bash
export TERM=xterm
clear

if [[ $# -eq 0 ]]
then
{
# Define Variable monitoring-server
termreset=$(tput sgr0)

date=$(date)
echo -e '\E[32m'"Date : " $termreset $date

# Check if connected to Internet or not
ping -c 1 google.com &> /dev/null && echo -e '\E[32m'"Internet: $termreset Connected" || echo -e '\033[91m'"Internet: $termreset Disconnected"
echo ""

# Check OS Type
os=$(uname -o)
echo -e '\E[32m'"Operating System Type :" $termreset $os

# Check OS Release Version and Name
###################################
OS=`uname -s`

GetVersionFromFile()
{
   VERSION=`cat $1 | tr "\n" ' ' | sed s/.*VERSION.*=\ // `
}

if [ "${OS}" = "SunOS" ] ; then
   OS=Solaris
elif [ "${OS}" = "AIX" ] ; then
   OSSTR="${OS} `oslevel` (`oslevel -r`)"
elif [ "${OS}" = "Linux" ] ; then
   if [ -f /etc/redhat-release ] ; then
       OS_Version=`cat /etc/redhat-release`
       DIST='RedHat'
   elif [ -f /etc/SuSE-release ] ; then
       OS_Version=`cat /etc/SuSE-release | tr "\n" ' '| sed s/VERSION.*//`
   elif [ -f /etc/os-release ]; then
       OS_Version=`cat /etc/issue | cut -d'\' -f1`
   fi
   OSSTR="${OS} ${OS_Version}"
fi

##################################
echo -e '\E[32m'"OS Version :" $termreset $OSSTR
# Check Architecture
architecture=$(uname -m)
echo -e '\E[32m'"Architecture :" $termreset $architecture

# Check Kernel Release
kernelrelease=$(uname -r)
echo -e '\E[32m'"Kernel Release :" $termreset $kernelrelease
echo ""

# Check hostname
echo -e '\E[32m'"Hostname :" $termreset $HOSTNAME

# Check Internal IP
internalip=$(hostname -I)
echo -e '\E[32m'"Internal IP :" $termreset $internalip

# Check External IP
externalip=$(curl -s ipecho.net/plain;echo)
echo -e '\E[32m'"External IP : $termreset "$externalip

# Check DNS
nameservers=$(cat /etc/resolv.conf | sed '/#/d' | awk '{print $2}')
echo -e '\E[32m'"Name Servers :" $termreset $nameservers
echo ""

# Check Logged In Users
who>/tmp/who
echo -e '\E[32m'"Logged In users :" $termreset && cat /tmp/who
echo ""

# Check CPU info and usage
cat /proc/cpuinfo | grep 'model name\|cpu cores' | sort | uniq -c | sed 's/  */ /g'> /tmp/cpuinfo
echo -e '\E[32m'"CPU info :" $termreset
cat /tmp/cpuinfo
if [ "${DIST}" = "RedHat" ]; then
  top -n 1 -b | grep Cpu | awk '{print $1, $2, $3, $5}' | sed 's/id,/id/' | sed 's/%/% /g' > /tmp/cpuusage
  echo -e '\E[32m'"CPU Usage :" $termreset
  cat /tmp/cpuusage
else
  top -n 1 -b | grep Cpu | awk '{print $1, $2, $3, $4, $5, $8, $9}' | sed 's/id,/id/' > /tmp/cpuusage
  echo -e '\E[32m'"CPU Usage :" $termreset
  cat /tmp/cpuusage
fi
echo ""

# Check RAM and SWAP Usages
free -h | grep -v + > /tmp/ramcache
echo -e '\E[32m'"Ram Usages :" $termreset
cat /tmp/ramcache | grep -v "Swap"
echo -e '\E[32m'"Swap Usages :" $termreset
cat /tmp/ramcache | grep -v "Mem"
echo ""

# Check Disk Usages
df -h| grep 'Filesystem\|/dev/[a-z][a-z][a-z][0-9]\|:' > /tmp/diskusage
echo -e '\E[32m'"Disk Usages :" $termreset
cat /tmp/diskusage

# Check disk usage warning
df -H | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{ print $5 " " $1 }' | grep "/dev/[a-z][a-z][a-z][0-9]\|:" | while read output;
do
  #echo -e '\E[32m'"Disk Usages percent :" $output
  usepercent=$(echo $output | awk '{print $1}' | cut -d'%' -f1)
  filesystem=$(echo $output | awk '{print $2}')
  if [ $usepercent -ge 80 ]; then
    echo -e '\033[91m'" > Running out of space \"$filesystem ($usepercent%)\""
  fi
done
echo ""

# Check Load Average
loadaverage=$(top -n 1 -b | grep "load average:" | awk '{print $(NF-2),$(NF-1),$(NF)}')
echo -e '\E[32m'"Load Average :" $termreset $loadaverage
echo ""

# Check process program and ports
if [ "${DIST}" = "RedHat" ]; then
  echo -e '\E[32m'"Process Program Lists and Ports :" $termreset
  $PRINT && printf "%7s %15s %20s %20s %5s\n" "Type" "Service" "Port" "User" "D.C"
  lsof -i -n -P | grep TCP | more | grep LIST | awk '{print $5,$3,$1,$9}' | sort | uniq -c | while read output;
  do
    types=$(echo $output | awk '{print $2}')
    services=$(echo $output | awk '{print $4}')
    ports=$(echo $output | awk '{print $5}')
    users=$(echo $output | awk '{print $3}')
    duplicate_count=$(echo $output | awk '{print $1}')
    $PRINT && printf "%7s %15s %20s %20s %5s\n" "$types" "$services" "$ports" "$users" "$duplicate_count"
  done
  echo ""
else
  echo -e '\E[32m'"Process Program Lists and Ports :" $termreset
  $PRINT && printf "%7s %15s %20s %20s %5s\n" "Type" "Service" "Port" "User" "D.C"
  sudo lsof -i -n -P | grep TCP | more | grep LIST | awk '{print $5,$3,$1,$9}' | sort | uniq -c | while read output;
  do
    types=$(echo $output | awk '{print $2}')
    services=$(echo $output | awk '{print $4}')
    ports=$(echo $output | awk '{print $5}')
    users=$(echo $output | awk '{print $3}')
    duplicate_count=$(echo $output | awk '{print $1}')
    $PRINT && printf "%7s %15s %20s %20s %5s\n" "$types" "$services" "$ports" "$users" "$duplicate_count"
  done
  echo ""
fi

# Check Process States
if [ "${DIST}" = "RedHat" ]; then
  echo -e '\E[32m'"Process States :" $termreset
  $PRINT && printf "%13s %5s\n" "States" "D.C"
  netstat -anlpt | awk '{print $6}' | sort | uniq -c | sort -n | while read output;
  do
    states=$(echo $output | awk '{print $2}')
    duplicate_count=$(echo $output | awk '{print $1}')
    $PRINT && printf "%13s %5s\n" "$states" "$duplicate_count"
  done
  echo ""
else
  echo -e '\E[32m'"Process States :" $termreset
  $PRINT && printf "%13s %5s\n" "States" "D.C"
  sudo netstat -anlpt | awk '{print $6}' | sort | uniq -c | sort -n | while read output;
  do
    states=$(echo $output | awk '{print $2}')
    duplicate_count=$(echo $output | awk '{print $1}')
    $PRINT && printf "%13s %5s\n" "$states" "$duplicate_count"
  done
  echo ""
fi

# Check System Uptime
uptime=$(uptime | awk '{print $3,$4}' | cut -f1 -d,)
echo -e '\E[32m'"System Uptime Days/(HH:MM) :" $termreset $uptime
echo ""

# Remove Temporary Files
rm /tmp/who /tmp/ramcache /tmp/diskusage /tmp/cpuinfo /tmp/cpuusage 
}
fi
