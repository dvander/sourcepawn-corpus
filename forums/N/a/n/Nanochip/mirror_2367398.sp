#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.0"

public Plugin myinfo = {
	name		= "Mirror",
	author		= "Nanochip",
	description = "Rotational Thirdperson View",
	version		= PLUGIN_VERSION,
	url			= "http://steamcommunity.com/id/xNanochip/"
};

bool mirror[MAXPLAYERS + 1] = { false, ... };
Handle mp_forcecamera;

public void OnPluginStart()
{
	CreateConVar("sm_mirror_version", PLUGIN_VERSION, "Mirror Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	mp_forcecamera = FindConVar("mp_forcecamera");
	RegConsoleCmd("sm_mirror", Cmd_Mirror, "Toggle Thirdperson view");
}

public Action Cmd_Mirror(int client, int args)
{
	if (!IsPlayerAlive(client))
	{
		ReplyToCommand(client, "[SM] You may not use this command while dead.");
		return Plugin_Handled;
	}
	
	if (!mirror[client])
	{
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0); 
		SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
		SetEntProp(client, Prop_Send, "m_iFOV", 120);
		SendConVarValue(client, mp_forcecamera, "1");
		mirror[client] = true;
		ReplyToCommand(client, "[SM] Enabled Mirror.");
	}
	else
	{
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
		SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
		SetEntProp(client, Prop_Send, "m_iFOV", 90);
		decl String:valor[6];
		GetConVarString(mp_forcecamera, valor, 6);
		SendConVarValue(client, mp_forcecamera, valor);
		mirror[client] = false;
		ReplyToCommand(client, "[SM] Disabled Mirror.");
	}
	return Plugin_Handled;
}