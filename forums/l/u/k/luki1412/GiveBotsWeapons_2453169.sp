#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.52"
#define COLLISION_GROUP_DEBRIS_TRIGGER 2
#define EF_NODRAW 32

#define BOTH_TEAMS 1
#define RED_TEAM 2
#define BLU_TEAM 3

bool g_bSuddenDeathMode;
bool g_bMVM;
bool g_bCVEnabled;
bool g_bCVMVMSupported;
bool g_bCVExtraLogic;
bool g_bCVDroppedWeaponRemoval;
bool g_bCVRandomizeDelay;
int g_iResourceEntity;
int g_iAttackPressed[MAXPLAYERS+1];
int g_iCVTeam;
float g_fCVDelay;
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
		FormatEx(error, err_max, "This plugin only works for Team Fortress 2.");
		return APLRes_Failure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	ConVar hCVVersion = CreateConVar("sm_gbw_version", PLUGIN_VERSION, "Give Bots Weapons version cvar", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	ConVar hCVEnabled = CreateConVar("sm_gbw_enabled", "1", "Enables/disables this plugin", FCVAR_NONE, true, 0.0, true, 1.0);
	ConVar hCVDelay = CreateConVar("sm_gbw_delay", "0.5", "Delay for giving weapons to bots", FCVAR_NONE, true, 0.1, true, 30.0);
	ConVar hCVRandomizeDelay = CreateConVar("sm_gbw_randomizedelay", "1", "Whether to randomize delay value by taking sm_gbw_delay as the upper bound and 0.1 as the lower bound. sm_gbw_delay must be bigger than 0.1", FCVAR_NONE, true, 0.0, true, 1.0);
	ConVar hCVTeam = CreateConVar("sm_gbw_team", "1", "Team to give weapons to: 1-both, 2-red, 3-blu", FCVAR_NONE, true, 1.0, true, 3.0);
	ConVar hCVMVMSupported = CreateConVar("sm_gbw_mvm", "0", "Enables/disables giving bots weapons when MVM mode is enabled", FCVAR_NONE, true, 0.0, true, 1.0);
	ConVar hCVDroppedWeaponRemoval = CreateConVar("sm_gbw_droppedweaponremoval", "0", "Specifies the removal type of dropped weapons, created by this plugin: 0-remove weapons near supply cabinets and in respawn rooms  1-remove weapons anywhere on the map", FCVAR_NONE, true, 0.0, true, 1.0);
	ConVar hCVExtraWeaponLogic = CreateConVar("sm_gbw_extraweaponlogic", "1", "Enables/disables extra logic for certain weapons. Some weapons require this, others are just improved. Performance impact.", FCVAR_NONE, true, 0.0, true, 1.0);

	OnEnabledChanged(hCVEnabled, "", "");
	HookConVarChange(hCVEnabled, OnEnabledChanged);
	OnDroppedWeaponRemovalChanged(hCVDroppedWeaponRemoval, "", "");
	HookConVarChange(hCVDroppedWeaponRemoval, OnDroppedWeaponRemovalChanged);
	OnExtraLogicChanged(hCVExtraWeaponLogic, "", "");
	HookConVarChange(hCVExtraWeaponLogic, OnExtraLogicChanged);
	OnMVMSupportedChanged(hCVMVMSupported, "", "");
	HookConVarChange(hCVMVMSupported, OnMVMSupportedChanged);
	OnRandomizeDelayChanged(hCVRandomizeDelay, "", "");
	HookConVarChange(hCVRandomizeDelay, OnRandomizeDelayChanged);
	OnDelayChanged(hCVDelay, "", "");
	HookConVarChange(hCVDelay, OnDelayChanged);
	OnTeamChanged(hCVTeam, "", "");
	HookConVarChange(hCVTeam, OnTeamChanged);
	SetConVarString(hCVVersion, PLUGIN_VERSION);
	AutoExecConfig(true, "Give_Bots_Weapons");
	GameData hGameConfig = LoadGameConfigFile("give.bots.stuff");

	if (!hGameConfig)
	{
		SetFailState("Failed to find give.bots.stuff.txt gamedata! Can't continue.");
	}

	StartPrepSDKCall(SDKCall_Player);

	if (!PrepSDKCall_SetFromConf(hGameConfig, SDKConf_Virtual, "WeaponEquip"))
	{
		SetFailState("Failed to prepare the SDKCall for giving weapons. Try updating gamedata or restarting your server.");
	}

	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hWeaponEquip = EndPrepSDKCall();

	if (!g_hWeaponEquip)
	{
		SetFailState("Failed to prepare the SDKCall for giving weapons. Try updating gamedata or restarting your server.");
	}

	StartPrepSDKCall(SDKCall_Player);

	if (!PrepSDKCall_SetFromConf(hGameConfig, SDKConf_Virtual, "EquipWearable"))
	{
		SetFailState("Failed to prepare the SDKCall for giving wearable weapons. Try updating gamedata or restarting your server.");
	}

	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hWWeaponEquip = EndPrepSDKCall();

	if (!g_hWWeaponEquip)
	{
		SetFailState("Failed to prepare the SDKCall for giving wearable weapons. Try updating gamedata or restarting your server.");
	}

	delete hGameConfig;
	delete hCVVersion;
	delete hCVEnabled;
	delete hCVDelay;
	delete hCVDroppedWeaponRemoval;
	delete hCVExtraWeaponLogic;
	delete hCVRandomizeDelay;
	delete hCVTeam;
	delete hCVMVMSupported;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsFakeClient(i))
		{
			SDKHook(i, SDKHook_OnTakeDamageAlivePost, OnTakeDamageAlivePost);
		}
	}
}

public void OnEnabledChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (GetConVarBool(convar))
	{
		g_bCVEnabled = true;
		HookEvent("post_inventory_application", player_inv);
		HookEvent("teamplay_round_stalemate", EventSuddenDeath, EventHookMode_PostNoCopy);
		HookEvent("teamplay_round_start", EventRoundReset, EventHookMode_PostNoCopy);
	}
	else
	{
		g_bCVEnabled = false;
		UnhookEvent("post_inventory_application", player_inv);
		UnhookEvent("teamplay_round_stalemate", EventSuddenDeath, EventHookMode_PostNoCopy);
		UnhookEvent("teamplay_round_start", EventRoundReset, EventHookMode_PostNoCopy);

		for (int i = 0; i < (MAXPLAYERS+1); i++)
		{
			delete g_hTouched[i];
		}
	}
}

public void OnExtraLogicChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bCVExtraLogic = GetConVarBool(convar);
}

public void OnDroppedWeaponRemovalChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bCVDroppedWeaponRemoval = GetConVarBool(convar);
}

public void OnMVMSupportedChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bCVMVMSupported = GetConVarBool(convar);
}

public void OnRandomizeDelayChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bCVRandomizeDelay = GetConVarBool(convar);
}

public void OnDelayChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_fCVDelay = GetConVarFloat(convar);
}

public void OnTeamChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iCVTeam = GetConVarInt(convar);
}

public void OnMapStart()
{
	g_bMVM = GameRules_GetProp("m_bPlayingMannVsMachine") ? true : false;
	g_iResourceEntity = GetPlayerResourceEntity();
	HookEntities("func_regenerate");
	HookEntities("func_respawnroom");

	for (int i = 0; i < (MAXPLAYERS+1); i++)
	{
		delete g_hTouched[i];
	}
}

public void OnClientDisconnect(int client)
{
	delete g_hTouched[client];
}

public void OnClientPutInServer(int client)
{
	if (IsFakeClient(client))
	{
		SDKHook(client, SDKHook_OnTakeDamageAlivePost, OnTakeDamageAlivePost);
	}
}

public void OnTakeDamageAlivePost(int victim, int attacker, int inflictor, float damage, int damagetype)
{
	if (!g_bCVEnabled || !g_bCVExtraLogic || !IsPlayerHere(victim))
	{
		return;
	}

	int curWeapon = GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon");

	if (!IsValidEntity(curWeapon))
	{
		return;
	}

	int curWeaponIndex = GetEntProp(curWeapon, Prop_Send, "m_iItemDefinitionIndex");

	switch (curWeaponIndex)
	{
		case 304:  // Amputator
		{
			if ((GetClientHealth(victim) < 70) && (GetURandomFloat() < 0.4))
			{
				FakeClientCommand(victim, "taunt");
			}
		}
		case 594: // Phlogistinator
		{
			if ((GetEntPropFloat(victim, Prop_Send, "m_flRageMeter") == 100.0) && (GetURandomFloat() < 0.5))
			{
				FakeClientCommand(victim, "taunt");
			}
		}
		case 589:  // Eureka Effect
		{
			if ((GetClientHealth(victim) < 70) && (GetURandomFloat() < 0.4))
			{
				FakeClientCommand(victim, "eureka_teleport 0");
			}
		}
	}

	return;
}

public Action OnPlayerRunCmd(int victim, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (!g_bCVEnabled || !g_bCVExtraLogic || !IsPlayerHere(victim))
	{
		return Plugin_Continue;
	}

	if (buttons&IN_ATTACK)
	{
		int curWeapon = GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon");

		if (!IsValidEntity(curWeapon))
		{
			return Plugin_Continue;
		}

		int curWeaponIndex = GetEntProp(curWeapon, Prop_Send, "m_iItemDefinitionIndex");

		switch (curWeaponIndex)
		{
			case 998: // Vaccinator
			{
				g_iAttackPressed[victim]++;

				if (g_iAttackPressed[victim] > 250)
				{
					buttons ^= IN_ATTACK;
					buttons |= IN_RELOAD;
					g_iAttackPressed[victim] = 0;
					return Plugin_Changed;
				}
			}
			case 730: // Beggar's Bazooka
			{
				g_iAttackPressed[victim]++;

				if (g_iAttackPressed[victim] > 1)
				{
					buttons ^= IN_ATTACK;
					g_iAttackPressed[victim] = 0;
					return Plugin_Changed;
				}
			}
			case 441: // Cow Mangler 5000
			{
				if ((GetEntPropFloat(curWeapon, Prop_Send, "m_flEnergy") == 20.0) && (GetURandomFloat() < 0.4))
				{
					buttons ^= IN_ATTACK;
					buttons |= IN_ATTACK2;
					return Plugin_Changed;
				}
			}
			case 996: // Loose Cannon
			{
				g_iAttackPressed[victim]++;

				if (g_iAttackPressed[victim] > 1)
				{
					buttons ^= IN_ATTACK;
					g_iAttackPressed[victim] = 0;
					return Plugin_Changed;
				}
			}
			case 448: // Soda Popper
			{
				if (GetEntPropFloat(victim, Prop_Send, "m_flHypeMeter") == 100.0)
				{
					buttons ^= IN_ATTACK;
					buttons |= IN_ATTACK2;
					return Plugin_Changed;
				}
				else if(TF2_IsPlayerInCondition(victim, TFCond_CritHype))
				{
					buttons |= IN_JUMP;
					return Plugin_Changed;
				}
			}
			case 752: // Hitman's Heatmaker
			{
				if (GetEntPropFloat(victim, Prop_Send, "m_flRageMeter") == 100.0)
				{
					buttons ^= IN_ATTACK;
					buttons |= IN_RELOAD;
					return Plugin_Changed;
				}
			}
			case 751: // Cleaner's Carabine
			{
				if (GetEntPropFloat(curWeapon, Prop_Send, "m_flMinicritCharge") == 100.0)
				{
					buttons ^= IN_ATTACK;
					buttons |= IN_ATTACK2;
					return Plugin_Changed;
				}
			}
			case 528: // Short Circuit
			{
				if (GetURandomFloat() < 0.3)
				{
					buttons ^= IN_ATTACK;
					buttons |= IN_ATTACK2;
					return Plugin_Changed;
				}
			}
			case 44:  // Sandman
			{
				g_iAttackPressed[victim]++;

				if (g_iAttackPressed[victim] > 20)
				{
					buttons ^= IN_ATTACK;
					buttons |= IN_ATTACK2;
					g_iAttackPressed[victim] = 0;
					return Plugin_Changed;
				}
			}
			case 648: // Wrap Assassin
			{
				g_iAttackPressed[victim]++;

				if (g_iAttackPressed[victim] > 15)
				{
					buttons ^= IN_ATTACK;
					buttons |= IN_ATTACK2;
					g_iAttackPressed[victim] = 0;
					return Plugin_Changed;
				}
			}
			case 595,351: // Manmelter, Detonator
			{
				g_iAttackPressed[victim]++;

				if ((g_iAttackPressed[victim] > 10) && (GetURandomFloat() < 0.3))
				{
					buttons ^= IN_ATTACK;
					buttons |= IN_ATTACK2;
					g_iAttackPressed[victim] = 0;
					return Plugin_Changed;
				}
			}
		}
	}
	else if (buttons&IN_RELOAD)
	{
		int curWeapon = GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon");

		if (!IsValidEntity(curWeapon))
		{
			return Plugin_Continue;
		}

		int curWeaponIndex = GetEntProp(curWeapon, Prop_Send, "m_iItemDefinitionIndex");

		switch (curWeaponIndex)
		{
			case 730: // Beggar's Bazooka
			{
				buttons ^= IN_RELOAD;

				if (GetEntProp(curWeapon, Prop_Data, "m_iClip1") < 4)
				{
					buttons |= IN_ATTACK;
				}

				return Plugin_Changed;
			}
			case 595: // Manmelter
			{
				buttons ^= IN_RELOAD;
				buttons |= IN_ATTACK2;
				return Plugin_Changed;
			}
		}
	}

	return Plugin_Continue;
}

public void player_inv(Handle event, const char[] ename, bool dontBroadcast)
{
	if (!g_bCVEnabled || g_bSuddenDeathMode || (g_bMVM && !g_bCVMVMSupported))
	{
		return;
	}

	int userid = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userid);
	delete g_hTouched[client];

	if (!IsPlayerHere(client) || !IsPlayerAllowed(client))
	{
		return;
	}

	float cvdelay = g_fCVDelay;

	if (g_bCVRandomizeDelay && (cvdelay > 0.1))
	{
		cvdelay = GetRandomUFloat(0.1, cvdelay);
	}

	g_hTouched[client] = CreateTimer(cvdelay, Timer_GiveWeapons, userid, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_GiveWeapons(Handle timer, any data)
{
	int client = GetClientOfUserId(data);
	g_hTouched[client] = null;

	if (!g_bCVEnabled || g_bSuddenDeathMode || (g_bMVM && !g_bCVMVMSupported) || !IsPlayerHere(client) || !IsPlayerAllowed(client))
	{
		return Plugin_Stop;
	}

	TFClassType class = TF2_GetPlayerClass(client);

	if (GameRules_GetProp("m_bPlayingMedieval") != 1)
	{
		SelectClassWeapons(client, class);
	}
	else
	{
		SelectMedievalClassWeapons(client, class);
	}

	SelectActionItem(client);
	CreateTimer(0.1, TimerHealth, client, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

void SelectActionItem(int client)
{
	int rnd = GetRandomUInt(0,3);

	switch (rnd)
	{
		case 1:
		{
			CreateWeapon(client, "tf_wearable", -1, 241, 5, true); // Duel MiniGame
		}
		case 2:
		{
			CreateWeapon(client, "tf_powerup_bottle", -1, 489, _, true); // Power Up Canteen
		}
		case 3:
		{
			CreateWeapon(client, "tf_weapon_spellbook", -1, 1069, 1, false); // Halloween Spellbook
		}
	}
}

void SelectMedievalClassWeapons(int client, TFClassType class)
{
	int rnd = 0;

	switch (class)
	{
		case TFClass_Scout:
		{
			rnd = GetRandomUInt(0,13);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_weapon_bat_wood", 2, 44, 15); // Sandman
				}
				case 2:
				{
					CreateWeapon(client, "tf_weapon_bat_fish", 2, 572); // Unarmed Combat
				}
				case 3:
				{
					CreateWeapon(client, "tf_weapon_bat", 2, 317, 25);  // Candy Cane
				}
				case 4:
				{
					CreateWeapon(client, "tf_weapon_bat", 2, 349, 10); // Sun-on-a-Stick
				}
				case 5:
				{
					CreateWeapon(client, "tf_weapon_bat", 2, 355, 5); // Fan O'War
				}
				case 6:
				{
					CreateWeapon(client, "tf_weapon_bat_giftwrap", 2, 648, 15); // Wrap Assassin
				}
				case 7:
				{
					CreateWeapon(client, "tf_weapon_bat", 2, 450, 10); // Atomizer
				}
				case 8:
				{
					CreateWeapon(client, "tf_weapon_bat_fish", 2, 221); // Holy Mackerel
				}
				case 9:
				{
					CreateWeapon(client, "tf_weapon_bat", 2, 1013, 5); // Ham Shank
				}
				case 10:
				{
					CreateWeapon(client, "tf_weapon_bat", 2, 939, 5); // Bat Outta Hell
				}
				case 11:
				{
					CreateWeapon(client, "tf_weapon_bat", 2, 880, 25); // Freedom Staff
				}
				case 12:
				{
					CreateWeapon(client, "tf_weapon_bat", 2, 474, 25); // Conscientious Objector
				}
				case 13:
				{
					CreateWeapon(client, "tf_weapon_bat", 2, 1123, 50); // Necro Smasher
				}
			}
		}
		case TFClass_Sniper:
		{
			rnd = GetRandomUInt(0,3);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_wearable", 1, 57, 10, true); // Razorback
				}
				case 2:
				{
					CreateWeapon(client, "tf_wearable", 1, 231, 10, true); // Darwin's Danger Shield
				}
				case 3:
				{
					CreateWeapon(client, "tf_wearable", 1, 642, 10, true); // Cozy Camper
				}
			}

			rnd = GetRandomUInt(0,8);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_weapon_club", 2, 171, 5); // Tribalman's Shiv
				}
				case 2:
				{
					CreateWeapon(client, "tf_weapon_club", 2, 232, 5); // Bushwacka
				}
				case 3:
				{
					CreateWeapon(client, "tf_weapon_club", 2, 401, 5); // Shahanshah
				}
				case 4:
				{
					CreateWeapon(client, "tf_weapon_club", 2, 1013, 5); // Ham Shank
				}
				case 5:
				{
					CreateWeapon(client, "tf_weapon_club", 2, 939, 5); // Bat Outta Hell
				}
				case 6:
				{
					CreateWeapon(client, "tf_weapon_club", 2, 880, 25); // Freedom Staff
				}
				case 7:
				{
					CreateWeapon(client, "tf_weapon_club", 2, 474, 25); // Conscientious Objector
				}
				case 8:
				{
					CreateWeapon(client, "tf_weapon_club", 2, 1123, 50); // Necro Smasher
				}
			}
		}
		case TFClass_Soldier:
		{
			rnd = GetRandomUInt(0,2);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_wearable", 1, 133, 10, true); // Gunboats
				}
				case 2:
				{
					CreateWeapon(client, "tf_wearable", 1, 444, 10, true); // Mantreads
				}
			}

			rnd = GetRandomUInt(0,10);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_weapon_shovel", 2, 128, 10); // Equalizer
				}
				case 2:
				{
					CreateWeapon(client, "tf_weapon_shovel", 2, 154, 5); // Pain Train
				}
				case 3:
				{
					CreateWeapon(client, "tf_weapon_shovel", 2, 447, 10); // Disciplinary Action
				}
				case 4:
				{
					CreateWeapon(client, "tf_weapon_shovel", 2, 775, 10); // Escape Plan
				}
				case 5:
				{
					CreateWeapon(client, "tf_weapon_katana", 2, 357, 5); // Half-Zatoichi
				}
				case 6:
				{
					CreateWeapon(client, "tf_weapon_shovel", 2, 1013, 5); // Ham Shank
				}
				case 7:
				{
					CreateWeapon(client, "tf_weapon_shovel", 2, 939, 5); // Bat Outta Hell
				}
				case 8:
				{
					CreateWeapon(client, "tf_weapon_shovel", 2, 880, 25); // Freedom Staff
				}
				case 9:
				{
					CreateWeapon(client, "tf_weapon_shovel", 2, 474, 25); // Conscientious Objector
				}
				case 10:
				{
					CreateWeapon(client, "tf_weapon_shovel", 2, 1123, 50); // Necro Smasher
				}
			}
		}
		case TFClass_DemoMan:
		{
			rnd = GetRandomUInt(0,2);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_wearable", 0, 405, 10, true); // Ali Baba's Wee Booties
				}
				case 2:
				{
					CreateWeapon(client, "tf_wearable", 0, 608, 10, true); // Bootlegger
				}
			}

			rnd = GetRandomUInt(0,3);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_wearable_demoshield", 1, 131, _, true); // Chargin' Targe
				}
				case 2:
				{
					CreateWeapon(client, "tf_wearable_demoshield", 1, 406, 10, true); // Splendid Screen
				}
				case 3:
				{
					CreateWeapon(client, "tf_wearable_demoshield", 1, 1099, _, true); // Tide Turner
				}
			}

			rnd = GetRandomUInt(0,14);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_weapon_sword", 2, 132, 5); // Eyelander
				}
				case 2:
				{
					CreateWeapon(client, "tf_weapon_shovel", 2, 154, 5); // Pain Train
				}
				case 3:
				{
					CreateWeapon(client, "tf_weapon_sword", 2, 172, 5); // Scotsman's Skullcutter
				}
				case 4:
				{
					CreateWeapon(client, "tf_weapon_stickbomb", 2, 307, 10); // Ullapool Caber
				}
				case 5:
				{
					CreateWeapon(client, "tf_weapon_sword", 2, 327, 10); // Claidheamohmor
				}
				case 6:
				{
					CreateWeapon(client, "tf_weapon_katana", 2, 357, 5); // Half-Zatoichi
				}
				case 7:
				{
					CreateWeapon(client, "tf_weapon_sword", 2, 482, 5); // Nessie's Nine Iron
				}
				case 8:
				{
					CreateWeapon(client, "tf_weapon_bottle", 2, 609, 10); // Scottish Handshake
				}
				case 9:
				{
					CreateWeapon(client, "tf_weapon_bottle", 2, 1013, 5); // Ham Shank
				}
				case 10:
				{
					CreateWeapon(client, "tf_weapon_bottle", 2, 939, 5); // Bat Outta Hell
				}
				case 11:
				{
					CreateWeapon(client, "tf_weapon_bottle", 2, 880, 25); // Freedom Staff
				}
				case 12:
				{
					CreateWeapon(client, "tf_weapon_bottle", 2, 474, 25); // Conscientious Objector
				}
				case 13:
				{
					CreateWeapon(client, "tf_weapon_sword", 2, 404); // Persian Persuader
				}
				case 14:
				{
					CreateWeapon(client, "tf_weapon_bottle", 2, 1123, 50); // Necro Smasher
				}
			}
		}
		case TFClass_Medic:
		{
			rnd = GetRandomUInt(0,9);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_weapon_bonesaw", 2, 37, 10); // Ubersaw
				}
				case 2:
				{
					CreateWeapon(client, "tf_weapon_bonesaw", 2, 173, 5); // Vita-Saw
				}
				case 3:
				{
					CreateWeapon(client, "tf_weapon_bonesaw", 2, 304, 15);  // Amputator
				}
				case 4:
				{
					CreateWeapon(client, "tf_weapon_bonesaw", 2, 413, 10); // Solemn Vow
				}
				case 5:
				{
					CreateWeapon(client, "tf_weapon_bonesaw", 2, 1013, 5); // Ham Shank
				}
				case 6:
				{
					CreateWeapon(client, "tf_weapon_bonesaw", 2, 939, 5); // Bat Outta Hell
				}
				case 7:
				{
					CreateWeapon(client, "tf_weapon_bonesaw", 2, 880, 25); // Freedom Staff
				}
				case 8:
				{
					CreateWeapon(client, "tf_weapon_bonesaw", 2, 474, 25); // Conscientious Objector
				}
				case 9:
				{
					CreateWeapon(client, "tf_weapon_bonesaw", 2, 1123, 50); // Necro Smasher
				}
			}
		}
		case TFClass_Heavy:
		{
			rnd = GetRandomUInt(0,12);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_weapon_fists", 2, 43, 7); // Killing Gloves of Boxing
				}
				case 2:
				{
					CreateWeapon(client, "tf_weapon_fists", 2, 239, 10); // Gloves of Running Urgently
				}
				case 3:
				{
					CreateWeapon(client, "tf_weapon_fists", 2, 310, 10); // Warrior's Spirit
				}
				case 4:
				{
					CreateWeapon(client, "tf_weapon_fists", 2, 331, 10); // Fists of Steel
				}
				case 5:
				{
					CreateWeapon(client, "tf_weapon_fists", 2, 426, 10); // Eviction Notice
				}
				case 6:
				{
					CreateWeapon(client, "tf_weapon_fists", 2, 656, 10);  // Holiday Punch
				}
				case 7:
				{
					CreateWeapon(client, "tf_weapon_fists", 2, 587, 10); // Apoco-Fists
				}
				case 8:
				{
					CreateWeapon(client, "tf_weapon_fireaxe", 2, 1013, 5); // Ham Shank
				}
				case 9:
				{
					CreateWeapon(client, "tf_weapon_fireaxe", 2, 939, 5); // Bat Outta Hell
				}
				case 10:
				{
					CreateWeapon(client, "tf_weapon_fireaxe", 2, 880, 25); // Freedom Staff
				}
				case 11:
				{
					CreateWeapon(client, "tf_weapon_fireaxe", 2, 474, 25); // Conscientious Objector
				}
				case 12:
				{
					CreateWeapon(client, "tf_weapon_fireaxe", 2, 1123, 50); // Necro Smasher
				}
			}
		}
		case TFClass_Pyro:
		{
			rnd = GetRandomUInt(0,16);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_weapon_fireaxe", 2, 38, 10); // Axtinguisher
				}
				case 2:
				{
					CreateWeapon(client, "tf_weapon_fireaxe", 2, 153, 5); // Homewrecker
				}
				case 3:
				{
					CreateWeapon(client, "tf_weapon_fireaxe", 2, 214, 5); // Powerjack
				}
				case 4:
				{
					CreateWeapon(client, "tf_weapon_fireaxe", 2, 326, 10); // Back Scratcher
				}
				case 5:
				{
					CreateWeapon(client, "tf_weapon_fireaxe", 2, 348, 10); // Sharpened Volcano Fragment
				}
				case 6:
				{
					CreateWeapon(client, "tf_weapon_fireaxe", 2, 593, 10); // Third Degree
				}
				case 7:
				{
					CreateWeapon(client, "tf_weapon_breakable_sign", 2, 813); // Neon Annihilator
				}
				case 8:
				{
					CreateWeapon(client, "tf_weapon_fireaxe", 2, 457, 10); // Postal Pummeler
				}
				case 9:
				{
					CreateWeapon(client, "tf_weapon_fireaxe", 2, 739); // Lollichop
				}
				case 10:
				{
					CreateWeapon(client, "tf_weapon_slap", 2, 1181); // Hot Hand
				}
				case 11:
				{
					CreateWeapon(client, "tf_weapon_fireaxe", 2, 466, 5); // Maul
				}
				case 12:
				{
					CreateWeapon(client, "tf_weapon_fireaxe", 2, 1013, 5); // Ham Shank
				}
				case 13:
				{
					CreateWeapon(client, "tf_weapon_fireaxe", 2, 939, 5); // Bat Outta Hell
				}
				case 14:
				{
					CreateWeapon(client, "tf_weapon_fireaxe", 2, 880, 25); // Freedom Staff
				}
				case 15:
				{
					CreateWeapon(client, "tf_weapon_fireaxe", 2, 474, 25); // Conscientious Objector
				}
				case 16:
				{
					CreateWeapon(client, "tf_weapon_fireaxe", 2, 1123, 50); // Necro Smasher
				}
			}
		}
		case TFClass_Spy:
		{
			rnd = GetRandomUInt(0,6);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_weapon_knife", 2, 356, 1); // Conniver's Kunai
				}
				case 2:
				{
					CreateWeapon(client, "tf_weapon_knife", 2, 461, 1); // Big Earner
				}
				case 3:
				{
					CreateWeapon(client, "tf_weapon_knife", 2, 649, 1); // Spy-cicle
				}
				case 4:
				{
					CreateWeapon(client, "tf_weapon_knife", 2, 638, 1); // Sharp Dresser
				}
				case 5:
				{
					CreateWeapon(client, "tf_weapon_knife", 2, 225, 1); // Your Eternal Reward
				}
				case 6:
				{
					CreateWeapon(client, "tf_weapon_knife", 2, 574); // Wanga Prick
				}
			}

			rnd = GetRandomUInt(0,1);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_weapon_invis", 4, 947); // Quackenbirdt
				}
			}
		}
		case TFClass_Engineer:
		{
			rnd = GetRandomUInt(0,5);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_weapon_wrench", 2, 155, 20); // Southern Hospitality
				}
				case 2:
				{
					CreateWeapon(client, "tf_weapon_wrench", 2, 329, 15); // Jag
				}
				case 3:
				{
					CreateWeapon(client, "tf_weapon_wrench", 2, 1123, 50); // Necro Smasher
				}
				case 4:
				{
					CreateWeapon(client, "tf_weapon_robot_arm", 2, 142, 15); // Gunslinger
				}
				case 5:
				{
					CreateWeapon(client, "tf_weapon_wrench", 2, 589, 50); // Eureka Effect
				}
			}
		}
	}
}

void SelectClassWeapons(int client, TFClassType class)
{
	int rnd = 0;

	switch (class)
	{
		case TFClass_Scout:
		{
			rnd = GetRandomUInt(0,5);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_weapon_scattergun", 0, 45, 10); // Force-a-Nature
				}
				case 2:
				{
					CreateWeapon(client, "tf_weapon_handgun_scout_primary", 0, 220, 1);  // Shortstop
				}
				case 3:
				{
					CreateWeapon(client, "tf_weapon_soda_popper", 0, 448, 10); // Soda Popper
				}
				case 4:
				{
					CreateWeapon(client, "tf_weapon_pep_brawler_blaster", 0, 772, 10); // Baby Face's Blaster
				}
				case 5:
				{
					CreateWeapon(client, "tf_weapon_scattergun", 0, 1103); // Back Scatter
				}
			}

			rnd = GetRandomUInt(0,2);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_weapon_handgun_scout_secondary", 1, 773, 10);  // Pretty Boy's Pocket Pistol
				}
				case 2:
				{
					CreateWeapon(client, "tf_weapon_handgun_scout_secondary", 1, 449, 15);  // Winger
				}
			}

			rnd = GetRandomUInt(0,13);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_weapon_bat_wood", 2, 44, 15); // Sandman
				}
				case 2:
				{
					CreateWeapon(client, "tf_weapon_bat_fish", 2, 572); // Unarmed Combat
				}
				case 3:
				{
					CreateWeapon(client, "tf_weapon_bat", 2, 317, 25);  // Candy Cane
				}
				case 4:
				{
					CreateWeapon(client, "tf_weapon_bat", 2, 349, 10); // Sun-on-a-Stick
				}
				case 5:
				{
					CreateWeapon(client, "tf_weapon_bat", 2, 355, 5); // Fan O'War
				}
				case 6:
				{
					CreateWeapon(client, "tf_weapon_bat_giftwrap", 2, 648, 15); // Wrap Assassin
				}
				case 7:
				{
					CreateWeapon(client, "tf_weapon_bat", 2, 450, 10); // Atomizer
				}
				case 8:
				{
					CreateWeapon(client, "tf_weapon_bat_fish", 2, 221);  // Holy Mackerel
				}
				case 9:
				{
					CreateWeapon(client, "tf_weapon_bat", 2, 1013, 5);  // Ham Shank
				}
				case 10:
				{
					CreateWeapon(client, "tf_weapon_bat", 2, 939, 5); // Bat Outta Hell
				}
				case 11:
				{
					CreateWeapon(client, "tf_weapon_bat", 2, 880, 25); // Freedom Staff
				}
				case 12:
				{
					CreateWeapon(client, "tf_weapon_bat", 2, 474, 25);  // Conscientious Objector
				}
				case 13:
				{
					CreateWeapon(client, "tf_weapon_bat", 2, 1123, 50);  // Necro Smasher
				}
			}
		}
		case TFClass_Sniper:
		{
			rnd = GetRandomUInt(0,8);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_weapon_compound_bow", 0, 56, 10); // Huntsman
				}
				case 2:
				{
					CreateWeapon(client, "tf_weapon_sniperrifle", 0, 230, 1); // Sydney Sleeper
				}
				case 3:
				{
					CreateWeapon(client, "tf_weapon_sniperrifle_decap", 0, 402, 10); // Bazaar Bargain
				}
				case 4:
				{
					CreateWeapon(client, "tf_weapon_sniperrifle", 0, 526, 5); // Machina
				}
				case 5:
				{
					CreateWeapon(client, "tf_weapon_sniperrifle", 0, 752, 1); // Hitman's Heatmaker
				}
				case 6:
				{
					CreateWeapon(client, "tf_weapon_sniperrifle_classic", 0, 1098, 1); // Classic
				}
				case 7:
				{
					CreateWeapon(client, "tf_weapon_compound_bow", 0, 1092, 10); // Fortified Compound
				}
				case 8:
				{
					CreateWeapon(client, "tf_weapon_sniperrifle", 0, 851, 1); // AWPer Hand
				}
			}

			rnd = GetRandomUInt(0,1);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_weapon_charged_smg", 1, 751, 1); // Cleaner's Carabine
				}
			}

			rnd = GetRandomUInt(0,8);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_weapon_club", 2, 171, 5); // Tribalman's Shiv
				}
				case 2:
				{
					CreateWeapon(client, "tf_weapon_club", 2, 232, 5); // Bushwacka
				}
				case 3:
				{
					CreateWeapon(client, "tf_weapon_club", 2, 401, 5); // Shahanshah
				}
				case 4:
				{
					CreateWeapon(client, "tf_weapon_club", 2, 1013, 5); // Ham Shank
				}
				case 5:
				{
					CreateWeapon(client, "tf_weapon_club", 2, 939, 5); // Bat Outta Hell
				}
				case 6:
				{
					CreateWeapon(client, "tf_weapon_club", 2, 880, 25); // Freedom Staff
				}
				case 7:
				{
					CreateWeapon(client, "tf_weapon_club", 2, 474, 25); // Conscientious Objector
				}
				case 8:
				{
					CreateWeapon(client, "tf_weapon_club", 2, 1123, 50); // Necro Smasher
				}
			}
		}
		case TFClass_Soldier:
		{
			rnd = GetRandomUInt(0,7);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_weapon_rocketlauncher_directhit", 0, 127, 1); // Direct Hit
				}
				case 2:
				{
					CreateWeapon(client, "tf_weapon_rocketlauncher", 0, 228, 5); // Black Box
				}
				case 3:
				{
					CreateWeapon(client, "tf_weapon_rocketlauncher", 0, 414, 25); // Liberty Launcher
				}
				case 4:
				{
					CreateWeapon(client, "tf_weapon_particle_cannon", 0, 441, 30); // Cow Mangler 5000
				}
				case 5:
				{
					CreateWeapon(client, "tf_weapon_rocketlauncher", 0, 513, 5); // Original
				}
				case 6:
				{
					CreateWeapon(client, "tf_weapon_rocketlauncher_airstrike", 0, 1104); // Air Strike
				}
				case 7:
				{
					CreateWeapon(client, "tf_weapon_rocketlauncher", 0, 730); // Beggar's Bazooka
				}
			}

			rnd = GetRandomUInt(0,3);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_weapon_raygun", 1, 442, 30); // Righteous Bison
				}
				case 2:
				{
					CreateWeapon(client, "tf_weapon_shotgun_soldier", 1, 1153); // Panic Attack Shotgun
				}
				case 3:
				{
					CreateWeapon(client, "tf_weapon_shotgun_soldier", 1, 415, 10); // Reserve Shooter
				}
			}

			rnd = GetRandomUInt(0,10);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_weapon_shovel", 2, 128, 10); // Equalizer
				}
				case 2:
				{
					CreateWeapon(client, "tf_weapon_shovel", 2, 154, 5); // Pain Train
				}
				case 3:
				{
					CreateWeapon(client, "tf_weapon_shovel", 2, 447, 10); // Disciplinary Action
				}
				case 4:
				{
					CreateWeapon(client, "tf_weapon_shovel", 2, 775, 10); // Escape Plan
				}
				case 5:
				{
					CreateWeapon(client, "tf_weapon_katana", 2, 357, 5); // Half-Zatoichi
				}
				case 6:
				{
					CreateWeapon(client, "tf_weapon_shovel", 2, 1013, 5); // Ham Shank
				}
				case 7:
				{
					CreateWeapon(client, "tf_weapon_shovel", 2, 939, 5);  // Bat Outta Hell
				}
				case 8:
				{
					CreateWeapon(client, "tf_weapon_shovel", 2, 880, 25); // Freedom Staff
				}
				case 9:
				{
					CreateWeapon(client, "tf_weapon_shovel", 2, 474, 25); // Conscientious Objector
				}
				case 10:
				{
					CreateWeapon(client, "tf_weapon_shovel", 2, 1123, 50); // Necro Smasher
				}
			}
		}
		case TFClass_DemoMan:
		{
			rnd = GetRandomUInt(0,2);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_weapon_grenadelauncher", 0, 1151); // Iron Bomber
				}
				case 2:
				{
					CreateWeapon(client, "tf_weapon_cannon", 0, 996, 10); // Loose Cannon
				}
			}

			rnd = GetRandomUInt(0,1);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_weapon_pipebomblauncher", 1, 1150); // Quickiebomb Launcher
				}
			}

			rnd = GetRandomUInt(0,13);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_weapon_sword", 2, 132, 5); // Eyelander
				}
				case 2:
				{
					CreateWeapon(client, "tf_weapon_shovel", 2, 154, 5); // Pain Train
				}
				case 3:
				{
					CreateWeapon(client, "tf_weapon_sword", 2, 172, 5); // Scotsman's Skullcutter
				}
				case 4:
				{
					CreateWeapon(client, "tf_weapon_stickbomb", 2, 307, 10); // Ullapool Caber
				}
				case 5:
				{
					CreateWeapon(client, "tf_weapon_sword", 2, 327, 10); // Claidheamohmor
				}
				case 6:
				{
					CreateWeapon(client, "tf_weapon_katana", 2, 357, 5); // Half-Zatoichi
				}
				case 7:
				{
					CreateWeapon(client, "tf_weapon_sword", 2, 482, 5); // Nessie's Nine Iron
				}
				case 8:
				{
					CreateWeapon(client, "tf_weapon_bottle", 2, 609, 10); // Scottish Handshake
				}
				case 9:
				{
					CreateWeapon(client, "tf_weapon_bottle", 2, 1013, 5); // Ham Shank
				}
				case 10:
				{
					CreateWeapon(client, "tf_weapon_bottle", 2, 939, 5); // Bat Outta Hell
				}
				case 11:
				{
					CreateWeapon(client, "tf_weapon_bottle", 2, 880, 25); // Freedom Staff
				}
				case 12:
				{
					CreateWeapon(client, "tf_weapon_bottle", 2, 474, 25); // Conscientious Objector
				}
				case 13:
				{
					CreateWeapon(client, "tf_weapon_bottle", 2, 1123, 50); // Necro Smasher
				}
			}
		}
		case TFClass_Medic:
		{
			rnd = GetRandomUInt(0,3);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_weapon_syringegun_medic", 0, 36, 5); // Blutsauger
				}
				case 2:
				{
					CreateWeapon(client, "tf_weapon_crossbow", 0, 305, 15); // Crusader's Crossbow
				}
				case 3:
				{
					CreateWeapon(client, "tf_weapon_syringegun_medic", 0, 412, 5); // Overdose
				}
			}

			rnd = GetRandomUInt(0,3);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_weapon_medigun", 1, 35, 8); // Kritzkrieg
				}
				case 2:
				{
					CreateWeapon(client, "tf_weapon_medigun", 1, 411, 8); // Quick-Fix
				}
				case 3:
				{
					CreateWeapon(client, "tf_weapon_medigun", 1, 998, 8); // Vaccinator
				}
			}

			rnd = GetRandomUInt(0,9);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_weapon_bonesaw", 2, 37, 10); // Ubersaw
				}
				case 2:
				{
					CreateWeapon(client, "tf_weapon_bonesaw", 2, 173, 5); // Vita-Saw
				}
				case 3:
				{
					CreateWeapon(client, "tf_weapon_bonesaw", 2, 304, 15); // Amputator
				}
				case 4:
				{
					CreateWeapon(client, "tf_weapon_bonesaw", 2, 413, 10); // Solemn Vow
				}
				case 5:
				{
					CreateWeapon(client, "tf_weapon_bonesaw", 2, 1013, 5); // Ham Shank
				}
				case 6:
				{
					CreateWeapon(client, "tf_weapon_bonesaw", 2, 939, 5); // Bat Outta Hell
				}
				case 7:
				{
					CreateWeapon(client, "tf_weapon_bonesaw", 2, 880, 25); // Freedom Staff
				}
				case 8:
				{
					CreateWeapon(client, "tf_weapon_bonesaw", 2, 474, 25); // Conscientious Objector
				}
				case 9:
				{
					CreateWeapon(client, "tf_weapon_bonesaw", 2, 1123, 50); // Necro Smasher
				}
			}
		}
		case TFClass_Heavy:
		{
			rnd = GetRandomUInt(0,4);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_weapon_minigun", 0, 41, 5); // Natascha
				}
				case 2:
				{
					CreateWeapon(client, "tf_weapon_minigun", 0, 312, 5); // Brass Beast
				}
				case 3:
				{
					CreateWeapon(client, "tf_weapon_minigun", 0, 424, 5); // Tomislav
				}
				case 4:
				{
					CreateWeapon(client, "tf_weapon_minigun", 0, 811); // Huo Long Heatmaker
				}
			}

			rnd = GetRandomUInt(0,2);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_weapon_shotgun_hwg", 1, 425, 10); // Family Business
				}
				case 2:
				{
					CreateWeapon(client, "tf_weapon_shotgun_hwg", 1, 1153); // Panic Attack Shotgun
				}
			}

			rnd = GetRandomUInt(0,12);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_weapon_fists", 2, 43, 7); // Killing Gloves of Boxing
				}
				case 2:
				{
					CreateWeapon(client, "tf_weapon_fists", 2, 239, 10); // Gloves of Running Urgently
				}
				case 3:
				{
					CreateWeapon(client, "tf_weapon_fists", 2, 310, 10); // Warrior's Spirit
				}
				case 4:
				{
					CreateWeapon(client, "tf_weapon_fists", 2, 331, 10); // Fists of Steel
				}
				case 5:
				{
					CreateWeapon(client, "tf_weapon_fists", 2, 426, 10); // Eviction Notice
				}
				case 6:
				{
					CreateWeapon(client, "tf_weapon_fists", 2, 656, 10); // Holiday Punch
				}
				case 7:
				{
					CreateWeapon(client, "tf_weapon_fists", 2, 587, 10);  // Apoco-Fists
				}
				case 8:
				{
					CreateWeapon(client, "tf_weapon_fireaxe", 2, 1013, 5); // Ham Shank
				}
				case 9:
				{
					CreateWeapon(client, "tf_weapon_fireaxe", 2, 939, 5); // Bat Outta Hell
				}
				case 10:
				{
					CreateWeapon(client, "tf_weapon_fireaxe", 2, 880, 25); // Freedom Staff
				}
				case 11:
				{
					CreateWeapon(client, "tf_weapon_fireaxe", 2, 474, 25); // Conscientious Objector
				}
				case 12:
				{
					CreateWeapon(client, "tf_weapon_fireaxe", 2, 1123, 50); // Necro Smasher
				}
			}
		}
		case TFClass_Pyro:
		{
			rnd = GetRandomUInt(0,6);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_weapon_flamethrower", 0, 40, 10); // Backburner
				}
				case 2:
				{
					CreateWeapon(client, "tf_weapon_flamethrower", 0, 215, 10); // Degreaser
				}
				case 3:
				{
					CreateWeapon(client, "tf_weapon_flamethrower", 0, 594, 10); // Phlogistinator
				}
				case 4:
				{
					CreateWeapon(client, "tf_weapon_flamethrower", 0, 741, 10); // Rainblower
				}
				case 5:
				{
					CreateWeapon(client, "tf_weapon_rocketlauncher_fireball", 0, 1178); // Dragon's Fury
				}
				case 6:
				{
					CreateWeapon(client, "tf_weapon_flamethrower", 0, 30474, 25); // Nostromo Napalmer
				}
			}

			rnd = GetRandomUInt(0,6);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_weapon_flaregun", 1, 39, 10); // Flare gun
				}
				case 2:
				{
					CreateWeapon(client, "tf_weapon_flaregun", 1, 351, 10); // Detonator
				}
				case 3:
				{
					CreateWeapon(client, "tf_weapon_flaregun_revenge", 1, 595, 30);  // Manmelter
				}
				case 4:
				{
					CreateWeapon(client, "tf_weapon_flaregun", 1, 740, 10); // Scorch Shot
				}
				case 5:
				{
					CreateWeapon(client, "tf_weapon_shotgun_pyro", 1, 1153); // Panic Attack Shotgun
				}
				case 6:
				{
					CreateWeapon(client, "tf_weapon_shotgun_pyro", 1, 415, 10); // Reserve Shooter
				}
			}

			rnd = GetRandomUInt(0,16);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_weapon_fireaxe", 2, 38, 10); // Axtinguisher
				}
				case 2:
				{
					CreateWeapon(client, "tf_weapon_fireaxe", 2, 153, 5); // Homewrecker
				}
				case 3:
				{
					CreateWeapon(client, "tf_weapon_fireaxe", 2, 214, 5); // Powerjack
				}
				case 4:
				{
					CreateWeapon(client, "tf_weapon_fireaxe", 2, 326, 10); // Back Scratcher
				}
				case 5:
				{
					CreateWeapon(client, "tf_weapon_fireaxe", 2, 348, 10); // Sharpened Volcano Fragment
				}
				case 6:
				{
					CreateWeapon(client, "tf_weapon_fireaxe", 2, 593, 10); // Third Degree
				}
				case 7:
				{
					CreateWeapon(client, "tf_weapon_breakable_sign", 2, 813); // Neon Annihilator
				}
				case 8:
				{
					CreateWeapon(client, "tf_weapon_fireaxe", 2, 457, 10); // Postal Pummeler
				}
				case 9:
				{
					CreateWeapon(client, "tf_weapon_fireaxe", 2, 739); // Lollichop
				}
				case 10:
				{
					CreateWeapon(client, "tf_weapon_slap", 2, 1181); // Hot Hand
				}
				case 11:
				{
					CreateWeapon(client, "tf_weapon_fireaxe", 2, 466, 5); // Maul
				}
				case 12:
				{
					CreateWeapon(client, "tf_weapon_fireaxe", 2, 1013, 5); // Ham Shank
				}
				case 13:
				{
					CreateWeapon(client, "tf_weapon_fireaxe", 2, 939, 5); // Bat Outta Hell
				}
				case 14:
				{
					CreateWeapon(client, "tf_weapon_fireaxe", 2, 880, 25); // Freedom Staff
				}
				case 15:
				{
					CreateWeapon(client, "tf_weapon_fireaxe", 2, 474, 25); // Conscientious Objector
				}
				case 16:
				{
					CreateWeapon(client, "tf_weapon_fireaxe", 2, 1123, 50); // Necro Smasher
				}
			}
		}
		case TFClass_Spy:
		{
			rnd = GetRandomUInt(0,4);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_weapon_revolver", 0, 61, 5); // Ambassador
				}
				case 2:
				{
					CreateWeapon(client, "tf_weapon_revolver", 0, 224, 5); // L'Etranger
				}
				case 3:
				{
					CreateWeapon(client, "tf_weapon_revolver", 0, 460, 5); // Enforcer
				}
				case 4:
				{
					CreateWeapon(client, "tf_weapon_revolver", 0, 525, 5); // Diamondback
				}
			}

			rnd = GetRandomUInt(0,1);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_weapon_sapper", 1, 810); // Red-Tape Recorder
				}
			}

			rnd = GetRandomUInt(0,6);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_weapon_knife", 2, 356, 1); // Conniver's Kunai
				}
				case 2:
				{
					CreateWeapon(client, "tf_weapon_knife", 2, 461, 1); // Big Earner
				}
				case 3:
				{
					CreateWeapon(client, "tf_weapon_knife", 2, 649, 1); // Spy-cicle
				}
				case 4:
				{
					CreateWeapon(client, "tf_weapon_knife", 2, 638, 1); // Sharp Dresser
				}
				case 5:
				{
					CreateWeapon(client, "tf_weapon_knife", 2, 225, 1); // Your Eternal Reward
				}
				case 6:
				{
					CreateWeapon(client, "tf_weapon_knife", 2, 574); // Wanga Prick
				}
			}

			rnd = GetRandomUInt(0,1);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_weapon_invis", 4, 947); // Quackenbirdt
				}
			}
		}
		case TFClass_Engineer:
		{
			rnd = GetRandomUInt(0,5);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_weapon_sentry_revenge", 0, 141, 5); // Frontier Justice
				}
				case 2:
				{
					CreateWeapon(client, "tf_weapon_shotgun_building_rescue", 0, 997); // Rescue Ranger
				}
				case 3:
				{
					CreateWeapon(client, "tf_weapon_drg_pomson", 0, 588, 10); // Pomson 6000
				}
				case 4:
				{
					CreateWeapon(client, "tf_weapon_shotgun_primary", 0, 1153); // Panic Attack Shotgun
				}
				case 5:
				{
					CreateWeapon(client, "tf_weapon_shotgun_primary", 0, 527, 5); // Widowmaker
				}
			}

			rnd = GetRandomUInt(0,1);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_weapon_mechanical_arm", 1, 528, 5); // Short Circuit
				}
			}

			rnd = GetRandomUInt(0,5);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_weapon_wrench", 2, 155, 20); // Southern Hospitality
				}
				case 2:
				{
					CreateWeapon(client, "tf_weapon_wrench", 2, 329, 15); // Jag
				}
				case 3:
				{
					CreateWeapon(client, "tf_weapon_wrench", 2, 1123, 50); // Necro Smasher
				}
				case 4:
				{
					CreateWeapon(client, "tf_weapon_robot_arm", 2, 142, 15); // Gunslinger
				}
				case 5:
				{
					CreateWeapon(client, "tf_weapon_wrench", 2, 589, 20); // Eureka Effect
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
	HookEntities("func_respawnroom");
}

void HookEntities(const char[] classname)
{
	int targetEntity = g_iResourceEntity+1;

	while ((targetEntity = FindEntityByClassname(targetEntity, classname)) != -1)
	{
		SDKHook(targetEntity, SDKHook_StartTouch, OnStartTouchEntity);
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (g_bCVEnabled && (entity > MaxClients) && classname[0] == 't' && (strcmp(classname, "tf_dropped_weapon", false) == 0))
	{
		SDKHook(entity, SDKHook_SpawnPost, OnDroppedWeaponSpawnPost);
	}
}

public Action OnStartTouchEntity(int entity, int other)
{
	char classname[64];

	if ((other > MaxClients) && GetEntityClassname(other,classname,sizeof(classname)) && classname[0] == 't' && (strcmp(classname, "tf_dropped_weapon", false) == 0) && (GetEntProp(other, Prop_Send, "m_iAccountID") == -1))
	{
		RemoveEntity(other);
	}

	return Plugin_Continue;
}

public void OnDroppedWeaponSpawnPost(int entity)
{
	if (GetEntProp(entity, Prop_Send, "m_iAccountID") == -1)
	{
		if (g_bCVDroppedWeaponRemoval)
		{
			SetEntProp(entity, Prop_Send, "m_fEffects", EF_NODRAW);
			RemoveEntity(entity);
		}
		else
		{
			SetEntProp(entity, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS_TRIGGER);

			if (GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex") == 947) // Quackenbirdt
			{
				SetEntProp(entity, Prop_Send, "m_fEffects", EF_NODRAW);
			}
		}
	}
}

bool CreateWeapon(int client, char[] classname, int slot, int itemindex, int level = 0, bool wearable = false)
{
	if (!g_bCVExtraLogic && (itemindex == 730 || itemindex == 966))
	{
		return false;
	}

	int weapon = CreateEntityByName(classname);

	if (!IsValidEntity(weapon))
	{
		LogError("Failed to create a valid entity with class name [%s]! Skipping.", classname);
		return false;
	}

	char entclass[64];
	GetEntityNetClass(weapon, entclass, sizeof(entclass));
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iItemDefinitionIndex"), itemindex);
	SetEntData(weapon, FindSendPropInfo(entclass, "m_bInitialized"), 1);
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 6);
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iAccountID"), -1);
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityLevel"), (level ? level : GetRandomUInt(1,99)));

	switch (itemindex)
	{
		case 810: // Red-Tape Recorder
		{
			SetEntData(weapon, FindSendPropInfo(entclass, "m_iObjectType"), 3);
			SetEntData(weapon, FindSendPropInfo(entclass, "m_iObjectMode"), 0);
			SetEntData(weapon, FindDataMapInfo(weapon, "m_iSubType"), 3);
			SetEntDataArray(weapon, FindSendPropInfo(entclass, "m_aBuildableObjectTypes"), {0,0,0,1}, 4);
		}
		case 998: // Vaccinator
		{
			SetEntData(weapon, FindSendPropInfo(entclass, "m_nChargeResistType"), GetRandomUInt(0,2));
		}
		case 1178: // The Dragon's Fury
		{
			int iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
			int iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
			SetEntData(client, iAmmoTable+iOffset, 40, 4);
		}
		case 39,351,740: // Flare gun,Detonator,Scorch Shot
		{
			int iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
			int iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
			SetEntData(client, iAmmoTable+iOffset, 16, 4);
		}
	}

	if (!DispatchSpawn(weapon))
	{
		LogError("The created weapon entity [Class name: %s, Item index: %i, Index: %i], failed to spawn! Skipping.", classname, itemindex, weapon);
		RemoveEntity(weapon);
		return false;
	}

	if (slot > -1)
	{
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

	if ((slot > -1) && !wearable && (GetPlayerWeaponSlot(client, slot) != weapon))
	{
		LogError("The created weapon entity [Class name: %s, Item index: %i, Index: %i], failed to equip! This is probably caused by invalid gamedata.", classname, itemindex, weapon);
		RemoveEntity(weapon);
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
	return (!IsClientInGame(client) || g_iResourceEntity == -1 ? -1 : GetEntProp(g_iResourceEntity, Prop_Send, "m_iMaxHealth", _, client));
}

bool IsPlayerHere(int client)
{
	return (client && IsClientInGame(client) && IsFakeClient(client) && !IsClientReplay(client) && !IsClientSourceTV(client));
}

bool IsPlayerAllowed(int client)
{
	return ((g_iCVTeam == BOTH_TEAMS) || (GetClientTeam(client) == g_iCVTeam) ? true : false);
}

int GetRandomUInt(int min, int max)
{
	return (RoundToFloor(GetURandomFloat() * (max - min + 1)) + min);
}

float GetRandomUFloat(float min, float max)
{
	return ((GetURandomFloat() * (max - min + 0.01)) + min);
}