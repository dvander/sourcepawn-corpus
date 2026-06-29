#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <dhooks>

// m_lifeState values
#define	LIFE_DYING				1 // playing death animation or still falling off of a ledge waiting to hit ground
#define	LIFE_DEAD				2 // dead. lying still.
#define LIFE_RESPAWNABLE		3

DynamicHook dhIsValidObserverTarget = null;

GameData g_pGameConfig = null;

bool bIsRoundRunning = false;


public void OnPluginStart()
{
    g_pGameConfig = new GameData("cssctspec.games");
    if(g_pGameConfig == null)
    {
        SetFailState("Gamedata file cssctspec.games.txt is missing!");
        return;
    }

    dhIsValidObserverTarget = DynamicHook.FromConf(g_pGameConfig, "IsValidObserverTarget");

    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("round_start", Event_RoundStart);
    HookEvent("round_end", Event_RoundEnd);

    for(int i = 1; i <= MaxClients; i++)
    {
        if(!IsClientInGame(i)) continue;
        OnClientPutInServer(i);
    }
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    char szGameFolder[PLATFORM_MAX_PATH];
    GetGameFolderName(szGameFolder, sizeof(szGameFolder));
    if(!StrEqual(szGameFolder, "cstrike"))
    {
        strcopy(error, err_max, "CS:S CT Spec Only is not supported for this game!");
        return APLRes_Failure;
    }
    return APLRes_Success;
}

public void OnMapStart()
{
    bIsRoundRunning = false;
}

public void OnClientPutInServer(int client)
{
    dhIsValidObserverTarget.HookEntity(Hook_Post, client, Hook_IsValidObServerTarget);
}

int FindNextObserverTarget(int client, bool bReverse = false)
{
    static Handle hSDKCall = null;
    if(hSDKCall == null)
    {
        StartPrepSDKCall(SDKCall_Player);
        PrepSDKCall_SetFromConf(g_pGameConfig, SDKConf_Virtual, "CBasePlayer::FindNextObserverTarget");
        PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
        PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
        hSDKCall = EndPrepSDKCall();
    }

    if(hSDKCall != null)
    {
        return SDKCall(hSDKCall, client, bReverse);
    }
    return INVALID_ENT_REFERENCE;
}

public void Event_RoundStart(Event event, const char[] szName, bool dontBroadcast)
{
    bIsRoundRunning = true;
}
public void Event_RoundEnd(Event event, const char[] szName, bool dontBroadcast)
{
    bIsRoundRunning = false;
}
public void Event_PlayerDeath(Event event, const char[] szName, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    if(!IsClientInGame(victim))
        return;

    // The game internally automatically just uses the last target if valid
    // Make sure we select a new one based on the modified search criteria.
    int observerTarget = FindNextObserverTarget(victim);
    SetEntPropEnt(victim, Prop_Send, "m_hObserverTarget", observerTarget);
}

public MRESReturn Hook_IsValidObServerTarget(int pThis, DHookReturn hReturn, DHookParam hParams)
{
    /* 
        Roughly recreating the IsValidObserverTarget code
    */ 
    // Only if the round is actually live.
    if(bIsRoundRunning == false)
        return MRES_Ignored;

    // Validate our potential target
    if(hParams.IsNull(1))
        return MRES_Ignored;

    int entity = hParams.Get(1);
        
    if(entity < 1 || entity > MaxClients)
    {
        hReturn.Value = false;
        return MRES_Supercede;
    }

     // Cannot spectate myself
    if(pThis == entity)
    {
        hReturn.Value = false;
        return MRES_Supercede;
    }

    if(!IsClientInGame(entity))
    {
        hReturn.Value = false;
        return MRES_Supercede;
    }
    
    int m_lifestate = GetEntProp(entity, Prop_Send, "m_lifeState");
    if( m_lifestate == LIFE_RESPAWNABLE) // target is dead, waiting for respawn
    {
        hReturn.Value = false;
        return MRES_Supercede;
    }
    
    if(m_lifestate == LIFE_DEAD || m_lifestate == LIFE_DYING)
    {
        hReturn.Value = false;
        return MRES_Supercede;
    }  
    // Target is not on CTs but is an admin. Valid
    if(GetClientTeam(entity) != CS_TEAM_CT)
    {
        if(CheckCommandAccess(pThis, "sm_spec_ct_only", ADMFLAG_KICK, true))
        {
            hReturn.Value = true;
        }
        else
        {
            hReturn.Value = false;
        }
        return MRES_Supercede;
    }
    else
    {
        hReturn.Value = true;
        return MRES_Supercede;
    }
}