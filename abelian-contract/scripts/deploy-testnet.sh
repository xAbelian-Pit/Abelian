#!/bin/bash
set -e
# Any subsequent(*) commands which fail will cause the shell script to exit immediately

REGISTRY_REMOVE="DotRegistry deployed to:  "

yarn hardhat compile

worm_eth="0x706abc4E45D419950511e474C7B9Ed348A4a716c"
worm_poly="0x0CBE91CF822c73C2315FB05100C2F714765d5c20"
worm_avax="0x7bbcE28e64B3F8b84d876Ab298393c38ad7aac4C"
worm_klaytn="0x1830CC6eE66c84D2F177B94D544967c774E624cA"

echo "Deployment starting..."
eth=$(npx hardhat deploy:DotRegistry --network goerli --core-bridge-address "$worm_eth")
echo ">>> Ethereum Goerli"
poly=$(npx hardhat deploy:DotRegistry --network mumbai --core-bridge-address "$worm_poly")
echo ">>> Polygon Mumnbai"
avax=$(npx hardhat deploy:DotRegistry --network fuji --core-bridge-address "$worm_avax")
echo ">>> Avalanche Fuji"
klaytn=$(npx hardhat deploy:DotRegistry --network baobab --core-bridge-address "$worm_klaytn")
echo ">>> Klaytn Baobab"

eth="${eth//$REGISTRY_REMOVE/}"
poly="${poly//$REGISTRY_REMOVE/}"
avax="${avax//$REGISTRY_REMOVE/}"
klaytn="${klaytn//$REGISTRY_REMOVE/}"

echo "DotRegistry deployed on testnets!"
echo "Ethereum Goerli: $eth"
echo "Polygon Mumnbai: $poly"
echo "Avalanche Fuji: $avax"
echo "Klaytn Baobab: $klaytn"

jq -n \
  --arg evm1 "$eth" \
  --arg evm2 "$poly" \
  --arg evm3 "$avax" \
  --arg evm4 "$klaytn" \
  --arg worm1 "$worm_eth" \
  --arg worm2 "$worm_poly" \
  --arg worm3 "$worm_avax" \
  --arg worm4 "$worm_klaytn" \
  '{evm1: $evm1, evm2: $evm2, evm3: $evm3, evm4: $evm4, worm1: $worm1, worm2: $worm2, worm3: $worm3, worm4: $worm4}' \
  > deployed-testnet.json

cp deployed-testnet.json ../../xName-server/src/constants/deployed-testnet.json
cp deployed-testnet.json ../../xName-website/src/utils/deployed-testnet.json
