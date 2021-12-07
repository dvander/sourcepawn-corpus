#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "LaFF"
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "", 
	author = PLUGIN_AUTHOR, 
	description = "", 
	version = PLUGIN_VERSION, 
	url = ""
};

bool Ready[MAXPLAYERS + 1] = false;
int ReadyPlayers = 0;
bool IsGameStarted = false;
bool IsKnifeRound = false;
bool Won[MAXPLAYERS + 1] = false;
bool MovedSpectator[MAXPLAYERS + 1] = false;

Handle tTimer1;
Handle hTakeGuns;
Handle hTimerTeam;
ConVar neededready;

public void OnPluginStart()
{
	RegConsoleCmd("sm_ready", command_ready);
	RegConsoleCmd("sm_unready", command_unready);
	RegAdminCmd("sm_forceready", command_aready, ADMFLAG_BAN);
	RegConsoleCmd("sm_t", command_t);
	RegConsoleCmd("sm_ct", command_ct);
	
	
	HookEvent("round_start", OnRoundStart);
	HookEvent("round_end", OnRoundEnd);
	
	neededready = CreateConVar("sm_need_ready", "2", "amount of players that have to do /ready");
	tTimer1 = CreateTimer(1.0, showtext, _, TIMER_REPEAT);
	
	AutoExecConfig(true, "Tournament");
	CreateTimer(1.0, tTakeGuns, _, TIMER_REPEAT);
	
}
public Action command_t(int client, int args)
{
	if (Won[client])
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsValidClient(i))continue;
			if (Won[i])
			{
				if (GetClientTeam(i) == CS_TEAM_SPECTATOR)
				{
					ChangeClientTeam(i, CS_TEAM_SPECTATOR);
					MovedSpectator[i] = true;
				}
				if (!MovedSpectator[i] && Won[i])
				{
					ChangeClientTeam(i, CS_TEAM_T);
				}
			} else {
				if (GetClientTeam(i) == CS_TEAM_SPECTATOR)
				{
					ChangeClientTeam(i, CS_TEAM_SPECTATOR);
					MovedSpectator[i] = true;
				}
				if (!MovedSpectator[i] && !Won[i])
				{
					ChangeClientTeam(i, CS_TEAM_CT);
				}
			}
			if (Won[i])
			{
				Won[i] = false;
			}
		}
		delete hTimerTeam;
		IsGameStarted = true;
		PrintToChatAll("\x01[\x10Tournament\x01] Game is starting!");
		SetTeamScore(CS_TEAM_CT, 0);
		SetTeamScore(CS_TEAM_T, 0);
		CreateTimer(5.0, tKillPlayers);
		
	}
	return Plugin_Handled;
}
public Action tKillPlayers(Handle timer)
{
	ServerCommand("sm_kill @all");
	ServerCommand("mp_restartgame 1");
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			CS_SetClientAssists(i, 0);
			SetEntProp(i, Prop_Data, "m_iFrags", 0);
			SetEntProp(i, Prop_Data, "m_iDeaths", 0);
		}
	}
}
public Action command_ct(int client, int args)
{
	if (Won[client])
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsValidClient(i))continue;
			if (Won[i])
			{
				if (GetClientTeam(i) == CS_TEAM_SPECTATOR)
				{
					ChangeClientTeam(i, CS_TEAM_SPECTATOR);
					MovedSpectator[i] = true;
				}
				if (!MovedSpectator[i] && Won[i])
				{
					ChangeClientTeam(i, CS_TEAM_CT);
				}
			} else {
				if (GetClientTeam(i) == CS_TEAM_SPECTATOR)
				{
					ChangeClientTeam(i, CS_TEAM_SPECTATOR);
					MovedSpectator[i] = true;
				}
				if (!MovedSpectator[i] && !Won[i])
				{
					ChangeClientTeam(i, CS_TEAM_T);
				}
			}
			Won[i] = false;
		}
		delete hTimerTeam;
		IsGameStarted = true;
		PrintToChatAll("\x01[\x10Tournament\x01] Game is starting");
		SetTeamScore(CS_TEAM_CT, 0);
		SetTeamScore(CS_TEAM_T, 0);
		CreateTimer(5.0, tKillPlayers);
	}
	return Plugin_Handled;
}
public Action OnRoundStart(Event event, const char[] name, bool dbc)
{
	if (IsKnifeRound)
	{
		IsGameStarted = true;
	}
}

public Action OnRoundEnd(Event event, const char[] name, bool dbc)
{
	if (IsKnifeRound)
	{
		delete hTakeGuns;
		if (GetTeamScore(CS_TEAM_T) > GetTeamScore(CS_TEAM_CT))
		{
			
			for (int i = 1; i <= MaxClients; i++)
			{
				if (!IsValidClient(i))continue;
				if (GetClientTeam(i) == CS_TEAM_T)
				{
					Won[i] = true;
				}
			}
			PrintToChatAll("\x01[\x10Tournament\x01] \x02 Terrorist team won");
		}
		if (GetTeamScore(CS_TEAM_CT) > GetTeamScore(CS_TEAM_T))
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (!IsValidClient(i))continue;
				if (GetClientTeam(i) == CS_TEAM_CT)
				{
					Won[i] = true;
				}
			}
			PrintToChatAll("\x01[\x10Tournament\x01] \x02 Counter-Terrorist team won");
		}
		PrintToChatAll("\x01[\x10Tournament\x01] \x04The winner team has to choose  /ct or /t, you have 30 seconds to deside or it will stay as it is.");
		hTimerTeam = CreateTimer(30.0, tChangeTeam);
		SetTeamScore(CS_TEAM_CT, 0);
		SetTeamScore(CS_TEAM_T, 0);
		IsKnifeRound = false;
		IsGameStarted = true;
		return Plugin_Changed;
	}
	return Plugin_Handled;
}
public Action tChangeTeam(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			Won[i] = false;
			ServerCommand("mp_restartgame 1");
			IsGameStarted = true;
			delete hTimerTeam;
		}
	}
}

public Action tTakeGuns(Handle timer)
{
	if (IsKnifeRound)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i))
			{
				if (IsPlayerAlive(i))
				{
					SmazatZbran(i);
					SmazatPistol(i);
				}
			}
		}
	}
}

public Action command_aready(int client, int args)
{
	PrintToChatAll("\x01[\x10Tournament\x01]  \x02Knife round starts");
	ServerCommand("mp_restartgame 1");
	delete tTimer1;
	if (!IsGameStarted)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i))
			{
				Ready[i] = true;
				ReadyPlayers = 4;
				if (GetClientTeam(i) != CS_TEAM_SPECTATOR)
				{
					PrintToChatAll("\x01[\x10Tournament\x01]  \x02%N \x04is ready actual state is \x01(\x02%i/%i\x01)", i, ReadyPlayers, neededready.IntValue);
				}
				SetTeamScore(CS_TEAM_CT, 0);
				SetTeamScore(CS_TEAM_T, 0);
				CS_SetClientAssists(i, 0);
				SetEntProp(client, Prop_Data, "m_iFrags", 0);
				SetEntProp(client, Prop_Data, "m_iDeaths", 0);
				IsKnifeRound = true;
			}
		}
	}
	IsGameStarted = true;
	return Plugin_Handled;
}

public Action command_unready(int client, int args)
{
	if (IsValidClient(client) && Ready[client] && !IsGameStarted)
	{
		Ready[client] = false;
		ReadyPlayers -= 1;
		PrintToChatAll("\x01[\x10Tournament\x01]  \x02%N \x04is not ready actual state is \x01(\x02%i/%i\x01)", client, ReadyPlayers, neededready.IntValue);
	}
}
public Action command_ready(int client, int args)
{
	if (!Ready[client] && !IsGameStarted && GetClientTeam(client) != CS_TEAM_SPECTATOR)
	{
		Ready[client] = true;
		ReadyPlayers += 1;
		PrintToChatAll("\x01[\x10Tournament\x01]  \x02%N \x04is ready actual state is (%i/%i)", client, ReadyPlayers, neededready.IntValue);
		PrintToServer("Ready players : %i", ReadyPlayers);
	}
	if (ReadyPlayers >= neededready.IntValue && !IsGameStarted)
	{
		PrintToChatAll("\x01[\x10Tournament\x01] \x02Knife round starts");
		IsGameStarted = true;
		ServerCommand("mp_restartgame 1");
		delete tTimer1;
		SetTeamScore(CS_TEAM_CT, 0);
		SetTeamScore(CS_TEAM_T, 0);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsValidClient(i))continue;
			CS_SetClientAssists(i, 0);
			SetEntProp(client, Prop_Data, "m_iFrags", 0);
			SetEntProp(client, Prop_Data, "m_iDeaths", 0);
		}
		IsKnifeRound = true;
	}
}

public Action showtext(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsGameStarted)
		{
			if (!IsValidClient(i))continue;
			SetHudTextParams(0.45, 0.2, 1.0, 255, 23, 126, 255);
			ShowHudText(i, -1, "Warmup round");
		}
	}
	return Plugin_Continue;
}

stock bool IsValidClient(int client)
{
	if (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsClientSourceTV(client))
	{
		return true;
	}
	
	return false;
}

stock void SmazatZbran(int client)
{
	int Primary = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
	if (IsValidEdict(Primary))
	{
		char WeaponName[30];
		GetEntityClassname(Primary, WeaponName, sizeof(WeaponName));
		//AWP
		if (StrEqual(WeaponName, "weapon_awp", false))
		{
			if (IsValidEdict(Primary) && Primary != -1)
			{
				RemoveEdict(Primary);
			}
		}
		
		//SCOUTA
		if (StrEqual(WeaponName, "weapon_ssg08", false))
		{
			if (IsValidEdict(Primary) && Primary != -1)
			{
				RemoveEdict(Primary);
			}
		}
		
		//AUTOLAMY
		if (StrEqual(WeaponName, "weapon_g3sg1", false) || StrEqual(WeaponName, "weapon_scar20", false))
		{
			if (IsValidEdict(Primary) && Primary != -1)
			{
				RemoveEdict(Primary);
			}
		}
		
		//RIFLE
		if (StrEqual(WeaponName, "weapon_ak47", false) || StrEqual(WeaponName, "weapon_aug", false) || StrEqual(WeaponName, "weapon_sg556", false) || StrEqual(WeaponName, "weapon_m4a1_silencer", false) || StrEqual(WeaponName, "weapon_m4a1", false) || StrEqual(WeaponName, "weapon_galilar", false) || StrEqual(WeaponName, "weapon_famas", false))
		{
			if (IsValidEdict(Primary) && Primary != -1)
			{
				RemoveEdict(Primary);
			}
		}
		
		//BROKOVNICE
		if (StrEqual(WeaponName, "weapon_nova", false) || StrEqual(WeaponName, "weapon_mag7", false) || StrEqual(WeaponName, "weapon_sawedoff", false) || StrEqual(WeaponName, "weapon_xm1014", false))
		{
			if (IsValidEdict(Primary) && Primary != -1)
			{
				RemoveEdict(Primary);
			}
		}
		
		//SMG
		if (StrEqual(WeaponName, "weapon_mac10", false) || StrEqual(WeaponName, "weapon_mp7", false) || StrEqual(WeaponName, "weapon_ump45", false) || StrEqual(WeaponName, "weapon_bizon", false) || StrEqual(WeaponName, "weapon_mp5sd", false) || StrEqual(WeaponName, "weapon_mp9", false))
		{
			if (IsValidEdict(Primary) && Primary != -1)
			{
				RemoveEdict(Primary);
			}
		}
		
		//TEZKE KULOMETY
		if (StrEqual(WeaponName, "weapon_m249", false))
		{
			if (IsValidEdict(Primary) && Primary != -1)
			{
				RemoveEdict(Primary);
			}
		}
		
		if (StrEqual(WeaponName, "weapon_negev", false))
		{
			if (IsValidEdict(Primary) && Primary != -1)
			{
				RemoveEdict(Primary);
			}
		}
	}
}

stock void SmazatPistol(int client)
{
	int Secondary = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
	if (IsValidEdict(Secondary))
	{
		char SecondaryName[30];
		GetEntityClassname(Secondary, SecondaryName, sizeof(SecondaryName));
		//PISTOLE
		if (StrEqual(SecondaryName, "weapon_glock", false) || StrEqual(SecondaryName, "weapon_usp_silencer", false) || StrEqual(SecondaryName, "weapon_hkp2000", false) || StrEqual(SecondaryName, "weapon_fiveseven", false) || StrEqual(SecondaryName, "weapon_revolver", false) || StrEqual(SecondaryName, "weapon_deagle", false) || StrEqual(SecondaryName, "weapon_cz75", false) || StrEqual(SecondaryName, "weapon_tec9", false) || StrEqual(SecondaryName, "weapon_p250", false) || StrEqual(SecondaryName, "weapon_elite", false))
		{
			if (IsValidEdict(Secondary) && Secondary != -1)
			{
				RemoveEdict(Secondary);
			}
		}
	}
}

stock void RemovePlayerPrimary(int client)
{
	int fegya;
	for (int i = 0; i < 6; i++)
	{
		fegya = GetPlayerWeaponSlot(client, i);
		if (IsValidEntity(fegya) && i == 0)
		{
			RemovePlayerItem(client, fegya);
			RemovePlayerItem(client, 31);
		}
	}
}
public void OnClientPutInServer(int client)
{
	if (IsValidClient(client))
	{
		SDKHook(client, SDKHook_PostThinkPost, Hook_PostThinkPost);
	}
}
public void Hook_PostThinkPost(int client)
{
	if (IsKnifeRound)
	{
		SetEntProp(client, Prop_Send, "m_bInBuyZone", 0);
	}
	
}
public void OnMapStart()
{
	ReadyPlayers = 0;
	IsGameStarted = false;
	IsKnifeRound = false;
	for (int i = 1; i <= MaxClients; i++)
	{
		Won[i] = false;
		MovedSpectator[i] = false;
		Ready[i] = false;
	}
	
	tTimer1 = CreateTimer(1.0, showtext, _, TIMER_REPEAT);
} 