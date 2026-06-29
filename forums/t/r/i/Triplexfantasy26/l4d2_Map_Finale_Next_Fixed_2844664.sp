#pragma semicolon 1
#include <sourcemod>
#pragma newdecls required

char g_Map[48];
char g_Mode[24];
bool g_Coop;

public Plugin myinfo =
{
    name = "[L4D2] mapfinalenext FIXED",
    author = "LethimCook!!",
    description = "Changes campaign only after finale completion",
    version = "2.0"
};

public void OnPluginStart()
{
    HookEvent("finale_win", Event_FinalWin, EventHookMode_PostNoCopy);
}

public void OnMapStart()
{
    GetCurrentMap(g_Map, sizeof(g_Map));
    GetConVarString(FindConVar("mp_gamemode"), g_Mode, sizeof(g_Mode));

    g_Coop = (!strcmp(g_Mode, "coop", false) || !strcmp(g_Mode, "realism", false));
}

public Action Timer_NextCampaign(Handle timer)
{
    if (StrContains(g_Map, "c1m", false) != -1) { ServerCommand("changelevel c2m1_highway"); return Plugin_Stop; }      // Dead Center -> Dark Carnival
    if (StrContains(g_Map, "c2m", false) != -1) { ServerCommand("changelevel c3m1_plankcountry"); return Plugin_Stop; } // Dark Carnival -> Swamp Fever
    if (StrContains(g_Map, "c3m", false) != -1) { ServerCommand("changelevel c4m1_milltown_a"); return Plugin_Stop; }  // Swamp Fever -> Hard Rain
    if (StrContains(g_Map, "c4m", false) != -1) { ServerCommand("changelevel c5m1_waterfront"); return Plugin_Stop; }  // Hard Rain -> The Parish
    if (StrContains(g_Map, "c5m", false) != -1) { ServerCommand("changelevel c6m1_riverbank"); return Plugin_Stop; }   // The Parish -> The Passing
    if (StrContains(g_Map, "c6m", false) != -1) { ServerCommand("changelevel c7m1_docks"); return Plugin_Stop; }       // The Passing -> The Sacrifice
    if (StrContains(g_Map, "c7m", false) != -1) { ServerCommand("changelevel c8m1_apartment"); return Plugin_Stop; }   // The Sacrifice -> No Mercy
    if (StrContains(g_Map, "c8m", false) != -1) { ServerCommand("changelevel c9m1_alleys"); return Plugin_Stop; }      // No Mercy -> Crash Course
    if (StrContains(g_Map, "c9m", false) != -1) { ServerCommand("changelevel c10m1_caves"); return Plugin_Stop; }      // Crash Course -> Death Toll
    if (StrContains(g_Map, "c10m", false) != -1) { ServerCommand("changelevel c11m1_greenhouse"); return Plugin_Stop; } // Death Toll -> Dead Air
    if (StrContains(g_Map, "c11m", false) != -1) { ServerCommand("changelevel c12m1_hilltop"); return Plugin_Stop; }   // Dead Air -> Blood Harvest
    if (StrContains(g_Map, "c12m", false) != -1) { ServerCommand("changelevel c13m1_alpinecreek"); return Plugin_Stop; } // Blood Harvest -> Cold Stream
    if (StrContains(g_Map, "c13m", false) != -1) { ServerCommand("changelevel c14m1_junkyard"); return Plugin_Stop; }  // Cold Stream -> Last Stand

    ServerCommand("changelevel c1m1_hotel"); // restart cycle
    return Plugin_Stop;
}

public void Event_FinalWin(Event event, const char[] name, bool dontBroadcast)
{
    if (g_Coop)
    {
        CreateTimer(5.0, Timer_NextCampaign, _, TIMER_FLAG_NO_MAPCHANGE);
    }
}
