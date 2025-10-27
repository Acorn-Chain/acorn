import { GasPrice, SigningStargateClient } from '@cosmjs/stargate';
import { DirectSecp256k1HdWallet } from '@cosmjs/proto-signing';
import { stringToPath } from '@cosmjs/crypto';
import { getSigningCosmosClient } from '@acorn-chain/acornjs';

import { createPublicClient, createWalletClient, defineChain, http, PublicClient, WalletClient } from 'viem'
import { mnemonicToAccount, HDAccount } from 'viem/accounts'

export type ChainName = 'localacorn' | 'acorndev';

export const localacorn = /*#__PURE__*/ defineChain({
  id: 9_000,
  name: 'Localhost',
  nativeCurrency: {
    decimals: 18,
    name: 'Ether',
    symbol: 'ETH',
  },
  rpcUrls: {
    default: { http: ['http://127.0.0.1:8545'] },
  },
})

export const acorndev = /*#__PURE__*/ defineChain({
  id: 1_235,
  name: 'AcornDev',
  nativeCurrency: {
    decimals: 18,
    name: 'Ether',
    symbol: 'ETH',
  },
  rpcUrls: {
    default: { http: ['https://jsonrpc.dev.acornchain.org:443'] },
  },
})


export const USERS = [
  {
    key: "user1",
    mnemonic: "copper push brief egg scan entry inform record adjust fossil boss egg comic alien upon aspect dry avoid interest fury window hint race symptom",
    address: "acorn1q986wh082dp6wndt58j60hrgsr8kh9wg88awl8"
  },
  {
    key: "user2",
    mnemonic: "maximum display century economy unlock van census kite error heart snow filter midnight usage egg venture cash kick motor survey drastic edge muffin visual",
    address: "acorn19uz0dc9j950knkxzdxs2m92q5474sgx335pz6r"
  },
  {
    key: "user3",
    mnemonic: "will wear settle write dance topic tape sea glory hotel oppose rebel client problem era video gossip glide during yard balance cancel file rose",
    address: "acorn1xejsnure97tteuqz4wggvl8cla3s9knj65alnu"
  },
  {
    key: "user4",
    mnemonic: "doll midnight silk carpet brush boring pluck office gown inquiry duck chief aim exit gain never tennis crime fragile ship cloud surface exotic patch",
    address: "acorn1rfn972g75dhyp586jmyda7vpsuqa4w0syh099q"
  },
  {
    key: "validator",
    mnemonic: "gesture inject test cycle original hollow east ridge hen combine junk child bacon zero hope comfort vacuum milk pitch cage oppose unhappy lunar seat",
  }
];

export const RPC_ENDPOINTS = {
  'acorndev': 'https://rpc.dev.acornchain.org:443',
  'localacorn': 'http://0.0.0.0:26657',
}

export async function setupClients(chainName: ChainName = 'localacorn'): Promise<{
  cosmosAccounts: DirectSecp256k1HdWallet[],
  cosmosClients: SigningStargateClient[],
  evmAccounts: HDAccount[],
  evmClients: WalletClient[],
  publicClient: PublicClient
}> {
  const cosmosAccounts = await Promise.all(USERS.map((user) => {
    return DirectSecp256k1HdWallet.fromMnemonic(user.mnemonic, { prefix: 'acorn' });
  }))

  const cosmosClients = await Promise.all(cosmosAccounts.map((wallet) => {
    return getSigningCosmosClient({
      rpcEndpoint: RPC_ENDPOINTS[chainName],
      signer: wallet,
    })
  }));

  const evmAccounts = USERS.map((user) => {
    return mnemonicToAccount(user.mnemonic)
  })


  const evmClients = evmAccounts.map((account) => {
    return createWalletClient({
      account,
      chain: chainName === 'localacorn' ? localacorn : acorndev,
      transport: http()
    })
  })

  const publicClient = createPublicClient({
    chain: chainName === 'localacorn' ? localacorn : acorndev,
    transport: http()
  });

  return {
    cosmosAccounts,
    cosmosClients,
    evmAccounts,
    evmClients,
    publicClient,
  }
}