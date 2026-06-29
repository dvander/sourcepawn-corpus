#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name		= "Get Player SteamID",
	version		= "1.0.1",
	description = "Displays a player's SteamID in console",
	author		= "YaroMudri",
	url			= "https://forums.alliedmods.net/showthread.php?t=351218"
}

public void OnPluginStart()
{
	RegAdminCmd("sm_get_steamid", Command_GetSteamID, ADMFLAG_GENERIC, "Displays a player's SteamID in console. Usage: sm_get_steamid <target>");
}

public Action Command_GetSteamID(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_get_steamid <target>");
		return Plugin_Handled;
	}

	char buffer[64];
	GetCmdArg(1, buffer, sizeof(buffer));

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
			buffer,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_NO_BOTS,
			target_name,
			sizeof(target_name),
			tn_is_ml)) < 1)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	ReplyToCommand(client, "[SM] SteamID for \"%s\" has been printed to your console.", buffer);

	PrintToConsole(client, "\n<SteamId>");
	for (int i, j; i < target_count; i++) if (IsClientInGame(target_list[i]))
	{
		j++;
		if (!GetClientAuthId(target_list[i], AuthId_Steam2, buffer, sizeof(buffer), false))
			FormatEx(buffer, sizeof(buffer), "unknown");
		else PrintToConsole(client, "  %2i) %N: %s", j, target_list[i], buffer);
	}
	PrintToConsole(client, "<|SteamId>\n");

	return Plugin_Handled;
}