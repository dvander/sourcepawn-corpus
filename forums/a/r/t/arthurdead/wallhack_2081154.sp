#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#pragma semicolon 1

new bool:Walling[MAXPLAYERS+1];
new Handle:cv_walltex;

public Plugin:myinfo = 
{
	name = "[ANY] Wallhack For Specs",
	author = "Arthurdead",
	description = "Wallhack For Specs",
	version = "0.3",
	url = "http://steamcommunity.com/id/Arthurdead"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_wallhack", Command_Wallhack);
	cv_walltex = CreateConVar("sm_wallhack_tex", "effects/strider_bulge_dudv_dx60.vmt", "Wallhack Texture", FCVAR_PLUGIN|FCVAR_NOTIFY);
	HookEvent("player_spawn", Event_Spawn);
}

public Action:Command_Wallhack(client, args)
{
	if(CheckCommandAccess(client, "sm_wallhack_access", ADMFLAG_ROOT))
	{
		if(GetClientTeam(client) == 1)
		{
			if(Walling[client] == false)
			{
				Walling[client] = true;
				PrintToChat(client, "Wallhack Enabled");
			}
			else if(Walling[client] == true)
			{
				Walling[client] = false;
				PrintToChat(client, "Wallhack Disabled");
			}
		}
		else ReplyToCommand(client, "[SM] You Must Be An Spectator To Use This Command");
	}
	return Plugin_Handled;
}

public Action:Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	SDKHook(client, SDKHook_PreThink, PreThinkHook);
}

public PreThinkHook(client)
{
	if(IsValidClient(client))
	{
		if(Walling[client] == true)
		{
			if(GetClientTeam(client) == 1)
			{
				decl Float:clientEyes[3];
				GetClientEyePosition(client, clientEyes);
				Client_GetClosest(clientEyes, client);
			}
		}
	}
}

bool:IsValidClient( client ) 
{
	if(!(1 <= client <= MaxClients ) || !IsClientInGame(client)) 
		return false; 
	return true; 
}

stock Client_GetClosest(Float:vecOrigin_center[3], const client)
{
	decl Float:vecOrigin_edict[3];
	new Float:distance = -1.0;
	new closestEdict = -1;
	new String:Tex[PLATFORM_MAX_PATH];
	GetConVarString(cv_walltex, Tex, PLATFORM_MAX_PATH);
	new mdl = PrecacheModel(Tex);
	new target = Client_GetObserverTarget(client);
	for (new i = 1; i < MaxClients; ++i)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i) || (i == client))
			continue;
		GetEntPropVector(i, Prop_Data, "m_vecOrigin", vecOrigin_edict);
		GetClientEyePosition(i, vecOrigin_edict);
		if(GetClientTeam(i) != GetClientTeam(target))
		{
			TE_SetupGlowSprite(vecOrigin_edict, mdl, 0.1, 1.0, 255);
			TE_SendToClient(client);
			if(IsPointVisible(vecOrigin_center, vecOrigin_edict))
			{
				new Float:edict_distance = GetVectorDistance(vecOrigin_center, vecOrigin_edict);
				if((edict_distance < distance) || (distance == -1.0))
				{
					distance = edict_distance;
					closestEdict = i;
				}
			}
		}
	}
	return closestEdict;
} 

stock bool:IsPointVisible(const Float:start[3], const Float:end[3])
{
	TR_TraceRayFilter(start, end, MASK_PLAYERSOLID, RayType_EndPoint, TraceEntityFilterStuff);
	return TR_GetFraction() >= 0.9;
}

public bool:TraceEntityFilterStuff(entity, mask)
{
	return entity > MaxClients;
}  