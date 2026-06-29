#include <sourcemod>
#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "L4D(2) Change Team",
	author = "danmala",
	description = "Allows a player to type !spectate and go to !spectate",
	version = "1.0.0",
	url = "N/A"
};

public OnPluginStart()
{
	RegConsoleCmd("spectate", JoinTeam1);
	RegConsoleCmd("sm_infected", JoinTeam3, "Jointeam 3 - Without dev console");
	RegConsoleCmd("sm_survivor", JoinTeam2, "Jointeam 2 - Without dev console");
}

// ------------------------------------------------------------------------
// jointeam2 && jointeam3
// ------------------------------------------------------------------------
public Action:JoinTeam3(client, args) {FakeClientCommand(client,"jointeam 3");return Plugin_Handled;}
public Action:JoinTeam2(client, args) {FakeClientCommand(client,"jointeam 2");return Plugin_Handled;}
public Action:JoinTeam1(client, args) {ChangeClientTeam(client, 1);return Plugin_Handled;}

public IsValidPlayer (client)
{
	if (client == 0)
		return false;
	
	if (!IsClientConnected(client))
		return false;
	
	if (IsFakeClient(client))
		return false;
	
	if (!IsClientInGame(client))
		return false;
	
	return true;
}