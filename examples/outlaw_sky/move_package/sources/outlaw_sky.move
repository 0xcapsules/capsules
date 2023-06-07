module outlaw_sky::outlaw_sky {
    use std::string::{String, utf8};
    use std::option::Option;

    use sui::object::{Self, ID, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::vec_map::{Self, VecMap};

    use sui_utils::typed_id;
    use sui_utils::vec_map2;

    use ownership::client;
    use ownership::ownership;
    use ownership::tx_authority::{Self, TxAuthority};
    use ownership::publish_receipt;
    use ownership::simple_transfer::Witness as SimpleTransfer;

    use attach::data;

    // use outlaw_sky::warship::Witness as Namespace;
    // use outlaw_sky::warship::Warship;

    // Error constants
    const ENOT_OWNER: u64 = 0;

    // Genesis-witness and module-authority witness
    struct OUTLAW_SKY has drop {}
    struct Witness has drop { }

    // Shared, root-level object
    struct Outlaw has key, store {
        id: UID
        // Ownership fields
        // Data fields
    }

    // Permission types
    struct EDIT {}

    // ==== Admin Functions ====
    // In production, you would gate each of these functions to make sure they're being called by an
    // authorized party rather than just anyone.

    public entry fun create(data: vector<vector<u8>>, fields: vector<vector<String>>, ctx: &mut TxContext) {
        let auth = tx_authority::begin_with_type(&Witness {});
        let owner = tx_context::sender(ctx);
        let outlaw = Outlaw { 
            id: object::new(ctx) 
        };
        let typed_id = typed_id::new(&outlaw);

        ownership::as_shared_object<Outlaw, SimpleTransfer>(&mut outlaw.id, typed_id, owner, &auth);

        data::deserialize_and_set(Witness {}, &mut outlaw.id, data, fields);

        transfer::share_object(outlaw);
    }

    // We need this wrapper because (1) we need &mut outlaw.id from an entry function, which is not possible until
    // Programmable Transactions are available, and (2) the metadata program requires that we, the creator module, sign off
    // on all changes to metadata.
    public entry fun update(
        outlaw: &mut Outlaw,
        data: vector<vector<u8>>,
        fields: vector<vector<String>>,
        _ctx: &mut TxContext
    ) {
        data::deserialize_and_set(Witness {}, &mut outlaw.id, data, fields);
    }

    // We cannot delete shared objects yet, like the Outlaw itself, but we _can_ delete metadata
    public entry fun remove_all(outlaw: &mut Outlaw, _ctx: &mut TxContext) {
        data::remove_all(Witness {}, &mut outlaw.id);
    }

    public fun load_dispenser() { 
        // TO DO
    }

    fun init(genesis: OUTLAW_SKY, ctx: &mut TxContext) {
        let receipt = publish_receipt::claim(&genesis, ctx);
        transfer::public_transfer(receipt, tx_context::sender(ctx));
    }

    // ====== User Functions ====== 
    // These are samples of how user-facing functions work

    // This will overwrite the field 'name' in the `Witness` namespace with a new string
    public entry fun rename(outlaw: &mut Outlaw, new_name: String, ctx: &TxContext) {
        assert!(client::can_act_as_owner<EDIT>(&outlaw.id, &tx_authority::begin(ctx)), ENOT_OWNER);

        data::set(Witness {}, &mut outlaw.id, vector[utf8(b"name")], vector[new_name]);
    }

    // This is a sample of how atomic updates work; the existing value is borrowed and then modified,
    // rather than simply being overwritten. This is safter for concurrently running processes
    public entry fun add_attribute(outlaw: &mut Outlaw, key: String, value: String, ctx: &mut TxContext) {
        assert!(client::can_act_as_owner<EDIT>(&outlaw.id, &tx_authority::begin(ctx)), ENOT_OWNER);

        let attributes = data::borrow_mut_fill<Witness, VecMap<String, String>>(
            Witness {}, &mut outlaw.id, utf8(b"attributes"), vec_map::empty());

        vec_map2::set(attributes, &key, value);
    }

    public entry fun remove_attribute(outlaw: &mut Outlaw, key: String, ctx: &mut TxContext) {
        assert!(client::can_act_as_owner<EDIT>(&outlaw.id, &tx_authority::begin(ctx)), ENOT_OWNER);

        let attributes = data::borrow_mut_fill<Witness, VecMap<String, String>>(
            Witness {}, &mut outlaw.id, utf8(b"attributes"), vec_map::empty());
            
        vec_map2::remove_maybe(attributes, &key);
    }

    public entry fun increment_power_level(outlaw: &mut Outlaw, ctx: &mut TxContext) {
        assert!(client::can_act_as_owner<EDIT>(&outlaw.id, &tx_authority::begin(ctx)), ENOT_OWNER);

        let power_level = data::borrow_mut_fill<Witness, u64>(
            Witness {}, &mut outlaw.id, utf8(b"power_level"), 0);

        *power_level = *power_level + 1;
    }
    
    // This is using a delegation from Foreign -> Witness
    // public entry fun edit_other_namespace(outlaw: &mut Outlaw, new_name: String, store: &DelegationStore) {
    //     let auth = tx_authority::begin_with_type(&Witness {});
    //     auth = tx_authority::add_from_delegation_store(store, &auth);
    //     let namespace_addr = tx_authority::type_into_address<Namespace>();
    //     data::set_(&mut outlaw.id, option::some(namespace_addr), vector[utf8(b"name")], vector[new_name], &auth);
    // }

    // This is using a delegation from Foreign -> address
    // public entry fun edit_other_namespace2(outlaw: &mut Outlaw, new_name: String, store: &DelegationStore, ctx: &mut TxContext) {
    //     let auth = tx_authority::begin(ctx);
    //     auth = tx_authority::add_from_delegation_store(store, &auth);
    //     let namespace_addr = tx_authority::type_into_address<Namespace>();
    //     data::set_(&mut outlaw.id, option::some(namespace_addr), vector[utf8(b"name")], vector[new_name], &auth);
    // }

    // public entry fun edit_as_someone_else(warship: &mut Warship, new_name: String, store: &DelegationStore) {
    //     // Get a different namespace
    //     let auth = tx_authority::begin_from_type(&Witness {});
    //     auth = tx_authority::add_from_delegation_store(store, &auth);
    //     let namespace_addr = tx_authority::type_into_address<Namespace>();

    //     // We have a permission added to this warship; warship.owner has granted our ctx-address permission to edit
    //     // Delegation { for: our-ctx }
    //     let uid = warship::uid_mut(warship, &auth);
    //     data::set_(&mut warship.id, option::some(namespace_addr), vector[utf8(b"name")], vector[new_name], &auth);

    //     // warship.owner has granted Witness permission to edit
    //     // Delegation { for: Witness }

    //     // Warship module has granted our ctx-address permission to edit
    //     // DelegationStore { for: our-ctx }

    //     // Warship module has granted Witness permission to edit
    //     // DelegationStore { for: Witness }
    // }

    // ==== General Functions ====

    // This function is needed until we can use UID's directly in devInspect transactions
    public fun view_all(outlaw: &Outlaw, namespace: Option<ID>): vector<u8> {
        data::view_all(&outlaw.id, namespace)
    }

    public fun uid(outlaw: &Outlaw): (&UID) {
        &outlaw.id
    }

    public fun uid_mut(outlaw: &mut Outlaw, auth: &TxAuthority): (&mut UID) {
        assert!(client::can_borrow_uid_mut(&outlaw.id, auth), ENOT_OWNER);

        &mut outlaw.id
    }
}

#[test_only]
module outlaw_sky::tests {
    use std::string::{String, utf8};

    use sui::test_scenario;

    use ownership::tx_authority;

    use display::schema;
    use display::display;

    use outlaw_sky::outlaw_sky;

    // Test constants
    const DATA: vector<vector<u8>> = vector[ vector[6, 79, 117, 116, 108, 97, 119], vector[1, 65, 84, 104, 101, 115, 101, 32, 97, 114, 101, 32, 100, 101, 109, 111, 32, 79, 117, 116, 108, 97, 119, 115, 32, 99, 114, 101, 97, 116, 101, 100, 32, 98, 121, 32, 67, 97, 112, 115, 117, 108, 101, 67, 114, 101, 97, 116, 111, 114, 32, 102, 111, 114, 32, 111, 117, 114, 32, 116, 117, 116, 111, 114, 105, 97, 108], vector[77, 104, 116, 116, 112, 115, 58, 47, 47, 112, 98, 115, 46, 116, 119, 105, 109, 103, 46, 99, 111, 109, 47, 112, 114, 111, 102, 105, 108, 101, 95, 105, 109, 97, 103, 101, 115, 47, 49, 53, 54, 57, 55, 50, 55, 51, 50, 52, 48, 56, 49, 51, 50, 56, 49, 50, 56, 47, 55, 115, 85, 110, 74, 118, 82, 103, 95, 52, 48, 48, 120, 52, 48, 48, 46, 106, 112, 103], vector[199, 0, 0, 0, 0, 0, 0, 0], vector[0] ];

    #[test]
    public fun test_rename() {
        let schema_fields = vector[ vector[utf8(b"name"), utf8(b"String")], vector[utf8(b"description"), utf8(b"String")], vector[utf8(b"image"), utf8(b"String")], vector[utf8(b"power_level"), utf8(b"u64")], vector[utf8(b"attributes"), utf8(b"VecMap")] ];

        let scenario = test_scenario::begin(@0x79);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            
            let schema = schema::create_from_strings(schema_fields, ctx);
            outlaw_sky::create(DATA, &schema, ctx);
            schema::freeze_(schema);
        };

        test_scenario::next_tx(&mut scenario, @0x79);
        {
            let outlaw = test_scenario::take_shared<outlaw_sky::Outlaw>(&scenario);
            let schema = test_scenario::take_immutable<schema::Schema>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);

            outlaw_sky::rename(&mut outlaw, utf8(b"New Name"), &schema, ctx);
            let auth = tx_authority::begin(ctx);
            let uid = outlaw_sky::extend(&mut outlaw, &auth);
            let name = display::borrow<String>(uid, utf8(b"name"));
            assert!(*name == utf8(b"New Name"), 0);

            test_scenario::return_shared(outlaw);
            test_scenario::return_immutable(schema);
        };

        test_scenario::end(scenario);
    }
}