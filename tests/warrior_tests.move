#[test_only]
module sui_warriors::warrior_tests {

    use sui::test_scenario;
    use sui_warriors::warrior;
    use std::string::utf8;

    const ADMIN: address = @0xAD;
    const USER: address = @0xB0B;

    #[test]
    fun test_full_game_loop(){
        let mut scenario = test_scenario::begin(ADMIN);

        {
            let ctx = test_scenario::ctx(&mut scenario);
            warrior::test_init(ctx);
        };

        // User mints a Warrior
        test_scenario::next_tx(&mut scenario, USER);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            warrior::mint_warrior(utf8(b"Conan"), ctx);
        };

        // Verify Warrior and Mint Sword
        test_scenario::next_tx(&mut scenario, USER);
        {
            let mut forge = test_scenario::take_shared<warrior::Forge>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);

            warrior::mint_sword(
                &mut forge,
                utf8(b"Excalibur"),
                50,
                ctx
            );

            test_scenario::return_shared(forge);
        };

        // Equip 
        test_scenario::next_tx(&mut scenario, USER);
        {
            let sword = test_scenario::take_from_sender<warrior::Sword>(&scenario);
            let mut hero = test_scenario::take_from_sender<warrior::Warrior>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);

            warrior::equip(&mut hero, b"main_hand", sword, ctx);

            test_scenario::return_to_sender(&scenario, hero);
        };

        // Fight
        test_scenario::next_tx(&mut scenario, USER);
        {
            let hero = test_scenario::take_from_sender<warrior::Warrior>(&scenario);

            assert!(warrior::fight_monster(&hero, b"main_hand", 40), 0);
            assert!(!warrior::fight_monster(&hero, b"main_hand", 80), 0);

            test_scenario::return_to_sender(&scenario, hero);
        };

        test_scenario::end(scenario);
    }
}