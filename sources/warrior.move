/// Warrior game module demonstrating Sui's object-centric model.
///
/// This module showcases:
/// - One-Time Witness (OTW) based initialization
/// - Owned vs shared objects
/// - Dynamic Object Fields for equipment
/// - Object-based authorization (no signer)
/// - Production-style testing patterns
#[allow(lint(self_transfer))]
module sui_warriors::warrior {

    use std::string::String;
    use sui::event;
    use sui::dynamic_object_field as dof;

    // --- Errors ---

    /// A attempting to unequip from a non-existent slot
    const EInvalidSlot: u64 = 0;

    /// A attempting to equip into an occupied slot
    const ESlotOccupied: u64 = 1;

    // --- One time Witness (OTW) ---

    /// One-Time Witness used to guarantee single execution of `init`
    ///
    /// This type can only be created at publish time and ensures
    /// the shared `Forge` object is initialized exactly once.
    public struct WARRIOR has drop {}

    // --- Objects ---

    /// Core player-owned character object
    ///
    /// Ownership of this object grants full authority to:
    /// - Equip items
    /// - Unequip items
    /// - Use the warrior in combat
    public struct Warrior has key, store {
        /// Unique object ID
        id: UID,

        /// Display name of the warrior
        name: String,

        /// Base combat strength without equipment
        base_strength: u64
    }

    /// Weapon object that can be equipped by a `Warrior`
    ///
    /// Swords are independent owned objects until equipped,
    /// at which point they become dynamic fields of a Warrior.
    public struct Sword has key, store {
        /// Unique object ID
        id: UID,

        /// Weapon name
        name: String,

        /// Weapon power added to warrior strength
        power: u64
    }

    /// Shared protocol-level object responsible for minting swords
    ///
    /// Demonstrates shared object usage and global state tracking.
    public struct Forge has key {
        /// Unique object ID
        id: UID,

        /// Total number of swords forged so far
        swords_forged: u64
    }

    // --- Events ---

    /// Emitted when a new Warrior is minted
    public struct WarriorMinted has copy, drop {
        /// Address derived from the warrior UID
        id: address,

        /// Address of the creator (transaction sender)
        creator: address
    }

    // --- Init ---

    /// Module initializer
    ///
    /// Creates and shares the global `Forge` object.
    /// This function can only be called once due to OTW enforcement.
    fun init(_witness: WARRIOR, ctx: &mut TxContext) {
        let forge = Forge {
            id: object::new(ctx),
            swords_forged: 0
        };

        transfer::share_object(forge);
    }

    // --- Public Entry Functions ---

    /// Mint a new `Warrior` object
    ///
    /// The newly created warrior is transferred to the transaction sender.
    public fun mint_warrior(name: String, ctx: &mut TxContext) {
        let id = object::new(ctx);
        let warrior_addr = object::uid_to_address(&id);
        let sender = tx_context::sender(ctx);

        let warrior = Warrior {
            id,
            name,
            base_strength: 10
        };

        // Transfer ownership of the warrior to the user
        transfer::public_transfer(warrior, sender);

        // Emit mint event
        event::emit(WarriorMinted {
            id: warrior_addr,
            creator: sender
        });
    }

    /// Mint a new `Sword` via the shared `Forge`
    ///
    /// Requires mutable access to the shared Forge object.
    public fun mint_sword(
        forge: &mut Forge,
        name: String,
        power: u64,
        ctx: &mut TxContext
    ) {
        // Increment global forge counter
        forge.swords_forged = forge.swords_forged + 1;

        let sword = Sword {
            id: object::new(ctx),
            name,
            power
        };

        // Transfer sword ownership to the transaction sender
        transfer::public_transfer(sword, tx_context::sender(ctx));
    }

    /// Equip a sword into a specific slot on a warrior
    ///
    /// The sword becomes a dynamic object field attached to the warrior.
    public fun equip(
        warrior: &mut Warrior,
        slot: vector<u8>,
        sword: Sword,
        _ctx: &mut TxContext
    ) {
        // Prevent overwriting an occupied slot
        if (dof::exists_(&warrior.id, slot)) {
            abort ESlotOccupied
        };

        // Attach the sword as a dynamic field to the warrior
        dof::add(&mut warrior.id, slot, sword);
    }

    /// Unequip a sword from a warrior slot
    ///
    /// The sword is removed from the dynamic field and
    /// transferred back to the transaction sender.
    public fun unequip(
        warrior: &mut Warrior,
        slot: vector<u8>,
        ctx: &mut TxContext
    ) {
        // Ensure the slot exists
        assert!(dof::exists_(&warrior.id, slot), EInvalidSlot);

        // Remove the sword object from the warrior
        let sword = dof::remove<vector<u8>, Sword>(&mut warrior.id, slot);

        // Transfer sword back to the user
        transfer::public_transfer(sword, tx_context::sender(ctx));
    }

    /// Simulate combat against a monster
    ///
    /// Calculates total power using base strength plus
    /// equipped sword (if present).
    public fun fight_monster(
        warrior: &Warrior,
        slot: vector<u8>,
        monster_power: u64
    ): bool {
        let mut total_power = warrior.base_strength;

        // If a sword is equipped, include its power
        if (dof::exists_(&warrior.id, slot)) {
            let sword_ref = dof::borrow<vector<u8>, Sword>(&warrior.id, slot);
            total_power = total_power + sword_ref.power;
        };

        total_power >= monster_power
    }

    // --- Test Utilities ---

    /// Test-only initializer
    ///
    /// Bypasses the OTW requirement to allow
    /// isolated unit testing.
    #[test_only]
    public fun test_init(ctx: &mut TxContext) {
        let forge = Forge {
            id: object::new(ctx),
            swords_forged: 0
        };

        transfer::share_object(forge);
    }
}
