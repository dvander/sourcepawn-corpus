#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

ConVar g_cvEnabled;
ConVar g_cvHealAmount;
ConVar g_cvReviveCount;
ConVar g_cvMaxIncaps;
bool   g_bEnabled;
int	   g_iHealAmount;
int	   g_iReviveCount;

public Plugin myinfo =
{
	name		= "Black & White Heal Remover when healing teammates",
	author		= "apples1949",
	description = "Remove black & white status when healing teammates",
	version		= "1.1",
	url			= "github.com/apples1949"
};

public void OnPluginStart()
{
	g_cvEnabled		= CreateConVar("sm_bwheal_enabled", "1", "Enable/Disable the plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvHealAmount	= CreateConVar("sm_bwheal_health", "50", "Amount of health to give after healing", FCVAR_NOTIFY, true, 1.0, true, 99.0);
	g_cvReviveCount = CreateConVar("sm_bwheal_revivecount", "0", "Set the number of times incapacitated after healing, which cannot exceed the game's cvar `survivor_max_incapacitated_count`. If set to 0, the player is restored to a non-incapacitated state.", FCVAR_NOTIFY, true, 0.0);

	g_bEnabled		= GetConVarBool(g_cvEnabled);
	g_iHealAmount	= GetConVarInt(g_cvHealAmount);
	g_iReviveCount	= GetConVarInt(g_cvReviveCount);
	HookConVarChange(g_cvEnabled, OnConVarChanged);
	HookConVarChange(g_cvHealAmount, OnConVarChanged);
	HookConVarChange(g_cvReviveCount, OnConVarChanged);

	g_cvMaxIncaps = FindConVar("survivor_max_incapacitated_count");

	HookEvent("heal_success", Event_HealSuccess);

	AutoExecConfig(true, "l4d2_bwheal");
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bEnabled	   = GetConVarBool(g_cvEnabled);
	g_iHealAmount  = GetConVarInt(g_cvHealAmount);
	g_iReviveCount = GetConVarInt(g_cvReviveCount);
	if (g_cvMaxIncaps)
		// Ensure revive count does not exceed survivor_max_incapacitated_count
		g_iReviveCount >= GetConVarInt(g_cvMaxIncaps) ? GetConVarInt(g_cvMaxIncaps) - 1 : g_iReviveCount;
	else g_iReviveCount = 0;
}

public void Event_HealSuccess(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bEnabled) return;

	int healer	= GetClientOfUserId(event.GetInt("userid"));
	int patient = GetClientOfUserId(event.GetInt("subject"));
	if (IsValidSurvivor(healer) && IsValidSurvivor(patient))
	{
		// Restore health
		int currentHealth = GetClientHealth(healer);
		int newHealth	  = currentHealth + g_iHealAmount;
		newHealth		  = newHealth > 100 ? 100 : newHealth;
		SetEntityHealth(healer, newHealth);
		// Send a notification message
		PrintHintText(healer, "Successfully healed a teammate, black and white state removed!");
		// Check if the healer is in black and white state
		if (IsInBlackWhite(healer))
		{
			// Remove black and white state
			SetEntProp(healer, Prop_Send, "m_bIsOnThirdStrike", 0);
			// Stop the heartbeat sound
			StopSound(healer, SNDCHAN_STATIC, "player/heartbeatloop.wav");

			// Set the number of times incapacitated
			SetEntProp(healer, Prop_Send, "m_currentReviveCount", g_iReviveCount);
		}
	}
}

// Check if the client is in black and white state
bool IsInBlackWhite(int client)
{
	return GetEntProp(client, Prop_Send, "m_bIsOnThirdStrike") == 1;
}

// Check if the client is a valid survivor
bool IsValidSurvivor(int client)
{
	return (client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client));
}
