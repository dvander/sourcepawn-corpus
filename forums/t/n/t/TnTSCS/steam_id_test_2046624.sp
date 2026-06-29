#pragma semicolon 1

#include <sourcemod>
#include <adt_array>

#define STEAMIDLIST "test.txt"

new Handle:Arr_SteamIDs = INVALID_HANDLE;

new bool:PlayerIsSpecial[MAXPLAYERS+1] = {false, ...};

public OnPluginStart()
{
	RegConsoleCmd("sm_test", cb, "Only people whose SteamID are in the file can use this command");
	RegConsoleCmd("sm_test2", cc, "testing");
	LoadSteamIDList();
}

public Action:cb(client, args)
{
	if (client == 0 || !PlayerIsSpecial[client])
	{
		// Do not allow player to use command
		ReplyToCommand(client, "You cannot use this command");
		return Plugin_Handled;
	}
	else
	{
		// Your special code here
		PrintToServer ("I love myself!");
		return Plugin_Continue;
	}
}

public Action:cc(client, args)
{
	new String:auth[32];
	GetClientAuthString(client, auth, sizeof(auth));
	//ReplyToCommand(client, "The value for SteamIDs is %s", Arr_SteamIDs); // What is this supposed to do?
	ReplyToCommand(client, "The value for Auths is %s", auth);
}

public OnClientPostAdminCheck(client)
{
	new String:auth[32];
	
	GetClientAuthString(client, auth, sizeof(auth));
	
	if (FindStringInArray(Arr_SteamIDs, auth) != -1)
	{
		PlayerIsSpecial[client] = true;
	}
	else
	{
		PlayerIsSpecial[client] = false;
	}
	
	LogMessage("PlayerIsSpecial [%s] is currently set to %s", auth, (PlayerIsSpecial[client] ? "TRUE" : "FALSE"));
}

public OnClientDisconnect(client)
{
	if (IsClientInGame(client))
	{
		PlayerIsSpecial[client] = false;
	}
}

LoadSteamIDList()
{
	new Handle:fSteamIDList = OpenFile(STEAMIDLIST, "rt");

	if (fSteamIDList == INVALID_HANDLE)
	{
		SetFailState("Unable to load file: %s", STEAMIDLIST);
	}

	Arr_SteamIDs = CreateArray(256);

	new String:auth[256];
	
	while (!IsEndOfFile(fSteamIDList) && ReadFileLine(fSteamIDList, auth, sizeof(auth)))
	{
		//ReplaceString(auth, sizeof(auth), "\r", "");
		//ReplaceString(auth, sizeof(auth), "\n", "");
		TrimString(auth);
		
		LogMessage("Pushing %s to Arr_SteamIDs", auth);
		
		PushArrayString(Arr_SteamIDs, auth);
	}
	
	LogMessage("Reached EOF on %s", STEAMIDLIST);
	
	CloseHandle(fSteamIDList);
} 