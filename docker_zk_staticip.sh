#!/bin/bash

# script from https://docs.docker.com/engine/userguide/networking/get-started-overlay/
# zoookeper without cluster



#DRIVER_OPTS=${DRIVER_OPTS:-'--driver virtualbox  --virtualbox-no-share --virtualbox-disk-size 2000 --virtualbox-memory 1024'}
DRIVER_OPTS="-d virtualbox"

NET="overlay_net"
KS="ks"
NODE="host"
CONTAINER="node"
NUM=3 #Number of Hosts and Nodes


echo -e "*********Set up a key-value store"
echo "*********Creating a virtualbox machine called $KS"
docker-machine create $DRIVER_OPTS "$KS"

echo "*********Start a zookeeper container running on the $KS machine"
docker $(docker-machine config "$KS") run -d \
    -p "8181:8181" \
	-p "2181:2181" \
	-p "2888:2888" \
	-p "3888:3888" \
    -h "zookeeper" \
    jplock/zookeeper

echo "*********Checking zookeeper container, using tcp/2181"
eval "$(docker-machine env "$KS")"
docker ps

echo "*********Creating $NUM nodes"
for (( i = 0; i < $NUM; i++ )); do
	docker-machine create $DRIVER_OPTS \
	--engine-opt="cluster-store=zk://$(docker-machine ip "$KS"):2181" \
	--engine-opt="cluster-advertise=eth1:2376" \
	 "$NODE$i"
done

echo "*********List of running virtualbox hosts:"
docker-machine ls 

echo "*********Create the overlay network"
# it's only needed to create on one of the nodes of the cluster
eval $(docker-machine env host0)

# old docker network creation
#docker network create --driver overlay "$NET"

#https://docs.docker.com/engine/userguide/networking/work-with-networks/
#https://docs.docker.com/engine/reference/commandline/network_create/
docker network create --driver overlay \
--subnet=192.168.0.0/16 \
--gateway=192.168.0.100 \
--ip-range=192.168.1.0/24 \
"$NET"
#--aux-address a=192.168.1.5 --aux-address b=192.168.1.6




echo "*********Creating one container inside each node"
for (( i = 0; i < $NUM; i++ )); do
	eval $(docker-machine env "$NODE$i")
	docker run -d --name="$CONTAINER$i" --net="$NET" --env="constraint:node==$NODE$i" gliderlabs/alpine sh -c "sleep 3000"
done


echo "*********Pinging from node0 to node0"
eval $(docker-machine env host0)
for (( i = 0; i < $NUM; i++ )); do
	echo "*********Pinging from node0 to node$i"
	docker exec "node0" ping -c 2 "$CONTAINER$i"
done

#state: all resolve the names, but the last doesn't ping






