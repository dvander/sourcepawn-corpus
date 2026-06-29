#include <sourcemod>
#include <sdktools>
#include <morecolors>

#pragma semicolon 1
#pragma newdecls required

char g_sBuildPath[255];

public Plugin myinfo =
{
	name = "Teleport Manager",
	author = "The Doggy",
	version = "0.3",
	description = "Teleporting! Woo!!",
	url = "doggaming.ga"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_createteleport", Command_CreateTeleport, ADMFLAG_GENERIC, "Creates the specified teleport location.");
	RegAdminCmd("sm_deleteteleport", Command_DeleteTeleport, ADMFLAG_GENERIC, "Deletes the specified teleport location.");

	RegConsoleCmd("sm_tp", Command_TeleportToLocation, "Teleports you to the specified location.");
	RegConsoleCmd("sm_tplist", Command_TeleportList, "Shows a list of available teleport locations.");

	LoadTranslations("common.phrases");
	BuildPath(Path_SM, g_sBuildPath, sizeof(g_sBuildPath), "configs/teleport_positions.txt");
}

public Action Command_CreateTeleport(int Client, int iArgs)
{
	if(!IsValidClient(Client))
	{
		PrintToServer("[SM] This command can only be run in-game.");
		return Plugin_Handled;
	}

	if(iArgs != 1)
	{
		CPrintToChat(Client, "[SM] Invalid Syntax. Usage: sm_createteleport <name>");
		return Plugin_Handled;
	}

	char sArg[32];
	GetCmdArg(1, sArg, sizeof(sArg));

	float pos[3];
	GetClientAbsOrigin(Client, pos);

	KeyValues kv = new KeyValues("TeleportLocations");
	kv.ImportFromFile(g_sBuildPath);
	kv.JumpToKey(sArg, true);
	kv.SetFloat("X", pos[0]);
	kv.SetFloat("Y", pos[2]);
	kv.SetFloat("Z", pos[1]);
	kv.Rewind();
	if(kv.ExportToFile(g_sBuildPath)) CPrintToChat(Client, "[SM] Successfully created teleport location {green}%s.", sArg);
	else CPrintToChat(Client, "[SM] Failed to create teleport location {green}%s.", sArg);
	delete kv;

	return Plugin_Handled;
}

public Action Command_DeleteTeleport(int Client, int iArgs)
{
	if(!IsValidClient(Client))
	{
		PrintToServer("[SM] This command can only be run in-game.");
		return Plugin_Handled;
	}

	if(iArgs != 1)
	{
		CPrintToChat(Client, "[SM] Invalid Syntax. Usage: sm_deleteteleport <name>");
		return Plugin_Handled;
	}

	char sArg[32];
	GetCmdArg(1, sArg, sizeof(sArg));

	KeyValues kv = new KeyValues("TeleportLocations");
	if(!kv.ImportFromFile(g_sBuildPath))
	{
		CPrintToChat(Client, "[SM] No teleport locations exist.");
		delete kv;
		return Plugin_Handled;
	}

	if(!kv.JumpToKey(sArg))
	{
		CPrintToChat(Client, "[SM] Invalid teleport location.");
		delete kv;
		return Plugin_Handled;
	}

	if(kv.DeleteThis()) CPrintToChat(Client, "[SM] Successfully deleted teleport location {green}%s.", sArg);
	else CPrintToChat(Client, "[SM] Failed to delete teleport location {green}%s.", sArg);
	kv.Rewind();
	kv.ExportToFile(g_sBuildPath);
	delete kv;
	return Plugin_Handled;
}

public Action Command_TeleportToLocation(int Client, int iArgs)
{
	if(!IsValidClient(Client))
	{
		PrintToServer("[SM] This command can only be run in-game.");
		return Plugin_Handled;
	}

	if(iArgs != 1)
	{
		CPrintToChat(Client, "[SM] Invalid Syntax. Usage: sm_tp <teleport name>");
		return Plugin_Handled;
	}

	char sArg[32];
	GetCmdArg(1, sArg, sizeof(sArg));

	KeyValues kv = new KeyValues("TeleportLocations");
	if(!kv.ImportFromFile(g_sBuildPath))
	{
		CPrintToChat(Client, "[SM] No teleport locations exist.");
		delete kv;
		return Plugin_Handled;
	}

	if(!kv.JumpToKey(sArg))
	{
		CPrintToChat(Client, "[SM] Invalid location: {green}%s", sArg);
		delete kv;
		return Plugin_Handled;
	}

	float pos[3];
	pos[0] = kv.GetFloat("X");
	pos[2] = kv.GetFloat("Y");
	pos[1] = kv.GetFloat("Z");

	TeleportEntity(Client, pos, NULL_VECTOR, NULL_VECTOR);
	CPrintToChat(Client, "[SM] Teleported to {green}%s", sArg);
	delete kv;
	return Plugin_Handled;
}

public Action Command_TeleportList(int Client, int iArgs)
{
	if(!IsValidClient(Client))
	{
		PrintToServer("[SM] This command can only be run in-game.");
		return Plugin_Handled;
	}

	KeyValues kv = new KeyValues("TeleportLocations");
	if(!kv.ImportFromFile(g_sBuildPath))
	{
		CPrintToChat(Client, "[SM] No teleport locations exist.");
		delete kv;
		return Plugin_Handled;
	}

	char sOutput[1024] = "\nList of Teleport Locations: \n--------------------------------------------------\n";
	kv.GotoFirstSubKey(true);

	do
	{
		char sName[32];
		kv.GetSectionName(sName, sizeof(sName));
		Format(sName, sizeof(sName), "%s\n", sName);
		StrCat(sOutput, sizeof(sOutput), sName);
	} while(kv.GotoNextKey(true));

	delete kv;
	PrintToConsole(Client, sOutput);
	CPrintToChat(Client, "[SM] See console for output.");
	return Plugin_Handled;
}

stock bool IsValidClient(int client)
{
	if (client >= 1 && 
	client <= MaxClients && 
	IsClientInGame(client) &&
	!IsFakeClient(client))
		return true;
	return false;
}