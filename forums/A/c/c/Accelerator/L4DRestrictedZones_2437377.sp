#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#pragma newdecls required

#define PLUGIN_VERSION "1.2 mod TY"

char sg_stf[8][32];
char sg_string[120];
char sg_file[160];
char sg_l4d2Map[65];
float fg_xyz[32][8];
float fg_MINdistance;
int ig_protec = 1;
int ig_tick = 0;
int ig_timer = 10;
int ig_lines = 0;
int ig_deleteAllCount;
float fg_arrayNewRestrictedSpot[3];
float fg_newRestrictedSpot_Radious;
float fg_arrayNewRestrictedSpot_MoveTo[3];

public Plugin myinfo = 
{
	name = "L4D Restricted Zones",
	author = "SkyDavid & TY",
	description = "This plugins allows you to restrict specific L4D zones",
	version = PLUGIN_VERSION,
	url = "www.sky.zebgames.com"
}

public void OnPluginStart()
{
	RegAdminCmd("rz_deleteall",   CmdDeleteAll,     ADMFLAG_CHEATS, "Deletes all the restricted zones for the current map");
	RegAdminCmd("rz_deletenear",  CmdDeleteNear,    ADMFLAG_CHEATS, "Deletes all the restricted zones near the current location. Radious is optional.");
	RegAdminCmd("rz_storeloc",    CmdStoreLocation, ADMFLAG_CHEATS, "Stores the current location as a restricted zone. Radious is optional.");
	RegAdminCmd("rz_storemoveto", CmdStoreMoveTo,   ADMFLAG_CHEATS, "Stores the current location as a 'Move-to' spot for last restricted zone.");

	CreateTimer(1.0, TyTimerUpdate, _, TIMER_REPEAT);
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
	if (!CheckPermissions(client))
	{
		return Plugin_Handled;
	}

	ig_protec = 1;
	
	if (ig_deleteAllCount == 0)
	{
		ig_protec = 0;

		ReplyToCommand (client, "[RZ] Please execute this command again to confirm that you want to delete all the restricted zones for this map.");
		ig_deleteAllCount = 1;
		return Plugin_Handled;
	}

	if (!DeleteAllZones())
	{
		ReplyToCommand (client, "[RZ] There were no restricted zones stored for this map!");
	}
	else
	{
		ReplyToCommand (client, "[RZ] All the restricted zones for this map has been deleted!");
	}

	TyLoadFile();

	ig_protec = 0;
	return Plugin_Handled;
}

public Action CmdDeleteNear (int client, int args)
{
	if (!CheckPermissions(client))
	{
		return Plugin_Handled;
	}

	ig_protec = 1;

	char arg[50];
	float radius;

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

			ig_protec = 0;

			return Plugin_Handled;
		}
	}

	TyLoadFile();

	DeleteNearSpots(client, radius);

	ig_protec = 0;
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

	GetClientAbsOrigin(client, Coord);

	for (i=0; i<ig_lines; i++)
	{
		Comp[0] = fg_xyz[i][0];
		Comp[1] = fg_xyz[i][1];
		Comp[2] = fg_xyz[i][2];

		for (j=0;j<3;j++)
		{
			Dif[j] = Coord[j] - Comp[j];
		}

		fDist = SquareRoot(Dif[0]*Dif[0] + Dif[1]*Dif[1] + Dif[2]*Dif[2]);

		if (fDist < 0)
		{
			fDist = fDist * -1;
		}

		if (fDist < radius)
		{
			deletedCount++;

			fg_xyz[i][0] = 0.0;
			fg_xyz[i][1] = 0.0;
			fg_xyz[i][2] = 0.0;
		}
	}

	if (deletedCount > 0)
	{
		if (!StoreAllRestrictedZones()) 
		{
			ReplyToCommand(client, "[RZ] An error was found when deleting the restricted zones.", deletedCount);
		}
		else
		{
			ReplyToCommand(client, "[RZ] %i zones has been deleted.", deletedCount);
		}

		TyLoadFile();
	}
	else
	{
		ReplyToCommand(client, "[RZ] There were no restricted zones near the current location.");
	}
}

public Action CmdStoreLocation(int client, int args)
{
	if (!CheckPermissions(client))
	{
		return Plugin_Handled;
	}

	ig_protec = 1;

	if (ig_lines >= 30)
	{
		ReplyToCommand (client, "[RZ] The maximum of %i restricted zones has been reached.", 30);

		ig_protec = 0;
		return Plugin_Handled;
	}

	char arg[50];
	float radius;

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

			ig_protec = 0;
			return Plugin_Handled;
		}
	}

	GetClientAbsOrigin(client, fg_arrayNewRestrictedSpot);
	fg_newRestrictedSpot_Radious = radius;

	ReplyToCommand(client, "[RZ] Restricted zone noted. Radious set on %f. Use rz_storemoveto to indicate the 'move to' location and store the zone.", radius);	

	ig_protec = 0;
	return Plugin_Handled;
}

public Action CmdStoreMoveTo (int client,int args)
{
	if (!CheckPermissions(client))
	{
		return Plugin_Handled;
	}

	ig_protec = 1;

	if ((fg_arrayNewRestrictedSpot[0]==0.0)&&(fg_arrayNewRestrictedSpot[1]==0.0)&&(fg_arrayNewRestrictedSpot[2]==0.0))
	{
		ReplyToCommand(client, "[RZ] You need to first select a restricted location with the rz_storeloc.");

		ig_protec = 0;
		return Plugin_Handled;
	}

	GetClientAbsOrigin(client, fg_arrayNewRestrictedSpot_MoveTo);

	if (Distance (fg_arrayNewRestrictedSpot_MoveTo[0], fg_arrayNewRestrictedSpot_MoveTo[1], fg_arrayNewRestrictedSpot_MoveTo[2], fg_arrayNewRestrictedSpot[0], fg_arrayNewRestrictedSpot[1], fg_arrayNewRestrictedSpot[2]) <= fg_newRestrictedSpot_Radious)
	{
		ReplyToCommand(client, "[RZ] This location is too close to the restricted spot. Please move away from it.");

		ig_protec = 0;
		return Plugin_Handled;
	}

	if (!StoreRestrictedZone())
	{
		ReplyToCommand (client, "[RZ] There was an error storing the restricted zone.");
	}
	else
	{
		ReplyToCommand (client, "[RZ] Restricted zone was stored.");
	}

	TyLoadFile();

	ig_protec = 0;
	return Plugin_Handled;
}

public bool DeleteAllZones()
{
	char fileName[256];
	BuildPath (Path_SM, fileName, sizeof(fileName)-1, "data/rz_%s.cfg", sg_l4d2Map);

	File hFile = OpenFile(fileName, "w+");
	if (hFile == null)
	{
		return false;
	}

	CloseHandle(hFile);
	return true;
}

void TyLoadFile()
{
	ig_lines = 0;
	sg_file[0] = '\0';
	BuildPath(Path_SM, sg_file, sizeof(sg_file) - 1, "data/rz_%s.cfg", sg_l4d2Map);

	File hFile = OpenFile(sg_file, "r");
	if (hFile != null)
	{
		FileSeek(hFile, 0, SEEK_SET);
		int i = 0;
		while (i < 30)
		{
			sg_string[0] = '\0';
			if (!ReadFileLine(hFile, sg_string, sizeof(sg_string) - 1))
			{
				break;
			}

			if (ExplodeString(sg_string, "\t", sg_stf, sizeof(sg_stf) - 1, sizeof(sg_stf[]) - 1) != 7)
			{
				break;
			}

			fg_xyz[i][0] = StringToFloat(sg_stf[0]);
			fg_xyz[i][1] = StringToFloat(sg_stf[1]);
			fg_xyz[i][2] = StringToFloat(sg_stf[2]);
			fg_xyz[i][3] = StringToFloat(sg_stf[3]);
			fg_xyz[i][4] = StringToFloat(sg_stf[4]);
			fg_xyz[i][5] = StringToFloat(sg_stf[5]);
			fg_xyz[i][6] = StringToFloat(sg_stf[6]);

			ig_lines += 1;
			i += 1;
		}

		CloseHandle(hFile);
		if (ig_lines == 0)
		{
			ig_timer = 999;
		}
	}
}

public bool StoreRestrictedZone()
{
	char fileName[256];
	BuildPath (Path_SM, fileName, sizeof(fileName)-1, "data/rz_%s.cfg", sg_l4d2Map);

	File hFile = OpenFile(fileName, "a+");
	if (hFile == null)
	{
		return false;
	}

	FileSeek(hFile, 0, SEEK_END);

	if (!WriteFileLine (hFile, "%f\t%f\t%f\t%f\t%f\t%f\t%f\t", fg_arrayNewRestrictedSpot[0], fg_arrayNewRestrictedSpot[1], fg_arrayNewRestrictedSpot[2], fg_newRestrictedSpot_Radious, fg_arrayNewRestrictedSpot_MoveTo[0], fg_arrayNewRestrictedSpot_MoveTo[1], fg_arrayNewRestrictedSpot_MoveTo[2]))
	{
		CloseHandle(hFile);
		return false;
	}

	CloseHandle(hFile);
	return true;
}

public bool StoreAllRestrictedZones()
{
	char fileName[256];
	BuildPath (Path_SM, fileName, sizeof(fileName)-1, "data/rz_%s.cfg", sg_l4d2Map);

	File hFile = OpenFile(fileName, "w+");
	if (hFile == null)
	{
		return false;
	}

	FileSeek(hFile, 0, SEEK_SET);

	int i;

	for (i=0; i<ig_lines; i++)
	{
		if ((fg_xyz[i][0] == 0.0)&&(fg_xyz[i][1] == 0.0)&&(fg_xyz[i][2] == 0.0))
		{
			break;
		}

		if (!WriteFileLine (hFile, "%f\t%f\t%f\t%f\t%f\t%f\t%f\t", fg_xyz[i][0], fg_xyz[i][1], fg_xyz[i][2], fg_xyz[i][3], fg_xyz[i][4], fg_xyz[i][5], fg_xyz[i][6]))
		{
			PrintToChatAll("error writing line");
			CloseHandle(hFile);
			return false;
		}
	}

	CloseHandle(hFile);
	return true;
}

public void OnMapStart()
{
	ig_tick = 0;
	ig_timer = 2;
	ig_protec = 0;
	ig_deleteAllCount = 0;
	GetCurrentMap(sg_l4d2Map, sizeof(sg_l4d2Map) - 1);
	TyLoadFile();
}

public void OnMapEnd()
{
	ig_tick = 0;
	ig_timer = 30;
	ig_protec = 1;
}

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

void TyClientXYZ(int client)
{
	float fCxyz[3];
	float fNewXYZ[3];
	float fDist;
	GetClientAbsOrigin(client, fCxyz);

	int i = 0;
	while (i < ig_lines)
	{
		fDist = Distance(fCxyz[0], fCxyz[1], fCxyz[2], fg_xyz[i][0], fg_xyz[i][1], fg_xyz[i][2]);
		if (fDist < fg_xyz[i][3])
		{
			fNewXYZ[0] = fg_xyz[i][4];
			fNewXYZ[1] = fg_xyz[i][5];
			fNewXYZ[2] = fg_xyz[i][6];
			TeleportEntity(client, fNewXYZ, NULL_VECTOR, NULL_VECTOR);
		}

		if (fDist < fg_MINdistance)
		{
			fg_MINdistance = fDist;
		}
		i += 1;
	}
}

void TyTimerInfinite()
{
	ig_tick += 1;
	if (ig_tick > ig_timer)
	{
		if (ig_lines > 0)
		{
			fg_MINdistance = 3001.0;
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
				{
					TyClientXYZ(i);
				}
			}

			ig_timer = 0;
			if (fg_MINdistance > 300.0)
			{
				ig_timer = 1;
			}
			if (fg_MINdistance > 500.0)
			{
				ig_timer = 2;
			}
			if (fg_MINdistance > 900.0)
			{
				ig_timer = 3;
			}
			if (fg_MINdistance > 1300.0)
			{
				ig_timer = 5;
			}
			if (fg_MINdistance > 2000.0)
			{
				ig_timer = 8;
			}
			if (fg_MINdistance > 3000.0)
			{
				ig_timer = 14;
			}
		}
		ig_tick = 0;
	}
}

public Action TyTimerUpdate(Handle timer)
{
	if (!ig_protec)
	{
		TyTimerInfinite();
	}
}