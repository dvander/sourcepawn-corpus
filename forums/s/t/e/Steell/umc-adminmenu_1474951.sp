/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                Ultimate Mapchooser - Admin Menu                               *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
 
#pragma semicolon 1

#include <sourcemod>
#include <umc-core>
#include <umc_utils>
#include <adminmenu>

#define AMMENU_ITEM_INDEX_AUTO 0
#define AMMENU_ITEM_INDEX_MANUAL 1
#define AMMENU_ITEM_INFO_AUTO "##auto##"
#define AMMENU_ITEM_INFO_MANUAL "##manual##"


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
new Handle:cvar_vote_type            = INVALID_HANDLE;
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
        "sm_umc_vc_adminflags",
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
        0, true, 0.0
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

    cvar_vote_type = CreateConVar(
        "sm_umc_am_type",
        "0",
        "Controls vote type:\n 0 - Maps,\n 1 - Groups,\n 2 - Tiered Vote (vote for a group, then vote for a map from the group).",
        0, true, 0.0, true, 2.0
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
        0, true, 0.0
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
    AutoExecConfig(true, "umc-votecommand");
    
    //Initialize our memory arrays
    new numCells = ByteCountToCells(MAP_LENGTH);
    vote_mem_arr    = CreateArray(numCells);
    vote_catmem_arr = CreateArray(numCells);
    
    //Manually fire AdminMenu callback.
    new Handle:topmenu;
    if ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE)
        OnAdminMenuReady(topmenu);
}


//************************************************************************************************//
//                                           GAME EVENTS                                          //
//************************************************************************************************//

//Called after all config files were executed.
public OnConfigsExecuted()
{
    can_vote = ReloadMapcycle();
    
    //Grab the name of the current map.
    decl String:mapName[MAP_LENGTH];
    GetCurrentMap(mapName, sizeof(mapName));
    
    decl String:groupName[MAP_LENGTH];
    UMC_GetCurrentMapGroup(groupName, sizeof(groupName));
    
    if (StrEqual(groupName, INVALID_GROUP, false))
    {
        KvFindGroupOfMap(map_kv, mapName, groupName, sizeof(groupName));
    }
    
    //Add the map to all the memory queues.
    new mapmem = GetConVarInt(cvar_vote_mem) + 1;
    new catmem = GetConVarInt(cvar_vote_catmem);
    AddToMemoryArray(mapName, vote_mem_arr, mapmem);
    AddToMemoryArray(groupName, vote_catmem_arr, (mapmem > catmem) ? mapmem : catmem);
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
    
    /*AddToTopMenu(
        admin_menu, "umc_mapvote", TopMenuObject_Item, UMCMenu_MapVote,
        umc_menu, "sm_umc_startmapvote", ADMFLAG_CHANGEMAP
    );*/
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
        //Make and display Change Map menu
        //...
        // 1. Auto Select   (Random using limits)
        // 2. Manual Select (Pick from a list)
        
        new Handle:menu = CreateAutoManualMenu(HandleAM_ChangeMap, "Select a Map");
        DisplayMenu(menu, param, 0);
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
        new Handle:menu = CreateAutoManualMenu(HandleAM_NextMap, "Select a Map");
        DisplayMenu(menu, param, 0);
    }
}


//Handles the Change Map option in the menu.
/*public UMCMenu_MapVote(Handle:topmenu, TopMenuAction:action, TopMenuObject:objectID, param,
                       String:buffer[], maxlength)
{
    if (action == TopMenuAction_DisplayOption)
    {
        Format(buffer, maxlength, "Start a Map Vote");
    }
    else if (action == TopMenuAction_SelectOption)
    {
        new Handle:menu = CreateAutoManualMenu(HandleAM_MapVote, "Populate Vote");
        DisplayMenu(menu, param, 0);
    }
}*/


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
            CloseHandle(menu_tries[param1]);
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
            CloseHandle(menu_tries[param1]);
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
    
    
    DoMapChange(client, UMC_ChangeMapTime:when, nextMap, nextGroup);
}


//
AutoChangeMap(client)
{
    new Handle:menu = CreateMenu(Handle_AutoChangeWhenMenu);
    SetMenuTitle(menu, "Change Map When?");

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
        //Log Failure
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
            CloseHandle(menu_tries[param1]);
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
        //Log Failure
    }
}


//
/*public HandleAM_MapVote(Handle:menu, MenuAction:action, param1, param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            if (param2 == AMMENU_ITEM_INDEX_AUTO)
            {
                AutoMapVote();
            }
            else
            {
                ManualMapVote();
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
}*/


//Builds and returns a map group selection menu.
Handle:CreateGroupMenu(MenuHandler:handler, bool:limits=false)
{
    //Initialize the menu
    new Handle:menu = CreateMenu(handler);
    SetMenuTitle(menu, "Select a Group");
    
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
    
    if (!StrEqual(group, INVALID_GROUP))
    {
        //Make it so we can return to the previous menu.
        SetMenuExitBackButton(menu, true);
    }
    
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


