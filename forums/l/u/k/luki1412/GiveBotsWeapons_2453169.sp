#include <sourcemod>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.38"

bool g_bSuddenDeathMode;
bool g_bMVM;
bool g_bLateLoad;
int g_iResourceEntity;
int g_iAttackPressed[MAXPLAYERS+1];
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
	
	GameData hGameConfig = LoadGameConfigFile("give.bots.stuff");
	
	if (!hGameConfig)
	{
		SetFailState("Failed to find give.bots.stuff.txt gamedata! Can't continue.");
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
		HookEvent("player_hurt", player_hurt);
	}
	else
	{
		UnhookEvent("post_inventory_application", player_inv);
		UnhookEvent("teamplay_round_stalemate", EventSuddenDeath, EventHookMode_PostNoCopy);
		UnhookEvent("teamplay_round_start", EventRoundReset, EventHookMode_PostNoCopy);
		UnhookEvent("player_hurt", player_hurt);
	}
}

public void OnMapStart()
{
	if (GameRules_GetProp("m_bPlayingMannVsMachine"))
	{
		g_bMVM = true;
	}

	g_iResourceEntity = GetPlayerResourceEntity();
}

public void OnClientDisconnect(int client)
{
	delete g_hTouched[client];
}

public void player_hurt(Handle event, const char[] name, bool dontBroadcast) 
{
	if (!GetConVarBool(g_hCVEnabled))
	{
		return;
	}

	int victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsPlayerHere(victim))
	{
		int actwep = GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon");
		int wep = GetPlayerWeaponSlot(victim, 0);
		int wepIndex;

		if (IsValidEntity(wep))
		{
			wepIndex = GetEntProp(wep, Prop_Send, "m_iItemDefinitionIndex");
		}

		int wep3 = GetPlayerWeaponSlot(victim, 2);
		int wepIndex3;

		if (IsValidEntity(wep3))
		{
			wepIndex3 = GetEntProp(wep3, Prop_Send, "m_iItemDefinitionIndex");
		}

		switch (wepIndex) 
		{
			case 594:
			{
				if (GetEntPropFloat(victim, Prop_Send, "m_flRageMeter") > 99.9 && wep == actwep) 
				{
					FakeClientCommand(victim, "taunt");
				}
			}
		}

		switch (wepIndex3) 
		{
			case 589:
			{
				if (GetClientHealth(victim) < 60 && wep3 == actwep) 
				{
					FakeClientCommand(victim, "eureka_teleport 0");
				}
			}
		}
	}
	
	return;
}

public Action OnPlayerRunCmd(int victim, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (!GetConVarBool(g_hCVEnabled))
	{
		return Plugin_Continue;
	}
	
	if (IsPlayerHere(victim) && IsPlayerAlive(victim))
	{
		if (buttons&IN_RELOAD)
		{
			int actwepa = GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon");
			int wepa = GetPlayerWeaponSlot(victim, 0);
			int wepIndexa;

			if (IsValidEntity(wepa))
			{
				wepIndexa = GetEntProp(wepa, Prop_Send, "m_iItemDefinitionIndex");
			}

			if (wepIndexa == 730 && wepa == actwepa)
			{
				buttons ^= IN_RELOAD;
				if (GetEntProp(wepa, Prop_Data, "m_iClip1") < 4) {
					buttons |= IN_ATTACK;
				}				
				return Plugin_Changed;
			}
		}

		if (buttons&IN_ATTACK)
		{
			int actwep = GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon");
			int wep = GetPlayerWeaponSlot(victim, 0);
			int wepIndex;

			if (IsValidEntity(wep))
			{
				wepIndex = GetEntProp(wep, Prop_Send, "m_iItemDefinitionIndex");
			}

			int wep2 = GetPlayerWeaponSlot(victim, 1);
			int wepIndex2;

			if (IsValidEntity(wep2))
			{
				wepIndex2 = GetEntProp(wep2, Prop_Send, "m_iItemDefinitionIndex");
			}

			switch (wepIndex) 
			{
				case 448:
				{
					if (GetEntPropFloat(victim, Prop_Send, "m_flHypeMeter") > 99.9 && wep == actwep) 
					{
						buttons ^= IN_ATTACK;
						buttons |= IN_ATTACK2;
						return Plugin_Changed;
					}
				}
				case 752:
				{

					if (GetEntPropFloat(victim, Prop_Send, "m_flRageMeter") > 99.9 && wep == actwep) 
					{
						buttons ^= IN_ATTACK;
						buttons |= IN_RELOAD;
						return Plugin_Changed;
					}
				}
				case 441:
				{
					if (GetEntPropFloat(wep, Prop_Send, "m_flEnergy") > 19.9 && wep == actwep && GetRandomUInt(1,2) == 1) 
					{
						buttons ^= IN_ATTACK;
						buttons |= IN_ATTACK2;
						return Plugin_Changed;
					}
				}
				case 996:
				{
					g_iAttackPressed[victim]++;
					if (wep == actwep && g_iAttackPressed[victim] > 1) 
					{
						buttons ^= IN_ATTACK;
						g_iAttackPressed[victim] = 0;
						return Plugin_Changed;
					}
				}
				case 730:
				{
					if (wep == actwep && GetEntProp(wep, Prop_Data, "m_iClip1") > 0) 
					{
						buttons ^= IN_ATTACK;
						return Plugin_Changed;
					}					
				}
			}

			switch (wepIndex2) 
			{
				case 751:
				{
					if (wep2 == actwep && GetRandomUInt(1,3) == 1) 
					{
						buttons |= IN_ATTACK2;
						return Plugin_Changed;
					}
				}
				case 528:
				{
					if (wep2 == actwep && GetRandomUInt(1,3) == 1) 
					{
						buttons ^= IN_ATTACK;
						buttons |= IN_ATTACK2;
						return Plugin_Changed;
					}	
				}
			}
		}
	}
	
	return Plugin_Continue;
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
					int rnd = GetRandomUInt(0,5);

					switch (rnd)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_scattergun", 0, 45, 10);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_handgun_scout_primary", 0, 220, 1);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_soda_popper", 0, 448, 10);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_pep_brawler_blaster", 0, 772, 10);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_scattergun", 0, 1103);
						}
					}
					
					int rnd2 = GetRandomUInt(0,2);

					switch (rnd2)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_handgun_scout_secondary", 1, 773, 10);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_handgun_scout_secondary", 1, 449, 15);
						}
					}
					
					int rnd3 = GetRandomUInt(0,13);

					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_bat_wood", 2, 44, 15);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_bat_fish", 2, 572);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_bat", 2, 317, 25);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_bat", 2, 349, 10);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_bat", 2, 355, 5);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_bat_giftwrap", 2, 648, 15);
						}
						case 7:
						{
							CreateWeapon(client, "tf_weapon_bat", 2, 450, 10);
						}
						case 8:
						{
							CreateWeapon(client, "tf_weapon_bat_fish", 2, 221);
						}
						case 9:
						{
							CreateWeapon(client, "tf_weapon_bat", 2, 1013, 5);
						}
						case 10:
						{
							CreateWeapon(client, "tf_weapon_bat", 2, 939, 5);
						}
						case 11:
						{
							CreateWeapon(client, "tf_weapon_bat", 2, 880, 25);
						}
						case 12:
						{
							CreateWeapon(client, "tf_weapon_bat", 2, 474, 25);
						}
						case 13:
						{
							CreateWeapon(client, "tf_weapon_bat", 2, 1123, 50);
						}
					}
				}
				case TFClass_Sniper:
				{
					int rnd = GetRandomUInt(0,8);

					switch (rnd)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_compound_bow", 0, 56, 10);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_sniperrifle", 0, 230, 1);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_sniperrifle_decap", 0, 402, 10);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_sniperrifle", 0, 526, 5);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_sniperrifle", 0, 752, 1);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_sniperrifle_classic", 0, 1098, 1);
						}
						case 7:
						{
							CreateWeapon(client, "tf_weapon_compound_bow", 0, 1092, 10);
						}
						case 8:
						{
							CreateWeapon(client, "tf_weapon_sniperrifle", 0, 851, 1);
						}
					}
					
					int rnd2 = GetRandomUInt(0,1);

					switch (rnd2)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_charged_smg", 1, 751, 1);
						}
					}
					
					int rnd3 = GetRandomUInt(0,8);

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
						case 4:
						{
							CreateWeapon(client, "tf_weapon_club", 2, 1013, 5);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_club", 2, 939, 5);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_club", 2, 880, 25);
						}
						case 7:
						{
							CreateWeapon(client, "tf_weapon_club", 2, 474, 25);
						}
						case 8:
						{
							CreateWeapon(client, "tf_weapon_club", 2, 1123, 50);
						}
					}			
				}
				case TFClass_Soldier:
				{
					int rnd = GetRandomUInt(0,7);

					switch (rnd)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_rocketlauncher_directhit", 0, 127, 1);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_rocketlauncher", 0, 228, 5);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_rocketlauncher", 0, 414, 25);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_particle_cannon", 0, 441, 30);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_rocketlauncher", 0, 513, 5);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_rocketlauncher_airstrike", 0, 1104);
						}
						case 7:
						{
							CreateWeapon(client, "tf_weapon_rocketlauncher", 0, 730);
						}
					}
					
					int rnd2 = GetRandomUInt(0,3);

					switch (rnd2)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_raygun", 1, 442, 30);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_shotgun_soldier", 1, 1153);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_shotgun_soldier", 1, 415, 10);
						}
					}
					
					int rnd3 = GetRandomUInt(0,10);

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
						case 10:
						{
							CreateWeapon(client, "tf_weapon_shovel", 2, 1123, 50);
						}
					}
				}
				case TFClass_DemoMan:
				{
					int rnd = GetRandomUInt(0,2);

					switch (rnd)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_grenadelauncher", 0, 1151);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_cannon", 0, 996, 10);
						}
					}
					
					int rnd2 = GetRandomUInt(0,1);

					switch (rnd2)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_pipebomblauncher", 1, 1150);
						}
					}
					
					int rnd3 = GetRandomUInt(0,13);

					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_sword", 2, 132, 5);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_shovel", 2, 154, 5);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_sword", 2, 172, 5);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_stickbomb", 2, 307, 10);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_sword", 2, 327, 10);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_katana", 2, 357, 5);
						}
						case 7:
						{
							CreateWeapon(client, "tf_weapon_sword", 2, 482, 5);
						}
						case 8:
						{
							CreateWeapon(client, "tf_weapon_bottle", 2, 609, 10);
						}
						case 9:
						{
							CreateWeapon(client, "tf_weapon_bottle", 2, 1013, 5);
						}
						case 10:
						{
							CreateWeapon(client, "tf_weapon_bottle", 2, 939, 5);
						}
						case 11:
						{
							CreateWeapon(client, "tf_weapon_bottle", 2, 880, 25);
						}
						case 12:
						{
							CreateWeapon(client, "tf_weapon_bottle", 2, 474, 25);
						}
						case 13:
						{
							CreateWeapon(client, "tf_weapon_bottle", 2, 1123, 50);
						}
					}				
				}
				case TFClass_Medic:
				{
					int rnd = GetRandomUInt(0,3);

					switch (rnd)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_syringegun_medic", 0, 36, 5);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_crossbow", 0, 305, 15);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_syringegun_medic", 0, 412, 5);
						}
					}
					
					int rnd2 = GetRandomUInt(0,3);

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
						case 3:
						{
							CreateWeapon(client, "tf_weapon_medigun", 1, 998, 8);
						}
					}
					
					int rnd3 = GetRandomUInt(0,9);

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
						case 9:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 2, 1123, 50);
						}
					}			
				}
				case TFClass_Heavy:
				{
					int rnd = GetRandomUInt(0,4);

					switch (rnd)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_minigun", 0, 41, 5);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_minigun", 0, 312, 5);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_minigun", 0, 424, 5);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_minigun", 0, 811);
						}
					}
					
					int rnd2 = GetRandomUInt(0,2);

					switch (rnd2)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_shotgun_hwg", 1, 425, 10);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_shotgun_hwg", 1, 1153);
						}						
					}
					
					int rnd3 = GetRandomUInt(0,12);

					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_fists", 2, 43, 7);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_fists", 2, 239, 10);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_fists", 2, 310, 10);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_fists", 2, 331, 10);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_fists", 2, 426, 10);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_fists", 2, 656, 10);
						}
						case 7:
						{
							CreateWeapon(client, "tf_weapon_fists", 2, 587, 10);
						}
						case 8:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 2, 1013, 5);
						}
						case 9:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 2, 939, 5);
						}
						case 10:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 2, 880, 25);
						}
						case 11:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 2, 474, 25);
						}
						case 12:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 2, 1123, 50);
						}
					}						
				}
				case TFClass_Pyro:
				{
					int rnd = GetRandomUInt(0,6);

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
					
					int rnd2 = GetRandomUInt(0,6);

					switch (rnd2)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_flaregun", 1, 39, 10);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_flaregun", 1, 351, 10);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_flaregun_revenge", 1, 595, 30);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_flaregun", 1, 740, 10);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_shotgun_pyro", 1, 1153);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_shotgun_pyro", 1, 415, 10);
						}
					}
					
					int rnd3 = GetRandomUInt(0,16);

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
						case 16:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 2, 1123, 50);
						}
					}			
				}
				case TFClass_Spy:
				{
					int rnd = GetRandomUInt(0,4);

					switch (rnd)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_revolver", 0, 61, 5);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_revolver", 0, 224, 5);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_revolver", 0, 460, 5);
						}
						case 4:
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
					
					int rnd3 = GetRandomUInt(0,6);

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
							CreateWeapon(client, "tf_weapon_knife", 2, 638, 1);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_knife", 2, 225, 1);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_knife", 2, 574);
						}
					}
					int rnd4 = GetRandomUInt(0,1);

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
					int rnd = GetRandomUInt(0,5);

					switch (rnd)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_sentry_revenge", 0, 141, 5);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_shotgun_building_rescue", 0, 997);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_drg_pomson", 0, 588, 10);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_shotgun_primary", 0, 1153);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_shotgun_primary", 0, 527, 5);
						}					
					}
					
					int rnd2 = GetRandomUInt(0,1);

					switch (rnd2)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_mechanical_arm", 1, 528, 5);
						}
					}

					int rnd3 = GetRandomUInt(0,5);

					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_wrench", 2, 155, 20);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_wrench", 2, 329, 15);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_wrench", 2, 1123, 50);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_robot_arm", 2, 142, 15);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_wrench", 2, 589, 20);
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
					int rnd3 = GetRandomUInt(0,13);

					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_bat_wood", 2, 44, 15);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_bat_fish", 2, 572);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_bat", 2, 317, 25);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_bat", 2, 349, 10);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_bat", 2, 355, 5);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_bat_giftwrap", 2, 648, 15);
						}
						case 7:
						{
							CreateWeapon(client, "tf_weapon_bat", 2, 450, 10);
						}
						case 8:
						{
							CreateWeapon(client, "tf_weapon_bat_fish", 2, 221);
						}
						case 9:
						{
							CreateWeapon(client, "tf_weapon_bat", 2, 1013, 5);
						}
						case 10:
						{
							CreateWeapon(client, "tf_weapon_bat", 2, 939, 5);
						}
						case 11:
						{
							CreateWeapon(client, "tf_weapon_bat", 2, 880, 25);
						}
						case 12:
						{
							CreateWeapon(client, "tf_weapon_bat", 2, 474, 25);
						}
						case 13:
						{
							CreateWeapon(client, "tf_weapon_bat", 2, 1123, 50);
						}
					}
				}
				case TFClass_Sniper:
				{
					int rnd2 = GetRandomUInt(0,3);

					switch (rnd2)
					{
						case 1:
						{
							CreateWeapon(client, "tf_wearable", 1, 57, 10, true);
						}
						case 2:
						{
							CreateWeapon(client, "tf_wearable", 1, 231, 10, true);
						}
						case 3:
						{
							CreateWeapon(client, "tf_wearable", 1, 642, 10, true);
						}
					}
					
					int rnd3 = GetRandomUInt(0,8);

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
						case 4:
						{
							CreateWeapon(client, "tf_weapon_club", 2, 1013, 5);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_club", 2, 939, 5);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_club", 2, 880, 25);
						}
						case 7:
						{
							CreateWeapon(client, "tf_weapon_club", 2, 474, 25);
						}
						case 8:
						{
							CreateWeapon(client, "tf_weapon_club", 2, 1123, 50);
						}
					}			
				}
				case TFClass_Soldier:
				{
					int rnd2 = GetRandomUInt(0,2);

					switch (rnd2)
					{
						case 1:
						{
							CreateWeapon(client, "tf_wearable", 1, 133, 10, true);
						}
						case 2:
						{
							CreateWeapon(client, "tf_wearable", 1, 444, 10, true);
						}
					}
					
					int rnd3 = GetRandomUInt(0,10);

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
						case 10:
						{
							CreateWeapon(client, "tf_weapon_shovel", 2, 1123, 50);
						}
					}
				}
				case TFClass_DemoMan:
				{
					int rnd = GetRandomUInt(0,2);

					switch (rnd)
					{
						case 1:
						{
							CreateWeapon(client, "tf_wearable", 0, 405, 10, true);
						}
						case 2:
						{
							CreateWeapon(client, "tf_wearable", 0, 608, 10, true);
						}
					}				

					int rnd2 = GetRandomUInt(0,3);

					switch (rnd2)
					{
						case 1:
						{
							CreateWeapon(client, "tf_wearable_demoshield", 1, 131, _, true);
						}
						case 2:
						{
							CreateWeapon(client, "tf_wearable_demoshield", 1, 406, 10, true);
						}
						case 3:
						{
							CreateWeapon(client, "tf_wearable_demoshield", 1, 1099, _, true);
						}
					}				
				
					int rnd3 = GetRandomUInt(0,14);

					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_sword", 2, 132, 5);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_shovel", 2, 154, 5);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_sword", 2, 172, 5);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_stickbomb", 2, 307, 10);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_sword", 2, 327, 10);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_katana", 2, 357, 5);
						}
						case 7:
						{
							CreateWeapon(client, "tf_weapon_sword", 2, 482, 5);
						}
						case 8:
						{
							CreateWeapon(client, "tf_weapon_bottle", 2, 609, 10);
						}
						case 9:
						{
							CreateWeapon(client, "tf_weapon_bottle", 2, 1013, 5);
						}
						case 10:
						{
							CreateWeapon(client, "tf_weapon_bottle", 2, 939, 5);
						}
						case 11:
						{
							CreateWeapon(client, "tf_weapon_bottle", 2, 880, 25);
						}
						case 12:
						{
							CreateWeapon(client, "tf_weapon_bottle", 2, 474, 25);
						}
						case 13:
						{						
							CreateWeapon(client, "tf_weapon_sword", 2, 404);							
						}
						case 14:
						{
							CreateWeapon(client, "tf_weapon_bottle", 2, 1123, 50);
						}
					}
				}
				case TFClass_Medic:
				{
					int rnd3 = GetRandomUInt(0,9);

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
						case 9:
						{
							CreateWeapon(client, "tf_weapon_bonesaw", 2, 1123, 50);
						}
					}	
				}
				case TFClass_Heavy:
				{
					int rnd3 = GetRandomUInt(0,12);

					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_fists", 2, 43, 7);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_fists", 2, 239, 10);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_fists", 2, 310, 10);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_fists", 2, 331, 10);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_fists", 2, 426, 10);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_fists", 2, 656, 10);
						}
						case 7:
						{
							CreateWeapon(client, "tf_weapon_fists", 2, 587, 10);
						}
						case 8:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 2, 1013, 5);
						}
						case 9:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 2, 939, 5);
						}
						case 10:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 2, 880, 25);
						}
						case 11:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 2, 474, 25);
						}
						case 12:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 2, 1123, 50);
						}
					}				
				}
				case TFClass_Pyro:
				{
					int rnd3 = GetRandomUInt(0,16);

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
						case 16:
						{
							CreateWeapon(client, "tf_weapon_fireaxe", 2, 1123, 50);
						}
					}
				}
				case TFClass_Spy:
				{
					int rnd3 = GetRandomUInt(0,6);

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
							CreateWeapon(client, "tf_weapon_knife", 2, 638, 1);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_knife", 2, 225, 1);
						}
						case 6:
						{
							CreateWeapon(client, "tf_weapon_knife", 2, 574);
						}
					}
					int rnd4 = GetRandomUInt(0,1);

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
					int rnd3 = GetRandomUInt(0,5);

					switch (rnd3)
					{
						case 1:
						{
							CreateWeapon(client, "tf_weapon_wrench", 2, 155, 20);
						}
						case 2:
						{
							CreateWeapon(client, "tf_weapon_wrench", 2, 329, 15);
						}
						case 3:
						{
							CreateWeapon(client, "tf_weapon_wrench", 2, 1123, 50);
						}
						case 4:
						{
							CreateWeapon(client, "tf_weapon_robot_arm", 2, 142, 15);
						}
						case 5:
						{
							CreateWeapon(client, "tf_weapon_wrench", 2, 1123, 50);
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
	
	SetEntData(weapon, FindSendPropInfo(entclass, "m_bInitialized"), 1);

	if (!DispatchSpawn(weapon)) 
	{
		LogError("The created weapon entity [Class name: %s, Item index: %i, Index: %i], failed to spawn! Skipping.", classname, itemindex, weapon);
		AcceptEntityInput(weapon, "Kill");
		return false;
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

			if (resistType > 2) {
				resistType = 0;
			}

			SetEntData(weapon, FindSendPropInfo(entclass, "m_nChargeResistType"), resistType);
		}
		case 1178:
		{
			int iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
			int iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
			SetEntData(client, iAmmoTable+iOffset, 40, 4);
		}
		case 39,351,740:
		{
			int iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
			int iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
			SetEntData(client, iAmmoTable+iOffset, 16, 4);			
		}
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
	if (!IsClientInGame(client) || g_iResourceEntity == -1)
	{
		return -1;
	}

	return GetEntProp(g_iResourceEntity, Prop_Send, "m_iMaxHealth", _, client);
}

bool IsPlayerHere(int client)
{
	return (client && IsClientInGame(client) && IsFakeClient(client) && !IsClientReplay(client) && !IsClientSourceTV(client));
}

int GetRandomUInt(int min, int max)
{
	return RoundToFloor(GetURandomFloat() * (max - min + 1)) + min;
}