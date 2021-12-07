#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

new Float:flag_pos[3];

public Plugin:myinfo=
{
	name= "MvM Bots",
	author= "tRololo312312",
	description= "Allows Bots to play MvM",
	version= "1.3",
	url= "http://steamcommunity.com/profiles/76561198039186809"
}

public OnPluginStart()
{
	HookEvent("mvm_begin_wave", RoundStarted);
	HookEvent("mvm_wave_complete", RoundStarted2);
	HookEvent("mvm_wave_failed", RoundStarted2);
}

public OnMapStart()
{
	CreateTimer(0.1, MoveTimer,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(315.0, InfoTimer,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:InfoTimer(Handle:timer)
{
	PrintToChatAll("This server is using MvM Bots plugin by tRololo312312");
}

public Action:RoundStarted2(Handle: event , const String: name[] , bool: dontBroadcast)
{
	decl String:nameflag[] = "redbotflag";
	decl String:class[] = "item_teamflag";
	new ent = FindEntityByTargetname(nameflag, class);
	if(ent != -1)
	{
		AcceptEntityInput(ent, "Kill");
	}
}

public Action:RoundStarted(Handle: event , const String: name[] , bool: dontBroadcast)
{
	CreateTimer(1.0, LoadStuff);
}

public Action:LoadStuff(Handle:timer,any:userid)
{
	new teamflags = CreateEntityByName("item_teamflag");
	if(IsValidEntity(teamflags))
	{
		DispatchKeyValue(teamflags, "targetname", "redbotflag");
		DispatchKeyValue(teamflags, "trail_effect", "0");
		DispatchKeyValue(teamflags, "ReturnTime", "1");
		DispatchKeyValue(teamflags, "flag_model", "models/empty.mdl");
		DispatchSpawn(teamflags);
		SetEntProp(teamflags, Prop_Send, "m_iTeamNum", 3);
	}
	CreateTimer(0.5, LoadStuff2);
}

public Action:LoadStuff2(Handle:timer)
{
	//Changed to one of the Golden Rules(1.1)
	decl String:name[] = "redbotflag";
	decl String:class[] = "item_teamflag";
	new ent = FindEntityByTargetname(name, class);
	if(ent != -1)
	{
		SDKHook(ent, SDKHook_StartTouch, OnFlagTouch );
		SDKHook(ent, SDKHook_Touch, OnFlagTouch );
	}
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

//danke Forlix for dis stock :))
stock FindEntityByTargetname(const String:targetname[], const String:classname[])
{
  decl String:namebuf[32];
  new index = -1;
  namebuf[0] = '\0';
 
  while(strcmp(namebuf, targetname) != 0
    && (index = FindEntityByClassname(index, classname)) != -1)
    GetEntPropString(index, Prop_Data, "m_iName", namebuf, sizeof(namebuf));
 
  return(index);
}

public Action:MoveTimer(Handle:timer)
{
	for(new client=1;client<=MaxClients;client++)
	{
		if(IsClientInGame(client))
		{
			if(IsPlayerAlive(client))
			{
				new team = GetClientTeam(client);
				decl String:name[] = "redbotflag";
				decl String:class[] = "item_teamflag";
				new iEnt = -1;
				new ent = FindEntityByTargetname(name, class);
				if(ent != -1)
				{
					if((iEnt = FindEntityByClassname(iEnt, "tank_boss")) != INVALID_ENT_REFERENCE)
					{
						if(IsValidEntity(iEnt))
						{
							decl Float:TankLoc[3];
							GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", TankLoc);
							TankLoc[2] += 20.0;
							TeleportEntity(ent, TankLoc, NULL_VECTOR, NULL_VECTOR);
						}
					}
					else if(team == 3)
					{
						GetClientAbsOrigin(client, flag_pos);
						TeleportEntity(ent, flag_pos, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
		}
	}
}
