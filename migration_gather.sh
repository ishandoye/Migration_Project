#!/bin/bash

 ############################################################################
 # Bash script to gather details for Migration Purpose
 # Author: Team L1
 # Team L1 - Ishan Doye(Captain), Navdeep
 # Functions Included
 #       # f_utlization_data     
 #       # f_pys_virt_env        
 #       # f_getusers_info       
 #       # f_bind_and_mount      
 #       # f_fstab_bind_and_mount
 #       # f_general_details     
 #       # f_logrotate_details   
 #       # f_cronjob_all         
 #       # f_storage_details     
 #       # f_holland             
 #       # f_pcs_details         
 #       # f_mysqldbcount        
 #       # f_website_running     
 #       # f_iptables_check      
 #       # f_firewalld_details   
 #       # f_check_monitoring    
 #       # f_check_backup        
 #       # f_fail2ban            
 # There is lots of scope in here to add multiple things
 ############################################################################
 
##---------------------------------------------------------------------------------------------------------------##
#  This is a Function to gather Information about Monitoring details #
## --------------------------------------------------------------------------------------------------------------##

f_check_monitoring() {

f_check_cloud_monitor() {
if command -v rackspace-monitoring-agent > /dev/null 2>&1; then
        echo -e "\n=== This cloud server has Racksapce Monitoring for Following agents ==="
        if [ $(tail -20 /var/log/rackspace-monitoring-agent.log|grep -w "agent.memory" |awk '/agent.memory/ {print $11}'|uniq) ]; then
        echo "Memory Monitoring"
        fi

        if [ $(tail -20 /var/log/rackspace-monitoring-agent.log|grep -w "agent.cpu"|awk '/agent.cpu/ {print $11}'|uniq) ]; then
        echo "CPU Monitoring"
        fi

        if [ $(tail -20 /var/log/rackspace-monitoring-agent.log|grep -w "agent.load_average"|awk '/agent.load_average/ {print $11}'|uniq) ]; then
        echo "Load Average Monitoring"
        fi

        if [ $(tail -20 /var/log/rackspace-monitoring-agent.log|grep -w "agent.filesystem"|awk '/agent.filesystem/ {print $11}'|uniq) ]; then
        echo "Filesystem Monitoring"
        echo "Filesystem Target: $(tail -20 /var/log/rackspace-monitoring-agent.log|grep -w "agent.filesystem"|awk '/agent.filesystem/ {print $11}'|uniq)"
        fi

        if [ $(tail -20 /var/log/rackspace-monitoring-agent.log|grep -w "agent.network"|awk '/agent.network/ {print $11}'|uniq) ]; then
        echo "Network Monitoring"
        echo "Network Target : $(tail -20 /var/log/rackspace-monitoring-agent.log|grep -w "agent.network"|awk '/target/ {print $12}'|cut -d "," -f1|cut -d '=' -f2,3|uniq)"
        fi

else
    echo ""
    echo -e "\n== There is no Rackspace Monitoring Agent Configured on this device =="
    echo ""
fi
}

f_check_nimbus_monitor() {
if [[ -z "$(ls -A /opt/nimbus/ > /dev/null 2>&1)" && "$netstat -tnlp|grep -w nimbus" ]]; then
        echo -e "\n=== This Device has Nimbus Monitoring Configuration with Following Probes ==="
        find /opt/nimsoft/ -iname \*.cfg|awk -F "/" '{print $(NF-1)}'|sort -u|egrep -v "robot|plugin_metric|cfgs"
        echo -e ""
        echo -e "\n=== This Device has Nimbus Monitoring with Following Probes ==="
        ss -tlnp | awk '/^LISTEN/ && $4 ~ /:(480[0-2][0-9]|48030)$/ {split($NF,a,"[\"/]"); print "PROCESS ==" a[2] "== is LISTNING on port " substr($4, index($4, ":")+1)}'

else
    echo ""
    echo -e "\n== There is no Nimbus Agent Configured on this device =="
    echo ""
fi
    echo -e "\n=== For More Information Please Visit UIM portal or run commands on device ==="
}

f_cloudwatch_monitor(){

if ! command -v amazon-cloudwatch-agent-ctl  2>/dev/null; then
        echo ""
        echo "== Cloud watch Agent is not present on this device check Manually"
        echo ""
        else
                echo -e "\n=== Cloud watch Configuration Status==="
                        amazon-cloudwatch-agent-ctl -a status|egrep '"status":|"starttime":|"configstatus":'
                echo -e "\n"
                echo -e "\n=== Cloud watch Monitoring for ==="
                        sed -n '/\[inputs\]/, /\[outputs\]/{ /\[outputs\]/!p }' /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.toml

fi
}


# Get the system manufacturer and product name
#manufacturer=$(sudo dmidecode -s system-manufacturer)
#product_name=$(sudo dmidecode -s system-product-name)

# Check if the device is physical or virtual
if [[ $manufacturer =~ (VMware|Dell|HP) || $product_name =~ (VMware|Dell|HP) ]]; then

    f_check_nimbus_monitor

elif [[ $manufacturer =~ Xen || $product_name =~ Xen ]]; then

    f_check_cloud_monitor

else
    f_cloudwatch_monitor
fi


}



##---------------------------------------------------------------------------------------------------------------##
# This is a Function to gather Generic Details
## --------------------------------------------------------------------------------------------------------------##

f_general_details() {

function Os_Detls() {
 # Check if the /etc/lsb-release file exists
    if [ -f /etc/lsb-release ]; then
        # Read the contents of the /etc/lsb-release file
        source /etc/lsb-release
        # save the Os Name and version details
        OS_Name=$DISTRIB_ID
        Version=$DISTRIB_RELEASE
        echo "Operating System: $OS_Name"
        echo "Operating System Version: $Version"
else
    # If the /etc/lsb-release file does not exist, check other files
    if [ -f /etc/os-release ]; then
    # Read the contents of the /etc/os-release file
    source /etc/os-release
   # save the Os Name and version details
    OS_Name=$NAME
    Version=$VERSION_ID
    echo "Operating System: $OS_Name"
    echo "Operating System Version: $Version"
    elif [ -f /etc/redhat-release ]; then
        # Read the contents of the /etc/redhat-release file
        OS_Name=$(cat /etc/redhat-release)
        echo "Operating System: $OS_Name"
    else
        echo "Unknown Linux distribution."
    fi
fi
}

f_network_details() {

# Gather network information
echo -e "=== ===                     === ==="
echo -e "=== === Network Information === ==="
echo -e "=== ===                     === ==="

echo -e "\n=== IP Adddress ==="
echo ""
ip addr 2>/dev/null
echo -e "\n=== MAC Address ==="
echo ""
ip -o link show | awk '/link\/ether/ {print "Interface: " $2 ", MAC Address: " $(NF-2)}'  2>/dev/null
echo -e "\n=== IP Routes ==="
echo ""
route -n  2>/dev/null
echo -e "\n=== IP Routes ==="
echo ""
ip route show  2>/dev/null

echo ""
echo "========= END ========="
echo ""

}

##---------------------------------------------------------------------------------------------------------------##
# This is a Function That will collect the Details of Lsynced service and the Exclusion of packages
## --------------------------------------------------------------------------------------------------------------##

f_pkg_lsyncd() {
f_exclusion_debian() {
       echo -e "\nPACKAGES EXCLUSION DPKG :"
        echo -e  "--------------------------\n"

        aptexc=$(sudo dpkg --get-selections | grep "hold" | wc -l)
        if [ $aptexc -le 0 ]
        then
        echo -e "\n=== There are no Package exclusions listed ===\n"
        echo ""
        else
        if [ $aptexc -ge 1 ]
        then
        echo -e "\n=== Below are the exclusions/hold listed ===\n"
        sudo dpkg --get-selections | grep "hold"
        fi
fi
}


f_exclusion_rhel() {
               echo -e "\nYUM EXCLUSION :"
               echo -e  "--------------------------\n"

                yumexc=$(cat /etc/yum.conf|grep exclude|grep -v "#"|grep "\S" | wc -l)
                if [ $yumexc -le 0 ]
                then
                echo -e "\n=== There are  No Package exclusions listed ===\n"
                else
                if [ $yumexc -ge 1 ]
                then
                echo -e "===\n Below are the Package exclusions listed ===\n"
                cat /etc/yum.conf|grep exclude|grep -v "#"|grep "\S"
                fi
fi
}


f_lsyncd_rhel() {

        echo -e "\nLSYNCED STATUS :"
        echo -e  "-----------------\n"
        if [ "$(ls -A /etc/lsyncd.conf  2>/dev/null )" ]; then

        echo -e "\n=== Lsync service is running in the server with below configuration: ===\n"

        grep -v "#" /etc/lsyncd.conf|grep -v "^--"

        else

        echo -e "\n=== Lsyncd is not configured on this device : ===\n"



fi
}


f_lsyncd_debian() {
        echo -e "\nLSYNCED STATUS :"
        echo -e  "-----------------\n"


        if [ "$(ls -A /etc/lsyncd/lsyncd.conf.lua  2>/dev/null)" ]; then

        echo -e "\n=== Lsync service is running in the server with below configuration: ===\n"

        grep -v "#" /etc/lsyncd/lsyncd.conf.lua|grep -v "^--"

        else

        echo -e "\n=== Lsyncd is not configured on this device : ===\n"
fi
}


# Check Linux distribution
get_linux_distro() {
  if [ -f /etc/redhat-release ]; then
    echo "rhel"
  elif [ -f /etc/os-release ]; then
    source /etc/os-release
    echo "$ID"
  elif [ -f /etc/lsb-release ]; then
    source /etc/lsb-release
    echo "$DISTRIB_ID"

  elif [ -f /etc/SuSE-release ]; then
    echo "sles"
  else
    echo "Unsupported"
  fi
}

# Get Linux distribution
linux_distro=$(get_linux_distro)

if [[ $linux_distro =~ ubuntu ||  $linux_distro =~ debian ]]; then

                f_exclusion_debian
                f_lsyncd_debian

elif [[ $linux_distro =~ rhel ]]; then

                f_exclusion_rhel
                f_lsyncd_rhel

fi

}


# Gather system information
echo "=== System Information ==="
echo "Hostname: $(hostname)"
echo "Kernel Version: $(uname -r)"
echo "Architecture: $(uname -m)"
echo "IP Address:$(hostname -I)"
echo "Server Date:$(date)"

Os_Detls
f_network_details  2>&1 > $dir_to_store/All_server_details/Nework_details.txt

echo "=== Combination of two functions pkg exclusion and lsynced ===== is present under $dir_to_store/All_server_details/Lsyncd_status_pkg_exclusion.txt"
f_pkg_lsyncd 2>&1 > $dir_to_store/All_server_details/Lsyncd_status_pkg_exclusion.txt

# Gather LastLogin information
lastlog|grep -v "**Never logged in**"


# Gather CPU information
echo -e "\n=== CPU Information ==="
echo "CPU Model: $(cat /proc/cpuinfo | grep "model name" | head -n 1 | cut -d ":" -f 2 | sed 's/^ *//')"
echo "CPU Cores: $(grep -c '^processor' /proc/cpuinfo)"

# Gather memory information
echo -e "\n=== Memory Information ==="
echo "Total Memory: $(free -h | awk '/Mem:/ {print $2}')"
echo "Used Memory: $(free -h | awk '/Mem:/ {print $3}')"
echo "Free Memory: $(free -h | awk '/Mem:/ {print $4}')"
echo "Available Memory: $(free -h | awk '/Mem:/ {print $7}')"

echo -e "\n=== SWAP Information ==="
echo "Total Swap: $(free -h | awk '/Swap:/ {print $2}')"
echo "Used Swap: $(free -h | awk '/Swap:/ {print $3}')"
echo "Free Swap: $(free -h | awk '/Swap:/ {print $4}')"


# Gather disk information
echo -e "\n=== Disk Information ==="
df -hT
echo -e "\n=== * Total Disk for / * ==="
echo "Total Disk: $(df -h | awk '$NF=="/"{printf "Total: %s, Used: %s, Free: %s\n", $2, $3, $4}')"

# Gather installed packages
echo -e "\n=== Installed Packages ==="
if command -v apt-get &> /dev/null; then
  echo -e "\n=== APT Packages: Check the $dir_to_store/All_server_details/packages_installed.txt file ==="
  dpkg --get-selections 2>&1 > $dir_to_store/All_server_details/packages_installed.txt
elif command -v yum &> /dev/null; then
  echo -e "\n=== YUM Packages:Check the $dir_to_store/All_server_details/packages_installed.txt file ==="
  rpm -qa  2>&1 > $dir_to_store/All_server_details/packages_installed.txt
else
  echo -e "\n=== Package manager not found or script is not aware of it. ==="
fi

# Gather System Manufacturer
echo -e "\n=== System Manufacturer ==="
if command -v dmidecode &> /dev/null; then
        echo "System Information: $(dmidecode|grep -A 2 "System Information")"
        else
        echo "Product_name: $(cat /sys/class/dmi/id/product_name)"
        echo "Chassis_vendor: $(cat /sys/class/dmi/id/chassis_vendor)"
fi


# Gather Details for User' having sudoe access.

sudo_users1=`egrep -w "wheel|sudo|admin" /etc/group|cut -d: -f4|grep "\S"`
sudo_users2=`egrep -v "#|Defaults" /etc/sudoers|grep ALL|awk '{print $1}'|egrep -v "wheel|sudo|root|admin"`
sudo_users3=`echo $sudo_users1,$sudo_users2`
sudo_users4=`echo $sudo_users3|tr -s ','  '\n'|tr -s ' '  '\n'|sort -u|tr '\n' ','`
echo "===========================                       ============================="
echo -e "\n === User having Sudo access ==="
echo "===========================                       ============================="
echo "Sudo Access users: $sudo_users4" 2>&1

echo ""
echo ""

hostname=$(cat /etc/hostname)

# /etc/hosts
echo -e "\n/ETC/HOSTS FILES :"
echo -e "-----------------\n"

echo /etc/hosts  Files Of Server $hostname
echo ""
cat /etc/hosts

echo -e "\n ========================================================\n"


echo "NFS EXPORTS :"
echo -e "--------------\n"

nfsexports=$(cat /etc/exports 2>/dev/null | wc -l)
if [ $nfsexports -le 0 ]
then
echo ""
echo "This is not NFS Server and there are no /etc/exports files are configured "
echo ""
else
if [ $nfsexports -ge 1   ]
then
echo "Nfs Server is Configured with below exports files :"
echo ""
cat /etc/exports 2>/dev/null
echo ""
fi
fi


echo ""
echo ===============================================================
echo ""

echo "SERVER LEVEL FIREWALLS :"
echo "------------------------"
echo ""

echo "SELINUX :"
echo "---------"
echo ""
sestatus 2>/dev/null| egrep 'SELinux status|Current'


echo -e "\nNSSWITCH :"
echo -e  "----------\n"


nsswitch=$(cat /etc/nsswitch.conf | egrep -i '^passwd|^shadow|^group|^hosts' | wc -l)
if [ $nsswitch -le 0 ]
then
cat "There are no important parameters listed in nsswitch"
else
if [ $nsswitch -ge 1 ]
then
echo -e "\n Below are the nsswitch listed paramters\n"
cat /etc/nsswitch.conf | egrep -i '^passwd|^shadow|^group|^hosts' 2>/dev/null
fi
fi


echo " === End Of the file ==="

}


##---------------------------------------------------------------------------------------------------------------##
# This is a Function to gather Information about the Mounts and bind mounts#
## --------------------------------------------------------------------------------------------------------------##

f_bind_and_mount() {

# Retrieve all mounts from /proc/mounts
# echo > $dir_to_store/All_server_details/mounts_bindMounts.txt

echo "---"
echo "You can Find the Generic data of all mounts on the server even if it is not in fstab like BindMount"
echo "----"

all_mounts=$(findmnt -m | awk '{if(NR>1)print}')
# Iterate over each mount
while read -r mount_entry; do
  # Extract mount point and mount type
  mount_point=$(echo "$mount_entry" | awk '{print $1}')
  source=$(echo "$mount_entry" | awk '{print $2}')
  mount_type=$(echo "$mount_entry" | awk '{print $3}')

  # Check if it's a bind mount
  if [[ $source =~ "[" ]]; then
echo "---------------------------------------------------------------------------------------------------------"
echo " === Bind Mount Entires ==="
        echo "Bind Mount: $mount_point"
        echo "Source: $source"
        echo "FsType: $mount_type"
        echo "--------"
echo "---------------------------------------------------------------------------------------------------------"
  else
        echo "Mount: $mount_point"
        echo "Source: $source"
        echo "FsType: $mount_type"
        echo "--------"

  fi
done <<< "$all_mounts"

#echo "===>                            ------------------                                            <==="
#echo " Please find all mounts over the server using mtab command $dir_to_store/All_server_details/mounts_bindMounts.txt"
#echo "===>                            ------------------                                            <==="
#echo ""

}


##---------------------------------------------------------------------------------------------------------------##
# This is a Function to gather Information about the Mounts and bind mountsi using the findmnt and fstab#
## --------------------------------------------------------------------------------------------------------------##

f_fstab_bind_and_mount() {

# Retrieve all mounts from fstab file
# echo 2>&1 > $dir_to_store/All_server_details/findmount_fstab.txt

echo "---"
echo "Extentioon to generic details"
echo "----"

fstab_mounts=$(findmnt --fstab --evaluate | awk '{if(NR>1)print}')
# Iterate over each mount
while read -r fmounts_entry; do
  # Extract mounts point and mount type
  mount_point=$(echo "$fmounts_entry" | awk '{print $1}')
  source=$(echo "$fmounts_entry" | awk '{print $2}')
  mount_type=$(echo "$fmounts_entry" | awk '{print $3}')
  options=$(echo "$fmounts_entry" | awk '{print $4}')

  # Check if it's a bind mount
  if [[ $source =~ "[" ]]; then
    echo "Bind Mount: $mount_point"
        echo "Source: $source"
        echo "FsType: $mount_type"
        echo "Options: $options"
        echo "--------"

  else
        echo "Mount: $mount_point"
        echo "Source: $source"
        echo "FsType: $mount_type"
        echo "Options: $options"
        echo "--------"

  fi
done <<< "$fstab_mounts"
}




##---------------------------------------------------------------------------------------------------------------##
# This is a Function to gather Information about the device User details#
## --------------------------------------------------------------------------------------------------------------##

f_getusers_info() {
# Function to get user information and permissions
function get_user_info() {
    username="$1"

    # Get user ID and group ID
    user_id=$(id -u "$username")
    group_id=$(id -g "$username")

    # Get user information from /etc/passwd
    user_info=$(getent passwd "$username")

    # Extract user's home directory and default shell
    home_directory=$(echo "$user_info" | awk -F: '{print $6}')
    default_shell=$(echo "$user_info" | awk -F: '{print $7}')

    # Get user's primary group from /etc/group
    primary_group=$(getent group "$group_id" | awk -F: '{print $1}')

    # Get supplementary groups
    supplementary_groups=$(id -Gn "$username" | tr ' ' ',')

    # Print user information
    echo "User: $username"
    echo "User ID: $user_id"
    echo "Group ID: $group_id"
    echo "Home Directory: $home_directory"
    echo "Default Shell: $default_shell"
    echo "Primary Group: $primary_group"
    echo "Supplementary Groups: $supplementary_groups"
    echo "---"
}


# Get a list of non-system users
# Empty the file

# echo > $dir_to_store/All_server_details/user_details.txt

if [ "$(grep -w UID_MIN /etc/login.defs|awk '{printf $2}')" != '500' ]; then
non_system_users=$(getent passwd | awk -F: '$3 >= 1000 && $3 != 65534 {print $1}')

# Iterate over non-system users and get their information
for user in $non_system_users; do
    get_user_info "$user" 2>&1 >> $dir_to_store/All_server_details/user_details.txt
done

else
        non_system_users=$(getent passwd | awk -F: '$3 >= 500 && $3 != 65534 {print $1}')
        # Iterate over non-system users and get their information
        for user in $non_system_users; do
        get_user_info "$user"
        done
fi

# echo "===>                            ------------------                                            <==="
# echo "Please Find the user details in $dir_to_store/All_server_details/user_details.txt "
# echo "===>                            ------------------                                            <==="
# echo ""

}



##---------------------------------------------------------------------------------------------------------------##
# This is a Function to gather Information about the resource utilization from Sar result#
## --------------------------------------------------------------------------------------------------------------##

f_utlization_data() {

#!/bin/bash
# Check if the sar command is available

# Check Linux distribution
get_linux_distro() {
  if [ -f /etc/redhat-release ]; then
    echo "rhel"
  elif [ -f /etc/os-release ]; then
    source /etc/os-release
    echo "$ID"
  elif [ -f /etc/lsb-release ]; then
    source /etc/lsb-release
    echo "$DISTRIB_ID"
  elif [ -f /etc/SuSE-release ]; then
    echo "sles"
  else
    echo "Unsupported"
  fi
}

# Get Linux distribution
linux_distro=$(get_linux_distro)

case $linux_distro in
    [Uu]buntu|[Dd]ebian)
        sar_log_location="/var/log/sysstat"
        ;;
    [Cc]entos|[Rr]hel)
        sar_log_location="/var/log/sa"
        ;;
     [Ss]les|[Oo]pensuse)
        sar_log_location="/var/log"
        ;;
    *)
        echo "Unsupported distribution."
        #exit 1
        ;;
esac


if ! command -v sar >/dev/null; then
  echo "sar command is not available. Please make sure the sysstat package is installed."
  #exit 1
 #break
else
        read -p "Do you want to grab overall resource Utilization data then press 'y' else want to go with specific date press 'n' (y/n): " response
if [[ $response =~ ^[Yy]$ ]]; then

     #   read -p "Please provide the Full directory path to store the details : " utilz
     #   mkdir -p $utilz


        # Check if 30 days of sar files are available
        days_to_check=30
        sar_files=()
        for ((i = $days_to_check - 1; i >= 0; i--)); do
          check_date=$(date -d "$i days ago" +%Y-%m-%d|cut -d - -f3)
          sar_file="$sar_log_location/sa$check_date"
          if [[ -f "$sar_file" ]]; then
            sar_files+=("$sar_file")
          fi
        done

# Check if any sar files exist
if [[ ${#sar_files[@]} -eq 0 ]]; then
  echo "No sar files found for the last $days_to_check days."
  #exit
fi



# Iterate over each sar file
for sar_file in "${sar_files[@]}"; do
  # Extract the date from the sar file name
  dateb=$(basename "$sar_file" | sed 's/^sa//')
  date=$(date -d "$i days ago" +%Y-%m)
  # Get the average CPU utilization


function sar_cpu_avg() {
        echo "===== Average CPU  utilization for $date-$dateb: ===="
        echo ""
        echo "+----------------------------------------------------------------------------------+"
        echo "|Average:         CPU     %user     %nice   %system   %iowait    %steal     %idle  |"
        echo "+----------------------------------------------------------------------------------+"
        for file in `ls -tr "$sar_file" | grep -v sar`
        do
        dat=`sar -f $file | head -n 1 | awk '{print $4}'`
        echo -n $dat
        sar -f $file  | grep -i Average | sed "s/Average://"
        done
        echo "+----------------------------------------------------------------------------------+"
        }

function sar_memory_avg() {
        echo "===== Average Memory  utilization for $date-$dateb: ===="
        echo ""
        echo "+-------------------------------------------------------------------------------------------------------------------+"
        echo "|Average:       kbmemfree kbmemused  %memused kbbuffers kbcached  kbcommit   %commit  kbactive   kbinact   kbdirty  |"
        echo "+-------------------------------------------------------------------------------------------------------------------+"
        for file in `ls -tr "$sar_file" | grep -v sar`
        do
        dat=`sar -f $file | head -n 1 | awk '{print $4}'`
        echo -n $dat
        sar -r -f $file  | grep -i Average | sed "s/Average://"
        done
        echo "+-------------------------------------------------------------------------------------------------------------------+"
        }

function sar_cpu_mem_avg() {
        echo "===== Average CPU and MEM  utilization for $date-$dateb: ===="
        echo ""
        for file in `ls -tr "$sar_file" | grep -v sar`
        do
                        sar -f $file | head -n 1 | awk '{print $4}'
                        echo "-----------"
                        sar -u -f $file | awk '/Average:/{printf("CPU Average: %.2f%\n"), 100 - $8}'
                        sar -r -f $file | awk '/Average:/{printf("Memory Average: %.2f%\n"),(($3-$5-$6)/($2+$3)) * 100 }'
                        printf "\n"
        done
        }


sar_cpu_avg
sar_memory_avg
sar_cpu_mem_avg
done

else

# Prompt the user to enter a date
read -p "Enter the date (YYYY-MM-DD) : " input_date

years_to_check=$(date +%Y)
years_from_input_date=$(date -d "$input_date" +%Y)

if [[ $years_to_check != $years_from_input_date ]]; then
  echo " No Sar file found for the Year $years_from_input_date"
  #exit
fi

f_resource_utilization() {

# Extract the year, month, and day from the input
year=$(date -d "$input_date" +%Y)
month=$(date -d "$input_date" +%m)
day=$(date -d "$input_date" +%d)

# Calculate resource utilization for the specified date
echo "Resource utilization for $input_date:"

# CPU utilization
cpu_utilization=$(sar -u -f $sar_log_location/sa"$day" | awk '$1=="Average:" {print 100 - $NF}')
echo "CPU Utilization: $cpu_utilization%"

# Memory utilization
memory_utilization=$(sar -r -f $sar_log_location/sa"$day" | awk '$1=="Average:" {print $4}')
echo "Memory Utilization: $memory_utilization%"

# Disk utilization
disk_utilization=$(sar -d -f $sar_log_location/sa"$day" | awk '$1=="Average:" {print $NF}')
echo "Disk Utilization: $disk_utilization%"

# Network utilization
network_utilization=$(sar -n DEV -f $sar_log_location/sa"$day" | awk '$1=="Average:" {print $NF}')
echo "Network Utilization: $network_utilization%"
}

# Validate the date format
if [[ ! $input_date =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  echo "Invalid date format. Please enter the date in YYYY-MM-DD format."
else
  f_resource_utilization
  #exit 1
fi
fi
fi


#echo "===>                            ------------------                                            <==="
#echo "Please find Utilization using Sar in "$dir_to_store/All_server_details/utilization_from_sar.txt" File"
#echo "===>                            ------------------                                            <==="
#echo ""
}


##---------------------------------------------------------------------------------------------------------------##
# This is a Function to gather Information about the device is Virtual or Physical and using that find out details#
## --------------------------------------------------------------------------------------------------------------##

f_pys_virt_env() {
# Get the manufacturer and product_name

 #     manufacturer=$(sudo dmidecode -s system-manufacturer)
 #     product_name=$(sudo dmidecode -s system-product-name)
if [ -z "$(ls -A /sys/hypervisor/ > /dev/null 2>&1)" ]; then

  # Get the system manufacturer and product name

        if [[ $manufacturer =~ (HP) || $product_name =~ (HP) ]]; then

                echo "===>                            ------------------                                            <==="
                echo " This is $manufacturer device "
                echo "===>                            ------------------                                            <==="
                echo ""
                                # Add set of commands for HP

                elif [[ $manufacturer =~ (Dell) || $product_name =~ (Dell) ]]; then
                echo "===>                            ------------------                                            <==="
                echo " This is $manufacturer device "
                echo "===>                            ------------------                                            <==="
                echo ""
                  # Add set of commands for DELL

                elif [[ $manufacturer =~ (VMware) || $product_name =~ (VMware) ]]; then
                echo "===>                            ------------------                                            <==="
                echo "This is $manufacturer device"
                echo "===>                            ------------------                                            <==="
                echo ""
                    # Add set of commands for Vmware

                else
                        echo "===>                            ------------------                                            <==="
                        echo "This device is $manufacturer and is Virtual"
                        echo "===>                            ------------------                                            <==="
                        echo ""
                        # Seems we do not need to worry about as it is cloud devices
        fi
fi
}

##---------------------------------------------------------------------------------------------------------------##
# This is a Function to gather Raid details for HP and DELL Devices
## --------------------------------------------------------------------------------------------------------------##


f_storage_details() {

f_for_hp() {
# Function to check if a command is available
command_exists() {
  command -v "$1" >/dev/null 2>&1
}
    # Check if device has HP Smart Storage RAID configured
    if command_exists "ssacli" && ssacli ctrl all show config | grep -q "logicaldrive"; then
        echo "Device $device has HP Smart Storage RAID configured."

                echo "=== FirmWare check ==="
                hpasmcli -s "show server"
                echo -e "\n"
                echo -e "\n=== Find the RAID controller ==="
                ssacli controller all show
                echo -e "\n"
                slot_d=$(ssacli controller all show|awk '{print $6}'|grep "\S")
                echo -e "\n=== View Occupied and Empty Drive Bays ==="
                        ssacli controller slot=$slot_d enclosure all show detail
                echo -e "\n"
                echo -e "\n===View Virtual Disks ==="
                ssacli controller slot=$slot_d logicaldrive all show
                echo -e "\n"
                echo -e "\n===View Physical Disks ==="
                ssacli controller slot=$slot_d physicaldrive all show
                echo -e "\n"
    fi

}


f_for_Dell() {
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

    if command_exists "omreport" && omreport storage controller > /dev/null; then
        echo "Device $device has Dell PERC RAID configured (using omreport)."
        echo "=== FirmWare check ==="
                omreport system version
                echo -e "\n"
                echo -e "\n=== Find the RAID controller ==="
                omreport storage controller|egrep -w "^ID|^Status|^Name|^Slot ID|^State|^Firmware Version|^Driver Version" |sed  '/Driver Version/a ========================='
                ctrl_id=$(omreport storage controller|grep -w ^ID|awk '{print $3}')
                echo -e "\n"
                echo -e "\n=== View Occupied and Empty Drive Bays ==="
                omreport storage controller controller=$ctrl_id info=pdslotreport | head -n 8
                echo -e "\n"
                echo -e "\n===View Virtual Disks ==="
                omreport storage vdisk|egrep -w "^ID|Name|Layout|Size|Device Name"|sed  '/Device Name/a ========================='|grep -v "Stripe Element Size"
                echo -e "\n"
                echo -e "\n===View Physical Disks ==="
                omreport storage pdisk controller=$ctrl_id|egrep -w "^ID|^Status|^Name|^State"| sed  '/State/a ========================='
                echo -e "\n"
    fi

}



f_find_hba() {
if [[ $(lspci | grep -i fibre 2>&1) ]]; then

echo -e "\n=====#########################################"
echo -e "\n=====    These are Details Of HBA          ==="
echo -e "\n=====#########################################"


    if ! command -v systool >/dev/null; then

    # find out the hba details
                for hba in `ls -d /sys/class/fc_host/host*`;do
            portmodel=$(awk '{print $1}' $hba/symbolic_name)
            portid=$(cat $hba/port_id)
            portname=$(cat $hba/port_name)
            portstate=$(cat $hba/port_state)
            portspeed=$(cat $hba/speed)
            portsupportedspeed=$(cat $hba/supported_speeds)

            echo -e "\n==================== $(ls -d $hba|awk -F'[/=]' '{print $5}') ===================="
            echo "HBA Model : $portmodel"
            echo "HBA PORTID : $portid"
            echo "HBA WWPN : $portname"
            echo "HBA State : $portstate"
            echo "HBA State: $portspeed"
            echo "HBA Suported Speed : $portsupportedspeed"
            echo -e "\n"
        done
    else
        systool -a -v -c scsi_host | egrep "Class Device|model|version|proc_name|info|fwrev"
        echo -e "\n==================== ===================="

fi
else
        echo -e "\n"
        echo "== HBA Not Found on this server =="
        echo -e "\n"

fi
}


f_find_dell_hp() {
# Function to check if a command is available
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to check if a device is Dell
is_dell_device() {
  echo $manufacturer | grep -iq "dell"
}

# Function to check if a device is HP
is_hp_device() {
  echo $manufacturer | grep -iq "hp"
}

is_vmware_device() {
  echo $manufacturer | grep -iq "vmware"
}

is_cloud_device() {
  echo $manufacturer | egrep -ivq "dell|hp|vmware"
}

# Iterate through all block devices
    # Check if device is Dell
    if is_dell_device; then

                f_for_Dell
                f_find_hba

    #fi

    # Check if device is HP
    elif is_hp_device; then

                f_for_hp
                f_find_hba

    #fi

    elif is_vmware_device; then

             f_find_hba

    #fi

    elif is_cloud_device; then
        echo ""
        echo -e "\n=== Disk Related information ==="
        lsblk
        fi
}


# Iterate through all block devices

f_find_dell_hp


    # Check if device has EMC PowerPath (emcpower)
if [[ $(sudo powermt display dev=all 2>/dev/null | grep "emcpower") ]]; then
        echo "Device $device has EMC PowerPath (emcpower) configured." 2>&1 > $dir_to_store/All_server_details/powermnt_displya_all.txt
                echo "=== SAN Storage check ===" 2>&1 >> $dir_to_store/All_server_details/powermnt_displya_all.txt
                powermt display dev=all | egrep "^Pseudo|^Device"  2>&1 >> $dir_to_store/All_server_details/powermnt_displya_all.txt
                echo -e "\n" 2>&1 >> $dir_to_store/All_server_details/powermnt_displya_all.txt
                powermt display dev=all | egrep 'Pseudo|Logical' | sed 'N; s/\n/ =/' | cut -d '=' -f2,4 | tr -s "=" " " 2>&1 >> $dir_to_store/All_server_details/powermnt_displya_all.txt
                echo -e "\n" 2>&1 >> $dir_to_store/All_server_details/powermnt_displya_all.txt
                echo "=== Details of all disks ===" 2>&1 >> $dir_to_store/All_server_details/powermnt_displya_all.txt
                echo -e "\n" 2>&1 >> $dir_to_store/All_server_details/powermnt_displya_all.txt
                powermt display dev=all 2>&1 >> $dir_to_store/All_server_details/powermnt_displya_all.txt

    elif [[ $(sudo multipath -ll "$device" 2>/dev/null | grep "dm-") ]]; then
        echo "Device $device has multipath configured." 2>&1 > $dir_to_store/All_server_details/Multipath_details.txt
                echo "=== If Multipath ===" 2>&1 >> $dir_to_store/All_server_details/Multipath_details.txt
                multipath -ll | grep ^mpath 2>&1 >> $dir_to_store/All_server_details/Multipath_details.txt
                echo -e "\n" 2>&1 >> $dir_to_store/All_server_details/Multipath_details.txt
    fi

}


##---------------------------------------------------------------------------------------------------------------##
# This is Function for checking Holland Configuration
## --------------------------------------------------------------------------------------------------------------##

f_holland(){
if ! command -v holland >/dev/null; then
        echo -e "\n=== Holland Is not installed on this device ==="
        echo ""

        else
         hconf_file="/etc/holland/holland.conf"
         conf_dir="/etc/holland"
         backupset=$(grep -w backupsets $hconf_file|grep -v "#"|grep "\S"|awk -F'[=]' '{print $2}'|tr -d "[:blank:]")

        if [[ "$(ls -A /etc/holland/backupsets/$backupset.conf 2>/dev/null)" ]]; then

         backup_directory=$(grep -w backup_directory $hconf_file|grep -v "#"|grep "\S"|awk -F'[=]' '{print $2}'|tr -d "[:blank:]")
         Log_file=$(grep -w filename $hconf_file|grep -v "#"|grep "\S"|awk -F'[=]' '{print $2}'|tr -d "[:blank:]")
         h_plugin=$(grep "^plugin" $conf_dir/backupsets/$backupset.conf|awk -F'[=]' '{print $2}'|tr -d "[:blank:]")
         conf_dir="/etc/holland"


         echo ""
         echo -e "\n=== Holland Details ==="
         echo "Holland Configuration file:== $hconf_file =="
         echo "Holland Backup to store is at :== $backup_directory =="
         echo "Holland backupset Configured in :== $conf_dir/backupsets/$backupset.conf =="
         echo "HOlland Log File :== $Log_file =="

         echo -e "\n=== Below Are some Values that might be helpful for you ==="
         echo ""
         egrep "plugin|backups-to-keep|auto-purge-failures|purge-policy|estimated-size-factor|additional-options|exclude" $conf_dir/backupsets/$backupset.conf 2>/dev/null|grep -v "#"|grep "\S"
         echo -e "\n"

         echo -e "\n=== Data from the Providers file ==="
         echo ""
         grep -v "#" $conf_dir/providers/$h_plugin.conf|grep "\S"

        else
                echo ""
                echo "== Holland is configured on the device but looks there is no backupset configured =="
                echo ""

fi
fi
}

##---------------------------------------------------------------------------------------------------------------##
# This is a Function to gather Information about the backups running on Devices#
## --------------------------------------------------------------------------------------------------------------##


#!/bin/bash
f_check_backup() {

        f_check_commvault() {

                if ! command -v simpana >/dev/null; then
                        echo "Looks the Server is not configured with the Commvault- Check For Server SKU"
                        #exit 1
                else
                        echo "=== Commvault Status ==="
                        simpana status
                        echo -e "\n===                     ==="
                        echo "=== Instance List ==="
                        simpana -all list
                fi
                }


        f_check_driveclient() {

                if ! command -v driveclient >/dev/null; then
                        echo "Looks the Server is not configured with the driveclient backup Agent"
                        #exit 1
                else
                        echo ""
                        echo "== Drivecleint is installed on the server ==="
                        echo -e "\n=== Below are the excluded Directories =="
                        sed -n '/Exclusions/, /\]/p' /var/log/driveclient.log|grep Pattern|sort -u|tr -d "[:blank:]"|awk -F ':' '{print $2}'|cut -d '"' -f2

                fi

                }

# Check if the device is physical or virtual
if [[ $manufacturer =~ (VMware|Dell|HP) || $product_name =~ (VMware|Dell|HP) ]]; then

    f_check_commvault

elif [[ $manufacturer =~ Xen || $product_name =~ Xen ]]; then

        f_check_driveclient


else
        echo "== This Script is desined for VMware/Dell/HP/Xen, Please go for Other Tools to check for AWS/GCP/Azure"
fi


}


##---------------------------------------------------------------------------------------------------------------##
# This is a function for getting cron jobs from the device.
## --------------------------------------------------------------------------------------------------------------##

f_cronjob_all() {
print_user_cron_details_debian() {
    local user="$1"
    local cron_file="/var/spool/cron/crontabs/$user"

    if [ -f "$cron_file" ]; then
        echo "=== Cron jobs for user: $user ==="
        echo "-----------------------------"
        cat "$cron_file"|grep -v "#"|grep "\S"
        echo "-----------------------------"
        echo
    #else
    #    echo "No cron jobs found for user: $user"
    fi
}

print_user_cron_details_redhat() {
    local user="$1"
    local cron_file="/var/spool/cron/$user"

    if [ -f "$cron_file" ]; then
        echo "=== Cron jobs for user: $user ==="
        echo "-----------------------------"
        cat "$cron_file"|grep -v "#"|grep "\S"
        echo "-----------------------------"
        echo
    #else
    #    echo "No cron jobs found for user: $user"
    fi
}

if [ -d "/etc/cron.d" ]; then
    # Print system-wide cron jobs from /etc/cron.d
    echo -e "\n=== System-wide cron jobs (/etc/cron.d): ==="
    echo
    echo "-----------------------------"
    for cron_file in /etc/cron.d/*; do
        echo "File: $cron_file"
        echo "-----------------------------"
        cat "$cron_file"|grep -v "#"|grep "\S"
        echo "-----------------------------"
        echo ""
    done
    echo
fi


if [ -d "/var/spool/cron/crontabs" ]; then
   # Print system-wide cron jobs from /etc/crontab
   echo -e "\n=== System-wide cron jobs (/etc/crontab): ==="
   echo
    echo "----------------------------"
    cat /etc/crontab|grep -v "#"|grep "\S"
    echo "-----------------------------"
    echo

     echo "---------------------------------------------------------------------------------------------------------"
        echo " === User-specific cron jobs: === "
        echo ""

# Loop through all users and print their cron jobs
    for user in $(cut -f1 -d: /etc/passwd); do
    print_user_cron_details_debian "$user"
    done

     echo "-----------------------------"
    else

        # Print system-wide cron jobs from /etc/crontab
        echo -e "\n=== System-wide cron jobs (/etc/crontab): ==="
        echo
    echo "-----------------------------"
    cat /etc/crontab|grep -v "#"|grep "\S"
    echo "-----------------------------"
    echo


     echo "---------------------------------------------------------------------------------------------------------"
        echo " === User-specific cron jobs: === "
        echo ""

# Loop through all users and print their cron jobs
        for user in $(cut -f1 -d: /etc/passwd); do
        print_user_cron_details_redhat "$user"
        done
            echo -e "\n=== ----------------------------- ==="

fi

}


##---------------------------------------------------------------------------------------------------------------##
# This is Function to collect the PCS cluster details
## --------------------------------------------------------------------------------------------------------------##


f_pcs_details() {

ps -ef |grep -v grep |grep -i corosync  > /dev/null 2>&1 && pcs status > /dev/null 2>&1
if [ "$?" == "0" ]; then
     shared_fs=$(pcs config show |grep -i Filesystem |awk -F" " '{print $2}')
     echo "           +-----------------------------------------------+
           +     PCS Shared Filesystem Details             +
           +-----------------------------------------------+"
     printf "\n"
     printf  "%-30s" "Filesystem Resource Name" "Filesystem Name" "Filesystem Total Size" "Filesystem Used Size"
     printf "\n"
    for i in $shared_fs
    do
      shared_fsname=$(df -h --output=source,size,pcent,target $(pcs resource show $i |grep -i directory |grep -oP '(?<=directory=)[^ ]*') |grep -v Size |awk -F" " '{print $4}')
      shared_fstotal=$(df -h --output=source,size,pcent,target $(pcs resource show $i |grep -i directory |grep -oP '(?<=directory=)[^ ]*') |grep -v Size |awk -F" " '{print $2}')
      shared_fsused=$(df -h --output=source,size,pcent,target $(pcs resource show $i |grep -i directory |grep -oP '(?<=directory=)[^ ]*') |grep -v Size |awk -F" " '{print $3}')
      printf "%-30s" "$i" "$shared_fsname" "$shared_fstotal" "$shared_fsused"
      printf "\n"
    done
    printf "\n"
    echo "           +-----------------------------------------------+
           +     PCS Resource  Details                     +
           +-----------------------------------------------+"
    printf "\n"
    pcs resource show

#VIP Details
    printf "\n"
    shared_vip=$(pcs config show |grep -i IPaddr2 |awk -F" " '{print $2}')
    echo "           +-----------------------------------------------+
           +     PCS Shared VIP/IP Details                 +
           +-----------------------------------------------+"
    printf  "%-30s" "VIP Name" "VIP IP"
    printf "\n"
    for i in $shared_vip
    do
     shared_vip_ip=$(pcs resource show $i |grep -i ip |grep -oP '(?<=ip=)[^ ]*')
     printf "%-30s" "$i" "$shared_vip_ip"
     printf "\n"
    done

#NFS Resource Details

     nfs_share=$(pcs config show |grep -i exportfs |awk -F" " '{print $2}')
     echo "           +-----------------------------------------------+
           +     PCS NFS Export Resource Details           +
           +-----------------------------------------------+"
     printf "\n"
     printf  "%-30s" "NFS Resource Name" "Export Name" "Export Range"
     printf "\n"
    for i in $nfs_share
    do
      export_name=$(pcs resource show $i |grep -i directory |grep -oP '(?<=directory=)[^ ]*')
      export_range=$(pcs resource show $i |grep -i clientspec |grep -oP '(?<=clientspec=)[^ ]*')
      printf "%-30s" "$i" "$export_name" "$export_range"
      printf "\n"
    done


#Constraint Details

    printf "\n"
    echo "           +-----------------------------------------------+
           +     PCS Resource Constraint Details           +
           +-----------------------------------------------+"
    printf "\n"
    pcs constraint show --full |grep -v cli-prefer

#Stonith / Fence Device Details

stonith_device=$(pcs stonith show|awk -F" " '{print $1}')
     echo "           +-----------------------------------------------+
           +     PCS Stonith Device Details                +
           +-----------------------------------------------+"
     printf "\n"
     printf  "%-30s" "Stonith Device Name" "Stonith Device IP"
     printf "\n"
     for i in $stonith_device
     do
       stonith_ip=$(pcs stonith show $i 2>/dev/null |grep -i ipaddr |grep -oP '(?<=ipaddr=)[^ ]*')
       printf "%-30s" "$i" "$stonith_ip" 2>/dev/null
       printf "\n"
     done


else
     echo "           +-----------------------------------------------+
           +     PCS Cluster not running in this Server    +
           +-----------------------------------------------+"

fi

}



##---------------------------------------------------------------------------------------------------------------##
# This is a Function to Check the iptables rule
## --------------------------------------------------------------------------------------------------------------##

f_iptables_check() {
# Function to check if iptables service is running
is_iptables_running() {
    service iptables status >/dev/null 2>&1
    return $?
}

# Function to get the active rules from /etc/iptables/
get_active_rules() {
   iptables-save
}

# Check if iptables service is running
if is_iptables_running; then
        echo "==="
    echo -e "\n===iptables service is running.==="
    echo

    # Get the active rules
    active_rules=$(get_active_rules)

    if [ -n "$active_rules" ]; then
        echo "=== Active iptables rules: === "
        echo "-----------------------------"
        echo "$active_rules"
        echo "-----------------------------"
    else
        echo "No active iptables rules found."
    fi
else
    echo -e "\n=== iptables service is not running.==="
        echo
fi

}

##---------------------------------------------------------------------------------------------------------------##
# This is a Function That will collect the UFW and Firewall Details
## --------------------------------------------------------------------------------------------------------------##

f_firewalld_details() {
# Check Linux distribution
get_linux_distro() {
  if [ -f /etc/redhat-release ]; then
    echo "rhel"
  elif [ -f /etc/os-release ]; then
    source /etc/os-release
    echo "$ID"
  elif [ -f /etc/lsb-release ]; then
    source /etc/lsb-release
    echo "$DISTRIB_ID"

  elif [ -f /etc/SuSE-release ]; then
    echo "sles"
  else
    echo "Unsupported"
  fi
}

# Get Linux distribution
linux_distro=$(get_linux_distro)

if [[ $linux_distro =~ ubuntu ||  $linux_distro =~ debian ]]; then

        echo "SERVER LEVEL FIREWALLS :"
        echo "------------------------"
        echo ""

        echo "UFW SERVICE :"
        echo "---------"
        echo ""
        ufw status numbered

elif [[ $linux_distro =~ rhel ]]; then

        if ! command -v firewall-cmd  >/dev/null; then
        echo
        echo -e "=== Firewalld Service is not Present ==="
        echo
        else
        echo -e "\n=== Service Staus: \n==="
        if systemctl is-active --quiet firewalld; then
        echo -e "=== FIREWALLD service is RUNNING ==="
        echo -e "\nFireawlld Rules of Public Zone:\n"
        firewall-cmd --permanent --list-all

        echo "================================================================================="

        echo -e "\nFireawlld Rules of All Zone:\n"
        firewall-cmd --permanent --list-all-zone



        else
        echo -e "=== FIREWALLD service is not RUNNING or Not available ==="
        echo



        fi
        fi
fi
}



##---------------------------------------------------------------------------------------------------------------##
# This is a Function to get the status of Fail2ban Service.
## --------------------------------------------------------------------------------------------------------------##


f_fail2ban() {

if ! command -v fail2ban-client >/dev/null; then
        echo "==========================================="
        echo -e "\n=== Fail2ban Is Not Install on this device ==="
        echo
else
# Function to check if Fail2Ban service is running
is_fail2ban_running() {
    fail2ban-client ping >/dev/null 2>&1
    return $?
}

# Function to get the active jail from Fail2Ban
get_active_jail() {
    active_jail=$(fail2ban-client status | grep "Jail list" | awk -F ":" '{print $2}' | tr -d '[:space:]')
    echo "$active_jail"
}

# Check if Fail2Ban service is running
if is_fail2ban_running; then
    echo "Fail2Ban is running."
    echo

    # Get the active jail
    active_jail=$(get_active_jail)

    if [ -n "$active_jail" ]; then
        echo "Active jail: $active_jail"
    else
        echo "No active jail found."
    fi
else
    echo "Fail2Ban is not running."
fi

fi

echo -e "\nFAIL2BAN SERVICE :"
echo -e  "------------------\n"

}



##---------------------------------------------------------------------------------------------------------------##
# This is a Function to get all the Logrotate informations
## --------------------------------------------------------------------------------------------------------------##


f_logrotate_details() {
# Function to display the contents of logrotate configuration files
display_logrotate_config() {
    local file="$1"
    echo "--------- $file ---------"
    cat "$file"|grep -v "#"|grep "\S"
    echo "--------------------------"
    echo
}

if command -v logrotate >/dev/null 2>&1; then

# Check if /etc/logrotate.conf file exists
if [ -f "/etc/logrotate.conf" ]; then
    echo "Logrotate configuration (/etc/logrotate.conf):"
    echo "----------------------------------------------"
    display_logrotate_config "/etc/logrotate.conf"
else
    echo "Logrotate configuration file (/etc/logrotate.conf) not found."
fi

# Check if /etc/logrotate.d/ directory exists
if [ -d "/etc/logrotate.d/" ]; then
    # Loop through all files in /etc/logrotate.d/ and display their contents
    for file in /etc/logrotate.d/*; do
        if [ -f "$file" ]; then
            echo "Logrotate configuration ($file):"
            echo "----------------------------------------------"
            display_logrotate_config "$file"
        fi
    done
else
    echo "Logrotate configuration directory (/etc/logrotate.d/) not found."
fi

else
    echo "Logrotate is not installed."
fi

}


##---------------------------------------------------------------------------------------------------------------##
# This is a Function to get Counts of the MySQL DB
## --------------------------------------------------------------------------------------------------------------##


f_mysqldbcount() {
print_fail_status() {
    echo -e "\e[31mFailed\e[0m"
}
print_notf_status() {
    echo -e "\e[31mNot Found\e[0m"
}

mysql -e 'show databases;'  > $dir_to_store/All_server_details/mysql-dbs0.txt 2>&1
if grep -q "command not found" $dir_to_store/All_server_details/mysql-dbs0.txt; then
printf "%-30s \e[95m%sMySQL command\e[0m" "[ $(print_notf_status) ]"
printf "\n"
        #echo "MySQL command didn't found"
        #break;
elif grep -q "Access denied" $dir_to_store/All_server_details/mysql-dbs0.txt; then
        printf "%-30s \e[95m%sScript couldn't login to MySQL\e[0m" "[$(print_fail_status) ]"
        printf "\n"
        #echo "Script couldn't login to MySQL. Kindly update credentials in ~/.my.cnf"
        #break;
else

printf "%-30s \e[95m%sMySQL DBs List\e[0m details has been captured " "[ $(print_ok_status) ]"
printf "\n"

echo -e "== MYSQL DATABASES FOUND ===\n" > $dir_to_store/All_server_details/MySQLDBList.txt

cat $dir_to_store/All_server_details/mysql-dbs0.txt | sed '1,1d'|egrep -vw "information_schema|mysql|performance_schema" >> $dir_to_store/All_server_details/MySQLDBList.txt
#ndb=$(wc -l $dir_to_store/All_server_details/MySQLDBcount_details.txt)
#        echo "No. of MySQL databases are $ndb"
echo ""
fi
rm -f $dir_to_store/All_server_details/mysql-dbs0.txt
}


##---------------------------------------------------------------------------------------------------------------##
# This is a Function to get the status of active service
## --------------------------------------------------------------------------------------------------------------##
f_active_service() {

f_case_service() {
# Iterate through the active services and check their versions
for service in $services; do
    version=""
    port=""

    # Check if the service has a version command
    case $service in
        "apache2")
            version=$(apache2 -v 2>&1| awk '/Apache/ {print $3}')
                port=$(ss -tlnp | awk -v service_name="apache" '$0 ~ service_name {split($4, a, ":"); print a[length(a)]}'|sort -u)
            ;;
        "nginx")
            version=$(nginx -v 2>&1 | awk -F'/' '/nginx/ {print $2}')
                port=$(ss -tlnp | awk -v service_name="nginx" '$0 ~ service_name {split($4, a, ":"); print a[length(a)]}'|sort -u)
            ;;
        "mysql"| "mariadb")
            version=$(mysql -V 2>&1 | awk '{print $5}' | sed 's/,//')
                port=$(ss -tlnp | awk -v service_name="mysql" '$0 ~ service_name {split($4, a, ":"); print a[length(a)]}'|sort -u)
            ;;
        "httpd")
            version=$(httpd -v 2>&1| awk '/Apache/ {print $3}')
                port=$(ss -tlnp | awk -v service_name="http" '$0 ~ service_name {split($4, a, ":"); print a[length(a)]}'|sort -u)
            ;;
        "redis")
            version=$(redis-server -v 2>&1|awk -F'=' '/v/ {print $2}'|cut -d ' ' -f1)
                port=$(ss -tlnp | awk -v service_name="redis" '$0 ~ service_name {split($4, a, ":"); print a[length(a)]}'|sort -u)
            ;;
#        "memcached")
#            version=$(memcached -V 2>&1|awk '/memcached/ {print $2}')
#            ;;
        "varnish")
            version=$(varnishd -V 2>&1|grep -v "Copyright"|grep -o "varnish-[0-9.]*"|awk -F'-' '{print $2}')
       port=$(ss -tlnp | awk -v service_name="varnish" '$0 ~ service_name {split($4, a, ":"); print a[length(a)]}'|sort -u|tr '\n' ' ')
            ;;
        php*)
            version=$(php -v 2>&1|grep -v "Copyright"|awk '{print $2}')
                port=$(ss -tlnp | awk -v service_name="php" '$0 ~ service_name {split($4, a, ":"); print a[length(a)]}'|sort -u)
            ;;

        # Add more service versions as needed

        # If the service doesn't have a version command, skip it
        *)
            continue
            ;;
    esac
   echo -e "\e[95mActive Service\e[0m: \e[32m$service\e[0m, \e[95mVersion\e[0m: \e[32m$version\e[0m, \e[95mPort\e[0m: \e[32m$port\e[0m"
done

}
# Find all services in active state

if ! command -v systemctl > /dev/null 2>&1; then

services=$(service --status-all|grep "is running"|awk -F'(' '{print $1}')
f_case_service

else
services=$(systemctl list-units --type=service --state=active --no-pager | awk '{print $1}'| sed -n '/UNIT/, /LOAD/{/UNIT/! {/LOAD/!p }}'|awk -F'.' '{print $1}'|grep "\S")
f_case_service
fi

}

##---------------------------------------------------------------------------------------------------------------##
# This is a Function to get the status of active service
## --------------------------------------------------------------------------------------------------------------##

f_website_running() {
# Function to check if a specific process is running
is_process_running() {
  pgrep -x "$1" >/dev/null
}

# Check for cPanel
if is_process_running "cpdavd"; then
echo
  echo "cPanel control panel is installed."
  echo
  #exit 0
fi

# Check for Plesk
if is_process_running "sw-engine" && is_process_running "sw-cp-server"; then
echo
  echo "Plesk control panel is installed."
  echo
  #exit 0
fi

# Check for DirectAdmin
if is_process_running "directadmin"; then
echo
  echo "DirectAdmin control panel is installed."
  echo
  #exit 0
fi

# Check for Webmin
if is_process_running "miniserv.pl"; then
echo
  echo "Webmin control panel is installed."
  echo
  #exit 0
fi

echo "Control panel  could not be determined or {cPanel|Plesk|DirectAdmin|Webmin} is not installed."

# Function to get status code
get_status_code() {
    local url=$1
    local status_code=$(curl -s -o /dev/null -I -w "%{http_code}" "$url")
    echo
    echo "$status_code"
    echo
}

# Function to get A record IP
get_a_record_ip() {
    local domain=$1
    local ip_address=$(dig +short "$domain" A 2>/dev/null)
    echo "$ip_address"
}

# Rest of the script remains unchanged
# ...
# Array to store website URLs
websites=()

# Check if Apache web server is running
apache_status_ht=$(pgrep httpd)
apache_status_ap=$(pgrep apache2)
# Check if Nginx web server is running
nginx_running=$(pgrep nginx)

# Check the running web server
if [[ -n "$apache_status_ht" || -n "$apache_status_ap" ]]; then
echo
    echo "Apache web server is running."
echo
    # Find website URLs from Apache configuration
    apache_sites_available="/etc/httpd"
    apache_files=$(find "$apache_sites_available" -type f -name '*.conf' 2>/dev/null)
    for file in $apache_files; do
        urls=$(grep "ServerName" "$file" 2>/dev/null| awk '{print $2}')
        websites+=($urls)
    done

    apache_sites_available="/etc/apache2"
    apache_files=$(find "$apache_sites_available" -type f -name '*.conf' 2>/dev/null)
    for file in $apache_files; do
        urls=$(grep "ServerName" "$file" 2>/dev/null| awk '{print $2}')
        websites+=($urls)
    done

# Check if Nginx web server is running
elif [[ -n "$nginx_running" ]]; then
echo
    echo "Nginx web server is running."
    echo

    if [ -f "/etc/debian_version" ]; then
        nginx_sites_available="/etc/nginx/sites-available"
        nginx_files=$(find "$nginx_sites_available" -type f -name '*.conf' 2>/dev/null)
        for file in $nginx_files; do
            urls=$(grep -E "server_name" "$file" 2>/dev/null| awk '{print $2}' | tr -d ';')
            websites+=($urls)
        done
    elif [ -f "/etc/redhat-release" ]; then
        nginx_sites_available="/etc/nginx/"
        nginx_files=$(find "$nginx_sites_available" -type f -name '*.conf' 2>/dev/null)
        for file in $nginx_files; do
#            urls=$(grep -E "server_name" "$file" 2>/dev/null| awk '{print $2}' | tr -d ';')
             urls=$(grep -hroP 'server_name\s+\K([^;]+)'  "$file"  \
      | sed -e 's/;/\n/g' -e 's/^\s*//' -e '/^\s*$/d' | grep -v "localhost" |grep -v "alias" | grep -v "_" | sort -u)
            websites+=($urls)
        done
    fi
else
echo
    echo "No web server (Apache or Nginx) is running."
echo
    #exit 1
fi



# Perform checks for each website
for website in "${websites[@]}"; do
  status_code=$(curl -s -IL $website | grep "HTTP/1" | tail -n1 | cut -c 9-15)
echo
  echo "Website: $website | Status Code: $status_code"
  echo
 #   else
  #      echo "Unable to retrieve status code."
  #  fi


# Check if the required command is available
if ! command -v whois &> /dev/null; then
    echo
    echo "whois command not found. Please install the whois package."
        echo
    #exit 1
fi

# Domain name to lookup
domain=$(echo "$website" | sed 's/^www\.//')

# Perform the WHOIS lookup and filter output for registrar and registration date
whois_output=$(whois "$domain"  2>/dev/null| grep -E 'Registrar:|Creation Date:')

# Extract registrar and registration date using sed or awk
registrar=$(echo "$whois_output" | grep 'Registrar:' | sed -e 's/Registrar: //')
registration_date=$(echo "$whois_output" | grep 'Creation Date:' | awk -F': ' '{print $2}')

# Print the WHOIS details
echo
echo
echo "WHOIS details for $domain:"
echo "Registrar: $registrar"
echo "Registration Date: $registration_date"






    # Get A record IP
    domain=$(echo "$website" 2>/dev/null| sed -e 's#https\?://##' -e 's#www\.##' -e 's#/#\n#g' | head -n 1)
    ip_address=$(get_a_record_ip "$domain")
    if [[ -n "$ip_address" ]]; then
        echo
        echo "A record IP: $ip_address"
        echo
    else
        echo
        echo "Unable to perform DNS lookup."
        echo
    fi

    echo "=================================="
done
}




##---------------------------------------------------------------------------------------------------------------##
# This is a Main Code of this Script from where all execution happens
## --------------------------------------------------------------------------------------------------------------##


if [ "$(id -u)" != "0" ] ; then
  echo "===== ======"
  echo "Please provide the current user password"
  read -s password
        if ! $(echo "$password"|sudo -S grep root /etc/sudoers > /dev/null 2>&1); then
                echo "=== This script must be run by the sudo user or the root user. Exiting... ==="
                exit 1
        else
        echo "You have the sudo rights But our script is limited to root so please login via ROOT user"
        exit 1
        fi
else
echo -e "==== \e[32mPLEASE PROVIDE THE DIRECTORY TO STORE THE DETAILS\e[0m ==== "
read dir_to_store
echo ""
mkdir -p $dir_to_store/All_server_details


# Gather System Manufacturer
#echo -e "\n=== System Manufacturer ==="
if command -v dmidecode &> /dev/null; then
        manufacturer="$(sudo dmidecode -s system-manufacturer)"
        product_name="$(sudo dmidecode -s system-manufacturer)"
        else
        product_name="$(cat /sys/class/dmi/id/sys_vendor)"
        manufacturer="$(cat /sys/class/dmi/id/sys_vendor)"
fi


# Function to print OK status in green color
print_ok_status() {
    echo -e "\e[32mDone\e[0m"
}
print_fail_status() {
    echo -e "\e[31mNot Found\e[0m"
}


echo ""
echo "Loading you data Please wait for a While In Progress ..."
#echo "In Progress ...."
#echo "In Progress ......."

### Execute the Functions now to get the details ############

f_utlization_data 2>&1 > $dir_to_store/All_server_details/utilization_from_sar.txt
printf "%-30s \e[95m%sSar data\e[0m details has been captured " "[ $(print_ok_status) ]"
printf "\n"

f_pys_virt_env 2>&1 > $dir_to_store/All_server_details/Hardware_details_dummy.txt
printf "%-30s \e[95m%sServer Platform\e[0m details has been captured " "[ $(print_ok_status) ]"
printf "\n"

f_getusers_info 2>&1 > $dir_to_store/All_server_details/user_details.txt
printf "%-30s \e[95m%sAll the user\e[0m details has been captured " "[ $(print_ok_status) ]"
printf "\n"

f_bind_and_mount 2>&1 > $dir_to_store/All_server_details/mounts_bindMounts.txt
printf "%-30s \e[95m%sGeneral Mount related\e[0m details has been captured " "[ $(print_ok_status) ]"
printf "\n"

f_fstab_bind_and_mount 2>&1 > $dir_to_store/All_server_details/findmount_fstab.txt
printf "%-30s \e[95m%sBind mount\e[0m details has been captured " "[ $(print_ok_status) ]"
printf "\n"

f_general_details 2>&1 > $dir_to_store/All_server_details/generic_details.txt
printf "%-30s \e[95m%sAll generic\e[0m details has been captured " "[ $(print_ok_status) ]"
printf "\n"

f_storage_details  2>&1 > $dir_to_store/All_server_details/Some_storage_details_physc.txt
printf "%-30s \e[95m%sStorage related\e[0m details has been captured " "[ $(print_ok_status) ]"
printf "\n"

f_check_monitoring 2>&1 > $dir_to_store/All_server_details/monitoring_details.txt
printf "%-30s \e[95m%sMonitoring\e[0m details has been captured " "[ $(print_ok_status) ]"
printf "\n"

f_holland 2>&1 > $dir_to_store/All_server_details/holland.txt
printf "%-30s \e[95m%sHolland backup\e[0m details has been captured " "[ $(print_ok_status) ]"
printf "\n"

f_check_backup 2>&1 > $dir_to_store/All_server_details/comm_drive_backup_status.txt
printf "%-30s \e[95m%sCommvault or Driveclient\e[0m details has been captured " "[ $(print_ok_status) ]"
printf "\n"

f_cronjob_all 2>&1 > $dir_to_store/All_server_details/cronjobs_details.txt
printf "%-30s \e[95m%sAll cronjobs\e[0m details has been captured " "[ $(print_ok_status) ]"
printf "\n"

f_pcs_details 2>&1 > $dir_to_store/All_server_details/pcs_cluster_details.txt
printf "%-30s \e[95m%sPCS Cluster\e[0m details has been captured " "[ $(print_ok_status) ]"
printf "\n"

f_iptables_check 2>&1 > $dir_to_store/All_server_details/iptables_details.txt
printf "%-30s \e[95m%sIptables\e[0m details has been captured " "[ $(print_ok_status) ]"
printf "\n"

f_firewalld_details 2>&1 > $dir_to_store/All_server_details/Firewalld_status_details.txt
printf "%-30s \e[95m%sFirewall\e[0m details has been captured " "[ $(print_ok_status) ]"
printf "\n"

f_fail2ban 2>&1 > $dir_to_store/All_server_details/Fail2Ban_status_details.txt
printf "%-30s \e[95m%sFail2ban\e[0m details has been captured " "[ $(print_ok_status) ]"
printf "\n"

f_logrotate_details 2>&1 > $dir_to_store/All_server_details/Logrotate_details.txt
printf "%-30s \e[95m%sLogrotate\e[0m details has been captured " "[ $(print_ok_status) ]"
printf "\n"

f_mysqldbcount
#printf "%-30s \e[95m%sMySQL DBs List\e[0m details has been captured " "[ $(print_ok_status) ]"
#printf "\n"

f_website_running 2>&1 > $dir_to_store/All_server_details/website_running_details.txt
printf "%-30s \e[95m%sWebsite Running List\e[0m details has been captured " "[ $(print_ok_status) ]"
printf "\n"

printf "%-30s \e[95m%sKnown Active Services List\e[0m details has been captured " "[ $(print_ok_status) ]"
printf "\n"
printf "\n"
f_active_service

fi

echo -e "##----------------------------------------------------------------------------------------------------------------------##"
echo -e "#  Please find the datails under folder  --> \e[32m$dir_to_store/All_server_details\e[0m ##"
echo -e "## -------------------------------------------------------------------------------------------------------------------- ##"

