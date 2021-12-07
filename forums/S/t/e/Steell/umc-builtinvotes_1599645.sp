/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                             Ultimate Mapchooser - Built-in Voting                             *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools_sound>
#include <umc-core>
#include <umc_utils>
#include <builtinvotes>

#undef REQUIRE_PLUGIN

//Auto update
#include <updater>
#define UPDATE_URL "http://www.ccs.neu.edu/home/steell/sourcemod/ultimate-mapchooser/updateinfo-umc-builtinvotes.txt"


new bool:vote_active;
new Handle:g_menu;

//Plugin Information
public Plugin:myinfo =
{
    name        = "[UMC] Built-in Voting",
    author      = "Steell",
    description = "Extends Ultimate Mapchooser to allow usage of Built-in Votes.",
    version     = PL_VERSION,
    url         = "http://forums.alliedmods.net/showthread.php?t=134190"
};


//
public OnAllPluginsLoaded()
{
    new String:game[20];
    GetGameFolderName(game, sizeof(game));
    
    if (!StrEqual(game, "tf", false))
    {
        SetFailState("UMC Built-in Vote support is only available for Team Fortress 2.");
    }
    
    if (LibraryExists("builtinvotes"))
    {
        UMC_RegisterVoteManager("core", VM_MapVote, VM_MapVote, VM_CancelVote);
    }
    
#if AUTOUPDATE_ENABLE
    if (LibraryExists("updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
#endif
}


//
/* public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "builtinvotes"))
    {
        UMC_RegisterVoteManager("core", VM_MapVote, VM_MapVote, VM_CancelVote);
    }
}


//
public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "builtinvotes"))
	{
		UMC_UnregisterVoteManager("core");
	}
} */


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
//                                        CORE VOTE MANAGER                                       //
//************************************************************************************************//

//
public Action:VM_MapVote(duration, Handle:vote_items, Handle:clients, const String:startSound[])
{
    decl clientArr[MAXPLAYERS+1];
    new count = 0;
    new size = GetArraySize(clients);
    for (new i = 0; i < size; i++)
    {
        clientArr[count++] = GetArrayCell(clients, i);
    }
    
    if (count == 0)
    {
        LogError("Could not start core vote, no players to display vote to!");
        return Plugin_Stop;
    }
    
    //new Handle:menu = BuildVoteMenu(vote_items, "Map Vote Menu Title", Handle_MapVoteResults);
    g_menu = BuildVoteMenu(vote_items, Handle_MapVoteResults);
            
    vote_active = true;
    
    if (g_menu != INVALID_HANDLE && DisplayBuiltinVote(g_menu, clientArr, count, duration))
    {
        if (strlen(startSound) > 0)
            EmitSoundToAll(startSound);
        
        return Plugin_Continue;
    }
            
    vote_active = false;
    
    //ClearVoteArrays();
    LogError("Could not start built-in vote.");
    return Plugin_Stop;
}


//
Handle:BuildVoteMenu(Handle:vote_items, BuiltinVoteHandler:callback)
{
    new size = GetArraySize(vote_items);
    if (size <= 1)
    {
        DEBUG_MESSAGE("Not enough items in the vote. Aborting.")
        LogError("VOTING: Not enough maps to run a map vote. %i maps available.", size);
        return INVALID_HANDLE;
    }
    
    //Begin creating menu
    new Handle:menu = CreateBuiltinVote(Handle_VoteMenu, BuiltinVoteType_NextLevelMult,
                                        BuiltinVoteAction_End|BuiltinVoteAction_Cancel);
        
    SetBuiltinVoteResultCallback(menu, callback); //Set callback
        
    new Handle:voteItem;
    decl String:info[MAP_LENGTH], String:display[MAP_LENGTH];
    for (new i = 0; i < size; i++)
    {
        voteItem = GetArrayCell(vote_items, i);
        GetTrieString(voteItem, "info", info, sizeof(info));
        GetTrieString(voteItem, "display", display, sizeof(display));
        
        if (StrEqual(info, EXTEND_MAP_OPTION))
        {
            AddBuiltinVoteItem(menu, BUILTINVOTES_EXTEND, BUILTINVOTES_EXTEND);
        }
        else
        {
            AddBuiltinVoteItem(menu, info, display);
        }
    }
    
    //DEBUG_MESSAGE("Setting proper pagination.")
    //SetCorrectMenuPagination(menu, voteSlots);
    //DEBUG_MESSAGE("Vote menu built successfully.")
    return menu; //Return the finished menu.
}


//
public VM_CancelVote()
{
    if (vote_active)
    {
        vote_active = false;
        CancelBuiltinVote();
    }
}


//Called when a vote has finished.
public Handle_VoteMenu(Handle:menu, BuiltinVoteAction:action, param1, param2)
{
    switch (action)
    {
        case BuiltinVoteAction_End:
        {
            DEBUG_MESSAGE("MenuAction_End")
            CloseHandle(menu);
        }
        case BuiltinVoteAction_Cancel:
        {
            DisplayBuiltinVoteFail(g_menu, BuiltinVoteFailReason:param1);
            if (vote_active)
            {
                DEBUG_MESSAGE("Vote Cancelled")
                UMC_VoteManagerVoteCancelled("core");
            }
        }
    }
}


//Handles the results of a vote.
public Handle_MapVoteResults(Handle:menu, num_votes, num_clients, const client_info[][2], num_items,
                             const item_info[][2])
{
    new Handle:results = ConvertVoteResults(menu, num_clients, client_info, num_items, item_info);

    UMC_VoteManagerVoteCompleted("core", results, Handle_UMCVoteResponse);
    
    //Free Memory
    new size = GetArraySize(results);
    new Handle:item;
    new Handle:clients;
    for (new i = 0; i < size; i++)
    {
        item = GetArrayCell(results, i);
        GetTrieValue(item, "clients", clients);
        CloseHandle(clients);
        CloseHandle(item);
    }
    CloseHandle(results);
}


//Converts results of a vote to the format required for UMC to process votes.
Handle:ConvertVoteResults(Handle:menu, num_clients, const client_info[][2], num_items,
                          const item_info[][2])
{
    new Handle:result = CreateArray();
    new itemIndex;
    new Handle:voteItem, Handle:voteClientArray;
    decl String:info[MAP_LENGTH], String:disp[MAP_LENGTH];
    for (new i = 0; i < num_items; i++)
    {
        itemIndex = item_info[i][BUILTINVOTEINFO_ITEM_INDEX];
        GetBuiltinVoteItem(menu, itemIndex, info, sizeof(info), disp, sizeof(disp));
        
        voteItem = CreateTrie();
        voteClientArray = CreateArray();
        
        SetTrieString(voteItem, "info", info);
        SetTrieString(voteItem, "display", disp);
        SetTrieValue(voteItem, "clients", voteClientArray);
        
        PushArrayCell(result, voteItem);
        
        for (new j = 0; j < num_clients; j++)
        {
            if (client_info[j][BUILTINVOTEINFO_CLIENT_ITEM] == itemIndex)
                PushArrayCell(voteClientArray, client_info[j][BUILTINVOTEINFO_CLIENT_INDEX]);
        }
    }
    return result;
}


public Handle_UMCVoteResponse(UMC_VoteResponse:response, const String:param[])
{
    switch (response)
    {
        case VoteResponse_Success:
        {
            decl String:map[MAP_LENGTH];
            strcopy(map, sizeof(map), param);
            DisplayBuiltinVotePass(g_menu, map);
        }
        case VoteResponse_Runoff:
        {
            DisplayBuiltinVoteFail(g_menu, BuiltinVoteFail_NotEnoughVotes);
        }
        case VoteResponse_Tiered:
        {
            decl String:map[MAP_LENGTH];
            strcopy(map, sizeof(map), param);
            DisplayBuiltinVotePass(g_menu, map);
        }
        case VoteResponse_Fail:
        {
            DisplayBuiltinVoteFail(g_menu, BuiltinVoteFail_NotEnoughVotes);
        }
    }
}