#include <sourcemod>

#pragma semicolon 1

new iAmmount = 25;

new bool:g_bTimerOn = false;

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
    name = "Count down plugin",
    author = "Headline",
    description = "Counts down from defined number",
    version = PLUGIN_VERSION
};

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(1.0, Timer_CountDown, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action:Timer_CountDown(Handle:timer, any:data)
{
	if (iAmmount == -1)
	{
		g_bTimerOn = false;
		return Plugin_Stop;
	}
	if (!g_bTimerOn)
	{
		return Plugin_Stop;
	}
	if (iAmmount == 10)
	{
		PrintCenterTextAll("<font size=\"32\">Zombies : <font color='#00ff00'>10</font>");
		iAmmount--;
	}
	else if (iAmmount == 9)
	{
		PrintCenterTextAll("<font size=\"32\">Zombies : <font color='#B3FF00'>9</font></font>");
		iAmmount--;
	}
	else if (iAmmount == 8)
	{
		PrintCenterTextAll("<font size=\"32\">Zombies : <font color='#F7FF00'>8</font></font>");
		iAmmount--;
	}
	else if (iAmmount == 7)
	{
		PrintCenterTextAll("<font size=\"32\">Zombies : <font color='#F7FF00'>7</font></font>");
		iAmmount--;
	}
	else if (iAmmount == 6)
	{
		PrintCenterTextAll("<font size=\"32\">Zombies : <font color='#FFD500'>6</font></font>");
		iAmmount--;
	}
	else if (iAmmount == 5)
	{
		PrintCenterTextAll("<font size=\"32\">Zombies : <font color='#FFD500'>5</font></font>");
		iAmmount--;
	}
	else if (iAmmount == 4)
	{
		PrintCenterTextAll("<font size=\"32\">Zombies : <font color='#FF9500'>4</font></font>");
		iAmmount--;
	}
	else if (iAmmount == 3)
	{
		PrintCenterTextAll("<font size=\"32\">Zombies : <font color='#FF1A00'>3</font></font>");
		iAmmount--;
	}
	else if (iAmmount == 2)
	{
		PrintCenterTextAll("<font size=\"32\">Zombies : <font color='#FF1A00'>2</font></font>");
		iAmmount--;
	}
	else if (iAmmount == 1)
	{
		PrintCenterTextAll("<font size=\"32\">Zombies : <font color='#FF0000'>1</font></font>");
		iAmmount--;
	}
	else if (iAmmount == 0)
	{
		PrintCenterTextAll("<font size=\"32\"><font color='#FF0000'>GO!</font></font>");
		iAmmount--;
	}
	else
	{
		PrintCenterTextAll("<font size=\"32\">Zombies : <font color='#00ff00'>%i</font>", iAmmount);
		iAmmount--;
	}
	return Plugin_Continue;
}