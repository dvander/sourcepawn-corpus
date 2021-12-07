/*
*******************************************************************************************
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
*
*  14.05.2013
* Автор модификации TY
********************************************************************************************
*/
#pragma semicolon 1
#define PLUGIN_VERSION "1.1.2 mod"

#include <sourcemod>
#include <sdktools>

#define MAX_RESTRICTEDSPOTS 	10

#define TY_DEBAG_LOG false // true или false

#if TY_DEBAG_LOG
new String:ty_file_path_log[256];
#endif

new String:MapName[100];
new Float:RestrictedSpots[MAX_RESTRICTEDSPOTS][7];
new RestrictedSpots_Count;
new Float:NewRestrictedSpot[3];
new Float:NewRestrictedSpot_Radious;
new Float:NewRestrictedSpot_MoveTo[3];
new Float:MinimumDistance;
new Handle:CheckTimer;
new Float:CurrentInterval;
new DeleteAllCount;
new bool:pauseTimer;


public Plugin:myinfo = 
{
	name = "L4D Restricted Zones",
	author = "SkyDavid",
	description = "This plugins allows you to restrict specific L4D zones",
	version = PLUGIN_VERSION,
	url = "www.sky.zebgames.com"
}

public OnPluginStart()
{
	// We register the version cvar
	CreateConVar("l4d_restrictedzones_version", PLUGIN_VERSION, "Version of L4D Restricted zones plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);


	// We register all of the commands...
	RegConsoleCmd("rz_deleteall", CmdDeleteAll, "Deletes all the restricted zones for the current map");
	RegConsoleCmd("rz_deletenear", CmdDeleteNear, "Deletes all the restricted zones near the current location. Radious is optional.");
	RegConsoleCmd("rz_storeloc", CmdStoreLocation, "Stores the current location as a restricted zone. Radious is optional.");
	RegConsoleCmd("rz_storemoveto", CmdStoreMoveTo, "Stores the current location as a 'Move-to' spot for last restricted zone.");
	
	pauseTimer = false;
	CheckTimer = INVALID_HANDLE;

	#if TY_DEBAG_LOG
	BuildPath(Path_SM, ty_file_path_log, sizeof(ty_file_path_log), "logs\\L4DRestrictedZones.log");
	LogToFile(ty_file_path_log, "--------------- OnPluginStart() ----------------------");
	#endif
}

KillCheckTimer()
{
	if (CheckTimer != INVALID_HANDLE)
	{
		KillTimer(CheckTimer, false);
		CheckTimer = INVALID_HANDLE;
	}
}


public CheckPermissions(client)
{
	if (!IsClientConnected(client))
		return false;
	
	if (!IsClientInGame(client))
		return false;
	
	if (IsFakeClient(client))
		return false;
	
	// Gets the admin id
	new AdminId:adminId = GetUserAdmin(client);
	
	// Checks if player is registered as an admin
	if (((adminId == INVALID_ADMIN_ID) ? false : GetAdminFlag(adminId, Admin_Root)) == false)
	{
		ReplyToCommand(client, "[RZ] You don't have enough permissions to use this command.");
		return false;
	}
	
	return true;	
}


public Action:CmdDeleteAll (client, args)
{
	// Checks permission ...
	if (!CheckPermissions(client)) return Plugin_Handled;
	
	// We pause the timer
	pauseTimer = true;
	
	// We requiere a validation ...
	if (DeleteAllCount == 0)
	{
		// We unpause the timer
		pauseTimer = false;
		
		ReplyToCommand (client, "[RZ] Please execute this command again to confirm that you want to delete all the restricted zones for this map.");
		DeleteAllCount = 1;
		return Plugin_Handled;
	}
	
	// Now we proceed to delete the file
	if (!DeleteAllZones())
		ReplyToCommand (client, "[RZ] There were no restricted zones stored for this map!");
	else
	ReplyToCommand (client, "[RZ] All the restricted zones for this map has been deleted!");
	
	// We reload spots
	LoadSpots();
	
	// We unpause the timer
	pauseTimer = false;
	
	return Plugin_Handled;
}

public Action:CmdDeleteNear (client, args)
{
	// Checks permission ...
	if (!CheckPermissions(client)) return Plugin_Handled;
	
	// We pause the timer
	pauseTimer = true;
	
	
	// We determine the radius
	new String:arg[50];
	new Float:radius;
	
	// if radius was not provided, we use 50 by default
	if (args < 1)
		radius = 50.00;
	else
	{
		GetCmdArg(1, arg, 50);
		radius = StringToFloat(arg);
		
		if ((radius < 10.0)||(radius > 1000.0))
		{
			ReplyToCommand (client, "[RZ] The radius must be between 10-1000. Command aborted.");
			
			// We unpause the timer
			pauseTimer = false;
			
			return Plugin_Handled;
		}
	}
	
	
	// We reload the spots
	LoadSpots();
	
	// Deletion of near spots ...
	DeleteNearSpots(client, radius);
	
	
	// We unpause the timer
	pauseTimer = false;
	
	return Plugin_Handled;
	
}

DeleteNearSpots (client, Float:radius)
{
	new Float:Coord[3];
	new Float:Comp[3];
	new Float:Dif[3];
	new Float:Dist;
	new deletedCount;
	new i;
	new j;
	
	deletedCount = 0;
	
	// We store the current location of the player
	GetClientAbsOrigin(client, Coord);			
	
	// Checks all spots of the map
	for (i=0;i<RestrictedSpots_Count; i++)
	{
		// Get restricted spot's coordinates
		Comp[0] = RestrictedSpots[i][0];
		Comp[1] = RestrictedSpots[i][1];
		Comp[2] = RestrictedSpots[i][2];
		
		// Gets the difference on each ...
		for (j=0;j<3;j++)
			Dif[j] = Coord[j] - Comp[j];
		
		// calculates distance
		Dist = SquareRoot(Dif[0]*Dif[0] + Dif[1]*Dif[1] + Dif[2]*Dif[2]);
		
		// Gets absolute value
		if (Dist < 0) Dist = Dist * -1;
		
		
		// If player is close to the spot, we mark it for deletion ...
		if (Dist < radius)
		{
			deletedCount++;
			
			RestrictedSpots[i][0] = 0.0;
			RestrictedSpots[i][1] = 0.0;
			RestrictedSpots[i][2] = 0.0;
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


public Action:CmdStoreLocation (client, args)
{
	// Checks permission ...
	if (!CheckPermissions(client)) return Plugin_Handled;
	
	// We pause the timer
	pauseTimer = true;
	
	// If we reached the limit of restricted points ...
	if (RestrictedSpots_Count == MAX_RESTRICTEDSPOTS)
	{
		ReplyToCommand (client, "[RZ] The maximum of %i restricted zones has been reached.", MAX_RESTRICTEDSPOTS);
		
		// We unpause the timer
		pauseTimer = false;
		
		return Plugin_Handled;
	}
	
	new String:arg[50];
	new Float:radius;
	
	// if radius was not provided, we use 50 by default
	if (args < 1)
		radius = 50.00;
	else
	{
		GetCmdArg(1, arg, 50);
		radius = StringToFloat(arg);
		
		if ((radius < 10.0)||(radius > 1000.0))
		{
			ReplyToCommand (client, "[RZ] The radius must be between 10-1000. Command aborted.");
			
			// We unpause the timer
			pauseTimer = false;
			
			return Plugin_Handled;
		}
	}
	
	// We store the current location of the player
	GetClientAbsOrigin(client, NewRestrictedSpot);
	NewRestrictedSpot_Radious = radius;
	
	ReplyToCommand(client, "[RZ] Restricted zone noted. Radious set on %f. Use rz_storemoveto to indicate the 'move to' location and store the zone.", radius);	
	
	// We unpause the timer
	pauseTimer = false;
	
	return Plugin_Handled;
}

public Action:CmdStoreMoveTo (client, args)
{
	// Checks permission ...
	if (!CheckPermissions(client)) return Plugin_Handled;
	
	// We pause the timer
	pauseTimer = true;
	
	// Check if location was stored ...
	if ((NewRestrictedSpot[0]==0.0)&&(NewRestrictedSpot[1]==0.0)&&(NewRestrictedSpot[2]==0.0))
	{
		ReplyToCommand(client, "[RZ] You need to first select a restricted location with the rz_storeloc.");
		
		// We unpause the timer
		pauseTimer = false;
		
		return Plugin_Handled;
	}
	
	// We store the current location of the player
	GetClientAbsOrigin(client, NewRestrictedSpot_MoveTo);
	
	
	// First we validate if the Move-To location is not within the reach of the restricted spot's radio ...
	if (Distance (NewRestrictedSpot_MoveTo[0], NewRestrictedSpot_MoveTo[1], NewRestrictedSpot_MoveTo[2], NewRestrictedSpot[0], NewRestrictedSpot[1], NewRestrictedSpot[2]) <= NewRestrictedSpot_Radious)
	{
		ReplyToCommand(client, "[RZ] This location is too close to the restricted spot. Please move away from it.");
		
		// We unpause the timer
		pauseTimer = false;
		
		return Plugin_Handled;
	}
	
	
	// Now we store all the info to the data file ...
	if (!StoreRestrictedZone())
		ReplyToCommand (client, "[RZ] There was an error storing the restricted zone.");
	else
	ReplyToCommand (client, "[RZ] Restricted zone was stored.");
	
	// We reload spots
	LoadSpots();
	
	// We unpause the timer
	pauseTimer = false;
	
	return Plugin_Handled;
}

DeleteAllZones()
{
	// We define the path + filename
	new String:fileName[256];
	BuildPath (Path_SM, fileName, sizeof(fileName), "gamedata/rz_%s.cfg", MapName);
	
	// We create the file
	new Handle:file = OpenFile(fileName, "w+");
	if (file == INVALID_HANDLE) return false;
	
	CloseHandle(file);
	return true;
}

StoreRestrictedZone()
{
	// We define the path + filename
	new String:fileName[256];
	BuildPath (Path_SM, fileName, sizeof(fileName), "gamedata/rz_%s.cfg", MapName);
	
	// We create the file
	new Handle:file = OpenFile(fileName, "a+");
	if (file == INVALID_HANDLE) return false;
	
	// We find the end of the file
	FileSeek(file, 0, SEEK_END);
	
	// We store the info into the file
	if (!WriteFileLine (file, "%f\t%f\t%f\t%f\t%f\t%f\t%f\t", NewRestrictedSpot[0], NewRestrictedSpot[1], NewRestrictedSpot[2], NewRestrictedSpot_Radious, NewRestrictedSpot_MoveTo[0], NewRestrictedSpot_MoveTo[1], NewRestrictedSpot_MoveTo[2]))
	{
		// Error, so we abort ...
		CloseHandle(file);
		return false;
	}
	
	CloseHandle(file);
	return true;
}

StoreAllRestrictedZones()
{
	// We define the path + filename
	new String:fileName[256];
	BuildPath (Path_SM, fileName, sizeof(fileName), "gamedata/rz_%s.cfg", MapName);
	
	// We create the file
	new Handle:file = OpenFile(fileName, "w+");
	if (file == INVALID_HANDLE) return false;
	
	// We find the start of the file
	FileSeek(file, 0, SEEK_SET);
	
	new i;
	
	// Checks all spots of the map
	for (i=0;i<RestrictedSpots_Count; i++)
	{
		// If the zone was marked for deletion, we skip it ...
		if ((RestrictedSpots[i][0] == 0.0)&&(RestrictedSpots[i][1] == 0.0)&&(RestrictedSpots[i][2] == 0.0))
			break;
		
		// We store the info into the file
		if (!WriteFileLine (file, "%f\t%f\t%f\t%f\t%f\t%f\t%f\t", RestrictedSpots[i][0], RestrictedSpots[i][1], RestrictedSpots[i][2], RestrictedSpots[i][3], RestrictedSpots[i][4], RestrictedSpots[i][5], RestrictedSpots[i][6]))
		{
			PrintToChatAll("error writing line");
			// Error, so we abort ...
			CloseHandle(file);
			return false;
		}
	}
	
	CloseHandle(file);
	return true;
}

LoadSpots ()
{
	// We reset the variables
	RestrictedSpots_Count = 0;

	// We define the path + filename
	new String:fileName[160];
	BuildPath (Path_SM, fileName, sizeof(fileName), "gamedata/rz_%s.cfg", MapName);

	#if TY_DEBAG_LOG
	LogToFile(ty_file_path_log, "0 %s _ %s", MapName, fileName);
	#endif

	// We read the file
	new Handle:file = OpenFile(fileName, "r");
	if (file == INVALID_HANDLE) {
		return;
	}

	FileSeek (file, 0, SEEK_SET);
	while (!IsEndOfFile(file))
	{
		// we declare the line
		decl String:line[500];
		line[0] = '\0';
		// we read the line
		if (!ReadFileLine(file, line, sizeof(line))) {
			break;
		}

		// we get the coordinates
		decl String:data[7][201];
		if (ExplodeString(line, "\t", data, 7, 200) != 7) {
			break;
		}

		// We store them
//		decl i;
//		decl j;
		new i = RestrictedSpots_Count;
		for (new j=0;j<7;j++) {
			RestrictedSpots[i][j] = StringToFloat(data[j]);
		}

		// We increment the counter ...
		RestrictedSpots_Count++;
	}

	CloseHandle(file);
	#if TY_DEBAG_LOG
	for (new ss=0; ss < RestrictedSpots_Count; ss++)
	{
		LogToFile(ty_file_path_log, "2 %f\t%f\t%f\t%f\t%f\t%f\t%f\t", RestrictedSpots[ss][0], RestrictedSpots[ss][1], RestrictedSpots[ss][2], RestrictedSpots[ss][3], RestrictedSpots[ss][4], RestrictedSpots[ss][5], RestrictedSpots[ss][6]);
	}
	#endif

	// This determines if we should start or not the timer 
	if (RestrictedSpots_Count == 0) {
		// We kill the timer
		KillCheckTimer();
	}
	else {
		// We set the minimum distance to a high value ...
		MinimumDistance = 9999.99;

		// We kill the timer
		KillCheckTimer();

		// We start a timer ....
		CurrentInterval = 1.5; // We start off with 1 second between checks, just in case there's a restricted spot near spawn 
		CheckTimer = CreateTimer(CurrentInterval, LocationCheckThread, _, TIMER_REPEAT);
	}
}

public OnMapStart()
{
	// Load current Map name
	GetCurrentMap(MapName, sizeof(MapName));

	// Loads spots
	LoadSpots();

	// We reset the deleteall count ...
	DeleteAllCount = 0;
}

public OnMapEnd()
{
	// We kill the timer
	KillCheckTimer();
}

CheckTimerReset()
{
	new Float:time;
	// We set the check interval depending on the minimum distance ... (Thx to ChillyWI for his idea).
	if (MinimumDistance > 4000) {
		time = 19.0;
	}
	else if (MinimumDistance > 2000) {
		time = 10.0;
	}
	else if (MinimumDistance > 1300) {
		time = 6.0;
	}
	else if (MinimumDistance > 900) {
		time = 4.0;
	}
	else if (MinimumDistance > 400) {
		time = 2.0;
	}
	else {
		time = 0.5;
	}

	#if TY_DEBAG_LOG
	LogToFile(ty_file_path_log, "time = %f", time);
	#endif

	// If the current interval is different from the one we should have according to the current distance ...
	if (CurrentInterval != time)
	{
		// We store the new interval ..
		CurrentInterval = time;

		// We kill the timer
		KillCheckTimer();

		// We reset the timer with the new interval ...
		CheckTimer = CreateTimer(CurrentInterval, LocationCheckThread, _, TIMER_REPEAT);
	}
	return;
}

// This function returns the distance between the 2 coordinates ...
Float:Distance(Float:x1, Float:y1, Float:z1, Float:x2, Float:y2, Float:z2)
{
	new Float:dist;
	new Float:dx;
	new Float:dy;
	new Float:dz;

	dx = x1 - x2;
	dy = y1 - y2;
	dz = z1 - z2;

	dist =  SquareRoot(dx*dx + dy*dy + dz*dz);
	if (dist < 0) {
		dist = dist * -1.00;
	}
	return dist;
}

CheckClientCoordinates(client)
{
//	static i;
	new Float:Coord[3];
	new Float:NewCoord[3];
	new Float:Dist;

	// We store the current location of the player
	GetClientAbsOrigin(client, Coord);

	// Checks all spots of the map
	for (new i = 0; i < RestrictedSpots_Count; i++)
	{
		// calculates distance between the current position and the restricted spot ..
		Dist = Distance(Coord[0], Coord[1], Coord[2], RestrictedSpots[i][0], RestrictedSpots[i][1], RestrictedSpots[i][2]);

		// If player is at least XX points close to that spot .... we move and warn him ...
		if (Dist < RestrictedSpots[i][3])
		{
			// Get new location's coordinates (to where the player will be moved to if it's on the restricted spot)
			NewCoord[0] = RestrictedSpots[i][4];
			NewCoord[1] = RestrictedSpots[i][5];
			NewCoord[2] = RestrictedSpots[i][6];

			// Warn ...
			PrintHintText(client, "\x01This zone is restricted. You have been moved by the server!");

			// Move ...
			TeleportEntity(client, NewCoord, NULL_VECTOR, NULL_VECTOR);
		}

		// If this distance is less than the current minimum .... we set it as minimum and then check if timer should be reset ...
		if (Dist < MinimumDistance) {
			MinimumDistance = Dist;
		}
	}
}

public Action:LocationCheckThread(Handle:timer)
{
	if (pauseTimer == true) {
		return Plugin_Continue;
	}

//	static iMaxClients = 0;
//	static i = 0;

	new iMaxClients = GetMaxClients();

	// We reset the minimum distance from all players to all restricted spots ...
	MinimumDistance = 9999.99;
	for (new i = 1; i <= iMaxClients; ++i)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2) {
			CheckClientCoordinates(i);
		}
	}

	// We check is timer should be reset ..
	CheckTimerReset();
	return Plugin_Continue;
}

