# Introduction

This Avamar script will recall backups from the Data Domain Cloud Tier. It is meant 
to be used with older versions of Avamar that are not integrated with Data Domain 
Cloud Tier.

# Installation

In order to use this script Admin Access must be configured on the Data Domain 
system. This allows a remote system with the proper ssh key to use ssh to execute 
commands on the Data Domain without a password. Next the script will need to be
installed on a system with he Avamar mccli, avmgr and ddmaint commands. The 
Avamar Utility Node, Avamar Single Node or AVE work best for this. The user that 
is used to run the script must have access to the Data Domain ssh key. 

## Configuring Admin Access for Data Domain

1. From a Linux system where the commands to recall data will be run 
   (the Avamar Utility node is a good place to do this):

	`ssh-keyen -t ecdsa`

	Leave the pass phrase blank and make note of the location to the id_ecdsa.pub file.

2. Edit the id_ecdsa.pub file and copy the contents to the clipboard.

3. Login to the console of the Data Domain as the sysadmin user.

4. Run the command:

	`adminaccess add ssh-keys`

	Paste the keys from the clipboard. Be careful not to include any trailing 
	carriage returns. Use Control-D to save the key.

5. Verify that they key was taken by running the command:

	`adminaccess show ssh-keys`

6.	Verify that Admin Access works by issuing the following command on the 
	Linux system that the ssh key was created on:

	`ssh sysadmin@<data_domain_system> filesys show status`

	The status of the Data Domain file system should be displayed.

## Install the script

1. Download and copy the `av_ddct_recall.sh` script to a location where it won't be deleted. 
   For this example we will use `/home/admin` on the Avamar server. Use the `admin` user
   on the Avamar system to do this.
	

2. Set the script to be executable. 

   `chmod 755 av_ddct_recall.sh`

3.   Verify that the ssh key created for Admin Access is installed in `/home/admin/.ssh`


# Usage

The `av_ddct_recall.sh` script can be used to locate and recall a single backup based on 
backup label number, all backups for a client or all backups for specific or all Data 
Domain systems. Care should be taken if recalling All backups since the recall process 
may take some time and incur additional charges from public cloud providers. 

## Single backup locate and recall

To locate or recall a single backup the operator must first determine the Avamar label
number of the backup. This can be done two ways.

### Identifying backup label numbers from the MCGUI

1. Start the MCGUI as a user that can browse clients for restore.

2. Select Navigation-->Backup and Restore

3. In the upper left window select the domain that the client is in.

4. In the lower left window select the client who's data needs to be recalled.

5. On the main window select the Manage tab.

6. Filter the backup list based on By day, By date range or By retention as needed.

7. In the lower part of the main window all of the filtered backups will be listed.
   Locate the backup of interest and record the number from the Number column

### Identifying backup label numbers from the MCGUI command line

1. From the command line on the Avamar Utility Node run the command:

   `mccli backup show --name=<full Avamar path to client>`
	
	Example:

    ```
	admin@ave-03:~/>: mccli backup show --name=/vc01.vlab.local/VirtualMachines/lguest-01_miniSUSE
    0,23000,CLI command completed successfully.
    Created                 LabelNum Size   Retention Hostname          Location
    ----------------------- -------- ------ --------- ----------------- --------
    2016-10-18 09:09:25 EDT 14       2.0 GB D         ave-03.vlab.local Local
    2016-10-18 03:37:22 EDT 13       2.0 GB D         ave-03.vlab.local Local
    2016-10-17 09:05:44 EDT 12       2.0 GB D         ave-03.vlab.local Local
    2016-10-16 09:07:30 EDT 11       2.0 GB DW        ave-03.vlab.local Local
    2016-10-15 09:06:05 EDT 10       2.0 GB D         ave-03.vlab.local Local
    2016-10-14 09:07:27 EDT 9        2.0 GB D         ave-03.vlab.local Local
    2016-10-13 09:07:22 EDT 8        2.0 GB D         ave-03.vlab.local Local
    2016-10-12 09:04:53 EDT 7        2.0 GB D         ave-03.vlab.local Local
    2016-10-11 09:08:34 EDT 6        2.0 GB D         ave-03.vlab.local Local
    2016-10-10 09:04:31 EDT 5        2.0 GB D         ave-03.vlab.local Local
    2016-10-09 15:51:38 EDT 4        2.0 GB D         ave-03.vlab.local Local
    2016-10-09 09:05:24 EDT 3        2.0 GB DW        ave-03.vlab.local Local
    2016-10-08 21:40:42 EDT 2        2.0 GB D         ave-03.vlab.local Local
    2016-10-07 09:05:26 EDT 1        2.0 GB DWMY      ave-03.vlab.local Local
	```

   Record the number in the LabelNum column that corresponds to the backup being 
   queried.
   
## Run `av_ddct_recall.sh` to locate or recall individual backups   

To list/query backups that are on the Data Domain Cloud Tier run the command below. If backup
files on the Data Domain are listed they are on the Cloud Tier and can be recalled.

`./av_ddct_recall.sh --label label_num --name client_path --sshid ssh_id_file --user DD_User --listonly`

Example:

```
admin@ave-03:~/>: ./av_ddct_recall.sh --label 8 --name /vc01.vlab.local/VirtualMachines/lguest-01_miniSUSE --sshid /home/admin/.ssh/id_ecdsa --user sysadmin --listonly
Searching for backup files to recall...
EMC Data Domain Virtual Edition
Listing or recalling a backup for client /vc01.vlab.local/VirtualMachines/lguest-01_miniSUSE from 14 files.
/data/col1/avamar-1456413272/cur/e05fe58850bcab7ed7dd44a7d5f967432011dfeb/1D22552BC3CAA98/C72555BBBE76E6B728343EAE9929A2CBFB0743FC
/data/col1/avamar-1456413272/cur/e05fe58850bcab7ed7dd44a7d5f967432011dfeb/1D22552BC3CAA98/F2D9844BD6D77E93B5C8BC9631699FA0A948AA87
/data/col1/avamar-1456413272/cur/e05fe58850bcab7ed7dd44a7d5f967432011dfeb/1D22552BC3CAA98/FB8EF224F27E03C510581104368A6C1D0F0D92FC
/data/col1/avamar-1456413272/cur/e05fe58850bcab7ed7dd44a7d5f967432011dfeb/1D22552BC3CAA98/7F480B1997C7EA8EC9A162EA11CD091FA870C0A1
/data/col1/avamar-1456413272/cur/e05fe58850bcab7ed7dd44a7d5f967432011dfeb/1D22552BC3CAA98/F9D5E927E61F587F14D3C86F40C7D8DEDD48B1F0
/data/col1/avamar-1456413272/cur/e05fe58850bcab7ed7dd44a7d5f967432011dfeb/1D22552BC3CAA98/D64EFFD14C0F546E848CED817D759DCFC7C15381
/data/col1/avamar-1456413272/cur/e05fe58850bcab7ed7dd44a7d5f967432011dfeb/1D22552BC3CAA98/7612CA7CF36C38CEBDB207CD0BB05F1013E0281E
/data/col1/avamar-1456413272/cur/e05fe58850bcab7ed7dd44a7d5f967432011dfeb/1D22552BC3CAA98/ED90E3F13AA5DE8D68DA567F28DCAB194D0553FA
/data/col1/avamar-1456413272/cur/e05fe58850bcab7ed7dd44a7d5f967432011dfeb/1D22552BC3CAA98/ED90E3F13AA5DE8D68DA567F28DCAB194D0553FA.trace
/data/col1/avamar-1456413272/cur/e05fe58850bcab7ed7dd44a7d5f967432011dfeb/1D22552BC3CAA98/91CD6F915C4CC01F2C3F4743698E99EE6DC12EDA
/data/col1/avamar-1456413272/cur/e05fe58850bcab7ed7dd44a7d5f967432011dfeb/1D22552BC3CAA98/7F014F9CDDCB11515755E3741F7EFC29C86A257D
/data/col1/avamar-1456413272/cur/e05fe58850bcab7ed7dd44a7d5f967432011dfeb/1D22552BC3CAA98/0CD5C4400901EB16E5A32CF7B15367465B24B0D7
/data/col1/avamar-1456413272/cur/e05fe58850bcab7ed7dd44a7d5f967432011dfeb/1D22552BC3CAA98/0CD5C4400901EB16E5A32CF7B15367465B24B0D7.trace
/data/col1/avamar-1456413272/cur/e05fe58850bcab7ed7dd44a7d5f967432011dfeb/1D22552BC3CAA98/v2_ddr_files.xml
```

To recall the backup from the Data Domain run:

  `./av_ddct_recall.sh --label label_num --name client_path --sshid ssh_id_file --user DD_User`

Example:

```
admin@ave-03:~/>: ./av_ddct_recall.sh --label 8 --name /vc01.vlab.local/VirtualMachines/lguest-01_miniSUSE --sshid /home/admin/.ssh/id_ecdsa --user sysadmin
Searching for backup files to recall...
EMC Data Domain Virtual Edition
Listing or recalling a backup for client /vc01.vlab.local/VirtualMachines/lguest-01_miniSUSE from 14 files.
EMC Data Domain Virtual Edition
Recall started for "/data/col1/avamar-1456413272/cur/e05fe58850bcab7ed7dd44a7d5f967432011dfeb/1D22552BC3CAA98/C72555BBBE76E6B728343EAE9929A2CBFB0743FC". Run the status command to monitor its progress.
EMC Data Domain Virtual Edition
Recall started for "/data/col1/avamar-1456413272/cur/e05fe58850bcab7ed7dd44a7d5f967432011dfeb/1D22552BC3CAA98/F2D9844BD6D77E93B5C8BC9631699FA0A948AA87". Run the status command to monitor its progress.
EMC Data Domain Virtual Edition
Recall started for "/data/col1/avamar-1456413272/cur/e05fe58850bcab7ed7dd44a7d5f967432011dfeb/1D22552BC3CAA98/FB8EF224F27E03C510581104368A6C1D0F0D92FC". Run the status command to monitor its progress.
EMC Data Domain Virtual Edition
Recall started for "/data/col1/avamar-1456413272/cur/e05fe58850bcab7ed7dd44a7d5f967432011dfeb/1D22552BC3CAA98/7F480B1997C7EA8EC9A162EA11CD091FA870C0A1". Run the status command to monitor its progress.
EMC Data Domain Virtual Edition
Recall started for "/data/col1/avamar-1456413272/cur/e05fe58850bcab7ed7dd44a7d5f967432011dfeb/1D22552BC3CAA98/F9D5E927E61F587F14D3C86F40C7D8DEDD48B1F0". Run the status command to monitor its progress.
EMC Data Domain Virtual Edition
Recall started for "/data/col1/avamar-1456413272/cur/e05fe58850bcab7ed7dd44a7d5f967432011dfeb/1D22552BC3CAA98/D64EFFD14C0F546E848CED817D759DCFC7C15381". Run the status command to monitor its progress.
EMC Data Domain Virtual Edition
Recall started for "/data/col1/avamar-1456413272/cur/e05fe58850bcab7ed7dd44a7d5f967432011dfeb/1D22552BC3CAA98/7612CA7CF36C38CEBDB207CD0BB05F1013E0281E". Run the status command to monitor its progress.
EMC Data Domain Virtual Edition
Recall started for "/data/col1/avamar-1456413272/cur/e05fe58850bcab7ed7dd44a7d5f967432011dfeb/1D22552BC3CAA98/ED90E3F13AA5DE8D68DA567F28DCAB194D0553FA". Run the status command to monitor its progress.
EMC Data Domain Virtual Edition
Recall started for "/data/col1/avamar-1456413272/cur/e05fe58850bcab7ed7dd44a7d5f967432011dfeb/1D22552BC3CAA98/ED90E3F13AA5DE8D68DA567F28DCAB194D0553FA.trace". Run the status command to monitor its progress.
EMC Data Domain Virtual Edition
Recall started for "/data/col1/avamar-1456413272/cur/e05fe58850bcab7ed7dd44a7d5f967432011dfeb/1D22552BC3CAA98/91CD6F915C4CC01F2C3F4743698E99EE6DC12EDA". Run the status command to monitor its progress.
EMC Data Domain Virtual Edition
Recall started for "/data/col1/avamar-1456413272/cur/e05fe58850bcab7ed7dd44a7d5f967432011dfeb/1D22552BC3CAA98/7F014F9CDDCB11515755E3741F7EFC29C86A257D". Run the status command to monitor its progress.
EMC Data Domain Virtual Edition
Recall started for "/data/col1/avamar-1456413272/cur/e05fe58850bcab7ed7dd44a7d5f967432011dfeb/1D22552BC3CAA98/0CD5C4400901EB16E5A32CF7B15367465B24B0D7". Run the status command to monitor its progress.
EMC Data Domain Virtual Edition
Recall started for "/data/col1/avamar-1456413272/cur/e05fe58850bcab7ed7dd44a7d5f967432011dfeb/1D22552BC3CAA98/0CD5C4400901EB16E5A32CF7B15367465B24B0D7.trace". Run the status command to monitor its progress.
EMC Data Domain Virtual Edition
Recall started for "/data/col1/avamar-1456413272/cur/e05fe58850bcab7ed7dd44a7d5f967432011dfeb/1D22552BC3CAA98/v2_ddr_files.xml". Run the status command to monitor its progress.
EMC Data Domain Virtual Edition
Data-movement to cloud tier:
----------------------------
Data-movement was started on Oct 17 2016 22:15 and completed on Oct 17 2016 22:20
Copied (post-comp): 36.70 MiB, (pre-comp): 104.00 GiB,
Files copied: 212, Files verified: 212, Files installed: 212

Data-movement recall:
---------------------
No recall operations running.
```

## Recalling all data for a client

To recall all data for a client run the command:

`./av_ddct_recall.sh --all --name client_path --sshid ssh_id_file --user DD_User`
 
 
Example:
 
`admin@ave-03:~/>: ./av_ddct_recall.sh --all --name /vc01.vlab.local/VirtualMachines/lguest-01_miniSUSE --sshid /home/admin/.ssh/id_ecdsa --user sysadmin`

## Recalling all data on all Data Domains

To recall all data that Avamar has backed up on all configured Data Domains run:

`./av_ddct_recall.sh --all --sshid ssh_id_file --user DD_User`

Example:

`admin@ave-03:~/>: ./av_ddct_recall.sh --all --sshid /home/admin/.ssh/id_ecdsa --user sysadmin`

# Compatibility

This script was created and tested using Avamar Virtual Edition v7.2.1-32. 