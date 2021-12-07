#pragma semicolon 1

#include <sourcemod>

// Global Definitions
#define PLUGIN_VERSION "1.0.0"

new achievements[MAXPLAYERS][5];
new Handle:cvarMessage;
new Handle:cvarTime;

// Functions
public Plugin:myinfo =
{
	name = "Achievement Limiter",
	author = "bl4nk",
	description = "Bans clients who spam achievements",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	cvarMessage = CreateConVar("sm_achlimiter_message", "Achievement spamming", "Message to ban the client with", FCVAR_PLUGIN);
	cvarTime = CreateConVar("sm_achlimiter_time", "0", "Time to ban the client for (0 = permanent)", FCVAR_PLUGIN, true, 0.0);

	HookEvent("achievement_earned", event_AchievementEarned);
}

public bool:OnClientConnect(client)
{
	for (new i = 0; i < 5; i++)
	{
		achievements[client][i] = 0;
	}

	return true;
}

public event_AchievementEarned(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetEventInt(event, "player");
	new achievement = GetEventInt(event, "achievement");

	if (HasAchieved(client, achievement))
	{
		decl String:message[64];
		GetConVarString(cvarMessage, message, sizeof(message));

		BanClient(client, GetConVarInt(cvarTime), BANFLAG_AUTHID, message, message, "achlimiter");
	}
	else
	{
		new size = CountArraySize(client);
		switch (size)
		{
			case 1:
			{
				achievements[client][1] = achievements[client][0];
			}
			case 2:
			{
				achievements[client][2] = achievements[client][1];
				achievements[client][1] = achievements[client][0];
			}
			case 3:
			{
				achievements[client][3] = achievements[client][2];
				achievements[client][2] = achievements[client][1];
				achievements[client][1] = achievements[client][0];

			}
			case 4:
			{
				achievements[client][4] = achievements[client][3];
				achievements[client][3] = achievements[client][2];
				achievements[client][2] = achievements[client][1];
				achievements[client][1] = achievements[client][0];

			}
			case 5:
			{
				achievements[client][4] = achievements[client][3];
				achievements[client][3] = achievements[client][2];
				achievements[client][2] = achievements[client][1];
				achievements[client][1] = achievements[client][0];
			}
		}

		achievements[client][0] = achievement;
	}
}

HasAchieved(client, achievement)
{
	for (new i = 0; i < 5; i++)
	{
		if (achievements[client][i] == achievement)
		{
			return true;
		}
	}

	return false;
}

CountArraySize(client)
{
    new counter;
    for (new i = 0; i < 5; i++)
    {
        if (achievements[client][i] != 0)
            counter++;
    }

    return counter;
}