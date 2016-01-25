#!/bin/bash

# script from https://docs.docker.com/engine/userguide/networking/get-started-overlay/
# consul without swarm

NET="overlay_net"
KS="keystore"
NODE="demo"
CONTAINER="node"
NUM=5 #Number of Hosts and Nodes


echo "*********Set up a key-value store"
echo "*********Creating a virtualbox machine called $KS"
docker-machine create -d virtualbox "$KS"

echo "*********Start a progrium/consul container running on the $KS machine"
docker $(docker-machine config "$KS") run -d \
    -p "8500:8500" \
    -h "consul" \
    progrium/consul -server -bootstrap

echo "*********Checking consul container, using tcp/8500"
eval "$(docker-machine env "$KS")"
docker ps

echo "*********Creating 3 nodes"
for (( i = 0; i < $NUM; i++ )); do
	docker-machine create -d virtualbox \
	--engine-opt="cluster-store=consul://$(docker-machine ip "$KS"):8500" \
	--engine-opt="cluster-advertise=eth1:2376" \
	 "$NODE$i"
done

echo "*********List of running virtualbox hosts:"
docker-machine ls 

echo "*********Create the overlay network"
# it's only needed to create on one of the nodes of the cluster
eval $(docker-machine env demo0)
docker network create --driver overlay "$NET"

echo "*********Creating one container inside each node"
for (( i = 0; i < $NUM; i++ )); do
	eval $(docker-machine env "$NODE$i")
	docker run -d --name="$CONTAINER$i" --net="$NET" --env="constraint:node==$NODE$i" gliderlabs/alpine sh -c "sleep 1000"
done


echo "*********Pinging from node0 to node0"
eval $(docker-machine env demo0)
docker exec "node0" ping -c 2 "10.0.0.2"
for (( i = 1; i < $NUM; i++ )); do
	echo "*********Pinging from node0 to node$i"
	docker exec "node0" ping -c 2 "$CONTAINER$i"
done





