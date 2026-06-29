#pragma semicolon 1

#include <sourcemod>

#pragma newdecls required

public Plugin myinfo =
{
	name = "L4D2 0hp bug fix",
	author = "MixJay",
	description = "L4D2 bug fix, when survivors get 0 HP",
	version = "1.1",
	url = "http://mixjay.ru"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_0hp", Cmd_ZeroHP);

	HookEvent("player_falldamage", Event_FallDamage);
	HookEvent("player_hurt", Event_PlayerHurt);
}

bool SurvZeroHP(int &client)
{
	if (IsClientInGame(client))
	{
		if (GetClientTeam(client) == 2)
		{
			if (IsPlayerAlive(client))
			{
				if (GetEntProp(client, Prop_Send, "m_iHealth") == 0)
				{
					return true;
				}
			}
		}
	}
	return false;
}

public Action Cmd_ZeroHP(int client, int args)
{
	if (client > 0)
	{
		if (SurvZeroHP(client))
		{
			SetEntProp(client, Prop_Send, "m_iHealth", 1);
		}
	}
	return Plugin_Handled;
}

public Action Event_FallDamage(Event event, const char [] name, bool dontBroadcast)
{
	if (event.GetFloat("damage") < 1.0)
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		if (GetEntProp(client, Prop_Send, "m_iHealth") == 1)
		{
			if (GetEntPropFloat(client, Prop_Send, "m_healthBuffer") < 1.0)
			{
				CreateTimer(0.01, Timer_Fix, client, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	return Plugin_Continue;
}

public Action Timer_Fix(Handle timer, any client)
{
	if (SurvZeroHP(client))
	{
		SetEntProp(client, Prop_Send, "m_iHealth", 1);
	}
	return Plugin_Stop;
}

public Action Event_PlayerHurt(Event event, const char [] name, bool dontBroadcast)
{
	if (event.GetInt("health") == 0)
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		if (SurvZeroHP(client))
		{
			SetEntProp(client, Prop_Send, "m_iHealth", 1);
		}
	}
	return Plugin_Continue;
}