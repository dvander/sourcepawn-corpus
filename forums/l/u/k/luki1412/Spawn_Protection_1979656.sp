#include <sourcemod>

#pragma semicolon 1

new Handle:cvarSpawnProtect;
new Handle:cvarAnnounce;
new Handle:cvarProtectTime;

new clientProtected[MAXPLAYERS+1];
new clientHP[MAXPLAYERS+1];

//Chat Color Defines
#define cDefault 0x01
#define cLightGreen 0x03
#define cGreen 0x04
#define cDarkGreen 0x05

#define PLUGIN_VERSION "1.1.0"

public Plugin:myinfo = 
{
	name = "TF2 Spawn Protection",
	author = "Crimson, UltIm4t3 Luk1",
	description = "Protects players on Spawn",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	CreateConVar("sm_spawnprotect_version", PLUGIN_VERSION, "Spawn Protection Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarSpawnProtect = CreateConVar("sm_spawnprotect_enable", "1.0", "Enable/Disable Spawn Protection", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarAnnounce = CreateConVar("sm_spawnprotect_announce", "1.0", "Enable/Disable Announcements", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarProtectTime = CreateConVar("sm_spawnprotect_timer", "10.0", "Length of Time to Protect Spawned Players", FCVAR_PLUGIN, true, 0.0, true, 30.0);
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_hurt", Event_PlayerHurt);	
} 

public Event_PlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{
	if (GetConVarFloat(cvarSpawnProtect))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new team = GetClientTeam(client); 
		
		if( client>0 && IsClientInGame(client) && IsPlayerAlive(client))
		{
			if (team == 3)
			{
				SetEntityRenderMode(client, RENDER_TRANSCOLOR);
				SetEntityRenderColor(client, 64, 128, 255, 255);
			}
			if (team == 2)
			{
				SetEntityRenderMode(client, RENDER_TRANSCOLOR);
				SetEntityRenderColor(client, 255, 128, 64, 255);
			}
			
			CreateTimer(0.1, timer_GetHealth, client);
			
			//Enable Protection on the Client
			clientProtected[client] = 1;
			
			CreateTimer(GetConVarFloat(cvarProtectTime), timer_PlayerProtect, client);
		}
	}
}

//Get the Player's Health After they Spawn
public Action:timer_GetHealth(Handle:timer, any:client)
{
	//Get the Player's Health on Spawning
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		clientHP[client] = GetClientHealth(client);
	}
}

//Player Protection Expires
public Action:timer_PlayerProtect(Handle:timer, any:client)
{
	//Disable Protection on the Client	
	if (IsClientInGame(client) )
	{
		clientProtected[client] = 0;
		if(IsPlayerAlive(client)){
			SetEntityRenderMode(client, RENDER_NORMAL);
			SetEntityRenderColor(client, 255, 255, 255, 255);
		}
	}
	
	if (GetConVarFloat(cvarAnnounce) && IsClientInGame(client) && !IsFakeClient(client) && IsPlayerAlive(client))
		PrintToChat(client, "%c[SpawnProtect] %cYour Spawn Protection is now DISABLED", cLightGreen, cDefault);
}

//If they take Damage during Protection Round, Restore their Health
public Event_PlayerHurt(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (clientProtected[client] == 1)
	{
		SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), clientHP[client], 4, true);
		SetEntData(client, FindDataMapOffs(client, "m_iHealth"), clientHP[client], 4, true);
	}
}
