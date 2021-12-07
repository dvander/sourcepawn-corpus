/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                   ULTIMATE MAPCHOOSER CORE                                    *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
 
#pragma semicolon 1

#define RUNTESTS 0

//Dependencies
#include <umc-core>
#include <umc_utils>
#include <sourcemod>
#include <sdktools_sound>

#undef REQUIRE_PLUGIN

//Auto update
#include <updater>
#define UPDATE_URL "www.ccs.neu.edu/home/steell/sourcemod/ultimate-mapchooser/updateinfo-umc-core.txt"

//Some definitions
#define DONT_CHANGE_OPTION "?DontChange?"
#define EXTEND_MAP_OPTION "?Extend?"
#define NOTHING_OPTION "?nothing?"
#define WEIGHT_KEY "##calculated-weight##"

//Plugin Information
public Plugin:myinfo =
{
    name        = "[UMC] Ultimate Mapchooser Core",
    author      = "Steell",
    description = "Core component for [UMC]",
    version     = PL_VERSION,
    url         = "http://forums.alliedmods.net/showthread.php?t=134190"
};

//Changelog:
/*
3.2.4 (10/12/11)
Added Auto Updating support.
Added new feature to the End of Map Vote module that delays a vote for a certain amount of time after it is triggered due to a round ending.
-New cvar "roundend_delaystart" to control this feature.
Fixed bug in Player Count Monitoring where an incorrect translation phrase was breaking Yes/No votes.

3.2.3 (9/17/11)
Updated Map Rate Map-Reweighting module to conform with the new Map Rate RELOADED cvars.
Fixed issue in TF2 where maps ending due to the mp_winlimit cvar would not trigger Random Mapcycle map selection.
Fixed issue with Tiered Votes where "Extend" and "Don't Change" options were not properly handled.

3.2.2 (8/11/11)
Added new Post-Played Exclusion module, giving the ability to specify a period of time after a map is played that it should be excluded. (Thanks Sazpaimon!)
Fixed bug which caused runoff votes to fail immediately when maximum amount of runoffs is set to 0 (infinite).
Fixed issue with invalid translation phrase in the ADMINMENU module.
Fixed issue with portugese translation.
Fixed issue where the option to change the map immediately was not working in Player Count Monitor.
Fixed issue with translation phrase which caused max player threshold to not trigger. PLAYERCOUNTMONITOR

3.2.1 (7/4/11)
Fixed issue where previously played groups were not being removed from the mapcycle.
Optimized vote menu population.

3.2 (7/2/11)
Modified previous exclusion so that it is performed at the start of the map.
Fixed issue where tiered votes would not work correctly when started via the admin menu and exlusion is ignored.
Changed previous-map exclusion so it doesn't automatically exclude the current map. If cvar is set to 0, the current map will not be excluded.

3.1.2 (6/24/11)
Disabled Prefix Exclusion by default.
Fixed issue with Map Votes not starting when there are no nominations.
Fixed issues where cancelled votes could cause memory leaks.

3.1.1 (6/23/11)
Fixed translation typo in Admin Menu
Fixed translation bug in Admin Menu
Fixed issue where admin flags would sometimes cause votes not to appear.
Fixed bug in the Admin Menu where Stopping an active vote would do nothing.

3.1 (6/22/11)
Added new map option to associate a nomination with a different group.
-New "nominate_group" option at the map-level of the mapcycle definition.
Added admin flag for ability to see vote menu.
-New "adminflags" cvar in ADMINMENU, ENDVOTE, PLAYERCOUNTMONITOR, ROCKTHEVOTE, and VOTECOMMAND.
Added admin flag for ability to enter rtv. [RTV]
-New "enteradminflags" cvar in RTV.
Added ability to specify flags for maps, limiting which players can nominate them.
-New group and map option in mapcycle "nominate_flags" to specify flags.
-New cvar "adminflags" in NOMINATE to set default.
Added ability to specify flags for maps, limiting which admins can select them in the admin menu.
-New group and map option in mapcycle "adminmenu_flags" to specify flags.
Added admin flags for admins who can ignore map exclusion in the admin menu.
-New cvar "sm_umc_am_adminflags_exclude" to control this feature.
Added admin flags for admins who can override default settings in the admin menu.
-New cvar "sm_umc_am_adminflags_defaults" to control this feature.
Added mp_winlimit-based vote warnings. [ENDVOTE-WARNINGS]
Turned basic time-based vote warnings on by default.
Added ability for sound to be played during countdown between Runoff/Tiered votes. [CORE]
-New "sm_umc_countdown_sound" cvar to specify the sound.
Added ability to specify a default weight for maps that do not have enough Map Rate ratings. [MAPRATE-REWEIGHT]
-New "sm_umc_maprate_default" cvar to control this feature.
Fixed bug with nominations not using group exclusion settings.
Fixed bug with nominations not passing their own mapcycle to forwards.
Fixed bug with tiered nomination menu excluding groups unnecessarily.
Fixed memory leak when parsing nominations for map group vote menus.
Fixed bug which could cause groups with no valid maps to be added to group votes.
Fixed bug in Prefix Exclusion which caused prefixes to be excluded even when the memory cvar was set to 0.

3.0.8 (6/11/11)
Fixed bug where sometimes only the first map group would be processed for map exclusions.

3.0.7 (6/10/11)
Changed default value for all threshold cvars to 0.
Added standard mapcycle feature; if given a special header, regular one-map-per-line mapcycles can be used with UMC.
Fixed bug that was causing "handle is invalid" error messages when runoff votes fail and thair failaction is set to consider the vote a success.
Fixed issues with Polish translation.
Modified exclusion algorithm when generating vote menus, should allow for nominations to be added to empty groups.
Heavily modified internal nomination system.
Fixed memory leak when mapcycle files can not be found.

3.0.6 (6/7/11)
Changed minimum value of the sm_umc_maprate_expscale cvar to 0. [MAPRATE-REWEIGHT]
Fixed bug in Player Count Monitoring where it couldn't auto-detect the current group. [PLAYERCOUNTMONITOR]
Fixed bug where errors could be caused by group exclusion code.
Heavily optimized debugging system, should result in execution speedup.
Optimized umc-maprate-reweight to fetch map weights in O(1) as opposed to O(n)
Added more debug messages.

3.0.5 (5/29/11)
Fixed bug where individual clients cancelling a vote menu could break tiered and group votes.

3.0.4 (5/28/11)
Added experimental admin menu module. [ADMINMENU]
Fixed rare bug with tiered nomination menus displaying groups with no maps in it. [NOMINATIONS]
Fixed bug where error log would be spammed with KillTimer errors (finally). [ENDVOTE]
Fixed bug where endvotes would not work in games without certain cvars. [ENDVOTE]
Made map weights of 0 automatically exclude maps from selection. [WEIGHT]
Updated various documentation.
Minor Optimizations.

3.0.3 (5/23/11)
Added ability to specify amount of times a prefix can be in the previously played prefixes before it is excluded.
-New cvar "sm_umc_prefixexclude_amount" in umc-prefixexclude to control this feature.
Fixed bug where endvotes would not appear after a map was extended. [ENDVOTE]

3.0.2 (5/22/11)
Fixed bug with previously played map exclusion in second stage tiered vote.
Fixed bug where nominated maps were not being excluded from votes properly.
Fixed bug where group votes would pick a random map group to be the next map.
Optimized map weight system so each map is only weighted once.
Made modules with previous map exclusions search for the current group if core reports it as INVALID_GROUP.
Added ability to specify a scale for umc-maprate-reweight
-New cvar "sm_umc_maprate_expscale" in umc-maprate-reweight to control this feature.
Added ability to make all votes use valve-syle menus (users press ESC to vote).
-New cvar "sm_umc_menu_esc" in umc-core to control this feature.
Made center message in umc-echonextmap last for at least 3 seconds.
Sequences of warnings can now be defined using a dash (-) as well as an elipses (...).
Added new Map Prefix Exclusion module (umc-prefixexclude).

3.0.1 (5/18/11)
Added extra argument to sm_setnextmap that specifies when the map will be changed.
Added response to the reload mapcycles command.
Fixed bug with map exclusion in tiered votes.

3.0 (5/16/11)
Near-complete rewrite of UMC. Divided up plugin into separate modules which operate independently. These modules are linked together through UMC's Core (this file).
Fixed many, many bugs with the rewrite. I will only be listing the ones I know have been fixed.
Fixed bug with Tiered Votes sometimes not displaying the second vote due to an invalid mapcycle.
Fixed bug with Map Group Exclusion not working correctly.
Fixed bug with Map Exclusion sometimes not working correctly.
Implemented support for "mp_winlimit" triggered end of map votes.
When UMC sets the next map, it can now be displayed in Center and Hint messages.
-New "sm_umc_echonextmap_hint" and "sm_umc_echonextmap_center" cvars to control this ability.
Added "next_mapgroup" to maps in the definitions, not just the groups anymore.
Added ability to delay end of map votes so they will only appear at the end of rounds.
-New "sm_umc_endvote_delayroundend" cvar to control this ability.
Added command to display how maprate-reweight will be reweighting maps.
Implemented developer's API, but it is not yet fully supported (in case I decide I need to make changes).
Probably more, I really should have kept track.

2.5.1 (5/5/11)
Added color to the [UMC] prefix in say messages.
Added German translation (thanks Leitwolf!)
Added Polish translation (thanks Arcy!)
Fixed minor issue with Random Selection of the Next Map not excluding maps correctly.
Fixed minor issue with Player Limits that was generating errors.
Fixed issue with "next_mapgroup" where it didn't properly check for excluded maps.
Fixed bug with max runoff votes not working as intended.
Implemented pre-command.

2.5 (4/3/11)
Added new feature: you can specify a maximum number of maps to appear in runoff votes.
-New "sm_umc_runoff_max" cvar to control this ability.
Players are now allowed to change their nomination.
Fixed bug where the map group configuration is not set properly.
Fixed tiered nomination menu where groups with no maps were still displayed.
Fixed bug where the sm_umc_mapvote command would change to an invalid map if nobody voted.
Added prevention code for various errors, not sure if it will fix them since I can't reproduce them.
Optimized memory usage in adt_arrays with Strings.
Added placeholders for "pre-command" support.

2.4.6 (3/25/11)
Fixed bug where having the same map in one group could cause a crash.
Fixed errors where delays between votes (runoff and tiered) could cause errors if the map ends during them.
Added dynamic reweight system, allowing other plugins to affect the weight of maps in UMC.

2.4.5 (3/20/11)
Disabled exit button on runoff votes.
Made runoff votes use proper pagination (< 9 options = no pagination [Radio Style Menus only])

2.4.4 (3/18/11)
Fixed issue where an extension could cause multiple votes.

2.4.3 (3/16/11)
Fixed issue with second stage tiered votes not limiting maps to the winning map group.

2.4.2 (3/9/11)
Modified sm_umc_mapvote command to take an argument specifying when to change the map after the vote.
Fixed issue with excluding previously played maps.
Fixed issue with random selection of the next map excluding previously played maps.

2.4.1 (3/7/11)
Fixed bug that caused runoff votes to never have a maximum.
Fixed bug that prevented some runoff votes from working correctly.

2.4 (3/7/11)
Made delay between votes (tiered and runoff) countdown to zero as opposed to one.
Fixed bug that disabled RTVs and Random Selection of the Next Map if a vote occurs and there are no votes.
Fixed bug with auto-pagination that broke votes with 8 or 9 items in HL2DM (and other mods that don't support Radio menus).

2.3.4-beta3 (3/6/11)
Made nomination menu not display maps from a map group if the strict cvar is on and enough maps have already been nominated to satisfy the maps_invote setting.
Fixed selective runoff votes so they take into account previous votes (from before the runoff).

2.3.4-beta2 (3/3/11)
Added ability for map votes to allow duplicate maps. This is useful for people running votes where the same map may appear for different mods.
-New sm_umc_vote_allowduplicates cvar to control this ability
Added ability to filter the nomination menu based off of what maps should be excluded at the time it's displayed.
-Removed sm_umc_nominate_timelimits cvar
-New sm_umc_nominate_displaylimits cvar to control this ability
Fixed cases where ignorelimits was not working.
Code refactoring

2.3.4-beta1 (3/2/11)
Fixed bug with Yes/No Playerlimit vote where a tie would result in garbage display.
Fixed bug where two RTVs could happen, one right after another, if enough people enter RTV during an RTV.
Made nomination menu not close automatically.
Fixed behavior of ignorelimits cvars and nominations.

2.3 (2/24/11)
Added client-side translations to all menus.
Added optional "display" option to map definitions, and "display-template" option to map group definitions.
Added ability to display nomination menu in tiers -- first select a group, then select a map.
-New cvar to control this feature.
Added ability to disable Map Exclusion for end-of-map votes, RTVs, random next map, and nominations.
-Four new cvars to control this feature.
Made all votes attempt to retry to initiate in the event they are blocked by a vote that is already running.
Added call to OnNominationRemoved forward in all appropriate places.
Modified nomination code in map group votes to not exclude the group if there were nominations for maps in it.
Fixed odd bug where a vote would display garbage if there was a map group with a cumulative weight of 0.

2.2.4 (2/21/11)
Fixed bug with center message warnings.
Fixed bug with runoff votes being populated with the wrong maps.
Fixed bug with runoff votes not paying attention to the threshold cvar.
Fixed bug with end of map vote timer that caused errors when the timelimit was changed.

2.2.3 (2/19/11)
Fixed bug that completely screwed up vote warnings.

2.2.2 (2/19/11)
Fixed bug that caused all time-based vote warnings to appear at 0 seconds.

2.2.1 (2/18/11)
Fixed problem with default min and max players for groups not being read correctly.

2.2 (2/18/11)
Added vote warnings support for frag and round limits.
-Removed sm_umc_endvote_warnings cvar
-Added three new cvars to control the feature: 1 each for time, frag, and round warnings.
Added mapchooser's "sm_setnextmap" command.
Changed required admin flag for commands from ADMFLAG_RCON to ADMFLAG_CHANGEMAP.
Added prevention measures from starting RTVs during delay between runoff and tiered votes.
Changed event hooks to act more like original mapchooser (may fix weird round_end bugs).
Fixed "nextmap" chat command functionality.
Fixed bug with end of map vote that prevented frag limit from triggering it.
Fixed bug that required mapchooser to be enabled.
Fixed rare memory leak with map exclusion algorithm for map groups with no maps defined.

2.1 (2/17/11)
Added support for mapchooser's natives.
Added customization for how runoff and tiered vote messages are displayed.
Fixed memory leak with nominations that are not added to votes.
Fixed memory leak with map exclusion algorithm.

2.0.2 (2/15/11)
Fied (another) obscure bug with Runoff Votes, this time preventing map change.

2.0.1 (2/14/11)
Fixed obscure bug with Runoff Votes that prevents a vote from starting.

2.0 (2/13/11)
Added new "command" option to map groups and maps defined in the mapcycle. The strings supplied will be executed at the start of the map.
Added some code optimizations.
Improved logging.
Added ability for plugin to search for a map's player limits if the map wasn't changed by the plugin.
Fixed bug with Tiered Votes where votes would fail if the winning group had only one available map.
Fixed bug with data not being cleared when a vote menu fails to be created.
Fixed bug with "rockthevote" chat triggers not working.
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

//TODO / IDEAS:
//	New "next_map" map command, works with "next_mapgroup".
//		-If next_map is set but next_mapgroup isn't, the current group is assumed.
//		-If next_map is not set but next_mapgroup is, then a map is selected at random from the group.
//		-If neither are set, a random map from a random group is selected.
//
//    ***Need to find a cleaner/clearer way to handle case where nominations are only used in certain modules.
//        -Solution 1: new "display-group" option that mimicks the "display" option for maps (but this is for groups).
//        -Solution 2: implement mapcycle-level options (to complement group and map options).
//  Take nominations into account when selecting a random map.
//  Add cvar to control where nominations are placed in the vote (on top vs. scrambled)
//  Possible Bug: map change (sm_map or changelevel) after a vote completes can set the wrong 
//                current_cat. I'm not exactly sure how to fix this.
//                PERHAPS: store the next map, whent he map changes compare the current map to the one we have
//                         stored. If they are different, set the current_cat to INVALID_GROUP.
//  New mapexclude_strict cvar that doesn't take map group into account when excluding previously played maps.
//  In situations where we're filtering a list of map tries (map/group tries) for a specific
//      group, it may be easier to store it instead as a trie of groups, where each group points
//      to a list of maps.
//  New module to specify a time amount (in minutes) after it's been played that a map is excluded.

//BUGS:

//************************************************************************************************//
//                                        GLOBAL VARIABLES                                        //
//************************************************************************************************//

    ////----CONVARS-----/////
new Handle:cvar_runoff_display     = INVALID_HANDLE;
new Handle:cvar_runoff_selective   = INVALID_HANDLE;        
new Handle:cvar_vote_tieramount    = INVALID_HANDLE;
new Handle:cvar_vote_tierdisplay   = INVALID_HANDLE;
new Handle:cvar_logging            = INVALID_HANDLE;
new Handle:cvar_runoff_slots       = INVALID_HANDLE;
new Handle:cvar_extend_display     = INVALID_HANDLE;
new Handle:cvar_dontchange_display = INVALID_HANDLE;
new Handle:cvar_valvemenu          = INVALID_HANDLE;
new Handle:cvar_version            = INVALID_HANDLE;
new Handle:cvar_count_sound        = INVALID_HANDLE;

//Stores the number of runoffs available.
new remaining_runoffs;

//Stores the current category.
new String:current_cat[MAP_LENGTH];

//Stores the category of the next map.
new String:next_cat[MAP_LENGTH];

//Stores the maps and map groups in a vote.
new Handle:map_vote = INVALID_HANDLE;

//Array of nomination tries.
new Handle:nominations_arr = INVALID_HANDLE;

//Variable to store the delay between stages of a tiered vote.
new tiered_delay;

//Variable to store the delay before a runoff vote starts.
new runoff_delay;

//Variable to hold the array of clients the runoff will be displayed to.
new Handle:runoff_clients = INVALID_HANDLE;

//Variable to hold the built runoff menu until after the runoff timer has finished.
new Handle:runoff_menu = INVALID_HANDLE;

//Forward for when a nomination is removed.
new Handle:nomination_reset_forward = INVALID_HANDLE;

//Stores when the map should be changed at the end of an end-of-map vote.
new UMC_ChangeMapTime:change_map_when;

//Stores the winning map from a native-induced vote.
//new String:normal_winning_map[MAP_LENGTH];

//
new String:countdown_sound[PLATFORM_MAX_PATH];

/* VOTE PARAMETERS */
new String:stored_start_sound[PLATFORM_MAX_PATH], String:stored_end_sound[PLATFORM_MAX_PATH],
    String:stored_runoff_sound[PLATFORM_MAX_PATH];
new Handle:stored_kv = INVALID_HANDLE;
new Handle:stored_mapcycle = INVALID_HANDLE;
//new stored_numexgroups;
new bool:stored_scramble;
new stored_blockslots;
new bool:stored_ignoredupes;
new bool:stored_strictnoms;
new UMC_RunoffFailAction:stored_fail_action;
new Float:extend_timestep;
new extend_roundstep;
new extend_fragstep;
new Float:stored_threshold;
new stored_runoffmaps_max;
new stored_votetime;
new String:stored_reason[PLATFORM_MAX_PATH];
new String:stored_adminflags[64];
new bool:stored_exclude;

/* Storage */
//Array to store results of a vote.
new Handle:vote_storage = INVALID_HANDLE;
new total_votes = 0;
new prev_vote_count = 0;

/* Reweight System */
new Handle:reweight_forward = INVALID_HANDLE;
new Handle:reweight_group_forward = INVALID_HANDLE;
new bool:reweight_active = false;
new Float:current_weight;

/* Exclusion System */
new Handle:exclude_forward = INVALID_HANDLE;
//new bool:exclude_active = false;

/* Reload System */
new Handle:reload_forward = INVALID_HANDLE;

/* Extend System */
new Handle:extend_forward = INVALID_HANDLE;

/* Nextmap System */
new Handle:nextmap_forward = INVALID_HANDLE;

/* Failure System */
new Handle:failure_forward = INVALID_HANDLE;

//Flags
//new bool:vote_completed;   //Has a vote been completed?
new bool:change_map_round; //Change map when the round ends?
new bool:vote_inprogress;  //Is there a vote in progress? (Includes delays between tiered + runoff)
new bool:vote_active;      //Is there an active vote menu?

#if RUNTESTS
RunTests()
{
    LogMessage("TEST: Running UMC tests.");
    
    //TESTS GO HERE
    new Handle:kv = CreateKeyValues("umc_rotation");
    KvJumpToKey(kv, "group", true);
    KvJumpToKey(kv, "MAP", true);
    KvRewind(kv);
    
    PrintKv(kv);
    if (KvDeleteSubKey(kv, "group"))
        LogMessage("Key Deleted");
        
    if (KvJumpToKey(kv, "group"))
    {
        LogMessage("Jumped to key. What the fuck?");
        KvGoBack(kv);
    }
    PrintKv(kv);
    
    CloseHandle(kv);
    
    LogMessage("TEST: Finished running UMC tests.");
}
#endif


//************************************************************************************************//
//                                        SOURCEMOD EVENTS                                        //
//************************************************************************************************//

//Called before the plugin loads, sets up our natives.
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    RegPluginLibrary("umccore");
    
    CreateNative("UMC_AddWeightModifier", Native_UMCAddWeightModifier);
    CreateNative("UMC_StartVote", Native_UMCStartVote);
    CreateNative("UMC_GetCurrentMapGroup", Native_UMCGetCurrentGroup);
    CreateNative("UMC_GetRandomMap", Native_UMCGetRandomMap);
    CreateNative("UMC_SetNextMap", Native_UMCSetNextMap);
    CreateNative("UMC_IsMapNominated", Native_UMCIsMapNominated);
    CreateNative("UMC_NominateMap", Native_UMCNominateMap);
    CreateNative("UMC_CreateValidMapArray", Native_UMCCreateMapArray);
    CreateNative("UMC_CreateValidMapGroupArray", Native_UMCCreateGroupArray);
    CreateNative("UMC_IsMapValid", Native_UMCIsMapValid);
    CreateNative("UMC_IsVoteInProgress", Native_UMCIsVoteInProgress);
    CreateNative("UMC_StopVote", Native_UMCStopVote);
    
    return APLRes_Success;
}


//Called when the plugin is finished loading.
public OnPluginStart()
{
    cvar_count_sound = CreateConVar(
        "sm_umc_countdown_sound",
        "",
        "Specifies a sound to be played each second during the countdown time between runoff and tiered votes. (Sound will be precached and added to the download table.)"
    );
    
    cvar_valvemenu = CreateConVar(
        "sm_umc_menu_esc",
        "0",
        "If enabled, votes will use Valve-Stlye menus (players will be required to press ESC in order to vote). NOTE: this may not work in TF2!",
        0, true, 0.0, true, 1.0
    );

    cvar_extend_display = CreateConVar(
        "sm_umc_extend_display",
        "0",
        "Determines where in votes the \"Extend Map\" option will be displayed.\n 0 - Bottom,\n 1 - Top",
        0, true, 0.0, true, 1.0
    );
    
    cvar_dontchange_display = CreateConVar(
        "sm_umc_dontchange_display",
        "0",
        "Determines where in votes the \"Don't Change\" option will be displayed.\n 0 - Bottom,\n 1 - Top",
        0, true, 0.0, true, 1.0
    );

    cvar_runoff_slots = CreateConVar(
        "sm_umc_runoff_blockslots",
        "1",
        "Determines whether slots in runoff votes should be blocked. This value is ignored if the original vote didn't have blocked slots.",
        0, true, 0.0, true, 1.0
    );
    
    cvar_logging = CreateConVar(
        "sm_umc_logging_verbose",
        "0",
        "Enables in-depth logging. Use this to have the plugin log how votes are being populated.",
        0, true, 0.0, true, 1.0
    );
    
    cvar_runoff_selective = CreateConVar(
        "sm_umc_runoff_selective",
        "0",
        "Specifies whether runoff votes are only displayed to players whose votes were eliminated in the runoff and players who did not vote.",
        0, true, 0.0, true, 1.0
    );
    
    cvar_vote_tieramount = CreateConVar(
        "sm_umc_vote_tieramount",
        "6",
        "Specifies the maximum number of maps to appear in the second part of a tiered vote.",
        0, true, 2.0
    );
    
    cvar_runoff_display = CreateConVar(
        "sm_umc_runoff_display",
        "C",
        "Determines where the Runoff Vote Message is displayed on the screen.\n C - Center Message\n S - Chat Message\n T - Top Message\n H - Hint Message"
    );
    
    cvar_vote_tierdisplay = CreateConVar(
        "sm_umc_vote_tierdisplay",
        "C",
        "Determines where the Tiered Vote Message is displayed on the screen.\n C - Center Message\n S - Chat Message\n T - Top Message\n H - Hint Message"
    );

    //Version
    cvar_version = CreateConVar(
        "improved_map_randomizer_version", PL_VERSION, "Ultimate Mapchooser's version",
        FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED
    );
    
    //Create the config if it doesn't exist, and then execute it.
    AutoExecConfig(true, "ultimate-mapchooser");
    
    //Admin command to set the next map
    RegAdminCmd("sm_setnextmap", Command_SetNextmap, ADMFLAG_CHANGEMAP, "sm_setnextmap <map>");
    
    //Admin command to reload the mapcycle.
    RegAdminCmd(
        "sm_umc_reload_mapcycles", Command_Reload, ADMFLAG_RCON, "Reloads the mapcycle file."
    );
    
    //Admin command to stop votes in progress.
    RegAdminCmd(
        "sm_umc_stopvote", Command_StopVote, ADMFLAG_CHANGEMAP,
        "Stops a UMC vote that's in progress."
    );
    
    //Hook round end events
    HookEvent("round_end",            Event_RoundEnd); //Generic
    HookEventEx("game_round_end",     Event_RoundEnd); //Hidden: Source, Neotokyo
    HookEventEx("teamplay_win_panel", Event_RoundEnd); //TF2
    HookEventEx("arena_win_panel",    Event_RoundEnd); //TF2
    
    //Initialize our vote arrays
    map_vote        = CreateArray();
    vote_storage    = CreateArray();
    nominations_arr = CreateArray();
    
    //Make listeners for player chat. Needed to recognize chat commands ("rtv", etc.)
    AddCommandListener(OnPlayerChat, "say");
    AddCommandListener(OnPlayerChat, "say2"); //Insurgency Only
    AddCommandListener(OnPlayerChat, "say_team");
    
    //Load the translations file
    LoadTranslations("ultimate-mapchooser.phrases");
    
    //Setup our forward for when a nomination is removed
    nomination_reset_forward = CreateGlobalForward(
        "OnNominationRemoved", ET_Ignore, Param_String, Param_Cell
    );
    
    reweight_forward = CreateGlobalForward(
        "UMC_OnReweightMap", ET_Ignore, Param_Cell, Param_String, Param_String
    );
    
    reweight_group_forward = CreateGlobalForward(
        "UMC_OnReweightGroup", ET_Ignore, Param_Cell, Param_String
    );
    
    exclude_forward = CreateGlobalForward(
        "UMC_OnDetermineMapExclude",
        ET_Hook, Param_Cell, Param_String, Param_String, Param_Cell, Param_Cell
    );
    
    reload_forward = CreateGlobalForward("UMC_RequestReloadMapcycle", ET_Ignore);
    
    extend_forward = CreateGlobalForward("UMC_OnMapExtended", ET_Ignore);
    
    nextmap_forward = CreateGlobalForward(
        "UMC_OnNextmapSet", ET_Ignore, Param_Cell, Param_String, Param_String, Param_String
    );
    
    failure_forward = CreateGlobalForward("UMC_OnVoteFailed", ET_Ignore);
    
#if AUTOUPDATE_ENABLE
    if (LibraryExists("updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
#endif
    
#if RUNTESTS
    RunTests();
#endif
}


#if AUTOUPDATE_ENABLE
//Called when a new API library is loaded. Used to register UMC auto-updating.
public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
}
#endif


//************************************************************************************************//
//                                           GAME EVENTS                                          //
//************************************************************************************************//

//Called before any configs are executed.
public OnMapStart()
{   
    //Update the current category.
    strcopy(current_cat, sizeof(current_cat), next_cat);
    strcopy(next_cat, sizeof(next_cat), INVALID_GROUP);
    
    CreateTimer(5.0, UpdateTrackingCvar);
}


//
public Action:UpdateTrackingCvar(Handle:timer)
{
    SetConVarString(cvar_version, PL_VERSION, false, false);
}


//Called after all config files were executed.
public OnConfigsExecuted()
{
    //Have all plugins reload their mapcycles.
    //Call_StartForward(reload_forward);
    //Call_Finish();

    //Turn off the reweight system in the event it was left active (map change?)
    reweight_active = false;
    
    //No votes have been completed.
    //vote_completed = false;
    
    change_map_round = false;
    
    vote_inprogress = false;
    vote_active = false; //Assuming the case where this is still active was caught by VoteComplete()
    
    GetConVarString(cvar_count_sound, countdown_sound, sizeof(countdown_sound));
    CacheSound(countdown_sound);
}


//Called when a player types in chat.
//Required to handle user commands.
public Action:OnPlayerChat(client, const String:command[], argc)
{
    //Return immediately if...
    //    ...nothing was typed.
    if (argc == 0) return Plugin_Continue;

    //Get what was typed.
    decl String:text[13];
    GetCmdArg(1, text, sizeof(text));
    
    if (StrEqual(text, "umc", false) || StrEqual(text, "!umc", false)
        || StrEqual(text, "/umc", false))
        PrintToChatAll("[SM] Ultimate Mapchooser v%s by Steell", PL_VERSION);
    
    return Plugin_Continue;
}


//Called when a client has left the server. Needed to update nominations.
public OnClientDisconnect(client)
{
    //Find this client in the array of clients who have entered RTV.
    new index = FindClientNomination(client);
    
    //Remove the client from the nomination pool if...
    //    ...the client is in the pool to begin with.
    if (index != -1)
    {
        new Handle:nomination = GetArrayCell(nominations_arr, index);
        
        decl String:oldMap[MAP_LENGTH];
        GetTrieString(nomination, MAP_TRIE_MAP_KEY, oldMap, sizeof(oldMap));
        new owner;
        GetTrieValue(nomination, "client", owner);
        Call_StartForward(nomination_reset_forward);
        Call_PushString(oldMap);
        Call_PushCell(owner);
        Call_Finish();

        new Handle:nomKV;
        GetTrieValue(nomination, "mapcycle", nomKV);
        CloseHandle(nomKV);
        CloseHandle(nomination);
        RemoveFromArray(nominations_arr, index);
    }
}


//Called when a round ends.
public Event_RoundEnd(Handle:evnt, const String:name[], bool:dontBroadcast)
{
    if (change_map_round)
    {
        change_map_round = false;
        decl String:map[MAP_LENGTH];
        GetNextMap(map, sizeof(map));    
        ForceChangeInFive(map, "CORE");
    }
}


//Called at the end of a map.
public OnMapEnd()
{
    //Empty array of nominations (and close all handles).
    ClearNominations();
}


//************************************************************************************************//
//                                             NATIVES                                            //
//************************************************************************************************//

//native Handle:UMC_CreateValidMapArray(Handle:kv, const String:group[], bool:isNom, 
//                                      bool:forMapChange);
public Native_UMCCreateMapArray(Handle:plugin, numParams)
{
    new Handle:kv = CreateKeyValues("umc_rotation");
    new Handle:arg = Handle:GetNativeCell(1);
    KvCopySubkeys(arg, kv);
    
    new Handle:mapcycle = Handle:GetNativeCell(2);
    
    new len;
    GetNativeStringLength(3, len);
    new String:group[len+1];
    if (len > 0)
        GetNativeString(3, group, len+1);
    
    new bool:isNom = bool:GetNativeCell(4);
    new bool:forMapChange = bool:GetNativeCell(5);
    
    new Handle:result = CreateMapArray(kv, mapcycle, group, isNom, forMapChange);
    
    CloseHandle(kv);
    
    return _:CloseAndClone(result, plugin);
}


//Create an array of valid maps from the given mapcycle and group.
Handle:CreateMapArray(Handle:kv, Handle:mapcycle, const String:group[], bool:isNom,
                      bool:forMapChange)
{
    if (kv == INVALID_HANDLE)
    {
        LogError("NATIVE: Cannot build map array, mapcycle is invalid.");
        return INVALID_HANDLE;
    }
 
    new bool:oneSection = false; 
    if (StrEqual(group, INVALID_GROUP))
    {
        if (!KvGotoFirstSubKey(kv))
        {
            LogError("NATIVE: Cannot build map array, mapcycle has no groups.");
            return INVALID_HANDLE;
        }
    }
    else
    {
        if (!KvJumpToKey(kv, group))
        {
            LogError("NATIVE: Cannot build map array, mapcycle has no group '%s'", group);
            return INVALID_HANDLE;
        }
        
        oneSection = true;
    }
    
    new Handle:result = CreateArray();
    decl String:mapName[MAP_LENGTH], String:groupName[MAP_LENGTH];
    do
    {
        KvGetSectionName(kv, groupName, sizeof(groupName));
        
        if (!KvGotoFirstSubKey(kv))
        {
            if (!oneSection)
                continue;
            else
                break;
        }
        
        do
        {
            if (IsValidMap(kv, mapcycle, groupName, isNom, forMapChange))
            {
                KvGetSectionName(kv, mapName, sizeof(mapName));
                PushArrayCell(result, CreateMapTrie(mapName, groupName));
            }
        }
        while (KvGotoNextKey(kv));
        
        KvGoBack(kv);
        
        if (oneSection) break;
    }
    while (KvGotoNextKey(kv));
    
    KvGoBack(kv);
    
    return result;
}


//native Handle:UMC_CreateValidMapGroupArray(Handle:kv, bool:isNom, bool:forMapChange);
public Native_UMCCreateGroupArray(Handle:plugin, numParams)
{
    new Handle:arg = Handle:GetNativeCell(1);
    new Handle:kv = CreateKeyValues("umc_rotation");
    KvCopySubkeys(arg, kv);
    new Handle:mapcycle = Handle:GetNativeCell(2);
    new bool:isNom = bool:GetNativeCell(3);
    new bool:forMapChange = bool:GetNativeCell(4);
    
    new Handle:result = CreateMapGroupArray(kv, mapcycle, isNom, forMapChange);
    
    CloseHandle(kv);
    
    return _:CloseAndClone(result, plugin);
}


//Create an array of valid maps from the given mapcycle and group.
Handle:CreateMapGroupArray(Handle:kv, Handle:mapcycle, bool:isNom, bool:forMapChange)
{
    if (!KvGotoFirstSubKey(kv))
    {
        LogError("NATIVE: Cannot build map array, mapcycle has no groups.");
        return INVALID_HANDLE;
    }
    
    new Handle:result = CreateArray(ByteCountToCells(MAP_LENGTH));
    decl String:groupName[MAP_LENGTH];
    do
    {
        if (IsValidCat(kv, mapcycle, isNom, forMapChange))
        {
            KvGetSectionName(kv, groupName, sizeof(groupName));
            PushArrayString(result, groupName);
        }    
    }
    while (KvGotoNextKey(kv));
    
    KvGoBack(kv);
    
    return result;
}


//native bool:UMC_IsMapNominated(const String:map[], const String:group[]);
public Native_UMCIsMapNominated(Handle:plugin, numParams)
{
    new len;
    GetNativeStringLength(1, len);
    new String:map[len+1];
    if (len > 0)
        GetNativeString(1, map, len+1);
        
    GetNativeStringLength(2, len);
    new String:group[len+1];
    if (len > 0)
        GetNativeString(2, group, len+1);
    
    return _:(FindNominationIndex(map, group) != -1);
}


//native bool:UMC_NominateMap(const String:map[], const String:group[]);
public Native_UMCNominateMap(Handle:plugin, numParams)
{
    new Handle:kv = CreateKeyValues("umc_rotation");
    KvCopySubkeys(Handle:GetNativeCell(1), kv);
    
#if UMC_DEBUG
    PrintKv(kv);
#endif
    
    new len;
    GetNativeStringLength(2, len);
    new String:map[len+1];
    if (len > 0)
        GetNativeString(2, map, len+1);
        
    GetNativeStringLength(3, len);
    new String:group[len+1];
    if (len > 0)
        GetNativeString(3, group, len+1);
        
    new String:nomGroup[MAP_LENGTH];
    if (numParams > 4)
    {
        GetNativeStringLength(5, len);
        if (len > 0)
            GetNativeString(5, nomGroup, sizeof(nomGroup));
    }
    else
    {
        strcopy(nomGroup, sizeof(nomGroup), INVALID_GROUP);
    }
        
    return _:InternalNominateMap(kv, map, group, GetNativeCell(4), nomGroup);
}


//native AddWeightModifier(MapWeightModifier:func);
public Native_UMCAddWeightModifier(Handle:plugin, numParams)
{
    if (reweight_active)
    {
        current_weight *= Float:GetNativeCell(1);
        DEBUG_MESSAGE("New map weight: %f", current_weight)
    }
    else
        LogError("REWEIGHT: Attempted to add weight modifier outside of UMC_OnReweightMap forward.");
}


//native bool:UMC_StartVote( ...20+ params... );
public Native_UMCStartVote(Handle:plugin, numParams)
{
    if (vote_inprogress)
        return _:false;
    
    //Get the name of the calling plugin.
    GetPluginFilename(plugin, stored_reason, sizeof(stored_reason));
    
    vote_inprogress = true;
    //vote_completed = false;

    //Retrieve the many, many parameters.
    new Handle:kv = Handle:GetNativeCell(1);
    new Handle:mapcycle = Handle:GetNativeCell(2);
    new UMC_VoteType:type = UMC_VoteType:GetNativeCell(3);
    new time = GetNativeCell(4);
    new bool:scramble = bool:GetNativeCell(5);
    new numBlockSlots = GetNativeCell(6);
    
    new len;
    GetNativeStringLength(7, len);
    new String:startSound[len+1];
    if (len > 0)
        GetNativeString(7, startSound, len+1);
    GetNativeStringLength(8, len);
    new String:endSound[len+1];
    if (len > 0)
        GetNativeString(8, endSound, len+1);
    
    new bool:extend = bool:GetNativeCell(9);
    new Float:timestep = Float:GetNativeCell(10);
    new roundstep = GetNativeCell(11);
    new fragstep = GetNativeCell(12);
    new bool:dontChange = bool:GetNativeCell(13);
    new Float:threshold = Float:GetNativeCell(14);
    new UMC_ChangeMapTime:successAction = UMC_ChangeMapTime:GetNativeCell(15);
    new UMC_VoteFailAction:failAction = UMC_VoteFailAction:GetNativeCell(16);
    new maxRunoffs = GetNativeCell(17);
    new maxRunoffMaps = GetNativeCell(18);
    new UMC_RunoffFailAction:runoffFailAction = UMC_RunoffFailAction:GetNativeCell(19);
    
    GetNativeStringLength(20, len);
    new String:runoffSound[len+1];
    if (len > 0)
        GetNativeString(20, runoffSound, len+1);
    
    new bool:nominationStrictness = bool:GetNativeCell(21);
    new bool:allowDuplicates = bool:GetNativeCell(22);
    
    GetNativeStringLength(23, len);
    new String:adminFlags[len+1];
    if (len > 0)
        GetNativeString(23, adminFlags, len+1);
        
    new bool:runExclusionCheck = (numParams >= 24) ? (bool:GetNativeCell(24)) : true;
    
    //OK now that that's done, let's save 'em.
    stored_scramble = scramble;
    stored_blockslots = numBlockSlots;
    stored_ignoredupes = allowDuplicates;
    stored_strictnoms = nominationStrictness;

    if (failAction == VoteFailAction_Nothing)
    {
        stored_fail_action = RunoffFailAction_Nothing;
        remaining_runoffs = 0;
    }
    else if (failAction == VoteFailAction_Runoff)
    {    
        stored_fail_action = runoffFailAction;   
        remaining_runoffs = (maxRunoffs == 0) ? -1 : maxRunoffs;
    }
    
    extend_timestep = timestep;
    extend_roundstep = roundstep;
    extend_fragstep = fragstep;
    stored_threshold = threshold;
    stored_runoffmaps_max = maxRunoffMaps;
    stored_votetime = time;
    
    change_map_when = successAction;
    
    stored_kv = CreateKeyValues("umc_rotation");
    KvCopySubkeys(kv, stored_kv);
    
    stored_mapcycle = CreateKeyValues("umc_rotation");
    KvCopySubkeys(mapcycle, stored_mapcycle);
    
    strcopy(stored_start_sound, sizeof(stored_start_sound), startSound);
    strcopy(stored_end_sound, sizeof(stored_end_sound), endSound);
    strcopy(stored_runoff_sound, sizeof(stored_runoff_sound), runoffSound);
    
    strcopy(stored_adminflags, sizeof(stored_adminflags), adminFlags);
    
    stored_exclude = runExclusionCheck;
    
    //Make the vote menu.
    new Handle:menu = BuildVoteMenu(kv, mapcycle, type, scramble, numBlockSlots, extend, dontChange,
                                    allowDuplicates, nominationStrictness, runExclusionCheck);
    
    //Run the vote if...
    //    ...the menu was created successfully.
    if (menu != INVALID_HANDLE)
    {
        //Play the vote start sound if...
        //  ...the filename is defined.
        if (strlen(startSound) > 0)
            EmitSoundToAll(startSound);
        
        vote_active = true;
        
        return _:VoteMenuToAllWithFlags(menu, time, adminFlags);
    }
    else
    {
        DeleteVoteParams();
        return _:false;
    }
}


//native bool:UMC_GetRandomMap(Handle:kv, const String:group=INVALID_GROUP, String:buffer[], size,
//                             Handle:excludedMaps, Handle:excludedGroups, bool:forceGroup);
public Native_UMCGetRandomMap(Handle:plugin, numParams)
{
    new Handle:kv = Handle:GetNativeCell(1);
    new Handle:filtered = CreateKeyValues("umc_rotation");
    KvCopySubkeys(kv, filtered);

    new Handle:mapcycle = Handle:GetNativeCell(2);
    new len;
    GetNativeStringLength(3, len);
    new String:group[len+1];
    if (len > 0)
        GetNativeString(3, group, len+1);
    
    new bool:isNom = bool:GetNativeCell(8);
    new bool:forMapChange = bool:GetNativeCell(9);
    
    FilterMapcycle(filtered, mapcycle, isNom, forMapChange);
    WeightMapcycle(filtered, mapcycle);
    
#if UMC_DEBUG
    PrintKv(filtered);
#endif
    
    decl String:map[MAP_LENGTH], String:groupResult[MAP_LENGTH];
    new bool:result = GetRandomMapFromCycle(filtered, group, map, sizeof(map), groupResult,
                                            sizeof(groupResult));
    
    CloseHandle(filtered);
    
    if (result)
    {
        SetNativeString(4, map, GetNativeCell(5), false);
        SetNativeString(6, groupResult, GetNativeCell(7), false);
        return true;
    }
    return false;
}


//native bool:UMC_SetNextMap(Handle:kv, const String:map[], const String:group[]);
public Native_UMCSetNextMap(Handle:plugin, numParams)
{
    new Handle:kv = Handle:GetNativeCell(1);
    
    new len;
    GetNativeStringLength(2, len);
    new String:map[len+1];
    if (len > 0)
        GetNativeString(2, map, len+1);
    GetNativeStringLength(3, len);
    new String:group[len+1];
    if (len > 0)
        GetNativeString(3, group, len+1);
    
    if (!IsMapValid(map))
    {
        LogError("SETMAP: Map %s is invalid!", map);
        return;
    }
    
    new UMC_ChangeMapTime:when = UMC_ChangeMapTime:GetNativeCell(4);
    
    decl String:reason[PLATFORM_MAX_PATH];
    GetPluginFilename(plugin, reason, sizeof(reason));
    
    DoMapChange(when, kv, map, group, reason, map);
}


//
public Native_UMCIsVoteInProgress(Handle:plugin, numParams)
{
    return vote_inprogress;
}


//
//"sm_umc_stopvote"
public Native_UMCStopVote(Handle:plugin, numParams)
{
    if (vote_inprogress)
    {
        if (vote_active)
        {
            CancelVote();
        }
        else
        {
            vote_inprogress = false;
        }
        return true;
    }
    return false;
}


//
public Native_UMCIsMapValid(Handle:plugin, numParams)
{
    new Handle:arg = Handle:GetNativeCell(1);
    new Handle:kv = CreateKeyValues("umc_rotation");
    KvCopySubkeys(arg, kv);
    
#if UMC_DEBUG
    DEBUG_MESSAGE("UMC_IsValidMap passed mapcycle:")
    PrintKv(arg);
#endif
    
    new len;
    GetNativeStringLength(2, len);
    new String:map[len+1];
    if (len > 0)
        GetNativeString(2, map, len+1);
    GetNativeStringLength(3, len);
    new String:group[len+1];
    if (len > 0)
        GetNativeString(3, group, len+1);
    
    new bool:isNom = bool:GetNativeCell(4);
    new bool:forMapChange = bool:GetNativeCell(5);
    
    if (!KvJumpToKey(kv, group))
    {
        LogError("NATIVE: No group '%s' in mapcycle.", group);
        return _:false;
    }
    if (!KvJumpToKey(kv, map))
    {
        LogError("NATIVE: No map %s found in group '%s'", map, group);
        return _:false;
    }
    
    return _:IsValidMap(kv, arg, group, isNom, forMapChange);
}


//
public Native_UMCGetCurrentGroup(Handle:plugin, numParams)
{
    SetNativeString(1, current_cat, GetNativeCell(2), false);
}


//************************************************************************************************//
//                                            COMMANDS                                            //
//************************************************************************************************//

//Called when the command to set the nextmap is called.
public Action:Command_SetNextmap(client, args)
{
    if (args < 1)
    {
        ReplyToCommand(
            client,
            "\x03[UMC]\x01 Usage: sm_setnextmap <map> <0|1|2>\n 0 - Change Now\n 1 - Change at end of round\n 2 - Change at end of map."
        );
        return Plugin_Handled;
    }
    
    decl String:map[MAP_LENGTH];
    GetCmdArg(1, map, sizeof(map));
    
    if (!IsMapValid(map))
    {
        ReplyToCommand(client, "\x03[UMC]\x01 Map '%s' was not found.", map);
        return Plugin_Handled;
    }
    
    new UMC_ChangeMapTime:when = ChangeMapTime_MapEnd;
    if (args > 1)
    {
        decl String:whenArg[2];
        GetCmdArg(2, whenArg, sizeof(whenArg));
        when = UMC_ChangeMapTime:StringToInt(whenArg);
    }
    
    DoMapChange(when, INVALID_HANDLE, map, INVALID_GROUP, "sm_setnextmap", map);
    
    //TODO: Make this a translation
    ShowActivity(client, "Changed nextmap to \"%s\".", map);
    LogMessage("%L changed nextmap to \"%s\"", client, map);
    
    //vote_completed = true;
    
    return Plugin_Handled;
}


//Called when the command to reload the mapcycle has been triggered.
public Action:Command_Reload(client, args)
{
    //Call the reload forward.
    Call_StartForward(reload_forward);
    Call_Finish();
    
    ReplyToCommand(client, "\x03[UMC]\x01 UMC Mapcycles Reloaded.");    
    
    //Return success
    return Plugin_Handled;
}


//"sm_umc_stopvote"
public Action:Command_StopVote(client, args)
{
    if (vote_inprogress)
    {
        if (vote_active)
        {
            CancelVote();
        }
        else
            vote_inprogress = false;
    }
    else
    {
        ReplyToCommand(client, "\x03[UMC]\x01 No map vote running!");
    }
    return Plugin_Handled;
}


//************************************************************************************************//
//                                        VOTING UTILITIES                                        //
//************************************************************************************************//

//Build and returns a new vote menu.
Handle:BuildVoteMenu(Handle:kv, Handle:mapcycle, UMC_VoteType:type, bool:scramble, numBlockSlots,
                     bool:extend, bool:dontChange, bool:allowDupes, bool:strictNoms, bool:exclude)
{
    new Handle:result = INVALID_HANDLE;

    switch (type)
    {
        case (VoteType_Map):
        {
            result = BuildMapVoteMenu(kv, mapcycle, Handle_MapVoteResults, scramble, extend,
                                      dontChange, numBlockSlots, allowDupes, strictNoms,
                                      .exclude=exclude);
        }
        case (VoteType_Group):
        {
            result = BuildCatVoteMenu(kv, mapcycle, Handle_CatVoteResults, scramble, extend,
                                      dontChange, numBlockSlots, strictNoms, .exclude=exclude);
        }
        case (VoteType_Tier):
        {
            result = BuildCatVoteMenu(kv, mapcycle, Handle_TierVoteResults, scramble, extend,
                                      dontChange, numBlockSlots, strictNoms, .exclude=exclude);
        }
    }
    
    return result;
}


//Builds and returns a menu for a map vote.
//    callback:   function to be called when the vote is finished.
//    scramble:   whether the menu items are in a random order (true) or in the order the categories 
//                are listed in the cycle.
//    extend:     whether an extend option should be added to the vote.
//    dontChange: whether a "Don't Change" option should be added to the vote.
Handle:BuildMapVoteMenu(Handle:okv, Handle:mapcycle, VoteHandler:callback, bool:scramble,
                        bool:extend, bool:dontChange, blockSlots=0, bool:ignoreDupes=false,
                        bool:strictNoms=false, bool:ignoreInvoteSetting=false, bool:exclude=true)
{
    DEBUG_MESSAGE("MAPVOTE - Building map vote menu.")
    //Throw an error and return nothing if...
    //    ...the mapcycle is invalid.
    if (okv == INVALID_HANDLE)
    {
        LogError("VOTING: Cannot build map vote menu, rotation file is invalid.");
        return INVALID_HANDLE;
    }
    
    DEBUG_MESSAGE("Preparing mapcycle for traversal.")
    //Duplicate the kv handle, because we will be deleting some keys.
    KvRewind(okv); //rewind original
    new Handle:kv = CreateKeyValues("umc_rotation"); //new handle
    KvCopySubkeys(okv, kv); //copy everything to the new handle
    
    //Filter mapcycle
    if (exclude)
        FilterMapcycle(kv, mapcycle, .deleteEmpty=false);
    
#if UMC_DEBUG
    PrintKv(kv);
#endif
    
    DEBUG_MESSAGE("Checking for groups.")
    //Log an error and return nothing if...
    //    ...it cannot find a category.
    if (!KvGotoFirstSubKey(kv))
    {
        LogError("VOTING: No map groups found in rotation. Vote menu was not built.");
        CloseHandle(kv);
        return INVALID_HANDLE;
    }
    
    DEBUG_MESSAGE("Preparing vote data storage.")
    ClearVoteArrays();

    DEBUG_MESSAGE("Getting options from cvars.")
    //Determine how we're logging
    new bool:verboseLogs = GetConVarBool(cvar_logging);
    
    DEBUG_MESSAGE("Initializing Buffers")
    //Buffers
    new String:mapName[MAP_LENGTH];     //Name of the map
    new String:display[MAP_LENGTH];     //String to be displayed in the vote
    new String:gDisp[MAP_LENGTH];
    new String:catName[MAP_LENGTH];     //Name of the category.
    
    //Other variables
    new voteCounter = 0; //Number of maps in the vote currently
    new numNoms = 0;     //Number of nominated maps in the vote.
    new Handle:nominationsFromCat = INVALID_HANDLE; //adt_array containing all nominations from the
                                                    //current category.
    new Handle:tempCatNoms = INVALID_HANDLE;
    new Handle:trie        = INVALID_HANDLE; //a nomination
    new Handle:nameArr     = INVALID_HANDLE; //adt_array of map names from nominations
    new Handle:weightArr   = INVALID_HANDLE; //adt_array of map weights from nominations.
    
    new Handle:map_vote_display = CreateArray(ByteCountToCells(MAP_LENGTH));
    
    new nomIndex, position, numMapsFromCat, nomCounter, inVote, index; //, cIndex;
    
    new tierAmount = GetConVarInt(cvar_vote_tieramount);
    
    new Handle:nomKV;
    decl String:nomGroup[MAP_LENGTH];
    
    DEBUG_MESSAGE("Performing Traversal")
    //Add maps to vote array from current category.
    do
    {
        WeightMapGroup(kv, mapcycle);
    
        //Store the name of the current category.
        KvGetSectionName(kv, catName, sizeof(catName));
        
        DEBUG_MESSAGE("Fetching map group data")
        
        //Get the map-display template from the categeory definition.
        KvGetString(kv, "display-template", gDisp, sizeof(gDisp), "{MAP}");
        
        DEBUG_MESSAGE("Fetching Nominations")
        
        //Get all nominations for the current category.
        if (exclude)
        {
            tempCatNoms = GetCatNominations(catName);
            nominationsFromCat = FilterNominationsArray(tempCatNoms);        
#if UMC_DEBUG
            DEBUG_MESSAGE("Unfiltered:")
            PrintNominationArray(tempCatNoms);
            DEBUG_MESSAGE("Filtered:")
            PrintNominationArray(nominationsFromCat);
#endif
            CloseHandle(tempCatNoms);
        }
        else
            nominationsFromCat = GetCatNominations(catName);
        
        //Get the amount of nominations for the current category.
        numNoms = GetArraySize(nominationsFromCat);
        
        DEBUG_MESSAGE("Calculating amount of maps needed to be fetched.")
        
        //Get the total amount of maps to appear in the vote from this category.
        inVote = ignoreInvoteSetting 
                    ? tierAmount
                    : KvGetNum(kv, "maps_invote", 1);
        
        if (verboseLogs)
        {
            if (ignoreInvoteSetting)
                LogMessage("VOTE MENU: (Verbose) Second stage tiered vote. See cvar \"sm_umc_vote_tieramount.\"");
            LogMessage("VOTE MENU: (Verbose) Fetching %i maps from group '%s'", inVote, catName);
        }
        
        //Calculate the number of maps we still need to fetch from the mapcycle.
        numMapsFromCat = inVote - numNoms;
        
        DEBUG_MESSAGE("Determining proper nomination processing algorithm.")
        
        //Populate vote with nomination maps from this category if...
        //    ...we do not need to fetch any maps from the mapcycle AND
        //    ...the number of nominated maps in the vote is limited to the maps_invote setting for
        //       the category.
        if (numMapsFromCat < 0 && strictNoms)
        {
            //////
            //The piece of code inside this block is for the case where the current category's
            //nominations exceeds it's number of maps allowed in the vote.
            //
            //In order to solve this problem, we first fetch all nominations where the map has
            //appropriate min and max players for the amount of players on the server, and then
            //randomly pick from this pool based on the weights if the maps, until the number
            //of maps in the vote from this category is reached.
            //////
            
            DEBUG_MESSAGE("Performing strict nomination algorithm.")
            
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
                nameArr = CreateArray(ByteCountToCells(MAP_LENGTH));
                weightArr = CreateArray();
                new Handle:cycleArr = CreateArray();
                
                DEBUG_MESSAGE("Fetching data from all nominations in the map group.")
                
                //Store data from a nomination for...
                //    ...each index of the adt_array of nominations from this category.
                for (new i = 0; i < numNoms; i++)
                {
                    DEBUG_MESSAGE("Fetching nomination data.")
                    //Store nomination.
                    trie = GetArrayCell(nominationsFromCat, i);
                    
                    //Get the map name from the nomination.
                    GetTrieString(trie, MAP_TRIE_MAP_KEY, mapName, sizeof(mapName));
                    
                    DEBUG_MESSAGE("Determining what to do with the nomination.")
                    
                    //Add map to list of possible maps to be added to vote from the nominations 
                    //if...
                    //    ...the map is valid (correct number of players, correct time)
                    if (!ignoreDupes 
                        && FindStringInVoteArray(mapName, MAP_TRIE_MAP_KEY, map_vote) != -1)
                    {
                        DEBUG_MESSAGE("Skipping repeated nomination.")
                        if (verboseLogs)
                        {
                            LogMessage(
                                "VOTE MENU: (Verbose) Skipping nominated map '%s' from map group '%s' because it already is in the vote.",
                                mapName, catName
                            );
                        }
                    }
                    else
                    {
                        DEBUG_MESSAGE("Adding nomination to the possible vote pool.")
                        //Increment number of noms fetched.
                        nomCounter++;
                        
                        //Fetch mapcycle for weighting
                        GetTrieValue(trie, "mapcycle", nomKV);
                        
                        //Add map name to the pool.
                        PushArrayString(nameArr, mapName);
                        
                        //Add map weight to the pool.
                        PushArrayCell(weightArr, GetMapWeight(nomKV, mapName, catName));
                        
                        PushArrayCell(cycleArr, trie);
                    }
                }
                
                //After we have parsed every map from the list of nominations...
                
                DEBUG_MESSAGE("Choosing nominations from the pool to be inserted into the vote.")
                
                //Populate vote array with maps from the pool if...
                //    ...the number of nominations fetched is greater than zero.
                if (nomCounter > 0)
                {
                    //Add a nominated map from the pool into the vote arrays for...
                    //    ...the number of available spots there are from the category.
                    new min = (inVote < nomCounter) ? inVote : nomCounter;
                    
                    DEBUG_MESSAGE("Begin parsing nomination pool.")
                    
                    for (new i = 0; i < min; i++)
                    {
                        DEBUG_MESSAGE("Fetching a random nomination from the pool.")
                        //Get a random map from the pool.
                        GetWeightedRandomSubKey(mapName, sizeof(mapName), weightArr, nameArr, index);
                        
                        new Handle:nom = GetArrayCell(cycleArr, index);
                        GetTrieValue(nom, "mapcycle", nomKV);
                        
                        GetTrieString(nom, "nom_group", nomGroup, sizeof(nomGroup));
                        
                        DEBUG_MESSAGE("Determining where to place the map in the vote.")
                        //Get the position in the vote array to add the map to
                        position = GetNextMenuIndex(voteCounter, scramble);
                        
                        DEBUG_MESSAGE("Fetching extra info for the map from the mapcycle.")
                        //Get extra fields from the map
                        KvJumpToKey(nomKV, nomGroup);
                        KvJumpToKey(nomKV, mapName);
                        KvGetString(nomKV, "display", display, sizeof(display), gDisp);
                        
                        DEBUG_MESSAGE("Setting proper display string.")
                        if (strlen(display) == 0)
                            strcopy(display, sizeof(display), mapName);
                        else
                            ReplaceString(display, sizeof(display), "{MAP}", mapName, false);
                        
                        KvGoBack(nomKV);
                        KvGoBack(nomKV);
                        
                        DEBUG_MESSAGE("Adding nomination to the vote.")
                        
                        new Handle:map = CreateMapTrie(mapName, catName);
                        
                        new Handle:nomMapcycle = CreateKeyValues("umc_mapcycle");
                        KvCopySubkeys(nomKV, nomMapcycle);
                        
                        SetTrieValue(map, "mapcycle", nomMapcycle);
                        
                        InsertArrayCell(map_vote, position, map);
                        InsertArrayString(map_vote_display, position, display);
                        
                        //Increment number of maps added to the vote.
                        voteCounter++;
                        
                        DEBUG_MESSAGE("Preventing nomination and map from being picked again.")
                        
                        //Delete the map so it can't be picked again.
                        KvDeleteSubKey(kv, mapName);

                        //Remove map from pool.
                        RemoveFromArray(nameArr, index);
                        RemoveFromArray(weightArr, index);
                        RemoveFromArray(cycleArr, index);
                        
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
                CloseHandle(cycleArr);
                
                //Update numMapsFromCat to reflect the actual amount still required.
                numMapsFromCat = inVote - nomCounter;
            }
        }
        //Otherwise, we fill the vote with nominations then fill the rest with random maps from the
        //mapcycle.
        else
        {
            DEBUG_MESSAGE("Adding all nominations to the vote.")
            //Add nomination to the vote array for..
            //    ...each index in the nomination array.
            for (new i = 0; i < numNoms; i++)
            {
                DEBUG_MESSAGE("Fetching nomination info.")
                //Get map name.
                new Handle:nom = GetArrayCell(nominationsFromCat, i);
                GetTrieString(nom, MAP_TRIE_MAP_KEY, mapName, sizeof(mapName));
                
                DEBUG_MESSAGE("Determining what to do with the nomination.")
                
                //Add nominated map to the vote array if...
                //    ...the map isn't already in the vote AND
                //    ...the server has a valid number of players for the map.
                if (!ignoreDupes
                    && FindStringInVoteArray(mapName, MAP_TRIE_MAP_KEY, map_vote) != -1)
                {
                    DEBUG_MESSAGE("Skipping repeated nomination.")
                    if (verboseLogs)
                    {
                        LogMessage(
                            "VOTE MENU: (Verbose) Skipping nominated map '%s' from map group '%s' because it is already in the vote.",
                            mapName, catName
                        );
                    }
                }
                else
                {
                    GetTrieValue(nom, "mapcycle", nomKV);
                    GetTrieString(nom, "nom_group", nomGroup, sizeof(nomGroup));
                
                    //Get extra fields from the map
                    KvJumpToKey(nomKV, nomGroup);
                    KvJumpToKey(nomKV, mapName);
                    KvGetString(nomKV, "display", display, sizeof(display), gDisp);
                    
                    DEBUG_MESSAGE("Setting proper display string.")
                    if (strlen(display) == 0)
                        strcopy(display, sizeof(display), mapName);
                    else
                        ReplaceString(display, sizeof(display), "{MAP}", mapName, false);
                        
                    KvGoBack(nomKV);
                    KvGoBack(nomKV);
                    
                    DEBUG_MESSAGE("Determining where to place the map in the vote.")
                    //Get the position in the vote array to add the map to.
                    position = GetNextMenuIndex(voteCounter, scramble);
                    
                    DEBUG_MESSAGE("Adding nomination to the vote.")
                    
                    new Handle:map = CreateMapTrie(mapName, catName);
                        
                    new Handle:nomMapcycle = CreateKeyValues("umc_mapcycle");
                    KvCopySubkeys(nomKV, nomMapcycle);
                    
                    SetTrieValue(map, "mapcycle", nomMapcycle);
                    
                    InsertArrayCell(map_vote, position, map);
                    InsertArrayString(map_vote_display, position, display);
                    
                    //Increment number of maps added to the vote.
                    voteCounter++;
                    
                    DEBUG_MESSAGE("Preventing map from being picked again.")
                        
                    //Delete the map so it cannot be picked again.
                    KvDeleteSubKey(kv, mapName);
                    
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
        
        DEBUG_MESSAGE("Finished processing nominations.")
        
        if (verboseLogs)
        {
            LogMessage("VOTE MENU: (Verbose) Finished parsing nominations for map group '%s'",
                catName);
            if (numMapsFromCat > 0)
            {
                LogMessage("VOTE MENU: (Verbose) Still need to fetch %i maps from the group.",
                    numMapsFromCat);
            }
        }
        
        //We no longer need the nominations array, so we close the handle.
        CloseHandle(nominationsFromCat);
        
        DEBUG_MESSAGE("Begin filling remaining spots in the vote.")
        //Add a map to the vote array from the current category while...
        //    ...maps still need to be added from the current category.
        while (numMapsFromCat > 0)
        {
            DEBUG_MESSAGE("Attempting to fetch a map from the group.")
            //Skip the category if...
            //    ...there are no more maps that can be added to the vote.
            if (!GetRandomMap(kv, mapName, sizeof(mapName)))
            {
                if (verboseLogs)
                    LogMessage("VOTE MENU: (Verbose) No more maps in map group '%s'", catName);
                DEBUG_MESSAGE("No more maps in group. Continuing to next group.")
                break;
            }

            //The name of the selected map is now stored in mapName.    
            
            DEBUG_MESSAGE("Checking to make sure the map isn't already in the vote.")
            //Remove the map from the category (so it cannot be selected again) and repick a map 
            //if...
            //    ...the map has already been added to the vote (through nomination or another 
            //       category
            if (!ignoreDupes && FindStringInVoteArray(mapName, MAP_TRIE_MAP_KEY, map_vote) != -1)
            {
                DEBUG_MESSAGE("Map found in vote. Removing from mapcycle.")
                KvDeleteSubKey(kv, mapName);
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
            
            DEBUG_MESSAGE("Searching for map in nominations.")
            //Find this map in the list of nominations.
            nomIndex = FindNominationIndex(mapName, catName);
            
            //Remove the nomination if...
            //    ...it was found.
            if (nomIndex != -1)
            {
                DEBUG_MESSAGE("Map found in nominations.")
                new Handle:nom = GetArrayCell(nominations_arr, nomIndex);
                
                DEBUG_MESSAGE("Calling nomination removal forward.")
                new owner;
                GetTrieValue(nom, "client", owner);
                
                Call_StartForward(nomination_reset_forward);
                Call_PushString(mapName);
                Call_PushCell(owner);
                Call_Finish();
                
                DEBUG_MESSAGE("Removing nomination.")
                new Handle:oldnomKV;
                GetTrieValue(nom, "mapcycle", oldnomKV);
                CloseHandle(oldnomKV);
                CloseHandle(nom);
                RemoveFromArray(nominations_arr, nomIndex);
                if (verboseLogs)
                {
                    LogMessage("VOTE MENU: (Verbose) Removing selected map '%s' from nominations.",
                        mapName);
                }
            }
            
            DEBUG_MESSAGE("Fetching extra info for the map from the mapcycle.")
            //Get extra fields from the map
            KvJumpToKey(kv, mapName);
            KvGetString(kv, "display", display, sizeof(display), gDisp);
            
            DEBUG_MESSAGE("Setting proper display string.")
            if (strlen(display) == 0)
                strcopy(display, sizeof(display), mapName);
            else 
                ReplaceString(display, sizeof(display), "{MAP}", mapName, false);
            
            KvGoBack(kv);
            
            DEBUG_MESSAGE("Determining where to place the map in the vote.")
            //Get the position in the vote array to add the map to.
            position = GetNextMenuIndex(voteCounter, scramble);
            
            DEBUG_MESSAGE("Adding map to the vote.")
                    
            new Handle:map = CreateMapTrie(mapName, catName);
            
            new Handle:mapMapcycle = CreateKeyValues("umc_mapcycle");
            KvCopySubkeys(mapcycle, mapMapcycle);
            
            SetTrieValue(map, "mapcycle", mapMapcycle);
            
            InsertArrayCell(map_vote, position, map);
            InsertArrayString(map_vote_display, position, display);
            
            //Increment number of maps added to the vote.
            voteCounter++;
            
            DEBUG_MESSAGE("Preventing map from being picked again.")
            //Delete the map from the KV so we can't pick it again.
            KvDeleteSubKey(kv, mapName);
            
            //One less map to be added to the vote from this category.
            numMapsFromCat--;
        }
    }
    while (KvGotoNextKey(kv)); //Do this for each category.
    
    DEBUG_MESSAGE("Vote now populated with maps.")
    
    //We no longer need the copy of the mapcycle
    CloseHandle(kv);
    
    DEBUG_MESSAGE("Initializing vote menu.")
    
    //Begin creating menu
    new Handle:menu = (GetConVarBool(cvar_valvemenu))
        ? CreateMenuEx(GetMenuStyleHandle(MenuStyle_Valve), Handle_VoteMenu,
                       MenuAction_DisplayItem|MenuAction_Display)
        : CreateMenu(Handle_VoteMenu, MenuAction_DisplayItem|MenuAction_Display);
        
    SetVoteResultCallback(menu, callback); //Set callback
    SetMenuExitButton(menu, false); //Don't want an exit button.
        
    //Set the title
    SetMenuTitle(menu, "Map Vote Menu Title");
    
    //Keep track of slots taken up in the vote.
    new voteSlots = blockSlots;
    
    DEBUG_MESSAGE("Setup slot blocking.")
    //Add blocked slots if...
    //    ...the cvar for blocked slots is enabled.
    AddSlotBlockingToMenu(menu, blockSlots);
    
    new Handle:infoArr = BuildNumArray(voteCounter);    
    
    DEBUG_MESSAGE("Adding maps to the menu.")
    //Add the array of maps to the menu.
    AddArrayToMenu(menu, infoArr, map_vote_display);
    CloseHandle(map_vote_display);
    CloseHandle(infoArr);
    
    //Update how many slots have been taken up in the vote.
    voteSlots += voteCounter;
    
    if (verboseLogs && scramble)
        LogMessage("VOTE MENU: (Verbose) Scrambling menu.");
    
    DEBUG_MESSAGE("Add extend or don't change options.")
    //Add an extend item if...
    //    ...the extend flag is true.
    if (extend)
    {
        if (GetConVarBool(cvar_extend_display))
            InsertMenuItem(menu, blockSlots, EXTEND_MAP_OPTION, "Extend Map");
        else
            AddMenuItem(menu, EXTEND_MAP_OPTION, "Extend Map");
        voteCounter++;
        voteSlots++;
    }
    //Add a don't change item if...
    //    ...the don't change flag is true.
    if (dontChange)
    {
        if (GetConVarBool(cvar_dontchange_display))
            InsertMenuItem(menu, blockSlots, DONT_CHANGE_OPTION, "Don't Change");
        else
            AddMenuItem(menu, DONT_CHANGE_OPTION, "Don't Change");
        voteCounter++;
        voteSlots++;
    }
    DEBUG_MESSAGE("Making sure there are enough items in the vote.")
    //Throw an error and return nothing if...
    //    ...the number of items in the vote is less than 2 (hence no point in voting).
    if (voteCounter <= 1)
    {
        DEBUG_MESSAGE("Not enough items in the vote. Aborting.")
        LogError("VOTING: Not enough maps to run a map vote. %i maps available.", voteCounter);
        CloseHandle(menu);
        ClearVoteArrays();
        return INVALID_HANDLE;
    }
    else //Otherwise, finish making the menu.
    {
        DEBUG_MESSAGE("Setting proper pagination.")
        SetCorrectMenuPagination(menu, voteSlots);
        DEBUG_MESSAGE("Vote menu built successfully.")
        return menu; //Return the finished menu (finally).
    }
}


//Builds and returns a menu for a category vote.
//    callback:   function to be called when the vote is finished.
//    scramble:   whether the menu items are in a random order (true) or in the order the categories 
//                are listed in the cycle.
//    extend:     whether an extend option should be added to the vote.
//    dontChange: whether a "Don't Change" option should be added to the vote.
Handle:BuildCatVoteMenu(Handle:okv, Handle:mapcycle, VoteHandler:callback, bool:scramble,
                        bool:extend, bool:dontChange, blockSlots=0, bool:strictNoms=false,
                        bool:exclude=true)
{
    //Throw an error and return nothing if...
    //    ...the mapcycle is invalid.
    if (okv == INVALID_HANDLE)
    {
        LogError("VOTING: Cannot build map group vote menu, rotation file is invalid.");
        return INVALID_HANDLE;
    }
    
    //Rewind our mapcycle.
    KvRewind(okv); //rewind original
    new Handle:kv = CreateKeyValues("umc_rotation"); //new handle
    KvCopySubkeys(okv, kv);
    
    //Log an error and return nothing if...
    //    ...it cannot find a category.
    if (!KvGotoFirstSubKey(kv))
    {
        LogError("VOTING: No map groups found in rotation. Vote menu was not built.");
        CloseHandle(kv);
        return INVALID_HANDLE;
    }
    
    ClearVoteArrays();
    
    new bool:verboseLogs = GetConVarBool(cvar_logging);
    
    decl String:catName[MAP_LENGTH]; //Buffer to store category name in.
    decl String:mapName[MAP_LENGTH];
    decl String:nomGroup[MAP_LENGTH];
    new voteCounter = 0;      //Number of categories in the vote.
    new Handle:catArray = CreateArray(ByteCountToCells(MAP_LENGTH), 0); //Array of categories in the vote.
    
    new Handle:catNoms = INVALID_HANDLE;
    new Handle:nom = INVALID_HANDLE;
    new size;
    new bool:haveNoms = false;
    
    new Handle:nomKV;
    new Handle:nomMapcycle;
    
    //Add the current category to the vote.
    do
    {
        KvGetSectionName(kv, catName, sizeof(catName));
        
        haveNoms = false;
        
        if (exclude)
        {
            catNoms = GetCatNominations(catName);
            size = GetArraySize(catNoms);
            for (new i = 0; i < size; i++)
            {
                nom = GetArrayCell(catNoms, i);
                GetTrieValue(nom, "mapcycle", nomMapcycle);
                
                nomKV = CreateKeyValues("umc_rotation");
                KvCopySubkeys(nomMapcycle, nomKV);
                
                GetTrieString(nom, "nom_group", nomGroup, sizeof(nomGroup));
                
                GetTrieString(nom, MAP_TRIE_MAP_KEY, mapName, sizeof(mapName));
                
                KvJumpToKey(nomKV, nomGroup);
                
                if (IsValidMapFromCat(nomKV, nomMapcycle, mapName, .isNom=true))
                {
                    haveNoms = true;            
                    CloseHandle(nomKV);
                    break;
                }
                
                CloseHandle(nomKV);
            }
            CloseHandle(catNoms);
        }
        else if (!KvGotoFirstSubKey(kv))
        {
            if (verboseLogs)
            {
                LogMessage(
                    "VOTE MENU: (Verbose) Skipping empty map group '%s'.",
                    catName
                );
            }
            continue;
        }
        else
        {
            KvGoBack(kv);
            haveNoms = true;
        }
        
        //Skip this category if...
        //    ...the server doesn't have the required amount of players or all maps are excluded OR
        //    ...the number of maps in the vote from the category is less than 1.
        if (!haveNoms)
        {
            if (!IsValidCat(kv, mapcycle))
            {
                if (verboseLogs)
                {
                    LogMessage(
                        "VOTE MENU: (Verbose) Skipping excluded map group '%s'.",
                        catName
                    );
                }
                continue;
            }
            else if (KvGetNum(kv, "maps_invote", 1) < 1 && strictNoms)
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
        }
        
        if (verboseLogs)
            LogMessage("VOTE MENU: (Verbose) Group '%s' was added to the vote.", catName);
        
        //Add category to the vote array...
        InsertArrayString(catArray, GetNextMenuIndex(voteCounter, scramble), catName);
        
        //Increment number of categories in the vote.
        voteCounter++;
    }
    while (KvGotoNextKey(kv)); //Do this for each category.
    
    //No longer need the copied mapcycle
    CloseHandle(kv);
    
    //Begin creating menu
    new Handle:menu = (GetConVarBool(cvar_valvemenu))
        ? CreateMenuEx(GetMenuStyleHandle(MenuStyle_Valve), Handle_VoteMenu,
                       MenuAction_DisplayItem|MenuAction_Display)
        : CreateMenu(Handle_VoteMenu, MenuAction_DisplayItem|MenuAction_Display);
    
    SetVoteResultCallback(menu, callback);    //Set callback
    SetMenuExitButton(menu, false); //Disable exit button
    
    //Set the title
    SetMenuTitle(menu, "Group Vote Menu Title");
    
    //Keep track of slots taken up in the vote.
    new voteSlots = blockSlots;

    //Add slot blocking
    AddSlotBlockingToMenu(menu, blockSlots);
    
    //Add array of votes to the menu.
    AddArrayToMenu(menu, catArray);
    voteSlots += GetArraySize(catArray);

    //We no longer need the vote array, so we close the handle.
    CloseHandle(catArray);

    //Add an extend item if...
    //    ...the extend flag is true.
    if (extend)
    {
        if (GetConVarBool(cvar_extend_display))
            InsertMenuItem(menu, blockSlots, EXTEND_MAP_OPTION, "Extend Map");
        else
            AddMenuItem(menu, EXTEND_MAP_OPTION, "Extend Map");
        voteCounter++;
        voteSlots++;
    }
    //Add a don't change item if...
    //    ...the don't change flag is true.
    if (dontChange)
    {
        if (GetConVarBool(cvar_dontchange_display))
            InsertMenuItem(menu, blockSlots, DONT_CHANGE_OPTION, "Don't Change");
        else
            AddMenuItem(menu, DONT_CHANGE_OPTION, "Don't Change");
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
    else //Otherwise, finish making the menu.
    {
        SetCorrectMenuPagination(menu, voteSlots);
        return menu; //Return our finished menu!
    }
}


//Adds slot blocking to a menu
AddSlotBlockingToMenu(Handle:menu, blockSlots)
{
    //Add blocked slots if...
    //    ...the cvar for blocked slots is enabled.
    if (blockSlots > 3)
        AddMenuItem(menu, NOTHING_OPTION, "", ITEMDRAW_SPACER);
    if (blockSlots > 0)
        AddMenuItem(menu, NOTHING_OPTION, "Slot Block Message 1", ITEMDRAW_DISABLED);
    if (blockSlots > 1)
        AddMenuItem(menu, NOTHING_OPTION, "Slot Block Message 2", ITEMDRAW_DISABLED);
    if (blockSlots > 2)
        AddMenuItem(menu, NOTHING_OPTION, "", ITEMDRAW_SPACER);
    if (blockSlots > 4)
        AddMenuItem(menu, NOTHING_OPTION, "", ITEMDRAW_SPACER);
}


//Selects a random map from a category based off of the supplied weights for the maps.
//    kv:     a mapcycle whose traversal stack is currently at the level of the category to choose 
//            from.
//    buffer:    a string to store the selected map in
//    key:  the key containing the weight information (for maps, 'weight', for cats, 'group_weight')
//    excluded: an adt_array of maps to exclude from the selection.
//bool:GetRandomMap(Handle:kv, String:buffer[], size, Handle:excluded, Handle:excludedCats, 
//                  bool:isNom=false, bool:forMapChange=true, bool:memory=true)
bool:GetRandomMap(Handle:kv, String:buffer[], size)
{
    decl String:catName[MAP_LENGTH];
    KvGetSectionName(kv, catName, sizeof(catName));
    
    DEBUG_MESSAGE("Preparing mapcycle for random map selection.")
    //Return failure if...
    //    ...there are no maps in the category.
    if (!KvGotoFirstSubKey(kv))
    {
        DEBUG_MESSAGE("No maps found in map group %s. Return false.", catName)
        return false;
    }

    DEBUG_MESSAGE("Preparing to traverse maps in the group.")
    new index = 0; //counter of maps in the random pool
    new Handle:nameArr = CreateArray(ByteCountToCells(MAP_LENGTH)); //Array to store possible map names
    new Handle:weightArr = CreateArray();  //Array to store possible map weights.
    decl String:temp[MAP_LENGTH]; //Buffer to store map names in.
    
    //Add a map to the random pool.
    do
    {    
        //Get the name of the map.
        KvGetSectionName(kv, temp, sizeof(temp));
        
        DEBUG_MESSAGE("Adding map %s to the pool.", temp)
        
        //Add the map to the random pool.
        PushArrayCell(weightArr, GetWeight(kv));
        PushArrayString(nameArr, temp);
        
        //One more map in the pool.
        index++;
    }
    while (KvGotoNextKey(kv)); //Do this for each map.
    
    DEBUG_MESSAGE("Finished populating random pool.")
    
    //Go back to the category level.
    KvGoBack(kv);

    //Close pool and fail if...
    //    ...no maps are selectable.
    if (index == 0)
    {
        DEBUG_MESSAGE("No maps found in pool. Returning false.")
        CloseHandle(nameArr);
        CloseHandle(weightArr);
        return false;
    }

    DEBUG_MESSAGE("Getting random map from the pool.")
    
    //Use weights to randomly select a map from the pool.
    new bool:result = GetWeightedRandomSubKey(buffer, size, weightArr, nameArr, _);
    
    //Close the pool.
    CloseHandle(nameArr);
    CloseHandle(weightArr);
    
    //Done!
    return result;
}


//Searches array for given string. Returns -1 on failure.
FindStringInVoteArray(const String:target[], const String:val[], Handle:arr)
{
    new size = GetArraySize(arr);
    decl String:buffer[MAP_LENGTH];
    for (new i = 0; i < size; i++)
    {
        GetTrieString(GetArrayCell(arr, i), val, buffer, sizeof(buffer));
        if (StrEqual(buffer, target))
            return i;
    }
    return -1;
}


//Called when a vote has finished.
public Handle_VoteMenu(Handle:menu, MenuAction:action, param1, param2)
{
    //DEBUG_MESSAGE("Vote Handler Called")
    //Cleanup the memory taken by the vote if...
    //    ...the vote is actually over.
    switch(action)
    {
        case MenuAction_End:
        {
            DEBUG_MESSAGE("MenuAction_End")
            CloseHandle(menu);
        }
        case MenuAction_VoteCancel:
        {
            DEBUG_MESSAGE("Vote Cancelled")
            VoteCancelled();
        }
        case MenuAction_Display:
        {
            //LogMessage("DEBUG: Display");
            new Handle:panel = Handle:param2;
            
            decl String:phrase[255];
            GetMenuTitle(menu, phrase, sizeof(phrase));
            
            decl String:buffer[255];
            Format(buffer, sizeof(buffer), "%T", phrase, param1);
            
            SetPanelTitle(panel, buffer);
        }
        case MenuAction_DisplayItem:
        {
            //LogMessage("DEBUG: DisplayItem");
            decl String:map[MAP_LENGTH], String:display[MAP_LENGTH];
            GetMenuItem(menu, param2, map, sizeof(map), _, display, sizeof(display));
            
            if (StrEqual(map, EXTEND_MAP_OPTION) || StrEqual(map, DONT_CHANGE_OPTION) ||
                (StrEqual(map, NOTHING_OPTION) && strlen(display) > 0))
            {
                decl String:buffer[255];
                Format(buffer, sizeof(buffer), "%T", display, param1);
                
                return RedrawMenuItem(buffer);
            }
        }
    }
    return 0;
}


//Called right after the vote menu is destroyed.
VoteCancelled()
{
    //Catches the case where a vote occurred but nobody voted.
    if (vote_active)
    {
        LogMessage("Map vote ended with no votes.");
    
        //Reset flags
        vote_active = false;
        
        //Cleanup the vote
        EmptyStorage();
        DeleteVoteParams();
        ClearVoteArrays();
        
        VoteFailed();
    }
}


//Utility function to clear all the voting storage arrays.
ClearVoteArrays()
{
    new size = GetArraySize(map_vote);
    new Handle:mapTrie;
    new Handle:kv;
    for (new i = 0; i < size; i++)
    {
        mapTrie = GetArrayCell(map_vote, i);
        GetTrieValue(mapTrie, "mapcycle", kv);
        CloseHandle(kv);
        CloseHandle(mapTrie);
    }
    ClearArray(map_vote);
}


//Get the winner from a vote.
any:GetWinner()
{
    new counter = 1;
    new Handle:voteItem = GetArrayCell(vote_storage, 0);
    new Handle:voteClients = INVALID_HANDLE;
    GetTrieValue(voteItem, "clients", voteClients);
    new most_votes = GetArraySize(voteClients);
    new num_items = GetArraySize(vote_storage);
    while (counter < num_items)
    {
        GetTrieValue(GetArrayCell(vote_storage, counter), "clients", voteClients);
        if (GetArraySize(voteClients) < most_votes)
            break;
        counter++;
    }
    if (counter > 1)
        return GetArrayCell(vote_storage, GetRandomInt(0, counter - 1));
    else
        return GetArrayCell(vote_storage, 0);
}


//Generates a list of categories to be excluded from the second stage of a tiered vote.
stock Handle:MakeSecondTieredCatExclusion(Handle:kv, const String:cat[])
{
    //Log an error and return nothing if...
    //  ...there are no categories in the cycle (for some reason).
    if (!KvJumpToKey(kv, cat))
    {
        LogError("TIERED VOTE: Cannot create second stage of vote, rotation file is invalid (no groups were found.)");
        return INVALID_HANDLE;
    }
    
    //Array to return at the end.
    new Handle:result = CreateKeyValues("umc_rotation");
    KvJumpToKey(result, cat, true);
    
    KvCopySubkeys(kv, result);
    
    //Return to the root.
    KvGoBack(kv);
    KvGoBack(result);
    
    //Success!
    return result;
}


//Updates the display for the interval between tiered votes.
DisplayTierMessage(timeleft)
{
    decl String:msg[255], String:notification[10];
    Format(msg, sizeof(msg), "%t", "Another Vote", timeleft);
    GetConVarString(cvar_vote_tierdisplay, notification, sizeof(notification));
    DisplayServerMessage(msg, notification);
}


//Empties the vote storage
EmptyStorage()
{
    new size = GetArraySize(vote_storage);
    for (new i = 0; i < size; i++)
        RemoveFromStorage(0);
    total_votes = 0;
}


//Removes a vote item from the storage
RemoveFromStorage(index)
{
    new Handle:stored = GetArrayCell(vote_storage, index);
    new Handle:clients = INVALID_HANDLE;
    GetTrieValue(stored, "clients", clients);
    total_votes -= GetArraySize(clients);
    CloseHandle(clients);
    CloseHandle(stored);
    RemoveFromArray(vote_storage, index);
}


//Gets the winning info for the vote
GetVoteWinner(String:info[], maxinfo, &Float:percentage, String:disp[]="", maxdisp=0)
{
    new Handle:winner = GetWinner();
    new Handle:clients = INVALID_HANDLE;
    GetTrieString(winner, "info", info, maxinfo);
    GetTrieString(winner, "disp", disp, maxdisp);
    GetTrieValue(winner, "clients", clients);
    percentage = float(GetArraySize(clients)) / total_votes * 100;
}


//Finds the index of the given vote item in the storage array. Returns -1 on failure.
FindVoteInStorage(const String:info[])
{
    new arraySize = GetArraySize(vote_storage);
    new Handle:vote = INVALID_HANDLE;
    decl String:infoBuf[255];
    for (new i = 0; i < arraySize; i++)
    {
        vote = GetArrayCell(vote_storage, i);
        GetTrieString(vote, "info", infoBuf, sizeof(infoBuf));
        if (StrEqual(info, infoBuf))
            return i;
    }
    return -1;
}


//Comparison function for stored vote items. Used for sorting.
public CompareStoredVoteItems(index1, index2, Handle:array, Handle:hndl)
{
    new size1, size2;
    new Handle:vote = INVALID_HANDLE;
    new Handle:clientArray = INVALID_HANDLE;
    vote = GetArrayCell(array, index1);
    GetTrieValue(vote, "clients", clientArray);
    size1 = GetArraySize(clientArray);
    vote = GetArrayCell(array, index2);
    GetTrieValue(vote, "clients", clientArray);
    size2 = GetArraySize(clientArray);
    return size2 - size1;
}


//Adds vote results to the vote storage
AddToStorage(Handle:menu, num_votes, num_items, const item_info[][2], num_clients,
             const client_info[][2])
{
    prev_vote_count = GetArraySize(vote_storage);
    
    new String:infoBuffer[255], String:dispBuffer[255];
    new storageIndex;
    new Handle:voteItem = INVALID_HANDLE;
    new Handle:voteClientArray = INVALID_HANDLE;
    new itemIndex;
    for (new i = 0; i < num_items; i++)
    {
        itemIndex = item_info[i][VOTEINFO_ITEM_INDEX];
        GetMenuItem(menu, itemIndex, infoBuffer, sizeof(infoBuffer), _, 
                    dispBuffer, sizeof(dispBuffer));
        storageIndex = FindVoteInStorage(infoBuffer);
        if (storageIndex == -1)
        {
            voteItem = CreateTrie();
            voteClientArray = CreateArray();
            SetTrieString(voteItem, "info", infoBuffer);
            SetTrieString(voteItem, "disp", dispBuffer);
            SetTrieValue(voteItem, "clients", voteClientArray);
            PushArrayCell(vote_storage, voteItem);
        }
        else
        {
            voteItem = GetArrayCell(vote_storage, storageIndex);
            GetTrieValue(voteItem, "clients", voteClientArray);
        }
        
        for (new j = 0; j < num_clients; j++)
        {
            if (client_info[j][VOTEINFO_CLIENT_ITEM] == itemIndex)
                PushArrayCell(voteClientArray, client_info[j][VOTEINFO_CLIENT_INDEX]);
        }
    }
    SortADTArrayCustom(vote_storage, CompareStoredVoteItems);
    total_votes += num_votes;
}


//Handles the results of a vote
ProcessVoteResults(Handle:menu, num_votes, num_clients, const client_info[][2], num_items,
                   const item_info[][2], VoteHandler:runoff_callback, Function:winner_callback)
{
    DEBUG_MESSAGE("Processing vote results")
    
    //Vote is no longer running.
    vote_active = false;

    //Adds these results to the storage.
    AddToStorage(menu, num_votes, num_items, item_info, num_clients, client_info);
    
    //Perform a runoff vote if it is necessary.
    if (NeedRunoff())
    {
        //If we can't runoff anymore
        if (remaining_runoffs == 0 || prev_vote_count == 2)
        {
            DEBUG_MESSAGE("Can't runoff, performing failure action.")
            if (stored_fail_action == RunoffFailAction_Accept)
            {
                ProcessVoteWinner(winner_callback);
            }
            else if (stored_fail_action == RunoffFailAction_Nothing)
            {
                new Float:percentage;
                GetVoteWinner("", 0, percentage, "", 0);
                PrintToChatAll(
                    "\x03[UMC]\x01 %t (%t)",
                    "Vote Failed",
                    "Vote Win Percentage",
                        percentage,
                        total_votes
                );
                LogMessage("MAPVOTE: Vote failed, winning map did not reach threshold.");
                VoteFailed();                
                DeleteVoteParams();
                ClearVoteArrays();
            }
            EmptyStorage();
        }
        else
        {
            DoRunoffVote(menu, runoff_callback);
        }
    }
    else //Otherwise set the results.
    {
        ProcessVoteWinner(winner_callback);
        EmptyStorage();
    }
}


//Processes the winner from the vote.
ProcessVoteWinner(Function:callback)
{
    //Detemine winner information.
    decl String:winner[255], String:disp[255];
    new Float:percentage;
    GetVoteWinner(winner, sizeof(winner), percentage, disp, sizeof(disp));
    
    //Call the appropriate VoteWinnerHandler
    Call_StartFunction(INVALID_HANDLE, callback);
    Call_PushString(winner);
    Call_PushString(disp);
    Call_PushFloat(percentage);
    Call_Finish();
}


//Determines if a runoff vote is needed.
bool:NeedRunoff()
{
    DEBUG_MESSAGE("Determining if the vote meets the defined threshold of %f", stored_threshold)
    
    //Get the winning vote item.
    new Handle:voteItem = GetArrayCell(vote_storage, 0);
    new Handle:clients = INVALID_HANDLE;
    GetTrieValue(voteItem, "clients", clients);
    
    new numClients = GetArraySize(clients);
    new bool:result = (float(numClients) / total_votes) < stored_threshold;
    return result;
}


//Sets up a runoff vote.
DoRunoffVote(Handle:menu, VoteHandler:callback)
{   
    DEBUG_MESSAGE("Performing runoff vote")
    
    remaining_runoffs--;

    //Array to store clients the menu will be displayed to.
    runoff_clients = CreateArray();
    
    //Build the runoff vote based off of the results of the failed vote.
    runoff_menu = BuildRunoffMenu(menu, callback, runoff_clients);

    //Setup the timer if...
    //  ...the menu was built successfully
    if (runoff_menu != INVALID_HANDLE)
    {        
        //Empty storage if we're revoting completely.
        if (!GetConVarBool(cvar_runoff_selective))
            EmptyStorage();
        
        //Setup timer to delay the start of the runoff vote.
        runoff_delay = 7;
        
        //Display the first message
        DisplayRunoffMessage(runoff_delay+1);
        
        DEBUG_MESSAGE("Runoff timer created. Runoff vote will be displayed in %i seconds.", runoff_delay + 1)
        
        //Setup data pack to go along with the timer.
        //new Handle:pack;    
        CreateTimer(
            1.0,
            Handle_RunoffVoteTimer,
            INVALID_HANDLE, //pack,
            TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT
        );
        //Add info to the pack.
        //WritePackString(pack, sound);
    }
    else //Otherwise, cleanup
    {
        LogError("RUNOFF: Unable to create runoff vote menu, runoff aborted.");
        CloseHandle(runoff_clients);
        VoteFailed();
        EmptyStorage();
        DeleteVoteParams();
        ClearVoteArrays();
    }
}


//Builds a runoff vote menu.
//  menu:           the menu of the original vote we're running off from
//  callback:       VoteHandler to be called when the voting is finished
//  clientArray:    adt_array to be populated with clients whose votes were eliminated
Handle:BuildRunoffMenu(Handle:menu, VoteHandler:callback, Handle:clientArray)
{
    new bool:verboseLogs = GetConVarBool(cvar_logging);
    if (verboseLogs)
        LogMessage("RUNOFF MENU: (Verbose) Building runoff vote menu.");
    
    new Float:runoffThreshold = stored_threshold;
    
    //Copy the current total number of votes. Needed because the number will change as we remove items.
    new totalVotes = total_votes;
    
    new Handle:voteItem = INVALID_HANDLE;
    new Handle:voteClients = INVALID_HANDLE;
    new voteNumVotes;
    new num_items = GetArraySize(vote_storage);
    
    //Array determining which clients have voted
    new bool:clientVotes[MAXPLAYERS];
    for (new i = 0; i < num_items; i++)
    {
        voteItem = GetArrayCell(vote_storage, i);
        GetTrieValue(voteItem, "clients", voteClients);
        voteNumVotes = GetArraySize(voteClients);
        
        for (new j = 0; j < voteNumVotes; j++)
            clientVotes[GetArrayCell(voteClients, j)] = true;
    }
    for (new i = 0; i < sizeof(clientVotes); i++)
    {
        if (!clientVotes[i])
            PushArrayCell(clientArray, i);
    }
    
    new Handle:winning = GetArrayCell(vote_storage, 0);
    new winningNumVotes;
    new Handle:winningClients = INVALID_HANDLE;
    GetTrieValue(winning, "clients", winningClients);
    winningNumVotes = GetArraySize(winningClients);
    
    //Starting max possible percentage of the winning item in this vote.
    new Float:percent = float(winningNumVotes) / float(totalVotes) * 100;
    new Float:newPercent;
    
    //Max number of maps in the runoff vote
    new maxMaps = stored_runoffmaps_max;
    new bool:checkMax = maxMaps > 1;
    
    //Starting at the item with the least votes, calculate the new possible max percentage
    //of the winning item. Stop when this percentage is greater than the threshold.
    for (new i = num_items - 1; i > 1; i--)
    {
        voteItem = GetArrayCell(vote_storage, i);
        GetTrieValue(voteItem, "clients", voteClients);
        voteNumVotes = GetArraySize(voteClients);
        ArrayAppend(clientArray, voteClients);
        
        newPercent = float(voteNumVotes) / float(totalVotes) * 100;
        percent += newPercent;
        
        if (verboseLogs)
        {
            decl String:dispBuf[255];
            GetTrieString(voteItem, "disp", dispBuf, sizeof(dispBuf));
            LogMessage(
                "RUNOFF MENU: (Verbose) '%s' was removed from the vote. It had %i votes (%.f%% of total)",
                dispBuf, voteNumVotes, newPercent
            );
        }
        
        //No longer store the map
        RemoveFromStorage(i);
        num_items--;
        
        //Stop if...
        //  ...the new percentage is over the threshold AND
        //  ...the number of maps in the vote is under the max.
        if (percent >= runoffThreshold && (!checkMax || num_items <= maxMaps))
            break;
    }
    
    if (verboseLogs)
    {
        LogMessage(
            "RUNOFF MENU: (Verbose) Stopped removing options from the vote. Maximum possible winning vote percentage is %.f%%.",
            percent
        );
    }
    
    //Start building the new vote menu.
    new Handle:newMenu = CreateMenu(Handle_VoteMenu, MenuAction_DisplayItem|MenuAction_Display);
    SetVoteResultCallback(newMenu, callback);
    SetMenuExitButton(newMenu, false);
    
    //Set the menu title to the old one.
    new String:title[255];
    GetMenuTitle(menu, title, sizeof(title));
    SetMenuTitle(newMenu, title);
    
    new voteSlots = 0;
    
    //Add blocked slots.
    if (GetConVarBool(cvar_runoff_slots))
    {
        voteSlots += stored_blockslots;
        AddSlotBlockingToMenu(newMenu, stored_blockslots);
    }
    
    //Populate the new menu with what remains of the storage.
    new count = 0;
    decl String:info[255], String:disp[255];
    for (new i = 0; i < num_items; i++)
    {
        voteItem = GetArrayCell(vote_storage, i);
        GetTrieString(voteItem, "info", info, sizeof(info));
        GetTrieString(voteItem, "disp", disp, sizeof(disp));
        AddMenuItem(newMenu, info, disp);
        count++;
        voteSlots++;
    }
    
    //Log an error and do nothing if...
    //  ...there weren't enough items added to the runoff vote.
    //  *This shouldn't happen if the algorithm is working correctly*
    if (count < 2)
    {
        CloseHandle(newMenu);
        LogError(
            "RUNOFF: Not enough remaining maps to perform runoff vote. %i maps remaining. Please notify plugin author.",
            count
        );
        return INVALID_HANDLE;
    }
    
    //Set the proper pagination.
    SetCorrectMenuPagination(newMenu, voteSlots);
    
    return newMenu;
}
                       
                       
//Called when the runoff timer for an end-of-map vote completes.
public Action:Handle_RunoffVoteTimer(Handle:timer)
{
    if (!vote_inprogress)
    {
        VoteFailed();
        EmptyStorage();
        DeleteVoteParams();
        ClearVoteArrays();
        return Plugin_Stop;
    }
    
    DisplayRunoffMessage(runoff_delay);

    //Display a message and continue timer if...
    //  ...the timer hasn't finished yet.
    if (runoff_delay > 0)
    {
        runoff_delay--;
        return Plugin_Continue;
    }

    LogMessage("RUNOFF: Starting runoff vote.");
    
    //Log an error and do nothing if...
    //    ...another vote is currently running for some reason.
    if (IsVoteInProgress()) 
    {
        //LogMessage("RUNOFF: There is a vote already in progress, cannot start a new vote.");
        return Plugin_Continue;
    }
    
    //Setup array of clients to display the vote to.
    new clients[MAXPLAYERS];
    ConvertArray(runoff_clients, clients, sizeof(clients));
    new numClients = GetArraySize(runoff_clients);
    CloseHandle(runoff_clients);
    
    //Play the vote start sound if...
    //  ...the filename is defined.
    if (strlen(stored_runoff_sound) > 0)
        EmitSoundToAll(stored_runoff_sound);
    //Otherwise, play the sound for end-of-map votes if...
    //  ...the filename is defined.
    else if (strlen(stored_start_sound) > 0)
        EmitSoundToAll(stored_start_sound);
    
    //Run the vote to selected client only if...
    //  ...the cvar to do so is enabled.
    if (GetConVarBool(cvar_runoff_selective))
    {
        //Log an error if...
        //    ...the vote cannot start for some reason.
        if (!VoteMenu(runoff_menu, clients, numClients, stored_votetime))
            LogMessage("RUNOFF: Menu already has a vote in progress, cannot start a new vote.");
        else
        {
            PrintToChatAll("\x03[UMC]\x01 %t", "Selective Runoff");
            vote_active = true;
        }
    }
    //Otherwise, just display it to everybody.
    else
    {
        //Log an error if...
        //    ...the vote cannot start for some reason.
        if (!VoteMenuToAllWithFlags(runoff_menu, stored_votetime, stored_adminflags))
            LogMessage("RUNOFF: Menu already has a vote in progress, cannot start a new vote.");
        else
            vote_active = true;
    }

    return Plugin_Stop;
}


//Displays a notification for the impending runoff vote.
DisplayRunoffMessage(timeRemaining)
{
    decl String:msg[255], String:notification[10];
    if (timeRemaining > 5)
        Format(msg, sizeof(msg), "%t", "Runoff Msg");
    else
        Format(msg, sizeof(msg), "%t", "Another Vote", timeRemaining);
    GetConVarString(cvar_runoff_display, notification, sizeof(notification));
    DisplayServerMessage(msg, notification);
}


//Handles the results of an end-of-map map vote.
public Handle_MapVoteResults(Handle:menu, num_votes, num_clients, const client_info[][2], num_items,
                             const item_info[][2])
{
    ProcessVoteResults(menu, num_votes, num_clients, client_info, num_items, item_info,
                       Handle_MapVoteResults, Handle_MapVoteWinner);
}


//Handles the winner of an end-of-map map vote.
public Handle_MapVoteWinner(const String:info[], const String:disp[], Float:percentage)
{
    //vote_completed = true;

    //Print a message and extend the current map if...
    //    ...the server voted to extend the map.
    if (StrEqual(info, EXTEND_MAP_OPTION))
    {
        PrintToChatAll(
            "\x03[UMC]\x01 %t %t (%t)",
            "End of Map Vote Over",
            "Map Extended",
            "Vote Win Percentage",
                percentage,
                total_votes
        );
        LogMessage("MAPVOTE: Players voted to extend the map.");
        ExtendMap();
    }
    else if (StrEqual(info, DONT_CHANGE_OPTION))
    {
        PrintToChatAll(
            "\x03[UMC]\x01 %t %t (%t)",
            "End of Map Vote Over",
            "Map Unchanged",
            "Vote Win Percentage",
                percentage,
                total_votes
        );
        
        LogMessage("MAPVOTE: Players voted to stay on the map (Don't Change).");
        VoteFailed();
    }
    else //Otherwise, we print a message and then set the new map.
    {
        PrintToChatAll(
            "\x03[UMC]\x01 %t %t (%t)",
            "End of Map Vote Over",
            "End of Map Vote Map Won",
                disp,
            "Vote Win Percentage",
                percentage,
                total_votes
        );
        
        //Find the index of the winning map in the stored vote array.
        new index = StringToInt(info);
        decl String:map[MAP_LENGTH], String:group[MAP_LENGTH];
        
        new Handle:mapData = GetArrayCell(map_vote, index);
        GetTrieString(mapData, MAP_TRIE_MAP_KEY, map, sizeof(map));
        GetTrieString(mapData, MAP_TRIE_GROUP_KEY, group, sizeof(group));

        new Handle:mapcycle;
        GetTrieValue(mapData, "mapcycle", mapcycle);
        
        //Set it.
        DoMapChange(change_map_when, mapcycle, map, group, stored_reason, disp);
        
        LogMessage("MAPVOTE: Players voted for map '%s' from group '%s'", map, group);
    }
    
    //Play the vote completed sound if...
    //  ...the vote completed sound is defined.
    if (strlen(stored_end_sound) > 0)
        EmitSoundToAll(stored_end_sound);
    
    //No longer need the vote array.
    ClearVoteArrays();
    DeleteVoteParams();
}


//Handles the results of an end-of-map category vote.
public Handle_CatVoteResults(Handle:menu, num_votes, num_clients, const client_info[][2], num_items,
                             const item_info[][2])
{
    ProcessVoteResults(menu, num_votes, num_clients, client_info, num_items, item_info,
                       Handle_CatVoteResults, Handle_CatVoteWinner);
}


//Handles the winner of an end-of-map category vote.
public Handle_CatVoteWinner(const String:cat[], const String:disp[], Float:percentage)
{
    DEBUG_MESSAGE("Handling group vote winner: %s", cat)
    //vote_completed = true;
    
    //Print a message and extend the map if...
    //    ...the server voted to extend the map.
    if (StrEqual(cat, EXTEND_MAP_OPTION))
    {
        DEBUG_MESSAGE("Map was extended")
        PrintToChatAll(
            "\x03[UMC]\x01 %t %t (%t)",
            "End of Map Vote Over",
            "Map Extended",
            "Vote Win Percentage",
                percentage,
                total_votes
        );
        LogMessage("Players voted to extend the map.");
        ExtendMap();
    }
    else if (StrEqual(cat, DONT_CHANGE_OPTION))
    {
        DEBUG_MESSAGE("Map was not changed.")
        PrintToChatAll(
            "\x03[UMC]\x01 %t %t (%t)",
            "End of Map Vote Over",
            "Map Unchanged",
            "Vote Win Percentage",
                percentage,
                total_votes
        );
        
        LogMessage("Players voted to stay on the map (Don't Change).");
        VoteFailed();
    }
    else //Otherwise, we pick a random map from the category and set that as the next map.
    {
        decl String:map[MAP_LENGTH];
        
        DEBUG_MESSAGE("Rewinding and copying the mapcycle")
        
        //Rewind the mapcycle.
        KvRewind(stored_kv); //rewind original
        new Handle:kv = CreateKeyValues("umc_rotation");
        KvCopySubkeys(stored_kv, kv);
                    
        //Jump to the category in the mapcycle.
        KvJumpToKey(kv, cat);
        
        if (stored_exclude)
        {
            DEBUG_MESSAGE("Filtering the map group")
            FilterMapGroup(kv, stored_mapcycle);
#if UMC_DEBUG
            PrintKv(kv);
#endif
        }
        
        DEBUG_MESSAGE("Weighting map group")

        WeightMapGroup(kv, stored_mapcycle);
        
        new Handle:nominationsFromCat;
        
        //An adt_array of nominations from the given category.
        if (stored_exclude)
        {
            DEBUG_MESSAGE("Filtering Nominations")
            new Handle:tempCatNoms = GetCatNominations(cat);
            nominationsFromCat = FilterNominationsArray(tempCatNoms);
            CloseHandle(tempCatNoms);
        }
        else
            nominationsFromCat = GetCatNominations(cat);
        
        //if...
        //    ...there are nominations for this category.
        if (GetArraySize(nominationsFromCat) > 0)
        {
            DEBUG_MESSAGE("Processing nomination(s)")
        
            //Array of nominated map names.
            new Handle:nameArr = CreateArray(ByteCountToCells(MAP_LENGTH));
            
            //Array of nominated map weights (linked to the previous by index).
            new Handle:weightArr = CreateArray();
            
            new Handle:cycleArr = CreateArray();
            
            //Buffer to store the map name
            decl String:nameBuffer[MAP_LENGTH];
            decl String:nomGroup[MAP_LENGTH];
            
            //A nomination.
            new Handle:trie = INVALID_HANDLE;
            
            new Handle:nomKV;
            
            new index;
            
            //Add nomination to name and weight array for...
            //    ...each nomination in the nomination array for this category.
            new arraySize = GetArraySize(nominationsFromCat);
            for (new i = 0; i < arraySize; i++)
            {
                //Get the nomination at the current index.
                trie = GetArrayCell(nominationsFromCat, i);
                
                //Get the map name from the nomination.
                GetTrieString(trie, MAP_TRIE_MAP_KEY, nameBuffer, sizeof(nameBuffer));    
                
                GetTrieValue(trie, "mapcycle", nomKV);
                
                //Add the map to the map name array.
                PushArrayString(nameArr, nameBuffer);
                PushArrayCell(weightArr, GetMapWeight(nomKV, nameBuffer, cat));
                PushArrayCell(cycleArr, trie);
            }
            
            //Pick a random map from the nominations if...
            //    ...there are nominations to choose from.
            if (GetWeightedRandomSubKey(map, sizeof(map), weightArr, nameArr, index))
            {
                DEBUG_MESSAGE("Selecting random nomination")
            
                trie = GetArrayCell(cycleArr, index);
                
                GetTrieValue(trie, "mapcycle", nomKV);
                
                GetTrieString(trie, "nom_group", nomGroup, sizeof(nomGroup));
                
                DoMapChange(change_map_when, nomKV, map, nomGroup, stored_reason, map);
            }
            else //Otherwise, we select a map randomly from the category.
            {
                DEBUG_MESSAGE("Couldn't select a random nomination [you shouldn't ever see this...]")
            
                GetRandomMap(kv, map, sizeof(map));
                DoMapChange(change_map_when, stored_mapcycle, map, cat, stored_reason, map);
            }
            
            //Close the handles for the storage arrays.
            CloseHandle(nameArr);
            CloseHandle(weightArr);
            CloseHandle(cycleArr);
        }
        else //Otherwise, there are no nominations to worry about so we just pick a map randomly
             //from the winning category.
        {
            DEBUG_MESSAGE("No nominations, selecting a random map from the winning group")
            GetRandomMap(kv, map, sizeof(map)); //, stored_exmaps, stored_exgroups);
            DoMapChange(change_map_when, stored_mapcycle, map, cat, stored_reason, map);
            DEBUG_MESSAGE("Map selected was %s", map)
        }
        
        //We no longer need the adt_array to store nominations.
        CloseHandle(nominationsFromCat);
        
        //We no longer need the copy of the mapcycle.
        CloseHandle(kv);
        
        PrintToChatAll(
            "\x03[UMC]\x01 %t %t (%t)",
            "End of Map Vote Over",
            "End of Map Vote Group Won",
                map, cat,
            "Vote Win Percentage",
                percentage,
                total_votes
        );
        LogMessage("MAPVOTE: Players voted for map group '%s' and the map '%s' was randomly selected.", cat, map);
    }
    
    //Play the vote completed sound if...
    //  ...the vote completed sound is defined.
    if (strlen(stored_end_sound) > 0)
        EmitSoundToAll(stored_end_sound);
        
    DeleteVoteParams();
}


//Handles the results of an end-of-map tiered vote.
public Handle_TierVoteResults(Handle:menu, num_votes, num_clients, const client_info[][2],
                              num_items, const item_info[][2])
{        
    ProcessVoteResults(menu, num_votes, num_clients, client_info, num_items, item_info,
                       Handle_TierVoteResults, Handle_TierVoteWinner);
}


//Handles the winner of an end-of-map tiered vote.
public Handle_TierVoteWinner(const String:cat[], const String:disp[], Float:percentage)
{
    DEBUG_MESSAGE("Handling Tiered Endvote Winner \"%s\"", cat)
    
    //Print a message and extend the map if...
    //    ...the server voted to extend the map.
    if (StrEqual(cat, EXTEND_MAP_OPTION))
    {
        DEBUG_MESSAGE("Endvote - Extending the map.")
    
        PrintToChatAll(
            "\x03[UMC]\x01 %t %t (%t)",
            "End of Map Vote Over",
            "Map Extended",
            "Vote Win Percentage",
                percentage,
                total_votes
        );
        LogMessage("MAPVOTE: Players voted to extend the map.");
        DeleteVoteParams();
        ExtendMap();
    }
    else if (StrEqual(cat, DONT_CHANGE_OPTION))
    {
        PrintToChatAll(
            "\x03[UMC]\x01 %t %t (%t)",
            "End of Map Vote Over",
            "Map Unchanged",
            "Vote Win Percentage",
                percentage,
                total_votes
        );
        
        LogMessage("MAPVOTE: Players voted to stay on the map (Don't Change).");
        DeleteVoteParams();
        VoteFailed();
    }
    else //Otherwise, we set up the second stage of the tiered vote
    {
        DEBUG_MESSAGE("Setting up second part of Tiered V.")
        LogMessage("MAPVOTE (Tiered): Players voted for map group '%s'", cat);
        
        //Jump to the map group
        KvRewind(stored_kv);
        new Handle:kv = CreateKeyValues("umc_rotation");
        KvCopySubkeys(stored_kv, kv);
        
        new vMapCount;
        
        DEBUG_MESSAGE("Counting the number of nominations from the winning group.")
        //Get the number of valid nominations from the group
        new Handle:tempNoms = GetCatNominations(cat);
        
        if (stored_exclude)
        {
            new Handle:catNoms = FilterNominationsArray(tempNoms);
            vMapCount = GetArraySize(catNoms);        
            CloseHandle(catNoms);
        }
        else
        {
            vMapCount = GetArraySize(tempNoms);
        }
        CloseHandle(tempNoms);
        
        DEBUG_MESSAGE("Valid Maps: %i", vMapCount)
        
        KvJumpToKey(kv, cat);
        
        if (stored_exclude)
            FilterMapGroup(kv, stored_mapcycle);
        
        DEBUG_MESSAGE("Counting the number of available maps from the winning group.")
        //Get the number of valid maps from the group
        vMapCount += CountMapsFromGroup(kv);
        
        DEBUG_MESSAGE("Valid Maps: %i", vMapCount)
        
        //Return to the root.
        KvGoBack(kv);
        
        DEBUG_MESSAGE("Determining if we need to run a second vote.")
        //Just parse the results as a normal map group vote if...
        //  ...the total number of valid maps is 1.
        if (vMapCount <= 1)
        {
            DEBUG_MESSAGE("Only 1 map available, no vote required.")
            LogMessage(
                "MAPVOTE (Tiered): Only one valid map found in group. Handling results as a Map Group Vote."
            );
            Handle_CatVoteWinner(cat, disp, percentage);
            CloseHandle(kv);
            return;
        }
    
        DEBUG_MESSAGE("Starting countdown timer for the second vote.")
        
        //Setup timer to delay the next vote for a few seconds.
        tiered_delay = 4;
        
        //Display the first message
        DisplayTierMessage(5);
        
        //TODO: Better to just filter the mapcycle instead of building an array.
        new Handle:tieredKV = MakeSecondTieredCatExclusion(kv, cat);
        
#if UMC_DEBUG
        DEBUG_MESSAGE("Group for Tiered Vote:")
        PrintKv(tieredKV);
#endif
        
        CloseHandle(kv);
        
        //Setup timer to delay the next vote for a few seconds.
        CreateTimer(
            1.0,
            Handle_TieredVoteTimer,
            tieredKV,
            TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT|TIMER_DATA_HNDL_CLOSE
        );
    }
    
    DEBUG_MESSAGE("Playing vote complete sound.")
    
    //Play the vote completed sound if...
    //  ...the vote completed sound is defined.
    if (strlen(stored_end_sound) > 0)
        EmitSoundToAll(stored_end_sound);
        
    DEBUG_MESSAGE("Finished handling Tiered winner.")
}


//Called when the timer for the tiered end-of-map vote triggers.
public Action:Handle_TieredVoteTimer(Handle:timer, Handle:tieredKV)
{
    if (!vote_inprogress)
    {
        VoteFailed();
        DeleteVoteParams();
        return Plugin_Stop;
    }
    
    DisplayTierMessage(tiered_delay);
    
    if (tiered_delay > 0)
    {
        if (strlen(countdown_sound) > 0)
            EmitSoundToAll(countdown_sound);

        tiered_delay--;
        return Plugin_Continue;
    }
        
    if (IsVoteInProgress())
    {
        return Plugin_Continue;
    }
    
    //Log a message
    LogMessage("MAPVOTE (Tiered): Starting second stage of tiered vote.");
    
    //Initialize the menu.
    new Handle:menu = BuildMapVoteMenu(tieredKV, stored_mapcycle, Handle_MapVoteResults,
                                       stored_scramble, false, false, stored_blockslots,
                                       stored_ignoredupes, stored_strictnoms, true, stored_exclude);
    
    if (menu != INVALID_HANDLE)
    {
        //Play the vote start sound if...
        //  ...the vote start sound is defined.
        if (strlen(stored_start_sound) > 0)
            EmitSoundToAll(stored_start_sound);
        
        //Display the menu.
        VoteMenuToAllWithFlags(menu, stored_votetime, stored_adminflags);
        
        vote_active = true;
    }
    else
    {
        LogError("MAPVOTE (Tiered): Unable to create second stage vote menu. Vote aborted.");
        VoteFailed();
        DeleteVoteParams();
    }
        
    return Plugin_Stop;
}


//Extend the current map.
ExtendMap()
{
    vote_inprogress = false;
    //vote_completed = false;
    
    //Set new limit cvar values if they are enabled to begin with (> 0).
    new Handle:cvar_maxrounds = FindConVar("mp_maxrounds");
    new Handle:cvar_fraglimit = FindConVar("mp_fraglimit");
    new Handle:cvar_winlimit  = FindConVar("mp_winlimit");
    
    if (cvar_maxrounds != INVALID_HANDLE && GetConVarInt(cvar_maxrounds) > 0)
        SetConVarInt(cvar_maxrounds, GetConVarInt(cvar_maxrounds) + extend_roundstep);
    if (cvar_winlimit != INVALID_HANDLE && GetConVarInt(cvar_winlimit) > 0)
        SetConVarInt(cvar_winlimit, GetConVarInt(cvar_winlimit) + extend_roundstep);
    if (cvar_fraglimit != INVALID_HANDLE && GetConVarInt(cvar_fraglimit) > 0)
        SetConVarInt(cvar_fraglimit, GetConVarInt(cvar_fraglimit) + extend_fragstep);
    
    //Extend the time limit.
    ExtendMapTimeLimit(RoundToNearest(extend_timestep * 60));
    
    Call_StartForward(extend_forward);
    Call_Finish();
    
    //Log some stuff.
    LogMessage("MAPVOTE: Map extended.");
}


//Called when the vote has failed.
VoteFailed()
{    
    vote_inprogress = false;

    Call_StartForward(failure_forward);
    Call_Finish();
}


//Sets the next map and when to change to it.
DoMapChange(UMC_ChangeMapTime:when, Handle:kv, const String:map[], const String:group[],
            const String:reason[], const String:display[]="")
{
    vote_inprogress = false;
    
    //Set the next map group
    strcopy(next_cat, sizeof(next_cat), group);

    if (when == ChangeMapTime_RoundEnd && FindConVar("mp_maxrounds") == INVALID_HANDLE)
    {
        DEBUG_MESSAGE("Setting RoundEnd Flags (no mp_maxrounds cvar)")
        change_map_round = true;
        SetTheNextMap(map);
    }
    else
        SetupMapChange(when, map, reason);
    
    
    new Handle:new_kv = INVALID_HANDLE;
    if (kv != INVALID_HANDLE)
    {
        new_kv = CreateKeyValues("umc_rotation");
        KvCopySubkeys(kv, new_kv);
    }
    
    Call_StartForward(nextmap_forward);
    Call_PushCell(new_kv);
    Call_PushString(map);
    Call_PushString(group);
    Call_PushString(display);
    Call_Finish();
}


//Deletes the stored parameters for the vote.
DeleteVoteParams()
{
    DEBUG_MESSAGE("Deleting Vote Parameters")
    CloseHandle(stored_kv);
    CloseHandle(stored_mapcycle);
    stored_kv = INVALID_HANDLE;
    stored_mapcycle = INVALID_HANDLE;
}


//************************************************************************************************//
//                                        VALIDITY TESTING                                        //
//************************************************************************************************//

//Checks to see if the server has the required number of players for the given map, and is in the
//required time range.
//    kv:       a mapcycle whose traversal stack is currently at the level of the map's category.
//    map:      the map to check
bool:IsValidMapFromCat(Handle:kv, Handle:mapcycle, const String:map[], bool:isNom=false,
                       bool:forMapChange=true)
{   
    decl String:catName[MAP_LENGTH];
    KvGetSectionName(kv, catName, sizeof(catName));
    
    //Return that the map is not valid if...
    //    ...the map doesn't exist in the category.
    if (!KvJumpToKey(kv, map))
    {
        DEBUG_MESSAGE("Could not find map '%s' in group '%s'", map, catName)
        return false;
    }
    
    //Determine if the map is valid, store the answer.
    new bool:result = IsValidMap(kv, mapcycle, catName, isNom, forMapChange);
    
    //Rewind back to the category.
    KvGoBack(kv);
    
    //Return the result.
    return result;
}


//Determines if the server has the required number of players for the given map.
//    kv:       a mapcycle whose traversal stack is currently at the level of the map.
bool:IsValidMap(Handle:kv, Handle:mapcycle, const String:groupName[], bool:isNom=false,
                bool:forMapChange=true)
{
    decl String:mapName[MAP_LENGTH];
    KvGetSectionName(kv, mapName, sizeof(mapName));
    
    if (!IsMapValid(mapName))
    {
        DEBUG_MESSAGE("Map '%s' does not exist on the server.", mapName)
        return false;
    }
    
    new Action:result;
    
    new Handle:new_kv = CreateKeyValues("umc_rotation");
    KvCopySubkeys(mapcycle, new_kv);
    
    Call_StartForward(exclude_forward);
    Call_PushCell(new_kv);
    Call_PushString(mapName);
    Call_PushString(groupName);
    Call_PushCell(isNom);
    Call_PushCell(forMapChange);
    Call_Finish(result);
    
    CloseHandle(new_kv);
    
    new bool:re = result == Plugin_Continue;
    
    return re;
}


//Determines if the server has the required number of players for the given category and the
//required time.
//    kv: a mapcycle whose traversal stack is currently at the level of the category.
bool:IsValidCat(Handle:kv, Handle:mapcycle, bool:isNom=false, bool:forMapChange=true)
{
    //Get the name of the cat.
    decl String:catName[MAP_LENGTH];
    KvGetSectionName(kv, catName, sizeof(catName));
    
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
        if (IsValidMap(kv, mapcycle, catName, isNom, forMapChange))
        {
            KvGoBack(kv);
            return true;
        }
    }
    while (KvGotoNextKey(kv)); //Goto the next map in the category.

    //Return to the category level.
    KvGoBack(kv);
    
    //No maps in the category can be played with the current amount of players on the server.
    return false;
}


//Counts the number of maps in the given group.
CountMapsFromGroup(Handle:kv)
{
    new result = 0;
    if (!KvGotoFirstSubKey(kv))
        return result;
    
    do
    {
        result++;
    }
    while (KvGotoNextKey(kv));
    
    KvGoBack(kv);
    
    return result;
}


//Calculates the weight of a map by running it through all of the weight modifiers.
Float:GetMapWeight(Handle:mapcycle, const String:map[], const String:group[])
{
    //Get the starting weight
    current_weight = 1.0;
    
    new Handle:kv = CreateKeyValues("umc_rotation");
    KvCopySubkeys(mapcycle, kv);
    
    reweight_active = true;
    
    Call_StartForward(reweight_forward);
    Call_PushCell(kv);
    Call_PushString(map);
    Call_PushString(group);
    Call_Finish();
    
    reweight_active = false;
    
    CloseHandle(kv);
    
    //And return our calculated weight.
    return (current_weight >= 0.0) ? current_weight : 0.0;
}


//Calculates the weight of a map group
Float:GetMapGroupWeight(Handle:originalMapcycle, const String:group[])
{
    current_weight = 1.0;
    
    new Handle:kv = CreateKeyValues("umc_rotation");
    KvCopySubkeys(originalMapcycle, kv);
    
    reweight_active = true;
    
    Call_StartForward(reweight_group_forward);
    Call_PushCell(kv);
    Call_PushString(group);
    Call_Finish();
    
    reweight_active = false;
    
    CloseHandle(kv);
    
    return (current_weight >= 0.0) ? current_weight : 0.0;
}


//Calculates weights for a mapcycle
WeightMapcycle(Handle:kv, Handle:originalMapcycle)
{
    if (!KvGotoFirstSubKey(kv))
        return;
        
    decl String:group[MAP_LENGTH];
    do
    {
        KvGetSectionName(kv, group, sizeof(group));
        
        KvSetFloat(kv, WEIGHT_KEY, GetMapGroupWeight(originalMapcycle, group));
    
        WeightMapGroup(kv, originalMapcycle);
    }
    while (KvGotoNextKey(kv));
    
    KvGoBack(kv);
}


//Calculates weights for a map group.
WeightMapGroup(Handle:kv, Handle:originalMapcycle)
{
    decl String:map[MAP_LENGTH], String:group[MAP_LENGTH];
    KvGetSectionName(kv, group, sizeof(group));
    
    if (!KvGotoFirstSubKey(kv))
        return;
    
    do
    {
        KvGetSectionName(kv, map, sizeof(map));
        
        KvSetFloat(kv, WEIGHT_KEY, GetMapWeight(originalMapcycle, map, group));
    }
    while (KvGotoNextKey(kv));
    
    KvGoBack(kv);
}


//Returns the weight of a given map or map group
Float:GetWeight(Handle:kv)
{
    return KvGetFloat(kv, WEIGHT_KEY, 1.0);
}


//Filters a mapcycle with all invalid entries filtered out.
FilterMapcycle(Handle:kv, Handle:originalMapcycle, bool:isNom=false, bool:forMapChange=true,
              bool:deleteEmpty=true)
{
    //Do nothing if there are no map groups.
    if (!KvGotoFirstSubKey(kv))
        return;
        
    DEBUG_MESSAGE("Starting mapcycle filtering.")
    decl String:group[MAP_LENGTH];
    for ( ; ; )
    {
        //Filter all the maps.
        FilterMapGroup(kv, originalMapcycle, isNom, forMapChange);
        
        //Delete the group if there are no valid maps in it.
        if (deleteEmpty) 
        {
            if (!KvGotoFirstSubKey(kv))
            {
                KvGetSectionName(kv, group, sizeof(group));
        
                DEBUG_MESSAGE("Removing empty group \"%s\".", group)
                if (KvDeleteThis(kv) == -1)
                {
                    DEBUG_MESSAGE("Mapcycle filtering completed.")
                    return;
                }
                else
                    continue;
            }
            
            KvGoBack(kv);
        }
                
        if (!KvGotoNextKey(kv))
            break;
    }
    
    //Return to the root.
    KvGoBack(kv);
    
    DEBUG_MESSAGE("Mapcycle filtering completed.")
}


//Filters the kv at the level of the map group.
FilterMapGroup(Handle:kv, Handle:mapcycle, bool:isNom=false, bool:forMapChange=true)
{
    decl String:group[MAP_LENGTH];
    KvGetSectionName(kv, group, sizeof(group));
    
    if (!KvGotoFirstSubKey(kv))
        return;
    
    DEBUG_MESSAGE("Starting filtering of map group \"%s\".", group)
    
    decl String:mapName[MAP_LENGTH];
    for ( ; ; )
    {
        if (!IsValidMap(kv, mapcycle, group, isNom, forMapChange))
        {
            KvGetSectionName(kv, mapName, sizeof(mapName));
            DEBUG_MESSAGE("Removing invalid map \"%s\" from group \"%s\".", mapName, group)
            if (KvDeleteThis(kv) == -1)
            {
                DEBUG_MESSAGE("Map Group filtering completed for group \"%s\".", group)
                return;
            }
        }
        else
        {
            if (!KvGotoNextKey(kv))
                break;
        }
    }
    
    KvGoBack(kv);
    
    DEBUG_MESSAGE("Map Group filtering completed for group \"%s\".", group)
}


//************************************************************************************************//
//                                           NOMINATIONS                                          //
//************************************************************************************************//

//Filters an array of nominations so that only valid maps remain.
Handle:FilterNominationsArray(Handle:nominations, bool:forMapChange=true)
{
    new Handle:result = CreateArray();

    new size = GetArraySize(nominations);
    new Handle:nom;
    decl String:gBuffer[MAP_LENGTH], String:mBuffer[MAP_LENGTH];
    new Handle:mapcycle;
    new Handle:kv;
    for (new i = 0; i < size; i++)
    {
        nom = GetArrayCell(nominations, i);
        GetTrieString(nom, MAP_TRIE_MAP_KEY, mBuffer, sizeof(mBuffer));
        GetTrieString(nom, MAP_TRIE_GROUP_KEY, gBuffer, sizeof(gBuffer));
        GetTrieValue(nom, "mapcycle", mapcycle);
        
        kv = CreateKeyValues("umc_rotation");
        KvCopySubkeys(mapcycle, kv);
        
        if (!KvJumpToKey(kv, gBuffer))
        {
            DEBUG_MESSAGE("Could not find group '%s' in nomination mapcycle.", gBuffer)
            continue;
        }
        
        if (IsValidMapFromCat(kv, mapcycle, mBuffer, .isNom=true, .forMapChange=forMapChange))
            PushArrayCell(result, nom);
        
        CloseHandle(kv);
    }
    
    return result;
}


//Nominated a map and group
bool:InternalNominateMap(Handle:kv, const String:map[], const String:group[], client,
                         const String:nomGroup[])
{
    DEBUG_MESSAGE("Adding map '%s' from group '%s' to nominations.", map, group)
    if (FindNominationIndex(map, group) != -1)
    {
        DEBUG_MESSAGE("Map/Group is already in nominations.")
        return false;
    }
    
    DEBUG_MESSAGE("Setting up nomination trie")
    //Create the nomination trie.
    new Handle:nomination = CreateMapTrie(map, StrEqual(nomGroup, INVALID_GROUP) ? group : nomGroup);
    SetTrieValue(nomination, "client", client); //Add the client
    SetTrieValue(nomination, "mapcycle", kv); //Add the mapcycle
    SetTrieString(nomination, "nom_group", group);
    
    //Get and add the nominated map's weight.
    //SetTrieValue(nomination, "weight", GetArrayCell(nomination_weights[client], param2));
    
    DEBUG_MESSAGE("Detecting client's old nomination")
    //Remove the client's old nomination, if it exists.
    new index = FindClientNomination(client);
    if (index != -1)
    {
        DEBUG_MESSAGE("Nomination found for client")
        new Handle:oldNom = GetArrayCell(nominations_arr, index);
        
        decl String:oldName[MAP_LENGTH];
        GetTrieString(oldNom, MAP_TRIE_MAP_KEY, oldName, sizeof(oldName));
        
        Call_StartForward(nomination_reset_forward);
        Call_PushString(oldName);
        Call_PushCell(client);
        Call_Finish();
        
        DEBUG_MESSAGE("Removing old nomination")
        new Handle:nomKV;
        GetTrieValue(oldNom, "mapcycle", nomKV);
        CloseHandle(nomKV);
        CloseHandle(oldNom);
        RemoveFromArray(nominations_arr, index);
    }
    
    DEBUG_MESSAGE("Adding new nomination to nomination array")
    //Add the nomination to the nomination array.
    PushArrayCell(nominations_arr, nomination);
    
    return true;
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
FindNominationIndex(const String:map[], const String:group[])
{
    decl String:mName[MAP_LENGTH];
    decl String:gName[MAP_LENGTH];
    new Handle:nom = INVALID_HANDLE;
    new arraySize = GetArraySize(nominations_arr);
    for (new i = 0; i < arraySize; i++)
    {
        nom = GetArrayCell(nominations_arr, i);
        GetTrieString(nom, MAP_TRIE_MAP_KEY, mName, sizeof(mName));
        GetTrieString(nom, MAP_TRIE_GROUP_KEY, gName, sizeof(gName));
        if (StrEqual(mName, map, false) && StrEqual(gName, group, false))
            return i;
    }
    return -1;
}


//Utility function to get all nominations from a group.
Handle:GetCatNominations(const String:cat[])
{
    new Handle:arr1 = FilterNominations(MAP_TRIE_GROUP_KEY, cat);
    new Handle:arr2 = FilterNominations(MAP_TRIE_GROUP_KEY, INVALID_GROUP);
    ArrayAppend(arr1, arr2);
    CloseHandle(arr2);
    return arr1;
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
        if (StrEqual(temp, value, false))
            PushArrayCell(result, buffer);
    }
    return result;
}


//Clears all stored nominations.
ClearNominations()
{
    new size = GetArraySize(nominations_arr);
    new Handle:nomination = INVALID_HANDLE;
    new owner;
    decl String:map[MAP_LENGTH];
    for (new i = 0; i < size; i++)
    {
        nomination = GetArrayCell(nominations_arr, i);
        GetTrieString(nomination, MAP_TRIE_MAP_KEY, map, sizeof(map));
        GetTrieValue(nomination, "client", owner);

        Call_StartForward(nomination_reset_forward);
        Call_PushString(map);
        Call_PushCell(owner);
        Call_Finish();
        
        new Handle:nomKV;
        GetTrieValue(nomination, "mapcycle", nomKV);
        CloseHandle(nomKV);
        CloseHandle(nomination);
    }
    ClearArray(nominations_arr);
}


//************************************************************************************************//
//                                         RANDOM NEXTMAP                                         //
//************************************************************************************************//

//bool:GetRandomMapFromCycle(Handle:kv, const String:group[], String:buffer[], size, String:gBuffer[],
//                           gSize, Handle:exMaps, Handle:exGroups, numEGroups, bool:isNom=false,
//                           bool:forMapChange=true)
bool:GetRandomMapFromCycle(Handle:kv, const String:group[], String:buffer[], size, String:gBuffer[],
                           gSize)
{
    //Buffer to store the name of the category we will be looking for a map in.
    decl String:gName[MAP_LENGTH];
    
#if UMC_DEBUG
    if (!StrEqual(group, INVALID_GROUP, false))
    {
        DEBUG_MESSAGE("Searching for random map in group %s.", group)
    }
#endif
    
    strcopy(gName, sizeof(gName), group);

#if UMC_DEBUG
    new bool:p1 = StrEqual(gName, INVALID_GROUP, false);
    new bool:p2 = p1 || !KvJumpToKey(kv, gName);
    if (p1 || p2)
    {
        DEBUG_MESSAGE("Picking random group. P1: %i, P2: %i", p1, p2)
        
        if (!p2)
        {
            PrintKv(kv);
        }
#else
    if (StrEqual(gName, INVALID_GROUP, false) || !KvJumpToKey(kv, gName))
    {
#endif
        if (!GetRandomCat(kv, gName, sizeof(gName)))
        {
            LogError(
                "RANDOM MAP: Cannot pick a random map, no available map groups found in rotation."
            );
            return false;
        }
        KvJumpToKey(kv, gName);
    }
    
    //Buffer to store the name of the new map.
    decl String:mapName[MAP_LENGTH];
    
    //Log an error and fail if...
    //    ...there were no maps found in the category.
    if (!GetRandomMap(kv, mapName, sizeof(mapName)))//, exMaps, exGroups, isNom, forMapChange))
    {
        LogError(
            "RANDOM MAP: Cannot pick a random map, no available maps found. Parent Group: %s",
            gName
        );
        return false;
    }


    KvGoBack(kv);
    
    //Copy results into the buffers.
    strcopy(buffer, size, mapName);
    strcopy(gBuffer, gSize, gName);
    
    //Return success!
    return true;
}


//Selects a random category based off of the supplied weights for the categories.
//    kv:       a mapcycle whose traversal stack is currently at the root level.
//    buffer:      a string to store the selected category in.
//    key:      the key containing the weight information (most likely 'group_weight')
//    excluded: adt_array of excluded maps
//bool:GetRandomCat(Handle:kv, String:buffer[], size, Handle:excludedCats, numExcludedCats,
//                  Handle:excluded, bool:isNom=false, bool:forMapChange=true)
bool:GetRandomCat(Handle:kv, String:buffer[], size)
{
    DEBUG_MESSAGE("Getting a random group")

    //Fail if...
    //    ...there are no categories in the mapcycle.
    if (!KvGotoFirstSubKey(kv))
        return false;

    new index = 0; //counter of categories in the random pool
    new Handle:nameArr = CreateArray(ByteCountToCells(MAP_LENGTH)); //Array to store possible category names.
    new Handle:weightArr = CreateArray();  //Array to store possible category weights.
    
    DEBUG_MESSAGE("Starting traversal")
    //Add a category to the random pool.
    do
    {
        decl String:temp[MAP_LENGTH]; //Buffer to store the name of the category.
        
        //Get the name of the category.
        KvGetSectionName(kv, temp, sizeof(temp));
        
        DEBUG_MESSAGE("Group %s added to random pool.", temp)
        
        //Add the category to the random pool.
        PushArrayCell(weightArr, GetWeight(kv));
        PushArrayString(nameArr, temp);
        
        //One more category in the pool.
        index++;
    }
    while (KvGotoNextKey(kv)); //Do this for each category.

    //Return to the root level.
    KvGoBack(kv);
    
    DEBUG_MESSAGE("Finished traversal.")
    
    //Fail if...
    //    ...no categories are selectable.
    if (index == 0)
    {
        CloseHandle(nameArr);
        CloseHandle(weightArr);
        return false;
    }
    
    DEBUG_MESSAGE("Selecting a random group.")

    //Use weights to randomly select a category from the pool.
    new bool:result = GetWeightedRandomSubKey(buffer, size, weightArr, nameArr);
    
    //Close the pool.
    CloseHandle(nameArr);
    CloseHandle(weightArr);
    
#if UMC_DEBUG
    if (result)
        DEBUG_MESSAGE("Selected group %s", buffer)
#endif
    
    //Booyah!
    return result;
}


