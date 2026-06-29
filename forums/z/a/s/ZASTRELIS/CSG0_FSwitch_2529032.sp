#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_NAME "part of Easy VIP"
#define PLUGIN_AUTHOR "KGB1st"
#define PLUGIN_DESCRIPTION "Bonus system"
#define PLUGIN_VERSION "7.0-beta"
#define PLUGIN_URL "vk.com/doomplay"

#define PRIMARY 0
#define SECONDARY 1

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public OnPluginStart()
{
	HookEvent( "weapon_fire", Event_weapon_fire_Post, EventHookMode_Post );
}

public void Event_weapon_fire_Post( Event event, const char[] name, bool dontBroadcast )
{	
	int att = event.GetInt("userid");
	int attacker = GetClientOfUserId(att);
	
	int iRifle = GetPlayerWeaponSlot( attacker, PRIMARY );
	int iPistol = GetPlayerWeaponSlot( attacker, SECONDARY );
	
	int m_hActiveWeapon = GetEntPropEnt(attacker, Prop_Data, "m_hActiveWeapon");
	
	if(IsValidEdict(m_hActiveWeapon) && IsValidEdict(iRifle) && IsValidEdict(iPistol))
	{
		// Start fast switch on empty weapon
		if((m_hActiveWeapon == iRifle) && (GetEntProp(iRifle, Prop_Data, "m_iClip1") <= 1) && (GetEntProp(iPistol, Prop_Data, "m_iClip1") > 0 ))
		{
			SetEntPropEnt(attacker, Prop_Data, "m_hActiveWeapon", iPistol);
			ChangeEdictState(attacker, FindDataMapInfo( attacker, "m_hActiveWeapon"));
		}
		
		if((m_hActiveWeapon == iPistol) && (GetEntProp(iPistol, Prop_Data, "m_iClip1") <= 1) && (GetEntProp(iRifle, Prop_Data, "m_iClip1") > 0 ))
		{
			SetEntPropEnt(attacker, Prop_Data, "m_hActiveWeapon", iRifle);
			ChangeEdictState(attacker, FindDataMapInfo( attacker, "m_hActiveWeapon"));
		}
	}
}

// Metamod:Source version 1.11.0-dev+1094
// SourceMod Version: 1.9.0.6095
// Exe build: 14:10:28 Jun 13 2017 (6793) (730)
