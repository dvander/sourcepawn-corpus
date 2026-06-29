#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

public Plugin myinfo =
{
	name = "Show Damage Simple",
	author = "Ayrton09",
	description = "Simple and optimized showdamage.",
	version = "1.0.0",
	url = ""
};

public void OnPluginStart()
{
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if (!IsValidHumanClient(attacker) || !IsValidClient(victim))
	{
		return;
	}

	if (attacker == victim)
	{
		return;
	}

	if (GetClientTeam(attacker) == GetClientTeam(victim))
	{
		return;
	}

	int damage = event.GetInt("dmg_health");
	if (damage <= 0)
	{
		return;
	}

	PrintCenterText(attacker, "-%d HP", damage);
}

bool IsValidHumanClient(int client)
{
	return IsValidClient(client) && !IsFakeClient(client);
}

bool IsValidClient(int client)
{
	return client != 0 && IsClientInGame(client);
}
