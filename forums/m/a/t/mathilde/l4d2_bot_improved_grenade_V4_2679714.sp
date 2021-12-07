#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define STARTSHOOTING 1
#define STOPSHOOTING 0
static shoot[MAXPLAYERS + 1] = 0;
#define CVAR_FLAGS			FCVAR_PLUGIN|FCVAR_NOTIFY
new Handle:sm_bot_grenade_pipe_interval = INVALID_HANDLE;
new Handle:sm_bot_grenade_pipe_short_distance = INVALID_HANDLE;
new Handle:sm_bot_grenade_pipe_long_distance = INVALID_HANDLE;
new Handle:sm_bot_grenade_pipe_short_common_limit = INVALID_HANDLE;
new Handle:sm_bot_grenade_pipe_long_common_limit = INVALID_HANDLE;
new Handle:sm_bot_grenade_pipe_vicinity_distance = INVALID_HANDLE;
public OnPluginStart()
{
	sm_bot_grenade_pipe_interval = CreateConVar("sm_bot_grenade_pipe_interval", "15.0", "interval for grenade", FCVAR_NOTIFY);
	sm_bot_grenade_pipe_short_distance = CreateConVar("sm_bot_grenade_pipe_short_distance", "750.0", "check distance within this range", FCVAR_NOTIFY);
	sm_bot_grenade_pipe_long_distance = CreateConVar("sm_bot_grenade_pipe_long_distance", "1200.0", "check distance within this range", FCVAR_NOTIFY);
	sm_bot_grenade_pipe_short_common_limit = CreateConVar("sm_bot_grenade_pipe_short_common_limit", "15", "Common limit within checked distance", FCVAR_NOTIFY);
	sm_bot_grenade_pipe_long_common_limit = CreateConVar("sm_bot_grenade_pipe_long_common_limit", "25", "Common limit within checked distance", FCVAR_NOTIFY);
	sm_bot_grenade_pipe_vicinity_distance = CreateConVar("sm_bot_grenade_pipe_vicinity_distance", "500.0", "vicinity check around target radius", FCVAR_NOTIFY);
	CreateTimer(GetConVarFloat(sm_bot_grenade_pipe_interval), ThrowGrenadePipe, _, TIMER_REPEAT);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (IsPlayerAlive(client) && IsFakeClient(client))
	{
		new grenade = GetPlayerWeaponSlot(client, 2);
		if (IsValidEntity(grenade))
		{
			decl String:classname[128];
			GetEntityClassname(grenade, classname, sizeof(classname));
			if (StrEqual(classname, "weapon_pipe_bomb"))
			{
				if (shoot[client] == STARTSHOOTING)
				{
					BotTargeting(client);
					buttons |= IN_ATTACK;
				}
				else if (shoot[client] == STOPSHOOTING)
				{
					buttons &= ~IN_ATTACK;
				}
			}
		}
	}
}

stock GetRandomPlayerPipe(team)
{
	new iClients[MaxClients+1];
	new iNumClients;
	for(new i = 1 ; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == team)
		{
			new String:grenade[32];
			if (IsValidEdict(GetPlayerWeaponSlot(i, 2)))
			{
				GetEdictClassname(GetPlayerWeaponSlot(i, 2), grenade, sizeof(grenade));
				if (StrEqual(grenade, "weapon_pipe_bomb"))
				{
					iClients[iNumClients++] = i;
				}
			}
		}
	}
	return (iNumClients == 0) ? -1 : iClients[GetRandomInt(0, iNumClients-1)];
}
public BotTargeting(client)
{
	decl Float:TargetArea[3];
	new highestCount = 0;
	for (new entity = 0; entity < 2048; entity++)
	{
		if(IsCommonInfected(entity))
		{
			decl Float:f_EntPos[3], Float:f_ClientPos[3];
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", f_EntPos);
			GetClientAbsOrigin(client, f_ClientPos);
 			if (GetVectorDistance(f_EntPos, f_ClientPos) <= GetConVarFloat(sm_bot_grenade_pipe_long_distance))
			{
				new count = 0;
				for (new i = 0; i < 2048; i++)
				{
					if(IsCommonInfected(i))
					{
						decl Float:f_EntPosVicinity[3];
						GetEntPropVector(i, Prop_Send, "m_vecOrigin", f_EntPosVicinity);
						if (GetVectorDistance(f_EntPos, f_EntPosVicinity) <= GetConVarFloat(sm_bot_grenade_pipe_vicinity_distance))
						{
							count++;
						}
					}
				}
	
				if(count > highestCount)
				{
					highestCount = count;
					GetEntPropVector(entity, Prop_Send, "m_vecOrigin", TargetArea);
				}
			}
			
		}
	}
 	decl Float:EyePos[3], Float:AimAtArea[3], Float:AimAngles[3];
	GetClientEyePosition(client, EyePos);
	MakeVectorFromPoints(EyePos, TargetArea, AimAtArea);
	GetVectorAngles(AimAtArea, AimAngles);
	TeleportEntity(client,  NULL_VECTOR, AimAngles, NULL_VECTOR);
}
public BotThrowPipeBomb(client)
{
	FakeClientCommand(client, "use weapon_pipe_bomb");
	CreateTimer(0.2, Command_MakeBotShoot, GetClientUserId(client));
	CreateTimer(1.0, StopShooting, GetClientUserId(client));
}
public Action:ThrowGrenadePipe(Handle:timer)
{
	if (!IsServerProcessing())
	{
		return;
	}
	new client = GetRandomPlayerPipe(2);
	new countShort = 0;
	new countLong = 0;
	for (new entity = 0; entity < 2048; entity++)
	{
		if(IsCommonInfected(entity))
		{
			decl Float:f_EntPos[3], Float:f_ClientPos[3];
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", f_EntPos);
			GetClientAbsOrigin(client, f_ClientPos);
			if (GetVectorDistance(f_EntPos, f_ClientPos) <= GetConVarFloat(sm_bot_grenade_pipe_short_distance))
			{
				countShort++;
				countLong++;
			}
			else if(GetVectorDistance(f_EntPos, f_ClientPos) <= GetConVarFloat(sm_bot_grenade_pipe_long_distance))
			{
				countLong++;
			}
		}
	}
	if(countShort >= GetConVarInt(sm_bot_grenade_pipe_short_common_limit) || countLong >= GetConVarInt(sm_bot_grenade_pipe_long_common_limit))
	{
		BotThrowPipeBomb(client);
		
		new say = GetRandomInt(1,5);
		if(say == 1)
		{
			FakeClientCommand(client, "say Pipe bomb's out!!!");
		}
		else if(say == 2)
		{
			FakeClientCommand(client, "say I'm throwing a pipe bomb!!!");
		}
		else if(say == 3)
		{
			FakeClientCommand(client, "say Eat this you bastards!!!");
		}
		else if(say == 4)
		{
			FakeClientCommand(client, "say Incoming Pipe bomb!!!");
		}
		else if(say == 5)
		{
			FakeClientCommand(client, "say Watch out, Pipe bomb!!!");
		}
	}

}
public Action:Command_MakeBotShoot(Handle:Timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	shoot[client] = STARTSHOOTING;
}

public Action:StopShooting(Handle:Timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	shoot[client] = STOPSHOOTING;
}
stock bool:IsCommonInfected(iEntity)
{
    if(iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
    {
        decl String:strClassName[64];
        GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
        return StrEqual(strClassName, "infected");
    }
    return false;
}  

stock bool:IsInfected(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3)
	{
		return true;
	}
	return false;
}

stock bool:IsSurvivorBot(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsFakeClient(client) && GetClientTeam(client) == 2)
	{
		return true;
	}
	return false;
}