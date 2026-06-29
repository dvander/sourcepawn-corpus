// ====================================================================================================
// Plugin Info
// ====================================================================================================
#define PLUGIN_NAME        "[L4D1/2] Lowhealth bloodspray"
#define PLUGIN_AUTHOR      "Finishlast"
#define PLUGIN_DESCRIPTION "Lowhealth bloodspray aka the squirting fun"
#define PLUGIN_VERSION     "1.0.0"
#define PLUGIN_URL         "https://forums.alliedmods.net/showthread.php?t=351645"

public Plugin myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_URL
}

// ====================================================================================================
// Includes & Pragmas
// ====================================================================================================
#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

// ====================================================================================================
// Globals
// ====================================================================================================
int g_Ent[MAXPLAYERS + 1];
bool g_HasTimer[MAXPLAYERS + 1];
Handle g_Timer[MAXPLAYERS + 1];
bool g_bLateLoad;

// ====================================================================================================
// Plugin Start
// ====================================================================================================
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();
    if (engine != Engine_Left4Dead && engine != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead 1 or 2\" game");
        return APLRes_SilentFailure;
    }
    g_bLateLoad = late;
    return APLRes_Success;
}

public void OnPluginStart()
{
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
    HookEvent("player_team", Event_PlayerTeam); 
    HookEvent("player_death", Event_PlayerDeath); 
    ClearAll();

    if (g_bLateLoad)
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
            {
                if (!g_HasTimer[i])
                {
                    g_HasTimer[i] = true;
                    float interval = GetRandomFloat(3.0, 5.0);
                    g_Timer[i] = CreateTimer(interval, Timer_RespawnParticle, i, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);  
                }
            }
        }
    }
}

public void OnPluginEnd()
{
    ClearAll();
}

public void OnMapStart()
{
    PrecacheParticle("blood_impact_arterial_spray_3"); 
    ClearAll();
}

// ====================================================================================================
// OnClientDisconnect
// ====================================================================================================
public void OnClientDisconnect(int client)
{
    g_HasTimer[client] = false;

    if (g_Timer[client] != null)
    {
        delete g_Timer[client];
    }

    if (IsValidEntity(g_Ent[client]))
    {
        RemoveEntity(g_Ent[client]);
        g_Ent[client] = -1;
    }
}

// ====================================================================================================
// clear timers
// ====================================================================================================
void ClearAll()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (g_Timer[i] != null)
        {
            delete g_Timer[i];
        }
        if (IsValidEntity(g_Ent[i]))
        {
            RemoveEntity(g_Ent[i]);
        }
        g_Ent[i] = -1;
        g_HasTimer[i] = false;
    }
}

// ====================================================================================================
// precache particles
// ====================================================================================================
int PrecacheParticle(const char[] sEffectName)
{
	static int table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("ParticleEffectNames");
	}
	
	int index = FindStringIndex(table, sEffectName);
	if (index == INVALID_STRING_INDEX)
	{
		bool save = LockStringTables(false);
		AddToStringTable(table, sEffectName);
		LockStringTables(save);
		index = FindStringIndex(table, sEffectName);
	}
	
	return index;
}

// ====================================================================================================
// Event_PlayerSpawn
// ====================================================================================================
void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (IsValidClient(client) && GetClientTeam(client) == 2)
    {
        if (!g_HasTimer[client])
        {
            g_HasTimer[client] = true;
            float interval = GetRandomFloat(3.0, 5.0);
            g_Timer[client] = CreateTimer(interval, Timer_RespawnParticle, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);  
        }
    }
}

// ====================================================================================================
// Event_PlayerTeam
// ====================================================================================================
void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!IsValidClient(client))
        return;

    int oldTeam = event.GetInt("oldteam");
    int newTeam = event.GetInt("team");

    // If they switched away from survivors
    if (oldTeam == 2 && newTeam != 2)
    {
        g_HasTimer[client] = false;

        if (g_Timer[client] != null)
        {
            delete g_Timer[client];
        }

        if (IsValidEntity(g_Ent[client]))
        {
            RemoveEntity(g_Ent[client]);
            g_Ent[client] = -1;
        }
    }
}

// ====================================================================================================
// Event_PlayerDeath
// ====================================================================================================
void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client && GetClientTeam(client) == 2)
    {
        if (IsValidEntity(g_Ent[client]))
        {
            RemoveEntity(g_Ent[client]);
            g_Ent[client] = -1;
        }
    }
}

// ====================================================================================================
// Timer_RespawnParticle
// ====================================================================================================
Action Timer_RespawnParticle(Handle timer, any client)
{
    if (!IsValidClient(client))
    {
        g_HasTimer[client] = false;
        g_Timer[client] = null;
        if (IsValidEntity(g_Ent[client]))
        {
            RemoveEntity(g_Ent[client]);
            g_Ent[client] = -1;
        }
        return Plugin_Stop;
    }

    if (GetClientTeam(client) != 2)
    {
        return Plugin_Continue;
    }

    int basehealth = GetClientHealth(client);
    float tmphealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
    bool condition = (tmphealth > 0.0 && tmphealth < 31.0) || (tmphealth == 0.0 && basehealth < 16) || IsClientIncapped(client);

    if (condition)
    {
        if (IsValidEntity(g_Ent[client]))
        {
            RemoveEntity(g_Ent[client]);
            g_Ent[client] = -1;
        }
        g_Ent[client] = AttachParticleToChest(client, "blood_impact_arterial_spray_3");
    }
    else
    {
        if (IsValidEntity(g_Ent[client]))
        {
            RemoveEntity(g_Ent[client]);
            g_Ent[client] = -1;
        }
    }
    return Plugin_Continue;
}

// ====================================================================================================
// AttachParticleToChest
// ====================================================================================================
int AttachParticleToChest(int client, const char[] particleType)
{
    int particle = CreateEntityByName("info_particle_system");
    if (!IsValidEdict(particle))
    {
        return -1;
    }

    float pos[3], angles[3];
    GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
    GetEntPropVector(client, Prop_Send, "m_angRotation", angles);

    TeleportEntity(particle, pos, angles, NULL_VECTOR);
    DispatchKeyValue(particle, "effect_name", particleType);

    char tName[64];
    Format(tName, sizeof(tName), "target_%d", client);
    DispatchKeyValue(client, "targetname", tName);
    DispatchKeyValue(particle, "parentname", tName);

    DispatchSpawn(particle);
    ActivateEntity(particle);

    SetVariantString(tName);
    AcceptEntityInput(particle, "SetParent");

    SetVariantString("Spine"); // attachment to chest
    AcceptEntityInput(particle, "SetParentAttachment");

    // Adjust yaw and lower origin
    GetEntPropVector(particle, Prop_Send, "m_vecOrigin", pos);
    GetEntPropVector(particle, Prop_Send, "m_angRotation", angles);
    angles[1] -= 9.0;
    angles[0] += 205.0;
    pos[2] -= 1.0;
    pos[0] -= 3.0;
    pos[1] -= 2.0;
    SetEntPropVector(particle, Prop_Send, "m_angRotation", angles);
    SetEntPropVector(particle, Prop_Send, "m_vecOrigin", pos);
    AcceptEntityInput(particle, "start");

    return particle;
}

// ====================================================================================================
// Client check if timer is applicable
// ====================================================================================================
stock bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

stock bool IsClientIncapped(int client)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client)) { return false; }
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated"));
}