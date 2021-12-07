#pragma semicolon 1
#include <sourcemod>
#include <tf2items>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <ff2_ams>
#include <freak_fortress_2_subplugin>

public Plugin:myinfo = {
	name = "Freak Fortress 2: Simple Custom Bowrage",
	author = "Koishi",
	version = "1.2"
};

public OnPluginStart2()
{
	HookEvent("arena_round_start", Event_RoundStart);
	if(FF2_GetRoundState()==1)
	{
		HookAbilities();
	}
}

new bool:AMSOnly[MAXPLAYERS+1]=false;

HookAbilities()
{
	for(new client=MaxClients;client;client--)
	{
		if(client<=0 || client>MaxClients || !IsClientInGame(client))
		{
			continue;
		}
		AMSOnly[client]=false;
		new boss=FF2_GetBossIndex(client);
		if(boss>=0 && FF2_HasAbility(boss, this_plugin_name, "rage_new_bowrage") && FF2_HasAbility(boss, "ff2_sarysapub3", "ability_management_system"))
		{
			AMSOnly[client]=true;
			AMS_InitSubability(boss, client, this_plugin_name, "rage_new_bowrage", "BOW");
		}
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	HookAbilities();
}

public Action:FF2_OnAbility2(boss,const String:plugin_name[],const String:ability_name[],action)
{
	new client=GetClientOfUserId(FF2_GetBossUserId(boss));
	if(StrEqual(ability_name, "rage_new_bowrage", false) && !AMSOnly[client])
	{
		BOW_Invoke(client);						// Standard Bowrage
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

public bool:BOW_CanInvoke(client)
{
	return true;
}

public BOW_Invoke(client)
{
	new weapon;
	new String:attributes[256];
	new boss=FF2_GetBossIndex(client);
	new bowtype=FF2_GetAbilityArgument(boss,this_plugin_name,"rage_new_bowrage", 1);	// Bow type? (0: Huntsman, 1: Festive Huntsman, 2: Fortified Compound, 3: Crusader's Crossbow, 4: Festive Crusader's crossbow)
	new kson=FF2_GetAbilityArgument(boss,this_plugin_name,"rage_new_bowrage", 2);	// Killstreaks? (0: Off, 1: On)
	new ammo=FF2_GetAbilityArgument(boss,this_plugin_name,"rage_new_bowrage", 3);	// Ammo amount (0 will match to # of alive players)
	new clip=FF2_GetAbilityArgument(boss,this_plugin_name,"rage_new_bowrage", 4);	// Clip amount
	if(kson)
		attributes="6 ; 0.5 ; 37 ; 0.0 ; 2025 ; 1";
	else
		attributes="6 ; 0.5 ; 37 ; 0.0";
	FF2_GetAbilityArgumentString(boss, this_plugin_name, "rage_new_bowrage", 5, attributes, sizeof(attributes));
	TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
	switch(bowtype)
	{
		case 1:
			weapon = SpawnWeapon(client, "tf_weapon_compound_bow", 1005, 101, 5, attributes);
		case 2:
			weapon = SpawnWeapon(client, "tf_weapon_compound_bow", 1092, 101, 5, attributes);
		case 3:
			weapon = SpawnWeapon(client, "tf_weapon_crossbow", 305, 101, 5, attributes);
		case 4:
			weapon = SpawnWeapon(client, "tf_weapon_crossbow", 1079, 101, 5, attributes);
		default:
			weapon = SpawnWeapon(client, "tf_weapon_compound_bow", 56, 101, 5, attributes);
	}
	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	if(ammo<0)
		ammo=FF2_GetAlivePlayers();
	if(ammo)
		SetAmmo(client, weapon , ammo);
	if(clip)
		SetEntProp(weapon, Prop_Send, "m_iClip1", clip);
}