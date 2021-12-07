public PlVers:__version =
{
	version = 5,
	filevers = "1.6.3",
	date = "04/26/2015",
	time = "13:16:59"
};
new Float:NULL_VECTOR[3];
new String:NULL_STRING[4];
public Extension:__ext_core =
{
	name = "Core",
	file = "core",
	autoload = 0,
	required = 0,
};
new MaxClients;
public Extension:__ext_sdktools =
{
	name = "SDKTools",
	file = "sdktools.ext",
	autoload = 1,
	required = 1,
};
public Extension:__ext_sdkhooks =
{
	name = "SDKHooks",
	file = "sdkhooks.ext",
	autoload = 1,
	required = 1,
};
new indicator;
new adt_log;
new global_stats[10];
new adt_clients;
new Handle:SQLcon;
new index_g;
new index_b;
new count_g;
new count_b = 5;
public Plugin:myinfo =
{
	name = "Dota 2 - Stats",
	description = "Dota 2 - Stats",
	author = "(2K)Ronaldo",
	version = "1.0",
	url = ""
};
public __ext_core_SetNTVOptional()
{
	MarkNativeAsOptional("GetFeatureStatus");
	MarkNativeAsOptional("RequireFeature");
	MarkNativeAsOptional("AddCommandListener");
	MarkNativeAsOptional("RemoveCommandListener");
	MarkNativeAsOptional("BfWriteBool");
	MarkNativeAsOptional("BfWriteByte");
	MarkNativeAsOptional("BfWriteChar");
	MarkNativeAsOptional("BfWriteShort");
	MarkNativeAsOptional("BfWriteWord");
	MarkNativeAsOptional("BfWriteNum");
	MarkNativeAsOptional("BfWriteFloat");
	MarkNativeAsOptional("BfWriteString");
	MarkNativeAsOptional("BfWriteEntity");
	MarkNativeAsOptional("BfWriteAngle");
	MarkNativeAsOptional("BfWriteCoord");
	MarkNativeAsOptional("BfWriteVecCoord");
	MarkNativeAsOptional("BfWriteVecNormal");
	MarkNativeAsOptional("BfWriteAngles");
	MarkNativeAsOptional("BfReadBool");
	MarkNativeAsOptional("BfReadByte");
	MarkNativeAsOptional("BfReadChar");
	MarkNativeAsOptional("BfReadShort");
	MarkNativeAsOptional("BfReadWord");
	MarkNativeAsOptional("BfReadNum");
	MarkNativeAsOptional("BfReadFloat");
	MarkNativeAsOptional("BfReadString");
	MarkNativeAsOptional("BfReadEntity");
	MarkNativeAsOptional("BfReadAngle");
	MarkNativeAsOptional("BfReadCoord");
	MarkNativeAsOptional("BfReadVecCoord");
	MarkNativeAsOptional("BfReadVecNormal");
	MarkNativeAsOptional("BfReadAngles");
	MarkNativeAsOptional("BfGetNumBytesLeft");
	MarkNativeAsOptional("PbReadInt");
	MarkNativeAsOptional("PbReadFloat");
	MarkNativeAsOptional("PbReadBool");
	MarkNativeAsOptional("PbReadString");
	MarkNativeAsOptional("PbReadColor");
	MarkNativeAsOptional("PbReadAngle");
	MarkNativeAsOptional("PbReadVector");
	MarkNativeAsOptional("PbReadVector2D");
	MarkNativeAsOptional("PbGetRepeatedFieldCount");
	MarkNativeAsOptional("PbSetInt");
	MarkNativeAsOptional("PbSetFloat");
	MarkNativeAsOptional("PbSetBool");
	MarkNativeAsOptional("PbSetString");
	MarkNativeAsOptional("PbSetColor");
	MarkNativeAsOptional("PbSetAngle");
	MarkNativeAsOptional("PbSetVector");
	MarkNativeAsOptional("PbSetVector2D");
	MarkNativeAsOptional("PbAddInt");
	MarkNativeAsOptional("PbAddFloat");
	MarkNativeAsOptional("PbAddBool");
	MarkNativeAsOptional("PbAddString");
	MarkNativeAsOptional("PbAddColor");
	MarkNativeAsOptional("PbAddAngle");
	MarkNativeAsOptional("PbAddVector");
	MarkNativeAsOptional("PbAddVector2D");
	MarkNativeAsOptional("PbRemoveRepeatedFieldValue");
	MarkNativeAsOptional("PbReadMessage");
	MarkNativeAsOptional("PbReadRepeatedMessage");
	MarkNativeAsOptional("PbAddMessage");
	VerifyCoreVersion();
	return 0;
}

FindCharInString(String:str[], c, bool:reverse)
{
	new i;
	new len = strlen(str);
	if (!reverse)
	{
		i = 0;
		while (i < len)
		{
			if (c == str[i])
			{
				return i;
			}
			i++;
		}
	}
	else
	{
		i = len + -1;
		while (0 <= i)
		{
			if (c == str[i])
			{
				return i;
			}
			i--;
		}
	}
	return -1;
}

StrCat(String:buffer[], maxlength, String:source[])
{
	new len = strlen(buffer);
	if (len >= maxlength)
	{
		return 0;
	}
	return Format(buffer[len], maxlength - len, "%s", source);
}

subSTR(String:str[], inc, fin)
{
	new String:result[16];
	new i = inc;
	while (i < fin)
	{
		StrCat(result, fin - inc, str[i]);
		i++;
	}
	return result;
}

Handle:SQL_DefConnect(String:error[], maxlength, bool:persistent)
{
	return SQL_Connect("default", persistent, error, maxlength);
}

GetAbilityIdByName(String:AbilityName[])
{
	new id;
	if (!strcmp(AbilityName, "ability_base", true))
	{
		id = 0;
	}
	if (!strcmp(AbilityName, "default_attack", true))
	{
		id = 5001;
	}
	if (!strcmp(AbilityName, "attribute_bonus", true))
	{
		id = 5002;
	}
	if (!strcmp(AbilityName, "antimage_mana_break", true))
	{
		id = 5003;
	}
	if (!strcmp(AbilityName, "antimage_blink", true))
	{
		id = 5004;
	}
	if (!strcmp(AbilityName, "antimage_spell_shield", true))
	{
		id = 5005;
	}
	if (!strcmp(AbilityName, "antimage_mana_void", true))
	{
		id = 5006;
	}
	if (!strcmp(AbilityName, "axe_berserkers_call", true))
	{
		id = 5007;
	}
	if (!strcmp(AbilityName, "axe_battle_hunger", true))
	{
		id = 5008;
	}
	if (!strcmp(AbilityName, "axe_counter_helix", true))
	{
		id = 5009;
	}
	if (!strcmp(AbilityName, "axe_culling_blade", true))
	{
		id = 5010;
	}
	if (!strcmp(AbilityName, "bane_enfeeble", true))
	{
		id = 5012;
	}
	if (!strcmp(AbilityName, "bane_brain_sap", true))
	{
		id = 5011;
	}
	if (!strcmp(AbilityName, "bane_fiends_grip", true))
	{
		id = 5013;
	}
	if (!strcmp(AbilityName, "bane_nightmare", true))
	{
		id = 5014;
	}
	if (!strcmp(AbilityName, "bane_nightmare_end", true))
	{
		id = 5523;
	}
	if (!strcmp(AbilityName, "bloodseeker_bloodrage", true))
	{
		id = 5015;
	}
	if (!strcmp(AbilityName, "bloodseeker_blood_bath", true))
	{
		id = 5016;
	}
	if (!strcmp(AbilityName, "bloodseeker_thirst", true))
	{
		id = 5017;
	}
	if (!strcmp(AbilityName, "bloodseeker_rupture", true))
	{
		id = 5018;
	}
	if (!strcmp(AbilityName, "drow_ranger_frost_arrows", true))
	{
		id = 5019;
	}
	if (!strcmp(AbilityName, "drow_ranger_silence", true))
	{
		id = 5020;
	}
	if (!strcmp(AbilityName, "drow_ranger_wave_of_silence", true))
	{
		id = 5632;
	}
	if (!strcmp(AbilityName, "drow_ranger_trueshot", true))
	{
		id = 5021;
	}
	if (!strcmp(AbilityName, "drow_ranger_marksmanship", true))
	{
		id = 5022;
	}
	if (!strcmp(AbilityName, "earthshaker_fissure", true))
	{
		id = 5023;
	}
	if (!strcmp(AbilityName, "earthshaker_enchant_totem", true))
	{
		id = 5024;
	}
	if (!strcmp(AbilityName, "earthshaker_aftershock", true))
	{
		id = 5025;
	}
	if (!strcmp(AbilityName, "earthshaker_echo_slam", true))
	{
		id = 5026;
	}
	if (!strcmp(AbilityName, "juggernaut_blade_dance", true))
	{
		id = 5027;
	}
	if (!strcmp(AbilityName, "juggernaut_blade_fury", true))
	{
		id = 5028;
	}
	if (!strcmp(AbilityName, "juggernaut_healing_ward", true))
	{
		id = 5029;
	}
	if (!strcmp(AbilityName, "juggernaut_omni_slash", true))
	{
		id = 5030;
	}
	if (!strcmp(AbilityName, "kunkka_torrent", true))
	{
		id = 5031;
	}
	if (!strcmp(AbilityName, "kunkka_tidebringer", true))
	{
		id = 5032;
	}
	if (!strcmp(AbilityName, "kunkka_x_marks_the_spot", true))
	{
		id = 5033;
	}
	if (!strcmp(AbilityName, "kunkka_return", true))
	{
		id = 5034;
	}
	if (!strcmp(AbilityName, "kunkka_ghostship", true))
	{
		id = 5035;
	}
	if (!strcmp(AbilityName, "lina_dragon_slave", true))
	{
		id = 5040;
	}
	if (!strcmp(AbilityName, "lina_light_strike_array", true))
	{
		id = 5041;
	}
	if (!strcmp(AbilityName, "lina_fiery_soul", true))
	{
		id = 5042;
	}
	if (!strcmp(AbilityName, "lina_laguna_blade", true))
	{
		id = 5043;
	}
	if (!strcmp(AbilityName, "lion_impale", true))
	{
		id = 5044;
	}
	if (!strcmp(AbilityName, "lion_voodoo", true))
	{
		id = 5045;
	}
	if (!strcmp(AbilityName, "lion_mana_drain", true))
	{
		id = 5046;
	}
	if (!strcmp(AbilityName, "lion_finger_of_death", true))
	{
		id = 5047;
	}
	if (!strcmp(AbilityName, "mirana_arrow", true))
	{
		id = 5048;
	}
	if (!strcmp(AbilityName, "mirana_invis", true))
	{
		id = 5049;
	}
	if (!strcmp(AbilityName, "mirana_leap", true))
	{
		id = 5050;
	}
	if (!strcmp(AbilityName, "mirana_starfall", true))
	{
		id = 5051;
	}
	if (!strcmp(AbilityName, "morphling_waveform", true))
	{
		id = 5052;
	}
	if (!strcmp(AbilityName, "morphling_adaptive_strike", true))
	{
		id = 5053;
	}
	if (!strcmp(AbilityName, "morphling_morph", true))
	{
		id = 5054;
	}
	if (!strcmp(AbilityName, "morphling_morph_agi", true))
	{
		id = 5055;
	}
	if (!strcmp(AbilityName, "morphling_morph_str", true))
	{
		id = 5056;
	}
	if (!strcmp(AbilityName, "morphling_replicate", true))
	{
		id = 5057;
	}
	if (!strcmp(AbilityName, "morphling_morph_replicate", true))
	{
		id = 5058;
	}
	if (!strcmp(AbilityName, "nevermore_shadowraze1", true))
	{
		id = 5059;
	}
	if (!strcmp(AbilityName, "nevermore_shadowraze2", true))
	{
		id = 5060;
	}
	if (!strcmp(AbilityName, "nevermore_shadowraze3", true))
	{
		id = 5061;
	}
	if (!strcmp(AbilityName, "nevermore_necromastery", true))
	{
		id = 5062;
	}
	if (!strcmp(AbilityName, "nevermore_dark_lord", true))
	{
		id = 5063;
	}
	if (!strcmp(AbilityName, "nevermore_requiem", true))
	{
		id = 5064;
	}
	if (!strcmp(AbilityName, "phantom_lancer_spirit_lance", true))
	{
		id = 5065;
	}
	if (!strcmp(AbilityName, "phantom_lancer_doppelwalk", true))
	{
		id = 5066;
	}
	if (!strcmp(AbilityName, "phantom_lancer_juxtapose", true))
	{
		id = 5067;
	}
	if (!strcmp(AbilityName, "phantom_lancer_phantom_edge", true))
	{
		id = 5068;
	}
	if (!strcmp(AbilityName, "puck_illusory_orb", true))
	{
		id = 5069;
	}
	if (!strcmp(AbilityName, "puck_ethereal_jaunt", true))
	{
		id = 5070;
	}
	if (!strcmp(AbilityName, "puck_waning_rift", true))
	{
		id = 5071;
	}
	if (!strcmp(AbilityName, "puck_phase_shift", true))
	{
		id = 5072;
	}
	if (!strcmp(AbilityName, "puck_dream_coil", true))
	{
		id = 5073;
	}
	if (!strcmp(AbilityName, "pudge_flesh_heap", true))
	{
		id = 5074;
	}
	if (!strcmp(AbilityName, "pudge_meat_hook", true))
	{
		id = 5075;
	}
	if (!strcmp(AbilityName, "pudge_rot", true))
	{
		id = 5076;
	}
	if (!strcmp(AbilityName, "pudge_dismember", true))
	{
		id = 5077;
	}
	if (!strcmp(AbilityName, "shadow_shaman_ether_shock", true))
	{
		id = 5078;
	}
	if (!strcmp(AbilityName, "shadow_shaman_voodoo", true))
	{
		id = 5079;
	}
	if (!strcmp(AbilityName, "shadow_shaman_shackles", true))
	{
		id = 5080;
	}
	if (!strcmp(AbilityName, "shadow_shaman_mass_serpent_ward", true))
	{
		id = 5081;
	}
	if (!strcmp(AbilityName, "razor_plasma_field", true))
	{
		id = 5082;
	}
	if (!strcmp(AbilityName, "razor_static_link", true))
	{
		id = 5083;
	}
	if (!strcmp(AbilityName, "razor_unstable_current", true))
	{
		id = 5084;
	}
	if (!strcmp(AbilityName, "razor_eye_of_the_storm", true))
	{
		id = 5085;
	}
	if (!strcmp(AbilityName, "skeleton_king_hellfire_blast", true))
	{
		id = 5086;
	}
	if (!strcmp(AbilityName, "skeleton_king_vampiric_aura", true))
	{
		id = 5087;
	}
	if (!strcmp(AbilityName, "skeleton_king_mortal_strike", true))
	{
		id = 5088;
	}
	if (!strcmp(AbilityName, "skeleton_king_reincarnation", true))
	{
		id = 5089;
	}
	if (!strcmp(AbilityName, "death_prophet_carrion_swarm", true))
	{
		id = 5090;
	}
	if (!strcmp(AbilityName, "death_prophet_silence", true))
	{
		id = 5091;
	}
	if (!strcmp(AbilityName, "death_prophet_witchcraft", true))
	{
		id = 5092;
	}
	if (!strcmp(AbilityName, "death_prophet_exorcism", true))
	{
		id = 5093;
	}
	if (!strcmp(AbilityName, "sven_storm_bolt", true))
	{
		id = 5094;
	}
	if (!strcmp(AbilityName, "sven_great_cleave", true))
	{
		id = 5095;
	}
	if (!strcmp(AbilityName, "sven_warcry", true))
	{
		id = 5096;
	}
	if (!strcmp(AbilityName, "sven_gods_strength", true))
	{
		id = 5097;
	}
	if (!strcmp(AbilityName, "storm_spirit_static_remnant", true))
	{
		id = 5098;
	}
	if (!strcmp(AbilityName, "storm_spirit_electric_vortex", true))
	{
		id = 5099;
	}
	if (!strcmp(AbilityName, "storm_spirit_overload", true))
	{
		id = 5100;
	}
	if (!strcmp(AbilityName, "storm_spirit_ball_lightning", true))
	{
		id = 5101;
	}
	if (!strcmp(AbilityName, "sandking_burrowstrike", true))
	{
		id = 5102;
	}
	if (!strcmp(AbilityName, "sandking_sand_storm", true))
	{
		id = 5103;
	}
	if (!strcmp(AbilityName, "sandking_caustic_finale", true))
	{
		id = 5104;
	}
	if (!strcmp(AbilityName, "sandking_epicenter", true))
	{
		id = 5105;
	}
	if (!strcmp(AbilityName, "tiny_avalanche", true))
	{
		id = 5106;
	}
	if (!strcmp(AbilityName, "tiny_toss", true))
	{
		id = 5107;
	}
	if (!strcmp(AbilityName, "tiny_craggy_exterior", true))
	{
		id = 5108;
	}
	if (!strcmp(AbilityName, "tiny_grow", true))
	{
		id = 5109;
	}
	if (!strcmp(AbilityName, "zuus_arc_lightning", true))
	{
		id = 5110;
	}
	if (!strcmp(AbilityName, "zuus_lightning_bolt", true))
	{
		id = 5111;
	}
	if (!strcmp(AbilityName, "zuus_static_field", true))
	{
		id = 5112;
	}
	if (!strcmp(AbilityName, "zuus_thundergods_wrath", true))
	{
		id = 5113;
	}
	if (!strcmp(AbilityName, "slardar_sprint", true))
	{
		id = 5114;
	}
	if (!strcmp(AbilityName, "slardar_slithereen_crush", true))
	{
		id = 5115;
	}
	if (!strcmp(AbilityName, "slardar_bash", true))
	{
		id = 5116;
	}
	if (!strcmp(AbilityName, "slardar_amplify_damage", true))
	{
		id = 5117;
	}
	if (!strcmp(AbilityName, "tidehunter_gush", true))
	{
		id = 5118;
	}
	if (!strcmp(AbilityName, "tidehunter_kraken_shell", true))
	{
		id = 5119;
	}
	if (!strcmp(AbilityName, "tidehunter_anchor_smash", true))
	{
		id = 5120;
	}
	if (!strcmp(AbilityName, "tidehunter_ravage", true))
	{
		id = 5121;
	}
	if (!strcmp(AbilityName, "vengefulspirit_magic_missile", true))
	{
		id = 5122;
	}
	if (!strcmp(AbilityName, "vengefulspirit_command_aura", true))
	{
		id = 5123;
	}
	if (!strcmp(AbilityName, "vengefulspirit_wave_of_terror", true))
	{
		id = 5124;
	}
	if (!strcmp(AbilityName, "vengefulspirit_nether_swap", true))
	{
		id = 5125;
	}
	if (!strcmp(AbilityName, "crystal_maiden_crystal_nova", true))
	{
		id = 5126;
	}
	if (!strcmp(AbilityName, "crystal_maiden_frostbite", true))
	{
		id = 5127;
	}
	if (!strcmp(AbilityName, "crystal_maiden_brilliance_aura", true))
	{
		id = 5128;
	}
	if (!strcmp(AbilityName, "crystal_maiden_freezing_field", true))
	{
		id = 5129;
	}
	if (!strcmp(AbilityName, "windrunner_shackleshot", true))
	{
		id = 5130;
	}
	if (!strcmp(AbilityName, "windrunner_powershot", true))
	{
		id = 5131;
	}
	if (!strcmp(AbilityName, "windrunner_windrun", true))
	{
		id = 5132;
	}
	if (!strcmp(AbilityName, "windrunner_focusfire", true))
	{
		id = 5133;
	}
	if (!strcmp(AbilityName, "lich_frost_nova", true))
	{
		id = 5134;
	}
	if (!strcmp(AbilityName, "lich_frost_armor", true))
	{
		id = 5135;
	}
	if (!strcmp(AbilityName, "lich_dark_ritual", true))
	{
		id = 5136;
	}
	if (!strcmp(AbilityName, "lich_chain_frost", true))
	{
		id = 5137;
	}
	if (!strcmp(AbilityName, "witch_doctor_paralyzing_cask", true))
	{
		id = 5138;
	}
	if (!strcmp(AbilityName, "witch_doctor_voodoo_restoration", true))
	{
		id = 5139;
	}
	if (!strcmp(AbilityName, "witch_doctor_maledict", true))
	{
		id = 5140;
	}
	if (!strcmp(AbilityName, "witch_doctor_death_ward", true))
	{
		id = 5141;
	}
	if (!strcmp(AbilityName, "riki_smoke_screen", true))
	{
		id = 5142;
	}
	if (!strcmp(AbilityName, "riki_blink_strike", true))
	{
		id = 5143;
	}
	if (!strcmp(AbilityName, "riki_backstab", true))
	{
		id = 5144;
	}
	if (!strcmp(AbilityName, "riki_permanent_invisibility", true))
	{
		id = 5145;
	}
	if (!strcmp(AbilityName, "enigma_malefice", true))
	{
		id = 5146;
	}
	if (!strcmp(AbilityName, "enigma_demonic_conversion", true))
	{
		id = 5147;
	}
	if (!strcmp(AbilityName, "enigma_midnight_pulse", true))
	{
		id = 5148;
	}
	if (!strcmp(AbilityName, "enigma_black_hole", true))
	{
		id = 5149;
	}
	if (!strcmp(AbilityName, "tinker_laser", true))
	{
		id = 5150;
	}
	if (!strcmp(AbilityName, "tinker_heat_seeking_missile", true))
	{
		id = 5151;
	}
	if (!strcmp(AbilityName, "tinker_march_of_the_machines", true))
	{
		id = 5152;
	}
	if (!strcmp(AbilityName, "tinker_rearm", true))
	{
		id = 5153;
	}
	if (!strcmp(AbilityName, "sniper_shrapnel", true))
	{
		id = 5154;
	}
	if (!strcmp(AbilityName, "sniper_headshot", true))
	{
		id = 5155;
	}
	if (!strcmp(AbilityName, "sniper_take_aim", true))
	{
		id = 5156;
	}
	if (!strcmp(AbilityName, "sniper_assassinate", true))
	{
		id = 5157;
	}
	if (!strcmp(AbilityName, "necrolyte_death_pulse", true))
	{
		id = 5158;
	}
	if (!strcmp(AbilityName, "necrolyte_heartstopper_aura", true))
	{
		id = 5159;
	}
	if (!strcmp(AbilityName, "necrolyte_sadist", true))
	{
		id = 5160;
	}
	if (!strcmp(AbilityName, "necrolyte_reapers_scythe", true))
	{
		id = 5161;
	}
	if (!strcmp(AbilityName, "warlock_fatal_bonds", true))
	{
		id = 5162;
	}
	if (!strcmp(AbilityName, "warlock_shadow_word", true))
	{
		id = 5163;
	}
	if (!strcmp(AbilityName, "warlock_upheaval", true))
	{
		id = 5164;
	}
	if (!strcmp(AbilityName, "warlock_rain_of_chaos", true))
	{
		id = 5165;
	}
	if (!strcmp(AbilityName, "warlock_golem_flaming_fists", true))
	{
		id = 5166;
	}
	if (!strcmp(AbilityName, "warlock_golem_permanent_immolation", true))
	{
		id = 5167;
	}
	if (!strcmp(AbilityName, "beastmaster_wild_axes", true))
	{
		id = 5168;
	}
	if (!strcmp(AbilityName, "beastmaster_call_of_the_wild", true))
	{
		id = 5169;
	}
	if (!strcmp(AbilityName, "beastmaster_call_of_the_wild_boar", true))
	{
		id = 5580;
	}
	if (!strcmp(AbilityName, "beastmaster_hawk_invisibility", true))
	{
		id = 5170;
	}
	if (!strcmp(AbilityName, "beastmaster_boar_poison", true))
	{
		id = 5171;
	}
	if (!strcmp(AbilityName, "beastmaster_greater_boar_poison", true))
	{
		id = 5352;
	}
	if (!strcmp(AbilityName, "beastmaster_inner_beast", true))
	{
		id = 5172;
	}
	if (!strcmp(AbilityName, "beastmaster_primal_roar", true))
	{
		id = 5177;
	}
	if (!strcmp(AbilityName, "queenofpain_shadow_strike", true))
	{
		id = 5173;
	}
	if (!strcmp(AbilityName, "queenofpain_blink", true))
	{
		id = 5174;
	}
	if (!strcmp(AbilityName, "queenofpain_scream_of_pain", true))
	{
		id = 5175;
	}
	if (!strcmp(AbilityName, "queenofpain_sonic_wave", true))
	{
		id = 5176;
	}
	if (!strcmp(AbilityName, "venomancer_venomous_gale", true))
	{
		id = 5178;
	}
	if (!strcmp(AbilityName, "venomancer_poison_sting", true))
	{
		id = 5179;
	}
	if (!strcmp(AbilityName, "venomancer_plague_ward", true))
	{
		id = 5180;
	}
	if (!strcmp(AbilityName, "venomancer_poison_nova", true))
	{
		id = 5181;
	}
	if (!strcmp(AbilityName, "faceless_void_time_walk", true))
	{
		id = 5182;
	}
	if (!strcmp(AbilityName, "faceless_void_backtrack", true))
	{
		id = 5183;
	}
	if (!strcmp(AbilityName, "faceless_void_time_lock", true))
	{
		id = 5184;
	}
	if (!strcmp(AbilityName, "faceless_void_chronosphere", true))
	{
		id = 5185;
	}
	if (!strcmp(AbilityName, "pugna_nether_blast", true))
	{
		id = 5186;
	}
	if (!strcmp(AbilityName, "pugna_decrepify", true))
	{
		id = 5187;
	}
	if (!strcmp(AbilityName, "pugna_nether_ward", true))
	{
		id = 5188;
	}
	if (!strcmp(AbilityName, "pugna_life_drain", true))
	{
		id = 5189;
	}
	if (!strcmp(AbilityName, "phantom_assassin_stifling_dagger", true))
	{
		id = 5190;
	}
	if (!strcmp(AbilityName, "phantom_assassin_phantom_strike", true))
	{
		id = 5191;
	}
	if (!strcmp(AbilityName, "phantom_assassin_blur", true))
	{
		id = 5192;
	}
	if (!strcmp(AbilityName, "phantom_assassin_coup_de_grace", true))
	{
		id = 5193;
	}
	if (!strcmp(AbilityName, "templar_assassin_refraction", true))
	{
		id = 5194;
	}
	if (!strcmp(AbilityName, "templar_assassin_meld", true))
	{
		id = 5195;
	}
	if (!strcmp(AbilityName, "templar_assassin_psi_blades", true))
	{
		id = 5196;
	}
	if (!strcmp(AbilityName, "templar_assassin_psionic_trap", true))
	{
		id = 5197;
	}
	if (!strcmp(AbilityName, "templar_assassin_trap", true))
	{
		id = 5198;
	}
	if (!strcmp(AbilityName, "templar_assassin_self_trap", true))
	{
		id = 5199;
	}
	if (!strcmp(AbilityName, "viper_poison_attack", true))
	{
		id = 5218;
	}
	if (!strcmp(AbilityName, "viper_nethertoxin", true))
	{
		id = 5219;
	}
	if (!strcmp(AbilityName, "viper_corrosive_skin", true))
	{
		id = 5220;
	}
	if (!strcmp(AbilityName, "viper_viper_strike", true))
	{
		id = 5221;
	}
	if (!strcmp(AbilityName, "luna_lucent_beam", true))
	{
		id = 5222;
	}
	if (!strcmp(AbilityName, "luna_moon_glaive", true))
	{
		id = 5223;
	}
	if (!strcmp(AbilityName, "luna_lunar_blessing", true))
	{
		id = 5224;
	}
	if (!strcmp(AbilityName, "luna_eclipse", true))
	{
		id = 5225;
	}
	if (!strcmp(AbilityName, "dragon_knight_breathe_fire", true))
	{
		id = 5226;
	}
	if (!strcmp(AbilityName, "dragon_knight_dragon_tail", true))
	{
		id = 5227;
	}
	if (!strcmp(AbilityName, "dragon_knight_dragon_blood", true))
	{
		id = 5228;
	}
	if (!strcmp(AbilityName, "dragon_knight_elder_dragon_form", true))
	{
		id = 5229;
	}
	if (!strcmp(AbilityName, "dragon_knight_frost_breath", true))
	{
		id = 5232;
	}
	if (!strcmp(AbilityName, "dazzle_poison_touch", true))
	{
		id = 5233;
	}
	if (!strcmp(AbilityName, "dazzle_shallow_grave", true))
	{
		id = 5234;
	}
	if (!strcmp(AbilityName, "dazzle_shadow_wave", true))
	{
		id = 5235;
	}
	if (!strcmp(AbilityName, "dazzle_weave", true))
	{
		id = 5236;
	}
	if (!strcmp(AbilityName, "rattletrap_battery_assault", true))
	{
		id = 5237;
	}
	if (!strcmp(AbilityName, "rattletrap_power_cogs", true))
	{
		id = 5238;
	}
	if (!strcmp(AbilityName, "rattletrap_rocket_flare", true))
	{
		id = 5239;
	}
	if (!strcmp(AbilityName, "rattletrap_hookshot", true))
	{
		id = 5240;
	}
	if (!strcmp(AbilityName, "leshrac_split_earth", true))
	{
		id = 5241;
	}
	if (!strcmp(AbilityName, "leshrac_diabolic_edict", true))
	{
		id = 5242;
	}
	if (!strcmp(AbilityName, "leshrac_lightning_storm", true))
	{
		id = 5243;
	}
	if (!strcmp(AbilityName, "leshrac_pulse_nova", true))
	{
		id = 5244;
	}
	if (!strcmp(AbilityName, "furion_sprout", true))
	{
		id = 5245;
	}
	if (!strcmp(AbilityName, "furion_teleportation", true))
	{
		id = 5246;
	}
	if (!strcmp(AbilityName, "furion_force_of_nature", true))
	{
		id = 5247;
	}
	if (!strcmp(AbilityName, "furion_wrath_of_nature", true))
	{
		id = 5248;
	}
	if (!strcmp(AbilityName, "life_stealer_rage", true))
	{
		id = 5249;
	}
	if (!strcmp(AbilityName, "life_stealer_feast", true))
	{
		id = 5250;
	}
	if (!strcmp(AbilityName, "life_stealer_open_wounds", true))
	{
		id = 5251;
	}
	if (!strcmp(AbilityName, "life_stealer_infest", true))
	{
		id = 5252;
	}
	if (!strcmp(AbilityName, "life_stealer_consume", true))
	{
		id = 5253;
	}
	if (!strcmp(AbilityName, "life_stealer_control", true))
	{
		id = 5655;
	}
	if (!strcmp(AbilityName, "life_stealer_empty_1", true))
	{
		id = 5657;
	}
	if (!strcmp(AbilityName, "life_stealer_empty_2", true))
	{
		id = 5658;
	}
	if (!strcmp(AbilityName, "life_stealer_empty_3", true))
	{
		id = 5659;
	}
	if (!strcmp(AbilityName, "life_stealer_empty_4", true))
	{
		id = 5660;
	}
	if (!strcmp(AbilityName, "dark_seer_vacuum", true))
	{
		id = 5255;
	}
	if (!strcmp(AbilityName, "dark_seer_ion_shell", true))
	{
		id = 5256;
	}
	if (!strcmp(AbilityName, "dark_seer_surge", true))
	{
		id = 5257;
	}
	if (!strcmp(AbilityName, "dark_seer_wall_of_replica", true))
	{
		id = 5258;
	}
	if (!strcmp(AbilityName, "clinkz_strafe", true))
	{
		id = 5259;
	}
	if (!strcmp(AbilityName, "clinkz_searing_arrows", true))
	{
		id = 5260;
	}
	if (!strcmp(AbilityName, "clinkz_wind_walk", true))
	{
		id = 5261;
	}
	if (!strcmp(AbilityName, "clinkz_death_pact", true))
	{
		id = 5262;
	}
	if (!strcmp(AbilityName, "omniknight_purification", true))
	{
		id = 5263;
	}
	if (!strcmp(AbilityName, "omniknight_repel", true))
	{
		id = 5264;
	}
	if (!strcmp(AbilityName, "omniknight_degen_aura", true))
	{
		id = 5265;
	}
	if (!strcmp(AbilityName, "omniknight_guardian_angel", true))
	{
		id = 5266;
	}
	if (!strcmp(AbilityName, "enchantress_untouchable", true))
	{
		id = 5267;
	}
	if (!strcmp(AbilityName, "enchantress_enchant", true))
	{
		id = 5268;
	}
	if (!strcmp(AbilityName, "enchantress_natures_attendants", true))
	{
		id = 5269;
	}
	if (!strcmp(AbilityName, "enchantress_impetus", true))
	{
		id = 5270;
	}
	if (!strcmp(AbilityName, "huskar_inner_vitality", true))
	{
		id = 5271;
	}
	if (!strcmp(AbilityName, "huskar_burning_spear", true))
	{
		id = 5272;
	}
	if (!strcmp(AbilityName, "huskar_berserkers_blood", true))
	{
		id = 5273;
	}
	if (!strcmp(AbilityName, "huskar_life_break", true))
	{
		id = 5274;
	}
	if (!strcmp(AbilityName, "night_stalker_void", true))
	{
		id = 5275;
	}
	if (!strcmp(AbilityName, "night_stalker_crippling_fear", true))
	{
		id = 5276;
	}
	if (!strcmp(AbilityName, "night_stalker_hunter_in_the_night", true))
	{
		id = 5277;
	}
	if (!strcmp(AbilityName, "night_stalker_darkness", true))
	{
		id = 5278;
	}
	if (!strcmp(AbilityName, "broodmother_spawn_spiderlings", true))
	{
		id = 5279;
	}
	if (!strcmp(AbilityName, "broodmother_poison_sting", true))
	{
		id = 5284;
	}
	if (!strcmp(AbilityName, "broodmother_spawn_spiderite", true))
	{
		id = 5283;
	}
	if (!strcmp(AbilityName, "broodmother_spin_web", true))
	{
		id = 5280;
	}
	if (!strcmp(AbilityName, "broodmother_incapacitating_bite", true))
	{
		id = 5281;
	}
	if (!strcmp(AbilityName, "broodmother_insatiable_hunger", true))
	{
		id = 5282;
	}
	if (!strcmp(AbilityName, "bounty_hunter_shuriken_toss", true))
	{
		id = 5285;
	}
	if (!strcmp(AbilityName, "bounty_hunter_jinada", true))
	{
		id = 5286;
	}
	if (!strcmp(AbilityName, "bounty_hunter_wind_walk", true))
	{
		id = 5287;
	}
	if (!strcmp(AbilityName, "bounty_hunter_track", true))
	{
		id = 5288;
	}
	if (!strcmp(AbilityName, "weaver_the_swarm", true))
	{
		id = 5289;
	}
	if (!strcmp(AbilityName, "weaver_shukuchi", true))
	{
		id = 5290;
	}
	if (!strcmp(AbilityName, "weaver_geminate_attack", true))
	{
		id = 5291;
	}
	if (!strcmp(AbilityName, "weaver_time_lapse", true))
	{
		id = 5292;
	}
	if (!strcmp(AbilityName, "jakiro_dual_breath", true))
	{
		id = 5297;
	}
	if (!strcmp(AbilityName, "jakiro_ice_path", true))
	{
		id = 5298;
	}
	if (!strcmp(AbilityName, "jakiro_liquid_fire", true))
	{
		id = 5299;
	}
	if (!strcmp(AbilityName, "jakiro_macropyre", true))
	{
		id = 5300;
	}
	if (!strcmp(AbilityName, "batrider_sticky_napalm", true))
	{
		id = 5320;
	}
	if (!strcmp(AbilityName, "batrider_flamebreak", true))
	{
		id = 5321;
	}
	if (!strcmp(AbilityName, "batrider_firefly", true))
	{
		id = 5322;
	}
	if (!strcmp(AbilityName, "batrider_flaming_lasso", true))
	{
		id = 5323;
	}
	if (!strcmp(AbilityName, "chen_penitence", true))
	{
		id = 5328;
	}
	if (!strcmp(AbilityName, "chen_test_of_faith", true))
	{
		id = 5329;
	}
	if (!strcmp(AbilityName, "chen_test_of_faith_teleport", true))
	{
		id = 5522;
	}
	if (!strcmp(AbilityName, "chen_holy_persuasion", true))
	{
		id = 5330;
	}
	if (!strcmp(AbilityName, "chen_hand_of_god", true))
	{
		id = 5331;
	}
	if (!strcmp(AbilityName, "spectre_spectral_dagger", true))
	{
		id = 5334;
	}
	if (!strcmp(AbilityName, "spectre_desolate", true))
	{
		id = 5335;
	}
	if (!strcmp(AbilityName, "spectre_dispersion", true))
	{
		id = 5336;
	}
	if (!strcmp(AbilityName, "spectre_haunt", true))
	{
		id = 5337;
	}
	if (!strcmp(AbilityName, "spectre_reality", true))
	{
		id = 5338;
	}
	if (!strcmp(AbilityName, "doom_bringer_devour", true))
	{
		id = 5339;
	}
	if (!strcmp(AbilityName, "doom_bringer_scorched_earth", true))
	{
		id = 5340;
	}
	if (!strcmp(AbilityName, "doom_bringer_lvl_death", true))
	{
		id = 5341;
	}
	if (!strcmp(AbilityName, "doom_bringer_doom", true))
	{
		id = 5342;
	}
	if (!strcmp(AbilityName, "doom_bringer_empty1", true))
	{
		id = 5343;
	}
	if (!strcmp(AbilityName, "doom_bringer_empty2", true))
	{
		id = 5344;
	}
	if (!strcmp(AbilityName, "ancient_apparition_cold_feet", true))
	{
		id = 5345;
	}
	if (!strcmp(AbilityName, "ancient_apparition_ice_vortex", true))
	{
		id = 5346;
	}
	if (!strcmp(AbilityName, "ancient_apparition_chilling_touch", true))
	{
		id = 5347;
	}
	if (!strcmp(AbilityName, "ancient_apparition_ice_blast", true))
	{
		id = 5348;
	}
	if (!strcmp(AbilityName, "ancient_apparition_ice_blast_release", true))
	{
		id = 5349;
	}
	if (!strcmp(AbilityName, "spirit_breaker_charge_of_darkness", true))
	{
		id = 5353;
	}
	if (!strcmp(AbilityName, "spirit_breaker_empowering_haste", true))
	{
		id = 5354;
	}
	if (!strcmp(AbilityName, "spirit_breaker_greater_bash", true))
	{
		id = 5355;
	}
	if (!strcmp(AbilityName, "spirit_breaker_nether_strike", true))
	{
		id = 5356;
	}
	if (!strcmp(AbilityName, "ursa_earthshock", true))
	{
		id = 5357;
	}
	if (!strcmp(AbilityName, "ursa_overpower", true))
	{
		id = 5358;
	}
	if (!strcmp(AbilityName, "ursa_fury_swipes", true))
	{
		id = 5359;
	}
	if (!strcmp(AbilityName, "ursa_enrage", true))
	{
		id = 5360;
	}
	if (!strcmp(AbilityName, "gyrocopter_rocket_barrage", true))
	{
		id = 5361;
	}
	if (!strcmp(AbilityName, "gyrocopter_homing_missile", true))
	{
		id = 5362;
	}
	if (!strcmp(AbilityName, "gyrocopter_flak_cannon", true))
	{
		id = 5363;
	}
	if (!strcmp(AbilityName, "gyrocopter_call_down", true))
	{
		id = 5364;
	}
	if (!strcmp(AbilityName, "alchemist_acid_spray", true))
	{
		id = 5365;
	}
	if (!strcmp(AbilityName, "alchemist_unstable_concoction", true))
	{
		id = 5366;
	}
	if (!strcmp(AbilityName, "alchemist_unstable_concoction_throw", true))
	{
		id = 5367;
	}
	if (!strcmp(AbilityName, "alchemist_goblins_greed", true))
	{
		id = 5368;
	}
	if (!strcmp(AbilityName, "alchemist_chemical_rage", true))
	{
		id = 5369;
	}
	if (!strcmp(AbilityName, "invoker_quas", true))
	{
		id = 5370;
	}
	if (!strcmp(AbilityName, "invoker_wex", true))
	{
		id = 5371;
	}
	if (!strcmp(AbilityName, "invoker_exort", true))
	{
		id = 5372;
	}
	if (!strcmp(AbilityName, "invoker_empty1", true))
	{
		id = 5373;
	}
	if (!strcmp(AbilityName, "invoker_empty2", true))
	{
		id = 5374;
	}
	if (!strcmp(AbilityName, "invoker_invoke", true))
	{
		id = 5375;
	}
	if (!strcmp(AbilityName, "invoker_cold_snap", true))
	{
		id = 5376;
	}
	if (!strcmp(AbilityName, "invoker_ghost_walk", true))
	{
		id = 5381;
	}
	if (!strcmp(AbilityName, "invoker_tornado", true))
	{
		id = 5382;
	}
	if (!strcmp(AbilityName, "invoker_emp", true))
	{
		id = 5383;
	}
	if (!strcmp(AbilityName, "invoker_alacrity", true))
	{
		id = 5384;
	}
	if (!strcmp(AbilityName, "invoker_chaos_meteor", true))
	{
		id = 5385;
	}
	if (!strcmp(AbilityName, "invoker_sun_strike", true))
	{
		id = 5386;
	}
	if (!strcmp(AbilityName, "invoker_forge_spirit", true))
	{
		id = 5387;
	}
	if (!strcmp(AbilityName, "forged_spirit_melting_strike", true))
	{
		id = 5388;
	}
	if (!strcmp(AbilityName, "invoker_ice_wall", true))
	{
		id = 5389;
	}
	if (!strcmp(AbilityName, "invoker_deafening_blast", true))
	{
		id = 5390;
	}
	if (!strcmp(AbilityName, "silencer_curse_of_the_silent", true))
	{
		id = 5377;
	}
	if (!strcmp(AbilityName, "silencer_glaives_of_wisdom", true))
	{
		id = 5378;
	}
	if (!strcmp(AbilityName, "silencer_last_word", true))
	{
		id = 5379;
	}
	if (!strcmp(AbilityName, "silencer_global_silence", true))
	{
		id = 5380;
	}
	if (!strcmp(AbilityName, "obsidian_destroyer_arcane_orb", true))
	{
		id = 5391;
	}
	if (!strcmp(AbilityName, "obsidian_destroyer_astral_imprisonment", true))
	{
		id = 5392;
	}
	if (!strcmp(AbilityName, "obsidian_destroyer_essence_aura", true))
	{
		id = 5393;
	}
	if (!strcmp(AbilityName, "obsidian_destroyer_sanity_eclipse", true))
	{
		id = 5394;
	}
	if (!strcmp(AbilityName, "lycan_summon_wolves", true))
	{
		id = 5395;
	}
	if (!strcmp(AbilityName, "lycan_howl", true))
	{
		id = 5396;
	}
	if (!strcmp(AbilityName, "lycan_feral_impulse", true))
	{
		id = 5397;
	}
	if (!strcmp(AbilityName, "lycan_shapeshift", true))
	{
		id = 5398;
	}
	if (!strcmp(AbilityName, "lycan_summon_wolves_critical_strike", true))
	{
		id = 5399;
	}
	if (!strcmp(AbilityName, "lycan_summon_wolves_invisibility", true))
	{
		id = 5500;
	}
	if (!strcmp(AbilityName, "lone_druid_spirit_bear", true))
	{
		id = 5412;
	}
	if (!strcmp(AbilityName, "lone_druid_rabid", true))
	{
		id = 5413;
	}
	if (!strcmp(AbilityName, "lone_druid_synergy", true))
	{
		id = 5414;
	}
	if (!strcmp(AbilityName, "lone_druid_true_form", true))
	{
		id = 5415;
	}
	if (!strcmp(AbilityName, "lone_druid_true_form_druid", true))
	{
		id = 5416;
	}
	if (!strcmp(AbilityName, "lone_druid_true_form_battle_cry", true))
	{
		id = 5417;
	}
	if (!strcmp(AbilityName, "lone_druid_spirit_bear_return", true))
	{
		id = 5418;
	}
	if (!strcmp(AbilityName, "lone_druid_spirit_bear_entangle", true))
	{
		id = 5419;
	}
	if (!strcmp(AbilityName, "lone_druid_spirit_bear_demolish", true))
	{
		id = 5420;
	}
	if (!strcmp(AbilityName, "brewmaster_thunder_clap", true))
	{
		id = 5400;
	}
	if (!strcmp(AbilityName, "brewmaster_drunken_haze", true))
	{
		id = 5401;
	}
	if (!strcmp(AbilityName, "brewmaster_drunken_brawler", true))
	{
		id = 5402;
	}
	if (!strcmp(AbilityName, "brewmaster_primal_split", true))
	{
		id = 5403;
	}
	if (!strcmp(AbilityName, "brewmaster_earth_hurl_boulder", true))
	{
		id = 5404;
	}
	if (!strcmp(AbilityName, "brewmaster_earth_spell_immunity", true))
	{
		id = 5405;
	}
	if (!strcmp(AbilityName, "brewmaster_earth_pulverize", true))
	{
		id = 5406;
	}
	if (!strcmp(AbilityName, "brewmaster_storm_dispel_magic", true))
	{
		id = 5408;
	}
	if (!strcmp(AbilityName, "brewmaster_storm_cyclone", true))
	{
		id = 5409;
	}
	if (!strcmp(AbilityName, "brewmaster_storm_wind_walk", true))
	{
		id = 5410;
	}
	if (!strcmp(AbilityName, "brewmaster_fire_permanent_immolation", true))
	{
		id = 5411;
	}
	if (!strcmp(AbilityName, "shadow_demon_disruption", true))
	{
		id = 5421;
	}
	if (!strcmp(AbilityName, "shadow_demon_soul_catcher", true))
	{
		id = 5422;
	}
	if (!strcmp(AbilityName, "shadow_demon_shadow_poison", true))
	{
		id = 5423;
	}
	if (!strcmp(AbilityName, "shadow_demon_shadow_poison_release", true))
	{
		id = 5424;
	}
	if (!strcmp(AbilityName, "shadow_demon_demonic_purge", true))
	{
		id = 5425;
	}
	if (!strcmp(AbilityName, "chaos_knight_chaos_bolt", true))
	{
		id = 5426;
	}
	if (!strcmp(AbilityName, "chaos_knight_reality_rift", true))
	{
		id = 5427;
	}
	if (!strcmp(AbilityName, "chaos_knight_chaos_strike", true))
	{
		id = 5428;
	}
	if (!strcmp(AbilityName, "chaos_knight_phantasm", true))
	{
		id = 5429;
	}
	if (!strcmp(AbilityName, "meepo_earthbind", true))
	{
		id = 5430;
	}
	if (!strcmp(AbilityName, "meepo_poof", true))
	{
		id = 5431;
	}
	if (!strcmp(AbilityName, "meepo_geostrike", true))
	{
		id = 5432;
	}
	if (!strcmp(AbilityName, "meepo_divided_we_stand", true))
	{
		id = 5433;
	}
	if (!strcmp(AbilityName, "treant_natures_guise", true))
	{
		id = 5434;
	}
	if (!strcmp(AbilityName, "treant_living_armor", true))
	{
		id = 5436;
	}
	if (!strcmp(AbilityName, "treant_overgrowth", true))
	{
		id = 5437;
	}
	if (!strcmp(AbilityName, "treant_eyes_in_the_forest", true))
	{
		id = 5649;
	}
	if (!strcmp(AbilityName, "ogre_magi_fireblast", true))
	{
		id = 5438;
	}
	if (!strcmp(AbilityName, "ogre_magi_unrefined_fireblast", true))
	{
		id = 5466;
	}
	if (!strcmp(AbilityName, "ogre_magi_ignite", true))
	{
		id = 5439;
	}
	if (!strcmp(AbilityName, "ogre_magi_bloodlust", true))
	{
		id = 5440;
	}
	if (!strcmp(AbilityName, "ogre_magi_multicast", true))
	{
		id = 5441;
	}
	if (!strcmp(AbilityName, "undying_decay", true))
	{
		id = 5442;
	}
	if (!strcmp(AbilityName, "undying_soul_rip", true))
	{
		id = 5443;
	}
	if (!strcmp(AbilityName, "undying_tombstone", true))
	{
		id = 5444;
	}
	if (!strcmp(AbilityName, "undying_tombstone_zombie_aura", true))
	{
		id = 5445;
	}
	if (!strcmp(AbilityName, "undying_tombstone_zombie_deathstrike", true))
	{
		id = 5446;
	}
	if (!strcmp(AbilityName, "undying_flesh_golem", true))
	{
		id = 5447;
	}
	if (!strcmp(AbilityName, "rubick_telekinesis", true))
	{
		id = 5448;
	}
	if (!strcmp(AbilityName, "rubick_telekinesis_land", true))
	{
		id = 5449;
	}
	if (!strcmp(AbilityName, "rubick_fade_bolt", true))
	{
		id = 5450;
	}
	if (!strcmp(AbilityName, "rubick_null_field", true))
	{
		id = 5451;
	}
	if (!strcmp(AbilityName, "rubick_spell_steal", true))
	{
		id = 5452;
	}
	if (!strcmp(AbilityName, "rubick_empty1", true))
	{
		id = 5453;
	}
	if (!strcmp(AbilityName, "rubick_empty2", true))
	{
		id = 5454;
	}
	if (!strcmp(AbilityName, "rubick_hidden1", true))
	{
		id = 5455;
	}
	if (!strcmp(AbilityName, "rubick_hidden2", true))
	{
		id = 5456;
	}
	if (!strcmp(AbilityName, "rubick_hidden3", true))
	{
		id = 5457;
	}
	if (!strcmp(AbilityName, "disruptor_thunder_strike", true))
	{
		id = 5458;
	}
	if (!strcmp(AbilityName, "disruptor_glimpse", true))
	{
		id = 5459;
	}
	if (!strcmp(AbilityName, "disruptor_kinetic_field", true))
	{
		id = 5460;
	}
	if (!strcmp(AbilityName, "disruptor_static_storm", true))
	{
		id = 5461;
	}
	if (!strcmp(AbilityName, "nyx_assassin_impale", true))
	{
		id = 5462;
	}
	if (!strcmp(AbilityName, "nyx_assassin_mana_burn", true))
	{
		id = 5463;
	}
	if (!strcmp(AbilityName, "nyx_assassin_spiked_carapace", true))
	{
		id = 5464;
	}
	if (!strcmp(AbilityName, "nyx_assassin_vendetta", true))
	{
		id = 5465;
	}
	if (!strcmp(AbilityName, "naga_siren_mirror_image", true))
	{
		id = 5467;
	}
	if (!strcmp(AbilityName, "naga_siren_ensnare", true))
	{
		id = 5468;
	}
	if (!strcmp(AbilityName, "naga_siren_rip_tide", true))
	{
		id = 5469;
	}
	if (!strcmp(AbilityName, "naga_siren_song_of_the_siren", true))
	{
		id = 5470;
	}
	if (!strcmp(AbilityName, "naga_siren_song_of_the_siren_cancel", true))
	{
		id = 5478;
	}
	if (!strcmp(AbilityName, "keeper_of_the_light_illuminate", true))
	{
		id = 5471;
	}
	if (!strcmp(AbilityName, "keeper_of_the_light_mana_leak", true))
	{
		id = 5472;
	}
	if (!strcmp(AbilityName, "keeper_of_the_light_chakra_magic", true))
	{
		id = 5473;
	}
	if (!strcmp(AbilityName, "keeper_of_the_light_empty1", true))
	{
		id = 5501;
	}
	if (!strcmp(AbilityName, "keeper_of_the_light_empty2", true))
	{
		id = 5502;
	}
	if (!strcmp(AbilityName, "keeper_of_the_light_spirit_form", true))
	{
		id = 5474;
	}
	if (!strcmp(AbilityName, "keeper_of_the_light_recall", true))
	{
		id = 5475;
	}
	if (!strcmp(AbilityName, "keeper_of_the_light_blinding_light", true))
	{
		id = 5476;
	}
	if (!strcmp(AbilityName, "keeper_of_the_light_illuminate_end", true))
	{
		id = 5477;
	}
	if (!strcmp(AbilityName, "keeper_of_the_light_spirit_form_illuminate", true))
	{
		id = 5479;
	}
	if (!strcmp(AbilityName, "keeper_of_the_light_spirit_form_illuminate_end", true))
	{
		id = 5503;
	}
	if (!strcmp(AbilityName, "visage_grave_chill", true))
	{
		id = 5480;
	}
	if (!strcmp(AbilityName, "visage_soul_assumption", true))
	{
		id = 5481;
	}
	if (!strcmp(AbilityName, "visage_gravekeepers_cloak", true))
	{
		id = 5482;
	}
	if (!strcmp(AbilityName, "visage_summon_familiars", true))
	{
		id = 5483;
	}
	if (!strcmp(AbilityName, "visage_summon_familiars_stone_form", true))
	{
		id = 5484;
	}
	if (!strcmp(AbilityName, "wisp_tether", true))
	{
		id = 5485;
	}
	if (!strcmp(AbilityName, "wisp_spirits", true))
	{
		id = 5486;
	}
	if (!strcmp(AbilityName, "wisp_overcharge", true))
	{
		id = 5487;
	}
	if (!strcmp(AbilityName, "wisp_relocate", true))
	{
		id = 5488;
	}
	if (!strcmp(AbilityName, "wisp_tether_break", true))
	{
		id = 5489;
	}
	if (!strcmp(AbilityName, "wisp_spirits_in", true))
	{
		id = 5490;
	}
	if (!strcmp(AbilityName, "wisp_spirits_out", true))
	{
		id = 5493;
	}
	if (!strcmp(AbilityName, "wisp_empty1", true))
	{
		id = 5498;
	}
	if (!strcmp(AbilityName, "wisp_empty2", true))
	{
		id = 5499;
	}
	if (!strcmp(AbilityName, "slark_dark_pact", true))
	{
		id = 5494;
	}
	if (!strcmp(AbilityName, "slark_pounce", true))
	{
		id = 5495;
	}
	if (!strcmp(AbilityName, "slark_essence_shift", true))
	{
		id = 5496;
	}
	if (!strcmp(AbilityName, "slark_shadow_dance", true))
	{
		id = 5497;
	}
	if (!strcmp(AbilityName, "medusa_split_shot", true))
	{
		id = 5504;
	}
	if (!strcmp(AbilityName, "medusa_mystic_snake", true))
	{
		id = 5505;
	}
	if (!strcmp(AbilityName, "medusa_mana_shield", true))
	{
		id = 5506;
	}
	if (!strcmp(AbilityName, "medusa_stone_gaze", true))
	{
		id = 5507;
	}
	if (!strcmp(AbilityName, "troll_warlord_berserkers_rage", true))
	{
		id = 5508;
	}
	if (!strcmp(AbilityName, "troll_warlord_whirling_axes_ranged", true))
	{
		id = 5509;
	}
	if (!strcmp(AbilityName, "troll_warlord_whirling_axes_melee", true))
	{
		id = 5510;
	}
	if (!strcmp(AbilityName, "troll_warlord_fervor", true))
	{
		id = 5511;
	}
	if (!strcmp(AbilityName, "troll_warlord_battle_trance", true))
	{
		id = 5512;
	}
	if (!strcmp(AbilityName, "centaur_hoof_stomp", true))
	{
		id = 5514;
	}
	if (!strcmp(AbilityName, "centaur_double_edge", true))
	{
		id = 5515;
	}
	if (!strcmp(AbilityName, "centaur_return", true))
	{
		id = 5516;
	}
	if (!strcmp(AbilityName, "centaur_stampede", true))
	{
		id = 5517;
	}
	if (!strcmp(AbilityName, "magnataur_shockwave", true))
	{
		id = 5518;
	}
	if (!strcmp(AbilityName, "magnataur_empower", true))
	{
		id = 5519;
	}
	if (!strcmp(AbilityName, "magnataur_skewer", true))
	{
		id = 5520;
	}
	if (!strcmp(AbilityName, "magnataur_reverse_polarity", true))
	{
		id = 5521;
	}
	if (!strcmp(AbilityName, "shredder_whirling_death", true))
	{
		id = 5524;
	}
	if (!strcmp(AbilityName, "shredder_timber_chain", true))
	{
		id = 5525;
	}
	if (!strcmp(AbilityName, "shredder_reactive_armor", true))
	{
		id = 5526;
	}
	if (!strcmp(AbilityName, "shredder_chakram", true))
	{
		id = 5527;
	}
	if (!strcmp(AbilityName, "shredder_chakram_2", true))
	{
		id = 5645;
	}
	if (!strcmp(AbilityName, "shredder_return_chakram", true))
	{
		id = 5528;
	}
	if (!strcmp(AbilityName, "shredder_return_chakram_2", true))
	{
		id = 5646;
	}
	if (!strcmp(AbilityName, "bristleback_viscous_nasal_goo", true))
	{
		id = 5548;
	}
	if (!strcmp(AbilityName, "bristleback_quill_spray", true))
	{
		id = 5549;
	}
	if (!strcmp(AbilityName, "bristleback_bristleback", true))
	{
		id = 5550;
	}
	if (!strcmp(AbilityName, "bristleback_warpath", true))
	{
		id = 5551;
	}
	if (!strcmp(AbilityName, "tusk_ice_shards", true))
	{
		id = 5565;
	}
	if (!strcmp(AbilityName, "tusk_snowball", true))
	{
		id = 5566;
	}
	if (!strcmp(AbilityName, "tusk_launch_snowball", true))
	{
		id = 5641;
	}
	if (!strcmp(AbilityName, "tusk_frozen_sigil", true))
	{
		id = 5567;
	}
	if (!strcmp(AbilityName, "tusk_walrus_punch", true))
	{
		id = 5568;
	}
	if (!strcmp(AbilityName, "skywrath_mage_arcane_bolt", true))
	{
		id = 5581;
	}
	if (!strcmp(AbilityName, "skywrath_mage_concussive_shot", true))
	{
		id = 5582;
	}
	if (!strcmp(AbilityName, "skywrath_mage_ancient_seal", true))
	{
		id = 5583;
	}
	if (!strcmp(AbilityName, "skywrath_mage_mystic_flare", true))
	{
		id = 5584;
	}
	if (!strcmp(AbilityName, "abaddon_death_coil", true))
	{
		id = 5585;
	}
	if (!strcmp(AbilityName, "abaddon_aphotic_shield", true))
	{
		id = 5586;
	}
	if (!strcmp(AbilityName, "abaddon_frostmourne", true))
	{
		id = 5587;
	}
	if (!strcmp(AbilityName, "abaddon_borrowed_time", true))
	{
		id = 5588;
	}
	if (!strcmp(AbilityName, "elder_titan_echo_stomp", true))
	{
		id = 5589;
	}
	if (!strcmp(AbilityName, "elder_titan_echo_stomp_spirit", true))
	{
		id = 5590;
	}
	if (!strcmp(AbilityName, "elder_titan_ancestral_spirit", true))
	{
		id = 5591;
	}
	if (!strcmp(AbilityName, "elder_titan_return_spirit", true))
	{
		id = 5592;
	}
	if (!strcmp(AbilityName, "elder_titan_natural_order", true))
	{
		id = 5593;
	}
	if (!strcmp(AbilityName, "elder_titan_earth_splitter", true))
	{
		id = 5594;
	}
	if (!strcmp(AbilityName, "legion_commander_overwhelming_odds", true))
	{
		id = 5595;
	}
	if (!strcmp(AbilityName, "legion_commander_press_the_attack", true))
	{
		id = 5596;
	}
	if (!strcmp(AbilityName, "legion_commander_moment_of_courage", true))
	{
		id = 5597;
	}
	if (!strcmp(AbilityName, "legion_commander_duel", true))
	{
		id = 5598;
	}
	if (!strcmp(AbilityName, "ember_spirit_searing_chains", true))
	{
		id = 5603;
	}
	if (!strcmp(AbilityName, "ember_spirit_sleight_of_fist", true))
	{
		id = 5604;
	}
	if (!strcmp(AbilityName, "ember_spirit_flame_guard", true))
	{
		id = 5605;
	}
	if (!strcmp(AbilityName, "ember_spirit_fire_remnant", true))
	{
		id = 5606;
	}
	if (!strcmp(AbilityName, "ember_spirit_activate_fire_remnant", true))
	{
		id = 5607;
	}
	if (!strcmp(AbilityName, "earth_spirit_boulder_smash", true))
	{
		id = 5608;
	}
	if (!strcmp(AbilityName, "earth_spirit_rolling_boulder", true))
	{
		id = 5609;
	}
	if (!strcmp(AbilityName, "earth_spirit_geomagnetic_grip", true))
	{
		id = 5610;
	}
	if (!strcmp(AbilityName, "earth_spirit_stone_caller", true))
	{
		id = 5611;
	}
	if (!strcmp(AbilityName, "earth_spirit_petrify", true))
	{
		id = 5648;
	}
	if (!strcmp(AbilityName, "earth_spirit_magnetize", true))
	{
		id = 5612;
	}
	if (!strcmp(AbilityName, "abyssal_underlord_firestorm", true))
	{
		id = 5613;
	}
	if (!strcmp(AbilityName, "abyssal_underlord_pit_of_malice", true))
	{
		id = 5614;
	}
	if (!strcmp(AbilityName, "abyssal_underlord_atrophy_aura", true))
	{
		id = 5615;
	}
	if (!strcmp(AbilityName, "abyssal_underlord_dark_rift", true))
	{
		id = 5616;
	}
	if (!strcmp(AbilityName, "abyssal_underlord_cancel_dark_rift", true))
	{
		id = 5617;
	}
	if (!strcmp(AbilityName, "terrorblade_reflection", true))
	{
		id = 5619;
	}
	if (!strcmp(AbilityName, "terrorblade_conjure_image", true))
	{
		id = 5620;
	}
	if (!strcmp(AbilityName, "terrorblade_metamorphosis", true))
	{
		id = 5621;
	}
	if (!strcmp(AbilityName, "terrorblade_sunder", true))
	{
		id = 5622;
	}
	if (!strcmp(AbilityName, "phoenix_icarus_dive", true))
	{
		id = 5623;
	}
	if (!strcmp(AbilityName, "phoenix_icarus_dive_stop", true))
	{
		id = 5624;
	}
	if (!strcmp(AbilityName, "phoenix_fire_spirits", true))
	{
		id = 5625;
	}
	if (!strcmp(AbilityName, "phoenix_sun_ray", true))
	{
		id = 5626;
	}
	if (!strcmp(AbilityName, "phoenix_sun_ray_stop", true))
	{
		id = 5627;
	}
	if (!strcmp(AbilityName, "phoenix_sun_ray_toggle_move", true))
	{
		id = 5628;
	}
	if (!strcmp(AbilityName, "phoenix_sun_ray_toggle_move_empty", true))
	{
		id = 5629;
	}
	if (!strcmp(AbilityName, "phoenix_supernova", true))
	{
		id = 5630;
	}
	if (!strcmp(AbilityName, "phoenix_launch_fire_spirit", true))
	{
		id = 5631;
	}
	if (!strcmp(AbilityName, "oracle_fortunes_end", true))
	{
		id = 5637;
	}
	if (!strcmp(AbilityName, "oracle_fates_edict", true))
	{
		id = 5638;
	}
	if (!strcmp(AbilityName, "oracle_purifying_flames", true))
	{
		id = 5639;
	}
	if (!strcmp(AbilityName, "oracle_false_promise", true))
	{
		id = 5640;
	}
	if (!strcmp(AbilityName, "broodmother_spin_web_destroy", true))
	{
		id = 5643;
	}
	if (!strcmp(AbilityName, "backdoor_protection", true))
	{
		id = 5350;
	}
	if (!strcmp(AbilityName, "backdoor_protection_in_base", true))
	{
		id = 5351;
	}
	if (!strcmp(AbilityName, "necronomicon_warrior_last_will", true))
	{
		id = 5200;
	}
	if (!strcmp(AbilityName, "necronomicon_warrior_sight", true))
	{
		id = 5201;
	}
	if (!strcmp(AbilityName, "necronomicon_warrior_mana_burn", true))
	{
		id = 5202;
	}
	if (!strcmp(AbilityName, "necronomicon_archer_mana_burn", true))
	{
		id = 5203;
	}
	if (!strcmp(AbilityName, "necronomicon_archer_aoe", true))
	{
		id = 5204;
	}
	if (!strcmp(AbilityName, "courier_return_to_base", true))
	{
		id = 5205;
	}
	if (!strcmp(AbilityName, "courier_go_to_secretshop", true))
	{
		id = 5492;
	}
	if (!strcmp(AbilityName, "courier_transfer_items", true))
	{
		id = 5206;
	}
	if (!strcmp(AbilityName, "courier_return_stash_items", true))
	{
		id = 5207;
	}
	if (!strcmp(AbilityName, "courier_take_stash_items", true))
	{
		id = 5208;
	}
	if (!strcmp(AbilityName, "courier_shield", true))
	{
		id = 5209;
	}
	if (!strcmp(AbilityName, "courier_burst", true))
	{
		id = 5210;
	}
	if (!strcmp(AbilityName, "courier_morph", true))
	{
		id = 5642;
	}
	if (!strcmp(AbilityName, "roshan_spell_block", true))
	{
		id = 5213;
	}
	if (!strcmp(AbilityName, "roshan_halloween_spell_block", true))
	{
		id = 5618;
	}
	if (!strcmp(AbilityName, "roshan_bash", true))
	{
		id = 5214;
	}
	if (!strcmp(AbilityName, "roshan_slam", true))
	{
		id = 5215;
	}
	if (!strcmp(AbilityName, "roshan_inherent_buffs", true))
	{
		id = 5216;
	}
	if (!strcmp(AbilityName, "roshan_devotion", true))
	{
		id = 5217;
	}
	if (!strcmp(AbilityName, "kobold_taskmaster_speed_aura", true))
	{
		id = 5293;
	}
	if (!strcmp(AbilityName, "centaur_khan_endurance_aura", true))
	{
		id = 5294;
	}
	if (!strcmp(AbilityName, "centaur_khan_war_stomp", true))
	{
		id = 5295;
	}
	if (!strcmp(AbilityName, "gnoll_assassin_envenomed_weapon", true))
	{
		id = 5296;
	}
	if (!strcmp(AbilityName, "ghost_frost_attack", true))
	{
		id = 5301;
	}
	if (!strcmp(AbilityName, "polar_furbolg_ursa_warrior_thunder_clap", true))
	{
		id = 5302;
	}
	if (!strcmp(AbilityName, "neutral_spell_immunity", true))
	{
		id = 5303;
	}
	if (!strcmp(AbilityName, "ogre_magi_frost_armor", true))
	{
		id = 5304;
	}
	if (!strcmp(AbilityName, "dark_troll_warlord_ensnare", true))
	{
		id = 5305;
	}
	if (!strcmp(AbilityName, "dark_troll_warlord_raise_dead", true))
	{
		id = 5306;
	}
	if (!strcmp(AbilityName, "giant_wolf_critical_strike", true))
	{
		id = 5307;
	}
	if (!strcmp(AbilityName, "alpha_wolf_critical_strike", true))
	{
		id = 5308;
	}
	if (!strcmp(AbilityName, "alpha_wolf_command_aura", true))
	{
		id = 5309;
	}
	if (!strcmp(AbilityName, "tornado_tempest", true))
	{
		id = 5310;
	}
	if (!strcmp(AbilityName, "enraged_wildkin_tornado", true))
	{
		id = 5312;
	}
	if (!strcmp(AbilityName, "enraged_wildkin_toughness_aura", true))
	{
		id = 5313;
	}
	if (!strcmp(AbilityName, "granite_golem_hp_aura", true))
	{
		id = 5656;
	}
	if (!strcmp(AbilityName, "satyr_trickster_purge", true))
	{
		id = 5314;
	}
	if (!strcmp(AbilityName, "satyr_soulstealer_mana_burn", true))
	{
		id = 5315;
	}
	if (!strcmp(AbilityName, "satyr_hellcaller_shockwave", true))
	{
		id = 5316;
	}
	if (!strcmp(AbilityName, "satyr_hellcaller_unholy_aura", true))
	{
		id = 5317;
	}
	if (!strcmp(AbilityName, "forest_troll_high_priest_heal", true))
	{
		id = 5318;
	}
	if (!strcmp(AbilityName, "harpy_storm_chain_lightning", true))
	{
		id = 5319;
	}
	if (!strcmp(AbilityName, "black_dragon_splash_attack", true))
	{
		id = 5324;
	}
	if (!strcmp(AbilityName, "blue_dragonspawn_sorcerer_evasion", true))
	{
		id = 5325;
	}
	if (!strcmp(AbilityName, "blue_dragonspawn_overseer_evasion", true))
	{
		id = 5326;
	}
	if (!strcmp(AbilityName, "blue_dragonspawn_overseer_devotion_aura", true))
	{
		id = 5327;
	}
	if (!strcmp(AbilityName, "big_thunder_lizard_slam", true))
	{
		id = 5332;
	}
	if (!strcmp(AbilityName, "big_thunder_lizard_frenzy", true))
	{
		id = 5333;
	}
	if (!strcmp(AbilityName, "forest_troll_high_priest_mana_aura", true))
	{
		id = 5491;
	}
	if (!strcmp(AbilityName, "roshan_halloween_candy", true))
	{
		id = 9990;
	}
	if (!strcmp(AbilityName, "roshan_halloween_angry", true))
	{
		id = 9991;
	}
	if (!strcmp(AbilityName, "roshan_halloween_wave_of_force", true))
	{
		id = 9993;
	}
	if (!strcmp(AbilityName, "roshan_halloween_greater_bash", true))
	{
		id = 9994;
	}
	if (!strcmp(AbilityName, "roshan_halloween_toss", true))
	{
		id = 9995;
	}
	if (!strcmp(AbilityName, "roshan_halloween_shell", true))
	{
		id = 9997;
	}
	if (!strcmp(AbilityName, "roshan_halloween_apocalypse", true))
	{
		id = 9998;
	}
	if (!strcmp(AbilityName, "roshan_halloween_burn", true))
	{
		id = 9999;
	}
	if (!strcmp(AbilityName, "roshan_halloween_levels", true))
	{
		id = 10000;
	}
	if (!strcmp(AbilityName, "roshan_halloween_summon", true))
	{
		id = 10001;
	}
	if (!strcmp(AbilityName, "roshan_halloween_fireball", true))
	{
		id = 10002;
	}
	if (!strcmp(AbilityName, "greevil_magic_missile", true))
	{
		id = 5529;
	}
	if (!strcmp(AbilityName, "greevil_cold_snap", true))
	{
		id = 5530;
	}
	if (!strcmp(AbilityName, "greevil_decrepify", true))
	{
		id = 5531;
	}
	if (!strcmp(AbilityName, "greevil_diabolic_edict", true))
	{
		id = 5532;
	}
	if (!strcmp(AbilityName, "greevil_maledict", true))
	{
		id = 5533;
	}
	if (!strcmp(AbilityName, "greevil_shadow_strike", true))
	{
		id = 5534;
	}
	if (!strcmp(AbilityName, "greevil_laguna_blade", true))
	{
		id = 5535;
	}
	if (!strcmp(AbilityName, "greevil_poison_nova", true))
	{
		id = 5546;
	}
	if (!strcmp(AbilityName, "greevil_ice_wall", true))
	{
		id = 5547;
	}
	if (!strcmp(AbilityName, "greevil_fatal_bonds", true))
	{
		id = 5552;
	}
	if (!strcmp(AbilityName, "greevil_blade_fury", true))
	{
		id = 5553;
	}
	if (!strcmp(AbilityName, "greevil_phantom_strike", true))
	{
		id = 5554;
	}
	if (!strcmp(AbilityName, "greevil_time_lock", true))
	{
		id = 5555;
	}
	if (!strcmp(AbilityName, "greevil_shadow_wave", true))
	{
		id = 5556;
	}
	if (!strcmp(AbilityName, "greevil_echo_slam", true))
	{
		id = 5558;
	}
	if (!strcmp(AbilityName, "greevil_natures_attendants", true))
	{
		id = 5559;
	}
	if (!strcmp(AbilityName, "greevil_bloodlust", true))
	{
		id = 5560;
	}
	if (!strcmp(AbilityName, "greevil_purification", true))
	{
		id = 5561;
	}
	if (!strcmp(AbilityName, "greevil_flesh_golem", true))
	{
		id = 5562;
	}
	if (!strcmp(AbilityName, "greevil_hook", true))
	{
		id = 5563;
	}
	if (!strcmp(AbilityName, "greevil_rot", true))
	{
		id = 5564;
	}
	if (!strcmp(AbilityName, "greevil_black_hole", true))
	{
		id = 5569;
	}
	if (!strcmp(AbilityName, "greevil_miniboss_black_nightmare", true))
	{
		id = 5536;
	}
	if (!strcmp(AbilityName, "greevil_miniboss_black_brain_sap", true))
	{
		id = 5537;
	}
	if (!strcmp(AbilityName, "greevil_miniboss_blue_cold_feet", true))
	{
		id = 5538;
	}
	if (!strcmp(AbilityName, "greevil_miniboss_blue_ice_vortex", true))
	{
		id = 5539;
	}
	if (!strcmp(AbilityName, "greevil_miniboss_red_earthshock", true))
	{
		id = 5540;
	}
	if (!strcmp(AbilityName, "greevil_miniboss_red_overpower", true))
	{
		id = 5541;
	}
	if (!strcmp(AbilityName, "greevil_miniboss_yellow_ion_shell", true))
	{
		id = 5542;
	}
	if (!strcmp(AbilityName, "greevil_miniboss_yellow_surge", true))
	{
		id = 5543;
	}
	if (!strcmp(AbilityName, "greevil_miniboss_white_purification", true))
	{
		id = 5544;
	}
	if (!strcmp(AbilityName, "greevil_miniboss_white_degen_aura", true))
	{
		id = 5545;
	}
	if (!strcmp(AbilityName, "greevil_miniboss_green_living_armor", true))
	{
		id = 5570;
	}
	if (!strcmp(AbilityName, "greevil_miniboss_green_overgrowth", true))
	{
		id = 5571;
	}
	if (!strcmp(AbilityName, "greevil_miniboss_orange_dragon_slave", true))
	{
		id = 5572;
	}
	if (!strcmp(AbilityName, "greevil_miniboss_orange_light_strike_array", true))
	{
		id = 5573;
	}
	if (!strcmp(AbilityName, "greevil_miniboss_purple_venomous_gale", true))
	{
		id = 5574;
	}
	if (!strcmp(AbilityName, "greevil_miniboss_purple_plague_ward", true))
	{
		id = 5575;
	}
	if (!strcmp(AbilityName, "greevil_miniboss_sight", true))
	{
		id = 5576;
	}
	if (!strcmp(AbilityName, "throw_snowball", true))
	{
		id = 5577;
	}
	if (!strcmp(AbilityName, "throw_coal", true))
	{
		id = 5578;
	}
	if (!strcmp(AbilityName, "healing_campfire", true))
	{
		id = 5579;
	}
	if (!strcmp(AbilityName, "shoot_firework", true))
	{
		id = 5650;
	}
	if (!strcmp(AbilityName, "techies_land_mines", true))
	{
		id = 5599;
	}
	if (!strcmp(AbilityName, "techies_stasis_trap", true))
	{
		id = 5600;
	}
	if (!strcmp(AbilityName, "techies_suicide", true))
	{
		id = 5601;
	}
	if (!strcmp(AbilityName, "techies_remote_mines", true))
	{
		id = 5602;
	}
	if (!strcmp(AbilityName, "techies_focused_detonate", true))
	{
		id = 5635;
	}
	if (!strcmp(AbilityName, "techies_remote_mines_self_detonate", true))
	{
		id = 5636;
	}
	if (!strcmp(AbilityName, "techies_minefield_sign", true))
	{
		id = 5644;
	}
	if (!strcmp(AbilityName, "winter_wyvern_arctic_burn", true))
	{
		id = 5651;
	}
	if (!strcmp(AbilityName, "winter_wyvern_splinter_blast", true))
	{
		id = 5652;
	}
	if (!strcmp(AbilityName, "winter_wyvern_cold_embrace", true))
	{
		id = 5653;
	}
	if (!strcmp(AbilityName, "winter_wyvern_winters_curse", true))
	{
		id = 5654;
	}
	return id;
}

GetItemIdByName(String:ItemName[])
{
	new id;
	if (!strcmp(ItemName, "item_blink", true))
	{
		id = 1;
	}
	if (!strcmp(ItemName, "item_blades_of_attack", true))
	{
		id = 2;
	}
	if (!strcmp(ItemName, "item_broadsword", true))
	{
		id = 3;
	}
	if (!strcmp(ItemName, "item_chainmail", true))
	{
		id = 4;
	}
	if (!strcmp(ItemName, "item_claymore", true))
	{
		id = 5;
	}
	if (!strcmp(ItemName, "item_helm_of_iron_will", true))
	{
		id = 6;
	}
	if (!strcmp(ItemName, "item_javelin", true))
	{
		id = 7;
	}
	if (!strcmp(ItemName, "item_mithril_hammer", true))
	{
		id = 8;
	}
	if (!strcmp(ItemName, "item_platemail", true))
	{
		id = 9;
	}
	if (!strcmp(ItemName, "item_quarterstaff", true))
	{
		id = 10;
	}
	if (!strcmp(ItemName, "item_quelling_blade", true))
	{
		id = 11;
	}
	if (!strcmp(ItemName, "item_ring_of_protection", true))
	{
		id = 12;
	}
	if (!strcmp(ItemName, "item_stout_shield", true))
	{
		id = 182;
	}
	if (!strcmp(ItemName, "item_gauntlets", true))
	{
		id = 13;
	}
	if (!strcmp(ItemName, "item_slippers", true))
	{
		id = 14;
	}
	if (!strcmp(ItemName, "item_mantle", true))
	{
		id = 15;
	}
	if (!strcmp(ItemName, "item_branches", true))
	{
		id = 16;
	}
	if (!strcmp(ItemName, "item_belt_of_strength", true))
	{
		id = 17;
	}
	if (!strcmp(ItemName, "item_boots_of_elves", true))
	{
		id = 18;
	}
	if (!strcmp(ItemName, "item_robe", true))
	{
		id = 19;
	}
	if (!strcmp(ItemName, "item_circlet", true))
	{
		id = 20;
	}
	if (!strcmp(ItemName, "item_ogre_axe", true))
	{
		id = 21;
	}
	if (!strcmp(ItemName, "item_blade_of_alacrity", true))
	{
		id = 22;
	}
	if (!strcmp(ItemName, "item_staff_of_wizardry", true))
	{
		id = 23;
	}
	if (!strcmp(ItemName, "item_ultimate_orb", true))
	{
		id = 24;
	}
	if (!strcmp(ItemName, "item_gloves", true))
	{
		id = 25;
	}
	if (!strcmp(ItemName, "item_lifesteal", true))
	{
		id = 26;
	}
	if (!strcmp(ItemName, "item_ring_of_regen", true))
	{
		id = 27;
	}
	if (!strcmp(ItemName, "item_sobi_mask", true))
	{
		id = 28;
	}
	if (!strcmp(ItemName, "item_boots", true))
	{
		id = 29;
	}
	if (!strcmp(ItemName, "item_gem", true))
	{
		id = 30;
	}
	if (!strcmp(ItemName, "item_cloak", true))
	{
		id = 31;
	}
	if (!strcmp(ItemName, "item_talisman_of_evasion", true))
	{
		id = 32;
	}
	if (!strcmp(ItemName, "item_cheese", true))
	{
		id = 33;
	}
	if (!strcmp(ItemName, "item_magic_stick", true))
	{
		id = 34;
	}
	if (!strcmp(ItemName, "item_recipe_magic_wand", true))
	{
		id = 35;
	}
	if (!strcmp(ItemName, "item_magic_wand", true))
	{
		id = 36;
	}
	if (!strcmp(ItemName, "item_ghost", true))
	{
		id = 37;
	}
	if (!strcmp(ItemName, "item_clarity", true))
	{
		id = 38;
	}
	if (!strcmp(ItemName, "item_flask", true))
	{
		id = 39;
	}
	if (!strcmp(ItemName, "item_dust", true))
	{
		id = 40;
	}
	if (!strcmp(ItemName, "item_bottle", true))
	{
		id = 41;
	}
	if (!strcmp(ItemName, "item_ward_observer", true))
	{
		id = 42;
	}
	if (!strcmp(ItemName, "item_ward_sentry", true))
	{
		id = 43;
	}
	if (!strcmp(ItemName, "item_tango", true))
	{
		id = 44;
	}
	if (!strcmp(ItemName, "item_tango_single", true))
	{
		id = 241;
	}
	if (!strcmp(ItemName, "item_courier", true))
	{
		id = 45;
	}
	if (!strcmp(ItemName, "item_tpscroll", true))
	{
		id = 46;
	}
	if (!strcmp(ItemName, "item_recipe_travel_boots", true))
	{
		id = 47;
	}
	if (!strcmp(ItemName, "item_travel_boots", true))
	{
		id = 48;
	}
	if (!strcmp(ItemName, "item_recipe_phase_boots", true))
	{
		id = 49;
	}
	if (!strcmp(ItemName, "item_phase_boots", true))
	{
		id = 50;
	}
	if (!strcmp(ItemName, "item_demon_edge", true))
	{
		id = 51;
	}
	if (!strcmp(ItemName, "item_eagle", true))
	{
		id = 52;
	}
	if (!strcmp(ItemName, "item_reaver", true))
	{
		id = 53;
	}
	if (!strcmp(ItemName, "item_relic", true))
	{
		id = 54;
	}
	if (!strcmp(ItemName, "item_hyperstone", true))
	{
		id = 55;
	}
	if (!strcmp(ItemName, "item_ring_of_health", true))
	{
		id = 56;
	}
	if (!strcmp(ItemName, "item_void_stone", true))
	{
		id = 57;
	}
	if (!strcmp(ItemName, "item_mystic_staff", true))
	{
		id = 58;
	}
	if (!strcmp(ItemName, "item_energy_booster", true))
	{
		id = 59;
	}
	if (!strcmp(ItemName, "item_point_booster", true))
	{
		id = 60;
	}
	if (!strcmp(ItemName, "item_vitality_booster", true))
	{
		id = 61;
	}
	if (!strcmp(ItemName, "item_recipe_power_treads", true))
	{
		id = 62;
	}
	if (!strcmp(ItemName, "item_power_treads", true))
	{
		id = 63;
	}
	if (!strcmp(ItemName, "item_recipe_hand_of_midas", true))
	{
		id = 64;
	}
	if (!strcmp(ItemName, "item_hand_of_midas", true))
	{
		id = 65;
	}
	if (!strcmp(ItemName, "item_recipe_oblivion_staff", true))
	{
		id = 66;
	}
	if (!strcmp(ItemName, "item_oblivion_staff", true))
	{
		id = 67;
	}
	if (!strcmp(ItemName, "item_recipe_pers", true))
	{
		id = 68;
	}
	if (!strcmp(ItemName, "item_pers", true))
	{
		id = 69;
	}
	if (!strcmp(ItemName, "item_recipe_poor_mans_shield", true))
	{
		id = 70;
	}
	if (!strcmp(ItemName, "item_poor_mans_shield", true))
	{
		id = 71;
	}
	if (!strcmp(ItemName, "item_recipe_bracer", true))
	{
		id = 72;
	}
	if (!strcmp(ItemName, "item_bracer", true))
	{
		id = 73;
	}
	if (!strcmp(ItemName, "item_recipe_wraith_band", true))
	{
		id = 74;
	}
	if (!strcmp(ItemName, "item_wraith_band", true))
	{
		id = 75;
	}
	if (!strcmp(ItemName, "item_recipe_null_talisman", true))
	{
		id = 76;
	}
	if (!strcmp(ItemName, "item_null_talisman", true))
	{
		id = 77;
	}
	if (!strcmp(ItemName, "item_recipe_mekansm", true))
	{
		id = 78;
	}
	if (!strcmp(ItemName, "item_mekansm", true))
	{
		id = 79;
	}
	if (!strcmp(ItemName, "item_recipe_vladmir", true))
	{
		id = 80;
	}
	if (!strcmp(ItemName, "item_vladmir", true))
	{
		id = 81;
	}
	if (!strcmp(ItemName, "item_flying_courier", true))
	{
		id = 84;
	}
	if (!strcmp(ItemName, "item_recipe_buckler", true))
	{
		id = 85;
	}
	if (!strcmp(ItemName, "item_buckler", true))
	{
		id = 86;
	}
	if (!strcmp(ItemName, "item_recipe_ring_of_basilius", true))
	{
		id = 87;
	}
	if (!strcmp(ItemName, "item_ring_of_basilius", true))
	{
		id = 88;
	}
	if (!strcmp(ItemName, "item_recipe_pipe", true))
	{
		id = 89;
	}
	if (!strcmp(ItemName, "item_pipe", true))
	{
		id = 90;
	}
	if (!strcmp(ItemName, "item_recipe_urn_of_shadows", true))
	{
		id = 91;
	}
	if (!strcmp(ItemName, "item_urn_of_shadows", true))
	{
		id = 92;
	}
	if (!strcmp(ItemName, "item_recipe_headdress", true))
	{
		id = 93;
	}
	if (!strcmp(ItemName, "item_headdress", true))
	{
		id = 94;
	}
	if (!strcmp(ItemName, "item_recipe_sheepstick", true))
	{
		id = 95;
	}
	if (!strcmp(ItemName, "item_sheepstick", true))
	{
		id = 96;
	}
	if (!strcmp(ItemName, "item_recipe_orchid", true))
	{
		id = 97;
	}
	if (!strcmp(ItemName, "item_orchid", true))
	{
		id = 98;
	}
	if (!strcmp(ItemName, "item_recipe_cyclone", true))
	{
		id = 99;
	}
	if (!strcmp(ItemName, "item_cyclone", true))
	{
		id = 100;
	}
	if (!strcmp(ItemName, "item_recipe_force_staff", true))
	{
		id = 101;
	}
	if (!strcmp(ItemName, "item_force_staff", true))
	{
		id = 102;
	}
	if (!strcmp(ItemName, "item_recipe_dagon", true))
	{
		id = 103;
	}
	if (!strcmp(ItemName, "item_recipe_dagon_2", true))
	{
		id = 197;
	}
	if (!strcmp(ItemName, "item_recipe_dagon_3", true))
	{
		id = 198;
	}
	if (!strcmp(ItemName, "item_recipe_dagon_4", true))
	{
		id = 199;
	}
	if (!strcmp(ItemName, "item_recipe_dagon_5", true))
	{
		id = 200;
	}
	if (!strcmp(ItemName, "item_dagon", true))
	{
		id = 104;
	}
	if (!strcmp(ItemName, "item_dagon_2", true))
	{
		id = 201;
	}
	if (!strcmp(ItemName, "item_dagon_3", true))
	{
		id = 202;
	}
	if (!strcmp(ItemName, "item_dagon_4", true))
	{
		id = 203;
	}
	if (!strcmp(ItemName, "item_dagon_5", true))
	{
		id = 204;
	}
	if (!strcmp(ItemName, "item_recipe_necronomicon", true))
	{
		id = 105;
	}
	if (!strcmp(ItemName, "item_recipe_necronomicon_2", true))
	{
		id = 191;
	}
	if (!strcmp(ItemName, "item_recipe_necronomicon_3", true))
	{
		id = 192;
	}
	if (!strcmp(ItemName, "item_necronomicon", true))
	{
		id = 106;
	}
	if (!strcmp(ItemName, "item_necronomicon_2", true))
	{
		id = 193;
	}
	if (!strcmp(ItemName, "item_necronomicon_3", true))
	{
		id = 194;
	}
	if (!strcmp(ItemName, "item_recipe_ultimate_scepter", true))
	{
		id = 107;
	}
	if (!strcmp(ItemName, "item_ultimate_scepter", true))
	{
		id = 108;
	}
	if (!strcmp(ItemName, "item_recipe_refresher", true))
	{
		id = 109;
	}
	if (!strcmp(ItemName, "item_refresher", true))
	{
		id = 110;
	}
	if (!strcmp(ItemName, "item_recipe_assault", true))
	{
		id = 111;
	}
	if (!strcmp(ItemName, "item_assault", true))
	{
		id = 112;
	}
	if (!strcmp(ItemName, "item_recipe_heart", true))
	{
		id = 113;
	}
	if (!strcmp(ItemName, "item_heart", true))
	{
		id = 114;
	}
	if (!strcmp(ItemName, "item_recipe_black_king_bar", true))
	{
		id = 115;
	}
	if (!strcmp(ItemName, "item_black_king_bar", true))
	{
		id = 116;
	}
	if (!strcmp(ItemName, "item_aegis", true))
	{
		id = 117;
	}
	if (!strcmp(ItemName, "item_recipe_shivas_guard", true))
	{
		id = 118;
	}
	if (!strcmp(ItemName, "item_shivas_guard", true))
	{
		id = 119;
	}
	if (!strcmp(ItemName, "item_recipe_bloodstone", true))
	{
		id = 120;
	}
	if (!strcmp(ItemName, "item_bloodstone", true))
	{
		id = 121;
	}
	if (!strcmp(ItemName, "item_recipe_sphere", true))
	{
		id = 122;
	}
	if (!strcmp(ItemName, "item_sphere", true))
	{
		id = 123;
	}
	if (!strcmp(ItemName, "item_recipe_vanguard", true))
	{
		id = 124;
	}
	if (!strcmp(ItemName, "item_vanguard", true))
	{
		id = 125;
	}
	if (!strcmp(ItemName, "item_recipe_crimson_guard", true))
	{
		id = 243;
	}
	if (!strcmp(ItemName, "item_crimson_guard", true))
	{
		id = 242;
	}
	if (!strcmp(ItemName, "item_recipe_blade_mail", true))
	{
		id = 126;
	}
	if (!strcmp(ItemName, "item_blade_mail", true))
	{
		id = 127;
	}
	if (!strcmp(ItemName, "item_recipe_soul_booster", true))
	{
		id = 128;
	}
	if (!strcmp(ItemName, "item_soul_booster", true))
	{
		id = 129;
	}
	if (!strcmp(ItemName, "item_recipe_hood_of_defiance", true))
	{
		id = 130;
	}
	if (!strcmp(ItemName, "item_hood_of_defiance", true))
	{
		id = 131;
	}
	if (!strcmp(ItemName, "item_recipe_rapier", true))
	{
		id = 132;
	}
	if (!strcmp(ItemName, "item_rapier", true))
	{
		id = 133;
	}
	if (!strcmp(ItemName, "item_recipe_monkey_king_bar", true))
	{
		id = 134;
	}
	if (!strcmp(ItemName, "item_monkey_king_bar", true))
	{
		id = 135;
	}
	if (!strcmp(ItemName, "item_recipe_radiance", true))
	{
		id = 136;
	}
	if (!strcmp(ItemName, "item_radiance", true))
	{
		id = 137;
	}
	if (!strcmp(ItemName, "item_recipe_butterfly", true))
	{
		id = 138;
	}
	if (!strcmp(ItemName, "item_butterfly", true))
	{
		id = 139;
	}
	if (!strcmp(ItemName, "item_recipe_greater_crit", true))
	{
		id = 140;
	}
	if (!strcmp(ItemName, "item_greater_crit", true))
	{
		id = 141;
	}
	if (!strcmp(ItemName, "item_recipe_basher", true))
	{
		id = 142;
	}
	if (!strcmp(ItemName, "item_basher", true))
	{
		id = 143;
	}
	if (!strcmp(ItemName, "item_recipe_bfury", true))
	{
		id = 144;
	}
	if (!strcmp(ItemName, "item_bfury", true))
	{
		id = 145;
	}
	if (!strcmp(ItemName, "item_recipe_manta", true))
	{
		id = 146;
	}
	if (!strcmp(ItemName, "item_manta", true))
	{
		id = 147;
	}
	if (!strcmp(ItemName, "item_recipe_lesser_crit", true))
	{
		id = 148;
	}
	if (!strcmp(ItemName, "item_lesser_crit", true))
	{
		id = 149;
	}
	if (!strcmp(ItemName, "item_recipe_armlet", true))
	{
		id = 150;
	}
	if (!strcmp(ItemName, "item_armlet", true))
	{
		id = 151;
	}
	if (!strcmp(ItemName, "item_recipe_invis_sword", true))
	{
		id = 183;
	}
	if (!strcmp(ItemName, "item_invis_sword", true))
	{
		id = 152;
	}
	if (!strcmp(ItemName, "item_recipe_sange_and_yasha", true))
	{
		id = 153;
	}
	if (!strcmp(ItemName, "item_sange_and_yasha", true))
	{
		id = 154;
	}
	if (!strcmp(ItemName, "item_recipe_satanic", true))
	{
		id = 155;
	}
	if (!strcmp(ItemName, "item_satanic", true))
	{
		id = 156;
	}
	if (!strcmp(ItemName, "item_recipe_mjollnir", true))
	{
		id = 157;
	}
	if (!strcmp(ItemName, "item_mjollnir", true))
	{
		id = 158;
	}
	if (!strcmp(ItemName, "item_recipe_skadi", true))
	{
		id = 159;
	}
	if (!strcmp(ItemName, "item_skadi", true))
	{
		id = 160;
	}
	if (!strcmp(ItemName, "item_recipe_sange", true))
	{
		id = 161;
	}
	if (!strcmp(ItemName, "item_sange", true))
	{
		id = 162;
	}
	if (!strcmp(ItemName, "item_recipe_helm_of_the_dominator", true))
	{
		id = 163;
	}
	if (!strcmp(ItemName, "item_helm_of_the_dominator", true))
	{
		id = 164;
	}
	if (!strcmp(ItemName, "item_recipe_maelstrom", true))
	{
		id = 165;
	}
	if (!strcmp(ItemName, "item_maelstrom", true))
	{
		id = 166;
	}
	if (!strcmp(ItemName, "item_recipe_desolator", true))
	{
		id = 167;
	}
	if (!strcmp(ItemName, "item_desolator", true))
	{
		id = 168;
	}
	if (!strcmp(ItemName, "item_recipe_yasha", true))
	{
		id = 169;
	}
	if (!strcmp(ItemName, "item_yasha", true))
	{
		id = 170;
	}
	if (!strcmp(ItemName, "item_recipe_mask_of_madness", true))
	{
		id = 171;
	}
	if (!strcmp(ItemName, "item_mask_of_madness", true))
	{
		id = 172;
	}
	if (!strcmp(ItemName, "item_recipe_diffusal_blade", true))
	{
		id = 173;
	}
	if (!strcmp(ItemName, "item_recipe_diffusal_blade_2", true))
	{
		id = 195;
	}
	if (!strcmp(ItemName, "item_diffusal_blade", true))
	{
		id = 174;
	}
	if (!strcmp(ItemName, "item_diffusal_blade_2", true))
	{
		id = 196;
	}
	if (!strcmp(ItemName, "item_recipe_ethereal_blade", true))
	{
		id = 175;
	}
	if (!strcmp(ItemName, "item_ethereal_blade", true))
	{
		id = 176;
	}
	if (!strcmp(ItemName, "item_recipe_soul_ring", true))
	{
		id = 177;
	}
	if (!strcmp(ItemName, "item_soul_ring", true))
	{
		id = 178;
	}
	if (!strcmp(ItemName, "item_recipe_arcane_boots", true))
	{
		id = 179;
	}
	if (!strcmp(ItemName, "item_arcane_boots", true))
	{
		id = 180;
	}
	if (!strcmp(ItemName, "item_orb_of_venom", true))
	{
		id = 181;
	}
	if (!strcmp(ItemName, "item_recipe_ancient_janggo", true))
	{
		id = 184;
	}
	if (!strcmp(ItemName, "item_ancient_janggo", true))
	{
		id = 185;
	}
	if (!strcmp(ItemName, "item_recipe_medallion_of_courage", true))
	{
		id = 186;
	}
	if (!strcmp(ItemName, "item_medallion_of_courage", true))
	{
		id = 187;
	}
	if (!strcmp(ItemName, "item_smoke_of_deceit", true))
	{
		id = 188;
	}
	if (!strcmp(ItemName, "item_recipe_veil_of_discord", true))
	{
		id = 189;
	}
	if (!strcmp(ItemName, "item_veil_of_discord", true))
	{
		id = 190;
	}
	if (!strcmp(ItemName, "item_recipe_rod_of_atos", true))
	{
		id = 205;
	}
	if (!strcmp(ItemName, "item_rod_of_atos", true))
	{
		id = 206;
	}
	if (!strcmp(ItemName, "item_recipe_abyssal_blade", true))
	{
		id = 207;
	}
	if (!strcmp(ItemName, "item_abyssal_blade", true))
	{
		id = 208;
	}
	if (!strcmp(ItemName, "item_recipe_heavens_halberd", true))
	{
		id = 209;
	}
	if (!strcmp(ItemName, "item_heavens_halberd", true))
	{
		id = 210;
	}
	if (!strcmp(ItemName, "item_recipe_ring_of_aquila", true))
	{
		id = 211;
	}
	if (!strcmp(ItemName, "item_ring_of_aquila", true))
	{
		id = 212;
	}
	if (!strcmp(ItemName, "item_recipe_tranquil_boots", true))
	{
		id = 213;
	}
	if (!strcmp(ItemName, "item_tranquil_boots", true))
	{
		id = 214;
	}
	if (!strcmp(ItemName, "item_shadow_amulet", true))
	{
		id = 215;
	}
	if (!strcmp(ItemName, "item_halloween_candy_corn", true))
	{
		id = 216;
	}
	if (!strcmp(ItemName, "item_mystery_hook", true))
	{
		id = 217;
	}
	if (!strcmp(ItemName, "item_mystery_arrow", true))
	{
		id = 218;
	}
	if (!strcmp(ItemName, "item_mystery_missile", true))
	{
		id = 219;
	}
	if (!strcmp(ItemName, "item_mystery_toss", true))
	{
		id = 220;
	}
	if (!strcmp(ItemName, "item_mystery_vacuum", true))
	{
		id = 221;
	}
	if (!strcmp(ItemName, "item_halloween_rapier", true))
	{
		id = 226;
	}
	if (!strcmp(ItemName, "item_greevil_whistle", true))
	{
		id = 228;
	}
	if (!strcmp(ItemName, "item_greevil_whistle_toggle", true))
	{
		id = 235;
	}
	if (!strcmp(ItemName, "item_present", true))
	{
		id = 227;
	}
	if (!strcmp(ItemName, "item_winter_stocking", true))
	{
		id = 229;
	}
	if (!strcmp(ItemName, "item_winter_skates", true))
	{
		id = 230;
	}
	if (!strcmp(ItemName, "item_winter_cake", true))
	{
		id = 231;
	}
	if (!strcmp(ItemName, "item_winter_cookie", true))
	{
		id = 232;
	}
	if (!strcmp(ItemName, "item_winter_coco", true))
	{
		id = 233;
	}
	if (!strcmp(ItemName, "item_winter_ham", true))
	{
		id = 234;
	}
	if (!strcmp(ItemName, "item_winter_kringle", true))
	{
		id = 236;
	}
	if (!strcmp(ItemName, "item_winter_mushroom", true))
	{
		id = 237;
	}
	if (!strcmp(ItemName, "item_winter_greevil_treat", true))
	{
		id = 238;
	}
	if (!strcmp(ItemName, "item_winter_greevil_garbage", true))
	{
		id = 239;
	}
	if (!strcmp(ItemName, "item_winter_greevil_chewy", true))
	{
		id = 240;
	}
	if (!strcmp(ItemName, "item_tango_single", true))
	{
		id = 241;
	}
	if (!strcmp(ItemName, "item_crimson_guard", true))
	{
		id = 242;
	}
	if (!strcmp(ItemName, "item_recipe_crimson_guard", true))
	{
		id = 243;
	}
	return id;
}

public GetHeroIdByLogName(String:HeroName[])
{
	new id = -1;
	if (!strcmp(HeroName, "\nCOMBAT SUMMARY\n", true))
	{
		id = 0;
	}
	if (!strcmp(HeroName, "--- Anti-Mage ---\n", true))
	{
		id = 1;
	}
	if (!strcmp(HeroName, "--- Axe ---\n", true))
	{
		id = 2;
	}
	if (!strcmp(HeroName, "--- Bane ---\n", true))
	{
		id = 3;
	}
	if (!strcmp(HeroName, "--- Bloodseeker ---\n", true))
	{
		id = 4;
	}
	if (!strcmp(HeroName, "--- Crystal Maiden ---\n", true))
	{
		id = 5;
	}
	if (!strcmp(HeroName, "--- Drow Ranger ---\n", true))
	{
		id = 6;
	}
	if (!strcmp(HeroName, "--- Earthshaker ---\n", true))
	{
		id = 7;
	}
	if (!strcmp(HeroName, "--- Juggernaut ---\n", true))
	{
		id = 8;
	}
	if (!strcmp(HeroName, "--- Mirana ---\n", true))
	{
		id = 9;
	}
	if (!strcmp(HeroName, "--- Shadow Fiend ---\n", true))
	{
		id = 11;
	}
	if (!strcmp(HeroName, "--- Morphling ---\n", true))
	{
		id = 10;
	}
	if (!strcmp(HeroName, "--- Phantom Lancer ---\n", true))
	{
		id = 12;
	}
	if (!strcmp(HeroName, "--- Puck ---\n", true))
	{
		id = 13;
	}
	if (!strcmp(HeroName, "--- Pudge ---\n", true))
	{
		id = 14;
	}
	if (!strcmp(HeroName, "--- Razor ---\n", true))
	{
		id = 15;
	}
	if (!strcmp(HeroName, "--- Sand King ---\n", true))
	{
		id = 16;
	}
	if (!strcmp(HeroName, "--- Storm Spirit ---\n", true))
	{
		id = 17;
	}
	if (!strcmp(HeroName, "--- Sven ---\n", true))
	{
		id = 18;
	}
	if (!strcmp(HeroName, "--- Tiny ---\n", true))
	{
		id = 19;
	}
	if (!strcmp(HeroName, "--- Vengeful Spirit ---\n", true))
	{
		id = 20;
	}
	if (!strcmp(HeroName, "--- Windranger ---\n", true))
	{
		id = 21;
	}
	if (!strcmp(HeroName, "--- Zeus ---\n", true))
	{
		id = 22;
	}
	if (!strcmp(HeroName, "--- Kunkka ---\n", true))
	{
		id = 23;
	}
	if (!strcmp(HeroName, "--- Lina ---\n", true))
	{
		id = 25;
	}
	if (!strcmp(HeroName, "--- Lich ---\n", true))
	{
		id = 31;
	}
	if (!strcmp(HeroName, "--- Lion ---\n", true))
	{
		id = 26;
	}
	if (!strcmp(HeroName, "--- Shadow Shaman ---\n", true))
	{
		id = 27;
	}
	if (!strcmp(HeroName, "--- Slardar ---\n", true))
	{
		id = 28;
	}
	if (!strcmp(HeroName, "--- Tidehunter ---\n", true))
	{
		id = 29;
	}
	if (!strcmp(HeroName, "--- Witch Doctor ---\n", true))
	{
		id = 30;
	}
	if (!strcmp(HeroName, "--- Riki ---\n", true))
	{
		id = 32;
	}
	if (!strcmp(HeroName, "--- Enigma ---\n", true))
	{
		id = 33;
	}
	if (!strcmp(HeroName, "--- Tinker ---\n", true))
	{
		id = 34;
	}
	if (!strcmp(HeroName, "--- Sniper ---\n", true))
	{
		id = 35;
	}
	if (!strcmp(HeroName, "--- Necrophos ---\n", true))
	{
		id = 36;
	}
	if (!strcmp(HeroName, "--- Warlock ---\n", true))
	{
		id = 37;
	}
	if (!strcmp(HeroName, "--- Beastmaster ---\n", true))
	{
		id = 38;
	}
	if (!strcmp(HeroName, "--- Queen of Pain ---\n", true))
	{
		id = 39;
	}
	if (!strcmp(HeroName, "--- Venomancer ---\n", true))
	{
		id = 40;
	}
	if (!strcmp(HeroName, "--- Faceless Void ---\n", true))
	{
		id = 41;
	}
	if (!strcmp(HeroName, "--- Wraith King ---\n", true))
	{
		id = 42;
	}
	if (!strcmp(HeroName, "--- Death Prophet ---\n", true))
	{
		id = 43;
	}
	if (!strcmp(HeroName, "--- Phantom Assassin ---\n", true))
	{
		id = 44;
	}
	if (!strcmp(HeroName, "--- Pugna ---\n", true))
	{
		id = 45;
	}
	if (!strcmp(HeroName, "--- Templar Assassin ---\n", true))
	{
		id = 46;
	}
	if (!strcmp(HeroName, "--- Viper ---\n", true))
	{
		id = 47;
	}
	if (!strcmp(HeroName, "--- Luna ---\n", true))
	{
		id = 48;
	}
	if (!strcmp(HeroName, "--- Dragon Knight ---\n", true))
	{
		id = 49;
	}
	if (!strcmp(HeroName, "--- Dazzle ---\n", true))
	{
		id = 50;
	}
	if (!strcmp(HeroName, "--- Clockwerk ---\n", true))
	{
		id = 51;
	}
	if (!strcmp(HeroName, "--- Leshrac ---\n", true))
	{
		id = 52;
	}
	if (!strcmp(HeroName, "--- Nature's Prophet ---\n", true))
	{
		id = 53;
	}
	if (!strcmp(HeroName, "--- Lifestealer ---\n", true))
	{
		id = 54;
	}
	if (!strcmp(HeroName, "--- Dark Seer ---\n", true))
	{
		id = 55;
	}
	if (!strcmp(HeroName, "--- Clinkz ---\n", true))
	{
		id = 56;
	}
	if (!strcmp(HeroName, "--- Omniknight ---\n", true))
	{
		id = 57;
	}
	if (!strcmp(HeroName, "--- Enchantress ---\n", true))
	{
		id = 58;
	}
	if (!strcmp(HeroName, "--- Huskar ---\n", true))
	{
		id = 59;
	}
	if (!strcmp(HeroName, "--- Night Stalker ---\n", true))
	{
		id = 60;
	}
	if (!strcmp(HeroName, "--- Broodmother ---\n", true))
	{
		id = 61;
	}
	if (!strcmp(HeroName, "--- Bounty Hunter ---\n", true))
	{
		id = 62;
	}
	if (!strcmp(HeroName, "--- Weaver ---\n", true))
	{
		id = 63;
	}
	if (!strcmp(HeroName, "--- Jakiro ---\n", true))
	{
		id = 64;
	}
	if (!strcmp(HeroName, "--- Batrider ---\n", true))
	{
		id = 65;
	}
	if (!strcmp(HeroName, "--- Chen ---\n", true))
	{
		id = 66;
	}
	if (!strcmp(HeroName, "--- Spectre ---\n", true))
	{
		id = 67;
	}
	if (!strcmp(HeroName, "--- Doom ---\n", true))
	{
		id = 69;
	}
	if (!strcmp(HeroName, "--- Ancient Apparition ---\n", true))
	{
		id = 68;
	}
	if (!strcmp(HeroName, "--- Ursa ---\n", true))
	{
		id = 70;
	}
	if (!strcmp(HeroName, "--- Spirit Breaker ---\n", true))
	{
		id = 71;
	}
	if (!strcmp(HeroName, "--- Gyrocopter ---\n", true))
	{
		id = 72;
	}
	if (!strcmp(HeroName, "--- Alchemist ---\n", true))
	{
		id = 73;
	}
	if (!strcmp(HeroName, "--- Invoker ---\n", true))
	{
		id = 74;
	}
	if (!strcmp(HeroName, "--- Silencer ---\n", true))
	{
		id = 75;
	}
	if (!strcmp(HeroName, "--- Outworld Devourer ---\n", true))
	{
		id = 76;
	}
	if (!strcmp(HeroName, "--- Lycan ---\n", true))
	{
		id = 77;
	}
	if (!strcmp(HeroName, "--- Brewmaster ---\n", true))
	{
		id = 78;
	}
	if (!strcmp(HeroName, "--- Shadow Demon ---\n", true))
	{
		id = 79;
	}
	if (!strcmp(HeroName, "--- Lone Druid ---\n", true))
	{
		id = 80;
	}
	if (!strcmp(HeroName, "--- Chaos Knight ---\n", true))
	{
		id = 81;
	}
	if (!strcmp(HeroName, "--- Meepo ---\n", true))
	{
		id = 82;
	}
	if (!strcmp(HeroName, "--- Treant Protector ---\n", true))
	{
		id = 83;
	}
	if (!strcmp(HeroName, "--- Ogre Magi ---\n", true))
	{
		id = 84;
	}
	if (!strcmp(HeroName, "--- Undying ---\n", true))
	{
		id = 85;
	}
	if (!strcmp(HeroName, "--- Rubick ---\n", true))
	{
		id = 86;
	}
	if (!strcmp(HeroName, "--- Disruptor ---\n", true))
	{
		id = 87;
	}
	if (!strcmp(HeroName, "--- Nyx Assassin ---\n", true))
	{
		id = 88;
	}
	if (!strcmp(HeroName, "--- Naga Siren ---\n", true))
	{
		id = 89;
	}
	if (!strcmp(HeroName, "--- Keeper of the Light ---\n", true))
	{
		id = 90;
	}
	if (!strcmp(HeroName, "--- Io ---\n", true))
	{
		id = 91;
	}
	if (!strcmp(HeroName, "--- Visage ---\n", true))
	{
		id = 92;
	}
	if (!strcmp(HeroName, "--- Slark ---\n", true))
	{
		id = 93;
	}
	if (!strcmp(HeroName, "--- Medusa ---\n", true))
	{
		id = 94;
	}
	if (!strcmp(HeroName, "--- Troll Warlord ---\n", true))
	{
		id = 95;
	}
	if (!strcmp(HeroName, "--- Centaur Warrunner ---\n", true))
	{
		id = 96;
	}
	if (!strcmp(HeroName, "--- Magnus ---\n", true))
	{
		id = 97;
	}
	if (!strcmp(HeroName, "--- Timbersaw ---\n", true))
	{
		id = 98;
	}
	if (!strcmp(HeroName, "--- Bristleback ---\n", true))
	{
		id = 99;
	}
	if (!strcmp(HeroName, "--- Tusk ---\n", true))
	{
		id = 100;
	}
	if (!strcmp(HeroName, "--- Skywrath Mage ---\n", true))
	{
		id = 101;
	}
	if (!strcmp(HeroName, "--- Abaddon ---\n", true))
	{
		id = 102;
	}
	if (!strcmp(HeroName, "--- Elder Titan ---\n", true))
	{
		id = 103;
	}
	if (!strcmp(HeroName, "--- Legion Commander ---\n", true))
	{
		id = 104;
	}
	if (!strcmp(HeroName, "--- Ember Spirit ---\n", true))
	{
		id = 106;
	}
	if (!strcmp(HeroName, "--- Earth Spirit ---\n", true))
	{
		id = 107;
	}
	if (!strcmp(HeroName, "npc_dota_hero_abyssal_underlord", true))
	{
		id = 108;
	}
	if (!strcmp(HeroName, "--- Terrorblade ---\n", true))
	{
		id = 109;
	}
	if (!strcmp(HeroName, "--- Phoenix ---\n", true))
	{
		id = 110;
	}
	if (!strcmp(HeroName, "--- Oracle ---\n", true))
	{
		id = 111;
	}
	if (!strcmp(HeroName, "--- Techies ---\n", true))
	{
		id = 105;
	}
	if (!strcmp(HeroName, "npc_dota_hero_winter_wyvern", true))
	{
		id = 112;
	}
	return id;
}

Insert_Winner(Handle:Connection, winner, gameid[])
{
	new String:error[256];
	new String:query[256];
	Connection = SQL_DefConnect(error, 255, true);
	if (Connection)
	{
		if (winner == 2)
		{
			Format(query, 255, "INSERT INTO dotagames (id,botid,gameid,winner,min,sec) VALUES (NULL,1,'%s', 1, 0, 0)", gameid);
			if (SQL_Query(Connection, query, -1))
			{
			}
			else
			{
				SQL_GetError(Connection, error, 255);
				PrintToServer("Failed to Insert in dotagames (error: %s)", error);
			}
		}
		Format(query, 255, "INSERT INTO dotagames (id,botid,gameid,winner,min,sec) VALUES (NULL,1,'%s', 2, 0, 0)", gameid);
		if (SQL_Query(Connection, query, -1))
		{
		}
		else
		{
			SQL_GetError(Connection, error, 255);
			PrintToServer("Failed to Insert in dotagames (error: %s)", error);
		}
	}
	else
	{
		PrintToServer("Could not connect: %s", error);
	}
	CloseHandle(Connection);
	return 0;
}

Insert_Game(Handle:Connection, gameid[], gamename[], duration)
{
	new String:error[256];
	new String:query[256];
	Connection = SQL_DefConnect(error, 255, true);
	if (Connection)
	{
		new String:datetime[24];
		FormatTime(datetime, 21, "%Y-%m-%d %H:%M:%S", -1);
		Format(query, 255, "INSERT INTO games ( id, botid, server, datetime, gamename, ownername, duration, gamestate, creatorname,stats, views) VALUES ( %s, 1,'192.168.96.2','%s','%s','DOTA 2', %d, 16, 'DOTA 2', 0, 0 )", gameid, datetime, gamename, duration);
		if (SQL_Query(Connection, query, -1))
		{
		}
		else
		{
			SQL_GetError(Connection, error, 255);
			PrintToServer("Failed to Insert in games (error: %s)", error);
		}
	}
	else
	{
		PrintToServer("Could not connect: %s", error);
	}
	CloseHandle(Connection);
	return 0;
}

Insert_Players(Handle:Connection, Handle:adt_array[], gameid[], duration)
{
	new String:error[1024];
	new String:query[1024];
	Connection = SQL_DefConnect(error, 1024, true);
	if (Connection)
	{
		new good;
		new bad = 6;
		new String:steamid[32];
		new String:ip[32];
		new String:hd[32];
		new i;
		while (i < 10)
		{
			if (GetArrayCell(adt_array[i], 14, 0, false) == 2)
			{
				good++;
				GetArrayString(adt_array[i], 24, ip, 32);
				GetArrayString(adt_array[i], 22, hd, 32);
				if (GetArrayCell(adt_array[i], 17, 0, false))
				{
					Format(query, 1024, "INSERT INTO gameplayers ( botid,gameid,name,ip,spoofed,gameplayers.left,leftreason,team,colour,spoofedrealm ) VALUES ( 1,'%s','%d','%s',1,'%d','has disconnected',0,%d,'192.168.96.2')", gameid, GetArrayCell(adt_array[i], 26, 0, false), ip, GetArrayCell(adt_array[i], 17, 0, false), good);
					if (SQL_Query(Connection, query, -1))
					{
					}
					else
					{
						SQL_GetError(Connection, error, 1024);
						PrintToServer("Failed to Insert in gameplayers good (error: %s)", error);
					}
				}
				else
				{
					Format(query, 1024, "INSERT INTO gameplayers ( botid,gameid,name,ip,spoofed,gameplayers.left,leftreason,team,colour,spoofedrealm ) VALUES ( 1,'%s','%d','%s',1,'%d','has left the game voluntarily',0,%d,'192.168.96.2')", gameid, GetArrayCell(adt_array[i], 26, 0, false), ip, duration, good);
					if (SQL_Query(Connection, query, -1))
					{
					}
					else
					{
						SQL_GetError(Connection, error, 1024);
						PrintToServer("Failed to Insert in gameplayers good (error: %s)", error);
					}
				}
				Format(query, 1024, "INSERT INTO dotaplayers (botid,gameid,colour,kills,deaths,creepkills,creepdenies,assists,gold,neutralkills,hero,newcolour,towerkills,raxkills,courierkills ) VALUES ( 1,'%s','%d','%d','%d','%d','%d','%d','%d','%d','%d','%d','%s','%d','%d' )", gameid, good, GetArrayCell(adt_array[i], 8, 0, false), GetArrayCell(adt_array[i], 9, 0, false), GetArrayCell(adt_array[i], 11, 0, false), GetArrayCell(adt_array[i], 12, 0, false), GetArrayCell(adt_array[i], 10, 0, false), GetArrayCell(adt_array[i], 18, 0, false), GetArrayCell(adt_array[i], 16, 0, false), GetArrayCell(adt_array[i], 1, 0, false), good, hd, GetArrayCell(adt_array[i], 25, 0, false), GetArrayCell(adt_array[i], 15, 0, false));
				if (!(SQL_Query(Connection, query, -1)))
				{
					SQL_GetError(Connection, error, 1024);
					PrintToServer("Failed to Insert in dotaplayers good (error: %s)", error);
				}
				Format(query, 1024, "UPDATE dotaplayers SET item1=%d,item2=%d,item3=%d,item4=%d,item5=%d,item6=%d  WHERE gameid=%s AND colour=%d ", GetArrayCell(adt_array[i], 2, 0, false), GetArrayCell(adt_array[i], 3, 0, false), GetArrayCell(adt_array[i], 4, 0, false), GetArrayCell(adt_array[i], 5, 0, false), GetArrayCell(adt_array[i], 6, 0, false), GetArrayCell(adt_array[i], 7, 0, false), gameid, good);
				if (SQL_Query(Connection, query, -1))
				{
				}
				else
				{
					SQL_GetError(Connection, error, 1024);
					PrintToServer("Failed to update items in dotaplayers good (error: %s)", error);
				}
			}
			if (GetArrayCell(adt_array[i], 14, 0, false) == 3)
			{
				bad++;
				GetArrayString(adt_array[i], 20, steamid, 32);
				GetArrayString(adt_array[i], 24, ip, 32);
				GetArrayString(adt_array[i], 22, hd, 32);
				if (GetArrayCell(adt_array[i], 17, 0, false))
				{
					Format(query, 1024, "INSERT INTO gameplayers ( botid,gameid,name,ip,spoofed,gameplayers.left,leftreason,team,colour,spoofedrealm ) VALUES ( 1,'%s','%d','%s',1,'%d','has disconnected',1,%d,'192.168.96.2')", gameid, GetArrayCell(adt_array[i], 26, 0, false), ip, GetArrayCell(adt_array[i], 17, 0, false), bad);
					if (SQL_Query(Connection, query, -1))
					{
					}
					else
					{
						SQL_GetError(Connection, error, 1024);
						PrintToServer("Failed to Insert in gameplayers bad (error: %s)", error);
					}
				}
				else
				{
					Format(query, 1024, "INSERT INTO gameplayers ( botid,gameid,name,ip,spoofed,gameplayers.left,leftreason,team,colour,spoofedrealm ) VALUES ( 1,'%s','%d','%s',1,%d,'has left the game voluntarily',1,%d,'192.168.96.2')", gameid, GetArrayCell(adt_array[i], 26, 0, false), ip, duration, bad);
					if (SQL_Query(Connection, query, -1))
					{
					}
					else
					{
						SQL_GetError(Connection, error, 1024);
						PrintToServer("Failed to Insert in gameplayers bad (error: %s)", error);
					}
				}
				Format(query, 1024, "INSERT INTO dotaplayers (botid,gameid,colour,kills,deaths,creepkills,creepdenies,assists,gold,neutralkills,hero,newcolour,towerkills,raxkills,courierkills ) VALUES ( 1,'%s','%d','%d','%d','%d','%d','%d','%d','%d','%d','%d','%s','%d','%d' )", gameid, bad, GetArrayCell(adt_array[i], 8, 0, false), GetArrayCell(adt_array[i], 9, 0, false), GetArrayCell(adt_array[i], 11, 0, false), GetArrayCell(adt_array[i], 12, 0, false), GetArrayCell(adt_array[i], 10, 0, false), GetArrayCell(adt_array[i], 18, 0, false), GetArrayCell(adt_array[i], 16, 0, false), GetArrayCell(adt_array[i], 1, 0, false), bad, hd, GetArrayCell(adt_array[i], 25, 0, false), GetArrayCell(adt_array[i], 15, 0, false));
				if (!(SQL_Query(Connection, query, -1)))
				{
					SQL_GetError(Connection, error, 1024);
					PrintToServer("Failed to Insert in dotaplayers bad (error: %s)", error);
				}
				Format(query, 1024, "UPDATE dotaplayers SET item1=%d,item2=%d,item3=%d,item4=%d,item5=%d,item6=%d  WHERE gameid=%s AND colour=%d ", GetArrayCell(adt_array[i], 2, 0, false), GetArrayCell(adt_array[i], 3, 0, false), GetArrayCell(adt_array[i], 4, 0, false), GetArrayCell(adt_array[i], 5, 0, false), GetArrayCell(adt_array[i], 6, 0, false), GetArrayCell(adt_array[i], 7, 0, false), gameid, bad);
				if (SQL_Query(Connection, query, -1))
				{
				}
				else
				{
					SQL_GetError(Connection, error, 1024);
					PrintToServer("Failed to update items in dotaplayers bad (error: %s)", error);
				}
			}
			i++;
		}
	}
	else
	{
		PrintToServer("Could not connect: %s", error);
	}
	CloseHandle(Connection);
	return 0;
}

Insert_Abilities(Handle:Connection, Handle:adt_array[], gameid[])
{
	new String:error[1024];
	new String:query[1024];
	Connection = SQL_DefConnect(error, 1024, true);
	if (Connection)
	{
		new good;
		new bad = 6;
		new String:abilitig[160];
		new String:abilitib[160];
		new String:ability[12];
		new i;
		while (i < 10)
		{
			if (GetArrayCell(adt_array[i], 14, 0, false) == 2)
			{
				good++;
				if (GetArraySize(adt_array[i]) > 28)
				{
					new f = 28;
					while (GetArraySize(adt_array[i]) > f)
					{
						IntToString(GetArrayCell(adt_array[i], f, 0, false), ability, 10);
						StrCat(abilitig, 160, ability);
						StrCat(abilitig, 160, ",");
						f++;
					}
				}
				Format(query, 1024, "UPDATE dotaplayers SET abilities='%s' WHERE gameid=%s AND colour=%d ", abilitig, gameid, good);
				if (SQL_Query(Connection, query, -1))
				{
				}
				else
				{
					SQL_GetError(Connection, error, 1024);
					PrintToServer("Failed to update abilities in dotaplayers good (error: %s)", error);
				}
			}
			if (GetArrayCell(adt_array[i], 14, 0, false) == 3)
			{
				bad++;
				if (GetArraySize(adt_array[i]) > 28)
				{
					new f = 28;
					while (GetArraySize(adt_array[i]) > f)
					{
						IntToString(GetArrayCell(adt_array[i], f, 0, false), ability, 10);
						StrCat(abilitib, 160, ability);
						StrCat(abilitib, 160, ",");
						f++;
					}
				}
				Format(query, 1024, "UPDATE dotaplayers SET abilities='%s' WHERE gameid=%s AND colour=%d ", abilitib, gameid, bad);
				if (SQL_Query(Connection, query, -1))
				{
				}
				else
				{
					SQL_GetError(Connection, error, 1024);
					PrintToServer("Failed to update abilities in dotaplayers bad (error: %s)", error);
				}
			}
			i++;
		}
	}
	else
	{
		PrintToServer("Could not connect: %s", error);
	}
	CloseHandle(Connection);
	return 0;
}

public OnPluginStart()
{
	HookEvent("player_team", Joined, EventHookMode:1);
	HookEvent("dota_player_learned_ability", abi_up, EventHookMode:1);
	HookUserMessage(UserMsg:24, MsgHook3, true, MsgPostHook:-1);
	HookEvent("dota_match_done", get_stats, EventHookMode:0);
	adt_log = CreateArray(32, 0);
	new i;
	while (i < 10)
	{
		global_stats[i] = CreateArray(32, 28);
		SetArrayCell(global_stats[i], 0, any:-1, 0, false);
		i++;
	}
	adt_clients = CreateArray(1, 0);
	return 0;
}

public OnClientConnected(client)
{
	new i;
	while (i < 10)
	{
		if (client == GetArrayCell(global_stats[i], 0, 0, false))
		{
			SetArrayCell(global_stats[i], 17, any:0, 0, false);
		}
		i++;
	}
	return 0;
}

public OnClientDisconnect(client)
{
	new start_time = GameRules_GetPropFloat("m_flGameStartTime", 0);
	new game_time = GameRules_GetPropFloat("m_fGameTime", 0);
	new time = game_time - start_time;
	new i;
	while (i < 10)
	{
		if (client == GetArrayCell(global_stats[i], 0, 0, false))
		{
			SetArrayCell(global_stats[i], 17, RoundToNearest(time), 0, false);
		}
		i++;
	}
	return 0;
}

public Action:abi_up(Handle:event, String:name[], bool:dontBroadcast)
{
	new player_id = GetEventInt(event, "player");
	new abi_name[64];
	GetEventString(event, "abilityname", abi_name, 64);
	new i;
	while (i < 10)
	{
		if (player_id == GetArrayCell(global_stats[i], 0, 0, false))
		{
			PushArrayCell(global_stats[i], GetAbilityIdByName(abi_name));
		}
		i++;
	}
	return Action:0;
}

public Action:Joined(Handle:event, String:name[], bool:dontBroadcast)
{
	new team = GetEventInt(event, "team");
	new user = GetEventInt(event, "userid");
	new client_index = GetClientOfUserId(user);
	new String:steamid[32];
	new String:ip[32];
	new var1;
	if (team == 2 && FindValueInArray(adt_clients, client_index) == -1 && index_g < 5)
	{
		GetClientAuthId(client_index, AuthIdType:2, steamid, 32, true);
		GetClientIP(client_index, ip, 32, true);
		steamid[0] = MissingTAG:117;
		SetArrayString(global_stats[index_g], 20, steamid);
		SetArrayString(global_stats[index_g], 24, ip);
		SetArrayCell(global_stats[index_g], 0, client_index, 0, false);
		SetArrayCell(global_stats[index_g], 17, any:0, 0, false);
		SetArrayCell(global_stats[index_g], 27, GetSteamAccountID(client_index, true), 0, false);
		index_g = index_g + 1;
		PushArrayCell(adt_clients, client_index);
	}
	new var2;
	if (team == 3 && FindValueInArray(adt_clients, client_index) == -1 && index_b < 5)
	{
		GetClientAuthId(client_index, AuthIdType:2, steamid, 32, true);
		GetClientIP(client_index, ip, 32, true);
		steamid[0] = MissingTAG:117;
		SetArrayString(global_stats[index_b + 5], 20, steamid);
		SetArrayString(global_stats[index_b + 5], 24, ip);
		SetArrayCell(global_stats[index_b + 5], 0, client_index, 0, false);
		SetArrayCell(global_stats[index_b + 5], 17, any:0, 0, false);
		SetArrayCell(global_stats[index_b + 5], 27, GetSteamAccountID(client_index, true), 0, false);
		index_b = index_b + 1;
		PushArrayCell(adt_clients, client_index);
	}
	return Action:0;
}

public Action:Command_Say(client, String:command[], args)
{
	return Action:0;
}

public Action:get_stats(Handle:event, String:name[], bool:dontBroadcast)
{
	new pr = GetPlayerResourceEntity();
	new spec = FindEntityByClassname(-1, "dota_data_spectator");
	new radiant = FindEntityByClassname(-1, "dota_data_radiant");
	new dire = FindEntityByClassname(-1, "dota_data_dire");
	new radiant_gold[10];
	new dire_gold[10];
	new hero_ids[10];
	new hero_ent[10];
	new team[10];
	new level[10];
	new kills[10];
	new assists[10];
	new deaths[10];
	new last_hits[10];
	new denies[10];
	new towerk[10];
	new roshank[10];
	new networth[10];
	new hhealing[10];
	new accounts[10];
	new id_offset = FindSendPropInfo("CDOTA_PlayerResource", "m_iPlayerSteamIDs", 0, 0, 0);
	new i;
	while (i < 10)
	{
		hero_ids[i] = GetEntProp(pr, PropType:0, "m_nSelectedHeroID", 4, i);
		hero_ent[i] = GetEntPropEnt(pr, PropType:0, "m_hSelectedHero", i);
		team[i] = GetEntProp(pr, PropType:0, "m_iPlayerTeams", 4, i);
		level[i] = GetEntProp(pr, PropType:0, "m_iLevel", 4, i);
		kills[i] = GetEntProp(pr, PropType:0, "m_iKills", 4, i);
		assists[i] = GetEntProp(pr, PropType:0, "m_iAssists", 4, i);
		deaths[i] = GetEntProp(pr, PropType:0, "m_iDeaths", 4, i);
		last_hits[i] = GetEntProp(pr, PropType:0, "m_iLastHitCount", 4, i);
		denies[i] = GetEntProp(pr, PropType:0, "m_iDenyCount", 4, i);
		towerk[i] = GetEntProp(pr, PropType:0, "m_iTowerKills", 4, i);
		roshank[i] = GetEntProp(pr, PropType:0, "m_iRoshanKills", 4, i);
		networth[i] = GetEntProp(spec, PropType:0, "m_iNetWorth", 4, i);
		hhealing[i] = GetEntPropFloat(pr, PropType:0, "m_fHealing", i);
		accounts[i] = GetEntData(pr, i * 8 + id_offset, 4);
		radiant_gold[i] = GetEntProp(radiant, PropType:0, "m_iUnreliableGold", 4, i) + GetEntProp(radiant, PropType:0, "m_iReliableGold", 4, i);
		dire_gold[i] = GetEntProp(dire, PropType:0, "m_iUnreliableGold", 4, i) + GetEntProp(dire, PropType:0, "m_iReliableGold", 4, i);
		i++;
	}
	new j;
	while (j < 10)
	{
		if (team[j] == 2)
		{
			SetArrayCell(global_stats[count_g], 1, hero_ids[j], 0, false);
			SetArrayCell(global_stats[count_g], 8, kills[j], 0, false);
			SetArrayCell(global_stats[count_g], 9, deaths[j], 0, false);
			SetArrayCell(global_stats[count_g], 10, assists[j], 0, false);
			SetArrayCell(global_stats[count_g], 11, last_hits[j], 0, false);
			SetArrayCell(global_stats[count_g], 12, denies[j], 0, false);
			SetArrayCell(global_stats[count_g], 13, level[j], 0, false);
			SetArrayCell(global_stats[count_g], 14, team[j], 0, false);
			SetArrayCell(global_stats[count_g], 15, towerk[j], 0, false);
			SetArrayCell(global_stats[count_g], 16, roshank[j], 0, false);
			SetArrayCell(global_stats[count_g], 18, radiant_gold[j], 0, false);
			SetArrayCell(global_stats[count_g], 19, networth[j], 0, false);
			SetArrayCell(global_stats[count_g], 21, hero_ent[j], 0, false);
			SetArrayCell(global_stats[count_g], 25, RoundToNearest(hhealing[j]), 0, false);
			SetArrayCell(global_stats[count_g], 26, accounts[j], 0, false);
			count_g = count_g + 1;
		}
		if (team[j] == 3)
		{
			SetArrayCell(global_stats[count_b], 1, hero_ids[j], 0, false);
			SetArrayCell(global_stats[count_b], 8, kills[j], 0, false);
			SetArrayCell(global_stats[count_b], 9, deaths[j], 0, false);
			SetArrayCell(global_stats[count_b], 10, assists[j], 0, false);
			SetArrayCell(global_stats[count_b], 11, last_hits[j], 0, false);
			SetArrayCell(global_stats[count_b], 12, denies[j], 0, false);
			SetArrayCell(global_stats[count_b], 13, level[j], 0, false);
			SetArrayCell(global_stats[count_b], 14, team[j], 0, false);
			SetArrayCell(global_stats[count_b], 15, towerk[j], 0, false);
			SetArrayCell(global_stats[count_b], 16, roshank[j], 0, false);
			SetArrayCell(global_stats[count_b], 18, dire_gold[j], 0, false);
			SetArrayCell(global_stats[count_b], 19, networth[j], 0, false);
			SetArrayCell(global_stats[count_b], 21, hero_ent[j], 0, false);
			SetArrayCell(global_stats[count_b], 25, RoundToNearest(hhealing[j]), 0, false);
			SetArrayCell(global_stats[count_b], 26, accounts[j], 0, false);
			count_b = count_b + 1;
		}
		j++;
	}
	new z;
	while (z < 10)
	{
		if (GetArrayCell(global_stats[z], 14, 0, false) == 2)
		{
			new var1;
			if (GetArrayCell(global_stats[z], 0, 0, false) > 0 || GetArrayCell(global_stats[z], 0, 0, false) < 33)
			{
				new heroEnt = GetArrayCell(global_stats[z], 21, 0, false);
				new j;
				while (j < 6)
				{
					new item = GetEntPropEnt(heroEnt, PropType:0, "m_hItems", j);
					if (!IsValidEntity(item))
					{
						SetArrayCell(global_stats[z], j + 2, any:0, 0, false);
					}
					else
					{
						new itemname[64];
						GetEdictClassname(item, itemname, 64);
						SetArrayCell(global_stats[z], j + 2, GetItemIdByName(itemname), 0, false);
					}
					j++;
				}
			}
		}
		if (GetArrayCell(global_stats[z], 14, 0, false) == 3)
		{
			new var2;
			if (GetArrayCell(global_stats[z], 0, 0, false) > 0 || GetArrayCell(global_stats[z], 0, 0, false) < 33)
			{
				new heroEnt = GetArrayCell(global_stats[z], 21, 0, false);
				new j;
				while (j < 6)
				{
					new item = GetEntPropEnt(heroEnt, PropType:0, "m_hItems", j);
					if (!IsValidEntity(item))
					{
						SetArrayCell(global_stats[z], j + 2, any:0, 0, false);
					}
					else
					{
						new itemname[64];
						GetEdictClassname(item, itemname, 64);
						SetArrayCell(global_stats[z], j + 2, GetItemIdByName(itemname), 0, false);
					}
					j++;
				}
			}
		}
		z++;
	}
	CombatLogParser();
	new String:hostn[28];
	new String:gameid[16];
	new winner = GameRules_GetProp("m_nGameWinner", 4, 0);
	new Handle:DHhostname = FindConVar("hostname");
	GetConVarString(DHhostname, hostn, 25);
	new fin = FindCharInString(hostn, 95, false);
	subSTR(hostn, -1, fin);
	Insert_Winner(SQLcon, winner, gameid);
	new end_time = GameRules_GetPropFloat("m_flGameEndTime", 0);
	new start_time = GameRules_GetPropFloat("m_flGameStartTime", 0);
	new duration = RoundToNearest(end_time - start_time);
	new String:gamen[28];
	new String:gamename[28];
	subSTR(hostn, FindCharInString(hostn, 95, false) + 1, strlen(hostn) + 1);
	ReplaceString(gamen, 25, "_", " ", true);
	Format(gamename, 25, "%s %dvs%d #%s", gamen, index_g, index_b, gameid);
	Insert_Game(SQLcon, gameid, gamename, duration);
	Insert_Players(SQLcon, global_stats, gameid, duration);
	Insert_Abilities(SQLcon, global_stats, gameid);
	new String:log[100];
	Format(log, 100, "pluginlog/%s.txt", hostn);
	new Handle:file = OpenFile(log, "w");
	new i;
	while (i < 10)
	{
		WriteFileLine(file, "global_stats[%d]", i);
		WriteFileLine(file, "[Clientindex]: %d", GetArrayCell(global_stats[i], 0, 0, false));
		WriteFileLine(file, "[heroid]: %d", GetArrayCell(global_stats[i], 1, 0, false));
		WriteFileLine(file, "[item1]: %d", GetArrayCell(global_stats[i], 2, 0, false));
		WriteFileLine(file, "[item2]: %d", GetArrayCell(global_stats[i], 3, 0, false));
		WriteFileLine(file, "[item3]: %d", GetArrayCell(global_stats[i], 4, 0, false));
		WriteFileLine(file, "[item4]: %d", GetArrayCell(global_stats[i], 5, 0, false));
		WriteFileLine(file, "[item5]: %d", GetArrayCell(global_stats[i], 6, 0, false));
		WriteFileLine(file, "[item6]: %d", GetArrayCell(global_stats[i], 7, 0, false));
		WriteFileLine(file, "[kills]: %d", GetArrayCell(global_stats[i], 8, 0, false));
		WriteFileLine(file, "[deaths]: %d", GetArrayCell(global_stats[i], 9, 0, false));
		WriteFileLine(file, "[assists]: %d", GetArrayCell(global_stats[i], 10, 0, false));
		WriteFileLine(file, "[last hits]: %d", GetArrayCell(global_stats[i], 11, 0, false));
		WriteFileLine(file, "[denies]: %d", GetArrayCell(global_stats[i], 12, 0, false));
		WriteFileLine(file, "[level]: %d", GetArrayCell(global_stats[i], 13, 0, false));
		WriteFileLine(file, "[team]: %d", GetArrayCell(global_stats[i], 14, 0, false));
		WriteFileLine(file, "[towerkill]: %d", GetArrayCell(global_stats[i], 15, 0, false));
		WriteFileLine(file, "[roshankill]: %d", GetArrayCell(global_stats[i], 16, 0, false));
		WriteFileLine(file, "[last seen]: %d", GetArrayCell(global_stats[i], 17, 0, false));
		WriteFileLine(file, "[gold]: %d", GetArrayCell(global_stats[i], 18, 0, false));
		WriteFileLine(file, "[networth]: %d", GetArrayCell(global_stats[i], 19, 0, false));
		new String:str[32];
		GetArrayString(global_stats[i], 20, str, 32);
		WriteFileLine(file, "[SteamId]: %s", str);
		WriteFileLine(file, "[hero entity]: %d", GetArrayCell(global_stats[i], 21, 0, false));
		GetArrayString(global_stats[i], 22, str, 32);
		WriteFileLine(file, "[hero damage]: %s", str);
		GetArrayString(global_stats[i], 24, str, 32);
		WriteFileLine(file, "[player ip]: %s", str);
		WriteFileLine(file, "[hero healing]: %f", GetArrayCell(global_stats[i], 25, 0, false));
		WriteFileLine(file, "[account]: %d", GetArrayCell(global_stats[i], 26, 0, false));
		WriteFileLine(file, "[client account]: %d", GetArrayCell(global_stats[i], 27, 0, false));
		if (GetArraySize(global_stats[i]) > 28)
		{
			new f = 28;
			while (GetArraySize(global_stats[i]) > f)
			{
				WriteFileLine(file, "[Ability%d]: %d", f + -27, GetArrayCell(global_stats[i], f, 0, false));
				f++;
			}
		}
		WriteFileLine(file, "\n\n");
		i++;
	}
	CloseHandle(file);
	return Action:0;
}

public Action:MsgHook3(UserMsg:msg_id, Handle:bf, players[], playersNum, bool:reliable, bool:init)
{
	if (GameRules_GetProp("m_nGameState", 4, 0) > 5)
	{
		new var1;
		if (indicator && indicator == 1)
		{
			new buffer[32];
			PbReadString(bf, "param", buffer, 32, 0);
			PushArrayString(adt_log, buffer);
			if (GetHeroIdByLogName(buffer))
			{
			}
			else
			{
				indicator = indicator + 1;
			}
		}
	}
	return Action:0;
}

public CombatLogParser()
{
	new i;
	while (GetArraySize(adt_log) > i)
	{
		new String:current_log[32];
		GetArrayString(adt_log, i, current_log, 32);
		new var1;
		if (GetHeroIdByLogName(current_log) != -1 && GetHeroIdByLogName(current_log))
		{
			new j;
			while (j < 10)
			{
				if (GetArrayCell(global_stats[j], 1, 0, false) == GetHeroIdByLogName(current_log))
				{
					new String:bufferino[32];
					GetArrayString(adt_log, i + 1, bufferino, 32);
					new String:total_damage[16];
					subSTR(bufferino, FindCharInString(bufferino, 58, false) + 2, strlen(bufferino));
					TrimString(total_damage);
					SetArrayString(global_stats[j], 22, total_damage);
				}
				j++;
			}
		}
		i++;
	}
	return 0;
}

