#pragma semicolon 1
#include <sourcemod>
#include <tf2items>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <ff2_ams>
#include <freak_fortress_2_subplugin>

public Plugin:myinfo = {
	name = "Freak Fortress 2: Simple Custom Flamethrower",
	author = "JuegosPablo",
	version = "1.0"
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
		if(boss>=0 && FF2_HasAbility(boss, this_plugin_name, "rage_new_flamethrower") && FF2_HasAbility(boss, "ff2_sarysapub3", "ability_management_system"))
		{
			AMSOnly[client]=true;
			AMS_InitSubability(boss, client, this_plugin_name, "rage_new_flamethrower", "RNF");
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
	if(StrEqual(ability_name, "rage_new_flamethrower", false) && !AMSOnly[client])
	{
		RNF_Invoke(client);						// Standard Bowrage
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

public bool:RNF_CanInvoke(client)
{
	return true;
}

public RNF_Invoke(client)
{
	new weapon;
	new boss=FF2_GetBossIndex(client);
	new rnftype=FF2_GetAbilityArgument(boss,this_plugin_name,"rage_new_flamethrower", 1);	// Bow type? (0: Huntsman, 1: Festive Huntsman, 2: Fortified Compound, 3: Crusader's Crossbow, 4: Festive Crusader's crossbow)
	new clip=FF2_GetAbilityArgument(boss,this_plugin_name,"rage_new_flamethrower", 2);	// Clip amount
	TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
	switch(rnftype)
	{
		case 1:
			weapon = SpawnWeapon(client, "tf_weapon_rocketlauncher_fireball", 1178, 101, 5, "37 ; 0.2 ; 783 ; 20 ; 801 ; 0.8 ; 856 ; 1 ; 2062 ; 0.25 ; 2063 ; 1 ; 2064 ; 1 ; 2065 ; 1 ; 2025 ; 2 ; 2014 ; 1");
		case 2:
			weapon = SpawnWeapon(client, "tf_weapon_flamethrower", 594, 101, 5, "839 ; 2.8 ; 841 ; 0 ; 843 ; 12 ; 844 ; 2300 ; 862 ; 0.6 ; 863 ; 0.1 ; 865 ; 5 ; 368 ; 1 ; 144 ; 1 ; 116 ; 5 ; 356 ; 1 ; 15 ; 0 ; 350 ; 1 ; 2025 ; 2 ; 2014 ; 1");
		case 3:
			weapon = SpawnWeapon(client, "tf_weapon_flamethrower", 40, 101, 5, "841 ; 0 ; 843 ; 8.5 ; 865 ; 50 ; 844 ; 2450 ; 839 ; 2.8 ; 862 ; 0.6 ; 863 ; 0.1 ; 2025 ; 2 ; 2014 ; 1");
		case 4:
			weapon = SpawnWeapon(client, "tf_weapon_flamethrower", 208, 101, 5, "542 ; 1 ; 2027 ; 1 ; 841 ; 0 ; 843 ; 8.5 ; 865 ; 50 ; 844 ; 2450 ; 839 ; 2.8 ; 862 ; 0.6 ; 863 ; 0.1 ; 2025 ; 2 ; 2014 ; 1");
		case 5:
			weapon = SpawnWeapon(client, "tf_weapon_flamethrower", 741, 101, 5, "841 ; 0 ; 843 ; 8.5 ; 865 ; 50 ; 844 ; 2450 ; 839 ; 2.8 ; 862 ; 0.6 ; 863 ; 0.1 ; 2025 ; 2 ; 2014 ; 1");
		case 6:
			weapon = SpawnWeapon(client, "tf_weapon_flamethrower", 1146, 101, 5, "841 ; 0 ; 843 ; 8.5 ; 865 ; 50 ; 844 ; 2450 ; 839 ; 2.8 ; 862 ; 0.6 ; 863 ; 0.1 ; 2025 ; 2 ; 2014 ; 1");
		case 7:
			weapon = SpawnWeapon(client, "tf_weapon_flamethrower", 215, 101, 5, "841 ; 0 ; 843 ; 8.5 ; 865 ; 50 ; 844 ; 2450 ; 839 ; 2.8 ; 862 ; 0.6 ; 863 ; 0.1 ; 2025 ; 2 ; 2014 ; 1");			
		case 8:
			weapon = SpawnWeapon(client, "tf_weapon_flamethrower", 659, 101, 5, "841 ; 0 ; 843 ; 8.5 ; 865 ; 50 ; 844 ; 2450 ; 839 ; 2.8 ; 862 ; 0.6 ; 863 ; 0.1 ; 2025 ; 2 ; 2014 ; 1");	
		default:
			weapon = SpawnWeapon(client, "tf_weapon_flamethrower", 21, 101, 5, "841 ; 0 ; 843 ; 8.5 ; 865 ; 50 ; 844 ; 2450 ; 839 ; 2.8 ; 862 ; 0.6 ; 863 ; 0.1 ; 2025 ; 2 ; 2014 ; 1");
	}
	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	if(clip)
		SetEntProp(weapon, Prop_Send, "m_iClip1", clip);
		
	if(AMSOnly[client])
	{
		new String:sound[PLATFORM_MAX_PATH];
		if(FF2_RandomSound("sound_speed_and_conditions", sound, sizeof(sound), boss))
		{
			EmitSoundToAll(sound, client);
			EmitSoundToAll(sound, client);	
		}
	}
}