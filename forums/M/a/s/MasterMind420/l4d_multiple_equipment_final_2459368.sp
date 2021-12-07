#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>

#pragma semicolon 1
#pragma newdecls required

#define LEN64 64
#define MAX_FRAMECHECK 20

int GameMode;
int L4D2Version;

MEOwner[2048+1] = {0, ...};
MEIndex[MAXPLAYERS+1] = {0, ...};
iModelIndex[MAXPLAYERS+1] = {0, ...};

LastButton[MAXPLAYERS+1];
LastWeapon[MAXPLAYERS+1];
ItemInfo[MAXPLAYERS+1][5][4];
ItemAttachEnt[MAXPLAYERS+1][5];
BackupItemInfo[MAXPLAYERS+1][5][4];

bool MsgOn[MAXPLAYERS+1];
bool TeamDeath[MAXPLAYERS+1];
bool bThirdPerson[MAXPLAYERS+1];

char VoteFix[MAXPLAYERS+1][32];
char ItemName[MAXPLAYERS+1][5][LEN64];
char BackupItemName[MAXPLAYERS+1][5][LEN64];

float Pos[3];
float Ang[3];
float InHeal[MAXPLAYERS+1];
float InRevive[MAXPLAYERS+1];
float SwapTime[MAXPLAYERS+1];
float ThrowTime[MAXPLAYERS+1];
float PressingTime[MAXPLAYERS+1];
float PressStartTime[MAXPLAYERS+1];
float LastSwitchTime[MAXPLAYERS+1];
float LastMeSwitchTime[MAXPLAYERS+1];

Handle l4d_me_mode;
Handle l4d_me_view;
Handle l4d_me_slot[5];
Handle l4d_me_afk_save;
Handle l4d_me_player_connect;
Handle l4d_me_custom_notify;
Handle l4d_me_custom_notify_msg;
Handle ME_Notify[MAXPLAYERS+1];
Handle AmmoLockSlot0 = INVALID_HANDLE;
Handle AmmoLockSlot1 = INVALID_HANDLE;
Handle AmmoUseDistance = INVALID_HANDLE;

public Plugin myinfo =
{
	name = "Multiple Equipment",
	author = "MasterMind420 & Ludastar & Pan Xiaohai & Marcus101RR",
	description = "Carry 2 items in each slot",
	version = "3.6",
	url = ""
}

public void OnPluginStart()
{
	GameCheck();

	l4d_me_slot[0] = CreateConVar("l4d_me_slot0", "1", "(Primary), 0=Disable, 1=Enable");
	l4d_me_slot[1] = CreateConVar("l4d_me_slot1", "0", "(Secondary), 0=Disable, 1=Enable");
	l4d_me_slot[2] = CreateConVar("l4d_me_slot2", "0", "(Pipebomb), 0=Disable, 1=Enable");
	l4d_me_slot[3] = CreateConVar("l4d_me_slot3", "1", "(Medkit), 0=Disable, 1=Enable");
	l4d_me_slot[4] = CreateConVar("l4d_me_slot4", "1", "(Pills), 0=Disable, 1=Enable");
	l4d_me_mode = CreateConVar("l4d_me_mode", "1", "1=Single Tap Mode, 2=Double Tap Mode");
	l4d_me_view = CreateConVar("l4d_me_view", "1", "0=Disable Extra Equipment View, 1=Enable Extra Equipment View");
	l4d_me_afk_save = CreateConVar("l4d_me_afk_save", "1", "0=Disable AFK Save, 1=Enable AFK Save");
	l4d_me_custom_notify = CreateConVar("l4d_me_custom_notify", "2", "0=Disable Custom Message, 1=Enable Chat Message, 2=Enable Hint Message");
	l4d_me_custom_notify_msg = CreateConVar("l4d_me_custom_notify_msg", "|| --->PRESS [H] FOR HELP<--- ||", "Create a custom welcome message for your server.");
	//l4d_me_thirdpersonshoulder_view = CreateConVar("l4d_me_thirdpersonshoulder_view", "1", "0=Disable Thirdpersonshoulder View, 1=Enable Thirdpersonshoulder View");
	l4d_me_player_connect = CreateConVar("l4d_me_player_connect", "1", "0=Disable Player Connect Message, 1=Enable Player Connect Message");
	AmmoLockSlot0 = CreateConVar("l4d_ammo_lock_slot0", "1", "0=Disable Lock Slot0 Ammo, 1=Enable Lock Slot0 Ammo", FCVAR_NOTIFY);
	AmmoLockSlot1 = CreateConVar("l4d_ammo_lock_slot1", "1", "[LOCK THIS SLOT IF USING LIMITED PISTOL AMMO], 0=Disable Lock Slot1 Ammo, 1=Enable Lock Slot1 Ammo", FCVAR_NOTIFY);
	AmmoUseDistance = CreateConVar("l4d2_ammo_pile_use_distance", "96", "This is the distance at which you use an ammo pile, for unlocking ammo only", FCVAR_NOTIFY);

	HookEvent("player_team", ePlayerTeam);
	HookEvent("player_death", ePlayerDeath, EventHookMode_Pre);
	HookEvent("player_disconnect", ePlayerDisconnect, EventHookMode_Pre);

	HookEvent("player_first_spawn", ePlayerFirstSpawn);
	HookEvent("player_spawn", ePlayerSpawn);

	HookEvent("mission_lost", eMissionLost);
	HookEvent("map_transition", eMapTransition);
	HookEvent("finale_win", eFinaleWin);

	HookEvent("weapon_fire", eWeaponFire);

	HookEvent("heal_begin", eHealBegin);
	HookEvent("heal_end", eHealEnd);
	HookEvent("heal_success", eHealSuccess);
 	HookEvent("revive_begin", eReviveBegin);
	HookEvent("revive_end", eReviveEnd);
	HookEvent("pills_used", ePillsUsed);

	if(L4D2Version)
	{
		HookEvent("molotov_thrown", eMolotovThrown);
		HookEvent("adrenaline_used", eAdrenalineUsed);
	}

	RegConsoleCmd("sm_s0", sm_s0);

	AutoExecConfig(true, "l4d_multiple_equipment");

	AddCommandListener(Listener_CallVote, "callvote");

	ResetClientStateAll();
}

void GameCheck()
{
	char GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));

	if (StrEqual(GameName, "survival", false))
		GameMode = 3;
	else if (StrEqual(GameName, "versus", false) || StrEqual(GameName, "teamversus", false) || StrEqual(GameName, "scavenge", false) || StrEqual(GameName, "teamscavenge", false))
		GameMode = 2;
	else if (StrEqual(GameName, "coop", false) || StrEqual(GameName, "realism", false))
		GameMode = 1;
	else
		GameMode = 0;

	GetGameFolderName(GameName, sizeof(GameName));

	if (StrEqual(GameName, "left4dead2", false))
		L4D2Version = true;
	else
		L4D2Version = false;

	GameMode += 0;
}

static void CheckAnimation(int client, int iSequence)
{
	static char sModel[31];
	GetEntPropString(client, Prop_Data, "m_ModelName", sModel, sizeof(sModel));

	switch(sModel[29])
	{
		case 'c'://coach
			if(iSequence == 37)
				SetEntProp(client, Prop_Send, "m_nSequence", 40, 2);
		case 'n'://zoey
			if(iSequence == 581)
				SetEntProp(client, Prop_Send, "m_nSequence", 646, 2);
	}
}

public void OnClientPostAdminCheck(int client)
{
	//ROUND START WEAPON VIEW FIX
	if(GetConVarInt(l4d_me_view) == 1) // && !IsFakeClient(client))
		CreateTimer(5.0, FixWeaponView, client, TIMER_FLAG_NO_MAPCHANGE);

	//SIMPLE PLAYER CONNECT MESSAGE
	if(GetConVarInt(l4d_me_player_connect) == 1 && !IsFakeClient(client))
		PrintToChatAll("%N Connected", client);
}

public void OnClientPutInServer(int client)
{
	if(!IsFakeClient(client))
		SDKHook(client, SDKHook_PreThink, OnPreThink); //AMMOLOCK
}

public void OnPreThink(int client)
{
	if(IsValidClient(client))
		AmmoLock(client);
}

void AmmoLock(int client)
{
	if(IsValidClient(client))
	{
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

		if (IsValidEntity(weapon))
		{
			char sClsName[32];
			GetEntityClassname(weapon, sClsName, sizeof(sClsName));

			if(sClsName[0] != 'w' || StrContains(sClsName, "weapon_", false) != 0)
				return;

			if (GetConVarInt(AmmoLockSlot0) == 1)
			{
				if (StrContains(sClsName, "smg") > -1 ||
					StrContains(sClsName, "shotgun") > -1 ||
					StrContains(sClsName, "rifle") > -1 ||
					StrContains(sClsName, "sniper") > -1 ||
					StrContains(sClsName, "grenade_launcher") > -1)
				{
					
					int Clip = GetEntProp(weapon, Prop_Data, "m_iClip1");
					int AmmoType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
					int Ammo = GetEntProp(client, Prop_Send, "m_iAmmo", _, AmmoType);

					if(Ammo == 1 && Clip == 0)
						SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 1.0);
					else if(Ammo < 1 && Clip < 1)
					{
						SetEntProp(client, Prop_Data, "m_iAmmo", 1, _, AmmoType);
						ChangeEdictState(client, FindDataMapInfo(client, "m_iAmmo"));
					}
				}
			}
			if (GetConVarInt(AmmoLockSlot1) == 1)
			{
				if (StrContains(sClsName, "pistol") > -1)
				{
					int Clip = GetEntProp(weapon, Prop_Data, "m_iClip1");
					int AmmoType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
					int Ammo = GetEntProp(client, Prop_Send, "m_iAmmo", _, AmmoType);

					if(Ammo == 1 && Clip == 0)
						SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 1.0);
					else if(Ammo < 1 && Clip < 1)
					{
						SetEntProp(client, Prop_Data, "m_iAmmo", 1, _, AmmoType);
						ChangeEdictState(client, FindDataMapInfo(client, "m_iAmmo"));
					}
				}
			}
		}
	}
}

public Action ePlayerFirstSpawn(Handle event, const char[] name, bool dont_broadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

 	if(GetConVarInt(l4d_me_afk_save) == 1)
		SaveEquipment(client);
}

public Action ePlayerSpawn(Handle event, const char[] name, bool dont_broadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	TeamDeath[client] = false;
	CreateTimer(0.5, FixWeaponView, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Listener_CallVote(int client, const char[] command, int argc)
{
	GetCmdArg(1, VoteFix[client], sizeof(VoteFix[]));

	if (StrEqual(VoteFix[client], "restartgame", false) || StrEqual(VoteFix[client], "changemission", false) || StrEqual(VoteFix[client], "returntolobby", false))
		ResetClientStateAll();
}

void Activate_ME(int client)
{
	if(!IsSurvivor(client))
		return;

	LoadEquipment(client);
	RemoveItemAttach(client, -1);
	AttachAllEquipment(client);
}

public Action FixWeaponView(Handle timer, any client)
{
	if(!IsSurvivor(client))
		return;

	RemoveItemAttach(client, -1);
	AttachAllEquipment(client);
}

public Action ME_Notify_Client(Handle timer, any client)
{
	if(!IsSurvivor(client) || IsFakeClient(client))
		return;

	char ME_Msg[99];
	GetConVarString(l4d_me_custom_notify_msg, ME_Msg, sizeof (ME_Msg));

	if (GetConVarInt(l4d_me_custom_notify) == 1)
		PrintToChat(client, "%s", ME_Msg);

	if (GetConVarInt(l4d_me_custom_notify) == 2)
		PrintHintText(client, "%s", ME_Msg);

	MsgOn[client] = false;
}

public void OnGameFrame()
{
	static int iFrameskip = 0;
	iFrameskip = (iFrameskip + 1) % MAX_FRAMECHECK;
	if(iFrameskip != 0 || !IsServerProcessing())
		return;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsSurvivor(i) || IsFakeClient(i))
			continue;

		if (!(GetEntityFlags(i) & FL_FROZEN) && IsValidEntity(i))
		{
			if (GetConVarInt(l4d_me_custom_notify) == 1 || GetConVarInt(l4d_me_custom_notify) == 2)
			{
				if (MsgOn[i] == false)
					continue;

				ME_Notify[i] = CreateTimer(0.1, ME_Notify_Client, i, TIMER_FLAG_NO_MAPCHANGE);
			}
		}

		if(iModelIndex[i] == GetEntProp(i, Prop_Data, "m_nModelIndex", 2))
			continue;

		CheckAnimation(i, GetEntProp(i, Prop_Send, "m_nSequence", 2));
		AttachAllEquipment(i);
		//PrintToChat(i, "AttachEquipment");
	}
}

public Action sm_s0(int client, int args)
{
	if (!IsSurvivor(client) || !IsPlayerAlive(client))
		return; // Plugin_Continue;

	float time = GetEngineTime();
	int buttons = GetClientButtons(client);

	if(time-PressStartTime[client] > 0.18)
		Process(client, time, buttons, true);

	PressStartTime[client] = time;

    //return Plugin_Continue;
}

public Action eWeaponFire(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsSurvivor(client) || !IsPlayerAlive(client))
		return; // Plugin_Continue;

	char item[10];
	GetEventString(event, "weapon", item, sizeof(item));

	if(item[0] != 'p' && item[0] != 'm' && item[0] != 'v')
		return; // Plugin_Continue;

	switch(item[0])
	{
		case 'p':
		{
			if(StrEqual(item, "pipe_bomb"))
				ThrowTime[client] = GetEngineTime();
		}
		case 'm':
		{
			if(StrEqual(item, "molotov"))
				ThrowTime[client] = GetEngineTime();
		}
		case 'v':
		{
			if(StrEqual(item, "vomitjar"))
				ThrowTime[client] = GetEngineTime();
		}
	}

	//return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (!client || !IsSurvivor(client) || !IsPlayerAlive(client))
		return;

	//new lastButton = LastButton[client];
	LastButton[client] = buttons;
	float time = GetEngineTime();

	if ((buttons & IN_ATTACK2) && !(LastButton[client] & IN_ATTACK2)) //lastButton
	{
		int w = Process(client, time, buttons, false);

		if (w > 0)
			LastWeapon[client] = w;
			//LastSwitchTime[client] = time;
	}
	else
	{
//SINGLE TAP MODE
		if(weapon > 0)
		{
			if (GetConVarInt(l4d_me_mode) == 1)
			{
				int newweapon = weapon;

				if (LastWeapon[client] == weapon)
				{
					int w = Process(client, time, buttons, true, weapon);

					if(w > 0)
						newweapon = w;
				}
				else
					Process(client, time, buttons, false);

				LastWeapon[client] = newweapon;
			}
//DOUBLE TAP MODE
			else if (GetConVarInt(l4d_me_mode) == 2)
			{
				int newweapon = weapon;

				if (LastWeapon[client] == weapon)
					Process(client, time, buttons, true, weapon);
				else
					Process(client, time, buttons, false);

				LastWeapon[client] = newweapon;
			}
		}
	}
}

public void OnClientDisconnect_Post(int client)
{
    LastButton[client] = 0;
}

public Action DelayRestore(Handle timer, any client)
{
	if(IsValidClient(client))
		Restore(client);

	return Plugin_Stop;
}

void Restore(int client)
{
	Process(client, GetEngineTime(), GetClientButtons(client), false);
}

int Process(int client, float time, int button, bool isSwitch, int currentWeapon = 0)
{
	int NewWeapon = 0;

	if (!client || !IsSurvivor(client) || !IsPlayerAlive(client))
		return NewWeapon;

	int m_tongueOwner = GetEntProp(client, Prop_Send, "m_tongueOwner");
	int m_pounceAttacker = GetEntProp(client, Prop_Send, "m_pounceAttacker");
	int m_isIncapacitated = GetEntProp(client, Prop_Send, "m_isIncapacitated", 1);
	int m_isHangingFromLedge = GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1);

	if (m_pounceAttacker > 0 || m_tongueOwner > 0 || m_isHangingFromLedge > 0 || m_isIncapacitated > 0)
		return NewWeapon;

	if(L4D2Version)
	{
		int m_pummelAttacker = GetEntProp(client, Prop_Send, "m_pummelAttacker", 1);
		int m_jockeyAttacker = GetEntProp(client, Prop_Send, "m_jockeyAttacker", 1);

		if(m_pummelAttacker > 0 || m_jockeyAttacker > 0)
			return NewWeapon;
	}

	int ActiveWeapon = currentWeapon;

	if (ActiveWeapon == 0)
		ActiveWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");

	if (ActiveWeapon < 0) //if (ActiveWeapon <= 0)
		ActiveWeapon = 0;

	int ActiveSlot = -1;

	for(int Slot = 0; Slot < 5; Slot++)
	{
		if (GetConVarInt(l4d_me_slot[Slot]) == 0 || (!L4D2Version && Slot == 1))
			continue;

		if (Slot == 2)
		{
			if(time - ThrowTime[client] < 2.0)
				continue;
		}

		int ent = GetPlayerWeaponSlot(client, Slot);

		if (ActiveWeapon == ent && ent > 0 && ActiveWeapon > 0)
			ActiveSlot = Slot;
		else if (ent <= 0)
			NewWeapon = SwapItem(client, Slot, 0);
	}

	if (ActiveSlot >= 0 && isSwitch)
		NewWeapon = SwapItem(client, ActiveSlot, ActiveWeapon);

	button = button+0;
	time += 0.0;

	if (!isSwitch && ActiveWeapon > 0)
	{
		SetEntPropEnt(client, Prop_Data, "m_hActiveWeapon", ActiveWeapon);
		NewWeapon = ActiveWeapon;
	}

	return NewWeapon;
}

int SwapItem(int client, int slot, int OldWeapon = 0)
{
	int Clip = 0;
	int Ammo = 0;
	int UpAmmo = 0;
	int UpgradeBit = 0;

	char OldWeaponName[LEN64] = "";

	if (OldWeapon > 0)
	{
		GetItemClass(OldWeapon, OldWeaponName);

		if (StrEqual(OldWeaponName, ""))
			return 0;

		bool isPistol = false;

		if (StrEqual(OldWeaponName, "weapon_pistol"))
			isPistol = true;

		GetItemInfo(client, slot, OldWeapon, Ammo, Clip, UpgradeBit, UpAmmo, isPistol);
		RemovePlayerItem(client, OldWeapon);
		AcceptEntityInput(OldWeapon, "kill");
	}
//THIS IS WEAPON CHANGE!!!
	int TheNewWeapon = 0;
	int NewWeapon = 0;

	if (!StrEqual(ItemName[client][slot], ""))
		NewWeapon = CreateWeaponEnt(ItemName[client][slot]);

	if (NewWeapon > 0)
	{
		EquipPlayerWeapon(client, NewWeapon);
		SetEntPropEnt(client, Prop_Data, "m_hActiveWeapon" , NewWeapon);
		SetItemInfo(client, slot, NewWeapon , ItemInfo[client][slot][0], ItemInfo[client][slot][1], ItemInfo[client][slot][2], ItemInfo[client][slot][3]);
		TheNewWeapon = NewWeapon;
	}

	ItemName[client][slot] = OldWeaponName;
	ItemInfo[client][slot][0] = Ammo;
	ItemInfo[client][slot][1] = Clip;
	ItemInfo[client][slot][2] = UpgradeBit;
	ItemInfo[client][slot][3] = UpAmmo;

	RemoveItemAttach(client, slot);
	ItemAttachEnt[client][slot] = 0;
	ItemAttachEnt[client][slot] = CreateItemAttach(client, OldWeaponName, slot);

	return TheNewWeapon;
}

void SetItemInfo (int client, int slot, int weapon, int ammo, int clip, int upgradeBit, int upammo)
{
	if (slot == 0)
	{
		if (L4D2Version)
			SetClientWeaponInfo_l4d2(client, weapon, ammo, clip, upgradeBit, upammo);
		else
			SetClientWeaponInfo_l4d1(client, weapon, ammo, clip);
	}
	else
	{
		SetEntProp(weapon, Prop_Send, "m_iClip1", clip);

 		if (slot == 1 && ammo > 0)
			SetEntProp(weapon, Prop_Send, "m_hasDualWeapons" ,ammo);
	}
}

void GetItemInfo(int client, int slot, int weapon, int &ammo, int &clip, int &upgradeBit, int &upammo, bool isPistol)
{
	if (slot == 0)
	{
		if (L4D2Version)
			GetClientWeaponInfo_l4d2(client, weapon, ammo, clip, upgradeBit, upammo);
		else
			GetClientWeaponInfo_l4d1(client,weapon, ammo, clip);
	}
	else
	{
		ammo = 0;
		upgradeBit = 0;
		upammo = 0;
		clip = GetEntProp(weapon, Prop_Send, "m_iClip1" );

		if (isPistol)
			ammo = GetEntProp(weapon, Prop_Send, "m_hasDualWeapons" );
	}
}

void RemoveItemAttach(int client, int slot)
{
	int startSlot = slot;
	int endSlot = slot;

	if (slot < 0 || slot > 4)
		startSlot=0, endSlot=4;

	for (int i = startSlot; i <= endSlot; i++)
	{
		int entity = ItemAttachEnt[client][i];
		ItemAttachEnt[client][i] = 0;

		if(entity > 0 && IsValidEntS(entity, "prop_dynamic"))
		{
			AcceptEntityInput(entity, "ClearParent");
			AcceptEntityInput(entity, "Kill");
		}
	}
}

void SetVector(float target[3], float x, float y, float z)
{
	target[0] = x, target[1] = y, target[2] = z;
}

int CreateItemAttach(int client, char[] classname, int slot)
{
	if(GetConVarInt(l4d_me_view) != 1 || !IsSurvivor(client) || !IsPlayerAlive(client))
		return;

	char model[LEN64];

	if (L4D2Version)
		GetModelFromClass_l4d2(classname, model, slot);
	else
		GetModelFromClass_l4d1(classname, model, slot);

	if (StrEqual(classname, "") || StrEqual(model, ""))
		return;

	int entity = MEIndex[client];

	if(IsValidEntRef(entity))
		AcceptEntityInput(entity, "kill");

	entity = CreateEntityByName("prop_dynamic_override");

	if(entity < 0)
		return;

	SetEntityModel(entity, model);
	//DispatchKeyValue(entity, "model", model);

	DispatchSpawn(entity);
	ActivateEntity(entity);

	//SetEntProp(entity, Prop_Data, "m_CollisionGroup", 2);
	//SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);

	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", client);

	char ModelName[PLATFORM_MAX_PATH];
	GetEntPropString(client, Prop_Data, "m_ModelName", ModelName, sizeof(ModelName));

	switch(slot)
	{
		case 0: //Slot0
		{
			SetVariantString("medkit");
			AcceptEntityInput(entity, "SetParentAttachment", entity);

			if(StrContains(ModelName, "survivor_teenangst", false) != -1 || StrContains(ModelName, "survivor_producer", false) != -1) //Zoey Rochelle
			{
				if (L4D2Version)
					SetVector(Pos, 2.0, 0.0, -4.5), SetVector(Ang, -22.0, 100.0, 180.0);
				else
					SetVector(Pos, 2.0, -4.0, 5.0), SetVector(Ang, -15.0, 90.0, 180.0);
			}
			else
			{
				if (L4D2Version)
					SetVector(Pos, 2.0, 0.0, -4.5), SetVector(Ang, -22.0, 100.0, 180.0);
				else
					SetVector(Pos, 2.0, -4.0, 5.0), SetVector(Ang, -15.0, 90.0, 180.0);
			}
		}
		case 1: //Slot1
		{
			SetVariantString("molotov");
			AcceptEntityInput(entity, "SetParentAttachment", entity);

			if (L4D2Version)
				SetVector(Pos, 0.0,  0.0, 0.0), SetVector(Ang, 120.0, 90.0, 0.0);
			else
				SetVector(Pos, 2.0, -4.0, 5.0), SetVector(Ang, -15.0, 90.0, 180.0);
		}
		case 2: //Slot2
		{
			SetVariantString("molotov");
			AcceptEntityInput(entity, "SetParentAttachment", entity);

			if (L4D2Version)
				SetVector(Pos, 0.0, 4.0, 0.0), SetVector(Ang, 0.0, 90.0, 0.0);
			else
				SetVector(Pos, 0.0, 4.0, 0.0), SetVector(Ang, 0.0, 90.0, 0.0);
		}
		case 3: //Slot3
		{
			SetVariantString("medkit");
			AcceptEntityInput(entity, "SetParentAttachment", entity);

			if (L4D2Version)
			{
				if (StrEqual(classname, "weapon_defibrillator"))
					SetVector(Pos, -0.0, 10.0, 0.0), SetVector(Ang, -90.0, 0.0, 0.0);
				else
					SetVector(Pos, -0.0, 10.0, 0.0), SetVector(Ang, 0.0, 0.0, 0.0);
			}
			else
				SetVector(Pos, -0.0, 10.0, 0.0), SetVector(Ang, 0.0, 0.0, 0.0);
		}
		case 4: //Slot4
		{
			SetVariantString("pills");
			AcceptEntityInput(entity, "SetParentAttachment", entity);

			if(StrContains(ModelName, "survivor_teenangst", false) != -1 || StrContains(ModelName, "survivor_producer", false) != -1) //Zoey Rochelle
			{
				if (L4D2Version)
				{
					if (StrEqual(classname, "weapon_adrenaline"))
						SetVector(Pos, 5.0, 3.0, 0.0), SetVector(Ang, 0.0, 90.0, 90.0);
					else
						SetVector(Pos, 5.0, 3.0, 0.0), SetVector(Ang, 0.0, 90.0, 0.0);
				}
				else
					SetVector(Pos, 5.0, 3.0, 0.0), SetVector(Ang, 0.0, 90.0, 0.0);
			}
			else
			{
				if (L4D2Version)
				{
					if (StrEqual(classname, "weapon_adrenaline"))
						SetVector(Pos, 5.0, 3.0, 0.0), SetVector(Ang, 0.0, 90.0, 90.0);
					else
						SetVector(Pos, 5.0, 3.0, 0.0), SetVector(Ang, 0.0, 90.0, 0.0);
				}
				else
					SetVector(Pos, 5.0, 3.0, 0.0), SetVector(Ang, 0.0, 90.0, 0.0);
			}
		}
	}

	AcceptEntityInput(entity, "TurnOn");
	AcceptEntityInput(entity, "DisableShadows");

	TeleportEntity(entity, Pos, Ang, NULL_VECTOR);

	MEIndex[client] = EntIndexToEntRef(entity);
	MEOwner[entity] = GetClientUserId(client);

	SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmit_View);
}

public Action Hook_SetTransmit_View(int entity, int client)
{
	if(IsFakeClient(client))
		return Plugin_Continue;

	if(!IsPlayerAlive(client))
		if(GetEntProp(client, Prop_Send, "m_iObserverMode") == 4)
			if(GetEntPropEnt(client, Prop_Send, "m_hObserverTarget") == GetClientOfUserId(MEOwner[entity]))
				return Plugin_Handled;

	int iEntOwner = GetClientOfUserId(MEOwner[entity]);

	if(iEntOwner < 1 || !IsClientInGame(iEntOwner))
		return Plugin_Continue;

	if(GetClientTeam(iEntOwner) == 2)
	{
		if(iEntOwner != client)
			return Plugin_Continue;

		if(!IsSurvivorThirdPerson(client))
			return Plugin_Handled;

		float Time = GetEngineTime();

		if (!L4D2Version)
		{
			if(Time-InHeal[client] < 5.0 || Time-InRevive[client] < 5.0)
				return Plugin_Continue;
		}
	}

	return Plugin_Continue;
}

void AttachAllEquipment(int client)
{
	if (!IsSurvivor(client) || IsFakeClient(client))
		return;

	for(int slot = 0; slot <= 4; slot++)
		ItemAttachEnt[client][slot] = CreateItemAttach(client, ItemName[client][slot], slot);
}

void DropSecondaryItem(int client)
{
	float origin[3];
	GetClientEyePosition(client, origin);

	for(int slot = 0; slot <= 4; slot++)
	{
		if(!StrEqual(ItemName[client][slot], ""))
		{
			int ammo = ItemInfo[client][slot][0];
			int clip = ItemInfo[client][slot][1];
			int info1 = ItemInfo[client][slot][2];
			int info2 = ItemInfo[client][slot][3];

			if(slot==0)
			{
				if(L4D2Version)
					DropPrimaryWeapon_l4d2(client,ItemName[client][slot], ammo, clip, info1, info2);
				else
					DropPrimaryWeapon_l4d1(client, ItemName[client][slot], ammo, clip);
			}
			else
			{
				int ent = CreateWeaponEnt(ItemName[client][slot]);
				TeleportEntity(ent, origin, NULL_VECTOR, NULL_VECTOR);
				ActivateEntity(ent);
			}
		}
	}
}

void SaveEquipment(int i) //FOR AFK
{
	for(int slot = 0; slot <= 4; slot++)
	{
		if(IsSurvivor(i))
		{
			BackupItemName[i][slot] = ItemName[i][slot];
			BackupItemInfo[i][slot][0] = ItemInfo[i][slot][0];
			BackupItemInfo[i][slot][1] = ItemInfo[i][slot][1];
			BackupItemInfo[i][slot][2] = ItemInfo[i][slot][2];
			BackupItemInfo[i][slot][3] = ItemInfo[i][slot][3];
		}
	}
}

void SaveEquipmentAll() //FOR MAP TRANSITION
{
	for(int i = 1; i <= MaxClients; i++)
	{
		for(int slot = 0; slot <= 4; slot++)
		{
			if(IsSurvivor(i))
			{
				BackupItemName[i][slot] = ItemName[i][slot];
				BackupItemInfo[i][slot][0] = ItemInfo[i][slot][0];
				BackupItemInfo[i][slot][1] = ItemInfo[i][slot][1];
				BackupItemInfo[i][slot][2] = ItemInfo[i][slot][2];
				BackupItemInfo[i][slot][3] = ItemInfo[i][slot][3];
			}
		}
	}
}

void LoadEquipment(int i) //FOR ROUND START
{
	for(int slot = 0; slot <= 4; slot++)
	{
		if(IsSurvivor(i))
		{
			ItemName[i][slot] = BackupItemName[i][slot];
			ItemInfo[i][slot][0] = BackupItemInfo[i][slot][0];
			ItemInfo[i][slot][1] = BackupItemInfo[i][slot][1];
			ItemInfo[i][slot][2] = BackupItemInfo[i][slot][2];
			ItemInfo[i][slot][3] = BackupItemInfo[i][slot][3];
		}
	}
}

void LoadEquipmentAll() //FOR MISSION LOST
{
	for(int i = 1; i <= MaxClients; i++)
	{
		for(int slot = 0; slot <= 4; slot++)
		{
			if(IsSurvivor(i))
			{
				ItemName[i][slot] = BackupItemName[i][slot];
				ItemInfo[i][slot][0] = BackupItemInfo[i][slot][0];
				ItemInfo[i][slot][1] = BackupItemInfo[i][slot][1];
				ItemInfo[i][slot][2] = BackupItemInfo[i][slot][2];
				ItemInfo[i][slot][3] = BackupItemInfo[i][slot][3];
			}
		}
	}
}

#define model_weapon_rifle "models/w_models/weapons/w_rifle_m16a2.mdl"
#define model_weapon_rifle_sg552 "models/w_models/weapons/w_rifle_sg552.mdl"
#define model_weapon_rifle_desert "models/w_models/weapons/w_desert_rifle.mdl"
#define model_weapon_rifle_ak47 "models/w_models/weapons/w_rifle_ak47.mdl"
#define model_weapon_smg "models/w_models/weapons/w_smg_uzi.mdl"
#define model_weapon_smg_silenced "models/w_models/weapons/w_smg_a.mdl"
#define model_weapon_smg_mp5 "models/w_models/weapons/w_smg_mp5.mdl"
#define model_weapon_pumpshotgun "models/w_models/weapons/w_shotgun.mdl"
#define model_weapon_shotgun_chrome "models/w_models/weapons/w_pumpshotgun_A.mdl"
#define model_weapon_autoshotgun "models/w_models/weapons/w_autoshot_m4super.mdl"
#define model_weapon_shotgun_spas "models/w_models/weapons/w_shotgun_spas.mdl"
#define model_weapon_hunting_rifle "models/w_models/weapons/w_sniper_mini14.mdl"
#define model_weapon_sniper_scout "models/w_models/weapons/w_sniper_scout.mdl"
#define model_weapon_sniper_military "models/w_models/weapons/w_sniper_military.mdl"
#define model_weapon_sniper_awp "models/w_models/weapons/w_sniper_awp.mdl"
#define model_weapon_rifle_m60 "models/w_models/weapons/w_m60.mdl"
#define model_weapon_grenade_launcher "models/w_models/weapons/w_grenade_launcher.mdl"
#define model_weapon_pistol "models/w_models/weapons/w_pistol_A.mdl"
#define model_weapon_pistol_magnum "models/w_models/weapons/w_desert_eagle.mdl"
#define model_weapon_chainsaw "models/weapons/melee/w_chainsaw.mdl"
#define model_weapon_melee_fireaxe "models/weapons/melee/w_fireaxe.mdl"
#define model_weapon_melee_baseball_bat "models/weapons/melee/w_bat.mdl"
#define model_weapon_melee_crowbar "models/weapons/melee/w_crowbar.mdl"
#define model_weapon_melee_electric_guitar "models/weapons/melee/w_electric_guitar.mdl"
#define model_weapon_melee_cricket_bat "models/weapons/melee/w_cricket_bat.mdl"
#define model_weapon_melee_frying_pan  "models/weapons/melee/w_frying_pan.mdl"
#define model_weapon_melee_golfclub  "models/weapons/melee/w_golfclub.mdl"
#define model_weapon_melee_machete  "models/weapons/melee/w_machete.mdl"
#define model_weapon_melee_katana  "models/weapons/melee/w_katana.mdl"
#define model_weapon_melee_tonfa  "models/weapons/melee/w_tonfa.mdl"
#define model_weapon_melee_riotshield  "models/weapons/melee/w_riotshield.mdl"
#define model_weapon_molotov "models/w_models/weapons/w_eq_molotov.mdl"
#define model_weapon_pipe_bomb "models/w_models/weapons/w_eq_pipebomb.mdl"
#define model_weapon_vomitjar "models/w_models/weapons/w_eq_bile_flask.mdl"
#define model_weapon_first_aid_kit "models/w_models/weapons/w_eq_Medkit.mdl"
#define model_weapon_defibrillator "models/w_models/weapons/w_eq_defibrillator.mdl"
#define model_weapon_upgradepack_explosive "models/w_models/weapons/w_eq_explosive_ammopack.mdl"
#define model_weapon_upgradepack_incendiary "models/w_models/weapons/w_eq_incendiary_ammopack.mdl"
#define model_weapon_pain_pills "models/w_models/weapons/w_eq_painpills.mdl"
#define model_weapon_adrenaline "models/w_models/weapons/w_eq_adrenaline.mdl"


int GetModelFromClass_l4d2(char[] weapon, char model[LEN64], int slot = 0)
{
	switch(slot)
	{
		case 0:
		//if(slot==0)
		{
			if(StrEqual(weapon, "weapon_rifle"))strcopy(model, LEN64, model_weapon_rifle);
			else if(StrEqual(weapon, "weapon_rifle_sg552"))strcopy(model, LEN64, model_weapon_rifle_sg552);
			else if(StrEqual(weapon, "weapon_rifle_desert"))strcopy(model, LEN64, model_weapon_rifle_desert);
			else if(StrEqual(weapon, "weapon_rifle_ak47"))strcopy(model, LEN64, model_weapon_rifle_ak47);
			else if(StrEqual(weapon, "weapon_rifle_m60"))strcopy(model, LEN64, model_weapon_rifle_m60);
			else if(StrEqual(weapon, "weapon_smg"))strcopy(model, LEN64, model_weapon_smg);
			else if(StrEqual(weapon, "weapon_smg_silenced"))strcopy(model, LEN64, model_weapon_smg_silenced);
			else if(StrEqual(weapon, "weapon_smg_mp5"))strcopy(model, LEN64, model_weapon_smg_mp5);
			else if(StrEqual(weapon, "weapon_pumpshotgun"))strcopy(model, LEN64, model_weapon_pumpshotgun);
			else if(StrEqual(weapon, "weapon_shotgun_chrome"))strcopy(model, LEN64, model_weapon_shotgun_chrome);
			else if(StrEqual(weapon, "weapon_autoshotgun"))strcopy(model, LEN64, model_weapon_autoshotgun);
			else if(StrEqual(weapon, "weapon_shotgun_spas"))strcopy(model, LEN64, model_weapon_shotgun_spas);
			else if(StrEqual(weapon, "weapon_hunting_rifle"))strcopy(model, LEN64, model_weapon_hunting_rifle);
			else if(StrEqual(weapon, "weapon_sniper_scout"))strcopy(model, LEN64, model_weapon_sniper_scout);
			else if(StrEqual(weapon, "weapon_sniper_military"))strcopy(model, LEN64, model_weapon_sniper_military);
			else if(StrEqual(weapon, "weapon_sniper_awp"))strcopy(model, LEN64, model_weapon_sniper_awp);
			else if(StrEqual(weapon, "weapon_grenade_launcher"))strcopy(model, LEN64, model_weapon_grenade_launcher);
			else model="";
		}
		case 1:
		//else if(slot==1)
		{
			if(StrEqual(weapon, "weapon_pistol"))strcopy(model, LEN64, model_weapon_pistol);
			else if(StrEqual(weapon, "weapon_pistol_magnum"))strcopy(model, LEN64, model_weapon_pistol_magnum);
			else if(StrEqual(weapon, "weapon_chainsaw"))strcopy(model, LEN64, model_weapon_chainsaw);
			else if(StrEqual(weapon, "weapon_melee_fireaxe"))strcopy(model, LEN64, model_weapon_melee_fireaxe);
			else if(StrEqual(weapon, "weapon_melee_baseball_bat"))strcopy(model, LEN64, model_weapon_melee_baseball_bat);
			else if(StrEqual(weapon, "weapon_melee_crowbar"))strcopy(model, LEN64, model_weapon_melee_crowbar);
			else if(StrEqual(weapon, "weapon_melee_electric_guitar"))strcopy(model, LEN64, model_weapon_melee_electric_guitar);
			else if(StrEqual(weapon, "weapon_melee_cricket_bat"))strcopy(model, LEN64, model_weapon_melee_cricket_bat);
			else if(StrEqual(weapon, "weapon_melee_frying_pan"))strcopy(model, LEN64, model_weapon_melee_frying_pan);
			else if(StrEqual(weapon, "weapon_melee_golfclub"))strcopy(model, LEN64, model_weapon_melee_golfclub);
			else if(StrEqual(weapon, "weapon_melee_machete"))strcopy(model, LEN64, model_weapon_melee_machete);
			else if(StrEqual(weapon, "weapon_melee_katana"))strcopy(model, LEN64, model_weapon_melee_katana);
			else if(StrEqual(weapon, "weapon_melee_tonfa"))strcopy(model, LEN64, model_weapon_melee_tonfa);
			else if(StrEqual(weapon, "weapon_melee_riotshield"))strcopy(model, LEN64, model_weapon_melee_riotshield);
			else model="";
		}
		case 2:
		//else if(slot==2)
		{
			if(StrEqual(weapon, "weapon_molotov"))strcopy(model, LEN64, model_weapon_molotov);
			else if(StrEqual(weapon, "weapon_pipe_bomb"))strcopy(model, LEN64, model_weapon_pipe_bomb);
			else if(StrEqual(weapon, "weapon_vomitjar"))strcopy(model, LEN64, model_weapon_vomitjar);
			else model="";
		}
		case 3:
		//else if(slot==3)
		{
			if(StrEqual(weapon, "weapon_first_aid_kit"))strcopy(model, LEN64, model_weapon_first_aid_kit);
			else if(StrEqual(weapon, "weapon_defibrillator"))strcopy(model, LEN64, model_weapon_defibrillator);
			else if(StrEqual(weapon, "weapon_upgradepack_explosive"))strcopy(model, LEN64, model_weapon_upgradepack_explosive);
			else if(StrEqual(weapon, "weapon_upgradepack_incendiary"))strcopy(model, LEN64, model_weapon_upgradepack_incendiary);
			else model="";
		}
		case 4:
		//else if(slot==4)
		{
			if(StrEqual(weapon, "weapon_pain_pills"))strcopy(model, LEN64, model_weapon_pain_pills);
			else if(StrEqual(weapon, "weapon_adrenaline"))strcopy(model, LEN64, model_weapon_adrenaline);
			else model="";
		}
	}
}

#define model1_weapon_rifle "models/w_models/weapons/w_rifle_m16a2.mdl"
#define model1_weapon_autoshotgun "models/w_models/weapons/w_autoshot_m4super.mdl"
#define model1_weapon_pumpshotgun "models/w_models/Weapons/w_shotgun.mdl"
#define model1_weapon_hunting_rifle "models/w_models/weapons/w_sniper_mini14.mdl"
#define model1_weapon_smg "models/w_models/Weapons/w_smg_uzi.mdl"
#define model1_weapon_pistol "models/w_models/Weapons/w_pistol_1911.mdl"
#define model1_weapon_molotov "models/w_models/weapons/w_eq_molotov.mdl"
#define model1_weapon_pipe_bomb "models/w_models/weapons/w_eq_pipebomb.mdl"
#define model1_weapon_first_aid_kit "models/w_models/weapons/w_eq_Medkit.mdl"
#define model1_weapon_pain_pills "models/w_models/weapons/w_eq_painpills.mdl"

int GetModelFromClass_l4d1(char[] weapon, char model[LEN64], int slot = 0)
{
	switch(slot)
	{
		case 0:
		//if(slot==0)
		{
			if(StrEqual(weapon, "weapon_rifle"))strcopy(model, LEN64, model1_weapon_rifle);
			else if(StrEqual(weapon, "weapon_autoshotgun"))strcopy(model, LEN64, model1_weapon_autoshotgun);
			else if(StrEqual(weapon, "weapon_pumpshotgun"))strcopy(model, LEN64, model1_weapon_pumpshotgun);
			else if(StrEqual(weapon, "weapon_hunting_rifle"))strcopy(model, LEN64, model1_weapon_hunting_rifle);
			else if(StrEqual(weapon, "weapon_smg"))strcopy(model, LEN64, model1_weapon_smg);
			else model="";
		}
		case 1:
		//else if(slot==1)
		{
			if(StrEqual(weapon, "weapon_pistol"))strcopy(model, LEN64, model1_weapon_pistol);
			else model="";
		}
		case 2:
		//else if(slot==2)
		{
			if(StrEqual(weapon, "weapon_molotov"))strcopy(model, LEN64, model1_weapon_molotov);
			else if(StrEqual(weapon, "weapon_pipe_bomb"))strcopy(model, LEN64, model1_weapon_pipe_bomb);
			else model="";
		}
		case 3:
		//else if(slot==3)
		{
			if(StrEqual(weapon, "weapon_first_aid_kit"))strcopy(model, LEN64, model1_weapon_first_aid_kit);
			else model="";
		}
		case 4:
		//else if(slot==4)
		{
			if(StrEqual(weapon, "weapon_pain_pills"))strcopy(model, LEN64, model1_weapon_pain_pills);
			else model="";
		}
	}
}

int GetItemClass(int ent, char classname[LEN64])
{
	classname = "";

	if(ent > 0)
	{
		GetEntityClassname(ent, classname, sizeof(classname));
		//GetEdictClassname(ent, classname, LEN64);
		if(StrEqual(classname, "weapon_melee"))
		{
			char model[128];
			GetEntPropString(ent, Prop_Data, "m_ModelName", model, sizeof(model));

			if(StrContains(model, "fireaxe")>=0)classname="weapon_melee_fireaxe";
			else if(StrContains(model, "v_bat")>=0)	classname="weapon_melee_baseball_bat";
			else if(StrContains(model, "crowbar")>=0)classname="weapon_melee_crowbar";
			else if(StrContains(model, "electric_guitar")>=0)classname="weapon_melee_electric_guitar";
			else if(StrContains(model, "cricket_bat")>=0)classname="weapon_melee_cricket_bat";
			else if(StrContains(model, "frying_pan")>=0)classname="weapon_melee_frying_pan";
			else if(StrContains(model, "golfclub")>=0)classname="weapon_melee_golfclub";
			else if(StrContains(model, "machete")>=0)classname="weapon_melee_machete";
			else if(StrContains(model, "katana")>=0)classname="weapon_melee_katana";
			else if(StrContains(model, "tonfa")>=0)classname="weapon_melee_tonfa";
			else if(StrContains(model, "riotshield")>=0)classname="weapon_melee_riotshield";
			else classname="";
		}
	}
}

int CreateWeaponEnt(char[] classname)
{
	if(StrEqual(classname, ""))
		return 0;

	if(StrContains(classname, "weapon_melee_")<0)
	{
		int ent = CreateEntityByName(classname);
		DispatchSpawn(ent);
		return ent;
	}
	else
	{
		int ent = CreateEntityByName("weapon_melee");

		if(StrEqual(classname, "weapon_melee_fireaxe"))DispatchKeyValue( ent, "melee_script_name", "fireaxe");
		else if(StrEqual(classname, "weapon_melee_baseball_bat"))DispatchKeyValue( ent, "melee_script_name", "baseball_bat");
		else if(StrEqual(classname, "weapon_melee_crowbar"))DispatchKeyValue( ent, "melee_script_name", "crowbar");
		else if(StrEqual(classname, "weapon_melee_electric_guitar"))DispatchKeyValue( ent, "melee_script_name", "electric_guitar");
		else if(StrEqual(classname, "weapon_melee_cricket_bat"))DispatchKeyValue( ent, "melee_script_name", "cricket_bat");
		else if(StrEqual(classname, "weapon_melee_frying_pan"))DispatchKeyValue( ent, "melee_script_name", "frying_pan");
		else if(StrEqual(classname, "weapon_melee_golfclub"))DispatchKeyValue( ent, "melee_script_name", "golfclub");
		else if(StrEqual(classname, "weapon_melee_machete"))DispatchKeyValue( ent, "melee_script_name", "machete");
		else if(StrEqual(classname, "weapon_melee_katana"))DispatchKeyValue( ent, "melee_script_name", "katana");
		else if(StrEqual(classname, "weapon_melee_tonfa"))DispatchKeyValue( ent, "melee_script_name", "tonfa");
		else if(StrEqual(classname, "weapon_melee_riotshield"))DispatchKeyValue( ent, "melee_script_name", "riotshield");

		DispatchSpawn(ent);
		return ent;
	}
}

public void OnMapStart()
{
	if(L4D2Version)
	{
		PrecacheModel(model_weapon_rifle);
		PrecacheModel(model_weapon_rifle_sg552);
		PrecacheModel(model_weapon_rifle_desert);
		PrecacheModel(model_weapon_rifle_ak47);
		PrecacheModel(model_weapon_rifle_m60);
		PrecacheModel(model_weapon_smg);
		PrecacheModel(model_weapon_smg_silenced);
		PrecacheModel(model_weapon_smg_mp5);
		PrecacheModel(model_weapon_pumpshotgun);
		PrecacheModel(model_weapon_shotgun_chrome);
		PrecacheModel(model_weapon_autoshotgun);
		PrecacheModel(model_weapon_shotgun_spas);
		PrecacheModel(model_weapon_hunting_rifle);
		PrecacheModel(model_weapon_sniper_scout);
		PrecacheModel(model_weapon_sniper_military);
		PrecacheModel(model_weapon_sniper_awp);
		PrecacheModel(model_weapon_grenade_launcher);
		
		PrecacheModel(model_weapon_pistol);
		PrecacheModel(model_weapon_pistol_magnum);
		PrecacheModel(model_weapon_chainsaw);
		
		PrecacheModel(model_weapon_melee_fireaxe);
		PrecacheModel(model_weapon_melee_baseball_bat);
		PrecacheModel(model_weapon_melee_crowbar);
		PrecacheModel(model_weapon_melee_electric_guitar);
		PrecacheModel(model_weapon_melee_cricket_bat);
		PrecacheModel(model_weapon_melee_frying_pan);
		PrecacheModel(model_weapon_melee_golfclub);
		PrecacheModel(model_weapon_melee_machete);
		PrecacheModel(model_weapon_melee_katana);
		PrecacheModel(model_weapon_melee_tonfa);
		PrecacheModel(model_weapon_melee_riotshield);
		
		PrecacheModel(model_weapon_molotov);
		PrecacheModel(model_weapon_pipe_bomb);
		PrecacheModel(model_weapon_vomitjar);
		
		PrecacheModel(model_weapon_first_aid_kit);
		PrecacheModel(model_weapon_defibrillator);
		PrecacheModel(model_weapon_upgradepack_explosive);
		PrecacheModel(model_weapon_upgradepack_incendiary);
		PrecacheModel(model_weapon_pain_pills);
		PrecacheModel(model_weapon_adrenaline);

		PrecacheGeneric( "scripts/melee/baseball_bat.txt", true);
		PrecacheGeneric( "scripts/melee/cricket_bat.txt", true);
		PrecacheGeneric( "scripts/melee/crowbar.txt", true);
		PrecacheGeneric( "scripts/melee/electric_guitar.txt", true);
		PrecacheGeneric( "scripts/melee/fireaxe.txt", true);
		PrecacheGeneric( "scripts/melee/frying_pan.txt", true);
		PrecacheGeneric( "scripts/melee/golfclub.txt", true);
		PrecacheGeneric( "scripts/melee/katana.txt", true);
		PrecacheGeneric( "scripts/melee/machete.txt", true);
		PrecacheGeneric( "scripts/melee/tonfa.txt", true);
		PrecacheGeneric( "scripts/melee/riotshield.txt", true);
	}
	else
	{
		PrecacheModel(model1_weapon_rifle);
		PrecacheModel(model1_weapon_autoshotgun);
		PrecacheModel(model1_weapon_pumpshotgun);
		PrecacheModel(model1_weapon_hunting_rifle);
		PrecacheModel(model1_weapon_smg);
		PrecacheModel(model1_weapon_pistol);
		PrecacheModel(model1_weapon_molotov);
		PrecacheModel(model1_weapon_pipe_bomb);
		PrecacheModel(model1_weapon_first_aid_kit);
		PrecacheModel(model1_weapon_pain_pills);
	}

	for (int client = 1; client <= MaxClients; client++)
		MsgOn[client] = true;
}

public Action ePlayerTeam(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int team = GetEventInt(event, "team");

	switch(team)
	{
		case 1:
		{
			RemoveItemAttach(client, -1);

			if(GetConVarInt(l4d_me_afk_save) == 1)
				SaveEquipment(client);
		}
		case 2:
		{
			Activate_ME(client);
			//RemoveItemAttach(client, -1);
			//LoadEquipment(client);
			//AttachAllEquipment(client);
		}
		case 3:
		{
			if(GetConVarInt(l4d_me_afk_save) == 1)
				SaveEquipment(client);

			RemoveItemAttach(client, -1);
		}
	}

	if(GetEventBool(event, "disconnected"))
		ResetClientState(client);

	if(!IsValidClient(client))
		return;

	int iEntity = MEIndex[client];

	if(!IsValidEntRef(iEntity))
		return;

	AcceptEntityInput(iEntity, "kill");
	MEIndex[client] = -1;
}

public Action ePlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(!IsValidClient(client))
		return;

	int iEntity = MEIndex[client];

	if(!IsValidEntRef(iEntity))
		return;

	AcceptEntityInput(iEntity, "kill");
	MEIndex[client] = -1;

	RemoveItemAttach(client,-1);
	DropSecondaryItem(client);
	ResetClientState(client);
	TeamDeath[client] = true;
	//}
}

public Action eMissionLost(Handle event, const char[] name, bool dontBroadcast)
{
	LoadEquipmentAll();
}

public Action eMapTransition(Handle event, const char[] name, bool dontBroadcast)
{
	SaveEquipmentAll();
}

public Action eFinaleWin(Handle event, const char[] name, bool dontBroadcast)
{	
	ResetClientStateAll();
}

public Action ePlayerDisconnect(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	ResetClientState(client);
}

void SetClientWeaponInfo_l4d1(int client, int ent, int ammo, int clip)
{
	if (ent > 0)
	{
		char sWeapon[32];
		GetEntityClassname(ent, sWeapon, sizeof(sWeapon));
		//GetEdictClassname(ent, weapon, 32);

		int ammoOffset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
		
		SetEntProp(ent, Prop_Send, "m_iClip1", clip);
		if (StrEqual(sWeapon, "weapon_pumpshotgun") || StrEqual(sWeapon, "weapon_autoshotgun"))
			SetEntData(client, ammoOffset+(6*4), ammo);
		else if (StrEqual(sWeapon, "weapon_smg"))
			SetEntData(client, ammoOffset+(5*4), ammo);
		else if (StrEqual(sWeapon, "weapon_rifle"))
			SetEntData(client, ammoOffset+(3*4), ammo);
		else if (StrEqual(sWeapon, "weapon_hunting_rifle"))
			SetEntData(client, ammoOffset+(2*4), ammo);
		else if (StrEqual(sWeapon, "weapon_pistol"))
			SetEntProp(ent, Prop_Send, "m_hasDualWeapons", ammo );
	}
}

void SetClientWeaponInfo_l4d2(int client, int ent , int ammo, int clip, int upgradeBit, int upammo)
{
	if (ent > 0 && GetClientTeam(client) == 2)
	{
		char sWeapon[32];
		GetEntityClassname(ent, sWeapon, sizeof(sWeapon));

		int ammoOffset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");

		SetEntProp(ent, Prop_Send, "m_iClip1", clip);
		SetEntProp(ent, Prop_Send, "m_upgradeBitVec", upgradeBit);
		SetEntProp(ent, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", upammo);

		if (StrEqual(sWeapon, "weapon_rifle") || StrEqual(sWeapon, "weapon_rifle_sg552") || StrEqual(sWeapon, "weapon_rifle_desert") || StrEqual(sWeapon, "weapon_rifle_ak47") || StrEqual(sWeapon, "weapon_rifle_m60"))
			SetEntData(client, ammoOffset+(12), ammo);
		else if (StrEqual(sWeapon, "weapon_smg") || StrEqual(sWeapon, "weapon_smg_silenced") || StrEqual(sWeapon, "weapon_smg_mp5"))
			SetEntData(client, ammoOffset+(20), ammo);
		else if (StrEqual(sWeapon, "weapon_pumpshotgun") || StrEqual(sWeapon, "weapon_shotgun_chrome"))
			SetEntData(client, ammoOffset+(28), ammo);
		else if (StrEqual(sWeapon, "weapon_autoshotgun") || StrEqual(sWeapon, "weapon_shotgun_spas"))
			SetEntData(client, ammoOffset+(32), ammo);
		else if (StrEqual(sWeapon, "weapon_hunting_rifle"))
			SetEntData(client, ammoOffset+(36), ammo);
		else if (StrEqual(sWeapon, "weapon_sniper_scout") || StrEqual(sWeapon, "weapon_sniper_military") || StrEqual(sWeapon, "weapon_sniper_awp"))
			SetEntData(client, ammoOffset+(40), ammo);
		else if (StrEqual(sWeapon, "weapon_grenade_launcher"))
			SetEntData(client, ammoOffset+(68), ammo);
		else if (StrEqual(sWeapon, "weapon_pistol"))
			SetEntProp(ent, Prop_Send, "m_hasDualWeapons", ammo );
	}
}

void GetClientWeaponInfo_l4d1(int client , int ent, int &ammo, int &clip)
{
	if (ent > 0)
	{
		char sWeapon[32];
		GetEntityClassname(ent, sWeapon, sizeof(sWeapon));

		int ammoOffset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");

		clip = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iClip1");

		if (StrEqual(sWeapon, "weapon_pumpshotgun") || StrEqual(sWeapon, "weapon_autoshotgun"))
			ammo = GetEntData(client, ammoOffset+(6*4));
		else if (StrEqual(sWeapon, "weapon_smg"))
			ammo = GetEntData(client, ammoOffset+(5*4));
		else if (StrEqual(sWeapon, "weapon_rifle"))
			ammo = GetEntData(client, ammoOffset+(3*4));
		else if (StrEqual(sWeapon, "weapon_hunting_rifle"))
			ammo = GetEntData(client, ammoOffset+(2*4));
		else if (StrEqual(sWeapon, "weapon_pistol"))
			ammo = GetEntProp(ent, Prop_Send, "m_hasDualWeapons" );
	}
}

void GetClientWeaponInfo_l4d2(int client, int ent, int &ammo, int &clip, int &upgradeBit, int &upammo)
{
	if (ent > 0 && GetClientTeam(client) == 2)
	{
		char sWeapon[32];
		GetEntityClassname(ent, sWeapon, sizeof(sWeapon));
		//GetEdictClassname(ent, weapon, 32);

		int ammoOffset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");

		upgradeBit = GetEntProp(ent, Prop_Send, "m_upgradeBitVec");
		upammo = GetEntProp(ent, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded");
		clip = GetEntProp(ent, Prop_Send, "m_iClip1");
		
		if (StrEqual(sWeapon, "weapon_rifle") || StrEqual(sWeapon, "weapon_rifle_sg552") || StrEqual(sWeapon, "weapon_rifle_desert") || StrEqual(sWeapon, "weapon_rifle_ak47") || StrEqual(sWeapon, "weapon_rifle_m60"))
			ammo = GetEntData(client, ammoOffset+(12));
		else if (StrEqual(sWeapon, "weapon_smg") || StrEqual(sWeapon, "weapon_smg_silenced") || StrEqual(sWeapon, "weapon_smg_mp5"))
			ammo = GetEntData(client, ammoOffset+(20));
		else if (StrEqual(sWeapon, "weapon_pumpshotgun") || StrEqual(sWeapon, "weapon_shotgun_chrome"))
			ammo = GetEntData(client, ammoOffset+(28));
		else if (StrEqual(sWeapon, "weapon_autoshotgun") || StrEqual(sWeapon, "weapon_shotgun_spas"))
			ammo = GetEntData(client, ammoOffset+(32));
		else if (StrEqual(sWeapon, "weapon_hunting_rifle"))
			ammo = GetEntData(client, ammoOffset+(36));
		else if (StrEqual(sWeapon, "weapon_sniper_scout") || StrEqual(sWeapon, "weapon_sniper_military") || StrEqual(sWeapon, "weapon_sniper_awp"))
			ammo = GetEntData(client, ammoOffset+(40));
		else if (StrEqual(sWeapon, "weapon_grenade_launcher"))
			ammo = GetEntData(client, ammoOffset+(68));
		else if (StrEqual(sWeapon, "weapon_pistol"))
			ammo = GetEntProp(ent, Prop_Send, "m_hasDualWeapons");
	}
}

void DropPrimaryWeapon_l4d1(int client, char[] weapon, int ammo, int clip) //[LEN64]
{
	bool Drop = false;

	if (StrEqual(weapon, "weapon_rifle") || StrEqual(weapon, "weapon_smg") || StrEqual(weapon, "weapon_hunting_rifle"))
		Drop=true;
	else if (StrEqual(weapon, "weapon_pumpshotgun") || StrEqual(weapon, "weapon_autoshotgun"))
		Drop=true;

 	if(Drop)
	{
		int index = CreateEntityByName(weapon);

		float origin[3];
		GetClientEyePosition(client,origin);

		DispatchSpawn(index);
		TeleportEntity(index, origin, NULL_VECTOR, NULL_VECTOR);
		ActivateEntity(index);

		SetEntProp(index, Prop_Send, "m_iExtraPrimaryAmmo", ammo);
		SetEntProp(index, Prop_Send, "m_iClip1", clip);
	}
}

void DropPrimaryWeapon_l4d2(int client, char[] weapon, int ammo, int clip, int upgradeBit, int upammo) //[LEN64]
{
	bool Drop = false;

	if (StrEqual(weapon, "weapon_rifle") || StrEqual(weapon, "weapon_rifle_ak47") || StrEqual(weapon, "weapon_rifle_sg552") || StrEqual(weapon, "weapon_rifle_desert"))
		Drop=true;
	else if (StrEqual(weapon, "weapon_smg") || StrEqual(weapon, "weapon_smg_silenced") || StrEqual(weapon, "weapon_smg_mp5")) 
		Drop=true;
	else if (StrEqual(weapon, "weapon_pumpshotgun") || StrEqual(weapon, "weapon_shotgun_chrome") || StrEqual(weapon, "weapon_autoshotgun") || StrEqual(weapon, "weapon_shotgun_spas"))
		Drop=true;
	else if (StrEqual(weapon, "weapon_hunting_rifle") || StrEqual(weapon, "weapon_sniper_scout") || StrEqual(weapon, "weapon_sniper_awp") || StrEqual(weapon, "weapon_sniper_military"))
		Drop=true;
	else if (StrEqual(weapon, "weapon_rifle_m60") || StrEqual(weapon, "weapon_grenade_launcher"))
		Drop=true;

	if(Drop)
	{
		int index = CreateEntityByName(weapon);

		float origin[3];
		GetClientEyePosition(client,origin);

		DispatchSpawn(index);
		TeleportEntity(index, origin, NULL_VECTOR, NULL_VECTOR);
		ActivateEntity(index);

		SetEntProp(index, Prop_Send, "m_iExtraPrimaryAmmo", ammo);
		SetEntProp(index, Prop_Send, "m_iClip1", clip);

		upgradeBit+=0;
		upammo+=0;
	}
}

void ResetClientState(int i)
{
	for(int slot = 0; slot <= 4; slot++)
	{
		ItemName[i][slot] = "";
		ItemInfo[i][slot][0] = 0;
		ItemInfo[i][slot][1] = 0;
		ItemInfo[i][slot][2] = 0;
		ItemInfo[i][slot][3] = 0;
		ItemAttachEnt[i][slot] = 0;
	}

	InHeal[i] = 0.0;
	InRevive[i] = 0.0;
	LastButton[i] = 0;
	SwapTime[i] = 0.0;
	PressingTime[i] = 0.0;
	PressStartTime[i] = 0.0;
	LastMeSwitchTime[i] = 0.0;
	LastSwitchTime[i] = 0.0;
	ThrowTime[i] = 0.0;
}

void ResetClientStateAll()
{
	for(int i = 1; i <= MaxClients; i++)
		ResetClientState(i);
}

public Action eHealBegin(Handle event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(GetEventInt(event, "userid"));
	InHeal[player] = GetEngineTime();
}

public Action eHealEnd(Handle event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(GetEventInt(event, "userid"));
	InHeal[player] = 0.0;
}

public Action eReviveBegin(Handle event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(GetEventInt(event, "userid"));
	InRevive[player] = GetEngineTime();
}

public Action eReviveEnd(Handle event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(GetEventInt(event, "userid"));
	InRevive[player] = 0.0;
}

public Action eHealSuccess(Handle event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(0.1, DelayRestore, player, TIMER_FLAG_NO_MAPCHANGE);
}

public Action eMolotovThrown(Handle event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(1.5, DelayRestore, player, TIMER_FLAG_NO_MAPCHANGE);
}

public Action eAdrenalineUsed(Handle event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(0.1, DelayRestore, player, TIMER_FLAG_NO_MAPCHANGE);
}

public Action ePillsUsed (Handle event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(0.1, DelayRestore, player, TIMER_FLAG_NO_MAPCHANGE);
}

static bool IsValidEnt(int ent)
{
	if(ent > 0 && IsValidEdict(ent) && IsValidEntity(ent))
		return true;
	else
		return false;
}

static bool IsValidEntS(int ent, char[] classname) //[LEN64]
{
	if(IsValidEnt(ent))
	{
		char name[LEN64];
		GetEntityClassname(ent, name, sizeof(name));

		if(StrEqual(classname, name))
			return true;
	}

	return false;
}

static bool IsSurvivorThirdPerson(int iClient)
{
	if(bThirdPerson[iClient])
		return true;
	if(GetEntPropEnt(iClient, Prop_Send, "m_hViewEntity") > 0)
		return true;
	if(GetEntPropFloat(iClient, Prop_Send, "m_TimeForceExternalView") > GetGameTime())
		return true;
	if(GetEntProp(iClient, Prop_Send, "m_iObserverMode") == 1)
		return true;
	if(GetEntPropEnt(iClient, Prop_Send, "m_pummelAttacker") > 0)
		return true;
	if(GetEntPropEnt(iClient, Prop_Send, "m_carryAttacker") > 0)
		return true;
	if(GetEntPropEnt(iClient, Prop_Send, "m_pounceAttacker") > 0)
		return true;
	if(GetEntPropEnt(iClient, Prop_Send, "m_jockeyAttacker") > 0)
		return true;
	if(GetEntProp(iClient, Prop_Send, "m_isHangingFromLedge") > 0)
		return true;
	if(GetEntPropEnt(iClient, Prop_Send, "m_reviveTarget") > 0)
		return true;
	if(GetEntPropFloat(iClient, Prop_Send, "m_staggerTimer", 1) > -1.0)
		return true;

	switch(GetEntProp(iClient, Prop_Send, "m_iCurrentUseAction"))
	{
		case 1:
		{
			static int iTarget;
			iTarget = GetEntPropEnt(iClient, Prop_Send, "m_useActionTarget");

			if(iTarget == GetEntPropEnt(iClient, Prop_Send, "m_useActionOwner"))
				return true;
			else if(iTarget != iClient)
				return true;
		}
		case 4, 6, 7, 8, 9, 10:
			return true;
	}

	static char sModel[31];
	GetEntPropString(iClient, Prop_Data, "m_ModelName", sModel, sizeof(sModel));

	switch(sModel[29])
	{
		case 'b'://nick
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 626, 625, 624, 623, 622, 621, 661, 662, 664, 665, 666, 667, 668, 670, 671, 672, 673, 674, 620, 680, 616:
					return true;
			}
		}
		case 'd'://rochelle
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 674, 678, 679, 630, 631, 632, 633, 634, 668, 677, 681, 680, 676, 675, 673, 672, 671, 670, 687, 629, 625, 616:
					return true;
			}
		}
		case 'c'://coach
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 656, 622, 623, 624, 625, 626, 663, 662, 661, 660, 659, 658, 657, 654, 653, 652, 651, 621, 620, 669, 615:
					return true;
			}
		}
		case 'h'://ellis
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 625, 675, 626, 627, 628, 629, 630, 631, 678, 677, 676, 575, 674, 673, 672, 671, 670, 669, 668, 667, 666, 665, 684, 621:
					return true;
			}
		}
		case 'v'://bill
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 528, 759, 763, 764, 529, 530, 531, 532, 533, 534, 753, 676, 675, 761, 758, 757, 756, 755, 754, 527, 772, 762, 522:
					return true;
			}
		}
		case 'n'://zoey
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 537, 819, 823, 824, 538, 539, 540, 541, 542, 543, 813, 828, 825, 822, 821, 820, 818, 817, 816, 815, 814, 536, 809, 572:
					return true;
			}
		}
		case 'e'://francis
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 532, 533, 534, 535, 536, 537, 769, 768, 767, 766, 765, 764, 763, 762, 761, 760, 759, 758, 757, 756, 531, 530, 775, 525:
					return true;
			}
		}
		case 'a'://louis
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 529, 530, 531, 532, 533, 534, 766, 765, 764, 763, 762, 761, 760, 759, 758, 757, 756, 755, 754, 753, 527, 772, 528, 522:
					return true;
			}
		}
		case 'w'://adawong
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 674, 678, 679, 630, 631, 632, 633, 634, 668, 677, 681, 680, 676, 675, 673, 672, 671, 670, 687, 629, 625:
					return true;
			}
		}
	}

	return false;
}

public void TP_OnThirdPersonChanged(int iClient, bool bIsThirdPerson)
{
	bThirdPerson[iClient] = bIsThirdPerson;
}

/*=====[ MY STOCKS ]=====*/
stock bool IsValidAdmin(int client)
{
	if (GetUserFlagBits(client) & ADMFLAG_ROOT) return true;
	return false;
}

stock bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

stock bool IsSpectator(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 1) return true;
	return false;
}

stock bool IsSurvivor(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2) return true;
	return false;
}

stock bool IsInfected(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3) return true;
	return false;
}

stock bool IsPlayerIncapped(int client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
 	return false;
}

stock bool IsOnGround(int client)
{
	if(GetEntityFlags(client) & FL_ONGROUND) return true;
	return false;
}

static bool IsValidEntRef(int iEntRef)
{
    static int iEntity;
    iEntity = EntRefToEntIndex(iEntRef);
    return (iEntRef && iEntity != INVALID_ENT_REFERENCE && IsValidEntity(iEntity));
}

public bool TraceRayDontHitPlayers(int entity, int mask)
{
    if (!entity || entity <= MaxClients || !IsValidEntity(entity))
        return false;
    return true;
}

/*
void CheatCommand(int client, const char[] command, const char[] argument1, const char[] argument2)
{
	int userFlags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s %s", command, argument1, argument2);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userFlags);
}
*/

/*---------->>>>>>>>>>NOTES<<<<<<<<<<----------
IsClientInGame(client); //Returns if a certain player has entered the game.
IsPlayerAlive(client); //Returns if the client is alive or dead.
IsFakeClient(client); //Returns if a certain player is a fake client.
IsClientObserver(client); //Returns if a certain player is an observer/spectator.
IsClientInKickQueue(client); //Returns if a client is in the "kick queue".

GetClientTeam(client); //Retrieves a client's team index.
GetClientHealth(client); //Returns the client's health.
GetClientModel(client, String:model[], maxlen); //Returns the client's model name.
GetClientWeapon(client, String:weapon[], maxlen); //Returns the client's weapon name.
*/