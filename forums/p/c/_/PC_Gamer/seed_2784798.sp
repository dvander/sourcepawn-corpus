#include <tf2_stocks>
#include <tf2attributes>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

bool g_bMedieval;
static int seed[2];

public Plugin myinfo = 
{
	name = "[TF2] Test of seed import and translation",
	author = "PC Gamer",
	description = "Test importing large number with BigInt",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_seed", Command_TestBigInt);
}

public void OnMapStart()
{
	if (GameRules_GetProp("m_bPlayingMedieval"))
	{
		g_bMedieval = true;
	}	
}

public Action Command_TestBigInt(int client, int args)
{
	char arg1[32];
	if (args < 1)
	{	
		ReplyToCommand(client, "Invalid seed number");		
		ReplyToCommand(client, "seed <warpaint id> <seed number> <unusual effect number>");
		ReplyToCommand(client, "warpaint ids: 200-297, 300-310, 390, 391");
		ReplyToCommand(client, "unusual effect numbers: blank, 0, 1, 2, 3, or 4");
		ReplyToCommand(client, "Example: seed 303 2000 4");
		
		return Plugin_Handled;
	}
	GetCmdArg(1, arg1, sizeof(arg1));
	int paint = StringToInt(arg1);	
	if ((paint < 200) || (paint > 391) || (paint >297 && paint < 300) || (paint >310 && paint <390))
	{
		ReplyToCommand(client, "Invalid warpaint id");
		ReplyToCommand(client, "seed <warpaint id> <seed number> <unusual effect number>");
		ReplyToCommand(client, "warpaint ids: 200-297, 300-310, 390, 391");
		ReplyToCommand(client, "unusual effect numbers: blank, 0, 1, 2, 3, or 4");
		ReplyToCommand(client, "Example: seed 303 2000 4");

		return Plugin_Handled;		
	}
	if (args < 2)
	{
		ReplyToCommand(client, "Invalid seed number");
		ReplyToCommand(client, "seed <warpaint id> <seed>");
		ReplyToCommand(client, "or: seed <warpaint id> <seed> <unusual effect number>");	
		ReplyToCommand(client, "warpaint ids: 200-297, 300-310, 390, 391"); 
		ReplyToCommand(client, "unusual effect numbers: blank, 0, 1, 2, 3, or 4");
		ReplyToCommand(client, "Example: seed 303 2000 4");
		
		return Plugin_Handled;		
	}	
	
	int effect = 0;
	if (args > 2)
	{
		char arg3[32];
		GetCmdArg(3, arg3, sizeof(arg3));
		effect = StringToInt(arg3);
		if (effect <1 || effect >4)
		{
			ReplyToCommand(client, "Invalid unusual effect number");
			ReplyToCommand(client, "seed <warpaint id> <seed>");
			ReplyToCommand(client, "or: seed <warpaint id> <seed> <unusual effect number>");	
			ReplyToCommand(client, "warpaint ids: 200-297, 300-310, 390, 391"); 
			ReplyToCommand(client, "unusual effect numbers: blank, 0, 1, 2, 3, or 4");
			ReplyToCommand(client, "Example: seed 303 2000 4");		
		}
	}
	
	char arg2[32];
	GetCmdArg(2, arg2, sizeof(arg2));
	
	StringToInt64v2(arg2, seed);

	PrintToChat(client, "Seed %s translates into: lowseed: %i, highseed: %i, effect: %i", arg2, seed[0], seed[1], effect);

	MakeWarPaintWithSeed(client, paint, seed[0], seed[1], effect);

	return Plugin_Handled;
}

void StringToInt64v2(const char[] buffer, int values[2])
{
	KeyValues kv = new KeyValues("temp");
	kv.SetString("var", buffer);
	kv.GetUInt64("var", values);
	delete kv;
}

void MakeWarPaintWithSeed(int client, int paint, int lowseed, int highseed, int effect = 0)
{
	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Scout)
	{
		if (!g_bMedieval)
		{	
			int myslot0 = GetIndexOfWeaponSlot(client, 0);
			if(myslot0 == 220)//Shortstop
			{
				CreateWeapon5(client, "tf_weapon_handgun_scout_primary", 220, 6, 98, 0, paint, lowseed, highseed, effect);
			}
			if(myslot0 == 448)//Soda Popper
			{
				CreateWeapon5(client, "tf_weapon_soda_popper", 448, 6, 98, 0, paint, lowseed, highseed, effect);
			}
			if(myslot0 != 220 && myslot0 != 448)
			{
				CreateWeapon5(client, "tf_weapon_scattergun", 200, 6, 98, 0, paint, lowseed, highseed, effect);
			}

			int myslot1 = GetIndexOfWeaponSlot(client, 1);
			if(myslot1 == 449)//Winger
			{
				CreateWeapon5(client, "tf_weapon_handgun_scout_secondary", 449, 6, 97, 1, paint, lowseed, highseed, effect);
			}
			if(myslot1 != 449)
			{
				CreateWeapon5(client, "tf_weapon_pistol", 209, 6, 97, 1, paint, lowseed, highseed, effect);
			}
		}

		CreateWeapon5(client, "tf_weapon_bat_fish", 221, 6, 96, 2, paint, lowseed, highseed, effect);
	}

	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Soldier)
	{
		if (!g_bMedieval)
		{
			int myslot0 = GetIndexOfWeaponSlot(client, 0);
			if(myslot0 == 228)//Black Box
			{
				CreateWeapon5(client, "tf_weapon_rocketlauncher", 228, 6, 98, 0, paint, lowseed, highseed, effect);
			}
			if(myslot0 == 1104)//Air Strike
			{
				CreateWeapon5(client, "tf_weapon_rocketlauncher_airstrike", 1104, 6, 98, 0, paint, lowseed, highseed, effect);
			}
			if(myslot0 != 228 && myslot0 != 1104)
			{
				CreateWeapon5(client, "tf_weapon_rocketlauncher", 205, 6, 98, 0, paint, lowseed, highseed, effect);
			}

			int myslot1 = GetIndexOfWeaponSlot(client, 1);
			if(myslot1 == 415)//Reserve Shooter
			{
				CreateWeapon5(client, "tf_weapon_shotgun_soldier", 415, 6, 97, 1, paint, lowseed, highseed, effect);
			}
			if(myslot1 == 1153)//Panic Attack
			{
				CreateWeapon5(client, "tf_weapon_shotgun_soldier", 1153, 6, 97, 1, paint, lowseed, highseed, effect);
			}		
			
			if(myslot1 != 415 && myslot1 != 1153 && myslot1 > 0)
			{
				CreateWeapon5(client, "tf_weapon_shotgun_soldier", 199, 6, 97, 1, paint, lowseed, highseed, effect);
			}
		}
		
		CreateWeapon5(client, "tf_weapon_shovel", 447, 6, 96, 2, paint, lowseed, highseed, effect);		
	}
	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Pyro)
	{
		if (!g_bMedieval)
		{
			int myslot0 = GetIndexOfWeaponSlot(client, 0);
			if(myslot0 == 215)//Degreaser
			{
				CreateWeapon5(client, "tf_weapon_flamethrower", 215, 6, 98, 0, paint, lowseed, highseed, effect);
			}
			if(myslot0 != 215)
			{
				CreateWeapon5(client, "tf_weapon_flamethrower", 208, 6, 98, 0, paint, lowseed, highseed, effect);
			}

			int myslot1 = GetIndexOfWeaponSlot(client, 1);
			if(myslot1 == 351)//Detonator
			{
				CreateWeapon5(client, "tf_weapon_flaregun", 351, 6, 97, 1, paint, lowseed, highseed, effect);
			}
			if(myslot1 == 740)//Scorch Shot
			{
				CreateWeapon5(client, "tf_weapon_flaregun", 740, 6, 97, 1, paint, lowseed, highseed, effect);
			}
			if(myslot1 == 1153)//Panic Attack
			{
				CreateWeapon5(client, "tf_weapon_shotgun_pyro", 1153, 6, 97, 1, paint, lowseed, highseed, effect);
			}
			if(myslot1 == 415)//Reserve Shooter
			{
				CreateWeapon5(client, "tf_weapon_shotgun_pyro", 415, 6, 97, 1, paint, lowseed, highseed, effect);
			}
			if(myslot1 != 351 && myslot1 != 740 && myslot1 != 415 && myslot1 != 1153)
			{
				CreateWeapon5(client, "tf_weapon_shotgun_pyro", 199, 6, 97, 1, paint, lowseed, highseed, effect);
			}
		}

		int myslot2 = GetIndexOfWeaponSlot(client, 2);
		if(myslot2 == 326)//Back Scratcher
		{
			CreateWeapon5(client, "tf_weapon_fireaxe", 326, 6, 96, 2, paint, lowseed, highseed, effect);
		}
		if(myslot2 != 326)
		{
			CreateWeapon5(client, "tf_weapon_fireaxe", 214, 6, 96, 2, paint, lowseed, highseed, effect);
		}
	}
	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_DemoMan)
	{
		if (!g_bMedieval)
		{
			int myslot0 = GetIndexOfWeaponSlot(client, 0);
			if(myslot0 == 308)//Loc n Load
			{
				CreateWeapon5(client, "tf_weapon_grenadelauncher", 308, 6, 98, 0, paint, lowseed, highseed, effect);
			}
			if(myslot0 == 996)//Loose Cannon
			{
				CreateWeapon5(client, "tf_weapon_cannon", 996, 6, 98, 0, paint, lowseed, highseed, effect);
			}
			if(myslot0 == 1151)//Iron Bomber
			{
				CreateWeapon5(client, "tf_weapon_grenadelauncher", 1151, 6, 98, 0, paint, lowseed, highseed, effect);
			}
			if(myslot0 != 308 && myslot0 != 996 && myslot0 != 1151 && myslot0 > 0)
			{
				CreateWeapon5(client, "tf_weapon_grenadelauncher", 206, 6, 98, 0, paint, lowseed, highseed, effect);
			}

			int myslot1 = GetIndexOfWeaponSlot(client, 1);
			if(myslot1 != -1)
			{
				CreateWeapon5(client, "tf_weapon_pipebomblauncher", 207, 6, 97, 1, paint, lowseed, highseed, effect);
			}
		}

		int myslot2 = GetIndexOfWeaponSlot(client, 2);
		if(myslot2 == 172)//Scotsmans Skullcutter
		{
			CreateWeapon5(client, "tf_weapon_sword", 172, 6, 96, 2, paint, lowseed, highseed, effect);
		}
		if(myslot2 == 327)//Claidheamh Mor
		{
			CreateWeapon5(client, "tf_weapon_sword", 327, 6, 96, 2, paint, lowseed, highseed, effect);
		}		
		if(myslot2 != 172 && myslot2 != 327)
		{
			CreateWeapon5(client, "tf_weapon_sword", 404, 6, 96, 2, paint, lowseed, highseed, effect);
		}
	}		
	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Heavy)
	{
		if (!g_bMedieval)
		{
			int myslot0 = GetIndexOfWeaponSlot(client, 0);
			if(myslot0 == 312)//Brass Beast
			{
				CreateWeapon5(client, "tf_weapon_minigun", 312, 6, 98, 0, paint, lowseed, highseed, effect);
			}
			if(myslot0 == 424)//Tomislav
			{
				CreateWeapon5(client, "tf_weapon_minigun", 424, 6, 98, 0, paint, lowseed, highseed, effect);
			}
			if(myslot0 != 312 && myslot0 != 424)
			{
				CreateWeapon5(client, "tf_weapon_minigun", 202, 6, 98, 0, paint, lowseed, highseed, effect);
			}

			int myslot1 = GetIndexOfWeaponSlot(client, 1);
			if(myslot1 == 425)//Family Business
			{
				CreateWeapon5(client, "tf_weapon_shotgun_hwg", 425, 6, 97, 1, paint, lowseed, highseed, effect);
			}		
			if(myslot1 == 1153)//Panic Attack
			{
				CreateWeapon5(client, "tf_weapon_shotgun_hwg", 1153, 6, 97, 1, paint, lowseed, highseed, effect);
			}
			if(myslot1 != 425 && myslot1 != 1153)
			{
				CreateWeapon5(client, "tf_weapon_shotgun_hwg", 199, 6, 97, 1, paint, lowseed, highseed, effect);
			}
		}
	}
	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Engineer)
	{
		if (!g_bMedieval)
		{
			int myslot0 = GetIndexOfWeaponSlot(client, 0);
			if(myslot0 == 997)//Rescue Ranger
			{
				CreateWeapon5(client, "tf_weapon_shotgun_building_rescue", 997, 6, 97, 1, paint, lowseed, highseed, effect);
			}
			if(myslot0 != 997)
			{
				CreateWeapon5(client, "tf_weapon_shotgun_primary", 199, 6, 98, 0, paint, lowseed, highseed, effect);
			}

			CreateWeapon5(client, "tf_weapon_pistol", 209, 6, 99, 1, paint, lowseed, highseed, effect);
		}
		
		int myslot2 = GetIndexOfWeaponSlot(client, 2);
		if(myslot2 == 329)//Jag
		{
			CreateWeapon5(client, "tf_weapon_wrench", 329, 6, 96, 2, paint, lowseed, highseed, effect);
		}
		if(myslot2 != 329)
		{
			CreateWeapon5(client, "tf_weapon_wrench", 197, 6, 96, 2, paint, lowseed, highseed, effect);
		}
	}
	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Medic)
	{
		if (!g_bMedieval)
		{
			CreateWeapon5(client, "tf_weapon_medigun", 211, 6, 99, 1, paint, lowseed, highseed, effect);
		}

		CreateWeapon5(client, "tf_weapon_crossbow", 305, 6, 99, 0, paint, lowseed, highseed, effect);
		
		int myslot2 = GetIndexOfWeaponSlot(client, 2);
		if(myslot2 == 37)//Ubersaw
		{
			CreateWeapon5(client, "tf_weapon_bonesaw", 37, 6, 96, 2, paint, lowseed, highseed, effect);
		}
		if(myslot2 != 37)
		{
			CreateWeapon5(client, "tf_weapon_bonesaw", 304, 6, 96, 2, paint, lowseed, highseed, effect);
		}
	}
	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Sniper)
	{
		if (!g_bMedieval)
		{
			int myslot0 = GetIndexOfWeaponSlot(client, 0);

			if(myslot0 == 402)//Bazaar Bargain
			{
				CreateWeapon5(client, "tf_weapon_sniperrifle_decap", 402, 6, 99, 0, paint, lowseed, highseed, effect);
			}
			if(myslot0 != 402)
			{
				CreateWeapon5(client, "tf_weapon_sniperrifle", 201, 6, 99, 0, paint, lowseed, highseed, effect);
			}		

			int myslot1 = GetIndexOfWeaponSlot(client, 1);
			if(myslot1 > 0) //NOT Razorback, danger shield, or cozy camper
			{
				CreateWeapon5(client, "tf_weapon_smg", 203, 6, 99, 1, paint, lowseed, highseed, effect);
			}
		}
		
		CreateWeapon5(client, "tf_weapon_club", 401, 6, 96, 2, paint, lowseed, highseed, effect);
	}
	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Spy)
	{
		if (!g_bMedieval)
		{		
			CreateWeapon5(client, "tf_weapon_revolver", 210, 6, 99, 0, paint, lowseed, highseed, effect);
		}
		
		CreateWeapon5(client, "tf_weapon_knife", 194, 6, 99, 2, paint, lowseed, highseed, effect);		
	}
}

bool CreateWeapon5(int client, char[] classname, int itemindex, int quality, int level, int slot, int paint, int lowseed, int highseed, int effect = 0)
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

	TF2Attrib_SetByDefIndex(weapon, 834, view_as<float>(paint));	//Set Warpaint
	
	if (lowseed !=-1 && highseed !=-1)
	{
		TF2Attrib_SetByDefIndex(weapon, 866, view_as<float>(lowseed));
		TF2Attrib_SetByDefIndex(weapon, 867, view_as<float>(highseed));		
	}
	
	if (GetRandomUInt(1,10) == 1)
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

	if (effect >0)
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
				|| itemindex == 194				
				|| itemindex == 210)	
		{
			if ((slot < 2))
			{
				SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 5);
				MakeUnusual(client, slot, effect);
			}
		}
	}

	TF2_SwitchtoSlot(client, 0);
	
	return true;
}

public void MakeUnusual(int client, int slot, int effect)
{
	TF2_SwitchtoSlot(client, slot);
	int clientweapon = GetPlayerWeaponSlot(client, slot);
	if (effect == 1)
	{
		TF2Attrib_SetByDefIndex(clientweapon, 134, 701.0);	
	}
	else if (effect == 2)
	{
		TF2Attrib_SetByDefIndex(clientweapon, 134, 702.0);	
	}	
	else if (effect == 3)
	{
		TF2Attrib_SetByDefIndex(clientweapon, 134, 703.0);	
	}
	else if (effect == 4)
	{
		TF2Attrib_SetByDefIndex(clientweapon, 134, 704.0);	
	}
}

stock bool IsValidClient(int client, bool nobots = true)
{ 
	if (client <= 0 || client > MaxClients)
	{
		return false; 
	}
	return IsClientInGame(client); 
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

stock int GetIndexOfWeaponSlot(int client, int iSlot)
{
	return GetWeaponIndex(GetPlayerWeaponSlot(client, iSlot));
}

stock int GetWeaponIndex(int iWeapon)
{
	return IsValidEnt(iWeapon) ? GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex"):-1;
}

stock bool IsValidEnt(int iEnt)
{
	return iEnt > MaxClients && IsValidEntity(iEnt);
}