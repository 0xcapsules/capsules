import { RawSigner, SuiTransactionBlockResponse, TransactionBlock } from "@mysten/sui.js"
import { provider } from "./config"

export async function createdObjectsMap(txb: SuiTransactionBlockResponse) {
    if (!txb.effects?.created) throw new Error("")

    const objects = new Map()
    const ids = txb.effects.created.map((obj) => obj.reference.objectId)
    const multiObjects = await provider.multiGetObjects({
        ids,
        options: { showType: true },
    })

    for (let i = 0; i < multiObjects.length; i++) {
        const object = multiObjects[i]
        if (object.data) {
            objects.set(object.data.type, object.data.objectId)
        }
    }

    return objects
}

export function sleep(ms = 3000) {
    return new Promise((r) => setTimeout(r, ms))
}

export async function executeTxb(signer: RawSigner, txb: TransactionBlock) {
    const response = await signer.signAndExecuteTransactionBlock({
        transactionBlock: txb,
        options: { showEffects: true },
    })

    console.log(
        {
            digest: response.digest,
            status: response.effects?.status.status,
            error: response.effects?.status.error || "No Error",
        },
        "\n"
    )

    return response
}
