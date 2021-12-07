/*
Say Sounds
Hell Phoenix
http://www.charliemaurice.com/plugins

This plugin is somewhat a port of the classic SankSounds.  Basically, it uses a chat trigger then plays a 
sound associated with it.  People get a certain "quota" of sounds per map (default is 5).  They are warned 
at a certain amount (default 3) that they only have so many left.  This plugin also allows you to ban 
people from the sounds, reset sound quotas for everyone or just one person, and allow only admins to use
certain sounds.  

Thanks To:
	Ferret for his initial sourcemod plugins.  I used a few functions from his plugins as a learning tool.
	Teame06 for his help with the string replace function
	Bailopan for the pack stream info
	
Versions:
	1.0
		* First Public Release!
	1.1
		* Removed "downloadtable extension" dependency
		* Added Insurgency Mod Support
	1.2
		* Fixed some errors
		* Added admin only triggers
		* Join/Exit sound added
	1.3
		* Made join/exit sounds for admins only
		* Fixed errors on linux
	1.4
		* Fixed sound reset bug (thanks to lambdacore for pointing it out)
		* Added join/exit and wazza sound files to the download
	1.5 September 26, 2007
		* Uses EmitSountToClient instead of play (should allow multiple sounds to play at once)
			- Note that the path for the file changed because of this...remove the sound/ from your 
				cfg file...IE. change sound/misc/wazza.wav to misc/wazza.wav
		* Clients using "!soundlist" in chat will get a list of triggers in their console
		* Added a cvar to control how long between each sound to wait and a message to the user
	1.5.5 Oct 9, 2007
		* Fixed small memory leak from not closing handle at the end of each map
	1.6   Dec 28, 2007
		* Modified by -=|JFH|=-Naris
		* Added soundmenu (Menu of sounds to play)
		* Added adminsounds (Menu of admin-only sounds for admins to play)
		* Added adminsounds menu to SourceMod's admin menu
		* Added sm_specific_join_exit (Join/Exit for specific STEAM IDs)
		* Fixed join/exit sounds not playing by adding call to KvRewind()
		  before KvJumpToKey().
		* Fixed non-admins playing admin sounds by checking for generic admin bits.
		* Used SourceMod's MANPLAYERS instread of recreating another MAX_PLAYERS constant.
		* Added globalLastSound which is set to duration of last sound played
		  to reduce possibility of overlapping sounds.
		* Fix the sounds go away bug
		* Moved close of listfile from mapchange to Load_Sounds (if handle is valid)
	1.7   Jan 10, 2008
		* Modified by -=|JFH|=-Naris
		* Added separate admin sound_limit and time_between_sounds convars.
		* Changed multiple sound to check the "file" key if "file1" is not found.
	1.8   Jan 11, 2008
		* Modified by -=|JFH|=-Naris
		* Fixed timer errors
	1.9   Jan 18, 2008
		* Modified by -=|JFH|=-Naris
		* Added Sound Duration setting in config file
		* Various fixes
	1.10  Jan 22, 2008
		* Modified by -=|JFH|=-Naris
		* Added more comprensive error checking
		* Changed !soundlist to call Sound_Menu() instead of List_Sounds().
	1.11  Feb 03, 2008
		* Modified by -=|JFH|=-Naris
		* Added separate sm_sound_admin_warn convar.
		* Added unlimited sounds when limit == 0.
	1.12  Feb 03, 2008
		* Modified by -=|JFH|=-Naris
		* Fixed message that limit was passed when unlimited
		* Fixed grammar in warning.
	1.13  Feb 06, 2008
		* Modified by -=|JFH|=-Naris
		* Fix bug in unlimited sounds.
		* Added logging.
	1.14  Feb 13, 2008
		* Modified by -=|JFH|=-Naris
		* Added logging of unnamed (join/exit) sounds.
	1.15  Feb 14, 2008
		* Modified by -=|JFH|=-Naris
		* Added LAMDACORE's change to increase memory to allow lots of sounds
		* Added LAMDACORE's change to allow keyword to be embedded in a sentence.
		* Added sm_sound_sentence to enable the above modification.
	1.16  Feb 18, 2008
		* Modified by -=|JFH|=-Naris
		* Added check for Fake clients (bots) before Emitting Sounds
		  or sending Chat messages.
	1.17  Mar 1, 2008
		* Modified by -=|JFH|=-Naris
		* Fixed crash in Counter-Strike (Windows) by NOT calling GetSoundDuration()
		  unless the SDKVersion >= 30 (Version or Orangebox/TF2)
	1.18  Mar 2, 2008
		* Modified by -=|JFH|=-NarisTIMER_HNDL_CLOSE
		* Also added check to not call GetSoundDuration() for mp3 files.
		* Added sm_sound_logging to turn logging of sounds played on and off.
		* Added sm_sound_allow_bots to allow bots to trigger sounds.
	1.19  Mar 2, 2008
		* Modified by -=|JFH|=-Naris
		* Removed sm_sound_allow_bots to allow bots to trigger sounds.
		* Removed several checks for Fake Clients.
		* Commented out code that calls GetSoundDuration()
	1.20  Mar 16, 2008
		* Modified by -=|JFH|=-Naris
		* Added AutoExecConfig()
		* Removed code that calls GetSoundDuration().
	2.0   March 15, 2008
	    * Modified by [RiCK] Stokes aka. FernFerret
		* Made version 2.0 due to massive functionallity change
		* Changed Plugin name from Saysounds, to Saysoundshybrid
		* Changed Reference from saysounds.cfg to saysoundshybrid.cfg
		* Added ability to create sounds from actions in TF2 :) (Currently only 3 supported(Flag Events, Kill Events, 
		- Medic Uber Event) more to be added later
		* Added ability to hide soundmenu from non admins (sm_sound_showmenu)
		* Added menu for admins to show ALL sounds admin and public (sm_all_sounds)
		* Added above two items to admin menu under "Server Commands"
		* Added a few new types of data that you can add in config file including "actiononly" which will allow
		- SSH(SaySoundsHybrid) to play the sound, aka clients will download it, but they can't play it
		- Other types are covered in the demo section of this file
		* Changed the Sound_Menu function: Added AllSounds parameter
		* Updated Credits
	2.0.1 March 15, 2008
		* Modified by [RiCK] Stokes aka. FernFerret
		* Fixed Error about hiding the sound menu
		* Updated to Core Version 1.17 - Fixed the crash on windows servers due to the getsoundduration
		* Added Spy disguiseing event(boolean) when a spy goes to disguise, triggers a true, opposite when he goes undisguised
	2.0.2 March 15, 2008
		* Modified by [RiCK] Stokes aka. FernFerret
		* Updated to Core Version 1.19 - The Following fixes were ported in:
			1.18  Mar 2, 2008
				* Modified by -=|JFH|=-Naris
				* Also added check to not call GetSoundDuration() for mp3 files.
				* Added sm_sound_logging to turn logging of sounds played on and off.
				* Added sm_sound_allow_bots to allow bots to trigger sounds.
			1.19  Mar 2, 2008
				* Modified by -=|JFH|=-Naris
				* Removed sm_sound_allow_bots to allow bots to trigger sounds.
				* Removed several checks for Fake Clients.
				* Commented out code that calls GetSoundDuration()
		* Added event "build" Support
	2.0.3 Mar 16, 2008
		* Modified by -=|JFH|=-Naris
		* Merged the last few saysounds changes with saysounds hybrid.
	2.0.4 Jun 13, 2008
		* Modified by -=|JFH|=-Naris
		* Checks the GameType() before hooking TF2 events.
	2.0.5 Aug 20, 2008
		* Modified by Uberman
		* Adds the chat "!stop" command to stop any currently playing sound
	2.0.6 Oct 30, 2008
		* Modified by gH0sTy
		* Added usage of clientprefs extension (SM 1.1 only)
		* If a client turns the playback of sounds on/off it will be stored in the clientprefs sqlite database
		* The next time the client connects, the plugin will retrieve the saved value so clients that don't want
		* to play sounds doesn't have to turn it off after every reconnect or mapchange 
		* Added sm_play_cl_snd_off to restrict players with sounds turned off from playing sounds
	3.0.0 Jun 15, 2008
		* Modified by -=|JFH|=-Naris
		* Added Karaoke mode.
	3.0.5 Sep 30, 2008
		* Merged Uberman !stop command into 3.0.0 by Naris
	3.0.6 Oct 30, 2008
		* Merged gH0sTy clientprefs code (to save user settings) into 3.0.0 by Naris


Todo:
	* Optimise keyvalues usage
	* Save user settings (Done for SM 1.1)
 
Cvarlist (default value):
	sm_sound_enable 1		 Turns Sounds On/Off
	sm_sound_warn 3			 Number of sounds to warn person at
	sm_sound_limit 5 		 Maximum sounds per person
	sm_sound_admin_limit 0 		 Maximum sounds per admin
	sm_sound_admin_warn 0		 Number of sounds to warn admin at
	sm_sound_announce 0		 Turns on announcements when a sound is played
	sm_sound_sentence 0	 	 When set, will trigger sounds if keyword is embedded in a sentence
	sm_sound_logging 0	 	 When set, will log sounds that are played
	sm_join_exit 0 			 Play sounds when someone joins or exits the game
	sm_join_spawn 1 		 Wait until the player spawns before playing the join sound
	sm_specific_join_exit 0 	 Play sounds when a specific STEAM ID joins or exits the game
	sm_time_between_sounds 4.5 	 Time between each sound trigger, 0.0 to disable checking
	sm_time_between_admin_sounds 4.5 Time between each sound trigger (for admins), 0.0 to disable checking
	sm_sound_showmenu 1		Turns the Public Sound Menu on(1) or off(0)

Admin Commands:
	sm_sound_ban <user>		 Bans a player from using sounds
	sm_sound_unban <user>		 Unbans a player os they can play sounds
	sm_sound_reset <all|user>	 Resets sound quota for user, or everyone if all
	sm_admin_sounds 		 Display a menu of all admin sounds to play
	!adminsounds 			 When used in chat will present a menu of all admin sound to play.
	!allsounds			 When used in chat will present a menu of all sounds to play.
	
User Commands:
	sm_sound_menu 			 Display a menu of all sounds (trigger words) to play
	sm_sound_list  			 Print all trigger words to the console
	!sounds  			 When used in chat turns sounds on/off for that client
	!soundlist  			 When used in chat will print all the trigger words to the console (Now displays menu)
	!soundmenu  			 When used in chat will present a menu to choose a sound to play.
	!stop	 			 When used in chat will per-user stop any sound currently playing by this plug-in


Make sure "saysounds.cfg" is in your addons/sourcemod/configs/ directory.
Sounds go in your mods "sound" directory (such as sound/misc/filename.wav).
File Format:
	"Sound Combinations"
		{
			"JoinSound" // Sound to play when a player Joins the server
			{
				"file"	"misc/welcome.wav"
				"admin"	"0"
				"single" "1" // 1 to play sound to single client only, 0 to play to all (default is 0)
			}
			"wazza"  // Word trigger
			{
				"file"	"misc/wazza.wav" //"file" is always there, next is the filepath (always starts with "sound/")
				"admin"	"1"	//1 is admin only, 0 is anyone (defaults is 0)
				"download" "1"	//1 to download the sounds, 0 to not download (default is 1)
				"duration" "5.0" // duration of the sound in seconds (default is 0.0)
			}
			"lol"  // Word trigger to randomly select 1 of multiple sounds
			{
				"file"	"misc/lol1.wav"	// name of the 1st option, can also be "file1"
				"file2"	"misc/lol2.wav"	// name of the 2nd option
				"file3"	"misc/lol3.wav"
				"file4"	"misc/lol4.wav"
				"count"	"4"		// number of sounds (default is 1)
				"duration" "1:30"	// This will apply no matter which sound is selected
			}
			"STEAM_0:x:xxxxxx" // trigger for specific STEAM ID
			{
				"file"	"misc/myhouse.mp3" // name of sound to play when joining
				"exit"	"misc/goodbye.mp3" // name of sound to play when leaving
				"admin"	"0"
			}
			"somesong"  // Word trigger for Karaoke
			{
				"file"	"misc/somesong.wav"
				"karaoke" "somesong.cfg" // name of config file for karaoke lyrics
			}
			"doh"  // Minimun configuration for sounds
			{
				"file"	"misc/doh.wav"	// This will set all other options to default values
			}
			* ####FernFerret####
			* New Section showing how to use Action Sounds Extention
			* New Parameters:
				- actiononly	If this variable is set to 1, the sound cannot be 
				 				played by a menu or a client typing
				- action		If the action filled in here is performed, the sound will play
				- param			The best way to think of param is "Play Sound if [ACTION] with [PARAM]"
				* 				Some examples are Flag events**, or weapons***
				- prob			The probability of a sound playing, if you want a sound to play 20% of the time
				* 				the fill in prob as ".2" or the percentage divided by 100
				* Some examples:
			"invincible"
			{
				"file"	"admin_plugin/invincible.wav"
				"admin"	"1"
				"actiononly" "1"
				"action"	"uber"
				// Note: If the action is uber, you do not need param
				// Prob is assumed 1 or 100% if nothing is provied
			}
			"lightmyfire"
			{
				"file"	"admin_plugin/lmf.wav"
				"admin"	"1"
				"actiononly" "1"
				"action"	"kill"
				"param"		"flamethrower"
				"prob"		".05"
			}
		}

Karaoke config files are formatted like this:
	"Some Song Karaoke" // Whatever
		{
			"1"
			{
				"time"	"0:0" // time offset for 1st line
				"text"	"1st line"
			}
			"2"
			{
				"time"	"0:5" // time offset for 2nd line
				"text"	"2nd line for spectators"
				"text1"	"2nd line for first (Red/T/Allies) team"
				"text2"	"2nd line for second (Blue/CT/Axis) team"
			}
			"3"
			{
				"time"	"0:10/ time offset for 3rd line
				"text"	"3rd line"
			}
		}

	**  Current Flag actions are:
		flag_picked_up
		flag_captured
		flag_defended
		flag_dropped
	*** Weapons are whatever the weapon is listed as in the source engine, will put up list soon
	* 
	* Any Questions, post on the forums: 
	* 
	* THANKS to Hell Phoenix for the great plugin, -=|JFH|=-Naris for the
	* Excellent improvements making this plugin truly a diamond among the others and 
	* LAMDACORE for his contributions to the effiecy of this plugin running
	* 
	* Enjoy Say Sounds Hybrid
	* - [RiCK] Stokes aka. FernFerret
*/


#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#undef REQUIRE_PLUGIN
#include <adminmenu>

#include "gametype"

// BEIGN MOD BY LAMDACORE
// extra memory usability for a lot of sounds.
// Uncomment the next line (w/#pragma) to add additional memory
//#pragma dynamic 65536 
#pragma dynamic 131072
// END MOD BY LAMDACORE

#pragma semicolon 1

#define PLUGIN_VERSION "3.0.6"

enum sound_types { normal_sounds, admin_sounds, karaoke_sounds, all_sounds };

new Handle:cvarsoundenable = INVALID_HANDLE;
new Handle:cvarsoundlimit = INVALID_HANDLE;
new Handle:cvarsoundwarn = INVALID_HANDLE;
new Handle:cvarjoinexit = INVALID_HANDLE;
new Handle:cvarjoinspawn = INVALID_HANDLE;
new Handle:cvarspecificjoinexit = INVALID_HANDLE;
new Handle:cvartimebetween = INVALID_HANDLE;
new Handle:cvaradmintime = INVALID_HANDLE;
new Handle:cvaradminwarn = INVALID_HANDLE;
new Handle:cvaradminlimit = INVALID_HANDLE;
new Handle:cvarannounce = INVALID_HANDLE;
new Handle:cvarsentence = INVALID_HANDLE;
new Handle:cvarlogging = INVALID_HANDLE;
new Handle:cvarplayifclsndoff = INVALID_HANDLE;
new Handle:cvarkaraokedelay = INVALID_HANDLE;
/*####FernFerret####*/
new Handle:cvarshowsoundmenu = INVALID_HANDLE;
/*##################*/
new Handle:listfile = INVALID_HANDLE;
new Handle:hAdminMenu = INVALID_HANDLE;
new String:soundlistfile[PLATFORM_MAX_PATH] = "";
//##### Clientprefs #####
new Handle:g_ssplay_cookie = INVALID_HANDLE;
//#######################
new restrict_playing_sounds[MAXPLAYERS+1];
new SndOn[MAXPLAYERS+1];
new SndCount[MAXPLAYERS+1];
new String:SndPlaying[MAXPLAYERS+1][PLATFORM_MAX_PATH];
new Float:LastSound[MAXPLAYERS+1];
new bool:firstSpawn[MAXPLAYERS+1];
new Float:globalLastSound = 0.0;
new Float:globalLastAdminSound = 0.0;

// Variables for karaoke
new Handle:karaokeFile = INVALID_HANDLE;
new Handle:karaokeTimer = INVALID_HANDLE;
new Float:karaokeStartTime = 0.0;

// Variables to enable/disable advertisments plugin during karaoke
new Handle:cvaradvertisements = INVALID_HANDLE;
new bool:advertisements_enabled = false;

public Plugin:myinfo = 
{
	name = "Say Sounds (including Hybrid Edition)",
	author = "Hell Phoenix, -=|JFH|=-Naris, [RiCK] Stokes, LAMDACORE, Uberman, gH0sTy",
	description = "Say Sounds and Action Sounds packaged into one neat plugin! Welcome to the new day of SaySounds Hybrid!",
	version = PLUGIN_VERSION,
	url = "http://www.charliemaurice.com/plugins/"
};

public OnPluginStart(){
	CreateConVar("sm_saysounds_version", PLUGIN_VERSION, "Say Sounds Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarsoundenable = CreateConVar("sm_sound_enable","1","Turns Sounds On/Off",FCVAR_PLUGIN);
	cvarsoundwarn = CreateConVar("sm_sound_warn","3","Number of sounds to warn person at (0 for no warnings)",FCVAR_PLUGIN);
	cvarsoundlimit = CreateConVar("sm_sound_limit","5","Maximum sounds per person (0 for unlimited)",FCVAR_PLUGIN);
	cvarjoinexit = CreateConVar("sm_join_exit","0","Play sounds when someone joins or exits the game",FCVAR_PLUGIN);
	cvarjoinspawn = CreateConVar("sm_join_spawn","1","Wait until the player spawns before playing the join sound",FCVAR_PLUGIN);
	cvarspecificjoinexit = CreateConVar("sm_specific_join_exit","1","Play sounds when specific steam ID joins or exits the game",FCVAR_PLUGIN);
	cvartimebetween = CreateConVar("sm_time_between_sounds","4.5","Time between each sound trigger, 0.0 to disable checking",FCVAR_PLUGIN);
	cvaradmintime = CreateConVar("sm_time_between_admin_sounds","4.5","Time between each admin sound trigger, 0.0 to disable checking",FCVAR_PLUGIN);
	cvaradminwarn = CreateConVar("sm_sound_admin_warn","0","Number of sounds to warn admin at (0 for no warnings)",FCVAR_PLUGIN);
	cvaradminlimit = CreateConVar("sm_sound_admin_limit","0","Maximum sounds per admin (0 for unlimited)",FCVAR_PLUGIN);
	cvarannounce = CreateConVar("sm_sound_announce","0","Turns on announcements when a sound is played",FCVAR_PLUGIN);
	cvarsentence = CreateConVar("sm_sound_sentence","0","When set, will trigger sounds if keyword is embedded in a sentence",FCVAR_PLUGIN);
	cvarlogging = CreateConVar("sm_sound_logging","1","When set, will log sounds that are played",FCVAR_PLUGIN);
	cvarplayifclsndoff = CreateConVar("sm_play_cl_snd_off","0","When set, allows clients that have turned their sounds off to trigger sounds (0=off | 1=on)",FCVAR_PLUGIN);
	cvarkaraokedelay = CreateConVar("sm_karaoke_delay","15.0","Delay before playing a Karaoke song",FCVAR_PLUGIN);

	/*####FernFerret####*/
	// This is the Variable that will enable or disable the sound menu to public users, Admin users will always have
	// access to their menus, From the admin menu it is a toggle variable
	cvarshowsoundmenu = CreateConVar("sm_sound_showmenu","1","1 To show menu to users, 0 to hide menu from users (admins excluded)",FCVAR_PLUGIN);
	/*##################*/

	//##### Clientprefs #####
	// for storing clients sound settings
	g_ssplay_cookie = RegClientCookie("saysoundsplay", "Play Say Sounds", CookieAccess_Protected);
	//#######################

	RegAdminCmd("sm_sound_ban", Command_Sound_Ban, ADMFLAG_BAN, "sm_sound_ban <user> : Bans a player from using sounds");
	RegAdminCmd("sm_sound_unban", Command_Sound_Unban, ADMFLAG_BAN, "sm_sound_unban <user> : Unbans a player from using sounds");
	RegAdminCmd("sm_sound_reset", Command_Sound_Reset, ADMFLAG_GENERIC, "sm_sound_reset <user | all> : Resets sound quota for user, or everyone if all");
	RegAdminCmd("sm_admin_sounds", Command_Admin_Sounds,ADMFLAG_GENERIC, "Display a menu of Admin sounds to play");
	RegAdminCmd("sm_karaoke", Command_Karaoke,ADMFLAG_GENERIC, "Display a menu of Karaoke songs to play");
	/*####FernFerret####*/
	// This is the admin command that shows all sounds, it is currently set to show to a GENERIC ADMIN
	RegAdminCmd("sm_all_sounds", Command_All_Sounds, ADMFLAG_GENERIC,"Display a menu of ALL sounds to play");
	/*##################*/

	RegConsoleCmd("sm_sound_list", Command_Sound_List, "List available sounds to console");
	RegConsoleCmd("sm_sound_menu", Command_Sound_Menu, "Display a menu of sounds to play");
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say2", Command_InsurgencySay);
	RegConsoleCmd("say_team", Command_Say);

	// Execute the config file
	AutoExecConfig(true, "sm_saysounds");

	/*####FernFerret####*/
	// This is where we hook the events that we will use and assign them to functions
	HookEvent("player_death", Event_Kill);
	HookEventEx("player_spawn",PlayerSpawn);

	if (GetGameType() == tf2){
		HookEvent("teamplay_flag_event", Event_Flag);
		HookEvent("player_chargedeployed", Event_UberCharge);
		HookEvent("player_builtobject", Event_Build);
	}
	/*##################*/

	/* Account for late loading */
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
		OnAdminMenuReady(topmenu);
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
		hAdminMenu = INVALID_HANDLE;
}
 
public OnAdminMenuReady(Handle:topmenu)
{
	/*************************************************************/
	/* Add a Play Admin Sound option to the SourceMod Admin Menu */
	/*************************************************************/

	/* Block us from being called twice */
	if (topmenu != hAdminMenu){
		/* Save the Handle */
		hAdminMenu = topmenu;
		new TopMenuObject:server_commands = FindTopMenuCategory(hAdminMenu, ADMINMENU_SERVERCOMMANDS);
		AddToTopMenu(hAdminMenu, "sm_admin_sounds", TopMenuObject_Item, Play_Admin_Sound,
				server_commands, "sm_admin_sounds", ADMFLAG_GENERIC);
		AddToTopMenu(hAdminMenu, "sm_karaoke", TopMenuObject_Item, Play_Karaoke_Sound, server_commands, "sm_karaoke", ADMFLAG_CHANGEMAP);

		/*####FernFerret####*/
		// Added two new items to the admin menu, the soundmenu hide (toggle) and the all sounds menu
		AddToTopMenu(hAdminMenu, "sm_all_sounds", TopMenuObject_Item, Play_All_Sound, server_commands, "sm_all_sounds", ADMFLAG_GENERIC);
		AddToTopMenu(hAdminMenu, "sm_sound_showmenu", TopMenuObject_Item, Set_Sound_Menu, server_commands, "sm_sound_showmenu", ADMFLAG_CHANGEMAP);
		/*##################*/
	}
}

public Play_Admin_Sound(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id,
                        param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "Play Admin Sound");
	else if (action == TopMenuAction_SelectOption)
		Sound_Menu(param,admin_sounds);
}

public Play_Karaoke_Sound(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id,
                          param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "Karaoke");
	else if (action == TopMenuAction_SelectOption)
		Sound_Menu(param,karaoke_sounds);
}

/*####FernFerret####*/
// Start FernFerret's Action Sounds Code
// This function sets parameters for showing the All Sounds item in the menu
public Play_All_Sound(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "Play a Sound");
	else if (action == TopMenuAction_SelectOption)
		Sound_Menu(param,all_sounds);
}

// Creates the SoundMenu show/hide item in the admin menu, it is a toggle
public Set_Sound_Menu(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if(GetConVarInt(cvarshowsoundmenu) == 1)
	{
		if (action == TopMenuAction_DisplayOption)
			Format(buffer, maxlength, "Hide Sound Menu");
		else if (action == TopMenuAction_SelectOption)
			SetConVarInt(cvarshowsoundmenu, 0);
	}
	else
	{
		if (action == TopMenuAction_DisplayOption)
			Format(buffer, maxlength, "Show Sound Menu");
		else if (action == TopMenuAction_SelectOption)
			SetConVarInt(cvarshowsoundmenu, 1);
	}
}

// Generic Sound event, this gets triggered whenever an event that is supported is triggered
public runSoundEvent(Handle:event,const String:type[],const String:extra[])
{
	decl String:action[PLATFORM_MAX_PATH+1];
	decl String:extraparam[PLATFORM_MAX_PATH+1];
	decl String:location[PLATFORM_MAX_PATH+1];
	// Send to all clients, will update in future to add To client/To Team/To All
	new clientlist[MAXPLAYERS+1];
	new clientcount = 0;
	new playersconnected = GetMaxClients();
	for (new i = 1; i <= playersconnected; i++){
		if(SndOn[i] && IsClientInGame(i)){
			clientlist[clientcount++] = i;
		}
	}
	KvRewind(listfile);
	if (!KvGotoFirstSubKey(listfile))
	{
		return false;
	}
	// Do while loop that finds out what extra parameter is and plays according sound, also adds random
	do
	{
		KvGetString(listfile, "action",action,sizeof(action),"");
		//PrintToServer("Found Subkey, trying to match (%s) with (%s)",action,type);
		if (StrEqual(action, type))
		{
			KvGetString(listfile, "file", location, sizeof(location),"");
			KvGetString(listfile, "param",extraparam,sizeof(extraparam),"");
			// Used for identifying the names of things
			//PrintToChatAll("Found Subkey, trying to match (%s) with (%s)",extra,extraparam);
			if(StrEqual(extra, extraparam))
			{
				// Next section performs random calculations, all percents in decimal from 1-0
				new Float:random = KvGetFloat(listfile, "prob",1.0);
				// Added error checking  for the random number
				if(random <= 0.0)
				{
					random = 0.01;
					PrintToChatAll("Your random value for (%s) is <= 0, please make it above 0",location);
				}
				if(random > 1.0)
				{
					random = 1.0;
				}
				new Float:generated = GetRandomFloat(0.0,1.0);
				if(generated <= random)
				{
					EmitSound(clientlist, clientcount, location);
				}
				return true;
			}
		}
	} while (KvGotoNextKey(listfile));
	return false;
}
// Event section, place events here
public Action:Event_UberCharge(Handle:event,const String:name[],bool:dontBroadcast)
{
	runSoundEvent(event,"uber","uber");
	return Plugin_Continue;
}
public Action:Event_Flag(Handle:event,const String:name[],bool:dontBroadcast)
{
	// pick up(1), capture(2), defend(3), dropped(4)
	// Translate the Integer that is the input to a string so that users
	// can just add a string to the config file
	decl String:flagstring[PLATFORM_MAX_PATH+1];
	new flagint;
	flagint = GetEventInt(event, "eventtype");
	switch(flagint)
	{
		case 1:
			strcopy(flagstring,sizeof(flagstring),"flag_picked_up");
		case 2:
			strcopy(flagstring,sizeof(flagstring),"flag_captured");
		case 3:
			strcopy(flagstring,sizeof(flagstring),"flag_defended");
		case 4:
			strcopy(flagstring,sizeof(flagstring),"flag_dropped");
		default:
			strcopy(flagstring,sizeof(flagstring),"flag_captured");
	}
	runSoundEvent(event,"flag",flagstring);
	return Plugin_Continue;
}
public Action:Event_Kill(Handle:event,const String:name[],bool:dontBroadcast)
{
	decl String:wepstring[PLATFORM_MAX_PATH+1];
	GetEventString(event, "weapon",wepstring,PLATFORM_MAX_PATH+1);
	runSoundEvent(event,"kill",wepstring);
	return Plugin_Continue;
}
public Action:Event_Build(Handle:event,const String:name[],bool:dontBroadcast)
{
	decl String:object[PLATFORM_MAX_PATH+1];
	new objectint = GetEventInt(event,"object");
	switch(objectint)
	{
		case 0:
			strcopy(object,sizeof(object),"obj_dispenser");
		case 1:
			strcopy(object,sizeof(object),"obj_tele_in");
		case 2:
			strcopy(object,sizeof(object),"obj_tele_out");
		case 3:
			strcopy(object,sizeof(object),"obj_sentry");
		default:
			strcopy(object,sizeof(object),"obj_dispenser");
	}
	runSoundEvent(event,"build",object);
	return Plugin_Continue;
}
// End FernFerret's Code
/*##################*/

public OnMapStart(){
	globalLastSound = 0.0;
	globalLastAdminSound = 0.0;
	for (new i = 1; i <= MAXPLAYERS; i++) {
		SndCount[i] = 0;
		LastSound[i] = 0.0;
	}

	if (GetGameType() == tf2) {
		PrecacheSound("vo/announcer_attention.wav", true);
		PrecacheSound("vo/announcer_begins_20sec.wav", true);
		PrecacheSound("vo/announcer_begins_10sec.wav", true);
		PrecacheSound("vo/announcer_begins_5sec.wav", true);
		PrecacheSound("vo/announcer_begins_4sec.wav", true);
		PrecacheSound("vo/announcer_begins_3sec.wav", true);
		PrecacheSound("vo/announcer_begins_2sec.wav", true);
		PrecacheSound("vo/announcer_begins_1sec.wav", true);
	} else {
		PrecacheSound("npc/overwatch/radiovoice/attention.wav", true);
		PrecacheSound("npc/overwatch/cityvoice/fcitadel_10sectosingularity.wav", true);
		PrecacheSound("npc/overwatch/radiovoice/five.wav", true);
		PrecacheSound("npc/overwatch/radiovoice/four.wav", true);
		PrecacheSound("npc/overwatch/radiovoice/three.wav", true);
		PrecacheSound("npc/overwatch/radiovoice/two.wav", true);
		PrecacheSound("npc/overwatch/radiovoice/one.wav", true);
	}

	CreateTimer(0.2, Load_Sounds);
}

public Action:Load_Sounds(Handle:timer){
	// precache sounds, loop through sounds
	BuildPath(Path_SM,soundlistfile,sizeof(soundlistfile),"configs/saysounds.cfg");
	if(!FileExists(soundlistfile)) {
		SetFailState("saysounds.cfg not parsed...file doesnt exist!");
	}else{
		if (listfile != INVALID_HANDLE){
			CloseHandle(listfile);
		}
		listfile = CreateKeyValues("soundlist");
		FileToKeyValues(listfile,soundlistfile);
		KvRewind(listfile);
		if (KvGotoFirstSubKey(listfile)){
			do{
				decl String:filelocation[PLATFORM_MAX_PATH+1];
				decl String:dl[PLATFORM_MAX_PATH+1];
				decl String:file[8];
				new count = KvGetNum(listfile, "count", 1);
				new download = KvGetNum(listfile, "download", 1);
				for (new i = 0; i <= count; i++){
					if (i){
						Format(file, sizeof(file), "file%d", i);
					}else{
						strcopy(file, sizeof(file), "file");
					}
					filelocation[0] = '\0';
					KvGetString(listfile, file, filelocation, sizeof(filelocation), "");
					if (filelocation[0] != '\0'){
						Format(dl, sizeof(dl), "sound/%s", filelocation);
						PrecacheSound(filelocation, true);
						if(download && FileExists(dl)){
							AddFileToDownloadsTable(dl);
						}
					}
				}
			} while (KvGotoNextKey(listfile));
		}
		else{
			SetFailState("saysounds.cfg not parsed...No subkeys found!");
		}
	}
	return Plugin_Handled;
}

public PlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast){
	if(GetConVarBool(cvarjoinspawn)){
		new userid = GetEventInt(event,"userid");
		if (userid){
			new index=GetClientOfUserId(userid);
			if (index){
				if(!IsFakeClient(index)){
					if (firstSpawn[index]){
						decl String:auth[64];
						GetClientAuthString(index,auth,63);
						CheckJoin(index, auth);
						firstSpawn[index] = false;
					}
				}
			}
		}
	}
}

public OnClientAuthorized(client, const String:auth[]){
	if(client != 0){
		SndCount[client] = 0;
		LastSound[client] = 0.0;
		firstSpawn[client]=true;
		if(!GetConVarBool(cvarjoinspawn)){
			CheckJoin(client, auth);
		}
	}
}

//##### Clientprefs #####
public OnClientPostAdminCheck(client){
	// Check Client cookie
	new String:cookie[4];
	if(AreClientCookiesCached(client)){
		GetClientCookie(client, g_ssplay_cookie, cookie, sizeof(cookie));
		if (StrEqual(cookie, "on")){
			SndOn[client] = 1;
			return;
		}
		if(StrEqual(cookie, "off")){
			SndOn[client] = 0;
			return;
		}
	}
	// Set cookie if client connects the first time
	SetClientCookie(client, g_ssplay_cookie, "on");
	SndOn[client] = 1;
}
//#######################

public CheckJoin(client, const String:auth[]){
	if(GetConVarBool(cvarspecificjoinexit)){
		decl String:filelocation[PLATFORM_MAX_PATH+1];
		KvRewind(listfile);
		if (KvJumpToKey(listfile, auth)){
			filelocation[0] = '\0';
			KvGetString(listfile, "join", filelocation, sizeof(filelocation), "");
			if (filelocation[0] != '\0'){
				Send_Sound(client,filelocation, "");
				SndCount[client] = 0;
				return;
			}else if (Submit_Sound(client,"")){
				SndCount[client] = 0;
				return;
			}
		}
	}

	if(GetConVarBool(cvarjoinexit)){
		KvRewind(listfile);
		if (KvJumpToKey(listfile, "JoinSound")){
			Submit_Sound(client,"");
			SndCount[client] = 0;
		}
	}
}

public OnClientDisconnect(client){
	if(GetConVarBool(cvarjoinexit)){
		SndCount[client] = 0;
		LastSound[client] = 0.0;
		firstSpawn[client] = true;

		if(GetConVarBool(cvarspecificjoinexit)){
			decl String:auth[64];
			GetClientAuthString(client,auth,63);

			decl String:filelocation[PLATFORM_MAX_PATH+1];
			KvRewind(listfile);
			if (KvJumpToKey(listfile, auth)){
				filelocation[0] = '\0';
				KvGetString(listfile, "exit", filelocation, sizeof(filelocation), "");
				if (filelocation[0] != '\0'){
					Send_Sound(client,filelocation, "");
					SndCount[client] = 0;
					return;
				}else if (Submit_Sound(client,"")){
					SndCount[client] = 0;
					return;
				}
			}
		}

		KvRewind(listfile);
		if (KvJumpToKey(listfile, "ExitSound")){
			Submit_Sound(client,"");
			SndCount[client] = 0;
		}
	}
}

public Action:Command_Say(client,args){
	if(client != 0){
		// If sounds are not enabled, then skip this whole thing
		if (!GetConVarBool(cvarsoundenable))
			return Plugin_Continue;

		// player is banned from playing sounds
		if (restrict_playing_sounds[client])
			return Plugin_Continue;
			
		decl String:speech[128];
		GetCmdArgString(speech,sizeof(speech));
		
		new startidx = 0;
		if (speech[0] == '"'){
			startidx = 1;
			/* Strip the ending quote, if there is one */
			new len = strlen(speech);
			if (speech[len-1] == '"'){
				speech[len-1] = '\0';
			}
		}

		if(strcmp(speech[startidx],"!sounds",false) == 0 || 
		   strcmp(speech[startidx],"sounds",false) == 0){
				if(SndOn[client] == 1){
					// Update cookie
					SetClientCookie(client, g_ssplay_cookie, "off");
					SndOn[client] = 0;
					PrintToChat(client,"[Say Sounds] Sounds Disabled");
				}else{
					// Update cookie
					SetClientCookie(client, g_ssplay_cookie, "on");
					SndOn[client] = 1;
					PrintToChat(client,"[Say Sounds] Sounds Enabled");
				}
				return Plugin_Handled;
		}else if(strcmp(speech[startidx],"!soundlist",false) == 0 ||
			strcmp(speech[startidx],"soundlist",false) == 0){
				if(GetConVarInt(cvarshowsoundmenu) == 1){
					Sound_Menu(client,normal_sounds);
				}else{
					List_Sounds(client);
					PrintToChat(client,"[Say Sounds] Check your console for a list of sound triggers");
				}
				return Plugin_Handled;
		}else if(strcmp(speech[startidx],"!soundmenu",false) == 0 ||
			strcmp(speech[startidx],"soundmenu",false) == 0){
				if(GetConVarInt(cvarshowsoundmenu) == 1){
					Sound_Menu(client,normal_sounds);
				}
				return Plugin_Handled;
		}else if(strcmp(speech[startidx],"!adminsounds",false) == 0 ||
			strcmp(speech[startidx],"adminsounds",false) == 0){
				Sound_Menu(client,admin_sounds);
				return Plugin_Handled;
		}else if(strcmp(speech[startidx],"!karaoke",false) == 0 ||
			strcmp(speech[startidx],"karaoke",false) == 0){
			Sound_Menu(client,karaoke_sounds);
			return Plugin_Handled;
		}else if(strcmp(speech[startidx],"!allsounds",false) == 0 ||
			strcmp(speech[startidx],"allsounds",false) == 0){
				Sound_Menu(client,all_sounds);
				return Plugin_Handled;
		}else if(strcmp(speech[startidx],"!stop",false) == 0){
			if(SndPlaying[client][0])
			{
				StopSound(client,SNDCHAN_AUTO,SndPlaying[client]);
				SndPlaying[client] = "";
			}
			return Plugin_Handled;
		}

		if(!GetConVarBool(cvarplayifclsndoff)){
			// Read Client cookie
			new String:cookie[4];
			GetClientCookie(client, g_ssplay_cookie, cookie, sizeof(cookie));
		
			// If player has turned sounds off and is restricted from playing sounds, skip
			if(StrEqual(cookie, "off") && !GetConVarBool(cvarplayifclsndoff)){
				return Plugin_Continue;
			}
		}

		KvRewind(listfile);
		KvGotoFirstSubKey(listfile);
		new bool:sentence = GetConVarBool(cvarsentence);
		decl String:buffer[255];
		do{
			KvGetSectionName(listfile, buffer, sizeof(buffer));
			if ((sentence && StrContains(speech[startidx],buffer,false) >= 0) ||
				(strcmp(speech[startidx],buffer,false) == 0)){
					Submit_Sound(client,buffer);
					break;
			}
		} while (KvGotoNextKey(listfile));

		return Plugin_Continue;
	}	
	return Plugin_Continue;
}

public Action:Command_InsurgencySay(client,args){
	if(client != 0){
		// If sounds are not enabled, then skip this whole thing
		if (!GetConVarBool(cvarsoundenable))
			return Plugin_Continue;

		// player is banned from playing sounds
		if (restrict_playing_sounds[client])
			return Plugin_Continue;
			
		decl String:speech[128];
		GetCmdArgString(speech,sizeof(speech));

		new startidx = 4;
		if (speech[0] == '"'){
			startidx = 5;
			/* Strip the ending quote, if there is one */
			new len = strlen(speech);
			if (speech[len-1] == '"'){
				speech[len-1] = '\0';
			}
		}

		if(strcmp(speech[startidx],"!sounds",false) == 0 ||
		   strcmp(speech[startidx],"sounds",false) == 0){
				if(SndOn[client] == 1){
					// Update cookie
					SetClientCookie(client, g_ssplay_cookie, "off");
					SndOn[client] = 0;
					PrintToChat(client,"[Say Sounds] Sounds Disabled");
				}else{
					// Update cookie
					SetClientCookie(client, g_ssplay_cookie, "on");
					SndOn[client] = 1;
					PrintToChat(client,"[Say Sounds] Sounds Enabled");
				}
				return Plugin_Handled;
		}else if(strcmp(speech[startidx],"!soundlist",false ||
			strcmp(speech[startidx],"soundlist",false) == 0) == 0){
			if(GetConVarInt(cvarshowsoundmenu) == 1){
				Sound_Menu(client,normal_sounds);
			}else{
				List_Sounds(client);
				PrintToChat(client,"[Say Sounds] Check your console for a list of sound triggers");
			}
			return Plugin_Handled;
		}else if(strcmp(speech[startidx],"!soundmenu",false ||
			strcmp(speech[startidx],"soundmenu",false) == 0) == 0){
			if(GetConVarInt(cvarshowsoundmenu) == 1){
				Sound_Menu(client,normal_sounds);
			}
			return Plugin_Handled;
		}else if(strcmp(speech[startidx],"!adminsounds",false) == 0 ||
			strcmp(speech[startidx],"adminsounds",false) == 0){
			Sound_Menu(client,admin_sounds);
			return Plugin_Handled;
		}else if(strcmp(speech[startidx],"!karaoke",false) == 0 ||
			strcmp(speech[startidx],"karaoke",false) == 0){
			Sound_Menu(client,karaoke_sounds);
			return Plugin_Handled;
		}else if(strcmp(speech[startidx],"!allsounds",false) == 0 ||
			strcmp(speech[startidx],"allsounds",false) == 0){
			Sound_Menu(client,all_sounds);
			return Plugin_Handled;
		}

		if(!GetConVarBool(cvarplayifclsndoff)){
			// Read Client cookie
			new String:cookie[4];
			GetClientCookie(client, g_ssplay_cookie, cookie, sizeof(cookie));
		
			// If player has turned sounds off and is restricted from playing sounds, skip
			if(StrEqual(cookie, "off") && !GetConVarBool(cvarplayifclsndoff)){
				return Plugin_Continue;
			}
		}

		KvRewind(listfile);
		KvGotoFirstSubKey(listfile);
		new bool:sentence = GetConVarBool(cvarsentence);
		decl String:buffer[255];
		do{
			KvGetSectionName(listfile, buffer, sizeof(buffer));
			if ((sentence && StrContains(speech[startidx],buffer,false) >= 0) ||
				(strcmp(speech[startidx],buffer,false) == 0)){
					Submit_Sound(client,buffer);
					break;
			}
		} while (KvGotoNextKey(listfile));

		return Plugin_Continue;
	}	
	return Plugin_Continue;
}

bool:Submit_Sound(client,const String:name[])
{
	decl String:filelocation[PLATFORM_MAX_PATH+1];
	decl String:file[8] = "file";
	new count = KvGetNum(listfile, "count", 1);
	if (count > 1){
		Format(file, sizeof(file), "file%d", GetRandomInt(1,count));
	}
	filelocation[0] = '\0';
	KvGetString(listfile, file, filelocation, sizeof(filelocation));
	if (filelocation[0] == '\0' && StrEqual(file, "file1")){
		KvGetString(listfile, "file", filelocation, sizeof(filelocation), "");
	}
	if (filelocation[0] != '\0'){
		decl String:karaoke[PLATFORM_MAX_PATH+1];
		karaoke[0] = '\0';
		KvGetString(listfile, "karaoke", karaoke, sizeof(karaoke));
		if (karaoke[0] != '\0'){
			Load_Karaoke(client, filelocation, name, karaoke);
		}else{
			Send_Sound(client, filelocation, name);
		}
		return true;
	}
	return false;
}

Send_Sound(client, const String:filelocation[], const String:name[])
{
	decl String:timebuf[64];
	new adminonly = KvGetNum(listfile, "admin",0);
	new singleonly = KvGetNum(listfile, "single",0);
	/*####FernFerret####*/
	// Added the action only param to the pack
	new actiononly = KvGetNum(listfile, "actiononly",0);
	/*##################*/
	new Float:duration = Convert_Time(timebuf);

	new Handle:pack;
	CreateDataTimer(0.1,Play_Sound_Timer,pack, TIMER_FLAG_NO_MAPCHANGE);
	WritePackCell(pack, client);
	WritePackCell(pack, adminonly);
	WritePackCell(pack, singleonly);
	/*####FernFerret####*/
	WritePackCell(pack, actiononly);
	/*##################*/
	WritePackFloat(pack, duration);
	WritePackString(pack, filelocation);
	WritePackString(pack, name);
	ResetPack(pack);
}

public Action:Play_Sound_Timer(Handle:timer,Handle:pack){
	decl String:filelocation[PLATFORM_MAX_PATH+1];
	decl String:name[PLATFORM_MAX_PATH+1];
	new client = ReadPackCell(pack);
	new adminonly = ReadPackCell(pack);
	new singleonly = ReadPackCell(pack);
	/*####FernFerret####*/
	new actiononly = ReadPackCell(pack);
	/*##################*/
	new Float:duration = ReadPackFloat(pack);
	ReadPackString(pack, filelocation, sizeof(filelocation));
	ReadPackString(pack, name , sizeof(name));

	/*####FernFerret####*/
	// Checks for Action Only sounds and messages user telling them why they can't play an action only sound
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		//new AdminId:aid = GetUserAdmin(client);
		//isadmin = (aid != INVALID_ADMIN_ID) && GetAdminFlag(aid, Admin_Generic, Access_Effective);
		if(actiononly == 1){
			PrintToChat(client,"[Action Sounds] Sorry, this is an action sound!");
			return Plugin_Handled;
		}
	}
	/*##################*/

	new bool:isadmin = false;
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		new AdminId:aid = GetUserAdmin(client);
		isadmin = (aid != INVALID_ADMIN_ID) && GetAdminFlag(aid, Admin_Generic, Access_Effective);
		if(adminonly && !isadmin){
			PrintToChat(client,"[Say Sounds] Sorry, you are not authorized to play this sound!");
			return Plugin_Handled;
		}
	}

	new Float:thetime = GetGameTime();
	if (LastSound[client] >= thetime){
		if(IsClientInGame(client) && !IsFakeClient(client)){
			PrintToChat(client,"[Say Sounds] Please don't spam the sounds!");
		}
		return Plugin_Handled;
	}

	new Float:waitTime = GetConVarFloat(cvartimebetween);
	if (waitTime < duration)
		waitTime = duration;

	new Float:adminTime = 0.0;
	if (adminonly)
	{
		if (globalLastAdminSound >= thetime){
			if(IsClientInGame(client) && !IsFakeClient(client)){
				PrintToChat(client,"[Say Sounds] Please don't spam the admin sounds!");
			}
			return Plugin_Handled;
		}

		adminTime = GetConVarFloat(cvaradmintime);
		if (adminTime < duration)
			adminTime = duration;
	}

	new soundLimit = isadmin ? GetConVarInt(cvaradminlimit) : GetConVarInt(cvarsoundlimit);	
	if (soundLimit <= 0 || SndCount[client] < soundLimit){
		if (globalLastSound < thetime){
			SndCount[client]++;
			LastSound[client] = thetime + waitTime;
			globalLastSound   = thetime + duration;

			if (adminonly)
				globalLastAdminSound = thetime + adminTime;

			if (singleonly){
				if(SndOn[client] && IsClientInGame(client) && !IsFakeClient(client)){
					EmitSoundToClient(client, filelocation);
					strcopy(SndPlaying[client], sizeof(SndPlaying[]), filelocation);
				}
			}else{
				Play_Sound(filelocation);
				if (name[0] && IsClientInGame(client) && !IsFakeClient(client)){
					if (GetConVarBool(cvarannounce)){
						PrintToChatAll("%N played %s", client, name);
					}
					if (GetConVarBool(cvarlogging)){
						LogToGame("[Say Sounds] %s%N played %s%s(%s)", isadmin ? "Admin " : "", client,
							   adminonly ? "admin sound " : "", name, filelocation);
					}
				}else if (GetConVarBool(cvarlogging)){
					LogToGame("[Say Sounds] played %s", filelocation);
				}
			}
		}
		else if(IsClientInGame(client) && !IsFakeClient(client)){
			PrintToChat(client,"[Say Sounds] Please don't spam the sounds!");
			return Plugin_Handled;
		}
	}

	if(soundLimit > 0 && IsClientInGame(client) && !IsFakeClient(client)){
		if (SndCount[client] > soundLimit){
			PrintToChat(client,"[Say Sounds] Sorry, you have reached your sound quota!");
		}else if (SndCount[client] == soundLimit){
			PrintToChat(client,"[Say Sounds] You have no sounds left to use!");
			SndCount[client]++; // Increment so we get the sorry message next time.
		}else{
			new soundWarn = isadmin ? GetConVarInt(cvaradminwarn) : GetConVarInt(cvarsoundwarn);	
			if (soundWarn <= 0 || SndCount[client] >= soundWarn){
				new numberleft = (soundLimit -  SndCount[client]);
				if (numberleft == 1)
					PrintToChat(client,"[Say Sounds] You only have %d sound left to use!",numberleft);
				else
					PrintToChat(client,"[Say Sounds] You only have %d sounds left to use!",numberleft);
			}
		}
	}
	return Plugin_Handled;
}

Play_Sound(const String:filelocation[])
{
	new clientlist[MAXPLAYERS+1];
	new clientcount = 0;
	new playersconnected = GetMaxClients();
	for (new i = 1; i <= playersconnected; i++){
		if(SndOn[i] && IsClientInGame(i) && !IsFakeClient(i)){
			clientlist[clientcount++] = i;
			strcopy(SndPlaying[i], sizeof(SndPlaying[]), filelocation);
		}
	}
	if (clientcount){
		EmitSound(clientlist, clientcount, filelocation);
	}
}

public Load_Karaoke(client, const String:filelocation[], const String:name[], const String:karaoke[]){
	new adminonly = KvGetNum(listfile, "admin", 1); // Karaoke sounds default to admin only
	new bool:isadmin = false;
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		new AdminId:aid = GetUserAdmin(client);
		isadmin = (aid != INVALID_ADMIN_ID) && GetAdminFlag(aid, Admin_Generic, Access_Effective);
		if(adminonly && !isadmin){
			PrintToChat(client,"[Say Sounds] Sorry, you are not authorized to play this sound!");
			return;
		}
	}

	decl String:karaokecfg[PLATFORM_MAX_PATH+1];
	BuildPath(Path_SM,karaokecfg,sizeof(karaokecfg),"configs/%s",karaoke);
	if(!FileExists(karaokecfg)){
		LogError("%s not parsed...file doesnt exist!", karaokecfg);
		Send_Sound(client, filelocation, name);
	}else{
		if (karaokeFile != INVALID_HANDLE){
			CloseHandle(karaokeFile);
		}
		karaokeFile = CreateKeyValues(name);
		FileToKeyValues(karaokeFile,karaokecfg);
		KvRewind(karaokeFile);
		decl String:title[128];
		title[0] = '\0';
		KvGetSectionName(karaokeFile, title, sizeof(title));
		if (KvGotoFirstSubKey(karaokeFile)){
			new Float:time = GetConVarFloat(cvarkaraokedelay);
			if (time > 0.0){
				Karaoke_Countdown(client, filelocation, title[0] ? title : name, time, true);
			}else{
				Karaoke_Start(client, filelocation, name);
			}
		}else{
			LogError("%s not parsed...No subkeys found!", karaokecfg);
			Send_Sound(client, filelocation, name);
		}
	}
}

Karaoke_Countdown(client, const String:filelocation[], const String:name[], Float:time, bool:attention){
	new Float:next=0.0;

	decl String:announcement[128];
	if (attention){
		Show_Message("%s\nKaraoke will begin in %2.0f seconds", name, time);
		if (GetGameType() == tf2) {
			strcopy(announcement, sizeof(announcement), "vo/announcer_attention.wav");
		}else{
			strcopy(announcement, sizeof(announcement), "npc/overwatch/radiovoice/attention.wav");
		}
		if (time >= 20.0){
			next = 20.0;
		}else if (time >= 10.0){
			next = 10.0;
		}else if (time > 5.0){
			next = 5.0;
		}else{
			next = time - 1.0;
		}
	}else{
		if (GetGameType() == tf2) {
			Format(announcement, sizeof(announcement), "vo/announcer_begins_%dsec.wav", RoundToFloor(time));
		}else{
			if (time == 10.0){
				strcopy(announcement, sizeof(announcement), "npc/overwatch/cityvoice/fcitadel_10sectosingularity.wav");
			} else if (time == 5.0){
				strcopy(announcement, sizeof(announcement), "npc/overwatch/radiovoice/five.wav");
			} else if (time == 4.0){
				strcopy(announcement, sizeof(announcement), "npc/overwatch/radiovoice/four.wav");
			} else if (time == 3.0){
				strcopy(announcement, sizeof(announcement), "npc/overwatch/radiovoice/three.wav");
			} else if (time == 2.0){
				strcopy(announcement, sizeof(announcement), "npc/overwatch/radiovoice/two.wav");
			} else if (time == 1.0){
				strcopy(announcement, sizeof(announcement), "npc/overwatch/radiovoice/one.wav");
			} else {
				announcement[0] = '\0';
			}
		}
		switch (time) {
			case 20.0: next = 10.0;
			case 10.0: next = 5.0;
			case 5.0:  next = 4.0;
			case 4.0:  next = 3.0;
			case 3.0:  next = 2.0; 
			case 2.0:  next = 1.0; 
			case 1.0:  next = 0.0; 
		}
	}

	if (time > 0.0){
		if (announcement[0] != '\0') {
			Play_Sound(announcement);
		}

		new Handle:pack;
		karaokeTimer = CreateDataTimer(time - next, Karaoke_Countdown_Timer, pack, TIMER_FLAG_NO_MAPCHANGE);
		WritePackCell(pack, client);
		WritePackFloat(pack, next);
		WritePackString(pack, filelocation);
		WritePackString(pack, name);
		ResetPack(pack);
	}else{
		Karaoke_Start(client, filelocation, name);
	}
}

Karaoke_Start(client, const String:filelocation[], const String:name[]){
	decl String:text[3][128], String:timebuf[64];
	timebuf[0] = '\0';
	text[0][0] = '\0';
	text[1][0] = '\0';
	text[2][0] = '\0';

	KvGetString(karaokeFile,"text",text[0],sizeof(text[]));
	KvGetString(karaokeFile,"text1",text[1],sizeof(text[]));
	KvGetString(karaokeFile,"text2",text[2],sizeof(text[]));
	KvGetString(karaokeFile,"time",timebuf,sizeof(timebuf));

	new Float:time = Convert_Time(timebuf);
	if (time == 0.0)
	{
		Karaoke_Message(text);
		if (KvGotoNextKey(karaokeFile)){
			text[0][0] = '\0';
			text[1][0] = '\0';
			text[2][0] = '\0';
			KvGetString(karaokeFile,"text",text[0],sizeof(text[]));
			KvGetString(karaokeFile,"text1",text[1],sizeof(text[]));
			KvGetString(karaokeFile,"text2",text[2],sizeof(text[]));
			KvGetString(karaokeFile,"time",timebuf,sizeof(timebuf));
			time = Convert_Time(timebuf);
		}else{
			CloseHandle(karaokeFile);
			karaokeFile = INVALID_HANDLE;
			time = 0.0;
		}
	}

	if (time > 0.0){
		cvaradvertisements = FindConVar("sm_advertisements_enabled");
		if (cvaradvertisements != INVALID_HANDLE)
		{
			advertisements_enabled = GetConVarBool(cvaradvertisements);
			SetConVarBool(cvaradvertisements, false);
		}

		new Handle:pack;
		karaokeTimer = CreateDataTimer(time, Karaoke_Timer, pack, TIMER_FLAG_NO_MAPCHANGE);
		WritePackString(pack, text[0]);
		WritePackString(pack, text[1]);
		WritePackString(pack, text[2]);
		ResetPack(pack);
	}else{
		karaokeTimer = INVALID_HANDLE;
	}

	karaokeStartTime = GetEngineTime();
	Send_Sound(client, filelocation, name);
}

Float:Convert_Time(const String:buffer[]){
	decl String:part[5];
	new pos = SplitString(buffer, ":", part, sizeof(part));
	if (pos == -1) {
		return StringToFloat(buffer);
	}else{
		return (StringToFloat(part)*60.0) +
			StringToFloat(buffer[pos]);
	}
}

Karaoke_Message(const String:text[3][]){
	new playersconnected = GetMaxClients();
	for (new i = 1; i <= playersconnected; i++){
		if(SndOn[i] && IsClientInGame(i) && !IsFakeClient(i)){
			new team = GetClientTeam(i) - 1;
			if (team >= 1 && text[team][0] != '\0')
				PrintCenterText(i, text[team]);
			else
				PrintCenterText(i, text[0]);
		}
	}
}

Show_Message(const String:fmt[], any:...){
        decl String:text[128];
        VFormat(text, sizeof(text), fmt, 2);

	new playersconnected = GetMaxClients();
	for (new i = 1; i <= playersconnected; i++){
		if(SndOn[i] && IsClientInGame(i) && !IsFakeClient(i)){
			PrintCenterText(i, text);
		}
	}
}

public Action:Karaoke_Countdown_Timer(Handle:timer,Handle:pack){
	decl String:filelocation[PLATFORM_MAX_PATH+1];
	decl String:name[PLATFORM_MAX_PATH+1];
	new client = ReadPackCell(pack);
	new Float:time = ReadPackFloat(pack);
	ReadPackString(pack, filelocation , sizeof(filelocation));
	ReadPackString(pack, name , sizeof(name));
	Karaoke_Countdown(client, filelocation, name, time, false);
}

public Action:Karaoke_Timer(Handle:timer,Handle:pack){
	decl String:text[3][128], String:timebuf[64];
	timebuf[0] = '\0';
	text[0][0] = '\0';
	text[1][0] = '\0';
	text[2][0] = '\0';

	ReadPackString(pack, text[0], sizeof(text[]));
	ReadPackString(pack, text[1], sizeof(text[]));
	ReadPackString(pack, text[2], sizeof(text[]));
	Karaoke_Message(text);

	if (karaokeFile != INVALID_HANDLE){
		if (KvGotoNextKey(karaokeFile)){
			text[0][0] = '\0';
			text[1][0] = '\0';
			text[2][0] = '\0';
			KvGetString(karaokeFile,"text",text[0],sizeof(text[]));
			KvGetString(karaokeFile,"text1",text[1],sizeof(text[]));
			KvGetString(karaokeFile,"text2",text[2],sizeof(text[]));
			KvGetString(karaokeFile,"time",timebuf,sizeof(timebuf));
			new Float:time = Convert_Time(timebuf);
			new Float:current_time = GetEngineTime() - karaokeStartTime;

			new Handle:next_pack;
			karaokeTimer = CreateDataTimer(time-current_time, Karaoke_Timer, next_pack, TIMER_FLAG_NO_MAPCHANGE);
			WritePackString(next_pack, text[0]);
			WritePackString(next_pack, text[1]);
			WritePackString(next_pack, text[2]);
			ResetPack(next_pack);
		}else{
			CloseHandle(karaokeFile);
			karaokeFile = INVALID_HANDLE;
			karaokeTimer = INVALID_HANDLE;
			karaokeStartTime = 0.0;

			if (cvaradvertisements != INVALID_HANDLE)
			{
				SetConVarBool(cvaradvertisements, advertisements_enabled);
				CloseHandle(cvaradvertisements);
				cvaradvertisements = INVALID_HANDLE;
			}
		}
	}else{
		karaokeTimer = INVALID_HANDLE;
	}
}

public Action:Command_Sound_Reset(client, args){
	if (args < 1){
		ReplyToCommand(client, "[Say Sounds] Usage: sm_sound_reset <user | all> : Resets sound quota for user, or everyone if all");
		return Plugin_Handled;
	}

	new String:arg[64];
	GetCmdArg(1, arg, sizeof(arg));	

	if (strcmp(arg,"all",false) == 0 ){
		for (new i = 1; i <= MAXPLAYERS; i++)
			SndCount[i] = 0;
		ReplyToCommand(client, "[Say Sounds] Quota has been reset for all players");	
	}else{
		decl String:name[64];
		new bool:isml,clients[MAXPLAYERS+1];
		new count=ProcessTargetString(arg,client,clients,MAXPLAYERS+1,COMMAND_FILTER_NO_BOTS,name,sizeof(name),isml);
		if (count > 0){
			for(new x=0;x<count;x++){
				new player=clients[x];
				if(IsPlayerAlive(player)){
					SndCount[player] = 0;
					new String:clientname[64];
					GetClientName(player,clientname,MAXPLAYERS);
					ReplyToCommand(client, "[Say Sounds] Quota has been reset for %s", clientname);
				}
			}
		}else{
			ReplyToTargetError(client, count);
		}
	}
	return Plugin_Handled;
}


public Action:Command_Sound_Ban(client, args){
	if (args < 1)
	{
		ReplyToCommand(client, "[Say Sounds] Usage: sm_sound_ban <user> : Bans a player from using sounds");
		return Plugin_Handled;	
	}

	new String:arg[64];
	GetCmdArg(1, arg, sizeof(arg));	

	decl String:name[64];
	new bool:isml,clients[MAXPLAYERS+1];
	new count=ProcessTargetString(arg,client,clients,MAXPLAYERS+1,COMMAND_FILTER_NO_BOTS,name,sizeof(name),isml);
	if (count > 0){
		for(new x=0;x<count;x++){
			new player=clients[x];
			if(IsPlayerAlive(player)){
				new String:clientname[64];
				GetClientName(player,clientname,MAXPLAYERS);
				if (restrict_playing_sounds[player] == 1){
					ReplyToCommand(client, "[Say Sounds] %s is already banned!", clientname);
				}else{
					restrict_playing_sounds[player]=1;
					ReplyToCommand(client,"[Say Sounds] %s has been banned!", clientname);
				}
			}
		}
	}else{
		ReplyToTargetError(client, count);
	}
	return Plugin_Handled;
}

public Action:Command_Sound_Unban(client, args){
	if (args < 1)
	{
		ReplyToCommand(client, "[Say Sounds] Usage: sm_sound_unban <user> <1|0> : Unbans a player from using sounds");
		return Plugin_Handled;	
	}

	new String:arg[64];
	GetCmdArg(1, arg, sizeof(arg));	

	decl String:name[64];
	new bool:isml,clients[MAXPLAYERS+1];
	new count=ProcessTargetString(arg,client,clients,MAXPLAYERS+1,COMMAND_FILTER_NO_BOTS,name,sizeof(name),isml);
	if (count > 0){
		for(new x=0;x<count;x++){
			new player=clients[x];
			if(IsPlayerAlive(player)){
				new String:clientname[64];
				GetClientName(player,clientname,MAXPLAYERS);
				if (restrict_playing_sounds[player] == 0){
					ReplyToCommand(client,"[Say Sounds] %s is not banned!", clientname);
				}else{
					restrict_playing_sounds[player]=0;
					ReplyToCommand(client,"[Say Sounds] %s has been unbanned!", clientname);
				}
			}
		}
	}else{
		ReplyToTargetError(client, count);
	}
	return Plugin_Handled;
}


public Action:Command_Sound_List(client, args){
	List_Sounds(client);
}

stock List_Sounds(client){
	KvRewind(listfile);
	if (KvJumpToKey(listfile, "ExitSound", false))
		KvGotoNextKey(listfile, true);
	else
		KvGotoFirstSubKey(listfile);

	decl String:buffer[PLATFORM_MAX_PATH+1];
	do{
		KvGetSectionName(listfile, buffer, sizeof(buffer));
		PrintToConsole(client, buffer);
	} while (KvGotoNextKey(listfile));
}

public Action:Command_Sound_Menu(client, args){
	Sound_Menu(client,normal_sounds);
}

public Action:Command_Admin_Sounds(client, args){
	Sound_Menu(client,admin_sounds);
}

public Action:Command_Karaoke(client, args){
	Sound_Menu(client,karaoke_sounds);
}

public Action:Command_All_Sounds(client, args){
	Sound_Menu(client,all_sounds);
}

public Sound_Menu(client, sound_types:types){
	if (types >= admin_sounds){
		new AdminId:aid = GetUserAdmin(client);
		new bool:isadmin = (aid != INVALID_ADMIN_ID) && GetAdminFlag(aid, Admin_Generic, Access_Effective);

		if (!isadmin){
			PrintToChat(client,"[Say Sounds] You must be an admin view this menu!");
			return;
		}
	}

	new Handle:soundmenu=CreateMenu(Menu_Select);
	SetMenuExitButton(soundmenu,true);
	SetMenuTitle(soundmenu,"Choose a sound to play.");

	decl String:num[4];
	decl String:buffer[PLATFORM_MAX_PATH+1];
	decl String:karaokefile[PLATFORM_MAX_PATH+1];
	new count=1;

	KvRewind(listfile);
	if (KvGotoFirstSubKey(listfile)){
		do{
			KvGetSectionName(listfile, buffer, sizeof(buffer));
			if (!StrEqual(buffer, "JoinSound") &&
			    !StrEqual(buffer, "ExitSound") &&
			    strncmp(buffer,"STEAM_",6,false))
			{
				if (!KvGetNum(listfile, "actiononly", 0)){
					new bool:admin = bool:KvGetNum(listfile, "admin",0);
					if (!admin || types >= admin_sounds){
						karaokefile[0] = '\0';
						KvGetString(listfile, "karaoke", karaokefile, sizeof(karaokefile));
						new bool:karaoke = (karaokefile[0] != '\0');
						if (!karaoke || types >= karaoke_sounds){
							switch (types){
								case karaoke_sounds:{
							    		if (!karaoke){
								    		continue;
									}
								}
								case admin_sounds:{
									if (!admin){
										continue;
									}
								}
								case all_sounds:{
									if (karaoke){
										StrCat(buffer, sizeof(buffer), " [Karaoke]");
									}
									if (admin){
										StrCat(buffer, sizeof(buffer), " [Admin]");
									}
								}
							}
							Format(num,3,"%d",count);
							AddMenuItem(soundmenu,num,buffer);
							count++;
						}
					}
				}
			}
		} while (KvGotoNextKey(listfile));
	}
	else{
		SetFailState("No subkeys found in the config file!");
	}

	DisplayMenu(soundmenu,client,MENU_TIME_FOREVER);
}

public Menu_Select(Handle:menu,MenuAction:action,client,selection)
{
	if(action==MenuAction_Select){
		decl String:SelectionInfo[4];
		decl String:SelectionDispText[PLATFORM_MAX_PATH+1];
		new SelectionStyle;
		if (GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText))){
			KvRewind(listfile);
			KvGotoFirstSubKey(listfile);
			decl String:buffer[PLATFORM_MAX_PATH];
			do{
				KvGetSectionName(listfile, buffer, sizeof(buffer));
				if (strcmp(SelectionDispText,buffer,false) == 0){
					Submit_Sound(client,buffer);
					break;
				}
			} while (KvGotoNextKey(listfile));
		}
	}else if (action == MenuAction_End){
		CloseHandle(menu);
	}
}

public OnMapEnd(){
	if (listfile != INVALID_HANDLE){
		CloseHandle(listfile);
		listfile = INVALID_HANDLE;
	}

	if (karaokeFile != INVALID_HANDLE){
		CloseHandle(karaokeFile);
		karaokeFile = INVALID_HANDLE;
	}

	if (karaokeTimer != INVALID_HANDLE){
		KillTimer(karaokeTimer);
		karaokeTimer = INVALID_HANDLE;
	}
}

public OnPluginEnd()
{
	if (listfile != INVALID_HANDLE){
		CloseHandle(listfile);
		listfile = INVALID_HANDLE;
	}

	if (karaokeFile != INVALID_HANDLE){
		CloseHandle(karaokeFile);
		karaokeFile = INVALID_HANDLE;
	}
}
