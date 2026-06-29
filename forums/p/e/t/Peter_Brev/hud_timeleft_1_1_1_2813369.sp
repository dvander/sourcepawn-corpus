#pragma semicolon 1
#pragma newdecls required

static const char
	PL_NAME[]		 = "Timeleft HUD",
	PL_AUTHOR[]		 = "Peter Brev",
	PL_DESCRIPTION[] = "Provides timeleft on the HUD",
	PL_VERSION[]	 = "1.1.1 (rewritten by Grey83)";

Handle hHUD;

public Plugin myinfo =
{
	name		= PL_NAME,
	author		= PL_AUTHOR,
	description = PL_DESCRIPTION,
	version		= PL_VERSION
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() != Engine_HL2DM)
	{
		FormatEx(error, err_max, "[HL2MP] This plugin is intended for Half-Life 2: Deathmatch only.");
		return APLRes_Failure;
	}

	return APLRes_Success;
}

public void OnMapStart()
{
	CreateTimer(1.0, Timer_Countdown, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Countdown(Handle timer, any data)
{
	static int time;
	GetMapTimeLeft(time);
	if(time < 1)
		return Plugin_Continue;

	static char left[32];
	if (time > 3599)
		FormatEx(left, sizeof(left), "%ih %02im", time / 3600, (time / 60) % 60);
	else if (time > 59)
		FormatEx(left, sizeof(left), "%i%c%02i", time / 60, time % 2 ? '.' : ':', time % 60);
	else FormatEx(left, sizeof(left), "%02i", time);

	if(!hHUD) hHUD = CreateHudSynchronizer();
	SetHudTextParams(-1.0, 0.01, 1.10, 255, 220, 0, 255, 0, 0.0, 0.0, 0.0);
	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i)) ShowSyncHudText(i, hHUD, left);

	return Plugin_Continue;
}