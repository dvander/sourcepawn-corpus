#include <sourcemod>
#include <sdktools>
#include <cstrike>

public OnPluginStart()
{
	AddCommandListener(Command_JoinTeam, "jointeam");
}

public Action:Command_JoinTeam(client, const String:command[], args)
{
	decl String:TeamNumber[3];
	GetCmdArg(1, TeamNumber, sizeof(TeamNumber));
	new Team = StringToInt(TeamNumber);
	if(Team!=CS_TEAM_CT&&Team!=CS_TEAM_T&&Team!=CS_TEAM_SPECTATOR)
	{
		PrintCenterText(client, "Auto-Join is disabled.");
		ClientCommand(client, "play buttons/button11.wav");
		UTIL_TeamMenu(client);
		return Plugin_Handled;
	}
	if(Team==CS_TEAM_T&&GetTeamClientCount(CS_TEAM_T)>=1)
	{
		PrintCenterText(client, "Only one terrorist please.");
		ClientCommand(client, "play buttons/button11.wav");
		UTIL_TeamMenu(client);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

UTIL_TeamMenu(client)
{
	new clients[1];
	new Handle:bf;
	clients[0] = client;
	
	bf = StartMessage("VGUIMenu", clients, 1);
	BfWriteString(bf, "team"); // panel name
	BfWriteByte(bf, 1); // bShow
	BfWriteByte(bf, 0); // count
	EndMessage();
}