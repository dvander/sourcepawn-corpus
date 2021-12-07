#include <sourcemod>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.10"

bool g_bTouched[MAXPLAYERS+1];
bool g_bSuddenDeathMode;
bool g_bMVM;
bool g_bLateLoad;
ConVar g_hCVTimer;
ConVar g_hCVEnabled;
ConVar g_hCVTeam;
Handle g_hWeaponEquip;
Handle g_hWWeaponEquip;
Handle g_hGameConfig;

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
	
	HookEvent("post_inventory_application", player_inv);
	HookEvent("teamplay_round_stalemate", EventSuddenDeath, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_start", EventRoundReset, EventHookMode_PostNoCopy);
	HookConVarChange(g_hCVEnabled, OnEnabledChanged);
	
	SetConVarString(hCVversioncvar, PLUGIN_VERSION);
	AutoExecConfig(true, "Give_Bots_Weapons");

	if (g_bLateLoad)
	{
		OnMapStart();
	}
	
	g_hGameConfig = LoadGameConfigFile("give.bots.weapons");
	
	if (!g_hGameConfig)
	{
		SetFailState("Failed to find give.bots.weapons.txt gamedata! Can't continue.");
	}	
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConfig, SDKConf_Virtual, "WeaponEquip");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hWeaponEquip = EndPrepSDKCall();
	
	if (!g_hWeaponEquip)
	{
		SetFailState("Failed to prepare the SDKCall for giving weapons. Try updating gamedata or restarting your server.");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConfig, SDKConf_Virtual, "EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hWWeaponEquip = EndPrepSDKCall();
	
	if (!g_hWWeaponEquip)
	{
		SetFailState("Failed to prepare the SDKCall for giving weapons. Try updating gamedata or restarting your server.");
	}
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
	g_bTouched[client] = false;
}

public void player_inv(Handle event, const char[] name, bool dontBroadcast) 
{
	if (!GetConVarBool(g_hCVEnabled))
	{
		return;
	}

	int userd = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userd);
	
	if (!g_bSuddenDeathMode && !g_bTouched[client] && !g_bMVM && IsPlayerHere(client))
	{
		g_bTouched[client] = true;
		int team = GetClientTeam(client);
		int team2 = GetConVarInt(g_hCVTeam);
		float timer = GetConVarFloat(g_hCVTimer);
		
		switch (team2)
		{
			case 1:
			{
				CreateTimer(timer, Timer_GiveWeapons, userd, TIMER_FLAG_NO_MAPCHANGE);
			}
			case 2:
			{
				if (team == 2)
				{
					CreateTimer(timer, Timer_GiveWeapons, userd, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
			case 3:
			{
				if (team == 3)
				{
					CreateTimer(timer, Timer_GiveWeapons, userd, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}
}

public Action Timer_GiveWeapons(Handle timer, any data)
{
	int client = GetClientOfUserId(data);
	g_bTouched[client] = false;
	
	if (!GetConVarBool(g_hCVEnabled) || !IsPlayerHere(client))
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

	if (!g_bSuddenDeathMode && !g_bMVM)
	{
		TFClassType class = TF2_GetPlayerClass(client);

		if (GameRules_GetProp("m_bPlayingMedieval") != 1)
		{
			switch (class)
			{
				case TFClass_Scout:
				{
					int rnd = GetRandomUInt(0,5);
					if(rnd != 0)
					{
						TF2_RemoveWeaponSlot(client, 0);
					}
					switch (rnd)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_scattergun", 45);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_handgun_scout_primary", 220);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_soda_popper", 448);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_pep_brawler_blaster", 772);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_scattergun", 1103);
						}
					}
					
					int rnd2 = GetRandomUInt(0,2);
					if(rnd2 != 0)
					{
						TF2_RemoveWeaponSlot(client, 1);
					}
					switch (rnd2)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_handgun_scout_secondary", 773);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_handgun_scout_secondary", 449);
						}
					}
					
					int rnd3 = GetRandomUInt(0,12);
					if(rnd3 != 0)
					{
						TF2_RemoveWeaponSlot(client, 2);
					}
					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_bat_wood", 44);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_bat_fish", 572, 42);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_bat", 317);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_bat", 349);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_bat", 355);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_bat_giftwrap", 648);
						}
						case 7:
						{
							CreateWeapon(client, "tf_weapon_bat", 450);
						}
						case 8:
						{
							CreateWeapon(client, "tf_weapon_bat_fish", 221);
						}
						case 9:
						{
							CreateWeapon(client, "tf_weapon_bat", 1013, 5);
						}
						case 10:
						{
							CreateWeapon(client, "tf_weapon_bat", 939, 5);
						}
						case 11:
						{
							CreateWeapon(client, "tf_weapon_bat", 880, 25);
						}
						case 12:
						{
							CreateWeapon(client, "tf_weapon_bat", 474, 25);
						}
					}
				}
				case TFClass_Sniper:
				{
					int rnd = GetRandomUInt(0,8);
					if(rnd != 0)
					{
						TF2_RemoveWeaponSlot(client, 0);
					}
					switch (rnd)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_compound_bow", 56);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_sniperrifle", 230);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_sniperrifle_decap", 402);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_sniperrifle", 526);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_sniperrifle", 752);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_sniperrifle_classic", 1098);
						}
						case 7:
						{
							CreateWeapon(client, "tf_weapon_compound_bow", 1092);
						}
						case 8:
						{
							CreateWeapon(client, "tf_weapon_sniperrifle", 851);
						}
					}
					
					int rnd2 = GetRandomUInt(0,1);
					if(rnd2 != 0)
					{
						TF2_RemoveWeaponSlot(client, 1);
					}
					switch (rnd2)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_smg", 751);
						}
					}
					
					int rnd3 = GetRandomUInt(0,7);
					if(rnd3 != 0)
					{
						TF2_RemoveWeaponSlot(client, 2);
					}
					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_club", 171);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_club", 232);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_club", 401);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_club", 1013, 5);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_club", 939, 5);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_club", 880, 25);
						}
						case 7:
						{
							CreateWeapon(client, "tf_weapon_club", 474, 25);
						}
					}			
				}
				case TFClass_Soldier:
				{
					int rnd = GetRandomUInt(0,6);
					if(rnd != 0)
					{
						TF2_RemoveWeaponSlot(client, 0);
					}
					switch (rnd)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_rocketlauncher_directhit", 127);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_rocketlauncher", 228);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_rocketlauncher", 414);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_particle_cannon", 441, 30);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_rocketlauncher", 513);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_rocketlauncher_airstrike", 1104);
						}						
					}
					
					int rnd2 = GetRandomUInt(0,3);
					if(rnd2 != 0)
					{
						TF2_RemoveWeaponSlot(client, 1);
					}
					switch (rnd2)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_raygun", 442, 30);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_shotgun_soldier", 1153);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_shotgun_soldier", 415);
						}
					}
					
					int rnd3 = GetRandomUInt(0,9);
					if(rnd3 != 0)
					{
						TF2_RemoveWeaponSlot(client, 2);
					}
					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_shovel", 128);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_shovel", 154);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_shovel", 447);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_shovel", 775);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_katana", 357);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_shovel", 1013, 5);
						}
						case 7:
						{
							CreateWeapon(client, "tf_weapon_shovel", 939, 5);
						}
						case 8:
						{
							CreateWeapon(client, "tf_weapon_shovel", 880, 25);
						}
						case 9:
						{
							CreateWeapon(client, "tf_weapon_shovel", 474, 25);
						}
					}
				}
				case TFClass_DemoMan:
				{
					int rnd = GetRandomUInt(0,2);
					if(rnd != 0)
					{
						TF2_RemoveWeaponSlot(client, 0);
					}
					switch (rnd)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_grenadelauncher", 308, 10);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_grenadelauncher", 1151);
						}
					}
					
					int rnd2 = GetRandomUInt(0,1);
					if(rnd2 != 0)
					{
						TF2_RemoveWeaponSlot(client, 1);
					}
					switch (rnd2)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_pipebomblauncher", 1150);
						}
					}
					
					int rnd3 = GetRandomUInt(0,12);
					if(rnd3 != 0)
					{
						TF2_RemoveWeaponSlot(client, 2);
					}
					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_sword", 132);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_shovel", 154);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_sword", 172);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_stickbomb", 307);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_sword", 327);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_katana", 357);
						}
						case 7:
						{
							CreateWeapon(client, "tf_weapon_sword", 482);
						}
						case 8:
						{
							CreateWeapon(client, "tf_weapon_bottle", 609);
						}
						case 9:
						{
							CreateWeapon(client, "tf_weapon_bottle", 1013, 5);
						}
						case 10:
						{
							CreateWeapon(client, "tf_weapon_bottle", 939, 5);
						}
						case 11:
						{
							CreateWeapon(client, "tf_weapon_bottle", 880, 25);
						}
						case 12:
						{
							CreateWeapon(client, "tf_weapon_bottle", 474, 25);
						}
					}				
				}
				case TFClass_Medic:
				{
					int rnd = GetRandomUInt(0,3);
					if(rnd != 0)
					{
						TF2_RemoveWeaponSlot(client, 0);
					}
					switch (rnd)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_syringegun_medic", 36, 5);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_crossbow", 305, 15);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_syringegun_medic", 412, 5);
						}
					}
					
					int rnd2 = GetRandomUInt(0,3);
					if(rnd2 != 0)
					{
						TF2_RemoveWeaponSlot(client, 1);
					}
					switch (rnd2)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_medigun", 35, 8);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_medigun", 411, 8);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_medigun", 998, 8);
						}
					}
					
					int rnd3 = GetRandomUInt(0,8);
					if(rnd3 != 0)
					{
						TF2_RemoveWeaponSlot(client, 2);
					}
					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 37, 10);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 173, 5);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 304, 15);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 413, 10);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 1013, 5);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 939, 5);
						}
						case 7:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 880, 25);
						}
						case 8:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 474, 25);
						}
					}			
				}
				case TFClass_Heavy:
				{
					int rnd = GetRandomUInt(0,4);
					if(rnd != 0)
					{
						TF2_RemoveWeaponSlot(client, 0);
					}
					switch (rnd)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_minigun", 41);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_minigun", 312);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_minigun", 424);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_minigun", 811);
						}
					}
					
					int rnd2 = GetRandomUInt(0,2);
					if(rnd2 != 0)
					{
						TF2_RemoveWeaponSlot(client, 1);
					}
					switch (rnd2)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_shotgun_hwg", 425);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_shotgun_hwg", 1153);
						}						
					}
					
					int rnd3 = GetRandomUInt(0,11);
					if(rnd3 != 0)
					{
						TF2_RemoveWeaponSlot(client, 2);
					}
					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_fists", 43);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_fists", 239);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_fists", 310);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_fists", 331);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_fists", 426);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_fists", 656);
						}
						case 7:
						{
							CreateWeapon(client, "tf_weapon_fists", 587);
						}
						case 8:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 1013, 5);
						}
						case 9:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 939, 5);
						}
						case 10:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 880, 25);
						}
						case 11:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 474, 25);
						}
					}						
				}
				case TFClass_Pyro:
				{
					int rnd = GetRandomUInt(0,6);
					if(rnd != 0)
					{
						TF2_RemoveWeaponSlot(client, 0);
					}
					switch (rnd)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_flamethrower", 40);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_flamethrower", 215);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_flamethrower", 594);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_flamethrower", 741);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_rocketlauncher_fireball", 1178);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_flamethrower", 30474, 25);
						}
					}
					
					int rnd2 = GetRandomUInt(0,6);
					if(rnd2 != 0)
					{
						TF2_RemoveWeaponSlot(client, 1);
					}
					switch (rnd2)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_flaregun", 39);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_flaregun", 351);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_flaregun_revenge", 595, 30);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_flaregun", 740);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_shotgun_pyro", 1153);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_shotgun_pyro", 415);
						}
					}
					
					int rnd3 = GetRandomUInt(0,15);
					if(rnd3 != 0)
					{
						TF2_RemoveWeaponSlot(client, 2);
					}
					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 38);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 153);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 214);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 326);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 348);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 593);
						}
						case 7:
						{
							CreateWeapon(client, "tf_weapon_breakable_sign", 813);
						}
						case 8:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 457);
						}
						case 9:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 739);
						}
						case 10:
						{
							CreateWeapon(client, "tf_weapon_slap", 1181);
						}
						case 11:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 466);
						}
						case 12:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 1013, 5);
						}
						case 13:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 939, 5);
						}
						case 14:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 880, 25);
						}
						case 15:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 474, 25);
						}
					}			
				}
				case TFClass_Spy:
				{
					int rnd = GetRandomUInt(0,4);
					if(rnd != 0)
					{
						TF2_RemoveWeaponSlot(client, 0);
					}
					switch (rnd)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_revolver", 61, 5);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_revolver", 224, 5);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_revolver", 460, 5);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_revolver", 525, 5);
						}					
					}
					
					int rnd2 = GetRandomUInt(0,1);
					if(rnd2 != 0)
					{
						TF2_RemoveWeaponSlot(client, 1);
					}
					switch (rnd2)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_sapper", 810);
						}
					}
					
					int rnd3 = GetRandomUInt(0,6);
					if(rnd3 != 0)
					{
						TF2_RemoveWeaponSlot(client, 2);
					}
					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_knife", 356);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_knife", 461);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_knife", 649);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_knife", 638);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_knife", 225);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_knife", 574);
						}
					}
					int rnd4 = GetRandomUInt(0,1);
					if(rnd4 != 0)
					{
						TF2_RemoveWeaponSlot(client, 4);
					}
					switch (rnd4)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_invis", 947);
						}
					}					
				}
				case TFClass_Engineer:
				{
					int rnd = GetRandomUInt(0,4);
					if(rnd != 0)
					{
						TF2_RemoveWeaponSlot(client, 0);
					}
					switch (rnd)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_sentry_revenge", 141, 5);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_shotgun_building_rescue", 997);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_drg_pomson", 588, 10);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_shotgun_primary", 1153);
						}						
					}
					
					int rnd3 = GetRandomUInt(0,4);
					if(rnd3 != 0)
					{
						TF2_RemoveWeaponSlot(client, 2);
					}
					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_wrench", 155, 20);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_wrench", 329, 15);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_wrench", 589, 20);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_robot_arm", 142, 15);
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
					int rnd3 = GetRandomUInt(0,12);
					if(rnd3 != 0)
					{
						TF2_RemoveWeaponSlot(client, 2);
					}
					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_bat_wood", 44);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_bat_fish", 572);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_bat", 317);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_bat", 349);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_bat", 355);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_bat_giftwrap", 648);
						}
						case 7:
						{
							CreateWeapon(client, "tf_weapon_bat", 450);
						}
						case 8:
						{
							CreateWeapon(client, "tf_weapon_bat_fish", 221, 42);
						}
						case 9:
						{
							CreateWeapon(client, "tf_weapon_bat", 1013, 5);
						}
						case 10:
						{
							CreateWeapon(client, "tf_weapon_bat", 939, 5);
						}
						case 11:
						{
							CreateWeapon(client, "tf_weapon_bat", 880, 25);
						}
						case 12:
						{
							CreateWeapon(client, "tf_weapon_bat", 474, 25);
						}
					}
				}
				case TFClass_Sniper:
				{
					int rnd2 = GetRandomUInt(0,3);
					if(rnd2 != 0)
					{
						TF2_RemoveWeaponSlot(client, 1);
					}
					switch (rnd2)
					{
						case 1:
						{
							CreateWWeapon(client, "tf_wearable", 57);
						}
						case 2:
						{
							CreateWWeapon(client, "tf_wearable", 231);
						}
						case 3:
						{
							CreateWWeapon(client, "tf_wearable", 642);
						}
					}
					
					int rnd3 = GetRandomUInt(0,7);
					if(rnd3 != 0)
					{
						TF2_RemoveWeaponSlot(client, 2);
					}
					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_club", 171);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_club", 232);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_club", 401);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_club", 1013, 5);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_club", 939, 5);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_club", 880, 25);
						}
						case 7:
						{
							CreateWeapon(client, "tf_weapon_club", 474, 25);
						}
					}			
				}
				case TFClass_Soldier:
				{
					int rnd2 = GetRandomUInt(0,2);
					if(rnd2 != 0)
					{
						TF2_RemoveWeaponSlot(client, 1);
					}
					switch (rnd2)
					{
						case 1:
						{
							CreateWWeapon(client, "tf_wearable", 133);
						}
						case 2:
						{
							CreateWWeapon(client, "tf_wearable", 444);
						}
					}
					
					int rnd3 = GetRandomUInt(0,9);
					if(rnd3 != 0)
					{
						TF2_RemoveWeaponSlot(client, 2);
					}
					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_shovel", 128);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_shovel", 154);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_shovel", 447);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_shovel", 775);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_katana", 357);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_shovel", 1013, 5);
						}
						case 7:
						{
							CreateWeapon(client, "tf_weapon_shovel", 939, 5);
						}
						case 8:
						{
							CreateWeapon(client, "tf_weapon_shovel", 880, 25);
						}
						case 9:
						{
							CreateWeapon(client, "tf_weapon_shovel", 474, 25);
						}
					}
				}
				case TFClass_DemoMan:
				{
					int rnd = GetRandomUInt(0,2);
					if(rnd != 0)
					{
						TF2_RemoveWeaponSlot(client, 0);
					}
					switch (rnd)
					{
						case 1:
						{
							CreateWWeapon(client, "tf_wearable", 405);
						}
						case 2:
						{
							CreateWWeapon(client, "tf_wearable", 608);
						}
					}				

					int rnd2 = GetRandomUInt(0,3);
					if(rnd2 != 0)
					{
						TF2_RemoveWeaponSlot(client, 1);
					}
					switch (rnd2)
					{
						case 1:
						{
							CreateWWeapon(client, "tf_wearable_demoshield", 131);
						}
						case 2:
						{
							CreateWWeapon(client, "tf_wearable_demoshield", 406);
						}
						case 3:
						{
							CreateWWeapon(client, "tf_wearable_demoshield", 1099);
						}
					}				
				
					int rnd3 = GetRandomUInt(0,13);
					if(rnd3 != 0)
					{
						TF2_RemoveWeaponSlot(client, 2);
					}
					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_sword", 132);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_shovel", 154);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_sword", 172);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_stickbomb", 307);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_sword", 327);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_katana", 357);
						}
						case 7:
						{
							CreateWeapon(client, "tf_weapon_sword", 482);
						}
						case 8:
						{
							CreateWeapon(client, "tf_weapon_bottle", 609);
						}
						case 9:
						{
							CreateWeapon(client, "tf_weapon_bottle", 1013, 5);
						}
						case 10:
						{
							CreateWeapon(client, "tf_weapon_bottle", 939, 5);
						}
						case 11:
						{
							CreateWeapon(client, "tf_weapon_bottle", 880, 25);
						}
						case 12:
						{
							CreateWeapon(client, "tf_weapon_bottle", 474, 25);
						}
						case 13:
						{						
							CreateWeapon(client, "tf_weapon_sword", 404);							
						}
					}
				}
				case TFClass_Medic:
				{
					int rnd3 = GetRandomUInt(0,8);
					if(rnd3 != 0)
					{
						TF2_RemoveWeaponSlot(client, 2);
					}
					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 37, 10);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 173, 5);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 304, 15);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 413, 10);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 1013, 5);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 939, 5);
						}
						case 7:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 880, 25);
						}
						case 8:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 474, 25);
						}
					}			
				}
				case TFClass_Heavy:
				{
					int rnd3 = GetRandomUInt(0,11);
					if(rnd3 != 0)
					{
						TF2_RemoveWeaponSlot(client, 2);
					}
					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_fists", 43);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_fists", 239);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_fists", 310);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_fists", 331);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_fists", 426);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_fists", 656);
						}
						case 7:
						{
							CreateWeapon(client, "tf_weapon_fists", 587);
						}
						case 8:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 1013, 5);
						}
						case 9:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 939, 5);
						}
						case 10:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 880, 25);
						}
						case 11:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 474, 25);
						}
					}						
				}
				case TFClass_Pyro:
				{
					int rnd3 = GetRandomUInt(0,15);
					if(rnd3 != 0)
					{
						TF2_RemoveWeaponSlot(client, 2);
					}
					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 38);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 153);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 214);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 326);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 348);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 593);
						}
						case 7:
						{
							CreateWeapon(client, "tf_weapon_breakable_sign", 813);
						}
						case 8:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 457);
						}
						case 9:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 739);
						}
						case 10:
						{
							CreateWeapon(client, "tf_weapon_slap", 1181);
						}
						case 11:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 466);
						}
						case 12:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 1013, 5);
						}
						case 13:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 939, 5);
						}
						case 14:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 880, 25);
						}
						case 15:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 474, 25);
						}
					}			
				}
				case TFClass_Spy:
				{
					int rnd3 = GetRandomUInt(0,6);
					if(rnd3 != 0)
					{
						TF2_RemoveWeaponSlot(client, 2);
					}
					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_knife", 356);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_knife", 461);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_knife", 649);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_knife", 638);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_knife", 225);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_knife", 574);
						}
					}
					int rnd4 = GetRandomUInt(0,1);
					if(rnd4 != 0)
					{
						TF2_RemoveWeaponSlot(client, 4);
					}
					switch (rnd4)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_invis", 947);
						}
					}					
				}
				case TFClass_Engineer:
				{
					int rnd3 = GetRandomUInt(0,4);
					if(rnd3 != 0)
					{
						TF2_RemoveWeaponSlot(client, 2);
					}
					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_wrench", 155, 20);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_wrench", 329, 15);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_wrench", 589, 20);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_robot_arm", 142, 15);
						}					
					}	
				}
			}
		}
	}
}

public void EventSuddenDeath(Handle event, const char[] name, bool dontBroadcast)
{
	g_bSuddenDeathMode = true;
}

public void EventRoundReset(Handle event, const char[] name, bool dontBroadcast)
{
	g_bSuddenDeathMode = false;
}

bool CreateWeapon(int client, char[] classname, int itemindex, int level = 0)
{
	int weapon = CreateEntityByName(classname);
	
	if (!IsValidEntity(weapon))
	{
		return false;
	}
	
	char entclass[64];
	GetEntityNetClass(weapon, entclass, sizeof(entclass));
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iItemDefinitionIndex"), itemindex);	 
	SetEntData(weapon, FindSendPropInfo(entclass, "m_bInitialized"), 1);
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
		}
		case 998:
		{
			SetEntData(weapon, FindSendPropInfo(entclass, "m_nChargeResistType"), GetRandomUInt(0,2));
		}
	}
	
	DispatchSpawn(weapon);
	SDKCall(g_hWeaponEquip, client, weapon);
	return true;
} 

bool CreateWWeapon(int client, char[] classname, int itemindex, int level = 0)
{
	int weapon = CreateEntityByName(classname);
	
	if (!IsValidEntity(weapon))
	{
		return false;
	}
	
	char entclass[64];
	GetEntityNetClass(weapon, entclass, sizeof(entclass));
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iItemDefinitionIndex"), itemindex);	 
	SetEntData(weapon, FindSendPropInfo(entclass, "m_bInitialized"), 1);
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 6);

	if (level)
	{
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	}
	else
	{
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityLevel"), GetRandomUInt(1,99));
	}	
	
	DispatchSpawn(weapon);
	SDKCall(g_hWWeaponEquip, client, weapon);
	CreateTimer(0.1, TimerHealth, client, TIMER_FLAG_NO_MAPCHANGE);
	return true;
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

bool IsPlayerHere(int client)
{
	return (client && IsClientInGame(client) && IsFakeClient(client));
}

int GetRandomUInt(int min, int max)
{
	return RoundToFloor(GetURandomFloat() * (max - min + 1)) + min;
}