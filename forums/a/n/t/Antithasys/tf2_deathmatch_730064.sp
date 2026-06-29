#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.0.0"

new Handle:tf2d_enabled = INVALID_HANDLE;
new bool:IsWaiting = false;
new String:entsToRemove[6][] = 
{
	"team_control_point_master",
	"team_control_point",
	"trigger_capture_area",
	"func_capturezone",
	"item_teamflag",
	"team_control_point_round"
};

public Plugin:myinfo =
{
	name = "TF2 DeathMatch",
	author = "FlyingMongoose, Antithasys",
	description = "TF2 DeathMatch",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("tf2deathmatch_ver", PLUGIN_VERSION, "TF2 DeathMatch", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	tf2d_enabled = CreateConVar("tf2d_enabled", "1", "Enables/Disables TF2 DeathMatch", _, true, 0.0, true, 1.0);
	HookEvent("teamplay_round_start", Event_RoundStart, EventHookMode_Post);
}

public OnMapStart()
{
	IsWaiting = true;
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (IsWaiting) {
		IsWaiting = false;
		return;
	}
	if (GetConVarBool(tf2d_enabled))
		RemoveEnts();
}

stock RemoveEnts()
{
	new iCurrentEnt = -1;
	for(new i = 0; i < sizeof(entsToRemove); i++) {
		while ((iCurrentEnt = FindEntityByClassname(iCurrentEnt, entsToRemove[i])) != -1) {
			AcceptEntityInput(iCurrentEnt, "Disable");
		}
	}
}
