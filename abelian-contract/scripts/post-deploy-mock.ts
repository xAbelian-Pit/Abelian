import {Overrides, providers, utils, Wallet} from "ethers";
import {DotRegistry__factory} from "../types";

import deployedMock from './deployed-mock.json'

const overrides: Overrides = {
  gasLimit: 21_000_000,
}

async function main() {
  const address = {
    evm1: deployedMock.evm1,
    evm2: deployedMock.evm2,
    evm3: deployedMock.evm3,
    // evm1 (ethereum) wormhole contract address
    worm1: deployedMock.worm1,
  }

  const rpcs = {
    evm1: 'http://localhost:8545',
    evm2: 'http://localhost:8546',
    evm3: 'http://localhost:8547',
  }

  const mnemonic = 'test test test test test test test test test test test junk'
  const wal = Wallet.fromMnemonic(mnemonic)

  const contract = {
    evm1: DotRegistry__factory.connect(address.evm1, wal.connect(new providers.JsonRpcProvider(rpcs.evm1))),
    evm2: DotRegistry__factory.connect(address.evm2, wal.connect(new providers.JsonRpcProvider(rpcs.evm2))),
    evm3: DotRegistry__factory.connect(address.evm3, wal.connect(new providers.JsonRpcProvider(rpcs.evm3))),
  }
  const networkEVMs = Object.values(contract)
  // const worm1 =  MockWormhole__factory.connect(address.worm1, wal.connect(new providers.JsonRpcProvider('http://localhost:8545'))),

  await contract.evm1.addSupportedChainId(5, overrides)
  await contract.evm1.addSupportedChainId(6, overrides)
  await contract.evm2.addSupportedChainId(5, overrides)
  await contract.evm2.addSupportedChainId(6, overrides)
  await contract.evm3.addSupportedChainId(5, overrides)
  await contract.evm3.addSupportedChainId(6, overrides)

  console.log(
    await contract.evm1.getChainIds(),
    await contract.evm2.getChainIds(),
    await contract.evm3.getChainIds(),
  )

  await contract.evm1.setRegistryDelegate(contract.evm2.address, true, overrides)
  await contract.evm1.setRegistryDelegate(contract.evm3.address, true, overrides)
  await contract.evm2.setRegistryDelegate(contract.evm1.address, true, overrides)
  await contract.evm2.setRegistryDelegate(contract.evm3.address, true, overrides)
  await contract.evm3.setRegistryDelegate(contract.evm1.address, true, overrides)
  await contract.evm3.setRegistryDelegate(contract.evm2.address, true, overrides)

  console.log(utils.hexZeroPad(contract.evm2.address, 32), await contract.evm1.registryDelegates(utils.hexZeroPad(contract.evm2.address, 32)))
  console.log(utils.hexZeroPad(contract.evm3.address, 32), await contract.evm2.registryDelegates(utils.hexZeroPad(contract.evm3.address, 32)))
  console.log(utils.hexZeroPad(contract.evm1.address, 32), await contract.evm3.registryDelegates(utils.hexZeroPad(contract.evm1.address, 32)))
}

main().catch((err) => console.error(err))
