#pragma semicolon 1
#define PLUGIN_VERSION "1.0"
#include <sourcemod>

public Plugin:myinfo =
{
	name = "[L4D] Black and White Notifier",
	author = "DarkNoghri, madcap",
	description = "Notify everyone when player is black and white.",
	version = "PLUGIN_VERSION",
	url = "http://www.sourcemod.net"
};

new Handle:cvarNoticeType=INVALID_HANDLE;
new g_maxplayers;
new g_bandw_notice;

public OnPluginStart()
{
	CreateConVar("l4d_blackandwhite_version", PLUGIN_VERSION, "Version of L4D Black and White Notifier", FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEvent("revive_success", EventReviveSuccess);
	cvarNoticeType = CreateConVar("l4d_bandw_notice", "0", "0 notifies team only, 1 notifies all, 2 is off.", FCVAR_PLUGIN, true, 0, true, 2.0);
	g_maxplayers = GetMaxClients();
	g_bandw_notice = GetConVarInt(cvarNoticeType);
	HookConVarChange(cvarNoticeType, ChangeNoticeVar);
}

public EventReviveSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	//turned off
	if(g_bandw_notice == 2) return;
	//turned on
	if(GetEventBool(event, "lastlife"))
	{
		new target = GetClientOfUserId(GetEventInt(event, "subject"));
		decl String:targetName[64];
		decl String:targetModel[128]; 
		decl String:charName[32];
		
		//get client name and model
		GetClientName(target, targetName, sizeof(targetName));
		GetClientModel(target, targetModel, sizeof(targetModel));
		
		//fill string with character names
		if(StrContains(targetModel, "teenangst", false) > 0) 
		{
			strcopy(charName, sizeof(charName), "Zoey");
		}
		else if(StrContains(targetModel, "biker", false) > 0)
		{
			strcopy(charName, sizeof(charName), "Francis");
		}
		else if(StrContains(targetModel, "manager", false) > 0)
		{
			strcopy(charName, sizeof(charName), "Louis");
		}
		else if(StrContains(targetModel, "namvet", false) > 0)
		{
			strcopy(charName, sizeof(charName), "Bill");
		}
		else{
			strcopy(charName, sizeof(charName), "Unknown");
		}
		//print to all
		if(g_bandw_notice == 1) 
			PrintToChatAll("%s (\x04%s\x01) is black and white.", targetName, charName);
		//print to team
		else
		{
			for( new x = 1; x <= g_maxplayers; x++)
			{
				if(!IsClientInGame(x) || GetClientTeam(x) != GetClientTeam(target) || x == target) 
					continue;
				PrintToChat(x, "%s (\x04%s\x01) is black and white.", targetName, charName);
			}
		}	
	}
}

//get cvar changes during game
public ChangeNoticeVar(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_bandw_notice = StringToInt(newVal);
}