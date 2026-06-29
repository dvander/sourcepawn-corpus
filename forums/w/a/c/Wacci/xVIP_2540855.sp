#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required

Handle HP,
	Gravity,
	Speedy,
	Smokegrenade,
	Flashbang,
	Hegrenade,
	Molotov,
	Remove_grenade,
	Armorvalue,
	Bhashelmet,
	HelmetPistolRound,
	Defuser,
	Moneystart,
	Headshot_hp,
	Kill_hp,
	Tagtable,
	MaxHP,
	Uleczenia,
	Uleczenie,
	Leczenie_HP,
	Reklama,
	TagTable_Timers,
	MoneyOnStart_Timers,
	HelmetPistolRound_Timers;

bool oldbuttons[65];

int g_iaGrenadeOffsets[] = {15, 17, 16, 14, 18, 17},
	uleczenie[MAXPLAYERS+1],
	Rundy;

public void OnPluginStart()
{
	HP = CreateConVar("vip_hp_start", "100", "Ilosc HP na start rundy.", FCVAR_NOTIFY);
	Gravity = CreateConVar("vip_gravity", "1.0", "Grawitacja (1.0 - standardowa).");
	Speedy = CreateConVar("vip_speed", "1.0", "Szybkosc biegania (1.0 - standardowo).");
	Smokegrenade = CreateConVar("vip_grenade_smokegrenade", "0", "Smoke na start rundy.", FCVAR_NONE, true, 0.0, true, 1.0);
	Flashbang = CreateConVar("vip_grenade_flashbang", "0", "Flash na start rundy (0-2).)", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	Hegrenade = CreateConVar("vip_grenade_hegrenade", "0", "Granat na start rundy.", FCVAR_NONE, true, 0.0, true, 1.0);
	Molotov = CreateConVar("vip_grenade_molotov", "0", "Molotov dla tt lub Incendiary dla ct na start rundy.",FCVAR_NONE, true, 0.0, true, 1.0);
	Remove_grenade = CreateConVar("vip_grenade_remove", "0", "Na pocz¹tku rundy usuwa wszystkie granaty.", FCVAR_NONE, true, 0.0, true, 1.0);
	Armorvalue = CreateConVar("vip_armorvalue", "0", "Kamizelka na start rundy.", FCVAR_NONE, true, 0.0, true, 1.0);
	Bhashelmet = CreateConVar("vip_bhashelmet", "0", "Kask na start rundy.", FCVAR_NONE, true, 0.0, true, 1.0);
	HelmetPistolRound = CreateConVar("vip_helmet", "0", "Kask w rundach pistoletowych. '1-wy³¹czony w pistolkach, 0-w³¹czony w pistolkach'", FCVAR_NONE, true, 0.0, true, 1.0);
	Defuser = CreateConVar("vip_defuser", "0", "Zestaw do rozbrajania dla CT na start rundy.", FCVAR_NONE, true, 0.0, true, 1.0);
	Moneystart = CreateConVar("vip_money_start", "0", "Ilosc $ na start rundy.", FCVAR_NOTIFY);
	Headshot_hp = CreateConVar("vip_headshot_hp", "0", "Ilosc HP za Headshot.", FCVAR_NOTIFY);
	Kill_hp = CreateConVar("vip_kill_hp", "0", "Ilosc HP za frag.a", FCVAR_NOTIFY);
	Tagtable = CreateConVar("vip_tag_table", "0", "Tag VIP w tabeli.", FCVAR_NONE, true, 0.0, true, 1.0);
	MaxHP = CreateConVar("vip_hp_max", "110", "Max hp VIP'a.", FCVAR_NOTIFY);
	Uleczenia = CreateConVar("vip_uleczenia", "0", "Uleczenia client'a pod 'E'", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	Uleczenie = CreateConVar("vip_ilosc_uleczen", "2", "Iloœæ uleczeñ VIP'a.", FCVAR_NOTIFY);
	Leczenie_HP = CreateConVar("vip_hp_uleczenie", "10", "Iloœæ HP po ile ma leczyæ.", FCVAR_NOTIFY);
	Reklama = CreateConVar("vip_reklama", "1", "Czy ma byæ w³¹czona reklama kto zrobi³ VIP'a co 2min? Za w³¹czon¹ dziekuje :)", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	AutoExecConfig(true, "xVIP");
	
	HookEvent("player_spawn", Spawn);
	HookEvent("player_death", PlayerDeath);
	HookEvent("round_start", RoundStart);
	HookEvent("cs_win_panel_match", RestartRound);
	
	CreateTimer(120.0, ReklamaAction, _, TIMER_REPEAT);
}

public Action RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	Rundy = Rundy + 1;
	
	TagTable_Timers = CreateTimer(1.5, TagTables, _, TIMER_FLAG_NO_MAPCHANGE);
	MoneyOnStart_Timers = CreateTimer(1.0, MoneyOnSpawn, _, TIMER_FLAG_NO_MAPCHANGE);
	HelmetPistolRound_Timers = CreateTimer(0.5, HelmetPistolRounds, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action RestartRound(Event event, const char[] name, bool dontBroadcast)
{
	Rundy = 0;
}

public Action Spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid")),
		team = GetClientTeam(client),
		g_HP = GetConVarInt(HP),
		g_Flashbang = GetConVarInt(Flashbang),
		i_uleczen = GetConVarInt(Uleczenie);
	
	if(client > 0 && IsPlayerAlive(client) && IsPlayerGenericAdmin(client))
	{
		SetEntityHealth(client, g_HP);
		SetEntityGravity(client, GetConVarFloat(Gravity));
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", GetConVarFloat(Speedy));
		
		if(GetConVarBool(Remove_grenade)) StripNades(client);
		if(GetConVarBool(Smokegrenade)) GivePlayerItem(client, "weapon_smokegrenade");
		if(GetConVarBool(Hegrenade)) GivePlayerItem(client, "weapon_hegrenade");
		if(GetConVarBool(Molotov) && team == CS_TEAM_T) GivePlayerItem(client, "weapon_molotov");
		if(GetConVarBool(Molotov) && team == CS_TEAM_CT) GivePlayerItem(client, "weapon_incgrenade");
		if(GetConVarBool(Armorvalue)) SetEntProp(client, Prop_Send, "m_ArmorValue", 100);
			
		if(GetConVarBool(Flashbang))
		{
			for (int i = 1; i <= g_Flashbang; i++)
			GivePlayerItem(client, "weapon_flashbang");
		}
		if(team == CS_TEAM_CT)
		{
			if(GetConVarBool(Defuser) && GetEntProp(client, Prop_Send, "m_bHasDefuser") == 0) GivePlayerItem(client, "item_defuser"); //kombinerki
		}
		uleczenie[client] = i_uleczen;
	}
} 

public Action PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker")),
		health = GetClientHealth(attacker),
		g_headshot_hp = GetConVarInt(Headshot_hp),
		g_kill_hp = GetConVarInt(Kill_hp),
		max_hp = GetConVarInt(MaxHP);
	
	bool headshot = GetEventBool(event, "headshot");
	if (IsPlayerGenericAdmin(attacker))
	{
		if(headshot)
		{
			if(health >= max_hp - g_headshot_hp)
			{
				SetEntityHealth(attacker, max_hp);
			}
			else
			{
				SetEntityHealth(attacker, health + g_headshot_hp);
			}
		}
		else	
		{
			if(health >= max_hp - g_kill_hp)
			{
				SetEntityHealth(attacker, max_hp);
			}
			else
			{
				SetEntityHealth(attacker, health + g_kill_hp);
			}
		}
	}
}

public Action TagTables(Handle timer)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsValidClient(client, true) && IsPlayerGenericAdmin(client) && GetConVarInt(Tagtable) == 1)
		{
			CS_SetClientClanTag(client, "[VIP]");
			KillTimer(TagTable_Timers);
		}
	}
}

public Action MoneyOnSpawn(Handle timer)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsValidClient(client, true) && IsPlayerGenericAdmin(client))
		{
			int money = GetEntProp(client, Prop_Send, "m_iAccount"),
				g_moneystart = GetConVarInt(Moneystart);
			
			SetEntProp(client, Prop_Send, "m_iAccount", money + g_moneystart);
			KillTimer(MoneyOnStart_Timers);
		}
	}
}

public Action HelmetPistolRounds(Handle timer)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsValidClient(client, true) && IsPlayerGenericAdmin(client))
		{
			if(GetConVarInt(HelmetPistolRound) == 1)
			{
				if(Rundy == 2 || Rundy == 17)
				{
					if(GetConVarBool(Bhashelmet)) SetEntProp(client, Prop_Send, "m_bHasHelmet", 0);
				}
				else
				{
					if(GetConVarBool(Bhashelmet)) SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);
				}
			}
			else
			{
				if(GetConVarBool(Bhashelmet)) SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);
			}
			KillTimer(HelmetPistolRound_Timers);
		}
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float[3] vel, float[3] angles, int &weapon)
{
	int max_hp = GetConVarInt(MaxHP),
		plus_hp = GetConVarInt(Leczenie_HP),
		health = GetEntProp(client, Prop_Send, "m_iHealth"),
		plus_hp2 = max_hp - GetClientHealth(client);
	
	if(client > 0 && IsPlayerGenericAdmin(client) && IsValidClient(client, true) && GetConVarInt(Uleczenia) == 1)
	{
		if(!oldbuttons[client] && buttons & IN_USE)
		{
			if(uleczenie[client] >= 1)
			{
				if(GetConVarInt(HP) > 0)
				{
					if(GetClientHealth(client) == max_hp)
					{
						PrintToChat(client,"[\x06VIP\x01] Nie mozesz sie uleczyc bo masz \x06%d\x07HP\x01, liczba uleczen: \x06%d\x01!", health, uleczenie[client]);
					}
					else if(GetClientHealth(client) >= max_hp - plus_hp)
					{
						SetEntityHealth(client, max_hp);
						
						--uleczenie[client];
						PrintToChat(client,"[\x06VIP\x01] Brawo, zostales uleczony o \x06%d\x07HP\x01, zostalo Ci \x06%d\x01 uleczenie!", plus_hp2, uleczenie[client]);
					}
					else
					{
						SetEntityHealth(client, health + plus_hp);
						
						--uleczenie[client];
						PrintToChat(client,"[\x06VIP\x01] Brawo, zostales uleczony o \x06%d\x07HP\x01, zostalo Ci \x06%d\x01 uleczenie!", plus_hp, uleczenie[client]);
					}
				}
			}
			else
			{
				PrintToChat(client,"[\x06VIP\x01] Przykro mi, ale masz \x06%d\x01 uleczen!", uleczenie[client]);
			}
			oldbuttons[client] = true;
		}
		else if(oldbuttons[client] && !(buttons & IN_USE))
		{
			oldbuttons[client] = false;
		}
	}
	return Plugin_Continue;
}

public Action CS_OnBuyCommand(int client, const char[] item)
{
	if(GetConVarInt(HelmetPistolRound) == 1 && IsPlayerGenericAdmin(client))
	{
		if(Rundy == 2 || Rundy == 17)
		{
			if(StrEqual(item,"assaultsuit"))
			{
				PrintToChat(client, "[\x06VIP\x01] Helm zostal zablokowany na rundach pistoletowych!");
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

public Action ReklamaAction(Handle timer)
{	
	if(GetConVarInt(Reklama) == 1)
	{
		PrintToChatAll("[\x06VIP\x01] Zostal stworzony przez \x04Hanys'a\x01, edytowany przez \x07xBonio\x01 [\x0BArenaSkilla.pl\x01]");
	}
}

stock void StripNades(int client)
{
    while(RemoveWeaponBySlot(client, 3)){}
    for(int i = 0; i < 6; i++)
	SetEntProp(client, Prop_Send, "m_iAmmo", 0, _, g_iaGrenadeOffsets[i]);
}

stock bool RemoveWeaponBySlot(int client, int iSlot)
{
    int iEntity = GetPlayerWeaponSlot(client, iSlot);
    if(IsValidEdict(iEntity))
	{
        RemovePlayerItem(client, iEntity);
        AcceptEntityInput(iEntity, "Kill");
        return true;
    }
    return false;
}

stock void CheckCloseHandle(Handle handle)
{
	if (handle != INVALID_HANDLE)
	{
		CloseHandle(handle);
		handle = INVALID_HANDLE;
	}
}

stock bool IsPlayerGenericAdmin(int client)
{
	if (!CheckCommandAccess(client, "sm_vip", 0, true) && !CheckCommandAccess(client, "arenaskilla", ADMFLAG_ROOT, true)) return false;
	{
		return true;
	}
}

stock bool IsValidClient(int client, bool alive = false)
{
	if(client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && (alive == false || IsPlayerAlive(client)))
	{
		return true;
	}
	return false;
} 

public Plugin myinfo =
{
	name = "xVIP",
	author = "xBonio",
	description = "Plugin z VIP'em (Autor Hanys, edycja xBonio)",
	version = "1.4.1",
	url = "http://arenaskilla.pl"
};