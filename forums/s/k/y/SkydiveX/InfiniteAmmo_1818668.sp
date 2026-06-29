// Code Created By Skydive On (14-10-12)
// You Are Free To Redistribute Or Use This In Your Own Work Without Restriction Whatsoever.

#include <sourcemod>
#include <cstrike>
#include <sdktools>

new Handle:g_ammoCvarEnable = INVALID_HANDLE;

public Plugin:myinfo= 
{
	name="Infinite Ammo Frenzy",
	author="Skydive",
	description="Reloading is no longer necessary.",
	version="1.0",
	url=""
};

public OnPluginStart()
{
	g_ammoCvarEnable = CreateConVar("sm_infiniteammo", "1", "Plugin Toggle", FCVAR_NOTIFY);
	HookEvent("weapon_fire",Event_WeaponFire);
}


public Event_WeaponFire(Handle:event, const String:name[],bool:dontBroadcast)
{
	if(GetConVarBool(g_ammoCvarEnable))
	{
		decl String:sWeapon[30];
		GetEventString(event,"weapon",sWeapon,30);
		new userid = GetClientOfUserId(GetEventInt(event, "userid"));
		new Slot1 = GetPlayerWeaponSlot(userid, CS_SLOT_PRIMARY);
		new Slot2 = GetPlayerWeaponSlot(userid, CS_SLOT_SECONDARY);
		
		if(IsValidEntity(Slot1))
		{
			if(GetEntProp(Slot1, Prop_Data, "m_iState") == 2)
			{
				SetEntProp(Slot1, Prop_Data, "m_iClip1", GetEntProp(Slot1, Prop_Data, "m_iClip1")+1);
				return;
			}
		}
		if(IsValidEntity(Slot2))
		{
			if(GetEntProp(Slot2, Prop_Data, "m_iState") == 2)
			{
				SetEntProp(Slot2, Prop_Data, "m_iClip1", GetEntProp(Slot2, Prop_Data, "m_iClip1")+1);
				return;
			}
		}
	}
}

