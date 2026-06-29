#include <sourcemod>
#include <mapchooser>
#include <nextmap>

#pragma semicolon 1

public Plugin:myinfo =
{
	name = "Rock The Vote (Pausing capabilities)",
	author = "AlliedModders LLC & bhop_alex",
	description = "Provides RTV Map Voting with speedrun functionality",
	version = SOURCEMOD_VERSION,
	url = "http://www.sourcemod.net/"
};

ConVar g_Cvar_Needed;
ConVar g_Cvar_MinPlayers;
ConVar g_Cvar_InitialDelay;
ConVar g_Cvar_Interval;
ConVar g_Cvar_ChangeTime;
ConVar g_Cvar_RTVPostVoteAction;

new bool:g_CanRTV = false;		// True if RTV loaded maps and is active.
new bool:g_RTVAllowed = false;	// True if RTV is available to players. Used to delay rtv votes.
new g_Voters = 0;				// Total voters connected. Doesn't include fake clients.
new g_Votes = 0;				// Total number of "say rtv" votes
new g_VotesNeeded = 0;			// Necessary votes before map vote begins. (voters * percent_needed)
new bool:g_Voted[MAXPLAYERS+1] = {false, ...};

new bool:g_InChange = false;

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("rockthevote.phrases");
	
	g_Cvar_Needed = CreateConVar("sm_rtv_needed", "0.60", "Percentage of players needed to rockthevote (Def 60%)", 0, true, 0.05, true, 1.0);
	g_Cvar_MinPlayers = CreateConVar("sm_rtv_minplayers", "0", "Number of players required before RTV will be enabled.", 0, true, 0.0, true, float(MAXPLAYERS));
	g_Cvar_InitialDelay = CreateConVar("sm_rtv_initialdelay", "30.0", "Time (in seconds) before first RTV can be held", 0, true, 0.00);
	g_Cvar_Interval = CreateConVar("sm_rtv_interval", "240.0", "Time (in seconds) after a failed RTV before another can be held", 0, true, 0.00);
	g_Cvar_ChangeTime = CreateConVar("sm_rtv_changetime", "0", "When to change the map after a succesful RTV: 0 - Instant, 1 - RoundEnd, 2 - MapEnd", _, true, 0.0, true, 2.0);
	g_Cvar_RTVPostVoteAction = CreateConVar("sm_rtv_postvoteaction", "0", "What to do with RTV's after a mapvote has completed. 0 - Allow, success = instant change, 1 - Deny", _, true, 0.0, true, 1.0);
	
	RegConsoleCmd("sm_rtv", Command_RTV);
	RegAdminCmd("sm_speedrun", Command_Speedrun, ADMFLAG_GENERIC, "sm_speedrun"); 
	
	AutoExecConfig(true, "rtv");
}

public OnMapStart()
{
	g_Voters = 0;
	g_Votes = 0;
	g_VotesNeeded = 0;
	g_InChange = false;
	
	/* Handle late load */
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			OnClientConnected(i);	
		}	
	}
}

public OnMapEnd()
{
	g_CanRTV = false;	
	g_RTVAllowed = false;
}

public OnConfigsExecuted()
{	
	g_CanRTV = true;
	g_RTVAllowed = false;
	CreateTimer(g_Cvar_InitialDelay.FloatValue, Timer_DelayRTV, _, TIMER_FLAG_NO_MAPCHANGE);
	decl String:filename[200];
	BuildPath(Path_SM, filename, sizeof(filename), "plugins/rockthevote.smx");
	if(FileExists(filename))
	{
		decl String:newfilename[200];
		BuildPath(Path_SM, newfilename, sizeof(newfilename), "plugins/disabled/rockthevote.smx");
		ServerCommand("sm plugins unload rockthevote");
		if(FileExists(newfilename))
			DeleteFile(newfilename);
		RenameFile(newfilename, filename);
	}
}

public OnClientConnected(client)
{
	if(IsFakeClient(client))
		return;
	
	g_Voted[client] = false;

	g_Voters++;
	g_VotesNeeded = RoundToFloor(float(g_Voters) * g_Cvar_Needed.FloatValue);
	
	return;
}

public OnClientDisconnect(client)
{
	if(IsFakeClient(client))
		return;
	
	if(g_Voted[client])
	{
		g_Votes--;
	}
	
	g_Voters--;
	
	g_VotesNeeded = RoundToFloor(float(g_Voters) * g_Cvar_Needed.FloatValue);
	
	if (!g_CanRTV)
	{
		return;	
	}
	
	if (g_Votes && 
		g_Voters && 
		g_Votes >= g_VotesNeeded && 
		g_RTVAllowed ) 
	{
		if (g_Cvar_RTVPostVoteAction.IntValue == 1 && HasEndOfMapVoteFinished())
		{
			return;
		}
		
		StartRTV();
	}	
}

public OnClientSayCommand_Post(client, const String:command[], const String:sArgs[])
{
	if (!g_CanRTV || !client)
	{
		return;
	}
	
	if (strcmp(sArgs, "rtv", false) == 0 || strcmp(sArgs, "rockthevote", false) == 0)
	{
		new ReplySource:old = SetCmdReplySource(SM_REPLY_TO_CHAT);
		
		AttemptRTV(client);
		
		SetCmdReplySource(old);
	}
}

public Action:Command_RTV(client, args)
{
	if (!g_CanRTV || !client)
	{
		return Plugin_Handled;
	}
	
	AttemptRTV(client);
	
	return Plugin_Handled;
}

AttemptRTV(client)
{
	if (!g_RTVAllowed  || (g_Cvar_RTVPostVoteAction.IntValue == 1 && HasEndOfMapVoteFinished()))
	{
		ReplyToCommand(client, "[SM] %t", "RTV Not Allowed");
		return;
	}
		
	if (!CanMapChooserStartVote())
	{
		ReplyToCommand(client, "[SM] %t", "RTV Started");
		return;
	}
	
	if (GetClientCount(true) < g_Cvar_MinPlayers.IntValue)
	{
		ReplyToCommand(client, "[SM] %t", "Minimal Players Not Met");
		return;			
	}
	
	if (g_Voted[client])
	{
		ReplyToCommand(client, "[SM] %t", "Already Voted", g_Votes, g_VotesNeeded);
		return;
	}	
	
	new String:name[64];
	GetClientName(client, name, sizeof(name));
	
	g_Votes++;
	g_Voted[client] = true;
	
	PrintToChatAll("[SM] %t", "RTV Requested", name, g_Votes, g_VotesNeeded);
	
	if (g_Votes >= g_VotesNeeded)
	{
		StartRTV();
	}	
}

public Action:Timer_DelayRTV(Handle:timer)
{
	g_RTVAllowed = true;
}

StartRTV()
{
	if (g_InChange)
	{
		return;	
	}
	
	if (EndOfMapVoteEnabled() && HasEndOfMapVoteFinished())
	{
		/* Change right now then */
		new String:map[65];
		if (GetNextMap(map, sizeof(map)))
		{
			PrintToChatAll("[SM] %t", "Changing Maps", map);
			CreateTimer(5.0, Timer_ChangeMap, _, TIMER_FLAG_NO_MAPCHANGE);
			g_InChange = true;
			
			ResetRTV();
			
			g_RTVAllowed = false;
		}
		return;	
	}
	
	if (CanMapChooserStartVote())
	{
		new MapChange:when = MapChange:g_Cvar_ChangeTime.IntValue;
		InitiateMapChooserVote(when);
		
		ResetRTV();
		
		g_RTVAllowed = false;
		CreateTimer(g_Cvar_Interval.FloatValue, Timer_DelayRTV, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Command_Speedrun(client, args)
{
	if (g_RTVAllowed == true)
	{
		PrintToChatAll("[SM] %t", "Speedrun Enabled");
		g_RTVAllowed = false;
	}
	
	else if (g_RTVAllowed == false)
	{
		PrintToChatAll("[SM] %t", "Speedrun Disabled");
		g_RTVAllowed = true;
	}
	return Plugin_Handled;
}
ResetRTV()
{
	g_Votes = 0;
			
	for (new i=1; i<=MAXPLAYERS; i++)
	{
		g_Voted[i] = false;
	}
}

public Action:Timer_ChangeMap(Handle:hTimer)
{
	g_InChange = false;
	
	LogMessage("RTV changing map manually");
	
	new String:map[65];
	if (GetNextMap(map, sizeof(map)))
	{	
		ForceChangeLevel(map, "RTV after mapvote");
	}
	
	return Plugin_Stop;
}
