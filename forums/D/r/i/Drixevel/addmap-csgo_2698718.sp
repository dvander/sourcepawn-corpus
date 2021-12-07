/*****************************/
//Pragma
#pragma semicolon 1
#pragma newdecls required

/*****************************/
//Defines
#define PLUGIN_NAME "[CSGO] AddMap"
#define PLUGIN_DESCRIPTION "Add mapnames to the mapcycle file via command for CSGO."
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
	
	//Attempt to add the map to the mapcycle file.
	if (!AddMap("mapcycle.txt", map))
		ReplyToCommand(client, "[SM] Error while finding mapcycle file.");
	
	//Attempt to add the map to the maplist file.
	if (!AddMap("maplist.txt", map))
		ReplyToCommand(client, "[SM] Error while finding maplist file.");
	
	//Send a success message.
	ReplyToCommand(client, "[SM] %s has been added to the mapcycle/maplist files.", map);
	
	//Tell the engine this command has done what it needs to do.
	return Plugin_Handled;
}

bool AddMap(const char[] path, const char[] map)
{
	//'a' or 'a+' should both work fine here with appending maps to the mapcycle file.
	File mapcycle = OpenFile(path, "a+");
	
	//Mapcycle file couldn't be found to update.
	if (mapcycle == null)
		return false;
	
	//Append the map to the file and close it.
	mapcycle.WriteLine(map);
	mapcycle.Close();
	
	//Return true since it worked.
	return true;
}