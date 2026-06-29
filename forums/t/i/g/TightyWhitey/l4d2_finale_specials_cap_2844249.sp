#include <sourcemod>
#include <left4dhooks>
#include <sdktools>

ConVar g_cvEnable;
ConVar g_cvFinaleSpecialsLimit;
ConVar g_cvVerbose;
ConVar g_cvModes;
ConVar g_hMPGameMode;
bool g_bInFinale;
bool g_bModeAllowed;

public Plugin myinfo =
{
    name = "L4D2 Finale Specials Cap",
    author = "Tighty-Whitey",
    version = "1.0",
    description = "Block special spawns exceeding a configurable limit during finales."
};

public void OnPluginStart()
{
    g_cvEnable = CreateConVar("l4d2_finale_specials_enable", "1", "Enable Finale Specials Cap plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvFinaleSpecialsLimit = CreateConVar("l4d2_finale_specials_limit", "2", "Maximum allowed special infected during a finale", _, true, 1.0);
    g_cvVerbose = CreateConVar("l4d2_finale_specials_verbose", "0", "Print blocked spawn messages (root admin only)");
    g_cvModes = CreateConVar("l4d2_finale_specials_modes", "coop,realism", "Enable only in these game modes, comma-separated (no spaces). Empty = all.", FCVAR_NOTIFY);

    AutoExecConfig(true, "l4d2_finale_specials_cap");

    HookEvent("finale_start", Event_FinaleStart);
    HookEvent("gauntlet_finale_start", Event_FinaleStart);
    HookEvent("finale_vehicle_leaving", Event_FinaleEnd);
    HookEvent("round_end", Event_FinaleEnd);
    HookEvent("map_transition", Event_FinaleEnd);

    RegAdminCmd("sm_specials", Command_Check, ADMFLAG_ROOT);

    g_hMPGameMode = FindConVar("mp_gamemode");
    if (g_hMPGameMode != null)
        g_hMPGameMode.AddChangeHook(Cvar_ModeChanged);
    g_cvModes.AddChangeHook(Cvar_ModeChanged);
    UpdateAllowedGameMode();
}

public void OnMapStart()
{
    g_bInFinale = false;
    UpdateAllowedGameMode();
}

void UpdateAllowedGameMode()
{
    g_bModeAllowed = true;
    char list[256];
    g_cvModes.GetString(list, sizeof(list));
    TrimString(list);
    if (!list[0]) return;

    if (g_hMPGameMode == null)
    {
        g_bModeAllowed = false;
        return;
    }

    char mode[64];
    g_hMPGameMode.GetString(mode, sizeof(mode));
    TrimString(mode);

    char hay[320], needle[96];
    Format(hay, sizeof(hay), ",%s,", list);
    Format(needle, sizeof(needle), ",%s,", mode);
    g_bModeAllowed = (StrContains(hay, needle, false) != -1);
}

public void Cvar_ModeChanged(ConVar cvar, const char[] oldV, const char[] newV)
{
    UpdateAllowedGameMode();
}

void Event_FinaleStart(Event event, const char[] name, bool dontBroadcast)
{
    g_bInFinale = true;
}

void Event_FinaleEnd(Event event, const char[] name, bool dontBroadcast)
{
    g_bInFinale = false;
}

bool IsRootAdmin(int client)
{
    return client > 0 && IsClientInGame(client) && GetUserFlagBits(client) & ADMFLAG_ROOT;
}

void PrintToRootAdmins(const char[] msg)
{
    for (int i = 1; i <= MaxClients; i++)
        if (IsRootAdmin(i))
            PrintToChat(i, msg);
}

int GetAliveSpecialCount()
{
    int count = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i)) continue;
        if (GetClientTeam(i) != 3) continue;
        if (!IsPlayerAlive(i)) continue;

        int zombieClass = GetEntProp(i, Prop_Send, "m_zombieClass");
        if (zombieClass < 1 || zombieClass > 6) continue;
        if (GetEntProp(i, Prop_Send, "m_isGhost") == 1) continue;

        count++;
    }
    return count;
}

public Action L4D_OnSpawnSpecial(int &zombieClass, const float vecOrigin[3], const float vecAngles[3])
{
    if (!g_cvEnable.BoolValue || !g_bModeAllowed || !g_bInFinale)
        return Plugin_Continue;

    int limit = g_cvFinaleSpecialsLimit.IntValue;
    int alive = GetAliveSpecialCount();

    if (alive >= limit)
    {
        if (g_cvVerbose.BoolValue)
        {
            char msg[128];
            Format(msg, sizeof(msg), "\x04[Specials]\x01 Spawn blocked (alive: \x05%d\x01 / \x05%d\x01)", alive, limit);
            PrintToRootAdmins(msg);
        }
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

public Action Command_Check(int client, int args)
{
    int alive = GetAliveSpecialCount();
    int limit = g_cvFinaleSpecialsLimit.IntValue;
    ReplyToCommand(client, "\x04[Specials]\x01 Alive: \x05%d\x01 / \x05%d\x01 (Finale: \x05%s\x01)", alive, limit, g_bInFinale ? "Yes" : "No");
    return Plugin_Handled;
}