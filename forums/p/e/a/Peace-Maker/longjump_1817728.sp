#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

new Handle:g_hCVJumpBoost;

new Float:g_fPreviousVelocity[MAXPLAYERS+1][3];
new bool:g_bPlayerJumped[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "Long Jump",
	author = "Jannik \"Peace-Maker\" Hartung",
	description = "Boosts player jumps",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
	g_hCVJumpBoost = CreateConVar("sm_longjump_boost", "0.20", "Set to speed percentage to add to player jump speeds. (Default: 0.2)");
	
	HookEvent("player_jump", Event_OnPlayerJump);
	HookEvent("player_footstep", Event_OnPlayerFootstep);
}

public OnClientDisconnect(client)
{
	g_bPlayerJumped[client] = false;
}

public Event_OnPlayerJump(Handle:event, const String:error[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", g_fPreviousVelocity[client]);
	g_bPlayerJumped[client] = true;
}

public Event_OnPlayerFootstep(Handle:event, const String:error[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_bPlayerJumped[client] = false;
}

public OnGameFrame()
{
	decl Float:vVelocity[3];
	for(new i=1;i<=MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
		
		if(!g_bPlayerJumped[i])
			continue;
		
		GetEntPropVector(i, Prop_Data, "m_vecVelocity", vVelocity);
		if(vVelocity[2] > g_fPreviousVelocity[i][2])
		{
			new Float:fIncrease = GetConVarFloat(g_hCVJumpBoost) + 1.0;
			vVelocity[0] *= fIncrease;
			vVelocity[1] *= fIncrease;
			
			TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, vVelocity);
			g_bPlayerJumped[i] = false;
		}
	}
}