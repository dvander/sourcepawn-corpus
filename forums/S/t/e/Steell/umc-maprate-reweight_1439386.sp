#pragma semicolon 1
#define PL_VERSION "0.1"

#include <sourcemod>
#include <ultimate-mapchooser>

#define DEBUG 0

//Welcome to UMC Map Rate Reweight by Steell!
/**
 * This plugin is meant to serve as a functional and useful example of Ultimate Mapchooser's
 * dynamic map reweighting system. This system allows other plugins to affect how a map's weight
 * is calculated when UMC is performing it's randomization algorithm.
 */
public Plugin:myinfo =
{
    name = "UMC Map Rate Reweight",
    author = "Steell",
    description = "Reweights maps in UMC based off of their average rating in Map Rate.",
    version = PL_VERSION,
    url = ""
}

#define SQL_STATEMENT "SELECT map, AVG(rating) FROM %s GROUP BY map"

/******** GLOBALS *********/

//Our SQL information
new String:table_name[255];
new String:db_name[255];

//We are going to cache this information early on so that UMC isn't held up by an SQL query.
new Handle:maps_array = INVALID_HANDLE;
new Handle:average_ratings = INVALID_HANDLE;

//Flag stating if we're ready to reweight (do we have information in the cache?)
new bool:reweight = false;

/**************************/


//Initialize the cache.
public OnPluginStart()
{
    maps_array = CreateArray(64);
    average_ratings = CreateArray();
}


//Make sure UMC is running (REQUIRE_PLUGIN is still defined so it should be)
/*public OnAllPluginsLoaded()
{
    if (!LibraryExists("ultimate-mapchooser"))
    {
        LogError("Ultimate Mapchooser is not loaded, plugin cannot run.");
        SetFailState("Ultimate Mapchooser not loaded.");
    }
}*/


//Repopulate the cache on each map start.
public OnConfigsExecuted()
{
    //OnAllPluginsLoaded();
    
    new Handle:cvarTable = FindConVar("maprate_table");
    new Handle:cvarDbConfig = FindConVar("maprate_db_config");
    
    GetConVarString(cvarTable, table_name, sizeof(table_name));
    GetConVarString(cvarDbConfig, db_name, sizeof(db_name));
    if (cvarTable != INVALID_HANDLE)
    {
        if (SQL_CheckConfig(db_name))
            SQL_TConnect(Handle_SQLConnect, db_name);
        else
            LogError("Database configuration \"%s\" does not exist.", db_name);
    }
    else
    {
        LogError("Plugin \"Map Rate\" is not loaded, cannot determine which SQL table to look for ratings in.");
        SetFailState("Plugin \"Map Rate\" is not loaded.");
    }    
}


//Handles the database connection
public Handle_SQLConnect(Handle:owner, Handle:db, const String:error[], any:data)
{
    if (db == INVALID_HANDLE)
    {
        LogError("Error establishing a database connection: %s", error);
        return;
    }
    
    new String:query[100];
    new bufferSize = sizeof(table_name) * 2 + 1;
    new String:tableName[bufferSize];
    
    SQL_QuoteString(db, table_name, tableName, bufferSize);
    Format(query, sizeof(query), SQL_STATEMENT, tableName);
    
    SQL_TQuery(db, Handle_MapRatingQuery, query);
    
    CloseHandle(db);
}


//Handles the results of the query
public Handle_MapRatingQuery(Handle:owner, Handle:hQuery, const String:error[], any:data)
{
    if (hQuery == INVALID_HANDLE)
    {
        LogError("Unable to fetch maps from database: \"%s\"", error);
        return;
    }
    
    decl String:map[64];
    new Float:average;
    while (SQL_FetchRow(hQuery))
    {
        SQL_FetchString(hQuery, 0, map, sizeof(map));
        average = SQL_FetchFloat(hQuery, 1);
        PushArrayString(maps_array, map);
        PushArrayCell(average_ratings, average);
    }
    reweight = true;
    
#if DEBUG

    for (new i = 0; i < GetArraySize(maps_array); i++)
    {
        GetArrayString(maps_array, i, map, sizeof(map));
        LogMessage("DEBUG: %s - %f", map, GetArrayCell(average_ratings, i));
    }

#endif    
}


//Close the database handle at the end of the map.
public OnMapEnd()
{
    reweight = false;
    ClearArray(maps_array);
    ClearArray(average_ratings);
}


//Reweight a map.
public UMC_OnReweightMap(const String:map[])
{
    if (!reweight) return;
    
    new index = FindStringInArray(maps_array, map);
    if (index >= 0)
    {
        UMC_AddWeightModifier(GetArrayCell(average_ratings, index));
#if DEBUG
        LogMessage("Map %s was reweighted!", map);
#endif
    }
}