# go-ipfs-docker
## overview
Repository deploys an IFPS cluster for benchmarking purposes. 

Uses a custom container image based on the [Dockerfile](https://github.com/ipfs/go-ipfs/blob/master/Dockerfile) from [go-ipfs](https://github.com/ipfs/go-ipfs). While the aforementioned work builds from busybox, we use debian bullseye to provide a larger suite of utilities.

# usage
    # initialize cluster
    docker-compose up -d

    # limit bandwidth to 32mbit and network latency to 5ms
    for i in $(seq 0 7); do
        docker exec ipfs$i tc qdisc add dev eth0 root tbf rate 32mbit latency 5ms burst 1540
    done

    # stop and delete cluster
    docker-compose down

## todo
