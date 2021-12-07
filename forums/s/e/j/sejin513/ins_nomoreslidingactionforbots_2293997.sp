#pragma semicolon 1
#include <sdkhooks>
#define PLUGIN_VERSION "1.0"
#define PLUGIN_DESCRIPTION "No more sliding shoot skill for bots. Awwwww ._."

public Plugin:myinfo =
{
	name = "＃Lua No More Sliding Action For Bots",
	author = "D.Freddo",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://steam.lua.kr"
}

public OnPluginStart()
	// TOO LONG for Cvar ._.)
	CreateConVar("sm_ins_no_more_sliding_action_for_bots", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if ((buttons & IN_ATTACK || buttons & IN_ATTACK2) && IsFakeClient(client)){
		if (GetEntProp(client, Prop_Send, "m_bWasSliding") == 1)
			return Plugin_Handled;
	}	
	return Plugin_Continue;
}