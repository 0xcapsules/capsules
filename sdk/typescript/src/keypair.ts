import {
  Ed25519Keypair,
  normalizeSuiAddress,
  RawSigner,
  JsonRpcProvider,
  fromB64
} from '@mysten/sui.js';

import fs from 'fs';

const PRIVATE_KEY_ENV_VAR = 'PRIVATE_KEY';

// Build a class to connect to Sui RPC servers
// Default endpoint is devnet 'https://fullnode.devnet.sui.io:443'
export const provider = new JsonRpcProvider();

async function requestFromFaucet(address: string) {
  const response = await provider.requestSuiFromFaucet(address);
  return response.transferred_gas_objects;
}

async function loadEnv(env_path: string): Promise<string> {
  return new Promise((resolve, reject) => {
    fs.readFile(env_path, { encoding: 'utf8' }, (err, data) => {
      if (err) reject(err);
      resolve(data);
    });
  });
}

async function storeInEnv(
  env_path: string,
  privateKey: string,
  existingEnv?: string
): Promise<void> {
  const data = `${PRIVATE_KEY_ENV_VAR}=${privateKey}\n${existingEnv ? existingEnv : ''}`;

  return new Promise((resolve, reject) => {
    fs.writeFile(env_path, data, { encoding: 'utf8' }, err => {
      if (err) reject(err);
      resolve();
    });
  });
}

function getPrivateKeyFromEnv(env: string) {
  const lines = env.split('\n');

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();
    if (line.startsWith(PRIVATE_KEY_ENV_VAR)) {
      return line.substring(12).trim();
    }
  }
}

async function generateAndStoreKeypair(env_path: string, existingEnv?: string) {
  const keypair = Ed25519Keypair.generate();
  const { privateKey } = keypair.export();
  await storeInEnv(env_path, privateKey, existingEnv);

  return keypair;
}

async function loadKeypair(env_path: string) {
  try {
    const env = await loadEnv(env_path);
    const privateKey = getPrivateKeyFromEnv(env);

    if (privateKey) {
      let secretKey = fromB64(privateKey);

      // This corrects for a bug in the Typescript SDK
      if (secretKey.length === 64) {
        secretKey = secretKey.slice(0, 32);
      }

      return Ed25519Keypair.fromSecretKey(secretKey);
    } else {
      return await generateAndStoreKeypair(env);
    }
  } catch (e: any) {
    if (e.code == 'ENOENT') {
      return await generateAndStoreKeypair(env_path);
    }

    throw e;
  }
}

async function fetchSuiCoinsForAddress(address: string) {
  const coins = await provider.getCoins(address, '0x2::sui::SUI');
  return coins.data;
}

export async function createAsyncValue(): Promise<string> {
  return new Promise(resolve => {
    setTimeout(() => {
      resolve('Hello, world!');
    }, 1000);
  });
}

export async function getAddress(env_path: string): Promise<string> {
  const keypair = await loadKeypair(env_path);
  const address = normalizeSuiAddress(keypair.getPublicKey().toSuiAddress());

  console.log('========== Keypair loaded ==========');
  console.log('Address', address);

  return address;
}

export async function getSigner(env_path: string): Promise<RawSigner> {
  const keypair = await loadKeypair(env_path);
  const address = keypair.getPublicKey().toSuiAddress();

  console.log('========== Keypair loaded ==========');
  console.log('Address', normalizeSuiAddress(address));

  const coins = await fetchSuiCoinsForAddress(address);

  if (coins.length < 1) {
    console.log('========== Sui Airdrop Requested ==========');

    await requestFromFaucet(address);

    console.log('========== Sui Airdrop Received ==========');
  }

  return new RawSigner(keypair, provider);
}
