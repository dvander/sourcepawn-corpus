/***************************************************************************************** 
* Black and White Notifier (L4D/L4D2)
* Author(s): DarkNoghri, madcap (recoded by: retsam)
* Date: 3/12/2011
* File: l4d_blackandwhite_ret.sp
* Description: Notify people when player is black and white.
******************************************************************************************
* 
* 1.6r - Couple small edits that arnt worth mentioning. (Wait, I think I just mentioned them? : /)
* 1.5r - Edited messages slightly.
* 1.4r	- Initial recode.
*/

#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.6r"

#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

new Handle:Cvar_BWNotify_Enabled = INVALID_HANDLE;
new Handle:Cvar_BWNotify_GlowEnabled = INVALID_HANDLE;
new Handle:Cvar_BWNotify_Type = INVALID_HANDLE;
new Handle:Cvar_BWNotify_Mode = INVALID_HANDLE;

new g_cvarGlow;
new g_cvarType;
new g_cvarMode;

new bool:g_bPlayerGlowed[MAXPLAYERS+1] = { false, ... };
new bool:g_bIsEnabled = true;

public Plugin:myinfo = 
{
	name = "[L4D] Black and White Notifier",
	author = "DarkNoghri, madcap (recoded by: retsam)",
	description = "Notify people when player is black and white.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showpost.php?p=1438810&postcount=68"
}

public OnPluginStart()
{
	CreateConVar("sm_bwnotice_version", PLUGIN_VERSION, "Version of black and white notification plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	Cvar_BWNotify_Enabled = CreateConVar("sm_bwnotice_enabled", "1", "Enable black and white notification plugin?(1/0 = yes/no)");
	Cvar_BWNotify_GlowEnabled = CreateConVar("sm_bwnotice_glow", "1", "Enable making black white players glow?(1/0 = yes/no)");
	Cvar_BWNotify_Type = CreateConVar("sm_bwnotice_noticetype", "0", "Type to use for notification. (0=chat, 1=hint text)");
	Cvar_BWNotify_Mode = CreateConVar("sm_bwnotice_mode", "0", "Method of notification. (0=survivors only, 1=infected only, 2=all players)");

	HookEvent("revive_success", Hook_ReviveSuccess);
	HookEvent("heal_success", Hook_HealSuccess);
	HookEvent("player_death", Hook_PlayerDeath);
	HookEvent("player_spawn", Hook_PlayerSpawn);
	
	HookConVarChange(Cvar_BWNotify_Enabled, Cvars_Changed);
	HookConVarChange(Cvar_BWNotify_GlowEnabled, Cvars_Changed);
	HookConVarChange(Cvar_BWNotify_Type, Cvars_Changed);
	HookConVarChange(Cvar_BWNotify_Mode, Cvars_Changed);
	
	AutoExecConfig(true, "plugin.bwnotifier");
}

public OnConfigsExecuted()
{
	g_bIsEnabled = GetConVarBool(Cvar_BWNotify_Enabled);
	g_cvarGlow = GetConVarInt(Cvar_BWNotify_GlowEnabled);
	g_cvarType = GetConVarInt(Cvar_BWNotify_Type);
	g_cvarMode = GetConVarInt(Cvar_BWNotify_Mode);
}

public OnClientPostAdminCheck(client)
{
	g_bPlayerGlowed[client] = false;
}

public OnClientDisconnect(client)
{
	g_bPlayerGlowed[client] = false;
}

public Hook_ReviveSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bIsEnabled)
	return;

	if(GetEventBool(event, "lastlife"))
	{
		//PrintToChatAll("Hook_Revive: Lastlife reached");
		new target = GetClientOfUserId(GetEventInt(event, "subject"));
		
		if(target < 1)
		return;
		
		decl String:targetModel[128]; 
		decl String:charName[32];
		
		GetClientModel(target, targetModel, sizeof(targetModel));
		//PrintToChatAll("%N model is: %s", target, targetModel);
		
		if(g_cvarGlow)
		{
			g_bPlayerGlowed[target] = true;
			//PrintToChatAll("%d",GetEntProp(target, Prop_Send, "m_glowColorOverride"));	//normally 0. cant be overwritten?
			SetEntProp(target, Prop_Send, "m_iGlowType", 3);
			SetEntProp(target, Prop_Send, "m_glowColorOverride", 16777215);
		}
		
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
		else if(StrContains(targetModel, "producer", false) > 0)
		{
			strcopy(charName, sizeof(charName), "Rochelle");
		}
		else if(StrContains(targetModel, "mechanic", false) > 0)
		{
			strcopy(charName, sizeof(charName), "Ellis");
		}
		else if(StrContains(targetModel, "coach", false) > 0)
		{
			strcopy(charName, sizeof(charName), "Coach");
		}
		else if(StrContains(targetModel, "gambler", false) > 0)
		{
			strcopy(charName, sizeof(charName), "Nick");
		}
		else
    {
			strcopy(charName, sizeof(charName), "Unknown");
		}
		
		switch(g_cvarMode)
		{
		case 0: //Survivors
			{
				for(new x = 1; x <= MaxClients; x++)
				{
					//if(!IsClientInGame(x) || GetClientTeam(x) != TEAM_SURVIVOR || x == target || IsFakeClient(x))
					if(!IsClientInGame(x) || GetClientTeam(x) != TEAM_SURVIVOR || IsFakeClient(x))
					{
						continue;
					}
					
					if(g_cvarType == 0)
					{
						PrintToChat(x, "\x01\x04[B&W] \x03%N \x01(%s) is Black&White and needs help!", target, charName);
					}
					else
					{
						PrintHintText(x, "%N (%s) is black and white!", target, charName);
					}
				}	
			}
		case 1: //Infected
			{
				for(new x = 1; x <= MaxClients; x++)
				{
					if(!IsClientInGame(x) || GetClientTeam(x) != TEAM_INFECTED || IsFakeClient(x))
					{
						continue;
					}
					
					if(g_cvarType == 0)
					{
						PrintToChat(x, "\x01\x04[B&W] \x03%N \x01(%s) is Black&White, take them out!", target, charName);
					}
					else
					{
						PrintHintText(x, "%N (%s) is black and white!", target, charName);
					}
				}
			}
		case 2:
			{
				if(g_cvarType == 0)
				{
					PrintToChatAll("\x01\x04[B&W] \x03%N \x01(%s) is Black&White and in danger of dying!", target, charName);
				}
				else
				{
					PrintHintTextToAll("%N (%s) is black and white!", target, charName);
				}
			}
		}
	}
}

public Hook_HealSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bIsEnabled)
	return;

	new healee = GetClientOfUserId(GetEventInt(event, "subject"));
	new healer = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(healee < 1)
	return;
	
	if(g_bPlayerGlowed[healee])
	{	
		g_bPlayerGlowed[healee] = false;
		SetEntProp(healee, Prop_Send, "m_iGlowType", 0);
		SetEntProp(healee, Prop_Send, "m_glowColorOverride", 0);		//16777215 white?
		
		for(new x = 1; x <= MaxClients; x++)
		{
			if(!IsClientInGame(x) || GetClientTeam(x) != TEAM_SURVIVOR || IsFakeClient(x))
			{
				continue;
			}
			
			if(g_cvarType == 0)
			{
				if(healee != healer)
				{
					PrintToChat(x, "\x01\x04[B&W] \x03%N \x01was healed by \x03%N \x01and is no longer Black&White! Thanks!", healee, healer);
				}
				else
				{
					PrintToChat(x, "\x01\x04[B&W] \x03%N \x01healed themselves and is no longer Black&White!", healee);
				}
			}
			else
			{
				if(healee != healer)
				{
					PrintHintText(x, "%N was healed by %N and is no longer black and white!", healee, healer);
				}
				else
				{
					PrintHintText(x, "%N healed themselves and is no longer black and white!", healee);
				}
			}
		}
	}
}

public Hook_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bIsEnabled)
	return;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client < 1)
	return;
	
	if(g_bPlayerGlowed[client])
	{
		g_bPlayerGlowed[client] = false;
		SetEntProp(client, Prop_Send, "m_iGlowType", 0);
		SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
	}
}

public Hook_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bIsEnabled)
	return;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client < 1 || !IsPlayerAlive(client))
	return;
	
	new team = GetClientTeam(client);
	if(team != TEAM_SURVIVOR)
	return;
	
	if(g_bPlayerGlowed[client])
	{
		g_bPlayerGlowed[client] = false;
		SetEntProp(client, Prop_Send, "m_iGlowType", 0);
		SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
	}
}

public Cvars_Changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == Cvar_BWNotify_Enabled)
	{
		if(StringToInt(newValue) == 0)
		{
			g_bIsEnabled = false;
		}
		else
		{
			g_bIsEnabled = true;
		}
	}
	else if(convar == Cvar_BWNotify_GlowEnabled)
	{
		g_cvarGlow = StringToInt(newValue);
	}
	else if(convar == Cvar_BWNotify_Type)
	{
		g_cvarType = StringToInt(newValue);
	}
	else if(convar == Cvar_BWNotify_Mode)
	{
		g_cvarMode = StringToInt(newValue);
	}
}
