/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                Ultimate Mapchooser - Admin Menu                               *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
 
#pragma semicolon 1

#include <sourcemod>
#include <umc-core>
#include <umc_utils>
#include <adminmenu>
#include <regex>

#define AMMENU_ITEM_INDEX_AUTO 0
#define AMMENU_ITEM_INDEX_MANUAL 1
#define AMMENU_ITEM_INFO_AUTO "auto"
#define AMMENU_ITEM_INFO_MANUAL "manual"

#define VTMENU_ITEM_INDEX_MAP 0
#define VTMENU_ITEM_INDEX_GROUP 1
#define VTMENU_ITEM_INDEX_TIER 2
#define VTMENU_ITEM_INFO_MAP "map"
#define VTMENU_ITEM_INFO_GROUP "group"
#define VTMENU_ITEM_INFO_TIER "tier"

#define VOTE_POP_STOP_INFO "stop"

#define DMENU_ITEM_INDEX_DEFAULTS 0
#define DMENU_ITEM_INDEX_MANUAL 1
#define DMENU_ITEM_INFO_DEFAULTS "0"
#define DMENU_ITEM_INFO_MANUAL "1"

#define SMENU_ITEM_INFO_NO "no"
#define SMENU_ITEM_INFO_YES "yes"

#define TMENU_ITEM_INFO_DEFAULT "default"

#define FAMENU_ITEM_INFO_NOTHING "nothing"
#define FAMENU_ITEM_INFO_RUNOFF "runoff"

#define MRMENU_ITEM_INFO_DEFAULT "default"

#define RFAMENU_ITEM_INFO_NOTHING "nothing"
#define RFAMENU_ITEM_INFO_ACCEPT "accept"

#define EMENU_ITEM_INFO_NO "no"
#define EMENU_ITEM_INFO_YES "yes"

#define DCMENU_ITEM_INFO_NO "no"
#define DCMENU_ITEM_INFO_YES "yes"


//Plugin Information
public Plugin:myinfo =
{
    name        = "[UMC] Admin Menu",
    author      = "Steell",
    description = "Adds an Ultimate Mapchooser entry in the SourceMod Admin Menu.",
    version     = PL_VERSION,
    url         = "http://forums.alliedmods.net/showthread.php?t=134190"
};


/* IDEAS:
    Votes:
        Votes Can be manually populated (choose maps/groups from a menu) or
        automatically populated (random w/ weight and exclusion).
        
        All settings are defined in cvars as "defaults." Admins are given the
        option to use these defaults or manually set each option. If manual,
        present series of menus for admin to set each option.
            -Options which can be set via the admin menu:
                *Scramble (auto-vote only)
                *Fail Action
                *Runoff (and Fail Action if enabled)
                *Extend Option
                *Don't Change Option
                *Type (Should come before picking maps/groups)
        
        When populating a manual vote, just build a new KV containing all of
        the selected maps, with an appropriate "maps_invote" setting. There is
        no need to take into account exclusions/weighting since it's not random
        and all the options in the admin menu are decidedly valid.
        
        Semi-auto mode: plugin picks the map, user has to confirm if he wants it
        in the vote. If he answers no, then it goes in the exclusion array.
        
        Limits: If we are using limits, then just use the UMC natives. If not, 
        then manually build menus by looping through the mapcycle. We can check
        if a map is excluded (perhaps for display/confirmation) if it is not
        found in the valid map array (fetched from core via native).
                
        Should we take nominations into consideration? (cvar perhaps)
        
        Turn MapVote button into StopVote button when a vote is in progress.

*/

        ////----CONVARS-----/////
new Handle:cvar_filename             = INVALID_HANDLE;
new Handle:cvar_scramble             = INVALID_HANDLE;
new Handle:cvar_vote_time            = INVALID_HANDLE;
new Handle:cvar_block_slots          = INVALID_HANDLE;
new Handle:cvar_strict_noms          = INVALID_HANDLE;
new Handle:cvar_runoff               = INVALID_HANDLE;
new Handle:cvar_runoff_sound         = INVALID_HANDLE;
new Handle:cvar_runoff_max           = INVALID_HANDLE;
new Handle:cvar_vote_allowduplicates = INVALID_HANDLE;
new Handle:cvar_vote_threshold       = INVALID_HANDLE;
new Handle:cvar_fail_action          = INVALID_HANDLE;
new Handle:cvar_runoff_fail_action   = INVALID_HANDLE;
new Handle:cvar_extend_rounds        = INVALID_HANDLE;
new Handle:cvar_extend_frags         = INVALID_HANDLE;
new Handle:cvar_extend_time          = INVALID_HANDLE;
new Handle:cvar_extensions           = INVALID_HANDLE;
new Handle:cvar_vote_mem             = INVALID_HANDLE;
new Handle:cvar_vote_startsound      = INVALID_HANDLE;
new Handle:cvar_vote_endsound        = INVALID_HANDLE;
new Handle:cvar_vote_catmem          = INVALID_HANDLE;
new Handle:cvar_dontchange           = INVALID_HANDLE;
        ////----/CONVARS-----/////

//Mapcycle KV
new Handle:map_kv = INVALID_HANDLE;

//Memory queues. Used to store the previously played maps.
new Handle:vote_mem_arr    = INVALID_HANDLE;
new Handle:vote_catmem_arr = INVALID_HANDLE;

//Sounds to be played at the start and end of votes.
new String:vote_start_sound[PLATFORM_MAX_PATH], String:vote_end_sound[PLATFORM_MAX_PATH],
    String:runoff_sound[PLATFORM_MAX_PATH];
    
//Can we start a vote (is the mapcycle valid?)
new bool:can_vote;

//Admin Menu
new Handle:admin_menu = INVALID_HANDLE;
//new TopMenuObject:umc_menu;

//Tries to store menu selections / build options.
new Handle:menu_tries[MAXPLAYERS];

//Flags for Chat Triggers
new bool:runoff_trigger[MAXPLAYERS];
new bool:runoff_menu_trigger[MAXPLAYERS];
new bool:threshold_trigger[MAXPLAYERS];
new bool:threshold_menu_trigger[MAXPLAYERS];

//Regex objects for chat triggers
new Handle:runoff_regex = INVALID_HANDLE;
new Handle:threshold_regex = INVALID_HANDLE;

//************************************************************************************************//
//                                        SOURCEMOD EVENTS                                        //
//************************************************************************************************//

//Called when the plugin is finished loading.
public OnPluginStart()
{
    cvar_fail_action = CreateConVar(
        "sm_umc_am_failaction",
        "0",
        "Specifies what action to take if the vote doesn't reach the set theshold.\n 0 - Do Nothing,\n 1 - Perform Runoff Vote",
        0, true, 0.0, true, 1.0
    );
    
    cvar_runoff_fail_action = CreateConVar(
        "sm_umc_am_runoff_failaction",
        "0",
        "Specifies what action to take if the runoff vote reaches the maximum amount of runoffs and the set threshold has not been reached.\n 0 - Do Nothing,\n 1 - Change Map to Winner",
        0, true, 0.0, true, 1.0
    );
    
    cvar_runoff_max = CreateConVar(
        "sm_umc_am_runoff_max",
        "0",
        "Specifies the maximum number of maps to appear in a runoff vote.\n 1 or 0 sets no maximum.",
        0, true, 0.0
    );

    /*cvar_vote_flags = CreateConVar(
        "sm_umc_am_adminflags",
        "",
        "String of admin flags required for players to be able to vote in end-of-map\nvotes. If no flags are specified, all players can vote."
    );*/

    cvar_vote_allowduplicates = CreateConVar(
        "sm_umc_am_allowduplicates",
        "1",
        "Allows a map to appear in the vote more than once. This should be enabled if you want the same map in different categories to be distinct.",
        0, true, 0.0, true, 1.0
    );
    
    cvar_vote_threshold = CreateConVar(
        "sm_umc_am_threshold",
        ".50",
        "If the winning option has less than this percentage of total votes, a vote will fail and the action specified in \"sm_umc_vc_failaction\" cvar will be performed.",
        0, true, 0.0, true, 1.0
    );
    
    cvar_runoff = CreateConVar(
        "sm_umc_am_runoffs",
        "0",
        "Specifies a maximum number of runoff votes to run for a vote.\n 0 = unlimited.",
        0, true, 0.0
    );
    
    cvar_runoff_sound = CreateConVar(
        "sm_umc_am_runoff_sound",
        "",
        "If specified, this sound file (relative to sound folder) will be played at the beginning of a runoff vote. If not specified, it will use the normal vote start sound."
    );
    
    cvar_vote_catmem = CreateConVar(
        "sm_umc_am_groupexclude",
        "0",
        "Specifies how many past map groups to exclude from votes.",
        0, true, 0.0, true, 10.0
    );
    
    cvar_vote_startsound = CreateConVar(
        "sm_umc_am_startsound",
        "",
        "Sound file (relative to sound folder) to play at the start of a vote."
    );
    
    cvar_vote_endsound = CreateConVar(
        "sm_umc_am_endsound",
        "",
        "Sound file (relative to sound folder) to play at the completion of a vote."
    );
    
    cvar_strict_noms = CreateConVar(
        "sm_umc_am_nominate_strict",
        "0",
        "Specifies whether the number of nominated maps appearing in the vote for a map group should be limited by the group's \"maps_invote\" setting.",
        0, true, 0.0, true, 1.0
    );

    cvar_block_slots = CreateConVar(
        "sm_umc_am_blockslots",
        "0",
        "Specifies how many slots in a vote are disabled to prevent accidental voting.",
        0, true, 0.0, true, 5.0
    );

    cvar_extend_rounds = CreateConVar(
        "sm_umc_am_extend_roundstep",
        "5",
        "Specifies how many more rounds each extension adds to the round limit.",
        0, true, 1.0
    );

    cvar_extend_time = CreateConVar(
        "sm_umc_am_extend_timestep",
        "15",
        "Specifies how many more minutes each extension adds to the time limit.",
        0, true, 1.0
    );

    cvar_extend_frags = CreateConVar(
        "sm_umc_am_extend_fragstep",
        "10",
        "Specifies how many more frags each extension adds to the frag limit.",
        0, true, 1.0
    );

    cvar_extensions = CreateConVar(
        "sm_umc_am_extend",
        "0",
        "Adds an \"Extend\" option to votes.",
        0, true, 0.0, true, 1.0
    );

    cvar_vote_time = CreateConVar(
        "sm_umc_am_duration",
        "20",
        "Specifies how long a vote should be available for.",
        0, true, 10.0
    );

    cvar_filename = CreateConVar(
        "sm_umc_am_cyclefile",
        "umc_mapcycle.txt",
        "File to use for Ultimate Mapchooser's map rotation."
    );

    cvar_vote_mem = CreateConVar(
        "sm_umc_am_mapexclude",
        "3",
        "Specifies how many past maps to exclude from votes.",
        0, true, 0.0, true, 10.0
    );

    cvar_scramble = CreateConVar(
        "sm_umc_am_menuscrambled",
        "0",
        "Specifies whether vote menu items are displayed in a random order.",
        0, true, 0.0, true, 1.0
    );
    
    cvar_dontchange = CreateConVar(
        "sm_umc_am_dontchange",
        "1",
        "Adds a \"Don't Change\" option to votes.",
        0, true, 0.0, true, 1.0
    );

    //Create the config if it doesn't exist, and then execute it.
    AutoExecConfig(true, "umc-adminmenu");
    
    //Make listeners for player chat. Needed to recognize chat input.
    AddCommandListener(OnPlayerChat, "say");
    AddCommandListener(OnPlayerChat, "say2"); //Insurgency Only
    AddCommandListener(OnPlayerChat, "say_team");
    
    //Initialize our memory arrays
    new numCells = ByteCountToCells(MAP_LENGTH);
    vote_mem_arr    = CreateArray(numCells);
    vote_catmem_arr = CreateArray(numCells);
    
    //Manually fire AdminMenu callback.
    new Handle:topmenu;
    if ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE)
        OnAdminMenuReady(topmenu);
        
    runoff_regex    = CompileRegex("^([0-9]+)\\s*$");
    threshold_regex = CompileRegex("^([0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)%?\\s*$");
}


//************************************************************************************************//
//                                           GAME EVENTS                                          //
//************************************************************************************************//

//Called after all config files were executed.
public OnConfigsExecuted()
{
    can_vote = ReloadMapcycle();
    
    SetupVoteSounds();
    
    //Grab the name of the current map.
    decl String:mapName[MAP_LENGTH];
    GetCurrentMap(mapName, sizeof(mapName));
    
    decl String:groupName[MAP_LENGTH];
    UMC_GetCurrentMapGroup(groupName, sizeof(groupName));
    
    if (can_vote && StrEqual(groupName, INVALID_GROUP, false))
    {
        KvFindGroupOfMap(map_kv, mapName, groupName, sizeof(groupName));
    }
    
    //TODO -- Set to 11, add options in menus to specify a smaller amount
    //Add the map to all the memory queues.
    new mapmem = GetConVarInt(cvar_vote_mem) + 1;
    new catmem = GetConVarInt(cvar_vote_catmem);
    AddToMemoryArray(mapName, vote_mem_arr, mapmem); //11); 
    AddToMemoryArray(groupName, vote_catmem_arr, (mapmem > catmem) ? mapmem : catmem); //11);
}


//Called when a player types in chat
public Action:OnPlayerChat(client, const String:command[], argc)
{
    //Return immediately if...
    //    ...nothing was typed.
    if (argc == 0) return Plugin_Continue;

    //Get what was typed.
    decl String:text[13];
    GetCmdArg(1, text, sizeof(text));
    
    if (threshold_trigger[client] && ProcessThresholdText(client, text))
        return Plugin_Handled;
    
    if (runoff_trigger[client] && ProcessRunoffText(client, text))
        return Plugin_Handled;
    
    return Plugin_Continue;
}


//************************************************************************************************//
//                                              SETUP                                             //
//************************************************************************************************//

//Parses the mapcycle file and returns a KV handle representing the mapcycle.
Handle:GetMapcycle()
{
    //Grab the file name from the cvar.
    decl String:filename[PLATFORM_MAX_PATH];
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


//Reloads the mapcycle. Returns true on success, false on failure.
bool:ReloadMapcycle()
{
    if (map_kv != INVALID_HANDLE)
    {
        CloseHandle(map_kv);
        map_kv = INVALID_HANDLE;
    }
    map_kv = GetMapcycle();
    
    return map_kv != INVALID_HANDLE;
}


//Sets up the vote sounds.
SetupVoteSounds()
{
    //Grab sound files from cvars.
    GetConVarString(cvar_vote_startsound, vote_start_sound, sizeof(vote_start_sound));
    GetConVarString(cvar_vote_endsound, vote_end_sound, sizeof(vote_end_sound));
    GetConVarString(cvar_runoff_sound, runoff_sound, sizeof(runoff_sound));
    
    //Gotta cache 'em all!
    CacheSound(vote_start_sound);
    CacheSound(vote_end_sound);
    CacheSound(runoff_sound);
}


//************************************************************************************************//
//                                           ADMIN MENU                                           //
//************************************************************************************************//

//Sets up the admin menu when it is ready to be set up.
public OnAdminMenuReady(Handle:topmenu)
{
    //Block this from being called twice
    if (topmenu == admin_menu)
        return;
        
    //Setup menu...
    admin_menu = topmenu;
    
    new TopMenuObject:umc_menu = AddToTopMenu(
        admin_menu, "Ultimate Mapchooser", TopMenuObject_Category,
        Adm_CategoryHandler, INVALID_TOPMENUOBJECT
    );
    
    AddToTopMenu(
        admin_menu, "umc_changemap", TopMenuObject_Item, UMCMenu_ChangeMap,
        umc_menu, "umc_changemap", ADMFLAG_CHANGEMAP
    );
    
    AddToTopMenu(
        admin_menu, "umc_setnextmap", TopMenuObject_Item, UMCMenu_NextMap,
        umc_menu, "sm_umc_setnextmap", ADMFLAG_CHANGEMAP
    );
    
    AddToTopMenu(
        admin_menu, "umc_mapvote", TopMenuObject_Item, UMCMenu_MapVote,
        umc_menu, "sm_umc_startmapvote", ADMFLAG_CHANGEMAP
    );
}


//Handles the UMC category in the admin menu.
public Adm_CategoryHandler(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param,
                           String:buffer[], maxlength)
{
    if (action == TopMenuAction_DisplayTitle || action == TopMenuAction_DisplayOption)
    {
        Format(buffer, maxlength, "Ultimate Mapchooser");
    }
}


//Handles the Change Map option in the menu.
public UMCMenu_ChangeMap(Handle:topmenu, TopMenuAction:action, TopMenuObject:objectID, param,
                         String:buffer[], maxlength)
{
    if (action == TopMenuAction_DisplayOption)
    {
        Format(buffer, maxlength, "Change Map");
    }
    else if (action == TopMenuAction_SelectOption)
    {
        CreateAMChangeMap(param);
    }
}


//Handles the Change Map option in the menu.
public UMCMenu_NextMap(Handle:topmenu, TopMenuAction:action, TopMenuObject:objectID, param,
                       String:buffer[], maxlength)
{
    if (action == TopMenuAction_DisplayOption)
    {
        Format(buffer, maxlength, "Set Next Map");
    }
    else if (action == TopMenuAction_SelectOption)
    {
        CreateAMNextMap(param);
    }
}


//Handles the Change Map option in the menu.
public UMCMenu_MapVote(Handle:topmenu, TopMenuAction:action, TopMenuObject:objectID, param,
                       String:buffer[], maxlength)
{
    if (action == TopMenuAction_DisplayOption)
    {
        Format(buffer, maxlength, "Start a Map Vote");
    }
    else if (action == TopMenuAction_SelectOption)
    {
        /*
        Order:
            1. Vote Type
            2. Auto/Manual
            --IF MANUAL--
                A. Pick Group/END
                --IF END--
                    I. Goto 3
                B. Pick Map
                C. Goto A
            3. Defaults/Override
            --IF OVERRIDE--
                A. Scramble
                B. Threshold
                C. Fail Action
                --IF RUNOFF--
                    I. Max Runoffs
                    II. Runoff Fail Action
                D. Extend Option
                E. Don't Change Option
            4. When
            
        Trie Structure:
        {
            int type
            bool auto
            adt_array maps
            bool defaults
            bool scramble
            Float threshold
            int fail_action
            int max_runoffs
            int runoff_fail_action
            bool extend
            bool dont_change
            int when
        }
        
        Trie "Methods":
            bool VoteAutoPopulated(client)
            bool RunoffIsEnabled(client)
            bool UsingDefaults(client)
        */
        
        menu_tries[param] = CreateVoteMenuTrie();
        DisplayVoteTypeMenu(param);
    }
}


//
Handle:CreateVoteMenuTrie()
{
    new Handle:trie = CreateTrie();
    new Handle:mapList = CreateArray();
    SetTrieValue(trie, "maps", mapList);
    return trie;
}


//
DisplayVoteTypeMenu(client)
{
    new Handle:menu = CreateMenu(HandleMV_VoteType);
    SetMenuTitle(menu, "Select Vote Type");
    
    AddMenuItem(menu, VTMENU_ITEM_INFO_MAP, "Maps");
    AddMenuItem(menu, VTMENU_ITEM_INFO_GROUP, "Groups");
    AddMenuItem(menu, VTMENU_ITEM_INFO_TIER, "Tiered");
    
    DisplayMenu(menu, client, 0);
}


//
public HandleMV_VoteType(Handle:menu, MenuAction:action, param1, param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            SetTrieValue(menu_tries[param1], "type", param2);
            DisplayAutoManualMenu(param1);
        }
        case MenuAction_Cancel:
        {
            CloseClientVoteTrie(param1);
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
}


//
DisplayAutoManualMenu(client)
{
    new Handle:menu = CreateAutoManualMenu(HandleMV_AutoManual, "Populate Vote");
    SetMenuExitBackButton(menu, true);
    DisplayMenu(menu, client, 0);
}


//
public HandleMV_AutoManual(Handle:menu, MenuAction:action, param1, param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            switch (param2)
            {
                case AMMENU_ITEM_INDEX_AUTO:
                {
                    AutoBuildVote(param1);
                    DisplayDefaultsMenu(param1);
                }
                case AMMENU_ITEM_INDEX_MANUAL:
                {
                    DisplayGroupSelectMenu(param1);
                }
            }
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                DisplayVoteTypeMenu(param1);
            }
            else
            {
                CloseClientVoteTrie(param1);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
}


//
AutoBuildVote(client)
{
    SetTrieValue(menu_tries[client], "auto", true);
}


//
CloseClientVoteTrie(client)
{
    new Handle:trie = menu_tries[client];
    menu_tries[client] = INVALID_HANDLE;
    
    new Handle:mapList;
    GetTrieValue(trie, "maps", mapList);
    ClearHandleArray(mapList);
    CloseHandle(mapList);
    
    CloseHandle(trie);
}


//
DisplayGroupSelectMenu(client)
{
    new Handle:menu = CreateGroupMenu(HandleMV_Groups);
    
    new Handle:voteArray;
    GetTrieValue(menu_tries[client], "maps", voteArray);
    if (GetArraySize(voteArray) > 1)
        InsertMenuItem(menu, 0, VOTE_POP_STOP_INFO, "Stop Adding Maps");
    
    DisplayMenu(menu, client, 0);
}


//
public HandleMV_Groups(Handle:menu, MenuAction:action, param1, param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            decl String:group[MAP_LENGTH];
            GetMenuItem(menu, param2, group, sizeof(group));
            
            if (StrEqual(group, VOTE_POP_STOP_INFO))
            {
                DisplayDefaultsMenu(param1);
            }
            else
            {
                SetTrieString(menu_tries[param1], "group", group);   
                DisplayMapSelectMenu(param1, group);
            }
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                DisplayAutoManualMenu(param1);
            }
            else
            {
                CloseClientVoteTrie(param1);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
}


//
DisplayMapSelectMenu(client, const String:group[])
{
    new Handle:newMenu = CreateMapMenu(HandleMV_Maps, group);
    DisplayMenu(newMenu, client, 0);
}


//
public HandleMV_Maps(Handle:menu, MenuAction:action, param1, param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            decl String:map[MAP_LENGTH], String:group[MAP_LENGTH];
            GetMenuItem(menu, param2, map, sizeof(map));
            GetTrieString(menu_tries[param1], "group", group, sizeof(group));
            
            AddToVoteList(param1, map, group);
            
            DisplayGroupSelectMenu(param1);
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                DisplayGroupSelectMenu(param1);
            }
            else
            {
                CloseClientVoteTrie(param1);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
}


//
AddToVoteList(client, const String:map[], const String:group[])
{
    new Handle:mapTrie = CreateMapTrie(map, group);
    new Handle:mapList;
    GetTrieValue(menu_tries[client], "maps", mapList);
    PushArrayCell(mapList, mapTrie);
}


//
DisplayDefaultsMenu(client)
{
    new Handle:menu = CreateMenu(HandleMV_Defaults);
    SetMenuTitle(menu, "Vote Settings");
    
    AddMenuItem(menu, DMENU_ITEM_INFO_DEFAULTS, "Use Defaults");
    AddMenuItem(menu, DMENU_ITEM_INFO_MANUAL, "Manually Choose");
    
    SetMenuExitBackButton(menu, true);
    
    DisplayMenu(menu, client, 0);
}


//
public HandleMV_Defaults(Handle:menu, MenuAction:action, param1, param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            switch (param2)
            {
                case DMENU_ITEM_INDEX_DEFAULTS:
                {
                    UseVoteDefaults(param1);
                    DisplayChangeWhenMenu(param1);
                }
                case DMENU_ITEM_INDEX_MANUAL:
                {
                    SetTrieValue(menu_tries[param1], "defaults", false);
                    DisplayScrambleMenu(param1);
                }
            }
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                if (VoteAutoPopulated(param1))
                    DisplayAutoManualMenu(param1);
                else
                    DisplayGroupSelectMenu(param1);
            }
            else
            {
                CloseClientVoteTrie(param1);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
}


//
UseVoteDefaults(client)
{
    new Handle:trie = menu_tries[client];
    
    SetTrieValue(trie, "defaults", true);
    
    SetTrieValue(trie, "scramble",           GetConVarBool(cvar_scramble));
    SetTrieValue(trie, "extend",             GetConVarBool(cvar_extensions));
    SetTrieValue(trie, "dont_change",        GetConVarBool(cvar_dontchange));
    SetTrieValue(trie, "threshold",          GetConVarFloat(cvar_vote_threshold));
    SetTrieValue(trie, "fail_action",        GetConVarInt(cvar_fail_action));
    SetTrieValue(trie, "runoff_fail_action", GetConVarInt(cvar_runoff_fail_action));
    SetTrieValue(trie, "max_runoffs",        GetConVarInt(cvar_runoff));
}


//
bool:VoteAutoPopulated(client)
{
    new bool:autoPop;
    GetTrieValue(menu_tries[client], "auto", autoPop);
    
    return autoPop;
}


//
DisplayScrambleMenu(client)
{
    new Handle:menu = CreateMenu(HandleMV_Scramble);
    SetMenuTitle(menu, "Scramble Vote Menu?");
    
    if (GetConVarBool(cvar_scramble))
    {
        AddMenuItem(menu, SMENU_ITEM_INFO_NO, "No");
        AddMenuItem(menu, SMENU_ITEM_INFO_YES, "Yes (default)");
    }
    else
    {
        AddMenuItem(menu, SMENU_ITEM_INFO_NO, "No (default)");
        AddMenuItem(menu, SMENU_ITEM_INFO_YES, "Yes");
    }
    
    SetMenuExitBackButton(menu, true);
    
    DisplayMenu(menu, client, 0);
}


//
public HandleMV_Scramble(Handle:menu, MenuAction:action, param1, param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            SetTrieValue(menu_tries[param1], "scramble", param2);
        
            DisplayThresholdMenu(param1);
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                DisplayDefaultsMenu(param1);
            }
            else
            {
                CloseClientVoteTrie(param1);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
}


//
DisplayThresholdMenu(client)
{
    threshold_trigger[client] = true;

    new Handle:menu = CreateMenu(HandleMV_Threshold);
    SetMenuTitle(menu, "Set Vote Threshold");
    
    AddMenuItem(menu, "", "Type in chat what threshold you would", ITEMDRAW_DISABLED);
    AddMenuItem(menu, "", "like to set the vote to [0 to 100].", ITEMDRAW_DISABLED);
    AddMenuItem(menu, "", "", ITEMDRAW_SPACER);
    
    new Float:threshold;
    if (GetTrieValue(menu_tries[client], "threshold", threshold))
    {
        decl String:fmt2[20];
        Format(fmt2, sizeof(fmt2), "%.f%% (previously entered)", threshold * 100);
        AddMenuItem(menu, "", fmt2);
    }
    
    decl String:fmt[20];
    Format(fmt, sizeof(fmt), "%.f%% (default)", GetConVarFloat(cvar_vote_threshold) * 100);
    AddMenuItem(menu, TMENU_ITEM_INFO_DEFAULT, fmt);
    
    SetMenuExitBackButton(menu, true);
    
    DisplayMenu(menu, client, 0);
}


//
public HandleMV_Threshold(Handle:menu, MenuAction:action, param1, param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            threshold_trigger[param1] = false;
            
            decl String:info[255];
            GetMenuItem(menu, param2, info, sizeof(info));
            
            if (StrEqual(info, TMENU_ITEM_INFO_DEFAULT))
                SetTrieValue(menu_tries[param1], "threshold", GetConVarFloat(cvar_vote_threshold));
                
            //TODO:
            //I don't think I need to handle the case where we reselect the previously entered threshold,
            //since it should already be stored in the trie.
        
            DisplayFailActionMenu(param1);
        }
        case MenuAction_Cancel:
        {
            threshold_trigger[param1] = false;
            
            if (!threshold_menu_trigger[param1])
            {
                if (param2 == MenuCancel_ExitBack)
                {
                    DisplayScrambleMenu(param1);
                }
                else
                {
                    CloseClientVoteTrie(param1);
                }
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
}


//
bool:ProcessThresholdText(client, const String:text[])
{
    decl String:num[20];
    new Float:percent;
    if (MatchRegex(threshold_regex, text))
    {
        GetRegexSubString(threshold_regex, 1, num, sizeof(num));
        percent = StringToFloat(num);
        
        if (percent <= 100.0 && percent >= 0.0)
        {
            SetTrieValue(menu_tries[client], "threshold", percent / 100.0);
            CancelThresholdMenu(client);
            DisplayFailActionMenu(client);
            return true;
        }
    }
    return false;
}


//
CancelThresholdMenu(client)
{
    threshold_menu_trigger[client] = true;
    CancelClientMenu(client);
    threshold_menu_trigger[client] = false;
}


//
DisplayFailActionMenu(client)
{
    new Handle:menu = CreateMenu(HandleMV_FailAction);
    SetMenuTitle(menu, "Set Fail Action");
    
    if (GetConVarBool(cvar_fail_action))
    {
        AddMenuItem(menu, FAMENU_ITEM_INFO_NOTHING, "Do Nothing");
        AddMenuItem(menu, FAMENU_ITEM_INFO_RUNOFF, "Perform Runoff Vote (default)");
    }
    else
    {
        AddMenuItem(menu, FAMENU_ITEM_INFO_NOTHING, "Do Nothing (default)");
        AddMenuItem(menu, FAMENU_ITEM_INFO_RUNOFF, "Perform Runoff Vote");
    }
    
    SetMenuExitBackButton(menu, true);
    
    DisplayMenu(menu, client, 0);
}


//
public HandleMV_FailAction(Handle:menu, MenuAction:action, param1, param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            SetTrieValue(menu_tries[param1], "fail_action", param2);
            
            switch (UMC_VoteFailAction:param2)
            {
                case VoteFailAction_Nothing:
                {
                    DisplayExtendMenu(param1);
                }
                case VoteFailAction_Runoff:
                {
                    DisplayMaxRunoffMenu(param1);
                }
            }
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                DisplayThresholdMenu(param1);
            }
            else
            {
                CloseClientVoteTrie(param1);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
}


//
DisplayMaxRunoffMenu(client)
{
    runoff_trigger[client] = true;
    
    new Handle:menu = CreateMenu(HandleMV_MaxRunoff);
    SetMenuTitle(menu, "Set Maximum Amount of Runoffs");
    
    AddMenuItem(menu, "", "Type in chat what maximum you would like", ITEMDRAW_DISABLED);
    AddMenuItem(menu, "", "to set the number of runoffs to (>= 0).", ITEMDRAW_DISABLED);
    AddMenuItem(menu, "", " 0 = unlimited", ITEMDRAW_DISABLED);
    AddMenuItem(menu, "", "", ITEMDRAW_SPACER);
    
    new runoffs;
    if (GetTrieValue(menu_tries[client], "max_runoffs", runoffs))
    {
        decl String:fmt2[20];
        Format(fmt2, sizeof(fmt2), "%i (previously entered)", runoffs);
        AddMenuItem(menu, "", fmt2);
    }
    
    decl String:fmt[20];
    Format(fmt, sizeof(fmt), "%i (default)", GetConVarInt(cvar_runoff_max));
    AddMenuItem(menu, MRMENU_ITEM_INFO_DEFAULT, fmt);
    
    SetMenuExitBackButton(menu, true);
    
    DisplayMenu(menu, client, 0);
}


//
public HandleMV_MaxRunoff(Handle:menu, MenuAction:action, param1, param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            runoff_trigger[param1] = false;
            
            decl String:info[255];
            GetMenuItem(menu, param2, info, sizeof(info));
            
            if (StrEqual(info, MRMENU_ITEM_INFO_DEFAULT))
                SetTrieValue(menu_tries[param1], "max_runoffs", GetConVarInt(cvar_runoff_max));
                
            //TODO:
            //I don't think I need to handle the case where we reselect the previously entered amount,
            //since it should already be stored in the trie.
        
            DisplayRunoffFailActionMenu(param1);
        }
        case MenuAction_Cancel:
        {
            runoff_trigger[param1] = false;
            
            if (!runoff_menu_trigger[param1])
            {
                if (param2 == MenuCancel_ExitBack)
                {
                    DisplayFailActionMenu(param1);
                }
                else
                {
                    CloseClientVoteTrie(param1);
                }
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
}


//
bool:ProcessRunoffText(client, const String:text[])
{
    decl String:num[20];
    new amt;
    if (MatchRegex(runoff_regex, text))
    {
        GetRegexSubString(runoff_regex, 1, num, sizeof(num));
        amt = StringToInt(num);
        
        if (amt >= 0)
        {
            SetTrieValue(menu_tries[client], "max_runoffs", amt);
            CancelRunoffMenu(client);
            DisplayRunoffFailActionMenu(client);
            return true;
        }
    }
    return false;
}


//
CancelRunoffMenu(client)
{
    runoff_menu_trigger[client] = true;
    CancelClientMenu(client);
    runoff_menu_trigger[client] = false;        
}


//
DisplayRunoffFailActionMenu(client)
{
    new Handle:menu = CreateMenu(HandleMV_RunoffFailAction);
    SetMenuTitle(menu, "Set Runoff Fail Action");
    
    if (GetConVarBool(cvar_runoff_fail_action))
    {
        AddMenuItem(menu, RFAMENU_ITEM_INFO_NOTHING, "Do Nothing");
        AddMenuItem(menu, RFAMENU_ITEM_INFO_ACCEPT, "Accept Winner (default)");
    }
    else
    {
        AddMenuItem(menu, RFAMENU_ITEM_INFO_NOTHING, "Do Nothing (default)");
        AddMenuItem(menu, RFAMENU_ITEM_INFO_ACCEPT, "Accept Winner");
    }
    
    SetMenuExitBackButton(menu, true);
    
    DisplayMenu(menu, client, 0);
}


//
public HandleMV_RunoffFailAction(Handle:menu, MenuAction:action, param1, param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            SetTrieValue(menu_tries[param1], "runoff_fail_action", param2);
            
            DisplayExtendMenu(param1);
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                DisplayMaxRunoffMenu(param1);
            }
            else
            {
                CloseClientVoteTrie(param1);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
}


//
DisplayExtendMenu(client)
{
    new Handle:menu = CreateMenu(HandleMV_Extend);
    SetMenuTitle(menu, "Add Extend Map Option?");
    
    if (GetConVarBool(cvar_extensions))
    {
        AddMenuItem(menu, EMENU_ITEM_INFO_NO, "No");
        AddMenuItem(menu, EMENU_ITEM_INFO_YES, "Yes (default)");
    }
    else
    {
        AddMenuItem(menu, EMENU_ITEM_INFO_NO, "No (default)");
        AddMenuItem(menu, EMENU_ITEM_INFO_YES, "Yes");
    }
    
    SetMenuExitBackButton(menu, true);
    
    DisplayMenu(menu, client, 0);
}


//
public HandleMV_Extend(Handle:menu, MenuAction:action, param1, param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            SetTrieValue(menu_tries[param1], "extend", param2);
            
            DisplayDontChangeMenu(param1);
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                if (RunoffIsEnabled(param1))
                    DisplayMaxRunoffMenu(param1);
                else
                    DisplayFailActionMenu(param1);
            }
            else
            {
                CloseClientVoteTrie(param1);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
}


//
bool:RunoffIsEnabled(client)
{
    new UMC_VoteFailAction:failAction;
    GetTrieValue(menu_tries[client], "fail_action", failAction);
    
    return failAction == VoteFailAction_Runoff;
}


//
DisplayDontChangeMenu(client)
{
    new Handle:menu = CreateMenu(HandleMV_DontChange);
    SetMenuTitle(menu, "Add Don't Change Option?");
    
    if (GetConVarBool(cvar_dontchange))
    {
        AddMenuItem(menu, DCMENU_ITEM_INFO_NO, "No");
        AddMenuItem(menu, DCMENU_ITEM_INFO_YES, "Yes (default)");
    }
    else
    {
        AddMenuItem(menu, DCMENU_ITEM_INFO_NO, "No (default)");
        AddMenuItem(menu, DCMENU_ITEM_INFO_YES, "Yes");
    }
    
    SetMenuExitBackButton(menu, true);
    
    DisplayMenu(menu, client, 0);
}


//
public HandleMV_DontChange(Handle:menu, MenuAction:action, param1, param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            SetTrieValue(menu_tries[param1], "dont_change", param2);
            
            DisplayChangeWhenMenu(param1);
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                DisplayExtendMenu(param1);
            }
            else
            {
                CloseClientVoteTrie(param1);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
}


//
DisplayChangeWhenMenu(client)
{
    new Handle:menu = CreateMenu(HandleMV_When);
    SetMenuTitle(menu, "Change Map When?");
    
    SetMenuExitBackButton(menu, true);

    decl String:info1[2];
    Format(info1, sizeof(info1), "%i", ChangeMapTime_Now);
    AddMenuItem(menu, info1, "Now");
    
    decl String:info2[2];
    Format(info2, sizeof(info2), "%i", ChangeMapTime_RoundEnd);
    AddMenuItem(menu, info2, "End of Round");
    
    decl String:info3[2];
    Format(info3, sizeof(info3), "%i", ChangeMapTime_MapEnd);
    AddMenuItem(menu, info3, "End of Map");
    
    DisplayMenu(menu, client, 0);
}


//
public HandleMV_When(Handle:menu, MenuAction:action, param1, param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            decl String:info[2];
            GetMenuItem(menu, param2, info, sizeof(info));
            
            SetTrieValue(menu_tries[param1], "when", StringToInt(info));
            
            DoMapVote(param1);
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                if (UsingDefaults(param1))
                    DisplayDefaultsMenu(param1);
                else
                    DisplayDontChangeMenu(param1);
            }
            else
            {
                CloseClientVoteTrie(param1);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
}


//
bool:UsingDefaults(client)
{
    new bool:defaults;
    GetTrieValue(menu_tries[client], "defaults", defaults);
    
    return defaults;
}


//
DoMapVote(client)
{
    new Handle:trie = menu_tries[client];
    
    new Handle:selectedMaps;
    
    new UMC_VoteType:type, bool:scramble, bool:extend, bool:dontChange, Float:threshold,
        UMC_ChangeMapTime:when, UMC_VoteFailAction:failAction, runoffs,
        UMC_RunoffFailAction:runoffFailAction;
        
    GetTrieValue(trie, "maps", selectedMaps);
    
    new bool:autoPop = VoteAutoPopulated(client);
    new Handle:mapcycle = autoPop
        ? map_kv
        : CreateVoteKV(selectedMaps);
    
    GetTrieValue(trie, "type",               type);
    GetTrieValue(trie, "scramble",           scramble);
    GetTrieValue(trie, "extend",             extend);
    GetTrieValue(trie, "dont_change",        dontChange);
    GetTrieValue(trie, "threshold",          threshold);
    GetTrieValue(trie, "when",               when);
    GetTrieValue(trie, "fail_action",        failAction);
    GetTrieValue(trie, "runoff_fail_action", runoffFailAction);
    GetTrieValue(trie, "max_runoffs",        runoffs);
    
    CloseClientVoteTrie(client);
    
    UMC_StartVote(
        mapcycle, type, GetConVarInt(cvar_vote_time), vote_mem_arr, vote_catmem_arr,
        GetConVarInt(cvar_vote_catmem), scramble, GetConVarInt(cvar_block_slots),
        vote_start_sound, vote_end_sound, extend, GetConVarFloat(cvar_extend_time),
        GetConVarInt(cvar_extend_rounds), GetConVarInt(cvar_extend_frags), dontChange, threshold,
        when, failAction, runoffs, GetConVarInt(cvar_runoff_max), runoffFailAction, runoff_sound,
        GetConVarBool(cvar_strict_noms), GetConVarBool(cvar_vote_allowduplicates)
    );
    
    if (!autoPop)
        CloseHandle(mapcycle);
}


//
Handle:CreateVoteKV(Handle:maps)
{
    new Handle:result = CreateKeyValues("umc_rotation");
    KvRewind(map_kv);
    KvCopySubkeys(map_kv, result);
    
    if (!KvGotoFirstSubKey(result))
        return result;
    
    decl String:group[MAP_LENGTH];
    decl String:map[MAP_LENGTH];
    new bool:goBackMap;
    new bool:goBackGroup = true;
    for ( ; ; )
    {
        goBackMap = true;
    
        KvGetSectionName(result, group, sizeof(group));
        
        if (!KvGotoFirstSubKey(result))
            continue;
        
        for ( ; ; )
        {
            KvGetSectionName(result, map, sizeof(map));
            
            if (!FindMapInList(maps, map, group))
            {
                if (KvDeleteThis(result) == -1)
                {
                    goBackMap = false;
                    break;
                }
            }
            
            KvGotoNextKey(result);
        }
        
        if (goBackMap)
            KvGoBack(result);
        
        if (!KvGotoFirstSubKey(result))
        {
            if (KvDeleteThis(result) == -1)
            {
                goBackGroup = false;
                break;
            }
        }
        else
            KvGoBack(result);
            
        KvGotoNextKey(result);
    }
    
    if (goBackGroup)
        KvGoBack(result);
    
    return result;
}


//
bool:FindMapInList(Handle:maps, const String:map[], const String:group[])
{
    decl String:gBuffer[MAP_LENGTH], String:mBuffer[MAP_LENGTH];
    new Handle:trie;
    new size = GetArraySize(maps);
    for (new i = 0; i < size; i++)
    {
        trie = GetArrayCell(maps, i);
        GetTrieString(trie, MAP_TRIE_MAP_KEY, mBuffer, sizeof(mBuffer));
        if (StrEqual(mBuffer, map, false))
        {
            GetTrieString(trie, MAP_TRIE_GROUP_KEY, gBuffer, sizeof(gBuffer));
            if (StrEqual(gBuffer, group, false))
                return true;
        }
    }
    return false;
}


//
CreateAMNextMap(client)
{
    new Handle:menu = CreateAutoManualMenu(HandleAM_NextMap, "Select a Map");
    DisplayMenu(menu, client, 0);
}


//
CreateAMChangeMap(client)
{
    new Handle:menu = CreateAutoManualMenu(HandleAM_ChangeMap, "Select a Map");
    DisplayMenu(menu, client, 0);
}


//
public HandleAM_ChangeMap(Handle:menu, MenuAction:action, param1, param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            if (param2 == AMMENU_ITEM_INDEX_AUTO)
            {
                AutoChangeMap(param1);
            }
            else
            {
                ManualChangeMap(param1);
            }
        }
        case MenuAction_Cancel:
        {
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
}


//
ManualChangeMap(client)
{
    menu_tries[client] = CreateTrie();
    
    new Handle:menu = CreateGroupMenu(HandleGM_ChangeMap);
    DisplayMenu(menu, client, 0);
}


//
public HandleGM_ChangeMap(Handle:menu, MenuAction:action, param1, param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            decl String:group[MAP_LENGTH];
            GetMenuItem(menu, param2, group, sizeof(group));
            
            SetTrieString(menu_tries[param1], "group", group);
            
            new Handle:newMenu = CreateMapMenu(HandleMM_ChangeMap, group);
            DisplayMenu(newMenu, param1, 0);
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                CreateAMChangeMap(param1);
            }
            else
            {
                CloseHandle(menu_tries[param1]);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
}


//
public HandleMM_ChangeMap(Handle:menu, MenuAction:action, param1, param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            decl String:map[MAP_LENGTH];
            GetMenuItem(menu, param2, map, sizeof(map));
            
            SetTrieString(menu_tries[param1], "map", map);
            
            ManualChangeMapWhen(param1);
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                new Handle:newMenu = CreateGroupMenu(HandleGM_ChangeMap);    
                DisplayMenu(newMenu, param1, 0);
            }
            else
            {
                CloseHandle(menu_tries[param1]);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
}


//
ManualChangeMapWhen(client)
{
    new Handle:menu = CreateMenu(Handle_ManualChangeWhenMenu);
    SetMenuTitle(menu, "Change Map When?");
    
    SetMenuExitBackButton(menu, true);

    decl String:info1[2];
    Format(info1, sizeof(info1), "%i", ChangeMapTime_Now);
    AddMenuItem(menu, info1, "Now");
    
    decl String:info2[2];
    Format(info2, sizeof(info2), "%i", ChangeMapTime_RoundEnd);
    AddMenuItem(menu, info2, "End of this round");
    
    DisplayMenu(menu, client, 0);
}


//
public Handle_ManualChangeWhenMenu(Handle:menu, MenuAction:action, param1, param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            decl String:info[2];
            GetMenuItem(menu, param2, info, sizeof(info));
            
            SetTrieValue(menu_tries[param1], "when", StringToInt(info));
            
            DoManualMapChange(param1);
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                new Handle:newMenu = CreateGroupMenu(HandleGM_ChangeMap);    
                DisplayMenu(newMenu, param1, 0);
            }
            else
            {
                CloseHandle(menu_tries[param1]);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
}


//
DoManualMapChange(client)
{
    new Handle:trie = menu_tries[client];
    
    decl String:nextMap[MAP_LENGTH], String:nextGroup[MAP_LENGTH];
    new when;
    
    GetTrieString(trie, "map", nextMap, sizeof(nextMap));
    GetTrieString(trie, "group", nextGroup, sizeof(nextGroup));
    GetTrieValue(trie, "when", when);
    
    CloseHandle(trie);
    
    DoMapChange(client, UMC_ChangeMapTime:when, nextMap, nextGroup);
}


//
AutoChangeMap(client)
{
    new Handle:menu = CreateMenu(Handle_AutoChangeWhenMenu);
    SetMenuTitle(menu, "Change Map When?");
    
    SetMenuExitBackButton(menu, true);

    decl String:info1[2];
    Format(info1, sizeof(info1), "%i", ChangeMapTime_Now);
    AddMenuItem(menu, info1, "Now");
    
    decl String:info2[2];
    Format(info2, sizeof(info2), "%i", ChangeMapTime_RoundEnd);
    AddMenuItem(menu, info2, "End of this round");
    
    DisplayMenu(menu, client, 0);
}


//
public Handle_AutoChangeWhenMenu(Handle:menu, MenuAction:action, param1, param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            decl String:info[2];
            GetMenuItem(menu, param2, info, sizeof(info));
            
            DoAutoMapChange(param1, UMC_ChangeMapTime:StringToInt(info));
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                CreateAMChangeMap(param1);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
}


//
DoAutoMapChange(client, UMC_ChangeMapTime:when)
{
    decl String:nextMap[MAP_LENGTH], String:nextGroup[MAP_LENGTH];
    if (UMC_GetRandomMap(map_kv, INVALID_GROUP, nextMap, sizeof(nextMap), nextGroup,
        sizeof(nextGroup), vote_mem_arr, vote_catmem_arr, GetConVarInt(cvar_vote_catmem), false,
        true))
    {
        DoMapChange(client, when, nextMap, nextGroup);
    }
    else
    {
        LogError("Could not automatically change the map, no valid maps available.");
    }
}


//
DoMapChange(client, UMC_ChangeMapTime:when, const String:map[], const String:group[])
{
    UMC_SetNextMap(map_kv, map, group, when);
}


//
public HandleAM_NextMap(Handle:menu, MenuAction:action, param1, param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            if (param2 == AMMENU_ITEM_INDEX_AUTO)
            {
                AutoNextMap(param1);
            }
            else
            {
                ManualNextMap(param1);
            }
        }
        case MenuAction_Cancel:
        {
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
}


//
ManualNextMap(client)
{
    menu_tries[client] = CreateTrie();
    
    new Handle:menu = CreateGroupMenu(HandleGM_NextMap);
    DisplayMenu(menu, client, 0);
}


//
public HandleGM_NextMap(Handle:menu, MenuAction:action, param1, param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            decl String:group[MAP_LENGTH];
            GetMenuItem(menu, param2, group, sizeof(group));
            
            SetTrieString(menu_tries[param1], "group", group);
            
            new Handle:newMenu = CreateMapMenu(HandleMM_NextMap, group);
            DisplayMenu(newMenu, param1, 0);
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                CreateAMNextMap(param1);
            }
            else
            {
                CloseHandle(menu_tries[param1]);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
}


//
public HandleMM_NextMap(Handle:menu, MenuAction:action, param1, param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            decl String:map[MAP_LENGTH];
            GetMenuItem(menu, param2, map, sizeof(map));
            
            SetTrieString(menu_tries[param1], "map", map);
            
            DoManualNextMap(param1);
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                new Handle:newMenu = CreateGroupMenu(HandleGM_ChangeMap);    
                DisplayMenu(newMenu, param1, 0);
            }
            else
            {
                CloseHandle(menu_tries[param1]);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
}


//
DoManualNextMap(client)
{
    new Handle:trie = menu_tries[client];
    
    decl String:nextMap[MAP_LENGTH], String:nextGroup[MAP_LENGTH];
    GetTrieString(trie, "map", nextMap, sizeof(nextMap));
    GetTrieString(trie, "group", nextGroup, sizeof(nextGroup));
    
    CloseHandle(trie);
    
    DoMapChange(client, ChangeMapTime_MapEnd, nextMap, nextGroup);
}


//
AutoNextMap(client)
{
    decl String:nextMap[MAP_LENGTH], String:nextGroup[MAP_LENGTH];
    if (UMC_GetRandomMap(map_kv, INVALID_GROUP, nextMap, sizeof(nextMap), nextGroup,
        sizeof(nextGroup), vote_mem_arr, vote_catmem_arr, GetConVarInt(cvar_vote_catmem), false,
        true))
    {
        DoMapChange(client, ChangeMapTime_MapEnd, nextMap, nextGroup);
    }
    else
    {
        LogError("Could not automatically set the next map, no valid maps available.");
    }
}


//Builds and returns a map group selection menu.
Handle:CreateGroupMenu(MenuHandler:handler, bool:limits=false)
{
    //Initialize the menu
    new Handle:menu = CreateMenu(handler);
    SetMenuTitle(menu, "Select a Group");
    
    SetMenuExitBackButton(menu, true);
    
    KvRewind(map_kv);
    
    //Get group array.
    //new Handle:groupArray = UMC_CreateValidMapGroupArray(map_kv, exMaps, exGroups, 0, true, false);
    new Handle:groupArray = UMC_CreateValidMapGroupArray(map_kv, vote_mem_arr, vote_catmem_arr,
                                                         GetConVarInt(cvar_vote_catmem),
                                                         false, true);

    new size = GetArraySize(groupArray);
    
    //Log an error and return nothing if...
    //    ...the number of maps available to be nominated
    if (size == 0)
    {
        LogError("No maps available to build menu.");
        CloseHandle(menu);
        CloseHandle(groupArray);
        return INVALID_HANDLE;
    }
    
    //Add all maps from the nominations array to the menu.
    AddArrayToMenu(menu, groupArray);
    
    //No longer need the array.
    CloseHandle(groupArray);

    //Success!
    return menu;
}


//Builds and returns a map selection menu.
Handle:CreateMapMenu(MenuHandler:handler, const String:group[]=INVALID_GROUP, bool:limits=false)
{
    //Initialize the menu
    new Handle:menu = CreateMenu(handler);
    
    //Set the title.
    SetMenuTitle(menu, "Select a Map");
    
    SetMenuExitBackButton(menu, true);
    
    KvRewind(map_kv);

    //Get map array.
    new Handle:mapArray = UMC_CreateValidMapArray(map_kv, group, vote_mem_arr, vote_catmem_arr,
                                                  GetConVarInt(cvar_vote_catmem), false, true);
    
    new size = GetArraySize(mapArray);
    if (size == 0)
    {
        LogError("No maps available to build menu.");
        CloseHandle(menu);
        CloseHandle(mapArray);
        return INVALID_HANDLE;
    }
    
    //Variables
    new numCells = ByteCountToCells(MAP_LENGTH);
    new Handle:menuItems = CreateArray(numCells);
    new Handle:menuItemDisplay = CreateArray(numCells);
    decl String:display[MAP_LENGTH], String:gDisp[MAP_LENGTH];
    new Handle:mapTrie = INVALID_HANDLE;
    decl String:mapBuff[MAP_LENGTH], String:groupBuff[MAP_LENGTH];
    
    for (new i = 0; i < size; i++)
    {
        mapTrie = GetArrayCell(mapArray, i);
        GetTrieString(mapTrie, MAP_TRIE_MAP_KEY, mapBuff, sizeof(mapBuff));
        GetTrieString(mapTrie, MAP_TRIE_GROUP_KEY, groupBuff, sizeof(groupBuff));
        
        //if (UMC_IsMapNominated(mapBuff, groupBuff))
        //    continue;
        
        KvJumpToKey(map_kv, groupBuff);
        KvGetString(map_kv, "display-template", gDisp, sizeof(gDisp), "{MAP}");
        KvJumpToKey(map_kv, mapBuff);

        //Get the name of the current map.
        KvGetSectionName(map_kv, mapBuff, sizeof(mapBuff));
        
        KvGetString(map_kv, "display", display, sizeof(display), gDisp);
                    
        if (strlen(display) == 0)
            display = mapBuff;
        else
            ReplaceString(display, sizeof(display), "{MAP}", mapBuff, false);
            
        //Add map data to the arrays.
        PushArrayString(menuItems, mapBuff);
        PushArrayString(menuItemDisplay, display);
        
        KvRewind(map_kv);
    }
    
    //Add all maps from the nominations array to the menu.
    AddArrayToMenu(menu, menuItems, menuItemDisplay);
    
    //No longer need the arrays.
    CloseHandle(menuItems);
    CloseHandle(menuItemDisplay);
    ClearHandleArray(mapArray);
    CloseHandle(mapArray);
    
    //Success!
    return menu;
}


//Builds a menu with Auto and Manual options.
Handle:CreateAutoManualMenu(MenuHandler:handler, const String:title[])
{
    new Handle:menu = CreateMenu(handler);
    SetMenuTitle(menu, title);
    
    AddMenuItem(menu, AMMENU_ITEM_INFO_AUTO, "Auto Select");
    AddMenuItem(menu, AMMENU_ITEM_INFO_MANUAL, "Manual Select");
    
    return menu;
}


//************************************************************************************************//
//                                   ULTIMATE MAPCHOOSER EVENTS                                   //
//************************************************************************************************//

//Called when UMC requests that the mapcycle should be reloaded.
public UMC_RequestReloadMapcycle()
{
    can_vote = ReloadMapcycle();
}


