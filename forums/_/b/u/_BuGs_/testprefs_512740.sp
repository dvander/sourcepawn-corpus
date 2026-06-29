#include <sourcemod>
#include <clientpref>

#pragma semicolon 1

public Plugin:myinfo = 
{
	name = "Test Client Preferences",
	author = "AlliedModders LLC",
	description = "Tests the ability of the client preferences plugin",
	version = SOURCEMOD_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_client_update_one", Command_Update1);
	RegConsoleCmd("sm_client_update_two", Command_Update2);
	RegConsoleCmd("sm_client_delete", Command_Delete);
	RegConsoleCmd("sm_client_select", Command_Select);
}

public Action:Command_Update1(client, args)
{
	new userid = GetClientUserId(client);
	ClientPrefUpdate(userid, "STEAM:TEST", "this_is_a_test", "teame06 does smell");	//	First time, if it doesn't exist it inserts the data.
	return Plugin_Handled;
}

public Action:Command_Update2(client, args)
{
	new userid = GetClientUserId(client);
	ClientPrefUpdate(userid, "STEAM:TEST", "this_is_a_test", "teame06 does not smell");	//	Second time, if the SteamID and the "ID" are the same, it updates the value
	return Plugin_Handled;
}

public Action:Command_Delete(client, args)
{
	new userid = GetClientUserId(client);
	ClientPrefDelete(userid, "STEAM:TEST", "this_is_a_test");	//	This deletes the value with the needed SteamID
	return Plugin_Handled;
}

public Action:Command_Select(client, args)
{
	new userid = GetClientUserId(client);
	ClientPrefSelect(userid, "STEAM:TEST", "this_is_a_test");	//	This gets the value for the ID with the needed SteamID
	return Plugin_Handled;
}

public OnClientPref(client, String:id[], String:value[])	//	All values are passed through this forward as a string. You must do a match on your ID.
{
	PrintToConsole(client, "ID %s Value: %s", id, value);
}