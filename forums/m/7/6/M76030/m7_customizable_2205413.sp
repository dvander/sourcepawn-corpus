#pragma semicolon 1

#include <sourcemod>
#include <tf2items>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
//#tryinclude <freak_fortress_2_extras> 

#define CLIPLESS "rage_cliplessweapons"
new bool:Clipless_TriggerAMS[MAXPLAYERS+1]; // global boolean to use with AMS
new String:Attributes[768];
new String:Classname[768];


public Plugin:myinfo = {
	name = "FF2 Ability: Customizable Clipless Weapons",
	author = "M7",
};

public OnPluginStart2()
{
	HookEvent("arena_round_start", Event_RoundStart, EventHookMode_Pre);
	HookEvent("arena_win_panel", Event_RoundEnd, EventHookMode_Pre);
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new client=1;client<=MaxClients;client++)
	{
		if(!IsValidClient(client))
			continue;
			
		new boss=FF2_GetBossIndex(client);
		
		Clipless_TriggerAMS[client] = false;
		
		if(boss>=0)
		{
			// Initialize if using AMS for these abilities
			if(FF2_HasAbility(boss, this_plugin_name, CLIPLESS))
			{
				Clipless_TriggerAMS[client]=bool:FF2_GetAbilityArgument(boss, this_plugin_name, CLIPLESS, 7);
				if(Clipless_TriggerAMS[client])
				{
					AMS_InitSubability(boss, client, this_plugin_name, CLIPLESS, "CLIP");
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			Clipless_TriggerAMS[client]=false;
		}
	}
}
			

public Action:FF2_OnAbility2(boss,const String:plugin_name[],const String:ability_name[],action)
{
	new client=GetClientOfUserId(FF2_GetBossUserId(boss));
	
	if(!strcmp(ability_name, CLIPLESS))  // Vaccinator resistances
	{
		Rage_Cliplessweapons(client);
	}
	return Plugin_Continue;
}


Rage_Cliplessweapons(client)
{
	if(Clipless_TriggerAMS[client])
		return;
	
	CLIP_Invoke(client);
}

public bool:CLIP_CanInvoke(client)
{
	return true;
}

public CLIP_Invoke(client)
{
	new boss=FF2_GetBossIndex(client);
	
	new Index = FF2_GetAbilityArgument(boss, this_plugin_name, CLIPLESS, 1);	// weaponindex
	FF2_GetAbilityArgumentString(boss, this_plugin_name, CLIPLESS, 2, Classname, sizeof(Classname));	// weapon attribute
	FF2_GetAbilityArgumentString(boss, this_plugin_name, CLIPLESS, 3, Attributes, sizeof(Attributes));	// weapon classname
	new Ammo = FF2_GetAbilityArgument(boss, this_plugin_name, CLIPLESS, 5);	// weaponindex
	new slot = FF2_GetAbilityArgument(boss, this_plugin_name, CLIPLESS, 6);
	
	TF2_RemoveWeaponSlot(client, slot);
	
	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", SpawnWeapon(client, Classname, Index, 100, 5, Attributes), bool:FF2_GetAbilityArgument(boss, this_plugin_name, CLIPLESS, 4));
	
	if(Ammo)
	{
		SetAmmo(client, slot, Ammo);
	}
	
	if(Clipless_TriggerAMS[client])
	{
		new String:snd[PLATFORM_MAX_PATH];
		if(FF2_RandomSound("sound_clipless_weapon", snd, sizeof(snd), boss))
		{
			EmitSoundToAll(snd, client);
			EmitSoundToAll(snd, client);
		}		
	}
}

stock SpawnWeapon(client,String:name[],index,level,qual,String:att[], bool:isVisible=false)
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
	
	if(!isVisible)
	{
		SetEntProp(entity, Prop_Send, "m_iWorldModelIndex", -1);
		SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 0.001);
	}
	#if defined _FF2_Extras_included
	else
	{
		PrepareWeapon(entity);
	}
	#endif	
	
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

stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients)
		return false;
		
	return IsClientInGame(client);
}

stock Handle:FindPlugin(String: pluginName[])
{
	new String: buffer[256];
	new String: path[PLATFORM_MAX_PATH];
	new Handle: iter = GetPluginIterator();
	new Handle: pl = INVALID_HANDLE;
	
	while (MorePlugins(iter))
	{
		pl = ReadPlugin(iter);
		Format(path, sizeof(path), "%s.ff2", pluginName);
		GetPluginFilename(pl, buffer, sizeof(buffer));
		if (StrContains(buffer, path, false) >= 0)
			break;
		else
			pl = INVALID_HANDLE;
	}
	
	CloseHandle(iter);

	return pl;
}

stock AMS_InitSubability(bossIdx, clientIdx, const String: pluginName[], const String: abilityName[], const String: prefix[])
{
	new Handle:plugin = FindPlugin("ff2_sarysapub3");
	if (plugin != INVALID_HANDLE)
	{
		new Function:func = GetFunctionByName(plugin, "AMS_InitSubability");
		if (func != INVALID_FUNCTION)
		{
			Call_StartFunction(plugin, func);
			Call_PushCell(bossIdx);
			Call_PushCell(clientIdx);
			Call_PushString(pluginName);
			Call_PushString(abilityName);
			Call_PushString(prefix);
			Call_Finish();
		}
		else
			LogError("ERROR: Unable to initialize ff2_sarysapub3:AMS_InitSubability()");
	}
	else
		LogError("ERROR: Unable to initialize ff2_sarysapub3:AMS_InitSubability(). Make sure this plugin exists!");
}