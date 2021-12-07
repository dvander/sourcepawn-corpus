/********************************************************************************
 *  vog_beammeup.sma         version 2.4                Date: 29/03/2008
 *   Author: Frederik        frederik156@hotmail.com
 *   Alias: V0gelz           Upgrade: http://dekaftgent.be/css/ - http://www.sourcemod.com
 *   Original Idea: Eric Lidman aka Ludgwig Van
 *
 *
 *  I guess alot of people will remember this plugin.
 *  I have been rewriting it from scratch and i know there are still some 
 *  functions in that aren't in yet from luds. Still it's a nice start
 *  to begin from.
 *  I'm using the transporter sounds from the show and 
 *  I will update this plugin one's in a while so don't worry.
 *  If you find bugs or maybe ideas or how i can write this better please
 *  post it on the topic on the forum of sourcemod.com.
 *  The effects may be changed during updating of this plugin to make it better.
 *  
 *  YouTube Video: http://www.youtube.com/watch?v=00vjYD3Ia34
 *  
 *
 ********************************************************************************
 * 
 * Ever watch the orignal Star-Trek TV show? This is a fun plugin which
 *  gives limited teleporting powers (you can decide how limited) to
 *  players using the theme of the Star-Trek matter transporter. There
 *  are sounds from the show too, including our favorite first engineer,
 *  the keeper of the transporter, Scotty. This plugin is currently only
 *  set up to work with the Counter-Strike Source and Team Fortress 2.
 *  Many player commands listed below the admin command and cvars: 
 *
 * Here are the admins scotty control commands:
 *
 *  sm_scotty_on         	 --- Makes scotty fully functional.
 *
 *  sm_scotty_off        	 --- Shuts Scotty down completely.
 *
 *  sm_votescotty       	 --- admin command to start a vote to enable scotty
 *                           	 Players do not have access to this.
 *			    	 They can however do the same with 'vote_scotty'
 * 			    	 through the chat if you
 *			     	 allow that with amx_scotty_vote (below)
 *
 * CVARS: which can be set in  ../cstike/cfg/sourcemod/sourcemod.cfg
 * 
 *  sm_startrek_transporter 1    -set to 1 to make scotty fully functional.
 * 				  set to 0 to shut scotty down completely.
 *
 *  sm_scotty_multibeam 0        -set to 0 for one transportporter allowed to
 *                                work at a time for all players to share.
 *                                -set to 1 for allowing anyone at anytime to
 *                                teleport independently but at the same time
 *                                warning, this mode 2 could be laggy perhaps.
 *
 *  sm_scotty_rebeamtime 25      -sets the amount of time a player must wait 
 *                                to teleport again using scotty. This is only
 *                                applicable if the mode is unlimited, crazy,
 *                                or insane. Time is seconds.
 * 
 *  sm_scotty_spawntimedelay 15  -sets the amount of time a player has to wait
 *                                in order to beam. Setting above 25 seconds may 
 *                                have adverse effects if the rounds are short
 *
 *  sm_scotty_vote 1             -enables/disables the player's "vote_scotty"
 *                                chat command so that only admins can set
 *                                the scotty mode.
 *
 *  sm_scotty_vote_delay 300	 -time before the scotty vote
 *				 is allowed after map start. 300 = 5 min.
 *
 *  sm_scotty_vote_interval 600  -interval between vote casts. In seconds.
 *				 600 = 10 min.
 *
 *  sm_scotty_sounds_dl 1  	 - 0: Client will not download the sounds true
 *				      this plugin. But you can use a third party
 *				      plugin to let them download for the client.
 *				   1: Only the 3 necessary sounds will be downloaded.
 *				      Only the beam in and out sounds
 * 				      will be downloaded to the client.
 *				   2: All sounds will be download to the client
 * 				      that uses this plugin true this plugin.
 *				      No need for any other download plugin.
 *				 
 *
 * For Players:
 *
 *      Say: vote_scotty    -- sets up a vote
 *
 *      say: /scotty_help      -- opens up an MOTD style window explaing
 *                                usage of all scotty commands
 *      say: /scotty           -- opens up the scotty player command menu
 *      console: scotty_menu   -- opens up the scotty player command menu
 *
 *	
 *  You can save up to any 3 locations on a map with while alive
 *  with the commands below: 
 * 
 *      say: scotty lock onto my coordinates        --- save set 1
 *		console: scotty_lock_onto_my_coordinates
 *
 *      say: scotty lock 2 onto my coordinates      --- save set 2
 *		console: scotty_lock_2_onto_my_coordinates
 *
 *      say: scotty lock 3 onto my coordinates      --- save set 3
 *		onsole: scotty_lock_onto_my_coordinates
 *
 *
 *  To go transport to those saved coordinates:
 *
 *      say: scotty energize                        --- go to set 1
 *		console: scotty_energize
 *
 *      say: scotty energize 2 now                  --- go to set 2
 *		console: scotty_energize_2_now
 *
 *      say: scotty energize 3 now                  --- go to set 3
 *		console: scotty_energize_3_now
 *
 *
 *
 * INSTALLATION:
 *  Download the extras package for "Beam Me Up Scotty" because they are
 *  not just extras, they are essentials. Part of the gameplay.
 *
 *  You can download it from my site: http://dekaftgent.be/css/BeamMeUpScotty
 *  or from the topic on sourcemod.com.
 *
 *  All the sound (.wav) files go into your ..cstrike\sounds\misc  folder.
 *  3 of the sounds (transporter_energize1.wav, transporter1_v1.wav,
 *  transporter2_v1.wav) are very important to gameplay.
 *  This way you can hear if someone is beaming in or out around you.
 *  You can auto download those remaining sounds to people using
 *  download plugins. I use my own all sound downloader.
 *  These sounds are also in the .zip file.
 *
 *******************************************************************************/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "2.4"

new Float:antifallvec[65][3];
new Float:WhereAmI[65][3];
new Float:WhereAmI2[65][3];
new Float:WhereAmI3[65][3];
new Float:Backup_WhereAmI[65][3];
new Float:LastBeamUpTime[65];
new isBeaming[65];

new round_start = 0;
new round_end;

new Handle:scotty_rebeamtime;
new Handle:scotty_spawntime;
new Handle:scotty_multibeam;
new Handle:scotty_online;
new Handle:scotty_vote;

// Sounds
new Handle:scotty_sounds_dl;

// Game
new String:game_dir[30];

new g_iVelocity = -1;

new StartTime;
new LastVote;
new Handle:VoteDelay;
new Handle:VotesInterval;


public Plugin:myinfo =
{
	name = "Beam Me Up Scotty",
	author = "V0gelz",
	description = "Scotty from Star Trek beams you around the map!",
	version = PLUGIN_VERSION,
	url = "http://www.dekaftgent.be/css"
};

public OnPluginStart()
{
	HookEvent("player_spawn",scotty_prespawn);
	HookEvent("round_start",RoundStart);
	HookEvent("round_end",RoundEnd);
	
	GetGameFolderName(game_dir, 29);

	g_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]");

	RegAdminCmd( "sm_scotty_on",	Command_Scotty_On,	ADMFLAG_CHEATS, "Turn the Star-Trek Transporter on." );
	RegAdminCmd( "sm_scotty_off",	Command_Scotty_Off,	ADMFLAG_CHEATS, "Turn the Star-Trek Transporter off." );

	RegAdminCmd( "sm_votescotty",	Scotty_Voting_Menu, ADMFLAG_VOTE, "Start a vote to enable/disable the scotty the transporter." );
	// 300 sec = 5 min
	VoteDelay= CreateConVar("sm_scotty_vote_delay","300.0", "Time before the scotty vote is allowed after map start. In seconds.");
	// 600 sec = 10 min
	VotesInterval = CreateConVar("sm_scotty_vote_interval", "600.0", "Interval between vote casts. In seconds.");

	RegConsoleCmd( "scotty_menu", Scotty_Menu);
	RegConsoleCmd( "scotty_where_am_i_scotty", Command_Where_Am_I_Scotty);

	RegConsoleCmd( "scotty_lock_onto_my_coordinates", Command_SLOMC);
	RegConsoleCmd( "scotty_lock_2_onto_my_coordinates", Command_SLOMC2);
	RegConsoleCmd( "scotty_lock_3_onto_my_coordinates", Command_SLOMC3);
	RegConsoleCmd( "scotty_energize", Command_Scotty_Energize);
	RegConsoleCmd( "scotty_energize_2_now", Command_Scotty_Energize2);
	RegConsoleCmd( "scotty_energize_3_now", Command_Scotty_Energize3);

	CreateConVar("sm_beammeup_version", PLUGIN_VERSION, "", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY);

	scotty_vote = CreateConVar("sm_scotty_vote","1", "StarTrek Transporter Voting on/off.", FCVAR_PLUGIN);
	scotty_online = CreateConVar("sm_startrek_transporter","1", "StarTrek Transporter on/off.", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY);
	scotty_multibeam = CreateConVar("sm_scotty_multibeam","0", "0 = Only 1 player can beam at a time. 1 = Everyone can beam at the same time.", FCVAR_PLUGIN);
	scotty_rebeamtime = CreateConVar("sm_scotty_rebeamtime","25", " How many seconds delay till next beam.", FCVAR_PLUGIN);
	scotty_spawntime = CreateConVar("sm_scotty_spawntimedelay","15", "How many seconds delay when spawn.", FCVAR_PLUGIN);

	// Sounds
	scotty_sounds_dl = CreateConVar("sm_scotty_sounds_dl","1", "Set how the sounds are beeing downloaded.", FCVAR_PLUGIN);

	//AutoExecConfig();

	RegConsoleCmd("say", Command_OnSay);
}

public OnMapStart()
{
	StartTime = GetTime();

	new maxplayers = GetMaxClients();
	for (new i=1; i<=maxplayers; i++) 
	{
 		LastBeamUpTime[i] = 0.0;
		WhereAmI[i][0] = 0;
		WhereAmI[i][1] = 0;
		WhereAmI[i][2] = 0;
		WhereAmI2[i][0] = 0;
		WhereAmI2[i][1] = 0;
		WhereAmI2[i][2] = 0;
		WhereAmI3[i][0] = 0;
		WhereAmI3[i][1] = 0;
		WhereAmI3[i][2] = 0;
	}
	PrecacheSound( "misc/transporter_lock.wav", true);
	PrecacheSound( "misc/transporter_lock2.wav", true);
	PrecacheSound( "misc/transporter_scottypower.wav", true);

	PrecacheSound( "misc/transporter_energize1.wav", true);
	PrecacheSound( "misc/transporter2_v1.wav", true);
	PrecacheSound( "misc/transporter1_v1.wav", true);

	PrecacheSound( "misc/transporter_molecules.wav", true);
	PrecacheSound( "misc/transporter_out1.wav", true);
	PrecacheSound( "misc/transporter_out2.wav", true);
	PrecacheSound( "misc/transporter_outagain.wav", true);
	PrecacheSound( "misc/tranpsorter_gamble.wav", true);
	PrecacheSound( "misc/transporter_scottybeammeup.wav", true);

	new Float:SCOTTY_SOUNDS_DL = GetConVarFloat(scotty_sounds_dl);
	if(SCOTTY_SOUNDS_DL == 0)
	{
		PrintToServer("<Scotty> Sounds will be downloaded true a third party plugin.");
	}
	if(SCOTTY_SOUNDS_DL == 1)
	{
		AddFileToDownloadsTable("sound/misc/transporter_energize1.wav");
		AddFileToDownloadsTable("sound/misc/transporter2_v1.wav");
		AddFileToDownloadsTable("sound/misc/transporter1_v1.wav");
		PrintToServer("<Scotty> Only the 3 necessary sounds will be downloaded.");
	}
	if(SCOTTY_SOUNDS_DL == 2)
	{
		AddFileToDownloadsTable("sound/misc/transporter_lock.wav");
		AddFileToDownloadsTable("sound/misc/transporter_lock2.wav");
		AddFileToDownloadsTable("sound/misc/transporter_scottypower.wav");
		AddFileToDownloadsTable("sound/misc/transporter_energize1.wav");
		AddFileToDownloadsTable("sound/misc/transporter2_v1.wav");
		AddFileToDownloadsTable("sound/misc/transporter1_v1.wav");
		AddFileToDownloadsTable("sound/misc/transporter_molecules.wav");
		AddFileToDownloadsTable("sound/misc/transporter_out1.wav");
		AddFileToDownloadsTable("sound/misc/transporter_out2.wav");
		AddFileToDownloadsTable("sound/misc/transporter_outagain.wav");
		AddFileToDownloadsTable("sound/misc/transporter_gamble.wav");
		AddFileToDownloadsTable("sound/misc/transporter_scottybeammeup.wav");
		PrintToServer("<Scotty> All the sounds that this plugin uses will be downloaded.");
	}
}

public scotty_prespawn(Handle:event,const String:name[],bool:dontBroadcast)
{
	if(StrEqual(game_dir,"tf") || StrEqual(game_dir,"hl2mp"))
	{
		if(round_start == 0)
		{
			round_start = 1;
			new Float:ROUND_START_TIME = GetConVarFloat(scotty_spawntime) + 5.0;
			CreateTimer(ROUND_START_TIME, roundstartover);
		}	
	}
	return Plugin_Handled;
}

public RoundStart(Handle:event,const String:name[],bool:dontBroadcast)
{
	round_end = 0;
	if(round_start == 0)
	{
		round_start = 1;
		new Float:ROUND_START_TIME = GetConVarFloat(scotty_spawntime) + 5.0;
		CreateTimer(ROUND_START_TIME, roundstartover);
	}
	return Plugin_Handled;
}


public RoundEnd(Handle: event , const String: name[] , bool: dontBroadcast)
{
	round_end = 1;

	return Plugin_Handled;
}

public Action:roundstartover(Handle:timer)
{
	round_start = 0;
}

public Action:Command_OnSay( client , args)
{
	decl String:text[192];
	GetCmdArgString(text, sizeof(text));
	
	new startidx;
	
	if (text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
	
	new Float:wxyz[3];
	GetClientAbsOrigin(client, wxyz);

	new User[32];
	GetClientName(client,User,31);

	new Float:SCOTTY_ONLINE = GetConVarFloat(scotty_online);

	if (strcmp(text[startidx], "scotty lock onto my coordinates", false) == 0)
	{
		ClientCommand(client, "scotty_lock_onto_my_coordinates");
		return Plugin_Handled;
	}
	if (strcmp(text[startidx], "scotty lock 2 onto my coordinates", false) == 0)
	{
		ClientCommand(client, "scotty_lock_2_onto_my_coordinates");
		return Plugin_Handled;
	}
	if (strcmp(text[startidx], "scotty lock 3 onto my coordinates", false) == 0)
	{
		ClientCommand(client, "scotty_lock_3_onto_my_coordinates");
		return Plugin_Handled;
	}
	if (strcmp(text[startidx], "scotty energize", false) == 0)
	{
		ClientCommand(client, "scotty_energize");
		return Plugin_Handled;
	}
	if (strcmp(text[startidx], "scotty energize 2 now", false) == 0)
	{
		ClientCommand(client, "scotty_energize_2_now");
		return Plugin_Handled;
	}
	if (strcmp(text[startidx], "scotty energize 3 now", false) == 0)
	{
		ClientCommand(client, "scotty_energize_3_now");
		return Plugin_Handled;
	}
	/******************************************************************************
	* 
	* This is just a easy way to get your coordinates in game,
	* but since i didn't yet added a function that teleports true xyz
	* this isn't realy needed.
	* 
	* If you don't want this just removed it or wait till an update of this plugin
	* on sourcemod.com.
	*	
	*******************************************************************************/

	if (strcmp(text[startidx], "scotty where am i", false) == 0)
	{
		if(SCOTTY_ONLINE==0.0)
		{
			new rand = GetRandomInt(0,1);
			switch(rand)
			{
				case 0: EmitSoundToClient(client, "misc/transporter_outagain.wav");
				case 1: EmitSoundToClient(client, "misc/transporter_out2.wav");
			}
			switch(rand)
			{
				case 0: PrintToChat( client , "<Scotty>  Transporter offline...     More info /scotty_help");
				case 1: PrintToChat( client , "<Scotty>  Transporter dead...     More info /scotty_help");
			}
		}
		if(SCOTTY_ONLINE==1.0)
		{
			PrintToChat(client, "<Scotty>  Correct usage is: where am i scotty  --  not: scotty where am i");
		
		}
		return Plugin_Handled;
	}
	
	if (strcmp(text[startidx], "where am i scotty", false) == 0)
	{
		ClientCommand(client, "scotty_where_am_i_scotty");
		return Plugin_Handled;
	}

	/******************************************************************************
	* 
	* Help functions for ingame players.
	*	
	*******************************************************************************/

	if (strcmp(text[startidx], "/scotty_help", false) == 0)
	{
		new temp1[1299];
		temp1 = "Say /scotty  -- shows a menu with options. - Say: vote_scotty  -- sets up a vote.";

		ShowMOTDPanel(client, "Star Trek style teleporting:", temp1, MOTDPANEL_TYPE_TEXT);
		PrintToChatAll("%s :   /scotty_help", User);
		return Plugin_Handled;
	}

	if (strcmp(text[startidx], "/scotty", false) == 0)
	{
		ClientCommand(client, "scotty_menu");
		PrintToChatAll("%s :   /scotty", User);
		return Plugin_Handled;
	}

	if (strcmp(text[startidx], "vote_scotty", false) == 0)
	{
		new Float:SCOTTY_VOTE = GetConVarFloat(scotty_vote);
		if(SCOTTY_VOTE == 1)
		{
			if (IsVoteInProgress())
			{
				PrintToChat( client ,"[SM]  Voting has allready started...");
				return Plugin_Handled;
			}

			new nFromStart = GetTime() - StartTime;
			new nFromLast = GetTime() - LastVote;	

			//new Float:SCOTTY_ONLINE = GetConVarFloat(scotty_online);

			if(nFromLast >= GetConVarInt(VotesInterval))
			{
				if(nFromStart >= GetConVarInt(VoteDelay))
				{
					if(SCOTTY_ONLINE == 1)
					{
						new Handle:menu = CreateMenu(Handle_Scotty_VoteMenu);
						SetMenuTitle(menu, "Scotty: Captain, disable the transporter?");
						AddMenuItem(menu, "yes", "Yes please");
						AddMenuItem(menu, "no", "No thanks");
						SetMenuExitButton(menu, false);
						VoteMenuToAll(menu, 20);
					}
					if(SCOTTY_ONLINE == 0)
					{
						new Handle:menu = CreateMenu(Handle_Scotty_VoteMenu);
						SetMenuTitle(menu, "Scotty: Captain, enable the transporter?");
						AddMenuItem(menu, "yes", "Beam me up Scotty!");
						AddMenuItem(menu, "no", "No thanks");
						SetMenuExitButton(menu, false);
						VoteMenuToAll(menu, 20);
					}
					LastVote = GetTime();
					//PrintToConsole( client ,"[SM]  ADMIN !!! Ignore the <Unknown command: sm_votescotty> -- its ok");
					PrintToChat( client ,"[SM]  Vote started...");
					PrintToChatAll("[SM]  The Scotty Teleporter vote has started!");

					PrintToChatAll("%s :   vote_scotty", User);
					EmitSoundToAll("misc/transporter_molecules.wav");
				}
				else
				{
					PrintToChat( client ,"[SM]  Voting not allowed yet.");
				}
			}
			else
			{
				PrintToChat( client ,"[SM]  Voting not allowed yet.");
			}
		}
		if(SCOTTY_VOTE == 0)
		{
			PrintToChat( client ,"[SM]  Sorry, 'vote_scotty' is disabled unless admin sets it otherwise");
		}
		PrintToChatAll("%s :   vote_scotty", User);
		return Plugin_Handled;
	}

	if ( (StrContains(text[startidx], "scotty") != -1) ||
	 (StrContains(text[startidx], "transp") != -1) ||
		 (StrContains(text[startidx], "beam") != -1) ||
		 (StrContains(text[startidx], "telep") != -1) ||
		 (StrContains(text[startidx], "energi") != -1) )
	{
		if(SCOTTY_ONLINE==1)
		{
			EmitSoundToClient(client, "misc/transporter_molecules.wav");
			PrintToChat( client , "<Scotty>  Transporter fully functional.   For help say:  /scotty_help");
			return Plugin_Continue;
		}
		else if(SCOTTY_ONLINE==0)
		{
			EmitSoundToClient(client, "misc/transporter_out1.wav");
			PrintToChat( client , "<Scotty>  Transporter dead.   For help say:  /scotty_help");
			return Plugin_Continue;
		}
	}

	return Plugin_Continue;
}

public Scotty_Menu_Handler(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		if (param2 == 0)
		{
			ClientCommand(param1, "scotty_energize");
		}
		if (param2 == 1)
		{
			ClientCommand(param1, "scotty_energize_2_now");
		}
		if (param2 == 2)
		{
			ClientCommand(param1, "scotty_energize_3_now");
		}
		if (param2 == 3)
		{
			ClientCommand(param1, "scotty_lock_onto_my_coordinates");
		}
		if (param2 == 4)
		{
			ClientCommand(param1, "scotty_lock_2_onto_my_coordinates");
		}
		if (param2 == 5)
		{
			ClientCommand(param1, "scotty_lock_3_onto_my_coordinates");
		}
		if (param2 == 6)
		{
			new temp1[1299];
			temp1 = "Say /scotty  -- shows a menu with options. - Say: vote_scotty  -- sets up a vote.";

			ShowMOTDPanel(param1, "Star Trek style teleporting:", temp1, MOTDPANEL_TYPE_TEXT);
		}
	}
	/* If the menu was cancelled, print a message to the server about it. */
	else if (action == MenuAction_Cancel)
	{
		//PrintToServer("Client %d's menu was cancelled.  Reason: %d", param1, param2);
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action:Scotty_Menu(client, args)
{
	new Handle:menu = CreateMenu(Scotty_Menu_Handler);
	SetMenuTitle(menu, "SCOTTY Teleport Menu");
	AddMenuItem(menu, "energize", "Scotty energize");
	AddMenuItem(menu, "energize2", "Scotty energize 2 now");
	AddMenuItem(menu, "energize3", "Scotty energize 3 now");
	AddMenuItem(menu, "lock", "Scotty lock onto my coordinates");
	AddMenuItem(menu, "lock2", "Scotty lock 2 onto my coordinates");
	AddMenuItem(menu, "lock3", "Scotty lock 3 onto my coordinates");
//	AddMenuItem(menu, "where", "Where am i scotty");
//	AddMenuItem(menu, "vote", "Vote Scotty");
	AddMenuItem(menu, "help", "Scotty info!");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 30);
 
	return Plugin_Handled;
}

public Action:Command_SLOMC( client, args )
{
	new Float:wxyz[3];
	GetClientAbsOrigin(client, wxyz);

	new User[32];
	GetClientName(client,User,31);

	new Float:SCOTTY_ONLINE = GetConVarFloat(scotty_online);

	if(SCOTTY_ONLINE==0.0)
	{
		new rand = GetRandomInt(0,1);
		switch(rand)
		{
			case 0: EmitSoundToClient(client, "misc/transporter_outagain.wav");
			case 1: EmitSoundToClient(client, "misc/transporter_out2.wav");
		}
		switch(rand)
		{
			case 0: PrintToChat( client , "<Mr. Spock>  The transporter is disabled captain.  Say: vote_scotty   More info /scotty_help");
			case 1: PrintToChat( client , "<Scotty>  Transporter dead...   Say: vote_scotty   More info /scotty_help");
		}
	}
	if(SCOTTY_ONLINE==1.0)
	{
		if (isBeaming[client] == 1)
		{
			PrintToChat(client,"<Scotty>  You are already in a beamup cycle captain!");
			EmitSoundToClient(client, "misc/transporter_scottypower.wav");
			return Plugin_Handled;
		}
		if(IsPlayerAlive( client ) == 0)
		{
			PrintToChat( client , "<Scotty>  Can't lock on your coordinates captain! You are dead!");
			return Plugin_Handled;
		}

		WhereAmI[client][0]=wxyz[0];
		WhereAmI[client][1]=wxyz[1];
		WhereAmI[client][2]=wxyz[2];

		PrintToChatAll("%s :   scotty lock onto my coordinates", User);
		PrintToChat(client, "<Scotty>  Set 1 Coordinates acknowledged captain.");
		PrintToServer("[SM][Transporter] Set 1 Coordinates locked for %s, Client ID: %d", User, client);

		new rand = GetRandomInt(0,1);
		switch(rand)
		{
			case 0: EmitSoundFromOrigin("misc/transporter_lock.wav",wxyz);
			case 1: EmitSoundFromOrigin("misc/transporter_lock2.wav",wxyz);
		}
	}
	return Plugin_Handled;
}

public Action:Command_SLOMC2( client, args )
{
	new Float:wxyz[3];
	GetClientAbsOrigin(client, wxyz);

	new User[32];
	GetClientName(client,User,31);

	new Float:SCOTTY_ONLINE = GetConVarFloat(scotty_online);

	if(SCOTTY_ONLINE==0.0)
	{
		new rand = GetRandomInt(0,1);
		switch(rand)
		{
			case 0: EmitSoundToClient(client, "misc/transporter_outagain.wav");
			case 1: EmitSoundToClient(client, "misc/transporter_out2.wav");
		}
		switch(rand)
		{
			case 0: PrintToChat( client , "<Mr. Spock>  The transporter is disabled captain.  Say: vote_scotty   More info /scotty_help");
			case 1: PrintToChat( client , "<Scotty>  Transporter dead...   Say: vote_scotty   More info /scotty_help");
		}
	}
	if(SCOTTY_ONLINE==1.0)
	{
		if (isBeaming[client] == 1)
		{
			PrintToChat(client,"<Scotty>  You are already in a beamup cycle captain!");
			EmitSoundToClient(client, "misc/transporter_scottypower.wav");
			return Plugin_Handled;
		}
		if(IsPlayerAlive( client ) == 0)
		{
			PrintToChat( client , "<Scotty>  Can't lock on your coordinates captain! You are dead!");
			return Plugin_Handled;
		}

		WhereAmI2[client][0]=wxyz[0];
		WhereAmI2[client][1]=wxyz[1];
		WhereAmI2[client][2]=wxyz[2];

		PrintToChatAll("%s :   scotty lock 2 onto my coordinates", User);
		PrintToChat(client, "<Scotty>  Set 2 Coordinates acknowledged captain.");
		PrintToServer("[SM][Transporter] Set 2 Coordinates locked for %s, Client ID: %d", User, client);

		new rand = GetRandomInt(0,1);
		switch(rand)
		{
			case 0: EmitSoundFromOrigin("misc/transporter_lock.wav",wxyz);
			case 1: EmitSoundFromOrigin("misc/transporter_lock2.wav",wxyz);
		}
	}
	return Plugin_Handled;
}

public Action:Command_SLOMC3( client, args )
{
	new Float:wxyz[3];
	GetClientAbsOrigin(client, wxyz);

	new User[32];
	GetClientName(client,User,31);

	new Float:SCOTTY_ONLINE = GetConVarFloat(scotty_online);

	if(SCOTTY_ONLINE==0.0)
	{
		new rand = GetRandomInt(0,1);
		switch(rand)
		{
			case 0: EmitSoundToClient(client, "misc/transporter_outagain.wav");
			case 1: EmitSoundToClient(client, "misc/transporter_out2.wav");
		}
		switch(rand)
		{
			case 0: PrintToChat( client , "<Mr. Spock>  The transporter is disabled captain.  Say: vote_scotty   More info /scotty_help");
			case 1: PrintToChat( client , "<Scotty>  Transporter dead...   Say: vote_scotty   More info /scotty_help");
		}
	}
	if(SCOTTY_ONLINE==1.0)
	{
		if (isBeaming[client] == 1)
		{
			PrintToChat(client,"<Scotty>  You are already in a beamup cycle captain!");
			EmitSoundToClient(client, "misc/transporter_scottypower.wav");
			return Plugin_Handled;
		}
		if(IsPlayerAlive( client ) == 0)
		{
			PrintToChat( client , "<Scotty>  Can't lock on your coordinates captain! You are dead!");
			return Plugin_Handled;
		}

		WhereAmI3[client][0]=wxyz[0];
		WhereAmI3[client][1]=wxyz[1];
		WhereAmI3[client][2]=wxyz[2];

		PrintToChatAll("%s :   scotty lock 3 onto my coordinates", User);
		PrintToChat(client, "<Scotty>  Set 3 Coordinates acknowledged captain.");
		PrintToServer("[SM][Transporter] Set 3 Coordinates locked for %s, Client ID: %d", User, client);

		new rand = GetRandomInt(0,1);
		switch(rand)
		{
			case 0: EmitSoundFromOrigin("misc/transporter_lock.wav",wxyz);
			case 1: EmitSoundFromOrigin("misc/transporter_lock2.wav",wxyz);
		}
	}
	return Plugin_Handled;
}

public Action:Command_Scotty_Energize( client, args )
{
	new Float:wxyz[3];
	GetClientAbsOrigin(client, wxyz);

	new User[32];
	GetClientName(client,User,31);

	new Float:SCOTTY_ONLINE = GetConVarFloat(scotty_online);
	new Float:MULTIBEAM = GetConVarFloat(scotty_multibeam);
	new deny;

	if(SCOTTY_ONLINE==0.0)
	{
		new rand = GetRandomInt(0,1);
		switch(rand)
		{
			case 0: EmitSoundToClient(client, "misc/transporter_outagain.wav");
			case 1: EmitSoundToClient(client, "misc/transporter_out2.wav");
		}
		switch(rand)
		{
			case 0: PrintToChat( client , "<Mr. Spock>  The transporter is disabled captain.  Say: vote_scotty   More info /scotty_help");
			case 1: PrintToChat( client , "<Scotty>  Transporter dead...   Say: vote_scotty   More info /scotty_help");
		}
	}
	if(SCOTTY_ONLINE==1.0)
	{
		if (isBeaming[client] == 1)
		{
			PrintToChat(client,"<Scotty>  You are already in a beamup cycle captain!");
			EmitSoundToClient(client, "misc/transporter_scottypower.wav");
			return Plugin_Handled;
		}
		if(round_start == 1)
		{
			PrintToChat(client, "<Scotty>  It will be a little longer captain, the warp drive is malfunctioning.");
			return Plugin_Handled;
		}

		if(IsPlayerAlive( client ) == 0)
		{
			PrintToChat(client, "<Scotty>  You are dead, why should I transport you?");
			EmitSoundToClient(client, "misc/transporter_scottypower.wav");
			return Plugin_Handled;
		}
		else
		{
			if(MULTIBEAM == 0){
				new maxplayers = GetMaxClients()+1;
				for (new i=1; i<=maxplayers; i++){				
					if(IsPlayerAlive( client )){			
						if(isBeaming[i] == 1){
							deny = 1;
						}			
					}
				}
			}

		}
		if(deny)
		{
			EmitSoundToClient(client, "misc/transporter_scottypower.wav");
			PrintToChat(client, "<Scotty>  She cant handle more than one at a time captain!");
			return Plugin_Handled;
		}
		if(round_end == 1)
		{
			PrintToChat(client, "<Scotty>  The ship's scanners are not picking you up, captain.");
			return Plugin_Handled;
		}
		new Float:TRANSPORTER_DELAY_L = GetConVarFloat(scotty_rebeamtime);
		if (GetGameTime() - TRANSPORTER_DELAY_L < (LastBeamUpTime[client]) )
		{
			PrintToChat(client, "<Scotty>  Give someone else a chance, captain.");
			EmitSoundToClient(client, "misc/tranpsorter_gamble.wav");
			return Plugin_Handled;
		}
		if(WhereAmI[client][0] == 0.0 && WhereAmI[client][1] == 0.0)
		{
			PrintToChat(client, "<Scotty>  No coordinates found in this player's lock coordinant set.");
			return Plugin_Handled;
		}

		new rand = GetRandomInt(0,1);
		switch(rand)
		{
			case 0: EmitSoundFromOrigin( "misc/transporter_energize1.wav",wxyz);
			case 1: EmitSoundFromOrigin( "misc/transporter1_v1.wav",wxyz);
		}
		switch(rand)
		{
			case 0: EmitSoundToClient(client, "misc/transporter_energize1.wav");
			case 1: EmitSoundToClient(client, "misc/transporter1_v1.wav");
		}
		
		PrintToChatAll("%s :   scotty energize", User);
		PrintToChat(client, "<Scotty>  Energize!");
		PrintToServer("[SM][Transporter] Energize Begon for %s, Client ID: %d", User, client);

		SetEntityRenderMode(client, 19);
		SetEntityRenderColor(client, 0, 0, 255, 100);
		SetEntityRenderFx(client, 5);
		
		// I know this is a crapy way but it works and looks good in game :)

		if(IsClientConnected(client) == 1 && IsClientInGame(client) == 1 )
		{
		CreateTimer(0.1, energize_step01, client);

		CreateTimer(2.0, energize_step1, client);
		CreateTimer(2.1, energize_step2_01, client);
		CreateTimer(2.2, energize_step2_01, client);
		CreateTimer(2.3, energize_step2_01, client);
		CreateTimer(2.4, energize_step2_01, client);
		CreateTimer(2.5, energize_step2_01, client);
		CreateTimer(2.6, energize_step2_01, client);
		CreateTimer(2.7, energize_step2_01, client);
		CreateTimer(2.8, energize_step2_01, client);
		CreateTimer(2.9, energize_step2_01, client);
		CreateTimer(3.0, energize_step2_01, client);

		CreateTimer(3.1, energize_step2_01, client);
		CreateTimer(3.2, energize_step2_01, client);
		CreateTimer(3.3, energize_step2_01, client);
		CreateTimer(3.4, energize_step2_01, client);
		CreateTimer(3.5, energize_step2_01, client);
		CreateTimer(3.6, energize_step2_01, client);
		CreateTimer(3.7, energize_step2_01, client);
		CreateTimer(3.8, energize_step2_01, client);
		CreateTimer(3.9, energize_step2_01, client);

		CreateTimer(4.0, energize_step2_01, client);
		CreateTimer(4.1, energize_step2_01, client);
		CreateTimer(4.2, energize_step2_01, client);
		CreateTimer(4.3, energize_step2_01, client);
		CreateTimer(4.4, energize_step2_01, client);
		CreateTimer(4.5, energize_step2_01, client);
		CreateTimer(4.6, energize_step2_01, client);
		CreateTimer(4.7, energize_step2_01, client);
		CreateTimer(4.8, energize_step2_01, client);
		CreateTimer(4.9, energize_step2_01, client);
		CreateTimer(5.0, energize_step2_01, client);

		CreateTimer(5.1, energize_step3_01, client);
		
		CreateTimer(5.2, energize_step4, client);
		CreateTimer(5.3, energize_step4, client);
		CreateTimer(5.4, energize_step4, client);
		CreateTimer(5.5, energize_step4, client);
		CreateTimer(5.6, energize_step4, client);
		CreateTimer(5.7, energize_step4, client);
		CreateTimer(5.8, energize_step4, client);
		CreateTimer(5.9, energize_step4, client);
		CreateTimer(6.0, energize_step4, client);
		CreateTimer(6.1, energize_step4, client);
		CreateTimer(6.2, energize_step4, client);
		CreateTimer(6.3, energize_step4, client);
		CreateTimer(6.4, energize_step4, client);
		CreateTimer(6.5, energize_step4, client);
		CreateTimer(6.6, energize_step4, client);
		CreateTimer(6.7, energize_step4, client);
		CreateTimer(6.8, energize_step4, client);
		CreateTimer(6.9, energize_step4, client);
		CreateTimer(7.1, energize_step4, client);
		CreateTimer(7.2, energize_step4, client);
		CreateTimer(7.3, energize_step4, client);
		CreateTimer(7.4, energize_step4, client);

		CreateTimer(7.5, energize_step5, client);

		LastBeamUpTime[client] = GetGameTime();
		}
	}
	return Plugin_Handled;
}

public Action:Command_Scotty_Energize2( client, args )
{
	new Float:wxyz[3];
	GetClientAbsOrigin(client, wxyz);

	new User[32];
	GetClientName(client,User,31);

	new Float:SCOTTY_ONLINE = GetConVarFloat(scotty_online);
	new Float:MULTIBEAM = GetConVarFloat(scotty_multibeam);
	new deny;

	if(SCOTTY_ONLINE==0.0)
	{
		new rand = GetRandomInt(0,1);
		switch(rand)
		{
			case 0: EmitSoundToClient(client, "misc/transporter_outagain.wav");
			case 1: EmitSoundToClient(client, "misc/transporter_out2.wav");
		}
		switch(rand)
		{
			case 0: PrintToChat( client , "<Mr. Spock>  The transporter is disabled captain.  Say: vote_scotty   More info /scotty_help");
			case 1: PrintToChat( client , "<Scotty>  Transporter dead...   Say: vote_scotty   More info /scotty_help");
		}
	}
	if(SCOTTY_ONLINE==1.0)
	{
		if (isBeaming[client] == 1)
		{
			PrintToChat(client,"<Scotty>  You are already in a beamup cycle captain!");
			EmitSoundToClient(client, "misc/transporter_scottypower.wav");
			return Plugin_Handled;
		}
		if(round_start == 1)
		{
			PrintToChat(client, "<Scotty>  It will be a little longer captain, the warp drive is malfunctioning.");
			return Plugin_Handled;
		}

		if(IsPlayerAlive( client ) == 0)
		{
			PrintToChat(client, "<Scotty>  You are dead, why should I transport you?");
			EmitSoundToClient(client, "misc/transporter_scottypower.wav");
			return Plugin_Handled;
		}
		else
		{
			if(MULTIBEAM == 0){
				new maxplayers = GetMaxClients()+1;
				for (new i=1; i<=maxplayers; i++){				
					if(IsPlayerAlive( client )){			
						if(isBeaming[i] == 1){
							deny = 1;
						}			
					}
				}
			}

		}
		if(deny)
		{
			EmitSoundToClient(client, "misc/transporter_scottypower.wav");
			PrintToChat(client, "<Scotty>  She cant handle more than one at a time captain!");
			return Plugin_Handled;
		}
		if(round_end == 1)
		{
			PrintToChat(client, "<Scotty>  The ship's scanners are not picking you up, captain.");
			return Plugin_Handled;
		}
		new Float:TRANSPORTER_DELAY_L = GetConVarFloat(scotty_rebeamtime);
		if (GetGameTime() - TRANSPORTER_DELAY_L < (LastBeamUpTime[client]) )
		{
			PrintToChat(client, "<Scotty>  Give someone else a chance, captain.");
			EmitSoundToClient(client, "misc/tranpsorter_gamble.wav");
			return Plugin_Handled;
		}
		if(WhereAmI2[client][0] == 0.0 && WhereAmI2[client][1] == 0.0)
		{
			PrintToChat(client, "<Scotty>  No coordinates found in this player's lock 2 coordinant set.");
			return Plugin_Handled;
		}

		new rand = GetRandomInt(0,1);
		switch(rand)
		{
			case 0: EmitSoundFromOrigin( "misc/transporter_energize1.wav",wxyz);
			case 1: EmitSoundFromOrigin( "misc/transporter1_v1.wav",wxyz);
		}
		switch(rand)
		{
			case 0: EmitSoundToClient(client, "misc/transporter_energize1.wav");
			case 1: EmitSoundToClient(client, "misc/transporter1_v1.wav");
		}
		
		PrintToChatAll("%s :   scotty energize 2 now", User);
		PrintToChat(client, "<Scotty>  Energize 2 now!");
		PrintToServer("[SM][Transporter] Energize 2 Begon for %s, Client ID: %d", User, client);

		SetEntityRenderMode(client, 19);
		SetEntityRenderColor(client, 0, 0, 255, 100);
		SetEntityRenderFx(client, 5);
		
		// I know this is a crapy way but it works and looks good in game :)
		if(IsClientConnected(client) == 1 && IsClientInGame(client) == 1 )
		{
		CreateTimer(0.1, energize_step01, client);

		CreateTimer(2.0, energize_step1, client);
		CreateTimer(2.1, energize_step2_02, client);
		CreateTimer(2.2, energize_step2_02, client);
		CreateTimer(2.3, energize_step2_02, client);
		CreateTimer(2.4, energize_step2_02, client);
		CreateTimer(2.5, energize_step2_02, client);
		CreateTimer(2.6, energize_step2_02, client);
		CreateTimer(2.7, energize_step2_02, client);
		CreateTimer(2.8, energize_step2_02, client);
		CreateTimer(2.9, energize_step2_02, client);
		CreateTimer(3.0, energize_step2_02, client);

		CreateTimer(3.1, energize_step2_02, client);
		CreateTimer(3.2, energize_step2_02, client);
		CreateTimer(3.3, energize_step2_02, client);
		CreateTimer(3.4, energize_step2_02, client);
		CreateTimer(3.5, energize_step2_02, client);
		CreateTimer(3.6, energize_step2_02, client);
		CreateTimer(3.7, energize_step2_02, client);
		CreateTimer(3.8, energize_step2_02, client);
		CreateTimer(3.9, energize_step2_02, client);

		CreateTimer(4.0, energize_step2_02, client);
		CreateTimer(4.1, energize_step2_02, client);
		CreateTimer(4.2, energize_step2_02, client);
		CreateTimer(4.3, energize_step2_02, client);
		CreateTimer(4.4, energize_step2_02, client);
		CreateTimer(4.5, energize_step2_02, client);
		CreateTimer(4.6, energize_step2_02, client);
		CreateTimer(4.7, energize_step2_02, client);
		CreateTimer(4.8, energize_step2_02, client);
		CreateTimer(4.9, energize_step2_02, client);
		CreateTimer(5.0, energize_step2_02, client);

		CreateTimer(5.1, energize_step3_02, client);
		
		CreateTimer(5.2, energize_step4, client);
		CreateTimer(5.3, energize_step4, client);
		CreateTimer(5.4, energize_step4, client);
		CreateTimer(5.5, energize_step4, client);
		CreateTimer(5.6, energize_step4, client);
		CreateTimer(5.7, energize_step4, client);
		CreateTimer(5.8, energize_step4, client);
		CreateTimer(5.9, energize_step4, client);
		CreateTimer(6.0, energize_step4, client);
		CreateTimer(6.1, energize_step4, client);
		CreateTimer(6.2, energize_step4, client);
		CreateTimer(6.3, energize_step4, client);
		CreateTimer(6.4, energize_step4, client);
		CreateTimer(6.5, energize_step4, client);
		CreateTimer(6.6, energize_step4, client);
		CreateTimer(6.7, energize_step4, client);
		CreateTimer(6.8, energize_step4, client);
		CreateTimer(6.9, energize_step4, client);
		CreateTimer(7.1, energize_step4, client);
		CreateTimer(7.2, energize_step4, client);
		CreateTimer(7.3, energize_step4, client);
		CreateTimer(7.4, energize_step4, client);

		CreateTimer(7.5, energize_step5, client);

		LastBeamUpTime[client] = GetGameTime();
		}
	}
	return Plugin_Handled;
}

public Action:Command_Scotty_Energize3( client, args )
{
	new Float:wxyz[3];
	GetClientAbsOrigin(client, wxyz);

	new User[32];
	GetClientName(client,User,31);

	new Float:SCOTTY_ONLINE = GetConVarFloat(scotty_online);
	new Float:MULTIBEAM = GetConVarFloat(scotty_multibeam);
	new deny;

	if(SCOTTY_ONLINE==0.0)
	{
		new rand = GetRandomInt(0,1);
		switch(rand)
		{
			case 0: EmitSoundToClient(client, "misc/transporter_outagain.wav");
			case 1: EmitSoundToClient(client, "misc/transporter_out2.wav");
		}
		switch(rand)
		{
			case 0: PrintToChat( client , "<Mr. Spock>  The transporter is disabled captain.  Say: vote_scotty   More info /scotty_help");
			case 1: PrintToChat( client , "<Scotty>  Transporter dead...   Say: vote_scotty   More info /scotty_help");
		}
	}
	if(SCOTTY_ONLINE==1.0)
	{
		if (isBeaming[client] == 1)
		{
			PrintToChat(client,"<Scotty>  You are already in a beamup cycle captain!");
			EmitSoundToClient(client, "misc/transporter_scottypower.wav");
			return Plugin_Handled;
		}
		if(round_start == 1)
		{
			PrintToChat(client, "<Scotty>  It will be a little longer captain, the warp drive is malfunctioning.");
			return Plugin_Handled;
		}

		if(IsPlayerAlive( client ) == 0)
		{
			PrintToChat(client, "<Scotty>  You are dead, why should I transport you?");
			EmitSoundToClient(client, "misc/transporter_scottypower.wav");
			return Plugin_Handled;
		}
		else
		{
			if(MULTIBEAM == 0){
				new maxplayers = GetMaxClients()+1;
				for (new i=1; i<=maxplayers; i++){				
					if(IsPlayerAlive( client )){			
						if(isBeaming[i] == 1){
							deny = 1;
						}			
					}
				}
			}

		}
		if(deny)
		{
			EmitSoundToClient(client, "misc/transporter_scottypower.wav");
			PrintToChat(client, "<Scotty>  She cant handle more than one at a time captain!");
			return Plugin_Handled;
		}
		if(round_end == 1)
		{
			PrintToChat(client, "<Scotty>  The ship's scanners are not picking you up, captain.");
			return Plugin_Handled;
		}
		new Float:TRANSPORTER_DELAY_L = GetConVarFloat(scotty_rebeamtime);
		if (GetGameTime() - TRANSPORTER_DELAY_L < (LastBeamUpTime[client]) )
		{
			PrintToChat(client, "<Scotty>  Give someone else a chance, captain.");
			EmitSoundToClient(client, "misc/tranpsorter_gamble.wav");
			return Plugin_Handled;
		}
		if(WhereAmI3[client][0] == 0.0 && WhereAmI3[client][1] == 0.0)
		{
			PrintToChat(client, "<Scotty>  No coordinates found in this player's lock 3 coordinant set.");
			return Plugin_Handled;
		}

		new rand = GetRandomInt(0,1);
		switch(rand)
		{
			case 0: EmitSoundFromOrigin( "misc/transporter_energize1.wav",wxyz);
			case 1: EmitSoundFromOrigin( "misc/transporter1_v1.wav",wxyz);
		}
		switch(rand)
		{
			case 0: EmitSoundToClient(client, "misc/transporter_energize1.wav");
			case 1: EmitSoundToClient(client, "misc/transporter1_v1.wav");
		}
		
		PrintToChatAll("%s :   scotty energize 3 now", User);
		PrintToChat(client, "<Scotty>  Energize 3 now!");
		PrintToServer("[SM][Transporter] Energize 3 Begon for %s, Client ID: %d", User, client);

		SetEntityRenderMode(client, 19);
		SetEntityRenderColor(client, 0, 0, 255, 100);
		SetEntityRenderFx(client, 5);
		
		// I know this is a crapy way but it works and looks good in game :)

		if(IsClientConnected(client) == 1 && IsClientInGame(client) == 1 )
		{
		CreateTimer(0.1, energize_step01, client);

		CreateTimer(2.0, energize_step1, client);
		CreateTimer(2.1, energize_step2_03, client);
		CreateTimer(2.2, energize_step2_03, client);
		CreateTimer(2.3, energize_step2_03, client);
		CreateTimer(2.4, energize_step2_03, client);
		CreateTimer(2.5, energize_step2_03, client);
		CreateTimer(2.6, energize_step2_03, client);
		CreateTimer(2.7, energize_step2_03, client);
		CreateTimer(2.8, energize_step2_03, client);
		CreateTimer(2.9, energize_step2_03, client);
		CreateTimer(3.0, energize_step2_03, client);

		CreateTimer(3.1, energize_step2_03, client);
		CreateTimer(3.2, energize_step2_03, client);
		CreateTimer(3.3, energize_step2_03, client);
		CreateTimer(3.4, energize_step2_03, client);
		CreateTimer(3.5, energize_step2_03, client);
		CreateTimer(3.6, energize_step2_03, client);
		CreateTimer(3.7, energize_step2_03, client);
		CreateTimer(3.8, energize_step2_03, client);
		CreateTimer(3.9, energize_step2_03, client);

		CreateTimer(4.0, energize_step2_03, client);
		CreateTimer(4.1, energize_step2_03, client);
		CreateTimer(4.2, energize_step2_03, client);
		CreateTimer(4.3, energize_step2_03, client);
		CreateTimer(4.4, energize_step2_03, client);
		CreateTimer(4.5, energize_step2_03, client);
		CreateTimer(4.6, energize_step2_03, client);
		CreateTimer(4.7, energize_step2_03, client);
		CreateTimer(4.8, energize_step2_03, client);
		CreateTimer(4.9, energize_step2_03, client);
		CreateTimer(5.0, energize_step2_03, client);

		CreateTimer(5.1, energize_step3_03, client);
		
		CreateTimer(5.2, energize_step4, client);
		CreateTimer(5.3, energize_step4, client);
		CreateTimer(5.4, energize_step4, client);
		CreateTimer(5.5, energize_step4, client);
		CreateTimer(5.6, energize_step4, client);
		CreateTimer(5.7, energize_step4, client);
		CreateTimer(5.8, energize_step4, client);
		CreateTimer(5.9, energize_step4, client);
		CreateTimer(6.0, energize_step4, client);
		CreateTimer(6.1, energize_step4, client);
		CreateTimer(6.2, energize_step4, client);
		CreateTimer(6.3, energize_step4, client);
		CreateTimer(6.4, energize_step4, client);
		CreateTimer(6.5, energize_step4, client);
		CreateTimer(6.6, energize_step4, client);
		CreateTimer(6.7, energize_step4, client);
		CreateTimer(6.8, energize_step4, client);
		CreateTimer(6.9, energize_step4, client);
		CreateTimer(7.1, energize_step4, client);
		CreateTimer(7.2, energize_step4, client);
		CreateTimer(7.3, energize_step4, client);
		CreateTimer(7.4, energize_step4, client);

		CreateTimer(7.5, energize_step5, client);

		LastBeamUpTime[client] = GetGameTime();
		}
	}
	return Plugin_Handled;
}

public Action:Command_Where_Am_I_Scotty( client, args )
{
	new Float:wxyz[3];
	GetClientAbsOrigin(client, wxyz);

	new User[32];
	GetClientName(client,User,31);

	new Float:SCOTTY_ONLINE = GetConVarFloat(scotty_online);
	if(SCOTTY_ONLINE==0.0)
	{
		new rand = GetRandomInt(0,1);
		switch(rand)
		{
			case 0: EmitSoundToClient(client, "misc/transporter_outagain.wav");
			case 1: EmitSoundToClient(client, "misc/transporter_out2.wav");
		}
		switch(rand)
		{
			case 0: PrintToChat( client , "<Mr. Spock>  The transporter is disabled captain.  Say: vote_scotty   More info /scotty_help");
			case 1: PrintToChat( client , "<Scotty>  Transporter dead...   Say: vote_scotty   More info /scotty_help");
		}
	}
	if(SCOTTY_ONLINE==1.0)
	{
		PrintToChatAll("%s :   where am i scotty", User);
		PrintToChat(client, "<Scotty>  Captain, you are at coordinates %d %d %d", wxyz[0], wxyz[1], wxyz[2]);
		PrintToServer("[SM][Transporter] Person: %s, Client ID: %d has asked for his coordinates.", User, client);
	
		new rand = GetRandomInt(0,1);
		switch(rand)
		{
			case 0: EmitSoundFromOrigin("misc/transporter_lock.wav",wxyz);
			case 1: EmitSoundFromOrigin("misc/transporter_lock2.wav",wxyz);
		}
	}
	return Plugin_Handled;
}

public Action:energize_step01(Handle:timer, any:client)
{
	isBeaming[client] = 1;

	new Float:wxyz[3];
	GetClientAbsOrigin(client, wxyz);

	//SetEntityGravity(client, 0.001);

	Backup_WhereAmI[client][0]=wxyz[0];
	Backup_WhereAmI[client][1]=wxyz[1];
	Backup_WhereAmI[client][2]=wxyz[2];
}

public Action:energize_step1(Handle:timer, any:client)
{
	new Float:wxyz[3];
	GetClientAbsOrigin(client, wxyz);

	wxyz[2] += 3700.0;

	antifallvec[client][0]=wxyz[0];
	antifallvec[client][1]=wxyz[1];
	antifallvec[client][2]=wxyz[2];

	ClientCommand(client, "r_screenoverlay effects/tp_eyefx/tpeye3.vmt");

	TeleportEntity( client, wxyz, NULL_VECTOR, NULL_VECTOR );

	new Float:velocity[3];
	if (g_iVelocity == -1) return;
		if(velocity[2] < 0.0)
		{
			velocity[2] = 99;
			SetEntDataVector(client, g_iVelocity, velocity);
			PrintToChat(client, "velocity set");
			SetEntityGravity(client,0.1);
		}
}

public Action:energize_step2_01(Handle:timer, any:client)
{
	new Float:wxyz[3];
	GetClientAbsOrigin(client, wxyz);

	new test[3]={0,0,0};
	TE_SetupSparks(WhereAmI[client],test,255,2);
	TE_SendToAll();

	TeleportEntity( client, antifallvec[client], NULL_VECTOR, NULL_VECTOR );
	new Float:velocity[3];
	velocity[2] = 99;
	SetEntDataVector(client, g_iVelocity, velocity);
	SetEntityGravity(client,0.1);
}

public Action:energize_step2_02(Handle:timer, any:client)
{
	new Float:wxyz[3];
	GetClientAbsOrigin(client, wxyz);

	new test[3]={0,0,0};
	TE_SetupSparks(WhereAmI2[client],test,255,2);
	TE_SendToAll();

	TeleportEntity( client, antifallvec[client], NULL_VECTOR, NULL_VECTOR );
	new Float:velocity[3];
	velocity[2] = 99;
	SetEntDataVector(client, g_iVelocity, velocity);
	SetEntityGravity(client,0.1);
}

public Action:energize_step2_03(Handle:timer, any:client)
{
	new Float:wxyz[3];
	GetClientAbsOrigin(client, wxyz);

	new test[3]={0,0,0};
	TE_SetupSparks(WhereAmI3[client],test,255,2);
	TE_SendToAll();

	TeleportEntity( client, antifallvec[client], NULL_VECTOR, NULL_VECTOR );
	new Float:velocity[3];
	SetEntDataVector(client, g_iVelocity, velocity);
	SetEntityGravity(client,0.1);
}

public Action:energize_step3_01(Handle:timer, any:client)
{
	new Float:wxyz[3];
	GetClientAbsOrigin(client, wxyz);

	new User[32];
	GetClientName(client,User,31);

	SetEntityGravity(client, 1.0);

	TeleportEntity( client, WhereAmI[client], NULL_VECTOR, NULL_VECTOR );

	isBeaming[client] = 0;

	EmitSoundToClient(client, "misc/transporter2_v1.wav");
	EmitSoundFromOrigin("misc/transporter2_v1.wav",wxyz);

	ClientCommand(client, "r_screenoverlay 0");
	SetEntityRenderColor(client, 0, 0, 100, 150);
	SetEntityRenderMode(client, 19);
	SetEntityRenderFx(client, 7);

	PrintToServer("[SM][Transporter] Energize succesfull for %s, Client ID: %d", User, client);
}

public Action:energize_step3_02(Handle:timer, any:client)
{
	new Float:wxyz[3];
	GetClientAbsOrigin(client, wxyz);
	new User[32];
	GetClientName(client,User,31);

	SetEntityGravity(client, 1.0);

	TeleportEntity( client, WhereAmI2[client], NULL_VECTOR, NULL_VECTOR );

	isBeaming[client] = 0;

	EmitSoundToClient(client, "misc/transporter2_v1.wav");
	EmitSoundFromOrigin("misc/transporter2_v1.wav",wxyz);

	ClientCommand(client, "r_screenoverlay 0");
	SetEntityRenderColor(client, 0, 0, 100, 150);
	SetEntityRenderMode(client, 19);
	SetEntityRenderFx(client, 7);

	PrintToServer("[SM][Transporter] Energize succesfull for %s, Client ID: %d", User, client);
}

public Action:energize_step3_03(Handle:timer, any:client)
{
	new Float:wxyz[3];
	GetClientAbsOrigin(client, wxyz);
	new User[32];
	GetClientName(client,User,31);

	SetEntityGravity(client, 1.0);

	TeleportEntity( client, WhereAmI3[client], NULL_VECTOR, NULL_VECTOR );

	isBeaming[client] = 0;

	EmitSoundToClient(client, "misc/transporter2_v1.wav");
	EmitSoundFromOrigin("misc/transporter2_v1.wav",wxyz);

	ClientCommand(client, "r_screenoverlay 0");
	SetEntityRenderColor(client, 0, 0, 100, 150);
	SetEntityRenderMode(client, 19);
	SetEntityRenderFx(client, 7);

	PrintToServer("[SM][Transporter] Energize succesfull for %s, Client ID: %d", User, client);
}

public Action:energize_step4(Handle:timer, any:client)
{
	new Float:wxyz[3];
	GetClientAbsOrigin(client, wxyz);

	new test[3]={0,0,0};
	TE_SetupSparks(wxyz,test,255,2);
	TE_SendToAll();
}

public Action:energize_step5(Handle:timer, any:client)
{
	new Float:wxyz[3];
	GetClientAbsOrigin(client, wxyz);

	SetEntityRenderColor(client, 255, 255, 255, 255);
	SetEntityRenderMode(client, 0);
	SetEntityRenderFx(client, 0);
}

public OnClientPostAdminCheck(client)
{
	if (client >= 1 && client <= 65)
	{
		for (new i=0; i<=7; i++)
		{		
			//WhereAmI[client][i] = 0;
		}
		LastBeamUpTime[client] = -900.0;
	}

}

public OnClientDisconnect(client)
{
	LastBeamUpTime[client] = -900.0;
	isBeaming[client] = 0;
}

// Help
public EmitSoundFromOrigin(const String:sound[],const Float:orig[3])
{
  EmitSoundToAll(sound,SOUND_FROM_WORLD,SNDCHAN_AUTO,SNDLEVEL_NORMAL,SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,orig,NULL_VECTOR,true,0.0);
}

public Action:Command_Scotty_On( client, args )
{
	new User[32];
	GetClientName(client,User,31);

	ServerCommand( "sm_startrek_transporter 1" );
	EmitSoundToAll("misc/transporter_molecules.wav");

	PrintCenterTextAll("Scotty: Captain, the tranporter is working again!");
	PrintHintTextToAll("Scotty: Captain, the tranporter is working again!");
	PrintToChatAll("Scotty: Captain, the tranporter is working again!");
	PrintToServer("[SM] Scotty's teleporter set to: 1  by %s", User);
	PrintToChatAll("ADMIN %s: Executed sm_scotty_on", User);

	return Plugin_Handled;
}

public Action:Command_Scotty_Off( client, args )
{
	new User[32];
	GetClientName(client,User,31);

	ServerCommand( "sm_startrek_transporter 0" );
	EmitSoundToAll("misc/transporter_out1.wav");

	PrintCenterTextAll("Scotty: She cant take it anymore capatin! The transporter is dead!");
	PrintHintTextToAll("Scotty: She cant take it anymore capatin! The transporter is dead!");
	PrintToChatAll("Scotty: She cant take it anymore capatin! The transporter is dead!");
	PrintToServer("[SM] Scotty's teleporter set to: 0  by %s", User);
	PrintToChatAll("ADMIN %s: Executed sm_scotty_off", User);

	return Plugin_Handled;
}

public Action:Scotty_Voting_Menu(client , Arguments)
{
	if (IsVoteInProgress())
	{
		PrintToConsole( client ,"[SM]  Voting has allready started...");
		return;
	}

	new Float:SCOTTY_ONLINE = GetConVarFloat(scotty_online);

	if(SCOTTY_ONLINE == 1)
	{
		new Handle:menu = CreateMenu(Handle_Scotty_VoteMenu);
		SetMenuTitle(menu, "Scotty: Captain, disable the transporter?");
		AddMenuItem(menu, "yes", "Yes please");
		AddMenuItem(menu, "no", "No thanks");
		SetMenuExitButton(menu, false);
		VoteMenuToAll(menu, 20);
	}
	if(SCOTTY_ONLINE == 0)
	{
		new Handle:menu = CreateMenu(Handle_Scotty_VoteMenu);
		SetMenuTitle(menu, "Scotty: Captain, enable the transporter?");
		AddMenuItem(menu, "yes", "Beam me up Scotty!");
		AddMenuItem(menu, "no", "No thanks");
		SetMenuExitButton(menu, false);
		VoteMenuToAll(menu, 20);
	}

	LastVote = GetTime();
	PrintToConsole( client ,"[SM]  ADMIN !!! Ignore the <Unknown command: sm_votescotty> -- its ok");
	PrintToConsole( client ,"[SM]  Vote started...");
	PrintToChatAll("[SM]  The Scotty Teleporter vote has started!");

	EmitSoundToAll("misc/transporter_molecules.wav");

	//return Plugin_Continue;
}

public Handle_Scotty_VoteMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		/* This is called after VoteEnd */
		CloseHandle(menu);
	} 
	else if (action == MenuAction_VoteEnd)
	{
		new Float:SCOTTY_ONLINE = GetConVarFloat(scotty_online);

		PrintToChatAll("[SM]  Vote has ended...");

		if(SCOTTY_ONLINE == 1)
		{
			/* 0=yes, 1=no */
			if (param1 == 0)
			{
				PrintToChatAll("Voting Results: The transporter is no longer functional.");
				ServerCommand( "sm_startrek_transporter 0" );
				EmitSoundToAll("misc/transporter_out1.wav");
			}
			if (param1 == 1)
			{
				PrintToChatAll("Voting Results: Scotty will stay !!!");
			}
		}
		if(SCOTTY_ONLINE == 0)
		{
			/* 0=yes, 1=no */
			if (param1 == 0)
			{
				PrintToChatAll("Voting Results: Beam me up scotty wins !!!");
				ServerCommand( "sm_startrek_transporter 1" );
				EmitSoundToAll("misc/transporter_scottybeammeup.wav");
			}
			if (param1 == 1)
			{
				PrintToChatAll("Voting Results: Scotty will stay disabled.");
				EmitSoundToAll("misc/transporter_molecules.wav");
			}
		}
	}
}