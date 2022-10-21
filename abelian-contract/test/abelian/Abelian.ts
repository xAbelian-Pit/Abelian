import { loadFixture } from '@nomicfoundation/hardhat-network-helpers'
import type { SignerWithAddress } from '@nomiclabs/hardhat-ethers/dist/src/signer-with-address'
import { ethers } from 'hardhat'

import type { Signers } from '../types'
import { shouldBehaveLikeAbelian } from './Abelian.behavior'
import { deployAbelianFixture } from './Abelian.fixture'
import { deployWormholeFixture } from './Wormhole.fixture'

describe('Unit tests', function () {
  before(async function () {
    this.signers = {} as Signers

    const signers: SignerWithAddress[] = await ethers.getSigners()
    this.signers.admin = signers[0]

    this.loadFixture = loadFixture

    const { wormhole } = await this.loadFixture(deployWormholeFixture)
    this.wormhole = wormhole
  })

  describe('Abelian', function () {
    beforeEach(async function () {
      const { abelian } = await this.loadFixture(deployAbelianFixture)
      this.abelian = abelian
    })

    shouldBehaveLikeAbelian()
  })
})
