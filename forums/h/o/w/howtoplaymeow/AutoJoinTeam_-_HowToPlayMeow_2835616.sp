#include <sourcemod>
#include <tf2> 
#include <sdktools>

// ConVars
ConVar g_cvEnabled;
ConVar g_cvRemoveAmmoPack;
ConVar g_cvRemoveWeapons;
ConVar g_cvRemoveRagdoll;
ConVar g_cvLockTeam;
Handle g_hTeamJoinCvar = null;

public Plugin myinfo =
{
    name = "Auto Join Team",
    author = "HowToPlayMeow",
    description = "Bot Team Blue, Player Team Red",
    version = "2.1",
    url = "https://forums.alliedmods.net/showthread.php?t=350752"
};

public void OnPluginStart()
{
    // Plugin ConVars
    g_cvEnabled = CreateConVar("sm_autojointeam_enabled", "1", "Auto Join Team  (0 = Disabled, 1 = Enabled)", FCVAR_PROTECTED|FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvRemoveAmmoPack = CreateConVar("sm_autojointeam_remove_ammopack", "1", "Remove Ammo Pack (0 = Disabled, 1 = Enabled)", FCVAR_PROTECTED|FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvRemoveWeapons = CreateConVar("sm_autojointeam_remove_weapons", "1", "Remove Dropped Weapons (0 = Disabled, 1 = Enabled)", FCVAR_PROTECTED|FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvRemoveRagdoll = CreateConVar("sm_autojointeam_remove_ragdoll", "1", "Remove Corpse (0 = Disabled, 1 = Enabled)", FCVAR_PROTECTED|FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvLockTeam = CreateConVar("sm_autojointeam_lockedteam", "1", "Unable To Change Team (0 = Unlocked, 1 = locked Teams)", FCVAR_PROTECTED|FCVAR_NOTIFY, true, 0.0, true, 1.0);
    
    // Hooks
    g_cvLockTeam.AddChangeHook(OnLockTeamChanged);
    g_cvEnabled.AddChangeHook(OnConVarChanged);
    
    // Get team join ConVar
    g_hTeamJoinCvar = FindConVar("mp_humans_must_join_team");
    if (g_hTeamJoinCvar == null)
    {
        SetFailState("Failed to find mp_humans_must_join_team convar");
    }
    
    // Events
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("post_inventory_application", Event_PostInventory);
    
    AutoExecConfig(true, "autojointeam");
    ApplyTeamLock();
}

public void OnPluginEnd()
{
    if (g_hTeamJoinCvar != null)
    {
        CloseHandle(g_hTeamJoinCvar);
        g_hTeamJoinCvar = null;
    }
}

bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client));
}

void ApplyTeamLock()
{
    if (g_cvLockTeam.BoolValue)
    {
        SetConVarString(g_hTeamJoinCvar, "red");
        
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsValidClient(i))
            {
                int team = GetClientTeam(i);
                if (team != 1)
                {
                    if (IsFakeClient(i))
                    {
                        if (team != 3)
                        {
                            CreateTimer(0.1, Timer_ChangeTeamToBlue, GetClientUserId(i));
                        }
                    }
                    else if (team != 2)
                    {
                        CreateTimer(0.1, Timer_ChangeTeamToRed, GetClientUserId(i));
                    }
                }
            }
        }
    }
    else
    {
        SetConVarString(g_hTeamJoinCvar, "any");
    }
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (g_cvEnabled.BoolValue)
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsValidClient(i))
            {
                CheckAndAssignTeam(i);
            }
        }
    }
}

public void OnLockTeamChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    ApplyTeamLock();
}

void CheckAndAssignTeam(int client)
{
    if (!IsValidClient(client))
        return;
        
    int team = GetClientTeam(client);
    
    if (team == 1)
        return;
        
    if (IsFakeClient(client))
    {
        if (team != 3)
        {
            CreateTimer(0.1, Timer_ChangeTeamToBlue, GetClientUserId(client));
        }
    }
    else if (g_cvLockTeam.BoolValue)
    {
        if (team != 2)
        {
            CreateTimer(0.1, Timer_ChangeTeamToRed, GetClientUserId(client));
        }
    }
    else if (team == 3)
    {
        CreateTimer(0.1, Timer_ChangeTeamToRed, GetClientUserId(client));
    }
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_cvEnabled.BoolValue || event == null)
        return;
        
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!IsValidClient(client) || !IsPlayerAlive(client))
        return;
        
    CheckAndAssignTeam(client);
    RemoveDroppedItems();
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    if (event == null)
        return;
        
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!IsValidClient(client))
        return;
        
    if (g_cvRemoveRagdoll.BoolValue)
    {
        CreateTimer(0.1, Timer_RemoveRagdoll, GetClientUserId(client));
    }
    
    RemoveDroppedItems();
}

public void Event_PostInventory(Event event, const char[] name, bool dontBroadcast)
{
    if (event == null)
        return;
        
    RemoveDroppedItems();
}

public Action Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_cvEnabled.BoolValue || event == null)
        return Plugin_Continue;
        
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!IsValidClient(client))
        return Plugin_Continue;
        
    int newTeam = GetEventInt(event, "team");
    
    if (newTeam == 1)
        return Plugin_Continue;
        
    if (g_cvLockTeam.BoolValue)
    {
        if (IsFakeClient(client))
        {
            if (newTeam != 3)
                return Plugin_Handled;
        }
        else
        {
            if (newTeam != 2)
                return Plugin_Handled;
        }
    }
    
    return Plugin_Continue;
}

public Action Timer_ChangeTeamToBlue(Handle timer, any data)
{
    if (timer == null)
        return Plugin_Stop;
        
    int client = GetClientOfUserId(data);
    if (IsValidClient(client))
    {
        if (g_cvRemoveRagdoll.BoolValue)
        {
            RemoveRagdoll(client);
        }
        
        ChangeClientTeam(client, 3);
        TF2_RespawnPlayer(client);
        RemoveDroppedItems();
    }
    return Plugin_Continue;
}

public Action Timer_ChangeTeamToRed(Handle timer, any data)
{
    if (timer == null)
        return Plugin_Stop;
        
    int client = GetClientOfUserId(data);
    if (IsValidClient(client))
    {
        if (g_cvRemoveRagdoll.BoolValue)
        {
            RemoveRagdoll(client);
        }
        
        ChangeClientTeam(client, 2);
        TF2_RespawnPlayer(client);
        RemoveDroppedItems();
    }
    return Plugin_Continue;
}

public Action Timer_RemoveRagdoll(Handle timer, any data)
{
    if (timer == null)
        return Plugin_Stop;
        
    int client = GetClientOfUserId(data);
    if (IsValidClient(client))
    {
        RemoveRagdoll(client);
    }
    return Plugin_Continue;
}

void RemoveRagdoll(int client)
{
    if (!IsValidClient(client))
        return;
        
    int ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
    
    if (ragdoll > MaxClients && IsValidEntity(ragdoll))
    {
        AcceptEntityInput(ragdoll, "Kill");
    }
}

void RemoveDroppedItems()
{
    int entity = -1;
    
    if (g_cvRemoveWeapons.BoolValue)
    {
        while ((entity = FindEntityByClassname(entity, "tf_dropped_weapon")) != -1)
        {
            if (IsValidEntity(entity))
            {
                AcceptEntityInput(entity, "Kill");
            }
        }
    }
    
    if (g_cvRemoveAmmoPack.BoolValue)
    {
        entity = -1;
        while ((entity = FindEntityByClassname(entity, "tf_ammo_pack")) != -1)
        {
            if (IsValidEntity(entity))
            {
                AcceptEntityInput(entity, "Kill");
            }
        }
    }
}
