#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

new Float:flag_pos[3];
new Float:ClientPosition[3];

public Plugin:myinfo=
{
	name= "VSH/FF2 Bots[moving]",
	author= "tRololo312312",
	description= "Makes TFBots move to enemys location",
	version= "1.1",
	url= "http://steamcommunity.com/profiles/76561198039186809"
}

public OnAllPluginsLoaded()
{
	new Handle:PFind = FindPluginByFile("vshbots_logic.smx");
	if(PFind != INVALID_HANDLE)
	{
		if(GetPluginStatus(PFind) != Plugin_Running)
		{
			SetFailState("logic plugin for these bots is not loaded!");
		}
	}
	else
	{
		SetFailState("logic plugin for these bots is not loaded!");
	}
}

public OnPluginStart()
{
	HookEvent("arena_round_start", RoundStarted);
}

public OnMapStart()
{
	CreateTimer(0.1, MoveTimer,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:OnFlagTouch(point, client)
{
	for(client=1;client<=MaxClients;client++)
	{
		if(IsClientInGame(client))
		{
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public Action:RoundStarted(Handle: event , const String: name[] , bool: dontBroadcast)
{
	CreateTimer(1.0, LoadStuff);
	CreateTimer(1.0, LoadStuff2);
	CreateTimer(2.0, FindFlag);
}

public Action:LoadStuff(Handle:timer)
{
	new teamflags = CreateEntityByName("item_teamflag");
	if(IsValidEntity(teamflags))
	{
		DispatchKeyValue(teamflags, "trail_effect", "0");
		DispatchKeyValue(teamflags, "ReturnTime", "1");
		DispatchKeyValue(teamflags, "flag_model", "models/empty.mdl");
		DispatchSpawn(teamflags);
		SetEntProp(teamflags, Prop_Send, "m_iTeamNum", 3);
	}
}

public Action:LoadStuff2(Handle:timer)
{
	new teamflags2 = CreateEntityByName("item_teamflag");
	if(IsValidEntity(teamflags2))
	{
		DispatchKeyValue(teamflags2, "trail_effect", "0");
		DispatchKeyValue(teamflags2, "ReturnTime", "1");
		DispatchKeyValue(teamflags2, "flag_model", "models/empty.mdl");
		DispatchSpawn(teamflags2);
		SetEntProp(teamflags2, Prop_Send, "m_iTeamNum", 2);
	}
}

public Action:FindFlag(Handle:timer)
{
	new ent = -1;
	while ((ent = FindEntityByClassname(ent, "item_teamflag"))!=INVALID_ENT_REFERENCE)
	{
		SDKHook(ent, SDKHook_StartTouch, OnFlagTouch );
		SDKHook(ent, SDKHook_Touch, OnFlagTouch );
	}
}

public Action:MoveTimer(Handle:timer)
{
	for(new client=1;client<=MaxClients;client++)
	{
		if(IsClientInGame(client))
		{
			if(IsPlayerAlive(client))
			{
				new entIndex = -1;
				new entIndex2 = -1;
				GetClientAbsOrigin(client, ClientPosition);
				new Ent = Client_GetClosest(ClientPosition, client);
				new team = GetClientTeam(client);
				if(team == 3)
				{
					GetClientAbsOrigin(client, flag_pos);
					while((entIndex = FindEntityByClassname(entIndex, "item_teamflag")) != INVALID_ENT_REFERENCE)
					{
						new iTeamNum = GetEntProp(entIndex, Prop_Send, "m_iTeamNum");
						if (iTeamNum == 3)
						{
							TeleportEntity(entIndex, flag_pos, NULL_VECTOR, NULL_VECTOR);
						}
					}
				}
				if(Ent != -1 && team == 3)
				{
					decl Float:ClosestClient[3];
					GetClientAbsOrigin(Ent, ClosestClient);
					while((entIndex2 = FindEntityByClassname(entIndex2, "item_teamflag")) != INVALID_ENT_REFERENCE)
					{
						new iTeamNum = GetEntProp(entIndex2, Prop_Send, "m_iTeamNum");
						if (iTeamNum == 2)
						{
							TeleportEntity(entIndex2, ClosestClient, NULL_VECTOR, NULL_VECTOR);
						}
					}
				}
			}
		}
	}
}

stock Client_GetClosest(Float:vecOrigin_center[3], const client)
{
	decl Float:vecOrigin_edict[3];
	new Float:distance = -1.0;
	new closestEdict = -1;
	for(new i=1;i<=MaxClients;i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || (i == client))
			continue;
		GetClientAbsOrigin(i, vecOrigin_edict);
		if(GetClientTeam(i) != GetClientTeam(client))
		{
			new Float:edict_distance = GetVectorDistance(vecOrigin_center, vecOrigin_edict);
			if((edict_distance < distance) || (distance == -1.0))
			{
				distance = edict_distance;
				closestEdict = i;
			}
		}
	}
	return closestEdict;
}
