public Plugin myinfo =
{
	name = "Panorama timeLeft",
	description = "Panorama timeLeft",
	author = "Phoenix",
	version = "1.0.0",
	url = "zizt.ru hlmod.ru"
};

bool g_bPanorama[MAXPLAYERS + 1];


public void ClientConVar(QueryCookie hCookie, int iClient, ConVarQueryResult hResult, const char[] sCvarName, const char[] sCvarValue)
{
   if(hResult == ConVarQuery_Okay) g_bPanorama[iClient] = true; // Использует
}

public void OnClientDisconnect(int iClient)
{
	g_bPanorama[iClient] = false;
}

public void OnClientPutInServer(int iClient) 
{
   QueryClientConVar(iClient, "@panorama_debug_overlay_opacity", ClientConVar);
}

public void OnMapStart() 
{
	CreateTimer(1.0, Timer_UPDATE, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_UPDATE(Handle timer)
{
	int timeleft;
	char sBuf[255];
	GetMapTimeLeft(timeleft);
	if(timeleft > 0) FormatEx(sBuf, sizeof sBuf, "Timeleft - %d:%02d", timeleft / 60, timeleft % 60);
	else sBuf = "Last Round";
	SetHudTextParams(-1.0, 0.99, 1.5, 0, 255, 255, 0);
	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if(g_bPanorama[iClient])
		{			
			ShowHudText(iClient, 4, sBuf);
		}
	}
	return Plugin_Continue; 
}