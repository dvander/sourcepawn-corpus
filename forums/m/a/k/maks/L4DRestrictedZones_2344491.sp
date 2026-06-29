/********************************************************************************************
* Plugin	: L4DRestrictedZones
* Version	: 1.1.2
* Game		: Left 4 Dead (only affects survivors)
* Author	: SkyDavid (djromero)
* Testers	: SkyVash, SkyCougar (and the entire Sky Clan)
* Website	: www.sky.zebgames.com
* 
* Purpose	: This plugins prevents Survivors from going into some restricted zones, 
* 			  such as the ramp on No Mercy finale.
* 
* Version 1.0:
* 		- Restricts access (by teleporting player) to the closet near the elevator in
*    	  the No Mercy hospital and underneath the ramp on the finale.
* 
* Version 1.1:
* 		- Fixed some issues about restricted zones not being reset on map start if the map 
* 	      didn't have any restricted location.
*		- Improved timer: Now the checks doesn't occur that often if the player is far away
* 		  from any restricted spot. They become more often when the players get closer to
* 		  a restricted spot. Original idea from: ChillyWI (forums.alliedmods.net).
* 		- Timer is disabled on maps that doesn't have restricted zones.
* 		- Added the following console commands:
* 		  * rz_storeloc: 	It stores a location as a restricted zone. Radious is optional.
* 		  * rz_storemoveto: Stores the 'move-to' location for last restricted zone stored 
* 							with the rz_storeloc command.
* 		  * rz_deletenear: 	It deletes all the restricted zones near the current location of
* 							the player. If radius is not provided, 100 is used as default.
* 							It prints out all the deleted locations.
* 		  * rz_deleteall:	It deletes all the restricted zones for the current map.
* 
* Version 1.1.1:
* 		- Fixed an issue when loading the .CFG file.
* 
* Version 1.1.2
* 		- Added public cvar.
*
* Version 1.2 mod (17.09.2015)
* 		The author the modification MAKS (steamcommunity.com/profiles/76561198025355822/)
* 		Fixed syntax errors with using transitional syntax.
*
*********************************************************************************************/
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#pragma newdecls required
#define PLUGIN_VERSION "1.2 mod (19.09.2015)"
#define MAX_RESTRICTEDSPOTS 10
#define FCVAR_SS_ADDED (1<<18)

char sg_map[100];
Handle hg_checkTimer;
float fg_arrayXYZ[MAX_RESTRICTEDSPOTS][7];
float fg_arrayNewRestrictedSpot[3];
float fg_newRestrictedSpot_Radious;
float fg_arrayNewRestrictedSpot_MoveTo[3];
float fg_MINdistance;
float fg_timeInterval;
int ig_restrictedSpots_Count;
int ig_deleteAllCount;
bool bg_pauseTimer;

public Plugin myinfo = 
{
	name = "L4D Restricted Zones",
	author = "SkyDavid",
	description = "This plugins allows you to restrict specific L4D zones",
	version = PLUGIN_VERSION,
	url = "www.sky.zebgames.com"
}

public void OnPluginStart()
{
	// We register the version cvar
	CreateConVar("l4d_restrictedzones_version",     PLUGIN_VERSION, "Version of L4D Restricted zones plugin", FCVAR_SS_ADDED|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	// We register all of the commands...
	RegAdminCmd("rz_deleteall",   CmdDeleteAll,     ADMFLAG_CHEATS, "Deletes all the restricted zones for the current map");
	RegAdminCmd("rz_deletenear",  CmdDeleteNear,    ADMFLAG_CHEATS, "Deletes all the restricted zones near the current location. Radious is optional.");
	RegAdminCmd("rz_storeloc",    CmdStoreLocation, ADMFLAG_CHEATS, "Stores the current location as a restricted zone. Radious is optional.");
	RegAdminCmd("rz_storemoveto", CmdStoreMoveTo,   ADMFLAG_CHEATS, "Stores the current location as a 'Move-to' spot for last restricted zone.");

	bg_pauseTimer = false;
	hg_checkTimer = null;
}

void KillCheckTimer()
{
	if (hg_checkTimer != null)
	{
		KillTimer(hg_checkTimer, false);
		hg_checkTimer = null;
	}
}

public bool CheckPermissions(int client)
{
	if (!IsClientConnected(client))
	{
		return false;
	}

	if (!IsClientInGame(client))
	{
		return false;
	}

	if (IsFakeClient(client))
	{
		return false;
	}

	return true;
}

public Action CmdDeleteAll(int client, int args)
{
	// Checks permission ...
	if (!CheckPermissions(client))
	{
		return Plugin_Handled;
	}

	// We pause the timer
	bg_pauseTimer = true;

	// We requiere a validation ...
	if (ig_deleteAllCount == 0)
	{
		// We unpause the timer
		bg_pauseTimer = false;

		ReplyToCommand (client, "[RZ] Please execute this command again to confirm that you want to delete all the restricted zones for this map.");
		ig_deleteAllCount = 1;
		return Plugin_Handled;
	}

	// Now we proceed to delete the file
	if (!DeleteAllZones())
	{
		ReplyToCommand (client, "[RZ] There were no restricted zones stored for this map!");
	}
	else
	{
		ReplyToCommand (client, "[RZ] All the restricted zones for this map has been deleted!");
	}

	// We reload spots
	LoadSpots();

	// We unpause the timer
	bg_pauseTimer = false;
	return Plugin_Handled;
}

public Action CmdDeleteNear (int client, int args)
{
	// Checks permission ...
	if (!CheckPermissions(client))
	{
		return Plugin_Handled;
	}

	// We pause the timer
	bg_pauseTimer = true;

	// We determine the radius
	char arg[50];
	float radius;

	// if radius was not provided, we use 50 by default
	if (args < 1)
	{
		radius = 50.00;
	}
	else
	{
		GetCmdArg(1, arg, sizeof(arg)-1);
		radius = StringToFloat(arg);

		if ((radius < 10.0)||(radius > 1000.0))
		{
			ReplyToCommand (client, "[RZ] The radius must be between 10-1000. Command aborted.");

			// We unpause the timer
			bg_pauseTimer = false;

			return Plugin_Handled;
		}
	}

	// We reload the spots
	LoadSpots();

	// Deletion of near spots ...
	DeleteNearSpots(client, radius);

	// We unpause the timer
	bg_pauseTimer = false;
	return Plugin_Handled;
}

void DeleteNearSpots(int client, float radius)
{
	float Coord[3];
	float Comp[3];
	float Dif[3];
	float fDist;
	int deletedCount;
	int i;
	int j;

	deletedCount = 0;

	// We store the current location of the player
	GetClientAbsOrigin(client, Coord);

	// Checks all spots of the map
	for (i=0; i<ig_restrictedSpots_Count; i++)
	{
		// Get restricted spot's coordinates
		Comp[0] = fg_arrayXYZ[i][0];
		Comp[1] = fg_arrayXYZ[i][1];
		Comp[2] = fg_arrayXYZ[i][2];

		// Gets the difference on each ...
		for (j=0;j<3;j++)
		{
			Dif[j] = Coord[j] - Comp[j];
		}

		// calculates distance
		fDist = SquareRoot(Dif[0]*Dif[0] + Dif[1]*Dif[1] + Dif[2]*Dif[2]);

		// Gets absolute value
		if (fDist < 0)
		{
			fDist = fDist * -1;
		}

		// If player is close to the spot, we mark it for deletion ...
		if (fDist < radius)
		{
			deletedCount++;

			fg_arrayXYZ[i][0] = 0.0;
			fg_arrayXYZ[i][1] = 0.0;
			fg_arrayXYZ[i][2] = 0.0;
		}
	}

	// If we had spots to delete ...
	if (deletedCount > 0)
	{
		// We store all of the locations .. (except for the ones being deleted)
		if (!StoreAllRestrictedZones()) 
		{
			// If an error was found ..
			ReplyToCommand(client, "[RZ] An error was found when deleting the restricted zones.", deletedCount);
		}
		else
		{
			// We reply the command
			ReplyToCommand(client, "[RZ] %i zones has been deleted.", deletedCount);
		}

		// We reload the locations
		LoadSpots();
	}
	else
	{
		ReplyToCommand(client, "[RZ] There were no restricted zones near the current location.");
	}
}

public Action CmdStoreLocation(int client, int args)
{
	// Checks permission ...
	if (!CheckPermissions(client))
	{
		return Plugin_Handled;
	}

	// We pause the timer
	bg_pauseTimer = true;

	// If we reached the limit of restricted points ...
	if (ig_restrictedSpots_Count == MAX_RESTRICTEDSPOTS)
	{
		ReplyToCommand (client, "[RZ] The maximum of %i restricted zones has been reached.", MAX_RESTRICTEDSPOTS);

		// We unpause the timer
		bg_pauseTimer = false;
		return Plugin_Handled;
	}

	char arg[50];
	float radius;

	// if radius was not provided, we use 50 by default
	if (args < 1)
	{
		radius = 50.00;
	}
	else
	{
		GetCmdArg(1, arg, sizeof(arg)-1);
		radius = StringToFloat(arg);

		if ((radius < 10.0)||(radius > 1000.0))
		{
			ReplyToCommand (client, "[RZ] The radius must be between 10-1000. Command aborted.");

			// We unpause the timer
			bg_pauseTimer = false;
			return Plugin_Handled;
		}
	}

	// We store the current location of the player
	GetClientAbsOrigin(client, fg_arrayNewRestrictedSpot);
	fg_newRestrictedSpot_Radious = radius;

	ReplyToCommand(client, "[RZ] Restricted zone noted. Radious set on %f. Use rz_storemoveto to indicate the 'move to' location and store the zone.", radius);	

	// We unpause the timer
	bg_pauseTimer = false;
	return Plugin_Handled;
}

public Action CmdStoreMoveTo (int client,int args)
{
	// Checks permission ...
	if (!CheckPermissions(client))
	{
		return Plugin_Handled;
	}

	// We pause the timer
	bg_pauseTimer = true;

	// Check if location was stored ...
	if ((fg_arrayNewRestrictedSpot[0]==0.0)&&(fg_arrayNewRestrictedSpot[1]==0.0)&&(fg_arrayNewRestrictedSpot[2]==0.0))
	{
		ReplyToCommand(client, "[RZ] You need to first select a restricted location with the rz_storeloc.");

		// We unpause the timer
		bg_pauseTimer = false;
		return Plugin_Handled;
	}

	// We store the current location of the player
	GetClientAbsOrigin(client, fg_arrayNewRestrictedSpot_MoveTo);

	// First we validate if the Move-To location is not within the reach of the restricted spot's radio ...
	if (Distance (fg_arrayNewRestrictedSpot_MoveTo[0], fg_arrayNewRestrictedSpot_MoveTo[1], fg_arrayNewRestrictedSpot_MoveTo[2], fg_arrayNewRestrictedSpot[0], fg_arrayNewRestrictedSpot[1], fg_arrayNewRestrictedSpot[2]) <= fg_newRestrictedSpot_Radious)
	{
		ReplyToCommand(client, "[RZ] This location is too close to the restricted spot. Please move away from it.");

		// We unpause the timer
		bg_pauseTimer = false;
		return Plugin_Handled;
	}

	// Now we store all the info to the data file ...
	if (!StoreRestrictedZone())
	{
		ReplyToCommand (client, "[RZ] There was an error storing the restricted zone.");
	}
	else
	{
		ReplyToCommand (client, "[RZ] Restricted zone was stored.");
	}

	// We reload spots
	LoadSpots();

	// We unpause the timer
	bg_pauseTimer = false;
	return Plugin_Handled;
}

public bool DeleteAllZones()
{
	// We define the path + filename
	char fileName[256];
	BuildPath (Path_SM, fileName, sizeof(fileName)-1, "gamedata/rz_%s.cfg", sg_map);

	// We create the file
	File hFile = OpenFile(fileName, "w+");
	if (hFile == null)
	{
		return false;
	}

	CloseHandle(hFile);
	return true;
}

public bool StoreRestrictedZone()
{
	// We define the path + filename
	char fileName[256];
	BuildPath (Path_SM, fileName, sizeof(fileName)-1, "gamedata/rz_%s.cfg", sg_map);

	// We create the file
	File hFile = OpenFile(fileName, "a+");
	if (hFile == null)
	{
		return false;
	}

	// We find the end of the file
	FileSeek(hFile, 0, SEEK_END);

	// We store the info into the file
	if (!WriteFileLine (hFile, "%f\t%f\t%f\t%f\t%f\t%f\t%f\t", fg_arrayNewRestrictedSpot[0], fg_arrayNewRestrictedSpot[1], fg_arrayNewRestrictedSpot[2], fg_newRestrictedSpot_Radious, fg_arrayNewRestrictedSpot_MoveTo[0], fg_arrayNewRestrictedSpot_MoveTo[1], fg_arrayNewRestrictedSpot_MoveTo[2]))
	{
		// Error, so we abort ...
		CloseHandle(hFile);
		return false;
	}

	CloseHandle(hFile);
	return true;
}

public bool StoreAllRestrictedZones()
{
	// We define the path + filename
	char fileName[256];
	BuildPath (Path_SM, fileName, sizeof(fileName)-1, "gamedata/rz_%s.cfg", sg_map);

	// We create the file
	File hFile = OpenFile(fileName, "w+");
	if (hFile == null)
	{
		return false;
	}

	// We find the start of the file
	FileSeek(hFile, 0, SEEK_SET);

	int i;

	// Checks all spots of the map
	for (i=0; i<ig_restrictedSpots_Count; i++)
	{
		// If the zone was marked for deletion, we skip it ...
		if ((fg_arrayXYZ[i][0] == 0.0)&&(fg_arrayXYZ[i][1] == 0.0)&&(fg_arrayXYZ[i][2] == 0.0))
		{
			break;
		}

		// We store the info into the file
		if (!WriteFileLine (hFile, "%f\t%f\t%f\t%f\t%f\t%f\t%f\t", fg_arrayXYZ[i][0], fg_arrayXYZ[i][1], fg_arrayXYZ[i][2], fg_arrayXYZ[i][3], fg_arrayXYZ[i][4], fg_arrayXYZ[i][5], fg_arrayXYZ[i][6]))
		{
			PrintToChatAll("error writing line");
			// Error, so we abort ...
			CloseHandle(hFile);
			return false;
		}
	}

	CloseHandle(hFile);
	return true;
}

public void LoadSpots()
{
	// We reset the variables
	ig_restrictedSpots_Count = 0;

	// We define the path + filename
	char fileName[256];

	// we declare the line
	char line[500];

	// we get the coordinates
	char data[7][201];

	BuildPath (Path_SM, fileName, sizeof(fileName)-1, "gamedata/rz_%s.cfg", sg_map);

	// We read the file
	File hFile = OpenFile(fileName, "r");
	if (hFile == null)
	{
		return;
	}

	FileSeek (hFile, 0, SEEK_SET);

	while (!IsEndOfFile(hFile))
	{
		// we read the line
		if (!ReadFileLine(hFile, line, sizeof(line)-1))
		{
			break;
		}

		if (ExplodeString(line, "\t", data, 7, 200) != 7)
		{
			break;
		}

		// We store them
		int i;
		int j;
		i = ig_restrictedSpots_Count;
		for (j=0; j<7; j++)
		{
			fg_arrayXYZ[i][j] = StringToFloat(data[j]);
		}

		// We increment the counter ...
		ig_restrictedSpots_Count++;
	}

	CloseHandle(hFile);

	// This determines if we should start or not the timer 
	if (ig_restrictedSpots_Count == 0)
	{
		// We kill the timer
		KillCheckTimer();
	}
	else
	{
		// We set the minimum distance to a high value ...
		fg_MINdistance = 999999.99;

		// We kill the timer
		KillCheckTimer();

		// We start a timer ....
		fg_timeInterval = 1.0; // We start off with 1 second between checks, just in case there's a restricted spot near spawn 
		hg_checkTimer = CreateTimer(fg_timeInterval, LocationCheckThread, _, TIMER_REPEAT);
	}
}

public void OnMapStart()
{
	// Load current Map name
	GetCurrentMap(sg_map, sizeof(sg_map)-1);

	// Loads spots
	LoadSpots();

	// We reset the deleteall count ...
	ig_deleteAllCount = 0;
}

public void OnMapEnd()
{
	// We kill the timer
	KillCheckTimer();
}

public void CheckTimerReset()
{
	float time;

	// We set the check interval depending on the minimum distance ... (Thx to ChillyWI for his idea).
	if (fg_MINdistance > 4000.0)
	{
		time = 19.00;
	}
	else if (fg_MINdistance > 2000.0)
	{
		time = 10.00;
	}
	else if (fg_MINdistance > 1300.0)
	{
		time = 6.00;
	}
	else if (fg_MINdistance > 900.0)
	{
		time = 4.00;
	}
	else if (fg_MINdistance > 400.0)
	{
		time = 2.00;
	}
	else
	{
		time = 0.5;
	}

	// If the current interval is different from the one we should have according to the current distance ...
	if (fg_timeInterval != time)
	{
		// We store the new interval ..
		fg_timeInterval = time;

		// We kill the timer
		KillCheckTimer();

		// We reset the timer with the new interval ...
		hg_checkTimer = CreateTimer(fg_timeInterval, LocationCheckThread, _, TIMER_REPEAT);
	}
}

// This function returns the distance between the 2 coordinates ...
public float Distance (float x1, float y1, float z1, float x2, float y2, float z2)
{
	static float fsDist;
	static float fsX;
	static float fsY;
	static float fsZ;

	fsX = x1 - x2;
	fsY = y1 - y2;
	fsZ = z1 - z2;

	fsDist = SquareRoot(fsX*fsX + fsY*fsY + fsZ*fsZ);
	if (fsDist < 0)
	{
		fsDist = fsDist * -1.00;
	}

	return fsDist;
}

void CheckClientCoordinates(int client)
{
	int i;
	float Coord[3];
	float fNewXYZ[3];
	float fDist;

	// We store the current location of the player
	GetClientAbsOrigin(client, Coord);

	// Checks all spots of the map
	for (i=0; i<ig_restrictedSpots_Count; i++)
	{
		// calculates distance between the current position and the restricted spot ..
		fDist = Distance(Coord[0], Coord[1], Coord[2], fg_arrayXYZ[i][0], fg_arrayXYZ[i][1], fg_arrayXYZ[i][2]);

		// If player is at least XX points close to that spot .... we move and warn him ...
		if (fDist < fg_arrayXYZ[i][3])
		{
			// Get new location's coordinates (to where the player will be moved to if it's on the restricted spot)
			fNewXYZ[0] = fg_arrayXYZ[i][4];
			fNewXYZ[1] = fg_arrayXYZ[i][5];
			fNewXYZ[2] = fg_arrayXYZ[i][6];

			// Warn ...
			PrintHintText(client, "\x01This zone is restricted. You have been moved by the server!");

			// Move ...
			TeleportEntity(client, fNewXYZ, NULL_VECTOR, NULL_VECTOR);
		}

		// If this distance is less than the current minimum .... we set it as minimum and then check if timer should be reset ...
		if (fDist < fg_MINdistance)
		{
			fg_MINdistance = fDist;
		}
	}
}

public Action LocationCheckThread(Handle timer)
{
	if (bg_pauseTimer == true)
	{
		return Plugin_Continue;
	}

	int i = 0;

	// We reset the minimum distance from all players to all restricted spots ...
	fg_MINdistance = 4001.00;

	for (i=1; i<=MaxClients; ++i)
	{
		if (IsClientInGame(i))
		{
			if(IsPlayerAlive(i))
			{
				if (GetClientTeam(i) == 2)
				{
					CheckClientCoordinates(i);
				}
			}
		}
	}

	// We check is timer should be reset ..
	CheckTimerReset();
	return Plugin_Continue;
}

