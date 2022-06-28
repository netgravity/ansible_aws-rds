#!/bin/bash

# to get the lastet minor version available for a given site
# and run ansible playbooks to get and upgrade

# target site
db_tobe_upgraded=$1


# make sure arg supplied supplied as command line arg else exit
[[ -z $db_tobe_upgraded ]] && { echo " db name name not passed in as argument"; exit 1; }

## the case statement will determine what profile to choose based on db instance name
option="${1}" 
case ${option} in 
   education) 
      awsconfig=default
      ansiblehost=db
      echo "Profile name is $awsconfig"
      ;; 
   -d) DIR="${2}" 
      echo "Dir name is $DIR"
      ;; 
   *)  
      echo "`basename ${0}`:usage: pass in a valid db name" 
      exit 1 # Command to come out of the program with status 1
      ;; 
esac 

get_latest_ver(){
        # get the db engine being used
        dbengine=$(aws rds describe-db-instances --db-instance-identifier "$db_tobe_upgraded" \
		--query 'DBInstances[*].[Engine]' --profile "$awsconfig" --output=text)

        # get the db engine version being used
        dbengineversion=$(aws rds describe-db-instances --db-instance-identifier "$db_tobe_upgraded" \
	        	--query 'DBInstances[*].[EngineVersion]' --profile "$awsconfig" --output=text)

        echo "Current state of $db_tobe_upgraded: Engine:$dbengine Version:$dbengineversion"

        # get the latest minor vers*ion availabe to be patched
        latestminorver=$(aws rds describe-db-engine-versions --engine "$dbengine" --engine-version "$dbengineversion" \
		        --query 'DBEngineVersions[*].ValidUpgradeTarget[?IsMajorVersionUpgrade==`false`].EngineVersion' \
		       	--output=text --profile "$awsconfig" | awk '{print $(NF)}')

        echo "The latest minor version available is $latestminorver"
     }

#[[ -z $awsconfig  ]] && { echo " config profile not passed in as argument"; exit 1; }


upgrade_rds_db(){

	## Run ansible playbook
	#ansible-playbook get_rds.yml -i hosts --extra-vars "variable_host=$ansiblehost" --vault-password-file ~/.ansibled.vault

	read -p "Are you absolutely sure, you want to upgrade $db_tobe_upgraded to version $latestminorver  " -n 3 -r
		echo    # (optional) move to a new line
		if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]
		then
			ansible-playbook ./files/upgrade_rds.yml -i hosts --extra-vars "variable_host=$ansiblehost \
			new_version=$latestminorver db_instance_id=$db_tobe_upgraded" --vault-password-file ~/.ansibled.vault
		else
			 echo "All good will not upgrade"
		fi

		}

get_rds_info(){

	ansible-playbook ./files/get_rds.yml -i hosts --extra-vars "variable_host=$ansiblehost"  --vault-password-file ~/.ansibled.vault
	
              }

create_rds_snapshot(){

	ansible-playbook ./files/createsnapshot.yml -i hosts --extra-vars "variable_host=$ansiblehost  db_instance_id=$db_tobe_upgraded" --vault-password-file ~/.ansibled.vault
	
              }

# invoke get latest version of the db instance available
get_latest_ver # "$db_tobe_upgraded"

# if no verion to be upgraded exit script here
[[ -z "$latestminorver" ]] && { echo "no minor version to be upgraded"; exit 1; }

# invoke get rds info to get basic rds details
get_rds_info


# take a backup
create_rds_snapshot
if [ $? -eq 0 ] 
then 
	  echo "Snapshot creation worked" 
  else 
	   echo "snapshot creation failed" ; exit 1
fi


echo $?
echo "after step createsnaphot"

# invoke upgade rds 
#upgrade_rds_db








