#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_AUTHOR "HelpMe"
#define PLUGIN_VERSION "1.03"

#define TRIGGER_NAME "nobuild_entity"
#define MAX_SEARCH_DIST 600.0

#include <sourcemod>
#include <sdktools>

bool g_bAllowOutline = true;
Handle g_hDatabase = INVALID_HANDLE;

int g_iLaserMaterial = -1;
int g_iHaloMaterial = -1;

float g_fMinBounds[MAXPLAYERS+1][3];
float g_fMaxBounds[MAXPLAYERS+1][3];
char g_sAllowSentry[MAXPLAYERS+1] = "0";
char g_sAllowDispenser[MAXPLAYERS+1] = "0";
char g_sAllowTeleporters[MAXPLAYERS+1] = "0";
char g_sTeamNum[MAXPLAYERS+1] = "0";

public Plugin myinfo = 
{
	name = "[TF2] Nobuild areas",
	author = PLUGIN_AUTHOR,
	description = "This plugin let you add func_nobuild brushes to a map and the locations gets saved.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2537267"
};

public void OnPluginStart()
{
	HookEvent("teamplay_round_start", EventRoundStart);

	CreateConVar("sm_nobuild_version", PLUGIN_VERSION, "No build areas version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	RegAdminCmd("sm_nobuild",Nobuild_Menu_1,ADMFLAG_ROOT,"Opens the nobuild menu.");
	RegAdminCmd("sm_shownobuild", Show_Nobuild, ADMFLAG_ROOT, "Shows all nobuild areas for 10 seconds to the client");
	
	ConnectToDatabase();
}

public void OnMapStart()
{
	g_iLaserMaterial = PrecacheModel("materials/sprites/laser.vmt");
	g_iHaloMaterial = PrecacheModel("materials/sprites/halo01.vmt");
	PrecacheModel("models/props_2fort/miningcrate002.mdl", true);
}

public void OnMapEnd()
{
	KillAllNobuild();
}

void ConnectToDatabase() 
{
	if (SQL_CheckConfig("nobuildareas"))
		SQL_TConnect(SQL_OnConnect, "nobuildareas");
	else
		SetFailState("Can't find 'nobuildareas' entry in sourcemod/configs/databases.cfg!");
} 

public void SQL_OnConnect(Handle owner, Handle hndl, const char[] error, any data)
{ 
	if (hndl == INVALID_HANDLE) 
	{ 
		LogError("Failed to connect! Error: %s", error);
		PrintToServer("Failed to connect: %s", error);
		SetFailState("SQL Error.  See error logs for details.");
		return;
	} 
	else 
	{
		SQL_TQuery(hndl, SQLErrorCheckCallback, "SET NAMES 'utf8'");
		g_hDatabase = hndl; 
		SQL_CreateTables();
	} 
}

void SQL_CreateTables()
{
	char query[512];
	Format(query,sizeof(query),"CREATE TABLE IF NOT EXISTS TF2_Nobuildareas (locX VARCHAR, locY VARCHAR, locZ VARCHAR, minX VARCHAR, minY VARCHAR, minZ VARCHAR, maxX VARCHAR, maxY VARCHAR, maxZ VARCHAR, allowsentry VARCHAR, allowdispenser VARCHAR, allowteleporters VARCHAR, teamnum VARCHAR, map VARCHAR);");
	SQL_TQuery(g_hDatabase, SQL_OnCreatedTable, query);
}

public void SQLErrorCheckCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (!StrEqual("", error))
	{
		LogMessage("SQL Error: %s", error);
	}
}

public void SQL_OnCreatedTable(Handle owner, Handle hndl, const char[] error, any data) 
{ 
	if (hndl == INVALID_HANDLE) 
	{ 
		LogError("Query failed! %s", error); 
	} 
}

public Action EventRoundStart(Event event, const char[] name, bool dontBroadcast)
{	
	char mapname[50];
	GetCurrentMap(mapname, sizeof(mapname));
	
	char sQuery[1000];
	Format(sQuery, sizeof(sQuery), "SELECT locX, locY, locZ, minX, minY, minZ, maxX, maxY, maxZ, allowsentry, allowdispenser, allowteleporters, teamnum FROM TF2_Nobuildareas WHERE map = '%s' ;", mapname);
	
	SQL_TQuery(g_hDatabase, SQL_OnGetTrigger, sQuery);
	return Plugin_Continue;
}
	
public void SQL_OnGetTrigger(Handle owner, Handle hndl, const char[] error, any data) 
{ 
	if (hndl == INVALID_HANDLE) 
	{ 
		LogError("Query failed! %s", error); 
	} 
	else if (SQL_GetRowCount(hndl) > 0) 
	{ 
		while (SQL_FetchRow(hndl))
		{
			float pos[3];
			float minbounds[3];
			float maxbounds[3];
			char allowsentry[16];
			char allowdispenser[16];
			char allowteleporters[16];
			char teamnum[16];
			pos[0] = SQL_FetchFloat(hndl, 0);
			pos[1] = SQL_FetchFloat(hndl, 1);
			pos[2] = SQL_FetchFloat(hndl, 2);
			minbounds[0] = SQL_FetchFloat(hndl, 3);
			minbounds[1] = SQL_FetchFloat(hndl, 4);
			minbounds[2] = SQL_FetchFloat(hndl, 5);
			maxbounds[0] = SQL_FetchFloat(hndl, 6);
			maxbounds[1] = SQL_FetchFloat(hndl, 7);
			maxbounds[2] = SQL_FetchFloat(hndl, 8);
			SQL_FetchString(hndl, 9, allowsentry, sizeof(allowsentry));
			SQL_FetchString(hndl, 10, allowdispenser, sizeof(allowdispenser));
			SQL_FetchString(hndl, 11, allowteleporters, sizeof(allowteleporters));
			SQL_FetchString(hndl, 12, teamnum, sizeof(teamnum));
			InsertTrigger(pos, minbounds, maxbounds, allowsentry, allowdispenser, allowteleporters, teamnum);
		}
	} 
}

public Action Nobuild_Menu_1(int client, int args)
{
	Menu menu = new Menu(Nobuild_Menu);
	SetMenuTitle(menu, "Nobuild Menu:");
	AddMenuItem(menu, "0", "Create", ITEMDRAW_DEFAULT);
	AddMenuItem(menu, "1", "Delete Nearest Nobuild Area", ITEMDRAW_DEFAULT);
	menu.Display(client, 20);
	
	return Plugin_Handled;
}

public int Nobuild_Menu(Menu menu, MenuAction action, int param1, int param2)
{
	char tmp[32], iSelected;
	GetMenuItem(menu, param2, tmp, sizeof(tmp));
	iSelected = StringToInt(tmp);

	switch(action)
	{
		case MenuAction_Select:
		{
			if(iSelected == 0)
			{
				Nobuild_Menu_2(param1);
			}	
			if(iSelected == 1)
			{
				DeleteTrigger(param1);
			}
		}
		case MenuAction_End: CloseHandle(menu);
	}
}
				

public Action Nobuild_Menu_2(int client)
{
	Menu menu = new Menu(Nobuild_Menu_Size);
	SetMenuTitle(menu, "Nobuild Area Size:");
	AddMenuItem(menu, "0", "128 x 128 x 64", ITEMDRAW_DEFAULT);
	AddMenuItem(menu, "1", "256 x 256 x 64", ITEMDRAW_DEFAULT);
	AddMenuItem(menu, "2", "512 x 512 x 64", ITEMDRAW_DEFAULT);
	AddMenuItem(menu, "3", "128 x 128 x 128", ITEMDRAW_DEFAULT);
	AddMenuItem(menu, "4", "256 x 256 x 128", ITEMDRAW_DEFAULT);
	AddMenuItem(menu, "5", "512 x 512 x 128", ITEMDRAW_DEFAULT);
	menu.Display(client, 20);
	
	return Plugin_Handled;
}

public int Nobuild_Menu_Size(Menu menu, MenuAction action, int param1, int param2)
{
	char tmp[32], iSelected;
	GetMenuItem(menu, param2, tmp, sizeof(tmp));
	iSelected = StringToInt(tmp);

	switch(action)
	{
		case MenuAction_Select:
		{
			if(iSelected == 0)
			{
				g_fMinBounds[param1][0] = -64.0;
				g_fMinBounds[param1][1] = -64.0;
				g_fMinBounds[param1][2] = -16.0;
				g_fMaxBounds[param1][0] = 64.0;
				g_fMaxBounds[param1][1] = 64.0;
				g_fMaxBounds[param1][2] = 48.0;
				Nobuild_Menu_3(param1);
			}
			if(iSelected == 1)
			{
				g_fMinBounds[param1][0] = -128.0;
				g_fMinBounds[param1][1] = -128.0;
				g_fMinBounds[param1][2] = -16.0;
				g_fMaxBounds[param1][0] = 128.0;
				g_fMaxBounds[param1][1] = 128.0;
				g_fMaxBounds[param1][2] = 48.0;
				Nobuild_Menu_3(param1);
			}
			if(iSelected == 2)
			{
				g_fMinBounds[param1][0] = -256.0;
				g_fMinBounds[param1][1] = -256.0;
				g_fMinBounds[param1][2] = -16.0;
				g_fMaxBounds[param1][0] = 256.0;
				g_fMaxBounds[param1][1] = 256.0;
				g_fMaxBounds[param1][2] = 48.0;
				Nobuild_Menu_3(param1);
			}
			if(iSelected == 3)
			{
				g_fMinBounds[param1][0] = -64.0;
				g_fMinBounds[param1][1] = -64.0;
				g_fMinBounds[param1][2] = -16.0;
				g_fMaxBounds[param1][0] = 64.0;
				g_fMaxBounds[param1][1] = 64.0;
				g_fMaxBounds[param1][2] = 112.0;
				Nobuild_Menu_3(param1);
			}
			if(iSelected == 4)
			{
				g_fMinBounds[param1][0] = -128.0;
				g_fMinBounds[param1][1] = -128.0;
				g_fMinBounds[param1][2] = -32.0;
				g_fMaxBounds[param1][0] = 128.0;
				g_fMaxBounds[param1][1] = 128.0;
				g_fMaxBounds[param1][2] = 112.0;
				Nobuild_Menu_3(param1);
			}
			if(iSelected == 5)
			{
				g_fMinBounds[param1][0] = -256.0;
				g_fMinBounds[param1][1] = -256.0;
				g_fMinBounds[param1][2] = -256.0;
				g_fMaxBounds[param1][0] = 256.0;
				g_fMaxBounds[param1][1] = 256.0;
				g_fMaxBounds[param1][2] = 112.0;
				Nobuild_Menu_3(param1);
			}
		}
		case MenuAction_End: CloseHandle(menu);
	}
}

public Action Nobuild_Menu_3(int client)
{
	Menu menu = new Menu(Nobuild_Menu_Team);
	SetMenuTitle(menu, "What team to disallow:");
	AddMenuItem(menu, "0", "Both", ITEMDRAW_DEFAULT);
	AddMenuItem(menu, "1", "Red", ITEMDRAW_DEFAULT);
	AddMenuItem(menu, "2", "Blue", ITEMDRAW_DEFAULT);
	menu.Display(client, 20);
	
	return Plugin_Handled;
}

public int Nobuild_Menu_Team(Menu menu, MenuAction action, int param1, int param2)
{
	char tmp[32], iSelected;
	GetMenuItem(menu, param2, tmp, sizeof(tmp));
	iSelected = StringToInt(tmp);

	switch(action)
	{
		case MenuAction_Select:
		{
			if(iSelected == 0)
			{
				Format(g_sTeamNum[param1], sizeof(g_sTeamNum), "0");
				Nobuild_Menu_4(param1);
			}
			if(iSelected == 1)
			{
				Format(g_sTeamNum[param1], sizeof(g_sTeamNum), "2");
				Nobuild_Menu_4(param1);
			}
			if(iSelected == 2)
			{
				Format(g_sTeamNum[param1], sizeof(g_sTeamNum), "3");
				Nobuild_Menu_4(param1);
			}
		}
		case MenuAction_End: CloseHandle(menu);
	}
}

public Action Nobuild_Menu_4(int client)
{
	Menu menu = new Menu(Nobuild_Menu_Buildings);
	SetMenuTitle(menu, "What buildings to allow:");
	AddMenuItem(menu, "0", "Allow None", ITEMDRAW_DEFAULT);
	AddMenuItem(menu, "1", "Sentries", ITEMDRAW_DEFAULT);
	AddMenuItem(menu, "2", "Dispensers", ITEMDRAW_DEFAULT);
	AddMenuItem(menu, "3", "Telporters", ITEMDRAW_DEFAULT);
	AddMenuItem(menu, "4", "Sentries and Dispensers", ITEMDRAW_DEFAULT);
	AddMenuItem(menu, "5", "Sentries and Teleporters", ITEMDRAW_DEFAULT);
	AddMenuItem(menu, "6", "Dispensers and Teleporters", ITEMDRAW_DEFAULT);
	menu.Display(client, 20);
	
	return Plugin_Handled;
}

public int Nobuild_Menu_Buildings(Menu menu, MenuAction action, int param1, int param2)
{
	char tmp[32], iSelected;
	GetMenuItem(menu, param2, tmp, sizeof(tmp));
	iSelected = StringToInt(tmp);

	switch(action)
	{
		case MenuAction_Select:
		{
			if(iSelected == 0)
			{
				Format(g_sAllowSentry[param1], sizeof(g_sAllowSentry), "0");
				Format(g_sAllowDispenser[param1], sizeof(g_sAllowDispenser), "0");
				Format(g_sAllowTeleporters[param1], sizeof(g_sAllowTeleporters), "0");
				CreateTrigger(param1);
			}
			if(iSelected == 1)
			{
				Format(g_sAllowSentry[param1], sizeof(g_sAllowSentry), "1");
				Format(g_sAllowDispenser[param1], sizeof(g_sAllowDispenser), "0");
				Format(g_sAllowTeleporters[param1], sizeof(g_sAllowTeleporters), "0");
				CreateTrigger(param1);
			}
			if(iSelected == 2)
			{
				Format(g_sAllowSentry[param1], sizeof(g_sAllowSentry), "0");
				Format(g_sAllowDispenser[param1], sizeof(g_sAllowDispenser), "1");
				Format(g_sAllowTeleporters[param1], sizeof(g_sAllowTeleporters), "0");
				CreateTrigger(param1);
			}
			if(iSelected == 3)
			{
				Format(g_sAllowSentry[param1], sizeof(g_sAllowSentry), "0");
				Format(g_sAllowDispenser[param1], sizeof(g_sAllowDispenser), "0");
				Format(g_sAllowTeleporters[param1], sizeof(g_sAllowTeleporters), "1");
				CreateTrigger(param1);
			}
			if(iSelected == 4)
			{
				Format(g_sAllowSentry[param1], sizeof(g_sAllowSentry), "1");
				Format(g_sAllowDispenser[param1], sizeof(g_sAllowDispenser), "1");
				Format(g_sAllowTeleporters[param1], sizeof(g_sAllowTeleporters), "0");
				CreateTrigger(param1);
			}
			if(iSelected == 5)
			{
				Format(g_sAllowSentry[param1], sizeof(g_sAllowSentry), "1");
				Format(g_sAllowDispenser[param1], sizeof(g_sAllowDispenser), "0");
				Format(g_sAllowTeleporters[param1], sizeof(g_sAllowTeleporters), "1");
				CreateTrigger(param1);
			}
			if(iSelected == 6)
			{
				Format(g_sAllowSentry[param1], sizeof(g_sAllowSentry), "0");
				Format(g_sAllowDispenser[param1], sizeof(g_sAllowDispenser), "1");
				Format(g_sAllowTeleporters[param1], sizeof(g_sAllowTeleporters), "1");
				CreateTrigger(param1);
			}
		}
		case MenuAction_End: CloseHandle(menu);
	}
}

void CreateTrigger(int client)
{
	if(GetEntityCount() >= GetMaxEntities() - MAXPLAYERS)
	{
		PrintToChat(client, "Entity limit is reached. Can't spawn more nobuild areas on this map.");
		return;
	}
	float pos[3];
	
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	
	for(int i = 0; i < 3; i++)
	{
		pos[i] = float(RoundToFloor(pos[i]));
	}
	
	InsertTrigger(pos, g_fMinBounds[client], g_fMaxBounds[client], g_sAllowSentry[client], g_sAllowDispenser[client], g_sAllowTeleporters[client], g_sTeamNum[client]);
	InsertOutline(pos, g_fMinBounds[client], g_fMaxBounds[client]);
	
	char mapname[150];
	char mapname_esc[150];
	GetCurrentMap(mapname, sizeof(mapname));
	SQL_EscapeString(g_hDatabase, mapname, mapname_esc, sizeof(mapname_esc));
	
	char sQuery[1000];
	Format(sQuery, sizeof(sQuery), "INSERT INTO TF2_Nobuildareas VALUES ('%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%s', '%s', '%s', '%s', '%s');", pos[0], pos[1], pos[2], g_fMinBounds[client][0], g_fMinBounds[client][1], g_fMinBounds[client][2], g_fMaxBounds[client][0], g_fMaxBounds[client][1], g_fMaxBounds[client][2], g_sAllowSentry[client], g_sAllowDispenser[client], g_sAllowTeleporters[client], g_sTeamNum[client], mapname_esc);
	SQL_TQuery(g_hDatabase, SQL_OnSavedTrigger, sQuery);
	return;
}

public void SQL_OnSavedTrigger(Handle owner, Handle hndl, char[] error, any data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed! %s", error);
		SetFailState("Couldn't connect to the database, check logs for more information.");
	}
	else
	{
		PrintToChatAll("Nobuild area added to database!");
	}
}

void DeleteTrigger(int client)
{
	char name[64];
	float entPos[3], cliPos[3];
	
	int aux_ent, closest = -1;
	float aux_dist, closest_dist = -1.0;
	
	GetClientAbsOrigin(client,cliPos);
	
	int MaxEntities = GetMaxEntities();
	for (aux_ent = MaxClients; aux_ent < MaxEntities; aux_ent++) 
	{		
		if (!IsValidEntity(aux_ent)) 
			continue;
		GetEntPropString(aux_ent, Prop_Data, "m_iName", name, sizeof(name));
		if (StrEqual(name, TRIGGER_NAME, false))
		{
			GetEntPropVector(aux_ent,Prop_Data,"m_vecOrigin",entPos);
			aux_dist = GetVectorDistance(entPos, cliPos, false);
			if(closest_dist > aux_dist || closest_dist == -1.0)
			{
				closest = aux_ent;
				closest_dist = aux_dist;
			}
		}
	}
	if(closest != -1 && closest_dist < MAX_SEARCH_DIST)
	{
		GetEntPropVector(closest, Prop_Send, "m_vecOrigin", entPos);
		char sQuery[1000];
		Format(sQuery, sizeof(sQuery), "DELETE FROM TF2_Nobuildareas WHERE locX = '%f' AND locY = '%f' AND locZ = '%f';", entPos[0], entPos[1], entPos[2]);
		SQL_TQuery(g_hDatabase, SQL_OnUpdateTrigger, sQuery);
		RemoveEdict(closest);
	}
	else
	{
		PrintToChat(client,"There isn't any near nobuild areas to delete"); 
	}
}

public void SQL_OnUpdateTrigger(Handle owner, Handle hndl, const char[] error, any data) 
{ 
	if (hndl == INVALID_HANDLE) 
	{ 
		LogError("Query failed! %s", error); 
	} 
	else 
	{ 
		PrintToChatAll( "Nobuild area deleted from database!");
	} 
}  

void InsertTrigger(float pos[3], float minbounds[3], float maxbounds[3], const char[] AllowSentry, const char[] AllowDispenser, const char[] AllowTeleporters, const char[] TeamNum)
{
	int entindex = CreateEntityByName("func_nobuild");
	if (entindex != -1)
	{
		DispatchKeyValue(entindex, "targetname", TRIGGER_NAME);
		DispatchKeyValue(entindex, "AllowSentry", AllowSentry);
		DispatchKeyValue(entindex, "AllowDispenser", AllowDispenser);
		DispatchKeyValue(entindex, "AllowTeleporters", AllowTeleporters);
		DispatchKeyValue(entindex, "TeamNum", TeamNum);
	}
	DispatchSpawn(entindex);
	ActivateEntity(entindex);
	
	TeleportEntity(entindex, pos, NULL_VECTOR, NULL_VECTOR);
	
	SetEntityModel(entindex, "models/props_2fort/miningcrate002.mdl");
	
	SetEntPropVector(entindex, Prop_Send, "m_vecMins", minbounds);
	SetEntPropVector(entindex, Prop_Send, "m_vecMaxs", maxbounds);
	    
	SetEntProp(entindex, Prop_Send, "m_nSolidType", 2);
	
	int enteffects = GetEntProp(entindex, Prop_Send, "m_fEffects");
	enteffects |= 32;
	SetEntProp(entindex, Prop_Send, "m_fEffects", enteffects);
}

public Action Show_Nobuild(int client, int args)
{	
	if (g_bAllowOutline == true)
	{
		ReplyToCommand(client, "Showing all nobuild areas");
		g_bAllowOutline = false;
		CreateTimer(10.0, Disallow_Show_Nobuild);
		char mapname[50];
		GetCurrentMap(mapname, sizeof(mapname));
		
		char sQuery[1000];
		Format(sQuery, sizeof(sQuery), "SELECT locX, locY, locZ, minX, minY, minZ, maxX, maxY, maxZ, allowsentry, allowdispenser, allowteleporters, teamnum FROM TF2_Nobuildareas WHERE map = '%s' ;", mapname);
		
		SQL_TQuery(g_hDatabase, SQL_OnGetOutline, sQuery);
		return Plugin_Continue;
	}
	else
	{
	ReplyToCommand(client, "Already showing the nobuild areas");
	}
	return Plugin_Continue;
}

public Action Disallow_Show_Nobuild(Handle timer)
{
	g_bAllowOutline = true;
}

public void SQL_OnGetOutline(Handle owner, Handle hndl, const char[] error, any data) 
{ 
	if (hndl == INVALID_HANDLE) 
	{ 
		LogError("Query failed! %s", error); 
	} 
	else if (SQL_GetRowCount(hndl) > 0) 
	{ 
		while (SQL_FetchRow(hndl))
		{
			float pos[3];
			float minbounds[3];
			float maxbounds[3];
			pos[0] = SQL_FetchFloat(hndl, 0);
			pos[1] = SQL_FetchFloat(hndl, 1);
			pos[2] = SQL_FetchFloat(hndl, 2);
			minbounds[0] = SQL_FetchFloat(hndl, 3);
			minbounds[1] = SQL_FetchFloat(hndl, 4);
			minbounds[2] = SQL_FetchFloat(hndl, 5);
			maxbounds[0] = SQL_FetchFloat(hndl, 6);
			maxbounds[1] = SQL_FetchFloat(hndl, 7);
			maxbounds[2] = SQL_FetchFloat(hndl, 8);
			InsertOutline(pos, minbounds, maxbounds);
		}
	} 
}

void InsertOutline(float pos[3], float minbounds[3], float maxbounds[3])
{
	int Color[4] = {255,255,255,255};
	float vector1[3];
	float vector2[3];
	AddVectors(pos, minbounds, vector1);
	AddVectors(pos, maxbounds, vector2);
	for(int client=1;client<=MaxClients;client++)
	{
		if(IsClientInGame(client) && IsClientConnected(client))
		{
			TE_SendBeamBoxToClient(client, vector1, vector2, g_iLaserMaterial, g_iHaloMaterial, 0, 30, 10.0, 5.0, 5.0, 2, 1.0, Color, 0);
		}
	}
}

stock int TE_SendBeamBoxToClient(int client, float uppercorner[3], float bottomcorner[3], int ModelIndex, int HaloIndex, int StartFrame, int FrameRate, float Life, float Width, float EndWidth, int FadeLength, float Amplitude, int Color[4], int Speed)
{
	// Create the additional corners of the box
	float tc1[3];
	AddVectors(tc1, uppercorner, tc1);
	tc1[0] = bottomcorner[0];
	float tc2[3];
	AddVectors(tc2, uppercorner, tc2);
	tc2[1] = bottomcorner[1];
	float tc3[3];
	AddVectors(tc3, uppercorner, tc3);
	tc3[2] = bottomcorner[2];
	float tc4[3];
	AddVectors(tc4, bottomcorner, tc4);
	tc4[0] = uppercorner[0];
	float tc5[3];
	AddVectors(tc5, bottomcorner, tc5);
	tc5[1] = uppercorner[1];
	float tc6[3];
	AddVectors(tc6, bottomcorner, tc6);
	tc6[2] = uppercorner[2];
	
	// Draw all the edges
	TE_SetupBeamPoints(uppercorner, tc1, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(uppercorner, tc2, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(uppercorner, tc3, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(tc6, tc1, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(tc6, tc2, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(tc6, bottomcorner, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(tc4, bottomcorner, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(tc5, bottomcorner, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(tc5, tc1, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(tc5, tc3, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(tc4, tc3, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(tc4, tc2, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
}
//Just to be safe
void KillAllNobuild()
{
	char name[64];
	
	int aux_ent;
	
	int MaxEntities = GetMaxEntities();
	for (aux_ent = MaxClients; aux_ent < MaxEntities; aux_ent++) 
	{		
		if (!IsValidEntity(aux_ent)) 
			continue;
		GetEntPropString(aux_ent, Prop_Data, "m_iName", name, sizeof(name));
		if (StrEqual(name, TRIGGER_NAME, false))
		{
			RemoveEdict(aux_ent);
		}
	}
}