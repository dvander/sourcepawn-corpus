#pragma semicolon 1

#include <sourcemod>

// Global Definitions
#define PLUGIN_VERSION "1.0.0"

new Handle:banArray;

public Plugin:myinfo =
{
	name = "TempBan",
	author = "bl4nk",
	description = "Ban a player until the map changes",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");

	CreateConVar("sm_tempban_version", PLUGIN_VERSION, "TempBan Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_tempban", Command_Tempban, ADMFLAG_BAN, "sm_tempban <player>");

	banArray = CreateArray(32);
}

public OnMapEnd()
	RemoveStoredBans();

public Action:Command_Tempban(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_tempban <player>");
		return Plugin_Handled;
	}

	decl String:text[256], String:arg[64];
	GetCmdArgString(text, sizeof(text));

	BreakString(text, arg, sizeof(arg));

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_NO_MULTI,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	decl String:authid[32];
	GetClientAuthString(target_list[0], authid, sizeof(authid));

	LogMessage("Client %N temp banned client %N (%s)", client, target_list[0], authid);
	BanClient(target_list[0], 9999, BANFLAG_AUTHID, "Temp banned", "Temp banned until map change", "tempban", client);

	StoreBan(authid);

	return Plugin_Handled;
}

stock RemoveStoredBans()
{
	new size = GetArraySize(banArray);
	for (new i = 0; i < size; i++)
	{
		decl String:authid[32];
		GetArrayString(banArray, i, authid, sizeof(authid));

		RemoveBan(authid, BANFLAG_AUTHID);
		LogMessage("Removed tempban for SteamID: %s", authid);
	}

	ClearArray(banArray);
}

stock StoreBan(String:authid[])
	PushArrayString(banArray, authid);