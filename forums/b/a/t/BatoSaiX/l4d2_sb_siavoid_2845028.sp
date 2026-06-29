#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.1"
#define DEBUG 0

// ── L4D2 m_zombieClass values ────────────────────────────────────────────────
//   1 = Smoker   ← EXCLUDED by design
//   2 = Boomer   ← tracked
//   3 = Hunter   ← tracked
//   4 = Spitter  ← tracked
//   5 = Jockey   ← tracked
//   6 = Charger  ← tracked
//   7 = Witch    ← tracked, but ONLY once enraged (see witch_harasser_set below)
//   8 = Tank     ← tracked
// ─────────────────────────────────────────────────────────────────────────────

// Witch tracking is adapted from "[L4D] Dynamic Witch Avoidance - Type A"
// by Omixsat & Bacardi: entref-based list kept current via OnEntityCreated/
// OnEntityDestroyed, with a per-witch rage flag set by witch_harasser_set.
// A calm Witch is not a threat yet, so bots only flee her once she's enraged.

// Spitter acid evasion: insect_swarm entities (the acid pool left by a Spitter)
// are tracked via OnEntityCreated/OnEntityDestroyed. When a bot steps within
// g_hAcidRange of a pool, bots flee from the owning Spitter (m_hOwnerEntity),
// falling back to any alive Spitter in the SI index if she's already dead.
// Entity class confirmed from l4d2_sb_ai_improver by Omixsat.
enum struct WitchInfo
{
    int  entref;
    bool isRage;
}

int       g_iSIIndex[MAXPLAYERS + 1]; // 1-based, mirroring the tank plugin style
int       g_iSICount = 0;
ArrayList g_listWitches;
ArrayList g_listAcidPools;           // entref ints of active insect_swarm (Spitter acid) entities
Handle    g_hAvoidTimer = INVALID_HANDLE;
ConVar    g_hDangerDistance;
ConVar    g_hAcidRange;              // proximity to acid pool that triggers evasion

public Plugin myinfo =
{
    name        = "[L4D2] Survivor Bot SI Avoidance",
    author      = "BatoSaiX",
    description = "Survivor bots flee from nearby SI, Tank, enraged Witch, and Spitter acid (Smoker excluded)",
    version     = PLUGIN_VERSION,
    url         = ""
};

// ── Game check ────────────────────────────────────────────────────────────────

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    char sGame[64];
    GetGameFolderName(sGame, sizeof(sGame));
    if (!StrEqual(sGame, "left4dead2", false))
    {
        strcopy(error, err_max, "Plugin only supports Left 4 Dead 2");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

// ── Plugin start / map lifecycle ──────────────────────────────────────────────

public void OnPluginStart()
{
    CreateConVar("l4d2_sbsiavoid_version", PLUGIN_VERSION,
        "[L4D2] Survivor Bot SI Avoidance Version",
        FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_DONTRECORD | FCVAR_SPONLY);

    g_hDangerDistance = CreateConVar("l4d2_sbsiavoid_range", "500.0",
        "Distance (units) within which survivor bots flee from a tracked threat.",
        FCVAR_NOTIFY | FCVAR_REPLICATED);

    g_hAcidRange = CreateConVar("l4d2_sbsiavoid_acidrange", "300.0",
        "Distance (units) from a Spitter acid pool (insect_swarm) within which survivor bots flee.",
        FCVAR_NOTIFY | FCVAR_REPLICATED);

    HookEvent("player_spawn",         Event_PlayerSpawn,   EventHookMode_PostNoCopy);
    HookEvent("player_death",         Event_PlayerDeath,   EventHookMode_PostNoCopy);
    HookEvent("player_incapacitated", Event_PlayerIncapped);
    HookEvent("witch_harasser_set",   Event_WitchEvents);
    HookEvent("witch_killed",         Event_WitchEvents);

    g_listWitches   = new ArrayList(sizeof(WitchInfo));
    g_listAcidPools = new ArrayList();

    // Late-load safety: pick up witches and acid pools already in the world.
    int ent = -1;
    while ((ent = FindEntityByClassname(ent, "witch")) != -1)
    {
        WitchInfo witch;
        witch.entref = EntIndexToEntRef(ent);
        witch.isRage = false;
        g_listWitches.PushArray(witch);
    }
    ent = -1;
    while ((ent = FindEntityByClassname(ent, "insect_swarm")) != -1)
        g_listAcidPools.Push(EntIndexToEntRef(ent));

    AutoExecConfig(true, "l4d2_sbsiavoidance");
}

public void OnMapStart()
{
    // SI/Tank are client-based and don't persist across maps; rebuild fresh.
    // Witches are repopulated naturally via OnEntityCreated as the new map spawns them.
    RebuildSIIndex();
    EnsureTimerState();
}

public void OnMapEnd()
{
    delete g_hAvoidTimer;
    g_iSICount = 0;
    g_listWitches.Clear();
    g_listAcidPools.Clear();
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (entity < 1) return;

    if (StrEqual(classname, "witch"))
    {
        WitchInfo witch;
        witch.entref = EntIndexToEntRef(entity);
        witch.isRage = false;
        g_listWitches.PushArray(witch);
        EnsureTimerState();
    }
    else if (StrEqual(classname, "insect_swarm"))
    {
        g_listAcidPools.Push(EntIndexToEntRef(entity));
        EnsureTimerState();

        // Issue an immediate flee the moment the acid pool appears, without
        // waiting up to 0.1 s for the next timer tick.
        RequestFrame(Frame_OnAcidSpawned, EntIndexToEntRef(entity));
    }
}

public void OnEntityDestroyed(int entity)
{
    if (entity < 1) return;

    char classname[16]; // 16 covers "witch"(5), "insect_swarm"(12) with room to spare
    GetEntityClassname(entity, classname, sizeof(classname));

    if (StrEqual(classname, "witch"))
    {
        int entref = EntIndexToEntRef(entity);
        int idx = g_listWitches.FindValue(entref, 0); // offset 0 = WitchInfo.entref
        if (idx != -1)
        {
            g_listWitches.Erase(idx);
            EnsureTimerState();
        }
    }
    else if (StrEqual(classname, "insect_swarm"))
    {
        int entref = EntIndexToEntRef(entity);
        int idx = g_listAcidPools.FindValue(entref);
        if (idx != -1)
        {
            g_listAcidPools.Erase(idx);
            EnsureTimerState();
        }
    }
}

// ── Events ────────────────────────────────────────────────────────────────────

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    RebuildSIIndex();
    EnsureTimerState();
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    RebuildSIIndex();
    EnsureTimerState();
}

Action Event_PlayerIncapped(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!IsClientInGame(client) || !IsPlayerAlive(client)) return Plugin_Continue;
    if (GetClientTeam(client) != 2 || !IsFakeClient(client))    return Plugin_Continue;

    // Cancel any in-flight flee order so the incapped bot doesn't ghost-walk.
    L4D2_RunScript("CommandABot({cmd=3,bot=GetPlayerFromUserID(%i)})",
        GetClientUserId(client));

#if DEBUG
    PrintToChatAll("[SIAvoid] Bot %i incapped — AI reset.", client);
#endif

    return Plugin_Continue;
}

void Event_WitchEvents(Event event, const char[] name, bool dontBroadcast)
{
    int entity = event.GetInt("witchid", 0);
    int entref = EntIndexToEntRef(entity);
    int idx    = g_listWitches.FindValue(entref, 0); // offset 0 = WitchInfo.entref
    if (idx == -1) return;

    if (StrEqual(name, "witch_harasser_set"))
    {
        // A survivor has startled her — she's now hostile and worth fleeing.
        WitchInfo witch;
        g_listWitches.GetArray(idx, witch);
        witch.isRage = true;
        g_listWitches.SetArray(idx, witch);

#if DEBUG
        PrintToChatAll("[SIAvoid] Witch (ent %i) is now enraged.", entity);
#endif
    }
    else if (StrEqual(name, "witch_killed"))
    {
        g_listWitches.Erase(idx);
        EnsureTimerState();
    }
}

// ── Main avoidance timer (runs at 0.1 s) ──────────────────────────────────────

Action Timer_BotAvoidSI(Handle timer)
{
    float fRange = g_hDangerDistance.FloatValue;

    for (int bot = 1; bot <= MaxClients; bot++)
    {
        if (!IsClientInGame(bot))    continue;
        if (!IsPlayerAlive(bot))     continue;
        if (GetClientTeam(bot) != 2) continue;
        if (!IsFakeClient(bot))      continue;
        if (IsIncapacitated(bot))    continue;

        float vBot[3];
        GetClientAbsOrigin(bot, vBot);

        // Among all tracked SI/Tank/Witch in range, pick the closest one to flee from.
        float fBestDist   = fRange;
        int   iTarget     = -1;
        bool  bEntityFlee = false; // true = target is an NPC entity; use EntIndexToHScript

        for (int t = 1; t <= g_iSICount; t++)
        {
            int si = g_iSIIndex[t];
            if (!IsClientInGame(si) || !IsPlayerAlive(si)) continue;
            if (GetClientTeam(si) != 3) continue;

            float vSI[3];
            GetClientAbsOrigin(si, vSI);
            float fDist = GetVectorDistance(vBot, vSI);

            if (fDist < fBestDist)
            {
                fBestDist   = fDist;
                iTarget     = si;
                bEntityFlee = false;
            }
        }

        for (int w = 0; w < g_listWitches.Length; w++)
        {
            WitchInfo witch;
            g_listWitches.GetArray(w, witch);

            if (!witch.isRage) continue; // Calm Witch — not a threat yet, leave her be.

            int witchIndex = EntRefToEntIndex(witch.entref);
            if (!IsValidWitch(witchIndex)) continue;

            float vWitch[3];
            GetEntPropVector(witchIndex, Prop_Send, "m_vecOrigin", vWitch);
            float fDist = GetVectorDistance(vBot, vWitch);

            if (fDist < fBestDist)
            {
                fBestDist   = fDist;
                iTarget     = witchIndex;
                bEntityFlee = true;
            }
        }

        // Acid pool check — runs after SI/Witch but takes unconditional priority.
        // cmd=5 (take cover from position) works directly on a world Vector so we
        // don't need the Spitter to be alive. Sets bAcidHandled to skip the
        // iTarget dispatch below.
        bool  bAcidHandled = false;
        float fAcidRange   = g_hAcidRange.FloatValue;
        for (int a = 0; a < g_listAcidPools.Length; a++)
        {
            int acidEnt = EntRefToEntIndex(g_listAcidPools.Get(a));
            if (!IsValidAcid(acidEnt)) continue;

            float vAcid[3];
            GetEntPropVector(acidEnt, Prop_Send, "m_vecOrigin", vAcid);

            if (GetVectorDistance(vBot, vAcid) >= fAcidRange) continue;

            // Bot is within acid range — issue take-cover from the pool's position.
            L4D2_RunScript(
                "CommandABot({cmd=5,bot=GetPlayerFromUserID(%i),pos=Vector(%f,%f,%f)})",
                GetClientUserId(bot), vAcid[0], vAcid[1], vAcid[2]);

#if DEBUG
            PrintToChatAll("[SIAvoid] Bot %i taking cover from acid pool (ent %i) dist=%.1f",
                bot, acidEnt, GetVectorDistance(vBot, vAcid));
#endif
            bAcidHandled = true;
            break;
        }

        if (!bAcidHandled && iTarget != -1)
        {
            if (bEntityFlee)
            {
                // Enraged Witch is an NPC — use EntIndexToHScript.
                L4D2_RunScript(
                    "CommandABot({cmd=2,bot=GetPlayerFromUserID(%i),target=EntIndexToHScript(%i)})",
                    GetClientUserId(bot), iTarget);

#if DEBUG
                PrintToChatAll("[SIAvoid] Bot %i fleeing Witch (ent %i) dist=%.1f",
                    bot, iTarget, fBestDist);
#endif
            }
            else
            {
                L4D2_RunScript(
                    "CommandABot({cmd=2,bot=GetPlayerFromUserID(%i),target=GetPlayerFromUserID(%i)})",
                    GetClientUserId(bot), GetClientUserId(iTarget));

#if DEBUG
                PrintToChatAll("[SIAvoid] Bot %i fleeing client %i (class %i) dist=%.1f",
                    bot, iTarget,
                    GetEntProp(iTarget, Prop_Send, "m_zombieClass"),
                    fBestDist);
#endif
            }
        }
    }

    return Plugin_Continue;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/**
 * Fires the next server frame after an insect_swarm entity is created.
 * Issues cmd=5 (take cover from position) to ALL alive bots immediately —
 * no distance check, no Spitter lookup. The acid is about to spread from
 * exactly where it landed, so every bot in the area should react at once.
 */
void Frame_OnAcidSpawned(any entref)
{
    int acidEnt = EntRefToEntIndex(entref);
    if (!IsValidAcid(acidEnt)) return;

    float vAcid[3];
    GetEntPropVector(acidEnt, Prop_Send, "m_vecOrigin", vAcid);

    for (int bot = 1; bot <= MaxClients; bot++)
    {
        if (!IsClientInGame(bot))    continue;
        if (!IsPlayerAlive(bot))     continue;
        if (GetClientTeam(bot) != 2) continue;
        if (!IsFakeClient(bot))      continue;
        if (IsIncapacitated(bot))    continue;

        // cmd=5: take cover FROM this world position — works on any Vector,
        // no living entity required. Bots move away from the acid spawn point.
        L4D2_RunScript(
            "CommandABot({cmd=5,bot=GetPlayerFromUserID(%i),pos=Vector(%f,%f,%f)})",
            GetClientUserId(bot), vAcid[0], vAcid[1], vAcid[2]);

#if DEBUG
        PrintToChatAll("[SIAvoid] Bot %i taking cover from acid spawn (ent %i)", bot, acidEnt);
#endif
    }
}

void EnsureTimerState()
{
    bool bAnyThreat = (g_iSICount > 0 || g_listWitches.Length > 0 || g_listAcidPools.Length > 0);

    if (bAnyThreat && g_hAvoidTimer == INVALID_HANDLE)
    {
        g_hAvoidTimer = CreateTimer(0.1, Timer_BotAvoidSI, _, TIMER_REPEAT);
    }
    else if (!bAnyThreat && g_hAvoidTimer != INVALID_HANDLE)
    {
        delete g_hAvoidTimer;
    }
}

void RebuildSIIndex()
{
    g_iSICount = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i))    continue;
        if (GetClientTeam(i) != 3) continue;
        if (!IsPlayerAlive(i))     continue;
        if (!IsTrackedSI(i))       continue;

        g_iSIIndex[++g_iSICount] = i;
    }
}

// Returns true for Boomer(2), Hunter(3), Spitter(4), Jockey(5), Charger(6), Tank(8).
// Excludes Smoker(1) and Witch(7, tracked separately — she's never a client).
stock bool IsTrackedSI(int client)
{
    int z = GetEntProp(client, Prop_Send, "m_zombieClass");
    return (z >= 2 && z <= 6) || z == 8;
}

// Validates that an entity index from a stale entref still refers to a live Witch.
stock bool IsValidWitch(int entity)
{
    if (entity > 0 && IsValidEdict(entity) && IsValidEntity(entity))
    {
        char classname[8];
        GetEntityClassname(entity, classname, sizeof(classname));
        return StrEqual(classname, "witch");
    }
    return false;
}

// Same entref-reuse guard for insect_swarm (Spitter acid pool).
stock bool IsValidAcid(int entity)
{
    if (entity > 0 && IsValidEdict(entity) && IsValidEntity(entity))
    {
        char classname[16];
        GetEntityClassname(entity, classname, sizeof(classname));
        return StrEqual(classname, "insect_swarm");
    }
    return false;
}

// ── Stocks ────────────────────────────────────────────────────────────────────

// Runs a single line of VScript. Credit: Timocop
stock void L4D2_RunScript(const char[] sCode, any ...)
{
    static int iScriptLogic = INVALID_ENT_REFERENCE;
    if (iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic))
    {
        iScriptLogic = EntIndexToEntRef(CreateEntityByName("logic_script"));
        if (iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic))
            SetFailState("Could not create 'logic_script'");
        DispatchSpawn(iScriptLogic);
    }

    static char sBuffer[512];
    VFormat(sBuffer, sizeof(sBuffer), sCode, 2);

    SetVariantString(sBuffer);
    AcceptEntityInput(iScriptLogic, "RunScriptCode");
}

stock bool IsIncapacitated(int client)
{
    return (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) > 0);
}
