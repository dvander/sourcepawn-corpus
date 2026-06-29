#define _english_translation
#include <sourcemod>
#include <left4dhooks>
#include <sdktools>
#include <sdkhooks>

#define MODEL_TANK "models/infected/hulk.mdl"

// #region class Corpse
methodmap Corpse < ArrayList
{
    public Corpse()
    {
        ArrayList arr = new ArrayList();
        arr.Resize(4);
        return view_as<Corpse>(arr);
    }

    public bool IsValid()
    {
        return this.Entity > 0 && IsValidEntity(this.Entity);
    }

    public bool GetCorpsePosition(float pos[3])
    {
        if(!this.IsValid())
            return false;
        GetAbsOrigin(this.Entity, pos);
        return true;
    }

    property int Entity
    {
        public set(int value) { this.Set(0, value); }
        public get() { return this.Get(0); }
    }
    
    property int ReviveHp
    {
        public set(int value) { this.Set(1, value); }
        public get() {
            int hp = this.Get(1);
            if(hp < 500) hp = 500;
            return hp;
        }
    }
    
    property int LeftDefibTimes
    {
        public set(int value) { this.Set(2, value); }
        public get() { return this.Get(2); }
    }

    property int ExpireTime
    {
        public set(int value) { this.Set(3, value); }
        public get() { return this.Get(3); }
    }
}

Corpse corpses[2049];
int target[MAXPLAYERS + 1];
Handle defibTimers[MAXPLAYERS + 1];

Handle lifeTimer;

ConVar isPluginEnableCvar;
ConVar defibTimesOfPerTankCvar;
ConVar tankHpDecayCvar;
ConVar tankCorpseLifeDurationCvar;

public Plugin DefibTankPluginInfo =
{
    name = "Defib Tank",
    author = "Pure_*",
    description = "After tank dead, Player can defib tank's body to make tank alive",
    version = "0.1",
    url = ""
};

public OnPluginStart()
{
    HookEvent("player_death", OnPlayerDeath);
    HookEvent("round_start", OnRoundStart);
    HookEvent("round_end", OnRoundEnd);
    HookEvent("mission_lost", OnRoundEnd);
    HookEvent("finale_win", OnRoundEnd);
    HookEvent("map_transition", OnRoundEnd);
#if defined _english_translation
    isPluginEnableCvar = CreateConVar("l4d2_defib_tank_enable", "1", "Enable Plugin? (0=disable, 1=enable)");
    defibTimesOfPerTankCvar = CreateConVar("l4d2_defib_tank_defib_times", "2", "Limit of defib Times for per Tank");
    tankHpDecayCvar = CreateConVar("l4d2_defib_tank_hp_decay", "0.5", "Decay percentage of Tank's hp of last alive");
    tankCorpseLifeDurationCvar = CreateConVar("l4d2_defib_tank_corpse_life_time", "20", "Time of Tank's corpse exist (unit: seconds)");
#else
    isPluginEnableCvar = CreateConVar("l4d2_defib_tank_enable", "1", "开启插件（0=不开启，1=开启）");
    defibTimesOfPerTankCvar = CreateConVar("l4d2_defib_tank_defib_times", "2", "每个Tank可以被电击的次数");
    tankHpDecayCvar = CreateConVar("l4d2_defib_tank_hp_decay", "0.5", "每次被电击起来血量是上一次的多少百分数");
    tankCorpseLifeDurationCvar = CreateConVar("l4d2_defib_tank_corpse_life_time", "20", "Tank尸体存在多久时间（单位：秒）");
#endif
    AutoExecConfig(true, "l4d2_defib_tank");
}

public void OnMapStart()
{
    if(!IsModelPrecached(MODEL_TANK)) PrecacheModel(MODEL_TANK, true);
}


// #region Operate

int GetCorpseTarget(int client)
{
    float center[3]; GetAbsOrigin(client, center);
    float pos[3];
    for(int i = MAXPLAYERS + 1; i < 2049; i++)
    {
        if(corpses[i] == null)
            continue;
        if(!corpses[i].GetCorpsePosition(pos))
            continue;

        if(GetVectorDistance(center, pos, true) <= 10000.0)
        {
            return i;
        }
    }
    return -1;
} 

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
    if(!isPluginEnableCvar.BoolValue)
        return Plugin_Continue;

    if(!IsSurvivor(client) || !IsPlayerAlive(client))
        return Plugin_Continue;
    
    int curWeapon = GetPlayerCurrentWeapon(client);
    if(curWeapon <= 0)
    {
        if(defibTimers[client] != null)
        {
            ShowProgressBar(client, GetGameTime(), 0.0);
            KillTimerSafety(defibTimers[client]);
            target[client] = 0;
        }
        return Plugin_Continue;
    }
    char weaponName[32]; GetEntityClassname(curWeapon, weaponName, 32);
    if(!StrEqual(weaponName, "weapon_defibrillator", false))
    {
        if(defibTimers[client] != null)
        {
            ShowProgressBar(client, GetGameTime(), 0.0);
            KillTimerSafety(defibTimers[client]);
            target[client] = 0;
        }
        return Plugin_Continue;
    }
        
    if(buttons & IN_ATTACK)
    {
        if(target[client] <= 0)
        {
            target[client] = GetCorpseTarget(client);
        }
        else
        {
            int index = target[client];
            if(corpses[index] == null)
            {
                target[client] = 0;
                KillTimerSafety(defibTimers[client]);
                return Plugin_Continue;
            }
            Corpse c = corpses[index];
            // 距离
            float center[3]; GetAbsOrigin(client, center);
            float pos[3];
            if(!c.GetCorpsePosition(pos))
            {
                target[client] = 0;
                KillTimerSafety(defibTimers[client]);
                CloseHandle(corpses[index]);
                corpses[index] = null;
                ShowProgressBar(client, GetGameTime(), 0.0);
                return Plugin_Continue;
            }
            
            if(GetVectorDistance(center, pos, true) > 10000.0)
            {
                KillTimerSafety(defibTimers[client]);
                target[client] = 0;
                ShowProgressBar(client, GetGameTime(), 0.0);
                return Plugin_Continue;
            }

            if(defibTimers[client] == null)
            {
                // 时间
                float time = 3.0; // 默认值
                ConVar durationCvar = FindConVar("defibrillator_use_duration");
                if(durationCvar != null)
                {
                    time = durationCvar.FloatValue;
                }
            #if defined _english_translation
                PrintToChat(client, "[TIP] You're defibrillating Tank!");
            #else
                PrintToChat(client, "[提示] 你正在救助Tank");
            #endif
                
                defibTimers[client] = CreateTimer(time, Timer_OnDefibed, client);
                // PLAYERANIMEVENT_DEFIB_START = 50,
	            // PLAYERANIMEVENT_DEFIB_END = 51,
                L4D2Direct_DoAnimationEvent(client, PLAYERANIMEVENT_DEFIB_START);
                ShowProgressBar(client, GetGameTime(), time);
            }
        }
    }
    else
    {
        if(defibTimers[client] != null)
        {
            ShowProgressBar(client, GetGameTime(), 0.0);
        }
        KillTimerSafety(defibTimers[client]);
        target[client] = 0;
    }

    return Plugin_Continue;
}

Action Timer_OnDefibed(Handle timer, int client)
{
    defibTimers[client] = null;
    if(!IsSurvivor(client) || !IsPlayerAlive(client))
    {
        target[client] = 0;
        return Plugin_Stop;
    }

    int index = target[client];
    if(corpses[index] == null || !corpses[index].IsValid())
    {
        target[client] = 0;
        return Plugin_Stop;
    }
    
    ReviveTank(client, index);
    return Plugin_Continue;
}

void ReviveTank(int client, int index)
{    
    float pos[3];
    if(!corpses[index].GetCorpsePosition(pos))
        return;
    // 删除尸体
    DeleteEntity(corpses[index].Entity);
    // 删除武器
    int curWeapon = GetPlayerCurrentWeapon(client);
    DeleteEntity(curWeapon);
    // 数据
    int hp = corpses[index].ReviveHp;
    // 复活Tank
    int tank = L4D2_SpawnTank(pos, NULL_VECTOR);
    SetEntityHealth(tank, hp);
    SetPlayerMaxHealth(tank, hp)
    corpses[index].ReviveHp = RoundToNearest(float(corpses[index].ReviveHp) * (tankHpDecayCvar.FloatValue));
    corpses[index].LeftDefibTimes--;

    corpses[tank] = corpses[index];
    
    corpses[index] = null;

#if defined _english_translation
    PrintHintTextToAll("[TIP] %N defibrillated Tank!", client);
#else
    PrintHintTextToAll("[提示] 玩家%N使用电击器复活了Tank", client);
#endif
    
}

// #region LifeTimer
public void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
    if(!isPluginEnableCvar.BoolValue)
        return;
    
    for(int i = 0; i < 2049; i++)
    {
        corpses[i] = null;
    }
    lifeTimer = CreateTimer(1.0, TimerRepeat_CorporseLife, 0, TIMER_REPEAT);
}

// !rcon sm plugins reload l4d2_defib_tank
public void OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    for(int i = 0; i < 2049; i++)
    {
        if(corpses[i] == null)
            continue;
        CloseHandle(corpses[i]);
        corpses[i] = null;
    }
    KillTimerSafety(lifeTimer);
}

Action TimerRepeat_CorporseLife(Handle timer)
{
    for(int i = MAXPLAYERS + 1; i < 2049; i++)
    {
        if(corpses[i] == null)
            continue;

        if(!corpses[i].IsValid())
        {
            CloseHandle(corpses[i]);
            corpses[i] = null;
        }

        if(corpses[i].ExpireTime <= RoundToFloor(GetGameTime()))
        {
            DeleteEntity(corpses[i].Entity);
            CloseHandle(corpses[i]);
            corpses[i] = null;
        }
    }
    return Plugin_Continue;
}

// !rcon sm plugins reload l4d2_defib_tank_2
// #region CorporseGenerate
public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    if(!isPluginEnableCvar.BoolValue)
        return;
    // short	userid	user ID who died
    // long	entityid	entity ID who died, userid should be used first, to get the dead Player. Otherwise, it is not a player, so use this.
    // short	attacker	user ID who killed
    // string	attackername	What type of zombie, so we don't have zombie names
    // long	attackerentid	if killer not a player, the entindex of who killed. Again, use attacker first
    // string	weapon	weapon name killer used
    // bool	headshot	signals a headshot
    // bool	attackerisbot	is the attacker a bot
    // string	victimname	What type of zombie, so we don't have zombie names
    // bool	victimisbot	is the victim a bot
    // bool	abort	did the victim abort
    // long	type	damage type
    // float	victim_x
    // float	victim_y
    // float	victim_z
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if(!IsTank(client))
        return;

    // Defib Time Use Out
    if(corpses[client] != null && corpses[client].LeftDefibTimes <= 0)
    {
        CloseHandle(corpses[client]);
        corpses[client] = null;
        return;
    }

    float pos[3]; GetAbsOrigin(client, pos);
    int entity = CreateTankModel(client);
    TeleportEntity(entity, pos, {-90.0, 0.0, 0.0});

    // 当前不是第一次死亡
    if(corpses[client] != null)
    {
        corpses[client].Entity = entity;
        corpses[client].ExpireTime = RoundToNearest(tankCorpseLifeDurationCvar.FloatValue + GetGameTime());
        corpses[entity] = corpses[client];
        corpses[client] = null;
    }
    else
    {
        // 第一次生成corpose
        corpses[entity] = new Corpse();
        corpses[entity].Entity = entity;
        corpses[entity].LeftDefibTimes = defibTimesOfPerTankCvar.IntValue;
        corpses[entity].ExpireTime = RoundToNearest(tankCorpseLifeDurationCvar.FloatValue + GetGameTime());
        corpses[entity].ReviveHp = RoundToNearest(float(GetPlayerMaxHealth(client)) * tankHpDecayCvar.FloatValue);
    }
}

public int CreateTankModel(int client)
{
    int entity = CreateEntityByName("prop_dynamic_override");
    if(entity <= 0)
    {
        return -1;
    }
    char name[64];
    Format(name, 64, "Tank-%d-%d", entity, client);
    DispatchKeyValue(entity, "model", MODEL_TANK);
    DispatchKeyValue(entity, "solid", "0");
    DispatchKeyValue(entity, "targetname", name);
    if(!DispatchSpawn(entity))
    {
        DeleteEntity(entity);
        return -1;
    }
    ActivateEntity(entity);
    
    SetEntityGlow(entity, 3, 255);

    return entity;
}

// #region Utils
stock bool IsClientValid(int client)
{
    return 1 <= client && client <= MaxClients && IsClientInGame(client);
}

stock bool IsSurvivor(int client)
{
    return IsClientValid(client) && GetClientTeam(client) == 2;
}

stock bool IsInfected(int client)
{
    return IsClientValid(client) && GetClientTeam(client) == 3;
}

stock bool IsTank(int entity)
{
    if(!IsInfected(entity))
        return false;

    return GetEntProp(entity, Prop_Send, "m_zombieClass") == 8;
}

stock void DeleteEntity(int entity)
{
    if(entity <= 0 || !IsValidEntity(entity))
        return;

    AcceptEntityInput(entity, "Kill");
}

stock int GetPlayerCurrentWeapon(int client)
{
    return GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
}

stock void SetEntityGlow(int entity, int type, int color)
{
    // GlowType_None = 0, 
    // GlowType_OnUse, 
    // GlowType_OnLookAt, 
    // GlowType_Constant 
    SetEntProp(entity, Prop_Send, "m_iGlowType", type);
    SetEntProp(entity, Prop_Send, "m_glowColorOverride", color);
}

stock void KillTimerSafety(Handle& timer)
{
    if(timer != null)
    {
        delete timer;
    }
    timer = null;
}

stock void ShowProgressBar(int client, float start, float duration)
{
    SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", start);
    SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", duration);
}

stock int GetPlayerMaxHealth(int client)
{
    return GetEntProp(client, Prop_Data, "m_iMaxHealth");
}

stock void SetPlayerMaxHealth(int client, int maxHp)
{
    SetEntProp(client, Prop_Data, "m_iMaxHealth", maxHp);
}