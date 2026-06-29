#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0.9"
#define CVAR_FLAGS FCVAR_SPONLY|FCVAR_NOTIFY
#define ZC_BOOMER 2

enum
{
    TEAM_SPECTATOR = 1,
    TEAM_SURVIVOR,
    TEAM_INFECTED
}

ConVar g_hCvarAllow, g_hSplashRadius, g_hSplashDamage, g_hDisplayDamageMessage, g_hIgnoreVisibility, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarMPGameMode;
bool g_bCvarAllow, g_bIgnoreVisibility, g_bMapStarted;
float g_fSplashRadius, g_fSplashDamage, g_fSplashRadiusSqr;
int g_iDisplayDamageMessage, g_iCurrentMode, g_iPlayerSpawn, g_iRoundStart;

public Plugin myinfo = 
{
    name = "L4D_Splash_Damage",
    author = "AtomicStryker",
    description = "Left 4 Dead Boomer Splash Damage",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?t=98794"
}

public void OnPluginStart()
{
    CreateConVar("l4d_splash_damage_version", PLUGIN_VERSION, "Version of L4D Boomer Splash Damage", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
    g_hCvarAllow = CreateConVar("l4d_splash_damage_enabled", "1", "Enable/Disable Boomer Splash Damage", CVAR_FLAGS);
    g_hSplashDamage = CreateConVar("l4d_splash_damage_damage", "10.0", "Damage dealt by Boomer explosion", CVAR_FLAGS);
    g_hSplashRadius = CreateConVar("l4d_splash_damage_radius", "200.0", "Radius of Boomer splash damage", CVAR_FLAGS);
    g_hDisplayDamageMessage = CreateConVar("l4d_splash_damage_notification", "0", "0: Disabled; 1: Small HUD; 2: Big HUD; 3: Chat", CVAR_FLAGS);
    g_hIgnoreVisibility = CreateConVar("l4d_splash_damage_ignore_visibility", "0", "Ignore visibility check for splash damage (0: Enable; 1: Disable)", CVAR_FLAGS);
    g_hCvarModes = CreateConVar("l4d_splash_damage_modes", "", "Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all)", CVAR_FLAGS);
    g_hCvarModesOff = CreateConVar("l4d_splash_damage_modes_off", "", "Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none)", CVAR_FLAGS);
    g_hCvarModesTog = CreateConVar("l4d_splash_damage_modes_tog", "0", "Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS);

    g_hCvarMPGameMode = FindConVar("mp_gamemode");
    g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
    g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
    g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
    g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
    g_hSplashRadius.AddChangeHook(ConVarChanged_Cvars);
    g_hSplashDamage.AddChangeHook(ConVarChanged_Cvars);
    g_hDisplayDamageMessage.AddChangeHook(ConVarChanged_Cvars);
    g_hIgnoreVisibility.AddChangeHook(ConVarChanged_Cvars);

    AutoExecConfig(true, "L4D_Splash_Damage");
}

public void OnMapStart()
{
    g_bMapStarted = true;
}

public void OnMapEnd()
{
    g_bMapStarted = false;
    ResetPlugin();
}

void ResetPlugin()
{
    g_iRoundStart = 0;
    g_iPlayerSpawn = 0;
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    ResetPlugin();
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    if( g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
        CreateTimer(2.0, TimerLoad, _, TIMER_FLAG_NO_MAPCHANGE);
    g_iRoundStart = 1;
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    if( g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
        CreateTimer(2.0, TimerLoad, _, TIMER_FLAG_NO_MAPCHANGE);
    g_iPlayerSpawn = 1;

    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!IsValidInfected(client) || GetInfectedClass(client) != ZC_BOOMER) return;
}

Action TimerLoad(Handle timer)
{
    IsAllowed();
    return Plugin_Continue;
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void ConVarChanged_Allow(ConVar convar, const char[] oldValue, const char[] newValue)
{
    IsAllowed();
}

void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();
}

void GetCvars()
{
    g_fSplashRadius = g_hSplashRadius.FloatValue;
    g_fSplashRadiusSqr = g_fSplashRadius * g_fSplashRadius;
    g_fSplashDamage = g_hSplashDamage.FloatValue;
    g_iDisplayDamageMessage = g_hDisplayDamageMessage.IntValue;
    g_bIgnoreVisibility = g_hIgnoreVisibility.BoolValue;
}

void IsAllowed()
{
    bool bCvarAllow = g_hCvarAllow.BoolValue;
    bool bAllowMode = IsAllowedGameMode();
    GetCvars();

    if( !g_bCvarAllow && bCvarAllow && bAllowMode )
    {
        g_bCvarAllow = true;
        HookEvent("round_end",		Event_RoundEnd,		EventHookMode_PostNoCopy);
        HookEvent("round_start",	Event_RoundStart,	EventHookMode_PostNoCopy);
        HookEvent("player_spawn",	Event_PlayerSpawn,	EventHookMode_PostNoCopy);
        HookEvent("player_death",	Event_PlayerDeath,	EventHookMode_Post);
    }
    else if( g_bCvarAllow && (!bCvarAllow || !bAllowMode) )
    {
        g_bCvarAllow = false;
        UnhookEvent("round_end",	Event_RoundEnd,		EventHookMode_PostNoCopy);
        UnhookEvent("round_start",	Event_RoundStart,	EventHookMode_PostNoCopy);
        UnhookEvent("player_spawn",	Event_PlayerSpawn,	EventHookMode_PostNoCopy);
        UnhookEvent("player_death",	Event_PlayerDeath,	EventHookMode_Post);
        ResetPlugin();
    }
}

bool IsAllowedGameMode()
{
    if( g_hCvarMPGameMode == null )
        return false;

    int iCvarModesTog = g_hCvarModesTog.IntValue;
    if( iCvarModesTog != 0 )
    {
        if( !g_bMapStarted )
            return false;

        g_iCurrentMode = 0;

        int entity = CreateEntityByName("info_gamemode");
        if( IsValidEntity(entity) )
        {
            DispatchSpawn(entity);
            HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
            HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
            HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
            HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
            ActivateEntity(entity);
            AcceptEntityInput(entity, "PostSpawnActivate");
            if( IsValidEntity(entity) )
                RemoveEdict(entity);
        }

        if( g_iCurrentMode == 0 )
            return false;

        if( !(iCvarModesTog & g_iCurrentMode) )
            return false;
    }

    char sGameModes[64], sGameMode[64];
    g_hCvarMPGameMode.GetString(sGameMode, sizeof(sGameMode));
    Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

    g_hCvarModes.GetString(sGameModes, sizeof(sGameModes));
    if( sGameModes[0] )
    {
        Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
        if( StrContains(sGameModes, sGameMode, false) == -1 )
            return false;
    }

    g_hCvarModesOff.GetString(sGameModes, sizeof(sGameModes));
    if( sGameModes[0] )
    {
        Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
        if( StrContains(sGameModes, sGameMode, false) != -1 )
            return false;
    }

    return true;
}

void OnGamemode(const char[] output, int caller, int activator, float delay)
{
    if( strcmp(output, "OnCoop") == 0 )
        g_iCurrentMode = 1;
    else if( strcmp(output, "OnSurvival") == 0 )
        g_iCurrentMode = 2;
    else if( strcmp(output, "OnVersus") == 0 )
        g_iCurrentMode = 4;
    else if( strcmp(output, "OnScavenge") == 0 )
        g_iCurrentMode = 8;
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    if( !g_bCvarAllow ) return;

    int client = GetClientOfUserId(event.GetInt("userid"));
    if( !IsValidInfected(client) || GetInfectedClass(client) != ZC_BOOMER) return;

    float pos[3];
    GetClientEyePosition(client, pos);

    for( int target = 1; target <= MaxClients; target++ )
    {
        if( !IsValidSurvivor(target) || !IsPlayerAlive(target) || IsClientPinned(target) || IsClientIncapped(target) ) continue;

        float targetPos[3];
        GetClientEyePosition(target, targetPos);

        float distanceSqr = GetVectorDistance(pos, targetPos, true);
        if( distanceSqr <= g_fSplashRadiusSqr && (g_bIgnoreVisibility || Player_IsVisible_To(client, target)) )
        {
            switch( g_iDisplayDamageMessage )
            {
                case 1: PrintCenterText(target, "Boomer explosion damage!");
                case 2: PrintHintText(target, "Boomer explosion damage!");
                case 3: PrintToChat(target, "\x04Boomer explosion damage!");
            }
            ApplyDamage(RoundToCeil(g_fSplashDamage), target, client);
        }
    }
}

void ApplyDamage(int damage, int victim, int attacker)
{
    if( damage <= 0 || !IsValidSurvivor(victim) || !IsPlayerAlive(victim) ) return;

    float victimPos[3];
    GetClientEyePosition(victim, victimPos);

    char strDamage[16], strTarget[16];
    IntToString(damage, strDamage, sizeof(strDamage));
    Format(strTarget, sizeof(strTarget), "hurtme%d", victim);

    int pointHurt = CreateEntityByName("point_hurt");
    if( pointHurt == -1 ) return;

    DispatchKeyValue(victim, "targetname", strTarget);
    DispatchKeyValue(pointHurt, "DamageTarget", strTarget);
    DispatchKeyValue(pointHurt, "Damage", strDamage);
    DispatchKeyValue(pointHurt, "DamageType", "65536");
    DispatchSpawn(pointHurt);

    TeleportEntity(pointHurt, victimPos, NULL_VECTOR, NULL_VECTOR);
    AcceptEntityInput(pointHurt, "Hurt", (attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker)) ? attacker : -1);

    DispatchKeyValue(victim, "targetname", "null");
    RemoveEdict(pointHurt);
}

bool Player_IsVisible_To(int client, int target)
{
    float self_pos[3], target_pos[3], look_at[3], vec_angles[3];
    GetClientEyePosition(client, self_pos);
    GetClientEyePosition(target, target_pos);
    MakeVectorFromPoints(self_pos, target_pos, look_at);
    GetVectorAngles(look_at, vec_angles);
    Handle hTrace = TR_TraceRayFilterEx(self_pos, vec_angles, MASK_VISIBLE, RayType_Infinite, TR_RayFilter, client);
    bool result = false;
    if( TR_DidHit(hTrace) && TR_GetEntityIndex(hTrace) == target )
        result = true;
    delete hTrace;
    return result;
}

bool TR_RayFilter(int entity, int mask, int self)
{
    return entity != self;
}

bool IsValidInfected(int client)
{
    return IsValidClient(client) && GetClientTeam(client) == TEAM_INFECTED;
}

int GetInfectedClass(int client)
{
    return IsValidInfected(client) ? GetEntProp(client, Prop_Send, "m_zombieClass") : -1;
}

bool IsValidSurvivor(int client)
{
    return IsValidClient(client) && GetClientTeam(client) == TEAM_SURVIVOR;
}

bool IsValidClient(int client)
{
    return client > 0 && client <= MaxClients && IsClientInGame(client);
}

bool IsClientPinned(int client)
{
    if( !IsValidSurvivor(client) || !IsPlayerAlive(client) ) return false;
    return GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0 
        || GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0 
        || GetEntPropEnt(client, Prop_Send, "m_carryAttacker") > 0 
        || GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0 
        || GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0;
}

bool IsClientIncapped(int client)
{
    if( !IsValidClient(client) || !IsPlayerAlive(client) ) return false;
    return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated"));
}