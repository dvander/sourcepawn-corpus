



char s_bot_quota_mode[][] = {
	"normal", // 0
	"fill",   // 1
	"match"   // 2
};

#include <sdktools>

public Plugin myinfo = 
{
	name = "Continue Bot quota order",
	author = "Bacardi",
	description = "Helps to keep bot quota amount right after round start",
	version = "1.0",
	url = "http://www.sourcemod.net/"
};


ConVar bot_quota;
ConVar bot_quota_mode;

float timestamp;
Handle timer_bot_quota_fix;

public void OnPluginStart()
{
	char game[128];
	GetGameFolderName(game, sizeof(game));

	if(!(StrEqual(game, "cstrike", false) || StrEqual(game, "csgo", false))) SetFailState("Plugin made for cstrike and csgo only");


	bot_quota = FindConVar("bot_quota");
	bot_quota_mode = FindConVar("bot_quota_mode");



	HookEvent("round_start", rounds, EventHookMode_PostNoCopy);
	HookEvent("round_end", rounds, EventHookMode_PostNoCopy);

	HookEvent("player_team", player_team);
}


public void rounds(Event event, const char[] name, bool dontBroadcast)
{
	// Keep record when in-game own bot_quota system work (round_end and 25sec after round_start)
	timestamp = GetGameTime();
}


public void player_team(Event event, const char[] name, bool dontBroadcast)
{
	// player is going to change team

	// First 25 sec, bots refill slots automatically by itselfs
	if(timestamp + 25.0 > GetGameTime())
	{
		return;
	}



	int client = GetClientOfUserId(event.GetInt("userid"));

	// ignore bots
	if(IsFakeClient(client)) return;

	
	int newteam = event.GetInt("team");
	int oldteam = event.GetInt("oldteam");
	bool disconnect = event.GetBool("disconnect");

	int maxplayerslots = GetMaxHumanPlayers(); // in some games, max players slots amount could change between maps and game modes
	int freeplayerslots = maxplayerslots;

	int players_inteams;
	int bots[MAXPLAYERS];
	int bot_count;
	int human_count;


	for(int i = 1; i <= maxplayerslots; i++)
	{
		if(!IsClientConnected(i)) continue;

		freeplayerslots--;

		if(!IsClientInGame(i)) continue;

		if(!IsFakeClient(i)) human_count++;

		if(GetClientTeam(i) >=2)
		{
			players_inteams++;
			if(IsFakeClient(i)) bots[bot_count++] = GetClientUserId(i);
		}
	}

	// This player leave from server
	if(disconnect)
	{
		freeplayerslots++;
		human_count--;
	}

	// This player will enter in team
	if(oldteam <= 1 && newteam >= 2)
	{
		players_inteams++;
	}
	// This player will enter in spec
	else if(oldteam >= 2 && newteam <= 1)
	{
		players_inteams--;
	}




	//PrintToServer("freeplayerslots %i", freeplayerslots);



	// == Get bot_quota_mode ==
	//
	char buffer[30];
	bot_quota_mode.GetString(buffer, sizeof(buffer));
	int quota_mode;

	for(int a = 0; a < sizeof(s_bot_quota_mode); a++)
	{
		if(StrEqual(buffer, s_bot_quota_mode[a], false))
		{
			quota_mode = a;
			break;
		}
	}


	// == Hold bot_quota value during bot_add commands ==
	//
	// Hold real value of bot_quota when this event launch multiple times in short time.
	static int quota;
	if(timer_bot_quota_fix == null) quota = bot_quota.IntValue;






	// == Math for bot quota offset ==
	//
	// If 'normal', keep this N amount of bots in game.
	// If 'fill', the server will adjust bots to keep N players in the game, where N is bot_quota.
	// If 'match', the server will maintain a 1:N ratio of humans to bots, where N is bot_quota.
	int bot_quota_offset;

	switch(quota_mode)
	{
		case 0: // normal
		{
			// bot_quota_mode "normal" maybe not need any action
			//bot_quota_offset = bot_count - quota;
			return;
			
		}
		case 1: // fill
		{
			bot_quota_offset = players_inteams - quota;
		}
		case 2: // match
		{
			bot_quota_offset = bot_count - (human_count * quota); // bots appear when human player has enter any team (1, 2, 3)
		}
	}


	//PrintToServer("freeplayerslots %i, players_inteams %i, bot_quota_offset %i, bot_count %i", freeplayerslots, players_inteams, bot_quota_offset, bot_count);



	//DataPack pack = new DataPack();
	//pack.WriteCell(newteam);
	//pack.Reset();
	// short bots
	//SortCustom1D(bots, bot_count, bots_sortfunc /*,pack*/);
	//SortIntegers(bots, bot_count, Sort_Descending);
	//delete pack;



	//

	for( ; bot_quota_offset > 0 || bot_quota_offset < 0; bot_quota_offset < 0 ? bot_quota_offset++:bot_quota_offset--)
	{
		//PrintToServer("bot_quota_offset %i", bot_quota_offset);
		
		if(bot_quota_offset < 0)
		{
			//PrintToServer("- bot_add");
			ServerCommand("bot_add");

			if(timer_bot_quota_fix == null) timer_bot_quota_fix = CreateTimer(2.0, delay_bot_quota_fix, bot_quota.IntValue);
		}
		
		if(bot_quota_offset > 0 && bot_count > 0)
		{
			//PrintToServer("- kick %i", bots[bot_count-1]);
			ServerCommand("kickid %i", bots[--bot_count]);
		}
	}
}

public Action delay_bot_quota_fix(Handle timer, any bot_quota_fix)
{
	timer_bot_quota_fix = null;

	bot_quota.SetInt(bot_quota_fix, true, true);
}

public int bots_sortfunc(int elem1, int elem2, const int[] array, Handle hndl)
{

	if( elem1 < elem2 ) return -1;

	return 1;
}