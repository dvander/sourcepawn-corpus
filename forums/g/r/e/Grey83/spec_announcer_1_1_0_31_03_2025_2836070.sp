#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name		= "[ANY] Spectators Announcer",
	author		= "101",
	description	= "Notifies players when a spectator join/left their channels",
	version		= "1.1.0_31.03.2025",
	url			= "https://forums.alliedmods.net/showthread.php?t=350867"
}

public void OnMapStart()
{
	CreateTimer(1.0, Timer_Check, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Check(Handle timer)
{
	for(int i, target; ++i <= MaxClients;) if(IsClientInGame(i) && !IsFakeClient(i))
	{
		target = IsClientObserver(i) ? GetEntPropEnt(i, Prop_Send, "m_hObserverTarget") : 0;
		UpdateInfo(i, target);
	}

	return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
	if(!IsFakeClient(client)) UpdateInfo(client);
}

// https://wiki.alliedmods.net/Scripting_FAQ_(SourceMod)#How_do_I_add_color_to_my_messages.3F
void UpdateInfo(int client, int target = 0)
{
	static int old_target[MAXPLAYERS+1];
	if(target > 0 && IsPlayerAlive(target) && !IsFakeClient(target))
		PrintToChat(target, "\x03%N is spectating you", client);

	if(old_target[client] > 0 && IsClientInGame(old_target[client]))
		PrintToChat(old_target[client], "\x05%N is no longer spectating", client);

	old_target[client] = target;
}