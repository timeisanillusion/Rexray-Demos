#!/bin/bash
#Simple script to automate the docker environment with Rexray on Windows from the docker toolset
# Created by James Scott based on work from blog.emc.com
# The virtualbox server should be running prior to launching this see "rexray.bat"
# Work in progrss :)

printf "Creating Docker Machine.... "
echo
CHECKDM="$(docker-machine status testing)"

#Don't create the machine if it's already running
#I've had rexray issues re-starting the machine so just re-create if it's not running
if [[ $CHECKDM == *"Running"* ]]
then
  echo "Docker Machine already running"
  echo
else
  # Delete it if it's found
  docker-machine rm -f testing
  # Re-create
  docker-machine create --driver=virtualbox testing
  printf "Downloading and Installing Rexray...."
  #Download and install rexray
  #Need to expand this to save the install locally for offline use
  docker-machine ssh testing "curl -sSL https://dl.bintray.com/emccode/rexray/install | sh -"
  printf "Setting Rexray Configuration to VirtualBox"
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
    volumePath: /Users/jscott/VirtualBox Volumes
    controllerName: SATA
  "
  printf "Staring Rexray Service \n"
  docker-machine ssh testing "sudo rexray start"
fi
printf "Setting environment to Docker Machine"

#Options to test the rexray environment

echo
eval $(docker-machine env testing)
read -p "Do you want to create a test volume? " -n 1 -r
echo
if [[  $REPLY =~ ^[Yy]$ ]]
then
  NAME="$RANDOM"
  echo "Creating volume with name $NAME....."
  docker volume create --driver=rexray --name=$NAME --opt=size=1
  read -p "Do you want to connect the voume to a test container? " -n 1 -r
  echo
  if [[  $REPLY =~ ^[Yy]$ ]]
  then
    echo "Creating container"
    docker run -ti --volume-driver=rexray -v $NAME:/$NAME busybox
  fi
fi
