/**
 * =============================================================================
 * SourceMod AdsQL Advertisements Plugin
 *
 * circa 2011 by PharaohsPaw - http://www.pwng.net
 *
 * A plugin which loads advertisements from a MySQL database based on
 * the game type(s) or unique per-server ID strings configured in the
 * provided standalone web interface.
 *
 * AdsQL is a FORK project based upon the "MySQL Advertisements"
 * SourceMod plugin (sm_adsmysql) and web interface which were
 * originally created/designed by:
 *
 * 	(c)2009 <eVa>Dog - http://www.theville.org
 *
 * which were released in 2009, but are no longer being updated or
 * maintained by anyone.
 *
 * Both I and the original author also credit the original work in the
 * standalone SourceMod "advertisements" plugin:
 *
 * 	(c)2009 DJ Tsunami - http://www.tsunami-productions.nl
 *
 * SourceMod (C)2004-2008 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_VERSION "1.7.8"
#define CVAR_DISABLED "OFF"
#define CVAR_ENABLED  "ON"

new Handle:hAdminMenu = INVALID_HANDLE;
new Handle:hDatabase = INVALID_HANDLE;
new Handle:hTimer = INVALID_HANDLE;
new Handle:hInterval = INVALID_HANDLE;
new Handle:g_hCenterAd[MAXPLAYERS + 1];

new bool:bAdsBeingSetupAlready = false;
new bool:bHaveAdsDisplayTimerAlready = false ;
new bool:bMapJustStarted = false;

// this stuff is necessary to make the cvars we *WANT* public
// show up - busted a2s_rules on linux (from hlstatsx.sp)
// BIG THANK YOU TO THE HLSTATSX:CE folks for the coding example
new Handle:adsql_version = INVALID_HANDLE;
new Handle:adsql_serverid = INVALID_HANDLE;

new Handle:adsql_debug = INVALID_HANDLE;

new bool:g_bTickrate = true;

new Float:g_fTime;

new g_iFrames = 0;
new g_iTickrate;
new g_AdCount;
new g_Current;

new String:SrvIDFile[256];
new idFileTime = 0;

//static String:g_sSColors[4][13]  = {"{DEFAULT}","{LIGHTGREEN}", "{TEAM}", "{GREEN}"};
static String:g_sSColors[5][13]  = {"{DEFAULT}","{LIGHTGREEN}", "{TEAM}", "{GREEN}", "{OLIVE}"};
static String:g_sTColors[13][12] = {"{WHITE}",       "{RED}",        "{GREEN}",   "{BLUE}",    "{YELLOW}",    "{PURPLE}",    "{CYAN}",      "{ORANGE}",    "{PINK}",      "{OLIVE}",     "{LIME}",      "{VIOLET}",    "{LIGHTBLUE}"};
//static g_iSColors[4]             = {1, 3, 3, 4};
static g_iSColors[5]             = {1, 3, 3, 4, 5};
static g_iTColors[13][3]         = {{255, 255, 255}, {255, 0, 0},    {0, 255, 0}, {0, 0, 255}, {255, 255, 0}, {255, 0, 255}, {0, 255, 255}, {255, 128, 0}, {255, 0, 128}, {128, 255, 0}, {0, 255, 128}, {128, 0, 255}, {0, 128, 255}};

new String:GameName[64];
new String:GameSearchName[64];
new String:GameSrvID[64];

new String:g_type[1024][2];
new String:g_text[1024][192];
new String:g_flags[1024][27];
new String:g_game[1024][64];

public Plugin:myinfo =
{
	name = "AdsQL Advertisements System",
	author = "PharaohsPaw",
	description = "Displays server ads from a MySQL database",
	version = PLUGIN_VERSION,
	url = "http://www.pwng.net"
}

public OnPluginStart()
{
	RegAdminCmd("sm_reloadads", Admin_ReloadAds, ADMFLAG_CONVARS, "- Reload the Ads ");
	
	hInterval = CreateConVar("adsql_interval", "45", "Time interval (seconds) between ads displayed", FCVAR_PLUGIN);

	HookConVarChange(hInterval, ConVarChange_Interval);

	// our two public cvars:
	
	adsql_version = CreateConVar("adsql_version", PLUGIN_VERSION, "AdsQL Plugin Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_SPONLY);
	
	// make this one public because its useful to see it in HLSW etc.
	adsql_serverid = CreateConVar("adsql_serverid", "", "ID string to uniquely identify this server when loading ads.\nThe SUPPORTED place to define this is:\n\n  * (sm_basepath)/configs/adsql/serverid.txt *\n\nto properly support running >1 server per dedicated server \"tree\".\nSee install docs and FAQ for details.", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_SPONLY);

	// hey, why not, lets make a debug cvar...
	adsql_debug = CreateConVar("adsql_debug", "0", "Enable debug logging for AdsQL plugin: 0=off, 1=on", FCVAR_PLUGIN);


	// init GameSrvID in case it never gets defined (no serverid.txt)
	GetConVarString(adsql_serverid, GameSrvID, sizeof(GameSrvID));


	// set up our serverid.txt file path
	BuildPath(Path_SM,SrvIDFile,sizeof(SrvIDFile),"configs/adsql/serverid.txt");

	if (FileExists(SrvIDFile))
	{
		// we probably want to try to read our server id before we hook
		CheckSrvIDFile();
	}

	// hook changes to the server id string cvar so we can reload ads
	HookConVarChange(adsql_serverid, NewIDSetupAds);
	
	GetGameFolderName(GameName, sizeof(GameName));

	if (GetConVarBool(adsql_debug))

		LogMessage("[AdsQL] - GetGameFolderName() returned '%s'", GameName);


	/* Now that we know which game we are running on, we can set
	 * GameSearchName.  The purpose of GameSearchName, as the name
	 * suggests, is to store the string representing the game name
	 * we want to use to search for ads for this game in our SQL
	 * queries.
	 *
	 * If there were not some game types whose game folder
	 * names were substring matches for the game folder names of
	 * other games (example: left4dead is a substring match for
	 * left4dead2), we would not need to do this, but since this
	 * IS the case for some games, it is easier/better to define a
	 * a different string variable for ads searches that we can
	 * customize when we need to if GameName makes a bad
	 * string to use in an SQL LIKE query (a substring search).
	 *
	 * We still need GameName elsewhere in this plugin -- some
	 * games need a different method to display the ad to the
	 * client -- so for now we will keep GameName intact and
	 * use a separate string variable we can modify when we need
	 * to.
	 *
	 * If we are running on one of these "special" games, we set
	 * GameSearchName to match the special name the web interface
	 * also uses (and stores in the database) for that game.
	 * Otherwise, we just copy the value of GameName to
	 * GameSearchName, since the game folder name is not going to
	 * cause us problems getting the wrong ads.
	 *
	 * More special cases are easily added below.
	 *
	 *
	 * I would use a switch/case if working with string values in a
	 * switch block did not require so much other work.
	 */

	/* These our our "special cases" that need a special name:	*/

	if (!strcmp(GameName, "left4dead2"))
	{
		strcopy(GameSearchName, sizeof(GameSearchName), "l4d2");
	}
	else if (!strcmp(GameName, "cstrike_beta"))
	{
		strcopy(GameSearchName, sizeof(GameSearchName), "cssbeta");
	}
	else if (!strcmp(GameName, "tf_beta"))
	{
		strcopy(GameSearchName, sizeof(GameSearchName), "teamfortbeta");
	}
	else

		/* The default situation - no special treatment needed for
		 * the game we are running on.
		 */

		strcopy(GameSearchName, sizeof(GameName), GameName);

	if (GetConVarBool(adsql_debug))

		LogMessage("[AdsQL] - Set GameSearchName to '%s'.", GameSearchName);
	
	new Handle:topmenu;

	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}

	// The databases.cfg section we read our config from --
	// I could change this but we want to make it easy for
	// existing users of the sm_adsmysql plugin to switch:

	SQL_TConnect(DBConnect, "admintools");

	// load our configuration from cfg/sourcemod/adsql.cfg
	// auto-create a default adsql.cfg is false because
	// it will write an adsql_serverid cvar in the file and
	// this is NOT a good way to define it for people who
	// run >1 game out of the same tree (precisely why I
	// have serverid.txt under (sm base dir)/configs/adsql)
	AutoExecConfig(false, "adsql");
	
}


/* to deal with a2s_rules problems with linux
 * again, this comes from the hlstatsx folks...
 */
public OnConfigsExecuted()
{
	if (GuessSDKVersion() != SOURCE_SDK_EPISODE2VALVE)
		return;

	decl String:buffer[128];

	GetConVarString(adsql_version, buffer, sizeof(buffer));
	SetConVarString(adsql_version, buffer);

	GetConVarString(adsql_serverid, buffer, sizeof(buffer));
	SetConVarString(adsql_serverid, buffer);

}


public IsGameSrvIDEmpty()
{
	// Check and make sure GameSrvID isnt empty before we use
	// it in an SQL query - we cannot search by Server ID if
	// it is empty or we will get unexpected results

	if (!strlen(GameSrvID))
	{
		LogMessage("[AdsQL] - adsql_serverid is undefined");

		return true;

	}
	else
		LogMessage("[AdsQL] - Using Server ID '%s' for ads search", GameSrvID);

	return false;

}


public CheckSrvIDFile()
{

	if (!FileExists(SrvIDFile))
	{
		LogMessage("[AdsQL] - Server ID file configs/adsql/serverid.txt not read - file not found.");
		return false;
	}

	new idNewFileTime = GetFileTime(SrvIDFile, FileTime_LastChange);

	if (idFileTime != idNewFileTime)
	{
		if (idFileTime != 0)
		{
			LogMessage("[AdsQL] - Updated configs/adsql/serverid.txt detected");
		}

		// update our global serverid.txt timestamp
		idFileTime = idNewFileTime;

		new Handle:FileHandle = OpenFile(SrvIDFile, "r");
		decl String:serveridbuf[128];
		while (!IsEndOfFile(FileHandle))
		{
			ReadFileLine(FileHandle, serveridbuf, sizeof(serveridbuf));
			TrimString(serveridbuf);
			if(strncmp(serveridbuf, "//", 2) != 0)
			{
				SetConVarString(adsql_serverid, serveridbuf);
				GetConVarString(adsql_serverid, GameSrvID, sizeof(GameSrvID));
				LogMessage("[AdsQL} - Read Server ID '%s' from configs/adsql/serverid.txt", serveridbuf);

				// break so we dont keep iterating through while loop, which means
				// we will only read the FIRST uncommented line from the file!
				break;
			}
		
		}

		CloseHandle(FileHandle);
	}

	return true;
}

public NewIDSetupAds(Handle:convar, const String:oldValue[], const String:newValue[])
{
	GetConVarString(adsql_serverid, GameSrvID, sizeof(GameSrvID));

	// Do some checking on how exactly the server id changed.
	//
	// If we just started the server up, this cvar will be undefined.
	// But if it is defined in a .cfg file that gets executed, even
	// THAT counts as a value change.  In which case we should avoid
	// "reloading" the ads before we have even loaded them the first
	// time - or in other words, wait 10 seconds to load ads if the map
	// just started, rather than 2 seconds

	if (!bAdsBeingSetupAlready)
	{

		// Did the map/server just start? If so then lets wait 10 seconds to
		// set up the ads instead of 2 seconds...
		if (bMapJustStarted)
		{
			if (GetConVarBool(adsql_debug))
			
				LogMessage("[AdsQL] - Server ID changed on map start, SetupAds in 10 seconds");

			bAdsBeingSetupAlready = true;


			/* try letting SetupAds clear this instead, we have
			 *  multiple functions looking at it now
			
			bMapJustStarted = false;	*/

			CreateTimer(10.0, SetupAds, _);
		}
		else
		{
			if (GetConVarBool(adsql_debug))

				LogMessage("[AdsQL] - adsql_serverid has changed - reloading ads in 2 seconds");

			bAdsBeingSetupAlready = true;

			CreateTimer(2.0, SetupAds, _);
		}
	}
	else
	{
		if (GetConVarBool(adsql_debug))
		
			LogMessage("[AdsQL] - bAdsBeingSetupAlready is true, avoiding creating another SetupAds timer");

	}

	return true;
}

public DBConnect(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Database failure: %s", error);
		LogMessage("[AdsQL] - Unable to connect to database");
		return;
	}
	if (GetConVarBool(adsql_debug))
	{
		LogMessage("[AdsQL] - DBconnect: hndl value = '%i'", hndl);
	}

	hDatabase = hndl;
	LogMessage("[AdsQL] - Connected Successfully to Database");

	//LogAction(0, 0, "[AdsQL] - Connected Successfully to Database");
}

public OnMapStart()
{
	g_Current = 0;

	
	// Check to see if serverid.txt has changed since last map
	// and if so, load our new server ID
	CheckSrvIDFile();

	bMapJustStarted = true;

	// This REALLY shouldnt be necessary to check, but just in case...
	// The idea is to avoid setting up another timer if we already have one
	//
	// dont laugh!  it WORKS!
	//
	if (!bAdsBeingSetupAlready)
	{
		if (GetConVarBool(adsql_debug))
	
			LogMessage("[AdsQL] - OnMapStart hook: bAdsBeingSetupAlready is false, creating SetupAds timer");

		bAdsBeingSetupAlready = true;

		CreateTimer(10.0, SetupAds, _);

	}

	
}

public OnMapEnd()
{
	// change our boolean because if we dont do it we will end up
	// calling KillTimer on a dead timer on the next map and FAIL

	if (GetConVarBool(adsql_debug))
	{
		LogMessage("[AdsQL] - OnMapEnd hook: Setting bHaveAdsDisplayTimerAlready to false");
	}

	bHaveAdsDisplayTimerAlready = false;

}


public Action:SetupAds(Handle:timer, any:client)
{

	/* reset boolean bMapJustStarted now that we are
	 * protected by bAdsBeingSetupAlready		*/

	bMapJustStarted = false;


	/* reset the "current ad displaying" counter
	 * since we are loading/reloading the ads	*/
	
	g_Current = 0;

	/* Set UTF8 DB Session parameters before *every time* we load ads	*/

	decl String:utfquery[32];

	Format(utfquery, sizeof(utfquery), "SET NAMES 'utf8';");

	if (SQL_FastQuery(hDatabase, utfquery, sizeof(utfquery)))
	{
		if (GetConVarBool(adsql_debug))
		{
			LogMessage("[AdsQL] - SET NAMES 'utf8' query succeeded.");
		}
	}
	else
	{
		if (GetConVarBool(adsql_debug))
		{
			LogMessage("[AdsQL] - SET NAMES 'utf8' query FAILED!");
		}
	}

	/* Now prepare our ad search query */

	decl String:query[1024];

	if (IsGameSrvIDEmpty())
	{
		Format(query, sizeof(query), "SELECT * FROM adsmysql WHERE ( game='All' OR (game LIKE '%%%s%%' AND gamesrvid='All') ) ORDER BY id;", GameSearchName);
	}
	else
	{
		Format(query, sizeof(query), "SELECT * FROM adsmysql WHERE ( game='All' OR (game LIKE '%%%s%%' AND gamesrvid='All') OR (game LIKE '%%%s%%' AND gamesrvid LIKE '%%%s%%') ) ORDER BY id;", GameSearchName, GameSearchName, GameSrvID);
	}

	SQL_TQuery(hDatabase, ParseAds, query, client, DBPrio_High);
	
	// ok, here is where we can avoid setting up more than one ad display timer
	// but we cant strictly go by whether handles == INVALID_HANDLE... or close
	// them when we are done (this causes compile errors) -- so we will just use
	// some boolean variables instead.  Also note that calling KillTimer() on a
	// handle left over from the last map will get us stuck without an ad display
	// timer.  Nothing else after the KillTimer call will execute!  This is why
	// we set bHaveAdsDisplayTimerAlready to false with our OnMapEnd() hook.  It
	// lets us CreateTimer on the existing handle after a map change.  You only
	// want to KillTimer if we are still on the same map (examples: interval
	// changed, server id changed, etc.)

	if (!bHaveAdsDisplayTimerAlready)
	{
		if (GetConVarBool(adsql_debug))
		{
			LogMessage("[AdsQL] - SetupAds: We do not already have an Ad Display Timer");
		}

		// create our timer but check the return value

		if ((hTimer = CreateTimer(GetConVarInt(hInterval) * 1.0, Timer_DisplayAds, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE)) != INVALID_HANDLE)
		{
			bHaveAdsDisplayTimerAlready = true;
			
			if(GetConVarBool(adsql_debug))
			{
				LogMessage("[AdsQL] - SetupAds: Created a New Ad Display Timer");
			}

		}
		else
		{
			bHaveAdsDisplayTimerAlready = false;

			LogMessage("[AdsQL] - SetupAds: Failed to Create a New Ad Display Timer!");

		}
	}
	else
	{
		// apparently we have a timer going already

		if (GetConVarBool(adsql_debug))
		{

			LogMessage("[AdsQL] - SetupAds: We seem to already have an Ads Display Timer");

		}


		/* Try to kill the existing Ads Display Timer.  KillTimer does
		 * not have a return value we can check... */

		if (CloseHandle(hTimer))
		{
			if (GetConVarBool(adsql_debug))

				LogMessage("[AdsQL] - SetupAds: Successfully deleted existing Ad Display Timer - Will start another one now.");

			hTimer = INVALID_HANDLE;
		}
		else
		{
			if (GetConVarBool(adsql_debug))

				LogMessage("[AdsQL] - SetupAds: CloseHandle on existing Ad Display Timer failed, do we have >1 already?  Not creating another!");

			bAdsBeingSetupAlready = false;

			return;

		}

		if ((hTimer = CreateTimer(GetConVarInt(hInterval) * 1.0, Timer_DisplayAds, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE)) != INVALID_HANDLE)
		{
			bHaveAdsDisplayTimerAlready = true;

			if (GetConVarBool(adsql_debug))

				LogMessage("[AdsQL] - SetupAds: Replaced existing Ad Display Timer");

		}
		else
		{

			bHaveAdsDisplayTimerAlready = false;

			LogMessage("[AdsQL] - SetupAds: Failed to replace existing Ad Display Timer!");

		}

	}

	// Now set bAdsBeingSetupAlready back to false, allowing something else to
	// call ads setup once again
	
	if (GetConVarBool(adsql_debug))

		LogMessage("[AdsQL] - SetupAds finishing, resetting bAdsBeingSetupAlready to false");

	bAdsBeingSetupAlready = false;

}


public ParseAds(Handle:owner, Handle:hQuery, const String:error[], any:client)
{
	g_AdCount = 0;
	
	if (hQuery != INVALID_HANDLE)
	{
		if(SQL_GetRowCount(hQuery) > 0)
		{			
			// to store our game type read into so we can clean it
			// up before storing the ad game in g_game[g_AdCount]
			// larger buf because the field could have several games
			// listed
			decl String:g_gametemp[192];

			// temporary string to show the gamesrvid field as read from
			// the database
			decl String:g_gamesrvid[512];

			PrintToConsole(client, "[AdsQL] %i rows found", SQL_GetRowCount(hQuery));
			while(SQL_FetchRow(hQuery))
			{
				SQL_FetchString(hQuery, 1, g_type[g_AdCount], 2);
				SQL_FetchString(hQuery, 2, g_text[g_AdCount], 192);
				SQL_FetchString(hQuery, 3, g_flags[g_AdCount], 27);
				//SQL_FetchString(hQuery, 4, g_game[g_AdCount], 64);
				SQL_FetchString(hQuery, 4, g_gametemp, 192);
				SQL_FetchString(hQuery, 5, g_gamesrvid, 512);

				PrintToConsole(client, "[AdsQL] Ad %i found in database: %s, %s, %s, %s [serverids: %s]", g_AdCount, g_type[g_AdCount], g_text[g_AdCount], g_flags[g_AdCount], g_gametemp, g_gamesrvid);
				
				// NOW CLEAN UP THE GAME NAME FIELD
				// We really should not have gotten a row with our SELECT call unless
				// it was an ad we wanted for this game, so we can go right to
				// the business of cleaning up (replacing) the value of the game
				// field.  There is no reason to even do any checks.  Just DOOoo eet!
				//
				// Note: We *NEED* the right game name later because of differences in
				//       in the function we use to display the ad to the clients.
				//
				// The *ONLY* reason I am not simply scrapping the game field fetch and
				// just copying GameName right into g_game[g_AdCount] is so the above
				// PrintToConsole call displays the data "as read from the database".
				//
				// The game field *could* have "All" set in it but that has no special
				// meaning beyond whether we should fetch it or not, so no need really
				// to keep "All" in there.  Just replace the game field.
				
				strcopy(g_game[g_AdCount], sizeof(GameName), GameName);

				g_AdCount++;
			}
		}
		CloseHandle(hQuery);
		
		if (client > 0)
			PrintToChat(client, "[AdsQL] Reloaded Ads");
	}
	else
	{
		LogMessage("[AdsQL] - ParseAds: DB Query failed! %s", error);
	}

}

public Action:Timer_DisplayAds(Handle:timer) 
{
	decl AdminFlag:fFlagList[16], String:sBuffer[256], String:sFlags[27], String:sText[192], String:sType[2], String:sGame[64];
	
	if (g_Current == g_AdCount) 
	{
		g_Current = 0;
	}
	

	if (GetConVarBool(adsql_debug))
	{

		LogMessage("[AdsQL] Firing Ad %i/%i: %s, %s, %s, %s", g_Current, g_AdCount, g_type[g_Current], g_text[g_Current], g_flags[g_Current], g_game[g_Current]);

	}
	
	sType = g_type[g_Current];
	sText = g_text[g_Current];
	sFlags = g_flags[g_Current];
	sGame = g_game[g_Current];
	
	g_Current++;
	
	if (StrEqual(sGame, GameName) || StrEqual(sGame, "All"))
	{
	
		new bool:bAdmins = StrEqual(sFlags, ""), bool:bFlags = !StrEqual(sFlags, "none");
		if (bFlags) 
		{
			FlagBitsToArray(ReadFlagString(sFlags), fFlagList, sizeof(fFlagList));
		}
		
		if (StrContains(sText, "{TICKRATE}")   != -1) 
		{
			IntToString(g_iTickrate, sBuffer, sizeof(sBuffer));
			ReplaceString(sText, sizeof(sText), "{TICKRATE}",   sBuffer);
		}
		
		if (StrContains(sText, "{CURRENTMAP}") != -1) 
		{
			GetCurrentMap(sBuffer, sizeof(sBuffer));
			ReplaceString(sText, sizeof(sText), "{CURRENTMAP}", sBuffer);
		}
		
		if (StrContains(sText, "{DATE}")       != -1) 
		{
			FormatTime(sBuffer, sizeof(sBuffer), "%m/%d/%Y");
			ReplaceString(sText, sizeof(sText), "{DATE}",       sBuffer);
		}
		
		if (StrContains(sText, "{TIME}")       != -1) 
		{
			FormatTime(sBuffer, sizeof(sBuffer), "%I:%M:%S%p");
			ReplaceString(sText, sizeof(sText), "{TIME}",       sBuffer);
		}
		
		if (StrContains(sText, "{TIME24}")     != -1) 
		{
			FormatTime(sBuffer, sizeof(sBuffer), "%H:%M:%S");
			ReplaceString(sText, sizeof(sText), "{TIME24}",     sBuffer);
		}
		
		if (StrContains(sText, "{TIMELEFT}")   != -1) 
		{
			new iMins, iSecs, iTimeLeft;
			
			if (GetMapTimeLeft(iTimeLeft) && iTimeLeft > 0) 
			{
				iMins = iTimeLeft / 60;
				iSecs = iTimeLeft % 60;
			}
			
			Format(sBuffer, sizeof(sBuffer), "%d:%02d", iMins, iSecs);
			ReplaceString(sText, sizeof(sText), "{TIMELEFT}",   sBuffer);
		}
		
		if (StrContains(sText, "\\n")          != -1) 
		{
			Format(sBuffer, sizeof(sBuffer), "%c", 13);
			ReplaceString(sText, sizeof(sText), "\\n",          sBuffer);
		}
		
		new iStart = StrContains(sText, "{BOOL:");
		while (iStart != -1) 
		{
			new iEnd = StrContains(sText[iStart + 6], "}");
			
			if (iEnd != -1) 
			{
				decl String:sConVar[64], String:sName[64];
				
				strcopy(sConVar, iEnd + 1, sText[iStart + 6]);
				Format(sName, sizeof(sName), "{BOOL:%s}", sConVar);
				
				new Handle:hConVar = FindConVar(sConVar);
				if (hConVar != INVALID_HANDLE) 
				{
					ReplaceString(sText, sizeof(sText), sName, GetConVarBool(hConVar) ? CVAR_ENABLED : CVAR_DISABLED);
				}
			}
			
			new iStart2 = StrContains(sText[iStart + 1], "{BOOL:") + iStart + 1;
			if (iStart == iStart2) 
			{
				break;
			} 
			else 
			{
				iStart = iStart2;
			}
		}
		
		iStart = StrContains(sText, "{");
		while (iStart != -1) 
		{
			new iEnd = StrContains(sText[iStart + 1], "}");
			
			if (iEnd != -1) 
			{
				decl String:sConVar[64], String:sName[64];
				
				strcopy(sConVar, iEnd + 1, sText[iStart + 1]);
				Format(sName, sizeof(sName), "{%s}", sConVar);
				
				new Handle:hConVar = FindConVar(sConVar);
				if (hConVar != INVALID_HANDLE) 
				{
					GetConVarString(hConVar, sBuffer, sizeof(sBuffer));
					ReplaceString(sText, sizeof(sText), sName, sBuffer);
				}
			}
			
			new iStart2 = StrContains(sText[iStart + 1], "{") + iStart + 1;
			if (iStart == iStart2) 
			{
				break;
			} 
			else 
			{
				iStart = iStart2;
			}
		}
		
		if (StrContains(sType, "C") != -1) 
		{
			for (new i = 1, iClients = GetClientCount(); i <= iClients; i++) 
			{
				if (IsClientInGame(i) && !IsFakeClient(i) &&
						((!bAdmins && !(bFlags && HasFlag(i, fFlagList))) ||
						 bAdmins && (GetUserFlagBits(i) & ADMFLAG_GENERIC ||
						 GetUserFlagBits(i) & ADMFLAG_ROOT))) 
				{
					PrintCenterText(i, sText);
					
					new Handle:hCenterAd;
					g_hCenterAd[i] = CreateDataTimer(1.0, Timer_CenterAd, hCenterAd, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
					WritePackCell(hCenterAd,   i);
					WritePackString(hCenterAd, sText);
				}
			}
		}
		
		if (StrContains(sType, "H") != -1) 
		{
			for (new i = 1, iClients = GetClientCount(); i <= iClients; i++) 
			{
				if (IsClientInGame(i) && !IsFakeClient(i) &&
						((!bAdmins && !(bFlags && HasFlag(i, fFlagList))) ||
						 bAdmins && (GetUserFlagBits(i) & ADMFLAG_GENERIC ||
						 GetUserFlagBits(i) & ADMFLAG_ROOT))) 
				{
					PrintHintText(i, sText);
				}
			}
		}
		
		if (StrContains(sType, "M") != -1) 
		{
			new Handle:hPl = CreatePanel();
			DrawPanelText(hPl, sText);
			SetPanelCurrentKey(hPl, 10);
			
			for (new i = 1, iClients = GetClientCount(); i <= iClients; i++) 
			{
				if (IsClientInGame(i) && !IsFakeClient(i) &&
						((!bAdmins && !(bFlags && HasFlag(i, fFlagList))) ||
						 bAdmins && (GetUserFlagBits(i) & ADMFLAG_GENERIC ||
						 GetUserFlagBits(i) & ADMFLAG_ROOT))) 
				{
					SendPanelToClient(hPl, i, Handler_DoNothing, 10);
				}
			}
			
			CloseHandle(hPl);
		}
		
		if (StrContains(sType, "T") != -1) 
		{
			decl String:sColor[16];
			new iColor = -1, iPos = BreakString(sText, sColor, sizeof(sColor));
			
			for (new i = 0; i < sizeof(g_sTColors); i++) 
			{
				if (StrEqual(sColor, g_sTColors[i])) 
				{
					iColor = i;
				}
			}
			
			if (iColor == -1) 
			{
				iPos     = 0;
				iColor   = 0;
			}
			
			new Handle:hKv = CreateKeyValues("Stuff", "title", sText[iPos]);
			KvSetColor(hKv, "color", g_iTColors[iColor][0], g_iTColors[iColor][1], g_iTColors[iColor][2], 255);
			KvSetNum(hKv,   "level", 1);
			KvSetNum(hKv,   "time",  10);
			
			for (new i = 1, iClients = GetClientCount(); i <= iClients; i++) 
			{
				if (IsClientInGame(i) && !IsFakeClient(i) &&
						((!bAdmins && !(bFlags && HasFlag(i, fFlagList))) ||
						 bAdmins && (GetUserFlagBits(i) & ADMFLAG_GENERIC ||
						 GetUserFlagBits(i) & ADMFLAG_ROOT))) 
				{
					CreateDialog(i, hKv, DialogType_Msg);
				}
			}
			CloseHandle(hKv);
		}
		
		if (StrContains(sType, "S") != -1) 
		{
			new iTeamColors = StrContains(sText, "{TEAM}"), String:sColor[4];
			
			Format(sText, sizeof(sText), "%c%s", 1, sText);
			
			for (new c = 0; c < sizeof(g_iSColors); c++) 
			{
				if (StrContains(sText, g_sSColors[c])) 
				{
					Format(sColor, sizeof(sColor), "%c", g_iSColors[c]);
					ReplaceString(sText, sizeof(sText), g_sSColors[c], sColor);
				}
			}
			
			if (iTeamColors == -1) 
			{
				for (new i = 1, iClients = GetClientCount(); i <= iClients; i++) 
				{
					if (IsClientInGame(i) && !IsFakeClient(i) &&
							((!bAdmins && !(bFlags && HasFlag(i, fFlagList))) ||
							 bAdmins && (GetUserFlagBits(i) & ADMFLAG_GENERIC ||
							 GetUserFlagBits(i) & ADMFLAG_ROOT))) 
					{
						PrintToChat(i, sText);
					}
				}
			} 
			else 
			{
				for (new i = 1, iClients = GetClientCount(); i <= iClients; i++) 
				{
					if (IsClientInGame(i) && !IsFakeClient(i) &&
							((!bAdmins && !(bFlags && HasFlag(i, fFlagList))) ||
							 bAdmins && (GetUserFlagBits(i) & ADMFLAG_GENERIC ||
							 GetUserFlagBits(i) & ADMFLAG_ROOT))) 
					{
						if (StrEqual(GameName, "tf") || StrEqual(GameName, "cstrike"))

							SayText2(i, sText);
						else

							PrintToChat(i, sText);
					}
				}
			}
		}
	}
}

bool:HasFlag(iClient, AdminFlag:fFlagList[16])
{
	new iFlags = GetUserFlagBits(iClient);
	if (iFlags & ADMFLAG_ROOT) 
	{
		return true;
	} 
	else 
	{
		for (new i = 0; i < sizeof(fFlagList); i++) 
		{
			if (iFlags & FlagToBit(fFlagList[i])) 
			{
				return true;
			}
		}
		
		return false;
	}
}

public Action:Timer_CenterAd(Handle:timer, Handle:pack) 
{
	decl String:sText[256];
	static iCount = 0;
	
	ResetPack(pack);
	new iClient = ReadPackCell(pack);
	ReadPackString(pack, sText, sizeof(sText));
	
	if (IsClientInGame(iClient) && ++iCount < 5) 
	{
		PrintCenterText(iClient, sText);
		
		return Plugin_Continue;
	} 
	else 
	{
		iCount = 0;
		g_hCenterAd[iClient] = INVALID_HANDLE;
		
		return Plugin_Stop;
	}
}

SayText2(to, const String:message[]) 
{
	new Handle:hBf = StartMessageOne("SayText2", to);
	
	if (hBf != INVALID_HANDLE) 
	{
		BfWriteByte(hBf,   to);
		BfWriteByte(hBf,   true);
		BfWriteString(hBf, message);
		
		EndMessage();
	}
}

public Handler_DoNothing(Handle:menu, MenuAction:action, param1, param2) 
{
}

public ConVarChange_Interval(Handle:convar, const String:oldValue[], const String:newValue[]) 
{

	if (GetConVarBool(adsql_debug))
		
		LogMessage("[AdsQL] - entering ConVarChange_Interval");

	/* evidently this is not good enough for
	 * a conditional to check...  but we should
	 * also probably still check it somehow

	if (hTimer != INVALID_HANDLE)	*/


	if (bHaveAdsDisplayTimerAlready)
	{
		if (GetConVarBool(adsql_debug))

			LogMessage("[AdsQL] - ConVarChange_Interval: We seem to have an Ads Display Timer Already, trying to kill it");
	
		/* KillTimer doesnt have a return value 
		 * so we dont know if it was successful or not */
		if(CloseHandle(hTimer))
		{
			if (GetConVarBool(adsql_debug))

				LogMessage("[AdsQL] - ConVarChange_Interval: Successfully killed existing Ads Display Timer, starting a new one");

			hTimer = INVALID_HANDLE;

		}
		else
		{
			if (GetConVarBool(adsql_debug))

				LogMessage("[AdsQL] - ConVarChange_Interval: CloseHandle failed on existing display timer, do we have >1 already?  Not creating another!");

			return;

		}
	}
	else if (bMapJustStarted)
	{
		if(GetConVarBool(adsql_debug))
	
			LogMessage("[AdsQL] - ConVarChange_Interval: Map Just Started - Avoiding creating an Ads Display Timer since SetupAds will be setting one up");

		return;

	}

	else
	{
		if(GetConVarBool(adsql_debug))
	
			LogMessage("[AdsQL] - ConVarChange_Interval: Boolean says we do not already have an Ads Display Timer.  Will create one before we leave.");

	}

	if ((hTimer = CreateTimer(GetConVarInt(hInterval) * 1.0, Timer_DisplayAds, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE)) != INVALID_HANDLE)
	{
		if(GetConVarBool(adsql_debug))

			LogMessage("[AdsQL] - ConVarChange_Interval: Successfully created replacement Ads Display Timer - exiting hook now");

		bHaveAdsDisplayTimerAlready = true;

	}
	else
	{
	
		if(GetConVarBool(adsql_debug))

			LogMessage("[AdsQL] - ConVarChange_Interval: Failed to create replacement Ads Display Timer! Exiting -EWTF");

		bHaveAdsDisplayTimerAlready = false;
	}

}


public Action:Admin_ReloadAds(client, args)
{

	if (!bAdsBeingSetupAlready)
	{
		bAdsBeingSetupAlready = true;
		CreateTimer(0.5, SetupAds, client);
	}

	return Plugin_Handled;

}

public OnGameFrame() 
{
	if (g_bTickrate) 
	{
		g_iFrames++;
		
		new Float:fTime = GetEngineTime();
		if (fTime >= g_fTime) 
		{
			if (g_iFrames == g_iTickrate) 
			{
				g_bTickrate = false;
			}
			else 
			{
				g_iTickrate = g_iFrames;
				g_iFrames   = 0;    
				g_fTime     = fTime + 1.0;
			}
		}
	}
}

// ############################################################################
// Admin Menus
// ############################################################################

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu")) 
	{
		hAdminMenu = INVALID_HANDLE;
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == hAdminMenu)
	{
		return;
	}
	
	hAdminMenu = topmenu;

	new TopMenuObject:player_commands = FindTopMenuCategory(hAdminMenu, ADMINMENU_SERVERCOMMANDS);

	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hAdminMenu,
			"sm_reloadads",
			TopMenuObject_Item,
			AdminMenu_ReloadAds,
			player_commands,
			"sm_reloadads",
			ADMFLAG_CONVARS);
	}
}

public AdminMenu_ReloadAds(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Reload Ads");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		if (!bAdsBeingSetupAlready)
		{
			bAdsBeingSetupAlready = true;
			CreateTimer(0.5, SetupAds, _);
		}
	}
}
