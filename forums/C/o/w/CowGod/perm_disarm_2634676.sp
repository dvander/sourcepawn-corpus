#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "CodingCow"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "perm_disarm",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

Handle g_hCookie;
bool g_bDisarmed[MAXPLAYERS + 1];

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	RegAdminCmd("sm_disarm", disarmPlayer, ADMFLAG_BAN);
	
	g_hCookie = RegClientCookie("disarm_player", "Disarms Player", CookieAccess_Private);
}

public void OnClientPutInServer(int client)
{
	g_bDisarmed[client] = false;
}

public void OnClientCookiesCached(int client)
{
	if(IsValidClient(client))
	{
		char sValue[8];
		
		GetClientCookie(client, g_hCookie, sValue, sizeof(sValue));
		g_bDisarmed[client] = StringToInt(sValue);
	}
}

public Action disarmPlayer(int client, int args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_disarm <#userid|name>");
		return Plugin_Handled;
	}
	
	char arg[128];
	GetCmdArg(1, arg, sizeof(arg));
	
	int target = FindTarget(client, arg, true, false);
	
	if(!IsValidClient(target))
	{
		PrintToChat(client, "[\x02Disarm\x01] Not a valid target!");
		return Plugin_Handled;
	}
	
	char sValue[8];
	
	IntToString(g_bDisarmed[target], sValue, sizeof(sValue));
	g_bDisarmed[target] = !g_bDisarmed[target];
	SetClientCookie(target, g_hCookie, sValue);
	
	return Plugin_Handled;
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    
    if(IsValidClient(client) && g_bDisarmed[client])
    {
   		StripWeapons(client);
  	}
}

void StripWeapons(int target)
{
	int weapon = -1;
	for (int i = 0; i <= 5; i++)
	{
	    if ((weapon = GetPlayerWeaponSlot(target, i)) != -1)
	    {
	        RemovePlayerItem(target, weapon);
	    }
	}
}


bool IsValidClient(int client, bool bAllowBots = false, bool bAllowDead = true)
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!bAllowDead && !IsPlayerAlive(client)))
	{
		return false;
	}
	return true;
}