#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <left4dhooks>

#define PLUGIN_NAME			    "l4d2_shoot_alert_common"
#define PLUGIN_VERSION 			"1.1 2026-03-09"
#define GAMEDATA_FILE           PLUGIN_NAME
#define CONFIG_FILENAME         PLUGIN_NAME

#define TEAM_SPECTATOR		1
#define TEAM_SURVIVOR		2
#define TEAM_INFECTED		3

#define MODEL_ROAD "models/infected/common_male_roadcrew.mdl"

// 1.1 Changes:
// 1. Added more places to reset timers
// 2. Removed SetEntProp(entity, Prop_Send, "m_nSequence", 37), a better solution is needed.
// 3. Replaced PARTITION_SOLID_EDICTS with PARTITION_NON_STATIC_EDICTS for optimization.
// 4. Small optimizations.

public Plugin myinfo =
{
	name = "[L4D2] Weapon Fire Alert Common",
	author = "gvazdas",
	description = "Weapon fire alerts Common Infected.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=352360,https://github.com/gvazdas/l4d2_zombie_master"
}

Handle timers[MAXPLAYERS+1] = {INVALID_HANDLE, ...}; // optimization

ConVar g_hCvarEnable, g_hCvarAlertRange, g_hCvarAlertProbability, g_hCvarRushRange;
bool enabled = false;
float alert_range = 3000.0;
float rush_range = 500.0;
float alert_probability = 0.5;

public void OnPluginStart()
{
    AutoExecConfig(true, CONFIG_FILENAME);
    
    g_hCvarEnable = CreateConVar("l4d2_shoot_alert_common_enable", "1", "0=Plugin off, 1=Plugin on.",FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hCvarEnable.AddChangeHook(ConVarChanged_Cvars);   
    
    g_hCvarAlertRange = CreateConVar("l4d2_shoot_alert_common_range", "3000.0", "Range to make commons look at shooter.",FCVAR_NOTIFY, true, 0.0, true, 100000.0);
    g_hCvarAlertRange.AddChangeHook(ConVarChanged_Cvars);
    
    g_hCvarAlertProbability = CreateConVar("l4d2_shoot_alert_common_probability", "0.5", "Probability for gun fire to alert a particular common zombie.",FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hCvarAlertProbability.AddChangeHook(ConVarChanged_Cvars);  
    
    g_hCvarRushRange = CreateConVar("l4d2_shoot_alert_common_range_rush", "500.0", "Range to make commons rush shooter immediately.",FCVAR_NOTIFY, true, 0.0, true, 100000.0);
    g_hCvarRushRange.AddChangeHook(ConVarChanged_Cvars);
    
    GetCvars();
}

void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();
}

void GetCvars()
{
    alert_range = g_hCvarAlertRange.FloatValue;
    rush_range = g_hCvarRushRange.FloatValue;
    alert_probability = g_hCvarAlertProbability.FloatValue;
    IsAllowed();
}

void IsAllowed()
{
    if (g_hCvarEnable.BoolValue == enabled) return;
    if (g_hCvarEnable.BoolValue)
    {
        HookEvent("weapon_fire", evtPlayerFired, EventHookMode_Post);
        HookEvent("round_start",   evtRoundStart,  EventHookMode_PostNoCopy);
        reset_timers();
    }
    else
    {
        UnhookEvent("weapon_fire", evtPlayerFired, EventHookMode_Post);
        UnhookEvent("round_start",   evtRoundStart,	 EventHookMode_PostNoCopy);
    }
    enabled = g_hCvarEnable.BoolValue;
} 

public void OnMapStart()
{
    if (enabled) reset_timers();
}

void evtRoundStart(Event event, const char[] name, bool dontBroadcast)
{
    if (enabled) reset_timers();
}

void evtPlayerFired(Event event, const char[] name, bool dontBroadcast)
{
    if (!enabled) return;
    if (L4D_IsSurvivalMode()) return; // horde is already aggro
    if (L4D_IsFinaleActive()) return; // horde is already aggro
    int count = event.GetInt("count");
    if (count<=0) return; // melee weapons give 0 count
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!IsPlayerAlive(client) || GetClientTeam(client)!=TEAM_SURVIVOR) return;
    if (timers[client]==INVALID_HANDLE)
        timers[client] = CreateTimer(GetRandomFloat(0.75-0.25,0.75+0.25),alert_update,EntIndexToEntRef(client),TIMER_FLAG_NO_MAPCHANGE);
}

// GUNFIRE!
Action alert_update(Handle timer, int entref)
{
    if (!enabled || !IsValidEntRef(entref)) return Plugin_Stop;
    int client = EntRefToEntIndex(entref);
    if (timers[client]==INVALID_HANDLE) return Plugin_Stop; //prevent carry-over to new round
    timers[client] = INVALID_HANDLE;
    if (!IsValidClient(client)) return Plugin_Stop;
    if (!IsPlayerAlive(client) || GetClientTeam(client)!=TEAM_SURVIVOR) return Plugin_Stop;
    if (L4D_GetCommonsCount()<=0) return Plugin_Stop;
    int entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "info_goal_infected_chase")) != INVALID_ENT_REFERENCE)
    {
        return Plugin_Stop; // horde is already aggro
    }
    while ((entity = FindEntityByClassname(entity, "pipe_bomb_projectile")) != INVALID_ENT_REFERENCE)
    {
        return Plugin_Stop; // horde is already aggro
    }
    float pos[3];
    L4D_GetEntityWorldSpaceCenter(client,pos);
    // PARTITION_NON_STATIC_EDICTS or PARTITION_SOLID_EDICTS?
    TR_EnumerateEntitiesSphere(pos,alert_range,PARTITION_NON_STATIC_EDICTS,AlertCallback,client);
    return Plugin_Stop;
}

public bool AlertCallback(int entity, int client)
{
    // Return true to continue enumerating, false to stop
    if (entity<=MaxClients || !IsValidEntity(entity)) return true;
    static char class[16];
    GetEntityClassname(entity, class, sizeof(class));
    switch (class[0])
    {
        case 'i':
        {
            if (strcmp(class,"infected")==0)
            {
                // If already rushing, do nothing.
                if (GetEntProp(entity,Prop_Send,"m_mobRush")>0) return true;
                
                // Road crew have headphones, ignore gunfire.
                char sModelName[64];
                GetEntPropString(entity, Prop_Data, "m_ModelName", sModelName, sizeof(sModelName));
                if (strcmp(sModelName,MODEL_ROAD)==0) return true;
                
                if (!IsValidClient(client) || !IsPlayerAlive(client)) return false;
                
                float pos[3], pos2[3];
                L4D_GetEntityWorldSpaceCenter(client,pos);
                L4D_GetEntityWorldSpaceCenter(entity,pos2);
                if (GetVectorDistance(pos,pos2)<=rush_range)
                {
                    SetEntProp(entity, Prop_Send, "m_mobRush", 1);
                    SetEntPropEnt(entity, Prop_Send, "m_clientLookatTarget",client);
                    return true;
                }
                
                // Update alert state (with a little bit of randomness):
                // 1) If idle, look at survivor and establish line of sight.
                // 2) If already looking at survivor, and there is line of sight, and survivor fires again, aggro!
                if (alert_probability>=1.0 || GetRandomFloat(0.0,1.0)<alert_probability)
                {
                    pos2[2] += 36.0;
                    int lookat = GetEntPropEnt(entity, Prop_Send, "m_clientLookatTarget");
                    if (lookat==client && L4D2_IsVisibleToPlayer(client,TEAM_SURVIVOR,3,0,pos2))
                    {
                        SetEntProp(entity, Prop_Send, "m_mobRush", 1);
                        return true;
                    }
                    else if (lookat<=0)
                    {
                        // This part needs work, setting sequence like this gives jank results.
                        // Maybe Actions is the way to go.
                        //SetEntProp(entity, Prop_Send, "m_nSequence", 37);
                        SetEntPropEnt(entity, Prop_Send, "m_clientLookatTarget",client);
                        DataPack pack;
                        CreateDataTimer(GetRandomFloat(2.0-0.5,2.0+0.5),undo_lookat,pack,TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
                        pack.WriteCell(EntIndexToEntRef(entity));
                        pack.WriteCell(EntIndexToEntRef(client));
                    }
                }
            }
        }
    }
    return true;
}

// Must have been the wind.
Action undo_lookat(Handle timer, DataPack pack)
{
    pack.Reset();
    int entref_zombie = pack.ReadCell();
    if (!IsValidEntRef(entref_zombie)) return Plugin_Stop;
    if (GetEntProp(entref_zombie, Prop_Send, "m_mobRush")>0) return Plugin_Stop;
    int entref_client = pack.ReadCell();
    if (!IsValidEntRef(entref_client)) return Plugin_Stop;
    int client = EntRefToEntIndex(entref_client);
    if (GetEntPropEnt(entref_zombie, Prop_Send, "m_clientLookatTarget")==client)
        SetEntPropEnt(entref_zombie, Prop_Send, "m_clientLookatTarget",-1);
    return Plugin_Stop;
}

void reset_timers()
{
    for( int i = 1; i <= MAXPLAYERS; i++ )
    {
        timers[i] = INVALID_HANDLE;
    }
}  

stock bool IsValidClient(int client, bool replaycheck = true)
{
	if (client<1 || client>MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	}
	return true;
}

stock bool IsValidEntRef(int entity)
{
	if( entity && entity != -1 && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;	
}