import type { SignerWithAddress } from '@nomiclabs/hardhat-ethers/dist/src/signer-with-address'
import { ethers } from 'hardhat'

import { MockAbelianToken, MockAbelianToken__factory } from '../../types'

export async function deployAbelianFixture(): Promise<{ abelian: MockAbelianToken }> {
  const signers: SignerWithAddress[] = await ethers.getSigners()
  const admin: SignerWithAddress = signers[0]

  // const args: any[] = [
  //   constants.AddressZero,
  // ]
  const abelianFactory = await ethers.getContractFactory('MockAbelianToken') as MockAbelianToken__factory
  const abelian: MockAbelianToken = await abelianFactory.connect(admin).deploy(2)
  await abelian.deployed()

  return { abelian }
}
