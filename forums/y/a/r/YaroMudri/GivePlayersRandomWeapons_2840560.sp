#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#pragma semicolon 1
#pragma newdecls required
#define PLUGIN_VERSION "1.43"

bool g_bSuddenDeathMode;
bool g_bMVM;
int g_iResourceEntity;
int g_iAttackPressed[MAXPLAYERS+1];
ConVar g_hCVTimer;
ConVar g_hCVEnabled;
ConVar g_hCVTeam;
ConVar g_hCVMVMSupport;
ConVar g_hCVDroppedWeaponRemoval;
Handle g_hWeaponEquip;
Handle g_hWWeaponEquip;
Handle g_hTouched[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "Give Players Random Weapons",
	author = "luki1412",
	description = "Gives TF2 players non-stock weapons",
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

	return APLRes_Success;
}

public void OnPluginStart()
{
	ConVar hCVversioncvar = CreateConVar("sm_gpw_version", PLUGIN_VERSION, "Give players Weapons version cvar", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hCVEnabled = CreateConVar("sm_gpw_enabled", "1", "Enables/disables this plugin", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCVTimer = CreateConVar("sm_gpw_delay", "0.1", "Delay for giving weapons to players", FCVAR_NONE, true, 0.1, true, 30.0);
	g_hCVTeam = CreateConVar("sm_gpw_team", "1", "Team to give weapons to: 1-both, 2-red, 3-blu", FCVAR_NONE, true, 1.0, true, 3.0);
	g_hCVMVMSupport = CreateConVar("sm_gpw_mvm", "0", "Enables/disables giving players weapons when MVM mode is enabled", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCVDroppedWeaponRemoval = CreateConVar("sm_gpw_droppedweaponremoval", "0", "Enables/disables removal of weapons dropped by players from this plugin", FCVAR_NONE, true, 0.0, true, 1.0);

	OnEnabledChanged(g_hCVEnabled, "", "");
	HookConVarChange(g_hCVEnabled, OnEnabledChanged);
	SetConVarString(hCVversioncvar, PLUGIN_VERSION);
	AutoExecConfig(true, "Give_Players_Weapons");

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

	if (!IsPlayerHere(victim))
	{
		return;
	}

	int actwep = GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon");
	int wep = GetPlayerWeaponSlot(victim, 0);
	int wep3 = GetPlayerWeaponSlot(victim, 2);
	int wepIndex, wepIndex3;

	if (IsValidEntity(wep))
	{
		wepIndex = GetEntProp(wep, Prop_Send, "m_iItemDefinitionIndex");
	}

	if (IsValidEntity(wep3))
	{
		wepIndex3 = GetEntProp(wep3, Prop_Send, "m_iItemDefinitionIndex");
	}

	switch (wepIndex)
	{
		case 594: // Phlogistinator
		{
			if ((wep == actwep) && (GetEntPropFloat(victim, Prop_Send, "m_flRageMeter") == 100.0))
			{
				FakeClientCommand(victim, "taunt");
			}
		}
	}

	switch (wepIndex3)
	{
		case 589:  // Eureka Effect
		{
			if ((wep3 == actwep) && (GetClientHealth(victim) < 60) && (GetRandomUInt(1,2) == 1))
			{
				FakeClientCommand(victim, "eureka_teleport 0");
			}
		}
		case 304:  // Amputator
		{
			if ((wep3 == actwep) && (GetClientHealth(victim) < 60) && (GetRandomUInt(1,2) == 1))
			{
				FakeClientCommand(victim, "taunt");
			}
		}
	}

	return;
}

public Action OnPlayerRunCmd(int victim, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (!GetConVarBool(g_hCVEnabled) || !IsPlayerHere(victim) || !IsPlayerAlive(victim))
	{
		return Plugin_Continue;
	}

	if (buttons&IN_ATTACK)
	{
		int actwep = GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon");
		int wep = GetPlayerWeaponSlot(victim, 0);
		int wep2 = GetPlayerWeaponSlot(victim, 1);
		int wep3 = GetPlayerWeaponSlot(victim, 2);
		int wepIndex, wepIndex2, wepIndex3;

		if (IsValidEntity(wep))
		{
			wepIndex = GetEntProp(wep, Prop_Send, "m_iItemDefinitionIndex");
		}

		if (IsValidEntity(wep2))
		{
			wepIndex2 = GetEntProp(wep2, Prop_Send, "m_iItemDefinitionIndex");
		}

		if (IsValidEntity(wep3))
		{
			wepIndex3 = GetEntProp(wep3, Prop_Send, "m_iItemDefinitionIndex");
		}

		switch (wepIndex)
		{
			case 448: // Soda Popper
			{
				if ((wep == actwep) && (GetEntPropFloat(victim, Prop_Send, "m_flHypeMeter") == 100.0))
				{
					buttons ^= IN_ATTACK;
					buttons |= IN_ATTACK2;
					return Plugin_Changed;
				}
			}
			case 752: // Hitman's Heatmaker
			{
				if ((wep == actwep) && (GetEntPropFloat(victim, Prop_Send, "m_flRageMeter") == 100.0))
				{
					buttons ^= IN_ATTACK;
					buttons |= IN_RELOAD;
					return Plugin_Changed;
				}
			}
			case 441: // Cow Mangler 5000
			{
				if ((wep == actwep) && (GetEntPropFloat(wep, Prop_Send, "m_flEnergy") == 20.0) && (GetRandomUInt(1,2) == 1))
				{
					buttons ^= IN_ATTACK;
					buttons |= IN_ATTACK2;
					return Plugin_Changed;
				}
			}
			case 996: // Loose Cannon
			{
				g_iAttackPressed[victim]++;
				if ((wep == actwep) && (g_iAttackPressed[victim] > 1))
				{
					buttons ^= IN_ATTACK;
					g_iAttackPressed[victim] = 0;
					return Plugin_Changed;
				}
			}
			case 730: // Beggar's Bazooka
			{
				if ((wep == actwep) && (GetEntProp(wep, Prop_Data, "m_iClip1") > 0))
				{
					buttons ^= IN_ATTACK;
					return Plugin_Changed;
				}
			}
		}

		switch (wepIndex2)
		{
			case 751: // Cleaner's Carabine
			{
				if ((wep2 == actwep) && (GetEntProp(wep, Prop_Data, "m_iClip1") > 18))
				{
					buttons |= IN_ATTACK2;
					return Plugin_Changed;
				}
			}
			case 528: // Short Circuit
			{
				if ((wep2 == actwep) && (GetRandomUInt(1,3) == 1))
				{
					buttons ^= IN_ATTACK;
					buttons |= IN_ATTACK2;
					return Plugin_Changed;
				}
			}
			case 998: // Vaccinator
			{
				g_iAttackPressed[victim]++;
				if ((wep2 == actwep) && (g_iAttackPressed[victim] > 200))
				{
					buttons |= IN_RELOAD;
					g_iAttackPressed[victim] = 0;
					return Plugin_Changed;
				}
			}
		}

		switch (wepIndex3)
		{
			case 44:  // Sandman
			{
				g_iAttackPressed[victim]++;
				if ((wep3 == actwep) && (g_iAttackPressed[victim] > 20))
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
				if ((wep3 == actwep) && (g_iAttackPressed[victim] > 15))
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
		int actwepa = GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon");
		int wepa = GetPlayerWeaponSlot(victim, 0);
		int wepIndexa;

		if (IsValidEntity(wepa))
		{
			wepIndexa = GetEntProp(wepa, Prop_Send, "m_iItemDefinitionIndex");
		}

		switch (wepIndexa)
		{
			case 730: // Beggar's Bazooka
			{
				if (wepa == actwepa)
				{
					buttons ^= IN_RELOAD;

					if (GetEntProp(wepa, Prop_Data, "m_iClip1") < 4)
					{
						buttons |= IN_ATTACK;
					}

					return Plugin_Changed;
				}
			}
		}
	}
	else if (buttons&IN_FORWARD)
	{
		int actwep = GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon");
		int wep2 = GetPlayerWeaponSlot(victim, 2);
		int wepIndex2;

		if (IsValidEntity(wep2))
		{
			wepIndex2 = GetEntProp(wep2, Prop_Send, "m_iItemDefinitionIndex");
		}

		switch (wepIndex2)
		{
			case 447:  // Disciplinary Action
			{
				if (wep2 == actwep)
				{
					buttons |= IN_ATTACK;
					return Plugin_Changed;
				}
			}
		}
	}

	return Plugin_Continue;
}

public void player_inv(Handle event, const char[] ename, bool dontBroadcast)
{
	if (!GetConVarBool(g_hCVEnabled) || g_bSuddenDeathMode || (g_bMVM && !GetConVarBool(g_hCVMVMSupport)))
	{
		return;
	}

	int userd = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userd);
	delete g_hTouched[client];

	if (!IsPlayerHere(client))
	{
		return;
	}

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

public Action Timer_GiveWeapons(Handle timer, any data)
{
	int client = GetClientOfUserId(data);
	g_hTouched[client] = null;

	if (!GetConVarBool(g_hCVEnabled) || g_bSuddenDeathMode || (g_bMVM && !GetConVarBool(g_hCVMVMSupport)) || !IsPlayerHere(client))
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

			rnd = GetRandomUInt(0,2);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_weapon_invis", 4, 947); // Quackenbirdt
				}
				case 2:
				{
					CreateWeapon(client, "tf_weapon_invis", 60, 947); // The Cloak and Dagger
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

			rnd = GetRandomUInt(0,5);

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
				case 3:
				{
					CreateWeapon(client, "tf_weapon_lunchbox_drink", 1, 46, 15);  // Bonk! Atomic Punch
				}
				case 4:
				{
					CreateWeapon(client, "tf_weapon_pistol", 1, 294, 15);  // Lugermorph
				}
				case 5:
				{
					CreateWeapon(client, "tf_weapon_jar_milk", 1, 222, 15);  // Mad Milk
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
			rnd = GetRandomUInt(0,8);

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
				case 8:
				{
					CreateWeapon(client, "tf_weapon_rocketlauncher", 0, 237); // Rocket Jumper
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

			rnd = GetRandomUInt(0,2);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_weapon_pipebomblauncher", 1, 1150); // Quickiebomb Launcher
				}
				case 2:
				{
					CreateWeapon(client, "tf_wearable_demoshield", 1, 1099, _, true); // Tide Turner
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

			rnd = GetRandomUInt(0,2);

			switch (rnd)
			{
				case 1:
				{
					CreateWeapon(client, "tf_weapon_invis", 4, 947); // Quackenbirdt
				}
				case 2:
				{
					CreateWeapon(client, "tf_weapon_invis", 60, 947); // The Cloak and Dagger
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
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (GetConVarBool(g_hCVEnabled) && GetConVarBool(g_hCVDroppedWeaponRemoval) && classname[0] == 't' && StrEqual(classname, "tf_dropped_weapon", false))
	{
		SDKHook(entity, SDKHook_SpawnPost, OnDroppedWeaponSpawnPost);
	}
}

public void OnDroppedWeaponSpawnPost(int entity)
{
	char entclass[64];
	GetEntityNetClass(entity, entclass, sizeof(entclass));
	int accId = GetEntData(entity, FindSendPropInfo(entclass, "m_iAccountID"));

	if (accId == 1)
	{
		AcceptEntityInput(entity, "Kill");
	}
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
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iAccountID"), 1);

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
		case 810: // Red-Tape Recorder
		{
			SetEntData(weapon, FindSendPropInfo(entclass, "m_iObjectType"), 3);
			SetEntData(weapon, FindDataMapInfo(weapon, "m_iSubType"), 3);
			int buildables[4] = {0,0,0,1};
			SetEntDataArray(weapon, FindSendPropInfo(entclass, "m_aBuildableObjectTypes"), buildables, 4);
		}
		case 998: // Vaccinator
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
		case 39,351,740: // Flare gun,Detonator,Scorch Shot
		{
			int iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
			int iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
			SetEntData(client, iAmmoTable+iOffset, 16, 4);
		}
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
    return (client && IsClientInGame(client) && !IsClientReplay(client) && !IsClientSourceTV(client));
}

int GetRandomUInt(int min, int max)
{
	return RoundToFloor(GetURandomFloat() * (max - min + 1)) + min;
}