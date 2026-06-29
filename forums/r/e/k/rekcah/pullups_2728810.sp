#pragma semicolon 1;

#include <sdktools>
#include <sourcemod>

new Float:spam[MAXPLAYERS+1];
new bool:onoff[MAXPLAYERS+1];
new bool:causedbysi[MAXPLAYERS+1];

public OnPluginStart()
{
	HookEvent("player_ledge_grab", player_ledge_grab);
	HookEvent("tongue_release", grab_end);
	HookEvent("jockey_ride",grab_start);
	HookEvent("tongue_grab",grab_start);
	
	HookEvent("jockey_ride_end", grab_end);
	HookEvent("player_bot_replace",player_bot_replace );
	
}
public Action:grab_start(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "player"));
	causedbysi[client] = true;
}
public Action:player_bot_replace(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "player"));
	if(IsHanging(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		PrintToChatAll("player took over bot, bot was hanging, starting pullup logic");
		CreateTimer(0.1, pullup, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:grab_end(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "victim"));
	causedbysi[client] = true;
	CreateTimer(0.2, reset, client, TIMER_FLAG_NO_MAPCHANGE);	
}

public Action:reset(Handle:hTimer, any:client)
{
	causedbysi[client] = false;
}

public Action:player_ledge_grab(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	//PrintHintText(client,"SPAM crtl TO DO A PULL UP!!!!");
	spam[client] = 0.0;
	if(!causedbysi[client])
	{
		if(IsFakeClient(client))
		{
			PrintToChatAll("\x04%N\x01 will do a pull up in \x04 15 \x01 seconds",client);		
			CreateTimer(15.0, botpullup, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			CreateTimer(0.1, pullup, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(2.0, pullupmessage, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	else
	{
		if(IsFakeClient(client))
		{
			PrintToChatAll("\x04%N\x01 will do a pull up in \x04 30 \x01 seconds",client);		
			CreateTimer(30.0, botpullup, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			PrintHintText(client,"struggling made you tired, you'll recover enough to pull yourself up soon");
			CreateTimer(30.0, Delayedpullup, client);
		}
	}
}


public OnClientDisconnect_Post(client)
{
	if(IsHanging(client))
	{
		onoff[client] = false;
		spam[client] = 0.0;
		PrintToChat(client,"\x04%N\x01 will do a pull up in \x04 15 \x01 seconds",client);		
		CreateTimer(15.0, botpullup, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}
public Action:botpullup(Handle:hTimer, any:client)
{
	if(!IsHanging(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
	{
		return Plugin_Stop;
	}
	CheatCommand(client, "give", "health", "");
	
	return Plugin_Stop;
}
public Action:Delayedpullup(Handle:hTimer, any:client)
{
	CreateTimer(0.1, pullup, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.5, pullupmessage, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}
public Action:pullupmessage(Handle:hTimer, any:client)
{
		if(!IsHanging(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
	{
		return Plugin_Stop;
	}
	PrintHintText(client,"to do a pull up, spam crtl %f / 100 ",spam[client]);
}

public Action:pullup(Handle:hTimer, any:client)
{
	if(!IsHanging(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
	{
		return Plugin_Stop;
	}

	new btns = GetClientButtons(client);
	
	if (btns & IN_DUCK)
	{
		//button down
		onoff[client] = true;
	}
	
	if (!(btns & IN_DUCK) && onoff[client])
	{
		// buton released
		onoff[client] = false;
		spam[client] += 3.0;
	}
	
	spam[client] -= 0.2;
	if (spam[client] < 0.0)
	{
		spam[client] = 0.0;
	}	
	
	if (IsHanging(client) && spam[client] > 100.0)
	{
		CheatCommand(client, "give", "health", "");
		return Plugin_Stop;
	}
	return Plugin_Continue;
	
}

bool:IsHanging(client)
{
 	if (GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1))return true;
	return false;
}

stock CheatCommand(client, String:command[], String:parameter1[], String:parameter2[])
{
	new userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s %s", command, parameter1, parameter2);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userflags);
}



