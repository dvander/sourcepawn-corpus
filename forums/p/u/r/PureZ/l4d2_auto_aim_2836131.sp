#define _english_version
#include <sourcemod>
#include <left4dhooks_lux_library>
#include <sdkhooks>
#include <sdktools>
#include <l4d_anim>

#define TEAM_SPECTATOR 1
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

public Plugin AutoAimPluginInfo =
{
    name = "Auto Aim",
    author = "Pure_*",
    description = "Allows player auto aim to SI immediately",
    version = "0.5",
    url = ""
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

    RegAdminCmd("sm_autoaim", Command_AutoAim, ADMFLAG_SLAY);
    RegAdminCmd("sm_quitaa", Command_QuitAutoAim, ADMFLAG_SLAY);

    HookEvent("player_spawn", OnPlayerSpawn);
    HookEvent("player_death", OnPlayerDeath);
    HookEvent("infected_death", OnInfectedDeath);
    HookEvent("weapon_fire", OnWeaponFire);
    HookEvent("round_end", OnRoundEnd);
    HookEvent("finale_win", OnRoundEnd);
    HookEvent("mission_lost", OnRoundEnd);
    HookEvent("map_transition", OnRoundEnd);

    mode = CreateConVar("l4d2_auto_aim_mode", "0", "Auto-Aim mode, 0 is nomal mode, 1 is Spin Bot mode", 0, true, 0.0, true, 1.0);
    angleLimit = CreateConVar("l4d2_auto_aim_limited_angle", "45.0", "Only use when mode is 0, the angle between the player's line of sight and the enemy's head", 0, true, 45.0, true, 89.0);
    needPrintTip = CreateConVar("l4d2_auto_aim_need_print_tip", "1", "Need to print who turn on auto-aim to all player? 0 = No, 1 = Yes", 0, true, 0.0, true, 1.0);
    aimCommonInfected = CreateConVar("l4d2_auto_aim_ci_enable", "1", "Auto aim common infected?(0=disable, 1=enable)");
    aimSpecialInfected = CreateConVar("l4d2_auto_aim_si_enable", "1", "Auto aim special infected?(0=disable, 1=enable)");
    
    AutoExecConfig(true, "l4d2_auto_aim");
    
}

Action Command_QuitAutoAim(int client, int args)
{    
    if(durations[client] > 0)
    {
        KillTimerSafety(timers[client]);
        durations[client] = 0;
    }
    return Plugin_Continue;
}

Action Command_AutoAim(int client, int args)
{
    int player = GetCmdArgInt(1);
    int time = GetCmdArgInt(2);
    if(GetConVarBool(needPrintTip))
    {   
        // There is only one phrases, it's not essential to make translation file
        #if defined _english_version
        PrintHintTextToAll("%N Turn On Auto-Aim", player);
        #else
        PrintHintTextToAll("%N 开启了自瞄", player);
        #endif
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
    return Plugin_Continue;
}

Action CountDown(Handle timer, int client)
{
    if(!IsClientValid(client))
    {
        timers[client] = null;
        durations[client] = 0;
        return Plugin_Stop;
    }
    durations[client]--;
    if(durations[client] <= 0)
    {
        timers[client] = null;
        return Plugin_Stop;
    }
    return Plugin_Continue;
}

public void OnEntityCreated(int entity, const char[] classname)
{
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
        return

    AddToMap(entity, 2);
}

public void OnWeaponFire(Event event, const char[] name, bool dontBroadcast)
{
    // 1	local	don't network this, its way too spammy
    // short	userid	
    // string	weapon	used weapon name
    // short	weaponid	used weapon ID
    // short	count	number of bullets
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(!IsSurvivor(client))
        return;
    if(durations[client] <= 0)
        return;
    
    char weaponName[32];
    GetEventString(event, "weapon", weaponName, 32);
    if(!allowedWeapons.ContainsKey(weaponName))
        return;

    // Get player's Transform
    float eye[3];
    GetClientEyePosition(client, eye);
    float eyeAngle[3];
    GetClientEyeAngles(client, eyeAngle);
    float eyeDir[3];
    GetAngleVectors(eyeAngle, eyeDir, NULL_VECTOR, NULL_VECTOR);

    int closestTarget = -1;
    float minDistance = 999999999.0;   // I think this is an impossible distance in every map
    float targetAngle[3];    // eye angle of player use to aim target

    float pos[3];    // infected head position
    float dir[3];    // Vector: player -> infected
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
        // 获取位置
        // !rcon sm plugins reload l4d2_auto_aim
        if(entity > MAXPLAYERS && IsCommonInfected(entity))
        {
             // In case to
            int curHp = GetEntProp(entity, Prop_Data, "m_iHealth");
            if(curHp <= 0)
                continue;
            // Common Infected Head Attachment
            if(!GetAttachmentVectors(entity, "forward", pos, dir))
            {
                GetAbsOrigin(entity, pos);
                pos[2] += 50.0;
            }
        }
        else if(IsInfected(entity))
        {
            isInfected = true;
            int zombieClass = GetEntProp(entity, Prop_Send, "m_zombieClass");
            if(zombieClass == 8)
                GetClientEyePosition(entity, pos);  // Tank does not have head
            else
                L4D_GetBonePosition(entity, L4D_GetZombieBone(entity, Bone_Head), pos);
        }
        else
        {
            RemoveFromMap(entity);
            continue;
        }

        MakeVectorFromPoints(eye, pos, dir);  
        // Nomal Mode needs to check angle
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
            if(FloatAbs(originDis - hitDis) < 15.0 && minDistance > hitDis)  // distance tolerance
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
    // Turn player to aim target
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