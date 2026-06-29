#include <sourcemod>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

new Damage[MAXPLAYERS+1][MAXPLAYERS+1];
new String:Temp1[] = " | Assist: ";
new String:Temp2[] = ", ";
new String:Temp3[] = " (";
new String:Temp4[] = " damage)";

public Plugin:myinfo = 
{
    name = "L4D Assistance System",
    author = "[E]c",
    description = "Show assists made by survivors",
    version = PLUGIN_VERSION,
    url = ""
}

public OnPluginStart()
{
	CreateConVar("sm_crit", PLUGIN_VERSION, "Critical Shot Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	HookEvent("player_hurt", Event_Player_Hurt);
	HookEvent("player_death", Event_Player_Death);
	HookEvent("round_end", Event_Round_End);
	HookEvent("round_start", Event_Round_Start);
}

public Action:Event_Round_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 0; i <= MAXPLAYERS; i++)
	{
		for (new a = 1; a <= MAXPLAYERS; a++)
		{
			Damage[i][a] = 0;
		}
	}
}

public Action:Event_Player_Hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
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
	return Plugin_Continue;
}

public Action:Event_Player_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	new String:Message[256];
	
	if (GetClientTeam(victim) == 3 && GetClientTeam(attacker) != 3)
	{
		decl String:sName[MAX_NAME_LENGTH];
		GetClientName(attacker, sName, sizeof(sName));
		decl String:sDamage[10];
		IntToString(Damage[attacker][victim], String:sDamage, sizeof(sDamage));
		StrCat(String:Message, sizeof(Message), String:sName);
		StrCat(String:Message, sizeof(Message), String:Temp3);
		StrCat(String:Message, sizeof(Message), String:sDamage);
		StrCat(String:Message, sizeof(Message), String:Temp4);

		StrCat(String:Message, sizeof(Message), String:Temp1);
		for (new i = 0; i <= MAXPLAYERS; i++)
		{
			if (Damage[i][victim] > 0)
			{
				if (i != attacker)
				{
					decl String:tName[MAX_NAME_LENGTH];
					GetClientName(i, tName, sizeof(tName));
					decl String:tDamage[10];
					IntToString(Damage[i][victim], String:tDamage, sizeof(tDamage));
					StrCat(String:Message, sizeof(Message), String:tName);
					StrCat(String:Message, sizeof(Message), String:Temp3);
					StrCat(String:Message, sizeof(Message), String:tDamage);
					StrCat(String:Message, sizeof(Message), String:Temp4);
					if (i != MAXPLAYERS)
					{
						StrCat(String:Message, sizeof(Message), String:Temp2);
					}
				}
			}
			Damage[i][victim] = 0;
		}
		PrintToChatAll("%N got killed by %s", victim, Message);
	}
	return Plugin_Continue;
}

public Action:Event_Round_End(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 0; i <= MAXPLAYERS; i++)
	{
		for (new a = 1; a <= MAXPLAYERS; a++)
		{
			Damage[i][a] = 0;
		}
	}
}