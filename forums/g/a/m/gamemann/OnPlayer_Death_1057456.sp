#pragma semicolon 1

#include <sourcemod>
#include <sdktools_functions>
#include <sdktools>

#define FCVAR_FLAGS
#define PLUGIN_VERSION	"1.0.0"


new Handle:PlayerDeathTimer = INVALID_HANDLE;
new Handle:PlayerDeathTimerTimer = INVALID_HANDLE;
new Handle:Enabled = INVALID_HANDLE;

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
	CreateConVar("sm_plugin_version", PLUGIN_VERSION, "the plugins version",FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEvent("player_death",PlayerDeath);
	Enabled = CreateConVar("sm_enabled", "1", "toggles wheather the plugin is enabled or not");
	PlayerDeathTimer = CreateConVar("sm_player_spawn_time", "45", "how many seconds it takes until the player spawns", FCVAR_FLAGS,true,1.0);
	SetConVarBounds(PlayerDeathTimer, ConVarBound_Lower, true,1.0);
	////
	//load our config
	////
	AutoExecConfig(true, "l4d2_player_death_timer_spawner");
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
	new bot = CreateFakeClient("bot1");
	if (bot == 0) return;
	
	ChangeClientTeam(bot,2);
	DispatchKeyValue(bot,"classname","survivorbot");
	DispatchSpawn(bot);
	CreateTimer(0.1,BotKicker,bot);
}

public Action:BotKicker(Handle:Timer, any:Client)
{
	if(IsClientConnected(Client) && IsFakeClient(Client))
	{
		KickClient(Client, "Kicking Fake Client.");
	}
	return Plugin_Handled;
}


	



