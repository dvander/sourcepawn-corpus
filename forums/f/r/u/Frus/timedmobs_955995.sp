
#include <sourcemod>
#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "Timed Mobs",
	author = "Crazydog",
	description = "Spawns mobs every x seconds, where x is a specified time",
	version = "1.0",
	url = ""
}


new Handle:sm_timedmobs_interval = INVALID_HANDLE
new Handle:mobspawner = INVALID_HANDLE

public OnPluginStart()
{
	CreateConVar("sm_timedmobs_version", PLUGIN_VERSION, "Timed Mobs Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD)
	sm_timedmobs_interval = CreateConVar("sm_timedmobs_interval", "30", "Time between mobs (seconds)", FCVAR_NOTIFY, true, 0.0)
	HookConVarChange(sm_timedmobs_interval, IntervalChange)
}
public OnMapStart(){
	mobspawner = CreateTimer(GetConVarFloat(sm_timedmobs_interval), spawnMob, _, TIMER_REPEAT)
}

public OnMapEnd(){
	KillTimer(mobspawner)
}

public Action:spawnMob(Handle:timer){
	if (!getClient()) return Plugin_Continue;
	new String:spawnCommand[32], defaultFlags
	spawnCommand = "z_spawn"
	defaultFlags = GetCommandFlags(spawnCommand)
	SetCommandFlags(spawnCommand, defaultFlags & ~FCVAR_CHEAT)
	FakeClientCommand(getClient(), "z_spawn mob auto")
	SetCommandFlags(spawnCommand, defaultFlags)
	return Plugin_Continue
}

public IntervalChange(Handle:convar, const String:oldValue[], const String:newValue[]){
	if(mobspawner != INVALID_HANDLE){
		new Float:newTime = StringToFloat(newValue)
		KillTimer(mobspawner)
		mobspawner = INVALID_HANDLE
		mobspawner = CreateTimer(newTime, spawnMob, _, TIMER_REPEAT)
	}
}

// Thanks mi123645 :P
public getClient()
{
	for (new i=1;i<=GetMaxClients();i++){
		if (IsClientConnected(i) && IsClientInGame(i) && (!IsFakeClient(i))){
			return i;
		}
	}
	return 0;
}