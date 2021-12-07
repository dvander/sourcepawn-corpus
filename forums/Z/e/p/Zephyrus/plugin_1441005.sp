#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.1"

public Plugin:myinfo = 
{
    name = "Give Weapon",
    author = "Zephyrus",
    description = "",
    version = PLUGIN_VERSION,
    url = ""
}

public OnPluginStart()
{
    RegConsoleCmd("sm_weapon", Command_Give);
}
    
public Action:Command_Give(client, args)
{
    new String:weapon[64];
    new String:name[64];

    GetCmdArg(1, name, sizeof(name));
    GetCmdArg(2, weapon, sizeof(weapon));

    new target = FindTarget(client, name);

    GivePlayerItem(target, weapon);
    return Plugin_Handled;
}

