#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#undef REQUIRE_PLUGIN
#include <updater>
#define REQUIRE_PLUGIN

#pragma semicolon 1

#define PLUGIN_VERSION "1.2"
#define UPDATE_URL "http://sheepdude.silksky.com/sourcemod-plugins/raw/default/spslay.txt"

public Plugin:myinfo = 
{
	name = "Spawn Protect Slay for CS:S, CS:GO",
	author = "Sheepdude",
	description = "Provides spawn protection for players and slays teammates who shoot them.",
	version = PLUGIN_VERSION,
	url = "http://www.clan-psycho.com"
};

// Updater handles
new Handle:h_cvarUpdater;

// Convar handles
new Handle:h_cvarEnabled;
new Handle:h_cvarTime;
new Handle:h_cvarSlay;
new Handle:h_cvarRemoveOnFire;
new Handle:h_cvarChangeColor;
new Handle:h_cvarCT[4];
new Handle:h_cvarTR[4];

// Plugin handles
new Handle:h_Timers[MAXPLAYERS+1];

// Convar variables
new bool:g_cvarEnabled;
new Float:g_cvarTime;
new bool:g_cvarSlay;
new bool:g_cvarRemoveOnFire;
new bool:g_cvarChangeColor;
new g_cvarCT[4];
new g_cvarTR[4];

// Plugin variables
new bool:g_IsCSGO;

/******
 *Load*
*******/

public OnPluginStart()
{
	// Updater convar
	h_cvarUpdater = CreateConVar("sm_spslay_auto_update", "1", "Update plugin automatically if Updater is installed (1 - auto update, 0 - don't update", 0, true, 0.0, true, 1.0);
	
	// Public convar
	CreateConVar("sm_spslay_version", PLUGIN_VERSION, "Plugin version", FCVAR_CHEAT|FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);
	
	// Plugin convars
	h_cvarEnabled = CreateConVar("sm_spslay_enable", "1", "Enable spawn protection (1 - enable, 0 - disable)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_cvarTime = CreateConVar("sm_spslay_time", "10.0", "Sets the amount of seconds user's will be protected from getting killed on their respawn", FCVAR_NOTIFY, true, 0.0);
	h_cvarSlay = CreateConVar("sm_spslay_slay", "1", "Slay players who shoot spawn-protected teammates (1 - slay, 0 - don't slay)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_cvarRemoveOnFire = CreateConVar("sm_spslay_removeonfire", "0", "Removes spawn protection if player fires (1 - remove, 0 - don't remove)", 0, true, 0.0, true, 1.0);
	h_cvarChangeColor = CreateConVar("sm_spslay_changecolor", "1", "Change color on spawn protected players (1 - custom colors, 0 - don't change)", 0, true, 0.0, true, 1.0);
	h_cvarCT[0] = CreateConVar("sm_spslay_ctred", "0", "Red component of CT spawn protect color", 0, true, 0.0, true, 255.0);
	h_cvarCT[1] = CreateConVar("sm_spslay_ctgreen", "0", "Green component of CT spawn protect color", 0, true, 0.0, true, 255.0);
	h_cvarCT[2] = CreateConVar("sm_spslay_ctblue", "255", "Blue component of CT spawn protect color", 0, true, 0.0, true, 255.0);
	h_cvarCT[3] = CreateConVar("sm_spslay_ctalpha", "128", "Alpha component of CT spawn protect color", 0, true, 0.0, true, 255.0);
	h_cvarTR[0] = CreateConVar("sm_spslay_tred", "255", "Red component of T spawn protect color", 0, true, 0.0, true, 255.0);
	h_cvarTR[1] = CreateConVar("sm_spslay_tgreen", "0", "Green component of T spawn protect color", 0, true, 0.0, true, 255.0);
	h_cvarTR[2] = CreateConVar("sm_spslay_tblue", "0", "Blue component of T spawn protect color", 0, true, 0.0, true, 255.0);
	h_cvarTR[3] = CreateConVar("sm_spslay_talpha", "128", "Alpha component of T spawn protect color", 0, true, 0.0, true, 255.0);
	
	// Convar hooks
	HookConVarChange(h_cvarEnabled, OnConvarChanged);
	HookConVarChange(h_cvarTime, OnConvarChanged);
	HookConVarChange(h_cvarSlay, OnConvarChanged);
	HookConVarChange(h_cvarRemoveOnFire, OnConvarChanged);
	HookConVarChange(h_cvarChangeColor, OnConvarChanged);
	for(new i = 0; i <= 3; i++)
	{
		HookConVarChange(h_cvarTR[i], OnConvarChanged);
		HookConVarChange(h_cvarCT[i], OnConvarChanged);
	}
	
	// Discover if game is Counter-Strike: Global Offensive
	decl String:gameName[16];
	GetGameFolderName(gameName, sizeof(gameName));
	g_IsCSGO = StrEqual(gameName, "csgo");
	
	// Execute configuration file
	AutoExecConfig(true, "spslay");
	UpdateAllConvars();
	
	// Event hooks
	if(g_cvarEnabled)
		HookEvent("player_spawn", OnPlayerSpawn);
	if(g_cvarRemoveOnFire)
		HookEvent("weapon_fire", OnWeaponFire);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("Updater_AddPlugin");
	return APLRes_Success;
}

public OnAllPluginsLoaded()
{
	if(LibraryExists("updater"))
		Updater_AddPlugin(UPDATE_URL);	
}

public OnLibraryAdded(const String:name[])
{
	if(StrEqual(name, "updater"))
		Updater_AddPlugin(UPDATE_URL);
}

/*********
 *Updater*
**********/

public Action:Updater_OnPluginDownloading()
{
	if(!GetConVarBool(h_cvarUpdater))
		return Plugin_Handled;
	return Plugin_Continue;
}

public Updater_OnPluginUpdated()
{
	ReloadPlugin();
}

/**********
 *Forwards*
***********/

public OnConfigsExecuted()
{
	UpdateAllConvars();
}

/********
 *Events*
*********/

public OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_cvarTime != 0 && IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client) > 1)
		if(!g_IsCSGO || GetEntProp(client, Prop_Send, "m_bIsControllingBot") != 1)
			SpawnProtectClient(client);
}

public OnWeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidClient(client) || h_Timers[client] == INVALID_HANDLE)
		return;
	CloseHandle(h_Timers[client]);
	UnSpawnProtectClient(client);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(IsValidClient(attacker) && IsValidClient(victim) && h_Timers[victim] != INVALID_HANDLE)
	{
		damage = 0.0;
		if(g_cvarSlay && IsPlayerAlive(attacker) && victim != attacker && GetClientTeam(attacker) == GetClientTeam(victim))
			CreateTimer(0.0, SlayTimer, attacker, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

/*********
 *Helpers*
**********/

SpawnProtectClient(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	h_Timers[client] = CreateTimer(g_cvarTime, UnSpawnProtectClientTimer, client);
	if(g_cvarChangeColor)
	{
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		if(GetClientTeam(client) == 3)
			SetEntityRenderColor(client, g_cvarCT[0], g_cvarCT[1], g_cvarCT[2], g_cvarCT[3]);
		else
			SetEntityRenderColor(client, g_cvarTR[0], g_cvarTR[1], g_cvarTR[2], g_cvarTR[3]);
		ChangeEdictState(client);
	}
}

UnSpawnProtectClient(client)
{
	h_Timers[client] = INVALID_HANDLE;
	if (!IsPlayerAlive(client))
		return;
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	if(g_cvarChangeColor)
	{
		SetEntityRenderMode(client, RENDER_NORMAL);
		SetEntityRenderColor(client, 255, 255, 255, 255);
		ChangeEdictState(client);
	}
}

/********
 *Timers*
*********/

public Action:UnSpawnProtectClientTimer(Handle:Timer, any:client)
{
	UnSpawnProtectClient(client);
	return Plugin_Handled;
}

public Action:SlayTimer(Handle:timer, any:client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		ForcePlayerSuicide(client);
		PrintToChat(client, "\x01\x0B\x04[Spawn Protect]\x01 Be careful in spawn!");
	}
}

/*********
 *Convars*
**********/

UpdateAllConvars()
{
	g_cvarEnabled = GetConVarBool(h_cvarEnabled);
	g_cvarTime = GetConVarFloat(h_cvarTime);
	g_cvarSlay = GetConVarBool(h_cvarSlay);
	g_cvarChangeColor = GetConVarBool(h_cvarChangeColor);
	g_cvarRemoveOnFire = GetConVarBool(h_cvarRemoveOnFire);
	for(new i = 0; i <= 3; i++)
	{
		g_cvarCT[i] = GetConVarInt(h_cvarCT[i]);
		g_cvarTR[i] = GetConVarInt(h_cvarTR[i]);
	}
}

public OnConvarChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if(cvar == h_cvarEnabled)
	{
		g_cvarEnabled = GetConVarBool(h_cvarEnabled);
		if(g_cvarEnabled)
			HookEvent("player_spawn", OnPlayerSpawn);
		else
			UnhookEvent("player_spawn", OnPlayerSpawn);
	}
	else if(cvar == h_cvarTime)
		g_cvarTime = GetConVarFloat(h_cvarTime);
	else if(cvar == h_cvarSlay)
		g_cvarSlay = GetConVarBool(h_cvarSlay);
	else if(cvar == h_cvarRemoveOnFire)
	{
		g_cvarRemoveOnFire = GetConVarBool(h_cvarRemoveOnFire);
		if (g_cvarRemoveOnFire)
			HookEvent("weapon_fire", OnWeaponFire);
		else
			UnhookEvent("weapon_fire", OnWeaponFire);
	}
	else if(cvar == h_cvarChangeColor)
		g_cvarChangeColor = GetConVarBool(h_cvarChangeColor);
	for(new i = 0; i <= 3; i++)
	{
		if(cvar == h_cvarCT[i])
			g_cvarCT[i] = GetConVarInt(h_cvarCT[i]);
		else if(cvar == h_cvarTR[i])
			g_cvarTR[i] = GetConVarInt(h_cvarTR[i]);
	}
}

/********
 *Stocks*
*********/

stock IsValidClient(client)
{
	if(client > 0 && client <= MaxClients && IsClientInGame(client))
		return true;
	return false;
}