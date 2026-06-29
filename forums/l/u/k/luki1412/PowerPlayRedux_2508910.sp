#include <sourcemod>
#include <tf2>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.22"

bool g_bPoweredUp[MAXPLAYERS+1] = {false, ...};
bool g_bPushbackImmunity;
bool g_bRegen;
bool g_bReenableOnRespawn;
float g_fRegenPeriod = 8.0;
ConVar g_CVPushbackImmunity = null;
ConVar g_CVRegen = null;
ConVar g_CVRegenPeriod = null;
ConVar g_CVReenableOnRespawn = null;
Handle g_hTimerRegen = null;

public Plugin myinfo =
{
    name = "[TF2] PowerPlay Redux",
    author = "luki1412, DarthNinja",
    description = "Uber and crits!",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/member.php?u=43109"
}

public void OnPluginStart()
{
	ConVar CVVersion = CreateConVar("sm_ppr_version", PLUGIN_VERSION, "PowerPlay Redux version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_CVReenableOnRespawn = CreateConVar("sm_ppr_reenableonrespawn", "0", "Reenable PowerPlay on respawn. 1 = yes, 0 = no. Default: 0", FCVAR_NONE, true, 0.0, true, 1.0);
	g_CVRegen = CreateConVar("sm_ppr_regen", "1", "Regen HP and ammo for PowerPlay players every couple of secounds. 1 = yes, 0 = no. Default: 1", FCVAR_NONE, true, 0.0, true, 1.0);
	g_CVRegenPeriod = CreateConVar("sm_ppr_regenperiod", "8.0", "How often to regen HP and ammo for PowerPlay players. Low value = bigger perfomance impact. Default: 8.0", FCVAR_NONE, true, 1.0, true, 999.0);
	g_CVPushbackImmunity = CreateConVar("sm_ppr_pushbackimmunity", "0", "Add pushback immunity for Powerplay. Takes effect on the next PowerPlay. 1 = yes, 0 = no. Default: 0", FCVAR_NONE, true, 0.0, true, 1.0);

	RegAdminCmd("sm_powerup", PowerPlays, ADMFLAG_SLAY, "Enables PowerPlay on the target");
	RegAdminCmd("sm_powerplayredux", PowerPlays, ADMFLAG_SLAY, "Enables PowerPlay on the target");
	RegAdminCmd("sm_ppr", PowerPlays, ADMFLAG_SLAY, "Enables PowerPlay on the target");

	HookEvent("player_spawn", Event_PlayerSpawn);
	OnRegenChanged(g_CVRegen, "", "");
	HookConVarChange(g_CVRegen, OnRegenChanged);
	OnRegenPeriodChanged(g_CVRegenPeriod, "", "");
	HookConVarChange(g_CVRegenPeriod, OnRegenPeriodChanged);
	OnReenableOnRespawnChanged(g_CVReenableOnRespawn, "", "");
	HookConVarChange(g_CVReenableOnRespawn, OnReenableOnRespawnChanged);
	OnPushbackImmunityChanged(g_CVPushbackImmunity, "", "");
	HookConVarChange(g_CVPushbackImmunity, OnPushbackImmunityChanged);
	AutoExecConfig(true, "PowerPlay_Redux");
	SetConVarString(CVVersion, PLUGIN_VERSION);
	delete CVVersion;
}

public Action Timer_Regen(Handle timer)
{
	if (!g_bRegen)
	{
		return Plugin_Continue;
	}

	for(int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && (g_bPoweredUp[i] == true))
		{
			TF2_RegeneratePlayer(i);
		}
	}

	return Plugin_Continue;
}

public void OnRegenPeriodChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_fRegenPeriod = GetConVarFloat(convar);
	delete g_hTimerRegen;
	g_hTimerRegen = CreateTimer(g_fRegenPeriod, Timer_Regen, _, TIMER_REPEAT);
}

public void OnPushbackImmunityChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bPushbackImmunity = GetConVarBool(convar);
}

public void OnRegenChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bRegen = GetConVarBool(convar);
}

public void OnReenableOnRespawnChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bReenableOnRespawn = GetConVarBool(convar);
}

public void Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (g_bPoweredUp[client])
	{
		if (g_bReenableOnRespawn)
		{
			PowerPlay(client, true);
			PrintToChat(client,"\x04[PowerPlayRedux]\x01 Reenabled PowerPlay on yourself!");
		}
		else
		{
			PowerPlay(client, false);
			g_bPoweredUp[client] = false;
		}
	}
}

public void OnClientDisconnect(int client)
{
	g_bPoweredUp[client] = false;
}

public Action PowerPlays(int client, int args)
{
	if (args != 0 && args != 2)
	{
		ReplyToCommand(client, "\x04[PowerPlayRedux]\x01 Usage: sm_ppr <target> <1/0> \nIf you dont enter arguments, Powerplay will be toggled on yourself.");
		return Plugin_Handled;
	}

	if (args == 0 && IsPlayerHere(client))
	{
		if (!g_bPoweredUp[client])
		{
			PowerPlay(client, true);
			g_bPoweredUp[client] = true;
			LogAction(client, client, "%N enabled PowerPlay on himself", client);
			ReplyToCommand(client,"\x04[PowerPlayRedux]\x01 You enabled PowerPlay on yourself!");
		}
		else
		{
			PowerPlay(client, false);
			g_bPoweredUp[client] = false;
			LogAction(client, client, "%N disabled PowerPlay on himself", client);
			ReplyToCommand(client,"\x04[PowerPlayRedux]\x01 You disabled PowerPlay on yourself!");
		}

		return Plugin_Handled;
	}
	else if (args == 2)
	{
		if (!CheckCommandAccess(client, "sm_powerplayredux_override", ADMFLAG_BAN))
		{
			ReplyToCommand(client, "\x04[PowerPlayRedux]\x01 Usage: sm_ppr <target> <1/0> \nIf you dont enter arguments, Powerplay will be toggled on yourself.");
			return Plugin_Handled;
		}

		char buffer[64];
		char target_name[MAX_NAME_LENGTH];
		int target_list[MAXPLAYERS];
		int target_count;
		bool tn_is_ml;
		GetCmdArg(1, buffer, sizeof(buffer));

		if ((target_count = ProcessTargetString(buffer,	client,	target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name,	sizeof(target_name), tn_is_ml)) <= 0)
		{
			ReplyToCommand(client, "\x04[PowerPlayRedux]\x01 Invalid target.");
			return Plugin_Handled;
		}

		char Enabled[2];
		GetCmdArg(2, Enabled, sizeof(Enabled));
		int iEnabled = StringToInt(Enabled);

		if (iEnabled == 1)
		{
			ReplyToCommand(client,"\x04[PowerPlayRedux]\x01 You enabled PowerPlay on %s!", target_name);
		}
		else
		{
			ReplyToCommand(client,"\x04[PowerPlayRedux]\x01 You disabled PowerPlay on %s!", target_name);
		}

		for (int i = 0; i < target_count; i++)
		{
			if (IsPlayerHere(target_list[i]))
			{
				if (iEnabled == 1)
				{
					PowerPlay(target_list[i], true);
					g_bPoweredUp[target_list[i]] = true;
					LogAction(client, target_list[i], "%N enabled PowerPlay on %N", client, target_list[i]);
				}
				else
				{
					PowerPlay(target_list[i], false);
					g_bPoweredUp[target_list[i]] = false;
					LogAction(client, target_list[i], "%N disabled PowerPlay on %N", client, target_list[i]);
				}
			}
		}
	}

	return Plugin_Handled;
}

void PowerPlay(int client, bool enabled)
{
	if (enabled)
	{
		TF2_AddCondition(client, TFCond_UberchargedCanteen, TFCondDuration_Infinite, client);
		TF2_AddCondition(client, TFCond_CritCanteen, TFCondDuration_Infinite, client);

		if (g_bPushbackImmunity)
		{
			TF2_AddCondition(client, TFCond_ImmuneToPushback, TFCondDuration_Infinite, client);
		}
	}
	else
	{
		TF2_RemoveCondition(client, TFCond_UberchargedCanteen);
		TF2_RemoveCondition(client, TFCond_CritCanteen);
		TF2_RemoveCondition(client, TFCond_ImmuneToPushback);
	}
}

bool IsPlayerHere(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client));
}