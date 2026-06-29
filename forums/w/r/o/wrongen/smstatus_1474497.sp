#include <sourcemod>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name = "Staus",
	author = "Jaffa",
	description = "Better Version of the status command in console",
	version = PLUGIN_VERSION,
	url = "http://www.dominance-gaming.com.au/"
};

public OnPluginStart()
{
	SetConVarString(CreateConVar("sm_users_version", PLUGIN_VERSION, "Show Players version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_CHEAT), PLUGIN_VERSION);


	RegConsoleCmd("sm_status", status, "Prints your current rate settings to chat");
	
}

public Action:status(client,args)
{
	if (args < 1)
	{
		new ID;
		new String:tmp_steamid[21];
		new String:tmp_name[32];

		for (new i=1; i<=MaxClients; i++)
		{
			if (!IsClientInGame(i))
			{
				continue;
			}

			ID = GetClientUserId(i);
			GetClientAuthString(i, tmp_steamid, 21);		
			GetClientName(i, tmp_name, 35);
			
			PrintToConsole(client, "#%-4.4d %-32.32s %-20.20s", ID, tmp_name, tmp_steamid);
		
		}
	}
	
	PrintToChat(client, "\x04[SM] See console for output!");
	
	return Plugin_Handled
}




