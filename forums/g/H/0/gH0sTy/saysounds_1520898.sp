/*
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
	sm_saysoundhe_interrupt_sound 1		 If set, interrupt the current sound when a new start
	sm_saysoundhe_filter_if_dead 0		 If set, alive players do not hear sounds triggered by dead players

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

*/

#include <sourcemod>
#include <sdktools>
#include <clientprefs>

// *** Sound Info Library ***
#include <soundlib>

#undef REQUIRE_PLUGIN
#include <adminmenu>

// BEIGN MOD BY LAMDACORE
// extra memory usability for a lot of sounds.
// Uncomment the next line (w/#pragma) to add additional memory
//#pragma dynamic 65536 
#pragma dynamic 131072
// END MOD BY LAMDACORE

#pragma semicolon 1

#define PLUGIN_VERSION "4.0.3"

//*****************************************************************
//	------------------------------------------------------------- *
//			*** Defines for checkClientCookies ***				  *
//	------------------------------------------------------------- *
//*****************************************************************
#define CHK_CHATMSG		1
#define CHK_SAYSOUNDS	2
#define CHK_EVENTS		3
#define CHK_KARAOKE		4
#define CHK_BANNED		5
#define CHK_GREETED		6

//*****************************************************************
//	------------------------------------------------------------- *
//			*** Define countdown sounds for karaoke ***			  *
//	------------------------------------------------------------- *
//*****************************************************************
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

//*****************************************************************
//	------------------------------------------------------------- *
//					*** Cvar Handles ***						  *
//	------------------------------------------------------------- *
//*****************************************************************
new Handle:cvarsaysoundversion		= INVALID_HANDLE;
new Handle:cvarsoundenable			= INVALID_HANDLE;
new Handle:cvarsoundlimit			= INVALID_HANDLE;
new Handle:cvarsoundwarn			= INVALID_HANDLE;
new Handle:cvarjoinexit				= INVALID_HANDLE;
new Handle:cvarjoinspawn			= INVALID_HANDLE;
new Handle:cvarspecificjoinexit		= INVALID_HANDLE;
new Handle:cvartimebetween			= INVALID_HANDLE;
new Handle:cvaradmintime			= INVALID_HANDLE;
new Handle:cvaradminwarn			= INVALID_HANDLE;
new Handle:cvaradminlimit			= INVALID_HANDLE;
new Handle:cvarannounce				= INVALID_HANDLE;
new Handle:cvaradult				= INVALID_HANDLE;
new Handle:cvarsentence				= INVALID_HANDLE;
new Handle:cvarlogging				= INVALID_HANDLE;
new Handle:cvarplayifclsndoff		= INVALID_HANDLE;
new Handle:cvarkaraokedelay			= INVALID_HANDLE;
new Handle:cvarvolume				= INVALID_HANDLE; // mod by Woody
new Handle:cvarsoundlimitround		= INVALID_HANDLE;
new Handle:cvarexcludelastsound		= INVALID_HANDLE;
new Handle:cvarblocktrigger			= INVALID_HANDLE;
new Handle:cvarinterruptsound		= INVALID_HANDLE;
new Handle:cvarfilterifdead			= INVALID_HANDLE;
//####FernFerret####/
new Handle:cvarshowsoundmenu		= INVALID_HANDLE;
//##################/
new Handle:listfile					= INVALID_HANDLE;
new Handle:hAdminMenu				= INVALID_HANDLE;
new Handle:g_hSoundCountDB			= INVALID_HANDLE;
new String:soundlistfile[PLATFORM_MAX_PATH] = "";

//*****************************************************************
//	------------------------------------------------------------- *
//					*** Client Peferences ***					  *
//	------------------------------------------------------------- *
//*****************************************************************
//new Handle:g_ssgeneral_cookie = INVALID_HANDLE;	// Cookie for storing clints general saysound setting (ON/OFF)
new Handle:g_sssaysound_cookie		= INVALID_HANDLE;	// Cookie for storing clints saysound setting (ON/OFF)
new Handle:g_ssevents_cookie		= INVALID_HANDLE;	// Cookie for storing clients eventsound setting (ON/OFF)
new Handle:g_sschatmsg_cookie		= INVALID_HANDLE;	// Cookie for storing clients chat message setting (ON/OFF)
new Handle:g_sskaraoke_cookie		= INVALID_HANDLE; // Cookie for storing clients karaoke setting (ON/OFF)
new Handle:g_ssban_cookie			= INVALID_HANDLE;		// Cookie for storing if client is banned from using saysiunds
new Handle:g_ssgreeted_cookie		= INVALID_HANDLE;	// Cookie for storing if we've played the welcome sound to the client
new Handle:g_dbClientprefs			= INVALID_HANDLE;	// Handle for the clientprefs SQLite DB

//*****************************************************************
//	------------------------------------------------------------- *
//						*** Variables ***						  *
//	------------------------------------------------------------- *
//*****************************************************************
//new restrict_playing_sounds[MAXPLAYERS+1];
//new SndOn[MAXPLAYERS+1];
new SndCount[MAXPLAYERS+1];
new String:SndPlaying[MAXPLAYERS+1][PLATFORM_MAX_PATH];
//new Float:LastSound[MAXPLAYERS+1];
new bool:firstSpawn[MAXPLAYERS+1];
new Float:globalLastSound = 0.0;
new Float:globalLastAdminSound = 0.0;
new String:LastPlayedSound[PLATFORM_MAX_PATH+1] = "";
new String:g_SaySoundErrorLog[PLATFORM_MAX_PATH+1];
new bool:hearalive = true;

// Variables for karaoke
new Handle:karaokeFile = INVALID_HANDLE;
new Handle:karaokeTimer = INVALID_HANDLE;
new Float:karaokeStartTime = 0.0;

// Variables to enable/disable advertisments plugin during karaoke
new Handle:cvaradvertisements = INVALID_HANDLE;
new bool:advertisements_enabled = false;

// Some event variable
//new bool:TF2waiting = false;
new WinningTeam;
//	Kill Event: If someone kills a few clients with a crit
//				make sure he won't get spammed with the corresponding sound
new bool:g_bPlayedEvent2Client[MAXPLAYERS+1] = false;

//*****************************************************************
//	------------------------------------------------------------- *
//						*** Plugin Info ***						  *
//	------------------------------------------------------------- *
//*****************************************************************
public Plugin:myinfo = 
{
	name = "Say Sounds (including Hybrid Edition)",
	author = "Hell Phoenix|Naris|FernFerret|Uberman|psychonic|edgecom|woody|Miraculix|gH0sTy",
	description = "Say Sounds and Action Sounds packaged into one neat plugin! Welcome to the new day of SaySounds Hybrid!",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=82220"
};


//*****************************************************************
//	------------------------------------------------------------- *
//					*** Get the game/mod type ***				  *
//	------------------------------------------------------------- *
//*****************************************************************
#tryinclude <gametype>
#if !defined _gametype_included
    enum Game { undetected, tf2, cstrike, dod, hl2mp, insurgency, zps, l4d, l4d2, other };
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
                GameType=l4d;
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

//*****************************************************************
//	------------------------------------------------------------- *
//				*** Manage precaching resources ***				  *
//	------------------------------------------------------------- *
//*****************************************************************
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

//*****************************************************************
//	------------------------------------------------------------- *
//						*** Plugin Start ***					  *
//	------------------------------------------------------------- *
//*****************************************************************
public OnPluginStart(){

	
	if(GetGameType() == l4d2 || GetGameType() == l4d)
		SetFailState("The Left 4 Dead series is not supported!");
	
	// ***Load Translations **
	LoadTranslations("common.phrases");
	LoadTranslations("saysoundhe.phrases");
	
	// *** Creating the Cvars ***
	cvarsaysoundversion = CreateConVar("sm_saysounds_hybrid_version", PLUGIN_VERSION, "Say Sounds Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvarsoundenable = CreateConVar("sm_saysoundhe_enable","1","Turns Sounds On/Off",FCVAR_PLUGIN);
	cvarsoundwarn = CreateConVar("sm_saysoundhe_sound_warn","3","Number of sounds to warn person at (0 for no warnings)",FCVAR_PLUGIN);
	cvarsoundlimit = CreateConVar("sm_saysoundhe_sound_limit","5","Maximum sounds per person (0 for unlimited)",FCVAR_PLUGIN);
	cvarjoinexit = CreateConVar("sm_saysoundhe_join_exit","0","Play sounds when someone joins or exits the game",FCVAR_PLUGIN);
	cvarjoinspawn = CreateConVar("sm_saysoundhe_join_spawn","1","Wait until the player spawns before playing the join sound",FCVAR_PLUGIN);
	cvarspecificjoinexit = CreateConVar("sm_saysoundhe_specific_join_exit","1","Play sounds when specific steam ID joins or exits the game",FCVAR_PLUGIN);
	cvartimebetween = CreateConVar("sm_saysoundhe_time_between_sounds","4.5","Time between each sound trigger, 0.0 to disable checking",FCVAR_PLUGIN);
	cvaradmintime = CreateConVar("sm_saysoundhe_time_between_admin_sounds","4.5","Time between each admin sound trigger, 0.0 to disable checking for admin sounds \nSet to -1 to completely bypass the soundspam protection for admins",FCVAR_PLUGIN);
	cvaradminwarn = CreateConVar("sm_saysoundhe_sound_admin_warn","0","Number of sounds to warn admin at (0 for no warnings)",FCVAR_PLUGIN);
	cvaradminlimit = CreateConVar("sm_saysoundhe_sound_admin_limit","0","Maximum sounds per admin (0 for unlimited)",FCVAR_PLUGIN);
	cvarannounce = CreateConVar("sm_saysoundhe_sound_announce","1","Turns on announcements when a sound is played",FCVAR_PLUGIN);
	cvaradult = CreateConVar("sm_saysoundhe_adult_announce","0","Announce played adult sounds? | 0 = off 1 = on",FCVAR_PLUGIN);
	cvarsentence = CreateConVar("sm_saysoundhe_sound_sentence","0","When set, will trigger sounds if keyword is embedded in a sentence",FCVAR_PLUGIN);
	cvarlogging = CreateConVar("sm_saysoundhe_sound_logging","0","When set, will log sounds that are played",FCVAR_PLUGIN);
	cvarvolume = CreateConVar("sm_saysoundhe_saysounds_volume","1.0","Volume setting for Say Sounds (0.0 <= x <= 1.0)",FCVAR_PLUGIN,true,0.0,true,1.0); // mod by Woody
	cvarplayifclsndoff = CreateConVar("sm_saysoundhe_play_cl_snd_off","0","When set, allows clients that have turned their sounds off to trigger sounds (0=off | 1=on)",FCVAR_PLUGIN);
	cvarkaraokedelay = CreateConVar("sm_saysoundhe_karaoke_delay","15.0","Delay before playing a Karaoke song",FCVAR_PLUGIN);
	cvarsoundlimitround = CreateConVar("sm_saysoundhe_limit_sound_per_round", "0", "If set, sm_saysoundhe_sound_limit is the limit per round instead of per map", FCVAR_PLUGIN);
	cvarexcludelastsound = CreateConVar("sm_saysoundhe_excl_last_sound", "0", "If set, don't allow to play a sound that was recently played", FCVAR_PLUGIN);
	cvarblocktrigger = CreateConVar("sm_saysoundhe_block_trigger", "0", "If set, block the sound trigger to be displayed in the chat window", FCVAR_PLUGIN);
	cvarinterruptsound = CreateConVar("sm_saysoundhe_interrupt_sound", "0", "If set, interrupt the current sound when a new start", FCVAR_PLUGIN);
	cvarfilterifdead = CreateConVar("sm_saysoundhe_filter_if_dead", "0", "If set, alive players do not hear sounds triggered by dead players", FCVAR_PLUGIN);

	#if !defined _ResourceManager_included
    		cvarDownloadThreshold = CreateConVar("sm_saysoundhe_download_threshold", "-1", "Number of sounds to download per map start (-1=unlimited).", FCVAR_PLUGIN);
	#endif

	//####FernFerret####//
	// This is the Variable that will enable or disable the sound menu to public users, Admin users will always have
	// access to their menus, From the admin menu it is a toggle variable
	cvarshowsoundmenu = CreateConVar("sm_saysoundhe_showmenu","1","1 To show menu to users, 0 to hide menu from users (admins excluded)",FCVAR_PLUGIN);
	//##################//

	//##### Clientprefs #####
	// for storing clients sound settings
	g_sssaysound_cookie = RegClientCookie("saysoundsplay", "Play Say Sounds", CookieAccess_Protected);
	g_ssevents_cookie = RegClientCookie("saysoundsevent", "Play Action sounds", CookieAccess_Protected);
	g_sschatmsg_cookie = RegClientCookie("saysoundschatmsg", "Display Chat messages", CookieAccess_Protected);
	g_sskaraoke_cookie = RegClientCookie("saysoundskaraoke", "Play Karaoke music", CookieAccess_Protected);
	g_ssban_cookie = RegClientCookie("saysoundsban", "Banned From Say Sounds", CookieAccess_Protected);
	g_ssgreeted_cookie = RegClientCookie("saysoundsgreeted", "Join sound Cache", CookieAccess_Protected);
	SetCookieMenuItem(SaysoundClientPref, 0, "Say Sounds Preferences");
	//SetCookiePrefabMenu(g_sssaysound_cookie, CookieMenu_OnOff, "Saysounds ON/OFF");
	//#######################
	
	// #### Handle Enabling/Disabling of Say Sounds ###
	HookConVarChange(cvarsoundenable, EnableChanged);

	RegAdminCmd("sm_sound_ban", Command_Sound_Ban, ADMFLAG_BAN, "sm_sound_ban <user> : Bans a player from using sounds");
	RegAdminCmd("sm_sound_unban", Command_Sound_Unban, ADMFLAG_BAN, "sm_sound_unban <user> : Unbans a player from using sounds");
	RegAdminCmd("sm_sound_reset", Command_Sound_Reset, ADMFLAG_GENERIC, "sm_sound_reset <user | all> : Resets sound quota for user, or everyone if all");
	RegAdminCmd("sm_admin_sounds", Command_Admin_Sounds,ADMFLAG_GENERIC, "Display a menu of Admin sounds to play");
	RegAdminCmd("sm_karaoke", Command_Karaoke, ADMFLAG_GENERIC, "Display a menu of Karaoke songs to play");
	//####FernFerret####/
	// This is the admin command that shows all sounds, it is currently set to show to a GENERIC ADMIN
	RegAdminCmd("sm_all_sounds", Command_All_Sounds, ADMFLAG_GENERIC,"Display a menu of ALL sounds to play");
	//##################/

	RegConsoleCmd("sm_sound_list", Command_Sound_List, "List available sounds to console");
	RegConsoleCmd("sm_sound_menu", Command_Sound_Menu, "Display a menu of sounds to play");
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say2", Command_InsurgencySay);
	RegConsoleCmd("say_team", Command_Say);

	// *** Execute the config file ***
	AutoExecConfig(true, "sm_saysounds");

	//*****************************************************************
	//	------------------------------------------------------------- *
	//						*** Hooking Events ***					  *
	//	------------------------------------------------------------- *
	//*****************************************************************
	if(GetConVarBool(cvarsoundenable)) 
	{
		HookEvent("player_death", Event_Kill);
		HookEvent("player_disconnect", Event_Disconnect, EventHookMode_Pre);
		HookEventEx("player_spawn",PlayerSpawn);

		if (GetGameType() == tf2){
			LogMessage("[Say Sounds] Detected Team Fortress 2");
			HookEvent("teamplay_flag_event", Event_Flag);
			HookEvent("player_chargedeployed", Event_UberCharge);
			HookEvent("player_builtobject", Event_Build);
			HookEvent("teamplay_round_start", Event_RoundStart);
			//HookEvent("teamplay_round_active", Event_SetupStart);
			HookEvent("teamplay_setup_finished", Event_SetupEnd);
			//HookEvent("teamplay_waiting_begins", Event_WaitingStart);
			//HookEvent("teamplay_waiting_ends", Event_WaitingEnd);
			HookEvent("teamplay_broadcast_audio", OnAudioBroadcast, EventHookMode_Pre);
		}
		else if (GetGameType() == dod){
			LogMessage("[Say Sounds] Detected Day of Defeat");
			HookEvent("player_hurt", Event_Hurt);
			HookEvent("dod_round_start", Event_RoundStart);
			//HookEvent("dod_round_win", Event_RoundWin);
			HookEvent("dod_broadcast_audio", OnAudioBroadcast, EventHookMode_Pre);
		}
		else if (GetGameType() == zps){
			LogMessage("[Say Sounds] Detected Zombie Panic:Source");
			HookEvent("game_round_restart", Event_RoundStart);
		}
		else if (GetGameType() == cstrike){
			LogMessage("[Say Sounds] Detected Counter Strike");
			HookEvent("round_start", Event_RoundStart);
			HookEvent("round_end", Event_RoundEnd);
		}
		else if (GetGameType() == hl2mp) {
			LogMessage("[Say Sounds] Detected Half-Life 2 Deathmatch");
			HookEvent("teamplay_round_start",Event_RoundStart);
		}
		else if (GetGameType() == other){
			LogMessage("[Say Sounds] No specific game detected");
			HookEvent("round_start", Event_RoundStart);
		}
		
		// Creating SoundCount DB
		InitDB();
		// Clearing the DB
		ClearDB();
	}
	//*****************************************************************
	//	------------------------------------------------------------- *
	//				*** Account for late loading ***				  *
	//	------------------------------------------------------------- *
	//*****************************************************************
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
		OnAdminMenuReady(topmenu);
	
	// *** Update the Plugin Version cvar ***
	SetConVarString(cvarsaysoundversion, PLUGIN_VERSION, true, true);
}
//*****************************************************************
//	------------------------------------------------------------- *
//					*** Un/Hooking Events ***					  *
//	------------------------------------------------------------- *
//*****************************************************************
public EnableChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new intNewValue = StringToInt(newValue);
	new intOldValue = StringToInt(oldValue);
	
	if(intNewValue == 1 && intOldValue == 0) 
	{
		LogMessage("[Say Sounds] Enabled, Hooking Events");
		
		HookEvent("player_death", Event_Kill);
		HookEvent("player_disconnect", Event_Disconnect, EventHookMode_Pre);
		HookEventEx("player_spawn",PlayerSpawn);

		if (GetGameType() == tf2){
			LogMessage("[Say Sounds] Detected Team Fortress 2");
			HookEvent("teamplay_flag_event", Event_Flag);
			HookEvent("player_chargedeployed", Event_UberCharge);
			HookEvent("player_builtobject", Event_Build);
			HookEvent("teamplay_round_start", Event_RoundStart);
			//HookEvent("teamplay_round_active", Event_SetupStart);
			HookEvent("teamplay_setup_finished", Event_SetupEnd);
			//HookEvent("teamplay_waiting_begins", Event_WaitingStart);
			//HookEvent("teamplay_waiting_ends", Event_WaitingEnd);
			HookEvent("teamplay_broadcast_audio", OnAudioBroadcast, EventHookMode_Pre);
		}
		else if (GetGameType() == dod){
			LogMessage("[Say Sounds] Detected Day of Defeat");
			HookEvent("player_hurt", Event_Hurt);
			HookEvent("dod_round_start", Event_RoundStart);
			//HookEvent("dod_round_win", Event_RoundWin);
			HookEvent("dod_broadcast_audio", OnAudioBroadcast, EventHookMode_Pre);
		}
		else if (GetGameType() == zps){
			LogMessage("[Say Sounds] Detected Zombie Panic:Source");
			HookEvent("game_round_restart", Event_RoundStart);
		}
		else if (GetGameType() == cstrike){
			LogMessage("[Say Sounds] Detected Counter Strike");
			HookEvent("round_start", Event_RoundStart);
			HookEvent("round_end", Event_RoundEnd);
		}
		else if (GetGameType() == hl2mp) {
			LogMessage("[Say Sounds] Detected Half-Life 2 Deathmatch");
			HookEvent("teamplay_round_start",Event_RoundStart);
		}
		else if (GetGameType() == other){
			LogMessage("[Say Sounds] No specific game detected");
			HookEvent("round_start", Event_RoundStart);
		}
	} 
	else if(intNewValue == 0 && intOldValue == 1) 
	{
		LogMessage("[Say Sounds] Disabled, Unhooking Events");
		
		UnhookEvent("player_death", Event_Kill);
		UnhookEvent("player_disconnect", Event_Disconnect, EventHookMode_Pre);
		UnhookEvent("player_spawn",PlayerSpawn);

		if (GetGameType() == tf2){
			UnhookEvent("teamplay_flag_event", Event_Flag);
			UnhookEvent("player_chargedeployed", Event_UberCharge);
			UnhookEvent("player_builtobject", Event_Build);
			UnhookEvent("teamplay_round_start", Event_RoundStart);
			//HookEvent("teamplay_round_active", Event_SetupStart);
			UnhookEvent("teamplay_setup_finished", Event_SetupEnd);
			//UnhookEvent("teamplay_waiting_begins", Event_WaitingStart);
			//UnhookEvent("teamplay_waiting_ends", Event_WaitingEnd);
			UnhookEvent("teamplay_broadcast_audio", OnAudioBroadcast, EventHookMode_Pre);
		}
		else if (GetGameType() == dod){
			UnhookEvent("player_hurt", Event_Hurt);
			UnhookEvent("dod_round_start", Event_RoundStart);
			//UnhookEvent("dod_round_win", Event_RoundWin);
			UnhookEvent("dod_broadcast_audio", OnAudioBroadcast, EventHookMode_Pre);
		}
		else if (GetGameType() == zps){
			UnhookEvent("game_round_restart", Event_RoundStart);
		}
		else if (GetGameType() == cstrike){
			UnhookEvent("round_start", Event_RoundStart);
			UnhookEvent("round_end", Event_RoundEnd);
		}
		else if (GetGameType() == hl2mp) {
			UnhookEvent("teamplay_round_start",Event_RoundStart);
		}
		else if (GetGameType() == other){
			UnhookEvent("round_start", Event_RoundStart);
		}
	}

}

//*****************************************************************
//	------------------------------------------------------------- *
//						*** Plugin End ***					 	  *
//	------------------------------------------------------------- *
//*****************************************************************
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

//*****************************************************************
//	------------------------------------------------------------- *
//						  *** Map Start ***						  *
//	------------------------------------------------------------- *
//*****************************************************************
public OnMapStart(){

	BuildPath(Path_SM,g_SaySoundErrorLog,sizeof(g_SaySoundErrorLog),"logs/saysounds_error.log");
	
	LastPlayedSound = "";
	globalLastSound = 0.0;
	globalLastAdminSound = 0.0;
	ClearDB();
	for (new i = 1; i <= MAXPLAYERS; i++) {
		SndCount[i] = 0;
		//LastSound[i] = 0.0;
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

	CreateTimer(0.1, Load_Sounds);
}

//*****************************************************************
//	------------------------------------------------------------- *
//						  *** Map End ***						  *
//	------------------------------------------------------------- *
//*****************************************************************
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

//*****************************************************************
//	------------------------------------------------------------- *
//				*** Load the Sounds from the Config ***			  *
//	------------------------------------------------------------- *
//*****************************************************************
public Action:Load_Sounds(Handle:timer){
	// precache sounds, loop through sounds
	BuildPath(Path_SM,soundlistfile,sizeof(soundlistfile),"configs/saysounds.cfg");
	if(!FileExists(soundlistfile)) {
		SetFailState("saysounds.cfg not parsed...file doesnt exist!");
	} else {
		if (listfile != INVALID_HANDLE){
			CloseHandle(listfile);
		}
		listfile = CreateKeyValues("soundlist");
		FileToKeyValues(listfile,soundlistfile);
		KvRewind(listfile);
		if (KvGotoFirstSubKey(listfile)){
			do {
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
		else {
			SetFailState("saysounds.cfg not parsed...No subkeys found!");
		}
	}
	return Plugin_Handled;
}

//*****************************************************************
//	------------------------------------------------------------- *
//						*** Checking stuff ***					  *
//	------------------------------------------------------------- *
//*****************************************************************
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

public IsDeadClient (client)
{
	if (IsValidClient(client) && !IsPlayerAlive(client))
		return true;
		
	return false;
}

public HearSound (client)
{	
	if (IsPlayerAlive(client) && !hearalive)
		return false;
	else
		return true;
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
		hAdminMenu = INVALID_HANDLE;
}

bool:checkSamplingRate(const String:filelocation[])
{
	new Handle:h_Soundfile = OpenSoundFile(filelocation,true);
	new samplerate;
	if (h_Soundfile != INVALID_HANDLE) {
		samplerate = GetSoundSamplingRate(h_Soundfile);
	} else {
		LogToFile(g_SaySoundErrorLog,"<checkSamplingRate> INVALID_HANDLE for file \"%s\" ", filelocation);
		CloseHandle(h_Soundfile);
		return false;
	}
	CloseHandle(h_Soundfile);
	
	if (samplerate > 44100) {
		LogToFile(g_SaySoundErrorLog,"Invalid sample rate (\%d Hz) for file \"%s\", sample rate should not be above 44100 Hz", samplerate, filelocation);
		return false;
	}
	return true;
}
//*****************************************************************
//	------------------------------------------------------------- *
//				*** Checking Client Preferences ***				  *
//	------------------------------------------------------------- *
//*****************************************************************
bool:checkClientCookies(iClient, iCase)
{
	new String:cookie[4];
	
	switch (iCase)
	{
		case 1:	/* Chat message */
		{
			GetClientCookie(iClient, g_sschatmsg_cookie, cookie, sizeof(cookie));
			if (StrEqual(cookie, "1")) {
				return true;
			} else if(StrEqual(cookie, "0")) {
				return false;
			} else {
				// Set cookie if client connects the first time
				SetClientCookie(iClient, g_sschatmsg_cookie, "1");
				return true;
			}
		}
		case 2:	/* Say sounds */
		{
			GetClientCookie(iClient, g_sssaysound_cookie, cookie, sizeof(cookie));
			// Switching form on/off, yes/no to 1/0 but for the old cookies we'll have to check both
			if (StrEqual(cookie, "on") || StrEqual(cookie, "1")) {
				return true;
			} else if(StrEqual(cookie, "off") || StrEqual(cookie, "0")) {
				return false;
			} else {
				// Set cookie if client connects the first time
				SetClientCookie(iClient, g_sssaysound_cookie, "1");
				return true;
			}
		}
		case 3:	/* Event Sounds */
		{
			GetClientCookie(iClient, g_ssevents_cookie, cookie, sizeof(cookie));
			if (StrEqual(cookie, "1")) {
				return true;
			} else if(StrEqual(cookie, "0")) {
				return false;
			} else {
				// Set cookie if client connects the first time
				SetClientCookie(iClient, g_ssevents_cookie, "1");
				return true;
			}
		}
		case 4:	/* Karaoke */
		{
			GetClientCookie(iClient, g_sskaraoke_cookie, cookie, sizeof(cookie));
			if (StrEqual(cookie, "1")) {
				return true;
			} else if(StrEqual(cookie, "0")) {
				return false;
			} else {
				// Set cookie if client connects the first time
				SetClientCookie(iClient, g_sskaraoke_cookie, "1");
				return true;
			}
		}
		case 5:	/* Banned */
		{
			GetClientCookie(iClient, g_ssban_cookie, cookie, sizeof(cookie));
			// Switching form on/off, yes/no to 1/0 but for the old cookies we'll have to check both
			if (StrEqual(cookie, "on") || StrEqual(cookie, "1")) {
				return true;
			} else if(StrEqual(cookie, "off") || StrEqual(cookie, "0")) {
				return false;
			} else {
				// Set cookie if client connects the first time
				SetClientCookie(iClient, g_ssban_cookie, "0");
				return false;
			}
		}
		case 6:	/* Greeted */
		{
			GetClientCookie(iClient, g_ssgreeted_cookie, cookie, sizeof(cookie));
			// Switching form on/off, yes/no to 1/0 but for the old cookies we'll have to check both
			if (StrEqual(cookie, "yes") || StrEqual(cookie, "1")) {
				return true;
			} else if(StrEqual(cookie, "no") || StrEqual(cookie, "0")) {
				return false;
			} else {
				// Set cookie if client connects the first time
				SetClientCookie(iClient, g_ssgreeted_cookie, "0");
				return false;
			}
		}
		default:
		{
			return true;
		}
	}
	return true;
}

//*****************************************************************
//	------------------------------------------------------------- *
//						*** UNSORTED ***						  *
//	------------------------------------------------------------- *
//*****************************************************************
ResetClientSoundCount(){
	for (new i = 1; i <= MAXPLAYERS; i++) {
		SndCount[i] = 0;
	}
	ClearDB();
}

public Action:reset_PlayedEvent2Client(Handle:timer, any:client)
{
	g_bPlayedEvent2Client[client] = false;
}

//*****************************************************************
//	------------------------------------------------------------- *
//						*** Menu Handling ***					  *
//	------------------------------------------------------------- *
//*****************************************************************
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

		/* ####FernFerret#### */
		// Added two new items to the admin menu, the soundmenu hide (toggle) and the all sounds menu
		AddToTopMenu(hAdminMenu, "sm_all_sounds", TopMenuObject_Item, Play_All_Sound, server_commands, "sm_all_sounds", ADMFLAG_GENERIC);
		AddToTopMenu(hAdminMenu, "sm_sound_showmenu", TopMenuObject_Item, Set_Sound_Menu, server_commands, "sm_sound_showmenu", ADMFLAG_CHANGEMAP);
		/* ################## */
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

/* ####FernFerret#### */
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

public Sound_Menu(client, sound_types:types){
	if (types >= admin_sounds){
		new AdminId:aid = GetUserAdmin(client);
		new bool:isadmin = (aid != INVALID_ADMIN_ID) && GetAdminFlag(aid, Admin_Generic, Access_Effective);

		if (!isadmin){
			//PrintToChat(client,"[Say Sounds] You must be an admin view this menu!");
			PrintToChat(client,"\x04[Say Sounds] \x01%t", "AdminMenu");
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
	else
	{
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

//*****************************************************************
//	------------------------------------------------------------- *
//				*** Client Preferences Menu ***					  *
//	------------------------------------------------------------- *
//*****************************************************************
public SaysoundClientPref(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	if (action == CookieMenuAction_SelectOption)
	{
		ShowClientPrefMenu(client);
	}
}

public MenuHandlerClientPref(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)	
	{
		if (param2 == 0) {
			// Saysounds
			if(!checkClientCookies(param1, CHK_SAYSOUNDS))
			{
				SetClientCookie(param1, g_sssaysound_cookie, "1");
			}
			else
			{
				SetClientCookie(param1, g_sssaysound_cookie, "0");
			}	
		}
		if (param2 == 1) {
			// Action Sounds
			if(!checkClientCookies(param1, CHK_EVENTS))
			{
				SetClientCookie(param1, g_ssevents_cookie, "1");
			}
			else
			{
				SetClientCookie(param1, g_ssevents_cookie, "0");
			}	
		}
		if (param2 == 2) {
			// Karaoke
			if(!checkClientCookies(param1, CHK_KARAOKE))
			{
				SetClientCookie(param1, g_sskaraoke_cookie, "1");
			}
			else
			{
				SetClientCookie(param1, g_sskaraoke_cookie, "0");
			}	
		}
		if (param2 == 3) {
			// Chat Message
			if(!checkClientCookies(param1, CHK_CHATMSG))
			{
				SetClientCookie(param1, g_sschatmsg_cookie, "1");
			}
			else
			{
				SetClientCookie(param1, g_sschatmsg_cookie, "0");
			}
		}
		ShowClientPrefMenu(param1);
	} 
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
 
ShowClientPrefMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandlerClientPref);
	decl String:buffer[100];
	
	Format(buffer, sizeof(buffer), "%T", "SaysoundsMenu", client);
	SetMenuTitle(menu, buffer);
	
	// Saysounds
	if(!checkClientCookies(client, CHK_SAYSOUNDS))
	{
		Format(buffer, sizeof(buffer), "%T", "EnableSaysound", client);
	}
	else
	{
		Format(buffer, sizeof(buffer), "%T", "DisableSaysound", client);
	}	
	AddMenuItem(menu, "SaysoundPref", buffer);
	
	// Action Sounds
	if(!checkClientCookies(client, CHK_EVENTS))
	{
		Format(buffer, sizeof(buffer), "%T", "EnableEvents", client);
	}
	else
	{
		Format(buffer, sizeof(buffer), "%T", "DisableEvents", client);
	}	
	AddMenuItem(menu, "EventPref", buffer);
	
	// Karaoke
	if(!checkClientCookies(client, CHK_KARAOKE))
	{
		Format(buffer, sizeof(buffer), "%T", "EnableKaraoke", client);
	}
	else
	{
		Format(buffer, sizeof(buffer), "%T", "DisableKaraoke", client);
	}
	AddMenuItem(menu, "KaraokePref", buffer);
	
	// Chat Messages
	if(!checkClientCookies(client, CHK_CHATMSG))
	{
		Format(buffer, sizeof(buffer), "%T", "EnableChat", client);
	}
	else
	{
		Format(buffer, sizeof(buffer), "%T", "DisableChat", client);
	}	
	AddMenuItem(menu, "ChatPref", buffer);
	
	SetMenuExitButton(menu, true);

	DisplayMenu(menu, client, 0);
}

//*****************************************************************
//	------------------------------------------------------------- *
//						*** Event Actions ***					  *
//	------------------------------------------------------------- *
//*****************************************************************
public Action:Event_Disconnect(Handle:event,const String:name[],bool:dontBroadcast)
{
	decl String:SteamID[60];
	GetEventString(event, "networkid", SteamID, sizeof(SteamID));
	new id2Client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	InsertCountQuery(SteamID, SndCount[id2Client]);

	if (!IsValidClient(id2Client)){
		/*	If a client disconnects during a map change.
			Clientprefs only works with a client index which will be 0
			if a client disconnects during a map change
		*/
		if (SQL_CheckConfig("clientprefs"))
		{
			decl String:error[255];
			decl String:QueryString[255];
			//g_dbClientprefs = SQLite_UseDatabase( "clientprefs-sqlite", error, 40 );
			g_dbClientprefs = SQL_Connect("clientprefs", true, error, sizeof(error));
			if (g_dbClientprefs != INVALID_HANDLE) {
				Format(QueryString, sizeof(QueryString), "SELECT id FROM sm_cookies WHERE name = 'saysoundsgreeted'");
				new Handle:Query = SQL_Query(g_dbClientprefs, QueryString);
				if (Query != INVALID_HANDLE) {
					SQL_FetchRow(Query);
					// Get the cookie id of our cookie
					new cookieID = SQL_FetchInt(Query, 0);
					// Update our cookie
					if (cookieID > 0){
						Format(QueryString, 255, "UPDATE sm_cookie_cache SET value = '0', timestamp = %i WHERE player = '%s' AND cookie_id = %i", GetTime(), SteamID, cookieID);
						SQL_FastQuery(g_dbClientprefs, QueryString);
					}
					CloseHandle(Query);
				} else {
					SQL_GetError(g_dbClientprefs, error, sizeof(error));
					LogToFile(g_SaySoundErrorLog,"<Event_Disconnect> Invalid query Handle! Error: %s", error);
				}
			} else {
				LogToFile(g_SaySoundErrorLog,"<Event_Disconnect> Failed to connect to clientprefs database! Error: %s", error);
			}
		}
	} else {
		if (checkClientCookies(id2Client, CHK_GREETED))
		SetClientCookie(id2Client, g_ssgreeted_cookie, "0");
	}
}

public Action:OnAudioBroadcast(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarBool(cvarsoundenable))
		return Plugin_Continue;
		
	decl String:sound[30];
	GetEventString(event, "sound", sound, sizeof(sound));
		
	if(GetGameType() == tf2){
		WinningTeam = GetEventInt(event, "team");
		if(StrEqual(sound, "Game.Stalemate") && runSoundEvent(event,"round","Stalemate",0,0,-1))
			return Plugin_Handled;
		else if(StrEqual(sound, "Game.SuddenDeath") && runSoundEvent(event,"round","SuddenDeath",0,0,-1))
			return Plugin_Handled;
		else if(StrEqual(sound, "Game.YourTeamWon") && runSoundEvent(event,"round","won",0,0,WinningTeam))
			return Plugin_Handled;
		else if(StrEqual(sound, "Game.YourTeamLost") && runSoundEvent(event,"round","lost",0,0,WinningTeam))
			return Plugin_Handled;
		/*
		if(suddendeath && runSoundEvent(event,"suddendeathend","suddendeathend", _, _,WinningTeam)) {
			//runSoundEvent(event,"suddendeathend","suddendeathend",0,0);
			suddendeath = false;
			return Plugin_Continue;
		}
		runSoundEvent(event,"roundend","roundend", _, _,WinningTeam);
		return Plugin_Continue;
		*/
	}
	if(GetGameType() == dod){
		if(StrEqual(sound, "Game.USWin") && runSoundEvent(event,"round","USWon",0,0,-1))
			return Plugin_Handled;
		else if(StrEqual(sound, "Game.GermanWin") && runSoundEvent(event,"round","GERWon",0,0,-1))
			return Plugin_Handled;
	}
	return Plugin_Continue;
}


public Action:Event_SetupEnd(Handle:event,const String:name[],bool:dontBroadcast){
	runSoundEvent(event,"round","setupend",0,0,-1);
	return Plugin_Continue;
}
/*
public Action:Event_WaitingStart(Handle:event,const String:name[],bool:dontBroadcast){
	PrintToChatAll("Waiting Start");
	TF2waiting = true;
	return Plugin_Continue;
}
public Action:Event_WaitingEnd(Handle:event,const String:name[],bool:dontBroadcast){
	PrintToChatAll("Waiting End");
	TF2waiting = false;
	return Plugin_Continue;
} */
/*  #### Now done by OnAudioBroadcast ###
public Action:Event_RoundWin(Handle:event,const String:name[],bool:dontBroadcast){
// ####	TF2 & DoD Event ###
	if(GetGameType() == tf2){
		WinningTeam = GetEventInt(event, "team");
		if(suddendeath && runSoundEvent(event,"suddendeathend","suddendeathend", _, _,WinningTeam)) {
			//runSoundEvent(event,"suddendeathend","suddendeathend",0,0);
			suddendeath = false;
			return Plugin_Continue;
		}
		runSoundEvent(event,"roundend","roundend", _, _,WinningTeam);
		return Plugin_Continue;
	}
	if (GetGameType() == dod) {
		dodRoundEnd = true;
		WinningTeam = GetEventInt(event, "team");
		return Plugin_Continue;
	}
	return Plugin_Continue;
}
*/
public Action:Event_RoundStart(Handle:event,const String:name[],bool:dontBroadcast)
{
	/* if(GetEventBool(event,"full_reset"))
		PrintToChatAll("Round Start: Full Reset");
	else
		PrintToChatAll("Round Start"); */
		
	runSoundEvent(event,"round","start",0,0,-1);

	if (GetConVarBool(cvarsoundlimitround)){
		ResetClientSoundCount();
	}
	return Plugin_Continue;
}

public Action:Event_RoundEnd(Handle:event,const String:name[],bool:dontBroadcast){
	runSoundEvent(event,"round","end",0,0,-1);
	return Plugin_Continue;
}

public Action:Event_UberCharge(Handle:event,const String:name[],bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	new victim   = GetClientOfUserId(GetEventInt(event, "targetid"));
	runSoundEvent(event,"uber","uber",attacker,victim,-1);
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
	runSoundEvent(event,"flag",flagstring,0,0,-1);
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
		runSoundEvent(event,"kill","suicide",0,victim,-1);
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
				runSoundEvent(event,"kill","headshot",attacker,victim,-1);
				return Plugin_Continue;
			}
			if (custom_kill == 2)
			{
				runSoundEvent(event,"kill","backstab",attacker,victim,-1);
				return Plugin_Continue;
			}
			new bits = GetEventInt(event,"damagebits");
			if (bits & 1048576 && attacker > 0)
			{
				runSoundEvent(event,"kill","crit_kill",attacker,victim,-1);
				return Plugin_Continue;
			}
			if (bits == 16 && victim > 0)
			{
				runSoundEvent(event,"kill","hit_by_train",0,victim,-1);
				return Plugin_Continue;
			}
			if (bits == 16384 && victim > 0)
			{
				runSoundEvent(event,"kill","drowned",0,victim,-1);
				return Plugin_Continue;
			}
			if (bits & 32 && victim > 0)
			{
				runSoundEvent(event,"kill","fall",0,victim,-1);
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
				runSoundEvent(event,"kill","headshot",attacker,victim,-1);
				return Plugin_Continue;
			}
			GetEventString(event, "weapon",wepstring,PLATFORM_MAX_PATH+1);
		}
		else
		{
			GetEventString(event, "weapon",wepstring,PLATFORM_MAX_PATH+1);
		}
		
		runSoundEvent(event,"kill",wepstring,attacker,victim,-1);
		
		return Plugin_Continue;
	}
}
// ####### Day of Defeat #######
public Action:Event_Hurt(Handle:event,const String:name[],bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim   = GetClientOfUserId(GetEventInt(event, "userid"));
	new headshot   = (GetEventInt(event, "health") == 0 && GetEventInt(event, "hitgroup") == 1);
	
	if (headshot) {
		runSoundEvent(event,"kill","headshot",attacker,victim,-1);
	}
	return Plugin_Continue;
}
// ####### TF2 #######
public Action:Event_Build(Handle:event,const String:name[],bool:dontBroadcast)
{
	decl String:object[PLATFORM_MAX_PATH+1];
	new objectint = GetEventInt(event,"object");
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
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
	runSoundEvent(event,"build",object,attacker,0,-1);
	return Plugin_Continue;
}

//*****************************************************************
//	------------------------------------------------------------- *
//					*** Run Event Sounds ***					  *
//	------------------------------------------------------------- *
//*****************************************************************
// Generic Sound event, this gets triggered whenever an event that is supported is triggered
public runSoundEvent(Handle:event,const String:type[],const String:extra[],const attacker,victim,team)
{
	decl String:action[PLATFORM_MAX_PATH+1];
	decl String:extraparam[PLATFORM_MAX_PATH+1];
	decl String:location[PLATFORM_MAX_PATH+1];
	decl String:playto[PLATFORM_MAX_PATH+1];
	new bool:result = false;
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
		return false;
		
	// Do while loop that finds out what extra parameter is and plays according sound, also adds random
	do
	{
		KvGetString(listfile, "action",action,sizeof(action),"");
		//PrintToServer("Found Subkey, trying to match (%s) with (%s)",action,type);
		if (StrEqual(action, type, false))
		{
			//KvGetString(listfile, "file", location, sizeof(location),"");
		// ###### Random Sound ######
			decl String:file[8] = "file";
			new count = KvGetNum(listfile, "count", 1);
			if (count > 1)
				Format(file, sizeof(file), "file%d", GetRandomInt(1,count));
				
			if (StrEqual(file, "file1"))
				KvGetString(listfile, "file", location, sizeof(location), "");
			else
				KvGetString(listfile, file, location, sizeof(location),"");

				
		// ###### Random Sound End ######
			KvGetString(listfile, "param",extraparam,sizeof(extraparam),action);
			if(team == -1)
				KvGetString(listfile, "playto",playto,sizeof(playto),"all");
			else
				KvGetString(listfile, "playto",playto,sizeof(playto),"RoundEvent");
				
			// Used for identifying the names of things
			//PrintToChatAll("Found Subkey, trying to match (%s) with (%s)",extra,extraparam);
			if(StrEqual(extra, extraparam, false) && checkSamplingRate(location))
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
					WritePackCell(pack, attacker);
					WritePackCell(pack, victim);
					WritePackString(pack, playto);
					WritePackString(pack, location);
					ResetPack(pack);
					//EmitSound(clientlist, clientcount, location);
				}
				result = true;
			}
			else
				result = false;
		}
		else
			result = false;
	} while (KvGotoNextKey(listfile));
	//return false;
	return result;
}

//*****************************************************************
//	------------------------------------------------------------- *
//					*** Event Sound Timer ***					  *
//	------------------------------------------------------------- *
//*****************************************************************
public Action:runSoundEventTimer(Handle:timer,Handle:pack){
	//decl String:location[PLATFORM_MAX_PATH+1];
	// Send to all clients, will update in future to add To client/To Team/To All
	//new clientlist[MAXPLAYERS+1];
	//new looserlist[MAXPLAYERS+1];
	//new clientcount = 0;
	//new loosercount = 0;
	new attacker = ReadPackCell(pack);
	new victim = ReadPackCell(pack);
	decl String:playto[PLATFORM_MAX_PATH+1];
	ReadPackString(pack, playto, sizeof(playto));
	decl String:location[PLATFORM_MAX_PATH+1];
	ReadPackString(pack, location, sizeof(location));
	//new playersconnected = GetMaxClients();
	
	if (StrEqual(playto, "attacker", false)) // Send to attacker
	{
		if (IsValidClient(attacker) && checkClientCookies(attacker, CHK_EVENTS) && !g_bPlayedEvent2Client[attacker]){
			EmitSoundToClient(attacker, location);
			g_bPlayedEvent2Client[attacker] = true;
			CreateTimer(2.0, reset_PlayedEvent2Client, attacker);
			//PrintToChat(attacker, "Attacker: %s", location);
		}
	} else if (StrEqual(playto, "victim", false)){ // Send to victim
		//PrintToChat(victim, "Victim: %s", location);
		if (IsValidClient(victim)&& checkClientCookies(victim, CHK_EVENTS)){
			EmitSoundToClient(victim, location);
			//PrintToChat(victim, "CL_Victim: %s", location);
		}
			
	} else if (StrEqual(playto, "both", false)){ // Send to attacker & victim
		
		if (IsValidClient(attacker) && checkClientCookies(attacker, CHK_EVENTS) && !g_bPlayedEvent2Client[attacker]){
			EmitSoundToClient(attacker, location);
			g_bPlayedEvent2Client[attacker] = true;
			CreateTimer(3.0, reset_PlayedEvent2Client, attacker);
			//PrintToChat(attacker, "Both attacker: %s", location);
		}
		if (IsValidClient(victim)&& checkClientCookies(victim, CHK_EVENTS)){
			EmitSoundToClient(victim, location);
			//PrintToChat(victim, "Both victim: %s", location);
		}
			
	} else if (StrEqual(playto, "ateam", false)){ // Send to attacker team
		
		//if (!g_bPlayedEvent2Client[attacker]){
			new aTeam = GetClientTeam(attacker);
			for (new i = 1; i <= MaxClients; i++){
				if(IsValidClient(i) && GetClientTeam(i) == aTeam && checkClientCookies(i, CHK_EVENTS))
					//clientlist[clientcount++] = i;
					EmitSoundToClient(i, location);
			}
			//EmitSound(clientlist, clientcount, location);
			//g_bPlayedEvent2Client[attacker] = true;
			//CreateTimer(3.0, reset_PlayedEvent2Client, attacker);
			//PrintToChatAll("ATeam: %s", location);
		//}
		
	} else if (StrEqual(playto, "vteam", false)){ // Send to victim team
		
		//if (!g_bPlayedEvent2Client[victim]){
			new vTeam = GetClientTeam(victim);
			for (new i = 1; i <= MaxClients; i++){
				if(IsValidClient(i) && GetClientTeam(i) == vTeam && checkClientCookies(i, CHK_EVENTS))
					//clientlist[clientcount++] = i;
					EmitSoundToClient(i, location);
			}
			//EmitSound(clientlist, clientcount, location);
			//g_bPlayedEvent2Client[victim] = true;
			//CreateTimer(3.0, reset_PlayedEvent2Client, victim);
			//PrintToChatAll("VTeam: %s", location);
		//}
	} else if (StrEqual(playto, "RoundEvent", false)){ // RoundEvent

		for (new i = 1; i <= MaxClients; i++){
			//if(IsValidClient(i) && GetClientTeam(i) == WinningTeam && checkClientCookies(i, _, _, true))
			if(IsValidClient(i)) /* && checkClientCookies(i, _, _, true)) */ {
				if(GetClientTeam(i) == WinningTeam)
					EmitSoundToClient(i, location);
				if(GetClientTeam(i) != WinningTeam && GetClientTeam(i) != 0)
					EmitSoundToClient(i, location);
			}
		}
		//EmitSound(clientlist, clientcount, location);
		g_bPlayedEvent2Client[victim] = true;
		CreateTimer(3.0, reset_PlayedEvent2Client, victim);
		//PrintToChatAll("VTeam: %s", location);
		
	} else { // Send to all clients
		
		for (new i = 1; i <= MaxClients; i++){
			if(IsValidClient(i) && checkClientCookies(i, CHK_EVENTS))
				//clientlist[clientcount++] = i;
				EmitSoundToClient(i, location);
		}
		//EmitSound(clientlist, clientcount, location);
	}
	//ReadPackString(pack, location, sizeof(location));
	//EmitSound(clientlist, clientcount, location);
}

//*****************************************************************
//	------------------------------------------------------------- *
//					*** Join/Exit Sounds ***					  *
//	------------------------------------------------------------- *
//*****************************************************************
public OnClientPostAdminCheck(client)
{
	if(IsValidClient(client) && !GetConVarBool(cvarjoinspawn)){
		decl String:auth[64];
		GetClientAuthString(client,auth,63);
		CheckJoin(client, auth);
	}
	GetConutDB(client);
}

	//####### Player Spawn #######
public PlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast){
	if(GetConVarBool(cvarjoinspawn) && GetConVarBool(cvarjoinexit)){
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

	//####### Check Join #######
public CheckJoin(client, const String:auth[]){
	/*if(listfile == INVALID_HANDLE)
		return;*/
	if(GetConVarBool(cvarspecificjoinexit)){
		decl String:filelocation[PLATFORM_MAX_PATH+1];
		KvRewind(listfile);
		if (KvJumpToKey(listfile, auth) && !checkClientCookies(client, CHK_GREETED)){
			filelocation[0] = '\0';
			KvGetString(listfile, "join", filelocation, sizeof(filelocation), "");
			if (filelocation[0] != '\0'){
				Send_Sound(client,filelocation, "", true, false);
				//SndCount[client] = 0;
				SetClientCookie(client, g_ssgreeted_cookie, "1");
				return;
			} else if (Submit_Sound(client,"", true, false)){
				//SndCount[client] = 0;
				SetClientCookie(client, g_ssgreeted_cookie, "1");
				return;
			}
		}
	}

	if(GetConVarBool(cvarjoinexit) || GetConVarBool(cvarjoinspawn)){
		KvRewind(listfile);
		if (KvJumpToKey(listfile, "JoinSound") && !checkClientCookies(client, CHK_GREETED)){
			Submit_Sound(client,"", true, false);
			//SndCount[client] = 0;
			SetClientCookie(client, g_ssgreeted_cookie, "1");
		}
	}
}

	//####### Client Disconnect #######
public OnClientDisconnect(client){
	if(GetConVarBool(cvarjoinexit) && listfile != INVALID_HANDLE){
		//SndCount[client] = 0;
		//LastSound[client] = 0.0;
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
					Send_Sound(client,filelocation, "", false, true);
					//SndCount[client] = 0;
					return;
				}else if (Submit_Sound(client,"", false, true)){
					//SndCount[client] = 0;
					return;
				}
			}
		}

		KvRewind(listfile);
		if (KvJumpToKey(listfile, "ExitSound")){
			Submit_Sound(client,"", false, true);
			//SndCount[client] = 0;
		}
	}
}

public OnClientAuthorized(client, const String:auth[]){
	if(client != 0){
		//SndCount[client] = 0;
		//LastSound[client] = 0.0;
		firstSpawn[client]=true;
		/*if(!GetConVarBool(cvarjoinspawn)){
			CheckJoin(client, auth);
		}*/
	}
}

//*****************************************************************
//	------------------------------------------------------------- *
//					*** Say Command Handling ***				  *
//	------------------------------------------------------------- *
//*****************************************************************
	//####### Command Say #######
public Action:Command_Say(client,args){
	if(client != 0){
		// If sounds are not enabled, then skip this whole thing
		if (!GetConVarBool(cvarsoundenable))
			return Plugin_Continue;

		// player is banned from playing sounds
		if (checkClientCookies(client, CHK_BANNED))
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

		if(strcmp(speech[startidx],"!sounds",false) == 0 || strcmp(speech[startidx],"sounds",false) == 0){
			ShowClientPrefMenu(client);
			return Plugin_Handled;
			/*if(ClientSoundOn(client)){
				// Update cookie
				SetClientCookie(client, g_sssaysound_cookie, "off");
				//SndOn[client] = 0;
				//PrintToChat(client,"\x04[Say Sounds]\x01 Sounds Disabled");
				PrintToChat(client,"\x04[Say Sounds] \x01%t", "SoundsDisabled");
			}else{
				// Update cookie
				SetClientCookie(client, g_sssaysound_cookie, "on");
				//SndOn[client] = 1;
				//PrintToChat(client,"\x04[Say Sounds]\x01 Sounds Enabled");
				PrintToChat(client,"\x04[Say Sounds] \x01%t", "SoundsEnabled");
			}
			return Plugin_Handled;
			*/
		} else if(strcmp(speech[startidx],"!soundlist",false) == 0 || strcmp(speech[startidx],"soundlist",false) == 0){
			if(GetConVarInt(cvarshowsoundmenu) == 1){
				Sound_Menu(client,normal_sounds);
			} else {
				List_Sounds(client);
				//PrintToChat(client,"\x04[Say Sounds]\x01 Check your console for a list of sound triggers");
				PrintToChat(client,"\x04[Say Sounds]\x01%t", "Soundlist");
			}
			return Plugin_Handled;
		} else if(strcmp(speech[startidx],"!soundmenu",false) == 0 || strcmp(speech[startidx],"soundmenu",false) == 0){
			if(GetConVarInt(cvarshowsoundmenu) == 1){
				Sound_Menu(client,normal_sounds);
			}
			return Plugin_Handled;
		} else if(strcmp(speech[startidx],"!adminsounds",false) == 0 || strcmp(speech[startidx],"adminsounds",false) == 0){
			Sound_Menu(client,admin_sounds);
			return Plugin_Handled;
		} else if(strcmp(speech[startidx],"!karaoke",false) == 0 || strcmp(speech[startidx],"karaoke",false) == 0){
			Sound_Menu(client,karaoke_sounds);
			return Plugin_Handled;
		} else if(strcmp(speech[startidx],"!allsounds",false) == 0 || strcmp(speech[startidx],"allsounds",false) == 0){
			Sound_Menu(client,all_sounds);
			return Plugin_Handled;
		} else if(strcmp(speech[startidx],"!stop",false) == 0){
			if(SndPlaying[client][0])
			{
				StopSound(client,SNDCHAN_AUTO,SndPlaying[client]);
				SndPlaying[client] = "";
			}
			return Plugin_Handled;
		}
		// If player has turned sounds off and is restricted from playing sounds, skip
		if(!GetConVarBool(cvarplayifclsndoff) && !checkClientCookies(client, CHK_SAYSOUNDS)) 
			return Plugin_Continue;
		/*
		{
			// Read Client cookie
			new String:cookie[4];
			GetClientCookie(client, g_sssaysound_cookie, cookie, sizeof(cookie));
		
			// If player has turned sounds off and is restricted from playing sounds, skip
			if(StrEqual(cookie, "off") && !GetConVarBool(cvarplayifclsndoff)){
				return Plugin_Continue;
			}
		}
		*/
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

	//####### Command Ins Say #######
public Action:Command_InsurgencySay(client,args){
	if(client != 0){
		// If sounds are not enabled, then skip this whole thing
		if (!GetConVarBool(cvarsoundenable))
			return Plugin_Continue;

		// player is banned from playing sounds
		if (checkClientCookies(client, CHK_BANNED))
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
				ShowClientPrefMenu(client);
				return Plugin_Handled;
				/*
				if(ClientSoundOn(client)){
					// Update cookie
					SetClientCookie(client, g_sssaysound_cookie, "off");
					//SndOn[client] = 0;
					//PrintToChat(client,"\x04[Say Sounds]\x01 Sounds Disabled");
					PrintToChat(client,"\x04[Say Sounds] \x01%t", "SoundsDisabled");
				}else{
					// Update cookie
					SetClientCookie(client, g_sssaysound_cookie, "on");
					//SndOn[client] = 1;
					//PrintToChat(client,"\x04[Say Sounds]\x01 Sounds Enabled");
					PrintToChat(client,"\x04[Say Sounds] \x01%t", "SoundsEnabled");
				}
				return Plugin_Handled;
				*/
		}else if(strcmp(speech[startidx],"!soundlist",false ||
			strcmp(speech[startidx],"soundlist",false) == 0) == 0){
			if(GetConVarInt(cvarshowsoundmenu) == 1){
				Sound_Menu(client,normal_sounds);
			}else{
				List_Sounds(client);
				//PrintToChat(client,"\x04[Say Sounds]\x01 Check your console for a list of sound triggers");
				PrintToChat(client,"\x04[Say Sounds]\x01%t", "Soundlist");
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
		// If player has turned sounds off and is restricted from playing sounds, skip
		if(!GetConVarBool(cvarplayifclsndoff) && !checkClientCookies(client, CHK_SAYSOUNDS))
			return Plugin_Continue;
		/*
		{
			// Read Client cookie
			new String:cookie[4];
			GetClientCookie(client, g_sssaysound_cookie, cookie, sizeof(cookie));
		
			// If player has turned sounds off and is restricted from playing sounds, skip
			if(StrEqual(cookie, "off") && !GetConVarBool(cvarplayifclsndoff)){
				return Plugin_Continue;
			}
		}
		*/
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

//*****************************************************************
//	------------------------------------------------------------- *
//					*** Play Say Sound ***						  *
//	------------------------------------------------------------- *
//*****************************************************************
	//####### Submit Sound #######
bool:Submit_Sound(client,const String:name[], bool:joinsound=false, bool:exitsound=false)
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
		} else {
			Send_Sound(client, filelocation, name, joinsound, exitsound);
		}
		return true;
	}
	return false;
}
	//####### Send Sound #######
Send_Sound(client, const String:filelocation[], const String:name[], bool:joinsound=false, bool:exitsound=false)
{
	new tmp_joinsound;
	
	new adminonly = KvGetNum(listfile, "admin",0);
	new adultonly = KvGetNum(listfile, "adult",0);
	new singleonly = KvGetNum(listfile, "single",0);
	decl String:txtmsg[256];
	txtmsg[0] = '\0';
	if (joinsound)
		KvGetString(listfile, "text", txtmsg, sizeof(txtmsg));
	if (exitsound)
		KvGetString(listfile, "etext", txtmsg, sizeof(txtmsg));
	if (!joinsound && !exitsound)
		KvGetString(listfile, "text", txtmsg, sizeof(txtmsg));
		
	new actiononly = KvGetNum(listfile, "actiononly",0);

	if (joinsound || exitsound){
		tmp_joinsound = 1;
	} else {
		tmp_joinsound = 0;
	}

	//####### DURATION #######
	// Get the handle to the soundfile
	new Handle:h_Soundfile = INVALID_HANDLE;
	new timebuf;
	new samplerate;
	
	h_Soundfile = OpenSoundFile(filelocation,true);
	
	if(h_Soundfile != INVALID_HANDLE) {
		// get the sound length
		timebuf = GetSoundLength(h_Soundfile);
		// get the sample rate
		samplerate = GetSoundSamplingRate(h_Soundfile);
		// close the handle
		CloseHandle(h_Soundfile);
	} else {
		LogToFile(g_SaySoundErrorLog,"<Send_Sound> INVALID_HANDLE for file \"%s\" ", filelocation);
	}
	// Check the sample rate and leave a message if it's above 44.1 kHz;
	if (samplerate > 44100) {
		LogToFile(g_SaySoundErrorLog,"Invalid sample rate (\%d Hz) for file \"%s\", sample rate should not be above 44100 Hz", samplerate, filelocation);
		PrintToChat(client, "\x04[Say Sounds] \x01Invalid sample rate (\x04%d Hz\x01) for file \x04%s\x01, sample rate should not be above \x0444100 Hz", samplerate, filelocation);
		return;
	}
	
	new Float:duration = float(timebuf);
	
	new Float:defVol = GetConVarFloat(cvarvolume);
	new Float:volume = KvGetFloat(listfile, "volume", defVol);
	if (volume == 0.0 || volume == 1.0) {
		volume = defVol; // do this check because of possibly "stupid" values in cfg file
	}
	
	// ### Delay ###
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
	WritePackCell(pack, actiononly);
	WritePackFloat(pack, duration);
	WritePackFloat(pack, volume); // mod by Woody
	WritePackString(pack, filelocation);
	WritePackString(pack, name);
	WritePackCell(pack, tmp_joinsound);
	WritePackString(pack, txtmsg);
	ResetPack(pack);
}

	//####### Play Sound #######
Play_Sound(const String:filelocation[], Float:volume)
{
	new clientlist[MAXPLAYERS+1];
	new clientcount = 0;
	//new playersconnected = GetMaxClients();
	for (new i = 1; i <= MaxClients; i++){
		if(IsValidClient(i) && checkClientCookies(i, CHK_SAYSOUNDS) && HearSound(i)){
			clientlist[clientcount++] = i;
			if (GetConVarBool(cvarinterruptsound))
				StopSound(i, SNDCHAN_AUTO, SndPlaying[i]);
			strcopy(SndPlaying[i], sizeof(SndPlaying[]), filelocation);
		}
	}
	if (clientcount){
		PrepareSound(filelocation, false);
		EmitSound(clientlist, clientcount, filelocation, .volume=volume);
	}
}

//*****************************************************************
//	------------------------------------------------------------- *
//					*** Play Sound Timer ***					  *
//	------------------------------------------------------------- *
//*****************************************************************
public Action:Play_Sound_Timer(Handle:timer,Handle:pack){
	decl String:filelocation[PLATFORM_MAX_PATH+1];
	decl String:name[PLATFORM_MAX_PATH+1];
	decl String:chatBuffer[256];
	decl String:txtmsg[256];
	txtmsg[0] = '\0';
	new client = ReadPackCell(pack);
	new adminonly = ReadPackCell(pack);
	new adultonly = ReadPackCell(pack);
	new singleonly = ReadPackCell(pack);
	/* ####FernFerret#### */
	new actiononly = ReadPackCell(pack);
	/* ################## */
	new Float:duration = ReadPackFloat(pack);
	new Float:volume = ReadPackFloat(pack); // mod by Woody
	ReadPackString(pack, filelocation, sizeof(filelocation));
	ReadPackString(pack, name , sizeof(name));
	new joinsound = ReadPackCell(pack);
	ReadPackString(pack, txtmsg , sizeof(txtmsg));

	/* ####FernFerret#### */
	// Checks for Action Only sounds and messages user telling them why they can't play an action only sound
	if (IsValidClient(client))
	{
		//new AdminId:aid = GetUserAdmin(client);
		//isadmin = (aid != INVALID_ADMIN_ID) && GetAdminFlag(aid, Admin_Generic, Access_Effective);
		if(actiononly == 1){
			//PrintToChat(client,"[Action Sounds] Sorry, this is an action sound!");
			PrintToChat(client,"\x04[Action Sounds] \x01%t", "ActionSounds");
			return Plugin_Handled;
		}
	}
	/* ################## */

	new Float:waitTime = GetConVarFloat(cvartimebetween);
	new Float:adminTime = GetConVarFloat(cvaradmintime);
	
	new bool:isadmin = false;
	if (IsValidClient(client))
	{
	
		new AdminId:aid = GetUserAdmin(client);
		isadmin = (aid != INVALID_ADMIN_ID) && GetAdminFlag(aid, Admin_Generic, Access_Effective);
		if(adminonly && !isadmin){
			//PrintToChat(client,"\x04[Say Sounds]\x01 Sorry, you are not authorized to play this sound!");
			PrintToChat(client,"\x04[Say Sounds] \x01%t", "AdminSounds");
			return Plugin_Handled;
		}
	}

	new Float:thetime = GetGameTime();
	//if (LastSound[client] >= thetime){
	//	Spam Sounds
	//	Only if the user is not admin or he is admin and the adminTime is not -1 for bypassing
	if (globalLastSound > 0.0) {
		if ((!isadmin && globalLastSound > thetime) || (isadmin && adminTime >= 0.0 && globalLastSound > thetime)){
			if(IsValidClient(client)){
				//PrintToChat(client,"\x04[Say Sounds]\x01 Please don't spam the sounds!");
				PrintToChat(client,"\x04[Say Sounds] \x01%t", "SpamSounds");
			}
			return Plugin_Handled;
		}
	}
	

//	new Float:waitTime = GetConVarFloat(cvartimebetween);
	if (waitTime > 0.0 && waitTime < duration)
		waitTime = duration;
	//else if (waitTime <= 0.0)
		//duration = waitTime;

//	new Float:adminTime = GetConVarFloat(cvaradmintime);
	if (adminonly)
	{
		if (globalLastAdminSound >= thetime){
			if(IsValidClient(client)){
				//PrintToChat(client,"\x04[Say Sounds]\x01 Please don't spam the admin sounds!");
				PrintToChat(client,"\x04[Say Sounds] \x01%t", "SpamAdminSounds");
			}
			return Plugin_Handled;
		}

//		adminTime = GetConVarFloat(cvaradmintime);
		
		if(adminTime > 0.0 && adminTime < duration)
				adminTime = duration;
	}

	if(GetConVarBool(cvarexcludelastsound) && IsValidClient(client) && joinsound != 1 && StrEqual(LastPlayedSound, name, false)){
		//PrintToChat(client, "\x04[Say Sounds]\x01 Sorry, this sound was recently played.");
		PrintToChat(client, "\x04[Say Sounds] \x01%t", "RecentlyPlayed");
		return Plugin_Handled;
	}

	if(GetConVarBool(cvarfilterifdead)){
		if(IsDeadClient(client))
			hearalive = false;
		else
			hearalive = true;
	}

	new soundLimit = isadmin ? GetConVarInt(cvaradminlimit) : GetConVarInt(cvarsoundlimit);	
	if (soundLimit <= 0 || SndCount[client] < soundLimit){

		if (joinsound == 1){
			//SndCount[client] = 0;
			if (txtmsg[0] != '\0')
				//PrintToChatAll("%s", txtmsg);
				dispatchChatMessage(client, txtmsg, "");
		} else {
			SndCount[client]++;
			//LastSound[client] = thetime + waitTime;
			globalLastSound   = thetime + waitTime;
		}
		if (adminonly)
			globalLastAdminSound = thetime + adminTime;

		if (singleonly && joinsound == 1){
			if(checkClientCookies(client, CHK_SAYSOUNDS) && IsValidClient(client)){
				PrepareSound(filelocation, false);
				EmitSoundToClient(client, filelocation, .volume=volume);
				strcopy(SndPlaying[client], sizeof(SndPlaying[]), filelocation);
				if (GetConVarBool(cvarlogging)){
					LogToGame("[Say Sounds Log] %s%N  played  %s%s(%s)", isadmin ? "Admin " : "", client,
					   adminonly ? "admin sound " : "", name, filelocation);
				}
			}
		} else {
			Play_Sound(filelocation, volume);
			LastPlayedSound = name;
			if (name[0] && IsValidClient(client)){
				if (GetConVarBool(cvarannounce)){
					if(adultonly && GetConVarBool(cvaradult)){
						if (txtmsg[0] != '\0'){
							//PrintToChatAll("\x04%N\x01: %s", client , txtmsg);
							Format(chatBuffer, sizeof(chatBuffer), "\x04%N\x01: %s", client , txtmsg);
							dispatchChatMessage(client, chatBuffer, "");
						} else {
							//PrintToChatAll("%t", "PlayedAdultSound", client);
							dispatchChatMessage(client, "PlayedAdultSound", "", true);
						}
					} else {
						if (txtmsg[0] != '\0'){
							//PrintToChatAll("\x04%N\x01: %s", client , txtmsg);
							Format(chatBuffer, sizeof(chatBuffer), "\x04%N\x01: %s", client , txtmsg);
							dispatchChatMessage(client, chatBuffer, "");
						} else {
							//PrintToChatAll("%t", "PlayedSound", client, name);
							dispatchChatMessage(client, "PlayedSound", name, true);
						}
					}
				}
				if (GetConVarBool(cvarlogging)){
					LogToGame("[Say Sounds Log] %s%N  played  %s%s(%s)", isadmin ? "Admin " : "", client,
						   adminonly ? "admin sound " : "", name, filelocation);
				}
			} else if (GetConVarBool(cvarlogging)){
				LogToGame("[Say Sounds Log] played %s", filelocation);
			}
		}
	}

	if(soundLimit > 0 && IsValidClient(client)){
		if (SndCount[client] > soundLimit){
			//PrintToChat(client,"\x04[Say Sounds]\x01 Sorry, you have reached your sound quota!");
			PrintToChat(client,"\x04[Say Sounds] \x01%t", "QuotaReched");
		} else if (SndCount[client] == soundLimit && joinsound != 1){
			//PrintToChat(client,"\x04[Say Sounds]\x01 You have no sounds left to use!");
			PrintToChat(client,"\x04[Say Sounds] \x01%t", "NoSoundsLeft");
			SndCount[client]++; // Increment so we get the sorry message next time.
		} else {
			new soundWarn = isadmin ? GetConVarInt(cvaradminwarn) : GetConVarInt(cvarsoundwarn);	
			if (soundWarn <= 0 || SndCount[client] >= soundWarn){
				new numberleft = (soundLimit -  SndCount[client]);
				if (numberleft == 1 && joinsound != 1)
					//PrintToChat(client,"\x04[Say Sounds]\x01 You only have \x04%d \x01sound left to use!",numberleft);
					PrintToChat(client,"\x04[Say Sounds] \x01%t", "SoundLeft",numberleft);
				else
					//PrintToChat(client,"\x04[Say Sounds]\x01 You only have \x04%d \x01sounds left to use!",numberleft);
					if (joinsound != 1)
						PrintToChat(client,"\x04[Say Sounds] \x01%t", "SoundLeftPlural",numberleft);
			}
		}
	}
	return Plugin_Handled;
}

//*****************************************************************
//	------------------------------------------------------------- *
//					*** Dispatch Chat Messages ***				  *
//	------------------------------------------------------------- *
//*****************************************************************
dispatchChatMessage(client, const String:message[], const String:name[], bool:translate=false)
{
	for(new i = 1; i <= MaxClients; i++) 
	{
		if(IsValidClient(i) && checkClientCookies(i, CHK_CHATMSG)) {
			if(translate && StrEqual(name, "")) {
				PrintToChat(i, "%t", message);
			} else if(translate && !StrEqual(name, "")) {
				PrintToChat(i, "%t", message, client, name);
			} else {
				PrintToChat(i, message);
			}
		}
	}
}

//*****************************************************************
//	------------------------------------------------------------- *
//					*** KARAOKE Handling ***					  *
//	------------------------------------------------------------- *
//*****************************************************************
	//####### Load Karaoke #######
public Load_Karaoke(client, const String:filelocation[], const String:name[], const String:karaoke[]){
	new adminonly = KvGetNum(listfile, "admin", 1); // Karaoke sounds default to admin only
	new bool:isadmin = false;
	if (IsValidClient(client))
	{
		new AdminId:aid = GetUserAdmin(client);
		isadmin = (aid != INVALID_ADMIN_ID) && GetAdminFlag(aid, Admin_Generic, Access_Effective);
		if(adminonly && !isadmin){
			//PrintToChat(client,"\x04[Say Sounds]\x01 Sorry, you are not authorized to play this sound!");
			PrintToChat(client,"\x04[Say Sounds] \x01%t", "AdminSounds");
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

	//####### Karaoke Countdown #######
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

	//####### Karaoke Start #######
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
	Send_Sound(client, filelocation, name, true);
}

	//####### Convert Time #######
Float:Convert_Time(const String:buffer[]){
	decl String:part[5];
	new pos = SplitString(buffer, ":", part, sizeof(part));
	if (pos == -1) {
		return StringToFloat(buffer);
	} else {
		// Convert from mm:ss to seconds
		return (StringToFloat(part)*60.0) +
			StringToFloat(buffer[pos]);
	}
}

	//####### Karaoke Message #######
Karaoke_Message(const String:text[3][]){
	//new playersconnected = GetMaxClients();
	for (new i = 1; i <= MaxClients; i++){
		if(IsValidClient(i) && checkClientCookies(i, CHK_KARAOKE)){
			new team = GetClientTeam(i) - 1;
			if (team >= 1 && text[team][0] != '\0')
				PrintCenterText(i, text[team]);
			else
				PrintCenterText(i, text[0]);
		}
	}
}

	//####### Show Message #######
Show_Message(const String:fmt[], any:...){
        decl String:text[128];
        VFormat(text, sizeof(text), fmt, 2);

	//new playersconnected = GetMaxClients();
	for (new i = 1; i <= MaxClients; i++){
		if(IsValidClient(i) && checkClientCookies(i, CHK_KARAOKE)){
			PrintCenterText(i, text);
		}
	}
}

	//####### Timer Karaoke Countdown #######
public Action:Karaoke_Countdown_Timer(Handle:timer,Handle:pack){
	decl String:filelocation[PLATFORM_MAX_PATH+1];
	decl String:name[PLATFORM_MAX_PATH+1];
	new client = ReadPackCell(pack);
	new Float:time = ReadPackFloat(pack);
	ReadPackString(pack, filelocation , sizeof(filelocation));
	ReadPackString(pack, name , sizeof(name));
	Karaoke_Countdown(client, filelocation, name, time, false);
}

	//####### Timer Karaoke #######
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

//*****************************************************************
//	------------------------------------------------------------- *
//					*** Command Handling ***					  *
//	------------------------------------------------------------- *
//*****************************************************************
	//####### Command Sound Reset #######
public Action:Command_Sound_Reset(client, args){
	if (args < 1){
		//ReplyToCommand(client, "[Say Sounds] Usage: sm_sound_reset <user | all> : Resets sound quota for user, or everyone if all");
		ReplyToCommand(client, "\x04[Say Sounds] \x01%t", "QuotaResetUsage");
		return Plugin_Handled;
	}

	new String:arg[64];
	GetCmdArg(1, arg, sizeof(arg));	

	if (strcmp(arg,"all",false) == 0 ){
		for (new i = 1; i <= MAXPLAYERS; i++)
			SndCount[i] = 0;
		if(client !=0){
			//ReplyToCommand(client, "[Say Sounds] Quota has been reset for all players");
			ReplyToCommand(client, "\x04[Say Sounds] \x01%t", "QuotaResetAll");
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
					//ReplyToCommand(client, "[Say Sounds] Quota has been reset for %s", clientname);
					ReplyToCommand(client, "\x04[Say Sounds] \x01%t", "QuotaResetUser", clientname);
				}
			}
		}else{
			ReplyToTargetError(client, count);
		}
	}
	return Plugin_Handled;
}

	//####### Command Sound Ban #######
public Action:Command_Sound_Ban(client, args){
	if (args < 1)
	{
		//ReplyToCommand(client, "[Say Sounds] Usage: sm_sound_ban <user> : Bans a player from using sounds");
		ReplyToCommand(client, "\x04[Say Sounds] \x01%t", "SoundBanUsage");
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
			if(IsClientConnected(player) && IsClientInGame(player)){
				new String:clientname[64];
				GetClientName(player,clientname,MAXPLAYERS);
				if (checkClientCookies(player, CHK_BANNED)){
					//ReplyToCommand(client, "[Say Sounds] %s is already banned!", clientname);
					ReplyToCommand(client, "\x04[Say Sounds] \x01%t", "AlreadyBanned", clientname);
				}else{
					SetClientCookie(player, g_ssban_cookie, "on");
					//restrict_playing_sounds[player]=1;
					//ReplyToCommand(client,"[Say Sounds] %s has been banned!", clientname);
					ReplyToCommand(client,"\x04[Say Sounds] \x01%t", "PlayerBanned", clientname);
				}
			}
		}
	}else{
		ReplyToTargetError(client, count);
	}
	return Plugin_Handled;
}

	//####### Command Sound Unban #######
public Action:Command_Sound_Unban(client, args){
	if (args < 1)
	{
		//ReplyToCommand(client, "[Say Sounds] Usage: sm_sound_unban <user> <1|0> : Unbans a player from using sounds");
		ReplyToCommand(client, "\x04[Say Sounds] \x01%t", "SoundUnbanUsage");
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
			if(IsClientConnected(player) && IsClientInGame(player)){
				new String:clientname[64];
				GetClientName(player,clientname,MAXPLAYERS);
				if(!checkClientCookies(player, CHK_BANNED)){
					//ReplyToCommand(client,"[Say Sounds] %s is not banned!", clientname);
					ReplyToCommand(client,"\x04[Say Sounds] \x01%t", "NotBanned", clientname);
				}else{
					SetClientCookie(player, g_ssban_cookie, "off");
					//restrict_playing_sounds[player]=0;
					//ReplyToCommand(client,"[Say Sounds] %s has been unbanned!", clientname);
					ReplyToCommand(client,"\x04[Say Sounds] \x01%t", "PlayerUnbanned", clientname);
				}
			}
		}
	}else{
		ReplyToTargetError(client, count);
	}
	return Plugin_Handled;
}

	//####### Command Sound List #######
public Action:Command_Sound_List(client, args){
	List_Sounds(client);
}

//####### List Sounds #######
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

//*****************************************************************
//	------------------------------------------------------------- *
//					*** Create SoundCount DB ***				  *
//	------------------------------------------------------------- *
//*****************************************************************
public InitDB()
{
	// SQL DB
	new String:error[255];
	g_hSoundCountDB = SQLite_UseDatabase("saysounds_soundcount", error, sizeof(error));
	
	if (g_hSoundCountDB == INVALID_HANDLE)
		SetFailState("SQL error: %s", error);
	
	SQL_LockDatabase(g_hSoundCountDB);
	SQL_FastQuery(g_hSoundCountDB, "VACUUM");
	SQL_FastQuery(g_hSoundCountDB, "CREATE TABLE IF NOT EXISTS soundcount_client (steamid TEXT PRIMARY KEY, count SMALLINT, timestamp INTEGER);");
	SQL_UnlockDatabase(g_hSoundCountDB);
}
//*****************************************************************
//	------------------------------------------------------------- *
//				*** Insert SoundCount into DB ***				  *
//	------------------------------------------------------------- *
//*****************************************************************
InsertCountQuery(const String:steamId[], count)
{
	decl String:query[200];
	Format(query, sizeof(query), "INSERT OR REPLACE INTO soundcount_client VALUES ('%s', %d, %d);", steamId, count, GetTime());
	SQL_TQuery(g_hSoundCountDB, EmptySQLCallback, query);
}
public EmptySQLCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
		LogError("SQL Error: %s", error);
}
//*****************************************************************
//	------------------------------------------------------------- *
//				*** Get SoundCount from DB ***				  *
//	------------------------------------------------------------- *
//*****************************************************************
public GetConutDB(client)
{	
	decl String:steamId[30];
	decl String:query[200];
	
	GetClientAuthString(client, steamId, sizeof(steamId));
	Format(query, sizeof(query), "SELECT * FROM	soundcount_client WHERE steamId = '%s';", steamId);
	SQL_TQuery(g_hSoundCountDB, SetSoundCount, query, client);
}

public SetSoundCount(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("SQL Error: %s", error);
		return;
	}
	
	if (SQL_GetRowCount(hndl) == 0)
	{
		return;
	}
	
	if (!IsClientInGame(client))
	{
		return;
	}

	new iCount = SQL_FetchInt(hndl,1);
	SndCount[client] = iCount;
}
//*****************************************************************
//	------------------------------------------------------------- *
//					*** Clearing SoundCount DB ***				  *
//	------------------------------------------------------------- *
//*****************************************************************
ClearDB()
{
	// Clearing SQL DB
	SQL_LockDatabase(g_hSoundCountDB);
	SQL_FastQuery(g_hSoundCountDB, "DELETE FROM soundcount_client;");
	SQL_UnlockDatabase(g_hSoundCountDB);
}