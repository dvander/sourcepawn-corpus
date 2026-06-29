/*NOTES
BACKPACK SIZE SYSTEM
% is total backpack size starting at 100%
-3% space per throwable
-5% space per health/defib/packs
-3% space per pills/adrenaline

BACKPACK ENCUMBRANCE SYSTEM (Make players limp at a certain amount)(detect at what health your limping)
% is total speed starting at 100%
-3% speed per throwable
-5% speed per health/defib/packs
-3% speed per pills/adrenaline
*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
//#pragma dynamic 1024
#pragma newdecls required

#define MAX_FRAMECHECK 50

//int MaxEntities = GetMaxEntities();

PlayerLine[MAXPLAYERS+1];

Molotovs[MAXPLAYERS+1];				//Molotovs
PipeBombs[MAXPLAYERS+1];			//Pipebombs
Vomitjars[MAXPLAYERS+1];			//Bilebombs
FirstAidKits[MAXPLAYERS+1];			//Medkits
Defibs[MAXPLAYERS+1];				//Defibs
Incendiary[MAXPLAYERS+1];			//Incendiary
Explosives[MAXPLAYERS+1];			//Explosive
PainPills[MAXPLAYERS+1];			//Pills
Adrenaline[MAXPLAYERS+1];			//Adrenaline

Storage[MAXPLAYERS+1][9];			//Backpack Storage
Backpack2[MAXPLAYERS+1];			//Slot2 Selector
Backpack3[MAXPLAYERS+1];			//Slot3 Selector
Backpack4[MAXPLAYERS+1];			//Slot4 Selector

//INT
int Reloads[MAXPLAYERS+1], LastSlot[MAXPLAYERS+1], LastWeapon[MAXPLAYERS+1], bWeaponSwitch[MAXPLAYERS+1];
int BackpackOwner[2048+1], BackpackIndex[MAXPLAYERS+1], iModelIndex[MAXPLAYERS+1];

//FLOAT
float InHeal[MAXPLAYERS+1], InRevive[MAXPLAYERS+1], LastDrop[MAXPLAYERS+1];

//BOOL
bool BPToggle[MAXPLAYERS+1], bPickedUp[MAXPLAYERS+1], bThirdPerson[MAXPLAYERS+1];
bool MolotovUsed[MAXPLAYERS+1], PipeBombUsed[MAXPLAYERS+1], VomitjarUsed[MAXPLAYERS+1], MedkitUsed[MAXPLAYERS+1], DefibUsed[MAXPLAYERS+1],
	IncendiaryUsed[MAXPLAYERS+1], ExplosiveUsed[MAXPLAYERS+1], PillsUsed[MAXPLAYERS+1], AdrenUsed[MAXPLAYERS+1];

//CHAR
//static const char SOUND_PICKUP[] 		= "^ui/gift_pickup.wav";
static const char SOUND_NOPICKUP[] 		= "ui/beep_error01.wav";

char gClassname[512], gModelname[512], MedsMunch[MAXPLAYERS+1][32];
char Slot0Class[17][32] = {"rifle", "rifle_sg552", "rifle_desert", "rifle_ak47", "rifle_m60", "smg",
							"smg_silenced", "smg_mp5", "pumpshotgun", "shotgun_chrome", "autoshotgun", "shotgun_spas",
							"hunting_rifle", "sniper_scout", "sniper_military", "sniper_awp", "grenade_launcher"};
char Slot1Class[3][32] = {"pistol", "pistol_magnum", "melee"};
							//"chainsaw", "fireaxe", "baseball_bat", "crowbar",
							//"electric_guitar", "cricket_bat", "frying_pan", "golfclub", "machete", "katana",
							//"tonfa", "knife", "riotshield"};
char Slot2Class[3][32] = {"molotov", "pipe_bomb", "vomitjar"};
char Slot3Class[4][32] = {"first_aid_kit", "defibrillator", "upgradepack_incendiary", "upgradepack_explosive"};
char Slot4Class[2][32] = {"pain_pills", "adrenaline"};

//HANDLE
Handle panel[MAXPLAYERS + 1] = INVALID_HANDLE;

//CONVAR
ConVar DeathDrop, FullNotify, ShowBackpack, SwitchMode;
ConVar max_molotovs, max_pipebombs, max_vomitjars, max_kits, max_defibs, max_incendiary, max_explosive, max_pills, max_adrenalines;
ConVar start_molotovs, start_pipebombs, start_vomitjars, start_kits, start_defibs, start_incendiary, start_explosive, start_pills, start_adrenalines;

public Plugin myinfo =
{
	name = "Oshroth's Backpack",
	author = "MasterMind420, Lux, NGBUCKWANGS, Oshroth",
	description = "Players get a backpack to carry extra items",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_bp", PackMenu);
	RegConsoleCmd("sm_bpt", BackPackToggle);

	RegAdminCmd("sm_vp", ViewPacks, ADMFLAG_GENERIC);

	FullNotify = CreateConVar("l4d_backpack_full_notify", "0", "[1 = Enable][0 = Disable] Backpack full notification");
	DeathDrop = CreateConVar("l4d_backpack_death_drop", "1", "[1 = Enable][0 = Disable] Drop backpack contents when players die");
	ShowBackpack = CreateConVar("l4d_backpack_show_backpack", "1", "[1 = Enable][0 = Disable] Show backpack model on players backs");
	SwitchMode = CreateConVar("l4d_backpack_switch_mode", "1", "[1 = SingleTap][2 = DoubleTap] Select item switch mode");

	max_molotovs = CreateConVar("l4d_backpack_max_mols", "2", "Max Molotovs", _, true, 0.0);
	max_pipebombs = CreateConVar("l4d_backpack_max_pipes", "2", "Max Pipe Bombs", _, true, 0.0);
	max_vomitjars = CreateConVar("l4d_backpack_max_biles", "2", "Max Bile Jars", _, true, 0.0);
	max_kits = CreateConVar("l4d_backpack_max_kits", "2", "Max Medkits", _, true, 0.0);
	max_defibs = CreateConVar("l4d_backpack_max_defibs", "2", "Max Defibs", _, true, 0.0);
	max_incendiary = CreateConVar("l4d_backpack_max_firepacks", "2", "Max Fire Ammo Packs", _, true, 0.0);
	max_explosive = CreateConVar("l4d_backpack_max_explodepacks", "2", "Max Explode Ammo Packs", _, true, 0.0);
	max_pills = CreateConVar("l4d_backpack_max_pills", "2", "Max Pills", _, true, 0.0);
	max_adrenalines = CreateConVar("l4d_backpack_max_adrens", "2", "Max Adrenalines", _, true, 0.0);

	start_molotovs = CreateConVar("l4d_backpack_start_mols", "0", "Starting Molotovs", _, true, 0.0);
	start_pipebombs = CreateConVar("l4d_backpack_start_pipes", "0", "Starting Pipe Bombs", _, true, 0.0);
	start_vomitjars = CreateConVar("l4d_backpack_start_biles", "0", "Starting Bile Jars", _, true, 0.0);
	start_kits = CreateConVar("l4d_backpack_start_kits", "0", "Starting Medkits", _, true, 0.0);
	start_defibs = CreateConVar("l4d_backpack_start_defibs", "0", "Starting Defibs", _, true, 0.0);
	start_incendiary = CreateConVar("l4d_backpack_start_firepacks", "0", "Starting Fire Ammo Packs", _, true, 0.0);
	start_explosive = CreateConVar("l4d_backpack_start_explodepacks", "0", "Starting Explode Ammo Packs", _, true, 0.0);
	start_pills = CreateConVar("l4d_backpack_start_pills", "0", "Starting Pills", _, true, 0.0);
	start_adrenalines = CreateConVar("l4d_backpack_start_adrens", "0", "Starting Adrenalines", _, true, 0.0);

	AutoExecConfig(true, "l4d2_backpack");

	HookEvent("round_start", eRoundStart);										//Save Backpack
	HookEvent("player_team", ePlayerTeam);										//Backpack Model Attachment
	HookEvent("player_activate", ePlayerActivate);
	//HookEvent("player_first_spawn", ePlayerFirstSpawn, EventHookMode_Post);	//Correct quantities

	HookEvent("player_disconnect", ePlayerDisconnect, EventHookMode_Pre);		//Reset disconnecting players
	HookEvent("mission_lost", eMissionLost, EventHookMode_Pre);					//Restore players backpack on mission lost
	HookEvent("finale_win", eFinaleWin, EventHookMode_Pre);						//Reset all players backpacks for new campaigns

	HookEvent("weapon_drop", eWeaponDrop);										//Used to catch when someone uses/drops anything
	HookEvent("player_death", ePlayerDeath);									//Used to catch when someone dies for dropping items
	//HookEvent("weapon_fire", eWeaponFire);									//Used to catch when someone uses grenade
	HookEvent("heal_success", eMedkitUsed, EventHookMode_Pre); 					//Used to catch when someone uses kit
	HookEvent("defibrillator_used", eDefibUsed, EventHookMode_Pre); 			//Used to catch when someone uses defib
	HookEvent("upgrade_pack_used", ePackUsed, EventHookMode_Pre);				//Used to catch when someone uses pack
	HookEvent("pills_used", ePillsUsed, EventHookMode_Pre);						//Used to catch when someone uses pills
	HookEvent("adrenaline_used", eAdrenalineUsed, EventHookMode_Pre);			//Used to catch when someone uses adrenaline

	HookEvent("player_bot_replace", ePlayerReplaced);							//Used to transfer backpack contents to bots
	HookEvent("bot_player_replace", eBotReplaced);								//Used to restore previous player backpack

	HookEvent("item_pickup", eItemPickup);										//Used to catch when someone picks up something
	HookEvent("weapon_given", eGiveWeapon, EventHookMode_Pre);					//Used to catch when someone gives pills

	HookEvent("revive_success", eReviveSuccessPre, EventHookMode_Pre);			//MedsMunch fix for incap
	HookEvent("revive_success", eReviveSuccess, EventHookMode_Post);			//MedsMunch fix for incap

	HookEvent("heal_begin", eHealBegin);
	HookEvent("heal_end", eHealEnd);
 	HookEvent("revive_begin", eReviveBegin);
	HookEvent("revive_end", eReviveEnd);

	//Manually Destroy Backpack Models & SDKHook Entities
	for (int i = MAXPLAYERS; i <= 2048; i++)
	{
		if (IsValidEntity(i))
		{
			if(GetConVarInt(ShowBackpack) == 1)
			{
				GetEntPropString(i, Prop_Data, "m_ModelName", gModelname, sizeof(gModelname));

				if(StrContains(gModelname, "models/props_collectables/backpack.mdl") > -1)
				{
					AcceptEntityInput(i, "Kill");
					continue;
				}
			}

			GetEntityClassname(i, gClassname, sizeof(gClassname));

			if(gClassname[0] != 'w' || StrContains(gClassname, "weapon_", false) != 0)
				continue;

			OnEntityCreated(i, gClassname);
		}
	}

	//Manually Create Backpack Models
	for (int i = 1; i <= MaxClients; i++)
	{
		OnClientPutInServer(i);
		OnClientPostAdminCheck(i);
	}

	//CreateTimer(0.1, GiveItem, _, TIMER_REPEAT);
	//CreateTimer(1.0, AutoRefill, _, TIMER_REPEAT);
}

public Action ViewPacks(int client, int args)
{
	if(client > 0)
		ShowAdminBackpack(client);
/*
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && !IsFakeClient(i))
			PrintToConsole(client, "\n%N \nMolotovs %d, Pipes %d, Bile %d \nMedkits %d, Defibs %d, Incendiary %d, Explosives %d \nPills %d, Adrenaline %d", i, Molotovs[i], PipeBombs[i], Vomitjars[i], FirstAidKits[i], Defibs[i], Incendiary[i], Explosives[i], PainPills[i], Adrenaline[i]);
	}
*/
}

public void OnEntityCreated(int entity, const char[] classname)
{
	//if(StrContains(sClassName, "defibrillator") > -1)
	//	SDKHook(entity, SDKHook_SpawnPost, SpawnPost);

	char sClassname[32];
	GetEntityClassname(entity, sClassname, sizeof(sClassname));

	if(StrContains(sClassname, "pain_pills") > -1 || StrContains(sClassname, "adrenaline") > -1 ||
		StrContains(sClassname, "upgradepack_explosive") > -1 || StrContains(sClassname, "upgradepack_incendiary") > -1 ||
		StrContains(sClassname, "defibrillator") > -1 || StrContains(sClassname, "first_aid_kit") > -1 ||
		StrContains(sClassname, "vomitjar") > -1 || StrContains(sClassname, "pipe_bomb") > -1 ||
		StrContains(sClassname, "molotov") > -1)
		SDKHook(entity, SDKHook_Use, OnPlayerUse);
}

/*
public void SpawnPost(int entity)
{
	int Defib = GetEntProp(entity, Prop_Send, "m_iWorldModelIndex");
	PrintToChatAll("Defib World Model Index %d", Defib);
}
*/

public void OnClientPutInServer(int client)
{
	if(IsValidClient(client))
	{
		SDKHook(client, SDKHook_WeaponSwitch, WeaponSwitch);
		SDKHook(client, SDKHook_WeaponCanUse, WeaponCanUse);
	}
}

public void OnClientPostAdminCheck(int client)
{
	if(IsValidClient(client) && !IsFakeClient(client))
	{
		if(GetConVarInt(ShowBackpack) == 1)
			CreateTimer(1.0, FixBackpackPosition, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void ePlayerActivate(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(IsValidClient(client))
	{
		//if(FirstAidKits[client] == 0 && !IsFakeClient(client))
		//	FirstAidKits[client] += 1;

		CreateTimer(1.0, FixBackpack, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void eRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		//FirstAidKits[i] += 1;

		//if (FirstAidKits[i] >= GetConVarInt(max_kits))
		//	FirstAidKits[i] = GetConVarInt(max_kits);

		CreateTimer(1.0, FixBackpack, i, TIMER_FLAG_NO_MAPCHANGE);
		SaveBackpack(i);
	}
}

public void ePlayerFirstSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsValidClient(client) && !IsFakeClient(client))
	{
		//CreateTimer(1.0, FixQuantity, client, TIMER_FLAG_NO_MAPCHANGE);
		//CreateTimer(1.5, FixStartBackpack, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action ePlayerTeam(Handle event, const char[] sEventName, bool bDontBroadcast)
{
	int team = GetEventInt(event, "team");
	int oldteam = GetEventInt(event, "oldteam");
	int disconnect = GetEventBool(event, "disconnect");
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(!IsValidClient(client))
		return;

	switch(oldteam)
	{
		case 0:
		{
			//if(!IsFakeClient(client))
			//	PrintToChatAll("%N Left Team 0(Idle)", client);
		}
		case 1:
		{
			//if(!IsFakeClient(client))
			//	PrintToChatAll("%N Left Team 1(Spectate)", client);
		}
		case 2:
		{
			//if(!IsFakeClient(client))
			//	PrintToChatAll("%N Left Team 2(Survivor)", client);
		}
		case 3:
		{
			//if(!IsFakeClient(client))
			//	PrintToChatAll("%N Left Team 3(Infected)", client);
		}
	}

	switch(team)
	{
		case 0:
		{
			//if(!IsFakeClient(client))
			//	PrintToChatAll("%N Joined Team 0(Idle)", client);
		}
		case 1:
		{
			//if(!IsFakeClient(client))
			//	PrintToChatAll("%N Joined Team 1(Spectate)", client);
		}
		case 2:
		{
			CreateTimer(0.3, FixBackpack, client, TIMER_FLAG_NO_MAPCHANGE);

			if(GetConVarInt(ShowBackpack) == 1)
				CreateTimer(0.2, FixBackpackPosition, client, TIMER_FLAG_NO_MAPCHANGE);
			//if(!IsFakeClient(client))
			//	PrintToChatAll("%N Joined Team 2(Survivor)", client);
		}
		case 3:
		{
			//if(!IsFakeClient(client))
			//	PrintToChatAll("%N Joined Team 3(Infected)", client);
		}
	}

	if(disconnect)
	{
		//if(!IsFakeClient(client))
		//	PrintToChatAll("%N Disconnected", client);
	}

	if(GetConVarInt(ShowBackpack) != 1)
		return;

	if(IsValidEntRef(BackpackIndex[client]))
	{
		AcceptEntityInput(BackpackIndex[client], "kill");
		BackpackIndex[client] = -1;
	}
}

public Action ePlayerDisconnect(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(IsValidClient(client))
	{
		ResetBackpack(client);
		SDKUnhook(client, SDKHook_WeaponSwitch, WeaponSwitch);
		SDKUnhook(client, SDKHook_WeaponCanUse, WeaponCanUse);
	}
}

public void ePlayerReplaced(Handle event, const char[] name, bool dontBroadcast)
{
	int bot = GetClientOfUserId(GetEventInt(event, "bot"));
	int player = GetClientOfUserId(GetEventInt(event, "player"));

	Storage[player][0] = Molotovs[player];
	Storage[player][1] = PipeBombs[player];
	Storage[player][2] = Vomitjars[player];
	Storage[player][3] = FirstAidKits[player];
	Storage[player][4] = Defibs[player];
	Storage[player][5] = Incendiary[player];
	Storage[player][6] = Explosives[player];
	Storage[player][7] = PainPills[player];
	Storage[player][8] = Adrenaline[player];

	Molotovs[bot] = Molotovs[player];
	PipeBombs[bot] = PipeBombs[player];
	Vomitjars[bot] = Vomitjars[player];
	FirstAidKits[bot] = FirstAidKits[player];
	Defibs[bot] = Defibs[player];
	Incendiary[bot] = Incendiary[player];
	Explosives[bot] = Explosives[player];
	PainPills[bot] = PainPills[player];
	Adrenaline[bot] = Adrenaline[player];
}

//Bot Replace
public void eBotReplaced(Handle event, const char[] name, bool dontBroadcast)
{
	//int bot = GetClientOfUserId(GetEventInt(event, "bot"));
	int player = GetClientOfUserId(GetEventInt(event, "player"));
/*
	Molotovs[player] = Molotovs[bot];
	PipeBombs[player] = PipeBombs[bot];
	Vomitjars[player] = Vomitjars[bot];
	FirstAidKits[player] = FirstAidKits[bot];
	Defibs[player] = Defibs[bot];
	Incendiary[player] = Incendiary[bot];
	Explosives[player] = Explosives[bot];
	PainPills[player] = PainPills[bot];
	Adrenaline[player] = Adrenaline[bot];
*/

	int slot2 = GetPlayerWeaponSlot(player, 2);
	int slot3 = GetPlayerWeaponSlot(player, 3);
	int slot4 = GetPlayerWeaponSlot(player, 4);

	if(slot2 == -1)
	{
		if(Molotovs[player] > 0)
			GiveWeapon(player, "weapon_molotov");
		else if(PipeBombs[player] > 0)
			GiveWeapon(player, "weapon_pipe_bomb");
		else if(Vomitjars[player] > 0)
			GiveWeapon(player, "weapon_vomitjar");
	}

	if(slot3 == -1)
	{
		if(FirstAidKits[player] > 0)
			GiveWeapon(player, "weapon_first_aid_kit");
		else if(Defibs[player] > 0)
			GiveWeapon(player, "weapon_defibrillator");
		else if(Incendiary[player] > 0)
			GiveWeapon(player, "weapon_upgradepack_incendiary");
		else if(Explosives[player] > 0)
			GiveWeapon(player, "weapon_upgradepack_explosive");
	}

	if(slot4 == -1)
	{
		if(PainPills[player] > 0)
			GiveWeapon(player, "weapon_pain_pills");
		else if(Adrenaline[player] > 0)
			GiveWeapon(player, "weapon_adrenaline");	
	}
}

//====================[ TIMERS ]====================//
public Action FixQuantity(Handle timer, any client)
{
	if (!IsValidClient(client) || GetClientTeam(client) != 2)
		return Plugin_Continue;

	int slot;
	char sClassName[32];

	slot = GetPlayerWeaponSlot(client, 2);

	if (slot != -1)
	{
		GetEntityClassname(slot, sClassName, sizeof(sClassName));
		
		if (StrContains(sClassName, "molotov", false) != -1)
		{
			Molotovs[client] += 1;
			Backpack2[client] = 1;
		}
		else if (StrContains(sClassName, "pipe_bomb", false) != -1)
		{
			PipeBombs[client] += 1;
			Backpack2[client] = 2;
		}
		else if (StrContains(sClassName, "vomitjar", false) != -1)
		{
			Vomitjars[client] += 1;
			Backpack2[client] = 3;
		}
	}

	slot = GetPlayerWeaponSlot(client, 3);

	if (slot != -1)
	{
		GetEntityClassname(slot, sClassName, sizeof(sClassName));
		
		if (StrContains(sClassName, "first_aid_kit", false) != -1)
		{
			FirstAidKits[client] += 1;
			Backpack3[client] = 1;
		}
		else if (StrContains(sClassName, "defibrillator", false) != -1)
		{
			Defibs[client] += 1;
			Backpack3[client] = 2;
		}
		else if (StrContains(sClassName, "upgradepack_incendiary", false) != -1)
		{
			Incendiary[client] += 1;
			Backpack3[client] = 3;
		}
		else if (StrContains(sClassName, "upgradepack_explosive", false) != -1)
		{
			Explosives[client] += 1;
			Backpack3[client] = 4;
		}
	}

	slot = GetPlayerWeaponSlot(client, 4);

	if (slot != -1)
	{
		GetEntityClassname(slot, sClassName, sizeof(sClassName));
		
		if (StrContains(sClassName, "pain_pills", false) != -1)
		{
			PainPills[client] += 1;
			Backpack4[client] = 1;
		}
		else if (StrContains(sClassName, "adrenaline", false) != -1)
		{
			Adrenaline[client] += 1;
			Backpack4[client] = 2;
		}
	}

	return Plugin_Continue;
}

public Action FixBackpack(Handle timer, any client)
{
	if (!IsValidClient(client) || GetClientTeam(client) != 2)
		return Plugin_Continue;

	int slot;
	slot = GetPlayerWeaponSlot(client, 2);

	if (slot == -1)
	{
		if(Molotovs[client] > 0)
		{
			Backpack2[client] = 1;
			GiveWeapon(client, "weapon_molotov");
		}
		else if(PipeBombs[client] > 0)
		{
			Backpack2[client] = 2;
			GiveWeapon(client, "weapon_pipe_bomb");
		}
		else if(Vomitjars[client] > 0)
		{
			Backpack2[client] = 3;
			GiveWeapon(client, "weapon_vomitjar");
		}
	}

	slot = GetPlayerWeaponSlot(client, 3);

	if (slot == -1)
	{
		if(FirstAidKits[client] > 0)
		{
			Backpack3[client] = 1;
			GiveWeapon(client, "weapon_first_aid_kit");
		}
		else if(Defibs[client] > 0)
		{
			Backpack3[client] = 2;
			GiveWeapon(client, "weapon_defibrillator");
		}
		else if(Incendiary[client] > 0)
		{
			Backpack3[client] = 3;
			GiveWeapon(client, "weapon_upgradepack_incendiary");
		}
		else if(Explosives[client] > 0)
		{
			Backpack3[client] = 4;
			GiveWeapon(client, "weapon_upgradepack_explosive");
		}
	}

	slot = GetPlayerWeaponSlot(client, 4);

	if (slot == -1)
	{
		if(PainPills[client] > 0)
		{
			Backpack4[client] = 1;
			GiveWeapon(client, "weapon_pain_pills");
		}
		else if(Adrenaline[client] > 0)
		{
			Backpack4[client] = 2;
			GiveWeapon(client, "weapon_adrenaline");
		}
	}
	
	return Plugin_Continue;
}

public Action FixStartBackpack(Handle timer, any client)
{
	if (!IsValidClient(client) || GetClientTeam(client) != 2)
		return Plugin_Continue;

	int slot;
	StartBackpack(client);

	slot = GetPlayerWeaponSlot(client, 2);

	if (slot == -1)
	{
		if(Molotovs[client] > 0)
		{
			Backpack2[client] = 1;
			GiveWeapon(client, "weapon_molotov");
		}
		else if(PipeBombs[client] > 0)
		{
			Backpack2[client] = 2;
			GiveWeapon(client, "weapon_pipe_bomb");
		}
		else if(Vomitjars[client] > 0)
		{
			Backpack2[client] = 3;
			GiveWeapon(client, "weapon_vomitjar");
		}
	}

	slot = GetPlayerWeaponSlot(client, 3);

	if (slot == -1)
	{
		if(FirstAidKits[client] > 0)
		{
			Backpack3[client] = 1;
			GiveWeapon(client, "weapon_first_aid_kit");
		}
		else if(Defibs[client] > 0)
		{
			Backpack3[client] = 2;
			GiveWeapon(client, "weapon_defibrillator");
		}
		else if(Incendiary[client] > 0)
		{
			Backpack3[client] = 3;
			GiveWeapon(client, "weapon_upgradepack_incendiary");
		}
		else if(Explosives[client] > 0)
		{
			Backpack3[client] = 4;
			GiveWeapon(client, "weapon_upgradepack_explosive");
		}
	}

	slot = GetPlayerWeaponSlot(client, 4);

	if (slot == -1)
	{
		if(PainPills[client] > 0)
		{
			Backpack4[client] = 1;
			GiveWeapon(client, "weapon_pain_pills");
		}
		else if(Adrenaline[client] > 0)
		{
			Backpack4[client] = 2;
			GiveWeapon(client, "weapon_adrenaline");
		}
	}
	
	return Plugin_Continue;
}

public Action FixBackpackPosition(Handle Timer, any client)
{
	if (IsValidClient(client) && GetClientTeam(client) == 2)
		CreateBackpack(client);
}

public void OnGameFrame()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && GetClientTeam(i) == 2)
			bPickedUp[i] = false;
	}

	static int iFrameskip = 0;
	iFrameskip = (iFrameskip + 1) % MAX_FRAMECHECK;
	if(iFrameskip != 0 || !IsServerProcessing())
		return;

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && !IsFakeClient(i) && GetClientTeam(i) == 2)
		{
			if(GetConVarInt(ShowBackpack) == 1)
			{
				if(iModelIndex[i] == GetEntProp(i, Prop_Data, "m_nModelIndex", 2))
					continue;

				CheckAnimation(i, GetEntProp(i, Prop_Send, "m_nSequence", 2));
				CreateBackpack(i);
			}
		}
	}
}

public Action OnPlayerUse(int entity, int activator, int caller, UseType type, float value)
{
	if(bPickedUp[activator])
		return Plugin_Handled;

	char sClassname[32];
	GetEntityClassname(entity, sClassname, sizeof(sClassname));
	//PrintToChat(client, "OnPlayerUse %s", item);

	if (StrContains(sClassname, "spawn") > -1)
	{
		if(GetEntProp(entity, Prop_Data, "m_spawnflags") < 8 && GetEntProp(entity, Prop_Data, "m_itemCount") < 1)
			return Plugin_Handled;
	}

	int slot;

	slot = DetectSlot(sClassname);
	BackpackQuantityHint(activator, slot, sClassname);

//SLOT2
	if(StrContains(sClassname, "molotov") > -1)
	{
		slot = GetPlayerWeaponSlot(activator, 2);

		if(Molotovs[activator] >= GetConVarInt(max_molotovs))
		{
			if(GetConVarInt(FullNotify) == 1)
				PrintToChat(activator, "[ \x04( %d/2 )\x01 MOLOTOVS FULL ]", Molotovs[activator]);
			else if(GetConVarInt(FullNotify) == 2)
				PrintHintText(activator, "[ ( %d/2 ) MOLOTOVS FULL ]", Molotovs[activator]);

			//if(IsFakeClient(activator))
			//{	
			if(slot > -1)
			{
				GetEntityClassname(slot, sClassname, sizeof(sClassname));

				if(StrContains(sClassname, "molotov") == -1)
				{
					RemovePlayerItem(activator, slot);
					AcceptEntityInput(slot, "kill");
					GiveWeapon(activator, "weapon_molotov");
				}
			}
			//}

			EmitSoundToClient(activator, SOUND_NOPICKUP, _, SNDCHAN_WEAPON, SNDLEVEL_GUNFIRE);
			return Plugin_Handled;
		}
		else
		{
			if(slot > -1)
			{
				RemovePlayerItem(activator, slot);
				AcceptEntityInput(slot, "kill");
			}

			Molotovs[activator] += 1;
		}
	}
	else if(StrContains(sClassname, "pipe_bomb") > -1)
	{
		slot = GetPlayerWeaponSlot(activator, 2);

		if (PipeBombs[activator] >= GetConVarInt(max_pipebombs))
		{
			if(GetConVarInt(FullNotify) == 1)
				PrintToChat(activator, "[ \x04( %d/2 )\x01 PIPEBOMBS FULL ]", PipeBombs[activator]);
			else if(GetConVarInt(FullNotify) == 2)
				PrintHintText(activator, "[ ( %d/2 ) PIPEBOMBS FULL ]", PipeBombs[activator]);

			//if(IsFakeClient(activator))
			//{
			if(slot > -1)
			{
				GetEntityClassname(slot, sClassname, sizeof(sClassname));

				if(StrContains(sClassname, "pipe_bomb") == -1)
				{
					RemovePlayerItem(activator, slot);
					AcceptEntityInput(slot, "kill");
					GiveWeapon(activator, "weapon_pipe_bomb");
				}
			}
			//}

			EmitSoundToClient(activator, SOUND_NOPICKUP, _, SNDCHAN_WEAPON, SNDLEVEL_GUNFIRE);
			return Plugin_Handled;
		}
		else
		{
			if(slot > -1)
			{
				RemovePlayerItem(activator, slot);
				AcceptEntityInput(slot, "kill");
			}

			PipeBombs[activator] += 1;
		}
	}
	else if(StrContains(sClassname, "vomitjar") > -1)
	{
		slot = GetPlayerWeaponSlot(activator, 2);

		if (Vomitjars[activator] >= GetConVarInt(max_vomitjars))
		{
			if(GetConVarInt(FullNotify) == 1)
				PrintToChat(activator, "[ \x04( %d/2 )\x01 VOMITJARS FULL ]", Vomitjars[activator]);
			else if(GetConVarInt(FullNotify) == 2)
				PrintHintText(activator, "[ ( %d/2 ) VOMITJARS FULL ]", Vomitjars[activator]);

			//if(IsFakeClient(activator))
			//{
			if(slot > -1)
			{
				GetEntityClassname(slot, sClassname, sizeof(sClassname));

				if(StrContains(sClassname, "vomitjar") == -1)
				{
					RemovePlayerItem(activator, slot);
					AcceptEntityInput(slot, "kill");
					GiveWeapon(activator, "weapon_vomitjar");
				}
			}
			//}

			EmitSoundToClient(activator, SOUND_NOPICKUP, _, SNDCHAN_WEAPON, SNDLEVEL_GUNFIRE);
			return Plugin_Handled;
		}
		else
		{
			if(slot > -1)
			{
				RemovePlayerItem(activator, slot);
				AcceptEntityInput(slot, "kill");
			}

			Vomitjars[activator] += 1;
		}
	}

//SLOT3
	if(StrContains(sClassname, "first_aid_kit") > -1)
	{
		slot = GetPlayerWeaponSlot(activator, 3);

		if (FirstAidKits[activator] >= GetConVarInt(max_kits))
		{
			if(GetConVarInt(FullNotify) == 1)
				PrintToChat(activator, "[ \x04( %d/2 )\x01 MEDKITS FULL ]", FirstAidKits[activator]);
			else if(GetConVarInt(FullNotify) == 2)
				PrintHintText(activator, "[ ( %d/2 ) MEDKITS FULL ]", FirstAidKits[activator]);

			//if(IsFakeClient(activator))
			//{
			if(slot > -1)
			{
				GetEntityClassname(slot, sClassname, sizeof(sClassname));

				if(StrContains(sClassname, "first_aid_kit") == -1)
				{
					RemovePlayerItem(activator, slot);
					AcceptEntityInput(slot, "kill");
					GiveWeapon(activator, "weapon_first_aid_kit");
				}
			}
			//}

			EmitSoundToClient(activator, SOUND_NOPICKUP, _, SNDCHAN_WEAPON, SNDLEVEL_GUNFIRE);
			return Plugin_Handled;
		}
		else
		{
			if(slot > -1)
			{
				RemovePlayerItem(activator, slot);
				AcceptEntityInput(slot, "kill");
			}

			FirstAidKits[activator] += 1;
		}
	}
	else if(StrContains(sClassname, "defibrillator") > -1)
	{
		slot = GetPlayerWeaponSlot(activator, 3);

		if (Defibs[activator] >= GetConVarInt(max_defibs))
		{
			if(GetConVarInt(FullNotify) == 1)
				PrintToChat(activator, "[ \x04( %d/2 )\x01 DEFIBS FULL ]", Defibs[activator]);
			else if(GetConVarInt(FullNotify) == 2)
				PrintHintText(activator, "[ ( %d/2 ) DEFIBS FULL ]", Defibs[activator]);

			//if(IsFakeClient(activator))
			//{
			if(slot > -1)
			{
				GetEntityClassname(slot, sClassname, sizeof(sClassname));

				if(StrContains(sClassname, "defibrillator") == -1)
				{
					RemovePlayerItem(activator, slot);
					AcceptEntityInput(slot, "kill");
					GiveWeapon(activator, "weapon_defibrillator");
				}
			}
			//}

			EmitSoundToClient(activator, SOUND_NOPICKUP, _, SNDCHAN_WEAPON, SNDLEVEL_GUNFIRE);
			return Plugin_Handled;
		}
		else
		{
			if(slot > -1)
			{
				RemovePlayerItem(activator, slot);
				AcceptEntityInput(slot, "kill");
			}

			Defibs[activator] += 1;
		}
	}
	else if(StrContains(sClassname, "upgradepack_incendiary") > -1)
	{
		slot = GetPlayerWeaponSlot(activator, 3);

		if (Incendiary[activator] >= GetConVarInt(max_incendiary))
		{
			if(GetConVarInt(FullNotify) == 1)
				PrintToChat(activator, "[ \x04( %d/2 )\x01 INCENDIARY FULL ]", Incendiary[activator]);
			else if(GetConVarInt(FullNotify) == 2)
				PrintHintText(activator, "[ ( %d/2 ) INCENDIARY FULL ]", Incendiary[activator]);

			//if(IsFakeClient(activator))
			//{
			if(slot > -1)
			{
				GetEntityClassname(slot, sClassname, sizeof(sClassname));

				if(StrContains(sClassname, "upgradepack_incendiary") == -1)
				{
					RemovePlayerItem(activator, slot);
					AcceptEntityInput(slot, "kill");
					GiveWeapon(activator, "weapon_upgradepack_incendiary");
				}
			}
			//}

			EmitSoundToClient(activator, SOUND_NOPICKUP, _, SNDCHAN_WEAPON, SNDLEVEL_GUNFIRE);
			return Plugin_Handled;
		}
		else
		{
			if(slot > -1)
			{
				RemovePlayerItem(activator, slot);
				AcceptEntityInput(slot, "kill");
			}

			Incendiary[activator] += 1;
		}
	}
	else if(StrContains(sClassname, "upgradepack_explosive") > -1)
	{
		slot = GetPlayerWeaponSlot(activator, 3);

		if (Explosives[activator] >= GetConVarInt(max_explosive))
		{
			if(GetConVarInt(FullNotify) == 1)
				PrintToChat(activator, "[ \x04( %d/2 )\x01 EXPLOSIVE FULL ]", Explosives[activator]);
			else if(GetConVarInt(FullNotify) == 2)
				PrintHintText(activator, "[ ( %d/2 ) EXPLOSIVE FULL ]", Explosives[activator]);

			//if(IsFakeClient(activator))
			//{
			if(slot > -1)
			{
				GetEntityClassname(slot, sClassname, sizeof(sClassname));

				if(StrContains(sClassname, "upgradepack_explosive") == -1)
				{
					RemovePlayerItem(activator, slot);
					AcceptEntityInput(slot, "kill");
					GiveWeapon(activator, "weapon_upgradepack_explosive");
				}
			}
			//}

			EmitSoundToClient(activator, SOUND_NOPICKUP, _, SNDCHAN_WEAPON, SNDLEVEL_GUNFIRE);
			return Plugin_Handled;
		}
		else
		{
			if(slot > -1)
			{
				RemovePlayerItem(activator, slot);
				AcceptEntityInput(slot, "kill");
			}

			Explosives[activator] += 1;
		}
	}

//SLOT4
	if(StrContains(sClassname, "pain_pills") > -1)
	{
		slot = GetPlayerWeaponSlot(activator, 4);

		if (PainPills[activator] >= GetConVarInt(max_pills))
		{
			if(GetConVarInt(FullNotify) == 1)
				PrintToChat(activator, "[ \x04( %d/2 )\x01 PILLS FULL ]", PainPills[activator]);
			else if(GetConVarInt(FullNotify) == 2)
				PrintHintText(activator, "[ ( %d/2 ) PILLS FULL ]", PainPills[activator]);

			//if(IsFakeClient(activator))
			//{
			if(slot > -1)
			{
				GetEntityClassname(slot, sClassname, sizeof(sClassname));

				if(StrContains(sClassname, "pain_pills") == -1)
				{
					RemovePlayerItem(activator, slot);
					AcceptEntityInput(slot, "kill");
					GiveWeapon(activator, "weapon_pain_pills");
				}
			}
			//}

			EmitSoundToClient(activator, SOUND_NOPICKUP, _, SNDCHAN_WEAPON, SNDLEVEL_GUNFIRE);
			return Plugin_Handled;
		}
		else
		{
			if(slot > -1)
			{
				RemovePlayerItem(activator, slot);
				AcceptEntityInput(slot, "kill");
			}

			PainPills[activator] += 1;
		}
	}
	else if(StrContains(sClassname, "adrenaline") > -1)
	{
		slot = GetPlayerWeaponSlot(activator, 4);

		if (Adrenaline[activator] >= GetConVarInt(max_adrenalines))
		{
			if(GetConVarInt(FullNotify) == 1)
				PrintToChat(activator, "[ \x04( %d/2 )\x01 ADRENALINE FULL ]", Adrenaline[activator]);
			else if(GetConVarInt(FullNotify) == 2)
				PrintHintText(activator, "[ ( %d/2 ) ADRENALINE FULL ]", Adrenaline[activator]);

			//if(IsFakeClient(activator))
			//{
			if(slot > -1)
			{
				GetEntityClassname(slot, sClassname, sizeof(sClassname));

				if(StrContains(sClassname, "adrenaline") == -1)
				{
					RemovePlayerItem(activator, slot);
					AcceptEntityInput(slot, "kill");
					GiveWeapon(activator, "weapon_adrenaline");
				}
			}
			//}

			EmitSoundToClient(activator, SOUND_NOPICKUP, _, SNDCHAN_WEAPON, SNDLEVEL_GUNFIRE);
			return Plugin_Handled;
		}
		else
		{
			if(slot > -1)
			{
				RemovePlayerItem(activator, slot);
				AcceptEntityInput(slot, "kill");
			}

			Adrenaline[activator] += 1;
		}
	}

	bPickedUp[activator] = true;

	return Plugin_Continue;
}

public Action eItemPickup(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	char item[32];
	GetEventString(event, "item", item, sizeof(item));
	//PrintToChat(client, "Item Pickup %s", item);

	if(StrContains(item, "molotov", false) > -1)
	{
		Backpack2[client] = 1;
		if(Molotovs[client] >= 2)
			Molotovs[client] = 2;
	}
	else if(StrContains(item, "pipe_bomb", false) > -1)
	{
		Backpack2[client] = 2;
		if(PipeBombs[client] >= 2)
			PipeBombs[client] = 2;
	}
	else if(StrContains(item, "vomitjar", false) > -1)
	{
		Backpack2[client] = 3;
		if(Vomitjars[client] >= 2)
			Vomitjars[client] = 2;
	}
	else if(StrContains(item, "first_aid_kit", false) > -1)
	{
		Backpack3[client] = 1;
		if(FirstAidKits[client] >= 2)
			FirstAidKits[client] = 2;
	}
	else if(StrContains(item, "defibrillator", false) > -1)
	{
		Backpack3[client] = 2;
		if(Defibs[client] >= 2)
			Defibs[client] = 2;
	}
	else if(StrContains(item, "upgradepack_incendiary", false) > -1)
	{
		Backpack3[client] = 3;
		if(Incendiary[client] >= 2)
			Incendiary[client] = 2;
	}
	else if(StrContains(item, "upgradepack_explosive", false) > -1)
	{
		Backpack3[client] = 4;
		if(Explosives[client] >= 2)
			Explosives[client] = 2;
	}
	else if(StrContains(item, "pain_pills", false) > -1)
	{
		Backpack4[client] = 1;
		if(PainPills[client] >= 2)
			PainPills[client] = 2;
	}
	else if(StrContains(item, "adrenaline", false) > -1)
	{
		Backpack4[client] = 2;
		if(Adrenaline[client] >= 2)
			Adrenaline[client] = 2;
	}

	int slot = DetectSlot(item);
	BackpackQuantityHint(client, slot, item);
	bWeaponSwitch[client] = true;
}

public void eWeaponDrop(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	//int entity = GetEventInt(event, "propid");

	if(IsValidClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		char item[32];
		GetEventString(event, "item", item, sizeof(item));
		//PrintToChat(client, "WeaponDrop %s", item);

		if (StrEqual(item, "molotov"))
		{
			MolotovUsed[client] = true;

			if(Molotovs[client] > 0)
			{
				Molotovs[client] -= 1;

				if(Molotovs[client] <= 0)
					Molotovs[client] = 0;
			}

			RequestFrame(NextFrame, client);
		}
		else if (StrEqual(item, "pipe_bomb"))
		{
			PipeBombUsed[client] = true;

			if(PipeBombs[client] > 0)
			{
				PipeBombs[client] -= 1;

				if(PipeBombs[client] <= 0)
					PipeBombs[client] = 0;
			}

			RequestFrame(NextFrame, client);
		}
		else if (StrEqual(item, "vomitjar"))
		{
			VomitjarUsed[client] = true;

			if(Vomitjars[client] > 0)
			{
				Vomitjars[client] -= 1;

				if(Vomitjars[client] <= 0)
					Vomitjars[client] = 0;
			}

			RequestFrame(NextFrame, client);
		}
		else if (StrEqual(item, "first_aid_kit"))
		{
			//MedkitUsed[client] = true;

			if(FirstAidKits[client] > 0)
			{
				FirstAidKits[client] -= 1;

				if(FirstAidKits[client] <= 0)
					FirstAidKits[client] = 0;
			}

			RequestFrame(NextFrame, client);
		}
		else if (StrEqual(item, "defibrillator"))
		{
			//DefibUsed[client] = true;

			if(Defibs[client] > 0)
			{
				Defibs[client] -= 1;

				if(Defibs[client] <= 0)
					Defibs[client] = 0;
			}

			RequestFrame(NextFrame, client);
		}
		else if (StrEqual(item, "upgradepack_incendiary"))
		{
			//IncendiaryUsed[client] = true;

			if(Incendiary[client] > 0)
			{
				Incendiary[client] -= 1;

				if(Incendiary[client] <= 0)
					Incendiary[client] = 0;
			}

			RequestFrame(NextFrame, client);
		}
		else if (StrEqual(item, "upgradepack_explosive"))
		{
			//ExplosiveUsed[client] = true;

			if(Explosives[client] > 0)
			{
				Explosives[client] -= 1;

				if(Explosives[client] <= 0)
					Explosives[client] = 0;
			}

			RequestFrame(NextFrame, client);
		}
		else if (StrEqual(item, "pain_pills"))
		{
			//PillsUsed[client] = true;

			if(PainPills[client] > 0)
			{
				PainPills[client] -= 1;

				if(PainPills[client] <= 0)
					PainPills[client] = 0;
				if(PainPills[client] >= 2)
					PainPills[client] = 2;
			}

			RequestFrame(NextFrame, client);
		}
		else if (StrEqual(item, "adrenaline"))
		{
			//AdrenUsed[client] = true;

			if(Adrenaline[client] > 0)
			{
				Adrenaline[client] -= 1;

				if(Adrenaline[client] <= 0)
					Adrenaline[client] = 0;
			}

			RequestFrame(NextFrame, client);
		}
	}
}

public void NextFrame(any client)
{
	RequestFrame(GiveItem, client);
}

public void ForceChangeWeapon(int client, int slot)
{
	int weapon = GetPlayerWeaponSlot(client, slot);

	if(weapon > 0)
	{
		char sWeapon[32];
		GetEntityClassname(weapon, sWeapon, sizeof(sWeapon));

		FakeClientCommand(client, "use %s", sWeapon);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}
}

public void GiveItem(any client)
{
	if(IsValidClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		if (MolotovUsed[client])
		{
			MolotovUsed[client] = false;
			bWeaponSwitch[client] = true;

			if(Molotovs[client] > 0)
			{
				GiveWeapon(client, "weapon_molotov");
				ClientCommand(client, "slot3");
				//ForceChangeWeapon(client, 2);
			}
			else if(PipeBombs[client] > 0)
			{
				GiveWeapon(client, "weapon_pipe_bomb");
				ClientCommand(client, "slot3");
				//ForceChangeWeapon(client, 2);
			}
			else if(Vomitjars[client] > 0)
			{
				GiveWeapon(client, "weapon_vomitjar");
				ClientCommand(client, "slot3");
				//ForceChangeWeapon(client, 2);
			}
		}
		else if (PipeBombUsed[client])
		{
			PipeBombUsed[client] = false;
			bWeaponSwitch[client] = true;

			if(PipeBombs[client] > 0)
			{
				GiveWeapon(client, "weapon_pipe_bomb");
				ClientCommand(client, "slot3");
				//ForceChangeWeapon(client, 2);
			}
			else if(Vomitjars[client] > 0)
			{
				GiveWeapon(client, "weapon_vomitjar");
				ClientCommand(client, "slot3");
				//ForceChangeWeapon(client, 2);
			}
			else if(Molotovs[client] > 0)
			{
				GiveWeapon(client, "weapon_molotov");
				ClientCommand(client, "slot3");
				//ForceChangeWeapon(client, 2);
			}
		}
		else if (VomitjarUsed[client])
		{
			VomitjarUsed[client] = false;
			bWeaponSwitch[client] = true;

			if(Vomitjars[client] > 0)
			{
				GiveWeapon(client, "weapon_vomitjar");
				ClientCommand(client, "slot3");
				//ForceChangeWeapon(client, 2);
			}
			else if(Molotovs[client] > 0)
			{
				GiveWeapon(client, "weapon_molotov");
				ClientCommand(client, "slot3");
				//ForceChangeWeapon(client, 2);
			}
			else if(PipeBombs[client] > 0)
			{
				GiveWeapon(client, "weapon_pipe_bomb");
				ClientCommand(client, "slot3");
				//ForceChangeWeapon(client, 2);
			}
		}
		else if (MedkitUsed[client])
		{
			MedkitUsed[client] = false;
			bWeaponSwitch[client] = true;

			if(FirstAidKits[client] > 0)
			{
				GiveWeapon(client, "weapon_first_aid_kit");
				//ClientCommand(client, "slot4");
			}
			else if(Defibs[client] > 0)
			{
				GiveWeapon(client, "weapon_defibrillator");
				//ClientCommand(client, "slot4");
			}
			else if(Incendiary[client] > 0)
			{
				GiveWeapon(client, "weapon_upgradepack_incendiary");
				//ClientCommand(client, "slot4");
			}
			else if(Explosives[client] > 0)
			{
				GiveWeapon(client, "weapon_upgradepack_explosive");
				//ClientCommand(client, "slot4");
			}
		}
		else if (DefibUsed[client])
		{
			DefibUsed[client] = false;
			bWeaponSwitch[client] = true;

			if(Defibs[client] > 0)
			{
				GiveWeapon(client, "weapon_defibrillator");
				//ClientCommand(client, "slot4");
			}
			else if(Incendiary[client] > 0)
			{
				GiveWeapon(client, "weapon_upgradepack_incendiary");
				//ClientCommand(client, "slot4");
			}
			else if(Explosives[client] > 0)
			{
				GiveWeapon(client, "weapon_upgradepack_explosive");
				//ClientCommand(client, "slot4");
			}
			else if(FirstAidKits[client] > 0)
			{
				GiveWeapon(client, "weapon_first_aid_kit");
				//ClientCommand(client, "slot4");
			}
		}
		else if (IncendiaryUsed[client])
		{
			IncendiaryUsed[client] = false;
			bWeaponSwitch[client] = true;

			if(Incendiary[client] > 0)
			{
				GiveWeapon(client, "weapon_upgradepack_incendiary");
				//ClientCommand(client, "slot4");
			}
			else if(Explosives[client] > 0)
			{
				GiveWeapon(client, "weapon_upgradepack_explosive");
				//ClientCommand(client, "slot4");
			}
			else if(FirstAidKits[client] > 0)
			{
				GiveWeapon(client, "weapon_first_aid_kit");
				//ClientCommand(client, "slot4");
			}
			else if(Defibs[client] > 0)
			{
				GiveWeapon(client, "weapon_defibrillator");
				//ClientCommand(client, "slot4");
			}
		}
		else if (ExplosiveUsed[client])
		{
			ExplosiveUsed[client] = false;
			bWeaponSwitch[client] = true;

			if(Explosives[client] > 0)
			{
				GiveWeapon(client, "weapon_upgradepack_explosive");
				//ClientCommand(client, "slot4");
			}
			else if(FirstAidKits[client] > 0)
			{
				GiveWeapon(client, "weapon_first_aid_kit");
				//ClientCommand(client, "slot4");
			}
			else if(Defibs[client] > 0)
			{
				GiveWeapon(client, "weapon_defibrillator");
				//ClientCommand(client, "slot4");
			}
			else if(Incendiary[client] > 0)
			{
				GiveWeapon(client, "weapon_upgradepack_incendiary");
				//ClientCommand(client, "slot4");
			}
		}
		else if (PillsUsed[client])
		{
			PillsUsed[client] = false;
			bWeaponSwitch[client] = true;

			if(PainPills[client] > 0)
			{
				GiveWeapon(client, "weapon_pain_pills");
				//ClientCommand(client, "slot5");
			}
			else if(Adrenaline[client] > 0)
			{
				GiveWeapon(client, "weapon_adrenaline");
				//ClientCommand(client, "slot5");
			}
		}
		else if (AdrenUsed[client])
		{
			AdrenUsed[client] = false;
			bWeaponSwitch[client] = true;

			if(Adrenaline[client] > 0)
			{
				GiveWeapon(client, "weapon_adrenaline");
				//ClientCommand(client, "slot5");
			}
			else if(PainPills[client] > 0)
			{
				GiveWeapon(client, "weapon_pain_pills");
				//ClientCommand(client, "slot5");
			}
		}
	}
}

//ITEM USE DETECTION
/*
public void eWeaponFire(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsSurvivor(client) || !IsPlayerAlive(client))
		return;

	char item[10];
	GetEventString(event, "weapon", item, sizeof(item));

	if(item[0] != 'm' && item[0] != 'p' && item[0] != 'v')
		return;

	switch(item[0])
	{
		case 'm':
		{
			if(StrEqual(item, "molotov"))
				MolotovUsed[client] = true;
		}

		case 'p':
		{
			if(StrEqual(item, "pipe_bomb"))
				PipeBombUsed[client] = true;
		}

		case 'v':
		{
			if(StrEqual(item, "vomitjar"))
				VomitjarUsed[client] = true;
		}
	}
}
*/

public void ePackUsed(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(!IsValidClient(client))
		return;

	char sWeapon[32];
	GetEntityClassname(GetEventInt(event, "upgradeid"), sWeapon, sizeof(sWeapon));

	if (StrEqual(sWeapon, "upgrade_ammo_incendiary"))
		IncendiaryUsed[client] = true;
	else if (StrEqual(sWeapon, "upgrade_ammo_explosive"))
		ExplosiveUsed[client] = true;
}

public void eDefibUsed(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(!IsValidClient(client))
		return;

	DefibUsed[client] = true;
}

public void eMedkitUsed(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(!IsValidClient(client))
		return;

	MedkitUsed[client] = true;
}

public void ePillsUsed(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(!IsValidClient(client))
		return;

	PillsUsed[client] = true;
}

public void eAdrenalineUsed(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(!IsValidClient(client))
		return;

	AdrenUsed[client] = true;
}
//ITEM USE DETECTION

public void ePlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(!IsValidClient(client) || GetClientTeam(client) != 2)
		return;

	float victim[3];
	victim[0] = GetEventFloat(event, "victim_x");
	victim[1] = GetEventFloat(event, "victim_y");
	victim[2] = GetEventFloat(event, "victim_z");

	if(GetClientTeam(client) == 2 && GetConVarInt(DeathDrop) == 1)
	{
		SpawnItem(victim, "weapon_molotov", Molotovs[client]);
		SpawnItem(victim, "weapon_pipe_bomb", PipeBombs[client]);
		SpawnItem(victim, "weapon_vomitjar", Vomitjars[client]);
		SpawnItem(victim, "weapon_first_aid_kit", FirstAidKits[client]);
		SpawnItem(victim, "weapon_defibrillator", Defibs[client]);
		SpawnItem(victim, "weapon_upgradepack_incendiary", Incendiary[client]);
		SpawnItem(victim, "weapon_upgradepack_explosive", Explosives[client]);
		SpawnItem(victim, "weapon_pain_pills", PainPills[client]);
		SpawnItem(victim, "weapon_adrenaline", Adrenaline[client]);
	}

	ResetBackpack(client);

	if(GetConVarInt(ShowBackpack) == 1)
	{
		if(IsValidEntRef(BackpackIndex[client]))
		{
			AcceptEntityInput(BackpackIndex[client], "kill");
			BackpackIndex[client] = -1;
		}

		CreateEntity(victim);
	}
}

stock void CreateEntity(const float origin[3])
{
	//int entity = CreateEntityByName("prop_dynamic_ornament");
	//int entity = CreateEntityByName("prop_dynamic_override");
	int entity = CreateEntityByName("prop_physics_override");

	if(entity < 0)
		return;

	DispatchKeyValue(entity, "model", "models/props_collectables/backpack.mdl");

	DispatchKeyValue(entity, "spawnflags", "1");
	DispatchKeyValue(entity, "Solid", "0"); //6 = SOLID
	DispatchKeyValue(entity, "rendermode", "3");
	DispatchKeyValue(entity, "disableshadows", "1");

	SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
	SetEntityRenderColor(entity, 0, 0, 0, 255);

	DispatchSpawn(entity);
	ActivateEntity(entity);
	AcceptEntityInput(entity, "TurnOn");

	//SetEntPropFloat(entity, Prop_Send,"m_flModelScale", 2.0);
	//SetEntProp(entity, Prop_Data, "m_CollisionGroup", 0); //FIXES MODEL INTERFERENCE WITH USE

	TeleportEntity(entity, origin, NULL_VECTOR, NULL_VECTOR);

	//Format(sGlowColour[entity], sizeof(sGlowColour[]), "0 0 255");
	//AddGlow(entity, 3, 9999, true);

	AcceptEntityInput(entity, "BecomeRagdoll");

	//SetEntityMoveType(entity, 6);

	//PrintToChatAll("Entity Created");
}

//MEDSMUNCH FIX
public void eReviveSuccessPre(Handle event, const char[] name, bool dontBroadcast)
{
	int recipient = GetClientOfUserId(GetEventInt(event, "subject"));

	if(!IsValidClient(recipient) || GetClientTeam(recipient) != 2)
		return;

	int slot4 = GetPlayerWeaponSlot(recipient, 4);

	if(slot4 == -1)
		return;

	GetEntityClassname(slot4, MedsMunch[recipient], sizeof(MedsMunch[]));
}

public void eReviveSuccess(Handle event, const char[] name, bool dontBroadcast)
{
	int recipient = GetClientOfUserId(GetEventInt(event, "subject"));

	if(!IsValidClient(recipient) || GetClientTeam(recipient) != 2)
		return;

	CreateTimer(0.5, GivePills, recipient, TIMER_FLAG_NO_MAPCHANGE);
}

public Action GivePills(Handle timer, any client)
{
	if(!IsValidClient(client) || GetClientTeam(client) != 2)
		return Plugin_Continue;

	int slot4 = GetPlayerWeaponSlot(client, 4);

	if(slot4 == -1)
	{
		if(StrContains(MedsMunch[client], "pain_pills") > -1)
		{
			PainPills[client] -= 1;
			MedsMunch[client][0] = '\0';

			if(PainPills[client] > 0)
			{
				Backpack4[client] = 1;
				GiveWeapon(client, "weapon_pain_pills");
			}
			else if(Adrenaline[client] > 0)
			{
				Backpack4[client] = 2;
				GiveWeapon(client, "weapon_adrenaline");
			}
		}
		else if(StrContains(MedsMunch[client], "adrenaline") > -1)
		{
			Adrenaline[client] -= 1;
			MedsMunch[client][0] = '\0';

			if(Adrenaline[client] > 0)
			{
				Backpack4[client] = 2;
				GiveWeapon(client, "weapon_adrenaline");
			}
			else if(PainPills[client] > 0)
			{
				Backpack4[client] = 1;
				GiveWeapon(client, "weapon_pain_pills");
			}
		}
	}

	return Plugin_Continue;
}
//MEDSMUNCH FIX

//PILLS PASS QUANTITY FIX
public void eGiveWeapon(Handle event, const char[] name, bool dontBroadcast)
{
	int receiver = GetClientOfUserId(GetEventInt(event, "userid"));

	char item[32];
	GetEventString(event, "weapon", item, sizeof(item));

	if(StrEqual(item, "23")) //ADRENALINE ID
		Adrenaline[receiver] += 1;
	else if(StrEqual(item, "15")) //PILLS ID
		PainPills[receiver] += 1;
}
//PILLS PASS QUANTITY FIX

public void eFinaleWin(Handle event, const char[] name, bool dontBroadcast)
{
	ResetBackpack(0);
}

public void eMissionLost(Handle event, const char[] name, bool dontBroadcast)
{
	for(int i = 1; i <= MaxClients; i++)
		LoadBackpack(i);
}

void ResetBackpack(int client = 0)
{
	/*0 = ALL CLIENTS*/

	int mols = GetConVarInt(FindConVar("l4d_backpack_start_mols"));
	int pipes = GetConVarInt(FindConVar("l4d_backpack_start_pipes"));
	int biles = GetConVarInt(FindConVar("l4d_backpack_start_biles"));
	int kits = GetConVarInt(FindConVar("l4d_backpack_start_kits"));
	int defibs = GetConVarInt(FindConVar("l4d_backpack_start_defibs"));
	int firepacks = GetConVarInt(FindConVar("l4d_backpack_start_firepacks"));
	int explodepacks = GetConVarInt(FindConVar("l4d_backpack_start_explodepacks"));
	int pills = GetConVarInt(FindConVar("l4d_backpack_start_pills"));
	int adrens = GetConVarInt(FindConVar("l4d_backpack_start_adrens"));

	if(client != 0)
	{
		Molotovs[client] = mols;
		PipeBombs[client] = pipes;
		Vomitjars[client] = biles;
		FirstAidKits[client] = kits;
		Defibs[client] = defibs;
		Incendiary[client] = firepacks;
		Explosives[client] = explodepacks;
		PainPills[client] = pills;
		Adrenaline[client] = adrens;

		Backpack2[client] = 0;
		Backpack3[client] = 0;
		Backpack4[client] = 0;

		InHeal[client] = 0.0;
		InRevive[client] = 0.0;
		bThirdPerson[client] = false;
		bPickedUp[client] = false;

		PipeBombUsed[client] = false;
		MolotovUsed[client] = false;
		VomitjarUsed[client] = false;
		MedkitUsed[client] = false;
		DefibUsed[client] = false;
		IncendiaryUsed[client] = false;
		ExplosiveUsed[client] = false;
		PillsUsed[client] = false;
		AdrenUsed[client] = false;
		
		return;
	}

	for(int i = 0; i <= MaxClients; i++)
	{
		Molotovs[i] = mols;
		PipeBombs[i] = pipes;
		Vomitjars[i] = biles;
		FirstAidKits[i] = kits;
		Defibs[i] = defibs;
		Incendiary[i] = firepacks;
		Explosives[i] = explodepacks;
		PainPills[i] = pills;
		Adrenaline[i] = adrens;

		Backpack2[i] = 0;
		Backpack3[i] = 0;
		Backpack4[i] = 0;

		InHeal[i] = 0.0;
		InRevive[i] = 0.0;
		bThirdPerson[i] = false;
		bPickedUp[i] = false;

		PipeBombUsed[i] = false;
		MolotovUsed[i] = false;
		VomitjarUsed[i] = false;
		MedkitUsed[i] = false;
		DefibUsed[i] = false;
		IncendiaryUsed[i] = false;
		ExplosiveUsed[i] = false;
		PillsUsed[i] = false;
		AdrenUsed[i] = false;
	}
}

void StartBackpack(int client)
{
	Molotovs[client] += GetConVarInt(start_molotovs);
	PipeBombs[client] += GetConVarInt(start_pipebombs);
	Vomitjars[client] += GetConVarInt(start_vomitjars);
	FirstAidKits[client] += GetConVarInt(start_kits);
	Defibs[client] += GetConVarInt(start_defibs);
	Incendiary[client] += GetConVarInt(start_incendiary);
	Explosives[client] += GetConVarInt(start_explosive);
	PainPills[client] += GetConVarInt(start_pills);
	Adrenaline[client] += GetConVarInt(start_adrenalines);
}

void SaveBackpack(int client)
{
	Storage[client][0] = Molotovs[client];
	Storage[client][1] = PipeBombs[client];
	Storage[client][2] = Vomitjars[client];
	Storage[client][3] = FirstAidKits[client];
	Storage[client][4] = Defibs[client];
	Storage[client][5] = Incendiary[client];
	Storage[client][6] = Explosives[client];
	Storage[client][7] = PainPills[client];
	Storage[client][8] = Adrenaline[client];
}

void LoadBackpack(int client)
{
	Molotovs[client] = Storage[client][0];
	PipeBombs[client] = Storage[client][1];
	Vomitjars[client] = Storage[client][2];
	FirstAidKits[client] = Storage[client][3];
	Defibs[client] = Storage[client][4];
	Incendiary[client] = Storage[client][5];
	Explosives[client] = Storage[client][6];
	PainPills[client] = Storage[client][7];
	Adrenaline[client] = Storage[client][8];
}

//========================[ QUICKSWITCH ]========================//

public Action WeaponSwitch(int client, int weapon)
{
	if(IsValidClient(client) && GetClientTeam(client) == 2)
	{
		if(IsValidEntity(weapon))
		{
			char sWeapon[32];
			GetEntityClassname(weapon, sWeapon, sizeof(sWeapon));

			int slot = DetectSlot(sWeapon);

			LastSlot[client] = slot;
			LastWeapon[client] = weapon;
		}
	}
}

public Action WeaponCanUse(int client, int weapon)
{
	if(IsValidClient(client) && GetClientTeam(client) == 2)
	{
		if(IsValidEntity(weapon))
		{
			char sWeapon[32];
			GetEntityClassname(weapon, sWeapon, sizeof(sWeapon));

			int slot = DetectSlot(sWeapon);

			//LastSlot[client] = slot;
			//LastWeapon[client] = weapon;

			BackpackQuantityHint(client, slot, sWeapon);
		}
	}
}

stock void LoadUnloadProgressBar(int client, float EngTime)
{
	if(IsValidClient(client))
	{
		SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
		SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", EngTime);
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (IsValidClient(client) && GetClientTeam(client) == 2)
	{
//===== QUICKSWITCH =====//
		char sWeapon[32];

		if(IsValidEntity(weapon))
			GetEntityClassname(weapon, sWeapon, sizeof(sWeapon));

		int aWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

		if(!IsValidEntity(aWeapon))
			return Plugin_Continue;

		//GetEntityClassname(aWeapon, sWeapon, sizeof(sWeapon));
		int slot = DetectSlot(sWeapon);

		if(slot == 2 || slot == 3 || slot == 4)
		{
			if(GetConVarInt(SwitchMode) == 1) //SingleTap
			{
				if(LastSlot[client] != slot)
				{
					BackpackQuantityHint(client, slot, sWeapon);
					LastSlot[client] = slot;
					return Plugin_Continue;
				}
			}
			else if(GetConVarInt(SwitchMode) == 2) //DoubleTap
			{
				if (LastWeapon[client] != weapon)
				{
					LastWeapon[client] = weapon;
					return Plugin_Continue;
				}
			}

			LastSlot[client] = slot;
			LastWeapon[client] = weapon;
			ChangeWeapon(client, slot, sWeapon);
		}

//===== QUICKDROP =====//
		float Time = GetEngineTime();

		if (buttons == 8192 && Reloads[client]++ >= 2)
		{
			Reloads[client] = 0;

			if (Time > LastDrop[client])
			{
				LastDrop[client] = Time + 0.75;

				if (IsValidEntity(aWeapon))
				{
					GetEntityClassname(aWeapon, sWeapon, sizeof(sWeapon));

					slot = DetectSlot(sWeapon);

					if(slot == 2 || slot == 3 || slot == 4)
					{
						char sDrop[32];
						GetEntityClassname(aWeapon, sDrop, sizeof(sDrop));

						RemovePlayerItem(client, aWeapon);
						AcceptEntityInput(aWeapon, "kill");
						DropWeapon(client, sDrop);
						RequestFrame(NextFrame, client);

						LastSlot[client] = -1;
						LastWeapon[client] = -1;
					}

					return Plugin_Continue;
				}
			}
		}
		else if (buttons != 8192)
		{
			Reloads[client] = 0;
			LastDrop[client] = Time + 0.75;
		}
	}

	return Plugin_Continue;
}

int DetectSlot(char[] sClassName)
{
    for (int i = 0; i < sizeof(Slot0Class); i++)
	{
        if (StrContains(sClassName, Slot0Class[i]) > -1)
            return 0;
    }

    for (int i = 0; i < sizeof(Slot1Class); i++)
	{
        if (StrContains(sClassName, Slot1Class[i]) > -1)
            return 1;
    }

    for (int i = 0; i < sizeof(Slot2Class); i++)
	{
        if (StrContains(sClassName, Slot2Class[i]) > -1)
            return 2;
    }

    for (int i = 0; i < sizeof(Slot3Class); i++)
	{
        if (StrContains(sClassName, Slot3Class[i]) > -1)
            return 3;
    }

    for (int i = 0; i < sizeof(Slot4Class); i++)
	{
        if (StrContains(sClassName, Slot4Class[i]) > -1)
            return 4;
    }

    return -1;
}

void ChangeWeapon(int client, int slot = -1, char sClassName[32])
{
	if(slot == 0 || slot == 1)
		return;

	switch(slot)
	{
		case 0:
		{
			
		}
		case 1:
		{
			
		}
        case 2:
		{
			if (StrContains(sClassName, "molotov") > -1)
			{
				if(Molotovs[client] > 0 && PipeBombs[client] < 1 && Vomitjars[client] < 1)
					return;

				RemoveWeapon(client, slot);

				if(PipeBombs[client] > 0)
					GiveWeapon(client, "weapon_pipe_bomb");
				else if(Vomitjars[client] > 0)
					GiveWeapon(client, "weapon_vomitjar");
				else
					GiveWeapon(client, "weapon_molotov");
			}
			else if (StrContains(sClassName, "pipe_bomb") > -1)
			{
				if(PipeBombs[client] > 0 && Vomitjars[client] < 1 && Molotovs[client] < 1)
					return;

				RemoveWeapon(client, slot);

				if(Vomitjars[client] > 0)
					GiveWeapon(client, "weapon_vomitjar");
				else if(Molotovs[client] > 0)
					GiveWeapon(client, "weapon_molotov");
				else
					GiveWeapon(client, "weapon_pipe_bomb");
			}
			else if (StrContains(sClassName, "vomitjar") > -1)
			{
				if(Vomitjars[client] > 0 && Molotovs[client] < 1 && PipeBombs[client] < 1)
					return;

				RemoveWeapon(client, slot);

				if(Molotovs[client] > 0)
					GiveWeapon(client, "weapon_molotov");
				else if(PipeBombs[client] > 0)
					GiveWeapon(client, "weapon_pipe_bomb");
				else
					GiveWeapon(client, "weapon_vomitjar");
			}
		}
        case 3:
		{
			if (StrContains(sClassName, "first_aid_kit") > -1)
			{
				if(FirstAidKits[client] > 0 && Defibs[client] < 1 && Incendiary[client] < 1 && Explosives[client] < 1)
					return;

				RemoveWeapon(client, slot);

				if(Defibs[client] > 0)
					GiveWeapon(client, "weapon_defibrillator");
				else if(Incendiary[client] > 0)
					GiveWeapon(client, "weapon_upgradepack_incendiary");
				else if(Explosives[client] > 0)
					GiveWeapon(client, "weapon_upgradepack_explosive");
				else
					GiveWeapon(client, "weapon_first_aid_kit");
			}
			else if (StrContains(sClassName, "defibrillator") > -1)
			{
				if(Defibs[client] > 0 && Incendiary[client] < 1 && Explosives[client] < 1 && FirstAidKits[client] < 1)
					return;

				RemoveWeapon(client, slot);

				if(Incendiary[client] > 0)
					GiveWeapon(client, "weapon_upgradepack_incendiary");
				else if(Explosives[client] > 0)
					GiveWeapon(client, "weapon_upgradepack_explosive");
				else if(FirstAidKits[client] > 0)
					GiveWeapon(client, "weapon_first_aid_kit");
				else
					GiveWeapon(client, "weapon_defibrillator");
			}
			else if (StrContains(sClassName, "upgradepack_incendiary") > -1)
			{
				if(Incendiary[client] > 0 && Explosives[client] < 1 && FirstAidKits[client] < 1 && Defibs[client] < 1)
					return;

				RemoveWeapon(client, slot);

				if(Explosives[client] > 0)
					GiveWeapon(client, "weapon_upgradepack_explosive");
				else if(FirstAidKits[client] > 0)
					GiveWeapon(client, "weapon_first_aid_kit");
				else if(Defibs[client] > 0)
					GiveWeapon(client, "weapon_defibrillator");
				else
					GiveWeapon(client, "weapon_upgradepack_incendiary");
			}
			else if (StrContains(sClassName, "upgradepack_explosive") > -1)
			{
				if(Explosives[client] > 0 && FirstAidKits[client] < 1 && Defibs[client] < 1 && Incendiary[client] < 1)
					return;

				RemoveWeapon(client, slot);

				if(FirstAidKits[client] > 0)
					GiveWeapon(client, "weapon_first_aid_kit");
				else if(Defibs[client] > 0)
					GiveWeapon(client, "weapon_defibrillator");
				else if(Incendiary[client] > 0)
					GiveWeapon(client, "weapon_upgradepack_incendiary");
				else
					GiveWeapon(client, "weapon_upgradepack_explosive");
			}
        }
        case 4:
		{
			if (StrContains(sClassName, "pain_pills") > -1)
			{
				if(PainPills[client] > 0 && Adrenaline[client] < 1)
					return;

				RemoveWeapon(client, slot);

				if(Adrenaline[client] > 0)
					GiveWeapon(client, "weapon_adrenaline");
				else
					GiveWeapon(client, "weapon_pain_pills");
			}
			else if (StrContains(sClassName, "adrenaline") > -1)
			{
				if(Adrenaline[client] > 0 && PainPills[client] < 1)
					return;

				RemoveWeapon(client, slot);

				if(PainPills[client] > 0)
					GiveWeapon(client, "weapon_pain_pills");
				else
					GiveWeapon(client, "weapon_adrenaline");
			}
        }
    }
}
//========================[ QUICKSWITCH ]========================//

//-----[ADMIN BACKPACK MENU]-----//
public void ShowAdminBackpack(int client)
{
	char line[100];
	panel[client] = CreatePanel();

	SetPanelTitle(panel[client], "-----[ ADMIN BACKPACK ]-----");

	int count = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && GetClientTeam(i) != 3)
		{
			Format(line, sizeof(line), "%N", i);
			DrawPanelItem(panel[client], line);

			count++;
			PlayerLine[i] = count;
		}
	}

	//DrawPanelItem(panel[client], "Exit");

	SendPanelToClient(panel[client], client, AdminBackpack, 60);
	CloseHandle(panel[client]);
}
			
public int AdminBackpack(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 1:
			{
				ShowAdminPack(param1, param2);
			}
			case 2:
			{
				ShowAdminPack(param1, param2);
			}
			case 3:
			{
				ShowAdminPack(param1, param2);
			}
			case 4:
			{
				ShowAdminPack(param1, param2);
			}
			case 5:
			{
				ShowAdminPack(param1, param2);
			}
			case 6:
			{
				ShowAdminPack(param1, param2);
			}
			case 7:
			{
				ShowAdminPack(param1, param2);
			}
			case 8:
			{
				ShowAdminPack(param1, param2);
			}
			case 9:
			{
				ShowAdminPack(param1, param2);
			}
			case 0:
			{
				ShowAdminPack(param1, param2);
			}
		}
	}
	else if (action == MenuAction_Cancel)
	{
		//PrintToServer("Client %d's menu was cancelled.  Reason: %d", param1, param2);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

public Action ShowAdminPack(int client, int iLine)
{
	char line[100];
	panel[client] = CreatePanel();

	SetPanelTitle(panel[client], " ");

	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && GetClientTeam(i) != 3)
		{
			if(PlayerLine[i] != iLine)
				continue;

			Format(line, sizeof(line), "-----[ %N ]-----", i);
			DrawPanelItem(panel[client], line);

			Format(line, sizeof(line), "[ %d/2 ] MOLOTOVS", Molotovs[i]);
			if(Backpack2[i] == 1)
				StrCat(line, sizeof(line), "     <");
			DrawPanelItem(panel[client], line);

			Format(line, sizeof(line), "[ %d/2 ] PIPEBOMBS", PipeBombs[i]);
			if(Backpack2[i] == 2)
				StrCat(line, sizeof(line), "     <");
			DrawPanelItem(panel[client], line);

			Format(line, sizeof(line), "[ %d/2 ] VOMITJARS", Vomitjars[i]);
			if(Backpack2[i] == 3)
				StrCat(line, sizeof(line), "     <");
			DrawPanelItem(panel[client], line);

			Format(line, sizeof(line), "[ %d/2 ] MEDKITS", FirstAidKits[i]);
			if(Backpack3[i] == 1)
				StrCat(line, sizeof(line), "     <");
			DrawPanelItem(panel[client], line);

			Format(line, sizeof(line), "[ %d/2 ] DEFIBS", Defibs[i]);
			if(Backpack3[i] == 2)
				StrCat(line, sizeof(line), "     <");
			DrawPanelItem(panel[client], line);

			Format(line, sizeof(line), "[ %d/2 ] INCENDIARY", Incendiary[i]);
			if(Backpack3[i] == 3)
				StrCat(line, sizeof(line), "     <");
			DrawPanelItem(panel[client], line);

			Format(line, sizeof(line), "[ %d/2 ] EXPLOSIVE", Explosives[i]);
			if(Backpack3[i] == 4)
				StrCat(line, sizeof(line), "     <");
			DrawPanelItem(panel[client], line);

			Format(line, sizeof(line), "[ %d/2 ] PILLS", PainPills[i]);
			if(Backpack4[i] == 1)
				StrCat(line, sizeof(line), "     <");
			DrawPanelItem(panel[client], line);

			Format(line, sizeof(line), "[ %d/2 ] ADRENALINE", Adrenaline[i]);
			if(Backpack4[i] == 2)
				StrCat(line, sizeof(line), "     <");
			DrawPanelItem(panel[client], line);
		}
	}

	//DrawPanelItem(panel[client], "Exit");

	SendPanelToClient(panel[client], client, AdminPack, 60);
	CloseHandle(panel[client]);
}

public int AdminPack(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 1:
			{

			}
			case 2:
			{

			}
			case 3:
			{

			}
			case 4:
			{

			}
			case 5:
			{

			}
			case 6:
			{

			}
			case 7:
			{

			}
			case 8:
			{

			}
			case 9:
			{

			}
			case 0:
			{

			}
		}
	}
	else if (action == MenuAction_Cancel)
	{
		//PrintToServer("Client %d's menu was cancelled.  Reason: %d", param1, param2);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

//=======================[ BACKPACK MENU ]=======================//
public Action BackPackToggle(int client, int arg)
{
	if(!IsValidClient(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
		return;

	BPToggle[client]=!BPToggle[client];

	if(BPToggle[client])
		showpackHUD(client);
	else
		showpackHUDTimer(client);
}

public Action showpackHUD(int client)
{
	char line[100];
	panel[client] = CreatePanel();

	SetPanelTitle(panel[client], "-----[ BACKPACK ]-----");

	Format(line, sizeof(line), "[ %d/2 ] MOLOTOVS", Molotovs[client]);
	if(Backpack2[client] == 1)
		StrCat(line, sizeof(line), "     <");
	DrawPanelItem(panel[client], line);

	Format(line, sizeof(line), "[ %d/2 ] PIPEBOMBS", PipeBombs[client]);
	if(Backpack2[client] == 2)
		StrCat(line, sizeof(line), "     <");
	DrawPanelItem(panel[client], line);

	Format(line, sizeof(line), "[ %d/2 ] VOMITJARS", Vomitjars[client]);
	if(Backpack2[client] == 3)
		StrCat(line, sizeof(line), "     <");
	DrawPanelItem(panel[client], line);

	Format(line, sizeof(line), "[ %d/2 ] MEDKITS", FirstAidKits[client]);
	if(Backpack3[client] == 1)
		StrCat(line, sizeof(line), "     <");
	DrawPanelItem(panel[client], line);

	Format(line, sizeof(line), "[ %d/2 ] DEFIBS", Defibs[client]);
	if(Backpack3[client] == 2)
		StrCat(line, sizeof(line), "     <");
	DrawPanelItem(panel[client], line);

	Format(line, sizeof(line), "[ %d/2 ] INCENDIARY", Incendiary[client]);
	if(Backpack3[client] == 3)
		StrCat(line, sizeof(line), "     <");
	DrawPanelItem(panel[client], line);

	Format(line, sizeof(line), "[ %d/2 ] EXPLOSIVE", Explosives[client]);
	if(Backpack3[client] == 4)
		StrCat(line, sizeof(line), "     <");
	DrawPanelItem(panel[client], line);

	Format(line, sizeof(line), "[ %d/2 ] PILLS", PainPills[client]);
	if(Backpack4[client] == 1)
		StrCat(line, sizeof(line), "     <");
	DrawPanelItem(panel[client], line);

	Format(line, sizeof(line), "[ %d/2 ] ADRENALINE", Adrenaline[client]);
	if(Backpack4[client] == 2)
		StrCat(line, sizeof(line), "     <");
	DrawPanelItem(panel[client], line);

	DrawPanelItem(panel[client], "Exit");

	SendPanelToClient(panel[client], client, Panel_Backpack, 30);
	CloseHandle(panel[client]);

	return;
}

public Action showpackHUDTimer(int client)
{
	char line[100];
	panel[client] = CreatePanel();

	SetPanelTitle(panel[client], "-----[ BACKPACK ]-----");
	//DrawPanelText(panel[client], "---------------------");

	Format(line, sizeof(line), "[ %d/2 ] MOLOTOVS", Molotovs[client]);
	if(Backpack2[client] == 1)
		StrCat(line, sizeof(line), "     <");
	DrawPanelItem(panel[client], line);

	Format(line, sizeof(line), "[ %d/2 ] PIPEBOMBS", PipeBombs[client]);
	if(Backpack2[client] == 2)
		StrCat(line, sizeof(line), "     <");
	DrawPanelItem(panel[client], line);

	Format(line, sizeof(line), "[ %d/2 ] VOMITJARS", Vomitjars[client]);
	if(Backpack2[client] == 3)
		StrCat(line, sizeof(line), "     <");
	DrawPanelItem(panel[client], line);

	Format(line, sizeof(line), "[ %d/2 ] MEDKITS", FirstAidKits[client]);
	if(Backpack3[client] == 1)
		StrCat(line, sizeof(line), "     <");
	DrawPanelItem(panel[client], line);

	Format(line, sizeof(line), "[ %d/2 ] DEFIBS", Defibs[client]);
	if(Backpack3[client] == 2)
		StrCat(line, sizeof(line), "     <");
	DrawPanelItem(panel[client], line);

	Format(line, sizeof(line), "[ %d/2 ] INCENDIARY", Incendiary[client]);
	if(Backpack3[client] == 3)
		StrCat(line, sizeof(line), "     <");
	DrawPanelItem(panel[client], line);

	Format(line, sizeof(line), "[ %d/2 ] EXPLOSIVE", Explosives[client]);
	if(Backpack3[client] == 4)
		StrCat(line, sizeof(line), "     <");
	DrawPanelItem(panel[client], line);

	Format(line, sizeof(line), "[ %d/2 ] PILLS", PainPills[client]);
	if(Backpack4[client] == 1)
		StrCat(line, sizeof(line), "     <");
	DrawPanelItem(panel[client], line);

	Format(line, sizeof(line), "[ %d/2 ] ADRENALINE", Adrenaline[client]);
	if(Backpack4[client] == 2)
		StrCat(line, sizeof(line), "     <");
	DrawPanelItem(panel[client], line);

	DrawPanelItem(panel[client], "Exit");

	SendPanelToClient(panel[client], client, Panel_Backpack, 1);
	CloseHandle(panel[client]);

	return;
}

public Action PackMenu(int client, int arg)
{
	int iSlot;
	char sSlot[32];

	if(IsValidClient(client))
	{
		if(GetClientTeam(client) == 2)
		{
			if(IsPlayerAlive(client))
			{
				GetCmdArg(1, sSlot, sizeof(sSlot));
				iSlot = StringToInt(sSlot);

				switch(iSlot)
				{
					case 1, 2, 3:
					{
						Backpack2[client] = iSlot;

						switch (iSlot)
						{
							case 1:
							{

							}
							case 2:
							{

							}
							case 3:
							{

							}
						}
					}

					case 4, 5, 6, 7:
					{
						Backpack3[client] = iSlot - 3;

						switch (iSlot - 3)
						{
							case 1:
							{

							}
							case 2:
							{

							}
							case 3:
							{

							}
							case 4:
							{

							}
						}
					}
					case 8, 9:
					{
						Backpack4[client] = iSlot - 7;

						switch (iSlot - 7)
						{
							case 1:
							{

							}
							case 2:
							{

							}
						}
					}
					default:
						showpackHUD(client);
				}
			}
			else
				PrintToChat(client, "Only Alive Players Can Access Backpack");
		}
		else
			PrintToChat(client, "Only Survivors Can Access Backpack");
	}

	return Plugin_Handled;
}

public int Panel_Backpack(Handle menu, MenuAction action, int param1, int param2)
{
	if (!(action == MenuAction_Select))
		return;

	int entity;
	char sClassname[32];

	switch (param2)
	{
		case 1, 2, 3:
		{
			entity = GetPlayerWeaponSlot(param1, 2);

			if(entity > 0)
			{
				GetEntityClassname(entity, sClassname, sizeof(sClassname));

				if(StrContains(sClassname, "molotov") > -1 || StrContains(sClassname, "pipe_bomb") > -1 ||
					StrContains(sClassname, "vomitjar") > -1)
				{
					//FakeClientCommand(param1, "use %s", sClassname);
					RemovePlayerItem(param1, entity);
					AcceptEntityInput(entity, "kill");
				}
			}

			Backpack2[param1] = param2;

			switch (param2)
			{
				case 1:
				{
					if(Molotovs[param1] < 1)
					{
						if(PipeBombs[param1] > 0)
						{
							Backpack2[param1] = 2;
							GiveWeapon(param1, "weapon_pipe_bomb");
						}
						else if(Vomitjars[param1] > 0)
						{
							Backpack2[param1] = 3;
							GiveWeapon(param1, "weapon_vomitjar");
						}
					}

					if(Molotovs[param1] > 0)
					{
						Backpack2[param1] = 1;
						GiveWeapon(param1, "weapon_molotov");
					}
				}
				case 2:
				{
					if(PipeBombs[param1] < 1)
					{
						if(Vomitjars[param1] > 0)
						{
							Backpack2[param1] = 3;
							GiveWeapon(param1, "weapon_vomitjar");
						}
						else if(Molotovs[param1] > 0)
						{
							Backpack2[param1] = 1;
							GiveWeapon(param1, "weapon_molotov");
						}
					}

					if(PipeBombs[param1] > 0)
					{
						Backpack2[param1] = 2;
						GiveWeapon(param1, "weapon_pipe_bomb");
					}
				}
				case 3:
				{
					if(Vomitjars[param1] < 1)
					{
						if(Molotovs[param1] > 0)
						{
							Backpack2[param1] = 1;
							GiveWeapon(param1, "weapon_molotov");
						}
						else if(PipeBombs[param1] > 0)
						{
							Backpack2[param1] = 2;
							GiveWeapon(param1, "weapon_pipe_bomb");
						}
					}

					if(Vomitjars[param1] > 0)
					{
						Backpack2[param1] = 3;
						GiveWeapon(param1, "weapon_vomitjar");
					}
				}
			}
		}
		case 4, 5, 6, 7:
		{
			entity = GetPlayerWeaponSlot(param1, 3);

			if(entity > 0)
			{
				GetEntityClassname(entity, sClassname, sizeof(sClassname));

				if(StrContains(sClassname, "first_aid_kit") > -1 || StrContains(sClassname, "defibrillator") > -1 ||
					StrContains(sClassname, "upgradepack_incendiary") > -1 || StrContains(sClassname, "upgradepack_explosive") > -1)
				{
					//FakeClientCommand(param1, "use %s", sClassname);
					RemovePlayerItem(param1, entity);
					AcceptEntityInput(entity, "kill");
				}
			}

			Backpack3[param1] = param2 - 3;

			switch (param2 - 3)
			{
				case 1:
				{
					if(FirstAidKits[param1] < 1)
					{
						if(Defibs[param1] > 0)
						{
							Backpack3[param1] = 2;
							GiveWeapon(param1, "weapon_defibrillator");
						}
						else if(Incendiary[param1] > 0)
						{
							Backpack3[param1] = 3;
							GiveWeapon(param1, "weapon_upgradepack_incendiary");
						}
						else if(Explosives[param1] > 0)
						{
							Backpack3[param1] = 4;
							GiveWeapon(param1, "weapon_upgradepack_explosive");
						}
					}
					if(FirstAidKits[param1] > 0)
					{
						Backpack3[param1] = 1;
						GiveWeapon(param1, "weapon_first_aid_kit");
					}
				}
				case 2:
				{
					if(Defibs[param1] < 1)
					{
						if(Incendiary[param1] > 0)
						{
							Backpack3[param1] = 3;
							GiveWeapon(param1, "weapon_upgradepack_incendiary");
						}
						else if(Explosives[param1] > 0)
						{
							Backpack3[param1] = 4;
							GiveWeapon(param1, "weapon_upgradepack_explosive");
						}
						else if(FirstAidKits[param1] > 0)
						{
							Backpack3[param1] = 1;
							GiveWeapon(param1, "weapon_first_aid_kit");
						}
					}
					if(Defibs[param1] > 0)
					{
						Backpack3[param1] = 2;
						GiveWeapon(param1, "weapon_defibrillator");
					}
				}
				case 3:
				{
					if(Incendiary[param1] < 1)
					{
						if(Explosives[param1] > 0)
						{
							Backpack3[param1] = 4;
							GiveWeapon(param1, "weapon_upgradepack_explosive");
						}
						else if(FirstAidKits[param1] > 0)
						{
							Backpack3[param1] = 1;
							GiveWeapon(param1, "weapon_first_aid_kit");
						}
						else if(Defibs[param1] > 0)
						{
							Backpack3[param1] = 2;
							GiveWeapon(param1, "weapon_defibrillator");
						}
					}
					if(Incendiary[param1] > 0)
					{
						Backpack3[param1] = 3;
						GiveWeapon(param1, "weapon_upgradepack_incendiary");
					}
				}
				case 4:
				{
					if(Explosives[param1] < 1)
					{
						if(FirstAidKits[param1] > 0)
						{
							Backpack3[param1] = 1;
							GiveWeapon(param1, "weapon_first_aid_kit");
						}
						else if(Defibs[param1] > 0)
						{
							Backpack3[param1] = 2;
							GiveWeapon(param1, "weapon_defibrillator");
						}
						else if(Incendiary[param1] > 0)
						{
							Backpack3[param1] = 3;
							GiveWeapon(param1, "weapon_upgradepack_incendiary");
						}
					}
					if(Explosives[param1] > 0)
					{
						Backpack3[param1] = 4;
						GiveWeapon(param1, "weapon_upgradepack_explosive");
					}
				}
			}
		}
		case 8, 9:
		{
			entity = GetPlayerWeaponSlot(param1, 4);

			if(entity > 0)
			{
				GetEntityClassname(entity, sClassname, sizeof(sClassname));

				if(StrContains(sClassname, "pain_pills") > -1 || StrContains(sClassname, "adrenaline") > -1)
				{
					//FakeClientCommand(param1, "use %s", sClassname);
					RemovePlayerItem(param1, entity);
					AcceptEntityInput(entity, "kill");
				}
			}

			Backpack4[param1] = param2 - 7;

			switch (param2 - 7)
			{
				case 1:
				{
					if(PainPills[param1] < 1)
					{
						if(Adrenaline[param1] > 0)
						{
							Backpack4[param1] = 2;
							GiveWeapon(param1, "weapon_adrenaline");
						}
					}
					if(PainPills[param1] > 0)
					{
						Backpack4[param1] = 1;
						GiveWeapon(param1, "weapon_pain_pills");
					}
				}
				case 2:
				{
					if(Adrenaline[param1] < 1)
					{
						if(PainPills[param1] > 0)
						{
							Backpack4[param1] = 1;
							GiveWeapon(param1, "weapon_pain_pills");
						}
					}
					if(Adrenaline[param1] > 0)
					{
						Backpack4[param1] = 2;
						GiveWeapon(param1, "weapon_adrenaline");
					}
				}
			}
		}
	}

	return;
}
/////====================[ BACKPACK MENU ]====================/////

/////====================[ BACKPACK MODEL ]====================/////
public void OnMapStart()
{
	//PrefetchSound(SOUND_PICKUP);
	//PrecacheSound(SOUND_PICKUP, true);

	PrefetchSound(SOUND_NOPICKUP);
	PrecacheSound(SOUND_NOPICKUP, true);

	PrecacheModel("models/props_collectables/backpack.mdl", true);
	//DefibModel = PrecacheModel("models/v_models/v_defibrillator.mdl", true);
}

void SetVector(float target[3], float x, float y, float z)
{
	target[0] = x, target[1] = y, target[2] = z;
}

void CreateBackpack(int client)
{
	if(!IsValidClient(client))
		return;

	if(IsValidEntRef(BackpackIndex[client]))
	{
		AcceptEntityInput(BackpackIndex[client], "kill");
		BackpackIndex[client] = -1;
	}

	int entity = CreateEntityByName("prop_dynamic_ornament");

	if(entity < 0)
		return;

	DispatchKeyValue(entity, "model", "models/props_collectables/backpack.mdl");

	SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
	SetEntityRenderColor(entity, 0, 0, 0, 255);
/*
//RANDOM BACKPACK COLORS
	int Random = GetRandomInt(0, 255);

	char sModel[64];
	GetEntPropString(client, Prop_Data, "m_ModelName", sModel, sizeof(sModel));

	switch(sModel[29])
	{
		case 'b'://nick
			SetEntityRenderColor(entity, Random, Random, Random, 255);
		case 'd'://rochelle
			SetEntityRenderColor(entity, Random, Random, Random, 255);
		case 'c'://coach
			SetEntityRenderColor(entity, Random, Random, Random, 255);
		case 'h'://ellis
			SetEntityRenderColor(entity, Random, Random, Random, 255);
		case 'v'://bill
			SetEntityRenderColor(entity, Random, Random, Random, 255);
		case 'n'://zoey
			SetEntityRenderColor(entity, Random, Random, Random, 255);
		case 'e'://francis
			SetEntityRenderColor(entity, Random, Random, Random, 255);
		case 'a'://louis
			SetEntityRenderColor(entity, Random, Random, Random, 255);
		case 'w'://adawong
			SetEntityRenderColor(entity, Random, Random, Random, 255);
	}
*/
	DispatchSpawn(entity);
	ActivateEntity(entity);
	AcceptEntityInput(entity, "TurnOn");
	
	SetEntPropFloat(entity, Prop_Send,"m_flModelScale", 0.67);

	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", client);

	SetVariantString("medkit");
	//AcceptEntityInput(entity, "SetParentAttachment", entity);
	AcceptEntityInput(entity, "SetParentAttachmentMaintainOffset");

	float Pos[3];
	SetVector(Pos, 4.0, 2.0, 3.3); //SetVector(Pos, In/Out, Up/Down, Left/Right);

	float Ang[3];
	SetVector(Ang, 175.0, 85.0, -75.0);

	TeleportEntity(entity, Pos, Ang, NULL_VECTOR);

	SetEntProp(entity, Prop_Data, "m_CollisionGroup", 0); //FIXES MODEL INTERFERENCE WITH USE

	BackpackIndex[client] = EntIndexToEntRef(entity);
	BackpackOwner[entity] = GetClientUserId(client);

	SDKHook(entity, SDKHook_SetTransmit, SetTransmit);
}

public Action SetTransmit(int entity, int client)
{
	if(IsFakeClient(client))
		return Plugin_Continue;

	if(!IsPlayerAlive(client))
	{
		if(GetEntProp(client, Prop_Send, "m_iObserverMode") == 4)
		{
			if(GetEntPropEnt(client, Prop_Send, "m_hObserverTarget") == GetClientOfUserId(BackpackOwner[entity]))
				return Plugin_Handled;
		}
	}

	static int iEntOwner;
	iEntOwner = GetClientOfUserId(BackpackOwner[entity]);

	if(iEntOwner < 1 || !IsClientInGame(iEntOwner))
		return Plugin_Continue;

	if(GetClientTeam(iEntOwner) == 2)
	{
		if(iEntOwner != client)
			return Plugin_Continue;

		if(!IsSurvivorThirdPerson(client))
			return Plugin_Handled;
	}

	return Plugin_Continue;
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
	if(GetEngineTime() - InHeal[iClient] < 5.0 || GetEngineTime() - InRevive[iClient] < 5.0)
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

public void TP_OnThirdPersonChanged(int client, bool bIsThirdPerson)
{
	bThirdPerson[client] = bIsThirdPerson;
}

static bool IsValidEntRef(int iEntRef)
{
    static int iEntity;
    iEntity = EntRefToEntIndex(iEntRef);
    return (iEntRef && iEntity != INVALID_ENT_REFERENCE && IsValidEntity(iEntity));
}
/////====================[ BACKPACK MODEL ]====================/////



public void SpawnItem(const float origin[3], const char[] item, const int amount)
{
	int entity = -1;

	for(int i = 1; i <= amount; i++)
	{
		entity = CreateEntityByName(item);

		if(entity < 1)
			break;

		if(!DispatchSpawn(entity))
			continue;

		ActivateEntity(entity);
		TeleportEntity(entity, origin, NULL_VECTOR, NULL_VECTOR);

		//DispatchKeyValue(entity, "solid", "6");
		//DispatchKeyValue(entity, "rendermode", "3");
		//DispatchKeyValue(entity, "disableshadows", "1");

		//DispatchSpawn(entity);
	}
}

stock bool GetPlayerEye(int client, float vecTarget[3])
{
	float Origin[3], float Angles[3];
	GetClientEyePosition(client, Origin);
	GetClientEyeAngles(client, Angles);

	int Handle trace = TR_TraceRayFilterEx(Origin, Angles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if (TR_DidHit(trace)) 
	{
		TR_GetEndPosition(vecTarget, trace);
		CloseHandle(trace);
		return true;
	}

	CloseHandle(trace);
	return false;
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask)
{
	return (entity > GetMaxClients() || !entity);
}

void DropWeapon(int client, char[] sClassname)
{
	int entity = CreateEntityByName(sClassname);

	if (!IsValidEntity(entity) || !DispatchSpawn(entity))
		return;

	ActivateEntity(entity);

	SDKUnhook(entity, SDKHook_Use, OnPlayerUse);

//THROW ITEM AT AIM
	float Pos[3];
	float vecAngles[3];
	float vecVelocity[3];

	GetClientEyePosition(client, Pos);
	GetClientEyeAngles(client, vecAngles);
	GetAngleVectors(vecAngles, vecVelocity, NULL_VECTOR, NULL_VECTOR);

	vecVelocity[0] *= 400.0;
	vecVelocity[1] *= 400.0;
	vecVelocity[2] *= 400.0;

	TeleportEntity(entity, Pos, NULL_VECTOR, vecVelocity);
//THROW ITEM AT AIM

	SDKHook(entity, SDKHook_Use, OnPlayerUse);

	if(StrContains(sClassname, "molotov") > -1)
	{
		Molotovs[client] -= 1;
		MolotovUsed[client] = true;
	}
	else if(StrContains(sClassname, "pipe_bomb") > -1)
	{
		PipeBombs[client] -= 1;
		PipeBombUsed[client] = true;
	}
	else if(StrContains(sClassname, "vomitjar") > -1)
	{
		Vomitjars[client] -= 1;
		VomitjarUsed[client] = true;
	}
	else if(StrContains(sClassname, "first_aid_kit") > -1)
	{
		FirstAidKits[client] -= 1;
		MedkitUsed[client] = true;
	}
	else if(StrContains(sClassname, "defibrillator") > -1)
	{
		Defibs[client] -= 1;
		DefibUsed[client] = true;
	}
	else if(StrContains(sClassname, "upgradepack_incendiary") > -1)
	{
		Incendiary[client] -= 1;
		IncendiaryUsed[client] = true;
	}
	else if(StrContains(sClassname, "upgradepack_explosive") > -1)
	{
		Explosives[client] -= 1;
		ExplosiveUsed[client] = true;
	}
	else if(StrContains(sClassname, "pain_pills") > -1)
	{
		PainPills[client] -= 1;
		PillsUsed[client] = true;
	}
	else if(StrContains(sClassname, "adrenaline") > -1)
	{
		Adrenaline[client] -= 1;
		AdrenUsed[client] = true;
	}
}

void BackpackQuantityHint(int client, int slot, char[] item)
{
	if(slot == 2)
	{
		if(StrContains(item, "molotov", false) > -1)
			PrintHintText(client, "[ MOLOTOVS ( %d/2 ) ]", Molotovs[client]);
		if(StrContains(item, "pipe_bomb", false) > -1)
			PrintHintText(client, "[ PIPEBOMBS ( %d/2 ) ]", PipeBombs[client]);
		if(StrContains(item, "vomitjar", false) > -1)
			PrintHintText(client, "[ VOMITJARS ( %d/2 ) ]", Vomitjars[client]);
	}
	else if(slot == 3)
	{
		if(StrContains(item, "first_aid_kit", false) > -1)
			PrintHintText(client, "[ MEDKITS ( %d/2 ) ]", FirstAidKits[client]);
		if(StrContains(item, "defibrillator", false) > -1)
			PrintHintText(client, "[ DEFIBS ( %d/2 ) ]", Defibs[client]);
		if(StrContains(item, "upgradepack_incendiary", false) > -1)
			PrintHintText(client, "[ INCENDIARY ( %d/2 ) ]", Incendiary[client]);
		if(StrContains(item, "upgradepack_explosive", false) > -1)
			PrintHintText(client, "[ EXPLOSIVE ( %d/2 ) ]", Explosives[client]);
	}
	else if(slot == 4)
	{
		if(StrContains(item, "pain_pills", false) > -1)
			PrintHintText(client, "[ PILLS ( %d/2 ) ]", PainPills[client]);
		if(StrContains(item, "adrenaline", false) > -1)
			PrintHintText(client, "[ ADRENALINE ( %d/2 ) ]", Adrenaline[client]);
	}
}

void CheckAnimation(int client, int iSequence)
{
	char sModel[31];
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

void GiveWeapon(int client, char[] sClassname)
{
	int entity = CreateEntityByName(sClassname);

	if (!IsValidEntity(entity) || !DispatchSpawn(entity))
		return;

	ActivateEntity(entity);

	SDKUnhook(entity, SDKHook_Use, OnPlayerUse);

	AcceptEntityInput(entity, "use", client);

	SDKHook(entity, SDKHook_Use, OnPlayerUse);
}

void RemoveWeapon(int client, int slot)
{
	int entity = GetPlayerWeaponSlot(client, slot);

	if(IsValidEntity(entity))
	{
		RemovePlayerItem(client, entity);
		AcceptEntityInput(entity, "kill");
	}
}

/////====================[ STOCKS ]====================/////
stock bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

stock bool IsIncapped(int client)
{
	return (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) > 0);
}

stock bool IsOnGround(int client)
{
	if(GetEntityFlags(client) & FL_ONGROUND)
		return true;
	return false;
}

stock bool IsAdmin(int client)
{
	if (GetUserFlagBits(client) & ADMFLAG_ROOT)
		return true;
	return false;
}