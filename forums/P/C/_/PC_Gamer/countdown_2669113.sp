#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

int iAmount;
bool g_bTimerOn = false;

#define PLUGIN_VERSION "1.1"

public Plugin myinfo =
{
	name = "TF2 Announcer Countdown plugin",
	author = "Headline code modified by PC Gamer",
	description = "TF2 Announcer counts down from defined number",
	version = PLUGIN_VERSION
};

public void OnPluginStart()
{
	RegAdminCmd("sm_countdown", Command_CountDown, ADMFLAG_GENERIC, "Starts a countdown");
	RegAdminCmd("sm_stopcountdown", Command_StopCountDown, ADMFLAG_GENERIC, "Stops a countdown");
}

public void OnMapStart()
{
	PrecacheSound("/vo/announcer_ends_1sec.mp3", true);
	PrecacheSound("/vo/announcer_ends_2sec.mp3", true);
	PrecacheSound("/vo/announcer_ends_3sec.mp3", true);
	PrecacheSound("/vo/announcer_ends_4sec.mp3", true);
	PrecacheSound("/vo/announcer_ends_5sec.mp3", true);
	PrecacheSound("/player/taunt_bell.wav", true);	
	PrecacheSound("vo/announcer_attention.mp3", true);	
}

public Action Command_CountDown(int client, int args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage : sm_countdown <amount>");
		return Plugin_Handled;
	}
	EmitSoundToAll("vo/announcer_attention.mp3");	
	g_bTimerOn = true;
	char sArg1[32];
	GetCmdArg(1, sArg1, sizeof(sArg1));
	StringToIntEx(sArg1, iAmount);
	CreateTimer(1.0, Timer_CountDown, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Handled;
}

public Action Command_StopCountDown(int client, int args)
{
	if (args != 0)
	{
		ReplyToCommand(client, "[SM] Usage : sm_stopcountdown");
		return Plugin_Handled;
	}
	g_bTimerOn = false;
	PrintCenterTextAll("Countdown STOPPED");
	return Plugin_Handled;
}

public Action Timer_CountDown(Handle timer, any data)
{
	if (iAmount == -1)
	{
		g_bTimerOn = false;
		return Plugin_Stop;
	}
	if (!g_bTimerOn)
	{
		g_bTimerOn = false;
		return Plugin_Stop;
	}
	if (iAmount == 10)
	{
		PrintCenterTextAll("Countdown: 10");
		iAmount--;
	}
	else if (iAmount == 9)
	{
		PrintCenterTextAll("Countdown: 9");
		iAmount--;
	}
	else if (iAmount == 8)
	{
		PrintCenterTextAll("Countdown: 8");
		iAmount--;
	}
	else if (iAmount == 7)
	{
		PrintCenterTextAll("Countdown: 7");
		iAmount--;
	}
	else if (iAmount == 6)
	{
		PrintCenterTextAll("Countdown: 6");
		iAmount--;
	}
	else if (iAmount == 5)
	{
		PrintCenterTextAll("Countdown: 5");
		iAmount--;
		EmitSoundToAll("/vo/announcer_ends_5sec.mp3");		
	}
	else if (iAmount == 4)
	{
		PrintCenterTextAll("Countdown: 4");
		iAmount--;
		EmitSoundToAll("/vo/announcer_ends_4sec.mp3");		
	}
	else if (iAmount == 3)
	{
		PrintCenterTextAll("Countdown: 3");
		iAmount--;
		EmitSoundToAll("/vo/announcer_ends_3sec.mp3");		
	}
	else if (iAmount == 2)
	{
		PrintCenterTextAll("Countdown: 2");
		iAmount--;
		EmitSoundToAll("/vo/announcer_ends_2sec.mp3");		
	}
	else if (iAmount == 1)
	{
		PrintCenterTextAll("Countdown: 1");
		iAmount--;
		EmitSoundToAll("/vo/announcer_ends_1sec.mp3");
	}
	else if (iAmount == 0)
	{
		PrintCenterTextAll("Done!");
		iAmount--;
		EmitSoundToAll("/player/taunt_bell.wav");
		PrintToServer("Countdown Complete");			
	}
	else
	{
		PrintCenterTextAll("Countdown: %i", iAmount);
		iAmount--;
	}
	return Plugin_Continue;
}