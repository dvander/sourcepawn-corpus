#include <sourcemod>

#define PLUGIN_VERSION "1.1"

#pragma semicolon 1
#pragma newdecls required

ConVar g_cvAllowAdmins;

public Plugin myinfo =
{
	name = "[ANY] Block Specatator",
	author = "Headline",
	description = "Makes the spectator team unjoinable.",
	version = PLUGIN_VERSION,
	url = "http://www.michaelwflaherty.com"
};

public void OnPluginStart()
{
	CreateConVar("hl_blockspec_version", PLUGIN_VERSION, "Headline's Block Spectator Version", FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_PLUGIN|FCVAR_SPONLY);
	g_cvAllowAdmins = CreateConVar("hl_blockspec_allow_admins", "1", "Allow admins to pass the spectator block? 1 = true, 0 = false.", FCVAR_DONTRECORD|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	AddCommandListener(Command_JoinTeam, "jointeam"); // Hook Join Team
}


public Action Command_JoinTeam(int client, char[] command, int args)  
{
	char sTeamName[8];
	GetCmdArg(1, sTeamName, sizeof(sTeamName)) ;// Get Team Name
	int iTeam = StringToInt(sTeamName);
	if (iTeam == 1) // Spectator
	{
		if (CheckCommandAccess(client, "sm_fake_command", ADMFLAG_GENERIC, true) && g_cvAllowAdmins.BoolValue)
		{
			return Plugin_Continue;
		}
		else
		{
			PrintToChat(client, "[SM] The server operator has blocked this team!");
			return Plugin_Handled; // Block it.
		}
	}
	else // If not spectator
	{
		return Plugin_Continue; // Allow
	}
}