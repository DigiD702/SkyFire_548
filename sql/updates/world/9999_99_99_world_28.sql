-- Bind player/class/item/generic C++ spell scripts missing from spell_script_names.
-- Uses positive MoP spell IDs (replaces obsolete negative-rank family bindings).

DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_dk_death_strike';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_dk_death_strike_enabler';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_dk_icebound_fortitude';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_dk_necrotic_strike';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_dk_rune_tap_party';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_dk_scent_of_blood';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_dk_vampiric_blood';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_dru_dash';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_dru_eclipse_lunar';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_dru_eclipse_solar';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_dru_glyph_of_innervate';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_dru_glyph_of_starfire';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_dru_glyph_of_starfire_proc';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_dru_innervate';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_dru_lifebloom';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_dru_living_seed';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_dru_stampede';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_dru_starfall_dummy';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_gen_alchemist_stone';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_gen_bandage';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_gen_clone';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_gen_create_lance';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_gen_creature_permanent_feign_death';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_gen_gift_of_naaru';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_gen_interrupt';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_gen_netherbloom';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_gen_override_display_power';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_hun_fire';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_hun_improved_serpent_sting';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_hun_invigoration';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_hun_ready_set_aim';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_hun_thrill_of_the_hunt';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_item_aegis_of_preservation';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_item_arcane_shroud';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_item_desperate_defense';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_item_gnomish_army_knife';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_item_goblin_jumper_cables';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_item_goblin_jumper_cables_xl';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_item_scroll_of_recall';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_item_the_eye_of_diminution';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_mage_glyph_of_ice_block';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_mage_glyph_of_polymorph';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_mage_ignite';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_mage_living_bomb';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_mage_ring_of_frost';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_mage_ring_of_frost_freeze';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_monk_bear_hug';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_monk_blackout_kick';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_monk_breath_of_fire';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_monk_chi_burst';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_monk_chi_torpedo';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_monk_clash';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_monk_crackling_jade_lightning';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_monk_diffuse_magic';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_monk_elusive_brew';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_monk_energizing_brew';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_monk_enveloping_mist';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_monk_expel_harm';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_monk_fortifying_brew';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_monk_glyph_of_mana_tea';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_monk_glyph_of_zen_flight';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_monk_grapple_weapon';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_monk_guard';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_monk_healing_elixirs';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_monk_keg_smash';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_monk_mana_tea';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_monk_mana_tea_stacks';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_monk_power_strikes';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_monk_purifying_brew';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_monk_serpents_zeal';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_monk_soothing_mist';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_monk_spear_hand_strike';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_monk_spinning_fire_blossom';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_monk_spinning_fire_blossom_damage';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_monk_surging_mist';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_monk_teachings_of_the_monastery';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_monk_tigereye_brew';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_monk_tigereye_brew_stacks';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_monk_tigers_lust';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_monk_touch_of_death';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_monk_zen_flight_check';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_monk_zen_pilgrimage';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_monk_zen_sphere';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_monk_zen_sphere_hot';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_pal_aura_mastery';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_pal_aura_mastery_immune';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_pal_beacon_of_light';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_pal_grand_crusader';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_pal_holy_shock';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_pal_item_healing_discount';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_pal_sacred_shield';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_pri_item_greater_heal_refund';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_pri_lightwell_renew';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_pri_mind_sear';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_pri_penance';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_pri_power_word_shield';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_pri_shadow_word_death';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_pri_vampiric_embrace';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_pri_vampiric_embrace_target';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_pri_vampiric_touch';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_rog_crippling_poison';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_rog_cut_to_the_chase';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_rog_deadly_poison';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_rog_rupture';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_sha_ancestral_awakening';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_sha_earth_shield';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_sha_glyph_of_healing_wave';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_sha_healing_stream_totem';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_sha_item_lightning_shield';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_sha_item_lightning_shield_trigger';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_sha_item_mana_surge';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_sha_mana_tide_totem';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_sha_nature_guardian';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_sha_telluric_currents';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_sha_thunderstorm';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_sha_tidal_waves';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_warl_fel_synergy';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_warl_healthstone_heal';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_warl_soul_swap';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_warl_soul_swap_dot_marker';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_warl_soul_swap_exhale';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_warl_soul_swap_override';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_warr_intimidating_shout';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_warr_shattering_throw';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_warr_sudden_death';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_warr_sword_and_board';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_warr_victorious';

INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(49998, 'spell_dk_death_strike'),
(89832, 'spell_dk_death_strike_enabler'),
(48792, 'spell_dk_icebound_fortitude'),
(73975, 'spell_dk_necrotic_strike'),
(59754, 'spell_dk_rune_tap_party'),
(50421, 'spell_dk_scent_of_blood'),
(55233, 'spell_dk_vampiric_blood'),
(1850, 'spell_dru_dash'),
(48518, 'spell_dru_eclipse_lunar'),
(48517, 'spell_dru_eclipse_solar'),
(54832, 'spell_dru_glyph_of_innervate'),
(54845, 'spell_dru_glyph_of_starfire'),
(54845, 'spell_dru_glyph_of_starfire_proc'),
(29166, 'spell_dru_innervate'),
(33763, 'spell_dru_lifebloom'),
(48500, 'spell_dru_living_seed'),
(81022, 'spell_dru_stampede'),
(50286, 'spell_dru_starfall_dummy'),
(17619, 'spell_gen_alchemist_stone'),
(746, 'spell_gen_bandage'),
(1159, 'spell_gen_bandage'),
(1160, 'spell_gen_bandage'),
(3267, 'spell_gen_bandage'),
(3268, 'spell_gen_bandage'),
(7926, 'spell_gen_bandage'),
(7927, 'spell_gen_bandage'),
(10838, 'spell_gen_bandage'),
(10839, 'spell_gen_bandage'),
(18608, 'spell_gen_bandage'),
(18610, 'spell_gen_bandage'),
(24414, 'spell_gen_bandage'),
(27030, 'spell_gen_bandage'),
(27031, 'spell_gen_bandage'),
(45543, 'spell_gen_bandage'),
(45544, 'spell_gen_bandage'),
(74556, 'spell_gen_bandage'),
(74557, 'spell_gen_bandage'),
(74558, 'spell_gen_bandage'),
(102694, 'spell_gen_bandage'),
(102695, 'spell_gen_bandage'),
(45204, 'spell_gen_clone'),
(45785, 'spell_gen_clone'),
(49889, 'spell_gen_clone'),
(50218, 'spell_gen_clone'),
(51719, 'spell_gen_clone'),
(57528, 'spell_gen_clone'),
(69828, 'spell_gen_clone'),
(63845, 'spell_gen_create_lance'),
(29266, 'spell_gen_creature_permanent_feign_death'),
(31261, 'spell_gen_creature_permanent_feign_death'),
(35356, 'spell_gen_creature_permanent_feign_death'),
(35357, 'spell_gen_creature_permanent_feign_death'),
(57685, 'spell_gen_creature_permanent_feign_death'),
(58951, 'spell_gen_creature_permanent_feign_death'),
(70592, 'spell_gen_creature_permanent_feign_death'),
(70628, 'spell_gen_creature_permanent_feign_death'),
(71598, 'spell_gen_creature_permanent_feign_death'),
(74490, 'spell_gen_creature_permanent_feign_death'),
(28880, 'spell_gen_gift_of_naaru'),
(59542, 'spell_gen_gift_of_naaru'),
(59543, 'spell_gen_gift_of_naaru'),
(59544, 'spell_gen_gift_of_naaru'),
(59545, 'spell_gen_gift_of_naaru'),
(59547, 'spell_gen_gift_of_naaru'),
(59548, 'spell_gen_gift_of_naaru'),
(121093, 'spell_gen_gift_of_naaru'),
(44835, 'spell_gen_interrupt'),
(28702, 'spell_gen_netherbloom'),
(123933, 'spell_gen_override_display_power'),
(145044, 'spell_gen_override_display_power'),
(145627, 'spell_gen_override_display_power'),
(145628, 'spell_gen_override_display_power'),
(82926, 'spell_hun_fire'),
(82834, 'spell_hun_improved_serpent_sting'),
(53253, 'spell_hun_invigoration'),
(82925, 'spell_hun_ready_set_aim'),
(109306, 'spell_hun_thrill_of_the_hunt'),
(23780, 'spell_item_aegis_of_preservation'),
(26400, 'spell_item_arcane_shroud'),
(33896, 'spell_item_desperate_defense'),
(54732, 'spell_item_gnomish_army_knife'),
(8342, 'spell_item_goblin_jumper_cables'),
(22999, 'spell_item_goblin_jumper_cables_xl'),
(48129, 'spell_item_scroll_of_recall'),
(60320, 'spell_item_scroll_of_recall'),
(60321, 'spell_item_scroll_of_recall'),
(28862, 'spell_item_the_eye_of_diminution'),
(115760, 'spell_mage_glyph_of_ice_block'),
(56375, 'spell_mage_glyph_of_polymorph'),
(12846, 'spell_mage_ignite'),
(44457, 'spell_mage_living_bomb'),
(113724, 'spell_mage_ring_of_frost'),
(136511, 'spell_mage_ring_of_frost'),
(82691, 'spell_mage_ring_of_frost_freeze'),
(127361, 'spell_monk_bear_hug'),
(100784, 'spell_monk_blackout_kick'),
(115181, 'spell_monk_breath_of_fire'),
(123986, 'spell_monk_chi_burst'),
(115008, 'spell_monk_chi_torpedo'),
(121828, 'spell_monk_chi_torpedo'),
(122057, 'spell_monk_clash'),
(126449, 'spell_monk_clash'),
(117952, 'spell_monk_crackling_jade_lightning'),
(122783, 'spell_monk_diffuse_magic'),
(115308, 'spell_monk_elusive_brew'),
(115288, 'spell_monk_energizing_brew'),
(124682, 'spell_monk_enveloping_mist'),
(115072, 'spell_monk_expel_harm'),
(115203, 'spell_monk_fortifying_brew'),
(123763, 'spell_monk_glyph_of_mana_tea'),
(125893, 'spell_monk_glyph_of_zen_flight'),
(117368, 'spell_monk_grapple_weapon'),
(115295, 'spell_monk_guard'),
(122280, 'spell_monk_healing_elixirs'),
(121253, 'spell_monk_keg_smash'),
(115294, 'spell_monk_mana_tea'),
(123766, 'spell_monk_mana_tea_stacks'),
(121817, 'spell_monk_power_strikes'),
(119582, 'spell_monk_purifying_brew'),
(127722, 'spell_monk_serpents_zeal'),
(115175, 'spell_monk_soothing_mist'),
(116705, 'spell_monk_spear_hand_strike'),
(115073, 'spell_monk_spinning_fire_blossom'),
(123408, 'spell_monk_spinning_fire_blossom_damage'),
(116694, 'spell_monk_surging_mist'),
(116645, 'spell_monk_teachings_of_the_monastery'),
(116740, 'spell_monk_tigereye_brew'),
(123980, 'spell_monk_tigereye_brew_stacks'),
(116841, 'spell_monk_tigers_lust'),
(115080, 'spell_monk_touch_of_death'),
(125883, 'spell_monk_zen_flight_check'),
(126892, 'spell_monk_zen_pilgrimage'),
(124081, 'spell_monk_zen_sphere'),
(124081, 'spell_monk_zen_sphere_hot'),
(31821, 'spell_pal_aura_mastery'),
(64364, 'spell_pal_aura_mastery_immune'),
(53651, 'spell_pal_beacon_of_light'),
(85416, 'spell_pal_grand_crusader'),
(20473, 'spell_pal_holy_shock'),
(37705, 'spell_pal_item_healing_discount'),
(20925, 'spell_pal_sacred_shield'),
(148039, 'spell_pal_sacred_shield'),
(37594, 'spell_pri_item_greater_heal_refund'),
(7001, 'spell_pri_lightwell_renew'),
(49821, 'spell_pri_mind_sear'),
(47540, 'spell_pri_penance'),
(17, 'spell_pri_power_word_shield'),
(32379, 'spell_pri_shadow_word_death'),
(15286, 'spell_pri_vampiric_embrace'),
(15290, 'spell_pri_vampiric_embrace_target'),
(34914, 'spell_pri_vampiric_touch'),
(51626, 'spell_rog_crippling_poison'),
(51667, 'spell_rog_cut_to_the_chase'),
(2818, 'spell_rog_deadly_poison'),
(1943, 'spell_rog_rupture'),
(51558, 'spell_sha_ancestral_awakening'),
(974, 'spell_sha_earth_shield'),
(55440, 'spell_sha_glyph_of_healing_wave'),
(52042, 'spell_sha_healing_stream_totem'),
(23551, 'spell_sha_item_lightning_shield'),
(23552, 'spell_sha_item_lightning_shield_trigger'),
(23572, 'spell_sha_item_mana_surge'),
(16191, 'spell_sha_mana_tide_totem'),
(30884, 'spell_sha_nature_guardian'),
(82987, 'spell_sha_telluric_currents'),
(51490, 'spell_sha_thunderstorm'),
(51564, 'spell_sha_tidal_waves'),
(47230, 'spell_warl_fel_synergy'),
(6262, 'spell_warl_healthstone_heal'),
(86121, 'spell_warl_soul_swap'),
(92795, 'spell_warl_soul_swap_dot_marker'),
(86213, 'spell_warl_soul_swap_exhale'),
(86211, 'spell_warl_soul_swap_override'),
(5246, 'spell_warr_intimidating_shout'),
(64380, 'spell_warr_shattering_throw'),
(65941, 'spell_warr_shattering_throw'),
(29725, 'spell_warr_sudden_death'),
(52437, 'spell_warr_sudden_death'),
(46953, 'spell_warr_sword_and_board'),
(32216, 'spell_warr_victorious');
