import { bcsSource as bcs } from "../../../../_framework/bcs";
import {
  FieldsWithTypes,
  Type,
  parseTypeName,
} from "../../../../_framework/util";
import { ID } from "../../0x2/object/structs";
import { Encoding } from "@mysten/bcs";
import { ObjectId } from "@mysten/sui.js";

/* ============================== TypedID =============================== */

bcs.registerStructType(
  "0x6188f77679f6b756f23557e9289fa7eacfaab7fc17e485ac22088e34e5fb5786::typed_id::TypedID<T>",
  {
    id: `0x2::object::ID`,
  }
);

export function isTypedID(type: Type): boolean {
  return type.startsWith(
    "0x6188f77679f6b756f23557e9289fa7eacfaab7fc17e485ac22088e34e5fb5786::typed_id::TypedID<"
  );
}

export interface TypedIDFields {
  id: ObjectId;
}

export class TypedID {
  static readonly $typeName =
    "0x6188f77679f6b756f23557e9289fa7eacfaab7fc17e485ac22088e34e5fb5786::typed_id::TypedID";
  static readonly $numTypeParams = 1;

  readonly $typeArg: Type;

  readonly id: ObjectId;

  constructor(typeArg: Type, id: ObjectId) {
    this.$typeArg = typeArg;

    this.id = id;
  }

  static fromFields(typeArg: Type, fields: Record<string, any>): TypedID {
    return new TypedID(typeArg, ID.fromFields(fields.id).bytes);
  }

  static fromFieldsWithTypes(item: FieldsWithTypes): TypedID {
    if (!isTypedID(item.type)) {
      throw new Error("not a TypedID type");
    }
    const { typeArgs } = parseTypeName(item.type);

    return new TypedID(typeArgs[0], item.fields.id);
  }

  static fromBcs(
    typeArg: Type,
    data: Uint8Array | string,
    encoding?: Encoding
  ): TypedID {
    return TypedID.fromFields(
      typeArg,
      bcs.de([TypedID.$typeName, typeArg], data, encoding)
    );
  }
}
