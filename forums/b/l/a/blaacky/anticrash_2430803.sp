#include <sdktools>
#include <dhooks>

Handle g_hTeleport;

public void OnAllPluginsLoaded()
{
	if(g_hTeleport == INVALID_HANDLE && LibraryExists("dhooks"))
	{
		Handle hGameData = LoadGameConfigFile("sdktools.games");
		if(hGameData == INVALID_HANDLE)
            return;
        
		int iOffset = GameConfGetOffset(hGameData, "Teleport");
        
		CloseHandle(hGameData);
        
		if(iOffset == -1)
			return;
        
		g_hTeleport = DHookCreate(iOffset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, Hook_DHooks_Teleport);

		if(g_hTeleport == INVALID_HANDLE){
			PrintToServer("\n!! g_hTeleport -> INVALID_HANDLE !!\n");
			return;
		}

		DHookAddParam(g_hTeleport, HookParamType_VectorPtr);
		DHookAddParam(g_hTeleport, HookParamType_ObjectPtr);
		DHookAddParam(g_hTeleport, HookParamType_VectorPtr);
		DHookAddParam(g_hTeleport, HookParamType_Bool); // CS:GO only

		for(int i=1;i<=MaxClients;i++)
		{
			if(IsClientInGame(i))
				OnClientPutInServer(i);
		}
	}
}

public void OnLibraryAdded(const char[] name)
{
    if(StrEqual(name, "dhooks") && g_hTeleport == INVALID_HANDLE)
	{
        Handle hGameData = LoadGameConfigFile("sdktools.games");
        if(hGameData == INVALID_HANDLE)
            return;
        
        int iOffset = GameConfGetOffset(hGameData, "Teleport");
        
        CloseHandle(hGameData);
        
        if(iOffset == -1)
            return;
        
        g_hTeleport = DHookCreate(iOffset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, Hook_DHooks_Teleport);
        
        if(g_hTeleport == INVALID_HANDLE){
            PrintToServer("\n!! g_hTeleport -> INVALID_HANDLE !!\n");
            return;
        }
        
        DHookAddParam(g_hTeleport, HookParamType_VectorPtr);
        DHookAddParam(g_hTeleport, HookParamType_ObjectPtr);
        DHookAddParam(g_hTeleport, HookParamType_VectorPtr);
        DHookAddParam(g_hTeleport, HookParamType_Bool); // CS:GO only
        
        for(int i=1;i<=MaxClients;i++)
        {
            if(IsClientInGame(i))
                OnClientPutInServer(i);
        }
    }
}

public void OnClientPutInServer(int client)
{
    if(g_hTeleport != INVALID_HANDLE)
	{
		DHookEntity(g_hTeleport, false, client);
	}
}

public MRESReturn Hook_DHooks_Teleport(int client, Handle hParams)
{
    if(!IsClientConnected(client) || IsFakeClient(client) || !IsPlayerAlive(client))
        return MRES_Ignored;
    
    if(!DHookIsNullParam(hParams, 2))
	{
        float angles[3];
        for(int i=0;i<3;i++)
		{
            angles[i] = DHookGetParamObjectPtrVar(hParams, 2, i*4, ObjectValueType_Float);
            
            if(IsBadAngle(angles[i]))
				return MRES_Supercede;
        }
    }
    
    return MRES_Ignored;
}

public bool IsBadAngle(float angle)
{
    return angle > 180.0 || angle < -180.0;
}