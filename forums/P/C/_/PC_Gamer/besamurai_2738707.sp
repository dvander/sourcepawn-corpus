#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>

#pragma newdecls required

#define PLUGIN_VERSION "1.1"

#define SND_SPAWN		"/items/samurai/tf_conch.wav"
#define SND_SAMURAI1	"/items/samurai/tf_samurai_noisemaker_seta_01.wav"
#define SND_SAMURAI2	"/items/samurai/tf_samurai_noisemaker_seta_03.wav"
#define SND_SAMURAI3	"/items/samurai/tf_samurai_noisemaker_seta_02.wav"
#define SND_DEATH		"/items/samurai/tf_samurai_noisemaker_setb_02.wav"

public Plugin myinfo = 
{
	name = "[TF2] Become the Mighty Samurai",
	author = "PC Gamer, using code from Pelipoika, FlaminSarge, Jaster, luki1412, manicogaming, and StrikeR14",
	description = "Become the Mighty Samurai",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

Handle g_hEquipWearable;
bool g_SplendidScreen[MAXPLAYERS+1] = false;

public void OnPluginStart()
{
	LoadTranslations("common.phrases.txt");
	RegAdminCmd("sm_besamurai", Command_preshield, ADMFLAG_SLAY, "Make player a Samurai");
	RegAdminCmd("sm_besam", Command_preshield, ADMFLAG_SLAY, "Make player a Samurai");	
	HookEvent("post_inventory_application", player_inv);
	HookEvent("player_death", player_inv, EventHookMode_Post);	

	GameData hTF2 = new GameData("sm-tf2.games"); // sourcemod's tf2 gamdata

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

public void OnMapStart()
{
	PrecacheSound(SND_SPAWN);
	PrecacheSound(SND_SAMURAI1);
	PrecacheSound(SND_SAMURAI2);
	PrecacheSound(SND_SAMURAI3);		
	PrecacheSound(SND_DEATH);
}

Action Command_preshield(int client, int args)
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
		GiveSamurai(target_list[i]);
		PrintToChat(target_list[i], "You are a powerful Samurai Warrior!");
		PrintToChat(target_list[i], "You will lose this status when you touch a locker or die.");			
	}
	return Plugin_Handled;
}

Action GiveSamurai(int client)
{
	if (IsValidClient(client))
	{
		TF2Attrib_RemoveAll(client);	

		TF2_SetPlayerClass(client, TFClass_DemoMan);
		TF2_RegeneratePlayer(client);

		TF2_SetHealth(client, 5000);

		g_SplendidScreen[client] = true;
		
		TF2_RemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);		
		CreateWeapon(client, "tf_wearable_demoshield", 406, 6, 99, 2, 0); //Splendid Screen
		TF2_RemoveWeaponSlot(client, 2);
		CreateWeapon(client, "tf_weapon_katana", 357, 6, 99, 2, 0);
		
		CreateHat(client, 359, 10, 6); //Samur Eye
		CreateHat(client, 875, 10, 6); //Menpo		
		CreateHat(client, 30348, 10, 6); //Bushi Dou
		CreateHat(client, 30366, 10, 6); //Sangu Sleeves
		CreateHat(client, 30742, 10, 6); //Shin Shredders	
		
		int iEntity = -1;
		while ((iEntity = FindEntityByClassname(iEntity, "tf_wearable_demoshield")) != -1)
		{
			if (client == GetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity"))
			{
				TF2Attrib_SetByName(iEntity, "charge time increased", 5.0);
				TF2Attrib_SetByName(iEntity, "charge recharge rate increased", 4.0);
				TF2Attrib_SetByName(iEntity, "charge impact damage increased", 20.0);	
				TF2Attrib_SetByName(iEntity, "mult charge turn control", 20.0);
				TF2Attrib_SetByName(iEntity, "move speed penalty", 1.5);
				TF2Attrib_SetByName(iEntity, "major increased jump height", 1.5);
				TF2Attrib_SetByName(iEntity, "attach particle effect", 13.0);				
				break;
			}
		}

		TF2Attrib_SetByName(client, "max health additive bonus", 4850.0);
		TF2Attrib_SetByName(client, "health from packs decreased", 0.0);
		TF2Attrib_SetByName(client, "cannot be backstabbed", 1.0);	

		int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		if(IsValidEntity(Weapon3))
		{
			TF2Attrib_RemoveAll(Weapon3);
			
			TF2Attrib_SetByName(Weapon3, "critboost on kill", 4.0);
			TF2Attrib_SetByName(Weapon3, "slow enemy on hit major", 5.0);	
			TF2Attrib_SetByName(Weapon3, "speed buff ally", 1.0);
			TF2Attrib_SetByName(Weapon3, "damage bonus", 8.0);
			TF2Attrib_SetByName(Weapon3, "dmg bonus vs buildings", 8.0);			
			TF2Attrib_SetByName(Weapon3, "melee bounds multiplier", 3.0);	
			TF2Attrib_SetByName(Weapon3, "melee range multiplier", 3.0);	
			TF2Attrib_SetByName(Weapon3, "melee attack rate bonus", 0.4);
			TF2Attrib_SetByName(Weapon3, "armor piercing", 5.0);	
			TF2Attrib_SetByName(Weapon3, "is australium item", 1.0);
			TF2Attrib_SetByName(Weapon3, "item style override", 1.0);
			TF2Attrib_SetByName(Weapon3, "turn to gold", 1.0);
			TF2Attrib_SetByName(Weapon3, "SPELL: set Halloween footstep type", 13595446.0);
			TF2Attrib_SetByName(Weapon3, "attach particle effect", 13.0);			
			TF2_AddCondition(client, TFCond_RadiusHealOnDamage, 3.0);			
		}

		Command_makesound1(client);
	}
}

public void player_inv(Handle event, const char[] name, bool dontBroadcast) 
{
	int userd = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userd);
	
	if (g_SplendidScreen[client] && IsValidClient(client))
	{
		EmitSoundToAll(SND_DEATH);
		TF2_RemoveAllWearables(client);
		int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		TF2Attrib_RemoveByName(Weapon3, "max health additive bonus");
		TF2Attrib_RemoveByName(Weapon3, "health from packs decreased");			
		TF2Attrib_RemoveByName(Weapon3, "cannot be backstabbed");	
		TF2Attrib_RemoveByName(Weapon3, "critboost on kill");
		TF2Attrib_RemoveByName(Weapon3, "slow enemy on hit major");	
		TF2Attrib_RemoveByName(Weapon3, "speed buff ally");
		TF2Attrib_RemoveByName(Weapon3, "damage bonus");	
		TF2Attrib_RemoveByName(Weapon3, "melee bounds multiplier");	
		TF2Attrib_RemoveByName(Weapon3, "melee range multiplier");	
		TF2Attrib_RemoveByName(Weapon3, "melee attack rate bonus");
		TF2Attrib_RemoveByName(Weapon3, "armor piercing");	
		TF2Attrib_RemoveByName(Weapon3, "is australium item");
		TF2Attrib_RemoveByName(Weapon3, "item style override");
		TF2Attrib_RemoveByName(Weapon3, "turn to gold");
		TF2Attrib_RemoveByName(Weapon3, "SPELL: set Halloween footstep type");
		TF2Attrib_RemoveByName(Weapon3, "attach particle effect");		

		int  iEntity = -1;
		while ((iEntity = FindEntityByClassname(iEntity, "tf_wearable_demoshield")) != -1)
		{
			if (client == GetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity"))
			{
				TF2Attrib_RemoveByName(iEntity, "charge time increased");
				TF2Attrib_RemoveByName(iEntity, "charge recharge rate increased");
				TF2Attrib_RemoveByName(iEntity, "charge impact damage increased");	
				TF2Attrib_RemoveByName(iEntity, "mult charge turn control");
				TF2Attrib_RemoveByName(iEntity, "move speed penalty");
				TF2Attrib_RemoveByName(iEntity, "major increased jump height");	
				TF2Attrib_RemoveByName(iEntity, "max health additive bonus");
				break;				
			}
		}
		g_SplendidScreen[client] = false;	
		
		TF2Attrib_RemoveAll(client);
		
		SetEntProp(client, Prop_Send, "m_iHealth", 125, 1);	
		
		TF2_RegeneratePlayer(client);			
	}
}

public void OnClientPutInServer(int client)
{
	OnClientDisconnect_Post(client);
}

public void OnClientDisconnect_Post(int client)
{
	if (g_SplendidScreen[client])
	{
		g_SplendidScreen[client] = false;
	}
}

public Action Command_makesound1(int client) 
{  
	EmitSoundToAll(SND_SAMURAI1); 
	CreateTimer(5.0, Command_makesound2);     
}

public Action Command_makesound2(Handle timer) 
{ 
	EmitSoundToAll(SND_SAMURAI2); 
	CreateTimer(5.0, Command_makesound3);  
}

public Action Command_makesound3(Handle timer) 
{ 
	EmitSoundToAll(SND_SAMURAI3); 
	
	return Plugin_Handled;
}

stock bool IsValidClient(int client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	return IsClientInGame(client);
}

stock Action TF2_SetHealth(int client, int NewHealth)
{
	SetEntProp(client, Prop_Send, "m_iHealth", NewHealth, 1);
	SetEntProp(client, Prop_Data, "m_iHealth", NewHealth, 1);
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
	
	if(itemindex == 359)
	{
		SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), 5);
		TF2Attrib_SetByDefIndex(hat, 134, GetRandomInt(1,133) + 0.0);	
	}

	DispatchSpawn(hat);
	SDKCall(g_hEquipWearable, client, hat);
	return true;
}

stock void RemoveAllWearables(int client)
{
	int edict = MaxClients+1;
	while((edict = FindEntityByClassname(edict, "tf_wearable")) != -1)
	{
		char netclass[32];
		if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable"))
		{
			if (GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
			{
				AcceptEntityInput(edict, "Kill");
			}
		}
	}
}

stock Action RemoveWearable(int client, char[] classname, char[] networkclass)
{
	if (IsValidClient(client) && IsPlayerAlive(client))
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
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iItemDefinitionIndex"), itemindex);	 
	SetEntData(weapon, FindSendPropInfo(entclass, "m_bInitialized"), 1);
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), quality);
	SetEntProp(weapon, Prop_Send, "m_bValidatedAttachedEntity", 1); 
	
	if (level)
	{
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	}
	else
	{
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityLevel"), GetRandomInt(1,99));
	}

	TF2Attrib_SetByDefIndex(weapon, 834, view_as<float>(paint));	//Set Warpaint
	
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

	if(quality == 9)
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
		if(GetRandomInt(1,15) == 1)
		{
			TF2Attrib_SetByDefIndex(weapon, 2053, 1.0);
		}
	}
	
	if(quality == 11)
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
	
	if (quality !=9)
	{
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
				|| itemindex == 210)	
		{
			if (GetRandomInt(1,2) < 3)
			{
				TF2_SwitchtoSlot(client, slot);
				int iRand = GetRandomInt(1,4);
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
		}
	}

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

stock void TF2_RemoveAllWearables(int client)
{
	int wearable = -1;
	while ((wearable = FindEntityByClassname(wearable, "tf_wearable*")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			int player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
			if (client == player)
			{
				TF2_RemoveWearable(client, wearable);
			}
		}
	}

	while ((wearable = FindEntityByClassname(wearable, "tf_powerup_bottle")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			int player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
			if (client == player)
			{
				TF2_RemoveWearable(client, wearable);
			}
		}
	}

	while ((wearable = FindEntityByClassname(wearable, "tf_weapon_spellbook")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			int player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
			if (client == player)
			{
				TF2_RemoveWearable(client, wearable);
			}
		}
	}
}