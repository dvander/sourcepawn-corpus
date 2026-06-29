//	------------------------------------------------------------------------------------
//	Filename:		noms.sp
//	Author:			Malachi
//	Version:		(see PLUGIN_VERSION)
//	Description:
//
// * Changelog (date/version/description):
// * 2013-01-23	-	0.1.1		-	initial dev version
// * 2013-03-17 -   0.1.1.1     -   Added new array handling
// * 2013-03-17 -   0.1.2		-   Changed so map and player name print on same line.
// * 2013-03-17 -   0.1.3		-   Check for console, check for empty noms list.
// * 2013-03-17 -   0.1.4		-   Changed to use Plugin_Handled, added color.
// * 2013-03-17 -   0.1.5		-   added test for map vote completed.
// * 2013-03-17 -   0.1.6		-   fixed chat not showing up
// * 2013-03-18 -   1.0.0		-   bumped version for release, commented out debug msg
// * 2013-03-18 -   1.0.1		-   uncommented accidentally commented out debug msg, return !noms command to chat
// * 2013-03-18 -   1.1.0		-   added tests to honor "/" silent chat
// * 2013-03-20 -   1.2.0		-   Billeh: code cleanup, now use registered command
// * 2013-03-20 -   1.2.1		-   style cleanup
// * 2013-03-21 -   1.2.2		-   Number maps in printout, check for mapchooser dependency
// * 2013-03-21 -   1.2.3		-   Show next map if vote already happened. (lifted from basetriggers.smx)
// *                                
//	------------------------------------------------------------------------------------


#include <sourcemod>
#include <mapchooser>

#pragma semicolon 1

#define PLUGIN_VERSION	"1.2.3"
#define ADMIN_NOMINATION "Console"
#define VOTE_COMPLETED "Next Map:"
#define EMPTY_NOMSLIST "-empty-"
#define NAME_SIZE 32

new Handle:g_NominateMaps = INVALID_HANDLE;
new Handle:g_NominateOwners = INVALID_HANDLE;


public Plugin:myinfo = 
{
	name = "Noms",
	author = "Malachi",
	description = "prints nominated maps to clients",
	version = PLUGIN_VERSION,
	url = "www.necrophix.com"
}


public OnPluginStart()
{
	g_NominateMaps   = CreateArray(ByteCountToCells(NAME_SIZE));
	g_NominateOwners = CreateArray(1);
	RegConsoleCmd("sm_noms", Command_Noms, "Display list of nominated maps to players.");
}


public OnAllPluginsLoaded()
{
	// Check dependencies
	if ( FindPluginByFile("mapchooser.smx") == INVALID_HANDLE )
	{
		SetFailState("[Noms]: ERROR - required plugin mapchooser.smx not found, exiting");
	}

//	mapchooser = LibraryExists("mapchooser");

}


public Action:Command_Noms(client, args)
{

	if (HasEndOfMapVoteFinished())
	{
		decl String:map[64];
		GetNextMap(map, sizeof(map));
		PrintToChatAll("\x04[Noms]\x01 %s %s", VOTE_COMPLETED, map);
	}
	else
	{
		displayNoms();
	}

	return Plugin_Handled;
}


public displayNoms()
{
	decl String:map[NAME_SIZE];
	decl String:name[NAME_SIZE];
	new owner;
	new size;

	ClearArray(g_NominateMaps);
	ClearArray(g_NominateOwners);
	
	GetNominatedMapList(g_NominateMaps, g_NominateOwners);
	size = GetArraySize(g_NominateMaps);

	if (size == 0)
	{
		//nothing nominated
		PrintToChatAll("\x04[Noms]\x01 %s", EMPTY_NOMSLIST);
	}
	else
	{
		//For each nominated map ...
		for (new i = 0; i < size; i++)
		{		
			GetArrayString(g_NominateMaps, i, map, sizeof(map));
			owner = GetArrayCell(g_NominateOwners, i);

			// Did an admin force a nomination?
			if (owner == 0)
			{
				name = ADMIN_NOMINATION;
			}
			else
			{
				GetClientName(owner, name, sizeof(name));
			}

			PrintToChatAll("\x04[Noms]\x01 %d. %s (%s)", (i+1), map, name);
		}
	}

}
