#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <sdkhooks>
#define PLUGIN_VERSION "1.0.1"

#define TEAM_SURVIVORS  2

ConVar g_cvInjectDistance = null;
ConVar g_cvInjectDuration = null;
ConVar g_cvAdrenaline_duration = null;

bool g_bInUse[MAXPLAYERS + 1] = {false, ...};
bool g_bIsAdrenalineActiveWeapon[MAXPLAYERS + 1] = {false, ...};
bool g_bIsDominated[MAXPLAYERS + 1] = {false, ...};
int g_iInjectTarget[MAXPLAYERS + 1] = {INVALID_ENT_REFERENCE, ...};
int g_iInjector[MAXPLAYERS + 1] = {INVALID_ENT_REFERENCE, ...};

#define ISHOLDING(%0) \
	((buttons & (%0)) == (%0))

public Plugin myinfo =
{
	name = "[L4D2] Inject Adrenaline on a Teammate",
	author = "XeroX",
	description = "Allows the injection of Adrenaline on Teammates",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2762136"
}

public void OnPluginStart()
{
    CreateConVar("inject_adrenaline_version", PLUGIN_VERSION, "Version of the Plugin", FCVAR_NOTIFY);
    g_cvInjectDistance = CreateConVar("inject_adrenaline_range", "128.0", "Maximum Distance between injector and receiver. If any player is beyond this range it will not inject.", FCVAR_NONE, true, 128.0, true, 256.0);
    g_cvInjectDuration = CreateConVar("inject_adrenaline_duration", "2.0", "Time it takes until the adrenaline is injected", FCVAR_NONE, true, 2.0, true, 10.0);

    g_cvAdrenaline_duration = FindConVar("adrenaline_duration");


    HookEvent("charger_carry_start", Event_PlayerDominatedStart);
    HookEvent("charger_carry_end", Event_PlayerDominatedEnd);
    
    // It is possible to let a charger pickup a survivor without "carrying them"
    // Hence we check both event types.

    HookEvent("charger_pummel_start", Event_PlayerDominatedStart);
    HookEvent("charger_pummel_end", Event_PlayerDominatedEnd);

    HookEvent("jockey_ride", Event_PlayerDominatedStart);
    HookEvent("jockey_ride_end", Event_PlayerDominatedEnd);

    HookEvent("lunge_pounce", Event_PlayerDominatedStart);
    HookEvent("pounce_stopped", Event_PlayerDominatedEnd);

    HookEvent("tongue_grab", Event_PlayerDominatedStart);
    HookEvent("tongue_release", Event_PlayerDominatedEnd);
    
    HookEvent("choke_start", Event_PlayerDominatedStart);
    HookEvent("choke_stopped", Event_PlayerDominatedEnd);
    HookEvent("choke_end", Event_PlayerDominatedEnd); 

    HookEvent("player_ledge_grab", Event_PlayerDominatedStart);
    HookEvent("player_ledge_release", Event_PlayerDominatedEnd);
}

public void OnClientPutInServer(int client)
{
    g_bInUse[client] = false;
    g_bIsAdrenalineActiveWeapon[client] = false;
    g_bIsDominated[client] = false;
    g_iInjectTarget[client] = INVALID_ENT_REFERENCE;
    g_iInjector[client] = INVALID_ENT_REFERENCE;

    SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
}

public void Event_PlayerDominatedStart(Event event, const char[] name, bool dontBroadcast)
{
    int userid = 0;
    if(StrEqual(name, "player_ledge_grab"))
    {
        userid = event.GetInt("userid");
    }
    else
    {
        userid = event.GetInt("victim");
    }
    int client = GetClientOfUserId(userid);
    if(g_bIsDominated[client] == false)
        g_bIsDominated[client] = true;
}

public void Event_PlayerDominatedEnd(Event event, const char[] name, bool dontBroadcast)
{
    int userid = 0;
    if(StrEqual(name, "player_ledge_release"))
    {
        userid = event.GetInt("userid");
    }
    else
    {
        userid = event.GetInt("victim");
    }

    int client = GetClientOfUserId(userid);
    if(g_bIsDominated[client])
        g_bIsDominated[client] = false;
}


public Action L4D_OnVomitedUpon(int victim, int &attacker, bool &boomerExplosion)
{
    if(!boomerExplosion)
        return Plugin_Continue;
    if(!g_bIsAdrenalineActiveWeapon[victim])
        return Plugin_Continue;
    if(g_bInUse[victim] == false)
        return Plugin_Continue;
    if(!IsValidInjector(victim))
        return Plugin_Continue;

    int target = GetClientFromSerial(g_iInjectTarget[victim]);
    if(!IsValidEntity(target))
        return Plugin_Continue;
    ResetInjection(victim, target);
    return Plugin_Continue;
}

public void OnWeaponSwitchPost(int client, int weapon)
{
    int currWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if(!IsValidEntity(currWeapon))
        return;

    static char szClassName[32];
    GetEntityClassname(currWeapon, szClassName, sizeof(szClassName));

    g_bIsAdrenalineActiveWeapon[client] = StrEqual(szClassName, "weapon_adrenaline", false);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
    if(!g_bIsAdrenalineActiveWeapon[client])
        return Plugin_Continue;
    
    if(!IsValidInjector(client)) 
        return Plugin_Continue;

    float curTime = GetGameTime();
    if(ISHOLDING(IN_USE) && g_bInUse[client] == false)
    {
        g_bInUse[client] = true;
        int target = GetClientAimTarget(client, true);

        if(!IsValidEntity(target)) 
            return Plugin_Continue;

        if(!IsValidInjectReceiver(target)) 
            return Plugin_Continue;

        if(!IsNearby(client, target)) 
            return Plugin_Continue;

        
        if(g_iInjectTarget[client] == INVALID_ENT_REFERENCE)
        {
            g_iInjectTarget[client] = GetClientSerial(target);
            g_iInjector[target] = GetClientSerial(client);

            SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", curTime);
            SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", g_cvInjectDuration.FloatValue);
            
            SetEntPropFloat(target, Prop_Send, "m_flProgressBarStartTime", curTime);
            SetEntPropFloat(target, Prop_Send, "m_flProgressBarDuration", g_cvInjectDuration.FloatValue);

            CreateTimer(g_cvInjectDuration.FloatValue, Inject_Adrenaline, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
        }
        else if(g_iInjectTarget[client] != GetClientSerial(target))
        {
            // Switched target. Abort
            ResetInjection(client, target);
        }
    }
    else if(!ISHOLDING(IN_USE) && g_bInUse[client] == true)
    {
        g_bInUse[client] = false;
        int target = GetClientAimTarget(client, true);

        if(!IsValidEntity(target)) return Plugin_Continue;
        if(!IsValidInjectReceiver(target)) return Plugin_Continue;
        //if(!IsNearby(client, target)) return Plugin_Continue;
        // Client let go of button. Abort.

        ResetInjection(client, target);
    }
    return Plugin_Continue;
}


public Action Inject_Adrenaline(Handle timer, any serial)
{
    int client = GetClientFromSerial(serial);
    if(!IsValidEntity(client))
        return Plugin_Continue;

    if(g_bInUse[client] == false)
        return Plugin_Continue;
    
    if(g_bIsAdrenalineActiveWeapon[client] == false)
        return Plugin_Continue;
    
    if(!IsValidInjector(client))
        return Plugin_Continue;

    int target = GetClientAimTarget(client, true);

    if(!IsValidEntity(target))
        return Plugin_Continue;

    if(!IsValidInjectReceiver(target))
        return Plugin_Continue;
    
    int actualTarget = GetClientFromSerial(g_iInjectTarget[client]);
    if(!IsValidEntity(actualTarget))
        return Plugin_Continue;

    if(!IsValidInjectReceiver(actualTarget))
        return Plugin_Continue;
    
    if(!IsNearby(client, target))
        return Plugin_Continue;

    
    if(target != actualTarget)
    {
        ResetInjection(client, target);
        return Plugin_Continue;
    }

    g_bIsAdrenalineActiveWeapon[client] = false;
    L4D2_UseAdrenaline(target, g_cvAdrenaline_duration.FloatValue, true);

    int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if(!IsValidEntity(weapon))
        return Plugin_Continue;
    
    SDKHooks_DropWeapon(client, weapon);
    
    RequestFrame(Frame_RemoveWeapon, EntIndexToEntRef(weapon));
    return Plugin_Continue;
}

void ResetInjection(int client, int target)
{
    float curTime = GetGameTime();
    SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", curTime);
    SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
            
    SetEntPropFloat(target, Prop_Send, "m_flProgressBarStartTime", curTime);
    SetEntPropFloat(target, Prop_Send, "m_flProgressBarDuration", 0.0);

    g_iInjectTarget[client] = INVALID_ENT_REFERENCE;
    g_iInjector[target] = INVALID_ENT_REFERENCE;
}

public void L4D_TankClaw_OnPlayerHit_Post(int tank, int claw, int client)
{
    if(g_bInUse[client] == false)
        return;
    
    if(!IsValidInjector(client))
        return;

    int target = g_iInjectTarget[client];
    if(!IsValidEntity(target))
        return;
    
    ResetInjection(client, target);
}

public void Frame_RemoveWeapon(any entref)
{
    int weapon = EntRefToEntIndex(entref);
    if(!IsValidEntity(weapon))
        return;
    RemoveEntity(weapon);
}

bool IsNearby(int client, int target)
{
    float Pos[3], tPos[3];
    GetClientAbsOrigin(client, Pos);
    GetClientAbsOrigin(target, tPos);
    float distance = GetVectorDistance(Pos, tPos);
    return (distance <= g_cvInjectDistance.FloatValue);
}

bool IsBusyReviving(int client)
{
    return ((GetEntPropEnt(client, Prop_Send, "m_reviveTarget") != -1) || (GetEntPropEnt(client, Prop_Send, "m_useActionTarget") != -1));
}

bool IsValidInjector(int client)
{
    return (IsClientInGame(client) && IsPlayerAlive(client) 
    && GetClientTeam(client) == TEAM_SURVIVORS && (GetEntProp(client, Prop_Send, "m_isFallingFromLedge") == 0)
    && !IsDominatedBySpecialInfected(client) && !IsStaggered(client) && !IsBusyReviving(client)
    && GetEntProp(client, Prop_Send, "m_bAdrenalineActive") == 0);
}

bool IsValidInjectReceiver(int client)
{
    return IsValidInjector(client);
}

bool IsStaggered(int client)
{
    int m_staggerTimerOffset = FindSendPropInfo("CTerrorPlayer", "m_staggerTimer");
    float m_timestamp = GetEntDataFloat(client, m_staggerTimerOffset + 8);
    return (m_timestamp != -1.0);
}

bool IsDominatedBySpecialInfected(int client)
{
    return g_bIsDominated[client];
}