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
	if (attacker == 0 || !IsClientInGame(attacker)) 
	{
		PrintToChatAll("Attacker check failed: attacker %i", attacker);
		return;
	}
    
	if (!CheckCommandAccess(attacker, "wrench_stun", ADMFLAG_CUSTOM2)) 
	{
		PrintToChatAll("Admin Access check failed")
		return;
	}
    
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (victim == 0 || !IsClientInGame(victim))
	{
		PrintToChatAll("Victim check failed: victim %i", victim)
		return;
    	}
	if (GetClientHealth(victim) <= 0)
	{
		PrintToChatAll("Hit check failed: target killed"); 
		return;
	}

	decl String:currentweapon[32];
	GetClientWeapon(attacker, currentweapon, sizeof(currentweapon));
	if (!StrEqual(currentweapon, "tf_weapon_wrench"))
	{
		PrintToChatAll("Weapon check tf_weapon_wrench failed : Weapon %s", currentweapon);
		return;
	}

	new equippedwrench = GetPlayerWeaponSlot(attacker, 2);
	new wrenchindex = GetEntProp(equippedwrench, Prop_Send, "m_iItemDefinitionIndex");
	if (wrenchindex != 7)
	{
		PrintToChatAll("Wrench check index 7 failed: Wrench Index %i", wrenchindex);
		return;
	}

	new Float:stunduration = GetConVarFloat(stun);
    	if(stunduration <= 0)
	{
		PrintToChatAll("Stun check greater than 0 failed: sm_stunwrench_duration %f", stunduration);
		return;
	}
	if (GetFeatureStatus(FeatureType_Native, "TF2_StunPlayer") != FeatureStatus_Available)
	{
		PrintToChatAll("Stun check failed: TF2_Stunplayer not availible");
		return;
	}
	TF2_StunPlayer(victim, stunduration, _, TF_STUNFLAGS_BIGBONK, attacker);


}