import type { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { task } from 'hardhat/config'
import type { TaskArguments } from 'hardhat/types'

import { MockWormhole, MockWormhole__factory } from '../../types'

task('deploy:MockWormhole')
  .addParam('wormholeChainId', 'Wormhole Chain ID')
  .setAction(async function (taskArguments: TaskArguments, { ethers }) {
    const signers: SignerWithAddress[] = await ethers.getSigners()

    const mockWormholeFactory = await ethers.getContractFactory('MockWormhole') as MockWormhole__factory
    const wormhole: MockWormhole = await mockWormholeFactory.connect(signers[0]).deploy(taskArguments.wormholeChainId)
    await wormhole.deployed()

    console.log('MockWormhole deployed to: ', wormhole.address)
  })
