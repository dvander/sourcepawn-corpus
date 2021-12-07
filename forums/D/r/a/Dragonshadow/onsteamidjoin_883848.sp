#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdktools>

#define PLUGIN_VERSION  "1"

public Plugin:myinfo = 
{
	name = "OnSteamID",
	author = "Dragonshadow - A.K.A - Fire",
	description = "wat",
	version = PLUGIN_VERSION,
	url = "-none-"
}

new Handle:plugin_enable = INVALID_HANDLE;
new Handle:steamid = INVALID_HANDLE;

new enablehook = true;
new String:steamidhook[40];

public OnPluginStart()
{	
	CreateConVar("sm_onsteamid_version", PLUGIN_VERSION, "OnSteamID Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	plugin_enable = CreateConVar("sm_onsteamid_enable", "0", "Enable/Disable", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0 , true, 1.0);
	steamid = CreateConVar("sm_onsteamid_steamid", "", "SteamID To Use", FCVAR_PLUGIN|FCVAR_NOTIFY);

	HookConVarChange(plugin_enable, cvarchanged); 
	HookConVarChange(steamid, cvarchanged);

}

public OnConfigsExecuted() 
{
	enablehook = GetConVarInt(plugin_enable);
	GetConVarString(steamid, steamidhook, sizeof(steamidhook));
} 

public cvarchanged(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
	enablehook = GetConVarInt(plugin_enable);
	GetConVarString(steamid, steamidhook, sizeof(steamidhook));
} 

public OnClientPostAdminCheck(client)
{
	if(enablehook)
	{
		if (IsClientInGame(client))
		{
			decl String:szSteamID[40];
			GetClientAuthString(client, szSteamID, sizeof(szSteamID));  
			if (strcmp(szSteamID, steamidhook, false) == 0)
			{
				decl String:clientname[MAX_NAME_LENGTH];
				GetClientName(client, clientname, sizeof(clientname));
				ServerCommand("sm_say Admin %s has joined. Hoorah!", clientname);
			}
		}
	}
}

public OnClientDisconnect(client)
{
	if(enablehook)
	{
		if (IsClientInGame(client))
		{
			decl String:szSteamID[40];
			GetClientAuthString(client, szSteamID, sizeof(szSteamID));  
			if (strcmp(szSteamID, steamidhook, false) == 0)
			{
				decl String:clientname[MAX_NAME_LENGTH];
				GetClientName(client, clientname, sizeof(clientname));
				ServerCommand("sm_say Goodbye all", clientname);
			}
		}
	}
}