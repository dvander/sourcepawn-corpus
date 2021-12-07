// ---- Preprocessor -----------------------------------------------------------
#pragma semicolon 1 

// ---- Includes ---------------------------------------------------------------
#include <sdktools>
#include <sourcemod>

// ---- Defines ----------------------------------------------------------------
#define AK_VERSION "0.1.0"
#define KIT_RESPAWN_TIME 10.0
#define MAX_SEARCH_DIST 100.0
#define KIT_NAME "autokit_entity"
#define AK_DELETE 0
#define AK_MED_S 1
#define AK_MED_M 2
#define AK_MED_F 3
#define AK_AMMO_S 4
#define AK_AMMO_M 5
#define AK_AMMO_F 6

// ---- Handles ----------------------------------------------------------------
new Handle:g_hDatabase = INVALID_HANDLE;

// ---- Variables --------------------------------------------------------------
new bool:isSuddenDeath=false;
new bool:onFirstSeconds = false;

// ---- Plugin's Information ---------------------------------------------------
public Plugin:myinfo =
{
	name			= "[TF2] Auto Kits",
	author			= "Classic",
	description	= "Auto spawns ammo and med kits that work like normal kits.",
	version			= AK_VERSION,
	url				= "http://www.clangs.com.ar"
};

/* OnPluginStart()
**
** When the plugin is loaded.
** -------------------------------------------------------------------------- */
public OnPluginStart()
{
	//Version CVar
	CreateConVar("sm_ak_version", AK_VERSION, "Auto Kits version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	//Menu command
	RegAdminCmd("sm_akmenu",AK_Menu,ADMFLAG_ROOT,"Opens the auto kit menu.");
	
	//We try to connect to the database
	ConnectToDatabase();
	
	//We hook round start so we can spawn every kit at start and sudden death so we don't spawn medikits on it.
	HookEvent("teamplay_round_start", EventRoundStart);
	HookEvent("teamplay_round_stalemate", EventSuddenDeathStart);
	
	//Here we hook the moment a player picks up a kit.
	HookEntityOutput("item_healthkit_small",  "OnPlayerTouch",	EntityOutput_Kit);
	HookEntityOutput("item_healthkit_medium", "OnPlayerTouch",	EntityOutput_Kit);
	HookEntityOutput("item_healthkit_full",   "OnPlayerTouch",	EntityOutput_Kit);
	HookEntityOutput("item_ammopack_small",  "OnPlayerTouch",	EntityOutput_Kit);
	HookEntityOutput("item_ammopack_medium", "OnPlayerTouch",	EntityOutput_Kit);
	HookEntityOutput("item_ammopack_full",   "OnPlayerTouch",	EntityOutput_Kit);
	
}

/* ConnectToDatabase()
**
** Here we try to connect to the database and we define de callback.
** -------------------------------------------------------------------------- */
ConnectToDatabase() 
{ 
	//This starts the connection defines the callback to run once connected or when an error is given.
	SQL_TConnect(SQL_OnConnect, "autokits"); 
} 

/* SQL_OnConnect()
**
** This the connection's callback, here we assign the handle if the connection was successful.
** Or we log the error otherwise.
** -------------------------------------------------------------------------- */
public SQL_OnConnect(Handle:owner, Handle:hndl, const String:error[], any:data) 
{ 
	//Since we are not guaranteed a connection, we make sure it actually worked 
	if (hndl == INVALID_HANDLE) 
	{ 
		//It didn't work, so we log the error 
		LogError("Database failure: %s", error); 
		SetFailState("Couldn't connect to the database, check logs for more information.");
	} 
	else 
	{ 
		//It worked, so we set the global to the handle the callback provided for this connection 
		g_hDatabase = hndl; 
		//And then we create the table (if it doesn't exists yet).
		SQL_CreateTables();
	} 
} 

/* SQL_CreateTables()
**
** Here we run the query to create the tables and we define a callback. Since we only check kits for maps or position we don't need a ID.
** -------------------------------------------------------------------------- */
SQL_CreateTables()
{
	decl String:query[256];
	Format(query,sizeof(query),"CREATE TABLE IF NOT EXISTS TF2_AutoKits (locX VARCHAR, locY VARCHAR, locZ VARCHAR, type INT, map VARCHAR);");
	SQL_TQuery(g_hDatabase, SQL_OnCreatedTable, query);
}

/* SQL_OnCreatedTable()
**
** This is the table creation's callback, we inform that is was successful or we log the error otherwise.
** -------------------------------------------------------------------------- */
public SQL_OnCreatedTable(Handle:owner, Handle:hndl, const String:error[], any:data) 
{ 
	if (hndl == INVALID_HANDLE) 
	{ 
		//There was a problem, log it 
		LogError("Query failed! %s", error); 
	} 
	else 
	{ 
		//Worked, so we tell them so 
		PrintToServer("[AK] The Auto-Kit table is ready!"); 
	} 
}  

/* EventSuddenDeathStart()
**
** This is the sudden death hook, we need it so we don't spawn medkits on sudden death.
** -------------------------------------------------------------------------- */
public Action:EventSuddenDeathStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	isSuddenDeath=true;
	return Plugin_Continue;
}

/* EventRoundStart()
**
** This is the round start's hook. Here we "end" the sudden death state, we create a timer to unlock the re-spawn of kits.
** We also run a query to get every kit for the current map.
** -------------------------------------------------------------------------- */
public Action:EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{	
	//The sudden death ended
	isSuddenDeath=false;
	
	//Here we create a timer to unlock the re-spawn so any kit picked in the last X seconds of the last round won re-spawn 
	onFirstSeconds = true;
	CreateTimer(KIT_RESPAWN_TIME, Unblock_KitRespawn);
	
	decl String:mapname[50];
	GetCurrentMap(mapname, sizeof(mapname));
	
	new String:sQuery[255];
	Format(sQuery, sizeof(sQuery), "SELECT locX, locY, locZ, type FROM TF2_AutoKits WHERE map = '%s' ;", mapname);
	
	SQL_TQuery(g_hDatabase, SQL_OnGetKit, sQuery);
	
	return Plugin_Continue;
}

/* Unblock_KitRespawn()
**
** Here we 'unlock' kit re-spawn, every kit that this plugin create now can re-spawn.
** -------------------------------------------------------------------------- */
public Action:Unblock_KitRespawn(Handle:timer)
{
	onFirstSeconds=false;
}

/* SQL_OnGetKit()
**
** This is the callback for the query that runs on round start.
** For every row we got, we get the x,y,z and type, then we spawn it
** -------------------------------------------------------------------------- */
public SQL_OnGetKit(Handle:owner, Handle:hndl, const String:error[], any:data) 
{ 

	if (hndl == INVALID_HANDLE) 
	{ 
		LogError("Query failed! %s", error); 
	} 
	else if (SQL_GetRowCount(hndl) > 0) 
	{ 
		while (SQL_FetchRow(hndl))
		{
			new Float:pos[3],type;
			pos[0] = SQL_FetchFloat(hndl, 0);
			pos[1] = SQL_FetchFloat(hndl, 1);
			pos[2] = SQL_FetchFloat(hndl, 2);
			type = SQL_FetchInt(hndl, 3);
			SpawnKit(type,pos);
		}
	} 
	else 
	{ 
		//There isn't any kit to spawn in this map.
		//PrintToChatAll("There isn't any kit to spawn..."); 
	} 
}  

/* AK_Menu()
**
** This is the admin menu for the plugin, used to delete the nearest kit or to spawn one.
** -------------------------------------------------------------------------- */
public Action:AK_Menu(client,args)
{
	new Handle:menu = CreateMenu(AK_Selected);
	SetMenuTitle(menu,"Spawn medkit/ammo :");
	AddMenuItem(menu, "0", "Delete Nearest Ammo/Medkit ", ITEMDRAW_DEFAULT);
	AddMenuItem(menu, "1", "Medkit (small)", ITEMDRAW_DEFAULT);
	AddMenuItem(menu, "2", "Medkit (medium)", ITEMDRAW_DEFAULT);
	AddMenuItem(menu, "3", "Medkit (full)", ITEMDRAW_DEFAULT);
	AddMenuItem(menu, "4", "Ammo (small)", ITEMDRAW_DEFAULT);
	AddMenuItem(menu, "5", "Ammo (medium)", ITEMDRAW_DEFAULT);
	AddMenuItem(menu, "6", "Ammo (full)", ITEMDRAW_DEFAULT);
	DisplayMenu(menu, client, 20);
	return Plugin_Handled;
}

/* AK_Selected()
**
** Here we manage the client's selection. We either delete a kit or create one by it's type.
** -------------------------------------------------------------------------- */
public AK_Selected(Handle:menu, MenuAction:action, param1, param2)
{
	decl String:tmp[32], iSelected;
	GetMenuItem(menu, param2, tmp, sizeof(tmp));
	iSelected = StringToInt(tmp);

	switch(action)
	{
		case MenuAction_Select:
		{
			if(iSelected == 0)
				DeleteKit(param1);
			else
				CreateKit(param1,iSelected);
		}
		case MenuAction_End: CloseHandle(menu);
	}
}
public PanelHandlerBlank(Handle:menu, MenuAction:action, client, param2) {}


/* CreateKit()
**
** Function used to create a kit and save it the database, we use the player's position.
** -------------------------------------------------------------------------- */
public CreateKit(client, type)
{
	if(GetEntityCount() >= GetMaxEntities() - MAXPLAYERS)
	{
		PrintToChat(client, "[AK] Entity limit is reached. Can't spawn anymore pumpkins. Change maps.");
		return;
	}
	
	//Here we get the player position and spawn a kit in it.
	new Float:pos[3];
	GetClientAbsOrigin(client, pos);
	SpawnKit(type,pos);
	
	//Here we get the map name and we and escape it.
	decl String:mapname[150];
	decl String:mapname_esc[150];
	GetCurrentMap(mapname, sizeof(mapname));
	SQL_EscapeString(g_hDatabase, mapname, mapname_esc, sizeof(mapname_esc));
	
	//We run the insert query
	decl String:sQuery[256];
	Format(sQuery, sizeof(sQuery), "INSERT INTO TF2_AutoKits VALUES ( '%f', '%f', '%f', '%d', '%s');", pos[0], pos[1], pos[2],type, mapname_esc);
	SQL_TQuery(g_hDatabase, SQL_OnSavedKit, sQuery);
	return;
}

/* SQL_OnSavedKit()
**
** Callback for the insert query, we inform it successful or we log the error otherwise.
** -------------------------------------------------------------------------- */
public SQL_OnSavedKit(Handle:owner, Handle:hndl, const String:error[], any:data) 
{ 
	if (hndl == INVALID_HANDLE) 
	{ 
		//There was a problem, log it 
		LogError("Query failed! %s", error); 
	} 
	else 
	{ 
		//Worked, so we tell them so 
		PrintToChatAll( "\x04[\x03AK\x04]\x01 Kit location added to database!");
	} 
}  

/* DeleteKit()
**
** Here we delete the nearest kit from the player. Then we run a query and we define a callback for it.
** -------------------------------------------------------------------------- */
public DeleteKit(client)
{
	
	new String:name[64];
	new Float:entPos[3], Float:cliPos[3];
	
	new aux_ent, closest = -1;
	new Float:aux_dist, Float:closest_dist = -1.0;
	
	GetClientAbsOrigin(client,cliPos);
	
	//We search for every kit (we check it's one of our kits by its name) and then we get the nearest
	new MaxEntities = GetMaxEntities();
	for (aux_ent = MaxClients; aux_ent < MaxEntities; aux_ent++) 
	{		
		if (!IsValidEntity(aux_ent)) 
			continue;
		GetEntPropString(aux_ent, Prop_Data, "m_iName", name, sizeof(name));
		if (StrEqual(name, KIT_NAME, false))
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
		//If we found the closest kit, we get its pos and then we delete it from the table.
		GetEntPropVector(closest, Prop_Send, "m_vecOrigin", entPos);
		new String:sQuery[255];
		Format(sQuery, sizeof(sQuery), "DELETE FROM TF2_AutoKits WHERE locX = '%f' AND locY = '%f' AND locZ = '%f';", entPos[0], entPos[1], entPos[2]);
		SQL_TQuery(g_hDatabase, SQL_OnUpdateKit, sQuery);
		RemoveEdict(closest);
	}
	else
	{
		PrintToChat(client,"\x04[\x03AK\x04]\x01 There isn't any near kit to delete"); 
	}
	
}

/* SQL_OnUpdateKit()
**
** This is the delete query's callback. We inform that the deletion was successful or we log the error otherwise.
** -------------------------------------------------------------------------- */
public SQL_OnUpdateKit(Handle:owner, Handle:hndl, const String:error[], any:data) 
{ 
	
	if (hndl == INVALID_HANDLE) 
	{ 
		//There was a problem, log it 
		LogError("Query failed! %s", error); 
	} 
	else 
	{ 
		//Worked, so we tell them so 
		PrintToChatAll( "\x04[\x03AK\x04]\x01 Kit location deleted from database!");
	} 
}  

/* SpawnKit()
**
** Function used to spawn a kit by its type and position. We don't spawn any medkit if we are on sudden death.
** -------------------------------------------------------------------------- */
public SpawnKit(type_kit, Float:kit_pos[3])
{
	new kit_ent = -1;
	switch(type_kit)
	{
		case AK_MED_S:
		{
			if(isSuddenDeath) return;
			kit_ent = CreateEntityByName("item_healthkit_small");
		}
		case AK_MED_M:
		{
			if(isSuddenDeath) return;
			kit_ent = CreateEntityByName("item_healthkit_medium");
		}
		case AK_MED_F:
		{
			if(isSuddenDeath) return;
			kit_ent = CreateEntityByName("item_healthkit_full");		
		}
		case AK_AMMO_S:
		{
			kit_ent = CreateEntityByName("item_ammopack_small");
		}
		case AK_AMMO_M:
		{
			kit_ent = CreateEntityByName("item_ammopack_medium");		
		}
		case AK_AMMO_F:
		{
			kit_ent = CreateEntityByName("item_ammopack_full");
		}
	}
	if( kit_ent <= -1)
		return;
	
	if (DispatchSpawn(kit_ent))
	{
		SetEntProp(kit_ent, Prop_Send, "m_iTeamNum", 0, 4);
		DispatchKeyValue(kit_ent, "targetname", KIT_NAME);
		
		TeleportEntity(kit_ent, kit_pos, NULL_VECTOR, NULL_VECTOR);
		
		//We don't reproduce the spawn sound at start
		if(!onFirstSeconds)
			EmitSoundToAll("items/spawn_item.wav", kit_ent, _, _, _, 0.75);
	}
}

/* EntityOutput_Kit()
**
** Function used to spawn a kit by its type and position. We don't spawn any medkit if we are on sudden death.
** -------------------------------------------------------------------------- */
public EntityOutput_Kit(const String:output[], entity, activator, Float:delay)
{
	new String:name[64];
	GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
	if (StrEqual(name, KIT_NAME, false))	// make sure it is onw of our kits
	{

		new Float:pos[3], type = -1;
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		new String:classname[64];
		GetEntityClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "item_healthkit_small", false))
			type = AK_MED_S;
		else if (StrEqual(classname, "item_healthkit_medium", false))
			type = AK_MED_M;
		else if (StrEqual(classname, "item_healthkit_full", false))
			type = AK_MED_F;
		else if (StrEqual(classname, "item_ammopack_small", false))
			type = AK_AMMO_S;
		else if (StrEqual(classname, "item_ammopack_medium", false))
			type = AK_AMMO_M;
		else if (StrEqual(classname, "item_ammopack_full", false))
			type = AK_AMMO_F;
		if( type <= -1)
			return;
		
		//Here we prepare a respawn for the kit that a player just picked using its position and type.
		new Handle:pack;
		CreateDataTimer(KIT_RESPAWN_TIME, RespawnKit, pack);	//cvar to set timer time
		WritePackFloat(pack, pos[0]);
		WritePackFloat(pack, pos[1]);
		WritePackFloat(pack, pos[2]);
		WritePackCell(pack, type);
		RemoveEdict(entity);
	} 
} 

/* RespawnKit()
**
** Timer used to respawn the kit but only if we are not in the first seconds of the round (so we don't get double kits)
** -------------------------------------------------------------------------- */
public Action:RespawnKit(Handle:timer, Handle:pack)
{
	if(onFirstSeconds) return;
	new Float:pos[3], type;
	ResetPack(pack);
	pos[0] = ReadPackFloat(pack);
	pos[1] = ReadPackFloat(pack);
	pos[2] = ReadPackFloat(pack);
	type = ReadPackCell(pack);
	SpawnKit(type,pos);
}
