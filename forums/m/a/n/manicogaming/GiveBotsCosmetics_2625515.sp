#include <sourcemod>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.10"

bool g_bTouched[MAXPLAYERS+1];
bool g_bMVM;
bool g_bLateLoad;
ConVar g_hCVTimer;
ConVar g_hCVEnabled;
ConVar g_hCVTeam;
Handle g_hWearableEquip;
Handle g_hGameConfig;
bool face;

public Plugin myinfo = 
{
	name = "Give Bots Cosmetics",
	author = "luki1412",
	description = "Gives TF2 bots cosmetics",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/member.php?u=43109"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	if (GetEngineVersion() != Engine_TF2) 
	{
		Format(error, err_max, "This plugin only works for Team Fortress 2.");
		return APLRes_Failure;
	}
	
	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart() 
{
	ConVar hCVversioncvar = CreateConVar("sm_gbc_version", PLUGIN_VERSION, "Give Bots Cosmetics version cvar", FCVAR_NOTIFY|FCVAR_DONTRECORD); 
	g_hCVEnabled = CreateConVar("sm_gbc_enabled", "1", "Enables/disables this plugin", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCVTimer = CreateConVar("sm_gbc_delay", "0.1", "Delay for giving cosmetics to bots", FCVAR_NONE, true, 0.1, true, 30.0);
	g_hCVTeam = CreateConVar("sm_gbc_team", "1", "Team to give cosmetics to: 1-both, 2-red, 3-blu", FCVAR_NONE, true, 1.0, true, 3.0);

	HookEvent("post_inventory_application", player_inv);
	HookConVarChange(g_hCVEnabled, OnEnabledChanged);
	
	SetConVarString(hCVversioncvar, PLUGIN_VERSION);
	AutoExecConfig(true, "Give_Bots_Cosmetics");

	if (g_bLateLoad)
	{
		OnMapStart();
	}
	
	g_hGameConfig = LoadGameConfigFile("give.bots.cosmetics");
	
	if (!g_hGameConfig)
	{
		SetFailState("Failed to find give.bots.cosmetics.txt gamedata! Can't continue.");
	}	
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConfig, SDKConf_Virtual, "EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hWearableEquip = EndPrepSDKCall();
	
	if (!g_hWearableEquip)
	{
		SetFailState("Failed to prepare the SDKCall for giving cosmetics. Try updating gamedata or restarting your server.");
	}
}

public void OnEnabledChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (GetConVarBool(g_hCVEnabled))
	{
		HookEvent("post_inventory_application", player_inv);
	}
	else
	{
		UnhookEvent("post_inventory_application", player_inv);
	}
}

public void OnMapStart()
{
	if (GameRules_GetProp("m_bPlayingMannVsMachine"))
	{
		g_bMVM = true;
	}
}

public void OnClientDisconnect(int client)
{
	g_bTouched[client] = false;
}

public void player_inv(Handle event, const char[] name, bool dontBroadcast) 
{
	if (!GetConVarInt(g_hCVEnabled))
	{
		return;
	}

	int userd = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userd);
	
	if (!g_bTouched[client] && !g_bMVM && IsPlayerHere(client))
	{
		g_bTouched[client] = true;
		int team = GetClientTeam(client);
		int team2 = GetConVarInt(g_hCVTeam);
		float timer = GetConVarFloat(g_hCVTimer);
		
		switch (team2)
		{
			case 1:
			{
				CreateTimer(timer, Timer_GiveHat, userd, TIMER_FLAG_NO_MAPCHANGE);
			}
			case 2:
			{
				if (team == 2)
				{
					CreateTimer(timer, Timer_GiveHat, userd, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
			case 3:
			{
				if (team == 3)
				{
					CreateTimer(timer, Timer_GiveHat, userd, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}
}

public Action Timer_GiveHat(Handle timer, any data)
{
	int client = GetClientOfUserId(data);
	g_bTouched[client] = false;
	
	if (!GetConVarInt(g_hCVEnabled) || !IsPlayerHere(client))
	{
		return;
	}

	int team = GetClientTeam(client);
	int team2 = GetConVarInt(g_hCVTeam);
	
	switch (team2)
	{
		case 2:
		{
			if (team != 2)
			{
				return;
			}
		}
		case 3:
		{
			if (team != 3)
			{
				return;
			}
		}
	}
	
	if (!g_bMVM)
	{
		face = false;
		TFClassType class = TF2_GetPlayerClass(client);
		
		switch (class)
		{
			case TFClass_Scout:
			{
				int rnd = GetRandomUInt(0,48);
				switch (rnd)
				{
					case 1:
					{
						CreateHat(client, 940, 6, 10); //Ghostly Gibus
					}
					case 2:
					{
						CreateHat(client, 668, 6); //The Full Head of Steam
					}
					case 3:
					{
						CreateHat(client, 774, 6); //The Gentle Munitionne of Leisure
					}
					case 4:
					{
						CreateHat(client, 941, 6, 31); //The Skull Island Topper
					}
					case 5:
					{
						CreateHat(client, 30357, 6); //Dark Falkirk Helm - Fiquei Neste
					}
					case 6:
					{
						CreateHat(client, 538, 6); //Killer Exclusive
					}	
					case 7:
					{
						CreateHat(client, 139, 6); //Modest Pile of Hat
					}
					case 8:
					{
						CreateHat(client, 137, 6); //Noble Amassment of Hats
					}
					case 9:
					{
						CreateHat(client, 135, 6); //Towering Pillar of Hats
					}	
					case 10:
					{
						CreateHat(client, 30119, 6); //The Federal Casemaker
					}
					case 11:
					{
						CreateHat(client, 252, 6); //Dr's Dapper Topper
					}
					case 12:
					{
						CreateHat(client, 341, 6); //A Rather Festive Tree
					}
					case 13:
					{
						CreateHat(client, 523, 6, 10); //The Sarif Cap
					}
					case 14:
					{
						CreateHat(client, 614, 6); //The Hot Dogger
					}
					case 15:
					{
						CreateHat(client, 611, 6); //The Salty Dog
					}
					case 16:
					{
						CreateHat(client, 671, 6); //The Brown Bomber
					}
					case 17:
					{
						CreateHat(client, 817, 6); //The Human Cannonball
					}
					case 18:
					{
						CreateHat(client, 993, 6); //Antlers
					}
					case 19:
					{
						CreateHat(client, 984, 6); //Tough Stuff Muffs
					}
					case 20:
					{
						CreateHat(client, 1014, 6); //The Brutal Bouffant
					}
					case 21:
					{
						CreateHat(client, 30066, 6); //The Brotherhood of Arms
					}	
					case 22:
					{
						CreateHat(client, 30067, 6); //The Well-Rounded Rifleman
					}
					case 23:
					{
						CreateHat(client, 30175, 6); //The Cotton Head
					}
					case 24:
					{
						CreateHat(client, 30177, 6); //Hong Kong Cone
					}
					case 25:
					{
						CreateHat(client, 30313, 6); //The Kiss King
					}
					case 26:
					{
						CreateHat(client, 30307, 6); //Neckwear Headwear
					}
					case 27:
					{
						CreateHat(client, 30329, 6); //The Polar Pullover
					}
					case 28:
					{
						CreateHat(client, 30362, 6); //The Law
					}
					case 29:
					{
						CreateHat(client, 30567, 6); //The Crown of the Old Kingdom
					}
					case 30:
					{
						CreateHat(client, 1164, 6, 50); //Civilian Grade JACK Hat
					}
					case 31:
					{
						CreateHat(client, 920, 6); //The Crone's Dome
					}
					case 32:
					{
						CreateHat(client, 30425, 6); //Tipped Lid
					}
					case 33:
					{
						CreateHat(client, 30413, 6); //The Merc's Mohawk
					}
					case 34:
					{
						CreateHat(client, 921, 6); //The Executioner
						face = true;
					}
					case 35:
					{
						CreateHat(client, 30422, 6); //Vive La France
						face = true;
					}
					case 36:
					{
						CreateHat(client, 291, 6); //Horrific Headsplitter
					}
					case 37:
					{
						CreateHat(client, 345, 6, 10); //MNC hat
					}
					case 38:
					{
						CreateHat(client, 785, 6, 10); //Robot Chicken Hat
					}
					case 39:
					{
						CreateHat(client, 702, 6); //Warsworn Helmet
						face = true;
					}
					case 40:
					{
						CreateHat(client, 634, 6); //Point and Shoot
					}
					case 41:
					{
						CreateHat(client, 942, 6); //Cockfighter
					}
					case 42:
					{
						CreateHat(client, 944, 6); //That 70s Chapeau
						face = true;
					}
					case 43:
					{
						CreateHat(client, 30065, 6); //Hardy Laurel
					}
					case 44:
					{
						CreateHat(client, 30571, 6); //Brimstone
					}
					case 45:
					{
						CreateHat(client, 30473, 6); //MK 50
					}
					case 46:
					{
						CreateHat(client, 126, 6); //Bill's Hat
					}
					case 47:
					{
						CreateHat(client, 940, 11, 10); //Ghostly Gibus
					}
					case 48:
					{
						CreateHat(client, 941, 11, 31); //The Skull Island Topper
					}
				}
			}
			case TFClass_Sniper:
			{
				int rnd = GetRandomUInt(0,46);
				switch (rnd)
				{
					case 1:
					{
						CreateHat(client, 940, 6, 10); //Ghostly Gibus
					}
					case 2:
					{
						CreateHat(client, 668, 6); //The Full Head of Steam
					}
					case 3:
					{
						CreateHat(client, 774, 6); //The Gentle Munitionne of Leisure
					}
					case 4:
					{
						CreateHat(client, 941, 6, 31); //The Skull Island Topper
					}
					case 5:
					{
						CreateHat(client, 30357, 6); //Dark Falkirk Helm - Fiquei Neste
					}
					case 6:
					{
						CreateHat(client, 538, 6); //Killer Exclusive
					}	
					case 7:
					{
						CreateHat(client, 139, 6); //Modest Pile of Hat
					}
					case 8:
					{
						CreateHat(client, 137, 6); //Noble Amassment of Hats
					}
					case 9:
					{
						CreateHat(client, 135, 6); //Towering Pillar of Hats
					}	
					case 10:
					{
						CreateHat(client, 30119, 6); //The Federal Casemaker
					}
					case 11:
					{
						CreateHat(client, 252, 6); //Dr's Dapper Topper
					}
					case 12:
					{
						CreateHat(client, 341, 6); //A Rather Festive Tree
					}
					case 13:
					{
						CreateHat(client, 523, 6, 10); //The Sarif Cap
					}
					case 14:
					{
						CreateHat(client, 614, 6); //The Hot Dogger
					}
					case 15:
					{
						CreateHat(client, 611, 6); //The Salty Dog
					}
					case 16:
					{
						CreateHat(client, 671, 6); //The Brown Bomber
					}
					case 17:
					{
						CreateHat(client, 817, 6); //The Human Cannonball
					}
					case 18:
					{
						CreateHat(client, 993, 6); //Antlers
					}
					case 19:
					{
						CreateHat(client, 984, 6); //Tough Stuff Muffs
					}
					case 20:
					{
						CreateHat(client, 1014, 6); //The Brutal Bouffant
					}
					case 21:
					{
						CreateHat(client, 30066, 6); //The Brotherhood of Arms
					}	
					case 22:
					{
						CreateHat(client, 30067, 6); //The Well-Rounded Rifleman
					}
					case 23:
					{
						CreateHat(client, 30175, 6); //The Cotton Head
					}
					case 24:
					{
						CreateHat(client, 30177, 6); //Hong Kong Cone
					}
					case 25:
					{
						CreateHat(client, 30313, 6); //The Kiss King
					}
					case 26:
					{
						CreateHat(client, 30307, 6); //Neckwear Headwear
					}
					case 27:
					{
						CreateHat(client, 30329, 6); //The Polar Pullover
					}
					case 28:
					{
						CreateHat(client, 30362, 6); //The Law
					}
					case 29:
					{
						CreateHat(client, 30567, 6); //The Crown of the Old Kingdom
					}
					case 30:
					{
						CreateHat(client, 1164, 6, 50); //Civilian Grade JACK Hat
					}
					case 31:
					{
						CreateHat(client, 920, 6); //The Crone's Dome
					}
					case 32:
					{
						CreateHat(client, 30425, 6); //Tipped Lid
					}
					case 33:
					{
						CreateHat(client, 30413, 6); //The Merc's Mohawk
					}
					case 34:
					{
						CreateHat(client, 921, 6); //The Executioner
						face = true;
					}
					case 35:
					{
						CreateHat(client, 30422, 6); //Vive La France
						face = true;
					}
					case 36:
					{
						CreateHat(client, 291, 6); //Horrific Headsplitter
					}
					case 37:
					{
						CreateHat(client, 345, 6, 10); //MNC hat
					}
					case 38:
					{
						CreateHat(client, 785, 6, 10); //Robot Chicken Hat
					}
					case 39:
					{
						CreateHat(client, 702, 6); //Warsworn Helmet
						face = true;
					}
					case 40:
					{
						CreateHat(client, 634, 6); //Point and Shoot
					}
					case 41:
					{
						CreateHat(client, 942, 6); //Cockfighter
					}
					case 42:
					{
						CreateHat(client, 944, 6); //That 70s Chapeau
						face = true;
					}
					case 43:
					{
						CreateHat(client, 30065, 6); //Hardy Laurel
					}
					case 44:
					{
						CreateHat(client, 30571, 6); //Brimstone
					}
					case 45:
					{
						CreateHat(client, 30473, 6); //MK 50
					}
					case 46:
					{
						CreateHat(client, 126, 6); //Bill's Hat
					}
				}
			}
			case TFClass_Soldier:
			{
				int rnd = GetRandomUInt(0,46);
				switch (rnd)
				{
					case 1:
					{
						CreateHat(client, 940, 6, 10); //Ghostly Gibus
					}
					case 2:
					{
						CreateHat(client, 668, 6); //The Full Head of Steam
					}
					case 3:
					{
						CreateHat(client, 774, 6); //The Gentle Munitionne of Leisure
					}
					case 4:
					{
						CreateHat(client, 941, 6, 31); //The Skull Island Topper
					}
					case 5:
					{
						CreateHat(client, 30357, 6); //Dark Falkirk Helm - Fiquei Neste
					}
					case 6:
					{
						CreateHat(client, 538, 6); //Killer Exclusive
					}	
					case 7:
					{
						CreateHat(client, 139, 6); //Modest Pile of Hat
					}
					case 8:
					{
						CreateHat(client, 137, 6); //Noble Amassment of Hats
					}
					case 9:
					{
						CreateHat(client, 135, 6); //Towering Pillar of Hats
					}	
					case 10:
					{
						CreateHat(client, 30119, 6); //The Federal Casemaker
					}
					case 11:
					{
						CreateHat(client, 252, 6); //Dr's Dapper Topper
					}
					case 12:
					{
						CreateHat(client, 341, 6); //A Rather Festive Tree
					}
					case 13:
					{
						CreateHat(client, 523, 6, 10); //The Sarif Cap
					}
					case 14:
					{
						CreateHat(client, 614, 6); //The Hot Dogger
					}
					case 15:
					{
						CreateHat(client, 611, 6); //The Salty Dog
					}
					case 16:
					{
						CreateHat(client, 671, 6); //The Brown Bomber
					}
					case 17:
					{
						CreateHat(client, 817, 6); //The Human Cannonball
					}
					case 18:
					{
						CreateHat(client, 993, 6); //Antlers
					}
					case 19:
					{
						CreateHat(client, 984, 6); //Tough Stuff Muffs
					}
					case 20:
					{
						CreateHat(client, 1014, 6); //The Brutal Bouffant
					}
					case 21:
					{
						CreateHat(client, 30066, 6); //The Brotherhood of Arms
					}	
					case 22:
					{
						CreateHat(client, 30067, 6); //The Well-Rounded Rifleman
					}
					case 23:
					{
						CreateHat(client, 30175, 6); //The Cotton Head
					}
					case 24:
					{
						CreateHat(client, 30177, 6); //Hong Kong Cone
					}
					case 25:
					{
						CreateHat(client, 30313, 6); //The Kiss King
					}
					case 26:
					{
						CreateHat(client, 30307, 6); //Neckwear Headwear
					}
					case 27:
					{
						CreateHat(client, 30329, 6); //The Polar Pullover
					}
					case 28:
					{
						CreateHat(client, 30362, 6); //The Law
					}
					case 29:
					{
						CreateHat(client, 30567, 6); //The Crown of the Old Kingdom
					}
					case 30:
					{
						CreateHat(client, 1164, 6, 50); //Civilian Grade JACK Hat
					}
					case 31:
					{
						CreateHat(client, 920, 6); //The Crone's Dome
					}
					case 32:
					{
						CreateHat(client, 30425, 6); //Tipped Lid
					}
					case 33:
					{
						CreateHat(client, 30413, 6); //The Merc's Mohawk
					}
					case 34:
					{
						CreateHat(client, 921, 6); //The Executioner
						face = true;
					}
					case 35:
					{
						CreateHat(client, 30422, 6); //Vive La France
						face = true;
					}
					case 36:
					{
						CreateHat(client, 291, 6); //Horrific Headsplitter
					}
					case 37:
					{
						CreateHat(client, 345, 6, 10); //MNC hat
					}
					case 38:
					{
						CreateHat(client, 785, 6, 10); //Robot Chicken Hat
					}
					case 39:
					{
						CreateHat(client, 702, 6); //Warsworn Helmet
						face = true;
					}
					case 40:
					{
						CreateHat(client, 634, 6); //Point and Shoot
					}
					case 41:
					{
						CreateHat(client, 942, 6); //Cockfighter
					}
					case 42:
					{
						CreateHat(client, 944, 6); //That 70s Chapeau
						face = true;
					}
					case 43:
					{
						CreateHat(client, 30065, 6); //Hardy Laurel
					}
					case 44:
					{
						CreateHat(client, 30571, 6); //Brimstone
					}
					case 45:
					{
						CreateHat(client, 30473, 6); //MK 50
					}
					case 46:
					{
						CreateHat(client, 126, 6); //Bill's Hat
					}
				}
			}
			case TFClass_DemoMan:
			{
				int rnd = GetRandomUInt(0,46);
				switch (rnd)
				{
					case 1:
					{
						CreateHat(client, 940, 6, 10); //Ghostly Gibus
					}
					case 2:
					{
						CreateHat(client, 668, 6); //The Full Head of Steam
					}
					case 3:
					{
						CreateHat(client, 774, 6); //The Gentle Munitionne of Leisure
					}
					case 4:
					{
						CreateHat(client, 941, 6, 31); //The Skull Island Topper
					}
					case 5:
					{
						CreateHat(client, 30357, 6); //Dark Falkirk Helm - Fiquei Neste
					}
					case 6:
					{
						CreateHat(client, 538, 6); //Killer Exclusive
					}	
					case 7:
					{
						CreateHat(client, 139, 6); //Modest Pile of Hat
					}
					case 8:
					{
						CreateHat(client, 137, 6); //Noble Amassment of Hats
					}
					case 9:
					{
						CreateHat(client, 135, 6); //Towering Pillar of Hats
					}	
					case 10:
					{
						CreateHat(client, 30119, 6); //The Federal Casemaker
					}
					case 11:
					{
						CreateHat(client, 252, 6); //Dr's Dapper Topper
					}
					case 12:
					{
						CreateHat(client, 341, 6); //A Rather Festive Tree
					}
					case 13:
					{
						CreateHat(client, 523, 6, 10); //The Sarif Cap
					}
					case 14:
					{
						CreateHat(client, 614, 6); //The Hot Dogger
					}
					case 15:
					{
						CreateHat(client, 611, 6); //The Salty Dog
					}
					case 16:
					{
						CreateHat(client, 671, 6); //The Brown Bomber
					}
					case 17:
					{
						CreateHat(client, 817, 6); //The Human Cannonball
					}
					case 18:
					{
						CreateHat(client, 993, 6); //Antlers
					}
					case 19:
					{
						CreateHat(client, 984, 6); //Tough Stuff Muffs
					}
					case 20:
					{
						CreateHat(client, 1014, 6); //The Brutal Bouffant
					}
					case 21:
					{
						CreateHat(client, 30066, 6); //The Brotherhood of Arms
					}	
					case 22:
					{
						CreateHat(client, 30067, 6); //The Well-Rounded Rifleman
					}
					case 23:
					{
						CreateHat(client, 30175, 6); //The Cotton Head
					}
					case 24:
					{
						CreateHat(client, 30177, 6); //Hong Kong Cone
					}
					case 25:
					{
						CreateHat(client, 30313, 6); //The Kiss King
					}
					case 26:
					{
						CreateHat(client, 30307, 6); //Neckwear Headwear
					}
					case 27:
					{
						CreateHat(client, 30329, 6); //The Polar Pullover
					}
					case 28:
					{
						CreateHat(client, 30362, 6); //The Law
					}
					case 29:
					{
						CreateHat(client, 30567, 6); //The Crown of the Old Kingdom
					}
					case 30:
					{
						CreateHat(client, 1164, 6, 50); //Civilian Grade JACK Hat
					}
					case 31:
					{
						CreateHat(client, 920, 6); //The Crone's Dome
					}
					case 32:
					{
						CreateHat(client, 30425, 6); //Tipped Lid
					}
					case 33:
					{
						CreateHat(client, 30413, 6); //The Merc's Mohawk
					}
					case 34:
					{
						CreateHat(client, 921, 6); //The Executioner
						face = true;
					}
					case 35:
					{
						CreateHat(client, 30422, 6); //Vive La France
						face = true;
					}
					case 36:
					{
						CreateHat(client, 291, 6); //Horrific Headsplitter
					}
					case 37:
					{
						CreateHat(client, 345, 6, 10); //MNC hat
					}
					case 38:
					{
						CreateHat(client, 785, 6, 10); //Robot Chicken Hat
					}
					case 39:
					{
						CreateHat(client, 702, 6); //Warsworn Helmet
						face = true;
					}
					case 40:
					{
						CreateHat(client, 634, 6); //Point and Shoot
					}
					case 41:
					{
						CreateHat(client, 942, 6); //Cockfighter
					}
					case 42:
					{
						CreateHat(client, 944, 6); //That 70s Chapeau
						face = true;
					}
					case 43:
					{
						CreateHat(client, 30065, 6); //Hardy Laurel
					}
					case 44:
					{
						CreateHat(client, 30571, 6); //Brimstone
					}
					case 45:
					{
						CreateHat(client, 30473, 6); //MK 50
					}
					case 46:
					{
						CreateHat(client, 126, 6); //Bill's Hat
					}
				}
			}
			case TFClass_Medic:
			{
				int rnd = GetRandomUInt(0,46);
				switch (rnd)
				{
					case 1:
					{
						CreateHat(client, 940, 6, 10); //Ghostly Gibus
					}
					case 2:
					{
						CreateHat(client, 668, 6); //The Full Head of Steam
					}
					case 3:
					{
						CreateHat(client, 774, 6); //The Gentle Munitionne of Leisure
					}
					case 4:
					{
						CreateHat(client, 941, 6, 31); //The Skull Island Topper
					}
					case 5:
					{
						CreateHat(client, 30357, 6); //Dark Falkirk Helm - Fiquei Neste
					}
					case 6:
					{
						CreateHat(client, 538, 6); //Killer Exclusive
					}	
					case 7:
					{
						CreateHat(client, 139, 6); //Modest Pile of Hat
					}
					case 8:
					{
						CreateHat(client, 137, 6); //Noble Amassment of Hats
					}
					case 9:
					{
						CreateHat(client, 135, 6); //Towering Pillar of Hats
					}	
					case 10:
					{
						CreateHat(client, 30119, 6); //The Federal Casemaker
					}
					case 11:
					{
						CreateHat(client, 252, 6); //Dr's Dapper Topper
					}
					case 12:
					{
						CreateHat(client, 341, 6); //A Rather Festive Tree
					}
					case 13:
					{
						CreateHat(client, 523, 6, 10); //The Sarif Cap
					}
					case 14:
					{
						CreateHat(client, 614, 6); //The Hot Dogger
					}
					case 15:
					{
						CreateHat(client, 611, 6); //The Salty Dog
					}
					case 16:
					{
						CreateHat(client, 671, 6); //The Brown Bomber
					}
					case 17:
					{
						CreateHat(client, 817, 6); //The Human Cannonball
					}
					case 18:
					{
						CreateHat(client, 993, 6); //Antlers
					}
					case 19:
					{
						CreateHat(client, 984, 6); //Tough Stuff Muffs
					}
					case 20:
					{
						CreateHat(client, 1014, 6); //The Brutal Bouffant
					}
					case 21:
					{
						CreateHat(client, 30066, 6); //The Brotherhood of Arms
					}	
					case 22:
					{
						CreateHat(client, 30067, 6); //The Well-Rounded Rifleman
					}
					case 23:
					{
						CreateHat(client, 30175, 6); //The Cotton Head
					}
					case 24:
					{
						CreateHat(client, 30177, 6); //Hong Kong Cone
					}
					case 25:
					{
						CreateHat(client, 30313, 6); //The Kiss King
					}
					case 26:
					{
						CreateHat(client, 30307, 6); //Neckwear Headwear
					}
					case 27:
					{
						CreateHat(client, 30329, 6); //The Polar Pullover
					}
					case 28:
					{
						CreateHat(client, 30362, 6); //The Law
					}
					case 29:
					{
						CreateHat(client, 30567, 6); //The Crown of the Old Kingdom
					}
					case 30:
					{
						CreateHat(client, 1164, 6, 50); //Civilian Grade JACK Hat
					}
					case 31:
					{
						CreateHat(client, 920, 6); //The Crone's Dome
					}
					case 32:
					{
						CreateHat(client, 30425, 6); //Tipped Lid
					}
					case 33:
					{
						CreateHat(client, 30413, 6); //The Merc's Mohawk
					}
					case 34:
					{
						CreateHat(client, 921, 6); //The Executioner
						face = true;
					}
					case 35:
					{
						CreateHat(client, 30422, 6); //Vive La France
						face = true;
					}
					case 36:
					{
						CreateHat(client, 291, 6); //Horrific Headsplitter
					}
					case 37:
					{
						CreateHat(client, 345, 6, 10); //MNC hat
					}
					case 38:
					{
						CreateHat(client, 785, 6, 10); //Robot Chicken Hat
					}
					case 39:
					{
						CreateHat(client, 702, 6); //Warsworn Helmet
						face = true;
					}
					case 40:
					{
						CreateHat(client, 634, 6); //Point and Shoot
					}
					case 41:
					{
						CreateHat(client, 942, 6); //Cockfighter
					}
					case 42:
					{
						CreateHat(client, 944, 6); //That 70s Chapeau
						face = true;
					}
					case 43:
					{
						CreateHat(client, 30065, 6); //Hardy Laurel
					}
					case 44:
					{
						CreateHat(client, 30571, 6); //Brimstone
					}
					case 45:
					{
						CreateHat(client, 30473, 6); //MK 50
					}
					case 46:
					{
						CreateHat(client, 126, 6); //Bill's Hat
					}
				}
			}
			case TFClass_Heavy:
			{
				int rnd = GetRandomUInt(0,46);
				switch (rnd)
				{
					case 1:
					{
						CreateHat(client, 940, 6, 10); //Ghostly Gibus
					}
					case 2:
					{
						CreateHat(client, 668, 6); //The Full Head of Steam
					}
					case 3:
					{
						CreateHat(client, 774, 6); //The Gentle Munitionne of Leisure
					}
					case 4:
					{
						CreateHat(client, 941, 6, 31); //The Skull Island Topper
					}
					case 5:
					{
						CreateHat(client, 30357, 6); //Dark Falkirk Helm - Fiquei Neste
					}
					case 6:
					{
						CreateHat(client, 538, 6); //Killer Exclusive
					}	
					case 7:
					{
						CreateHat(client, 139, 6); //Modest Pile of Hat
					}
					case 8:
					{
						CreateHat(client, 137, 6); //Noble Amassment of Hats
					}
					case 9:
					{
						CreateHat(client, 135, 6); //Towering Pillar of Hats
					}	
					case 10:
					{
						CreateHat(client, 30119, 6); //The Federal Casemaker
					}
					case 11:
					{
						CreateHat(client, 252, 6); //Dr's Dapper Topper
					}
					case 12:
					{
						CreateHat(client, 341, 6); //A Rather Festive Tree
					}
					case 13:
					{
						CreateHat(client, 523, 6, 10); //The Sarif Cap
					}
					case 14:
					{
						CreateHat(client, 614, 6); //The Hot Dogger
					}
					case 15:
					{
						CreateHat(client, 611, 6); //The Salty Dog
					}
					case 16:
					{
						CreateHat(client, 671, 6); //The Brown Bomber
					}
					case 17:
					{
						CreateHat(client, 817, 6); //The Human Cannonball
					}
					case 18:
					{
						CreateHat(client, 993, 6); //Antlers
					}
					case 19:
					{
						CreateHat(client, 984, 6); //Tough Stuff Muffs
					}
					case 20:
					{
						CreateHat(client, 1014, 6); //The Brutal Bouffant
					}
					case 21:
					{
						CreateHat(client, 30066, 6); //The Brotherhood of Arms
					}	
					case 22:
					{
						CreateHat(client, 30067, 6); //The Well-Rounded Rifleman
					}
					case 23:
					{
						CreateHat(client, 30175, 6); //The Cotton Head
					}
					case 24:
					{
						CreateHat(client, 30177, 6); //Hong Kong Cone
					}
					case 25:
					{
						CreateHat(client, 30313, 6); //The Kiss King
					}
					case 26:
					{
						CreateHat(client, 30307, 6); //Neckwear Headwear
					}
					case 27:
					{
						CreateHat(client, 30329, 6); //The Polar Pullover
					}
					case 28:
					{
						CreateHat(client, 30362, 6); //The Law
					}
					case 29:
					{
						CreateHat(client, 30567, 6); //The Crown of the Old Kingdom
					}
					case 30:
					{
						CreateHat(client, 1164, 6, 50); //Civilian Grade JACK Hat
					}
					case 31:
					{
						CreateHat(client, 920, 6); //The Crone's Dome
					}
					case 32:
					{
						CreateHat(client, 30425, 6); //Tipped Lid
					}
					case 33:
					{
						CreateHat(client, 30413, 6); //The Merc's Mohawk
					}
					case 34:
					{
						CreateHat(client, 921, 6); //The Executioner
						face = true;
					}
					case 35:
					{
						CreateHat(client, 30422, 6); //Vive La France
						face = true;
					}
					case 36:
					{
						CreateHat(client, 291, 6); //Horrific Headsplitter
					}
					case 37:
					{
						CreateHat(client, 345, 6, 10); //MNC hat
					}
					case 38:
					{
						CreateHat(client, 785, 6, 10); //Robot Chicken Hat
					}
					case 39:
					{
						CreateHat(client, 702, 6); //Warsworn Helmet
						face = true;
					}
					case 40:
					{
						CreateHat(client, 634, 6); //Point and Shoot
					}
					case 41:
					{
						CreateHat(client, 942, 6); //Cockfighter
					}
					case 42:
					{
						CreateHat(client, 944, 6); //That 70s Chapeau
						face = true;
					}
					case 43:
					{
						CreateHat(client, 30065, 6); //Hardy Laurel
					}
					case 44:
					{
						CreateHat(client, 30571, 6); //Brimstone
					}
					case 45:
					{
						CreateHat(client, 30473, 6); //MK 50
					}
					case 46:
					{
						CreateHat(client, 126, 6); //Bill's Hat
					}
				}
			}
			case TFClass_Pyro:
			{
				int rnd = GetRandomUInt(0,46);
				switch (rnd)
				{
					case 1:
					{
						CreateHat(client, 940, 6, 10); //Ghostly Gibus
					}
					case 2:
					{
						CreateHat(client, 668, 6); //The Full Head of Steam
					}
					case 3:
					{
						CreateHat(client, 774, 6); //The Gentle Munitionne of Leisure
					}
					case 4:
					{
						CreateHat(client, 941, 6, 31); //The Skull Island Topper
					}
					case 5:
					{
						CreateHat(client, 30357, 6); //Dark Falkirk Helm - Fiquei Neste
					}
					case 6:
					{
						CreateHat(client, 538, 6); //Killer Exclusive
					}	
					case 7:
					{
						CreateHat(client, 139, 6); //Modest Pile of Hat
					}
					case 8:
					{
						CreateHat(client, 137, 6); //Noble Amassment of Hats
					}
					case 9:
					{
						CreateHat(client, 135, 6); //Towering Pillar of Hats
					}	
					case 10:
					{
						CreateHat(client, 30119, 6); //The Federal Casemaker
					}
					case 11:
					{
						CreateHat(client, 252, 6); //Dr's Dapper Topper
					}
					case 12:
					{
						CreateHat(client, 341, 6); //A Rather Festive Tree
					}
					case 13:
					{
						CreateHat(client, 523, 6, 10); //The Sarif Cap
					}
					case 14:
					{
						CreateHat(client, 614, 6); //The Hot Dogger
					}
					case 15:
					{
						CreateHat(client, 611, 6); //The Salty Dog
					}
					case 16:
					{
						CreateHat(client, 671, 6); //The Brown Bomber
					}
					case 17:
					{
						CreateHat(client, 817, 6); //The Human Cannonball
					}
					case 18:
					{
						CreateHat(client, 993, 6); //Antlers
					}
					case 19:
					{
						CreateHat(client, 984, 6); //Tough Stuff Muffs
					}
					case 20:
					{
						CreateHat(client, 1014, 6); //The Brutal Bouffant
					}
					case 21:
					{
						CreateHat(client, 30066, 6); //The Brotherhood of Arms
					}	
					case 22:
					{
						CreateHat(client, 30067, 6); //The Well-Rounded Rifleman
					}
					case 23:
					{
						CreateHat(client, 30175, 6); //The Cotton Head
					}
					case 24:
					{
						CreateHat(client, 30177, 6); //Hong Kong Cone
					}
					case 25:
					{
						CreateHat(client, 30313, 6); //The Kiss King
					}
					case 26:
					{
						CreateHat(client, 30307, 6); //Neckwear Headwear
					}
					case 27:
					{
						CreateHat(client, 30329, 6); //The Polar Pullover
					}
					case 28:
					{
						CreateHat(client, 30362, 6); //The Law
					}
					case 29:
					{
						CreateHat(client, 30567, 6); //The Crown of the Old Kingdom
					}
					case 30:
					{
						CreateHat(client, 1164, 6, 50); //Civilian Grade JACK Hat
					}
					case 31:
					{
						CreateHat(client, 920, 6); //The Crone's Dome
					}
					case 32:
					{
						CreateHat(client, 30425, 6); //Tipped Lid
					}
					case 33:
					{
						CreateHat(client, 30413, 6); //The Merc's Mohawk
					}
					case 34:
					{
						CreateHat(client, 921, 6); //The Executioner
						face = true;
					}
					case 35:
					{
						CreateHat(client, 30422, 6); //Vive La France
						face = true;
					}
					case 36:
					{
						CreateHat(client, 291, 6); //Horrific Headsplitter
					}
					case 37:
					{
						CreateHat(client, 345, 6, 10); //MNC hat
					}
					case 38:
					{
						CreateHat(client, 785, 6, 10); //Robot Chicken Hat
					}
					case 39:
					{
						CreateHat(client, 702, 6); //Warsworn Helmet
						face = true;
					}
					case 40:
					{
						CreateHat(client, 634, 6); //Point and Shoot
					}
					case 41:
					{
						CreateHat(client, 942, 6); //Cockfighter
					}
					case 42:
					{
						CreateHat(client, 944, 6); //That 70s Chapeau
						face = true;
					}
					case 43:
					{
						CreateHat(client, 30065, 6); //Hardy Laurel
					}
					case 44:
					{
						CreateHat(client, 30571, 6); //Brimstone
					}
					case 45:
					{
						CreateHat(client, 30473, 6); //MK 50
					}
					case 46:
					{
						CreateHat(client, 126, 6); //Bill's Hat
					}
				}
			}
			case TFClass_Spy:
			{
				int rnd = GetRandomUInt(0,46);
				switch (rnd)
				{
					case 1:
					{
						CreateHat(client, 940, 6, 10); //Ghostly Gibus
					}
					case 2:
					{
						CreateHat(client, 668, 6); //The Full Head of Steam
					}
					case 3:
					{
						CreateHat(client, 774, 6); //The Gentle Munitionne of Leisure
					}
					case 4:
					{
						CreateHat(client, 941, 6, 31); //The Skull Island Topper
					}
					case 5:
					{
						CreateHat(client, 30357, 6); //Dark Falkirk Helm - Fiquei Neste
					}
					case 6:
					{
						CreateHat(client, 538, 6); //Killer Exclusive
					}	
					case 7:
					{
						CreateHat(client, 139, 6); //Modest Pile of Hat
					}
					case 8:
					{
						CreateHat(client, 137, 6); //Noble Amassment of Hats
					}
					case 9:
					{
						CreateHat(client, 135, 6); //Towering Pillar of Hats
					}	
					case 10:
					{
						CreateHat(client, 30119, 6); //The Federal Casemaker
					}
					case 11:
					{
						CreateHat(client, 252, 6); //Dr's Dapper Topper
					}
					case 12:
					{
						CreateHat(client, 341, 6); //A Rather Festive Tree
					}
					case 13:
					{
						CreateHat(client, 523, 6, 10); //The Sarif Cap
					}
					case 14:
					{
						CreateHat(client, 614, 6); //The Hot Dogger
					}
					case 15:
					{
						CreateHat(client, 611, 6); //The Salty Dog
					}
					case 16:
					{
						CreateHat(client, 671, 6); //The Brown Bomber
					}
					case 17:
					{
						CreateHat(client, 817, 6); //The Human Cannonball
					}
					case 18:
					{
						CreateHat(client, 993, 6); //Antlers
					}
					case 19:
					{
						CreateHat(client, 984, 6); //Tough Stuff Muffs
					}
					case 20:
					{
						CreateHat(client, 1014, 6); //The Brutal Bouffant
					}
					case 21:
					{
						CreateHat(client, 30066, 6); //The Brotherhood of Arms
					}	
					case 22:
					{
						CreateHat(client, 30067, 6); //The Well-Rounded Rifleman
					}
					case 23:
					{
						CreateHat(client, 30175, 6); //The Cotton Head
					}
					case 24:
					{
						CreateHat(client, 30177, 6); //Hong Kong Cone
					}
					case 25:
					{
						CreateHat(client, 30313, 6); //The Kiss King
					}
					case 26:
					{
						CreateHat(client, 30307, 6); //Neckwear Headwear
					}
					case 27:
					{
						CreateHat(client, 30329, 6); //The Polar Pullover
					}
					case 28:
					{
						CreateHat(client, 30362, 6); //The Law
					}
					case 29:
					{
						CreateHat(client, 30567, 6); //The Crown of the Old Kingdom
					}
					case 30:
					{
						CreateHat(client, 1164, 6, 50); //Civilian Grade JACK Hat
					}
					case 31:
					{
						CreateHat(client, 920, 6); //The Crone's Dome
					}
					case 32:
					{
						CreateHat(client, 30425, 6); //Tipped Lid
					}
					case 33:
					{
						CreateHat(client, 30413, 6); //The Merc's Mohawk
					}
					case 34:
					{
						CreateHat(client, 921, 6); //The Executioner
						face = true;
					}
					case 35:
					{
						CreateHat(client, 30422, 6); //Vive La France
						face = true;
					}
					case 36:
					{
						CreateHat(client, 291, 6); //Horrific Headsplitter
					}
					case 37:
					{
						CreateHat(client, 345, 6, 10); //MNC hat
					}
					case 38:
					{
						CreateHat(client, 785, 6, 10); //Robot Chicken Hat
					}
					case 39:
					{
						CreateHat(client, 702, 6); //Warsworn Helmet
						face = true;
					}
					case 40:
					{
						CreateHat(client, 634, 6); //Point and Shoot
					}
					case 41:
					{
						CreateHat(client, 942, 6); //Cockfighter
					}
					case 42:
					{
						CreateHat(client, 944, 6); //That 70s Chapeau
						face = true;
					}
					case 43:
					{
						CreateHat(client, 30065, 6); //Hardy Laurel
					}
					case 44:
					{
						CreateHat(client, 30571, 6); //Brimstone
					}
					case 45:
					{
						CreateHat(client, 30473, 6); //MK 50
					}
					case 46:
					{
						CreateHat(client, 126, 6); //Bill's Hat
					}
				}
			}
			case TFClass_Engineer:
			{
				int rnd = GetRandomUInt(0,46);
				switch (rnd)
				{
					case 1:
					{
						CreateHat(client, 940, 6, 10); //Ghostly Gibus
					}
					case 2:
					{
						CreateHat(client, 668, 6); //The Full Head of Steam
					}
					case 3:
					{
						CreateHat(client, 774, 6); //The Gentle Munitionne of Leisure
					}
					case 4:
					{
						CreateHat(client, 941, 6, 31); //The Skull Island Topper
					}
					case 5:
					{
						CreateHat(client, 30357, 6); //Dark Falkirk Helm - Fiquei Neste
					}
					case 6:
					{
						CreateHat(client, 538, 6); //Killer Exclusive
					}	
					case 7:
					{
						CreateHat(client, 139, 6); //Modest Pile of Hat
					}
					case 8:
					{
						CreateHat(client, 137, 6); //Noble Amassment of Hats
					}
					case 9:
					{
						CreateHat(client, 135, 6); //Towering Pillar of Hats
					}	
					case 10:
					{
						CreateHat(client, 30119, 6); //The Federal Casemaker
					}
					case 11:
					{
						CreateHat(client, 252, 6); //Dr's Dapper Topper
					}
					case 12:
					{
						CreateHat(client, 341, 6); //A Rather Festive Tree
					}
					case 13:
					{
						CreateHat(client, 523, 6, 10); //The Sarif Cap
					}
					case 14:
					{
						CreateHat(client, 614, 6); //The Hot Dogger
					}
					case 15:
					{
						CreateHat(client, 611, 6); //The Salty Dog
					}
					case 16:
					{
						CreateHat(client, 671, 6); //The Brown Bomber
					}
					case 17:
					{
						CreateHat(client, 817, 6); //The Human Cannonball
					}
					case 18:
					{
						CreateHat(client, 993, 6); //Antlers
					}
					case 19:
					{
						CreateHat(client, 984, 6); //Tough Stuff Muffs
					}
					case 20:
					{
						CreateHat(client, 1014, 6); //The Brutal Bouffant
					}
					case 21:
					{
						CreateHat(client, 30066, 6); //The Brotherhood of Arms
					}	
					case 22:
					{
						CreateHat(client, 30067, 6); //The Well-Rounded Rifleman
					}
					case 23:
					{
						CreateHat(client, 30175, 6); //The Cotton Head
					}
					case 24:
					{
						CreateHat(client, 30177, 6); //Hong Kong Cone
					}
					case 25:
					{
						CreateHat(client, 30313, 6); //The Kiss King
					}
					case 26:
					{
						CreateHat(client, 30307, 6); //Neckwear Headwear
					}
					case 27:
					{
						CreateHat(client, 30329, 6); //The Polar Pullover
					}
					case 28:
					{
						CreateHat(client, 30362, 6); //The Law
					}
					case 29:
					{
						CreateHat(client, 30567, 6); //The Crown of the Old Kingdom
					}
					case 30:
					{
						CreateHat(client, 1164, 6, 50); //Civilian Grade JACK Hat
					}
					case 31:
					{
						CreateHat(client, 920, 6); //The Crone's Dome
					}
					case 32:
					{
						CreateHat(client, 30425, 6); //Tipped Lid
					}
					case 33:
					{
						CreateHat(client, 30413, 6); //The Merc's Mohawk
					}
					case 34:
					{
						CreateHat(client, 921, 6); //The Executioner
						face = true;
					}
					case 35:
					{
						CreateHat(client, 30422, 6); //Vive La France
						face = true;
					}
					case 36:
					{
						CreateHat(client, 291, 6); //Horrific Headsplitter
					}
					case 37:
					{
						CreateHat(client, 345, 6, 10); //MNC hat
					}
					case 38:
					{
						CreateHat(client, 785, 6, 10); //Robot Chicken Hat
					}
					case 39:
					{
						CreateHat(client, 702, 6); //Warsworn Helmet
						face = true;
					}
					case 40:
					{
						CreateHat(client, 634, 6); //Point and Shoot
					}
					case 41:
					{
						CreateHat(client, 942, 6); //Cockfighter
					}
					case 42:
					{
						CreateHat(client, 944, 6); //That 70s Chapeau
						face = true;
					}
					case 43:
					{
						CreateHat(client, 30065, 6); //Hardy Laurel
					}
					case 44:
					{
						CreateHat(client, 30571, 6); //Brimstone
					}
					case 45:
					{
						CreateHat(client, 30473, 6); //MK 50
					}
					case 46:
					{
						CreateHat(client, 126, 6); //Bill's Hat
					}
				}
			}
		}
	}	
		
	if ( !face )
	{
		TFClassType class = TF2_GetPlayerClass(client);
	
		switch (class)
		{
			case TFClass_Scout:
			{
				int rnd2 = GetRandomUInt(0,41);
				switch (rnd2)
				{
					case 1:
					{
						CreateHat(client, 30569, 6); //The Tomb Readers
					}
					case 2:
					{
						CreateHat(client, 744, 6); //Pyrovision Goggles
					}
					case 3:
					{
						CreateHat(client, 522, 6); //The Deus Specs
					}
					case 4:
					{
						CreateHat(client, 816, 6); //The Marxman
					}
					case 5:
					{
						CreateHat(client, 30104, 6); //Graybanns
					}
					case 6:
					{
						CreateHat(client, 30306, 6); //The Dictator
					}
					case 7:
					{
						CreateHat(client, 30352, 6); //The Mustachioed Mann
					}
					case 8:
					{
						CreateHat(client, 30414, 6); //The Eye-Catcher
					}
					case 9:
					{
						CreateHat(client, 30140, 6); //The Virtual Viewfinder
					}
					case 10:
					{
						CreateHat(client, 30397, 6); //The Bruiser's Bandanna
					}
					case 11:
					{
						CreateHat(client, 30569, 1); //The Tomb Readers
					}	
					case 12:
					{
						CreateHat(client, 744, 3); //Pyrovision Goggles
					}	
					case 13:
					{
						CreateHat(client, 522, 1); //The Deus Specs
					}	
					case 14:
					{
						CreateHat(client, 816, 1); //The Marxman
					}		
					case 15:
					{
						CreateHat(client, 816, 11); //The Marxman
					}	
					case 16:
					{
						CreateHat(client, 30104, 11); //Graybanns
					}
					case 17:
					{
						CreateHat(client, 30306, 11); //The Dictator
					}	
					case 18:
					{
						CreateHat(client, 30352, 11); //The Mustachioed Mann
					}
					case 19:
					{
						CreateHat(client, 30414, 11); //The Eye-Catcher
					}
					case 20:
					{
						CreateHat(client, 30140, 11); //The Virtual Viewfinder
					}
					case 21:
					{
						CreateHat(client, 30397, 11); //The Bruiser's Bandanna
					}
					case 22:
					{
						CreateHat(client, 143, 6); //Earbuds
					}
					case 23:
					{
						CreateHat(client, 343, 6); //Professor Speks
					}
					case 24:
					{
						CreateHat(client, 486, 6); //Summer Shades
					}
					case 25:
					{
						CreateHat(client, 486, 11); //Summer Shades
					}
					case 26:
					{
						CreateHat(client, 582, 6); //Seal Mask
					}
					case 27:
					{
						CreateHat(client, 451, 6); //Bonk Boy
					}
					case 28:
					{
						CreateHat(client, 451, 11); //Bonk Boy
					}
					case 29:
					{
						CreateHat(client, 468, 1); //Planeswalker Goggles
					}
					case 30:
					{
						CreateHat(client, 468, 6); //Planeswalker Goggles
					}
					case 31:
					{
						CreateHat(client, 630, 6); //The Stereoscopic Shades
					}
					case 32:
					{
						CreateHat(client, 630, 11); //The Stereoscopic Shades
					}
					case 33:
					{
						CreateHat(client, 30027, 6); //Bolt Boy
					}
					case 34:
					{
						CreateHat(client, 30027, 11); //Bolt Boy
					}
					case 35:
					{
						CreateHat(client, 30085, 6); //The Macho Mann
					}
					case 36:
					{
						CreateHat(client, 30085, 11); //The Macho Mann
					}
					case 37:
					{
						CreateHat(client, 30661, 11); //Cadet Visor
					}
					case 38:
					{
						CreateHat(client, 30661, 15); //Cadet Visor
					}
					case 39:
					{
						CreateHat(client, 30231, 6); //The Face Plante
					}
					case 40:
					{
						CreateHat(client, 30231, 13); //The Face Plante
					}
					case 41:
					{
						CreateHat(client, 30414, 11); //The Eye-Catcher
					}
				}
			}
			case TFClass_Sniper:
			{
				int rnd2 = GetRandomUInt(0,47);
				switch (rnd2)
				{
					case 1:
					{
						CreateHat(client, 30569, 6); //The Tomb Readers
					}
					case 2:
					{
						CreateHat(client, 744, 6); //Pyrovision Goggles
					}
					case 3:
					{
						CreateHat(client, 522, 6); //The Deus Specs
					}
					case 4:
					{
						CreateHat(client, 816, 6); //The Marxman
					}
					case 5:
					{
						CreateHat(client, 30104, 6); //Graybanns
					}
					case 6:
					{
						CreateHat(client, 30306, 6); //The Dictator
					}
					case 7:
					{
						CreateHat(client, 30352, 6); //The Mustachioed Mann
					}
					case 8:
					{
						CreateHat(client, 30414, 6); //The Eye-Catcher
					}
					case 9:
					{
						CreateHat(client, 30140, 6); //The Virtual Viewfinder
					}
					case 10:
					{
						CreateHat(client, 30397, 6); //The Bruiser's Bandanna
					}
					case 11:
					{
						CreateHat(client, 30569, 1); //The Tomb Readers
					}	
					case 12:
					{
						CreateHat(client, 744, 3); //Pyrovision Goggles
					}	
					case 13:
					{
						CreateHat(client, 522, 1); //The Deus Specs
					}	
					case 14:
					{
						CreateHat(client, 816, 1); //The Marxman
					}		
					case 15:
					{
						CreateHat(client, 816, 11); //The Marxman
					}	
					case 16:
					{
						CreateHat(client, 30104, 11); //Graybanns
					}
					case 17:
					{
						CreateHat(client, 30306, 11); //The Dictator
					}	
					case 18:
					{
						CreateHat(client, 30352, 11); //The Mustachioed Mann
					}
					case 19:
					{
						CreateHat(client, 30414, 11); //The Eye-Catcher
					}
					case 20:
					{
						CreateHat(client, 30140, 11); //The Virtual Viewfinder
					}
					case 21:
					{
						CreateHat(client, 30397, 11); //The Bruiser's Bandanna
					}
					case 22:
					{
						CreateHat(client, 143, 6); //Earbuds
					}
					case 23:
					{
						CreateHat(client, 343, 6); //Professor Speks
					}
					case 24:
					{
						CreateHat(client, 486, 6); //Summer Shades
					}
					case 25:
					{
						CreateHat(client, 486, 11); //Summer Shades
					}
					case 26:
					{
						CreateHat(client, 582, 6); //Seal Mask
					}
					case 27:
					{
						CreateHat(client, 30085, 6); //The Macho Mann
					}
					case 28:
					{
						CreateHat(client, 30085, 11); //The Macho Mann
					}
					case 29:
					{
						CreateHat(client, 393, 6); //Villain's Veil
					}
					case 30:
					{
						CreateHat(client, 393, 11); //Villain's Veil
					}
					case 31:
					{
						CreateHat(client, 534, 6); //Sniper's Snipin' Glass
					}
					case 32:
					{
						CreateHat(client, 986, 6); //The Mutton Mann
					}
					case 33:
					{
						CreateHat(client, 986, 11); //The Mutton Mann
					}
					case 34:
					{
						CreateHat(client, 30317, 6); //The Five-Month Shadow
					}
					case 35:
					{
						CreateHat(client, 30317, 11); //The Five-Month Shadow
					}
					case 36:
					{
						CreateHat(client, 30423, 6); //The Scoper's Smoke
					}
					case 37:
					{
						CreateHat(client, 30423, 11); //The Scoper's Smoke
					}
					case 38:
					{
						CreateHat(client, 30597, 6); //Bushman's Bristles
					}
					case 39:
					{
						CreateHat(client, 30597, 11); //Bushman's Bristles
					}
					case 40:
					{
						CreateHat(client, 647, 6); //The All-Father
					}
					case 41:
					{
						CreateHat(client, 647, 11); //The All-Father
					}
					case 42:
					{
						CreateHat(client, 30499, 6); //Conspiratorial Cut
					}
					case 43:
					{
						CreateHat(client, 30499, 11); //Conspiratorial Cut
					}
					case 44:
					{
						CreateHat(client, 30499, 13); //Conspiratorial Cut
					}
					case 45:
					{
						CreateHat(client, 783, 6); //The HazMat Headcase
					}
					case 46:
					{
						CreateHat(client, 783, 11); //The HazMat Headcase
					}
					case 47:
					{
						CreateHat(client, 30414, 11); //The Eye-Catcher
					}
				}
			}
			case TFClass_Soldier:
			{
				int rnd2 = GetRandomUInt(0,56);
				switch (rnd2)
				{
					case 1:
					{
						CreateHat(client, 30569, 6); //The Tomb Readers
					}
					case 2:
					{
						CreateHat(client, 744, 6); //Pyrovision Goggles
					}
					case 3:
					{
						CreateHat(client, 522, 6); //The Deus Specs
					}
					case 4:
					{
						CreateHat(client, 816, 6); //The Marxman
					}
					case 5:
					{
						CreateHat(client, 30104, 6); //Graybanns
					}
					case 6:
					{
						CreateHat(client, 30306, 6); //The Dictator
					}
					case 7:
					{
						CreateHat(client, 30352, 6); //The Mustachioed Mann
					}
					case 8:
					{
						CreateHat(client, 30414, 6); //The Eye-Catcher
					}
					case 9:
					{
						CreateHat(client, 30140, 6); //The Virtual Viewfinder
					}
					case 10:
					{
						CreateHat(client, 30397, 6); //The Bruiser's Bandanna
					}
					case 11:
					{
						CreateHat(client, 30569, 1); //The Tomb Readers
					}	
					case 12:
					{
						CreateHat(client, 744, 3); //Pyrovision Goggles
					}	
					case 13:
					{
						CreateHat(client, 522, 1); //The Deus Specs
					}	
					case 14:
					{
						CreateHat(client, 816, 1); //The Marxman
					}		
					case 15:
					{
						CreateHat(client, 816, 11); //The Marxman
					}	
					case 16:
					{
						CreateHat(client, 30104, 11); //Graybanns
					}
					case 17:
					{
						CreateHat(client, 30306, 11); //The Dictator
					}	
					case 18:
					{
						CreateHat(client, 30352, 11); //The Mustachioed Mann
					}
					case 19:
					{
						CreateHat(client, 30414, 11); //The Eye-Catcher
					}
					case 20:
					{
						CreateHat(client, 30140, 11); //The Virtual Viewfinder
					}
					case 21:
					{
						CreateHat(client, 30397, 11); //The Bruiser's Bandanna
					}
					case 22:
					{
						CreateHat(client, 143, 6); //Earbuds
					}
					case 23:
					{
						CreateHat(client, 343, 6); //Professor Speks
					}
					case 24:
					{
						CreateHat(client, 486, 6); //Summer Shades
					}
					case 25:
					{
						CreateHat(client, 486, 11); //Summer Shades
					}
					case 26:
					{
						CreateHat(client, 582, 6); //Seal Mask
					}
					case 27:
					{
						CreateHat(client, 30085, 6); //The Macho Mann
					}
					case 28:
					{
						CreateHat(client, 30085, 11); //The Macho Mann
					}
					case 29:
					{
						CreateHat(client, 986, 6); //The Mutton Mann
					}
					case 30:
					{
						CreateHat(client, 986, 11); //The Mutton Mann
					}
					case 31:
					{
						CreateHat(client, 440, 6); //Lord Cockswain's Novelty Mutton Chops and Pipe
					}
					case 32:
					{
						CreateHat(client, 440, 11); //Lord Cockswain's Novelty Mutton Chops and Pipe
					}
					case 33:
					{
						CreateHat(client, 647, 6); //The All-Father
					}
					case 34:
					{
						CreateHat(client, 647, 11); //The All-Father
					}
					case 35:
					{
						CreateHat(client, 852, 6); //The Soldier's Stogie
					}
					case 36:
					{
						CreateHat(client, 852, 11); //The Soldier's Stogie
					}
					case 37:
					{
						CreateHat(client, 875, 1); //The Menpo
					}
					case 38:
					{
						CreateHat(client, 875, 6); //The Menpo
					}
					case 39:
					{
						CreateHat(client, 30033, 6); //Soldier's Sparkplug
					}
					case 40:
					{
						CreateHat(client, 30033, 11); //Soldier's Sparkplug
					}
					case 41:
					{
						CreateHat(client, 30164, 6); //The Viking Braider
					}
					case 42:
					{
						CreateHat(client, 30164, 11); //The Viking Braider
					}
					case 43:
					{
						CreateHat(client, 30335, 6); //Marshall's Mutton Chops
					}
					case 44:
					{
						CreateHat(client, 30335, 11); //Marshall's Mutton Chops
					}
					case 45:
					{
						CreateHat(client, 30477, 6); //The Lone Survivor
					}
					case 46:
					{
						CreateHat(client, 30477, 11); //The Lone Survivor
					}
					case 47:
					{
						CreateHat(client, 30554, 6); //Mistaken Movember
					}
					case 48:
					{
						CreateHat(client, 30554, 11); //Mistaken Movember
					}
					case 49:
					{
						CreateHat(client, 30227, 6); //The Faux Manchu
					}
					case 50:
					{
						CreateHat(client, 30227, 13); //The Faux Manchu
					}
					case 51:
					{
						CreateHat(client, 30522, 6); //Supernatural Stalker
					}
					case 52:
					{
						CreateHat(client, 30522, 11); //Supernatural Stalker
					}
					case 53:
					{
						CreateHat(client, 30522, 13); //Supernatural Stalker
					}
					case 54:
					{
						CreateHat(client, 30165, 6); //The Cuban Bristle Crisis
					}
					case 55:
					{
						CreateHat(client, 30165, 11); //The Cuban Bristle Crisis
					}
					case 56:
					{
						CreateHat(client, 30414, 11); //The Eye-Catcher
					}
				}
			}
			case TFClass_DemoMan:
			{
				int rnd2 = GetRandomUInt(0,51);
				switch (rnd2)
				{
					case 1:
					{
						CreateHat(client, 30569, 6); //The Tomb Readers
					}
					case 2:
					{
						CreateHat(client, 744, 6); //Pyrovision Goggles
					}
					case 3:
					{
						CreateHat(client, 522, 6); //The Deus Specs
					}
					case 4:
					{
						CreateHat(client, 816, 6); //The Marxman
					}
					case 5:
					{
						CreateHat(client, 30104, 6); //Graybanns
					}
					case 6:
					{
						CreateHat(client, 30306, 6); //The Dictator
					}
					case 7:
					{
						CreateHat(client, 30352, 6); //The Mustachioed Mann
					}
					case 8:
					{
						CreateHat(client, 30414, 6); //The Eye-Catcher
					}
					case 9:
					{
						CreateHat(client, 30140, 6); //The Virtual Viewfinder
					}
					case 10:
					{
						CreateHat(client, 30397, 6); //The Bruiser's Bandanna
					}
					case 11:
					{
						CreateHat(client, 30569, 1); //The Tomb Readers
					}	
					case 12:
					{
						CreateHat(client, 744, 3); //Pyrovision Goggles
					}	
					case 13:
					{
						CreateHat(client, 522, 1); //The Deus Specs
					}	
					case 14:
					{
						CreateHat(client, 816, 1); //The Marxman
					}		
					case 15:
					{
						CreateHat(client, 816, 11); //The Marxman
					}	
					case 16:
					{
						CreateHat(client, 30104, 11); //Graybanns
					}
					case 17:
					{
						CreateHat(client, 30306, 11); //The Dictator
					}	
					case 18:
					{
						CreateHat(client, 30352, 11); //The Mustachioed Mann
					}
					case 19:
					{
						CreateHat(client, 30414, 11); //The Eye-Catcher
					}
					case 20:
					{
						CreateHat(client, 30140, 11); //The Virtual Viewfinder
					}
					case 21:
					{
						CreateHat(client, 30397, 11); //The Bruiser's Bandanna
					}
					case 22:
					{
						CreateHat(client, 143, 6); //Earbuds
					}
					case 23:
					{
						CreateHat(client, 343, 6); //Professor Speks
					}
					case 24:
					{
						CreateHat(client, 486, 6); //Summer Shades
					}
					case 25:
					{
						CreateHat(client, 486, 11); //Summer Shades
					}
					case 26:
					{
						CreateHat(client, 582, 6); //Seal Mask
					}
					case 27:
					{
						CreateHat(client, 30085, 6); //The Macho Mann
					}
					case 28:
					{
						CreateHat(client, 30085, 11); //The Macho Mann
					}
					case 29:
					{
						CreateHat(client, 986, 6); //The Mutton Mann
					}
					case 30:
					{
						CreateHat(client, 986, 11); //The Mutton Mann
					}
					case 31:
					{
						CreateHat(client, 647, 6); //The All-Father
					}
					case 32:
					{
						CreateHat(client, 647, 11); //The All-Father
					}
					case 33:
					{
						CreateHat(client, 875, 1); //The Menpo
					}
					case 34:
					{
						CreateHat(client, 875, 6); //The Menpo
					}
					case 35:
					{
						CreateHat(client, 295, 6); //Dangeresque, Too?!
					}
					case 36:
					{
						CreateHat(client, 709, 6); //The Snapped Pupil
					}
					case 37:
					{
						CreateHat(client, 709, 11); //The Snapped Pupil
					}
					case 38:
					{
						CreateHat(client, 830, 6); //The Bearded Bombardier
					}
					case 39:
					{
						CreateHat(client, 830, 11); //The Bearded Bombardier
					}
					case 40:
					{
						CreateHat(client, 30010, 6); //The HDMI Patch
					}
					case 41:
					{
						CreateHat(client, 30010, 11); //The HDMI Patch
					}
					case 42:
					{
						CreateHat(client, 30011, 6); //Bolted Bombardier
					}
					case 43:
					{
						CreateHat(client, 30011, 11); //Bolted Bombardier
					}
					case 44:
					{
						CreateHat(client, 30430, 6); //Seeing Double
					}
					case 45:
					{
						CreateHat(client, 30430, 11); //Seeing Double
					}
					case 46:
					{
						CreateHat(client, 30518, 6); //Eyeborg
					}
					case 47:
					{
						CreateHat(client, 30518, 11); //Eyeborg
					}
					case 48:
					{
						CreateHat(client, 30518, 13); //Eyeborg
					}
					case 49:
					{
						CreateHat(client, 30414, 11); //The Eye-Catcher
					}
					case 50:
					{
						CreateHat(client, 1019, 6); //Blind Justice
					}
					case 51:
					{
						CreateHat(client, 1019, 1); //Blind Justice
					}
				}
			}
			case TFClass_Medic:
			{
				int rnd2 = GetRandomUInt(0,58);
				switch (rnd2)
				{
					case 1:
					{
						CreateHat(client, 30569, 6); //The Tomb Readers
					}
					case 2:
					{
						CreateHat(client, 744, 6); //Pyrovision Goggles
					}
					case 3:
					{
						CreateHat(client, 522, 6); //The Deus Specs
					}
					case 4:
					{
						CreateHat(client, 816, 6); //The Marxman
					}
					case 5:
					{
						CreateHat(client, 30104, 6); //Graybanns
					}
					case 6:
					{
						CreateHat(client, 30306, 6); //The Dictator
					}
					case 7:
					{
						CreateHat(client, 30352, 6); //The Mustachioed Mann
					}
					case 8:
					{
						CreateHat(client, 30414, 6); //The Eye-Catcher
					}
					case 9:
					{
						CreateHat(client, 30140, 6); //The Virtual Viewfinder
					}
					case 10:
					{
						CreateHat(client, 30397, 6); //The Bruiser's Bandanna
					}
					case 11:
					{
						CreateHat(client, 30569, 1); //The Tomb Readers
					}	
					case 12:
					{
						CreateHat(client, 744, 3); //Pyrovision Goggles
					}	
					case 13:
					{
						CreateHat(client, 522, 1); //The Deus Specs
					}	
					case 14:
					{
						CreateHat(client, 816, 1); //The Marxman
					}		
					case 15:
					{
						CreateHat(client, 816, 11); //The Marxman
					}	
					case 16:
					{
						CreateHat(client, 30104, 11); //Graybanns
					}
					case 17:
					{
						CreateHat(client, 30306, 11); //The Dictator
					}	
					case 18:
					{
						CreateHat(client, 30352, 11); //The Mustachioed Mann
					}
					case 19:
					{
						CreateHat(client, 30414, 11); //The Eye-Catcher
					}
					case 20:
					{
						CreateHat(client, 30140, 11); //The Virtual Viewfinder
					}
					case 21:
					{
						CreateHat(client, 30397, 11); //The Bruiser's Bandanna
					}
					case 22:
					{
						CreateHat(client, 143, 6); //Earbuds
					}
					case 23:
					{
						CreateHat(client, 343, 6); //Professor Speks
					}
					case 24:
					{
						CreateHat(client, 486, 6); //Summer Shades
					}
					case 25:
					{
						CreateHat(client, 486, 11); //Summer Shades
					}
					case 26:
					{
						CreateHat(client, 582, 6); //Seal Mask
					}
					case 27:
					{
						CreateHat(client, 30085, 6); //The Macho Mann
					}
					case 28:
					{
						CreateHat(client, 30085, 11); //The Macho Mann
					}
					case 29:
					{
						CreateHat(client, 986, 6); //The Mutton Mann
					}
					case 30:
					{
						CreateHat(client, 986, 11); //The Mutton Mann
					}
					case 31:
					{
						CreateHat(client, 647, 6); //The All-Father
					}
					case 32:
					{
						CreateHat(client, 647, 11); //The All-Father
					}
					case 33:
					{
						CreateHat(client, 144, 3); //Physician's Procedure Mask
					}
					case 34:
					{
						CreateHat(client, 144, 6); //Physician's Procedure Mask
					}
					case 35:
					{
						CreateHat(client, 315, 6); //Blighted Beak
					}
					case 36:
					{
						CreateHat(client, 30046, 6); //Practitioner's Processing Mask
					}
					case 37:
					{
						CreateHat(client, 30046, 11); //Practitioner's Processing Mask
					}
					case 38:
					{
						CreateHat(client, 30052, 6); //The Byte'd Beak
					}
					case 39:
					{
						CreateHat(client, 30052, 11); //The Byte'd Beak
					}
					case 40:
					{
						CreateHat(client, 30095, 6); //Das Hazmattenhatten
					}
					case 41:
					{
						CreateHat(client, 30095, 11); //Das Hazmattenhatten
					}
					case 42:
					{
						CreateHat(client, 30186, 6); //A Brush with Death
					}
					case 43:
					{
						CreateHat(client, 30186, 11); //A Brush with Death
					}
					case 44:
					{
						CreateHat(client, 30323, 6); //The Ruffled Ruprecht
					}
					case 45:
					{
						CreateHat(client, 30323, 11); //The Ruffled Ruprecht
					}
					case 46:
					{
						CreateHat(client, 30349, 6); //The Fashionable Megalomaniac
					}
					case 47:
					{
						CreateHat(client, 30349, 11); //The Fashionable Megalomaniac
					}
					case 48:
					{
						CreateHat(client, 30410, 6); //Ze Ubermensch
					}
					case 49:
					{
						CreateHat(client, 30410, 11); //Ze Ubermensch
					}
					case 50:
					{
						CreateHat(client, 30595, 6); //Unknown Mann
					}
					case 51:
					{
						CreateHat(client, 30595, 11); //Unknown Mann
					}
					case 52:
					{
						CreateHat(client, 553, 6); //Dr. Googlestache
					}
					case 53:
					{
						CreateHat(client, 553, 13); //Dr. Googlestache
					}
					case 54:
					{
						CreateHat(client, 30197, 6); //The Second Opinion
					}
					case 55:
					{
						CreateHat(client, 30197, 13); //The Second Opinion
					}
					case 56:
					{
						CreateHat(client, 30414, 11); //The Eye-Catcher
					}
					case 57:
					{
						CreateHat(client, 657, 6); //The Nine-Pipe Problem
					}
					case 58:
					{
						CreateHat(client, 657, 11); //The Nine-Pipe Problem
					}
				}
			}
			case TFClass_Heavy:
			{
				int rnd2 = GetRandomUInt(0,56);
				switch (rnd2)
				{
					case 1:
					{
						CreateHat(client, 30569, 6); //The Tomb Readers
					}
					case 2:
					{
						CreateHat(client, 744, 6); //Pyrovision Goggles
					}
					case 3:
					{
						CreateHat(client, 522, 6); //The Deus Specs
					}
					case 4:
					{
						CreateHat(client, 816, 6); //The Marxman
					}
					case 5:
					{
						CreateHat(client, 30104, 6); //Graybanns
					}
					case 6:
					{
						CreateHat(client, 30306, 6); //The Dictator
					}
					case 7:
					{
						CreateHat(client, 30352, 6); //The Mustachioed Mann
					}
					case 8:
					{
						CreateHat(client, 30414, 6); //The Eye-Catcher
					}
					case 9:
					{
						CreateHat(client, 30140, 6); //The Virtual Viewfinder
					}
					case 10:
					{
						CreateHat(client, 30397, 6); //The Bruiser's Bandanna
					}
					case 11:
					{
						CreateHat(client, 30569, 1); //The Tomb Readers
					}	
					case 12:
					{
						CreateHat(client, 744, 3); //Pyrovision Goggles
					}	
					case 13:
					{
						CreateHat(client, 522, 1); //The Deus Specs
					}	
					case 14:
					{
						CreateHat(client, 816, 1); //The Marxman
					}		
					case 15:
					{
						CreateHat(client, 816, 11); //The Marxman
					}	
					case 16:
					{
						CreateHat(client, 30104, 11); //Graybanns
					}
					case 17:
					{
						CreateHat(client, 30306, 11); //The Dictator
					}	
					case 18:
					{
						CreateHat(client, 30352, 11); //The Mustachioed Mann
					}
					case 19:
					{
						CreateHat(client, 30414, 11); //The Eye-Catcher
					}
					case 20:
					{
						CreateHat(client, 30140, 11); //The Virtual Viewfinder
					}
					case 21:
					{
						CreateHat(client, 30397, 11); //The Bruiser's Bandanna
					}
					case 22:
					{
						CreateHat(client, 143, 6); //Earbuds
					}
					case 23:
					{
						CreateHat(client, 343, 6); //Professor Speks
					}
					case 24:
					{
						CreateHat(client, 486, 6); //Summer Shades
					}
					case 25:
					{
						CreateHat(client, 486, 11); //Summer Shades
					}
					case 26:
					{
						CreateHat(client, 582, 6); //Seal Mask
					}
					case 27:
					{
						CreateHat(client, 30085, 6); //The Macho Mann
					}
					case 28:
					{
						CreateHat(client, 30085, 11); //The Macho Mann
					}
					case 29:
					{
						CreateHat(client, 986, 6); //The Mutton Mann
					}
					case 30:
					{
						CreateHat(client, 986, 11); //The Mutton Mann
					}
					case 31:
					{
						CreateHat(client, 647, 6); //The All-Father
					}
					case 32:
					{
						CreateHat(client, 647, 11); //The All-Father
					}
					case 33:
					{
						CreateHat(client, 30164, 6); //The Viking Braider
					}
					case 34:
					{
						CreateHat(client, 30164, 11); //The Viking Braider
					}
					case 35:
					{
						CreateHat(client, 479, 6); //Security Shades
					}
					case 36:
					{
						CreateHat(client, 485, 6); //Big Steel Jaw of Summer Fun
					}
					case 37:
					{
						CreateHat(client, 30141, 6); //The Gabe Glasses
					}
					case 38:
					{
						CreateHat(client, 30141, 11); //The Gabe Glasses
					}
					case 39:
					{
						CreateHat(client, 30165, 6); //The Cuban Bristle Crisis
					}
					case 40:
					{
						CreateHat(client, 30165, 11); //The Cuban Bristle Crisis
					}
					case 41:
					{
						CreateHat(client, 30345, 6); //The Leftover Trap
					}
					case 42:
					{
						CreateHat(client, 30345, 11); //The Leftover Trap
					}
					case 43:
					{
						CreateHat(client, 30368, 6); //The War Goggles
					}
					case 44:
					{
						CreateHat(client, 30368, 11); //The War Goggles
					}
					case 45:
					{
						CreateHat(client, 30401, 6); //Yuri's Revenge
					}
					case 46:
					{
						CreateHat(client, 30401, 11); //Yuri's Revenge
					}
					case 47:
					{
						CreateHat(client, 30482, 6); //Yuri's Revenge
					}
					case 48:
					{
						CreateHat(client, 30482, 11); //Yuri's Revenge
					}
					case 49:
					{
						CreateHat(client, 30645, 15); //El Duderino
					}
					case 50:
					{
						CreateHat(client, 30645, 11); //El Duderino
					}
					case 51:
					{
						CreateHat(client, 30280, 6); //The Monstrous Mandible
					}
					case 52:
					{
						CreateHat(client, 30280, 13); //The Monstrous Mandible
					}
					case 53:
					{
						CreateHat(client, 30532, 6); //Bull Locks
					}
					case 54:
					{
						CreateHat(client, 30532, 11); //Bull Locks
					}
					case 55:
					{
						CreateHat(client, 30532, 13); //Bull Locks
					}
					case 56:
					{
						CreateHat(client, 30414, 11); //The Eye-Catcher
					}
				}
			}
			case TFClass_Pyro:
			{
				int rnd2 = GetRandomUInt(0,107);
				switch (rnd2)
				{
					case 1:
					{
						CreateHat(client, 30569, 6); //The Tomb Readers
					}
					case 2:
					{
						CreateHat(client, 744, 6); //Pyrovision Goggles
					}
					case 3:
					{
						CreateHat(client, 522, 6); //The Deus Specs
					}
					case 4:
					{
						CreateHat(client, 816, 6); //The Marxman
					}
					case 5:
					{
						CreateHat(client, 30104, 6); //Graybanns
					}
					case 6:
					{
						CreateHat(client, 30306, 6); //The Dictator
					}
					case 7:
					{
						CreateHat(client, 30352, 6); //The Mustachioed Mann
					}
					case 8:
					{
						CreateHat(client, 30414, 6); //The Eye-Catcher
					}
					case 9:
					{
						CreateHat(client, 30140, 6); //The Virtual Viewfinder
					}
					case 10:
					{
						CreateHat(client, 30397, 6); //The Bruiser's Bandanna
					}
					case 11:
					{
						CreateHat(client, 30569, 1); //The Tomb Readers
					}	
					case 12:
					{
						CreateHat(client, 744, 3); //Pyrovision Goggles
					}	
					case 13:
					{
						CreateHat(client, 522, 1); //The Deus Specs
					}	
					case 14:
					{
						CreateHat(client, 816, 1); //The Marxman
					}		
					case 15:
					{
						CreateHat(client, 816, 11); //The Marxman
					}	
					case 16:
					{
						CreateHat(client, 30104, 11); //Graybanns
					}
					case 17:
					{
						CreateHat(client, 30306, 11); //The Dictator
					}	
					case 18:
					{
						CreateHat(client, 30352, 11); //The Mustachioed Mann
					}
					case 19:
					{
						CreateHat(client, 30414, 11); //The Eye-Catcher
					}
					case 20:
					{
						CreateHat(client, 30140, 11); //The Virtual Viewfinder
					}
					case 21:
					{
						CreateHat(client, 30397, 11); //The Bruiser's Bandanna
					}
					case 22:
					{
						CreateHat(client, 143, 6); //Earbuds
					}
					case 23:
					{
						CreateHat(client, 343, 6); //Professor Speks
					}
					case 24:
					{
						CreateHat(client, 486, 6); //Summer Shades
					}
					case 25:
					{
						CreateHat(client, 486, 11); //Summer Shades
					}
					case 26:
					{
						CreateHat(client, 582, 6); //Seal Mask
					}
					case 27:
					{
						CreateHat(client, 175, 3); //Whiskered Gentleman
					}
					case 28:
					{
						CreateHat(client, 175, 6); //Whiskered Gentleman
					}
					case 29:
					{
						CreateHat(client, 335, 3); //Foster's Facade
					}
					case 30:
					{
						CreateHat(client, 335, 6); //Foster's Facade
					}
					case 31:
					{
						CreateHat(client, 335, 6); //Foster's Facade
					}
					case 32:
					{
						CreateHat(client, 335, 11); //Foster's Facade
					}
					case 33:
					{
						CreateHat(client, 570, 6); //The Last Breath
					}
					case 34:
					{
						CreateHat(client, 570, 11); //The Last Breath
					}
					case 35:
					{
						CreateHat(client, 571, 6); //Apparition's Aspect
					}
					case 36:
					{
						CreateHat(client, 571, 11); //Apparition's Aspect
					}
					case 37:
					{
						CreateHat(client, 783, 6); //The HazMat Headcase
					}
					case 38:
					{
						CreateHat(client, 783, 11); //The HazMat Headcase
					}
					case 39:
					{
						CreateHat(client, 950, 6); //Nose Candy
					}
					case 40:
					{
						CreateHat(client, 976, 6); //Winter Wonderland Wrap
					}
					case 41:
					{
						CreateHat(client, 976, 11); //Winter Wonderland Wrap
					}
					case 42:
					{
						CreateHat(client, 1020, 1); //The Person in the Iron Mask
					}
					case 43:
					{
						CreateHat(client, 1020, 6); //The Person in the Iron Mask
					}
					case 44:
					{
						CreateHat(client, 1038, 6); //The Breather Bag
					}
					case 45:
					{
						CreateHat(client, 1124, 1); //The Nabler
					}
					case 46:
					{
						CreateHat(client, 1124, 6); //The Nabler
					}
					case 47:
					{
						CreateHat(client, 30032, 6); //The Rusty Reaper
					}
					case 48:
					{
						CreateHat(client, 30032, 11); //The Rusty Reaper
					}
					case 49:
					{
						CreateHat(client, 30036, 6); //The Filamental
					}
					case 50:
					{
						CreateHat(client, 30036, 11); //The Filamental
					}
					case 51:
					{
						CreateHat(client, 30053, 6); //The Googol Glass Eyes
					}
					case 52:
					{
						CreateHat(client, 30053, 11); //The Googol Glass Eyes
					}
					case 53:
					{
						CreateHat(client, 30075, 6); //The Mair Mask
					}
					case 54:
					{
						CreateHat(client, 30075, 11); //The Mair Mask
					}
					case 55:
					{
						CreateHat(client, 30163, 6); //The Air Raider
					}
					case 56:
					{
						CreateHat(client, 30163, 11); //The Air Raider
					}
					case 57:
					{
						CreateHat(client, 30176, 6); //Pop-eyes
					}
					case 58:
					{
						CreateHat(client, 30176, 11); //Pop-eyes
					}
					case 59:
					{
						CreateHat(client, 30304, 6); //The Blizzard Breather
					}
					case 60:
					{
						CreateHat(client, 30304, 11); //The Blizzard Breather
					}
					case 61:
					{
						CreateHat(client, 30367, 6); //The Blizzard Breather
					}
					case 62:
					{
						CreateHat(client, 30367, 11); //The Blizzard Breather
					}
					case 63:
					{
						CreateHat(client, 30475, 6); //The Mishap Mercenary
					}
					case 64:
					{
						CreateHat(client, 30475, 11); //The Mishap Mercenary
					}
					case 65:
					{
						CreateHat(client, 30538, 6); //Wartime Warmth
					}
					case 66:
					{
						CreateHat(client, 30538, 11); //Wartime Warmth
					}
					case 67:
					{
						CreateHat(client, 30582, 6); //Black Knight's Bascinet
					}
					case 68:
					{
						CreateHat(client, 30582, 11); //Black Knight's Bascinet
					}
					case 69:
					{
						CreateHat(client, 30652, 15); //Phobos Filter
					}
					case 70:
					{
						CreateHat(client, 30652, 11); //Phobos Filter
					}
					case 71:
					{
						CreateHat(client, 30191, 6); //The Beast From Below
					}
					case 72:
					{
						CreateHat(client, 30191, 13); //The Beast From Below
					}
					case 73:
					{
						CreateHat(client, 30192, 6); //Hard-Headed Hardware
					}
					case 74:
					{
						CreateHat(client, 30192, 13); //Hard-Headed Hardware
					}
					case 75:
					{
						CreateHat(client, 30194, 6); //The Spectralnaut
					}
					case 76:
					{
						CreateHat(client, 30194, 13); //The Spectralnaut
					}
					case 77:
					{
						CreateHat(client, 30213, 6); //Up Pyroscopes
					}
					case 78:
					{
						CreateHat(client, 30213, 13); //Up Pyroscopes
					}
					case 79:
					{
						CreateHat(client, 30218, 6); //The Rugged Respirator
					}
					case 80:
					{
						CreateHat(client, 30218, 13); //The Rugged Respirator
					}
					case 81:
					{
						CreateHat(client, 30220, 6); //The Hallowhead
					}
					case 82:
					{
						CreateHat(client, 30220, 13); //The Hallowhead
					}
					case 83:
					{
						CreateHat(client, 30222, 6); //The Gothic Guise
					}
					case 84:
					{
						CreateHat(client, 30222, 13); //The Gothic Guise
					}
					case 85:
					{
						CreateHat(client, 30269, 6); //The Macabre Mask
					}
					case 86:
					{
						CreateHat(client, 30269, 13); //The Macabre Mask
					}
					case 87:
					{
						CreateHat(client, 30273, 6); //The Vicious Visage
					}
					case 88:
					{
						CreateHat(client, 30273, 13); //The Vicious Visage
					}
					case 89:
					{
						CreateHat(client, 30286, 6); //The Glob
					}
					case 90:
					{
						CreateHat(client, 30286, 13); //The Glob
					}
					case 91:
					{
						CreateHat(client, 30290, 6); //PY-40 Incinibot
					}
					case 92:
					{
						CreateHat(client, 30290, 13); //PY-40 Incinibot
					}
					case 93:
					{
						CreateHat(client, 30525, 6); //Creature's Grin
					}
					case 94:
					{
						CreateHat(client, 30525, 13); //Creature's Grin
					}
					case 95:
					{
						CreateHat(client, 30525, 11); //Creature's Grin
					}
					case 96:
					{
						CreateHat(client, 30528, 6); //Lollichop Licker
					}
					case 97:
					{
						CreateHat(client, 30528, 13); //Lollichop Licker
					}
					case 98:
					{
						CreateHat(client, 30528, 11); //Lollichop Licker
					}
					case 99:
					{
						CreateHat(client, 30529, 6); //Mr. Juice
					}
					case 100:
					{
						CreateHat(client, 30529, 13); //Mr. Juice
					}
					case 101:
					{
						CreateHat(client, 30529, 11); //Mr. Juice
					}
					case 102:
					{
						CreateHat(client, 30530, 6); //Vampyro
					}
					case 103:
					{
						CreateHat(client, 30530, 13); //Vampyro
					}
					case 104:
					{
						CreateHat(client, 30530, 11); //Vampyro
					}
					case 105:
					{
						CreateHat(client, 30168, 6); //The Special Eyes
					}
					case 106:
					{
						CreateHat(client, 30168, 11); //The Special Eyes
					}
					case 107:
					{
						CreateHat(client, 30414, 11); //The Eye-Catcher
					}
				}
			}
			case TFClass_Spy:
			{
				int rnd2 = GetRandomUInt(0,47);
				switch (rnd2)
				{
					case 1:
					{
						CreateHat(client, 30569, 6); //The Tomb Readers
					}
					case 2:
					{
						CreateHat(client, 744, 6); //Pyrovision Goggles
					}
					case 3:
					{
						CreateHat(client, 522, 6); //The Deus Specs
					}
					case 4:
					{
						CreateHat(client, 816, 6); //The Marxman
					}
					case 5:
					{
						CreateHat(client, 30104, 6); //Graybanns
					}
					case 6:
					{
						CreateHat(client, 30306, 6); //The Dictator
					}
					case 7:
					{
						CreateHat(client, 30352, 6); //The Mustachioed Mann
					}
					case 8:
					{
						CreateHat(client, 30414, 6); //The Eye-Catcher
					}
					case 9:
					{
						CreateHat(client, 30140, 6); //The Virtual Viewfinder
					}
					case 10:
					{
						CreateHat(client, 30397, 6); //The Bruiser's Bandanna
					}
					case 11:
					{
						CreateHat(client, 30569, 1); //The Tomb Readers
					}	
					case 12:
					{
						CreateHat(client, 744, 3); //Pyrovision Goggles
					}	
					case 13:
					{
						CreateHat(client, 522, 1); //The Deus Specs
					}	
					case 14:
					{
						CreateHat(client, 816, 1); //The Marxman
					}		
					case 15:
					{
						CreateHat(client, 816, 11); //The Marxman
					}	
					case 16:
					{
						CreateHat(client, 30104, 11); //Graybanns
					}
					case 17:
					{
						CreateHat(client, 30306, 11); //The Dictator
					}	
					case 18:
					{
						CreateHat(client, 30352, 11); //The Mustachioed Mann
					}
					case 19:
					{
						CreateHat(client, 30414, 11); //The Eye-Catcher
					}
					case 20:
					{
						CreateHat(client, 30140, 11); //The Virtual Viewfinder
					}
					case 21:
					{
						CreateHat(client, 30397, 11); //The Bruiser's Bandanna
					}
					case 22:
					{
						CreateHat(client, 143, 6); //Earbuds
					}
					case 23:
					{
						CreateHat(client, 343, 6); //Professor Speks
					}
					case 24:
					{
						CreateHat(client, 486, 6); //Summer Shades
					}
					case 25:
					{
						CreateHat(client, 486, 11); //Summer Shades
					}
					case 26:
					{
						CreateHat(client, 582, 6); //Seal Mask
					}
					case 27:
					{
						CreateHat(client, 30085, 6); //The Macho Mann
					}
					case 28:
					{
						CreateHat(client, 30085, 11); //The Macho Mann
					}
					case 29:
					{
						CreateHat(client, 103, 1); //Camera Beard
					}
					case 30:
					{
						CreateHat(client, 103, 3); //Camera Beard
					}
					case 31:
					{
						CreateHat(client, 103, 6); //Camera Beard
					}
					case 32:
					{
						CreateHat(client, 103, 11); //Camera Beard
					}
					case 33:
					{
						CreateHat(client, 337, 6); //Le Party Phantom
					}
					case 34:
					{
						CreateHat(client, 629, 6); //The Spectre's Spectacles
					}
					case 35:
					{
						CreateHat(client, 629, 11); //The Spectre's Spectacles
					}
					case 36:
					{
						CreateHat(client, 919, 6); //The Scarecrow
					}
					case 37:
					{
						CreateHat(client, 919, 11); //The Scarecrow
					}
					case 38:
					{
						CreateHat(client, 919, 13); //The Scarecrow
					}
					case 39:
					{
						CreateHat(client, 1030, 6); //The Dapper Disguise
					}
					case 40:
					{
						CreateHat(client, 30009, 6); //The Megapixel Beard
					}
					case 41:
					{
						CreateHat(client, 30009, 11); //The Megapixel Beard
					}
					case 42:
					{
						CreateHat(client, 559, 6); //Griffin's Gog
					}
					case 43:
					{
						CreateHat(client, 559, 13); //Griffin's Gog
					}
					case 44:
					{
						CreateHat(client, 30512, 6); //Facepeeler
					}
					case 45:
					{
						CreateHat(client, 30512, 13); //Facepeeler
					}
					case 46:
					{
						CreateHat(client, 30512, 11); //Facepeeler
					}
					case 47:
					{
						CreateHat(client, 30414, 11); //The Eye-Catcher
					}
				}
			}
			case TFClass_Engineer:
			{
				int rnd2 = GetRandomUInt(0,58);
				switch (rnd2)
				{
					case 1:
					{
						CreateHat(client, 30569, 6); //The Tomb Readers
					}
					case 2:
					{
						CreateHat(client, 744, 6); //Pyrovision Goggles
					}
					case 3:
					{
						CreateHat(client, 522, 6); //The Deus Specs
					}
					case 4:
					{
						CreateHat(client, 816, 6); //The Marxman
					}
					case 5:
					{
						CreateHat(client, 30104, 6); //Graybanns
					}
					case 6:
					{
						CreateHat(client, 30306, 6); //The Dictator
					}
					case 7:
					{
						CreateHat(client, 30352, 6); //The Mustachioed Mann
					}
					case 8:
					{
						CreateHat(client, 30414, 6); //The Eye-Catcher
					}
					case 9:
					{
						CreateHat(client, 30140, 6); //The Virtual Viewfinder
					}
					case 10:
					{
						CreateHat(client, 30397, 6); //The Bruiser's Bandanna
					}
					case 11:
					{
						CreateHat(client, 30569, 1); //The Tomb Readers
					}	
					case 12:
					{
						CreateHat(client, 744, 3); //Pyrovision Goggles
					}	
					case 13:
					{
						CreateHat(client, 522, 1); //The Deus Specs
					}	
					case 14:
					{
						CreateHat(client, 816, 1); //The Marxman
					}		
					case 15:
					{
						CreateHat(client, 816, 11); //The Marxman
					}	
					case 16:
					{
						CreateHat(client, 30104, 11); //Graybanns
					}
					case 17:
					{
						CreateHat(client, 30306, 11); //The Dictator
					}	
					case 18:
					{
						CreateHat(client, 30352, 11); //The Mustachioed Mann
					}
					case 19:
					{
						CreateHat(client, 30414, 11); //The Eye-Catcher
					}
					case 20:
					{
						CreateHat(client, 30140, 11); //The Virtual Viewfinder
					}
					case 21:
					{
						CreateHat(client, 30397, 11); //The Bruiser's Bandanna
					}
					case 22:
					{
						CreateHat(client, 143, 6); //Earbuds
					}
					case 23:
					{
						CreateHat(client, 343, 6); //Professor Speks
					}
					case 24:
					{
						CreateHat(client, 486, 6); //Summer Shades
					}
					case 25:
					{
						CreateHat(client, 486, 11); //Summer Shades
					}
					case 26:
					{
						CreateHat(client, 582, 6); //Seal Mask
					}
					case 27:
					{
						CreateHat(client, 30085, 6); //The Macho Mann
					}
					case 28:
					{
						CreateHat(client, 30085, 11); //The Macho Mann
					}
					case 29:
					{
						CreateHat(client, 986, 6); //The Mutton Mann
					}
					case 30:
					{
						CreateHat(client, 986, 11); //The Mutton Mann
					}
					case 31:
					{
						CreateHat(client, 647, 6); //The All-Father
					}
					case 32:
					{
						CreateHat(client, 647, 11); //The All-Father
					}
					case 33:
					{
						CreateHat(client, 30164, 6); //The Viking Braider
					}
					case 34:
					{
						CreateHat(client, 30164, 11); //The Viking Braider
					}
					case 35:
					{
						CreateHat(client, 30165, 6); //The Cuban Bristle Crisis
					}
					case 36:
					{
						CreateHat(client, 30165, 11); //The Cuban Bristle Crisis
					}
					case 37:
					{
						CreateHat(client, 30367, 6); //The Blizzard Breather
					}
					case 38:
					{
						CreateHat(client, 30367, 11); //The Blizzard Breather
					}
					case 39:
					{
						CreateHat(client, 389, 6); //Googly Gazer
					}
					case 40:
					{
						CreateHat(client, 591, 6); //The Brainiac Goggles
					}
					case 41:
					{
						CreateHat(client, 1009, 6); //The Grizzled Growth
					}
					case 42:
					{
						CreateHat(client, 1009, 1); //The Grizzled Growth
					}
					case 43:
					{
						CreateHat(client, 30168, 6); //The Special Eyes
					}
					case 44:
					{
						CreateHat(client, 30168, 11); //The Special Eyes
					}
					case 45:
					{
						CreateHat(client, 30172, 6); //The Gold Digger
					}
					case 46:
					{
						CreateHat(client, 30172, 11); //The Gold Digger
					}
					case 47:
					{
						CreateHat(client, 30322, 6); //Face Full of Festive
					}
					case 48:
					{
						CreateHat(client, 30322, 11); //Face Full of Festive
					}
					case 49:
					{
						CreateHat(client, 30347, 6); //The Scotch Saver
					}
					case 50:
					{
						CreateHat(client, 30347, 11); //The Scotch Saver
					}
					case 51:
					{
						CreateHat(client, 30407, 6); //The Level Three Chin
					}
					case 52:
					{
						CreateHat(client, 30407, 11); //The Level Three Chin
					}
					case 53:
					{
						CreateHat(client, 30223, 6); //The Grease Monkey
					}
					case 54:
					{
						CreateHat(client, 30223, 13); //The Grease Monkey
					}
					case 55:
					{
						CreateHat(client, 30523, 6); //Garden Bristles
					}
					case 56:
					{
						CreateHat(client, 30523, 13); //Garden Bristles
					}
					case 57:
					{
						CreateHat(client, 30523, 11); //Garden Bristles
					}
					case 58:
					{
						CreateHat(client, 30414, 11); //The Eye-Catcher
					}
				}
			}
		}
	}
		
	TFClassType class = TF2_GetPlayerClass(client);
		
	switch (class)
	{
		case TFClass_Scout:
		{
			int rnd3 = GetRandomUInt(0,228);
			switch (rnd3)
			{
				case 1:
				{
					CreateHat(client, 868, 6, 20); //Heroic Companion Badge
				}
				case 2:
				{
					CreateHat(client, 583, 6, 20); //Bombinomicon
				}
				case 3:
				{
					CreateHat(client, 586, 6); //Mark of the Saint
				}
				case 4:
				{
					CreateHat(client, 625, 6, 20); //Clan Pride
				}
				case 5:
				{
					CreateHat(client, 619, 6, 20); //Flair!
				}
				case 6:
				{
					CreateHat(client, 1025, 6); //The Fortune Hunter
				}
				case 7:
				{
					CreateHat(client, 623, 6, 20); //Photo Badge
				}
				case 8:
				{
					CreateHat(client, 738, 6); //Pet Balloonicorn
				}
				case 9:
				{
					CreateHat(client, 955, 6); //The Tuxxy
				}
				case 10:
				{
					CreateHat(client, 995, 6, 20); //Pet Reindoonicorn
				}
				case 11:
				{
					CreateHat(client, 987, 6); //The Merc's Muffler
				}
				case 12:
				{
					CreateHat(client, 1096, 6); //The Baronial Badge
				}
				case 13:
				{
					CreateHat(client, 30607, 6); //The Pocket Raiders
				}
				case 14:
				{
					CreateHat(client, 30068, 6); //The Breakneck Baggies
				}
				case 15:
				{
					CreateHat(client, 869, 6); //The Rump-o-Lantern
				}
				case 16:
				{
					CreateHat(client, 30309, 6); //Dead of Night
				}
				case 17:
				{
					CreateHat(client, 1024, 6); //Crofts Crest
				}
				case 18:
				{
					CreateHat(client, 992, 6); //Smissmas Wreath
				}
				case 19:
				{
					CreateHat(client, 956, 6); //Faerie Solitaire Pin
				}
				case 20:
				{
					CreateHat(client, 943, 6); //Hitt Mann Badge
				}
				case 21:
				{
					CreateHat(client, 873, 6, 20); //Whale Bone Charm
				}
				case 22:
				{
					CreateHat(client, 855, 6); //Vigilant Pin
				}
				case 23:
				{
					CreateHat(client, 818, 6); //Awesomenauts Badge
				}
				case 24:
				{
					CreateHat(client, 767, 6); //Atomic Accolade
				}
				case 25:
				{
					CreateHat(client, 718, 6); //Merc Medal
				}
				case 26:
				{
					CreateHat(client, 868, 1, 20); //Heroic Companion Badge
				}
				case 27:
				{
					CreateHat(client, 586, 1); //Mark of the Saint
				}
				case 28:
				{
					CreateHat(client, 625, 11, 20); //Clan Pride
				}
				case 29:
				{
					CreateHat(client, 619, 11, 20); //Flair!
				}
				case 30:
				{
					CreateHat(client, 1025, 1); //The Fortune Hunter
				}
				case 31:
				{
					CreateHat(client, 623, 11, 20); //Photo Badge
				}
				case 32:
				{
					CreateHat(client, 738, 1); //Pet Balloonicorn
				}
				case 33:
				{
					CreateHat(client, 738, 11); //Pet Balloonicorn
				}
				case 34:
				{
					CreateHat(client, 987, 11); //The Merc's Muffler
				}
				case 35:
				{
					CreateHat(client, 1096, 1); //The Baronial Badge
				}
				case 36:
				{
					CreateHat(client, 30068, 11); //The Breakneck Baggies
				}
				case 37:
				{
					CreateHat(client, 869, 11); //The Rump-o-Lantern
				}
				case 38:
				{
					CreateHat(client, 869, 13); //The Rump-o-Lantern
				}
				case 39:
				{
					CreateHat(client, 30309, 11); //Dead of Night
				}
				case 40:
				{
					CreateHat(client, 1024, 1); //Crofts Crest
				}
				case 41:
				{
					CreateHat(client, 956, 1); //Faerie Solitaire Pin
				}
				case 42:
				{
					CreateHat(client, 943, 1); //Hitt Mann Badge
				}
				case 43:
				{
					CreateHat(client, 873, 1, 20); //Whale Bone Charm
				}
				case 44:
				{
					CreateHat(client, 855, 1); //Vigilant Pin
				}
				case 45:
				{
					CreateHat(client, 818, 1); //Awesomenauts Badge
				}
				case 46:
				{
					CreateHat(client, 767, 1); //Atomic Accolade
				}
				case 47:
				{
					CreateHat(client, 718, 1); //Merc Medal
				}
				case 48:
				{
					CreateHat(client, 164, 6); //Grizzled Veteran
				}
				case 49:
				{
					CreateHat(client, 165, 6); //Soldier of Fortune
				}
				case 50:
				{
					CreateHat(client, 166, 6); //Mercenary
				}
				case 51:
				{
					CreateHat(client, 170, 6); //Primeval Warrior
				}
				case 52:
				{
					CreateHat(client, 242, 6); //Duel Medal Bronze
				}
				case 53:
				{
					CreateHat(client, 243, 6); //Duel Medal Silver
				}
				case 54:
				{
					CreateHat(client, 244, 6); //Duel Medal Gold
				}
				case 55:
				{
					CreateHat(client, 245, 6); //Duel Medal Plat
				}
				case 56:
				{
					CreateHat(client, 262, 6); //Polycount Pin
				}
				case 57:
				{
					CreateHat(client, 296, 6); //License to Maim
				}
				case 58:
				{
					CreateHat(client, 299, 1); //Companion Cube Pin
				}
				case 59:
				{
					CreateHat(client, 299, 3); //Companion Cube Pin
				}
				case 60:
				{
					CreateHat(client, 422, 3); //Resurrection Associate Pin
				}
				case 61:
				{
					CreateHat(client, 432, 6); //SpaceChem Pin
				}
				case 62:
				{
					CreateHat(client, 432, 6); //Dr. Grordbort's Crest
				}
				case 63:
				{
					CreateHat(client, 541, 6); //Merc's Pride Scarf
				}
				case 64:
				{
					CreateHat(client, 541, 1); //Merc's Pride Scarf
				}
				case 65:
				{
					CreateHat(client, 541, 11); //Merc's Pride Scarf
				}
				case 66:
				{
					CreateHat(client, 592, 6); //Dr. Grordbort's Copper Crest
				}
				case 67:
				{
					CreateHat(client, 636, 6); //Dr. Grordbort's Silver Crest
				}
				case 68:
				{
					CreateHat(client, 655, 11); //The Spirit of Giving
				}
				case 69:
				{
					CreateHat(client, 704, 1); //The Bolgan Family Crest
				}
				case 70:
				{
					CreateHat(client, 704, 6); //The Bolgan Family Crest
				}
				case 71:
				{
					CreateHat(client, 717, 1); //Mapmaker's Medallion
				}
				case 72:
				{
					CreateHat(client, 733, 6); //Pet Robro
				}
				case 73:
				{
					CreateHat(client, 733, 11); //Pet Robro
				}
				case 74:
				{
					CreateHat(client, 864, 1); //The Friends Forever Companion Square Badge
				}
				case 75:
				{
					CreateHat(client, 865, 1); //The Triple A Badge
				}
				case 76:
				{
					CreateHat(client, 953, 6); //The Saxxy Clapper Badge
				}
				case 77:
				{
					CreateHat(client, 995, 11); //Pet Reindoonicorn
				}
				case 78:
				{
					CreateHat(client, 1011, 6); //Tux
				}
				case 79:
				{
					CreateHat(client, 1126, 6); //Duck Badge
				}
				case 80:
				{
					CreateHat(client, 5075, 6); //Something Special For Someone Special
				}
				case 81:
				{
					CreateHat(client, 30000, 9); //The Electric Badge-alo
				}
				case 82:
				{
					CreateHat(client, 30550, 6); //Snow Sleeves
				}
				case 83:
				{
					CreateHat(client, 30550, 11); //Snow Sleeves
				}
				case 84:
				{
					CreateHat(client, 30551, 6); //Flashdance Footies
				}
				case 85:
				{
					CreateHat(client, 30551, 11); //Flashdance Footies
				}
				case 86:
				{
					CreateHat(client, 30559, 9); //End of the Line Community Update Medal
				}
				case 87:
				{
					CreateHat(client, 30669, 15); //Space Hamster Hammy
				}
				case 88:
				{
					CreateHat(client, 30669, 11); //Space Hamster Hammy
				}
				case 89:
				{
					CreateHat(client, 30670, 9); //Invasion Community Update Medal
				}
				case 90:
				{
					CreateHat(client, 927, 6); //The Boo Balloon
				}
				case 91:
				{
					CreateHat(client, 927, 13); //The Boo Balloon
				}
				case 92:
				{
					CreateHat(client, 929, 6); //The Unknown Monkeynaut
				}
				case 93:
				{
					CreateHat(client, 929, 13); //The Unknown Monkeynaut
				}
				case 94:
				{
					CreateHat(client, 934, 6); //The Dead Little Buddy
				}
				case 95:
				{
					CreateHat(client, 934, 13); //The Dead Little Buddy
				}
				case 96:
				{
					CreateHat(client, 30198, 6); //The Pocket Horsemann
				}
				case 97:
				{
					CreateHat(client, 30198, 13); //The Pocket Horsemann
				}
				case 98:
				{
					CreateHat(client, 30206, 6); //The Accursed Apparition
				}
				case 99:
				{
					CreateHat(client, 30206, 13); //The Accursed Apparition
				}
				case 100:
				{
					CreateHat(client, 30234, 6); //The Sackcloth Spook
				}
				case 101:
				{
					CreateHat(client, 30234, 13); //The Sackcloth Spook
				}
				case 102:
				{
					CreateHat(client, 30252, 6); //Guano
				}
				case 103:
				{
					CreateHat(client, 30252, 13); //Guano
				}
				case 104:
				{
					CreateHat(client, 30254, 6); //Unidentified Following Object
				}
				case 105:
				{
					CreateHat(client, 30254, 13); //Unidentified Following Object
				}
				case 106:
				{
					CreateHat(client, 30255, 6); //The Beacon From Beyond
				}
				case 107:
				{
					CreateHat(client, 30255, 13); //The Beacon From Beyond
				}
				case 108:
				{
					CreateHat(client, 30289, 6); //Quoth
				}
				case 109:
				{
					CreateHat(client, 30289, 13); //Quoth
				}
				case 110:
				{
					CreateHat(client, 30302, 6); //The Cryptic Keepsake
				}
				case 111:
				{
					CreateHat(client, 30302, 13); //The Cryptic Keepsake
				}
				case 112:
				{
					CreateHat(client, 30497, 6); //Ghost of Spies Checked Past
				}
				case 113:
				{
					CreateHat(client, 30497, 13); //Ghost of Spies Checked Past
				}
				case 114:
				{
					CreateHat(client, 30497, 11); //Ghost of Spies Checked Past
				}
				case 115:
				{
					CreateHat(client, 30498, 6); //The Hooded Haunter
				}
				case 116:
				{
					CreateHat(client, 30498, 13); //The Hooded Haunter
				}
				case 117:
				{
					CreateHat(client, 30498, 11); //The Hooded Haunter
				}
				case 118:
				{
					CreateHat(client, 30536, 6); //Cursed Cruise
				}
				case 119:
				{
					CreateHat(client, 30536, 13); //Cursed Cruise
				}
				case 120:
				{
					CreateHat(client, 30536, 11); //Cursed Cruise
				}
				case 121:
				{
					CreateHat(client, 347, 6); //The Essential Accessories
				}
				case 122:
				{
					CreateHat(client, 454, 6); //Sign of the Wolf's School
				}
				case 123:
				{
					CreateHat(client, 454, 1); //Sign of the Wolf's School
				}
				case 124:
				{
					CreateHat(client, 490, 6); //Flip-Flops
				}
				case 125:
				{
					CreateHat(client, 491, 6); //Lucky No. 42
				}
				case 126:
				{
					CreateHat(client, 540, 6); //Ball-Kicking Boots
				}
				case 127:
				{
					CreateHat(client, 540, 1); //Ball-Kicking Boots
				}
				case 128:
				{
					CreateHat(client, 653, 6); //The Bootie Time
				}
				case 129:
				{
					CreateHat(client, 653, 11); //The Bootie Time
				}
				case 130:
				{
					CreateHat(client, 707, 6); //The Boston Boom-Bringer
				}
				case 131:
				{
					CreateHat(client, 707, 11); //The Boston Boom-Bringer
				}
				case 132:
				{
					CreateHat(client, 722, 6); //The Fast Learner
				}
				case 133:
				{
					CreateHat(client, 722, 11); //The Fast Learner
				}
				case 134:
				{
					CreateHat(client, 734, 6); //The Teufort Tooth Kicker
				}
				case 135:
				{
					CreateHat(client, 734, 11); //The Teufort Tooth Kicker
				}
				case 136:
				{
					CreateHat(client, 781, 6); //Dillinger's Duffel
				}
				case 137:
				{
					CreateHat(client, 781, 11); //Dillinger's Duffel
				}
				case 138:
				{
					CreateHat(client, 814, 1); //The Triad Trinket
				}
				case 139:
				{
					CreateHat(client, 814, 6); //The Triad Trinket
				}
				case 140:
				{
					CreateHat(client, 814, 11); //The Triad Trinket
				}
				case 141:
				{
					CreateHat(client, 815, 1); //The Champ Stamp
				}
				case 142:
				{
					CreateHat(client, 815, 6); //The Champ Stamp
				}
				case 143:
				{
					CreateHat(client, 815, 11); //The Champ Stamp
				}
				case 144:
				{
					CreateHat(client, 924, 6); //The Spooky Shoes
				}
				case 145:
				{
					CreateHat(client, 924, 11); //The Spooky Shoes
				}
				case 146:
				{
					CreateHat(client, 924, 13); //The Spooky Shoes
				}
				case 147:
				{
					CreateHat(client, 925, 6); //The Spooky Sleeves
				}
				case 148:
				{
					CreateHat(client, 925, 11); //The Spooky Sleeves
				}
				case 149:
				{
					CreateHat(client, 925, 13); //The Spooky Sleeves
				}
				case 150:
				{
					CreateHat(client, 983, 6); //The Digit Divulger
				}
				case 151:
				{
					CreateHat(client, 983, 11); //The Digit Divulger
				}
				case 152:
				{
					CreateHat(client, 1016, 11); //Buck Turner All-Stars
				}
				case 153:
				{
					CreateHat(client, 1026, 1); //The Tomb Wrapper
				}
				case 154:
				{
					CreateHat(client, 1026, 6); //The Tomb Wrapper
				}
				case 155:
				{
					CreateHat(client, 1032, 6); //The Long Fall Loafers
				}
				case 156:
				{
					CreateHat(client, 1075, 6); //The Sack Fulla Smissmas
				}
				case 157:
				{
					CreateHat(client, 30060, 6); //The Cheet Sheet
				}
				case 158:
				{
					CreateHat(client, 30060, 1); //The Cheet Sheet
				}
				case 159:
				{
					CreateHat(client, 30076, 6); //The Bigg Mann on Campus
				}
				case 160:
				{
					CreateHat(client, 30076, 11); //The Bigg Mann on Campus
				}
				case 161:
				{
					CreateHat(client, 30077, 6); //The Cool Cat Cardigan
				}
				case 162:
				{
					CreateHat(client, 30077, 11); //The Cool Cat Cardigan
				}
				case 163:
				{
					CreateHat(client, 30083, 6); //The Caffeine Cooler
				}
				case 164:
				{
					CreateHat(client, 30083, 11); //The Caffeine Cooler
				}
				case 165:
				{
					CreateHat(client, 30084, 6); //The Half-Pipe Hurdler
				}
				case 166:
				{
					CreateHat(client, 30084, 11); //The Half-Pipe Hurdler
				}
				case 167:
				{
					CreateHat(client, 30134, 6); //The Delinquent's Down Vest
				}
				case 168:
				{
					CreateHat(client, 30134, 11); //The Delinquent's Down Vest
				}
				case 169:
				{
					CreateHat(client, 30185, 6); //The Flapjack
				}
				case 170:
				{
					CreateHat(client, 30185, 11); //The Flapjack
				}
				case 171:
				{
					CreateHat(client, 30320, 6); //Chucklenuts
				}
				case 172:
				{
					CreateHat(client, 30320, 11); //Chucklenuts
				}
				case 173:
				{
					CreateHat(client, 30325, 6); //The Little Drummer Mann
				}
				case 174:
				{
					CreateHat(client, 30325, 11); //The Little Drummer Mann
				}
				case 175:
				{
					CreateHat(client, 30376, 6); //The Ticket Boy
				}
				case 176:
				{
					CreateHat(client, 30376, 11); //The Ticket Boy
				}
				case 177:
				{
					CreateHat(client, 30395, 6); //The Southie Shinobi
				}
				case 178:
				{
					CreateHat(client, 30395, 11); //The Southie Shinobi
				}
				case 179:
				{
					CreateHat(client, 30396, 6); //The Red Socks
				}
				case 180:
				{
					CreateHat(client, 30396, 11); //The Red Socks
				}
				case 181:
				{
					CreateHat(client, 30426, 6); //The Paisley Pro
				}
				case 182:
				{
					CreateHat(client, 30426, 11); //The Paisley Pro
				}
				case 183:
				{
					CreateHat(client, 30427, 6); //The Argyle Ace
				}
				case 184:
				{
					CreateHat(client, 30427, 11); //The Argyle Ace
				}
				case 185:
				{
					CreateHat(client, 30540, 6); //Brooklyn Booties
				}
				case 186:
				{
					CreateHat(client, 30540, 11); //Brooklyn Booties
				}
				case 187:
				{
					CreateHat(client, 30552, 6); //Thermal Tracker
				}
				case 188:
				{
					CreateHat(client, 30552, 11); //Thermal Tracker
				}
				case 189:
				{
					CreateHat(client, 30561, 6); //The Bootenkhamuns
				}
				case 190:
				{
					CreateHat(client, 30564, 6); //Orion's Belt
				}
				case 191:
				{
					CreateHat(client, 30574, 6); //Courtier's Collar
				}
				case 192:
				{
					CreateHat(client, 30574, 11); //Courtier's Collar
				}
				case 193:
				{
					CreateHat(client, 30575, 6); //Harlequin's Hooves
				}
				case 194:
				{
					CreateHat(client, 30575, 11); //Harlequin's Hooves
				}
				case 195:
				{
					CreateHat(client, 30637, 15); //Flak Jack
				}
				case 196:
				{
					CreateHat(client, 30637, 11); //Flak Jack
				}
				case 197:
				{
					CreateHat(client, 547, 6); //B-ankh!
				}
				case 198:
				{
					CreateHat(client, 547, 13); //B-ankh!
				}
				case 199:
				{
					CreateHat(client, 548, 6); //Futankhamun
				}
				case 200:
				{
					CreateHat(client, 548, 13); //Futankhamun
				}
				case 201:
				{
					CreateHat(client, 30200, 6); //The Baphomet Trotters
				}
				case 202:
				{
					CreateHat(client, 30200, 13); //The Baphomet Trotters
				}
				case 203:
				{
					CreateHat(client, 30208, 6); //The Terrier Trousers
				}
				case 204:
				{
					CreateHat(client, 30208, 13); //The Terrier Trousers
				}
				case 205:
				{
					CreateHat(client, 30247, 6); //Faun Feet
				}
				case 206:
				{
					CreateHat(client, 30247, 13); //Faun Feet
				}
				case 207:
				{
					CreateHat(client, 30253, 6); //The Sprinting Cephalopod
				}
				case 208:
				{
					CreateHat(client, 30253, 13); //The Sprinting Cephalopod
				}
				case 209:
				{
					CreateHat(client, 30470, 1); //The Biomech Backpack
				}
				case 210:
				{
					CreateHat(client, 30470, 6); //The Biomech Backpack
				}
				case 211:
				{
					CreateHat(client, 30472, 1); //The Xeno Suit
				}
				case 212:
				{
					CreateHat(client, 30472, 6); //The Xeno Suit
				}
				case 213:
				{
					CreateHat(client, 30492, 11); //Fowl Fists
				}
				case 214:
				{
					CreateHat(client, 30492, 6); //Fowl Fists
				}
				case 215:
				{
					CreateHat(client, 30492, 13); //Fowl Fists
				}
				case 216:
				{
					CreateHat(client, 30493, 11); //Talon Trotters
				}
				case 217:
				{
					CreateHat(client, 30493, 6); //Talon Trotters
				}
				case 218:
				{
					CreateHat(client, 30493, 13); //Talon Trotters
				}
				case 219:
				{
					CreateHat(client, 30495, 11); //Claws and Infect
				}
				case 220:
				{
					CreateHat(client, 30495, 6); //Claws and Infect
				}
				case 221:
				{
					CreateHat(client, 30495, 13); //Claws and Infect
				}
				case 222:
				{
					CreateHat(client, 30496, 11); //Crazy Legs
				}
				case 223:
				{
					CreateHat(client, 30496, 6); //Crazy Legs
				}
				case 224:
				{
					CreateHat(client, 30496, 13); //Crazy Legs
				}		
				case 225:
				{
					CreateHat(client, 30178, 6); //Weight Room Warmer
				}		
				case 226:
				{
					CreateHat(client, 30178, 11); //Weight Room Warmer
				}														
				case 227:
				{
					CreateHat(client, 30167, 6); //The Beep Boy
				}									
				case 228:
				{
					CreateHat(client, 30167, 11); //The Beep Boy
				}	
			}
		}
		case TFClass_Sniper:
		{
			int rnd3 = GetRandomUInt(0,183);
			switch (rnd3)
			{
				case 1:
				{
					CreateHat(client, 868, 6, 20); //Heroic Companion Badge
				}
				case 2:
				{
					CreateHat(client, 583, 6, 20); //Bombinomicon
				}
				case 3:
				{
					CreateHat(client, 586, 6); //Mark of the Saint
				}
				case 4:
				{
					CreateHat(client, 625, 6, 20); //Clan Pride
				}
				case 5:
				{
					CreateHat(client, 619, 6, 20); //Flair!
				}
				case 6:
				{
					CreateHat(client, 1025, 6); //The Fortune Hunter
				}
				case 7:
				{
					CreateHat(client, 623, 6, 20); //Photo Badge
				}
				case 8:
				{
					CreateHat(client, 738, 6); //Pet Balloonicorn
				}
				case 9:
				{
					CreateHat(client, 955, 6); //The Tuxxy
				}
				case 10:
				{
					CreateHat(client, 995, 6, 20); //Pet Reindoonicorn
				}
				case 11:
				{
					CreateHat(client, 987, 6); //The Merc's Muffler
				}
				case 12:
				{
					CreateHat(client, 1096, 6); //The Baronial Badge
				}
				case 13:
				{
					CreateHat(client, 30607, 6); //The Pocket Raiders
				}
				case 14:
				{
					CreateHat(client, 30068, 6); //The Breakneck Baggies
				}
				case 15:
				{
					CreateHat(client, 869, 6); //The Rump-o-Lantern
				}
				case 16:
				{
					CreateHat(client, 30309, 6); //Dead of Night
				}
				case 17:
				{
					CreateHat(client, 1024, 6); //Crofts Crest
				}
				case 18:
				{
					CreateHat(client, 992, 6); //Smissmas Wreath
				}
				case 19:
				{
					CreateHat(client, 956, 6); //Faerie Solitaire Pin
				}
				case 20:
				{
					CreateHat(client, 943, 6); //Hitt Mann Badge
				}
				case 21:
				{
					CreateHat(client, 873, 6, 20); //Whale Bone Charm
				}
				case 22:
				{
					CreateHat(client, 855, 6); //Vigilant Pin
				}
				case 23:
				{
					CreateHat(client, 818, 6); //Awesomenauts Badge
				}
				case 24:
				{
					CreateHat(client, 767, 6); //Atomic Accolade
				}
				case 25:
				{
					CreateHat(client, 718, 6); //Merc Medal
				}
				case 26:
				{
					CreateHat(client, 868, 1, 20); //Heroic Companion Badge
				}
				case 27:
				{
					CreateHat(client, 586, 1); //Mark of the Saint
				}
				case 28:
				{
					CreateHat(client, 625, 11, 20); //Clan Pride
				}
				case 29:
				{
					CreateHat(client, 619, 11, 20); //Flair!
				}
				case 30:
				{
					CreateHat(client, 1025, 1); //The Fortune Hunter
				}
				case 31:
				{
					CreateHat(client, 623, 11, 20); //Photo Badge
				}
				case 32:
				{
					CreateHat(client, 738, 1); //Pet Balloonicorn
				}
				case 33:
				{
					CreateHat(client, 738, 11); //Pet Balloonicorn
				}
				case 34:
				{
					CreateHat(client, 987, 11); //The Merc's Muffler
				}
				case 35:
				{
					CreateHat(client, 1096, 1); //The Baronial Badge
				}
				case 36:
				{
					CreateHat(client, 30068, 11); //The Breakneck Baggies
				}
				case 37:
				{
					CreateHat(client, 869, 11); //The Rump-o-Lantern
				}
				case 38:
				{
					CreateHat(client, 869, 13); //The Rump-o-Lantern
				}
				case 39:
				{
					CreateHat(client, 30309, 11); //Dead of Night
				}
				case 40:
				{
					CreateHat(client, 1024, 1); //Crofts Crest
				}
				case 41:
				{
					CreateHat(client, 956, 1); //Faerie Solitaire Pin
				}
				case 42:
				{
					CreateHat(client, 943, 1); //Hitt Mann Badge
				}
				case 43:
				{
					CreateHat(client, 873, 1, 20); //Whale Bone Charm
				}
				case 44:
				{
					CreateHat(client, 855, 1); //Vigilant Pin
				}
				case 45:
				{
					CreateHat(client, 818, 1); //Awesomenauts Badge
				}
				case 46:
				{
					CreateHat(client, 767, 1); //Atomic Accolade
				}
				case 47:
				{
					CreateHat(client, 718, 1); //Merc Medal
				}
				case 48:
				{
					CreateHat(client, 164, 6); //Grizzled Veteran
				}
				case 49:
				{
					CreateHat(client, 165, 6); //Soldier of Fortune
				}
				case 50:
				{
					CreateHat(client, 166, 6); //Mercenary
				}
				case 51:
				{
					CreateHat(client, 170, 6); //Primeval Warrior
				}
				case 52:
				{
					CreateHat(client, 242, 6); //Duel Medal Bronze
				}
				case 53:
				{
					CreateHat(client, 243, 6); //Duel Medal Silver
				}
				case 54:
				{
					CreateHat(client, 244, 6); //Duel Medal Gold
				}
				case 55:
				{
					CreateHat(client, 245, 6); //Duel Medal Plat
				}
				case 56:
				{
					CreateHat(client, 262, 6); //Polycount Pin
				}
				case 57:
				{
					CreateHat(client, 296, 6); //License to Maim
				}
				case 58:
				{
					CreateHat(client, 299, 1); //Companion Cube Pin
				}
				case 59:
				{
					CreateHat(client, 299, 3); //Companion Cube Pin
				}
				case 60:
				{
					CreateHat(client, 422, 3); //Resurrection Associate Pin
				}
				case 61:
				{
					CreateHat(client, 432, 6); //SpaceChem Pin
				}
				case 62:
				{
					CreateHat(client, 432, 6); //Dr. Grordbort's Crest
				}
				case 63:
				{
					CreateHat(client, 541, 6); //Merc's Pride Scarf
				}
				case 64:
				{
					CreateHat(client, 541, 1); //Merc's Pride Scarf
				}
				case 65:
				{
					CreateHat(client, 541, 11); //Merc's Pride Scarf
				}
				case 66:
				{
					CreateHat(client, 592, 6); //Dr. Grordbort's Copper Crest
				}
				case 67:
				{
					CreateHat(client, 636, 6); //Dr. Grordbort's Silver Crest
				}
				case 68:
				{
					CreateHat(client, 655, 11); //The Spirit of Giving
				}
				case 69:
				{
					CreateHat(client, 704, 1); //The Bolgan Family Crest
				}
				case 70:
				{
					CreateHat(client, 704, 6); //The Bolgan Family Crest
				}
				case 71:
				{
					CreateHat(client, 717, 1); //Mapmaker's Medallion
				}
				case 72:
				{
					CreateHat(client, 733, 6); //Pet Robro
				}
				case 73:
				{
					CreateHat(client, 733, 11); //Pet Robro
				}
				case 74:
				{
					CreateHat(client, 864, 1); //The Friends Forever Companion Square Badge
				}
				case 75:
				{
					CreateHat(client, 865, 1); //The Triple A Badge
				}
				case 76:
				{
					CreateHat(client, 953, 6); //The Saxxy Clapper Badge
				}
				case 77:
				{
					CreateHat(client, 995, 11); //Pet Reindoonicorn
				}
				case 78:
				{
					CreateHat(client, 1011, 6); //Tux
				}
				case 79:
				{
					CreateHat(client, 1126, 6); //Duck Badge
				}
				case 80:
				{
					CreateHat(client, 5075, 6); //Something Special For Someone Special
				}
				case 81:
				{
					CreateHat(client, 30000, 9); //The Electric Badge-alo
				}
				case 82:
				{
					CreateHat(client, 30550, 6); //Snow Sleeves
				}
				case 83:
				{
					CreateHat(client, 30550, 11); //Snow Sleeves
				}
				case 84:
				{
					CreateHat(client, 30551, 6); //Flashdance Footies
				}
				case 85:
				{
					CreateHat(client, 30551, 11); //Flashdance Footies
				}
				case 86:
				{
					CreateHat(client, 30559, 9); //End of the Line Community Update Medal
				}
				case 87:
				{
					CreateHat(client, 30669, 15); //Space Hamster Hammy
				}
				case 88:
				{
					CreateHat(client, 30669, 11); //Space Hamster Hammy
				}
				case 89:
				{
					CreateHat(client, 30670, 9); //Invasion Community Update Medal
				}
				case 90:
				{
					CreateHat(client, 927, 6); //The Boo Balloon
				}
				case 91:
				{
					CreateHat(client, 927, 13); //The Boo Balloon
				}
				case 92:
				{
					CreateHat(client, 929, 6); //The Unknown Monkeynaut
				}
				case 93:
				{
					CreateHat(client, 929, 13); //The Unknown Monkeynaut
				}
				case 94:
				{
					CreateHat(client, 934, 6); //The Dead Little Buddy
				}
				case 95:
				{
					CreateHat(client, 934, 13); //The Dead Little Buddy
				}
				case 96:
				{
					CreateHat(client, 30198, 6); //The Pocket Horsemann
				}
				case 97:
				{
					CreateHat(client, 30198, 13); //The Pocket Horsemann
				}
				case 98:
				{
					CreateHat(client, 30206, 6); //The Accursed Apparition
				}
				case 99:
				{
					CreateHat(client, 30206, 13); //The Accursed Apparition
				}
				case 100:
				{
					CreateHat(client, 30234, 6); //The Sackcloth Spook
				}
				case 101:
				{
					CreateHat(client, 30234, 13); //The Sackcloth Spook
				}
				case 102:
				{
					CreateHat(client, 30252, 6); //Guano
				}
				case 103:
				{
					CreateHat(client, 30252, 13); //Guano
				}
				case 104:
				{
					CreateHat(client, 30254, 6); //Unidentified Following Object
				}
				case 105:
				{
					CreateHat(client, 30254, 13); //Unidentified Following Object
				}
				case 106:
				{
					CreateHat(client, 30255, 6); //The Beacon From Beyond
				}
				case 107:
				{
					CreateHat(client, 30255, 13); //The Beacon From Beyond
				}
				case 108:
				{
					CreateHat(client, 30289, 6); //Quoth
				}
				case 109:
				{
					CreateHat(client, 30289, 13); //Quoth
				}
				case 110:
				{
					CreateHat(client, 30302, 6); //The Cryptic Keepsake
				}
				case 111:
				{
					CreateHat(client, 30302, 13); //The Cryptic Keepsake
				}
				case 112:
				{
					CreateHat(client, 30497, 6); //Ghost of Spies Checked Past
				}
				case 113:
				{
					CreateHat(client, 30497, 13); //Ghost of Spies Checked Past
				}
				case 114:
				{
					CreateHat(client, 30497, 11); //Ghost of Spies Checked Past
				}
				case 115:
				{
					CreateHat(client, 30498, 6); //The Hooded Haunter
				}
				case 116:
				{
					CreateHat(client, 30498, 13); //The Hooded Haunter
				}
				case 117:
				{
					CreateHat(client, 30498, 11); //The Hooded Haunter
				}
				case 118:
				{
					CreateHat(client, 30536, 6); //Cursed Cruise
				}
				case 119:
				{
					CreateHat(client, 30536, 13); //Cursed Cruise
				}
				case 120:
				{
					CreateHat(client, 30536, 11); //Cursed Cruise
				}	
				case 121:
				{
					CreateHat(client, 814, 1); //The Triad Trinket
				}
				case 122:
				{
					CreateHat(client, 814, 6); //The Triad Trinket
				}
				case 123:
				{
					CreateHat(client, 814, 11); //The Triad Trinket
				}	
				case 124:
				{
					CreateHat(client, 815, 1); //The Champ Stamp
				}
				case 125:
				{
					CreateHat(client, 815, 6); //The Champ Stamp
				}
				case 126:
				{
					CreateHat(client, 815, 11); //The Champ Stamp
				}
				case 127:
				{
					CreateHat(client, 618, 6); //The Crocodile Smile
				}
				case 128:
				{
					CreateHat(client, 618, 11); //The Crocodile Smile
				}	
				case 129:
				{
					CreateHat(client, 645, 6); //The Outback Intellectual
				}
				case 130:
				{
					CreateHat(client, 645, 11); //The Outback Intellectual
				}	
				case 131:
				{
					CreateHat(client, 646, 6); //The Itsy Bitsy Spyer
				}
				case 132:
				{
					CreateHat(client, 646, 11); //The Itsy Bitsy Spyer
				}	
				case 133:
				{
					CreateHat(client, 734, 6); //The Teufort Tooth Kicker
				}
				case 134:
				{
					CreateHat(client, 734, 11); //The Teufort Tooth Kicker
				}	
				case 135:
				{
					CreateHat(client, 734, 6); //Sir Hootsalot
				}
				case 136:
				{
					CreateHat(client, 734, 11); //Sir Hootsalot
				}	
				case 137:
				{
					CreateHat(client, 734, 13); //Sir Hootsalot
				}			
				case 138:
				{
					CreateHat(client, 948, 1); //The Deadliest Duckling
				}				
				case 139:
				{
					CreateHat(client, 948, 6); //The Deadliest Duckling
				}			
				case 140:
				{
					CreateHat(client, 1023, 1); //The Steel Songbird
				}				
				case 141:
				{
					CreateHat(client, 1023, 6); //The Steel Songbird
				}				
				case 142:
				{
					CreateHat(client, 1094, 1); //The Criminal Cloak
				}				
				case 143:
				{
					CreateHat(client, 1094, 6); //The Criminal Cloak
				}					
				case 144:
				{
					CreateHat(client, 30056, 6); //The Dual-Core Devil Doll
				}				
				case 145:
				{
					CreateHat(client, 30056, 11); //The Dual-Core Devil Doll
				}						
				case 146:
				{
					CreateHat(client, 30056, 6); //The Birdman of Australiacatraz
				}				
				case 147:
				{
					CreateHat(client, 30056, 11); //The Birdman of Australiacatraz
				}							
				case 148:
				{
					CreateHat(client, 30101, 6); //The Cobber Chameleon
				}				
				case 149:
				{
					CreateHat(client, 30101, 11); //The Cobber Chameleon
				}						
				case 150:
				{
					CreateHat(client, 30103, 6); //The Falconer
				}				
				case 151:
				{
					CreateHat(client, 30103, 11); //The Falconer
				}							
				case 152:
				{
					CreateHat(client, 30170, 6); //The Chronomancer
				}				
				case 153:
				{
					CreateHat(client, 30170, 11); //The Chronomancer
				}								
				case 154:
				{
					CreateHat(client, 30181, 6); //Li'l Snaggletooth
				}				
				case 155:
				{
					CreateHat(client, 30181, 11); //Li'l Snaggletooth
				}									
				case 156:
				{
					CreateHat(client, 30310, 6); //The Snow Scoper
				}				
				case 157:
				{
					CreateHat(client, 30310, 11); //The Snow Scoper
				}									
				case 158:
				{
					CreateHat(client, 30324, 6); //The Golden Garment
				}				
				case 159:
				{
					CreateHat(client, 30324, 11); //The Golden Garment
				}										
				case 160:
				{
					CreateHat(client, 30328, 6); //The Extra Layer
				}				
				case 161:
				{
					CreateHat(client, 30328, 11); //The Extra Layer
				}										
				case 162:
				{
					CreateHat(client, 30359, 6); //The Huntman's Essentials
				}				
				case 163:
				{
					CreateHat(client, 30359, 11); //The Huntman's Essentials
				}										
				case 164:
				{
					CreateHat(client, 30371, 6); //The Archers Groundings
				}				
				case 165:
				{
					CreateHat(client, 30371, 11); //The Archers Groundings
				}											
				case 166:
				{
					CreateHat(client, 30373, 6); //The Toowoomba Tunic
				}				
				case 167:
				{
					CreateHat(client, 30373, 11); //The Toowoomba Tunic
				}												
				case 168:
				{
					CreateHat(client, 30424, 6); //The Triggerman's Tacticals
				}				
				case 169:
				{
					CreateHat(client, 30424, 11); //The Triggerman's Tacticals
				}												
				case 170:
				{
					CreateHat(client, 30478, 6); //Poacher's Safari Jacket
				}				
				case 171:
				{
					CreateHat(client, 30478, 11); //Poacher's Safari Jacket
				}													
				case 172:
				{
					CreateHat(client, 30481, 6); //Hillbilly Speed Bump
				}				
				case 173:
				{
					CreateHat(client, 30481, 11); //Hillbilly Speed Bump
				}														
				case 174:
				{
					CreateHat(client, 30599, 6); //Marksman's Mohair
				}				
				case 175:
				{
					CreateHat(client, 30599, 11); //Marksman's Mohair
				}															
				case 176:
				{
					CreateHat(client, 30600, 6); //Wally Pocket
				}				
				case 177:
				{
					CreateHat(client, 30600, 11); //Wally Pocket
				}																
				case 178:
				{
					CreateHat(client, 30629, 15); //Support Spurs
				}				
				case 179:
				{
					CreateHat(client, 30629, 11); //Support Spurs
				}																
				case 180:
				{
					CreateHat(client, 30649, 15); //Final Fontiersman
				}				
				case 181:
				{
					CreateHat(client, 30649, 11); //Final Fontiersman
				}																
				case 182:
				{
					CreateHat(client, 30650, 15); //Starduster
				}				
				case 183:
				{
					CreateHat(client, 30650, 11); //Starduster
				}			
			}
		}
		case TFClass_Soldier:
		{
			int rnd3 = GetRandomUInt(0,193);
			switch (rnd3)
			{
				case 1:
				{
					CreateHat(client, 868, 6, 20); //Heroic Companion Badge
				}
				case 2:
				{
					CreateHat(client, 583, 6, 20); //Bombinomicon
				}
				case 3:
				{
					CreateHat(client, 586, 6); //Mark of the Saint
				}
				case 4:
				{
					CreateHat(client, 625, 6, 20); //Clan Pride
				}
				case 5:
				{
					CreateHat(client, 619, 6, 20); //Flair!
				}
				case 6:
				{
					CreateHat(client, 1025, 6); //The Fortune Hunter
				}
				case 7:
				{
					CreateHat(client, 623, 6, 20); //Photo Badge
				}
				case 8:
				{
					CreateHat(client, 738, 6); //Pet Balloonicorn
				}
				case 9:
				{
					CreateHat(client, 955, 6); //The Tuxxy
				}
				case 10:
				{
					CreateHat(client, 995, 6, 20); //Pet Reindoonicorn
				}
				case 11:
				{
					CreateHat(client, 987, 6); //The Merc's Muffler
				}
				case 12:
				{
					CreateHat(client, 1096, 6); //The Baronial Badge
				}
				case 13:
				{
					CreateHat(client, 30607, 6); //The Pocket Raiders
				}
				case 14:
				{
					CreateHat(client, 30068, 6); //The Breakneck Baggies
				}
				case 15:
				{
					CreateHat(client, 869, 6); //The Rump-o-Lantern
				}
				case 16:
				{
					CreateHat(client, 30309, 6); //Dead of Night
				}
				case 17:
				{
					CreateHat(client, 1024, 6); //Crofts Crest
				}
				case 18:
				{
					CreateHat(client, 992, 6); //Smissmas Wreath
				}
				case 19:
				{
					CreateHat(client, 956, 6); //Faerie Solitaire Pin
				}
				case 20:
				{
					CreateHat(client, 943, 6); //Hitt Mann Badge
				}
				case 21:
				{
					CreateHat(client, 873, 6, 20); //Whale Bone Charm
				}
				case 22:
				{
					CreateHat(client, 855, 6); //Vigilant Pin
				}
				case 23:
				{
					CreateHat(client, 818, 6); //Awesomenauts Badge
				}
				case 24:
				{
					CreateHat(client, 767, 6); //Atomic Accolade
				}
				case 25:
				{
					CreateHat(client, 718, 6); //Merc Medal
				}
				case 26:
				{
					CreateHat(client, 868, 1, 20); //Heroic Companion Badge
				}
				case 27:
				{
					CreateHat(client, 586, 1); //Mark of the Saint
				}
				case 28:
				{
					CreateHat(client, 625, 11, 20); //Clan Pride
				}
				case 29:
				{
					CreateHat(client, 619, 11, 20); //Flair!
				}
				case 30:
				{
					CreateHat(client, 1025, 1); //The Fortune Hunter
				}
				case 31:
				{
					CreateHat(client, 623, 11, 20); //Photo Badge
				}
				case 32:
				{
					CreateHat(client, 738, 1); //Pet Balloonicorn
				}
				case 33:
				{
					CreateHat(client, 738, 11); //Pet Balloonicorn
				}
				case 34:
				{
					CreateHat(client, 987, 11); //The Merc's Muffler
				}
				case 35:
				{
					CreateHat(client, 1096, 1); //The Baronial Badge
				}
				case 36:
				{
					CreateHat(client, 30068, 11); //The Breakneck Baggies
				}
				case 37:
				{
					CreateHat(client, 869, 11); //The Rump-o-Lantern
				}
				case 38:
				{
					CreateHat(client, 869, 13); //The Rump-o-Lantern
				}
				case 39:
				{
					CreateHat(client, 30309, 11); //Dead of Night
				}
				case 40:
				{
					CreateHat(client, 1024, 1); //Crofts Crest
				}
				case 41:
				{
					CreateHat(client, 956, 1); //Faerie Solitaire Pin
				}
				case 42:
				{
					CreateHat(client, 943, 1); //Hitt Mann Badge
				}
				case 43:
				{
					CreateHat(client, 873, 1, 20); //Whale Bone Charm
				}
				case 44:
				{
					CreateHat(client, 855, 1); //Vigilant Pin
				}
				case 45:
				{
					CreateHat(client, 818, 1); //Awesomenauts Badge
				}
				case 46:
				{
					CreateHat(client, 767, 1); //Atomic Accolade
				}
				case 47:
				{
					CreateHat(client, 718, 1); //Merc Medal
				}
				case 48:
				{
					CreateHat(client, 164, 6); //Grizzled Veteran
				}
				case 49:
				{
					CreateHat(client, 165, 6); //Soldier of Fortune
				}
				case 50:
				{
					CreateHat(client, 166, 6); //Mercenary
				}
				case 51:
				{
					CreateHat(client, 170, 6); //Primeval Warrior
				}
				case 52:
				{
					CreateHat(client, 242, 6); //Duel Medal Bronze
				}
				case 53:
				{
					CreateHat(client, 243, 6); //Duel Medal Silver
				}
				case 54:
				{
					CreateHat(client, 244, 6); //Duel Medal Gold
				}
				case 55:
				{
					CreateHat(client, 245, 6); //Duel Medal Plat
				}
				case 56:
				{
					CreateHat(client, 262, 6); //Polycount Pin
				}
				case 57:
				{
					CreateHat(client, 296, 6); //License to Maim
				}
				case 58:
				{
					CreateHat(client, 299, 1); //Companion Cube Pin
				}
				case 59:
				{
					CreateHat(client, 299, 3); //Companion Cube Pin
				}
				case 60:
				{
					CreateHat(client, 422, 3); //Resurrection Associate Pin
				}
				case 61:
				{
					CreateHat(client, 432, 6); //SpaceChem Pin
				}
				case 62:
				{
					CreateHat(client, 432, 6); //Dr. Grordbort's Crest
				}
				case 63:
				{
					CreateHat(client, 541, 6); //Merc's Pride Scarf
				}
				case 64:
				{
					CreateHat(client, 541, 1); //Merc's Pride Scarf
				}
				case 65:
				{
					CreateHat(client, 541, 11); //Merc's Pride Scarf
				}
				case 66:
				{
					CreateHat(client, 592, 6); //Dr. Grordbort's Copper Crest
				}
				case 67:
				{
					CreateHat(client, 636, 6); //Dr. Grordbort's Silver Crest
				}
				case 68:
				{
					CreateHat(client, 655, 11); //The Spirit of Giving
				}
				case 69:
				{
					CreateHat(client, 704, 1); //The Bolgan Family Crest
				}
				case 70:
				{
					CreateHat(client, 704, 6); //The Bolgan Family Crest
				}
				case 71:
				{
					CreateHat(client, 717, 1); //Mapmaker's Medallion
				}
				case 72:
				{
					CreateHat(client, 733, 6); //Pet Robro
				}
				case 73:
				{
					CreateHat(client, 733, 11); //Pet Robro
				}
				case 74:
				{
					CreateHat(client, 864, 1); //The Friends Forever Companion Square Badge
				}
				case 75:
				{
					CreateHat(client, 865, 1); //The Triple A Badge
				}
				case 76:
				{
					CreateHat(client, 953, 6); //The Saxxy Clapper Badge
				}
				case 77:
				{
					CreateHat(client, 995, 11); //Pet Reindoonicorn
				}
				case 78:
				{
					CreateHat(client, 1011, 6); //Tux
				}
				case 79:
				{
					CreateHat(client, 1126, 6); //Duck Badge
				}
				case 80:
				{
					CreateHat(client, 5075, 6); //Something Special For Someone Special
				}
				case 81:
				{
					CreateHat(client, 30000, 9); //The Electric Badge-alo
				}
				case 82:
				{
					CreateHat(client, 30550, 6); //Snow Sleeves
				}
				case 83:
				{
					CreateHat(client, 30550, 11); //Snow Sleeves
				}
				case 84:
				{
					CreateHat(client, 30551, 6); //Flashdance Footies
				}
				case 85:
				{
					CreateHat(client, 30551, 11); //Flashdance Footies
				}
				case 86:
				{
					CreateHat(client, 30559, 9); //End of the Line Community Update Medal
				}
				case 87:
				{
					CreateHat(client, 30669, 15); //Space Hamster Hammy
				}
				case 88:
				{
					CreateHat(client, 30669, 11); //Space Hamster Hammy
				}
				case 89:
				{
					CreateHat(client, 30670, 9); //Invasion Community Update Medal
				}
				case 90:
				{
					CreateHat(client, 927, 6); //The Boo Balloon
				}
				case 91:
				{
					CreateHat(client, 927, 13); //The Boo Balloon
				}
				case 92:
				{
					CreateHat(client, 929, 6); //The Unknown Monkeynaut
				}
				case 93:
				{
					CreateHat(client, 929, 13); //The Unknown Monkeynaut
				}
				case 94:
				{
					CreateHat(client, 934, 6); //The Dead Little Buddy
				}
				case 95:
				{
					CreateHat(client, 934, 13); //The Dead Little Buddy
				}
				case 96:
				{
					CreateHat(client, 30198, 6); //The Pocket Horsemann
				}
				case 97:
				{
					CreateHat(client, 30198, 13); //The Pocket Horsemann
				}
				case 98:
				{
					CreateHat(client, 30206, 6); //The Accursed Apparition
				}
				case 99:
				{
					CreateHat(client, 30206, 13); //The Accursed Apparition
				}
				case 100:
				{
					CreateHat(client, 30234, 6); //The Sackcloth Spook
				}
				case 101:
				{
					CreateHat(client, 30234, 13); //The Sackcloth Spook
				}
				case 102:
				{
					CreateHat(client, 30252, 6); //Guano
				}
				case 103:
				{
					CreateHat(client, 30252, 13); //Guano
				}
				case 104:
				{
					CreateHat(client, 30254, 6); //Unidentified Following Object
				}
				case 105:
				{
					CreateHat(client, 30254, 13); //Unidentified Following Object
				}
				case 106:
				{
					CreateHat(client, 30255, 6); //The Beacon From Beyond
				}
				case 107:
				{
					CreateHat(client, 30255, 13); //The Beacon From Beyond
				}
				case 108:
				{
					CreateHat(client, 30289, 6); //Quoth
				}
				case 109:
				{
					CreateHat(client, 30289, 13); //Quoth
				}
				case 110:
				{
					CreateHat(client, 30302, 6); //The Cryptic Keepsake
				}
				case 111:
				{
					CreateHat(client, 30302, 13); //The Cryptic Keepsake
				}
				case 112:
				{
					CreateHat(client, 30497, 6); //Ghost of Spies Checked Past
				}
				case 113:
				{
					CreateHat(client, 30497, 13); //Ghost of Spies Checked Past
				}
				case 114:
				{
					CreateHat(client, 30497, 11); //Ghost of Spies Checked Past
				}
				case 115:
				{
					CreateHat(client, 30498, 6); //The Hooded Haunter
				}
				case 116:
				{
					CreateHat(client, 30498, 13); //The Hooded Haunter
				}
				case 117:
				{
					CreateHat(client, 30498, 11); //The Hooded Haunter
				}
				case 118:
				{
					CreateHat(client, 30536, 6); //Cursed Cruise
				}
				case 119:
				{
					CreateHat(client, 30536, 13); //Cursed Cruise
				}
				case 120:
				{
					CreateHat(client, 30536, 11); //Cursed Cruise
				}	
				case 121:
				{
					CreateHat(client, 734, 6); //The Teufort Tooth Kicker
				}
				case 122:
				{
					CreateHat(client, 734, 11); //The Teufort Tooth Kicker
				}	
				case 124:
				{
					CreateHat(client, 121, 6); //Service Medal
				}		
				case 125:
				{
					CreateHat(client, 392, 6); //Pocket Medic
				}			
				case 126:
				{
					CreateHat(client, 446, 6); //Fancy Dress Uniform
				}				
				case 127:
				{
					CreateHat(client, 446, 11); //Fancy Dress Uniform
				}				
				case 128:
				{
					CreateHat(client, 641, 6); //The Ornament Armament
				}				
				case 129:
				{
					CreateHat(client, 641, 11); //The Ornament Armament
				}					
				case 130:
				{
					CreateHat(client, 650, 6); //The Kringle Collection
				}				
				case 131:
				{
					CreateHat(client, 650, 11); //The Kringle Collection
				}						
				case 132:
				{
					CreateHat(client, 731, 6); //The Captain's Cocktails
				}				
				case 133:
				{
					CreateHat(client, 731, 11); //The Captain's Cocktails
				}						
				case 134:
				{
					CreateHat(client, 768, 6); //The Professor's Pineapple
				}				
				case 135:
				{
					CreateHat(client, 768, 11); //The Professor's Pineapple
				}						
				case 136:
				{
					CreateHat(client, 922, 6); //The Bonedolier
				}				
				case 137:
				{
					CreateHat(client, 922, 11); //The Bonedolier
				}					
				case 138:
				{
					CreateHat(client, 922, 13); //The Bonedolier
				}				
				case 139:
				{
					CreateHat(client, 948, 1); //The Deadliest Duckling
				}				
				case 140:
				{
					CreateHat(client, 948, 6); //The Deadliest Duckling
				}				
				case 141:
				{
					CreateHat(client, 1074, 6); //The War on Smissmas Battle Socks
				}				
				case 142:
				{
					CreateHat(client, 30115, 6); //The Compatriot
				}				
				case 143:
				{
					CreateHat(client, 30115, 11); //The Compatriot
				}				
				case 144:
				{
					CreateHat(client, 30117, 6); //The Colonial Clogs
				}				
				case 145:
				{
					CreateHat(client, 30117, 11); //The Colonial Clogs
				}				
				case 146:
				{
					CreateHat(client, 30126, 6); //The Shotgun's Shoulder Guard
				}				
				case 147:
				{
					CreateHat(client, 30126, 11); //The Shotgun's Shoulder Guard
				}				
				case 148:
				{
					CreateHat(client, 30129, 6); //The Hornblower
				}				
				case 149:
				{
					CreateHat(client, 30129, 11); //The Hornblower
				}				
				case 150:
				{
					CreateHat(client, 30130, 6); //Lieutenant Bites
				}				
				case 151:
				{
					CreateHat(client, 30130, 11); //Lieutenant Bites
				}				
				case 152:
				{
					CreateHat(client, 30131, 6); //The Brawling Buccaneer
				}				
				case 153:
				{
					CreateHat(client, 30131, 11); //The Brawling Buccaneer
				}				
				case 154:
				{
					CreateHat(client, 30142, 6); //The Founding Father
				}				
				case 155:
				{
					CreateHat(client, 30142, 11); //The Founding Father
				}				
				case 156:
				{
					CreateHat(client, 30331, 6); //Anarctic Parka
				}				
				case 157:
				{
					CreateHat(client, 30331, 11); //Anarctic Parka
				}				
				case 158:
				{
					CreateHat(client, 30339, 6); //The Killer's Kit
				}				
				case 159:
				{
					CreateHat(client, 30339, 11); //The Killer's Kit
				}				
				case 160:
				{
					CreateHat(client, 30388, 6); //The Classified Coif
				}				
				case 161:
				{
					CreateHat(client, 30388, 11); //The Classified Coif
				}				
				case 162:
				{
					CreateHat(client, 30392, 6); //The Man in Slacks
				}				
				case 163:
				{
					CreateHat(client, 30392, 11); //The Man in Slacks
				}				
				case 164:
				{
					CreateHat(client, 30543, 6); //Snow Stompers
				}				
				case 165:
				{
					CreateHat(client, 30543, 11); //Snow Stompers
				}				
				case 166:
				{
					CreateHat(client, 30558, 6); //Coldfront Curbstompers
				}				
				case 167:
				{
					CreateHat(client, 30558, 11); //Coldfront Curbstompers
				}				
				case 168:
				{
					CreateHat(client, 30601, 6); //Cold Snap Coat
				}				
				case 169:
				{
					CreateHat(client, 30601, 11); //Cold Snap Coat
				}				
				case 170:
				{
					CreateHat(client, 556, 6); //Steel Pipes
				}				
				case 171:
				{
					CreateHat(client, 556, 13); //Steel Pipes
				}				
				case 172:
				{
					CreateHat(client, 556, 6); //Shoestring Budget
				}				
				case 173:
				{
					CreateHat(client, 556, 13); //Shoestring Budget
				}				
				case 174:
				{
					CreateHat(client, 30221, 6); //Grub Grenades
				}				
				case 175:
				{
					CreateHat(client, 30221, 13); //Grub Grenades
				}				
				case 176:
				{
					CreateHat(client, 30236, 6); //Pin Pals
				}				
				case 177:
				{
					CreateHat(client, 30236, 13); //Pin Pals
				}				
				case 178:
				{
					CreateHat(client, 30242, 6); //The Candleer
				}				
				case 179:
				{
					CreateHat(client, 30242, 13); //The Candleer
				}				
				case 180:
				{
					CreateHat(client, 30265, 6); //The Jupiter Jumpers
				}				
				case 181:
				{
					CreateHat(client, 30265, 13); //The Jupiter Jumpers
				}				
				case 182:
				{
					CreateHat(client, 30266, 6); //The Space Bracers
				}				
				case 183:
				{
					CreateHat(client, 30266, 13); //The Space Bracers
				}				
				case 184:
				{
					CreateHat(client, 30276, 6); //Lieutenant Bites the Dust
				}				
				case 185:
				{
					CreateHat(client, 30276, 13); //Lieutenant Bites the Dust
				}				
				case 186:
				{
					CreateHat(client, 30276, 6); //The Shaolin Sash
				}				
				case 187:
				{
					CreateHat(client, 30276, 13); //The Shaolin Sash
				}				
				case 188:
				{
					CreateHat(client, 30520, 6); //Ghoul Gibbin' Gear
				}				
				case 189:
				{
					CreateHat(client, 30520, 13); //Ghoul Gibbin' Gear
				}				
				case 190:
				{
					CreateHat(client, 30520, 11); //Ghoul Gibbin' Gear
				}
				case 191:
				{
					CreateHat(client, 936, 6); //The Exorcizor
				}
				case 192:
				{
					CreateHat(client, 936, 11); //The Exorcizor
				}
				case 193:
				{
					CreateHat(client, 936, 13); //The Exorcizor
				}
			}
		}
		case TFClass_DemoMan:
		{
			int rnd3 = GetRandomUInt(0,199);
			switch (rnd3)
			{
				case 1:
				{
					CreateHat(client, 868, 6, 20); //Heroic Companion Badge
				}
				case 2:
				{
					CreateHat(client, 583, 6, 20); //Bombinomicon
				}
				case 3:
				{
					CreateHat(client, 586, 6); //Mark of the Saint
				}
				case 4:
				{
					CreateHat(client, 625, 6, 20); //Clan Pride
				}
				case 5:
				{
					CreateHat(client, 619, 6, 20); //Flair!
				}
				case 6:
				{
					CreateHat(client, 1025, 6); //The Fortune Hunter
				}
				case 7:
				{
					CreateHat(client, 623, 6, 20); //Photo Badge
				}
				case 8:
				{
					CreateHat(client, 738, 6); //Pet Balloonicorn
				}
				case 9:
				{
					CreateHat(client, 955, 6); //The Tuxxy
				}
				case 10:
				{
					CreateHat(client, 995, 6, 20); //Pet Reindoonicorn
				}
				case 11:
				{
					CreateHat(client, 987, 6); //The Merc's Muffler
				}
				case 12:
				{
					CreateHat(client, 1096, 6); //The Baronial Badge
				}
				case 13:
				{
					CreateHat(client, 30607, 6); //The Pocket Raiders
				}
				case 14:
				{
					CreateHat(client, 30068, 6); //The Breakneck Baggies
				}
				case 15:
				{
					CreateHat(client, 869, 6); //The Rump-o-Lantern
				}
				case 16:
				{
					CreateHat(client, 30309, 6); //Dead of Night
				}
				case 17:
				{
					CreateHat(client, 1024, 6); //Crofts Crest
				}
				case 18:
				{
					CreateHat(client, 992, 6); //Smissmas Wreath
				}
				case 19:
				{
					CreateHat(client, 956, 6); //Faerie Solitaire Pin
				}
				case 20:
				{
					CreateHat(client, 943, 6); //Hitt Mann Badge
				}
				case 21:
				{
					CreateHat(client, 873, 6, 20); //Whale Bone Charm
				}
				case 22:
				{
					CreateHat(client, 855, 6); //Vigilant Pin
				}
				case 23:
				{
					CreateHat(client, 818, 6); //Awesomenauts Badge
				}
				case 24:
				{
					CreateHat(client, 767, 6); //Atomic Accolade
				}
				case 25:
				{
					CreateHat(client, 718, 6); //Merc Medal
				}
				case 26:
				{
					CreateHat(client, 868, 1, 20); //Heroic Companion Badge
				}
				case 27:
				{
					CreateHat(client, 586, 1); //Mark of the Saint
				}
				case 28:
				{
					CreateHat(client, 625, 11, 20); //Clan Pride
				}
				case 29:
				{
					CreateHat(client, 619, 11, 20); //Flair!
				}
				case 30:
				{
					CreateHat(client, 1025, 1); //The Fortune Hunter
				}
				case 31:
				{
					CreateHat(client, 623, 11, 20); //Photo Badge
				}
				case 32:
				{
					CreateHat(client, 738, 1); //Pet Balloonicorn
				}
				case 33:
				{
					CreateHat(client, 738, 11); //Pet Balloonicorn
				}
				case 34:
				{
					CreateHat(client, 987, 11); //The Merc's Muffler
				}
				case 35:
				{
					CreateHat(client, 1096, 1); //The Baronial Badge
				}
				case 36:
				{
					CreateHat(client, 30068, 11); //The Breakneck Baggies
				}
				case 37:
				{
					CreateHat(client, 869, 11); //The Rump-o-Lantern
				}
				case 38:
				{
					CreateHat(client, 869, 13); //The Rump-o-Lantern
				}
				case 39:
				{
					CreateHat(client, 30309, 11); //Dead of Night
				}
				case 40:
				{
					CreateHat(client, 1024, 1); //Crofts Crest
				}
				case 41:
				{
					CreateHat(client, 956, 1); //Faerie Solitaire Pin
				}
				case 42:
				{
					CreateHat(client, 943, 1); //Hitt Mann Badge
				}
				case 43:
				{
					CreateHat(client, 873, 1, 20); //Whale Bone Charm
				}
				case 44:
				{
					CreateHat(client, 855, 1); //Vigilant Pin
				}
				case 45:
				{
					CreateHat(client, 818, 1); //Awesomenauts Badge
				}
				case 46:
				{
					CreateHat(client, 767, 1); //Atomic Accolade
				}
				case 47:
				{
					CreateHat(client, 718, 1); //Merc Medal
				}
				case 48:
				{
					CreateHat(client, 164, 6); //Grizzled Veteran
				}
				case 49:
				{
					CreateHat(client, 165, 6); //Soldier of Fortune
				}
				case 50:
				{
					CreateHat(client, 166, 6); //Mercenary
				}
				case 51:
				{
					CreateHat(client, 170, 6); //Primeval Warrior
				}
				case 52:
				{
					CreateHat(client, 242, 6); //Duel Medal Bronze
				}
				case 53:
				{
					CreateHat(client, 243, 6); //Duel Medal Silver
				}
				case 54:
				{
					CreateHat(client, 244, 6); //Duel Medal Gold
				}
				case 55:
				{
					CreateHat(client, 245, 6); //Duel Medal Plat
				}
				case 56:
				{
					CreateHat(client, 262, 6); //Polycount Pin
				}
				case 57:
				{
					CreateHat(client, 296, 6); //License to Maim
				}
				case 58:
				{
					CreateHat(client, 299, 1); //Companion Cube Pin
				}
				case 59:
				{
					CreateHat(client, 299, 3); //Companion Cube Pin
				}
				case 60:
				{
					CreateHat(client, 422, 3); //Resurrection Associate Pin
				}
				case 61:
				{
					CreateHat(client, 432, 6); //SpaceChem Pin
				}
				case 62:
				{
					CreateHat(client, 432, 6); //Dr. Grordbort's Crest
				}
				case 63:
				{
					CreateHat(client, 541, 6); //Merc's Pride Scarf
				}
				case 64:
				{
					CreateHat(client, 541, 1); //Merc's Pride Scarf
				}
				case 65:
				{
					CreateHat(client, 541, 11); //Merc's Pride Scarf
				}
				case 66:
				{
					CreateHat(client, 592, 6); //Dr. Grordbort's Copper Crest
				}
				case 67:
				{
					CreateHat(client, 636, 6); //Dr. Grordbort's Silver Crest
				}
				case 68:
				{
					CreateHat(client, 655, 11); //The Spirit of Giving
				}
				case 69:
				{
					CreateHat(client, 704, 1); //The Bolgan Family Crest
				}
				case 70:
				{
					CreateHat(client, 704, 6); //The Bolgan Family Crest
				}
				case 71:
				{
					CreateHat(client, 717, 1); //Mapmaker's Medallion
				}
				case 72:
				{
					CreateHat(client, 733, 6); //Pet Robro
				}
				case 73:
				{
					CreateHat(client, 733, 11); //Pet Robro
				}
				case 74:
				{
					CreateHat(client, 864, 1); //The Friends Forever Companion Square Badge
				}
				case 75:
				{
					CreateHat(client, 865, 1); //The Triple A Badge
				}
				case 76:
				{
					CreateHat(client, 953, 6); //The Saxxy Clapper Badge
				}
				case 77:
				{
					CreateHat(client, 995, 11); //Pet Reindoonicorn
				}
				case 78:
				{
					CreateHat(client, 1011, 6); //Tux
				}
				case 79:
				{
					CreateHat(client, 1126, 6); //Duck Badge
				}
				case 80:
				{
					CreateHat(client, 5075, 6); //Something Special For Someone Special
				}
				case 81:
				{
					CreateHat(client, 30000, 9); //The Electric Badge-alo
				}
				case 82:
				{
					CreateHat(client, 30550, 6); //Snow Sleeves
				}
				case 83:
				{
					CreateHat(client, 30550, 11); //Snow Sleeves
				}
				case 84:
				{
					CreateHat(client, 30551, 6); //Flashdance Footies
				}
				case 85:
				{
					CreateHat(client, 30551, 11); //Flashdance Footies
				}
				case 86:
				{
					CreateHat(client, 30559, 9); //End of the Line Community Update Medal
				}
				case 87:
				{
					CreateHat(client, 30669, 15); //Space Hamster Hammy
				}
				case 88:
				{
					CreateHat(client, 30669, 11); //Space Hamster Hammy
				}
				case 89:
				{
					CreateHat(client, 30670, 9); //Invasion Community Update Medal
				}
				case 90:
				{
					CreateHat(client, 927, 6); //The Boo Balloon
				}
				case 91:
				{
					CreateHat(client, 927, 13); //The Boo Balloon
				}
				case 92:
				{
					CreateHat(client, 929, 6); //The Unknown Monkeynaut
				}
				case 93:
				{
					CreateHat(client, 929, 13); //The Unknown Monkeynaut
				}
				case 94:
				{
					CreateHat(client, 934, 6); //The Dead Little Buddy
				}
				case 95:
				{
					CreateHat(client, 934, 13); //The Dead Little Buddy
				}
				case 96:
				{
					CreateHat(client, 30198, 6); //The Pocket Horsemann
				}
				case 97:
				{
					CreateHat(client, 30198, 13); //The Pocket Horsemann
				}
				case 98:
				{
					CreateHat(client, 30206, 6); //The Accursed Apparition
				}
				case 99:
				{
					CreateHat(client, 30206, 13); //The Accursed Apparition
				}
				case 100:
				{
					CreateHat(client, 30234, 6); //The Sackcloth Spook
				}
				case 101:
				{
					CreateHat(client, 30234, 13); //The Sackcloth Spook
				}
				case 102:
				{
					CreateHat(client, 30252, 6); //Guano
				}
				case 103:
				{
					CreateHat(client, 30252, 13); //Guano
				}
				case 104:
				{
					CreateHat(client, 30254, 6); //Unidentified Following Object
				}
				case 105:
				{
					CreateHat(client, 30254, 13); //Unidentified Following Object
				}
				case 106:
				{
					CreateHat(client, 30255, 6); //The Beacon From Beyond
				}
				case 107:
				{
					CreateHat(client, 30255, 13); //The Beacon From Beyond
				}
				case 108:
				{
					CreateHat(client, 30289, 6); //Quoth
				}
				case 109:
				{
					CreateHat(client, 30289, 13); //Quoth
				}
				case 110:
				{
					CreateHat(client, 30302, 6); //The Cryptic Keepsake
				}
				case 111:
				{
					CreateHat(client, 30302, 13); //The Cryptic Keepsake
				}
				case 112:
				{
					CreateHat(client, 30497, 6); //Ghost of Spies Checked Past
				}
				case 113:
				{
					CreateHat(client, 30497, 13); //Ghost of Spies Checked Past
				}
				case 114:
				{
					CreateHat(client, 30497, 11); //Ghost of Spies Checked Past
				}
				case 115:
				{
					CreateHat(client, 30498, 6); //The Hooded Haunter
				}
				case 116:
				{
					CreateHat(client, 30498, 13); //The Hooded Haunter
				}
				case 117:
				{
					CreateHat(client, 30498, 11); //The Hooded Haunter
				}
				case 118:
				{
					CreateHat(client, 30536, 6); //Cursed Cruise
				}
				case 119:
				{
					CreateHat(client, 30536, 13); //Cursed Cruise
				}
				case 120:
				{
					CreateHat(client, 30536, 11); //Cursed Cruise
				}
				case 121:
				{
					CreateHat(client, 1016, 11); //Buck Turner All-Stars
				}
				case 122:
				{
					CreateHat(client, 30200, 6); //The Baphomet Trotters
				}
				case 123:
				{
					CreateHat(client, 30200, 13); //The Baphomet Trotters
				}	
				case 124:
				{
					CreateHat(client, 734, 6); //The Teufort Tooth Kicker
				}
				case 125:
				{
					CreateHat(client, 734, 11); //The Teufort Tooth Kicker
				}					
				case 126:
				{
					CreateHat(client, 641, 6); //The Ornament Armament
				}				
				case 127:
				{
					CreateHat(client, 641, 11); //The Ornament Armament
				}						
				case 129:
				{
					CreateHat(client, 768, 6); //The Professor's Pineapple
				}				
				case 130:
				{
					CreateHat(client, 768, 11); //The Professor's Pineapple
				}						
				case 131:
				{
					CreateHat(client, 922, 6); //The Bonedolier
				}				
				case 132:
				{
					CreateHat(client, 922, 11); //The Bonedolier
				}					
				case 133:
				{
					CreateHat(client, 922, 13); //The Bonedolier
				}			
				case 134:
				{
					CreateHat(client, 948, 1); //The Deadliest Duckling
				}				
				case 135:
				{
					CreateHat(client, 948, 6); //The Deadliest Duckling
				}				
				case 136:
				{
					CreateHat(client, 30242, 6); //The Candleer
				}				
				case 137:
				{
					CreateHat(client, 30242, 13); //The Candleer
				}					
				case 138:
				{
					CreateHat(client, 610, 6); //A Whiff of the Old Brimstone
				}					
				case 139:
				{
					CreateHat(client, 610, 11); //A Whiff of the Old Brimstone
				}					
				case 140:
				{
					CreateHat(client, 708, 6); //Aladdin's Private Reserve
				}						
				case 141:
				{
					CreateHat(client, 708, 11); //Aladdin's Private Reserve
				}					
				case 142:
				{
					CreateHat(client, 771, 6); //The Liquor Locker
				}						
				case 143:
				{
					CreateHat(client, 771, 11); //The Liquor Locker
				}						
				case 144:
				{
					CreateHat(client, 776, 6); //The Bird-Man of Aberdeen
				}						
				case 145:
				{
					CreateHat(client, 776, 11); //The Bird-Man of Aberdeen
				}							
				case 146:
				{
					CreateHat(client, 845, 6); //The Battery Bandolier
				}							
				case 147:
				{
					CreateHat(client, 874, 6); //King of Scotland Cape
				}							
				case 148:
				{
					CreateHat(client, 874, 1); //King of Scotland Cape
				}								
				case 149:
				{
					CreateHat(client, 976, 6); //The Cool Breeze
				}								
				case 150:
				{
					CreateHat(client, 976, 11); //The Cool Breeze
				}									
				case 151:
				{
					CreateHat(client, 30055, 6); //The Scrumpy Strongbox
				}								
				case 152:
				{
					CreateHat(client, 30055, 11); //The Scrumpy Strongbox
				}								
				case 153:
				{
					CreateHat(client, 30061, 1); //The Tartantaloons
				}								
				case 154:
				{
					CreateHat(client, 30061, 6); //The Tartantaloons
				}								
				case 155:
				{
					CreateHat(client, 30073, 6); //The Dark Age Defender
				}								
				case 156:
				{
					CreateHat(client, 30073, 11); //The Dark Age Defender
				}								
				case 157:
				{
					CreateHat(client, 30107, 6); //The Gaelic Golf Bag
				}								
				case 158:
				{
					CreateHat(client, 30107, 11); //The Gaelic Golf Bag
				}								
				case 159:
				{
					CreateHat(client, 30110, 6); //The Whiskey Bib
				}								
				case 160:
				{
					CreateHat(client, 30110, 11); //The Whiskey Bib
				}								
				case 161:
				{
					CreateHat(client, 30124, 6); //The Gaelic Garb
				}								
				case 162:
				{
					CreateHat(client, 30124, 11); //The Gaelic Garb
				}								
				case 163:
				{
					CreateHat(client, 30179, 6); //The Hurt Locher
				}								
				case 164:
				{
					CreateHat(client, 30179, 11); //The Hurt Locher
				}									
				case 165:
				{
					CreateHat(client, 30333, 6); //Highland High Heels
				}								
				case 166:
				{
					CreateHat(client, 30333, 11); //Highland High Heels
				}										
				case 167:
				{
					CreateHat(client, 30348, 6); //Bushi-Dou
				}								
				case 168:
				{
					CreateHat(client, 30348, 11); //Bushi-Dou
				}											
				case 169:
				{
					CreateHat(client, 30358, 6); //The Sole Saviors
				}								
				case 170:
				{
					CreateHat(client, 30358, 11); //The Sole Saviors
				}											
				case 171:
				{
					CreateHat(client, 30363, 6); //The Juggernaut Jacket
				}								
				case 172:
				{
					CreateHat(client, 30363, 11); //The Juggernaut Jacket
				}												
				case 173:
				{
					CreateHat(client, 30366, 6); //The Sangu Sleeves
				}								
				case 174:
				{
					CreateHat(client, 30366, 11); //The Sangu Sleeves
				}												
				case 175:
				{
					CreateHat(client, 30431, 6); //Six Pack Abs
				}								
				case 176:
				{
					CreateHat(client, 30431, 11); //Six Pack Abs
				}												
				case 177:
				{
					CreateHat(client, 30480, 6); //Mann of the Seven Seas
				}								
				case 178:
				{
					CreateHat(client, 30480, 11); //Mann of the Seven Seas
				}												
				case 179:
				{
					CreateHat(client, 30541, 6); //Double Dynamite
				}								
				case 180:
				{
					CreateHat(client, 30541, 11); //Double Dynamite
				}												
				case 181:
				{
					CreateHat(client, 30555, 6); //Double Dog Dare Demo Pants
				}								
				case 182:
				{
					CreateHat(client, 30555, 11); //Double Dog Dare Demo Pants
				}												
				case 183:
				{
					CreateHat(client, 30587, 6); //Storm Stompers
				}								
				case 184:
				{
					CreateHat(client, 30587, 11); //Storm Stompers
				}													
				case 185:
				{
					CreateHat(client, 545, 6); //Pickled Paws
				}								
				case 186:
				{
					CreateHat(client, 545, 13); //Pickled Paws
				}														
				case 187:
				{
					CreateHat(client, 30226, 6); //Polly Putrid
				}								
				case 188:
				{
					CreateHat(client, 30226, 13); //Polly Putrid
				}															
				case 189:
				{
					CreateHat(client, 30243, 6); //The Horsemann's Hand-Me-Down
				}								
				case 190:
				{
					CreateHat(client, 30243, 13); //The Horsemann's Hand-Me-Down
				}																
				case 191:
				{
					CreateHat(client, 30249, 6); //Lordly Lapels
				}								
				case 192:
				{
					CreateHat(client, 30249, 13); //Lordly Lapels
				}																
				case 193:
				{
					CreateHat(client, 30517, 6); //Forgotten King's Pauldrons
				}								
				case 194:
				{
					CreateHat(client, 30517, 13); //Forgotten King's Pauldrons
				}								
				case 195:
				{
					CreateHat(client, 30517, 11); //Forgotten King's Pauldrons
				}		
				case 196:
				{
					CreateHat(client, 30178, 6); //Weight Room Warmer
				}		
				case 197:
				{
					CreateHat(client, 30178, 11); //Weight Room Warmer
				}
				case 198:
				{
					CreateHat(client, 30305, 6); //The Sub Zero Suit
				}
				case 199:
				{
					CreateHat(client, 30305, 11); //The Sub Zero Suit
				}		
			}
		}
		case TFClass_Medic:
		{
			int rnd3 = GetRandomUInt(0,200);
			switch (rnd3)
			{
				case 1:
				{
					CreateHat(client, 868, 6, 20); //Heroic Companion Badge
				}
				case 2:
				{
					CreateHat(client, 583, 6, 20); //Bombinomicon
				}
				case 3:
				{
					CreateHat(client, 586, 6); //Mark of the Saint
				}
				case 4:
				{
					CreateHat(client, 625, 6, 20); //Clan Pride
				}
				case 5:
				{
					CreateHat(client, 619, 6, 20); //Flair!
				}
				case 6:
				{
					CreateHat(client, 1025, 6); //The Fortune Hunter
				}
				case 7:
				{
					CreateHat(client, 623, 6, 20); //Photo Badge
				}
				case 8:
				{
					CreateHat(client, 738, 6); //Pet Balloonicorn
				}
				case 9:
				{
					CreateHat(client, 955, 6); //The Tuxxy
				}
				case 10:
				{
					CreateHat(client, 995, 6, 20); //Pet Reindoonicorn
				}
				case 11:
				{
					CreateHat(client, 987, 6); //The Merc's Muffler
				}
				case 12:
				{
					CreateHat(client, 1096, 6); //The Baronial Badge
				}
				case 13:
				{
					CreateHat(client, 30607, 6); //The Pocket Raiders
				}
				case 14:
				{
					CreateHat(client, 30068, 6); //The Breakneck Baggies
				}
				case 15:
				{
					CreateHat(client, 869, 6); //The Rump-o-Lantern
				}
				case 16:
				{
					CreateHat(client, 30309, 6); //Dead of Night
				}
				case 17:
				{
					CreateHat(client, 1024, 6); //Crofts Crest
				}
				case 18:
				{
					CreateHat(client, 992, 6); //Smissmas Wreath
				}
				case 19:
				{
					CreateHat(client, 956, 6); //Faerie Solitaire Pin
				}
				case 20:
				{
					CreateHat(client, 943, 6); //Hitt Mann Badge
				}
				case 21:
				{
					CreateHat(client, 873, 6, 20); //Whale Bone Charm
				}
				case 22:
				{
					CreateHat(client, 855, 6); //Vigilant Pin
				}
				case 23:
				{
					CreateHat(client, 818, 6); //Awesomenauts Badge
				}
				case 24:
				{
					CreateHat(client, 767, 6); //Atomic Accolade
				}
				case 25:
				{
					CreateHat(client, 718, 6); //Merc Medal
				}
				case 26:
				{
					CreateHat(client, 868, 1, 20); //Heroic Companion Badge
				}
				case 27:
				{
					CreateHat(client, 586, 1); //Mark of the Saint
				}
				case 28:
				{
					CreateHat(client, 625, 11, 20); //Clan Pride
				}
				case 29:
				{
					CreateHat(client, 619, 11, 20); //Flair!
				}
				case 30:
				{
					CreateHat(client, 1025, 1); //The Fortune Hunter
				}
				case 31:
				{
					CreateHat(client, 623, 11, 20); //Photo Badge
				}
				case 32:
				{
					CreateHat(client, 738, 1); //Pet Balloonicorn
				}
				case 33:
				{
					CreateHat(client, 738, 11); //Pet Balloonicorn
				}
				case 34:
				{
					CreateHat(client, 987, 11); //The Merc's Muffler
				}
				case 35:
				{
					CreateHat(client, 1096, 1); //The Baronial Badge
				}
				case 36:
				{
					CreateHat(client, 30068, 11); //The Breakneck Baggies
				}
				case 37:
				{
					CreateHat(client, 869, 11); //The Rump-o-Lantern
				}
				case 38:
				{
					CreateHat(client, 869, 13); //The Rump-o-Lantern
				}
				case 39:
				{
					CreateHat(client, 30309, 11); //Dead of Night
				}
				case 40:
				{
					CreateHat(client, 1024, 1); //Crofts Crest
				}
				case 41:
				{
					CreateHat(client, 956, 1); //Faerie Solitaire Pin
				}
				case 42:
				{
					CreateHat(client, 943, 1); //Hitt Mann Badge
				}
				case 43:
				{
					CreateHat(client, 873, 1, 20); //Whale Bone Charm
				}
				case 44:
				{
					CreateHat(client, 855, 1); //Vigilant Pin
				}
				case 45:
				{
					CreateHat(client, 818, 1); //Awesomenauts Badge
				}
				case 46:
				{
					CreateHat(client, 767, 1); //Atomic Accolade
				}
				case 47:
				{
					CreateHat(client, 718, 1); //Merc Medal
				}
				case 48:
				{
					CreateHat(client, 164, 6); //Grizzled Veteran
				}
				case 49:
				{
					CreateHat(client, 165, 6); //Soldier of Fortune
				}
				case 50:
				{
					CreateHat(client, 166, 6); //Mercenary
				}
				case 51:
				{
					CreateHat(client, 170, 6); //Primeval Warrior
				}
				case 52:
				{
					CreateHat(client, 242, 6); //Duel Medal Bronze
				}
				case 53:
				{
					CreateHat(client, 243, 6); //Duel Medal Silver
				}
				case 54:
				{
					CreateHat(client, 244, 6); //Duel Medal Gold
				}
				case 55:
				{
					CreateHat(client, 245, 6); //Duel Medal Plat
				}
				case 56:
				{
					CreateHat(client, 262, 6); //Polycount Pin
				}
				case 57:
				{
					CreateHat(client, 296, 6); //License to Maim
				}
				case 58:
				{
					CreateHat(client, 299, 1); //Companion Cube Pin
				}
				case 59:
				{
					CreateHat(client, 299, 3); //Companion Cube Pin
				}
				case 60:
				{
					CreateHat(client, 422, 3); //Resurrection Associate Pin
				}
				case 61:
				{
					CreateHat(client, 432, 6); //SpaceChem Pin
				}
				case 62:
				{
					CreateHat(client, 432, 6); //Dr. Grordbort's Crest
				}
				case 63:
				{
					CreateHat(client, 541, 6); //Merc's Pride Scarf
				}
				case 64:
				{
					CreateHat(client, 541, 1); //Merc's Pride Scarf
				}
				case 65:
				{
					CreateHat(client, 541, 11); //Merc's Pride Scarf
				}
				case 66:
				{
					CreateHat(client, 592, 6); //Dr. Grordbort's Copper Crest
				}
				case 67:
				{
					CreateHat(client, 636, 6); //Dr. Grordbort's Silver Crest
				}
				case 68:
				{
					CreateHat(client, 655, 11); //The Spirit of Giving
				}
				case 69:
				{
					CreateHat(client, 704, 1); //The Bolgan Family Crest
				}
				case 70:
				{
					CreateHat(client, 704, 6); //The Bolgan Family Crest
				}
				case 71:
				{
					CreateHat(client, 717, 1); //Mapmaker's Medallion
				}
				case 72:
				{
					CreateHat(client, 733, 6); //Pet Robro
				}
				case 73:
				{
					CreateHat(client, 733, 11); //Pet Robro
				}
				case 74:
				{
					CreateHat(client, 864, 1); //The Friends Forever Companion Square Badge
				}
				case 75:
				{
					CreateHat(client, 865, 1); //The Triple A Badge
				}
				case 76:
				{
					CreateHat(client, 953, 6); //The Saxxy Clapper Badge
				}
				case 77:
				{
					CreateHat(client, 995, 11); //Pet Reindoonicorn
				}
				case 78:
				{
					CreateHat(client, 1011, 6); //Tux
				}
				case 79:
				{
					CreateHat(client, 1126, 6); //Duck Badge
				}
				case 80:
				{
					CreateHat(client, 5075, 6); //Something Special For Someone Special
				}
				case 81:
				{
					CreateHat(client, 30000, 9); //The Electric Badge-alo
				}
				case 82:
				{
					CreateHat(client, 30550, 6); //Snow Sleeves
				}
				case 83:
				{
					CreateHat(client, 30550, 11); //Snow Sleeves
				}
				case 84:
				{
					CreateHat(client, 30551, 6); //Flashdance Footies
				}
				case 85:
				{
					CreateHat(client, 30551, 11); //Flashdance Footies
				}
				case 86:
				{
					CreateHat(client, 30559, 9); //End of the Line Community Update Medal
				}
				case 87:
				{
					CreateHat(client, 30669, 15); //Space Hamster Hammy
				}
				case 88:
				{
					CreateHat(client, 30669, 11); //Space Hamster Hammy
				}
				case 89:
				{
					CreateHat(client, 30670, 9); //Invasion Community Update Medal
				}
				case 90:
				{
					CreateHat(client, 927, 6); //The Boo Balloon
				}
				case 91:
				{
					CreateHat(client, 927, 13); //The Boo Balloon
				}
				case 92:
				{
					CreateHat(client, 929, 6); //The Unknown Monkeynaut
				}
				case 93:
				{
					CreateHat(client, 929, 13); //The Unknown Monkeynaut
				}
				case 94:
				{
					CreateHat(client, 934, 6); //The Dead Little Buddy
				}
				case 95:
				{
					CreateHat(client, 934, 13); //The Dead Little Buddy
				}
				case 96:
				{
					CreateHat(client, 30198, 6); //The Pocket Horsemann
				}
				case 97:
				{
					CreateHat(client, 30198, 13); //The Pocket Horsemann
				}
				case 98:
				{
					CreateHat(client, 30206, 6); //The Accursed Apparition
				}
				case 99:
				{
					CreateHat(client, 30206, 13); //The Accursed Apparition
				}
				case 100:
				{
					CreateHat(client, 30234, 6); //The Sackcloth Spook
				}
				case 101:
				{
					CreateHat(client, 30234, 13); //The Sackcloth Spook
				}
				case 102:
				{
					CreateHat(client, 30252, 6); //Guano
				}
				case 103:
				{
					CreateHat(client, 30252, 13); //Guano
				}
				case 104:
				{
					CreateHat(client, 30254, 6); //Unidentified Following Object
				}
				case 105:
				{
					CreateHat(client, 30254, 13); //Unidentified Following Object
				}
				case 106:
				{
					CreateHat(client, 30255, 6); //The Beacon From Beyond
				}
				case 107:
				{
					CreateHat(client, 30255, 13); //The Beacon From Beyond
				}
				case 108:
				{
					CreateHat(client, 30289, 6); //Quoth
				}
				case 109:
				{
					CreateHat(client, 30289, 13); //Quoth
				}
				case 110:
				{
					CreateHat(client, 30302, 6); //The Cryptic Keepsake
				}
				case 111:
				{
					CreateHat(client, 30302, 13); //The Cryptic Keepsake
				}
				case 112:
				{
					CreateHat(client, 30497, 6); //Ghost of Spies Checked Past
				}
				case 113:
				{
					CreateHat(client, 30497, 13); //Ghost of Spies Checked Past
				}
				case 114:
				{
					CreateHat(client, 30497, 11); //Ghost of Spies Checked Past
				}
				case 115:
				{
					CreateHat(client, 30498, 6); //The Hooded Haunter
				}
				case 116:
				{
					CreateHat(client, 30498, 13); //The Hooded Haunter
				}
				case 117:
				{
					CreateHat(client, 30498, 11); //The Hooded Haunter
				}
				case 118:
				{
					CreateHat(client, 30536, 6); //Cursed Cruise
				}
				case 119:
				{
					CreateHat(client, 30536, 13); //Cursed Cruise
				}
				case 120:
				{
					CreateHat(client, 30536, 11); //Cursed Cruise
				}
				case 121:
				{
					CreateHat(client, 620, 6); //Couvre Corner
				}
				case 122:
				{
					CreateHat(client, 620, 11); //Couvre Corner
				}
				case 123:
				{
					CreateHat(client, 621, 6); //The Surgeon's Stethoscope
				}
				case 124:
				{
					CreateHat(client, 621, 11); //The Surgeon's Stethoscope
				}
				case 125:
				{
					CreateHat(client, 639, 6); //Dr. Whoa
				}
				case 126:
				{
					CreateHat(client, 639, 11); //Dr. Whoa
				}
				case 127:
				{
					CreateHat(client, 754, 1); //The Scrap Pack
				}
				case 128:
				{
					CreateHat(client, 754, 6); //The Scrap Pack
				}
				case 129:
				{
					CreateHat(client, 769, 1); //The Quadwranlger
				}
				case 130:
				{
					CreateHat(client, 769, 6); //The Quadwranlger
				}
				case 131:
				{
					CreateHat(client, 770, 6); //The Surgeon's Side Satchel
				}
				case 132:
				{
					CreateHat(client, 770, 11); //The Surgeon's Side Satchel
				}
				case 133:
				{
					CreateHat(client, 828, 6); //Archimedes
				}
				case 134:
				{
					CreateHat(client, 828, 11); //Archimedes
				}
				case 135:
				{
					CreateHat(client, 828, 1); //Archimedes
				}
				case 136:
				{
					CreateHat(client, 843, 6); //The Medic Mech-bag
				}
				case 137:
				{
					CreateHat(client, 878, 6); //The Foppish Physician
				}
				case 138:
				{
					CreateHat(client, 878, 11); //The Foppish Physician
				}
				case 139:
				{
					CreateHat(client, 878, 1); //The Foppish Physician
				}
				case 140:
				{
					CreateHat(client, 978, 6); //Der Wintermantel
				}
				case 141:
				{
					CreateHat(client, 978, 11); //Der Wintermantel
				}
				case 142:
				{
					CreateHat(client, 982, 6); //Doc's Holiday
				}
				case 143:
				{
					CreateHat(client, 982, 11); //Doc's Holiday
				}
				case 144:
				{
					CreateHat(client, 30048, 6); //Mecha-Medes
				}
				case 145:
				{
					CreateHat(client, 30048, 11); //Mecha-Medes
				}
				case 146:
				{
					CreateHat(client, 30096, 6); //Das Feelinbeterbager
				}
				case 147:
				{
					CreateHat(client, 30096, 11); //Das Feelinbeterbager
				}
				case 148:
				{
					CreateHat(client, 30098, 6); //Das Metalmeatencasen
				}
				case 149:
				{
					CreateHat(client, 30098, 11); //Das Metalmeatencasen
				}
				case 150:
				{
					CreateHat(client, 30137, 6); //Das Fantzipantzen
				}
				case 151:
				{
					CreateHat(client, 30137, 11); //Das Fantzipantzen
				}
				case 152:
				{
					CreateHat(client, 30171, 6); //The Medical Mystery
				}
				case 153:
				{
					CreateHat(client, 30171, 11); //The Medical Mystery
				}
				case 154:
				{
					CreateHat(client, 30190, 6); //The Ward
				}
				case 155:
				{
					CreateHat(client, 30190, 11); //The Ward
				}
				case 156:
				{
					CreateHat(client, 30350, 6); //The Dough Puncher
				}
				case 157:
				{
					CreateHat(client, 30350, 11); //The Dough Puncher
				}
				case 158:
				{
					CreateHat(client, 30356, 6); //The Heat of Winter
				}
				case 159:
				{
					CreateHat(client, 30356, 11); //The Heat of Winter
				}
				case 160:
				{
					CreateHat(client, 30361, 6); //The Colonel's Coat
				}
				case 161:
				{
					CreateHat(client, 30361, 11); //The Colonel's Coat
				}
				case 162:
				{
					CreateHat(client, 30365, 6); //The Smock Surgeon
				}
				case 163:
				{
					CreateHat(client, 30365, 11); //The Smock Surgeon
				}
				case 164:
				{
					CreateHat(client, 30379, 6); //The Gaiter Guards
				}
				case 165:
				{
					CreateHat(client, 30379, 11); //The Gaiter Guards
				}
				case 166:
				{
					CreateHat(client, 30415, 6); //The Medicine Manpurse
				}
				case 167:
				{
					CreateHat(client, 30415, 11); //The Medicine Manpurse
				}
				case 168:
				{
					CreateHat(client, 30419, 6); //The Chronoscarf
				}
				case 169:
				{
					CreateHat(client, 30419, 11); //The Chronoscarf
				}
				case 170:
				{
					CreateHat(client, 30483, 6); //Pocket Heavy
				}
				case 171:
				{
					CreateHat(client, 30483, 11); //Pocket Heavy
				}
				case 172:
				{
					CreateHat(client, 30626, 15); //The Vascular Vestment
				}
				case 173:
				{
					CreateHat(client, 30626, 11); //The Vascular Vestment
				}
				case 174:
				{
					CreateHat(client, 554, 6); //Emerald Jarate
				}
				case 175:
				{
					CreateHat(client, 554, 13); //Emerald Jarate
				}
				case 176:
				{
					CreateHat(client, 30229, 6); //The Lo-Grav Loafers
				}
				case 177:
				{
					CreateHat(client, 30229, 13); //The Lo-Grav Loafers
				}
				case 178:
				{
					CreateHat(client, 30230, 6); //The Surgeon's Space Suit
				}
				case 179:
				{
					CreateHat(client, 30230, 13); //The Surgeon's Space Suit
				}
				case 180:
				{
					CreateHat(client, 30263, 6); //The Vicar's Vestments
				}
				case 181:
				{
					CreateHat(client, 30263, 13); //The Vicar's Vestments
				}
				case 182:
				{
					CreateHat(client, 30279, 6); //Archimedes the Undying
				}
				case 183:
				{
					CreateHat(client, 30279, 13); //Archimedes the Undying
				}
				case 184:
				{
					CreateHat(client, 30299, 6); //Ramses' Regalia
				}
				case 185:
				{
					CreateHat(client, 30299, 13); //Ramses' Regalia
				}
				case 186:
				{
					CreateHat(client, 30486, 6); //Herzensbrecher
				}
				case 187:
				{
					CreateHat(client, 30486, 13); //Herzensbrecher
				}
				case 188:
				{
					CreateHat(client, 30486, 11); //Herzensbrecher
				}
				case 189:
				{
					CreateHat(client, 30488, 6); //Kriegsmaschine-9000
				}
				case 190:
				{
					CreateHat(client, 30488, 13); //Kriegsmaschine-9000
				}
				case 191:
				{
					CreateHat(client, 30488, 11); //Kriegsmaschine-9000
				}
				case 192:
				{
					CreateHat(client, 30490, 6); //Vampiric Vesture
				}
				case 193:
				{
					CreateHat(client, 30490, 13); //Vampiric Vesture
				}
				case 194:
				{
					CreateHat(client, 30490, 11); //Vampiric Vesture
				}
				case 195:
				{
					CreateHat(client, 30515, 6); //Wings of Purity
				}
				case 196:
				{
					CreateHat(client, 30515, 13); //Wings of Purity
				}
				case 197:
				{
					CreateHat(client, 30515, 11); //Wings of Purity
				}
				case 198:
				{
					CreateHat(client, 936, 6); //The Exorcizor
				}
				case 199:
				{
					CreateHat(client, 936, 11); //The Exorcizor
				}
				case 200:
				{
					CreateHat(client, 936, 13); //The Exorcizor
				}
			}
		}
		case TFClass_Heavy:
		{
			int rnd3 = GetRandomUInt(0,195);
			switch (rnd3)
			{
				case 1:
				{
					CreateHat(client, 868, 6, 20); //Heroic Companion Badge
				}
				case 2:
				{
					CreateHat(client, 583, 6, 20); //Bombinomicon
				}
				case 3:
				{
					CreateHat(client, 586, 6); //Mark of the Saint
				}
				case 4:
				{
					CreateHat(client, 625, 6, 20); //Clan Pride
				}
				case 5:
				{
					CreateHat(client, 619, 6, 20); //Flair!
				}
				case 6:
				{
					CreateHat(client, 1025, 6); //The Fortune Hunter
				}
				case 7:
				{
					CreateHat(client, 623, 6, 20); //Photo Badge
				}
				case 8:
				{
					CreateHat(client, 738, 6); //Pet Balloonicorn
				}
				case 9:
				{
					CreateHat(client, 955, 6); //The Tuxxy
				}
				case 10:
				{
					CreateHat(client, 995, 6, 20); //Pet Reindoonicorn
				}
				case 11:
				{
					CreateHat(client, 987, 6); //The Merc's Muffler
				}
				case 12:
				{
					CreateHat(client, 1096, 6); //The Baronial Badge
				}
				case 13:
				{
					CreateHat(client, 30607, 6); //The Pocket Raiders
				}
				case 14:
				{
					CreateHat(client, 30068, 6); //The Breakneck Baggies
				}
				case 15:
				{
					CreateHat(client, 869, 6); //The Rump-o-Lantern
				}
				case 16:
				{
					CreateHat(client, 30309, 6); //Dead of Night
				}
				case 17:
				{
					CreateHat(client, 1024, 6); //Crofts Crest
				}
				case 18:
				{
					CreateHat(client, 992, 6); //Smissmas Wreath
				}
				case 19:
				{
					CreateHat(client, 956, 6); //Faerie Solitaire Pin
				}
				case 20:
				{
					CreateHat(client, 943, 6); //Hitt Mann Badge
				}
				case 21:
				{
					CreateHat(client, 873, 6, 20); //Whale Bone Charm
				}
				case 22:
				{
					CreateHat(client, 855, 6); //Vigilant Pin
				}
				case 23:
				{
					CreateHat(client, 818, 6); //Awesomenauts Badge
				}
				case 24:
				{
					CreateHat(client, 767, 6); //Atomic Accolade
				}
				case 25:
				{
					CreateHat(client, 718, 6); //Merc Medal
				}
				case 26:
				{
					CreateHat(client, 868, 1, 20); //Heroic Companion Badge
				}
				case 27:
				{
					CreateHat(client, 586, 1); //Mark of the Saint
				}
				case 28:
				{
					CreateHat(client, 625, 11, 20); //Clan Pride
				}
				case 29:
				{
					CreateHat(client, 619, 11, 20); //Flair!
				}
				case 30:
				{
					CreateHat(client, 1025, 1); //The Fortune Hunter
				}
				case 31:
				{
					CreateHat(client, 623, 11, 20); //Photo Badge
				}
				case 32:
				{
					CreateHat(client, 738, 1); //Pet Balloonicorn
				}
				case 33:
				{
					CreateHat(client, 738, 11); //Pet Balloonicorn
				}
				case 34:
				{
					CreateHat(client, 987, 11); //The Merc's Muffler
				}
				case 35:
				{
					CreateHat(client, 1096, 1); //The Baronial Badge
				}
				case 36:
				{
					CreateHat(client, 30068, 11); //The Breakneck Baggies
				}
				case 37:
				{
					CreateHat(client, 869, 11); //The Rump-o-Lantern
				}
				case 38:
				{
					CreateHat(client, 869, 13); //The Rump-o-Lantern
				}
				case 39:
				{
					CreateHat(client, 30309, 11); //Dead of Night
				}
				case 40:
				{
					CreateHat(client, 1024, 1); //Crofts Crest
				}
				case 41:
				{
					CreateHat(client, 956, 1); //Faerie Solitaire Pin
				}
				case 42:
				{
					CreateHat(client, 943, 1); //Hitt Mann Badge
				}
				case 43:
				{
					CreateHat(client, 873, 1, 20); //Whale Bone Charm
				}
				case 44:
				{
					CreateHat(client, 855, 1); //Vigilant Pin
				}
				case 45:
				{
					CreateHat(client, 818, 1); //Awesomenauts Badge
				}
				case 46:
				{
					CreateHat(client, 767, 1); //Atomic Accolade
				}
				case 47:
				{
					CreateHat(client, 718, 1); //Merc Medal
				}
				case 48:
				{
					CreateHat(client, 164, 6); //Grizzled Veteran
				}
				case 49:
				{
					CreateHat(client, 165, 6); //Soldier of Fortune
				}
				case 50:
				{
					CreateHat(client, 166, 6); //Mercenary
				}
				case 51:
				{
					CreateHat(client, 170, 6); //Primeval Warrior
				}
				case 52:
				{
					CreateHat(client, 242, 6); //Duel Medal Bronze
				}
				case 53:
				{
					CreateHat(client, 243, 6); //Duel Medal Silver
				}
				case 54:
				{
					CreateHat(client, 244, 6); //Duel Medal Gold
				}
				case 55:
				{
					CreateHat(client, 245, 6); //Duel Medal Plat
				}
				case 56:
				{
					CreateHat(client, 262, 6); //Polycount Pin
				}
				case 57:
				{
					CreateHat(client, 296, 6); //License to Maim
				}
				case 58:
				{
					CreateHat(client, 299, 1); //Companion Cube Pin
				}
				case 59:
				{
					CreateHat(client, 299, 3); //Companion Cube Pin
				}
				case 60:
				{
					CreateHat(client, 422, 3); //Resurrection Associate Pin
				}
				case 61:
				{
					CreateHat(client, 432, 6); //SpaceChem Pin
				}
				case 62:
				{
					CreateHat(client, 432, 6); //Dr. Grordbort's Crest
				}
				case 63:
				{
					CreateHat(client, 541, 6); //Merc's Pride Scarf
				}
				case 64:
				{
					CreateHat(client, 541, 1); //Merc's Pride Scarf
				}
				case 65:
				{
					CreateHat(client, 541, 11); //Merc's Pride Scarf
				}
				case 66:
				{
					CreateHat(client, 592, 6); //Dr. Grordbort's Copper Crest
				}
				case 67:
				{
					CreateHat(client, 636, 6); //Dr. Grordbort's Silver Crest
				}
				case 68:
				{
					CreateHat(client, 655, 11); //The Spirit of Giving
				}
				case 69:
				{
					CreateHat(client, 704, 1); //The Bolgan Family Crest
				}
				case 70:
				{
					CreateHat(client, 704, 6); //The Bolgan Family Crest
				}
				case 71:
				{
					CreateHat(client, 717, 1); //Mapmaker's Medallion
				}
				case 72:
				{
					CreateHat(client, 733, 6); //Pet Robro
				}
				case 73:
				{
					CreateHat(client, 733, 11); //Pet Robro
				}
				case 74:
				{
					CreateHat(client, 864, 1); //The Friends Forever Companion Square Badge
				}
				case 75:
				{
					CreateHat(client, 865, 1); //The Triple A Badge
				}
				case 76:
				{
					CreateHat(client, 953, 6); //The Saxxy Clapper Badge
				}
				case 77:
				{
					CreateHat(client, 995, 11); //Pet Reindoonicorn
				}
				case 78:
				{
					CreateHat(client, 1011, 6); //Tux
				}
				case 79:
				{
					CreateHat(client, 1126, 6); //Duck Badge
				}
				case 80:
				{
					CreateHat(client, 5075, 6); //Something Special For Someone Special
				}
				case 81:
				{
					CreateHat(client, 30000, 9); //The Electric Badge-alo
				}
				case 82:
				{
					CreateHat(client, 30550, 6); //Snow Sleeves
				}
				case 83:
				{
					CreateHat(client, 30550, 11); //Snow Sleeves
				}
				case 84:
				{
					CreateHat(client, 30551, 6); //Flashdance Footies
				}
				case 85:
				{
					CreateHat(client, 30551, 11); //Flashdance Footies
				}
				case 86:
				{
					CreateHat(client, 30559, 9); //End of the Line Community Update Medal
				}
				case 87:
				{
					CreateHat(client, 30669, 15); //Space Hamster Hammy
				}
				case 88:
				{
					CreateHat(client, 30669, 11); //Space Hamster Hammy
				}
				case 89:
				{
					CreateHat(client, 30670, 9); //Invasion Community Update Medal
				}
				case 90:
				{
					CreateHat(client, 927, 6); //The Boo Balloon
				}
				case 91:
				{
					CreateHat(client, 927, 13); //The Boo Balloon
				}
				case 92:
				{
					CreateHat(client, 929, 6); //The Unknown Monkeynaut
				}
				case 93:
				{
					CreateHat(client, 929, 13); //The Unknown Monkeynaut
				}
				case 94:
				{
					CreateHat(client, 934, 6); //The Dead Little Buddy
				}
				case 95:
				{
					CreateHat(client, 934, 13); //The Dead Little Buddy
				}
				case 96:
				{
					CreateHat(client, 30198, 6); //The Pocket Horsemann
				}
				case 97:
				{
					CreateHat(client, 30198, 13); //The Pocket Horsemann
				}
				case 98:
				{
					CreateHat(client, 30206, 6); //The Accursed Apparition
				}
				case 99:
				{
					CreateHat(client, 30206, 13); //The Accursed Apparition
				}
				case 100:
				{
					CreateHat(client, 30234, 6); //The Sackcloth Spook
				}
				case 101:
				{
					CreateHat(client, 30234, 13); //The Sackcloth Spook
				}
				case 102:
				{
					CreateHat(client, 30252, 6); //Guano
				}
				case 103:
				{
					CreateHat(client, 30252, 13); //Guano
				}
				case 104:
				{
					CreateHat(client, 30254, 6); //Unidentified Following Object
				}
				case 105:
				{
					CreateHat(client, 30254, 13); //Unidentified Following Object
				}
				case 106:
				{
					CreateHat(client, 30255, 6); //The Beacon From Beyond
				}
				case 107:
				{
					CreateHat(client, 30255, 13); //The Beacon From Beyond
				}
				case 108:
				{
					CreateHat(client, 30289, 6); //Quoth
				}
				case 109:
				{
					CreateHat(client, 30289, 13); //Quoth
				}
				case 110:
				{
					CreateHat(client, 30302, 6); //The Cryptic Keepsake
				}
				case 111:
				{
					CreateHat(client, 30302, 13); //The Cryptic Keepsake
				}
				case 112:
				{
					CreateHat(client, 30497, 6); //Ghost of Spies Checked Past
				}
				case 113:
				{
					CreateHat(client, 30497, 13); //Ghost of Spies Checked Past
				}
				case 114:
				{
					CreateHat(client, 30497, 11); //Ghost of Spies Checked Past
				}
				case 115:
				{
					CreateHat(client, 30498, 6); //The Hooded Haunter
				}
				case 116:
				{
					CreateHat(client, 30498, 13); //The Hooded Haunter
				}
				case 117:
				{
					CreateHat(client, 30498, 11); //The Hooded Haunter
				}
				case 118:
				{
					CreateHat(client, 30536, 6); //Cursed Cruise
				}
				case 119:
				{
					CreateHat(client, 30536, 13); //Cursed Cruise
				}
				case 120:
				{
					CreateHat(client, 30536, 11); //Cursed Cruise
				}
				case 121:
				{
					CreateHat(client, 815, 1); //The Champ Stamp
				}
				case 122:
				{
					CreateHat(client, 815, 6); //The Champ Stamp
				}
				case 123:
				{
					CreateHat(client, 815, 11); //The Champ Stamp
				}
				case 124:
				{
					CreateHat(client, 814, 1); //The Triad Trinket
				}
				case 125:
				{
					CreateHat(client, 814, 6); //The Triad Trinket
				}
				case 126:
				{
					CreateHat(client, 814, 11); //The Triad Trinket
				}		
				case 127:
				{
					CreateHat(client, 392, 6); //Pocket Medic
				}		
				case 128:
				{
					CreateHat(client, 524, 6); //The Purity Fist
				}		
				case 129:
				{
					CreateHat(client, 524, 1); //The Purity Fist
				}		
				case 130:
				{
					CreateHat(client, 643, 6); //The Sandvich Safe
				}		
				case 131:
				{
					CreateHat(client, 643, 11); //The Sandvich Safe
				}		
				case 132:
				{
					CreateHat(client, 757, 6); //The Toss-Proof Towel
				}		
				case 133:
				{
					CreateHat(client, 757, 11); //The Toss-Proof Towel
				}		
				case 134:
				{
					CreateHat(client, 777, 6); //The Apparatchik's Apparel
				}		
				case 135:
				{
					CreateHat(client, 777, 11); //The Apparatchik's Apparel
				}		
				case 136:
				{
					CreateHat(client, 946, 6); //The Siberian Sophisticate
				}		
				case 138:
				{
					CreateHat(client, 946, 1); //The Siberian Sophisticate
				}		
				case 139:
				{
					CreateHat(client, 985, 6); //Heavy's Hockey Hair
				}		
				case 140:
				{
					CreateHat(client, 985, 11); //Heavy's Hockey Hair
				}		
				case 141:
				{
					CreateHat(client, 990, 6); //Aqua Flops
				}		
				case 142:
				{
					CreateHat(client, 991, 6); //The Hunger Force
				}		
				case 143:
				{
					CreateHat(client, 1028, 6); //The Samson Skewer
				}		
				case 144:
				{
					CreateHat(client, 1097, 6); //The Little Bear
				}		
				case 145:
				{
					CreateHat(client, 1097, 1); //The Little Bear
				}		
				case 146:
				{
					CreateHat(client, 1097, 11); //The Little Bear
				}		
				case 147:
				{
					CreateHat(client, 30012, 6); //The Titanium Towel
				}		
				case 148:
				{
					CreateHat(client, 30012, 11); //The Titanium Towel
				}		
				case 149:
				{
					CreateHat(client, 30074, 6); //The Tyrutleneck
				}		
				case 150:
				{
					CreateHat(client, 30074, 11); //The Tyrutleneck
				}		
				case 151:
				{
					CreateHat(client, 30079, 6); //The Red Army Robin
				}		
				case 152:
				{
					CreateHat(client, 30079, 11); //The Red Army Robin
				}		
				case 153:
				{
					CreateHat(client, 30080, 6); //The Heavy-Weight Champ
				}		
				case 154:
				{
					CreateHat(client, 30080, 11); //The Heavy-Weight Champ
				}		
				case 155:
				{
					CreateHat(client, 30108, 6); //The Borscht Belt
				}		
				case 156:
				{
					CreateHat(client, 30108, 11); //The Borscht Belt
				}		
				case 157:
				{
					CreateHat(client, 30138, 6); //The Bolshevik Biker
				}		
				case 158:
				{
					CreateHat(client, 30138, 11); //The Bolshevik Biker
				}		
				case 159:
				{
					CreateHat(client, 30178, 6); //Weight Room Warmer
				}		
				case 160:
				{
					CreateHat(client, 30178, 11); //Weight Room Warmer
				}		
				case 161:
				{
					CreateHat(client, 30319, 6); //The Mann of the House
				}		
				case 162:
				{
					CreateHat(client, 30319, 11); //The Mann of the House
				}		
				case 163:
				{
					CreateHat(client, 30342, 6); //The Heavy Lifter
				}		
				case 164:
				{
					CreateHat(client, 30342, 11); //The Heavy Lifter
				}		
				case 165:
				{
					CreateHat(client, 30343, 6); //Gone Commando
				}		
				case 166:
				{
					CreateHat(client, 30343, 11); //Gone Commando
				}		
				case 167:
				{
					CreateHat(client, 30354, 6); //The Rat Stompers
				}		
				case 168:
				{
					CreateHat(client, 30354, 11); //The Rat Stompers
				}		
				case 169:
				{
					CreateHat(client, 30364, 6); //The Warmth Preserver
				}		
				case 170:
				{
					CreateHat(client, 30364, 11); //The Warmth Preserver
				}		
				case 171:
				{
					CreateHat(client, 30372, 6); //Combat Slacks
				}		
				case 172:
				{
					CreateHat(client, 30372, 11); //Combat Slacks
				}		
				case 173:
				{
					CreateHat(client, 30556, 6); //Sleeveless in Siberia
				}		
				case 174:
				{
					CreateHat(client, 30556, 11); //Sleeveless in Siberia
				}		
				case 175:
				{
					CreateHat(client, 30557, 6); //Hunter Heavy
				}		
				case 176:
				{
					CreateHat(client, 30557, 11); //Hunter Heavy
				}		
				case 177:
				{
					CreateHat(client, 30563, 6); //Jungle Booty
				}		
				case 178:
				{
					CreateHat(client, 30563, 11); //Jungle Booty
				}		
				case 179:
				{
					CreateHat(client, 30633, 15); //Comissar's Coat
				}		
				case 180:
				{
					CreateHat(client, 30633, 11); //Comissar's Coat
				}		
				case 181:
				{
					CreateHat(client, 562, 6); //Soviet Stitch-Up
				}		
				case 182:
				{
					CreateHat(client, 562, 13); //Soviet Stitch-Up
				}		
				case 183:
				{
					CreateHat(client, 563, 6); //Steel-Toed Stompers
				}		
				case 184:
				{
					CreateHat(client, 563, 13); //Steel-Toed Stompers
				}		
				case 185:
				{
					CreateHat(client, 930, 6); //The Grand Duchess Tutu
				}		
				case 186:
				{
					CreateHat(client, 930, 13); //The Grand Duchess Tutu
				}		
				case 187:
				{
					CreateHat(client, 931, 6); //The Grand Duchess Fairy Wings
				}		
				case 188:
				{
					CreateHat(client, 931, 13); //The Grand Duchess Fairy Wings
				}		
				case 189:
				{
					CreateHat(client, 30199, 6); //The Last Bite
				}		
				case 190:
				{
					CreateHat(client, 30199, 13); //The Last Bite
				}		
				case 191:
				{
					CreateHat(client, 30531, 6); //Bone-Cut Belt
				}		
				case 192:
				{
					CreateHat(client, 30531, 13); //Bone-Cut Belt
				}		
				case 193:
				{
					CreateHat(client, 30534, 6); //Immobile Suit
				}		
				case 194:
				{
					CreateHat(client, 30534, 13); //Immobile Suit
				}		
				case 195:
				{
					CreateHat(client, 30534, 11); //Immobile Suit
				}
			}
		}
		case TFClass_Pyro:
		{
			int rnd3 = GetRandomUInt(0,234);
			switch (rnd3)
			{
				case 1:
				{
					CreateHat(client, 868, 6, 20); //Heroic Companion Badge
				}
				case 2:
				{
					CreateHat(client, 583, 6, 20); //Bombinomicon
				}
				case 3:
				{
					CreateHat(client, 586, 6); //Mark of the Saint
				}
				case 4:
				{
					CreateHat(client, 625, 6, 20); //Clan Pride
				}
				case 5:
				{
					CreateHat(client, 619, 6, 20); //Flair!
				}
				case 6:
				{
					CreateHat(client, 1025, 6); //The Fortune Hunter
				}
				case 7:
				{
					CreateHat(client, 623, 6, 20); //Photo Badge
				}
				case 8:
				{
					CreateHat(client, 738, 6); //Pet Balloonicorn
				}
				case 9:
				{
					CreateHat(client, 955, 6); //The Tuxxy
				}
				case 10:
				{
					CreateHat(client, 995, 6, 20); //Pet Reindoonicorn
				}
				case 11:
				{
					CreateHat(client, 987, 6); //The Merc's Muffler
				}
				case 12:
				{
					CreateHat(client, 1096, 6); //The Baronial Badge
				}
				case 13:
				{
					CreateHat(client, 30607, 6); //The Pocket Raiders
				}
				case 14:
				{
					CreateHat(client, 30068, 6); //The Breakneck Baggies
				}
				case 15:
				{
					CreateHat(client, 869, 6); //The Rump-o-Lantern
				}
				case 16:
				{
					CreateHat(client, 30309, 6); //Dead of Night
				}
				case 17:
				{
					CreateHat(client, 1024, 6); //Crofts Crest
				}
				case 18:
				{
					CreateHat(client, 992, 6); //Smissmas Wreath
				}
				case 19:
				{
					CreateHat(client, 956, 6); //Faerie Solitaire Pin
				}
				case 20:
				{
					CreateHat(client, 943, 6); //Hitt Mann Badge
				}
				case 21:
				{
					CreateHat(client, 873, 6, 20); //Whale Bone Charm
				}
				case 22:
				{
					CreateHat(client, 855, 6); //Vigilant Pin
				}
				case 23:
				{
					CreateHat(client, 818, 6); //Awesomenauts Badge
				}
				case 24:
				{
					CreateHat(client, 767, 6); //Atomic Accolade
				}
				case 25:
				{
					CreateHat(client, 718, 6); //Merc Medal
				}
				case 26:
				{
					CreateHat(client, 868, 1, 20); //Heroic Companion Badge
				}
				case 27:
				{
					CreateHat(client, 586, 1); //Mark of the Saint
				}
				case 28:
				{
					CreateHat(client, 625, 11, 20); //Clan Pride
				}
				case 29:
				{
					CreateHat(client, 619, 11, 20); //Flair!
				}
				case 30:
				{
					CreateHat(client, 1025, 1); //The Fortune Hunter
				}
				case 31:
				{
					CreateHat(client, 623, 11, 20); //Photo Badge
				}
				case 32:
				{
					CreateHat(client, 738, 1); //Pet Balloonicorn
				}
				case 33:
				{
					CreateHat(client, 738, 11); //Pet Balloonicorn
				}
				case 34:
				{
					CreateHat(client, 987, 11); //The Merc's Muffler
				}
				case 35:
				{
					CreateHat(client, 1096, 1); //The Baronial Badge
				}
				case 36:
				{
					CreateHat(client, 30068, 11); //The Breakneck Baggies
				}
				case 37:
				{
					CreateHat(client, 869, 11); //The Rump-o-Lantern
				}
				case 38:
				{
					CreateHat(client, 869, 13); //The Rump-o-Lantern
				}
				case 39:
				{
					CreateHat(client, 30309, 11); //Dead of Night
				}
				case 40:
				{
					CreateHat(client, 1024, 1); //Crofts Crest
				}
				case 41:
				{
					CreateHat(client, 956, 1); //Faerie Solitaire Pin
				}
				case 42:
				{
					CreateHat(client, 943, 1); //Hitt Mann Badge
				}
				case 43:
				{
					CreateHat(client, 873, 1, 20); //Whale Bone Charm
				}
				case 44:
				{
					CreateHat(client, 855, 1); //Vigilant Pin
				}
				case 45:
				{
					CreateHat(client, 818, 1); //Awesomenauts Badge
				}
				case 46:
				{
					CreateHat(client, 767, 1); //Atomic Accolade
				}
				case 47:
				{
					CreateHat(client, 718, 1); //Merc Medal
				}
				case 48:
				{
					CreateHat(client, 164, 6); //Grizzled Veteran
				}
				case 49:
				{
					CreateHat(client, 165, 6); //Soldier of Fortune
				}
				case 50:
				{
					CreateHat(client, 166, 6); //Mercenary
				}
				case 51:
				{
					CreateHat(client, 170, 6); //Primeval Warrior
				}
				case 52:
				{
					CreateHat(client, 242, 6); //Duel Medal Bronze
				}
				case 53:
				{
					CreateHat(client, 243, 6); //Duel Medal Silver
				}
				case 54:
				{
					CreateHat(client, 244, 6); //Duel Medal Gold
				}
				case 55:
				{
					CreateHat(client, 245, 6); //Duel Medal Plat
				}
				case 56:
				{
					CreateHat(client, 262, 6); //Polycount Pin
				}
				case 57:
				{
					CreateHat(client, 296, 6); //License to Maim
				}
				case 58:
				{
					CreateHat(client, 299, 1); //Companion Cube Pin
				}
				case 59:
				{
					CreateHat(client, 299, 3); //Companion Cube Pin
				}
				case 60:
				{
					CreateHat(client, 422, 3); //Resurrection Associate Pin
				}
				case 61:
				{
					CreateHat(client, 432, 6); //SpaceChem Pin
				}
				case 62:
				{
					CreateHat(client, 432, 6); //Dr. Grordbort's Crest
				}
				case 63:
				{
					CreateHat(client, 541, 6); //Merc's Pride Scarf
				}
				case 64:
				{
					CreateHat(client, 541, 1); //Merc's Pride Scarf
				}
				case 65:
				{
					CreateHat(client, 541, 11); //Merc's Pride Scarf
				}
				case 66:
				{
					CreateHat(client, 592, 6); //Dr. Grordbort's Copper Crest
				}
				case 67:
				{
					CreateHat(client, 636, 6); //Dr. Grordbort's Silver Crest
				}
				case 68:
				{
					CreateHat(client, 655, 11); //The Spirit of Giving
				}
				case 69:
				{
					CreateHat(client, 704, 1); //The Bolgan Family Crest
				}
				case 70:
				{
					CreateHat(client, 704, 6); //The Bolgan Family Crest
				}
				case 71:
				{
					CreateHat(client, 717, 1); //Mapmaker's Medallion
				}
				case 72:
				{
					CreateHat(client, 733, 6); //Pet Robro
				}
				case 73:
				{
					CreateHat(client, 733, 11); //Pet Robro
				}
				case 74:
				{
					CreateHat(client, 864, 1); //The Friends Forever Companion Square Badge
				}
				case 75:
				{
					CreateHat(client, 865, 1); //The Triple A Badge
				}
				case 76:
				{
					CreateHat(client, 953, 6); //The Saxxy Clapper Badge
				}
				case 77:
				{
					CreateHat(client, 995, 11); //Pet Reindoonicorn
				}
				case 78:
				{
					CreateHat(client, 1011, 6); //Tux
				}
				case 79:
				{
					CreateHat(client, 1126, 6); //Duck Badge
				}
				case 80:
				{
					CreateHat(client, 5075, 6); //Something Special For Someone Special
				}
				case 81:
				{
					CreateHat(client, 30000, 9); //The Electric Badge-alo
				}
				case 82:
				{
					CreateHat(client, 30550, 6); //Snow Sleeves
				}
				case 83:
				{
					CreateHat(client, 30550, 11); //Snow Sleeves
				}
				case 84:
				{
					CreateHat(client, 30551, 6); //Flashdance Footies
				}
				case 85:
				{
					CreateHat(client, 30551, 11); //Flashdance Footies
				}
				case 86:
				{
					CreateHat(client, 30559, 9); //End of the Line Community Update Medal
				}
				case 87:
				{
					CreateHat(client, 30669, 15); //Space Hamster Hammy
				}
				case 88:
				{
					CreateHat(client, 30669, 11); //Space Hamster Hammy
				}
				case 89:
				{
					CreateHat(client, 30670, 9); //Invasion Community Update Medal
				}
				case 90:
				{
					CreateHat(client, 927, 6); //The Boo Balloon
				}
				case 91:
				{
					CreateHat(client, 927, 13); //The Boo Balloon
				}
				case 92:
				{
					CreateHat(client, 929, 6); //The Unknown Monkeynaut
				}
				case 93:
				{
					CreateHat(client, 929, 13); //The Unknown Monkeynaut
				}
				case 94:
				{
					CreateHat(client, 934, 6); //The Dead Little Buddy
				}
				case 95:
				{
					CreateHat(client, 934, 13); //The Dead Little Buddy
				}
				case 96:
				{
					CreateHat(client, 30198, 6); //The Pocket Horsemann
				}
				case 97:
				{
					CreateHat(client, 30198, 13); //The Pocket Horsemann
				}
				case 98:
				{
					CreateHat(client, 30206, 6); //The Accursed Apparition
				}
				case 99:
				{
					CreateHat(client, 30206, 13); //The Accursed Apparition
				}
				case 100:
				{
					CreateHat(client, 30234, 6); //The Sackcloth Spook
				}
				case 101:
				{
					CreateHat(client, 30234, 13); //The Sackcloth Spook
				}
				case 102:
				{
					CreateHat(client, 30252, 6); //Guano
				}
				case 103:
				{
					CreateHat(client, 30252, 13); //Guano
				}
				case 104:
				{
					CreateHat(client, 30254, 6); //Unidentified Following Object
				}
				case 105:
				{
					CreateHat(client, 30254, 13); //Unidentified Following Object
				}
				case 106:
				{
					CreateHat(client, 30255, 6); //The Beacon From Beyond
				}
				case 107:
				{
					CreateHat(client, 30255, 13); //The Beacon From Beyond
				}
				case 108:
				{
					CreateHat(client, 30289, 6); //Quoth
				}
				case 109:
				{
					CreateHat(client, 30289, 13); //Quoth
				}
				case 110:
				{
					CreateHat(client, 30302, 6); //The Cryptic Keepsake
				}
				case 111:
				{
					CreateHat(client, 30302, 13); //The Cryptic Keepsake
				}
				case 112:
				{
					CreateHat(client, 30497, 6); //Ghost of Spies Checked Past
				}
				case 113:
				{
					CreateHat(client, 30497, 13); //Ghost of Spies Checked Past
				}
				case 114:
				{
					CreateHat(client, 30497, 11); //Ghost of Spies Checked Past
				}
				case 115:
				{
					CreateHat(client, 30498, 6); //The Hooded Haunter
				}
				case 116:
				{
					CreateHat(client, 30498, 13); //The Hooded Haunter
				}
				case 117:
				{
					CreateHat(client, 30498, 11); //The Hooded Haunter
				}
				case 118:
				{
					CreateHat(client, 30536, 6); //Cursed Cruise
				}
				case 119:
				{
					CreateHat(client, 30536, 13); //Cursed Cruise
				}
				case 120:
				{
					CreateHat(client, 30536, 11); //Cursed Cruise
				}				
				case 121:
				{
					CreateHat(client, 641, 6); //The Ornament Armament
				}				
				case 122:
				{
					CreateHat(client, 641, 11); //The Ornament Armament
				}							
				case 123:
				{
					CreateHat(client, 768, 6); //The Professor's Pineapple
				}				
				case 124:
				{
					CreateHat(client, 768, 11); //The Professor's Pineapple
				}							
				case 125:
				{
					CreateHat(client, 922, 6); //The Bonedolier
				}				
				case 126:
				{
					CreateHat(client, 922, 11); //The Bonedolier
				}					
				case 127:
				{
					CreateHat(client, 922, 13); //The Bonedolier
				}			
				case 128:
				{
					CreateHat(client, 948, 1); //The Deadliest Duckling
				}				
				case 129:
				{
					CreateHat(client, 948, 6); //The Deadliest Duckling
				}				
				case 130:
				{
					CreateHat(client, 30236, 6); //Pin Pals
				}				
				case 131:
				{
					CreateHat(client, 30236, 13); //Pin Pals
				}				
				case 132:
				{
					CreateHat(client, 30242, 6); //The Candleer
				}				
				case 133:
				{
					CreateHat(client, 30242, 13); //The Candleer
				}
				case 134:
				{
					CreateHat(client, 754, 1); //The Scrap Pack
				}
				case 135:
				{
					CreateHat(client, 754, 6); //The Scrap Pack
				}
				case 136:
				{
					CreateHat(client, 336, 6); //Stockbroker's Scarf
				}
				case 137:
				{
					CreateHat(client, 336, 3); //Stockbroker's Scarf
				}
				case 138:
				{
					CreateHat(client, 336, 11); //Stockbroker's Scarf
				}
				case 139:
				{
					CreateHat(client, 596, 6); //The Moonman Backpack
				}
				case 140:
				{
					CreateHat(client, 632, 6); //The Cremator's Conscience
				}
				case 141:
				{
					CreateHat(client, 632, 11); //The Cremator's Conscience
				}
				case 142:
				{
					CreateHat(client, 651, 6); //The Jingle Belt
				}
				case 143:
				{
					CreateHat(client, 651, 11); //The Jingle Belt
				}
				case 144:
				{
					CreateHat(client, 745, 6); //The Infernal Orchestrina
				}
				case 145:
				{
					CreateHat(client, 745, 11); //The Infernal Orchestrina
				}
				case 146:
				{
					CreateHat(client, 746, 6); //The Burning Bongoes
				}
				case 147:
				{
					CreateHat(client, 746, 11); //The Burning Bongoes
				}
				case 148:
				{
					CreateHat(client, 787, 6); //The Tribal Bones
				}
				case 149:
				{
					CreateHat(client, 820, 6); //The Russian Rocketeer
				}
				case 150:
				{
					CreateHat(client, 820, 1); //The Russian Rocketeer
				}
				case 151:
				{
					CreateHat(client, 842, 6); //The Pyrobotics Pack
				}
				case 152:
				{
					CreateHat(client, 856, 6); //The Pyrotechnic Tote
				}
				case 153:
				{
					CreateHat(client, 856, 11); //The Pyrotechnic Tote
				}
				case 154:
				{
					CreateHat(client, 938, 6); //The Coffin Kit
				}
				case 155:
				{
					CreateHat(client, 938, 11); //The Coffin Kit
				}
				case 156:
				{
					CreateHat(client, 938, 13); //The Coffin Kit
				}
				case 157:
				{
					CreateHat(client, 951, 6); //Rail Spikes
				}
				case 158:
				{
					CreateHat(client, 1072, 6); //The Portable Smissmas Spirit Dispenser
				}
				case 159:
				{
					CreateHat(client, 30020, 6); //The Scrap Sack
				}
				case 160:
				{
					CreateHat(client, 30020, 11); //The Scrap Sack
				}
				case 161:
				{
					CreateHat(client, 30062, 6); //The Steel Sixpack
				}
				case 162:
				{
					CreateHat(client, 30062, 1); //The Steel Sixpack
				}
				case 163:
				{
					CreateHat(client, 30089, 6); //El Muchacho
				}
				case 164:
				{
					CreateHat(client, 30089, 11); //El Muchacho
				}
				case 165:
				{
					CreateHat(client, 30090, 6); //The Backpack Broiler
				}
				case 166:
				{
					CreateHat(client, 30090, 11); //The Backpack Broiler
				}
				case 167:
				{
					CreateHat(client, 30092, 6); //The Soot Suit
				}
				case 168:
				{
					CreateHat(client, 30092, 11); //The Soot Suit
				}
				case 169:
				{
					CreateHat(client, 30169, 6); //Trickster's Turnout Gear
				}
				case 170:
				{
					CreateHat(client, 30169, 11); //Trickster's Turnout Gear
				}
				case 171:
				{
					CreateHat(client, 30305, 6); //The Sub Zero Suit
				}
				case 172:
				{
					CreateHat(client, 30305, 11); //The Sub Zero Suit
				}
				case 173:
				{
					CreateHat(client, 30308, 6); //The Trail-Blazer
				}
				case 174:
				{
					CreateHat(client, 30308, 11); //The Trail-Blazer
				}
				case 175:
				{
					CreateHat(client, 30321, 6); //Tiny Timber
				}
				case 176:
				{
					CreateHat(client, 30321, 11); //Tiny Timber
				}
				case 178:
				{
					CreateHat(client, 30391, 6); //The Sengoku Scorcher
				}
				case 179:
				{
					CreateHat(client, 30391, 11); //The Sengoku Scorcher
				}
				case 180:
				{
					CreateHat(client, 30398, 6); //The Gas Guzzler
				}
				case 181:
				{
					CreateHat(client, 30398, 11); //The Gas Guzzler
				}
				case 182:
				{
					CreateHat(client, 30400, 6); //The Lunatic's Leathers
				}
				case 183:
				{
					CreateHat(client, 30400, 11); //The Lunatic's Leathers
				}
				case 184:
				{
					CreateHat(client, 30417, 6); //The Frymaster
				}
				case 185:
				{
					CreateHat(client, 30417, 11); //The Frymaster
				}
				case 186:
				{
					CreateHat(client, 30544, 6); //North Polar Fleece
				}
				case 187:
				{
					CreateHat(client, 30544, 11); //North Polar Fleece
				}
				case 188:
				{
					CreateHat(client, 30581, 6); //Pyromancer's Raiments
				}
				case 189:
				{
					CreateHat(client, 30581, 11); //Pyromancer's Raiments
				}
				case 190:
				{
					CreateHat(client, 30583, 6); //Torcher's Tabard
				}
				case 191:
				{
					CreateHat(client, 30583, 11); //Torcher's Tabard
				}
				case 192:
				{
					CreateHat(client, 30584, 6); //Charred Chainmail
				}
				case 193:
				{
					CreateHat(client, 30584, 11); //Charred Chainmail
				}
				case 194:
				{
					CreateHat(client, 30663, 6); //Jupiter Jetpack
				}
				case 195:
				{
					CreateHat(client, 30663, 11); //Jupiter Jetpack
				}
				case 196:
				{
					CreateHat(client, 30664, 15); //The Space Diver
				}
				case 197:
				{
					CreateHat(client, 30664, 11); //The Space Diver
				}
				case 198:
				{
					CreateHat(client, 550, 6); //Fallen Angel
				}
				case 199:
				{
					CreateHat(client, 550, 13); //Fallen Angel
				}
				case 200:
				{
					CreateHat(client, 551, 6); //Tail From the Crypt
				}
				case 201:
				{
					CreateHat(client, 551, 13); //Tail From the Crypt
				}
				case 202:
				{
					CreateHat(client, 30196, 6); //The Maniac's Manacles
				}
				case 203:
				{
					CreateHat(client, 30196, 13); //The Maniac's Manacles
				}
				case 204:
				{
					CreateHat(client, 30205, 6); //The Scorched Skirt
				}
				case 205:
				{
					CreateHat(client, 30205, 13); //The Scorched Skirt
				}
				case 206:
				{
					CreateHat(client, 30216, 6); //The External Organ
				}
				case 207:
				{
					CreateHat(client, 30216, 13); //The External Organ
				}
				case 208:
				{
					CreateHat(client, 30225, 6); //The Cauterizer's Caudal Appendage
				}
				case 209:
				{
					CreateHat(client, 30225, 13); //The Cauterizer's Caudal Appendage
				}
				case 210:
				{
					CreateHat(client, 30257, 6); //The Death Support Pack
				}
				case 211:
				{
					CreateHat(client, 30257, 13); //The Death Support Pack
				}
				case 212:
				{
					CreateHat(client, 30259, 6); //The Monster's Stompers
				}
				case 213:
				{
					CreateHat(client, 30259, 13); //The Monster's Stompers
				}
				case 214:
				{
					CreateHat(client, 30267, 6); //The Handhunter
				}
				case 215:
				{
					CreateHat(client, 30267, 13); //The Handhunter
				}
				case 216:
				{
					CreateHat(client, 30277, 6); //The Grisly Gumbo
				}
				case 217:
				{
					CreateHat(client, 30277, 13); //The Grisly Gumbo
				}
				case 218:
				{
					CreateHat(client, 30288, 6); //Carrion Companion
				}
				case 219:
				{
					CreateHat(client, 30288, 13); //Carrion Companion
				}
				case 220:
				{
					CreateHat(client, 30296, 6); //The Creature From The Heap
				}
				case 221:
				{
					CreateHat(client, 30296, 13); //The Creature From The Heap
				}
				case 222:
				{
					CreateHat(client, 30303, 6); //The Abhorrent Appendages
				}
				case 223:
				{
					CreateHat(client, 30303, 13); //The Abhorrent Appendages
				}
				case 224:
				{
					CreateHat(client, 30526, 6); //Arsonist Apparatus
				}
				case 225:
				{
					CreateHat(client, 30526, 13); //Arsonist Apparatus
				}
				case 226:
				{
					CreateHat(client, 30526, 11); //Arsonist Apparatus
				}
				case 227:
				{
					CreateHat(client, 30527, 6); //Moccasin Machinery
				}
				case 228:
				{
					CreateHat(client, 30527, 13); //Moccasin Machinery
				}
				case 229:
				{
					CreateHat(client, 30527, 11); //Moccasin Machinery
				}
				case 230:
				{
					CreateHat(client, 936, 6); //The Exorcizor
				}
				case 231:
				{
					CreateHat(client, 936, 11); //The Exorcizor
				}
				case 232:
				{
					CreateHat(client, 936, 13); //The Exorcizor
				}														
				case 233:
				{
					CreateHat(client, 30167, 6); //The Beep Boy
				}									
				case 234:
				{
					CreateHat(client, 30167, 11); //The Beep Boy
				}	
			}
		}
		case TFClass_Spy:
		{
			int rnd3 = GetRandomUInt(0,175);
			switch (rnd3)
			{
				case 1:
				{
					CreateHat(client, 868, 6, 20); //Heroic Companion Badge
				}
				case 2:
				{
					CreateHat(client, 583, 6, 20); //Bombinomicon
				}
				case 3:
				{
					CreateHat(client, 586, 6); //Mark of the Saint
				}
				case 4:
				{
					CreateHat(client, 625, 6, 20); //Clan Pride
				}
				case 5:
				{
					CreateHat(client, 619, 6, 20); //Flair!
				}
				case 6:
				{
					CreateHat(client, 1025, 6); //The Fortune Hunter
				}
				case 7:
				{
					CreateHat(client, 623, 6, 20); //Photo Badge
				}
				case 8:
				{
					CreateHat(client, 738, 6); //Pet Balloonicorn
				}
				case 9:
				{
					CreateHat(client, 955, 6); //The Tuxxy
				}
				case 10:
				{
					CreateHat(client, 995, 6, 20); //Pet Reindoonicorn
				}
				case 11:
				{
					CreateHat(client, 987, 6); //The Merc's Muffler
				}
				case 12:
				{
					CreateHat(client, 1096, 6); //The Baronial Badge
				}
				case 13:
				{
					CreateHat(client, 30607, 6); //The Pocket Raiders
				}
				case 14:
				{
					CreateHat(client, 30068, 6); //The Breakneck Baggies
				}
				case 15:
				{
					CreateHat(client, 869, 6); //The Rump-o-Lantern
				}
				case 16:
				{
					CreateHat(client, 30309, 6); //Dead of Night
				}
				case 17:
				{
					CreateHat(client, 1024, 6); //Crofts Crest
				}
				case 18:
				{
					CreateHat(client, 992, 6); //Smissmas Wreath
				}
				case 19:
				{
					CreateHat(client, 956, 6); //Faerie Solitaire Pin
				}
				case 20:
				{
					CreateHat(client, 943, 6); //Hitt Mann Badge
				}
				case 21:
				{
					CreateHat(client, 873, 6, 20); //Whale Bone Charm
				}
				case 22:
				{
					CreateHat(client, 855, 6); //Vigilant Pin
				}
				case 23:
				{
					CreateHat(client, 818, 6); //Awesomenauts Badge
				}
				case 24:
				{
					CreateHat(client, 767, 6); //Atomic Accolade
				}
				case 25:
				{
					CreateHat(client, 718, 6); //Merc Medal
				}
				case 26:
				{
					CreateHat(client, 868, 1, 20); //Heroic Companion Badge
				}
				case 27:
				{
					CreateHat(client, 586, 1); //Mark of the Saint
				}
				case 28:
				{
					CreateHat(client, 625, 11, 20); //Clan Pride
				}
				case 29:
				{
					CreateHat(client, 619, 11, 20); //Flair!
				}
				case 30:
				{
					CreateHat(client, 1025, 1); //The Fortune Hunter
				}
				case 31:
				{
					CreateHat(client, 623, 11, 20); //Photo Badge
				}
				case 32:
				{
					CreateHat(client, 738, 1); //Pet Balloonicorn
				}
				case 33:
				{
					CreateHat(client, 738, 11); //Pet Balloonicorn
				}
				case 34:
				{
					CreateHat(client, 987, 11); //The Merc's Muffler
				}
				case 35:
				{
					CreateHat(client, 1096, 1); //The Baronial Badge
				}
				case 36:
				{
					CreateHat(client, 30068, 11); //The Breakneck Baggies
				}
				case 37:
				{
					CreateHat(client, 869, 11); //The Rump-o-Lantern
				}
				case 38:
				{
					CreateHat(client, 869, 13); //The Rump-o-Lantern
				}
				case 39:
				{
					CreateHat(client, 30309, 11); //Dead of Night
				}
				case 40:
				{
					CreateHat(client, 1024, 1); //Crofts Crest
				}
				case 41:
				{
					CreateHat(client, 956, 1); //Faerie Solitaire Pin
				}
				case 42:
				{
					CreateHat(client, 943, 1); //Hitt Mann Badge
				}
				case 43:
				{
					CreateHat(client, 873, 1, 20); //Whale Bone Charm
				}
				case 44:
				{
					CreateHat(client, 855, 1); //Vigilant Pin
				}
				case 45:
				{
					CreateHat(client, 818, 1); //Awesomenauts Badge
				}
				case 46:
				{
					CreateHat(client, 767, 1); //Atomic Accolade
				}
				case 47:
				{
					CreateHat(client, 718, 1); //Merc Medal
				}
				case 48:
				{
					CreateHat(client, 164, 6); //Grizzled Veteran
				}
				case 49:
				{
					CreateHat(client, 165, 6); //Soldier of Fortune
				}
				case 50:
				{
					CreateHat(client, 166, 6); //Mercenary
				}
				case 51:
				{
					CreateHat(client, 170, 6); //Primeval Warrior
				}
				case 52:
				{
					CreateHat(client, 242, 6); //Duel Medal Bronze
				}
				case 53:
				{
					CreateHat(client, 243, 6); //Duel Medal Silver
				}
				case 54:
				{
					CreateHat(client, 244, 6); //Duel Medal Gold
				}
				case 55:
				{
					CreateHat(client, 245, 6); //Duel Medal Plat
				}
				case 56:
				{
					CreateHat(client, 262, 6); //Polycount Pin
				}
				case 57:
				{
					CreateHat(client, 296, 6); //License to Maim
				}
				case 58:
				{
					CreateHat(client, 299, 1); //Companion Cube Pin
				}
				case 59:
				{
					CreateHat(client, 299, 3); //Companion Cube Pin
				}
				case 60:
				{
					CreateHat(client, 422, 3); //Resurrection Associate Pin
				}
				case 61:
				{
					CreateHat(client, 432, 6); //SpaceChem Pin
				}
				case 62:
				{
					CreateHat(client, 432, 6); //Dr. Grordbort's Crest
				}
				case 63:
				{
					CreateHat(client, 541, 6); //Merc's Pride Scarf
				}
				case 64:
				{
					CreateHat(client, 541, 1); //Merc's Pride Scarf
				}
				case 65:
				{
					CreateHat(client, 541, 11); //Merc's Pride Scarf
				}
				case 66:
				{
					CreateHat(client, 592, 6); //Dr. Grordbort's Copper Crest
				}
				case 67:
				{
					CreateHat(client, 636, 6); //Dr. Grordbort's Silver Crest
				}
				case 68:
				{
					CreateHat(client, 655, 11); //The Spirit of Giving
				}
				case 69:
				{
					CreateHat(client, 704, 1); //The Bolgan Family Crest
				}
				case 70:
				{
					CreateHat(client, 704, 6); //The Bolgan Family Crest
				}
				case 71:
				{
					CreateHat(client, 717, 1); //Mapmaker's Medallion
				}
				case 72:
				{
					CreateHat(client, 733, 6); //Pet Robro
				}
				case 73:
				{
					CreateHat(client, 733, 11); //Pet Robro
				}
				case 74:
				{
					CreateHat(client, 864, 1); //The Friends Forever Companion Square Badge
				}
				case 75:
				{
					CreateHat(client, 865, 1); //The Triple A Badge
				}
				case 76:
				{
					CreateHat(client, 953, 6); //The Saxxy Clapper Badge
				}
				case 77:
				{
					CreateHat(client, 995, 11); //Pet Reindoonicorn
				}
				case 78:
				{
					CreateHat(client, 1011, 6); //Tux
				}
				case 79:
				{
					CreateHat(client, 1126, 6); //Duck Badge
				}
				case 80:
				{
					CreateHat(client, 5075, 6); //Something Special For Someone Special
				}
				case 81:
				{
					CreateHat(client, 30000, 9); //The Electric Badge-alo
				}
				case 82:
				{
					CreateHat(client, 30550, 6); //Snow Sleeves
				}
				case 83:
				{
					CreateHat(client, 30550, 11); //Snow Sleeves
				}
				case 84:
				{
					CreateHat(client, 30551, 6); //Flashdance Footies
				}
				case 85:
				{
					CreateHat(client, 30551, 11); //Flashdance Footies
				}
				case 86:
				{
					CreateHat(client, 30559, 9); //End of the Line Community Update Medal
				}
				case 87:
				{
					CreateHat(client, 30669, 15); //Space Hamster Hammy
				}
				case 88:
				{
					CreateHat(client, 30669, 11); //Space Hamster Hammy
				}
				case 89:
				{
					CreateHat(client, 30670, 9); //Invasion Community Update Medal
				}
				case 90:
				{
					CreateHat(client, 927, 6); //The Boo Balloon
				}
				case 91:
				{
					CreateHat(client, 927, 13); //The Boo Balloon
				}
				case 92:
				{
					CreateHat(client, 929, 6); //The Unknown Monkeynaut
				}
				case 93:
				{
					CreateHat(client, 929, 13); //The Unknown Monkeynaut
				}
				case 94:
				{
					CreateHat(client, 934, 6); //The Dead Little Buddy
				}
				case 95:
				{
					CreateHat(client, 934, 13); //The Dead Little Buddy
				}
				case 96:
				{
					CreateHat(client, 30198, 6); //The Pocket Horsemann
				}
				case 97:
				{
					CreateHat(client, 30198, 13); //The Pocket Horsemann
				}
				case 98:
				{
					CreateHat(client, 30206, 6); //The Accursed Apparition
				}
				case 99:
				{
					CreateHat(client, 30206, 13); //The Accursed Apparition
				}
				case 100:
				{
					CreateHat(client, 30234, 6); //The Sackcloth Spook
				}
				case 101:
				{
					CreateHat(client, 30234, 13); //The Sackcloth Spook
				}
				case 102:
				{
					CreateHat(client, 30252, 6); //Guano
				}
				case 103:
				{
					CreateHat(client, 30252, 13); //Guano
				}
				case 104:
				{
					CreateHat(client, 30254, 6); //Unidentified Following Object
				}
				case 105:
				{
					CreateHat(client, 30254, 13); //Unidentified Following Object
				}
				case 106:
				{
					CreateHat(client, 30255, 6); //The Beacon From Beyond
				}
				case 107:
				{
					CreateHat(client, 30255, 13); //The Beacon From Beyond
				}
				case 108:
				{
					CreateHat(client, 30289, 6); //Quoth
				}
				case 109:
				{
					CreateHat(client, 30289, 13); //Quoth
				}
				case 110:
				{
					CreateHat(client, 30302, 6); //The Cryptic Keepsake
				}
				case 111:
				{
					CreateHat(client, 30302, 13); //The Cryptic Keepsake
				}
				case 112:
				{
					CreateHat(client, 30497, 6); //Ghost of Spies Checked Past
				}
				case 113:
				{
					CreateHat(client, 30497, 13); //Ghost of Spies Checked Past
				}
				case 114:
				{
					CreateHat(client, 30497, 11); //Ghost of Spies Checked Past
				}
				case 115:
				{
					CreateHat(client, 30498, 6); //The Hooded Haunter
				}
				case 116:
				{
					CreateHat(client, 30498, 13); //The Hooded Haunter
				}
				case 117:
				{
					CreateHat(client, 30498, 11); //The Hooded Haunter
				}
				case 118:
				{
					CreateHat(client, 30536, 6); //Cursed Cruise
				}
				case 119:
				{
					CreateHat(client, 30536, 13); //Cursed Cruise
				}
				case 120:
				{
					CreateHat(client, 30536, 11); //Cursed Cruise
				}
				case 121:
				{
					CreateHat(client, 814, 1); //The Triad Trinket
				}
				case 122:
				{
					CreateHat(client, 814, 6); //The Triad Trinket
				}
				case 123:
				{
					CreateHat(client, 814, 11); //The Triad Trinket
				}
				case 124:
				{
					CreateHat(client, 639, 6); //Dr. Whoa
				}
				case 125:
				{
					CreateHat(client, 639, 11); //Dr. Whoa
				}
				case 126:
				{
					CreateHat(client, 462, 6); //The Made Man
				}
				case 127:
				{
					CreateHat(client, 483, 6); //Rogue's Col Roule
				}
				case 128:
				{
					CreateHat(client, 763, 6); //The Sneaky Spats of Sneaking
				}
				case 129:
				{
					CreateHat(client, 763, 11); //The Sneaky Spats of Sneaking
				}
				case 130:
				{
					CreateHat(client, 782, 6); //The Business Casual
				}
				case 131:
				{
					CreateHat(client, 782, 11); //The Business Casual
				}
				case 132:
				{
					CreateHat(client, 879, 6); //The Distinguished Rogue
				}
				case 133:
				{
					CreateHat(client, 879, 1); //The Distinguished Rogue
				}
				case 134:
				{
					CreateHat(client, 936, 6); //The Exorcizor
				}
				case 135:
				{
					CreateHat(client, 936, 11); //The Exorcizor
				}
				case 136:
				{
					CreateHat(client, 936, 13); //The Exorcizor
				}
				case 137:
				{
					CreateHat(client, 977, 6); //The Cut-Throat Concierge
				}
				case 138:
				{
					CreateHat(client, 977, 11); //The Cut-Throat Concierge
				}
				case 139:
				{
					CreateHat(client, 30125, 6); //The Rogue's Brogues
				}
				case 140:
				{
					CreateHat(client, 30125, 11); //The Rogue's Brogues
				}
				case 141:
				{
					CreateHat(client, 30132, 6); //The Blood Banker
				}
				case 142:
				{
					CreateHat(client, 30132, 11); //The Blood Banker
				}
				case 143:
				{
					CreateHat(client, 30132, 6); //The After Dark
				}
				case 144:
				{
					CreateHat(client, 30132, 11); //The After Dark
				}
				case 145:
				{
					CreateHat(client, 30183, 6); //Escapist
				}
				case 146:
				{
					CreateHat(client, 30183, 11); //Escapist
				}
				case 147:
				{
					CreateHat(client, 30189, 6); //The Frenchman's Formals
				}
				case 148:
				{
					CreateHat(client, 30189, 11); //The Frenchman's Formals
				}
				case 149:
				{
					CreateHat(client, 30353, 6); //The Backstabber's Boomslang
				}
				case 150:
				{
					CreateHat(client, 30353, 11); //The Backstabber's Boomslang
				}
				case 151:
				{
					CreateHat(client, 30389, 6); //The Rogue's Robe
				}
				case 152:
				{
					CreateHat(client, 30389, 11); //The Rogue's Robe
				}
				case 153:
				{
					CreateHat(client, 30405, 6); //The Sky Captain
				}
				case 154:
				{
					CreateHat(client, 30405, 11); //The Sky Captain
				}
				case 155:
				{
					CreateHat(client, 30411, 6); //The Au Courant Assassin
				}
				case 156:
				{
					CreateHat(client, 30411, 11); //The Au Courant Assassin
				}
				case 157:
				{
					CreateHat(client, 30467, 1); //The Spycrab
				}
				case 158:
				{
					CreateHat(client, 30476, 6); //The Lady Killer
				}
				case 159:
				{
					CreateHat(client, 30476, 11); //The Lady Killer
				}
				case 160:
				{
					CreateHat(client, 30602, 6); //Puffy Provocateur
				}
				case 161:
				{
					CreateHat(client, 30602, 11); //Puffy Provocateur
				}
				case 162:
				{
					CreateHat(client, 30603, 6); //Stealthy Scarf
				}
				case 163:
				{
					CreateHat(client, 30603, 11); //Stealthy Scarf
				}
				case 164:
				{
					CreateHat(client, 30606, 6); //Pocket Momma
				}
				case 165:
				{
					CreateHat(client, 30606, 11); //Pocket Momma
				}
				case 166:
				{
					CreateHat(client, 30631, 15); //Lurker's Leathers
				}
				case 167:
				{
					CreateHat(client, 30631, 11); //Lurker's Leathers
				}
				case 168:
				{
					CreateHat(client, 560, 6); //Intangible Ascot
				}
				case 169:
				{
					CreateHat(client, 560, 13); //Intangible Ascot
				}
				case 170:
				{
					CreateHat(client, 30260, 6); //The Bountiful Bow
				}
				case 171:
				{
					CreateHat(client, 30260, 13); //The Bountiful Bow
				}
				case 172:
				{
					CreateHat(client, 30283, 6); //The Foul Cowl
				}
				case 173:
				{
					CreateHat(client, 30283, 13); //The Foul Cowl
				}
				case 174:
				{
					CreateHat(client, 30301, 6); //Bozo's Brogues
				}
				case 175:
				{
					CreateHat(client, 30301, 13); //Bozo's Brogues
				}
			}
		}
		case TFClass_Engineer:
		{
			int rnd3 = GetRandomUInt(0,214);
			switch (rnd3)
			{
				case 1:
				{
					CreateHat(client, 868, 6, 20); //Heroic Companion Badge
				}
				case 2:
				{
					CreateHat(client, 583, 6, 20); //Bombinomicon
				}
				case 3:
				{
					CreateHat(client, 586, 6); //Mark of the Saint
				}
				case 4:
				{
					CreateHat(client, 625, 6, 20); //Clan Pride
				}
				case 5:
				{
					CreateHat(client, 619, 6, 20); //Flair!
				}
				case 6:
				{
					CreateHat(client, 1025, 6); //The Fortune Hunter
				}
				case 7:
				{
					CreateHat(client, 623, 6, 20); //Photo Badge
				}
				case 8:
				{
					CreateHat(client, 738, 6); //Pet Balloonicorn
				}
				case 9:
				{
					CreateHat(client, 955, 6); //The Tuxxy
				}
				case 10:
				{
					CreateHat(client, 995, 6, 20); //Pet Reindoonicorn
				}
				case 11:
				{
					CreateHat(client, 987, 6); //The Merc's Muffler
				}
				case 12:
				{
					CreateHat(client, 1096, 6); //The Baronial Badge
				}
				case 13:
				{
					CreateHat(client, 30607, 6); //The Pocket Raiders
				}
				case 14:
				{
					CreateHat(client, 30068, 6); //The Breakneck Baggies
				}
				case 15:
				{
					CreateHat(client, 869, 6); //The Rump-o-Lantern
				}
				case 16:
				{
					CreateHat(client, 30309, 6); //Dead of Night
				}
				case 17:
				{
					CreateHat(client, 1024, 6); //Crofts Crest
				}
				case 18:
				{
					CreateHat(client, 992, 6); //Smissmas Wreath
				}
				case 19:
				{
					CreateHat(client, 956, 6); //Faerie Solitaire Pin
				}
				case 20:
				{
					CreateHat(client, 943, 6); //Hitt Mann Badge
				}
				case 21:
				{
					CreateHat(client, 873, 6, 20); //Whale Bone Charm
				}
				case 22:
				{
					CreateHat(client, 855, 6); //Vigilant Pin
				}
				case 23:
				{
					CreateHat(client, 818, 6); //Awesomenauts Badge
				}
				case 24:
				{
					CreateHat(client, 767, 6); //Atomic Accolade
				}
				case 25:
				{
					CreateHat(client, 718, 6); //Merc Medal
				}
				case 26:
				{
					CreateHat(client, 868, 1, 20); //Heroic Companion Badge
				}
				case 27:
				{
					CreateHat(client, 586, 1); //Mark of the Saint
				}
				case 28:
				{
					CreateHat(client, 625, 11, 20); //Clan Pride
				}
				case 29:
				{
					CreateHat(client, 619, 11, 20); //Flair!
				}
				case 30:
				{
					CreateHat(client, 1025, 1); //The Fortune Hunter
				}
				case 31:
				{
					CreateHat(client, 623, 11, 20); //Photo Badge
				}
				case 32:
				{
					CreateHat(client, 738, 1); //Pet Balloonicorn
				}
				case 33:
				{
					CreateHat(client, 738, 11); //Pet Balloonicorn
				}
				case 34:
				{
					CreateHat(client, 987, 11); //The Merc's Muffler
				}
				case 35:
				{
					CreateHat(client, 1096, 1); //The Baronial Badge
				}
				case 36:
				{
					CreateHat(client, 30068, 11); //The Breakneck Baggies
				}
				case 37:
				{
					CreateHat(client, 869, 11); //The Rump-o-Lantern
				}
				case 38:
				{
					CreateHat(client, 869, 13); //The Rump-o-Lantern
				}
				case 39:
				{
					CreateHat(client, 30309, 11); //Dead of Night
				}
				case 40:
				{
					CreateHat(client, 1024, 1); //Crofts Crest
				}
				case 41:
				{
					CreateHat(client, 956, 1); //Faerie Solitaire Pin
				}
				case 42:
				{
					CreateHat(client, 943, 1); //Hitt Mann Badge
				}
				case 43:
				{
					CreateHat(client, 873, 1, 20); //Whale Bone Charm
				}
				case 44:
				{
					CreateHat(client, 855, 1); //Vigilant Pin
				}
				case 45:
				{
					CreateHat(client, 818, 1); //Awesomenauts Badge
				}
				case 46:
				{
					CreateHat(client, 767, 1); //Atomic Accolade
				}
				case 47:
				{
					CreateHat(client, 718, 1); //Merc Medal
				}
				case 48:
				{
					CreateHat(client, 164, 6); //Grizzled Veteran
				}
				case 49:
				{
					CreateHat(client, 165, 6); //Soldier of Fortune
				}
				case 50:
				{
					CreateHat(client, 166, 6); //Mercenary
				}
				case 51:
				{
					CreateHat(client, 170, 6); //Primeval Warrior
				}
				case 52:
				{
					CreateHat(client, 242, 6); //Duel Medal Bronze
				}
				case 53:
				{
					CreateHat(client, 243, 6); //Duel Medal Silver
				}
				case 54:
				{
					CreateHat(client, 244, 6); //Duel Medal Gold
				}
				case 55:
				{
					CreateHat(client, 245, 6); //Duel Medal Plat
				}
				case 56:
				{
					CreateHat(client, 262, 6); //Polycount Pin
				}
				case 57:
				{
					CreateHat(client, 296, 6); //License to Maim
				}
				case 58:
				{
					CreateHat(client, 299, 1); //Companion Cube Pin
				}
				case 59:
				{
					CreateHat(client, 299, 3); //Companion Cube Pin
				}
				case 60:
				{
					CreateHat(client, 422, 3); //Resurrection Associate Pin
				}
				case 61:
				{
					CreateHat(client, 432, 6); //SpaceChem Pin
				}
				case 62:
				{
					CreateHat(client, 432, 6); //Dr. Grordbort's Crest
				}
				case 63:
				{
					CreateHat(client, 541, 6); //Merc's Pride Scarf
				}
				case 64:
				{
					CreateHat(client, 541, 1); //Merc's Pride Scarf
				}
				case 65:
				{
					CreateHat(client, 541, 11); //Merc's Pride Scarf
				}
				case 66:
				{
					CreateHat(client, 592, 6); //Dr. Grordbort's Copper Crest
				}
				case 67:
				{
					CreateHat(client, 636, 6); //Dr. Grordbort's Silver Crest
				}
				case 68:
				{
					CreateHat(client, 655, 11); //The Spirit of Giving
				}
				case 69:
				{
					CreateHat(client, 704, 1); //The Bolgan Family Crest
				}
				case 70:
				{
					CreateHat(client, 704, 6); //The Bolgan Family Crest
				}
				case 71:
				{
					CreateHat(client, 717, 1); //Mapmaker's Medallion
				}
				case 72:
				{
					CreateHat(client, 733, 6); //Pet Robro
				}
				case 73:
				{
					CreateHat(client, 733, 11); //Pet Robro
				}
				case 74:
				{
					CreateHat(client, 864, 1); //The Friends Forever Companion Square Badge
				}
				case 75:
				{
					CreateHat(client, 865, 1); //The Triple A Badge
				}
				case 76:
				{
					CreateHat(client, 953, 6); //The Saxxy Clapper Badge
				}
				case 77:
				{
					CreateHat(client, 995, 11); //Pet Reindoonicorn
				}
				case 78:
				{
					CreateHat(client, 1011, 6); //Tux
				}
				case 79:
				{
					CreateHat(client, 1126, 6); //Duck Badge
				}
				case 80:
				{
					CreateHat(client, 5075, 6); //Something Special For Someone Special
				}
				case 81:
				{
					CreateHat(client, 30000, 9); //The Electric Badge-alo
				}
				case 82:
				{
					CreateHat(client, 30550, 6); //Snow Sleeves
				}
				case 83:
				{
					CreateHat(client, 30550, 11); //Snow Sleeves
				}
				case 84:
				{
					CreateHat(client, 30551, 6); //Flashdance Footies
				}
				case 85:
				{
					CreateHat(client, 30551, 11); //Flashdance Footies
				}
				case 86:
				{
					CreateHat(client, 30559, 9); //End of the Line Community Update Medal
				}
				case 87:
				{
					CreateHat(client, 30669, 15); //Space Hamster Hammy
				}
				case 88:
				{
					CreateHat(client, 30669, 11); //Space Hamster Hammy
				}
				case 89:
				{
					CreateHat(client, 30670, 9); //Invasion Community Update Medal
				}
				case 90:
				{
					CreateHat(client, 927, 6); //The Boo Balloon
				}
				case 91:
				{
					CreateHat(client, 927, 13); //The Boo Balloon
				}
				case 92:
				{
					CreateHat(client, 929, 6); //The Unknown Monkeynaut
				}
				case 93:
				{
					CreateHat(client, 929, 13); //The Unknown Monkeynaut
				}
				case 94:
				{
					CreateHat(client, 934, 6); //The Dead Little Buddy
				}
				case 95:
				{
					CreateHat(client, 934, 13); //The Dead Little Buddy
				}
				case 96:
				{
					CreateHat(client, 30198, 6); //The Pocket Horsemann
				}
				case 97:
				{
					CreateHat(client, 30198, 13); //The Pocket Horsemann
				}
				case 98:
				{
					CreateHat(client, 30206, 6); //The Accursed Apparition
				}
				case 99:
				{
					CreateHat(client, 30206, 13); //The Accursed Apparition
				}
				case 100:
				{
					CreateHat(client, 30234, 6); //The Sackcloth Spook
				}
				case 101:
				{
					CreateHat(client, 30234, 13); //The Sackcloth Spook
				}
				case 102:
				{
					CreateHat(client, 30252, 6); //Guano
				}
				case 103:
				{
					CreateHat(client, 30252, 13); //Guano
				}
				case 104:
				{
					CreateHat(client, 30254, 6); //Unidentified Following Object
				}
				case 105:
				{
					CreateHat(client, 30254, 13); //Unidentified Following Object
				}
				case 106:
				{
					CreateHat(client, 30255, 6); //The Beacon From Beyond
				}
				case 107:
				{
					CreateHat(client, 30255, 13); //The Beacon From Beyond
				}
				case 108:
				{
					CreateHat(client, 30289, 6); //Quoth
				}
				case 109:
				{
					CreateHat(client, 30289, 13); //Quoth
				}
				case 110:
				{
					CreateHat(client, 30302, 6); //The Cryptic Keepsake
				}
				case 111:
				{
					CreateHat(client, 30302, 13); //The Cryptic Keepsake
				}
				case 112:
				{
					CreateHat(client, 30497, 6); //Ghost of Spies Checked Past
				}
				case 113:
				{
					CreateHat(client, 30497, 13); //Ghost of Spies Checked Past
				}
				case 114:
				{
					CreateHat(client, 30497, 11); //Ghost of Spies Checked Past
				}
				case 115:
				{
					CreateHat(client, 30498, 6); //The Hooded Haunter
				}
				case 116:
				{
					CreateHat(client, 30498, 13); //The Hooded Haunter
				}
				case 117:
				{
					CreateHat(client, 30498, 11); //The Hooded Haunter
				}
				case 118:
				{
					CreateHat(client, 30536, 6); //Cursed Cruise
				}
				case 119:
				{
					CreateHat(client, 30536, 13); //Cursed Cruise
				}
				case 120:
				{
					CreateHat(client, 30536, 11); //Cursed Cruise
				}
				case 121:
				{
					CreateHat(client, 814, 1); //The Triad Trinket
				}
				case 122:
				{
					CreateHat(client, 814, 6); //The Triad Trinket
				}
				case 123:
				{
					CreateHat(client, 814, 11); //The Triad Trinket
				}
				case 124:
				{
					CreateHat(client, 815, 1); //The Champ Stamp
				}
				case 125:
				{
					CreateHat(client, 815, 6); //The Champ Stamp
				}
				case 126:
				{
					CreateHat(client, 815, 11); //The Champ Stamp
				}	
				case 128:
				{
					CreateHat(client, 646, 6); //The Itsy Bitsy Spyer
				}
				case 129:
				{
					CreateHat(client, 646, 11); //The Itsy Bitsy Spyer
				}	
				case 130:
				{
					CreateHat(client, 734, 6); //The Teufort Tooth Kicker
				}
				case 131:
				{
					CreateHat(client, 734, 11); //The Teufort Tooth Kicker
				}					
				case 132:
				{
					CreateHat(client, 30056, 6); //The Dual-Core Devil Doll
				}				
				case 133:
				{
					CreateHat(client, 30056, 11); //The Dual-Core Devil Doll
				}														
				case 134:
				{
					CreateHat(client, 30481, 6); //Hillbilly Speed Bump
				}				
				case 135:
				{
					CreateHat(client, 30481, 11); //Hillbilly Speed Bump
				}				
				case 136:
				{
					CreateHat(client, 948, 1); //The Deadliest Duckling
				}				
				case 137:
				{
					CreateHat(client, 948, 6); //The Deadliest Duckling
				}				
				case 138:
				{
					CreateHat(client, 386, 6); //Teddy Roosebelt
				}					
				case 139:
				{
					CreateHat(client, 386, 11); //Teddy Roosebelt
				}					
				case 140:
				{
					CreateHat(client, 484, 6); //Prarie Heel Biters
				}						
				case 141:
				{
					CreateHat(client, 519, 6); //Pip-Boy
				}							
				case 142:
				{
					CreateHat(client, 519, 1); //Pip-Boy
				}						
				case 143:
				{
					CreateHat(client, 520, 6); //Wingstick
				}							
				case 144:
				{
					CreateHat(client, 520, 1); //Wingstick
				}								
				case 145:
				{
					CreateHat(client, 606, 6); //The Builder's Blueprints
				}								
				case 146:
				{
					CreateHat(client, 606, 11); //The Builder's Blueprints
				}								
				case 147:
				{
					CreateHat(client, 670, 6); //The Stocking Stuffer
				}								
				case 148:
				{
					CreateHat(client, 670, 11); //The Stocking Stuffer
				}									
				case 149:
				{
					CreateHat(client, 755, 6); //The Texas Half-Pants
				}								
				case 150:
				{
					CreateHat(client, 755, 11); //The Texas Half-Pants
				}										
				case 151:
				{
					CreateHat(client, 784, 6); //The Idea Tube
				}								
				case 152:
				{
					CreateHat(client, 784, 11); //The Idea Tube
				}									
				case 153:
				{
					CreateHat(client, 1008, 6); //The Prize Plushy
				}									
				case 154:
				{
					CreateHat(client, 1008, 1); //The Prize Plushy
				}									
				case 155:
				{
					CreateHat(client, 1089, 6); //Mister Bubbles
				}									
				case 156:
				{
					CreateHat(client, 1089, 1); //Mister Bubbles
				}									
				case 157:
				{
					CreateHat(client, 30023, 6); //Teddy Robobelt
				}									
				case 158:
				{
					CreateHat(client, 30023, 11); //Teddy Robobelt
				}										
				case 159:
				{
					CreateHat(client, 30070, 6); //The Pocket Pyro
				}									
				case 160:
				{
					CreateHat(client, 30070, 11); //The Pocket Pyro
				}											
				case 161:
				{
					CreateHat(client, 30086, 6); //The Trash Toter
				}									
				case 162:
				{
					CreateHat(client, 30086, 11); //The Trash Toter
				}												
				case 163:
				{
					CreateHat(client, 30087, 6); //The Dry Gulch Gulp
				}									
				case 164:
				{
					CreateHat(client, 30087, 11); //The Dry Gulch Gulp
				}													
				case 165:
				{
					CreateHat(client, 30113, 6); //The Flared Frontiersman
				}									
				case 166:
				{
					CreateHat(client, 30113, 11); //The Flared Frontiersman
				}														
				case 167:
				{
					CreateHat(client, 30167, 6); //The Beep Boy
				}									
				case 168:
				{
					CreateHat(client, 30167, 11); //The Beep Boy
				}														
				case 169:
				{
					CreateHat(client, 30330, 6); //The Dogfighter
				}									
				case 170:
				{
					CreateHat(client, 30330, 11); //The Dogfighter
				}															
				case 171:
				{
					CreateHat(client, 30337, 6); //The Trencher's Tunic
				}									
				case 172:
				{
					CreateHat(client, 30337, 11); //The Trencher's Tunic
				}																
				case 173:
				{
					CreateHat(client, 30341, 6); //Ein
				}									
				case 174:
				{
					CreateHat(client, 30341, 11); //Ein
				}																	
				case 175:
				{
					CreateHat(client, 30377, 6); //The Antarctic Researcher
				}									
				case 176:
				{
					CreateHat(client, 30377, 11); //The Antarctic Researcher
				}																	
				case 177:
				{
					CreateHat(client, 30402, 6); //The Tools of the Trade
				}									
				case 178:
				{
					CreateHat(client, 30402, 11); //The Tools of the Trade
				}																		
				case 179:
				{
					CreateHat(client, 30403, 6); //The Joe-on-the-Go
				}									
				case 180:
				{
					CreateHat(client, 30403, 11); //The Joe-on-the-Go
				}																			
				case 181:
				{
					CreateHat(client, 30408, 6); //The Egghead's Overalls
				}									
				case 182:
				{
					CreateHat(client, 30408, 11); //The Egghead's Overalls
				}																			
				case 183:
				{
					CreateHat(client, 30409, 6); //The Lonesome Loafers
				}									
				case 184:
				{
					CreateHat(client, 30409, 11); //The Lonesome Loafers
				}																				
				case 185:
				{
					CreateHat(client, 30412, 6); //The Endothermic Exowear
				}									
				case 186:
				{
					CreateHat(client, 30412, 11); //The Endothermic Exowear
				}																					
				case 187:
				{
					CreateHat(client, 30539, 6); //Insulated Inventor
				}									
				case 188:
				{
					CreateHat(client, 30539, 11); //Insulated Inventor
				}																						
				case 189:
				{
					CreateHat(client, 30590, 6); //Holstered Heaters
				}									
				case 190:
				{
					CreateHat(client, 30590, 11); //Holstered Heaters
				}																							
				case 191:
				{
					CreateHat(client, 30591, 6); //Cop Caller
				}									
				case 192:
				{
					CreateHat(client, 30591, 11); //Cop Caller
				}																								
				case 193:
				{
					CreateHat(client, 30593, 6); //Clubsy the Seal
				}									
				case 194:
				{
					CreateHat(client, 30593, 11); //Clubsy the Seal
				}																								
				case 195:
				{
					CreateHat(client, 30605, 6); //Thermal Insulation Layer
				}									
				case 196:
				{
					CreateHat(client, 30605, 11); //Thermal Insulation Layer
				}																
				case 197:
				{
					CreateHat(client, 30629, 15); //Support Spurs
				}				
				case 198:
				{
					CreateHat(client, 30629, 11); //Support Spurs
				}																
				case 199:
				{
					CreateHat(client, 30635, 15); //Wild West Waistcoat
				}				
				case 200:
				{
					CreateHat(client, 30635, 11); //Wild West Waistcoat
				}																
				case 201:
				{
					CreateHat(client, 30654, 15); //Life Support System
				}				
				case 202:
				{
					CreateHat(client, 30654, 11); //Life Support System
				}																
				case 203:
				{
					CreateHat(client, 30655, 15); //Rocket Operator
				}				
				case 204:
				{
					CreateHat(client, 30655, 11); //Rocket Operator
				}																
				case 205:
				{
					CreateHat(client, 568, 6); //Frontier Flyboy
				}				
				case 206:
				{
					CreateHat(client, 568, 13); //Frontier Flyboy
				}																	
				case 207:
				{
					CreateHat(client, 569, 6); //Legend of Bugfoot
				}				
				case 208:
				{
					CreateHat(client, 569, 13); //Legend of Bugfoot
				}																	
				case 209:
				{
					CreateHat(client, 30508, 6); //Iron Fist
				}				
				case 210:
				{
					CreateHat(client, 30508, 13); //Iron Fist
				}				
				case 211:
				{
					CreateHat(client, 30508, 11); //Iron Fist
				}																		
				case 212:
				{
					CreateHat(client, 30510, 6); //Soul of 'Spenser's Past
				}				
				case 213:
				{
					CreateHat(client, 30510, 13); //Soul of 'Spenser's Past
				}				
				case 214:
				{
					CreateHat(client, 30510, 11); //Soul of 'Spenser's Past
				}		
			}
		}
	}	
}

bool CreateHat(int client, int itemindex, int quality, int level = 0)
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
	SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), quality);

	if (level)
	{
		SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	}
	else
	{
		SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityLevel"), GetRandomUInt(1,100));
	}
	
	DispatchSpawn(hat);
	SDKCall(g_hWearableEquip, client, hat);
	return true;
} 

bool IsPlayerHere(int client)
{
	return (client && IsClientInGame(client) && IsFakeClient(client));
}

int GetRandomUInt(int min, int max)
{
	return RoundToFloor(GetURandomFloat() * (max - min + 1)) + min;
}