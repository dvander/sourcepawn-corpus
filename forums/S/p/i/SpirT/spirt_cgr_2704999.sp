#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "SpirT"
#define PLUGIN_VERSION "1.1.2"

#define MouseScoping FindSendPropOffs("CBaseCombatWeapon", "m_flNextSecondaryAttack")

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

bool IsRoundActive;
bool IsCommandBlocked;
bool IsKillBonusEnabled;
bool IsPickupBlocked;

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
	HookEvent("player_death", PlayerDeath);
	
	BuildPath(Path_SM, file, sizeof(file), "configs/custom_game_rounds.cfg");
	
	g_time = CreateConVar("spirt_cgr_interval", "10.0", "How many seconds after the round start should the command be blocked.");
	AutoExecConfig(true, "spirt.cgr");
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
								
				char kvstartHealth[10];
				KvGetString(kv, "start_health", kvstartHealth, sizeof(kvstartHealth), "100");
				int startHealth = StringToInt(kvstartHealth);
				
				char kvkillBonus[10];
				KvGetString(kv, "kill_bonus", kvkillBonus, sizeof(kvkillBonus), "0");
				killBonus = StringToInt(kvkillBonus);
				
				char g_pickupEnabled[3];
				KvGetString(kv, "weapons_pickup", g_pickupEnabled, sizeof(g_pickupEnabled), "1");
				int pickupEnabled = StringToInt(g_pickupEnabled);
				
				if(killBonus != 0)
				{
					IsKillBonusEnabled = true;
				}
				
				for (int i = 1; i < MaxClients; i++)
				{
					if(IsClientConnected(i) && IsClientInGame(i))
					{
						PrintHintText(i, hint);
						DisarmPlayer(i);
						EquipPlayer(i, roundWeapon);
						BlockPlayersWeaponPickup(i, pickupEnabled);
						SetPlayerHealth(i, startHealth);
					}
				}
			}
		} while (KvGotoNextKey(kv));
		
		delete kv;
	}
}

void DisarmPlayer(int client)
{
	for(int i = 0; i < 5; i++)
	{
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

public void OnClientPutInServer(int client)
{
	if(IsPickupBlocked)
	{
		SDKHook(client, SDKHook_WeaponCanUse, SDKHook_BlockPickup);
	}
	else
	{
		IsPickupBlocked = false;
		SDKHook(client, SDKHook_WeaponCanUse, SDKHook_BlockPickup);
	}
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
	CreateTimer(GetConVarFloat(g_time), Timer_BlockCommand);
	return Plugin_Handled;
}

public Action PlayerDeath(Event event, char[] name, bool dontBroadCast)
{
	if(IsKillBonusEnabled)
	{
		int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		
		int current = GetClientHealth(attacker);
		int newhealth = current + killBonus;
		SetPlayerHealth(attacker, newhealth);
	}
}

public Action Timer_BlockCommand(Handle timer)
{
	IsCommandBlocked = true;
	return Plugin_Handled;
}