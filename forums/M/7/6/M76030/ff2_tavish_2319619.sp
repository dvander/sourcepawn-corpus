#pragma semicolon 1

#include <sourcemod>
#include <tf2items>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

public Plugin:myinfo = {
	name = "Freak Fortress 2: Tavish's Abilities (2 lives plugin)",
	author = "M7",
};

new tavish;
new String:LIVE1[PLATFORM_MAX_PATH];
new String:LIVE2[PLATFORM_MAX_PATH];

new Float: Live1length;
new Float: Live2length;

public OnPluginStart2()
{
	HookEvent("arena_round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("arena_win_panel", OnRoundEnd, EventHookMode_PostNoCopy);
}

public Action:FF2_OnAbility2(index,const String:plugin_name[],const String:ability_name[],action)
{
	if(!FF2_IsFF2Enabled() || FF2_GetRoundState()!=1)
		return Plugin_Continue;

	if (!strcmp(ability_name,"special_tavish"))
	{
		decl String:classname[64], String:attributes[256];
		decl String:classname2[64], String:attributes2[256];
		new String:BossCond[768], String:BossCond2[768];
		new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
		switch(FF2_GetBossLives(index))
		{
			case 2:
			{
				new Removeslot = FF2_GetAbilityArgument(index, this_plugin_name, ability_name, 19);
				new slot = FF2_GetAbilityArgument(index, this_plugin_name, ability_name, 4);
				TF2_RemoveWeaponSlot(Boss, slot);
				FF2_GetAbilityArgumentString(index, this_plugin_name, ability_name, 1, classname, sizeof(classname));
				new weaponindex=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 2);
				FF2_GetAbilityArgumentString(index, this_plugin_name, ability_name, 3, attributes, sizeof(attributes));
				SetEntPropEnt(Boss, Prop_Send, "m_hActiveWeapon", SpawnWeapon(Boss, classname, weaponindex, 100, 5, attributes));
				CreateTimer(FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,5,5.0),(Removeslot == 1 ? RemoveSecondary : RemovePrimary),index);
				
				FF2_GetAbilityArgumentString(index, this_plugin_name, ability_name, 6, BossCond, sizeof(BossCond));
				if(BossCond[0]!='\0')
				{
					SetCondition(Boss, BossCond);
				}
								
				new ammo = FF2_GetAbilityArgument(index, this_plugin_name, ability_name, 7, 0);
				
				SetAmmo(Boss, TFWeaponSlot_Primary,ammo);
			}
			
			case 1:
			{
				new Removeslot2 = FF2_GetAbilityArgument(index, this_plugin_name, ability_name, 20);
				new slot2 = FF2_GetAbilityArgument(index, this_plugin_name, ability_name, 8);
				TF2_RemoveWeaponSlot(Boss, slot2);
				FF2_GetAbilityArgumentString(index, this_plugin_name, ability_name, 9, classname2, sizeof(classname2));
				new weaponindex2=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 10);
				FF2_GetAbilityArgumentString(index, this_plugin_name, ability_name, 11, attributes2, sizeof(attributes2));
				SetEntPropEnt(Boss, Prop_Send, "m_hActiveWeapon", SpawnWeapon(Boss, classname2, weaponindex2, 100, 5, attributes2));
				
				FF2_GetAbilityArgumentString(index, this_plugin_name, ability_name, 12, BossCond2, sizeof(BossCond2));
				if(BossCond2[0]!='\0')
				{
					SetCondition(Boss, BossCond2);
				}
				
				CreateTimer(FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,13,5.0),(Removeslot2 == 1 ? RemoveSecondary : RemovePrimary),index);
				
				new ammo2 = FF2_GetAbilityArgument(index, this_plugin_name, ability_name, 14, 0);
				
				SetAmmo(Boss, TFWeaponSlot_Primary,ammo2);
			}
		}
	}
	return Plugin_Continue;
}

public Action:RemovePrimary(Handle:hTimer,any:index)
{
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	TF2_RemoveWeaponSlot(Boss, TFWeaponSlot_Primary);
	new weapon=GetPlayerWeaponSlot(Boss, TFWeaponSlot_Melee);
	if(IsValidEdict(weapon))
	{
		SetEntPropEnt(Boss, Prop_Send, "m_hActiveWeapon", weapon);
	}
}

public Action:RemoveSecondary(Handle:hTimer,any:index)
{
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	TF2_RemoveWeaponSlot(Boss, TFWeaponSlot_Secondary);
	new weapon=GetPlayerWeaponSlot(Boss, TFWeaponSlot_Melee);
	if(IsValidEdict(weapon))
	{
		SetEntPropEnt(Boss, Prop_Send, "m_hActiveWeapon", weapon);
	}
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (FF2_IsFF2Enabled())
	{
		tavish = GetClientOfUserId(FF2_GetBossUserId(0));
		if (tavish>0)
		{
			if (FF2_HasAbility(0, this_plugin_name, "special_tavish"))
			{
				decl i;
				for( i = 1; i <= MaxClients; i++ )
				{
					if(IsClientInGame(i) && IsValidClient(i))
					{
						LookPimpin(i);
					}
				}
				LookPimpin(0);
			}
		}
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

LookPimpin(client)
{
	new boss=GetClientOfUserId(FF2_GetBossUserId(client));
	if(IsValidClient(boss))
	{
		FF2_GetAbilityArgumentString(client, this_plugin_name, "special_tavish", 15, LIVE2, PLATFORM_MAX_PATH);
		Live2length = FF2_GetAbilityArgumentFloat(client,this_plugin_name,"special_tavish",16,200.0);
		MuteSecondSong(boss);
		if(LIVE2[0]!='\0')
		{
			EmitSoundToClient(boss,LIVE2); 
			CreateTimer(Live2length, RepeatSong, boss);
		}
	}
}

SoCold(client)
{
	new boss=GetClientOfUserId(FF2_GetBossUserId(client));
	if(IsValidClient(boss))
	{
		FF2_GetAbilityArgumentString(client, this_plugin_name, "special_tavish", 17, LIVE1, PLATFORM_MAX_PATH);
		Live1length = FF2_GetAbilityArgumentFloat(client,this_plugin_name,"special_tavish",18,200.0);
		MuteFirstSong(boss);
		if(LIVE1[0]!='\0')
		{
			EmitSoundToClient(boss,LIVE1);
			CreateTimer(Live1length, RepeatSong, boss);
		}
	}
}

MuteFirstSong(client)
{
	StopSound(client, SNDCHAN_AUTO,LIVE2);
}

MuteSecondSong(client)
{
	StopSound(client, SNDCHAN_AUTO,LIVE1);
}

public Action:RepeatSong(Handle:hTimer)
{
	if (FF2_GetRoundState()==1)
	{
		decl i;
		for( i = 1; i <= MaxClients; i++ )
		{
			if(IsClientInGame(i))
			{
				switch(FF2_GetBossLives(0))
				{
					case 2:
					{
						LookPimpin(i);
					}
					case 1:
					{
						SoCold(i);
					}
				}
			}
		}
	}
	else
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:FF2_OnLoseLife(index)
{
	if (FF2_GetRoundState()==1 && FF2_HasAbility(index, this_plugin_name, "special_tavish"))
	{
		decl i;
		for( i = 1; i <= MaxClients; i++ )
		{
			if(IsClientInGame(i) && IsValidClient(i))
			{
				SoCold(i);
			}
		}
		SoCold(index);
	}
}

public Action:OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(FF2_GetBossUserId());
	decl i;
	for( i = 1; i <= MaxClients; i++ )
	{
		if(IsClientInGame(i))
		{
			MuteFirstSong(i);
			MuteSecondSong(i);
		}
	}
	MuteFirstSong(client);
	MuteSecondSong(client);
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

stock IsValidClient(client, bool:replaycheck=true)
{
	if(client<=0 || client>MaxClients)
	{
		return false;
	}

	if(!IsClientInGame(client))
	{
		return false;
	}

	if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
	{
		return false;
	}

	if(replaycheck)
	{
		if(IsClientSourceTV(client) || IsClientReplay(client))
		{
			return false;
		}
	}
	return true;
}

stock SetCondition(client, String:cond[])
{
	new String:conds[32][32];
	new count = ExplodeString(cond, " ; ", conds, sizeof(conds), sizeof(conds));
	if (count > 0)
	{
		for (new i = 0; i < count; i+=2)
		{
			TF2_AddCondition(client, TFCond:StringToInt(conds[i]), StringToFloat(conds[i+1]));
		}
	}
}