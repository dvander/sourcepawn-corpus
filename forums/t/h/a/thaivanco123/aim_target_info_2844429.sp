#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
    name = "Aim Target Info",
    author = "Nah Nah",
    description = "Retrieve information about the entity you are aiming at",
    version = "1.0",
    url = ""
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_aiminfo", Command_AimInfo, "Display information about the entity you are aiming at");
}

Action Command_AimInfo(int client, int args)
{
    if( !client )
    {
        ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
        return Plugin_Handled;
    }

    if( !IsClientInGame(client) || !IsPlayerAlive(client) )
    {
        ReplyToCommand(client, "[SM] This command can only be used in-game while alive.");
        return Plugin_Handled;
    }

    int entity = GetClientAimTarget(client, false);

    if( entity == -1 )
    {
        ReplyToCommand(client, "[SM] You are not looking at any entity.");
        return Plugin_Handled;
    }
    if( entity == -2 )
    {
        ReplyToCommand(client, "[SM] You are looking at another player (not an entity).");
        return Plugin_Handled;
    }

    char className[64];
    GetEdictClassname(entity, className, sizeof(className));

    char modelName[PLATFORM_MAX_PATH];
    GetEntPropString(entity, Prop_Data, "m_ModelName", modelName, sizeof(modelName));

    char targetName[64];
    GetEntPropString(entity, Prop_Data, "m_iName", targetName, sizeof(targetName));

    PrintToChat(client, "\x04[AIM]\x01 Class: \x05%s\x01 | Model: \x05%s\x01 | Name: \x05%s\x01", 
        className, modelName[0] ? modelName : "(none)", targetName[0] ? targetName : "(none)");
    
    PrintToConsole(client, "[AIM] Entity Index: %d", entity);
    PrintToConsole(client, "[AIM] Classname: %s", className);
    PrintToConsole(client, "[AIM] m_ModelName: %s", modelName[0] ? modelName : "(no model)");
    PrintToConsole(client, "[AIM] m_iName: %s", targetName[0] ? targetName : "(no targetname)");

    return Plugin_Handled;
}