#pragma semicolon 1                  // Force strict semicolon mode.

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <sdkhooks>

#define PLUGIN_NAME             "Slag Soccer"
#define PLUGIN_AUTHOR           "Mecha the Slag"
#define PLUGIN_VERSION          "1.0"
#define PLUGIN_CONTACT          "www.mechaware.net/"

#define MODEL_BALL              "models/props_gameplay/ball001.mdl"
#define MODEL_GOALS             "models/goalposts.mdl"

#define DISTANCE_BALL_MIN       5.0    
#define DISTANCE_BALL_MAX       15.0    
#define DISTANCE_BALL_PUSH      40.0    
#define DAMAGE_BALL_LIMIT       70.0    
#define DAMAGE_BALL_MULTI       0.75    

new g_iBall = -1;
new g_iRedGoal = -1;
new g_iBlueGoal = -1;
new g_iLast = 0;
new g_iOffsetOrigin;

new Handle:g_hEnable = INVALID_HANDLE;

new Float:g_fCenter[3];
new Float:g_fBlueGoalPos[3];
new Float:g_fBlueGoalAngle[3];
new Float:g_fRedGoalPos[3];
new Float:g_fRedGoalAngle[3];
new Float:g_fDistanceCenter2;

new bool:g_bCheckOnce = false;
new bool:g_bRoundActive = false;
new bool:g_bEnable = true;

public Plugin:myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_NAME,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_CONTACT
};

public OnPluginStart() {

    HookEvent("teamplay_round_start", RoundStartEvent);
    HookEvent("teamplay_round_win", RoundWinEvent);

    g_iOffsetOrigin = FindSendPropOffs("CTFPlayer", "m_vecOrigin");
    
    CreateConVar("soccer_version", PLUGIN_VERSION, "Slag Soccer version", FCVAR_REPLICATED|FCVAR_NOTIFY);
    g_hEnable = CreateConVar("soccer_enable", "1", "Enable Slag Soccer");
    
    HookConVarChange(g_hEnable, GamemodeEnable);
    
    g_bEnable = GetConVarBool(g_hEnable);
}

public OnMapStart() {
    AddFileToDownloadsTable("models/goalposts.mdl");
    AddFileToDownloadsTable("models/goalposts.phy");
    AddFileToDownloadsTable("models/goalposts.dx80.vtx");
    AddFileToDownloadsTable("models/goalposts.dx90.vtx");
    AddFileToDownloadsTable("models/goalposts.sw.vtx");
    AddFileToDownloadsTable("models/goalposts.vvd");
    AddFileToDownloadsTable("models/goalposts.xbox.vtx");
    AddFileToDownloadsTable("materials/models/tor.vtf");
    AddFileToDownloadsTable("materials/models/tor.vmt");

    PrecacheModel(MODEL_BALL, true);
    PrecacheModel(MODEL_GOALS, true);
    
    if (!CreateOrigins()) {
        if (g_bEnable) {
            LogError("Unable to load origins");
        }
        g_bEnable = false;
    }
    
    if (g_bEnable) {
        SetupRequiredEntities();
        CreateGoals();
    }
}

public OnClientPostAdminCheck(iClient) {
    SDKHook(iClient, SDKHook_OnTakeDamage, SDKHook_ClientDamage);
}

public GamemodeEnable(Handle:hConvar, const String:strOld[], const String:strNew[]) {
    new bool:bEnable = (StringToInt(strNew) == 1);
    new bool:bEnable2 = (StringToInt(strOld) == 1);
    
    g_bEnable = bEnable;
    
    if (bEnable == bEnable2) return;
    
    if (bEnable) {
        CreateGoals();
        CreateBall();
        SetupRequiredEntities();
    } else {
        DestroyGoals();
        DestroyBall();
    }
}

CreateBall() {
    DestroyBall();
    
    new iEntity = CreateEntityByName("prop_physics_override");
    if (IsClassname(iEntity, "prop_physics_override")) {
        SetEntityModel(iEntity, MODEL_BALL);
        DispatchKeyValue(iEntity, "targetname", "ball");
        DispatchSpawn(iEntity);
        TeleportEntity(iEntity, g_fCenter, NULL_VECTOR, NULL_VECTOR);
        
        SDKHook(iEntity, SDKHook_OnTakeDamage, SDKHook_BallDamage);
        
        g_iBall = iEntity;
    }
}

CreateGoals() {
    CreateGoal(false);
    CreateGoal(true);
}

DestroyGoals() {
    DestroyGoal(g_iRedGoal);
    g_iRedGoal = -1;
    DestroyGoal(g_iBlueGoal);
    g_iBlueGoal = -1;
}

CreateGoal(bool:bRed = false) {
    if (bRed) {
        DestroyGoal(g_iRedGoal);
        g_iRedGoal = -1;
    }
    else {
        DestroyGoal(g_iBlueGoal);
        g_iBlueGoal = -1;
    }

    new iEntity = CreateEntityByName("prop_physics_override");
    if (IsClassname(iEntity, "prop_physics_override")) {
        SetEntityModel(iEntity, MODEL_GOALS);
        DispatchKeyValue(iEntity, "StartDisabled", "false");
        if (bRed) {
            DispatchKeyValue(iEntity, "targetname", "red_goal");
            SetEntityRenderColor(iEntity, 255, 70, 70, 255);
        } else {
            DispatchKeyValue(iEntity, "targetname", "blue_goal");
            SetEntityRenderColor(iEntity, 150, 200, 255, 255);
        }
        DispatchKeyValue(iEntity, "Solid", "6");
        SetEntProp(iEntity, Prop_Data, "m_CollisionGroup", 5);
        SetEntProp(iEntity, Prop_Data, "m_usSolidFlags", 16);
        SetEntProp(iEntity, Prop_Data, "m_nSolidType", 6);
        DispatchSpawn(iEntity);
        AcceptEntityInput(iEntity, "Enable");
        AcceptEntityInput(iEntity, "TurnOn");
        AcceptEntityInput(iEntity, "DisableMotion");
        if (bRed) {
            TeleportEntity(iEntity, g_fRedGoalPos, g_fRedGoalAngle, NULL_VECTOR);
            g_iRedGoal = iEntity;
        } else {
            TeleportEntity(iEntity, g_fBlueGoalPos, g_fBlueGoalAngle, NULL_VECTOR);
            g_iBlueGoal = iEntity;
        }
    }
}

NewRound() {
    if (g_bEnable) {
        SetupRequiredEntities();
        CreateGoals();
        CreateBall();
    }
    g_bRoundActive = true;
}

DestroyGoal(iEntity) {
    if (IsClassname(iEntity, "prop_physics")) {
        RemoveEdict(iEntity);
    }
}

DestroyBall() {
    new iEntity = g_iBall;
    g_iBall = -1;
    g_iLast = 0;
    g_bCheckOnce = false;
    if (IsClassname(iEntity, "prop_physics")) {
        RemoveEdict(iEntity);
    }
}

bool:CreateOrigins() {
    decl String:strMap[PLATFORM_MAX_PATH];
    GetCurrentMap(strMap, sizeof(strMap));
    
    new Handle:hKeyvalue = CreateKeyValues("MapData");
    
    decl String:strData[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, strData, PLATFORM_MAX_PATH, "data/SlagSoccer.txt");
        
    FileToKeyValues(hKeyvalue, strData);
    if (!KvJumpToKey(hKeyvalue, strMap)) return false;
    
    KvGetVector(hKeyvalue, "center", g_fCenter);
    KvGetVector(hKeyvalue, "red", g_fRedGoalPos);
    KvGetVector(hKeyvalue, "blue", g_fBlueGoalPos);
    KvGetVector(hKeyvalue, "redangle", g_fRedGoalAngle);
    KvGetVector(hKeyvalue, "blueangle", g_fBlueGoalAngle);
    
    g_fCenter[2] += 20;
    
    CloseHandle(hKeyvalue); 
    return true;
}

stock bool:IsClassname(iEntity, String:strClassname[]) {
    if (iEntity <= 0) return false;
    if (!IsValidEdict(iEntity)) return false;
    
    decl String:strClassname2[32];
    GetEdictClassname(iEntity, strClassname2, sizeof(strClassname2));
    if (StrEqual(strClassname, strClassname2, false)) return true;
    
    return false;
}

public RoundStartEvent(Handle:hEvent, const String:strName[], bool:bHide) {
    NewRound();
}

public RoundWinEvent(Handle:hEvent, const String:strName[], bool:bHide) {
    DestroyBall();
    g_bRoundActive = false;
}

public Action:SDKHook_ClientDamage(iVictim, &iAttacker, &iInflicter, &Float:fDamage, &iDamagetype) {
    if (!g_bEnable) return Plugin_Continue;
    if (!g_bRoundActive) return Plugin_Continue;
    if (IsValidClient(iVictim) && IsValidClient(iAttacker)) {
        new Float:fDistanceV = ClientDistanceFromBall(iVictim);
        new Float:fDistanceA = ClientDistanceFromBall(iAttacker);
        new Float:fDistance = (fDistanceV + fDistanceA) * 0.5;
        
        if (fDistance < DISTANCE_BALL_MIN) return Plugin_Continue;
        if (fDistance > DISTANCE_BALL_MAX) return Plugin_Stop;
        
        fDistance -= DISTANCE_BALL_MIN;
        if (fDistance <= 0.0) fDistance = 0.0;
        
        new Float:fNewMax = DISTANCE_BALL_MAX - DISTANCE_BALL_MIN;
        new Float:fMultiplier = (fNewMax - fDistance) / fNewMax;
        
        new Float:fNewDamage = fDamage * fMultiplier;
        if (fNewDamage <= 0.0) return Plugin_Stop;
        
        fDamage = fNewDamage;
        return Plugin_Changed;
    }
    return Plugin_Continue;
}

public Action:SDKHook_BallDamage(iVictim, &iAttacker, &iInflicter, &Float:fDamage, &iDamagetype) {
    if (!g_bEnable) return Plugin_Continue;
    if (!IsValidClient(iAttacker)) return Plugin_Continue;
    
    new Float:fDistance = ClientDistanceFromBall(iAttacker);
    
    if (fDistance > DISTANCE_BALL_PUSH) return Plugin_Stop;
    
    new Float:fMultiplier = (DISTANCE_BALL_PUSH - fDistance) / DISTANCE_BALL_PUSH;
    
    fDamage = fDamage * DAMAGE_BALL_MULTI * fMultiplier;
    if (fDamage > DAMAGE_BALL_LIMIT) fDamage = DAMAGE_BALL_LIMIT;
    if (fDamage <= 0.0) return Plugin_Stop;
    
    g_iLast = iAttacker;
    
    return Plugin_Changed;
}

Float:ClientDistanceFromBall(iClient) {
    if (!IsValidClient(iClient)) return 0.0;
    if (g_iBall <= 0) return 0.0;
    
    decl Float:fOriginClient[3], Float:fOriginBall[3];
    
    GetClientAbsOrigin(iClient, fOriginClient);
    GetEntDataVector(g_iBall, g_iOffsetOrigin, fOriginBall);
    
    return (GetVectorDistance(fOriginClient, fOriginBall) / 50.0);
}

public OnGameFrame() {
    if (g_bEnable) {
        BallCheck();
    }
}

BallCheck() {
    if (!IsClassname(g_iBall, "prop_physics")) return;
    
    
    decl Float:fOriginBall[3];
    GetEntDataVector(g_iBall, g_iOffsetOrigin, fOriginBall);
    
    new Float:fDistanceBallBlue = GetVectorDistance(fOriginBall, g_fBlueGoalPos);
    new Float:fDistanceBallRed = GetVectorDistance(fOriginBall, g_fRedGoalPos);
    new Float:fDistanceCenterRed = GetVectorDistance(g_fCenter, g_fRedGoalPos);
    new Float:fDistanceCenterBlue = GetVectorDistance(g_fCenter, g_fBlueGoalPos);
    new Float:fDistanceBallCenter = GetVectorDistance(fOriginBall, g_fCenter);
    
    if (g_bCheckOnce) {
        // The distance from the ball and the goal is less than 150.0
        // The distance from ball to center is greater than goal to center. This means the ball is behind the goal.
        // The ball is now further away from the center than it was previously.
        // The ball was previously closer to the center than the goal.
        if (fDistanceBallRed < 150.0 && fDistanceBallCenter > fDistanceCenterRed && fDistanceBallCenter > g_fDistanceCenter2 && fDistanceCenterRed > g_fDistanceCenter2) {
            ForceWinner(2);
        }
        if (fDistanceBallBlue < 150.0 && fDistanceBallCenter > fDistanceCenterBlue && fDistanceBallCenter > g_fDistanceCenter2 && fDistanceCenterBlue > g_fDistanceCenter2) {
            ForceWinner(3);
        }
    }
    
    g_bCheckOnce = true;
    
    g_fDistanceCenter2 = fDistanceBallCenter;
}

public ForceWinner(iWinner) {
    if (!g_bEnable) return;
    if (!g_bRoundActive) return;

    new iEntity = FindEntityByClassname(-1, "team_control_point_master");
    if (IsValidEdict(iEntity)) {
        SetVariantInt(iWinner);
        AcceptEntityInput(iEntity, "SetWinner");
    }
}

stock bool:IsValidClient(iClient) {
    if (iClient <= 0) return false;
    if (iClient > MaxClients) return false;
    return IsClientInGame(iClient);
}

SetupRequiredEntities() {
    new iControlMaster = FindEntityByClassname(-1, "team_control_point_master");
    if (iControlMaster == -1) {
        iControlMaster = CreateEntityByName("team_control_point_master");
        DispatchSpawn(iControlMaster);
        AcceptEntityInput(iControlMaster, "Enable");
    }        
}