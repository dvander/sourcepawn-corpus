#pragma semicolon 1

#include <tf2_stocks>
#include <tf2items>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <ff2_ams>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#pragma newdecls required

/*
 * Defines "rage_new_bowrage"
 */
#define BOW "rage_new_bowrage"
bool AMS_BOW[MAXPLAYERS+1];	//AMS Boolean
int BowType[MAXPLAYERS+1]; //Bow type -1
char BowAttribs[764]; //Attributes -2
int BowAmmo[MAXPLAYERS+1]; //Ammo -3
int BowClip[MAXPLAYERS+1]; //Clip -4
bool BowSetActive[MAXPLAYERS+1]; //Set Active Weapon? -5
bool BowSetVis[MAXPLAYERS+1]; //Set Weapon Visibility -6



public Plugin myinfo = 
{
	name = "Freak Fortress 2: Bow Rage",
	author = "93SHADoW, J0BL3SS",
	version = "1.3.0",
};

public void OnPluginStart2()
{
	HookEvent("arena_round_start", Event_RoundStart);
	HookEvent("teamplay_round_active", Event_RoundStart); // for non-arena maps
	
	HookEvent("arena_win_panel", Event_RoundEnd);
	HookEvent("teamplay_round_win", Event_RoundEnd); // for non-arena maps
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if(!FF2_IsFF2Enabled() || FF2_GetRoundState() != 1)
		return;
	
	for(int bossClientIdx = 1; bossClientIdx < MaxClients; bossClientIdx++)
	{		
		int bossIdx = FF2_GetBossIndex(bossClientIdx);
		if(bossIdx >= 0)
		{
			if(FF2_HasAbility(bossIdx, this_plugin_name, BOW))
			{
				AMS_BOW[bossClientIdx] = AMS_IsSubabilityReady(bossIdx, this_plugin_name, BOW);
				if(AMS_BOW[bossClientIdx])
				{
					AMS_InitSubability(bossIdx, bossClientIdx, this_plugin_name, BOW, "BOW");
				}
				BowType[bossClientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, BOW, 1, 0);
				FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, BOW, 2, BowAttribs, sizeof(BowAttribs));
				BowAmmo[bossClientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, BOW, 3, -1);
				BowClip[bossClientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, BOW, 4, 1);
				BowSetActive[bossClientIdx] = view_as<bool>(FF2_GetAbilityArgument(bossIdx, this_plugin_name, BOW, 5, 1));
				BowSetVis[bossClientIdx] = view_as<bool>(FF2_GetAbilityArgument(bossIdx, this_plugin_name, BOW, 6, 1));
			}
		}
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for(int i; i <= MaxClients; i++)
	{	
		AMS_BOW[i] = false;
	}
}

public Action FF2_OnAbility2(int bossIdx, const char[] plugin_name, const char[] ability_name, int status)
{
	if(!FF2_IsFF2Enabled() || FF2_GetRoundState() != 1)
		return Plugin_Continue; // Because some FF2 forks still allow RAGE to be activated when the round is over....
	
	int bossClientIdx = GetClientOfUserId(FF2_GetBossUserId(bossIdx));
	
	if(!strcmp(ability_name, BOW))
	{
		if(AMS_BOW[bossClientIdx])
		{
			if(!FunctionExists("ff2_sarysapub3.ff2", "AMS_InitSubability"))
			{
				AMS_BOW[bossClientIdx] = false;
			}
			else
			{
				return Plugin_Continue;
			}
		}
		BOW_Invoke(bossClientIdx);
	}
	return Plugin_Continue;
}

public bool BOW_CanInvoke(int bossClientIdx)
{
	return true;
}

public void BOW_Invoke(int bossClientIdx)
{
	char BowClassname[128];
	int BowDefIndex, BowNewAmmo, BowNewClip;
	
	switch(BowType[bossClientIdx])
	{
		case 0:
		{
			BowClassname = "tf_weapon_compound_bow"; //Huntsman
			BowDefIndex = 56;
		}
		case 1:
		{
			BowClassname = "tf_weapon_compound_bow"; //Festive Huntsman
			BowDefIndex = 1005;
		}
		case 2:
		{
			BowClassname = "tf_weapon_compound_bow"; //Fortified Compound
			BowDefIndex = 1092;
		}
		case 3:
		{
			BowClassname = "tf_weapon_crossbow"; //Crusader's Crossbow
			BowDefIndex = 305;
		}
		case 4:
		{
			BowClassname = "tf_weapon_crossbow"; //Festive Crusader's Crossbow
			BowDefIndex = 1079;
		}
		default:
		{
			BowClassname = "tf_weapon_compound_bow"; //Huntsman
			BowDefIndex = 56;
		}
	}
	TF2_RemoveWeaponSlot(bossClientIdx, TFWeaponSlot_Primary);
	int weapon = SpawnWeapon(bossClientIdx, BowClassname, BowDefIndex, 101, 5, BowAttribs, BowSetVis[bossClientIdx]);
	if(BowSetActive[bossClientIdx])
	{
		SetEntPropEnt(bossClientIdx, Prop_Send, "m_hActiveWeapon", weapon);
	}
	
	if(BowAmmo[bossClientIdx] <= 0)
		BowNewAmmo = GetAlivePlayerCount();
	else
		BowNewAmmo = BowAmmo[bossClientIdx];
		
	SetAmmo(bossClientIdx, weapon , BowNewAmmo);	

	if(BowClip[bossClientIdx] <= 0)
		BowNewClip = 1;
	else
		BowNewClip = BowClip[bossClientIdx];
		
	SetEntProp(weapon, Prop_Send, "m_iClip1", BowNewClip);

}

stock int SetAmmo(int client, int slot, int ammo)
{
	int weapon = GetPlayerWeaponSlot(client, slot);
	if(IsValidEntity(weapon))
	{
		int iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
		int iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		SetEntData(client, iAmmoTable+iOffset, ammo, 4, true);
	}
}

stock int GetAlivePlayerCount()
{
    int number = 0;
    for (int i=1; i<=MaxClients; i++)
    {
        if (IsPlayerAlive(i) && GetClientTeam(i) != FF2_GetBossTeam()) 
            number++;
    }
    return number;
}

stock int SpawnWeapon(int client, char[] name, int index, int level, int qual, const char[] att, bool visible=true)
{
	#if defined _tf2items_included
	Handle hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	if(hWeapon == INVALID_HANDLE)
		return -1;

	TF2Items_SetClassname(hWeapon, name);
	TF2Items_SetItemIndex(hWeapon, index);
	TF2Items_SetLevel(hWeapon, level);
	TF2Items_SetQuality(hWeapon, qual);
	char atts[32][32];
	int count = ExplodeString(att, ";", atts, 32, 32);

	if(count % 2)
		--count;

	if(count > 0)
	{
		TF2Items_SetNumAttributes(hWeapon, count/2);
		int i2;
		for(int i; i<count; i+=2)
		{
			int attrib = StringToInt(atts[i]);
			if(!attrib)
			{
				LogError("Bad weapon attribute passed: %s ; %s", atts[i], atts[i+1]);
				delete hWeapon;
				return -1;
			}

			TF2Items_SetAttribute(hWeapon, i2, attrib, StringToFloat(atts[i+1]));
			i2++;
		}
	}
	else
	{
		TF2Items_SetNumAttributes(hWeapon, 0);
	}

	int entity = TF2Items_GiveNamedItem(client, hWeapon);
	delete hWeapon;
	if(entity == -1)
		return -1;

	EquipPlayerWeapon(client, entity);

	if(visible)
	{
		SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", 1);
	}
	else
	{
		SetEntProp(entity, Prop_Send, "m_iWorldModelIndex", -1);
		SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 0.001);
	}
	return entity;
	#else
	return -1;
	#endif
}