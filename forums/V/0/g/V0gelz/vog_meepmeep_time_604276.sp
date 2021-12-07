/***************************************************************************
 *  vog_meepmeep_time.sma
 *   version 1.1          Date: 25/03/2008
 *   Author: Frederik     frederik156@hotmail.com
 *   Alias: V0gelz
 *
 *   *UPDATE 6/04/08*
 *   This is a update for the mod TF2, it will now play the sounds like it should.
 *   Read the note for down the readme!!
 *   I also changed the speed so it will not lag the server.
 *    
 *  An other time plugin. This is based on the cartoon meep meep.
 *  This is basicly the same like the bullet time plugin but now the time
 *  go's faster. I do not recomment that you use this plugin with the
 *  bullet time plugin. But you can try it. Don't think it will have that much
 *  impact on it but still. You can allways use other sounds to.
 *  You can try
 *
 *  Have fun!
 *
 *  SixSicSix recomments to use '  Less sv cheats ' plugin.
 *  To enable the slow effect sv_cheats 1 must be on.
 *  People can use noclip and stuff if that is on.
 *  This plugin blocks those commands so you can use this plugin safely.
 *
 *  http://forums.alliedmods.net/showthread.php?t=66390
 *
 *
 *  Admin commands:
 *
 *  sm_meepmeep			-1/0 this enables meep meep speed
 *				when it is set to 1 it will
 *				stay untill an admin sets it back to 0.
 *  CVARS:
 *
 *  sm_meepmeep_vote 1         -enables/disables the player's "vote_meepmeep"
 *                              chat command so that only admins can set
 *                              the meep meep mode.
 *
 *  sm_meepmeep_vote_delay 180	-time before the meep meep vote
 *				is allowed after map start. 180 = 3 min.
 *
 *  sm_meepmeep_vote_int 180   -interval between vote casts. In seconds.
 *				180 = 3 min.
 *
 *  *NOTE*
 *  For the mod TF2 you will have to put this command to 1.
 *  Otherwise the sounds will not be played to the people.
 *
 *  sm_meep_sounds_dl 1  	 - 0: Client will not download the sounds true
 *				      this plugin. But you can use a third party
 *				      plugin to let them download for the client.
 *				   1: All sounds will be download to the client
 * 				      that uses this plugin true this plugin.
 *				      No need for any other download plugin.
 *
 * For Players:
 *
 *      Say: vote_meepmeep    -- sets up a vote
 *      Say: meep meep	      -- sets up a vote
 *
 *
 ***************************************************************************/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

new StartTime;
new LastVote;
new Handle:Vote_MeepMeep;
new Handle:VoteDelay;
new Handle:VotesInterval;
new Handle:TimeScale;
new vote_on;

// Sounds
new Handle:meep_sounds_dl;

public Plugin:myinfo =
{
	name = "Meep Meep Time Plugin",
	author = "V0gelz",
	description = "Meep Meep Time",
	version = "1.1",
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	RegAdminCmd("sm_meepmeep", Command_MeepMeep, ADMFLAG_VOTE, "Set Meep Meep mode 1/0");
	RegConsoleCmd("say", Command_OnSay);

	CreateConVar("sm_meepmeep_version","1.1", "", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY);
	TimeScale = FindConVar("host_timescale");
	Vote_MeepMeep = CreateConVar("sm_meepmeep_vote","1", "Meep Meep Voting on/off.", FCVAR_PLUGIN);
	VoteDelay= CreateConVar("sm_meepmeep_vote_delay","180.0", "Time before the meep meep vote is allowed after map start.", 0, true, 0.0, true, 1000.0);
	VotesInterval = CreateConVar("sm_meepmeep_vote_int", "180.0", "Interval between vote casts.", 0, true, 0.0, true, 60.0);

	// Sounds
	meep_sounds_dl = CreateConVar("sm_meep_sounds_dl","1", "Set how the sounds are beeing downloaded.", FCVAR_PLUGIN);

}

public OnMapStart()
{
	StartTime = GetTime();

	PrecacheSound( "misc/meepmeep/rrtong.mp3", true);
	PrecacheSound( "misc/meepmeep/speedy.mp3", true);
	new Float:MEEP_SOUNDS_DL = GetConVarFloat(meep_sounds_dl);
	if(MEEP_SOUNDS_DL == 1)
	{
		AddFileToDownloadsTable("sound/misc/meepmeep/rrtong.mp3");
		AddFileToDownloadsTable("sound/misc/meepmeep/speedy.mp3");
		PrintToServer("[MeepMeep] Sounds are beeing downloaded true this plugin.");
	}
	else
	{
		PrintToServer("[MeepMeep] Sounds are not beeing downloaded true this plugin.");
	}
}

public Action:Command_OnSay( client , args)
{
	decl String:text[192];
	GetCmdArgString(text, sizeof(text));

	new User[32];
	GetClientName(client,User,31);

	new startidx;
	
	if (text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}

	if ((strcmp(text[startidx], "meep", false) == 0) || (strcmp(text[startidx], "meep meep", false) == 0) || (strcmp(text[startidx], "speed", false) == 0))
	{
		new meepmeep = GetConVarInt(TimeScale);
		if(meepmeep == 2)
		{
			PrintToChatAll("Meep Meep!!!");
		}
		if(meepmeep == 1)
		{
			PrintToChatAll("Meep Meep is tired for now.");
		}
		return Plugin_Handled;
	}

	if ((strcmp(text[startidx], "vote_meepmeep", false) == 0) || (strcmp(text[startidx], "meep meep", false) == 0))
	{
		if(IsPlayerAlive( client ) == 0)
		{
			PrintToChat( client , "Sorry your dead, you can't start a vote.");
			return Plugin_Handled;
		}
		new Float:MEEPMEEP_VOTE = GetConVarFloat(Vote_MeepMeep);
		if(MEEPMEEP_VOTE == 1 && vote_on == 0)
		{
			if (IsVoteInProgress())
			{
				PrintToChat( client ,"[SM]  Voting has started...");
				return Plugin_Handled;
			}

			new nFromStart = GetTime() - StartTime;
			new nFromLast = GetTime() - LastVote;	

			new meepmeep = GetConVarInt(TimeScale);

			if(nFromLast >= GetConVarInt(VotesInterval))
			{
				if(nFromStart >= GetConVarInt(VoteDelay))
				{
					PrintToChatAll("%s :   vote_meepmeep", User);
					// speedy
					EmitSoundToAll("misc/meepmeep/rrtong.mp3");
					if(meepmeep == 1)
					{
						new Handle:menu = CreateMenu(Handle_Meep_VoteMenu);
						SetMenuTitle(menu, "Do you want Meep Meep Speed?");
						AddMenuItem(menu, "yes", "Help us meep meep!");
						AddMenuItem(menu, "no", "No thanks");
						SetMenuExitButton(menu, false);
						VoteMenuToAll(menu, 20);
					}
					LastVote = GetTime();
					PrintToChat( client ,"[SM]  Vote started...");
					PrintToChatAll("[SM]  The meep meep vote has started!");
				}
				else
				{
					PrintToChat( client ,"[SM]  Meep Meep need to warm up!");
				}
			}
			else
			{
				PrintToChat( client ,"[SM]  Meep Meep is tired, please wait 3 min.");
			}
		}
		if(MEEPMEEP_VOTE == 0)
		{
			PrintToChat( client ,"[SM]  Sorry, 'vote_meepmeep' is disabled unless admin sets it otherwise");
		}
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Handle_Meep_VoteMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		/* This is called after VoteEnd */
		CloseHandle(menu);
	} 
	else if (action == MenuAction_VoteEnd)
	{
		new meepmeep = GetConVarInt(TimeScale);
		PrintToChatAll("[SM]  Vote has ended...");

		if(meepmeep == 1)
		{
			/* 0=yes, 1=no */
			if (param1 == 0)
			{
				PrintToChatAll("Voting Results: Meep Meep Speed has started for 15 Seconds!");
				
				CreateTimer(0.1, count_15);
				CreateTimer(2.0, count_14);
				CreateTimer(4.0, count_13);
				CreateTimer(6.0, count_12);
				CreateTimer(8.0, count_11);
				CreateTimer(10.0, count_10);
				CreateTimer(12.0, count_9);
				CreateTimer(14.0, count_8);
				CreateTimer(16.0, count_7);
				CreateTimer(18.0, count_6);
				CreateTimer(20.0, count_5);
				CreateTimer(22.0, count_4);
				CreateTimer(24.0, count_3);
				CreateTimer(26.0, count_2);
				CreateTimer(28.0, count_1);
				CreateTimer(30.0, count_01);

			}
			if (param1 == 1)
			{
				PrintToChatAll("Voting Results: Meep Meep Speed vote failed!");
			}
		}
	}
}

public Action:Command_MeepMeep(client, Arguments)
{
	//Error Check:
	if(Arguments < 1)
	{

		PrintToConsole(client, "[SM]  Usage: sm_meepmeep 1/0");
		return Plugin_Handled;
	}

	//Retrieve Arguments:
	new String:Given_MeepMeep[32], Converted_MeepMeep;
	GetCmdArg(1, Given_MeepMeep, sizeof(Given_MeepMeep));
		
	//Convert:
	StringToIntEx(Given_MeepMeep, Converted_MeepMeep);

	new User[32];
	GetClientName(client,User,31);

	if(Converted_MeepMeep == 1)
	{
		PrintToConsole(client,"[SM]  MEEP MEEP mode is now ON");
		PrintToChatAll("[SM]  Admin %s has turned MEEP MEEP ON", User);
		ServerCommand( "sv_cheats 1" );
		ServerCommand( "host_timescale 2" );
	}

	if(Converted_MeepMeep == 0)
	{
		PrintToConsole(client,"[SM]  MEEP MEEP mode is now OFF");
		PrintToChatAll("[SM]  Admin %s has turned MEEP MEEP OFF", User);
		ServerCommand( "host_timescale 1" );
		ServerCommand( "sv_cheats 0" );
	}

	return Plugin_Handled;
}

public Action:count_01(Handle:timer){
vote_on = 0;
ServerCommand( "host_timescale 1" );
ServerCommand( "sv_cheats 0" );
PrintCenterTextAll("Meep Meep Speed has ended!");
}

public Action:count_1(Handle:timer){
PrintCenterTextAll("Meep Meep Speed will end in 1 second!");
}

public Action:count_2(Handle:timer){
PrintCenterTextAll("Meep Meep Speed will end in 2 second!");
}

public Action:count_3(Handle:timer){
PrintCenterTextAll("Meep Meep Speed will end in 3 second!");
}

public Action:count_4(Handle:timer){
PrintCenterTextAll("Meep Meep Speed will end in 4 second!");
}

public Action:count_5(Handle:timer){
PrintCenterTextAll("Meep Meep Speed will end in 5 second!");
}

public Action:count_6(Handle:timer){
PrintCenterTextAll("Meep Meep Speed will end in 6 second!");
}

public Action:count_7(Handle:timer){
PrintCenterTextAll("Meep Meep Speed will end in 7 second!");
}

public Action:count_8(Handle:timer){
PrintCenterTextAll("Meep Meep Speed will end in 8 second!");
}
public Action:count_9(Handle:timer){
PrintCenterTextAll("Meep Meep Speed will end in 9 second!");
}

public Action:count_10(Handle:timer){
PrintCenterTextAll("Meep Meep Speed will end in 10 second!");
}

public Action:count_11(Handle:timer){
PrintCenterTextAll("Meep Meep Speed will end in 11 second!");
}

public Action:count_12(Handle:timer){
PrintCenterTextAll("Meep Meep Speed will end in 12 second!");
}

public Action:count_13(Handle:timer){
PrintCenterTextAll("Meep Meep Speed will end in 13 second!");
}

public Action:count_14(Handle:timer){
PrintCenterTextAll("Meep Meep Speed will end in 14 second!");
}

public Action:count_15(Handle:timer){
EmitSoundToAll("misc/meepmeep/rrtong.mp3");
vote_on = 1;
ServerCommand( "sv_cheats 1" );
ServerCommand( "host_timescale 1.5" );
PrintCenterTextAll("Meep Meep Speed will end in 15 second!");
}