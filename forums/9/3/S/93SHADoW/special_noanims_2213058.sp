/*
special_noanims:	arg0 - unused.
					arg1 - 1=Custom Model Rotates (def.0)

rage_new_weapon:	arg0 - slot (def.0)
					arg1 - new weapon's classname
					arg2 - new weapon's index
					arg3 - new weapon's attributes
					arg4 - new weapon's slot (0 - primary. 1 - secondary. 2 - melee. 3 - pda. 4 - spy's watches)
					arg5 - new weapon's ammo
					arg6 - force switch to this weapon (must be 1 if using timed weapons)
					arg7 - new weapon's clip size (if any)
*/
#pragma semicolon 1

#include <sourcemod>
#include <tf2items>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#define PLUGIN_VERSION "1.9.2"

new Handle: notforever;

public Plugin:myinfo=
{
	name="Freak Fortress 2: special_noanims",
	author="RainBolt Dash",
	description="FF2: New Weapon and No Animations abilities",
	version=PLUGIN_VERSION
};

public OnPluginStart2()
{
	HookEvent("teamplay_round_start", event_round_start);
	HookEvent("teamplay_round_win", event_round_end);
}

public Action:FF2_OnAbility2(client, const String:plugin_name[], const String:ability_name[], status)
{
	if(!strcmp(ability_name, "rage_new_weapon"))
	{
		Rage_New_Weapon(client, ability_name);
	}
	return Plugin_Continue;
}

public Action:event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.41, Timer_Disable_Anims);
	CreateTimer(9.31, Timer_Disable_Anims);
	return Plugin_Continue;
}

public Action:event_round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (FF2_HasAbility(0, this_plugin_name, "rage_new_weapon"))
		{
				KillTimer(notforever);
				notforever = INVALID_HANDLE;
		}
}

public Action:Timer_Disable_Anims(Handle:timer)
{
	new client;
	for(new boss=0; (client=GetClientOfUserId(FF2_GetBossUserId(boss)))>0; boss++)
	{
		if(FF2_HasAbility(boss, this_plugin_name, "special_noanims"))
		{
			SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 0);
			SetEntProp(client, Prop_Send, "m_bCustomModelRotates", FF2_GetAbilityArgument(boss, this_plugin_name, "special_noanims", 1, 0));
		}
	}
	return Plugin_Continue;
}

Rage_New_Weapon(boss, const String:ability_name[])
{
	new client=GetClientOfUserId(FF2_GetBossUserId(boss));
	if(client<0)
	{
		return;
	}

	decl String:classname[256];
	decl String:attributes[512];
	FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, 1, classname, 64);
	FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, 3, attributes, 64);
	new slot=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 4);
	TF2_RemoveWeaponSlot(client, slot);
	new weapon=SpawnWeapon(client, classname, FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 2, 56), 100, 5, attributes);
	if(FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 6))
	{
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}

	new ammo=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 5);
	new clip=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 7);
	if(ammo>0)
	{
		SetAmmo(client, weapon, ammo, clip);
	}
}

stock SpawnWeapon(client,String:name[],index,level,qual,String:att[], bool:hide=false, bool:equip=false)
{
    new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
    TF2Items_SetClassname(hWeapon, name);
    TF2Items_SetItemIndex(hWeapon, index);
    TF2Items_SetLevel(hWeapon, level);
    TF2Items_SetQuality(hWeapon, qual);
    new String:atts[32][32];
    new count = ExplodeString(att, ";", atts, 32, 32);
    if (count > 1)
    {
        TF2Items_SetNumAttributes(hWeapon, count/2);
        new i2 = 0;
        for (new i = 0;  i < count;  i+= 2)
        {
            TF2Items_SetAttribute(hWeapon, i2, StringToInt(atts[i]), StringToFloat(atts[i+1]));
            i2++;
        }
    }
    else
    TF2Items_SetNumAttributes(hWeapon, 0);
    if (hWeapon == INVALID_HANDLE)
    return -1;
    new entity = TF2Items_GiveNamedItem(client, hWeapon);
    CloseHandle(hWeapon);
    EquipPlayerWeapon(client, entity);
    
    if(hide)
    {
        SetEntProp(entity, Prop_Send, "m_iWorldModelIndex", -1);
        SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 0.001);
    }
    if(equip)
    {
        SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", entity);
    }

    return entity;
}

stock SetAmmo(client, weapon, ammo, clip = 0)
{
    if(clip < 0)
    {
        SetEntProp(weapon, Prop_Data, "m_iClip1", 0);
    }
    else if(clip)
    {
        SetEntProp(weapon, Prop_Data, "m_iClip1", clip);
    }

    new ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
    if(ammotype != -1)
    {
        SetEntProp(client, Prop_Data, "m_iAmmo", ammo, _, ammotype);
    }
}  