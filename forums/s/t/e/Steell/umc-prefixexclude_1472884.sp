/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                             Ultimate Mapchooser - Prefix Exclusion                            *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
 
#pragma semicolon 1

#include <sourcemod>
#include <umc-core>
#include <umc_utils>
#include <umc-playerlimits>
#include <regex>

public Plugin:myinfo =
{
    name = "[UMC] Player Limits",
    author = "Steell",
    description = "Allows users to specify player limits for maps.",
    version = PL_VERSION,
    url = "http://forums.alliedmods.net/showthread.php?t=134190"
}

new Handle:cvar_nom_ignore = INVALID_HANDLE;
new Handle:cvar_display_ignore = INVALID_HANDLE;
new Handle:cvar_prev = INVALID_HANDLE;

new Handle:prefix_array = INVALID_HANDLE;

public OnPluginStart()
{
    cvar_prev = CreateConVar(
        "sm_umc_prefixexclude_memory",
        "1",
        "Specifies how many previously played prefixes to exclude. 1 = Current Only",
        0, true, 0.0
    );

    cvar_nom_ignore = CreateConVar(
        "sm_umc_prefixexclude_nominations",
        "0",
        "Determines if nominations are exempt from being excluded due to Prefix Exclusion.",
        0, true, 0.0, true, 1.0
    );
    
    cvar_display_ignore = CreateConVar(
        "sm_umc_prefixexclude_display",
        "0",
        "Determines if maps being displayed are exempt from being excluded due to Prefix Exclusion.",
        0, true, 0.0, true, 1.0
    );
    
    AutoExecConfig(true, "umc-prefixexclude");
    
    prefix_array = CreateArray(ByteCountToCells(MAP_LENGTH));
}


public OnMapStart()
{
    decl String:prefix[MAP_LENGTH];
    GetCurrentMapPrefix(prefix, sizeof(prefix));
    AddToMemoryArray(prefix, prefix_array, GetConVarInt(cvar_prev));
}


GetCurrentMapPrefix(String:buffer[], maxlen)
{
    decl String:currentMap[MAP_LENGTH];
    GetCurrentMap(currentMap, sizeof(currentMap));
    
    static Handle:re = INVALID_HANDLE;
    if (re == INVALID_HANDLE)
        CompileRegex("^([a-zA-Z0-9]*)_(.*)$");
        
    if (MatchRegex(re, currentMap) > 1)
        GetRegexSubString(re, 1, buffer, maxlen);
    else
        strcopy(buffer, maxlen, "");
}


//Called when UMC wants to know if this map is excluded
public Action:UMC_OnDetermineMapExclude(Handle:kv, const String:map[], const String:group[],
                                        bool:isNomination, bool:forMapChange)
{
    if (isNomination && GetConVarBool(cvar_nom_ignore))
        return Plugin_Continue;
        
    if (!forMapChange && GetConVarBool(cvar_display_ignore))
        return Plugin_Continue;
    
    decl String:prefix[MAP_LENGTH];
    new size = GetArraySize(prefix_array);
    for (new i = 0; i < size; i++)
    {
        GetArrayString(prefix_array, i, prefix, sizeof(prefix));
        if (StrContains(map, prefix, false) == 0)
            return Plugin_Stop;
    }
    
    return Plugin_Continue;
}