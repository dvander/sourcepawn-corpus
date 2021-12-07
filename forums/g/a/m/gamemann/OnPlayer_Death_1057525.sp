
#include <sourcemod>
#include <sdktools_functions>
#include <sdktools>

#define PLUGIN_VERSION	"1.0.0"


new Handle:PlayerDeathTimer = INVALID_HANDLE;
new Handle:PlayerDeathTimerTimer = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "OnPlayerDeath",
	author = "gamemann",
	description = "When a player dies they get a timer and when the timer is finished they spawn back again.",
	version = PLUGIN_VERSION,
	url = "http://sourcemod.net/",
};

public OnPluginStart()
{
	PlayerDeathTimer = CreateConVar("sm_player_spawn_time", "45", "how many seconds it takes until the player spawns", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_SPONLY, true, 1.00, true, 900.00);
	SetConVarBounds(PlayerDeathTimer, ConVarBound_Lower, true,1.00);
	CreateConVar("sm_plugin_version", PLUGIN_VERSION, "the plugins version", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEvent("player_death", PlayerDeath);
	HookEvent("round_end", RoundEnd);
	////////
	//hooking convarchanges
	////////
	////
	//load our config
	////

	AutoExecConfig(true, "l4d2playerdeathtimerspawner");
}

public PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	PlayerDeathTimerTimer = CreateTimer(PlayerDeathTimer, PlayerDeathT);
}

public Action:PlayerDeathT(Handle:timer, any:Client)
{
	SpawnFakeClient()
}

SpawnFakeClient()
{
	// Spawn bot survivor.
	new Bot = CreateFakeClient("SurvivorBot");
	if (Bot == 0) return;

	ChangeClientTeam(Bot, 2);
	DispatchKeyValue(Bot, "classname", "SurvivorBot");
	CreateTimer(0.1,BotKicker, Bot);
}

public Action:BotKicker(Handle:Timer, any:Client)
{
	if(IsClientConnected(Client) && IsFakeClient(Client))
	{
		KickClient(Client, "Kicking Fake Client.");
	}
	return Plugin_Handled;
}

public RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	return Plugin_Handled;
}

public OnRoundLost(Handle:event)
{
	new statement = GetEventInt(event, "PlayerDeath")
	if (statement == 1) 
	RoundEnd == false;
	return Plugin_Stop;
}



