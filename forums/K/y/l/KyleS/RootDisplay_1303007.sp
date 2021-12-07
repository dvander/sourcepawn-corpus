#pragma semicolon 1
/* Borrowed a couple lines from GoD_Tony's Plugin http://forums.alliedmods.net/showthread.php?t=135353 and the posted Snippet http://forums.alliedmods.net/showthread.php?t=133287 */
/* I also took a look at the SourceMod timeleft implementation and borrowed a bit of code */

#include <sourcemod>
#define PLUGIN_VERSION "2.1"

new Handle:HudHintTimer[MAXPLAYERS+1], Handle:Enabled, Handle:Show, Handle:SlowCache, Handle:FastCache;
new String:Clock[64], String:Date[32], String:ServerInformation[512], String:NextMap[32], String:CurrMap[32], String:TimeLeftMapFinal[13], String:UpTime[64];
new ClientConn, ClientGame, ClientLimbo, TimeCache, TimeLeft, MapTimeLeftMin, MapTimeLeftSec, ServerUpTime;
new bool:bTimeLeftLogic;

public Plugin:myinfo =
{
	name = "ServerInformation for Root",
	author = "Kyle Sanderson",
	description = "Provides Admins with the Root flag basic Server Information via KeyHintText.",
	version = PLUGIN_VERSION,
	url = "http://RawhMadeMeCry.webuda.com"
};

public OnPluginStart()
{
	CreateConVar("sm_rootdisplay_version", PLUGIN_VERSION, "Creates a HudHint Message for Root", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	Enabled = CreateConVar("sm_rootdisplay_enabled", "1", "Am I Enabled? or Disabled? D:", FCVAR_PLUGIN);
	Show = CreateConVar("sm_rootdisplay_show", "1", "Should I automatically appear on your screen? Or should you manually trigger me? :<", FCVAR_PLUGIN);
	HookConVarChange(Enabled, Enabled_Changed);
	RegAdminCmd("sm_rdisplay", Command_ToggleDisplay, ADMFLAG_ROOT, "Toggles the Display of the HudHint Message for Root.");
}

public OnConfigsExecuted()
{
	new bool:bCVarEnabled;
	bCVarEnabled = GetConVarBool(Enabled);
	
	switch(bCVarEnabled)
	{
		case 0:
		{
			PluginKill();
		}
		
		case 1:
		{
			PluginInit();
		}
	}
}

public PluginInit()
{
	bTimeLeftLogic = true;
	GetCurrentMap(CurrMap, sizeof(CurrMap));
	GetMapTimeLeft(TimeLeft);
	FastCache = CreateTimer(1.0, UpdateCacheFast, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	SlowCache = CreateTimer(5.0, UpdateCacheSlow, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	TimeCache = GetTime(); // http://www.youtube.com/watch?v=Rd6YR4RWO5A&fmt=22
	ServerUpTime = RoundToFloor(GetEngineTime());
}

public PluginKill()
{
	bTimeLeftLogic = false;
	FastCache = INVALID_HANDLE;
	SlowCache = INVALID_HANDLE;
}

public OnClientPostAdminCheck(client)
{
	new bool:bCVarEnabled, bool:bCVarShow;
	bCVarEnabled = GetConVarBool(Enabled);
	bCVarShow = GetConVarBool(Enabled);
	if (bCVarEnabled && bCVarShow)
	{
		if (CheckCommandAccess(client, "sm_rdisplay", ADMFLAG_ROOT, true))
		{
			HudHintTimer[client] = CreateTimer(1.0, Timer_UpdateHudHint, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public OnClientDisconnect(client)
{
	if (HudHintTimer[client] != INVALID_HANDLE)
	{
		KillTimer(HudHintTimer[client]);
		HudHintTimer[client] = INVALID_HANDLE;
	}
}

public Action:Timer_UpdateHudHint(Handle:timer, any:client)
{
	new Handle:hBuffer = StartMessageOne("KeyHintText", client); 
	BfWriteByte(hBuffer, 1); 
	BfWriteString(hBuffer, ServerInformation); 
	EndMessage();
	return Plugin_Handled;
}

public Action:UpdateCacheFast(Handle:timer)
{
	TimeCache++;
	ServerUpTime++;
	if (bTimeLeftLogic)
	{
		TimeLeft--;
		TimeLeftLogic();
	}
	new Days = ServerUpTime / 60 / 60 / 24; // Borrowed from Mr.Exvel.
	new Hours = (ServerUpTime / 60 / 60) % 24;
	new Mins = (ServerUpTime / 60) % 60;
	
	FormatEx(UpTime, sizeof(UpTime), "%d Days %02d Hours %02d Minutes", Days, Hours, Mins);
	FormatTime(Clock, sizeof(Clock), "%I:%M:%S%p %Z", TimeCache);
	FormatEx(ServerInformation, sizeof(ServerInformation), "Kyle's Server Information\nTime: %s\nDate: %s\nCurrent Map: %s\nNext Map: %s\nTime until Map Change: %s\nPlayers (T/I/C): %i/%i/%i\nUpTime: %s", Clock, Date, CurrMap, NextMap, TimeLeftMapFinal, ClientConn, ClientGame, ClientLimbo, UpTime);
	return Plugin_Handled;
}

public Action:UpdateCacheSlow(Handle:timer)
{
	ClientConn = GetClientCount(false);
	ClientGame = GetClientCount(true);
	ClientLimbo = ClientConn - ClientGame;
	GetNextMap(NextMap, sizeof(NextMap));
	FormatTime(Date, sizeof(Date), "%A, %B %d, %Y", TimeCache);
	return Plugin_Handled;
}

public Action:Command_ToggleDisplay(client, args)
{
	new bool:bCVarEnabled;
	bCVarEnabled = GetConVarBool(Enabled);
	if (!bCVarEnabled)
	{
		PrintToChat(client, "\x04[RootDisplay]\x03 Sorry buddy, Server Information is \x04Disabled\x03 at the moment.");
		return Plugin_Handled;
	}
	
	if (HudHintTimer[client] != INVALID_HANDLE)
	{
		KillTimer(HudHintTimer[client]);
		HudHintTimer[client] = INVALID_HANDLE;
		PrintToChat(client, "\x04[RootDisplay]\x03 Server Information has been \x04Disabled\x03.");
		return Plugin_Handled;
	}

	HudHintTimer[client] = CreateTimer(1.0, Timer_UpdateHudHint, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	PrintToChat(client, "\x04[RootDisplay]\x03 Server Information has been \x04Enabled\x03, cheers.");
	return Plugin_Handled;
}

public Enabled_Changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new bool:bCVarEnabled;
	bCVarEnabled = GetConVarBool(Enabled);
	if(bCVarEnabled)
	{
		new bool:bCVarShow;
		bCVarShow = GetConVarBool(Show);
		PluginInit();
		
		if(bCVarShow)
		{
			for (new client = 1; client <= MaxClients; client++)
			{
				if (IsClientConnected(client) && IsClientInGame(client) && CheckCommandAccess(client, "sm_rdisplay", ADMFLAG_ROOT, true))
				{
					if (HudHintTimer[client] == INVALID_HANDLE)
					{
						PrintToChat(client, "\x04[RootDisplay]\x03 Server Information has been \x04Enabled\x03.");
						HudHintTimer[client] = CreateTimer(1.0, Timer_UpdateHudHint, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					}
				}
			}
		}
	}
	else
	{
		if(FastCache != INVALID_HANDLE)
		{
			KillTimer(FastCache);
		}
		
		if(SlowCache != INVALID_HANDLE)
		{
			KillTimer(SlowCache);
		}
		
		PluginKill();
		for (new client = 1; client <= MaxClients; client++)
		{
			if (IsClientConnected(client) && IsClientInGame(client))
			{
				if (HudHintTimer[client] != INVALID_HANDLE)
				{
					KillTimer(HudHintTimer[client]);
					HudHintTimer[client] = INVALID_HANDLE;
					PrintToChat(client, "\x04[RootDisplay]\x03 Sorry buddy, Server Information was literally just \x04Disabled\x03.");
				}
			}
		}
	}
}

public OnMapTimeLeftChanged()
{
	TimeLeft += 12;
	GetMapTimeLeft(TimeLeft);
	TimeLeftLogic();
}

public TimeLeftLogic()
{
	if (TimeLeft > 0) // Boom Otherwise D:!
	{
		MapTimeLeftMin = TimeLeft / 60;
		MapTimeLeftSec = TimeLeft % 60;
		FormatEx(TimeLeftMapFinal, sizeof(TimeLeftMapFinal), "%i:%02i", MapTimeLeftMin, MapTimeLeftSec);
		bTimeLeftLogic = true;
	}
	else
	{
		FormatEx(TimeLeftMapFinal, sizeof(TimeLeftMapFinal), "Last Round.");
		bTimeLeftLogic = false;
	}
}