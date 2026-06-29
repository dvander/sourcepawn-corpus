#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "2.0"

public Plugin myinfo =
{
    name        = "[L4D2] Rescue Vehicle Glow",
    author      = "Support by Chat GPT, and thaivanco123 (this guy's script helped me a lot with this version.), made by Kayle Tid",
    description = "Glow all rescue vehicles on official maps",
    version     = PLUGIN_VERSION,
    url         = "https://forums.alliedmods.net/showthread.php?t=352703"
};

ConVar g_hEnable;
ConVar g_hGlowColor;
ConVar g_hGlowRange;
ConVar g_hGlowFlashing;

bool g_bFinaleReady = false;

char g_sClassnames[][] =
{
    "prop_dynamic",
    "prop_dynamic_override",
    "prop_physics",
    "prop_physics_override",
    "prop_vehicle",
    "prop_vehicle_driveable",
    "func_tracktrain",
    "func_brush"
};

char g_sModels[][] =
{
    "helicopter",
    "chopper",
    "heli",
    "rescue_heli",
    "rescue_vehicle",
    "finale_vehicle",
    "escape_plane",
    "plane_rescue",
    "c130",
    "boat_rescue",
    "ferry",
    "barge",
    "houseboat",
    "riverboat",
    "rescue_boat",
    "train_rescue",
    "train_enginecar",
    "train_boxcar",
    "getaway_vehicle",
    "apc",
    "armored",
    "military",
    "locomotive",
    "subway",
    "metro"
};

char g_sTargetnames[][] =
{
    "rescue_vehicle",
    "escape_vehicle",
    "finale_vehicle",
    "rescue_heli",
    "escape",
    "apc",
    "rescue_apc",
    "boat",
    "houseboat",
    "helicopter_brush",
    "rescue_boat",
    "rescue_train",
    "rescue_plane",
    "getaway_car",
    "rescue"
};

public void OnPluginStart()
{
    g_hEnable       = CreateConVar("sm_rescue_glow_enable", "1", "Enable/Disable plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hGlowColor    = CreateConVar("sm_rescue_glow_color", "0 255 100", "Glow color RGB", FCVAR_NOTIFY);
    g_hGlowRange    = CreateConVar("sm_rescue_glow_range", "99999", "Glow range", FCVAR_NOTIFY, true, 0.0);
    g_hGlowFlashing = CreateConVar("sm_rescue_glow_flashing", "0", "Enable flashing effect", FCVAR_NOTIFY, true, 0.0, true, 1.0);

    HookEvent("finale_vehicle_ready", Event_FinaleVehicleReady);
    HookEvent("finale_vehicle_leaving", Event_FinaleVehicleLeaving);
    HookEvent("finale_win", Event_FinaleEnd);
    HookEvent("mission_lost", Event_Reset);
    HookEvent("round_start", Event_Reset);
    HookEvent("round_end", Event_Reset);
    HookEvent("map_transition", Event_Reset);

    AutoExecConfig(true, "l4d2_rescue_vehicle_glow");
}

public void OnMapStart()
{
    g_bFinaleReady = false;
}

void Event_FinaleVehicleReady(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_hEnable.BoolValue)
        return;

    g_bFinaleReady = true;

    CreateTimer(1.0, Timer_ApplyGlow, _, TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_ApplyGlow(Handle timer)
{
    ApplyGlowToVehicles();
    return Plugin_Handled;
}

void ApplyGlowToVehicles()
{
    if (!g_hEnable.BoolValue || !g_bFinaleReady)
        return;

    char model[256];
    char targetname[128];
    char mapname[128];

    GetCurrentMap(mapname, sizeof(mapname));

    bool found = false;

    for (int c = 0; c < sizeof(g_sClassnames); c++)
    {
        int entity = -1;

        while ((entity = FindEntityByClassname(entity, g_sClassnames[c])) != -1)
        {
            if (!IsValidEntity(entity))
                continue;

            if (!HasEntProp(entity, Prop_Data, "m_ModelName"))
                continue;

            GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));

            if (model[0] == '\0')
                continue;

            GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

            bool isRescue = false;

            if (StrEqual(mapname, "c3m4_plantation", false))
            {
                if (
                    StrContains(model, "boat", false) == -1 &&
                    StrContains(model, "ferry", false) == -1 &&
                    StrContains(model, "barge", false) == -1 &&
                    StrContains(model, "riverboat", false) == -1
                )
                {
                    continue;
                }
            }

            // MODEL CHECK
            for (int i = 0; i < sizeof(g_sModels); i++)
            {
                if (StrContains(model, g_sModels[i], false) != -1)
                {
                    isRescue = true;
                    break;
                }
            }

            // TARGETNAME CHECK
            if (!isRescue)
            {
                for (int i = 0; i < sizeof(g_sTargetnames); i++)
                {
                    if (StrContains(targetname, g_sTargetnames[i], false) != -1)
                    {
                        isRescue = true;
                        break;
                    }
                }
            }

            if (!isRescue)
                continue;

            ApplyGlow(entity);

            found = true;
        }
    }

    if (found)
    {
        PrintToServer("[Rescue Glow] Rescue vehicle highlighted successfully on map: %s", mapname);

        PrintToChatAll(
            "\x04[Rescue]\x01 The rescue team has arrived, run to the glowing area to escape!"
        );
    }
    else
    {
        PrintToServer("[Rescue Glow] Could not detect rescue vehicle on map: %s", mapname);
    }
}

void ApplyGlow(int entity)
{
    if (!IsValidEntity(entity))
        return;

    SetEntProp(entity, Prop_Send, "m_iGlowType", 3);

    SetEntProp(entity, Prop_Send, "m_nGlowRange", g_hGlowRange.IntValue);

    SetEntProp(entity, Prop_Send, "m_nGlowRangeMin", 0);

    SetEntProp(entity, Prop_Send, "m_bFlashing", g_hGlowFlashing.IntValue);

    char sColor[32];
    g_hGlowColor.GetString(sColor, sizeof(sColor));

    char buffers[3][8];

    int rgb[3] = {0, 255, 100};

    if (ExplodeString(sColor, " ", buffers, sizeof(buffers), sizeof(buffers[])) >= 3)
    {
        rgb[0] = StringToInt(buffers[0]);
        rgb[1] = StringToInt(buffers[1]);
        rgb[2] = StringToInt(buffers[2]);
    }

    int color =
        rgb[0] +
        (rgb[1] << 8) +
        (rgb[2] << 16);

    SetEntProp(entity, Prop_Send, "m_glowColorOverride", color);
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (!g_hEnable.BoolValue || !g_bFinaleReady)
        return;

    for (int i = 0; i < sizeof(g_sClassnames); i++)
    {
        if (StrEqual(classname, g_sClassnames[i], false))
        {
            RequestFrame(CheckNewVehicle, entity);
            break;
        }
    }
}

void CheckNewVehicle(int entity)
{
    if (!g_bFinaleReady || !IsValidEntity(entity))
        return;

    char model[256];
    char targetname[128];
    char mapname[128];

    GetCurrentMap(mapname, sizeof(mapname));

    GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));

    GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

    if (StrEqual(mapname, "c3m4_plantation", false))
    {
        if (
            StrContains(model, "boat", false) == -1 &&
            StrContains(model, "ferry", false) == -1 &&
            StrContains(model, "barge", false) == -1 &&
            StrContains(model, "riverboat", false) == -1
        )
        {
            return;
        }
    }

    bool isRescue = false;

    // MODEL CHECK
    for (int i = 0; i < sizeof(g_sModels); i++)
    {
        if (StrContains(model, g_sModels[i], false) != -1)
        {
            isRescue = true;
            break;
        }
    }

    // TARGETNAME CHECK
    if (!isRescue)
    {
        for (int i = 0; i < sizeof(g_sTargetnames); i++)
        {
            if (StrContains(targetname, g_sTargetnames[i], false) != -1)
            {
                isRescue = true;
                break;
            }
        }
    }

    if (isRescue)
    {
        CreateTimer(
            0.5,
            Timer_GlowNewVehicle,
            EntIndexToEntRef(entity),
            TIMER_FLAG_NO_MAPCHANGE
        );
    }
}

Action Timer_GlowNewVehicle(Handle timer, any ref)
{
    int entity = EntRefToEntIndex(ref);

    if (entity != INVALID_ENT_REFERENCE)
    {
        ApplyGlow(entity);
    }

    return Plugin_Handled;
}

void Event_FinaleVehicleLeaving(Event event, const char[] name, bool dontBroadcast)
{
    g_bFinaleReady = false;
    RemoveAllGlows();
}

void Event_FinaleEnd(Event event, const char[] name, bool dontBroadcast)
{
    g_bFinaleReady = false;
    RemoveAllGlows();
}

void Event_Reset(Event event, const char[] name, bool dontBroadcast)
{
    g_bFinaleReady = false;

    RemoveAllGlows();

    PrintToServer("[Rescue Glow] Plugin state reset (%s)", name);
}

void RemoveAllGlows()
{
    for (int c = 0; c < sizeof(g_sClassnames); c++)
    {
        int entity = -1;

        while ((entity = FindEntityByClassname(entity, g_sClassnames[c])) != -1)
        {
            if (!IsValidEntity(entity))
                continue;

            SetEntProp(entity, Prop_Send, "m_iGlowType", 0);
        }
    }
}

public void OnPluginEnd()
{
    g_bFinaleReady = false;

    RemoveAllGlows();
}