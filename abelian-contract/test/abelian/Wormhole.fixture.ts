import type { SignerWithAddress } from '@nomiclabs/hardhat-ethers/dist/src/signer-with-address'
import { ethers } from 'hardhat'

import type { MockWormhole, MockWormhole__factory } from '../../types'

export async function deployWormholeFixture(): Promise<{ wormhole: MockWormhole }> {
  const signers: SignerWithAddress[] = await ethers.getSigners()
  const admin: SignerWithAddress = signers[0]

  const mockWormholeFactory = await ethers.getContractFactory('MockWormhole') as MockWormhole__factory
  const wormhole: MockWormhole = await mockWormholeFactory.connect(admin).deploy(2)
  await wormhole.deployed()

  return { wormhole }
}
