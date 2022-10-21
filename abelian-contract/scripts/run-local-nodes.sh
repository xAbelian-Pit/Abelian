#!/bin/bash

declare -a ports=(8545, 8546, 8547)

for port in "${arr[@]}"
do
if [ lsof -t -i top:$port ]; then kill -9 $(lsof -t -i :$port); fi
done

ttab 'npx hardhat node --fork https://rpc.ankr.com/eth --port 8545'
ttab 'npx hardhat node --fork https://rpc.ankr.com/polygon --port 8546'
ttab 'npx hardhat node --fork https://rpc.ankr.com/avalanche --port 8547'
#ttab 'npx hardhat node --fork https://api.baobab.klaytn.net:8651 --port 8548'
