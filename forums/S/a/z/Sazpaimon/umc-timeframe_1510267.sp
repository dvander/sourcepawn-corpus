/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                          Ultimate Mapchooser - Time-Based Condition                           *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
 
#pragma semicolon 1

#include <sourcemod>
#include <umc-core>
#include <umc_utils>

public Plugin:myinfo =
{
    name = "[UMC] Time-Based Condition",
    author = "Sazpaimon",
    description = "Allows users to how much time has passed before.",
    version = PL_VERSION,
    url = "http://forums.alliedmods.net/showthread.php?t=134190"
}

#define TIMELIMIT_KEY_MAP_MIN "allow_every"
#define TIMELIMIT_KEY_GROUP_MIN "default_allow_every"

new String:g_time;
new Handle:map_trie    = INVALID_HANDLE;
new Handle:cat_trie = INVALID_HANDLE;

public OnPluginStart()
{
    map_trie = CreateTrie();
    cat_trie = CreateTrie();
}
public OnPluginEnd(){
	CloseHandle(map_trie);
	CloseHandle(cat_trie);
}

//Called after all config files were executed.
public OnConfigsExecuted()
{
    g_time = GetTime();
    new thing;    
    decl String:mapName[MAP_LENGTH];
    GetCurrentMap(mapName, sizeof(mapName));
    SetTrieValue(map_trie, mapName, g_time);
    GetTrieValue(map_trie, mapName, thing);
    DEBUG_MESSAGE("Map %s Time %i.", mapName, thing)
    
    decl String:groupName[MAP_LENGTH];
    UMC_GetCurrentMapGroup(groupName, sizeof(groupName));
    SetTrieValue(cat_trie, groupName, g_time);
}

//Called when UMC wants to know if this map is excluded
public Action:UMC_OnDetermineMapExclude(Handle:kv, const String:map[], const String:group[],
                                        bool:isNom, bool:forMapChange)
{
    new defaultNumHours;
    new numHours;
    new playTime;

    KvRewind(kv);
    if (KvJumpToKey(kv, group))
    {
        defaultNumHours = KvGetNum(kv, TIMELIMIT_KEY_GROUP_MIN);
    
        if (KvJumpToKey(kv, map))
        {    
            numHours = KvGetNum(kv, TIMELIMIT_KEY_MAP_MIN, defaultNumHours);
            KvGoBack(kv);
        }
        KvGoBack(kv);
    }
    
    g_time = GetTime();
    
    if (GetTrieValue(cat_trie, group, playTime)) {
        if (g_time >= (playTime + (numHours * 3600))) {
            DEBUG_MESSAGE("Map %s Time %i Play time %i.", group, g_time, playTime)
            RemoveFromTrie(cat_trie, group);
            return Plugin_Continue;
        }
    }
    if((GetTrieValue(map_trie, map, playTime))) {
        if (g_time >= (playTime + (numHours * 3600))) {
            DEBUG_MESSAGE("Map %s Time %i Play time %i.", map, g_time, playTime)
            RemoveFromTrie(map_trie, map);
            return Plugin_Continue;
        }
    }

    if(!GetTrieValue(cat_trie, group, playTime) && !GetTrieValue(map_trie, map, playTime)) {
        return Plugin_Continue;
    }

    DEBUG_MESSAGE("Map %s is excluded due to Time Frame Limits (Will be available at %i, currently %i).", map, (playTime + (numHours * 3600)), g_time)
    return Plugin_Stop;
}


