#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
    name = "[NMRiH] Objective Respawns",
    author = "Ryan.",
    description = "Players respawn every time 'sm_objective_respawn' objectives are completed.",
    version = "1.0",
    url = ""
};

int g_objective_count;
ConVar g_cvar_enabled;

public void OnPluginStart()
{
    HookEvent("nmrih_round_begin", Event_RoundBegin);
    HookEntityOutput("nmrih_objective_boundary", "OnObjectiveBegin", Output_OnObjectiveBegin);

    g_cvar_enabled = CreateConVar("sm_objective_respawn", "1",
        "Number of objectives between player respawns. 1 means every objective is a respawn. 2 is every other objective. 0 disables plugin.");

    g_objective_count = 0;

    AutoExecConfig(true);
}

public void Event_RoundBegin(Event event, const char[] name, bool no_broadcast)
{
    // -1 because round begins right after round starts.
    g_objective_count = -1;
}

public void Output_OnObjectiveBegin(const char[] output, int caller, int activator, float delay)
{
    ++g_objective_count;

    int period = g_cvar_enabled.IntValue;
    if (period > 0 && g_objective_count > 0 && (g_objective_count % period == 0))
    {
        int spawn_point = -1;
        while ((spawn_point = FindEntityByClassname(spawn_point, "info_player_nmrih")) != -1)
        {
            AcceptEntityInput(spawn_point, "RespawnPlayers");
        }
    }
}
