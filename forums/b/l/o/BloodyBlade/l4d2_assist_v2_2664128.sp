#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <colors>

#define PLUGIN_VERSION "2.2"
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3
#define SURVIVOR_MODELS 8

#define MAX_SURVS 6
#define NAME_IF_MAX_SURVS 20
#define NAME_NORMAL 40

ConVar cvar_AssistEnable, cvar_AssistSI, cvar_AssistWitch, cvar_Frags; 
bool g_bAssistEnable;
int g_iAssistSI;
bool g_bAssistWitch, g_bFrags;
int zClassTank, 
DamageSI[MAXPLAYERS+1][MAXPLAYERS+1];
int DamageWitch[MAXPLAYERS+1][2048];
int Frags[MAXPLAYERS+1];
bool g_bHealthAndFragsPrinted;

static char sSurvivorNames[SURVIVOR_MODELS][] =
{
	"Bill", 
	"Zoey", 
	"Francis", 
	"Louis", 
	"Nick", 
	"Rochelle", 
	"Coach", 
	"Ellis"
};

static char sSurvivorModels[SURVIVOR_MODELS][] =
{
	"models/survivors/survivor_namvet.mdl", 
	"models/survivors/survivor_teenangst.mdl", 
	"models/survivors/survivor_biker.mdl", 
	"models/survivors/survivor_manager.mdl", 
	"models/survivors/survivor_gambler.mdl", 
	"models/survivors/survivor_producer.mdl", 
	"models/survivors/survivor_coach.mdl", 
	"models/survivors/survivor_mechanic.mdl"
};

public Plugin myinfo = 
{
	name = "[L4D1/2] Assistance System v.2",
	author = "[E]c, Ren89 & thrillkill",
	description = "Show damage dealt to killed infected",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	char sGameName[12];
	GetGameFolderName(sGameName, sizeof(sGameName));
	if (strcmp(sGameName, "left4dead", false) == 0) zClassTank = 5;
	else if (strcmp(sGameName, "left4dead2", false) == 0) zClassTank = 8;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("sm_assist_version", PLUGIN_VERSION, "Assistance System Version", FCVAR_NONE|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvar_AssistEnable = CreateConVar("sm_assist_enable", "1", "Enables this plugin.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvar_AssistSI = CreateConVar("sm_assist_si", "0", "Show SI damage (0: only tank, 1: all infected except tank, 2: all infected)", FCVAR_NONE, true, 0.0, true, 2.0);
	cvar_AssistWitch = CreateConVar("sm_assist_witch", "1", "1: Show witch damage, cr0wn, who startled, remaining health, 0: off", FCVAR_NONE, true, 0.0, true, 1.0);
	cvar_Frags = CreateConVar("sm_assist_frags", "1", "1: Show frags and tank(s) remaining health at the round end, 0: off", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(cvar_AssistSI, ConVarChanged_Cvars);
	HookConVarChange(cvar_AssistWitch, ConVarChanged_Cvars);
	HookConVarChange(cvar_AssistEnable, ConVarChanged_Cvars);
	HookConVarChange(cvar_Frags, ConVarChanged_Cvars);
	GetCvars();
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("witch_spawn", Event_WitchSpawn);
	HookEvent("infected_hurt", Event_InfectedHurt);
	HookEvent("witch_killed", Event_WitchKilled);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("map_transition", Event_RoundEnd);
	HookEvent("finale_win", Event_RoundEnd);
	HookEvent("witch_harasser_set", Event_WitchHarasserSet);
	HookEvent("player_incapacitated", Event_PlayerIncap);
	
	AutoExecConfig(true, "l4d2_assist_v2");
	
	LoadTranslations("l4d2_assist.phrases");
}

public void OnMapStart()
{
	CreateTimer(180.0, Timer_ShowFrags, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}

public void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bAssistEnable = GetConVarBool(cvar_AssistEnable);
	g_iAssistSI = GetConVarInt(cvar_AssistSI);
	g_bAssistWitch = GetConVarBool(cvar_AssistWitch);
	g_bFrags = GetConVarBool(cvar_Frags);
}

public void Event_PlayerSpawn(Event event, char[] event_name, bool dontBroadcast)
{
	if (g_bAssistEnable)
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		if (IsValidClient(client, TEAM_INFECTED)) ClearDmgSI(client);
	}
}

public Action Event_PlayerHurt(Event event, char[] name, bool dontBroadcast)
{
	if (g_bAssistEnable)
	{
		int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		if (!IsValidClient(attacker, TEAM_SURVIVOR)) return Plugin_Continue;
		
		int victim = GetClientOfUserId(GetEventInt(event, "userid"));
		if (!IsValidClient(victim, TEAM_INFECTED)) return Plugin_Continue;
		
		switch(g_iAssistSI)
		{
			case 0: if (!IsTank(victim)) return Plugin_Handled;
			case 1: if (IsTank(victim)) return Plugin_Handled;
		}
		
		int DamageHealth = GetEventInt(event, "dmg_health");
		if (DamageHealth < 1024) DamageSI[attacker][victim] += DamageHealth;
	}
	return Plugin_Continue;
}

public Action Event_PlayerDeath(Event event, char[] name, bool dontBroadcast)
{
	if (g_bAssistEnable)
	{
		int victim = GetClientOfUserId(GetEventInt(event, "userid"));
		if (IsClient(victim))
		{
			int team = GetClientTeam(victim);
			if (team == TEAM_SURVIVOR)
			{
				if (g_bAssistWitch && !IsFakeClient(victim))
				{
					int witch = GetEventInt(event,"attackerentid");
					if (IsValidEntity(witch) && IsValidEdict(witch))
					{
						char class[64];
						GetEdictClassname(witch, class, sizeof(class));
						if (StrEqual(class, "witch"))
						{
							CPrintToChat(victim, "%t", "WITCH_REMAINING_HEALTH", GetEntProp(witch, Prop_Data, "m_iHealth"));
						}
					}
				}
				ClearDmgSI(victim);
			}
			else if (team == TEAM_INFECTED)
			{
				bool IsVictimTank = IsTank(victim);
				if (g_bFrags && !IsVictimTank)
				{
					int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
					if (IsValidClient(attacker, TEAM_SURVIVOR))
					{
						Frags[attacker]++;
						if (!IsFakeClient(attacker)) PrintHintText(attacker, "%t", "FRAGS_HINT", Frags[attacker]);
					}
				}
				
				switch(g_iAssistSI)
				{
					case 0:
					{
						if (!IsVictimTank)
						{
							ClearDmgSI(victim);
							return Plugin_Handled;
						}
					}
					case 1:
					{
						if (IsVictimTank)
						{
							ClearDmgSI(victim);
							return Plugin_Handled;
						}
					}
				}
				
				int survivors, players[MAXPLAYERS+1][2];
				for (int i = 1; i <= MaxClients; i++)
				{
					if (DamageSI[i][victim] <= 0 || !IsClientInGame(i) || GetClientTeam(i) != TEAM_SURVIVOR) continue;
					players[survivors][0] = i;
					players[survivors][1] = DamageSI[i][victim];
					survivors++;
				}
				
				if (survivors == 0) return Plugin_Handled;
				SortCustom2D(players, survivors, SortByDamage);
				char sMessage[256] = "";
				
				for (int i; i < survivors; i++)
				{
					int attacker = players[i][0];
					char sTempMessage[64];
					Format(sTempMessage, sizeof(sTempMessage), "%t", "DAMAGE_STRING", (i > 0 ? ", " : ""), attacker, DamageSI[attacker][victim]);
					StrCat(sMessage, sizeof(sMessage), sTempMessage);
					DamageSI[attacker][victim] = 0;
				}
				
				CPrintToChatAll("%t", "TANK_KILLED", victim, sMessage);
			}
		}
		else ClearDmgSI(victim);
	}
	return Plugin_Continue;
}

public int SortByDamage(int[] x, int[] y, const int[][] array, Handle hndl)
{
	if (x[1] > y[1]) return -1;
	else if (x[1] == y[1]) return 0;
	return 1;
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	ClearDmgAll();
	g_bHealthAndFragsPrinted = false;
}

public Action Timer_ShowFrags(Handle timer)
{
	char sMessage[256], sTempMessage[64];
	int survivors = 0, players[MAXPLAYERS+1][2];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != TEAM_SURVIVOR) continue;
		if (Frags[i] > 0)
		{
			players[survivors][0] = i;
			players[survivors][1] = Frags[i];
			survivors++;
		}
	}
	
	if (survivors)
	{
		int len = (survivors > MAX_SURVS ? NAME_IF_MAX_SURVS : NAME_NORMAL);
		SortCustom2D(players, survivors, SortByDamage);
		
		for (int i; i < survivors; i++)
		{
			int attacker = players[i][0];
			char[] sName = new char[len];
			GetClientName(attacker, sName, len);
			Format(sTempMessage, sizeof(sTempMessage), "%t", "FRAGS_STRING", (i > 0 ? ", " : ""), sName, Frags[attacker]);
			StrCat(sMessage, sizeof(sMessage), sTempMessage);
		}
		
		CPrintToChatAll("%t", "FRAGS", sMessage);
	}	
}

public Action Event_RoundEnd(Event event, char[] name, bool dontBroadcast)
{
	if (!g_bHealthAndFragsPrinted)
	{
		g_bHealthAndFragsPrinted = true;
		if (g_bAssistEnable && g_bFrags)
		{
			char sMessage[256], sTempMessage[64];
			int Tanks = 0, survivors = 0, players[MAXPLAYERS+1][2];
			for (int i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGame(i)) continue;
				switch(GetClientTeam(i))
				{
					case TEAM_SURVIVOR:
					{
						if (Frags[i] > 0)
						{
							players[survivors][0] = i;
							players[survivors][1] = Frags[i];
							survivors++;
						}
					}
					case TEAM_INFECTED:
					{
						if (IsTank(i) && IsPlayerAlive(i))
						{
							Tanks++;
							Format(sTempMessage, sizeof(sTempMessage), "%t", "TANK_HEALTH_STRING", (Tanks > 1 ? ", " : ""), i, GetClientHealth(i));
							StrCat(sMessage, sizeof(sMessage), sTempMessage);
						}
					}
				}
			}
			
			if (Tanks) CPrintToChatAll("%t", "TANK_REMAINING_HEALTH", sMessage);
			
			if (survivors)
			{
				sMessage = "", sTempMessage = "";
				int len = (survivors > MAX_SURVS ? NAME_IF_MAX_SURVS : NAME_NORMAL);
				SortCustom2D(players, survivors, SortByDamage);
				
				for (int i; i < survivors; i++)
				{
					int attacker = players[i][0];
					char[] sName = new char[len];
					GetClientName(attacker, sName, len);
					Format(sTempMessage, sizeof(sTempMessage), "%t", "FRAGS_STRING", (i > 0 ? ", " : ""), sName, Frags[attacker]);
					StrCat(sMessage, sizeof(sMessage), sTempMessage);
				}
				
				CPrintToChatAll("%t", "FRAGS", sMessage);
			}
		}
		
		ClearDmgAll();
	}
}

void ClearDmgSI(int victim)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		DamageSI[i][victim] = 0;
	}
}

void ClearDmgWitch(int entity)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		DamageWitch[i][entity] = 0;
	}
}

void ClearDmgAll()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		Frags[i] = 0;
		int x;
		for (x = 1; x <= MaxClients; x++)
		{
			DamageSI[i][x] = 0;
		}
		for (x = MaxClients+1; x < 2048; x++)
		{
			DamageWitch[i][x] = 0;
		}
	}
}

public Action Event_WitchSpawn(Event event, char[] name, bool dontBroadcast)
{
	if (g_bAssistEnable && g_bAssistWitch)
	{
		int witch = GetEventInt(event, "witchid");
		if (IsValidEntity(witch) && IsValidEdict(witch)) ClearDmgWitch(witch);
	}
}

public void Event_InfectedHurt(Event event, char[] name, bool dontBroadcast)
{
	if (g_bAssistEnable && g_bAssistWitch)
	{
		int witch = GetEventInt(event, "entityid");
		char class[64];
		GetEdictClassname(witch, class, sizeof(class));
		if (!StrEqual(class, "witch", false)) return;
		
		int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		if (IsValidClient(attacker, TEAM_SURVIVOR))
		{
			int damage = GetEventInt(event, "amount");
			DamageWitch[attacker][witch] += damage;
		}
	}
}

public Action Event_WitchKilled(Event event, char[] name, bool dontBroadcast)
{
	if (g_bAssistEnable && g_bAssistWitch)
	{
		int witch = GetEventInt(event, "witchid");
		if (IsValidEntity(witch) && IsValidEdict(witch))
		{
			int attacker = GetClientOfUserId(GetEventInt(event, "userid"));
			if (IsValidClient(attacker, TEAM_SURVIVOR))
			{
				if (GetEventBool(event, "oneshot"))
				{
					CPrintToChatAll("%t", "WITCH_CROWNED", attacker);
					ClearDmgWitch(witch);
				}
				else
				{
					int survivors, players[33][2];
					for (int i = 1; i <= MaxClients; i++)
					{
						if (DamageWitch[i][witch] <= 0 || !IsClientInGame(i) || GetClientTeam(i) != TEAM_SURVIVOR) continue;
						players[survivors][0] = i;
						players[survivors][1] = DamageWitch[i][witch];
						survivors++;
					}
					
					if (survivors == 0) return Plugin_Handled;
					SortCustom2D(players, survivors, SortByDamage);
					char sMessage[256] = "";
					
					for (int i; i < survivors; i++)
					{
						int client = players[i][0];
						char sTempMessage[64];
						Format(sTempMessage, sizeof(sTempMessage), "%t", "DAMAGE_STRING", (i > 0 ? ", " : ""), client, DamageWitch[client][witch]);
						StrCat(sMessage, sizeof(sMessage), sTempMessage);
						DamageWitch[client][witch] = 0;
					}
					
					CPrintToChatAll("%t", "WITCH_KILLED", sMessage);
				}
			}
			else ClearDmgWitch(witch);
		}
	}
	return Plugin_Continue;
}

public void OnEntityDestroyed(int entity) //escaped or burned
{
	if (g_bAssistEnable && g_bAssistWitch)
	{
		if (IsValidEntity(entity) && IsValidEdict(entity))
		{
			char class[64];
			GetEdictClassname(entity, class, sizeof(class));
			if (StrEqual(class, "witch")) ClearDmgWitch(entity);
		}
	}
}

public Action Event_WitchHarasserSet(Event event, char[] name, bool dontBroadcast)
{
	if (g_bAssistEnable && g_bAssistWitch)
	{
		int target = GetClientOfUserId(GetEventInt(event, "userid"));
		if (IsValidClient(target, TEAM_SURVIVOR))
		{
			if (IsFakeClient(target))
			{
				CPrintToChatAll("%t", "WITCH_STARTLED_BOT", target);
			}
			else
			{
				int iNumMatch = -1;
				char sSubjectModel[64];
				GetClientModel(target, sSubjectModel, sizeof(sSubjectModel));
				for (int i = 0; i < SURVIVOR_MODELS; i++)
				{
					if (StrEqual(sSubjectModel, sSurvivorModels[i]))
					{
						iNumMatch = i;
						break;
					}
				}
				if (iNumMatch == -1) CPrintToChatAll("%t", "WITCH_STARTLED", target, "Unknown");
				else CPrintToChatAll("%t", "WITCH_STARTLED", target, sSurvivorNames[iNumMatch]);
			}
		}
	}
}

public Action Event_PlayerIncap(Event event, char[] name, bool dontBroadcast)
{
	if (g_bAssistEnable && g_bAssistWitch)
	{
		int victim = GetClientOfUserId(GetEventInt(event,"userid"));
		if (IsValidClient(victim, TEAM_SURVIVOR) && !IsFakeClient(victim))
		{
			int witch =  GetEventInt(event, "attackerentid");
			if (IsValidEntity(witch) && IsValidEdict(witch))
			{
				char class[64];
				GetEdictClassname(witch, class, sizeof(class));
				if (StrEqual(class, "witch"))
				{
					CPrintToChat(victim, "%t", "WITCH_REMAINING_HEALTH", GetEntProp(witch, Prop_Data, "m_iHealth"));
				}
			}
		}
	}
}

stock bool IsValidClient(int client, int team)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == team;
}

stock bool IsClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

stock bool IsTank(int client)
{
	return GetEntProp(client, Prop_Send, "m_zombieClass") == zClassTank;
}

public void OnClientDisconnect(int client)
{
	Frags[client] = 0;
}