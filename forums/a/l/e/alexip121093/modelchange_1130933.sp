#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

#define MODEL_BILL "models/survivors/survivor_namvet.mdl"
#define MODEL_FRANCIS "models/survivors/survivor_biker.mdl"
#define MODEL_LOUIS "models/survivors/survivor_manager.mdl"
#define MODEL_ZOEY "models/survivors/survivor_teenangst.mdl"
#define MODEL_KEITH "models/bloocobalt/l4d/survivors/survivor_keith.mdl"
public OnPluginStart()
{
    RegConsoleCmd("say", Command_Say);
}

public OnMapStart()
{
    PrecacheModel(MODEL_BILL, true);
    PrecacheModel(MODEL_FRANCIS, true);
    PrecacheModel(MODEL_LOUIS, true);
    PrecacheModel(MODEL_ZOEY, true);
    PrecacheModel(MODEL_KEITH, true);
}

public Action:Command_Say(client, args)
{
    if (args < 1)
    {
        return Plugin_Continue;
    }
    
    decl String:text[15];
    GetCmdArg(1, text, sizeof(text));
    
    if (StrContains(text, "!bill") == 0)
    {
        ChangeModel(client, client, MODEL_BILL);
        return Plugin_Handled;
    }
    else if (StrContains(text, "!francis") == 0)
    {
        ChangeModel(client, client, MODEL_FRANCIS);
        return Plugin_Handled;
    }
    else if (StrContains(text, "!louis") == 0)
    {
        ChangeModel(client, client, MODEL_LOUIS);
        return Plugin_Handled;
    }
    else if (StrContains(text, "!zoey") == 0)
    {
        ChangeModel(client, client, MODEL_ZOEY);
        return Plugin_Handled;
    }
    else if (StrContains(text, "!keith") == 0)
    {
        ChangeModel(client, client, MODEL_KEITH);
        return Plugin_Handled;
    }
    return Plugin_Continue;
}


ChangeModel(client, target, String:model[])
{
    if (!IsClientInGame(target))
    {
        PrintToChat(client, "Target not ingame, fail!");
        return;
    }
    
    if (GetClientTeam(target) != 2)
    {
        PrintToChat(client, "Target no survivor, fail!");
        return;
    }
            
    SetEntityModel(target, model);
}  
