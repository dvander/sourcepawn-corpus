#include <sourcemod>
#include <dhooks>
#include <sdktools>

new Handle:hClientPrintf = INVALID_HANDLE;

public OnPluginStart()
{    
    new Handle:gameconf = LoadGameConfigFile("clientprintf-hook.games");
    if(gameconf == INVALID_HANDLE)
    {
        SetFailState("Failed to find clientprintf-hook.games.txt gamedata");
    }
    new offset = GameConfGetOffset(gameconf, "ClientPrintf");
    if(offset == -1)
    {
        SetFailState("Failed to find offset for ClientPrintf");
        CloseHandle(gameconf);
    }
    StartPrepSDKCall(SDKCall_Static);
    if(!PrepSDKCall_SetFromConf(gameconf, SDKConf_Signature, "CreateInterface"))
    {
        SetFailState("Failed to get CreateInterface");
        CloseHandle(gameconf);
    }
    
    PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
    
    new String:interface[64];
    if(!GameConfGetKeyValue(gameconf, "EngineInterface", interface, sizeof(interface)))
    {
        SetFailState("Failed to get engine interface name");
        CloseHandle(gameconf);
    }
    
    new Handle:temp = EndPrepSDKCall();
    new Address:addr = SDKCall(temp, interface, 0);
    
    CloseHandle(gameconf);
    CloseHandle(temp);
    
    if(!addr) SetFailState("Failed to get engine ptr");
    
    hClientPrintf = DHookCreate(offset, HookType_Raw, ReturnType_Void, ThisPointer_Ignore, Hook_ClientPrintf);
    DHookAddParam(hClientPrintf, HookParamType_Edict);
    DHookAddParam(hClientPrintf, HookParamType_CharPtr);
    DHookRaw(hClientPrintf, false, addr);
}
public MRESReturn:Hook_ClientPrintf(Handle:hParams)
{
	decl String:buffer[1024];
	DHookGetParamString(hParams, 2, buffer, 1024);
	if(StrContains(buffer, "Введите в чат !нож") != -1) 
	{
		DHookSetParamString(hParams, 2, "Введите в чат !knife");
		return MRES_ChangedHandled;
	}
	return MRES_Ignored;
}  