#pragma semicolon 1

#include <cstrike>
#include <sdktools>
#include <sourcemod>

// SPECTATOR MODES

#define SPECMODE_NONE           0
#define SPECMODE_FIRSTPERSON    4
#define SPECMODE_THIRDPERSON    5
#define SPECMODE_FREELOOK       6

// PLUGIN INFORMATION

#define PLUGIN_NAME "CS:S Bot Control"
#define PLUGIN_AUTHOR "Adam Short"
#define PLUGIN_DESCRIPTION "Hacky way to 'control' bots, similar to CS:GO"
#define PLUGIN_VERSION "1.1.0"
#define PLUGIN_URL "https://gamepunch.net"

public Plugin:myinfo =
{
    name = PLUGIN_NAME,
    author = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version = PLUGIN_VERSION,
    url = PLUGIN_URL
}

public void OnPluginStart()
{
    HookEvent("player_death", Event_PlayerDeath);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{

    new client = GetClientOfUserId(GetEventInt(event, "userid"));

    PrintToChat(client, "\x04You can take over a bot by pressing your use key while spectating a bot!");

}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
    new iTarget, iSpecMode, iFrags, iDeaths;
    float teleportDestination[3];
    float anglesDestination[3];
    float velocityDestination[3];

    // If the player is using the use key
    if((buttons & IN_USE))
    {
        // Make sure the player is dead
        if(!IsPlayerAlive(client))
        {
            iSpecMode = GetEntProp(client, Prop_Send, "m_iObserverMode");
            // If the client is not spectating anyone, ignore
            if (iSpecMode != SPECMODE_FIRSTPERSON && iSpecMode != SPECMODE_THIRDPERSON)
                return Plugin_Continue;

            // Get the target
            iTarget = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");


            // Make sure the player is a bot
            if(!IsFakeClient(iTarget))
                return Plugin_Continue;

            // Make sure the target is alive
            if(!IsPlayerAlive(iTarget))
                return Plugin_Continue;

            // Make sure they are on the same team
            if(GetClientTeam(iTarget) != GetClientTeam(client))
                return Plugin_Continue;


            CS_RespawnPlayer(client);

            GetClientAbsOrigin(iTarget, teleportDestination);
            teleportDestination[2] = teleportDestination[2] + 16;
            GetClientAbsAngles(iTarget, anglesDestination);
            GetEntPropVector(iTarget, Prop_Data, "m_vecVelocity", velocityDestination);
            TeleportEntity(client, teleportDestination, anglesDestination, velocityDestination);

            // Kill the bot, clean it up
            iFrags = GetClientFrags(iTarget);
            iDeaths = GetClientDeaths(iTarget);
            ForcePlayerSuicide(iTarget);
            RemoveBody(iTarget);
            SetEntProp(iTarget, Prop_Data, "m_iFrags", iFrags);
            SetEntProp(iTarget, Prop_Data, "m_iDeaths", iDeaths);

        }

    }
    return Plugin_Continue;

}

//Body:
stock RemoveBody(client)
{

	//Declare:
	decl BodyRagdoll;
	decl String:Classname[64];

	//Initialize:
	BodyRagdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if(IsValidEdict(BodyRagdoll))
	{
	
		//Find:
		GetEdictClassname(BodyRagdoll, Classname, sizeof(Classname)); 

		//Remove:
		if(StrEqual(Classname, "cs_ragdoll", false))
            RemoveEdict(BodyRagdoll);
	}
}