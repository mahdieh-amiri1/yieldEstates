import { createPublicClient, http } from 'viem'
import { baseSepolia, fraxtal, fraxtalTestnet } from 'viem/chains'
import { createConfig } from 'wagmi'
export const selectedChain = fraxtalTestnet;
export const publicClient = createPublicClient({
  chain: selectedChain,
  transport: http()
})
export const simulateConfig = createConfig({
  chains: [selectedChain],
  transports: {
    [selectedChain.id]: http(),
  },
})