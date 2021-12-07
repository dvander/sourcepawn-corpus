#pragma semicolon 1

// To change the flag: https://sm.alliedmods.net/new-api/admin/AdminFlag
#define AdmFlag		Admin_Custom6

#define PLUGIN_AUTHOR "[W]atch [D]ogs"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>

#pragma newdecls required


public Plugin myinfo = 
{
	name = "Admin Spec Restrict",
	author = PLUGIN_AUTHOR,
	description = "Restrict spec team for special admin flag",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=298190"
};

public void OnPluginStart()
{
	AddCommandListener(CMD_JoinTeam, "jointeam");
}

public Action CMD_JoinTeam(int client, const char[] command, int args)
{
	char sTeam[3];
	GetCmdArg(1, sTeam, sizeof(sTeam));
	
	if(StringToInt(sTeam) == 1)
	{
		if(GetAdminFlag(GetUserAdmin(client), AdmFlag))
			return Plugin_Continue;
			
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
