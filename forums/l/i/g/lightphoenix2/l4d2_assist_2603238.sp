#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <colors>
#pragma tabsize 0

#define PLUGIN_VERSION "2.0"
#define ZOMBIECLASS_TANK 8
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3
#define SURVIVOR_MODELS 8

ConVar cvarEnable, cvarTank, cvarWitch;

new bool:AssistFlag, bool:WitchAssistFlag;
	

new Damage[MAXPLAYERS+1][MAXPLAYERS+1], DamageWitch[MAXPLAYERS+1][MAXPLAYERS+1];
new String:Temp1[] = " | Assist: ";
new String:Temp2[] = ", ";
new String:Temp3[] = " (";
new String:Temp4[] = " dmg)";
new String:Temp5[] = "\x04";
new String:Temp6[] = "\x01";
bool EnableAssist, EnableWitch, EnableTankOnly;

public Plugin:myinfo = 
{
	name = "L4D2 Assistance System",
	author = "Lightphoenix2",
	description = "Show assists made by survivors",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=123811"
}

public OnPluginStart()
{
	CreateConVar("sm_assist_version", PLUGIN_VERSION, "Assistance System Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarTank = CreateConVar("sm_assist_tank_only", "0", "Enables this will show only damage done to Tank.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarWitch = CreateConVar("sm_crown_witch", "1", "Enables this will show damage done to the witch", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarEnable = CreateConVar("sm_assist_enable", "1", "Enables this plugin.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
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
	HookEvent("witch_harasser_set", Event_WitchHarasserSet);
	HookEvent("infected_hurt", Event_InfectedHurt);
}

public Action:Event_Round_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(cvarEnable))
	{
		ClearAllDmg();
	}
}

public Action:Event_Player_Hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(cvarEnable))
	{
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		new victim = GetClientOfUserId(GetEventInt(event, "userid"));
		if (GetConVarInt(cvarTank))
		{
			new class = GetEntProp(victim, Prop_Send, "m_zombieClass");
			if (class != ZOMBIECLASS_TANK)
			{
				return Plugin_Handled;
			}
		}
		if ((victim != 0) && (attacker != 0))
		{
			if(GetClientTeam(attacker) != 3 && GetClientTeam(victim) == 3)
			{
				new DamageHealth = GetEventInt(event, "dmg_health");
				if (DamageHealth < 1024)
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

public Action:Event_Player_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(cvarEnable))
	{
		new victim = GetClientOfUserId(GetEventInt(event, "userid"));
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		int hitgroup = GetEventInt(event, "headshot");
		int type = GetEventInt(event, "type");
		if (GetConVarInt(cvarTank))
		{
			if ((victim != 0) && (attacker != 0))
			{
				if (GetClientTeam(victim) == 3 && GetClientTeam(attacker) != 3)
				{
					new class = GetEntProp(victim, Prop_Send, "m_zombieClass");
					if (class != ZOMBIECLASS_TANK)
					{
						return Plugin_Handled;
					}
				}
			}
		}
		new String:Message[256];
		new String:MsgAssist[256];
		
		if ((victim != 0) && (attacker != 0))
		{
			if (GetClientTeam(victim) == 3 && GetClientTeam(attacker) != 3)
			{
				decl String:sName[MAX_NAME_LENGTH];
				GetClientName(attacker, sName, sizeof(sName));
				decl String:sDamage[10];
				IntToString(Damage[attacker][victim], String:sDamage, sizeof(sDamage));
				StrCat(String:Message, sizeof(Message), String:sName);
				StrCat(String:Message, sizeof(Message), String:Temp6);
				StrCat(String:Message, sizeof(Message), String:Temp3);
				StrCat(String:Message, sizeof(Message), String:sDamage);
				StrCat(String:Message, sizeof(Message), String:Temp4);

				for (new i = 0; i <= MAXPLAYERS; i++)
				{
					if (Damage[i][victim] > 0)
					{
						if (i != attacker)
						{
							AssistFlag = true;
							decl String:tName[MAX_NAME_LENGTH];
							GetClientName(i, tName, sizeof(tName));
							decl String:tDamage[10];
							IntToString(Damage[i][victim], String:tDamage, sizeof(tDamage));
							StrCat(String:MsgAssist, sizeof(MsgAssist), String:Temp5);
							StrCat(String:MsgAssist, sizeof(MsgAssist), String:tName);
							StrCat(String:MsgAssist, sizeof(MsgAssist), String:Temp6);
							StrCat(String:MsgAssist, sizeof(MsgAssist), String:Temp3);
							StrCat(String:MsgAssist, sizeof(MsgAssist), String:tDamage);
							StrCat(String:MsgAssist, sizeof(MsgAssist), String:Temp4);
							StrCat(String:MsgAssist, sizeof(MsgAssist), String:Temp2);
						}
					}
					Damage[i][victim] = 0;
				}

				if (AssistFlag == true) 
				{
					strcopy(String:MsgAssist,strlen(MsgAssist)-1,MsgAssist);
					StrCat(String:Message, sizeof(Message), String:Temp1);
					StrCat(String:Message, sizeof(Message), String:MsgAssist);
					AssistFlag = false;
				}
				if (hitgroup == 1 && type != 8) // 8 == death by fire
				{  
					PrintToChatAll("\x04%N\x01 killed by a \x05headshot\x01 from \x04%s.", victim, Message);
				}
				else
				{
					PrintToChatAll("\x04%N\x01 got killed by \x04%s.", victim, Message);
				}
			}
		}
		for (new i = 0; i <= MAXPLAYERS; i++)
		{
			Damage[i][victim] = 0;
		}
	}
	return Plugin_Continue;
}


public Action:Event_Round_End(Handle:event, const char[] name, bool:dontBroadcast)
{
	if (GetConVarInt(cvarEnable))
	{
		ClearAllDmg();		
	}
}
public Action:Event_WitchSpawn(Handle:event, const char[] name, bool:dontBroadcast)
{
	if (EnableAssist && EnableWitch && !EnableTankOnly)
	{
		new witch = GetClientOfUserId(GetEventInt(event, "witchid"));
		if (IsValidEntity(witch) && IsValidEdict(witch)) 
		{
			ClearDmgWitch();
		}
	}
}

public Action:Event_WitchKilled(Handle:event, const char[] name, bool:dontBroadcast)
{
	if (EnableAssist && EnableWitch && !EnableTankOnly)
	{
		new witch = GetClientOfUserId(GetEventInt(event, "witchid"));
		new witchCheck = GetEventInt(event,"witchid");
		new killer = GetClientOfUserId(GetEventInt(event, "userid"));
		int hitgroup = GetEventInt(event, "headshot");
		int type = GetEventInt(event, "type");
		if (IsValidEntity(witch) && IsValidEdict(witch))
		{
			if (GetEventBool(event, "oneshot"))
			{
				decl String:sName[MAX_NAME_LENGTH];
				GetClientName(killer, sName, sizeof(sName));
				PrintToChatAll("\x04Witch\x01 got Crowned by \x04%s.", sName);
				ClearDmgWitch();
			}
			else
			{
				new String:WMessage[256];
				new String:WMsgAssist[256];
				if (IsWitch(witchCheck))
				{
					decl String:killerName[MAX_NAME_LENGTH];
					GetClientName(killer, killerName, sizeof(killerName));
					decl String:killerDamage[10];
					IntToString(DamageWitch[killer][witch], String:killerDamage, sizeof(killerDamage));
					StrCat(String:WMessage, sizeof(WMessage), String:killerName);
					StrCat(String:WMessage, sizeof(WMessage), String:Temp6);
					StrCat(String:WMessage, sizeof(WMessage), String:Temp3);
					StrCat(String:WMessage, sizeof(WMessage), String:killerDamage);
					StrCat(String:WMessage, sizeof(WMessage), String:Temp4);

					for (new i = 0; i <= MAXPLAYERS; i++)
					{
						if (DamageWitch[i][witch] > 0)
						{
							if (i != killer)
							{
								WitchAssistFlag = true;
								decl String:AssistName[MAX_NAME_LENGTH];
								GetClientName(i, AssistName, sizeof(AssistName));
								decl String:AssistDamage[10];
								IntToString(DamageWitch[i][witch], String:AssistDamage, sizeof(AssistDamage));
								StrCat(String:WMsgAssist, sizeof(WMsgAssist), String:Temp5);
								StrCat(String:WMsgAssist, sizeof(WMsgAssist), String:AssistName);
								StrCat(String:WMsgAssist, sizeof(WMsgAssist), String:Temp6);
								StrCat(String:WMsgAssist, sizeof(WMsgAssist), String:Temp3);
								StrCat(String:WMsgAssist, sizeof(WMsgAssist), String:AssistDamage);
								StrCat(String:WMsgAssist, sizeof(WMsgAssist), String:Temp4);
								StrCat(String:WMsgAssist, sizeof(WMsgAssist), String:Temp2);
							}
						}
						DamageWitch[i][witch] = 0;
					}
					if (WitchAssistFlag == true) 
					{
						strcopy(String:WMsgAssist,strlen(WMsgAssist)-1,WMsgAssist);
						StrCat(String:WMessage, sizeof(WMessage), String:Temp1);
						StrCat(String:WMessage, sizeof(WMessage), String:WMsgAssist);
						WitchAssistFlag = false;
					}
					if (hitgroup == 1 && type != 8) // 8 == death by fire
					{  
						PrintToChatAll("\x04Witch\x01 killed by a \x05headshot\x01 from \x04%s.", WMessage);
					}
					else
					{
						PrintToChatAll("\x04Witch\x01 got killed by \x04%s.", WMessage);
					}
				}	
			}
			
		}
		else
			ClearDmgWitch();
	}
	return Plugin_Continue;
}

public Event_InfectedHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (EnableAssist && EnableWitch && !EnableTankOnly)
	{		
		new witch = GetEventInt(event, "entityid");		
		decl String:class[64];
		GetEdictClassname(witch, class, sizeof(class));
		if (!StrEqual(class, "witch", false)) return;
		new CWitch = GetClientOfUserId(GetEventInt(event, "entityid"));
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		if (IsValidClient(attacker, TEAM_SURVIVOR))
		{
			new damage = GetEventInt(event, "amount");
			DamageWitch[attacker][CWitch] += damage;			
		}
	}
}

ClearDmgWitch()
{	
	for (new i = 0; i <= MAXPLAYERS; i++)
		{
			for (new a = 1; a <= MAXPLAYERS; a++)
			{
				DamageWitch[i][a] = 0;
			}
		}
}
ClearAllDmg()
{
	for (new i = 0; i <= MAXPLAYERS; i++)
	{
		for (new a = 1; a <= MaxClients; a++)
		{
			Damage[i][a] = 0;
			DamageWitch[i][a] = 0;
		}
	}
}
public Action:Event_WitchHarasserSet(Handle: event, const String: name[], bool: dontBroadcast)
{
	if (EnableAssist && EnableWitch && !EnableTankOnly)
	{
		new target = GetClientOfUserId(GetEventInt(event, "userid"));
		decl String:alerter[MAX_NAME_LENGTH];
		GetClientName(target, alerter, sizeof(alerter));
		if (IsValidClient(target, TEAM_SURVIVOR))
		{
				PrintToChatAll("\x04%s\x01 Startled the \x03Witch", alerter);
		}
	}
}

public OnEntityDestroyed(entity) //escaped or burned
{
	if (EnableAssist && EnableWitch && !EnableTankOnly)
	{
		if (IsValidEntity(entity) && IsValidEdict(entity))
		{
			new String:class[64];
			GetEdictClassname(entity, class, sizeof(class));						
			if (StrEqual(class, "witch"))
			{
				ClearDmgWitch();
			}
		}
	}
}

stock bool:IsValidClient(client, team)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == team;
}

stock bool:IsClient(client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

stock bool:IsWitch(client)
{
	new String:class[64];
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

GetCvars()
{
	EnableAssist = cvarEnable.BoolValue;
	EnableWitch = cvarWitch.BoolValue;
	EnableTankOnly = cvarTank.BoolValue;
}

