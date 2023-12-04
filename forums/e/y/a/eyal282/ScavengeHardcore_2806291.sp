
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

/**
*    @param    sMapName                Map String without .bsp
*    @param    bShouldResetScores        Reset all scores in all gamemodes
*    @noreturn
*/
native void L4D2_ChangeLevel(const char[] sMapName, bool bShouldResetScores=true); 

#define PLUGIN_VERSION "1.0"
#pragma newdecls required

#pragma semicolon 1

public Plugin myinfo =
{
    name = "[L4D2] Scavenge Hardcore",
    author = "Eyal282",
    description = "Hardcore Scavenge Rules",
    version = "1.0",
    url = "None."
}

int ghostSpawnIncreaseByInfected[4] = {0, 10, 15, 20};

int ghostSpawnIncreasePerUnbalanced[4] = {5, 10, 15, 20};

int ghostSpawnDecreasePerUnbalanced[4] = {5, 10, 15, 20};

// Replace is done before remove. Replaced weapons are never removed.
char g_sRemoveMapWeapons[][] =
{
    "weapon_adrenaline_spawn",
    "weapon_defibrillator_spawn",
    "weapon_molotov_spawn",
    "weapon_pain_pills_spawn",
    "weapon_pipe_bomb_spawn",
    "weapon_propanetank_spawn",
    "weapon_vomitjar_spawn",
    "weapon_item_spawn",
    "weapon_melee_spawn",
    "weapon_autoshotgun_spawn",
    "weapon_chainsaw_spawn",
    "weapon_hunting_rifle_spawn",
    "weapon_pistol_magnum_spawn",
    "weapon_pistol_spawn",
    "weapon_pumpshotgun_spawn",
    "weapon_rifle_ak47_spawn",
    "weapon_rifle_desert_spawn",
    "weapon_rifle_m60_spawn",
    "weapon_rifle_sg552_spawn",
    "weapon_rifle_spawn",
    "weapon_shotgun_chrome_spawn",
    "weapon_shotgun_spas_spawn",
    "weapon_smg_mp5_spawn",
    "weapon_smg_silenced_spawn",
    "weapon_sniper_awp_spawn",
    "weapon_sniper_military_spawn",
    "weapon_sniper_scout_spawn",
    "weapon_spawn"
};

enum struct enReplaceWeapons 
{
    char sClassname[64];
    any wepID;

    // How many times can you take the new weapon before it disappears
    int count;

    // Maximum amount of entities to replace.
    int maxReplace;

    bool bSafeAreaOnly;


    // Ignore this.
    int currentReplace;
}

enReplaceWeapons g_sReplaceMapWeapons[] =
{
    { "weapon_spawn", L4D2WeaponId_Smg, 4, 1, true, 0 },
    { "weapon_spawn", L4D2WeaponId_SniperAWP, 4, 1, true, 0 },
    { "weapon_first_aid_kit_spawn", L4D2WeaponId_PainPills, 1, 4, true, 0},
    { "weapon_melee_spawn", L4D2WeaponId_Molotov, 9999, 1, true, 0 },
    { "weapon_melee_spawn", view_as<int>(L4D2WeaponId_UpgradeItem) + L4D2_WEPUPGFLAG_LASER, 9999, 1, true, 0 }
};

ConVar g_hAllBotGame;
ConVar g_hGamemode;
ConVar g_hStartingClock;
ConVar g_hGhostDelayMin;
ConVar g_hGhostDelayMax;
ConVar g_hGhostDelayTrueMin;

float g_fMapStartTime;

public Action L4D_OnMaterializeFromGhostPre(int client)
{
    if(!L4D_HasAnySurvivorLeftSafeArea())
        return Plugin_Handled;

    return Plugin_Continue;
}

public Action L4D_OnSpawnSpecial(int &zombieClass, const float vecPos[3], const float vecAng[3])
{
    if(!L4D_HasAnySurvivorLeftSafeArea())
        return Plugin_Handled;

    return Plugin_Continue;
}

public void OnPluginStart()
{
    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("scavenge_round_start", Event_ScavengeRoundStart, EventHookMode_Post);
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
    HookEvent("bot_player_replace", Event_PlayerReplacesABot, EventHookMode_Post);
    //HookEvent("gascan_pour_completed", Event_GasCanPourCompleted, EventHookMode_PostNoCopy);

    g_hAllBotGame = FindConVar("sb_all_bot_game");
    g_hGamemode = FindConVar("mp_gamemode");
    g_hStartingClock = FindConVar("scavenge_round_initial_time");
    g_hGhostDelayMin = FindConVar("z_ghost_delay_min");
    g_hGhostDelayMax = FindConVar("z_ghost_delay_max");
    g_hGhostDelayTrueMin = FindConVar("z_ghost_delay_minspawn");

    HookVoteMsgs();

    for(int i=1;i <= MaxClients;i++)
    {
        if(!IsClientInGame(i))
            continue;

        SDKHook(i, SDKHook_WeaponCanUse, SDKEvent_WeaponCanUse);
    }
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_WeaponCanUse, SDKEvent_WeaponCanUse);
}

public Action SDKEvent_WeaponCanUse(int client, int weapon)
{
    char sClassname[64];
    GetEdictClassname(weapon, sClassname, sizeof(sClassname));

    if(StrEqual(sClassname, "weapon_pistol"))
        return Plugin_Continue;

    if(GetEntityMoveType(client) == MOVETYPE_NONE)
        return Plugin_Handled;

    return Plugin_Continue;
}

public void OnMapStart()
{
    g_fMapStartTime = GetGameTime();
    
    
    TriggerTimer(CreateTimer(1.0, Timer_CheckConfig, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT));
    TriggerTimer(CreateTimer(60.0, Timer_CheckConfigLong, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT));
    CreateTimer(10.0, Timer_ScanGascans, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}

public Action Timer_ScanGascans(Handle hTimer)
{
    int entity = -1;

    while((entity = FindEntityByClassname(entity, "weapon_gascan")) != -1)
    {
        Scavenge_ScanGasCan(entity);
    }

    return Plugin_Continue;
}

public void Scavenge_ScanGasCan(int entity)
{
    float fOrigin[3];
    GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", fOrigin);

    ArrayList aEntities = new ArrayList(1);

    TR_EnumerateEntities(fOrigin, fOrigin, PARTITION_SOLID_EDICTS | PARTITION_TRIGGER_EDICTS | PARTITION_STATIC_PROPS, RayType_EndPoint, TraceEnum_TriggerHurt, aEntities);

    
    int size = GetArraySize(aEntities);
    delete aEntities;

    if(size > 0)
    {
        AcceptEntityInput(entity, "Ignite");

        PrintToChatAll("[Scavenge] A gas can was found out of bounds and was ignited.");
    }
}


public bool TraceEnum_TriggerHurt(int entity, ArrayList aEntities)
{
    // If we hit the world, stop enumerating.
    if (!entity)
        return false;

    else if (!IsValidEdict(entity))
        return false;

    char sClassname[24];
    GetEdictClassname(entity, sClassname, sizeof(sClassname));

    // Also works for trigger_hurt_ghost because some maps wager on the fact trigger_hurt_ghost kills the charger and the survivors dies from the fall itself.

    if (strncmp(sClassname, "trigger_hurt", 12) == 0)
    {
        TR_ClipCurrentRayToEntity(MASK_ALL, entity);

        if (TR_GetEntityIndex() != entity)
            return true;

        float fDamage = GetEntPropFloat(entity, Prop_Data, "m_flDamage");

        // Does it do incap damage?
        if (fDamage < 100)
            return true;

        int iDamagetype = GetEntProp(entity, Prop_Data, "m_bitsDamageInflict");

        // Does it simulate a fall or water?
        if (iDamagetype != DMG_FALL && iDamagetype != DMG_DROWN)
            return true;

        aEntities.Push(entity);

        return true;
    }

    return true;
}
public Action Timer_CheckConfig(Handle hTimer)
{
    int count, survivorCount, infectedCount;
    bool bLoading = false;

    for(int i=1;i <= MaxClients;i++)
    {
        if(IsClientConnected(i) && !IsClientInGame(i))
            bLoading = true;
        
        if(!IsClientInGame(i))
            continue;

        else if(IsFakeClient(i))
            continue;

        switch(L4D_GetClientTeam(i))
        {
            case L4DTeam_Survivor:
            {
                count++;

                if(IsPlayerAlive(i))
                    survivorCount++;
            }
            case L4DTeam_Infected:
            {
                count++;
                infectedCount++;
            }
            case L4DTeam_Unassigned:
            {
                bLoading = true;
            }
        }
    }

    if(count == 0)
    {
        g_hAllBotGame.BoolValue = false;
    }
    else if(!bLoading)
    {
        g_hAllBotGame.BoolValue = true;
        g_hStartingClock.IntValue = 300;

        char MapName[32];

        GetCurrentMap(MapName, sizeof(MapName));
        
        if(!StrEqual(MapName, "c8m5_rooftop") && !StrEqual(MapName, "c14m2_lighthouse"))
        {

            g_fMapStartTime = GetGameTime();

            L4D2_ChangeLevel("c8m5_rooftop");

            return Plugin_Stop;
        } 
        // Weird bug.
        char sValue[32];
        g_hGamemode.GetString(sValue, sizeof(sValue));

        if(StrEqual(sValue, "scavenge") && GetGameTime() - g_fMapStartTime > 5.0 && GameRules_GetProp("m_nScavengeItemsRemaining") == 0 && GameRules_GetProp("m_nScavengeItemsGoal") == 0 && GetGasCanCount() == 0)
        {
            Scavenge_FixNoGascanSpawnBug();

            return Plugin_Continue;
        }
        else if(!StrEqual(sValue, "scavenge"))
        {
            g_hGamemode.SetString("scavenge");
        }
    }


    if(infectedCount == 0)
        return Plugin_Continue;

    int timer = ghostSpawnIncreaseByInfected[infectedCount-1];

    if(infectedCount > survivorCount)
    {
        timer += ghostSpawnIncreasePerUnbalanced[(infectedCount - survivorCount - 1)];
    }
    else if(survivorCount > infectedCount)
    {
        timer -= ghostSpawnDecreasePerUnbalanced[(survivorCount - infectedCount - 1)];
    }

    g_hGhostDelayTrueMin.IntValue = timer;
    g_hGhostDelayMin.IntValue = timer;
    g_hGhostDelayMax.IntValue = timer;

    return Plugin_Continue;
}



public Action Timer_CheckConfigLong(Handle hTimer)
{
    int count;

    for(int i=1;i <= MaxClients;i++)
    {        
        if(!IsClientInGame(i))
            continue;

        else if(IsFakeClient(i))
            continue;

        switch(L4D_GetClientTeam(i))
        {
            case L4DTeam_Survivor:
            {
                count++;
            }
            case L4DTeam_Infected:
            {
                count++;
            }
        }
    }

    if(count == 0)
    {
        g_hAllBotGame.BoolValue = false;

        CreateTimer(0.0, Timer_RestartGame);
    }

    return Plugin_Continue;
}
public Action Event_RoundStart(Handle hEvent, const char[] Name, bool dontBroadcast)
{
    CreateTimer(1.0, Timer_ReplaceWeapons);

    return Plugin_Continue;
}

public Action Event_ScavengeRoundStart(Handle hEvent, const char[] Name, bool dontBroadcast)
{
    for(int i=1;i <= MaxClients;i++)
    {
        if(!IsClientInGame(i))
            continue;

        else if(L4D_GetClientTeam(i) != L4DTeam_Survivor)
            continue;

        SetEntityMoveType(i, MOVETYPE_WALK);
    }

    return Plugin_Continue;
}

public Action Event_PlayerSpawn(Handle hEvent, const char[] Name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));

    if(L4D_GetClientTeam(client) != L4DTeam_Survivor)
        return Plugin_Continue;

    else if(L4D_HasAnySurvivorLeftSafeArea())
        return Plugin_Continue;

    if(IsFakeClient(client))        
        SetEntityMoveType(client, MOVETYPE_NONE);

    else
        SetEntityMoveType(client, MOVETYPE_WALK);

    return Plugin_Continue;
}

public Action Event_PlayerReplacesABot(Handle hEvent, const char[] Name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(hEvent, "player"));

    if(L4D_GetClientTeam(client) != L4DTeam_Survivor)
        return Plugin_Continue;

    else if(L4D_HasAnySurvivorLeftSafeArea())
        return Plugin_Continue;
    
    SetEntityMoveType(client, MOVETYPE_WALK);

    return Plugin_Continue;
}

public Action Timer_ReplaceWeapons(Handle hTimer)
{

    for(int i=0;i < sizeof(g_sReplaceMapWeapons);i++)
    {
        g_sReplaceMapWeapons[i].currentReplace = g_sReplaceMapWeapons[i].maxReplace;
    }

    int count = GetEntityCount();

    for(int ent=MaxClients+1;ent < count;ent++)
    {
        if(!IsValidEdict(ent))
            continue;

        char sClassname[64];
        GetEdictClassname(ent, sClassname, sizeof(sClassname));

        for(int i=0;i < sizeof(g_sReplaceMapWeapons);i++)
        {	
            
            if(StrEqual(sClassname, g_sReplaceMapWeapons[i].sClassname))
            {
                
                float fOrigin[3];

                GetEntPropVector(ent, Prop_Data, "m_vecAbsOrigin", fOrigin);

                if(!g_sReplaceMapWeapons[i].bSafeAreaOnly || IsPositionInScavengeCheckpoint(fOrigin))
                {
                    if(g_sReplaceMapWeapons[i].currentReplace > 0)
                    {
                        g_sReplaceMapWeapons[i].currentReplace--;

                        OnSpawnPost_ReplaceWeaponSpawn(ent, i);

                        i = 999999;
                    }
                }
            }
        }
    }

    CreateTimer(0.3, Timer_RemoveIllegalWeapons, _, TIMER_FLAG_NO_MAPCHANGE);

    return Plugin_Continue;
}

public Action Timer_RemoveIllegalWeapons(Handle hTimer)
{
    int count = GetEntityCount();

    for(int ent=MaxClients+1;ent < count;ent++)
    {
        if(!IsValidEdict(ent))
            continue;

        char sClassname[64];
        GetEdictClassname(ent, sClassname, sizeof(sClassname));

        for(int i=0;i < sizeof(g_sRemoveMapWeapons);i++)
        {
            if(StrEqual(sClassname, g_sRemoveMapWeapons[i]))
            {
                char iName[64];
                GetEntPropString(ent, Prop_Data, "m_iName", iName, sizeof(iName));

                if(!StrEqual(iName, "ScavengeHardcore"))
                {
                    AcceptEntityInput(ent, "Kill");

                    i = 999999;
                }
            }
        }
    }

    return Plugin_Stop;
}

public void OnSpawnPost_ReplaceWeaponSpawn(int entity, int replaceIndex)
{
    DataPack DP;
    CreateDataTimer(0.1, Timer_ReplaceWeaponSpawn, DP, TIMER_FLAG_NO_MAPCHANGE);

    WritePackCell(DP, EntIndexToEntRef(entity));
    WritePackCell(DP, replaceIndex);
}

public Action Timer_ReplaceWeaponSpawn(Handle hTimer, DataPack DP)
{
    ResetPack(DP);

    int entity = EntRefToEntIndex(ReadPackCell(DP));
    int replaceIndex = ReadPackCell(DP);

    if(entity == INVALID_ENT_REFERENCE)
        return Plugin_Stop;

    float fOrigin[3], fAngles[3];

    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", fOrigin);
    GetEntPropVector(entity, Prop_Send, "m_angRotation", fAngles);

    AcceptEntityInput(entity, "Kill");

    if(g_sReplaceMapWeapons[replaceIndex].wepID > L4D2WeaponId_UpgradeItem)
    {

        int spawn;
        switch(g_sReplaceMapWeapons[replaceIndex].wepID - L4D2WeaponId_UpgradeItem)
        {
            case L4D2_WEPUPGFLAG_INCENDIARY: spawn = CreateEntityByName("upgrade_ammo_incendiary");
            case L4D2_WEPUPGFLAG_EXPLOSIVE: spawn = CreateEntityByName("upgrade_ammo_explosive");
            case L4D2_WEPUPGFLAG_LASER: spawn = CreateEntityByName("upgrade_laser_sight");
            default: return Plugin_Stop;
        }

        //SetEntProp(spawn, Prop_Data, "m_weaponID", g_sReplaceMapWeapons[replaceIndex].wepID);
        TeleportEntity(spawn, fOrigin, NULL_VECTOR, NULL_VECTOR);
        DispatchSpawn(spawn);
        SetEntityMoveType(spawn, MOVETYPE_NONE);
    }
    else
    {
        int spawn = CreateEntityByName("weapon_spawn");

        SetEntProp(spawn, Prop_Data, "m_weaponID", g_sReplaceMapWeapons[replaceIndex].wepID);
        SetEntPropString(spawn, Prop_Data, "m_iName", "ScavengeHardcore");

        char sCount[11];
        IntToString(g_sReplaceMapWeapons[replaceIndex].count, sCount, sizeof(sCount));

        DispatchKeyValue(spawn, "count", sCount);
        TeleportEntity(spawn, fOrigin, fAngles, NULL_VECTOR);
        DispatchSpawn(spawn);
        SetEntityMoveType(spawn, MOVETYPE_NONE);
    }


    return Plugin_Stop;
}

void HookVoteMsgs()
{
    char msgname[64];
    int i = 1;
    while( i )
    {
        if( GetUserMessageName(view_as<UserMsg>(i), msgname, sizeof msgname) )
        {
            if( strcmp(msgname, "PZEndGamePanelMsg") == 0 )
            {
                HookUserMessage(view_as<UserMsg>(i), OnMessage, true);
                break;
            }

            i++;
        } else {
            i = 0;
        }
    }
}

public Action OnMessage(UserMsg msg_id, BfRead hMsg, const int[] players, int playersNum, bool reliable, bool init)
{
    CreateTimer(1.0, Timer_RestartGame, _, TIMER_FLAG_NO_MAPCHANGE);

    return Plugin_Handled;
}

public Action Timer_RestartGame(Handle hTimer)
{
    ServerCommand("exec server.cfg");

    Scavenge_RestartGame();
    
    g_fMapStartTime = GetGameTime();

    return Plugin_Stop;

}


public Action L4D_OnSpawnTank(const float vecPos[3], const float vecAng[3])
{
    return Plugin_Handled;
}

public void RPG_Perks_OnGetSpecialInfectedClass(int priority, int client, L4D2ZombieClassType &zclass)
{
    if(priority != 0)
        return;
        
    else if(zclass != L4D2ZombieClass_Boomer)
        return;

    L4D2ZombieClassType zclassList[] = { L4D2ZombieClass_Charger, L4D2ZombieClass_Smoker, L4D2ZombieClass_Hunter, L4D2ZombieClass_Jockey, L4D2ZombieClass_Spitter };

    for(int i=0;i < sizeof(zclassList);i++)
    {
        if(Scavenge_CountHumanSpecialInfected(zclassList[i]) <= 0)
        {
            zclass = zclassList[i];

            return;
        }
    }
}


public Action L4D_OnIsTeamFull(int team, bool &full)
{
    int teamCount;
    bool bLoading = false;

    for(int i=1;i <= MaxClients;i++)
    {
        if(IsClientConnected(i) && !IsClientInGame(i))
            bLoading = true;
        
        if(!IsClientInGame(i))
            continue;

        else if(IsFakeClient(i))
            continue;

        else if(L4D_GetClientTeam(i) != view_as<L4DTeam>(team))
        {
        teamCount++;
        }
    }

    if(teamCount >= 4)
    {
        full = true;
        return Plugin_Handled;
    }

    return Plugin_Continue;
    
}

public Action L4D2_CGasCan_ShouldStartAction(int client, int gascan, int nozzle)
{

    float fOrigin[3], fNozzleOrigin[3];
    GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", fOrigin);
    GetEntPropVector(nozzle, Prop_Data, "m_vecOrigin", fNozzleOrigin);

    if(fOrigin[2] - fNozzleOrigin[2] > -40.0)
        return Plugin_Handled;

    return Plugin_Continue;
}

stock bool IsPositionInScavengeCheckpoint(float fOrigin[3])
{
    Address navarea = L4D_GetNearestNavArea(fOrigin);

    if(navarea == Address_Null)
        return false;

    int spawnAttributes = L4D_GetNavArea_SpawnAttributes(navarea);

    if(!(spawnAttributes & NAV_SPAWN_CHECKPOINT))
        return false;

    int nozzle = -1;

    while((nozzle = FindEntityByClassname(nozzle, "point_prop_use_target")) != -1)
    {
        char sNozzleTargetname[3];
        GetEntPropString(nozzle, Prop_Data, "m_sGasNozzleName", sNozzleTargetname, sizeof(sNozzleTargetname));

        // Not a real nozzle, probably a plugin made it.
        if(sNozzleTargetname[0] == EOS)
            continue;

        float fOrigin1[3], fOrigin2[3];
        GetEntPropVector(nozzle, Prop_Data, "m_vecAbsOrigin", fOrigin1);
        L4D_GetNavAreaCenter(navarea, fOrigin2);

        if(GetVectorDistance(fOrigin1, fOrigin2) > 512.0)
            return false;

        return true;
    }

    return false;
}

stock int GetGasCanCount()
{
    int count;
    int entCount = GetEntityCount();

    for(int ent=MaxClients+1;ent < entCount;ent++)
    {
        if(!IsValidEdict(ent))
            continue;

        char sClassname[64];
        GetEdictClassname(ent, sClassname, sizeof(sClassname));

        if(StrEqual(sClassname, "weapon_gascan") || StrEqual(sClassname, "weapon_gascan_spawn"))
            count++;
    }

    return count;
}

stock void Scavenge_FixNoGascanSpawnBug()
{   
    char sSignature[128];
    sSignature = "@_ZN9CDirector21SpawnAllScavengeItemsEv";

    Handle Call = INVALID_HANDLE;
    if (Call == INVALID_HANDLE)
    {
        StartPrepSDKCall(SDKCall_Raw);
        if (!PrepSDKCall_SetSignature(SDKLibrary_Server, sSignature, strlen(sSignature)-1))
        {
            return;
        }

        Call = EndPrepSDKCall();
        if (Call == INVALID_HANDLE)
        {
            return;
        }
    }

    SDKCall(Call, L4D_GetPointer(POINTER_DIRECTOR));
}

stock void Scavenge_RestartGame()
{
    
    char sSignature[128];
    sSignature = "@_ZN9CDirector7RematchEv";

    Handle Call = INVALID_HANDLE;
    if (Call == INVALID_HANDLE)
    {
        StartPrepSDKCall(SDKCall_Raw);
        if (!PrepSDKCall_SetSignature(SDKLibrary_Server, sSignature, strlen(sSignature)-1))
        {
            return;
        }

        Call = EndPrepSDKCall();
        if (Call == INVALID_HANDLE)
        {
            return;
        }
    }

    SDKCall(Call, L4D_GetPointer(POINTER_DIRECTOR));

    
    Handle event = CreateEvent("vote_passed");
    SetEventString(event, "details", "Game will continue");
    SetEventString(event, "param1", "Game will continue.");
    SetEventInt(event, "team", 0);
    FireEvent(event);
    
    Handle msg = StartMessageAll("VotePass", USERMSG_RELIABLE);
    
    BfWriteByte(msg, 0);
    BfWriteString(msg, "Game will continue");
    BfWriteString(msg, "Game will continue");
    EndMessage();
    
    sSignature = "@_ZN15CVoteController5SpawnEv";
    Call = INVALID_HANDLE;

    if (Call == INVALID_HANDLE)
    {
        StartPrepSDKCall(SDKCall_Entity);
        if (!PrepSDKCall_SetSignature(SDKLibrary_Server, sSignature, strlen(sSignature)-1))
        {
            return;
        }

        Call = EndPrepSDKCall();
        if (Call == INVALID_HANDLE)
        {
            return;
        }
    }

    int entity = Scavenge_GetVoteController();

    SDKCall(Call, entity);
    
}

stock int Scavenge_CountHumanSpecialInfected(L4D2ZombieClassType zclass)
{
    int count;

    for(int i=1;i <= MaxClients;i++)
    {
        if(!IsClientInGame(i))
            continue;

        else if(IsFakeClient(i))
            continue;

        else if(!IsPlayerAlive(i))
            continue;

        else if(L4D_GetClientTeam(i) != L4DTeam_Infected)
            continue;

        else if(L4D2_GetPlayerZombieClass(i) != zclass)
            continue;

        count++;
    }
    
    return count;
}


stock int Scavenge_GetVoteController()
{
    int entity = FindEntityByClassname(-1, "vote_controller");

    if (entity == -1)
    {
        LogError("Could not find Vote Controller.");
        return -1;
    }

    return entity;
}

stock bool Scavenge_ResetActiveVote()
{
    int entity = Scavenge_GetVoteController();

    if(entity == -1)
        return false;

    SetEntProp(entity, Prop_Send, "m_onlyTeamToVote", -1);
    SetEntProp(entity, Prop_Send, "m_votesYes", 8);
    SetEntProp(entity, Prop_Send, "m_votesNo", 0);
    SetEntProp(entity, Prop_Send, "m_potentialVotes", 0);
    SetEntProp(entity, Prop_Send, "m_activeIssueIndex", 0);

    return true;
}