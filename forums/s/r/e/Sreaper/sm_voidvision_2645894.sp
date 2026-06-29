#include <sourcemod>
 
#pragma newdecls required
#pragma semicolon 1
 
#define PLUGIN_VERSION "1.1"
 
ConVar g_cvRollingAngle;
 
public Plugin myinfo =
{
    name = "Void Vision",
    author = "Sreap",
    description = "Shows a player the void",
    version = PLUGIN_VERSION,
    url = ""
};
 
public void OnPluginStart()
{
    LoadTranslations("common.phrases");
    RegAdminCmd("sm_void", Command_Void, ADMFLAG_ROOT, "Forces a player to look at the void.");
   
    CreateConVar("sm_void_version", PLUGIN_VERSION, "Plugin Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    g_cvRollingAngle = FindConVar("sv_rollangle");
}
public Action Command_Void(int client, int args)
{
    // Switched this to 1 so the command can also function as a toggle
    // i.e. "sm_void @me" used repeatedly will toggle between on and off
    // If this was set to 2, it would require a 0/1 value no matter what.
    if (args < 1)
    {
        ReplyToCommand(client, "[SM] Usage: sm_void <#userid|name> <1/0>");
        return Plugin_Handled;
    }
   
    char arg1[MAX_TARGET_LENGTH];
    char arg2[2];
    GetCmdArg(1, arg1, sizeof(arg1));
    GetCmdArg(2, arg2, sizeof(arg2));
 
    // Re-interpret the 2nd argument string as a boolean true/false value
    bool voided = view_as<bool>(StringToInt(arg2));
   
    char target_name[MAX_TARGET_LENGTH];
    int target_list[MAXPLAYERS], target_count;
    bool tn_is_ml;
   
    if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
    {
        ReplyToTargetError(client, target_count);
        return Plugin_Handled;
    }
    for (int i = 0; i < target_count; i++)
    {
   		if(IsFakeClient(target_list[i])) continue;
   
		SendConVarValue(target_list[i], g_cvRollingAngle, voided ? "999999999999999999999999999999999999999" : "0");
		LogAction(client, target_list[i], "\"%n\" %s the void to \"%n\".", client, (voided ? "Showed" : "Stopped showing"), target_list[i]);

    }    
    ShowActivity2(client, "[SM] ", "%s the void to %s.", (voided ? "Showed" : "Stopped showing"), target_name);
    return Plugin_Handled;
}



