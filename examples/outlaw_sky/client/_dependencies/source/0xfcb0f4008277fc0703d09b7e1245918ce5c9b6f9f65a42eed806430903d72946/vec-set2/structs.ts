import { bcsSource as bcs } from "../../../../_framework/bcs";
import { initLoaderIfNeeded } from "../../../../_framework/init-source";
import { structClassLoaderSource } from "../../../../_framework/loader";
import {
  FieldsWithTypes,
  Type,
  parseTypeName,
} from "../../../../_framework/util";
import { Encoding } from "@mysten/bcs";

/* ============================== VecSet =============================== */

bcs.registerStructType(
  "0xfcb0f4008277fc0703d09b7e1245918ce5c9b6f9f65a42eed806430903d72946::vec_set2::VecSet<K>",
  {
    contents: `vector<K>`,
  }
);

export function isVecSet(type: Type): boolean {
  return type.startsWith(
    "0xfcb0f4008277fc0703d09b7e1245918ce5c9b6f9f65a42eed806430903d72946::vec_set2::VecSet<"
  );
}

export interface VecSetFields<K> {
  contents: Array<K>;
}

export class VecSet<K> {
  static readonly $typeName =
    "0xfcb0f4008277fc0703d09b7e1245918ce5c9b6f9f65a42eed806430903d72946::vec_set2::VecSet";
  static readonly $numTypeParams = 1;

  readonly $typeArg: Type;

  readonly contents: Array<K>;

  constructor(typeArg: Type, contents: Array<K>) {
    this.$typeArg = typeArg;

    this.contents = contents;
  }

  static fromFields<K>(typeArg: Type, fields: Record<string, any>): VecSet<K> {
    initLoaderIfNeeded();

    return new VecSet(
      typeArg,
      fields.contents.map((item: any) =>
        structClassLoaderSource.fromFields(typeArg, item)
      )
    );
  }

  static fromFieldsWithTypes<K>(item: FieldsWithTypes): VecSet<K> {
    initLoaderIfNeeded();

    if (!isVecSet(item.type)) {
      throw new Error("not a VecSet type");
    }
    const { typeArgs } = parseTypeName(item.type);

    return new VecSet(
      typeArgs[0],
      item.fields.contents.map((item: any) =>
        structClassLoaderSource.fromFieldsWithTypes(typeArgs[0], item)
      )
    );
  }

  static fromBcs<K>(
    typeArg: Type,
    data: Uint8Array | string,
    encoding?: Encoding
  ): VecSet<K> {
    return VecSet.fromFields(
      typeArg,
      bcs.de([VecSet.$typeName, typeArg], data, encoding)
    );
  }
}
