#include <sourcemod>
#include <colors>
#include <sdktools>


public Plugin:myinfo = 
{
	name = "Surrender & Refuse",
	author = "BlacksilverGM & Noobstyler",
	description = "Surrender and Refuse Plugin",
	version = "0.3",
	url = "www.pup-board.de"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_s", Command_Surrender); // command for surrender
	RegConsoleCmd("sm_r", Command_Refuse); // command for refuse
	RegConsoleCmd("sur", Command_Surrender); // command for surrender
	RegConsoleCmd("ref", Command_Refuse); // command for refuse
	CreateConVar("sm_plugin_version", "0.3", "Version", FCVAR_DONTRECORD);  // version but dont shown at cfg/sourcemod
	
	AutoExecConfig(true, "surrender_refuse"); // create the autoconfig and named it
	
}

public Action:Command_Surrender(client, args)
{
	new a;
	
	(a = 2);
	
	if(GetClientTeam(client) == a)
	{
		new String:name[32];
		GetClientName(client, name, sizeof(name));

		PrintToChatAll("\x01[\x04Surrender\x01]\x03 %s \x04surrendered!", name);
	}
	else
	{
		new String:name[32];
		GetClientName(client, name, sizeof(name));
		
		PrintToChat(client, "\x04You must be in the opposit team!", name);

	}
	
	return Plugin_Handled;
}



public Action:Command_Refuse(client, args)
{
	new b;
	
	b = 2;
	
	if(GetClientTeam(client) == b)
	{
		new String:name[32];
		GetClientName(client, name, sizeof(name));
	
		PrintToChatAll("\x01[\x04Refuse\x01]\x03 %s \x04refused!", name);
	}
	else
	{
		new String:name[32];
		GetClientName(client, name, sizeof(name));
		
		PrintToChat(client, "\x04You must be in the opposit team!", name);

	}
	
	return Plugin_Handled;
}

