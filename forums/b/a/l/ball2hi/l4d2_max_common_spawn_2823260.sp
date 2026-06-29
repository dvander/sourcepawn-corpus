#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define PLUGIN_VERSION "0.5"

Handle cleanupTimer;

int refCommon[2048];
int totalCommon;
int maxCommon;
int directorLeniency;

float lastCleanupAction;
float elapsed;

ConVar cvarZCommonLimit;

bool mapActive;
bool cleanupActive;

public Plugin myinfo =
{
	name = "[L4D2] Common Limiter",
	author = "Silvers, Xbye",
	description = "Limits number of common infected to 'z_common_limit', attempts to avoid vanilla director conflict.",
	version = PLUGIN_VERSION
}

public void OnPluginStart()
{
    cvarZCommonLimit = FindConVar("z_common_limit");
    cvarZCommonLimit.AddChangeHook(ConVarChanged_Cvars);
    maxCommon = cvarZCommonLimit.IntValue;

    HookEvent("round_end",		Event_RoundEnd, EventHookMode_PostNoCopy);
    HookEvent("round_start",	Event_RoundStart, EventHookMode_PostNoCopy);

    LateLoad();

    directorLeniency = 5;

    RegAdminCmd("sm_common_limit", AdminLimitRply, ADMFLAG_GENERIC);
}

void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
    maxCommon = cvarZCommonLimit.IntValue;
    ZombieCleanupInitial();
}

public Action AdminLimitRply(int client, int args)
{   
    ReplyToCommand(client, "Common: %d / %d (+ %d) | [Active: %s]", totalCommon, maxCommon, directorLeniency, cleanupActive? "ON" : "OFF");
    return Plugin_Handled;
}

public void OnMapStart()
{
	mapActive = true;
}

public void OnMapEnd()
{
    mapActive = false;
    ResetPlugin();
}

void ResetPlugin()
{
    for( int i = 0; i < 2048; i++ )
    {
        refCommon[i] = 0;
    }

    totalCommon = 0;
}

void LateLoad()
{
    ResetPlugin();

    int amtRmvd = 0;

    int entity = -1;
    while((entity = FindEntityByClassname(entity, "infected")) != INVALID_ENT_REFERENCE)
    {
        refCommon[entity] = EntIndexToEntRef(entity);
        totalCommon++;

        if(totalCommon > maxCommon)
        {
            RemoveEntity(entity);
            amtRmvd++;
        }

    }

    PrintToServer("[Max_Common] %d zombies deleted. (lateload)", amtRmvd);
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	LateLoad();

	mapActive = true;
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	mapActive = false;

	ResetPlugin();
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if(mapActive && entity > 0 && entity < 2048 && (StrContains(classname, "infected") != -1))
    {
        refCommon[entity] = EntIndexToEntRef(entity);
        totalCommon++;

        if (cleanupActive)
        {
            if(OverZombieLimit())
            {
                SDKHook(entity, SDKHook_SpawnPost, ZombieCleanupPost);
                lastCleanupAction = GetGameTime();
            }

            elapsed = GetGameTime() - lastCleanupAction;

            if (elapsed > 5.0)
            {
                cleanupActive = false;
                lastCleanupAction = 0.0;
                PrintToServer("[Max_Common] Deactivated. (timer)");
            }

        }
        else if(OverZombieLimit() && !cleanupTimer)
        {
            cleanupTimer = CreateTimer(3.0, TimerCleanup);
            PrintToServer("[Max_Common] Timer created.");
        }}

}

bool OverZombieLimit()
{
    if (cleanupActive && (totalCommon > maxCommon))
        return true;
    else if (!cleanupActive && (totalCommon > maxCommon + directorLeniency))
        return true;
    else
        return false;
}

Action TimerCleanup(Handle timer)
{
    cleanupTimer = null;

    if(OverZombieLimit())
    {
        PrintToServer("[Max_Common] Activated.");       
        ZombieCleanupInitial();
    }

    return Plugin_Continue;
}

public void OnEntityDestroyed(int entity)
{
    if(mapActive && entity > 0 && entity < 2048 && refCommon[entity] == EntIndexToEntRef(entity))
    {
        refCommon[entity] = 0;
        totalCommon--;

        if(cleanupActive)
        {
            elapsed = GetGameTime() - lastCleanupAction;

            if (elapsed > 5.0 && !OverZombieLimit())
            {
                cleanupActive = false;
                lastCleanupAction = 0.0;
                PrintToServer("[Max_Common] Deactived. (destroy)");
            }
        }
    }
}

void ZombieCleanupInitial()
{
    int amtRmvd = 0;

    int entity = -1;
    while((entity = FindEntityByClassname(entity, "infected")) != INVALID_ENT_REFERENCE)
    {
        if(totalCommon > maxCommon)
        {
            RemoveEntity(entity);
            amtRmvd++;
        }
    }

    cleanupActive = true;
    lastCleanupAction = GetGameTime();
    PrintToServer("[Max_Common] %d zombies deleted.", amtRmvd);
}

void ZombieCleanupPost(int entity)
{
    RemoveEntity(entity);
}