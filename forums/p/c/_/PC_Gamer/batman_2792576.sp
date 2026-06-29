#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#undef REQUIRE_PLUGIN
#include <rtd2>

#pragma newdecls required

#define PLUGIN_VERSION "1.1"
#define SPAWN	"/ui/halloween_loot_spawn.wav"
#define DEATH	"/misc/taps_02.wav"

public Plugin myinfo =
{
	name = "[TF2] Be the Batman",
	author = "PC Gamer",
	description = "Play as the Batman",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

bool g_bIsBatman[MAXPLAYERS + 1];
bool g_bIsRTD2Loaded = false;

Handle g_hEquipWearable;

public void OnPluginStart()
{
	LoadTranslations("common.phrases");

	RegAdminCmd("sm_bebatman", Command_Batman, ADMFLAG_SLAY, "Become the Batman");
	RegAdminCmd("sm_batman", Command_Batman, ADMFLAG_SLAY, "Become the Batman");

	HookEvent("post_inventory_application", EventInventoryApplication, EventHookMode_Post);
	HookEvent("player_death", Event_Death, EventHookMode_Post);
	
	GameData hTF2 = new GameData("sm-tf2.games"); // sourcemod's tf2 gamedata

	if (!hTF2)
	SetFailState("This plugin is designed for a TF2 dedicated server only.");

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetVirtual(hTF2.GetOffset("RemoveWearable") - 1);    // EquipWearable offset is always behind RemoveWearable, subtract its value by 1
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hEquipWearable = EndPrepSDKCall();

	if (!g_hEquipWearable)
	SetFailState("Failed to create call: CBasePlayer::EquipWearable");

	delete hTF2;
}

public void OnAllPluginsLoaded()
{
	g_bIsRTD2Loaded = LibraryExists("RollTheDice2");
}

public void OnClientPutInServer(int client)
{
	OnClientDisconnect_Post(client);
}

public void OnClientDisconnect_Post(int client)
{
	if (g_bIsBatman[client])
	{
		StopSound(client, SNDCHAN_AUTO, SPAWN);
		StopSound(client, SNDCHAN_AUTO, SPAWN);		
		g_bIsBatman[client] = false;
	}
}

public void OnMapStart()
{
	PrecacheSound(SPAWN);
	PrecacheSound(DEATH);
}

public void EventInventoryApplication(Handle event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_bIsBatman[client])
	{
		SetEntProp(client, Prop_Send, "m_iHealth", 125, 1);
		
		StopSound(client, SNDCHAN_AUTO, SPAWN);
		StopSound(client, SNDCHAN_AUTO, SPAWN);		
		
		SetVariantInt(0);
		AcceptEntityInput(client, "SetForcedTauntCam");
		TF2Attrib_RemoveAll(client);
		
		int weapon = GetPlayerWeaponSlot(client, 0); 
		if(IsValidEntity(weapon))
		{
			TF2Attrib_RemoveAll(weapon);
		}

		int weapon2 = GetPlayerWeaponSlot(client, 1); 
		if(IsValidEntity(weapon2))
		{
			TF2Attrib_RemoveAll(weapon2);
		}
		
		int weapon3 = GetPlayerWeaponSlot(client, 2); 
		if(IsValidEntity(weapon3))
		{
			TF2Attrib_RemoveAll(weapon3);
		}
		g_bIsBatman[client] = false;

		SetSpell2(client, 1, 0);		
		
		SetEntProp(client, Prop_Send, "m_iHealth", 125, 1);
		TF2_RegeneratePlayer(client);		
	}
}

public void Event_Death(Handle event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int deathflags = GetEventInt(event, "death_flags");
	if (!(deathflags & TF_DEATHFLAG_DEADRINGER))
	{
		if (IsValidClient(client) && g_bIsBatman[client])
		{
			StopSound(client, SNDCHAN_AUTO, SPAWN);
			StopSound(client, SNDCHAN_AUTO, SPAWN);			
			
			EmitSoundToClient(client, DEATH);
			EmitSoundToClient(client, DEATH);
			
			TF2Attrib_RemoveAll(client);		
			
			int weapon = GetPlayerWeaponSlot(client, 0); 
			if(IsValidEntity(weapon))
			{
				TF2Attrib_RemoveAll(weapon);
			}

			int weapon2 = GetPlayerWeaponSlot(client, 1); 
			if(IsValidEntity(weapon2))
			{
				TF2Attrib_RemoveAll(weapon2);
			}
			
			int weapon3 = GetPlayerWeaponSlot(client, 2); 
			if(IsValidEntity(weapon3))
			{
				TF2Attrib_RemoveAll(weapon3);
			}
			
			SetSpell2(client, 1, 0);
					
			g_bIsBatman[client] = false;			
		}
	}
}

public Action SetModel(int client)
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		TF2_RemoveAllWearables(client);
		
		CreateHat(client, 30720, 10, 6, 76); //Arkham Cowl
		CreateHat(client, 30722, 10, 6, 0); //Batters Bracers		
		CreateHat(client, 30738, 10, 6, 0); //Bat Belt
		CreateHat(client, 30727, 10, 6, 0); //Caped Crusader
		CreateHat(client, 30265, 10, 6, 0); //Jupiter Jumpers	
	}
	return Plugin_Handled;
}

public Action Command_Batman(int client, int args)
{
	char arg1[32];
	if (args < 1)
	{
		arg1 = "@me";
	}
	else GetCmdArg(1, arg1, sizeof(arg1));
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
					arg1,
					client,
					target_list,
					MAXPLAYERS,
					COMMAND_FILTER_ALIVE|(args < 1 ? COMMAND_FILTER_NO_IMMUNITY : 0),
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (int i = 0; i < target_count; i++)
	{
		MakeBatman(target_list[i]);
		LogAction(client, target_list[i], "\"%L\" made \"%L\" the Batman!", client, target_list[i]);
		EmitSoundToClient(target_list[i], SPAWN);
		EmitSoundToClient(target_list[i], SPAWN);		
	}

	return Plugin_Handled;
}

Action MakeBatman(int client)
{
	TF2_SetPlayerClass(client, TFClass_Soldier);

	RemoveTFModel(client);

	PrintToChat(client, "You are the Batman");
	PrintToChat(client, "You have a Grappling Hook and 50 Bat Spells");	
	PrintToChat(client, "To change to First Person view type in chat:  !fp");	
	PrintToChat(client, "To change to Third Person view type in chat:  !tp");
	PrintToChat(client, "You will lose your powers when you touch a locker or die.");

	SetModel(client);

	TF2_SetHealth(client, 3000);
	
	SetSpell2(client, 1, 50);

	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	
	TF2_AddCondition(client, TFCond_SpawnOutline, 20.0);	
	
	g_bIsBatman[client] = true;
	
	CreateTimer(0.1, Timer_Switch, client);
	
	return Plugin_Handled;	
}

stock Action TF2_SetHealth(int client, int NewHealth)
{
	SetEntProp(client, Prop_Send, "m_iHealth", NewHealth, 1);
	SetEntProp(client, Prop_Data, "m_iHealth", NewHealth, 1);
	
	return Plugin_Handled;	
}

Action Timer_Switch(Handle timer, any client)
{
	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Soldier)
	{

		TF2_RemoveWeaponSlot(client, 0);
		CreateWeapon(client, "tf_weapon_rocketlauncher", 205, 6, 98, 0, 297);

		TF2_RemoveWeaponSlot(client, 1);
		CreateWeapon(client, "tf_weapon_shotgun_soldier", 199, 6, 97, 1, 232);

		TF2_RemoveWeaponSlot(client, 2);
		CreateWeapon(client, "tf_weapon_shovel", 416, 6, 96, 2, 0);
		
		CreateWeapon(client, "tf_weapon_grapplinghook", 1152, 6, 98, 3, 0);		

		TF2_SwitchtoSlot(client, 0);	

		GiveBatman(client);
	}

	return Plugin_Handled;
}

Action GiveBatman(int client)
{
	TF2Attrib_SetByName(client, "max health additive bonus", 2800.0);
	TF2Attrib_SetByName(client, "health from packs decreased", 0.0); 	
	TF2Attrib_SetByName(client, "major move speed bonus", 2.0);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);			
	TF2Attrib_SetByName(client, "dmg taken from blast reduced", 0.5);
	TF2Attrib_SetByName(client, "dmg taken from fire reduced", 0.5);
	TF2Attrib_SetByName(client, "dmg taken from bullets reduced", 0.5);
	TF2Attrib_SetByName(client, "dmg taken from crit reduced", 0.5);
	TF2Attrib_SetByName(client, "dmg from ranged reduced", 0.5);
	TF2Attrib_SetByName(client, "SET BONUS: dmg from sentry reduced", 0.5);	
	TF2Attrib_SetByName(client, "damage force reduction", 0.5);				
	TF2Attrib_SetByName(client, "increase player capture value", 2.0);
	TF2Attrib_SetByName(client, "major increased jump height", 1.7);
	TF2Attrib_SetByName(client, "cannot be backstabbed", 1.0);
	TF2Attrib_SetByName(client, "increased air control", 25.0);	
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.3);
	TF2Attrib_SetByName(client, "airblast vertical vulnerability multiplier", 0.3);
	TF2Attrib_SetByName(client, "parachute attribute", 1.0);	
	//TF2Attrib_SetByName(client, "mod weapon blocks healing", 1.0);	
	
	int Weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	if(IsValidEntity(Weapon))	
	{
		TF2Attrib_SetByName(Weapon, "fire rate bonus", 0.2);	
		TF2Attrib_SetByName(Weapon, "faster reload rate", 0.2);
		TF2Attrib_SetByName(Weapon, "damage bonus", 5.0);
		TF2Attrib_SetByName(Weapon, "projectile penetration", 1.0);
		TF2Attrib_SetByName(Weapon, "attack projectiles", 1.0);				
		TF2Attrib_SetByName(Weapon, "maxammo primary increased", 5.0);
		TF2Attrib_SetByName(Weapon, "clip size bonus", 5.0);
		TF2Attrib_SetByName(Weapon, "armor piercing", 40.0);
		TF2Attrib_SetByName(Weapon, "ammo regen", 1.0);
		TF2Attrib_SetByName(Weapon, "killstreak tier", 3.0);
		TF2Attrib_SetByName(Weapon, "killstreak effect", 2005.0);
		TF2Attrib_SetByName(Weapon, "killstreak idleeffect", 7.0);
		TF2Attrib_SetByName(Weapon, "blast radius increased", 3.0);
		TF2Attrib_SetByName(Weapon, "Projectile speed increased", 4.0);
		TF2Attrib_SetByName(Weapon, "Projectile range increased", 3.0);	
		TF2Attrib_SetByName(Weapon, "SPELL: Halloween pumpkin explosions", 1.0);
		TF2Attrib_SetByName(Weapon, "no self blast dmg", 2.0);
		TF2Attrib_SetByName(Weapon, "blast radius increased", 2.0);	

		SetEntProp(Weapon, Prop_Send, "m_iClip1", 20);		
	}

	int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if(IsValidEntity(Weapon2))
	{
		TF2Attrib_SetByName(Weapon2, "fire rate bonus", 0.2);	
		TF2Attrib_SetByName(Weapon2, "faster reload rate", 0.2);
		TF2Attrib_SetByName(Weapon2, "damage bonus", 5.0);
		TF2Attrib_SetByName(Weapon2, "projectile penetration", 1.0);
		TF2Attrib_SetByName(Weapon2, "attack projectiles", 1.0);
		TF2Attrib_SetByName(Weapon2, "armor piercing", 40.0);		
		TF2Attrib_SetByName(Weapon2, "maxammo secondary increased", 2.0);
		TF2Attrib_SetByName(Weapon2, "clip size bonus", 5.0);
		TF2Attrib_SetByName(Weapon2, "killstreak tier", 3.0);
		TF2Attrib_SetByName(Weapon2, "killstreak effect", 2005.0);
		TF2Attrib_SetByName(Weapon2, "killstreak idleeffect", 7.0);		
	}
	
	int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	if(IsValidEntity(Weapon3))
	{
		TF2Attrib_SetByName(Weapon3, "melee attack rate bonus", 0.4);	
		TF2Attrib_SetByName(Weapon3, "melee bounds multiplier", 2.0);					
		TF2Attrib_SetByName(Weapon3, "melee range multiplier", 2.0);
		TF2Attrib_SetByName(Weapon3, "damage bonus", 5.0);
		TF2Attrib_SetByName(Weapon3, "armor piercing", 40.0);
		TF2Attrib_SetByName(Weapon3, "speed buff ally", 1.0);
		TF2Attrib_SetByName(Weapon3, "dmg bonus vs buildings", 3.0);
		TF2Attrib_SetByName(Weapon3, "damage applies to sappers", 1.0);
		TF2Attrib_SetByName(Weapon3, "killstreak tier", 3.0);
		TF2Attrib_SetByName(Weapon3, "killstreak effect", 2005.0);
		TF2Attrib_SetByName(Weapon3, "killstreak idleeffect", 7.0);
		TF2Attrib_SetByName(Weapon3, "mod see enemy health", 1.0);		
	}
	
	if(g_bIsRTD2Loaded)
	{
		CreateTimer(10.0, Timer_Homing, client);		
	}
	
	return Plugin_Handled;	
}

public Action Timer_Homing(Handle timer, any client)
{
	if (g_bIsBatman[client])
	{
		RTD2_Force(client, "homingprojectiles", 20);
	}
	
	return Plugin_Handled;
}
		
stock bool IsValidClient(int client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	return IsClientInGame(client);
}

bool CreateHat(int client, int itemindex, int level, int quality, int unusual)
{
	int hat = CreateEntityByName("tf_wearable");
	
	if (!IsValidEntity(hat))
	{
		return false;
	}
	
	char entclass[64];
	GetEntityNetClass(hat, entclass, sizeof(entclass));
	SetEntProp(hat, Prop_Send, "m_iItemDefinitionIndex", itemindex);
	SetEntProp(hat, Prop_Send, "m_bInitialized", 1); 	
	SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), quality);	
	SetEntProp(hat, Prop_Send, "m_bValidatedAttachedEntity", 1); 
	
	if (level !=10)
	{
		SetEntProp(hat, Prop_Send, "m_iEntityLevel", level);
	}
	else
	{
		SetEntProp(hat, Prop_Send, "m_iEntityLevel", GetRandomUInt(1,100));
	}

	if (quality == 6)
	{
		if (GetRandomUInt(1,5) == 1)
		{
			SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), 11);	
			TF2Attrib_SetByDefIndex(hat, 214, view_as<float>(GetRandomUInt(0, 9000)));
		}
	}	

	if (unusual == 1)
	{
		TF2Attrib_SetByName(hat, "particle effect use head origin", 1.0);
		SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), 5);	
		TF2Attrib_SetByDefIndex(hat, 134, GetRandomInt(1,270) + 0.0);
	}

	if (unusual > 1)
	{
		SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), 5);	
		TF2Attrib_SetByDefIndex(hat, 134, unusual + 0.0);
	}
	
	if(itemindex == 1158 || itemindex == 1173)
	{
		TF2Attrib_SetByDefIndex(hat, 134, GetRandomUInt(1,270) + 0.0);
	}

	DispatchSpawn(hat);
	SDKCall(g_hEquipWearable, client, hat);
	return true;
} 

bool CreateWeapon(int client, char[] classname, int itemindex, int quality, int level, int slot, int paint)
{
	TF2_RemoveWeaponSlot(client, slot);

	int weapon = CreateEntityByName(classname);

	if (!IsValidEntity(weapon))
	{
		return false;
	}
	
	quality = 15;
	
	char entclass[64];
	GetEntityNetClass(weapon, entclass, sizeof(entclass));
	SetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex", itemindex);	 
	SetEntProp(weapon, Prop_Send, "m_bInitialized", 1);
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), quality);
	SetEntProp(weapon, Prop_Send, "m_bValidatedAttachedEntity", 1);
	
	if (level)
	{
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	}
	else
	{
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityLevel"), GetRandomUInt(1,99));
	}

	if(paint > 0)
	{
		TF2Attrib_SetByDefIndex(weapon, 834, view_as<float>(paint));	//Set Warpaint
	}
	
	if (GetRandomUInt(1,4) == 1)
	{
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 11);

		TF2Attrib_SetByDefIndex(weapon, 2025, 1.0);

		if (GetRandomUInt(1,5) == 2)
		{
			TF2Attrib_SetByDefIndex(weapon, 2025, 2.0);
			TF2Attrib_SetByDefIndex(weapon, 2014, GetRandomUInt(1,7) + 0.0);
		}
		else if (GetRandomUInt(1,5) == 3)
		{
			TF2Attrib_SetByDefIndex(weapon, 2025, 3.0);
			TF2Attrib_SetByDefIndex(weapon, 2014, GetRandomUInt(1,7) + 0.0);
			TF2Attrib_SetByDefIndex(weapon, 2013, GetRandomUInt(2002,2008) + 0.0);
		}
		TF2Attrib_SetByDefIndex(weapon, 214, view_as<float>(GetRandomUInt(0, 9000)));
	}
	
	//	TF2Attrib_SetByDefIndex(weapon, 725, GetRandomFloat(0.0,1.0));  //Weapon texture wear

	DispatchSpawn(weapon);
	EquipPlayerWeapon(client, weapon); 

	if (itemindex == 13
			|| itemindex == 200
			|| itemindex == 23
			|| itemindex == 209
			|| itemindex == 18
			|| itemindex == 205
			|| itemindex == 10
			|| itemindex == 199
			|| itemindex == 21
			|| itemindex == 208
			|| itemindex == 12
			|| itemindex == 19
			|| itemindex == 206
			|| itemindex == 20
			|| itemindex == 207
			|| itemindex == 15
			|| itemindex == 202
			|| itemindex == 11
			|| itemindex == 9
			|| itemindex == 22
			|| itemindex == 29
			|| itemindex == 211
			|| itemindex == 14
			|| itemindex == 201
			|| itemindex == 16
			|| itemindex == 203
			|| itemindex == 24
			|| itemindex == 194				
			|| itemindex == 210)	
	{
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 5);
		TF2_SwitchtoSlot(client, slot);
		int iRand = GetRandomUInt(1,4);
		if (iRand == 1)
		{
			TF2Attrib_SetByDefIndex(weapon, 134, 701.0);	
		}
		else if (iRand == 2)
		{
			TF2Attrib_SetByDefIndex(weapon, 134, 702.0);	
		}	
		else if (iRand == 3)
		{
			TF2Attrib_SetByDefIndex(weapon, 134, 703.0);	
		}
		else if (iRand == 4)
		{
			TF2Attrib_SetByDefIndex(weapon, 134, 704.0);	
		}
	}

	TF2_SwitchtoSlot(client, 0);
	
	return true;
}

stock void TF2_SwitchtoSlot(int client, int slot)
{
	if (slot >= 0 && slot <= 5 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		char wepclassname[64];
		int wep = GetPlayerWeaponSlot(client, slot);
		if (wep > MaxClients && IsValidEdict(wep) && GetEdictClassname(wep, wepclassname, sizeof(wepclassname)))
		{
			FakeClientCommandEx(client, "use %s", wepclassname);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", wep);
		}
	}
}

int GetRandomUInt(int min, int max)
{
	return RoundToFloor(GetURandomFloat() * (max - min + 1)) + min;
}

stock Action TF2_RemoveAllWearables(int client)
{
	RemoveWearable(client, "tf_wearable", "CTFWearable");
	RemoveWearable(client, "tf_powerup_bottle", "CTFPowerupBottle");
	
	return Plugin_Handled;
}

stock Action RemoveWearable(int client, char[] classname, char[] networkclass)
{
	if (IsPlayerAlive(client))
	{
		int edict = MaxClients+1;
		while((edict = FindEntityByClassname(edict, classname)) != -1)
		{
			char netclass[32];
			if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, networkclass))
			{
				if (GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client)
				{
					AcceptEntityInput(edict, "Kill"); 
				}
			}
		}
	}
	return Plugin_Handled;
}

int SetSpell2(int client, int spell, int uses)
{
	int ent = GetSpellBook(client);
	if(!IsValidEntity(ent)) return -1;
	SetEntProp(ent, Prop_Send, "m_iSelectedSpellIndex", spell);
	SetEntProp(ent, Prop_Send, "m_iSpellCharges", uses);
	return 1;
}  

int GetSpellBook(int client)
{
	int entity = -1;
	while((entity = FindEntityByClassname(entity, "tf_weapon_spellbook")) != INVALID_ENT_REFERENCE)
	{
		if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client) return entity;
	}
	return -1;
}

Action RemoveTFModel(int client)
{
	TF2_RemoveAllWearables(client);	
	SetVariantString("");
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_bCustomModelRotates", 0);
	SetVariantString("ParticleEffectStop");
	AcceptEntityInput(client, "DispatchEffect");

	return Plugin_Handled;
}