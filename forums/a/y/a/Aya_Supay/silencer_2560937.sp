#include <sourcemod>
#pragma semicolon 1
#pragma newdecls required

bool SilencerCheck[MAXPLAYERS + 1];

Handle SilencerEnable;

public Plugin myinfo =
{
	name = "[L4D2] Silencer Weapon.",
	description = "",
	author = "Figa",
	version = "1.1",
	url = ""
};

public void OnPluginStart()
{
	HookEvent("player_death", player_death, EventHookMode_Post);
	HookEvent("player_spawn", player_death, EventHookMode_Post);
	HookEvent("round_end", round_end, EventHookMode_Pre);
	HookEvent("map_transition", round_end, EventHookMode_Pre);
	
	RegConsoleCmd("sm_silent", ToggleSilencer, "sm_silent - Toggle Silencer");
	
	SilencerEnable = CreateConVar( "l4d_enable_silencer", "1", "1 - Enable Toggle Silencer Upgrade; 0 - Disable This Upgrade", FCVAR_PLUGIN);

}
public void OnClientPostAdminCheck(int client)
{
	ClientCommand(client, "bind k sm_silent");
}
public Action round_end(Handle event, const char[] name, bool dontBroadcast)
{
	for(int i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i)) DisableAllUpgrades(i);
	}
}
public Action player_death(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2) DisableAllUpgrades(client);
}
public void OnClientPutInServer(int client)
{
	if (IsFakeClient(client) || (!client)) return;
	DisableAllUpgrades(client);
}
stock void DisableAllUpgrades(int client)
{
	SetEntProp(client, Prop_Send, "m_upgradeBitVec", 0, 4);
	SilencerCheck[client] = false;
}
public Action ToggleSilencer(int client, int args)
{
	if (GetConVarBool(SilencerEnable) && IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		int cl_upgrades = GetEntProp(client, Prop_Send, "m_upgradeBitVec");
		if (!SilencerCheck[client])
		{
			SetEntProp(client, Prop_Send, "m_upgradeBitVec", cl_upgrades + 262144, 4);
			SilencerCheck[client] = true;
			PrintToChat(client, "%t", "Silencer_On");
		}
		else
		{
			SetEntProp(client, Prop_Send, "m_upgradeBitVec", cl_upgrades - 262144, 4);
			SilencerCheck[client] = false;
			PrintToChat(client, "%t", "Silencer_Off");
		}
	}
	return Plugin_Handled;
}



