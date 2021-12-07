#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PL_VERSION "0.5"

new Float:g_pos[3];

new g_iBalls[1500];
new g_iClientBalls[MAXPLAYERS+1][1500];
new g_iCurrent;
new g_ClientCurrent[MAXPLAYERS+1];
public Plugin:myinfo = 
{
	name = "[TF2] Balls",
	author = "Geit",
	description = "Spawns Balls where you're looking. (Adapted from a plugin by linux_lover)",
	version = PL_VERSION,
	url = "http://gamingmasters.co.uk"
}
new	Handle:g_BirthdayBalls;
new	Handle:g_RandomColor;
new Handle:g_MinSize;
new Handle:g_Flags;
new Handle:g_MaxAmount;
new Handle:g_OverrideFlags;

public OnPluginStart()
{
	CreateConVar("sm_balls_version", PL_VERSION, "Balls Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_BirthdayBalls = CreateConVar("sm_balls_birthday", "0", "0 = Normal Balls, 1 = Birthday Balls");
	g_RandomColor = CreateConVar("sm_balls_random", "0", "0 = Normal Balls, 1 = Randomly colored balls");
	g_MinSize = CreateConVar("sm_balls_minsize", "1.0", "Minimum ball size, do not set over 1");
	g_Flags = CreateConVar("sm_balls_flag", "f", "Flag(s) required to spawn balls (obeys the balls per client limit)");
	g_MaxAmount = CreateConVar("sm_balls_amount", "10", "The maximum amount of balls a normal client can spawn");
	g_OverrideFlags = CreateConVar("sm_balls_override", "z", "Flag(s) required to override the balls per client limit");
	RegConsoleCmd("sm_ball", Command_Ball);
	RegConsoleCmd("sm_cleanballs", Command_CleanupSelf);
	RegAdminCmd("sm_balls_cleanup", Command_Cleanup, ADMFLAG_SLAY);
	HookEvent("teamplay_round_start", Event_RestartRound);
}

public Action:Command_Ball(client, args)
{
	if (!IsValidAdmin(client) && !ClientCanOverride(client))
	{
		PrintToChat(client, "[SM] You do not have access to this command.");
		return Plugin_Handled;
	}
	
	if (g_ClientCurrent[client] >= GetConVarInt(g_MaxAmount) && !ClientCanOverride(client))
	{
		PrintToChat(client, "[SM] You have the maximum number of balls spawned!");
		return Plugin_Handled;
	}

	if(!SetTeleportEndPoint(client))
	{
		PrintToChat(client, "[SM] Could not find spawn point.");
		return Plugin_Handled;
	}
	
	if(GetEntityCount() >= GetMaxEntities()-32|| g_iCurrent >= sizeof(g_iBalls))
	{
		PrintToChat(client, "[SM] Entity limit is reached. Can't spawn anymore balls. Change maps.");
		return Plugin_Handled;
	}
	
	new iBall = CreateEntityByName("prop_physics_multiplayer");
	
	if(IsValidEntity(iBall))
	{
		DispatchKeyValue(iBall, "model", "models/props_gameplay/ball001.mdl");
		DispatchKeyValue(iBall, "disableshadows", "1");
		DispatchKeyValue(iBall, "skin", GetConVarInt(g_BirthdayBalls) ? "1" : "0");
		DispatchKeyValue(iBall, "physicsmode", "2");
		DispatchKeyValue(iBall, "spawnflags", "256");
		if (GetConVarInt(g_RandomColor))
		{
			SetEntityRenderMode(iBall, RENDER_TRANSTEXTURE);
			SetEntityRenderColor(iBall, GetRandomInt(0,255), GetRandomInt(0,255), GetRandomInt(0,255), 255);
		}
		DispatchSpawn(iBall);
		SetEntPropFloat(iBall, Prop_Send, "m_flModelScale", GetRandomFloat(GetConVarFloat(g_MinSize), 1.0));
		g_pos[2] += 100.0;
		TeleportEntity(iBall, g_pos, NULL_VECTOR, NULL_VECTOR);
		g_iBalls[g_iCurrent++] = iBall;
		g_iClientBalls[client][g_ClientCurrent[client]++] = iBall;
		
	}
	return Plugin_Handled;
}

public OnClientPostAdminCheck(client)
{
	g_ClientCurrent[client]=0;
}

public Action:Command_CleanupSelf(client, args)
{
	if (g_ClientCurrent[client] == 0)
	{
		PrintToChat(client, "[SM] You have no balls!");
		return Plugin_Handled;
	}

	new String:strClassname[50];
	
	for(new i=0; i<g_ClientCurrent[client]; i++)
	{
		if(IsValidEntity(g_iClientBalls[client][i]))
		{
			GetEdictClassname(g_iClientBalls[client][i], strClassname, sizeof(strClassname));
			if(strcmp(strClassname, "prop_physics_multiplayer") == 0)
			{
				AcceptEntityInput(g_iClientBalls[client][i], "Kill");
			}
		}
		
		g_iClientBalls[client][i] = 0;
	}
	g_ClientCurrent[client] = 0;
	
	return Plugin_Handled;
}

public Action:Command_Cleanup(client, args)
{
	new String:strClassname[50];
	
	for(new i=0; i<g_iCurrent; i++)
	{
		if(IsValidEntity(g_iBalls[i]))
		{
			GetEdictClassname(g_iBalls[i], strClassname, sizeof(strClassname));
			if(strcmp(strClassname, "prop_physics_multiplayer") == 0)
			{
				AcceptEntityInput(g_iBalls[i], "Kill");
			}
		}
		
		g_iBalls[i] = 0;
	}
	g_iCurrent = 0;
	
	return Plugin_Handled;
}

public Action:Event_RestartRound(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i=0; i<sizeof(g_iBalls); i++)
	{
		g_iBalls[i] = 0;
	}
	
	g_iCurrent = 0;
	
	for(new i=1; i <= MaxClients; i++)
	{
		g_ClientCurrent[i]=0;
	}
	
	return Plugin_Continue;
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

stock bool:IsValidAdmin(client)
{
	decl String:flags[52];
	GetConVarString(g_Flags, flags, sizeof(flags));
	if (strcmp(flags, "0") == 0)
	{
		return true;
	}
	if (GetUserFlagBits(client) & ADMFLAG_ROOT)
	{
		return true;
	}
	new iFlags = ReadFlagString(flags);
	if (GetUserFlagBits(client) & iFlags)
	{
		return true;
	}
	return false;
}

stock bool:ClientCanOverride(client)
{
	decl String:flags[26];
	GetConVarString(g_OverrideFlags, flags, sizeof(flags));
	if (strcmp(flags, "0") == 0)
	{
		return true;
	}
	if (GetUserFlagBits(client) & ADMFLAG_ROOT)
	{
		return true;
	}
	new iFlags = ReadFlagString(flags);
	if (GetUserFlagBits(client) & iFlags)
	{
		return true;
	}
	return false;
}