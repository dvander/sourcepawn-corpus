#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>

#define PLUGIN_VERSION "1.0"

//handles
//tank health and speed
new Handle:TankHealth = INVALID_HANDLE;
new Handle:TankSpeed = INVALID_HANDLE;

//timers
new Handle:TankHealthTimer = INVALID_HANDLE;
new Handle:TankSpeedTimer = INVALID_HANDLE;

//other
new Handle:Enabled = INVALID_HANDLE;

//floats
//tank and speed random health 
new Float:RandomHealth
new Float:RandomSpeed


public Plugin:myinfo =
{
	name = "random tank",
	author = "gamemann",
	description = "gives a tank random speed and health!",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	//hooking events
	HookEvent("round_start", Event_Round_Start);
	HookEvent("tank_spawn", Event_Tank_Spawn);

	//convars
	CreateConVar("sm_version", PLUGIN_VERSION, "the plugin's version", FCVAR_NOTIFY);
	Enabled = CreateConVar("sm_enabled", "1", "toggles whether the plugin is enabled or not");
	
	//finding convars
	TankHealth = FindConVar("z_tank_health");
	TankSpeed = FindConVar("z_tank_speed");

	// loading our config
	AutoExecConfig(true, "l4d2_random_tank");
}

public Event_Round_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	//on round start the messaging TIMER
	CreateTimer(10.0, ClientMessage);
}

public Action:ClientMessage(Handle:htimer, any:client)
{
	decl String:name[128];
	PrintToChat(client, "this server is running the plugin random tank so the tank has random speed or health!", name);
}

public Event_Tank_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	TankSpeedTimer = CreateTimer(0.3, TankSpeedTimerT);
	TankHealthTimer = CreateTimer(0.4, TankHealthTimerT);
	
	//message
	decl String:Name
	PrintToChatAll("Tank speed and health is being set!", Name);
}

public Action:TankSpeedTimerT(Handle:htimer)
{
	static NumPrinted = 0
	if(NumPrinted++ <= 2)
	{
		RandomSpeed = GetRandomInt(1, 500)
		SetConVarInt(TankSpeed, RandomSpeed)
		NumPrinted = 0
	}
}

public Action:TankHealthTimerT(Handle:htimer)
{
	static NumPrinted = 0
	if(NumPrinted++ <= 2)
	{
		RandomHealth = GetRandomInt(1, 10000)
		SetConVarInt(TankHealth, RandomHealth)
		NumPrinted = 0
	}
}
	

