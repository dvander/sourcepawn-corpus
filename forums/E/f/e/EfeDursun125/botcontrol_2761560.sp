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

public Plugin myinfo =
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
	if (GetRandomInt(1, 3) == 1)
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		PrintToChat(client, "\x04You can take over a bot by pressing your use key while spectating a bot!");
	}
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
    int iTarget, iSpecMode, iFrags, iDeaths;
    float teleportDestination[3];
    float anglesDestination[3];
    float velocityDestination[3];
	
    if((buttons & IN_USE))
    {
        if(!IsPlayerAlive(client) && !IsFakeClient(client) && IsClientInGame(client))
        {
            iSpecMode = GetEntProp(client, Prop_Send, "m_iObserverMode");
            if (iSpecMode != SPECMODE_FIRSTPERSON && iSpecMode != SPECMODE_THIRDPERSON)
                return Plugin_Continue;
				
            iTarget = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
            if(!IsFakeClient(iTarget))
                return Plugin_Continue;
				
            if(!IsPlayerAlive(iTarget))
                return Plugin_Continue;
				
            if(GetClientTeam(iTarget) != GetClientTeam(client))
                return Plugin_Continue;
				
            CS_RespawnPlayer(client);
            GetClientAbsOrigin(iTarget, teleportDestination);
            teleportDestination[2] = teleportDestination[2] + 9;
            GetClientAbsAngles(iTarget, anglesDestination);
            GetEntPropVector(iTarget, Prop_Data, "m_vecVelocity", velocityDestination);
            TeleportEntity(client, teleportDestination, anglesDestination, velocityDestination);
			
			SetEntityHealth(client, GetClientHealth(iTarget));
			SetEntProp(client, Prop_Send, "m_ArmorValue", GetEntProp(iTarget, Prop_Send, "m_ArmorValue"));
			SetEntProp(client, Prop_Send, "m_bHasHelmet", GetEntProp(iTarget, Prop_Send, "m_bHasHelmet"));
			
            iFrags = GetClientFrags(iTarget);
            iDeaths = GetClientDeaths(iTarget);
            ForcePlayerSuicide(iTarget);
            RemoveBody(iTarget);
            SetEntProp(iTarget, Prop_Data, "m_iFrags", iFrags);
            SetEntProp(iTarget, Prop_Data, "m_iDeaths", iDeaths);
			
			int iAccount = FindSendPropInfo("CCSPlayer", "m_iAccount");
			if (iAccount != -1 && GetEntData(client, iAccount) >= 2000)
				SetEntData(client, iAccount, GetEntData(client, iAccount) + 2000);
        }
    }
	
    return Plugin_Continue;
}

stock void RemoveBody(int client)
{
	int BodyRagdoll = -1;
	char Classname[64];
	
	BodyRagdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if(IsValidEdict(BodyRagdoll))
	{
		GetEdictClassname(BodyRagdoll, Classname, sizeof(Classname)); 
		if(StrEqual(Classname, "cs_ragdoll", false))
            RemoveEdict(BodyRagdoll);
	}
}