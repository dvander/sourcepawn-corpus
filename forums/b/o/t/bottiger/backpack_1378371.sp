#define PLUGIN_VERSION "1.0.6"

#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
    name = "MOTD Backpack Enhanced",
    author = "Bottiger, Munra",
    description = "Opens MOTD with clients TF2items.com backpack",
    version = PLUGIN_VERSION,
    url = "http://skial.com"
}
public OnPluginStart()
{
    CreateConVar("motd_backpack_version", PLUGIN_VERSION, "MOTD Backpack Version", FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    RegConsoleCmd("sm_backpack", bakpak, "Aim at someone and type !backpack or !backpack [playername]");
    RegConsoleCmd("sm_bp", bakpak, "Aim at someone and type !bp or !bp [playername]");
    LoadTranslations("common.phrases");
}

//Displays given player's backpack
public Action:bakpak(client, args) {
    if (client == 0)
        ReplyToCommand(client, "%s", "MOTDBackpack: Can't do command from console");
    
    //Gets target client
    new target;
    if(args == 0) {
        target = GetClientAimTarget(client, true);
    } else {
        decl String:argstring[128];
        GetCmdArgString(argstring, sizeof(argstring));
        target = FindTarget(client, argstring, true, false);
    }
    
    if (target == -1) {
        ReplyToCommand(client, "MOTDBackpack: Could not find target. Please aim at a person or type in their name.");
        return Plugin_Handled;
    }
    
    DisplayBackpack(client, target);
    return Plugin_Handled;
}

public DisplayBackpack(client, target) {
    decl String:communityid[32];
    decl String:itemsurl[128];

    GetClientAuthString(target, communityid, sizeof(communityid));
    Format(itemsurl, sizeof(itemsurl), "http://www.tf2items.com/steamid/%s?wrap=1", communityid);
    ShowMOTDPanel(client, "Backpack", itemsurl, MOTDPANEL_TYPE_URL);
}