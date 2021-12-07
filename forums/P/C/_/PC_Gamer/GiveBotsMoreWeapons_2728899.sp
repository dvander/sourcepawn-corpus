#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.10"

bool g_bMVM;
bool g_bMedieval;
bool g_bLateLoad;
ConVar g_hCVTimer;
ConVar g_hCVEnabled;
ConVar g_hCVTeam;
Handle g_hEquipWearable;

public Plugin myinfo = 
{
	name = "Give Bots More Weapons",
	author = "PC Gamer, with code by luki1412 and manicogaming, edited by That Annoying Guide",
	description = "Gives TF2 bots more non-stock weapons",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net"
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
	ConVar hCVversioncvar = CreateConVar("sm_gbmw_version", PLUGIN_VERSION, "Give Bots Weapons version cvar", FCVAR_NOTIFY|FCVAR_DONTRECORD); 
	g_hCVEnabled = CreateConVar("sm_gbmw_enabled", "1", "Enables/disables this plugin", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCVTimer = CreateConVar("sm_gbmw_delay", "0.2", "Delay for giving weapons to bots", FCVAR_NONE, true, 0.1, true, 30.0);
	g_hCVTeam = CreateConVar("sm_gbmw_team", "1", "Team to give weapons to: 1-both, 2-red, 3-blu", FCVAR_NONE, true, 1.0, true, 3.0);
	
	HookEvent("post_inventory_application", player_inv);
	HookConVarChange(g_hCVEnabled, OnEnabledChanged);
	
	SetConVarString(hCVversioncvar, PLUGIN_VERSION);

	if (g_bLateLoad)
	{
		OnMapStart();
	}
	
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
	
	if (GameRules_GetProp("m_bPlayingMedieval"))
	{
		g_bMedieval = true;
	}	
}

public void player_inv(Handle event, const char[] name, bool dontBroadcast) 
{
	if (!GetConVarBool(g_hCVEnabled))
	{
		return;
	}

	int userd = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userd);

	if (!g_bMVM && IsPlayerHere(client))
	{
		int team = GetClientTeam(client);
		int team2 = GetConVarInt(g_hCVTeam);
		float timer = GetConVarFloat(g_hCVTimer);
		
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
		
		CreateTimer(timer, Timer_GiveWeapons, userd);
	}
}

public Action Timer_GiveWeapons(Handle timer, any data)
{
	int client = GetClientOfUserId(data);
	
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

	if (!g_bMVM)
	{
		TFClassType class = TF2_GetPlayerClass(client);

		switch (class)
		{
		case TFClass_Scout:
			{
				if (!g_bMedieval)
				{
					int rnd = GetRandomUInt(1,6);
					TF2_RemoveWeaponSlot(client, 0);

					switch (rnd)
					{
					case 1:
						{
							int rnd8 = GetRandomUInt(1,3);
							switch (rnd8)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_scattergun", 45, 6);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_scattergun", 1078, 6);
								}
							case 3:
								{
									CreateWeapon(client, "tf_weapon_scattergun", 45, 9);
								}
							}
						}
					case 2:
						{
							int rnd6 = GetRandomUInt(1,2);
							switch (rnd6)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_handgun_scout_primary", 220, 6);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_handgun_scout_primary", 220, 16);
								}
							}
						}
					case 3:
						{
							int rnd7 = GetRandomUInt(1,2);
							switch (rnd7)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_soda_popper", 448, 6);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_soda_popper", 448, 16);
								}
							}
						}
					case 4:
						{
							CreateWeapon(client, "tf_weapon_pep_brawler_blaster", 772, 6);
						}
					case 5:
						{
							CreateWeapon(client, "tf_weapon_scattergun", 1103, 6);
						}
					case 6:
						{
							int rnd8 = GetRandomUInt(1,7);
							switch (rnd8)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_scattergun", 13, 5);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_scattergun", 669, 6);
								}
							case 3:
								{
									CreateWeapon(client, "tf_weapon_scattergun", 200, 9);
								}
							case 4:
								{
									CreateWeapon(client, "tf_weapon_scattergun", 200, 16);
								}
							case 5:
								{
									CreateWeapon(client, "tf_weapon_scattergun", 200, 11);
								}
							case 6:
								{
									int rnd9 = GetRandomUInt(1,8);
									switch (rnd9)
									{
									case 1:
										{
											CreateWeapon(client, "tf_weapon_scattergun", 799, 11);
										}
									case 2:
										{
											CreateWeapon(client, "tf_weapon_scattergun", 808, 11);
										}
									case 3:
										{
											CreateWeapon(client, "tf_weapon_scattergun", 888, 11);
										}
									case 4:
										{
											CreateWeapon(client, "tf_weapon_scattergun", 897, 11);
										}
									case 5:
										{
											CreateWeapon(client, "tf_weapon_scattergun", 906, 11);
										}
									case 6:
										{
											CreateWeapon(client, "tf_weapon_scattergun", 915, 11);
										}
									case 7:
										{
											CreateWeapon(client, "tf_weapon_scattergun", 964, 11);
										}
									case 8:
										{
											CreateWeapon(client, "tf_weapon_scattergun", 973, 11);
										}
									}
								}
							case 7:
								{
									int rnd10 = GetRandomUInt(1,14);
									switch (rnd10)
									{
									case 1:
										{
											CreateWeapon(client, "tf_weapon_scattergun", 15002, 15);
										}
									case 2:
										{
											CreateWeapon(client, "tf_weapon_scattergun", 15015, 15);
										}
									case 3:
										{
											CreateWeapon(client, "tf_weapon_scattergun", 15029, 15);
										}
									case 4:
										{
											CreateWeapon(client, "tf_weapon_scattergun", 15036, 15);
										}
									case 5:
										{
											CreateWeapon(client, "tf_weapon_scattergun", 15053, 15);
										}
									case 6:
										{
											CreateWeapon(client, "tf_weapon_scattergun", 15065, 11);
										}
									case 7:
										{
											CreateWeapon(client, "tf_weapon_scattergun", 15069, 15);
										}
									case 8:
										{
											CreateWeapon(client, "tf_weapon_scattergun", 15106, 15);
										}
									case 9:
										{
											CreateWeapon(client, "tf_weapon_scattergun", 15107, 15);
										}
									case 10:
										{
											CreateWeapon(client, "tf_weapon_scattergun", 15108, 15);
										}
									case 11:
										{
											CreateWeapon(client, "tf_weapon_scattergun", 15131, 15);
										}
									case 12:
										{
											CreateWeapon(client, "tf_weapon_scattergun", 15151, 15);
										}
									case 13:
										{
											CreateWeapon(client, "tf_weapon_scattergun", 15157, 15);
										}
									case 14:
										{
											CreateWeapon(client, "tf_weapon_scattergun", 15021, 15);
										}
									}
								}
							}
						}
					}
					
					int rnd2 = GetRandomUInt(1,7);
					TF2_RemoveWeaponSlot(client, 1);
					
					switch (rnd2)
					{
					case 1:
						{
							CreateWeapon(client, "tf_weapon_handgun_scout_secondary", 773, 6);
						}
					case 2:
						{
							int rnd14 = GetRandomUInt(1,2);
							switch (rnd14)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_handgun_scout_secondary", 449, 6);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_handgun_scout_secondary", 449, 16);
								}
							}
						}
					case 3:
						{
							int rnd800 = GetRandomUInt(1,2);
							switch (rnd800)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_cleaver", 812, 6);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_cleaver", 833, 3);
								}
							}
						}
					case 4:
						{
							int rnd8 = GetRandomUInt(1,2);
							switch (rnd8)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_lunchbox_drink", 46, 6);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_lunchbox_drink", 1145, 6);
								}
							}
						}
					case 5:
						{
							CreateWeapon(client, "tf_weapon_lunchbox_drink", 163, 6);
						}
					case 6:
						{
							int rnd9 = GetRandomUInt(1,2);
							switch (rnd9)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_jar_milk", 222, 6);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_jar_milk", 1121, 6);
								}
							}
						}
					case 7:
						{
							int rnd3 = GetRandomUInt(1,5);
							switch (rnd3)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_pistol", 23, 5);
								}
							case 2:
								{
									int rnd7 = GetRandomUInt(1,2);
									switch (rnd7)
									{
									case 1:
										{
											CreateWeapon(client, "tf_weapon_pistol", 160, 3);
										}
									case 2:
										{
											CreateWeapon(client, "tf_weapon_pistol", 294, 6);
										}
									}
								}
							case 3:
								{
									CreateWeapon(client, "tf_weapon_pistol", 30666, 6);
								}
							case 4:
								{
									CreateWeapon(client, "tf_weapon_pistol", 209, 16);
								}
							case 5:
								{
									int rnd7 = GetRandomUInt(1,13);
									switch (rnd7)
									{
									case 1:
										{
											CreateWeapon(client, "tf_weapon_pistol", 15013, 15);
										}
									case 2:
										{
											CreateWeapon(client, "tf_weapon_pistol", 15018, 15);
										}
									case 3:
										{
											CreateWeapon(client, "tf_weapon_pistol", 15035, 15);
										}
									case 4:
										{
											CreateWeapon(client, "tf_weapon_pistol", 15041, 15);
										}
									case 5:
										{
											CreateWeapon(client, "tf_weapon_pistol", 15046, 15);
										}
									case 6:
										{
											CreateWeapon(client, "tf_weapon_pistol", 15056, 15);
										}
									case 7:
										{
											CreateWeapon(client, "tf_weapon_pistol", 15060, 15);
										}
									case 8:
										{
											CreateWeapon(client, "tf_weapon_pistol", 15061, 15);
										}
									case 9:
										{
											CreateWeapon(client, "tf_weapon_pistol", 15100, 15);
										}
									case 10:
										{
											CreateWeapon(client, "tf_weapon_pistol", 15101, 15);
										}
									case 11:
										{
											CreateWeapon(client, "tf_weapon_pistol", 15102, 15);
										}
									case 12:
										{
											CreateWeapon(client, "tf_weapon_pistol", 15126, 15);
										}
									case 13:
										{
											CreateWeapon(client, "tf_weapon_pistol", 15148, 15);
										}
									}
								}
							}
						}
					}
				}
				
				int rnd3 = GetRandomUInt(1,9);
				TF2_RemoveWeaponSlot(client, 2);
				
				switch (rnd3)
				{
				case 1:
					{
						CreateWeapon(client, "tf_weapon_bat_wood", 44, 6);
					}
				case 2:
					{
						int rnd6 = GetRandomUInt(1,2);
						switch (rnd6)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_bat", 325, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_bat", 452, 6);
							}
						}
					}
				case 3:
					{
						CreateWeapon(client, "tf_weapon_bat", 317, 6);
					}
				case 4:
					{
						CreateWeapon(client, "tf_weapon_bat", 349, 6);
					}
				case 5:
					{
						CreateWeapon(client, "tf_weapon_bat", 355, 6);
					}
				case 6:
					{
						CreateWeapon(client, "tf_weapon_bat_giftwrap", 648, 6);
					}
				case 7:
					{
						CreateWeapon(client, "tf_weapon_bat", 450, 6);
					}
				case 8:
					{
						int rnd24 = GetRandomUInt(1,4);
						switch (rnd24)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_bat_fish", 221, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_bat_fish", 572, 6);
							}
						case 3:
							{
								CreateWeapon(client, "tf_weapon_bat_fish", 999, 6);
							}
						case 4:
							{
								CreateWeapon(client, "tf_weapon_bat_fish", 221, 16);
							}
						}
					}
				case 9:
					{
						int rnd7 = GetRandomUInt(1,14);
						switch (rnd7)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_bat", 190, 11);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_bat", 264, 6);
							}
						case 3:
							{
								CreateWeapon(client, "tf_weapon_bat", 423, 11);
							}
						case 4:
							{
								CreateWeapon(client, "tf_weapon_bat", 474, 6);
							}
						case 5:
							{
								CreateWeapon(client, "tf_weapon_bat", 880, 6);
							}
						case 6:
							{
								CreateWeapon(client, "tf_weapon_bat", 939, 6);
							}
						case 7:
							{
								CreateWeapon(client, "tf_weapon_bat", 954, 11);
							}
						case 8:
							{
								CreateWeapon(client, "tf_weapon_bat", 1013, 6);
							}
						case 9:
							{
								CreateWeapon(client, "tf_weapon_bat", 1071, 11);
							}
						case 10:
							{
								CreateWeapon(client, "tf_weapon_bat", 1123, 6);
							}
						case 11:
							{
								CreateWeapon(client, "tf_weapon_bat", 1127, 6);
							}
						case 12:
							{
								CreateWeapon(client, "tf_weapon_bat", 30667, 15);
							}
						case 13:
							{
								CreateWeapon(client, "tf_weapon_bat", 30758, 6);
							}
						case 14:
							{
								CreateWeapon(client, "tf_weapon_bat", 660, 6);
							}
						}
					}
				}
			}
			
		case TFClass_Sniper:
			{
				if (!g_bMedieval)
				{
					int rnd = GetRandomUInt(1,7);
					TF2_RemoveWeaponSlot(client, 0);
					
					switch (rnd)
					{
					case 1:
						{
							int rnd5 = GetRandomUInt(1,3);
							switch (rnd5)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_compound_bow", 56, 6);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_compound_bow", 1092, 6);
								}
							case 3:
								{
									CreateWeapon(client, "tf_weapon_compound_bow", 1005, 6);
								}
							}
						}
					case 2:
						{
							CreateWeapon(client, "tf_weapon_sniperrifle", 230, 6);
						}
					case 3:
						{
							int rnd11 = GetRandomUInt(1,2);
							switch (rnd11)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_sniperrifle_decap", 402, 6);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_sniperrifle_decap", 402, 16);
								}
							}
						}
					case 4:
						{
							int rnd6 = GetRandomUInt(1,2);
							switch (rnd6)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_sniperrifle", 526, 6);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_sniperrifle", 30665, 15);
								}
							}
						}
					case 5:
						{
							CreateWeapon(client, "tf_weapon_sniperrifle", 752, 6);
						}
					case 6:
						{
							CreateWeapon(client, "tf_weapon_sniperrifle_classic", 1098, 6);
						}
					case 7:
						{
							int rnd4 = GetRandomUInt(1,7);
							switch (rnd4)
							{     
							case 1:
								{
									CreateWeapon(client, "tf_weapon_sniperrifle", 14, 5);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_sniperrifle", 851, 6);
								}
							case 3:
								{
									CreateWeapon(client, "tf_weapon_sniperrifle", 664, 6);
								}
							case 4:
								{
									int rnd10 = GetRandomUInt(1,8);
									switch (rnd10)
									{
									case 1:
										{
											CreateWeapon(client, "tf_weapon_sniperrifle", 792, 11);
										}
									case 2:
										{
											CreateWeapon(client, "tf_weapon_sniperrifle", 801, 11);
										}
									case 3:
										{
											CreateWeapon(client, "tf_weapon_sniperrifle", 881, 11);
										}
									case 4:
										{
											CreateWeapon(client, "tf_weapon_sniperrifle", 890, 11);
										}
									case 5:
										{
											CreateWeapon(client, "tf_weapon_sniperrifle", 899, 11);
										}
									case 6:
										{
											CreateWeapon(client, "tf_weapon_sniperrifle", 908, 11);
										}
									case 7:
										{
											CreateWeapon(client, "tf_weapon_sniperrifle", 957, 11);
										}
									case 8:
										{
											CreateWeapon(client, "tf_weapon_sniperrifle", 966, 11);
										}
									}
								}
							case 5:
								{
									int rnd11 = GetRandomUInt(1,14);
									switch (rnd11)
									{
									case 1:
										{
											CreateWeapon(client, "tf_weapon_sniperrifle", 15000, 15);
										}
									case 2:
										{
											CreateWeapon(client, "tf_weapon_sniperrifle", 15007, 15);
										}
									case 3:
										{
											CreateWeapon(client, "tf_weapon_sniperrifle", 15019, 15);
										}
									case 4:
										{
											CreateWeapon(client, "tf_weapon_sniperrifle", 15023, 15);
										}
									case 5:
										{
											CreateWeapon(client, "tf_weapon_sniperrifle", 15033, 15);
										}
									case 6:
										{
											CreateWeapon(client, "tf_weapon_sniperrifle", 15059, 15);
										}
									case 7:
										{
											CreateWeapon(client, "tf_weapon_sniperrifle", 15070, 15);
										}
									case 8:
										{
											CreateWeapon(client, "tf_weapon_sniperrifle", 15071, 15);
										}
									case 9:
										{
											CreateWeapon(client, "tf_weapon_sniperrifle", 15072, 15);
										}
									case 10:
										{
											CreateWeapon(client, "tf_weapon_sniperrifle", 15111, 15);
										}
									case 11:
										{
											CreateWeapon(client, "tf_weapon_sniperrifle", 15112, 15);
										}
									case 12:
										{
											CreateWeapon(client, "tf_weapon_sniperrifle", 15135, 15);
										}
									case 13:
										{
											CreateWeapon(client, "tf_weapon_sniperrifle", 15136, 15);
										}
									case 14:
										{
											CreateWeapon(client, "tf_weapon_sniperrifle", 15154, 15);
										}
									}
								}
							case 6:
								{
									CreateWeapon(client, "tf_weapon_sniperrifle", 201, 11);
								}
							case 7:
								{
									CreateWeapon(client, "tf_weapon_sniperrifle", 201, 9);
								}
							}
						}				
					}
					
					int rnd2 = GetRandomUInt(1,6);
					TF2_RemoveWeaponSlot(client, 1);

					switch (rnd2)
					{
					case 1:
						{
							CreateWeapon(client, "tf_weapon_charged_smg", 751, 6);
						}
					case 2:
						{
							int rnd7 = GetRandomUInt(1,3);
							switch (rnd7)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_jar", 58, 6);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_jar", 1105, 6);
								}
							case 3:
								{
									CreateWeapon(client, "tf_weapon_jar", 1083, 6);
								}
							}
						}
					case 3:
						{
							CreateWeapon(client, "tf_wearable_razorback", 57, 6);
						}
					case 4:
						{
							CreateWeapon(client, "tf_wearable", 231, 6);
						}
					case 5:
						{
							CreateWeapon(client, "tf_wearable", 642, 6);
						}
					case 6:
						{
							int rnd6 = GetRandomUInt(1,6);
							switch (rnd6)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_smg", 16, 5);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_smg", 1149, 6);
								}
							case 3:
								{
									int rnd10 = GetRandomUInt(1,9);
									switch (rnd10)
									{
									case 1:
										{
											CreateWeapon(client, "tf_weapon_smg", 15001, 15);
										}
									case 2:
										{
											CreateWeapon(client, "tf_weapon_smg", 15022, 15);
										}
									case 3:
										{
											CreateWeapon(client, "tf_weapon_smg", 15032, 15);
										}
									case 4:
										{
											CreateWeapon(client, "tf_weapon_smg", 15037, 15);
										}
									case 5:
										{
											CreateWeapon(client, "tf_weapon_smg", 15058, 15);
										}
									case 6:
										{
											CreateWeapon(client, "tf_weapon_smg", 15076, 15);
										}
									case 7:
										{
											CreateWeapon(client, "tf_weapon_smg", 15110, 15);
										}
									case 8:
										{
											CreateWeapon(client, "tf_weapon_smg", 15134, 15);
										}
									case 9:
										{
											CreateWeapon(client, "tf_weapon_smg", 15153, 15);
										}
									}
								}
							case 4:
								{
									CreateWeapon(client, "tf_weapon_smg", 203, 11);
								}
							case 5:
								{
									CreateWeapon(client, "tf_weapon_smg", 203, 9);
								}
							case 6:
								{
									CreateWeapon(client, "tf_weapon_smg", 203, 16);
								}
							}
						}
					}
				}
				
				int rnd3 = GetRandomUInt(1,4);
				TF2_RemoveWeaponSlot(client, 2);

				switch (rnd3)
				{
				case 1:
					{
						CreateWeapon(client, "tf_weapon_club", 171, 6);
					}
				case 2:
					{
						CreateWeapon(client, "tf_weapon_club", 232, 6);
					}
				case 3:
					{
						int rnd6 = GetRandomUInt(1,2);
						switch (rnd6)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_club", 401, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_club", 401, 16);
							}
						}
					}
				case 4:
					{
						int rnd8 = GetRandomUInt(1,13);
						switch (rnd8)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_club", 3, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_club", 264, 6);
							}
						case 3:
							{
								CreateWeapon(client, "tf_weapon_club", 423, 11);
							}
						case 4:
							{
								CreateWeapon(client, "tf_weapon_club", 474, 6);
							}
						case 5:
							{
								CreateWeapon(client, "tf_weapon_club", 880, 6);
							}
						case 6:
							{
								CreateWeapon(client, "tf_weapon_club", 939, 6);
							}
						case 7:
							{
								CreateWeapon(client, "tf_weapon_club", 954, 11);
							}
						case 8:
							{
								CreateWeapon(client, "tf_weapon_club", 1013, 6);
							}
						case 9:
							{
								CreateWeapon(client, "tf_weapon_club", 1071, 11);
							}
						case 10:
							{
								CreateWeapon(client, "tf_weapon_club", 1123, 6);
							}
						case 11:
							{
								CreateWeapon(client, "tf_weapon_club", 1127, 6);
							}
						case 12:
							{
								CreateWeapon(client, "tf_weapon_club", 30758, 6);
							}
						case 13:
							{
								CreateWeapon(client, "tf_weapon_club", 193, 11);
							}
						}
					}					
				}			
			}
			
		case TFClass_Soldier:
			{
				if (!g_bMedieval)
				{
					int rnd = GetRandomUInt(1,8);
					TF2_RemoveWeaponSlot(client, 0);

					switch (rnd)
					{
					case 1:
						{
							CreateWeapon(client, "tf_weapon_rocketlauncher_directhit", 127, 6);
						}
					case 2:
						{
							int rnd4 = GetRandomUInt(1,4);
							switch (rnd4)
							{     
							case 1:
								{
									CreateWeapon(client, "tf_weapon_rocketlauncher", 228, 6);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_rocketlauncher", 1085, 6);
								}
							case 3:
								{
									CreateWeapon(client, "tf_weapon_rocketlauncher", 228, 9);
								}
							case 4:
								{
									CreateWeapon(client, "tf_weapon_rocketlauncher", 228, 16);
								}
							}
						}
					case 3:
						{
							CreateWeapon(client, "tf_weapon_rocketlauncher", 414, 6);
						}
					case 4:
						{
							CreateWeapon(client, "tf_weapon_particle_cannon", 441, 6);
						}
					case 5:
						{
							CreateWeapon(client, "tf_weapon_rocketlauncher", 513, 6);
						}
					case 6:
						{
							int rnd4 = GetRandomUInt(1,2);
							switch (rnd4)
							{     
							case 1:
								{
									CreateWeapon(client, "tf_weapon_rocketlauncher_airstrike", 1104, 6);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_rocketlauncher_airstrike", 1104, 16);
								}
							}
						}
					case 7:
						{
							CreateWeapon(client, "tf_weapon_rocketlauncher", 730, 6);
						}
					case 8:
						{
							int rnd4 = GetRandomUInt(1,6);
							switch (rnd4)
							{     
							case 1:
								{
									CreateWeapon(client, "tf_weapon_rocketlauncher", 18, 5);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_rocketlauncher", 658, 6);
								}
							case 3:
								{
									int rnd11 = GetRandomUInt(1,8);
									switch (rnd11)
									{
									case 1:
										{
											CreateWeapon(client, "tf_weapon_rocketlauncher", 800, 11);
										}
									case 2:
										{
											CreateWeapon(client, "tf_weapon_rocketlauncher", 809, 11);
										}
									case 3:
										{
											CreateWeapon(client, "tf_weapon_rocketlauncher", 889, 11);
										}
									case 4:
										{
											CreateWeapon(client, "tf_weapon_rocketlauncher", 898, 11);
										}
									case 5:
										{
											CreateWeapon(client, "tf_weapon_rocketlauncher", 907, 11);
										}
									case 6:
										{
											CreateWeapon(client, "tf_weapon_rocketlauncher", 916, 11);
										}
									case 7:
										{
											CreateWeapon(client, "tf_weapon_rocketlauncher", 965, 11);
										}
									case 8:
										{
											CreateWeapon(client, "tf_weapon_rocketlauncher", 974, 11);
										}
									}
								}
							case 4:
								{
									int rnd12 = GetRandomUInt(1,12);
									switch (rnd12)
									{
									case 1:
										{
											CreateWeapon(client, "tf_weapon_rocketlauncher", 15006, 15);
										}
									case 2:
										{
											CreateWeapon(client, "tf_weapon_rocketlauncher", 15014, 15);
										}
									case 3:
										{
											CreateWeapon(client, "tf_weapon_rocketlauncher", 15028, 15);
										}
									case 4:
										{
											CreateWeapon(client, "tf_weapon_rocketlauncher", 15043, 15);
										}
									case 5:
										{
											CreateWeapon(client, "tf_weapon_rocketlauncher", 15052, 15);
										}
									case 6:
										{
											CreateWeapon(client, "tf_weapon_rocketlauncher", 15057, 15);
										}
									case 7:
										{
											CreateWeapon(client, "tf_weapon_rocketlauncher", 15081, 15);
										}
									case 8:
										{
											CreateWeapon(client, "tf_weapon_rocketlauncher", 15104, 15);
										}
									case 9:
										{
											CreateWeapon(client, "tf_weapon_rocketlauncher", 15105, 15);
										}
									case 10:
										{
											CreateWeapon(client, "tf_weapon_rocketlauncher", 15129, 15);
										}
									case 11:
										{
											CreateWeapon(client, "tf_weapon_rocketlauncher", 15130, 15);
										}
									case 12:
										{
											CreateWeapon(client, "tf_weapon_rocketlauncher", 15150, 15);
										}
									}
								}
							case 5:
								{
									CreateWeapon(client, "tf_weapon_rocketlauncher", 205, 9);
								}
							case 6:
								{
									CreateWeapon(client, "tf_weapon_rocketlauncher", 205, 16);
								}
							}
						}					
					}
					
					int rnd2 = GetRandomUInt(1,9);
					TF2_RemoveWeaponSlot(client, 1);
					
					switch (rnd2)
					{
					case 1:
						{
							CreateWeapon(client, "tf_weapon_raygun", 442, 6);
						}
					case 2:
						{
							int rnd5 = GetRandomUInt(1,2);
							switch (rnd5)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_shotgun_soldier", 1153, 6);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_shotgun_soldier", 1153, 16);
								}
							}
						}
					case 3:
						{
							int rnd5 = GetRandomUInt(1,2);
							switch (rnd5)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_shotgun_soldier", 415, 6);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_shotgun_soldier", 415, 16);
								}
							}
						}
					case 4:
						{
							int rnd6 = GetRandomUInt(1,2);
							switch (rnd6)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_buff_item", 129, 6);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_buff_item", 1001, 6);
								}
							}
						}
					case 5:
						{
							CreateWeapon(client, "tf_weapon_buff_item", 226, 6);
						}
					case 6:
						{
							CreateWeapon(client, "tf_weapon_buff_item", 354, 6);
						}
					case 7:
						{
							CreateWeapon(client, "tf_wearable", 133, 6);
						}
					case 8:
						{
							CreateWeapon(client, "tf_wearable", 444, 6);
						}
					case 9:
						{
							int rnd7 = GetRandomUInt(1,5);
							switch (rnd7)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_shotgun_soldier", 10, 5);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_shotgun_soldier", 1141, 6);
								}
							case 3:
								{
									int rnd11 = GetRandomUInt(1,9);
									switch (rnd11)
									{
									case 1:
										{
											CreateWeapon(client, "tf_weapon_shotgun_soldier", 15003, 15);
										}
									case 2:
										{
											CreateWeapon(client, "tf_weapon_shotgun_soldier", 15016, 15);
										}
									case 3:
										{
											CreateWeapon(client, "tf_weapon_shotgun_soldier", 15044, 15);
										}
									case 4:
										{
											CreateWeapon(client, "tf_weapon_shotgun_soldier", 15047, 15);
										}
									case 5:
										{
											CreateWeapon(client, "tf_weapon_shotgun_soldier", 15085, 15);
										}
									case 6:
										{
											CreateWeapon(client, "tf_weapon_shotgun_soldier", 15109, 15);
										}
									case 7:
										{
											CreateWeapon(client, "tf_weapon_shotgun_soldier", 15132, 15);
										}
									case 8:
										{
											CreateWeapon(client, "tf_weapon_shotgun_soldier", 15133, 15);
										}
									case 9:
										{
											CreateWeapon(client, "tf_weapon_shotgun_soldier", 15152, 15);
										}
									}
								}
							case 4:
								{
									CreateWeapon(client, "tf_weapon_shotgun_soldier", 199, 11);
								}
							case 5:
								{
									CreateWeapon(client, "tf_weapon_shotgun_soldier", 199, 16);
								}
							}
						}					
					}
				}
				
				int rnd3 = GetRandomUInt(1,7);
				TF2_RemoveWeaponSlot(client, 2);
				
				switch (rnd3)
				{
				case 1:
					{
						CreateWeapon(client, "tf_weapon_shovel", 128, 6);
					}
				case 2:
					{
						CreateWeapon(client, "tf_weapon_shovel", 154, 6);
					}
				case 3:
					{
						int rnd6 = GetRandomUInt(1,2);
						switch (rnd6)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_shovel", 447, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_shovel", 447, 16);
							}
						}
					}
				case 4:
					{
						CreateWeapon(client, "tf_weapon_shovel", 775, 6);
					}
				case 5:
					{
						CreateWeapon(client, "tf_weapon_katana", 357, 6);
					}
				case 6:
					{
						CreateWeapon(client, "tf_weapon_shovel", 416, 6);
					}
				case 7:
					{
						int rnd5 = GetRandomUInt(1,12);
						switch (rnd5)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_shovel", 264, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_shovel", 423, 11);
							}
						case 3:
							{
								CreateWeapon(client, "tf_weapon_shovel", 474, 6);
							}
						case 4:
							{
								CreateWeapon(client, "tf_weapon_shovel", 880, 6);
							}
						case 5:
							{
								CreateWeapon(client, "tf_weapon_shovel", 939, 6);
							}
						case 6:
							{
								CreateWeapon(client, "tf_weapon_shovel", 1013, 6);
							}
						case 7:
							{
								CreateWeapon(client, "tf_weapon_shovel", 1071, 11);
							}
						case 8:
							{
								CreateWeapon(client, "tf_weapon_shovel", 1123, 6);
							}
						case 9:
							{
								CreateWeapon(client, "tf_weapon_shovel", 1127, 6);
							}
						case 10:
							{
								CreateWeapon(client, "tf_weapon_shovel", 30758, 6);
							}
						case 11:
							{
								CreateWeapon(client, "tf_weapon_shovel", 954, 11);
							}
						case 12:
							{
								CreateWeapon(client, "tf_weapon_shovel", 196, 11);
							}
						}
					}					
				}
			}
			
		case TFClass_DemoMan:
			{
				if (!g_bMedieval)
				{
					int rnd = GetRandomUInt(1,4); 
					TF2_RemoveWeaponSlot(client, 0);
					
					switch (rnd)
					{
					case 1:
						{
							int rnd8 = GetRandomUInt(1,2);
							switch (rnd8)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_grenadelauncher", 308, 6);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_grenadelauncher", 308, 16);
								}
							}
						}
					case 2:
						{
							int rnd9 = GetRandomUInt(1,2);
							switch (rnd9)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_grenadelauncher", 1151, 6);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_grenadelauncher", 1151, 6);
								}
							}
						}
					case 3:
						{
							int rnd4 = GetRandomUInt(1,2);
							switch (rnd4)
							{
							case 1:
								{
									CreateWeapon(client, "tf_wearable", 405, 6);
								}
							case 2:
								{
									CreateWeapon(client, "tf_wearable", 608, 6);
								}
							}
						}
					case 4:
						{
							int rnd7 = GetRandomUInt(1,6);
							switch (rnd7)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_grenadelauncher", 19, 5);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_grenadelauncher", 1007, 6);
								}
							case 3:
								{
									int rnd11 = GetRandomUInt(1,8);
									switch (rnd11)
									{
									case 1:
										{
											CreateWeapon(client, "tf_weapon_grenadelauncher", 15077, 15);
										}
									case 2:
										{
											CreateWeapon(client, "tf_weapon_grenadelauncher", 15079, 15);
										}
									case 3:
										{
											CreateWeapon(client, "tf_weapon_grenadelauncher", 15091, 15);
										}
									case 4:
										{
											CreateWeapon(client, "tf_weapon_grenadelauncher", 15092, 15);
										}
									case 5:
										{
											CreateWeapon(client, "tf_weapon_grenadelauncher", 15116, 15);
										}
									case 6:
										{
											CreateWeapon(client, "tf_weapon_grenadelauncher", 15117, 15);
										}
									case 7:
										{
											CreateWeapon(client, "tf_weapon_grenadelauncher", 15142, 15);
										}
									case 8:
										{
											CreateWeapon(client, "tf_weapon_grenadelauncher", 15158, 15);
										}
									}
								}
							case 4:
								{
									CreateWeapon(client, "tf_weapon_grenadelauncher", 206, 11);
								}
							case 5:
								{
									CreateWeapon(client, "tf_weapon_grenadelauncher", 206, 9);
								}
							case 6:
								{
									CreateWeapon(client, "tf_weapon_grenadelauncher", 206, 16);
								}
							}
						}	
					}
					
					int rnd2 = GetRandomUInt(1,6); 
					TF2_RemoveWeaponSlot(client, 1);
					
					switch (rnd2)
					{
					case 1:
						{
							CreateWeapon(client, "tf_weapon_pipebomblauncher", 1150, 6);
						}
					case 2:
						{
							CreateWeapon(client, "tf_weapon_pipebomblauncher", 130, 6);
						}
					case 3:
						{
							int rnd4 = GetRandomUInt(1,2);
							switch (rnd4)
							{     
							case 1:
								{
									CreateWeapon(client, "tf_wearable_demoshield", 131, 6);
								}
							case 2:
								{
									CreateWeapon(client, "tf_wearable_demoshield", 1144, 6);
								}
							}
						}
					case 4:
						{
							CreateWeapon(client, "tf_wearable_demoshield", 406, 6);
						}
					case 5:
						{
							CreateWeapon(client, "tf_wearable_demoshield", 1099, 6);
						}
					case 6:
						{
							int rnd5 = GetRandomUInt(1,8);
							switch (rnd5)
							{     
							case 1:
								{
									CreateWeapon(client, "tf_weapon_pipebomblauncher", 20, 5);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_pipebomblauncher", 661, 6);
								}
							case 3:
								{
									int rnd12 = GetRandomUInt(1,8);
									switch (rnd12)
									{
									case 1:
										{
											CreateWeapon(client, "tf_weapon_pipebomblauncher", 797, 11);
										}
									case 2:
										{
											CreateWeapon(client, "tf_weapon_pipebomblauncher", 806, 11);
										}
									case 3:
										{
											CreateWeapon(client, "tf_weapon_pipebomblauncher", 886, 11);
										}
									case 4:
										{
											CreateWeapon(client, "tf_weapon_pipebomblauncher", 895, 11);
										}
									case 5:
										{
											CreateWeapon(client, "tf_weapon_pipebomblauncher", 904, 11);
										}
									case 6:
										{
											CreateWeapon(client, "tf_weapon_pipebomblauncher", 913, 11);
										}
									case 7:
										{
											CreateWeapon(client, "tf_weapon_pipebomblauncher", 962, 11);
										}
									case 8:
										{
											CreateWeapon(client, "tf_weapon_pipebomblauncher", 971, 11);
										}
									}
								}
							case 4:
								{
									int rnd14 = GetRandomUInt(1,13);
									switch (rnd14)
									{
									case 1:
										{
											CreateWeapon(client, "tf_weapon_pipebomblauncher", 15009, 15);
										}
									case 2:
										{
											CreateWeapon(client, "tf_weapon_pipebomblauncher", 15012, 15);
										}
									case 3:
										{
											CreateWeapon(client, "tf_weapon_pipebomblauncher", 15024, 15);
										}
									case 4:
										{
											CreateWeapon(client, "tf_weapon_pipebomblauncher", 15038, 15);
										}
									case 5:
										{
											CreateWeapon(client, "tf_weapon_pipebomblauncher", 15045, 15);
										}
									case 6:
										{
											CreateWeapon(client, "tf_weapon_pipebomblauncher", 15048, 15);
										}
									case 7:
										{
											CreateWeapon(client, "tf_weapon_pipebomblauncher", 15082, 15);
										}
									case 8:
										{
											CreateWeapon(client, "tf_weapon_pipebomblauncher", 15083, 15);
										}
									case 9:
										{
											CreateWeapon(client, "tf_weapon_pipebomblauncher", 15084, 15);
										}
									case 10:
										{
											CreateWeapon(client, "tf_weapon_pipebomblauncher", 15113, 15);
										}
									case 11:
										{
											CreateWeapon(client, "tf_weapon_pipebomblauncher", 15137, 15);
										}
									case 12:
										{
											CreateWeapon(client, "tf_weapon_pipebomblauncher", 15138, 15);
										}
									case 13:
										{
											CreateWeapon(client, "tf_weapon_pipebomblauncher", 15155, 15);
										}
									}
								}
							case 5:
								{
									CreateWeapon(client, "tf_weapon_pipebomblauncher", 207, 9);
								}
							case 6:
								{
									CreateWeapon(client, "tf_weapon_pipebomblauncher", 207, 16);
								}
							case 7:
								{
									CreateWeapon(client, "tf_weapon_pipebomblauncher", 207, 11);
								}
							case 8:
								{
									CreateWeapon(client, "tf_weapon_pipebomblauncher", 661, 11);
								}
							}
						}					
					}
				}
				
				int rnd3 = GetRandomUInt(1,8);
				TF2_RemoveWeaponSlot(client, 2);
				
				switch (rnd3)
				{
				case 1:
					{
						int rnd5 = GetRandomUInt(1,5);
						switch (rnd5)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_sword", 132, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_sword", 266, 5);
							}
						case 3:
							{
								CreateWeapon(client, "tf_weapon_sword", 482, 6);
							}
						case 4:
							{
								CreateWeapon(client, "tf_weapon_sword", 1082, 6);
							}
						case 5:
							{
								CreateWeapon(client, "tf_weapon_sword", 132, 9);
							}
						}
					}
				case 2:
					{
						CreateWeapon(client, "tf_weapon_shovel", 154, 6);
					}
				case 3:
					{
						int rnd4 = GetRandomUInt(1,2);
						switch (rnd4)
						{     
						case 1:
							{
								CreateWeapon(client, "tf_weapon_sword", 172, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_sword", 172, 16);
							}
						}
					}
				case 4:
					{
						CreateWeapon(client, "tf_weapon_stickbomb", 307, 6);
					}
				case 5:
					{
						int rnd7 = GetRandomUInt(1,2);
						switch (rnd7)
						{     
						case 1:
							{
								CreateWeapon(client, "tf_weapon_sword", 327, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_sword", 327, 16);
							}
						}
					}
				case 6:
					{
						CreateWeapon(client, "tf_weapon_katana", 357, 6);
					}
				case 7:
					{
						int rnd8 = GetRandomUInt(1,2);
						switch (rnd8)
						{     
						case 1:
							{
								CreateWeapon(client, "tf_weapon_sword", 404, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_sword", 404, 16);
							}
						}
					}
				case 8:
					{
						int rnd6 = GetRandomUInt(1,13);
						switch (rnd6)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_bottle", 191, 11);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_bottle", 264, 6);
							}
						case 3:
							{
								CreateWeapon(client, "tf_weapon_bottle", 423, 11);
							}
						case 4:
							{
								CreateWeapon(client, "tf_weapon_bottle", 474, 6);
							}
						case 5:
							{
								CreateWeapon(client, "tf_weapon_bottle", 609, 6);
							}
						case 6:
							{
								CreateWeapon(client, "tf_weapon_bottle", 880, 6);
							}
						case 7:
							{
								CreateWeapon(client, "tf_weapon_bottle", 939, 6);
							}
						case 8:
							{
								CreateWeapon(client, "tf_weapon_bottle", 954, 11);
							}
						case 9:
							{
								CreateWeapon(client, "tf_weapon_bottle", 1013, 6);
							}
						case 10:
							{
								CreateWeapon(client, "tf_weapon_bottle", 1071, 11);
							}
						case 11:
							{
								CreateWeapon(client, "tf_weapon_bottle", 1123, 6);
							}
						case 12:
							{
								CreateWeapon(client, "tf_weapon_bottle", 1127, 6);
							}
						case 13:
							{
								CreateWeapon(client, "tf_weapon_bottle", 30758, 6);
							}
						}
					}					
				}				
			}
			
		case TFClass_Medic:
			{
				if (!g_bMedieval)
				{
					int rnd = GetRandomUInt(1,4); 
					TF2_RemoveWeaponSlot(client, 0);
					
					switch (rnd)
					{
					case 1:
						{
							int rnd7 = GetRandomUInt(1,2);
							switch (rnd7)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_syringegun_medic", 36, 6);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_syringegun_medic", 36, 9);
								}
							}
						}
					case 2:
						{
							int rnd6 = GetRandomUInt(1,3);
							switch (rnd6)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_crossbow", 305, 6);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_crossbow", 1079, 6);
								}
							case 3:
								{
									CreateWeapon(client, "tf_weapon_crossbow", 305, 16);
								}
							}
						}
					case 3:
						{
							CreateWeapon(client, "tf_weapon_syringegun_medic", 412, 6);
						}
					case 4:
						{
							CreateWeapon(client, "tf_weapon_syringegun_medic", 204, 11);
						}				
					}
					
					int rnd2 = GetRandomUInt(1,4);
					TF2_RemoveWeaponSlot(client, 1);
					switch (rnd2)
					{
					case 1:
						{
							CreateWeapon(client, "tf_weapon_medigun", 35, 6);
						}
					case 2:
						{
							CreateWeapon(client, "tf_weapon_medigun", 411, 6);
						}
					case 3:
						{
							CreateWeapon(client, "tf_weapon_medigun", 998, 6);
						}
					case 4:
						{
							int rnd4 = GetRandomUInt(1,7);
							switch (rnd4)
							{     
							case 1:
								{
									CreateWeapon(client, "tf_weapon_medigun", 29, 5);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_medigun", 663, 6);
								}
							case 3:
								{
									int rnd13 = GetRandomUInt(1,8);
									switch (rnd13)
									{
									case 1:
										{
											CreateWeapon(client, "tf_weapon_medigun", 796, 11);
										}
									case 2:
										{
											CreateWeapon(client, "tf_weapon_medigun", 805, 11);
										}
									case 3:
										{
											CreateWeapon(client, "tf_weapon_medigun", 885, 11);
										}
									case 4:
										{
											CreateWeapon(client, "tf_weapon_medigun", 894, 11);
										}
									case 5:
										{
											CreateWeapon(client, "tf_weapon_medigun", 903, 11);
										}
									case 6:
										{
											CreateWeapon(client, "tf_weapon_medigun", 912, 11);
										}
									case 7:
										{
											CreateWeapon(client, "tf_weapon_medigun", 961, 11);
										}
									case 8:
										{
											CreateWeapon(client, "tf_weapon_medigun", 970, 11);
										}
									}
								}
							case 4:
								{
									int rnd12 = GetRandomUInt(1,12);
									switch (rnd12)
									{
									case 1:
										{
											CreateWeapon(client, "tf_weapon_medigun", 15008, 15);
										}
									case 2:
										{
											CreateWeapon(client, "tf_weapon_medigun", 15010, 15);
										}
									case 3:
										{
											CreateWeapon(client, "tf_weapon_medigun", 15025, 15);
										}
									case 4:
										{
											CreateWeapon(client, "tf_weapon_medigun", 15039, 15);
										}
									case 5:
										{
											CreateWeapon(client, "tf_weapon_medigun", 15050, 15);
										}
									case 6:
										{
											CreateWeapon(client, "tf_weapon_medigun", 15078, 15);
										}
									case 7:
										{
											CreateWeapon(client, "tf_weapon_medigun", 15097, 15);
										}
									case 8:
										{
											CreateWeapon(client, "tf_weapon_medigun", 15121, 15);
										}
									case 9:
										{
											CreateWeapon(client, "tf_weapon_medigun", 15122, 15);
										}
									case 10:
										{
											CreateWeapon(client, "tf_weapon_medigun", 15123, 15);
										}
									case 11:
										{
											CreateWeapon(client, "tf_weapon_medigun", 15145, 15);
										}
									case 12:
										{
											CreateWeapon(client, "tf_weapon_medigun", 15146, 15);
										}
									}
								}
							case 5:
								{
									CreateWeapon(client, "tf_weapon_medigun", 211, 11);
								}
							case 6:
								{
									CreateWeapon(client, "tf_weapon_medigun", 211, 9);
								}
							case 7:
								{
									CreateWeapon(client, "tf_weapon_medigun", 211, 16);
								}
							}
						}				
					}
				}
				int rnd3 = GetRandomUInt(1,5);
				TF2_RemoveWeaponSlot(client, 2);
				
				switch (rnd3)
				{
				case 1:
					{
						int rnd7 = GetRandomUInt(1,3);
						switch (rnd7)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_bonesaw", 37, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_bonesaw", 1003, 6);
							}
						case 3:
							{
								CreateWeapon(client, "tf_weapon_bonesaw", 37, 16);
							}
						}
					}
				case 2:
					{
						CreateWeapon(client, "tf_weapon_bonesaw", 173, 6);
					}
				case 3:
					{
						int rnd8 = GetRandomUInt(1,2);
						switch (rnd8)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_bonesaw", 304, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_bonesaw", 304, 16);
							}
						}
					}
				case 4:
					{
						CreateWeapon(client, "tf_weapon_bonesaw", 413, 6);
					}
				case 5:
					{
						int rnd4 = GetRandomUInt(1,14);
						switch (rnd4)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_bonesaw", 8, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_bonesaw", 264, 6);
							}
						case 3:
							{
								CreateWeapon(client, "tf_weapon_bonesaw", 423, 11);
							}
						case 4:
							{
								CreateWeapon(client, "tf_weapon_bonesaw", 474, 6);
							}
						case 5:
							{
								CreateWeapon(client, "tf_weapon_bonesaw", 880, 6);
							}
						case 6:
							{
								CreateWeapon(client, "tf_weapon_bonesaw", 939, 6);
							}
						case 7:
							{
								CreateWeapon(client, "tf_weapon_bonesaw", 1013, 6);
							}
						case 8:
							{
								CreateWeapon(client, "tf_weapon_bonesaw", 1071, 11);
							}
						case 9:
							{
								CreateWeapon(client, "tf_weapon_bonesaw", 1123, 6);
							}
						case 10:
							{
								CreateWeapon(client, "tf_weapon_bonesaw", 1127, 6);
							}
						case 11:
							{
								CreateWeapon(client, "tf_weapon_bonesaw", 30758, 6);
							}
						case 12:
							{
								CreateWeapon(client, "tf_weapon_bonesaw", 1143, 11);
							}
						case 13:
							{
								CreateWeapon(client, "tf_weapon_bonesaw", 954, 11);
							}
						case 14:
							{
								CreateWeapon(client, "tf_weapon_bonesaw", 198, 11);
							}
						}
					}			
				}			
			}
			
		case TFClass_Heavy:
			{
				if (!g_bMedieval)
				{
					int rnd = GetRandomUInt(1,5);
					TF2_RemoveWeaponSlot(client, 0);
					
					switch (rnd)
					{
					case 1:
						{
							CreateWeapon(client, "tf_weapon_minigun", 41, 6);
						}
					case 2:
						{
							int rnd10 = GetRandomUInt(1,2);
							switch (rnd10)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_minigun", 312, 6);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_minigun", 312, 16);
								}
							}
						}
					case 3:
						{
							int rnd9 = GetRandomUInt(1,4);
							switch (rnd9)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_minigun", 424, 6);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_minigun", 424, 5);
								}
							case 3:
								{
									CreateWeapon(client, "tf_weapon_minigun", 424, 9);
								}
							case 4:
								{
									CreateWeapon(client, "tf_weapon_minigun", 424, 16);
								}
							}
						}
					case 4:
						{
							int rnd8 = GetRandomUInt(1,2);
							switch (rnd8)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_minigun", 811, 6);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_minigun", 811, 15);
								}
							}
						}
					case 5:
						{
							int rnd4 = GetRandomUInt(1,8);
							switch (rnd4)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_minigun", 15, 5);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_minigun", 298, 6);
								}
							case 3:
								{
									int rnd13 = GetRandomUInt(1,8);
									switch (rnd13)
									{
									case 1:
										{
											CreateWeapon(client, "tf_weapon_minigun", 793, 11);
										}
									case 2:
										{
											CreateWeapon(client, "tf_weapon_minigun", 802, 11);
										}
									case 3:
										{
											CreateWeapon(client, "tf_weapon_minigun", 882, 11);
										}
									case 4:
										{
											CreateWeapon(client, "tf_weapon_minigun", 891, 11);
										}
									case 5:
										{
											CreateWeapon(client, "tf_weapon_minigun", 900, 11);
										}
									case 6:
										{
											CreateWeapon(client, "tf_weapon_minigun", 909, 11);
										}
									case 7:
										{
											CreateWeapon(client, "tf_weapon_minigun", 958, 11);
										}
									case 8:
										{
											CreateWeapon(client, "tf_weapon_minigun", 967, 11);
										}
									}
								}
							case 4:
								{
									int rnd12 = GetRandomUInt(1,15);
									switch (rnd12)
									{
									case 1:
										{
											CreateWeapon(client, "tf_weapon_minigun", 15004, 15);
										}
									case 2:
										{
											CreateWeapon(client, "tf_weapon_minigun", 15020, 15);
										}
									case 3:
										{
											CreateWeapon(client, "tf_weapon_minigun", 15026, 15);
										}
									case 4:
										{
											CreateWeapon(client, "tf_weapon_minigun", 15031, 15);
										}
									case 5:
										{
											CreateWeapon(client, "tf_weapon_minigun", 15040, 15);
										}
									case 6:
										{
											CreateWeapon(client, "tf_weapon_minigun", 15055, 15);
										}
									case 7:
										{
											CreateWeapon(client, "tf_weapon_minigun", 15086, 15);
										}
									case 8:
										{
											CreateWeapon(client, "tf_weapon_minigun", 15087, 15);
										}
									case 9:
										{
											CreateWeapon(client, "tf_weapon_minigun", 15088, 15);
										}
									case 10:
										{
											CreateWeapon(client, "tf_weapon_minigun", 15098, 15);
										}
									case 11:
										{
											CreateWeapon(client, "tf_weapon_minigun", 15099, 15);
										}
									case 12:
										{
											CreateWeapon(client, "tf_weapon_minigun", 15123, 15);
										}
									case 13:
										{
											CreateWeapon(client, "tf_weapon_minigun", 15124, 15);
										}
									case 14:
										{
											CreateWeapon(client, "tf_weapon_minigun", 15125, 15);
										}
									case 15:
										{
											CreateWeapon(client, "tf_weapon_minigun", 15147, 15);
										}
									}
								}
							case 5:
								{
									CreateWeapon(client, "tf_weapon_minigun", 202, 11);
								}
							case 6:
								{
									CreateWeapon(client, "tf_weapon_minigun", 202, 9);
								}
							case 7:
								{
									CreateWeapon(client, "tf_weapon_minigun", 202, 16);
								}
							case 8:
								{
									CreateWeapon(client, "tf_weapon_minigun", 850, 6);
								}
							}
						}					
					}
					
					int rnd2 = GetRandomUInt(1,3);
					TF2_RemoveWeaponSlot(client, 1);
					
					switch (rnd2)
					{
					case 1:
						{
							CreateWeapon(client, "tf_weapon_shotgun_hwg", 425, 6);
						}
					case 2:
						{
							int rnd5 = GetRandomUInt(1,2);
							switch (rnd5)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_shotgun_hwg", 1153, 6);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_shotgun_hwg", 1153, 16);
								}
							}
						}	
					case 3:
						{
							int rnd7 = GetRandomUInt(1,5);
							switch (rnd7)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_shotgun_hwg", 11, 5);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_shotgun_hwg", 1141, 6);
								}
							case 3:
								{
									int rnd11 = GetRandomUInt(1,9);
									switch (rnd11)
									{
									case 1:
										{
											CreateWeapon(client, "tf_weapon_shotgun_hwg", 15003, 15);
										}
									case 2:
										{
											CreateWeapon(client, "tf_weapon_shotgun_hwg", 15016, 15);
										}
									case 3:
										{
											CreateWeapon(client, "tf_weapon_shotgun_hwg", 15044, 15);
										}
									case 4:
										{
											CreateWeapon(client, "tf_weapon_shotgun_hwg", 15047, 15);
										}
									case 5:
										{
											CreateWeapon(client, "tf_weapon_shotgun_hwg", 15085, 15);
										}
									case 6:
										{
											CreateWeapon(client, "tf_weapon_shotgun_hwg", 15109, 15);
										}
									case 7:
										{
											CreateWeapon(client, "tf_weapon_shotgun_hwg", 15132, 15);
										}
									case 8:
										{
											CreateWeapon(client, "tf_weapon_shotgun_hwg", 15133, 15);
										}
									case 9:
										{
											CreateWeapon(client, "tf_weapon_shotgun_hwg", 15152, 15);
										}
									}
								}
							case 4:
								{
									CreateWeapon(client, "tf_weapon_shotgun_hwg", 199, 16);
								}
							case 5:
								{
									CreateWeapon(client, "tf_weapon_shotgun_hwg", 199, 11);
								}
							}
						}				
					}
				}
				int rnd3 = GetRandomUInt(1,8);
				TF2_RemoveWeaponSlot(client, 2);
				
				switch (rnd3)
				{
				case 1:
					{
						CreateWeapon(client, "tf_weapon_fists", 43, 6);
					}
				case 2:
					{
						int rnd5 = GetRandomUInt(1,3);
						switch (rnd5)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_fists", 239, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_fists", 1100, 6);
							}
						case 3:
							{
								CreateWeapon(client, "tf_weapon_fists", 1084, 6);
							}
						}
					}
				case 3:
					{
						CreateWeapon(client, "tf_weapon_fists", 310, 6);
					}
				case 4:
					{
						CreateWeapon(client, "tf_weapon_fists", 331, 6);
					}
				case 5:
					{
						CreateWeapon(client, "tf_weapon_fists", 426, 6);
					}
				case 6:
					{
						CreateWeapon(client, "tf_weapon_fists", 656, 6);
					}
				case 7:
					{
						CreateWeapon(client, "tf_weapon_fists", 1184, 6);
					}
				case 8:
					{
						int rnd6 = GetRandomUInt(1,13);
						switch (rnd6)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_fists", 195, 11);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_fists", 587, 6);
							}
						case 3:
							{
								CreateWeapon(client, "tf_weapon_fireaxe", 264, 6);
							}
						case 4:
							{
								CreateWeapon(client, "tf_weapon_fireaxe", 423, 11);
							}
						case 5:
							{
								CreateWeapon(client, "tf_weapon_fireaxe", 474, 6);
							}
						case 6:
							{
								CreateWeapon(client, "tf_weapon_fireaxe", 880, 6);
							}
						case 7:
							{
								CreateWeapon(client, "tf_weapon_fireaxe", 939, 6);
							}
						case 8:
							{
								CreateWeapon(client, "tf_weapon_fireaxe", 954, 11);
							}
						case 9:
							{
								CreateWeapon(client, "tf_weapon_fireaxe", 1013, 6);
							}
						case 10:
							{
								CreateWeapon(client, "tf_weapon_fireaxe", 1071, 11);
							}
						case 11:
							{
								CreateWeapon(client, "tf_weapon_fireaxe", 1123, 6);
							}
						case 12:
							{
								CreateWeapon(client, "tf_weapon_fireaxe", 1127, 6);
							}
						case 13:
							{
								CreateWeapon(client, "tf_weapon_fireaxe", 30758, 6);
							}
						}
					}
				}						
			}
			
		case TFClass_Pyro:
			{
				if (!g_bMedieval)
				{
					int rnd = GetRandomUInt(1,5);
					TF2_RemoveWeaponSlot(client, 0);
					
					switch (rnd)
					{
					case 1:
						{
							int rnd5 = GetRandomUInt(1,2);
							switch (rnd5)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_flamethrower", 40, 6);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_flamethrower", 1146, 6);
								}
							}
						}
					case 2:
						{
							int rnd9 = GetRandomUInt(1,2);
							switch (rnd9)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_flamethrower", 215, 6);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_flamethrower", 215, 16);
								}
							}
						}
					case 3:
						{
							CreateWeapon(client, "tf_weapon_flamethrower", 594, 6);
						}
					case 4:
						{
							CreateWeapon(client, "tf_weapon_rocketlauncher_fireball", 1178, 6);
						}
					case 5:
						{
							int rnd4 = GetRandomUInt(1,9);
							switch (rnd4)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_flamethrower", 21, 5);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_flamethrower", 741, 6);
								}
							case 3:
								{
									CreateWeapon(client, "tf_weapon_flamethrower", 30474, 6);
								}
							case 4:
								{
									int rnd15 = GetRandomUInt(1,8);
									switch (rnd15)
									{
									case 1:
										{
											CreateWeapon(client, "tf_weapon_flamethrower", 798, 11);
										}
									case 2:
										{
											CreateWeapon(client, "tf_weapon_flamethrower", 807, 11);
										}
									case 3:
										{
											CreateWeapon(client, "tf_weapon_flamethrower", 887, 11);
										}
									case 4:
										{
											CreateWeapon(client, "tf_weapon_flamethrower", 896, 11);
										}
									case 5:
										{
											CreateWeapon(client, "tf_weapon_flamethrower", 905, 11);
										}
									case 6:
										{
											CreateWeapon(client, "tf_weapon_flamethrower", 914, 11);
										}
									case 7:
										{
											CreateWeapon(client, "tf_weapon_flamethrower", 963, 11);
										}
									case 8:
										{
											CreateWeapon(client, "tf_weapon_flamethrower", 972, 11);
										}
									}
								}
							case 5:
								{
									int rnd12 = GetRandomUInt(1,13);
									switch (rnd12)
									{
									case 1:
										{
											CreateWeapon(client, "tf_weapon_flamethrower", 15005, 15);
										}
									case 2:
										{
											CreateWeapon(client, "tf_weapon_flamethrower", 15017, 15);
										}
									case 3:
										{
											CreateWeapon(client, "tf_weapon_flamethrower", 15030, 15);
										}
									case 4:
										{
											CreateWeapon(client, "tf_weapon_flamethrower", 15034, 15);
										}
									case 5:
										{
											CreateWeapon(client, "tf_weapon_flamethrower", 15049, 15);
										}
									case 6:
										{
											CreateWeapon(client, "tf_weapon_flamethrower", 15054, 15);
										}
									case 7:
										{
											CreateWeapon(client, "tf_weapon_flamethrower", 15066, 15);
										}
									case 8:
										{
											CreateWeapon(client, "tf_weapon_flamethrower", 15067, 15);
										}
									case 9:
										{
											CreateWeapon(client, "tf_weapon_flamethrower", 15068, 15);
										}
									case 10:
										{
											CreateWeapon(client, "tf_weapon_flamethrower", 15089, 15);
										}
									case 11:
										{
											CreateWeapon(client, "tf_weapon_flamethrower", 15090, 15);
										}
									case 12:
										{
											CreateWeapon(client, "tf_weapon_flamethrower", 15115, 15);
										}
									case 13:
										{
											CreateWeapon(client, "tf_weapon_flamethrower", 15141, 15);
										}
									}
								}
							case 6:
								{
									CreateWeapon(client, "tf_weapon_flamethrower", 659, 6);
								}
							case 7:
								{
									CreateWeapon(client, "tf_weapon_flamethrower", 208, 11);
								}
							case 8:
								{
									CreateWeapon(client, "tf_weapon_flamethrower", 208, 9);
								}
							case 9:
								{
									CreateWeapon(client, "tf_weapon_flamethrower", 208, 16);
								}
							}
						}	
					}
					
					int rnd2 = GetRandomUInt(1,8);
					TF2_RemoveWeaponSlot(client, 1);
					
					switch (rnd2)
					{
					case 1:
						{
							int rnd7 = GetRandomUInt(1,2);
							switch (rnd7)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_flaregun", 39, 6);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_flaregun", 1081, 6);
								}
							}
						}
					case 2:
						{
							int rnd8 = GetRandomUInt(1,2);
							switch (rnd8)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_flaregun", 351, 6);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_flaregun", 351, 16);
								}
							}
						}
					case 3:
						{
							CreateWeapon(client, "tf_weapon_flaregun_revenge", 595, 6);
						}
					case 4:
						{
							int rnd7 = GetRandomUInt(1,2);
							switch (rnd7)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_flaregun", 740, 6);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_flaregun", 740, 16);
								}
							}
						}
					case 5:
						{
							int rnd5 = GetRandomUInt(1,2);
							switch (rnd5)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_shotgun_pyro", 1153, 6);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_shotgun_pyro", 1153, 16);
								}
							}
						}
					case 6:
						{
							int rnd6 = GetRandomUInt(1,2);
							switch (rnd6)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_shotgun_pyro", 415, 6);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_shotgun_pyro", 415, 16);
								}
							}
						}
					case 7:
						{
							CreateWeapon(client, "tf_weapon_jar_gas", 1180, 6);
						}
					case 8:
						{
							int rnd8 = GetRandomUInt(1,5);
							switch (rnd8)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_shotgun_pyro", 12, 6);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_shotgun_pyro", 1141, 6);
								}
							case 3:
								{
									int rnd11 = GetRandomUInt(1,9);
									switch (rnd11)
									{
									case 1:
										{
											CreateWeapon(client, "tf_weapon_shotgun_pyro", 15003, 15);
										}
									case 2:
										{
											CreateWeapon(client, "tf_weapon_shotgun_pyro", 15016, 15);
										}
									case 3:
										{
											CreateWeapon(client, "tf_weapon_shotgun_pyro", 15044, 15);
										}
									case 4:
										{
											CreateWeapon(client, "tf_weapon_shotgun_pyro", 15047, 15);
										}
									case 5:
										{
											CreateWeapon(client, "tf_weapon_shotgun_pyro", 15085, 15);
										}
									case 6:
										{
											CreateWeapon(client, "tf_weapon_shotgun_pyro", 15109, 15);
										}
									case 7:
										{
											CreateWeapon(client, "tf_weapon_shotgun_pyro", 15132, 15);
										}
									case 8:
										{
											CreateWeapon(client, "tf_weapon_shotgun_pyro", 15133, 15);
										}
									case 9:
										{
											CreateWeapon(client, "tf_weapon_shotgun_pyro", 15152, 15);
										}
									}
								}
							case 4:
								{
									CreateWeapon(client, "tf_weapon_shotgun_pyro", 199, 16);
								}
							case 5:
								{
									CreateWeapon(client, "tf_weapon_shotgun_pyro", 199, 11);
								}
							}
						}				
					}
				}
				
				int rnd3 = GetRandomUInt(1,9);
				TF2_RemoveWeaponSlot(client, 2);
				
				switch (rnd3)
				{
				case 1:
					{
						int rnd5 = GetRandomUInt(1,4);
						switch (rnd5)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_fireaxe", 38, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_fireaxe", 457, 6);
							}
						case 3:
							{
								CreateWeapon(client, "tf_weapon_fireaxe", 1000, 6);
							}
						case 4:
							{
								CreateWeapon(client, "tf_weapon_fireaxe", 38, 9);
							}
						}
					}
				case 2:
					{
						int rnd6 = GetRandomUInt(1,2);
						switch (rnd6)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_fireaxe", 153, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_fireaxe", 466, 6);
							}
						}
					}
				case 3:
					{
						int rnd8 = GetRandomUInt(1,2);
						switch (rnd8)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_fireaxe", 326, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_fireaxe", 326, 16);
							}
						}
					}
				case 4:
					{
						int rnd9 = GetRandomUInt(1,2);
						switch (rnd9)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_fireaxe", 214, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_fireaxe", 214, 16);
							}
						}
					}
				case 5:
					{
						CreateWeapon(client, "tf_weapon_fireaxe", 348, 6);
					}
				case 6:
					{
						CreateWeapon(client, "tf_weapon_fireaxe", 593, 6);
					}
				case 7:
					{
						CreateWeapon(client, "tf_weapon_breakable_sign", 813, 6);
					}
				case 8:
					{
						CreateWeapon(client, "tf_weapon_slap", 1181, 6);
					}
				case 9:
					{
						int rnd7 = GetRandomUInt(1,13);
						switch (rnd7)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_fireaxe", 192, 11);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_fireaxe", 739, 6);
							}
						case 3:
							{
								CreateWeapon(client, "tf_weapon_fireaxe", 264, 6);
							}
						case 4:
							{
								CreateWeapon(client, "tf_weapon_fireaxe", 423, 11);
							}
						case 5:
							{
								CreateWeapon(client, "tf_weapon_fireaxe", 474, 6);
							}
						case 6:
							{
								CreateWeapon(client, "tf_weapon_fireaxe", 880, 6);
							}
						case 7:
							{
								CreateWeapon(client, "tf_weapon_fireaxe", 939, 6);
							}
						case 8:
							{
								CreateWeapon(client, "tf_weapon_fireaxe", 954, 11);
							}
						case 9:
							{
								CreateWeapon(client, "tf_weapon_fireaxe", 1013, 6);
							}
						case 10:
							{
								CreateWeapon(client, "tf_weapon_fireaxe", 1071, 11);
							}
						case 11:
							{
								CreateWeapon(client, "tf_weapon_fireaxe", 1123, 6);
							}
						case 12:
							{
								CreateWeapon(client, "tf_weapon_fireaxe", 1127, 6);
							}
						case 13:
							{
								CreateWeapon(client, "tf_weapon_fireaxe", 30758, 6);
							}
						}
					}				
				}			
			}
		case TFClass_Spy:
			{
				if (!g_bMedieval)
				{
					int rnd = GetRandomUInt(1,5);
					TF2_RemoveWeaponSlot(client, 0);
					
					switch (rnd)
					{
					case 1:
						{
							int rnd5 = GetRandomUInt(1,2);
							switch (rnd5)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_revolver", 61, 6);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_revolver", 1006, 6);
								}
							}
						}
					case 2:
						{
							CreateWeapon(client, "tf_weapon_revolver", 224, 6);
						}
					case 3:
						{
							CreateWeapon(client, "tf_weapon_revolver", 460, 6);
						}
					case 4:
						{
							CreateWeapon(client, "tf_weapon_revolver", 525, 6);
						}
					case 5:
						{
							int rnd23 = GetRandomUInt(1,6);
							switch (rnd23)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_revolver", 24, 6);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_revolver", 161, 6);
								}
							case 3:
								{
									CreateWeapon(client, "tf_weapon_revolver", 1142, 6);
								}
							case 4:
								{
									int rnd12 = GetRandomUInt(1,11);
									switch (rnd12)
									{
									case 1:
										{
											CreateWeapon(client, "tf_weapon_revolver", 15011, 15);
										}
									case 2:
										{
											CreateWeapon(client, "tf_weapon_revolver", 15027, 15);
										}
									case 3:
										{
											CreateWeapon(client, "tf_weapon_revolver", 15042, 15);
										}
									case 4:
										{
											CreateWeapon(client, "tf_weapon_revolver", 15051, 15);
										}
									case 5:
										{
											CreateWeapon(client, "tf_weapon_revolver", 15062, 15);
										}
									case 6:
										{
											CreateWeapon(client, "tf_weapon_revolver", 15063, 15);
										}
									case 7:
										{
											CreateWeapon(client, "tf_weapon_revolver", 15064, 15);
										}
									case 8:
										{
											CreateWeapon(client, "tf_weapon_revolver", 15103, 15);
										}
									case 9:
										{
											CreateWeapon(client, "tf_weapon_revolver", 15128, 15);
										}
									case 10:
										{
											CreateWeapon(client, "tf_weapon_revolver", 15129, 15);
										}
									case 11:
										{
											CreateWeapon(client, "tf_weapon_revolver", 15149, 15);
										}
									}
								}
							case 5:
								{
									CreateWeapon(client, "tf_weapon_revolver", 210, 11);
								}
							case 6:
								{
									CreateWeapon(client, "tf_weapon_revolver", 210, 16);
								}
							}
						}					
					}
					
					int rnd2 = GetRandomUInt(1,5);
					TF2_RemoveWeaponSlot(client, 1);
					
					switch (rnd2)
					{
					case 1:
						{
							CreateWeapon(client, "tf_weapon_sapper", 810, 6);
						}
					case 2:
						{
							CreateWeapon(client, "tf_weapon_builder", 736, 11);
						}
					case 3:
						{
							CreateWeapon(client, "tf_weapon_sapper", 933, 6);
						}
					case 4:
						{
							CreateWeapon(client, "tf_weapon_sapper", 1080, 6);
						}
					case 5:
						{
							CreateWeapon(client, "tf_weapon_sapper", 1102, 6);
						}
					}
				}
				
				int rnd3 = GetRandomUInt(1,5);
				TF2_RemoveWeaponSlot(client, 2);
				CreateWeapon(client, "tf_weapon_pda_spy", 27, 6);
				
				switch (rnd3)
				{
				case 1:
					{
						CreateWeapon(client, "tf_weapon_knife", 356, 6);
					}
				case 2:
					{
						CreateWeapon(client, "tf_weapon_knife", 461, 6);
					}
				case 3:
					{
						CreateWeapon(client, "tf_weapon_knife", 649, 6);
					}
				case 4:
					{
						int rnd7 = GetRandomUInt(1,2);
						switch (rnd7)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_knife", 225, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_knife", 574, 6);
							}
						}
					}
				case 5:
					{
						int rnd6 = GetRandomUInt(1,11);
						switch (rnd6)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_knife", 194, 16);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_knife", 423, 11);
							}
						case 3:
							{
								CreateWeapon(client, "tf_weapon_knife", 638, 6);
							}
						case 4:
							{
								CreateWeapon(client, "tf_weapon_knife", 727, 6);
							}
						case 5:
							{
								CreateWeapon(client, "tf_weapon_knife", 1071, 11);
							}
						case 6:
							{
								CreateWeapon(client, "tf_weapon_knife", 30758, 6);
							}
						case 7:
							{
								CreateWeapon(client, "tf_weapon_knife", 665, 6);
							}
						case 8:
							{
								int rnd11 = GetRandomUInt(1,8);
								switch (rnd11)
								{
								case 1:
									{
										CreateWeapon(client, "tf_weapon_knife", 794, 11);
									}
								case 2:
									{
										CreateWeapon(client, "tf_weapon_knife", 803, 11);
									}
								case 3:
									{
										CreateWeapon(client, "tf_weapon_knife", 883, 11);
									}
								case 4:
									{
										CreateWeapon(client, "tf_weapon_knife", 892, 11);
									}
								case 5:
									{
										CreateWeapon(client, "tf_weapon_knife", 901, 11);
									}
								case 6:
									{
										CreateWeapon(client, "tf_weapon_knife", 910, 11);
									}
								case 7:
									{
										CreateWeapon(client, "tf_weapon_knife", 959, 11);
									}
								case 8:
									{
										CreateWeapon(client, "tf_weapon_knife", 968, 11);
									}
								}
							}
						case 9:
							{
								int rnd12 = GetRandomUInt(1,8);
								switch (rnd12)
								{
								case 1:
									{
										CreateWeapon(client, "tf_weapon_knife", 15062, 15);
									}
								case 2:
									{
										CreateWeapon(client, "tf_weapon_knife", 15094, 15);
									}
								case 3:
									{
										CreateWeapon(client, "tf_weapon_knife", 15095, 15);
									}
								case 4:
									{
										CreateWeapon(client, "tf_weapon_knife", 15096, 15);
									}
								case 5:
									{
										CreateWeapon(client, "tf_weapon_knife", 15118, 15);
									}
								case 6:
									{
										CreateWeapon(client, "tf_weapon_knife", 15119, 15);
									}
								case 7:
									{
										CreateWeapon(client, "tf_weapon_knife", 15143, 15);
									}
								case 8:
									{
										CreateWeapon(client, "tf_weapon_knife", 15144, 15);
									}
								}
							}
						case 10:
							{
								CreateWeapon(client, "tf_weapon_knife", 194, 11);
							}
						case 11:
							{
								CreateWeapon(client, "tf_weapon_knife", 194, 9);
							}
						}
					}					
				}

				int rnd4 = GetRandomUInt(1,5);
				TF2_RemoveWeaponSlot(client, 4);

				switch (rnd4)
				{
				case 1:
					{
						CreateWeapon(client, "tf_weapon_invis", 947, 6);
					}
				case 2:
					{
						CreateWeapon(client, "tf_weapon_invis", 212, 11);
					}
				case 3:
					{
						CreateWeapon(client, "tf_weapon_invis", 60, 6);
					}
				case 4:
					{
						CreateWeapon(client, "tf_weapon_invis", 297, 6);
					}
				case 5:
					{
						CreateWeapon(client, "tf_weapon_invis", 59, 6);
					}
				}
			}
		case TFClass_Engineer:
			{
				if (!g_bMedieval)
				{
					int rnd = GetRandomUInt(1,6);
					TF2_RemoveWeaponSlot(client, 0);
					
					switch (rnd)
					{
					case 1:
						{
							int rnd8 = GetRandomUInt(1,3);
							switch (rnd8)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_sentry_revenge", 141, 6);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_sentry_revenge", 1004, 6);
								}
							case 3:
								{
									CreateWeapon(client, "tf_weapon_sentry_revenge", 141, 9);
								}
							}
						}
					case 2:
						{
							int rnd11 = GetRandomUInt(1,2);
							switch (rnd11)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_shotgun_building_rescue", 997, 6);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_shotgun_building_rescue", 997, 16);
								}
							}
						}
					case 3:
						{
							CreateWeapon(client, "tf_weapon_drg_pomson", 588, 6);
						}
					case 4:
						{
							int rnd5 = GetRandomUInt(1,2);
							switch (rnd5)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_shotgun_primary", 1153, 6);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_shotgun_primary", 1153, 16);
								}
							}
						}	
					case 5:
						{
							CreateWeapon(client, "tf_weapon_shotgun_primary", 527, 6);
						}				
					case 6:
						{
							int rnd7 = GetRandomUInt(1,4);
							switch (rnd7)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_shotgun_primary", 9, 5);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_shotgun_primary", 1141, 6);
								}
							case 3:
								{
									int rnd11 = GetRandomUInt(1,9);
									switch (rnd11)
									{
									case 1:
										{
											CreateWeapon(client, "tf_weapon_shotgun_primary", 15003, 15);
										}
									case 2:
										{
											CreateWeapon(client, "tf_weapon_shotgun_primary", 15016, 15);
										}
									case 3:
										{
											CreateWeapon(client, "tf_weapon_shotgun_primary", 15044, 15);
										}
									case 4:
										{
											CreateWeapon(client, "tf_weapon_shotgun_primary", 15047, 15);
										}
									case 5:
										{
											CreateWeapon(client, "tf_weapon_shotgun_primary", 15085, 15);
										}
									case 6:
										{
											CreateWeapon(client, "tf_weapon_shotgun_primary", 15109, 15);
										}
									case 7:
										{
											CreateWeapon(client, "tf_weapon_shotgun_primary", 15132, 15);
										}
									case 8:
										{
											CreateWeapon(client, "tf_weapon_shotgun_primary", 15133, 15);
										}
									case 9:
										{
											CreateWeapon(client, "tf_weapon_shotgun_primary", 15152, 15);
										}
									}
								}
							case 4:
								{
									CreateWeapon(client, "tf_weapon_shotgun_primary", 199, 16);
								}
							}
						}					
					}
					
					int rnd2 = GetRandomUInt(1,3);
					TF2_RemoveWeaponSlot(client, 1);
					
					switch (rnd2)
					{
					case 1:
						{
							int rnd5 = GetRandomUInt(1,3);
							switch (rnd5)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_laser_pointer", 140, 6);
								}
							case 2:
								{
									CreateWeapon(client, "tf_weapon_laser_pointer", 30668, 15);
								}
							case 3:
								{
									CreateWeapon(client, "tf_weapon_laser_pointer", 1086, 6);
								}
							}
						}
					case 2:
						{
							CreateWeapon(client, "tf_weapon_mechanical_arm", 528, 6);
						}
					case 3:
						{
							int rnd6 = GetRandomUInt(1,5);
							switch (rnd6)
							{
							case 1:
								{
									CreateWeapon(client, "tf_weapon_pistol", 22, 5);
								}
							case 2:
								{
									int rnd7 = GetRandomUInt(1,2);
									switch (rnd7)
									{
									case 1:
										{
											CreateWeapon(client, "tf_weapon_pistol", 160, 3);
										}
									case 2:
										{
											CreateWeapon(client, "tf_weapon_pistol", 294, 6);
										}
									}
								}
							case 3:
								{
									CreateWeapon(client, "tf_weapon_pistol", 30666, 15);
								}
							case 4:
								{
									int rnd7 = GetRandomUInt(1,13);
									switch (rnd7)
									{
									case 1:
										{
											CreateWeapon(client, "tf_weapon_pistol", 15013, 15);
										}
									case 2:
										{
											CreateWeapon(client, "tf_weapon_pistol", 15018, 15);
										}
									case 3:
										{
											CreateWeapon(client, "tf_weapon_pistol", 15035, 15);
										}
									case 4:
										{
											CreateWeapon(client, "tf_weapon_pistol", 15041, 15);
										}
									case 5:
										{
											CreateWeapon(client, "tf_weapon_pistol", 15046, 15);
										}
									case 6:
										{
											CreateWeapon(client, "tf_weapon_pistol", 15056, 15);
										}
									case 7:
										{
											CreateWeapon(client, "tf_weapon_pistol", 15060, 15);
										}
									case 8:
										{
											CreateWeapon(client, "tf_weapon_pistol", 15061, 15);
										}
									case 9:
										{
											CreateWeapon(client, "tf_weapon_pistol", 15100, 15);
										}
									case 10:
										{
											CreateWeapon(client, "tf_weapon_pistol", 15101, 15);
										}
									case 11:
										{
											CreateWeapon(client, "tf_weapon_pistol", 15102, 15);
										}
									case 12:
										{
											CreateWeapon(client, "tf_weapon_pistol", 15126, 15);
										}
									case 13:
										{
											CreateWeapon(client, "tf_weapon_pistol", 15148, 15);
										}
									}
								}
							case 5:
								{
									CreateWeapon(client, "tf_weapon_pistol", 209, 16);
								}
							}
						}					
					}
					int rnd4 = GetRandomUInt(1,4);
					if(rnd4 == 1)
					{
						TF2_RemoveWeaponSlot(client, 3);				
						CreateWeapon(client, "tf_weapon_pda_engineer_build", 737, 11);
					}
					else
					{
						TF2_RemoveWeaponSlot(client, 3);				
						CreateWeapon(client, "tf_weapon_pda_engineer_build", 25, 6);
					}				
					
					TF2_RemoveWeaponSlot(client, 4);
					CreateWeapon(client, "tf_weapon_pda_engineer_destroy", 26, 6);					
				}
				int rnd3 = GetRandomUInt(1,5);
				TF2_RemoveWeaponSlot(client, 2);

				switch (rnd3)
				{
				case 1:
					{
						CreateWeapon(client, "tf_weapon_wrench", 155, 6);
					}
				case 2:
					{
						int rnd6 = GetRandomUInt(1,2);
						switch (rnd6)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_wrench", 329, 6);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_wrench", 329, 16);
							}
						}
					}
				case 3:
					{
						CreateWeapon(client, "tf_weapon_robot_arm", 142, 6);
					}
				case 4:
					{
						int rnd5 = GetRandomUInt(1,11);
						switch (rnd5)
						{
						case 1:
							{
								CreateWeapon(client, "tf_weapon_wrench", 197, 11);
							}
						case 2:
							{
								CreateWeapon(client, "tf_weapon_wrench", 169, 6);
							}
						case 3:
							{
								CreateWeapon(client, "tf_weapon_wrench", 423, 11);
							}
						case 4:
							{
								CreateWeapon(client, "tf_weapon_wrench", 1071, 11);
							}
						case 5:
							{
								CreateWeapon(client, "tf_weapon_wrench", 1123, 6);
							}
						case 6:
							{
								CreateWeapon(client, "tf_weapon_wrench", 30758, 6);
							}
						case 7:
							{
								CreateWeapon(client, "tf_weapon_wrench", 662, 6);
							}
						case 8:
							{
								int rnd12 = GetRandomUInt(1,8);
								switch (rnd12)
								{
								case 1:
									{
										CreateWeapon(client, "tf_weapon_wrench", 795, 11);
									}
								case 2:
									{
										CreateWeapon(client, "tf_weapon_wrench", 804, 11);
									}
								case 3:
									{
										CreateWeapon(client, "tf_weapon_wrench", 884, 11);
									}
								case 4:
									{
										CreateWeapon(client, "tf_weapon_wrench", 893, 11);
									}
								case 5:
									{
										CreateWeapon(client, "tf_weapon_wrench", 902, 11);
									}
								case 6:
									{
										CreateWeapon(client, "tf_weapon_wrench", 911, 11);
									}
								case 7:
									{
										CreateWeapon(client, "tf_weapon_wrench", 960, 11);
									}
								case 8:
									{
										CreateWeapon(client, "tf_weapon_wrench", 969, 11);
									}
								}
							}
						case 9:
							{
								int rnd13 = GetRandomUInt(1,7);
								switch (rnd13)
								{
								case 1:
									{
										CreateWeapon(client, "tf_weapon_wrench", 15073, 15);
									}
								case 2:
									{
										CreateWeapon(client, "tf_weapon_wrench", 15074, 15);
									}
								case 3:
									{
										CreateWeapon(client, "tf_weapon_wrench", 15075, 15);
									}
								case 4:
									{
										CreateWeapon(client, "tf_weapon_wrench", 15139, 15);
									}
								case 5:
									{
										CreateWeapon(client, "tf_weapon_wrench", 15140, 15);
									}
								case 6:
									{
										CreateWeapon(client, "tf_weapon_wrench", 15114, 15);
									}
								case 7:
									{
										CreateWeapon(client, "tf_weapon_wrench", 15156, 15);
									}
								}
							}
						case 10:
							{
								CreateWeapon(client, "tf_weapon_wrench", 197, 9);
							}
						case 11:
							{
								CreateWeapon(client, "tf_weapon_wrench", 197, 16);
							}
						}
					}
				case 5:
					{
						CreateWeapon(client, "tf_weapon_wrench", 589, 6);
					}					
				}	
			}
		}
	}
}

bool CreateWeapon(int client, char[] classname, int itemindex, int quality, int level = 0)
{
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

	if (level)
	{
		SetEntProp(weapon, Prop_Send, "m_iEntityLevel", level);
	}
	else
	{
		SetEntProp(weapon, Prop_Send, "m_iEntityLevel", GetRandomInt(1,99));
	}

	switch (itemindex)
	{
	case 25, 26:
		{
			DispatchSpawn(weapon);
			EquipPlayerWeapon(client, weapon); 

			return true; 			
		}
	case 735, 736, 810, 933, 1080, 1102:
		{
			SetEntProp(weapon, Prop_Send, "m_iObjectType", 3);
			SetEntProp(weapon, Prop_Data, "m_iSubType", 3);
			SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 0);
			SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 1);
			SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 2);
			SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 3);
		}	
	case 998:
		{
			SetEntProp(weapon, Prop_Send, "m_nChargeResistType", GetRandomInt(0,2));
		}
	case 1071:
		{
			TF2Attrib_SetByName(weapon, "item style override", 0.0);
			TF2Attrib_SetByName(weapon, "loot rarity", 1.0);		
			TF2Attrib_SetByName(weapon, "turn to gold", 1.0);
			SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 11);			

			DispatchSpawn(weapon);
			EquipPlayerWeapon(client, weapon); 
			
			return true; 
		}
	}

	if(quality == 9)
	{
		TF2Attrib_SetByName(weapon, "is australium item", 1.0);
		TF2Attrib_SetByName(weapon, "item style override", 1.0);
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 11);
		
		TF2Attrib_SetByDefIndex(weapon, 2025, 1.0);

		if (GetRandomInt(1,5) == 1)
		{
			TF2Attrib_SetByDefIndex(weapon, 2025, 2.0);
			TF2Attrib_SetByDefIndex(weapon, 2014, GetRandomInt(1,7) + 0.0);
		}
		else if (GetRandomInt(1,5) == 2)
		{
			TF2Attrib_SetByDefIndex(weapon, 2025, 3.0);
			TF2Attrib_SetByDefIndex(weapon, 2014, GetRandomInt(1,7) + 0.0);
			TF2Attrib_SetByDefIndex(weapon, 2013, GetRandomInt(2002,2008) + 0.0);
		}
		
		TF2Attrib_SetByDefIndex(weapon, 214, view_as<float>(GetRandomInt(0, 9000)));		
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
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 11);
		
		TF2Attrib_SetByDefIndex(weapon, 2025, 1.0);

		if (GetRandomInt(1,5) == 1)
		{
			TF2Attrib_SetByDefIndex(weapon, 2025, 2.0);
			TF2Attrib_SetByDefIndex(weapon, 2014, GetRandomInt(1,7) + 0.0);
		}
		else if (GetRandomInt(1,5) == 2)
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
		case 30665, 30666, 30667, 30668:
			{
				TF2Attrib_RemoveByDefIndex(weapon, 725);
			}
		default:
			{
				TF2Attrib_SetByDefIndex(weapon, 725, GetRandomFloat(0.0,1.0));
			}
		}
	}

	if (quality == 16)
	{
		quality = 14;
		int paint = GetRandomUInt(200, 283);
		if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274)
		{		
			paint = GetRandomUInt(300, 310);
		}
		TF2Attrib_SetByDefIndex(weapon, 834, view_as<float>(paint));

		if (GetRandomUInt(1,8) < 7)
		{
			TF2Attrib_SetByDefIndex(weapon, 725, GetRandomFloat(0.0,1.0));		
		}
		
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 14);		
	}
	
	if (quality >0 && quality < 9)
	{
		int rnd4 = GetRandomUInt(1,4);
		switch (rnd4)
		{
		case 1:
			{
				SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 1);
			}
		case 2:
			{
				SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 3);
			}
		case 3:
			{
				SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 7);
			}
		case 4:
			{
				SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 11);
				if (GetRandomInt(1,5) == 1)
				{
					TF2Attrib_SetByDefIndex(weapon, 2025, 1.0);
				}
				else if (GetRandomInt(1,5) == 2)
				{
					TF2Attrib_SetByDefIndex(weapon, 2025, 2.0);
					TF2Attrib_SetByDefIndex(weapon, 2014, GetRandomInt(1,7) + 0.0);
				}
				else if (GetRandomInt(1,5) == 3)
				{
					TF2Attrib_SetByDefIndex(weapon, 2025, 3.0);
					TF2Attrib_SetByDefIndex(weapon, 2014, GetRandomInt(1,7) + 0.0);
					TF2Attrib_SetByDefIndex(weapon, 2013, GetRandomInt(2002,2008) + 0.0);
				}
				
				TF2Attrib_SetByDefIndex(weapon, 214, view_as<float>(GetRandomInt(0, 9000)));
			}
		}
	}
	
	if (itemindex == 405 || itemindex == 608 || itemindex == 1101 || itemindex == 133 || itemindex == 444 || itemindex == 57 || itemindex == 231 || itemindex == 642 || itemindex == 131 || itemindex == 406 || itemindex == 1099 || itemindex == 1144)
	{
		DispatchSpawn(weapon);
		SDKCall(g_hEquipWearable, client, weapon);
		CreateTimer(0.1, TimerHealth, client);
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
			|| itemindex == 210)	
	{
		if (GetRandomUInt(1,4) == 1)
		{
			TF2_SwitchtoSlot(client, 0);
			SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 5);			
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
		if (GetRandomUInt(1,4) == 1)
		{
			TF2_SwitchtoSlot(client, 1);
			SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 5);						
			int iRand2 = GetRandomInt(1,4);
			if (iRand2 == 1)
			{
				TF2Attrib_SetByDefIndex(weapon, 134, 701.0);	
			}
			else if (iRand2 == 2)
			{
				TF2Attrib_SetByDefIndex(weapon, 134, 702.0);	
			}	
			else if (iRand2 == 3)
			{
				TF2Attrib_SetByDefIndex(weapon, 134, 703.0);	
			}
			else if (iRand2 == 4)
			{
				TF2Attrib_SetByDefIndex(weapon, 134, 704.0);	
			}				
		}
	}
	TF2_SwitchtoSlot(client, 0);
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