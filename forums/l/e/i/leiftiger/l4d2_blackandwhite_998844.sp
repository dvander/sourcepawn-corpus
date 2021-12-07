#pragma semicolon 1
#define PLUGIN_VERSION "1.11"
#include <sourcemod>

#define ROCHELLE 0
#define COACH 1
#define ELLIS 2
#define NICK 3


public Plugin:myinfo =
{
	name = "[L4D2] Black and White Notifier",
	author = "DarkNoghri, madcap, L4D2 by leiftiger",
	description = "Notify people when player is black and white.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
};

new Handle:h_cvarNoticeType=INVALID_HANDLE;
new bandw_notice;
new bool:status[4];

public OnPluginStart()
{
	CreateConVar("l4d2_blackandwhite_version", PLUGIN_VERSION, "Version of L4D Black and White Notifier", FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEvent("revive_success", EventReviveSuccess);
	HookEvent("heal_success", EventHealSuccess);
	HookEvent("player_death", EventPlayerDeath);
	h_cvarNoticeType = CreateConVar("l4d_bandw_notice", "1", "0 turns notifications off, 1 notifies survivors, 2 notifies all.", FCVAR_PLUGIN, true, 0, true, 2.0);
	bandw_notice = GetConVarInt(h_cvarNoticeType);
	HookConVarChange(h_cvarNoticeType, ChangeNoticeVar);
	LoadTranslations("blackandwhite.phrases");
}

public EventReviveSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
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
		if(StrContains(targetModel, "producer", false) > 0) 
		{
			strcopy(charName, sizeof(charName), "Rochelle");
			status[ROCHELLE] = true;
		}
		else if(StrContains(targetModel, "mechanic", false) > 0)
		{
			strcopy(charName, sizeof(charName), "Ellis");
			status[ELLIS] = true;
		}
		else if(StrContains(targetModel, "coach", false) > 0)
		{
			strcopy(charName, sizeof(charName), "Coach");
			status[COACH] = true;
		}
		else if(StrContains(targetModel, "gambler", false) > 0)
		{
			strcopy(charName, sizeof(charName), "Nick");
			status[NICK] = true;
		}
		else{
			strcopy(charName, sizeof(charName), "Unknown");
		}
		
		//turned off
		if(bandw_notice == 0) return;
		
		//print to all
		else if(bandw_notice == 2) 
			PrintHintTextToAll("%t", "BLACKWHITE_MODEL_NAME", targetName, charName);
		
		//print to team
		else
		{
			for( new x = 1; x <= GetMaxClients(); x++)
			{
				if(!IsClientInGame(x) || GetClientTeam(x) != GetClientTeam(target) || x == target || IsFakeClient(x)) 
					continue;
					if(StrEqual(charName, targetName, false))
					{
				PrintHintText(x, "%t", "BLACKWHITE_NAME", targetName);
					}
					else
					{
				PrintHintText(x, "%t", "BLACKWHITE_MODEL_NAME", targetName, charName);
					}
			}
		}	
	}
}

public EventHealSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	new healeeID = GetEventInt(event, "subject");
	new healee = GetClientOfUserId(healeeID);
	
	decl String:healeeModel[128]; 
	GetClientModel(healee, healeeModel, sizeof(healeeModel));
	
	//fill string with character names
	if(StrContains(healeeModel, "producer", false) > 0) 
	{
		if(status[ROCHELLE]) status[ROCHELLE] = false;
	}
	else if(StrContains(healeeModel, "mechanic", false) > 0)
	{
		status[ELLIS] = false;
	}
	else if(StrContains(healeeModel, "coach", false) > 0)
	{
		status[COACH] = false;
	}
	else if(StrContains(healeeModel, "gambler", false) > 0)
	{
		status[NICK] = false;
	}
}

public EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new deadID = GetEventInt(event, "userid");
	new dead = GetClientOfUserId(deadID);
	
	if(dead == 0) return Plugin_Continue;
	
	decl String:deadModel[128]; 
	GetClientModel(dead, deadModel, sizeof(deadModel));
	
	//fill string with character names
	if(StrContains(deadModel, "producer", false) > 0) 
	{
		if(status[ROCHELLE]) status[ROCHELLE] = false;
	}
	else if(StrContains(deadModel, "mechanic", false) > 0)
	{
		status[ELLIS] = false;
	}
	else if(StrContains(deadModel, "coach", false) > 0)
	{
		status[COACH] = false;
	}
	else if(StrContains(deadModel, "gambler", false) > 0)
	{
		status[NICK] = false;
	}
}

//could possibly get away with hooking player_bot_replace and bot_player_replace for names?
//failing that, hook player_team?

//get cvar changes during game
public ChangeNoticeVar(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	bandw_notice = StringToInt(newVal);
}