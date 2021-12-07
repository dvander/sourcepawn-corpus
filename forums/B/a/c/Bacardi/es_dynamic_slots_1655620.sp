new Handle:sv_visiblemaxplayers = INVALID_HANDLE;

new Handle:cvars[5] = { INVALID_HANDLE , ...};

public Plugin:myinfo = 
{
	name = "DYNAMIC SLOTS by ShoTaXx",
	description = "This script set the viewable server slots depending on playercount.",
	version = "5.1",
	url = "http://forums.alliedmods.net/showthread.php?t=178899"
}

public OnPluginStart()
{
	if((sv_visiblemaxplayers = FindConVar("sv_visiblemaxplayers")) == INVALID_HANDLE)
	{
		SetFailState("sv_visiblemaxplayers not exist");
	}

	cvars[0] = CreateConVar("dyn_start", "12", "Set the visible Slots at the Beginning", FCVAR_NONE, true, 1.0);
	cvars[1] = CreateConVar("dyn_min", "8", "Set the minimum of slots!", FCVAR_NONE, true, 1.0);
	cvars[2] = CreateConVar("dyn_max", "64", "Set the maximum of slots\nCan't set higher as your real slots!", FCVAR_NONE, true, 1.0);
	cvars[3] = CreateConVar("dyn_div", "3", "Set the divergence of the playercount", FCVAR_NONE, true, 0.0);
	cvars[4] = CreateConVar("dyn_info", "1", "Send infos of current slots on round end", FCVAR_NONE, true, 0.0, true, 1.0);

	HookEvent("player_connect", player_connect, EventHookMode_PostNoCopy);
	HookEvent("player_disconnect", player_connect, EventHookMode_PostNoCopy);
	HookEvents( );

	SetConVarInt(sv_visiblemaxplayers, GetConVarInt(cvars[0])); // Set the visible Slots at the Beginning
	PrintToChatAll("\x01[\x04Dynamic Slots\x01]\x03 Hello World!");
}

HookEvents( )
{
	decl String:folder[64];
	GetGameFolderName(folder, sizeof(folder));

	if (strcmp(folder, "tf") == 0)
	{
		HookEvent("teamplay_win_panel", round_end, EventHookMode_PostNoCopy);
		HookEvent("teamplay_restart_round", round_end, EventHookMode_PostNoCopy);
		HookEvent("arena_win_panel", round_end, EventHookMode_PostNoCopy);
	}
	else if (strcmp(folder, "nucleardawn") == 0)
	{
		HookEvent("round_win", round_end, EventHookMode_PostNoCopy);
	}
	else
	{
		HookEvent("round_end", round_end, EventHookMode_PostNoCopy);
	}	
}

public OnPluginEnd()
{
	PrintToChatAll("\x01[\x04Dynamic Slots\x01]\x03 Goodbye World!");
}

public player_connect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new count = GetClientCount(false) + GetConVarInt(cvars[3]);

	new temp; // Temporary variable for less using GetConVarInt() function...

	if(count <= (temp = GetConVarInt(cvars[1])))
	{
		SetConVarInt(sv_visiblemaxplayers, temp); // Set the minimum of slots!
	}
	else if(count >= (temp = GetConVarInt(cvars[2])))
	{
		SetConVarInt(sv_visiblemaxplayers, temp); // Set the maximum of slots
	}
	else
	{
		SetConVarInt(sv_visiblemaxplayers, count); // Set the divergence of the playercount
	}
}

public round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarBool(cvars[4]))
	{
		new count = GetClientCount(false);
		PrintToChatAll("\x01[\x04Dynamic Slots\x01]\x03 Current players: %i/%i server slots depends on players!", count, count + GetConVarInt(cvars[3]));
	}
}