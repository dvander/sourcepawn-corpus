#include <sourcemod>
#include <sdktools>

// 1. I do not know if there is a better way to do this
// 2. I do not care, this works.
// 3. If there is a better way to do this, please steal this code and make it better becuase:
// 4. I do not care.
// Usage: in console type "sm_mvmround" and it will spit out the current wave and the max waves.

new const String:PLUGIN_VERSION[] = "1.1";

public Plugin:myinfo =
{
    name = "MvM Round Reporter",
    author = "doc",
    description = "Returns the current and total waves for the current MvM game.",
    version = PLUGIN_VERSION,
    url = "http://cafeofbrokendreams.com"
};

public OnPluginStart ()
{
    CreateConVar("sm_mvmround_version", PLUGIN_VERSION, "Version of MvM Round Reporter", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    RegConsoleCmd("sm_mvmround", Command_MVMRound)
}

public Action:Command_MVMRound(client, args)
{
    if (!GameRules_GetProp("m_bPlayingMannVsMachine"))
    {
        return Plugin_Handled;
    }

    new ent, round, maxrnd

    ent = FindEntityByClassname(-1, "tf_objective_resource");
    round = GetEntProp(ent, Prop_Send, "m_nMannVsMachineWaveCount");
    maxrnd = GetEntProp(ent, Prop_Send, "m_nMannVsMachineMaxWaveCount");

    ReplyToCommand(client, "%i/%i", round, maxrnd);

    return Plugin_Handled;
}

