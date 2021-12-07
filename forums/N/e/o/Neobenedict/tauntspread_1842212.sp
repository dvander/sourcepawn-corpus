#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#define PLUGIN_VERSION "0.1"

new bool:Taunting[MAXPLAYERS + 1];
new Handle:g_bEnabled = INVALID_HANDLE;


public Plugin:myinfo =
{
	name = "Taunt Spread",
	description = "If you kill a taunter, you taunt.",
	version = PLUGIN_VERSION,
	url = "http://www.twinbladesgaming.com/"
};

public OnPluginStart()
{
	g_bEnabled = CreateConVar("sm_tauntspread_enabled", "1", "0 = Disable plugin, 1 = Enable plugin", 0, true, 0.0, true, 1.0);
	CreateConVar("sm_tauntspread_version", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	AddCommandListener(OnTauntButton, "taunt");
	AddCommandListener(OnTauntButton, "+taunt");
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
}

public Action:OnTauntButton(client, const String:command[], args)
{
	if (GetConVarInt(g_bEnabled))
	{
		Taunting[client] = true;
	}
	
	return Plugin_Continue;
}
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	new victimId = GetEventInt(event, "userid");
	new attackerId = GetEventInt(event, "attacker");
	if (GetConVarBool(g_bEnabled)) {
		if (Taunting[GetClientOfUserId(victimId)]) {
			FakeClientCommand(GetClientOfUserId(attackerId), "taunt");
		}
	}

}
public OnGameFrame()
{
	new i = 1;
	while (i <= MaxClients)
	{
		if (Taunting[i])
		{
			if (!TF2_IsPlayerInCondition(i, TFCond_Taunting))
			{
				Taunting[i] = false;
			}
			else
			{
				Taunting[i] = true;
			}
		}
		i++;
	}
}