#include <sourcemod>
#include <tf2_stocks>

#define PLUGIN_VERSION		"1.0.1"

new Handle:g_hRoundThriller = INVALID_HANDLE;
new Handle:g_hDisplayTimer = INVALID_HANDLE;
new ClientDancing[MAXPLAYERS+1] = false;
new ClientDuration[MAXPLAYERS+1] = 0;
new bool:waiting = false; // Start false in case plugin re/loads during round.

public Plugin:myinfo = 
{
	name = "Thriller Dance",
	author = "SoulSharD",
	description = "Allows admins to force the Thriller Dance to players.",
	version = PLUGIN_VERSION,
	url = "tf2lottery.com"
};

public OnPluginStart()
{
	CreateConVar("sm_thrillerdance_version", PLUGIN_VERSION, "Thriller Dance: Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_CHEAT|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hRoundThriller = CreateConVar("sm_thrillerdance_humiliation", "0", "This will force the losing team to do the Thriller during humiliation.");
	g_hDisplayTimer = CreateConVar("sm_thrillerdance_displaytimer", "0", "Enable or disable the timer display at the bottom of the screen.");
	
	RegAdminCmd("sm_thriller", Command_Dance, ADMFLAG_SLAY);
	RegAdminCmd("sm_dance", Command_Dance, ADMFLAG_SLAY);
	
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("teamplay_round_win", Event_RoundWin); // Fires with stalemates too.
	
	LoadTranslations("common.phrases");
}

public OnClientDisconnect(client)
{
	ClientDancing[client] = false;
	ClientDuration[client] = 0;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(ClientDancing[client])
	{
		UndanceClient(client);
	}
	
	return Plugin_Continue;
}

public Action:Event_RoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(g_hRoundThriller) <= 0)
	{
		return Plugin_Continue;
	}
	
	new team = GetEventInt(event, "team");
	new duration = GetConVarInt(FindConVar("mp_bonusroundtime"));
	new cteam;
	
	for(new i = 1; i <= MaxClients; i++)
	{
		cteam = GetClientTeam(i);
		if(cteam != team)
		{
			DanceClient(i, duration-1);
		}
	}
	return Plugin_Continue;
}

public Action:Command_Dance(client, args)
{
	if(waiting)
	{
		ReplyToCommand(client, "[SM] Waiting for players.");
		return Plugin_Handled;
	}
	
	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_thriller <name|#userid> [duration/s]");
		return Plugin_Handled;
	}
	
	decl String:target[64];
	decl String:target_name[MAX_NAME_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;
	
	GetCmdArg(1, target, sizeof(target));
	
	if ((target_count = ProcessTargetString(
			target,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	decl String:arg2[5];
	decl duration;
	
	GetCmdArg(2, arg2, sizeof(arg2));
	duration = StringToInt(arg2);
	
	if(duration <= 0)
	{
		ReplyToCommand(client, "[SM] Stopped %s from dancing.", target_name);
	}
	else
	{
		ReplyToCommand(client, "[SM] Forced %s to dance for %i second(s).", target_name, duration);
	}
	
	for(new i = 0; i < target_count; i++)
	{	
		if(duration <= 0) // Stop dancing.
		{
			if(ClientDancing[target_list[i]])
			{
				UndanceClient(target_list[i]);
				LogAction(client, target_list[i], "[ThrillerDance] \"%L\" stopped \"%L\" from dancing.", client, target_list[i]);
			}
		}
		else if(duration >= 1) // Start Dancing | Refresh countdown
		{
			if(!ClientDancing[target_list[i]])
			{
				DanceClient(target_list[i], duration);
				LogAction(client, target_list[i], "[ThrillerDance] \"%L\" forced dancing on \"%L\" for %i second(s).", client, target_list[i], duration);
			}
			else
			{
				ClientDuration[target_list[i]] = duration;
			}
		}
	}
	return Plugin_Handled;
}

DanceClient(any:client, duration)
{	
	if(IsPlayerAlive(client) && IsClientInGame(client))
	{
		ClientDancing[client] = true;
		ClientDuration[client] = duration;
		
		TF2_AddCondition(client, TFCond:54, 99999.0);
		CreateTimer(1.0, DurationTimer, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

UndanceClient(any:client)
{
	ClientDancing[client] = false;
	ClientDuration[client] = 0;
	
	TF2_RemoveCondition(client, TFCond:54);
}

public Action:DurationTimer(Handle:timer, any:client)
{
	new timeleft = ClientDuration[client];
	
	if(!ClientDancing[client])
		return Plugin_Stop;
		
	if(ClientDuration[client]-- <= 0)
	{
		if(GetConVarInt(g_hDisplayTimer) > 0)
			PrintHintText(client, "Dancing finished");
			
		UndanceClient(client);
		return Plugin_Stop;
	}
	
	if(GetConVarInt(g_hDisplayTimer) > 0)
	{
		if(timeleft == 1) PrintHintText(client, "Dancing for: 1 second");
		else PrintHintText(client, "Dancing for: %i seconds", timeleft);
	}
	
	FakeClientCommand(client, "taunt"); // During condition 54, the taunt will ALWAYS be the thriller.
	return Plugin_Continue;
}

public TF2_OnWaitingForPlayersStart()
{
	waiting = true;
}

public TF2_OnWaitingForPlayersEnd()
{
	waiting = false;
}