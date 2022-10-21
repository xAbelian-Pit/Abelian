import type { SignerWithAddress } from '@nomiclabs/hardhat-ethers/dist/src/signer-with-address'

import type { DotRegistry, MockWormhole } from '../types'

type Fixture<T> = () => Promise<T>

declare module 'mocha' {
  export interface Context {
    registry: DotRegistry
    wormhole: MockWormhole
    loadFixture: <T>(fixture: Fixture<T>) => Promise<T>
    signers: Signers
  }
}

export interface Signers {
  admin: SignerWithAddress
}
