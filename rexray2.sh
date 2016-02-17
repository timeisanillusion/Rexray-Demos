#!/bin/bash
# Simple script to automate the docker environment with Rexray on Windows from the docker toolset
# Created by James Scott based on work from blog.emc.com
# The virtualbox server should be running prior to launching this (see "rexray.bat")
# Work in progrss :)
# This is designed to be run in Windows from the Docker Toolset Shell


#Set this where virtualbox volumes will be stored
LOCATION="E:\volumes\\"

#Start the docker machine to install rexray to
echo "Creating Docker Machine.... "
echo

CHECKDM="$(docker-machine ls | grep testing  2>&1) "
#Don't create the machine if it's already running unless the user wants to
#I've had rexray issues re-starting the machine so just re-create if it's not running for now (why use a scaple!)

if [[ $CHECKDM == *"Running"* ]]
then
  read -p "Do you want to recreate the docker-machine? " -n 1 -r
  if [[  $REPLY =~ ^[Yy]$ ]]
  then
    CHECKDM="recreate"
  fi
fi

echo


if [[ $CHECKDM == *"Running"* ]]
then
  echo "Docker Machine already running"
else
  echo "Recreating Docker VM"
  # Delete it if it's found
  docker-machine rm -f testing
  # Re-create
  docker-machine create --driver=virtualbox testing
  echo "Downloading and Installing Rexray...."
  #Download and install rexray
  docker-machine ssh testing "curl -sSL https://dl.bintray.com/emccode/rexray/install | sh -"

  echo "Setting Rexray Configuration to VirtualBox"
  docker-machine ssh testing "sudo tee -a /etc/rexray/config.yml << EOF
  rexray:
    storageDrivers:
    - virtualbox
    volume:
      mount:
        preempt: false
  virtualbox:
    endpoint: http://10.0.2.2:18083
    tls: false
    controllerName: SATA
    volumePath: $LOCATION
  "
  echo
  echo
  echo "Staring Rexray Service"
  echo
  REXRAY="$(docker-machine ssh testing "sudo rexray start"  2>&1)"
  if [[ $REXRAY == *"SUCCESS"* ]]
  then
    echo "RexRay Service Started"
  else
    echo "RexRay Server Failed to Start $REXRAY"
    echo
  fi
fi

REXRAY=$(docker-machine ssh testing "sudo rexray start" 2>&1)

if [[ $REXRAY == *"running"* ]]
then
  #Options to test the rexray environment
  echo
  eval $(docker-machine env testing)
  read -p "Do you want to create a test volume? " -n 1 -r
  echo
  if [[  $REPLY =~ ^[Yy]$ ]]
  then
    NAME="$RANDOM"
    RED='\033[0;31m'
    NC='\033[0m'
    printf "Creating volume with name ${RED}$NAME${NC}\n"
    docker volume create --driver=rexray --name=$NAME --opt=size=1
    echo
    read -p "Do you want to connect the voume to a test container? " -n 1 -r
    echo
    if [[  $REPLY =~ ^[Yy]$ ]]
    then
      echo "Creating container"
      docker run -ti --volume-driver=rexray -v $NAME:/$NAME busybox
    fi
    echo
    read -p "Start a new container and connect the same volume? " -n 1 -r
    echo
    if [[  $REPLY =~ ^[Yy]$ ]]
    then
      echo "Creating new container"
      docker run -ti --volume-driver=rexray -v $NAME:/$NAME busybox
    fi
  fi
else
  echo " $REXRAY "
  echo
  echo "Something Failed"
  echo "Check VirtualBox Web Service is running and you have internet access"
  echo "Maybe try recreating the docker machine?"
fi
