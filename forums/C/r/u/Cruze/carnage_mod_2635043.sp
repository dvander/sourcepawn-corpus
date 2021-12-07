#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>
#include <smlib>

#define Prefix "CARNAGE"
#define m_flNextSecondaryAttack FindSendPropInfo("CBaseCombatWeapon", "m_flNextSecondaryAttack") 

#pragma semicolon 1
#pragma newdecls required

int g_Round = 0;
bool g_NoScope = false, g_bForceCarnage[MAXPLAYERS+1];

ConVar g_EveryWhichRound, g_ADMINFLAG;

char WeaponList[][] =  
{ 
    "weapon_glock", "weapon_usp_silencer", "weapon_deagle", "weapon_tec9", "weapon_hkp2000", "weapon_p250", "weapon_fiveseven", "weapon_elite", "weapon_cz75a", "weapon_galilar", "weapon_famas", "weapon_ak47", "weapon_m4a1", "weapon_m4a1_silencer", "weapon_ssg08", "weapon_aug", "weapon_sg556", "weapon_awp", "weapon_scar20", "weapon_g3sg1", "weapon_nova", "weapon_xm1014","weapon_mag7", "weapon_m249", "weapon_negev", "weapon_mac10", "weapon_mp9", "weapon_mp7", "weapon_ump45", "weapon_p90", "weapon_bizon", "weapon_mp5sd", "weapon_sawedoff", "weapon_knife", "weapon_flashbang", "weapon_hegrenade", "weapon_smokegrenade", "weapon_healthshot", "weapon_decoy", "weapon_molotov", "weapon_incgrenade", "weapon_tagrenade", "weapon_taser"
}; 

public Plugin myinfo = 
{
	name = "[CSGO] Carnage Round", 
	author = "Elitcky, Cruze",
	description = "Normal carnage rounds",
	version = "1.1",
	url = "http://steamcommunity.com/id/stormsmurf2"
};

public void OnPluginStart()
{
	HookEvent("round_start", OnRoundStart);
	HookEvent("round_end", OnRoundEnd);

	RegConsoleCmd("sm_carnage", CMD_CARNAGE);
	RegConsoleCmd("sm_awp", CMD_AWP);
	RegConsoleCmd("sm_forcecarnage", CMD_FCARNAGE);
	RegConsoleCmd("sm_fcarnage", CMD_FCARNAGE);

	g_EveryWhichRound = CreateConVar("sm_carnage_round", "5");
	g_ADMINFLAG = CreateConVar("sm_carnage_flag", "z");
	
	AutoExecConfig(true, "carnage-mod");
	
	for(int i = 1; i <= MaxClients; i++) if(IsValidClient(i, false))
	{
		SDKHook(i, SDKHook_PreThink, PreThink);
	}
}

public void OnMapStart()
{
	AddFileToDownloadsTable("sound/misc/carnageround/ronda_carnageR.mp3");
	AddFileToDownloadsTable("sound/misc/carnageround/ronda_carnage2R.mp3");

	PrecacheSound("misc/carnageround/ronda_carnageR.mp3");
	PrecacheSound("misc/carnageround/ronda_carnage2R.mp3");

	g_Round = 0;
	g_NoScope = false;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_PreThink, PreThink);
}

public Action PreThink(int client)
{
	if(IsPlayerAlive(client))
	{
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(!IsValidEdict(weapon) || !IsValidEntity(weapon))
			return Plugin_Continue;

		char item[64];
		GetEdictClassname(weapon, item, sizeof(item)); 
		if(g_NoScope && isNoScopeWeapon(item))
		{
			SetEntDataFloat(weapon, m_flNextSecondaryAttack, GetGameTime() + 9999.9); //Disable Scope
		}
	}
	return Plugin_Continue;
}

public void OnRoundEnd(Event hEvent, const char[] sName, bool dontBroadcast)
{
	g_NoScope = false;
}

public void OnRoundStart(Event hEvent, const char[] sName, bool dontBroadcast)
{
	if (!IsWarmup()) 
	{ 
		g_Round++;
		if (g_Round == g_EveryWhichRound.IntValue)
		{
			CPrintToChatAll("{green}[%s] {default}CARNAGE ROUND!!!", Prefix);
			g_Round = 0;
			CreateTimer(1.0, Start_Carnage);
		}
		else
		{
			int g_RestaRound = g_EveryWhichRound.IntValue - g_Round;
			if(g_RestaRound == 1) CPrintToChatAll("{green}[%s] {default}%d round left for carnage.", Prefix, g_RestaRound);
			else CPrintToChatAll("{green}[%s] {default}%d rounds left for carnage.", Prefix, g_RestaRound);
		}
	}
}

public Action CMD_FCARNAGE(int client, int args)
{
	GetFlags(client);
	if(g_bForceCarnage[client])
	{
		g_Round = 0;
		CPrintToChatAll("{green}[%s] {default}CARNAGE ROUND!!!", Prefix);
		CreateTimer(1.0, Start_Carnage);
	}
	else
	{
		CPrintToChat(client, "{green}[%s] {default} You need to be admin to use this command.", Prefix);
	}
}

public Action CMD_AWP(int client, int args)
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		if (g_NoScope)
		{
			CPrintToChat(client, "{green}[%s] {default} YOU RECEIVED AN {green}AWP", Prefix);
			Client_GiveWeaponAndAmmo(client, "weapon_awp", _, 50, _, 100);
		}
		else
		{
			CPrintToChat(client, "{green}[%s] {default} You can use this command in carnage round only.", Prefix);
		}
	}
}

public Action CMD_CARNAGE(int client, int args)
{
	if (g_NoScope)
	{
		CPrintToChat(client, "{green}[%s] {default}CARNAGE ROUND!!!", Prefix);
	}
	else
	{ 
		int g_RestaRound = g_EveryWhichRound.IntValue - g_Round;
		if(g_RestaRound == 1) CPrintToChatAll("{green}[%s] {default}%d round left for carnage.", Prefix, g_RestaRound);
		else CPrintToChatAll("{green}[%s] {default}%d rounds left for carnage.", Prefix, g_RestaRound);
	}
}

public Action Start_Carnage(Handle timer)
{
	g_NoScope = true;
	CPrintToChatAll("{green}[%s] {default}THIS IS CARNAGE ROUND", Prefix);
	CPrintToChatAll("{green}[%s] {default}THIS IS CARNAGE ROUND", Prefix);
	CPrintToChatAll("{green}[%s] {default}THIS IS CARNAGE ROUND", Prefix);
	DoWeapons();
	for(int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			switch (GetRandomInt(1, 2))
			{
				case 1:
				{
					ClientCommand(client, "play *misc/carnageround/ronda_carnageR.mp3");
				}
				case 2:
				{
					ClientCommand(client, "play *misc/carnageround/ronda_carnage2R.mp3");
				}
			}
		}
	}
	timer = null;
	return Plugin_Stop;
}

void DoWeapons()
{
	for (int i = 0; i < sizeof(WeaponList); i++)
	{ 
		int ent = -1;
		while ((ent = FindEntityByClassname(ent, WeaponList[i])) != -1)
		{ 
			AcceptEntityInput(ent, "Kill");
		}
	}
	CreateTimer(0.1, TIMER_AWP);
}


public Action TIMER_AWP(Handle timer)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client, false) && IsPlayerAlive(client))
		{
			Client_GiveWeaponAndAmmo(client, "weapon_awp", _, 50, _, 100);
			CPrintToChat(client, "{green}[%s] {default} YOU RECEIVED AN {green}AWP", Prefix);
		}
	}
	timer = null;
	return Plugin_Stop;
}

bool isNoScopeWeapon(char[] weapon)
{
	if(StrEqual(weapon, "weapon_scout")
		|| StrEqual(weapon, "weapon_g3sg1")
		|| StrEqual(weapon, "weapon_ssg08")
		|| StrEqual(weapon, "weapon_aug")
		|| StrEqual(weapon, "weapon_sg556")
		|| StrEqual(weapon, "weapon_awp")
		|| StrEqual(weapon, "weapon_scar20"))
		return true;
	return false;
}

public void GetFlags(int client)
{
	if (IsClientInGame(client))
	{
		char flag[8];
		int g_hFlag;
		GetConVarString(g_ADMINFLAG, flag, sizeof(flag));
		if (StrEqual(flag, "a")) g_hFlag = ADMFLAG_RESERVATION;
		else if (StrEqual(flag, "b")) g_hFlag = ADMFLAG_GENERIC;
		else if (StrEqual(flag, "c")) g_hFlag = ADMFLAG_KICK;
		else if (StrEqual(flag, "d")) g_hFlag = ADMFLAG_BAN;
		else if (StrEqual(flag, "e")) g_hFlag = ADMFLAG_UNBAN;
		else if (StrEqual(flag, "f")) g_hFlag = ADMFLAG_SLAY;
		else if (StrEqual(flag, "g")) g_hFlag = ADMFLAG_CHANGEMAP;
		else if (StrEqual(flag, "h")) g_hFlag = ADMFLAG_CONVARS;
		else if (StrEqual(flag, "i")) g_hFlag = ADMFLAG_CONFIG;
		else if (StrEqual(flag, "j")) g_hFlag = ADMFLAG_CHAT;
		else if (StrEqual(flag, "k")) g_hFlag = ADMFLAG_VOTE;
		else if (StrEqual(flag, "l")) g_hFlag = ADMFLAG_PASSWORD;
		else if (StrEqual(flag, "m")) g_hFlag = ADMFLAG_RCON;
		else if (StrEqual(flag, "n")) g_hFlag = ADMFLAG_CHEATS;
		else if (StrEqual(flag, "z")) g_hFlag = ADMFLAG_ROOT;
		else if (StrEqual(flag, "o")) g_hFlag = ADMFLAG_CUSTOM1;
		else if (StrEqual(flag, "p")) g_hFlag = ADMFLAG_CUSTOM2;
		else if (StrEqual(flag, "q")) g_hFlag = ADMFLAG_CUSTOM3;
		else if (StrEqual(flag, "r")) g_hFlag = ADMFLAG_CUSTOM4;
		else if (StrEqual(flag, "s")) g_hFlag = ADMFLAG_CUSTOM5;
		else if (StrEqual(flag, "t")) g_hFlag = ADMFLAG_CUSTOM6;
		else
		{
			SetFailState("The given flag is invalid in sm_carnage_flag");
		}
		
		int flags = GetUserFlagBits(client);		
		if (flags & g_hFlag)
		{
			g_bForceCarnage[client] = true;
		}
		else
		{
			g_bForceCarnage[client] = false;
		}
	}
}

stock bool IsWarmup() 
{ 
    int warmup = GameRules_GetProp("m_bWarmupPeriod", 4, 0); 
    if (warmup == 1) return true; 
    else return false; 
}

bool IsValidClient(int client, bool botz = true)
{ 
    if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || !IsClientConnected(client) || botz && IsFakeClient(client) || IsClientSourceTV(client)) 
        return false; 
     
    return true;
}