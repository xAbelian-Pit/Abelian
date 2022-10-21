import type { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { task } from 'hardhat/config'
import type { TaskArguments } from 'hardhat/types'

import { DotRegistry, DotRegistry__factory } from '../../types'

// eth: yarn deploy --network localEvm1 --core-bridge-address 0x98f3c9e6E3fAce36bAAd05FE09d375Ef1464288B
// avax: yarn deploy --network localEvm2 --core-bridge-address 0x54a8e5f9c4CbA08F9943965859F6c34eAF03E26c
task('deploy:MockRegistry')
  .addParam('coreBridgeAddress', 'Wormhole Core Bridge Address')
  .setAction(async function (taskArguments: TaskArguments, { ethers }) {
    const signers: SignerWithAddress[] = await ethers.getSigners()
    const registryFactory = await ethers.getContractFactory('DotRegistry') as DotRegistry__factory

    const registry: DotRegistry = await registryFactory.connect(signers[0]).deploy(taskArguments.coreBridgeAddress)
    await registry.deployed()

    console.log('MockDotRegistry deployed to: ', registry.address)
  })
