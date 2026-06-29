#include <sourcemod>
#include <sdktools>
#include <dhooks>

public OnPluginStart()
{
    GameData hData = new GameData("l4dcollisionhook");
    
    Handle hDetour = DHookCreateFromConf(hData, "PassEntityFilter");
    if( !hDetour ) SetFailState("Failed to find \"PassEntityFilter\" offset.");
    if( !DHookEnableDetour(hDetour, true, detour) ) SetFailState("Failed to detour \"PassEntityFilter\".");
    delete hData;
}


public MRESReturn detour(Handle hReturn, Handle hParams)
{
    PrintToServer("Entity 1 %i Entity 2 %i", DHookGetParam(hParams, 1), DHookGetParam(hParams, 2));
    return MRES_Ignored;
} 