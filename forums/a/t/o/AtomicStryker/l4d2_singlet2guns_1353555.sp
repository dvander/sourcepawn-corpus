#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

static const String:t2strings[][] = {
									"weapon_autoshotgun",
									"weapon_shotgun_spas",
									"weapon_hunting_rifle",
									"weapon_sniper",
									"weapon_rifle"
									};
									
static const		t2weaponIDs[] = {
									4,
									5,
									6,
									9,
									10,
									11,
									26,
									34,
									35,
									36
									};

/*
#define PISTOL 					1
#define SMG 					2
#define PUMPSHOTGUN 			3
#define AUTOSHOTGUN 			4
#define RIFLE 					5
#define HUNTING_RIFLE 			6
#define SMG_SILENCED 			7
#define SHOTGUN_CHROME 			8
#define RIFLE_DESERT 			9
#define SNIPER_MILITARY 		10
#define SHOTGUN_SPAS 			11
#define MOLOTOV 				13
#define PIPE_BOMB 				14
#define VOMITJAR 				25
#define RIFLE_AK47 				26
#define PISTOL_MAGNUM 			32
#define SMG_MP5 				33
#define RIFLE_SG552 			34
#define SNIPER_AWP 				35
#define SNIPER_SCOUT 			36
*/

static const String:GENERIC_WEAPON[] 		= "weapon_spawn";
static const String:WEAPON_ID_ENTPROP[]		= "m_weaponID";


public OnPluginStart()
{
	HookEvent("player_use", Event_PlayerUse);
}

public Action:Event_PlayerUse(Handle:event, const String:name[], bool:dontBroadcast)
{
	new item = GetEventInt(event, "targetid");
	
	if (IsValidEdict(item)
	&& IsT2Gun(item))
	{
		RemoveEdict(item);
	}
}

static bool:IsT2Gun(item)
{
	decl String:itemname[64];
	GetEdictClassname(item, itemname, sizeof(itemname));
	
	if (StrEqual(itemname, GENERIC_WEAPON, false))
	{
		new gunid = GetEntProp(item, Prop_Send, WEAPON_ID_ENTPROP);
		
		for (new x = 0; x < sizeof(t2weaponIDs); x++)
		{
			if (gunid == t2weaponIDs[x])
			{
				return true;
			}
		}
		
		return false;
	}
	
	for (new i = 0; i < sizeof(t2strings); i++)
	{
		if (StrContains(t2strings[i], itemname, false) != -1)
		{
			return true;
		}
	}
	
	return false;
}