#pragma semicolon 1

//The string that should be in player name to receive cash & double jump. You can change this value to any string you want 
#define PLUGIN_TAG "CSGO"

// Amount of cash to give player
#define CASH_AMOUNT	500


#define PLUGIN_AUTHOR "[W]atch [D]ogs"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <multicolors>

#pragma newdecls required

int g_fLastButtons[MAXPLAYERS + 1], g_fLastFlags[MAXPLAYERS + 1], g_iJumps[MAXPLAYERS + 1];
bool HasSpecialNick[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "Nickname Prize",
	author = PLUGIN_AUTHOR,
	description = "Gives some cash & double jump to player who has special string in name.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=298911"
};

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
}

public void OnClientDisconnect(int client)
{
	if (HasSpecialNick[client])	
		HasSpecialNick[client] = false;
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			char sName[64];
			GetClientName(i, sName, sizeof(sName));
			if(StrContains(sName, PLUGIN_TAG) != -1)
			{
				SetEntProp(i, Prop_Send, "m_iAccount", GetClientCash(i) + CASH_AMOUNT);
				HasSpecialNick[i] = true;
				CPrintToChat(i, "{green}[Name-Prize] {default}You received %i cash & free double jump for '%s' tag in your name!", CASH_AMOUNT, PLUGIN_TAG);
			}
		}
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (IsValidPlayer(client))
	{
		int	fCurFlags = GetEntityFlags(client);	
		int fCurButtons	= GetClientButtons(client);
					
		if (g_fLastFlags[client] & FL_ONGROUND)
		{		
			if (!(fCurFlags & FL_ONGROUND) &&!(g_fLastButtons[client] & IN_JUMP) &&	fCurButtons & IN_JUMP) 
			{
				g_iJumps[client]++;			
			}
		}
		else if (fCurFlags & FL_ONGROUND)
		{
			g_iJumps[client] = 0;						
		}
		else if (!(g_fLastButtons[client] & IN_JUMP) && fCurButtons & IN_JUMP)
		{
			if ( 0 <= g_iJumps[client] <= 1)
			{						
				g_iJumps[client]++;											
				float vVel[3];
				GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVel);	
								
				vVel[2] = 250.0;
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVel);
			}							
		}
		g_fLastFlags[client]	= fCurFlags;				
		g_fLastButtons[client]	= fCurButtons;
	}
}

int GetClientCash(int client) 
{ 
    return GetEntProp(client, Prop_Send, "m_iAccount"); 
} 

stock bool IsValidPlayer(int client)
{
	if(client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client) && HasSpecialNick[client])
		return true;
		
	return false;
}