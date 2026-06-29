#include <sourcemod>

public Plugin:myinfo = {name = "L4D panic enabler", author = "", description = "", version = "0.1", url = ""};
public OnPluginStart()
{
	CreateConVar("sm_panic_enabler_version", "0.1", "L4D panic enabler", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("director_force_panic_event", Command_panic, ADMFLAG_GENERIC, "director_force_panic_event")
	SetCommandFlags("director_force_panic_event",GetCommandFlags("director_force_panic_event")^FCVAR_CHEAT)
}
public Action:Command_panic(client, args)
{
	return Plugin_Continue;
}