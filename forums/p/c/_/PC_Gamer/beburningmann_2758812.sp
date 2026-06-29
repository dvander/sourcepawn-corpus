#pragma semicolon 1
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2attributes>

#define PLUGIN_VERSION "1.1"

#define SPAWN	"/vo/pyro_laughlong01.mp3"
#define SPAWN2	"/ambient_mp3/lair/rolling_thunder1.mp3"
#define DEATH	"/misc/taps_02.wav"

public Plugin:myinfo =
{
	name = "[TF2] Be the Burning Mann",
	author = "PC Gamer",
	description = "Play as the Burning Mann",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

bool g_bIsBurningMann[MAXPLAYERS + 1];
int g_iBody[MAXPLAYERS+1] = {-1, ... };

new g_iFlamethrower[MAXPLAYERS+1] = {-1, ... };
new g_iFlamethrowerTrash[MAXPLAYERS+1] = {-1, ... };

Handle g_hEquipWearable;

public OnPluginStart()
{
	LoadTranslations("common.phrases");

	RegAdminCmd("sm_beburningman", Command_BeBurningMann, ADMFLAG_SLAY, "Become the Burning Mann");
	RegAdminCmd("sm_beburningmann", Command_BeBurningMann, ADMFLAG_SLAY, "Become the Burning Mann");
	RegAdminCmd("sm_burningman", Command_BeBurningMann, ADMFLAG_SLAY, "Become the Burning Mann");
	RegAdminCmd("sm_burningmann", Command_BeBurningMann, ADMFLAG_SLAY, "Become the Burning Mann");	
	
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
	
	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i))
	{
		SDKHook(i, SDKHook_Touch, SpreadFire);
	}	
}

public OnClientPutInServer(client)
{
	OnClientDisconnect_Post(client);
	
	SDKHook(client, SDKHook_Touch, SpreadFire);
	SDKHook(client, SDKHook_PreThink, OnPreThink);
}

public OnClientDisconnect_Post(client)
{
	if (g_bIsBurningMann[client])
	{
		StopSound(client, SNDCHAN_AUTO, SPAWN);
		StopSound(client, SNDCHAN_AUTO, SPAWN);
		StopSound(client, SNDCHAN_AUTO, SPAWN2);
		StopSound(client, SNDCHAN_AUTO, SPAWN2);			
		g_bIsBurningMann[client] = false;
	}
}

public OnMapStart()
{
	PrecacheSound(SPAWN);
	PrecacheSound(SPAWN2);
	PrecacheSound(DEATH);
}

public EventInventoryApplication(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_bIsBurningMann[client])
	{
		SetEntProp(client, Prop_Send, "m_iHealth", 125, 1);
		RemoveModel(client);
		
		StopSound(client, SNDCHAN_AUTO, SPAWN);
		StopSound(client, SNDCHAN_AUTO, SPAWN);
		StopSound(client, SNDCHAN_AUTO, SPAWN2);
		StopSound(client, SNDCHAN_AUTO, SPAWN2);			
		
		SetVariantInt(0);
		AcceptEntityInput(client, "SetForcedTauntCam");
		TF2Attrib_RemoveAll(client);
		
		TF2Attrib_RemoveAll(client);		
		
		new weapon = GetPlayerWeaponSlot(client, 0); 
		if(IsValidEntity(weapon))
		{
			TF2Attrib_RemoveAll(weapon);
		}

		new weapon2 = GetPlayerWeaponSlot(client, 1); 
		if(IsValidEntity(weapon2))
		{
			TF2Attrib_RemoveAll(weapon2);
		}
		
		new weapon3 = GetPlayerWeaponSlot(client, 2); 
		if(IsValidEntity(weapon3))
		{
			TF2Attrib_RemoveAll(weapon3);
		}
		g_bIsBurningMann[client] = false;

		SetEntProp(client, Prop_Send, "m_iHealth", 125, 1);
		TF2_RegeneratePlayer(client);		
	}
}

public Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new deathflags = GetEventInt(event, "death_flags");
	if (!(deathflags & TF_DEATHFLAG_DEADRINGER))
	{
		if (IsValidClient(client) && g_bIsBurningMann[client])
		{
			RemoveModel(client);
			
			StopSound(client, SNDCHAN_AUTO, SPAWN);
			StopSound(client, SNDCHAN_AUTO, SPAWN);	
			StopSound(client, SNDCHAN_AUTO, SPAWN2);
			StopSound(client, SNDCHAN_AUTO, SPAWN2);				
			
			EmitSoundToClient(client, DEATH);			
			EmitSoundToClient(client, DEATH);
			
			TF2Attrib_RemoveAll(client);		
			
			new weapon = GetPlayerWeaponSlot(client, 0); 
			if(IsValidEntity(weapon))
			{
				TF2Attrib_RemoveAll(weapon);
			}

			new weapon2 = GetPlayerWeaponSlot(client, 1); 
			if(IsValidEntity(weapon2))
			{
				TF2Attrib_RemoveAll(weapon2);
			}
			
			new weapon3 = GetPlayerWeaponSlot(client, 2); 
			if(IsValidEntity(weapon3))
			{
				TF2Attrib_RemoveAll(weapon3);
			}
			g_bIsBurningMann[client] = false;

			ResetClient(client);			
		}
	}
}

public Action:SetModel(client)
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		CreateHat(client, 30203, 10, 6); //Burnys Boney Bonnet
		CreateHat(client, 550, 10, 6); //Fallen Angel		
		CreateHat(client, 551, 10, 6); //Tail from the Crypt
		CreateHat(client, 30303, 10, 6); //Abhorrent Appendates
		CreateHat(client, 632, 10, 6); //Cremators Conscience	
	}
}

public Action:RemoveModel(client)
{
	if (IsValidClient(client))
	{
		TF2_RemoveAllWearables(client);
	}
}

public Action:Command_BeBurningMann(client, args)
{
	decl String:arg1[32];
	if (args < 1)
	{
		arg1 = "@me";
	}
	else GetCmdArg(1, arg1, sizeof(arg1));
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;

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
	for (new i = 0; i < target_count; i++)
	{
		LogAction(client, target_list[i], "\"%L\" made \"%L\" the BurningMann!", client, target_list[i]);
		EmitSoundToClient(target_list[i], SPAWN);
		EmitSoundToClient(target_list[i], SPAWN);
		EmitSoundToClient(target_list[i], SPAWN2);
		EmitSoundToClient(target_list[i], SPAWN2);		
		Makegiantpyro(target_list[i]);		
	}

	return Plugin_Handled;
}

Makegiantpyro(client)
{
	TF2_SetPlayerClass(client, TFClass_Pyro);
	TF2_RemoveAllWearables(client);
	TF2_RegeneratePlayer(client);

	ServerCommand("tf_models_remove #%d", GetClientUserId(client));	

	PrintToChat(client, "You are The BurningMann");
	PrintToChat(client, "To change to First Person view type in chat:  !fp");	
	PrintToChat(client, "To change to Third Person view type in chat:  !tp");
	PrintToChat(client, "You will lose your powers when you touch a locker or die.");

	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll > MaxClients && IsValidEntity(ragdoll)) AcceptEntityInput(ragdoll, "Kill");
	decl String:weaponname[32];
	GetClientWeapon(client, weaponname, sizeof(weaponname));
	if (strcmp(weaponname, "tf_weapon_", false) == 0)
	{
		SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iWeaponState", 0);
		TF2_RemoveCondition(client, TFCond_Slowed);
	}

	TF2_RemoveAllWearables(client);
	
	CreateTimer(0.1, Timer_Switch, client);

	SetModel(client);

	SDKHook(client, SDKHook_PreThink, OnPreThink);

	TF2_SetHealth(client, 3000);

	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	g_bIsBurningMann[client] = true;
}

stock TF2_SetHealth(client, NewHealth)
{
	SetEntProp(client, Prop_Send, "m_iHealth", NewHealth, 1);
	SetEntProp(client, Prop_Data, "m_iHealth", NewHealth, 1);
}

public Action:Timer_Switch(Handle:timer, any:client)
{
	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Pyro)
	{
		TF2_RemoveWeaponSlot(client, 0);
		CreateWeapon(client, "tf_weapon_flamethrower", 208, 9, 98, 0, 0);

		TF2_RemoveWeaponSlot(client, 1);
		//CreateWeapon(client, "tf_weapon_shotgun_pyro", 199, 6, 97, 1, 390);
		CreateWeapon(client, "tf_weapon_flaregun", 740, 6, 97, 1, 280);		
		
		TF2_RemoveWeaponSlot(client, 2);
		CreateWeapon(client, "tf_weapon_fireaxe", 348, 6, 99, 2, 0);  //Sharpened Volcano Fragment
	}

	TF2_SwitchtoSlot(client, 0);	

	Givegiantpyro(client);
}

stock Givegiantpyro(client)
{
	TF2Attrib_SetByName(client, "max health additive bonus", 2875.0);
	TF2Attrib_SetByName(client, "health from packs decreased", 0.0); 	
	TF2Attrib_SetByName(client, "major move speed bonus", 1.5);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);			
	TF2Attrib_SetByName(client, "dmg taken from blast reduced", 0.5);
	TF2Attrib_SetByName(client, "dmg taken from fire reduced", 0.5);
	TF2Attrib_SetByName(client, "dmg taken from bullets reduced", 0.5);
	TF2Attrib_SetByName(client, "dmg taken from crit reduced", 0.5);
	TF2Attrib_SetByName(client, "dmg from ranged reduced", 0.5);
	TF2Attrib_SetByName(client, "SET BONUS: dmg from sentry reduced", 0.5);	
	TF2Attrib_SetByName(client, "damage force reduction", 0.5);				
	TF2Attrib_SetByName(client, "increase player capture value", 2.0);
	TF2Attrib_SetByName(client, "major increased jump height", 1.5);
	TF2Attrib_SetByName(client, "cannot be backstabbed", 1.0);
	TF2Attrib_SetByName(client, "increased air control", 25.0);	
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.3);
	TF2Attrib_SetByName(client, "airblast vertical vulnerability multiplier", 0.3);
	TF2Attrib_SetByName(client, "attach particle effect", 1.0);
	TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 13595446.0);	
	
	new Weapon = GetPlayerWeaponSlot(client, 0);
	if(IsValidEntity(Weapon))	
	{
		TF2Attrib_SetByName(Weapon, "damage bonus", 7.0);
		TF2Attrib_SetByName(Weapon, "maxammo primary increased", 2.5);
		TF2Attrib_SetByName(Weapon, "armor piercing", 40.0);
		TF2Attrib_SetByName(Weapon, "ammo regen", 0.2);
		TF2Attrib_SetByName(Weapon, "damage causes airblast", 5.0);
		TF2Attrib_SetByName(Weapon, "airblast pushback scale", 2.0);
		TF2Attrib_SetByName(Weapon, "flame_speed", 3000.0);
		TF2Attrib_SetByName(Weapon, "flame_spread_degree", 2.0);
		TF2Attrib_SetByName(Weapon, "flame_gravity", 0.0);
		TF2Attrib_SetByName(Weapon, "flame ammopersec decreased", 0.3);
		TF2Attrib_SetByName(Weapon, "mod flamethrower back crit", 1.0);				
		TF2Attrib_SetByName(Weapon, "dmg bonus vs buildings", 3.0);
		TF2Attrib_SetByName(Weapon, "damage applies to sappers", 1.0);
		TF2Attrib_SetByName(Weapon, "reveal disguised victim on hit", 1.0);
		TF2Attrib_SetByName(Weapon, "SPELL: Halloween green flames", 1.0);
		TF2Attrib_SetByName(Weapon, "attach particle effect", 1.0);		
	}

	int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if(IsValidEntity(Weapon2))
	{
		TF2Attrib_SetByName(Weapon2, "fire rate bonus", 0.4);	
		TF2Attrib_SetByName(Weapon2, "faster reload rate", 0.2);
		TF2Attrib_SetByName(Weapon2, "damage bonus", 5.0);
		TF2Attrib_SetByName(Weapon2, "projectile penetration", 1.0);
		TF2Attrib_SetByName(Weapon2, "attack projectiles", 1.0);				
		TF2Attrib_SetByName(Weapon2, "maxammo secondary increased", 2.0);
		TF2Attrib_SetByName(Weapon2, "clip size bonus", 5.0);
		TF2Attrib_SetByName(Weapon2, "ammo regen", 0.2);		
		TF2Attrib_SetByName(Weapon2, "no self blast dmg", 2.0);
		TF2Attrib_SetByName(Weapon2, "dmg bonus vs buildings", 3.0);		
		TF2Attrib_SetByName(Weapon2, "Blast radius increased", 5.0);		
		TF2Attrib_SetByName(Weapon2, "attach particle effect", 1.0);		
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
		TF2Attrib_SetByName(Weapon3, "attach particle effect", 1.0);		
	}
	TF2_AddCondition(client, TFCond_RadiusHealOnDamage, 5.0);	
}

public Native_Setgiantspy(Handle:plugin, args)
Makegiantpyro(GetNativeCell(1));

public Native_Isgiantspy(Handle:plugin, args)
return g_bIsBurningMann[GetNativeCell(1)];

stock bool:IsValidClient(client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	return IsClientInGame(client);
}

stock bool:IsValidWeapon(weapon)
{
	if (!IsValidEntity(weapon))
	return false;
	
	decl String:class[64];
	GetEdictClassname(weapon, class, sizeof(class));
	
	if (strncmp(class, "tf_weapon_", 10) == 0 || strncmp(class, "tf_wearable_demoshield", 22) == 0)
	return true;
	
	return false;
}

bool CreateHat(int client, int itemindex, int level, int quality)
{
	int hat = CreateEntityByName("tf_wearable");
	
	if (!IsValidEntity(hat))
	{
		return false;
	}
	
	char entclass[64];
	GetEntityNetClass(hat, entclass, sizeof(entclass));
	SetEntData(hat, FindSendPropInfo(entclass, "m_iItemDefinitionIndex"), itemindex);
	SetEntData(hat, FindSendPropInfo(entclass, "m_bInitialized"), 1); 	
	SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), quality);
	SetEntProp(hat, Prop_Send, "m_bValidatedAttachedEntity", 1);

	if (level)
	{
		SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	}
	else
	{
		SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityLevel"), GetRandomInt(1,100));
	}

	if(itemindex == 632)
	{
		SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), 5);
		TF2Attrib_SetByDefIndex(hat, 134, 1.0);
	}

	if(itemindex == 550 || itemindex == 551)
	{
		SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), 5);
		TF2Attrib_SetByDefIndex(hat, 134, 1.0);	
	}
	
	if(itemindex == 30203 || itemindex == 30303)
	{
		SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), 5);
		TF2Attrib_SetByDefIndex(hat, 134, 1.0);	
	}

	DispatchSpawn(hat);
	SDKCall(g_hEquipWearable, client, hat);
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

bool CreateWeapon(int client, char[] classname, int itemindex, int quality, int level, int slot, int paint)
{
	TF2_RemoveWeaponSlot(client, slot);

	int weapon = CreateEntityByName(classname);

	if (!IsValidEntity(weapon))
	{
		return false;
	}
	
	char entclass[64];
	GetEntityNetClass(weapon, entclass, sizeof(entclass));
	SetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex", itemindex);	 
	SetEntProp(weapon, Prop_Send, "m_bInitialized", 1);
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), quality);
	SetEntProp(weapon, Prop_Send, "m_bValidatedAttachedEntity", 1);
	
	if (level > 0)
	{
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	}
	else
	{
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityLevel"), GetRandomUInt(1,99));
	}

	if (paint > 0)
	{
		TF2Attrib_SetByDefIndex(weapon, 834, view_as<float>(paint));	//Set Warpaint
	}
	
	switch (itemindex)
	{
	case 810, 736, 933, 1080, 1102:
		{
			SetEntData(weapon, FindSendPropInfo(entclass, "m_iObjectType"), 3);
		}
	case 998:
		{
			SetEntData(weapon, FindSendPropInfo(entclass, "m_nChargeResistType"), GetRandomInt(0,2));
		}
	case 1071:
		{
			TF2Attrib_SetByName(weapon, "item style override", 0.0);
			TF2Attrib_SetByName(weapon, "loot rarity", 1.0);		
			TF2Attrib_SetByName(weapon, "turn to gold", 1.0);

			DispatchSpawn(weapon);
			EquipPlayerWeapon(client, weapon);
			
			return true; 
		}		
	}

	if(quality == 9) //self made quality
	{
		TF2Attrib_SetByName(weapon, "is australium item", 1.0);
		TF2Attrib_SetByName(weapon, "item style override", 1.0);
	}

	if(itemindex == 200 || itemindex == 220 || itemindex == 448 || itemindex == 15002 || itemindex == 15015 || itemindex == 15021 || itemindex == 15029 || itemindex == 15036 || itemindex == 15053 || itemindex == 15065 || itemindex == 15069 || itemindex == 15106 || itemindex == 15107 || itemindex == 15108 || itemindex == 15131 || itemindex == 15151 || itemindex == 15157 || itemindex == 449 || itemindex == 15013 || itemindex == 15018 || itemindex == 15035 || itemindex == 15041 || itemindex == 15046 || itemindex == 15056 || itemindex == 15060 || itemindex == 15061 || itemindex == 15100 || itemindex == 15101
			|| itemindex == 15102 || itemindex == 15126 || itemindex == 15148 || itemindex == 44 || itemindex == 221 || itemindex == 205 || itemindex == 228 || itemindex == 1104 || itemindex == 15006 || itemindex == 15014 || itemindex == 15028 || itemindex == 15043 || itemindex == 15052 || itemindex == 15057 || itemindex == 15081 || itemindex == 15104 || itemindex == 15105 || itemindex == 15129 || itemindex == 15130 || itemindex == 15150 || itemindex == 196 || itemindex == 447 || itemindex == 208 || itemindex == 215 || itemindex == 1178 || itemindex == 15005 || itemindex == 15017 || itemindex == 15030 || itemindex == 15034
			|| itemindex == 15049 || itemindex == 15054 || itemindex == 15066 || itemindex == 15067 || itemindex == 15068 || itemindex == 15089 || itemindex == 15090 || itemindex == 15115 || itemindex == 15141 || itemindex == 351 || itemindex == 740 || itemindex == 192 || itemindex == 214 || itemindex == 326 || itemindex == 206 || itemindex == 308 || itemindex == 996 || itemindex == 1151 || itemindex == 15077 || itemindex == 15079 || itemindex == 15091 || itemindex == 15092 || itemindex == 15116 || itemindex == 15117 || itemindex == 15142 || itemindex == 15158 || itemindex == 207 || itemindex == 130 || itemindex == 15009
			|| itemindex == 15012 || itemindex == 15024 || itemindex == 15038 || itemindex == 15045 || itemindex == 15048 || itemindex == 15082 || itemindex == 15083 || itemindex == 15084 || itemindex == 15113 || itemindex == 15137 || itemindex == 15138 || itemindex == 15155 || itemindex == 172 || itemindex == 327 || itemindex == 404 || itemindex == 202 || itemindex == 41 || itemindex == 312 || itemindex == 424 || itemindex == 15004 || itemindex == 15020 || itemindex == 15026 || itemindex == 15031 || itemindex == 15040 || itemindex == 15055 || itemindex == 15086 || itemindex == 15087 || itemindex == 15088 || itemindex == 15098
			|| itemindex == 15099 || itemindex == 15123 || itemindex == 15124 || itemindex == 15125 || itemindex == 15147 || itemindex == 425 || itemindex == 997 || itemindex == 197 || itemindex == 329 || itemindex == 15073 || itemindex == 15074 || itemindex == 15075 || itemindex == 15139 || itemindex == 15140 || itemindex == 15114 || itemindex == 15156 || itemindex == 305 || itemindex == 211 || itemindex == 15008 || itemindex == 15010 || itemindex == 15025 || itemindex == 15039 || itemindex == 15050 || itemindex == 15078 || itemindex == 15097 || itemindex == 15121 || itemindex == 15122 || itemindex == 15123 || itemindex == 15145
			|| itemindex == 15146 || itemindex == 35 || itemindex == 411 || itemindex == 37 || itemindex == 304 || itemindex == 201 || itemindex == 402 || itemindex == 15000 || itemindex == 15007 || itemindex == 15019 || itemindex == 15023 || itemindex == 15033 || itemindex == 15059 || itemindex == 15070 || itemindex == 15071 || itemindex == 15072 || itemindex == 15111 || itemindex == 15112 || itemindex == 15135 || itemindex == 15136 || itemindex == 15154 || itemindex == 203 || itemindex == 15001 || itemindex == 15022 || itemindex == 15032 || itemindex == 15037 || itemindex == 15058 || itemindex == 15076 || itemindex == 15110
			|| itemindex == 15134 || itemindex == 15153 || itemindex == 193 || itemindex == 401 || itemindex == 210 || itemindex == 15011 || itemindex == 15027 || itemindex == 15042 || itemindex == 15051 || itemindex == 15062 || itemindex == 15063 || itemindex == 15064 || itemindex == 15103 || itemindex == 15128 || itemindex == 15129 || itemindex == 15149 || itemindex == 194 || itemindex == 649 || itemindex == 15062 || itemindex == 15094 || itemindex == 15095 || itemindex == 15096 || itemindex == 15118 || itemindex == 15119 || itemindex == 15143 || itemindex == 15144 || itemindex == 209 || itemindex == 15013 || itemindex == 15018
			|| itemindex == 15035 || itemindex == 15041 || itemindex == 15046 || itemindex == 15056 || itemindex == 15060 || itemindex == 15061 || itemindex == 15100 || itemindex == 15101 || itemindex == 15102 || itemindex == 15126 || itemindex == 15148 || itemindex == 415 || itemindex == 15003 || itemindex == 15016 || itemindex == 15044 || itemindex == 15047 || itemindex == 15085 || itemindex == 15109 || itemindex == 15132 || itemindex == 15133 || itemindex == 15152 || itemindex == 1153)
	{
		if(GetRandomInt(1,30) == 1) //not used quality level
		{
			TF2Attrib_SetByDefIndex(weapon, 2053, 1.0);
		}
	}
	
	if(quality == 11 || quality == 9) //strange quality
	{
		if (GetRandomInt(1,10) == 1)
		{
			TF2Attrib_SetByDefIndex(weapon, 2025, 1.0);
		}
		else if (GetRandomInt(1,10) == 2)
		{
			TF2Attrib_SetByDefIndex(weapon, 2025, 2.0);
			TF2Attrib_SetByDefIndex(weapon, 2014, GetRandomInt(1,7) + 0.0);
		}
		else if (GetRandomInt(1,10) == 3)
		{
			TF2Attrib_SetByDefIndex(weapon, 2025, 3.0);
			TF2Attrib_SetByDefIndex(weapon, 2014, GetRandomInt(1,7) + 0.0);
			TF2Attrib_SetByDefIndex(weapon, 2013, GetRandomInt(2002,2008) + 0.0);
		}
		TF2Attrib_SetByDefIndex(weapon, 214, view_as<float>(GetRandomInt(0, 9000)));
	}
	
	if (quality == 15)
	{
		switch(itemindex)
		{
		case 30666, 30667, 30668, 30665:
			{
				TF2Attrib_RemoveByDefIndex(weapon, 725);
			}
		default:
			{
				TF2Attrib_SetByDefIndex(weapon, 725, GetRandomFloat(0.0,1.0));
			}
		}
	}
	
	//	TF2Attrib_SetByDefIndex(weapon, 725, GetRandomFloat(0.0,1.0));  //Weapon texture wear

	if (itemindex == 405 || itemindex == 608 || itemindex == 1101 || itemindex == 133 || itemindex == 444 || itemindex == 57 || itemindex == 231 || itemindex == 642 || itemindex == 131 || itemindex == 406 || itemindex == 1099 || itemindex == 1144)
	{
		DispatchSpawn(weapon);
		SDKCall(g_hEquipWearable, client, weapon);
	}

	else
	{
		DispatchSpawn(weapon);
		EquipPlayerWeapon(client, weapon);
	}
	
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

public OnGameFrame()
{
	for(new iClient = 1; iClient <= MaxClients; iClient++)
	if(IsClientInGame(iClient) && IsPlayerAlive(iClient) && (g_bIsBurningMann[iClient]))
	{
		if(g_iBody[iClient] == -1)
		{
			new iLightEntity = CreateLightEntity(iClient);
			if(iLightEntity > 0)
			g_iBody[iClient] = EntIndexToEntRef(iLightEntity);
		}
	}
	else
	{
		if(g_iBody[iClient] != -1)
		{
			new iLightEntity = EntRefToEntIndex(g_iBody[iClient]);
			if(iLightEntity > 0)
			RemoveEdict(iLightEntity);
			g_iBody[iClient] = -1;
		}
	}
}

stock _:CreateLightEntity(iEntity, bool:bRagdoll=false)
{
	if (!IsValidEdict(iEntity))
	return -1;
	
	new iLightEntity = CreateEntityByName("light_dynamic");
	if (IsValidEntity(iLightEntity))
	{
		DispatchKeyValue(iLightEntity, "inner_cone", "0");
		DispatchKeyValue(iLightEntity, "cone", "80");
		DispatchKeyValue(iLightEntity, "brightness", "6");
		DispatchKeyValueFloat(iLightEntity, "spotlight_radius", 132.0);
		DispatchKeyValueFloat(iLightEntity, "distance", 225.0);
		DispatchKeyValue(iLightEntity, "_light", "255 100 10 41");
		DispatchKeyValue(iLightEntity, "pitch", "-90");
		DispatchKeyValue(iLightEntity, "style", "5");
		DispatchSpawn(iLightEntity);
		
		decl Float:fOrigin[3];
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fOrigin);
		
		fOrigin[2] += 40.0;
		TeleportEntity(iLightEntity, fOrigin, NULL_VECTOR, NULL_VECTOR);

		decl String:strName[32];
		Format(strName, sizeof(strName), "target%i", iEntity);
		DispatchKeyValue(iEntity, "targetname", strName);
		
		DispatchKeyValue(iLightEntity, "parentname", strName);
		SetVariantString("!activator");
		AcceptEntityInput(iLightEntity, "SetParent", iEntity, iLightEntity, 0);
		AcceptEntityInput(iLightEntity, "TurnOn");
	}
	return iLightEntity;
}

public SpreadFire(client, target)
{
	if (g_bIsBurningMann[client] && client <= MaxClients && client >= 1 && target <= MaxClients && target >= 1)
	{
		TF2_IgnitePlayer(target, client);
	}
}

public OnPreThink(iClient) {
	if (!g_bIsBurningMann[iClient]) return;

	new iEntity;
	decl String:strWeapon[52];
	GetClientWeapon(iClient, strWeapon, sizeof(strWeapon));
	new Float:fStrength = GetFlamethrowerStrength(iClient);
	if (fStrength > 0.0) {
		// If no light is present, let's spawn it
		if (g_iFlamethrower[iClient] == -1) {
			iEntity = CreateLightEntity2(iClient);
			if (IsLightEntity(iEntity)) {
				KillFlamethrowerTrash(iClient);
				g_iFlamethrower[iClient] = iEntity;
			}
		}

		// If the light is already there, let's increase its strength
		iEntity = g_iFlamethrower[iClient];
		if (IsLightEntity(iEntity)) {
			AdjustLight(iClient, iEntity);
		}
	}
	else {
		// if there is a light, let's trash it
		if (g_iFlamethrower[iClient] != -1) {
			iEntity = g_iFlamethrower[iClient];
			if (IsLightEntity(iEntity)) {
				// If there's already trash, kill the trash
				KillFlamethrowerTrash(iClient);
				g_iFlamethrowerTrash[iClient] = iEntity;
			}
			g_iFlamethrower[iClient] = -1;
		}

		// decrease the trash's strength
		iEntity = g_iFlamethrowerTrash[iClient];
		if (IsLightEntity(iEntity)) {
			if (fStrength <= 0.0) {
				KillFlamethrowerTrash(iClient);
			} else {
				AdjustLight(iClient, iEntity);
			}
		}
	}
}

ResetClient(iClient) {
	new iLight;

	iLight = g_iFlamethrower[iClient];
	if (IsLightEntity(iLight)) RemoveEdict(iLight);

	KillFlamethrowerTrash(iClient);

	g_iFlamethrower[iClient] = -1;
}

CreateLightEntity2(iClient) {
	if (!IsValidClient(iClient)) return -1;
	if (!IsPlayerAlive(iClient)) return -1;
	new iEntity = CreateEntityByName("light_dynamic");
	if (IsValidEntity(iEntity)) {
		DispatchKeyValue(iEntity, "inner_cone", "0");
		DispatchKeyValue(iEntity, "cone", "80");
		DispatchKeyValue(iEntity, "brightness", "0");
		DispatchKeyValueFloat(iEntity, "spotlight_radius", 240.0);
		DispatchKeyValueFloat(iEntity, "distance", 250.0);
		DispatchKeyValue(iEntity, "_light", "255 100 10 255");
		DispatchKeyValue(iEntity, "pitch", "-90");
		DispatchKeyValue(iEntity, "style", "5");
		DispatchSpawn(iEntity);

		decl Float:fPos[3];
		decl Float:fAngle[3];
		decl Float:fAngle2[3];
		decl Float:fForward[3];
		decl Float:fOrigin[3];
		GetClientEyePosition(iClient, fPos);
		GetClientEyeAngles(iClient, fAngle);
		GetClientEyeAngles(iClient, fAngle2);

		fAngle2[0] = 0.0;
		fAngle2[2] = 0.0;
		GetAngleVectors(fAngle2, fForward, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(fForward, 100.0);
		fForward[2] = 0.0;
		AddVectors(fPos, fForward, fOrigin);

		fAngle[0] += 90.0;
		fOrigin[2] -= 100.0;
		TeleportEntity(iEntity, fOrigin, fAngle, NULL_VECTOR);

		decl String:strName[32];
		Format(strName, sizeof(strName), "target%i", iClient);
		DispatchKeyValue(iClient, "targetname", strName);

		DispatchKeyValue(iEntity, "parentname", strName);
		SetVariantString("!activator");
		AcceptEntityInput(iEntity, "SetParent", iClient, iEntity, 0);
		SetVariantString("head");
		AcceptEntityInput(iEntity, "SetParentAttachmentMaintainOffset", iClient, iEntity, 0);
		AcceptEntityInput(iEntity, "TurnOn");
	}
	return iEntity;
}

stock bool:IsLightEntity(iEntity) {
	if (iEntity > 0) {
		if (IsValidEdict(iEntity)) {
			decl String:strClassname[32];
			GetEdictClassname(iEntity, strClassname, sizeof(strClassname));
			if (StrEqual(strClassname, "light_dynamic", false)) return true;
		}
	}
	return false;
}

stock bool:IsFlamethrower(iEntity) {
	if (iEntity > 0) {
		if (IsValidEdict(iEntity)) {
			decl String:strClassname[32];
			GetEdictClassname(iEntity, strClassname, sizeof(strClassname));
			if (StrEqual(strClassname, "tf_weapon_flamethrower", false)) return true;
		}
	}
	return false;
}

KillFlamethrowerTrash(iClient) {
	if (g_iFlamethrowerTrash[iClient] != -1) {
		new iEntity = g_iFlamethrowerTrash[iClient];
		if (IsLightEntity(iEntity)) RemoveEdict(iEntity);
		g_iFlamethrowerTrash[iClient] = -1;
	}
}

AdjustLight(iClient, iEntity) {
	new Float:fValue;
	new iValue;
	fValue = (GetFlamethrowerStrength(iClient) * 5.0);
	iValue = RoundFloat(fValue);
	SetVariantInt(iValue);
	AcceptEntityInput(iEntity, "Brightness");
}

Float:GetFlamethrowerStrength(iClient) {
	if (!IsValidClient(iClient)) return 0.0;
	if (!IsPlayerAlive(iClient)) return 0.0;
	new iEntity = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
	if (IsFlamethrower(iEntity)) {
		new iWeaponState = GetEntProp(iEntity, Prop_Send, "m_iWeaponState");
		if(iWeaponState == 1) {
			return 0.5;
		} else if(iWeaponState > 1) {
			return 1.0;
		}
	}
	return 0.0;
}