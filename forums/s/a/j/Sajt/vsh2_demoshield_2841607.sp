#include <sourcemod>
#include <sdktools>
#include <vsh2>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
    name = "[VSH2] Demo Shield Protection",
    author = "Sajt",
    description = "Modifies boss damage to protect demo shield and player HP.",
    version = "1.0",
};

public void OnLibraryAdded(const char[] name) {
    if (StrEqual(name, "VSH2")) {
        if( !VSH2_HookEx(OnBossDealDamage_OnHitShield, hitShield) )
            LogError("Error Hooking OnBossTakeDamage_OnStabbed forward for VSH2 Extension Plugin");
    }
}

public Action hitShield(VSH2Player victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
    if (!IsValidClient(victim.index) || !IsValidClient(attacker) || !VSH2Player(attacker).bIsBoss)
        return Plugin_Continue;

    int ent = GetDemoShield(victim.index);
    if (ent == -1)
        return Plugin_Continue;

    int currentHP = GetClientHealth(victim.index);
    int maxHP = GetEntProp(victim.index, Prop_Data, "m_iMaxHealth");
    
    float maxAllowedDamage = float(maxHP) * 0.75;
    if (damage > maxAllowedDamage)
    {
        damage = maxAllowedDamage;
    }

    int newHP = currentHP - RoundToNearest(damage);
    if (newHP <= 0 && currentHP > 0)
    {
        TF2_RemoveWearable(victim.index, ent);
        SetEntProp(victim.index, Prop_Data, "m_iHealth", 1);
        damage = 0.0;
        EmitSoundToAll("player/spy_shield_break.wav", victim.index, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, true, 0.0);
        return Plugin_Changed;
    }

    return Plugin_Changed;
}

stock bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

stock int GetDemoShield(int client)
{
	int numwearables = TF2_GetNumWearables(client);
	for( int i=numwearables-1; i>=0; --i ) {
		int wearable = TF2_GetWearable(client, i);
		if( wearable && HasEntProp(wearable, Prop_Send, "m_bDisguiseWearable") && !GetEntProp(wearable, Prop_Send, "m_bDisguiseWearable") ) {
			char cls[32];
			if( GetEntityClassname(wearable, cls, sizeof(cls)), !strncmp(cls, "tf_wearable_demo", 16, false) ) {
				return wearable;
			}
		}
	}
	return -1;
}

stock int TF2_GetNumWearables(int client)
{
	/// 3552 linux
	/// 3532 windows
	int offset = FindSendPropInfo("CTFPlayer", "m_flMaxspeed") - 20 + 12;
	return GetEntData(client, offset);
}

stock int TF2_GetWearable(int client, int wearableidx)
{
	/// 3540 linux
	/// 3520 windows
	int offset = FindSendPropInfo("CTFPlayer", "m_flMaxspeed") - 20;
	Address m_hMyWearables = view_as< Address >(LoadFromAddress(GetEntityAddress(client) + view_as< Address >(offset), NumberType_Int32));
	return LoadFromAddress(m_hMyWearables + view_as< Address >(4 * wearableidx), NumberType_Int32) & 0xFFF;
}