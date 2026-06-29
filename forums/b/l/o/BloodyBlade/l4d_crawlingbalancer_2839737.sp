#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_NOTIFY|FCVAR_SPONLY

ConVar l4d_crawlingbalance_enable, l4d_crawlingbalancer_hurt;
bool bPluginOn = false;
int iHurt = 0;
float fHurtInterval[MAXPLAYERS + 1] = {0.0, ...};

public Plugin myinfo = 
{
	name = "[L4D] Crawling Balancer",
	author = "BloodyBlade",
	description = "Allow crawling and take dmg every crawl secs.",
	version = PLUGIN_VERSION,
	url = "http://bloodsiworld.ru"
}

public void OnPluginStart()
{
	CreateConVar("l4d_crawlingbalancer_version", PLUGIN_VERSION, "[L4D] Crawl Balancer plugin version", CVAR_FLAGS|FCVAR_DONTRECORD);
	l4d_crawlingbalance_enable = CreateConVar("l4d_crawlingbalance_enable", "1", "Enable/Disable plugin", CVAR_FLAGS, true, 0.0, true, 1.0);
	l4d_crawlingbalancer_hurt = CreateConVar("l4d_crawlingbalancer_hurt", "2",	"Damage to apply every second of crawling, 0=No damage when crawling.", CVAR_FLAGS);
	AutoExecConfig(true, "l4d_crawlbalancer");
	l4d_crawlingbalance_enable.AddChangeHook(OnConVarsCnanged);
	l4d_crawlingbalancer_hurt.AddChangeHook(OnConVarsCnanged);
}

public void OnConfigsExecuted()
{
    OnConVarsCnanged(null, "", "");
}

void OnConVarsCnanged(ConVar cvar, const char[] OldValue, const char[] NewValue)
{
	bPluginOn = l4d_crawlingbalance_enable.BoolValue;
	iHurt = l4d_crawlingbalancer_hurt.IntValue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(bPluginOn)
	{
		if(IsValidSurv(client) && (buttons & IN_FORWARD))
		{
			if(IsIncapOrLedge(client))
			{
				SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
				if(GetGameTime() - fHurtInterval[client] >= 1.0)
				{
					fHurtInterval[client] = GetGameTime();
				}
				else
				{
					return Plugin_Continue;
				}

				if(iHurt > 0)
				{
					int iHealth = GetClientHealth(client) - iHurt;
					if(iHealth > 0)
					{
						SetEntityHealth(client, iHealth);
					}
				}
			}
			else
			{
				fHurtInterval[client] = 0.0;
			}
		}
	}
	return Plugin_Continue;
}

stock bool IsValidSurv(int client)
{
    return client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client);
}

stock bool IsIncapOrLedge(int client)
{
    return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated")) || view_as<bool>(GetEntProp(client, Prop_Send, "m_isHangingFromLedge"));
}
