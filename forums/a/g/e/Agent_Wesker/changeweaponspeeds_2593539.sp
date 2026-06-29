#pragma semicolon 1

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.03"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <dhooks>
#include <sdkhooks>

enum CSGOWeaponID
{
	CSGOWeaponID_NONE = 0, //250
	CSGOWeaponID_DEAGLE, //230
	CSGOWeaponID_REVOLVER, //220
	CSGOWeaponID_ELITE, //240
	CSGOWeaponID_FIVESEVEN, //240
	CSGOWeaponID_GLOCK, //240
	CSGOWeaponID_AK47, //215
	CSGOWeaponID_AUG, //220
	CSGOWeaponID_AWP, //200
	CSGOWeaponID_FAMAS, //220
	CSGOWeaponID_G3SG1, //215
	CSGOWeaponID_GALILAR, //215
	CSGOWeaponID_M249, //195
	CSGOWeaponID_M4A1, //225
	CSGOWeaponID_M4A1SILENCER, //225
	CSGOWeaponID_MAC10, //240
	CSGOWeaponID_P90, //230
	CSGOWeaponID_UMP45, //230
	CSGOWeaponID_XM1014, //215
	CSGOWeaponID_BIZON, //240
	CSGOWeaponID_MAG7, //225
	CSGOWeaponID_NEGEV, //150
	CSGOWeaponID_SAWEDOFF, //210
	CSGOWeaponID_TEC9, //240
	CSGOWeaponID_TASER, //220
	CSGOWeaponID_HKP2000, //240
	CSGOWeaponID_USPSILENCER, //240
	CSGOWeaponID_MP7, //220
	CSGOWeaponID_MP9, //240
	CSGOWeaponID_NOVA, //220
	CSGOWeaponID_P250, //240
	CSGOWeaponID_CZ75A, //240
	CSGOWeaponID_SCAR20, //215
	CSGOWeaponID_SG556, //210
	CSGOWeaponID_SSG08, //230
	CSGOWeaponID_KNIFE, //250
	CSGOWeaponID_FLASHBANG, //245
	CSGOWeaponID_SMOKEGRENADE, //245
	CSGOWeaponID_HEGRENADE, //245
	CSGOWeaponID_MOLOTOV, //245
	CSGOWeaponID_DECOY, //245
	CSGOWeaponID_INCGRENADE, //245
	CSGOWeaponID_C4, //250
	CSGOWeaponID_HEALTHSHOT, //250
}

#pragma newdecls required

EngineVersion g_Game;

Handle g_hPlayerMaxSpeed = INVALID_HANDLE;

ConVar g_WarmupOnly;
File wsFile;

int g_iPlayerSpeed[MAXPLAYERS + 1] =  { 250, ... };
int g_iWeaponSpeeds[44] =  { 250,230,220,240,240,
							 240,215,220,200,220, 
							 215,215,195,225,225,
							 240,230,230,215,240,
							 225,150,210,240,220,
							 240,240,220,240,220,
							 240,240,215,210,230,
							 250,245,245,245,245,
							 245,245,250,250 };


public Plugin myinfo = 
{
	name = "Change Weapon Speeds",
	author = PLUGIN_AUTHOR,
	description = "Change the real speed of weapons (Not lagged movement speed)",
	version = PLUGIN_VERSION,
	url = "https://github.com/Rachnus"
};

public void OnPluginStart()
{
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO)
	{
		SetFailState("This plugin is for CSGO only.");	
	}
	
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	
	RegAdminCmd("sm_reloadweaponspeeds", Command_ReloadWeaponSpeeds, ADMFLAG_GENERIC);
	
	if (wsFile != null) {
		delete wsFile;
		wsFile = null;
	}
	
	g_WarmupOnly = CreateConVar("changeweaponspeeds_warmup_only", "0", "Only change speeds on warmup");
	
	Handle hConf = LoadGameConfigFile("changeweaponspeeds.games");
	int PlayerMaxSpeedOffset = GameConfGetOffset(hConf, "PlayerMaxSpeedOffset");
	//DHOOK CCSPlayer::GetPlayerMaxSpeed 498
	g_hPlayerMaxSpeed = DHookCreate(PlayerMaxSpeedOffset, HookType_Entity, ReturnType_Float, ThisPointer_CBaseEntity, CCSPlayer_GetPlayerMaxSpeed);
	ReadWeaponSpeeds();
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsValidClient(i))
			continue;
		OnClientPutInServer(i);
		DHookEntity(g_hPlayerMaxSpeed, false, i);
	}
	
}

//Called when getting weapon player max speed
public MRESReturn CCSPlayer_GetPlayerMaxSpeed(int pThis, Handle hReturn, Handle hParams)
{
	if(g_WarmupOnly.BoolValue)
		if(!GameRules_GetProp("m_bWarmupPeriod"))
			return MRES_Ignored;
	
	if(!IsValidClient(pThis) || !IsPlayerAlive(pThis))
		return MRES_Ignored;
	
	int weapon = GetEntPropEnt(pThis, Prop_Send, "m_hActiveWeapon");
	if(weapon == INVALID_ENT_REFERENCE)
		return MRES_Ignored;
		
#if defined DEBUG
	PrintToChat(pThis, "SPEED: %d", g_iPlayerSpeed[pThis]);
#endif
	DHookSetReturn(hReturn, float(g_iPlayerSpeed[pThis]));
	return MRES_Supercede;
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(weapon == INVALID_ENT_REFERENCE)
	{
		g_iPlayerSpeed[client] = g_iWeaponSpeeds[view_as<int>(CSGOWeaponID_NONE)];
		return Plugin_Continue;
	}
		
	char szClassName[32];
	GetEntityClassname(weapon, szClassName, sizeof(szClassName));
	g_iPlayerSpeed[client] = g_iWeaponSpeeds[view_as<int>(WeaponClassNameToCSWeaponID(szClassName))];
	return Plugin_Continue;
}

public Action Command_ReloadWeaponSpeeds(int client, int args)
{
	if(ReadWeaponSpeeds()) {
		if (client == 0) {
			PrintToServer(" \x09[\x04Weapon Speeds\x09] Reloaded weapon speeds config!");
			LogMessage(" \x09[\x04Weapon Speeds\x09] Reloaded weapon speeds config!");
		} else if (IsValidClient(client)) {
			PrintToChat(client, " \x09[\x04Weapon Speeds\x09] Reloaded weapon speeds config!");
		}
	} else {
		if (client == 0) {
			PrintToServer(" \x09[\x04Weapon Speeds\x09] Could not load any weapon speeds!");
			LogMessage(" \x09[\x04Weapon Speeds\x09] Could not load any weapon speeds!");
		} else if (IsValidClient(client)) {
			PrintToChat(client, " \x09[\x04Weapon Speeds\x09] Could not load any weapon speeds!");
		}
	}
	return Plugin_Handled;
}

public void OnWeaponSwitchPost(int client, int weapon)
{
	char szClassName[32];
	GetEntityClassname(weapon, szClassName, sizeof(szClassName));
	g_iPlayerSpeed[client] = g_iWeaponSpeeds[view_as<int>(WeaponClassNameToCSWeaponID(szClassName))];
}

public void OnClientPutInServer(int client)
{
	DHookEntity(g_hPlayerMaxSpeed, false, client);
	SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
}

// Is the player in game?
stock bool IsValidClient(int client)
{
	if(client > 0 && client <= MaxClients && IsClientInGame(client))
		return true;
	return false;
}

//Converts a weapon class named to CSGOWeaponID enum
stock CSGOWeaponID WeaponClassNameToCSWeaponID(char[] classname)
{
	if(StrEqual(classname, "weapon_deagle")) return CSGOWeaponID_DEAGLE;
	else if(StrEqual(classname, "weapon_revolver")) return CSGOWeaponID_REVOLVER;
	else if(StrEqual(classname, "weapon_elite")) return CSGOWeaponID_ELITE;
	else if(StrEqual(classname, "weapon_fiveseven")) return CSGOWeaponID_FIVESEVEN;
	else if(StrEqual(classname, "weapon_glock")) return CSGOWeaponID_GLOCK;
	else if(StrEqual(classname, "weapon_ak47")) return CSGOWeaponID_AK47;
	else if(StrEqual(classname, "weapon_aug")) return CSGOWeaponID_AUG;
	else if(StrEqual(classname, "weapon_awp")) return CSGOWeaponID_AWP;
	else if(StrEqual(classname, "weapon_famas")) return CSGOWeaponID_FAMAS;
	else if(StrEqual(classname, "weapon_g3sg1")) return CSGOWeaponID_G3SG1;
	else if(StrEqual(classname, "weapon_galilar")) return CSGOWeaponID_GALILAR;
	else if(StrEqual(classname, "weapon_m249")) return CSGOWeaponID_M249;
	else if(StrEqual(classname, "weapon_m4a1")) return CSGOWeaponID_M4A1;
	else if(StrEqual(classname, "weapon_mac10")) return CSGOWeaponID_MAC10;
	else if(StrEqual(classname, "weapon_p90")) return CSGOWeaponID_P90;
	else if(StrEqual(classname, "weapon_ump45")) return CSGOWeaponID_UMP45;
	else if(StrEqual(classname, "weapon_xm1014")) return CSGOWeaponID_XM1014;
	else if(StrEqual(classname, "weapon_bizon")) return CSGOWeaponID_BIZON;
	else if(StrEqual(classname, "weapon_mag7")) return CSGOWeaponID_MAG7;
	else if(StrEqual(classname, "weapon_negev")) return CSGOWeaponID_NEGEV;
	else if(StrEqual(classname, "weapon_sawedoff")) return CSGOWeaponID_SAWEDOFF;
	else if(StrEqual(classname, "weapon_tec9")) return CSGOWeaponID_TEC9;
	else if(StrEqual(classname, "weapon_taser")) return CSGOWeaponID_TASER;
	else if(StrEqual(classname, "weapon_hkp2000")) return CSGOWeaponID_HKP2000;
	else if(StrEqual(classname, "weapon_mp7")) return CSGOWeaponID_MP7;
	else if(StrEqual(classname, "weapon_mp9")) return CSGOWeaponID_MP9;
	else if(StrEqual(classname, "weapon_nova")) return CSGOWeaponID_NOVA;
	else if(StrEqual(classname, "weapon_p250")) return CSGOWeaponID_P250;
	else if(StrEqual(classname, "weapon_scar20")) return CSGOWeaponID_SCAR20;
	else if(StrEqual(classname, "weapon_sg556")) return CSGOWeaponID_SG556;
	else if(StrEqual(classname, "weapon_ssg08")) return CSGOWeaponID_SSG08;
	else if(StrContains(classname, "knife") != -1 || StrContains(classname, "bayonet") != -1) return CSGOWeaponID_KNIFE; //NO:GO
	else if(StrEqual(classname, "weapon_flashbang")) return CSGOWeaponID_FLASHBANG;
	else if(StrEqual(classname, "weapon_smokegrenade")) return CSGOWeaponID_SMOKEGRENADE;
	else if(StrEqual(classname, "weapon_hegrenade")) return CSGOWeaponID_HEGRENADE;
	else if(StrEqual(classname, "weapon_molotov")) return CSGOWeaponID_MOLOTOV;
	else if(StrEqual(classname, "weapon_decoy")) return CSGOWeaponID_DECOY;
	else if(StrEqual(classname, "weapon_incgrenade")) return CSGOWeaponID_INCGRENADE;
	else if(StrEqual(classname, "weapon_c4")) return CSGOWeaponID_C4;
	else if(StrEqual(classname, "weapon_m4a1_silencer")) return CSGOWeaponID_M4A1SILENCER;
	else if(StrEqual(classname, "weapon_usp_silencer")) return CSGOWeaponID_USPSILENCER;
	else if(StrEqual(classname, "weapon_cz75a")) return CSGOWeaponID_CZ75A;
	else if(StrEqual(classname, "weapon_revolver")) return CSGOWeaponID_REVOLVER;
	else if(StrEqual(classname, "weapon_healthshot")) return CSGOWeaponID_HEALTHSHOT;
	else return CSGOWeaponID_NONE;
}

public void OnMapStart()
{
	if (wsFile != null) {
		delete wsFile;
		wsFile = null;
	}
}

public void OnMapEnd()
{
	if (wsFile != null) {
		delete wsFile;
		wsFile = null;
	}
}

public bool ReadWeaponSpeeds()
{
	if (wsFile != null) {
		delete wsFile;
		wsFile = null;
	}
	
	char weaponSpeedsPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, weaponSpeedsPath, sizeof(weaponSpeedsPath), "configs/changeweaponspeeds.ini");

	if(!FileExists(weaponSpeedsPath))
		SetFailState("[changeweaponspeeds.smx] Could not load %s", weaponSpeedsPath);

	wsFile = OpenFile(weaponSpeedsPath, "rt");

	if(!wsFile)
		SetFailState("[changeweaponspeeds.smx] Could not load %s", weaponSpeedsPath);

	char data[256];
	char szSpeed[9];
	int speed = 0;
	int weapon = 0;
	while (!IsEndOfFile(wsFile)) 
	{
		if(weapon > view_as<int>(CSGOWeaponID_HEALTHSHOT))
			SetFailState("[changeweaponspeed.smx] There are too many weapon entries in weaponspeeds.ini");
			
		ReadFileLine(wsFile, data, sizeof(data));
		TrimString(data);
		
		if( data[0] == '\0' || strncmp(data, "##", 2, false) == 0) 
			continue;

		BreakString(data, szSpeed, sizeof(szSpeed));
		TrimString(szSpeed);
		speed = StringToInt(szSpeed);
#if defined DEBUG
		PrintToServer("%d - SPEED: %d", weapon, speed);
#endif
		g_iWeaponSpeeds[weapon] = speed;
		weapon++;
	}
	if(weapon > 0) {
		wsFile.Close();
		wsFile = null;
		return true;
	} else {
		wsFile.Close();
		wsFile = null;
		return false;
	}
}