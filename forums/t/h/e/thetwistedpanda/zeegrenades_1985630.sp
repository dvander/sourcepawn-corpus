#pragma semicolon 1

#define PLUGIN_VERSION "1.0.2"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <adminmenu>
#include <cstrike>
#include <morecolors>
#include <zombiereloaded>

#define AMMO_HEGRENADE 11
#define AMMO_FLASHBANG 12
#define AMMO_SMGRENADE 13

new Handle:g_hMultiAccess = INVALID_HANDLE;
new Handle:g_hMultiFlag = INVALID_HANDLE;
new Handle:g_hSpawnDuration = INVALID_HANDLE;
new Handle:g_hInfectDuration = INVALID_HANDLE;
new Handle:g_hFreezeRadius = INVALID_HANDLE;
new Handle:g_hFreezeDuration = INVALID_HANDLE;
new Handle:g_hFreezeSound = INVALID_HANDLE;
new Handle:g_hExplodeSound = INVALID_HANDLE;
new Handle:g_hFreezeSpeed = INVALID_HANDLE;
new Handle:g_hFreezeRecovery = INVALID_HANDLE;
new Handle:g_hGrenadeCap = INVALID_HANDLE;
new Handle:g_hSmokeCap = INVALID_HANDLE;
new Handle:g_hFlashCap = INVALID_HANDLE;
new Handle:g_hFreezeReset = INVALID_HANDLE;
new Handle:g_hFreezeColor = INVALID_HANDLE;
new Handle:g_hBounceFlash = INVALID_HANDLE;
new Handle:g_hBounceSmoke = INVALID_HANDLE;
new Handle:g_hBounceGrenade = INVALID_HANDLE;
new Handle:g_hDurationFlash = INVALID_HANDLE;
new Handle:g_hDurationGrenade = INVALID_HANDLE;
new Handle:g_hDurationSmoke = INVALID_HANDLE;
new Handle:g_hMultiDelay = INVALID_HANDLE;
new Handle:g_hDisappearingPatch = INVALID_HANDLE;
new Handle:g_hDropKnife = INVALID_HANDLE;

new bool:g_bLateLoad, bool:g_bFreezeReset, bool:g_bFreezeColor, bool:g_bDisappearingPatch;
new g_iLightSprite, g_iHaloSprite, g_iMultiFlag, g_iSpawnDuration, g_iInfectDuration, g_iFlashCap, g_iGrenadeCap, g_iSmokeCap, g_iMultiDelay, g_iDropKnife;
new Float:g_fFreezeDuration, Float:g_fFreezeRadius, Float:g_fFreezeSpeed, Float:g_fFreezeRecovery;
new String:g_sFreezeSound[PLATFORM_MAX_PATH], String:g_sExplodeSound[PLATFORM_MAX_PATH], String:g_sMultiAccess[32];
new Float:g_fBounceFlash, Float:g_fBounceSmoke, Float:g_fBounceGrenade, Float:g_fDurationFlash, Float:g_fDurationGrenade, Float:g_fDurationSmoke;

new Handle:g_hCurrentlyFrozen[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };
new Float:g_fCurrentlyFrozen[MAXPLAYERS + 1];
new Float:g_fOriginalSpeed[MAXPLAYERS + 1];
new g_iSpawnImmunity[MAXPLAYERS + 1];
new g_iLastMessageType[MAXPLAYERS + 1];
new g_iLastMessageTime[MAXPLAYERS + 1];
new g_iInfectImmunity[MAXPLAYERS + 1];
new g_iGrenades[MAXPLAYERS + 1][3];

public Plugin:myinfo =
{
	name = "ZeeGrenades",
	author = "Panduh",
	description = "Provides functionality for preventing multiple grenades, freeze grenades, and grenade customization.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar("zeegrenades_version", PLUGIN_VERSION, "ZeeGrenades: Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_CHEAT|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_hMultiAccess = CreateConVar("zeegrenades_multi_access_override", "MultiZeeGrenades", "Individuals with this override will be able to hold more than one grenade type.", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hMultiAccess, OnSettingsChange);
	GetConVarString(g_hMultiAccess, g_sMultiAccess, sizeof(g_sMultiAccess));

	g_hMultiFlag = CreateConVar("zeegrenades_multi_access_flag", "a", "Individuals with this flag (if they do not possess the override) will be able to hold more than one grenade type.", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hMultiFlag, OnSettingsChange);
	decl String:sTemp[8];
	GetConVarString(g_hMultiFlag, sTemp, sizeof(sTemp));
	g_iMultiFlag = ReadFlagString(sTemp);
	
	g_hSpawnDuration = CreateConVar("zeegrenades_zombie_spawn_immunity", "10", "The duration, in seconds, a newly spawning zombie is protected from grenade effects. (0 = Disabled)", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hSpawnDuration, OnSettingsChange);
	g_iSpawnDuration = GetConVarInt(g_hSpawnDuration);
	
	g_hInfectDuration = CreateConVar("zeegrenades_zombie_infect_immunity", "0", "The duration, in seconds, a newly infected zombie is protected from grenade effects. (0 = Disabled)", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hInfectDuration, OnSettingsChange);
	g_iInfectDuration = GetConVarInt(g_hInfectDuration);
	
	g_hFreezeRadius = CreateConVar("zeegrenades_freeze_radius", "500.0", "The radius around an exploding smoke grenade to check for zombies to freeze.", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hFreezeRadius, OnSettingsChange);
	g_fFreezeRadius = GetConVarFloat(g_hFreezeRadius);
	
	g_hFreezeDuration = CreateConVar("zeegrenades_freeze_duration", "2.0", "The minimum number of seconds to freeze zombies.", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hFreezeDuration, OnSettingsChange);
	g_fFreezeDuration = GetConVarFloat(g_hFreezeDuration);
	
	g_hFreezeRecovery = CreateConVar("zeegrenades_freeze_recovery", "3.0", "The number of seconds after a zombie's freeze that their speed slowly recovers to the original amount.", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hFreezeRecovery, OnSettingsChange);
	g_fFreezeRecovery = GetConVarFloat(g_hFreezeRecovery);
	
	g_hFreezeReset = CreateConVar("zeegrenades_freeze_reset", "0", "If enabled, an additional freeze grenade will reset the zombie's counter, re-freezing them.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hFreezeReset, OnSettingsChange);
	g_bFreezeReset = GetConVarBool(g_hFreezeReset);
	
	g_hFreezeColor = CreateConVar("zeegrenades_freeze_color", "1", "If enabled, zombies will receive a blue color while frozen.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hFreezeColor, OnSettingsChange);
	g_bFreezeColor = GetConVarBool(g_hFreezeColor);
	
	g_hFreezeSound = CreateConVar("zeegrenades_freeze_sound", "physics/glass/glass_impact_bullet4.wav", "The sound to play to frozen zombies.", FCVAR_NONE);
	HookConVarChange(g_hFreezeSound, OnSettingsChange);
	GetConVarString(g_hFreezeSound, g_sFreezeSound, sizeof(g_sFreezeSound));
	
	g_hExplodeSound = CreateConVar("zeegrenades_freeze_explode_sound", "ui/freeze_cam.wav", "The sound to play at the location of the explosion.", FCVAR_NONE);
	HookConVarChange(g_hExplodeSound, OnSettingsChange);
	GetConVarString(g_hExplodeSound, g_sExplodeSound, sizeof(g_sExplodeSound));

	g_hBounceFlash = CreateConVar("zeegrenades_flash_bounce", "0.5", "The amount of \"bounce\" Flashbangs have. (0.0 = No Bounce, 0.5 = Default, 1.0 = Excessive Bounce)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hBounceFlash, OnSettingsChange);
	g_fBounceFlash = GetConVarFloat(g_hBounceFlash);
	
	g_hBounceSmoke = CreateConVar("zeegrenades_smoke_bounce", "0.25", "The amount of \"bounce\" Smoke Grenades have. (0.0 = No Bounce, 0.5 = Default, 1.0 = Excessive Bounce)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hBounceSmoke, OnSettingsChange);
	g_fBounceSmoke = GetConVarFloat(g_hBounceSmoke);

	g_hBounceGrenade = CreateConVar("zeegrenades_grenade_bounce", "0.5", "The amount of \"bounce\" HE Grenades have. (0.0 = No Bounce, 0.5 = Default, 1.0 = Excessive Bounce)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hBounceGrenade, OnSettingsChange);
	g_fBounceGrenade = GetConVarFloat(g_hBounceGrenade);
	
	g_hDurationFlash = CreateConVar("zeegrenades_flash_length", "0.0", "The number of seconds it takes before a Flashbang will explode. (0.0 = Default)", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hDurationFlash, OnSettingsChange);
	g_fDurationFlash = GetConVarFloat(g_hDurationFlash);
	
	g_hDurationGrenade = CreateConVar("zeegrenades_grenade_length", "0.0", "The number of seconds it takes before a HE Grenade will explode. (0.0 = Default)", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hDurationGrenade, OnSettingsChange);
	g_fDurationGrenade = GetConVarFloat(g_hDurationGrenade);
	
	g_hDurationSmoke = CreateConVar("zeegrenades_smoke_length", "2.0", "The number of seconds it takes before a Smoke Grenade will explode. (0.0 = Default)", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hDurationSmoke, OnSettingsChange);	
	g_fDurationSmoke = GetConVarFloat(g_hDurationSmoke);

	g_hFreezeSpeed = CreateConVar("zeegrenades_freeze_speed", "0.001", "The speed to set zombies to while frozen.", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hFreezeSpeed, OnSettingsChange);
	g_fFreezeSpeed = GetConVarFloat(g_hFreezeSpeed);
	
	g_hMultiDelay = CreateConVar("zeegrenades_multi_restrict_delay", "2", "The number of seconds before a user can be re-notified about restricted access, unless grenade type differs. (0 = Disabled)", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hMultiDelay, OnSettingsChange);
	g_iMultiDelay = GetConVarInt(g_hMultiDelay);
	
	g_hDisappearingPatch = CreateConVar("zeegrenades_disappearing_patch", "1", "If enabled, players grenades will be removed at the end of the round and re-applied at start.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hDisappearingPatch, OnSettingsChange);
	g_bDisappearingPatch = GetConVarBool(g_hDisappearingPatch);
	
	g_hDropKnife = CreateConVar("zeegrenades_drop_knife", "2", "The teams that are allowed to drop their knife. (0 = Disabled, 1 = Both, 2 = Humans, 3 = Zombies)", FCVAR_NONE, true, 0.0, true, 3.0);
	HookConVarChange(g_hDropKnife, OnSettingsChange);
	g_iDropKnife = GetConVarInt(g_hDropKnife);
	AutoExecConfig(true, "zeegrenades");
	
	AddCommandListener(Listener_Drop, "drop");
	
	g_hGrenadeCap = FindConVar("ammo_hegrenade_max");
	HookConVarChange(g_hGrenadeCap, OnSettingsChange);
	g_iGrenadeCap = GetConVarInt(g_hGrenadeCap);
	
	g_hSmokeCap  = FindConVar("ammo_flashbang_max");
	HookConVarChange(g_hSmokeCap, OnSettingsChange);
	g_iSmokeCap = GetConVarInt(g_hSmokeCap);
	
	g_hFlashCap = FindConVar("ammo_smokegrenade_max");
	HookConVarChange(g_hFlashCap, OnSettingsChange);
	g_iFlashCap = GetConVarInt(g_hFlashCap);
	
	HookEvent("round_end", Event_OnRoundEnd, EventHookMode_Pre);
	HookEvent("player_spawn", Event_OnPlayerSpawn, EventHookMode_Pre);
}

public OnMapStart() 
{
	g_iLightSprite = PrecacheModel("materials/sprites/lgtning.vmt");
	g_iHaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	
	PrecacheSound(g_sFreezeSound);
	PrecacheSound(g_sExplodeSound);
}

public Action:Event_OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bDisappearingPatch)
		return Plugin_Continue;
	
	for(new i = 1; i <= MaxClients; i++)
	{
		for(new j = 0; j <= 2; j++)
			g_iGrenades[i][j] = 0;

		if(IsClientInGame(i) && IsPlayerAlive(i) && ZR_IsClientHuman(i))
		{
			g_iGrenades[i][0] = GetGrenadeCount(i, AMMO_HEGRENADE);
			if(g_iGrenades[i][0])
				SetGrenadeCount(i, AMMO_HEGRENADE, 0);
			
			g_iGrenades[i][1] = GetGrenadeCount(i, AMMO_FLASHBANG);
			if(g_iGrenades[i][1])
				SetGrenadeCount(i, AMMO_FLASHBANG, 0);
			
			g_iGrenades[i][2] = GetGrenadeCount(i, AMMO_SMGRENADE);
			if(g_iGrenades[i][2])
				SetGrenadeCount(i, AMMO_SMGRENADE, 0);
		}
	}

	return Plugin_Continue;
}

public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bDisappearingPatch)
		return Plugin_Continue;

	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Continue;
		
	CreateTimer(0.3, Timer_Equip, userid, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}		

public Action:Timer_Equip(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(!client || !IsClientInGame(client))
		return Plugin_Continue;
		
	if(IsPlayerAlive(client) && ZR_IsClientHuman(client))
	{
		if(g_iGrenades[client][0])
		{
			new iCurrent = GetGrenadeCount(client, AMMO_HEGRENADE);
			if(iCurrent < g_iGrenades[client][0])
			{
				if(!iCurrent)
					GivePlayerItem(client, "weapon_hegrenade");

				iCurrent++;
				if(iCurrent < g_iGrenades[client][0])
					SetGrenadeCount(client, AMMO_HEGRENADE, (g_iGrenades[client][0] - iCurrent));
			}
			
			g_iGrenades[client][0] = 0;
		}
		
		if(g_iGrenades[client][1])
		{
			new iCurrent = GetGrenadeCount(client, AMMO_FLASHBANG);
			if(iCurrent < g_iGrenades[client][0])
			{
				if(!iCurrent)
					GivePlayerItem(client, "weapon_flashbang");

				iCurrent++;
				if(iCurrent < g_iGrenades[client][1])
					SetGrenadeCount(client, AMMO_FLASHBANG, (g_iGrenades[client][1] - iCurrent));
			}
			
			g_iGrenades[client][1] = 0;
		}
		
		if(g_iGrenades[client][2])
		{
			new iCurrent = GetGrenadeCount(client, AMMO_SMGRENADE);
			if(iCurrent < g_iGrenades[client][2])
			{
				if(!iCurrent)
					GivePlayerItem(client, "weapon_smokegrenade");
				iCurrent++;

				if(iCurrent < g_iGrenades[client][2])
					SetGrenadeCount(client, AMMO_SMGRENADE, (g_iGrenades[client][2] - iCurrent));
			}
			
			g_iGrenades[client][2] = 0;
		}
	}
		
	return Plugin_Continue;
}

public OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hSpawnDuration)
		g_iSpawnDuration = StringToInt(newvalue);
	else if(cvar == g_hMultiDelay)
		g_iMultiDelay = StringToInt(newvalue);
	else if(cvar == g_hInfectDuration)
		g_iInfectDuration = StringToInt(newvalue);
	else if(cvar == g_hFreezeRadius)
		g_fFreezeRadius = StringToFloat(newvalue);
	else if(cvar == g_hFreezeDuration)
		g_fFreezeDuration = StringToFloat(newvalue);
	else if(cvar == g_hFreezeSpeed)
		g_fFreezeSpeed = StringToFloat(newvalue);
	else if(cvar == g_hFreezeRecovery)
		g_fFreezeRecovery = StringToFloat(newvalue);
	else if(cvar == g_hFreezeReset)
		g_bFreezeReset = bool:StringToInt(newvalue);
	else if(cvar == g_hFreezeColor)
		g_bFreezeColor = bool:StringToInt(newvalue);
	else if(cvar == g_hFreezeSound)
		strcopy(g_sFreezeSound, sizeof(g_sFreezeSound), newvalue);
	else if(cvar == g_hExplodeSound)
		strcopy(g_sExplodeSound, sizeof(g_sExplodeSound), newvalue);
	else if(cvar == g_hMultiFlag)
		g_iMultiFlag = ReadFlagString(newvalue);
	else if(cvar == g_hBounceFlash)
		g_fBounceFlash = StringToFloat(newvalue);
	else if(cvar == g_hBounceSmoke)
		g_fBounceSmoke = StringToFloat(newvalue);
	else if(cvar == g_hBounceGrenade)
		g_fBounceGrenade = StringToFloat(newvalue);
	else if(cvar == g_hDurationFlash)
		g_fDurationFlash = StringToFloat(newvalue);
	else if(cvar == g_hDurationGrenade)
		g_fDurationGrenade = StringToFloat(newvalue);
	else if(cvar == g_hDurationSmoke)
		g_fDurationSmoke = StringToFloat(newvalue);
	else if(cvar == g_hGrenadeCap)
		g_iGrenadeCap = StringToInt(newvalue);
	else if(cvar == g_hSmokeCap)
		g_iSmokeCap = StringToInt(newvalue);
	else if(cvar == g_hFlashCap)
		g_iFlashCap = StringToInt(newvalue);
}

public OnConfigsExecuted()
{
	if(g_bLateLoad)
	{
		for(new i = 1; i <= MaxClients; i++)
			if(IsClientInGame(i))
				SDKHook(i, SDKHook_WeaponCanUse, Hook_WeaponCanUse);
				
		g_bLateLoad = false;
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponCanUse, Hook_WeaponCanUse);
}

public OnClientDisconnect(client)
{
	g_iSpawnImmunity[client] = 0;
	g_iInfectImmunity[client] = 0;
	g_fOriginalSpeed[client] = 0.0;
	if(g_hCurrentlyFrozen[client] != INVALID_HANDLE && CloseHandle(g_hCurrentlyFrozen[client]))
		g_hCurrentlyFrozen[client] = INVALID_HANDLE;
}

public Action:Hook_WeaponCanUse(client, weapon)
{
	if(weapon <= 0 || !IsValidEntity(weapon))
		return Plugin_Continue;

	decl String:sClassname[32];
	GetEntityClassname(weapon, sClassname, sizeof(sClassname));
	if(StrEqual(sClassname, "weapon_flashbang", false))
	{
		new iGrenade = GetGrenadeCount(client, AMMO_HEGRENADE);
		new iSmoke = GetGrenadeCount(client, AMMO_SMGRENADE);
		if(GetGrenadeCount(client, AMMO_FLASHBANG) >= g_iFlashCap)
			return Plugin_Handled;
		else if((iGrenade || iSmoke) && !CheckCommandAccess(client, g_sMultiAccess, g_iMultiFlag))
		{
			new iTime = GetTime();
			if(g_iLastMessageType[client] != AMMO_FLASHBANG || iTime >= g_iLastMessageTime[client])
			{
				g_iLastMessageType[client] = AMMO_FLASHBANG;
				g_iLastMessageTime[client] = (iTime + g_iMultiDelay);
				
				CPrintToChat(client, "{olive}[ZR] {default}You may only hold one grenade of any type! You must drop your current grenade to pick up this Flashbang.");
			}
			else
				PrintHintText(client, "[ZR] You're only allowed to hold one grenade of any type!");

			return Plugin_Handled;
		}
	}
	else if(StrEqual(sClassname, "weapon_hegrenade", false))
	{
		new iFlash = GetGrenadeCount(client, AMMO_FLASHBANG);
		new iSmoke = GetGrenadeCount(client, AMMO_SMGRENADE);
		if(GetGrenadeCount(client, AMMO_HEGRENADE) >= g_iGrenadeCap)
			return Plugin_Handled;
		else if((iFlash || iSmoke) && !CheckCommandAccess(client, g_sMultiAccess, g_iMultiFlag))
		{
			new iTime = GetTime();
			if(g_iLastMessageType[client] != AMMO_HEGRENADE || iTime >= g_iLastMessageTime[client])
			{
				g_iLastMessageType[client] = AMMO_HEGRENADE;
				g_iLastMessageTime[client] = (iTime + g_iMultiDelay);
				
				CPrintToChat(client, "{olive}[ZR] {default}You may only hold one grenade of any type! You must drop your current grenade to pick up this HE-Grenade.");
			}
			else
				PrintHintText(client, "[ZR] You're only allowed to hold one grenade of any type!");
				
			return Plugin_Handled;
		}
	}
	else if(StrEqual(sClassname, "weapon_smokegrenade", false))
	{
		new iFlash = GetGrenadeCount(client, AMMO_FLASHBANG);
		new iGrenade = GetGrenadeCount(client, AMMO_HEGRENADE);
		if(GetGrenadeCount(client, AMMO_SMGRENADE) >= g_iSmokeCap)
			return Plugin_Handled;
		else if((iFlash || iGrenade) && !CheckCommandAccess(client, g_sMultiAccess, g_iMultiFlag))
		{
			new iTime = GetTime();
			if(g_iLastMessageType[client] != AMMO_SMGRENADE || iTime >= g_iLastMessageTime[client])
			{
				g_iLastMessageType[client] = AMMO_SMGRENADE;
				g_iLastMessageTime[client] = (iTime + g_iMultiDelay);
				
				CPrintToChat(client, "{olive}[ZR] {default}You may only hold one grenade of any type! You must drop your current grenade to pick up this Smoke Grenade.");
			}
			else
				PrintHintText(client, "[ZR] You're only allowed to hold one grenade of any type!");

			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

public Action:Listener_Drop(client, const String:command[], argc)
{
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) <= CS_TEAM_SPECTATOR)
		return Plugin_Handled;
	
	new iEntity = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if(iEntity <= 0 || !IsValidEdict(iEntity) || !IsValidEntity(iEntity))
		return Plugin_Handled;

	decl String:sClassname[32];
	GetEntityClassname(iEntity, sClassname, sizeof(sClassname));

	if(StrEqual(sClassname, "weapon_flashbang", false))
	{
		new iCount = GetEntProp(client, Prop_Send, "m_iAmmo", _, AMMO_FLASHBANG);
		CS_DropWeapon(client, iEntity, true, true);
		
		if(iCount > 1)
		{
			new iIndex = GivePlayerItem(client, "weapon_flashbang");
			SetGrenadeCount(client, AMMO_FLASHBANG, (iCount - 1));
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", iIndex);
		}
		
		return Plugin_Handled;
	}
	else if(StrEqual(sClassname, "weapon_hegrenade", false))
	{
		new iCount = GetEntProp(client, Prop_Send, "m_iAmmo", _, AMMO_HEGRENADE);
		CS_DropWeapon(client, iEntity, true, true);
		
		if(iCount > 1)
		{
			new iIndex = GivePlayerItem(client, "weapon_hegrenade");
			SetGrenadeCount(client, AMMO_HEGRENADE, (iCount - 1));
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", iIndex);
		}
		
		return Plugin_Handled;
	}
	else if(StrEqual(sClassname, "weapon_smokegrenade", false))
	{
		new iCount = GetEntProp(client, Prop_Send, "m_iAmmo", _, AMMO_SMGRENADE);
		CS_DropWeapon(client, iEntity, true, true);
		
		if(iCount > 1)
		{
			new iIndex = GivePlayerItem(client, "weapon_smokegrenade");
			SetGrenadeCount(client, AMMO_SMGRENADE, (iCount - 1));
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", iIndex);
		}
		
		return Plugin_Handled;
	}
	else if(g_iDropKnife && StrEqual(sClassname, "weapon_knife", false))
	{
		new bool:bAllowed;
		if(g_iDropKnife == 1 || (g_iDropKnife == 2 && ZR_IsClientHuman(client)) || (g_iDropKnife == 3 && ZR_IsClientZombie(client)))
			CS_DropWeapon(client, iEntity, true, true);

		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action:Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client || !IsClientInGame(client))
		return Plugin_Continue;
		
	if(g_hCurrentlyFrozen[client] != INVALID_HANDLE && CloseHandle(g_hCurrentlyFrozen[client]))
		g_hCurrentlyFrozen[client] = INVALID_HANDLE;

	return Plugin_Continue;
}

public ZR_OnClientInfected(client, attacker, bool:motherInfect, bool:respawnOverride, bool:respawn)
{
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client))
		return;
	
	if(motherInfect)
	{
		if(g_iSpawnDuration)
			g_iSpawnImmunity[client] = GetTime() + g_iSpawnDuration;
	}
	else
	{
		if(g_iInfectDuration)
			g_iInfectImmunity[client] = GetTime() + g_iInfectDuration;
	}

	return;
}


public OnEntityCreated(entity, const String:classname[])
{
	if(!strcmp(classname, "env_particlesmokegrenade", false))
		AcceptEntityInput(entity, "Kill");
	else if(!strcmp(classname, "hegrenade_projectile", false))
	{
		new iReference = EntIndexToEntRef(entity);
		CreateTimer(0.1, Timer_OnGrenadeCreated, iReference);
		if(g_fDurationGrenade)
			CreateTimer(g_fDurationGrenade, Timer_OnStartDetonate, iReference);
	}
	else if(!strcmp(classname, "smokegrenade_projectile", false))
	{
		new iReference = EntIndexToEntRef(entity);
		CreateTimer(0.1, Timer_OnSmokeCreated, iReference);
		if(g_fDurationSmoke)
			CreateTimer(g_fDurationSmoke, Timer_DetonateFreeze, iReference);
	}
	else if(!strcmp(classname, "flashbang_projectile", false))
	{
		new iReference = EntIndexToEntRef(entity);
		CreateTimer(0.1, Timer_OnFlashCreated, iReference);
		if(g_fDurationFlash)
			CreateTimer(g_fDurationFlash, Timer_OnStartDetonate, iReference);
	}
}

public Action:Timer_OnGrenadeCreated(Handle:timer, any:ref)
{
	new entity = EntRefToEntIndex(ref);
	if(entity != INVALID_ENT_REFERENCE)
	{
		SetEntPropFloat(entity, Prop_Data, "m_flElasticity", g_fBounceGrenade);
		if(g_fDurationGrenade)
			SetEntProp(entity, Prop_Data, "m_nNextThinkTick", -1);
	}
}

public Action:Timer_OnSmokeCreated(Handle:timer, any:ref)
{
	new entity = EntRefToEntIndex(ref);
	if(entity != INVALID_ENT_REFERENCE)
	{
		SetEntPropFloat(entity, Prop_Data, "m_flElasticity", g_fBounceSmoke);
		if(g_fDurationSmoke)
			SetEntProp(entity, Prop_Data, "m_nNextThinkTick", -1);
	}
}

public Action:Timer_OnFlashCreated(Handle:timer, any:ref)
{
	new entity = EntRefToEntIndex(ref);
	if(entity != INVALID_ENT_REFERENCE)
	{
		SetEntPropFloat(entity, Prop_Data, "m_flElasticity", g_fBounceFlash);
		if(g_fDurationFlash)
			SetEntProp(entity, Prop_Data, "m_nNextThinkTick", -1);
	}
}

public Action:Timer_OnStartDetonate(Handle:timer, any:ref)
{
	new entity = EntRefToEntIndex(ref);
	if(entity != INVALID_ENT_REFERENCE)
		SetEntProp(entity, Prop_Data, "m_nNextThinkTick", 1);
}

public Action:Timer_DetonateFreeze(Handle:timer, any:ref)
{
	new entity = EntRefToEntIndex(ref);
	if(entity != INVALID_ENT_REFERENCE)
	{
		decl Float:fOrigin[3], Float:fPosition[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", fOrigin);

		fOrigin[2] += 10.0;
		new iTime = GetTime();
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || !IsPlayerAlive(i) || ZR_IsClientHuman(i))
				continue;
			
			GetClientAbsOrigin(i, fPosition);
			if (GetVectorDistance(fOrigin, fPosition) > g_fFreezeRadius)
				continue;
			if(g_iSpawnDuration && iTime < g_iSpawnImmunity[i] || g_iInfectDuration && iTime < g_iInfectImmunity[i])
				continue;
			
			Freeze(i);
		}

		EmitSoundToAll(g_sExplodeSound, entity, SNDCHAN_WEAPON);
		TE_SetupBeamRingPoint(fOrigin, 10.0, g_fFreezeRadius, g_iLightSprite, g_iHaloSprite, 1, 1, 0.2, 100.0, 1.0, {75, 75, 255, 255}, 0, 0);
		TE_SendToAll();
		
		AcceptEntityInput(entity, "Kill");
	}
}

Freeze(client)
{
	if(g_bFreezeReset && g_hCurrentlyFrozen[client] != INVALID_HANDLE)
	{
		g_fCurrentlyFrozen[client] = 0.0;
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", g_fFreezeSpeed);
		if(g_bFreezeColor)
			SetEntityRenderColor(client, 0, 0, 255, 255);
				
		if(strlen(g_sFreezeSound))
		{
			new Float:fEyePosition[3];
			GetClientEyePosition(client, fEyePosition);
			EmitAmbientSound(g_sFreezeSound, fEyePosition, client, SNDLEVEL_RAIDSIREN);
		}
	}
	else
	{
		if(g_hCurrentlyFrozen[client] != INVALID_HANDLE)
			return;
		
		if(g_bFreezeColor)
			SetEntityRenderColor(client, 0, 0, 255, 255);

		g_fCurrentlyFrozen[client] = 0.0;
		g_fOriginalSpeed[client] = GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue");
		if(g_fOriginalSpeed[client] < 1.0)
			g_fOriginalSpeed[client] = 1.0;
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", g_fFreezeSpeed);
		g_hCurrentlyFrozen[client] = CreateTimer(0.1, Timer_Defrost, client, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);

		if(strlen(g_sFreezeSound))
		{
			new Float:fEyePosition[3];
			GetClientEyePosition(client, fEyePosition);
			EmitAmbientSound(g_sFreezeSound, fEyePosition, client, SNDLEVEL_RAIDSIREN);
		}
	}
}

public Action:Timer_Defrost(Handle:timer, any:client)
{
	if(!IsClientInGame(client) || !IsPlayerAlive(client) || !ZR_IsClientZombie(client))
	{
		if(g_bFreezeColor)
			SetEntityRenderColor(client, 255, 255, 255, 255);
		g_hCurrentlyFrozen[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	if(g_fCurrentlyFrozen[client] <= (g_fFreezeDuration + g_fFreezeRecovery))
	{
		g_fCurrentlyFrozen[client] += 0.1;

		if(g_fCurrentlyFrozen[client] <= g_fFreezeDuration)
		{
			if(g_bFreezeColor)
				SetEntityRenderColor(client, 0, 0, 255, 255);
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", g_fFreezeSpeed);
			return Plugin_Continue;
		}
			
		new Float:fSpeed = ((g_fOriginalSpeed[client] * (g_fCurrentlyFrozen[client] - g_fFreezeDuration))) / g_fFreezeRecovery;
		if(g_bFreezeColor)
		{
			new iColor = RoundToFloor(255.0 / (g_fCurrentlyFrozen[client] / g_fFreezeRecovery));
			SetEntityRenderColor(client, 0, 0, iColor, 255);
		}
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", fSpeed);
		return Plugin_Continue;
	}
	else
	{
		if(g_bFreezeColor)
			SetEntityRenderColor(client, 255, 255, 255, 255);
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", g_fOriginalSpeed[client]);
		g_hCurrentlyFrozen[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
}

SetGrenadeCount(client, type, amount)
{
	SetEntData(client, (FindDataMapOffs(client, "m_iAmmo") + (type * 4)), amount);
}

GetGrenadeCount(client, type)
{
	return GetEntData(client, (FindDataMapOffs(client, "m_iAmmo") + (type * 4)));
}