#include <sourcemod>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.31"

bool g_bSuddenDeathMode;
bool g_bMVM;
bool g_bLateLoad;
ConVar g_hCVTimer;
ConVar g_hCVEnabled;
ConVar g_hCVTeam;
ConVar g_hCVMVMSupport;
Handle g_hWeaponEquip;
Handle g_hWWeaponEquip;
Handle g_hTouched[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "Give Bots Weapons",
	author = "luki1412",
	description = "Gives TF2 bots non-stock weapons",
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
	ConVar hCVversioncvar = CreateConVar("sm_gbw_version", PLUGIN_VERSION, "Give Bots Weapons version cvar", FCVAR_NOTIFY|FCVAR_DONTRECORD); 
	g_hCVEnabled = CreateConVar("sm_gbw_enabled", "1", "Enables/disables this plugin", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCVTimer = CreateConVar("sm_gbw_delay", "0.1", "Delay for giving weapons to bots", FCVAR_NONE, true, 0.1, true, 30.0);
	g_hCVTeam = CreateConVar("sm_gbw_team", "1", "Team to give weapons to: 1-both, 2-red, 3-blu", FCVAR_NONE, true, 1.0, true, 3.0);
	g_hCVMVMSupport = CreateConVar("sm_gbw_mvm", "0", "Enables/disables giving bots weapons when MVM mode is enabled", FCVAR_NONE, true, 0.0, true, 1.0);

	OnEnabledChanged(g_hCVEnabled, "", "");
	HookConVarChange(g_hCVEnabled, OnEnabledChanged);

	SetConVarString(hCVversioncvar, PLUGIN_VERSION);
	AutoExecConfig(true, "Give_Bots_Weapons");

	if (g_bLateLoad)
	{
		OnMapStart();
	}
	
	GameData hGameConfig = LoadGameConfigFile("give.bots.weapons");
	
	if (!hGameConfig)
	{
		SetFailState("Failed to find give.bots.weapons.txt gamedata! Can't continue.");
	}	
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConfig, SDKConf_Virtual, "WeaponEquip");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hWeaponEquip = EndPrepSDKCall();
	
	if (!g_hWeaponEquip)
	{
		SetFailState("Failed to prepare the SDKCall for giving weapons. Try updating gamedata or restarting your server.");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConfig, SDKConf_Virtual, "EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hWWeaponEquip = EndPrepSDKCall();
	
	if (!g_hWWeaponEquip)
	{
		SetFailState("Failed to prepare the SDKCall for giving weapons. Try updating gamedata or restarting your server.");
	}

	delete hGameConfig;
}

public void OnEnabledChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (GetConVarBool(g_hCVEnabled))
	{
		HookEvent("post_inventory_application", player_inv);
		HookEvent("teamplay_round_stalemate", EventSuddenDeath, EventHookMode_PostNoCopy);
		HookEvent("teamplay_round_start", EventRoundReset, EventHookMode_PostNoCopy);
	}
	else
	{
		UnhookEvent("post_inventory_application", player_inv);
		UnhookEvent("teamplay_round_stalemate", EventSuddenDeath, EventHookMode_PostNoCopy);
		UnhookEvent("teamplay_round_start", EventRoundReset, EventHookMode_PostNoCopy);
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
	delete g_hTouched[client];
}

public void player_inv(Handle event, const char[] ename, bool dontBroadcast) 
{
	if (!GetConVarBool(g_hCVEnabled))
	{
		return;
	}

	int userd = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userd);
	delete g_hTouched[client];

	if (!g_bSuddenDeathMode && (!g_bMVM || (g_bMVM && GetConVarBool(g_hCVMVMSupport))) && IsPlayerHere(client))
	{
		int team = GetClientTeam(client);
		int team2 = GetConVarInt(g_hCVTeam);
		float timer = GetConVarFloat(g_hCVTimer);
		switch (team2)
		{
			case 1:
			{
				g_hTouched[client] = CreateTimer(timer, Timer_GiveWeapons, userd, TIMER_FLAG_NO_MAPCHANGE);
			}
			case 2:
			{
				if (team == 2)
				{
					g_hTouched[client] = CreateTimer(timer, Timer_GiveWeapons, userd, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
			case 3:
			{
				if (team == 3)
				{
					g_hTouched[client] = CreateTimer(timer, Timer_GiveWeapons, userd, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}
}

public Action Timer_GiveWeapons(Handle timer, any data)
{
	int client = GetClientOfUserId(data);
	g_hTouched[client] = null;
	
	if (!GetConVarBool(g_hCVEnabled) || !IsPlayerHere(client))
	{
		return Plugin_Stop;
	}

	int team = GetClientTeam(client);
	int team2 = GetConVarInt(g_hCVTeam);
	
	switch (team2)
	{
		case 2:
		{
			if (team != 2)
			{
				return Plugin_Stop;
			}
		}
		case 3:
		{
			if (team != 3)
			{
				return Plugin_Stop;
			}
		}
	}

	if (!g_bSuddenDeathMode && (!g_bMVM || (g_bMVM && GetConVarBool(g_hCVMVMSupport))))
	{
		TFClassType class = TF2_GetPlayerClass(client);

		int rndact = GetRandomUInt(0,3);

		switch (rndact)
		{
			case 1:
			{
				CreateWeapon(client, "tf_wearable", -1, 241, 5, true);
			}
			case 2:
			{
				CreateWeapon(client, "tf_powerup_bottle", -1, 489, _, true);
			}
			case 3:
			{
				CreateWeapon(client, "tf_weapon_spellbook", -1, 1069, 1, false);
			}
		}

		if (GameRules_GetProp("m_bPlayingMedieval") != 1)
		{
			switch (class)
			{
				case TFClass_Scout:
				{
					int rnd = GetRandomUInt(0,2);

					switch (rnd)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_scattergun", 0, 45, 10);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_pep_brawler_blaster", 0, 772, 10);
						}
					}
					
					int rnd2 = GetRandomUInt(0,5);

					switch (rnd2)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_lunchbox_drink", 1, 46, 10);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_lunchbox_drink", 1, 163, 15);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_jar_milk", 1, 222, 20);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_handgun_scout_secondary", 1, 773, 25);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_cleaver", 1, 812, 30);
						}
					}
					
					int rnd3 = GetRandomUInt(0,1);

					switch (rnd3)
					{
						case 3:
						{
							CreateWeapon(client, "tf_weapon_bat", 2, 317, 25);
						}
					}
				}
				case TFClass_Sniper:
				{
					int rnd = GetRandomUInt(1,1);

					switch (rnd)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_compound_bow", 0, 56, 10);
						}
					}
					
					int rnd2 = GetRandomUInt(0,4);

					switch (rnd2)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_jar", 1, 58, 10);
						}
						case 2:
						{
							CreateWeapon(client, "tf_wearable", 1, 57, 10, true);
						}
						case 3:
						{
							CreateWeapon(client, "tf_wearable", 1, 231, 10, true);
						}
						case 4:
						{
							CreateWeapon(client, "tf_wearable", 1, 642, 10, true);
						}
					}
					
					int rnd3 = GetRandomUInt(0,3);

					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_club", 2, 171, 5);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_club", 2, 232, 5);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_club", 2, 401, 5);
						}
					}			
				}
				case TFClass_Soldier:
				{
					int rnd = GetRandomUInt(0,3);

					switch (rnd)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_rocketlauncher", 0, 228, 5);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_rocketlauncher", 0, 414, 25);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_particle_cannon", 0, 441, 30);
						}						
					}
					
					int rnd2 = GetRandomUInt(1,3);

					switch (rnd2)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_buff_item", 1, 129, 30);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_buff_item", 1, 226, 20);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_buff_item", 1, 354, 10);
						}
					}
					
					int rnd3 = GetRandomUInt(0,0);

					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_shovel", 2, 128, 10);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_shovel", 2, 154, 5);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_shovel", 2, 447, 10);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_shovel", 2, 775, 10);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_katana", 2, 357, 5);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_shovel", 2, 1013, 5);
						}
						case 7:
						{
							CreateWeapon(client, "tf_weapon_shovel", 2, 939, 5);
						}
						case 8:
						{
							CreateWeapon(client, "tf_weapon_shovel", 2, 880, 25);
						}
						case 9:
						{
							CreateWeapon(client, "tf_weapon_shovel", 2, 474, 25);
						}
					}
				}
				case TFClass_DemoMan:
				{
					int rnd = GetRandomUInt(1,1);

					switch (rnd)
					{
						case 1:
						{
							CreateWeapon(client, "tf_wearable", 0, 405, 20, true);
						}
					}
					
					int rnd2 = GetRandomUInt(1,2);

					switch (rnd2)
					{
						case 1:
						{
							CreateWeapon(client, "tf_wearable_demoshield", 1, 131, _, true);
						}
						case 2:
						{
							CreateWeapon(client, "tf_wearable_demoshield", 1, 406, _, true);
						}
					}
					
					int rnd3 = GetRandomUInt(1,2);

					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_sword", 2, 132, 5);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_katana", 2, 357, 5);
						}
					}				
				}
				case TFClass_Medic:
				{
					int rnd = GetRandomUInt(1,1);

					switch (rnd)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_crossbow", 0, 305, 15);
						}
					}
					
					int rnd2 = GetRandomUInt(0,2);

					switch (rnd2)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_medigun", 1, 35, 8);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_medigun", 1, 411, 8);
						}
					}
					
					int rnd3 = GetRandomUInt(0,1);

					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 2, 37, 10);
						}
					}			
				}
				case TFClass_Heavy:
				{
					int rnd = GetRandomUInt(0,2);

					switch (rnd)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_minigun", 0, 41, 5);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_minigun", 0, 424, 5);
						}
					}
					
					int rnd2 = GetRandomUInt(1,1);

					switch (rnd2)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_shotgun_hwg", 1, 425, 10);
						}						
					}
					
					int rnd3 = GetRandomUInt(0,1);

					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_fists", 2, 331, 10);
						}
					}						
				}
				case TFClass_Pyro:
				{
					int rnd = GetRandomUInt(0,0);

					switch (rnd)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_flamethrower", 0, 40, 10);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_flamethrower", 0, 215, 10);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_flamethrower", 0, 594, 10);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_flamethrower", 0, 741, 10);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_rocketlauncher_fireball", 0, 1178);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_flamethrower", 0, 30474, 25);
						}
					}
					
					int rnd2 = GetRandomUInt(0,2);

					switch (rnd2)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_flaregun", 1, 39, 10);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_flaregun", 1, 740, 10);
						}
					}
					
					int rnd3 = GetRandomUInt(0,0);

					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 2, 38, 10);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 2, 153, 5);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 2, 214, 5);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 2, 326, 10);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 2, 348, 10);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 2, 593, 10);
						}
						case 7:
						{
							CreateWeapon(client, "tf_weapon_breakable_sign", 2, 813);
						}
						case 8:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 2, 457, 10);
						}
						case 9:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 2, 739);
						}
						case 10:
						{
							CreateWeapon(client, "tf_weapon_slap", 2, 1181);
						}
						case 11:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 2, 466, 5);
						}
						case 12:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 2, 1013, 5);
						}
						case 13:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 2, 939, 5);
						}
						case 14:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 2, 880, 25);
						}
						case 15:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 2, 474, 25);
						}
					}			
				}
				case TFClass_Spy:
				{
					int rnd = GetRandomUInt(0,2);

					switch (rnd)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_revolver", 0, 224, 5);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_revolver", 0, 525, 5);
						}					
					}
					
					int rnd2 = GetRandomUInt(0,1);

					switch (rnd2)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_sapper", 1, 810);
						}
					}
					
					int rnd3 = GetRandomUInt(0,4);

					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_knife", 2, 356, 1);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_knife", 2, 461, 1);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_knife", 2, 649, 1);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_knife", 2, 225, 1);
						}
					}
					int rnd4 = GetRandomUInt(0,0);

					switch (rnd4)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_invis", 4, 947);
						}
					}					
				}
				case TFClass_Engineer:
				{
					int rnd = GetRandomUInt(1,1);

					switch (rnd)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_sentry_revenge", 0, 141, 5);
						}					
					}
					
					int rnd3 = GetRandomUInt(1,1);

					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_wrench", 2, 329, 15);
						}						
					}	
				}
			}
		}
		else
		{
			switch (class)
			{
				case TFClass_Scout:
				{
					int rnd3 = GetRandomUInt(0,2);

					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_bat", 2, 317, 25);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_bat", 2, 355, 5);
						}
					}
				}
				case TFClass_Sniper:
				{
					int rnd = GetRandomUInt(1,1);

					switch (rnd)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_compound_bow", 0, 56, 10);
						}
					}
					
					int rnd2 = GetRandomUInt(1,2);

					switch (rnd2)
					{
						case 1:
						{
							CreateWeapon(client, "tf_wearable", 1, 57, 10, true);
						}
						case 2:
						{
							CreateWeapon(client, "tf_wearable", 1, 642, 10, true);
						}
					}
					
					int rnd3 = GetRandomUInt(0,2);

					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_club", 2, 171, 5);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_club", 2, 401, 5);
						}
					}			
				}
				case TFClass_Soldier:
				{
					int rnd2 = GetRandomUInt(1,3);

					switch (rnd2)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_buff_item", 1, 129, 30);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_buff_item", 1, 226, 20);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_buff_item", 1, 354, 10);
						}
					}
					
					int rnd3 = GetRandomUInt(0,3);

					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_shovel", 2, 154, 5);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_shovel", 2, 447, 10);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_katana", 2, 357, 5);
						}
					}
				}
				case TFClass_DemoMan:
				{
					int rnd = GetRandomUInt(1,1);

					switch (rnd)
					{
						case 1:
						{
							CreateWeapon(client, "tf_wearable", 0, 405, 10, true);
						}
					}				

					int rnd2 = GetRandomUInt(1,2);

					switch (rnd2)
					{
						case 1:
						{
							CreateWeapon(client, "tf_wearable_demoshield", 1, 131, 20, true);
						}
						case 2:
						{
							CreateWeapon(client, "tf_wearable_demoshield", 1, 406, 30, true);
						}
					}				
				
					int rnd3 = GetRandomUInt(1,5);

					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_sword", 2, 132, 5);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_sword", 2, 172, 5);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_sword", 2, 327, 10);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_katana", 2, 357, 5);
						}
						case 5:
						{						
							CreateWeapon(client, "tf_weapon_sword", 2, 404);							
						}
					}
				}
				case TFClass_Medic:
				{
					int rnd = GetRandomUInt(1,1);

					switch (rnd)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_crossbow", 0, 305, 15);
						}
					}

					int rnd3 = GetRandomUInt(0,0);

					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 2, 37, 10);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 2, 173, 5);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 2, 304, 15);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 2, 413, 10);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 2, 1013, 5);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 2, 939, 5);
						}
						case 7:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 2, 880, 25);
						}
						case 8:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 2, 474, 25);
						}
					}			
				}
				case TFClass_Heavy:
				{
					int rnd3 = GetRandomUInt(0,3);

					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_fists", 2, 43, 7);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_fists", 2, 310, 10);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_fists", 2, 656, 10);
						}
					}						
				}
				case TFClass_Pyro:
				{
					int rnd3 = GetRandomUInt(0,3);

					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 2, 214, 5);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 2, 326, 10);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 2, 348, 10);
						}
					}			
				}
				case TFClass_Spy:
				{
					int rnd3 = GetRandomUInt(0,4);

					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_knife", 2, 356, 1);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_knife", 2, 461, 1);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_knife", 2, 649, 1);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_knife", 2, 225, 1);
						}
					}
					int rnd4 = GetRandomUInt(1,1);

					switch (rnd4)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_invis", 4, 947);
						}
					}					
				}
				case TFClass_Engineer:
				{
					int rnd3 = GetRandomUInt(0,2);

					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_wrench", 2, 155, 20);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_robot_arm", 2, 142, 15);
						}					
					}	
				}
			}
		}
		CreateTimer(0.1, TimerHealth, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

public void EventSuddenDeath(Handle event, const char[] name, bool dontBroadcast)
{
	g_bSuddenDeathMode = true;
}

public void EventRoundReset(Handle event, const char[] name, bool dontBroadcast)
{
	g_bSuddenDeathMode = false;
}

bool CreateWeapon(int client, char[] classname, int slot, int itemindex, int level = 0, bool wearable = false)
{
	int weapon = CreateEntityByName(classname);
	
	if (!IsValidEntity(weapon))
	{
		LogError("Failed to create a valid entity with class name [%s]! Skipping.", classname);
		return false;
	}
	
	char entclass[64];
	GetEntityNetClass(weapon, entclass, sizeof(entclass));
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iItemDefinitionIndex"), itemindex);	 
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 6);

	if (level)
	{
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	}
	else
	{
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityLevel"), GetRandomUInt(1,99));
	}

	switch (itemindex)
	{
		case 810:
		{
			SetEntData(weapon, FindSendPropInfo(entclass, "m_iObjectType"), 3);
			SetEntData(weapon, FindDataMapInfo(weapon, "m_iSubType"), 3);
			int buildables[4] = {0,0,0,1};
			SetEntDataArray(weapon, FindSendPropInfo(entclass, "m_aBuildableObjectTypes"), buildables, 4);
		}
		case 998:
		{
			int resistType = GetRandomUInt(0,4);
			if(resistType > 2) {
				resistType = 0;
			}
			SetEntData(weapon, FindSendPropInfo(entclass, "m_nChargeResistType"), resistType);
		}
	}
	
	SetEntData(weapon, FindSendPropInfo(entclass, "m_bInitialized"), 1);

	if (!DispatchSpawn(weapon)) 
	{
		LogError("The created weapon entity [Class name: %s, Item index: %i, Index: %i], failed to spawn! Skipping.", classname, itemindex, weapon);
		AcceptEntityInput(weapon, "Kill");
		return false;
	}

	if (slot > -1) {
		TF2_RemoveWeaponSlot(client, slot);
	}

	if (!wearable) 
	{
		SDKCall(g_hWeaponEquip, client, weapon);
	} 
	else 
	{
		SDKCall(g_hWWeaponEquip, client, weapon);
	}

	if ((slot > -1) && !wearable && (GetPlayerWeaponSlot(client, slot) != weapon)) {
		LogError("The created weapon entity [Class name: %s, Item index: %i, Index: %i], failed to equip! This is probably caused by invalid gamedata.", classname, itemindex, weapon);
		AcceptEntityInput(weapon, "Kill");
		return false;
	}

	return true;
}

public Action TimerHealth(Handle timer, any client)
{
	int hp = GetPlayerMaxHp(client);
	
	if (hp > 0)
	{
		SetEntityHealth(client, hp);
	}

	return Plugin_Continue;
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

bool IsPlayerHere(int client)
{
	return (client && IsClientInGame(client) && IsFakeClient(client));
}

int GetRandomUInt(int min, int max)
{
	return RoundToFloor(GetURandomFloat() * (max - min + 1)) + min;
}