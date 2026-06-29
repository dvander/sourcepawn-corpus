#include <sourcemod>
#include <sdktools>

ConVar g_cvEnable;
ConVar g_cvTargetSize;
ConVar g_cvModes;
ConVar g_cvCustomOnly;
ConVar g_cvDebug;
ConVar g_hMPGameMode;

int g_iOriginalSize = -1;
bool g_bInFinale;
bool g_bModeAllowed;
bool g_bCustomCampaign;

public Plugin myinfo =
{
    name = "L4D2 Finale MegaMob Size",
    author = "Tighty-Whitey",
    version = "1.0",
    description = "Silently change z_mega_mob_size during finales."
};

public void OnPluginStart()
{
    g_cvEnable       = CreateConVar("l4d2_finale_megamob_enable",      "1",  "Enable Finale MegaMob Size plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvTargetSize   = CreateConVar("l4d2_finale_megamob_size",        "80", "z_mega_mob_size value during finales");
    g_cvModes        = CreateConVar("l4d2_finale_megamob_modes",       "",   "Game modes to work in (comma-separated, no spaces). Empty = all.", FCVAR_NOTIFY);
    g_cvCustomOnly   = CreateConVar("l4d2_finale_megamob_customonly", "0",  "Only change cvar in custom (non-Valve) campaigns", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvDebug        = CreateConVar("l4d2_finale_megamob_debug",      "0",  "Print change events to server console (0=off, 1=on)");

    AutoExecConfig(true, "l4d2_finale_mega_mob_size");

    HookEvent("finale_start",           Event_FinaleStart);
    HookEvent("gauntlet_finale_start",  Event_FinaleStart);
    HookEvent("finale_vehicle_leaving", Event_FinaleEnd);
    HookEvent("round_end",              Event_FinaleEnd);
    HookEvent("map_transition",         Event_FinaleEnd);
    HookEvent("round_start",            Event_RoundStart, EventHookMode_PostNoCopy);

    RegAdminCmd("sm_megamob", Command_Check, ADMFLAG_ROOT);

    g_hMPGameMode = FindConVar("mp_gamemode");
    if (g_hMPGameMode != null)
        g_hMPGameMode.AddChangeHook(Cvar_ModeChanged);
    g_cvModes.AddChangeHook(Cvar_ModeChanged);
}

public void OnMapStart()
{
    g_bInFinale = false;
    UpdateAllowedGameMode();
    DetectCustomCampaign();
    CaptureOriginalValue();
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

void DetectCustomCampaign()
{
    g_bCustomCampaign = false;
    if (!g_cvCustomOnly.BoolValue)
    {
        g_bCustomCampaign = true;
        return;
    }

    char map[128];
    GetCurrentMap(map, sizeof(map));

    static const char official[][] = {
        "c1m1_hotel", "c1m2_streets", "c1m3_mall", "c1m4_atrium",
        "c2m1_highway", "c2m2_fairgrounds", "c2m3_coaster", "c2m4_barns", "c2m5_concert",
        "c3m1_plankcountry", "c3m2_swamp", "c3m3_shantytown", "c3m4_plantation",
        "c4m1_milltown_a", "c4m2_sugarmill_a", "c4m3_sugarmill_b", "c4m4_milltown_b", "c4m5_milltown_escape",
        "c5m1_waterfront", "c5m2_park", "c5m3_cemetery", "c5m4_quarter", "c5m5_bridge",
        "c6m1_riverbank", "c6m2_bedlam", "c6m3_port",
        "c7m1_docks", "c7m2_barge", "c7m3_port",
        "c8m1_apartment", "c8m2_subway", "c8m3_sewers", "c8m4_interior", "c8m5_rooftop",
        "c9m1_alleys", "c9m2_lots",
        "c10m1_caves", "c10m2_drainage", "c10m3_ranchhouse", "c10m4_mainstreet", "c10m5_houseboat",
        "c11m1_greenhouse", "c11m2_offices", "c11m3_garage", "c11m4_terminal", "c11m5_runway",
        "c12m1_hilltop", "c12m2_traintunnel", "c12m3_bridge", "c12m4_barn", "c12m5_cornfield",
        "c13m1_alpinecreek", "c13m2_southpinestream", "c13m3_memorialbridge", "c13m4_cutthroatcreek",
        "c14m1_junkyard", "c14m2_lighthouse"
    };

    for (int i = 0; i < sizeof(official); i++)
    {
        if (strcmp(map, official[i], false) == 0)
        {
            return; // exact match → official map
        }
    }
    g_bCustomCampaign = true; // any other map name → custom
}

void CaptureOriginalValue()
{
    ConVar hCvar = FindConVar("z_mega_mob_size");
    if (hCvar != null)
        g_iOriginalSize = hCvar.IntValue;
    else
        g_iOriginalSize = -1;
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    CaptureOriginalValue();
}

void Event_FinaleStart(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_cvEnable.BoolValue || !g_bModeAllowed || !g_bCustomCampaign) return;

    g_bInFinale = true;
    int target = g_cvTargetSize.IntValue;

    ConVar hCvar = FindConVar("z_mega_mob_size");
    if (hCvar != null)
    {
        hCvar.IntValue = target;
        if (g_cvDebug.BoolValue)
            PrintToServer("[Megamob] Finale start: set z_mega_mob_size to %d", target);
    }
}

void Event_FinaleEnd(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bInFinale) return;

    g_bInFinale = false;
    RestoreValue();
}

void RestoreValue()
{
    if (g_iOriginalSize < 0) return;

    ConVar hCvar = FindConVar("z_mega_mob_size");
    if (hCvar != null)
    {
        hCvar.IntValue = g_iOriginalSize;
        if (g_cvDebug.BoolValue)
            PrintToServer("[Megamob] Finale end: restored z_mega_mob_size to %d", g_iOriginalSize);
    }
}

public Action Command_Check(int client, int args)
{
    ConVar hCvar = FindConVar("z_mega_mob_size");
    int val = hCvar != null ? hCvar.IntValue : -1;
    ReplyToCommand(client,
        "\x04[Megamob]\x01 Current z_mega_mob_size: \x05%d\x01 (Original: \x05%d\x01, In finale: \x05%s\x01)",
        val, g_iOriginalSize, g_bInFinale ? "Yes" : "No");
    return Plugin_Handled;
}