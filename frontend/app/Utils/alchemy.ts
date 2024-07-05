
import { Network, Alchemy} from 'alchemy-sdk'

// Optional Config object, but defaults to demo api-key and eth-mainnet.
const settings = {
    apiKey: "AnUP6UgLP1hi0_5HyiFk4H9MWnnoBvJZ", // Replace with your Alchemy API Key.
    network: Network.ARB_GOERLI, // Replace with your network.
  };
  
  export const alchemy = new Alchemy(settings);