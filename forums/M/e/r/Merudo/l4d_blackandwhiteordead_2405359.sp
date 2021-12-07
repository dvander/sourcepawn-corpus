/***************************************************************************************** 
* Black and White Notifier (L4D/L4D2)
* Author(s): DarkNoghri, madcap (recoded by: retsam), Merudo
* Date: 3/24/2016
* File: l4d_blackandwhiteordead.sp
* Description: Notify people when player is black and white or dead
******************************************************************************************
* 
* 1.7r2 - Cancel B/W glow if healed from non-medkit source. Glow stays if player disconnect / goes idle
* 1.7r  - Initial recode.
*/

#include <sourcemod>

#pragma semicolon 1;
#pragma newdecls required;

#define PLUGIN_VERSION "1.7r2"

#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

ConVar Cvar_GlowEnabled;
ConVar Cvar_Hint;
ConVar Cvar_Mode;
ConVar Cvar_Death;

ConVar Cvar_MaxIncap;

bool g_bPlayerBW[MAXPLAYERS+1] = { false, ... };
bool L4D1;

public Plugin myinfo = 
{
	name = "[L4D] Black and White Notifier",
	author = "DarkNoghri, madcap (recoded by: retsam), Merudo",
	description = "Notify people when player is black and white or dead.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showpost.php?p=1438810&postcount=68"
}

public void OnPluginStart()
{
	char gameName[64]; GetGameFolderName(gameName, sizeof(gameName));
	L4D1 = StrEqual(gameName, "left4dead", false);

	CreateConVar("sm_bwnotice_version", PLUGIN_VERSION, "Version of black and white notification plugin",FCVAR_NOTIFY);

	Cvar_GlowEnabled = CreateConVar("sm_bwnotice_glow", "1", "Enable making black white players glow?(1/0 = yes/no. Default 1)", FCVAR_NOTIFY);
	Cvar_Hint  = CreateConVar("sm_bwnotice_noticetype", "0", "Type to use for notification. (0=chat, 1=hint text. Default 0)", FCVAR_NOTIFY);
	Cvar_Mode  = CreateConVar("sm_bwnotice_mode", "1", "Method of notification for BW. (0=Nobody, 1=survivors only, 2=infected only, 3=all players. Default 1)", FCVAR_NOTIFY);
	Cvar_Death = CreateConVar("sm_bwnotice_death", "0", "Method of notification for deaths. (0=Nobody, 1=survivor only, 2=infected only, 3=all players. Default 0)", FCVAR_NOTIFY);
	
	Cvar_MaxIncap = FindConVar("survivor_max_incapacitated_count");

	HookEvent("revive_success", Hook_ReviveSuccess);
	HookEvent("heal_success", Hook_HealSuccess);
	HookEvent("player_death", Hook_PlayerDeath);
	
	CreateTimer(2.0, Timer_UpdateGlow, _, TIMER_REPEAT); // check every 3 sec for incorrect glow
	
	AutoExecConfig(true, "plugin.bwdnotifier");
}
int glowColor[4] = {205,91,69, 255};

// --------------------------------------
// Update glow in case it got changed (admin heal, player replacement, etc)
// --------------------------------------
public Action Timer_UpdateGlow(Handle timer)
{
	for(int x = 1; x <= MaxClients; x++)
	{
		UpdateGlow(x);
	}
}

void StopGlow(int client)
{
	if  (!L4D1 && GetEntProp(client, Prop_Send, "m_iGlowType") == 3 &&  Cvar_GlowEnabled.BoolValue) // if glowing but shouldn't
	{
		SetEntProp(client, Prop_Send, "m_iGlowType", 0);
		SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);		//16777215 white?				
	}

	if  (L4D1 && Cvar_GlowEnabled.BoolValue) // if glowing but shouldn't
	{
		SetEntityRenderColor(client);
	}
}

void StartGlow(int client)
{
	if (!L4D1 && GetEntProp(client, Prop_Send, "m_iGlowType") != 3 &&  Cvar_GlowEnabled.BoolValue) // if should be glowing but isn't
	{
		SetEntProp(client, Prop_Send, "m_iGlowType", 3);
		SetEntProp(client, Prop_Send, "m_glowColorOverride", 16777215);		
	}

	if  ( L4D1 && Cvar_GlowEnabled.BoolValue) // if should be glowing but isn't
	{
		SetEntityRenderColor(client, glowColor[0], glowColor[1], glowColor[2], glowColor[3]);
	}
}

public Action UpdateGlow(int client)
{
	if(!client || !IsClientInGame(client) || GetClientTeam(client) != TEAM_SURVIVOR) return;

	g_bPlayerBW[client] = false;
			
	if (Cvar_MaxIncap.IntValue < GetEntProp(client, Prop_Send, "m_currentReviveCount") || !IsPlayerAlive(client)) // if not on last revive
	{
		StopGlow(client);
	}
	else if (Cvar_MaxIncap.IntValue == GetEntProp(client, Prop_Send, "m_currentReviveCount")) // if on last revive
	{
		g_bPlayerBW[client] = true;
		StartGlow(client);
	}
}

// --------------------------------------
// On last revive, show message & change glow
// --------------------------------------
char survivor_names[8][] = { "Nick", "Rochelle", "Coach", "Ellis", "Bill", "Zoey", "Francis", "Louis"};
public void Hook_ReviveSuccess(Handle event, const char[] name, bool dontBroadcast)
{
	if(GetEventBool(event, "lastlife"))
	{
		//PrintToChatAll("Hook_Revive: Lastlife reached");
		int target = GetClientOfUserId(GetEventInt(event, "subject"));
		
		if(target < 1) return;
		
		g_bPlayerBW[target] = true;
		
		char charName[32];
		int  charID = GetSurvivorID(target);
		if (charID == -1) charName = "Unknown"; else strcopy(charName, 32, survivor_names[charID]);
		
		StartGlow(target) ;
		
		switch(Cvar_Mode.IntValue)
		{
		case 1: //Survivors
			{
				for(int x = 1; x <= MaxClients; x++)
				{
					//if(!IsClientInGame(x) || GetClientTeam(x) != TEAM_SURVIVOR || x == target || IsFakeClient(x))
					if(!IsClientInGame(x) || GetClientTeam(x) != TEAM_SURVIVOR || IsFakeClient(x))
					{
						continue;
					}
					
					if(Cvar_Hint.BoolValue)
					{
						PrintHintText(x, "%N (%s) is black and white!", target, charName);
					}
					else					
					{
						PrintToChat(x, "\x01\x04[B&W] \x03%N \x01(%s) is Black&White and needs help!", target, charName);
					}
				}	
			}
		case 2: //Infected
			{
				for(int x = 1; x <= MaxClients; x++)
				{
					if(!IsClientInGame(x) || GetClientTeam(x) != TEAM_INFECTED || IsFakeClient(x))
					{
						continue;
					}

					if(Cvar_Hint.BoolValue)
					{
						PrintHintText(x, "%N (%s) is black and white!", target, charName);
					}
					else
					{
						PrintToChat(x, "\x01\x04[B&W] \x03%N \x01(%s) is Black&White, take them out!", target, charName);	
					}
				}
			}
		case 3:
			{
				if(Cvar_Hint.BoolValue)
				{
					PrintHintTextToAll("%N (%s) is black and white!", target, charName);				
				}
				else
				{
					PrintToChatAll("\x01\x04[B&W] \x03%N \x01(%s) is Black&White and in danger of dying!", target, charName);
				}
			}
		}
	}
}

// --------------------------------------
// If healing and healee was B&W, show message & remove glow
// --------------------------------------
public void Hook_HealSuccess(Handle event, const char[] name, bool dontBroadcast)
{

	int healee = GetClientOfUserId(GetEventInt(event, "subject"));
	int healer = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(healee < 1)
	return;
	
	if(g_bPlayerBW[healee])
	{		
		g_bPlayerBW[healee] = false;
		StopGlow(healee);
		
		if (Cvar_Mode.IntValue == 1 || Cvar_Mode.IntValue == 3)   // Show to survivors
		{
			for(int x = 1; x <= MaxClients; x++)
			{
				if(!IsClientInGame(x) || GetClientTeam(x) != TEAM_SURVIVOR || IsFakeClient(x))
				{
					continue;
				}
			
				if(Cvar_Hint.BoolValue)
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
				else			
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
			}
		}
		
		if (Cvar_Mode.IntValue == 2 || Cvar_Mode.IntValue == 3)  // To infected
		{		
			for(int x = 1; x <= MaxClients; x++)
			{
				if(!IsClientInGame(x) || GetClientTeam(x) != TEAM_INFECTED || IsFakeClient(x))
				{
					continue;
				}
				
				if(Cvar_Hint.BoolValue)
				{
					PrintHintText(x, "%N was healed and is no longer black and white!", healee);
				}				
				else
				{
					PrintToChat(x, "\x01\x04[B&W] \x03%N \x01was healed and is no longer Black&White!", healee);
				}
			}
		}
	}
}

// --------------------------------------
// If player death, show message & remove glow
// --------------------------------------
public void Hook_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client < 1) return;
	
	if(g_bPlayerBW[client]) StopGlow(client);
	
	g_bPlayerBW[client] = false;
	
	if (GetClientTeam(client) == TEAM_SURVIVOR)
	{
		char charName[32];
		int  charID = GetSurvivorID(client);
		if (charID == -1) charName = "Unknown";
		else strcopy(charName, 32, survivor_names[charID]);
		
		int SurvivorsLeft = CountSurvivorsLeft();
		char sSurvivors[32];	
		if (SurvivorsLeft !=  1 )  	  Format(sSurvivors, sizeof(sSurvivors), "%d survivors remain.", SurvivorsLeft);
		else if (SurvivorsLeft == 1 ) Format(sSurvivors, sizeof(sSurvivors), "%d survivor remains.", SurvivorsLeft);

		if (Cvar_Death.IntValue > 0)
		{
			for(int x = 1; x <= MaxClients; x++)
			{
				if(!IsClientInGame(x) || IsFakeClient(x) || GetClientTeam(x) == 0) 	continue;
				if(Cvar_Death.IntValue == 3 || (GetClientTeam(x) == TEAM_SURVIVOR && Cvar_Death.IntValue == 1) || (GetClientTeam(x) == TEAM_INFECTED && Cvar_Death.IntValue == 2))
				{	
					if(Cvar_Hint.BoolValue)
					{
						PrintHintText(x, "%N (%s) has died! %s", client, charName, sSurvivors);
					}
					else				
					{
						PrintToChat(x, "\x01\x04[B&W] \x03%N \x01(%s) has died! %s", client, charName, sSurvivors);
					}
				}
			}
		}
	}
}

char survivor_models[8][] =
{
	"gambler", "producer", "coach", "mechanic",
	"namvet", "teenangst", "biker", "manager"
};

int GetSurvivorID(int client)
{
	char Model[128]; 
	GetClientModel(client, Model, sizeof(Model));

	for (int i = 0; i < 8; i++)
	{
		if (StrContains(Model, survivor_models[i], false) > 0) return i;
	}
	return -1;
}

int CountSurvivorsLeft()
{
	int count = 0;
	for(int i = 1; i <= MaxClients; i++)
	{	
		if(IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsPlayerAlive(i))
		{
			count = count + 1;
		}
	}
	return count;
}
