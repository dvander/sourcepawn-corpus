#include <sourcemod> 
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = { 
    name = "[L4D, L4D2] No Death Check Until Dead", 
    author = "chinagreenelvis, edit by Eyal282", 
    description = "Prevents mission loss until all players have died.", 
    version = "1.5.6", 
    url = "https://forums.alliedmods.net/showthread.php?t=142432" 
}; 

Handle deathcheck = INVALID_HANDLE;
Handle deathcheck_bots = INVALID_HANDLE;
Handle director_no_death_check = INVALID_HANDLE;
Handle allow_all_bot_survivor_team = INVALID_HANDLE;

int director_no_death_check_default_cvar = 0;
int allow_all_bot_survivor_team_default_cvar = 0;
bool Enabled = false;

public void OnPluginStart()
{  
    deathcheck = CreateConVar("deathcheck_incap_is_standing", "1", "0: Mission will be lost if all survivors are incapped, 1: Mission will continue until all humans ", FCVAR_SPONLY|FCVAR_NOTIFY);
    deathcheck_bots = CreateConVar("deathcheck_bots_are_humans", "1", "0: Mission will be lost if all human players have died, 1: Mission will continue until all surivovrs have died.", FCVAR_SPONLY|FCVAR_NOTIFY);
    
    director_no_death_check = FindConVar("director_no_death_check");
    allow_all_bot_survivor_team = FindConVar("allow_all_bot_survivor_team");

    AutoExecConfig(true, "l4d2_deathcheck_final");
    
    HookConVarChange(deathcheck, ConVarChange_deathcheck);
    HookConVarChange(deathcheck_bots, ConVarChange_deathcheck_bots);
    
    HookEvent("player_first_spawn", Event_PlayerFirstSpawn);
    HookEvent("player_spawn", Event_PlayerFirstSpawn);
    HookEvent("player_bot_replace", Event_PlayerBotReplace); 
    HookEvent("bot_player_replace", Event_BotPlayerReplace); 
    HookEvent("player_team", Event_PlayerTeam);
    HookEvent("player_death", Event_PlayerDeath);
    
    Enabled = false;
}

public void OnConfigsExecuted()
{
    director_no_death_check_default_cvar = GetConVarInt(director_no_death_check);
    allow_all_bot_survivor_team_default_cvar = GetConVarInt(allow_all_bot_survivor_team);
}

public void ConVarChange_deathcheck(Handle convar, const char[] oldValue, const char[] newValue)
{
    if (strcmp(oldValue, newValue) != 0)
    {
        if (strcmp(newValue, "1") == 0)
        {
            //PrintToChatAll("Setting director_no_death_check to 1.");
            SetConVarInt(director_no_death_check, 1);
            if (GetConVarInt(deathcheck_bots) == 1)
            {
                //PrintToChatAll("Setting allow_all_bot_survivor_team to 1.");
                SetConVarInt(allow_all_bot_survivor_team, 1);
            }
            else
            {
                //PrintToChatAll("Resetting allow_all_bot_survivor_team to default value.");
                SetConVarInt(allow_all_bot_survivor_team, allow_all_bot_survivor_team_default_cvar);
            }
        }
        else
        {
            //PrintToChatAll("Resetting director_no_death_check and allow_all_bot_survivor_team to default values.");
            SetConVarInt(director_no_death_check, director_no_death_check_default_cvar);
            SetConVarInt(allow_all_bot_survivor_team, allow_all_bot_survivor_team_default_cvar);
        }
    }
}

public void ConVarChange_deathcheck_bots(Handle convar, const char[] oldValue, const char[] newValue)
{
    if (GetConVarInt(deathcheck) == 1)
    {
        if (strcmp(oldValue, newValue) != 0)
        {
            if (strcmp(newValue, "1") == 0)
            {
                //PrintToChatAll("Setting allow_all_bot_survivor_team to 1.");
                SetConVarInt(allow_all_bot_survivor_team, 1);
            }
            else
            {
                //PrintToChatAll("Resetting allow_all_bot_survivor_team to default value.");
                SetConVarInt(allow_all_bot_survivor_team, allow_all_bot_survivor_team_default_cvar);
            }
        }
    }
}

public void OnMapEnd()
{
    if (Enabled == true)
    {
        Enabled = false;
    }
}

public void OnClientDisconnect()
{ 
    DeathCheck();
}

public void OnClientDisconnect_Post()
{
    DeathCheck();
}

public Action Event_PlayerFirstSpawn(Handle event, const char[] name, bool dontBroadcast)  
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if (IsClientInGame(client) && !IsFakeClient(client))
    {
        if (Enabled == false)
        {
            if (GetConVarInt(deathcheck) == 1)
            {
                SetConVarInt(director_no_death_check, 1);
                if (GetConVarInt(deathcheck_bots) == 1)
                {
                    SetConVarInt(allow_all_bot_survivor_team, 1);
                }
            }
            Enabled = true;
        }
    }

    return Plugin_Continue;
}  

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)  
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    
    if (IsClientInGame(client) && !IsFakeClient(client))
    {
        if (Enabled == false)
        {
            if (GetConVarInt(deathcheck) == 1)
            {
                SetConVarInt(director_no_death_check, 1);
                if (GetConVarInt(deathcheck_bots) == 1)
                {
                    SetConVarInt(allow_all_bot_survivor_team, 1);
                }
            }
            Enabled = true;
        }
    }
    
    return Plugin_Continue;
} 

public Action Event_PlayerBotReplace(Handle event, const char[] name, bool dontBroadcast)  
{  
    DeathCheck();

    return Plugin_Continue;
}  

public Action Event_BotPlayerReplace(Handle event, const char[] name, bool dontBroadcast)  
{  
    DeathCheck();

    return Plugin_Continue;
}  

public Action Event_PlayerTeam(Handle event, const char[] name, bool dontBroadcast)  
{  
    DeathCheck();

    return Plugin_Continue;
}  

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)  
{
    DeathCheck();

    return Plugin_Continue;
}

void DeathCheck()
{
    if (Enabled == true)
    {
        // Give time for some insane revive plugin to go through?
        CreateTimer(0.2, Timer_DeathCheck);
    }
}

public Action Timer_DeathCheck(Handle timer)
{
    if (GetConVarInt(deathcheck) == 1)
    {
        int survivors = 0;

        for (int i = 1; i <= MaxClients; i++) 
        {
            if (IsValidSurvivor(i))
            {
                survivors ++;
            }
        }
        
        //PrintToChatAll("%i survivors remaining.", survivors);
        
        if (survivors < 1)
        {
            SetConVarInt(director_no_death_check, 0);
        }
        else
        {
            SetConVarInt(director_no_death_check, 1);
        }
    }

    return Plugin_Continue;
}

stock bool IsValidSurvivor(int client)
{
    if (!client) return false;

    if (!IsClientInGame(client)) return false;

    if (GetConVarInt(deathcheck_bots) == 0)
    {
        if (IsFakeClient(client))
            return false;
    }

    if (!IsPlayerAlive(client))
        return false;

    if (GetClientTeam(client) != 2) 
        return false;

    return true;
}