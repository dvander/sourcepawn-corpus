#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define PLUGIN_NAME		"[TF2] Wrangle Multiple Sentries"
#define PLUGIN_AUTHOR		"FlaminSarge"
#define PLUGIN_VERSION		"1.00" //as of March 06, 2013
#define PLUGIN_CONTACT		"http://forums.alliedmods.net/showthread.php?t=210081"
#define PLUGIN_DESCRIPTION	"Allows clients that 'own' multiple sentries to use the Wrangler on all of them properly"

public Plugin:myinfo = {
	name			= PLUGIN_NAME,
	author			= PLUGIN_AUTHOR,
	description		= PLUGIN_DESCRIPTION,
	version			= PLUGIN_VERSION,
	url				= PLUGIN_CONTACT
};
new bool:bEnabled;
public OnPluginStart()
{
	CreateConVar("wranglemultiple_version", PLUGIN_VERSION, "[TF2] Wrangle Multiple Sentries version", FCVAR_NOTIFY|FCVAR_PLUGIN);
	new Handle:hCvarEnabled = CreateConVar("wranglemultiple_enabled", "1", "Enable/Disable wrangling multiple sentries", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	bEnabled = GetConVarBool(hCvarEnabled);
	HookConVarChange(hCvarEnabled, cvarchangeEnabled);
}
public cvarchangeEnabled(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	bEnabled = GetConVarBool(cvar);
}
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:ang[3], &weapon)
{
	if (!bEnabled) return Plugin_Continue;
	decl String:wep[64];
	if (!IsClientInGame(client)) return Plugin_Continue;
	if (!IsPlayerAlive(client)) return Plugin_Continue;
	new offs = FindSendPropInfo("CObjectSentrygun", "m_hEnemy");
	new wepent = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (wepent < MaxClients || !IsValidEntity(wepent)) return Plugin_Continue;
	if (GetEntProp(client, Prop_Send, "m_bFeignDeathReady")) return Plugin_Continue;
	if (TF2_IsPlayerInCondition(client, TFCond_Cloaked) || TF2_IsPlayerInCondition(client, TFCond_Bonked)) return Plugin_Continue;
	if (TF2_IsPlayerInCondition(client, TFCond_Dazed) && GetEntProp(client, Prop_Send, "m_iStunFlags") & (TF_STUNFLAG_BONKSTUCK|TF_STUNFLAG_THIRDPERSON)) return Plugin_Continue;
	new Float:time = GetGameTime();
	if (time < GetEntPropFloat(client, Prop_Send, "m_flNextAttack")) return Plugin_Continue;
	if (time < GetEntPropFloat(client, Prop_Send, "m_flStealthNoAttackExpire")) return Plugin_Continue;
	new bool:nextprim = time >= GetEntPropFloat(wepent, Prop_Send, "m_flNextPrimaryAttack");
	new bool:nextsec = time >= GetEntPropFloat(wepent, Prop_Send, "m_flNextSecondaryAttack");
	if (!nextprim && !nextsec) return Plugin_Continue;
	GetClientWeapon(client, wep, sizeof(wep));
	if (!StrEqual(wep, "tf_weapon_laser_pointer", false)) return Plugin_Continue;
	new i = -1;
	while ((i = FindEntityByClassname(i, "obj_sentrygun")) != -1)
	{
		if (GetEntPropEnt(i, Prop_Send, "m_hBuilder") != client) continue;
		if (GetEntProp(i, Prop_Send, "m_bDisabled")) continue;
		new level = GetEntProp(i, Prop_Send, "m_iUpgradeLevel");
		if (nextsec && level == 3 && buttons & IN_ATTACK2) SetEntData(i, offs+5, 1, 1, true);
		if (nextprim && buttons & IN_ATTACK) SetEntData(i, offs+4, 1, 1, true);
	}
	return Plugin_Continue;
}