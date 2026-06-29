#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_NOTIFY

public Plugin myinfo =
{
	name = "[L4D2] Health Abuse Fix (Ledge Hang)",
	author = "bullet28(Edit. by BloodyBlade)",
	description = "Disabling abuse method of receiving free health",
	version = PLUGIN_VERSION,
	url = ""
}

ConVar lfd_both_enable;
bool bHooked = false;
int lastHealth[MAXPLAYERS + 1] = {0, ...};
float fLastTempHealth[MAXPLAYERS + 1] = {0.0, ...}, fFrameTempHealth[MAXPLAYERS + 1] = {0.0, ...};

public void OnPluginStart()
{
	CreateConVar("lfd_both_ledge_version", PLUGIN_VERSION, "[L4D2] Health Abuse Fix (Ledge Hang) plugin version", CVAR_FLAGS|FCVAR_DONTRECORD);
	lfd_both_enable = CreateConVar("lfd_both_ledge_enable", "1", "Enable/Disable plugin", CVAR_FLAGS);
	AutoExecConfig(true, "lfd_both_ledge");
	lfd_both_enable.AddChangeHook(OnConVarEnableChanged);
}

public void OnConfigsExecuted()
{
    IsAllowed();
}

void OnConVarEnableChanged(ConVar cvar, const char[] OldValue, const char[] NewValue)
{
    IsAllowed();
}

void IsAllowed()
{
	bool bPluginOn = lfd_both_enable.BoolValue;
	if(!bHooked && bPluginOn)
	{
		bHooked = true;
		HookEvent("revive_success", eventReviveSucess);
	}
	else if(bHooked && !bPluginOn)
	{
		bHooked = false;
		UnhookEvent("revive_success", eventReviveSucess);
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
    if (isPlayerAliveSurvivor(client) && !view_as<bool>(GetEntProp(client, Prop_Send, "m_isHangingFromLedge")))
    {
        lastHealth[client] = GetEntProp(client, Prop_Data, "m_iHealth");
        fLastTempHealth[client] = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
    }
    return Plugin_Continue;
}

Action eventReviveSucess(Event event, const char[] name, bool dontBroadcast)
{
    if (event.GetBool("ledge_hang"))
    {
        int client = GetClientOfUserId(event.GetInt("subject"));
        if (lastHealth[client] == 1)
        {
            fFrameTempHealth[client] = fLastTempHealth[client];
            RequestFrame(delayedReviveSuccess, client);
        }
    }
    return Plugin_Continue;
}

void delayedReviveSuccess(int client)
{
	if (isPlayerAliveSurvivor(client))
	{
		int health = GetEntProp(client, Prop_Data, "m_iHealth");
		if (health == 1)
		{
			float tempHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
			if (fFrameTempHealth[client] <= 3.0 && tempHealth > fFrameTempHealth[client])
			{
				SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
			}
		}
	}
}

stock bool isPlayerAliveSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client);
}
