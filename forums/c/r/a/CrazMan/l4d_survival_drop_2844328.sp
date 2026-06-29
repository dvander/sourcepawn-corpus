#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <multicolors>

#define PLUGIN_VERSION "2.1-L4D1"

// -------------------------------------------------------
// ConVar handles
// -------------------------------------------------------
ConVar g_cvEnable;
ConVar g_cvDelay;
ConVar g_cvCheckRate;
ConVar g_cvMaxDrops;
ConVar g_cvHPLimit;
ConVar g_cvNearbyRadius;
ConVar g_cvMoveDist;
ConVar g_cvDropCooldown;
ConVar g_cvWeaponExpire;
ConVar g_cvChatMsg;

// -------------------------------------------------------
// ConVar values (cached)
// -------------------------------------------------------
bool  g_bEnabled      = true;
float g_fDelay        = 30.0;
float g_fCheckRate    = 2.0;
int   g_iMaxDrops     = 2;
int   g_iHPLimit      = 70;
float g_fNearbyRadius = 400.0;
float g_fMoveDist     = 700.0;
float g_fDropCooldown = 60.0;
float g_fWeaponExpire = 45.0;
bool  g_bChatMsg      = true;

// -------------------------------------------------------
// Per-client state
// -------------------------------------------------------
float g_fNoMedTime     [MAXPLAYERS + 1];
bool  g_bNoMedTracking [MAXPLAYERS + 1];
int   g_iDropsThisRound[MAXPLAYERS + 1];
float g_vLastPos       [MAXPLAYERS + 1][3];
float g_fMovedDistance [MAXPLAYERS + 1];
float g_fLastDropTime  [MAXPLAYERS + 1];
bool  g_bPosInit       [MAXPLAYERS + 1];

Handle g_hCheckTimer = null;

// -------------------------------------------------------
// Weighted item table for L4D1 (no adrenaline)
//   Pills      90%
//   Medkit     10%
// -------------------------------------------------------
static const char g_szItems[][] =
{
    "weapon_pain_pills",
    "weapon_pain_pills",
    "weapon_pain_pills",
    "weapon_pain_pills",
    "weapon_pain_pills",
    "weapon_pain_pills",
    "weapon_pain_pills",
    "weapon_pain_pills",
    "weapon_pain_pills",
    "weapon_first_aid_kit"
};
#define ITEM_TABLE_SIZE 10

// -------------------------------------------------------
public Plugin myinfo =
{
    name        = "[L4D1] Survival Drop",
    author      = "Nico (ported by CrazMan)",
    description = "Выдаёт аптечку или таблетки игроку, у которого долго нет медикаментов",
    version     = PLUGIN_VERSION,
    url         = ""
};

// -------------------------------------------------------
public void OnPluginStart()
{
    LoadTranslations("l4d_survival_drop.phrases");

    g_cvEnable = CreateConVar(
        "l4d1_survdrop_enable", "1",
        "Включить плагин (0=выкл, 1=вкл)",
        0, true, 0.0, true, 1.0);

    g_cvDelay = CreateConVar(
        "l4d1_survdrop_delay", "10.0",
        "Секунд без аптечки/таблеток, после которых сработает выдача",
        0, true, 5.0, true, 300.0);

    g_cvCheckRate = CreateConVar(
        "l4d1_survdrop_checkrate", "2.0",
        "Интервал проверки в секундах",
        0, true, 0.5, true, 10.0);

    g_cvMaxDrops = CreateConVar(
        "l4d1_survdrop_max_per_round", "5",
        "Максимум выдач на игрока за раунд (0 = безлимит)",
        0, true, 0.0, true, 20.0);

    g_cvHPLimit = CreateConVar(
        "l4d1_survdrop_hp_limit", "50",
        "Выдавать, только если здоровье игрока <= этому значению (0 = игнорировать HP)",
        0, true, 0.0, true, 100.0);

    g_cvNearbyRadius = CreateConVar(
        "l4d1_survdrop_nearby_radius", "400.0",
        "Не выдавать, если аптечка/таблетки уже есть в этом радиусе (0 = отключить)",
        0, true, 0.0, true, 2000.0);

    g_cvMoveDist = CreateConVar(
        "l4d1_survdrop_move_dist", "700.0",
        "Минимальное перемещение до первой выдачи (0 = отключить защиту от AFK)",
        0, true, 0.0, true, 5000.0);

    g_cvDropCooldown = CreateConVar(
        "l4d1_survdrop_drop_cooldown", "60.0",
        "Кулдаун после выдачи предмета (0 = отключить)",
        0, true, 0.0, true, 300.0);

    g_cvWeaponExpire = CreateConVar(
        "l4d1_survdrop_weapon_expire", "45.0",
        "Через сколько секунд удалить выданный предмет (-1 = никогда)",
        0, true, -1.0, true, 300.0);

    g_cvChatMsg = CreateConVar(
        "l4d1_survdrop_chat_msg", "1",
        "Показывать сообщение в чате при выдаче предмета (1=да, 0=нет)",
        0, true, 0.0, true, 1.0);

    CacheConVars();

    g_cvEnable      .AddChangeHook(OnCvarChange);
    g_cvDelay       .AddChangeHook(OnCvarChange);
    g_cvCheckRate   .AddChangeHook(OnCvarChange);
    g_cvMaxDrops    .AddChangeHook(OnCvarChange);
    g_cvHPLimit     .AddChangeHook(OnCvarChange);
    g_cvNearbyRadius.AddChangeHook(OnCvarChange);
    g_cvMoveDist    .AddChangeHook(OnCvarChange);
    g_cvDropCooldown.AddChangeHook(OnCvarChange);
    g_cvWeaponExpire.AddChangeHook(OnCvarChange);
    g_cvChatMsg     .AddChangeHook(OnCvarChange);

    AutoExecConfig(true, "l4d1_survival_drop");

    HookEvent("round_end",            Event_RoundEnd,    EventHookMode_PostNoCopy);
    HookEvent("player_death",         Event_PlayerDeath);
    HookEvent("player_incapacitated", Event_PlayerIncap);
    HookEvent("player_bot_replace",   Event_BotReplace);
    // НЕ вешаем "weapon_drop" – его нет в L4D1
}

void CacheConVars()
{
    g_bEnabled      = g_cvEnable.BoolValue;
    g_fDelay        = g_cvDelay.FloatValue;
    g_fCheckRate    = g_cvCheckRate.FloatValue;
    g_iMaxDrops     = g_cvMaxDrops.IntValue;
    g_iHPLimit      = g_cvHPLimit.IntValue;
    g_fNearbyRadius = g_cvNearbyRadius.FloatValue;
    g_fMoveDist     = g_cvMoveDist.FloatValue;
    g_fDropCooldown = g_cvDropCooldown.FloatValue;
    g_fWeaponExpire = g_cvWeaponExpire.FloatValue;
    g_bChatMsg      = g_cvChatMsg.BoolValue;
}

void OnCvarChange(ConVar hCvar, const char[] oldVal, const char[] newVal)
{
    CacheConVars();
    SafeKillTimer();
    if (g_bEnabled)
        StartTimer();
}

// -------------------------------------------------------
// Timer helpers
// -------------------------------------------------------
void SafeKillTimer()
{
    if (g_hCheckTimer != null)
    {
        KillTimer(g_hCheckTimer);
        g_hCheckTimer = null;
    }
}

void StartTimer()
{
    if (g_hCheckTimer != null) return;
    g_hCheckTimer = CreateTimer(g_fCheckRate, Timer_CheckSurvivors, _, TIMER_REPEAT);
}

// -------------------------------------------------------
// Map / round lifecycle
// -------------------------------------------------------
public void OnMapStart()
{
    ResetAll();
    if (g_bEnabled)
        StartTimer();
}

public void OnMapEnd()
{
    SafeKillTimer();
    ResetAll();
}

void Event_RoundEnd(Event hEvent, const char[] name, bool dontBroadcast)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        g_iDropsThisRound[i] = 0;
        g_fMovedDistance [i] = 0.0;
        g_bPosInit       [i] = false;
        g_fNoMedTime    [i] = 0.0;
        g_bNoMedTracking[i] = false;
    }
}

// -------------------------------------------------------
// Client events
// -------------------------------------------------------
void Event_PlayerDeath(Event hEvent, const char[] name, bool dontBroadcast)
{
    int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
    if (iClient > 0 && iClient <= MaxClients)
        ResetClientTracking(iClient);
}

void Event_PlayerIncap(Event hEvent, const char[] name, bool dontBroadcast)
{
    int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
    if (iClient > 0 && iClient <= MaxClients)
        ResetClientTracking(iClient);
}

void Event_BotReplace(Event hEvent, const char[] name, bool dontBroadcast)
{
    int iClient = GetClientOfUserId(hEvent.GetInt("player"));
    if (iClient > 0 && iClient <= MaxClients)
        ResetClient(iClient);
}

// Функция Event_WeaponDrop полностью удалена – она больше не нужна

public void OnClientDisconnect(int iClient)
{
    ResetClient(iClient);
}

// -------------------------------------------------------
// Reset helpers
// -------------------------------------------------------
void ResetAll()
{
    for (int i = 1; i <= MaxClients; i++)
        ResetClient(i);
}

void ResetClient(int iClient)
{
    g_fNoMedTime     [iClient] = 0.0;
    g_bNoMedTracking [iClient] = false;
    g_iDropsThisRound[iClient] = 0;
    g_fMovedDistance [iClient] = 0.0;
    g_fLastDropTime  [iClient] = 0.0;
    g_bPosInit       [iClient] = false;
    g_vLastPos       [iClient][0] = 0.0;
    g_vLastPos       [iClient][1] = 0.0;
    g_vLastPos       [iClient][2] = 0.0;
}

void ResetClientTracking(int iClient)
{
    g_fNoMedTime    [iClient] = 0.0;
    g_bNoMedTracking[iClient] = false;
}

// -------------------------------------------------------
// Main timer
// -------------------------------------------------------
Action Timer_CheckSurvivors(Handle hTimer)
{
    if (!g_bEnabled)
    {
        g_hCheckTimer = null;
        return Plugin_Stop;
    }

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsFakeClient(i))
        {
            ResetClientTracking(i);
            continue;
        }
        if (!IsPlayerAlive(i) || GetClientTeam(i) != 2)
        {
            ResetClientTracking(i);
            continue;
        }
        if (GetEntProp(i, Prop_Send, "m_isIncapacitated"))
        {
            ResetClientTracking(i);
            continue;
        }

        if (IsInSafeRoom(i))
        {
            ResetClientTracking(i);
            continue;
        }

        if (g_iMaxDrops > 0 && g_iDropsThisRound[i] >= g_iMaxDrops)
            continue;

        if (g_iHPLimit > 0 && GetClientHealth(i) > g_iHPLimit)
        {
            ResetClientTracking(i);
            continue;
        }

        float vPos[3];
        GetClientAbsOrigin(i, vPos);

        if (!g_bPosInit[i])
        {
            g_bPosInit   [i] = true;
            g_vLastPos   [i][0] = vPos[0];
            g_vLastPos   [i][1] = vPos[1];
            g_vLastPos   [i][2] = vPos[2];
        }

        float fDist = GetVectorDistance(vPos, g_vLastPos[i]);
        if (fDist > 15.0)
        {
            g_fMovedDistance[i]  += fDist;
            g_vLastPos      [i][0] = vPos[0];
            g_vLastPos      [i][1] = vPos[1];
            g_vLastPos      [i][2] = vPos[2];
        }

        if (g_fMoveDist > 0.0 && g_fMovedDistance[i] < g_fMoveDist)
            continue;

        if (g_fDropCooldown > 0.0 && GetGameTime() - g_fLastDropTime[i] < g_fDropCooldown)
            continue;

        bool bHasMed = ClientHasMed(i);

        if (!bHasMed)
        {
            if (!g_bNoMedTracking[i])
            {
                g_bNoMedTracking[i] = true;
                g_fNoMedTime    [i] = GetGameTime();
            }
            else
            {
                float elapsed = GetGameTime() - g_fNoMedTime[i];
                if (elapsed >= g_fDelay)
                {
                    if (!MedNearby(i))
                    {
                        int iTeamMeds = CountTeamMeds();
                        if (ShouldDropByTeam(iTeamMeds) && ShouldDropByHP(i))
                        {
                            g_iDropsThisRound[i]++;
                            DropRandomMedNear(i);
                        }
                    }
                    ResetClientTracking(i);
                }
            }
        }
        else
        {
            ResetClientTracking(i);
        }
    }

    return Plugin_Continue;
}

// -------------------------------------------------------
// Safe room check
// -------------------------------------------------------
bool IsInSafeRoom(int iClient)
{
    float vPos[3];
    GetClientAbsOrigin(iClient, vPos);

    int ent = -1;
    while ((ent = FindEntityByClassname(ent, "trigger_checkpoint")) != -1)
    {
        float vMins[3], vMaxs[3], vEntPos[3];
        GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vEntPos);
        GetEntPropVector(ent, Prop_Send, "m_vecMins",   vMins);
        GetEntPropVector(ent, Prop_Send, "m_vecMaxs",   vMaxs);

        if (vPos[0] >= vEntPos[0] + vMins[0] && vPos[0] <= vEntPos[0] + vMaxs[0] &&
            vPos[1] >= vEntPos[1] + vMins[1] && vPos[1] <= vEntPos[1] + vMaxs[1] &&
            vPos[2] >= vEntPos[2] + vMins[2] && vPos[2] <= vEntPos[2] + vMaxs[2])
            return true;
    }
    return false;
}

// -------------------------------------------------------
// Count team meds
// -------------------------------------------------------
int CountTeamMeds()
{
    int count = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != 2)
            continue;
        if (IsFakeClient(i))
            continue;
        if (ClientHasMed(i))
            count++;
    }
    return count;
}

bool ShouldDropByTeam(int iTeamMeds)
{
    int roll = GetRandomInt(1, 100);
    if      (iTeamMeds == 0) return true;
    else if (iTeamMeds == 1) return roll <= 70;
    else if (iTeamMeds == 2) return roll <= 40;
    else                     return roll <= 15;
}

// -------------------------------------------------------
// HP-based chance
// -------------------------------------------------------
bool ShouldDropByHP(int iClient)
{
    int hp   = GetClientHealth(iClient);
    int roll = GetRandomInt(1, 100);

    if      (hp <= 20) return true;
    else if (hp <= 40) return roll <= 70;
    else               return roll <= 40;
}

// -------------------------------------------------------
// Check if client has meds
// -------------------------------------------------------
bool ClientHasMed(int iClient)
{
    int iSlot3 = GetPlayerWeaponSlot(iClient, 3);
    if (iSlot3 != -1 && IsValidEntity(iSlot3) && IsValidEdict(iSlot3))
    {
        char szClass[64];
        GetEdictClassname(iSlot3, szClass, sizeof(szClass));
        if (StrEqual(szClass, "weapon_first_aid_kit"))
            return true;
    }

    int iSlot4 = GetPlayerWeaponSlot(iClient, 4);
    if (iSlot4 != -1 && IsValidEntity(iSlot4) && IsValidEdict(iSlot4))
    {
        char szClass[64];
        GetEdictClassname(iSlot4, szClass, sizeof(szClass));
        if (StrEqual(szClass, "weapon_pain_pills"))
            return true;
    }

    return false;
}

// -------------------------------------------------------
// Check if med item is nearby
// -------------------------------------------------------
bool MedNearby(int iClient)
{
    if (g_fNearbyRadius <= 0.0) return false;

    float vSurv[3];
    GetClientAbsOrigin(iClient, vSurv);
    float fRadiusSq = g_fNearbyRadius * g_fNearbyRadius;

    static const char g_szMedClasses[][] =
    {
        "weapon_first_aid_kit",
        "weapon_pain_pills"
    };

    for (int m = 0; m < sizeof(g_szMedClasses); m++)
    {
        int ent = -1;
        while ((ent = FindEntityByClassname(ent, g_szMedClasses[m])) != -1)
        {
            if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") != -1)
                continue;

            float vEnt[3];
            GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vEnt);

            if (GetVectorDistance(vSurv, vEnt, true) <= fRadiusSq)
                return true;
        }
    }
    return false;
}

// -------------------------------------------------------
// Spawn the item and optionally show chat message
// -------------------------------------------------------
void DropRandomMedNear(int iClient)
{
    int iRand = GetRandomInt(0, ITEM_TABLE_SIZE - 1);
    char szItem[64];
    strcopy(szItem, sizeof(szItem), g_szItems[iRand]);

    float vPos[3];
    GetClientAbsOrigin(iClient, vPos);

    float vAng[3], fFwd[3];
    GetClientEyeAngles(iClient, vAng);
    GetAngleVectors(vAng, fFwd, NULL_VECTOR, NULL_VECTOR);
    vPos[0] += fFwd[0] * 40.0;
    vPos[1] += fFwd[1] * 40.0;
    vPos[2] += 10.0;

    float vDown[3];
    vDown[0] = vPos[0]; vDown[1] = vPos[1]; vDown[2] = vPos[2] - 100.0;
    TR_TraceRayFilter(vPos, vDown, MASK_PLAYERSOLID, RayType_EndPoint, TraceFilter_NoPlayers);
    if (!TR_DidHit())
    {
        GetClientAbsOrigin(iClient, vPos);
        vPos[2] += 5.0;
    }

    float vMins[3] = {-10.0, -10.0, 0.0};
    float vMaxs[3] = { 10.0,  10.0, 20.0};
    TR_TraceHullFilter(vPos, vPos, vMins, vMaxs, MASK_PLAYERSOLID, TraceFilter_NoPlayers);
    if (TR_DidHit())
    {
        GetClientAbsOrigin(iClient, vPos);
        vPos[2] += 5.0;
    }

    int iEnt = CreateEntityByName(szItem);
    if (!IsValidEntity(iEnt))
        return;

    DispatchSpawn(iEnt);
    TeleportEntity(iEnt, vPos, NULL_VECTOR, NULL_VECTOR);

    // Удаление предмета через таймер, если g_fWeaponExpire > 0
    if (g_fWeaponExpire > 0.0)
    {
        CreateTimer(g_fWeaponExpire, Timer_RemoveWeapon, EntIndexToEntRef(iEnt), TIMER_FLAG_NO_MAPCHANGE);
    }

    // Запоминаем время выдачи для кулдауна
    g_fLastDropTime[iClient] = GetGameTime();

    // Отправка сообщения в чат, если разрешено
    if (g_bChatMsg)
    {
        char szItemName[32];
        if (StrEqual(szItem, "weapon_first_aid_kit"))
            strcopy(szItemName, sizeof(szItemName), "Аптечка \x07(10%)");
        else
            strcopy(szItemName, sizeof(szItemName), "Таблетки \x05(90%)");

        CPrintToChat(iClient, "%t", "SurvivalDrop_Message", RoundToNearest(g_fDelay), szItemName, g_iDropsThisRound[iClient], g_iMaxDrops);
    }
}

// -------------------------------------------------------
// Timer callback to remove weapon entity
// -------------------------------------------------------
public Action Timer_RemoveWeapon(Handle timer, int entRef)
{
    int ent = EntRefToEntIndex(entRef);
    if (ent != INVALID_ENT_REFERENCE && IsValidEntity(ent))
    {
        RemoveEntity(ent);
    }
    return Plugin_Stop;
}

// -------------------------------------------------------
public bool TraceFilter_NoPlayers(int iEntity, int iMask)
{
    return iEntity > MaxClients;
}