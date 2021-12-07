#define PLUGIN_NAME	"[CSS] QuickJoin 1.0"
#define PLUGIN_VERSION	"1.0"
#define PLUGIN_URL	"www.sourcemod.net"

#include <sourcemod>

public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = "NineTyNine",
	description = "A simple plugin that lets a player join a team quickly.",
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

public OnPluginStart()
{
	CreateConVar("sm_qj_version", PLUGIN_VERSION, "QuickJoin Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	RegConsoleCmd("sm_spec", QJTurnClientToSpectate);
	RegConsoleCmd("sm_spectate", QJTurnClientToSpectate);
	RegConsoleCmd("sm_away", QJTurnClientToSpectate);
	RegConsoleCmd("sm_afk", QJTurnClientToSpectate);
	RegConsoleCmd("sm_ct", QJTurnClientToCounterTerrorist);
	RegConsoleCmd("sm_counterterrorist", QJTurnClientToCounterTerrorist);
	RegConsoleCmd("sm_t", QJTurnClientToTerrorist);
	RegConsoleCmd("sm_terrorist", QJTurnClientToTerrorist);
}

public Action:QJTurnClientToSpectate(client, argCount)
{
	ChangeClientTeam(client, 1)
	PrintToChat( client, "\x03[\x01QuickJoin\x03]\x01 You Have Been Moved To Spectators." );
	return Plugin_Handled;
}

public Action:QJTurnClientToTerrorist(client, args)
{ 
	ClientCommand(client, "jointeam 2");
	PrintToChat( client, "\x03[\x01QuickJoin\x03]\x01 You Have Been Moved To Terrorists." );
	return Plugin_Handled;
}
public Action:QJTurnClientToCounterTerrorist(client, args)
{ 
	ClientCommand(client, "jointeam 3");
	PrintToChat( client, "\x03[\x01QuickJoin\x03]\x01 You Have Been Moved To Counter-Terrorists." );
	return Plugin_Handled;
}