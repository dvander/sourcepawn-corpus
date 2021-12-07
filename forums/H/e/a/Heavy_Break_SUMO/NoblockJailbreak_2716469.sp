#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <cstrike>

#define cDefault 0x01
#define cLightGreen 0x03
#define cGreen 0x04
#define cDarkGreen 0x05

#define PLUGIN_VERSION "1.4.2"

// Uncomment for debugging
#define DEBUG 1

public Plugin:myinfo = 
{
    name = "Noblock Jailbreak",
    author = "Heavy Break Server modifying Otstrel.ru Team's plugin",
    description = "CT team can use a command to enable or disable all player collisions.",
    version = PLUGIN_VERSION,
    url = "http://otstrel.ru  AND  http://steamcommunity.com/groups/heavy_break/"
};

// ===========================================================================
// GLOBALS
// ===========================================================================

new g_offsCollisionGroup;
new bool:g_enabled;

new Handle:sm_nb;
new Handle:g_hTimer[MAXPLAYERS+1];

// ===========================================================================
// LOAD & UNLOAD
// ===========================================================================

public OnPluginStart()
{
    #if defined DEBUG
        LogError("[DEBUG] Plugin started.");
    #endif
    
    new Handle:Cvar_Version = CreateConVar("sm_noblock_version", PLUGIN_VERSION,    "NoBlock Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    /* Just to make sure they it updates the convar version if they just had the plugin reload on map change */
    SetConVarString(Cvar_Version, PLUGIN_VERSION);
    
    g_offsCollisionGroup = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
    if (g_offsCollisionGroup == -1)
    {
        SetFailState("[NoBlock] Failed to get offset for CBaseEntity::m_CollisionGroup.");
    }
    
    sm_nb = CreateConVar("sm_nb", "1", "Removes player vs. player collisions.");
    g_enabled = GetConVarBool(sm_nb);
    HookConVarChange(sm_nb, OnConVarChange);
    HookEvent("round_end", onRoundEnd);
    
    RegConsoleCmd("sm_nb", Command_nb, "Enable or disable all players collisions.");

}

// ===========================================================================
// EVENTS
// ===========================================================================

public OnConVarChange(Handle:hCvar, const String:oldValue[], const String:newValue[])
{
    #if defined DEBUG
        LogError("[DEBUG] Cvar changed.");
    #endif
    if ( hCvar == sm_nb ) {
        g_enabled = GetConVarBool(sm_nb);
        if ( g_enabled ) {
            UnblockClientAll();
        } else {
            BlockClientAll();
        }
        return;
    }

}


public Action Command_nb(int client, int args)
{

	if(GetClientTeam(client) != CS_TEAM_CT)
	{
		ReplyToCommand(client, "Only CT team can use this command.");
		return Plugin_Continue;
	}

	if(GetClientTeam(client) == CS_TEAM_CT && IsPlayerAlive(client) && g_enabled)
	{
		UnblockClientAll();
		PrintToChat(client, "Collisions between players has been enabled.");
		g_enabled = false;
		return Plugin_Continue;
		
	} else {
	
		if (GetClientTeam(client) == CS_TEAM_CT && IsPlayerAlive(client)) 
		{
			BlockClientAll();
			PrintToChat(client, "Collisions between players has been disabled.");
			g_enabled = true;
			return Plugin_Continue;
	
		} else {
	
			if (GetClientTeam(client) == CS_TEAM_CT) {
		
				ReplyToCommand(client, "You have to be alive to use this command.");
				return Plugin_Continue;				

			}	
	
		}
		
	}

	return Plugin_Continue;

}


public OnSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    #if defined DEBUG
        LogError("[DEBUG] Player spawned.");
    #endif

    new userid = GetEventInt(event, "userid");
    new client = GetClientOfUserId(userid);
    #if defined DEBUG
        LogError("[DEBUG] ... player %i.", client);
    #endif
    if ( g_hTimer[client] != INVALID_HANDLE )
    {
        CloseHandle(g_hTimer[client]);
        g_hTimer[client] = INVALID_HANDLE;
        PrintToChat(client, "%c[NoBlock] %cBlocking has been Disabled because of respawn", cLightGreen, cDefault);
    }

    UnblockEntity(client);
    
}

public Action:onRoundEnd(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{

	g_enabled = true;

}	



// ===========================================================================
// HELPERS
// ===========================================================================


BlockEntity(client)
{
    #if defined DEBUG
        LogError("[DEBUG] BLOCK client %i.", client);
    #endif
    SetEntData(client, g_offsCollisionGroup, 5, 4, true);
}

UnblockEntity(client)
{
    #if defined DEBUG
        LogError("[DEBUG] UNBLOCK client %i.", client);
    #endif
    SetEntData(client, g_offsCollisionGroup, 2, 4, true);
}

BlockClientAll()
{
    #if defined DEBUG
        LogError("[DEBUG] Block all.");
    #endif
    for (new i = 1; i <= MaxClients; i++)
    {
        if ( IsClientInGame(i) && IsPlayerAlive(i) )
        {
            BlockEntity(i);
        }
    }
}

UnblockClientAll()
{
    #if defined DEBUG
        LogError("[DEBUG] Unblock all.");
    #endif
    for (new i = 1; i <= MaxClients; i++)
    {
        if ( IsClientInGame(i) && IsPlayerAlive(i) )
        {
            UnblockEntity(i);
        }
    }
}

