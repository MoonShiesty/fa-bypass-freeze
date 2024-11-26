# fungible asset freeze bypass overview

An adversary can prevent a fungible asset (token) issuer from ever freezing or accessing their tokens, and then later withdraw those funds to any address, including another address that has already prevented freezing. This means in the event of an exploit or use of funds by a restricted entity, a fungible asset would be unable to prevent those users from accessing and spending their tokens.

Fungible assets such as USDT and USDC rely on a resource TransferRef to freeze, withdraw, deposit, assets from users FungibleStore via set_frozen_flag(), withdraw_with_ref(), deposit_with_ref()

These functions take a reference to the FungibleStore store: Object<T>. To create such a reference, either by calling an entry function, or through a cross-contract call, the resource ObjectCore must exist in the FungibleStore address. Without such a reference, theset_frozen_flag, as well as any other function in the fungible asset module that requires Object<T> as input will revert because the object does not exist.

This means that if an adversary destroys the object containing FungibleStore, the manager of the FungibleAsset such as Tether will be unable to freeze the adversaries assets. This can be done by calling object::delete with the object's DeleteRef.

Without a store Object<T> the adversary would be unable to later withdraw the assets after deleting the object. However, the adversary can simple store an Object<FungibleStore before calling object::delete on the store object.

However, withdraw() also calls withdraw_sanity_check() which calls object::owns. object::owns checks the ownership of the object to confirm the signer either owns the object OR the signer is the object address. Importantly, if the signer is the object address, this function does not check if the object still exists and wasn't previously deleted. An adversary can create a signature for the object by storing an ExtendRef and then later signing as the object to withdraw the assets.

# steps to reproduce
I created a proof of concept of this exploit and verified with a local deployment that i could:

1) deposit tokens to a FungibleStore, delete the object and set_frozen_flag() and any other fungible_asset function that accesses the store reverts
2) later withdraw from the same FungibleStore for which the set_frozen_flag() reverts when called
3) if i don't delete the object, set_frozen_flag() works correctly

step to reproduce with proof of concept

1) aptos move create-object-and-publish-package --move-2 --address-name fungible_asset_bypass
2) call mint_to_with_bypass() (you can find the FungibleStore address in the transaction events)
3) call enable_bypass() with theFungibleStore address
4) freeze_store() will now revert with the FungibleStore address
5) withdraw_with_bypass() will deposit the funds in the users wallet (primary_fungible_store)

if step 3) is skipped, 4) freeze_store() will succeed and step 5) will fail

