import { providers, utils, Wallet } from "ethers"

import { DotRegistry, DotRegistry__factory } from "../types"
import deployedMock from './deployed-mock.json'

async function main() {
	const address = {
    evm1: deployedMock.evm1,
    evm2: deployedMock.evm2,
    evm3: deployedMock.evm3,
    // evm1 (ethereum) wormhole contract address
    worm1: deployedMock.worm1,
  }

  const mnemonic = 'test test test test test test test test test test test junk'
  const wal = Wallet.fromMnemonic(mnemonic)

  const contract = {
    evm1: DotRegistry__factory.connect(address.evm1, wal.connect(new providers.JsonRpcProvider('http://localhost:8545'))),
    evm2: DotRegistry__factory.connect(address.evm2, wal.connect(new providers.JsonRpcProvider('http://localhost:8546'))),
    evm3: DotRegistry__factory.connect(address.evm3, wal.connect(new providers.JsonRpcProvider('http://localhost:8547'))),
  }
  const networkEVMs = Object.values(contract)

  const node = utils.namehash('jongwon.worm')

  const names: Promise<string>[] = []
  networkEVMs.forEach((evm) => {
    names.push(evm['owner(bytes32)'](node))
  })

  await Promise.all(names).then(console.log)
}

main()
 .then(() => process.exit(0))
 .catch((err) => console.error(err))
