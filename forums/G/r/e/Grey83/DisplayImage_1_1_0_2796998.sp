#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name		= "DisplayImage",
	author		= "kurumi",
	description = "Allow admins to display images.",
	version		= "1.1.0 (rewritten by Grey83)",
	url			= "https://github.com/tokKurumi"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() != Engine_CSGO)
	{
		FormatEx(error, err_max, "Plugin for CS:GO only!");
		return APLRes_Failure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	RegAdminCmd("sm_image", Cmd_DisplayImage, ADMFLAG_GENERIC, "Display image to players by URL.");
	RegAdminCmd("sm_clearimage", Cmd_AdminClearImage, ADMFLAG_GENERIC, "Remove image from showing to players.");
	RegConsoleCmd("sm_climg", Cmd_UserClearImage, "Remove current image.");
}

public Action Cmd_DisplayImage(int client, int args)
{
	if(args < 2)
	{
		PrintToConsole(client, "Usage: sm_image <duration> \"<URL>\"");
		return Plugin_Handled;
	}

	char buffer[PLATFORM_MAX_PATH];
	GetCmdArg(2, buffer, sizeof(buffer));
	StripQuotes(buffer);
	if(TrimString(buffer) < 5)
	{
		PrintToConsole(client, "URL \"%s\" is too short", buffer);
		return Plugin_Handled;
	}

	Format(buffer, sizeof(buffer), "<img width=\"500\" height=\"600\" src=\"https://%s\">", buffer);
	SendWinPanel(buffer);

	GetCmdArg(1, buffer, sizeof(buffer));
	float time = StringToFloat(buffer);
	if(time < 0.0) time *= -1;
	CreateTimer(time, Timer_ClearImage);

	return Plugin_Handled;
}

public Action Cmd_AdminClearImage(int client, int args)
{
	CreateTimer(0.1, Timer_ClearImage);
	return Plugin_Handled;
}

public Action Timer_ClearImage(Handle timer)
{
	SendWinPanel();
	return Plugin_Stop;
}

public Action Cmd_UserClearImage(int client, int args)
{
	SendWinPanel();
	return Plugin_Handled;
}

stock void SendWinPanel(const char[] text = "")
{
	Event event = CreateEvent("cs_win_panel_round");
	if(!event) return;

	event.SetString("funfact_token", text);
	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i)) event.FireToClient(i);
	event.Cancel();
}