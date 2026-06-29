#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <multicolors>

public Plugin myinfo =
{
	name		= "Server Info",
	author		= "EmreBulut",
	description	= "Shows info about server.",
	version		= "1.1.1",
	url			= "https://forums.alliedmods.net/showthread.php?t=278311"
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_info", CMD_Info, "Show info about server.");
}

public void OnClientPostAdminCheck(int client)
{
	CreateTimer(15.0, Timer_ShowInfo, client);
}

public Action Timer_ShowInfo(Handle timer, any client)
{
	if(IsValidPlayer(client)) ShowInfo(client);
}

public Action CMD_Info(int client, int args)
{
	if(IsValidPlayer(client)) ShowInfo(client);
}

void ShowInfo(int client)
{
	char sBuffer[256];
	GetConVarString(FindConVar("hostname"), sBuffer,sizeof(sBuffer));
	CPrintToChat(client, "{darkred}Server name :{default} %s", sBuffer);

	int pieces[4];
	int longip = GetConVarInt(FindConVar("hostip"));
	int port = GetConVarInt(FindConVar("hostport"));
	pieces[0] = (longip >> 24) & 0x000000FF;
	pieces[1] = (longip >> 16) & 0x000000FF;
	pieces[2] = (longip >> 8) & 0x000000FF;
	pieces[3] = longip & 0x000000FF;

	CPrintToChat(client, "{darkred}==============================================");
	CPrintToChat(client, "{darkred}Server IP: {default}%d.%d.%d.%d:%d", pieces[0], pieces[1], pieces[2], pieces[3], port);

	char AdminNames[MAXPLAYERS+1][MAX_NAME_LENGTH+1];
	int count;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			AdminId AdminID = GetUserAdmin(i);
			if(AdminID != INVALID_ADMIN_ID)
			{
				GetClientName(i, AdminNames[count], sizeof(AdminNames[]));
				count++;
			}
		}
	}

	if(count) ImplodeStrings(AdminNames, count, ", ", sBuffer, sizeof(sBuffer));
	CPrintToChat(client, "{darkred}Online admins (%d):{default} %s", count, count ? sBuffer: "absent");

	GetNextMap(sBuffer, sizeof(sBuffer));
	CPrintToChat(client, "{darkred}Next map:{default} %s", sBuffer);

	GetCurrentMap(sBuffer, sizeof(sBuffer));
	CPrintToChat(client, "{darkred}Current map:{default} %s", sBuffer);

	int i_Minutes, i_Seconds, i_Time;
	if(GetMapTimeLeft(i_Time) && i_Time > 0)
	{
		i_Seconds = i_Time % 60;
		if(i_Time > 59) i_Minutes = (i_Time - i_Seconds) / 60;
	}
	CPrintToChat(client, "{DarkRed}Timeleft:{default} %d:%02d", i_Minutes, i_Seconds);
}

stock bool IsValidPlayer(int client)
{
	return (0 < client <= MaxClients && IsClientConnected(client) && IsClientInGame(client));
}