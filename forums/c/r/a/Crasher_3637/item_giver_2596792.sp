#include <sourcemod>
#pragma semicolon 1
#pragma newdecls required
#define IG_VERSION "1.4"

public Plugin myinfo =
{
	name = "[L4D & L4D2] Item Giver",
	author = "Psyk0tik (Crasher_3637)",
	description = "Provides a command to give items to players.",
	version = IG_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=308268"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion evEngine = GetEngineVersion();
	if (evEngine != Engine_Left4Dead && evEngine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Item Giver only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_give", cmdGive, ADMFLAG_KICK, "Gives items to players.");
	CreateConVar("ig_pluginversion", IG_VERSION, "Item Giver version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public Action cmdGive(int client, int args)
{
	if (client == 0 || !IsClientInGame(client))
	{
		ReplyToCommand(client, "[IG] You must be in-game to use this command.");
		return Plugin_Handled;
	}
	if (GetClientTeam(client) != 2)
	{
		ReplyToCommand(client, "\x04[IG]\x01 You must be on the survivor team to use this command.");
		return Plugin_Handled;
	}
	char item[32];
	GetCmdArg(2, item, sizeof(item));
	char target[32];
	char target_name[32];
	int target_list[MAXPLAYERS];
	int target_count;
	bool tn_is_ml;
	GetCmdArg(1, target, sizeof(target));
	if ((target_count = ProcessTargetString(target, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (int iPlayer = 0; iPlayer < target_count; iPlayer++)
	{
		int iCmdFlags = GetCommandFlags("give");
		SetCommandFlags("give", iCmdFlags & ~FCVAR_CHEAT);
		FakeClientCommand(target_list[iPlayer], "give %s", item);
		SetCommandFlags("give", iCmdFlags);
	}
	ShowActivity2(client, "\x04[IG]\x01 ", "Gave a(n) %s to %s.", item, target_name);
	return Plugin_Handled;
}