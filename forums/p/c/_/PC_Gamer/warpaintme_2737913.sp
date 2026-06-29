#include <tf2_stocks>
#include <tf2attributes>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "2.3"

public const int festiveWeps[224] = { 
	35, 37, 41, 44, 130, 172, 192, 193, 194, 196, 197, 200, 201, 202, 203,
	205, 206, 207, 208, 209, 210, 211, 214, 215, 220, 221, 228, 304, 305, 308,
	312, 326, 327, 329, 351, 401, 402, 404, 411, 415, 424, 425, 447, 448, 449, 
	649, 740, 996, 997, 1104, 1151, 1153, 1178, 15000, 15001, 15002, 15003, 15004, 15005, 15006,
	15007, 15008, 15009, 15010, 15011, 15012, 15013, 15013, 15014, 15015, 15016, 15017, 15018, 15019, 15020,
	15021, 15022, 15023, 15024, 15025, 15026, 15027, 15028, 15029, 15030, 15031, 15032, 15033, 15034, 15035,
	15035, 15036, 15037, 15038, 15039, 15040, 15041, 15041, 15042, 15043, 15044, 15045, 15046, 15046, 15047,
	15048, 15049, 15050, 15051, 15052, 15053, 15054, 15055, 15056, 15056, 15057, 15058, 15059, 15060, 15060,
	15061, 15061, 15062, 15062, 15063, 15064, 15065, 15066, 15067, 15068, 15069, 15070, 15071, 15072, 15073,
	15074, 15075, 15076, 15077, 15078, 15079, 15081, 15082, 15083, 15084, 15085, 15086, 15087, 15088, 15089,
	15090, 15091, 15092, 15094, 15095, 15096, 15097, 15098, 15099, 15100, 15100, 15101, 15101, 15102, 15102,
	15103, 15104, 15105, 15106, 15107, 15108, 15109, 15110, 15111, 15112, 15113, 15114, 15115, 15116, 15117,
	15118, 15119, 15121, 15122, 15123, 15123, 15124, 15125, 15126, 15126, 15128, 15129, 15129, 15130, 15131,
	15132, 15133, 15134, 15135, 15136, 15137, 15138, 15139, 15140, 15141, 15142, 15143, 15144, 15145, 15146,
	15147, 15148, 15148, 15149, 15150, 15151, 15152, 15153, 15154, 15155, 15156, 15157, 15158 };


public Plugin myinfo = 
{
	name = "[TF2] War Paint weapons",
	author = "PC Gamer, with code by luki1412 and manicogaming",
	description = "Apply War Paint to weapons",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

bool g_bIsWarPainted[MAXPLAYERS + 1];
bool g_bMedieval;

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	RegAdminCmd("sm_warpaint", Command_givewarpainttotarget, ADMFLAG_SLAY, "Give Target War Paint Weapons");
	RegAdminCmd("sm_opwarpaint", Command_giveopwarpainttotarget, ADMFLAG_SLAY, "Give Target Overpowered War Paint Weapons");
	RegConsoleCmd("sm_warpaintme", Command_givewarpaint);
	RegAdminCmd("sm_opwarpaintme", Command_giveopwarpaint, ADMFLAG_SLAY, "Give Me Overpowered War Paint Weapons");
	HookEvent("post_inventory_application", player_inv2);		
}

public void OnMapStart()
{
	if (GameRules_GetProp("m_bPlayingMedieval"))
	{
		g_bMedieval = true;
	}	
}

Action Command_givewarpaint(int client, int args)
{
	char arg1[32];
	if (args < 1)
	{	
		GiveWarPaint(client);
		
		return Plugin_Handled;
	}
	GetCmdArg(1, arg1, sizeof(arg1));
	int paint = StringToInt(arg1);	
	if ((paint < 200) || (paint > 297 && paint < 300) || (paint > 310 && paint < 390) || (paint > 390 && paint < 400)|| (paint > 410 && paint < 15000) || (paint > 15158))
	{
		ReplyToCommand(client, "warpaintme <warpaint id>");
		ReplyToCommand(client, "warpaint ids: 200-297, 300-310, 390, 391, 400-410, 15000-15158"); 		
	}
	else
	{
		MakeWarPaint(client, paint);
	}
	
	return Plugin_Handled;
}

Action Command_giveopwarpaint(int client, int args)
{
	char arg1[32];
	if (args < 1)
	{	
		GiveWarPaint(client);
		MakeOP(client);
		
		return Plugin_Handled;
	}
	GetCmdArg(1, arg1, sizeof(arg1));
	int paint = StringToInt(arg1);	
	if ((paint < 200) || (paint > 297 && paint < 300) || (paint > 310 && paint < 390) || (paint > 390 && paint < 400)|| (paint > 410 && paint < 15000) || (paint > 15158))
	{

		ReplyToCommand(client, "opwarpaintme <warpaint id>");
		ReplyToCommand(client, "warpaint ids: 200-297, 300-310, 390, 391, 400-410, 15000-15158"); 		
	}
	else
	{
		MakeWarPaint(client, paint);
		MakeOP(client);
	}
	
	return Plugin_Handled;
}

Action Command_givewarpainttotarget(int client, int args)
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
	
	char arg2[32];
	if (args < 2)
	{
		for (int i = 0; i < target_count; i++)
		{
			GiveWarPaint(target_list[i]);
			LogAction(client, target_list[i], "\"%L\" gave \"%L\" Warpaint Weapons!", client, target_list[i]);
		}
		
		return Plugin_Handled;
	}


	GetCmdArg(2, arg2, sizeof(arg2));
	int paint = StringToInt(arg2);	
	if ((paint < 200) || (paint > 297 && paint < 300) || (paint > 310 && paint < 390) || (paint > 390 && paint < 400)|| (paint > 410 && paint < 15000) || (paint > 15158))
	{

		ReplyToCommand(client, "warpaint <target> <warpaint id>");
		ReplyToCommand(client, "warpaint ids: 200-297, 300-310, 390, 391, 400-410, 15000-15158"); 		
	}
	else
	{
		for (int i = 0; i < target_count; i++)
		{
			MakeWarPaint(target_list[i], paint);
			LogAction(client, target_list[i], "\"%L\" gave \"%L\" Warpaint Weapons!", client, target_list[i]);
		}
	}
	
	return Plugin_Handled;
}

Action Command_giveopwarpainttotarget(int client, int args)
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
	char arg2[32];
	if (args < 2)
	{
		for (int i = 0; i < target_count; i++)
		{
			GiveWarPaint(target_list[i]);
			MakeOP(target_list[i]);
			LogAction(client, target_list[i], "\"%L\" gave \"%L\" OP Warpaint Weapons!", client, target_list[i]);
		}
		
		return Plugin_Handled;
	}	
	
	GetCmdArg(2, arg2, sizeof(arg2));
	int paint = StringToInt(arg2);	
	if ((paint < 200) || (paint > 297 && paint < 300) || (paint > 310 && paint < 390) || (paint > 390 && paint < 400)|| (paint > 410 && paint < 15000) || (paint > 15158))
	{

		ReplyToCommand(client, "warpaint <target> <warpaint id>");
		ReplyToCommand(client, "warpaint ids: 200-297, 300-310, 390, 391, 400-410, 15000-15158"); 		
	}
	else
	{
		for (int i = 0; i < target_count; i++)
		{
			MakeWarPaint(target_list[i], paint);
			MakeOP(target_list[i]);
			LogAction(client, target_list[i], "\"%L\" gave \"%L\" OP Warpaint Weapons!", client, target_list[i]);
		}
	}
	
	return Plugin_Handled;
}

Action GiveWarPaint(int client)
{
	PrintToChat(client, "You now have Warpaint weapons.");
	PrintToChat(client, "You will lose the weapons when you die or touch a locker.");	
	PrintToChat(client, "To pick a specifc warpaint use:  warpaintme <warpaint id>");
	PrintToChat(client, "warpaint ids: 200-297, 300-310, 390, 391, 400-410, 15000-15158"); 	
	
	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Scout)
	{
		if (!g_bMedieval)
		{
			int paint = GetRandomUInt(200, 297);
			if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274 || paint == 288)
			{		
				if(GetRandomUInt(1,2)== 1)
				{
					paint = GetRandomUInt(300, 310);
				}
				else
				{
					paint = GetRandomUInt(400, 410);
				}
			}
			int myslot0 = GetIndexOfWeaponSlot(client, 0);
			if(myslot0 == 220)//Shortstop
			{
				CreateWeapon(client, "tf_weapon_handgun_scout_primary", 220, 6, 98, 0, paint);
			}
			if(myslot0 == 448)//Soda Popper
			{
				CreateWeapon(client, "tf_weapon_soda_popper", 448, 6, 98, 0, paint);
			}
			if(myslot0 != 220 && myslot0 != 448)
			{
				CreateWeapon(client, "tf_weapon_scattergun", 200, 6, 98, 0, paint);
			}

			paint = GetRandomUInt(200, 283);
			if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274 || paint == 288)
			{		
				if(GetRandomUInt(1,2)== 1)
				{
					paint = GetRandomUInt(300, 310);
				}
				else
				{
					paint = GetRandomUInt(400, 410);
				}
			}		
			int myslot1 = GetIndexOfWeaponSlot(client, 1);
			if(myslot1 == 449)//Winger
			{
				CreateWeapon(client, "tf_weapon_handgun_scout_secondary", 449, 6, 97, 1, paint);
			}
			if(myslot1 != 449)
			{
				CreateWeapon(client, "tf_weapon_pistol", 209, 6, 97, 1, paint);
			}
		}

		int paint = GetRandomUInt(200, 297);
		if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274 || paint == 288)
		{		
			if(GetRandomUInt(1,2)== 1)
			{
				paint = GetRandomUInt(300, 310);
			}
			else
			{
				paint = GetRandomUInt(400, 410);
			}
		}

		CreateWeapon(client, "tf_weapon_bat_fish", 221, 6, 96, 2, paint);
		
		return Plugin_Handled;
	}
	
	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Soldier)
	{
		if (!g_bMedieval)
		{
			int paint = GetRandomUInt(200, 297);
			if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274 || paint == 288)
			{		
				if(GetRandomUInt(1,2)== 1)
				{
					paint = GetRandomUInt(300, 310);
				}
				else
				{
					paint = GetRandomUInt(400, 410);
				}
			}
			int myslot0 = GetIndexOfWeaponSlot(client, 0);
			if(myslot0 == 228)//Black Box
			{
				CreateWeapon(client, "tf_weapon_rocketlauncher", 228, 6, 98, 0, paint);
			}
			if(myslot0 == 1104)//Air Strike
			{
				CreateWeapon(client, "tf_weapon_rocketlauncher_airstrike", 1104, 6, 98, 0, paint);
			}
			if(myslot0 != 228 && myslot0 != 1104)
			{
				CreateWeapon(client, "tf_weapon_rocketlauncher", 205, 6, 98, 0, paint);
			}

			paint = GetRandomUInt(200, 283);
			if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274 || paint == 288)
			{		
				if(GetRandomUInt(1,2)== 1)
				{
					paint = GetRandomUInt(300, 310);
				}
				else
				{
					paint = GetRandomUInt(400, 410);
				}
			}
			int myslot1 = GetIndexOfWeaponSlot(client, 1);
			if(myslot1 == 415)//Reserve Shooter
			{
				CreateWeapon(client, "tf_weapon_shotgun_soldier", 415, 6, 97, 1, paint);
			}
			if(myslot1 == 1153)//Panic Attack
			{
				CreateWeapon(client, "tf_weapon_shotgun_soldier", 1153, 6, 97, 1, paint);
			}		
			
			if(myslot1 != 415 && myslot1 != 1153 && myslot1 > 0)
			{
				CreateWeapon(client, "tf_weapon_shotgun_soldier", 199, 6, 97, 1, paint);
			}
		}

		int paint = GetRandomUInt(200, 297);
		if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274 || paint == 288)
		{		
			if(GetRandomUInt(1,2)== 1)
			{
				paint = GetRandomUInt(300, 310);
			}
			else
			{
				paint = GetRandomUInt(400, 410);
			}
		}
		
		CreateWeapon(client, "tf_weapon_shovel", 447, 6, 96, 2, paint);
		
		return Plugin_Handled;		
	}
	
	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Pyro)
	{
		if (!g_bMedieval)
		{
			int paint = GetRandomUInt(200, 297);
			if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274 || paint == 288)
			{		
				if(GetRandomUInt(1,2)== 1)
				{
					paint = GetRandomUInt(300, 310);
				}
				else
				{
					paint = GetRandomUInt(400, 410);
				}
			}
			int myslot0 = GetIndexOfWeaponSlot(client, 0);
			if(myslot0 == 215)//Degreaser
			{
				CreateWeapon(client, "tf_weapon_flamethrower", 215, 6, 98, 0, paint);
			}
			if(myslot0 != 215)
			{
				CreateWeapon(client, "tf_weapon_flamethrower", 208, 6, 98, 0, paint);
			}

			paint = GetRandomUInt(200, 283);
			if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274 || paint == 288)
			{		
				if(GetRandomUInt(1,2)== 1)
				{
					paint = GetRandomUInt(300, 310);
				}
				else
				{
					paint = GetRandomUInt(400, 410);
				}
			}		
			int myslot1 = GetIndexOfWeaponSlot(client, 1);
			if(myslot1 == 351)//Detonator
			{
				CreateWeapon(client, "tf_weapon_flaregun", 351, 6, 97, 1, paint);
			}
			if(myslot1 == 740)//Scorch Shot
			{
				CreateWeapon(client, "tf_weapon_flaregun", 740, 6, 97, 1, paint);
			}
			if(myslot1 == 1153)//Panic Attack
			{
				CreateWeapon(client, "tf_weapon_shotgun_pyro", 1153, 6, 97, 1, paint);
			}
			if(myslot1 == 415)//Reserve Shooter
			{
				CreateWeapon(client, "tf_weapon_shotgun_pyro", 415, 6, 97, 1, paint);
			}
			if(myslot1 != 351 && myslot1 != 740 && myslot1 != 415 && myslot1 != 1153)
			{
				CreateWeapon(client, "tf_weapon_shotgun_pyro", 199, 6, 97, 1, paint);
			}
		}

		int paint = GetRandomUInt(200, 297);
		if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274 || paint == 288)
		{		
			if(GetRandomUInt(1,2)== 1)
			{
				paint = GetRandomUInt(300, 310);
			}
			else
			{
				paint = GetRandomUInt(400, 410);
			}
		}
		
		int myslot2 = GetIndexOfWeaponSlot(client, 2);
		if(myslot2 == 326)//Back Scratcher
		{
			CreateWeapon(client, "tf_weapon_fireaxe", 326, 6, 96, 2, paint);
		}
		if(myslot2 != 326)
		{
			CreateWeapon(client, "tf_weapon_fireaxe", 214, 6, 96, 2, paint);
		}
		
		return Plugin_Handled;
	}

	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_DemoMan)
	{
		if (!g_bMedieval)
		{	
			int paint = GetRandomUInt(200, 297);
			if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274 || paint == 288)
			{		
				if(GetRandomUInt(1,2)== 1)
				{
					paint = GetRandomUInt(300, 310);
				}
				else
				{
					paint = GetRandomUInt(400, 410);
				}
			}
			int myslot0 = GetIndexOfWeaponSlot(client, 0);
			if(myslot0 == 308)//Loc n Load
			{
				CreateWeapon(client, "tf_weapon_grenadelauncher", 308, 6, 98, 0, paint);
			}
			if(myslot0 == 996)//Loose Cannon
			{
				CreateWeapon(client, "tf_weapon_cannon", 996, 6, 98, 0, paint);
			}
			if(myslot0 == 1151)//Iron Bomber
			{
				CreateWeapon(client, "tf_weapon_grenadelauncher", 1151, 6, 98, 0, paint);
			}		
			paint = GetRandomUInt(200, 283);
			if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274 || paint == 288)
			{		
				if(GetRandomUInt(1,2)== 1)
				{
					paint = GetRandomUInt(300, 310);
				}
				else
				{
					paint = GetRandomUInt(400, 410);
				}
			}
			if(myslot0 != 308 && myslot0 != 996 && myslot0 != 1151 && myslot0 > 0)
			{
				CreateWeapon(client, "tf_weapon_grenadelauncher", 206, 6, 98, 0, paint);
			}

			paint = GetRandomUInt(200, 283);
			if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274 || paint == 288)
			{		
				if(GetRandomUInt(1,2)== 1)
				{
					paint = GetRandomUInt(300, 310);
				}
				else
				{
					paint = GetRandomUInt(400, 410);
				}
			}		
			int myslot1 = GetIndexOfWeaponSlot(client, 1);
			if(myslot1 != -1)
			{
				CreateWeapon(client, "tf_weapon_pipebomblauncher", 207, 6, 97, 1, paint);
			}
		}

		int paint = GetRandomUInt(200, 297);
		if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274 || paint == 288)
		{		
			if(GetRandomUInt(1,2)== 1)
			{
				paint = GetRandomUInt(300, 310);
			}
			else
			{
				paint = GetRandomUInt(400, 410);
			}
		}
		
		int myslot2 = GetIndexOfWeaponSlot(client, 2);
		if(myslot2 == 172)//Scotsmans Skullcutter
		{
			CreateWeapon(client, "tf_weapon_sword", 172, 6, 96, 2, paint);
		}
		if(myslot2 == 327)//Claidheamh Mor
		{
			CreateWeapon(client, "tf_weapon_sword", 327, 6, 96, 2, paint);
		}		
		if(myslot2 != 172 && myslot2 != 327)
		{
			CreateWeapon(client, "tf_weapon_sword", 404, 6, 96, 2, paint);
		}
		
		return Plugin_Handled;
	}
	
	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Heavy)
	{
		if (!g_bMedieval)
		{
			int paint = GetRandomUInt(200, 297);
			if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274 || paint == 288)
			{		
				if(GetRandomUInt(1,2)== 1)
				{
					paint = GetRandomUInt(300, 310);
				}
				else
				{
					paint = GetRandomUInt(400, 410);
				}
			}
			int myslot0 = GetIndexOfWeaponSlot(client, 0);
			if(myslot0 == 312)//Brass Beast
			{
				CreateWeapon(client, "tf_weapon_minigun", 312, 6, 98, 0, paint);
			}
			if(myslot0 == 424)//Tomislav
			{
				CreateWeapon(client, "tf_weapon_minigun", 424, 6, 98, 0, paint);
			}
			paint = GetRandomUInt(200, 283);
			if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274 || paint == 288)
			{		
				if(GetRandomUInt(1,2)== 1)
				{
					paint = GetRandomUInt(300, 310);
				}
				else
				{
					paint = GetRandomUInt(400, 410);
				}
			}
			if(myslot0 != 312 && myslot0 != 424)
			{
				CreateWeapon(client, "tf_weapon_minigun", 202, 6, 98, 0, paint);
			}

			paint = GetRandomUInt(200, 283);
			if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274 || paint == 288)
			{		
				if(GetRandomUInt(1,2)== 1)
				{
					paint = GetRandomUInt(300, 310);
				}
				else
				{
					paint = GetRandomUInt(400, 410);
				}
			}		
			int myslot1 = GetIndexOfWeaponSlot(client, 1);
			if(myslot1 == 425)//Family Business
			{
				CreateWeapon(client, "tf_weapon_shotgun_hwg", 425, 6, 97, 1, paint);
			}		
			if(myslot1 == 1153)//Panic Attack
			{
				CreateWeapon(client, "tf_weapon_shotgun_hwg", 1153, 6, 97, 1, paint);
			}
			if(myslot1 != 425 && myslot1 != 1153)
			{
				CreateWeapon(client, "tf_weapon_shotgun_hwg", 199, 6, 97, 1, paint);
			}
		}

		return Plugin_Handled;
	}
	
	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Engineer)
	{
		if (!g_bMedieval)
		{
			int paint = GetRandomUInt(200, 297);
			if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274 || paint == 288)
			{		
				if(GetRandomUInt(1,2)== 1)
				{
					paint = GetRandomUInt(300, 310);
				}
				else
				{
					paint = GetRandomUInt(400, 410);
				}
			}		
			int myslot0 = GetIndexOfWeaponSlot(client, 0);
			if(myslot0 == 997)//Rescue Ranger
			{
				CreateWeapon(client, "tf_weapon_shotgun_building_rescue", 997, 6, 97, 1, paint);
			}
			if(myslot0 != 997)
			{
				CreateWeapon(client, "tf_weapon_shotgun_primary", 199, 6, 98, 0, paint);
			}

			paint = GetRandomUInt(200, 283);
			if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274 || paint == 288)
			{		
				if(GetRandomUInt(1,2)== 1)
				{
					paint = GetRandomUInt(300, 310);
				}
				else
				{
					paint = GetRandomUInt(400, 410);
				}
			}
			CreateWeapon(client, "tf_weapon_pistol", 209, 6, 97, 1, paint);
		}

		int paint = GetRandomUInt(200, 297);
		if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274 || paint == 288)
		{		
			if(GetRandomUInt(1,2)== 1)
			{
				paint = GetRandomUInt(300, 310);
			}
			else
			{
				paint = GetRandomUInt(400, 410);
			}
		}
		int myslot2 = GetIndexOfWeaponSlot(client, 2);
		if(myslot2 == 329)//Jag
		{
			CreateWeapon(client, "tf_weapon_wrench", 329, 6, 96, 2, paint);
		}
		if(myslot2 != 329)
		{
			CreateWeapon(client, "tf_weapon_wrench", 197, 6, 96, 2, paint);
		}
		
		return Plugin_Handled;
	}
	
	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Medic)
	{
		if (!g_bMedieval)
		{
			int paint = GetRandomUInt(200, 297);
			if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274 || paint == 288)
			{		
				if(GetRandomUInt(1,2)== 1)
				{
					paint = GetRandomUInt(300, 310);
				}
				else
				{
					paint = GetRandomUInt(400, 410);
				}
			}

			CreateWeapon(client, "tf_weapon_medigun", 211, 6, 97, 1, paint);
		}

		int paint = GetRandomUInt(200, 297);
		if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274 || paint == 288)
		{		
			if(GetRandomUInt(1,2)== 1)
			{
				paint = GetRandomUInt(300, 310);
			}
			else
			{
				paint = GetRandomUInt(400, 410);
			}
		}

		CreateWeapon(client, "tf_weapon_crossbow", 305, 6, 98, 0, paint);

		paint = GetRandomUInt(200, 283);
		if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274 || paint == 288)
		{		
			if(GetRandomUInt(1,2)== 1)
			{
				paint = GetRandomUInt(300, 310);
			}
			else
			{
				paint = GetRandomUInt(400, 410);
			}
		}

		int myslot2 = GetIndexOfWeaponSlot(client, 2);
		if(myslot2 == 37)//Ubersaw
		{
			CreateWeapon(client, "tf_weapon_bonesaw", 37, 6, 96, 2, paint);
		}
		if(myslot2 != 37)
		{
			CreateWeapon(client, "tf_weapon_bonesaw", 304, 6, 96, 2, paint);
		}
		
		return Plugin_Handled;
	}
	
	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Sniper)
	{
		if (!g_bMedieval)
		{
			int paint = GetRandomUInt(200, 297);
			if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274 || paint == 288)
			{		
				if(GetRandomUInt(1,2)== 1)
				{
					paint = GetRandomUInt(300, 310);
				}
				else
				{
					paint = GetRandomUInt(400, 410);
				}
			}

			int myslot0 = GetIndexOfWeaponSlot(client, 0);

			if(myslot0 == 402)//Bazaar Bargain
			{
				CreateWeapon(client, "tf_weapon_sniperrifle_decap", 402, 6, 98, 0, paint);
			}
			paint = GetRandomUInt(200, 283);
			if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274 || paint == 288)
			{		
				if(GetRandomUInt(1,2)== 1)
				{
					paint = GetRandomUInt(300, 310);
				}
				else
				{
					paint = GetRandomUInt(400, 410);
				}
			}		

			if(myslot0 != 402)
			{
				CreateWeapon(client, "tf_weapon_sniperrifle", 201, 6, 98, 0, paint);
			}
			
			int myslot1 = GetIndexOfWeaponSlot(client, 1);

			if(myslot1 > 0) //NOT Razorback, danger shield, or cozy camper
			{
				paint = GetRandomUInt(200, 283);
				if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274 || paint == 288)
				{		
					if(GetRandomUInt(1,2)== 1)
					{
						paint = GetRandomUInt(300, 310);
					}
					else
					{
						paint = GetRandomUInt(400, 410);
					}
				}		

				CreateWeapon(client, "tf_weapon_smg", 203, 6, 97, 1, paint);
			}
		}

		int paint = GetRandomUInt(200, 297);
		if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274 || paint == 288)
		{		
			if(GetRandomUInt(1,2)== 1)
			{
				paint = GetRandomUInt(300, 310);
			}
			else
			{
				paint = GetRandomUInt(400, 410);
			}
		}

		CreateWeapon(client, "tf_weapon_club", 401, 6, 96, 2, paint);
		
		return Plugin_Handled;
	}

	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Spy)
	{
		if (!g_bMedieval)
		{
			int paint = GetRandomUInt(200, 297);
			if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274 || paint == 288)
			{		
				if(GetRandomUInt(1,2)== 1)
				{
					paint = GetRandomUInt(300, 310);
				}
				else
				{
					paint = GetRandomUInt(400, 410);
				}
			}

			CreateWeapon(client, "tf_weapon_revolver", 210, 6, 98, 0, paint);
		}
		
		int paint = GetRandomUInt(200, 297);
		if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274 || paint == 288)
		{		
			if(GetRandomUInt(1,2)== 1)
			{
				paint = GetRandomUInt(300, 310);
			}
			else
			{
				paint = GetRandomUInt(400, 410);
			}
	}

		CreateWeapon(client, "tf_weapon_knife", 194, 6, 96, 2, paint);
		
		return Plugin_Handled;
	}
	
	TF2_SwitchtoSlot(client, 0);
	
	return Plugin_Handled;
}

Action MakeWarPaint(int client, int paint)
{
	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Scout)
	{
		if (!g_bMedieval)
		{	
			if (paint > 14999 && paint < 15158)
			{
				if (paint == 15002 || paint == 15015 || paint == 15021 || paint == 15029 || paint == 15036 || paint == 15053 || paint == 15065 || paint == 15069 || paint == 15106 || paint == 15107 || paint == 15108 || paint == 15131 || paint == 15151 || paint == 15167)
				{
					CreateWeapon(client, "tf_weapon_scattergun", paint, 6, 98, 0, 0);
				}
				else if (paint == 15013 || paint == 15018 || paint == 15035 || paint == 15041 || paint == 15046 || paint == 15056 || paint == 15060 || paint == 15061 || paint == 15100 || paint == 15101 || paint == 15102 || paint == 15126 || paint == 15148)
				{
					CreateWeapon(client, "tf_weapon_handgun_scout_secondary", paint, 6, 97, 1, 0);
				}				
				else
				{
					ReplyToCommand(client, "Invalid warpaint id for this player class.");
					return Plugin_Handled;
				}
				return Plugin_Handled;
			}

			int myslot0 = GetIndexOfWeaponSlot(client, 0);
			if(myslot0 == 220)//Shortstop
			{
				CreateWeapon(client, "tf_weapon_handgun_scout_primary", 220, 6, 98, 0, paint);
			}
			if(myslot0 == 448)//Soda Popper
			{
				CreateWeapon(client, "tf_weapon_soda_popper", 448, 6, 98, 0, paint);
			}
			if(myslot0 != 220 && myslot0 != 448)
			{
				CreateWeapon(client, "tf_weapon_scattergun", 200, 6, 98, 0, paint);
			}

			int myslot1 = GetIndexOfWeaponSlot(client, 1);
			if(myslot1 == 449)//Winger
			{
				CreateWeapon(client, "tf_weapon_handgun_scout_secondary", 449, 6, 97, 1, paint);
			}
			if(myslot1 != 449)
			{
				CreateWeapon(client, "tf_weapon_pistol", 209, 6, 97, 1, paint);
			}
		}

		if (paint > 14999)
		{
			return Plugin_Handled;
		}
		
		CreateWeapon(client, "tf_weapon_bat_fish", 221, 6, 96, 2, paint);
		return Plugin_Handled;
	}

	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Soldier)
	{
		if (!g_bMedieval)
		{
			if (paint > 14999 && paint < 15158)
			{
				if (paint == 15006 || paint == 15014 || paint == 15028 || paint == 15043 || paint == 15052 || paint == 15057 || paint == 15081 || paint == 15104 || paint == 15105 || paint == 15129 || paint == 15130 || paint == 15150)
				{
					CreateWeapon(client, "tf_weapon_rocketlauncher", paint, 6, 98, 0, 0);
				}
				else if (paint == 15003 || paint == 15016 || paint == 15044 || paint == 15047 || paint == 15085 || paint == 15109 || paint == 15132 || paint == 15133 || paint == 15152)
				{
					CreateWeapon(client, "tf_weapon_shotgun_soldier", paint, 6, 99, 1, 0);
				}				
				else
				{
					ReplyToCommand(client, "Invalid warpaint id for this player class.");
					return Plugin_Handled;
				}
				return Plugin_Handled;
			}

			int myslot0 = GetIndexOfWeaponSlot(client, 0);
			if(myslot0 == 228)//Black Box
			{
				CreateWeapon(client, "tf_weapon_rocketlauncher", 228, 6, 98, 0, paint);
			}
			if(myslot0 == 1104)//Air Strike
			{
				CreateWeapon(client, "tf_weapon_rocketlauncher_airstrike", 1104, 6, 98, 0, paint);
			}
			if(myslot0 != 228 && myslot0 != 1104)
			{
				CreateWeapon(client, "tf_weapon_rocketlauncher", 205, 6, 98, 0, paint);
			}

			int myslot1 = GetIndexOfWeaponSlot(client, 1);
			if(myslot1 == 415)//Reserve Shooter
			{
				CreateWeapon(client, "tf_weapon_shotgun_soldier", 415, 6, 97, 1, paint);
			}
			if(myslot1 == 1153)//Panic Attack
			{
				CreateWeapon(client, "tf_weapon_shotgun_soldier", 1153, 6, 97, 1, paint);
			}		
			
			if(myslot1 != 415 && myslot1 != 1153 && myslot1 > 0)
			{
				CreateWeapon(client, "tf_weapon_shotgun_soldier", 199, 6, 97, 1, paint);
			}
		}
		if (paint > 14999)
		{
			return Plugin_Handled;
		}
		
		CreateWeapon(client, "tf_weapon_shovel", 447, 6, 96, 2, paint);
		return Plugin_Handled;		
	}
	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Pyro)
	{
		if (!g_bMedieval)
		{
			if (paint > 14999 && paint < 15158)
			{
				if (paint == 15005 || paint == 15017 || paint == 15030 || paint == 15034 || paint == 15049 || paint == 15054 || paint == 15066 || paint == 15067 || paint == 15068 || paint == 15089 || paint == 15090 || paint == 15115 || paint == 15141)
				{
					CreateWeapon(client, "tf_weapon_flamethrower", paint, 6, 98, 0, 0);
				}
				else if (paint == 15003 || paint == 15016 || paint == 15044 || paint == 15047 || paint == 15085 || paint == 15109 || paint == 15132 || paint == 15133 || paint == 15152)
				{
					CreateWeapon(client, "tf_weapon_shotgun_pyro", paint, 6, 99, 1, 0);
				}				
				else
				{
					ReplyToCommand(client, "Invalid warpaint id for this player class.");
					return Plugin_Handled;
				}
				return Plugin_Handled;
			}

			int myslot0 = GetIndexOfWeaponSlot(client, 0);
			if(myslot0 == 215)//Degreaser
			{
				CreateWeapon(client, "tf_weapon_flamethrower", 215, 6, 98, 0, paint);
			}
			if(myslot0 != 215)
			{
				CreateWeapon(client, "tf_weapon_flamethrower", 208, 6, 98, 0, paint);
			}

			int myslot1 = GetIndexOfWeaponSlot(client, 1);
			if(myslot1 == 351)//Detonator
			{
				CreateWeapon(client, "tf_weapon_flaregun", 351, 6, 97, 1, paint);
			}
			if(myslot1 == 740)//Scorch Shot
			{
				CreateWeapon(client, "tf_weapon_flaregun", 740, 6, 97, 1, paint);
			}
			if(myslot1 == 1153)//Panic Attack
			{
				CreateWeapon(client, "tf_weapon_shotgun_pyro", 1153, 6, 97, 1, paint);
			}
			if(myslot1 == 415)//Reserve Shooter
			{
				CreateWeapon(client, "tf_weapon_shotgun_pyro", 415, 6, 97, 1, paint);
			}
			if(myslot1 != 351 && myslot1 != 740 && myslot1 != 415 && myslot1 != 1153)
			{
				CreateWeapon(client, "tf_weapon_shotgun_pyro", 199, 6, 97, 1, paint);
			}
		}
		
		if (paint > 14999)
		{
			return Plugin_Handled;
		}		

		int myslot2 = GetIndexOfWeaponSlot(client, 2);
		if(myslot2 == 326)//Back Scratcher
		{
			CreateWeapon(client, "tf_weapon_fireaxe", 326, 6, 96, 2, paint);
		}
		if(myslot2 != 326)
		{
			CreateWeapon(client, "tf_weapon_fireaxe", 214, 6, 96, 2, paint);
		}
		return Plugin_Handled;
	}
	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_DemoMan)
	{
		if (!g_bMedieval)
		{
			if (paint > 14999 && paint < 15158)
			{
				if (paint == 15077 || paint == 15079 || paint == 15091 || paint == 15092 || paint == 15116 || paint == 15117 || paint == 15142 || paint == 15158)
				{
					CreateWeapon(client, "tf_weapon_grenadelauncher", paint, 6, 98, 0, 0);
				}
				else if (paint == 15009 || paint == 15012 || paint == 15024 || paint == 15038 || paint == 15045 || paint == 15048 || paint == 15082 || paint == 15083 || paint == 15084 || paint == 15113 || paint == 15137 || paint == 15138 || paint == 15155)
				{
					CreateWeapon(client, "tf_weapon_pipebomblauncher", 207, 6, 97, 1, 0);
				}				
				else
				{
					ReplyToCommand(client, "Invalid warpaint id for this player class.");
					return Plugin_Handled;
				}
				return Plugin_Handled;
			}

			int myslot0 = GetIndexOfWeaponSlot(client, 0);
			if(myslot0 == 308)//Loc n Load
			{
				CreateWeapon(client, "tf_weapon_grenadelauncher", 308, 6, 98, 0, paint);
			}
			if(myslot0 == 996)//Loose Cannon
			{
				CreateWeapon(client, "tf_weapon_cannon", 996, 6, 98, 0, paint);
			}
			if(myslot0 == 1151)//Iron Bomber
			{
				CreateWeapon(client, "tf_weapon_grenadelauncher", 1151, 6, 98, 0, paint);
			}
			if(myslot0 != 308 && myslot0 != 996 && myslot0 != 1151 && myslot0 > 0)
			{
				CreateWeapon(client, "tf_weapon_grenadelauncher", 206, 6, 98, 0, paint);
			}

			int myslot1 = GetIndexOfWeaponSlot(client, 1);
			if(myslot1 != -1)
			{
				CreateWeapon(client, "tf_weapon_pipebomblauncher", 207, 6, 97, 1, paint);
			}
		}

		if (paint > 14999)
		{
			return Plugin_Handled;
		}	
		
		int myslot2 = GetIndexOfWeaponSlot(client, 2);
		if(myslot2 == 172)//Scotsmans Skullcutter
		{
			CreateWeapon(client, "tf_weapon_sword", 172, 6, 96, 2, paint);
		}
		if(myslot2 == 327)//Claidheamh Mor
		{
			CreateWeapon(client, "tf_weapon_sword", 327, 6, 96, 2, paint);
		}		
		if(myslot2 != 172 && myslot2 != 327)
		{
			CreateWeapon(client, "tf_weapon_sword", 404, 6, 96, 2, paint);
		}
		return Plugin_Handled;		
	}		
	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Heavy)
	{
		if (!g_bMedieval)
		{
			if (paint > 14999 && paint < 15158)
			{
				if (paint == 15004 || paint == 15020 || paint == 15026 || paint == 15031 || paint == 15040 || paint == 15055 || paint == 15086 || paint == 15087 || paint == 15088 || paint == 15098 || paint == 15099 || paint == 15123 || paint == 15124 || paint == 15147)
				{
					CreateWeapon(client, "tf_weapon_minigun", paint, 6, 98, 0, 0);
				}
				else if (paint == 15003 || paint == 15016 || paint == 15044 || paint == 15047 || paint == 15085 || paint == 15109 || paint == 15132 || paint == 15133 || paint == 15152)
				{
					CreateWeapon(client, "tf_weapon_shotgun_hwg", paint, 6, 99, 1, 0);
				}				
				else
				{
					ReplyToCommand(client, "Invalid warpaint id for this player class.");
					return Plugin_Handled;
				}
				return Plugin_Handled;
			}

			int myslot0 = GetIndexOfWeaponSlot(client, 0);
			if(myslot0 == 312)//Brass Beast
			{
				CreateWeapon(client, "tf_weapon_minigun", 312, 6, 98, 0, paint);
			}
			if(myslot0 == 424)//Tomislav
			{
				CreateWeapon(client, "tf_weapon_minigun", 424, 6, 98, 0, paint);
			}
			if(myslot0 != 312 && myslot0 != 424)
			{
				CreateWeapon(client, "tf_weapon_minigun", 202, 6, 98, 0, paint);
			}

			int myslot1 = GetIndexOfWeaponSlot(client, 1);
			if(myslot1 == 425)//Family Business
			{
				CreateWeapon(client, "tf_weapon_shotgun_hwg", 425, 6, 97, 1, paint);
			}		
			if(myslot1 == 1153)//Panic Attack
			{
				CreateWeapon(client, "tf_weapon_shotgun_hwg", 1153, 6, 97, 1, paint);
			}
			if(myslot1 != 425 && myslot1 != 1153)
			{
				CreateWeapon(client, "tf_weapon_shotgun_hwg", 199, 6, 97, 1, paint);
			}
		}
		return Plugin_Handled;
	}
	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Engineer)
	{
		if (!g_bMedieval)
		{
			if (paint > 14999 && paint < 15158)
			{
				if (paint == 15003 || paint == 15016 || paint == 15044 || paint == 15047 || paint == 15085 || paint == 15109 || paint == 15132 || paint == 15133 || paint == 15152)
				{
					CreateWeapon(client, "tf_weapon_shotgun_primary", paint, 6, 99, 0, 0);
				}
				else if (paint == 15013 || paint == 15018 || paint == 15035 || paint == 15041 || paint == 15046 || paint == 15056 || paint == 15060 || paint == 15061 || paint == 15100 || paint == 15101 || paint == 15102 || paint == 15126 || paint == 15148)
				{
					CreateWeapon(client, "tf_weapon_pistol", paint, 6, 97, 1, 0);
				}
				else if (paint == 15073 || paint == 15074 || paint == 15075 || paint == 15139 || paint == 15140 || paint == 15114 || paint == 15156)
				{
					CreateWeapon(client, "tf_weapon_wrench", paint, 6, 96, 2, 0);
				}				
				else
				{
					ReplyToCommand(client, "Invalid warpaint id for this player class.");
					return Plugin_Handled;
				}
				return Plugin_Handled;
			}

			int myslot0 = GetIndexOfWeaponSlot(client, 0);
			if(myslot0 == 997)//Rescue Ranger
			{
				CreateWeapon(client, "tf_weapon_shotgun_building_rescue", 997, 6, 97, 1, paint);
			}
			if(myslot0 != 997)
			{
				CreateWeapon(client, "tf_weapon_shotgun_primary", 199, 6, 98, 0, paint);
			}

			CreateWeapon(client, "tf_weapon_pistol", 209, 6, 99, 1, paint);
		}
		
		if (paint > 14999)
		{
			if (paint == 15073 || paint == 15074 || paint == 15075 || paint == 15139 || paint == 15140 || paint == 15114 || paint == 15156)
			{
				CreateWeapon(client, "tf_weapon_wrench", paint, 6, 96, 2, 0);
			}
			return Plugin_Handled;
		}
		
		int myslot2 = GetIndexOfWeaponSlot(client, 2);
		if(myslot2 == 329)//Jag
		{
			CreateWeapon(client, "tf_weapon_wrench", 329, 6, 96, 2, paint);
		}
		if(myslot2 != 329)
		{
			CreateWeapon(client, "tf_weapon_wrench", 197, 6, 96, 2, paint);
		}
		return Plugin_Handled;
	}
	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Medic)
	{
		if (!g_bMedieval)
		{
			if (paint > 14999 && paint < 15158)
			{
				if (paint == 15008 || paint == 15010 || paint == 15025 || paint == 15039 || paint == 15050 || paint == 15078 || paint == 15097 || paint == 15121 || paint == 15122 || paint == 15123 || paint == 15145 || paint == 15146)
				{
					CreateWeapon(client, "tf_weapon_medigun", paint, 6, 99, 1, 0);
					return Plugin_Handled;
				}
			}

			CreateWeapon(client, "tf_weapon_medigun", 211, 6, 99, 1, paint);
		}

		if (paint > 14999)
		{
			return Plugin_Handled;
		}	

		CreateWeapon(client, "tf_weapon_crossbow", 305, 6, 99, 0, paint);
		
		int myslot2 = GetIndexOfWeaponSlot(client, 2);
		if(myslot2 == 37)//Ubersaw
		{
			CreateWeapon(client, "tf_weapon_bonesaw", 37, 6, 96, 2, paint);
		}
		if(myslot2 != 37)
		{
			CreateWeapon(client, "tf_weapon_bonesaw", 304, 6, 96, 2, paint);
		}
	}
	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Sniper)
	{
		if (!g_bMedieval)
		{
			if (paint > 14999 && paint < 15158)
			{
				if (paint == 15000 || paint == 15007 || paint == 15019 || paint == 15023 || paint == 15033 || paint == 15059 || paint == 15070 || paint == 15071 || paint == 15111 || paint == 15112 || paint == 15135 || paint == 15136 || paint == 15154)
				{
					CreateWeapon(client, "tf_weapon_sniperrifle", paint, 6, 99, 0, 0);
				}
				else if (paint == 15001 || paint == 15022 || paint == 15032 || paint == 15037 || paint == 15058 || paint == 15076 || paint == 15110 || paint == 15134 || paint == 15153)
				{
					CreateWeapon(client, "tf_weapon_smg", paint, 6, 99, 1, 0);
				}				
				else
				{
					ReplyToCommand(client, "Invalid warpaint id for this player class.");
					return Plugin_Handled;
				}
				return Plugin_Handled;
			}

			int myslot0 = GetIndexOfWeaponSlot(client, 0);

			if(myslot0 == 402)//Bazaar Bargain
			{
				CreateWeapon(client, "tf_weapon_sniperrifle_decap", 402, 6, 99, 0, paint);
			}
			if(myslot0 != 402)
			{
				CreateWeapon(client, "tf_weapon_sniperrifle", 201, 6, 99, 0, paint);
			}		

			int myslot1 = GetIndexOfWeaponSlot(client, 1);
			if(myslot1 > 0) //NOT Razorback, danger shield, or cozy camper
			{
				CreateWeapon(client, "tf_weapon_smg", 203, 6, 99, 1, paint);
			}
		}
		
		if (paint > 14999)
		{
			return Plugin_Handled;
		}

		CreateWeapon(client, "tf_weapon_club", 401, 6, 96, 2, paint);
	}
	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Spy)
	{
		if (!g_bMedieval)
		{		
			if (paint > 14999 && paint < 15158)
			{
				if (paint == 15011 || paint == 15027 || paint == 15042 || paint == 15051 || paint == 15062 || paint == 15063 || paint == 15064 || paint == 15103 || paint == 15128 || paint == 15127 || paint == 15149)
				{
					CreateWeapon(client, "tf_weapon_revolver", paint, 6, 99, 0, 0);
				}
				else if (paint == 15062 || paint == 15094 || paint == 15095 || paint == 15096 || paint == 15118 || paint == 15119 || paint == 15143 || paint == 15144)
				{
					CreateWeapon(client, "tf_weapon_knife", paint, 6, 99, 2, 0);
				}				
				else
				{
					ReplyToCommand(client, "Invalid warpaint id for this player class.");
					return Plugin_Handled;
				}
				return Plugin_Handled;
			}
			
			
			CreateWeapon(client, "tf_weapon_revolver", 210, 6, 99, 0, paint);
		}
		
		if (paint == 15062 || paint == 15094 || paint == 15095 || paint == 15096 || paint == 15118 || paint == 15119 || paint == 15143 || paint == 15144)
		{
			CreateWeapon(client, "tf_weapon_knife", paint, 6, 99, 2, 0);
		}
		else
		{
			CreateWeapon(client, "tf_weapon_knife", 194, 6, 99, 2, paint);
			return Plugin_Handled;
		}
	}
	
	return Plugin_Handled;
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

	if (paint > 0)
	{
		TF2Attrib_SetByDefIndex(weapon, 834, view_as<float>(paint));	//Set Warpaint	
	}
	
	if(FindIfCanBeFestive(itemindex))
	{
		if(GetRandomInt(1,30) == 1) //festive check
		{
			TF2Attrib_SetByDefIndex(weapon, 2053, 1.0);
		}
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
	
	//TF2Attrib_SetByDefIndex(weapon, 725, GetRandomFloat(0.0,1.0));  //Weapon texture random wear
	TF2Attrib_SetByDefIndex(weapon, 725, 0.0);  //Weapon texture Factory New
	
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
		if (GetRandomUInt(1,5) == 1)
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
	}

	TF2_SwitchtoSlot(client, 0);
	
	return true;
}

Action MakeOP(int client) 
{
	g_bIsWarPainted[client] = true;
	
	TF2_SetHealth(client, 2000);	

	if (IsClientInGame(client) && TF2_GetPlayerClass(client) == TFClass_Engineer)
	{
		PrintToChat(client, "You are an overpowered Engineer");
		PrintToChat(client, "You will lose your powers when you touch a locker or die.");		

		TF2Attrib_SetByName(client, "max health additive bonus", 1875.0);
		TF2Attrib_SetByName(client, "major move speed bonus", 2.0);
		TF2Attrib_SetByName(client, "health regen", 5.0);	
		TF2Attrib_SetByName(client, "cancel falling damage", 1.0);			
		TF2Attrib_SetByName(client, "dmg taken from blast reduced", 0.7);
		TF2Attrib_SetByName(client, "dmg taken from fire reduced", 0.7);
		TF2Attrib_SetByName(client, "dmg taken from bullets reduced", 0.7);
		TF2Attrib_SetByName(client, "dmg taken from crit reduced", 0.7);
		TF2Attrib_SetByName(client, "dmg from ranged reduced", 0.7);
		TF2Attrib_SetByName(client, "SET BONUS: dmg from sentry reduced", 0.7);	
		TF2Attrib_SetByName(client, "damage force reduction", 0.7);				
		TF2Attrib_SetByName(client, "increase player capture value", 2.0);
		TF2Attrib_SetByName(client, "major increased jump height", 2.0);
		TF2Attrib_SetByName(client, "parachute attribute", 1.0);
		TF2Attrib_SetByName(client, "increased air control", 12.0);	
		TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.7);
		TF2Attrib_SetByName(client, "airblast vertical vulnerability multiplier", 0.7);
		
		int Weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		if(IsValidEntity(Weapon))
		{
			TF2Attrib_SetByName(Weapon, "fire rate bonus", 0.3);	
			TF2Attrib_SetByName(Weapon, "faster reload rate", 0.2);
			TF2Attrib_SetByName(Weapon, "damage bonus", 5.0);
			TF2Attrib_SetByName(Weapon, "no self blast dmg", 2.0);				
			TF2Attrib_SetByName(Weapon, "projectile penetration", 1.0);
			TF2Attrib_SetByName(Weapon, "attack projectiles", 1.0);				
			TF2Attrib_SetByName(Weapon, "maxammo primary increased", 3.0);
			TF2Attrib_SetByName(Weapon, "clip size bonus", 5.0);
			TF2Attrib_SetByName(Weapon, "armor piercing", 20.0);
			TF2Attrib_SetByName(Weapon, "ammo regen", 2.0);
			TF2Attrib_SetByName(Weapon, "killstreak tier", 3.0);
			TF2Attrib_SetByName(Weapon, "killstreak effect", 2005.0);
			TF2Attrib_SetByName(Weapon, "killstreak idleeffect", 7.0);
		}
		int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if(IsValidEntity(Weapon2))
		{
			TF2Attrib_SetByName(Weapon2, "fire rate bonus", 0.3);	
			TF2Attrib_SetByName(Weapon2, "faster reload rate", 0.2);
			TF2Attrib_SetByName(Weapon2, "damage bonus", 5.0);
			TF2Attrib_SetByName(Weapon2, "projectile penetration", 1.0);
			TF2Attrib_SetByName(Weapon2, "attack projectiles", 1.0);				
			TF2Attrib_SetByName(Weapon2, "maxammo secondary increased", 3.0);
			TF2Attrib_SetByName(Weapon2, "clip size bonus", 5.0);
			TF2Attrib_SetByName(Weapon2, "armor piercing", 20.0);
			TF2Attrib_SetByName(Weapon2, "ammo regen", 2.0);
			TF2Attrib_SetByName(Weapon2, "no self blast dmg", 2.0);	
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
			TF2Attrib_SetByName(Weapon3, "armor piercing", 20.0);

			TF2Attrib_SetByName(Weapon3, "maxammo metal increased", 5.0);				
			TF2Attrib_SetByName(Weapon3, "metal regen", 20.0);	
			TF2Attrib_SetByName(Weapon3, "speed buff ally", 1.0);
			TF2Attrib_SetByName(Weapon3, "killstreak tier", 3.0);
			TF2Attrib_SetByName(Weapon3, "killstreak effect", 2005.0);
			TF2Attrib_SetByName(Weapon3, "killstreak idleeffect", 7.0);			
		}
		int Weapon4 = GetPlayerWeaponSlot(client, TFWeaponSlot_PDA);
		if(IsValidEntity(Weapon4))
		{
			TF2Attrib_SetByName(Weapon4, "engy sentry fire rate increased", 0.6);					
			TF2Attrib_SetByName(Weapon4, "engy sentry radius increased", 3.0);
			TF2Attrib_SetByName(Weapon4, "engy dispenser radius increased", 3.0);
			TF2Attrib_SetByName(Weapon4, "armor piercing", 20.0);
			TF2Attrib_SetByName(Weapon4, "has pipboy build interface", 1.0);
			TF2Attrib_SetByName(Weapon4, "bidirectional teleport", 1.0);
			TF2Attrib_SetByName(Weapon4, "engy sentry damage bonus", 5.0);	
			TF2Attrib_SetByName(Weapon4, "engy building health bonus", 3.0);
			TF2Attrib_SetByName(Weapon4, "maxammo metal increased", 2.0);
			TF2Attrib_SetByName(Weapon4, "metal regen", 10.0);	
			TF2Attrib_SetByName(Weapon4, "repair rate increased", 3.0);				
		}
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 5.0);		
		return Plugin_Handled;	
	}
	if (TF2_GetPlayerClass(client) == TFClass_Pyro)
	{
		PrintToChat(client, "You are an overpowered Pyro");
		PrintToChat(client, "You will lose your powers when you touch a locker or die.");		

		TF2Attrib_SetByName(client, "max health additive bonus", 1825.0);
		TF2Attrib_SetByName(client, "major move speed bonus", 2.0);
		TF2Attrib_SetByName(client, "health regen", 5.0);	
		TF2Attrib_SetByName(client, "cancel falling damage", 1.0);			
		TF2Attrib_SetByName(client, "dmg taken from blast reduced", 0.7);
		TF2Attrib_SetByName(client, "dmg taken from fire reduced", 0.7);
		TF2Attrib_SetByName(client, "dmg taken from bullets reduced", 0.7);
		TF2Attrib_SetByName(client, "dmg taken from crit reduced", 0.7);
		TF2Attrib_SetByName(client, "dmg from ranged reduced", 0.7);
		TF2Attrib_SetByName(client, "SET BONUS: dmg from sentry reduced", 0.7);	
		TF2Attrib_SetByName(client, "damage force reduction", 0.7);				
		TF2Attrib_SetByName(client, "increase player capture value", 2.0);
		TF2Attrib_SetByName(client, "major increased jump height", 2.0);
		TF2Attrib_SetByName(client, "parachute attribute", 1.0);
		TF2Attrib_SetByName(client, "increased air control", 12.0);	
		TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.7);
		TF2Attrib_SetByName(client, "airblast vertical vulnerability multiplier", 0.7);
		
		int Weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		if(IsValidEntity(Weapon))
		{
			TF2Attrib_SetByName(Weapon, "damage bonus", 5.0);
			TF2Attrib_SetByName(Weapon, "maxammo primary increased", 3.0);
			TF2Attrib_SetByName(Weapon, "armor piercing", 20.0);
			TF2Attrib_SetByName(Weapon, "clip size bonus", 5.0);			
			TF2Attrib_SetByName(Weapon, "ammo regen", 2.0);
			TF2Attrib_SetByName(Weapon, "killstreak tier", 3.0);
			TF2Attrib_SetByName(Weapon, "killstreak effect", 2005.0);
			TF2Attrib_SetByName(Weapon, "killstreak idleeffect", 7.0);
			TF2Attrib_SetByName(Weapon, "mult_item_meter_charge_rate", 0.2);
			TF2Attrib_SetByName(Weapon, "reveal disguised victim on hit", 1.0);
			TF2Attrib_SetByName(Weapon, "SPELL: Halloween green flames", 1.0);
			TF2Attrib_SetByName(Weapon, "airblast_give_teammate_speed_boost", 1.0);			
		}
		int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if(IsValidEntity(Weapon2))
		{
			TF2Attrib_SetByName(Weapon2, "fire rate bonus", 0.3);	
			TF2Attrib_SetByName(Weapon2, "faster reload rate", 0.2);
			TF2Attrib_SetByName(Weapon2, "damage bonus", 5.0);
			TF2Attrib_SetByName(Weapon2, "projectile penetration", 1.0);
			TF2Attrib_SetByName(Weapon2, "attack projectiles", 1.0);				
			TF2Attrib_SetByName(Weapon2, "maxammo secondary increased", 3.0);
			TF2Attrib_SetByName(Weapon2, "clip size bonus", 5.0);
			TF2Attrib_SetByName(Weapon2, "armor piercing", 20.0);
			TF2Attrib_SetByName(Weapon2, "ammo regen", 2.0);
			TF2Attrib_SetByName(Weapon2, "no self blast dmg", 2.0);	
			TF2Attrib_SetByName(Weapon2, "killstreak tier", 3.0);
			TF2Attrib_SetByName(Weapon2, "killstreak effect", 2005.0);
			TF2Attrib_SetByName(Weapon2, "killstreak idleeffect", 7.0);	
			TF2Attrib_SetByName(Weapon2, "mult_item_meter_charge_rate", 0.001);
			TF2Attrib_SetByName(Weapon2, "explode_on_ignite", 1.0);
			TF2Attrib_SetByName(Weapon2, "thermal_thruster_air_launch", 1.0);			
		}
		int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		if(IsValidEntity(Weapon3))
		{
			TF2Attrib_SetByName(Weapon3, "melee attack rate bonus", 0.4);	
			TF2Attrib_SetByName(Weapon3, "melee bounds multiplier", 2.0);					
			TF2Attrib_SetByName(Weapon3, "melee range multiplier", 2.0);
			TF2Attrib_SetByName(Weapon3, "damage bonus", 5.0);
			TF2Attrib_SetByName(Weapon3, "armor piercing", 20.0);
			TF2Attrib_SetByName(Weapon3, "speed buff ally", 1.0);
			TF2Attrib_SetByName(Weapon3, "killstreak tier", 3.0);
			TF2Attrib_SetByName(Weapon3, "killstreak effect", 2005.0);
			TF2Attrib_SetByName(Weapon3, "killstreak idleeffect", 7.0);				
		}
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 5.0);
		return Plugin_Handled;	
	}
	if (TF2_GetPlayerClass(client) == TFClass_Soldier)
	{
		PrintToChat(client, "You are an overpowered Soldier");
		PrintToChat(client, "You will lose your powers when you touch a locker or die.");		

		TF2Attrib_SetByName(client, "max health additive bonus", 1800.0);
		TF2Attrib_SetByName(client, "major move speed bonus", 2.0);
		TF2Attrib_SetByName(client, "health regen", 5.0);	
		TF2Attrib_SetByName(client, "cancel falling damage", 1.0);			
		TF2Attrib_SetByName(client, "dmg taken from blast reduced", 0.7);
		TF2Attrib_SetByName(client, "dmg taken from fire reduced", 0.7);
		TF2Attrib_SetByName(client, "dmg taken from bullets reduced", 0.7);
		TF2Attrib_SetByName(client, "dmg taken from crit reduced", 0.7);
		TF2Attrib_SetByName(client, "dmg from ranged reduced", 0.7);
		TF2Attrib_SetByName(client, "SET BONUS: dmg from sentry reduced", 0.7);	
		TF2Attrib_SetByName(client, "damage force reduction", 0.7);				
		TF2Attrib_SetByName(client, "increase player capture value", 2.0);
		TF2Attrib_SetByName(client, "major increased jump height", 2.0);
		TF2Attrib_SetByName(client, "parachute attribute", 1.0);
		TF2Attrib_SetByName(client, "increased air control", 12.0);	
		TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.7);
		TF2Attrib_SetByName(client, "airblast vertical vulnerability multiplier", 0.7);
		
		int Weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		if(IsValidEntity(Weapon))
		{
			TF2Attrib_SetByName(Weapon, "fire rate bonus", 0.3);	
			TF2Attrib_SetByName(Weapon, "faster reload rate", 0.2);
			TF2Attrib_SetByName(Weapon, "damage bonus", 5.0);
			TF2Attrib_SetByName(Weapon, "no self blast dmg", 2.0);				
			TF2Attrib_SetByName(Weapon, "projectile penetration", 1.0);
			TF2Attrib_SetByName(Weapon, "attack projectiles", 1.0);				
			TF2Attrib_SetByName(Weapon, "maxammo primary increased", 3.0);
			TF2Attrib_SetByName(Weapon, "clip size bonus", 5.0);
			TF2Attrib_SetByName(Weapon, "armor piercing", 20.0);
			TF2Attrib_SetByName(Weapon, "ammo regen", 2.0);
			TF2Attrib_SetByName(Weapon, "killstreak tier", 3.0);
			TF2Attrib_SetByName(Weapon, "killstreak effect", 2005.0);
			TF2Attrib_SetByName(Weapon, "killstreak idleeffect", 7.0);
			TF2Attrib_SetByName(Weapon, "blast radius increased", 3.0);
			TF2Attrib_SetByName(Weapon, "can overload", 0.0);
			TF2Attrib_SetByName(Weapon, "SPELL: Halloween pumpkin explosions", 1.0);			
		}
		int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if(IsValidEntity(Weapon2))
		{
			TF2Attrib_SetByName(Weapon2, "fire rate bonus", 0.3);	
			TF2Attrib_SetByName(Weapon2, "faster reload rate", 0.2);
			TF2Attrib_SetByName(Weapon2, "damage bonus", 5.0);
			TF2Attrib_SetByName(Weapon2, "projectile penetration", 1.0);
			TF2Attrib_SetByName(Weapon2, "attack projectiles", 1.0);				
			TF2Attrib_SetByName(Weapon2, "maxammo secondary increased", 3.0);
			TF2Attrib_SetByName(Weapon2, "clip size bonus", 5.0);
			TF2Attrib_SetByName(Weapon2, "armor piercing", 20.0);
			TF2Attrib_SetByName(Weapon2, "ammo regen", 2.0);
			TF2Attrib_SetByName(Weapon2, "no self blast dmg", 2.0);	
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
			TF2Attrib_SetByName(Weapon3, "armor piercing", 20.0);
			TF2Attrib_SetByName(Weapon3, "speed buff ally", 1.0);
			TF2Attrib_SetByName(Weapon3, "killstreak tier", 3.0);
			TF2Attrib_SetByName(Weapon3, "killstreak effect", 2005.0);
			TF2Attrib_SetByName(Weapon3, "killstreak idleeffect", 7.0);				
		}
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 5.0);
		return Plugin_Handled;
	}
	if (TF2_GetPlayerClass(client) == TFClass_Sniper)
	{
		PrintToChat(client, "You are an overpowered Sniper");
		PrintToChat(client, "You will lose your powers when you touch a locker or die.");		

		TF2Attrib_SetByName(client, "max health additive bonus", 1875.0);
		TF2Attrib_SetByName(client, "major move speed bonus", 2.0);
		TF2Attrib_SetByName(client, "health regen", 5.0);	
		TF2Attrib_SetByName(client, "cancel falling damage", 1.0);			
		TF2Attrib_SetByName(client, "dmg taken from blast reduced", 0.7);
		TF2Attrib_SetByName(client, "dmg taken from fire reduced", 0.7);
		TF2Attrib_SetByName(client, "dmg taken from bullets reduced", 0.7);
		TF2Attrib_SetByName(client, "dmg taken from crit reduced", 0.7);
		TF2Attrib_SetByName(client, "dmg from ranged reduced", 0.7);
		TF2Attrib_SetByName(client, "SET BONUS: dmg from sentry reduced", 0.7);	
		TF2Attrib_SetByName(client, "damage force reduction", 0.7);				
		TF2Attrib_SetByName(client, "increase player capture value", 2.0);
		TF2Attrib_SetByName(client, "major increased jump height", 2.0);
		TF2Attrib_SetByName(client, "parachute attribute", 1.0);
		TF2Attrib_SetByName(client, "increased air control", 12.0);	
		TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.7);
		TF2Attrib_SetByName(client, "airblast vertical vulnerability multiplier", 0.7);
		
		int Weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		if(IsValidEntity(Weapon))
		{
			TF2Attrib_SetByName(Weapon, "fire rate bonus", 0.3);	
			TF2Attrib_SetByName(Weapon, "faster reload rate", 0.2);
			TF2Attrib_SetByName(Weapon, "damage bonus", 5.0);
			TF2Attrib_SetByName(Weapon, "no self blast dmg", 2.0);				
			TF2Attrib_SetByName(Weapon, "projectile penetration", 1.0);
			TF2Attrib_SetByName(Weapon, "attack projectiles", 1.0);				
			TF2Attrib_SetByName(Weapon, "maxammo primary increased", 3.0);
			TF2Attrib_SetByName(Weapon, "clip size bonus", 5.0);
			TF2Attrib_SetByName(Weapon, "armor piercing", 20.0);
			TF2Attrib_SetByName(Weapon, "ammo regen", 2.0);
			TF2Attrib_SetByName(Weapon, "killstreak tier", 3.0);
			TF2Attrib_SetByName(Weapon, "killstreak effect", 2005.0);
			TF2Attrib_SetByName(Weapon, "killstreak idleeffect", 7.0);
			TF2Attrib_SetByName(Weapon, "headshot damage increase", 3.0);			
		}
		int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if(IsValidEntity(Weapon2))
		{
			TF2Attrib_SetByName(Weapon2, "fire rate bonus", 0.3);	
			TF2Attrib_SetByName(Weapon2, "faster reload rate", 0.2);
			TF2Attrib_SetByName(Weapon2, "damage bonus", 5.0);
			TF2Attrib_SetByName(Weapon2, "projectile penetration", 1.0);
			TF2Attrib_SetByName(Weapon2, "attack projectiles", 1.0);				
			TF2Attrib_SetByName(Weapon2, "maxammo secondary increased", 3.0);
			TF2Attrib_SetByName(Weapon2, "clip size bonus", 5.0);
			TF2Attrib_SetByName(Weapon2, "armor piercing", 20.0);
			TF2Attrib_SetByName(Weapon2, "ammo regen", 2.0);
			TF2Attrib_SetByName(Weapon2, "no self blast dmg", 2.0);	
			TF2Attrib_SetByName(Weapon2, "killstreak tier", 3.0);
			TF2Attrib_SetByName(Weapon2, "killstreak effect", 2005.0);
			TF2Attrib_SetByName(Weapon2, "killstreak idleeffect", 7.0);	
			TF2Attrib_SetByName(Weapon2, "effect bar recharge rate increased", 0.001);			
		}
		int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		if(IsValidEntity(Weapon3))
		{
			TF2Attrib_SetByName(Weapon3, "melee attack rate bonus", 0.4);	
			TF2Attrib_SetByName(Weapon3, "melee bounds multiplier", 2.0);					
			TF2Attrib_SetByName(Weapon3, "melee range multiplier", 2.0);
			TF2Attrib_SetByName(Weapon3, "damage bonus", 5.0);
			TF2Attrib_SetByName(Weapon3, "armor piercing", 20.0);
			TF2Attrib_SetByName(Weapon3, "speed buff ally", 1.0);
			TF2Attrib_SetByName(Weapon3, "killstreak tier", 3.0);
			TF2Attrib_SetByName(Weapon3, "killstreak effect", 2005.0);
			TF2Attrib_SetByName(Weapon3, "killstreak idleeffect", 7.0);				
		}
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 5.0);
		return Plugin_Handled;	
	}
	if (TF2_GetPlayerClass(client) == TFClass_Medic)
	{
		PrintToChat(client, "You are an overpowered Medic");
		PrintToChat(client, "You will lose your powers when you touch a locker or die.");		

		TF2Attrib_SetByName(client, "max health additive bonus", 1850.0);
		TF2Attrib_SetByName(client, "major move speed bonus", 2.0);
		TF2Attrib_SetByName(client, "health regen", 5.0);	
		TF2Attrib_SetByName(client, "cancel falling damage", 1.0);			
		TF2Attrib_SetByName(client, "dmg taken from blast reduced", 0.7);
		TF2Attrib_SetByName(client, "dmg taken from fire reduced", 0.7);
		TF2Attrib_SetByName(client, "dmg taken from bullets reduced", 0.7);
		TF2Attrib_SetByName(client, "dmg taken from crit reduced", 0.7);
		TF2Attrib_SetByName(client, "dmg from ranged reduced", 0.7);
		TF2Attrib_SetByName(client, "SET BONUS: dmg from sentry reduced", 0.7);	
		TF2Attrib_SetByName(client, "damage force reduction", 0.7);				
		TF2Attrib_SetByName(client, "increase player capture value", 2.0);
		TF2Attrib_SetByName(client, "major increased jump height", 2.0);
		TF2Attrib_SetByName(client, "parachute attribute", 1.0);
		TF2Attrib_SetByName(client, "increased air control", 12.0);	
		TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.7);
		TF2Attrib_SetByName(client, "airblast vertical vulnerability multiplier", 0.7);
		
		int Weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		if(IsValidEntity(Weapon))
		{
			TF2Attrib_SetByName(Weapon, "fire rate bonus", 0.3);	
			TF2Attrib_SetByName(Weapon, "faster reload rate", 0.2);
			TF2Attrib_SetByName(Weapon, "damage bonus", 5.0);
			TF2Attrib_SetByName(Weapon, "no self blast dmg", 2.0);				
			TF2Attrib_SetByName(Weapon, "projectile penetration", 1.0);
			TF2Attrib_SetByName(Weapon, "attack projectiles", 1.0);				
			TF2Attrib_SetByName(Weapon, "maxammo primary increased", 3.0);
			TF2Attrib_SetByName(Weapon, "clip size bonus", 5.0);
			TF2Attrib_SetByName(Weapon, "armor piercing", 20.0);
			TF2Attrib_SetByName(Weapon, "ammo regen", 2.0);
			TF2Attrib_SetByName(Weapon, "killstreak tier", 3.0);
			TF2Attrib_SetByName(Weapon, "killstreak effect", 2005.0);
			TF2Attrib_SetByName(Weapon, "killstreak idleeffect", 7.0);
		}
		int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if(IsValidEntity(Weapon2))
		{
			TF2Attrib_SetByName(Weapon2, "generate rage on heal", 1.0);
			TF2Attrib_SetByName(Weapon2, "medigun charge is megaheal", 1.0);
			TF2Attrib_SetByName(Weapon2, "ubercharge rate bonus", 10.0);
			TF2Attrib_SetByName(Weapon2, "overheal bonus", 2.0);
			TF2Attrib_SetByName(Weapon2, "ubercharge rate bonus for healer", 2.0);
			TF2Attrib_SetByName(Weapon2, "heal rate bonus", 5.0);			
		}
		int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		if(IsValidEntity(Weapon3))
		{
			TF2Attrib_SetByName(Weapon3, "melee attack rate bonus", 0.4);	
			TF2Attrib_SetByName(Weapon3, "melee bounds multiplier", 2.0);					
			TF2Attrib_SetByName(Weapon3, "melee range multiplier", 2.0);
			TF2Attrib_SetByName(Weapon3, "damage bonus", 5.0);
			TF2Attrib_SetByName(Weapon3, "armor piercing", 20.0);
			TF2Attrib_SetByName(Weapon3, "speed buff ally", 1.0);
			TF2Attrib_SetByName(Weapon3, "killstreak tier", 3.0);
			TF2Attrib_SetByName(Weapon3, "killstreak effect", 2005.0);
			TF2Attrib_SetByName(Weapon3, "killstreak idleeffect", 7.0);				
		}
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 5.0);
		return Plugin_Handled;			
	}
	if (TF2_GetPlayerClass(client) == TFClass_DemoMan)
	{
		PrintToChat(client, "You are an overpowered DemoMan");
		PrintToChat(client, "You will lose your powers when you touch a locker or die.");		

		TF2Attrib_SetByName(client, "max health additive bonus", 1800.0);
		TF2Attrib_SetByName(client, "major move speed bonus", 2.0);
		TF2Attrib_SetByName(client, "health regen", 5.0);	
		TF2Attrib_SetByName(client, "cancel falling damage", 1.0);			
		TF2Attrib_SetByName(client, "dmg taken from blast reduced", 0.7);
		TF2Attrib_SetByName(client, "dmg taken from fire reduced", 0.7);
		TF2Attrib_SetByName(client, "dmg taken from bullets reduced", 0.7);
		TF2Attrib_SetByName(client, "dmg taken from crit reduced", 0.7);
		TF2Attrib_SetByName(client, "dmg from ranged reduced", 0.7);
		TF2Attrib_SetByName(client, "SET BONUS: dmg from sentry reduced", 0.7);	
		TF2Attrib_SetByName(client, "damage force reduction", 0.7);				
		TF2Attrib_SetByName(client, "increase player capture value", 2.0);
		TF2Attrib_SetByName(client, "major increased jump height", 2.0);
		TF2Attrib_SetByName(client, "parachute attribute", 1.0);
		TF2Attrib_SetByName(client, "increased air control", 12.0);	
		TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.7);
		TF2Attrib_SetByName(client, "airblast vertical vulnerability multiplier", 0.7);
		
		int Weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		if(IsValidEntity(Weapon))
		{
			TF2Attrib_SetByName(Weapon, "fire rate bonus", 0.3);	
			TF2Attrib_SetByName(Weapon, "faster reload rate", 0.2);
			TF2Attrib_SetByName(Weapon, "damage bonus", 5.0);
			TF2Attrib_SetByName(Weapon, "no self blast dmg", 2.0);				
			TF2Attrib_SetByName(Weapon, "projectile penetration", 1.0);
			TF2Attrib_SetByName(Weapon, "attack projectiles", 1.0);				
			TF2Attrib_SetByName(Weapon, "maxammo primary increased", 3.0);
			TF2Attrib_SetByName(Weapon, "clip size bonus", 5.0);
			TF2Attrib_SetByName(Weapon, "armor piercing", 20.0);
			TF2Attrib_SetByName(Weapon, "ammo regen", 2.0);
			TF2Attrib_SetByName(Weapon, "killstreak tier", 3.0);
			TF2Attrib_SetByName(Weapon, "killstreak effect", 2005.0);
			TF2Attrib_SetByName(Weapon, "killstreak idleeffect", 7.0);
			TF2Attrib_SetByName(Weapon, "blast radius increased", 3.0);
			TF2Attrib_SetByName(Weapon, "Projectile speed increased", 3.0);
			TF2Attrib_SetByName(Weapon, "Projectile range increased", 3.0);
		}
		int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if(IsValidEntity(Weapon2))
		{
			TF2Attrib_SetByName(Weapon2, "fire rate bonus", 0.3);	
			TF2Attrib_SetByName(Weapon2, "faster reload rate", 0.2);
			TF2Attrib_SetByName(Weapon2, "damage bonus", 5.0);
			TF2Attrib_SetByName(Weapon2, "projectile penetration", 1.0);
			TF2Attrib_SetByName(Weapon2, "attack projectiles", 1.0);				
			TF2Attrib_SetByName(Weapon2, "maxammo secondary increased", 3.0);
			TF2Attrib_SetByName(Weapon2, "clip size bonus", 5.0);
			TF2Attrib_SetByName(Weapon2, "armor piercing", 20.0);
			TF2Attrib_SetByName(Weapon2, "ammo regen", 2.0);
			TF2Attrib_SetByName(Weapon2, "no self blast dmg", 2.0);	
			TF2Attrib_SetByName(Weapon2, "killstreak tier", 3.0);
			TF2Attrib_SetByName(Weapon2, "killstreak effect", 2005.0);
			TF2Attrib_SetByName(Weapon2, "killstreak idleeffect", 7.0);	
			TF2Attrib_SetByName(Weapon2, "charge time increased", 5.0);
			TF2Attrib_SetByName(Weapon2, "no charge impact range", 1.0);
			TF2Attrib_SetByName(Weapon2, "charge impact damage increased", 5.0);
			TF2Attrib_SetByName(Weapon2, "charge recharge rate increased", 5.0);	
			TF2Attrib_SetByName(Weapon2, "mult charge turn control", 5.0);			
		}
		int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		if(IsValidEntity(Weapon3))
		{
			TF2Attrib_SetByName(Weapon3, "melee attack rate bonus", 0.4);	
			TF2Attrib_SetByName(Weapon3, "melee bounds multiplier", 2.0);					
			TF2Attrib_SetByName(Weapon3, "melee range multiplier", 2.0);
			TF2Attrib_SetByName(Weapon3, "damage bonus", 5.0);
			TF2Attrib_SetByName(Weapon3, "armor piercing", 20.0);
			TF2Attrib_SetByName(Weapon3, "speed buff ally", 1.0);
			TF2Attrib_SetByName(Weapon3, "killstreak tier", 3.0);
			TF2Attrib_SetByName(Weapon3, "killstreak effect", 2005.0);
			TF2Attrib_SetByName(Weapon3, "killstreak idleeffect", 7.0);	
		}
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 5.0);
		return Plugin_Handled;			
	}
	if (TF2_GetPlayerClass(client) == TFClass_Spy)
	{
		PrintToChat(client, "You are an overpowered Spy");
		PrintToChat(client, "You will lose your powers when you touch a locker or die.");

		TF2Attrib_SetByName(client, "max health additive bonus", 1875.0);
		TF2Attrib_SetByName(client, "major move speed bonus", 2.0);
		TF2Attrib_SetByName(client, "health regen", 5.0);	
		TF2Attrib_SetByName(client, "cancel falling damage", 1.0);			
		TF2Attrib_SetByName(client, "dmg taken from blast reduced", 0.7);
		TF2Attrib_SetByName(client, "dmg taken from fire reduced", 0.7);
		TF2Attrib_SetByName(client, "dmg taken from bullets reduced", 0.7);
		TF2Attrib_SetByName(client, "dmg taken from crit reduced", 0.7);
		TF2Attrib_SetByName(client, "dmg from ranged reduced", 0.7);
		TF2Attrib_SetByName(client, "SET BONUS: dmg from sentry reduced", 0.7);	
		TF2Attrib_SetByName(client, "damage force reduction", 0.7);				
		TF2Attrib_SetByName(client, "increase player capture value", 2.0);
		TF2Attrib_SetByName(client, "major increased jump height", 2.0);
		TF2Attrib_SetByName(client, "parachute attribute", 1.0);
		TF2Attrib_SetByName(client, "increased air control", 12.0);	
		TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.7);
		TF2Attrib_SetByName(client, "airblast vertical vulnerability multiplier", 0.7);	
		
		int Weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		if(IsValidEntity(Weapon))
		{
			TF2Attrib_SetByName(Weapon, "fire rate bonus", 0.3);	
			TF2Attrib_SetByName(Weapon, "faster reload rate", 0.2);
			TF2Attrib_SetByName(Weapon, "damage bonus", 5.0);
			TF2Attrib_SetByName(Weapon, "no self blast dmg", 2.0);				
			TF2Attrib_SetByName(Weapon, "projectile penetration", 1.0);
			TF2Attrib_SetByName(Weapon, "attack projectiles", 1.0);				
			TF2Attrib_SetByName(Weapon, "maxammo primary increased", 3.0);
			TF2Attrib_SetByName(Weapon, "clip size bonus", 5.0);
			TF2Attrib_SetByName(Weapon, "armor piercing", 20.0);
			TF2Attrib_SetByName(Weapon, "ammo regen", 2.0);
			TF2Attrib_SetByName(Weapon, "killstreak tier", 3.0);
			TF2Attrib_SetByName(Weapon, "killstreak effect", 2005.0);
			TF2Attrib_SetByName(Weapon, "killstreak idleeffect", 7.0);
			TF2Attrib_SetByName(Weapon, "blast radius increased", 3.0);
			TF2Attrib_SetByName(Weapon, "Projectile speed increased", 3.0);
			TF2Attrib_SetByName(Weapon, "Projectile range increased", 3.0);
		}
		int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if(IsValidEntity(Weapon2))
		{
			TF2Attrib_SetByName(Weapon2, "fire rate bonus", 0.3);	
			TF2Attrib_SetByName(Weapon2, "faster reload rate", 0.2);
			TF2Attrib_SetByName(Weapon2, "damage bonus", 5.0);
			TF2Attrib_SetByName(Weapon2, "projectile penetration", 1.0);
			TF2Attrib_SetByName(Weapon2, "attack projectiles", 1.0);				
			TF2Attrib_SetByName(Weapon2, "maxammo secondary increased", 3.0);
			TF2Attrib_SetByName(Weapon2, "clip size bonus", 5.0);
			TF2Attrib_SetByName(Weapon2, "armor piercing", 20.0);
			TF2Attrib_SetByName(Weapon2, "ammo regen", 2.0);
			TF2Attrib_SetByName(Weapon2, "no self blast dmg", 2.0);	
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
			TF2Attrib_SetByName(Weapon3, "armor piercing", 20.0);
			TF2Attrib_SetByName(Weapon3, "speed buff ally", 1.0);
			TF2Attrib_SetByName(Weapon3, "killstreak tier", 3.0);
			TF2Attrib_SetByName(Weapon3, "killstreak effect", 2005.0);
			TF2Attrib_SetByName(Weapon3, "killstreak idleeffect", 7.0);				
		}
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 5.0);
		return Plugin_Handled;			
	}

	if (TF2_GetPlayerClass(client) == TFClass_Heavy)
	{
		PrintToChat(client, "You are an overpowered Heavy");
		PrintToChat(client, "You will lose your powers when you touch a locker or die.");

		TF2Attrib_SetByName(client, "max health additive bonus", 1700.0);
		TF2Attrib_SetByName(client, "major move speed bonus", 2.0);
		TF2Attrib_SetByName(client, "health regen", 5.0);	
		TF2Attrib_SetByName(client, "cancel falling damage", 1.0);			
		TF2Attrib_SetByName(client, "dmg taken from blast reduced", 0.7);
		TF2Attrib_SetByName(client, "dmg taken from fire reduced", 0.7);
		TF2Attrib_SetByName(client, "dmg taken from bullets reduced", 0.7);
		TF2Attrib_SetByName(client, "dmg taken from crit reduced", 0.7);
		TF2Attrib_SetByName(client, "dmg from ranged reduced", 0.7);
		TF2Attrib_SetByName(client, "SET BONUS: dmg from sentry reduced", 0.7);	
		TF2Attrib_SetByName(client, "damage force reduction", 0.7);				
		TF2Attrib_SetByName(client, "increase player capture value", 2.0);
		TF2Attrib_SetByName(client, "major increased jump height", 2.0);
		TF2Attrib_SetByName(client, "parachute attribute", 1.0);
		TF2Attrib_SetByName(client, "increased air control", 12.0);	
		TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.7);
		TF2Attrib_SetByName(client, "airblast vertical vulnerability multiplier", 0.7);
		
		int Weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		if(IsValidEntity(Weapon))
		{
			TF2Attrib_SetByName(Weapon, "fire rate bonus", 0.3);	
			TF2Attrib_SetByName(Weapon, "faster reload rate", 0.2);
			TF2Attrib_SetByName(Weapon, "damage bonus", 5.0);
			TF2Attrib_SetByName(Weapon, "no self blast dmg", 2.0);				
			TF2Attrib_SetByName(Weapon, "projectile penetration", 1.0);
			TF2Attrib_SetByName(Weapon, "attack projectiles", 1.0);				
			TF2Attrib_SetByName(Weapon, "maxammo primary increased", 3.0);
			TF2Attrib_SetByName(Weapon, "clip size bonus", 5.0);
			TF2Attrib_SetByName(Weapon, "armor piercing", 20.0);
			TF2Attrib_SetByName(Weapon, "ammo regen", 2.0);
			TF2Attrib_SetByName(Weapon, "killstreak tier", 3.0);
			TF2Attrib_SetByName(Weapon, "killstreak effect", 2005.0);
			TF2Attrib_SetByName(Weapon, "killstreak idleeffect", 7.0);
		}
		int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if(IsValidEntity(Weapon2))
		{
			TF2Attrib_SetByName(Weapon2, "fire rate bonus", 0.3);	
			TF2Attrib_SetByName(Weapon2, "faster reload rate", 0.2);
			TF2Attrib_SetByName(Weapon2, "damage bonus", 5.0);
			TF2Attrib_SetByName(Weapon2, "projectile penetration", 1.0);
			TF2Attrib_SetByName(Weapon2, "attack projectiles", 1.0);				
			TF2Attrib_SetByName(Weapon2, "maxammo secondary increased", 3.0);
			TF2Attrib_SetByName(Weapon2, "clip size bonus", 5.0);
			TF2Attrib_SetByName(Weapon2, "armor piercing", 20.0);
			TF2Attrib_SetByName(Weapon2, "ammo regen", 2.0);
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
			TF2Attrib_SetByName(Weapon3, "armor piercing", 20.0);
			TF2Attrib_SetByName(Weapon3, "speed buff ally", 1.0);
			TF2Attrib_SetByName(Weapon3, "killstreak tier", 3.0);
			TF2Attrib_SetByName(Weapon3, "killstreak effect", 2005.0);
			TF2Attrib_SetByName(Weapon3, "killstreak idleeffect", 7.0);
			TF2Attrib_SetByName(Weapon3, "hit self on miss", 0.0);			
		}
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Scout)
	{
		PrintToChat(client, "You are an overpowered Scout");
		PrintToChat(client, "You will lose your powers when you touch a locker or die.");

		TF2Attrib_SetByName(client, "max health additive bonus", 1875.0);
		TF2Attrib_SetByName(client, "major move speed bonus", 2.0);
		TF2Attrib_SetByName(client, "health regen", 5.0);	
		TF2Attrib_SetByName(client, "cancel falling damage", 1.0);			
		TF2Attrib_SetByName(client, "dmg taken from blast reduced", 0.7);
		TF2Attrib_SetByName(client, "dmg taken from fire reduced", 0.7);
		TF2Attrib_SetByName(client, "dmg taken from bullets reduced", 0.7);
		TF2Attrib_SetByName(client, "dmg taken from crit reduced", 0.7);
		TF2Attrib_SetByName(client, "dmg from ranged reduced", 0.7);
		TF2Attrib_SetByName(client, "SET BONUS: dmg from sentry reduced", 0.7);	
		TF2Attrib_SetByName(client, "damage force reduction", 0.7);				
		TF2Attrib_SetByName(client, "increase player capture value", 2.0);
		TF2Attrib_SetByName(client, "major increased jump height", 2.0);
		TF2Attrib_SetByName(client, "parachute attribute", 1.0);
		TF2Attrib_SetByName(client, "increased air control", 12.0);	
		TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.7);
		TF2Attrib_SetByName(client, "airblast vertical vulnerability multiplier", 0.7);
		
		int Weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		if(IsValidEntity(Weapon))
		{
			TF2Attrib_SetByName(Weapon, "fire rate bonus", 0.3);	
			TF2Attrib_SetByName(Weapon, "faster reload rate", 0.2);
			TF2Attrib_SetByName(Weapon, "damage bonus", 5.0);
			TF2Attrib_SetByName(Weapon, "no self blast dmg", 2.0);				
			TF2Attrib_SetByName(Weapon, "projectile penetration", 1.0);
			TF2Attrib_SetByName(Weapon, "attack projectiles", 1.0);				
			TF2Attrib_SetByName(Weapon, "maxammo primary increased", 3.0);
			TF2Attrib_SetByName(Weapon, "clip size bonus", 5.0);
			TF2Attrib_SetByName(Weapon, "armor piercing", 20.0);
			TF2Attrib_SetByName(Weapon, "ammo regen", 2.0);
			TF2Attrib_SetByName(Weapon, "killstreak tier", 3.0);
			TF2Attrib_SetByName(Weapon, "killstreak effect", 2005.0);
			TF2Attrib_SetByName(Weapon, "killstreak idleeffect", 7.0);
		}
		int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if(IsValidEntity(Weapon2))
		{
			TF2Attrib_SetByName(Weapon2, "fire rate bonus", 0.3);	
			TF2Attrib_SetByName(Weapon2, "faster reload rate", 0.2);
			TF2Attrib_SetByName(Weapon2, "damage bonus", 5.0);
			TF2Attrib_SetByName(Weapon2, "projectile penetration", 1.0);
			TF2Attrib_SetByName(Weapon2, "attack projectiles", 1.0);				
			TF2Attrib_SetByName(Weapon2, "maxammo secondary increased", 3.0);
			TF2Attrib_SetByName(Weapon2, "clip size bonus", 5.0);
			TF2Attrib_SetByName(Weapon2, "armor piercing", 20.0);
			TF2Attrib_SetByName(Weapon2, "ammo regen", 2.0);
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
			TF2Attrib_SetByName(Weapon3, "armor piercing", 20.0);
			TF2Attrib_SetByName(Weapon3, "speed buff ally", 1.0);
			TF2Attrib_SetByName(Weapon3, "killstreak tier", 3.0);
			TF2Attrib_SetByName(Weapon3, "killstreak effect", 2005.0);
			TF2Attrib_SetByName(Weapon3, "killstreak idleeffect", 7.0);
			TF2Attrib_SetByName(Weapon3, "hit self on miss", 0.0);			
		}
		
	}
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 5.0);
	return Plugin_Handled;	
}

public void player_inv2(Handle event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (g_bIsWarPainted[client] && IsValidClient(client))
	{	
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
		
		g_bIsWarPainted[client] = false;
		TF2_SetHealth(client, 100);
		TF2_RegeneratePlayer(client);		
	}
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

stock bool IsValidClient(int client, bool nobots = true)
{ 
	if (client <= 0 || client > MaxClients)
	{
		return false; 
	}
	return IsClientInGame(client); 
}  

stock int GetIndexOfWeaponSlot(int client, int iSlot)
{
	return GetWeaponIndex(GetPlayerWeaponSlot(client, iSlot));
}

stock int GetClientCloakIndex(int client)
{
	return GetWeaponIndex(GetPlayerWeaponSlot(client, 4));
}

stock int GetWeaponIndex(int iWeapon)
{
	return IsValidEnt(iWeapon) ? GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex"):-1;
}

stock int GetActiveIndex(int client)
{
	return GetWeaponIndex(GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"));
}

stock bool IsWeaponSlotActive(int client, int iSlot)
{
	return GetPlayerWeaponSlot(client, iSlot) == GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
}

stock bool IsIndexActive(int client, int iIndex)
{
	return iIndex == GetWeaponIndex(GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"));
}

stock bool IsSlotIndex(int client, int iSlot, int iIndex)
{
	return iIndex == GetIndexOfWeaponSlot(client, iSlot);
}

stock bool IsValidEnt(int iEnt)
{
	return iEnt > MaxClients && IsValidEntity(iEnt);
}

stock int GetSlotFromPlayerWeapon(int client, int iWeapon)
{
	for (int i = 0; i <= 5; i++)
	{
		if (iWeapon == GetPlayerWeaponSlot(client, i))
		{
			return i;
		}
	}
	return -1;
} 

int GetRandomUInt(int min, int max)
{
	return RoundToFloor(GetURandomFloat() * (max - min + 1)) + min;
}

stock void TF2_SetHealth(int client, int NewHealth)
{
	SetEntProp(client, Prop_Send, "m_iHealth", NewHealth, 1);
	SetEntProp(client, Prop_Data, "m_iHealth", NewHealth, 1);
}

bool FindIfCanBeFestive(const int def)
{
	for(int i = 0; i < sizeof(festiveWeps); i++)
	{
		if(festiveWeps[i] == def)
		return true;
	}

	return false;
}