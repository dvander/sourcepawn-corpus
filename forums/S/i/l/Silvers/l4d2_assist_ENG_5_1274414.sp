#include <sourcemod>
#include <colors>

#pragma semicolon 1

#define PLUGIN_VERSION "1.5"
#define ZOMBIECLASS_TANK 8

new Handle:cvarEnable;
new Handle:cvarTank;
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
    author = "[E]c & Max Chu & SilverShot",
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

		if (AssistFlag == true) {
			strcopy(String:MsgAssist,strlen(MsgAssist)-1,MsgAssist);
			StrCat(String:Message, sizeof(Message), String:Temp1);
			StrCat(String:Message, sizeof(Message), String:MsgAssist);
			AssistFlag = false;
		}

		decl String:victimModel[128];
		decl String:charName[32];
		decl String:victimName[64];
		GetClientName(victim, victimName, sizeof(victimName));
		GetClientModel(victim, victimModel, sizeof(victimModel));

		strcopy(charName, sizeof(charName), "Unknown");
		new const String:a_contains[10][] =
		{"Boomer","Boomette","Smoker","Hunter","Charger","Spitter","Jockey","Witch","Bride Witch","Tank"};
		new const String:b_contains[10][] =
		{"boomer","boomette","smoker","hunter","charger","spitter","jockey","witch","bride_witch","hulk"};
		new u;
		for (u = 0; u < 10; u++)
		{
			if(StrContains(victimModel, b_contains[u], false) > 0) {
				strcopy(charName, sizeof(charName), a_contains[u]);
			}
		}

		new String:TempName[32];
		new String:TempVictimName[32];
		strcopy(TempName, sizeof(TempName), charName);
		StrCat(TempVictimName, sizeof(TempVictimName), victimName);

		if (StrEqual(charName,"Boomette") && StrContains(TempVictimName, "Boomer",false) > -1) {
			strcopy(victimName, sizeof(victimName), "Boomette");
			strcopy(victimName, sizeof(victimName), "Boomette");
		}
		if (StrContains(victimName, charName, false) == -1) {//Names are different
			strcopy(charName, sizeof(charName), " (\x04");
			StrCat(String:charName, sizeof(charName), String:TempName);
			StrCat(String:charName, sizeof(charName), "\x01)");
		}else{
			strcopy(charName, sizeof(charName), "");
		}

		PrintToChatAll("\x04%s\x01%s got killed by \x04%s", victimName, charName, Message);
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