# Server Migration Data Gathering Script

## 📖 Overview
This Bash script automates the collection of critical system, network, hardware, and application data from Linux servers. It is designed to assist in migration planning by generating a comprehensive, categorized inventory of the server's current state.

**Author:** Team L1  
*(Navdeep (Captain), Rohit Varshney, Ashok Kumar, Yogendra Modak, Gaurav Kumar, Godishala Rajkumar, Ishan Doye)*

## 🚀 Features
The script executes a series of modular functions to gather and export data into a specified directory. Key details collected include:

*   **System & OS:** General OS release details, kernel version, installed packages, user accounts, and `sudo` access lists.
*   **Hardware & Storage:** Virtual vs. Physical environment detection (VMware, Dell, HP, Xen), RAID configurations (`ssacli`, `omreport`), HBA details, Multipath/EMC PowerPath, standard mounts, and bind mounts (`findmnt`, `/etc/fstab`).
*   **Resource Utilization:** CPU, memory, disk, and network stats pulled via `sar` (allows checking 30-day averages or specific dates).
*   **Networking & Security:** IP/MAC addresses, routing tables, SELinux status, AppArmor, UFW/Firewalld/iptables rules, and Fail2ban configurations.
*   **Applications & Services:** Active services (Apache, Nginx, MySQL, Redis, PHP, etc.), running web control panels (cPanel, Plesk, DirectAdmin, Webmin), MySQL database lists, and website WHOIS/DNS details.
*   **Infrastructure Tools:** Monitoring agents (Rackspace, Nimbus, CloudWatch), Backup tools (Holland, Commvault, Driveclient), and High Availability PCS Cluster status.
*   **System Tasks:** Comprehensive cron job listings (system-wide and user-specific) and logrotate configurations.

## ⚙️ Prerequisites
*   **Root Access:** The script must be run directly as the `root` user. It actively checks privileges and will exit if run with standard `sudo` by a non-root user.
*   **Dependencies:** Standard Linux utilities, plus `sysstat` (required for `sar` utilization data).

## 🛠️ Usage

1. **Make the script executable:**
   ```bash
   chmod +x migration_gather.sh
