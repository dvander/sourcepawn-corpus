#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#pragma semicolon 1

#define DECAL_PAINT "gmg/paint/splatter_blue"
#define SOUND_JUMP "gmg/portal/bounce.wav"

new Float:gelPos[3] = {0.0, 0.0, 9999.0};

public Plugin:myinfo = 
{
	name = "Repulsion Gel",
	author = "noodleboy347",
	description = "bounceh",
	version = "1.0",
	url = "http://www.frozencubes.com"
}

public OnPluginStart()
{
	RegAdminCmd("sm_repulsion", Command_Repulsion, ADMFLAG_ROOT);
	PrecacheSound(SOUND_JUMP);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon) 
{
	if(IsPlayerAlive(client))
	{
		if(buttons & IN_JUMP && GetEntityFlags(client) & FL_ONGROUND)
		{
			decl Float:pos[3];
			GetClientAbsOrigin(client, pos);
			if(GetVectorDistance(pos, gelPos) < 128.0)
			{
				BouncePlayer(client, vel);
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

public Action:Command_Repulsion(client, args)
{
	decl Float:origin[3], Float:angles[3];
	GetClientEyePosition(client, origin);
	GetClientEyeAngles(client, angles);
	new Handle:trace = TR_TraceRayFilterEx(origin, angles, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer);
	
	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(gelPos, trace);
		CloseHandle(trace);
		CreateGel();
		ReplyToCommand(client, "Repulsion Gel placed.");
	}
	return Plugin_Handled;
}

CreateGel()
{
	TE_SetupBSPDecal(gelPos, 0, PrecacheDecal("gmg/paint/splatter_blue", true));
	TE_SendToAll();
}

BouncePlayer(client, Float:vel[3])
{
	decl Float:ang[3];
	GetClientAbsAngles(client, ang);
	/*vel[0] -= 300.0 * Cosine(DegToRad(ang[1])) * -1.0;
	vel[1] -= 300.0 * Sine(DegToRad(ang[1])) * -1.0;
	vel[2] = 768.0;*/
	vel[0] = 0.0;
	vel[1] = 0.0;
	vel[2] = 768.0;
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);
	EmitSoundToClient(client, SOUND_JUMP);
}

TE_SetupBSPDecal(Float:origin[3], entity, index)
{
	TE_Start("BSP Decal");
	TE_WriteVector("m_vecOrigin", origin);
	TE_WriteNum("m_nEntity", entity);
	TE_WriteNum("m_nIndex", index);
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
    return entity > MaxClients;
}