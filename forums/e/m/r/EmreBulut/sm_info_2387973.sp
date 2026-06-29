#include <sourcemod>
#include <multicolors>

#define PLUGIN_VERSION "1.1.0"

public Plugin myinfo =
{
	name = "Server Info",
	author = "EmreBulut",
	description = "Shows info about server.",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/emrebulut"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_info", CMD_Info)
}

public Action:CMD_Info(client, args)
{
	char sBuffer[256];
	GetConVarString(FindConVar("hostname"), sBuffer,sizeof(sBuffer));
	CPrintToChat(client, "{darkred}Server name :{default} %s", sBuffer)

	int pieces[4];
	int longip = GetConVarInt(FindConVar("hostip"));
	int port = GetConVarInt(FindConVar("hostport"));
	pieces[0] = (longip >> 24) & 0x000000FF;
	pieces[1] = (longip >> 16) & 0x000000FF;
	pieces[2] = (longip >> 8) & 0x000000FF;
	pieces[3] = longip & 0x000000FF;

	char NetIP[32];
	Format(NetIP, sizeof(NetIP), "%d.%d.%d.%d:%d", pieces[0], pieces[1], pieces[2], pieces[3], port);  
	CPrintToChat(client, "{darkred}==============================================");
	CPrintToChat(client, "{darkred}Server IP: {default}%d.%d.%d.%d:%d", pieces[0], pieces[1], pieces[2], pieces[3], port)
	
	decl String:AdminNames[MAXPLAYERS+1][MAX_NAME_LENGTH+1];
	new count = 0;
	for(new i = 1 ; i <= GetMaxClients();i++)
	{
		if(IsClientInGame(i))
		{
			new AdminId:AdminID = GetUserAdmin(i);
			if(AdminID != INVALID_ADMIN_ID)
			{
				GetClientName(i, AdminNames[count], sizeof(AdminNames[]));
				count++;
			}
		} 
	}
	decl String:buffer[1024];
	ImplodeStrings(AdminNames, count, ",", buffer, sizeof(buffer));
	CPrintToChat(client, "{darkred}Online admins:{default} %s", buffer);

	GetNextMap(sBuffer, sizeof(sBuffer));
	CPrintToChat(client, "{darkred}Next map:{default} %s", sBuffer)

	GetCurrentMap(sBuffer, sizeof(sBuffer));
	CPrintToChat(client, "{darkred}Current map:{default} %s", sBuffer)

	int i_Minutes;
	int i_Seconds;
	int i_Time;
	if(GetMapTimeLeft(i_Time) && i_Time > 0)
	{
		i_Minutes = i_Time / 60;
		i_Seconds = i_Time % 60;
	}
	Format(sBuffer, sizeof(sBuffer), "%d:%02d", i_Minutes, i_Seconds);
	CPrintToChat(client, "{DarkRed}Timeleft:{default} %s", sBuffer)
}

stock bool IsValidPlayer(int client, bool alive = false)
{
	if(client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && (alive == false || IsPlayerAlive(client)))
	{
		return true;
	}
	return false;
}
stock bool IsPlayerAdmin(client)
{
	if (GetAdminFlag(GetUserAdmin(client), Admin_Generic))
	{
		return true;
	}
	return false;
}