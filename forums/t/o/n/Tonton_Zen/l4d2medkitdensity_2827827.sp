/********************************************************************************************
* Plugin    : [L4D2] Medkit Density in Versus/TeamVersus or Coop/Realism/Versus/TeamVersus
* Version    : 1.6.6
* Game        : Left 4 Dead 2
* Author    : SwiftReal (Yves), Tonton Zen
* Testers    : Myself, SwiftReal, Mika Misori
* Website    : forums.alliedmods.net
* 
* Purpose    : This plugin removes, replaces, doubles or leaves medkits
*               at the start of a campaign, at checkpoints/safehouses and in the outdoors.
* 
* WARNING    : Please use sourcemod's latest 1.10 branch snapshot.
*
* Version 1.6.6
*         - Only use delayed saferoom timer when option is set to add kits matching 5 players and more on multislot servers.
*
* Version 1.6.5
*         - Ensure the delayed saferoom timer does not run more than once.
*
* Version 1.6.4
*         - Changed starting point timer according to number of starting kits to enable replacement
*
* Version 1.6.3
*         - Changed all code to new sourcepawn syntax
*         - Added extra kits at finale
*         - Bug fixes
*
* Version 1.6
*         - Added the option to add kits in saferoom or start to match the number of players
* 
* Version 1.5
*         - added FCVAR_NOTIFY cvar flags to all cvars
*         - added ability to have infite medkits at start, saferoom and outdoors
*         - removed round_freeze_end event, applied different method
* Version 1.4
*         - remove abilities to double, tripple or quadruple medkitcount at start, checkpoints and outdoors
*         - added ability to set a specified amount of medkits at start and checkpoints
*         - added ability to replace each outdoor medkit with specified amount of medkits
*         - fixed case where random outdoor medkit was treated like a saferoom medkit
*         - changed method of spawning saferoom medkits to gradually spawning
*         - changed the method of finding entities
*         - sm_md_start now effects every medkit at start of every map in versus games
* Version 1.3.2
*         - fixed a bug where a survivor has his medkit removed from him/her
*         - other minor changes 
* Version 1.3.1
*         - applied another way to carry over the correct amount of medkits at checkpoint to next map
*         - added a reset on closest medkit location on mapchange
*         - changed convar limits for tripple, quadruple and 1defib+3medkits to work
* Version 1.3
*         - really fixed carrying over the correct amount of medkits at checkpoint to next map
*         - fixed replacing some outdoor medkits that the director spawned late into the game
*         - added the abilities to tripple or quadruple medkitcount at start, checkpoints and outdoors
*         - added the ability to replace 1 of 4 medkits with 1 defibrillator at start and checkpoints
* Version 1.2
*         - fixed carrying over the correct amount of medkits at checkpoint to next map
* Version 1.1
*         - set convar min and max limits
*         - fixed issue with spawning way too many medkits after a few fail rounds
* Version 1.0
*          - Initial release
* 
********************************************************************************************/

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION        "1.6.6"
#define CVAR_FLAGS            FCVAR_PLUGIN|FCVAR_NOTIFY
#define MEDKIT                "models/w_models/weapons/w_eq_medkit.mdl"
#define DEFIB                "models/w_models/weapons/w_eq_defibrillator.mdl"
#define PILLS                "models/w_models/weapons/w_eq_painpills.mdl"

Handle h_PluginEnabled;
Handle h_OnlyVersus;
Handle h_KitsStart;
Handle h_KitsStartCount;
Handle h_KitsSaferoom;
Handle h_KitsSaferoomCount;
Handle h_KitsOutdoors;
Handle h_KitsOutdoorsCount;
Handle timer_DensityOutdoors = INVALID_HANDLE;
Handle timer_DelayChangeSaferoom = INVALID_HANDLE;
Handle h_Debug;
char g_MapName[128];
char g_GameMode[32];
float vecLocationStart[3];
float vecClosestKitStart[3];
float vecLocationCheckpoint[3];
float vecClosestKitCheckpoint[3];
int g_iKitsSpawned = 0;
bool g_bFirstItemPickedUp;
bool g_bDebug = true;
int g_Debug;
bool g_bFinale;

public Plugin myinfo = 
{
    name            = "[L4D2] Medkit Density",
    author            = "SwiftReal, Tonton Zen",
    description        = "Removes, replaces or adds medkits at start, saferooms and outdoors",
    version            = PLUGIN_VERSION,
    url                = "http://forums.alliedmods.net/showthread.php?p=1121462"
}

public void OnPluginStart()
{
    new String:GameFolder[50];
    GetGameFolderName(GameFolder, sizeof(GameFolder));
    if(!StrEqual(GameFolder, "left4dead2", false))
        SetFailState("Medkit Density supports Left 4 Dead 2 only");
    
    // Register Cmds and Cvars
    CreateConVar("medkitdensity_version", PLUGIN_VERSION, "Medkit Density version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
    SetConVarString(FindConVar("medkitdensity_version"), PLUGIN_VERSION);
    
    h_PluginEnabled            = CreateConVar("sm_md_enabled", "1", "Should the plugin be on? 1[on] 2[off]", 0, true, 0.0, true, 1.0);
    h_OnlyVersus               = CreateConVar("sm_md_versusonly", "0", "Change medkit density in versus games only? 0[coop,realism,versus,teamversus] 1[versus,teamversus]", 0, true, 0.0, true, 1.0);
    h_KitsStart                = CreateConVar("sm_md_start", "1", "What to do with medkits at the start? (coop: start of campaign)(versus: start of every map) 0[do nothing] 1[use sm_md_start_medkitcount] 2[remove medkits] 3[replace with pills] 4[replace with defibrillators] 5[infinite] 6[change 1 medkit into defibrillator] 7[match players]", 0, true, 0.0, true, 7.0);
    h_KitsStartCount           = CreateConVar("sm_md_start_medkitcount", "8", "At start, replace medkits with how many medkits?", 0, true, 4.0, true, 20.0);
    h_KitsSaferoom             = CreateConVar("sm_md_saferoom", "1", "What to do with medkits in saferooms? 0[do nothing] 1[use sm_md_checkpoint_medkitcount] 2[remove medkits] 3[replace with pills] 4[replace with defibrillators] 5[infinite] 6[change 1 medkit into defibrillator] 7[match players", 0, true, 0.0, true, 7.0);
    h_KitsSaferoomCount        = CreateConVar("sm_md_saferoom_medkitcount", "12", "In saferooms, replace medkits with how many medkits?", 0, true, 4.0, true, 20.0);
    h_KitsOutdoors             = CreateConVar("sm_md_outdoors", "1", "What to do with each medkit outdoors? 0[do nothing] 1[use sm_md_outdoors_medkitcount] 2[remove medkits] 3[replace with pills] 4[replace with defibrillators] 5[infinite]", 0, true, 0.0, true, 5.0);
    h_KitsOutdoorsCount        = CreateConVar("sm_md_outdoors_medkitcount", "2", "With how many medkits should each medkit in the outdoors be replaced?", 0, true, 2.0, true, 10.0);
    h_Debug                    = CreateConVar("sm_md_debug", "0", "Turn on debug logging? 0[off] 1-3[level]", 0, true, 0.0, true, 3.0);

    // Execute or create cfg
    AutoExecConfig(true, "l4d2medkitdensity");

    // Hook Events
    HookEvent("item_pickup", evtItemPickup);
    HookEvent("mission_lost", evtMissionLost);
    HookEvent("round_start", evtRoundStarted);   
}

public void OnConfigsExecuted()
{
    g_Debug = GetConVarInt(h_Debug);
    g_bDebug = (g_Debug > 0) ? true : false;
    LogMessage("SM_MD: Plugin config executed. Debug is %d which is %s.", g_Debug, (g_bDebug) ? "ON" : "OFF");
}

public void OnMapStart()
{
    g_Debug = GetConVarInt(h_Debug);
    g_bDebug = (g_Debug > 0) ? true : false;
    g_bFirstItemPickedUp = false;
    if(g_bDebug)
        LogMessage("SM_MD: MapStart");
    
    if(!IsModelPrecached(MEDKIT)) PrecacheModel(MEDKIT, true);
    if(!IsModelPrecached(DEFIB)) PrecacheModel(DEFIB, true); 
    if(!IsModelPrecached(PILLS)) PrecacheModel(PILLS, true);
}

public Action evtItemPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
    int iKitsStart = GetConVarInt(h_KitsStart);
    float f_delay = (iKitsStart == 7) ? 10.0 : 0.1;

    if(GetConVarBool(h_PluginEnabled))
    {
        g_Debug = GetConVarInt(h_Debug);
        g_bDebug = (g_Debug > 0) ? true : false;
        if(!g_bFirstItemPickedUp)
        {
            g_bFirstItemPickedUp = true;
            CreateTimer(f_delay, Timer_DelayChangeDensity);
            if(g_bDebug)
                LogMessage("SM_MD: FirstItemPickup actioned true");
        }
    }
    return Plugin_Handled;
}

public void OnClientDisconnect(client)
{
    if(!RealPlayersInGame(client))
    {
        if(timer_DelayChangeSaferoom != INVALID_HANDLE)
        {
            KillTimer(timer_DelayChangeSaferoom);
            timer_DelayChangeSaferoom = INVALID_HANDLE;
        }
        if(timer_DensityOutdoors != INVALID_HANDLE)
        {
            KillTimer(timer_DensityOutdoors);
            timer_DensityOutdoors = INVALID_HANDLE;
        }
        g_bFirstItemPickedUp = false;
    }
}

public Action evtMissionLost(Handle:event, const String:name[], bool:dontBroadcast)
{
    g_bFirstItemPickedUp = false;
    if(timer_DelayChangeSaferoom != INVALID_HANDLE)
    {
        KillTimer(timer_DelayChangeSaferoom);
        timer_DelayChangeSaferoom = INVALID_HANDLE;
    }
    if(timer_DensityOutdoors != INVALID_HANDLE)
    {
        KillTimer(timer_DensityOutdoors);
        timer_DensityOutdoors = INVALID_HANDLE;
    }
    if(g_bDebug)
        LogMessage("SM_MD: MissionLost");

    return Plugin_Handled;
}

public Action evtRoundStarted(Handle:event, const String:name[], bool:dontBroadcast)
{
    g_iKitsSpawned = 0;
    g_bFinale = false;
    g_Debug = GetConVarInt(h_Debug);
    g_bDebug = (g_Debug > 0) ? true : false;

    if(g_bDebug)
        LogMessage("SM_MD: Round start.");
    if(FindEntityByClassname(-1, "trigger_finale") > -1)
    {
        g_bFinale = true;
        if(g_bDebug)
            LogMessage("SM_MD: Finale detected");
    }
    return Plugin_Handled;
}

public Action Timer_DelayChangeDensity(Handle:timer)
{
    int iKitsSaferoom = GetConVarInt(h_KitsSaferoom);

    GetCurrentMap(g_MapName, sizeof(g_MapName));
    GetConVarString(FindConVar("mp_gamemode"), g_GameMode, sizeof(g_GameMode));
    bool bOnlyVersus = GetConVarBool(h_OnlyVersus);
    if((StrContains(g_GameMode, "versus", false) != -1) || ((StrContains(g_GameMode, "scavenge", false) == -1) && !bOnlyVersus))
    {
        if(g_bDebug)
        {
            LogMessage("SM_MD: Start of Delayed calls");
            LogMessage("SM_MD: Map %s", g_MapName);
            LogMessage("SM_MD: Human survivor players = %d", GetSurvivorCount());
        }
        FindLocationStart();
        FindLocationSaferoom();
        SetKitsDensity_Start();
        if(iKitsSaferoom == 7)
        {
            if(g_bDebug)
                LogMessage("SM_MD: Saferoom kit option 7, match 5+ players and use a timer to get best amount of players.");
            timer_DelayChangeSaferoom = CreateTimer(10.0, Timer_DelayChangeSaferoom, _, TIMER_REPEAT);
        } else {
            if(g_bDebug)
                LogMessage("SM_MD: Saferoom kit option not 7, no need for a timer set saferoom options immediately.");
            SetKitsDensity_Saferoom();
        }
        if(timer_DensityOutdoors == INVALID_HANDLE)
            timer_DensityOutdoors = CreateTimer(10.0, Timer_DensityOutdoors, _, TIMER_REPEAT);
    }
    return Plugin_Handled;
}

public Action Timer_DelayChangeSaferoom(Handle:timer)
{
    if(g_bDebug)
        LogMessage("SM_MD: Checking distance from survivors to checkpoint.");

    for(new i = 1; i <= MaxClients; i++)
    {
        if(!IsClientConnected(i))
            continue;
        if(!IsClientInGame(i))
            continue;
        if(GetClientTeam(i) != 2)
            continue;
        
        float vecOrigin[3];
        GetClientAbsOrigin(i, vecOrigin);
        
        if(FloatAbs(GetVectorDistance(vecOrigin, vecLocationCheckpoint, false)) < 1200.0){
            if(g_bDebug)
            {
                LogMessage("SM_MD: Player close enough to saferoom to alter saferoom kits.");
                //PrintToChatAll("SM_MD: Player close enough to saferoom to alter saferoom kits.");
            }
            KillTimer(timer, false);
            timer_DelayChangeSaferoom = INVALID_HANDLE;

            SetKitsDensity_Saferoom();
            return Plugin_Stop;
        }
    }
    return Plugin_Handled;
}

public Action Timer_DensityOutdoors(Handle:timer)
{
    SetDensity_Outdoors();
    if(timer_DensityOutdoors != INVALID_HANDLE)
    {
        KillTimer(timer_DensityOutdoors);
        timer_DensityOutdoors = INVALID_HANDLE;
    }
    return Plugin_Stop;
}

stock FindLocationStart()
{
    int ent;
    float vecLocation[3];
 
    // search for a survivor spawnpoint if first map of campaign
    if((ent = FindEntityByClassname(-1, "info_survivor_position")) != -1)
    {
        if(IsValidEntity(ent))
        {
            GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecLocation);
            vecLocationStart = vecLocation;
        }
        if(g_bDebug)
            LogMessage("SM_MD: info_survivor_position detected");
        return;
    }

    if((ent = FindEntityByClassname(-1, "info_player_start")) != -1)
    {
        if(IsValidEntity(ent))
        {
            GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecLocation);
            vecLocationStart = vecLocation;
        }
        if(g_bDebug)
            LogMessage("SM_MD: info_player_start detected");
    }
    return;
}

stock FindLocationSaferoom()
{
    int ent;
    float curDistance = -1.0;
    float tempDistance;
    float vecLocation[3];

    if(g_bDebug)
        LogMessage("SM_MD: Searching saferoom/finale locations");

    if ( !g_bFinale )
    {
        // Search for a locked checkpoint door...
        ent = -1;
        while((ent = FindEntityByClassname(ent, "prop_door_rotating_checkpoint")) != -1)
        {
            if(IsValidEntity(ent))
            {
                if(GetEntProp(ent, Prop_Send, "m_bLocked") != 1)
                {
                    GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecLocation);
                
                    // Remember the farthest one only
                    tempDistance = GetVectorDistance(vecLocationStart, vecLocation, false);
                    if( tempDistance > curDistance)
                    {
                        vecLocationCheckpoint = vecLocation;
                        curDistance = tempDistance;
                    }
                }
            }
        }
    }
    else
    {
        // Is there a finale trigger instead?
        ent = -1;
        while((ent = FindEntityByClassname(ent, "trigger_finale")) != -1)
        {
            if(IsValidEntity(ent))
            {
                GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecLocation);
                vecLocationCheckpoint = vecLocation;
            }
        }
    }

    // search for an ammo pile close to checkpoint
    ent = -1;
    while((ent = FindEntityByClassname(ent, "weapon_ammo_spawn")) != -1)
    {
        if(IsValidEntity(ent))
        {
            GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecLocation);
            if(GetVectorDistance(vecLocationCheckpoint, vecLocation, false) < 1000)
            {
                vecLocationCheckpoint = vecLocation;
                break;
            }
        }
    }
    
    // Find closest medkit nearby a checkpoint door
    vecClosestKitCheckpoint[0] = 0.0;
    vecClosestKitCheckpoint[1] = 0.0;
    vecClosestKitCheckpoint[2] = 0.0;
    ent = -1;
    while((ent = FindEntityByClassname(ent, "weapon_first_aid_kit_spawn")) != -1)
    {
        if(IsValidEntity(ent))
        {
            GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecLocation);
            // If vecClosestKit is zero, then this must be the first medkit we found.
            if((vecClosestKitCheckpoint[0] + vecClosestKitCheckpoint[1] + vecClosestKitCheckpoint[2]) == 0.0)
                vecClosestKitCheckpoint = vecLocation;
            
            // If this medkit is closer than the last medkit, record its location.
            if(GetVectorDistance(vecLocationCheckpoint, vecLocation, false) < GetVectorDistance(vecLocationCheckpoint, vecClosestKitCheckpoint, false))
                vecClosestKitCheckpoint = vecLocation;
        }
    }
    if(g_Debug > 1)
        LogMessage("SM_MD: Closest kit to checkpoint at coords: X=%f Y=%f Z=%f", vecClosestKitCheckpoint[0], vecClosestKitCheckpoint[1], vecClosestKitCheckpoint[2]);
    return;
}

stock SetKitsDensity_Start()
{    
    int ent;
    float vecLocation[3];
    int iKitsStart = GetConVarInt(h_KitsStart);
    int iKitsStartCount = GetConVarInt(h_KitsStartCount);

    if(g_bDebug)
        LogMessage("SM_MD: Start Positions function entry");

    if(iKitsStart == 7)
    {
        iKitsStartCount = GetSurvivorCount();
        iKitsStart = 1;
        if(g_bDebug)
            LogMessage("SM_MD: Start kits option 7 found %d survivors.", iKitsStartCount);
        if (iKitsStartCount <4)
        {
            iKitsStartCount = 4;
            if(g_bDebug)
                LogMessage("SM_MD: Less than 4 human players, set playercount to 4");
        }
    }

    // Find closest medkit nearby survivors start
    ent = -1;
    while((ent = FindEntityByClassname(ent, "weapon_first_aid_kit_spawn")) != -1)
    {
        if(IsValidEntity(ent))
        {
            GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecLocation);
            
            // If vecClosestKit is zero, then this must be the first medkit we found.
            if((vecClosestKitStart[0] + vecClosestKitStart[1] + vecClosestKitStart[2]) == 0.0)
                vecClosestKitStart = vecLocation;
            
            // If this medkit is closer than the last medkit, record its location.
            if(GetVectorDistance(vecLocationStart, vecLocation, false) < GetVectorDistance(vecLocationStart, vecClosestKitStart, false))
                vecClosestKitStart = vecLocation;
        }
    }
    if(g_bDebug)
        LogMessage("SM_MD: Closest kit to survivors at coords: X=%f Y=%f Z=%f", vecClosestKitStart[0], vecClosestKitStart[1], vecClosestKitStart[2]);


    // Remove, replace or leave the medkits near it
    ent = -1;
    while((ent = FindEntityByClassname(ent, "weapon_first_aid_kit_spawn")) != -1)
    {
        if(IsValidEntity(ent))
        {
            GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecLocation);
            if(GetVectorDistance(vecClosestKitStart, vecLocation, false) < 200)
            {
                if(g_Debug > 1)
                    LogMessage("SM_MD: Found kit %d within 200 distance of closest kit.", ent);
                if((StrContains(g_MapName, "m1_", false) != -1) || StrContains(g_GameMode, "versus", false) != -1)
                {
                    switch(iKitsStart)
                    {
                        case 0:
                        {
                            break;
                        }
                        case 1:
                        {
                            if(iKitsStartCount > 4)
                            {
                                // set medkit count (1 medkit found, 6 medkits in total)
                                if(g_bDebug)
                                    LogMessage("SM_MD: Need to add more kits.");
                                if(StrContains(g_MapName, "c4m1", false) != -1)
                                {
                                    if(iKitsStartCount > 6)
                                    {
                                        iKitsStartCount -= 5;
                                    }
                                    else if(iKitsStartCount == 5)
                                    {
                                        AcceptEntityInput(ent, "Kill");
                                        break;
                                    }
                                    else
                                    {
                                        break;
                                    }
                                }
                                // set medkit count (1 medkit found, 4 medkits in total)
                                else
                                {
                                    iKitsStartCount -= 3;
                                }                                
                                float fCount = float(iKitsStartCount);
                                DispatchKeyValueFloat(ent, "count", fCount);
                                if(g_Debug > 1)
                                    LogMessage("SM_MD: Changed kit count for %d to %f start.", ent, fCount);
                                break;
                            }
                        }
                        case 2:
                        {
                            AcceptEntityInput(ent, "Kill");
                            if(g_bDebug)
                                LogMessage("SM_MD: Kit %d removed.", ent);
                        }
                        case 3:
                        {
                            ReplaceOrAddEnt(ent, "weapon_pain_pills", true);
                            if(g_bDebug)
                                LogMessage("SM_MD: Kit %d replaced by pills.", ent);
                        }
                        case 4:
                        {
                            ReplaceOrAddEnt(ent, "weapon_defibrillator", true);
                            if(g_bDebug)
                                LogMessage("SM_MD: Kit %d replaced by defib.", ent);
                        }
                        case 5:
                        {
                            DispatchKeyValueFloat(ent, "count", 100.0);
                            if(g_bDebug)
                                LogMessage("SM_MD: Kit count for %d changed to 100.", ent);
                        }
                        case 6:
                        {
                            // replace one kit with defib and stop
                            ReplaceOrAddEnt(ent, "weapon_defibrillator", true);
                            if(g_bDebug)
                                LogMessage("SM_MD: Kit %d replaced by defib.", ent);
                            break;
                        }
                    }
                }
            }
        }
    }
    return;
}

stock SetKitsDensity_Saferoom()
{    
    int ent;
    float vecLocation[3];
    int iKitsSaferoom = GetConVarInt(h_KitsSaferoom);
    int iKitsSaferoomCount = GetConVarInt(h_KitsSaferoomCount);
    
    if(iKitsSaferoom == 7)
    {
        iKitsSaferoomCount = GetSurvivorCount();
        iKitsSaferoom = 1;
        if(g_bDebug)
            LogMessage("SM_MD: Saferoom kits for option 7, check for %d players what to do.", iKitsSaferoomCount);
        if (iKitsSaferoomCount < 4){
            iKitsSaferoomCount = 4;
            if(g_bDebug)
                LogMessage("SM_MD: Less than 4 human players, do not add anything to saferoom and set playercount to 4");
        }
    }
    
    // Remove, replace or leave the medkits near checkpoint door
    ent = -1;
    while((ent = FindEntityByClassname(ent, "weapon_first_aid_kit_spawn")) != -1)
    {
        if(IsValidEntity(ent))
        {
            GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecLocation);
            if(GetVectorDistance(vecClosestKitCheckpoint, vecLocation, false) < 200)
            {
                if(g_bDebug)
                    LogMessage("SM_MD: Saferoom kit %d at coords: X=%f Y=%f Z=%f", ent, vecLocation[0], vecLocation[1], vecLocation[2]);
                switch(iKitsSaferoom)
                {
                    case 0:
                    {
                        break;
                    }
                    case 1:
                    {
                        if(iKitsSaferoomCount > 4)
                        {
                            if(g_bDebug)
                                LogMessage("SM_MD: Adding kits for %d clients.", iKitsSaferoomCount);

                            // Some maps should not be altered due to specific gameplay (kit preservation etc).
                            if(StrContains(g_MapName, "c4m3_", false) != -1)
                            {
                                if(g_bDebug)
                                    LogMessage("SM_MD: Skip altering # kits for %s.", g_MapName);
                                break;
                            }

                            // set medkit count (1 medkit found, 6 medkits in total)
                            if(StrContains(g_MapName, "c4m1", false) != -1)
                            {
                                if(iKitsSaferoomCount > 6)
                                {
                                    iKitsSaferoomCount -= 6;
                                }
                                else if(iKitsSaferoomCount == 5)
                                {
                                    AcceptEntityInput(ent, "Kill");
                                    break;
                                }
                                else
                                {
                                    break;
                                }
                            }
                            // set medkit count (1 medkit found, 4 medkits in total)
                            else
                            {
                                iKitsSaferoomCount -= 4;
                            }
                            // spawn medkits (above it) every second
                            int ref = EntIndexToEntRef(ent);
                            Handle datapack;
                            CreateDataTimer(1.0, Timer_GraduallySpawnMedkits, datapack, TIMER_REPEAT);
                            WritePackCell(datapack, ref);
                            WritePackCell(datapack, iKitsSaferoomCount);
                            break;
                        }
                        else
                        {
                            if(g_bDebug)
                                LogMessage("SM_MD: No need to add more kits for %d players.", iKitsSaferoomCount);
                            break;
                        }
                    }
                    case 2:
                    {
                        AcceptEntityInput(ent, "Kill");
                    }
                    case 3:
                    {
                        ReplaceOrAddEnt(ent, "weapon_pain_pills", true);
                    }
                    case 4:
                    {
                        ReplaceOrAddEnt(ent, "weapon_defibrillator", true);
                    }
                    case 5:
                    {
                        DispatchKeyValueFloat(ent, "count", 100.0);
                    }
                    case 6:
                    {
                        // replace one kit with defib
                        ReplaceOrAddEnt(ent, "weapon_defibrillator", true);
                        // stop replacing anything else
                        break;
                    }
                }
            }
        }
    }
    return;
}

stock SetDensity_Outdoors()
{    
    int ent;
    float vecLocation[3];
    int iKitsOutdoors = GetConVarInt(h_KitsOutdoors);
    int iKitsOutdoorsCount = GetConVarInt(h_KitsOutdoorsCount);
    
    // Find all medkits far from a safe area
    ent = -1;
    while((ent = FindEntityByClassname(ent, "weapon_first_aid_kit_spawn")) != -1)
    {
        if(IsValidEntity(ent))
        {
            GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecLocation);
            // Remove, replace or leave the medkits away from a safe area
            if( GetVectorDistance(vecClosestKitStart, vecLocation, false) > 500.0 && GetVectorDistance(vecClosestKitCheckpoint, vecLocation, false) > 500.0 )
            {
                if(!IsLocationFar(vecLocation[0], vecLocation[1], vecLocation[2]))
                {
                    if(g_Debug > 1)
                        LogMessage("SM_MD: Kit %d found too close to a survivor.", ent);
                    break;
                }
                else
                {
                    switch(iKitsOutdoors)
                    {
                        case 0:
                        {
                            break;
                        }
                        case 1:
                        {
                            // set medkit count (1 medkit found, who knows how many medkits in total)
                            if(iKitsOutdoorsCount > 1)
                            {
                                float fCount = float(iKitsOutdoorsCount);
                                DispatchKeyValueFloat(ent, "count", fCount);
                                if(g_Debug > 1)
                                    LogMessage("SM_MD: Changed outdoor kit %d count to %f (coords X=%f Y=%f Z=%f).", ent, fCount, vecLocation[0], vecLocation[1], vecLocation[2]);
                            }
                            else
                            {
                                if(g_Debug > 1)
                                    LogMessage("SM_MD: No need to change outdoor kit %d count.", ent);
                                break;
                            }
                        }
                        case 2:
                        {
                            AcceptEntityInput(ent, "Kill");
                            if(g_Debug > 1)
                                LogMessage("SM_MD: Removed outdoor kit %d.", ent);
                        }
                        case 3:
                        {
                            ReplaceOrAddEnt(ent, "weapon_pain_pills", true);
                            if(g_Debug > 1)
                                LogMessage("SM_MD: Changed outdoor kit %d count into pills.", ent);
                        }
                        case 4:
                        {
                            ReplaceOrAddEnt(ent, "weapon_defibrillator", true);
                            if(g_Debug > 1)
                                LogMessage("SM_MD: Changed outdoor kit %d count into defib.", ent);
                        }
                        case 5:
                        {
                            DispatchKeyValueFloat(ent, "count", 100.0);
                            if(g_Debug > 1)
                                LogMessage("SM_MD: Changed outdoor kit %d count into 100.", ent);
                        }
                    }
                }
            }
            else
            {
                if(g_bDebug)
                    LogMessage("SM_MD: Outdoor kit %d (coords X=%f Y=%f Z=%f) too close to safe room or start.", ent, vecLocation[0], vecLocation[1], vecLocation[2]);
            }
        }
    }
    return;
}

stock bool IsLocationFar(const Float:vecX, const Float:vecY, const Float:vecZ)
{
    float vecLocation[3];
    vecLocation[0] = vecX;
    vecLocation[1] = vecY;
    vecLocation[2] = vecZ;
    
    for(new i = 1; i <= MaxClients; i++)
    {
        if(!IsClientConnected(i))
            continue;
        if(!IsClientInGame(i))
            continue;
        if(GetClientTeam(i) != 2)
            continue;
        
        float vecOrigin[3];
        GetClientAbsOrigin(i, vecOrigin);
        
        if(GetVectorDistance(vecOrigin, vecLocation, false) < 500.0)
            return false;
    }
    return true;
}

stock bool RealPlayersInGame(client)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (i != client)
        {
            if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
                return true;
        }
    }    
    return false;
}

int GetSurvivorCount()
{
    int nSurvivors = 0;
    
    for (int i = 1; i <= MaxClients; i++)
    {
        if(IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
            if (GetClientTeam(i) == 2)
                nSurvivors++;
    }
    return nSurvivors;
}


public Action:Timer_GraduallySpawnMedkits(Handle:timer, Handle:datapack)
{
    ResetPack(datapack, false);
    int ref = ReadPackCell(datapack);
    int count = ReadPackCell(datapack);
    
    int ent = EntRefToEntIndex(ref);
    ReplaceOrAddEnt(ent, "weapon_first_aid_kit", false);
    g_iKitsSpawned++;
    if(g_bDebug)
        LogMessage("SM_MD: Adding kit #%d to saferoom", g_iKitsSpawned);
    if(g_iKitsSpawned >= count)
    {
        g_iKitsSpawned = 0;
        return Plugin_Stop;
    }    
    return Plugin_Continue;
}

stock ReplaceOrAddEnt(any:ent, const String:entname[], bool:delent)
{
    if(!IsValidEntity(ent)) return
    
    float vecLocation[3];
    GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecLocation);
    int entCreated = CreateEntityByName(entname);
    if(entCreated != -1)
    {
        float vecAngles[3];
        GetEntPropVector(ent, Prop_Send, "m_angRotation", vecAngles);
        
        if((StrContains(entname, "weapon_pain_pills", false) != -1) && vecAngles[0] == 90.0)
        {
            vecAngles[0] = 0.0;
            vecLocation[2] -= 3.0;
        }
        
        if(StrContains(entname, "weapon_first_aid_kit", false) != -1)
            vecLocation[2] += 32.0;
        
        TeleportEntity(entCreated, vecLocation, vecAngles, NULL_VECTOR);
        DispatchSpawn(entCreated);
        
        if(delent)
            AcceptEntityInput(ent, "Kill");
    }
    return;
}
