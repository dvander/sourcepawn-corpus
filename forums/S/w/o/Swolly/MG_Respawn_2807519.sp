#include <sourcemod>
#include <cstrike>

#pragma tabsize 0

ConVar cSure;

public OnPluginStart()
{
    RegAdminCmd("sm_mrespawn", Respawn, ADMFLAG_GENERIC);
    RegAdminCmd("sm_mres", Respawn, ADMFLAG_GENERIC);
     
    cSure = CreateConVar("mg_respawn_sure", "10", "remove godmode after a certain time after respawn");
    AutoExecConfig(true, "MG_Respawn", "Plugincim_com");
}

public Action Respawn(iClient, iArgs)
{
    if(iArgs != 1)
        return Plugin_Handled;
    
	char szArgTarget[MAX_NAME_LENGTH];
    GetCmdArg(1, szArgTarget, sizeof(szArgTarget));
    
   	char szTargetName[MAX_NAME_LENGTH];
    int iTargetList[MAXPLAYERS], iTargetCount;
    bool tn_is_ml;
    
    iTargetCount = ProcessTargetString(szArgTarget, iClient, iTargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED,szTargetName, sizeof(szTargetName), tn_is_ml);
    
    if(iTargetCount >= 1)
		for(new i=0; i<iTargetCount; i++)
			if(!IsPlayerAlive(iTargetList[i]))
		    {
		    	CS_RespawnPlayer(iTargetList[i]);
		    	
		    	CreateTimer(10.0, Kapat, iTargetList[i], TIMER_FLAG_NO_MAPCHANGE);
				SetEntProp(iTargetList[i], Prop_Data, "m_takedamage", 0, 1);	
		    }

    return Plugin_Handled;
}  

public Action Kapat(Handle Timer, any client)
{
	if(IsValidClient(client))
		if(IsPlayerAlive(client))
			SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);			
}






stock bool IsValidClient(client, bool nobots = true)
{ 
    if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
        return false; 

    return IsClientInGame(client); 
} 