#pragma semicolon 1

#include <tf2>
#include <sdktools>
#include <colors>

#define PLUGIN_VERSION "1.0.0"

new Handle:g_hcvarunderworldmode = INVALID_HANDLE;
new Handle:g_AccessArray;

public Plugin:myinfo =
{
	name = "tf2 underworld",
	author = "timtam95",
	description = "tf2 underworld",
	version = PLUGIN_VERSION,
	url = "none"
}

stock bool:IsValidClient(iClient)
{

    return (0 < iClient && iClient <= MaxClients
        && IsClientInGame(iClient)
        && !IsClientReplay(iClient)
        && !IsClientSourceTV(iClient)
        && !GetEntProp(iClient, Prop_Send, "m_bIsCoaching")
    );

}

//!sm_underworld @red

void LoadAccessList()
{

        g_AccessArray = CreateArray(32, 32);

	new String:path[PLATFORM_MAX_PATH], String:line[128];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "configs/tf2underworld.txt");
	new Handle:fileHandle = OpenFile(path, "r");

	if (!fileHandle)
	{
		PrintToServer("configs/tf2underworld.txt does not exist.");
		return Plugin_Handled;
	}


	while(!IsEndOfFile(fileHandle) && ReadFileLine(fileHandle, line, sizeof(line)))
	{
		PushArrayString(g_AccessArray, line);
	}

	CloseHandle(fileHandle);

}

public bool HasAccess(String:steamid[32])
{

	if (FindStringInArray(g_AccessArray, steamid) != -1) return true; else return false;

}

public OnPluginStart()
{

	LoadTranslations("common.phrases");
	LoadAccessList();
	RegAdminCmd("sm_underworld", Command_underworld, 0, "underworld");
	g_hcvarunderworldmode = CreateConVar("sm_underworldmode", "1", "underworld mode", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);

}

public Action:Command_underworld(client, args)
{

	new String:steamid[32];
	GetClientAuthString(client, steamid, sizeof(steamid));

	if (!HasAccess(steamid))
	{
		ReplyToCommand(client, "[SM] You do not have access to this command.");
		return Plugin_Handled;
	}

	if(args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_underworld \"target\"");
		return Plugin_Handled;
	}

	new String:strBuffer[MAX_NAME_LENGTH], String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	GetCmdArg(1, strBuffer, sizeof(strBuffer));
	if ((target_count = ProcessTargetString(strBuffer, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	new String:nick[MAX_NAME_LENGTH], String:teamcolor[8];

	for(new i = 0; i < target_count; i++)
	{

		if (GetConVarInt(g_hcvarunderworldmode) == 1)
		{
			GetClientName(target_list[i], nick, MAX_NAME_LENGTH);
			if (GetClientTeam(target_list[i]) == 2) 
				Format(teamcolor, sizeof(teamcolor), "red"); 	else
				Format(teamcolor, sizeof(teamcolor), "blue"); 
			for (new j = 0; j < MAXPLAYERS; j++)
				if (IsValidClient(j)) EmitSoundToClient(j, "ui/halloween_boss_player_becomes_it.wav");

			
			CPrintToChatAll("{%s}%s{default} has escaped the underworld!", teamcolor, nick);
		}
		else
			TF2_AddCondition(target_list[i], 108, 0.0);

	}

	return Plugin_Handled;

}

