# Abelian

Multi-chain dynamic NFT, powered by Wormhole

Slides: [xAbelian](https://docs.google.com/presentation/d/1vMSaXpUu9Nt6WS_ty_fmNxxWoU2f_0VVtpY32l0mQRE/edit?usp=sharing)

## How does it work?

When you request a state change on one chain, it first creates a message through Wormhole (VAA) with the request. VAA gets distributed to all other supported blockchains, where the same contract is deployed. Each contract receives the VAA, validates it, and creates its own VAA, which gets distributed to all other chains.

Let's say there are *n* chains supported. When each chain's contract receives *(n-1)/n* VAAs with the "success" payload, it finalizes the state on its chain. This is a mesh network mechanism that costs more gas than the hub-and-spoke approach, but guarantees parallelization and semi-atomicity of state finalization.

If one chain finds an error within a VAA received from another chain, it'll create a VAA with an error log that gets delivered to all other chains. This error VAA will trigger the state reversion for all contracts.

Currently, the distribution of VAAs is centralized and executed by a relayer ran by me, but this can become decentralized with incentives for fast relayers.
