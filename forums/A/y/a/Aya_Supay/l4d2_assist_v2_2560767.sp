#pragma semicolon 1
#include <sourcemod>
#include <colors>
#pragma newdecls required

#define PLUGIN_VERSION "2.0"

	ConVar cvar_AssistEnable;
	ConVar cvar_AssistSI; 
	ConVar cvar_AssistWitch;
	bool g_bAssistEnable; 
	int g_iAssistSI;
	bool g_bAssistWitch; 
	int zClassTank;
	int DamageSI[33][33]; 
	int DamageWitch[33][2049];
 
public Plugin myinfo = 
{
	name = "[L4D1/2] Assistance System v.2",
	author = "[E]c, Ren89 & thrillkill edited by [†×Ą]AYA SUPAY[Ļ×Ø]",
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
	CreateConVar("sm_assist_version", PLUGIN_VERSION, "Assistance System Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvar_AssistEnable = CreateConVar("sm_assist_enable", "1", "Enables this plugin.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_AssistSI = CreateConVar("sm_assist_si", "2", "Show SI damage (0: only tank, 1: all infected except tank, 2: all infected)", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	cvar_AssistWitch = CreateConVar("sm_assist_witch", "1", "Show witch damage & cr0wn", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(cvar_AssistSI, ConVarChanged_Cvars);
	HookConVarChange(cvar_AssistWitch, ConVarChanged_Cvars);
	HookConVarChange(cvar_AssistEnable, ConVarChanged_Cvars);
	g_bAssistEnable = GetConVarBool(cvar_AssistEnable);
	g_iAssistSI = GetConVarInt(cvar_AssistSI);
	g_bAssistWitch = GetConVarBool(cvar_AssistWitch);
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("witch_spawn", Event_WitchSpawn);
	HookEvent("infected_hurt", Event_InfectedHurt);
	HookEvent("witch_killed", Event_WitchKilled);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("round_start", Event_RoundEnd);
	
	AutoExecConfig(true, "l4d2_assist_v2");
	
	LoadTranslations("l4d2_assist.phrases");
}

public void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	g_bAssistEnable = GetConVarBool(cvar_AssistEnable);
	g_iAssistSI = GetConVarInt(cvar_AssistSI);
	g_bAssistWitch = GetConVarBool(cvar_AssistWitch);
}

public Action Event_PlayerSpawn(Event event, char[] event_name, bool dontBroadcast)
{
	if (g_bAssistEnable)
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		if (client > 0 && GetClientTeam(client) == 3) ClearDmg(client);
	}
}

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bAssistEnable)
	{
		int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		int victim = GetClientOfUserId(GetEventInt(event, "userid"));
		if (attacker > 0 && victim > 0 && victim != attacker)
		{
			int iAttackerTeam = GetClientTeam(attacker);
			int iVictimTeam = GetClientTeam(victim);
			if (iAttackerTeam == 2 && iVictimTeam == 3 && iAttackerTeam != iVictimTeam)
			{
				int class = GetEntProp(victim, Prop_Send, "m_zombieClass");
				switch(g_iAssistSI)
				{
					case 0:
					{
						if (class != zClassTank) return Plugin_Handled;
					}
					case 1:
					{
						if (class == zClassTank) return Plugin_Handled;
					}
				}
				
				int DamageHealth = GetEventInt(event, "dmg_health");
				if (DamageHealth < 1024) DamageSI[attacker][victim] += DamageHealth;
			}
		}
	}
	return Plugin_Continue;
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bAssistEnable)
	{
		int victim = GetClientOfUserId(GetEventInt(event, "userid"));
		if (victim > 0 && GetClientTeam(victim) == 3)
		{
			int class = GetEntProp(victim, Prop_Send, "m_zombieClass");
			switch(g_iAssistSI)
			{
				case 0:
				{
					if (class != zClassTank)
					{
						ClearDmg(victim);
						return Plugin_Handled;
					}
				}
				case 1:
				{
					if (class == zClassTank)
					{
						ClearDmg(victim);
						return Plugin_Handled;
					}
				}
			}
			
			int survivors, players[33][2];
			for (int i = 1; i <= MaxClients; i++)
			{
				if (DamageSI[i][victim] <= 0 || !IsClientInGame(i) || GetClientTeam(i) != 2) continue;
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
		else ClearDmg(victim);
	}
	return Plugin_Continue;
}

public int SortByDamage(int[] x, int[] y, const int[][] array, Handle hndl)
{
	if (x[1] > y[1]) return -1;
	else if (x[1] == y[1]) return 0;
	return 1;
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ClearDmgAll();
}

void ClearDmg(int victim)
{
	if (g_bAssistEnable)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (victim >= 33) return;
			DamageSI[i][victim] = 0; 
		}
	}
}

void ClearDmgAll()
{
	if (g_bAssistEnable)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			int x;
			for (x = 1; x <= MaxClients; x++)
			{
				DamageSI[i][x] = 0;
			}
			for (x = 33; x < 2048; x++)
			{
				DamageWitch[i][x] = 0;
			}
		}
	}
}

public Action Event_WitchSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bAssistEnable && g_bAssistWitch)
	{
		int witch = GetEventInt(event, "witchid");
		if (witch > 32) ClearDmg(witch);
	}
}

public Action Event_InfectedHurt(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bAssistEnable && g_bAssistWitch)
	{
		int witch = GetEventInt(event, "entityid");
		char class[64];
		GetEdictClassname(witch, class, sizeof(class));
		if (!StrEqual(class, "witch", false)) return;
		
		int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		if (attacker > 0 && GetClientTeam(attacker) == 2)
		{
			int damage = GetEventInt(event, "amount");
			DamageWitch[attacker][witch] += damage;
		}
	}
}

public Action Event_WitchKilled(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bAssistEnable && g_bAssistWitch)
	{
		int witch = GetEventInt(event, "witchid");
		int attacker = GetClientOfUserId(GetEventInt(event, "userid"));
		if (attacker > 0 && GetClientTeam(attacker) == 2)
		{
			if (GetEventBool(event, "oneshot"))
			{
				CPrintToChatAll("%t", "WITCH_CROWNED", attacker);
				ClearDmg(witch);
			}
			else
			{
				int survivors, players[33][2];
				for (int i = 1; i <= MaxClients; i++)
				{
					if (DamageWitch[i][witch] <= 0 || !IsClientInGame(i) || GetClientTeam(i) != 2) continue;
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
		else ClearDmg(witch);
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
			if (StrEqual(class, "witch")) ClearDmg(entity);
		}
	}
}