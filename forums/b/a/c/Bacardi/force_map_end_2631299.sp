


public Plugin myinfo =
{
	name = "Force Map End",
	author = "Plagiarism by Bacardi (Created by many others)",
	description = "Force map end when mp_timelimit hits",
	version = "1.0",
	url = "http://www.sourcemod.net/"
};

#include <sdktools>
//#include <cstrike>

ConVar mp_timelimit;
int iCsMod;

public void OnPluginStart()
{
	mp_timelimit = FindConVar("mp_timelimit");
	if(mp_timelimit == null) SetFailState("This game not have ConVar mp_timelimit");

	CreateTimer(1.0, timer_repeat, INVALID_HANDLE, TIMER_REPEAT);

	char buffer[20];
	GetGameFolderName(buffer, sizeof(buffer));

	iCsMod = -1;
	if(StrEqual(buffer, "cstrike", false)) iCsMod = 0;
	if(StrEqual(buffer, "csgo", false)) iCsMod = 1;
}

public Action timer_repeat(Handle timer)
{
	static bool bAllowRoundEnd;

	if(mp_timelimit.IntValue <= 0) return Plugin_Continue;

	int timeleft;

	if(!GetMapTimeLeft(timeleft)) SetFailState("GetMapTimeLeft() is not supported in this game");
	//PrintToServer("timeleft %i", timeleft);

	// Reset
	if(!bAllowRoundEnd && timeleft > 0) bAllowRoundEnd = true;

	switch(timeleft)
	{
		case 1800: print_function(timeleft);
		case 1200: print_function(timeleft);
		case 600: print_function(timeleft);
		case 300: print_function(timeleft);
		case 120: print_function(timeleft);
		case 60: print_function(timeleft);
		case 30: print_function(timeleft);
		case 15: print_function(timeleft);
		case -1: print_function(timeleft);
		case -2: print_function(timeleft);
		case -3: print_function(timeleft);
	}

	if(bAllowRoundEnd && timeleft < -3)
	{
		bAllowRoundEnd = false;

		int entity = FindEntityByClassname(-1, "game_end");
		if(entity == -1 && (entity = CreateEntityByName("game_end")) == -1)
		{
			//CS_TerminateRound(0.5, CSRoundEnd_Draw, true);
			LogError("Unable to create entity \"game_end\"!");
		}
		else
		{
			AcceptEntityInput(entity, "EndGame");
		}
	}

	return Plugin_Continue;
}


print_function(int timeleft)
{
	char buffer[254];

	if(timeleft > 0)
	{
		Format(buffer, sizeof(buffer), "[SM] Time Remaining: %02i:%02i", (timeleft/60), timeleft % 60);
	}
	else if(timeleft < 0)
	{
		Format(buffer, sizeof(buffer), "[SM] %i...", 4 + timeleft);
	}

	switch(iCsMod)
	{
		case 0:
		{
			Format(buffer, sizeof(buffer), "\x07FF0000%s", buffer);
		}
		case 1:
		{
			Format(buffer, sizeof(buffer), " \x02%s", buffer);
		}
	}

	PrintToChatAll(buffer);
}




