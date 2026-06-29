#include <sourcemod>
#include <warden>
#include <basecomm>

new bool:Muted[MAXPLAYERS+1] = {false, ...};

public Plugin:myinfo =
{
	name = "Warden mute",
	author = "tommie113",
	description = "Allows wardens to mute terrorists.",
	version = "1.0",
	url = ""
}

public OnPluginStart()
{
	RegConsoleCmd("sm_wmute", Wmute, "Allows a warden to mute all terrorists for a specified duration or untill the next round.");
	RegConsoleCmd("sm_wunmute", Wunmute, "Allows a warden to unmute the terrorists.");

	HookEvent("round_end", OnRoundEnd);
}

public Action:Wmute(int client, any args)
{
	if(!warden_iswarden(client))
	{
		ReplyToCommand(client, "You have to be warden in order to use this command.");
		return Plugin_Handled;
	}
	
	if(args < 1)
	{
		Mute(0);
		return Plugin_Handled;
	} else if (args == 1) {
		new String:arg1[10];
		GetCmdArg(1, arg1, sizeof(arg1));
		new argument1;
		argument1 = StringToInt(arg1);
		Mute(argument1);
		return Plugin_Handled;
	} else {
		ReplyToCommand(client, "Usage: !wmute <duration>");
		return Plugin_Handled;
	}
}

public Action:Wunmute(int client, any args)
{
	if(!warden_iswarden(client))
	{
		ReplyToCommand(client, "You have to be warden in order to use this command.");
		return Plugin_Handled;
	}
	
	Unmute();
	return Plugin_Handled;
}

public OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	Unmute();
}

public Mute(a)
{
	for(new i = 1; i < MAXPLAYERS; i++)
	{
		if(IsClientConnected(i) && IsPlayerAlive(i) && !IsFakeClient(i))
		{
			if(GetClientTeam(i) == 2)
			{
				if(!BaseComm_IsClientMuted(i))
				{
					BaseComm_SetClientMute(i, true);
					Muted[i] = true;
				}
			}
		}
	}
	if(a > 0)
	{
		new Float:b = float(a);
		CreateTimer(b, Timer);
	}
	
}

public Action:Timer(Handle timer)
{
	Unmute();
}

public Unmute()
{
	for(new i = 1; i < MAXPLAYERS; i++)
	{
		if(Muted[i])
		{
			BaseComm_SetClientMute(i, false);
			Muted[i] = false;
		}
	}
}


