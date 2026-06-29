#include <sourcemod>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <clientprefs>
#undef REQUIRE_PLUGIN
#include <updater>
#include <morecolors>

#define PLUGIN_VERSION		"1.9.7"
#define UPDATE_URL		"https://bitbucket.org/assyrian/tf2-advanced-armor-plugin/raw/default/updater.txt"

#define SoundArmorAdd		"weapons/quake_ammo_pickup_remastered.wav"
#define SoundArmorLose		"player/death.wav"
#define PLYR			MAXPLAYERS+1


//ints
int iArmor[PLYR];
int iMaxArmor[PLYR];
int ArmorType[PLYR];
int ArmorHUDColor[PLYR][3];
int iArmorRegenerate[PLYR];

//floats
float flArmorHUDParams[PLYR][2];
float flDamageResistance[PLYR];

//bools
bool bArmorOverheal[PLYR] = { false, ... };
bool bArmorEquipped[PLYR] = { true, ... };
bool ArmorVoice[PLYR] = { false, ... };
bool ArmorVoiceAuto[PLYR];
bool bAutoUpdate;
bool bMedicButtonBool[PLYR] = { false, ... };

//strings

enum
{
	Armor_None = 0,
	Armor_Light, //light Armor duh
	Armor_Medium,
	Armor_Heavy,
	Armor_Luck, //absorbs damage by probability
	Armor_Chance //absorbs fatal damage by probability
}

Handle hHudText;

ConVar plugin_enable = null;
ConVar armor_ammo_allow = null;
ConVar armor_bots_allow = null;
ConVar armor_from_engie = null;
ConVar allow_self_hurt = null;
ConVar allow_uber_damage = null;
ConVar allow_crit_pierce = null;
ConVar armorregen = null;
ConVar show_hud_armor = null;
ConVar armor_snd_allow = null;
ConVar allow_damage_overwhelm = null;

ConVar HUD_PreThink = null;
ConVar ArmorVoiceCvar = null;

ConVar life_armor_chance = null;
ConVar luck_armor_chance = null;

ConVar armor_from_spencer = null;
ConVar spencer_time = null;
ConVar allow_hud_change = null;
ConVar allow_hud_color = null;

ConVar maxarmor_scout = null;
ConVar maxarmor_soldier = null;
ConVar maxarmor_pyro = null;
ConVar maxarmor_demo = null;
ConVar maxarmor_heavy = null;
ConVar maxarmor_engie = null;
ConVar maxarmor_med = null;
ConVar maxarmor_sniper = null;
ConVar maxarmor_spy = null;

ConVar armor_from_metal = null;
ConVar armor_from_metal_mult = null;
ConVar spencer_to_armor = null;
ConVar armor_from_smallammo = null;
ConVar armor_from_medammo = null;
ConVar armor_from_fullammo = null;
//Handle armor_from_widowmaker = null;

ConVar damage_resistance_type1 = null;
ConVar damage_resistance_type2 = null;
ConVar damage_resistance_type3 = null;
ConVar damage_resistance_chance = null;

ConVar armortype_scout = null;
ConVar armortype_soldier = null;
ConVar armortype_pyro = null;
ConVar armortype_demo = null;
ConVar armortype_heavy = null;
ConVar armortype_engie = null;
ConVar armortype_med = null;
ConVar armortype_sniper = null;
ConVar armortype_spy = null;

ConVar armorregen_scout = null;
ConVar armorregen_soldier = null;
ConVar armorregen_pyro = null;
ConVar armorregen_demo = null;
ConVar armorregen_heavy = null;
ConVar armorregen_engie = null;
ConVar armorregen_med = null;
ConVar armorregen_sniper = null;
ConVar armorregen_spy = null;

//need moar handles lulz

ConVar armorspawn = null;
ConVar setarmormax = null;

ConVar cvBlu = null;
ConVar cvRed = null;

Handle HUDCookie;
Handle HUDParamsCookieX;
Handle HUDParamsCookieY;
Handle VoiceCookie;

Handle RedCookie;
Handle GreenCookie;
Handle BlueCookie;

ConVar timer_bitch_convar = null;

ConVar level1 = null;
ConVar level2 = null;
ConVar level3 = null;

ConVar cconVar = null;

//Handle g_hSdkEquipWearable; // handles viewmodels and world models; props to Friagram
//bool g_bEwSdkStarted;

//#define SOUND_REGENERATE	"items/spawn_item.wav"

//#define ARMOR_NONE	(1 << 0)
//#define ARMOR_HAS	(1 << 1)
//#define ARMOR_RED	(1 << 2)
//#define ARMOR_YELLOW	(1 << 3)
//#define ARMOR_GREEN	(1 << 4)

public Plugin myinfo = {
	name = "[TF2] Advanced Armor",
	author = "Assyrian/Nergal",
	description = "a plugin that gives armor for TF2",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"  
};

public void OnPluginStart()
{
	cconVar = CreateConVar("sm_adarmor_autoupdate", "1", "Is auto-update enabled?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	bAutoUpdate = cconVar.BoolValue;
	cconVar.AddChangeHook(OnAutoUpdateChange);

	hHudText = CreateHudSynchronizer();

	RegAdminCmd("sm_setarmor", Command_SetPlayerArmor, ADMFLAG_KICK);
	RegAdminCmd("reloadarmor", CmdReloadCFG, ADMFLAG_GENERIC);

	RegConsoleCmd("sm_armorhud", Command_SetPlayerHUD, "Let's a player set his/her Armor hud style");
	RegConsoleCmd("sm_armorhudparams", Command_SetHudParams, "Let's a player set his/her Armor hud params");
	RegConsoleCmd("sm_armorhelp", ArmorHelp, "help menu for players");
	RegConsoleCmd("sm_armorhudcolor", Command_SetHudColor, "let's players change their armor hud color");
	RegConsoleCmd("sm_armoron", CmdEnable);
	RegConsoleCmd("sm_armoroff", CmdDisable);
	RegConsoleCmd("sm_armorvoice", VoiceTogglePanelCmd);
	AddCommandListener(Listener_Voice, "voicemenu");

	HUDCookie = RegClientCookie("adarmor_hudstyle", "player's selected hud style", CookieAccess_Public);
	VoiceCookie = RegClientCookie("adarmor_voice", "player's armor voice setting", CookieAccess_Public);
	HUDParamsCookieX = RegClientCookie("adarmor_hudparamsx", "player's selected hud params x coordinate", CookieAccess_Public);
	HUDParamsCookieY = RegClientCookie("adarmor_hudparamsy", "player's selected hud params y coordinate", CookieAccess_Public);
	RedCookie = RegClientCookie("adarmor_hudred", "player's selected hud params red", CookieAccess_Public);
	GreenCookie = RegClientCookie("adarmor_hudgreen", "player's selected hud params green", CookieAccess_Public);
	BlueCookie = RegClientCookie("adarmor_hudblue", "player's selected hud params blue", CookieAccess_Public);

	plugin_enable = CreateConVar("sm_adarmor_enabled", "1", "Enable Advanced Armor plugin", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	HUD_PreThink = CreateConVar("sm_adarmor_hud_switch", "0", "switches between Timer HUD and OnPreThink, 0 = 0.2 second timer, and 1 puts the HUD on PreThink control", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	armor_ammo_allow = CreateConVar("sm_adarmor_fromammo", "1", "Enable getting armor from ammo", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	armor_bots_allow = CreateConVar("sm_adarmor_allow_bots", "1", "Enables bots to have armor", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	armor_snd_allow = CreateConVar("sm_adarmor_allow_sound", "1", "Enables sounds when getting/losing armor", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	ArmorVoiceCvar = CreateConVar("sm_adarmor_allow_voice", "1", "Enable/Disable Armor Voice, also prevents download of voice files", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	allow_damage_overwhelm = CreateConVar("sm_adarmor_allow_dmg_overwhelm", "1", "if damage depletes armor, transfer the rest of the damage to the player's health", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	life_armor_chance = CreateConVar("sm_adarmor_life_armor_chance", "2.5", "chance between 1.0 and 10.0 for Life armor to activate. The lower the decimal, the higher chance of the armor activating for players", FCVAR_PLUGIN|FCVAR_NOTIFY);

	luck_armor_chance = CreateConVar("sm_adarmor_luck_armor_chance", "3", "chance between 1 and 10 for Luck armor to activate. The lower the integer, the higher chance of the armor working for players", FCVAR_PLUGIN|FCVAR_NOTIFY);
	
	armor_from_engie = CreateConVar("sm_adarmor_armor_from_engie", "1", "Enable getting armor from engineer's metal", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	show_hud_armor = CreateConVar("sm_adarmor_show_hud_armor", "1", "Enable HUD", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	allow_self_hurt = CreateConVar("sm_adarmor_allow_self_hurt", "1", "Let's players destroy their own armor by damaging themselves", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	allow_uber_damage = CreateConVar("sm_adarmor_allow_uber_dmg", "0", "allows players to destroy ubered or bonked player's armor while invulnerable", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	allow_crit_pierce = CreateConVar("sm_adarmor_allow_crit_dmg", "0", "allows crit damage to ignore armor", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	allow_hud_change = CreateConVar("sm_adarmor_allow_hud_change", "1", "Let's players change their HUD parameters with sm_armorhudparams", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	allow_hud_color = CreateConVar("sm_adarmor_allow_hud_color", "1", "Let's players change their HUD color with sm_armorhudcolor", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	armorspawn = CreateConVar("sm_adarmor_armoronspawn", "1", "Enable players to spawn with armor, 1 = full armor, 2 = half, 0 = none", FCVAR_PLUGIN|FCVAR_NOTIFY);

	armorregen = CreateConVar("sm_adarmor_armorregen", "0", "Enables armor regen", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	armor_from_spencer = CreateConVar("sm_adarmor_armor_from_spencer", "1", "Enables armor from dispensers", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	level1 = CreateConVar("sm_adarmor_level1_repair", "0.0", "multiplier of how much armor level 1 dispensers will heal. Leave at 0.0 if you want level 1 dispensers to repair at sm_adarmor_dispenser_to_armor rate", FCVAR_PLUGIN|FCVAR_NOTIFY);
	level2 = CreateConVar("sm_adarmor_level2_repair", "0.50", "multiplier of how much armor level 2 dispensers will heal. Leave at 0.0 if you want level 2 dispensers to repair at sm_adarmor_dispenser_to_armor rate", FCVAR_PLUGIN|FCVAR_NOTIFY);
	level3 = CreateConVar("sm_adarmor_level3_repair", "1.0", "multiplier of how much armor level 3 dispensers will heal. Leave at 0.0 if you want level 3 dispensers to repair at sm_adarmor_dispenser_to_armor rate", FCVAR_PLUGIN|FCVAR_NOTIFY);

	cvBlu = CreateConVar("sm_adarmor_blue", "1", "Enables armor for BLU team", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvRed = CreateConVar("sm_adarmor_red", "1", "Enables armor for RED team", FCVAR_PLUGIN, true, 0.0, true, 1.0);

        CreateConVar("sm_adarmor_version", PLUGIN_VERSION, "Advanced Armor version", FCVAR_NOTIFY|FCVAR_PLUGIN);

	maxarmor_scout = CreateConVar("sm_adarmor_scout_maxarmor", "50", "sets how much max armor scout will have", FCVAR_PLUGIN|FCVAR_NOTIFY);
	maxarmor_soldier = CreateConVar("sm_adarmor_soldier_maxarmor", "200", "sets how much max armor soldier will have", FCVAR_PLUGIN|FCVAR_NOTIFY);
	maxarmor_pyro = CreateConVar("sm_adarmor_pyro_maxarmor", "150", "sets how much max armor pyro will have", FCVAR_PLUGIN|FCVAR_NOTIFY);
	maxarmor_demo = CreateConVar("sm_adarmor_demoman_maxarmor", "120", "sets how much max armor demoman will have", FCVAR_PLUGIN|FCVAR_NOTIFY);
	maxarmor_heavy = CreateConVar("sm_adarmor_heavy_maxarmor", "300", "sets how much max armor heavy will have", FCVAR_PLUGIN|FCVAR_NOTIFY);
	maxarmor_engie = CreateConVar("sm_adarmor_engineer_maxarmor", "60", "sets how much max armor engineer will have", FCVAR_PLUGIN|FCVAR_NOTIFY);
	maxarmor_med = CreateConVar("sm_adarmor_medic_maxarmor", "100", "sets how much max armor medic will have", FCVAR_PLUGIN|FCVAR_NOTIFY);
	maxarmor_sniper = CreateConVar("sm_adarmor_sniper_maxarmor", "50", "sets how much max armor sniper will have", FCVAR_PLUGIN|FCVAR_NOTIFY);
	maxarmor_spy = CreateConVar("sm_adarmor_spy_maxarmor", "100", "sets how much max armor spy will have", FCVAR_PLUGIN|FCVAR_NOTIFY);



	armorregen_scout = CreateConVar("sm_adarmor_scout_armoregen", "6", "armor regen per second for scout", FCVAR_PLUGIN|FCVAR_NOTIFY);
	armorregen_soldier = CreateConVar("sm_adarmor_soldier_armoregen", "8", "armor regen per second for soldier", FCVAR_PLUGIN|FCVAR_NOTIFY);
	armorregen_pyro = CreateConVar("sm_adarmor_pyro_armoregen", "8", "armor regen per second for pyro", FCVAR_PLUGIN|FCVAR_NOTIFY);
	armorregen_demo = CreateConVar("sm_adarmor_demoman_armoregen", "7", "armor regen per second for demoman", FCVAR_PLUGIN|FCVAR_NOTIFY);
	armorregen_heavy = CreateConVar("sm_adarmor_heavy_armoregen", "10", "armor regen per second for heavy", FCVAR_PLUGIN|FCVAR_NOTIFY);
	armorregen_engie = CreateConVar("sm_adarmor_engineer_armoregen", "6", "armor regen per second for engineer", FCVAR_PLUGIN|FCVAR_NOTIFY);
	armorregen_med = CreateConVar("sm_adarmor_medic_armoregen", "7", "armor regen per second for medic", FCVAR_PLUGIN|FCVAR_NOTIFY);
	armorregen_sniper = CreateConVar("sm_adarmor_sniper_armoregen", "6", "armor regen per second for sniper", FCVAR_PLUGIN|FCVAR_NOTIFY);
	armorregen_spy = CreateConVar("sm_adarmor_spy_armoregen", "7", "armor regen per second for spy", FCVAR_PLUGIN|FCVAR_NOTIFY);




	armor_from_metal = CreateConVar("sm_adarmor_metaltoarmor", "10", "converts metal, from engineer, to armor for teammates", FCVAR_PLUGIN|FCVAR_NOTIFY);

	armor_from_metal_mult = CreateConVar("sm_adarmor_metaltoarmor_mult", "5", "multiplies with sm_metaltoarmor to reduce metal cost to repair teammates armor, use in conjuction with sm_metaltoarmor", FCVAR_PLUGIN|FCVAR_NOTIFY);

	armor_from_smallammo = CreateConVar("sm_adarmor_smallammoarmor", "0.25", "give armor from small ammo packs by multiplying it with the players max armor they can get", FCVAR_PLUGIN|FCVAR_NOTIFY);

	armor_from_medammo = CreateConVar("sm_adarmor_medammoarmor", "0.50", "give armor from med ammo packs by multiplying it with the players max armor they can get", FCVAR_PLUGIN|FCVAR_NOTIFY);

	armor_from_fullammo = CreateConVar("sm_adarmor_fullammoarmor", "1.0", "give armor from full ammo packs by multiplying it with the players max armor they can get", FCVAR_PLUGIN|FCVAR_NOTIFY);

	spencer_to_armor = CreateConVar("sm_adarmor_dispenser_to_armor", "1", "gives x amount of armor from dispensers per rate from sm_adarmor_dispenser_time", FCVAR_PLUGIN|FCVAR_NOTIFY);

	spencer_time = CreateConVar("sm_adarmor_dispenser_time", "0.2", "amount of rate/time dispensers will give armor", FCVAR_PLUGIN|FCVAR_NOTIFY);

	//armor_from_widowmaker = CreateConVar("sm_armor_from_widowmaker", "1", "converts widowmaker dmg to armor", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	setarmormax = CreateConVar("sm_adarmor_setarmor_max", "999", "highest armor that admins can give armor to players", FCVAR_PLUGIN|FCVAR_NOTIFY);



	damage_resistance_type1 = CreateConVar("sm_adarmor_damage_resistance_light", "0.3", "how much damage should Light Armor absorb", FCVAR_PLUGIN|FCVAR_NOTIFY);
	damage_resistance_type2 = CreateConVar("sm_adarmor_damage_resistance_med", "0.6", "how much damage should Medium Armor absorb", FCVAR_PLUGIN|FCVAR_NOTIFY);
	damage_resistance_type3 = CreateConVar("sm_adarmor_damage_resistance_heavy", "0.8", "how much damage should Heavy Armor absorb", FCVAR_PLUGIN|FCVAR_NOTIFY);
	damage_resistance_chance = CreateConVar("sm_adarmor_damage_resistance_chance", "0.25", "how much damage should Luck Armor absorb", FCVAR_PLUGIN|FCVAR_NOTIFY);



	armortype_scout = CreateConVar("sm_adarmor_armortype_scout", "1", "ArmorType for Scout; Light(1), Medium(2), Heavy(3), Luck(4), Chance(5)", FCVAR_PLUGIN|FCVAR_NOTIFY);

	armortype_soldier = CreateConVar("sm_adarmor_armortype_soldier", "3", "Armor Type for Soldier; Light(1), Medium(2), Heavy(3), Luck(4), Chance(5)", FCVAR_PLUGIN|FCVAR_NOTIFY);

	armortype_pyro = CreateConVar("sm_adarmor_armortype_pyro", "2", "Armor Type for Pyro; Light(1), Medium(2), Heavy(3), Luck(4), Chance(5)", FCVAR_PLUGIN|FCVAR_NOTIFY);

	armortype_demo = CreateConVar("sm_adarmor_armortype_demo", "2", "Armor Type for Demoman; Light(1), Medium(2), Heavy(3), Luck(4), Chance(5)", FCVAR_PLUGIN|FCVAR_NOTIFY);

	armortype_heavy = CreateConVar("sm_adarmor_armortype_heavy", "3", "Armor Type for Heavy; Light(1), Medium(2), Heavy(3), Luck(4), Chance(5)", FCVAR_PLUGIN|FCVAR_NOTIFY);

	armortype_engie = CreateConVar("sm_adarmor_armortype_engie", "2", "Armor Type for Engineer; Light(1), Medium(2), Heavy(3), Luck(4), Chance(5)", FCVAR_PLUGIN|FCVAR_NOTIFY);

	armortype_med = CreateConVar("sm_adarmor_armortype_med", "2", "Armor Type for Medic; Light(1), Medium(2), Heavy(3), Luck(4), Chance(5)", FCVAR_PLUGIN|FCVAR_NOTIFY);

	armortype_sniper = CreateConVar("sm_adarmor_armortype_sniper", "1", "Armor Type for Sniper; Light(1), Medium(2), Heavy(3), Luck(4), Chance(5)", FCVAR_PLUGIN|FCVAR_NOTIFY);

	armortype_spy = CreateConVar("sm_adarmor_armortype_spy", "2", "Armor Type for Spy; Light(1), Medium(2), Heavy(3), Luck(4), Chance(5)", FCVAR_PLUGIN|FCVAR_NOTIFY);

	timer_bitch_convar = CreateConVar("sm_adarmor_advert_bitch", "60.0", "how many times the advert will bitch at players per second", FCVAR_PLUGIN|FCVAR_NOTIFY);

	//g_bEwSdkStarted = TF2_EwSdkStartup();

	HookEvent("player_death", EventPlayerDeath, EventHookMode_Pre);
	HookEvent("player_changeclass", EventChangeClass);
	HookEvent("player_spawn", EventPlayerSpawn);
	HookEvent("post_inventory_application", EventResupply);
	HookEvent("item_pickup", ItemPickedUp);
	AutoExecConfig(true, "Advanced_Armor");

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i)) continue;
		OnClientPutInServer(i);
	}
}
////////////////////////////////natives/forwards//////////////////////////////////////////////////
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("GetArmorType", Native_GetArmorType);
	CreateNative("SetArmorType", Native_SetArmorType);
	CreateNative("GetMaxArmor", Native_GetMaxArmor);
	CreateNative("SetMaxArmor", Native_SetMaxArmor);
	CreateNative("GetCurrentArmor", Native_GetCurrentArmor);
	CreateNative("SetCurrentArmor", Native_SetCurrentArmor);
	CreateNative("GetArmorDamageResistance", Native_GetArmorDamageResistance);
	CreateNative("SetArmorDamageResistance", Native_SetArmorDamageResistance);
	CreateNative("IsNearDispenser", Native_IsNearDispenser);
	CreateNative("ReadClientArmor", Native_ReadClientArmor);
	RegPluginLibrary("advanced_armor");

	return APLRes_Success;
}
public int Native_GetArmorType(Handle plugin, int numParams)
{
	return ArmorType[GetNativeCell(1)];
}
public int Native_SetArmorType(Handle plugin, int numParams)
{
	int client = GetNativeCell(1), type = GetNativeCell(2);
	if (IsValidClient(client)) ArmorType[client] = type;
}
public int Native_GetMaxArmor(Handle plugin, int numParams)
{
	return iMaxArmor[GetNativeCell(1)];
}
public int Native_SetMaxArmor(Handle plugin, int numParams)
{
	int client = GetNativeCell(1), maxarmor = GetNativeCell(2);
	if (IsValidClient(client)) iMaxArmor[client] = maxarmor;
}
public int Native_GetCurrentArmor(Handle plugin, int args)
{
	return iArmor[GetNativeCell(1)];
}
public int Native_SetCurrentArmor(Handle plugin, int numParams)
{
	int client = GetNativeCell(1), armount = GetNativeCell(2);
	if (IsValidClient(client)) iArmor[client] = armount;
}
public int Native_GetArmorDamageResistance(Handle plugin, int numParams)
{
	return view_as<int>(flDamageResistance[GetNativeCell(1)]);
}
public int Native_SetArmorDamageResistance(Handle plugin, int numParams)
{
	int client = GetNativeCell(1); float dmgfloat = view_as<float>(GetNativeCell(2));
	if (IsValidClient(client)) flDamageResistance[client] = dmgfloat;
}
public int Native_IsNearDispenser(Handle plugin, int numParams)
{
	return view_as<int>( IsNearSpencer(GetNativeCell(1)) );
}
public int Native_ReadClientArmor(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if (IsValidClient(client)) ReadArmor(GetClientUserId(client));
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public void OnConfigsExecuted()
{
	CreateTimer(timer_bitch_convar.FloatValue, Timer_Announce, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(GetRandomFloat(30.0, 60.0), Timer_DoBool, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}
public void OnClientDisconnect(int client)
{
	iMaxArmor[client] = 0;
	ArmorType[client] = Armor_None;
}
public void OnMapStart()
{
	char s[PLATFORM_MAX_PATH];
	PrecacheSound(SoundArmorAdd, true);
	PrecacheSound(SoundArmorLose, true);
	if (ArmorVoiceCvar.BoolValue)
	{
		for (int i = 1; i <= 20; i++)
		{
			Format(s, PLATFORM_MAX_PATH, "armorvoice/%i.wav", i);
			PrecacheSound(s, true);
			Format(s, PLATFORM_MAX_PATH, "sound/%s", s);
			AddFileToDownloadsTable(s);
		}
		for (int f = 30; f <= 90; f += 10)
		{
			Format(s, PLATFORM_MAX_PATH, "armorvoice/%i.wav", f);
			PrecacheSound(s, true);
			Format(s, PLATFORM_MAX_PATH, "sound/%s", s);
			AddFileToDownloadsTable(s);
		}
		Format(s, PLATFORM_MAX_PATH, "armorvoice/armor_gone.wav");
		PrecacheSound(s, true);
		Format(s, PLATFORM_MAX_PATH, "sound/%s", s);
		AddFileToDownloadsTable(s);

		Format(s, PLATFORM_MAX_PATH, "armorvoice/armor_level_is.wav");
		PrecacheSound(s, true);
		Format(s, PLATFORM_MAX_PATH, "sound/%s", s);
		AddFileToDownloadsTable(s);

		Format(s, PLATFORM_MAX_PATH, "armorvoice/hundred.wav");
		PrecacheSound(s, true);
		Format(s, PLATFORM_MAX_PATH, "sound/%s", s);
		AddFileToDownloadsTable(s);
	}
	CreateTimer(1.0, ArmorRegen, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(spencer_time.FloatValue, DispenserCheck, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}
public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_TraceAttack, TraceAttack);
	if ( HUD_PreThink.BoolValue ) SDKHook(client, SDKHook_PreThink, OnPreThink);
	else CreateTimer(0.2, DrawHud, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	if ( plugin_enable.BoolValue )
	{
		GetHUDColor(client);
		if (ArmorHUDColor[client][0] <= 0 && ArmorHUDColor[client][1] <= 0 && ArmorHUDColor[client][2] <= 0)
		{
			SetHUDColor(client, 255, 30, 90);
		}
		iArmor[client] = 0;
		iMaxArmor[client] = 0;
		ArmorType[client] = Armor_None;
	}
}
public Action VoiceTogglePanelCmd(int client, int args)
{
	if (!plugin_enable.BoolValue || !IsValidClient(client) || !ArmorVoiceCvar.BoolValue) return Plugin_Continue;
	VoiceTogglePanel(client);
	return Plugin_Handled;
}
public Action VoiceTogglePanel(int client)
{
	if (!IsValidClient(client)) return Plugin_Continue;
	Panel panel = new Panel();
	panel.SetTitle("Turn the Advanced Armor voice...");
	panel.DrawItem("On");
	panel.DrawItem("Off");
	panel.Send(client, VoiceTogglePanelH, 9001);
	panel.Close();
	return Plugin_Continue;
}
public int VoiceTogglePanelH(Menu menu, MenuAction action, int client, int param2)
{
	if (IsValidClient(client))
	{
		if (action == MenuAction_Select)
		{
			switch (param2)
			{
				case 1:
				{
					SetVoiceSetting(client, true);
					CPrintToChat(client, "{red}[Ad-Armor]{default} You've turned the Armor Voice On");
				}
				case 2:
				{
					SetVoiceSetting(client, false);
					CPrintToChat(client, "{red}[Ad-Armor]{default} You've turned the Armor Voice Off");
				}
			}
		}
	}
}
public bool GetVoiceSetting(int client)
{
	if (!AreClientCookiesCached(client)) return true;
	char strCookie[4]; GetClientCookie(client, VoiceCookie, strCookie, sizeof(strCookie));
	if ( !strCookie[0] ) return true;
	else return view_as<bool>(StringToInt(strCookie));
}
public void SetVoiceSetting(int client, bool on)
{
	if ( !IsValidClient(client) || IsFakeClient(client) || !AreClientCookiesCached(client) ) return;
	char strCookie[4];
	if (on) strCookie = "1";
	else strCookie = "0";
	SetClientCookie(client, VoiceCookie, strCookie);
}
public int GetHUDSetting(int client)
{
	if (AreClientCookiesCached(client))
	{
		char hudpick[4];
		GetClientCookie(client, HUDCookie, hudpick, sizeof(hudpick));
		return StringToInt(hudpick);
	}
	return 0; //default setting
}
public void SetHUDSetting(int client, int option)
{
	if ( !IsValidClient(client) || IsFakeClient(client) || !AreClientCookiesCached(client) ) return;
	char hudpick[4];
	IntToString(option, hudpick, sizeof(hudpick));
	SetClientCookie(client, HUDCookie, hudpick);
}
public void GetHUDParams(int client)
{
	if (AreClientCookiesCached(client))
	{
		char hudparams[6];

		GetClientCookie(client, HUDParamsCookieX, hudparams, sizeof(hudparams));
		flArmorHUDParams[client][0] = StringToFloat(hudparams);

		GetClientCookie(client, HUDParamsCookieY, hudparams, sizeof(hudparams));
		flArmorHUDParams[client][1] = StringToFloat(hudparams);
	}
}
public void SetHUDParams(int client, float x, float y)
{
	char string[6];

	FloatToString(x, string, sizeof(string));
	SetClientCookie(client, HUDParamsCookieX, string);

	FloatToString(y, string, sizeof(string));
	SetClientCookie(client, HUDParamsCookieY, string);
}
public void GetHUDColor(int client)
{
	if (AreClientCookiesCached(client))
	{
		char getcolor[6];

		GetClientCookie( client, RedCookie, getcolor, sizeof(getcolor) );
		ArmorHUDColor[client][0] = StringToInt(getcolor);

		GetClientCookie( client, GreenCookie, getcolor, sizeof(getcolor) );
		ArmorHUDColor[client][1] = StringToInt(getcolor);

		GetClientCookie( client, BlueCookie, getcolor, sizeof(getcolor) );
		ArmorHUDColor[client][2] = StringToInt(getcolor);
	}
}
public void SetHUDColor(int client, int r, int g, int b)
{
	char lecolor[6];
	IntToString(r, lecolor, sizeof(lecolor));
	SetClientCookie(client, RedCookie, lecolor);

	IntToString(g, lecolor, sizeof(lecolor));
	SetClientCookie(client, GreenCookie, lecolor);

	IntToString(b, lecolor, sizeof(lecolor));
	SetClientCookie(client, BlueCookie, lecolor);
}
public Action EventPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if ( !plugin_enable.BoolValue ) return Plugin_Continue;
	int client = GetClientOfUserId( event.GetInt("userid") );
	if ( client && IsClientInGame(client) )
	{
		iArmor[client] = 0;
		bArmorOverheal[client] = false;
		GetMaxArmor(client);
		if (!bArmorEquipped[client]) return Plugin_Continue;
		if (ArmorType[client] == Armor_None) GetArmorType(client);
		GetDamageResistanceArmor(client);

		if ( (!cvBlu.BoolValue && GetClientTeam(client) == 3) || (!cvRed.BoolValue && GetClientTeam(client) == 2) )
			return Plugin_Continue;

		if (!armor_bots_allow.BoolValue && IsFakeClient(client) && IsClientInGame(client)) return Plugin_Continue;

		switch (armorspawn.IntValue)
		{
			case 0: iArmor[client] = 0;
			case 1: iArmor[client] = iMaxArmor[client];
			case 2: iArmor[client] = iMaxArmor[client]/2;
		}
		if (ArmorVoiceCvar.BoolValue) ArmorVoice[client] = GetVoiceSetting(client);
	}
	return Plugin_Continue;
}
public Action EventChangeClass(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId( event.GetInt("userid") );
	if (plugin_enable.BoolValue)
	{
		iArmor[client] = 0;
		bArmorOverheal[client] = false;
		if (ArmorVoiceCvar.BoolValue) ArmorVoice[client] = GetVoiceSetting(client);
	}
	return Plugin_Continue;
}
public Action EventPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (!plugin_enable.BoolValue) return Plugin_Continue;

	int client = GetClientOfUserId( event.GetInt("userid") );
	int deathflags = event.GetInt("death_flags");
	if ( client && IsClientInGame(client) && !(deathflags & TF_DEATHFLAG_DEADRINGER) )
	{
		bArmorOverheal[client] = false;
		iArmor[client] = 0;
		iMaxArmor[client] = 0;
		ArmorType[client] = Armor_None;
		flDamageResistance[client] = 0.0;
	}

	return Plugin_Continue;
}
public Action CmdReloadCFG(int client, int iAction)
{
	ServerCommand("sm_rcon exec sourcemod/advanced_armor.cfg");
	for (int i = 1; i <= MaxClients; i++)
	{
		if ( IsValidClient(i) )
		{
			GetMaxArmor(i);
			GetArmorType(i);
		}
	}
	ReplyToCommand(client, "**** Reloading Armor Config ****");
	return Plugin_Handled;
}
public Action CmdEnable(int client, int iAction)
{
	if (IsValidClient(client)) bArmorEquipped[client] = true;
	ReplyToCommand(client, "**** Equipping Armor ****");
	GetMaxArmor(client);
	return Plugin_Handled;
}
public Action CmdDisable(int client, int iAction)
{
	if (IsValidClient(client)) bArmorEquipped[client] = false;
	ReplyToCommand(client, "**** Unequipping Armor ****");
	return Plugin_Handled;
}

public Action Listener_Voice(int client, const char[] command, int argc)
{
	if ( !ArmorVoiceCvar.BoolValue ) return Plugin_Continue;
	if ( !IsValidClient(client) || !ArmorVoice[client] ) return Plugin_Continue;

	char arguments[4]; GetCmdArgString(arguments, sizeof(arguments));

	if ( StrEqual(arguments, "0 0") && !bMedicButtonBool[client] ) bMedicButtonBool[client] = true;

	else if ( StrEqual(arguments, "0 0") && bMedicButtonBool[client] )
	{
		CreateTimer(0.0, Timer_ReadArmorVoice, client);
		bMedicButtonBool[client] = false;
	}
	return Plugin_Continue;
}

public void OnPreThink(int client) //powers the HUD
{
	if ( !HUD_PreThink.BoolValue ) return;
	if ( (!cvBlu.BoolValue && GetClientTeam(client) == 3) || (!cvRed.BoolValue && GetClientTeam(client) == 2) ) return;
	if ( IsFakeClient(client) && IsValidClient(client) ) return;
	UpdateHUD(client);
	return;
}
public Action DrawHud(Handle timer, any userid)
{
	if ( HUD_PreThink.BoolValue ) return Plugin_Handled;
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client) || (IsFakeClient(client) && IsClientInGame(client))) return Plugin_Stop;

	if ( (!cvBlu.BoolValue && GetClientTeam(client) == 3) || (!cvRed.BoolValue && GetClientTeam(client) == 2) )
		return Plugin_Handled;

	UpdateHUD(client);
	return Plugin_Continue;
}
public Action ArmorRegen(Handle timer) 
{
	if (!plugin_enable.BoolValue || !armorregen.BoolValue) return Plugin_Continue;

	for (int client = 1; client <= MaxClients; client++)
	{
		if ( !IsValidClient(client) || !IsPlayerAlive(client) ) continue;
		if ( (!cvBlu.BoolValue && GetClientTeam(client) == 3) || (!cvRed.BoolValue && GetClientTeam(client) == 2) )
			continue;

		if (!armor_bots_allow.BoolValue && IsFakeClient(client) && IsClientInGame(client)) continue;
		if (!bArmorEquipped[client]) continue;

		GetArmorRegen(client);
		if ( iMaxArmor[client] - iArmor[client] < iArmorRegenerate[client] ) {
			iArmorRegenerate[client] = iMaxArmor[client] - iArmor[client];
		}
		if ( iArmor[client] < iMaxArmor[client] ) iArmor[client] += iArmorRegenerate[client];

		if ( iArmor[client] > iMaxArmor[client] && !bArmorOverheal[client] ) iArmor[client] = iMaxArmor[client];
	}
	return Plugin_Continue;
}
public Action DispenserCheck(Handle timer)
{
	if ( !plugin_enable.BoolValue || !armor_from_spencer.BoolValue ) return Plugin_Continue;

	for (int client = 1; client <= MaxClients; client++)
	{
		if ( !IsValidClient(client) || !IsPlayerAlive(client) ) continue;
		if ( (!cvBlu.BoolValue && GetClientTeam(client) == 3) || (!cvRed.BoolValue && GetClientTeam(client) == 2) )
			continue;

		if (!armor_bots_allow.BoolValue && IsFakeClient(client) && IsClientInGame(client)) continue;
		if (!bArmorEquipped[client]) continue;

		int cond = GetEntProp(client, Prop_Send, "m_nPlayerCond");
		if (IsNearSpencer(client) && !(cond & 21)) //IDK why, but this glitches by giving medics armor during quickfix ubers.
		{
			int lvl = GetDispenserLevel();
			int spencerrepair = spencer_to_armor.IntValue;
			switch (lvl)
			{
				case 1: spencerrepair += RoundFloat(spencerrepair*level1.FloatValue);
				case 2: spencerrepair += RoundFloat(spencerrepair*level2.FloatValue);
				case 3: spencerrepair += RoundFloat(spencerrepair*level3.FloatValue);
			}
			if (iMaxArmor[client]-iArmor[client] < spencerrepair)
				spencerrepair = (iMaxArmor[client]-iArmor[client]);

			if (iArmor[client] < iMaxArmor[client])
			{
				iArmor[client] += spencerrepair;
				if ( armor_snd_allow.BoolValue ) EmitSoundToClient(client, SoundArmorAdd);
			}

			if (iArmor[client] > iMaxArmor[client] && !bArmorOverheal[client])
				iArmor[client] = iMaxArmor[client];
		}
	}
	return Plugin_Continue;
}
public Action Command_SetPlayerHUD(int client, int args)
{
	if (plugin_enable.BoolValue)
	{
		Menu HUDMenu = new Menu(MenuHandler_SetHud);
		HUDMenu.SetTitle("Advanced Armor - Current Armor HUD: %i", GetHUDSetting(client));
		HUDMenu.AddItem("gnric", "Generic FPS Style - Example: 'Armor:#/iMaxArmor:#'");
		HUDMenu.AddItem("doom", "DOOM Style - Example: 'Armor:#/#'");
		HUDMenu.AddItem("tfc", "TFC/Quake Style - Example: 'Armor:#'");
		HUDMenu.AddItem("lame", "New Style - Example: 'Armor:(#) | Max Armor:(#)'");
		HUDMenu.Display(client, MENU_TIME_FOREVER);
	}
	return Plugin_Handled;
}
public int MenuHandler_SetHud(Menu menu, MenuAction action, int client, int setter)
{
	char hudslct[64];
	menu.GetItem(setter, hudslct, sizeof(hudslct));
	if (action == MenuAction_Select) SetHUDSetting(client, setter+1);
	else if (action == MenuAction_End) delete menu;
}
public Action Command_SetPlayerArmor(int client, int args) //THIS INTENTIONALLY OVERRIDES TEAM RESTRICTIONS ON ARMOR
{
	if (plugin_enable.BoolValue)
	{
		if (args < 2)
		{
			ReplyToCommand(client, "[Ad-Armor] Usage: sm_setarmor <target> <0-%i>", setarmormax.IntValue);
			return Plugin_Handled;
		}
		char targetname[64], number[9];
		GetCmdArg(1, targetname, sizeof(targetname));
		GetCmdArg(2, number, sizeof(number));
		int armorsize = StringToInt(number);
		if (armorsize < 0 || armorsize > setarmormax.IntValue)
		{
			ReplyToCommand(client, "[Ad-Armor] Usage: sm_setarmor <target> <0-%i>", setarmormax.IntValue);
			return Plugin_Handled;
		}
		char target_name[MAX_TARGET_LENGTH];
		int target_list[PLYR], target_count;
		bool tn_is_ml;
		if ((target_count = ProcessTargetString(
				targetname,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_ALIVE,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			/* This function replies to the admin with a failure message */
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		for (int i = 0; i < target_count; i++)
		{
			if ( (armorsize >= 0 && armorsize <= setarmormax.IntValue) && IsValidClient(target_list[i]) )
			{
				//GetMaxArmor(target_list[i]);
				iArmor[target_list[i]] = armorsize;
				bArmorOverheal[target_list[i]] = (armorsize > iMaxArmor[target_list[i]]) ? true : false;
				CPrintToChat(target_list[i], "{red}[Ad-Armor]{default} You've been given {green}%i{default} Armor", armorsize);
			}
		}
	}
	return Plugin_Continue;
}
public Action Command_SetHudParams(int client, int args)
{
	if (plugin_enable.BoolValue && allow_hud_change.BoolValue)
	{
		if (args < 2)
		{
			ReplyToCommand(client, "[Ad-Armor] Usage: sm_armorhudparams <x> <y>", setarmormax.IntValue);
			return Plugin_Handled;
		}
		char numberx[10], numbery[10];
		GetCmdArg(1, numberx, sizeof(numberx));
		GetCmdArg(2, numbery, sizeof(numbery));

		float params[2];
		params[0] = StringToFloat(numberx);
		params[1] = StringToFloat(numbery);
		for (int o = 0; o < 2; o++) { flArmorHUDParams[client][o] = params[o]; }

		SetHUDParams(client, flArmorHUDParams[client][0], flArmorHUDParams[client][1]);
		PrintToChat(client, "[Ad-Armor] You've changed your Armor HUD Parameters");
	}
	return Plugin_Continue;
}
public Action Command_SetHudColor(int client, int args)
{
	if (plugin_enable.BoolValue && allow_hud_color.BoolValue)
	{
		if (args < 3)
		{
			ReplyToCommand(client, "[Ad-Armor] Usage: sm_armorhudcolor <red: 0-255> <green: 0-255> <blue: 0-255>", setarmormax.IntValue);
			return Plugin_Handled;
		}
		char red[5], green[5], blue[5];
		GetCmdArg(1, red, sizeof(red));
		GetCmdArg(2, green, sizeof(green));
		GetCmdArg(3, blue, sizeof(blue));
		int params[3];
		params[0] = StringToInt(red);
		params[1] = StringToInt(green);
		params[2] = StringToInt(blue);
		for (int a=0; a < 3; a++) { ArmorHUDColor[client][a] = params[a]; }
		SetHUDColor( client, ArmorHUDColor[client][0], ArmorHUDColor[client][1], ArmorHUDColor[client][2] );

		PrintToChat( client, "[Ad-Armor] You've changed your Armor HUD Color" );
	}
	return Plugin_Continue;
}
public Action ItemPickedUp(Event event, const char[] name, bool dontBroadcast)
{
	if (!plugin_enable.BoolValue || !armor_ammo_allow.BoolValue) return Plugin_Continue;

	int client = GetClientOfUserId( event.GetInt("userid") );

	if ( !IsValidClient(client) ) return Plugin_Continue;
	if ( (!cvBlu.BoolValue && GetClientTeam(client) == 3) || (!cvRed.BoolValue && GetClientTeam(client) == 2) )
	{
		return Plugin_Continue;
	}
	if (!armor_ammo_allow.BoolValue && IsFakeClient(client) && IsClientInGame(client)) return Plugin_Continue;
	if (!bArmorEquipped[client]) return Plugin_Continue;

	char item[32]; event.GetString("item", item, sizeof(item));
	int pack = 0;
	if ( StrEqual(item, "item_ammopack_full") ) pack = RoundFloat( iMaxArmor[client]*armor_from_fullammo.FloatValue );
	else if ( StrEqual(item, "item_ammopack_medium") ) pack = RoundFloat( iMaxArmor[client]*armor_from_medammo.FloatValue );
	else if ( StrEqual(item, "item_ammopack_small") ) pack = RoundFloat( iMaxArmor[client]*armor_from_smallammo.FloatValue );

	if ( iMaxArmor[client] - iArmor[client] < pack ) pack = iMaxArmor[client] - iArmor[client];
	if ( iArmor[client] < iMaxArmor[client] )
	{
		iArmor[client] += pack;
		if ( armor_snd_allow.BoolValue ) EmitSoundToClient(client, SoundArmorAdd);
	}
	if ( iArmor[client] > iMaxArmor[client] && !bArmorOverheal[client] ) iArmor[client] = iMaxArmor[client];

	return Plugin_Continue;
}
public Action EventResupply(Event event, const char[] name, bool dontBroadcast)
{
	if (!plugin_enable.BoolValue) return Plugin_Continue;
	int client = GetClientOfUserId( event.GetInt("userid") );
	if (client && IsClientInGame(client))
	{
		if ( (!cvBlu.BoolValue && GetClientTeam(client) == 3) || (!cvRed.BoolValue && GetClientTeam(client) == 2) )
			return Plugin_Continue;

		if (!armor_bots_allow.BoolValue && IsFakeClient(client) && IsClientInGame(client))
			 return Plugin_Continue;

		if (!bArmorEquipped[client]) return Plugin_Continue;
		//GetMaxArmor(activator);
		iArmor[client] = iMaxArmor[client];
	}
	return Plugin_Continue;
}
public Action TraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if (plugin_enable.BoolValue && IsValidClient(attacker) && IsValidClient(victim))
	{
		if (GetClientTeam(attacker) == GetClientTeam(victim))
		{
			if (TF2_GetPlayerClass(attacker) == TFClass_Engineer && armor_from_engie.BoolValue) //props to robin walker for engie armor fix code
			{
				if ( (!cvBlu.BoolValue && GetClientTeam(victim) == 3) || (!cvRed.BoolValue && GetClientTeam(victim) == 2) ) return Plugin_Handled;

				if (!armor_bots_allow.BoolValue && IsFakeClient(victim) && IsClientInGame(victim)) return Plugin_Handled;
				if (!bArmorEquipped[victim]) return Plugin_Handled;

				//GetMaxArmor(victim);
				int iCurrentMetal = GetEntProp(attacker, Prop_Data, "m_iAmmo", 4, 3);
				int repairamount = armor_from_metal.IntValue; //default 10
				int mult = armor_from_metal_mult.IntValue; //default 5

				int hClientWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
				//new wepindex = (IsValidEdict(hClientWeapon) && GetEntProp(hClientWeapon, Prop_Send, "m_iItemDefinitionIndex"));
				char classname[64];
				if (IsValidEdict(hClientWeapon)) GetEdictClassname(hClientWeapon, classname, sizeof(classname));
				
				if (StrEqual(classname, "tf_weapon_wrench", false) || StrEqual(classname, "tf_weapon_robot_arm", false))
				{
					if (iArmor[victim] >= 0 && iArmor[victim] < iMaxArmor[victim])
					{
						if (iCurrentMetal < repairamount) repairamount = iCurrentMetal;

						if (iMaxArmor[victim] - iArmor[victim] < repairamount*mult)/*becomes 50 by default*/
						{
							repairamount = RoundToCeil(float((iMaxArmor[victim] - iArmor[victim]) / mult));
						}
						if (repairamount < 1 && iCurrentMetal > 0) repairamount = 1;

						iArmor[victim] += repairamount*mult;

						if (iArmor[victim] > iMaxArmor[victim]) iArmor[victim] = iMaxArmor[victim];

						iCurrentMetal -= repairamount;
						SetEntProp(attacker, Prop_Data, "m_iAmmo", iCurrentMetal, 4, 3);
						if (armor_snd_allow.BoolValue)
						{
							EmitSoundToClient(victim, SoundArmorAdd);
							EmitSoundToClient(attacker, SoundArmorAdd);
						}
						if (ArmorVoice[victim] && ArmorVoiceAuto[victim] && ArmorVoiceCvar.BoolValue)
						{
							CreateTimer(GetRandomFloat(3.0, 4.0), Timer_ReadArmorVoice, victim);
							ArmorVoiceAuto[victim] = false;
						}
					}
				}
			}
		}
		else return Plugin_Continue;
	}
	return Plugin_Continue;
}
public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (plugin_enable.BoolValue && IsValidClient(attacker) && IsValidClient(victim))
	{
		if ( (victim == attacker && !allow_self_hurt.BoolValue) || (allow_crit_pierce.BoolValue && (damagetype & DMG_CRIT)) )
		{
			return Plugin_Continue; //prevents soldiers/demos from destroying their own armor but also allows crits to pierce through iArmor.
		}
		if ( !allow_uber_damage.BoolValue && (TF2_IsPlayerInCondition(victim, TFCond_Ubercharged) || TF2_IsPlayerInCondition(victim, TFCond_Bonked)) )
		{
			return Plugin_Continue; //prevent ubered players from losing iArmor
		}
		if ( iArmor[victim] >= 1 && ArmorType[victim] != Armor_None && GetClientTeam(attacker) != GetClientTeam(victim) )
		{
			if ( ArmorType[victim] == Armor_Chance ) //life iArmor
			{
				if ( damage > GetClientHealth(victim) )
				{
					if (GetRandomFloat(1.0, 10.0) > life_armor_chance.FloatValue) damage = float(iArmor[victim]);
				}
			}
			if ( allow_self_hurt.BoolValue ) ScaleVector(damageForce, 2.0);
			float intdamage = flDamageResistance[victim]*damage;
			iArmor[victim] -= RoundFloat(intdamage); //subtract iArmor
			if ( armor_snd_allow.BoolValue ) EmitSoundToClient(victim, SoundArmorLose);
			if (iArmor[victim] < 1) //if armor goes under 1, transfer rest of unabsorbed damage to health.
			{
				if ( allow_damage_overwhelm.BoolValue ) intdamage += iArmor[victim];
				iArmor[victim] = 0;
			}
			damage -= intdamage;
			if ( ArmorVoice[victim] && ArmorVoiceAuto[victim] && ArmorVoiceCvar.BoolValue )
			{
				CreateTimer(GetRandomFloat(3.0, 4.0), Timer_ReadArmorVoice, GetClientUserId(victim));
				ArmorVoiceAuto[victim] = false;
			}
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}
void GetMaxArmor(int client)
{
	TFClassType maxarmor = TF2_GetPlayerClass(client);
	switch (maxarmor)
	{
		case TFClass_Scout:	iMaxArmor[client] = maxarmor_scout.IntValue;
		case TFClass_Soldier:	iMaxArmor[client] = maxarmor_soldier.IntValue;
		case TFClass_Pyro:	iMaxArmor[client] = maxarmor_pyro.IntValue;
		case TFClass_DemoMan:	iMaxArmor[client] = maxarmor_demo.IntValue;
		case TFClass_Heavy:	iMaxArmor[client] = maxarmor_heavy.IntValue;
		case TFClass_Engineer:	iMaxArmor[client] = maxarmor_engie.IntValue;
		case TFClass_Medic:	iMaxArmor[client] = maxarmor_med.IntValue;
		case TFClass_Sniper:	iMaxArmor[client] = maxarmor_sniper.IntValue;
		case TFClass_Spy:	iMaxArmor[client] = maxarmor_spy.IntValue;
	}
}
void GetDamageResistanceArmor(int client)
{
	int dmgresist = ArmorType[client];
	switch (dmgresist)
	{
		case Armor_Light:	flDamageResistance[client] = damage_resistance_type1.FloatValue; //default 0.3
		case Armor_Medium:	flDamageResistance[client] = damage_resistance_type2.FloatValue; //default 0.6
		case Armor_Heavy:	flDamageResistance[client] = damage_resistance_type3.FloatValue; //default 0.8
		case Armor_Luck:
		{
			int chance = GetRandomInt(1, 10);
			flDamageResistance[client] = (chance > luck_armor_chance.IntValue) ? damage_resistance_chance.FloatValue : 0.0;
			//default 0.25
		}
		case Armor_Chance:	flDamageResistance[client] = 1.0;
		default:		flDamageResistance[client] = flDamageResistance[client];
	}
}
void GetArmorType(int client)
{
	TFClassType armortype = TF2_GetPlayerClass(client);
	switch (armortype)
	{
		case TFClass_Scout:	ArmorType[client] = armortype_scout.IntValue;
		case TFClass_Soldier:	ArmorType[client] = armortype_soldier.IntValue;
		case TFClass_Pyro:	ArmorType[client] = armortype_pyro.IntValue;
		case TFClass_DemoMan:	ArmorType[client] = armortype_demo.IntValue;
		case TFClass_Heavy:	ArmorType[client] = armortype_heavy.IntValue;
		case TFClass_Engineer:	ArmorType[client] = armortype_engie.IntValue;
		case TFClass_Medic:	ArmorType[client] = armortype_med.IntValue;
		case TFClass_Sniper:	ArmorType[client] = armortype_sniper.IntValue;
		case TFClass_Spy:	ArmorType[client] = armortype_spy.IntValue;
	}
}
void GetArmorRegen(int client)
{
	TFClassType regen = TF2_GetPlayerClass(client);
	switch (regen)
	{
		case TFClass_Scout:	iArmorRegenerate[client] = armorregen_scout.IntValue;
		case TFClass_Soldier:	iArmorRegenerate[client] = armorregen_soldier.IntValue;
		case TFClass_Pyro:	iArmorRegenerate[client] = armorregen_pyro.IntValue;
		case TFClass_DemoMan:	iArmorRegenerate[client] = armorregen_demo.IntValue;
		case TFClass_Heavy:	iArmorRegenerate[client] = armorregen_heavy.IntValue;
		case TFClass_Engineer:	iArmorRegenerate[client] = armorregen_engie.IntValue;
		case TFClass_Medic:	iArmorRegenerate[client] = armorregen_med.IntValue;
		case TFClass_Sniper:	iArmorRegenerate[client] = armorregen_sniper.IntValue;
		case TFClass_Spy:	iArmorRegenerate[client] = armorregen_spy.IntValue;
	}
}
void GetClassHealth(int client)
{
	TFClassType healthabove = TF2_GetPlayerClass(client);
	int max = GetEntProp(client, Prop_Data, "m_iMaxHealth");
	switch (healthabove)
	{
		case TFClass_Scout:	bArmorEquipped[client] = (max > 75) ? false : true;
		case TFClass_Soldier:	bArmorEquipped[client] = (max > 100) ? false : true;
		case TFClass_Pyro:	bArmorEquipped[client] = (max > 100) ? false : true;
		case TFClass_DemoMan:	bArmorEquipped[client] = (max > 90) ? false : true;
		case TFClass_Heavy:	bArmorEquipped[client] = (max > 100) ? false : true;
		case TFClass_Engineer:	bArmorEquipped[client] = (max > 60) ? false : true;
		case TFClass_Medic:	bArmorEquipped[client] = (max > 90) ? false : true;
		case TFClass_Sniper:	bArmorEquipped[client] = (max > 90) ? false : true;
		case TFClass_Spy:	bArmorEquipped[client] = (max > 90) ? false : true;
	}
}
public Action Timer_DoBool(Handle hTimer, any client)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if ( IsValidClient(i) ) ArmorVoiceAuto[i] = true;
	}
	return Plugin_Continue;
}
public Action Timer_ReadArmorVoice(Handle hTimer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (IsValidClient(client)) ReadArmor(userid);
	return Plugin_Continue;
}

char sentence[PLATFORM_MAX_PATH]; //256

public ReadArmor(int userid) //only "reads" up to 999. To make it read 1000+ You gotta do "10" "hundred" xD
{
	if (!plugin_enable.BoolValue) return;

	int client = GetClientOfUserId(userid);
	if ( !IsValidClient(client) ) return;

	float convert;
	int tenths, hundredth, units;
	if ( IsPlayerAlive(client) )
	{
		int read = iArmor[client]; float readout = float(iArmor[client]);
		if (read <= 0)
		{
			strcopy(sentence, PLATFORM_MAX_PATH, "armorvoice/armor_gone.wav");
			PlayAudioSequence(client, sentence, 2.0);
		}
		if (read >= 100)
		{
			EmitSoundToClient(client, "armorvoice/armor_level_is.wav");
			hundredth = RoundToFloor(readout/100);
			Format(sentence, PLATFORM_MAX_PATH, "armorvoice/%i.wav", hundredth);
			PlayAudioSequence(client, sentence, 2.0);
			Format(sentence, PLATFORM_MAX_PATH, "armorvoice/hundred.wav");
			PlayAudioSequence(client, sentence, 3.0);

			tenths = RoundFloat(GetTensValue(readout));
			if (tenths > 20)
			{
				convert = float(tenths);
				tenths = RoundFloat(RoundToDecimal(convert));
				Format(sentence, PLATFORM_MAX_PATH, "armorvoice/%i.wav", tenths);
				PlayAudioSequence(client, sentence, 4.0);
				convert /= 10.0;
				units = RoundFloat(FloatFraction(convert)*10);
				Format(sentence, PLATFORM_MAX_PATH, "armorvoice/%i.wav", units);
				PlayAudioSequence(client, sentence, 5.0);
			}
			else
			{
				Format(sentence, PLATFORM_MAX_PATH, "armorvoice/%i.wav", tenths);
				PlayAudioSequence(client, sentence, 4.0);
			}
		}
		else if (read < 100 && read > 21)
		{
			EmitSoundToClient(client, "armorvoice/armor_level_is.wav");
			tenths = RoundToFloor(GetTensValue(readout));
			if (tenths >= 21)
			{
				convert = float(tenths);
				tenths = RoundFloat(RoundToDecimal(convert));
				Format(sentence, PLATFORM_MAX_PATH, "armorvoice/%i.wav", tenths);
				PlayAudioSequence(client, sentence, 2.0);
				convert /= 10.0;

				units = RoundFloat(FloatFraction(convert)*10);
				Format(sentence, PLATFORM_MAX_PATH, "armorvoice/%i.wav", units);
				PlayAudioSequence(client, sentence, 3.0);
			}
			else
			{
				Format(sentence, PLATFORM_MAX_PATH, "armorvoice/%i.wav", tenths);
				PlayAudioSequence(client, sentence, 2.0);
			}
		}
		else if (read <= 20)
		{
			EmitSoundToClient(client, "armorvoice/armor_level_is.wav");
			Format(sentence, PLATFORM_MAX_PATH, "armorvoice/%i.wav", read);
			PlayAudioSequence(client, sentence, 2.0);
		}
	}
	else
	{
		int spec = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
		if (IsValidClient(spec) && IsPlayerAlive(spec) && spec != client)
		{
			int read = iArmor[spec]; float readout = float(iArmor[spec]);
			if (read <= 0)
			{
				strcopy(sentence, PLATFORM_MAX_PATH, "armorvoice/armor_gone.wav");
				PlayAudioSequence(client, sentence, 2.0);
			}
			if (read >= 100)
			{
				EmitSoundToClient(client, "armorvoice/armor_level_is.wav");
				hundredth = RoundToFloor(readout/100);
				Format(sentence, PLATFORM_MAX_PATH, "armorvoice/%i.wav", hundredth);
				PlayAudioSequence(client, sentence, 2.0);
				Format(sentence, PLATFORM_MAX_PATH, "armorvoice/hundred.wav");
				PlayAudioSequence(client, sentence, 3.0);

				tenths = RoundFloat(GetTensValue(readout));
				if (tenths > 20)
				{
					convert = float(tenths);
					tenths = RoundFloat(RoundToDecimal(convert));
					Format(sentence, PLATFORM_MAX_PATH, "armorvoice/%i.wav", tenths);
					PlayAudioSequence(client, sentence, 4.0);
					convert /= 10.0;

					units = RoundFloat(FloatFraction(convert)*10);
					PrintToConsole(client, "[Ad-Armor-Test] units = %i, convert = %f", units, convert);
					Format(sentence, PLATFORM_MAX_PATH, "armorvoice/%i.wav", units);
					PlayAudioSequence(client, sentence, 5.0);
				}
				else
				{
					Format(sentence, PLATFORM_MAX_PATH, "armorvoice/%i.wav", tenths);
					PlayAudioSequence(client, sentence, 4.0);
				}
			}
			else if (read < 100 && read > 21)
			{
				EmitSoundToClient(client, "armorvoice/armor_level_is.wav");
				tenths = RoundToFloor(GetTensValue(readout));
				if (tenths >= 21)
				{
					convert = float(tenths);
					tenths = RoundFloat(RoundToDecimal(convert));
					Format(sentence, PLATFORM_MAX_PATH, "armorvoice/%i.wav", tenths);
					PlayAudioSequence(client, sentence, 2.0);
					convert /= 10.0;

					units = RoundFloat(FloatFraction(convert)*10);
					Format(sentence, PLATFORM_MAX_PATH, "armorvoice/%i.wav", units);
					PlayAudioSequence(client, sentence, 3.0);
				}
				else
				{
					Format(sentence, PLATFORM_MAX_PATH, "armorvoice/%i.wav", tenths);
					PlayAudioSequence(client, sentence, 2.0);
				}
			}
			else if (read <= 20)
			{
				EmitSoundToClient(client, "armorvoice/armor_level_is.wav");
				Format(sentence, PLATFORM_MAX_PATH, "armorvoice/%i.wav", read);
				PlayAudioSequence(client, sentence, 2.0);
			}
		}
	}
}
public void PlayAudioSequence(int client, char[] sound, float delay)
{
	if ( IsValidClient(client) )
	{
		DataPack SndPack = new DataPack();
		SndPack.WriteString(sound);
		SndPack.WriteCell(client);
		CreateTimer(delay, TimerPlaySound, SndPack, TIMER_DATA_HNDL_CLOSE);
	}
}
public Action TimerPlaySound(Handle hTimer, DataPack pack)
{
	pack.Reset();
	char sound[64]; pack.ReadString(sound, sizeof(sound));
	int client = pack.ReadCell();
	if ( IsValidClient(client) ) EmitSoundToClient(client, sound, _, _, SNDLEVEL_AIRCRAFT);
	return Plugin_Continue;
}
public Action ArmorHelp(int client, int args)
{
	if (!plugin_enable.BoolValue)
	{
		ReplyToCommand(client, "[Ad-Armor]{green} Advanced Armor is turned {red}off");
		return Plugin_Handled;
	}
        if (IsClientInGame(client))
        {
		Menu armorhalp = new Menu(MenuHandler_armorhalp);
		armorhalp.SetTitle("Armor Help - Main Menu:");
		armorhalp.AddItem("armrtype", "What's my Armor type?");
		armorhalp.AddItem("cmds", "What are the Available Commands?");
		//armorhalp.AddItem("", "");
		armorhalp.ExitButton = true;
		armorhalp.Display(client, MENU_TIME_FOREVER);
        }
        return Plugin_Handled;
}
public MenuHandler_armorhalp(Menu menu, MenuAction action, int client, int param2)
{
	char armar[32], arg[32];
	menu.GetItem(param2, arg, sizeof(arg));
	if (action == MenuAction_Select)
        {
		switch (param2)
		{
			case 0:
			{
				float resist;
				int name = ArmorType[client];
				switch (name)
				{
					case Armor_None:
					{
						armar = "None";
						resist = 0.0;
					}
					case Armor_Light:
					{
						armar = "Light Armor";
						resist = GetConVarFloat(damage_resistance_type1);
					}
					case Armor_Medium:
					{
						armar = "Medium Armor";
						resist = GetConVarFloat(damage_resistance_type2);
					}
					case Armor_Heavy:
					{
						armar = "Heavy Armor";
						resist = GetConVarFloat(damage_resistance_type3);
					}
					case Armor_Luck:
					{
						armar = "Luck Armor";
						resist = GetConVarFloat(damage_resistance_chance);
					}
					case Armor_Chance:
					{
						armar = "Life Armor";
						resist = 0.0;
					}
				}
				CPrintToChat(client, "{red}[Ad-Armor]{default} Your Armor Type is {cyan}%s{default}, with Damage Absorption Rate of {cyan}%f{default}", armar, resist);
		        }
			case 1: CPrintToChat(client, "{red}[Ad-Armor]{default} The Available Commands are {green}'sm_armorhud'{default}, {green}'sm_armorhudparams'{default}, {green}'sm_setarmor' for admins{default}, {green}'sm_armorhudcolor'{default}, {green}armoroff{default} to remove iArmor, and {green}sm_armorvoice{default} for a voice that reads iArmor.");
		}
	}
	else if (action == MenuAction_End) delete menu;
}
public Action Timer_Announce(Handle hTimer)
{
	if (plugin_enable.BoolValue)
	{
		CPrintToChatAll("{red}[Ad-Armor]{default} for help/info about Armor, type !armorhelp");
	}
	return Plugin_Continue;
}

//UPDATER CRAP//
public void OnAllPluginsLoaded() 
{
	ConVar convar;
	if ( LibraryExists("updater") ) 
	{
		Updater_AddPlugin(UPDATE_URL);
		char newVersion[10];
		FormatEx(newVersion, sizeof(newVersion), "%sA", PLUGIN_VERSION);
		convar = CreateConVar("sm_adarmor_version", newVersion, "Plugin Version", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_CHEAT);
	}
	else convar = CreateConVar("sm_adarmor_version", PLUGIN_VERSION, "Plugin Version", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_CHEAT);
	convar.AddChangeHook(Callback_VersionConVarChanged);
}
public void OnAutoUpdateChange(ConVar conVar, const char[] oldVal, const char[] newVal)
{
	bAutoUpdate = view_as<bool>( StringToInt(newVal) );
}
public void Callback_VersionConVarChanged(ConVar convar, const char[] oldVal, const char[] newVal) 
{
	convar.RestoreDefault();
}
public void OnLibraryAdded(const char[] name)
{
	if (!strcmp(name, "updater")) Updater_AddPlugin(UPDATE_URL);
}
public Action Updater_OnPluginDownloading()
{
	if (!bAutoUpdate) return Plugin_Handled;
	return Plugin_Continue;
}
public void Updater_OnPluginUpdated() 
{
	ReloadPlugin();
}
void UpdateHUD(int client)
{
	if (plugin_enable.BoolValue)
	{
		int setting = GetHUDSetting(client);
		if (show_hud_armor.BoolValue)
		{
			GetHUDParams(client); GetHUDColor(client);
			if ( !IsClientObserver(client) )
			{
				switch (setting)
				{
					case 0, 1: // Generic style
					{
						SetHudTextParams(flArmorHUDParams[client][0], flArmorHUDParams[client][1], 1.0, ArmorHUDColor[client][0], ArmorHUDColor[client][1], ArmorHUDColor[client][2], 255);
						ShowSyncHudText(client, hHudText, "Armor: %i/Max Armor: %i", iArmor[client], iMaxArmor[client]);
					}
					case 2: // DOOM Style
					{
						SetHudTextParams(flArmorHUDParams[client][0], flArmorHUDParams[client][1], 1.0, ArmorHUDColor[client][0], ArmorHUDColor[client][1], ArmorHUDColor[client][2], 255);
						ShowSyncHudText(client, hHudText, "Armor: %i/%i", iArmor[client], iMaxArmor[client]);
					}
					case 3: // TFC/Quake Style
					{
						SetHudTextParams(flArmorHUDParams[client][0], flArmorHUDParams[client][1], 1.0, ArmorHUDColor[client][0], ArmorHUDColor[client][1], ArmorHUDColor[client][2], 255);
						ShowSyncHudText(client, hHudText, "Armor: %i", iArmor[client]);
					}
					case 4: // new style
					{
						SetHudTextParams(flArmorHUDParams[client][0], flArmorHUDParams[client][1], 1.0, ArmorHUDColor[client][0], ArmorHUDColor[client][1], ArmorHUDColor[client][2], 255);
						ShowSyncHudText(client, hHudText, "Armor:(%i) | Max Armor:(%i)", iArmor[client], iMaxArmor[client]);
					}
				}
			}
			if ( IsClientObserver(client) || !IsPlayerAlive(client) )
			{
				int spec = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
				if (IsValidClient(spec) && IsPlayerAlive(spec) && spec != client)
				{
					switch (setting)
					{
						case 0, 1: //Generic style
						{
							SetHudTextParams(flArmorHUDParams[client][0], flArmorHUDParams[client][1], 1.0, ArmorHUDColor[client][0], ArmorHUDColor[client][1], ArmorHUDColor[client][2], 255);
							ShowSyncHudText(client, hHudText, "Armor: %i/Max Armor: %i", iArmor[spec], iMaxArmor[spec]);
						}
						case 2: //DOOM Style
						{
							SetHudTextParams(flArmorHUDParams[client][0], flArmorHUDParams[client][1], 1.0, ArmorHUDColor[client][0], ArmorHUDColor[client][1], ArmorHUDColor[client][2], 255);
							ShowSyncHudText(client, hHudText, "Armor: %i/%i", iArmor[spec], iMaxArmor[spec]);
						}
						case 3: //TFC/Quake Style
						{
							SetHudTextParams(flArmorHUDParams[client][0], flArmorHUDParams[client][1], 1.0, ArmorHUDColor[client][0], ArmorHUDColor[client][1], ArmorHUDColor[client][2], 255);
							ShowSyncHudText(client, hHudText, "Armor: %i", iArmor[spec]);
						}
						case 4: //new style
						{
							SetHudTextParams(flArmorHUDParams[client][0], flArmorHUDParams[client][1], 1.0, ArmorHUDColor[client][0], ArmorHUDColor[client][1], ArmorHUDColor[client][2], 255);
							ShowSyncHudText(client, hHudText, "Armor:(%i) | Max Armor:(%i)", iArmor[spec], iMaxArmor[spec]);
						}
					}
				}
			}
		}
	}
}
///////////////////stocks/////////////////////////////////////////////////////////////////////////////////////////////////
stock void ClearTimer(Handle &Timer)
{
	if (Timer != null)
	{
		Timer.Close(Timer);
		Timer = null;
	}
}
stock bool IsValidClient(int client, bool replaycheck = true)
{
	if ( client <= 0 || client > MaxClients ) return false;
	if ( !IsClientInGame(client) ) return false;
	if ( GetEntProp(client, Prop_Send, "m_bIsCoaching") ) return false;
	if ( replaycheck ) if ( IsClientSourceTV(client) || IsClientReplay(client) ) return false;
	return true;
}
stock float GetTensValue(float value)
{
	float calc = (value/100)-RoundToFloor( (value/100) );
	return (calc *= 100.0);
}
stock float RoundToDecimal(float value)
{
	value /= 10.0;
	return (RoundToFloor(value)*10.0);
}
stock int FindEntityByClassname2(int startEnt, const char[] classname)
{
	/* If startEnt isn't valid shifting it back to the nearest valid one */
	while (startEnt > -1 && !IsValidEdict(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}
stock int GetHealingTarget(int client)
{
	int medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if (medigun <= MaxClients || !IsValidEdict(medigun)) return -1;
	char s[64]; GetEdictClassname(medigun, s, sizeof(s));
	if ( !strcmp(s, "tf_weapon_medigun", false) )
	{
		if (GetEntProp(medigun, Prop_Send, "m_bHealing"))
			return GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");
	}
	return -1;
}
stock bool IsNearSpencer(int client)
{
	int healers = GetEntProp(client, Prop_Send, "m_nNumHealers");
	int medics = 0;
	if (healers > 0)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && IsPlayerAlive(i) && GetHealingTarget(i) == client)
				medics++;
		}
	}
	return ( healers > medics );
}
stock int GetDispenserLevel()
{
	int level, spencer = -1;
	while ((spencer = FindEntityByClassname2(spencer, "obj_dispenser")) != -1)
	{
		level = (IsValidEdict(spencer)) ? GetEntProp(spencer, Prop_Send, "m_iUpgradeLevel") : -1;
	}
	return level;
}
/*stock bool TF2_EwSdkStartup()
{
	Handle hGameConf = LoadGameConfigFile("tf2items.randomizer");
	if (hGameConf == null)
	{
		LogError("Couldn't load SDK functions (GiveWeapon). Make sure tf2items.randomizer.txt is in your gamedata folder! Restart server if you want wearable weapons.");
		return false;
	}
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CTFPlayer::EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	if ((g_hSdkEquipWearable = EndPrepSDKCall()) == null)
	{
		LogError("Couldn't load SDK functions (CTFPlayer::EquipWearable). SDK call failed.");
		return false;
	}
	CloseHandle(hGameConf);
	return true;
}*/
