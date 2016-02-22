Repository to play with Docker networking functionabilities to support Mesos - Eureka ecosystem

ONGOING WORK - based on https://github.com/danigiri/docker-eureka

docker_eureka.sh : 

+ HOST A
  - Eureka0 : Eureka node
  - Node0 : Working node
+ HOST B
  - Eureka1 : Eureka node
  - Node1 : Working node
+ HOST Z
  - Zookeper :  KV store
  - Dnsmasq : DNS server to provide TXT records for Eureka

Embedded Docker DNS will be used by default and forwarded to Dnsmasq for external resolving
Docker overlay networks:
  - Service : All nodes
  - Production : Working nodes

____________________________________________
PREVIOUS WORK
docker_3.sh : basic test of overlay networking across multiple hosts using Consul as Key-Value Store
docker_zookeper.sh : same as above but using Zookeeper as Key-Value Store
docker_zk_staticip : same as above but defining a specific IP network for the overlay network
