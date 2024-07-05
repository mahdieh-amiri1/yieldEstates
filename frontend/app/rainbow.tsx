'use client'
import '@rainbow-me/rainbowkit/styles.css';

import {
  getDefaultConfig,
  RainbowKitProvider,
} from '@rainbow-me/rainbowkit';
import { WagmiProvider,http, createConfig } from 'wagmi';
import { coinbaseWallet } from 'wagmi/connectors';

import {
  base,
  baseSepolia,
  baseGoerli
} from 'wagmi/chains';
import {
  QueryClientProvider,
  QueryClient,
} from "@tanstack/react-query";
import { selectedChain } from './Utils/client';
const config = getDefaultConfig({
  appName: 'Yield Estates',
  projectId: 'e528f025dadac44dcaa3b7b77f3ac08f',
  chains: [ selectedChain],
  ssr: true, 
});
const queryClient = new QueryClient();
 

export default function RainbowComponent({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <WagmiProvider config={config}>
        <QueryClientProvider client={queryClient}>
            <RainbowKitProvider>
                {children}
            </RainbowKitProvider>
        </QueryClientProvider>
    </WagmiProvider>
  );
}
