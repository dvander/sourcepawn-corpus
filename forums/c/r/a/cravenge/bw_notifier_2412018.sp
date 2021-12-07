#include <sourcemod>
#pragma semicolon 1

#define PLUGIN_VERSION "1.2"

#define ZOEY 5
#define LOUIS 7
#define FRANCIS 6
#define BILL 4
#define ROCHELLE 1
#define COACH 2
#define ELLIS 3
#define NICK 0

public Plugin:myinfo =
{
	name = "Black and White Notifier",
	author = "DarkNoghri, madcap",
	description = "Notifies Players When Someone Goes Black And White.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
};

new GameMode;

new Handle:h_cvarNoticeType = INVALID_HANDLE;
new Handle:h_cvarPrintType = INVALID_HANDLE;
new Handle:h_cvarGlowEnable = INVALID_HANDLE;

new bandw_notice;
new bandw_type;
new bandw_glow;

new bool:status[8];

public OnPluginStart()
{
	GameCheck();
	
	CreateConVar("bw_notifier_version", PLUGIN_VERSION, "Black and White Notifier Version", FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	HookEvent("round_start", OnRoundStart);
	HookEvent("map_transition", OnRoundStart);
	HookEvent("player_transitioned", OnRoundStart);
	HookEvent("revive_success", OnReviveSuccess);
	HookEvent("heal_success", OnHealSuccess);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("witch_killed", OnWitchKilled);
	HookEvent("round_end", OnRoundEnd);
	
	h_cvarNoticeType = CreateConVar("bw_notifier_notice", "1", "Notifications Mode: 0=Off, 1=Own Team Only, 2=On, 3=Enemy Team Only", FCVAR_NOTIFY, true, 0.0, true, 3.0);
	h_cvarPrintType = CreateConVar("bw_notifier_type", "1", "Notifications Type: 0=Chat Text, 1=Hint Box", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_cvarGlowEnable = CreateConVar("bw_notifier_glow", "1", "Enable/Disable Glow", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	bandw_notice = GetConVarInt(h_cvarNoticeType);
	bandw_type = GetConVarInt(h_cvarPrintType);
	bandw_glow = GetConVarInt(h_cvarGlowEnable);
	
	HookConVarChange(h_cvarNoticeType, ChangeVars);
	HookConVarChange(h_cvarPrintType, ChangeVars);
	HookConVarChange(h_cvarGlowEnable, ChangeVars);
}

GameCheck()
{
	decl String:GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));
	if (StrEqual(GameName, "survival", false))
	{
		GameMode = 3;
	}
	else if (StrEqual(GameName, "versus", false) || StrEqual(GameName, "teamversus", false) || StrEqual(GameName, "scavenge", false) || StrEqual(GameName, "teamscavenge", false))
	{
		GameMode = 2;
	}
	else if (StrEqual(GameName, "coop", false) || StrEqual(GameName, "realism", false))
	{
		GameMode = 1;
	}
	else
	{
		GameMode = 0;
 	}
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GameMode != 1)
	{
		return;
	}
	
	for (new client=1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client) && GetClientTeam(client) == 2)
		{
			decl String:targetModel[128];
			GetClientModel(client, targetModel, sizeof(targetModel));
			
			if(GetEntProp(client, Prop_Send, "m_currentReviveCount") == GetConVarInt(FindConVar("survivor_max_incapacitated_count")))
			{
				if(bandw_glow)
				{
					SetEntProp(client, Prop_Send, "m_iGlowType", 3);
					SetEntProp(client, Prop_Send, "m_glowColorOverride", 16777215);
				}
				
				if(StrContains(targetModel, "teenangst", false) > 0) 
				{
					status[ZOEY] = true;
				}
				else if(StrContains(targetModel, "biker", false) > 0)
				{
					status[FRANCIS] = true;
				}
				else if(StrContains(targetModel, "manager", false) > 0)
				{
					status[LOUIS] = true;
				}
				else if(StrContains(targetModel, "namvet", false) > 0)
				{
					status[BILL] = true;
				}
				else if(StrContains(targetModel, "producer", false) > 0)
				{
					status[ROCHELLE] = true;
				}
				else if(StrContains(targetModel, "mechanic", false) > 0)
				{
					status[ELLIS] = true;
				}
				else if(StrContains(targetModel, "coach", false) > 0)
				{
					status[COACH] = true;
				}
				else if(StrContains(targetModel, "gambler", false) > 0)
				{
					status[NICK] = true;
				}
			}
			else
			{
				if(bandw_glow)
				{
					SetEntProp(client, Prop_Send, "m_iGlowType", 0);
					SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
				}
				
				if(StrContains(targetModel, "teenangst", false) > 0) 
				{
					status[ZOEY] = false;
				}
				else if(StrContains(targetModel, "biker", false) > 0)
				{
					status[FRANCIS] = false;
				}
				else if(StrContains(targetModel, "manager", false) > 0)
				{
					status[LOUIS] = false;
				}
				else if(StrContains(targetModel, "namvet", false) > 0)
				{
					status[BILL] = false;
				}
				else if(StrContains(targetModel, "producer", false) > 0)
				{
					status[ROCHELLE] = false;
				}
				else if(StrContains(targetModel, "mechanic", false) > 0)
				{
					status[ELLIS] = false;
				}
				else if(StrContains(targetModel, "coach", false) > 0)
				{
					status[COACH] = false;
				}
				else if(StrContains(targetModel, "gambler", false) > 0)
				{
					status[NICK] = false;
				}
			}
		}
	}
}

public Action:OnReviveSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	new target = GetClientOfUserId(GetEventInt(event, "subject"));
	
	if (GetEntProp(target, Prop_Send, "m_currentReviveCount") == GetConVarInt(FindConVar("survivor_max_incapacitated_count")))
	{
		decl String:victimName[64];
		decl String:targetModel[128];
		decl String:charName[32];
		
		if(target == 0 || !IsClientInGame(target) || GetClientTeam(target) != 2)
		{
			return;
		}
		
		GetClientName(target, victimName, sizeof(victimName));
		GetClientModel(target, targetModel, sizeof(targetModel));
		
		if(bandw_glow)
		{
			SetEntProp(target, Prop_Send, "m_iGlowType", 3);
			SetEntProp(target, Prop_Send, "m_glowColorOverride", 16777215);
		}
		
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
		else
		{
			strcopy(charName, sizeof(charName), "Unknown");
		}
		
		if(bandw_notice == 0)
		{
			return;
		}
		else if(bandw_notice == 2) 
		{
			if(bandw_type == 1)
			{
				PrintHintTextToAll("%s (\x04%s\x01) Is Holding On To Last Life!", victimName, charName);
			}
			else
			{
				PrintToChatAll("%s (\x04%s\x01) Is Holding On To Last Life!", victimName, charName);
			}
		}
		else if(bandw_notice == 3)
		{
			for(new x = 1; x <= GetMaxClients(); x++)
			{
				if(!IsClientInGame(x) || GetClientTeam(x) == GetClientTeam(target) || x == target || IsFakeClient(x))
				{
					continue;
				}
				
				if(bandw_type == 1)
				{
					PrintHintText(x, "%s (\x04%s\x01) Is Holding On To Last Life!", victimName, charName);
				}
				else
				{
					PrintToChat(x, "%s (\x04%s\x01) Is Holding On To Last Life!", victimName, charName);
				}
			}
		}
		else
		{
			for(new x = 1; x <= GetMaxClients(); x++)
			{
				if(!IsClientInGame(x) || GetClientTeam(x) != GetClientTeam(target) || x == target || IsFakeClient(x)) 
				{
					continue;
				}
				
				if(bandw_type == 1)
				{
					PrintHintText(x, "%s (\x04%s\x01) Is Holding On To Last Life!", victimName, charName);
				}
				else
				{
					PrintToChat(x, "%s (\x04%s\x01) Is Holding On To Last Life!", victimName, charName);
				}
			}
		}	
	}
	return;
}

public Action:OnHealSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	new healeeID = GetEventInt(event, "subject");
	new healee = GetClientOfUserId(healeeID);
	
	if(healee == 0 || !IsClientInGame(healee) || GetClientTeam(healee) != 2)
	{
		return;
	}
	
	SetEntProp(healee, Prop_Send, "m_currentReviveCount", 0);
	
	decl String:healeeModel[128]; 
	GetClientModel(healee, healeeModel, sizeof(healeeModel));
	
	if(bandw_glow)
	{
		SetEntProp(healee, Prop_Send, "m_iGlowType", 0);
		SetEntProp(healee, Prop_Send, "m_glowColorOverride", 0);
	}
	
	if(StrContains(healeeModel, "teenangst", false) > 0) 
	{
		status[ZOEY] = false;
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
	
	return;
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victimID = GetEventInt(event, "userid");
	new victim = GetClientOfUserId(victimID);
	if(victim == 0 || victim > MaxClients || !IsClientInGame(victim) || GetClientTeam(victim) != 2)
	{
		return;
	}
	
	if(bandw_glow)
	{
		SetEntProp(victim, Prop_Send, "m_iGlowType", 0);
		SetEntProp(victim, Prop_Send, "m_glowColorOverride", 0);
	}
	
	decl String:victimName[64];
	GetClientName(victim, victimName, sizeof(victimName));
	PrintHintTextToAll("%s Is Dead!", victimName);
	
	decl String:victimModel[128];
	GetClientModel(victim, victimModel, sizeof(victimModel));
	
	if(StrContains(victimModel, "teenangst", false) > 0)
	{
		status[ZOEY] = false;
	}
	else if(StrContains(victimModel, "biker", false) > 0)
	{
		status[FRANCIS] = false;
	}
	else if(StrContains(victimModel, "manager", false) > 0)
	{
		status[LOUIS] = false;
	}
	else if(StrContains(victimModel, "namvet", false) > 0)
	{
		status[BILL] = false;
	}
	else if(StrContains(victimModel, "producer", false) > 0)
	{
		status[ROCHELLE] = false;
	}
	else if(StrContains(victimModel, "mechanic", false) > 0)
	{
		status[ELLIS] = false;
	}
	else if(StrContains(victimModel, "coach", false) > 0)
	{
		status[COACH] = false;
	}
	else if(StrContains(victimModel, "gambler", false) > 0)
	{
		status[NICK] = false;
	}
	
	return;
}

public Action:OnWitchKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	new killer = GetClientOfUserId(GetEventInt(event, "userid"));
	if(killer == 0 || !IsClientInGame(killer) || GetClientTeam(killer) != 2 || !IsPlayerAlive(killer) || GetEntProp(killer, Prop_Send, "m_isIncapacitated", 1))
	{
		return;
	}
	
	if(bandw_glow)
	{
		SetEntProp(killer, Prop_Send, "m_iGlowType", 0);
		SetEntProp(killer, Prop_Send, "m_glowColorOverride", 0);
	}
	
	decl String:killerModel[128];
	GetClientModel(killer, killerModel, sizeof(killerModel));
	
	if(StrContains(killerModel, "teenangst", false) > 0)
	{
		status[ZOEY] = false;
	}
	else if(StrContains(killerModel, "biker", false) > 0)
	{
		status[FRANCIS] = false;
	}
	else if(StrContains(killerModel, "manager", false) > 0)
	{
		status[LOUIS] = false;
	}
	else if(StrContains(killerModel, "namvet", false) > 0)
	{
		status[BILL] = false;
	}
	else if(StrContains(killerModel, "producer", false) > 0)
	{
		status[ROCHELLE] = false;
	}
	else if(StrContains(killerModel, "mechanic", false) > 0)
	{
		status[ELLIS] = false;
	}
	else if(StrContains(killerModel, "coach", false) > 0)
	{
		status[COACH] = false;
	}
	else if(StrContains(killerModel, "gambler", false) > 0)
	{
		status[NICK] = false;
	}
	
	return;
}

public Action:OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GameMode != 2)
	{
		return;
	}
	
	CreateTimer(6.5, RemoveGlows);
}

public Action:RemoveGlows(Handle:timer)
{
	for (new client=1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			decl String:targetModel[128];
			GetClientModel(client, targetModel, sizeof(targetModel));
			
			if(bandw_glow)
			{
				SetEntProp(client, Prop_Send, "m_iGlowType", 0);
				SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
			}
			
			if(StrContains(targetModel, "teenangst", false) > 0) 
			{
				status[ZOEY] = false;
			}
			else if(StrContains(targetModel, "biker", false) > 0)
			{
				status[FRANCIS] = false;
			}
			else if(StrContains(targetModel, "manager", false) > 0)
			{
				status[LOUIS] = false;
			}
			else if(StrContains(targetModel, "namvet", false) > 0)
			{
				status[BILL] = false;
			}
			else if(StrContains(targetModel, "producer", false) > 0)
			{
				status[ROCHELLE] = false;
			}
			else if(StrContains(targetModel, "mechanic", false) > 0)
			{
				status[ELLIS] = false;
			}
			else if(StrContains(targetModel, "coach", false) > 0)
			{
				status[COACH] = false;
			}
			else if(StrContains(targetModel, "gambler", false) > 0)
			{
				status[NICK] = false;
			}
		}
	}
}

public ChangeVars(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	bandw_notice = GetConVarInt(h_cvarNoticeType);
	bandw_type = GetConVarInt(h_cvarPrintType);
	bandw_glow = GetConVarInt(h_cvarGlowEnable);
}

