/*
	Credits: 
	MaTi: http://forums.alliedmods.net/showthread.php?t=102606
	- The barrel spawning code belongs to that player, I just copy/pasted/edited.
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

enum RallyBarrels
{
	totalBarrels = 0,
	Float:locationX = 0,
	Float:locationY = 0,
	Float:locationZ = 0
}

new Handle:p_Enabled = INVALID_HANDLE;
new Handle:p_Amount = INVALID_HANDLE;
new Handle:p_Delay = INVALID_HANDLE;
new p_Players[MAXPLAYERS + 1][RallyBarrels];

public Plugin:myinfo = 
{
	name = "Rally Racing Barrels",
	author = "Twisted|Panda",
	description = "Allows a player to drop a barrel at the current position if they're racing.",
	version = PLUGIN_VERSION,
	url = "http://alliedmods.net/"
};

public OnPluginStart() 
{ 
	CreateConVar("sm_rrbarrels_version", PLUGIN_VERSION, "Rally Racing Barrels Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	p_Enabled = CreateConVar("sm_rrbarrels", "1", "Enables or disables any feature of this plugin.");
	p_Amount = CreateConVar("sm_rrbarrels_amount", "1", "The maximum number of barrels a player is allowed to spawn.");
	p_Delay = CreateConVar("sm_rrbarrels_delay", "1.0", "The delay in seconds before a spawn barrel drops from the player (prevents it from getting stuck?)");
	AutoExecConfig(true, "sm_rrbarrels");

	RegConsoleCmd("sm_drop", Command_Drop);
	RegConsoleCmd("sm_barrel", Command_Drop);
}

public OnMapStart()
{
	PrecacheModel("models/props_c17/oildrum001_explosive.mdl");
}

public OnClientPostAdminCheck(client)
{
	if(GetConVarInt(p_Enabled))
	{
		p_Players[client][totalBarrels] = 0;
		p_Players[client][locationX] = 0.0;
		p_Players[client][locationY] = 0.0;
		p_Players[client][locationZ] = 0.0;
	}
}

public Action:Command_Drop(client, args)
{
	if(p_Players[client][totalBarrels] < GetConVarInt(p_Amount))
	{
		if(GetClientTeam(client) == 3)
		{
			p_Players[client][totalBarrels]++;

			new Float:curPosition[3];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", curPosition);
			
			p_Players[client][locationX] = curPosition[0];
			p_Players[client][locationY] = curPosition[1];
			p_Players[client][locationZ] = curPosition[2];
			
			CreateTimer(GetConVarFloat(p_Delay), spawnBarrel, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
			PrintToChat(client, "[SM] You must be racing to use this command!");
	}
	else
		PrintToChat(client, "[SM] You do not have any barrels left!");


}

public Action:spawnBarrel(Handle:timer, any:client)
{
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != 3)
		return Plugin_Handled;

	new Float:curPosition[3];
	curPosition[0] = p_Players[client][locationX];
	curPosition[1] = p_Players[client][locationY];
	curPosition[2] = p_Players[client][locationZ];
			
	new EntitySpawnIndex = CreateEntityByName("prop_physics");
	SetEntityModel(EntitySpawnIndex,"models/props_c17/oildrum001_explosive.mdl");
	DispatchSpawn(EntitySpawnIndex);
	SetEntityMoveType(EntitySpawnIndex, MOVETYPE_VPHYSICS);
	SetEntProp(EntitySpawnIndex, Prop_Data, "m_CollisionGroup", 5);
	SetEntProp(EntitySpawnIndex, Prop_Data, "m_nSolidType", 6);
	TeleportEntity(EntitySpawnIndex, curPosition, NULL_VECTOR, NULL_VECTOR);
	
	return Plugin_Continue;
}