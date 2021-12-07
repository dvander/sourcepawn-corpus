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
		* Used SourceMod's MANPLAYERS instead of recreating another MAX_PLAYERS constant.
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
		* Added more comprehensive error checking
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
		* Modified by -=|JFH|=-Naris
		* Also added check to not call GetSoundDuration() for mp3 files.
		* Added sm_sound_logging to turn logging of sounds played on and off.
		* Added sm_sound_allow_bots to allow bots to trigger sounds.
	1.19  Mar 2, 2008
		* Modified by -=|JFH|=-Naris
		* Removed sm_sound_allow_bots to allow bots to trigger sounds.
		* Removed several checks for Fake Clients.
		* Commented out code that calls GetSoundDuration()
	1.19.1	Dec 10, 2008
		* Modified by Woody
		* Added volume setting cvar sm_saysounds_volume
		* Added individual sound volume override with cfg file key "volume"
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
		* Added Spy disguising event(boolean) when a spy goes to disguise, triggers a true, opposite when he goes undisguised
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
	3.0.7 Jan 04, 2009
		* Modified by gH0sTy
		* fixed Anti-Soundspam Issue, (epic fail :P)
		* Changed Version Cvar from "sm_saysounds_version" to "sm_saysounds_hybrid_version" so this plugin can be approved without the need to unapprove the original one
	3.0.8 Jan 05, 2009
		* Modified by gH0sTy
		* fixed Anti-Soundspam Issue - Added the Function again that reads the duration from the saysounds.cfg; Added a check if the sound is a Karaoke sound (new bool:iskaraoke)
		* NOTE: Haven't tested if Karaoke still works but it should
	3.0.9 Jan 14, 2009
		* Fixed broken duration that broke anti-spam, iskaraoke no longer required.
		* Merged/Ported Woody's volume code (1.19.1) into 3.0.6 by Naris
			* Added volume setting cvar sm_saysounds_volume
			* Added individual sound volume override with cfg file key "volume"
	3.1.0 Jan 15, 2009
		* Modified by gH0sTy
		* Fixed broken anti-spam
	3.1.1 Feb 20, 2009
		* Modified by W]M[D FernFerret
		* Added following actions:
		* hit_by_train
		* drowned
		* backstab
		* crit_kill
		* 
		* Use these in your config the same as you would uber
		* Special thanks to BigPimpNick(psychonic) and Octo, for parts of this code
	3.1.2 Feb 26, 2009
		* Modified by -=|JFH|=-Naris
		* Don't precache sounds until they are played
		* Incorporated gametype.inc into this source
	3.1.3 Feb 27, 2009
		* Modified by psychonic
		* TF2 kill parameter names now use same weapon name as in game log (should clear up some confusion and fix some deflect_ kills not working)
		* Added headshot support for css, dods, and tf2 (action "kill", param "headshot")
		* Backstab is now (action "kill" param "backstab") to keep consistency
		* Fixed some cases where plugin was going through extra logic (was continuing kill logic after finding sound to play (like for headshot, train, etc.)
		* Fixed looking through tf2 logic for all games instead of just tf2
		* Fixed potential issue with leaving out "param" for some special events
	3.1.4 Apr 13, 2009
		* Modified by gH0sTy
		* Added IsValidClient function and replaced all IsClientInGame & !IsFakeClient with it
		* Changed all cvar names to sm_saysoundhe* to have them listed beneath each other for a cvarlist output and make it easier to recognize them as a Say Sounds related cvar
		* Added an "adult" param, if it's specified in saysounds.cfg it will, hide this sound from the sound menu, block the chat output for this trigger, announces the played sound as ADULT SOUND
		* Added a "delay" param, if it's specified in saysounds.cfg it will delay the sound by x seconds (max delay 60 seconds)
		* Added the possibility to reset the clients played sound count at round end (sm_saysoundhe_limit_sound_per_round)
		* Support for playing sound for the round_start event (action "roundstart" param "roundstart")
		* Added the possibility to restrict clients form playing a sound that was recently played (sm_saysoundhe_excl_last_sound)
		* Added the possibility to hide the chat output for a sound trigger word (sm_saysoundhe_block_trigger)
		* Colored Chat output
	3.1.5 Apr 30, 2009
		* Modified by gH0sTy
		* Added a listfile == INVALID_HANDLE check for runSoundEvent
		* Moved CheckJoin from OnClientAuthorized to OnClientPostAdminCheck as CheckJoin is done to early and listfile == INVALID_HANDLE (at least on my ZPS server)
		* Added TF event for waiting_begins/ends (action "setupstart", "setupend" param "setupstart", "setupend")
			and suddendeath_begin/end (action "suddendeathstart", "suddendeathend" param "suddendeathstart", "suddendeathend")
	3.1.6 Jun 08, 2009
		* Modified by edgecom
		* Added support for TF2's new unlockable weapons
			(huntsman , sniper rifle, back stab and ambassador)
	3.1.7 Jun 15, 2009
		* Modified by psychonic
		* Fixed headshot and backstab actions in TF2
		* Added "fall" action for TF2
		* Added suicide action for all games
	3.1.8 Jun 16, 2009
		* Modified by gH0sTy
		* Fixed suddendeath event
		* Fixed Setup end event, there's no setup start event so "setupstart" is not available anymore
		* Added delay support for event sounds
	3.1.9 Jun 25, 2009
		* Modified by psychoinc
		* Fixed translation error "Native "ReplyToCommand" reported: Language phrase "No matching client" not found"
	3.2.0 November 14, 2009
		* Modified by gH0sTy
		* Added round_start event for CS:S so the sound limit for players can be reset each round
		* Fixed some join sound bugs:
			* A join sound doesn't count to a players sound quota any more
			* A join sound doesn't affect the anti sound spam function
	3.2.1 April 30, 2010
		* Modified by Naris
		* Added ResourceManage to limit number of downloads per map

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
	sm_sound_showmenu 1		 Turns the Public Sound Menu on(1) or off(0)
	sm_saysounds_volume 1.0		 Global/Default Volume setting for Say Sounds (0.0 <= x <= 1.0).

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
				"volume" "0.5" // Specify volume for this specific sound
			}
			"wazza"  // Word trigger
			{
				"file"	"misc/wazza.wav" //"file" is always there, next is the filepath (always starts with "sound/")
				"admin"	"1"	//1 is admin only, 0 is anyone (defaults is 0)
				"adult" "1" //will announce the sound as ADULT SOUND, hide it from the sounds menu, block the chat output (defaults is 0)
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
				"volume" "0.5" 		// Specify volume for this specific sound
			}
			"STEAM_0:x:xxxxxx" // trigger for specific STEAM ID
			{
				"file"	"misc/myhouse.mp3" // name of sound to play when joining
				"exit"	"misc/goodbye.mp3" // name of sound to play when leaving
				"admin"	"0"
				"volume" "0.5" 		   // Specify volume for this specific sound
			}
			"somesong"  // Word trigger for Karaoke
			{
				"file"	"misc/somesong.wav"
				"karaoke" "somesong.cfg" // name of config file for karaoke lyrics
			}
			"doh"  // Minimum configuration for sounds
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
	* - [RiCK] Stokes aka. W]M[D FernFerret
*/

#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#undef REQUIRE_PLUGIN
#include <adminmenu>

// BEIGN MOD BY LAMDACORE
// extra memory usability for a lot of sounds.
// Uncomment the next line (w/#pragma) to add additional memory
//#pragma dynamic 65536 
#pragma dynamic 131072
// END MOD BY LAMDACORE

#pragma semicolon 1

#define PLUGIN_VERSION "3.2.1"

// Define countdown sounds for karaoke
#define TF2_ATTENTION	"vo/announcer_attention.wav"
#define TF2_20_SECONDS	"vo/announcer_begins_20sec.wav"
#define TF2_10_SECONDS	"vo/announcer_begins_10sec.wav"
#define TF2_5_SECONDS	"vo/announcer_begins_5sec.wav"
#define TF2_4_SECONDS	"vo/announcer_begins_4sec.wav"
#define TF2_3_SECONDS	"vo/announcer_begins_3sec.wav"
#define TF2_2_SECONDS	"vo/announcer_begins_2sec.wav"
#define TF2_1_SECOND	"vo/announcer_begins_1sec.wav"

#define HL2_ATTENTION	"npc/overwatch/radiovoice/attention.wav"
#define HL2_10_SECONDS	"npc/overwatch/cityvoice/fcitadel_10sectosingularity.wav"
#define HL2_5_SECONDS	"npc/overwatch/radiovoice/five.wav"
#define HL2_4_SECONDS	"npc/overwatch/radiovoice/four.wav"
#define HL2_3_SECONDS	"npc/overwatch/radiovoice/three.wav"
#define HL2_2_SECONDS	"npc/overwatch/radiovoice/two.wav"
#define HL2_1_SECOND	"npc/overwatch/radiovoice/one.wav"

enum sound_types { normal_sounds, admin_sounds, karaoke_sounds, all_sounds };

new Handle:cvarsaysoundversion = INVALID_HANDLE;
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
new Handle:cvarvolume = INVALID_HANDLE; // mod by Woody
/*####FernFerret####*/
new Handle:cvarshowsoundmenu = INVALID_HANDLE;
/*##################*/
new Handle:listfile = INVALID_HANDLE;
new Handle:hAdminMenu = INVALID_HANDLE;
new String:soundlistfile[PLATFORM_MAX_PATH] = "";
//##### Clientprefs #####
new Handle:g_ssplay_cookie = INVALID_HANDLE;
//#######################
new Handle:cvarsoundlimitround = INVALID_HANDLE;
new Handle:cvarexcludelastsound = INVALID_HANDLE;
new Handle:cvarblocktrigger = INVALID_HANDLE;
new restrict_playing_sounds[MAXPLAYERS+1];
new SndOn[MAXPLAYERS+1];
new SndCount[MAXPLAYERS+1];
new String:SndPlaying[MAXPLAYERS+1][PLATFORM_MAX_PATH];
new Float:LastSound[MAXPLAYERS+1];
new bool:firstSpawn[MAXPLAYERS+1];
new Float:globalLastSound = 0.0;
new Float:globalLastAdminSound = 0.0;
new String:LastPlayedSound[PLATFORM_MAX_PATH+1] = "";

// Variables for karaoke
new Handle:karaokeFile = INVALID_HANDLE;
new Handle:karaokeTimer = INVALID_HANDLE;
new Float:karaokeStartTime = 0.0;

// Variables to enable/disable advertisments plugin during karaoke
new Handle:cvaradvertisements = INVALID_HANDLE;
new bool:advertisements_enabled = false;

// Some event variable
new bool:suddendeath = false;

public Plugin:myinfo = 
{
	name = "Say Sounds (including Hybrid Edition)",
	author = "Hell Phoenix, -=|JFH|=-Naris, W]M[D FernFerret, LAMDACORE, Uberman, gH0sTy, Woody",
	description = "Say Sounds and Action Sounds packaged into one neat plugin! Welcome to the new day of SaySounds Hybrid!",
	version = PLUGIN_VERSION,
	url = "http://www.charliemaurice.com/plugins/"
};

/**
 * Description: Function to determine game/mod type
 */
#tryinclude <gametype>
#if !defined _gametype_included
    enum Game { undetected, tf2, cstrike, dod, hl2mp, insurgency, zps, l4d1, l4d2, other };
    stock Game:GameType = undetected;

    stock Game:GetGameType()
    {
        if (GameType == undetected)
        {
            new String:modname[30];
            GetGameFolderName(modname, sizeof(modname));
            if (StrEqual(modname,"cstrike",false))
                GameType=cstrike;
            else if (StrEqual(modname,"tf",false)) 
                GameType=tf2;
            else if (StrEqual(modname,"dod",false)) 
                GameType=dod;
            else if (StrEqual(modname,"hl2mp",false)) 
                GameType=hl2mp;
            else if (StrEqual(modname,"Insurgency",false)) 
                GameType=insurgency;
            else if (StrEqual(modname,"left4dead", false)) 
                GameType=l4d1;
            else if (StrEqual(modname,"left4dead2", false)) 
                GameType=l4d2;
            else if (StrEqual(modname,"zps",false)) 
                GameType=zps;
            else
                GameType=other;
        }
        return GameType;
    }
#endif

/**
 * Description: Manage precaching resources.
 */
#tryinclude "ResourceManager"
#if !defined _ResourceManager_included
	new Handle:cvarDownloadThreshold = INVALID_HANDLE;

	new g_iSoundCount                = 0;
	new g_iDownloadCount             = 0;
	new g_iRequiredCount             = 0;
	new g_iDownloadThreshold         = -1;
	new g_iPrevDownloadIndex         = 0;

	// Trie to hold precache status of sounds
	new Handle:g_precacheTrie = INVALID_HANDLE;

	stock PrepareSound(const String:sound[], bool:preload=false)
	{
    		// If the sound hasn't been played yet, precache it first
    		// :( IsSoundPrecached() doesn't work ):
    		//if (!IsSoundPrecached(sound))
    		new bool:value;
    		if (!GetTrieValue(g_precacheTrie, sound, value))
    		{
			PrecacheSound(sound,preload);
			SetTrieValue(g_precacheTrie, sound, true);
    		}
	}

	stock SetupSound(const String:sound[], download=1,
	                  bool:precache=false, bool:preload=false)
	{
		decl String:dl[PLATFORM_MAX_PATH+1];
		Format(dl, sizeof(dl), "sound/%s", sound);

		if (download && FileExists(dl))
		{
			g_iSoundCount++;
			if (download > 1 || g_iDownloadThreshold <= 0 ||
			    (g_iSoundCount > g_iPrevDownloadIndex &&
			     g_iDownloadCount < g_iDownloadThreshold + g_iRequiredCount))
			{
				AddFileToDownloadsTable(dl);
				g_iPrevDownloadIndex = g_iSoundCount;
				g_iDownloadCount++;
				if (download > 1)
					g_iRequiredCount++;
			}
		}

		if (precache)
			PrecacheSound(sound, preload);
	}
#endif

public OnPluginStart(){
	LoadTranslations("common.phrases");
	cvarsaysoundversion = CreateConVar("sm_saysounds_hybrid_version", PLUGIN_VERSION, "Say Sounds Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvarsoundenable = CreateConVar("sm_saysoundhe_enable","1","Turns Sounds On/Off",FCVAR_PLUGIN);
	cvarsoundwarn = CreateConVar("sm_saysoundhe_sound_warn","3","Number of sounds to warn person at (0 for no warnings)",FCVAR_PLUGIN);
	cvarsoundlimit = CreateConVar("sm_saysoundhe_sound_limit","5","Maximum sounds per person (0 for unlimited)",FCVAR_PLUGIN);
	cvarjoinexit = CreateConVar("sm_saysoundhe_join_exit","0","Play sounds when someone joins or exits the game",FCVAR_PLUGIN);
	cvarjoinspawn = CreateConVar("sm_saysoundhe_join_spawn","1","Wait until the player spawns before playing the join sound",FCVAR_PLUGIN);
	cvarspecificjoinexit = CreateConVar("sm_saysoundhe_specific_join_exit","1","Play sounds when specific steam ID joins or exits the game",FCVAR_PLUGIN);
	cvartimebetween = CreateConVar("sm_saysoundhe_time_between_sounds","4.5","Time between each sound trigger, 0.0 to disable checking",FCVAR_PLUGIN);
	cvaradmintime = CreateConVar("sm_saysoundhe_time_between_admin_sounds","4.5","Time between each admin sound trigger, 0.0 to disable checking",FCVAR_PLUGIN);
	cvaradminwarn = CreateConVar("sm_saysoundhe_sound_admin_warn","0","Number of sounds to warn admin at (0 for no warnings)",FCVAR_PLUGIN);
	cvaradminlimit = CreateConVar("sm_saysoundhe_sound_admin_limit","0","Maximum sounds per admin (0 for unlimited)",FCVAR_PLUGIN);
	cvarannounce = CreateConVar("sm_saysoundhe_sound_announce","0","Turns on announcements when a sound is played",FCVAR_PLUGIN);
	cvarsentence = CreateConVar("sm_saysoundhe_sound_sentence","0","When set, will trigger sounds if keyword is embedded in a sentence",FCVAR_PLUGIN);
	cvarlogging = CreateConVar("sm_saysoundhe_sound_logging","1","When set, will log sounds that are played",FCVAR_PLUGIN);
	cvarvolume = CreateConVar("sm_saysoundhe_saysounds_volume","1.0","Volume setting for Say Sounds (0.0 <= x <= 1.0)",FCVAR_PLUGIN,true,0.0,true,1.0); // mod by Woody
	cvarplayifclsndoff = CreateConVar("sm_saysoundhe_play_cl_snd_off","0","When set, allows clients that have turned their sounds off to trigger sounds (0=off | 1=on)",FCVAR_PLUGIN);
	cvarkaraokedelay = CreateConVar("sm_saysoundhe_karaoke_delay","15.0","Delay before playing a Karaoke song",FCVAR_PLUGIN);
	cvarsoundlimitround = CreateConVar("sm_saysoundhe_limit_sound_per_round", "0", "If set, sm_saysoundhe_sound_limit is the limit per round instead of per map", FCVAR_PLUGIN);
	cvarexcludelastsound = CreateConVar("sm_saysoundhe_excl_last_sound", "0", "If set, don't allow to play a sound that was recently played", FCVAR_PLUGIN);
	cvarblocktrigger = CreateConVar("sm_saysoundhe_block_trigger", "0", "If set, block the sound trigger to be displayed in the chat window", FCVAR_PLUGIN);

	#if !defined _ResourceManager_included
    		cvarDownloadThreshold = CreateConVar("sm_saysoundhe_download_threshold", "-1", "Number of sounds to download per map start (-1=unlimited).", FCVAR_PLUGIN);
	#endif

	/*####FernFerret####*/
	// This is the Variable that will enable or disable the sound menu to public users, Admin users will always have
	// access to their menus, From the admin menu it is a toggle variable
	cvarshowsoundmenu = CreateConVar("sm_saysoundhe_showmenu","1","1 To show menu to users, 0 to hide menu from users (admins excluded)",FCVAR_PLUGIN);
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
	
	//Load Translations
	//LoadTranslations("saysounds.hybrid.phrases");

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
		HookEvent("teamplay_round_start", Event_RoundStart);
		//HookEvent("teamplay_round_active", Event_SetupStart);
		HookEvent("teamplay_setup_finished", Event_SetupEnd);
		HookEvent("teamplay_round_stalemate", Event_SuddenDeathStart);
		HookEvent("teamplay_round_win", Event_RoundWin);
	}
	else if (GetGameType() == dod){
		HookEvent("player_hurt", Event_Hurt);
		HookEvent("dod_round_start", Event_RoundStart);
	}
	else if (GetGameType() == zps){
		HookEvent("game_round_restart", Event_RoundStart);
	}
	else if (GetGameType() == cstrike){
		HookEvent("round_start", Event_RoundStart);
	}
	else if (GetGameType() == other){
		HookEvent("round_start", Event_RoundStart);
	}
	/*##################*/

	/* Account for late loading */
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
		OnAdminMenuReady(topmenu);
	
	// Update the Plugin Version cvar
	SetConVarString(cvarsaysoundversion, PLUGIN_VERSION, true, true);
}

public IsValidClient (client)
{
	if (client == 0)
		return false;
	
	if (!IsClientConnected(client))
		return false;
	
	if (IsFakeClient(client))
		return false;
	
	if (!IsClientInGame(client))
		return false;
	
	return true;
}

ResetClientSoundCount(){
	for (new i = 1; i <= MAXPLAYERS; i++)
		SndCount[i] = 0;
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
	/*// Send to all clients, will update in future to add To client/To Team/To All
	new clientlist[MAXPLAYERS+1];
	new clientcount = 0;
	new playersconnected = GetMaxClients();
	for (new i = 1; i <= playersconnected; i++){
		if(SndOn[i] && IsValidClient(i)){
			clientlist[clientcount++] = i;
		}
	}*/
	
	if(listfile == INVALID_HANDLE)
		return false;
	
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
			KvGetString(listfile, "param",extraparam,sizeof(extraparam),action);
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
				// Debug line for new action sounds -- FernFerret
				//PrintToChatAll("I found action: %s",action);
				if (generated <= random)
				{
					PrepareSound(location, false);
					//### Delay
					new Float:delay = KvGetFloat(listfile, "delay", 0.1);
					if(delay < 0.1){
					delay = 0.1;
					}else if (delay > 60.0){
						delay = 60.0;
					}
					
					new Handle:pack;
					CreateDataTimer(delay,runSoundEventTimer,pack, TIMER_FLAG_NO_MAPCHANGE);
					WritePackString(pack, location);
					ResetPack(pack);
					//EmitSound(clientlist, clientcount, location);
				}
				return true;
			}
		}
	} while (KvGotoNextKey(listfile));
	return false;
}

public Action:runSoundEventTimer(Handle:timer,Handle:pack){
	decl String:location[PLATFORM_MAX_PATH+1];
	// Send to all clients, will update in future to add To client/To Team/To All
	new clientlist[MAXPLAYERS+1];
	new clientcount = 0;
	new playersconnected = GetMaxClients();
	for (new i = 1; i <= playersconnected; i++){
		if(SndOn[i] && IsValidClient(i)){
			clientlist[clientcount++] = i;
		}
	}
	ReadPackString(pack, location, sizeof(location));
	EmitSound(clientlist, clientcount, location);
}

// Event section, place events here
/*public Action:Event_SetupStart(Handle:event,const String:name[],bool:dontBroadcast){
	setupphase = true;
	runSoundEvent(event,"setupstart","setupstart");
	return Plugin_Continue;
}*/

public Action:Event_SetupEnd(Handle:event,const String:name[],bool:dontBroadcast){
	runSoundEvent(event,"setupend","setupend");
	return Plugin_Continue;
}

public Action:Event_SuddenDeathStart(Handle:event,const String:name[],bool:dontBroadcast){
	suddendeath = true;
	runSoundEvent(event,"suddendeathstart","suddendeathstart");
	return Plugin_Continue;
}

public Action:Event_RoundWin(Handle:event,const String:name[],bool:dontBroadcast){
	if(suddendeath){
		runSoundEvent(event,"suddendeathend","suddendeathend");
		suddendeath =false;
	}
	return Plugin_Continue;
}

public Action:Event_RoundStart(Handle:event,const String:name[],bool:dontBroadcast){
	if(suddendeath){
		runSoundEvent(event,"suddendeathend","suddendeathend");
		suddendeath = false;
	}else{
		runSoundEvent(event,"roundstart","roundstart");
	}
	if (GetConVarBool(cvarsoundlimitround)){
		ResetClientSoundCount();
	}
	return Plugin_Continue;
}

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
	// psychonic ,octo, FernFerret
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim   = GetClientOfUserId(GetEventInt(event, "userid"));
	if (attacker == victim)
	{
		runSoundEvent(event,"suicide","suicide");
		return Plugin_Continue;
	}
	else
	{
		GetEventString(event, "weapon_logclassname",wepstring,PLATFORM_MAX_PATH+1);
		if (GetGameType() == tf2)
		{
			new custom_kill = GetEventInt(event, "customkill");
			if (custom_kill == 1)
			{
				runSoundEvent(event,"headshot","headshot");
				return Plugin_Continue;
			}
			if (custom_kill == 2)
			{
				runSoundEvent(event,"backstab","backstab");
				return Plugin_Continue;
			}
			new bits = GetEventInt(event,"damagebits");
			if (bits & 1048576 && attacker > 0)
			{
				runSoundEvent(event,"crit_kill","crit_kill");
				return Plugin_Continue;
			}
			if (bits == 16 && victim > 0)
			{
				runSoundEvent(event,"hit_by_train","hit_by_train");
				return Plugin_Continue;
			}
			if (bits == 16384 && victim > 0)
			{
				runSoundEvent(event,"drowned","drowned");
				return Plugin_Continue;
			}
			if (bits & 32 && victim > 0)
			{
				runSoundEvent(event,"fall","fall");
				return Plugin_Continue;
			}

			GetEventString(event, "weapon_logclassname",wepstring,PLATFORM_MAX_PATH+1);
		}
		else if (GetGameType() == cstrike)
		{
			new headshot = 0;
			headshot = GetEventBool(event, "headshot");
			if (headshot == 1)
			{
				runSoundEvent(event,"kill","headshot");
				return Plugin_Continue;
			}
			GetEventString(event, "weapon",wepstring,PLATFORM_MAX_PATH+1);
		}
		else
		{
			GetEventString(event, "weapon",wepstring,PLATFORM_MAX_PATH+1);
		}
		
		runSoundEvent(event,"kill",wepstring);
		
		return Plugin_Continue;
	}
}

public Action:Event_Hurt(Handle:event,const String:name[],bool:dontBroadcast)
{
	new headshot   = (GetEventInt(event, "health") == 0 && GetEventInt(event, "hitgroup") == 1);
	
	if (headshot) {
		runSoundEvent(event,"kill","headshot");
	}
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
	
	LastPlayedSound = "";
	globalLastSound = 0.0;
	globalLastAdminSound = 0.0;
	for (new i = 1; i <= MAXPLAYERS; i++) {
		SndCount[i] = 0;
		LastSound[i] = 0.0;
	}
	
	#if !defined _ResourceManager_included
    		g_iDownloadThreshold = GetConVarInt(cvarDownloadThreshold);

		// Setup trie to keep track of precached sounds
		if (g_precacheTrie == INVALID_HANDLE)
	    		g_precacheTrie = CreateTrie();
		else
	    		ClearTrie(g_precacheTrie);
	#endif

	/* Delay precaching the karaoke countdown sounds
         * until they are actually used.
         *
	if (GetGameType() == tf2) {
		PrecacheSound(TF2_ATTENTION, true);
		PrecacheSound(TF2_20_SECONDS, true);
		PrecacheSound(TF2_10_SECONDS, true);
		PrecacheSound(TF2_5_SECONDS, true);
		PrecacheSound(TF2_4_SECONDS, true);
		PrecacheSound(TF2_3_SECONDS, true);
		PrecacheSound(TF2_2_SECONDS, true);
		PrecacheSound(TF2_1_SECOND, true);
	} else {
		PrecacheSound(HL2_ATTENTION, true);
		PrecacheSound(HL2_10_SECONDS, true);
		PrecacheSound(HL2_5_SECONDS, true);
		PrecacheSound(HL2_4_SECONDS, true);
		PrecacheSound(HL2_3_SECONDS, true);
		PrecacheSound(HL2_2_SECONDS, true);
		PrecacheSound(HL2_1_SECOND, true);
	}
	*/

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
					if (filelocation[0] != '\0')
						SetupSound(filelocation, download, false, false);
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
		/*if(!GetConVarBool(cvarjoinspawn)){
			CheckJoin(client, auth);
		}*/
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
	
	if(!GetConVarBool(cvarjoinspawn)){
		decl String:auth[64];
		GetClientAuthString(client,auth,63);
		CheckJoin(client, auth);
	}
}
//#######################

public CheckJoin(client, const String:auth[]){
	/*if(listfile == INVALID_HANDLE)
		return;*/
	if(GetConVarBool(cvarspecificjoinexit)){
		decl String:filelocation[PLATFORM_MAX_PATH+1];
		KvRewind(listfile);
		if (KvJumpToKey(listfile, auth)){
			filelocation[0] = '\0';
			KvGetString(listfile, "join", filelocation, sizeof(filelocation), "");
			if (filelocation[0] != '\0'){
				Send_Sound(client,filelocation, "", true);
				SndCount[client] = 0;
				return;
			}else if (Submit_Sound(client,"")){
				SndCount[client] = 0;
				return;
			}
		}
	}

	if(GetConVarBool(cvarjoinexit) || GetConVarBool(cvarjoinspawn)){
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
					PrintToChat(client,"\x04[Say Sounds]\x01 Sounds Disabled");
					//PrintToChat(client,"\x04[Say Sounds] \x01%t", "SoundsDisabled", client);
				}else{
					// Update cookie
					SetClientCookie(client, g_ssplay_cookie, "on");
					SndOn[client] = 1;
					PrintToChat(client,"\x04[Say Sounds]\x01 Sounds Enabled");
					//PrintToChat(client,"\x04[Say Sounds] \x01%t", "SoundsEnabled", client);
				}
				return Plugin_Handled;
		}else if(strcmp(speech[startidx],"!soundlist",false) == 0 ||
			strcmp(speech[startidx],"soundlist",false) == 0){
				if(GetConVarInt(cvarshowsoundmenu) == 1){
					Sound_Menu(client,normal_sounds);
				}else{
					List_Sounds(client);
					PrintToChat(client,"\x04[Say Sounds]\x01 Check your console for a list of sound triggers");
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
		new bool:adult;
		new bool:trigfound;
		decl String:buffer[255];
		do{
			KvGetSectionName(listfile, buffer, sizeof(buffer));
			adult = bool:KvGetNum(listfile, "adult",0);
			if ((sentence && StrContains(speech[startidx],buffer,false) >= 0) ||
				(strcmp(speech[startidx],buffer,false) == 0)){
					Submit_Sound(client,buffer);
					trigfound = true;
					break;
			}
		} while (KvGotoNextKey(listfile));

		if(GetConVarBool(cvarblocktrigger) && trigfound && !StrEqual(LastPlayedSound, buffer, false)){
			return Plugin_Handled;
		}else if(adult && trigfound){
			return Plugin_Handled;
		}else{
			return Plugin_Continue;
		}
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
					PrintToChat(client,"\x04[Say Sounds]\x01 Sounds Disabled");
					//PrintToChat(client,"\x04[Say Sounds] \x01%t", "SoundsDisabled", client);
				}else{
					// Update cookie
					SetClientCookie(client, g_ssplay_cookie, "on");
					SndOn[client] = 1;
					PrintToChat(client,"\x04[Say Sounds]\x01 Sounds Enabled");
					//PrintToChat(client,"\x04[Say Sounds] \x01%t", "SoundsEnabled", client);
				}
				return Plugin_Handled;
		}else if(strcmp(speech[startidx],"!soundlist",false ||
			strcmp(speech[startidx],"soundlist",false) == 0) == 0){
			if(GetConVarInt(cvarshowsoundmenu) == 1){
				Sound_Menu(client,normal_sounds);
			}else{
				List_Sounds(client);
				PrintToChat(client,"\x04[Say Sounds]\x01 Check your console for a list of sound triggers");
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
		new bool:adult;
		new bool:trigfound;
		new bool:sentence = GetConVarBool(cvarsentence);
		decl String:buffer[255];
		do{
			KvGetSectionName(listfile, buffer, sizeof(buffer));
			adult = bool:KvGetNum(listfile, "adult",0);
			if ((sentence && StrContains(speech[startidx],buffer,false) >= 0) ||
				(strcmp(speech[startidx],buffer,false) == 0)){
					Submit_Sound(client,buffer);
					trigfound = true;
					break;
			}
		} while (KvGotoNextKey(listfile));

		if(GetConVarBool(cvarblocktrigger) && trigfound && !StrEqual(LastPlayedSound, buffer, false)){
			return Plugin_Handled;
		}else if(adult && trigfound){
			return Plugin_Handled;
		}else{
			return Plugin_Continue;
		}
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

Send_Sound(client, const String:filelocation[], const String:name[], bool:joinsound=false)
{
	new tmp_joinsound;
	
	new adminonly = KvGetNum(listfile, "admin",0);
	new adultonly = KvGetNum(listfile, "adult",0);
	new singleonly = KvGetNum(listfile, "single",0);
	/*####FernFerret####*/
	// Added the action only param to the pack
	new actiononly = KvGetNum(listfile, "actiononly",0);
	/*##################*/
	if (joinsound){
		tmp_joinsound = 1;
	}else{
		tmp_joinsound = 0;
	}

	decl String:timebuf[64];
	KvGetString(listfile,"duration",timebuf,sizeof(timebuf));
	new Float:duration = Convert_Time(timebuf);

	new Float:defVol = GetConVarFloat(cvarvolume);
	new Float:volume = KvGetFloat(listfile, "volume", defVol);
	if (volume == 0.0 || volume == 1.0) {
		volume = defVol; // do this check because of possibly "stupid" values in cfg file
	}
	
	//### Delay
	new Float:delay = KvGetFloat(listfile, "delay", 0.1);
	if(delay < 0.1){
		delay = 0.1;
	}else if (delay > 60.0){
		delay = 60.0;
	}

	new Handle:pack;
	CreateDataTimer(delay,Play_Sound_Timer,pack, TIMER_FLAG_NO_MAPCHANGE);
	WritePackCell(pack, client);
	WritePackCell(pack, adminonly);
	WritePackCell(pack, adultonly);
	WritePackCell(pack, singleonly);
	/*####FernFerret####*/
	WritePackCell(pack, actiononly);
	/*##################*/
	WritePackFloat(pack, duration);
	WritePackFloat(pack, volume); // mod by Woody
	WritePackString(pack, filelocation);
	WritePackString(pack, name);
	WritePackCell(pack, tmp_joinsound);
	ResetPack(pack);
}

public Action:Play_Sound_Timer(Handle:timer,Handle:pack){
	decl String:filelocation[PLATFORM_MAX_PATH+1];
	decl String:name[PLATFORM_MAX_PATH+1];
	new client = ReadPackCell(pack);
	new adminonly = ReadPackCell(pack);
	new adultonly = ReadPackCell(pack);
	new singleonly = ReadPackCell(pack);
	/*####FernFerret####*/
	new actiononly = ReadPackCell(pack);
	/*##################*/
	new Float:duration = ReadPackFloat(pack);
	new Float:volume = ReadPackFloat(pack); // mod by Woody
	ReadPackString(pack, filelocation, sizeof(filelocation));
	ReadPackString(pack, name , sizeof(name));
	new joinsound = ReadPackCell(pack);

	/*####FernFerret####*/
	// Checks for Action Only sounds and messages user telling them why they can't play an action only sound
	if (IsValidClient(client))
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
	if (IsValidClient(client))
	{
		new AdminId:aid = GetUserAdmin(client);
		isadmin = (aid != INVALID_ADMIN_ID) && GetAdminFlag(aid, Admin_Generic, Access_Effective);
		if(adminonly && !isadmin){
			PrintToChat(client,"\x04[Say Sounds]\x01 Sorry, you are not authorized to play this sound!");
			return Plugin_Handled;
		}
	}

	new Float:thetime = GetGameTime();
	if (LastSound[client] >= thetime){
		if(IsValidClient(client)){
			PrintToChat(client,"\x04[Say Sounds]\x01 Please don't spam the sounds!");
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
			if(IsValidClient(client)){
				PrintToChat(client,"\x04[Say Sounds]\x01 Please don't spam the admin sounds!");
			}
			return Plugin_Handled;
		}

		adminTime = GetConVarFloat(cvaradmintime);
		if (adminTime < duration)
			adminTime = duration;
	}
	
	if(GetConVarBool(cvarexcludelastsound) && IsValidClient(client) && StrEqual(LastPlayedSound, name, false)){
		PrintToChat(client, "\x04[Say Sounds]\x01 Sorry, this sound was recently played.");
		return Plugin_Handled;
	}

	new soundLimit = isadmin ? GetConVarInt(cvaradminlimit) : GetConVarInt(cvarsoundlimit);	
	if (soundLimit <= 0 || SndCount[client] < soundLimit){
		if (globalLastSound < thetime){
			if (joinsound == 1){
				SndCount[client] = 0;
			}else{
				SndCount[client]++;
				LastSound[client] = thetime + waitTime;
				globalLastSound   = thetime + duration;
			}
			

			if (adminonly)
				globalLastAdminSound = thetime + adminTime;

			if (singleonly){
				if(SndOn[client] && IsValidClient(client)){
					PrepareSound(filelocation, false);
					EmitSoundToClient(client, filelocation, .volume=volume);
					strcopy(SndPlaying[client], sizeof(SndPlaying[]), filelocation);
				}
			}else{
				Play_Sound(filelocation, volume);
				LastPlayedSound = name;
				if (name[0] && IsValidClient(client)){
					if (GetConVarBool(cvarannounce)){
						if(adultonly){
							PrintToChatAll("\x04%N\x01 played \x04ADULT SOUND", client);
						}else{
							PrintToChatAll("\x04%N\x01 played \x04%s", client, name);
						}
					}
					if (GetConVarBool(cvarlogging)){
						LogToGame("[Say Sounds] \x04%s%N\x01 played \x04%s%s(%s)", isadmin ? "Admin " : "", client,
							   adminonly ? "admin sound " : "", name, filelocation);
					}
				}else if (GetConVarBool(cvarlogging)){
					LogToGame("\x04[Say Sounds]\x01 played \x04%s", filelocation);
				}
			}
		}
		else if(IsValidClient(client)){
			PrintToChat(client,"\x04[Say Sounds]\x01 Please don't spam the sounds!");
			return Plugin_Handled;
		}
	}

	if(soundLimit > 0 && IsValidClient(client)){
		if (SndCount[client] > soundLimit){
			PrintToChat(client,"\x04[Say Sounds]\x01 Sorry, you have reached your sound quota!");
		}else if (SndCount[client] == soundLimit){
			PrintToChat(client,"\x04[Say Sounds]\x01 You have no sounds left to use!");
			SndCount[client]++; // Increment so we get the sorry message next time.
		}else{
			new soundWarn = isadmin ? GetConVarInt(cvaradminwarn) : GetConVarInt(cvarsoundwarn);	
			if (soundWarn <= 0 || SndCount[client] >= soundWarn){
				new numberleft = (soundLimit -  SndCount[client]);
				if (numberleft == 1)
					PrintToChat(client,"\x04[Say Sounds]\x01 You only have \x04%d \x01sound left to use!",numberleft);
				else
					PrintToChat(client,"\x04[Say Sounds]\x01 You only have \x04%d \x01sounds left to use!",numberleft);
			}
		}
	}
	return Plugin_Handled;
}

Play_Sound(const String:filelocation[], Float:volume)
{
	new clientlist[MAXPLAYERS+1];
	new clientcount = 0;
	new playersconnected = GetMaxClients();
	for (new i = 1; i <= playersconnected; i++){
		if(SndOn[i] && IsValidClient(i)){
			clientlist[clientcount++] = i;
			strcopy(SndPlaying[i], sizeof(SndPlaying[]), filelocation);
		}
	}
	if (clientcount){
		PrepareSound(filelocation, false);
		EmitSound(clientlist, clientcount, filelocation, .volume=volume);
	}
}

public Load_Karaoke(client, const String:filelocation[], const String:name[], const String:karaoke[]){
	new adminonly = KvGetNum(listfile, "admin", 1); // Karaoke sounds default to admin only
	new bool:isadmin = false;
	if (IsValidClient(client))
	{
		new AdminId:aid = GetUserAdmin(client);
		isadmin = (aid != INVALID_ADMIN_ID) && GetAdminFlag(aid, Admin_Generic, Access_Effective);
		if(adminonly && !isadmin){
			PrintToChat(client,"\x04[Say Sounds]\x01 Sorry, you are not authorized to play this sound!");
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
			strcopy(announcement, sizeof(announcement), TF2_ATTENTION);
		}else{
			strcopy(announcement, sizeof(announcement), HL2_ATTENTION);
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
				strcopy(announcement, sizeof(announcement), HL2_10_SECONDS);
			} else if (time == 5.0){
				strcopy(announcement, sizeof(announcement), HL2_5_SECONDS);
			} else if (time == 4.0){
				strcopy(announcement, sizeof(announcement), HL2_4_SECONDS);
			} else if (time == 3.0){
				strcopy(announcement, sizeof(announcement), HL2_3_SECONDS);
			} else if (time == 2.0){
				strcopy(announcement, sizeof(announcement), HL2_2_SECONDS);
			} else if (time == 1.0){
				strcopy(announcement, sizeof(announcement), HL2_1_SECOND);
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
			Play_Sound(announcement, 1.0);
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
		// Convert from mm:ss to seconds
		return (StringToFloat(part)*60.0) +
			StringToFloat(buffer[pos]);
	}
}

Karaoke_Message(const String:text[3][]){
	new playersconnected = GetMaxClients();
	for (new i = 1; i <= playersconnected; i++){
		if(SndOn[i] && IsValidClient(i)){
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
		if(SndOn[i] && IsValidClient(i)){
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
		if(client !=0){
			ReplyToCommand(client, "[Say Sounds] Quota has been reset for all players");
		}
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
					new bool:adult = bool:KvGetNum(listfile, "adult",0);
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
							if(!adult){
								Format(num,3,"%d",count);
								AddMenuItem(soundmenu,num,buffer);
								count++;
							}
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

	#if !defined _ResourceManager_included
		if (g_iPrevDownloadIndex >= g_iSoundCount ||
		    g_iDownloadCount < g_iDownloadThreshold)
		{
		    g_iPrevDownloadIndex = 0;
		}

		g_iDownloadCount     = 0;
		g_iSoundCount        = 0;
	#endif
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
