/*****************************/
//Pragma
#pragma semicolon 1
#pragma newdecls required

/*****************************/
//Defines
#define PLUGIN_NAME "[ANY] AddMap"
#define PLUGIN_DESCRIPTION "Add mapnames to the mapcycle file via command."
#define PLUGIN_VERSION "1.0.0"

/*****************************/
//Includes
#include <sourcemod>

/*****************************/
//Globals

/*****************************/
//Plugin Info
public Plugin myinfo = 
{
	name = PLUGIN_NAME, 
	author = "Drixevel", 
	description = PLUGIN_DESCRIPTION, 
	version = PLUGIN_VERSION, 
	url = "https://drixevel.dev/"
};

public void OnPluginStart()
{
	//Register the command.
	RegAdminCmd("sm_addmap", Command_AddMap, ADMFLAG_ROOT, "Add a new map to the Mapcycle file.");
}

public Action Command_AddMap(int client, int args)
{
	//No argument specified, need to handle it.
	if (args == 0)
	{
		char command[64];
		GetCmdArg(0, command, sizeof(command));
		ReplyToCommand(client, "[SM] Usage: %s <mapname>", command);
		return Plugin_Handled;
	}
	
	//Get the argument specified.
	char map[128];
	GetCmdArg(1, map, sizeof(map));
	
	//Trim the string of any potential spaces on the sides.
	TrimString(map);
	
	//Get the mapcycle file being used.
	char path[PLATFORM_MAX_PATH];
	FindConVar("mapcyclefile").GetString(path, sizeof(path));
	
	//Update the path so it can be opened.
	Format(path, sizeof(path), "cfg/%s", path);
	
	//If file doesn't exist, stop the process since it'll just use default anyways.
	if (!FileExists(path))
	{
		ReplyToCommand(client, "[SM] Error while finding file: %s", path);
		return Plugin_Handled;
	}
	
	//'a' or 'a+' should both work fine here with appending maps to the mapcycle file.
	File mapcycle = OpenFile(path, "a+");
	
	//Mapcycle file couldn't be found to update.
	if (mapcycle == null)
	{
		ReplyToCommand(client, "[SM] Error while finding mapcycle file.");
		return Plugin_Handled;
	}
	
	//Append the map to the file and close it.
	mapcycle.WriteLine(map);
	mapcycle.Close();
	
	//Send a success message.
	ReplyToCommand(client, "[SM] %s has been added to the mapcycle file successfully.", map);
	
	//Tell the engine this command has done what it needs to do.
	return Plugin_Handled;
}