/**
 * This plugin shares the motd command with the basetriggers plugin that ships with vanilla SourceMod, and will conflict with it.
 * Many of the functions provided by basetriggers do not work properly with Dystopia and I would recommend removing it.
 *
 * Creates the motdfordys_automotd ConVar with the default value of 1.
 */ 

#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

ConVar g_cvAutoMOTD;

public Plugin myinfo =
{
	name = "MOTD For Dystopia",
	author = "emjay",
	description = "Creates the \"motd\" console command, and displays the MOTD upon connection if the motdfordys_automotd ConVar is set to 1.",
	version = "5.0",
	url = "https://forums.alliedmods.net/showthread.php?t=275178"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	/* Register the motd command. */
	RegConsoleCmd("motd", Command_Motd);

	/* Create the motdfordys_automotd ConVar. */
	g_cvAutoMOTD = CreateConVar("motdfordys_automotd",
	                            "1", 
	                            "Sets whether the MOTD is automatically displayed upon client connection.");
}

/* Basically copied from the SourceMod basetriggers plugin. */
public Action Command_Motd(int client, int args)
{
	if(client == 0)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}

	if( !IsClientInGame(client) )
	{
		return Plugin_Handled;
	}

	ShowMOTDPanel(client, "Message Of The Day", "motd", MOTDPANEL_TYPE_INDEX);
	return Plugin_Handled;
}

public void OnClientPutInServer(int client)
{
	/* If the boolean value of motdfordys_automotd is true, then the MOTD should be automatically displayed. */
	if(g_cvAutoMOTD.BoolValue)
	{
		/* Ensure that the command is not being called from the server, or a fake client. */
		if( client < 1 || IsFakeClient(client) )
		{
			return;
		}

		/* Call the motd command as a fake client. */
		FakeClientCommandEx(client, "motd");
	}
}
