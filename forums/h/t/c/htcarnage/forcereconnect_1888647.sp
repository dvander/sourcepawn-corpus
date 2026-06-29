#include <sourcemod>
#define PLUGIN_VERSION "1.1.2"

public Plugin:myinfo=
{
	name = "Force Player Reconnect",
	author = "BB",
	version = PLUGIN_VERSION,
}

new Handle:sm_reconnect_delay;
new Handle:sm_reconnect_announce;

public OnPluginStart()
{
	CreateConVar("force_reconnect_version", PLUGIN_VERSION, "Force Reconnect Version", FCVAR_PLUGIN|FCVAR_NOTIFY);
	RegAdminCmd("sm_reconnect", Command_Reconnect, ADMFLAG_KICK, "sm_reconnect <#userid|name> - Force a player to reconnect");
	sm_reconnect_delay = CreateConVar("sm_reconnect_delay", "3", "Sets the delay before a client is reconnected", FCVAR_PLUGIN|FCVAR_NOTIFY);
	sm_reconnect_announce = CreateConVar("sm_reconnect_announce", "1", "Sets whether a client is informed of their reconnect", FCVAR_PLUGIN|FCVAR_NOTIFY);
	
	LoadTranslations("common.phrases.txt");
}

public Action:Command_Reconnect(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_reconnect <#userid|name>");
		return Plugin_Handled;
	}
	decl String:arg[64];
	GetCmdArg(1, arg, sizeof(arg));

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
 
	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (new i = 0; i < target_count; i++)
	{
		if(GetConVarInt(sm_reconnect_announce))
		{
			switch(GetConVarInt(sm_reconnect_announce))
			{
				case 1: PrintCenterText(target_list[i], "You are being reconnected in %d seconds", GetConVarInt(sm_reconnect_delay));
				case 2: PrintToChat(target_list[i], "\x03You are being reconnected in %d seconds", GetConVarInt(sm_reconnect_delay));
				case 3: PrintHintText(target_list[i], "You are being reconnected in %d seconds", GetConVarInt(sm_reconnect_delay));
			}
		}
		CreateTimer((GetConVarInt(sm_reconnect_delay) * 1.0), ReconnectPlayer, GetClientUserId(target_list[i]));

	}
	return Plugin_Handled;
}

public Action:ReconnectPlayer(Handle: timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client > 0)
	{
		ClientCommand(client, "retry");
	}
	return Plugin_Handled;
}

