#pragma semicolon 1

public void OnPluginStart()
{
	SetHudTextParams(-1.0, -0.15, 0.5, 31, 255, 127, 191);
}

public void OnMapStart()
{
	CreateTimer(0.5, Timer_Print, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Print(Handle timer)
{
	static char buffer[64];
	static int i, HP, j, num;
	for (i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i))
	{
		HP = GetClientHealth(i);
		buffer[0] = 0;
		for(j = 0, num = RoundToZero(HP * 0.1); j < num; j++) Format(buffer, sizeof(buffer), "%s☐", buffer);
		ShowHudText(i, 1, "%d %s", HP, buffer);
	}
}