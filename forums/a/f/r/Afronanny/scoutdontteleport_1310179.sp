#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

//Contents of teleportcheck.inc for web compiler
forward bool:OnTeleportCheck(client, bool:actual);

 public Extension:__ext_teleportcheck =
{
	name = "teleportcheck",
	file = "teleportcheck.ext",
#if defined AUTOLOAD_EXTENSIONS
	autoload = 1,
#else
	autoload = 0,
#endif
#if defined REQUIRE_EXTENSIONS
	required = 1,
#else
	required = 0,
#endif
};
//End teleportcheck.inc
new Handle:g_hCvarEnabled;

public Plugin:myinfo = 
{
	name = "Scouts Can't Teleport",
	author = "Afronanny",
	description = "Scouts cannot take teleporters",
	version = "1.0",
	url = "http://www.afronanny.org/"
}

public OnPluginStart()
{
	CreateConVar("sm_teleportcheck_version", "1.0", _, FCVAR_NOTIFY);
	g_hCvarEnabled = CreateConVar("sm_teleportcheck_enabled", "1");
}

public bool:OnTeleportCheck(client, bool:actual)
{
	if (TF2_GetPlayerClass(client) == TFClass_Scout && GetConVarBool(g_hCvarEnabled))
	{
		return false;
	} else {
		return actual;
	}
}
