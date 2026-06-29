// only made due to issues rage_new_weapon has with clipless weps such as miniguns, Sniper Rifles, flamethrowers, and Flare Guns

#pragma semicolon 1

#include <sourcemod>
#include <tf2items>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
#define MB 3

new bEnableSuperDuperJump[MB];
new Handle:OnHaleJump = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "FF2 Package - Mokou + Radigan Conagher",
	author = "EP",
};

public OnPluginStart2()
{
	HookEvent("teamplay_round_start", event_round_start);
}

public OnMapStart()
{
	PrecacheSound("replay\\exitperformancemode.wav",true);
	PrecacheSound("replay\\enterperformancemode.wav",true);
}


public Action:FF2_OnAbility2(index,const String:plugin_name[],const String:ability_name[],action)
{
	if (!strcmp(ability_name,"rage_radigan"))
		Rage_Radigan(index);									// Minigun
	else if (!strcmp(ability_name,"rage_moko"))
		Rage_Mokou(index);						// Detonator
	else if (!strcmp(ability_name,"fukkatsu_moko"))
		Fukkatsu_Mokou(index);							// FUJIYAMA VOLCANO!
	return Plugin_Continue;
}

public Action:event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i=0;i<MB;i++)
	{
		bEnableSuperDuperJump[i]=false;
	}
	return Plugin_Continue;
}

stock SpawnWeapon(client,String:name[],index,level,qual,String:att[])
{
	new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	TF2Items_SetClassname(hWeapon, name);
	TF2Items_SetItemIndex(hWeapon, index);
	TF2Items_SetLevel(hWeapon, level);
	TF2Items_SetQuality(hWeapon, qual);
	new String:atts[32][32];
	new count = ExplodeString(att, " ; ", atts, 32, 32);
	if (count > 0)
	{
		TF2Items_SetNumAttributes(hWeapon, count/2);
		new i2 = 0;
		for (new i = 0; i < count; i+=2)
		{
			TF2Items_SetAttribute(hWeapon, i2, StringToInt(atts[i]), StringToFloat(atts[i+1]));
			i2++;
		}
	}
	else
		TF2Items_SetNumAttributes(hWeapon, 0);
	if (hWeapon==INVALID_HANDLE)
		return -1;
	new entity = TF2Items_GiveNamedItem(client, hWeapon);
	CloseHandle(hWeapon);
	EquipPlayerWeapon(client, entity);
	return entity;
}

stock SetAmmo(client, slot, ammo)
{
	new weapon = GetPlayerWeaponSlot(client, slot);
	if (IsValidEntity(weapon))
	{
		new iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
		new iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		SetEntData(client, iAmmoTable+iOffset, ammo, 4, true);
	}
}

Rage_Radigan(index)
{
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	TF2_RemoveWeaponSlot(Boss, TFWeaponSlot_Primary);
	SetEntPropEnt(Boss, Prop_Send, "m_hActiveWeapon", SpawnWeapon(Boss, "tf_weapon_minigun", 312, 100, 5, "2 ; 1.3 ; 86 ; 1.3 ; 5 ; 1.3 ; 37 ; 0 ; 77 ; 0 ; 205 ; 1.5 ; 206 ; 2.25 ; 128 ; 1 ; 75 ; 0.35"));
		// 2 - +30% damage done
		// 86 - +30% spinup time
		// 5 - 30% slower fire speed
		// 75 - -65% move speed when spinning
		// (note: it seems Hales are unaffected by move speed effects on Rage?)
		// 54 - -65% move speed
		// 77 - 0 is max clip size
		// 205 - +50% damage taken from projectiles when active
		// 206 - +125% damage taken from melee sources when active
		// 128 - effects only take hold on active
	SetAmmo(Boss, TFWeaponSlot_Primary,35);
}

Rage_Mokou(index)
{
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	TF2_RemoveWeaponSlot(Boss, TFWeaponSlot_Secondary);
	SetEntPropEnt(Boss, Prop_Send, "m_hActiveWeapon", SpawnWeapon(Boss, "tf_weapon_flaregun", 351, 100, 5, "2 ; 1.4 ; 99 ; 2.5 ; 209 ; 1 ; 97 ; 0.7 ; 6 ; 0.6 ; 25 ; 0.0"));
		// 2 - +40% damage done
		// 99 - +150% splash radius
		// 209 - mini-crits burning targets
		// 97 - -30% reload speed
		// 6 - +40% faster fire rate
		// 25 - 0 is max ammo size
	SetAmmo(Boss, TFWeaponSlot_Secondary,6);
}

Fukkatsu_Mokou(index)
{
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	TF2_RemoveWeaponSlot(Boss, TFWeaponSlot_Primary);
	SetEntPropEnt(Boss, Prop_Send, "m_hActiveWeapon", SpawnWeapon(Boss, "tf_weapon_flamethrower", 594, 100, 5, "2 ; 1.4 ; 137 ; 1.5 ; 37 ; 0 ; 356 ; 1 ; 128 ; 1 ; 62 ; 0.67 ; 252 ; 0.5 ; 64 ; 0.7 ; 107 ; 1.15"));
		// 2 - +40% damage done
		// 62 - -33% damage taken from critical hits
		// 252 - -50% knockback from damage
		// 64 - -30% damage taken from explosions
		// 137 - +50% damage versus buildings
		// 107 - +15% move speed
		// 128 - effects take hold on active
		// 37 - 0 is max ammo size
		// 356 - cannot airblast
	SetAmmo(Boss, TFWeaponSlot_Primary,40);
}

public Action:Timer_ResetCharge(Handle:timer, any:index)
{
	new slot=index%10000;
	index/=1000;
	FF2_SetBossCharge(index,slot,0.0);
}

public Action:FF2_OnTriggerHurt(index,triggerhurt,&Float:damage)
{
	bEnableSuperDuperJump[index]=true;
	if (FF2_GetBossCharge(index,1)<0)
		FF2_SetBossCharge(index,1,0.0);
	return Plugin_Continue;
}