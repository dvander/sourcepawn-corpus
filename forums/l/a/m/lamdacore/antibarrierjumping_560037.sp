/*
 * Name: Anti Barrier Jumping
 * By: lamdacore
 * Thanks to: GODJonez for helping with the is-player-in-zone calculating.
*/
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>


#define PLUGIN_VERSION "1.00"
#define MAX_ALLIES_COORDS 5
#define MAX_AXIS_COORDS 5
#define TEAM_SPEC 1
#define TEAM_ALLIES 2
#define TEAM_AXIS 3

public Plugin:myinfo = {
        name = "Anti Barrier Jumping",
        author = "lamdacore",
        description = "Slays Player that do barrier jumping",
        version = PLUGIN_VERSION,
        url = "http://www.spackenz.de/"
};

static String:teamname[3][] = { "Spectator", "Allies", "Axis" };
new Float:g_AlliesCoords[MAX_ALLIES_COORDS][8];
new Float:g_AxisCoords[MAX_AXIS_COORDS][8];
new Float:g_SetCoords[8];
new g_MaxCoordsAllies = 0;
new g_MaxCoordsAxis = 0;
new Handle:cvarABJVerbose;

public OnPluginStart()
{
	CreateConVar("antibarrierjumping_version", PLUGIN_VERSION, _, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarABJVerbose = CreateConVar("abj_verbose", "1", "Sets when/where output is sent and to whom\n0 = No output\n1 = Show only to the user involved\n2 = Show to admins and user involved\n3 = Show to admins only\n4 = Show to everyone",FCVAR_PLUGIN, true, 0.0, true, 4.0);

	RegConsoleCmd("sm_clearzone", CommandClearZone, "clears current point coordinates for Barrier-Jumping-Zone.");
	RegConsoleCmd("sm_setzone", CommandSetZone, "set 3 point coordinates and the min/max height for Barrier-Jumping-Zone.");
	RegConsoleCmd("sm_savezone_allies", CommandSaveZoneAllies, "save the current cooridinates for Barrier-Jumping-Zone that will slay the Allies team.");
	RegConsoleCmd("sm_savezone_axis", CommandSaveZoneAxis, "save the current cooridinates for Barrier-Jumping-Zone that will slay the Axis team.");
	RegConsoleCmd("sm_delzone_allies", CommandDeleteZoneAllies, "delete the last saved Barrier-Jumping-Zone that will slay the Allies team.");
	RegConsoleCmd("sm_delzone_axis", CommandDeleteZoneAxis, "delete the last saved Barrier-Jumping-Zone that will slay the Axis team.");
	RegConsoleCmd("sm_testzones", CommandTestZones, "test the Barrier-Jumping-Zones by your current position.");

/*	g_AlliesCoords[0][0] = 527.7; // x1
	g_AlliesCoords[0][1] = 1307.1; // y1
	g_AlliesCoords[0][2] = 813.5; // x2
	g_AlliesCoords[0][3] = 1593.5; // y2
	g_AlliesCoords[0][4] = 464.6; // x3
	g_AlliesCoords[0][5] = 1958.3; // y3
	g_AlliesCoords[0][6] = 90.0; // z min
	g_AlliesCoords[0][7] = 280.0; // z max

	g_AxisCoords[0][0] = 1362.6; // x1
	g_AxisCoords[0][1] = -936.9; // y1
	g_AxisCoords[0][2] = 1617.2; // x2
	g_AxisCoords[0][3] = -695.3; // y2
	g_AxisCoords[0][4] = 1128.5; // x3
	g_AxisCoords[0][5] = -273.0; // y3
	g_AxisCoords[0][6] = -60.0; // z min
	g_AxisCoords[0][7] = 280.0; // z max*/

	AutoExecConfig(true, "antibarrierjumping", "sourcemod");
	
	CreateTimer(1.0, BarrierJumpingCheckThread, _,TIMER_REPEAT);	
}

public OnMapStart()
{
	decl String:szDataFile[256];
	decl String:MapName[32];
	GetCurrentMap(MapName, 32);

	InitializeCoords();

	BuildPath(Path_SM, szDataFile, sizeof(szDataFile), "data/abj_%s.txt", MapName);
	if (FileExists(szDataFile))
	{
		ReadDataFile(szDataFile);
	}
}

CheckForValidPlayer(client)
{
	if (client <= 0 || !IsClientConnected(client) || !IsClientInGame(client))
		return false;

	new AdminId:adminid = GetUserAdmin(client);
	new bool:has_Root = (adminid == INVALID_ADMIN_ID) ? false : GetAdminFlag(adminid, Admin_Root);
	if (!has_Root)
	{
		ReplyToCommand(client, "You do not have the right permission to this command.");
		return false;
	}

	if (GetClientTeam(client) != TEAM_SPEC)
	{
		ReplyToCommand(client, "You have to be Spectrator to use this command.");
		return false;
	}

	return true;
}

public Action:CommandSetZone(client, args)
{
	if (!CheckForValidPlayer(client))
		return Plugin_Handled;

	new Float:PlayerCoords[3];
	GetClientAbsOrigin(client, PlayerCoords);
	if (g_SetCoords[0] == 0.0)
	{
		g_SetCoords[0] = PlayerCoords[0];
		g_SetCoords[1] = PlayerCoords[1];
		ReplyToCommand(client, "First point setted. (x: %f, y: %f)\nNext will be the second point.", PlayerCoords[0], PlayerCoords[1]);
	}
	else if (g_SetCoords[2] == 0.0)
	{
		g_SetCoords[2] = PlayerCoords[0];
		g_SetCoords[3] = PlayerCoords[1];
		ReplyToCommand(client, "Second point setted. (x: %f, y: %f)\nNext will be the third point.", PlayerCoords[0], PlayerCoords[1]);
	}
	else if (g_SetCoords[4] == 0.0)
	{
		g_SetCoords[4] = PlayerCoords[0];
		g_SetCoords[5] = PlayerCoords[1];
		ReplyToCommand(client, "Third point setted. (x: %f, y: %f)\nNext will be the minimum height.", PlayerCoords[0], PlayerCoords[1]);
	}
	else if (g_SetCoords[6] == 0.0)
	{
		g_SetCoords[6] = PlayerCoords[2];
		ReplyToCommand(client, "Minimum height setted. (zMin: %f)\nNext will be the maximum height.", PlayerCoords[2]);
	}
	else if (g_SetCoords[7] == 0.0)
	{
		g_SetCoords[7] = PlayerCoords[2];
		ReplyToCommand(client, "Maximum height setted. (zMax: %f)\nNow save the zone with sm_savezone_allies or sm_savezone_axis or reset with sm_clearzone.", PlayerCoords[2]);
	}
	else
	{
		ReplyToCommand(client, "A zone is already setted.\nx1: %f, y1:%f\nx2: %f, y2: %f\nx3: %f, y3: %f\nzMin: %f, zMax: %f\nNow save the zone with sm_savezone_allies or sm_savezone_axis or reset with sm_clearzone.",
			g_SetCoords[0],
			g_SetCoords[1],
			g_SetCoords[2],
			g_SetCoords[3],
			g_SetCoords[4],
			g_SetCoords[5],
			g_SetCoords[6],
			g_SetCoords[7]);
	}

	return Plugin_Handled;
}

public Action:CommandClearZone(client, args)
{
	if (!CheckForValidPlayer(client))
		return Plugin_Handled;


	for (new i=0; i<8; ++i)
		g_SetCoords[i] = 0.0;

	ReplyToCommand(client, "Current point coordinates for zone resetted.\nNow redefine zone with sm_setzone.");	

	return Plugin_Handled;
}

public Action:CommandSaveZoneAllies(client, args)
{
	if (!CheckForValidPlayer(client))
		return Plugin_Handled;

	for (new i=0; i<8; ++i)
	{
		if (g_SetCoords[i] == 0.0)
		{
			ReplyToCommand(client, "Current coordinates are not complete. Please use sm_setzone more times to define a complete zone.");
			return Plugin_Handled;
		}
	}

	if (g_MaxCoordsAllies+1 >= MAX_ALLIES_COORDS)
	{
		ReplyToCommand(client, "Maximum number of zones to save reached. Please delete a zone first with sm_delzone_allies.");
		return Plugin_Handled;
	}

	for (new i=0; i<8; ++i)
	{
		g_AlliesCoords[g_MaxCoordsAllies][i] = g_SetCoords[i];
	}
	ReplyToCommand(client, "Zone saved for Allies: %d.", g_MaxCoordsAllies++);

	WriteDataFile();

	for (new i=0; i<8; ++i)
		g_SetCoords[i] = 0.0;

	return Plugin_Handled;
}

public Action:CommandSaveZoneAxis(client, args)
{
	if (!CheckForValidPlayer(client))
		return Plugin_Handled;

	for (new i=0; i<8; ++i)
	{
		if (g_SetCoords[i] == 0.0)
		{
			ReplyToCommand(client, "Current coordinates are not complete. Please use sm_setzone more times to define a complete zone.");
			return Plugin_Handled;
		}
	}

	if (g_MaxCoordsAxis+1 >= MAX_AXIS_COORDS)
	{
		ReplyToCommand(client, "Maximum number of zones to save reached. Please delete a zone first with sm_delzone_axis.");
		return Plugin_Handled;
	}

	for (new i=0; i<8; ++i)
	{
		g_AxisCoords[g_MaxCoordsAxis][i] = g_SetCoords[i];
	}
	ReplyToCommand(client, "Zone saved for Axis: %d.", g_MaxCoordsAxis++);

	WriteDataFile();

	for (new i=0; i<8; ++i)
		g_SetCoords[i] = 0.0;

	return Plugin_Handled;
}

public Action:CommandDeleteZoneAllies(client, args)
{
	if (!CheckForValidPlayer(client))
		return Plugin_Handled;

	if (g_MaxCoordsAllies <= 0)
	{
		ReplyToCommand(client, "There is no zone to delete. The Allies-List is empty.");
		return Plugin_Handled;
	}

	for (new i=0; i<8; ++i)
	{
		g_AlliesCoords[g_MaxCoordsAllies][i] = 0.0;
	}
	ReplyToCommand(client, "Last Allies-Zone deleted. Allies-List has now %d entries.", --g_MaxCoordsAllies);

	WriteDataFile();
	return Plugin_Handled;
}

public Action:CommandDeleteZoneAxis(client, args)
{
	if (!CheckForValidPlayer(client))
		return Plugin_Handled;

	if (g_MaxCoordsAxis <= 0)
	{
		ReplyToCommand(client, "There is no zone to delete. The Axis-List is empty.");
		return Plugin_Handled;
	}

	for (new i=0; i<8; ++i)
	{
		g_AxisCoords[g_MaxCoordsAxis][i] = 0.0;
	}
	ReplyToCommand(client, "Last Axis-Zone deleted. Axis-List has now %d entries.", --g_MaxCoordsAxis);

	WriteDataFile();
	return Plugin_Handled;
}

public Action:CommandTestZones(client, args)
{
	if (!CheckForValidPlayer(client))
		return Plugin_Handled;

	new i;
	for (i=0; i<g_MaxCoordsAllies; ++i)
	{
		if (CalculatePlayerInZone(client, g_AlliesCoords[i]))
		{
			ReplyToCommand(client, "You're in an Anti-Barrier-Zone. As an Allie You would be slain.");
			return Plugin_Handled;
		}
	}

	for (i=0; i<g_MaxCoordsAxis; ++i)
	{
		if (CalculatePlayerInZone(client, g_AxisCoords[i]))
		{
			ReplyToCommand(client, "You're in an Anti-Barrier-Zone. As an Axis You would be slain.");
			return Plugin_Handled;
		}
	}

	ReplyToCommand(client, "You're safe. No Anti-Barrier-Zone here.");
	return Plugin_Handled;
}

InitializeCoords()
{
	g_MaxCoordsAllies = 0;
	g_MaxCoordsAxis = 0;

	for (new i=0; i<8; ++i)
	{
		new ii;
		for (ii=0; ii<MAX_ALLIES_COORDS; ++ii)
		{
			g_AlliesCoords[ii][i] = 0.0;
		}

		for (ii=0; ii<MAX_AXIS_COORDS; ++ii)
		{
			g_AxisCoords[ii][i] = 0.0;
		}

		g_SetCoords[i] = 0.0;
	}
}

ReadDataFile(String:szFile[256])
{
	new Handle:hFile = OpenFile(szFile, "r");

	if (hFile == INVALID_HANDLE)
		return;

	while (!IsEndOfFile(hFile))
	{
		decl String:szLine[256];
		if (!ReadFileLine(hFile, szLine, sizeof(szLine)))
			break;

		TrimString(szLine);

		decl String:szCoords[9][16];
		if (ExplodeString(szLine, ",", szCoords, 9, 16) != 9)
			break;
	
		new iTeam = 0;
		for (new i=0; i<9; ++i)
		{
			if (i == 0)
			{
				iTeam = StringToInt(szCoords[i]);
				continue;
			}

			if (iTeam == TEAM_ALLIES)
			{
				g_AlliesCoords[g_MaxCoordsAllies][i-1] = StringToFloat(szCoords[i]);
			}
			else if (iTeam == TEAM_AXIS)
			{
				g_AxisCoords[g_MaxCoordsAxis][i-1] = StringToFloat(szCoords[i]);
			}
		}

		if (iTeam == TEAM_ALLIES)
		{
			if (++g_MaxCoordsAllies >= MAX_ALLIES_COORDS)
				break;
		}
		else if (iTeam == TEAM_AXIS)
		{
			if (++g_MaxCoordsAxis >= MAX_AXIS_COORDS)
			{
				break;
			}
		}
	}

	CloseHandle(hFile);
}

WriteDataFile()
{
	decl String:szDataFile[256];
	decl String:MapName[32];
	GetCurrentMap(MapName, 32);
	BuildPath(Path_SM, szDataFile, sizeof(szDataFile), "data/abj_%s.txt", MapName);
	new Handle:hFile = OpenFile(szDataFile, "w");

	if (hFile == INVALID_HANDLE)
		return;

	FileSeek(hFile, 0, SEEK_SET);

	for (new i=0; i<g_MaxCoordsAllies; ++i)
	{
		if (!WriteFileLine(hFile, "%d,%f,%f,%f,%f,%f,%f,%f,%f", TEAM_ALLIES, g_AlliesCoords[i][0], g_AlliesCoords[i][1], g_AlliesCoords[i][2], g_AlliesCoords[i][3], g_AlliesCoords[i][4], g_AlliesCoords[i][5], g_AlliesCoords[i][6], g_AlliesCoords[i][7]))
			break;
	}

	for (new i=0; i<g_MaxCoordsAxis; ++i)
	{
		if (!WriteFileLine(hFile, "%d,%f,%f,%f,%f,%f,%f,%f,%f", TEAM_AXIS, g_AxisCoords[i][0], g_AxisCoords[i][1], g_AxisCoords[i][2], g_AxisCoords[i][3], g_AxisCoords[i][4], g_AxisCoords[i][5], g_AxisCoords[i][6], g_AxisCoords[i][7]))
			break;
	}

	CloseHandle(hFile);
}

CalculatePlayerInZone(client, Float:ZoneCoords[8])
{
	new Float:PlayerCoord[3];
	GetClientAbsOrigin(client, PlayerCoord);

	new Float:PlayerZ = PlayerCoord[2];
	new Float:ZoneMinZ = ZoneCoords[6];
	new Float:ZoneMaxZ = ZoneCoords[7];
	new Float:Temp;

	if (ZoneMinZ > ZoneMaxZ)
	{
		Temp = ZoneMinZ;
		ZoneMinZ = ZoneMaxZ;
		ZoneMaxZ = Temp;
	}

	if (PlayerZ < ZoneMinZ || PlayerZ > ZoneMaxZ)
		return false;

	new Float:PlayerX = PlayerCoord[0];
	new Float:PlayerY = PlayerCoord[1];
	new Float:ZoneX1 = ZoneCoords[0];
	new Float:ZoneX2 = ZoneCoords[2];
	new Float:ZoneX3 = ZoneCoords[4];
	new Float:ZoneY1 = ZoneCoords[1];
	new Float:ZoneY2 = ZoneCoords[3];
	new Float:ZoneY3 = ZoneCoords[5];
	new Float:TempY1;
	new Float:TempY2;

	if (ZoneX1 > ZoneX2)
	{
		Temp = ZoneX1;
		ZoneX1 = ZoneX2;
		ZoneX2 = Temp;
	}

	TempY1 = (ZoneY2 - ZoneY1) / (ZoneX2 - ZoneX1) * (PlayerX - ZoneX1) + ZoneY1; // calculating for 1 -> 2
	TempY2 = (ZoneY2 - ZoneY1) / (ZoneX2 - ZoneX1) * (PlayerX - ZoneX3) + ZoneY3; // calculating for 3 -> 4

	if (TempY1 > TempY2)
	{
		Temp = TempY1;
		TempY1 = TempY2;
		TempY2 = Temp;
	}
	
	if (PlayerY < TempY1 || PlayerY > TempY2)
		return false;

	TempY1 = (ZoneY3 - ZoneY2) / (ZoneX3 - ZoneX2) * (PlayerX - ZoneX2) + ZoneY2; // calculating for 2 -> 3
	TempY2 = (ZoneY3 - ZoneY2) / (ZoneX3 - ZoneX2) * (PlayerX - ZoneX1) + ZoneY1; // calculating for 4 -> 1

	if (TempY1 > TempY2)
	{
		Temp = TempY1;
		TempY1 = TempY2;
		TempY2 = Temp;
	}
	
	if (PlayerY < TempY1 || PlayerY > TempY2)
		return false;

	return true;
}

HandlePlayerInZone(client, teamid)
{
	ForcePlayerSuicide(client);

	decl String:name[32];
	decl String:steamid[32];
	GetClientName(client, name, 32);
	GetClientAuthString(client, steamid, 32);
	LogToGame("\"%s<%d><%s><%s>\" was slain for being in Barrier-Jumping-Zone", name, GetClientUserId(client), steamid, teamname[teamid-1]);
	new Verbose = GetConVarInt(cvarABJVerbose);
	new PlayerSlots = GetMaxClients();

	if (Verbose == 1 || Verbose == 2)
	{
		PrintToChat(client, "Barrier Jumping and/or being in the zone is not allowed!");
	}

	for (new players=1; players<=PlayerSlots; ++players)
	{
		if (IsClientConnected(players) && IsClientInGame(players) && ((GetUserAdmin(players) != INVALID_ADMIN_ID && players != client && (Verbose == 2 || Verbose == 3)) || (players != client && Verbose == 4)))
		{
			PrintToChat(players, "%s has ben slain for being in Barrier-Jumping-Zone", name);
		}
	}
}

public Action:BarrierJumpingCheckThread(Handle:timer)
{
	static iMaxClients = 0;
	static i = 0;
	static iClientTeam = 0;
	static ii = 0;

	iMaxClients = GetMaxClients();

	for (i=1; i<=iMaxClients; ++i)
	{
		if (!IsClientConnected(i))
			continue;

		if (!IsClientInGame(i))
			continue;

		if (IsFakeClient(i))
			continue;

		if (!IsPlayerAlive(i))
			continue;

		iClientTeam = GetClientTeam(i);
		if (iClientTeam == TEAM_ALLIES)
		{
			for (ii=0; ii<g_MaxCoordsAllies; ++ii)
			{
				if (CalculatePlayerInZone(i, g_AlliesCoords[ii]))
				{
					HandlePlayerInZone(i, iClientTeam);
					break;
				}
			}
		}
		else if (iClientTeam == TEAM_AXIS)
		{
			for (ii=0; ii<g_MaxCoordsAxis; ++ii)
			{
				if (CalculatePlayerInZone(i, g_AxisCoords[ii]))
				{
					HandlePlayerInZone(i, iClientTeam);
					break;
				}
			}
		}
	}

	return Plugin_Continue;
}

