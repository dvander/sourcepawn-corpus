#include <sourcemod>

#pragma semicolon 1

new Handle:cvarSpawnProtect;
new Handle:cvarProtectTime;

new clientProtected[MAXPLAYERS+1];
new clientHP[MAXPLAYERS+1];

//Chat Color Defines
#define cDefault 0x01
#define cLightGreen 0x03
#define cGreen 0x04
#define cDarkGreen 0x05

#define PLUGIN_VERSION "1.1"

public Plugin:myinfo = 
{
	name = "TF2 Spawn Protection",
	author = "Crimson, playboycyberclub",
	description = "Protects Player's on Spawn",
	version = PLUGIN_VERSION,
	url = "www.tf2rocketarena.com"
}

public OnPluginStart()
{
	CreateConVar("sm_spawnprotect_version", PLUGIN_VERSION, "Spawn Protection Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarSpawnProtect = CreateConVar("sm_spawnprotect_enable", "1.0", "Enable/Disable Spawn Protection");
	cvarProtectTime = CreateConVar("sm_spawnprotect_timer", "5.0", "Length of Time to Protect Spawned Players");
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_hurt", Event_PlayerHurt);	
} 

public Event_PlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{
	if (GetConVarFloat(cvarSpawnProtect))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		CreateTimer(0.1, timer_GetHealth, GetClientUserId (client));
		
		//Enable Protection on the Client
		clientProtected[client] = 1;
		
		CreateTimer(GetConVarFloat(cvarProtectTime), timer_PlayerProtect, GetClientUserId (client));
	}
}

//Get the Player's Health After they Spawn
public Action:timer_GetHealth(Handle:timer, any:userid)
{
	new client = GetClientOfUserId (userid);
	
	if (Client_IsValid (client) && IsClientInGame(client)) 
	{
		//Get the Player's Health on Spawning
		if(IsClientConnected(client) && IsClientInGame(client))
		{
			clientHP[client] = GetClientHealth(client);
		}
	}
}

//Player Protection Expires
public Action:timer_PlayerProtect(Handle:timer, any:userid)
{
	new client = GetClientOfUserId (userid);
	
	if (Client_IsValid (client) && IsClientInGame(client)) 
	{
		//Disable Protection on the Client
		clientProtected[client] = false;
		
		PrintHintText(client, "[WARNING] Spawn Protection is now OFF!");
		
	}
}

//If they take Damage during Protection Round, Restore their Health
public Event_PlayerHurt(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (clientProtected[client] == 1)
	{
		SetEntData(client, FindDataMapInfo(client, "m_iMaxHealth"), clientHP[client], 4, true);
		SetEntData(client, FindDataMapInfo(client, "m_iHealth"), clientHP[client], 4, true);
	}
}

stock bool:Client_IsValid (client, bool:checkConnected=true) 
{
	if ( client > 4096 ) 
	{
		client = EntRefToEntIndex (client);
	}
	
	if (client < 1 || client > MaxClients) 
	{
		return false;
	}
	
	if (! (1 <= client <= MaxClients) || ! IsClientInGame (client)) 
	{
		return false;
	}
	
	if (checkConnected && ! IsClientConnected (client)) 
	{
		return false;
	}
	
	return true;
}
