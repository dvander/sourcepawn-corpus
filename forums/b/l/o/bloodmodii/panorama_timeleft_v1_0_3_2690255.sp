#include <sourcemod>
/////////
// ConVars
ConVar convar_ptenabled;
ConVar convar_servername;

public Plugin myinfo = 
{
	name = "Panorama - Timeleft",
	author = "Fastmancz",
	description = "Shows timeleft at the bottom of the screen",
	version = "1.0.1"
};

public void OnPluginStart()
{
	CreateTimer(1.0, Timeleft, _, TIMER_REPEAT);
	convar_ptenabled = CreateConVar("sm_pt_enable", "1", "Sets whether the plugin is enabled"); //declaring cvar
	convar_servername = CreateConVar("sm_pt_servername", "test", "Sets the server name"); //declaring cvar
	AutoExecConfig(true, "plugin.panorama_timeleft_v2");
	
}

public Action Timeleft(Handle timer)
{
	char sTime[60];
	int iTimeleft;
	char serverName[100];
  bool ptenabled = convar_ptenabled.BoolValue;
	char mapName[100];
	GetCurrentMap(mapName, sizeof(mapName));
	GetMapTimeLeft(iTimeleft);
	
	if(iTimeleft > 0 && ptenabled == 1)
	{
		FormatTime(sTime, sizeof(sTime), "%M:%S", iTimeleft);

		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i))
			{
				convar_servername.GetString(serverName, sizeof(serverName)); //How do I assigne serverName the cvar pt_servername?
				char message[60];
				Format(message, sizeof(message), "%s - Timeleft: %s - Map: %s", serverName, sTime, mapName);
				SetHudTextParams(-1.0, 1.00, 1.0, 4, 180, 255, 255, 0, 0.00, 0.00, 0.00);
				ShowHudText(i, -1, message);
			}
		}
	}
	return Plugin_Continue;
}