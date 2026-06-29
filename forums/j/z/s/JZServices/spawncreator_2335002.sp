#pragma semicolon 1
#pragma dynamic 16384
#include <sourcemod>
#include <sdktools>
#include <regex>

public Plugin:myinfo = 
{
	name = "Spawn Creator",
	author = "Wiskyjim, Spongebob",
	description = "Creat new Serverside Spawns",
	version = "1.0.1",
	url = "http://www.gungame.eu"
}; 

#define MAX_SPAWNS			256


new bool:g_AreWeSpawning = false;
new g_SpawnCount = 0;
new Float:g_SpawnOrigins[MAX_SPAWNS][3];
new Float:g_SpawnAngles[MAX_SPAWNS][3];
new Handle:g_hSpawnMenu = INVALID_HANDLE;
new g_LastLocation[MAXPLAYERS+1];
new String:spawntype[MAX_SPAWNS][25];

public OnPluginStart()
{
	RegAdminCmd("sm_spawn_creator", 	Command_SpawnMenu, 		ADMFLAG_CHANGEMAP, 	"Edits CS:S DM spawn points");
	
	g_hSpawnMenu = CreateMenu(Menu_EditSpawns);
	SetMenuTitle(g_hSpawnMenu, "Spawn Creator");
	AddMenuItem(g_hSpawnMenu, "t_add", 	"Add T position");
	AddMenuItem(g_hSpawnMenu, "ct_add", "Add CT position");
	AddMenuItem(g_hSpawnMenu, "clear", 	"Delete all spawn points");
}

public OnClientPutInServer(client)
{
	g_LastLocation[client] = -1;
}

/* :TODO: we need this in core */
Float:GetDistance(const Float:vec1[3], const Float:vec2[3])
{
	decl Float:x, Float:y, Float:z;
	
	x = vec1[0] - vec2[0];
	y = vec1[1] - vec2[1];
	z = vec1[2] - vec2[2];
	
	return SquareRoot(x*x + y*y + z*z);
}

public WriteMapConfig()
{
	new String:map[64];
	GetCurrentMap(map, sizeof(map));
	new String:pattern[32];
	Format (pattern, sizeof(pattern), "^workshop/[0-9]*/");
	new Handle:h_regex=CompileRegex(pattern);
	if (MatchRegex(h_regex,map) > 0)
	{
			decl String:matchedpattern[64];
			GetRegexSubString(h_regex,0,matchedpattern,sizeof(matchedpattern));
			//PrintToServer("Matched pattern %s",matchedpattern);
			Format(matchedpattern, sizeof(matchedpattern), "addons/stripper/maps/%s", matchedpattern);
			//PrintToServer("Matched pattern %s",matchedpattern);
			if(!DirExists(matchedpattern))
				CreateDirectory(matchedpattern, 509);  
	}
	CloseHandle(h_regex);
	new String:path[512];
	Format(path, sizeof(path), "addons/stripper/maps/%s.cfg", map);
	
	new Handle:file = OpenFile(path, "wt");
	if (file == INVALID_HANDLE)
	{
		LogError("Could not open spawn point file \"%s\" for writing.", path);
		return false;
	}	
	
	for (new i=0; i<g_SpawnCount; i++)
	{
		WriteFileLine(file, "add:");
		WriteFileLine(file, "{");
		WriteFileLine(file, "\"origin\" \"%f %f %f\"", 
			g_SpawnOrigins[i][0],
			g_SpawnOrigins[i][1],
			g_SpawnOrigins[i][2]);
		WriteFileLine(file, "\"angles\" \"%f %f %f\"",
			g_SpawnAngles[i][0],
			g_SpawnAngles[i][1],
			g_SpawnAngles[i][2]);
		WriteFileLine(file, "\"classname\" \"info_player_%s\"", spawntype[i]);
		WriteFileLine(file, "}");
	}
	
	CloseHandle(file);
	return true;
}

AddSpawnFromClient(client, args)
{
	if (g_SpawnCount >= MAX_SPAWNS)
	{
		return -1;
	}
	
	GetClientAbsOrigin(client, g_SpawnOrigins[g_SpawnCount]);
	GetClientAbsAngles(client, g_SpawnAngles[g_SpawnCount]);
	
	if (args == 0) 
	{
	Format(spawntype[g_SpawnCount], 10, "terrorist");
	}
	else
	{
	Format(spawntype[g_SpawnCount], 17, "counterterrorist");		
	}
	
	new old = g_SpawnCount++;
	
	return old;
}

public Action:Command_SpawnMenu(client, args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "This command is not available from the server console.");
		return Plugin_Handled;
	}
	
	DisplayMenu(g_hSpawnMenu, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public Panel_VerifyDeleteSpawns(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 1)
		{
			g_SpawnCount = 0;
			if (!WriteMapConfig())
			{
				PrintToChat(param1, "Could not write to spawn config file.");
			} else {
				PrintToChat(param1, "All spawn points have been deleted.");
			}
		}
		DisplayMenu(g_hSpawnMenu, param1, MENU_TIME_FOREVER);
	}
}

public Menu_EditSpawns(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 0) 
		{
			if (AddSpawnFromClient(param1, param2) == -1)
			{
				PrintToChat(param1, "Could not add spawn (max limit reached).");
			} 
			else 
			{	
				if (!WriteMapConfig())
				{
					PrintToChat(param1, "Could not write to spawn config file!");
				} 
				else 
				{
					PrintToChat(param1, "Added spawn terrorist (%d total).", g_SpawnCount);
					
				}
			}
		} 
		else if (param2 == 1) 
		{
			if (AddSpawnFromClient(param1, param2) == -1)
			{
				PrintToChat(param1, "Could not add spawn (max limit reached).");
			} 
			else 
			{	
				
				if (!WriteMapConfig())
				{
					PrintToChat(param1, "Could not write to spawn config file!");
				} 
				else 
				{
					PrintToChat(param1, "Added spawn counterterrorist (%d total).", g_SpawnCount);
					
				}
			}
		}
		else if (param2 == 2) 
		{
			/* Beim Auswählen wird der Admin zur Sicherheit gefragt. */
			new Handle:panel = CreatePanel();
			SetPanelTitle(panel, "Delete all spawn points?");
			DrawPanelItem(panel, "Yes");
			DrawPanelItem(panel, "No");
			SendPanelToClient(panel, param1, Panel_VerifyDeleteSpawns, MENU_TIME_FOREVER);
			CloseHandle(panel);
			return;
		}
		/* Redraw the menu */
		DisplayMenu(g_hSpawnMenu, param1, MENU_TIME_FOREVER);
	}
}

public DM_OnClientSpawned(client)
{
	if (!g_AreWeSpawning || !g_SpawnCount)
	{
		return;
	}
	
	new maxClients = GetMaxClients();
	new startPoint = GetRandomInt(0, g_SpawnCount-1);
	
	/* Prefetch player origins */
	decl Float:origins[65][3];
	new numToCheck = 0;
	
	for (new i=1; i<=maxClients; i++)
	{
		if (i == client || !IsClientInGame(i))
		{
			continue;
		}
		GetClientAbsOrigin(i, origins[numToCheck]);
		numToCheck++;
	}
	
	/* Cycle through until we get a spawn point */
	new bool:use_this_point;
	new checked = 0;
	while (checked < g_SpawnCount)
	{
		if (startPoint >= g_SpawnCount)
		{
			startPoint = 0;
		}
		
		use_this_point = true;
		for (new i=0; i<numToCheck; i++)
		{
			if (GetDistance(g_SpawnOrigins[startPoint], origins[i]) < 600.0)
			{
				use_this_point = false;
				break;
			}
		}
		
		if (use_this_point)
		{
			break;
		}
		
		checked++;
		startPoint++;
	}
	
	if (startPoint >= g_SpawnCount)
	{
		startPoint = 0;
	}
		
	TeleportEntity(client, g_SpawnOrigins[startPoint], g_SpawnAngles[startPoint], NULL_VECTOR);
}