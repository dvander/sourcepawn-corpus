#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_NAME		"[CSGO] Refill on kill"
#define PLUGIN_VERSION	"1.0"

Handle hAmt = INVALID_HANDLE;
int iAmt;
int iActiveOffset = -1;
int iClip1Offset = -1;
int iAmmoOffset = -1;

public Plugin myinfo = {
	name		= PLUGIN_NAME,
	author		= "Grey83",
	description	= "",
	version		= PLUGIN_VERSION,
	url			= "https://forums.alliedmods.net/showthread.php?p=2412441"
};

public void OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSGO) SetFailState("Plugin for CSGO only!");

	hAmt = CreateConVar("sm_refill_amt", "5", "The amount of ammo that will get the attacker after the kill.");
	iAmt = GetConVarInt(hAmt);
	HookConVarChange(hAmt, OnConVarChange);

	HookEvent("player_death", Event_Death);

	iActiveOffset = FindSendPropOffs("CAI_BaseNPC", "m_hActiveWeapon");
	iClip1Offset = FindSendPropOffs("CBaseCombatWeapon", "m_iClip1");
//	iAmmoOffset = FindSendPropOffs("CBaseCombatWeapon", "m_iPrimaryAmmoCount");
	iAmmoOffset = FindSendPropOffs("CBaseCombatWeapon", "m_iSecondaryAmmoCount");
}

public void OnConVarChange(Handle cvar, const char[] oldValue, const char[] newValue)
{
	if (cvar == hAmt) iAmt = GetConVarBool(hAmt);
}

public Action Event_Death(Handle event, const char[] name, bool dontBroadcast)
{
	int victim = GetEventInt(event, "userid");
	int attacker = GetEventInt(event, "attacker");
	char weapon[32];
	GetEventString(event, "weapon", weapon, sizeof(weapon));

	if (0 < attacker <= MaxClients && attacker != victim && IsClientInGame(attacker) && IsPlayerAlive(attacker))
	{
		if (StrContains(weapon, "knife") == 0 || StrContains(weapon, "bayonet") == 0)
		{
			AddAmmo(GetPlayerWeaponSlot(attacker, 0));
			AddAmmo(GetPlayerWeaponSlot(attacker, 1));
		}
		if (StrContains(weapon, "grenade") != -1 || StrContains(weapon, "flashbang") == 0 || StrContains(weapon, "molotov") == 0 || StrContains(weapon, "decoy") == 0 || StrContains(weapon, "taser") == 0)
		{
			char granade[32];
			Format(granade, sizeof(granade), "weapon_%s", weapon);
			GivePlayerItem(attacker, granade);
		}
		else AddAmmo(GetEntDataEnt2(attacker, iActiveOffset));
	}
	return Plugin_Continue;
}

void AddAmmo(int weapon)
{
	if (IsValidEntity(weapon))
	{
		int iClip = GetEntData(weapon, iClip1Offset, 4);
		if (iClip > 0 && iAmmoOffset > 0) SetEntData(weapon, iClip1Offset, iClip+iAmt, _, true);
	}
}