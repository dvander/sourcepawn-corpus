
//
//	Server event "player_disconnect", Tick 52023:
//	- "userid" = "170"
//	- "reason" = "#GameUI_Disconnect_TooManyCommands"
//	- "name" = "'Bacardi"
//	- "networkid" = "STEAM_1:1:14163588"
//
//
//
//	In normal game mode, where is no fast-respawn system in use, glitch play drowning sound: "player/pl_wade1.wav"
//
//
//	In normal game mode, when player connect/re-connect just before round_start,
//	while connecting to server, using "jointeam" command to change team and team change have to happen in current round (jointeam 3 1)
//	and using "joingame" command, player could spawn on entity point_viewcontrol origin (or else were).
//
//	One way to prevent this is block command(s) before "player_connect_full" event.
//
//	On game modes where are fast-respawn system, player can try to do glitch on every connection.
//
//
//



public Plugin myinfo =
{
	name = "[csgo] Joingame bug/exploit - block",
	author = "Bacardi",
	description = "Stop players to spawn in wierd place",
	version = "01.02.2022",
	url = "https://forums.alliedmods.net"
};


#include <sdktools>

enum {
	jointeam_cmd = 0,
	joingame_cmd,
	joincmds_max
};


bool allowspam[MAXPLAYERS+1] = {true, ...};

int spamcount[MAXPLAYERS+1][joincmds_max];

int spamthreshold = 15;

ConVar sm_joingame_spam_threshold;
ConVar sm_joingame_spam_punish;


public void OnPluginStart()
{
	HookEvent("player_connect_full", player_connect_full);

	// Keep record of this command as well
	AddCommandListener(jointeam, "jointeam");

	// Lets be minimalist, block this command only on bad time.
	AddCommandListener(joingame, "joingame");

	sm_joingame_spam_threshold = CreateConVar("sm_joingame_spam_threshold", "15", "The limit to spam command while connecting to server", _, true, 15.0);
	sm_joingame_spam_punish = CreateConVar("sm_joingame_spam_punish", "0", "Punish method: 0 = nothing, 1 = Kick", _, true, 0.0);
}


// jointeam
public Action jointeam(int client, const char[] command, int args)
{

	if(!client)
		return Plugin_Continue;


	if(!allowspam[client])
	{
		spamcount[client][jointeam_cmd]++;
		return Plugin_Handled;
	}


	return Plugin_Continue;
}


// joingame
public Action joingame(int client, const char[] command, int args)
{

	if(!client)
		return Plugin_Continue;


	if(!allowspam[client])
	{
		spamcount[client][joingame_cmd]++;
		return Plugin_Handled;
	}


	return Plugin_Continue;
}


public void OnClientConnected(int client)
{

	spamthreshold = sm_joingame_spam_threshold.IntValue;

	spamcount[client][jointeam_cmd] = 0;
	spamcount[client][joingame_cmd] = 0;
	allowspam[client] = false;
}


public void player_connect_full(Event event, const char[] name, bool dontBroadcast)
{
	// "index" not always work on this "player_connect_full" event

	int client = GetClientOfUserId(event.GetInt("userid"));

	if(!client)
	{
		LogError("Event player_connect_full with userid = %i, return client index 0. We will reset allowspam[] array to avoid bugs.", event.GetInt("userid"));
		
		for(int x = 0; x < MAXPLAYERS+1; x++)
		{
			allowspam[x] = true;
		}
	}
	else
	{
		//PrintToServer("jointeam_cmd %i", spamcount[client][jointeam_cmd]);
		//PrintToServer("joingame_cmd %i", spamcount[client][joingame_cmd]);
		
		if(spamcount[client][jointeam_cmd] >= spamthreshold ||
			spamcount[client][joingame_cmd] >= spamthreshold)
		{
			if(!IsClientInGame(client))
			{
			}
			else
			{
				LogAction(-1, -1, "Player %L has spam command(s) over threshold limit jointeam = %i/%i, joingame = %i/%i",
							client,
							spamcount[client][jointeam_cmd], spamthreshold,
							spamcount[client][joingame_cmd], spamthreshold);

				PunishPlayer(client);
			}
		}
	}


	allowspam[client] = true;
}


void PunishPlayer(int client)
{
	switch(sm_joingame_spam_punish.IntValue)
	{
		case 1:
		{
			LogAction(-1, -1, "Kicked %L for spamming commands", client);
			KickClient(client, "#GameUI_Disconnect_TooManyCommands");
		}
	}
}

















public void player_spawn(Event event, const char[] name, bool dontBroadcast)
{
}



public Action soundhook(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH],
	  int &entity, int &channel, float &volume, int &level, int &pitch, int &flags,
	  char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if(0 < entity <= MaxClients && StrEqual(sample, "player/pl_wade1.wav", false))
	{
		//PrintToServer("-%s   userid = %i , Tick %i:", sample, GetClientUserId(entity), GetGameTickCount());
		PrintToServer("soundhook - m_AirFinished %f = %f", GetEntPropFloat(entity, Prop_Data, "m_AirFinished"), GetGameTime());
	}
}

