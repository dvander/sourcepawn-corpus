/*============================================================================================
							[L4D2] Explosive AWP and Scout bullets
----------------------------------------------------------------------------------------------
*	Author	:	Eärendil
*	Descrp	:	AWP and Scout bullets explode on impact.
*	Version	:	1.1
*	Link	:	https://forums.alliedmods.net/showthread.php?p=2747814#post2747814
==============================================================================================*/
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define SND_EXPL1 "weapons/flaregun/gunfire/flaregun_explode_1.wav"
#define SND_EXPL2 "weapons/flaregun/gunfire/flaregun_fire_1.wav"
#define SND_EXPL3 "animation/plane_engine_explode.wav"

#define PLUGIN_VERSION		"1.1"

ConVar g_hAllow, g_hGameModes, g_hDamage, g_hRadius, g_hDamageFriend, g_hCurrGameMode, g_hAllowScout;

bool g_bAllow, g_bPluginOn, g_bBlockExpl[MAXPLAYERS + 1], g_bAllowScout;

char g_sDamage[16], g_sRadius[16];

float g_fRadius, g_fDamageFriend, g_fDamage;

public Plugin myinfo =
{
	name = "[L4D2] Explosive AWP and Scout bullets",
	author = "Eärendil",
	description = "AWP and Scout bullets explode on impact.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2747814#post2747814",
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() == Engine_Left4Dead2)
		return APLRes_Success;
		
	strcopy(error, err_max, "This plugin only supports Left 4 Dead 2.");
	return APLRes_SilentFailure;
}

public void OnPluginStart()
{
	CreateConVar("l4d2_explosiveawp_version", PLUGIN_VERSION, "L4D2 Explosive AWP & Scout bullets Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hAllow			= CreateConVar("l4d2_explawp_enable", 			"1", 		"0 = Plugin off, 1 = Plugin on.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hGameModes		= CreateConVar("l4d2_explawp_gamemodes",		"",			"Enable the plugin in these gamemodes, separated by spaces. (Empty = all).", FCVAR_NOTIFY);
	g_hDamage			= CreateConVar("l4d2_explawp_damage",			"100",		"Max damage of the explosion.", FCVAR_NOTIFY, true, 0.0, true, 1000.0);	// Need to clamp damage and radius or entity will bug
	g_hRadius			= CreateConVar("l4d2_explawp_radius",			"0",		"Explosion radius override (16 units = 1 foot). If set to 0 radius will be proportional to damage.", FCVAR_NOTIFY, true, 0.0, true, 8000.0);
	g_hDamageFriend		= CreateConVar("l4d2_explawp_damage_friendly",	"15",		"Max explosion damage caused to survivors.", FCVAR_NOTIFY, true, 0.0);
	g_hAllowScout		= CreateConVar("l4d2_explawp_allow_scout",		"1",		"If set to 1 Scout will cause explosions too.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hCurrGameMode		= FindConVar("mp_gamemode");

	g_hAllow.AddChangeHook(CVarChange_Enable);
	g_hGameModes.AddChangeHook(CVarChange_Enable);
	g_hCurrGameMode.AddChangeHook(CVarChange_Enable);
	
	g_hDamage.AddChangeHook(CVarChange_CVars);
	g_hRadius.AddChangeHook(CVarChange_CVars);
	g_hDamageFriend.AddChangeHook(CVarChange_CVars);
	g_hAllowScout.AddChangeHook(CVarChange_CVars);
	AutoExecConfig(true, "l4d2_explosiveawp");
}

public void OnConfigsExecuted()
{
	SwitchPlugin();
	GetCVars();
}

public void CVarChange_Enable(Handle convar, const char[] oldValue, const char[] newValue)
{
	SwitchPlugin();
}

public void CVarChange_CVars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCVars();
}

void SwitchPlugin()
{
	g_bAllow = g_hAllow.BoolValue;
	if (g_bPluginOn == false && g_bAllow == true && GetGameMode() == true)
	{
		g_bPluginOn = true;
		HookEvent("bullet_impact", Event_Bullet_Impact);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
				SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
	if (g_bPluginOn == true && (g_bAllow == false || GetGameMode() == false))
	{
		g_bPluginOn = false;
		UnhookEvent("bullet_impact", Event_Bullet_Impact);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
				SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}

bool GetGameMode()
{
	if (g_hCurrGameMode == null)
		return false;

	char sGameModes[64], sGameMode[64];
	g_hCurrGameMode.GetString(sGameMode, sizeof(sGameMode));	// Store "mp_gamemode" result in sGameMode
	g_hGameModes.GetString(sGameModes, sizeof(sGameModes));		// Store all gamemodes that will start plugin in sGameModes
	Format(sGameMode, sizeof(sGameMode), " %s ", sGameMode);
	
	if (sGameModes[0])	// If string is not empty that means that server admin only wants plugin in some gamemodes
	{
		Format(sGameModes, sizeof(sGameModes), " %s ", sGameModes);
		if (StrContains(sGameModes, sGameMode, false) == -1)	// Check if the current gamemode is not in the list of allowed gamemodes
			return false;
	}
	return true;
}

void GetCVars()
{
	g_hDamage.GetString(g_sDamage, sizeof(g_sDamage));
	g_hRadius.GetString(g_sRadius, sizeof(g_sRadius));
	g_fDamage = g_hDamage.FloatValue;
	g_fDamageFriend = g_hDamageFriend.FloatValue;
	g_fRadius = g_hRadius.FloatValue;
	g_bAllowScout = g_hAllowScout.BoolValue;
}

public void OnClientPutInServer(int client)
{
	if (g_bPluginOn)		
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnClientDisconnect(int client)
{
	if (g_bPluginOn)
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnMapStart()
{
	PrecacheSound(SND_EXPL1, false);
	PrecacheSound(SND_EXPL2, false);
	PrecacheSound(SND_EXPL2, false);
}

public Action Event_Bullet_Impact(Event event, const char[] name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(event, "userid"));	// Get the player who shooted
	if (g_bBlockExpl[iClient] || IsFakeClient(iClient))	//Don`t allow bots to make explosions or they will explode everything
		return;

	char sWeaponName[32];
	GetClientWeapon(iClient, sWeaponName, sizeof(sWeaponName));	// Get the weapon used
	if (!StrEqual(sWeaponName, "weapon_sniper_awp", false) && !StrEqual(sWeaponName, "weapon_sniper_scout", false))
		return;
		
	if(StrEqual(sWeaponName, "weapon_sniper_scout", false) && !g_bAllowScout)
		return;

	// Fixes bug with miniguns
	if (IsUsingMountedWeapon(iClient))
		return;

	// Get where the shot was placed
	float vPos[3];
	vPos[0] = GetEventFloat(event, "x");
	vPos[1] = GetEventFloat(event, "y");
	vPos[2] = GetEventFloat(event, "z");
	
	// Create an env_explosion
	int entity = CreateEntityByName("env_explosion");
	TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValue(entity, "iMagnitude", g_sDamage);
	if (g_fRadius > 0.0) DispatchKeyValue(entity, "iRadiusOverride", g_sRadius);
	DispatchKeyValue(entity, "rendermode", "5");
	DispatchKeyValue(entity, "spawnflags", "128");	// Random orientation
	DispatchKeyValue(entity, "fireballsprite", "sprites/zerogxplode.spr");
	SetEntPropEnt(entity, Prop_Data, "m_hInflictor", iClient);	// Make the player who created the env_explosion the owner of it
	SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", iClient);
	
	DispatchSpawn(entity);
	
	SetVariantString("OnUser1 !self:Explode::0.01:1)");	// Add a delay to allow explosion effect to be visible
	AcceptEntityInput(entity, "Addoutput");
	AcceptEntityInput(entity, "FireUser1");
	// env_explosion is autodeleted after 0.3s while spawnflag repeteable is not added
	
	g_bBlockExpl[iClient] = true;
	CreateTimer(0.1, EnableShoot_Timer, iClient);
	
	// Play an explosion sound
	switch (GetRandomInt(1,3))
	{
		case 1: EmitAmbientSound(SND_EXPL1, vPos);
		case 2: EmitAmbientSound(SND_EXPL2, vPos);
		case 3: EmitAmbientSound(SND_EXPL2, vPos);
	}
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (!g_bPluginOn)
		return Plugin_Continue;
		
	if (GetClientTeam(victim) == 3)
		return Plugin_Continue;
		
	if (damagetype != 64 || weapon != -1)
		return Plugin_Continue;
	
	if (IsValidClient(attacker) && GetClientTeam(attacker) == 2)
	{
		float vPlayerPos[3], fDist;
		GetClientEyePosition(victim, vPlayerPos);
		vPlayerPos[2] -= 12;
		fDist = GetVectorDistance(vPlayerPos, damagePosition, false);

		if (g_fRadius > 0.0)
			damage = g_fDamageFriend - (g_fDamageFriend / g_fRadius) * fDist;
		
		else
			damage = g_fDamageFriend - 0.4 * g_fDamageFriend * fDist/g_fDamage;	// Decay of env explosion damage is: Maxdamage - (0.4 * distance to explosion) if radius is not specified
		
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

// Prevent multiple instances of env_explosion per bullet
public Action EnableShoot_Timer(Handle timer, int client)
{
	g_bBlockExpl[client] = false;
}

bool IsValidClient(int client)
{
	if (client < 1 || client > MaxClients)
		return false;
	if (!IsClientConnected(client))
		return false;
	return IsClientInGame(client);
}

// Thanks to HarryPotter for the bug report and the fix
bool IsUsingMountedWeapon(int client)
{
	if (GetEntProp(client, Prop_Send, "m_usingMountedWeapon") == 1)
		return true;
		
	return false;
}