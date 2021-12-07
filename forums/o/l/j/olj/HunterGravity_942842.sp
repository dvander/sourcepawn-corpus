#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>
//#include <funcommands>
//#include "funcommands/gravity.sp"

#define PLUGIN_VERSION "1"
#define DEBUG 0
#define TEAM_INFECTED 3

new hungrav             = 500;
new normgrav            = 800;
new bool:DecreasedGravity[MAXPLAYERS+1];

public Plugin:myinfo =
{
    name = "L4D hunter grav",
    author = "gendoakari",
    description = "when ever a hunter spawns change the gravity value",
};

public OnPluginStart()
{
		HookEvent("player_spawn", evtInfectedSpawn);
		HookEvent("player_team", evtTeamSwitch);
		HookEvent("round_end", evtRoundEnd);
}

public Action:evtInfectedSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
		new userID = GetEventInt(event,"userid");
		new client = GetClientOfUserId(userID);
		if (GetClientTeam(client) == TEAM_INFECTED)
			{
				if (client && !IsFakeClient(client)) 
					{
						decl String:Class[100];
						GetClientModel(client, Class, sizeof(Class));
						if (StrContains(Class, "hunter", false) != -1) 
							{
								ServerCommand("sm_gravity #%i %i", userID, hungrav);
								DecreasedGravity[client] = true;
							}
						else
							{
								if (DecreasedGravity[client])
									{
										ServerCommand("sm_gravity #%i %i", userID, normgrav);
										DecreasedGravity[client] = false;
									}
							}
					}
        	}
}

public Action:evtTeamSwitch(Handle:event, const String:name[], bool:dontBroadcast)
{
		new userID = GetEventInt(event,"userid");
		new client = GetClientOfUserId(userID);
		new team = GetEventInt(event, "team");
		if (team != 3)
			{
				if (client && !IsFakeClient(client)) 
					{
						if (DecreasedGravity[client]) 
							{
								ServerCommand("sm_gravity #%i %i", userID, normgrav);
								DecreasedGravity[client] = false;
							}
            		}
        	}
}

public Action:evtRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    for (new i = 1; i < MaxClients; i++) 
		{
			if (DecreasedGravity[i])
				{
					new userID = GetClientUserId(i);
					ServerCommand("sm_gravity #%i %i", userID, normgrav);
					DecreasedGravity[i] = false;
				}
		}
}