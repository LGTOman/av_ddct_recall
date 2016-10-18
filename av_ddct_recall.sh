#!/bin/bash

AVAMARPATH=/usr/local/avamar/bin
MCCLI=$AVAMARPATH/mccli
AVMGR=$AVAMARPATH/avmgr
DDRMAINT=$AVAMARPATH/ddrmaint

#CLIENTPATH=/vc01.vlab.local/VirtualMachines/lguest-01_miniSUSE
#SSHID=/home/admin/.ssh/id_ecdsa
#DDRUSER=sysadmin
#DDRHOST=ddve-01
#CLOUDUNIT=ECS-LSS-Engineering
#LABELNUM=1

usage () {
  echo
  echo Usage: $0 --all --sshid ssh_id_file --user DD_User [--ddr DD_Host] [--listonly] [--debug]
  echo
  echo Usage: $0 --all --name client_path --sshid ssh_id_file --user DD_User [--ddr DD_Host] [--listonly] [--debug]
  echo
  echo Usage: $0 --label label_num --name client_path --sshid ssh_id_file --user DD_User [--ddr DD_Host] [--listonly] [--debug]
  echo
  echo Usage: $0 -?\|-h\|--help 
  echo
  echo "--all                          Recall all backups for the clien if --nanme is specified."
  echo "                               Otherwise recall all files for the Data Domain spedfied by --ddr."
  echo "                               Otherwise recall all files for all Data Domains if --ddr is not specified."
  echo "--cloudunit cloud_unit_name    Specifies the cloud unit where the backups reside to search."
  echo "--label label_num              Recall a single backup based on the "
  echo "                               backup label number specified by label_num."
  echo "                                 NOTE: Consult the README.MD file for instructions on how to lookup "
  echo "                                       backup label numbers."
  echo "--listonly                     Only lists files to be recalled on the Data Domain. No recall occurs."
  echo "--name client_path             Specifies the full Avamar domain path to the client being recalled. "
  echo "                                 Example: /clients/sql-01"
  echo "--sshid ssh_id_file            Specifies the full path to the sshid file to use with Admin Access "
  echo "                               for the Data Domain"
  echo "                                 NOTE: It is reqiured to specify the sshid file otherwise the Avamar "
  echo "                                       server may inspect a local one that requires a password. The "
  echo "                                       ssh ID file is the one generated for Admin Acess to work on "
  echo "                                       the Data Domain."
  echo "--user DD_User                 Specfies the name of the Data Domain user to use to execute commands"
  echo "                               on the Data Domain with."
  echo
}

while [ $# -gt 0 ]; do 
  case "$1" in
    --all)
      ALL=TRUE
      ;;
    --debug)
      DEBUG=Y
      ;;
    --ddr)
      DDRHOSTS="$2"
      shift
      ;;
    --label)
      LABELNUM="$2"
      shift
      ;;
    --listonly)
      LISTONLY=TRUE
      ;;
    --name)
      CLIENTPATH="$2"
      shift
      ;;
    --sshid)
      SSHID="$2"
      shift
      ;;
    --user)
      DDRUSER="$2"
      shift
      ;;
    -?|-h|--help)
      usage
      exit
      ;; 
  esac
  shift
done

if [ "$ALL" == "TRUE" ] && [ "$LABELNUM" != "" ]; then
  echo
  echo ERROR: Conflicting options specified. --all and --label not allowed in the same command. 
  usage
  exit 1
elif [ "$ALL" == "FALSE" ] && [ "$LABELNUM" == ""  ]; then 
  echo
  echo ERROR: One of --all or --label must be specified.
  usage
  exit 1
elif [ "$CLIENTPATH" == "" ] && [ "$ALL" == "FALSE" ]; then
  echo
  echo ERROR: --name must be specified
  usage
  exit 1
elif [ "$SSHID" == "" ]; then
  echo
  echo ERROR: --sshid must be specified
  usage
  exit 1
elif [ "$DDRUSER" == "" ]; then
  echo
  echo ERROR: --user must be specified
  usage
  exit 1
fi

if [ "$ALL" == "TRUE" ]; then
  echo About to recall all backups for a client or Data Domain\(s\).
  echo This operation may take sigifigant time and space.
  echo It may also incur additinal charges from public cloud providers.
  echo Are you sure you want to proceed? \(YES/[NO]\)
  read ANSWER
  if [ "$ANSWER" != "YES" ]; then
    echo Canceling...
    exit 2
  fi
fi

echo Searching for backup files to recall...
DPNID=$(ddrmaint read-ddr-info | grep dpnid | cut -d \" -f 2)
AVAMARMTREE=/data/col1/avamar-$DPNID
if [ "$ALL" == "TRUE" ] && [ "$DDRHOSTS" == "" ];then 
  DDRHOSTS="$($DDRMAINT read-ddr-info | grep hostname | awk -F \" '{print $14}')"
elif  [ "$DDRHOSTS" == "" ]; then
  DDRHOSTS=$($MCCLI backup show --name=/vc01.vlab.local/VirtualMachines/lguest-01_miniSUSE --verbose=true | grep " $LABELNUM " | awk -F " " '{print $NF}')
fi

if [ "$CLIENTPATH" != "" ]; then
  CLIENTCONTAINER=$(dirname $CLIENTPATH)
  CID=$($MCCLI client show --name=$CLIENTPATH --verbose=true | grep CID | grep -v Assigned | awk '{print $2}')
  LONGCLIENTPATH=$($AVMGR getm --path=$CLIENTCONTAINER | grep $CID | awk '{print $2}') 
  HEXBACKUPTIME=$($AVMGR getb --path=$CLIENTCONTAINER/$LONGCLIENTPATH --format=xml | grep labelnum=\"$LABELNUM\" | cut -d = -f 12| cut -d x -f 2 | cut -d \" -f 1 | tr '[:lower:]' '[:upper:]')
fi

let REPEAT=1

for DDRHOST in $DDRHOSTS; do
  while [ $REPEAT -ne 0 ]; do 
    let REPEAT=0
#    for FILE in $(ssh -i $SSHID $DDRUSER@$DDRHOST filesys report generate file-location path $AVAMARMTREE | grep $CID | grep $HEXBACKUPTIME | grep $CLOUDUNIT | awk '{print $1}'); do
    OLDIFS=$IFS
    IFS=$'\n'
    if [ "$ALL" == "TRUE" ] && [ "$CID" != "" ];then
      FILES=($(ssh -i $SSHID $DDRUSER@$DDRHOST filesys report generate file-location path $AVAMARMTREE | grep -v Active | grep $CID | awk '{$NF=""}1'| grep $AVAMARMTREE))
      if [ ${#FILES[@]} -lt 1 ]; then
        echo No backup files to recall. All backup files may be on the Active teir.
        echo Exiting...
        exit 3
      fi
      echo About to recall all backups for client $CLIENTPATH from ${#FILES[@]} files.
      echo Are you really sure you want to proceed? \(YES/[NO]\)
      read ANSWER
      if [ "$ANSWER" != "YES" ]; then
        echo Canceling...
        exit 2
      fi
    elif [ "$ALL" == "TRUE" ];then
#      FILES=($(ssh -i $SSHID $DDRUSER@$DDRHOST filesys report generate file-location path $AVAMARMTREE | grep -v Active | awk '{print $1}' | grep $AVAMARMTREE))
      FILES=($(ssh -i $SSHID $DDRUSER@$DDRHOST filesys report generate file-location path $AVAMARMTREE | grep -v Active | awk '{$NF=""}1' | grep $AVAMARMTREE))
      if [ ${#FILES[@]} -lt 1 ]; then
        echo No backup files to recall. All backup files may be on the Active teir.
        echo Exiting...
        exit 3
      fi
      echo About to recall all backups for Data Domain $DDRHOST from ${#FILES[@]} files.
      echo Are you really sure you want to proceed? \(YES/[NO]\)
      read ANSWER
      if [ "$ANSWER" != "YES" ]; then
        echo Canceling...
        exit 2
      fi
    else
      FILES=($(ssh -i $SSHID $DDRUSER@$DDRHOST filesys report generate file-location path $AVAMARMTREE | grep -v Active | grep $CID | grep $HEXBACKUPTIME | awk '{$NF=""}1'))
      if [ ${#FILES[@]} -lt 1 ]; then
        echo No backup files to recall. All backup files may be on the Active teir.
        echo Exiting...
        exit 3
      fi
      echo Listing or recalling a backup for client $CLIENTPATH from ${#FILES[@]} files.
    fi
    for ((FILE=0; FILE<${#FILES[@]}; FILE++)); do
      if [ "$LISTONLY" == "TRUE" ]; then
        echo "${FILES[$FILE]}"
      else
        ssh -i $SSHID $DDRUSER@$DDRHOST data-movement recall path "${FILES[$FILE]}"
      fi
      RC=$?
      if [ "$DEBUG" == "Y" ]; then echo Error Code is: $RC; fi
      if [ $RC -gt 0 ]; then 
        let REPEAT=$REPEAT+1
      fi
    done
    if [ "$LISTONLY" != "TRUE" ]; then
      ssh -i $SSHID $DDRUSER@$DDRHOST data-movement status
      if [ $REPEAT -gt 0 ]; then
        echo $REPEAT files were not recalled. Any files not recalled will be tried agian.
      fi
    fi
    IFS=$OLDIFS
  done 
done


