#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

new Handle:g_hCVBurnTime;

new Handle:g_hExtinguishPlayer[MAXPLAYERS+1] = {INVALID_HANDLE,...};

public Plugin:myinfo = 
{
	name = "AWP Burner",
	author = "Jannik \"Peace-Maker\" Hartung",
	description = "Sets players hit by an awp on fire",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
	new Handle:hVersion = CreateConVar("sm_awpburner_version", PLUGIN_VERSION, "AWP Burner version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if(hVersion != INVALID_HANDLE)
		SetConVarString(hVersion, PLUGIN_VERSION);
	
	g_hCVBurnTime = CreateConVar("sm_awpburner_burntime", "5", "How many seconds should the player burn after being hit by an awp?", FCVAR_PLUGIN, true, 0.0);
	
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("player_hurt", Event_OnPlayerHurt);
}

public OnClientDisconnect(client)
{
	if(g_hExtinguishPlayer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hExtinguishPlayer[client]);
		g_hExtinguishPlayer[client] = INVALID_HANDLE;
	}
}

public Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	
	if(!client)
		return;
	
	// Extinguish him after spawn
	if(g_hExtinguishPlayer[client] != INVALID_HANDLE)
		TriggerTimer(g_hExtinguishPlayer[client]);
}

public Event_OnPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	
	if(!client)
		return;
	
	decl String:sWeapon[64];
	GetEventString(event, "weapon", sWeapon, sizeof(sWeapon));
	
	// Got shot by an AWP?
	if(StrEqual(sWeapon, "awp", false))
	{
		new Float:fBurnTime = GetConVarFloat(g_hCVBurnTime);
		
		// Plugin disabled?
		if(fBurnTime <= 0.0)
			return;
		
		// Ignite him
		IgniteEntity(client, fBurnTime);
		if(g_hExtinguishPlayer[client] != INVALID_HANDLE)
		{
			// He burned before?
			TriggerTimer(g_hExtinguishPlayer[client]);
		}
		// Make sure he's really extinguished after the set time.
		g_hExtinguishPlayer[client] = CreateTimer(fBurnTime, Timer_ExtinguishPlayer, userid, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_ExtinguishPlayer(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	
	if(!client)
		return Plugin_Stop;
	
	g_hExtinguishPlayer[client] = INVALID_HANDLE;
	
	ExtinguishEntity(client);
	
	return Plugin_Stop;
}