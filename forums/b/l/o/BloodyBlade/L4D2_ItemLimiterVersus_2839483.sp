/**
 * L4D2 Item LimiterVersus
 * v1.2.2 (SM 1.10) - stable mirror + precise ground-only limits
 * --------------------------------------------------------------
 * - Limite UNIQUEMENT les pickups au sol (jamais l'inventaire des joueurs).
 * - 1re manche: applique les limites après player_left_start_area, puis construit le cache
 *   après un petit délai (et un second passage optionnel pour capter les spawns tardifs).
 * - 2e manche: restauration après player_left_start_area, en 2 PHASES (delete -> create).
 * - Verrouillage de map: on ne restaure que si la map est identique à celle du cache.
 * - Supporte classnames base + *_spawn (configurable pour la recréation).
 * - Corrigé un crash serveur au début de la deuxième manche.
 */

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdktools_gamerules>

// ---------- Plugin info ----------
public Plugin myinfo =
{
    name        = "L4D2 Item LimiterVersus",
    author      = "Lunatix",
    description = "Limits items + mirror them on second round",
    version     = "v1.2.2",
    url         = "https://steamcommunity.com/id/Xitanul/"
};

// ---------- ConVars ----------
ConVar gCvarPills, gCvarAdre, gCvarMolotov, gCvarPipe, gCvarBile, gCvarKit, gCvarDefib;
ConVar gCvarDebug, gCvarMirror;
ConVar gCvarUseSpawn;              // 0 = recréer en "base" (défaut, plus sûr), 1 = *_spawn
ConVar gCvarRestoreDel1;           // délai entre delete -> create en 2e manche
ConVar gCvarRestoreDel2;           // délai initial avant la phase delete en 2e manche (après sortie safe)
ConVar gCvarFirstCacheDelay;       // délai avant le build du cache (1re manche)
ConVar gCvarFirstCacheSecondPass;  // second passage de cache optionnel (0=off)

// ---------- Types & classnames ----------
enum ItemType
{
    IT_PILLS = 0,
    IT_ADRE,
    IT_MOLO,
    IT_PIPE,
    IT_BILE,
    IT_KIT,
    IT_DEFIB,
    IT_MAX
};

char g_ClassA[IT_MAX][32] =
{
    "weapon_pain_pills",
    "weapon_adrenaline",
    "weapon_molotov",
    "weapon_pipe_bomb",
    "weapon_vomitjar",
    "weapon_first_aid_kit",
    "weapon_defibrillator"
};
char g_ClassB[IT_MAX][32] =
{
    "weapon_pain_pills_spawn",
    "weapon_adrenaline_spawn",
    "weapon_molotov_spawn",
    "weapon_pipe_bomb_spawn",
    "weapon_vomitjar_spawn",
    "weapon_first_aid_kit_spawn",
    "weapon_defibrillator_spawn"
};

ConVar g_ItemCvars[IT_MAX];

// ---------- Cache ----------
// Par item: which(0=A,1=B) + 6 floats (org/ang) => 7 cells par pickup
Handle g_SpawnCache[IT_MAX];
bool   g_HasCache = false;
char   g_CachedMap[64];

// ---------- État de manche ----------
bool g_LastRoundStartWasSecondHalf = false;  // mémorise si le dernier round_start était une 2e manche
bool g_FirstHalfAppliedThisMap     = false;  // pour n’appliquer qu’une fois en 1re manche

// ======================================================
// Helpers généraux
// ======================================================
bool IsVersusMode()
{
    char mode[32];
    ConVar h = FindConVar("mp_gamemode");
    if (h == null) return false;
    h.GetString(mode, sizeof(mode));
    return (StrContains(mode, "versus", false) != -1);
}

bool InSecondHalf()
{
    // CTerrorGameRulesProxy::m_bInSecondHalfOfRound
    return (GameRules_GetProp("m_bInSecondHalfOfRound", 1, 0) != 0);
}

bool IsWorldPickup(int ent)
{
    if (!IsValidEntity(ent)) return false;

    // Si possédé par un joueur / arme → inventaire → on ignore
    int owner  = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
    if (owner != -1 && IsValidEntity(owner)) return false;

    // Si parenté (attaché/porté) → on ignore
    int parent = GetEntPropEnt(ent, Prop_Data, "m_hParent");
    if (parent != -1 && IsValidEntity(parent)) return false;

    return true;
}

// ======================================================
// Cache helpers
// ======================================================
void CacheClearAll()
{
    for (int i = 0; i < view_as<int>(IT_MAX); i++)
    {
        if (g_SpawnCache[i] != INVALID_HANDLE)
            ClearArray(g_SpawnCache[i]);
    }
    g_HasCache = false;
    g_CachedMap[0] = '\0';
}

void CacheEnsureAll()
{
    for (int i = 0; i < view_as<int>(IT_MAX); i++)
    {
        if (g_SpawnCache[i] == INVALID_HANDLE)
            g_SpawnCache[i] = CreateArray(1);
    }
}

void CachePush(int type, int whichClass, const float org[3], const float ang[3])
{
    PushArrayCell(g_SpawnCache[type], whichClass);
    PushArrayCell(g_SpawnCache[type], view_as<int>(org[0]));
    PushArrayCell(g_SpawnCache[type], view_as<int>(org[1]));
    PushArrayCell(g_SpawnCache[type], view_as<int>(org[2]));
    PushArrayCell(g_SpawnCache[type], view_as<int>(ang[0]));
    PushArrayCell(g_SpawnCache[type], view_as<int>(ang[1]));
    PushArrayCell(g_SpawnCache[type], view_as<int>(ang[2]));
}

int CacheLenCells(int type)
{
    return GetArraySize(g_SpawnCache[type]);
}

void CacheGetAt(int type, int start, int &whichClass, float org[3], float ang[3])
{
    whichClass = GetArrayCell(g_SpawnCache[type], start);
    org[0]     = view_as<float>(GetArrayCell(g_SpawnCache[type], start+1));
    org[1]     = view_as<float>(GetArrayCell(g_SpawnCache[type], start+2));
    org[2]     = view_as<float>(GetArrayCell(g_SpawnCache[type], start+3));
    ang[0]     = view_as<float>(GetArrayCell(g_SpawnCache[type], start+4));
    ang[1]     = view_as<float>(GetArrayCell(g_SpawnCache[type], start+5));
    ang[2]     = view_as<float>(GetArrayCell(g_SpawnCache[type], start+6));
}

// ======================================================
// Collecte des pickups au sol
// ======================================================
int CollectWorldPickupsByType(ItemType type, int entities[2048], int which[2048])
{
    int count=0, ent=-1;

    // Classe "base"
    while ((ent = FindEntityByClassname(ent, g_ClassA[type])) != -1)
    {
        if (!IsWorldPickup(ent)) continue;
        if (count < 2048) { entities[count]=ent; which[count]=0; count++; } else break;
    }

    // Variante *_spawn
    ent=-1;
    while ((ent = FindEntityByClassname(ent, g_ClassB[type])) != -1)
    {
        if (!IsWorldPickup(ent)) continue;
        if (count < 2048) { entities[count]=ent; which[count]=1; count++; } else break;
    }

    return count;
}

int CountWorldPickupsByType(ItemType t)
{
    int e[2048], w[2048];
    return CollectWorldPickupsByType(t, e, w);
}

// ======================================================
// Cœur (1re manche): appliquer limites au sol
// ======================================================
void ApplyAllLimits_FirstHalf()
{
	bool dbg = gCvarDebug.BoolValue;

	for (int i = 0; i < view_as<int>(IT_MAX); i++)
	{
		int limit = g_ItemCvars[i].IntValue;
		if (limit < 0)
		{
			if (dbg) LogMessage("[IL] %s/%s : ignore (limit=%d)", g_ClassA[i], g_ClassB[i], limit);
			continue;
		}

		int entities[2048], which[2048];
		int total = CollectWorldPickupsByType(view_as<ItemType>(i), entities, which);

		if (dbg) LogMessage("[IL] %s/%s (ground): found=%d, limit=%d", g_ClassA[i], g_ClassB[i], total, limit);

		if (total <= limit) continue;

		// ---------------------------------------------------------
		// SHUFFLE : Mélanger la liste pour que la suppression soit 100% aléatoire
		// Cela évite de cibler toujours les derniers items spawnés (souvent ceux des armoires)
		// ---------------------------------------------------------
		for (int k = total - 1; k > 0; k--)
		{
			int rnd = GetRandomInt(0, k);

			// Echange des entités dans la liste
			int tempEnt = entities[k];
			entities[k] = entities[rnd];
			entities[rnd] = tempEnt;

			// On échange aussi le type pour garder la cohérence (bonnes pratiques)
			int tempWhich = which[k];
			which[k] = which[rnd];
			which[rnd] = tempWhich;
		}
		// ---------------------------------------------------------

		int toRemove = (limit == 0) ? total : (total - limit);
		int removed = 0;

		// Maintenant qu'on a mélangé, on peut supprimer séquentiellement
		for (int idx = 0; idx < total && removed < toRemove; idx++)
		{
			int ent = entities[idx];
			if (IsValidEntity(ent))
			{
				AcceptEntityInput(ent, "Kill");
				removed++;
			}
		}

		if (dbg) LogMessage("[IL] %s/%s : removed=%d, remain=%d", g_ClassA[i], g_ClassB[i], removed, total - removed);
	}
}

// ======================================================
// Build cache (avec map lock + logs)
// ======================================================
void BuildSpawnCacheInternal(bool resetMapInfo)
{
    bool dbg = gCvarDebug.BoolValue;

    CacheClearAll();
    CacheEnsureAll();

    int totalAll = 0;

    for (int i = 0; i < view_as<int>(IT_MAX); i++)
    {
        int entities[2048], which[2048];
        int total = CollectWorldPickupsByType(view_as<ItemType>(i), entities, which);
        totalAll += total;

        for (int k = 0; k < total; k++)
        {
            int ent = entities[k];
            if (!IsValidEntity(ent)) continue;

            float org[3], ang[3];
            GetEntPropVector(ent, Prop_Send, "m_vecOrigin", org);
            GetEntPropVector(ent, Prop_Data, "m_angRotation", ang);

            CachePush(i, which[k], org, ang);
        }

        if (dbg) LogMessage("[IL] Cache: type %d -> %d pickups", i, total);
    }

    if (resetMapInfo)
    {
        char map[64];
        GetCurrentMap(map, sizeof(map));
        strcopy(g_CachedMap, sizeof(g_CachedMap), map);
        if (dbg) LogMessage("[IL] Cache built on map: %s (total=%d)", g_CachedMap, totalAll);
    }

    g_HasCache = true;
}

// ======================================================
// Timers (build cache après sortie de safe, 1re manche)
// ======================================================
Action Timer_BuildCachePass1(Handle timer)
{
    BuildSpawnCacheInternal(true);
    return Plugin_Stop;
}

Action Timer_BuildCachePass2(Handle timer)
{
    // Re-scan (spawns tardifs), on ne change pas le nom de map
    BuildSpawnCacheInternal(false);
    return Plugin_Stop;
}

// ======================================================
// Restauration (2e manche) en 2 phases
// ======================================================
Action Timer_PhaseDelete(Handle timer)
{
    // Supprimer tous les pickups au sol actuels (inventaire intouché)
    for (int i = 0; i < view_as<int>(IT_MAX); i++)
    {
        int ents[2048], wh[2048];
        int total = CollectWorldPickupsByType(view_as<ItemType>(i), ents, wh);
        for (int k = 0; k < total; k++)
            if (IsValidEntity(ents[k]))
                AcceptEntityInput(ents[k], "Kill");
    }

    // Planifier la phase de création
    CreateTimer(gCvarRestoreDel1.FloatValue, Timer_PhaseCreate, _, TIMER_FLAG_NO_MAPCHANGE);
    return Plugin_Stop;
}

Action Timer_PhaseCreate(Handle timer)
{
    bool dbg = gCvarDebug.BoolValue;
    int preferSpawn = gCvarUseSpawn.IntValue;
    float zeroVel[3]; zeroVel[0] = zeroVel[1] = zeroVel[2] = 0.0;

    for (int i = 0; i < view_as<int>(IT_MAX); i++)
    {
        int countCells = CacheLenCells(i);
        for (int idx = 0; idx + 6 < countCells; idx += 7)
        {
            int cachedWhich; float org[3], ang[3];
            CacheGetAt(i, idx, cachedWhich, org, ang);

            // Choisir la classe à créer:
            // - si preferSpawn=1 -> tenter *_spawn d’abord, sinon base d’abord
            // - fallback automatique si CreateEntityByName échoue
            char cls[32];

            if (preferSpawn)
            {
                strcopy(cls, sizeof(cls), g_ClassB[i]);
                int ent = CreateEntityByName(cls);
                if (ent != -1)
                {
                    DispatchSpawn(ent);
                    ActivateEntity(ent);
                    TeleportEntity(ent, org, ang, zeroVel);
                    if (dbg) LogMessage("[IL] Recreate %s (spawn) at (%.1f %.1f %.1f)", cls, org[0], org[1], org[2]);
                }
                else
                {
                    strcopy(cls, sizeof(cls), g_ClassA[i]);
                    ent = CreateEntityByName(cls);
                    if (ent != -1)
                    {
                        DispatchSpawn(ent);
                        ActivateEntity(ent);
                        TeleportEntity(ent, org, ang, zeroVel);
                        if (dbg) LogMessage("[IL] Fallback -> %s (base)", cls);
                    }
                }
            }
            else
            {
                strcopy(cls, sizeof(cls), g_ClassA[i]);
                int ent = CreateEntityByName(cls);
                if (ent != -1)
                {
                    DispatchSpawn(ent);
                    ActivateEntity(ent);
                    TeleportEntity(ent, org, ang, zeroVel);
                    if (dbg) LogMessage("[IL] Recreate %s (base) at (%.1f %.1f %.1f)", cls, org[0], org[1], org[2]);
                }
                else
                {
                    strcopy(cls, sizeof(cls), g_ClassB[i]);
                    ent = CreateEntityByName(cls);
                    if (ent != -1)
                    {
                        DispatchSpawn(ent);
                        ActivateEntity(ent);
                        TeleportEntity(ent, org, ang, zeroVel);
                        if (dbg) LogMessage("[IL] Fallback -> %s (spawn)", cls);
                    }
                }
            }
            // Si aucune création possible, on skip (sécurité crash)
        }
    }

    return Plugin_Stop;
}

// ======================================================
// Events
// ======================================================
public void OnPluginStart()
{
    // Limites par type (-1 ignore, 0 supprime tout, N garde N)
    gCvarPills   = CreateConVar("il_pills_limit",   "2",   "Max pills au sol (-1=ignore, 0=tout retirer, N=max)");
    gCvarAdre    = CreateConVar("il_adre_limit",    "-1",   "Max adrenaline au sol");
    gCvarMolotov = CreateConVar("il_molotov_limit", "1",   "Max molotovs au sol");
    gCvarPipe    = CreateConVar("il_pipe_limit",    "1",   "Max pipe bombs au sol");
    gCvarBile    = CreateConVar("il_bile_limit",    "-1",   "Max bile jars au sol");
    gCvarKit     = CreateConVar("il_kit_limit",     "-1",   "Max first aid kits au sol");
    gCvarDefib   = CreateConVar("il_defib_limit",   "-1",   "Max defibrillators au sol");

    // Contrôles
    gCvarDebug         = CreateConVar("il_debug",               "0",    "Logs debug (0/1)");
    gCvarMirror        = CreateConVar("il_mirror_versus",       "1",    "Miroir entre mi-temps (0/1)");
    gCvarUseSpawn      = CreateConVar("il_use_spawn_variants",  "0",    "Recréer en *_spawn (0=non/base, 1=oui)");
    gCvarRestoreDel1   = CreateConVar("il_restore_phase_delay", "0.35", "Délai delete->create (2e manche)");
    gCvarRestoreDel2   = CreateConVar("il_restore_start_delay", "2.5",  "Délai initial avant delete (2e manche)");
    gCvarFirstCacheDelay      = CreateConVar("il_first_cache_delay",       "1.0", "Délai avant build du cache (1re manche)");
    gCvarFirstCacheSecondPass = CreateConVar("il_first_cache_second_pass", "0.0", "Second build cache (0=off)");

    // Table d'accès rapide
    g_ItemCvars[IT_PILLS] = gCvarPills;
    g_ItemCvars[IT_ADRE]  = gCvarAdre;
    g_ItemCvars[IT_MOLO]  = gCvarMolotov;
    g_ItemCvars[IT_PIPE]  = gCvarPipe;
    g_ItemCvars[IT_BILE]  = gCvarBile;
    g_ItemCvars[IT_KIT]   = gCvarKit;
    g_ItemCvars[IT_DEFIB] = gCvarDefib;

    // Init cache arrays
    for (int i = 0; i < view_as<int>(IT_MAX); i++) g_SpawnCache[i] = CreateArray(1);

    // Admin cmds
    RegAdminCmd("sm_il_counts",     CmdCounts,     ADMFLAG_GENERIC, "Compter les pickups au sol");
    RegAdminCmd("sm_il_clearcache", CmdClearCache, ADMFLAG_GENERIC, "Vider le cache");
    RegAdminCmd("sm_il_apply",      CmdApply,      ADMFLAG_GENERIC, "Forcer application (1re manche) + cache");

    // Hooks d'événements
    HookEvent("round_start",            Event_RoundStart,   EventHookMode_PostNoCopy);
    HookEvent("round_end",              Event_RoundEnd,     EventHookMode_PostNoCopy);
    HookEvent("map_transition",         Event_MapTransition,EventHookMode_PostNoCopy);
    HookEvent("mission_lost",           Event_RoundEnd,     EventHookMode_PostNoCopy);
    HookEvent("player_left_start_area", Event_PlayerLeftStart, EventHookMode_PostNoCopy);
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    g_LastRoundStartWasSecondHalf = (IsVersusMode() && InSecondHalf());

    // Reset flag pour la prochaine 1re manche
    if (IsVersusMode() && !g_LastRoundStartWasSecondHalf)
        g_FirstHalfAppliedThisMap = false;
}

void Event_PlayerLeftStart(Event event, const char[] name, bool dontBroadcast)
{
    if (!IsVersusMode()) return;

    if (!InSecondHalf())
    {
        // 1re manche: appliquer limites + planifier le cache
        if (g_FirstHalfAppliedThisMap) return;

        ApplyAllLimits_FirstHalf();
        g_FirstHalfAppliedThisMap = true;

        float d1 = gCvarFirstCacheDelay.FloatValue;
        CreateTimer(d1, Timer_BuildCachePass1, _, TIMER_FLAG_NO_MAPCHANGE);

        float d2 = gCvarFirstCacheSecondPass.FloatValue;
        if (d2 > 0.0)
            CreateTimer(d1 + d2, Timer_BuildCachePass2, _, TIMER_FLAG_NO_MAPCHANGE);

        if (gCvarDebug.BoolValue)
            LogMessage("[IL] 1re manche: limites appliquées, cache planifié (%.2fs + %.2fs).", d1, d2);
    }
    else
    {
        // 2e manche: restauration en 2 phases (si miroir actif + cache + map identique)
        if (!gCvarMirror.BoolValue || !g_HasCache) return;

        char cur[64];
        GetCurrentMap(cur, sizeof(cur));
        if (g_CachedMap[0] == '\0' || strcmp(cur, g_CachedMap, false) != 0)
        {
            if (gCvarDebug.BoolValue)
                LogMessage("[IL] 2e manche: pas de restauration (map courante='%s' != cache='%s').", cur, g_CachedMap);
            return;
        }

        float dStart = gCvarRestoreDel2.FloatValue;
        CreateTimer(dStart, Timer_PhaseDelete, _, TIMER_FLAG_NO_MAPCHANGE);

        if (gCvarDebug.BoolValue)
            LogMessage("[IL] 2e manche: restauration planifiée (start=%.2fs, phase=%.2fs).",
                        dStart, gCvarRestoreDel1.FloatValue);
    }
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    // Si la manche terminée était la 2e -> fin de niveau -> purge
    if (IsVersusMode() && g_LastRoundStartWasSecondHalf)
    {
        CacheClearAll();
        g_FirstHalfAppliedThisMap = false;
        if (gCvarDebug.BoolValue) LogMessage("[IL] Fin 2e manche: cache purgé.");
    }
}

void Event_MapTransition(Event event, const char[] name, bool dontBroadcast)
{
    // Changement de map -> purge
    CacheClearAll();
    g_FirstHalfAppliedThisMap = false;
    if (gCvarDebug.BoolValue) LogMessage("[IL] map_transition: cache purgé.");
}

// ======================================================
// Commandes admin
// ======================================================
Action CmdCounts(int client, int args)
{
    for (int i = 0; i < view_as<int>(IT_MAX); i++)
    {
        int c = CountWorldPickupsByType(view_as<ItemType>(i));
        ReplyToCommand(client, "[IL] %s/%s (ground) = %d", g_ClassA[i], g_ClassB[i], c);
    }
    return Plugin_Handled;
}

Action CmdClearCache(int client, int args)
{
    CacheClearAll();
    ReplyToCommand(client, "[IL] Cache vidé.");
    return Plugin_Handled;
}

Action CmdApply(int client, int args)
{
    // Force l’étape 1re manche (utile si la sortie de safe a déjà eu lieu)
    ApplyAllLimits_FirstHalf();

    // Build cache immédiat (équivalent Pass1)
    BuildSpawnCacheInternal(true);
    g_FirstHalfAppliedThisMap = true;

    ReplyToCommand(client, "[IL] Limites appliquées et cache reconstruit (1re manche).");
    return Plugin_Handled;
}
