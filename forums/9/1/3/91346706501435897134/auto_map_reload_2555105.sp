#include <sourcemod>



public Plugin myinfo =
{
	name = "auto_map_reload",
	author = "91346706501435897134",
	description = "automatically reloads the current map",
	version = "1.1",
};



ConVar sm_auto_map_reload_time = null;



public void OnPluginStart()
{
	sm_auto_map_reload_time = CreateConVar("sm_auto_map_reload_time", "43200.000000", "timer in seconds (WARNING: RELOAD MAP FOR CHANGES TO TAKE EFFECT)", FCVAR_NOTIFY, true, 3600.000000, true, 86400.000000);
	AutoExecConfig(true, "plugin.auto_map_reload", "sourcemod");
}



public void OnMapStart()
{
	float time = GetConVarFloat(sm_auto_map_reload_time);
	CreateTimer(time-60, notify_map_reload);
}



public Action notify_map_reload(Handle timer)
{
	PrintHintTextToAll(">> map reloading in 60.0 seconds <<");
	CreateTimer(60.000000, map_reload);
}



public Action map_reload(Handle timer)
{
	char current_map_name[255];
	GetCurrentMap(current_map_name, sizeof(current_map_name));
	ServerCommand("changelevel %s", current_map_name);	
}