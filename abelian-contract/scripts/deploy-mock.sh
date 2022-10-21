#!/bin/bash
set -e
# Any subsequent(*) commands which fail will cause the shell script to exit immediately

WORM_REMOVE="MockWormhole deployed to:  "
REGISTRY_REMOVE="MockDotRegistry deployed to:  "

yarn hardhat compile

worm_eth=$(npx hardhat deploy:MockWormhole --network localEvm1 --wormhole-chain-id 2)
worm_poly=$(npx hardhat deploy:MockWormhole --network localEvm2 --wormhole-chain-id 5)
worm_avax=$(npx hardhat deploy:MockWormhole --network localEvm3 --wormhole-chain-id 6)

worm_eth="${worm_eth//$WORM_REMOVE/}"
worm_poly="${worm_poly//$WORM_REMOVE/}"
worm_avax="${worm_avax//$WORM_REMOVE/}"

eth=$(npx hardhat deploy:MockRegistry --network localEvm1 --core-bridge-address "$worm_eth")
poly=$(npx hardhat deploy:MockRegistry --network localEvm2 --core-bridge-address "$worm_poly")
avax=$(npx hardhat deploy:MockRegistry --network localEvm3 --core-bridge-address "$worm_avax")

eth="${eth//$REGISTRY_REMOVE/}"
poly="${poly//$REGISTRY_REMOVE/}"
avax="${avax//$REGISTRY_REMOVE/}"

echo "DotRegistry deployed!"
echo "Ethereum: $eth"
echo "Polygon: $poly"
echo "Avalanche: $avax"

jq -n \
  --arg evm1 "$eth" \
  --arg evm2 "$poly" \
  --arg evm3 "$avax" \
  --arg worm1 "$worm_eth" \
  --arg worm2 "$worm_poly" \
  --arg worm3 "$worm_avax" \
  '{evm1: $evm1, evm2: $evm2, evm3: $evm3, worm1: $worm1, worm2: $worm2, worm3: $worm3}' \
  > deployed-mock.json

cp deployed-mock.json ../../xName-server/src/constants/deployed-mock.json
cp deployed-mock.json ../../xName-website/src/utils/deployed-mock.json
