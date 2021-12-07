#include <sourcemod>

#define Plugin_Version "1.0.0"

public Plugin:myinfo = { name = "Auto-JoinGame", author = "Marcus", description = "Disables the 'Join Game' screen to enter a server.", version = Plugin_Version, url = "http://www.sourcemod.com"};

public OnPluginStart()
{
	CreateConVar("sv_autojoingame_version", Plugin_Version, "This is the version of the plugin running on the server.", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_SPONLY);
}

public OnClientPostAdminCheck(iClient)
{
	if (!IsClientInGame(iClient)) return;

	CreateTimer(0.1, Timer_JoinGame, GetClientSerial(iClient));
}

public Action:Timer_JoinGame(Handle:Timer, any:iBuffer)
{
	new iClient = GetClientFromSerial(iBuffer);

	if (!IsClientInGame(iClient)) return;

	FakeClientCommand(iClient, "joingame");
}
