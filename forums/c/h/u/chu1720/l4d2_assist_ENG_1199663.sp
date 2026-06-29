#include <sourcemod>
#include <colors>

#pragma semicolon 1

#define PLUGIN_VERSION "1.5"
#define ZOMBIECLASS_TANK 8

new Handle:cvarEnable;
new Handle:cvarTank;

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
    author = "[E]c & Max Chu",
    description = "Show assists made by survivors",
    version = PLUGIN_VERSION,
    url = ""
}

public OnPluginStart()
{
	CreateConVar("sm_assist_version", PLUGIN_VERSION, "Assistance System Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarTank = CreateConVar("sm_assist_tank_only", "0", "Enables this will show only damage done to Tank.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarEnable = CreateConVar("sm_assist_enable", "1", "Enables this plugin.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookEvent("player_hurt", Event_Player_Hurt);
	HookEvent("player_death", Event_Player_Death);
	HookEvent("round_end", Event_Round_End);
	HookEvent("round_start", Event_Round_Start);
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
					StrCat(String:Message, sizeof(Message), String:Temp5);
					StrCat(String:Message, sizeof(Message), String:tName);
					StrCat(String:Message, sizeof(Message), String:Temp6);
					StrCat(String:Message, sizeof(Message), String:Temp3);
					StrCat(String:Message, sizeof(Message), String:tDamage);
					StrCat(String:Message, sizeof(Message), String:Temp4);
					StrCat(String:Message, sizeof(Message), String:Temp2);
				}
			}
			Damage[i][victim] = 0;
		}
		strcopy(String:Message,strlen(Message)-1,Message);
		
		decl String:victimModel[128];
		decl String:charName[32];
		GetClientModel(victim, victimModel, sizeof(victimModel));

		if(StrContains(victimModel, "boomer", false) > 0) 
		{
			strcopy(charName, sizeof(charName), "Boomer");
		}
		else if(StrContains(victimModel, "boomette", false) > 0) 
		{
			strcopy(charName, sizeof(charName), "Boomette");
		}
		else if(StrContains(victimModel, "smoker", false) > 0)
		{
			strcopy(charName, sizeof(charName), "Smoker");
		}
		else if(StrContains(victimModel, "hunter", false) > 0)
		{
			strcopy(charName, sizeof(charName), "Hunter");
		}
		else if(StrContains(victimModel, "charger", false) > 0)
		{
			strcopy(charName, sizeof(charName), "Charger");
		}
		else if(StrContains(victimModel, "spitter", false) > 0)
		{
			strcopy(charName, sizeof(charName), "Spitter");
		}
		else if(StrContains(victimModel, "jockey", false) > 0)
		{
			strcopy(charName, sizeof(charName), "Jockey");
		}
		else if(StrContains(victimModel, "witch", false) > 0)
		{
			strcopy(charName, sizeof(charName), "Witch");
		}
		else if(StrContains(victimModel, "witch_bride", false) > 0)
		{
			strcopy(charName, sizeof(charName), "Bride Witch");
		}
		else if(StrContains(victimModel, "hulk", false) > 0)
		{
			strcopy(charName, sizeof(charName), "Tank");
		}
		else{
			strcopy(charName, sizeof(charName), "Unknown");
		}
		PrintToChatAll("\x04%N\x01 (\x04%s\x01) got killed by \x04%s", victim, charName, Message);
	}
	}
	for (new i = 0; i <= MAXPLAYERS; i++)
	{
		Damage[i][victim] = 0;
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