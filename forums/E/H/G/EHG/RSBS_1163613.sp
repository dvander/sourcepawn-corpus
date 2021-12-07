#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.8"

new Handle:g_hEnableDelay;
new Handle:DelayCvar;

public Plugin:myinfo = 
{
	name = "Round Start Bot Stop",
	author = "EHG",
	description = "Round Start Bot Stop",
	version = PLUGIN_VERSION,
	url = ""
}


new bool:AlreadyDone = false;

public OnPluginStart()
{
	CreateConVar("l4d2_RSBS_version", PLUGIN_VERSION, "RSBS version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD)
	
	g_hEnableDelay = CreateConVar("l4d2_RSBS_delay_enabled", "1", "Enable/disable bot start delay", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	DelayCvar = CreateConVar("l4d2_RSBS_delay", "40", "Delay to enable bots if no human does.", FCVAR_PLUGIN, true, 1.0, false, _);
	
	HookEvent("round_start", Event_round_start);
}

public OnMapStart()
{
	SetConVarInt(FindConVar("sb_stop"), 0);
	AlreadyDone = false;
}

public Action:Event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	SetConVarInt(FindConVar("sb_stop"), 0);
	AlreadyDone = false;
}


public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (buttons & IN_MOVELEFT || buttons & IN_BACK || buttons & IN_FORWARD || buttons & IN_MOVERIGHT || buttons & IN_USE)
	{
		if (GetClientTeam(client) != 2)
		{
			return Plugin_Continue;
		}
		
		if (IsFakeClient(client))
		{
			if (GetConVarInt(FindConVar("sb_stop")) == 0 && !AlreadyDone)
			{
				SetConVarInt(FindConVar("sb_stop"), 1);
				if (GetConVarBool(g_hEnableDelay))
				{
					CreateTimer(GetConVarFloat(DelayCvar), StartBotsDelay);
				}
			}
		}
		
		if (!IsFakeClient(client))
		{
			if (GetConVarInt(FindConVar("sb_stop")) == 1 && !AlreadyDone)
			{
				AlreadyDone = true;
				SetConVarInt(FindConVar("sb_stop"), 0);
			}
		}
	}
	return Plugin_Continue;
}

public Action:StartBotsDelay(Handle:timer)
{
	if (GetConVarInt(FindConVar("sb_stop")) == 1 && !AlreadyDone)
	{
		AlreadyDone = true;
		SetConVarInt(FindConVar("sb_stop"), 0);
	}
	return Plugin_Handled;
}







