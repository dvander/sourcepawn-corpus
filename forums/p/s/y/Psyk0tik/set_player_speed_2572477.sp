#include <sourcemod>
#pragma semicolon 1
#pragma newdecls required
#define PLUGIN_VERSION "1.0"

ConVar cvEnablePlugin;

public Plugin myinfo =
{
	name = "[L4D & L4D2] Set Player Speed",
	author = "Psykotik (Crasher_3637)",
	description = "Allows admins to set player's speed.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=304476"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_setspeed", cmdSetSpeed, ADMFLAG_KICK, "Set a player's speed.");
	RegAdminCmd("sm_speedplayer", cmdSetSpeed, ADMFLAG_KICK, "Set a player's speed.")
	cvEnablePlugin = CreateConVar("sps_enableplugin", "1", "Enable the plugin?\n(0: OFF)\n(1: ON)", FCVAR_NOTIFY);
	CreateConVar("sps_pluginversion", PLUGIN_VERSION, "Plugin version", FCVAR_NOTIFY);
	cvEnablePlugin.AddChangeHook(vCvarChanged_cvEnablePlugin);
}

public void vCvarChanged_cvEnablePlugin(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (!cvEnablePlugin.BoolValue)
	{
		for (int iPlayer; iPlayer <= MaxClients; iPlayer++)
		{
			if (bIsValidClient(iPlayer))
			{
				SetEntPropFloat(iPlayer, Prop_Data, "m_flLaggedMovementValue", 1.0);
			}
		}
	}
}

public Action cmdSetSpeed(int client, int args)
{
	if (!cvEnablePlugin.BoolValue)
	{
		ReplyToCommand(client, "\x04[SPS]\x01 The\x05 Set Player Speed\x01 plugin is off.");
		return Plugin_Handled;
	}

	if (args != 2)
	{
		ReplyToCommand(client, "\x04[SPS]\x01 Usage: sm_setspeed <player> <value>");
		return Plugin_Handled;
	}

	char target[32];
	char target_name[MAX_NAME_LENGTH];
	int target_list[MAXPLAYERS];
	int target_count;
	bool tn_is_ml;
	GetCmdArg(1, target, sizeof(target));
	char arg2[32];
	float value;
	GetCmdArg(2, arg2, sizeof(arg2));
	value = StringToFloat(arg2);
	if ((target_count = ProcessTargetString(target, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (int iPlayer = 0; iPlayer < target_count; iPlayer++)
	{
		if (bIsValidClient(iPlayer))
		{
			vChangePlayerSpeed(target_list[iPlayer], value);
		}
	}

	return Plugin_Handled;
}

void vChangePlayerSpeed(int target, float value)
{
	if (bIsValidClient(target))
	{
		SetEntPropFloat(target, Prop_Data, "m_flLaggedMovementValue", value);
	}
}

bool bIsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsClientInKickQueue(client) && IsPlayerAlive(client) && IsValidEntity(client));
}