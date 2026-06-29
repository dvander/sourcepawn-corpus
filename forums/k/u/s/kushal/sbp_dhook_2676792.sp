#pragma semicolon 1

#include <sourcemod>
#include <dhooks>
#include <sdktools>

#pragma newdecls required

Handle g_hClientPrintf = null;

char g_sLogs[PLATFORM_MAX_PATH + 1];

public Plugin myinfo =
{
    name = "Hide Plugin List",
    description = "Block People From stealing your Plugins",
    author = "[PewDiePie]",
    version = "1.0.0",
    url = ""
};

public void OnPluginStart()
{    
    Handle gameconf = LoadGameConfigFile("sbp.games");
    if(gameconf == null)
    {
        SetFailState("Failed to find sbp.games.txt gamedata");
        delete gameconf;
    }
    
    int offset = GameConfGetOffset(gameconf, "ClientPrintf");
    if(offset == -1)
    {
        SetFailState("Failed to find offset for ClientPrintf");
        delete gameconf;
    }
    
    StartPrepSDKCall(SDKCall_Static);
    
    if(!PrepSDKCall_SetFromConf(gameconf, SDKConf_Signature, "CreateInterface"))
    {
        SetFailState("Failed to get CreateInterface");
        delete gameconf;
    }
    
    PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
    
    char identifier[64];
    if(!GameConfGetKeyValue(gameconf, "EngineInterface", identifier, sizeof(identifier)))
    {
        SetFailState("Failed to get engine identifier name");
        delete gameconf;
    }
    
    Handle temp = EndPrepSDKCall();
    Address addr = SDKCall(temp, identifier, 0);
    
    delete gameconf;
    delete temp;
    
    if(!addr)
    {
        SetFailState("Failed to get engine ptr");
    }
    
    g_hClientPrintf = DHookCreate(offset, HookType_Raw, ReturnType_Void, ThisPointer_Ignore, Hook_ClientPrintf);
    DHookAddParam(g_hClientPrintf, HookParamType_Edict);
    DHookAddParam(g_hClientPrintf, HookParamType_CharPtr);
    DHookRaw(g_hClientPrintf, false, addr);
    
    char sDate[18];
    FormatTime(sDate, sizeof(sDate), "%y-%m-%d");
    BuildPath(Path_SM, g_sLogs, sizeof(g_sLogs), "logs/sbp-%s.log", sDate);
}

public MRESReturn Hook_ClientPrintf(Handle hParams)
{
    char sBuffer[1024];
    int client = DHookGetParam(hParams, 1);
    
    if (client == 0)
    {
        return MRES_Ignored;
    }
    
    DHookGetParamString(hParams, 2, sBuffer, sizeof(sBuffer));
    
    if(sBuffer[1] == '"' && (StrContains(sBuffer, "\" (") != -1 || (StrContains(sBuffer, ".smx\" ") != -1))) 
    {
        DHookSetParamString(hParams, 2, "");
        return MRES_ChangedHandled;
    }
    else if(StrContains(sBuffer, "To see more, type \"sm plugins") != -1)
    {
        if (client > 0 && IsClientInGame(client) && !IsFakeClient(client) && !IsClientSourceTV(client))
        {
            if (CheckCommandAccess(client, "sm_admin", ADMFLAG_ROOT, true))
            {
                return MRES_Ignored;
            }
            
                PrintToConsole(iClient, "   ¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶\n \
                                            ¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶\n \
                                            ¶¶¶¶¶¶¶¶¶¶¶¶GET LOST YOU STEALER¶¶¶¶¶¶¶¶¶¶¶¶\n \
                                            ¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶DONT STEAL MY¶¶¶¶¶¶¶¶¶¶¶¶¶¶\n \
                                            ¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶PLUGINS¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶\n \
                                            ¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶\n \
                                            ¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶CODED BY PEWDIEPIE¶¶¶¶¶¶¶¶¶¶¶");
            PrintToConsole(client, "\t\tNo chance\n");

            LogToFile(g_sLogs, "\"%L\" tried to get the plugin list", client);
        }
        
        return MRES_ChangedHandled;
    }
    return MRES_Ignored;
}  