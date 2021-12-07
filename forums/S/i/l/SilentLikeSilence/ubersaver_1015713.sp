#include <sourcemod>
#include <tf2_stocks>

new Handle:g_hPluginEnable = INVALID_HANDLE;
new Float: g_hUberAmount[MAXPLAYERS +1];

new bool:IsPlayerMedic[MAXPLAYERS +1] = false;

public Plugin:myinfo =
{
	name = "[TF2] Uber Saver",
	author = "John B.",
	description = "Medics don't lose their über amount when they die",
	version = "1.0.0",
	url = "www.sourcemod.net",
}

public OnPluginStart()
{
	g_hPluginEnable = CreateConVar("sm_ubersaver_enable", "1", "0 Disable | 1 Enable");

	AutoExecConfig(true, "plugin.ubersaver");

	HookEvent("player_changeclass", Event_PlayerChangeClass);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public Action:Event_PlayerChangeClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(g_hPluginEnable) != 1)
	{
		UnhookEvent("player_changeclass", Event_PlayerChangeClass);
		UnhookEvent("player_hurt", Event_PlayerHurt);
		UnhookEvent("player_spawn", Event_PlayerSpawn);
	}

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new TFClassType:class = TF2_GetPlayerClass(client);

	if(class == TFClass_Medic && IsPlayerMedic[client] != true)
	{
		IsPlayerMedic[client] = true;
	}
	else if(class != TFClass_Medic && IsPlayerMedic[client] != false)
	{
		IsPlayerMedic[client] = false;
	}

	return Plugin_Continue;
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(IsPlayerMedic[client] == false) return Plugin_Stop;

	new medigun = GetPlayerWeaponSlot(client, 1);

	g_hUberAmount[client] = GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel");

	return Plugin_Continue;
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(IsPlayerMedic[client] == false) return Plugin_Stop;

	new medigun = GetPlayerWeaponSlot(client, 1);

	SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel", g_hUberAmount[client]);

	return Plugin_Continue;
}