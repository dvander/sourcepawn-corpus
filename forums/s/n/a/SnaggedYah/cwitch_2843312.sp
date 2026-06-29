/*
    ==================================================================================
    LEFT 4 DEAD 2 - COMMON INFECTED CONTROL MEGA
    Version 4.8 - Survivor Control Support
    ==================================================================================
    
    ✅ NEW in 4.8:
    - l4d2_survivor_can_control 1  → Survivor team có thể chiếm CI/Witch trong campaign
    - Survivor không bị suicide khi thoát, body được restore ngay chỗ cũ
    - Friendly fire bị chặn: survivor-controlled CI KHÔNG thể đánh đồng đội
    
    ✅ KEY CHANGES:
    - TAB = Switch animation mode
    - SHIFT = ONLY run faster (no conflicts!)
    - RIGHT CLICK (Mouse2) = Cycle walk style
    
    ✅ CONTROLS:
    MOVEMENT MODE:
    - W/A/S/D = Move & rotate
    - SHIFT = Run faster
    - Right Click (Mouse2) = Cycle walk style (8 styles)
    - SPACE = Jump
    - LMB = Attack
    - R = Toggle first/third person
    - Hold E (2s) = Release control
    
    POSE MODES:
    - TAB = Switch animation category (13 modes)
    - SPACE = Next animation in category
    - A/D = Rotate while in pose
    - R = Toggle camera
    
    ==================================================================================
*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "4.8-SURVIVOR-CONTROL"

#define FADE_IN 0x0001
#define CLASS_HUNTER 3
#define CLASS_TANK 8
#define CLASS_NOTINFECTED 9
#define EF_NODRAW 32
/* ==================== COMMON INFECTED TRACKING SYSTEM ==================== */
#define COMMON_LEN 128  // [TUNE] Số CI tối đa được track cùng lúc – tăng nếu server đông, giảm để nhẹ RAM
int g_iCommonCUR;
int g_iCommonID[COMMON_LEN];
int g_iCommonHP[COMMON_LEN];
int g_iCommonMaxHP[COMMON_LEN];
int g_iCommonOwner[COMMON_LEN];  // Client index đang control CI (-1 = không ai control)
/* ==================== DAMAGE REDUCTION SYSTEM ==================== */
#define MAX_KILL_STACKS 50  // [TUNE] Số stack giảm damage tối đa mỗi CI – 50 stacks = -25% damage mặc định
int g_iKillStacks[COMMON_LEN];  // Số lượng stack của mỗi CI
float g_fStackExpireTime[COMMON_LEN][MAX_KILL_STACKS];  // Thời gian hết hạn của từng stack
Handle h_CvarStackDuration, h_CvarStackReduction;
float g_fStackDuration, g_fStackReduction;
/* ==================== WITCH ANIMATIONS ==================== */
#define ANIM_STANDING_CRYING 2
#define ANIM_SITTING 4
#define ANIM_WALK 10
#define ANIM_TURN_RIGHT 34
#define ANIM_TURN_LEFT 35
#define ANIM_FALL 54
#define ANIM_JUMP 58
#define ANIM_LADDER_ASCEND 70
#define ANIM_LADDER_DESCEND 71

/* ==================== CORE MOVEMENT ANIMATIONS ==================== */
#define CI_IDLE_NEUTRAL        45
#define CI_IDLE_ALERT          14
#define CI_RUN_INTENSE         89
#define CI_SHAMBLE             78
#define CI_CROUCH_RUN          82
#define CI_ATTACK              102
#define CI_ATTACK_LOW          118
#define CI_JUMP                142
#define CI_FALL                154
#define CI_LAND_NEUTRAL        163
#define CI_LAND_HARD           169
#define CI_WALK_INTENSE        80

/* ==================== WALK STYLES (8 variations) ==================== */
new const g_WalkStyles[] = {
    70, 71, 72, 73, 74, 75, 76, 77
};
#define WALK_STYLES_COUNT 8

/* ==================== VAULT / STEP-UP SYSTEM ==================== */
#define VAULT_STEP_HEIGHT   45.0    // [TUNE] Chiều cao tele lên bậc thấp (bậc thang, vỉa hè) – tăng nếu bị stuck ở bậc cao
#define VAULT_HIGH_HEIGHT   85.0    // [TUNE] Chiều cao tele lên vật cản vừa (mui xe, thùng) – tăng nếu không leo được lên xe
#define VAULT_DETECT_DIST   38.0    // [TUNE] Khoảng cách phát hiện vật cản phía trước (units) – tăng nếu vault quá muộn
#define VAULT_COOLDOWN      0.4     // [TUNE] Thời gian chờ giữa 2 lần vault (giây) – giảm nếu cảm giác lag, tăng nếu vault spam

new const String:g_WalkStyleNames[WALK_STYLES_COUNT][] = {
    "Normal",      // 70
    "Limping",     // 71
    "Drunk",       // 72
    "Aggressive",  // 73
    "Cautious",    // 74
    "Tired",       // 75
    "Confused",    // 76
    "Enraged"      // 77
};

/* ==================== MODE 1: IDLE POSES (40+) ==================== */
new const g_IdlePoses[] = {
    45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59,
    14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33,
    149, 161, 249, 291, 339, 380
};
#define IDLE_POSES_COUNT 41

/* ==================== MODE 2: SITTING POSES (15+) ==================== */
new const g_SittingPoses[] = {
    251, 252, 253, 254, 255, 256, 257, 258, 259,
    260, 266, 267, 268, 269,
    250, 261, 287, 288
};
#define SITTING_POSES_COUNT 18

/* ==================== MODE 3: LYING POSES (15+) ==================== */
new const g_LyingPoses[] = {
    271, 272, 273, 274, 275, 276, 277, 278,
    279, 280, 281
};
#define LYING_POSES_COUNT 11

/* ==================== MODE 4: LEANING POSES (16) ==================== */
new const g_LeaningPoses[] = {
    289, 290, 291, 292,
    293, 294, 295, 296,
    297, 298, 299, 300,
    301, 302, 303, 304
};
#define LEANING_POSES_COUNT 16

/* ==================== MODE 5: SPECIAL ACTIONS (10+) ==================== */
new const g_SpecialPoses[] = {
    367, 368, 370, 373,
    371, 372, 374, 375, 379,
    409, 410
};
#define SPECIAL_POSES_COUNT 11

/* ==================== MODE 6: ATTACK VARIATIONS (30+) ==================== */
new const g_AttackPoses[] = {
    100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116,
    117, 118, 119,
    121, 122,
    96, 97, 98,
    396, 397, 398, 399
};
#define ATTACK_POSES_COUNT 31

/* ==================== MODE 7: CLIMBING POSES (70+) ==================== */
new const g_ClimbingPoses[] = {
    174, 175, 176, 177,
    178, 179, 180, 181,
    182, 183, 184, 185,
    186, 187, 188, 189,
    190, 191, 192, 193,
    194, 195, 196, 197,
    198, 199, 200, 201, 204,
    202, 203, 208, 209, 210, 211,
    212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 224, 225,
    226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239,
    240, 241, 242, 243, 244, 245
};
#define CLIMBING_POSES_COUNT 74

/* ==================== MODE 8: STAGGER/SHOVED (30+) ==================== */
new const g_StaggerPoses[] = {
    123, 124, 127, 128, 129, 131,
    132,
    133,
    134,
    135, 136, 137, 138, 139, 140, 141,
    262, 263, 264, 265,
    394, 395
};
#define STAGGER_POSES_COUNT 26

/* ==================== MODE 9: JUMP/LEAP (10+) ==================== */
new const g_JumpPoses[] = {
    142, 143, 144, 145, 146, 147, 148, 150, 151, 152, 153
};
#define JUMP_POSES_COUNT 11

/* ==================== MODE 10: FALL/LANDING (15+) ==================== */
new const g_FallPoses[] = {
    154, 155, 156, 157, 158, 159, 160,
    162, 163, 164, 165, 166, 167, 168,
    169, 170, 171, 172, 173
};
#define FALL_POSES_COUNT 19

/* ==================== MODE 11: DEATH ANIMATIONS (100+) ==================== */
new const g_DeathPoses[] = {
    306, 307, 308, 309, 310, 311, 312, 313, 314, 315, 316, 317, 318, 319, 320,
    321, 322, 323, 324, 325, 326, 327, 328, 329, 330, 331,
    332, 333, 334, 335, 336, 337, 338, 339, 340, 341, 342, 343,
    344, 345, 346, 347, 348, 349, 350, 351, 352, 353, 354, 355, 356, 357, 358, 359,
    360, 361, 362, 363, 364, 365, 366,
    376, 377,
    381, 382, 383, 384, 385, 386, 387,
    388, 389, 390, 391, 392, 393,
    400, 401, 402, 403, 404, 405, 406, 407, 408
};
#define DEATH_POSES_COUNT 96

/* ==================== MODE 12: MISC ACTIONS (10+) ==================== */
new const g_MiscPoses[] = {
    81, 82,
    80, 83, 84, 85, 86, 87, 89, 90, 91, 92, 93, 94, 95,
    411, 412, 413,
    442, 443, 444, 445
};
#define MISC_POSES_COUNT 24

/* ==================== MODE DEFINITIONS ==================== */
#define MODE_MOVEMENT   0
#define MODE_IDLE       1
#define MODE_SITTING    2
#define MODE_LYING      3
#define MODE_LEANING    4
#define MODE_SPECIAL    5
#define MODE_ATTACK     6
#define MODE_CLIMBING   7
#define MODE_STAGGER    8
#define MODE_JUMP       9
#define MODE_FALL       10
#define MODE_DEATH      11
#define MODE_MISC       12
#define MODE_COUNT      13

new const String:g_ModeNames[MODE_COUNT][] = {
    "Movement",
    "Idle Poses",
    "Sitting Poses",
    "Lying Poses",
    "Leaning Poses",
    "Special Actions",
    "Attack Variations",
    "Climbing Poses",
    "Stagger/Shoved",
    "Jump/Leap",
    "Fall/Landing",
    "Death Animations",
    "Misc Actions"
};

/* ==================== ENTITY TYPES ==================== */
#define ENTITY_WITCH 1
#define ENTITY_COMMON 2
#define ENTITY_BOTH 3
#define DAY_MIDNIGHT "1"
#define TEAM_INFECTED 3
#define TEAM_SURVIVOR 2
#define CAMERA_MODEL "models/w_models/weapons/w_eq_pipebomb.mdl"

/* ==================== PLUGIN INFO ==================== */
public Plugin:myinfo = 
{
    name = "Common Infected Control MEGA - Separated Keys",
    author = "DJ_WEST (Modified - Separated Keys Edition)",
    description = "300+ animations, SHIFT=run, Mouse2=walk style!",
    version = PLUGIN_VERSION,
    url = "http://amx-x.ru"
}

/* ==================== GLOBAL VARIABLES ==================== */
new g_b_WitchControl[MAXPLAYERS+1], Float:g_PlayerGameTime[MAXPLAYERS+1], bool:g_b_OnLadder[MAXPLAYERS+1],
    bool:g_b_FirstPerson[MAXPLAYERS+1], g_i_ClientCamera[MAXPLAYERS+1],
    Handle:g_h_SetClass, Handle:g_h_GameConfig, Float:g_WitchLadderOrigin[MAXPLAYERS+1], Handle:g_h_TeleportTimer[MAXPLAYERS+1],
    Float:g_PlayerTraceTimer[MAXPLAYERS+1], Handle:h_CvarWitchSpeed, Handle:h_CvarMode, Handle:h_CvarMessageType, Float:g_b_WitchJump[MAXPLAYERS+1],
    Handle:h_CvarAttack, Handle:h_CvarEntityType, g_i_EntityType[MAXPLAYERS+1], Handle:h_CvarCommonSpeed, g_i_CommonAnimSequence[MAXPLAYERS+1], Handle:g_h_AttackTimer[MAXPLAYERS+1],
    Float:g_LastCameraPos[MAXPLAYERS+1][3], bool:g_b_IsMoving[MAXPLAYERS+1], bool:g_b_IsFalling[MAXPLAYERS+1],
    Float:g_f_LastGroundZ[MAXPLAYERS+1], bool:g_b_IsAttacking[MAXPLAYERS+1], Float:g_f_LandingTime[MAXPLAYERS+1],
    g_i_AnimMode[MAXPLAYERS+1], g_i_AnimIndex[MAXPLAYERS+1], bool:g_b_InPoseMode[MAXPLAYERS+1],
    g_i_WalkStyleIndex[MAXPLAYERS+1], Float:g_f_LastWalkStyleChange[MAXPLAYERS+1],
    Float:g_fLastCameraAngles[MAXPLAYERS+1][3], Float:g_f_LastModeSwitch[MAXPLAYERS+1], Float:g_f_LastAttackPress[MAXPLAYERS+1],
Handle:h_CvarSurvivorControl,
    bool:g_b_WasSurvivor[MAXPLAYERS+1],
Handle:h_CvarKillReward, g_i_KillReward, Handle:h_CvarMaxHealth, g_i_MaxHealth, Float:g_f_LastShoveTime[MAXPLAYERS+1],
    Float:g_f_VaultCooldown[MAXPLAYERS+1]   // ✅ VAULT cooldown per client
/* ==================== PLUGIN START ==================== */
public OnPluginStart()
{
    decl String:s_Game[12], Handle:h_Version
    
    GetGameFolderName(s_Game, sizeof(s_Game))
    if (!StrEqual(s_Game, "left4dead2"))
        SetFailState("This plugin supports Left 4 Dead 2 only!")
        
    g_h_GameConfig = LoadGameConfigFile("l4d2_witch_control")

    if (g_h_GameConfig != INVALID_HANDLE)
    {
        StartPrepSDKCall(SDKCall_Player)
        PrepSDKCall_SetFromConf(g_h_GameConfig, SDKConf_Signature, "SetClass")
        PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain)
        g_h_SetClass = EndPrepSDKCall()
        
        if (g_h_SetClass == INVALID_HANDLE)
            SetFailState("Don't find SetClass function! Update gamedata/l4d2_witch_control.txt file.")
    }
    else
        SetFailState("Don't find gamedata/l4d2_witch_control.txt file!")
    
    CloseHandle(g_h_GameConfig)
    
    LoadTranslations("witch_control.phrases")
    
    h_Version = CreateConVar("witch_control_version", PLUGIN_VERSION, "Witch Control version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
    h_CvarWitchSpeed = CreateConVar("l4d2_witch_speed", "2.0", "Witch speed", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 1.0, true, 5.0)  // [TUNE] Tốc độ Witch – min 1.0, max 5.0
    h_CvarCommonSpeed = CreateConVar("l4d2_common_speed", "1.5", "Common infected speed multiplier", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.1, true, 5.0)  // [TUNE] Hệ số tốc độ CI – 1.0=bình thường, 2.0=nhanh gấp đôi
    h_CvarMode = CreateConVar("l4d2_witch_take_mode", "2", "Mode of taking control (0 - only alive, 1 - only ghost, 2 - both)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 2.0)
    h_CvarMessageType = CreateConVar("l4d2_witch_message_type", "3", "Message type (0 - disable, 1 - chat, 2 - hint, 3 - instructor hint)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 3.0)
    h_CvarAttack = CreateConVar("l4d2_witch_attack", "1", "Attack ability (0 - disable, 1 - enable)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0)
    h_CvarEntityType = CreateConVar("l4d2_control_entity_type", "3", "Entity types (1 - witch, 2 - common, 3 - both)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 1.0, true, 3.0)
    h_CvarKillReward = CreateConVar("l4d2_ci_kill_reward", "10", "Health reward per kill", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 100.0)  // [TUNE] HP cộng thêm mỗi lần giết – giảm nếu CI quá trâu
    h_CvarMaxHealth = CreateConVar("l4d2_ci_max_health", "200", "Max health for CI", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 100.0, true, 1000.0)  // [TUNE] HP tối đa CI có thể đạt – giảm nếu muốn nerf
    h_CvarStackDuration = CreateConVar("l4d2_ci_stack_duration", "60.0", "Duration of damage reduction stack (seconds)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 10.0, true, 300.0)  // [TUNE] Thời gian 1 stack giảm damage tồn tại (giây)
    h_CvarStackReduction = CreateConVar("l4d2_ci_stack_reduction", "2.0", "Damage reduction per kill (%)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.1, true, 5.0)  // [TUNE] % giảm damage mỗi stack – 2.0% x 50 stacks = -100% nhưng bị cap ở 75%
    h_CvarSurvivorControl = CreateConVar("l4d2_survivor_can_control", "1", "Allow survivors to control infected in campaign (0 = disabled, 1 = enabled)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0)
    HookEvent("witch_spawn", EventWitchSpawn)
    HookEvent("tank_spawn", EventTankSpawn)
    HookEvent("round_end", EventRoundEnd)
    HookEvent("infected_death", Event_InfectedDeath)
    SetConVarString(h_Version, PLUGIN_VERSION)
    
    LogMessage("[CI Control MEGA v%s] Loaded!", PLUGIN_VERSION)
    LogMessage("[CI Control] TAB = mode | SHIFT = run | Mouse2 = walk style")
}

public OnMapStart()
{
    DispatchKeyValue(0, "timeofday", DAY_MIDNIGHT)
    if (!IsModelPrecached(CAMERA_MODEL))
        PrecacheModel(CAMERA_MODEL)
    
    g_i_KillReward = GetConVarInt(h_CvarKillReward)
    g_i_MaxHealth = GetConVarInt(h_CvarMaxHealth)
    g_fStackDuration = GetConVarFloat(h_CvarStackDuration)
    g_fStackReduction = GetConVarFloat(h_CvarStackReduction)
    
    // ✅ RESET TRACKING
    g_iCommonCUR = 0
    for (int i = 0; i < COMMON_LEN; i++)
    {
        g_iCommonID[i] = -1
        g_iCommonHP[i] = 0
        g_iCommonMaxHP[i] = 0
        g_iCommonOwner[i] = -1
    }
    
    // Reset damage reduction stacks
    for (int i = 0; i < COMMON_LEN; i++)
    {
        g_iKillStacks[i] = 0
        for (int j = 0; j < MAX_KILL_STACKS; j++)
        {
            g_fStackExpireTime[i][j] = 0.0
        }
    }
    
    // ✅✅ HOOK TẤT CẢ CI ĐANG TỒN TẠI ✅✅
    CreateTimer(1.0, Timer_HookExistingCI)
}
public Action:Timer_HookExistingCI(Handle:h_Timer)
{
    new i_MaxEntities = GetMaxEntities()
    new String:s_ClassName[64]
    
    for (new i = MaxClients + 1; i < i_MaxEntities; i++)
    {
        if (!IsValidEntity(i))
            continue
        
        GetEntityClassname(i, s_ClassName, sizeof(s_ClassName))
        
        if (StrEqual(s_ClassName, "infected"))
        {
            // Hook damage
            SDKHook(i, SDKHook_OnTakeDamagePost, OnCommonTakeDamage)
            SDKHook(i, SDKHook_OnTakeDamage, OnCommonTakeDamagePre)
            
            // Thêm vào tracking
            new bool:bAlreadyTracked = false
            for (new j = 0; j < COMMON_LEN; j++)
            {
                if (g_iCommonID[j] == i)
                {
                    bAlreadyTracked = true
                    break
                }
            }
            
            if (!bAlreadyTracked)
            {
                g_iCommonID[g_iCommonCUR] = i
                g_iCommonHP[g_iCommonCUR] = GetEntProp(i, Prop_Data, "m_iHealth")
                g_iCommonMaxHP[g_iCommonCUR] = g_iCommonHP[g_iCommonCUR]
                g_iCommonOwner[g_iCommonCUR] = -1
                g_iCommonCUR = (g_iCommonCUR + 1) % COMMON_LEN
            }
        }
    }
    
    LogMessage("[CI Control] Hooked %d existing Common Infected", g_iCommonCUR)
    return Plugin_Handled
}
/* ==================== CLIENT CONNECT/DISCONNECT ==================== */
public OnClientPutInServer(i_Client)
{
    if (IsFakeClient(i_Client))
        return
        
    g_b_OnLadder[i_Client] = false
    g_b_WitchControl[i_Client] = 0
    g_i_CommonAnimSequence[i_Client] = -1
    g_b_FirstPerson[i_Client] = false
    g_i_ClientCamera[i_Client] = 0
    g_LastCameraPos[i_Client][0] = 0.0
    g_LastCameraPos[i_Client][1] = 0.0
    g_LastCameraPos[i_Client][2] = 0.0
    g_b_IsMoving[i_Client] = false
    g_b_IsFalling[i_Client] = false
    g_b_IsAttacking[i_Client] = false
    g_i_AnimMode[i_Client] = MODE_MOVEMENT
    g_i_AnimIndex[i_Client] = 0
    g_b_InPoseMode[i_Client] = false
    g_i_WalkStyleIndex[i_Client] = 0
    g_f_LastWalkStyleChange[i_Client] = 0.0
    g_fLastCameraAngles[i_Client][0] = 0.0
    g_fLastCameraAngles[i_Client][1] = 0.0
    g_fLastCameraAngles[i_Client][2] = 0.0
    g_f_LastModeSwitch[i_Client] = 0.0
    g_f_LastAttackPress[i_Client] = 0.0
    g_f_VaultCooldown[i_Client] = 0.0  // ✅ VAULT
    g_b_WasSurvivor[i_Client] = false
}

public OnClientDisconnected(i_Client)
{
    if (IsFakeClient(i_Client))
        return

    if (g_h_TeleportTimer[i_Client] != INVALID_HANDLE)
    {
        KillTimer(g_h_TeleportTimer[i_Client])
        g_h_TeleportTimer[i_Client] = INVALID_HANDLE
    }

    if (g_h_AttackTimer[i_Client] != INVALID_HANDLE)
    {
        KillTimer(g_h_AttackTimer[i_Client])
        g_h_AttackTimer[i_Client] = INVALID_HANDLE
    }
    g_f_VaultCooldown[i_Client] = 0.0  // ✅ Reset vault khi disconnect
}

/* ==================== TAKE CONTROL ==================== */
public Action:SetWitchControl(Handle:h_Timer, Handle:h_Pack)
{
    decl i_Camera, i_Client, i_Witch, Handle:h_PackData
    
    ResetPack(h_Pack, false)
    i_Client = ReadPackCell(h_Pack)
    i_Witch = ReadPackCell(h_Pack)
    CloseHandle(h_Pack)
    
    if (g_b_WitchControl[i_Client] || !IsValidEdict(i_Witch) || !IsClientInGame(i_Client))
        return
            
    g_b_WitchControl[i_Client] = i_Witch
    g_b_WasSurvivor[i_Client] = (GetClientTeam(i_Client) == TEAM_SURVIVOR)
// ✅ LƯU OWNER VÀO TRACKING
    new i_CommonNum = GetCommonNumber(i_Witch)
    if (i_CommonNum != -1)
    {
        g_iCommonOwner[i_CommonNum] = i_Client
    }
    g_WitchLadderOrigin[i_Client] = 0.0
    g_PlayerTraceTimer[i_Client] = 0.0
    g_b_WitchJump[i_Client] = 0.0
    g_i_CommonAnimSequence[i_Client] = -1
    g_b_IsMoving[i_Client] = false
    g_b_IsFalling[i_Client] = false
    g_b_IsAttacking[i_Client] = false

    // Class change: giống hệt infected controller cho tất cả
    SDKCall(g_h_SetClass, i_Client, CLASS_HUNTER)
    CreateTimer(0.1, ChangeClass, i_Client)
    SetEntPropEnt(i_Witch, Prop_Data, "m_hOwnerEntity", i_Client)
    
    if (g_i_EntityType[i_Client] == ENTITY_COMMON)
    {
        SetEntProp(i_Witch, Prop_Data, "m_takedamage", 2, 1)
        SetEntProp(i_Witch, Prop_Data, "m_lifeState", 0)
        SetEntProp(i_Witch, Prop_Send, "m_iTeamNum", 3)
        SetEntProp(i_Witch, Prop_Send, "m_bClientSideAnimation", 1)
        SetEntPropFloat(i_Witch, Prop_Send, "m_flPlaybackRate", 1.0)
        SetEntProp(i_Witch, Prop_Data, "m_nSequence", CI_IDLE_NEUTRAL)
// ✅ Force parity ngay khi take control lần đầu
new i_InitParity = (GetEntProp(i_Witch, Prop_Send, "m_nNewSequenceParity") + 1) & 15
SetEntProp(i_Witch, Prop_Send, "m_nNewSequenceParity", i_InitParity)
        g_i_CommonAnimSequence[i_Client] = CI_IDLE_NEUTRAL
        // ✅ TẮT AI & CLEAR FLAGS
        
        SetEntProp(i_Witch, Prop_Send, "m_mobRush", 0)  // Clear mob rush
        decl Float:f_ZeroVel[3], Float:f_CurrentOrigin[3], Float:f_CurrentAngles[3]
        GetEntPropVector(i_Witch, Prop_Send, "m_vecOrigin", f_CurrentOrigin)
        GetEntPropVector(i_Witch, Prop_Send, "m_angRotation", f_CurrentAngles)
        f_ZeroVel[0] = 0.0
        f_ZeroVel[1] = 0.0
        f_ZeroVel[2] = 0.0
        TeleportEntity(i_Witch, f_CurrentOrigin, f_CurrentAngles, f_ZeroVel)
        g_f_LastGroundZ[i_Client] = f_CurrentOrigin[2]
        SetEntProp(i_Witch, Prop_Send, "m_fFlags", GetEntityFlags(i_Witch) | FL_FROZEN)
        
CreateTimer(1.5, UnfreezeCommon, i_Client)
        i_Camera = CreateCommonCamera(i_Witch, i_Client)
        if (i_Camera)
        {
            g_i_ClientCamera[i_Client] = i_Camera
            if (!g_b_FirstPerson[i_Client])
                AcceptEntityInput(i_Camera, "Enable", i_Client)
            new i_ActiveWpn = GetEntPropEnt(i_Client, Prop_Data, "m_hActiveWeapon")
            if (i_ActiveWpn != -1)
                RemovePlayerItem(i_Client, i_ActiveWpn)
            AcceptEntityInput(i_Client, "DisableShadow")
            g_h_TeleportTimer[i_Client] = CreateTimer(0.1, TeleportPlayer, i_Client, TIMER_REPEAT)
            
            decl Float:f_InitAngles[3]
            GetEntPropVector(i_Witch, Prop_Send, "m_angRotation", f_InitAngles)
            g_fLastCameraAngles[i_Client][0] = 0.0
            g_fLastCameraAngles[i_Client][1] = f_InitAngles[1] - 75.0
            g_fLastCameraAngles[i_Client][2] = -90.0
        }
    }
    else if (g_i_EntityType[i_Client] == ENTITY_WITCH)
    {
        i_Camera = CreateCamera(i_Witch, i_Client)
        if (i_Camera)
        {
            g_i_ClientCamera[i_Client] = i_Camera
            if (!g_b_FirstPerson[i_Client])
                AcceptEntityInput(i_Camera, "Enable", i_Client)
            new i_ActiveWpn2 = GetEntPropEnt(i_Client, Prop_Data, "m_hActiveWeapon")
            if (i_ActiveWpn2 != -1)
                RemovePlayerItem(i_Client, i_ActiveWpn2)
            AcceptEntityInput(i_Client, "DisableShadow")
            g_h_TeleportTimer[i_Client] = CreateTimer(0.1, TeleportPlayer, i_Client, TIMER_REPEAT)
            
            decl Float:f_InitAngles[3]
            GetEntPropVector(i_Witch, Prop_Send, "m_angRotation", f_InitAngles)
            g_fLastCameraAngles[i_Client][0] = 0.0
            g_fLastCameraAngles[i_Client][1] = f_InitAngles[1] - 75.0
            g_fLastCameraAngles[i_Client][2] = -90.0
        }
    }
    
    h_PackData = CreateDataPack()
    WritePackCell(h_PackData, i_Client)
    if (g_i_EntityType[i_Client] == ENTITY_WITCH)
    {
        WritePackString(h_PackData, "Sit witch")
        WritePackString(h_PackData, "+duck")
        CreateTimer(0.1, DisplayHint, h_PackData)
        
        h_PackData = CreateDataPack()
        WritePackCell(h_PackData, i_Client)
        WritePackString(h_PackData, "Lose witch")
        WritePackString(h_PackData, "+use")
        CreateTimer(7.0, DisplayHint, h_PackData)
    }
    else if (g_i_EntityType[i_Client] == ENTITY_COMMON)
    {
        CreateTimer(0.5, ShowCommonControls, i_Client)
        
        // ✅ Hiển thị tên CI
        new i_CINum = GetCommonNumber(i_Witch)  // ✅ Đổi tên
        if (i_CINum != -1)
        {
            PrintToChat(i_Client, "\x04[CI Control] \x01You are controlling \x03Common(%d) \x01- HP: \x05%d\x01/\x05%d", 
                i_CINum + 1,  // ✅ Dùng tên mới
                g_iCommonHP[i_CINum], 
                g_iCommonMaxHP[i_CINum])
            
            // ✅ LƯU OWNER
            g_iCommonOwner[i_CINum] = i_Client  // ✅ Dùng tên mới
        }
    }
}

/* ==================== CAMERA CREATION ==================== */
public CreateCommonCamera(i_Common, i_Client)
{
    decl i_Camera, Float:f_Origin[3], Float:f_Angles[3]
    
    GetEntPropVector(i_Common, Prop_Send, "m_vecOrigin", f_Origin)
    GetEntPropVector(i_Common, Prop_Send, "m_angRotation", f_Angles)
    
    i_Camera = CreateEntityByName("point_viewcontrol")
    if (IsValidEdict(i_Camera))
    {
        decl String:s_ClientName[32]
        FormatEx(s_ClientName, sizeof(s_ClientName), "common_client_%d", i_Client)
        DispatchKeyValue(i_Client, "targetname", s_ClientName)
        
        decl String:s_CameraName[32]
        FormatEx(s_CameraName, sizeof(s_CameraName), "common_camera_%d", i_Client)
        DispatchKeyValue(i_Camera, "targetname", s_CameraName)
        
        DispatchSpawn(i_Camera)
        ActivateEntity(i_Camera)
        
        SetVariantString("!activator")
        AcceptEntityInput(i_Camera, "SetParent", i_Common)
        SetVariantString("Head")
        AcceptEntityInput(i_Camera, "SetParentAttachment")
        
        decl Float:f_CamAngles[3]
        f_CamAngles[0] = 0.0
        f_CamAngles[1] = 0.0
        f_CamAngles[2] = -90.0
        TeleportEntity(i_Camera, Float:{-2.0, 0.0, 0.0}, f_CamAngles, NULL_VECTOR)
        
        AcceptEntityInput(i_Camera, "DisableShadow")
        SetEntityRenderMode(i_Camera, RENDER_TRANSCOLOR)
        SetEntityRenderColor(i_Camera, 0, 0, 0, 0)
    
        return i_Camera
    }
    
    return 0
}

public CreateCamera(i_Witch, i_Client)
{
    decl i_Camera, Float:f_Origin[3], Float:f_Angles[3]
    
    GetEntPropVector(i_Witch, Prop_Send, "m_vecOrigin", f_Origin)
    GetEntPropVector(i_Witch, Prop_Send, "m_angRotation", f_Angles)
    
    i_Camera = CreateEntityByName("point_viewcontrol")
    if (IsValidEdict(i_Camera))
    {
        decl String:s_TargetName[32]
        FormatEx(s_TargetName, sizeof(s_TargetName), "witch_camera_%d", i_Client)
        DispatchKeyValue(i_Camera, "targetname", s_TargetName)
        
        decl String:s_ClientName[32]
        FormatEx(s_ClientName, sizeof(s_ClientName), "client_%d", i_Client)
        DispatchKeyValue(i_Client, "targetname", s_ClientName)
        
        DispatchSpawn(i_Camera)
        ActivateEntity(i_Camera)
        
        SetVariantString("!activator")
        AcceptEntityInput(i_Camera, "SetParent", i_Witch)
        SetVariantString("reye")
        AcceptEntityInput(i_Camera, "SetParentAttachment")
        
        decl Float:f_CamAngles[3]
        f_CamAngles[0] = 0.0
        f_CamAngles[1] = 0.0
        f_CamAngles[2] = -90.0
        TeleportEntity(i_Camera, Float:{-2.0, 0.0, 0.0}, f_CamAngles, NULL_VECTOR)
        
        AcceptEntityInput(i_Camera, "DisableShadow")
        SetEntityRenderMode(i_Camera, RENDER_TRANSCOLOR)
        SetEntityRenderColor(i_Camera, 0, 0, 0, 0)
    
        return i_Camera
    }
    
    return 0
}

/* ==================== SHOW CONTROLS ==================== */
public Action:ShowCommonControls(Handle:h_Timer, any:i_Client)
{
    if (!IsClientInGame(i_Client))
        return Plugin_Handled
    
    if (!g_b_WitchControl[i_Client] || g_i_EntityType[i_Client] != ENTITY_COMMON)
        return Plugin_Handled
    
    PrintToChat(i_Client, "\x04[CI Control MEGA] \x01Welcome!")
    PrintToChat(i_Client, "\x03Movement: \x01W/S/D/A | SHIFT = run faster")
    PrintToChat(i_Client, "\x03Walk Style: \x01Right Click (Mouse2) = cycle (8 styles)")
    PrintToChat(i_Client, "\x03Pose System: \x01TAB = switch mode | SPACE = next pose")
    PrintToChat(i_Client, "\x0313 modes \x01with \x05300+ animations!")
    PrintToChat(i_Client, "\x04Hold E 2s to release control")
    
    return Plugin_Handled
}
/* ==================== COMMON INFECTED TRACKING EVENTS ==================== */
public Action:Event_InfectedDeath(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
    new i_VictimID = GetEventInt(h_Event, "entityid")
    
    // Xóa victim khỏi tracking + check xem có player nào đang control không
    for (new i = 0; i < COMMON_LEN; i++)
    {
        if (g_iCommonID[i] == i_VictimID)
        {
            g_iCommonID[i] = -1
            g_iCommonHP[i] = 0
            g_iCommonMaxHP[i] = 0
            g_iCommonOwner[i] = -1
            break
        }
    }
    
    return Plugin_Continue
}

public OnEntityCreated(i_Entity, const String:s_ClassName[])
{
    if (StrEqual(s_ClassName, "infected"))
    {
        // Hook damage cho CI mới spawn
        SDKHook(i_Entity, SDKHook_OnTakeDamagePost, OnCommonTakeDamage)
        SDKHook(i_Entity, SDKHook_OnTakeDamage, OnCommonTakeDamagePre)  // ✅ THÊM PRE-HOOK ĐỂ GIẢM DAMAGE
        
        // Đăng ký CI vào tracking system
        CreateTimer(0.1, Timer_RegisterCommon, i_Entity)
    }
}

public Action:Timer_RegisterCommon(Handle:h_Timer, any:i_Entity)
{
    if (!IsValidEdict(i_Entity))
        return Plugin_Handled
    
    // Kiểm tra xem đã tồn tại chưa
    for (new i = 0; i < COMMON_LEN; i++)
    {
        if (g_iCommonID[i] == i_Entity)
            return Plugin_Handled  // Đã có rồi
    }
    
    // Thêm mới
    g_iCommonID[g_iCommonCUR] = i_Entity
    g_iCommonHP[g_iCommonCUR] = GetEntProp(i_Entity, Prop_Data, "m_iHealth")
    g_iCommonMaxHP[g_iCommonCUR] = g_iCommonHP[g_iCommonCUR]
    g_iCommonCUR = (g_iCommonCUR + 1) % COMMON_LEN
    
    return Plugin_Handled
}

public OnCommonTakeDamage(i_Victim, i_Attacker, i_Inflictor, Float:f_Damage, i_DamageType)
{
    if (!IsValidEdict(i_Attacker) || !IsValidEdict(i_Victim))
        return
    
    new String:s_AttackerClass[64], String:s_VictimClass[64]
    GetEdictClassname(i_Attacker, s_AttackerClass, sizeof(s_AttackerClass))
    GetEdictClassname(i_Victim, s_VictimClass, sizeof(s_VictimClass))
    
    // ✅ CHECK CẢ BOT CI VÀ PLAYER-CONTROLLED CI
    if (StrEqual(s_AttackerClass, "infected") && StrEqual(s_VictimClass, "infected"))
    {
        new i_VictimHP = GetEntProp(i_Victim, Prop_Data, "m_iHealth")
        
        if (i_VictimHP <= 0)
        {
            new i_AttackerNum = GetCommonNumber(i_Attacker)
            
            if (i_AttackerNum != -1)
            {
                // ✅ CHECK OWNER
                new i_Owner = g_iCommonOwner[i_AttackerNum]
                new bool:b_IsPlayerControlled = (i_Owner > 0 && IsClientInGame(i_Owner))
                
                // Cộng máu
                g_iCommonHP[i_AttackerNum] += g_i_KillReward
                
                new i_NewMaxHP = g_iCommonMaxHP[i_AttackerNum] + RoundFloat(g_i_KillReward * 0.5)
                if (i_NewMaxHP > g_i_MaxHealth)
                    i_NewMaxHP = g_i_MaxHealth
                
                g_iCommonMaxHP[i_AttackerNum] = i_NewMaxHP
                
                if (g_iCommonHP[i_AttackerNum] > i_NewMaxHP)
                    g_iCommonHP[i_AttackerNum] = i_NewMaxHP
                
                SetEntProp(i_Attacker, Prop_Data, "m_iHealth", g_iCommonHP[i_AttackerNum])
                
                // ✅ THÊM STACK
                if (g_iKillStacks[i_AttackerNum] < MAX_KILL_STACKS)
                {
                    for (new j = 0; j < MAX_KILL_STACKS; j++)
                    {
                        if (g_fStackExpireTime[i_AttackerNum][j] <= GetGameTime())
                        {
                            g_fStackExpireTime[i_AttackerNum][j] = GetGameTime() + g_fStackDuration
                            g_iKillStacks[i_AttackerNum]++
                            break
                        }
                    }
                }
                // ✅ HIỂN THỊ NOTIFICATION (ưu tiên controller)
                if (b_IsPlayerControlled)
                {
                    // Hiển thị cho player đang control
                    new i_VictimNum = GetCommonNumber(i_Victim)
                    PrintToChat(i_Owner, "\x04[YOU] \x05Killed \x03Common(%d) \x01→ HP:\x05%d \x01| Armor:\x04-%0.1f%%", 
                        i_VictimNum + 1, 
                        g_iCommonHP[i_AttackerNum],
                        float(g_iKillStacks[i_AttackerNum]) * g_fStackReduction)
                }
                
                ShowKillNotification(i_Attacker, i_Victim, i_AttackerNum)
            }
        }
    }
}
public Action:OnCommonTakeDamagePre(i_Victim, &i_Attacker, &i_Inflictor, &Float:f_Damage, &i_DamageType)
{
    if (!IsValidEdict(i_Victim))
        return Plugin_Continue
    
    new i_VictimNum = GetCommonNumber(i_Victim)
    if (i_VictimNum == -1)
        return Plugin_Continue
    
    // ✅ TÍNH SỐ STACK
    new Float:f_CurrentTime = GetGameTime()
    new i_ActiveStacks = 0
    
    for (new i = 0; i < MAX_KILL_STACKS; i++)
    {
        if (g_fStackExpireTime[i_VictimNum][i] > f_CurrentTime)
        {
            i_ActiveStacks++
        }
        else if (g_fStackExpireTime[i_VictimNum][i] > 0.0)
        {
            g_fStackExpireTime[i_VictimNum][i] = 0.0
            if (g_iKillStacks[i_VictimNum] > 0)
                g_iKillStacks[i_VictimNum]--
        }
    }
    // ✅ ÁP DỤNG GIẢM DAMAGE
    if (i_ActiveStacks > 0)
    {
        new Float:f_OriginalDmg = f_Damage
        new Float:f_Reduction = 1.0 - (float(i_ActiveStacks) * g_fStackReduction / 100.0)
        
        if (f_Reduction < 0.25)  // [TUNE] Cap giảm damage tối đa = 75% (0.25 = còn lại 25% damage) – giảm số này để nerf
            f_Reduction = 0.25
        
        f_Damage *= f_Reduction
                
        // Hiển thị cho player gần
        for (new i = 1; i <= MaxClients; i++)
        {
            if (!IsClientInGame(i))
                continue
            
            new Float:f_PlayerPos[3], Float:f_VictimPos[3]
            GetClientAbsOrigin(i, f_PlayerPos)
            GetEntPropVector(i_Victim, Prop_Send, "m_vecOrigin", f_VictimPos)
            
            if (GetVectorDistance(f_PlayerPos, f_VictimPos) <= 300.0)  // [TUNE] Khoảng cách hiện thông báo armor cho player gần (units)
            {
                PrintToChat(i, "\x04[Armor] \x03#%d \x01blocked \x05%.1f→%.1f dmg \x01(\x04-%d%%\x01)", 
                    i_VictimNum + 1, f_OriginalDmg, f_Damage, 
                    RoundToNearest((1.0 - f_Reduction) * 100.0))
            }
        }
        
        return Plugin_Changed
    }
    
    return Plugin_Continue
}

stock ShowDamageReduction(i_Victim, i_VictimNum, i_Stacks, Float:f_Reduction)
{
    new Float:f_VictimPos[3]
    GetEntPropVector(i_Victim, Prop_Send, "m_vecOrigin", f_VictimPos)
    
    for (new i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i))
            continue
        
        new Float:f_PlayerPos[3]
        GetClientAbsOrigin(i, f_PlayerPos)
        
        // Chỉ hiển thị cho player trong 300 units (throttle spam)
        if (GetVectorDistance(f_PlayerPos, f_VictimPos) <= 300.0)
        {
            new Float:f_TimeLeft = g_fStackExpireTime[i_VictimNum][0] - GetGameTime()
            
            // Tìm thời gian expire gần nhất
            for (new j = 1; j < MAX_KILL_STACKS; j++)
            {
                if (g_fStackExpireTime[i_VictimNum][j] > 0.0)
                {
                    new Float:f_ThisTime = g_fStackExpireTime[i_VictimNum][j] - GetGameTime()
                    if (f_ThisTime < f_TimeLeft)
                        f_TimeLeft = f_ThisTime
                }
            }
            
            new i_Reduction = RoundToNearest((1.0 - f_Reduction) * 100.0)
            
            PrintHintText(i, "Common(%d): -%d%% dmg [%d stacks] (%.0fs)", 
                i_VictimNum + 1, 
                i_Reduction, 
                i_Stacks, 
                f_TimeLeft)
        }
    }
}
stock ShowKillNotification(i_Attacker, i_Victim, i_AttackerNum)
{
    new i_VictimNum = GetCommonNumber(i_Victim)
    
    // ✅ LẤY SỐ STACK HIỆN TẠI (sau khi đã thêm stack mới)
    new i_TotalStacks = g_iKillStacks[i_AttackerNum]
    new Float:f_DmgReduction = float(i_TotalStacks) * g_fStackReduction
    
    // Tìm player gần nhất
    for (new i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i))
            continue
        
        new Float:f_PlayerPos[3], Float:f_AttackerPos[3]
        GetClientAbsOrigin(i, f_PlayerPos)
        GetEntPropVector(i_Attacker, Prop_Send, "m_vecOrigin", f_AttackerPos)
        
        if (GetVectorDistance(f_PlayerPos, f_AttackerPos) <= 500.0)  // [TUNE] Khoảng cách hiện thông báo kill cho player gần (units)
        {
            if (i_VictimNum != -1)
            {
                PrintToChat(i, "\x04[CI Kill] \x03#%d \x05killed \x03#%d \x01→ HP:\x05%d \x01| DMG:\x04-%0.1f%% \x01(\x03%d stacks\x01)", 
                    i_AttackerNum + 1, 
                    i_VictimNum + 1,
                    g_iCommonHP[i_AttackerNum],
                    f_DmgReduction,
                    i_TotalStacks)
            }
            else
            {
                PrintToChat(i, "\x04[CI Kill] \x03#%d \x05killed CI \x01→ HP:\x05%d \x01| DMG:\x04-%0.1f%% \x01(\x03%d stacks\x01)", 
                    i_AttackerNum + 1, 
                    g_iCommonHP[i_AttackerNum],
                    f_DmgReduction,
                    i_TotalStacks)
            }
        }
    }
}

stock GetCommonNumber(i_Entity)
{
    for (new i = 0; i < COMMON_LEN; i++)
    {
        if (g_iCommonID[i] == i_Entity)
            return i
    }
    return -1
}
/* ==================== HINT SYSTEM ==================== */
public Action:DisplayHint(Handle:h_Timer, Handle:h_Pack)
{
    decl i_Client
    ResetPack(h_Pack, false)
    i_Client = ReadPackCell(h_Pack)
    
    if (GetConVarInt(h_CvarMessageType) == 3 && IsClientInGame(i_Client))
        ClientCommand(i_Client, "gameinstructor_enable 1")
        
    CreateTimer(0.3, DelayDisplayHint, h_Pack)
}

public Action:DelayDisplayHint(Handle:h_Timer, Handle:h_Pack)
{
    decl i_Client, String:s_LanguageKey[16], String:s_Message[256], String:s_Bind[10]

    ResetPack(h_Pack, false)
    i_Client = ReadPackCell(h_Pack)
    ReadPackString(h_Pack, s_LanguageKey, sizeof(s_LanguageKey))
    ReadPackString(h_Pack, s_Bind, sizeof(s_Bind))
    CloseHandle(h_Pack)
    
    switch (GetConVarInt(h_CvarMessageType))
    {
        case 1:
        {
            FormatEx(s_Message, sizeof(s_Message), "\x03[%t]\x01 %t.", "Information", s_LanguageKey)
            ReplaceString(s_Message, sizeof(s_Message), "\n", " ")
            PrintToChat(i_Client, s_Message)
        }
        case 2: PrintHintText(i_Client, "%t", s_LanguageKey)
        case 3:
        {
            FormatEx(s_Message, sizeof(s_Message), "%t", s_LanguageKey)
            DisplayInstructorHint(i_Client, s_Message, s_Bind)
        }
    }
}

public DisplayInstructorHint(i_Client, String:s_Message[256], String:s_Bind[])
{
    decl i_Ent, String:s_TargetName[32], Handle:h_RemovePack
    
    i_Ent = CreateEntityByName("env_instructor_hint")
    FormatEx(s_TargetName, sizeof(s_TargetName), "hint%d", i_Client)
    ReplaceString(s_Message, sizeof(s_Message), "\n", " ")
    DispatchKeyValue(i_Client, "targetname", s_TargetName)
    DispatchKeyValue(i_Ent, "hint_target", s_TargetName)
    DispatchKeyValue(i_Ent, "hint_timeout", "5")
    DispatchKeyValue(i_Ent, "hint_range", "0.01")
    DispatchKeyValue(i_Ent, "hint_color", "255 255 255")
    DispatchKeyValue(i_Ent, "hint_icon_onscreen", "use_binding")
    DispatchKeyValue(i_Ent, "hint_caption", s_Message)
    DispatchKeyValue(i_Ent, "hint_binding", s_Bind)
    DispatchSpawn(i_Ent)
    AcceptEntityInput(i_Ent, "ShowHint")
    
    h_RemovePack = CreateDataPack()
    WritePackCell(h_RemovePack, i_Client)
    WritePackCell(h_RemovePack, i_Ent)
    CreateTimer(5.0, RemoveInstructorHint, h_RemovePack)
}
    
public Action:RemoveInstructorHint(Handle:h_Timer, Handle:h_Pack)
{
    decl i_Ent, i_Client
    
    ResetPack(h_Pack, false)
    i_Client = ReadPackCell(h_Pack)
    i_Ent = ReadPackCell(h_Pack)
    CloseHandle(h_Pack)
    
    if (!i_Client || !IsClientInGame(i_Client))
        return Plugin_Handled
    
    if (IsValidEntity(i_Ent))
            RemoveEdict(i_Ent)
    
    ClientCommand(i_Client, "gameinstructor_enable 0")
    DispatchKeyValue(i_Client, "targetname", "")
        
    return Plugin_Continue
}

/* ==================== CHANGE CLASS ==================== */
public Action:ChangeClass(Handle:h_Timer, any:i_Client)
{
    if (IsClientInGame(i_Client))
    {
        decl i_Witch
        i_Witch = g_b_WitchControl[i_Client]
        
        if (!i_Witch || !IsValidEdict(i_Witch))
            return
        
        SetEntProp(i_Client, Prop_Send, "m_fFlags", GetEntityFlags(i_Client) | FL_GODMODE)
        SetEntProp(i_Client, Prop_Data, "m_takedamage", 0, 1)
        SetEntProp(i_Client, Prop_Send, "m_lifeState", 0)
        SetEntProp(i_Client, Prop_Data, "m_iMaxHealth", GetEntProp(i_Witch, Prop_Data, "m_iMaxHealth"))
        SetEntityMoveType(i_Client, MOVETYPE_NONE)
        SetEntityRenderMode(i_Client, RENDER_TRANSCOLOR)
        SetEntityRenderColor(i_Client, 0, 0, 0, 0)
        SetEntProp(i_Client, Prop_Send, "m_fEffects", EF_NODRAW)
        
        // m_isGhost, m_iGlowType, m_glowColorOverride, m_customAbility: infected-only props
        if (GetClientTeam(i_Client) == TEAM_INFECTED)
        {
            SetEntProp(i_Client, Prop_Send, "m_isGhost", 0)
            SDKCall(g_h_SetClass, i_Client, CLASS_NOTINFECTED)
            SetEntProp(i_Client, Prop_Send, "m_iGlowType", 3)
            SetEntProp(i_Client, Prop_Send, "m_glowColorOverride", 1)
            new i_Ability = GetEntProp(i_Client, Prop_Send, "m_customAbility")
            new i_AbilityEnt = MakeCompatEntRef(i_Ability)
            if (i_AbilityEnt != -1 && IsValidEdict(i_AbilityEnt))
                AcceptEntityInput(i_AbilityEnt, "Kill")
        }
        else if (g_b_WasSurvivor[i_Client])
        {
            // Switch sang TEAM_INFECTED → engine nhận ra m_hOwnerEntity là "infected player"
            // → disable CI's NPC AI → TeleportEntity velocity apply được lên CI như infected controller
            SetEntProp(i_Client, Prop_Send, "m_iTeamNum", TEAM_INFECTED)
            SDKCall(g_h_SetClass, i_Client, CLASS_NOTINFECTED)
        }
    }
}
/* ==================== COMMON INFECTED CONTROL - TÁCH PHÍM SHIFT ==================== */
public Action:HandleCommonInfectedControls(i_Client, i_Common, i_Buttons, Float:f_GameTime, i_Sequence, i_Flags, Float:f_PlayerAngles[3])
{
    decl Float:f_Origin[3], Float:f_Angles[3], Float:f_Forward[3], Float:f_Vel[3], Float:f_Speed
    decl bool:b_IsMoving, bool:b_OnGround, i_NewSequence, Float:f_FallDist
    
    b_IsMoving = false
    i_NewSequence = g_i_CommonAnimSequence[i_Client]
    
    GetEntPropVector(i_Common, Prop_Send, "m_vecOrigin", f_Origin)
    GetEntPropVector(i_Common, Prop_Send, "m_angRotation", f_Angles)
    
    // ========== TAB = SWITCH ANIMATION MODE ==========
    if (i_Buttons & IN_SCORE)
    {
        if (f_GameTime - g_f_LastModeSwitch[i_Client] > 0.5)
        {
            g_i_AnimMode[i_Client]++
            if (g_i_AnimMode[i_Client] >= MODE_COUNT)
                g_i_AnimMode[i_Client] = MODE_MOVEMENT
            
            g_i_AnimIndex[i_Client] = 0
            
            if (g_i_AnimMode[i_Client] == MODE_MOVEMENT)
            {
                g_b_InPoseMode[i_Client] = false
                PrintToChat(i_Client, "\x04[Mode] \x03%s", g_ModeNames[g_i_AnimMode[i_Client]])
            }
            else
            {
                g_b_InPoseMode[i_Client] = true
                i_NewSequence = GetSequenceFromMode(g_i_AnimMode[i_Client], 0)
                SetAnimationIfChanged(i_Common, i_Client, i_NewSequence)
                
                new i_MaxCount = GetModeMaxIndex(g_i_AnimMode[i_Client])
                PrintToChat(i_Client, "\x04[Mode] \x03%s \x01(%d poses)", 
                    g_ModeNames[g_i_AnimMode[i_Client]], i_MaxCount)
            }
            g_f_LastModeSwitch[i_Client] = f_GameTime
        }
        
        i_Buttons &= ~IN_SCORE
    }
    
    // ========== RIGHT CLICK (MOUSE2) = CYCLE WALK STYLE ==========
    if (i_Buttons & IN_ATTACK2 && !g_b_InPoseMode[i_Client])
    {
        if (f_GameTime - g_f_LastWalkStyleChange[i_Client] > 0.5)
        {
            g_i_WalkStyleIndex[i_Client]++
            if (g_i_WalkStyleIndex[i_Client] >= WALK_STYLES_COUNT)
                g_i_WalkStyleIndex[i_Client] = 0
            
            PrintToChat(i_Client, "\x04[Walk Style] \x01%s \x03(%d/8)", 
                g_WalkStyleNames[g_i_WalkStyleIndex[i_Client]], 
                g_i_WalkStyleIndex[i_Client] + 1)
            
            g_f_LastWalkStyleChange[i_Client] = f_GameTime
        }
        
        i_Buttons &= ~IN_ATTACK2
    }
    
    // ========== SPACE = NEXT POSE (CHỈ Ở POSE MODE) ==========
    if (i_Buttons & IN_JUMP)
    {
        if (g_b_InPoseMode[i_Client] && f_GameTime - g_PlayerGameTime[i_Client] > 0.3)
        {
            g_i_AnimIndex[i_Client]++
            
            new i_MaxIndex = GetModeMaxIndex(g_i_AnimMode[i_Client])
            if (g_i_AnimIndex[i_Client] >= i_MaxIndex)
                g_i_AnimIndex[i_Client] = 0
            
            i_NewSequence = GetSequenceFromMode(g_i_AnimMode[i_Client], g_i_AnimIndex[i_Client])
            SetAnimationIfChanged(i_Common, i_Client, i_NewSequence)
            
            PrintToChat(i_Client, "\x04[Pose] \x01#%d/%d \x03(Seq %d)", 
                g_i_AnimIndex[i_Client] + 1, i_MaxIndex, i_NewSequence)
            
            g_PlayerGameTime[i_Client] = f_GameTime
            
            f_Vel[0] = 0.0
            f_Vel[1] = 0.0
            f_Vel[2] = 0.0
            TeleportEntity(i_Common, NULL_VECTOR, NULL_VECTOR, f_Vel)
            
            i_Buttons &= ~IN_JUMP
            return Plugin_Continue
        }
    }
    
    // ========== POSE MODE - ROTATION ONLY ==========
    if (g_b_InPoseMode[i_Client])
    {
        if (i_Buttons & (IN_LEFT|IN_MOVELEFT))
        {
            f_Angles[1] += 3.0
            SetEntPropVector(i_Common, Prop_Send, "m_angRotation", f_Angles)
        }
        
        if (i_Buttons & (IN_RIGHT|IN_MOVERIGHT))
        {
            f_Angles[1] -= 3.0
            SetEntPropVector(i_Common, Prop_Send, "m_angRotation", f_Angles)
        }
        
        f_Vel[0] = 0.0
        f_Vel[1] = 0.0
        f_Vel[2] = 0.0
        TeleportEntity(i_Common, NULL_VECTOR, NULL_VECTOR, f_Vel)
        
        return Plugin_Continue
    }
    
    // ========== MOVEMENT MODE BELOW ==========
    
    b_OnGround = (GetEntPropEnt(i_Common, Prop_Data, "m_hGroundEntity") != -1)

    // ========== LADDER (COMMON INFECTED) ==========
    // Dựa theo logic climb ladder của Witch: trace vào "func_simpleladder", nếu đủ gần thì bật mode ladder,
    // sau đó W/S sẽ tăng/giảm Z theo từng tick.
    //
    // Lưu ý: Common không có anim ladder riêng chắc chắn (sequence có thể khác theo model),
    // nên ở đây chỉ ưu tiên di chuyển/leo được; anim sẽ dùng sequence hiện tại hoặc set về idle/walk.
    if (!g_b_InPoseMode[i_Client])
    {
        // Nếu đang on ladder: chỉ xử lý leo lên/xuống và bỏ qua falling/movement thường
        if (g_b_OnLadder[i_Client])
        {
            decl Float:f_TraceOrigin[3], Handle:h_Trace, bool:b_HasLadder
            b_HasLadder = true
            
            // giữ player bám ladder theo mốc Z đã lưu
            if (g_WitchLadderOrigin[i_Client])
                f_Origin[2] = g_WitchLadderOrigin[i_Client]
            
            // tiếp tục trace để biết còn ladder trước mặt không
            f_TraceOrigin[0] = f_Origin[0]
            f_TraceOrigin[1] = f_Origin[1]
            f_TraceOrigin[2] = f_Origin[2] + 2.0
            
            h_Trace = TR_TraceRayFilterEx(f_TraceOrigin, f_Angles, MASK_ALL, RayType_Infinite, TraceFilterClients, i_Common)
            if (TR_DidHit(h_Trace))
            {
                decl i_Target, String:s_ClassName[32], Float:f_EndOrigin[3]
                i_Target = TR_GetEntityIndex(h_Trace)
                TR_GetEndPosition(f_EndOrigin, h_Trace)
                
                if (i_Target && IsValidEdict(i_Target))
                {
                    GetEdictClassname(i_Target, s_ClassName, sizeof(s_ClassName))
                    if (StrEqual(s_ClassName, "func_simpleladder"))
                    {
                        // còn ladder
                        b_HasLadder = true
                    }
                    else
                    {
                        b_HasLadder = false
                    }
                }
                else
                {
                    b_HasLadder = false
                }
            }
            else
            {
                b_HasLadder = false
            }
            CloseHandle(h_Trace)
            
            if (!b_HasLadder)
            {
                // mất ladder -> thoát mode
                g_b_OnLadder[i_Client] = false
                g_WitchLadderOrigin[i_Client] = 0.0
                return Plugin_Continue
            }
            
            // leo lên/xuống bằng W/S
            if (i_Buttons & IN_FORWARD)
            {
                if (!g_WitchLadderOrigin[i_Client])
                    g_WitchLadderOrigin[i_Client] = f_Origin[2]
                
                g_WitchLadderOrigin[i_Client] += 1.2  // [TUNE] Tốc độ leo ladder lên (units/tick) – tăng để leo nhanh hơn
                f_Origin[2] = g_WitchLadderOrigin[i_Client]
                TeleportEntity(i_Common, f_Origin, NULL_VECTOR, Float:{0.0, 0.0, 0.0})
                b_IsMoving = true
            }
            else if (i_Buttons & IN_BACK)
            {
                if (!g_WitchLadderOrigin[i_Client])
                    g_WitchLadderOrigin[i_Client] = f_Origin[2]
                
                g_WitchLadderOrigin[i_Client] -= 1.2  // [TUNE] Tốc độ xuống ladder (units/tick) – tăng để xuống nhanh hơn
                f_Origin[2] = g_WitchLadderOrigin[i_Client]
                TeleportEntity(i_Common, f_Origin, NULL_VECTOR, Float:{0.0, 0.0, 0.0})
                b_IsMoving = true
            }
            else
            {
                // đứng yên trên ladder -> triệt tiêu velocity để khỏi rớt
                f_Vel[0] = 0.0
                f_Vel[1] = 0.0
                f_Vel[2] = 0.0
                TeleportEntity(i_Common, NULL_VECTOR, NULL_VECTOR, f_Vel)
            }
            
            // Trên ladder thì không xử lý falling/jump/attack theo logic thường
            i_NewSequence = (b_IsMoving ? CI_SHAMBLE : CI_IDLE_NEUTRAL)
            SetAnimationIfChanged(i_Common, i_Client, i_NewSequence)
            g_b_IsMoving[i_Client] = b_IsMoving
            return Plugin_Continue
        }
        else
        {
            // Chưa on ladder: nếu W hoặc S thì trace tìm ladder (giống Witch)
            if ((i_Buttons & IN_FORWARD) || (i_Buttons & IN_BACK))
            {
                decl Float:f_TraceOrigin2[3], Handle:h_Trace2
                decl Float:f_EndOrigin2[3], String:s_ClassName2[32], i_Target2
                
                f_TraceOrigin2[0] = f_Origin[0]
                f_TraceOrigin2[1] = f_Origin[1]
                f_TraceOrigin2[2] = f_Origin[2] + 20.0
                
                // throttle trace để đỡ nặng
                if (!g_PlayerTraceTimer[i_Client] || (f_GameTime - g_PlayerTraceTimer[i_Client] >= 0.5))
                {
                    h_Trace2 = TR_TraceRayFilterEx(f_TraceOrigin2, f_Angles, MASK_ALL, RayType_Infinite, TraceFilterClients, i_Common)
                    g_PlayerTraceTimer[i_Client] = f_GameTime
                    
                    if (TR_DidHit(h_Trace2))
                    {
                        i_Target2 = TR_GetEntityIndex(h_Trace2)
                        TR_GetEndPosition(f_EndOrigin2, h_Trace2)
                        
                        if (i_Target2 && IsValidEdict(i_Target2))
                        {
                            GetEdictClassname(i_Target2, s_ClassName2, sizeof(s_ClassName2))
                            if (StrEqual(s_ClassName2, "func_simpleladder"))
                            {
                                // đủ gần ladder -> bật mode ladder
                                if (GetVectorDistance(f_Origin, f_EndOrigin2) <= 25.0)  // [TUNE] Khoảng cách tối đa để bắt đầu bám ladder (units)
                                {
                                    g_b_OnLadder[i_Client] = true
                                    if (!g_WitchLadderOrigin[i_Client])
                                        g_WitchLadderOrigin[i_Client] = f_Origin[2] + 15.0
                                }
                            }
                        }
                    }
                    
                    CloseHandle(h_Trace2)
                }
            }
        }
    }
    
    // ✅ NẾU ĐANG Ở CHẾ ĐỘ JUMP WITCH-STYLE → BỎ QUA XỬ LÝ FALLING THÔNG THƯỜNG
    if (g_b_WitchJump[i_Client] > 0.0)
    {
        // Đang trong quá trình jump, để OnGameFrame xử lý
        return Plugin_Continue
    }
    
    // Falling detection (CHỈ KHI KHÔNG DÙNG WITCH JUMP)
    if (!b_OnGround && !g_b_IsFalling[i_Client])
    {
        g_b_IsFalling[i_Client] = true
        g_f_LastGroundZ[i_Client] = f_Origin[2]
        i_NewSequence = CI_FALL
    }
    else if (b_OnGround && g_b_IsFalling[i_Client])
    {
        g_b_IsFalling[i_Client] = false
        f_FallDist = g_f_LastGroundZ[i_Client] - f_Origin[2]
        
        if (f_FallDist > 100.0)  // [TUNE] Ngưỡng rơi nặng (units) – landing stun 0.8s
        {
            i_NewSequence = CI_LAND_HARD
            g_f_LandingTime[i_Client] = f_GameTime + 0.8  // [TUNE] Thời gian stun khi rơi nặng (giây)
        }
        else if (f_FallDist > 30.0)  // [TUNE] Ngưỡng rơi nhẹ (units) – landing stun 0.4s
        {
            i_NewSequence = CI_LAND_NEUTRAL
            g_f_LandingTime[i_Client] = f_GameTime + 0.4  // [TUNE] Thời gian stun khi rơi nhẹ (giây)
        }
        else
        {
            i_NewSequence = CI_IDLE_NEUTRAL
        }
        
        g_f_LastGroundZ[i_Client] = f_Origin[2]
    }
    
    // Landing stun
    if (g_f_LandingTime[i_Client] > f_GameTime)
    {
        SetAnimationIfChanged(i_Common, i_Client, i_NewSequence)
        GetEntPropVector(i_Common, Prop_Data, "m_vecVelocity", f_Vel)
        f_Vel[0] *= 0.5
        f_Vel[1] *= 0.5
        TeleportEntity(i_Common, NULL_VECTOR, NULL_VECTOR, f_Vel)
        return Plugin_Continue
    }
    
    if (g_b_IsFalling[i_Client])
    {
        SetAnimationIfChanged(i_Common, i_Client, CI_FALL)
        return Plugin_Continue
    }
    
                // Attack
    if (i_Buttons & IN_ATTACK && GetConVarInt(h_CvarAttack) && !g_b_InPoseMode[i_Client])
    {
        if (f_GameTime - g_f_LastAttackPress[i_Client] > 0.8)  // [TUNE] Cooldown tấn công (giây) – giảm để đánh nhanh hơn
        {
            g_b_IsAttacking[i_Client] = true
            i_NewSequence = CI_ATTACK
            SetAnimationIfChanged(i_Common, i_Client, i_NewSequence)
            
            // 🔥 GÂY DAMAGE NGAY
            DamageNearbyEntities(i_Client, i_Common, 60.0, 4)  // [TUNE] 60.0=bán kính tấn công (units), 4=damage mỗi hit
            
            g_f_LastAttackPress[i_Client] = f_GameTime
            g_h_AttackTimer[i_Client] = CreateTimer(0.6, ResetAttack, i_Client)
        }
    }
    
    // Rotation
    if (i_Buttons & (IN_LEFT|IN_MOVELEFT))
    {
        f_Angles[1] += 3.0
        SetEntPropVector(i_Common, Prop_Send, "m_angRotation", f_Angles)
        b_IsMoving = true
    }
    
    if (i_Buttons & (IN_RIGHT|IN_MOVERIGHT))
    {
        f_Angles[1] -= 3.0
        SetEntPropVector(i_Common, Prop_Send, "m_angRotation", f_Angles)
        b_IsMoving = true
    }
    
    GetEntPropVector(i_Common, Prop_Send, "m_angRotation", f_Angles)
    
    // Movement
    f_Speed = GetConVarFloat(h_CvarCommonSpeed)
    
    if (i_Buttons & IN_FORWARD)
    {
        GetAngleVectors(f_Angles, f_Forward, NULL_VECTOR, NULL_VECTOR)
        NormalizeVector(f_Forward, f_Forward)
        
        if (i_Buttons & IN_SPEED)
        {
            ScaleVector(f_Forward, f_Speed * 200.0)  // [TUNE] Tốc độ chạy (SHIFT+W) – nhân với l4d2_common_speed
            i_NewSequence = CI_RUN_INTENSE
// ✅ FIX: đẩy blend tree về hướng N (chạy thẳng)
        SetEntPropFloat(i_Common, Prop_Send, "m_flPoseParameter", 0.5, 2)
        SetEntPropFloat(i_Common, Prop_Send, "m_flPoseParameter", 1.0, 3)
        }
        else
        {
            ScaleVector(f_Forward, f_Speed * 80.0)  // [TUNE] Tốc độ đi bộ (W không SHIFT) – nhân với l4d2_common_speed
            i_NewSequence = g_WalkStyles[g_i_WalkStyleIndex[i_Client]]
        }
        
        f_Vel[0] = f_Forward[0]
        f_Vel[1] = f_Forward[1]
        
        TeleportEntity(i_Common, NULL_VECTOR, NULL_VECTOR, f_Vel)
        
        // ✅ AUTO VAULT / STEP-UP: tự leo qua vật cản thấp/vừa khi đi thẳng vào
        if (b_OnGround && !g_b_IsAttacking[i_Client] &&
            f_GameTime - g_f_VaultCooldown[i_Client] >= VAULT_COOLDOWN)
        {
            if (TryVaultObstacle(i_Client, i_Common, f_Origin, f_Angles))
            {
                g_f_VaultCooldown[i_Client] = f_GameTime
                i_NewSequence = CI_JUMP
            }
        }
        
        b_IsMoving = true

        // ✅ Hold-to-walk: giữ W thì animation phải chạy liên tục, không bị pause cuối vòng
        // Một số sequence của infected có thể tự "khựng" khi cycle chạm 1.0, nên wrap lại.
        SetEntPropFloat(i_Common, Prop_Send, "m_flPlaybackRate", 1.0)
        new Float:f_Cycle = GetEntPropFloat(i_Common, Prop_Send, "m_flCycle")
        if (f_Cycle >= 0.99)
            SetEntPropFloat(i_Common, Prop_Send, "m_flCycle", 0.0)
    }
    else if (i_Buttons & IN_BACK)
    {
        GetAngleVectors(f_Angles, f_Forward, NULL_VECTOR, NULL_VECTOR)
        NormalizeVector(f_Forward, f_Forward)
        ScaleVector(f_Forward, -f_Speed * 60.0)  // [TUNE] Tốc độ lùi (S) – nhân với l4d2_common_speed
        
        f_Vel[0] = f_Forward[0]
        f_Vel[1] = f_Forward[1]
        
        TeleportEntity(i_Common, NULL_VECTOR, NULL_VECTOR, f_Vel)
        i_NewSequence = CI_SHAMBLE
        b_IsMoving = true

        // ✅ giữ S thì cũng tránh pause
        SetEntPropFloat(i_Common, Prop_Send, "m_flPlaybackRate", 1.0)
        new Float:f_CycleBack = GetEntPropFloat(i_Common, Prop_Send, "m_flCycle")
        if (f_CycleBack >= 0.99)
            SetEntPropFloat(i_Common, Prop_Send, "m_flCycle", 0.0)
    }
    else if (!g_b_IsAttacking[i_Client])
    {
        f_Vel[0] = 0.0
        f_Vel[1] = 0.0
        f_Vel[2] = 0.0
        TeleportEntity(i_Common, NULL_VECTOR, NULL_VECTOR, f_Vel)
        i_NewSequence = CI_IDLE_NEUTRAL
 // ✅ Reset pose parameters về 0
    SetEntPropFloat(i_Common, Prop_Send, "m_flPoseParameter", 0.0, 2)
    SetEntPropFloat(i_Common, Prop_Send, "m_flPoseParameter", 0.0, 3)
    }
    
    // ✅ JUMP MỚI - WITCH-STYLE (CHỈ Ở MOVEMENT MODE)
    if (i_Buttons & IN_JUMP && b_OnGround && !g_b_IsFalling[i_Client])
    {
        // Kích hoạt jump với cooldown
        if (f_GameTime - g_PlayerGameTime[i_Client] > 1.5)  // [TUNE] Cooldown nhảy (giây) – tăng nếu không muốn spam nhảy
        {
            g_b_WitchJump[i_Client] = 2.0  // [TUNE] Lực nhảy ban đầu – tăng để nhảy cao hơn/xa hơn
            g_PlayerGameTime[i_Client] = f_GameTime
            i_NewSequence = CI_JUMP
            b_IsMoving = true
            
            // Phát âm thanh nhảy (optional)
            EmitSoundToAll("player/jumplanding.wav", i_Common, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5)
        }
    }
    
    // Idle
    if (!b_IsMoving && !g_b_IsAttacking[i_Client])
    {
        GetEntPropVector(i_Common, Prop_Data, "m_vecVelocity", f_Vel)
        
        if (GetVectorLength(f_Vel) < 10.0)
        {
            i_NewSequence = CI_IDLE_NEUTRAL
        }
    }
    
    SetAnimationIfChanged(i_Common, i_Client, i_NewSequence)
    g_b_IsMoving[i_Client] = b_IsMoving
    
    // ✅ PROXIMITY SHOVE: khi đang chạy (SHIFT + move) thì đẩy CI xung quanh ra
    // Không dùng m_mobRush (gây uncontrolled AI) - tự apply velocity thủ công
    if (b_IsMoving && (i_Buttons & IN_SPEED))
{
    if (f_GameTime - g_f_LastShoveTime[i_Client] >= 0.15)  // [TUNE] Cooldown đẩy CI xung quanh khi sprint (giây) – tăng để đỡ spam
    {
        ShoveNearbyCommon(i_Client, i_Common)
        g_f_LastShoveTime[i_Client] = f_GameTime
    }
}
    // ✅ Sync player theo CI ngay cùng frame — tránh race condition với timer
    decl Float:f_SyncOrigin[3]
    GetEntPropVector(i_Common, Prop_Send, "m_vecOrigin", f_SyncOrigin)
    f_SyncOrigin[2] += 10.0
    TeleportEntity(i_Client, f_SyncOrigin, NULL_VECTOR, NULL_VECTOR)
    SetEntProp(i_Common, Prop_Send, "m_mobRush", 0)
    return Plugin_Continue
}
/* ==================== SHOVE NEARBY COMMON INFECTED ==================== */
// NPC (infected) ignore velocity hoàn toàn → phải teleport thẳng POSITION ra ngoài.
// Mỗi frame khi đang chạy (SHIFT+move), CI xung quanh trong bán kính 55u bị đẩy ra.
public ShoveNearbyCommon(i_Client, i_Common)
{
    if (!IsValidEdict(i_Common))
        return
    
    decl Float:f_Origin[3], Float:f_TargetOrigin[3], Float:f_NewPos[3], Float:f_Dir[3], Float:f_Dist
    decl i_Entity, String:s_ClassName[32]
    
    GetEntPropVector(i_Common, Prop_Send, "m_vecOrigin", f_Origin)
    
    for (i_Entity = MaxClients + 1; i_Entity <= GetMaxEntities(); i_Entity++)
    {
        if (i_Entity == i_Common)
            continue
        
        if (!IsValidEdict(i_Entity) || !IsValidEntity(i_Entity))
            continue
        
        GetEdictClassname(i_Entity, s_ClassName, sizeof(s_ClassName))
        if (!StrEqual(s_ClassName, "infected"))
            continue
        
        // Bỏ qua CI đang được ai đó control
        new i_CommonNum = GetCommonNumber(i_Entity)
        if (i_CommonNum != -1 && g_iCommonOwner[i_CommonNum] != -1)
            continue
        
        GetEntPropVector(i_Entity, Prop_Send, "m_vecOrigin", f_TargetOrigin)
        f_Dist = GetVectorDistance(f_Origin, f_TargetOrigin)
        
        if (f_Dist < 55.0 && f_Dist > 0.1)  // [TUNE] 55.0=bán kính đẩy CI bot xung quanh khi sprint (units)
        {
            // Hướng đẩy ra ngoài
            f_Dir[0] = f_TargetOrigin[0] - f_Origin[0]
            f_Dir[1] = f_TargetOrigin[1] - f_Origin[1]
            f_Dir[2] = 0.0
            NormalizeVector(f_Dir, f_Dir)
            
            // Đẩy position ra đủ xa để thoát khỏi radius (55 - dist + 5 buffer)
            new Float:f_PushDist = (55.0 - f_Dist) + 5.0
            
            f_NewPos[0] = f_TargetOrigin[0] + f_Dir[0] * f_PushDist
            f_NewPos[1] = f_TargetOrigin[1] + f_Dir[1] * f_PushDist
            f_NewPos[2] = f_TargetOrigin[2]  // giữ nguyên Z để không bay
            
            // Teleport position (không velocity) — cách duy nhất work với NPC
            TeleportEntity(i_Entity, f_NewPos, NULL_VECTOR, NULL_VECTOR)
            
            // Trigger stagger animation cho con bị đẩy
            SetEntProp(i_Entity, Prop_Data, "m_nSequence", 131)  // stagger back
        }
    }
}
public Action:UnfreezeCommon(Handle:h_Timer, any:i_Client)
{
    if (!IsClientInGame(i_Client))
        return Plugin_Handled
    
    new i_Common = g_b_WitchControl[i_Client]
    if (IsValidEdict(i_Common) && g_i_EntityType[i_Client] == ENTITY_COMMON && i_Common > 0)
    {
        new i_LifeState = GetEntProp(i_Common, Prop_Data, "m_lifeState")
        if (i_LifeState == 0)  // 0 = alive
            SetEntProp(i_Common, Prop_Send, "m_fFlags", GetEntityFlags(i_Common) & ~FL_FROZEN)
    }
    
    return Plugin_Handled
}

/* ==================== AUTO VAULT / STEP-UP SYSTEM ==================== */
// Phát hiện vật cản phía trước bằng 3 tầng raycast:
//   Tầng 1 (shin 15u)   → có gì chặn không?
//   Tầng 2 (step  45u)  → vật cản thấp → step up
//   Tầng 3 (vault 85u)  → vật cản vừa (xe) → vault cao
// Nếu tầng nào clear → teleport CI lên tầng đó + push forward nhẹ.
public bool:TryVaultObstacle(i_Client, i_Common, Float:f_Origin[3], Float:f_Angles[3])
{
    decl Float:f_FwdDir[3]
    decl Float:f_TStart[3], Float:f_TEnd[3]
    decl Handle:h_Tr
    
    GetAngleVectors(f_Angles, f_FwdDir, NULL_VECTOR, NULL_VECTOR)
    NormalizeVector(f_FwdDir, f_FwdDir)
    
    // ── Tầng 1: shin level – kiểm tra có vật cản trước mặt không ──
    f_TStart[0] = f_Origin[0]
    f_TStart[1] = f_Origin[1]
    f_TStart[2] = f_Origin[2] + 15.0
    f_TEnd[0]   = f_Origin[0] + f_FwdDir[0] * VAULT_DETECT_DIST
    f_TEnd[1]   = f_Origin[1] + f_FwdDir[1] * VAULT_DETECT_DIST
    f_TEnd[2]   = f_TStart[2]
    
    h_Tr = TR_TraceRayFilterEx(f_TStart, f_TEnd, MASK_SOLID, RayType_EndPoint, TraceFilterWorldOnly, i_Common)
    new bool:b_LowHit = TR_DidHit(h_Tr)
    CloseHandle(h_Tr)
    
    if (!b_LowHit)
        return false  // Đường trước rộng → không cần vault
    
    // ── Tầng 2: step height – vật cản thấp (bậc thang, vỉa hè)? ──
    f_TStart[2] = f_Origin[2] + VAULT_STEP_HEIGHT
    f_TEnd[2]   = f_TStart[2]
    
    h_Tr = TR_TraceRayFilterEx(f_TStart, f_TEnd, MASK_SOLID, RayType_EndPoint, TraceFilterWorldOnly, i_Common)
    new bool:b_StepHit = TR_DidHit(h_Tr)
    CloseHandle(h_Tr)
    
    if (!b_StepHit)
    {
        // Vật cản thấp → step lên + đẩy forward nhẹ
        decl Float:f_NewPos[3]
        f_NewPos[0] = f_Origin[0] + f_FwdDir[0] * 20.0
        f_NewPos[1] = f_Origin[1] + f_FwdDir[1] * 20.0
        f_NewPos[2] = f_Origin[2] + VAULT_STEP_HEIGHT
        TeleportEntity(i_Common, f_NewPos, NULL_VECTOR, NULL_VECTOR)
        return true
    }
    
    // ── Tầng 3: vault height – vật cản vừa (xe, thùng)? ──
    f_TStart[2] = f_Origin[2] + VAULT_HIGH_HEIGHT
    f_TEnd[2]   = f_TStart[2]
    
    h_Tr = TR_TraceRayFilterEx(f_TStart, f_TEnd, MASK_SOLID, RayType_EndPoint, TraceFilterWorldOnly, i_Common)
    new bool:b_HighHit = TR_DidHit(h_Tr)
    CloseHandle(h_Tr)
    
    if (!b_HighHit)
    {
        // Vật cản vừa → vault lên cao + push forward
        decl Float:f_NewPos[3]
        f_NewPos[0] = f_Origin[0] + f_FwdDir[0] * 20.0
        f_NewPos[1] = f_Origin[1] + f_FwdDir[1] * 20.0
        f_NewPos[2] = f_Origin[2] + VAULT_HIGH_HEIGHT
        TeleportEntity(i_Common, f_NewPos, NULL_VECTOR, NULL_VECTOR)
        return true
    }
    
    return false  // Vật cản quá cao → không vault được
}
/* ==================== ATTACK DAMAGE SYSTEM ==================== */

public DamageNearbyEntities(i_Client, i_Common, Float:f_Radius, i_Damage)
{
    decl Float:f_Origin[3], Float:f_TargetOrigin[3], Float:f_Distance
    decl i_Entity, i_Health, i_Count = 0, String:s_ClassName[64]
    
    if (!IsValidEdict(i_Common))
        return 0
    
    GetEntPropVector(i_Common, Prop_Send, "m_vecOrigin", f_Origin)
    
    for (i_Entity = 1; i_Entity <= GetMaxEntities(); i_Entity++)
    {
        if (!IsValidEntity(i_Entity) || i_Entity == i_Common)
            continue
        
        GetEntityClassname(i_Entity, s_ClassName, sizeof(s_ClassName))
        
        // SURVIVORS
        if (i_Entity <= MaxClients)
        {
            if (!IsClientInGame(i_Entity) || !IsPlayerAlive(i_Entity))
                continue
            if (GetClientTeam(i_Entity) != 2)
                continue
            // Survivor controller: skip teammates
            if (g_b_WasSurvivor[i_Client])
                continue
            
            i_Health = GetClientHealth(i_Entity)
        }
        // INFECTED & SPECIAL
        else if (StrEqual(s_ClassName, "infected") || 
                 StrEqual(s_ClassName, "witch") || 
                 StrEqual(s_ClassName, "tank_player") ||
                 StrContains(s_ClassName, "common") != -1)
        {
            i_Health = GetEntProp(i_Entity, Prop_Data, "m_iHealth")
            if (i_Health <= 0)
                continue
        }
        else
        {
            continue
        }
        
        GetEntPropVector(i_Entity, Prop_Send, "m_vecOrigin", f_TargetOrigin)
        f_Distance = GetVectorDistance(f_Origin, f_TargetOrigin)
        
        if (f_Distance <= f_Radius && i_Health > 0)
        {
            // ✅ CHECK NẾU GIẾT CHẾT
            new bool:b_WillKill = (i_Health <= i_Damage)
            
            SDKHooks_TakeDamage(i_Entity, i_Common, i_Common, float(i_Damage), DMG_SLASH)
            i_Count++
            
            if (i_Entity <= MaxClients)
            {
                PrintToChat(i_Client, "\x04[Attack] \x01Hit: \x03%N \x01| \x05%d HP", i_Entity, i_Health - i_Damage)
                
                // ✅ CỘNG MÁU KHI GIẾT PLAYER
                if (b_WillKill)
                {
                    new i_CurrentHealth = GetEntProp(i_Common, Prop_Data, "m_iHealth")
                    new i_NewHealth = i_CurrentHealth + g_i_KillReward
                    if (i_NewHealth > g_i_MaxHealth) i_NewHealth = g_i_MaxHealth
                    
                    SetEntProp(i_Common, Prop_Data, "m_iHealth", i_NewHealth)
                    PrintToChat(i_Client, "\x04[KILL!] \x03%N \x01→ +\x05%d HP \x01(\x03%d\x01/\x03%d\x01)", 
                        i_Entity, g_i_KillReward, i_NewHealth, g_i_MaxHealth)
                }
            }
            else
            {
                PrintToChat(i_Client, "\x04[Attack] \x01Hit: \x03%s \x01| \x05%d HP", s_ClassName, i_Health - i_Damage)
                
                // ✅ CỘNG MÁU KHI GIẾT INFECTED
                if (b_WillKill && StrEqual(s_ClassName, "infected"))
                {
                    new i_CurrentHealth = GetEntProp(i_Common, Prop_Data, "m_iHealth")
                    new i_NewHealth = i_CurrentHealth + g_i_KillReward
                    if (i_NewHealth > g_i_MaxHealth) i_NewHealth = g_i_MaxHealth
                    
                    SetEntProp(i_Common, Prop_Data, "m_iHealth", i_NewHealth)
                    PrintToChat(i_Client, "\x04[KILL!] \x01Infected → +\x05%d HP \x01(\x03%d\x01/\x03%d\x01)", 
                        g_i_KillReward, i_NewHealth, g_i_MaxHealth)
                }
            }
        }
    }
    
    return i_Count
}

public Action:ResetAttack(Handle:h_Timer, any:i_Client)
{
    if (g_b_WitchControl[i_Client] && IsClientInGame(i_Client))
    {
        g_b_IsAttacking[i_Client] = false
        g_h_AttackTimer[i_Client] = INVALID_HANDLE
    }
    return Plugin_Handled
}
/* ==================== HELPER FUNCTIONS ==================== */
public GetModeMaxIndex(i_Mode)
{
    new i_Result = 1
    
    switch (i_Mode)
    {
        case MODE_IDLE: i_Result = IDLE_POSES_COUNT
        case MODE_SITTING: i_Result = SITTING_POSES_COUNT
        case MODE_LYING: i_Result = LYING_POSES_COUNT
        case MODE_LEANING: i_Result = LEANING_POSES_COUNT
        case MODE_SPECIAL: i_Result = SPECIAL_POSES_COUNT
        case MODE_ATTACK: i_Result = ATTACK_POSES_COUNT
        case MODE_CLIMBING: i_Result = CLIMBING_POSES_COUNT
        case MODE_STAGGER: i_Result = STAGGER_POSES_COUNT
        case MODE_JUMP: i_Result = JUMP_POSES_COUNT
        case MODE_FALL: i_Result = FALL_POSES_COUNT
        case MODE_DEATH: i_Result = DEATH_POSES_COUNT
        case MODE_MISC: i_Result = MISC_POSES_COUNT
    }
    
    return i_Result
}

public GetSequenceFromMode(i_Mode, i_Index)
{
    new i_Result = CI_IDLE_NEUTRAL
    
    switch (i_Mode)
    {
        case MODE_IDLE:
        {
            if (i_Index >= 0 && i_Index < IDLE_POSES_COUNT)
                i_Result = g_IdlePoses[i_Index]
        }
        case MODE_SITTING:
        {
            if (i_Index >= 0 && i_Index < SITTING_POSES_COUNT)
                i_Result = g_SittingPoses[i_Index]
        }
        case MODE_LYING:
        {
            if (i_Index >= 0 && i_Index < LYING_POSES_COUNT)
                i_Result = g_LyingPoses[i_Index]
        }
        case MODE_LEANING:
        {
            if (i_Index >= 0 && i_Index < LEANING_POSES_COUNT)
                i_Result = g_LeaningPoses[i_Index]
        }
        case MODE_SPECIAL:
        {
            if (i_Index >= 0 && i_Index < SPECIAL_POSES_COUNT)
                i_Result = g_SpecialPoses[i_Index]
        }
        case MODE_ATTACK:
        {
            if (i_Index >= 0 && i_Index < ATTACK_POSES_COUNT)
                i_Result = g_AttackPoses[i_Index]
        }
        case MODE_CLIMBING:
        {
            if (i_Index >= 0 && i_Index < CLIMBING_POSES_COUNT)
                i_Result = g_ClimbingPoses[i_Index]
        }
        case MODE_STAGGER:
        {
            if (i_Index >= 0 && i_Index < STAGGER_POSES_COUNT)
                i_Result = g_StaggerPoses[i_Index]
        }
        case MODE_JUMP:
        {
            if (i_Index >= 0 && i_Index < JUMP_POSES_COUNT)
                i_Result = g_JumpPoses[i_Index]
        }
        case MODE_FALL:
        {
            if (i_Index >= 0 && i_Index < FALL_POSES_COUNT)
                i_Result = g_FallPoses[i_Index]
        }
        case MODE_DEATH:
        {
            if (i_Index >= 0 && i_Index < DEATH_POSES_COUNT)
                i_Result = g_DeathPoses[i_Index]
        }
        case MODE_MISC:
        {
            if (i_Index >= 0 && i_Index < MISC_POSES_COUNT)
                i_Result = g_MiscPoses[i_Index]
        }
    }
    
    return i_Result
}

public SetAnimationIfChanged(i_Entity, i_Client, i_NewSequence)
{
// ✅ Phát hiện engine inject sequence lạ → force lại sequence của mình
    new i_CurrentSeq = GetEntProp(i_Entity, Prop_Data, "m_nSequence")
    if (i_CurrentSeq != g_i_CommonAnimSequence[i_Client] && g_i_CommonAnimSequence[i_Client] != -1)
    {
        // Engine đã override (flinch, burn, v.v.) → set lại ngay
        SetEntProp(i_Entity, Prop_Data, "m_nSequence", g_i_CommonAnimSequence[i_Client])
        new i_Parity = (GetEntProp(i_Entity, Prop_Send, "m_nNewSequenceParity") + 1) & 15
        SetEntProp(i_Entity, Prop_Send, "m_nNewSequenceParity", i_Parity)
    }
    if (i_NewSequence < 0 || i_NewSequence > 445)
    {
        LogError("[CI Control] Invalid sequence %d - clamping", i_NewSequence)
        i_NewSequence = CI_IDLE_NEUTRAL
    }

    if (g_i_CommonAnimSequence[i_Client] != i_NewSequence)
    {
        SetEntProp(i_Entity, Prop_Data, "m_nSequence", i_NewSequence)
        SetEntProp(i_Entity, Prop_Data, "m_bSequenceLoops", 1)
// ✅ BẮT BUỘC CLIENT NHẬN SEQUENCE MỚI — không có 2 dòng này client sẽ bỏ qua đổi sequence
        new i_Parity = (GetEntProp(i_Entity, Prop_Send, "m_nNewSequenceParity") + 1) & 15
        SetEntProp(i_Entity, Prop_Send, "m_nNewSequenceParity", i_Parity)
        g_i_CommonAnimSequence[i_Client] = i_NewSequence
    }
}

/* ==================== ATTACK SYSTEM ==================== */
public CommonAttack(i_Client, i_Common)
{
    decl Float:f_Origin[3], Float:f_Angles[3], Float:f_Forward[3], Float:f_End[3], Handle:h_Trace
    
    GetEntPropVector(i_Common, Prop_Send, "m_vecOrigin", f_Origin)
    GetEntPropVector(i_Common, Prop_Send, "m_angRotation", f_Angles)
    
    GetAngleVectors(f_Angles, f_Forward, NULL_VECTOR, NULL_VECTOR)
    NormalizeVector(f_Forward, f_Forward)
    
    decl Float:f_LungeVel[3]
    f_LungeVel[0] = f_Forward[0] * 400.0  // [TUNE] Lực lao người khi đánh (LMB) – tăng để lao xa hơn
    f_LungeVel[1] = f_Forward[1] * 400.0
    f_LungeVel[2] = 0.0
    
    TeleportEntity(i_Common, NULL_VECTOR, NULL_VECTOR, f_LungeVel)
    
    SetEntPropFloat(i_Common, Prop_Send, "m_flPlaybackRate", 2.0)
    CreateTimer(0.3, ResetPlaybackRate, i_Client)
    
    EmitSoundToAll("player/pz/hit/zombie_slice_1.wav", i_Common, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.8)
    
    f_Origin[2] += 50.0
    GetAngleVectors(f_Angles, f_Forward, NULL_VECTOR, NULL_VECTOR)
    NormalizeVector(f_Forward, f_Forward)
    ScaleVector(f_Forward, 70.0)  // [TUNE] Tầm đánh trace (units) – khoảng cách hit khi LMB
    AddVectors(f_Origin, f_Forward, f_End)
    
    h_Trace = TR_TraceRayFilterEx(f_Origin, f_End, MASK_SHOT, RayType_EndPoint, TraceFilterNotSelf, i_Common)
    
    if (TR_DidHit(h_Trace))
    {
        decl i_HitEntity = TR_GetEntityIndex(h_Trace)
        
        if (i_HitEntity > 0 && i_HitEntity <= MaxClients && IsClientInGame(i_HitEntity))
        {
            decl i_Team = GetClientTeam(i_HitEntity)
            new bool:b_ControllerIsSurvivor = g_b_WasSurvivor[i_Client]
            
            if (i_Team == 2)
            {
                // Survivor controller: no friendly fire against own team
                if (b_ControllerIsSurvivor)
                {
                    PrintToChat(i_Client, "\x04[Attack] \x01Can't attack teammates!")
                }
                else
                {
                    SDKHooks_TakeDamage(i_HitEntity, i_Common, i_Client, 20.0, DMG_SLASH)  // [TUNE] Damage đánh trực tiếp vào survivor
                    PrintToChat(i_Client, "\x04[Attack] \x01Hit %N for 20 damage!", i_HitEntity)
                }
            }
            else if (i_Team == 3 && i_HitEntity != i_Client)
            {
                SDKHooks_TakeDamage(i_HitEntity, i_Common, i_Client, 15.0, DMG_SLASH)  // [TUNE] Damage friendly-fire đánh vào infected khác
                PrintToChat(i_Client, "\x04[Attack] \x01Hit infected %N!", i_HitEntity)
            }
        }
    }
    
    CloseHandle(h_Trace)
    g_h_AttackTimer[i_Client] = CreateTimer(1.2, ResetAttackTimer, i_Client)  // [TUNE] Cooldown sau khi đánh LMB (giây)
}

public Action:ResetPlaybackRate(Handle:h_Timer, any:i_Client)
{
    if (IsClientInGame(i_Client) && g_b_WitchControl[i_Client] && g_i_EntityType[i_Client] == ENTITY_COMMON)
    {
        new i_Common = g_b_WitchControl[i_Client]
        if (IsValidEdict(i_Common))
        {
            SetEntPropFloat(i_Common, Prop_Send, "m_flPlaybackRate", 1.0)
        }
    }
    return Plugin_Continue
}

public bool:TraceFilterNotSelf(i_Entity, i_Mask, any:i_Data)
{
    if (i_Entity == i_Data)
        return false
    return true
}

public Action:ResetAttackTimer(Handle:h_Timer, any:i_Client)
{
    g_h_AttackTimer[i_Client] = INVALID_HANDLE
    return Plugin_Continue
}
/* ==================== EVENTS ==================== */
public Action:EventRoundEnd(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
    for (new i_Client = 1; i_Client <= MaxClients; i_Client++)
        if (IsClientInGame(i_Client) && !IsFakeClient(i_Client) && 
            (GetClientTeam(i_Client) == TEAM_INFECTED || GetClientTeam(i_Client) == TEAM_SURVIVOR))
        {
            decl i_Witch
            i_Witch = g_b_WitchControl[i_Client]
            if (i_Witch)
                RemoveWitchControl(i_Client, i_Witch)
        }
}

public Action:EventTankSpawn(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
    decl i_UserID, i_Client, i_Witch, String:s_ClassName[16]
    
    i_UserID = GetEventInt(h_Event, "userid")
    i_Client = GetClientOfUserId(i_UserID)
    
    if (IsClientInGame(i_Client))
    {
        i_Witch = g_b_WitchControl[i_Client]
        GetEdictClassname(i_Client, s_ClassName, sizeof(s_ClassName))
        
        if (StrEqual(s_ClassName, "player") && i_Witch && IsValidEdict(i_Witch))
            RemoveWitchControl(i_Client, i_Witch)
    }
}

public Action:EventWitchSpawn(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
    decl i_Witch, Handle:h_Pack
    
    i_Witch = GetEventInt(h_Event, "witchid")
    
    if (IsValidEdict(i_Witch))
        SetEntProp(i_Witch, Prop_Send, "m_fFlags", GetEntityFlags(i_Witch) | FL_DUCKING)
        
    for (new i_Client = 1; i_Client <= MaxClients; i_Client++)
        if (IsClientInGame(i_Client) && !IsFakeClient(i_Client) && 
            (GetClientTeam(i_Client) == TEAM_INFECTED || 
             (GetConVarBool(h_CvarSurvivorControl) && GetClientTeam(i_Client) == TEAM_SURVIVOR)))
        {
            if (GetConVarInt(h_CvarMessageType) == 3)
                ClientCommand(i_Client, "gameinstructor_enable 1")
                
            h_Pack = CreateDataPack()
            WritePackCell(h_Pack, i_Client)
            WritePackString(h_Pack, "Take witch")
            WritePackString(h_Pack, "+use")
            CreateTimer(0.1, DisplayHint, h_Pack)
        }
}

/* ==================== MAIN CONTROL LOGIC ==================== */
public Action:OnPlayerRunCmd(i_Client, &i_Buttons, &i_Impulse, Float:f_PlayerVelocity[3], Float:f_PlayerAngles[3], &i_Weapon)
{
    if (IsFakeClient(i_Client))
        return Plugin_Continue
        
    // Take control logic
    if (!g_b_WitchControl[i_Client])
    {
        new i_ClientTeam = GetClientTeam(i_Client)
        new bool:b_IsSurvivor = (i_ClientTeam == TEAM_SURVIVOR)
        new bool:b_IsInfected = (i_ClientTeam == TEAM_INFECTED)
        
        // Survivor control: only when cvar enabled
        if (b_IsSurvivor && !GetConVarBool(h_CvarSurvivorControl))
            return Plugin_Continue
        
        if (i_Buttons & IN_USE && (b_IsInfected || b_IsSurvivor))
        {
            // Infected: skip tanks. Survivor: just check alive
            new bool:b_CanControl = false
            if (b_IsInfected)
                b_CanControl = (GetEntProp(i_Client, Prop_Send, "m_zombieClass") != CLASS_TANK && IsPlayerAlive(i_Client))
            else
                b_CanControl = IsPlayerAlive(i_Client)
            
            if (b_CanControl)
            {
                decl i_Target, String:s_ClassName[16]
                i_Target = GetClientAimTarget(i_Client, false)
                
                if (i_Target > 0 && IsValidEdict(i_Target))
                {
                    GetEdictClassname(i_Target, s_ClassName, sizeof(s_ClassName))

                    decl i_EntityType = 0
                    if (StrEqual(s_ClassName, "witch"))
                        i_EntityType = ENTITY_WITCH
                    else if (StrEqual(s_ClassName, "infected"))
                        i_EntityType = ENTITY_COMMON
                    
                    if (i_EntityType > 0 && GetEntPropEnt(i_Target, Prop_Data, "m_hOwnerEntity") == -1)
                    {
                        if ((GetConVarInt(h_CvarEntityType) & i_EntityType) == 0)
                            return Plugin_Continue
                        
                        g_i_EntityType[i_Client] = i_EntityType
                        
                        // Ghost check: only for infected team (survivors have no m_isGhost)
                        if (b_IsInfected)
                        {
                            decl bool:b_IsGhost
                            b_IsGhost = bool:GetEntProp(i_Client, Prop_Send, "m_isGhost")
                            switch (GetConVarInt(h_CvarMode))
                            {
                                case 0:
                                    if (b_IsGhost)
                                        return Plugin_Continue
                                case 1:
                                    if (!b_IsGhost)
                                        return Plugin_Continue
                            }
                        }
                        
                        decl Float:f_TargetOrigin[3], Float:f_PlayerOrigin[3]
                        GetClientAbsOrigin(i_Client, f_PlayerOrigin)
                        GetEntPropVector(i_Target, Prop_Send, "m_vecOrigin", f_TargetOrigin)

                        if (GetVectorDistance(f_PlayerOrigin, f_TargetOrigin) <= 100.0)  // [TUNE] Khoảng cách tối đa để chiếm CI/Witch (units) – tăng nếu muốn chiếm từ xa hơn
                        {
                            decl Float:f_Origin[3]
                            GetEntPropVector(i_Target, Prop_Send, "m_vecOrigin", f_Origin)
                            f_Origin[2] += 10.0
                            TeleportEntity(i_Client, f_Origin, NULL_VECTOR, NULL_VECTOR)
                            SetEntProp(i_Client, Prop_Send, "m_fFlags", GetEntityFlags(i_Client) | FL_GODMODE)
                            SetEntProp(i_Client, Prop_Data, "m_takedamage", 0, 1)
                            
                            if (IsPlayerOnFire(i_Client))
                                ExtinguishEntity(i_Client)
                                
                            new Handle:h_Pack = CreateDataPack()
                            WritePackCell(h_Pack, i_Client)
                            WritePackCell(h_Pack, i_Target)
                            CreateTimer(0.1, SetWitchControl, h_Pack)
                            g_PlayerGameTime[i_Client] = GetGameTime() - 2.0
                        }
                    }
                }
            }
        }
        
        return Plugin_Continue
    }
        
    decl i_Witch, b_WitchMoved, i_Health, Float:f_GameTime, i_Sequence, Float:f_Rage, i_Flags
    
    b_WitchMoved = false
    i_Witch = g_b_WitchControl[i_Client]
    
    if (!IsValidEdict(i_Witch))
    {
        RemoveWitchControl(i_Client, i_Witch)
        return Plugin_Continue
    }
    
    // Toggle camera
    if (i_Buttons & IN_RELOAD)
    {
        if (g_b_FirstPerson[i_Client])
        {
            if (g_i_ClientCamera[i_Client] && IsValidEdict(g_i_ClientCamera[i_Client]))
            {
                AcceptEntityInput(g_i_ClientCamera[i_Client], "Enable", i_Client)
            }
            g_b_FirstPerson[i_Client] = false
        }
        else
        {
            if (g_i_ClientCamera[i_Client] && IsValidEdict(g_i_ClientCamera[i_Client]))
            {
                AcceptEntityInput(g_i_ClientCamera[i_Client], "Disable")
            }
            g_b_FirstPerson[i_Client] = true
        }
        i_Buttons &= ~IN_RELOAD
    }
    
    // Sync entity rotation with player view
    decl Float:f_Ang[3]
    GetEntPropVector(i_Witch, Prop_Send, "m_angRotation", f_Ang)
    f_Ang[0] = 0.0
    f_Ang[1] = f_PlayerAngles[1]
    f_Ang[2] = 0.0
    SetEntPropVector(i_Witch, Prop_Send, "m_angRotation", f_Ang)
    
    i_Health = GetEntProp(i_Witch, Prop_Data, "m_iHealth")
    
    if (i_Health <= 0 && !GetEntProp(i_Witch, Prop_Send, "m_bIsBurning"))
    {
        RemoveWitchControl(i_Client, i_Witch)
        return Plugin_Continue
    }
    else
        SetEntProp(i_Client, Prop_Data, "m_iHealth", i_Health)
    
    f_GameTime = GetGameTime()
    i_Sequence = GetEntProp(i_Witch, Prop_Data, "m_nSequence")
    
    if (g_i_EntityType[i_Client] == ENTITY_COMMON)
    {
        f_Rage = 0.0
    }
    else
    {
        f_Rage = GetEntPropFloat(i_Witch, Prop_Send, "m_rage")
    }
    
    i_Flags = GetEntityFlags(i_Witch)
        
    // Release control
    if (i_Buttons & IN_USE)
    {
        if (f_GameTime - g_PlayerGameTime[i_Client] > 3.5 || 0.0 < f_GameTime - g_PlayerGameTime[i_Client] < 2.0)
        {
            if (g_b_OnLadder[i_Client])
                return Plugin_Continue
        
            RemoveWitchControl(i_Client, i_Witch)
            g_PlayerGameTime[i_Client] = GetGameTime()
            i_Buttons &= ~IN_USE
            return Plugin_Continue
        }
    }
    
    // Handle Common Infected
    if (g_i_EntityType[i_Client] == ENTITY_COMMON)
    {
        // ✅ FORCE CLEAR MOB RUSH EVERY FRAME
        SetEntProp(i_Witch, Prop_Send, "m_mobRush", 0)
        
        // Survivor: strip IN_DUCK (SHIFT = crouch trong survivor) để không đè pose lên CI
        if (g_b_WasSurvivor[i_Client])
        {
            i_Buttons &= ~IN_DUCK
            return HandleCommonInfectedControls(i_Client, i_Witch, i_Buttons, f_GameTime, i_Sequence, i_Flags, f_PlayerAngles)
        }
        
        new Action:result = HandleCommonInfectedControls(i_Client, i_Witch, i_Buttons, f_GameTime, i_Sequence, i_Flags, f_PlayerAngles)
        
        return result
    }
    
    // WITCH CONTROL BELOW
    if (f_Rage)
    {
        if (i_Buttons & IN_ATTACK && GetConVarInt(h_CvarAttack))
            WitchAttack(i_Client, i_Witch)
        
        if (g_WitchLadderOrigin[i_Client])
            g_WitchLadderOrigin[i_Client] = 0.0
        
        if (i_Flags & FL_FROZEN)
            SetEntProp(i_Witch, Prop_Send, "m_fFlags", i_Flags & ~FL_FROZEN)
            
        return Plugin_Continue
    }
    
    if (GetEntProp(i_Witch, Prop_Send, "m_bIsBurning"))
        return Plugin_Continue
    
    if (GetEntPropEnt(i_Witch, Prop_Data, "m_hGroundEntity") == -1)
    {
        if (!g_b_OnLadder[i_Client] && !g_b_WitchJump[i_Client])
        {
            decl Float:f_Origin[3], Float:f_Angles[3], Float:f_Up[3]
            
            if (i_Flags & FL_FROZEN)
                SetEntProp(i_Witch, Prop_Send, "m_fFlags", i_Flags & ~FL_FROZEN)
                
            GetEntPropVector(i_Witch, Prop_Send, "m_vecOrigin", f_Origin)
            GetEntPropVector(i_Witch, Prop_Send, "m_angRotation", f_Angles)
            
            if (g_WitchLadderOrigin[i_Client])
            {
                f_Origin[2] = g_WitchLadderOrigin[i_Client]
                g_WitchLadderOrigin[i_Client] = 0.0
            }
            
            GetAngleVectors(f_Angles, NULL_VECTOR, NULL_VECTOR, f_Up)
            NormalizeVector(f_Up, f_Up)
            ScaleVector(f_Up, -4.0)
            AddVectors(f_Up, f_Origin, f_Origin)
            SetEntProp(i_Witch, Prop_Data, "m_nSequence", ANIM_FALL)
            TeleportEntity(i_Witch, f_Origin, NULL_VECTOR, NULL_VECTOR)
                
            return Plugin_Continue
        }
    }
    else
    { 
        if (!g_b_OnLadder[i_Client] && g_WitchLadderOrigin[i_Client])
            g_WitchLadderOrigin[i_Client] = 0.0
        
        if (i_Flags & FL_FROZEN)
            SetEntProp(i_Witch, Prop_Send, "m_fFlags", i_Flags & ~FL_FROZEN)	
    }
    
    if (0.0 < (f_GameTime - g_PlayerGameTime[i_Client]) < 1.0)
        return Plugin_Continue
        
    if (g_b_WitchJump[i_Client])
        return Plugin_Continue
    
    if (i_Buttons & IN_DUCK && !g_b_OnLadder[i_Client])
    {
        if (i_Sequence != ANIM_SITTING)
        {
            SetEntProp(i_Witch, Prop_Send, "m_fFlags", i_Flags | FL_DUCKING)
            SetEntProp(i_Witch, Prop_Data, "m_nSequence", ANIM_SITTING)
        }
        else
        {
            SetEntProp(i_Witch, Prop_Send, "m_fFlags", i_Flags & ~FL_DUCKING)
            SetEntProp(i_Witch, Prop_Data, "m_nSequence", ANIM_STANDING_CRYING)
        }

        g_PlayerGameTime[i_Client] = f_GameTime
        i_Buttons &= ~IN_DUCK
        return Plugin_Continue
    }
        
    if (i_Buttons & IN_JUMP && !g_b_OnLadder[i_Client] && !(i_Flags & FL_DUCKING))
    {
        if (f_GameTime - g_PlayerGameTime[i_Client] > 3.5 || f_GameTime - g_PlayerGameTime[i_Client] < 2.0)
        {
            g_b_WitchJump[i_Client] = 2.0
            g_PlayerGameTime[i_Client] = f_GameTime - 2.0
            return Plugin_Continue
        }
    }
    
    if (i_Buttons & IN_ATTACK && GetConVarInt(h_CvarAttack))
    {
        WitchAttack(i_Client, i_Witch)
        return Plugin_Continue
    }
    
    if (i_Buttons & (IN_LEFT|IN_MOVELEFT))
    {
        decl Float:f_Origin[3], Float:f_Angles[3], Float:f_Left[3], Float:f_TraceOrigin[3], Handle:h_Trace
        
        GetEntPropVector(i_Witch, Prop_Send, "m_vecOrigin", f_Origin)
        GetEntPropVector(i_Witch, Prop_Send, "m_angRotation", f_Angles)
        
        if (g_b_OnLadder[i_Client])
        {
            f_TraceOrigin[0] = f_Origin[0]
            f_TraceOrigin[1] = f_Origin[1]
            f_TraceOrigin[2] = f_Origin[2] + 2.0
    
            h_Trace = TR_TraceRayFilterEx(f_TraceOrigin, f_Angles, MASK_ALL, RayType_Infinite, TraceFilterClients, i_Witch)
            
            if (TR_DidHit(h_Trace))
            {
                decl i_Target
                i_Target = TR_GetEntityIndex(h_Trace)
    
                if (i_Target)
                {
                    GetAngleVectors(f_Angles, NULL_VECTOR, f_Left, NULL_VECTOR)
                    NormalizeVector(f_Left, f_Left)
                    ScaleVector(f_Left, -1.0)
                    AddVectors(f_Left, f_Origin, f_Origin)
                    TeleportEntity(i_Witch, f_Origin, NULL_VECTOR, NULL_VECTOR)
                }
                else
                {
                    g_b_OnLadder[i_Client] = false
                    f_Origin[2] = g_WitchLadderOrigin[i_Client]
                    TeleportEntity(i_Witch, f_Origin, NULL_VECTOR, NULL_VECTOR)
                }
            }
            CloseHandle(h_Trace)
        }
        else
        {
            if (i_Flags & FL_DUCKING)
            {
                f_Angles[1] += 1.0
                SetEntProp(i_Witch, Prop_Data, "m_nSequence", ANIM_TURN_LEFT)
                TeleportEntity(i_Witch, NULL_VECTOR, f_Angles, NULL_VECTOR)
                return Plugin_Continue
            }
            else
                f_Angles[1] += 2.0
            TeleportEntity(i_Witch, NULL_VECTOR, f_Angles, NULL_VECTOR)
        }
    }	
    
    if (i_Buttons & (IN_RIGHT|IN_MOVERIGHT))
    {
        decl Float:f_Origin[3], Float:f_Angles[3], Float:f_Right[3], Float:f_TraceOrigin[3], Handle:h_Trace
        
        GetEntPropVector(i_Witch, Prop_Send, "m_vecOrigin", f_Origin)
        GetEntPropVector(i_Witch, Prop_Send, "m_angRotation", f_Angles)
        
        if (g_b_OnLadder[i_Client])
        {
            f_TraceOrigin[0] = f_Origin[0]
            f_TraceOrigin[1] = f_Origin[1]
            f_TraceOrigin[2] = f_Origin[2] + 2.0
    
            h_Trace = TR_TraceRayFilterEx(f_TraceOrigin, f_Angles, MASK_ALL, RayType_Infinite, TraceFilterClients, i_Witch)
            
            if (TR_DidHit(h_Trace))
            {
                decl i_Target
                i_Target = TR_GetEntityIndex(h_Trace)
    
                if (i_Target)
                {
                    GetAngleVectors(f_Angles, NULL_VECTOR, f_Right, NULL_VECTOR)
                    NormalizeVector(f_Right, f_Right)
                    ScaleVector(f_Right, 1.0)
                    AddVectors(f_Right, f_Origin, f_Origin)
                    TeleportEntity(i_Witch, f_Origin, NULL_VECTOR, NULL_VECTOR)
                }
                else
                {
                    g_b_OnLadder[i_Client] = false
                    f_Origin[2] = g_WitchLadderOrigin[i_Client]
                    TeleportEntity(i_Witch, f_Origin, NULL_VECTOR, NULL_VECTOR)
                }
            }
            CloseHandle(h_Trace)
        }
        else
        {
            if (i_Flags & FL_DUCKING)
            {
                f_Angles[1] -= 1.0
                SetEntProp(i_Witch, Prop_Data, "m_nSequence", ANIM_TURN_RIGHT)
                TeleportEntity(i_Witch, NULL_VECTOR, f_Angles, NULL_VECTOR)
                return Plugin_Continue
            }
            else
                f_Angles[1] -= 2.0
            TeleportEntity(i_Witch, NULL_VECTOR, f_Angles, NULL_VECTOR)
        }
    }
    
    if (i_Flags & FL_DUCKING)
    {
        SetEntProp(i_Witch, Prop_Data, "m_nSequence", ANIM_SITTING)
        return Plugin_Continue
    }
        
    if (i_Buttons & IN_FORWARD)
    {
        decl Float:f_Origin[3], Float:f_Angles[3], Float:f_Forward[3], Float:f_TraceOrigin[3], Handle:h_Trace, bool:b_LadderTrace
        
        b_WitchMoved = true
        
        GetEntPropVector(i_Witch, Prop_Send, "m_vecOrigin", f_Origin)
        GetEntPropVector(i_Witch, Prop_Send, "m_angRotation", f_Angles)
        
        if (g_b_OnLadder[i_Client])
        {
            b_LadderTrace = true
            f_TraceOrigin[0] = f_Origin[0]
            f_TraceOrigin[1] = f_Origin[1]
            f_TraceOrigin[2] = f_Origin[2]
        }
        else
        {
            b_LadderTrace = false
            f_TraceOrigin[0] = f_Origin[0]
            f_TraceOrigin[1] = f_Origin[1]
            f_TraceOrigin[2] = f_Origin[2] + 20.0
        }

        if (b_LadderTrace || !g_PlayerTraceTimer[i_Client] || (f_GameTime - g_PlayerTraceTimer[i_Client] >= 0.5))
        {
            h_Trace = TR_TraceRayFilterEx(f_TraceOrigin, f_Angles, MASK_ALL, RayType_Infinite, TraceFilterClients, i_Witch)
            g_PlayerTraceTimer[i_Client] = f_GameTime
        
            if (TR_DidHit(h_Trace))
            {
                decl Float:f_EndOrigin[3], String:s_ClassName[20], i_Target
    
                i_Target = TR_GetEntityIndex(h_Trace)
                TR_GetEndPosition(f_EndOrigin, h_Trace)

                if (i_Target)
                {
                    if (IsValidEdict(i_Target))
                    {
                        GetEdictClassname(i_Target, s_ClassName, sizeof(s_ClassName))
                        if (StrEqual(s_ClassName, "func_simpleladder"))
                        {
                            if (GetVectorDistance(f_Origin, f_EndOrigin) <= 25.0)
                            {
                                g_b_OnLadder[i_Client] = true
                                SetEntProp(i_Witch, Prop_Data, "m_nSequence", ANIM_LADDER_ASCEND)
                                if (!g_WitchLadderOrigin[i_Client])
                                {
                                    f_Origin[2] += 15.0
                                    g_WitchLadderOrigin[i_Client] = f_Origin[2]
                                }
                                g_WitchLadderOrigin[i_Client] += 1.2
                                CloseHandle(h_Trace)
                                return Plugin_Continue
                            }
                        }
                    }
                }
                else if (g_b_OnLadder[i_Client])
                {
                    g_b_OnLadder[i_Client] = false
                    SetEntProp(i_Witch, Prop_Send, "m_fFlags", i_Flags & ~FL_FROZEN)
                }
            }
            CloseHandle(h_Trace)
        }
        
        GetAngleVectors(f_Angles, f_Forward, NULL_VECTOR, NULL_VECTOR)
        NormalizeVector(f_Forward, f_Forward)
        ScaleVector(f_Forward, GetConVarFloat(h_CvarWitchSpeed))
        AddVectors(f_Forward, f_Origin, f_Origin)
        SetEntProp(i_Witch, Prop_Data, "m_nSequence", ANIM_WALK)
        TeleportEntity(i_Witch, f_Origin, NULL_VECTOR, NULL_VECTOR)
    }
    
    if (i_Buttons & IN_BACK && g_b_OnLadder[i_Client])
    {
        decl Float:f_Origin[3], Float:f_Angles[3], Handle:h_Trace
        
        b_WitchMoved = true
        
        GetEntPropVector(i_Witch, Prop_Send, "m_vecOrigin", f_Origin)
        GetEntPropVector(i_Witch, Prop_Send, "m_angRotation", f_Angles)
        
        h_Trace = TR_TraceRayFilterEx(f_Origin, f_Angles, MASK_ALL, RayType_Infinite, TraceFilterClients, i_Witch)
        
        if (TR_DidHit(h_Trace))
        {
            decl Float:f_EndOrigin[3], String:s_ClassName[20], i_Target
    
            i_Target = TR_GetEntityIndex(h_Trace)
            
            if (i_Target > 0 && IsValidEdict(i_Target))
            {
                GetEdictClassname(i_Target, s_ClassName, sizeof(s_ClassName))
                if (StrEqual(s_ClassName, "func_simpleladder"))
                {
                    TR_GetEndPosition(f_EndOrigin, h_Trace)
                    if (GetVectorDistance(f_Origin, f_EndOrigin) <= 15.0)
                    {
                        g_b_OnLadder[i_Client] = true
                        SetEntProp(i_Witch, Prop_Data, "m_nSequence", ANIM_LADDER_DESCEND)
                        f_Origin[2] = g_WitchLadderOrigin[i_Client]
                        g_WitchLadderOrigin[i_Client] -= 1.2
                        CloseHandle(h_Trace)
                        return Plugin_Continue
                    }
                }
            }
            else if (g_b_OnLadder[i_Client])
            {
                g_b_OnLadder[i_Client] = false
                SetEntProp(i_Witch, Prop_Send, "m_fFlags", i_Flags & ~FL_FROZEN)
            }
        }	
        CloseHandle(h_Trace)
    }

    if (!b_WitchMoved && !g_b_OnLadder[i_Client] && !(i_Flags & FL_DUCKING))
        SetEntProp(i_Witch, Prop_Data, "m_nSequence", ANIM_STANDING_CRYING)
    
    return Plugin_Continue
}
/* ==================== CAMERA UPDATE (SMOOTH) ==================== */
public OnGameFrame()
{
    decl i_Client, i_Witch, Float:f_Angles[3], Float:f_Origin[3], Float:f_Forward[3], Float:f_Up[3]
    decl Float:f_PlayerAngles[3], Float:f_CamAngles[3]
    
    for (i_Client = 1; i_Client <= MaxClients; i_Client++)
    {
        i_Witch = g_b_WitchControl[i_Client]
        
        if (i_Witch && IsValidEdict(i_Witch) && g_i_ClientCamera[i_Client] && IsValidEdict(g_i_ClientCamera[i_Client]))
        {
           // ⭐ THÊM BIẾN GLOBAL:
new Float:g_fLastCameraAngles[MAXPLAYERS+1][3];

// TRONG OnGameFrame():
if (!g_b_FirstPerson[i_Client])
            {
                GetClientEyeAngles(i_Client, f_PlayerAngles);
                GetEntPropVector(i_Witch, Prop_Send, "m_vecOrigin", f_Origin);
                
                // Normalize input
                while (f_PlayerAngles[0] > 180.0) f_PlayerAngles[0] -= 360.0;
                while (f_PlayerAngles[0] < -180.0) f_PlayerAngles[0] += 360.0;
                while (f_PlayerAngles[1] > 180.0) f_PlayerAngles[1] -= 360.0;
                while (f_PlayerAngles[1] < -180.0) f_PlayerAngles[1] += 360.0;
                
                // ✅ TÍNH DELTA (thay đổi so với frame trước)
                new Float:f_DeltaPitch = f_PlayerAngles[0] - g_fLastCameraAngles[i_Client][0];
                new Float:f_DeltaYaw = f_PlayerAngles[1] - g_fLastCameraAngles[i_Client][1];
                
                // Handle angle wrap
                if (f_DeltaPitch > 180.0) f_DeltaPitch -= 360.0;
                if (f_DeltaPitch < -180.0) f_DeltaPitch += 360.0;
                if (f_DeltaYaw > 180.0) f_DeltaYaw -= 360.0;
                if (f_DeltaYaw < -180.0) f_DeltaYaw += 360.0;
                
                // ✅ GIỚI HẠN TỐC ĐỘ (degrees per frame)
                new Float:f_MaxDelta = 5.0;
                if (f_DeltaPitch > f_MaxDelta) f_DeltaPitch = f_MaxDelta;
                if (f_DeltaPitch < -f_MaxDelta) f_DeltaPitch = -f_MaxDelta;
                if (f_DeltaYaw > f_MaxDelta) f_DeltaYaw = f_MaxDelta;
                if (f_DeltaYaw < -f_MaxDelta) f_DeltaYaw = -f_MaxDelta;
                
                // ✅ ÁP DỤNG DELTA
                f_CamAngles[0] = g_fLastCameraAngles[i_Client][0] + f_DeltaPitch;
                f_CamAngles[1] = g_fLastCameraAngles[i_Client][1] + f_DeltaYaw - 60.0;
                f_CamAngles[2] = -90.0;
                
                // ✅ CLAMP PITCH
                if (f_CamAngles[0] > 85.0) f_CamAngles[0] = 85.0;
                if (f_CamAngles[0] < -85.0) f_CamAngles[0] = -85.0;
                
                // Normalize output
                while (f_CamAngles[0] > 180.0) f_CamAngles[0] -= 360.0;
                while (f_CamAngles[0] < -180.0) f_CamAngles[0] += 360.0;
                while (f_CamAngles[1] > 180.0) f_CamAngles[1] -= 360.0;
                while (f_CamAngles[1] < -180.0) f_CamAngles[1] += 360.0;
                
                // ✅✅ CHECK COLLISION TRƯỚC KHI ÁP DỤNG ✅✅
                decl Float:f_CamPos[3], Float:f_TestPos[3], Float:f_Dir[3];
                decl Handle:h_Trace;
                
                // Tính vị trí camera dự kiến
                GetAngleVectors(f_CamAngles, f_Dir, NULL_VECTOR, NULL_VECTOR);
                f_CamPos[0] = f_Origin[0] - f_Dir[0] * 150.0; // Camera cách 150 units
                f_CamPos[1] = f_Origin[1] - f_Dir[1] * 150.0;
                f_CamPos[2] = f_Origin[2] + 60.0 - f_Dir[2] * 150.0; // Cao 60 units
                
                // Trace từ entity đến camera position
                h_Trace = TR_TraceRayFilterEx(f_Origin, f_CamPos, MASK_SOLID, RayType_EndPoint, TraceFilterClients, i_Witch);
                
                if (TR_DidHit(h_Trace))
                {
                    // ✅ CÓ VA CHẠM → GIỮ CAMERA GẦN HỞN
                    TR_GetEndPosition(f_TestPos, h_Trace);
                    
                    // Tính khoảng cách thực tế có thể dùng
                    new Float:f_HitDist = GetVectorDistance(f_Origin, f_TestPos);
                    new Float:f_SafeDist = f_HitDist - 20.0; // Lùi thêm 20 units để tránh clipping
                    
                    if (f_SafeDist < 30.0) f_SafeDist = 30.0; // Tối thiểu 30 units
                    
                    // Tính lại vị trí camera an toàn
                    f_CamPos[0] = f_Origin[0] - f_Dir[0] * f_SafeDist;
                    f_CamPos[1] = f_Origin[1] - f_Dir[1] * f_SafeDist;
                    f_CamPos[2] = f_Origin[2] + 60.0 - f_Dir[2] * f_SafeDist;
                    
                    // ✅ SNAP CAMERA NGAY LẬP TỨC (không smooth khi có va chạm)
                    TeleportEntity(g_i_ClientCamera[i_Client], NULL_VECTOR, f_CamAngles, NULL_VECTOR);
                }
                else
                {
                    // ✅ KHÔNG VA CHẠM → SMOOTH BÌNH THƯỜNG
                    TeleportEntity(g_i_ClientCamera[i_Client], NULL_VECTOR, f_CamAngles, NULL_VECTOR);
                }
                
                CloseHandle(h_Trace);
                
                // Lưu lại góc hiện tại
                g_fLastCameraAngles[i_Client][0] = f_CamAngles[0];
                g_fLastCameraAngles[i_Client][1] = f_CamAngles[1];
            }
        }
        // ✅ XỬ LÝ JUMP CHO COMMON INFECTED
            if (g_b_WitchJump[i_Client] && g_i_EntityType[i_Client] == ENTITY_COMMON)
            {
                g_b_WitchJump[i_Client] += 0.15  // Tăng nhanh hơn witch một chút
                
                GetEntPropVector(i_Witch, Prop_Send, "m_vecOrigin", f_Origin)
                GetEntPropVector(i_Witch, Prop_Send, "m_angRotation", f_Angles)
                GetAngleVectors(f_Angles, f_Forward, NULL_VECTOR, f_Up)
                NormalizeVector(f_Forward, f_Forward)
                NormalizeVector(f_Up, f_Up)

                // Pha tăng tốc (2.0 → 3.5)
                if (g_b_WitchJump[i_Client] <= 3.5)
                {
                    ScaleVector(f_Forward, g_b_WitchJump[i_Client] * 1.5)      
                    ScaleVector(f_Up, g_b_WitchJump[i_Client] * 12.5)           
                }
                // Pha rơi xuống (3.5 → 5.0)
                else if (g_b_WitchJump[i_Client] <= 5.0)
                {
                    ScaleVector(f_Forward, g_b_WitchJump[i_Client] * 0.8)
                    ScaleVector(f_Up, -(g_b_WitchJump[i_Client] - 3.5) * 1.5)  // Rơi xuống
                }
                // Kết thúc
                else
                {
                    g_b_WitchJump[i_Client] = 0.0
                    
                    // Kiểm tra landing
                    new bool:b_OnGround = (GetEntPropEnt(i_Witch, Prop_Data, "m_hGroundEntity") != -1)
                    if (b_OnGround)
                    {
                        SetEntProp(i_Witch, Prop_Data, "m_nSequence", CI_LAND_NEUTRAL)
                    }
                }
                
                // Áp dụng di chuyển
                if (g_b_WitchJump[i_Client] > 0.0)
                {
                    AddVectors(f_Forward, f_Origin, f_Origin)
                    AddVectors(f_Up, f_Origin, f_Origin)
                    SetEntProp(i_Witch, Prop_Data, "m_nSequence", CI_JUMP)
                    
                    TeleportEntity(i_Witch, f_Origin, NULL_VECTOR, NULL_VECTOR)
                }
            }
        if (g_b_WitchJump[i_Client] && g_i_EntityType[i_Client] == ENTITY_WITCH)
        {
            if (i_Witch && IsValidEdict(i_Witch))
            {
                g_b_WitchJump[i_Client] += 0.1;
                
                GetEntPropVector(i_Witch, Prop_Send, "m_vecOrigin", f_Origin);
                GetEntPropVector(i_Witch, Prop_Send, "m_angRotation", f_Angles);
                GetAngleVectors(f_Angles, f_Forward, NULL_VECTOR, f_Up);
                NormalizeVector(f_Forward, f_Forward);
                NormalizeVector(f_Up, f_Up);

                if (g_b_WitchJump[i_Client] <= 3.0)
                {
                    ScaleVector(f_Forward, g_b_WitchJump[i_Client]);
                    ScaleVector(f_Up, g_b_WitchJump[i_Client] * 3.0);
                }
                else if (g_b_WitchJump[i_Client] <= 4.0)
                {
                    ScaleVector(f_Forward, g_b_WitchJump[i_Client]);
                    ScaleVector(f_Up, g_b_WitchJump[i_Client] / 3.0);
                }
                else
                    g_b_WitchJump[i_Client] = 0.0;
                
                AddVectors(f_Forward, f_Origin, f_Origin);
                AddVectors(f_Up, f_Origin, f_Origin);
                SetEntProp(i_Witch, Prop_Data, "m_nSequence", ANIM_JUMP);
                
                TeleportEntity(i_Witch, f_Origin, NULL_VECTOR, NULL_VECTOR);
            }
        }
        else if (g_b_OnLadder[i_Client] && g_i_EntityType[i_Client] == ENTITY_WITCH)
        {
            if (i_Witch && IsValidEdict(i_Witch))
            {
                GetEntPropVector(i_Witch, Prop_Send, "m_vecOrigin", f_Origin);
                if (f_Origin[2] == g_WitchLadderOrigin[i_Client])
                    SetEntProp(i_Witch, Prop_Send, "m_fFlags", GetEntityFlags(i_Witch) | FL_FROZEN);
                else
                    SetEntProp(i_Witch, Prop_Send, "m_fFlags", GetEntityFlags(i_Witch) & ~FL_FROZEN);
                    
                f_Origin[2] = g_WitchLadderOrigin[i_Client];
                TeleportEntity(i_Witch, f_Origin, NULL_VECTOR, NULL_VECTOR);
            }
        }
        else if (g_b_OnLadder[i_Client] && g_i_EntityType[i_Client] == ENTITY_WITCH)
        {
            if (i_Witch && IsValidEdict(i_Witch))
            {
                GetEntPropVector(i_Witch, Prop_Send, "m_vecOrigin", f_Origin)
                if (f_Origin[2] == g_WitchLadderOrigin[i_Client])
                    SetEntProp(i_Witch, Prop_Send, "m_fFlags", GetEntityFlags(i_Witch) | FL_FROZEN)
                else
                    SetEntProp(i_Witch, Prop_Send, "m_fFlags", GetEntityFlags(i_Witch) & ~FL_FROZEN)
                    
                f_Origin[2] = g_WitchLadderOrigin[i_Client]
                TeleportEntity(i_Witch, f_Origin, NULL_VECTOR, NULL_VECTOR)
            }
        }
    }
}

/* ==================== MISC FUNCTIONS ==================== */
public WitchAttack(i_Client, i_Witch)
{
    if (g_b_OnLadder[i_Client])
        g_b_OnLadder[i_Client] = false
        
    SetEntPropFloat(i_Witch, Prop_Send, "m_rage", 1.0)
    SetEntProp(i_Witch, Prop_Send, "m_mobRush", 1)
}

public Action:TeleportPlayer(Handle:h_Timer, any:i_Client)
{
    decl i_Witch, Float:f_Origin[3]
    
    i_Witch = g_b_WitchControl[i_Client]
    
    if (!IsValidEdict(i_Witch) || !IsClientInGame(i_Client))
    {
        if (g_h_TeleportTimer[i_Client] != INVALID_HANDLE)
        {
            KillTimer(g_h_TeleportTimer[i_Client])
            g_h_TeleportTimer[i_Client] = INVALID_HANDLE
        }	
        return Plugin_Handled
    }
    
    GetEntPropVector(i_Witch, Prop_Send, "m_vecOrigin", f_Origin)
    f_Origin[2] += 10.0
    
    if (g_i_EntityType[i_Client] == ENTITY_COMMON)
    {
        // CI: sync player đã xử lý trong OnPlayerRunCmd rồi
        // Chỉ cần anti-jitter velocity thôi
        decl Float:f_Vel[3]
        GetEntPropVector(i_Witch, Prop_Data, "m_vecVelocity", f_Vel)
        if (!g_b_IsMoving[i_Client] && !g_b_IsAttacking[i_Client] && GetVectorLength(f_Vel) > 50.0)
        {
            f_Vel[0] = 0.0
            f_Vel[1] = 0.0
            f_Vel[2] = 0.0
            TeleportEntity(i_Witch, NULL_VECTOR, NULL_VECTOR, f_Vel)
        }
    }
    else
    {
        // Witch: vẫn sync player qua timer như cũ
        TeleportEntity(i_Client, f_Origin, NULL_VECTOR, NULL_VECTOR)
    }
    return Plugin_Continue
}

public bool:TraceFilterClients(i_Entity, i_Mask, any:i_Data)
{
    if (i_Entity == i_Data)
        return false;
    if (1 <= i_Entity <= MaxClients)
        return false;
    return true;
}

// ✅ Filter cho vault: bỏ qua players VÀ infected, chỉ hit world/props
public bool:TraceFilterWorldOnly(i_Entity, i_Mask, any:i_Data)
{
    if (i_Entity == i_Data)
        return false
    if (1 <= i_Entity <= MaxClients)
        return false
    
    // Bỏ qua infected entity
    decl String:s_Class[32]
    GetEdictClassname(i_Entity, s_Class, sizeof(s_Class))
    if (StrEqual(s_Class, "infected") || StrEqual(s_Class, "witch") || StrContains(s_Class, "tank") != -1)
        return false
    
    return true
}

public RemoveWitchControl(i_Client, i_Witch)
{
    decl Float:f_Origin[3], i_Sequence, Float:f_Rage
    
    if (g_h_TeleportTimer[i_Client] != INVALID_HANDLE)
    {
        KillTimer(g_h_TeleportTimer[i_Client])
        g_h_TeleportTimer[i_Client] = INVALID_HANDLE
    }

    g_b_WitchControl[i_Client] = 0
    g_b_OnLadder[i_Client] = false
    g_b_IsMoving[i_Client] = false
    g_b_IsFalling[i_Client] = false
    g_b_IsAttacking[i_Client] = false
    g_i_AnimMode[i_Client] = MODE_MOVEMENT
    g_i_AnimIndex[i_Client] = 0
    g_b_InPoseMode[i_Client] = false
    
    g_LastCameraPos[i_Client][0] = 0.0
    g_LastCameraPos[i_Client][1] = 0.0
    g_LastCameraPos[i_Client][2] = 0.0
    g_b_WitchControl[i_Client] = 0
    g_b_OnLadder[i_Client] = false
    g_b_IsMoving[i_Client] = false
    g_b_IsFalling[i_Client] = false
    g_b_IsAttacking[i_Client] = false
    g_i_AnimMode[i_Client] = MODE_MOVEMENT
    g_i_AnimIndex[i_Client] = 0
    g_b_InPoseMode[i_Client] = false
    g_b_WitchJump[i_Client] = 0.0  // ✅ RESET JUMP
    g_f_VaultCooldown[i_Client] = 0.0  // ✅ RESET VAULT
    if (IsValidEdict(i_Witch))
    {
        if (g_i_EntityType[i_Client] == ENTITY_WITCH)
        {
            i_Sequence = GetEntProp(i_Witch, Prop_Data, "m_nSequence")
            f_Rage = GetEntPropFloat(i_Witch, Prop_Send, "m_rage")
        
            if (i_Sequence != ANIM_SITTING && !f_Rage)
            {
                SetEntProp(i_Witch, Prop_Send, "m_fFlags", GetEntityFlags(i_Witch) | FL_DUCKING)
                
                if (!GetEntProp(i_Witch, Prop_Send, "m_bIsBurning"))
                    SetEntProp(i_Witch, Prop_Data, "m_nSequence", ANIM_SITTING)
            }
        }
        else if (g_i_EntityType[i_Client] == ENTITY_COMMON)
        {
            SetEntProp(i_Witch, Prop_Data, "m_takedamage", 2, 1)
            SetEntProp(i_Witch, Prop_Data, "m_lifeState", 0)
            
            // Restore NPC movetype nếu survivor đã đổi nó
            if (g_b_WasSurvivor[i_Client])
                SetEntityMoveType(i_Witch, MOVETYPE_STEP)
            
            // ✅ XÓA OWNER TRACKING
            new i_CommonNum = GetCommonNumber(i_Witch)
            if (i_CommonNum != -1)
            {
                g_iCommonOwner[i_CommonNum] = -1
            }
        }
            
        SetEntPropEnt(i_Witch, Prop_Data, "m_hOwnerEntity", -1)
    }
    
    GetClientAbsOrigin(i_Client, f_Origin)
    f_Origin[2] += 50.0
    
    DispatchKeyValue(i_Client, "parentname", "")
    SetVariantString("")
    AcceptEntityInput(i_Client, "SetParent")
    
    if (GetClientTeam(i_Client) == TEAM_INFECTED && GetEntProp(i_Client, Prop_Send, "m_zombieClass") != CLASS_TANK)
    {
        ScreenFade(i_Client, 1, 1, {0, 0, 0, 255})
        TeleportEntity(i_Client, Float:{0.0, 0.0, 0.0}, NULL_VECTOR, NULL_VECTOR)
        ForcePlayerSuicide(i_Client)
        
        new Handle:h_Pack = CreateDataPack()
        WritePackCell(h_Pack, i_Client)
        WritePackFloat(h_Pack, f_Origin[0])
        WritePackFloat(h_Pack, f_Origin[1])
        WritePackFloat(h_Pack, f_Origin[2])
    
        CreateTimer(1.0, ReturnCamera, h_Pack)
    }
    else if (g_b_WasSurvivor[i_Client])
    {
        // Survivor controller: restore team + body, no suicide
        SetEntProp(i_Client, Prop_Send, "m_iTeamNum", TEAM_SURVIVOR)
        g_b_WasSurvivor[i_Client] = false
        SetEntityMoveType(i_Client, MOVETYPE_WALK)
        SetEntityRenderMode(i_Client, RENDER_NORMAL)
        SetEntityRenderColor(i_Client, 255, 255, 255, 255)
        AcceptEntityInput(i_Client, "EnableShadow")
        SetEntProp(i_Client, Prop_Send, "m_fFlags", GetEntityFlags(i_Client) & ~FL_GODMODE)
        SetEntProp(i_Client, Prop_Data, "m_takedamage", 2, 1)
        
        ScreenFade(i_Client, 1, 1, {0, 0, 0, 255})
        
        new Handle:h_Pack = CreateDataPack()
        WritePackCell(h_Pack, i_Client)
        WritePackFloat(h_Pack, f_Origin[0])
        WritePackFloat(h_Pack, f_Origin[1])
        WritePackFloat(h_Pack, f_Origin[2])
        CreateTimer(1.0, ReturnCamera, h_Pack)
    }
    
    if (g_i_ClientCamera[i_Client] && IsValidEdict(g_i_ClientCamera[i_Client]))
        AcceptEntityInput(g_i_ClientCamera[i_Client], "Disable")
    
    g_i_ClientCamera[i_Client] = 0
    g_b_FirstPerson[i_Client] = false
}

public Action:ReturnCamera(Handle:h_Timer, Handle:h_Pack)
{
    decl Float:f_Origin[3], Float:f_Angles[3], i_Client
    
    ResetPack(h_Pack, false)
    i_Client = ReadPackCell(h_Pack)
    f_Origin[0] = ReadPackFloat(h_Pack)
    f_Origin[1] = ReadPackFloat(h_Pack)
    f_Origin[2] = ReadPackFloat(h_Pack)
    CloseHandle(h_Pack)
        
    f_Angles[0] = 0.0
    f_Angles[1] = GetRandomFloat(-180.0, 180.0)
    f_Angles[2] = 0.0
    
    if (IsClientInGame(i_Client))
        TeleportEntity(i_Client, f_Origin, f_Angles, NULL_VECTOR)
}

public ScreenFade(i_Client, i_Duration, i_Time, const i_Color[4])
{
    new Handle:h_Screen = StartMessageOne("Fade", i_Client)
    
    if (h_Screen != INVALID_HANDLE)
    {
        BfWriteShort(h_Screen, i_Duration*400)
        BfWriteShort(h_Screen, i_Time*400)
        BfWriteShort(h_Screen, FADE_IN)
        BfWriteByte(h_Screen, i_Color[0])
        BfWriteByte(h_Screen, i_Color[1])
        BfWriteByte(h_Screen, i_Color[2])
        BfWriteByte(h_Screen, i_Color[3])
        EndMessage()
    }
}

public bool:IsPlayerOnFire(i_Client)
{
    if (GetEntityFlags(i_Client) & FL_ONFIRE)
        return true
    return false
}