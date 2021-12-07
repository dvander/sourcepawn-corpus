#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>

new Handle:stun = INVALID_HANDLE;
new Handle:enabled = INVALID_HANDLE;

public OnPluginStart()
{	
	enabled = CreateConVar("sm_stunwrench_enabled", "1", "Enable/Disable Plugin");
	stun = CreateConVar("sm_stunwrench_duration", "1", "Duration of Stunwrench Stun");
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(!enabled) return;

	if (!IsPlayerAlive(attacker) || !IsClientInGame(attacker)) return;
    
	if (!CheckCommandAccess(attacker, "wrench_stun", ADMFLAG_CUSTOM2)) return;
    
	if (!IsClientInGame(victim) || GetClientHealth(victim) <= 0) return;

	new String:strinflictor[32];
	GetEdictClassname(inflictor, strinflictor, sizeof(strinflictor));
 	if (!StrEqual(strinflictor, "player")) return;

	new String:currentweapon[32];
	GetClientWeapon(attacker, currentweapon, sizeof(currentweapon));
	if (!StrEqual(currentweapon, "tf_weapon_wrench")) return;

	new equippedwrench = GetPlayerWeaponSlot(attacker, 2);
	if (GetEntProp(equippedwrench, Prop_Send, "m_iItemDefinitionIndex") != 7) return;
	
	new Float:stunduration = GetConVarFloat(stun);
    
	TF2_StunPlayer(victim, stunduration, _, TF_STUNFLAGS_BIGBONK, attacker);
}