#include <sourcemod>

#pragma semicolon 1

new iAmmount;

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
	RegAdminCmd("sm_countdown", Command_CountDown, ADMFLAG_GENERIC, "Starts a countdown");
	RegAdminCmd("sm_stopcountdown", Command_StopCountDown, ADMFLAG_GENERIC, "Stops a countdown");
}

public Action:Command_CountDown(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage : sm_countdown <ammount>");
		return Plugin_Handled;
	}
	g_bTimerOn = true;
	new String:sArg1[32];
	GetCmdArg(1, sArg1, sizeof(sArg1));
	StringToIntEx(sArg1, iAmmount);
	CreateTimer(1.0, Timer_CountDown, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Handled;
}

public Action:Command_StopCountDown(client, args)
{
	if (args != 0)
	{
		ReplyToCommand(client, "[SM] Usage : sm_stopcountdown");
		return Plugin_Handled;
	}
	g_bTimerOn = false;
	PrintCenterTextAll("<font size=\"32\">Countdown <font color='#00ff00'>STOPPED</font>");
	return Plugin_Handled;
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
		g_bTimerOn = false;
		return Plugin_Stop;
	}
	if (iAmmount == 10)
	{
		PrintCenterTextAll("<font size=\"32\">Countdown : <font color='#00ff00'>10</font>");
		iAmmount--;
	}
	else if (iAmmount == 9)
	{
		PrintCenterTextAll("<font size=\"32\">Countdown : <font color='#B3FF00'>9</font></font>");
		iAmmount--;
	}
	else if (iAmmount == 8)
	{
		PrintCenterTextAll("<font size=\"32\">Countdown : <font color='#F7FF00'>8</font></font>");
		iAmmount--;
	}
	else if (iAmmount == 7)
	{
		PrintCenterTextAll("<font size=\"32\">Countdown : <font color='#F7FF00'>7</font></font>");
		iAmmount--;
	}
	else if (iAmmount == 6)
	{
		PrintCenterTextAll("<font size=\"32\">Countdown : <font color='#FFD500'>6</font></font>");
		iAmmount--;
	}
	else if (iAmmount == 5)
	{
		PrintCenterTextAll("<font size=\"32\">Countdown : <font color='#FFD500'>5</font></font>");
		iAmmount--;
	}
	else if (iAmmount == 4)
	{
		PrintCenterTextAll("<font size=\"32\">Countdown : <font color='#FF9500'>4</font></font>");
		iAmmount--;
	}
	else if (iAmmount == 3)
	{
		PrintCenterTextAll("<font size=\"32\">Countdown : <font color='#FF1A00'>3</font></font>");
		iAmmount--;
	}
	else if (iAmmount == 2)
	{
		PrintCenterTextAll("<font size=\"32\">Countdown : <font color='#FF1A00'>2</font></font>");
		iAmmount--;
	}
	else if (iAmmount == 1)
	{
		PrintCenterTextAll("<font size=\"32\">Countdown : <font color='#FF0000'>1</font></font>");
		iAmmount--;
	}
	else if (iAmmount == 0)
	{
		PrintCenterTextAll("<font size=\"32\"><font color='#00ff00'>Done!</font></font>");
		iAmmount--;
	}
	else
	{
		PrintCenterTextAll("<font size=\"32\">Countdown : <font color='#00ff00'>%i</font>", iAmmount);
		iAmmount--;
	}
	return Plugin_Continue;
}