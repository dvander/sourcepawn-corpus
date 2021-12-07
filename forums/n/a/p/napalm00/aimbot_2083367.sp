#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

new bool:Aiming[MAXPLAYERS+1];
new bool:Walling[MAXPLAYERS+1];
new Handle:cv_walltex;

public Plugin:myinfo = 
{
	name = "[ANY] Aimbot/Wallhack",
	author = "Arthurdead",
	description = "Aimbot And Wallhack",
	version = "0.1",
	url = "http://steamcommunity.com/id/Arthurdead"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_aimbot", Command_AimBot);
	RegConsoleCmd("sm_wallhack", Command_Wallhack);
	cv_walltex = CreateConVar("sm_wallhack_tex", "effects/strider_bulge_dudv_dx60.vmt", "Wallhack Texture", FCVAR_PLUGIN|FCVAR_NOTIFY);
	HookEvent("player_spawn", Event_Spawn);
}

public Action:Command_Wallhack(client, args)
{
	if(CheckCommandAccess(client, "sm_wallhack_access", ADMFLAG_ROOT))
	{
		if(Walling[client] == false)
		{
			Walling[client] = true;
			PrintToChat(client, "Wallhack Enabled")
		}
		else if(Walling[client] == true)
		{
			Walling[client] = false;
			PrintToChat(client, "Wallhack Disabled")
		}
	}
}

public Action:Command_AimBot(client, args)
{
	if(CheckCommandAccess(client, "sm_aimbot_access", ADMFLAG_ROOT))
	{
		if(Aiming[client] == false)
		{
			Aiming[client] = true;
			PrintToChat(client, "Aimbot Enabled")
		}
		else if(Aiming[client] == true)
		{
			Aiming[client] = false;
			PrintToChat(client, "Aimbot Disabled")
		}
	}
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
		if(Aiming[client] == true)
		{
			decl Float:camangle[3], Float:clientEyes[3], Float:targetEyes[3];
			GetClientEyePosition(client, clientEyes);
			new Ent = Client_GetClosest(clientEyes, client);
			if(Ent != -1)
			{
				decl Float:vec[3],Float:angle[3];
				GetClientAbsOrigin(Ent, targetEyes);
				GetEntPropVector(Ent, Prop_Data, "m_angRotation", angle);    
				if(GetClientButtons(Ent) & IN_DUCK)
				{
					targetEyes[2] += 45;
					targetEyes[0] += 20.0 * Cosine(DegToRad(angle[1]));
					targetEyes[1] += 20.0 * Sine(DegToRad(angle[1]));
				}
				else
				{
					targetEyes[2] += 65;
					targetEyes[0] += 10.0 * Cosine(DegToRad(angle[1]));
					targetEyes[1] += 15.0 * Sine(DegToRad(angle[1]));
				}
				MakeVectorFromPoints(targetEyes, clientEyes, vec);
				GetVectorAngles(vec, camangle);
				camangle[0] *= -1.0;
				camangle[1] += 180.0;
				TeleportEntity(client, NULL_VECTOR, camangle, NULL_VECTOR);
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
	new maxClients = GetMaxClients();
	new String:Tex[PLATFORM_MAX_PATH];
	GetConVarString(cv_walltex, Tex, PLATFORM_MAX_PATH)
	new mdl = PrecacheModel(Tex);
	for (new i = 1; i < maxClients; ++i) {
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || (i == client))
			continue;
		GetEntPropVector(i, Prop_Data, "m_vecOrigin", vecOrigin_edict);
		GetClientEyePosition(i, vecOrigin_edict);
		if(GetClientTeam(i) != GetClientTeam(client))
		{
			if(Walling[client] == true)
			{
				TE_SetupGlowSprite(vecOrigin_edict, mdl, 0.1, 1.0, 255);
				TE_SendToClient(client);
			}
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