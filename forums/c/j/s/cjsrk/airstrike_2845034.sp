#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
// #include <HanZombieScenarioAPI>                    // 增加对大灾变插件命中NPC的支持

#define PLUGIN_VERSION "1.0"
#define GREEN_SMOKE_DURATION 18.0    // 信号持续时间（默认烟雾弹烟雾也是持续18秒）
#define Received_DELAY 5.0    // 指挥中心收到信号并回复玩家的时间间隔
#define MISSILE_DELAY 15.0    // 信号弹爆炸后多久生成导弹，理论上其值应该小于信号持续时间，且其值+5应该大于信号持续时间
#define MISSILE_SPEED 5000.0    // 导弹飞行速度
#define FLY_TICK_INTERVAL 0.02
#define EXPLODE_SOUND "ambient/fire/mtov_flame2.wav"

int g_iAirstrikeCount[MAXPLAYERS+1];
bool g_bRoundActive;
ArrayList g_hActiveMissiles;

// 全局数组，记录购买前烟雾弹数量
int g_iSmokeBefore[MAXPLAYERS+1];

// 导弹模型
char g_sMissileModel[] = "models/weapons/w_airstrike_missile.mdl";

// Cvars
ConVar g_cvEnable;
ConVar g_cvSmokeWeapon;
ConVar g_cvDamage;
ConVar g_cvRadius;
ConVar g_cvType;
ConVar g_cvMaxPerRound;
ConVar g_cvPrice;

static bool:cvIsEnabled;    //  启动或禁用插件变量
static char cvSmokeWeapon[32];    //应用空袭信号弹功能的武器（必须为烟雾弹或者以烟雾弹为父类的新武器）
static int cvDamage = 0;    //  空袭爆炸伤害
static int cvRadius = 0;    //  空袭爆炸半径
static int cvType = 0;    //  信号弹种类，0为发出绿色烟雾，1为类似信号棒发出红光且不断闪烁
static int cvMaxPerRound = 0;    //  每回合最多购买次数
static int cvPrice = 0;    //  购买一次空袭信号弹的价格

public Plugin myinfo =
{
    name = "Airstrike Smoke Grenade",
    author = "cjsrk, Based on homingmissiles2 & snoweffects",
    description = "Use the smoke bomb as a signal flare and, 20 seconds later, summon a missile strike.",
    version = PLUGIN_VERSION,
    url = ""
};

public void OnPluginStart()
{
    LoadTranslations("common.phrases");
    
    CreateConVar("sm_airstrike_version", "1.0.0", "Plugin version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    g_cvEnable = CreateConVar("sm_airstrike_enable", "1", "Whether to enable the plugin (1: Enable; 0: Disable)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvSmokeWeapon = CreateConVar("sm_airstrike_weapon", "weapon_smokegrenade", "Set the weapon to which the air strike flare function is applied (must be smoke grenade or a new weapon with smoke grenade as the parent).", FCVAR_NOTIFY);
    g_cvDamage = CreateConVar("sm_airstrike_damage", "1000", "Air strike explosion damage", FCVAR_NOTIFY, true, 1.0, true, 10000.0);
    g_cvRadius = CreateConVar("sm_airstrike_radius", "1200", "Air wtrike explosion radius", FCVAR_NOTIFY, true, 1.0, true, 5000.0);
    g_cvType = CreateConVar("sm_airstrike_type", "0", "Types of signal flares for air strikes (0: emits green smoke, 1: similar to a signal stick, emits red light and keeps flashing)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvMaxPerRound = CreateConVar("sm_airstrike_max_per_round", "2", "The maximum number of purchases that players can make per round. If the limit is exceeded, no air strike will be triggered.", FCVAR_NOTIFY, true, 1.0, true, 5.0);
    g_cvPrice = CreateConVar("sm_airstrike_price", "2000", "The price of buy an air raid signal flare (only available when the signal flare is replacing the smoke grenade)", FCVAR_NOTIFY, true, 0.0, true, 15000.0);
    
    AutoExecConfig(true, "plugin.airstrike");
    HookConVarChange(g_cvEnable, CvarChange);
    HookConVarChange(g_cvSmokeWeapon, CvarChange);
    HookConVarChange(g_cvDamage, CvarChange);
    HookConVarChange(g_cvRadius, CvarChange);
    HookConVarChange(g_cvType, CvarChange);
    HookConVarChange(g_cvMaxPerRound, CvarChange);
    HookConVarChange(g_cvPrice, CvarChange);
    
    HookEvent("round_start", Event_RoundStart);
    HookEvent("round_end", Event_RoundEnd);
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("smokegrenade_detonate", Event_SmokeDetonate, EventHookMode_Pre);
    AddNormalSoundHook(Event_SmokeSound);
    
    g_hActiveMissiles = new ArrayList();
    
    g_bRoundActive = false;
}

public void OnMapStart()
{
    PrecacheModel(g_sMissileModel, true);
    PrecacheSound(EXPLODE_SOUND);
    PrecacheSound("weapons/explode3.wav");
    PrecacheSound("weapons/explode4.wav");
    PrecacheSound("weapons/explode5.wav");
    PrecacheSound("weapons/missile/c4_explode1.wav");
    PrecacheSound("weapons/missile/missile_fly.wav");
    PrecacheSound("weapons/missile/air_raid_warning.wav");
    PrecacheSound("weapons/missile/sign.wav");
    
    AddFileToDownloadsTable("models/weapons/w_airstrike_missile.mdl");
    AddFileToDownloadsTable("models/weapons/w_airstrike_missile.phy");
    AddFileToDownloadsTable("models/weapons/w_airstrike_missile.vvd");
    AddFileToDownloadsTable("models/weapons/w_airstrike_missile.dx80.vtx");
    AddFileToDownloadsTable("models/weapons/w_airstrike_missile.dx90.vtx");
    AddFileToDownloadsTable("models/weapons/w_airstrike_missile.sw.vtx");
    AddFileToDownloadsTable(EXPLODE_SOUND);
    AddFileToDownloadsTable("weapons/missile/c4_explode1.wav");
    AddFileToDownloadsTable("weapons/missile/missile_fly.wav");
    AddFileToDownloadsTable("weapons/missile/air_raid_warning.wav");
    AddFileToDownloadsTable("weapons/missile/sign.wav");
}

//读取配置文件的cvar的值
public OnConfigsExecuted()
{
    cvIsEnabled = GetConVarBool(g_cvEnable);
    cvDamage = GetConVarInt(g_cvDamage);
    cvRadius = GetConVarInt(g_cvRadius);
    cvType = GetConVarBool(g_cvType);
    cvMaxPerRound = GetConVarInt(g_cvMaxPerRound);
    cvPrice = GetConVarInt(g_cvPrice);
    GetConVarString(g_cvSmokeWeapon, cvSmokeWeapon, sizeof(cvSmokeWeapon));
}

//cvar值变化时的响应数组
public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
    if(convar == g_cvEnable)
    {
        if(StringToInt(newValue) == 1)
        {
            cvIsEnabled = true;
        }
        else
        {
            cvIsEnabled = false;
        }
    }
    if(convar == g_cvSmokeWeapon)
    {
        if(strlen(newValue) > 0 && !StrEqual("", newValue))
        {
            strcopy(cvSmokeWeapon, strlen(newValue) + 1, newValue);     
        }
    }
    if(convar == g_cvDamage)
    {
        if(StringToInt(newValue) < 1)
            cvDamage = 1;
        else if(StringToInt(newValue) > 10000)
            cvDamage = 10000;
        else
            cvDamage = StringToInt(newValue);
    }
    if(convar == g_cvRadius)
    {
        if(StringToInt(newValue) < 1)
            cvRadius = 1;
        else if(StringToInt(newValue) > 5000)
            cvRadius = 5000;
        else
            cvRadius = StringToInt(newValue);
    }
    if(convar == g_cvType)
    {
        if(StringToInt(newValue) == 1)
        {
            cvType = 1;
        }
        else
        {
            cvType = 0;
        }
    }
    if(convar == g_cvMaxPerRound)
    {
        if(StringToInt(newValue) < 1)
            cvMaxPerRound = 1;
        else if(StringToInt(newValue) > 5)
            cvMaxPerRound = 5;
        else
            cvMaxPerRound = StringToInt(newValue);
    }
    if(convar == g_cvPrice)
    {
        if(StringToInt(newValue) < 0)
            cvPrice = 0;
        else if(StringToInt(newValue) > 15000)
            cvPrice = 15000;
        else
            cvPrice = StringToInt(newValue);
    }
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
    g_iAirstrikeCount[client] = 0;
}

public void OnClientDisconnect(int client)
{
    g_iAirstrikeCount[client] = 0;
}

public void Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
    g_bRoundActive = true;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            // g_iAirstrikeCount[i] = 0;
            // g_iSmokeBefore[i] = 0;
        }    
    }
    
    KillAllActiveMissiles();
}

public void Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
    g_bRoundActive = false;
    KillAllActiveMissiles();
}

public void Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (client && IsClientInGame(client) && !IsFakeClient(client))
    {
        g_iAirstrikeCount[client] = 0;
        g_iSmokeBefore[client] = 0;    // 先清零
        CountPlayerSmokeWeapons(client);                 // 重新统计持有投掷物
    }
}

void CountPlayerSmokeWeapons(int client)
{
    if (!IsClientInGame(client)) return;
    
    int count = 0;
    int weapons = GetEntPropArraySize(client, Prop_Data, "m_hMyWeapons");
    for (int i = 0; i < weapons; i++)
    {
        int weapon = GetEntPropEnt(client, Prop_Data, "m_hMyWeapons", i);
        if (weapon == -1) continue;
        
        char sWeapon[32];
        GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));
        if (StrEqual(sWeapon, cvSmokeWeapon))
            count++;
    }
    
    if (count > cvMaxPerRound)
        count = cvMaxPerRound;
    
    g_iAirstrikeCount[client] = count;
    if( g_iAirstrikeCount[client] > 0)
    {
        int RemainingCount = cvMaxPerRound - g_iAirstrikeCount[client];
        if (RemainingCount < 0) RemainingCount = 0;
        PrintToChat(client, " \x04[Air Strike]\x01 You already have an airstrike flare! (Remaining purchases this round: %d) Throw it to call in an airstrike, arriving in 20 seconds.", RemainingCount);
    }
}

public void Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
    new victim = GetClientOfUserId(GetEventInt(event, "userid"));
    g_iAirstrikeCount[victim] = 0;
    g_iSmokeBefore[victim] = 0;
}

// 如果应用空袭信号弹功能的武器是通过加强插件添加的新烟雾弹
public Action OnWeaponEquip(client, weapon)
{
    if(cvIsEnabled == false)
        return Plugin_Continue;
    
    if (!client || !IsClientInGame(client) || IsFakeClient(client))
    {
        return Plugin_Continue;
    }
    
    decl String:sWeapon[32];
    GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));
    if(!StrEqual("weapon_smokegrenade", cvSmokeWeapon) && StrEqual(sWeapon, cvSmokeWeapon))
    {
        // 检查是否已达到本回合购买上限
        if (g_iAirstrikeCount[client] >= cvMaxPerRound)
        {
            PrintToChat(client, " \x04[Air Strike]\x01 You have already purchased %d airstrike flares this round (limit: %d), so you cannot buy this ammunition any more!", g_iAirstrikeCount[client], cvMaxPerRound);
            return Plugin_Stop; // 阻止购买
        }

        // 记录购买前的烟雾弹数量（弹药类型索引12为烟雾弹）
        g_iSmokeBefore[client] = GetEntProp(client, Prop_Send, "m_iAmmo", 4, 12);
        
        // 未达上限，开始延迟验证（确保武器真正被玩家持有）
        CreateTimer(0.1, Timer_VerifyWeapon, client, TIMER_FLAG_NO_MAPCHANGE);

        return Plugin_Continue;
    }
    return Plugin_Continue;
}

public Action Timer_VerifyWeapon(Handle timer, int client)
{
    if (!client || !IsClientInGame(client))
        return Plugin_Stop;

    int current = GetEntProp(client, Prop_Send, "m_iAmmo", 4, 12);
    if (current > g_iSmokeBefore[client])
    {
        // 验证通过，增加计数（再次检查上限，防止期间被其他操作修改）
        if (g_iAirstrikeCount[client] >= cvMaxPerRound)
        {
            g_iAirstrikeCount[client]++;
            PrintToChat(client, " \x04[Air Strike]\x01 You have already purchased %d airstrike flares this round (limit: %d), so this one cannot call in an airstrike!", g_iAirstrikeCount[client], cvMaxPerRound);
            return Plugin_Continue;
        }
        
        // 验证通过
        g_iAirstrikeCount[client]++;
        
        int RemainingCount = cvMaxPerRound - g_iAirstrikeCount[client];
        if (RemainingCount < 0) RemainingCount = 0;
        PrintToChat(client, " \x04[Air Strike]\x01 Airstrike flare purchased successfully! (Remaining purchases this round: %d) Throw it to call in an airstrike, arriving in 20 seconds.", RemainingCount);
    }

    return Plugin_Continue;
}

// 如果应用空袭信号弹功能的武器只是替换了原版烟雾弹
public Action CS_OnBuyCommand(int client, const char[] weapon)
{
    if(cvIsEnabled == false)
        return Plugin_Continue;
    
    if(StrEqual("smokegrenade", weapon, false) == false)
        return Plugin_Continue;
    
    if (!client || !IsClientInGame(client) || IsFakeClient(client))
    {
        return Plugin_Continue;
    }
    
    if(!StrEqual("weapon_smokegrenade", cvSmokeWeapon))
        return Plugin_Continue;
    
    if (!g_bRoundActive)
    {
        PrintToChat(client, " \x04[Air Strike]\x01 Round has not started, cannot purchase.");
        return Plugin_Handled;
    }
    
    if (g_iAirstrikeCount[client] >= cvMaxPerRound)
    {
        g_iAirstrikeCount[client]++;
        PrintToChat(client, " \x04[Air Strike]\x01 You have already purchased %d airstrike flares this round (limit: %d), so this one cannot call in an airstrike!", g_iAirstrikeCount[client], cvMaxPerRound);
        return Plugin_Continue;
    }
    
    int price = cvPrice;
    int money = GetEntProp(client, Prop_Send, "m_iAccount");
    if (money < price)
    {
        PrintToChat(client, " \x04[Air Strike]\x01 Insufficient funds, need $%d to purchase an airstrike flare.", price);
        return Plugin_Handled;
    }
    
    // 记录购买前的烟雾弹数量（弹药类型索引13为烟雾弹）
    g_iSmokeBefore[client] = GetEntProp(client, Prop_Send, "m_iAmmo", 4, 12);
    
    // 延迟检查购买是否成功
    CreateTimer(0.1, Timer_CheckSmokePurchase, client, TIMER_FLAG_NO_MAPCHANGE);
    
    // 让游戏正常处理购买
    return Plugin_Continue;
}

public Action Timer_CheckSmokePurchase(Handle timer, int client)
{
    if (!client || !IsClientInGame(client))
        return Plugin_Continue;
    
    int current = GetEntProp(client, Prop_Send, "m_iAmmo", 4, 12);
    if (current > g_iSmokeBefore[client])
    {
        int price = cvPrice;
        int money = GetEntProp(client, Prop_Send, "m_iAccount");
        
        // 购买成功
        SetEntProp(client, Prop_Send, "m_iAccount", money - price + 300);
        g_iAirstrikeCount[client]++;
        
        int RemainingCount = cvMaxPerRound - g_iAirstrikeCount[client];
        if(RemainingCount < 0)
            RemainingCount = 0;
        PrintToChat(client, " \x04[Air Strike]\x01 Airstrike flare purchased successfully! (Remaining purchases this round: %d) Throw it to call in an airstrike, arriving in 20 seconds.", RemainingCount);
    }
    // 如果数量未增加，说明购买被游戏阻止（如已达上限），不计数，也不扣钱（游戏已处理）
    return Plugin_Continue;
}

public void OnEntityCreated(int entity, const char[] classname)
{   
    if(cvIsEnabled == false)
        return;
    
    if (StrEqual(classname, "smokegrenade_projectile"))
    {
        CreateTimer(0.01, OnSmokeProjectileSpawn, entity);
    }
}

public Action OnSmokeProjectileSpawn(Handle timer, int entity)
{
    if(cvIsEnabled == false)
        return Plugin_Continue;
    
    if (!g_bRoundActive) 
        return Plugin_Continue;
    
    if(HasEntProp(entity, Prop_Send, "m_hThrower") == false)
        return Plugin_Continue;
    
    int owner = GetEntPropEnt(entity, Prop_Send, "m_hThrower");
    if (owner < 1 || owner > MaxClients)
        return Plugin_Continue;
    if (!IsClientInGame(owner) || IsFakeClient(owner))
        return Plugin_Continue;
    
    if(HasEntProp(owner, Prop_Send, "m_hActiveWeapon") == false)
        return Plugin_Continue;
    new currentWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
    if (!IsValidEdict(currentWeapon) || (currentWeapon == -1))
        return Plugin_Continue;
    decl String:sWeapon[64];
    GetEntityClassname(currentWeapon, sWeapon, sizeof(sWeapon));
    if(StrEqual(sWeapon, cvSmokeWeapon))
    {
        if (g_iAirstrikeCount[owner] > 0 && g_iAirstrikeCount[owner] <= cvMaxPerRound)
        {
            // 标记这个烟雾弹为空袭专用
            SetEntProp(entity, Prop_Send, "m_nSkin", 1);
            // PrintToChat(owner, " \x04[Air Strike]\x01 你投掷了空袭信号弹，剩余 %d 次可用。", cvMaxPerRound - g_iAirstrikeCount[owner]);
        }
    }
    return Plugin_Continue;
}

public void Event_SmokeDetonate(Handle event, const char[] name, bool dontBroadcast)
{
    if(cvIsEnabled == false)
        return;
    
    if (!g_bRoundActive) return;
    
    int userid = GetEventInt(event, "userid");
    int client = GetClientOfUserId(userid);
    if (!client) 
        return;
    if (!IsClientInGame(client))
        return;
    
    float pos[3];
    pos[0] = GetEventFloat(event, "x");
    pos[1] = GetEventFloat(event, "y");
    pos[2] = GetEventFloat(event, "z");
    
    // 找到对应的 projectile 实体
    int projectile = -1;
    float closestDist = 100.0;
    int ent = -1;
    while ((ent = FindEntityByClassname(ent, "smokegrenade_projectile")) != -1)
    {
        float org[3];
        GetEntPropVector(ent, Prop_Send, "m_vecOrigin", org);
        float dist = GetVectorDistance(pos, org);
        if (dist < closestDist)
        {
            closestDist = dist;
            projectile = ent;
        }
    }
 
    if (projectile == -1) return;
    
    // 读取标记 (m_nSkin 是否等于1)
    int isAirstrike = GetEntProp(projectile, Prop_Send, "m_nSkin");
    if (isAirstrike != 1) return;
    
    // 判断室外
    bool isOutdoor = IsOutdoorPosition(pos);
    
    if (!isOutdoor)
    {
        if(IsPlayerAlive(client))
        {
            // PrintToChat(client, " \x04[Air Strike]\x01 信号弹在室内爆炸，无法召唤空中打击！");
            PrintHintText(client, "Flare detonated indoors, signal strength insufficient, cannot call in an airstrike!");
            EmitSoundToClient(client,"UI/hint.wav", client, SNDCHAN_VOICE);
            
            if(cvType == 1)
            {
                RemoveDefaultSmoke(pos);
                CreateGreenSmoke(pos, GREEN_SMOKE_DURATION);
            }
        }
        return;
    }
    
    // 移除原默认烟雾
    if(cvType == 1)
    {
        RemoveDefaultSmoke(pos);
        // 杀死 projectile 以彻底停止发烟声音
        if (IsValidEntity(projectile))
            AcceptEntityInput(projectile, "Kill");
    }
    
    // 创建绿色烟雾（持续18秒）或者红色闪光
    CreateGreenSmoke(pos, GREEN_SMOKE_DURATION);
    
    if (isOutdoor)
    {
        // 使用 DataPack 传递爆炸位置和投掷者
        DataPack pack = new DataPack();
        pack.WriteFloat(pos[0]);
        pack.WriteFloat(pos[1]);
        pack.WriteFloat(pos[2]);
        pack.WriteCell(client);
        CreateTimer(MISSILE_DELAY, Timer_LaunchMissile, pack, TIMER_FLAG_NO_MAPCHANGE);
        
        if(IsPlayerAlive(client))
        {
            // PrintToChat(client, " \x04[Air Strike]\x01 空中打击将在20秒后到达，请注意避险！");
            PrintHintText(client, "Airstrike arriving in 20 seconds, take cover!");
            EmitSoundToClient(client,"UI/hint.wav", client, SNDCHAN_VOICE);
            CreateTimer(Received_DELAY, Timer_VoiceTip, client);
        }
    }
}

bool IsOutdoorPosition(float pos[3])
{
    float end[3];
    end[0] = pos[0];
    end[1] = pos[1];
    end[2] = pos[2] + 10000.0;
    
    TR_TraceRayFilter(pos, end, MASK_SOLID, RayType_EndPoint, TraceFilter_IgnoreNothing);
    if (TR_DidHit())
    {
        char surfName[256];
        TR_GetSurfaceName(null, surfName, sizeof(surfName));
        if (StrContains(surfName, "SKYBOX", false) != -1)
            return true;
    }
    return false;
}

public bool TraceFilter_IgnoreNothing(int entity, int mask, any data)
{
    return false;
}

public Action Timer_VoiceTip(Handle timer, any client)
{
    if(!IsValidEntity(client) || client >= MAXPLAYERS)
        return Plugin_Continue;
    
    if (!g_bRoundActive)
        return Plugin_Continue;
    
    if(IsClientInGame(client))
        CreateTimer(6.5, Timer_MissileFlySound, client);    // 6.5 = 6（空袭语音时长） + 0.5
    
    if (!IsClientInGame(client) || !IsPlayerAlive(client))
        return Plugin_Continue;
    
    EmitSoundToClient(client,"weapons/missile/air_raid_warning.wav", client, SNDCHAN_VOICE);
    
    return Plugin_Continue;
}

public Action Timer_MissileFlySound(Handle timer, any client)
{
    if(!IsValidEntity(client) || client >= MAXPLAYERS)
        return Plugin_Continue;
    
    if (!IsClientInGame(client))
        return Plugin_Continue;
    
    if (!g_bRoundActive)
        return Plugin_Continue;
    
    // 计算声音起始位置
    float startPos[3];
    float ownerEye[3], ownerAng[3];
    GetClientEyePosition(client, ownerEye);
    GetClientEyeAngles(client, ownerAng);

    // 获取视线反方向向量
    float backVec[3];
    GetAngleVectors(ownerAng, backVec, NULL_VECTOR, NULL_VECTOR);
    ScaleVector(backVec, -1500.0); // 向后距离

    // 起始位置 = 投掷者位置 + 反方向偏移 + 高度
    startPos[0] = ownerEye[0] + backVec[0];
    startPos[1] = ownerEye[1] + backVec[1];
    startPos[2] = ownerEye[2] + 1000.0; // 向上高度
    
    EmitAmbientSound("weapons/missile/missile_fly.wav", startPos, client, SNDLEVEL_NORMAL, _ , 1.0);
    
    return Plugin_Continue;
}

// 消除原有烟雾
void RemoveDefaultSmoke(float pos[3])
{
    int ent = -1;
    while ((ent = FindEntityByClassname(ent, "env_particlesmokegrenade")) != -1)
    {
        float org[3];
        GetEntPropVector(ent, Prop_Send, "m_vecOrigin", org);
        if (GetVectorDistance(pos, org) < 200.0)
        {
            AcceptEntityInput(ent, "Kill");
        }
    }
    ent = -1;
    while ((ent = FindEntityByClassname(ent, "info_particle_system")) != -1)
    {
        float org[3];
        GetEntPropVector(ent, Prop_Send, "m_vecOrigin", org);
        if (GetVectorDistance(pos, org) < 200.0)
        {
            char effect[64];
            GetEntPropString(ent, Prop_Data, "m_EffectName", effect, sizeof(effect));
            if (StrContains(effect, "smoke", false) != -1)
                AcceptEntityInput(ent, "Kill");
        }
    }
}

void CreateGreenSmoke(float pos[3], float duration)
{
    // 主要烟雾效果
    if(cvType == 0)    // 发出绿色烟雾
    {
        int light = CreateEntityByName("light_dynamic");
        if (light != -1)
        {
            // 设置光源的基础属性
            DispatchKeyValue(light, "inner_cone", "0");
            DispatchKeyValue(light, "cone", "0");
            DispatchKeyValue(light, "brightness", "5"); // 亮度，1-10
            DispatchKeyValue(light, "distance", "300"); // 光照距离
            DispatchKeyValueFloat(light, "spotlight_radius", 250.0); // 聚光灯半径
            
            // 设置颜色为绿色 (RGB: 0, 255, 0)
            DispatchKeyValue(light, "_light", "73 135 105 255");
            
            // 允许它被关闭
            DispatchKeyValue(light, "spawnflags", "1");
            
            // 生成并激活实体
            DispatchSpawn(light);
            TeleportEntity(light, pos, NULL_VECTOR, NULL_VECTOR);
            ActivateEntity(light);
            AcceptEntityInput(light, "TurnOn");
            
            // 设置定时器在烟雾消散时关闭并移除光源
            // 原版烟雾持续时间约为 18 秒
            CreateTimer(duration, Timer_RemoveLight, EntIndexToEntRef(light));
        }
    }
    else    // 类似信号棒发出红光且不断闪烁
    {
        // ===== 替换为红色信号棒闪烁光源 =====
        // 创建红色闪烁光球（env_sprite）
        int sprite = CreateEntityByName("env_sprite");
        if (sprite != -1)
        {
            DispatchKeyValue(sprite, "model", "sprites/glow01.vmt");   // 游戏自带，无需下载
            DispatchKeyValue(sprite, "rendermode", "5");               // 叠加发光
            DispatchKeyValue(sprite, "rendercolor", "255 0 0");
            DispatchKeyValue(sprite, "renderamt", "255");
            DispatchKeyValue(sprite, "scale", "0.1");                  // 大小，可调
            DispatchSpawn(sprite);
            TeleportEntity(sprite, pos, NULL_VECTOR, NULL_VECTOR);
            ActivateEntity(sprite);

            // 0.05秒切换一次亮灭（TIMER_REPEAT）
            CreateTimer(0.05, Timer_Blink, EntIndexToEntRef(sprite), TIMER_REPEAT);
            
            // ---- 新增：播放“滴”声定时器 ----
            // 使用 DataPack 传递 sprite 引用和声音路径
            DataPack pack4 = new DataPack();
            pack4.WriteCell(EntIndexToEntRef(sprite));
            pack4.WriteFloat(pos[0]);
            pack4.WriteFloat(pos[1]);
            pack4.WriteFloat(pos[2]);
            CreateTimer(1.5, Timer_PlayBeep, pack4, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
            
            // 18秒后移除
            CreateTimer(duration, Timer_RemoveSprite, EntIndexToEntRef(sprite));
        }
    }
}

public Action Timer_RemoveLight(Handle timer, int ref) 
{
    int light = EntRefToEntIndex(ref);
    if (light != INVALID_ENT_REFERENCE && IsValidEntity(light)) {
        AcceptEntityInput(light, "TurnOff");
        AcceptEntityInput(light, "Kill");
    }
    return Plugin_Continue;
}

public Action Timer_Blink(Handle timer, int ref)
{
    int sprite = EntRefToEntIndex(ref);
    if (sprite == INVALID_ENT_REFERENCE || !IsValidEntity(sprite))
        return Plugin_Stop;

    float time = GetGameTime();
    // 1.5 秒一个完整亮灭周期
    float sinVal = Sine(time * (2.0 * FLOAT_PI / 0.7));
    // 映射到 0~255，最低亮度留 30 避免完全消失
    int brightness = RoundFloat(30.0 + (sinVal + 1.0) * 0.5 * 225.0);
    if (brightness < 0) brightness = 0;
    if (brightness > 255) brightness = 255;

    // 叠加模式下只用 RGB，alpha 无效，但保险起见都设上
    SetEntityRenderMode(sprite, RENDER_TRANSADD);
    SetEntityRenderColor(sprite, brightness, 0, 0, 255);
    return Plugin_Continue;
}

public Action Timer_PlayBeep(Handle timer, DataPack pack4)
{
    // 重置 DataPack 读取位置
    pack4.Reset();
    int ref = pack4.ReadCell();
    float pos[3];
    pos[0] = pack4.ReadFloat();
    pos[1] = pack4.ReadFloat();
    pos[2] = pack4.ReadFloat();

    // 检查信号棒是否仍然存在
    int sprite = EntRefToEntIndex(ref);
    if (sprite == INVALID_ENT_REFERENCE || !IsValidEntity(sprite))
    {
        // 信号棒已消失，停止定时器并关闭 DataPack
        CloseHandle(pack4);
        return Plugin_Stop;
    }

    // 播放“滴”声（附着在信号棒实体上，声音从信号棒位置发出）
    EmitAmbientSound( "weapons/missile/sign.wav", pos, sprite, SNDLEVEL_NORMAL, _ , 1.0);

    return Plugin_Continue;
}

public Action Timer_RemoveSprite(Handle timer, int ref)
{
    int sprite = EntRefToEntIndex(ref);
    if (sprite != INVALID_ENT_REFERENCE && IsValidEntity(sprite))
    {
        // 停止所有附着在该实体上的声音（避免残留）
        StopSound(sprite, SNDCHAN_AUTO, "weapons/missile/sign.wav");
        AcceptEntityInput(sprite, "Kill");
    }
    return Plugin_Stop;
}

public Action Timer_RemoveEntity(Handle timer, any ent)
{
    if (IsValidEntity(ent))
        AcceptEntityInput(ent, "Kill");
    return Plugin_Stop;
}

public Action Timer_LaunchMissile(Handle timer, DataPack pack)
{
    pack.Reset();
    float targetPos[3];
    targetPos[0] = pack.ReadFloat();
    targetPos[1] = pack.ReadFloat();
    targetPos[2] = pack.ReadFloat();
    int owner = pack.ReadCell();
    CloseHandle(pack);
    
    if (!g_bRoundActive) return Plugin_Stop;
    // if (!IsClientInGame(owner) || !IsPlayerAlive(owner)) return Plugin_Stop;
    if (!IsClientInGame(owner)) return Plugin_Stop;
    
    // 计算导弹起始位置：投掷者背后高空
    float startPos[3];
    float ownerEye[3], ownerAng[3];
    GetClientEyePosition(owner, ownerEye);
    GetClientEyeAngles(owner, ownerAng);

    // 获取视线反方向向量
    float backVec[3];
    GetAngleVectors(ownerAng, backVec, NULL_VECTOR, NULL_VECTOR);
    ScaleVector(backVec, -1500.0); // 向后距离

    // 起始位置 = 投掷者位置 + 反方向偏移 + 高度
    startPos[0] = ownerEye[0] + backVec[0];
    startPos[1] = ownerEye[1] + backVec[1];
    startPos[2] = ownerEye[2] + 1000.0; // 向上高度
    
    // 创建导弹实体
    int missile = CreateEntityByName("prop_physics_override");
    if (missile == -1) return Plugin_Stop;
    
    SetEntityModel(missile, g_sMissileModel);
    DispatchKeyValue(missile, "solid", "2");
    DispatchKeyValue(missile, "spawnflags", "256");
    DispatchSpawn(missile);
    
    TeleportEntity(missile, startPos, NULL_VECTOR, NULL_VECTOR);
    SetEntProp(missile, Prop_Data, "m_nNextThinkTick", -1);
    SetEntityMoveType(missile, MOVETYPE_FLY);
    
    // 添加火箭尾迹
    float SmokeOrigin[3] = {-30.0,0.0,0.0};
    float SmokeAngle[3] = {0.0,-180.0,0.0};
    int trail = CreateEntityByName("env_rockettrail");
    if (trail != -1)
    {
        SetEntPropFloat(trail, Prop_Send, "m_Opacity", 0.7);
        SetEntPropFloat(trail, Prop_Send, "m_SpawnRate", 120.0);
        SetEntPropFloat(trail, Prop_Send, "m_ParticleLifetime", 1.5);
        SetEntPropFloat(trail, Prop_Send, "m_StartSize", 8.0);
        SetEntPropFloat(trail, Prop_Send, "m_EndSize", 25.0);
        SetEntPropFloat(trail, Prop_Send, "m_SpawnRadius", 15.0);
        SetEntPropVector(trail, Prop_Send, "m_StartColor", view_as<float>({0.3, 0.3, 0.3}));
        SetEntPropFloat(trail, Prop_Send, "m_MinSpeed", 0.0);
        SetEntPropFloat(trail, Prop_Send, "m_MaxSpeed", 10.0);
        SetEntPropFloat(trail, Prop_Send, "m_flFlareScale", 1.0);
        DispatchSpawn(trail);
        ActivateEntity(trail);
        SetVariantString("!activator");
        AcceptEntityInput(trail, "SetParent", missile);
        TeleportEntity(trail, SmokeOrigin, SmokeAngle, NULL_VECTOR);
    }
    
    // 飞行逻辑 DataPack
    DataPack pack2 = new DataPack();
    pack2.WriteCell(missile);
    pack2.WriteFloat(targetPos[0]);
    pack2.WriteFloat(targetPos[1]);
    pack2.WriteFloat(targetPos[2]);
    pack2.WriteCell(owner);
    CreateTimer(FLY_TICK_INTERVAL, Timer_MissileFly, pack2, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    
    g_hActiveMissiles.Push(missile);
    // EmitSoundToAll("weapons/missile/missile_fly.wav", missile, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
    return Plugin_Stop;
}

public Action Timer_MissileFly(Handle timer, DataPack pack2)
{
    pack2.Reset();
    int missile = pack2.ReadCell();
    float targetX = pack2.ReadFloat();
    float targetY = pack2.ReadFloat();
    float targetZ = pack2.ReadFloat();
    int owner = pack2.ReadCell(); 
    
    if (!g_bRoundActive || !IsValidEntity(missile))
    {
        if (IsValidEntity(missile)) 
            AcceptEntityInput(missile, "Kill");
        CloseHandle(pack2);
        return Plugin_Stop;
    }
    
    float currentPos[3], targetPos[3];
    GetEntPropVector(missile, Prop_Send, "m_vecOrigin", currentPos);
    targetPos[0] = targetX; targetPos[1] = targetY; targetPos[2] = targetZ;
    
    float dist = GetVectorDistance(currentPos, targetPos);
    if (dist < 100.0)
    {
        DoExplosion(targetPos, owner);
        AcceptEntityInput(missile, "Kill");
        CloseHandle(pack2);
        return Plugin_Stop;
    }
    
    float dir[3];
    MakeVectorFromPoints(currentPos, targetPos, dir);
    NormalizeVector(dir, dir);
    ScaleVector(dir, MISSILE_SPEED * FLY_TICK_INTERVAL);
    float newPos[3];
    AddVectors(currentPos, dir, newPos);
    TeleportEntity(missile, newPos, NULL_VECTOR, dir);
    
    float angles[3];
    GetVectorAngles(dir, angles);
    TeleportEntity(missile, NULL_VECTOR, angles, NULL_VECTOR);
    return Plugin_Continue;
}

void DoExplosion(float pos[3], int owner)
{
    // 主爆炸实体
    int explosion = CreateEntityByName("env_explosion");
    if (explosion != -1)
    {
        SetEntProp(explosion, Prop_Data, "m_spawnflags", 6146);
        SetEntProp(explosion, Prop_Data, "m_iMagnitude", 1);
        SetEntProp(explosion, Prop_Data, "m_iRadiusOverride", cvRadius);
        if(0 < owner <= MaxClients)
           SetEntPropEnt(explosion, Prop_Send, "m_hOwnerEntity", owner);
        DispatchSpawn(explosion);
        ActivateEntity(explosion);
        TeleportEntity(explosion, pos, NULL_VECTOR, NULL_VECTOR);
        AcceptEntityInput(explosion, "Explode");
        
        CreateTimer(1.0, Timer_RemoveEntity, explosion);
        
        // 爆炸参数
        int maxRadius = cvRadius;      // 最大范围（单位）
        int maxDamage = cvDamage;          // 中心点最大伤害
        int minDamage = 20;           // 边缘最小伤害
        
        // 1. 对真人玩家和 Bot 造成衰减伤害
        for (int i = 1; i <= MaxClients; i++)
        {
            if(!IsValidEntity(i))
            continue;
        
            decl String:classname[32];
            GetEdictClassname(i, classname, sizeof(classname));
            if(!StrEqual(classname, "player"))
                continue;
            
            if (!IsClientInGame(i) || !IsPlayerAlive(i))
                continue;
            
            float targetPos[3];
            GetEntPropVector(i, Prop_Send, "m_vecOrigin", targetPos);
            float dist = GetVectorDistance(pos, targetPos);
            
            if (dist <= maxRadius)
            {
                // 线性衰减: 距离越远伤害越低
                float damage = float(maxDamage) * (1.0 - dist / maxRadius);
                if (damage < float(minDamage))
                    damage = float(minDamage);
                
                // PrintToChatAll("距离：%f", dist);
                // PrintToChatAll("伤害：%f", damage);
                
                SDKHooks_TakeDamage(i, 0, 0, damage, DMG_BLAST);
            }
        }
        
        // 2. 对大灾变丧尸造成衰减伤害（通过API）
        /*int zombieCount = Han_GetZombieCount();
        for (int idx = 0; idx < zombieCount; idx++)
        {
            int zombie = Han_GetZombieByIndex(idx);
            if (!IsValidEntity(zombie))
                continue;
            
            float zombiePos[3];
            GetEntPropVector(zombie, Prop_Send, "m_vecOrigin", zombiePos);
            float dist = GetVectorDistance(pos, zombiePos);
            
            if (dist <= maxRadius)
            {
                float damage = float(maxDamage) * (1.0 - dist / maxRadius);
                if (damage < float(minDamage))
                    damage = float(minDamage);
                
                damage = damage * 1.25;
                
                // 使用大灾变提供的安全伤害函数
                if(0 < owner <= MaxClients)
                   Han_SafeDamageZombie(owner, zombie, RoundToNearest(damage));
            }
        }*/
    }
    
    // 爆炸粒子效果1
    int particle = CreateEntityByName("info_particle_system");
    if (particle != -1)
    {
        DispatchKeyValue(particle, "effect_name", "explosion_silo");
        DispatchSpawn(particle);
        TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
        ActivateEntity(particle);
        AcceptEntityInput(particle, "Start");
        CreateTimer(5.0, Timer_RemoveEntity, particle);
    }
    
    // 爆炸粒子效果2
    int particle2 = CreateEntityByName("info_particle_system");
    if (particle2 != -1)
    {
        DispatchKeyValue(particle2, "effect_name", "explosion_huge_flames");
        DispatchSpawn(particle2);
        TeleportEntity(particle2, pos, NULL_VECTOR, NULL_VECTOR);
        ActivateEntity(particle2);
        AcceptEntityInput(particle2, "Start");
        CreateTimer(5.0, Timer_RemoveEntity, particle2);
    }
    
    // 爆炸粒子效果3
    int particle3 = CreateEntityByName("info_particle_system");
    if (particle3 != -1)
    {
        DispatchKeyValue(particle3, "effect_name", "explosion_huge_burning_chunks");
        DispatchSpawn(particle3);
        TeleportEntity(particle3, pos, NULL_VECTOR, NULL_VECTOR);
        ActivateEntity(particle3);
        AcceptEntityInput(particle3, "Start");
        CreateTimer(5.0, Timer_RemoveEntity, particle3);
    }
    
    // 播放爆炸音效
    EmitSoundToAll("weapons/missile/c4_explode1.wav", explosion, 1, 90);  
    
    DataPack pack3 = new DataPack();
    pack3.WriteFloat(pos[0]);
    pack3.WriteFloat(pos[1]);
    pack3.WriteFloat(pos[2]);
    CreateTimer(5.0, Timer_NewExplosionFire, pack3);
    
    // ===== 冲击波效果 =====
    float maxRadius = cvRadius * 2.0;   // 冲击波范围 = 2.0倍杀伤半径
    float maxShake = 8.0;                                 // 最大震动幅度
    float maxPush = 400.0;                               // 最大推力 (单位/秒)

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || !IsPlayerAlive(i))
            continue;

        float targetPos[3];
        GetEntPropVector(i, Prop_Send, "m_vecOrigin", targetPos);
        float dist = GetVectorDistance(pos, targetPos);
        if (dist > maxRadius) continue;

        // 距离衰减因子
        float factor = 1.0 - (dist / maxRadius);
        if (factor < 0.0) factor = 0.0;
        
        // ---- 物理推力 (对所有玩家) ----
        float dir[3];
        MakeVectorFromPoints(pos, targetPos, dir);
        NormalizeVector(dir, dir);
        float pushStrength = maxPush * factor;
        if (pushStrength > 10.0)
        {
            float currentVel[3];
            GetEntPropVector(i, Prop_Data, "m_vecVelocity", currentVel);
            float pushVec[3];
            ScaleVector(dir, pushStrength);
            AddVectors(currentVel, dir, pushVec);
            TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, pushVec);
        }
        
        // ---- 屏幕震动 (仅真人玩家) ----
        if (!IsFakeClient(i))
        {
            float shakeAmt = maxShake * factor;
            if (shakeAmt > 0.1)
            {
                shakeAmt = shakeAmt * 2.0;
                new Handle:hBf = StartMessageOne("Shake", i, 0);
                BfWriteByte(hBf, 0);
                BfWriteFloat(hBf, shakeAmt);    // 振幅
                BfWriteFloat(hBf, 2.0);    // 持续时间（秒）
                BfWriteFloat(hBf, 2.0);    // 频率
                EndMessage();
            }
        }
        
    }
}

public Action:Timer_NewExplosionFire(Handle timer, DataPack pack3)
{
    new Float:pos[3];
    pack3.Reset();  
    pos[0] = pack3.ReadFloat();
    pos[1] = pack3.ReadFloat();
    pos[2] = pack3.ReadFloat();
    CloseHandle(pack3);
    
    // 在爆炸中心生成残余火焰
    new fire = CreateEntityByName("env_fire"); 
    if (fire != -1)
    {
        DispatchKeyValue(fire, "firesize", "50");
        //DispatchKeyValue(fire, "fireattack", "5");
        DispatchKeyValue(fire, "health", "7");
        DispatchKeyValue(fire, "firetype", "Normal");

        DispatchKeyValueFloat(fire, "damagescale", 20.0);
        DispatchKeyValue(fire, "spawnflags", "256");  //Used to controll flags
        SetVariantString("WaterSurfaceExplosion");
        AcceptEntityInput(fire, "DispatchEffect"); 
        DispatchSpawn(fire);
        TeleportEntity(fire, pos, NULL_VECTOR, NULL_VECTOR);
        AcceptEntityInput(fire, "StartFire");
        
        EmitAmbientSound( EXPLODE_SOUND, pos, fire, SNDLEVEL_NORMAL, _ , 1.0);
    }
}

public Action Event_SmokeSound(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags)
{
    if(IsValidEntity(entity) && entity > 0)
    {
        if(StrContains(sample, "weapons/smokegrenade/sg_explode.wav") != -1)
        {
            if(HasEntProp(entity, Prop_Send, "m_nSkin") == false)
                return Plugin_Continue;
            
            // 读取标记 (m_nSkin 是否等于1)
            int isAirstrike = GetEntProp(entity, Prop_Send, "m_nSkin");
            if(isAirstrike == 1 && cvType == 1)    // 如果cvType等于1，清除烟雾发散的声音
                return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}

void KillAllActiveMissiles()
{
    for (int i = 0; i < g_hActiveMissiles.Length; i++)
    {
        int ent = g_hActiveMissiles.Get(i);
        if (IsValidEntity(ent))
            AcceptEntityInput(ent, "Kill");
    }
    g_hActiveMissiles.Clear();
}