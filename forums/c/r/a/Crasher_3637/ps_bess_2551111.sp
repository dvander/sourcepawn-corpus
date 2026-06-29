#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <ps_natives>

#define PLUGIN_VERSION "2.0.0"
#define PS_ModuleName "\nBuy Extended Support Structure (BESS Module)"

#define MSGTAG "\x04[PS]\x01"

public Plugin:myinfo =
{
	name = "[PS] Buy Extended Support Structure",
	author = "McFlurry && evilmaniac and modified by Psykotik",
	description = "Module to extend buy support, example: !buy pills // this would buy you pills",
	version = PLUGIN_VERSION,
	url = "http://www.evilmania.net"
}

enum module_settings{
	Float:fVersion,
	Float:fMinLibraryVersion,
	Handle:hVersion,
	Handle:hEnabled,
	bool:bModuleLoaded
}
new ModuleSettings[module_settings];

void initPluginSettings(){
	ModuleSettings[fVersion] = 2.00;
	ModuleSettings[fMinLibraryVersion] = 1.77;

	ModuleSettings[hVersion] = CreateConVar("em_ps_bess", PLUGIN_VERSION, "PS Bess version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_REPLICATED);
	ModuleSettings[hEnabled] = CreateConVar("ps_bess_enable", "1", "Enable BESS Module", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	ModuleSettings[bModuleLoaded] = false;
	return;
}

StringMap hItemMap = null;
StringMap hPriceMap = null;
StringMap hTeamExclusive = null;

void populateItemMap(){
	// Health Items
	hItemMap.SetString("pills", "give pain_pills", true);
	hItemMap.SetString("medkit", "give first_aid_kit", true);
	hItemMap.SetString("defib", "give defibrillator", true);
	hItemMap.SetString("adren", "give adrenaline", true);
	hItemMap.SetString("fheal", "give health", true);
	hItemMap.SetString("heal", "give health", true);

	// Secondary Pistols
	hItemMap.SetString("pistol", "give pistol", true);
	hItemMap.SetString("magnum", "give pistol_magnum", true);

	// SMGs
	hItemMap.SetString("smg", "give smg", true);
	hItemMap.SetString("silenced", "give smg_silenced", true);
	hItemMap.SetString("mp5", "give smg_mp5", true);

	// Rifles
	hItemMap.SetString("m16", "give rifle", true);
	hItemMap.SetString("scar", "give rifle_desert", true);
	hItemMap.SetString("ak47", "give rifle_ak47", true);
	hItemMap.SetString("sg552", "give rifle_sg552", true);
	hItemMap.SetString("m60", "give rifle_m60", true);

	// Sniper
	hItemMap.SetString("hunting", "give hunting_rifle", true);
	hItemMap.SetString("scout", "give sniper_scout", true);
	hItemMap.SetString("military", "give sniper_military", true);
	hItemMap.SetString("awp", "give sniper_awp", true);

	// Shotguns
	hItemMap.SetString("chrome", "give shotgun_chrome", true);
	hItemMap.SetString("pump", "give pumpshotgun", true);
	hItemMap.SetString("spas", "give shotgun_spas", true);
	hItemMap.SetString("auto", "give autoshotgun", true);

	// Throwables
	hItemMap.SetString("molotov", "give molotov", true);
	hItemMap.SetString("pipe", "give pipe_bomb", true);
	hItemMap.SetString("bile", "give vomitjar", true);

	// Misc
	hItemMap.SetString("chainsaw", "give chainsaw", true);
	hItemMap.SetString("grenade", "give grenade_launcher", true);
	hItemMap.SetString("gnome", "give gnome", true);
	hItemMap.SetString("cola", "give cola_bottles", true);
	hItemMap.SetString("gas", "give gascan", true);
	hItemMap.SetString("propane", "give propanetank", true);
	hItemMap.SetString("fworks", "give fireworkcrate", true);
	hItemMap.SetString("oxy", "give oxygentank", true);

	// Upgrades
	hItemMap.SetString("packex", "give upgradepack_explosive", true);
	hItemMap.SetString("packin", "give upgradepack_incendiary", true);
	hItemMap.SetString("ammo", "give ammo", true);
	hItemMap.SetString("exammo", "upgrade_add EXPLOSIVE_AMMO", true);
	hItemMap.SetString("inammo", "upgrade_add INCENDIARY_AMMO", true);
	hItemMap.SetString("laser", "upgrade_add LASER_SIGHT", true);

	// Melee
	hItemMap.SetString("baseball_bat", "give baseball_bat", true);
	hItemMap.SetString("cricket_bat", "give cricket_bat", true);
	hItemMap.SetString("crowbar", "give crowbar", true);
	hItemMap.SetString("electric_guitar", "give electric_guitar", true);
	hItemMap.SetString("fireaxe", "give fireaxe", true);
	hItemMap.SetString("frying_pan", "give frying_pan", true);
	hItemMap.SetString("golfclub", "give golfclub", true);
	hItemMap.SetString("katana", "give katana", true);
	hItemMap.SetString("machete", "give machete", true);
	hItemMap.SetString("tonfa", "give tonfa", true);
	hItemMap.SetString("2_handed_concrete", "give 2_handed_concrete", true);
	hItemMap.SetString("aetherpickaxe", "give aetherpickaxe", true);
	hItemMap.SetString("aethersword", "give aethersword", true);
	hItemMap.SetString("arm", "give arm", true);
	hItemMap.SetString("b_brokenbottle", "give b_brokenbottle", true);
	hItemMap.SetString("b_foamfinger", "give b_foamfinger", true);
	hItemMap.SetString("b_legbone", "give b_legbone", true);
	hItemMap.SetString("bamboo", "give bamboo", true);
	hItemMap.SetString("barnacle", "give barnacle", true);
	hItemMap.SetString("bigoronsword", "give bigoronsword", true);
	hItemMap.SetString("bnc", "give bnc", true);
	hItemMap.SetString("bottle", "give bottle", true);
	hItemMap.SetString("bow", "give bow", true);
	hItemMap.SetString("bt_nail", "give bt_nail", true);
	hItemMap.SetString("bt_sledge", "give bt_sledge", true);
	hItemMap.SetString("btorch", "give btorch", true);
	hItemMap.SetString("chains", "give chains", true);
	hItemMap.SetString("chair", "give chair", true);
	hItemMap.SetString("chair2", "give chair2", true);
	hItemMap.SetString("combat_knife", "give combat_knife", true);
	hItemMap.SetString("computer_keyboard", "give computer_keyboard", true);
	hItemMap.SetString("concrete1", "give concrete1", true);
	hItemMap.SetString("concrete2", "give concrete2", true);
	hItemMap.SetString("custom_ammo_pack", "give custom_ammo_pack", true);
	hItemMap.SetString("daxe", "give daxe", true);
	hItemMap.SetString("dekustick", "give dekustick", true);
	hItemMap.SetString("dhoe", "give dhoe", true);
	hItemMap.SetString("doc1", "give doc1", true);
	hItemMap.SetString("dshovel", "give dshovel", true);
	hItemMap.SetString("dsword", "give dsword", true);
	hItemMap.SetString("dustpan", "give dustpan", true);
	hItemMap.SetString("electric_guitar2", "give electric_guitar2", true);
	hItemMap.SetString("electric_guitar3", "give electric_guitar3", true);
	hItemMap.SetString("electric_guitar4", "give electric_guitar4", true);
	hItemMap.SetString("enchsword", "give enchsword", true);
	hItemMap.SetString("fishingrod", "give fishingrod", true);
	hItemMap.SetString("flamethrower", "give flamethrower", true);
	hItemMap.SetString("foot", "give foot", true);
	hItemMap.SetString("fubar", "give fubar", true);
	hItemMap.SetString("gaxe", "give gaxe", true);
	hItemMap.SetString("ghoe", "give ghoe", true);
	hItemMap.SetString("gloves", "give gloves", true);
	hItemMap.SetString("gman", "give gman", true);
	hItemMap.SetString("gpickaxe", "give gpickaxe", true);
	hItemMap.SetString("gshovel", "give gshovel", true);
	hItemMap.SetString("guandao", "give guandao", true);
	hItemMap.SetString("guitar", "give guitar", true);
	hItemMap.SetString("hammer", "give hammer", true);
	hItemMap.SetString("helms_anduril", "give helms_anduril", true);
	hItemMap.SetString("helms_hatchet", "give helms_hatchet", true);
	hItemMap.SetString("helms_orcrist", "give helms_orcrist", true);
	hItemMap.SetString("helms_sting", "give helms_sting", true);
	hItemMap.SetString("helms_sword_and_shield", "give helms_sword_and_shield", true);
	hItemMap.SetString("hylianshield", "give hylianshield", true);
	hItemMap.SetString("iaxe", "give iaxe", true);
	hItemMap.SetString("ihoe", "give ihoe", true);
	hItemMap.SetString("ipickaxe", "give ipickaxe", true);
	hItemMap.SetString("isword", "give isword", true);
	hItemMap.SetString("katana2", "give katana2", true);
	hItemMap.SetString("kitchen_knife", "give kitchen_knife", true);
	hItemMap.SetString("lamp", "give lamp", true);
	hItemMap.SetString("legosword", "give legosword", true);
	hItemMap.SetString("lightsaber", "give lightsaber", true);
	hItemMap.SetString("lobo", "give lobo", true);
	hItemMap.SetString("longsword", "give longsword", true);
	hItemMap.SetString("m72law", "give m72law", true);
	hItemMap.SetString("mace", "give mace", true);
	hItemMap.SetString("mace2", "give mace2", true);
	hItemMap.SetString("mastersword", "give mastersword", true);
	hItemMap.SetString("mirrorshield", "give mirrorshield", true);
	hItemMap.SetString("mop", "give mop", true);
	hItemMap.SetString("mop2", "give mop2", true);
	hItemMap.SetString("muffler", "give muffler", true);
	hItemMap.SetString("nailbat", "give nailbat", true);
	hItemMap.SetString("pickaxe", "give pickaxe", true);
	hItemMap.SetString("pipehammer", "give pipehammer", true);
	hItemMap.SetString("pot", "give pot", true);
	hItemMap.SetString("riotshield", "give riotshield", true);
	hItemMap.SetString("rockaxe", "give rockaxe", true);
	hItemMap.SetString("scup", "give scup", true);
	hItemMap.SetString("sh2wood", "give sh2wood", true);
	hItemMap.SetString("shoe", "give shoe", true);
	hItemMap.SetString("slasher", "give slasher", true);
	hItemMap.SetString("spickaxe", "give spickaxe", true);
	hItemMap.SetString("sshovel", "give sshovel", true);
	hItemMap.SetString("ssword", "give ssword", true);
	hItemMap.SetString("syringe_gun", "give syringe_gun", true);
	hItemMap.SetString("thrower", "give thrower", true);
	hItemMap.SetString("tireiron", "give tireiron", true);
	hItemMap.SetString("tonfa_riot", "give tonfa_riot", true);
	hItemMap.SetString("trashbin", "give trashbin", true);
	hItemMap.SetString("vampiresword", "give vampiresword", true);
	hItemMap.SetString("wand", "give wand", true);
	hItemMap.SetString("waterpipe", "give waterpipe", true);
	hItemMap.SetString("waxe", "give waxe", true);
	hItemMap.SetString("weapon_chalice", "give weapon_chalice", true);
	hItemMap.SetString("weapon_morgenstern", "give weapon_morgenstern", true);
	hItemMap.SetString("weapon_shadowhand", "give weapon_shadowhand", true);
	hItemMap.SetString("weapon_sof", "give weapon_sof", true);
	hItemMap.SetString("woodbat", "give woodbat", true);
	hItemMap.SetString("wpickaxe", "give wpickaxe", true);
	hItemMap.SetString("wrench", "give wrench", true);
	hItemMap.SetString("wshovel", "give wshovel", true);
	hItemMap.SetString("wsword", "give wsword", true);
	hItemMap.SetString("wulinmiji", "give wulinmiji", true);

	// Infected
	hItemMap.SetString("kill", "kill", true);
	hItemMap.SetString("boomer", "z_spawn_old boomer auto", true);
	hItemMap.SetString("smoker", "z_spawn_old smoker auto", true);
	hItemMap.SetString("hunter", "z_spawn_old hunter auto", true);
	hItemMap.SetString("spitter", "z_spawn_old spitter auto", true);
	hItemMap.SetString("jockey", "z_spawn_old jockey auto", true);
	hItemMap.SetString("charger", "z_spawn_old charger auto", true);
	hItemMap.SetString("witch", "z_spawn_old witch auto", true);
	hItemMap.SetString("bride", "z_spawn_old witch_bride auto", true);
	hItemMap.SetString("tank", "z_spawn_old tank auto", true);
	hItemMap.SetString("horde", "director_force_panic_event", true);
	hItemMap.SetString("mob", "z_spawn_old mob auto", true);
	hItemMap.SetString("umob", "z_spawn_old mob", true);

	return;
}

void populatePriceMap(){
	// Health Items
	hPriceMap.SetValue("pills", FindConVar("l4d2_points_pills").IntValue, true);
	hPriceMap.SetValue("medkit", FindConVar("l4d2_points_medkit").IntValue, true);
	hPriceMap.SetValue("defib", FindConVar("l4d2_points_defib").IntValue, true);
	hPriceMap.SetValue("adren", FindConVar("l4d2_points_adrenaline").IntValue, true);

	// Secondary Pistols
	hPriceMap.SetValue("pistol", FindConVar("l4d2_points_pistol").IntValue, true);
	hPriceMap.SetValue("magnum", FindConVar("l4d2_points_magnum").IntValue, true);

	// SMGs
	hPriceMap.SetValue("smg", FindConVar("l4d2_points_smg").IntValue, true);
	hPriceMap.SetValue("silenced", FindConVar("l4d2_points_silenced").IntValue, true);
	hPriceMap.SetValue("mp5", FindConVar("l4d2_points_mp5").IntValue, true);

	// Rifles
	hPriceMap.SetValue("m16", FindConVar("l4d2_points_m16").IntValue, true);
	hPriceMap.SetValue("scar", FindConVar("l4d2_points_scar").IntValue, true);
	hPriceMap.SetValue("ak47", FindConVar("l4d2_points_ak47").IntValue, true);
	hPriceMap.SetValue("sg552", FindConVar("l4d2_points_sg552").IntValue, true);
	hPriceMap.SetValue("m60", FindConVar("l4d2_points_m60").IntValue, true);

	// Snipers
	hPriceMap.SetValue("hunting", FindConVar("l4d2_points_hunting").IntValue, true);
	hPriceMap.SetValue("scout", FindConVar("l4d2_points_scout").IntValue, true);
	hPriceMap.SetValue("military", FindConVar("l4d2_points_military").IntValue, true);
	hPriceMap.SetValue("awp", FindConVar("l4d2_points_awp").IntValue, true);

	// Shotguns
	hPriceMap.SetValue("chrome", FindConVar("l4d2_points_chrome").IntValue, true);
	hPriceMap.SetValue("pump", FindConVar("l4d2_points_pump").IntValue, true);
	hPriceMap.SetValue("spas", FindConVar("l4d2_points_spas").IntValue, true);
	hPriceMap.SetValue("auto", FindConVar("l4d2_points_auto").IntValue, true);

	// Throwables
	hPriceMap.SetValue("molotov", FindConVar("l4d2_points_molotov").IntValue, true);
	hPriceMap.SetValue("pipe", FindConVar("l4d2_points_pipe").IntValue, true);
	hPriceMap.SetValue("bile", FindConVar("l4d2_points_bile").IntValue, true);

	// Misc
	hPriceMap.SetValue("chainsaw", FindConVar("l4d2_points_chainsaw").IntValue, true);
	hPriceMap.SetValue("grenade", FindConVar("l4d2_points_grenade").IntValue, true);
	hPriceMap.SetValue("gnome", FindConVar("l4d2_points_gnome").IntValue, true);
	hPriceMap.SetValue("cola", FindConVar("l4d2_points_cola").IntValue, true);
	hPriceMap.SetValue("gas", FindConVar("l4d2_points_gascan").IntValue, true);
	hPriceMap.SetValue("propane", FindConVar("l4d2_points_propane").IntValue, true);
	hPriceMap.SetValue("fworks", FindConVar("l4d2_points_fireworks").IntValue, true);
	hPriceMap.SetValue("oxy", FindConVar("l4d2_points_oxygen").IntValue, true);

	// Upgrades
	hPriceMap.SetValue("packex", FindConVar("l4d2_points_explosive_ammo_pack").IntValue, true);
	hPriceMap.SetValue("packin", FindConVar("l4d2_points_incendiary_ammo_pack").IntValue, true);
	hPriceMap.SetValue("ammo", FindConVar("l4d2_points_refill").IntValue, true);
	hPriceMap.SetValue("exammo", FindConVar("l4d2_points_explosive_ammo").IntValue, true);
	hPriceMap.SetValue("inammo", FindConVar("l4d2_points_incendiary_ammo").IntValue, true);
	hPriceMap.SetValue("laser", FindConVar("l4d2_points_laser").IntValue, true);

	// Melee
	hPriceMap.SetValue("baseball_bat", FindConVar("l4d2_points_baseballbat").IntValue, true);
	hPriceMap.SetValue("cricket_bat", FindConVar("l4d2_points_cricketbat").IntValue, true);
	hPriceMap.SetValue("crowbar", FindConVar("l4d2_points_crowbar").IntValue, true);
	hPriceMap.SetValue("electric_guitar", FindConVar("l4d2_points_electricguitar").IntValue, true);
	hPriceMap.SetValue("fireaxe", FindConVar("l4d2_points_fireaxe").IntValue, true);
	hPriceMap.SetValue("frying_pan", FindConVar("l4d2_points_fryingpan").IntValue, true);
	hPriceMap.SetValue("golfclub", FindConVar("l4d2_points_golfclub").IntValue, true);
	hPriceMap.SetValue("katana", FindConVar("l4d2_points_katana").IntValue, true);
	hPriceMap.SetValue("machete", FindConVar("l4d2_points_machete").IntValue, true);
	hPriceMap.SetValue("tonfa", FindConVar("l4d2_points_tonfa").IntValue, true);
	hPriceMap.SetValue("2_handed_concrete", FindConVar("l4d2_points_2handedconcrete").IntValue, true);
	hPriceMap.SetValue("aetherpickaxe", FindConVar("l4d2_points_aetherpickaxe").IntValue, true);
	hPriceMap.SetValue("aethersword", FindConVar("l4d2_points_aethersword").IntValue, true);
	hPriceMap.SetValue("arm", FindConVar("l4d2_points_arm").IntValue, true);
	hPriceMap.SetValue("b_brokenbottle", FindConVar("l4d2_points_brokenbottle").IntValue, true);
	hPriceMap.SetValue("b_foamfinger", FindConVar("l4d2_points_foamfinger").IntValue, true);
	hPriceMap.SetValue("b_legbone", FindConVar("l4d2_points_legbone").IntValue, true);
	hPriceMap.SetValue("bamboo", FindConVar("l4d2_points_bamboo").IntValue, true);
	hPriceMap.SetValue("barnacle", FindConVar("l4d2_points_barnacle").IntValue, true);
	hPriceMap.SetValue("bigoronsword", FindConVar("l4d2_points_bigoronsword").IntValue, true);
	hPriceMap.SetValue("bnc", FindConVar("l4d2_points_bnc").IntValue, true);
	hPriceMap.SetValue("bottle", FindConVar("l4d2_points_bottle").IntValue, true);
	hPriceMap.SetValue("bow", FindConVar("l4d2_points_bow").IntValue, true);
	hPriceMap.SetValue("bt_nail", FindConVar("l4d2_points_nail").IntValue, true);
	hPriceMap.SetValue("bt_sledge", FindConVar("l4d2_points_sledge").IntValue, true);
	hPriceMap.SetValue("btorch", FindConVar("l4d2_points_torch").IntValue, true);
	hPriceMap.SetValue("chains", FindConVar("l4d2_points_chains").IntValue, true);
	hPriceMap.SetValue("chair", FindConVar("l4d2_points_chair").IntValue, true);
	hPriceMap.SetValue("chair2", FindConVar("l4d2_points_chair2").IntValue, true);
	hPriceMap.SetValue("combat_knife", FindConVar("l4d2_points_combatknife").IntValue, true);
	hPriceMap.SetValue("computer_keyboard", FindConVar("l4d2_points_computerkeyboard").IntValue, true);
	hPriceMap.SetValue("concrete1", FindConVar("l4d2_points_concrete1").IntValue, true);
	hPriceMap.SetValue("concrete2", FindConVar("l4d2_points_concrete2").IntValue, true);
	hPriceMap.SetValue("custom_ammo_pack", FindConVar("l4d2_points_customammopack").IntValue, true);
	hPriceMap.SetValue("daxe", FindConVar("l4d2_points_daxe").IntValue, true);
	hPriceMap.SetValue("dekustick", FindConVar("l4d2_points_dekustick").IntValue, true);
	hPriceMap.SetValue("dhoe", FindConVar("l4d2_points_dhoe").IntValue, true);
	hPriceMap.SetValue("doc1", FindConVar("l4d2_points_doc1").IntValue, true);
	hPriceMap.SetValue("dshovel", FindConVar("l4d2_points_dshovel").IntValue, true);
	hPriceMap.SetValue("dsword", FindConVar("l4d2_points_dsword").IntValue, true);
	hPriceMap.SetValue("dustpan", FindConVar("l4d2_points_dustpan").IntValue, true);
	hPriceMap.SetValue("electric_guitar2", FindConVar("l4d2_points_electricguitar2").IntValue, true);
	hPriceMap.SetValue("electric_guitar3", FindConVar("l4d2_points_electricguitar3").IntValue, true);
	hPriceMap.SetValue("electric_guitar4", FindConVar("l4d2_points_electricguitar4").IntValue, true);
	hPriceMap.SetValue("enchsword", FindConVar("l4d2_points_enchsword").IntValue, true);
	hPriceMap.SetValue("fishingrod", FindConVar("l4d2_points_fishingrod").IntValue, true);
	hPriceMap.SetValue("flamethrower", FindConVar("l4d2_points_flamethrower").IntValue, true);
	hPriceMap.SetValue("foot", FindConVar("l4d2_points_foot").IntValue, true);
	hPriceMap.SetValue("fubar", FindConVar("l4d2_points_fubar").IntValue, true);
	hPriceMap.SetValue("gaxe", FindConVar("l4d2_points_gaxe").IntValue, true);
	hPriceMap.SetValue("ghoe", FindConVar("l4d2_points_ghoe").IntValue, true);
	hPriceMap.SetValue("gloves", FindConVar("l4d2_points_gloves").IntValue, true);
	hPriceMap.SetValue("gman", FindConVar("l4d2_points_gman").IntValue, true);
	hPriceMap.SetValue("gpickaxe", FindConVar("l4d2_points_gpickaxe").IntValue, true);
	hPriceMap.SetValue("gshovel", FindConVar("l4d2_points_gshovel").IntValue, true);
	hPriceMap.SetValue("guandao", FindConVar("l4d2_points_guandao").IntValue, true);
	hPriceMap.SetValue("guitar", FindConVar("l4d2_points_guitar").IntValue, true);
	hPriceMap.SetValue("hammer", FindConVar("l4d2_points_hammer").IntValue, true);
	hPriceMap.SetValue("helms_anduril", FindConVar("l4d2_points_helmsanduril").IntValue, true);
	hPriceMap.SetValue("helms_hatchet", FindConVar("l4d2_points_helmshatchet").IntValue, true);
	hPriceMap.SetValue("helms_orcrist", FindConVar("l4d2_points_helmsorcrist").IntValue, true);
	hPriceMap.SetValue("helms_sting", FindConVar("l4d2_points_helmssting").IntValue, true);
	hPriceMap.SetValue("helms_sword_and_shield", FindConVar("l4d2_points_helmsswordshield").IntValue, true);
	hPriceMap.SetValue("hylianshield", FindConVar("l4d2_points_hylianshield").IntValue, true);
	hPriceMap.SetValue("iaxe", FindConVar("l4d2_points_iaxe").IntValue, true);
	hPriceMap.SetValue("ihoe", FindConVar("l4d2_points_ihoe").IntValue, true);
	hPriceMap.SetValue("ipickaxe", FindConVar("l4d2_points_ipickaxe").IntValue, true);
	hPriceMap.SetValue("isword", FindConVar("l4d2_points_isword").IntValue, true);
	hPriceMap.SetValue("katana2", FindConVar("l4d2_points_katana2").IntValue, true);
	hPriceMap.SetValue("kitchen_knife", FindConVar("l4d2_points_kitchenknife").IntValue, true);
	hPriceMap.SetValue("lamp", FindConVar("l4d2_points_lamp").IntValue, true);
	hPriceMap.SetValue("legosword", FindConVar("l4d2_points_legosword").IntValue, true);
	hPriceMap.SetValue("lightsaber", FindConVar("l4d2_points_lightsaber").IntValue, true);
	hPriceMap.SetValue("lobo", FindConVar("l4d2_points_lobo").IntValue, true);
	hPriceMap.SetValue("longsword", FindConVar("l4d2_points_longsword").IntValue, true);
	hPriceMap.SetValue("m72law", FindConVar("l4d2_points_m72law").IntValue, true);
	hPriceMap.SetValue("mace", FindConVar("l4d2_points_mace").IntValue, true);
	hPriceMap.SetValue("mace2", FindConVar("l4d2_points_mace2").IntValue, true);
	hPriceMap.SetValue("mastersword", FindConVar("l4d2_points_mastersword").IntValue, true);
	hPriceMap.SetValue("mirrorshield", FindConVar("l4d2_points_mirrorshield").IntValue, true);
	hPriceMap.SetValue("mop", FindConVar("l4d2_points_mop").IntValue, true);
	hPriceMap.SetValue("mop2", FindConVar("l4d2_points_mop2").IntValue, true);
	hPriceMap.SetValue("muffler", FindConVar("l4d2_points_muffler").IntValue, true);
	hPriceMap.SetValue("nailbat", FindConVar("l4d2_points_nailbat").IntValue, true);
	hPriceMap.SetValue("pickaxe", FindConVar("l4d2_points_pickaxe").IntValue, true);
	hPriceMap.SetValue("pipehammer", FindConVar("l4d2_points_pipehammer").IntValue, true);
	hPriceMap.SetValue("pot", FindConVar("l4d2_points_pot").IntValue, true);
	hPriceMap.SetValue("riotshield", FindConVar("l4d2_points_riotshield").IntValue, true);
	hPriceMap.SetValue("rockaxe", FindConVar("l4d2_points_rockaxe").IntValue, true);
	hPriceMap.SetValue("scup", FindConVar("l4d2_points_scup").IntValue, true);
	hPriceMap.SetValue("sh2wood", FindConVar("l4d2_points_sh2wood").IntValue, true);
	hPriceMap.SetValue("shoe", FindConVar("l4d2_points_shoe").IntValue, true);
	hPriceMap.SetValue("slasher", FindConVar("l4d2_points_slasher").IntValue, true);
	hPriceMap.SetValue("spickaxe", FindConVar("l4d2_points_spickaxe").IntValue, true);
	hPriceMap.SetValue("sshovel", FindConVar("l4d2_points_sshovel").IntValue, true);
	hPriceMap.SetValue("ssword", FindConVar("l4d2_points_ssword").IntValue, true);
	hPriceMap.SetValue("syringe_gun", FindConVar("l4d2_points_syringegun").IntValue, true);
	hPriceMap.SetValue("thrower", FindConVar("l4d2_points_thrower").IntValue, true);
	hPriceMap.SetValue("tireiron", FindConVar("l4d2_points_tireiron").IntValue, true);
	hPriceMap.SetValue("tonfa_riot", FindConVar("l4d2_points_tonfariot").IntValue, true);
	hPriceMap.SetValue("trashbin", FindConVar("l4d2_points_trashbin").IntValue, true);
	hPriceMap.SetValue("vampiresword", FindConVar("l4d2_points_vampiresword").IntValue, true);
	hPriceMap.SetValue("wand", FindConVar("l4d2_points_wand").IntValue, true);
	hPriceMap.SetValue("waterpipe", FindConVar("l4d2_points_waterpipe").IntValue, true);
	hPriceMap.SetValue("waxe", FindConVar("l4d2_points_waxe").IntValue, true);
	hPriceMap.SetValue("weapon_chalice", FindConVar("l4d2_points_weaponchalice").IntValue, true);
	hPriceMap.SetValue("weapon_morgenstern", FindConVar("l4d2_points_weaponmorgenstern").IntValue, true);
	hPriceMap.SetValue("weapon_shadowhand", FindConVar("l4d2_points_weaponshadowhand").IntValue, true);
	hPriceMap.SetValue("weapon_sof", FindConVar("l4d2_points_weaponsof").IntValue, true);
	hPriceMap.SetValue("woodbat", FindConVar("l4d2_points_woodbat").IntValue, true);
	hPriceMap.SetValue("wpickaxe", FindConVar("l4d2_points_wpickaxe").IntValue, true);
	hPriceMap.SetValue("wrench", FindConVar("l4d2_points_wrench").IntValue, true);
	hPriceMap.SetValue("wshovel", FindConVar("l4d2_points_wshovel").IntValue, true);
	hPriceMap.SetValue("wsword", FindConVar("l4d2_points_wsword").IntValue, true);
	hPriceMap.SetValue("wulinmiji", FindConVar("l4d2_points_wulinmiji").IntValue, true);

	// Infected
	hPriceMap.SetValue("kill", FindConVar("l4d2_points_suicide").IntValue, true);
	hPriceMap.SetValue("boomer", FindConVar("l4d2_points_boomer").IntValue, true);
	hPriceMap.SetValue("smoker", FindConVar("l4d2_points_smoker").IntValue, true);
	hPriceMap.SetValue("hunter", FindConVar("l4d2_points_hunter").IntValue, true);
	hPriceMap.SetValue("spitter", FindConVar("l4d2_points_spitter").IntValue, true);
	hPriceMap.SetValue("jockey", FindConVar("l4d2_points_jockey").IntValue, true);
	hPriceMap.SetValue("charger", FindConVar("l4d2_points_charger").IntValue, true);
	hPriceMap.SetValue("witch", FindConVar("l4d2_points_witch").IntValue, true);
	hPriceMap.SetValue("bride", FindConVar("l4d2_points_witch").IntValue, true);
	hPriceMap.SetValue("tank", FindConVar("l4d2_points_tank").IntValue, true);
	hPriceMap.SetValue("horde", FindConVar("l4d2_points_horde").IntValue, true);
	hPriceMap.SetValue("mob", FindConVar("l4d2_points_mob").IntValue, true);
	hPriceMap.SetValue("umob", FindConVar("l4d2_points_umob").IntValue, true);

	return;
}

void populateExclusiveItemsMap(){
	//  Infected Only
	hTeamExclusive.SetValue("kill", 3, true);
	hTeamExclusive.SetValue("boomer", 3, true);
	hTeamExclusive.SetValue("smoker", 3, true);
	hTeamExclusive.SetValue("hunter", 3, true);
	hTeamExclusive.SetValue("spitter", 3, true);
	hTeamExclusive.SetValue("jockey", 3, true);
	hTeamExclusive.SetValue("charger", 3, true);
	hTeamExclusive.SetValue("witch", 3, true);
	hTeamExclusive.SetValue("bride", 3, true);
	hTeamExclusive.SetValue("tank", 3, true);
	hTeamExclusive.SetValue("horde", 3, true);
	hTeamExclusive.SetValue("mob", 3, true);
	hTeamExclusive.SetValue("umob", 3, true);

	// Survivor Only
	hTeamExclusive.SetValue("laser", 2, true);
	hTeamExclusive.SetValue("packex", 2, true);
	hTeamExclusive.SetValue("packin", 2, true);
	hTeamExclusive.SetValue("exammo", 2, true);
	hTeamExclusive.SetValue("inammo", 2, true);

	return;
}

void buildMap(){
	hItemMap = new StringMap();
	hPriceMap = new StringMap();
	hTeamExclusive = new StringMap();

	populateItemMap();
	populatePriceMap();
	populateExclusiveItemsMap();
	return;
}

void registerConsoleCommands(){
	RegConsoleCmd("sm_buy", Cmd_Buy);
	return;
}

bool IsModuleActive(){
	if(GetConVarBool(ModuleSettings[hEnabled]))
		if(ModuleSettings[bModuleLoaded])
			if(PS_IsSystemEnabled())
				return true;
	return false;
}

public void OnPluginStart(){
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false))
		SetFailState("%T", "Game Check Fail", LANG_SERVER);
	else{
		initPluginSettings();
		registerConsoleCommands();

		AutoExecConfig(true, "ps_bess");
		LoadTranslations("points_system.phrases");
	}
	return;
}

public void OnAllPluginsLoaded(){
	if(LibraryExists("ps_natives")){
		if(PS_GetVersion() >= ModuleSettings[fMinLibraryVersion]){
			if(!PS_RegisterModule(PS_ModuleName)) // If module registeration has failed
				LogMessage("[PS] Plugin already registered.");
			else{
				buildMap();
				ModuleSettings[bModuleLoaded] = true;
				return;
			}
		}
		else
			SetFailState("[PS] Outdated version of Points System installed.");
	}
	else
		SetFailState("[PS] PS Natives are not loaded.");

	return;
}

public void OnPluginEnd(){
	PS_UnregisterModule(PS_ModuleName);

	hItemMap.Clear();
	hPriceMap.Clear();

	return;
}

public OnPSUnloaded(){
	ModuleSettings[bModuleLoaded] = false;
	return;
}

public void OnConfigsExecuted(){
	populatePriceMap();
	return;
}

bool IsClientSurvivor(int iClientIndex){
	if(iClientIndex > 0){
		if(GetClientTeam(iClientIndex) == 2) // Survivor
			return true;
	}
	return false;
}

bool IsClientInfected(int iClientIndex){
	if(iClientIndex > 0){
		if(GetClientTeam(iClientIndex) == 3) // Infected
			return true;
	}
	return false;
}

bool IsClientTank(iClientIndex){
	if(iClientIndex > 0){
		if(GetEntProp(iClientIndex, Prop_Send, "m_zombieClass") == 8)
			return true;
	}
	return false;
}

bool checkDisabled(int iCost){
	if(iCost <= -1)
		//PrintToChat(iClientIndex, "%s %T", MSGTAG, "Item Disabled", LANG_SERVER);
		return true;
	else return false;
}

bool checkPoints(int iClientIndex, int iCost){
	if(PS_GetPoints(iClientIndex) >= iCost)
		return true;
	else
		PrintToChat(iClientIndex, "%s %T", MSGTAG, "Insufficient Funds", LANG_SERVER);
	return false;
}

bool hasEnoughPoints(int iClientIndex, int iCost){
	return(checkPoints(iClientIndex, iCost));
}

void removePoints(int iClientIndex, int iPoints){
	PS_RemovePoints(iClientIndex, iPoints);
	return;
}

int getHealCost(int iClientIndex){
	int iCost = -1;
	if(IsClientInfected(iClientIndex)){
		iCost = FindConVar("l4d2_points_infected_heal").IntValue;

		if(IsClientTank(iClientIndex))
			iCost *= FindConVar("l4d2_points_tank_heal_mult").IntValue;
	}
	else if(IsClientSurvivor(iClientIndex))
		iCost = FindConVar("l4d2_points_survivor_heal").IntValue;

	return(iCost);
}

public Action Cmd_Buy(int iClientIndex, int iNumArgs){
	if(iNumArgs != 1)
		return Plugin_Continue;

	if(!IsModuleActive() || !IsClientInGame(iClientIndex) || iClientIndex > MaxClients)
		return Plugin_Continue;

	if(!IsPlayerAlive(iClientIndex)){
		ReplyToCommand(iClientIndex, "[PS] Must Be Alive To Buy Items!");
		return Plugin_Continue;
	}

	decl String:sPlayerInput[50]; sPlayerInput[0] = '\0';
	decl String:sPurchaseCmd[100]; sPurchaseCmd[0] = '\0';
	GetCmdArg(1, sPlayerInput, sizeof(sPlayerInput));

	if(hItemMap.GetString(sPlayerInput, sPurchaseCmd, sizeof(sPurchaseCmd))){ // If an entry exists
		int iRequiredTeam = 0;
		if(hTeamExclusive.GetValue(sPlayerInput, iRequiredTeam))
			if(GetClientTeam(iClientIndex) != iRequiredTeam)
				return Plugin_Continue;

		int iCost = -2; //-2 = invalid
		if(StrEqual(sPlayerInput, "cola", false)){
			decl String:sMapName[100]; sMapName[0] = '\0';

			GetCurrentMap(sMapName, 100);
			if(StrEqual(sMapName, "c1m2_streets", false))
				PrintToChat(iClientIndex, "[PS] This item is unavailable during this map");
		}
		else if(StrEqual(sPlayerInput, "fheal", false) || StrEqual(sPlayerInput, "heal", false)){
			iCost = getHealCost(iClientIndex);
			if(!checkDisabled(iCost))
				performHeal(iClientIndex, iCost);
			return Plugin_Continue;
		}
		else{ // If not a special case
			if(hPriceMap.GetValue(sPlayerInput, iCost) && !checkDisabled(iCost)){
				if(StrEqual(sPlayerInput, "kill", false) && IsClientInfected(iClientIndex))
					performSuicide(iClientIndex, iCost);
				else if(StrEqual(sPlayerInput, "umob", false) && IsClientInfected(iClientIndex)){
					PS_SetBoughtCost(iClientIndex, iCost);
					PS_SetBought(iClientIndex, sPurchaseCmd);
					HandleUMob(iClientIndex);
				}
				else if(GetClientTeam(iClientIndex) > 1) // If not a spectator
					performPurchase(iClientIndex, iCost, sPurchaseCmd);
			}
		}
	}
	return Plugin_Continue;
}

bool IsCarryingWeapon(int iClientIndex){
	int iWeapon = GetPlayerWeaponSlot(iClientIndex, 0);
	if(iWeapon == -1)
		return false;
	else return true;
}

public reloadAmmo(int iClientIndex, int iCost, const char[] sItem){
	int hWeapon = GetPlayerWeaponSlot(iClientIndex, 0);
	if(IsCarryingWeapon(iClientIndex)){

		decl String:sWeapon[40]; sWeapon[0] = '\0';
		GetEdictClassname(hWeapon, sWeapon, sizeof(sWeapon));
		if(StrEqual(sWeapon, "weapon_rifle_m60", false)){
			int iAmmo_m60 = 150;
			new Handle:hGunControl_m60 = FindConVar("l4d2_guncontrol_m60ammo");
			if(hGunControl_m60 != null){
				iAmmo_m60 = GetConVarInt(hGunControl_m60);
				CloseHandle(hGunControl_m60);
			}
			SetEntProp(hWeapon, Prop_Data, "m_iClip1", iAmmo_m60, 1);
		}
		else if(StrEqual(sWeapon, "weapon_grenade_launcher", false)){
			int iAmmo_Launcher = 30;
			Handle hGunControl_Launcher = FindConVar("l4d2_guncontrol_grenadelauncherammo");
			if(hGunControl_Launcher != null){
				iAmmo_Launcher = GetConVarInt(hGunControl_Launcher);
				CloseHandle(hGunControl_Launcher);
			}
			int uOffset = FindDataMapOffs(iClientIndex, "m_iAmmo");
			SetEntData(iClientIndex, uOffset + 68, iAmmo_Launcher);
		}
		execClientCommand(iClientIndex, sItem);
		removePoints(iClientIndex, iCost);
	}
	else
		PrintToChat(iClientIndex, "%s %T", MSGTAG, "Primary Warning", LANG_SERVER);
	return;
}

void setLastPurchase(int iClientIndex, int iCost, const char[] sPurchaseCmd){ // We are doing this so !repeatbuy works
	PS_SetItem(iClientIndex, sPurchaseCmd);
	PS_SetCost(iClientIndex, iCost);
	return;
}

void performPurchase(int iClientIndex, int iCost, const char[] sPurchaseCmd){ // sItem[] should be const
	if(iCost >= 0){
		if(hasEnoughPoints(iClientIndex, iCost)){
			if(StrEqual(sPurchaseCmd, "give ammo", false)){
				reloadAmmo(iClientIndex, iCost, sPurchaseCmd);
				setLastPurchase(iClientIndex, iCost, sPurchaseCmd);
			}
			else{
				execClientCommand(iClientIndex, sPurchaseCmd);
				removePoints(iClientIndex, iCost);
				setLastPurchase(iClientIndex, iCost, sPurchaseCmd);
			}
		}
	}
	return;
}

void performHeal(int iClientIndex, int iCost){
	if(iCost >= 0){
		if(hasEnoughPoints(iClientIndex, iCost)){
			execClientCommand(iClientIndex, "give health");
			SetEntPropFloat(iClientIndex, Prop_Send, "m_healthBuffer", 0.0);
			removePoints(iClientIndex, iCost);
		}
	}
	return;
}

void performSuicide(int iClientIndex, int iCost){
	if(iCost >= 0){
		if(hasEnoughPoints(iClientIndex, iCost)){
			if(IsClientInGame(iClientIndex) && IsPlayerAlive(iClientIndex)){
				ForcePlayerSuicide(iClientIndex);
				if(IsClientTank(iClientIndex))
					return;
				else
				removePoints(iClientIndex, iCost);
			}
		}
	}
	return;
}

stock HandleUMob(iClientIndex)
{
	PS_SetCost(iClientIndex, PS_GetBoughtCost(iClientIndex));
	if(PS_GetCost(iClientIndex) > -1 && PS_GetPoints(iClientIndex) >= PS_GetCost(iClientIndex))
	{
		PS_SetupUMob(GetConVarInt(FindConVar("z_common_limit")));
		PS_SetItem(iClientIndex, "z_spawn_old mob");

		removePoints(iClientIndex, PS_GetCost(iClientIndex));

	}
	else if(checkDisabled(PS_GetCost(iClientIndex)))
		PS_SetBoughtCost(iClientIndex, PS_GetBoughtCost(iClientIndex));
	else
	{
		PS_SetBoughtCost(iClientIndex, PS_GetBoughtCost(iClientIndex));
		ReplyToCommand(iClientIndex, "%s %T", MSGTAG, "Insufficient Funds", LANG_SERVER);
	}
}

void execClientCommand(int iClientIndex, const char[] sCommand){
	RemoveFlags();
	FakeClientCommand(iClientIndex, sCommand);
	AddFlags();
	return;
}

void RemoveFlags(){
	new flagsgive = GetCommandFlags("give");
	new flagszspawn = GetCommandFlags("z_spawn_old");
	new flagsupgradeadd = GetCommandFlags("upgrade_add");
	new flagspanic = GetCommandFlags("director_force_panic_event");
	SetCommandFlags("give", flagsgive & ~FCVAR_CHEAT);
	SetCommandFlags("z_spawn_old", flagszspawn & ~FCVAR_CHEAT);
	SetCommandFlags("upgrade_add", flagsupgradeadd & ~FCVAR_CHEAT);
	SetCommandFlags("director_force_panic_event", flagspanic & ~FCVAR_CHEAT);
	return;
}

void AddFlags(){
	new flagsgive = GetCommandFlags("give");
	new flagszspawn = GetCommandFlags("z_spawn_old");
	new flagsupgradeadd = GetCommandFlags("upgrade_add");
	new flagspanic = GetCommandFlags("director_force_panic_event");
	SetCommandFlags("give", flagsgive|FCVAR_CHEAT);
	SetCommandFlags("z_spawn_old", flagszspawn|FCVAR_CHEAT);
	SetCommandFlags("upgrade_add", flagsupgradeadd|FCVAR_CHEAT);
	SetCommandFlags("director_force_panic_event", flagspanic|FCVAR_CHEAT);
	return;
}