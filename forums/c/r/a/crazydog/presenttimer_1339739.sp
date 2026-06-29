#include <sourcemod>
#include <wepannounce>

#define PLUGIN_VERSION "1.0.0"

new nextSpawn;

new bool:g_bPauseTimer = false;
new bool:g_bMapIsManor = false;

public Plugin:myinfo = 
{
	name = "[TF2] Custom Timer",
	author = "Fox",
	description = "custom timer",
	version = PLUGIN_VERSION,
	url = "http://www.rtdgaming.com"
}

public OnMapStart()
{
	g_bPauseTimer = false;
	
	decl String:sMapname[128];
	GetCurrentMap(sMapname, sizeof(sMapname));
	//LogAction(0, -1, "Current Map Detected as: %s", sMapname);
	if(strcmp(sMapname, "cp_manor_event") == 0)
	{
		g_bMapIsManor = true;
		CreateTimer(1.0, ShowTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		HookEvent("teamplay_setup_finished", Hook_SetupFinished, EventHookMode_Post);
		HookEvent("teamplay_round_start", Hook_PauseTimerEvents, EventHookMode_Post);
		HookEvent("teamplay_round_win", Hook_PauseTimerEvents, EventHookMode_Post);
	}
	else
	{
		g_bMapIsManor = false;
	}
}

public OnMapEnd()
{
	if(g_bMapIsManor)
	{
		UnhookEvent("teamplay_setup_finished", Hook_SetupFinished, EventHookMode_Post);
		UnhookEvent("teamplay_round_start", Hook_PauseTimerEvents, EventHookMode_Post);
		UnhookEvent("teamplay_round_win", Hook_PauseTimerEvents, EventHookMode_Post);
	}
}

public Action:ShowTimer(Handle:timer)
{
	new timeMin;
	new timeLeft;
	
	new String:timeSec[3];
	new String:message[32];
	
	timeLeft = nextSpawn - GetTime();
	
	timeMin = timeLeft / 60; //Minutes Left
	
	IntToString((timeLeft - (timeMin * 60)), timeSec, sizeof(timeSec)); //Seconds Left
	if(strlen(timeSec) == 1)
	{
		Format(timeSec, sizeof(timeSec), "0%s", timeSec);
	}
	
	if(timeMin <= 0 && StringToInt(timeSec) <= 0)
	return Plugin_Continue;
	
	if(GetClientCount(false) >= 10 && !g_bPauseTimer)
	{
		Format(message, sizeof(message), "Gift ETA: %d:%s", timeMin, timeSec);
	}
	else
	{
		Format(message, sizeof(message), "Gift ETA: PAUSED");
	}
	
	for (new i = 1; i <= MaxClients ; i++)
	{
		if(!IsClientInGame(i))
		{
			continue;
		}
		
		SetHudTextParams(0.43, 0.09, 2.0, 250, 250, 210, 255);
		ShowHudText(i, 3, message);
	}
	
	return Plugin_Continue;
}

public OnItemAddedToInventory(client, itemDefinitionIndex, itemLevel, itemQuality, inventoryPos, String:customName[], String:itemName[], bool:properName, String:typeName[], String:name[], globalIndex_low, globalIndex_high)
{
	if (inventoryPos == 0)
	{
		//PrintToChatAll("%N has found %s%s.", client, properName?"":"a ", name);
	} else if ((inventoryPos & 0xF0000000) == 0xC0000000) 
	{
		if((inventoryPos & 0xFFFF) == 1)
		{
			if(StrContains(itemName, "TF_Halloween_Mask_", false) != -1)
			{
				nextSpawn = GetTime() + 303;
				//PrintToChatAll("Debug: Halloween Mask picked up?");
			}
		}
	}
}

public Hook_PauseTimerEvents(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bPauseTimer = true;
}

public Hook_SetupFinished(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bPauseTimer = false;
}