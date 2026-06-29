#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2items>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

public Plugin:myinfo = {
	name	= "Freak Fortress 2: Timed Weapon Rage",
	author	= "Deathreus",
	version = "1.0",
};

#define MAXSPECIALS 64

new BossTeam=_:TFTeam_Blue;

new bool:g_bHasRaged=false;

new Handle:BossKV[MAXSPECIALS];

new Float:WeaponTime;

new Special[MAXPLAYERS+1];
new Specials;

public OnPluginStart2()
{
	HookEvent("teamplay_round_start", event_round_start);
	HookEvent("teamplay_round_win", event_round_end);

	LoadTranslations("freak_fortress_2.phrases");
	
	Specials = 0;
}

public OnMapStart()
{
	for(new specials; specials<MAXSPECIALS; specials++)
	{
		decl String:key[4], String:config[PLATFORM_MAX_PATH];
		new Handle:Kv = CreateKeyValues("");
		FileToKeyValues(Kv, config);
		if(BossKV[specials] != INVALID_HANDLE)
		{
			CloseHandle(BossKV[specials]);
			BossKV[specials] = INVALID_HANDLE;
		}
		IntToString(specials, key, sizeof(key));
		KvGetString(Kv, key, config, PLATFORM_MAX_PATH);
		if(!config[0])
		{
			break;
		}
		LoadCharacter(config);
	}
	g_bHasRaged = false;
}
public OnMapEnd()
{
	g_bHasRaged = false;
}

public Action:FF2_OnAbility2(client, const String:plugin_name[], const String:ability_name[], status)
{
	if (!strcmp(ability_name, "rage_timed_new_weapon"))
		Rage_Timed_New_Weapon(client, ability_name);
	return Plugin_Continue;
}

public Action:event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.3, Timer_GetBossTeam);
	for (new Index = 0; FF2_GetBossIndex(Index)>0; Index++)
	{
		if(FF2_HasAbility(Index, this_plugin_name, "rage_timed_new_weapon"))
			SDKHook(Index, SDKHook_PreThink, Boss_Think);
	}
	return Plugin_Continue;
}
public Action:event_round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bHasRaged = false;
	return Plugin_Continue;
}

public Boss_Think(Boss)
{
	if(g_bHasRaged)
	{
		if(WeaponTime >= GetEngineTime())
		{
			RemoveWeapons(Boss);
			if(GetPlayerWeaponSlot(Boss, 2) == GetEntProp(Boss, Prop_Send, "m_hActiveWeapon"))
			{
				TF2_RemoveWeaponSlot(Boss, TFWeaponSlot_Melee);
				decl String:weapon[64], String:attributes[64], index;
				for(new i=1; ; i++)
				{
					KvRewind(BossKV[Special[Boss]]);
					Format(weapon, 10, "weapon%i", i);
					if(KvJumpToKey(BossKV[Special[Boss]], weapon))
					{
						index = KvGetNum(BossKV[Special[Boss]], "index");
						KvGetString(BossKV[Special[Boss]], "name", weapon, sizeof(weapon));
						KvGetString(BossKV[Special[Boss]], "attributes", attributes, sizeof(attributes));
						if(attributes[0]!='\0')
						{
							Format(attributes, sizeof(attributes), "68 ; 2.0 ; 2 ; 3.0 ; 259 ; 1.0 ; %s", attributes);
								//68: +2 cap rate
								//2: x3 damage
								//259: Mantreads Effect
						}
						else
						{
							attributes="68 ; 2.0 ; 2 ; 3.0 ; 259 ; 1.0";
								//68: +2 cap rate
								//2: x3 damage
								//259: Mantreads Effect
						}

						new BossWeapon=SpawnWeapon(Boss, weapon, index, 101, 5, attributes);
						if(!KvGetNum(BossKV[Special[Boss]], "show", 0))
						{
							SetEntProp(BossWeapon, Prop_Send, "m_iWorldModelIndex", -1);
							SetEntProp(BossWeapon, Prop_Send, "m_nModelIndexOverrides", -1, _, 0);
							SetEntPropFloat(BossWeapon, Prop_Send, "m_flModelScale", 0.001);
						}
						
						SetEntPropEnt(Boss, Prop_Send, "m_hActiveWeapon", BossWeapon);
					}
				}
			}
			SwitchtoSlot(Boss, 2);
			g_bHasRaged = false;
		}
	}
}

Rage_Timed_New_Weapon(client, const String:ability_name[])
{
	new Boss = GetClientOfUserId(FF2_GetBossUserId(client));
	decl String:classname[64];
	decl String:attributes[64];
	
	WeaponTime = GetEngineTime() + FF2_GetAbilityArgumentFloat(client, this_plugin_name, ability_name, 8);  // Duration to keep the weapon, set to 0 or -1 to keep the weapon

	FF2_GetAbilityArgumentString(client, this_plugin_name, ability_name, 1, classname, 64);	// Weapons classname
	FF2_GetAbilityArgumentString(client, this_plugin_name, ability_name, 3, attributes, 64);	// Attributes to apply to the weapon

	new slot = FF2_GetAbilityArgument(client, this_plugin_name, ability_name, 4);		// Slot of the weapon 0 = Primary(Or sapper), 1 = Secondary(Or spies revolver), 2 = Melee, 3 = PDA1(Build tool, disguise kit), 4 = PDA2(Destroy tool, cloak), 5 = Building
	TF2_RemoveWeaponSlot(Boss, slot);

	new weapon = SpawnWeapon(Boss, classname, FF2_GetAbilityArgument(client, this_plugin_name, ability_name, 2)/*Index number*/, 100, 5, attributes);
	
	if (FF2_GetAbilityArgument(client, this_plugin_name, ability_name, 7))	// Make them equip it?
		SetEntPropEnt(Boss, Prop_Send, "m_hActiveWeapon", weapon);
		
	g_bHasRaged = true;
	
	new ammo = FF2_GetAbilityArgument(Boss, this_plugin_name, ability_name, 5, 0);
	new clip = FF2_GetAbilityArgument(Boss, this_plugin_name, ability_name, 6, 0);
	
	if(ammo || clip)
		FF2_SetAmmo(client, weapon, ammo, clip);
		
}

public Action:Timer_GetBossTeam(Handle:hTimer)
{
	BossTeam=FF2_GetBossTeam();
	return Plugin_Continue;
}

stock GetIndexOfWeaponSlot(client, slot)
{
	new weapon = GetPlayerWeaponSlot(client, slot);
	return (weapon > MaxClients && IsValidEntity(weapon) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
}
stock RemoveWeapons(client)
{
	if (IsValidClient(client) && GetPlayerWeaponSlot(client, 0) != -1 && GetClientTeam(client)==BossTeam)
	{
		TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
		SwitchtoSlot(client, TFWeaponSlot_Melee);
	}
	else if (IsValidClient(client) && GetPlayerWeaponSlot(client, 1) != -1 && GetClientTeam(client)==BossTeam)
	{
		TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
		SwitchtoSlot(client, TFWeaponSlot_Melee);
	}
}
stock SwitchtoSlot(client, slot)
{
	if (slot >= 0 && slot <= 5 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		decl String:classname[64];
		new wep = GetPlayerWeaponSlot(client, slot);
		if (wep > MaxClients && IsValidEdict(wep) && GetEdictClassname(wep, classname, sizeof(classname)))
		{
			FakeClientCommandEx(client, "use %s", classname);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", wep);
		}
	}
}
stock bool:IsValidClient(client, bool:bReplay = true)
{
	if(client <= 0
	|| client > MaxClients
	|| !IsClientInGame(client))
		return false;

	if(bReplay
	&& (IsClientSourceTV(client) || IsClientReplay(client)))
		return false;

	return true;
}
stock FindEntityByClassname2(startEnt, const String:classname[])
{
	/* If startEnt isn't valid shifting it back to the nearest valid one */
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}
stock SpawnWeapon(client, String:name[], index, level, qual, String:att[])
{
	new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	if(hWeapon==INVALID_HANDLE)
	{
		return -1;
	}

	TF2Items_SetClassname(hWeapon, name);
	TF2Items_SetItemIndex(hWeapon, index);
	TF2Items_SetLevel(hWeapon, level);
	TF2Items_SetQuality(hWeapon, qual);
	new String:atts[32][32];
	new count = ExplodeString(att, ";", atts, 32, 32);

	if(count%2!=0)
	{
		--count;
	}

	if(count>0)
	{
		TF2Items_SetNumAttributes(hWeapon, count/2);
		new i2 = 0;
		for(new i=0; i<count; i+=2)
		{
			new attrib = StringToInt(atts[i]);
			if(attrib==0)
			{
				LogError("Bad weapon attribute passed: %s ; %s", atts[i], atts[i+1]);
				CloseHandle(hWeapon);
				return -1;
			}
			
			TF2Items_SetAttribute(hWeapon, i2, attrib, StringToFloat(atts[i+1]));
			i2++;
		}
	}
	else
		TF2Items_SetNumAttributes(hWeapon, 0);
	new entity = TF2Items_GiveNamedItem(client, hWeapon);
	CloseHandle(hWeapon);
	EquipPlayerWeapon(client, entity);
	return entity;
}

public LoadCharacter(const String:character[])
{
	decl String:config[PLATFORM_MAX_PATH];

	BuildPath(Path_SM, config, PLATFORM_MAX_PATH, "configs/freak_fortress_2/%s.cfg", character);
	if(!FileExists(config))
	{
		LogError("[FF2] Character %s does not exist!", character);
		return;
	}
	BossKV[Specials]=CreateKeyValues("character");
	FileToKeyValues(BossKV[Specials], config);

	new version=KvGetNum(BossKV[Specials], "version", 1);
	if(version!=1)
	{
		LogError("[FF2] Character %s is only compatible with FF2 v%i!", character, version);
		return;
	}

	for(new i=1; ; i++)
	{
		Format(config, 10, "ability%i", i);
		if(KvJumpToKey(BossKV[Specials], config))
		{
			decl String:plugin_name[64];
			KvGetString(BossKV[Specials], "plugin_name", plugin_name, 64);
			BuildPath(Path_SM, config, PLATFORM_MAX_PATH, "plugins/freaks/%s.ff2", plugin_name);
			if(!FileExists(config))
			{
				LogError("[FF2] Character %s needs plugin %s!", character, plugin_name);
				return;
			}
		}
		else
		{
			break;
		}
	}
	KvRewind(BossKV[Specials]);

	KvSetString(BossKV[Specials], "filename", character);
	KvGetString(BossKV[Specials], "name", config, PLATFORM_MAX_PATH);

	Specials++;
}