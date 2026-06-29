#include <sourcemod>

public Plugin myinfo =
{
	name = "HUD Test",
	author = "Vaggelis",
	description = "",
	version = "1.0",
	url = ""
}
 
public void OnPluginStart()
{
	RegConsoleCmd("sm_hudtest", CmdHUD);
}

public Action CmdHUD(int client, int args)
{
	char arg1[32], arg2[32];
	float x, y;
	
	if(args < 8)
	{
		return Plugin_Handled;
	}
	
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	x = StringToFloat(arg1);
	y = StringToFloat(arg2);
	
	SetHudTextParams(x, y, 4.0, 255, 0, 0, 255, 0, 0.0, 0.0, 0.0);
	ShowHudText(client, 1, "This is a test MESSAGE!");
	
	return Plugin_Handled;
}