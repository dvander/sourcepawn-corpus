#pragma semicolon 1

#include <sdktools>

new Float:g_pos[3];

public Plugin:myinfo = 
{
	name = "[TF2] Spawn Tank",
	author = "Oshizu / Dr. Stein",
	description = "Spawns Tank from Mann Vs Machine in place where your crosshair is located",
	version = "1.0.1",
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	RegAdminCmd("sm_tank", Command_Spawn, ADMFLAG_GENERIC);
}

public OnMapStart()
{
	PrecacheModel("models/bots/boss_bot/bomb_mechanism.mdl"); 
	PrecacheModel("models/bots/boss_bot/boss_tank.mdl");
	PrecacheModel("models/bots/boss_bot/boss_tank_damage1.mdl");
	PrecacheModel("models/bots/boss_bot/boss_tank_damage2.mdl");
	PrecacheModel("models/bots/boss_bot/boss_tank_damage3.mdl");
	PrecacheModel("models/bots/boss_bot/boss_tank_part1_destruction.mdl");
	PrecacheModel("models/bots/boss_bot/static_boss_tank.mdl");
	PrecacheModel("models/bots/boss_bot/tank_track.mdl");
	PrecacheModel("models/bots/boss_bot/tank_track_R.mdl");
	PrecacheModel("models/bots/boss_bot/tank_track_L.mdl");
}

// FUNCTIONS
public Action:Command_Spawn(client, args)
{
	if(!SetTeleportEndPoint(client))
	{	
		PrintToChat(client, "[SM] Could not find spawn point.");	
		return Plugin_Handled;	
	}
	new String:sHealth[16], HP = -1;
	if (args > 0)
	{
		GetCmdArg(1, sHealth, sizeof(sHealth));
		HP = StringToInt(sHealth);
	}
	new String:sSpeed[5], SPD = -1;
	if (args > 1)
	{
		GetCmdArg(2, sSpeed, sizeof(sSpeed));
		SPD = StringToInt(sSpeed);
	}
	new String:sTeam[10], TEAM = 1;
	if (args > 2)
	{
		GetCmdArg(3, sTeam, sizeof(sTeam));
		TEAM = StringToInt(sTeam);
	}
	new entity = CreateEntityByName("tank_boss");	
	if(IsValidEntity(entity))
	{
		if (SPD > -1)
		{
			SetVariantInt(SPD); 
			AcceptEntityInput(entity, "SetSpeed", client);
		}
		DispatchSpawn(entity);
		if (HP > -1)
		{
			SetVariantInt(HP); 
			AcceptEntityInput(entity, "SetMaxHealth", client);
			SetVariantInt(HP); 
			AcceptEntityInput(entity, "SetHealth", client);
		}
		else
		{
			SetVariantInt(1000); 
			AcceptEntityInput(entity, "SetMaxHealth", client);
			SetVariantInt(1000); 
			AcceptEntityInput(entity, "SetHealth", client);
		}
		if (TEAM > 0)
		{
				if (TEAM < 4)
				{
					SetEntProp(entity, Prop_Send, "m_iTeamNum", TEAM);
				}
		}
		if (TEAM == 1)
		{
			SetEntityRenderColor(entity, 0, 0, 0, 255);
		}
		if (TEAM == 2)
		{
			SetEntityRenderColor(entity, 255, 0, 0, 255);
		}
		g_pos[2] -= 10.0;
		TeleportEntity(entity, g_pos, NULL_VECTOR, NULL_VECTOR);
	}
	return Plugin_Handled;
}

SetTeleportEndPoint(client)
{
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:vBuffer[3];
	decl Float:vStart[3];
	decl Float:Distance;
	
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
    //get endpoint for teleport
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if(TR_DidHit(trace))
	{   	 
   	 	TR_GetEndPosition(vStart, trace);
		GetVectorDistance(vOrigin, vStart, false);
		Distance = -35.0;
   	 	GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		g_pos[0] = vStart[0] + (vBuffer[0]*Distance);
		g_pos[1] = vStart[1] + (vBuffer[1]*Distance);
		g_pos[2] = vStart[2] + (vBuffer[2]*Distance);
	}
	else
	{
		CloseHandle(trace);
		return false;
	}
	
	CloseHandle(trace);
	return true;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > GetMaxClients() || !entity;
}