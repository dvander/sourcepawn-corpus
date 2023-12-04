
//training.train_idtestwaiting_02
//training.train_idtestwaiting_01
//training.train_failure_03b
//training.train_failure_02
//training.train_bombplantbfail_03
//Survival.BeaconGlobal
//UIPanorama.round_report_round_won

char gamesound[][] =
{
	"UIPanorama.round_report_round_won",
	"Survival.BeaconGlobal",
	"training.train_idtestwaiting_02"
};

#include <cstrike>
#include <sdktools>

bool HasVoted = false;
bool HasEnd = false;

int cooldownfrommapstart;

public void OnPluginStart()
{
	RegConsoleCmd("sm_rr", CreateVote);

	//HookEventEx("begin_new_match", events);
}

public Action CreateVote(int client, int args)
{

	if(client && !IsClientInGame(client))
		return Plugin_Handled;


	if(HasVoted)
	{
		if(!HasEnd)
			ReplyToCommand(client, "[SM] Vote Restart Game is in progress...");

		ReplyToCommand(client, "[SM] Vote Restart Game already used once.");
		return Plugin_Handled;
	}


	if(client)
	{

		int time = cooldownfrommapstart - GetTime();
		
		if(time > 0)
		{
			ReplyToCommand(client, "[SM] There is cooldown in progress from start of map, %i seconds", time);
			return Plugin_Handled;
		}

		ShowActivity2(client, "[SM]", " Vote Restart Game started");
		ReplyToCommand(client, "[SM] You started Vote Restart Game");
	}
	else
	{
		ShowActivity2(0, "[SM]", " Vote Restart Game started");
	}


	HasVoted = true;

	PrintToChatAll("- Vote appear soon, under 30 sec or so.");

	StartVote();

	return Plugin_Handled;
}

//public void events(Event event, const char[] name, bool dontBroadcast)
public void OnConfigsExecuted()
{
	cooldownfrommapstart = GetTime() + 120;

	HasEnd = false;
	HasVoted = false;
}

void StartVote()
{
	CreateTimer(2.0, VoteStart, 0, TIMER_FLAG_NO_MAPCHANGE);
}

public Action VoteStart(Handle timer, any data)
{
	static int x;

	if(data == 0)
		x = 0;

	if(IsVoteInProgress())
	{
		// When fail to create vote, try few times again.
		if(data < 2)
		{
			float delay = float(CheckVoteDelay());
			CreateTimer(delay, VoteStart, ++x, TIMER_FLAG_NO_MAPCHANGE);
			
			PrintToChatAll("[SM] Vote Restart Game failed(%i/2) to start, trying again after %0.0f seconds", x, delay);
		}
		else
		{
			PrintToChatAll("[SM] Vote Restart Game failed... You can try use command again");
			HasEnd = false;
			HasVoted = false;
		}

		return Plugin_Continue;
	}


	int targets[MAXPLAYERS+1];
	int numtargets;

	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || IsFakeClient(i))
			continue;
		
		targets[numtargets] = i;
		numtargets++;
	}

	if(numtargets == 0)
		return Plugin_Handled;

	Menu menu = new Menu(menu_handler, MenuAction_End|MenuAction_VoteCancel)
	menu.Pagination = MENU_NO_PAGINATION;
	
	menu.VoteResultCallback = vote_handler;

	//menu.AddItem("0", "-Disabled-", ITEMDRAW_SPACER);
	//menu.AddItem("0", "-Disabled-", ITEMDRAW_SPACER);
	//menu.AddItem("0", "-Disabled-", ITEMDRAW_SPACER);
	//menu.AddItem("0", "-Disabled-", ITEMDRAW_SPACER);
	menu.AddItem("10", "Yes");
	menu.AddItem("0", "No");
	menu.ExitButton = false;
	menu.SetTitle("Vote Restart Game");

	//menu.ShufflePerClient(4, -1);

	menu.DisplayVote(targets, numtargets, 15);


	EmitGameSound(targets,
					numtargets,
					gamesound[GetRandomInt(0, 2)]);


	return Plugin_Continue
}


public int menu_handler(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_VoteCancel && param1 == VoteCancel_NoVotes)
	{
		HasEnd = true;
		PrintToChatAll("[SM] Vote End: No votes");
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}

	return 0;
}


public void vote_handler(Menu menu, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
	HasEnd = true;

	int winner = 0;

	if(num_items > 1 &&
		item_info[0][VOTEINFO_ITEM_VOTES] == item_info[1][VOTEINFO_ITEM_VOTES])
	{
		winner = GetRandomInt(0, 1);
	}

	char info[3], display[50];
	menu.GetItem(item_info[winner][VOTEINFO_ITEM_INDEX], info, sizeof(info), _, display, sizeof(display), -1);

	int voteresult = StringToInt(info);

	if(voteresult == 0)
	{
		PrintToChatAll("[SM] Vote end: Vote result %s", display);
		return;
	}

	PrintToChatAll("[SM] Vote end: Vote result, Restart Game = %s", display);

	ServerCommand("mp_restartgame %i", voteresult);
}