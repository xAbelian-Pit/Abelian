import * as dotenv from 'dotenv'
import {Overrides, providers, utils, Wallet} from 'ethers'

dotenv.config({ path: '../.env' })

import {DotRegistry, DotRegistry__factory} from '../types'
import deployedTestnet from './deployed-testnet.json'

const overrides: { [key: string]: Overrides } = {
  evm1: { gasLimit: 21_000_000 },
  evm2: { gasLimit: 3_000_000 },
  evm3: { gasLimit: 3_000_000 },
  evm4: { gasLimit: 3_000_000 },
}

async function main() {
  const address = {
    evm1: deployedTestnet.evm1,
    evm2: deployedTestnet.evm2,
    evm3: deployedTestnet.evm3,
    evm4: deployedTestnet.evm4,
  }

  const rpcs = {
    evm1: 'https://rpc.ankr.com/eth_goerli',
    evm2: 'https://rpc.ankr.com/polygon_mumbai',
    evm3: 'https://rpc.ankr.com/avalanche_fuji',
    evm4: 'https://api.baobab.klaytn.net:8651',
  }

  const wal = new Wallet(process.env.PRIVATE_KEY as string)

  const contract: { [key: string]: DotRegistry } = {
    evm1: DotRegistry__factory.connect(address.evm1, wal.connect(new providers.JsonRpcProvider(rpcs.evm1))),
    evm2: DotRegistry__factory.connect(address.evm2, wal.connect(new providers.JsonRpcProvider(rpcs.evm2))),
    evm3: DotRegistry__factory.connect(address.evm3, wal.connect(new providers.JsonRpcProvider(rpcs.evm3))),
    evm4: DotRegistry__factory.connect(address.evm4, wal.connect(new providers.JsonRpcProvider(rpcs.evm4))),
  }
  const contractNames = Object.keys(contract)

  const wormholeChainId: { [key: string]: number } = {
    evm1: 1,
    evm2: 5,
    evm3: 6,
    emv4: 13,
  }

  // contractNames.forEach((key) => {
  //   const selfChainId = wormholeChainId[key]
  //   contractNames.forEach((j) => {
  //     if (wormholeChainId[j] !== selfChainId) {
  //       await contract[key].addSupportedChainId(5, overrides.evm1)
  //     }
  //   })
  // })

  console.log('>>> Adding support chain ids...')
  await (await contract.evm1.addSupportedChainId(5, overrides.evm1)).wait()
  await (await contract.evm1.addSupportedChainId(6, overrides.evm1)).wait()
  await (await contract.evm1.addSupportedChainId(13, overrides.evm1)).wait()
  await (await contract.evm2.addSupportedChainId(1, overrides.evm2)).wait()
  await (await contract.evm2.addSupportedChainId(6, overrides.evm2)).wait()
  await (await contract.evm2.addSupportedChainId(13, overrides.evm2)).wait()
  await (await contract.evm3.addSupportedChainId(1, overrides.evm3)).wait()
  await (await contract.evm3.addSupportedChainId(5, overrides.evm3)).wait()
  await (await contract.evm3.addSupportedChainId(13, overrides.evm3)).wait()
  await (await contract.evm4.addSupportedChainId(1, overrides.evm4)).wait()
  await (await contract.evm4.addSupportedChainId(5, overrides.evm4)).wait()
  await (await contract.evm4.addSupportedChainId(6, overrides.evm4)).wait()
  console.log('>>> Support chain ids complete!')

  console.log('>>> Setting registry delegates...')
  await (await contract.evm1.setRegistryDelegate(contract.evm2.address, true, overrides.evm1)).wait()
  await (await contract.evm1.setRegistryDelegate(contract.evm3.address, true, overrides.evm1)).wait()
  await (await contract.evm1.setRegistryDelegate(contract.evm4.address, true, overrides.evm1)).wait()
  await (await contract.evm2.setRegistryDelegate(contract.evm1.address, true, overrides.evm2)).wait()
  await (await contract.evm2.setRegistryDelegate(contract.evm3.address, true, overrides.evm2)).wait()
  await (await contract.evm2.setRegistryDelegate(contract.evm4.address, true, overrides.evm2)).wait()
  await (await contract.evm3.setRegistryDelegate(contract.evm1.address, true, overrides.evm3)).wait()
  await (await contract.evm3.setRegistryDelegate(contract.evm2.address, true, overrides.evm3)).wait()
  await (await contract.evm3.setRegistryDelegate(contract.evm4.address, true, overrides.evm3)).wait()
  await (await contract.evm4.setRegistryDelegate(contract.evm1.address, true, overrides.evm4)).wait()
  await (await contract.evm4.setRegistryDelegate(contract.evm2.address, true, overrides.evm4)).wait()
  await (await contract.evm4.setRegistryDelegate(contract.evm3.address, true, overrides.evm4)).wait()
  console.log('>>> Setting registry delegates complete!')

  console.log(
    await contract.evm1.getChainIds(),
    await contract.evm2.getChainIds(),
    await contract.evm3.getChainIds(),
    await contract.evm4.getChainIds(),
  )

  console.log(utils.hexZeroPad(contract.evm1.address, 32), await contract.evm4.registryDelegates(utils.hexZeroPad(contract.evm1.address, 32)))
  console.log(utils.hexZeroPad(contract.evm2.address, 32), await contract.evm1.registryDelegates(utils.hexZeroPad(contract.evm2.address, 32)))
  console.log(utils.hexZeroPad(contract.evm3.address, 32), await contract.evm2.registryDelegates(utils.hexZeroPad(contract.evm3.address, 32)))
  console.log(utils.hexZeroPad(contract.evm4.address, 32), await contract.evm3.registryDelegates(utils.hexZeroPad(contract.evm4.address, 32)))
}

main().catch((err) => console.error(err))
