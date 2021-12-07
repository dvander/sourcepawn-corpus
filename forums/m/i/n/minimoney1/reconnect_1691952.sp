#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION         "1.1"

new Handle:g_hSilent = INVALID_HANDLE;

public Plugin:myinfo =
{
    name = "Force Reconnect",
    author = "Alm, mINI",
    description = "Forces players to recconect",
    version = PLUGIN_VERSION,
};

public OnPluginStart()
{
	RegAdminCmd("sm_retry", ForceRetry, ADMFLAG_ROOT, "[SM] Usage: sm_retry <name|#userid>\nForces player to reconnect.");
	g_hSilent = CreateConVar("sm_retry_silent", "0", "Behavior of the plugin:\n0. Non-silent (Shows messages to public announcing people reconnecting.\1. Silent (No announcements)", _, true, 0.0, true, 1.0);
	CreateConVar("sm_retry_version", PLUGIN_VERSION, "Plugin Version", FCVAR_DONTRECORD);
	LoadTranslations("common.phrases");
	LoadTranslations("reconnect.phrases");
}

public Action:ForceRetry(client, args)
{
	if(args == 0)
	{
		ReplyToCommand(client, "[SM] Usage: sm_retry <name|#userid>\nForces player to reconnect.");
		return Plugin_Handled;
	}
	decl String:arg[MAX_NAME_LENGTH], String:target_name[MAX_TARGET_LENGTH];
	decl target_count, target_list[MAXPLAYERS], bool:tn_is_ml;
	GetCmdArg(1, arg, sizeof(arg));
	if ((target_count = ProcessTargetString(arg,
                           client,
                           target_list,
                           MAXPLAYERS,
                           COMMAND_FILTER_CONNECTED,
                           target_name,
                           sizeof(target_name),
                           tn_is_ml)) <= 0)
	{

		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	new bool:silent = GetConVarBool(g_hSilent);
	for (new i = 0; i < target_count; i++)
	{
		ClientCommand(target_list[i], "retry");
		if (silent == true)
		{
			PrintToChatAll("%t", "Forced Client Retry", target_list[i]);
		}
	}
	return Plugin_Handled;
}