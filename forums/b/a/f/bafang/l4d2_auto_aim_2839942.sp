#include <sourcemod>
#include <left4dhooks_lux_library>
#include <sdkhooks>
#include <sdktools>
#include <l4d_anim>

#define TEAM_SPECTATOR 1
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

#define LANGUAGE "ENG"

public Plugin AutoAimPluginInfo =
{
    name = "Auto Aim",
    author = "Pure_*",
    description = "Allows player auto aim to SI immediately",
    version = "0.5",
    url = "purezhao.github.io"
};

int durations[MAXPLAYERS + 1];
Handle timers[MAXPLAYERS + 1];

StringMap infecteds;
StringMap allowedWeapons;

ConVar mode;
ConVar angleLimit;
ConVar needPrintTip;
ConVar aimCommonInfected;
ConVar aimSpecialInfected;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion version = GetEngineVersion();
    if(version != Engine_Left4Dead2)
    {
        Format(error, err_max, "[Auto-Aim] This Plugin Only Support Left 4 Dead 2");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

public OnPluginStart()
{
    infecteds = new StringMap();
    allowedWeapons = new StringMap();
    allowedWeapons.SetValue("autoshotgun", true);
    allowedWeapons.SetValue("hunting_rifle", true);
    allowedWeapons.SetValue("pistol", true);
    allowedWeapons.SetValue("pistol_magnum", true);
    allowedWeapons.SetValue("pumpshotgun", true);
    allowedWeapons.SetValue("rifle", true);
    allowedWeapons.SetValue("rifle_ak47", true);
    allowedWeapons.SetValue("rifle_desert", true);
    allowedWeapons.SetValue("rifle_m60", true);
    allowedWeapons.SetValue("rifle_sg552", true);
    allowedWeapons.SetValue("shotgun_chrome", true);
    allowedWeapons.SetValue("shotgun_spas", true);
    allowedWeapons.SetValue("smg", true);
    allowedWeapons.SetValue("smg_mp5", true);
    allowedWeapons.SetValue("smg_silenced", true);
    allowedWeapons.SetValue("sniper_awp", true);
    allowedWeapons.SetValue("sniper_military", true);
    allowedWeapons.SetValue("sniper_scout", true);

    // 注册两个命令
    RegAdminCmd("sm_autoaim", Command_AutoAim, ADMFLAG_SLAY);
    RegAdminCmd("sm_zimiao", Command_ZiMiao, ADMFLAG_SLAY);

    HookEvent("player_spawn", OnPlayerSpawn);
    HookEvent("player_death", OnPlayerDeath);
    HookEvent("infected_death", OnInfectedDeath);
    HookEvent("weapon_fire", OnWeaponFire);
    HookEvent("round_end", OnRoundEnd);
    HookEvent("finale_win", OnRoundEnd);
    HookEvent("mission_lost", OnRoundEnd);
    HookEvent("map_transition", OnRoundEnd);

    mode = CreateConVar("l4d2_auto_aim_mode", "0", "Auto-Aim mode, 0 is nomal mode, 1 is Spin Bot mode", 0, true, 0.0, true, 1.0);
    angleLimit = CreateConVar("l4d2_auto_aim_limited_angle", "20.0", "Only use when mode is 0, the angle between the player's line of sight and the enemy's head", 0, true, 45.0, true, 89.0);
    needPrintTip = CreateConVar("l4d2_auto_aim_need_print_tip", "1", "Need to print who turn on auto-aim to all player? 0 = No, 1 = Yes", 0, true, 0.0, true, 1.0);
    
    // 修改这里：将普通感染者默认值改为0（关闭）
    aimCommonInfected = CreateConVar("l4d2_auto_aim_ci_enable", "0", "Auto aim common infected?(0=disable, 1=enable)", 0, true, 0.0, true, 1.0);
    aimSpecialInfected = CreateConVar("l4d2_auto_aim_si_enable", "1", "Auto aim special infected?(0=disable, 1=enable)", 0, true, 0.0, true, 1.0);
    
    AutoExecConfig(true, "l4d2_auto_aim");
}

// 新增命令：快速查看当前配置
Action Command_ZiMiao(int client, int args)
{
    if (!IsClientValid(client))
    {
        ReplyToCommand(client, "[Auto-Aim] You must be a valid player to use this command.");
        return Plugin_Handled;
    }
    
    if (!IsSurvivor(client))
    {
        ReplyToCommand(client, "[Auto-Aim] You must be a survivor to use auto-aim.");
        return Plugin_Handled;
    }
    
    // 显示当前配置状态
    ReplyToCommand(client, "[Auto-Aim] Current Settings:");
    ReplyToCommand(client, "- Common Infected Aim: %s", GetConVarBool(aimCommonInfected) ? "ENABLED" : "DISABLED");
    ReplyToCommand(client, "- Special Infected Aim: %s", GetConVarBool(aimSpecialInfected) ? "ENABLED" : "DISABLED");
    ReplyToCommand(client, "- Mode: %s", GetConVarInt(mode) == 0 ? "Normal" : "Spin Bot");
    ReplyToCommand(client, "- Angle Limit: %.1f degrees", GetConVarFloat(angleLimit));
    
    int time = 3600; // 60分钟 = 3600秒
    
    if(GetConVarBool(needPrintTip))
    {   
        if(StrEqual(LANGUAGE, "CHI", false))
        {
            PrintHintTextToAll("%N 开启了自瞄 (60分钟)", client);
        }
        else
        {
            PrintHintTextToAll("%N Turn On Auto-Aim (60 minutes)", client);
        }
    }
    
    if(durations[client] > 0)
    {
        durations[client] += time;
        ReplyToCommand(client, "[Auto-Aim] Auto-aim duration extended by 60 minutes. Total duration: %d seconds.", durations[client]);
    }
    else
    {
        durations[client] = time;
        timers[client] = CreateTimer(1.0, CountDown, client, TIMER_REPEAT);
        ReplyToCommand(client, "[Auto-Aim] Auto-aim enabled for 60 minutes.");
    }
    
    return Plugin_Handled;
}

// 原有的sm_autoaim命令处理函数
Action Command_AutoAim(int client, int args)
{
    if (args < 2)
    {
        // 显示使用方法和当前状态
        ReplyToCommand(client, "[Auto-Aim] Usage: sm_autoaim <#userid|name> <time in seconds>");
        ReplyToCommand(client, "[Auto-Aim] Current CI Aim: %s", GetConVarBool(aimCommonInfected) ? "ENABLED" : "DISABLED");
        ReplyToCommand(client, "[Auto-Aim] Config: l4d2_auto_aim_ci_enable 0/1");
        return Plugin_Handled;
    }
    
    char arg1[32], arg2[32];
    GetCmdArg(1, arg1, sizeof(arg1));
    GetCmdArg(2, arg2, sizeof(arg2));
    
    int time = StringToInt(arg2);
    if (time <= 0)
    {
        ReplyToCommand(client, "[Auto-Aim] Time must be a positive number.");
        return Plugin_Handled;
    }
    
    char target_name[MAX_TARGET_LENGTH];
    int target_list[MAXPLAYERS], target_count;
    bool tn_is_ml;
    
    if ((target_count = ProcessTargetString(
            arg1,
            client,
            target_list,
            MAXPLAYERS,
            COMMAND_FILTER_CONNECTED,
            target_name,
            sizeof(target_name),
            tn_is_ml)) <= 0)
    {
        ReplyToTargetError(client, target_count);
        return Plugin_Handled;
    }
    
    for (int i = 0; i < target_count; i++)
    {
        int player = target_list[i];
        if (!IsSurvivor(player))
            continue;
            
        if(GetConVarBool(needPrintTip))
        {   
            if(StrEqual(LANGUAGE, "CHI", false))
            {
                PrintHintTextToAll("%N 开启了自瞄 (%d秒)", player, time);
            }
            else
            {
                PrintHintTextToAll("%N Turn On Auto-Aim (%d seconds)", player, time);
            }
        }
        
        if(durations[player] > 0)
        {
            durations[player] += time;
        }
        else
        {
            durations[player] = time;
            timers[player] = CreateTimer(1.0, CountDown, player, TIMER_REPEAT);
        }
    }
    
    if (tn_is_ml)
    {
        ReplyToCommand(client, "[Auto-Aim] Auto-aim enabled for %t for %d seconds.", target_name, time);
    }
    else
    {
        ReplyToCommand(client, "[Auto-Aim] Auto-aim enabled for %s for %d seconds.", target_name, time);
    }
    
    // 显示当前普通感染者瞄准状态
    ReplyToCommand(client, "[Auto-Aim] Common Infected Aim: %s", GetConVarBool(aimCommonInfected) ? "ENABLED" : "DISABLED");
    
    return Plugin_Handled;
}

// 其余代码保持不变...
Action CountDown(Handle timer, int client)
{
    if(!IsClientValid(client))
    {
        return Plugin_Stop;
    }
    durations[client]--;
    if(durations[client] <= 0)
    {
        return Plugin_Stop;
    }
    return Plugin_Continue;
}

public void OnEntityCreated(int entity, const char[] classname)
{
    // 这里已经使用了aimCommonInfected ConVar来控制是否追踪普通感染者
    if(StrEqual(classname, "infected", false) && GetConVarBool(aimCommonInfected))
    {
        SDKHook(EntIndexToEntRef(entity), SDKHook_SpawnPost, OnCommonCreatedPost);
    }
}

void OnCommonCreatedPost(int entityRef)
{
    SDKUnhook(entityRef, SDKHook_SpawnPost, OnCommonCreatedPost);
    int entity = EntRefToEntIndex(entityRef);
    if(!IsValidEntity(entity))
        return;

    AddToMap(entity, 2);
}

public void OnWeaponFire(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(!IsSurvivor(client))
        return;
    if(durations[client] <= 0)
        return;
    
    char weaponName[32];
    GetEventString(event, "weapon", weaponName, 32);
    if(!allowedWeapons.ContainsKey(weaponName))
        return;    

    // 获取玩家视角信息
    float eye[3];
    GetClientEyePosition(client, eye);
    float eyeAngle[3];
    GetClientEyeAngles(client, eyeAngle);
    float eyeDir[3];
    GetAngleVectors(eyeAngle, eyeDir, NULL_VECTOR, NULL_VECTOR);

    int closestTarget = -1;
    float minDistance = 999999999.0;
    float targetAngle[3];

    float pos[3];
    float dir[3];
    float angle[3];

    Handle trace = null;

    StringMapSnapshot shots = infecteds.Snapshot();
    char num[8];
    int type;

    for(int i = 0; i < shots.Length; i++)
    {
        shots.GetKey(i, num, 8);
        
        if(!infecteds.GetValue(num, type))
            continue;
            
        int entity = StringToInt(num);

        if(entity <= 0 || !IsValidEntity(entity))
        {
            RemoveFromMap(entity);
            continue;
        }
        
        bool isInfected = false;
        
        // 普通感染者处理（只有当aimCommonInfected为1时才处理）
        if(entity > MAXPLAYERS && IsCommonInfected(entity))
        {
            if(!GetConVarBool(aimCommonInfected)) // 再次检查配置
                continue;
                
            int curHp = GetEntProp(entity, Prop_Data, "m_iHealth");
            if(curHp <= 0)
                continue;
                
            if(!GetAttachmentVectors(entity, "forward", pos, dir))
            {
                GetAbsOrigin(entity, pos);
                pos[2] += 50.0;
            }
        }
        else if(IsInfected(entity))
        {
            if(!GetConVarBool(aimSpecialInfected)) // 检查特感配置
                continue;
                
            isInfected = true;
            int zombieClass = GetEntProp(entity, Prop_Send, "m_zombieClass");
            if(zombieClass == 8)
                GetClientEyePosition(entity, pos);
            else
                L4D_GetBonePosition(entity, L4D_GetZombieBone(entity, Bone_Head), pos);
        }
        else
        {
            RemoveFromMap(entity);
            continue;
        }

        MakeVectorFromPoints(eye, pos, dir);  
        if(GetConVarInt(mode) == 0)
        {
            if(GetAngleBetweenTwoDirection(eyeDir, dir) > GetConVarFloat(angleLimit))
                continue;
        }
        GetVectorAngles(dir, angle);
        if(!isInfected)
            trace = TR_TraceRayFilterEx(eye, angle, MASK_SHOT, RayType_Infinite, TraceFilterCommon, client);
        else
            trace = TR_TraceRayFilterEx(eye, angle, MASK_SHOT, RayType_Infinite, TraceFilterSpecial, client);
        if(trace == null)
            continue;
            
        if(TR_DidHit(trace))
        {
            float endPoint[3];
            TR_GetEndPosition(endPoint, trace);

            float originDis = GetVectorDistance(eye, pos);
            float hitDis = GetVectorDistance(eye, endPoint);
            if(FloatAbs(originDis - hitDis) < 15.0 && minDistance > hitDis)
            {
                closestTarget = entity;
                minDistance = hitDis;
                targetAngle[0] = angle[0];
                targetAngle[1] = angle[1];
                targetAngle[2] = angle[2];
            }
        }
        CloseHandle(trace);
    }
    CloseHandle(shots);
    
    if(closestTarget != -1)
    {
        TeleportEntity(client, NULL_VECTOR, targetAngle);
    }
}

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    if(!GetConVarBool(aimSpecialInfected))
        return;
    
    int infected = GetClientOfUserId(GetEventInt(event, "userid"));
    if(IsInfected(infected))
    {
        AddToMap(infected, 1);
    }
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int infected = GetClientOfUserId(GetEventInt(event, "userid"));
    if(IsInfected(infected))
    {
        RemoveFromMap(infected);
    }
}

public void OnInfectedDeath(Event event, const char[] name, bool dontBroadcast)
{
    // short	attacker	user ID who killed
    // short	infected_id	ID of the infected that died
    // short	gender	gender (type) of the infected
    // short	weapon_id	ID of the weapon used
    // bool	headshot	signals a headshot
    // bool	minigun	signals a minigun kill
    // bool	blast	signals a death from blast damage
    // bool	submerged	indicates the infected was submerged

    int infected = GetEventInt(event, "infected_id");
    RemoveFromMap(infected);
}

public void OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    for(int i = 1; i <= MAXPLAYERS; i++)
    {
        if(durations[i] > 0)
        {
            KillTimerSafety(timers[i]);
        }
        durations[i] = 0;
    }
    infecteds.Clear();
}

// !rcon sm plugins reload l4d2_auto_aim
void AddToMap(int entity, int headRefEntity)
{
    char num[8];
    Format(num, 8, "%d", entity);
    if(!infecteds.ContainsKey(num))
    {
        infecteds.SetValue(num, headRefEntity);
    }
}

void RemoveFromMap(int entity)
{
    char num[8];
    Format(num, 8, "%d", entity);
    if(infecteds.ContainsKey(num))
    {
        infecteds.Remove(num);
    }
}

public bool TraceFilterCommon(int entity, int contentsMask, int self)
{
    if(!IsCommonInfected(entity))
    {
        return false;
    }
    return true;
}

public bool TraceFilterSpecial(int entity, int contentsMask, int self)
{
    if(!IsInfected(entity))
    {
        return false;
    }
    return true;
}

stock float GetAngleBetweenTwoDirection(float a[3], float b[3])
{
    float modA = SquareRoot(a[0] * a[0] + a[1] * a[1] + a[2] * a[2]);
    float modB = SquareRoot(b[0] * b[0] + b[1] * b[1] + b[2] * b[2]);
    float dotProd = GetVectorDotProduct(a, b);
    float cos = dotProd / (modA * modB);
    return RadToDeg(ArcCosine(cos));
}

stock bool IsTank(int entity)
{
    if(IsInfected(entity))
    {
        return GetEntProp(entity, Prop_Send, "m_zombieClass") == 8;
    }
    return false;
}

stock void KillTimerSafety(Handle& timer)
{
    if(timer != null)
    {
        delete timer;
    }
    timer = null;
}

stock bool IsCommonInfected(int entity)
{
    if (entity > 0 && IsValidEntity(entity))
    {
        char classname[16];
        GetEntityClassname(entity, classname, 16);
        return StrEqual(classname, "infected", false);
    }
    return false;
}

stock bool IsClientValid(int client)
{
    return 1 <= client && client <= MaxClients && IsClientInGame(client);
}

stock bool IsRealClient(int client)
{
    return IsClientValid(client) && !IsFakeClient(client);
}

stock bool IsSurvivor(int client)
{
    return IsClientValid(client) && GetClientTeam(client) == TEAM_SURVIVOR;
}

stock bool IsInfected(int client)
{
    return IsClientValid(client) && GetClientTeam(client) == TEAM_INFECTED;
}