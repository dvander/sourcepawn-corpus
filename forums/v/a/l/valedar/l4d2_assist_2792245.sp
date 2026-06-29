#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
//#include <colors>
//#pragma tabsize 0

#define PLUGIN_VERSION "2.0"
#define ZOMBIECLASS_TANK 8
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3
#define SURVIVOR_MODELS 8

ConVar cvarEnable;
ConVar cvarTank;
ConVar cvarWitch;

int g_iCvarEnable;
int g_iCvarTank;

bool AssistFlag;
bool WitchAssistFlag;
	

int Damage[MAXPLAYERS+1][MAXPLAYERS+1];
int DamageWitch[MAXPLAYERS+1][MAXPLAYERS+1];
static const char Temp1[] = " | Assist: ";
static const char Temp2[] = ", ";
static const char Temp3[] = " (";
static const char Temp4[] = " dmg)";
static const char Temp5[] = "\x04";
static const char Temp6[] = "\x01";
bool EnableAssist;
bool EnableWitch;

public Plugin myinfo = 
{
	name = "L4D2 Assistance System",
	author = "Lightphoenix2",
	description = "Show assists made by survivors",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=123811"
}

public void OnPluginStart()
{
	CreateConVar("sm_assist_version", PLUGIN_VERSION, "Assistance System Version", FCVAR_NONE|FCVAR_SPONLY|FCVAR_REPLICATED);
	cvarTank = CreateConVar("sm_assist_tank_only", "0", "Enables this will show only damage done to Tank.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarWitch = CreateConVar("sm_crown_witch", "1", "Enables this will show damage done to the witch", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarEnable = CreateConVar("sm_assist_enable", "1", "Enables this plugin.", FCVAR_NONE, true, 0.0, true, 1.0);
	
	AutoExecConfig(true, "l4d2_assist");
	
	cvarEnable.AddChangeHook(ConVarChanged_Cvars);
	cvarWitch.AddChangeHook(ConVarChanged_Cvars);
	cvarTank.AddChangeHook(ConVarChanged_Cvars);
	GetCvars();
	
	HookEvent("player_hurt", Event_Player_Hurt);
	HookEvent("player_death", Event_Player_Death);
	HookEvent("round_end", Event_Round_End);
	HookEvent("round_start", Event_Round_Start);
	HookEvent("witch_killed", Event_WitchKilled);
	HookEvent("witch_spawn", Event_WitchSpawn);
	HookEvent("infected_hurt", Event_InfectedHurt);
}

public void Event_Round_Start(Event event, const char[] name, bool dontBroadcast)
{
	if (g_iCvarEnable)
	{
		ClearAllDmg();
	}
}

public Action Event_Player_Hurt(Event event, const char[] name, bool dontBroadcast)
{
	if (g_iCvarEnable)
	{
		int attacker = GetClientOfUserId(event.GetInt("attacker"));
		int victim = GetClientOfUserId(event.GetInt("userid"));
		if (g_iCvarTank)
		{
			int class = GetEntProp(victim, Prop_Send, "m_zombieClass");
			if (class != ZOMBIECLASS_TANK)
			{
				return Plugin_Handled;
			}
		}
		if ((victim != 0) && (attacker != 0))
		{
			if(GetClientTeam(attacker) != 3 && GetClientTeam(victim) == 3)
			{
				int DamageHealth = GetEventInt(event, "dmg_health");
				if (DamageHealth)
				{
					if (victim != attacker && GetClientTeam(victim) != GetClientTeam(attacker))
					{
						Damage[attacker][victim] += DamageHealth;
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action Event_Player_Death(Event event, const char[] name, bool dontBroadcast)
{
	if (g_iCvarEnable)
	{
		int victim = GetClientOfUserId(event.GetInt("userid"));
		int attacker = GetClientOfUserId(event.GetInt("attacker"));
		int hitgroup = event.GetInt("headshot");
		int type = event.GetInt("type");
		if (g_iCvarTank)
		{
			if ((victim != 0) && (attacker != 0))
			{
				if (GetClientTeam(victim) == 3 && GetClientTeam(attacker) != 3)
				{
					int class = GetEntProp(victim, Prop_Send, "m_zombieClass");
					if (class != ZOMBIECLASS_TANK)
					{
						return Plugin_Handled;
					}
				}
			}
		}
		char Message[256];
		char MsgAssist[256];
		
		if ((victim != 0) && (attacker != 0))
		{
			if (GetClientTeam(victim) == 3 && GetClientTeam(attacker) != 3)
			{
				char sName[MAX_NAME_LENGTH];
				GetClientName(attacker, sName, sizeof(sName));
				char sDamage[10];
				IntToString(Damage[attacker][victim], sDamage, sizeof(sDamage));
				StrCat(Message, sizeof(Message), sName);
				StrCat(Message, sizeof(Message), Temp6);
				StrCat(Message, sizeof(Message), Temp3);
				StrCat(Message, sizeof(Message), sDamage);
				StrCat(Message, sizeof(Message), Temp4);

				for (int i = 1; i <= MaxClients; i++)
				{
					if(IsClientInGame(i) && !IsFakeClient(i))
					{
						if (Damage[i][victim] > 0)
						{
							if (i != attacker)
							{
								AssistFlag = true;
								char tName[MAX_NAME_LENGTH];
								GetClientName(i, tName, sizeof(tName));
								char tDamage[10];
								IntToString(Damage[i][victim], tDamage, sizeof(tDamage));
								StrCat(MsgAssist, sizeof(MsgAssist), Temp5);
								StrCat(MsgAssist, sizeof(MsgAssist), tName);
								StrCat(MsgAssist, sizeof(MsgAssist), Temp6);
								StrCat(MsgAssist, sizeof(MsgAssist), Temp3);
								StrCat(MsgAssist, sizeof(MsgAssist), tDamage);
								StrCat(MsgAssist, sizeof(MsgAssist), Temp4);
								StrCat(MsgAssist, sizeof(MsgAssist), Temp2);
							}
							Damage[i][victim] = 0;
						}
					}
				}

				if (AssistFlag == true) 
				{
					strcopy(MsgAssist, strlen(MsgAssist)-1, MsgAssist);
					StrCat(Message, sizeof(Message), Temp1);
					StrCat(Message, sizeof(Message), MsgAssist);
					AssistFlag = false;
				}
				if (hitgroup == 1 && type != 8) // 8 == death by fire
				{  
					PrintToChatAll("\x04%N\x01 killed by a \x05headshot\x01 from \x04%s.", victim, Message);
				}
				else
				{
					PrintToChatAll("\x04%N\x01 killed by \x04%s.", victim, Message);
				}
			}
		}
		for (int i = 0; i <= MaxClients; i++)
		{
			Damage[i][victim] = 0;
		}
	}
	return Plugin_Continue;
}


public void Event_Round_End(Event event, const char[] name, bool dontBroadcast)
{
	if (g_iCvarEnable)
	{
		ClearAllDmg();		
	}
}
public void Event_WitchSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (EnableAssist && EnableWitch)
	{
		int witch = GetClientOfUserId(event.GetInt("witchid"));
		if (IsValidEntity(witch) && IsValidEdict(witch)) 
		{
			ClearDmgWitch();
		}
	}
}

public void Event_WitchKilled(Event event, const char[] name, bool dontBroadcast)
{
	if (EnableAssist && EnableWitch)
	{
		int witch = GetClientOfUserId(event.GetInt("witchid"));
		int witchCheck = event.GetInt("witchid");
		int killer = GetClientOfUserId(event.GetInt("userid"));
		int hitgroup = event.GetInt("headshot");
		int type = event.GetInt("type");
		if (IsValidEntity(witch) && IsValidEdict(witch))
		{
			if (event.GetBool("oneshot"))
			{
				char sName[MAX_NAME_LENGTH];
				GetClientName(killer, sName, sizeof(sName));
				PrintToChatAll("\x04Witch\x01 Crowned by \x04%s.", sName);
				ClearDmgWitch();
			}
			else
			{
				char WMessage[256];
				char WMsgAssist[256];
				if (IsWitch(witchCheck))
				{
					char killerName[MAX_NAME_LENGTH];
					GetClientName(killer, killerName, sizeof(killerName));
					char killerDamage[10];
					IntToString(DamageWitch[killer][witch], killerDamage, sizeof(killerDamage));
					StrCat(WMessage, sizeof(WMessage), killerName);
					StrCat(WMessage, sizeof(WMessage), Temp6);
					StrCat(WMessage, sizeof(WMessage), Temp3);
					StrCat(WMessage, sizeof(WMessage), killerDamage);
					StrCat(WMessage, sizeof(WMessage), Temp4);

					for (int i = 0; i <= MaxClients; i++)
					{
						if (DamageWitch[i][witch] > 0)
						{
							if (i != killer)
							{
								WitchAssistFlag = true;
								char AssistName[MAX_NAME_LENGTH];
								GetClientName(i, AssistName, sizeof(AssistName));
								char AssistDamage[10];
								IntToString(DamageWitch[i][witch], AssistDamage, sizeof(AssistDamage));
								StrCat(WMsgAssist, sizeof(WMsgAssist), Temp5);
								StrCat(WMsgAssist, sizeof(WMsgAssist), AssistName);
								StrCat(WMsgAssist, sizeof(WMsgAssist), Temp6);
								StrCat(WMsgAssist, sizeof(WMsgAssist), Temp3);
								StrCat(WMsgAssist, sizeof(WMsgAssist), AssistDamage);
								StrCat(WMsgAssist, sizeof(WMsgAssist), Temp4);
								StrCat(WMsgAssist, sizeof(WMsgAssist), Temp2);
							}
						}
						DamageWitch[i][witch] = 0;
					}
					if (WitchAssistFlag == true) 
					{
						strcopy(WMsgAssist,strlen(WMsgAssist)-1,WMsgAssist);
						StrCat(WMessage, sizeof(WMessage), Temp1);
						StrCat(WMessage, sizeof(WMessage), WMsgAssist);
						WitchAssistFlag = false;
					}
					if (hitgroup == 1 && type != 8) // 8 == death by fire
					{  
						PrintToChatAll("\x04Witch\x01 killed by a \x05headshot\x01 from \x04%s.", WMessage);
					}
					else
					{
						PrintToChatAll("\x04Witch\x01 killed by \x04%s.", WMessage);
					}
				}	
			}
			
		}
		else
			ClearDmgWitch();
	}
}

public void Event_InfectedHurt(Event event, const char[] name, bool dontBroadcast)
{
	if (EnableAssist && EnableWitch)
	{		
		int witch = event.GetInt("entityid");		
		char class[64];
		GetEdictClassname(witch, class, sizeof(class));
		if (!StrEqual(class, "witch", false)) return;
		int CWitch = GetClientOfUserId(event.GetInt("entityid"));
		int attacker = GetClientOfUserId(event.GetInt("attacker"));
		if (IsValidClient(attacker, TEAM_SURVIVOR))
		{
			int damage = event.GetInt("amount");
			DamageWitch[attacker][CWitch] += damage;			
		}
	}
}

void ClearDmgWitch()
{	
	for (int i = 0; i <= MaxClients; i++)
		{
			for (int a = 1; a <= MaxClients; a++)
			{
				DamageWitch[i][a] = 0;
			}
		}
}
void ClearAllDmg()
{
	for (int i = 0; i <= MaxClients; i++)
	{
		for (int a = 1; a <= MaxClients; a++)
		{
			Damage[i][a] = 0;
			DamageWitch[i][a] = 0;
		}
	}
}


public void OnEntityDestroyed(int entity) //escaped or burned
{
	if (EnableAssist && EnableWitch)
	{
		if (IsValidEntity(entity) && IsValidEdict(entity))
		{
			char class[64];
			GetEdictClassname(entity, class, sizeof(class));						
			if (StrEqual(class, "witch"))
			{
				ClearDmgWitch();
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

stock bool IsWitch(int client)
{
	char class[64];
	GetEdictClassname(client, class, sizeof(class));						
	if (StrEqual(class, "witch"))
	{
		return true;
	}
	return false;
}
// ====================================================================================================
//					CVARS
// ====================================================================================================
public void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	EnableAssist = cvarEnable.BoolValue;
	EnableWitch = cvarWitch.BoolValue;
	g_iCvarEnable = cvarEnable.IntValue;
	g_iCvarTank = cvarTank.IntValue;
}

