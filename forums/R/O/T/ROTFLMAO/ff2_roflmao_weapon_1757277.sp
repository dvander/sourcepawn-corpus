//
//arg1 - weapon disable time
//you MUST change SpawnWeapon(Boss, "       This part       ",       This part, 100, 5, "       This part       "));
//

#pragma semicolon 1

#include <sourcemod>
#include <tf2items>
#include <tf2>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#define ME 2048


public Plugin:myinfo = {
	name = "Freak Fortress 2: ROFLMAO's Rage Set - Weapon",
	author = "ROFLMAO",
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	return APLRes_Success;
}

public OnPluginStart2()
{
	LoadTranslations("freak_fortress_2.phrases");
}

public Action:FF2_OnAbility2(index,const String:plugin_name[],const String:ability_name[],action)
{
	if (!strcmp(ability_name,"rage_i_can_use_bison"))
		Rage_Bison(index,ability_name);				//yourability
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

Rage_Bison(index,const String:ability_name[])
{
	new Float:duration=FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,1,1.0)+1.0;
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	TF2_RemoveAllWeapons(Boss);
	SetEntPropEnt(Boss, Prop_Send, "m_hActiveWeapon", SpawnWeapon(Boss, "tf_weapon_raygun", 442, 100, 5, "68 ; 2 ; 2 ; 3.0"));
	CreateTimer(0.5, Timer_Imuseshovel, index);
	CreateTimer(duration, Timer_Stoprage, index);
}

public Action:Timer_Imuseshovel(Handle:hTimer,any:index)
{
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	TF2_RemoveWeaponSlot(Boss, TFWeaponSlot_Melee);
	SetEntPropEnt(Boss, Prop_Send, "m_hActiveWeapon", SpawnWeapon(Boss, "tf_weapon_shovel", 5, 100, 5, "68 ; 2 ; 2 ; 3.0 ; 259 ; 1 ; 269 ; 1"));
	return Plugin_Continue;
}

public Action:Timer_Stoprage(Handle:hTimer,any:index)
{
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	TF2_RemoveAllWeapons(Boss);
	SetEntPropEnt(Boss, Prop_Send, "m_hActiveWeapon", SpawnWeapon(Boss, "tf_weapon_shovel", 5, 100, 5, "68 ; 2 ; 2 ; 3.0 ; 259 ; 1 ; 269 ; 1"));
	return Plugin_Continue;
}