//This plugin was created by me(MartinBerthelsen) under the name NineTyNine.
//I changed a bit in the coding, plus I updated to my new name and gave the
//plugin a new name!

#include <sourcemod>

#define PLUGIN_VERSION	"2.0"

public Plugin:myinfo = 
{
	name = "TeamCommands",
	author = "RaT3D // Steam ~ MartinBerthelsen",
	description = "A simple plugin which lets a client join / change teams by typing a command in chat.",
	version = PLUGIN_VERSION,
	url = "http://www.teamroyal.dk/"
}

public OnPluginStart()
{
	//Version ConVar
	CreateConVar("sm_tc_version", PLUGIN_VERSION, "TeamCommands Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	//Chat Commands
	RegConsoleCmd("sm_spec", TCTurnClientToSpectate);
	RegConsoleCmd("sm_spectate", TCTurnClientToSpectate);
	RegConsoleCmd("sm_away", TCTurnClientToSpectate);
	RegConsoleCmd("sm_afk", TCTurnClientToSpectate);
	RegConsoleCmd("sm_ct", TCTurnClientToCounterTerrorist);
	RegConsoleCmd("sm_counterterrorist", TCTurnClientToCounterTerrorist);
	RegConsoleCmd("sm_t", TCTurnClientToTerrorist);
	RegConsoleCmd("sm_terrorist", TCTurnClientToTerrorist);
}
//Moves Client To Spectators.
public Action:TCTurnClientToSpectate(client, argCount)
{
	ChangeClientTeam(client, 1)//Changes clients team.
	PrintToChat( client, "\x03[TeamCommands]\x01 You Have Been Moved To Spectators." );//Prints a fancy message to the chat.
	return Plugin_Handled;
}
//Moves Client To Terrorists.
public Action:TCTurnClientToTerrorist(client, args)
{ 
	ClientCommand(client, "jointeam 2");//Changes clients team.
	PrintToChat( client, "\x03[TeamCommands]\x01 You Have Been Moved To Terrorists." );//Prints a fancy message to the chat.
	return Plugin_Handled;
}
//Moves Client To Counter-Terrorists.
public Action:TCTurnClientToCounterTerrorist(client, args)
{ 
	ClientCommand(client, "jointeam 3");//Changes clients team.
	PrintToChat( client, "\x03[TeamCommands]\x01 You Have Been Moved To Counter-Terrorists." );//Prints a fancy message to the chat.
	return Plugin_Handled;
}