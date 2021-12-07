#include <sourcemod>
#pragma semicolon 1
#pragma newdecls required
#define PLUGIN_VERSION "1.0"

bool g_bSpedUp[MAXPLAYERS + 1];
ConVar g_cvEnablePlugin;

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
	RegAdminCmd("sm_speedplayer", cmdSetSpeed, ADMFLAG_KICK, "Set a player's speed.");
	g_cvEnablePlugin = CreateConVar("sps_enableplugin", "1", "Enable the plugin?\n(0: OFF)\n(1: ON)");
	CreateConVar("sps_pluginversion", PLUGIN_VERSION, "Plugin version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_cvEnablePlugin.AddChangeHook(vEnablePlugin);
	AutoExecConfig(true, "set_player_speed");
}

public void vEnablePlugin(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (!g_cvEnablePlugin.BoolValue)
	{
		for (int iPlayer; iPlayer <= MaxClients; iPlayer++)
		{
			if (bIsValidClient(iPlayer))
			{
				SetEntPropFloat(iPlayer, Prop_Send, "m_flLaggedMovementValue", 1.0);
			}
		}
	}
}

public Action cmdSetSpeed(int client, int args)
{
	if (!g_cvEnablePlugin.BoolValue)
	{
		ReplyToCommand(client, "\x04[SPS]\x01 The\x05 Set Player Speed\x01 plugin is off.");
		return Plugin_Handled;
	}
	if (!bIsValidClient(client))
	{
		ReplyToCommand(client, "\x04[SPS]\x01 You must be in-game to use this command.");
		return Plugin_Handled;
	}
	char target[32];
	char target_name[MAX_NAME_LENGTH];
	int target_list[MAXPLAYERS];
	int target_count;
	bool tn_is_ml;
	GetCmdArg(1, target, sizeof(target));
	char arg2[32];
	GetCmdArg(2, arg2, sizeof(arg2));
	float value = StringToFloat(arg2);
	char arg3[32];
	GetCmdArg(3, arg3, sizeof(arg3));
	int toggle = StringToInt(arg3);
	if (args != 3)
	{
		ReplyToCommand(client, "\x04[SPS]\x01 Usage: sm_setspeed <#userid|name> <value> <0|1> or sm_speedplayer <#userid|name> <value> <0|1>");
		return Plugin_Handled;
	}
	if ((target_count = ProcessTargetString(target, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (int iPlayer = 0; iPlayer < target_count; iPlayer++)
	{
		vChangePlayerSpeed(target_list[iPlayer], value, toggle);
	}
	return Plugin_Handled;
}

void vChangePlayerSpeed(int client, float value, int toggle)
{
	switch (toggle)
	{
		case 0:
		{
			g_bSpedUp[client] = false;
			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
		}
		case 1:
		{
			if (bIsValidClient(client) && !g_bSpedUp[client])
			{
				g_bSpedUp[client] = true;
				DataPack dpDataPack;
				CreateDataTimer(1.0, tTimerChangePlayerSpeed, dpDataPack, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
				dpDataPack.WriteCell(GetClientUserId(client));
				dpDataPack.WriteFloat(value);
			}
		}
	}
}

public Action tTimerChangePlayerSpeed(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	float value = pack.ReadFloat();
	if (!g_cvEnablePlugin.BoolValue || !bIsValidClient(client) || !g_bSpedUp[client])
	{
		return Plugin_Stop;
	}
	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", value);
	return Plugin_Continue;
}

bool bIsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && !IsClientInKickQueue(client) && IsPlayerAlive(client);
}