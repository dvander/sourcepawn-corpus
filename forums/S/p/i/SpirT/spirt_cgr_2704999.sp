#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "SpirT"
#define PLUGIN_VERSION "1.1.4"

#define m_flNextSecondaryAttack FindSendPropInfo("CBaseCombatWeapon", "m_flNextSecondaryAttack")

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

bool IsRoundActive;
bool IsCommandBlocked;
bool IsKillBonusEnabled;
bool IsPickupBlocked;
bool IsRoundNoscope = false;
bool ChangedInfiniteAmmoValue = false;
int defaultInfiniteAmmo = 0;
bool AllowKnifeDamage = true;
bool HeadshotOnly = false;

int dropWeapon = 1;

float startInterval = 10.0;

ConVar gInfiniteAmmo, gDropWeapon;

int killBonus;

char roundWeapon[64];

ConVar g_time;

char file[512];

#pragma newdecls required

public Plugin myinfo = 
{
	name = "[SpirT] Custom Game Rounds",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{	
	RegAdminCmd("sm_rounds", Command_Rounds, ADMFLAG_CHAT);
	HookEvent("round_end", RoundEnd);
	HookEvent("round_start", RoundStart);
	HookEvent("player_death", PlayerDeath, EventHookMode_Pre);
	
	BuildPath(Path_SM, file, sizeof(file), "configs/custom_game_rounds.cfg");
	
	g_time = CreateConVar("spirt_cgr_interval", "10.0", "How many seconds after the round start should the command be blocked (0.0 == command is always available).");
	AutoExecConfig(true, "spirt.cgr");
}

public void OnConfigsExecuted() {
	
	gInfiniteAmmo = FindConVar("sv_infinite_ammo");
	if(gInfiniteAmmo != null) {
		defaultInfiniteAmmo = GetConVarInt(gInfiniteAmmo);
	}
	
	gDropWeapon = FindConVar("mp_death_drop_gun");
	
	if(gDropWeapon != null) {
		dropWeapon = GetConVarInt(gDropWeapon);
	}

	startInterval = GetConVarFloat(g_time);
}

public Action Command_Rounds(int client, int args)
{
	if(IsRoundActive)
	{
		ReplyToCommand(client, "[SpirT - CGR] A Custom Game Round is already active. Wait for the next round.");
		return Plugin_Handled;
	}
	
	if(IsCommandBlocked)
	{
		ReplyToCommand(client, "[SpirT - CGR] This command is blocked. Wait a moment.");
		return Plugin_Handled;
	}
	
	ShowRounds().Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public void OnMapStart()
{
	IsRoundActive = false;
	return;
}

Menu ShowRounds()
{
	Menu menu = new Menu(RoundsHandle, MENU_ACTIONS_ALL);
	menu.SetTitle("Choose a Custom Round:");
	
	KeyValues kv = new KeyValues("CGR");
	kv.ImportFromFile(file);
	
	KvGotoFirstSubKey(kv);
	
	do
	{
		char RoundName[64];
		KvGetSectionName(kv, RoundName, sizeof(RoundName));
		
		menu.AddItem(RoundName, RoundName);
	} while (KvGotoNextKey(kv));
	
	delete kv;
	
	return menu;
}

public int RoundsHandle(Menu menu, MenuAction action, int client, int item)
{
	char choice[64];
	menu.GetItem(item, choice, sizeof(choice));
	
	if(action == MenuAction_Select)
	{
		KeyValues kv = new KeyValues("CGR");
		kv.ImportFromFile(file);
		
		KvGotoFirstSubKey(kv);
		
		do
		{
			char RoundName[64];
			KvGetSectionName(kv, RoundName, sizeof(RoundName));
			
			if(StrEqual(choice, RoundName))
			{
				IsRoundActive = true;
				KvJumpToKey(kv, RoundName);
				
				KvGetString(kv, "weapon", roundWeapon, sizeof(roundWeapon));
				
				char hint[64];
				KvGetString(kv, "hint", hint, sizeof(hint));

				char sNoscope[10];
				KvGetString(kv, "noscope", sNoscope, sizeof(sNoscope), "false");
				IsRoundNoscope = StrEqual(sNoscope, "true");

				char sKeepKnife[10];
				KvGetString(kv, "keepknife", sKeepKnife, sizeof(sKeepKnife), "true");
				bool keepKnife = StrEqual(sKeepKnife, "true");
								
				char kvstartHealth[10];
				KvGetString(kv, "start_health", kvstartHealth, sizeof(kvstartHealth), "100");
				int startHealth = StringToInt(kvstartHealth);
				
				char kvkillBonus[10];
				KvGetString(kv, "kill_bonus", kvkillBonus, sizeof(kvkillBonus), "0");
				killBonus = StringToInt(kvkillBonus);
				
				char g_pickupEnabled[3];
				KvGetString(kv, "weapons_pickup", g_pickupEnabled, sizeof(g_pickupEnabled), "1");
				int pickupEnabled = StringToInt(g_pickupEnabled);
				
				char g_blockKnifeDamage[10];
				KvGetString(kv, "knifedamage", g_blockKnifeDamage, sizeof(g_blockKnifeDamage), "false");
				AllowKnifeDamage = StrEqual(g_blockKnifeDamage, "true");
				
				char g_hsOnly[10];
				KvGetString(kv, "hsonly", g_hsOnly, sizeof(g_hsOnly), "false");
				HeadshotOnly = StrEqual(g_hsOnly, "true");
				
				char g_infiniteAmmoValue[10];
				KvGetString(kv, "infiniteammo", g_infiniteAmmoValue, sizeof(g_infiniteAmmoValue), "0");
				int ammo = StringToInt(g_infiniteAmmoValue);
				if(ammo == 1 || ammo == 2) {
					ChangedInfiniteAmmoValue = true;
					SetConVarInt(gInfiniteAmmo, ammo);
				}
				
				SetConVarInt(gDropWeapon, 0);
				
				if(killBonus != 0)
				{
					IsKillBonusEnabled = true;
				}
				
				for (int i = 1; i <= MaxClients; i++)
				{
					if(IsClientConnected(i) && IsClientInGame(i))
					{
						PrintHintText(i, hint);
						DisarmPlayer(i, keepKnife);
						EquipPlayer(i, roundWeapon);
						BlockPlayersWeaponPickup(i, pickupEnabled);
						SetPlayerHealth(i, startHealth);
					}
				}
			}
		} while (KvGotoNextKey(kv));
		
		delete kv;
	}

	return 0;
}

void DisarmPlayer(int client, bool keepKnife = true)
{
	for(int i = 0; i < 5; i++)
	{
		if(i == CS_SLOT_KNIFE && keepKnife) {
			continue;
		}

		int weapon = -1;
		while((weapon = GetPlayerWeaponSlot(client, i)) != -1)
		{
			if(IsValidEntity(weapon))
			{
				RemovePlayerItem(client, weapon);
			}
		}
	}
}

void EquipPlayer(int client, const char[] weapon)
{
	GivePlayerItem(client, weapon);
}

void SetPlayerHealth(int client, int health)
{
	SetEntityHealth(client, health);
	return;
}

void BlockPlayersWeaponPickup(int client, int enabled)
{
	if(enabled != 0)
	{
		return;
	}
	
	IsPickupBlocked = true;
	SDKHook(client, SDKHook_WeaponCanUse, SDKHook_BlockPickup);
}

public Action SDKHook_BlockPickup(int client, int weapon)
{
	if(IsPickupBlocked)
	{
		char weaponName[64];
		if(GetEntityClassname(weapon, weaponName, sizeof(weaponName)))
		{
			if(StrEqual(weaponName, roundWeapon))
			{
				return Plugin_Continue;
			}
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public void OnClientPostAdminCheck(int client)
{
	if (!IsClientInGame(client) || IsFakeClient(client) || client < 1 || client > MaxClients) {
		return;
	}
	
	if(IsPickupBlocked)
	{
		SDKHook(client, SDKHook_WeaponCanUse, SDKHook_BlockPickup);
	}
	else
	{
		IsPickupBlocked = false;
		SDKHook(client, SDKHook_WeaponCanUse, SDKHook_BlockPickup);
	}
	
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_PreThink, PreThink);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom) {
	if(AllowKnifeDamage) {
		return Plugin_Continue;
	}
	if(IsValidEdict(weapon)) {
		if(HeadshotOnly) {
			if(damagetype &= CS_DMG_HEADSHOT) {} else {
				damage = 0.0;
				return Plugin_Changed;
			}
		}
		
		char sWeapon[64];
		GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));
		
		if(StrEqual(sWeapon, "weapon_knife_ct") || StrEqual(sWeapon, "weapon_knife_t") || StrEqual(sWeapon, "weapon_knife") || StrEqual(sWeapon, "weapon_bayonet") || StrEqual(sWeapon, "weapon_knife_flip") || StrEqual(sWeapon, "weapon_knife_gut") || StrEqual(sWeapon, "weapon_knife_karambit") || StrEqual(sWeapon, "weapon_knife_m9_bayonet") || StrEqual(sWeapon, "weapon_knife_tactical") || StrEqual(sWeapon, "weapon_knife_butterfly") || StrEqual(sWeapon, "weapon_falchion") || StrEqual(sWeapon, "weapon_knifegg") || StrEqual(sWeapon, "weapon_knife_survival_bowie")) {
			damage = 0.0;
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}

public Action PreThink(int client) {
	if(!IsRoundActive) {
		return Plugin_Continue;
	}

	if(!IsPlayerAlive(client)) {
		return Plugin_Continue;
	}

	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(!IsValidEdict(weapon)) {
		return Plugin_Continue;
	}

	char item[64];
	GetEdictClassname(weapon, item, sizeof(item));
	if(!IsRoundNoscope || !IsNoscopeWeapon(item)) {
		return Plugin_Continue;
	}

	//Disable Scope
	SetEntDataFloat(weapon, m_flNextSecondaryAttack, GetGameTime() + 9999.9);
	return Plugin_Continue;
}

bool IsNoscopeWeapon(const char[] classname) {
	if(StrEqual(classname, "weapon_awp") || StrEqual(classname, "weapon_aug") || StrEqual(classname, "weapon_gs3sg1") || StrEqual(classname, "weapon_scar20") || StrEqual(classname, "weapon_sg556") || StrEqual(classname, "weapon_ssg08")) {
		return true;
	}

	return false;
}

public Action RoundEnd(Event event, char[] name, bool dontBroadCast)
{
	IsCommandBlocked = true;
	if(IsRoundActive)
	{
		IsRoundActive = false;
		if(IsPickupBlocked)
		{
			IsPickupBlocked = false;
		}
			
		if(IsKillBonusEnabled)
		{
			IsKillBonusEnabled = false;
		}
		
		if(IsPickupBlocked)
		{
			IsPickupBlocked = false;
		}

		if(IsRoundNoscope) {
			IsRoundNoscope = false;
		}
		
		if(!AllowKnifeDamage) {
			AllowKnifeDamage = true;
		}

		if(ChangedInfiniteAmmoValue) {
			ChangedInfiniteAmmoValue = false;
			if(gInfiniteAmmo != null) {
				SetConVarInt(gInfiniteAmmo, defaultInfiniteAmmo);
			}
		}
		
		if(HeadshotOnly) {
			HeadshotOnly = false;
		}
		
		SetConVarInt(gDropWeapon, dropWeapon);
		
		for (int i = 1; i < MaxClients; i++)
		{
			DisarmPlayer(i);
		}
	}
	
	return Plugin_Handled;
}

public Action RoundStart(Event event, char[] name, bool dontBroadCast)
{
	IsCommandBlocked = false;
	if(startInterval > 0.0) {
		CreateTimer(startInterval, Timer_BlockCommand);
	}

	return Plugin_Continue;
}

public Action PlayerDeath(Event event, char[] name, bool dontBroadCast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	DisarmPlayer(client);
	
	if(IsKillBonusEnabled)
	{
		int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		
		int current = GetClientHealth(attacker);
		int newhealth = current + killBonus;
		SetPlayerHealth(attacker, newhealth);
	}

	return Plugin_Continue;
}

public Action Timer_BlockCommand(Handle timer)
{
	IsCommandBlocked = true;
	return Plugin_Handled;
}