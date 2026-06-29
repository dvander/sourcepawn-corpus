#include <sourcemod>
#include <colors>

#pragma semicolon 1

#define PLUGIN_VERSION "1.6"
#define ZOMBIECLASS_TANK 8

new Handle:cvarEnable;
new Handle:cvarTank;
new Handle:cvarWitch;

new bool:AssistFlag;

new Damage[MAXPLAYERS+1][MAXPLAYERS+1];
new String:Temp1[] = " | Assist: ";
new String:Temp2[] = ", ";
new String:Temp3[] = " (";
new String:Temp4[] = " dmg)";
new String:Temp5[] = "\x04";
new String:Temp6[] = "\x01";

public Plugin:myinfo = 
{
	name = "L4D Assistance System",
	author = "[E]c & Max Chu, SilverS & ViRaGisTe",
	description = "Show assists made by survivors",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=123811"
}

public OnPluginStart()
{
	CreateConVar("sm_assist_version", PLUGIN_VERSION, "Assistance System Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarTank = CreateConVar("sm_assist_tank_only", "0", "Enables this will show only damage done to Tank.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarWitch = CreateConVar("sm_crown_witch", "0", "Enables this will show if a player one-shot-killed the witch", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarEnable = CreateConVar("sm_assist_enable", "1", "Enables this plugin.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookEvent("player_hurt", Event_Player_Hurt);
	HookEvent("player_death", Event_Player_Death);
	HookEvent("round_end", Event_Round_End);
	HookEvent("round_start", Event_Round_Start);
	HookEvent("witch_killed", Event_Witch_Death);
	
	AutoExecConfig(true, "l4d2_assist");
}

public Action:Event_Round_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(cvarEnable))
	{
		for (new i = 0; i <= MAXPLAYERS; i++)
		{
			for (new a = 1; a <= MAXPLAYERS; a++)
			{
				Damage[i][a] = 0;
			}
		}
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

				PrintToChatAll("\x04%N\x01 got killed by \x04%s.", victim, Message);
			}
		}
		for (new i = 0; i <= MAXPLAYERS; i++)
		{
			Damage[i][victim] = 0;
		}
	}
	return Plugin_Continue;
}

public Action:Event_Witch_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(cvarEnable))
	{
		new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
		new Crownd   = GetEventBool(event,"oneshot");
		if (GetConVarInt(cvarWitch) && (Crownd==1))
		{
			PrintToChatAll("\x04%N\x01 cr0wn'd \x04The Witch.", attacker);
		}
	}
	return Plugin_Continue;
}

public Action:Event_Round_End(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(cvarEnable))
	{
		for (new i = 0; i <= MAXPLAYERS; i++)
		{
			for (new a = 1; a <= MAXPLAYERS; a++)
			{
				Damage[i][a] = 0;
			}
		}
	}
}