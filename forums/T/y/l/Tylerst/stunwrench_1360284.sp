#include <sourcemod>
#include <sdktools>
#include <tf2>

new Handle:stun = INVALID_HANDLE;

public OnPluginStart()
{	
	stun = CreateConVar("sm_stunwrench_duration", "1", "Duration of Stunwrench Stun");
	HookEvent("player_hurt", OnPlayerHurtEvent);
}

public OnPlayerHurtEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (attacker == 0 || !IsClientInGame(attacker)) return;
    
	if (!CheckCommandAccess(attacker, "wrench_stun", ADMFLAG_CUSTOM2)) return;
    
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (victim == 0 || !IsClientInGame(victim)) return;
    
	if (GetClientHealth(victim) <= 0) return;

	//Check if weapon was a wrench    
	decl String:currentweapon[32];
	GetClientWeapon(attacker, currentweapon, sizeof(currentweapon));
	if (!StrEqual(currentweapon, "tf_weapon_wrench")) return;

	//Then check if it was the regular wrench
	new equippedwrench = GetPlayerWeaponSlot(attacker, 2);
	if (GetEntProp(equippedwrench, Prop_Send, "m_iItemDefinitionIndex") != 7) return;
	
	new Float:stunduration = GetConVarFloat(stun);
    
	TF2_StunPlayer(victim, stunduration, _, TF_STUNFLAGS_BIGBONK, attacker);
}