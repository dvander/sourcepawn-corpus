#include <base64>

// 3 floats of 4 bytes
#define SPAWNS_DISTANCE_SERIAL_SOURCE_SIZE 12
// Safety margin to the 50% more than SPAWNS_DISTANCE_SERIAL_BYTE_SIZE
#define SPAWNS_DISTANCE_SERIAL_BASE64_SIZE 2*SPAWNS_DISTANCE_SERIAL_SOURCE_SIZE

#define FLOAT_EPSILON 0.00001
#define SPAWNS_CONFIG_PATH "data/deathmatch_spawn"
#define SPAWNS_MAXPOINT 200
#define SPAWNS_MAX_DELETE_DISTANCE 100.0

#define SPAWNS_SAFE_WALL_DISTANCE 25.0
#define SPAWNS_SAFE_FLOOR_DISTANCE 5.0
#define SPAWNS_SAFE_CEILING_DISTANCE 85.0
#define SPAWNS_SAFE_HORIZONTAL_SPAWN_DISTANCE 46.0
#define SPAWNS_SAFE_VERTICAL_SPAWN_DISTANCE SPAWNS_SAFE_CEILING_DISTANCE
#define SPAWNS_MAXIMUM_ADJUSTMENT_DISTANCE 2*SPAWNS_SAFE_HORIZONTAL_SPAWN_DISTANCE

enum Spawns_Teams
{
    Spawns_TeamT,
    Spawns_TeamCT,
    Spawns_TeamBoth,
    Spawns_Team_Count
};

static SPAWNS_COLORS[_:Spawns_Team_Count][4] = 
{
    {255, 0, 0, 255},   // Spawns_TeamT
    {0, 0, 255, 255},   // Spawns_TeamCT
    {255, 255, 0, 255}  // Spawns_TeamBoth
};

static g_iBeamSprite = 0;
static g_iHaloSprite = 0;

new bool:g_bSpawns_CompAvailable = false;
new bool:g_bSpawns_DmAvailable = false;

static g_iSpawns_PointCount = 0;
static g_iSpawns_TPointCount = 0;
static g_iSpawns_CTPointCount = 0;
static g_iSpawns_DmPointCount = 0;

static g_iSpawns_NotUsedTPointCount = 0;
static g_iSpawns_NotUsedCTPointCount = 0;
static g_iSpawns_NotUsedDMPointCount = 0;

static g_iSpawns_MapTPointCount = 0;
static g_iSpawns_MapCTPointCount = 0;
static g_iSpawns_MapDMPointCount = 0;

static g_iSpawns_LoadedDmPointCount = 0;
static g_iSpawns_LoadedCTPointCount = 0;
static g_iSpawns_LoadedTPointCount = 0;
static Float:g_fSpawns_LoadedDMPositions[SPAWNS_MAXPOINT][3];
static Float:g_fSpawns_LoadedCTPositions[SPAWNS_MAXPOINT][3];
static Float:g_fSpawns_LoadedTPositions[SPAWNS_MAXPOINT][3];
static g_iSpawns_LoadedDMEntities[SPAWNS_MAXPOINT];
static g_iSpawns_LoadedCTEntities[SPAWNS_MAXPOINT];
static g_iSpawns_LoadedTEntities[SPAWNS_MAXPOINT];

static Float:g_fSpawns_Positions[SPAWNS_MAXPOINT][3];
static Float:g_fSpawns_Angles[SPAWNS_MAXPOINT][3];
static Spawns_Teams:g_iSpawns_Team[SPAWNS_MAXPOINT];
static g_iSpawns_Entities[SPAWNS_MAXPOINT];
static g_iSpawns_NotUsedCTEntities[SPAWNS_MAXPOINT];
static g_iSpawns_NotUsedTEntities[SPAWNS_MAXPOINT];
static g_iSpawns_NotUsedDMEntities[SPAWNS_MAXPOINT];

static Float:g_fSpawns_MaxInterDMDistance_Squared;
static Float:g_fSpawns_MaxInterCTDistance_Squared;
static Float:g_fSpawns_MaxInterTDistance_Squared;
static Float:g_fSpawns_MaxInterTAndCTDistance_Squared;
static Float:g_fSpawns_MedianInterDMDistance_Squared;
static Float:g_fSpawns_MedianInterTandCTDistance_Squared;
static Float:g_fSpawns_MinTeamInterDMDistance_Squared;
static Float:g_fSpawns_MinTeamInterTDistance_Squared;
static Float:g_fSpawns_MinTeamInterCTDistance_Squared;

static Handle:g_hSpawns_CheckDistanceSaveArray;

static bool:g_bSpawns_EditorMode = false;
static g_iSpawns_EditorMode_Client;
static Handle:g_hSpawns_MessageHandle;

static bool:g_bSpawns_AdminTestSpawnRequested = false;
static g_iSpawns_AdminTestSpawnClientIndex = 0;
static g_iSpawns_AdminTestSpawnIndex = 0;
static g_iSpawns_AdminTestSpawnEntity = -1;

static Handle:g_hSpawns_Function_IsTriggered = INVALID_HANDLE;

static g_iSpawns_Stats_SpawnSucceded = 0;
static g_iSpawns_Stats_SpawnLOSFailed = 0;
static g_iSpawns_Stats_SpawnPointTestedFailed = 0;
static g_iSpawns_Stats_SpawnPointLOSSearch = 0;
static g_iSpawns_Stats_SpawnPointLOSSearchFailed = 0;

static g_iSpawns_StatsMap_SpawnSucceded = 0;
static g_iSpawns_StatsMap_SpawnLOSFailed = 0;
static g_iSpawns_StatsMap_SpawnPointTestedFailed = 0;
static g_iSpawns_StatsMap_SpawnPointLOSSearch = 0;
static g_iSpawns_StatsMap_SpawnPointLOSSearchFailed = 0;

stock spawns_Init()
{     
    g_hSpawns_MessageHandle = userMessage_RegisterNewMessage(
                                        eUserMessages_ToHint,
                                        spawns_MessageBuildCallBack,
                                        .buildcallBackArgument = 0,
                                        .repeatPeriod = 60,
                                        .repeatCount = 0,
                                        .minDisplayTime = 60,
                                        .flags = USER_MESSAGES_FLAG_REPEAT_INFINITE,
                                        .priority = 150
                                    );
    
    spawn_CreateConfigsDir();
    
    new Handle:CvarHandle;
    
    if((CvarHandle = FindConVar("mp_randomspawn")) != INVALID_HANDLE)
        HookConVarChange(CvarHandle, spawns_Event_CvarChange);
    if((CvarHandle = FindConVar("mp_randomspawn_los")) != INVALID_HANDLE)
        HookConVarChange(CvarHandle, spawns_Event_CvarChange);
    if((CvarHandle = FindConVar("mp_teammates_are_enemies")) != INVALID_HANDLE)
        HookConVarChange(CvarHandle, spawns_Event_CvarChange);
    
    new Handle:gameOffsets = LoadGameConfigFile("deathmatch.games");
    if(gameOffsets == INVALID_HANDLE)
    {
        LogMessage("Deathmatch offsets file for spawns not found! Resuming without spawns triggered check feature");
        return;
    }
    
    StartPrepSDKCall(SDKCall_Entity);
    if(!PrepSDKCall_SetFromConf(gameOffsets, SDKConf_Virtual, "IsTriggered"))
    {
        LogMessage("EntSelectSpawnPoint function offset for spawns not found! Resuming without spawns triggered check feature");
        return;
    }
    PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
    PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
    
    g_hSpawns_Function_IsTriggered = EndPrepSDKCall();
}

stock spawns_OnMapStart()
{    
    g_iBeamSprite = PrecacheModel("sprites/laserbeam.vmt", true);
    g_iHaloSprite = PrecacheModel("sprites/halo.vmt", true);
    
    g_iSpawns_AdminTestSpawnEntity = -1;
    
    g_iSpawns_StatsMap_SpawnSucceded = 0;
    g_iSpawns_StatsMap_SpawnLOSFailed = 0;
    g_iSpawns_StatsMap_SpawnPointTestedFailed = 0;
    g_iSpawns_StatsMap_SpawnPointLOSSearch = 0;
    g_iSpawns_StatsMap_SpawnPointLOSSearchFailed = 0;
    
    spawns_Load();
    
    g_bSpawns_CompAvailable = (g_iSpawns_TPointCount > 0) && (g_iSpawns_CTPointCount > 0);
    g_bSpawns_DmAvailable = g_iSpawns_DmPointCount > 0;
    
    spawns_registerAllSpawnEntities();
    
    g_iSpawns_MapTPointCount = g_iSpawns_NotUsedTPointCount;
    g_iSpawns_MapCTPointCount = g_iSpawns_NotUsedCTPointCount;
    g_iSpawns_MapDMPointCount = g_iSpawns_NotUsedDMPointCount;
    
    if(!g_bSpawns_CompAvailable && !g_bSpawns_DmAvailable)
    {
        spawns_LoadEntitiesForSpawming(.noInternalSpawn = true);
        return;
    }
    
    if(
        g_bSpawns_CompAvailable && 
        ((g_iSpawns_TPointCount < g_iSpawns_MapTPointCount) || (g_iSpawns_CTPointCount < g_iSpawns_MapCTPointCount))
        ||
        g_bSpawns_DmAvailable &&
        (g_iSpawns_DmPointCount < g_iSpawns_MapDMPointCount)
       )
    {
        LogError("Deathmatch: Custom spawn points disabled to prevent crash");
        LogError("Custom spawns T:%d | CT:%d | Dm:%d", g_iSpawns_TPointCount, g_iSpawns_CTPointCount, g_iSpawns_DmPointCount);
        LogError("But map has   T:%d | CT:%d | Dm:%d", g_iSpawns_MapTPointCount, g_iSpawns_MapCTPointCount, g_iSpawns_MapDMPointCount);
        LogError("Each category must have at least the same amount as map");
        spawns_LoadEntitiesForSpawming(.noInternalSpawn = true);
        return;
    }
    
    if(g_bSpawns_DmAvailable)
        spawns_disableMapDMGeneration();
    spawns_createAllSpawnEntities();
    
    spawns_LoadEntitiesForSpawming(.noInternalSpawn = false);
}

stock spawns_OnMapEnd()
{
    g_bSpawns_CompAvailable = false;
    g_bSpawns_DmAvailable = false;
    g_bSpawns_EditorMode = false;
    g_iSpawns_PointCount = 0;
    g_iSpawns_TPointCount = 0;
    g_iSpawns_CTPointCount = 0;
    g_iSpawns_DmPointCount = 0;
    g_iSpawns_NotUsedTPointCount = 0;
    g_iSpawns_NotUsedCTPointCount = 0;
    g_iSpawns_NotUsedDMPointCount = 0;
}

stock spawn_CreateConfigsDir()
{
    decl String:sConfigPath[PLATFORM_MAX_PATH];
    
    BuildPath(Path_SM, sConfigPath, sizeof(sConfigPath), SPAWNS_CONFIG_PATH);
    
    if (!DirExists(sConfigPath))
        CreateDirectory(sConfigPath, 451);
}

public spawns_Event_CvarChange(Handle:cvar, const String:oldValue[], const String:newValue[])
{
    new Handle:CvarHandle;
    
    if((CvarHandle = FindConVar("mp_randomspawn")) != INVALID_HANDLE)
        g_bConfig_mp_randomspawn           = GetConVarBool(CvarHandle);
    if((CvarHandle = FindConVar("mp_randomspawn_los")) != INVALID_HANDLE)
        g_bConfig_mp_randomspawn_los           = GetConVarBool(CvarHandle);
    if((CvarHandle = FindConVar("mp_teammates_are_enemies")) != INVALID_HANDLE)
        g_bConfig_mp_teammates_are_enemies  = GetConVarBool(CvarHandle);
}

stock spawns_CreateWorksopSubDirectories(const String:mapname[])
{
    decl String:sConfigPath[PLATFORM_MAX_PATH];
    new strStart = 0;
    new strEnd = 0;
    
    BuildPath(Path_SM, sConfigPath, sizeof(sConfigPath), "%s/", SPAWNS_CONFIG_PATH);
    
    if(mapname[strStart] == '/')
        strStart++;
        
    while((strEnd = FindCharInString(mapname[strStart], '/')) != -1)
    {
        strcopy(sConfigPath[strlen(sConfigPath)], strEnd + 2, mapname[strStart]);
        strStart = strStart + strEnd + 1;
        
        if (!DirExists(sConfigPath))
            CreateDirectory(sConfigPath, 451);
    }
    
}

stock Handle:spawns_GetConfigFileHandle(const String:mode[], const String:mapname[]="")
{
    decl String:sConfigPath[PLATFORM_MAX_PATH];
    decl String:sConfigFile[PLATFORM_MAX_PATH];
    decl String:sMap[PLATFORM_MAX_PATH];
    
    BuildPath(Path_SM, sConfigPath, sizeof(sConfigPath), SPAWNS_CONFIG_PATH);
    
    if(StrEqual(mapname, ""))
        GetCurrentMap(sMap, sizeof(sMap));
    else
        strcopy(sMap, sizeof(sMap), mapname);
        
    if(StrEqual(mode, "w"))
        spawns_CreateWorksopSubDirectories(sMap);
    
    Format(sConfigFile, sizeof(sConfigFile), "%s/%s.txt", sConfigPath, sMap);
    
    return OpenFile(sConfigFile, mode);
}

stock spawns_Load(const String:mapname[]="")
{
    decl String:sLine[256];
    decl String:sLineParts[7][16];
    decl iElementsFound;
    new Handle:fileHandle = spawns_GetConfigFileHandle("r", mapname);
    
    g_iSpawns_PointCount = 0;
    g_iSpawns_TPointCount = 0;
    g_iSpawns_CTPointCount = 0;
    g_iSpawns_DmPointCount = 0;
    
    if (fileHandle == INVALID_HANDLE)
        return;
    
    
    while (!IsEndOfFile(fileHandle) && ReadFileLine(fileHandle, sLine, sizeof(sLine)))
    {
        iElementsFound = ExplodeString(sLine, " ", sLineParts, 7, 16, true);
        
        if(iElementsFound < 6)
            LogError("Incorrect spawn position definition \"%s\"", sLine);
        else
        {
            g_fSpawns_Positions[g_iSpawns_PointCount][0] = StringToFloat(sLineParts[0]);
            g_fSpawns_Positions[g_iSpawns_PointCount][1] = StringToFloat(sLineParts[1]);
            g_fSpawns_Positions[g_iSpawns_PointCount][2] = StringToFloat(sLineParts[2]);
            g_fSpawns_Angles[g_iSpawns_PointCount][0] = StringToFloat(sLineParts[3]);
            g_fSpawns_Angles[g_iSpawns_PointCount][1] = StringToFloat(sLineParts[4]);
            g_fSpawns_Angles[g_iSpawns_PointCount][2] = StringToFloat(sLineParts[5]);
            
            if(iElementsFound >= 7)
            {
                if(StrPartEqual(sLineParts[6], "T"))
                {
                    g_iSpawns_Team[g_iSpawns_PointCount] = Spawns_TeamT;
                }
                else if(StrPartEqual(sLineParts[6], "CT"))
                {
                    g_iSpawns_Team[g_iSpawns_PointCount] = Spawns_TeamCT;
                }
                else
                {
                    g_iSpawns_Team[g_iSpawns_PointCount] = Spawns_TeamBoth;
                }
            }
            else
            {
                g_iSpawns_Team[g_iSpawns_PointCount] = Spawns_TeamBoth;
            }
            
            g_iSpawns_Entities[g_iSpawns_PointCount] = -1;
            
            if(g_iSpawns_Team[g_iSpawns_PointCount]==Spawns_TeamBoth)
                g_iSpawns_DmPointCount++;
            else if(g_iSpawns_Team[g_iSpawns_PointCount]==Spawns_TeamT)
                g_iSpawns_TPointCount++;
            else if(g_iSpawns_Team[g_iSpawns_PointCount]==Spawns_TeamCT)
                g_iSpawns_CTPointCount++;
            
            g_iSpawns_PointCount++;
        }
    }
    
    CloseHandle(fileHandle);
}

stock spawns_LoadEntitiesForSpawming(bool:noInternalSpawn = false)
{
    g_iSpawns_LoadedDmPointCount = 0;
    g_iSpawns_LoadedCTPointCount = 0;
    g_iSpawns_LoadedTPointCount = 0;
    
    if(!g_bSpawns_DmAvailable || noInternalSpawn)
        for(new index = 0; index < g_iSpawns_NotUsedDMPointCount; index++)
        {
            GetEntPropVector(g_iSpawns_NotUsedDMEntities[index], Prop_Data, "m_vecOrigin", g_fSpawns_LoadedDMPositions[g_iSpawns_LoadedDmPointCount]);
            g_iSpawns_LoadedDMEntities[g_iSpawns_LoadedDmPointCount] = g_iSpawns_NotUsedDMEntities[index];
            g_iSpawns_LoadedDmPointCount++;
        }
    else
        for(new index = 0; index < g_iSpawns_PointCount; index++)
            if(g_iSpawns_Team[index] == Spawns_TeamBoth)
            {
                g_fSpawns_LoadedDMPositions[g_iSpawns_LoadedDmPointCount] = g_fSpawns_Positions[index];
                g_iSpawns_LoadedDMEntities[g_iSpawns_LoadedDmPointCount] = g_iSpawns_Entities[index];
                g_iSpawns_LoadedDmPointCount++;
            }
        
    if(!g_bSpawns_CompAvailable || noInternalSpawn)
    {
        for(new index = 0; index < g_iSpawns_NotUsedTPointCount; index++)
        {
            GetEntPropVector(g_iSpawns_NotUsedTEntities[index], Prop_Data, "m_vecOrigin", g_fSpawns_LoadedTPositions[g_iSpawns_LoadedTPointCount]);
            g_iSpawns_LoadedTEntities[g_iSpawns_LoadedTPointCount] = g_iSpawns_NotUsedTEntities[index];
            g_iSpawns_LoadedTPointCount++;
        }
        for(new index = 0; index < g_iSpawns_NotUsedCTPointCount; index++)
        {
            GetEntPropVector(g_iSpawns_NotUsedCTEntities[index], Prop_Data, "m_vecOrigin", g_fSpawns_LoadedCTPositions[g_iSpawns_LoadedCTPointCount]);
            g_iSpawns_LoadedCTEntities[g_iSpawns_LoadedCTPointCount] = g_iSpawns_NotUsedCTEntities[index];
            g_iSpawns_LoadedCTPointCount++;
        }
    }
    else
    
        for(new index = 0; index < g_iSpawns_PointCount; index++)
            if(g_iSpawns_Team[index] == Spawns_TeamCT)
            {
                g_fSpawns_LoadedCTPositions[g_iSpawns_LoadedCTPointCount] = g_fSpawns_Positions[index];
                g_iSpawns_LoadedCTEntities[g_iSpawns_LoadedCTPointCount] = g_iSpawns_Entities[index];
                g_iSpawns_LoadedCTPointCount++;
            }
            else if(g_iSpawns_Team[index] == Spawns_TeamT)
            {
                g_fSpawns_LoadedTPositions[g_iSpawns_LoadedTPointCount] = g_fSpawns_Positions[index];
                g_iSpawns_LoadedTEntities[g_iSpawns_LoadedTPointCount] = g_iSpawns_Entities[index];
                g_iSpawns_LoadedTPointCount++;
            }
    
    g_fSpawns_MaxInterDMDistance_Squared = spawns_ComputeMaxInterSpawnDistance(g_fSpawns_LoadedDMPositions, g_iSpawns_LoadedDmPointCount, g_fSpawns_LoadedDMPositions, g_iSpawns_LoadedDmPointCount, .squared = true);
    g_fSpawns_MaxInterCTDistance_Squared = spawns_ComputeMaxInterSpawnDistance(g_fSpawns_LoadedCTPositions, g_iSpawns_LoadedCTPointCount, g_fSpawns_LoadedCTPositions, g_iSpawns_LoadedCTPointCount, .squared = true);
    g_fSpawns_MaxInterTDistance_Squared = spawns_ComputeMaxInterSpawnDistance(g_fSpawns_LoadedTPositions, g_iSpawns_LoadedTPointCount, g_fSpawns_LoadedTPositions, g_iSpawns_LoadedTPointCount, .squared = true);
    g_fSpawns_MaxInterTAndCTDistance_Squared = spawns_ComputeMaxInterSpawnDistance(g_fSpawns_LoadedTPositions, g_iSpawns_LoadedTPointCount, g_fSpawns_LoadedCTPositions, g_iSpawns_LoadedCTPointCount, .squared = true);
}

stock spawns_disableMapDMGeneration()
{
    decl map_Params;
    
    map_Params = FindEntityByClassname(-1, "info_map_parameters");
    if(map_Params == -1)
    {
        map_Params = CreateEntityByName("info_map_parameters");
        DispatchSpawn(map_Params);
    }
    SetEntProp(map_Params, Prop_Data, "m_bDisableAutoGeneratedDMSpawns", 1);
}

stock spawns_createSpawnEntity(index)
{
    if(g_iSpawns_Team[index] == Spawns_TeamT)
    {
        if(g_iSpawns_NotUsedTPointCount > 0)
        {
            g_iSpawns_NotUsedTPointCount--;
            g_iSpawns_Entities[index] = g_iSpawns_NotUsedTEntities[g_iSpawns_NotUsedTPointCount];
        }
        else
        {
            g_iSpawns_Entities[index] = CreateEntityByName("info_player_terrorist");
            DispatchSpawn(g_iSpawns_Entities[index]);
        }
    }
    
    else if(g_iSpawns_Team[index] == Spawns_TeamCT)
    {
        if(g_iSpawns_NotUsedCTPointCount > 0)
        {
            g_iSpawns_NotUsedCTPointCount--;
            g_iSpawns_Entities[index] = g_iSpawns_NotUsedCTEntities[g_iSpawns_NotUsedCTPointCount];
        }
        else
        {
            g_iSpawns_Entities[index] = CreateEntityByName("info_player_counterterrorist");
            DispatchSpawn(g_iSpawns_Entities[index]);
        }
    }
    
    else if(g_iSpawns_Team[index] == Spawns_TeamBoth)
    {
        if(g_iSpawns_NotUsedDMPointCount > 0)
        {
            g_iSpawns_NotUsedDMPointCount--;
            g_iSpawns_Entities[index] = g_iSpawns_NotUsedDMEntities[g_iSpawns_NotUsedDMPointCount];
        }
        else
        {
            g_iSpawns_Entities[index] = CreateEntityByName("info_deathmatch_spawn");
            DispatchSpawn(g_iSpawns_Entities[index]);
        }
    }
    
    TeleportEntity(g_iSpawns_Entities[index],  g_fSpawns_Positions[index], g_fSpawns_Angles[index], NULL_VECTOR);
}

stock spawns_createAllSpawnEntities()
{
    for(new index = 0; index < g_iSpawns_PointCount; index++)
    {
        spawns_createSpawnEntity(index);
    }
}

stock spawns_AdminTestSpawn_PrepareSpawnEntity(spawnIndex)
{
    if(
        g_iSpawns_AdminTestSpawnEntity == -1 ||
        !IsValidEntity(g_iSpawns_AdminTestSpawnEntity)
       )
    {
        g_iSpawns_AdminTestSpawnEntity = CreateEntityByName("info_deathmatch_spawn");
        DispatchSpawn(g_iSpawns_AdminTestSpawnEntity);
    }
    
    TeleportEntity(g_iSpawns_AdminTestSpawnEntity,  g_fSpawns_Positions[spawnIndex], g_fSpawns_Angles[spawnIndex], NULL_VECTOR);
    
    return g_iSpawns_AdminTestSpawnEntity;
}

stock FindEntityByClassname2(startEnt, const String:classname[])
{
    while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
    
    return FindEntityByClassname(startEnt, classname);
}

stock spawns_registerAllSpawnEntities()
{
    new entity = -1;
    
    g_iSpawns_NotUsedTPointCount = 0;
    g_iSpawns_NotUsedCTPointCount = 0;
    g_iSpawns_NotUsedDMPointCount = 0;

    while ((entity = FindEntityByClassname2(entity, "info_player_terrorist")) != -1)
    {
        g_iSpawns_NotUsedTEntities[g_iSpawns_NotUsedTPointCount] = entity;
        g_iSpawns_NotUsedTPointCount++;
    }
    
    while ((entity = FindEntityByClassname2(entity, "info_player_counterterrorist")) != -1)
    {
        g_iSpawns_NotUsedCTEntities[g_iSpawns_NotUsedCTPointCount] = entity;
        g_iSpawns_NotUsedCTPointCount++;
    }
    
    while ((entity = FindEntityByClassname2(entity, "info_deathmatch_spawn")) != -1)
    {
        g_iSpawns_NotUsedDMEntities[g_iSpawns_NotUsedDMPointCount] = entity;
        g_iSpawns_NotUsedDMPointCount++;
    }
}

stock spawns_RemoveFromArray(any:array[], index, size)
{
    for(new i = index; i < size - 1; i++)
        array[i] = array[i+1];
}

stock spawns_RemoveFromArrayVect(any:array[][], index, size, size2)
{
    for(new i = index; i < size - 1; i++)
    {
        for(new j = 0; j < size2; j++)
        {
            array[i][j] = array[i+1][j];
        }
    }
}

stock spawns_DeletePoint(index)
{
    if(g_iSpawns_Team[index] == Spawns_TeamT)
        g_iSpawns_TPointCount--;
    else if(g_iSpawns_Team[index] == Spawns_TeamCT)
        g_iSpawns_CTPointCount--;
    else if(g_iSpawns_Team[index] == Spawns_TeamBoth)
        g_iSpawns_DmPointCount--;
    
    spawns_RemoveFromArrayVect(g_fSpawns_Positions, index, g_iSpawns_PointCount, 3);
    spawns_RemoveFromArrayVect(g_fSpawns_Angles, index, g_iSpawns_PointCount, 3);
    spawns_RemoveFromArray(g_iSpawns_Team, index, g_iSpawns_PointCount);
    spawns_RemoveFromArray(g_iSpawns_Entities, index, g_iSpawns_PointCount);
    
    g_iSpawns_PointCount--;
}

stock bool:spawns_DeleteNearestPoint(clientIndex)
{
    decl Float:clientPosition[3];
    new Float:currentEligiblePointDistance = SPAWNS_MAX_DELETE_DISTANCE + FLOAT_EPSILON;
    new currentEligiblePoint = -1;
    
    GetClientAbsOrigin(clientIndex, clientPosition);
    
    for (new i = 0; i < g_iSpawns_PointCount; i++)
    {
        new Float:distance = GetVectorDistance(clientPosition, g_fSpawns_Positions[i]);
        if(distance < currentEligiblePointDistance)
        {
            currentEligiblePoint = i;
            currentEligiblePointDistance = distance;
        }
    }
    
    if(currentEligiblePoint > -1)
    {
        spawns_DeletePoint(currentEligiblePoint);
        return true;
    }
    else
        return false;
}

stock spawns_SaveCheckCorrectResult(const Float:position[3], Float:distanceResult, const Float:moveOffset[3])
{
    decl String:positionSerial[SPAWNS_DISTANCE_SERIAL_BASE64_SIZE];
    decl Float:saveVect[4];
    
    saveVect[0] = distanceResult;
    saveVect[1] = moveOffset[0];
    saveVect[2] = moveOffset[1];
    saveVect[3] = moveOffset[2];
    
    EncodeBase64(positionSerial, SPAWNS_DISTANCE_SERIAL_BASE64_SIZE, String:position, SPAWNS_DISTANCE_SERIAL_SOURCE_SIZE);
    
    SetTrieArray(g_hSpawns_CheckDistanceSaveArray, positionSerial, saveVect, sizeof(saveVect), false);
}

stock bool:spawns_RetreiveCheckCorrectResult(const Float:position[3], &Float:distanceResult, Float:moveOffsetResult[3])
{
    decl String:positionSerial[SPAWNS_DISTANCE_SERIAL_BASE64_SIZE];
    decl Float:saveVect[4];
    decl bool:result;
    
    EncodeBase64(positionSerial, SPAWNS_DISTANCE_SERIAL_BASE64_SIZE, String:position, SPAWNS_DISTANCE_SERIAL_SOURCE_SIZE);
    
    result = GetTrieArray(g_hSpawns_CheckDistanceSaveArray, positionSerial, saveVect, sizeof(saveVect));
    
    distanceResult = saveVect[0];
    moveOffsetResult[0] = saveVect[1];
    moveOffsetResult[1] = saveVect[2];
    moveOffsetResult[2] = saveVect[3];
    
    return result;
}

public bool:spawns_TraceFilterClients(entity, mask)
{
    return entity > MaxClients;
}

stock bool:spawns_OffsetFollowsConstraint(const Float:moveOffset[3], const Float:constraint[3])
{
    for(new i = 0; i < 3; i++)
    {
        // Check if we move back against constraint
        if(moveOffset[i] * constraint[i] < -FLOAT_EPSILON)
            return false;
    }
    
    return true;
}

stock bool:spawns_movedToLeaveHull(const Float:hullCenter[3], const Float:hullMin[3], const Float:hullMax[3], const Float:point[3], const Float:moveConstraint[3], &bool:insidedHull, Float:moveToAvoid[3])
{
    new Float:OffsetToMin;
    new Float:OffsetToMax;
    new bool:moved[3] = {true, ...};
    new bool:inside[3] = {true, ...};
    
    for(new i = 0; i < 3; i++)
    {
        OffsetToMin = point[i] - (hullCenter[i] + hullMin[i]);
        OffsetToMax = point[i] - (hullCenter[i] + hullMax[i]);
        
        if(OffsetToMin > FLOAT_EPSILON && OffsetToMax < -FLOAT_EPSILON)
        {
            if(moveConstraint[i] > 0.0)
                moveToAvoid[i] = OffsetToMin;
            else if(moveConstraint[i] < 0.0)
                moveToAvoid[i] = OffsetToMax;
            else
            {
                moveToAvoid[i] = 0.0;
                moved[i] = false;
            }
        }
        else
        {
            moveToAvoid[i] = 0.0;
            moved[i] = false;
            inside[i] = false;
        }
    }
    
    insidedHull = inside[0] && inside[1] && inside[2];
    
    return insidedHull && (moved[0] || moved[1] || moved[2]);
}

new Float:directionList[6][3] = 
        {
            {-2.0, 0.0, 0.0},
            {0.0, -2.0, 0.0},
            {0.0, 0.0, -2.0},
            {2.0, 0.0, 0.0},
            {0.0, 2.0, 0.0},
            {0.0, 0.0, 2.0}
        };
        
new Float:minHullAgainstSpawns[3] = {-SPAWNS_SAFE_HORIZONTAL_SPAWN_DISTANCE, -SPAWNS_SAFE_HORIZONTAL_SPAWN_DISTANCE, -SPAWNS_SAFE_VERTICAL_SPAWN_DISTANCE};
new Float:maxHullAgainstSpawns[3] = { SPAWNS_SAFE_HORIZONTAL_SPAWN_DISTANCE,  SPAWNS_SAFE_HORIZONTAL_SPAWN_DISTANCE,  SPAWNS_SAFE_VERTICAL_SPAWN_DISTANCE};
new Float:minHullAgainstWalls[3] = {-SPAWNS_SAFE_WALL_DISTANCE, -SPAWNS_SAFE_WALL_DISTANCE, -SPAWNS_SAFE_FLOOR_DISTANCE};
new Float:maxHullAgainstWalls[3] = { SPAWNS_SAFE_WALL_DISTANCE,  SPAWNS_SAFE_WALL_DISTANCE,  SPAWNS_SAFE_CEILING_DISTANCE};

stock bool:spawns_hitInthatDirection(const Float:hullCenter[3], const Float:hullMin[3], const Float:hullMax[3], const Float:direction[3])
{
    new Float:endPoint[3];
    
    endPoint = hullCenter;
    
    for(new axis = 0; axis < 3; axis++)
    {
        if(direction[axis] < 0.0)
            endPoint[axis] += hullMin[axis];
        else if (direction[axis] > 0.0)
            endPoint[axis] += hullMax[axis];
    }
    
    TR_TraceRayFilter(hullCenter, endPoint, MASK_PLAYERSOLID, RayType_EndPoint, spawns_TraceFilterClients);
    
    return TR_DidHit();
}

stock spawns_hitInOppositeDirection(const Float:hullCenter[3], const Float:hullMin[3], const Float:hullMax[3], const Float:direction[3], Float:resultingOffset[3])
{
    new Float:endPoint[3];
    
    endPoint = hullCenter;
    
    for(new axis = 0; axis < 3; axis++)
    {
        if(direction[axis] > 0.0)
            endPoint[axis] += hullMin[axis] - FLOAT_EPSILON;
        else if (direction[axis] < 0.0)
            endPoint[axis] += hullMax[axis] + FLOAT_EPSILON;
    }
    
    TR_TraceRayFilter(hullCenter, endPoint, MASK_PLAYERSOLID, RayType_EndPoint, spawns_TraceFilterClients);
    
    if(TR_DidHit())
    {
        TR_GetEndPosition(resultingOffset);
        SubtractVectors(resultingOffset, endPoint, resultingOffset);
        
        for(new axis = 0; axis < 3; axis++)
        {
            if(resultingOffset[axis] > 0.0)
                endPoint[axis] += FLOAT_EPSILON;
            else if (resultingOffset[axis] < 0.0)
                endPoint[axis] -= FLOAT_EPSILON;
        }
    }
    else
    {
        resultingOffset = direction;
        NegateVector(resultingOffset);
    }
}

stock bool:spawns_CheckCorrectDistancesToWall(const Float:position[3], Float:moveOffset[3], bool:isDMSpawn, stack=0)
{
    decl Float:moveToAvoid[3];
    decl Float:currentPosition[3];
    decl Float:currentOffset[3];
    decl Float:selectedOffset[3];
    decl Float:distance;
    new Float:shortestDistance = SPAWNS_MAXIMUM_ADJUSTMENT_DISTANCE + 1.0;
    
    // Inite recurursion could occur, eliminate that
    if(stack > 100)
        return false;
    
    // Check if we already did that position
    if(spawns_RetreiveCheckCorrectResult(position, distance, currentOffset))
    {
        moveOffset = currentOffset;
        return distance < SPAWNS_MAXIMUM_ADJUSTMENT_DISTANCE;
    }
    
    // Trace
    TR_TraceHullFilter(position, position, minHullAgainstWalls, maxHullAgainstWalls, MASK_PLAYERSOLID, spawns_TraceFilterClients);
    if(TR_DidHit())
    {
        for(new direction = 0; direction < 6; direction++)
        {
            if( spawns_OffsetFollowsConstraint(moveOffset, directionList[direction]) &&
                !spawns_hitInthatDirection(position, minHullAgainstWalls, maxHullAgainstWalls, directionList[direction]))
            {
                spawns_hitInOppositeDirection(position, minHullAgainstWalls, maxHullAgainstWalls, directionList[direction], moveToAvoid);
                
                AddVectors(moveOffset, moveToAvoid, currentOffset);
                AddVectors(position, moveToAvoid, currentPosition);
                
                if(GetVectorLength(currentOffset) >= shortestDistance)
                    continue;
                
                TR_TraceRayFilter(position, currentPosition, MASK_PLAYERSOLID, RayType_EndPoint, spawns_TraceFilterClients);
                
                if(
                    !TR_DidHit() &&
                    spawns_CheckCorrectDistancesToWall(currentPosition, currentOffset, isDMSpawn, stack+1) &&
                    (distance = GetVectorLength(currentOffset)) < shortestDistance
                  )
                {
                    shortestDistance = distance;
                    selectedOffset = currentOffset;
                }
            }
        }
        
        if(shortestDistance < SPAWNS_MAXIMUM_ADJUSTMENT_DISTANCE)
        {
            moveOffset = selectedOffset;
            return true;
        }
        
    }
    else
    {
        return spawns_CheckCorrectDistancesToSpawns(position, moveOffset, isDMSpawn, stack);
    }
    
    spawns_SaveCheckCorrectResult(position, SPAWNS_MAXIMUM_ADJUSTMENT_DISTANCE + 1.0, moveOffset);
    return false;
    
}

stock bool:spawns_CheckCorrectDistancesToSpawns(const Float:position[3], Float:moveOffset[3], bool:isDMSpawn, stack=0)
{
    decl Float:moveToAvoid[3];
    decl Float:currentPosition[3];
    decl Float:currentOffset[3];
    decl Float:selectedOffset[3];
    decl Float:distance;
    decl bool:insideHull;
    decl Float:shortestDistance;
    
    for(new i = 0; i < g_iSpawns_PointCount; i++)
    {
        // Skip unrelated points
        if(isDMSpawn && g_iSpawns_Team[i] != Spawns_TeamBoth)
            continue;
        
        if(!isDMSpawn && g_iSpawns_Team[i] == Spawns_TeamBoth)
            continue;
        
        shortestDistance = SPAWNS_MAXIMUM_ADJUSTMENT_DISTANCE + 1.0;
        
        for(new direction = 0; direction < 6; direction++)
        {
            if( spawns_OffsetFollowsConstraint(moveOffset, directionList[direction]) )
            {
                if(spawns_movedToLeaveHull(position, minHullAgainstSpawns, maxHullAgainstSpawns, g_fSpawns_Positions[i], directionList[direction], insideHull, moveToAvoid))
                {
                    AddVectors(moveOffset, moveToAvoid, currentOffset);
                    AddVectors(position, moveToAvoid, currentPosition);
                }
                else if(!insideHull)
                    break;
                else
                    continue;
                
                TR_TraceRayFilter(position, currentPosition, MASK_PLAYERSOLID, RayType_EndPoint, spawns_TraceFilterClients);
                
                if(
                    !TR_DidHit() &&
                    GetVectorLength(currentOffset) < shortestDistance &&
                    spawns_CheckCorrectDistancesToWall(currentPosition, currentOffset, isDMSpawn, stack+1) &&
                    (distance = GetVectorLength(currentOffset)) < shortestDistance
                  )
                {
                    shortestDistance = distance;
                    selectedOffset = currentOffset;
                }
            }
        }
        
        if(!insideHull)
            continue;
        
        if(shortestDistance < SPAWNS_MAXIMUM_ADJUSTMENT_DISTANCE)
        {
            spawns_SaveCheckCorrectResult(position, shortestDistance, selectedOffset);
            moveOffset = selectedOffset;
            return true;
        }
        else
        {
            spawns_SaveCheckCorrectResult(position, SPAWNS_MAXIMUM_ADJUSTMENT_DISTANCE + 1.0, moveOffset);
            return false;
        }
    }
    
    spawns_SaveCheckCorrectResult(position, GetVectorLength(moveOffset), moveOffset);
    return true;
}

stock bool:spawns_CheckCorrectDistances(Float:position[3], bool:isDMSpawn)
{
    new Float:moveOffset[3] = {0.0, 0.0, 0.0};
    
    g_hSpawns_CheckDistanceSaveArray = CreateTrie();
    
    if(spawns_CheckCorrectDistancesToWall(position, moveOffset, isDMSpawn))
    {
        AddVectors(position, moveOffset, position);
        
        CloseHandle(g_hSpawns_CheckDistanceSaveArray);
        
        return true;
    }
    
    CloseHandle(g_hSpawns_CheckDistanceSaveArray);
    return false;
}

stock bool:spawns_CreateNewPoint(clientCreator, Spawns_Teams:team=Spawns_TeamBoth)
{
    if(g_iSpawns_PointCount >= SPAWNS_MAXPOINT)
        return false;
    
    g_iSpawns_Team[g_iSpawns_PointCount] = team;
    
    g_iSpawns_Entities[g_iSpawns_PointCount] = -1;
    
    GetClientAbsOrigin(clientCreator, g_fSpawns_Positions[g_iSpawns_PointCount]);
    GetClientAbsAngles(clientCreator, g_fSpawns_Angles[g_iSpawns_PointCount]);
    
    g_fSpawns_Positions[g_iSpawns_PointCount][2] += SPAWNS_SAFE_FLOOR_DISTANCE;
        
    if(!spawns_CheckCorrectDistances(g_fSpawns_Positions[g_iSpawns_PointCount], (team==Spawns_TeamBoth)))
        return false;
    
    if(team == Spawns_TeamT)
        g_iSpawns_TPointCount++;
    else if(team == Spawns_TeamCT)
        g_iSpawns_CTPointCount++;
    else if(team == Spawns_TeamBoth)
        g_iSpawns_DmPointCount++;
    
    g_iSpawns_PointCount++;
    
    return true;
}

stock spawns_ImportMapSpawns(clientIndex)
{
    if(
        g_iSpawns_MapTPointCount    > g_iSpawns_NotUsedTPointCount  ||
        g_iSpawns_MapCTPointCount   > g_iSpawns_NotUsedCTPointCount ||
        g_iSpawns_MapDMPointCount   > g_iSpawns_NotUsedDMPointCount
       )
    {
        PrintToConsole(clientIndex, "Some spawns have been used by plugin and won't be imported (%d T| %d CT | %d DM)", 
                                        g_iSpawns_MapTPointCount - g_iSpawns_NotUsedTPointCount,
                                        g_iSpawns_MapCTPointCount - g_iSpawns_NotUsedCTPointCount,
                                        g_iSpawns_MapDMPointCount - g_iSpawns_NotUsedDMPointCount);
        PrintToChat(clientIndex, " \x01\x0B\x07Some spawns have been used by plugin and won't be imported (%d T| %d CT | %d DM)", 
                                        g_iSpawns_MapTPointCount - g_iSpawns_NotUsedTPointCount,
                                        g_iSpawns_MapCTPointCount - g_iSpawns_NotUsedCTPointCount,
                                        g_iSpawns_MapDMPointCount - g_iSpawns_NotUsedDMPointCount);
    }
    
    for(new i = 0; i < g_iSpawns_NotUsedTPointCount; i++)
    {
        GetEntPropVector(g_iSpawns_NotUsedTEntities[i], Prop_Data, "m_vecOrigin", g_fSpawns_Positions[g_iSpawns_PointCount]);
        GetEntPropVector(g_iSpawns_NotUsedTEntities[i], Prop_Data, "m_angRotation", g_fSpawns_Angles[g_iSpawns_PointCount]);
        g_iSpawns_Entities[g_iSpawns_PointCount] = g_iSpawns_NotUsedTEntities[i];
        g_iSpawns_Team[g_iSpawns_PointCount] = Spawns_TeamT;
        g_iSpawns_TPointCount++;
        g_iSpawns_PointCount++;
    }
    
    for(new i = 0; i < g_iSpawns_NotUsedCTPointCount; i++)
    {
        GetEntPropVector(g_iSpawns_NotUsedCTEntities[i], Prop_Data, "m_vecOrigin", g_fSpawns_Positions[g_iSpawns_PointCount]);
        GetEntPropVector(g_iSpawns_NotUsedCTEntities[i], Prop_Data, "m_angRotation", g_fSpawns_Angles[g_iSpawns_PointCount]);
        g_iSpawns_Entities[g_iSpawns_PointCount] = g_iSpawns_NotUsedCTEntities[i];
        g_iSpawns_Team[g_iSpawns_PointCount] = Spawns_TeamCT;
        g_iSpawns_CTPointCount++;
        g_iSpawns_PointCount++;
    }
    
    for(new i = 0; i < g_iSpawns_NotUsedDMPointCount; i++)
    {
        GetEntPropVector(g_iSpawns_NotUsedDMEntities[i], Prop_Data, "m_vecOrigin", g_fSpawns_Positions[g_iSpawns_PointCount]);
        GetEntPropVector(g_iSpawns_NotUsedDMEntities[i], Prop_Data, "m_angRotation", g_fSpawns_Angles[g_iSpawns_PointCount]);
        g_iSpawns_Entities[g_iSpawns_PointCount] = g_iSpawns_NotUsedDMEntities[i];
        g_iSpawns_Team[g_iSpawns_PointCount] = Spawns_TeamBoth;
        g_iSpawns_DmPointCount++;
        g_iSpawns_PointCount++;
    }
    
    
    PrintToConsole(clientIndex, "Imported %d T| %d CT | %d DM spawns", 
                                    g_iSpawns_NotUsedTPointCount,
                                    g_iSpawns_NotUsedCTPointCount,
                                    g_iSpawns_NotUsedDMPointCount);
    PrintToChat(clientIndex, " \x01\x0B\x04Imported %d T| %d CT | %d DM spawns", 
                                    g_iSpawns_NotUsedTPointCount,
                                    g_iSpawns_NotUsedCTPointCount,
                                    g_iSpawns_NotUsedDMPointCount);
    
    g_iSpawns_NotUsedTPointCount = 0;
    g_iSpawns_NotUsedCTPointCount = 0;
    g_iSpawns_NotUsedDMPointCount = 0;
}

stock bool:spawns_Save()
{
    decl String:sTeam[4];
    new Handle:fileHandle = spawns_GetConfigFileHandle("w");
    
    if (fileHandle == INVALID_HANDLE)
        return false;

    for (new i = 0; i < g_iSpawns_PointCount; i++)
    {
        switch(g_iSpawns_Team[i])
        {
            case Spawns_TeamBoth:
                strcopy(sTeam, sizeof(sTeam), "");
                
            case Spawns_TeamT:
                strcopy(sTeam, sizeof(sTeam), " T");
                
            case Spawns_TeamCT:
                strcopy(sTeam, sizeof(sTeam), " CT");
        }
        
        WriteFileLine(fileHandle, "%f %f %f %f %f %f%s", 
                            g_fSpawns_Positions[i][0],
                            g_fSpawns_Positions[i][1],
                            g_fSpawns_Positions[i][2],
                            g_fSpawns_Angles[i][0],
                            g_fSpawns_Angles[i][1],
                            g_fSpawns_Angles[i][2],
                            sTeam);
    }
    
    CloseHandle(fileHandle);
    return true;
}

stock spawns_WarnSpawnsCount(clientIndex)
{
    if((g_iSpawns_TPointCount > 0) && (g_iSpawns_TPointCount < g_iSpawns_MapTPointCount))
    {
        PrintToConsole(clientIndex, "%d more T spawn points shall be created", g_iSpawns_MapTPointCount - g_iSpawns_TPointCount);
        PrintToChat(clientIndex, " \x01\x0B\x07%d more \x02T spawn points\x07 shall be created", g_iSpawns_MapTPointCount - g_iSpawns_TPointCount);
    }
    
    if((g_iSpawns_CTPointCount > 0) && (g_iSpawns_CTPointCount < g_iSpawns_MapCTPointCount))
    {
        PrintToConsole(clientIndex, "%d more CT spawn points shall be created", g_iSpawns_MapCTPointCount - g_iSpawns_CTPointCount);
        PrintToChat(clientIndex, " \x01\x0B\x07%d more \x0CCT spawn points\x07 shall be created", g_iSpawns_MapCTPointCount - g_iSpawns_CTPointCount);
    }
    
    if((g_iSpawns_DmPointCount > 0) && (g_iSpawns_DmPointCount < g_iSpawns_MapDMPointCount))
    {
        PrintToConsole(clientIndex, "%d more DM spawn points shall be created", g_iSpawns_MapDMPointCount - g_iSpawns_DmPointCount);
        PrintToChat(clientIndex, " \x01\x0B\x07%d more \x09DM spawn points\x07 shall be created", g_iSpawns_MapDMPointCount - g_iSpawns_DmPointCount);
    }
}

stock spawns_DisplaySpawnPoint(clientIndex, Float:position[3], Float:angles[3], Float:size, Spawns_Teams:team)
{
    new Float:direction[3];
    
    GetAngleVectors(angles, direction, NULL_VECTOR, NULL_VECTOR);
    ScaleVector(direction, size/2);
    AddVectors(position, direction, direction);

    TE_Start("BeamRingPoint");
    TE_WriteVector("m_vecCenter", position);
    TE_WriteFloat("m_flStartRadius", 10.0);
    TE_WriteFloat("m_flEndRadius", size);
    TE_WriteNum("m_nModelIndex", g_iBeamSprite);
    TE_WriteNum("m_nHaloIndex", g_iHaloSprite);
    TE_WriteNum("m_nStartFrame", 0);
    TE_WriteNum("m_nFrameRate", 0);
    TE_WriteFloat("m_fLife", 1.0);
    TE_WriteFloat("m_fWidth", 1.0);
    TE_WriteFloat("m_fEndWidth", 1.0);
    TE_WriteFloat("m_fAmplitude", 0.0);
    TE_WriteNum("r", SPAWNS_COLORS[_:team][0]);
    TE_WriteNum("g", SPAWNS_COLORS[_:team][1]);
    TE_WriteNum("b", SPAWNS_COLORS[_:team][2]);
    TE_WriteNum("a", SPAWNS_COLORS[_:team][3]);
    TE_WriteNum("m_nSpeed", 50);
    TE_WriteNum("m_nFlags", 0);
    TE_WriteNum("m_nFadeLength", 0);
    TE_SendToClient(clientIndex);
    
    TE_Start("BeamPoints");
    TE_WriteVector("m_vecStartPoint", position);
    TE_WriteVector("m_vecEndPoint", direction);
    TE_WriteNum("m_nModelIndex", g_iBeamSprite);
    TE_WriteNum("m_nHaloIndex", g_iHaloSprite);
    TE_WriteNum("m_nStartFrame", 0);
    TE_WriteNum("m_nFrameRate", 0);
    TE_WriteFloat("m_fLife", 1.0);
    TE_WriteFloat("m_fWidth", 1.0);
    TE_WriteFloat("m_fEndWidth", 1.0);
    TE_WriteFloat("m_fAmplitude", 0.0);
    TE_WriteNum("r", SPAWNS_COLORS[_:team][0]);
    TE_WriteNum("g", SPAWNS_COLORS[_:team][1]);
    TE_WriteNum("b", SPAWNS_COLORS[_:team][2]);
    TE_WriteNum("a", SPAWNS_COLORS[_:team][3]);
    TE_WriteNum("m_nSpeed", 50);
    TE_WriteNum("m_nFlags", 0);
    TE_WriteNum("m_nFadeLength", 0);
    TE_SendToClient(clientIndex);
}

stock spawns_DisplaySpawnPoints(clientIndex, startPoint, endPoint)
{    
    for (new i = startPoint; i < g_iSpawns_PointCount && i <= endPoint; i++)
    {
        spawns_DisplaySpawnPoint(
                                    clientIndex,
                                    g_fSpawns_Positions[i],
                                    g_fSpawns_Angles[i],
                                    40.0,
                                    g_iSpawns_Team[i]
                                );
    }
}

public Action:Spawns_Timer_Display(Handle:timer, any:clientRef)
{
    if(!g_bSpawns_EditorMode)
        return Plugin_Stop;
    
    new clientIndex = EntRefToEntIndex(clientRef);
    
    if(!players_IsClientValid(clientIndex) || !IsClientInGame(clientIndex))
    {
        g_bSpawns_EditorMode = false;
        userMessage_CancelDisplay(g_hSpawns_MessageHandle, clientIndex);
        return Plugin_Stop;
    }
    
    new Float:gameTime = GetGameTime();
    new Float:timeOffset = gameTime - RoundToFloor(gameTime);
    
    if(RoundToFloor(gameTime) == gameTime)
        timeOffset += 0.01; // Trick to avoid having 9 steps when we expect 10
    
    new pointsDisplayedPerStep = RoundToCeil(g_iSpawns_PointCount / 10.0);
    
    new startPoint = pointsDisplayedPerStep * RoundToFloor(timeOffset * 10.0);
    new endPoint = startPoint + pointsDisplayedPerStep - 1;
    
    spawns_DisplaySpawnPoints(clientIndex, startPoint, endPoint);
    
    return Plugin_Continue;
}

public Action:spawns_Hook_SetTransmit(entity, client)
{
    if (g_bSpawns_EditorMode && entity != client)
        return Plugin_Handled;
    
    return Plugin_Continue;
}

stock spawns_SetEditorModeProps(clientIndex)
{
    if (g_bSpawns_EditorMode && g_iSpawns_EditorMode_Client == clientIndex)
    {
        SetEntProp(clientIndex, Prop_Data, "m_takedamage", 0);
        SetEntProp(clientIndex, Prop_Data, "m_CollisionGroup", 2);
        SetEntPropFloat(clientIndex, Prop_Data, "m_flGravity", g_fConfig_SpawnEditorGravity_ratio);
        SetEntPropFloat(clientIndex, Prop_Data, "m_flLaggedMovementValue", g_fConfig_SpawnEditorSpeed_ratio);
    }
}

stock spawns_ToggleEdit(clientIndex)
{    
    if(!g_bSpawns_EditorMode)
    {
        CreateTimer(0.1, Spawns_Timer_Display,  EntIndexToEntRef(clientIndex), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
        userMessage_RequestDisplay(g_hSpawns_MessageHandle, clientIndex);
        
        SetEntProp(clientIndex, Prop_Data, "m_takedamage", 0);
        SetEntProp(clientIndex, Prop_Data, "m_CollisionGroup", 2);
        SetEntPropFloat(clientIndex, Prop_Data, "m_flGravity", g_fConfig_SpawnEditorGravity_ratio);
        SetEntPropFloat(clientIndex, Prop_Data, "m_flLaggedMovementValue", g_fConfig_SpawnEditorSpeed_ratio);
        SDKHook(clientIndex, SDKHook_SetTransmit, spawns_Hook_SetTransmit);
        g_iSpawns_EditorMode_Client = clientIndex;
        PrintToChat(clientIndex, "[ \x02DM\x01 ] You are now Invisible, God, and made of thin air!");
    }
    else
    {
        userMessage_CancelDisplay(g_hSpawns_MessageHandle, clientIndex);
        
        SetEntProp(clientIndex, Prop_Data, "m_takedamage", 2);
        SetEntProp(clientIndex, Prop_Data, "m_CollisionGroup", 5);
        SetEntPropFloat(clientIndex, Prop_Data, "m_flGravity", 1.0);
        SetEntPropFloat(clientIndex, Prop_Data, "m_flLaggedMovementValue", 1.0);
        SDKUnhook(clientIndex, SDKHook_SetTransmit, spawns_Hook_SetTransmit);
        PrintToChat(clientIndex, "[ \x02DM\x01 ] You are now back to normal!");
    }
    
    g_bSpawns_EditorMode = !g_bSpawns_EditorMode;
}

stock bool:spawns_SpawnAdminToFirstPoint(clientIndex)
{
    if(g_iSpawns_PointCount < 0)
        return false;
        
    g_iSpawns_AdminTestSpawnIndex = 0;
    
    g_iSpawns_AdminTestSpawnClientIndex = clientIndex;
    g_bSpawns_AdminTestSpawnRequested = true;
    
    CS_RespawnPlayer(clientIndex);
    
    return true;
}

stock bool:spawns_SpawnAdminToNextPoint(clientIndex)
{
    if(g_iSpawns_PointCount < 0)
        return false;
    
    if(g_iSpawns_AdminTestSpawnIndex+1 >= g_iSpawns_PointCount)
        g_iSpawns_AdminTestSpawnIndex = 0;
    else
        g_iSpawns_AdminTestSpawnIndex++;
    
    g_iSpawns_AdminTestSpawnClientIndex = clientIndex;
    g_bSpawns_AdminTestSpawnRequested = true;
    
    CS_RespawnPlayer(clientIndex);
    
    return true;
}

stock bool:spawns_SpawnAdminToLastPoint(clientIndex)
{
    if(g_iSpawns_PointCount < 0)
        return false;
    
    if(g_iSpawns_AdminTestSpawnIndex <= 0)
        g_iSpawns_AdminTestSpawnIndex = g_iSpawns_PointCount-1;
    else
        g_iSpawns_AdminTestSpawnIndex--;
    
    g_iSpawns_AdminTestSpawnClientIndex = clientIndex;
    g_bSpawns_AdminTestSpawnRequested = true;
    
    CS_RespawnPlayer(clientIndex);
    
    return true;
}

public bool:spawns_MessageBuildCallBack(clientIndex, argument, drawCount, drawDuration, String:message[], length)
{
    Format(message, length, "<font color='#3333AA'>Spawns CT</font>: %d (Map %d)\n<font color='#AA0000'>Spawns T</font>:  %d (Map %d)\n<font color='#AAAA00'>Spawns DM</font>: %d (Map %d)\n",
            g_iSpawns_CTPointCount, g_iSpawns_MapCTPointCount,
            g_iSpawns_TPointCount, g_iSpawns_MapTPointCount,
            g_iSpawns_DmPointCount, g_iSpawns_MapDMPointCount
          );
    
    return true;
}

stock Float:spawns_ComputeMaxInterSpawnDistance(Float:positions1[][3], size1, Float:positions2[][3], size2, bool:squared)
{
    new Float:maxDistance = 0.0;
    
    for(new spawnIndex = 0; spawnIndex < size1; spawnIndex++)
    {
        
        for(new spawnIndex2 = 0; spawnIndex2 < size2; spawnIndex2++)
        {
            new Float:Distance = GetVectorDistance(positions1[spawnIndex], positions2[spawnIndex2], squared);
            if(Distance > maxDistance)
                maxDistance = Distance;
            
        }
    }
    
    return maxDistance;
}

stock Float:spawns_ApplyMedianRatio(Float:medianRatio, Float:minTeamRatio)
{
    g_fSpawns_MedianInterDMDistance_Squared = g_fSpawns_MaxInterDMDistance_Squared * medianRatio;
    g_fSpawns_MedianInterTandCTDistance_Squared = g_fSpawns_MaxInterTAndCTDistance_Squared * medianRatio;
    g_fSpawns_MinTeamInterDMDistance_Squared = g_fSpawns_MaxInterDMDistance_Squared * minTeamRatio;
    g_fSpawns_MinTeamInterTDistance_Squared = g_fSpawns_MaxInterTDistance_Squared * minTeamRatio;
    g_fSpawns_MinTeamInterCTDistance_Squared = g_fSpawns_MaxInterCTDistance_Squared * minTeamRatio;
}

stock bool:spawns_IsSpawnPointClear(const Float:point[3], bool:validclients[])
{
    static Float:constraint[3] = {0.0, 0.0, 0.0};    // Unused, just to pass valid variable to hull function
    static Float:moveToAvoid[3];                    // Unused, just to pass valid variable to hull function
    static bool:insideHull;
    decl Float:position[3];
    
    for (new i = 1; i <= MaxClients; i++)
    if (validclients[i])
    {
        GetClientAbsOrigin(i, position);
        spawns_movedToLeaveHull(position, minHullAgainstSpawns, maxHullAgainstSpawns, point, constraint, insideHull, moveToAvoid);
        
        if(insideHull)
            return false;
    }
    
    return true;
}

stock spawns_ComputeValidSpawns(clientIndex, bool:validSpawns[], bool:validClients[], spawnEntities[], Float:spawnPositions[][3], spawnCount)
{
    for (new i = 0; i < spawnCount; i++)
    {
        if(g_hSpawns_Function_IsTriggered != INVALID_HANDLE && !SDKCall(g_hSpawns_Function_IsTriggered, spawnEntities[i], clientIndex))
        {
            validSpawns[i] = false;
        }
        else
        {
            validSpawns[i] = spawns_IsSpawnPointClear(spawnPositions[i], validClients);
        }
    }
}

stock Float:spawns_ComputeScoreFromDistance(Float:distance, bool:isTeammate, bool:isCT)
{
    if(isTeammate)
    {
        new Float:targetDistance = g_bConfig_mp_randomspawn ? g_fSpawns_MinTeamInterDMDistance_Squared : (isCT ? g_fSpawns_MinTeamInterCTDistance_Squared : g_fSpawns_MinTeamInterTDistance_Squared);
        if(distance >= targetDistance)
            return 1.0;
        else
        {
            new Float:r = distance/targetDistance;
            r = r*r;
            return r*r;
        }
    }
    else
    {
        new Float:targetDistance = g_bConfig_mp_randomspawn ? g_fSpawns_MedianInterDMDistance_Squared : g_fSpawns_MedianInterTandCTDistance_Squared;
        
        if(distance < targetDistance)
        {
            new Float:r = distance/targetDistance;
            r = r*r;
            return r*r;
        }
        else
            return targetDistance/distance;
    }
}

stock spawns_SelectSpawnPoint(clientIndex)
{
    if(g_bSpawns_AdminTestSpawnRequested && clientIndex == g_iSpawns_AdminTestSpawnClientIndex)
    {
        g_bSpawns_AdminTestSpawnRequested = false;
        
        adminCmd_SpawnTest_VerboseOnSpawned(clientIndex, g_iSpawns_AdminTestSpawnIndex);
        return spawns_AdminTestSpawn_PrepareSpawnEntity(g_iSpawns_AdminTestSpawnIndex);
    }
    
    if(g_bConfig_mp_randomspawn && (!g_bConfig_RandomSpam_Internal || g_iSpawns_LoadedDmPointCount <= 0))
        return -1;
    
    if(!g_bConfig_mp_randomspawn && (!g_bConfig_NormalSpam_Internal  || g_iSpawns_LoadedCTPointCount <= 0 || g_iSpawns_LoadedTPointCount <= 0))
        return -1;
    
    decl Float:spawnPointsDistances[SPAWNS_MAXPOINT][MAXPLAYERS + 1];
    
    decl bool:validEnemies[MAXPLAYERS + 1];
    decl totalEnnemiesCount;
    decl bool:validClients[MAXPLAYERS + 1];
    decl bool:validSpawns[SPAWNS_MAXPOINT];
    
    decl Float:spawnPointsScores[SPAWNS_MAXPOINT];
    decl Float:minTeammatesDistance_squared;
    decl Float:globalScore;
    
    new bool:isCT = GetClientTeam(clientIndex) == CS_TEAM_CT;
    
    new bool:includeCts = g_bConfig_mp_teammates_are_enemies || !isCT;
    new bool:includeTs = g_bConfig_mp_teammates_are_enemies || isCT;
    
    new SpawnsCount = g_bConfig_mp_randomspawn ?  g_iSpawns_LoadedDmPointCount : (!isCT ? g_iSpawns_LoadedTPointCount : g_iSpawns_LoadedCTPointCount);
    
    players_ComputeValidEnnemies(validEnemies, validClients, includeCts, includeTs, totalEnnemiesCount);
    spawns_ComputeValidSpawns(clientIndex, validSpawns, validClients, 
                                  g_bConfig_mp_randomspawn ?  g_iSpawns_LoadedDMEntities : (!isCT ? g_iSpawns_LoadedTEntities : g_iSpawns_LoadedCTEntities),
                                  g_bConfig_mp_randomspawn ?  g_fSpawns_LoadedDMPositions : (!isCT ? g_fSpawns_LoadedTPositions : g_fSpawns_LoadedCTPositions),
                                  SpawnsCount);
    
    new Float:maxScore = 0.0;
    new maxScoreIndex = 0;
    
    for(new spawnIndex = 0; spawnIndex < SpawnsCount; spawnIndex++)
    if(validSpawns[spawnIndex])
    {
        new Float:EnnemiesMinDistance_squared = players_GetMinDistanceToPoint(
            g_bConfig_mp_randomspawn ?  g_fSpawns_LoadedDMPositions[spawnIndex] : (!isCT ? g_fSpawns_LoadedTPositions[spawnIndex] : g_fSpawns_LoadedCTPositions[spawnIndex]),
            spawnPointsDistances[spawnIndex], globalScore, minTeammatesDistance_squared, validEnemies, validClients, isCT, .squared = true);
        
        spawnPointsScores[spawnIndex] = 
                spawns_ComputeScoreFromDistance(EnnemiesMinDistance_squared, .isTeammate = false, .isCT = isCT) *
                spawns_ComputeScoreFromDistance(minTeammatesDistance_squared, .isTeammate = true, .isCT = isCT);
        
        if(totalEnnemiesCount > 2)
            spawnPointsScores[spawnIndex] *= globalScore/totalEnnemiesCount;
        
        if(maxScore < spawnPointsScores[spawnIndex])
        {
            maxScore = spawnPointsScores[spawnIndex];
            maxScoreIndex = spawnIndex;
        }
    }
    
    new bestScoreBeforeLOS = maxScoreIndex;
    
    if((g_bConfig_mp_randomspawn && g_bConfig_mp_randomspawn_los) || (!g_bConfig_mp_randomspawn && g_bConfig_NormalSpam_LOS))
    {
        new bool:noLowerScore = false;
        decl Float:maxScoreAllowed;
        decl Float:pointPosition[3];
        pointPosition = g_bConfig_mp_randomspawn ?  g_fSpawns_LoadedDMPositions[maxScoreIndex] : (!isCT ? g_fSpawns_LoadedTPositions[maxScoreIndex] : g_fSpawns_LoadedCTPositions[maxScoreIndex]);
        pointPosition[2] += EYES_OFFSET;
        decl LOSSearch;
        
        while(!players_HasPointClearLineOfSight(pointPosition, spawnPointsDistances[maxScoreIndex], validEnemies, LOSSearch))
        {
            g_iSpawns_Stats_SpawnPointTestedFailed++;
            g_iSpawns_StatsMap_SpawnPointTestedFailed++;
            g_iSpawns_Stats_SpawnPointLOSSearch += LOSSearch;
            g_iSpawns_Stats_SpawnPointLOSSearchFailed += LOSSearch;
            g_iSpawns_StatsMap_SpawnPointLOSSearch += LOSSearch;
            g_iSpawns_StatsMap_SpawnPointLOSSearchFailed += LOSSearch;
            
            maxScore = 0.0;
            maxScoreAllowed = spawnPointsScores[maxScoreIndex];
            
            noLowerScore = true;
            
            for(new spawnIndex = 0; spawnIndex < SpawnsCount; spawnIndex++)
                if(
                    validSpawns[spawnIndex] &&
                    spawnPointsScores[spawnIndex] < maxScoreAllowed && 
                    spawnPointsScores[spawnIndex] > maxScore
                   )
                {
                    noLowerScore = false;
                    maxScore = spawnPointsScores[spawnIndex];
                    maxScoreIndex = spawnIndex;
                }
            
            if(noLowerScore)
            {
                maxScoreIndex = bestScoreBeforeLOS;
                g_iSpawns_Stats_SpawnLOSFailed++;
                g_iSpawns_StatsMap_SpawnLOSFailed++;
                break;
            }
            else
            {
                pointPosition = g_bConfig_mp_randomspawn ?  g_fSpawns_LoadedDMPositions[maxScoreIndex] : (!isCT ? g_fSpawns_LoadedTPositions[maxScoreIndex] : g_fSpawns_LoadedCTPositions[maxScoreIndex]);
                pointPosition[2] += EYES_OFFSET;
            }
        }
        
        g_iSpawns_Stats_SpawnPointLOSSearch += LOSSearch;
        g_iSpawns_StatsMap_SpawnPointLOSSearch += LOSSearch;
    }
    
    g_iSpawns_Stats_SpawnSucceded++;
    g_iSpawns_StatsMap_SpawnSucceded++;
    
    return g_bConfig_mp_randomspawn ?  g_iSpawns_LoadedDMEntities[maxScoreIndex] : (!isCT ? g_iSpawns_LoadedTEntities[maxScoreIndex] : g_iSpawns_LoadedCTEntities[maxScoreIndex]);
}

stock spawns_DisplayStats(clientIndex)
{
    ReplyToCommand(clientIndex, "================================\nSpawns stats for current Map:");
    ReplyToCommand(clientIndex, "Player Spawned: %d", g_iSpawns_StatsMap_SpawnSucceded);
    ReplyToCommand(clientIndex, "Player Spawned in other player LOS: %d (%f%%)", g_iSpawns_StatsMap_SpawnLOSFailed, 100.0 * g_iSpawns_StatsMap_SpawnLOSFailed / g_iSpawns_StatsMap_SpawnSucceded);
    ReplyToCommand(clientIndex, "Average LOS traced per spawn: %f", 1.0 * g_iSpawns_StatsMap_SpawnPointLOSSearch/g_iSpawns_StatsMap_SpawnSucceded);
    ReplyToCommand(clientIndex, "Average spawn position tested for LOS per spawn: %f", 1.0 * (g_iSpawns_StatsMap_SpawnPointTestedFailed + g_iSpawns_StatsMap_SpawnSucceded)/g_iSpawns_StatsMap_SpawnSucceded);
    if(g_iSpawns_StatsMap_SpawnPointTestedFailed>0)
        ReplyToCommand(clientIndex, "Average LOS traced per 'LOS not clear' spawn position: %f", 1.0 * g_iSpawns_StatsMap_SpawnPointLOSSearchFailed/g_iSpawns_StatsMap_SpawnPointTestedFailed);
    ReplyToCommand(clientIndex, "================================\nTOTAL spawns stats:");
    ReplyToCommand(clientIndex, "Player Spawned: %d", g_iSpawns_Stats_SpawnSucceded);
    ReplyToCommand(clientIndex, "Player Spawned in other player LOS: %d (%f%%)", g_iSpawns_Stats_SpawnLOSFailed, 100.0 * g_iSpawns_Stats_SpawnLOSFailed / g_iSpawns_Stats_SpawnSucceded);
    ReplyToCommand(clientIndex, "Average LOS traced per spawn: %f", 1.0 * g_iSpawns_Stats_SpawnPointLOSSearch/g_iSpawns_Stats_SpawnSucceded);
    ReplyToCommand(clientIndex, "Average spawn position tested for LOS per spawn: %f", 1.0 * (g_iSpawns_Stats_SpawnPointTestedFailed + g_iSpawns_Stats_SpawnSucceded)/g_iSpawns_Stats_SpawnSucceded);
    if(g_iSpawns_Stats_SpawnPointTestedFailed>0)
        ReplyToCommand(clientIndex, "Average LOS traced per 'LOS not clear' spawn position: %f", 1.0 * g_iSpawns_Stats_SpawnPointLOSSearchFailed/g_iSpawns_Stats_SpawnPointTestedFailed);
}