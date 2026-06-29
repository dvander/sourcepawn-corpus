#include <sourcemod>
#include <sdktools_functions>
#include <sdktools>



new Handle:PlayerDeathTimer = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "OnPlayerDeath",
	author = "gamemann",
	description = "When a player dies they get a timer and when the timer is finished they spawn back again.",
	version = "1",
	url = "http://sourcemod.net/",
};

public OnPluginStart()
{
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false))
		SetFailState("Plugin supports Left 4 Dead 2 only.");
	PlayerDeathTimer = CreateConVar("sm_player_spawn_time", "45", "how many seconds it takes until the player spawns", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_SPONLY, true, 1.00, true, 900.00);
	SetConVarBounds(PlayerDeathTimer, ConVarBound_Lower, true,1.00);
	CreateConVar("sm_plugin_version", "1", "the plugins version", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEvent("player_death", PlayerDeath);
	//hooking convarchanges
	HookConVarChange(PlayerDeathTimer, ConVarChanged);

	//load our config
	AutoExecConfig(true, "l4d2playerdeathtimerspawner");
	UpgradeConVars();
}

public OnMapStart()
{
	UpgradeConVars();
}

public ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	UpgradeConVars();
}

UpgradeConVars()
{
		SetConVarInt(FindConVar("player_death_time"), GetConVarInt(PlayerDeathTimer));
}

public PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(45.0,PlayerDeathT,TIMER_REPEAT);
	return;
}

public Action:PlayerDeathT(Handle:htimer, any:Client)
{
	SpawnClient()
}

SpawnClient()
{
	// Spawn bot survivor.
	new Bot = SpawnClient();
	if(Bot == 0) 
	return;

	ChangeClientTeam(Bot, 2);
	DispatchKeyValue(Bot, "classname", "SurvivorBot");
}
