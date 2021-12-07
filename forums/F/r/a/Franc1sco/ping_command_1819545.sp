#include <sourcemod>
#include <sdktools>

new g_iMaxClients		= 0;
new Float:g_fTimer		= 0.0;
new String:g_szPlayerManager[50] = "";
new g_iPlayerManager	= -1;
new g_iPing				= -1;

new usarping[MAXPLAYERS+1];

public OnPluginStart()
{
	
	g_iPing	= FindSendPropOffs("CPlayerResource", "m_iPing");

	new String:szBuffer[100];
	GetGameFolderName(szBuffer, sizeof(szBuffer));

	if(StrEqual("cstrike", szBuffer))
		strcopy(g_szPlayerManager, sizeof(g_szPlayerManager), "cs_player_manager");
	else if(StrEqual("dod", szBuffer))
		strcopy(g_szPlayerManager, sizeof(g_szPlayerManager), "dod_player_manager");
	else
		strcopy(g_szPlayerManager, sizeof(g_szPlayerManager), "player_manager");

   	RegAdminCmd("sm_fakeping", FijarPing, ADMFLAG_ROOT);
}

public Action:FijarPing(client, args)
{
    if(args < 2) // Not enough parameters
    {
        ReplyToCommand(client, "[SM] Use: sm_fakeping <#userid|name> [ping]");
        return Plugin_Handled;
    }

    decl String:arg2[10];
    GetCmdArg(2, arg2, sizeof(arg2));

    new amount = StringToInt(arg2);

    decl String:strTarget[32]; GetCmdArg(1, strTarget, sizeof(strTarget)); 

    // Process the targets 
    decl String:strTargetName[MAX_TARGET_LENGTH]; 
    decl TargetList[MAXPLAYERS], TargetCount; 
    decl bool:TargetTranslate; 

    if ((TargetCount = ProcessTargetString(strTarget, client, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED, 
                                           strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0) 
    { 
          PrintToChat(client, "target not found");
          return Plugin_Handled; 
    } 

    // Apply to all targets 
    for (new i = 0; i < TargetCount; i++) 
    { 
        new iClient = TargetList[i]; 
        if (IsClientInGame(iClient)) 
        { 
              usarping[iClient] = amount;
              PrintToChat(client, "Set ping in %i for player %N", amount, iClient);
        } 
    } 


    return Plugin_Handled;
}

public OnClientPostAdminCheck(client)
{
    usarping[client] = -1;
}

public OnMapStart()
{
	g_iMaxClients		= GetMaxClients();
	g_iPlayerManager	= FindEntityByClassname(g_iMaxClients + 1, g_szPlayerManager);
	g_fTimer			= 0.0;
}

public OnGameFrame()
{
	if(g_fTimer < GetGameTime() - 3)
	{
		g_fTimer = GetGameTime();
		
		if(g_iPlayerManager == -1 || g_iPing == -1)
			return;

		for(new i = 1; i <= g_iMaxClients; i++)
		{
			if(!IsValidEdict(i) || !IsClientInGame(i) || usarping[i] == -1)
				continue;

			SetEntData(g_iPlayerManager, g_iPing + (i * 4), usarping[i]);
		}
	}
}
