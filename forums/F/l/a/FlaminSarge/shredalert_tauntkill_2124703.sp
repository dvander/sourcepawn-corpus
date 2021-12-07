#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0.1"

public Plugin:myinfo =
{
	name = "[TF2] Shred Alert Tauntkill",
	author = "FlaminSarge",
	description = "Causes the Shred Alert to use the unused taunt kill effect",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=238676"
}

public OnPluginStart()
{
	CreateConVar("shredalert_tauntkill_version", PLUGIN_VERSION, "[TF2] Shred Alert Tauntkill version");
	//TODO: Cvars for who gets the tauntkill, enable/disable
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
}
public Event_PlayerDeath(Handle:event, const String:name[], bool:bDontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new customkill = GetEventInt(event, "customkill");
	if (attacker <= 0 || attacker > MaxClients || !IsClientInGame(attacker))
		return;
	if (GetEntProp(attacker, Prop_Send, "m_iTauntItemDefIndex") != 1015 || customkill != TF_CUSTOM_TAUNT_ARMAGEDDON)
		return;
	SetEventInt(event, "customkill", TF_CUSTOM_TAUNT_ALLCLASS_GUITAR_RIFF);
	SetEventString(event, "weapon", "taunt_guitar_riff_kill");
	SetEventString(event, "weapon_logclassname", "tf_weapon_taunt_guitar_riff_kill");
}
public Event_PlayerHurt(Handle:event, const String:name[], bool:bDontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new customkill = GetEventInt(event, "custom");
	if (attacker <= 0 || attacker > MaxClients || !IsClientInGame(attacker))
		return;
	if (GetEntProp(attacker, Prop_Send, "m_iTauntItemDefIndex") != 1015 || customkill != TF_CUSTOM_TAUNT_ARMAGEDDON)
		return;
	SetEventInt(event, "custom", TF_CUSTOM_TAUNT_ALLCLASS_GUITAR_RIFF);
}
public TF2_OnConditionAdded(client, TFCond:condition)
{
	if (condition != TFCond_Taunting)
		return;
	//134 is the concept for shred alert, tauntindex 1 is some kinda action taunt, and we check to make sure we're not overriding another taunt event
	if (GetEntProp(client, Prop_Send, "m_iTauntIndex") == 1 && GetEntProp(client, Prop_Send, "m_iTauntItemDefIndex") == 1015 && GetTauntEventIndex(client) == 30)
	{
		RequestFrame(SetShredKill, any:GetClientUserId(client));
	}
}
public SetShredKill(any:userid)
{
	new client = GetClientOfUserId(userid);
	if (!IsClientInGame(client)) return;
	new Float:flCurrTime = GetGameTime();
	SetTauntEventTime(client, flCurrTime + 3.13);	//3.13 seconds from start of taunt
	SetTauntEventIndex(client, 28);	//30 is for the shred alert tauntkill (acts like rainblower, but uses its own kill log/icon)
}
stock SetTauntEventTime(client, Float:time)
{
	new offs = FindSendPropInfo("CTFPlayer", "m_iSpawnCounter");
	if (offs <= 0)
		return;
	SetEntDataFloat(client, offs-32, time);
}
stock Float:GetTauntEventTime(client)
{
	new offs = FindSendPropInfo("CTFPlayer", "m_iSpawnCounter");
	if (offs <= 0)
		return 0.0;	//neutral value typically found on clients
	return GetEntDataFloat(client, offs-32);
}
stock SetTauntEventIndex(client, index)
{
	new offs = FindSendPropInfo("CTFPlayer", "m_iSpawnCounter");
	if (offs <= 0)
		return;
	SetEntData(client, offs-24, index);  //9328 windows
}
stock GetTauntEventIndex(client)
{
	new offs = FindSendPropInfo("CTFPlayer", "m_iSpawnCounter");
	if (offs <= 0)
		return 0;	//neutral value typically found on clients
	return GetEntData(client, offs-24);
}