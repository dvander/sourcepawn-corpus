#include <sourcemod>
#include <sdktools>

public OnPluginStart()
{
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
}

public Action:Command_Say(client, args)
{	
	decl String:text[192];
	GetCmdArgString(text, sizeof(text));
	
	new startidx;
	if (text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
	
	if (strcmp(text[startidx], "!sr") == 0)
	{
		new String:currentMap[64]; 
		GetCurrentMap(currentMap, sizeof(currentMap));
		if (strcmp(currentMap, "surf_bedroom") == 0)
		{
			TeleportToBedroom(client);
		}
	}
	else if (strcmp(text[startidx], "!kill") == 0)
	{
		ForcePlayerSuicide(client)
	}

	return Plugin_Continue;
}

TeleportToBedroom(client)
{
	new Float:coordinates[3];

	coordinates[0] = -683.0;
	coordinates[1] = -7878.0;
	coordinates[2] = -4906.0;

	TeleportEntity(client, coordinates, NULL_VECTOR, NULL_VECTOR);
}