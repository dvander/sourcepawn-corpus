#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.4"

new bool:jumpdelay[MAXPLAYERS+1];
new bool:jumpedonce[MAXPLAYERS+1];
new bool:PressingJump[MAXPLAYERS+1];
new bool:DoubleJump[MAXPLAYERS+1];

new Handle:jumpheight;

public Plugin:myinfo = 
{
	name = "L4D2_InfectedDoubleJump",
	author = "N3wton",
	description = "Double Jump When Ghost Infected",
	version = PLUGIN_VERSION,
}

public OnPluginStart()
{
	jumpheight = CreateConVar( "IDJ_JumpHeight", "700.0", "How height the ghosted infected can jump", FCVAR_PLUGIN );
	
	AutoExecConfig(true, "[L4D2] InfectedGhostLeep");
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if ( GetClientTeam(client)!=3 || !IsPlayerSpawnGhost(client) ) return Plugin_Continue;
		
	if (buttons & IN_JUMP && !jumpdelay[client] && jumpedonce[client] && DoubleJump[client] && !PressingJump[client] )
	{		
		jumpdelay[client] = true;
		CreateTimer(2.0, ResetJumpDelay, client);
		DoPounce(client);
	}
	else
	{
		if ( buttons & IN_JUMP )
		{
			if( !DoubleJump[client] && !jumpedonce[client] )
			{
				jumpedonce[client] = true;
				PressingJump[client] = true;
				CreateTimer(0.1, SetDoubleJump, client);
				CreateTimer(1.0, ResetDoubleJump, client);
			}
		} else
		{
			PressingJump[client] = false;
		}
	}

	if (buttons & IN_ATTACK && jumpdelay[client] && !(GetEntProp(client, Prop_Send, "m_ghostSpawnState", 4)))
	{
		SetEntProp(client, Prop_Send, "m_ghostSpawnState", 128, 4);
	}
	return Plugin_Continue;
}

DoPounce(any:client)
{
	decl Float:vec[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vec);
	
	if (vec[2] < 0 && !DoubleJump[client] )
	{
		return;
	}
	
	vec[2] = GetConVarFloat( jumpheight );
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vec);
}

public Action:SetDoubleJump(Handle:timer, any:client)
{
	DoubleJump[client] = true;
}

public Action:ResetDoubleJump(Handle:timer, any:client)
{
	jumpedonce[client] = false;
	DoubleJump[client] = false;
}

public Action:ResetJumpDelay(Handle:timer, any:client)
{
	jumpdelay[client] = false;
	jumpedonce[client] = false;
}

stock bool:IsPlayerSpawnGhost(client)
{
	if (GetEntProp(client, Prop_Send, "m_isGhost", 1)) return true;
	else return false;
}