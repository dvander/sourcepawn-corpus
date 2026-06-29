#pragma semicolon 1
#pragma tabsize 0
#define DEBUG

#define PREFIX " \x04[Map Time]\x01"

#include <sourcemod>
#include <sdktools>

ConVar mp_timelimit;
ConVar g_cvStartVoteTime;
ConVar g_cvDisplayVoteTime;
ConVar g_cvOption1;
ConVar g_cvOption2;
ConVar g_cvOption3;
ConVar g_cvOption4;
char option1[16];
char option2[16];
char option3[16];
char option4[16];
int Options[5];
public Plugin myinfo = 
{
	name = "Vote for mp_timelimit value",
	author = "SheriF",
	description = "",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	mp_timelimit = FindConVar("mp_timelimit");
    g_cvStartVoteTime = CreateConVar("sm_start_vote_time", "60.0", "After how much seconds from map start the vote map time should be started.");
    g_cvDisplayVoteTime = CreateConVar("sm_display_vote_time", "15", "The amount of seconds the vote map time is being displayed to all players.");
    g_cvOption1 = CreateConVar("sm_vote_option1", "10", "Option 1 in the vote (minutes).");
    g_cvOption2 = CreateConVar("sm_vote_option2", "20", "Option 2 in the vote (minutes).");
    g_cvOption3 = CreateConVar("sm_vote_option3", "30", "Option 3 in the vote (minutes).");
    g_cvOption4 = CreateConVar("sm_vote_option4", "40", "Option 4 in the vote (minutes).");
    AutoExecConfig(true, "Map_Time_Vote");
}
public void OnConfigsExecuted()
{
	Options[1] = GetConVarInt(g_cvOption1);
	Options[2] = GetConVarInt(g_cvOption2);
	Options[3] = GetConVarInt(g_cvOption3);
	Options[4] = GetConVarInt(g_cvOption4);
}
public void OnMapStart()
{
	CreateTimer(g_cvStartVoteTime.FloatValue, StartVote);
}
public Action StartVote(Handle timer)
{
	Menu menu = new Menu(MenuHandler_MapTime);
    menu.VoteResultCallback = VoteResultCallback_MapTime;
    menu.SetTitle("Choose map time");
    if(Options[1]!=0)
    {
  		IntToString(Options[1], option1, 16);
   		StrCat(option1, 16, " Minutes");
   	}
   	else
   	strcopy(option1, 16, "No time limit");
    if(Options[2]!=0)
    {
  		IntToString(Options[2], option2, 16);
   		StrCat(option2, 16, " Minutes");
   	}
   	else
   	strcopy(option2, 16, "No time limit");
   	if(Options[3]!=0)
    {
  		IntToString(Options[3], option3, 16);
   		StrCat(option3, 16, " Minutes");
   	}
   	else
   	strcopy(option3, 16, "No time limit");
   	if(Options[4]!=0)
    {
  		IntToString(Options[4], option4, 16);
   		StrCat(option4, 16, " Minutes");
   	}
   	else
   	strcopy(option4, 16, "No time limit");
    menu.AddItem(option1, option1);
	menu.AddItem(option2, option2);
	menu.AddItem(option3, option3);
    menu.AddItem(option4, option4);
    menu.ExitButton = false;
    menu.DisplayVoteToAll(g_cvDisplayVoteTime.IntValue);
}
public int MenuHandler_MapTime(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_End)
        delete menu;
}

public void VoteResultCallback_MapTime(Menu menu, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
    char item[65];
    menu.GetItem(item_info[0][VOTEINFO_ITEM_INDEX], item, sizeof(item));
    if (StrEqual(item, option1, false))
    {
		SetConVarInt(mp_timelimit, Options[1]);
		PrintToChatAll("%s The vote map time is over. The result is \x07%s\x01",PREFIX,option1);
	}
	else if (StrEqual(item, option2, false))
    {
		SetConVarInt(mp_timelimit, Options[2]);
		PrintToChatAll("%s The vote map time is over. The result is \x07%s\x01",PREFIX,option2);
	}
	else if (StrEqual(item, option3, false))
    {
		SetConVarInt(mp_timelimit, Options[3]);
		PrintToChatAll("%s The vote map time is over. The result is \x07%s\x01",PREFIX,option3);
	}
	else if (StrEqual(item, option4, false))
    {
		SetConVarInt(mp_timelimit, Options[4]);
		PrintToChatAll("%s The vote map time is over. The result is \x07%s\x01",PREFIX,option4);
	}	
}
