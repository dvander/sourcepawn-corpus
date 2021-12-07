#include <sourcemod>
#include <sdktools>

#define DEAD -1

#define PLUGIN_VERSION "1.0"

new TANKS = DEAD;

new Float:ftlPos[3];

new Handle:tank_warp_enable = INVALID_HANDLE;
new Handle:tank_warp_interval = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "[L4D2] Tank Warp",
	author = "Kirisame",
	description = "Tank can warp to players.",
	version = "1.0",
	url = "http://123456.tv"
}

public OnPluginStart()
{
	//Support Left 4 dead 2 only
	decl String:sGame[256];
	GetGameFolderName(sGame, sizeof(sGame));
	if (!StrEqual(sGame, "left4dead2", false))
	{
		SetFailState("Tank Warp system supports Left 4 dead 2 only!");
	}
	
	CreateConVar("l4d2_tankwarp_version", PLUGIN_VERSION, "Version of the Tank Warp System plugin", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	tank_warp_enable  = CreateConVar("tankwarp_enable", "1", "Is Tank Warp enable? (0:OFF 1:ON)", FCVAR_NOTIFY);
	tank_warp_interval = CreateConVar("tankwarp_interval", "10.0", "Tank Warp Delay (Default: 20.0, Must bigger than 5.0)", FCVAR_PLUGIN, true, 5.0, true, 60.0);
	
	HookEvent("tank_spawn", Event_Tank_Spawn);
	HookEvent("round_start", Event_Round_Start);
	
	AutoExecConfig(true, "l4d2_tankwarp");
}


InitData()
{
	TANKS = DEAD;
}

public OnMapStart()
{
	InitData();
}

public OnMapEnd()
{
	InitData();
}

public Action:Event_Round_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	InitData();	
}

public Action:Event_Tank_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new idTankSpawn = GetClientOfUserId(GetEventInt(event, "userid"));
	TANKS = idTankSpawn;
	
	if(GetConVarInt(tank_warp_enable))
	{
		CreateTimer(5.0, GetSurvivorPosition, _, TIMER_REPEAT);
		CreateTimer(GetConVarFloat(tank_warp_interval), FatalMirror, _, TIMER_REPEAT);
	}
}

public Action:GetSurvivorPosition(Handle:timer)
{
	if(IsValidEntity(TANKS) && IsClientInGame(TANKS) && TANKS != DEAD)
	{
		new count = 0;
		new idAlive[MAXPLAYERS+1];
		
		for(new i = 1; i <= MaxClients; i++)
		{
			if(!IsValidEntity(i) || !IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != 2)
				continue;
			idAlive[count] = i;
			count++;
		}
		if(count == 0) return;
		new clientNum = GetRandomInt(0, count-1);
		GetClientAbsOrigin(idAlive[clientNum], ftlPos);
	}
	else
	{
		KillTimer(timer);
	}
}

public Action:FatalMirror(Handle:timer)
{
	if(IsValidEntity(TANKS) && IsClientInGame(TANKS) && TANKS != DEAD)
	{
		SetEntityMoveType(TANKS, MOVETYPE_NONE);
		SetEntProp(TANKS, Prop_Data, "m_takedamage", 0, 1);
		
		CreateTimer(0.1, WarpTimer);
	}
	else
	{
		KillTimer(timer);
	}
}

public Action:WarpTimer(Handle:timer)
{
	if(IsValidEntity(TANKS) && IsClientInGame(TANKS) && TANKS != DEAD)
	{
		decl Float:pos[3];
		
		for(new i = 1; i <= GetMaxClients(); i++)
		{
			if(!IsValidEntity(i) || !IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != 2)
				continue;
		}
		GetClientAbsOrigin(TANKS, pos);
		TeleportEntity(TANKS, ftlPos, NULL_VECTOR, NULL_VECTOR);
		SetEntityMoveType(TANKS, MOVETYPE_WALK);
		SetEntProp(TANKS, Prop_Data, "m_takedamage", 2, 1);
	}
	else
	{
		KillTimer(timer);
	}
}

