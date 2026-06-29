/* 1 Minute Mute
* 
* 	DESCRIPTION
* 		Request: https://forums.alliedmods.net/showthread.php?t=220534
* 
* 		lets players with the flag "i" mute 1 player at a time for 1minute, 
* 		after the minute is over the player with "i" flag could mute another 
* 		player for a minute again
* 
* 	VERSIONS and ChangeLog
* 
* 		0.0.1.0	*	Initial Release (code borrowed from basecomm.sp and gag.sp, thanks SM team :))
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define 	PLUGIN_VERSION 		"0.0.1.0"

new Handle:Deadtalk = INVALID_HANDLE;
new Handle:ClientTimer[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
new bool:PlayerIsMuted[MAXPLAYERS+1] = {false, ...};
new bool:PlayerCanMute[MAXPLAYERS+1] = {false, ...};
new MutedBy[MAXPLAYERS+1];
new bool:Enabled = true;

public Plugin:myinfo = 
{
	name = "Timed Mute",
	author = "TnTSCS aka ClarkKent",
	description = "Certain players can mute other players for 1 minute",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
};

public OnPluginStart()
{
	new Handle:hRandom; // KyleS HATES handles
	
	HookConVarChange((hRandom = CreateConVar("sm_tmute_version", PLUGIN_VERSION, 
	"Version of Timed Mute", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_DONTRECORD)), OnVersionChanged);
	
	HookConVarChange((hRandom = CreateConVar("sm_tmute_enabled", "1", 
	"Plugin enabled?\n1 = Yes\n0 = No", _, true, 0.0, true, 1.0)), OnEnabledChanged);
	Enabled = GetConVarBool(hRandom);
	
	CloseHandle(hRandom); // KyleS HATES Handles
	
	Deadtalk = FindConVar("sm_deadtalk");
	if (Deadtalk == INVALID_HANDLE)
	{
		SetFailState("Unable to find CVar sm_deadtalk");
	}
	
	RegAdminCmd("sm_tmute", Cmd_TMute, ADMFLAG_CONFIG, "Allows player to mute other players for 1 minute");
}

public OnClientConnected(client)
{
	PlayerIsMuted[client] = false;
	PlayerCanMute[client] = true;
	MutedBy[client] = 0;
}

public OnClientDisconnect(client)
{
	if (IsClientInGame(client))
	{
		PlayerIsMuted[client] = false;
		PlayerCanMute[client] = false;
		
		if (MutedBy[client] > 0)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && i == MutedBy[client])
				{
					ClearTimer(ClientTimer[i]);
					PlayerCanMute[i] = true;
					PrintToChat(i, "Since %N disconnected, you can mute someone else now", client);
				}
			}
			
			MutedBy[client] = 0;
		}
	}
}

public Action:Cmd_TMute(client, args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "In-game command only");
		return Plugin_Handled;
	}
	
	if (!Enabled)
	{
		ReplyToCommand(client, "[SM] This command is not available");
		return Plugin_Handled;
	}
	
	if (!PlayerCanMute[client])
	{
		ReplyToCommand(client, "[SM] You cannot use this command right now");
		return Plugin_Handled;
	}
	
	if (args < 1)
	{
		PrintToChat(client, "[SM] Usage: sm_tmute <target>");
		return Plugin_Handled;
	}
	
	new String:target[MAX_NAME_LENGTH];
	new String:target_name[MAX_NAME_LENGTH];	
	new target_list[MAXPLAYERS];
	new target_count;
	new bool:tn_is_ml;	

	GetCmdArg(1, target, sizeof(target));

	if ((target_count = ProcessTargetString( 
			target,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_NO_BOTS,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		if (target_list[i] == -1)
		{
			return Plugin_Handled;
		}
		
		if (PlayerIsMuted[target_list[i]])
		{
			ReplyToCommand(client, "%N is already muted, try again later", target_list[i]);
			return Plugin_Handled;
		}
		else
		{
			MuteClient(target_list[i]);
			PlayerCanMute[client] = false;
			
			ClearTimer(ClientTimer[client]);
			
			ClientTimer[client] = CreateTimer(60.0, Timer_ResetClient, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	
	return Plugin_Handled;
}

MuteClient(client)
{
	PlayerIsMuted[client] = true;
	SetClientListeningFlags(client, VOICE_MUTED);
	CreateTimer(60.0, Timer_UnMute, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_ResetClient(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if (client == 0)
	{
		return Plugin_Continue;
	}
	
	ClientTimer[client] = INVALID_HANDLE;
	
	PlayerCanMute[client] = true;
	
	return Plugin_Continue;
}

public Action:Timer_UnMute(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if (client == 0)
	{
		return Plugin_Continue;
	}
	
	PlayerIsMuted[client] = false;
	MutedBy[client] = 0;
	
	if (GetConVarInt(Deadtalk) == 1 && !IsPlayerAlive(client))
	{
		SetClientListeningFlags(client, VOICE_LISTENALL);
	}
	else if (GetConVarInt(Deadtalk) == 2 && !IsPlayerAlive(client))
	{
		SetClientListeningFlags(client, VOICE_TEAM);
	}
	else
	{
		SetClientListeningFlags(client, VOICE_NORMAL);
	}
	
	return Plugin_Continue;
}

ClearTimer(&Handle:timer)
{
	if (timer != INVALID_HANDLE)
	{
		KillTimer(timer);
		timer = INVALID_HANDLE;
	}     
}

public OnVersionChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (!StrEqual(newVal, PLUGIN_VERSION))
	{
		SetConVarString(cvar, PLUGIN_VERSION);
	}
}

public OnEnabledChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	Enabled = GetConVarBool(cvar);
}