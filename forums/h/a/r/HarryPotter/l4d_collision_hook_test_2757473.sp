#include <sourcemod>
#include <sdktools>
#include <dhooks>

Handle g_CHPassEntity;

public Plugin myinfo =
{
    name = "CollisionHook Dhooks",
    author = "$atanic $pirit, BHaType",
    description = "Hook on entity collision",
    version = "1.0",
    url = ""
}

public OnPluginStart()
{
    GameData hData = new GameData("CollisionHook");

    Handle hDetour = DHookCreateFromConf(hData, "PassEntityFilter");
    if( !hDetour ) 
        SetFailState("Failed to find \"PassEntityFilter\" offset.");
        
    if( !DHookEnableDetour(hDetour, true, detour) ) 
        SetFailState("Failed to detour \"PassEntityFilter\".");
    delete hData;
    
    g_CHPassEntity = CreateGlobalForward("CH_PassFilter", ET_Event, Param_Cell, Param_Cell , Param_CellByRef);
}


public MRESReturn detour(Handle hReturn, Handle hParams)
{
    if(!DHookIsNullParam(hParams, 1) && !DHookIsNullParam(hParams, 2))
    {
        int iEntity1    = DHookGetParam(hParams, 1);
        int iEntity2    = DHookGetParam(hParams, 2);
        int funcresult    = DHookGetReturn(hReturn);
        
        if(g_CHPassEntity)
        {
            Action result = Plugin_Continue;
            
            /* Start function call */
            Call_StartForward(g_CHPassEntity);

            /* Push parameters one at a time */
            Call_PushCell(iEntity1);
            Call_PushCell(iEntity2);
            Call_PushCellRef(funcresult);

            /* Finish the call, get the result */
            Call_Finish(result);
            
            if (result == Plugin_Handled)
            {
                DHookSetReturn(hReturn, funcresult);
                return MRES_Supercede;
            }
        }
    }
    
    //PrintToChatAll("Entity 1 %i Entity 2 %i", iEntity1, iEntity2);
    return MRES_Ignored;
} 