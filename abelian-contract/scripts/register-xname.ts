import { constants, providers, utils, Overrides, Wallet } from "ethers"

import { DotRegistry, DotRegistry__factory, MockWormhole__factory } from "../types"
import deployedMock from './deployed-mock.json'
import { abi as DotRegistryABI } from '../artifacts/contracts/DotRegistry.sol/DotRegistry.json'

const overrides: Overrides = {
  gasLimit: 21_000_000,
}

function randomId(length: number = 10) {
  const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  const charactersLength = characters.length;
  let result = '';
  for (let i = 0; i < length; i++ ) result += characters.charAt(Math.floor(Math.random() * charactersLength));
  return result;
}

// const dummyPayload = utils.AbiCoder.prototype.encode(
//   ['uint8', 'bytes32', 'bytes32', 'bytes32', 'uint64', 'uint16', 'uint8'],
//   [9, node, utils.hexZeroPad(wal.address, 32), utils.hexZeroPad(wal.address, 32), 10000, 2, 0],
// )
// const dummyVM = await worm1.createDummyVM(2, utils.hexZeroPad(contract.evm1.address, 32), dummyPayload)

async function retrieveDummyVM(tx: providers.TransactionResponse): Promise<string> {
  const iface = new utils.Interface(['event MockVMLog(bytes vm)'])
  const receipt = await tx.wait()
  let dummyVM: string = ''
  receipt.logs.forEach((log: providers.Log) => {
    try {
      dummyVM = iface.parseLog(log).args[0]
    } catch (err) {}
  })
  return dummyVM
}

type StatePropagationResult = [DotRegistry[], string[]]

async function propagateToOtherChains(VM: string, originEVM: DotRegistry, allEVMs: DotRegistry[]): Promise<StatePropagationResult> {
  const usedEVMs = allEVMs.filter((targetEVM) => targetEVM != originEVM)
  const responses = usedEVMs.map((targetEVM) => targetEVM.receiveSetOwner(VM, overrides))
  let vms: string[] = []

  try {
    const receipts = await Promise.all(responses)
    vms = await Promise.all(receipts.map((receipt) => retrieveDummyVM(receipt)))
  } catch (err) {
    console.error(`Propagation error from ${originEVM.address} for vm: \n ${VM}`)
    console.error(err)
    return [[], []]
  } finally {
    return [usedEVMs, vms]
  }
}

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

  // const completion = new Set<DotRegistry>()

  // const node = utils.namehash(`${randomId()}.worm`)
  const node = utils.namehash('jongwon.worm')
  console.log('Before reg owner: ', await contract.evm1['owner(bytes32)'](node))

  let originEVM = contract.evm1

  const dummyVM1 = await retrieveDummyVM(await originEVM.setOwner(node, wal.address))
  console.log('Flight 0', dummyVM1)

  // completion.add(originEVM)
  const [secondaryEVMs, vms] = await propagateToOtherChains(dummyVM1, originEVM, networkEVMs)

  // const propagations: Promise<StatePropagationResult>[] = []
  for (let i = 0; i < secondaryEVMs.length; i++) {
    const secondaryEVM = secondaryEVMs[i]
    const secondaryVM = vms[i]

    await propagateToOtherChains(secondaryVM, secondaryEVM, networkEVMs)
    console.log(`Flight ${i+1}`, secondaryVM)
  }
  // const res = await Promise.all(propagations)
  
  console.log('After reg owner: ',await contract.evm1['owner(bytes32)'](node))
}

main().catch((err) => console.error(err))
