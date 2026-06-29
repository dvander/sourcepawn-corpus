#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

new Float:flag_pos[3];

public Plugin:myinfo=
{
	name= "AFK Bot Payload Support",
	author= "EfeDursun125",
	description= "",
	version= "1.0",
	url= "http://steamcommunity.com/profiles/76561198039186809"
}

public OnPluginStart()
{
	HookEvent("teamplay_round_start", RoundStarted);
}

public OnMapStart()
{
	char currentMap[PLATFORM_MAX_PATH];
	GetCurrentMap(currentMap, sizeof(currentMap));
	if(StrContains(currentMap, "pl_" , false) != -1)
	{
		CreateTimer(0.1, MoveTimer,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(1.0, FindFlag,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
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

public Action:RoundStarted(Handle: event , const String: name[] , bool: dontBroadcast)
{
	char currentMap[PLATFORM_MAX_PATH];
	GetCurrentMap(currentMap, sizeof(currentMap));
	if(StrContains(currentMap, "pl_" , false) != -1)
	{
		CreateTimer(0.1, LoadStuff);
	}
}

public Action:LoadStuff(Handle:timer)
{
	decl String:nameblue[] = "bluebotflag";
	decl String:classblue[] = "item_teamflag";
	new ent = FindEntityByTargetname(nameblue, classblue);
	if(ent != -1)
	{
		//Do nothing.
	}
	else
	{
		new teamflags = CreateEntityByName("item_teamflag");
		if(IsValidEntity(teamflags))
		{
			DispatchKeyValue(teamflags, "targetname", "bluebotflag");
			DispatchKeyValue(teamflags, "trail_effect", "0");
			DispatchKeyValue(teamflags, "ReturnTime", "1");
			DispatchKeyValue(teamflags, "flag_model", "models/empty.mdl");
			DispatchSpawn(teamflags);
			SetEntProp(teamflags, Prop_Send, "m_iTeamNum", 2);
		}
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
	decl String:nameblue[] = "bluebotflag";
	decl String:classblue[] = "item_teamflag";
	new cartEnt = -1;
	while((cartEnt = FindEntityByClassname(cartEnt, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
	{
		new iTeamNumCart = GetEntProp(cartEnt, Prop_Send, "m_iTeamNum");
		if (iTeamNumCart == 2)
		{
			GetEntPropVector(cartEnt, Prop_Data, "m_vecAbsOrigin", flag_pos);
			new ent = FindEntityByTargetname(nameblue, classblue);
			if(ent != -1)
			{
				new randompos = GetRandomInt(1,2);
				switch(randompos)
				{
					case 1:
					{
						flag_pos[0] += 44.0;
						flag_pos[1] += 14.0;
						flag_pos[2] -= 60.0;
					}
					case 2:
					{
						flag_pos[0] += -44.0;
						flag_pos[1] += -14.0;
						flag_pos[2] -= 60.0;
					}
				}
				TeleportEntity(ent, flag_pos, NULL_VECTOR, NULL_VECTOR);
			}
		}
	}
}

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
