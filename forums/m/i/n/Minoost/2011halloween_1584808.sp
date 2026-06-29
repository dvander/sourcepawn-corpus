#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>

public Plugin:myinfo =
{
	name = "Dive Into A Good Book",
	author = "Mino",
	description = "Teleports that makes easier to earn achievement Dive into a Good Book",
	version = "1.2",
	url = "http://minoost.tk/"
};

public OnPluginStart()
{
	decl String:szGameName[32];
	GetGameFolderName(szGameName, sizeof(szGameName));
	if (strcmp(szGameName, "tf", false) != 0)
		SetFailState("SERVER IS NOT RUNNING TF2");
	
	RegConsoleCmd("sm_halloween",Command_go2011);
	RegConsoleCmd("sm_book",Command_go2011);
}

public Action:Command_go2011(client, args)
{
	if (!IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Continue;
	
	// I just decompiled koth_viaduct_event for this so, i guess it works for other maps.
	AcceptEntityInput(client, "TriggerLootIslandAchievement2");
	AcceptEntityInput(client, "TriggerLootIslandAchievement");
	
	// May be later used for eyeball boss?
	/*
	new Handle:hEventEye = INVALID_HANDLE;
	hEventEye = CreateEvent("eyeball_boss_killer", true);
	if (hEventEye == INVALID_HANDLE)
	{
		LogError("Event create failed");
		return Plugin_Handled;
	}
	SetEventInt(hEventEye, "level", 1);
	SetEventInt(hEventEye, "player_entindex", client);
	FireEvent(hEventEye);*/
	return Plugin_Handled;
}

/* I'm not sure below code for force holiday that make achievable Dive into a good book */
public Action:TF2_OnIsHolidayActive(TFHoliday:holiday, &bool:result)
{
	if (holiday == TFHoliday_Halloween || holiday == TFHoliday_FullMoon || holiday == TFHoliday_HalloweenOrFullMoon)	
	{
		result = true;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}