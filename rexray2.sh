#!/bin/bash
printf "Creating Docker Machine.... "
echo
CHECKDM="$(docker-machine status testing)"
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
