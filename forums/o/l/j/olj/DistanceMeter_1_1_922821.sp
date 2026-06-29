#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

#define PLUGIN_VERSION "1.1"

new bool:DistanceEnabled[MAXPLAYERS+1];
new Handle:DistanceMeterTimer[MAXPLAYERS+1];
new propinfoghost = -1;

public Plugin:myinfo = 

{
	name = "Distance Meter",
	author = "Olj",
	description = "Displays distance between hunter and any object",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
	{
		RegConsoleCmd("distance", Command_Distance, "Toggles distance showing for hunters", FCVAR_PLUGIN);
		CreateConVar("l4d_dmeter_version", PLUGIN_VERSION, "Version of Distance Meter", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		HookEvent("round_start", RoundStartEvent);
		propinfoghost = FindSendPropInfo("CTerrorPlayer", "m_isGhost");
	}

public RoundStartEvent(Handle:event, const String:name[], bool:dontBroadcast)
	{
		CreateTimer(20.0, ResetTimer);
	}

public Action:ResetTimer(Handle:timer, any:clientID)
	{
		for (new i = 1; i <=MaxClients; i++)
			{
				DistanceEnabled[i] = false;
			}
	}

public Action:Command_Distance(client, args)
	{
		if (!IsValidClient(client)) return Plugin_Handled;
		//PrintToChatAll("Invalid client test passed");
		if (GetClientTeam(client)!=3) return Plugin_Handled;
		//PrintToChatAll("Client team test passed");
		if (IsPlayerGhost(client)) return Plugin_Handled;
		//PrintToChatAll("Client ghost test passed");
		decl String:model[128];
		GetClientModel(client, model, sizeof(model));
		if (StrContains(model, "hunter", false)!=-1)
			{
				if (DistanceEnabled[client] == true)
					{
						DistanceEnabled[client] = false;
						//PrintToChatAll("Disabled DistanceMeter");
						return Plugin_Handled;
					}
				if (DistanceEnabled[client] == false)
					{
						DistanceEnabled[client] = true;
						DistanceMeterTimer[client] = CreateTimer(0.1, DistanceTimer, any:client, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
						//PrintToChatAll("Enabled DistanceMeter");
						return Plugin_Handled;
					}
			}
		return Plugin_Continue;
	}

public Action:DistanceTimer(Handle:timer, any:client)
	{
		if ((!IsValidClient(client))||(DistanceEnabled[client] == false)||(GetClientTeam(client)!=3)||(IsPlayerGhost(client)))
			{
				DistanceEnabled[client] = false;
				DistanceMeterTimer[client] = INVALID_HANDLE;
				//PrintToChatAll("Invalid client detected");
				return Plugin_Stop;
			}
		new buttons = GetEntProp(client, Prop_Data, "m_nButtons", buttons);
		if(buttons & IN_DUCK)
			{
				decl Float:vAngles[3], Float:vOrigin[3], Float:vStart[3], Distance;
				GetClientEyePosition(client,vOrigin);
				GetClientEyeAngles(client, vAngles);
				new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceRayDontHitSelf, client);
				if(TR_DidHit(trace))
					{        
						TR_GetEndPosition(vStart, trace);
						Distance = RoundToNearest(GetVectorDistance(vOrigin, vStart, false));
						PrintCenterText(client, "%i", Distance);
						CloseHandle(trace);
					}
				else CloseHandle(trace);
			}
		return Plugin_Continue;
	}

public IsValidClient(client)
{
	if (client == 0)
		return false;
	
	if (!IsClientConnected(client))
		return false;
	
	if (IsFakeClient(client))
		return false;
	
	if (!IsClientInGame(client))
		return false;
	
	if (!IsPlayerAlive(client))
		return false;
	return true;
}				
				
bool:IsPlayerGhost(client)
{
	new isghost = GetEntData(client, propinfoghost, 1);
	
	if (isghost == 1) return true;
	else return false;
}			

/*public GetEntityAbsOrigin(entity,Float:origin[3]) {
    decl Float:mins[3], Float:maxs[3];

    GetEntPropVector(entity,Prop_Send,"m_vecOrigin",origin);
    GetEntPropVector(entity,Prop_Send,"m_vecMins",mins);
    GetEntPropVector(entity,Prop_Send,"m_vecMaxs",maxs);

    origin[0] += (mins[0] + maxs[0]) * 0.5;
    origin[1] += (mins[1] + maxs[1]) * 0.5;
    origin[2] += (mins[2] + maxs[2]) * 0.5;
}  */

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	if(entity == data) // Check if the TraceRay hit the itself.
		{
			return false; // Don't let the entity be hit
		}
	return true; // It didn't hit itself
}