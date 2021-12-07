#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "2.0"

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

public Action Command_givewarpaint(int client, int args)
{
	char arg1[32];
	if (args < 1)
	{	
		GiveWarPaint(client);
		
		return Plugin_Handled;
	}
	GetCmdArg(1, arg1, sizeof(arg1));
	int paint = StringToInt(arg1);	
	if ((paint < 200) || (paint > 391) || (paint >283 && paint < 300) || (paint >310 && paint <390))
	{

		ReplyToCommand(client, "warpaintme <warpaint id>");
		ReplyToCommand(client, "warpaint ids: 200-283, 300-310, 390, 391"); 		
	}
	else
	{
		MakeWarPaint(client, paint);
	}
	
	return Plugin_Handled;
}

public Action Command_giveopwarpaint(int client, int args)
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
	if ((paint < 200) || (paint > 391) || (paint >283 && paint < 300) || (paint >310 && paint <390))
	{

		ReplyToCommand(client, "opwarpaintme <warpaint id>");
		ReplyToCommand(client, "warpaint ids: 200-283, 300-310, 390, 391"); 		
	}
	else
	{
		MakeWarPaint(client, paint);
		MakeOP(client);
	}
	
	return Plugin_Handled;
}

public Action Command_givewarpainttotarget(int client, int args)
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
	if ((paint < 200) || (paint > 391) || (paint >283 && paint < 300) || (paint >310 && paint <390))
	{

		ReplyToCommand(client, "warpaint <target> <warpaint id>");
		ReplyToCommand(client, "warpaint ids: 200-283, 300-310, 390, 391"); 		
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

public Action Command_giveopwarpainttotarget(int client, int args)
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
	if ((paint < 200) || (paint > 391) || (paint >283 && paint < 300) || (paint >310 && paint <390))
	{

		ReplyToCommand(client, "warpaint <target> <warpaint id>");
		ReplyToCommand(client, "warpaint ids: 200-283, 300-310, 390, 391"); 		
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

public Action GiveWarPaint(int client)
{
	PrintToChat(client, "You now have Warpaint weapons.");
	PrintToChat(client, "You will lose the weapons when you die or touch a locker.");	
	PrintToChat(client, "To pick a specifc warpaint use:  warpaintme <warpaint id>");
	PrintToChat(client, "warpaint ids: 200-283, 300-310, 390, 391"); 	
	
	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Scout)
	{
		if (!g_bMedieval)
		{
			int paint = GetRandomUInt(200, 283);
			if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274)
			{		
				paint = GetRandomUInt(300, 310);
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
			if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274)
			{		
				paint = GetRandomUInt(300, 310);
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

		int paint = GetRandomUInt(200, 283);
		if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274)
		{		
			paint = GetRandomUInt(300, 310);
		}

		CreateWeapon(client, "tf_weapon_bat_fish", 221, 6, 96, 2, paint);
		
		return Plugin_Handled;
	}
	
	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Soldier)
	{
		if (!g_bMedieval)
		{
			int paint = GetRandomUInt(200, 283);
			if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274)
			{		
				paint = GetRandomUInt(300, 310);
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
			if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274)
			{		
				paint = GetRandomUInt(300, 310);
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

		int paint = GetRandomUInt(200, 283);
		if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274)
		{		
			paint = GetRandomUInt(300, 310);
		}
		
		CreateWeapon(client, "tf_weapon_shovel", 447, 6, 96, 2, paint);
		
		return Plugin_Handled;		
	}
	
	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Pyro)
	{
		if (!g_bMedieval)
		{
			int paint = GetRandomUInt(200, 283);
			if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274)
			{		
				paint = GetRandomUInt(300, 310);
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
			if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274)
			{		
				paint = GetRandomUInt(300, 310);
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

		int paint = GetRandomUInt(200, 283);
		if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274)
		{		
			paint = GetRandomUInt(300, 310);
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
			int paint = GetRandomUInt(200, 283);
			if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274)
			{		
				paint = GetRandomUInt(300, 310);
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
			if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274)
			{		
				paint = GetRandomUInt(300, 310);
			}
			if(myslot0 != 308 && myslot0 != 996 && myslot0 != 1151 && myslot0 > 0)
			{
				CreateWeapon(client, "tf_weapon_grenadelauncher", 206, 6, 98, 0, paint);
			}

			paint = GetRandomUInt(200, 283);
			if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274)
			{		
				paint = GetRandomUInt(300, 310);
			}		
			int myslot1 = GetIndexOfWeaponSlot(client, 1);
			if(myslot1 != -1)
			{
				CreateWeapon(client, "tf_weapon_pipebomblauncher", 207, 6, 97, 1, paint);
			}
		}

		int paint = GetRandomUInt(200, 283);
		if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274)
		{		
			paint = GetRandomUInt(300, 310);
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
			int paint = GetRandomUInt(200, 283);
			if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274)
			{		
				paint = GetRandomUInt(300, 310);
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
			if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274)
			{		
				paint = GetRandomUInt(300, 310);
			}
			if(myslot0 != 312 && myslot0 != 424)
			{
				CreateWeapon(client, "tf_weapon_minigun", 202, 6, 98, 0, paint);
			}

			paint = GetRandomUInt(200, 283);
			if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274)
			{		
				paint = GetRandomUInt(300, 310);
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
			int paint = GetRandomUInt(200, 283);
			if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274)
			{		
				paint = GetRandomUInt(300, 310);
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
			if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274)
			{		
				paint = GetRandomUInt(300, 310);
			}
			CreateWeapon(client, "tf_weapon_pistol", 209, 6, 97, 1, paint);
		}

		int paint = GetRandomUInt(200, 283);
		if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274)
		{		
			paint = GetRandomUInt(300, 310);
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
			int paint = GetRandomUInt(200, 283);
			if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274)
			{		
				paint = GetRandomUInt(300, 310);
			}

			CreateWeapon(client, "tf_weapon_medigun", 211, 6, 97, 1, paint);
		}

		int paint = GetRandomUInt(200, 283);
		if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274)
		{		
			paint = GetRandomUInt(300, 310);
		}

		CreateWeapon(client, "tf_weapon_crossbow", 305, 6, 98, 0, paint);

		paint = GetRandomUInt(200, 283);
		if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274)
		{		
			paint = GetRandomUInt(300, 310);
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
			int paint = GetRandomUInt(200, 283);
			if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274)
			{		
				paint = GetRandomUInt(300, 310);
			}

			int myslot0 = GetIndexOfWeaponSlot(client, 0);

			if(myslot0 == 402)//Bazaar Bargain
			{
				CreateWeapon(client, "tf_weapon_sniperrifle_decap", 402, 6, 98, 0, paint);
			}
			paint = GetRandomUInt(200, 283);
			if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274)
			{		
				paint = GetRandomUInt(300, 310);
			}		

			if(myslot0 != 402)
			{
				CreateWeapon(client, "tf_weapon_sniperrifle", 201, 6, 98, 0, paint);
			}
			
			int myslot1 = GetIndexOfWeaponSlot(client, 1);

			if(myslot1 > 0) //NOT Razorback, danger shield, or cozy camper
			{
				paint = GetRandomUInt(200, 283);
				if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274)
				{		
					paint = GetRandomUInt(300, 310);
				}		

				CreateWeapon(client, "tf_weapon_smg", 203, 6, 97, 1, paint);
			}
		}

		int paint = GetRandomUInt(200, 283);
		if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274)
		{		
			paint = GetRandomUInt(300, 310);
		}

		CreateWeapon(client, "tf_weapon_club", 401, 6, 96, 2, paint);
		
		return Plugin_Handled;
	}

	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Spy)
	{
		if (!g_bMedieval)
		{
			int paint = GetRandomUInt(200, 283);
			if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274)
			{		
				paint = GetRandomUInt(300, 310);
			}

			CreateWeapon(client, "tf_weapon_revolver", 210, 6, 98, 0, paint);
		}
		
		int paint = GetRandomUInt(200, 283);
		if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274)
		{		
			paint = GetRandomUInt(300, 310);
		}

		CreateWeapon(client, "tf_weapon_knife", 194, 6, 96, 2, paint);
		
		return Plugin_Handled;
	}
	
	TF2_SwitchtoSlot(client, 0);
	
	return Plugin_Handled;
}

void MakeWarPaint(int client, int paint)
{
	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Scout)
	{
		if (!g_bMedieval)
		{	
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

		CreateWeapon(client, "tf_weapon_bat_fish", 221, 6, 96, 2, paint);
	}

	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Soldier)
	{
		if (!g_bMedieval)
		{
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
		
		CreateWeapon(client, "tf_weapon_shovel", 447, 6, 96, 2, paint);		
	}
	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Pyro)
	{
		if (!g_bMedieval)
		{
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

		int myslot2 = GetIndexOfWeaponSlot(client, 2);
		if(myslot2 == 326)//Back Scratcher
		{
			CreateWeapon(client, "tf_weapon_fireaxe", 326, 6, 96, 2, paint);
		}
		if(myslot2 != 326)
		{
			CreateWeapon(client, "tf_weapon_fireaxe", 214, 6, 96, 2, paint);
		}
	}
	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_DemoMan)
	{
		if (!g_bMedieval)
		{
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
	}		
	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Heavy)
	{
		if (!g_bMedieval)
		{
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
	}
	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Engineer)
	{
		if (!g_bMedieval)
		{
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
		
		int myslot2 = GetIndexOfWeaponSlot(client, 2);
		if(myslot2 == 329)//Jag
		{
			CreateWeapon(client, "tf_weapon_wrench", 329, 6, 96, 2, paint);
		}
		if(myslot2 != 329)
		{
			CreateWeapon(client, "tf_weapon_wrench", 197, 6, 96, 2, paint);
		}
	}
	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Medic)
	{
		if (!g_bMedieval)
		{
			CreateWeapon(client, "tf_weapon_medigun", 211, 6, 99, 1, paint);
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
		
		CreateWeapon(client, "tf_weapon_club", 401, 6, 96, 2, paint);
	}
	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Spy)
	{
		if (!g_bMedieval)
		{		
			CreateWeapon(client, "tf_weapon_revolver", 210, 6, 99, 0, paint);
		}
		
		CreateWeapon(client, "tf_weapon_knife", 194, 6, 99, 2, paint);		
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
	
	if(itemindex == 200 || itemindex == 220 || itemindex == 448 || itemindex == 15002 || itemindex == 15015 || itemindex == 15021 || itemindex == 15029 || itemindex == 15036 || itemindex == 15053 || itemindex == 15065 || itemindex == 15069 || itemindex == 15106 || itemindex == 15107 || itemindex == 15108 || itemindex == 15131 || itemindex == 15151 || itemindex == 15157 || itemindex == 449 || itemindex == 15013 || itemindex == 15018 || itemindex == 15035 || itemindex == 15041 || itemindex == 15046 || itemindex == 15056 || itemindex == 15060 || itemindex == 15061 || itemindex == 15100 || itemindex == 15101
			|| itemindex == 15102 || itemindex == 15126 || itemindex == 15148 || itemindex == 44 || itemindex == 221 || itemindex == 205 || itemindex == 228 || itemindex == 1104 || itemindex == 15006 || itemindex == 15014 || itemindex == 15028 || itemindex == 15043 || itemindex == 15052 || itemindex == 15057 || itemindex == 15081 || itemindex == 15104 || itemindex == 15105 || itemindex == 15129 || itemindex == 15130 || itemindex == 15150 || itemindex == 196 || itemindex == 447 || itemindex == 208 || itemindex == 215 || itemindex == 1178 || itemindex == 15005 || itemindex == 15017 || itemindex == 15030 || itemindex == 15034
			|| itemindex == 15049 || itemindex == 15054 || itemindex == 15066 || itemindex == 15067 || itemindex == 15068 || itemindex == 15089 || itemindex == 15090 || itemindex == 15115 || itemindex == 15141 || itemindex == 351 || itemindex == 740 || itemindex == 192 || itemindex == 214 || itemindex == 326 || itemindex == 206 || itemindex == 308 || itemindex == 996 || itemindex == 1151 || itemindex == 15077 || itemindex == 15079 || itemindex == 15091 || itemindex == 15092 || itemindex == 15116 || itemindex == 15117 || itemindex == 15142 || itemindex == 15158 || itemindex == 207 || itemindex == 130 || itemindex == 15009
			|| itemindex == 15012 || itemindex == 15024 || itemindex == 15038 || itemindex == 15045 || itemindex == 15048 || itemindex == 15082 || itemindex == 15083 || itemindex == 15084 || itemindex == 15113 || itemindex == 15137 || itemindex == 15138 || itemindex == 15155 || itemindex == 172 || itemindex == 327 || itemindex == 404 || itemindex == 202 || itemindex == 41 || itemindex == 312 || itemindex == 424 || itemindex == 15004 || itemindex == 15020 || itemindex == 15026 || itemindex == 15031 || itemindex == 15040 || itemindex == 15055 || itemindex == 15086 || itemindex == 15087 || itemindex == 15088 || itemindex == 15098
			|| itemindex == 15099 || itemindex == 15123 || itemindex == 15124 || itemindex == 15125 || itemindex == 15147 || itemindex == 425 || itemindex == 997 || itemindex == 197 || itemindex == 329 || itemindex == 15073 || itemindex == 15074 || itemindex == 15075 || itemindex == 15139 || itemindex == 15140 || itemindex == 15114 || itemindex == 15156 || itemindex == 305 || itemindex == 211 || itemindex == 15008 || itemindex == 15010 || itemindex == 15025 || itemindex == 15039 || itemindex == 15050 || itemindex == 15078 || itemindex == 15097 || itemindex == 15121 || itemindex == 15122 || itemindex == 15123 || itemindex == 15145
			|| itemindex == 15146 || itemindex == 35 || itemindex == 411 || itemindex == 37 || itemindex == 304 || itemindex == 201 || itemindex == 402 || itemindex == 15000 || itemindex == 15007 || itemindex == 15019 || itemindex == 15023 || itemindex == 15033 || itemindex == 15059 || itemindex == 15070 || itemindex == 15071 || itemindex == 15072 || itemindex == 15111 || itemindex == 15112 || itemindex == 15135 || itemindex == 15136 || itemindex == 15154 || itemindex == 203 || itemindex == 15001 || itemindex == 15022 || itemindex == 15032 || itemindex == 15037 || itemindex == 15058 || itemindex == 15076 || itemindex == 15110
			|| itemindex == 15134 || itemindex == 15153 || itemindex == 193 || itemindex == 401 || itemindex == 210 || itemindex == 15011 || itemindex == 15027 || itemindex == 15042 || itemindex == 15051 || itemindex == 15062 || itemindex == 15063 || itemindex == 15064 || itemindex == 15103 || itemindex == 15128 || itemindex == 15129 || itemindex == 15149 || itemindex == 194 || itemindex == 649 || itemindex == 15062 || itemindex == 15094 || itemindex == 15095 || itemindex == 15096 || itemindex == 15118 || itemindex == 15119 || itemindex == 15143 || itemindex == 15144 || itemindex == 209 || itemindex == 15013 || itemindex == 15018
			|| itemindex == 15035 || itemindex == 15041 || itemindex == 15046 || itemindex == 15056 || itemindex == 15060 || itemindex == 15061 || itemindex == 15100 || itemindex == 15101 || itemindex == 15102 || itemindex == 15126 || itemindex == 15148 || itemindex == 415 || itemindex == 15003 || itemindex == 15016 || itemindex == 15044 || itemindex == 15047 || itemindex == 15085 || itemindex == 15109 || itemindex == 15132 || itemindex == 15133 || itemindex == 15152 || itemindex == 1153)
	{
		if(GetRandomUInt(1,30) == 1)
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
		if ((slot < 2) && (GetRandomUInt(1,5) == 1))
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

public Action MakeOP(int client) 
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

public Action TimerHealth(Handle timer, any client)
{
	int hp = GetPlayerMaxHp(client);
	
	if (hp > 0)
	{
		SetEntityHealth(client, hp);
	}
}

int GetPlayerMaxHp(int client)
{
	if (!IsClientConnected(client))
	{
		return -1;
	}

	int entity = GetPlayerResourceEntity();

	if (entity == -1)
	{
		return -1;
	}

	return GetEntProp(entity, Prop_Send, "m_iMaxHealth", _, client);
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
	return GetWeaponIndex(GetPlayerWeaponSlot(client, TFWeaponSlot_Watch));
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
	for (new i = 0; i <= 5; i++)
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