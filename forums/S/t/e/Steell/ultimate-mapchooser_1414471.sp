//Welcome to Steell's Ultimate Mapchooser plugin for SourceMod!
#pragma semicolon 1
#define PL_VERSION "1.9"

//Dependencies
#include <sourcemod.inc>
#include <sdktools_sound.inc>
#include <sdktools_functions.inc>
#include <sdktools_entinput.inc>
#include <sdktools_stringtables.inc>
#include <regex.inc>

//Auto update
#undef REQUIRE_PLUGIN
#include <autoupdate.inc>
#define UPDATE_URL "ccs.neu.edu/home/steell/sourcemod/ultimate-mapchooser"
#define UPDATE_XML "/plugins.xml"

//Some definitions
#define CHANGE_MAP_ACTION_NOW 0
#define CHANGE_MAP_ACTION_ROUNDEND 1
#define CHANGE_MAP_ACTION_MAPEND 2
#define VOTE_TYPE_MAP 0
#define VOTE_TYPE_CAT 1
#define VOTE_TYPE_TIER 2
#define PLAYERLIMIT_ACTION_NOTHING 0
#define PLAYERLIMIT_ACTION_NOW 1
#define PLAYERLIMIT_ACTION_YESNO 2
#define PLAYERLIMIT_ACTION_VOTE 3

//Plugin Information
public Plugin:myinfo =
{
    name        = "Ultimate Mapchooser",
    author      = "Steell",
    description = "Provides advanced control over map selection for the server.",
    version     = PL_VERSION,
    url         = "http://forums.alliedmods.net/showthread.php?t=134190"
};

//Changelog:
/*
2.0 ()
Added new "command" option to map groups and maps defined in the mapcycle. The strings supplied will be executed at the start of the map.
Added some code optimizations.
Improved logging.
Added ability for plugin to search for a map's player limits if the map wasn't changed by the plugin.
Fixed bug with Tiered Votes where votes would fail if the winning group had only one available map.
Fixed bug with data not being cleared when a vote menu fails to be created.
Fixed bug with vote warnings where mp_timelimit was 0.
Fixed bug where strict nominations would sometimes cause duplicate vote entries.
Fixed bug where player limits would stop working.
Fixed bug with group voting where if a nominated map won the winning map wasn't set correctly.
Fixed memory leak with checking for maps with proper time and player counts.
Organized code

2.0-beta (2/5/11)
Added Runoff Vote feature. If a vote end and the winning option is less than a specified threshold, another vote will be run with losing options eliminated.
-Added cvar to control max amount runoffs to run (> 0 enables the feature)
-Added cvar to control the threshold required to prevent a runoff
-Added cvar to control which sound is played at the start of a runoff
-Added cvar to specify whether runoffs are shown to everyone or just players who need to (re)vote.
Added Tiered Votes. If enabled, first players will vote for a category, and then they will vote for a map from that category.
-Modified type cvars to allow for this kind of vote.
-Added cvar to control how many maps are displayed in the vote (after a category is already selected).
Added ability to exclude previously played categories.
-Three new cvars to control this ability.
Added ability to specify how many slots to block (up to 5)
-Modified blocking cvar to allow for this customization.
Internationalisation - Translations are now supported.
Votes will now only paginate when there are more than 9 slots required in the menu.
Added optional auto-updating.
Fixed memory leak with Random Selection of the Next Map.
Fixed memory leak with Vote Warnings.
Fixed bug with Vote Warnings not working after a map change.

1.5.1 (1/26/11)
Added shortcut to vote warnings that allows users to specify a sequence of warnings with one definition.
Fixed issue with time restrictions that prevented max_time from being larger than min_time (necessary for, as an example, 11:00PM - 6:00AM, which would be min_time: 2300  max_time: 0600)
Changed name of plugin from Improved Map Randomizer (IMR) to Ultimate Mapchooser (UMC)

1.5 (1/24/11)
Added vote warning feature. You can now specify warnings which appear to players before an end-of-map vote. Warnings are fully customizeable.
-New cvar to enable/disable this feature.
Added vote sounds. Cvars specify sounds to be played when a vote starts and completed.
-Four new cvars, 2 for end-of-map votes and 2 for RTVs
Added time-based map selection. New "min_time" and "max_time" options added to maps in "random_mapcycle.txt".
Made votes with less than 10 items not have a paginated menu.
Added more chat triggers for RTV. Now accepts: rtv, !rtv, rockthevote, and !rockthevote.
Fixed memory bug with tracking min/max players for a map.
Fixed bug with nominations where some categories stopped appearing in the menu.
Fixed bug with strict nomination cvar and populating votes.
Fixed bug with random group selections where groups with all their maps having been played recently and still excluded would still appear in votes.
Literally commented the entire plugin source code thoroughly. Happy reading!

1.4.1 (8/27/10)
Fixed bug in some mods where random selection of the next map was not being triggered.

1.4 (8/13/10)
Added separate options for when the max player limit and min player limit of the current map is broken.
-Two new cvars to control this feature.
-Old cvar removed.
Added a delay before the plugin checks to see if the current map has a valid number of players.
-New cvar to control this feature.
Added the ability to limit the number of nominations appearing in a vote to the number specified by that group's "maps_invote" setting.
-New cvar to control this feature.

1.3 (8/10/10)
Added vote slot blocking feature. When enabled, the first four vote slots are disabled to prevent accidental votes.
-New cvar to control this feature.
Fixed issues with displaying certain text to clients.
Improved error handling when rotation file is invalid.

1.2 (8/8/10)
Fixed bug where "next_mapgroup" was not working properly with votes.
Fixed bug where current map was appearing in nomination menu.
Added feature where if the current players on the server is not within the range defined by the current map's "min_players" and "max_players", the map can be changed.
-Two new cvars to control this feature.
Nominations now work with group votes.
-When a group wins the vote, it selects a random map from the nominations for that group, taking into account the weights of the maps.

1.1.3 (8/5/10)
Fixed memory bug with nominations.
Fixed (another) bug where random selection of the next map would not work properly.
Added ability to include a "Don't Change" option in RTVs.
-New cvar to enable/disable this ability.
-New cvar to control the delay between an RTV where "Don't Change" wins and the ability for players to RTV again.

1.1.2 (8/4/10)
Fixed bug in DOD:S where plugin could not start due to missing "mp_maxrounds" cvar.

1.1.1 (8/3/10)
Fixed bug where rounds ending would trigger end of map votes even after one was already triggered.
Fixed bug where frags would trigger end of map votes even after one was already triggered.
Fixed bug where current map would appear in votes.
Fixed bug where random selection of the next map would not work properly.

1.1 (8/2/10)
Added public cvar for tracking.
Modified nominations
-Nominations menu now contains all maps in rotation. Nominated maps will now be rejected when considered for inclusion in the vote. This way, players can nominate maps which may be valid when it's time to vote, even if they aren't valid at time of nomination.

1.0 (8/1/10)
Initial Release
*/


//TODO:
// Add customizations for how tiered delay and runoff delay are displayed
//      -Location and text
// Display some sort of vote result in chat for first stage tier and runoff
// Handle tier / runoff displays / vote warnings when there's a vote already in progress.

//************************************************************************************************//
//                                        GLOBAL VARIABLES                                        //
//************************************************************************************************//

//Handle to contain the KV tree storing the map and category data.
new Handle:map_kv = INVALID_HANDLE;

        ////----CONVARS-----/////
//Universal
new Handle:cvar_filename = INVALID_HANDLE;
new Handle:cvar_scramble = INVALID_HANDLE;
new Handle:cvar_vote_time = INVALID_HANDLE;
new Handle:cvar_nominate = INVALID_HANDLE;
new Handle:cvar_invalid_min = INVALID_HANDLE;
new Handle:cvar_invalid_max = INVALID_HANDLE;
new Handle:cvar_invalid_post = INVALID_HANDLE;
new Handle:cvar_invalid_delay = INVALID_HANDLE;
new Handle:cvar_block_slots = INVALID_HANDLE;
new Handle:cvar_strict_noms = INVALID_HANDLE;
new Handle:cvar_runoff = INVALID_HANDLE;
new Handle:cvar_runoff_sound = INVALID_HANDLE;
new Handle:cvar_runoff_threshold = INVALID_HANDLE;
new Handle:cvar_runoff_selective = INVALID_HANDLE;
new Handle:cvar_vote_tieramount = INVALID_HANDLE;
new Handle:cvar_logging = INVALID_HANDLE;

//Random selection of the nextmap
new Handle:cvar_randnext = INVALID_HANDLE;
new Handle:cvar_randnext_mem = INVALID_HANDLE;
new Handle:cvar_randnext_catmem = INVALID_HANDLE;
new Handle:cvar_ignoregweight = INVALID_HANDLE;

//Mapchooser equivalents
new Handle:cvar_endvote = INVALID_HANDLE;
new Handle:cvar_extend_rounds = INVALID_HANDLE;
new Handle:cvar_extend_frags = INVALID_HANDLE;
new Handle:cvar_extend_time = INVALID_HANDLE;
new Handle:cvar_extensions = INVALID_HANDLE;
new Handle:cvar_start_frags = INVALID_HANDLE;
new Handle:cvar_start_time = INVALID_HANDLE;
new Handle:cvar_start_rounds = INVALID_HANDLE;
new Handle:cvar_vote_mem = INVALID_HANDLE;

//End-of-map vote extras
new Handle:cvar_vote_type = INVALID_HANDLE;
new Handle:cvar_warnings = INVALID_HANDLE;
new Handle:cvar_vote_startsound = INVALID_HANDLE;
new Handle:cvar_vote_endsound = INVALID_HANDLE;
new Handle:cvar_vote_catmem = INVALID_HANDLE;

//RTV equivalents
new Handle:cvar_rtv_enable = INVALID_HANDLE;
new Handle:cvar_rtv_changetime = INVALID_HANDLE;
new Handle:cvar_rtv_delay = INVALID_HANDLE;
new Handle:cvar_rtv_minplayers = INVALID_HANDLE;
new Handle:cvar_rtv_postaction = INVALID_HANDLE;
new Handle:cvar_rtv_needed = INVALID_HANDLE;
new Handle:cvar_rtv_interval = INVALID_HANDLE;

//RTV extras
new Handle:cvar_rtv_mem = INVALID_HANDLE;
new Handle:cvar_rtv_catmem = INVALID_HANDLE;
new Handle:cvar_rtv_type = INVALID_HANDLE;
new Handle:cvar_rtv_dontchange = INVALID_HANDLE;
new Handle:cvar_rtv_startsound = INVALID_HANDLE;
new Handle:cvar_rtv_endsound = INVALID_HANDLE;
        ////----/CONVARS-----/////
            
            
//Stores the number of runoffs available.
new remaining_runoffs;

//Memory queues. Used to store the previously played maps.
new Handle:vote_mem_arr     = INVALID_HANDLE;
new Handle:rtv_mem_arr      = INVALID_HANDLE;
new Handle:randnext_mem_arr = INVALID_HANDLE;
new Handle:vote_catmem_arr     = INVALID_HANDLE;
new Handle:rtv_catmem_arr      = INVALID_HANDLE;
new Handle:randnext_catmem_arr = INVALID_HANDLE;

//Timers
new Handle:vote_timer = INVALID_HANDLE; //Timer which handles end-of-map vote based off of time
                                        //remaining.

//Stores the next category to randomly select a map from.
new String:next_rand_cat[255];

//Stores the current category.
new String:current_cat[255];

//Stores the category of the next map.
new String:next_cat[255];

//Stores config file to be executed for the category
new String:cat_config[255];

//Stores the config file to be executed for the map
new String:map_config[255];

//Stores the categories for the map vote menu, so the next category
//can be set after the winning map is selected.
new Handle:map_vote_cat_configs = INVALID_HANDLE; //Stores the config to be executed for the cat
new Handle:map_vote_map_configs = INVALID_HANDLE; //Stores the config to be executed for the map
new Handle:map_vote_next_cats = INVALID_HANDLE; //Stores the next_cat element of each map.
new Handle:map_vote_cats = INVALID_HANDLE; //Stores the cat of each map.
new Handle:map_vote = INVALID_HANDLE; //Stores the maps, used to look up the indexes so the other
                                      //arrays can be accessed.

new Handle:rtv_clients = INVALID_HANDLE; //Array of players who have RTV'd

new Handle:nominations_arr = INVALID_HANDLE; //Array of nomination tries.
new Handle:nomination_cats[MAXPLAYERS+1]; //Array containing adt_arrays of nominated map categories.
new Handle:nomination_weights[MAXPLAYERS+1]; //Array contrining adt_arrays of nominated map weights.
//EACH INDEX OF THE ABOVE TWO ARRAYS CORRESPONDS TO A NOMINATION MENU FOR A PARTICULAR CLIENT.

//Limit Cvars
new Handle:cvar_maxrounds = INVALID_HANDLE; //Round limit cvar
new Handle:cvar_fraglimit = INVALID_HANDLE; //Frag limit cvar

//Used to hold original values for the limit cvars, in order to reset them to the correct value when
//the map changes.
new maxrounds_mem;
new fraglimit_mem;
new bool:catch_change = false; //Flag used to ignore changes to the limit cvars.

//How many people are required to trigger an RTV.
new rtv_threshold = 0;

//Flags
new bool:timer_alive;      //Is the time-based vote timer ticking?
new bool:vote_completed;   //Has a vote been completed?
new bool:rtv_completed;    //Has an rtv been completed?
new bool:rtv_enabled;      //Are we able to RTV? Used by the rtv timer to disallow early RTVs.
new bool:vote_enabled;     //Are we able to run a vote? Means that the timer is running.
new bool:validity_enabled; //Are we monitoring the amount of players to be within the valid bounds?

//Stores whether or not players have seen the long RTV message.
new bool:rtv_message[MAXPLAYERS+1];

//Keeps track of a delay before we are able to RTV.
new Float:rtv_delaystart;

//Keeps track of the time before the end-of-map vote starts.
new Float:vote_delaystart;

//Variable to store the delay between stages of a tiered vote.
new tiered_delay;

//Variable to store the delay before a runoff vote starts.
new runoff_delay;

//Counts the rounds.
new round_counter = 0;

//Counts the number of available extensions.
new extend_counter;

//Keeps track of the minimum and maximum allowed players for this map.
new map_min_players;
new map_max_players;

//Vote Warnings
new Handle:vote_warnings = INVALID_HANDLE; //adt_array of vote warnings
new next_warning; //index of the next warning to be displayed

//Used to display a vote at the end of a round if the mod doesn't support the round_end event.
new UserMsg:VGuiMenu;
new bool:intermission_called;

//Sounds to be played at the start and end of votes.
new String:vote_start_sound[PLATFORM_MAX_PATH], String:vote_end_sound[PLATFORM_MAX_PATH],
    String:rtv_start_sound[PLATFORM_MAX_PATH], String:rtv_end_sound[PLATFORM_MAX_PATH],
    String:runoff_start_sound[PLATFORM_MAX_PATH];
    
//Color Arrays for colors in warning messages.
static g_iSColors[7]             = {1, 3, 3, 4, 4, 5, 6};
static String:g_sSColors[7][13]  = {"{DEFAULT}", "{LIGHTGREEN}", "{TEAM}", "{GREEN}", "{RED}",
                                    "{DARKGREEN}", "{YELLOW}"};
static g_iTColors[13][3]         = {{255, 255, 255}, {255,   0,   0}, {  0, 255,   0}, 
                                    {  0,   0, 255}, {255, 255,   0}, {255,   0, 255},
                                    {  0, 255, 255}, {255, 128,   0}, {255,   0, 128},
                                    {128, 255,   0}, {  0, 255, 128}, {128,   0, 255}, 
                                    {  0, 128, 255}};
static String:g_sTColors[13][12] = {"{WHITE}", "{RED}", "{GREEN}", "{BLUE}", "{YELLOW}", "{PURPLE}",
                                    "{CYAN}", "{ORANGE}", "{PINK}", "{OLIVE}", "{LIME}", "{VIOLET}",    
                                    "{LIGHTBLUE}"};

//Handle to the Center Message timer. For Vote Warnings.
new Handle:center_message_timer = INVALID_HANDLE;
new bool:center_warning_active = false;

//Handle to the TF2 Game Message entity timer. For Vote Warnings.
new Handle:game_message_timer = INVALID_HANDLE;
new bool:game_message_active = false;

//Variable to hold the built runoff menu until after the runoff timer has finished.
new Handle:runoff_menu = INVALID_HANDLE;

//Variable to hold the array of clients the runoff will be displayed to.
new Handle:runoff_clients = INVALID_HANDLE;


//************************************************************************************************//
//                                        SOURCEMOD EVENTS                                        //
//************************************************************************************************//

//Called when the plugin is finished loading.
public OnPluginStart()
{
    //Initialize our new Cvars.
    cvar_logging = CreateConVar(
        "sm_umc_logging_verbose",
        "0",
        "Enables in-depth logging. Use this to have the plugin log how votes are\nbeing populated.",
        0, true, 0.0, true, 1.0
    );
    
    cvar_runoff_threshold = CreateConVar(
        "sm_umc_runoff_threshold",
        ".50",
        "If a winning vote has less than this percentage of total votes, a runoff vote\nwill be held.",
        0, true, 0.0, true, 0.5
    );
    
    cvar_runoff_selective = CreateConVar(
        "sm_umc_runoff_selective",
        "0",
        "Specifies whether runoff votes are only displayed to players whose votes were\neliminated in the runoff and players who did not vote.",
        0, true, 0.0, true, 1.0
    );
    
    cvar_vote_tieramount = CreateConVar(
        "sm_umc_vote_tieramount",
        "6",
        "Specifies the maximum number of maps to appear in the second part of a tiered\nvote.",
        0, true, 2.0
    );

    cvar_runoff = CreateConVar(
        "sm_umc_runoffs",
        "0",
        "Specifies a maximum number of runoff votes to run for any given vote.\n 0 disables runoff votes.",
        0, true, 0.0
    );
    
    cvar_runoff_sound = CreateConVar(
        "sm_umc_runoff_sound",
        "",
        "If specified, this sound file (relative to sound folder) will be played at\nthe beginning of a runoff vote. If not specified, it will use the default\nsound, as defined in other cvars."
    );
    
    cvar_rtv_catmem = CreateConVar(
        "sm_umc_rtv_groupexclude",
        "0",
        "Specifies how many past map groups to exclude from RTVs.",
        0, true, 0.0
    );
    
    cvar_vote_catmem = CreateConVar(
        "sm_umc_endvote_groupexclude",
        "0",
        "Specifies how many past map groups to exclude from the end of map vote.",
        0, true, 0.0
    );
    
    cvar_randnext_catmem = CreateConVar(
        "sm_umc_randcycle_groupexclude",
        "0",
        "Specifies how many past map groups to exclude when picking a random map.",
        0, true, 0.0
    );
    
    cvar_ignoregweight = CreateConVar(
        "sm_umc_randcycle_nogroupweight",
        "0",
        "Specifies whether or not group weighting is ignored. Use this if you want\nUltimate Mapchooser to select maps as if they were all in one group, rather\nthan selecting a random group first before selecting a random map.",
        0, true, 0.0, true, 1.0
    );
    
    cvar_rtv_startsound = CreateConVar(
        "sm_umc_rtv_startsound",
        "",
        "Sound file (relative to sound folder) to play at the start of an RTV."
    );
    
    cvar_rtv_endsound = CreateConVar(
        "sm_umc_rtv_endsound",
        "",
        "Sound file (relative to sound folder) to play at the completion of an RTV."
    );
    
    cvar_vote_startsound = CreateConVar(
        "sm_umc_endvote_startsound",
        "",
        "Sound file (relative to sound folder) to play at the start of an end-of-map\nvote."
    );
    
    cvar_vote_endsound = CreateConVar(
        "sm_umc_endvote_endsound",
        "",
        "Sound file (relative to sound folder) to play at the completion of an\nend-of-map vote."
    );
    
    cvar_warnings = CreateConVar(
        "sm_umc_endvote_warnings",
        "1",
        "Specifies whether vote warnings are displayed to players during the period\nleading up to an end-of-map vote (see vote_warnings.txt).",
        0, true, 0.0, true, 1.0
    );
    
    cvar_strict_noms = CreateConVar(
        "sm_umc_nominate_strict",
        "0",
        "Specifies whether the number of nominated maps appearing in the vote for a\nmap group should be limited by the group's \"maps_invote\" setting.",
        0, true, 0.0, true, 1.0
    );

    cvar_invalid_delay = CreateConVar(
        "sm_umc_playerlimit_delay",
        "240.0",
        "Time in seconds before the plugin will check to see if the current number of\nplayers is within the map's bounds.",
        0, true, 0.0
    );

    cvar_block_slots = CreateConVar(
        "sm_umc_vote_blockslots",
        "0",
        "Specifies how many slots in a vote are disabled to prevent accidental voting.",
        0, true, 0.0, true, 5.0
    );

    cvar_invalid_min = CreateConVar(
        "sm_umc_playerlimit_minaction",
        "0",
        "Specifies what action to take when the number of players on the server is\nless than what the current map allows.\n 0 - Do Nothing,\n 1 - Pick a map, change to it,\n 2 - Pick a map, run a yes/no vote to change,\n 3 - Run a full mapvote, change to the winner.",
        0, true, 0.0, true, 3.0
    );

    cvar_invalid_max = CreateConVar(
        "sm_umc_playerlimit_maxaction",
        "0",
        "Specifies what action to take when the number of players on the server is\nmore than what the current map allows.\n 0 - Do Nothing,\n 1 - Pick a map, change to it,\n 2 - Pick a map, run a yes/no vote to change,\n 3 - Run a full mapvote, change to the winner.",
        0, true, 0.0, true, 3.0
    );

    cvar_invalid_post = CreateConVar(
        "sm_umc_playerlimit_voteaction",
        "0",
        "Specifies when to change the map after an action is taken due to too many or\ntoo little players.\n 0 - Change instantly,\n 1 - Change at the end of the round",
        0, true, 0.0, true, 1.0
    );

    cvar_rtv_interval = CreateConVar(
        "sm_umc_rtv_interval",
        "240",
        "Time (in seconds) after a failed RTV before another can be held.",
        0, true, 0.0
    );

    cvar_rtv_dontchange = CreateConVar(
        "sm_umc_rtv_dontchange",
        "1",
        "Adds a \"Don't Change\" option to RTVs.",
        0, true, 0.0, true, 1.0
    );

    CreateConVar(
        "improved_randomizer_version",
        PL_VERSION,
        "Ultimate Mapchooser's version",
        FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED
    );

    cvar_nominate = CreateConVar(
        "sm_umc_nominate_enabled",
        "1",
        "Specifies whether players have the ability to nominate maps for votes.",
        0, true, 0.0, true, 1.0
    );

    cvar_extend_rounds = CreateConVar(
        "sm_umc_extend_roundstep",
        "5",
        "Specifies how many more rounds each extension adds to the round limit.",
        0, true, 1.0
    );

    cvar_extend_time = CreateConVar(
        "sm_umc_extend_timestep",
        "15",
        "Specifies how many more minutes each extension adds to the time limit.",
        0, true, 1.0
    );

    cvar_extend_frags = CreateConVar(
        "sm_umc_extend_fragstep",
        "10",
        "Specifies how many more frags each extension adds to the frag limit.",
        0, true, 1.0
    );

    cvar_extensions = CreateConVar(
        "sm_umc_extends",
        "0",
        "Number of extensions allowed each map. 0 disables the Extend option.",
        0, true, 0.0
    );

    cvar_rtv_postaction = CreateConVar(
        "sm_umc_rtv_postvoteaction",
        "0",
        "What to do with RTVs after an end-of-map vote has completed.\n 0 - Allow, success = instant change,\n 1 - Deny",
        0, true, 0.0, true, 1.0
    );

    cvar_rtv_minplayers = CreateConVar(
        "sm_umc_rtv_minplayers",
        "0",
        "Number of players required before RTV will be enabled.",
        0, true, 0.0, true, float(MAXPLAYERS)
    );

    cvar_rtv_delay = CreateConVar(
        "sm_umc_rtv_initialdelay",
        "30",
        "Time (in seconds) before first RTV can be held.",
        0, true, 0.0
    );

    cvar_rtv_changetime = CreateConVar(
        "sm_umc_rtv_changetime",
        "0",
        "When to change the map after a successful RTV:\n 0 - Instant,\n 1 - Round End,\n 2 - Map End",
        0, true, 0.0, true, 2.0
    );

    cvar_rtv_needed = CreateConVar(
        "sm_umc_rtv_percent",
        "0.65",
        "Percentage of players required to trigger an RTV vote.",
        0, true, 0.0, true, 1.0
    );

    cvar_rtv_enable = CreateConVar(
        "sm_umc_rtv_enabled",
        "1",
        "Enables RTV.",
        0, true, 0.0, true, 1.0
    );

    cvar_rtv_type = CreateConVar(
        "sm_umc_rtv_type",
        "0",
        "Controls RTV vote type:\n 0 - Maps,\n 1 - Groups,\n 2 - Tiered Vote (vote for a group, then vote for a map from the group).",
        0, true, 0.0, true, 2.0
    );

    cvar_endvote = CreateConVar(
        "sm_umc_endvote_enabled",
        "1",
        "Specifies if Ultimate Mapchooser should run an end of map vote.",
        0, true, 0.0, true, 1.0
    );

    cvar_vote_type = CreateConVar(
        "sm_umc_endvote_type",
        "0",
        "Controls end of map vote type:\n 0 - Maps,\n 1 - Groups,\n 2 - Tiered Vote (vote for a group, then vote for a map from the group).",
        0, true, 0.0, true, 2.0
    );

    cvar_randnext = CreateConVar(
        "sm_umc_randcycle_enabled",
        "1",
        "Enables random selection of the next map at the end of each map if a vote\nhasn't taken place.",
        0, true, 0.0, true, 1.0
    );

    cvar_start_time = CreateConVar(
        "sm_umc_endvote_starttime",
        "6",
        "Specifies when to start the vote based on time remaining in minutes.",
        0, true, 1.0
    );

    cvar_start_rounds = CreateConVar(
        "sm_umc_endvote_startrounds",
        "2",
        "Specifies when to start the vote based on rounds remaining. Use 0 on TF2 to\nstart vote during bonus round time",
        0, true, 0.0
    );

    cvar_start_frags = CreateConVar(
        "sm_umc_endvote_startfrags",
        "10",
        "Specifies when to start the vote based on frags remaining.",
        0, true, 1.0
    );

    cvar_vote_time = CreateConVar(
        "sm_umc_vote_duration",
        "20",
        "Specifies how long a vote should be available for.",
        0, true, 10.0
    );

    cvar_filename = CreateConVar(
        "sm_umc_cyclefile",
        "umc_mapcycle.txt",
        "File to use for Ultimate Mapchooser's map rotation."
    );

    cvar_vote_mem = CreateConVar(
        "sm_umc_endvote_mapexclude",
        "3",
        "Specifies how many past maps to exclude from the end of map vote.",
        0, true, 0.0
    );

    cvar_rtv_mem = CreateConVar(
        "sm_umc_rtv_mapexclude",
        "3",
        "Specifies how many past maps to exclude from RTVs.",
        0, true, 0.0
    );

    cvar_randnext_mem = CreateConVar(
        "sm_umc_randcycle_mapexclude",
        "3",
        "Specifies how many past maps to exclude when picking a random map.",
        0, true, 0.0
    );

    cvar_scramble = CreateConVar(
        "sm_umc_vote_menuscrambled",
        "0",
        "Specifies whether vote menu items are displayed in a random order.",
        0, true, 0.0, true, 1.0
    );

    //Create the config if it doesn't exist, and then execute it.
    AutoExecConfig(true, "ultimate_mapchooser");

    //Admin command to immediately start a mapvote.
    RegAdminCmd(
        "sm_umc_mapvote",
        Command_Vote,
        ADMFLAG_RCON,
        "Starts an Ultimate Mapchooser map vote."
    );

    //Admin command to reload the mapcycle.
    RegAdminCmd(
        "sm_umc_reload_file",
        Command_Reload,
        ADMFLAG_RCON,
        "Reloads the Ultimate Mapchooser mapcycle file."
    );

    //Admin commmand to pick a random nextmap.
    RegAdminCmd(
        "sm_umc_picknextmapnow",
        Command_Random,
        ADMFLAG_RCON,
        "Makes Ultimate Mapchooser pick a random nextmap."
    );

    //Set up our "timers" for the end-of-map vote.
    cvar_maxrounds = FindConVar("mp_maxrounds");
    cvar_fraglimit = FindConVar("mp_fraglimit");
    
    //Hook roundlimit
    if (cvar_maxrounds == INVALID_HANDLE)
        cvar_maxrounds = CreateConVar("mp_maxrounds", "0", "");
    HookConVarChange(cvar_maxrounds, Handle_MaxroundsChange);
    
    //Hook fraglimit
    if (cvar_maxrounds == INVALID_HANDLE)
        cvar_fraglimit = CreateConVar("mp_fraglimit", "0", "");
    HookConVarChange(cvar_fraglimit, Handle_FraglimitChange);

    //Hook end of round.
    HookEvent("round_end", Event_RoundEnd); //Generic
    HookEventEx("game_round_end", Event_RoundEnd); //Hidden: Source, Neotokyo
    HookEventEx("teamplay_round_win", Event_RoundEndTF2); //TF2
    
    //Hook score.
    HookEvent("player_score", Event_ScoreUpdated);
    
    //Hook end of game.
    HookEventEx("dod_game_over", Event_GameEnd); //DoD
    HookEventEx("teamplay_game_over", Event_GameEnd); //TF2
    HookEventEx("game_newmap", Event_GameEnd); //Insurgency
    
    //Hook intermission (for games which don't have round_end or equivalent event)
    new String:game[20];
    GetGameFolderName(game, sizeof(game));
    if (!StrEqual(game, "tf", false) &&
        !StrEqual(game, "dod", false) &&
        !StrEqual(game, "insurgency", false))
    {
        LogMessage("SETUP: Hooking intermission...");
        VGuiMenu = GetUserMessageId("VGUIMenu");
        HookUserMessage(VGuiMenu, _VGuiMenu);
    }

    //Make listeners for player chat. Needed to recognize chat commands ("rtv", etc.)
    AddCommandListener(OnPlayerChat, "say");
    AddCommandListener(OnPlayerChat, "say2"); //Insurgency Only
    AddCommandListener(OnPlayerChat, "say_team");

    //Hook all necessary cvar changes
    HookConVarChange(cvar_vote_mem,     Handle_VoteMemoryChange);
    HookConVarChange(cvar_rtv_mem,      Handle_RTVMemoryChange);
    HookConVarChange(cvar_randnext_mem, Handle_RandNextMemoryChange);
    HookConVarChange(cvar_endvote,      Handle_VoteChange);
    HookConVarChange(cvar_start_time,   Handle_TriggerChange);
    HookConVarChange(cvar_rtv_enable,   Handle_RTVChange);
    HookConVarChange(cvar_rtv_needed,   Handle_ThresholdChange);
    HookConVarChange(cvar_runoff,       Handle_RunoffChange);

    //Initialize our memory arrays
    vote_mem_arr = CreateArray(255, 0);
    vote_catmem_arr = CreateArray(255, 0);
    rtv_mem_arr = CreateArray(255, 0);
    rtv_catmem_arr = CreateArray(255, 0);
    randnext_mem_arr = CreateArray(255, 0);
    randnext_catmem_arr = CreateArray(255, 0);
    map_vote_cat_configs = CreateArray(255, 0);
    map_vote_map_configs = CreateArray(255, 0);
    map_vote_next_cats = CreateArray(255, 0);
    map_vote_cats = CreateArray(255, 0);
    map_vote = CreateArray(255, 0);
    rtv_clients = CreateArray();
    nominations_arr = CreateArray();
    vote_warnings = CreateArray(255, 0);
    
    //Load the translations file
    LoadTranslations("ultimate-mapchooser.phrases");
}


//Called when all plugins for sourcemod have been loaded.
public OnAllPluginsLoaded()
{ 
    //Setup autoupdating if...
    //  ...the auto update plugin is loaded.
    if(LibraryExists("pluginautoupdate"))
    {
        AutoUpdate_AddPlugin(UPDATE_URL, UPDATE_XML, PL_VERSION);
        LogMessage("SETUP: Auto-updating has been successfully setup.");
    }
}


//Called when the plugin is about to be deactived. Used to reset all modified cvars (limit cvars).
public OnPluginEnd()
{
    //Reset all modified cvars to original values.
    RestoreCvars();
    
    //Remove auto updating if...
    //  ...the auto update plugin is loaded.
    if(LibraryExists("pluginautoupdate"))
    {
        AutoUpdate_RemovePlugin();
        LogMessage("CLEANUP: Auto-updating has been successfully disabled.");
    }
}


//************************************************************************************************//
//                                           GAME EVENTS                                          //
//************************************************************************************************//

//Called at the start of a new map
public OnMapStart()
{
    //Grab the name of the current map.
    decl String:mapName[255];
    GetCurrentMap(mapName, sizeof(mapName));
    
    //Add the map to all the memory queues.
    AddToMemoryArray(mapName, rtv_mem_arr, GetConVarInt(cvar_rtv_mem) + 1);
    AddToMemoryArray(mapName, vote_mem_arr, GetConVarInt(cvar_vote_mem) + 1);
    AddToMemoryArray(mapName, randnext_mem_arr, GetConVarInt(cvar_randnext_mem) + 1);
    
    if (strlen(current_cat) > 0)
    {
        AddToMemoryArray(current_cat, rtv_catmem_arr, GetConVarInt(cvar_rtv_catmem));
        AddToMemoryArray(current_cat, vote_catmem_arr, GetConVarInt(cvar_vote_catmem));
        AddToMemoryArray(current_cat, randnext_catmem_arr, GetConVarInt(cvar_randnext_catmem));
    }
    
    //Reload the mapcycle.
    map_kv = GetMapcycle();
    
    //Reset entire plugin if...
    //    ...the mapcycle was successfully reloaded.
    if (map_kv != INVALID_HANDLE)
        FullReset();
}


//Called after all config files were executed.
public OnConfigsExecuted()
{
    //Execute configs
    if (strlen(cat_config) > 0)
    {
        LogMessage("SETUP: Executing map group command: '%s'", cat_config);
        ServerCommand(cat_config); //First the cat
    }
    if (strlen(map_config) > 0)
    {
        LogMessage("SETUP: Executing map command: '%s'", map_config);
        ServerCommand(map_config); //Then the map
    }
    
    //Clear the stored commands now that they've been executed
    strcopy(cat_config, sizeof(cat_config), "");
    strcopy(map_config, sizeof(map_config), "");

    //Set initial values for cvar value storage.
    maxrounds_mem = GetConVarInt(cvar_maxrounds);
    fraglimit_mem = GetConVarInt(cvar_fraglimit);
    
    //Setup the vote warnings if...
    //  ...there is going to be a vote.
    if (map_kv != INVALID_HANDLE)
        SetupVoteWarnings();
    
    //Setup vote sounds.
    SetupVoteSounds();
}


//Called when a client enters the server.
//Required for checking for min/max players and updating the RTV threshold.
public OnClientPutInServer(client)
{
    //Get the number of players.
    new clientCount = GetRealClientCount();
    
    //Update the RTV threshold if...
    //    ...RTV is enabled.
    if (GetConVarBool(cvar_rtv_enable))
        UpdateRTVThreshold(clientCount);
        
    //Change the map if...
    //    ...the flag to perform the min/max player check is enabled AND
    //    ...the cvar to check for max players is enabled AND
    //    ...the number of players on the server exceeds the limit set by the map.
    if (validity_enabled && GetConVarInt(cvar_invalid_max) != 0 && clientCount > map_max_players)
    {
        LogMessage("PLAYERLIMITS: Number of clients above player threshold. %i clients, %i max.",
            clientCount, map_max_players);
        if (GetConVarInt(cvar_invalid_max) != PLAYERLIMIT_ACTION_NOTHING)
        {
            PrintToChatAll("[UMC] %t", "Too Many players", map_max_players);
            ChangeToValidMap(cvar_invalid_max);
        }
    }
}


//Called when a player types in chat.
//Required to handle user commands.
public Action:OnPlayerChat(client, const String:command[], argc)
{
    //Return immediately if...
    //    ...nothing was typed.
    if (argc == 0) return Plugin_Continue;

    //Get what was typed.
    decl String:text[10];
    GetCmdArg(1, text, sizeof(text));
    
    //Get the number of clients who have RTV'd.
    new size = GetArraySize(rtv_clients);
    
    //Handle RTV client-command if...
    //    ...RTV is enabled AND
    //    ...the client typed a valid RTV command AND
    //    ...the required number of clients for RTV hasn't been reached already AND
    //    ...the client isn't the console.
    if (GetConVarBool(cvar_rtv_enable)
        && (StrEqual(text, "rtv", false) 
            || StrEqual(text, "!rtv", false)
            || StrEqual(text, "/rtv", false)
            || StrEqual(text, "rockthevote", false)
            || StrEqual(text, "!rockthevote", false)
            || StrEqual(text, "/rockthevote", false))
        && size < rtv_threshold
        && client != 0)
    {
        //Print a message if...
        //    ...the number of players on the server is less than the minimum required to RTV.
        if (GetConVarInt(cvar_rtv_minplayers) > GetRealClientCount())
        {
            PrintToChat(
                client,
                "[UMC] %t",
                "No RTV Player Count",
                    GetConVarInt(cvar_rtv_minplayers) - GetRealClientCount()
            );
            return Plugin_Handled;
        }
        //Otherwise, print a message if...
        //    ...an RTV has already been completed OR
        //    ...a vote has already been completed and RTVs after votes aren't allowed.
        else if (rtv_completed || (vote_completed && GetConVarBool(cvar_rtv_postaction)))
        {
            PrintToChat(client, "[UMC] %t", "No RTV Nextmap");
            return Plugin_Handled;
        }
        //Otherwise, print a message if...
        //    ...it is too early to RTV.
        else if (!rtv_enabled)
        {
            PrintToChat(client, "[UMC] %t", "No RTV Time", rtv_delaystart);
            return Plugin_Handled;
        }
        //Othwise, accept RTV command if...
        //    ...the client hasn't already RTV'd.
        else if (FindValueInArray(rtv_clients, client) == -1)
        {
            //Add client to RTV array.
            PushArrayCell(rtv_clients, client);
            
            //Get the name of the client.
            decl String:name[MAX_NAME_LENGTH];
            GetClientName(client, name, sizeof(name));
            
            //Increase the tracked size to account for the new addition.
            size++;
            
            //Display an RTV message to a client for...
            //    ...each client on the server.
            for (new i = 1; i <= MaxClients; i++)
            {
                //Display initial (long) RTV message if...
                //    ...the client hasn't seen it yet.
                if (!rtv_message[i])
                {
                    //Display message if...
                    //    ...the client can actually see it.
                    if (IsClientInGame(i))
                    {
                        //Remember that the client has now seen this message.
                        rtv_message[i] = true;
                        PrintToChat(
                            i, 
                            "[UMC] %t %t (%t)",
                            "RTV Entered",
                                name,
                            "RTV Info Msg",
                            "More Required",
                                rtv_threshold - size
                        );
                    }
                }
                else //Otherwise, print the standard message.
                {
                    PrintToChat(
                        i,
                        "[UMC] %t (%t)",
                        "RTV Entered",
                            name,
                        "More Required",
                            rtv_threshold - size
                    );
                }
            }
            
            //Start RTV if...
            //    ...the new size has surpassed the threshold required to RTV.
            if (size >= rtv_threshold)
            {
                //Start the vote if...
                //    ...there isn't one happening already.
                if (!IsVoteInProgress())
                {
                    PrintToChatAll("[UMC] %t", "RTV Start");
                    StartRTV();
                }
                else //Otherwise, display a message.
                    PrintToChat(client, "[UMC] %t", "Vote In Progress");
            }
        }
        //Otherwise, display a message to the client if...
        //    ...the client has already RTV'd.
        else if (FindValueInArray(rtv_clients, client) != -1)
        {
            PrintToChat(
                client,
                "[UMC] %t (%t)",
                "RTV Already Entered",
                "More Required",
                    rtv_threshold - size
            );
        }
        return Plugin_Handled;
    }
    //Otherwise, handle nomination client-command if...
    //    ...nominations are enabled AND
    //    ...the client isn't the console AND
    //    ...the client typed a valid nominate command.
    else if (GetConVarBool(cvar_nominate)
        && client != 0
        && (StrEqual(text, "nominate", false) 
            || StrEqual(text, "!nominate", false)
            || StrEqual(text, "/nominate", false)))
    {
        //Block nomination and diplay a message if...
        //    ...an rtv has already been completed OR
        //    ...an end-of-map vote has already been completed OR
        //    ...a vote is currently in progress OR
        //    ...the client has already nominated.
        if (rtv_completed || vote_completed || IsVoteInProgress() ||
            FindClientNomination(client) != -1)
        {
            PrintToChat(client, "[UMC] %t", "No Nominate Nextmap");
        }
        else //Otherwise, let them nominate.
        {
            DisplayNominationMenu(client);
        }
        return Plugin_Handled;
    }
    //Otherwise, handle plugin-info client-command if...
    //    ...the client typed a valid info command.
    else if (StrEqual(text, "imr", false) || StrEqual(text, "!imr", false)
             || StrEqual(text, "umc", false) || StrEqual(text, "!umc", false))
    {
        PrintToChatAll(
            "[SM] Ultimate Mapchooser v%s by Steell",
            PL_VERSION
        );
    }
    //Otherwise. handle nextmap client-command if...
    //  ...the client typed a valid nextmap command.
    else if (StrEqual(text, "nextmap", false) || StrEqual(text, "!nextmap", false))
    {
        if (GetConVarBool(cvar_endvote))
        {
            if (!vote_completed)
                PrintToChatAll("[UMC] %t", "Pending Vote");
            else
                PrintNextMap();
        }
        else if (GetConVarBool(cvar_rtv_enable))
        {
            if (rtv_completed)
                PrintNextMap();
        }
        return Plugin_Handled;
    }
    return Plugin_Continue;
}


//Called when the score has been updated. Used for end-of-map vote based on frags.
public Event_ScoreUpdated(Handle:evnt, String:name[], bool:dontBroadcast)
{
    //Get the frag count required to trigger the vote from the cvar.
    new startfrags = GetConVarInt(cvar_start_frags);
    
    //Stop all timers and start an end-of-map vote if...
    //    ...the starting frag value is greater than zero (aka the setting is enabled) AND
    //    ...we haven't already completed an end-of-map vote AND
    //    ...we haven't already completed an RTV AND
    //    ...end-of-map votes are enabled AND
    //    ...the highest score is greater than or equal to the score required to trigger the vote.
    if (startfrags > 0 && !vote_completed && !rtv_completed && vote_enabled &&
        GetHighestScore() >= (GetConVarInt(cvar_fraglimit) - startfrags))
    {
        DestroyTimers();
        StartMapVote();
    }
}


//Called when a client has left the server.
//Needed to update RTV and nominations.
public OnClientDisconnect(client)
{
    //Remove this client from people who have seen the extended RTV message.
    rtv_message[client] = false;
    
    //Find this client in the array of clients who have entered RTV.
    new index = FindValueInArray(rtv_clients, client);
    
    //Remove the client from the RTV array if...
    //    ...the client is in the array to begin with.
    if (index != -1)
        RemoveFromArray(rtv_clients, index);

    //Find this client in the pool of clients who have nominated.
    index = FindClientNomination(client);
    
    //Remove the client from the nomination pool if...
    //    ...the client is in the pool to begin with.
    if (index != -1)
        RemoveFromArray(nominations_arr, index);
}


//Called after a client has left the server.
//Needed to update RTV and the check that the server has the required number of players for the map.
public OnClientDisconnect_Post(client)
{
    //Recalculate the RTV threshold.
    UpdateRTVThreshold(GetRealClientCount());
    
    //Start RTV if...
    //    ...we haven't had an RTV already AND
    //    ...the new amount of players on the server as passed the required threshold.
    if (!rtv_completed && GetArraySize(rtv_clients) >= rtv_threshold)
    {
        PrintToChatAll("[UMC] %t", "Player Disconnect RTV");
        StartRTV();
    }
    //Otherwise, change to a map whose min/max player requirements are met by the server if...
    //    ...the flag to check for min/max players is enabled AND
    //    ...the cvar to check for min players is enabled AND
    //    ...the number of players on the server is less than the minumum required by the map.
    else if (validity_enabled && GetConVarInt(cvar_invalid_min) != 0 &&
            GetRealClientCount() < map_min_players)
    {
        LogMessage("PLAYERLIMITS: Number of clients below player threshold: %i clients, %i min",
            GetRealClientCount(), map_min_players);
        if (GetConVarInt(cvar_invalid_min) != PLAYERLIMIT_ACTION_NOTHING)
            PrintToChatAll("[UMC] %t", "Not Enough Players", map_min_players);
        ChangeToValidMap(cvar_invalid_min);
    }
}


//Called if the the amount of map time left is changed at any point.
//Needed to update our vote timer.
public OnMapTimeLeftChanged()
{
    //Update the end-of-map vote timer if...
    //    ...we haven't already completed an RTV.
    if (!rtv_completed)
        UpdateTimers();
}


//Called when a round ends.
public Event_RoundEnd(Handle:evnt, const String:name[], bool:dontBroadcast)
{
    //Update the round "timer"
    round_counter--;
    
    //Delete end-of-map vote timers and start a vote if...
    //    ...an end-of-map vote hasn't already been completed AND
    //    ...end-of-map votes are enabled AND
    //    ...the required number of rounds has been reached AND
    //    ...there is a round limit in place.
    if (!vote_completed && vote_enabled && round_counter <= 0 && GetConVarInt(cvar_maxrounds) > 0)
    {
        DestroyTimers();
        StartMapVote();
    }
}


//Called when a round ends in tf2.
public Event_RoundEndTF2(Handle:evnt, const String:name[], bool:dontBroadcast)
{
    //Call round_end code if...
    //    ...a full round in TF2 has ended (as opposed to mini-rounds, such as in attack/defend maps).
    if (GetEventInt(evnt, "full_round") == 1)
        Event_RoundEnd(evnt, name, dontBroadcast);
}


//Called when intermission window is active. Necessary for mods without "game_end" event.
public Action:_VGuiMenu(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable,
                        bool:init)
{
    //Do nothing if we have already seen the intermission.
    if(intermission_called)
        return;

    new String:type[10];
    BfReadString(bf, type, sizeof(type));

    if(strcmp(type, "scores", false) == 0)
    {
        if(BfReadByte(bf) == 1 && BfReadByte(bf) == 0)
        {
            intermission_called = true;
            Event_GameEnd(INVALID_HANDLE, "", false);
        }
    }
}


//Called when the game ends. Used to trigger random selection of the next map.
public Event_GameEnd(Handle:evnt, const String:name[], bool:dontBroadcast)
{
    //Select and change to a random map if...
    //    ...the cvar to do so is enabled AND
    //    ...we haven't completed an end-of-map vote AND
    //    ...we haven't completed an RTV.
    if (GetConVarBool(cvar_randnext) && !vote_completed && !rtv_completed)
        RandomNextMap(randnext_mem_arr, randnext_catmem_arr, GetConVarBool(cvar_ignoregweight));
}


//Called at the end of a map. Basically disables the plugin before it is reset at the start of the
//next map.
public OnMapEnd()
{
    //Close handle to mapcycle.
    CloseHandle(map_kv);
    
    //Empty array of clients who have entered RTV.
    ClearArray(rtv_clients);
    
    //Empty array of nominations (and close all handles).
    ClearHandleArray(nominations_arr);
    
    //Restore limit cvars to their original values.
    RestoreCvars();
    
    //Update the current category.
    strcopy(current_cat, sizeof(current_cat), next_cat);
    
    //Reset array determining which message to display to clients who enter RTV.
    ResetArray(rtv_message, sizeof(rtv_message));
    
    //Set the intermission flag to No.
    intermission_called = false;
}


//************************************************************************************************//
//                                              SETUP                                             //
//************************************************************************************************//

//Parses the mapcycle file and returns a KV handle representing the mapcycle.
Handle:GetMapcycle()
{
    //Grab the file name from the cvar.
    decl String:filename[255];
    GetConVarString(cvar_filename, filename, sizeof(filename));
    
    //Get the kv handle from the file.
    new Handle:result = GetKvFromFile(filename, "umc_rotation");
    
    //Log an error and return empty handle if...
    //    ...the mapcycle file failed to parse.
    if (result == INVALID_HANDLE)
    {
        LogError("SETUP: Mapcycle failed to load!");
        return INVALID_HANDLE;
    }
    
    //Success!
    return result;
}


//Performs a reset of the plugin.
//Resets the vote timer and sets the next map.
FullReset()
{
    //No RTVs have been completed.
    rtv_completed = false;
    
    //No votes have been completed.
    vote_completed = false;
    
    //Votes are not enabled.
    vote_enabled = false;
    
    //No end-of-map vote timers are running.
    timer_alive = false;
    
    //No timer is setup so delay is undefined
    vote_delaystart = -1.0;
    
    //Set the amount of time required before players are able to RTV.
    rtv_delaystart = GetConVarFloat(cvar_rtv_delay);
    
    //Set the amount of remaining extensions allowed for the map.
    extend_counter = GetConVarInt(cvar_extensions);
    
    //No rounds have finished yet.
    round_counter = 0;
    
    //Set triggers for min and max number of players.
    SetupMinMaxPlayers();
    
    //Log some info.
    LogMessage("SETUP: %i map extensions remaining.", extend_counter);
    
    //Setup the initial runoff count
    remaining_runoffs = GetConVarInt(cvar_runoff);

    //Make end-of-map vote timers if...
    //    ...the end-of-map vote cvar is enabled AND
    //    ...the timer is not currently alive.
    if (GetConVarBool(cvar_endvote) && !timer_alive)
        MakeVoteTimer();

    //Setup RTV if...
    //    ...the RTV cvar is enabled.
    if (GetConVarBool(cvar_rtv_enable))
    {
        //Set RTV threshold.
        UpdateRTVThreshold(GetRealClientCount());
        
        //Make timer to activate RTV (player's cannot RTV before this timer finishes).
        MakeRTVTimer();
    }
}


//Sets up the vote sounds.
SetupVoteSounds()
{
    //Grab sound files from cvars.
    GetConVarString(cvar_vote_startsound, vote_start_sound, sizeof(vote_start_sound));
    GetConVarString(cvar_vote_endsound, vote_end_sound, sizeof(vote_end_sound));
    GetConVarString(cvar_rtv_startsound, rtv_start_sound, sizeof(rtv_start_sound));
    GetConVarString(cvar_rtv_endsound, rtv_end_sound, sizeof(rtv_end_sound));
    GetConVarString(cvar_runoff_sound, runoff_start_sound, sizeof(runoff_start_sound));
    
    //Gotta cache 'em all!
    CacheSound(vote_start_sound);
    CacheSound(vote_end_sound);
    CacheSound(rtv_start_sound);
    CacheSound(rtv_end_sound);
    CacheSound(runoff_start_sound);
}


//Sets up the vote warnings
SetupVoteWarnings()
{
    //Clear old warning adt_array
    ClearHandleArray(vote_warnings);
    
    //Initialize warning variables if...
    //    ...vote warnings are enabled.
    if (GetConVarBool(cvar_warnings))
    {
        //Make the new array.
        GetVoteWarnings(vote_warnings);
        
        //Set the starting point.
        UpdateVoteWarnings();
    }
}


//Sets the min and max player values for the current map.
SetupMinMaxPlayers()
{
    //Set defaults in the event we error out.
    map_min_players = 0;
    map_max_players = MaxClients;
    
    //Log some errors and exit function if...
    //    ...the mapcycle is invalid.
    if (map_kv == INVALID_HANDLE)
    {
        LogError("PLAYERLIMITS: Unable to set min and max players, rotation file is invalid."); 
        return;
    }
        
    //Fetch current map
    decl String:map[255];
    GetCurrentMap(map, sizeof(map));
    
    KvRewind(map_kv); //rewind the mapcycle handle
    new dmin, dmax; //variables to store default values for the category.
    
    //Set appropriate min and max player variables if...
    //    ...we can reach the current category in the mapcycle OR
    //    ...we can jump to the map somewhere in the mapcycle
    if (KvJumpToKey(map_kv, current_cat) ||
            (KvJumpToMap(map_kv, map) &&
             KvGoBack(map_kv) &&
             KvGetSectionName(map_kv, current_cat, sizeof(current_cat))))
    {
        //Store defaults for the category
        dmin = KvGetNum(map_kv, "default_min_players", 0);
        dmax = KvGetNum(map_kv, "default_max_players", MaxClients);
        
        //Set the map's min and max player variables if...
        //    ...we can reach the current map in the mapcycle.
        if (KvJumpToKey(map_kv, map))
        {
            //Log success message.
            LogMessage("SETUP: Current Map Group is '%s.'", current_cat);
            
            //Set variables for min and max players, using the category defaults if they are not
            //available.
            map_min_players = KvGetNum(map_kv, "min_players", dmin);
            map_max_players = KvGetNum(map_kv, "max_players", dmax);
            
            //Log Info
            LogMessage("PLAYERLIMITS: Min Players: %i, Max Players: %i", map_min_players, map_max_players);
    
            //Make timer to do min/max player check.
            MakePlayerLimitCheckTimer();
            return;
        }
    }
    
    //Error, was not able to find the appropriate data.
    LogMessage("SETUP: Current Map Group could not be determined. (Non-UMC mapchange or plugin just loaded.)");
    
    //Use defaults.
    map_min_players = 0;
    map_max_players = MaxClients;
    
    //Log Info
    LogMessage("PLAYERLIMITS: Min Players: %i, Max Players: %i", map_min_players, map_max_players);
    
    //Make timer to do min/max player check.
    MakePlayerLimitCheckTimer();
}


//Sets up timers for an end-of-map vote.
MakeVoteTimer()
{
    //A vote has not been completed if we're making a new timer.
    vote_completed = false;
    
    //The end-of-map vote is now enabled.
    vote_enabled = true;
    
    //Make the end-of-map vote timer.
    vote_timer = MakeTimer();
    
    //The timer is alive if the new timer was made successfully.
    timer_alive = vote_timer != INVALID_HANDLE;
    
    //Calculate the number of rounds required before the vote is triggered.
    round_counter += GetConVarInt(cvar_maxrounds) - GetConVarInt(cvar_start_rounds);
    
    //Log
    if (round_counter > 0)
        LogMessage("SETUP: End of map vote will appear after %i rounds.", round_counter);
}


//************************************************************************************************//
//                                          CVAR CHANGES                                          //
//************************************************************************************************//

//Called when the cvar for the maximum number of rounds has been changed. Used for end-of-map vote
//based on rounds.
public Handle_MaxroundsChange(Handle:convar, const String:oldVal[], const String:newVal[])
{
    //Update the "timer" for rounds.
    round_counter += StringToInt(newVal) - StringToInt(oldVal);
    
    //Store the new value to change the cvar to when the map ends if...
    //    ...the flag to bypass this action is set to False.
    if (!catch_change)
        maxrounds_mem = StringToInt(newVal);
}


//Called when the cvar for the maximum number of frags has been changed. Used for end-of-map vote
//based on frags.
public Handle_FraglimitChange(Handle:convar, const String:oldVal[], const String:newVal[])
{
    //Store the new value to change the cvar to when the map ends if...
    //    ...the flag to bypass this action is set to False.
    if (!catch_change)
        fraglimit_mem = StringToInt(newVal);
}


//Reset all modified cvars to the stored values.
RestoreCvars()
{
    SetConVarInt(cvar_maxrounds, maxrounds_mem);
    SetConVarInt(cvar_fraglimit, fraglimit_mem);
}


//Called when the cvar for max number of runoffs to run changes.
public Handle_RunoffChange(Handle:convar, const String:oldVal[], const String:newVal[])
{
    remaining_runoffs = StringToInt(newVal);
}


//Called when the cvar to enable RTVs has been changed.
public Handle_RTVChange(Handle:convar, const String:oldVal[], const String:newVal[])
{
    //If the new value is 0, we ignore the change until next map.
    
    //Update (in this case set) the RTV threshold if...
    //    ...the new value of the changed cvar is 1.
    if (StringToInt(newVal) == 1)
        UpdateRTVThreshold(GetRealClientCount());
}


//Called when the cvar specifying the required RTV threshold percentage has changed.
public Handle_ThresholdChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
    //Recalculate the required threshold.
    UpdateRTVThreshold(GetRealClientCount());
    
    //Start an RTV if...
    //    ...the amount of clients who have RTVd is greater than the new RTV threshold.
    if (GetArraySize(rtv_clients) >= rtv_threshold)
        StartRTV();
}


//Called when the number of excluded previous maps from random selection of the next map has
//changed.
public Handle_RandNextMemoryChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
    //Trim the memory array for random selection of the next map.
        //We pass 1 extra to the argument in order to account for the current map, which should 
        //always be excluded.
    TrimArray(randnext_mem_arr, StringToInt(newValue) + 1);
}


//Called when the number of excluded previous maps from end-of-map votes has changed.
public Handle_VoteMemoryChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
    //Trim the memory array for end-of-map votes.
        //We pass 1 extra to the argument in order to account for the current map, which should 
        //always be excluded.
    TrimArray(vote_mem_arr, StringToInt(newValue) + 1);
}


//Called when the number of excluded previous maps from RTVs has changed.
public Handle_RTVMemoryChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
    //Trim the memory array for RTVs.
        //We pass 1 extra to the argument in order to account for the current map, which should 
        //always be excluded.
    TrimArray(rtv_mem_arr, StringToInt(newValue) + 1);
}


//Called when the cvar which enabled end-of-map votes has changed.
public Handle_VoteChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
    //Regardless of the change, destroy all existing end-of-map vote timers.
    DestroyTimers();
    
    //Make new timers if...
    //    ...the new value of the cvar is 1.
    if (StringToInt(newValue) == 1)
        MakeVoteTimer();
}


//Called when the cvar which specifies the time trigger for the end-of-round vote is changed.
public Handle_TriggerChange(Handle:convar, const String:oldVal[], const String:newVal[])
{
    //Update all necessary timers.
    UpdateTimers();
}


//************************************************************************************************//
//                                            COMMANDS                                            //
//************************************************************************************************//

//Called when the command to reload the mapcycle has been triggered.
public Action:Command_Reload(client, args)
{
    //Delete our old cycle.
    CloseHandle(map_kv);
    
    //Fetch the new cycle.
    map_kv = GetMapcycle();
    
    //Log a success message if...
    //    ...the reload completed successfully.
    if (map_kv != INVALID_HANDLE)
        LogMessage("SETUP: UMC Rotation file successfully reloaded.");
    
    //Return success
    return Plugin_Handled;
}


//Called when the command to start a map vote is called
public Action:Command_Vote(client, args)
{
    //Delete all existing timers.
    DestroyTimers();
    
    //Start a vote.
    StartMapVote();
    
    //Return success.
    return Plugin_Handled;
}


//Called when the command to pick a random nextmap (sm_dynamic_repick_nextmap) is called
public Action:Command_Random(client, args)
{
    //Pick a random map, using the memory queue for random selection of the next map as the
    //exclusion array.
    RandomNextMap(randnext_mem_arr, randnext_catmem_arr, GetConVarBool(cvar_ignoregweight));
    
    //Return success.
    return Plugin_Handled;
}


//************************************************************************************************//
//                                         END OF MAP VOTE                                        //
//************************************************************************************************//

//Makes the timer which will activate the end-of-map vote at a certain time.
Handle:MakeTimer()
{
    //Get current timeleft.
    new timeleft, triggertime, starttime;
    GetMapTimeLeft(timeleft);
    starttime = RoundToNearest(GetConVarFloat(cvar_start_time) * 60);
    
    //Duration until the vote starts.
    triggertime = timeleft - starttime;
    
    //Make the timer if...
    //    ...the time to start the vote hasn't already passed.
    if (timeleft >= 0 && starttime > 0 && triggertime > 0)
    {
        //Setup counter until the end-of-map vote triggers.
        vote_delaystart = float(timeleft - RoundToNearest(GetConVarFloat(cvar_start_time) * 60));
    
        //Update Vote Warnings if...
        //    ...vote warnings are enabled.
        if (GetConVarBool(cvar_warnings))
            UpdateVoteWarnings();
        
        //Log message
        LogMessage("MAPVOTE: End of map vote will appear after %.f seconds", vote_delaystart);
        
        //Make the timer
        return CreateTimer(
            1.0, //float(timeleft - RoundToNearest(GetConVarFloat(cvar_start_time) * 60)),
            Handle_MapVoteTimer,
            INVALID_HANDLE,
            TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT
        );
    }
    else //Otherwise...
    {
        //Never trigger the vote.
        vote_delaystart = -1.0;
        
        //Log message
        LogMessage("MAPVOTE: Unable to create end of map vote timer, trigger time already passed.");
        
        //We couldn't make the timer, so return nothing.
        return INVALID_HANDLE;
    }
}


//Update the end-of-map vote timer.
UpdateTimers()
{
    //Reset the timer if...
    //    ...we haven't already completed a vote.
    //    ...the cvar to run an end-of-round vote is enabled.
    if (!vote_completed && GetConVarBool(cvar_endvote))
    {
        //Delete the timer if...
        //    ...the timer is currently alive.
        if (timer_alive)
            KillTimer(vote_timer);
        
        //Make a new timer.
        vote_timer = MakeTimer();
        
        //The timer is alive if the new timer was made successfully.
        timer_alive = vote_timer != INVALID_HANDLE;
        
        if (timer_alive)
            LogMessage("MAPVOTE: Map vote timer successfully updated.");
    }
}


//Disables all end-of-map vote timers.
DestroyTimers()
{
    LogMessage("MAPVOTE: End of map vote timer stopped.");

    //Delete the time trigger if...
    //    ...the timer is alive.
    if (timer_alive)
    {
        KillTimer(vote_timer);
        timer_alive = false;
    }
    
    //Set flag for voting to disabled.
    vote_enabled = false;
}


//Called when the end-of-vote timer (vote_timer) is finished.
public Action:Handle_MapVoteTimer(Handle:timer)
{
    //Handle vote warnings if...
    //    ...vote warnings are enabled.
    if (GetConVarBool(cvar_warnings))
        DoVoteWarning();

    //Continue ticking if...
    //    ...there is still time left on the counter.
    if (FloatCompare(vote_delaystart, 0.0) > 0)
    {
        //Tick another second off the timer counter.
        vote_delaystart--;
        return Plugin_Continue;
    }
    
    //If there isn't time left on the timer...
    
    //Start the end-of-map vote.
    StartMapVote();
    
    //The timer is no longer alive.
    timer_alive = false;
    vote_delaystart = -1.0;
    
    return Plugin_Stop;
}


//Initiates the map vote.
StartMapVote()
{
    //Log a message
    LogMessage("MAPVOTE: Starting an end of map vote.");
    
    //Log an error and do nothing if...
    //    ...another vote is currently running for some reason.
    if (IsVoteInProgress()) 
    {
        LogMessage("MAPVOTE: There is a vote already in progress, cannot start a new vote.");
        return;
    }
    
    //Make the vote menu.
    new Handle:menu = BuildVoteMenu();
    
    //Run the vote if...
    //    ...the menu was created successfully.
    if (menu != INVALID_HANDLE)
    {
        //Play the vote start sound if...
        //  ...the filename is defined.
        if (strlen(vote_start_sound) > 0)
            EmitSoundToAll(vote_start_sound);
    
        //Log an error if...
        //    ...the vote cannot start for some reason.
        if (!VoteMenuToAll(menu, GetConVarInt(cvar_vote_time)))
            LogMessage("MAPVOTE: Menu already has a vote in progress, cannot start a new vote.");
    }
}


//Builds and returns the end-of-map vote menu.
Handle:BuildVoteMenu()
{
    //Do different things depending on the type of vote.
    switch (GetConVarInt(cvar_vote_type))
    {
        case VOTE_TYPE_MAP: //If the vote is a Map Vote...
            return BuildMapVoteMenu(Handle_MapVoteResults, GetConVarBool(cvar_scramble),
                                    extend_counter > 0, false, vote_mem_arr, vote_catmem_arr);
        case VOTE_TYPE_CAT: //If the vote is a Category Vote...
            return BuildCatVoteMenu(Handle_CatVoteResults, GetConVarBool(cvar_scramble),
                                    extend_counter > 0, false, vote_mem_arr, vote_catmem_arr);
        case VOTE_TYPE_TIER: //If the vote is a Tiered Vote...
            return BuildCatVoteMenu(Handle_TierVoteResults, GetConVarBool(cvar_scramble),
                                    extend_counter > 0, false, vote_mem_arr, vote_catmem_arr);
    }
    
    //If the cvar is anything else, return invalid handle.
    //Necessary line of code to prevent compiler warning.
    return INVALID_HANDLE;
}


//Handles the results of a end-of-map map vote.
public Handle_MapVoteResults(Handle:menu, num_votes, num_clients, const client_info[][2], num_items,
                             const item_info[][2])
{
    //Get the winning map.
    new winner = GetWinner(num_items, item_info);
    decl String:map[255];
    GetMenuItem(menu, item_info[winner][VOTEINFO_ITEM_INDEX], map, sizeof(map));
    
    //Play the vote completed sound if...
    //  ...the vote completed sound is defined.
    if (strlen(vote_end_sound) > 0)
        EmitSoundToAll(vote_end_sound);
        
    //Calc winner percentage
    new Float:winPercent = float(item_info[winner][VOTEINFO_ITEM_VOTES]) / float(num_votes) * 100;
    
    //Perform a runoff vote if...
    //  ...we can still do one AND
    //  ...the win percent is less than the required threshold
    if (remaining_runoffs > 0 && winPercent < GetConVarFloat(cvar_runoff_threshold) * 100)
    {
        //No more voting. We don't want an rtv occuring during the delay.
        vote_enabled = false;
        
        //Do the runoff.
        DoRunoffVote(menu, num_votes, num_clients, client_info, num_items, item_info,
                     Handle_MapVoteResults, vote_start_sound);
        return;
    }
    
    //Print a message and extend the current map if...
    //    ...the server voted to extend the map.
    if (StrEqual(map, "?Extend?"))
    {
        /*PrintToChatAll(
            "[UMC] Map voting has finished. The current map will be extended. (Received %.f%% of %i votes)",
            float(item_info[winner][VOTEINFO_ITEM_VOTES]) / float(num_votes) * 100,
            num_votes
        );*/
        PrintToChatAll(
            "[UMC] %t %t (%t)",
            "End of Map Vote Over",
            "Map Extended",
            "Vote Win Percentage",
                float(item_info[winner][VOTEINFO_ITEM_VOTES]) / float(num_votes) * 100,
                num_votes
        );
        LogMessage("MAPVOTE: Players voted to extend the map.");
        ExtendMap();
    }
    else //Otherwise, we print a message and then set the new map.
    {
        /*PrintToChatAll(
            "[UMC] Map voting has finished. The next map will be %s. (Received %.f%% of %i votes)",
            map,
            float(item_info[winner][VOTEINFO_ITEM_VOTES]) / float(num_votes) * 100,
            num_votes
        );*/
        PrintToChatAll(
            "[UMC] %t %t (%t)",
            "End of Map Vote Over",
            "End of Map Vote Map Won",
                map,
            "Vote Win Percentage",
                float(item_info[winner][VOTEINFO_ITEM_VOTES]) / float(num_votes) * 100,
                num_votes
        );
        
        //Find the index of the winning map in the stored vote array.
        new index = FindStringInArray(map_vote, map);
        
        //Fetch relevant data--using the previously found index--from other arrays.
        GetArrayString(map_vote_next_cats, index, next_rand_cat, sizeof(next_rand_cat));
        GetArrayString(map_vote_cats, index, next_cat, sizeof(next_cat));
        GetArrayString(map_vote_cat_configs, index, cat_config, sizeof(cat_config));
        GetArrayString(map_vote_map_configs, index, map_config, sizeof(map_config));
        
        //Set it.
        SetTheNextMap(map);
        
        LogMessage("MAPVOTE: Players voted for map '%s' from group '%s.'", map, next_cat);
        
        //We have officially completed an end-of-map vote.
        vote_completed = true;
    }
}


//Handles the results of an end-of-map category vote.
public Handle_CatVoteResults(Handle:menu, num_votes, num_clients, const client_info[][2], num_items,
                             const item_info[][2])
{
    //Play the vote completed sound if...
    //  ...the vote completed sound is defined.
    if (strlen(vote_end_sound) > 0)
        EmitSoundToAll(vote_end_sound);

    //Get the winning category.
    new winner = GetWinner(num_items, item_info);
    decl String:map[255];
    decl String:cat[255];
    GetMenuItem(menu, item_info[winner][VOTEINFO_ITEM_INDEX], cat, sizeof(cat));
    
    //Calc winner percentage
    new Float:winPercent = float(item_info[winner][VOTEINFO_ITEM_VOTES]) / float(num_votes) * 100;
    
    //Perform a runoff vote if...
    //  ...we can still do one and the win percent is less than the required threshold
    if (remaining_runoffs > 0 && winPercent < GetConVarFloat(cvar_runoff_threshold) * 100)
    {
        //No more voting. We don't want an rtv occuring during the delay.
        vote_enabled = false;
        
        //Do the runoff.
        DoRunoffVote(menu, num_votes, num_clients, client_info, num_items, item_info,
                     Handle_CatVoteResults, vote_start_sound);
        return;
    }
    
    //Print a message and extend the map if...
    //    ...the server voted to extend the map.
    if (StrEqual(cat, "?Extend?"))
    {
        /*PrintToChatAll(
            "[UMC] Map voting has finished. The current map will be extended. (Received %.f%% of %i votes)",
            float(item_info[winner][VOTEINFO_ITEM_VOTES]) / float(num_votes) * 100,
            num_votes
        );*/
        PrintToChatAll(
            "[UMC] %t %t (%t)",
            "End of Map Vote Over",
            "Map Extended",
            "Vote Win Percentage",
                float(item_info[winner][VOTEINFO_ITEM_VOTES]) / float(num_votes) * 100,
                num_votes
        );
        LogMessage("MAPVOTE: Players voted to extend the map.");
        ExtendMap();
    }
    else //Otherwise, we pick a random map from the category and set that as the next map.
    {
        //Set the next_cat to the winning category (the category of the next map will be from this
        //category obviously).
        strcopy(next_cat, sizeof(next_cat), cat);
        
        //Number of nominated maps for the winning category.
        new counter = 0;
        
        //An adt_array of nominations from the given category.
        new Handle:nominationsFromCat = FilterNominations("cat", cat);
        
        //if...
        //    ...there are nominations for this category.
        if (GetArraySize(nominationsFromCat) > 0)
        {
            //Array of nominated map names.
            new Handle:nameArr = CreateArray(255);
            
            //Array of nominated map weights (linked to the previous by index).
            new Handle:weightArr = CreateArray();
            
            //Buffer to store the map name
            decl String:nameBuffer[255];
            
            //Variable to store the map weight.
            new weight;
            
            //A nomination.
            new Handle:trie = INVALID_HANDLE;
            
            //Rewind the mapcycle.
            KvRewind(map_kv);
            
            //Jump to the category in the mapcycle.
            KvJumpToKey(map_kv, cat);
            
            //Set up the cat config
            KvGetString(map_kv, "command", cat_config, sizeof(cat_config));
            
            //Add nomination to name and weight array for...
            //    ...each nomination in the nomination array for this category.
            new arraySize = GetArraySize(nominationsFromCat);
            for (new i = 0; i < arraySize; i++)
            {
                //Get the nomination at the current index.
                trie = GetArrayCell(nominationsFromCat, i);
                
                //Get the map name from the nomination.
                GetTrieString(trie, "map", nameBuffer, sizeof(nameBuffer));    
                
                //Add the map to the storage arrays if...
                //    ...the server has the required amount of players for the map.
                if (IsValidMapFromCat(map_kv, nameBuffer))
                {
                    //Increment the nomination counter.
                    counter++;
                    
                    //Add the map to the map name array.
                    PushArrayString(nameArr, nameBuffer);
                    
                    //Add the map's weight to the map weight array.
                    GetTrieValue(trie, "weight", weight);
                    PushArrayCell(weightArr, weight);
                }
            }
            
            //Pick a random map from the nominations if...
            //    ...there are nominations to choose from.
            if (counter > 0)
            {
                GetWeightedRandomSubKey(map, sizeof(map), weightArr, nameArr);
                
                //Get additional data from the map
                KvRewind(map_kv);
                KvJumpToKey(map_kv, cat);
                KvGetString(map_kv, "next_mapgroup", next_rand_cat, sizeof(next_rand_cat));
                KvJumpToKey(map_kv, map);
                KvGetString(map_kv, "command", map_config, sizeof(map_config));
                KvGoBack(map_kv);

                SetTheNextMap(map);
            }
            else //Otherwise, we select a map randomly from the category.
            {
                //Set the current category as the category to be selected randomly from.
                //This is necessary for RandomNextMaps algorithm to select specifically from the
                //winning category.
                strcopy(next_rand_cat, sizeof(next_rand_cat), cat);
                
                //Pick and set the next map.
                RandomNextMap(vote_mem_arr, vote_catmem_arr);
                
                //Fetch the new next map and store it for the message we're going to display.
                GetNextMap(map, sizeof(map));
            }
            
            //Close the handles for the storage arrays.
            CloseHandle(nameArr);
            CloseHandle(weightArr);
        }
        else //Otherwise, there are no nominations to worry about so we just pick a map randomly
             //from the winning category.
        {
            //Set the current category as the category to be selected randomly from.
            //This is necessary for RandomNextMaps algorithm to select specifically from the
            //winning category.
            strcopy(next_rand_cat, sizeof(next_rand_cat), cat);
            
            //Pick and set the next map.
            RandomNextMap(vote_mem_arr, vote_catmem_arr);
            
            //Fetch the new next map and store it for the message we're going to display.
            GetNextMap(map, sizeof(map));
        }
        
        //We no longer need the adt_array to store nominations.
        CloseHandle(nominationsFromCat);
        
        PrintToChatAll(
            "[UMC] %t %t (%t)",
            "End of Map Vote Over",
            "End of Map Vote Group Won",
                map, cat,
            "Vote Win Percentage",
                float(item_info[winner][VOTEINFO_ITEM_VOTES]) / float(num_votes) * 100,
                num_votes
        );
        LogMessage("MAPVOTE: Players voted for map group '%s.'", cat);
            
        //We have officially completed an end-of-map vote.
        vote_completed = true;
    }
}


//Handles the results of an end-of-map tiered vote.
public Handle_TierVoteResults(Handle:menu, num_votes, num_clients, const client_info[][2],
                              num_items, const item_info[][2])
{        
    //Play the vote completed sound if...
    //  ...the vote completed sound is defined.
    if (strlen(vote_end_sound) > 0)
        EmitSoundToAll(vote_end_sound);

    //Get the winning category.
    new winner = GetWinner(num_items, item_info);
    decl String:cat[255];
    GetMenuItem(menu, item_info[winner][VOTEINFO_ITEM_INDEX], cat, sizeof(cat));
    
    //Calc winner percentage
    new Float:winPercent = float(item_info[winner][VOTEINFO_ITEM_VOTES]) / float(num_votes) * 100;
    
    //Perform a runoff vote if...
    //  ...we can still do one and the win percent is less than the required threshold
    if (remaining_runoffs > 0 && winPercent < GetConVarFloat(cvar_runoff_threshold) * 100)
    {
        //No more voting. We don't want an rtv occuring during the delay.
        vote_enabled = false;
        
        //Do the runoff.
        DoRunoffVote(menu, num_votes, num_clients, client_info, num_items, item_info,
                     Handle_TierVoteResults, vote_start_sound);
        return;
    }
    
    //Print a message and extend the map if...
    //    ...the server voted to extend the map.
    if (StrEqual(cat, "?Extend?"))
    {
        /*PrintToChatAll(
            "[UMC] Map voting has finished. The current map will be extended. (Received %.f%% of %i votes)",
            float(item_info[winner][VOTEINFO_ITEM_VOTES]) / float(num_votes) * 100,
            num_votes
        );*/
        PrintToChatAll(
            "[UMC] %t %t (%t)",
            "End of Map Vote Over",
            "Map Extended",
            "Vote Win Percentage",
                float(item_info[winner][VOTEINFO_ITEM_VOTES]) / float(num_votes) * 100,
                num_votes
        );
        LogMessage("MAPVOTE: Players voted to extend the map.");
        ExtendMap();
    }
    else //Otherwise, we set up the second stage of the tiered vote
    {
        LogMessage("MAPVOTE (Tiered): Players voted for map group '%s.'", cat);
    
        KvRewind(map_kv);
        KvJumpToKey(map_kv, cat);
        if (CountValidMapsFromCat(map_kv, vote_mem_arr) == 1)
        {
            Handle_CatVoteResults(menu, num_votes, num_clients, client_info, num_items, item_info);
            KvGoBack(map_kv);
            return;
        }
        KvGoBack(map_kv);
    
        //Setup timer to delay the next vote for a few seconds.
        tiered_delay = 4;
        
        //Display the first message
        DisplayTierMessage(5);
        
        //Setup timer to delay the next vote for a few seconds.
        CreateTimer(
            1.0,
            Handle_TieredVoteTimer,
            MakeSecondTieredCatExclusion(cat),
            TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT | TIMER_DATA_HNDL_CLOSE
        );
    }
}


//Called when the timer for the tiered end-of-map vote triggers.
public Action:Handle_TieredVoteTimer(Handle:timer, Handle:excludedCats)
{
    if (tiered_delay > 0)
    {
        DisplayTierMessage(tiered_delay);
        tiered_delay--;
        return Plugin_Continue;
    }
        
    if (IsVoteInProgress())
    {
        LogMessage("MAPVOTE (Tiered): There is a vote already in progress, cannot start a new vote.");
        return Plugin_Stop;
    }
    
    //Log a message
    LogMessage("MAPVOTE (Tiered): Starting second stage of tiered vote.");
        
    //Initialize the menu.
    new Handle:menu = BuildMapVoteMenu(Handle_MapVoteResults, GetConVarBool(cvar_scramble),
                                       false, false, vote_mem_arr, excludedCats, true);
    
    if (menu != INVALID_HANDLE)
    {
        //Play the vote start sound if...
        //  ...the vote start sound is defined.
        if (strlen(vote_start_sound) > 0)
            EmitSoundToAll(vote_start_sound);
        
        //Display the menu.
        if (!VoteMenuToAll(menu, GetConVarInt(cvar_vote_time)))
            LogMessage("MAPVOTE (Tiered): Menu already has a vote in progress, cannot start a new vote.");
    }
    else
        LogError("MAPVOTE (Tiered): Unable to create second stage vote menu. Vote aborted.");
        
    return Plugin_Stop;
}


//Extend the current map.
ExtendMap()
{
    //We do not want to keep track of the following changes to the limit cvars.
    catch_change = true;
    
    //Set new limit cvar values if they are enabled to begin with (> 0).
    if (GetConVarInt(cvar_maxrounds) > 0)
        SetConVarInt(cvar_maxrounds, GetConVarInt(cvar_maxrounds) + GetConVarInt(cvar_extend_rounds));
    if (GetConVarInt(cvar_fraglimit) > 0)
        SetConVarInt(cvar_fraglimit, GetConVarInt(cvar_fraglimit) + GetConVarInt(cvar_extend_frags));
    
    //Now we can keep track of changes again.
    catch_change = false;
    
    //Extend the time limit.
    ExtendMapTimeLimit(RoundToNearest(GetConVarFloat(cvar_extend_time) * 60));
    
    //Make a new vote timer.
    MakeVoteTimer();
    
    //Reduce the extend counter since we have just used an extension.
    extend_counter--;
    
    //Log some stuff.
    LogMessage("MAPVOTE: Map extended. %i extensions remaining.", extend_counter);
}


//************************************************************************************************//
//                                          ROCK THE VOTE                                         //
//************************************************************************************************//

//Creates the RTV timer. While this timer is active, players are not able to RTV.
MakeRTVTimer()
{
    //RTV is currently not enabled.
    rtv_enabled = false;
    
    //Log a message
    LogMessage("RTV: RTV will be made available in %.f seconds.", rtv_delaystart);
    
    //Create timer that lasts every second.
    CreateTimer(
        1.0,
        Handle_RTVTimer,
        INVALID_HANDLE,
        TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT
    );
}


//Callback for the RTV timer, is called every second the timer is running.
public Action:Handle_RTVTimer(Handle:timer)
{
    //Tick another second off of the counter.
    rtv_delaystart--;
    
    //Continue ticking if...
    //    ...there is still time left on the counter.
    if (FloatCompare(rtv_delaystart, 0.0) > 0)
        return Plugin_Continue;

    //If there isn't time left on the counter...
    
    //RTV is now enabled.
    rtv_enabled = true;
    
    LogMessage("RTV: RTV is now available.");
    
    //Stop the timer.
    return Plugin_Stop;
}


//Recalculated the RTV threshold based off of the given playercount.
UpdateRTVThreshold(count)
{
    if (count > 1)
        rtv_threshold = RoundToNearest(float(count) * GetConVarFloat(cvar_rtv_needed));
    else
        rtv_threshold = 1;
}


//Starts an RTV.
StartRTV()
{
    LogMessage("RTV: Starting RTV.");
    
    //Change the map immediately if...
    //    ...there has already been an end-of-map vote AND
    //    ...the cvar that handles RTV actions after end-of-map votes specifies to change the map.
    if (vote_completed && GetConVarInt(cvar_rtv_postaction) == 0)
    {
        //Get the next map set by the vote.
        decl String:temp[255];
        GetNextMap(temp, sizeof(temp));
        
        LogMessage("RTV: End of map vote has already been completed, changing map.");
        
        //Change to it.
        ForceChangeInFive(temp, "RTV");
    }
    //Otherwise, build the RTV vote if...
    //    ...a vote hasn't already been completed.
    else if (!vote_completed)
    {
        //Do nothing if...
        //    ...there is a vote already in progress.
        if (IsVoteInProgress()) 
        {
            LogMessage("RTV: There is a vote already in progress, cannot start a new vote.");
            return;
        }
        
        //Build the RTV menu.
        new Handle:menu = BuildRTVMenu();
        
        //Display the vote menu if...
        //    ...the menu was created successfully.
        if (menu != INVALID_HANDLE)
        {
            //Play the vote start sound if...
            //  ...the filename is defined.
            if (strlen(rtv_start_sound) > 0)
                EmitSoundToAll(rtv_start_sound);
        
            //Log a message if...
            //    ...the menu couldn't be displayed.
            if (!VoteMenuToAll(menu, GetConVarInt(cvar_vote_time)))
                LogMessage("RTV: Menu already has a vote in progress, cannot start a new vote.");
        }
        else
            LogError("RTV: Unable to create RTV menu, voting aborted.");
    }
    
    //Clear the array of clients who have entered RTV.
    ClearArray(rtv_clients);
}


//Builds and returns the RTV vote menu.
Handle:BuildRTVMenu()
{
    //Do different things depending on the type of vote.
    switch (GetConVarInt(cvar_rtv_type))
    {
        case VOTE_TYPE_MAP: //If the vote is a Map Vote...
            return BuildMapVoteMenu(Handle_MapRTVResults, GetConVarBool(cvar_scramble), false,
                                    GetConVarBool(cvar_rtv_dontchange), rtv_mem_arr, rtv_catmem_arr);
        case VOTE_TYPE_CAT: //If the vote is a Category Vote...
            return BuildCatVoteMenu(Handle_CatRTVResults, GetConVarBool(cvar_scramble), false,
                                    GetConVarBool(cvar_rtv_dontchange), rtv_mem_arr, rtv_catmem_arr);
        case VOTE_TYPE_TIER: //If the vote is a Tiered Vote...
            return BuildCatVoteMenu(Handle_TierRTVResults, GetConVarBool(cvar_scramble), false,
                                    GetConVarBool(cvar_rtv_dontchange), rtv_mem_arr, rtv_catmem_arr);
    }
    
    //If the cvar is anything else, return invalid handle.
    //Necessary line of code to prevent compiler warning.
    return INVALID_HANDLE;
}


//Handles the results of an RTV map vote.
public Handle_MapRTVResults(Handle:menu, num_votes, num_clients, const client_info[][2], num_items,
                            const item_info[][2])
{
    //Get the winning map.
    new winner = GetWinner(num_items, item_info);
    decl String:map[255];
    GetMenuItem(menu, item_info[winner][VOTEINFO_ITEM_INDEX], map, sizeof(map));
    
    //Play the vote completed sound if...
    //  ...the vote completed sound is defined.
    if (strlen(rtv_end_sound) > 0)
        EmitSoundToAll(rtv_end_sound);
        
    //RUNOFF HERE
    new Float:winPercent = float(item_info[winner][VOTEINFO_ITEM_VOTES]) / float(num_votes) * 100;
    if (remaining_runoffs > 0 && winPercent < GetConVarFloat(cvar_runoff_threshold) * 100)
    {
        rtv_enabled = false;
        DoRunoffVote(menu, num_votes, num_clients, client_info, num_items, item_info,
                     Handle_MapRTVResults, rtv_start_sound);
        return;
    }
    
    //Print a message and reset the RTV timer if...
    //    ...the server voted to not change the map.
    if (StrEqual(map, "?DontChange?"))
    {
        /*PrintToChatAll(
            "[UMC] Map voting has finished. The map will not be changed. (Received %.f%% of %i votes)",
            float(item_info[winner][VOTEINFO_ITEM_VOTES]) / float(num_votes) * 100,
            num_votes
        );*/
        PrintToChatAll(
            "[UMC] %t %t (%t)",
            "End of Map Vote Over",
            "Map Unchanged",
            "Vote Win Percentage",
                float(item_info[winner][VOTEINFO_ITEM_VOTES]) / float(num_votes) * 100,
                num_votes
        );
        
        LogMessage("RTV: Players voted to stay on the map (Don't Change).");
        
        //Reset the RTV timer.
        rtv_delaystart = GetConVarFloat(cvar_rtv_interval);
        MakeRTVTimer();
    }
    else //Otherwise, we print a message and then set the new map.
    {
        /*PrintToChatAll(
            "[UMC] Map voting has finished. Changing map to %s. (Received %.f%% of %i votes)",
            map,
            float(item_info[winner][VOTEINFO_ITEM_VOTES]) / float(num_votes) * 100,
            num_votes
        );*/
        PrintToChatAll(
            "[UMC] %t %t (%t)",
            "End of Map Vote Over",
            "RTV Map Won",
                map,
            "Vote Win Percentage",
                float(item_info[winner][VOTEINFO_ITEM_VOTES]) / float(num_votes) * 100,
                num_votes
        );
        
        //Find the index of the winning map in the stored vote array.
        new index = FindStringInArray(map_vote, map);
        
        //Fetch relevant data from other map arrays.
        GetArrayString(map_vote_next_cats, index, next_rand_cat, sizeof(next_rand_cat));
        GetArrayString(map_vote_cats, index, next_cat, sizeof(next_cat));
        GetArrayString(map_vote_cat_configs, index, cat_config, sizeof(cat_config));
        GetArrayString(map_vote_map_configs, index, map_config, sizeof(map_config));
        
        LogMessage("RTV: Players voted for map '%s' from group '%s.'", map, next_cat);
        
        //Set it.
        ChangeMapRTV(map);
    }
}


//Handles the results of an RTV category vote.
public Handle_CatRTVResults(Handle:menu, num_votes, num_clients,
                            const client_info[][2], num_items, const item_info[][2])
{
    //Play the vote completed sound if...
    //  ...the vote completed sound is defined.
    if (strlen(rtv_end_sound) > 0)
        EmitSoundToAll(rtv_end_sound);

    //Get the winning category.
    new winner = GetWinner(num_items, item_info);
    decl String:map[255];
    decl String:cat[255];
    GetMenuItem(menu, item_info[winner][VOTEINFO_ITEM_INDEX], cat, sizeof(cat));
    
    //RUNOFF HERE
    new Float:winPercent = float(item_info[winner][VOTEINFO_ITEM_VOTES]) / float(num_votes) * 100;
    if (remaining_runoffs > 0 && winPercent < GetConVarFloat(cvar_runoff_threshold) * 100)
    {
        rtv_enabled = false;
        DoRunoffVote(menu, num_votes, num_clients, client_info, num_items, item_info,
                     Handle_CatRTVResults, vote_start_sound);
        return;
    }
    
    //Print a message and reset the RTV timer if...
    //    ...the server voted to not change the map.
    if (StrEqual(cat, "?DontChange?"))
    {
        /*PrintToChatAll(
            "[UMC] Map voting has finished. The map will not be changed. (Received %.f%% of %i votes)",
            float(item_info[winner][VOTEINFO_ITEM_VOTES]) / float(num_votes) * 100,
            num_votes
        );*/
        PrintToChatAll(
            "[UMC] %t %t (%t)",
            "End of Map Vote Over",
            "Map Unchanged",
            "Vote Win Percentage",
                float(item_info[winner][VOTEINFO_ITEM_VOTES]) / float(num_votes) * 100,
                num_votes
        );
        LogMessage("RTV: Players voted to stay on the map (Don't Change).");
        
        //Reset all clients who have entered RTV (they will have to re-enter in the future).
        //ClearArray(rtv_clients);
        
        //Reset the RTV timer.
        rtv_delaystart = GetConVarFloat(cvar_rtv_interval);
        MakeRTVTimer();
    }
    else //Otherwise, we pick a random map from the category and change to it.
    {
        //Set the next_cat to the winning category (the category of the next map will be from this
        //category obviously).
        strcopy(next_cat, sizeof(next_cat), cat);
        
        //Number of nominated maps for the winning category.
        new counter = 0;
        
        //An adt_array of nominations from the given category.
        new Handle:nominationsFromCat = FilterNominations("cat", cat);
        
        //if...
        //    ...there are nominations for this category.
        if (GetArraySize(nominationsFromCat) > 0)
        {
            //Array of nominated map names.
            new Handle:nameArr = CreateArray(255);
            
            //Array of nominated map weights (linked to the previous by index).
            new Handle:weightArr = CreateArray();
            
            //Buffer to store the map name
            decl String:nameBuffer[255];
            
            //Variable to store the map weight.
            new weight;
            
            //A nomination.
            new Handle:trie = INVALID_HANDLE;
            
            //Rewind the mapcycle.
            KvRewind(map_kv);
            
            //Jump to the category in the mapcycle.
            KvJumpToKey(map_kv, cat);
            
            //Set up the cat config
            KvGetString(map_kv, "command", cat_config, sizeof(cat_config));
            
            //Add nomination to name and weight array for...
            //    ...each nomination in the nomination array for this category.
            new arraySize = GetArraySize(nominationsFromCat);
            for (new i = 0; i < arraySize; i++)
            {
                //Get the nomination at the current index.
                trie = GetArrayCell(nominationsFromCat, i);
                
                //Get the map name from the nomination.
                GetTrieString(trie, "map", nameBuffer, sizeof(nameBuffer));    
                
                //Add the map to the storage arrays if...
                //    ...the map is valid (correct number of players, correct time)
                if (IsValidMapFromCat(map_kv, nameBuffer))
                {
                    //Increment the nomination counter.
                    counter++;
                    
                    //Add the map to the map name array.
                    PushArrayString(nameArr, nameBuffer);
                    
                    //Add the map's weight to the map weight array.
                    GetTrieValue(trie, "weight", weight);
                    PushArrayCell(weightArr, weight);
                }
            }
            
            //Pick a random map from the nominations if...
            //    ...there are nominations to choose from.
            if (counter > 0)
            {
                GetWeightedRandomSubKey(map, sizeof(map), weightArr, nameArr);
                
                //Get additional data from the map
                KvRewind(map_kv);
                KvJumpToKey(map_kv, cat);
                KvGetString(map_kv, "next_mapgroup", next_rand_cat, sizeof(next_rand_cat));
                KvJumpToKey(map_kv, map);
                KvGetString(map_kv, "command", map_config, sizeof(map_config));
                KvGoBack(map_kv);
            }
            else //Otherwise, we select a map randomly from the category.
            {
                //Set the current category as the category to be selected randomly from.
                //This is necessary for RandomNextMaps algorithm to select specifically from the
                //winning category.
                strcopy(next_rand_cat, sizeof(next_rand_cat), cat);
                
                //Pick and set the next map.
                RandomNextMap(rtv_mem_arr, rtv_catmem_arr);
                
                //Fetch the new next map.
                GetNextMap(map, sizeof(map));
            }
            
            //Close the handles for the storage arrays.
            CloseHandle(nameArr);
            CloseHandle(weightArr);
        }
        else //Otherwise, there are no nominations to worry about so we just pick a map randomly
             //from the winning category.
        {
            //Set the current category as the category to be selected randomly from.
            //This is necessary for RandomNextMaps algorithm to select specifically from the
            //winning category.
            strcopy(next_rand_cat, sizeof(next_rand_cat), cat);
            
            //Pick and set the next map.
            RandomNextMap(rtv_mem_arr, rtv_catmem_arr);
            
            //Fetch the new next map.
            GetNextMap(map, sizeof(map));
        }
        
        //We no longer need the adt_array to store nominations.
        CloseHandle(nominationsFromCat);
        
        PrintToChatAll(
            "[UMC] %t %t (%t)",
            "End of Map Vote Over",
            "RTV Group Won",
                map, cat,
            "Vote Win Percentage",
                float(item_info[winner][VOTEINFO_ITEM_VOTES]) / float(num_votes) * 100,
                num_votes
        );
        LogMessage("RTV: Players voted for map group '%s.'", cat);
            
        //Change the map.
        ChangeMapRTV(map);
    }
}


//Handles the results of an RTV tiered vote.
public Handle_TierRTVResults(Handle:menu, num_votes, num_clients,
                             const client_info[][2], num_items, const item_info[][2])
{        
    //Play the vote completed sound if...
    //  ...the vote completed sound is defined.
    if (strlen(rtv_end_sound) > 0)
        EmitSoundToAll(rtv_end_sound);

    //Get the winning category.
    new winner = GetWinner(num_items, item_info);
    decl String:cat[255];
    GetMenuItem(menu, item_info[winner][VOTEINFO_ITEM_INDEX], cat, sizeof(cat));
    
    //RUNOFF HERE
    new Float:winPercent = float(item_info[winner][VOTEINFO_ITEM_VOTES]) / float(num_votes) * 100;
    if (remaining_runoffs > 0 && winPercent < GetConVarFloat(cvar_runoff_threshold) * 100)
    {
        rtv_enabled = false;
        DoRunoffVote(menu, num_votes, num_clients, client_info, num_items, item_info,
                     Handle_TierRTVResults, vote_start_sound);
        return;
    }
    
    //Print a message and reset the RTV timer if...
    //    ...the server voted to not change the map.
    if (StrEqual(cat, "?DontChange?"))
    {
        /*PrintToChatAll(
            "[UMC] Map voting has finished. The map will not be changed. (Received %.f%% of %i votes)",
            float(item_info[winner][VOTEINFO_ITEM_VOTES]) / float(num_votes) * 100,
            num_votes
        );*/
        PrintToChatAll(
            "[UMC] %t %t (%t)",
            "End of Map Vote Over",
            "Map Unchanged",
            "Vote Win Percentage",
                float(item_info[winner][VOTEINFO_ITEM_VOTES]) / float(num_votes) * 100,
                num_votes
        );
        LogMessage("RTV: Players voted to stay on the map (Don't Change).");
        
        //Reset the RTV timer.
        rtv_delaystart = GetConVarFloat(cvar_rtv_interval);
        MakeRTVTimer();
    }
    else //Otherwise, we set up the second stage of the tiered vote
    {
        LogMessage("RTV (Tiered): Players voted for map group '%s.'", cat);
        
        KvRewind(map_kv);
        KvJumpToKey(map_kv, cat);
        if (CountValidMapsFromCat(map_kv, rtv_mem_arr) == 1)
        {
            Handle_CatRTVResults(menu, num_votes, num_clients, client_info, num_items, item_info);
            KvGoBack(map_kv);
            return;
        }
        KvGoBack(map_kv);
    
        //Setup timer to delay the next vote for a few seconds.
        tiered_delay = 4;
        
        DisplayTierMessage(5);
        
        CreateTimer(
            1.0,
            Handle_TieredRTVTimer,
            MakeSecondTieredCatExclusion(cat),
            TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT | TIMER_DATA_HNDL_CLOSE
        );
    }
}


//Called when the timer for the tiered RTV vote triggers.
public Action:Handle_TieredRTVTimer(Handle:timer, Handle:excludedCats)
{
    if (tiered_delay > 0)
    {
        DisplayTierMessage(tiered_delay);
        tiered_delay--;
        return Plugin_Continue;
    }
    
    if (IsVoteInProgress())
    {
        LogMessage("RTV (Tiered): There is a vote already in progress, cannot start a new vote.");
        return Plugin_Stop;
    }
        
    //Log a message
    LogMessage("RTV (Tiered): Starting second stage of a tiered RTV.");
        
    //Initialize the menu.
    new Handle:menu = BuildMapVoteMenu(Handle_MapRTVResults, GetConVarBool(cvar_scramble),
                                       false, false, rtv_mem_arr, excludedCats, true);
        
    if (menu != INVALID_HANDLE)
    {
        //Play the vote start sound if...
        //  ...the vote start sound is defined.
        if (strlen(rtv_start_sound) > 0)
            EmitSoundToAll(rtv_start_sound);
                
        //Display the menu.
        if (!VoteMenuToAll(menu, GetConVarInt(cvar_vote_time)))
            LogMessage("RTV (Tiered): Menu already has a vote in progress, cannot start a new vote.");
    }
    else
        LogError("RTV (Tiered): Unable to create second stage tiered vote menu, voting aborted."); 
        
    return Plugin_Stop;
}


//Handles the map change from an RTV.
ChangeMapRTV(const String:map[])
{
    //We have officially completed an RTV at this point.
    rtv_completed = true;
    
    //Destroy all of the other timers, there's no need to run an end-of-map vote.
    DestroyTimers();
    
    //And change the map based off of the action defined in the rtv change action cvar.
    SetupMapChange(GetConVarInt(cvar_rtv_changetime), map, "RTV");
}


//************************************************************************************************//
//                                        VOTING UTILITIES                                        //
//************************************************************************************************//

//Builds and returns a menu for a map vote.
//    callback:   function to be called when the vote is finished.
//    scramble:   whether the menu items are in a random order (true) or in the order the categories 
//                are listed in the cycle.
//    extend:        whether an extend option should be added to the vote.
//    dontChange: whether a "Don't Change" option should be added to the vote.
//    excluded:    adt_array of maps to be excluded from the vote.
//    excludedCats: adt_array of cats to be excluded from the vote.
Handle:BuildMapVoteMenu(const VoteHandler:callback, bool:scramble, bool:extend, bool:dontChange, 
                        Handle:excluded=INVALID_HANDLE, Handle:excludedCats=INVALID_HANDLE,
                        bool:ignoreInvoteSetting=false)
{
    //Throw an error and return nothing if...
    //    ...the mapcucle is invalid.
    if (map_kv == INVALID_HANDLE)
    {
        LogError("VOTING: Cannot build map vote menu, rotation file is invalid.");
        return INVALID_HANDLE;
    }
    
    //Duplicate the map_kv handle, because we will be deleting some keys.
    new Handle:kv = CreateKeyValues("random_rotation"); //new handle
    KvRewind(map_kv); //rewind original
    KvCopySubkeys(map_kv, kv); //copy everything to the new handle
    
    //Log an error and return nothing if...
    //    ...it cannot find a category.
    if (!KvGotoFirstSubKey(kv))
    {
        LogError("VOTING: No map categories found in rotation. Vote menu was not built.");
        CloseHandle(kv);
        return INVALID_HANDLE;
    }

    //Determine how we're logging
    new bool:verboseLogs = GetConVarBool(cvar_logging);

    //Buffers
    decl String:mapName[255];     //Name of the map
    decl String:catName[255];     //Name of the category.
    decl String:nextCatName[255]; //Name of the next category to be set (if the map wins the vote).
    decl String:catConfig[255];
    decl String:mapConfig[255];
    
    //Other variables
    new voteCounter = 0; //Number of maps in the vote currently
    new numNoms = 0;     //Number of nominated maps in the vote.
    new Handle:nominationsFromCat = INVALID_HANDLE; //adt_array containing all nominations from the
                                                    //current category.
    new Handle:trie = INVALID_HANDLE;       //a nomination
    new Handle:nameArr = INVALID_HANDLE;   //adt_array of map names from nominations
    new Handle:weightArr = INVALID_HANDLE; //adt_array of map weights from nominations.
    
    new nomIndex, position, numMapsFromCat, nomCounter, weight, inVote, index;
    
    //Add maps to vote array from current category.
    do
    {
        //Store the name of the current category.
        KvGetSectionName(kv, catName, sizeof(catName));
        
        //Skip this category if...
        //  ...it is to be excluded.
        if (FindStringInArray(excludedCats, catName) != -1)
        {
            if (verboseLogs)
            {
                LogMessage(
                    "VOTE MENU: (Verbose) Skipped map group '%s' because it was played within %i maps ago. (See \"sm_umc_endvote_catexclude\" or \"sm_umc_rtv_catexclude\")",
                    catName, GetArraySize(excludedCats)
                );
            }
            continue;
        }
        
        //Store the name of the next category, in the event a map from this category wins the vote.
        KvGetString(kv, "next_mapgroup", nextCatName, sizeof(nextCatName));
        
        //Store the config file to be executed
        KvGetString(kv, "command", catConfig, sizeof(catConfig));
        
        //Get all nominations for the current category.
        nominationsFromCat = FilterNominations("cat", catName);
        
        //Get the amount of nominations for the current category.
        numNoms = GetArraySize(nominationsFromCat);
        
        //Get the total amount of maps to appear in the vote from this category.
        inVote = ignoreInvoteSetting ? GetConVarInt(cvar_vote_tieramount) : KvGetNum(kv, "maps_invote", 1);
        
        if (verboseLogs)
        {
            if (ignoreInvoteSetting)
                LogMessage("VOTE MENU: (Verbose) Second stage tiered vote. See cvar \"sm_umc_vote_tieramount.\"");
            LogMessage("VOTE MENU: (Verbose) Fetching %i maps from group '%s.'", inVote, catName);
        }
        
        //Calculate the number of maps we still need to fetch from the mapcycle.
        numMapsFromCat = inVote - numNoms;
        
        //Populate vote with nomination maps from this category if...
        //    ...we do not need to fetch any maps from the mapcycle AND
        //    ...the number of nominated maps in the vote is limited to the maps_invote setting for
        //       the category.
        if (numMapsFromCat < 0 && GetConVarBool(cvar_strict_noms))
        {
            //////
            //The piece of code inside this block is for the case where the current category's
            //nominations exceeds it's number of maps allowed in the vote.
            //
            //In order to solve this problem, we first fetch all nominations where the map has
            //appropriate min and max players for the amount of players on the server, and then
            //randomly pick from this pool based on the weights if the maps, until the number
            //of maps in the vote from this category is reached.
            //
            //POSSIBLE BUG HERE:
            //    The pool may be smaller than the required number of maps for the category. Can be
            //    prevented by filtering the nominations for validity before testing to see
            //     if the amount of nominations is greater than the in_vote setting.
            //////
            
            if (verboseLogs)
            {
                LogMessage(
                    "VOTE MENU: (Verbose) Number of nominations (%i) exceeds allowable maps in vote for the map group '%s'. Limiting nominated maps to %i. (See cvar \"sm_umc_nominate_strict\")",
                    numNoms, catName, inVote
                );
            }
        
            //No nominations have been fetched from pool of possible nomination.
            nomCounter = 0;
            
            //Populate vote array with nominations from this category if...
            //    ...we have nominations from this category.
            if (numNoms > 0)
            {
                //Initialize name and weight adt_arrays.
                nameArr = CreateArray(255);
                weightArr = CreateArray();
                
                //Store data from a nomination for...
                //    ...each index of the adt_array of nominations from this category.
                for (new i = 0; i < numNoms; i++)
                {
                    //Store nomination.
                    trie = GetArrayCell(nominationsFromCat, i);
                    
                    //Get the map name from the nomination.
                    GetTrieString(trie, "map", mapName, sizeof(mapName));    
                    
                    //Add map to list of possible maps to be added to vote from the nominations 
                    //if...
                    //    ...the map is valid (correct number of players, correct time)
                    if (FindStringInArray(map_vote, mapName) != -1)
                    {
                        if (verboseLogs)
                        {
                            LogMessage(
                                "VOTE MENU: (Verbose) Skipping nominated map '%s' from map group '%s' because it already is in the vote.",
                                mapName, catName
                            );
                        }
                    }
                    else if (IsValidMapFromCat(kv, mapName))
                    {
                        //Increment number of noms fetched.
                        nomCounter++;
                        
                        //Add map name to the pool.
                        PushArrayString(nameArr, mapName);
                        
                        //Add map weight to the pool.
                        GetTrieValue(trie, "weight", weight);
                        PushArrayCell(weightArr, weight);
                    }
                    else
                    {
                        if (verboseLogs)
                        {
                            LogMessage(
                                "VOTE MENU: (Verbose) Skipping nominated map '%s' from map group '%s' due to invalid server player count or server time.",
                                mapName, catName
                            );
                        }
                    }
                }
                
                //After we have parsed every map from the list of nominations...
                
                //Populate vote array with maps from the pool if...
                //    ...the number of nominations fetched is greater than zero.
                if (nomCounter > 0)
                {
                    //Add a nominated map from the pool into the vote arrays for...
                    //    ...the number of available spots there are from the category.
                    new min = (inVote < nomCounter) ? inVote : nomCounter;
                    for (new i = 0; i < min; i++)
                    {
                        //Get a random map from the pool.
                        GetWeightedRandomSubKey(mapName, sizeof(mapName), weightArr, nameArr);
                        
                        //Get the position in the vote array to add the map to
                        position = GetNextMenuIndex(voteCounter, scramble);
                        
                        //Get extra fields from the map
                        KvJumpToKey(kv, mapName);
                        KvGetString(kv, "command", mapConfig, sizeof(mapConfig));
                        KvGoBack(kv);
                        
                        //Add map data to the vote arrays.
                        InsertArrayString(map_vote_next_cats, position, nextCatName);
                        InsertArrayString(map_vote_cats, position, catName);
                        InsertArrayString(map_vote, position, mapName);
                        InsertArrayString(map_vote_cat_configs, position, catConfig);
                        InsertArrayString(map_vote_map_configs, position, mapConfig);

                        //Increment number of maps added to the vote.
                        voteCounter++;

                        //Remove map from pool.
                        index = FindStringInArray(nameArr, mapName);
                        RemoveFromArray(nameArr, index);
                        RemoveFromArray(weightArr, index);
                        
                        if (verboseLogs)
                        {
                            LogMessage(
                                "VOTE MENU: (Verbose) Nominated map '%s' from group '%s' was added to the vote.",
                                mapName, catName
                            );
                        }
                    }
                }
                
                //Close handles for the pool.
                CloseHandle(nameArr);
                CloseHandle(weightArr);
                
                //Update numMapsFromCat to reflect the actual amount still required.
                numMapsFromCat = inVote - nomCounter;
            }
        }
        //Otherwise, we fill the vote with nominations then fill the rest with random maps from the
        //mapcycle.
        else
        {
            //Add nomination to the vote array for..
            //    ...each index in the nomination array.
            for (new i = 0; i < numNoms; i++)
            {
                //Get map name.
                GetTrieString(GetArrayCell(nominationsFromCat, i), "map", mapName, sizeof(mapName));
                
                //Add nominated map to the vote array if...
                //    ...the map isn't already in the vote AND
                //    ...the server has a valid number of players for the map.
                if (FindStringInArray(map_vote, mapName) != -1)
                {
                    if (verboseLogs)
                    {
                        LogMessage(
                            "VOTE MENU: (Verbose) Skipping nominated map '%s' from map group '%s' because it is already in the vote.",
                            mapName, catName
                        );
                    }
                }
                else if (!IsValidMapFromCat(kv, mapName))
                {
                    if (verboseLogs)
                    {
                        LogMessage(
                            "VOTE MENU: (Verbose) Skipping nominated map '%s' from map group '%s' due to invalid server player count or server time.",
                            mapName, catName
                        );
                    }
                }
                else
                {
                    //Get extra fields from the map
                    KvJumpToKey(kv, mapName);
                    KvGetString(kv, "command", mapConfig, sizeof(mapConfig));
                    KvGoBack(kv);
                    
                    //Get the position in the vote array to add the map to.
                    position = GetNextMenuIndex(voteCounter, scramble);
                    
                    //Add map data to the vote arrays.
                    InsertArrayString(map_vote_next_cats, position, nextCatName);
                    InsertArrayString(map_vote_cats, position, catName);
                    InsertArrayString(map_vote, position, mapName);
                    InsertArrayString(map_vote_cat_configs, position, catConfig);
                    InsertArrayString(map_vote_map_configs, position, mapConfig);
                    
                    //Increment number of maps added to the vote.
                    voteCounter++;
                    
                    if (verboseLogs)
                    {
                        LogMessage(
                            "VOTE MENU: (Verbose) Nominated map '%s' from group '%s' was added to the vote.",
                            mapName, catName
                        );
                    }
                }
            }
        }
        
        //////
        //At this point in the algorithm, we have already handled nominations for this category.
        //If there are maps which still need to be added to the vote, we will be fetching them
        //from the mapcycle directly.
        //////
        
        if (verboseLogs)
        {
            LogMessage("VOTE MENU: (Verbose) Finished parsing nominations for map group '%s.'",
                catName);
            if (numMapsFromCat > 0)
            {
                LogMessage("VOTE MENU: (Verbose) Still need to fetch %i maps from the group.",
                    numMapsFromCat);
            }
        }
        
        //We no longer need the nominations array, so we close the handle.
        CloseHandle(nominationsFromCat);
        
        //Add a map to the vote array from the current category while...
        //    ...maps still need to be added from the current category.
        while (numMapsFromCat > 0)
        {
            //Skip the category if...
            //    ...there are no more maps that can be added to the vote.
            if (!GetRandomMap(kv, mapName, sizeof(mapName), excluded))
            {
                if (verboseLogs)
                    LogMessage("VOTE MENU: (Verbose) No more maps in map group '%s.'", catName);
                break;
            }

            //The name of the selected map is now stored in mapName.    

            //Remove the map from the category (so it cannot be selected again) and repick a map 
            //if...
            //    ...the map has already been added to the vote (through nomination or another 
            //       category
            if (FindStringInArray(map_vote, mapName) != -1)
            {
                KvDeleteKey(kv, mapName);
                if (verboseLogs)
                {
                    LogMessage(
                        "VOTE MENU: (Verbose) Skipping selected map '%s' from map group '%s' because it is already in the vote.",
                        mapName, catName
                    );
                }
                continue;
            }
            
            //At this point we have a map which we are going to add to the vote array.

            if (verboseLogs)
            {
                LogMessage(
                    "VOTE MENU: (Verbose) Selected map '%s' from group '%s' was added to the vote.",
                    mapName, catName
                );
            }

            //Find this map in the list of nominations.
            nomIndex = FindNominationIndex(mapName);
            
            //Remove the nomination if...
            //    ...it was found.
            if (nomIndex != -1)
            {
                RemoveFromArray(nominations_arr, nomIndex);
                if (verboseLogs)
                {
                    LogMessage("VOTE MENU: (Verbose) Removing selected map '%s' from nominations.",
                        mapName);
                }
            }

            //Get extra fields from the map
            KvJumpToKey(kv, mapName);
            KvGetString(kv, "command", mapConfig, sizeof(mapConfig));
            KvGoBack(kv);
                    
            //Get the position in the vote array to add the map to.
            position = GetNextMenuIndex(voteCounter, scramble);
            
            //Add map data to the vote arrays.
            InsertArrayString(map_vote_next_cats, position, nextCatName);
            InsertArrayString(map_vote_cats, position, catName);
            InsertArrayString(map_vote, position, mapName);
            InsertArrayString(map_vote_cat_configs, position, catConfig);
            InsertArrayString(map_vote_map_configs, position, mapConfig);
            
            //Delete the map from the KV so we can't pick it again.
            KvDeleteKey(kv, mapName); 
            
            //Increment number of maps added to the vote.
            voteCounter++;
            
            //One less map to be added to the vote from this category.
            numMapsFromCat--;
        }
    } while (KvGotoNextKey(kv)); //Do this for each category.
    
    //We no longer need the copy of the mapcycle
    CloseHandle(kv); //Cleanup
    
    //Begin creating menu
    new Handle:menu = CreateMenu(Handle_VoteMenu); //New menu
    SetVoteResultCallback(menu, callback); //Set callback
    SetMenuExitButton(menu, false); //Don't want an exit button.
        
    //Set the title
    SetMenuTitle(menu, "%T", "Map Vote Menu Title", LANG_SERVER);
    
    //Keep track of slots taken up in the vote.
    new voteSlots = 0;
    
    //Add blocked slots if...
    //    ...the cvar for blocked slots is enabled.
    new blockSlots = GetConVarInt(cvar_block_slots);
    if (blockSlots > 3)
    {
        AddMenuItem(menu, "nothing", " ", ITEMDRAW_SPACER);
        voteSlots++;
    }
    if (blockSlots > 0)
    {
        decl String:block1[255];
        Format(block1, sizeof(block1), "%T", "Slot Block Message 1", LANG_SERVER); 
        AddMenuItem(menu, "nothing", block1, ITEMDRAW_DISABLED);
        voteSlots++;
    }
    if (blockSlots > 1)
    {
        decl String:block2[255];
        Format(block2, sizeof(block2), "%T", "Slot Block Message 2", LANG_SERVER);
        AddMenuItem(menu, "nothing", block2, ITEMDRAW_DISABLED);
        voteSlots++;
    }
    if (blockSlots > 2)
    {
        AddMenuItem(menu, "nothing", " ", ITEMDRAW_SPACER);
        voteSlots++;
    }
    if (blockSlots > 4)
    {
        AddMenuItem(menu, "nothing", " ", ITEMDRAW_SPACER);
        voteSlots++;
    }
    
    //Add the array of votes to the menu.
    AddArrayToMenu(menu, map_vote);
    voteSlots += GetArraySize(map_vote);
    
    if (verboseLogs && GetConVarBool(cvar_scramble))
        LogMessage("VOTE MENU: (Verbose) Scrambling menu.");
    
    //Add an extend item if...
    //    ...the extend flag is true.
    if (extend)
    {
        decl String:extendOption[255];
        Format(extendOption, sizeof(extendOption), "%T", "Extend", LANG_SERVER);
        AddMenuItem(menu, "?Extend?", extendOption);
        voteCounter++;
        voteSlots++;
    }
    //Add a don't change item if...
    //    ...the don't change flag is true.
    if (dontChange)
    {
        decl String:change[255];
        Format(change, sizeof(change), "%T", "Don't Change", LANG_SERVER);
        AddMenuItem(menu, "?DontChange?", change);
        voteCounter++;
        voteSlots++;
    }
    //Throw an error and return nothing if...
    //    ...the number of items in the vote is less than 2 (hence no point in voting).
    if (voteCounter <= 1)
    {
        LogError("VOTING: Not enough maps to run a map vote. %i maps available.", voteCounter);
        CloseHandle(menu);
        ClearVoteArrays();
        return INVALID_HANDLE;
    }
    else //Otherwise, finish making the menu.
    {
        //Disable pagination if...
        //    ...the number of slots taken up is less than or equal to 10.
        if (voteSlots <= 9)
            SetMenuPagination(menu, MENU_NO_PAGINATION);
        return menu; //Return the finished menu (finally).
    }
}


//Builds and returns a menu for a category vote.
//    callback:   function to be called when the vote is finished.
//    scramble:   whether the menu items are in a random order (true) or in the order the categories 
//                are listed in the cycle.
//    extend:        whether an extend option should be added to the vote.
//    dontChange: whether a "Don't Change" option should be added to the vote.
//  excluded:    adt_array of maps to be excluded from the vote
Handle:BuildCatVoteMenu(VoteHandler:callback, bool:scramble, bool:extend, bool:dontChange=false,
                        Handle:excluded=INVALID_HANDLE, Handle:excludedCats=INVALID_HANDLE)
{
    //Throw an error and return nothing if...
    //    ...the mapcycle is invalid.
    if (map_kv == INVALID_HANDLE)
    {
        LogError("VOTING: Cannot build map group vote menu, rotation file is invalid.");
        return INVALID_HANDLE;
    }
    
    //Rewind our mapcycle.
    KvRewind(map_kv);
    
    //Log an error and return nothing if...
    //    ...it cannot find a category.
    if (!KvGotoFirstSubKey(map_kv))
    {
        LogError("VOTING: No map categories found in rotation. Vote menu was not built.");
        return INVALID_HANDLE;
    }
    
    new bool:verboseLogs = GetConVarBool(cvar_logging);

    decl String:catName[255]; //Buffer to store category name in.
    new voteCounter = 0;      //Number of categories in the vote.
    new Handle:catArray = CreateArray(255, 0); //Array of categories in the vote.
    
    //Add the current category to the vote.
    do
    {
        KvGetSectionName(map_kv, catName, sizeof(catName));
        
        //Skip this category if...
        //    ...the server doesn't have the required amount of players or all maps are excluded OR
        //    ...the number of maps in the vote from the category is less than 1.
        if (!IsValidCat(map_kv, excludedCats, excluded))
        {
            if (verboseLogs)
            {
                LogMessage(
                    "VOTE MENU: (Verbose) Skipping map group '%s' due to invalid server player count or server time.",
                    catName
                );
            }
            continue;
        }
        else if (KvGetNum(map_kv, "maps_invote", 1) <= 0)
        {
            if (verboseLogs)
            {
                LogMessage(
                    "VOTE MENU: (Verbose) Skipping map group '%s' due to \"maps_invote\" setting of 0.",
                    catName
                );
            }
            continue;
        }
        
        if (verboseLogs)
            LogMessage("VOTE MENU: (Verbose) Group '%s' was added to the vote.", catName);
        
        //Add category to the vote array...
        InsertArrayString(catArray, GetNextMenuIndex(voteCounter, scramble), catName);
        
        //Increment number of categories in the vote.
        voteCounter++;
    } while (KvGotoNextKey(map_kv)); //Do this for each category.
    
    //Begin creating menu
    new Handle:menu = CreateMenu(Handle_VoteMenu); //New menu
    SetVoteResultCallback(menu, callback);    //Set callback
    SetMenuExitButton(menu, false); //Disable exit button
    
    //Set the title
    SetMenuTitle(menu, "%T", "Group Vote Menu Title", LANG_SERVER);
    
    //Keep track of slots taken up in the vote.
    new voteSlots = 0;

    //Add blocked slots if...
    //    ...the cvar for blocked slots is enabled.
    new blockSlots = GetConVarInt(cvar_block_slots);
    if (blockSlots > 3)
    {
        AddMenuItem(menu, "nothing", " ", ITEMDRAW_SPACER);
        voteSlots++;
    }
    if (blockSlots > 0)
    {
        decl String:block1[255];
        Format(block1, sizeof(block1), "%T", "Slot Block Message 1", LANG_SERVER); 
        AddMenuItem(menu, "nothing", block1, ITEMDRAW_DISABLED);
        voteSlots++;
    }
    if (blockSlots > 1)
    {
        decl String:block2[255];
        Format(block2, sizeof(block2), "%T", "Slot Block Message 2", LANG_SERVER);
        AddMenuItem(menu, "nothing", block2, ITEMDRAW_DISABLED);
        voteSlots++;
    }
    if (blockSlots > 2)
    {
        AddMenuItem(menu, "nothing", " ", ITEMDRAW_SPACER);
        voteSlots++;
    }
    if (blockSlots > 4)
    {
        AddMenuItem(menu, "nothing", " ", ITEMDRAW_SPACER);
        voteSlots++;
    }
    
    //Add array of votes to the menu.
    AddArrayToMenu(menu, catArray);
    voteSlots += GetArraySize(catArray);

    //We no longer need the vote array, so we close the handle.
    CloseHandle(catArray);

    //Add an extend item if...
    //    ...the extend flag is true.
    if (extend)
    {
        decl String:extendOption[255];
        Format(extendOption, sizeof(extendOption), "%T", "Extend", LANG_SERVER);
        AddMenuItem(menu, "?Extend?", extendOption);
        voteCounter++;
        voteSlots++;
    }
    //Add a don't change item if...
    //    ...the don't change flag is true.
    if (dontChange)
    {
        decl String:change[255];
        Format(change, sizeof(change), "%T", "Don't Change", LANG_SERVER);
        AddMenuItem(menu, "?DontChange?", change);
        voteCounter++;
        voteSlots++;
    }
    //Throw an error and return nothing if...
    //    ...the number of items in the vote is less than 2 (hence no point in voting).
    if (voteCounter <= 1)
    {
        LogError("VOTING: Not enough map groups to run a group vote. %i groups available.",
            voteCounter);
        CloseHandle(menu);
        ClearVoteArrays();
        return INVALID_HANDLE;
    }
    else
    {
        //Disable pagination if...
        //    ...the number of slots taken up is less than or equal to 10.
        if (voteSlots <= 9)
            SetMenuPagination(menu, MENU_NO_PAGINATION);
        return menu; //Return our finished menu!
    }
}


//Called when a vote has finished.
public Handle_VoteMenu(Handle:menu, MenuAction:action, param1, param2)
{
    //Cleanup the memory taken by the vote if...
    //    ...the vote is actually over.
    if (action == MenuAction_End)
    {
        CloseHandle(menu);
        ClearVoteArrays();
        remaining_runoffs = GetConVarInt(cvar_runoff);
    }
}


//Utility function to clear all the voting storage arrays.
ClearVoteArrays()
{
    ClearArray(map_vote_next_cats);
    ClearArray(map_vote_cats);
    ClearArray(map_vote);
    ClearArray(map_vote_cat_configs);
    ClearArray(map_vote_map_configs);
}


//Get the winner from a vote.
GetWinner(num_items, const item_info[][2])
{
    new counter = 1;
    new most_votes = item_info[0][VOTEINFO_ITEM_VOTES];
    while (counter < num_items)
    {
        if (item_info[counter][VOTEINFO_ITEM_VOTES] < most_votes)
            break;
        counter++;
    }
    if (counter > 1)
        return GetRandomInt(0, counter - 1);
    else
        return 0;
}


//Generates a list of categories to be excluded from the second stage of a tiered vote.
Handle:MakeSecondTieredCatExclusion(const String:cat[])
{
    //Array to return at the end.
    new Handle:result = CreateArray(255, 0);
    
    //Reset the mapcycle to the root entry.
    KvRewind(map_kv);
    
    //Log an error and return nothing if...
    //  ...there are no categories in the cycle (for some reason).
    if (!KvGotoFirstSubKey(map_kv))
    {
        CloseHandle(result);
        LogError("TIERED VOTE: Cannot create second stage of vote, rotation file is invalid (no categories were found.)");
        return INVALID_HANDLE;
    }
    
    //Buffer to store a category name
    decl String:catName[255];
    
    do //For a category in the mapcycle...
    {
        //Get the name of the category.
        KvGetSectionName(map_kv, catName, sizeof(catName));
        
        //Add the category name to the result array if...
        //  ...it is not equal to the given category.
        if (!StrEqual(catName, cat))
            PushArrayString(result, catName);
        
    } while (KvGotoNextKey(map_kv));
    
    //Return to the root.
    KvGoBack(map_kv);
    
    //Success!
    return result;
}


//Updates the display for the interval between tiered votes.
DisplayTierMessage(timeleft)
{
    PrintCenterTextAll("Another vote is on the way in %i seconds.", timeleft);
}


//Sets up a runoff vote.
DoRunoffVote(Handle:menu, num_votes, num_clients, const client_info[][2], num_items,
             const item_info[][2], VoteHandler:callback, const String:sound[]="")
{   
    //Array to store clients the menu will be displayed to.
    runoff_clients = CreateArray();
    
    //Build the runoff vote based off of the results of the failed vote.
    runoff_menu = BuildRunoffMenu(menu, num_votes, num_clients, client_info, num_items,
                                  item_info, callback, runoff_clients);

    //Setup the timer if...
    //  ...the menu was built successfully
    if (runoff_menu != INVALID_HANDLE)
    {
        //Setup timer to delay the start of the runoff vote.
        runoff_delay = 7;
        
        //Display the first message
        DisplayRunoffMessage(8);
        
        LogMessage("RUNOFF: Runoff timer created. Runoff vote will be displayed in %i seconds.",
            runoff_delay+1);
        
        //Setup data pack to go along with the timer.
        new Handle:pack;    
        CreateDataTimer(
            1.0,
            Handle_RunoffVoteTimer,
            pack,
            TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT
        );
        //Add info to the pack.
        WritePackString(pack, sound);
    }
    else //Otherwise, cleanup
    {
        LogError("RUNOFF: Unable to create runoff vote menu, runoff aborted.");
        CloseHandle(runoff_clients);
    }
}


//Builds a runoff vote menu.
//  menu:           the menu of the original vote we're running off from
//  num_votes:      the number of votes performed in the original vote
//  num_clients:    the number of clients who *could* vote.
//  client_info:    array of client votes
//  num_items:      number of unique items in the vote
//  item_info:      array of items, sorted by count
//  callback:       VoteHandler to be called when the voting is finished
//  clients:        adt_array to be populated with clients whose votes were eliminated
Handle:BuildRunoffMenu(Handle:menu, num_votes, num_clients, const client_info[][2], num_items,
                       const item_info[][2], VoteHandler:callback, Handle:clientArray)
{
    //Array to contain items we're removing from the original vote.
    new Handle:removedItems = CreateArray();
    
    new bool:verboseLogs = GetConVarBool(cvar_logging);
    
    if (verboseLogs)
        LogMessage("RUNOFF MENU: (Verbose) Building runoff vote menu. (See cvar \"sm_umc_vote_runoffs\"");
    
    //Starting possible max percentage of the winning item in this vote.
    new Float:percent = float(item_info[0][VOTEINFO_ITEM_VOTES]) / float(num_votes) * 100;

    //Starting at the item with the least votes, calculate the new possible max percentage
    //of the winning item. Stop when this percentage is greater than 50.
    for (new i = num_items - 1; i > 0; i--)
    {
        //Update percentage
        percent += float(item_info[i][VOTEINFO_ITEM_VOTES]) / float(num_votes) * 100;
        
        //Add item to removed items array.
        PushArrayCell(removedItems, i);
        
        if (verboseLogs)
        {
            decl String:disp[255], String:buf[255];
            new b = 0;
            GetMenuItem(menu, item_info[i][VOTEINFO_ITEM_INDEX], buf, sizeof(buf), b, disp,
                sizeof(disp));
            LogMessage("RUNOFF MENU: (Verbose) '%s' was removed from the vote.", disp);
        }
        
        //Stop if...
        //  ...the new percentage is over 50.
        if (percent > 50) 
            break;
    }
    
    if (verboseLogs)
    {
        LogMessage(
            "RUNOFF MENU: (Verbose) Stopped removing options from the vote. Maximum possible winning vote percentage is %.f%%.",
            percent
        );
    }
    
    //Array determining which clients have voted
    new bool:clientVotes[MAXPLAYERS];
    
    //For each client, determine if they voted for a removed item, and if so add them to the
    //client array.
    for (new i = 0; i < num_clients; i++)
    {
        if (FindValueInArray(removedItems, client_info[i][VOTEINFO_CLIENT_ITEM]) != -1)
        {
            PushArrayCell(clientArray, client_info[i][VOTEINFO_CLIENT_INDEX]);
            if (verboseLogs)
            {
                LogMessage(
                    "RUNOFF MENU: (Verbose) %N will be presented with the vote again, because he didn't vote for one of the remaining options.",
                    client_info[i][VOTEINFO_CLIENT_INDEX]
                );
            }
        }
        
        //This client did vote
        clientVotes[client_info[i][VOTEINFO_CLIENT_ITEM]] = true;
    }
    
    //Add all clients who didn't vote to the client array
    for (new i = 0; i < sizeof(clientVotes); i++)
    {
        if (!clientVotes[i])
        {
            PushArrayCell(clientArray, i);
            if (verboseLogs)
            {
                LogMessage(
                    "RUNOFF MENU: (Verbose) %N will be presented with the vote again, because he didn't vote.",
                    i
                );
            }
        }
    }
    
    //Start building the new vote menu.
    new Handle:newMenu = CreateMenu(Handle_VoteMenu);
    SetVoteResultCallback(newMenu, callback);
    
    //Set the menu title to the old one.
    new String:title[255];
    GetMenuTitle(menu, title, sizeof(title));
    SetMenuTitle(newMenu, title);
    
    //Storage buffers.
    new item;
    new count = 0;
    decl String:infoBuf[255], String:displayBuf[255];
    
    //For each voted item, determine if the item hasn't been removed from the vote. If so,
    //add the item to the new vote.
    for (new i = 0; i < num_items; i++)
    {
        //Get the item index.
        item = item_info[i][VOTEINFO_ITEM_INDEX];
        
        //Add to the new vote if...
        //  ...it wasn't found in the removed items array.
        if (FindValueInArray(removedItems, item) == -1)
        {
            //Get info from the old vote.
            GetMenuItem(menu, item, infoBuf, sizeof(infoBuf), _, displayBuf, sizeof(displayBuf));
            
            //Add the info to the new vote.
            AddMenuItem(newMenu, infoBuf, displayBuf);
            
            //Increment counter.
            count++;
        }
    }
    
    //We no longer need the removed item array.
    CloseHandle(removedItems);
    
    //Log an error and do nothing if...
    //  ...there weren't enough items added to the runoff vote.
    //  *This shouldn't happen if the algorithm is working correctly*
    if (count < 2)
    {
        CloseHandle(newMenu);
        LogError("RUNOFF: Not enough remaining maps to perform runoff vote. %i maps remaining.",
            count);
        return INVALID_HANDLE;
    }
    
    return newMenu;
}


//Called when the runoff timer for an end-of-map vote completes.
public Action:Handle_RunoffVoteTimer(Handle:timer, Handle:pack)
{
    //Display a message and continue timer if...
    //  ...the timer hasn't finished yet.
    if (runoff_delay > 0)
    {
        DisplayRunoffMessage(runoff_delay);
        runoff_delay--;
        return Plugin_Continue;
    }

    LogMessage("RUNOFF: Starting runoff vote.");
    
    //Log an error and do nothing if...
    //    ...another vote is currently running for some reason.
    if (IsVoteInProgress()) 
    {
        LogMessage("RUNOFF: There is a vote already in progress, cannot start a new vote.");
        return Plugin_Stop;
    }
    
    //Get info from the pack
    ResetPack(pack);
    decl String:sound[255];
    ReadPackString(pack, sound, sizeof(sound));
    
    //Setup array of clients to display the vote to.
    new clients[MAXPLAYERS];
    ConvertArray(runoff_clients, clients, sizeof(clients));
    new numClients = GetArraySize(runoff_clients);
    CloseHandle(runoff_clients);
    
    //Play the vote start sound if...
    //  ...the filename is defined.
    if (strlen(runoff_start_sound) > 0)
        EmitSoundToAll(runoff_start_sound);
    //Otherwise, play the sound for end-of-map votes if...
    //  ...the filename is defined.
    else if (strlen(sound) > 0)
        EmitSoundToAll(sound);
    
    //Run the vote to selected client only if...
    //  ...the cvar to do so is enabled.
    if (GetConVarBool(cvar_runoff_selective))
    {
        //Log an error if...
        //    ...the vote cannot start for some reason.
        if (!VoteMenu(runoff_menu, clients, numClients, GetConVarInt(cvar_vote_time)))
            LogMessage("RUNOFF: Menu already has a vote in progress, cannot start a new vote.");
    }
    //Otherwise, just display it to everybody.
    else
    {
        //Log an error if...
        //    ...the vote cannot start for some reason.
        if (!VoteMenuToAll(runoff_menu, GetConVarInt(cvar_vote_time)))
            LogMessage("RUNOFF: Menu already has a vote in progress, cannot start a new vote.");
    }

    return Plugin_Stop;
}


//Displays a notification for the impending runoff vote.
DisplayRunoffMessage(timeRemaining)
{
    if (timeRemaining > 5)
        PrintCenterTextAll("%t", "Runoff Msg");
    else
        PrintCenterTextAll("%t", "Another Vote", timeRemaining);
}


//************************************************************************************************//
//                                          VOTE WARNINGS                                         //
//************************************************************************************************//

//Parses the vote warning definitions file and returns an adt_array of vote warnings.
GetVoteWarnings(Handle:warning_array)
{
    //Get our warnings file as a Kv file.
    decl String:fileName[255];
    BuildPath(Path_SM, fileName, sizeof(fileName), "configs/vote_warnings.txt");
    new Handle:kv = GetKvFromFile(fileName, "vote_warnings");
    
    //Do nothing if...
    //  ...we can't find the warning definitions.
    if (kv == INVALID_HANDLE)
    {
        LogMessage("Unable to parse vote_warnings.txt, no vote warnings created.");
        return;
    }
    
    //Variables to hold default values. Initially set to defaults in the event that the user doesn't
    //specify his own.
    decl String:dMessage[255];
    Format(dMessage, sizeof(dMessage), "%T", "Default Warning", LANG_SERVER); //Message
    new String:dNotification[2] = "c"; //Notification
    new String:dSound[255] = ""; //Sound
    
    //Grab defaults from the KV if...
    //    ...they are actually defined.
    if (KvJumpToKey(kv, "default"))
    {
        //Grab 'em.
        KvGetString(kv, "message", dMessage, sizeof(dMessage), "%i seconds until vote.");
        KvGetString(kv, "notification", dNotification, sizeof(dNotification), "c");
        KvGetString(kv, "sound", dSound, sizeof(dSound), "");
    
        //Rewind back to root, so we can begin parsing the warnings.
        KvRewind(kv);
    }
    
    //Log an error and return nothing if...
    //    ...it cannot find any defined warnings. If the default definition is found, this code block
    //       will not execute. We will catch this case after we attempt to parse the file.
    if (!KvGotoFirstSubKey(kv))
    {
        LogMessage("SETUP: No vote warnings defined, vote warnings were not created.");
        return;
    }
    
    //Counter to keep track of the number of warnings we're storing.
    new warningCount = 0;
    
    //Storage handle for each warning.
    new Handle:warning = INVALID_HANDLE;
    
    //Storage buffers for warning values.
    new warningTime; //Time (in seconds) before vote when the warning is displayed.
    decl String:nameBuffer[10]; //Buffer to hold the section name;
    decl String:message[255];
    decl String:notification[2];
    decl String:sound[255];
    
    //Storage buffer for formatted sound strings
    decl String:fsound[255];
    decl String:timeString[10];
    
    //Regex to store sequence pattern in.
    static Handle:re = INVALID_HANDLE;
    if (re == INVALID_HANDLE)
        re = CompileRegex("^([0-9]+)\\.\\.\\.([0-9]+)$");
    
    //Variables to store sequence definition
    decl String:sequence_start[10], String:sequence_end[10];
    
    //Variable storing interval of the sequence
    new interval;
    
    //For a warning, add it to the result adt_array.
    do
    {
        //Grab the name (time) of the warning.
        KvGetSectionName(kv, nameBuffer, sizeof(nameBuffer));
        
        //Skip this warning if...
        //    ...it is the default definition.
        if (StrEqual(nameBuffer, "default"))
            continue;
            
        //Store warning info into variables.
        KvGetString(kv, "message", message, sizeof(message), dMessage);
        KvGetString(kv, "notification", notification, sizeof(notification), dNotification);
        KvGetString(kv, "sound", sound, sizeof(sound), dSound);
        
        //Prepare to handle sequence of warnings if...
        //  ...a sequence is what was defined.
        if (MatchRegex(re, nameBuffer) > 0)
        {
            //Get components of sequence
            GetRegexSubString(re, 1, sequence_start, sizeof(sequence_start));
            GetRegexSubString(re, 2, sequence_end, sizeof(sequence_end));
            
            //Calculate sequence interval
            warningTime = StringToInt(sequence_start);
            interval = (warningTime - StringToInt(sequence_end)) + 1;
            //Invert sequence if...
            //  ...it was specified in the wrong order.
            if (interval < 0)
        	{
                interval *= -1;
                warningTime += interval;
            }
        }
        else //Otherwise, just handle the single warning.
        {
            warningTime = StringToInt(nameBuffer);
            interval = 1;
        }
        
        //Store a warning for...
        //  ...each element in the interval.
        for (new i = 0; i < interval; i++)
        {
            //Store everything in a trie which represents a warning object
            warning = CreateTrie();
            SetTrieValue(warning, "time", warningTime - i);
            SetTrieString(warning, "message", message);
            SetTrieString(warning, "notification", notification);
            
            //Insert correct time remaining if...
            //    ...the message has a place to insert it.
            if (StrContains(sound, "{TIME}") != -1)
            {
                IntToString(warningTime - i, timeString, sizeof(timeString));
                strcopy(fsound, sizeof(fsound), sound);
                ReplaceString(fsound, sizeof(fsound), "{TIME}", timeString, false);
                
                //Setup the sound for the warning.
                CacheSound(fsound);
                
                SetTrieString(warning, "sound", fsound);
            }
            else //Otherwise just cache the defined sound.
            {
                //Setup the sound for the warning.
                CacheSound(sound);
                
                SetTrieString(warning, "sound", sound);
            }
            
            //Add the new warning to the result adt_array.
            PushArrayCell(warning_array, warning);
            
            //Increment the counter.
            warningCount++;
        }
    } while(KvGotoNextKey(kv)); //Do this for every warning.
    
    //We no longer need the kv.
    CloseHandle(kv);
    
    //Log an error and return nothing if...
    //    ...no vote warnings were found. This accounts for the case where the default definition was
    //       provided, but not actual warnings.
    if (warningCount < 1)
        LogMessage("SETUP: No vote warnings defined, vote warnings were not created.");
    else //Otherwise, log a success!
    {
        LogMessage("SETUP: Successfully parsed and set up %i vote warnings.", warningCount);
    
        //Sort the array in descending order of time.
        SortADTArrayCustom(warning_array, CompareWarnings);
    }
}


//Comparison function for vote warnings. Used for sorting.
public CompareWarnings(index1, index2, Handle:array, Handle:hndl)
{
    new time1, time2;
    new Handle:warning = INVALID_HANDLE;
    warning = GetArrayCell(array, index1);
    GetTrieValue(warning, "time", time1);
    warning = GetArrayCell(array, index2);
    GetTrieValue(warning, "time", time2);
    return time2 - time1;
}


//Recalculates which warning is the next one to be displayed.
UpdateVoteWarnings()
{
    //Storage variables.
    new warningTime;
    new Handle:warning = INVALID_HANDLE;
    new i;
    
    //Do nothing if...
    //  ...the array isn't defined.
    if (vote_warnings == INVALID_HANDLE)
        return;
        
    //Test if a warning is the next warning to be displayed for...
    //    ...each warning in the warning array.
    new arraySize = GetArraySize(vote_warnings);
    for (i = 0; i < arraySize; i++)
    {
        warning = GetArrayCell(vote_warnings, i);
        GetTrieValue(warning, "time", warningTime);
        
        //We found out answer if...
        //    ...the trigger for the next warning hasn't passed.
        if (FloatCompare(float(warningTime), vote_delaystart) < 0)
            break;
    }
    
    next_warning = i;
    
    if (next_warning < arraySize)
    {
        LogMessage("VOTE WARNINGS: First warning will appear at %i seconds before the end of map vote.",
            warningTime);
    }
}


//Perform a vote warning, does nothing if there is no warning defined for this time.
DoVoteWarning()
{
    //Do nothing if...
    //    ...there are no more warnings to perform.
    if (GetArraySize(vote_warnings) <= next_warning)
        return;

    //Get the current warning.
    new Handle:warning = GetArrayCell(vote_warnings, next_warning);
    
    //Get the trigger time of the current warning.
    new warningTime;
    GetTrieValue(warning, "time", warningTime);
    
    //Display warning if...
    //    ...the time to trigger it has come.
    if (FloatCompare(vote_delaystart, float(warningTime)) <= 0)
    {
        DisplayVoteWarning(warning);
        
        //Move to the next warning.
        next_warning++;
        
        //Repeat in the event that there are multiple warnings for this time.
        DoVoteWarning();
    }
}


//Displays the given vote warning to the server
DisplayVoteWarning(Handle:warning)
{
    //Get warning information.
    new time;
    decl String:message[255];
    decl String:notification[2];
    decl String:sound[255];
    GetTrieValue(warning, "time", time);
    GetTrieString(warning, "message", message, sizeof(message));
    GetTrieString(warning, "notification", notification, sizeof(notification));
    GetTrieString(warning, "sound", sound, sizeof(sound));
    
    //Emit the warning sound if...
    //    ...the sound is defined.
    if (strlen(sound) > 0)
        EmitSoundToAll(sound);
    
    //Stop here if...
    //  ...there is nothing to display.
    if (strlen(message) == 0 || strlen(notification) == 0)
        return;
    
    //Kill timers for previous warnings.
    if (game_message_active)
    {
        TriggerTimer(game_message_timer);
    }
    if (center_warning_active)
    {   
        TriggerTimer(center_message_timer);
    }
        
    //Buffer to store string replacements in the message.
    decl String:sBuffer[5];
    
    //Insert correct time remaining if...
    //    ...the message has a place to insert it.
    if (StrContains(message, "{TIME}") != -1)
    {
        IntToString(time, sBuffer, sizeof(sBuffer));
        ReplaceString(message, sizeof(message), "{TIME}", sBuffer, false);
    }
    
    //Insert a newline character if...
    //    ...the message has a place to insert it.
    if (StrContains(message, "\\n") != -1)
    {
        Format(sBuffer, sizeof(sBuffer), "%c", 13);
        ReplaceString(message, sizeof(message), "\\n", sBuffer);
    }
    
    //Display a chat message ("S") if...
    //    ...the user specifies.
    if (StrContains(notification, "S") != -1) {
        new String:sColor[4];
        
        Format(message, sizeof(message), "%c%s", 1, message);
        
        for (new c = 0; c < sizeof(g_iSColors); c++)
        {
            if (StrContains(message, g_sSColors[c]))
            {
                Format(sColor, sizeof(sColor), "%c", g_iSColors[c]);
                ReplaceString(message, sizeof(message), g_sSColors[c], sColor);
            }
        }
        
        PrintToChatAll(message);
    }
    
    //Buffer to hold message in order to manipulate it.
    decl String:sTextTmp[255];
    
    //Display a top message ("T") if...
    //    ...the user specifies.
    if (StrContains(notification, "T") != -1) {
        sTextTmp = message;
        decl String:sColor[16];
        new iColor = -1, iPos = BreakString(sTextTmp, sColor, sizeof(sColor));
        
        for (new i = 0; i < sizeof(g_sTColors); i++)
        {
            if (StrEqual(sColor, g_sTColors[i]))
                iColor = i;
        }
        
        if (iColor == -1)
        {
            iPos   = 0;
            iColor = 0;
        }
        
        new Handle:hKv = CreateKeyValues("Stuff", "title", sTextTmp[iPos]);
        KvSetColor(hKv, "color", g_iTColors[iColor][0], g_iTColors[iColor][1], 
                   g_iTColors[iColor][2], 255);
        KvSetNum(hKv, "level", 1);
        KvSetNum(hKv, "time",  10);
        
        for (new i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && !IsFakeClient(i))
                CreateDialog(i, hKv, DialogType_Msg);
        }
        
        CloseHandle(hKv);
    }
    
    // Remove colors from advertisement, because
    // C,H,M methods do not support colors.
    
    //Remove a color from the message string for...
    //    ...each color in the Say color array.
    for (new c = 0; c < sizeof(g_iSColors); c++)
    {
        if (StrContains(message, g_sSColors[c]) != -1)
            ReplaceString(message, sizeof(message), g_sSColors[c], "");
    }
    
    //Remove a color from the message string for...
    //    ...each color in the Top color array.
    for (new c = 0; c < sizeof(g_iTColors); c++)
    {
        if (StrContains(message, g_sTColors[c]) != -1)
            ReplaceString(message, sizeof(message), g_sTColors[c], "");
    }
    
    //Display a center message ("C") if...
    //    ...the user specifies.
    if (StrContains(notification, "C") != -1)
    {
        PrintCenterTextAll(message);
        
        //Setup timer to keep the center message visible.
        new Handle:hCenterAd;
        center_message_timer = CreateDataTimer(1.0, Timer_CenterAd, hCenterAd, 
                                               TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
        WritePackString(hCenterAd, message);
        
        center_warning_active = true;
    }
    
    //Display a hint message ("H") if...
    //    ...the user specifies.
    if (StrContains(notification, "H") != -1)
        PrintHintTextToAll(message);
        
    //Display a TF2 Game Event message ("G") if...
    //    ...the user specifies.
    if (StrContains(notification, "G") != -1)
    {
        /*
        decl String:sIcon[64],  String:sBackground[6],  String:sTeam[6];
        
        KvGetString(g_hAdvertisements, "icon",  sIcon,  sizeof(sIcon),
                    "leaderboard_dominated");
        KvGetString(g_hAdvertisements, "background",  sBackground,

        sizeof(sBackground), "0");
        KvGetString(g_hAdvertisements, "team", sTeam, sizeof(sTeam), "0");
        new Float:fTime = KvGetFloat(g_hAdvertisements, "time");
        */
        
        TFGameText(message);
    }
    
}


//Called with each tick of the timer for center messages. Used to keep the message visible for an
//extended period.
public Action:Timer_CenterAd(Handle:timer, Handle:pack)
{
    decl String:sText[256];
    static iCount = 0;
    
    ResetPack(pack);
    ReadPackString(pack, sText, sizeof(sText));
    
    if (center_warning_active && ++iCount < 5)
    {
        PrintCenterTextAll(sText);
        return Plugin_Continue;
    }
    else
    {
        iCount = 0;
        center_message_timer = INVALID_HANDLE;
        center_warning_active = false;
        return Plugin_Stop;
    }
}


//Displays a game text message for TF2.
TFGameText(const String:message[], Float:time=10.0, const String:icon[]="leaderboard_dominated",
           const String:background[]="0", const String:team[]="0")
{        
    if (!IsEntLimitReached(.message="unable to create game_text_tf"))
    {
        new Text_Ent = CreateEntityByName("game_text_tf");
        DispatchKeyValue(Text_Ent,"message",message);
        DispatchKeyValue(Text_Ent,"display_to_team",team);
        DispatchKeyValue(Text_Ent,"icon",icon);
        DispatchKeyValue(Text_Ent,"targetname","game_text1");
        DispatchKeyValue(Text_Ent,"background",background);
        DispatchSpawn(Text_Ent);

        AcceptEntityInput(Text_Ent, "Display", Text_Ent, Text_Ent);
        
        game_message_timer = CreateTimer(time, Kill_ent, 
                                         EntIndexToEntRef(Text_Ent));
        game_message_active = true;
    }
}


//Kills the game text message when the time limit is up.
public Action:Kill_ent(Handle:timer, any:ref)
{
    new ent = EntRefToEntIndex(ref);
    if (ent > 0 && IsValidEntity(ent))
    {
        decl String:classname[50];
        if (GetEdictClassname(ent, classname, sizeof(classname)) &&
            StrEqual(classname, "game_text_tf", false))
        {
            AcceptEntityInput(ent, "kill");
        }
    }
    game_message_active = false;
}


//************************************************************************************************//
//                                         RANDOM NEXTMAP                                         //
//************************************************************************************************//

//Sets a random next map. Returns true on success.
bool:RandomNextMap(Handle:excluded, Handle:excludedCats, bool:ignoreCatWeights=false) 
{    
    //Log an error and fail if...
    //    ...the mapcycle is invalid.
    if (map_kv == INVALID_HANDLE)
    {
        LogError("RANDOM MAP: Unable to select a random map, rotation is invalid.");
        return false;
    }
    
    //Rewind the mapcycle.
    KvRewind(map_kv);
    
    //Copy over the mapcycle, since we will be deleting entries.
    new Handle:kv = CreateKeyValues("dynamic_rotation");
    KvCopySubkeys(map_kv, kv);

    //Buffer to store the name of the category we will be looking for a map in.
    decl String:catName[255];
    
    //Copy the set next category if...
    //    ...the server has the required number of players.
    if (CheckNextCatValidity(kv, excludedCats, excluded))
        strcopy(catName, sizeof(catName), next_rand_cat);
    else //Otherwise there isn't a set next category, so we get a random one from the mapcycle.
    {
        //Use algorithm which ignores cat weights if...
        //  ...the cvar to use it is set to true.
        if (ignoreCatWeights)
        {
            LogMessage("RANDOM MAP: Using alternative algorithm that ignores group weights.");
            new bool:result = RandomNextMapIgnoreCatWeight(kv, excludedCats, excluded);
            CloseHandle(kv);
            return result;
        }
         
        //Log an error and fail if...
        //    ...there are no categories found in the mapcycle.
        if (!GetRandomCat(kv, catName, sizeof(catName), excludedCats, excluded)) //This grabs the random category.
        {
            LogError("RANDOM MAP: Cannot pick a random map, no available map groups found in rotation.");
            CloseHandle(kv);
            return false;
        }
    }
    
    //Jump to the new category.
    KvJumpToKey(kv, catName);
    
    //Set up the cat config
    KvGetString(map_kv, "command", cat_config, sizeof(cat_config));
    
    //Buffer to store the name of the new map.
    decl String:mapName[255];
    
    //Log an error and fail if...
    //    ...there were no maps found in the category.
    if (!GetRandomMap(kv, mapName, sizeof(mapName), excluded))
    {
        LogError("RANDOM MAP: Cannot pick a random map, no available maps found. Parent Group: %s",
            catName);
        CloseHandle(kv);
        return false;
    }
    
    LogMessage("RANDOM MAP: Chose map '%s' from group '%s.'", mapName, catName);

    //Set the map.
    SetTheNextMap(mapName);

    //Set the next category to be used, as defined in the category.
    KvGetString(kv, "next_mapgroup", next_rand_cat, sizeof(next_rand_cat), "");
    
    //Store the category of the next map.
    strcopy(next_cat, sizeof(next_cat), catName);
    
    //Get additional info from the map
    KvJumpToKey(kv, mapName);
    KvGetString(kv, "command", map_config, sizeof(map_config));
    KvGoBack(kv);

    //We don't need the copy of the mapcycle anymore.
    CloseHandle(kv);
    
    //Return success!
    return true;
}


//Sets a random map to the next map while ignoring category weights.
bool:RandomNextMapIgnoreCatWeight(Handle:oldkv, Handle:excludedCats, Handle:excludedMaps)
{
    new Handle:kv = CreateKeyValues("all_maps");
    
    if (!KvGotoFirstSubKey(oldkv))
    {
        LogError("RANDOM MAP: Cannot pick a random, no map groups found in rotation.");
        return false;
    }
    
    //Buffers
    decl String:nextMapGroup[255], String:mapName[255],
         String:catName[255], String:catConfig[255];
    new defaultMinPlayers, defaultMaxPlayers, defaultMinTime, defaultMaxTime;
    new minplayers, maxplayers, mintime, maxtime;
    
    do //For each category
    {
        //Grab information
        KvGetSectionName(oldkv, catName, sizeof(catName));
        
        if (FindStringInArray(excludedCats, catName) != -1)
            continue;
        
        KvGetString(oldkv, "next_mapgroup", nextMapGroup, sizeof(nextMapGroup), "");
        KvGetString(oldkv, "command", catConfig, sizeof(catConfig), "");
        defaultMinPlayers = KvGetNum(oldkv, "default_min_players", 0);
        defaultMaxPlayers = KvGetNum(oldkv, "default_max_players", MaxClients);
        defaultMinTime = KvGetNum(oldkv, "default_min_time", 0);
        defaultMaxTime = KvGetNum(oldkv, "default_max_time", 2359);
    
        if (!KvGotoFirstSubKey(oldkv))
            continue;
        
        do //For each map
        {
            KvGetSectionName(oldkv, mapName, sizeof(mapName));
            KvJumpToKey(kv, mapName, true);
            KvCopySubkeys(oldkv, kv);
            
            //Set proper information
            minplayers = KvGetNum(kv, "min_players", defaultMinPlayers);
            maxplayers = KvGetNum(kv, "max_players", defaultMaxPlayers);
            mintime = KvGetNum(kv, "min_time", defaultMinTime);
            maxtime = KvGetNum(kv, "max_time", defaultMaxTime);
            KvSetString(kv, "next_mapgroup", nextMapGroup);
            KvSetString(kv, "cat", catName);
            KvSetString(kv, "catconfig", catConfig);
            KvSetNum(kv, "min_players", minplayers);
            KvSetNum(kv, "max_players", maxplayers);
            KvSetNum(kv, "min_time", mintime);
            KvSetNum(kv, "max_time", maxtime);
            
            KvGoBack(kv);
        } while (KvGotoNextKey(oldkv));
    } while (KvGotoNextKey(oldkv));
    
    //Log an error and fail if...
    //    ...there were no maps found.
    if (!GetRandomMap(kv, mapName, sizeof(mapName), excludedMaps))
    {
        LogError("RANDOM MAP: Cannot pick a random map, no available maps found in rotation.");
        return false;
    }
    
    //Set the map.
    SetTheNextMap(mapName);
    
    //Goto the winning map.
    KvJumpToKey(kv, mapName);

    //Set the next category to be used, as defined by the map.
    KvGetString(kv, "next_mapgroup", next_rand_cat, sizeof(next_rand_cat), "");
    
    //Set the next category to the name of the category the winning map is from.
    KvGetString(kv, "cat", next_cat, sizeof(next_cat));
    
    LogMessage("RANDOM MAP: Chose map '%s' from group '%s.'", mapName, next_cat);

    //Setup configurations
    KvGetString(kv, "catconfig", cat_config, sizeof(cat_config));
    KvGetString(kv, "command", map_config, sizeof(map_config));

    //We don't need the copy of the mapcycle anymore.
    CloseHandle(kv);
    
    //Return success!
    return true;
}


//Convenience function for getting a weighted random category.
bool:GetRandomCat(Handle:kv, String:buffer[], size, Handle:excludedCats, Handle:excluded)
{
    return GetWeightedRandomCat(kv, buffer, size, "group_weight", excludedCats, excluded);
}


//Convenience function for getting a weighted random map.
bool:GetRandomMap(Handle:kv, String:buffer[], size, Handle:excluded)
{
    return GetWeightedRandomMap(kv, buffer, size, "weight", excluded);
}


//Selects a random map from a category based off of the supplied weights for the maps.
//    kv:     a mapcycle whose traversal stack is currently at the level of the category to choose 
//            from.
//    buffer:    a string to store the selected map in
//    key:  the key containing the weight information (for maps, 'weight', for cats, 'group_weight')
//    excluded: an adt_array of maps to exclude from the selection.
bool:GetWeightedRandomMap(Handle:kv, String:buffer[], size, const String:key[], Handle:excluded)
{
    //Create a trie of default min and max player settings (taken from the category).
    new Handle:defaults = CreateTrie();
    SetTrieValue(defaults, "min_players", KvGetNum(kv, "default_min_players", 0));
    SetTrieValue(defaults, "max_players", KvGetNum(kv, "default_max_players", MaxClients));
    SetTrieValue(defaults, "min_time", KvGetNum(kv, "default_min_time", 0));
    SetTrieValue(defaults, "max_time", KvGetNum(kv, "default_max_time", 2359));
    
    //Return failure if...
    //    ...there are no maps in the category.
    if (!KvGotoFirstSubKey(kv))
    {
        CloseHandle(defaults);
        return false; //Return immediately if there are no subkeys.
    }

    new index = 0; //counter of maps in the random pool
    new Handle:nameArr = CreateArray(255); //Array to store possible map names
    new Handle:weightArr = CreateArray();  //Array to store possible map weights.
    decl String:temp[255]; //Buffer to store map names in.
    
    //Add a map to the random pool.
    do
    {    
        //Skip this map if...
        //    ...it is in the array of excluded maps OR
        //    ...the server doesn't have the required number of players for the map.
        if (!IsValidMap(kv, defaults, excluded))
            continue;
        
        //Get the name of the map.
        KvGetSectionName(kv, temp, sizeof(temp));
        
        //Add the map to the random pool.
        PushArrayCell(weightArr, KvGetFloat(kv, key, 1.0));
        PushArrayString(nameArr, temp);
        
        //One more map in the pool.
        index++;
    } while (KvGotoNextKey(kv)); //Do this for each map.
    
    //Go back to the category level.
    KvGoBack(kv);

    //Close pool and fail if...
    //    ...no maps are selectable.
    if (index == 0)
    {
        CloseHandle(nameArr);
        CloseHandle(weightArr);
        return false;
    }

    //Use weights to randomly select a map from the pool.
    GetWeightedRandomSubKey(buffer, size, weightArr, nameArr);
    
    //Close the pool.
    CloseHandle(nameArr);
    CloseHandle(weightArr);
    
    //Done!
    return true;
}

//Selects a random category based off of the supplied weights for the categories.
//    kv:       a mapcycle whose traversal stack is currently at the root level.
//    buffer:      a string to store the selected category in.
//    key:      the key containing the weight information (most likely 'group_weight')
//    excluded: adt_array of excluded maps
bool:GetWeightedRandomCat(Handle:kv, String:buffer[], size, String:key[],
                          Handle:excluded=INVALID_HANDLE, Handle:excludedCats=INVALID_HANDLE)
{
    //Fail if...
    //    ...there are no categories in the mapcycle.
    if (!KvGotoFirstSubKey(kv))
        return false;

    new index = 0; //counter of categories in the random pool
    new Handle:nameArr = CreateArray(255); //Array to store possible category names.
    new Handle:weightArr = CreateArray();  //Array to store possible category weights.
    
    //Add a category to the random pool.
    do
    {
        decl String:temp[255]; //Buffer to store the name of the category.
        
        //Get the name of the category.
        KvGetSectionName(kv, temp, sizeof(temp));
        
        //Skip this category if..
        //    ...the server doesn't have the required amount of players.
        if (!IsValidCat(kv, excludedCats, excluded))
            continue;
            
        //Add the category to the random pool.
        PushArrayCell(weightArr, KvGetFloat(kv, key, 1.0));
        PushArrayString(nameArr, temp);
        
        //One more category in the pool.
        index++;
    } while (KvGotoNextKey(kv)); //Do this for each category.s

    //Return to the root level.
    KvGoBack(kv);

    //Fail if...
    //    ...no categories are selectable.
    if (index == 0)
    {
        CloseHandle(nameArr);
        CloseHandle(weightArr);
        return false;
    }

    //Use weights to randomly select a category from the pool.
    GetWeightedRandomSubKey(buffer, size, weightArr, nameArr);
    
    //Close the pool.
    CloseHandle(nameArr);
    CloseHandle(weightArr);

    //Booyah!
    return true;
}


//************************************************************************************************//
//                                        VALIDITY TESTING                                        //
//************************************************************************************************//

//Checks to see if the server has the required number of players for the given map, and is in the
//required time range.
//    kv:       a mapcycle whose traversal stack is currently at the level of the map's category.
//    map:      the map to check
//    excluded: optional adt_array specifying maps to be excluded (if the map is in this array, it
//              is automatically considered to be invalid).
bool:IsValidMapFromCat(Handle:kv, const String:map[], Handle:excluded=INVALID_HANDLE)
{
    //Trie to store the default min/max player values (defined for the category).
    new Handle:defaults = CreateTrie();
    
    //Store the defaults.
    SetTrieValue(defaults, "min_players", KvGetNum(kv, "default_min_players", 0));
    SetTrieValue(defaults, "max_players", KvGetNum(kv, "default_max_players", MaxClients));
    SetTrieValue(defaults, "min_time", KvGetNum(kv, "default_min_time", 0));
    SetTrieValue(defaults, "max_time", KvGetNum(kv, "default_max_time", 2359));
    
    //Return that the map is not valid if...
    //    ...the map doesn't exist in the category.
    if (!KvJumpToKey(kv, map))
    {
        CloseHandle(defaults);
        return false;
    }
    
    //Determine if the map is valid, store the answer.
    new bool:result = IsValidMap(kv, defaults, excluded);
    
    //Rewind back to the category.
    KvGoBack(kv);
    
    //Close the defaults trie.
    CloseHandle(defaults);
    
    //Return the result.
    return result;
}


//Determines if the server has the required number of players for the given map.
//    kv:       a mapcycle whose traversal sack is currently at the level of the map.
//    defaults: a trie containing default min and max player values, to be used if the map doesn't
//              have them defined.
bool:IsValidMap(Handle:kv, Handle:defaults=INVALID_HANDLE, Handle:excluded=INVALID_HANDLE)
{
    //Get the current number of players.
    new numplayers = GetRealClientCount();
    
    //Storage variables.
    new minp, maxp, dminp, dmaxp;
    new mint, maxt, dmint, dmaxt;
    
    //Set the defaults if...
    //    ...the defaults trie wasn't supplied.
    if (defaults == INVALID_HANDLE)
    {
        dminp = 0;
        dmint = 0;
        dmaxp = MaxClients;
        dmaxt = 2359;
    }
    else //Otherwise grab them from the trie.
    {
        GetTrieValue(defaults, "min_players", dminp);
        GetTrieValue(defaults, "max_players", dmaxp);
        GetTrieValue(defaults, "min_time", dmint);
        GetTrieValue(defaults, "max_time", dmaxt);
    }
    
    //Get the min and max players from the map.
    minp = KvGetNum(kv, "min_players", dminp);
    maxp = KvGetNum(kv, "max_players", dmaxp);
    
    //Get the min and max time from the map.
    mint = KvGetNum(kv, "min_time", dmint);
    maxt = KvGetNum(kv, "max_time", dmaxt);
    
    //Get the name of the map
    decl String:mapName[255];
    KvGetSectionName(kv, mapName, sizeof(mapName));
    
    //Return true if the number of players is between the min and max for the map (inclusive)
    //     AND the time is between the allowable times for the map
    //     AND the map is not in the excluded array (if it exists).
    return numplayers >= minp && numplayers <= maxp 
        && IsTimeBetween(mint, maxt)
        && (excluded == INVALID_HANDLE || FindStringInArray(excluded, mapName) == -1);
}


//Determines if the server has the required number of players for the category that is to be
//randomly selected from and that at least one map isn't excluded.
//    kv: a mapcycle whose traversal stack is currently at the root level.
//    excludedCats: an adt_array containing cats to be excluded from being picked.
//    excluded: an adt_array containing maps to be excluded from being picked.
bool:CheckNextCatValidity(Handle:kv, Handle:excludedCats, Handle:excluded)
{
    //Return false instantly if the category is not set. Otherwise return the result of validity 
    //check
    return !StrEqual(next_rand_cat, "") 
        && CheckCatValidity(kv, next_rand_cat, excludedCats, excluded);
}


//Determines if the server has the required number of players for the given category.
//    kv:  a mapcycle whose traversal stack is currently at the root level..
//    cat: the string containing the category name.
//    excludedCats: an adt_array containing cats to be excluded from being picked.
//    excluded: an adt_array containing maps to be excluded from being picked.
bool:CheckCatValidity(Handle:kv, const String:cat[], Handle:excludedCats, Handle:excluded)
{
    //Jump to the level of the category.
    KvJumpToKey(kv, cat);
    
    //Determine if the number of players is valid for the category.
    new bool:result = IsValidCat(kv, excludedCats, excluded);
    
    //Return to the root.
    KvGoBack(kv);
    
    //Return our result.
    return result;
}


//Determines if the server has the required number of players for the given category and the
//required time.
//    kv: a mapcycle whose traversal stack is currently at the level of the category.
//    excludedCats: adt_array containing categories to be automatically considered invalid.
//    excludedMaps: adr_array containing maps to be automatically considered invalid.
bool:IsValidCat(Handle:kv, Handle:excludedCats, Handle:excludedMaps)
{
    //Get the name of the cat.
    decl String:catName[255];
    KvGetSectionName(kv, catName, sizeof(catName));

    //Return false if...
    //  ...the category is in the excluded array.
    if (excludedCats != INVALID_HANDLE && FindStringInArray(excludedCats, catName) != -1)
        return false;

    //Setup a trie to contain the default values for the category.
    new Handle:defaults = CreateTrie();
    SetTrieValue(defaults, "min_players", KvGetNum(kv, "default_min_players", 0));
    SetTrieValue(defaults, "max_players", KvGetNum(kv, "default_max_players", MaxClients));
    SetTrieValue(defaults, "min_time", KvGetNum(kv, "default_min_time", 0));
    SetTrieValue(defaults, "max_time", KvGetNum(kv, "default_max_time", 2359));
    
    //Return that the map is invalid if...
    //    ...there are no maps to check.
    if (!KvGotoFirstSubKey(kv))
        return false;
    
    //Check to see if the server's player count satisfies the min/max conditions for a map in the
    //category.
    do
    {
        //Return to the category level of the mapcycle and return true if...
        //    ...a map was found to be satisfied by the server's player count.
        if (IsValidMap(kv, defaults, excludedMaps))
        {
            KvGoBack(kv);
            CloseHandle(defaults);
            return true;
        }
    } while(KvGotoNextKey(kv)); //Goto the next map in the category.

    //Return to the category level.
    KvGoBack(kv);
    
    //Close handle to defaults trie.
    CloseHandle(defaults);
    
    //No maps in the category can be played with the current amount of players on the server.
    return false;
}


//Counts the number of maps in the given category that are valid.
//  kv:     Mapcycle at the level of the category we're checking.
//  excludedMaps:   adt_array of maps to be considered invalid.
CountValidMapsFromCat(Handle:kv, Handle:excludedMaps)
{
    new result = 0;

    //Setup a trie to contain the default values for the category.
    new Handle:defaults = CreateTrie();
    SetTrieValue(defaults, "min_players", KvGetNum(kv, "default_min_players", 0));
    SetTrieValue(defaults, "max_players", KvGetNum(kv, "default_max_players", MaxClients));
    SetTrieValue(defaults, "min_time", KvGetNum(kv, "default_min_time", 0));
    SetTrieValue(defaults, "max_time", KvGetNum(kv, "default_max_time", 2359));
    
    //Return that the map is invalid if...
    //    ...there are no maps to check.
    if (!KvGotoFirstSubKey(kv))
        return false;
    
    //Check to see if the server's player count satisfies the min/max conditions for a map in the
    //category.
    do
    {
        if (IsValidMap(kv, defaults, excludedMaps))
            result++;    
    } while(KvGotoNextKey(kv)); //Goto the next map in the category.

    //Return to the category level.
    KvGoBack(kv);
    
    //Close handle to defaults trie.
    CloseHandle(defaults);
    
    return result;
}


//************************************************************************************************//
//                                          PLAYER LIMITS                                         //
//************************************************************************************************//

//Creates the timer to check for when the amount of players is within the min and max bounds.
MakePlayerLimitCheckTimer()
{
    //We are currently not checking for valid player amounts.
    validity_enabled = false;
    
    //Get the timer delay
    new Float:delay = GetConVarFloat(cvar_invalid_delay);
    
    LogMessage("PLAYERLIMITS: Server will begin watching for inproper number of players in %.f seconds.",
        delay);
    
    //Create the timer.
    CreateTimer(
        delay,
        Handle_PlayerLimitTimer,
        INVALID_HANDLE,
        TIMER_FLAG_NO_MAPCHANGE
    );
}


//Callback for the min and max player check timer. Once the timer ends, we begin testing for valid
//amounts of players.
public Action:Handle_PlayerLimitTimer(Handle:Timer)
{
    //We are now checking for valid player amounts.
    validity_enabled = true;
    
    LogMessage("PLAYERLIMITS: Server is now watching for inproper number of players.");
    
    //Check player limits now.
    RunPlayerLimitCheck();
}


//Checks to see if the amount of players on the server is withing the required bounds set by the
//map. Changes to a map that does satisfy the requirement if this map doesn't.
RunPlayerLimitCheck()
{
    //Get the number of players.
    new clientCount = GetRealClientCount();
        
    //Change the map if...
    //    ...the cvar to check for max players is enabled AND
    //    ...the number of players on the server is greater than the maximum set by the map.
    if (GetConVarInt(cvar_invalid_max) != 0 && clientCount > map_max_players)
    {
        LogMessage("PLAYERLIMITS: Number of clients above player threshold: %i clients, %i max",
            clientCount, map_max_players);
        if (GetConVarInt(cvar_invalid_max) != PLAYERLIMIT_ACTION_NOTHING)
        {
            PrintToChatAll("[UMC] %t", "Too Many Players", map_max_players);
            ChangeToValidMap(cvar_invalid_max);
        }
    }
    //Otherwise, change the map if...
    //    ...the cvar to check for min players is enabled AND
    //    ...the number of players on the server is less than the minimum required by the map.
    else if (GetConVarInt(cvar_invalid_min) != 0 && clientCount < map_min_players)
    {
        LogMessage("PLAYERLIMITS: Number of clients below player threshold: %i clients, %i min",
            clientCount, map_min_players);
        if (GetConVarInt(cvar_invalid_min) != PLAYERLIMIT_ACTION_NOTHING)
        {
            PrintToChatAll("[UMC] %t", "Not Enough Players", map_min_players);
            ChangeToValidMap(cvar_invalid_min);
        }
    }
}


//Handles changing to a map in the event the number of players on the server is outside of the 
//bounds defined by the map.
//    cvar:    the cvar defining what action to take in this event.
ChangeToValidMap(Handle:cvar)
{
    switch (GetConVarInt(cvar))
    {
        case PLAYERLIMIT_ACTION_NOW: //Pick a map and change to it.
        {
            //Log message
            LogMessage("PLAYERLIMITS: Changing to a map that can support %i players.",
                GetRealClientCount());
        
            //Pick a map.
            RandomNextMap(randnext_mem_arr, randnext_catmem_arr, GetConVarBool(cvar_ignoregweight));
            
            //Get the picked map.
            decl String:map[255];
            GetNextMap(map, sizeof(map));
            
            //Change to the picked map.
            SetupMapChange(GetConVarInt(cvar_invalid_post), map, "PLAYERLIMITS");
            
            //Disallow all voting.
            vote_completed = true;
        }
        case PLAYERLIMIT_ACTION_YESNO: //Pick a map and run yes/no vote.
        {
            LogMessage("PLAYERLIMITS: Picking a map that can support %i players.",
                GetRealClientCount());
            
            //Pick a map.
            RandomNextMap(randnext_mem_arr, randnext_catmem_arr, GetConVarBool(cvar_ignoregweight));
            
            //Get the picked map.
            decl String:map[255];
            GetNextMap(map, sizeof(map));
            
            LogMessage("PLAYERLIMITS: Perfoming YES/NO vote to change the map to '%s.'", map);
            
            //Run the yes/no vote if...
            //    ...there isn't already a vote in progress.
            if (!IsVoteInProgress())
            {
                //Initialize the menu.
                new Handle:menu = CreateMenu(Handle_VoteMenu);    //SET
                SetVoteResultCallback(menu, Handle_YesNoMapVote); //CALLBACKS

                //Set the title
                SetMenuTitle(menu, "%T", "Yes/No Menu Title", LANG_SERVER, map);
                
                //Add options
                decl String:yes[10], String:no[10];
                Format(yes, sizeof(yes), "%T", "Yes", LANG_SERVER);
                Format(no, sizeof(no), "%T", "No", LANG_SERVER);
                AddMenuItem(menu, map, yes);
                AddMenuItem(menu, "?no?", no);
                SetMenuExitButton(menu, false);
                
                //Display it.
                VoteMenuToAll(menu, GetConVarInt(cvar_vote_time));
                
                //Play the vote start sound if...
                //  ...the vote start sound is defined.
                if (strlen(vote_start_sound) > 0)
                    EmitSoundToAll(vote_start_sound);
            }
            else
                LogMessage("PLAYERLIMITS: Unable to start YES/NO vote, another vote is in progress.");
        }
        case PLAYERLIMIT_ACTION_VOTE: //Run a full mapvote.
        {
            LogMessage("PLAYERLIMITS: Performing map vote to change to a map that can support %i players.",
                GetRealClientCount());
        
            //Run the mapvote if...
            //    ...there isn't already a vote in progress.
            if (!IsVoteInProgress())
            {
                //Initialize the menu.
                new Handle:menu = BuildMapVoteMenu(Handle_PlayerMapVoteResults,
                                                   GetConVarBool(cvar_scramble),
                                                   false, true, vote_mem_arr, vote_catmem_arr);
                
                //Display a message.
                PrintToChatAll("[UMC] %t", "Starting Map Vote");
                
                //Display the menu.
                VoteMenuToAll(menu, GetConVarInt(cvar_vote_time));
                
                //Play the vote start sound if...
                //  ...the vote start sound is defined.
                if (strlen(vote_start_sound) > 0)
                    EmitSoundToAll(vote_start_sound);
            }
            else
                LogMessage("PLAYERLIMITS: Unable to start map vote, another vote is in progress.");
        }
    }
}


//Called at the end of a yes/no map vote.
public Handle_YesNoMapVote(Handle:menu, num_votes, num_clients, const client_info[][2], num_items,
                           const item_info[][2])
{
    //Play the vote completed sound if...
    //  ...the vote completed sound is defined.
    if (strlen(vote_end_sound) > 0)
        EmitSoundToAll(vote_end_sound);
    
    //Get the winning choice.
    new winner = 0;
    decl String:map[255];
    GetMenuItem(menu, item_info[winner][VOTEINFO_ITEM_INDEX], map, sizeof(map));
    
    //Change the map if...
    //    ...the answer wasn't No OR
    //    ...there was a tie.
    if (!StrEqual(map, "?no?")
        || (num_items > 1 
            && (item_info[0][VOTEINFO_ITEM_VOTES] == item_info[1][VOTEINFO_ITEM_VOTES])))
    {
        /*PrintToChatAll(
            "[UMC] Map voting has finished. Changing map to %s. (Received %.f%% of %i votes)",
            map,
            float(item_info[winner][VOTEINFO_ITEM_VOTES]) / float(num_votes) * 100,
            num_votes
        );*/
        PrintToChatAll(
            "[UMC] %t %t (%t)",
            "End of Map Vote Over",
            "RTV Map Won",
                map,
            "Vote Win Percentage",
                float(item_info[winner][VOTEINFO_ITEM_VOTES]) / float(num_votes) * 100,
                num_votes
        );
        
        //Change it.
        SetupMapChange(GetConVarInt(cvar_invalid_post), map, "PLAYERLIMITS");

        //No more voting today.
        vote_completed = true;
    }
    else //Otherwise, just display the result.
    {
        /*PrintToChatAll(
            "[UMC] Map voting has finished. The map will not be changed. (Received %.f%% of %i votes)",
            float(item_info[winner][VOTEINFO_ITEM_VOTES]) / float(num_votes) * 100,
            num_votes
        );*/
        PrintToChatAll(
            "[UMC] %t %t (%t)",
            "End of Map Vote Over",
            "Map Unchanged",
            "Vote Win Percentage",
                float(item_info[winner][VOTEINFO_ITEM_VOTES]) / float(num_votes) * 100,
                num_votes
        );
    }
}


//Called at the end of a map vote for invalid number of players on the current map.
public Handle_PlayerMapVoteResults(Handle:menu, num_votes, num_clients, const client_info[][2],
                                   num_items, const item_info[][2])
{
    //Play the vote completed sound if...
    //  ...the vote completed sound is defined.
    if (strlen(vote_end_sound) > 0)
        EmitSoundToAll(vote_end_sound);

    //Get the winning map.
    new winner = GetWinner(num_items, item_info);
    decl String:map[255];
    GetMenuItem(menu, item_info[winner][VOTEINFO_ITEM_INDEX], map, sizeof(map));
    
    //Change the map if...
    //    ...the winning option was not Don't Change.
    if (!StrEqual(map, "?no?"))
    {
        /*PrintToChatAll(
            "[UMC] Map voting has finished. Changing map to %s. (Received %.f%% of %i votes)",
            map,
            float(item_info[winner][VOTEINFO_ITEM_VOTES]) / float(num_votes) * 100,
            num_votes
        );*/
        PrintToChatAll(
            "[UMC] %t %t (%t)",
            "End of Map Vote Over",
            "RTV Map Won",
                map,
            "Vote Win Percentage",
                float(item_info[winner][VOTEINFO_ITEM_VOTES]) / float(num_votes) * 100,
                num_votes
        );
        
        //Grab the index in the vote array.
        new index = FindStringInArray(map_vote, map);
        
        //Fetch the remaining map data.
        GetArrayString(map_vote_next_cats, index, next_rand_cat, sizeof(next_rand_cat));
        GetArrayString(map_vote_cats, index, next_cat, sizeof(next_cat));
        GetArrayString(map_vote_cat_configs, index, cat_config, sizeof(cat_config));
        GetArrayString(map_vote_map_configs, index, map_config, sizeof(map_config));
        
        //Change it.
        SetupMapChange(GetConVarInt(cvar_invalid_post), map, "PLAYERLIMITS");

        //We're done here.
        vote_completed = true;
    }
    else //Otherwise, just display the result.
    {
        /*PrintToChatAll(
            "[UMC] Map voting has finished. The map will not be changed. (Received %.f%% of %i votes)",
            float(item_info[winner][VOTEINFO_ITEM_VOTES]) / float(num_votes) * 100,
            num_votes
        );*/
        PrintToChatAll(
            "[UMC] %t %t (%t)",
            "End of Map Vote Over",
            "Map Unchanged",
            "Vote Win Percentage",
                float(item_info[winner][VOTEINFO_ITEM_VOTES]) / float(num_votes) * 100,
                num_votes
        );
    }
}


//************************************************************************************************//
//                                           NOMINATIONS                                          //
//************************************************************************************************//

//Displays a nomination menu to the given client.
DisplayNominationMenu(client)
{
    LogMessage("NOMINATIONS: %N wants to nominate a map.", client);

    //Build the menu
    new Handle:menu = BuildNominationMenu(client);
    
    //Display the menu if...
    //    ..the menu was built successfully.
    if (menu != INVALID_HANDLE)
    {
        DisplayMenu(menu, client, 20);
    }
}


//Creates and returns the Nomination menu for the given client.
Handle:BuildNominationMenu(client)
{
    //Fail and return nothing if...
    //    ...the mapcycle is invalid.
    if (map_kv == INVALID_HANDLE)
    {
        LogError("NOMINATIONS: Cannot generate nominations menu, rotation file is invalid.");
        return INVALID_HANDLE;
    }
    
    //Initialize the menu
    new Handle:menu = CreateMenu(Handle_NominationMenu);
    
    //Set the title.
    SetMenuTitle(menu, "%T", "Nomination Menu Title", LANG_SERVER);
    
    //Rewind the mapcycle.
    KvRewind(map_kv);
    
    //Fail and return nothing if...
    //    ...no categories were found.
    if (!KvGotoFirstSubKey(map_kv))
    {
        LogError("NOMINATIONS: Nomination menu not built, no map groups found in rotation.");
        CloseHandle(menu);
        return INVALID_HANDLE;
    }

    //Get the current map.
    decl String:currentMap[255];
    GetCurrentMap(currentMap, sizeof(currentMap));

    //Variables
    nomination_cats[client] = CreateArray(255); //Array to store categories for each nomination
    nomination_weights[client] = CreateArray(); //Array to store weights for each nomination
    new Handle:menuItems = CreateArray(255);    //Array to store each nominated map
    decl String:mapName[255];     //Temporary buffer for each map name.
    decl String:catName[255];   //Temporary buffer for each category name.
    new counter = 0;    //Counts number of nominations added to the menu.
    //new Handle:nominationsFromCat = INVALID_HANDLE;    //Array to store nominations from a category.
    //new size = 0; //Amount of nominations from a category.
    
    //Add maps from a category to the nominated maps array.
    do
    {
        //Get the name of the current category.
        KvGetSectionName(map_kv, catName, sizeof(catName));
        
        /*
        //Get all nominations in this category.
        nominationsFromCat = FilterNominations("cat", catName);
        
        //Store the number of nominations in this category.
        size = GetArraySize(nominationsFromCat);
        
        //We no longer need the entire array.
        CloseHandle(nominationsFromCat);
        */
        
        //Skip this category if...
        //    ...there are no maps found in the category.
        if (/*KvGetNum(map_kv, "maps_invote", 1) - size <= 0 ||*/ !KvGotoFirstSubKey(map_kv))
            continue;
        
        //Add a map to the nominated maps array.
        do
        {
            //Get the name of the current map.
            KvGetSectionName(map_kv, mapName, sizeof(mapName));
            
            //Add the map to the nominated maps array if...
            //    ...the map is not the current map AND
            //    ...the map isn't already in the array AND
            //    ...the map hasn't already been nominated.
            if (!StrEqual(mapName, currentMap) && FindStringInArray(menuItems, mapName) == -1 
                && FindNominationIndex(mapName) == -1)
            {
                //Add map data to the arrays.
                PushArrayString(menuItems, mapName);
                PushArrayString(nomination_cats[client], catName);
                PushArrayCell(nomination_weights[client], KvGetNum(map_kv, "weight", 1));
                
                //One more map in the menu.
                counter++;
            }
        } while (KvGotoNextKey(map_kv)); //Do this for each map in the category.
        
        //Rewind to the category level.
        KvGoBack(map_kv);
    
    } while (KvGotoNextKey(map_kv)); //Do this for each category in the mapcycle.
    
    //Add all maps from the nominations array to the menu.
    AddArrayToMenu(menu, menuItems);
    
    //No longer need the array.
    CloseHandle(menuItems);

    //Log an error and return nothing if...
    //    ...the number of maps available to be nominated
    if (counter < 1)
    {
        LogError("NOMINATIONS: No maps available to be nominated.");
        CloseHandle(menu);
        CloseHandle(nomination_cats[client]);
        CloseHandle(nomination_weights[client]);
        return INVALID_HANDLE;
    }

    //Success!
    return menu;
}


//Called when the client has picked an item in the nomination menu.
public Handle_NominationMenu(Handle:menu, MenuAction:action, client, param2)
{
    switch (action)
    {
        case MenuAction_Select: //The client has picked something.
        {
            //Get the selected map.
            decl String:map[255];
            GetMenuItem(menu, param2, map, sizeof(map));
            
            //Create the nomination trie.
            new Handle:nomination = CreateTrie();
            SetTrieValue(nomination, "client", client); //Add the client
            SetTrieString(nomination, "map", map);        //Add the map
            
            //Get the category for the nominated map.
            decl String:cat[255];
            GetArrayString(nomination_cats[client], param2, cat, sizeof(cat));
            
            //Add it to the nomination trie.
            SetTrieString(nomination, "cat", cat);
            
            //Get and add the nominated map's weight.
            SetTrieValue(nomination, "weight", GetArrayCell(nomination_weights[client], param2));
            PushArrayCell(nominations_arr, nomination);
            
            //Display a message.
            decl String:clientName[MAX_NAME_LENGTH];
            GetClientName(client, clientName, sizeof(clientName));
            PrintToChatAll("[UMC] %t", "Player Nomination", clientName, map);
            LogMessage("NOMINATIONS: %s has nominated '%s' from group '%s.'", clientName, map, cat);
            
            //Close handles for stored data for the client's menu.
            CloseHandle(nomination_cats[client]);
            CloseHandle(nomination_weights[client]);
        }
        case MenuAction_End: //The client has closed the menu.
        {
            //We're done here.
            CloseHandle(menu);
        }
    }
}


//Returns the index of the given client in the nomination pool. -1 is returned if the client isn't
//in the pool.
FindClientNomination(client)
{
    new buffer;
    new arraySize = GetArraySize(nominations_arr);
    for (new i = 0; i < arraySize; i++)
    {
        GetTrieValue(GetArrayCell(nominations_arr, i), "client", buffer);
        if (buffer == client)
            return i;
    }
    return -1;
}


//Utility function to find the index of a map in the nomination pool.
FindNominationIndex(const String:map[])
{
    decl String:temp[255];
    new arraySize = GetArraySize(nominations_arr);
    for (new i = 0; i < arraySize; i++)
    {
        GetTrieString(GetArrayCell(nominations_arr, i), "map", temp, sizeof(temp));
        if (StrEqual(temp, map))
            return i;
    }
    return -1;
}


//Utility function to filter out nominations whose value for the given key matches the given value.
Handle:FilterNominations(const String:key[], const String:value[])
{
    new Handle:result = CreateArray();
    new Handle:buffer;
    decl String:temp[255];
    new arraySize = GetArraySize(nominations_arr);
    for (new i = 0; i < arraySize; i++)
    {
        buffer = GetArrayCell(nominations_arr, i);
        GetTrieString(GetArrayCell(nominations_arr, i), key, temp, sizeof(temp));
        if (StrEqual(temp, value))
            PushArrayCell(result, buffer);
    }
    return result;
}


//************************************************************************************************//
//                                        GENERAL UTILITIES                                       //
//************************************************************************************************//

//Utility function to get a KeyValues Handle from a filename, with the specified root key.
Handle:GetKvFromFile(const String:filename[], const String:rootKey[])
{
    new Handle:kv = CreateKeyValues(rootKey);
    
    //Log an error and return empty handle if...
    //    ...the kv file fails to parse.
    if (!FileToKeyValues(kv, filename))
    {
        LogError("KV ERROR: Unable to load KV file: %s", filename);
        return INVALID_HANDLE;
    }
    
    //Log success message and return handle.
    LogMessage("SETUP: KV file \"%s\" successfully loaded.", filename);
    return kv;
}


//Utility function to jump to a specific map in a mapcycle.
//  kv: Mapcycle Keyvalues that must be at the root value.
bool:KvJumpToMap(Handle:kv, const String:map[])
{
    if (!KvGotoFirstSubKey(kv))
        return false;
        
    decl String:mapName[255];
    
    do
    {
        if (!KvGotoFirstSubKey(kv))
            continue;
        do
        {
            KvGetSectionName(kv, mapName, sizeof(mapName));
            if (StrEqual(mapName, map))
                return true;
        } while (KvGotoNextKey(kv));
        
        KvGoBack(kv);
    } while (KvGotoNextKey(kv));
    
    KvGoBack(kv);
    return false;
}


//Sets all elements of an array of booleans to false.
ResetArray(bool:arr[], size)
{
    for (new i = 0; i < size; i++)
        arr[i] = false;
}


//Deletes values off the beginning of an array until it is down to the given size.
TrimArray(Handle:arr, size)
{
    //Remove elements from the start of an array while...
    //    ...the size of the array is greater than the required size.
    while (GetArraySize(arr) > size)
        RemoveFromArray(arr, 0);
}


//Utility function to cache a sound.
CacheSound(const String:sound[])
{
    //Handle the sound if...
    //  ...it is defined.
    if (strlen(sound) > 0)
    {
        //Filepath buffer
        decl String:filePath[PLATFORM_MAX_PATH];
    
        //Format sound to the correct directory.
        Format(filePath, sizeof(filePath), "sound/%s", sound);
        
        //Log an error and don't cache the sound if...
        //    ...the sound file does not exist
        if (!FileExists(filePath))
            LogError("SOUND ERROR: Sound file '%s' does not exist.", filePath);
        //Otherwise, cache the sound.
        else
        {
            //Make sure clients download the sound if they don't have it.
            AddFileToDownloadsTable(filePath);
            
            //Cache it.
            PrecacheSound(sound, true);
            
            //Log an error if...
            //    ...the sound failed to be cached.
            if (!IsSoundPrecached(filePath))
                LogError("SOUND ERROR: Failed to precache sound file '%s.'", sound);
        }
    }
}


//Fetch the next index of the menu.
//    size: the size of the menu
//    scramble: whether or not a random index should be picked.
GetNextMenuIndex(size, bool:scramble)
{
    return scramble ? GetRandomInt(0, size) : size;
}


//Inserts given string into given array at given index.
InsertArrayString(Handle:arr, index, const String:value[])
{
    if (GetArraySize(arr) > index)
    {
        ShiftArrayUp(arr, index);
        SetArrayString(arr, index, value);
    }
    else
        PushArrayString(arr, value);
}


//Adds entire array to the given menu.
AddArrayToMenu(Handle:menu, Handle:arr)
{
    decl String:map[255];
    new arraySize = GetArraySize(arr);
    for (new i = 0; i < arraySize; i++)
    {
        GetArrayString(arr, i, map, sizeof(map));
        AddMenuItem(menu, map, map);
    }
}


//Function to check the entity limit. Used before spawning an entity.
#tryinclude <entlimit>
#if !defined _entlimit_included
stock IsEntLimitReached(warn=20, critical=16, client=0, const String:message[]="")
{
    new max = GetMaxEntities();
    new count = GetEntityCount();
    new remaining = max - count;
    if (remaining <= warn)
    {
        if (count <= critical)
        {
            PrintToServer("Warning: Entity limit is nearly reached! Please switch or reload the map!");
            LogError("VOTEWARNINGS: Entity limit is nearly reached: %d/%d (%d):%s", 
                count, max, remaining, message);
    
            if (client > 0)
            {
                PrintToConsole(client, "Entity limit is nearly reached: %d/%d (%d):%s",
                       count, max, remaining, message);
            }
        }
        else
        {
            PrintToServer("Caution: Entity count is getting high!");
            LogMessage("VOTEWARNINGS: Entity count is getting high: %d/%d (%d):%s",
                count, max, remaining, message);
    
            if (client > 0)
            {
                PrintToConsole(client, "Entity count is getting high: %d/%d (%d):%s",
                       count, max, remaining, message);
            }
        }
        return count;
    }
    else
        return 0;
}
#endif


//Changes the map in 5 seconds.
ForceChangeInFive(const String:map[], const String:reason[])
{
    //Notify the server.
    PrintToChatAll("[UMC] %t", "Map Change in 5");
    
    //Setup the change.
    ForceChangeMap(map, 5.0, reason);
}


//Changes the map after the specified time period.
ForceChangeMap(const String:map[], Float:time, const String:reason[]="")
{
    LogMessage("%s: Changing map to '%s' in %.f seconds.", reason, map, time);

    //Setup the timer.
    new Handle:pack;
    CreateDataTimer(
        time,
        Handle_MapChangeTimer,
        pack,
        TIMER_FLAG_NO_MAPCHANGE
    );
    WritePackString(pack, map);
    WritePackString(pack, reason);
}


//Called after the mapchange timer is completed.
public Action:Handle_MapChangeTimer(Handle:timer, Handle:pack)
{
    //Get map from the timer's pack.
    decl String:map[255], String:reason[255];
    ResetPack(pack);
    ReadPackString(pack, map, sizeof(map));
    ReadPackString(pack, reason, sizeof(reason));
    
    //Change the map.
    ForceChangeLevel(map, reason);
}


//Changes the map based off of the given action.
SetupMapChange(action, const String:map[], const String:reason[]="")
{
    switch (action)
    {
        case CHANGE_MAP_ACTION_NOW: //We change the map in 5 seconds.
            ForceChangeInFive(map, reason);
        case CHANGE_MAP_ACTION_ROUNDEND: //We change the map at the end of the round.
        {
            LogMessage("%s: Map will change to '%s' at the end of the round.", reason, map);
        
            //We don't want to update our stored values for the limit cvars.
            catch_change = true;
            
            //Limit the remaining rounds to 1.
            SetConVarInt(cvar_maxrounds, 1);
            
            //Now we can track changes again.
            catch_change = false;
            
            //Get the next map.
            decl String:nmap[255];
            GetNextMap(nmap, sizeof(nmap));
            
            //Set the map to be the next map played.
            if (!StrEqual(map, nmap))
                SetTheNextMap(map);
            
            //Print a message.
            PrintToChatAll("[UMC] %t", "Map Change at Round End");
        }
        case CHANGE_MAP_ACTION_MAPEND: //We set the map as the next map.
        {
            //Get the currently set next map.
            decl String:curMap[255];
            GetNextMap(curMap, sizeof(curMap));
            
            //Set the voted map as the next map if...
            //    ...that map isn't already set as the next map.
            if (!StrEqual(curMap, map))
                SetTheNextMap(map);
        }
    }
}


//Determines if the current server time is between the given min and max.
bool:IsTimeBetween(min, max)
{
    //Get the current server time.
    decl String:time[5];
    FormatTime(time, sizeof(time), "%H%M");
    new theTime = StringToInt(time);
    
    //Handle wrap-around case if...
    //  ...max time is less than min time.
    if (max <= min)
        max += 2400;
    
    //Return true if the server time is between the given max and min.
    return min <= theTime && theTime <= max;
}


//Converts an adt_array to a standard array.
ConvertArray(Handle:arr, any:newArr[], size)
{
    new arraySize = GetArraySize(arr);
    for (new i = 0; i < size && i < arraySize; i++)
        newArr[i] = GetArrayCell(arr, i);
}


//Selects one random name from the given name array, using the weights in the supplies weight array.
//Stores the result in buffer.
GetWeightedRandomSubKey(String:buffer[], size, Handle:weightArr, Handle:nameArr)
{
    //Calc total number of maps we're choosing.
    new total = GetArraySize(weightArr);
    
    //Return an answer immediately if...
    //    ...there's only one map to choose from.
    if (total == 1)
    {    
        //WE HAVE A WINNER!
        GetArrayString(nameArr, 0, buffer, size);
        return;
    }
    //Otherwise, we immediately do nothing and return, if...
    //    ...there are no maps to choose from.
    else if (total == 0)
        return;

    //Convert the adt_array of weights to a normal array.
    new Float:weights[total];
    ConvertArray(weightArr, weights, total);

    //We select a random number here by getting a random Float in the
    //range [0, 1), and then multiply it by the sum of the weights, to
    //make the effective range [0, totalweight).
    new Float:rand = GetURandomFloat() * ArraySum(weights, total);
    new Float:runningTotal = 0.0; //keeps track of total so far
    
    //Determine if a map is the winner for...
    //    ...each map in the arrays.
    for (new i = 0; i < total; i++)
    {
        //add weight onto the total
        runningTotal += weights[i];
        
        //We have found an answer if...
        //    ...the running total has reached the random number.
        if (runningTotal > rand)
        {
            GetArrayString(nameArr, i, buffer, size);
            break;
        }
    }
}


//Utility function to sum up an array of floats.
Float:ArraySum(const Float:floats[], size)
{
    new Float:result = 0.0;
    for (new i = 0; i < size; i++)
        result += floats[i];
    return result;
}


//Utility function to set the next map.
SetTheNextMap(const String:mapName[])
{
    LogMessage("Setting nextmap to: %s", mapName);
    SetNextMap(mapName);
}


//Adds the given map to the given memory array.
//    mapName: the name of the map
//    arr:     the memory array we're adding to
//    size:    the maximum size of the memory array
AddToMemoryArray(const String:mapName[], Handle:arr, size)
{
    //Add the new map to the beginning of the array.
    PushArrayString(arr, mapName);
    
    //Trim the array down to size.
    TrimArray(arr, size);
}


//Print the next map to chat.
PrintNextMap()
{
    decl String:map[255];
    GetNextMap(map, sizeof(map));
    PrintToChatAll("[UMC] %t", "Next Map", map);
}


//Utility function to clear an array of Handles and close each Handle.
ClearHandleArray(Handle:arr)
{
    new arraySize = GetArraySize(arr);
    for (new i = 0; i < arraySize; i++)
        CloseHandle(GetArrayCell(arr, i));
    ClearArray(arr);
}


//Utility function to get the true count of active clients on the server.
GetRealClientCount(bool:inGameOnly=true)
{
    new clients = 0;
    for (new i = 1; i <= MaxClients; i++)
    {
        if ((inGameOnly ? IsClientInGame(i) : IsClientConnected(i)) && !IsFakeClient(i))
            clients++;
    }
    return clients;
}


//Utility function to fetch the highest score on the server.
GetHighestScore()
{
    new score = 0;
    new temp;
    for (new i = 1; i <= MaxClients; i++)
    {
        temp = GetClientFrags(i);
        if (temp > score)
            score = temp;
    }
    return score;
}


//FUCK YEAH EOF