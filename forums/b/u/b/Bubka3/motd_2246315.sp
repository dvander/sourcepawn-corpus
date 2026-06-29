#include <sourcemod>

#define Plugin_Version "1.0.1"

public Plugin:myinfo = { name = "[NMRiH] MOTD Opener", author = "Marcus", description = "Opens the default motd when a client joins the server.", version = Plugin_Version, url = "http://www.sourcemod.com"};

public OnPluginStart()
{
	CreateConVar("sv_motdopener_version", Plugin_Version, "This is the version of the plugin running on the server.", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_SPONLY);

	AddCommandListener(Command_JoinGame, "joingame");
}

public Action:Command_JoinGame(iClient, const String:sCommand[], iArgs)
{
	if (!IsClientInGame(iClient)) return;

	ShowMOTDPanel(iClient, "Message Of The Day", "motd", MOTDPANEL_TYPE_INDEX);
}