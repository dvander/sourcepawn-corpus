/*
	Credits: 
	MaTi: http://forums.alliedmods.net/showthread.php?t=102606
	- The barrel spawning code belongs to that player, I just copy/pasted/edited.
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.4"

#define LOCATION_X 0
#define LOCATION_Y 1
#define LOCATION_Z 2
#define LOCATION_DATA 3

new Handle:p_Enabled = INVALID_HANDLE;
new Handle:p_Cash = INVALID_HANDLE;
new Handle:p_Loss = INVALID_HANDLE;
new Handle:p_Time = INVALID_HANDLE;
new Handle:p_Barrels = INVALID_HANDLE;
new Handle:p_Delay = INVALID_HANDLE;

enum RallyRacing
{
	totalCash = 0,
	Float:totalReward = 0,
	totalBarrels = 0,
	Handle:racingTimer = INVALID_HANDLE
}

new p_Players[MAXPLAYERS + 1][RallyRacing];
new Float:p_Locations[MAXPLAYERS + 1][LOCATION_DATA];

public Plugin:myinfo = 
{
	name = "Rally Racing Extras",
	author = "Twisted|Panda",
	description = "Provides several extra features to be used in conjunction with the Rally Racing mod.",
	version = PLUGIN_VERSION,
	url = "http://alliedmods.net/"
};

public OnPluginStart() 
{ 
	CreateConVar("sm_rrextras_version", PLUGIN_VERSION, "Rally Racing Extras Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	p_Enabled = CreateConVar("sm_rrextras", "1", "Enables or disables any feature of this plugin.");
	
	p_Cash = CreateConVar("sm_rrextras_cash", "180", "The amount of cash players will receive per each race.");
	p_Loss = CreateConVar("sm_rrextras_loss", "0.5", "The degree the player's reward decreases each occurance of sm_rrextras_time.");

	p_Barrels = CreateConVar("sm_rrextras_amount", "1", "The number of barrels players will receive per race.");
	p_Delay = CreateConVar("sm_rrextras_delay", "0.5", "The delay in seconds before a spawned barrel drops from the player (prevents it from getting stuck?)");
	
	p_Time = CreateConVar("sm_rrextras_time", "0.5", "The degree of accuracy for the reoccuring client function. The more accurate, the more resources it may require.");
	AutoExecConfig(true, "sm_rrextras");

	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
	HookEvent("player_team", OnPlayerTeam, EventHookMode_Post);

	RegConsoleCmd("sm_drop", Command_Drop);
	RegConsoleCmd("sm_barrel", Command_Drop);
	RegConsoleCmd("kill", Command_Kill);
}

public OnPluginEnd()
{
	for(new i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			if(p_Players[i][racingTimer] != INVALID_HANDLE)
			{
				KillTimer(p_Players[i][racingTimer]);
				p_Players[i][racingTimer] = INVALID_HANDLE;
			}
}

public OnMapStart()
{
	PrecacheModel("models/props_c17/oildrum001_explosive.mdl");
}

public OnClientPostAdminCheck(client)
{
	if(GetConVarInt(p_Enabled))
	{
		p_Players[client][totalCash] = 0;
		p_Players[client][totalReward] = 0.0;
		p_Players[client][totalBarrels] = 0;
		p_Players[client][racingTimer] = INVALID_HANDLE;
		
		for(new i = 0; i < LOCATION_DATA; i++)
			p_Locations[client][i] = 0.0;
	}
}

public OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(p_Enabled))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client))
			return;

		new newTeam = GetEventInt(event, "team");
		new oldTeam = GetEventInt(event, "oldteam");
		//Prevent players from joining their same team to create issues.
		if(newTeam == GetClientTeam(client))
			return;

		//If the player is moved to the racing team, start their timer.
		if(oldTeam == 2 && newTeam == 3)
		{
			p_Players[client][totalReward] = float(GetConVarInt(p_Cash));
			p_Players[client][totalBarrels] = GetConVarInt(p_Barrels);
			p_Players[client][racingTimer] = CreateTimer(GetConVarFloat(p_Time), doClientRace, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}

		//Once the player is moved back to the racing team, give the player his/her reward.
		if(newTeam == 2 && oldTeam == 3)
		{
			new reward = RoundToNearest(p_Players[client][totalReward]);
			if(reward < 0)
				reward = 0;
				
			p_Players[client][totalCash] += reward;
			new cash = p_Players[client][totalCash];
			SetEntProp(client, Prop_Send, "m_iAccount", (cash + reward));
		}
	}
}

public OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(p_Enabled))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client))
			return;
			
		new original = p_Players[client][totalCash];
		SetEntProp(client, Prop_Send, "m_iAccount", original);
	}
}

public Action:doClientRace(Handle:timer, any:client)
{
	new bool:returnFlag;
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client))
		returnFlag = false;
	else
	{
		new clientTeam = GetClientTeam(client);
		if(clientTeam == 2)
			returnFlag = false;
		else
		{
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", p_Locations[client]);
			p_Players[client][totalReward] -= GetConVarFloat(p_Loss);
			returnFlag = true;
		}
	}

	if(returnFlag)
		return Plugin_Continue;
	else
	{
		p_Players[client][racingTimer] = INVALID_HANDLE;
		return Plugin_Stop;
	}
}

public Action:Command_Kill(client, args)
{
	if(GetConVarInt(p_Enabled))
	{
		p_Players[client][totalReward] = 0;
		if(p_Players[client][racingTimer] != INVALID_HANDLE)
		{
			KillTimer(p_Players[client][racingTimer]);
			p_Players[client][racingTimer] = INVALID_HANDLE;
		}
	}

	return Plugin_Handled;
}

public Action:Command_Drop(client, args)
{
	if(p_Players[client][totalBarrels] < GetConVarInt(p_Barrels))
	{
		if(GetClientTeam(client) == 3)
		{
			p_Players[client][totalBarrels]++;
			CreateTimer(GetConVarFloat(p_Delay), spawnBarrel, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
			PrintToChat(client, "[SM] You must be racing to use this command!");
	}
	else
		PrintToChat(client, "[SM] You do not have any barrels left!");
	
	return Plugin_Handled;
}

public Action:spawnBarrel(Handle:timer, any:client)
{
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != 3)
		return Plugin_Handled;

	new EntitySpawnIndex = CreateEntityByName("prop_physics");
	SetEntityModel(EntitySpawnIndex,"models/props_c17/oildrum001_explosive.mdl");
	DispatchSpawn(EntitySpawnIndex);
	SetEntityMoveType(EntitySpawnIndex, MOVETYPE_VPHYSICS);
	SetEntProp(EntitySpawnIndex, Prop_Data, "m_CollisionGroup", 5);
	SetEntProp(EntitySpawnIndex, Prop_Data, "m_nSolidType", 6);
	TeleportEntity(EntitySpawnIndex, p_Locations[client], NULL_VECTOR, NULL_VECTOR);
	
	return Plugin_Continue;
}