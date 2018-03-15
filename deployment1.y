apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  annotations:
    node.number: "3"
    node.current: "1"
  creationTimestamp: null
  labels:
    node.name: node-1
  name: node-1
spec:
  replicas: 1
  strategy:
    type: RollingUpdate
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: atn-consotium
        node.name: node-1
    spec:
      containers:
      - image: quorum
        imagePullPolicy: Never
        name: node-1
        command: ["/bin/bash"]
        args:
        - "-cx"
        - |-
          qd=/qdata
          mkdir -p $qd/{logs,constellation/keys}
          mkdir -p $qd/dd/{geth,keystore}
          touch $qd/passwords.txt

          echo -n '0939fa86e99e497b30b5f4a8019fce384e80ee83a80f309c562f33cec5375434' > $qd/dd/geth/nodekey
          echo -n 'EFnioZclBx/G18Catxmr4oF1IR+tpevrBXUV1H0iwjs=' > $qd/constellation/keys/tm.pub
          echo -n '{"data":{"bytes":"T1X3We4fCZmX1JlDrh21/pvh55w6TQopYPLxmUVODjM="},"type":"unlocked"}' > $qd/constellation/keys/tm.key
          echo -n '{"address":"ee6fdb995fd4492385dfd0ea43a08d4b91a85f83","crypto":{"cipher":"aes-128-ctr","ciphertext":"077310466447f19669d0c7c573c4b8cf5714b8990dc2461da040ac6781b02f1c","cipherparams":{"iv":"04d55a59febb09147170771d61077524"},"kdf":"scrypt","kdfparams":{"dklen":32,"n":262144,"p":1,"r":8,"salt":"21b412bd17ee569634e6d07070261e242924c3de74d5a0acab7aefa180efb050"},"mac":"c8cadcdff502596cde2b9fc6b6bf06c74fb8f946e12ccae9fb3077e838c149d2"},"id":"e8da7a9a-804d-496c-b862-e92807fa2cc3","version":3}' > $qd/dd/keystore/UTC--2018-03-15T09-59-21.642265928Z--ee6fdb995fd4492385dfd0ea43a08d4b91a85f83
          cat << EOF > $qd/tm.conf
          url = "http://10.103.197.78:9000/"
          port = 9000
          socket = "/qdata/tm.ipc"
          othernodes = ["http://10.103.197.78:9000/","http://10.103.62.221:9000/","http://10.107.160.229:9000/"]
          publickeys = ["/qdata/constellation/keys/tm.pub"]
          privatekeys = ["/qdata/constellation/keys/tm.key"]
          workdir = "/qdata/constellation"
          EOF
          cat << EOF > $qd/dd/static-nodes.json
          [
           "enode://36c2e95786657b23c41a2b5ec4fb3a5e6b3e71a3a1f0daed4f6a49a525e28e5ad47d37c8e99f094ad9a2ab8e3eb5d4e53c1d8b63895ad8ec17a775d8a12f3b2f@10.103.197.78:30303?discport=0&raftport=23000",
           "enode://3894b5b7e4ba6be92e4fa7b156de257717867f870caefbc4315d784a25d1a13e9cf427bc1270a3a696c35b995d66e77db0ccdf3770e2f6e84bcd6f1ea8d9e38f@10.103.62.221:30303?discport=0&raftport=23000",
           "enode://26033fee3ca2b453da16c1ab34bbe08a877c5aa997686a6a184246a2a58786f95106bb285187ba12d7b3b36e6c27315749c052d57c043ca3c47f6a69536011d3@10.107.160.229:30303?discport=0&raftport=23000"
          ]
          EOF
          cat << EOF > $qd/genesis.json
          {
            "alloc": {
              "ee6fdb995fd4492385dfd0ea43a08d4b91a85f83": {
                "balance": "1000000000000000000000000000"
              },
              "d82e26a67f483019c7cde38d0a4c761f1b1df16c": {
                "balance": "1000000000000000000000000000"
              },
              "25fd1c47e1d0de371ba13edef972fcba64b036fc": { "balance": "1000000000000000000000000000"
              }
            },
            "coinbase": "0x0000000000000000000000000000000000000000",
            "config": {
              "homesteadBlock": 0
            },
            "difficulty": "0x0",
            "extraData": "0x",
            "gasLimit": "0x2FEFD800",
            "mixhash": "0x00000000000000000000000000000000000000647572616c65787365646c6578",
            "nonce": "0x0",
            "parentHash": "0x0000000000000000000000000000000000000000000000000000000000000000",
            "timestamp": "0x00"
          }
          EOF
          cat << EOF > $qd/start.sh
          #!/bin/bash

          set -u
          set -e

          TMCONF=/qdata/tm.conf
          GETH=/usr/local/bin/geth
          CONSTELLATION=/usr/local/bin/constellation-node
          GETH_ARGS="--datadir /qdata/dd \
            --raft --raftport 23000 \
            --rpc --rpcaddr 0.0.0.0 \
            --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum \
            --nodiscover \
            --unlock 0 --password /qdata/passwords.txt"

          if [ ! -d /qdata/dd/geth/chaindata ]; then
            echo "[*] Mining Genesis block"
            \$GETH --datadir /qdata/dd init /qdata/genesis.json
          fi

          echo "[*] Starting Constellation node"
          nohup \$CONSTELLATION \$TMCONF 2>> /qdata/logs/constellation.log &

          sleep 5

          echo "[*] Starting node"
          PRIVATE_CONFIG=/qdata/tm.ipc nohup \$GETH \$GETH_ARGS 2>>/qdata/logs/geth.log
          EOF

          chmod 755 $qd/start.sh
          /qdata/start.sh
        ports:
        - containerPort: 8545
        - containerPort: 23000
        - containerPort: 9000
        resources: {}
        volumeMounts:
        - mountPath: /qdata
          name: node-1-claim0
      restartPolicy: Always
      volumes:
      - name: node-1-claim0
        persistentVolumeClaim:
          claimName: node-1-claim0
status: {}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  creationTimestamp: null
  labels:
    atn.service: node-1-claim0
  name: node-1-claim0
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 100Mi
status: {}
---
apiVersion: v1
kind: Service
metadata:
  annotations:
    app: atn-consortium
    version: '1'
  creationTimestamp: null
  labels:
    atn.service: node-1
  name: node-1
spec:
  clusterIP: "10.103.197.78"
  ports:
  - name: "8545"
    port: 8545
    targetPort: 8545
  - name: "23000"
    port: 23000
    targetPort: 23000
  - name: "9000"
    port: 9000
    targetPort: 9000
  selector:
    service: node-1
status:
  loadBalancer: {}
