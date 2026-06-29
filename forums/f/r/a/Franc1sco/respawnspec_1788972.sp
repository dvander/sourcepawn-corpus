#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#include <cstrike>


public Plugin:myinfo =
{
	name = "SM Respawn Spectators",
	author = "Franc1sco steam: franug",
	description = "For respawn spectators",
	version = "1.0",
	url = "http://servers-cfg.foroactivo.com/"
};

public OnPluginStart()
{
	CreateConVar("sm_RespawnSpectators", "1.0", "plugin info", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	RegAdminCmd("sm_respawnspec", Rspec, ADMFLAG_GENERIC);

    	LoadTranslations("common.phrases");
}


public Action:Rspec(client, args)
{
    if(args < 1)
    {
        ReplyToCommand(client, "[SM] Use: sm_respawnspec <#userid|name>");
        return Plugin_Handled;
    }


    decl String:strTarget[32]; GetCmdArg(1, strTarget, sizeof(strTarget)); 

    // Process the targets 
    decl String:strTargetName[MAX_TARGET_LENGTH]; 
    decl TargetList[MAXPLAYERS], TargetCount; 
    decl bool:TargetTranslate; 

    if ((TargetCount = ProcessTargetString(strTarget, client, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED, 
                                           strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0) 
    { 
          ReplyToTargetError(client, TargetCount); 
          return Plugin_Handled; 
    } 

    // Apply to all targets 
    for (new i = 0; i < TargetCount; i++) 
    { 
        new iClient = TargetList[i]; 
        if (GetClientTeam(iClient) != 2 && GetClientTeam(iClient) != 3) 
        { 
	      new ramdom = GetRandomInt(2,3);
              ChangeClientTeam(iClient,ramdom);
	      CS_RespawnPlayer(iClient);
              PrintToChatAllEx(iClient,"\x01[SM]\x04%N \x01respawned \x03%N", client, iClient);
        } 
    } 

    return Plugin_Handled;
}

public PrintToChatAllEx(from,const String:format[], any:...)
{
	decl String:message[512];
	VFormat(message,sizeof(message),format,3);
	

	new Handle:hBf = StartMessageAll("SayText2");
	if (hBf != INVALID_HANDLE)
	{
		BfWriteByte(hBf, from);
		BfWriteByte(hBf, true);
		BfWriteString(hBf, message);
	
		EndMessage();
	}
}