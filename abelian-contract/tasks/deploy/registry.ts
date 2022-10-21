import type { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { task } from 'hardhat/config'
import type { TaskArguments } from 'hardhat/types'

import { DotRegistry, DotRegistry__factory } from '../../types'

task('deploy:DotRegistry')
  .addParam('coreBridgeAddress', 'Wormhole Core Bridge Address')
  .setAction(async function (taskArguments: TaskArguments, { ethers }) {
    const signers: SignerWithAddress[] = await ethers.getSigners()
    const registryFactory = await ethers.getContractFactory('DotRegistry') as DotRegistry__factory

    const registry: DotRegistry = await registryFactory.connect(signers[0]).deploy(taskArguments.coreBridgeAddress)
    await registry.deployed()

    console.log('DotRegistry deployed to: ', registry.address)
  })
