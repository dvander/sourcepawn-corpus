/* vim: set filetype=c : */
#pragma semicolon 1

#include <sourcemod>

public Plugin:myinfo = {
    name = "Custom Spy Variables",
    author = "Author",
    description = "Description",
    version = "0.0.0.0",
    url = "Internet"
};

public OnPluginStart() {
    SetConVarFloat(FindConVar("tf_spy_cloak_consume_rate"), 10.0);
    SetConVarFloat(FindConVar("tf_spy_cloak_regen_rate"), 10.0);
    SetConVarFloat(FindConVar("tf_spy_cloak_no_attack_time"), 0.0);
    SetConVarFloat(FindConVar("tf_spy_invis_time"), 1.0);
    SetConVarFloat(FindConVar("tf_spy_invis_unstealth_time"), 0.0);
}
