#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <cstrike>

#pragma semicolon 1

public Plugin myinfo = 
{
    name = "CS:GO Force Defuse",
    author = "Gdk",
    description = "Forces player to stick bomb defuse",
    version = "1.1.2",
    url = "https://github.com/RavageCS/CSGO-Force-Defuse"
};

int g_num_aborts[MAXPLAYERS+1][1];
int g_defuser;
int g_buttons;

bool g_has_kit;
bool g_defuse_signal;

float g_angles[3];
float g_origin[3];

Handle g_h_enabled = INVALID_HANDLE;
Handle g_h_num_aborts = INVALID_HANDLE;
Handle g_h_num_alive_defuse = INVALID_HANDLE;
Handle g_h_behavior = INVALID_HANDLE;

public OnPluginStart() 
{
	g_h_enabled 		= CreateConVar("sm_fd_enabled",    "1", "Whether force defuse is enabled");
	g_h_num_aborts 		= CreateConVar("sm_fd_num_aborts", "3", "Number of canceled defuses before forcing defuse");
	g_h_num_alive_defuse	= CreateConVar("sm_fd_num_alive", "0", "Number of terrorists alive to force defuse");
	g_h_behavior		= CreateConVar("sm_fd_behavior", "1", "0: Always force defuse 1: Force if defuser has a kit 2: Force if defuser has a kit or teamates have no kit");

	HookEvent("bomb_begindefuse", Event_BeginDefuse, EventHookMode_Post);
	HookEvent("bomb_abortdefuse", Event_AbortDefuse, EventHookMode_Post);
	HookEvent("bomb_defused", Event_Reset, EventHookMode_Post);
	HookEvent("bomb_exploded", Event_Reset, EventHookMode_Post);
	HookEvent("round_start", Event_Reset, EventHookMode_Post);

	AutoExecConfig(true, "force_defuse");
}

public void OnClientAuthorized(int client)
{
	if(GetConVarInt(g_h_enabled))
		g_num_aborts[client][0] = 0;
}

public void ResetGlobals()
{
	for (int x=0; x < MAXPLAYERS+1; x++) 
	{
		g_num_aborts[x][0] = 0;
	}

	g_defuse_signal = false;

	g_buttons = 0;
}  

public Action Event_BeginDefuse(Handle event, const char[] name, bool dontBroadcast)
{
	g_defuser = GetClientOfUserId(GetEventInt(event, "userid"));

	int m_fFlags = GetEntProp(g_defuser, Prop_Send, "m_fFlags");

	if(GetConVarInt(g_h_enabled) && GetAllivePlayers(2) <= GetConVarInt(g_h_num_alive_defuse) && m_fFlags != 256 && m_fFlags != 262)
	{
		g_has_kit = GetEventBool(event, "haskit");

		if(g_num_aborts[g_defuser][0] >= GetConVarInt(g_h_num_aborts))
		{
			switch (GetConVarInt(g_h_behavior))
			{
				case 0:
				{
					g_defuse_signal = true;
				}
				case 1:
				{
					g_defuse_signal = g_has_kit;
				}
				case 2:
				{
					g_defuse_signal = g_has_kit || !TeamHasKit();
				}
			}
		}
			
		if(g_defuse_signal)
		{
			g_buttons = GetClientButtons(g_defuser);

			GetClientEyeAngles(g_defuser, g_angles);
			GetClientAbsOrigin(g_defuser, g_origin);
		}
	}

	return Plugin_Continue;
}

public Action Event_AbortDefuse(Handle event, const char[] name, bool dontBroadcast)
{
	g_defuser = GetClientOfUserId(GetEventInt(event, "userid"));

	int m_fFlags = GetEntProp(g_defuser, Prop_Send, "m_fFlags");

	if(GetConVarInt(g_h_enabled) && GetAllivePlayers(2) <= GetConVarInt(g_h_num_alive_defuse) && m_fFlags != 256 && m_fFlags != 262)
	{	
		bool abort = false;
		switch (GetConVarInt(g_h_behavior))
		{
			case 0:
			{
				abort = true;
			}
			case 1:
			{
				abort = g_has_kit;
			}
			case 2:
			{
				abort = g_has_kit || !TeamHasKit();
			}
		}

		if(abort)
			g_num_aborts[g_defuser][0]++;
	}

	return Plugin_Continue;
}

public Action Event_Reset(Handle event, const char[] name, bool dontBroadcast)
{
	if(GetConVarInt(g_h_enabled))
		ResetGlobals();
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3],
                             int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2]) 
{
	if(g_defuse_signal)
	{
		buttons = g_buttons;
		TeleportEntity(g_defuser, g_origin, g_angles, NULL_VECTOR);
		SetEntProp(g_defuser, Prop_Send, "m_fFlags", FL_ONGROUND);
	}
	
    	return Plugin_Continue;
}

public int GetAllivePlayers(int team)
{
	int total;

    	for(int x = 1; x <= MaxClients; x++)
	{
        	if(IsClientInGame(x) && GetClientTeam(x) == team && IsPlayerAlive(x))
            		total++;
	}

    	return total;
}
		
public bool TeamHasKit()
{
	int num_kits;

    	for(int x = 1; x <= MaxClients; x++)
	{
        	if(IsClientInGame(x) && GetClientTeam(x) == 3 && IsPlayerAlive(x) && GetEntProp(x, Prop_Send, "m_bHasDefuser"))
            		num_kits++;
	}
	
	if(num_kits > 0)
		return true;

	else
		return false;
}
