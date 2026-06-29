#include <sourcemod>
#pragma semicolon 1
#define PLUGIN_VERSION "1.2.1"

#define ZOEY 0
#define LOUIS 1
#define FRANCIS 2
#define BILL 3
#define ROCHELLE 4
#define COACH 5
#define ELLIS 6
#define NICK 7


public Plugin:myinfo =
{
	name = "L4D Black and White Notifier",
	author = "DarkNoghri, madcap",
	description = "Notify people when player is black and white.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
};

new Handle:h_cvarNoticeType=INVALID_HANDLE;
new Handle:h_cvarPrintType=INVALID_HANDLE;
new bandw_notice;
new bandw_type;
new bool:status[8];

public OnPluginStart()
{
	//create version convar
	CreateConVar("l4d_blackandwhite_version", PLUGIN_VERSION, "Version of L4D Black and White Notifier", FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	//hook some events
	HookEvent("revive_success", EventReviveSuccess);
	HookEvent("heal_success", EventHealSuccess);
	HookEvent("player_death", EventPlayerDeath);
	
	//create option convars
	h_cvarNoticeType = CreateConVar("l4d_bandw_notice", "1", "0 turns notifications off, 1 notifies survivors, 2 notifies all.", FCVAR_PLUGIN, true, 0, true, 2.0);
	h_cvarPrintType = CreateConVar("l4d_bandw_type", "1", "0 prints to chat, 1 displays hint box.", FCVAR_PLUGIN, true, 0, true, 1.0);
	
	//read values from convars initially
	bandw_notice = GetConVarInt(h_cvarNoticeType);
	bandw_type = GetConVarInt(h_cvarPrintType);
	
	//hook changes to those convars
	HookConVarChange(h_cvarNoticeType, ChangeNoticeVar);
	HookConVarChange(h_cvarPrintType, ChangeTypeVar);
}

public EventReviveSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetEventBool(event, "lastlife"))
	{
		new target = GetClientOfUserId(GetEventInt(event, "subject"));
		decl String:targetName[64];
		decl String:targetModel[128]; 
		decl String:charName[32];
		
		if(target == 0) return Plugin_Continue;
		
		//get client name and model
		GetClientName(target, targetName, sizeof(targetName));
		GetClientModel(target, targetModel, sizeof(targetModel));
		
		//fill string with character names
		if(StrContains(targetModel, "teenangst", false) > 0) 
		{
			strcopy(charName, sizeof(charName), "Zoey");
			status[ZOEY] = true;
		}
		else if(StrContains(targetModel, "biker", false) > 0)
		{
			strcopy(charName, sizeof(charName), "Francis");
			status[FRANCIS] = true;
		}
		else if(StrContains(targetModel, "manager", false) > 0)
		{
			strcopy(charName, sizeof(charName), "Louis");
			status[LOUIS] = true;
		}
		else if(StrContains(targetModel, "namvet", false) > 0)
		{
			strcopy(charName, sizeof(charName), "Bill");
			status[BILL] = true;
		}
		else if(StrContains(targetModel, "producer", false) > 0)
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
		if(bandw_notice == 0) return Plugin_Continue;
		
		//print to all
		else if(bandw_notice == 2) 
		{
			if(bandw_type == 1) PrintHintTextToAll("%s (\x04%s\x01) is black and white.", targetName, charName);
			else PrintToChatAll("%s (\x04%s\x01) is black and white.", targetName, charName);
		}
		//print to team
		else
		{
			for( new x = 1; x <= GetMaxClients(); x++)
			{
				if(!IsClientInGame(x) || GetClientTeam(x) != GetClientTeam(target) || x == target || IsFakeClient(x)) 
					continue;
					
				if(bandw_type == 1) PrintHintText(x, "%s (\x04%s\x01) is black and white.", targetName, charName);
				else PrintToChat(x, "%s (\x04%s\x01) is black and white.", targetName, charName);
			}
		}	
	}
	return Plugin_Continue;
}

public EventHealSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	new healeeID = GetEventInt(event, "subject");
	new healee = GetClientOfUserId(healeeID);
	
	if(healee == 0) return Plugin_Continue;
	
	decl String:healeeModel[128]; 
	GetClientModel(healee, healeeModel, sizeof(healeeModel));
	
	//fill string with character names
	if(StrContains(healeeModel, "teenangst", false) > 0) 
	{
		if(status[ZOEY]) status[ZOEY] = false;
	}
	else if(StrContains(healeeModel, "biker", false) > 0)
	{
		status[FRANCIS] = false;
	}
	else if(StrContains(healeeModel, "manager", false) > 0)
	{
		status[LOUIS] = false;
	}
	else if(StrContains(healeeModel, "namvet", false) > 0)
	{
		status[BILL] = false;
	}
	else if(StrContains(healeeModel, "producer", false) > 0) 
	{
		status[ROCHELLE] = false;
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
	
	return Plugin_Continue;
}

public EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new deadID = GetEventInt(event, "userid");
	new dead = GetClientOfUserId(deadID);
	
	if(dead == 0) return Plugin_Continue;
	
	decl String:deadModel[128]; 
	GetClientModel(dead, deadModel, sizeof(deadModel));
	
	//fill string with character names
	if(StrContains(deadModel, "teenangst", false) > 0) 
	{
		if(status[ZOEY]) status[ZOEY] = false;
	}
	else if(StrContains(deadModel, "biker", false) > 0)
	{
		status[FRANCIS] = false;
	}
	else if(StrContains(deadModel, "manager", false) > 0)
	{
		status[LOUIS] = false;
	}
	else if(StrContains(deadModel, "namvet", false) > 0)
	{
		status[BILL] = false;
	}
	else if(StrContains(deadModel, "producer", false) > 0)
	{
		status[ROCHELLE] = false;
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
	
	return Plugin_Continue;
}

//could possibly get away with hooking player_bot_replace and bot_player_replace for names?
//failing that, hook player_team?

//get cvar changes during game
public ChangeNoticeVar(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	bandw_notice = StringToInt(newVal);
}

public ChangeTypeVar(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	bandw_type = StringToInt(newVal);
}