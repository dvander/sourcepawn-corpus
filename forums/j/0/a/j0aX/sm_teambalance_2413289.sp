#pragma semicolon 1

//#define SM_TEAMBALANCE_DEBUG 1

#define TEAM_NONE 0
#define TEAM_SPEC 1
#define TEAM_T 2
#define TEAM_CT 3

#include <cstrike>
#include <sourcemod>
#include <sdktools>

new g_Tcount, g_CTcount;
new bool:g_balance;
new bool:g_isHooked;
new Handle:sm_teambalance_enabled;

public Plugin:myinfo = 
{
    name = "Team Balance",
    author = "Otstrel.ru Team",
    description = "Team Balance for SourceMod.",
    version = "1.2",
    url = "http://otstrel.ru"
};

public OnPluginStart()
{
	//Create ConVars...
	sm_teambalance_enabled = CreateConVar("sm_teambalance_enabled", "1", "Sets whether teambalance is enabled");
	HookConVarChange(sm_teambalance_enabled, OnEnableVarChange);
	
	if((GetConVarInt(sm_teambalance_enabled)) == 1) {
		HookEvent("player_death", Event_PlayerDeath);
		HookEvent("player_team", Event_PlayerTeam);
		g_isHooked = true;
	} else {
		g_isHooked = false;
	}
}
public OnEnableVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new value = !!StringToInt(newValue);
	if(value == 0) {
		if(g_isHooked == true) {
			UnhookEvent("player_death", Event_PlayerDeath);
			UnhookEvent("player_team", Event_PlayerTeam);
			g_isHooked = false;
		}
	} else {
		if(g_isHooked == false) {
			HookEvent("player_death", Event_PlayerDeath);
			HookEvent("player_team", Event_PlayerTeam);
			g_isHooked = true;
		}
	}
}

public OnMapStart()
{
		g_Tcount = 0;
		g_CTcount = 0;
		for ( new i = 1; i <= MaxClients; i++ )
		{
			if ( IsClientInGame(i) )
			{
				ChangeTeamCount(GetClientTeam(i), 1);
			}
		}

		CheckBalance();
}

public Action:Event_PlayerDeath(Handle:event,const String:name[],bool:dontBroadcast)
{
    if ( g_balance )
    {
        return;
    }
    new killer = GetClientOfUserId(GetEventInt(event, "killer"));
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if ( client == killer || IsFakeClient(client) )
    {
        return;
    }
    new team = GetClientTeam(client);
    if ( team != TEAM_T && team != TEAM_CT )
    {
        return;
    }
    if ( team != ( (g_Tcount > g_CTcount) ? TEAM_T : TEAM_CT ) )
    {
        return;
    }
    team = team == TEAM_T ? TEAM_CT : TEAM_T;
    
    #if defined SM_TEAMBALANCE_DEBUG
        LogError("[DEBUG] ChangeClientTeam(client = %i, team = %i)", client, team);
    #endif
    new Handle:pack = CreateDataPack();
    WritePackCell(pack, client);
    WritePackCell(pack, team);
    CreateTimer(0.1, Timer_ChangeClientTeam, pack);
}

public Action:Timer_ChangeClientTeam(Handle:timer, any:pack)
{
    ResetPack(pack);
    new client = ReadPackCell(pack);
    new team = ReadPackCell(pack);
    CloseHandle(pack);
    ChangeClientTeam(client, team);
}
    
public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
    new oldTeam         = GetEventInt(event, "oldteam");
    new newTeam         = GetEventInt(event, "team");
    new bool:disconnect = GetEventBool(event, "disconnect");

    ChangeTeamCount(oldTeam, -1);

    /* Player disconnected and didn't join a new team */
    if ( !disconnect ) {
        ChangeTeamCount(newTeam, 1);
    }

    CheckBalance();
}

CheckBalance()
{
    new diff = g_Tcount - g_CTcount;
    if ( diff < 0 ) diff = -diff;
    g_balance = diff <= 1;
    #if defined SM_TEAMBALANCE_DEBUG
        LogError("[DEBUG] Balance = %i", g_balance);
    #endif
}

ChangeTeamCount(team, diff)
{
    switch ( team ) {
        case TEAM_T: {
            g_Tcount += diff;
        }
        case TEAM_CT: {
            g_CTcount += diff;
        }
    }
}


