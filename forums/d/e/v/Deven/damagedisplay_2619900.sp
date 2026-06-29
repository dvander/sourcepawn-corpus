#pragma semicolon 1
#define DEBUG
#define PLUGIN_AUTHOR "Maxximou5"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <csgocolors>
#pragma newdecls required
#define HIDEHUD_RADAR 1 << 12

Handle damageDisplay[MAXPLAYERS+1];

bool displayPanel;
bool displayPanelDamage;
bool hideradar;

ConVar cvar_dm_hide_radar;
ConVar cvar_dm_display_panel;
ConVar cvar_dm_display_panel_damage;


public Plugin myinfo = 
{
	name = "DamageDisplay",
	author = PLUGIN_AUTHOR,
	description = "Advanced DamageDisplay with Health",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	LoadTranslations("dmgdisplay.phrases");
	cvar_dm_display_panel = CreateConVar("dm_display_panel", "1", "Display a panel showing health of the victim.");
	cvar_dm_display_panel_damage = CreateConVar("dm_display_panel_damage", "1", "Display a panel showing damage done to a player. Requires dm_display_panel set to 1.");
	cvar_dm_hide_radar = CreateConVar("dm_hide_radar", "1", "Hides the radar from players.");
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
	HookConVarChange(cvar_dm_display_panel, Event_CvarChange);
	HookConVarChange(cvar_dm_display_panel_damage, Event_CvarChange);
	HookConVarChange(cvar_dm_hide_radar, Event_CvarChange);
	
	if (GetEngineVersion() != Engine_CSGO)
    {
        SetFailState("ERROR: This plugin is designed only for CS:GO.");
	}
	UpdateState();
}

public void OnConfigsExecuted()
{
	UpdateState();
}

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if (displayPanel)
	{
		int victim = GetClientOfUserId(event.GetInt("userid"));
		int attacker = GetClientOfUserId(event.GetInt("attacker"));
		int health = event.GetInt("health");

		if (IsValidClient(attacker) && attacker != victim && victim != 0)
		{
			if (0 < health)
			{
				if (displayPanelDamage)
				{
					PrintHintText(attacker, "%t <font color='#FF0000'>%i</font> %t <font color='#00FF00'>%N</font>\n %t <font color='#00FF00'>%i</font>", "Panel Damage Giver", event.GetInt("dmg_health"), "Panel Damage Taker", victim, "Panel Health Remaining", health);
				}
				else
				{
					PrintHintText(attacker, "%t <font color='#FF0000'>%i</font>", "Panel Health Remaining", health);
				}
			}
			else
			{
				PrintHintText(attacker, "\n   %t", "Panel Kill Confirmed");
			}
		}
	}
	return Plugin_Continue;
}

public void Event_CvarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	UpdateState();
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient && IsClientInGame(client) && IsPlayerAlive(client) || (GetClientTeam(client) != CS_TEAM_T) || (GetClientTeam(client) != CS_TEAM_CT))
		{
			if (!IsFakeClient(client))
			{
				/* Hide radar. */
				if (hideradar)
				{
					CreateTimer(0.0, RemoveRadar, GetClientSerial(client));
				}
				/* Display the panel for attacker information. */
				if (displayPanel)
				{
					damageDisplay[client] = CreateTimer(1.0, PanelDisplay, GetClientSerial(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}
			
public Action PanelDisplay(Handle timer, any serial)
{
	int client = GetClientFromSerial(serial);
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		int aim = GetClientAimTarget(client, true);
		if (0 < aim)
		{
			PrintHintText(client, "%t %i", "Panel Health Remaining", GetClientHealth(aim));
			return Plugin_Continue;
		}
	}
	return Plugin_Stop;
}

void UpdateState()
{
	hideradar = GetConVarBool(cvar_dm_hide_radar);
	displayPanel = GetConVarBool(cvar_dm_display_panel);
	displayPanelDamage = GetConVarBool(cvar_dm_display_panel_damage);
}


public Action RemoveRadar(Handle timer, any serial)
{
	int client = GetClientFromSerial(serial);
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		SetEntProp(client, Prop_Send, "m_iHideHUD", HIDEHUD_RADAR);
	}
}

stock bool IsValidClient(int client)
{
	if (client <= 0)return false;
	if (client > MaxClients)return false;
	if (!IsClientConnected(client))return false;
	return IsClientInGame(client);
}
