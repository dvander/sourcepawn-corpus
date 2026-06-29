#include <sourcemod>
#include <sdktools>

new Float:startpoint[3];					// where to start drawing lights
new Float:endpoint[3];						// where to stop drawing lights

new Handle:undo = INVALID_HANDLE;			// undo props made

new Handle:g_hDatabase; 					// sqlite database

public Plugin:myinfo = 
{
	name = "Christmasification",
	author = "MPQC",
	description = "Adds some Christmas lights",
	version = "1.0.3",
	url = "www.steamgamers.com"
}

public OnPluginStart()
{
	RegAdminCmd("sm_christmasification", Cmd_Christmasification, ADMFLAG_BAN, "Creates Christmas Lights"); 
	
	SQL_TConnect(OnDatabaseConnect, "christmasification");
	
	HookEvent("round_start", RoundStart);
	HookEvent("round_end", RoundEnd);
}

public OnMapStart()
{
	PrecacheModel("cable/cable.vmt");
	PrecacheModel("sprites/greenglow1.vmt");
	PrecacheModel("sprites/greenglow1.vtf");
	PrecacheModel("sprites/redglow3.vmt");
	PrecacheModel("sprites/redglow3.vtf");
}

public OnMapEnd()
{
	ClearUndo();
}

public Action:RoundStart(Handle:Event, const String:Name[], bool:Broadcast)
{
	if (g_hDatabase == INVALID_HANDLE)
	{
		return Plugin_Continue;
	}
	decl String:query[256];
	decl String:mapname[32];
	
	GetCurrentMap(mapname, sizeof(mapname));
	Format(query, sizeof(query), "SELECT * FROM christmasification WHERE mapname=\"%s\";", mapname); // get all lights in this map
	SQL_TQuery(g_hDatabase, SQL_PopulateMap, query);
	return Plugin_Continue;
}

public Action:RoundEnd(Handle:Event, const String:Name[], bool:Broadcast)
{
	ClearUndo();
	return Plugin_Continue;
}

public SQL_PopulateMap(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("SQL Query Error: %s", error);
		SetFailState("Lost connection to database. Reconnecting on map change.");
	}
	
	new Float:pos[3];
	
	new color[3]; color[2] = 0;
	
	while (SQL_MoreRows(hndl))
	{
		if (SQL_FetchRow(hndl))
		{
			// get the positions of the lights
			pos[0] = SQL_FetchFloat(hndl, 1);
			pos[1] = SQL_FetchFloat(hndl, 2);
			pos[2] = SQL_FetchFloat(hndl, 3);
			
			// grab the color of the lights.. we only care about the first color since we have either red or green
			color[0] = SQL_FetchInt(hndl, 4);
			if (color[0] == 255) // color of the light is red
			{
				color[1] = 0;
			}
			else // color is green
			{
				color[1] = 255;
			}
			
			CreateSprite(pos, color, false);
		}
	}
}

Save(client)
{
	if (IsStackEmpty(undo))
	{
		PrintToChat(client, "Round restarted or no lights made. Try again.");
		return;
	}
	
	new color;
	new index
	
	new Float:position[3];
	
	decl String:mapname[32];
	decl String:query[256];
	
	GetCurrentMap(mapname, sizeof(mapname));
	
	// keep popping from the stack until it's empty, and save the position/color of the light
	while (!IsStackEmpty(undo))
	{
		PopStackCell(undo, index);
		if (IsValidEdict(index))
		{
			GetEntPropVector(index, Prop_Send, "m_vecOrigin", position);
			color = GetEntProp(index, Prop_Send, "m_clrRender", 4, 0) & 0xFF;
			Format(query, sizeof(query), "INSERT INTO christmasification (mapname, first, second, third, color) VALUES (\"%s\", \"%f\", \"%f\", \"%f\", %d);", mapname, position[0], position[1], position[2], color);
			SQL_TQuery(g_hDatabase, SQL_DoNothing, query);
		}
	}
}

Undo(client)
{
	if (IsStackEmpty(undo))
	{
		PrintToChat(client, "Round restarted or no lights made. Try again.");
		return;
	}
	
	new index;
	
	// empty the stack and delete all entities within it
	while (!IsStackEmpty(undo))
	{
		PopStackCell(undo, index);
		if (IsValidEdict(index))
		{
			AcceptEntityInput(index, "Kill");
		}
	}
}

ClearAllSQL(client)
{
	decl String:query[256];
	decl String:mapname[32];
	
	GetCurrentMap(mapname, sizeof(mapname));

	Format(query, sizeof(query), "DELETE FROM christmasification WHERE mapname=\"%s\";", mapname);
	SQL_TQuery(g_hDatabase, SQL_DoNothing, query);
	PrintToChat(client, "[Christmasification] Cleared all lights.");
}


public OnDatabaseConnect(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		PrintToServer("Error connecting to database: %s", error);
		SetFailState("Lost connection to database. Reconnecting on map change.");
	}
	
	g_hDatabase = hndl;
	
	SQL_TQuery(g_hDatabase, SQL_DoNothing, "CREATE TABLE IF NOT EXISTS christmasification (mapname VARCHAR(64), first REAL, second REAL, third REAL, color INTEGER);");
}

public SQL_DoNothing(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("SQL query errors: %s", error);
		SetFailState("Lost connection to database. Reconnecting on map change.");
	}
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////         MENU            ///////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public Action:Cmd_Christmasification(client, args)
{
	MainMenu(client);
	return Plugin_Handled;
}

MainMenu(client)
{
	if (client == 0 || (!IsClientInGame(client)))
	{
		return;
	}
	
	new Handle:menu = CreateMenu(MainMenuHandler);
	SetMenuTitle(menu, "Christmas Menu");
	AddMenuItem(menu, "lights", "Add Lights");
	AddMenuItem(menu, "lights", "Clear All Lights");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 60);
}

public MainMenuHandler(Handle:menu, MenuAction:action, client, buttonnum)
{
	if (action == MenuAction_Select)
	{
		if (buttonnum == 0)
		{
			ChooseLightTypeMenu(client);
		}
		else if (buttonnum == 1)
		{
			ClearAll(client);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

ClearAll(client)
{
	if (client == 0 || (!IsClientInGame(client)))
	{
		return;
	}
	
	new Handle:menu = CreateMenu(ClearAllMenuHandler);
	SetMenuTitle(menu, "Are you sure you want to erase all lights?");
	AddMenuItem(menu, "yes", "Yes");
	AddMenuItem(menu, "no", "No");
	SetMenuExitButton(menu, true);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 60);
}

public ClearAllMenuHandler(Handle:menu, MenuAction:action, client, buttonnum)
{
	if (action == MenuAction_Select)
	{
		if (buttonnum == 0)
		{
			ClearAllSQL(client);
			MainMenu(client);
		}
		else
		{
			MainMenu(client);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (buttonnum == MenuCancel_ExitBack)
		{
			MainMenu(client);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

ChooseLightTypeMenu(client)
{
	if (client == 0 || (!IsClientInGame(client)))
	{
		return;
	}
	
	new Handle:menu = CreateMenu(ChooseLightTypeMenuHandler);
	SetMenuTitle(menu, "Choose Light Type");
	AddMenuItem(menu, "look", "Row of Lights");
	AddMenuItem(menu, "lights", "Individual light");
	SetMenuExitButton(menu, true);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 60);
}

public ChooseLightTypeMenuHandler(Handle:menu, MenuAction:action, client, buttonnum)
{
	if (action == MenuAction_Select)
	{
		if (buttonnum == 0)
		{
			AddLightsMenu(client);
		}
		else if (buttonnum == 1)
		{
			AddIndividualLightMenu(client);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (buttonnum == MenuCancel_ExitBack)
		{
			MainMenu(client);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

AddIndividualLightMenu(client)
{
	if (client == 0 || (!IsClientInGame(client)))
	{
		return;
	}
	
	new Handle:menu = CreateMenu(AddIndividualLightMenuHandler);
	SetMenuTitle(menu, "Add Lights Menu");
	AddMenuItem(menu, "look", "Look where you want the light to be created", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "lights", "Red");
	AddMenuItem(menu, "lights", "Green");
	SetMenuExitButton(menu, true);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 60);
}

public AddIndividualLightMenuHandler(Handle:menu, MenuAction:action, client, buttonnum)
{
	if (action == MenuAction_Select)
	{
		if (buttonnum == 1)
		{
			new Float:position[3];
			ClearUndo();
			TraceEye(client, position);
			CreateSprite(position, {255, 0, 0}); // red
			DecideLightsMenuEnd(client);
		}
		else if (buttonnum == 2)
		{
			new Float:position[3];
			ClearUndo();
			TraceEye(client, position);
			CreateSprite(position, {0, 255, 0}); // green
			DecideLightsMenuEnd(client);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (buttonnum == MenuCancel_ExitBack)
		{
			ChooseLightTypeMenu(client);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

AddLightsMenu(client)
{
	if (client == 0 || (!IsClientInGame(client)))
	{
		return;
	}
	
	new Handle:menu = CreateMenu(AddLightsMenuHandler);
	SetMenuTitle(menu, "Add Lights Menu");
	AddMenuItem(menu, "look", "Look at where you want to begin adding lights then push 2", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "lights", "Begin");
	SetMenuExitButton(menu, true);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 60);
}

public AddLightsMenuHandler(Handle:menu, MenuAction:action, client, buttonnum)
{
	if (action == MenuAction_Select)
	{
		if (buttonnum == 0 || buttonnum == 1)
		{
			TraceEye(client, startpoint);
			AddLightsMenuEnd(client);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (buttonnum == MenuCancel_ExitBack)
		{
			ChooseLightTypeMenu(client);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

AddLightsMenuEnd(client)
{
	if (client == 0 || (!IsClientInGame(client)))
	{
		return;
	}
	
	new Handle:menu = CreateMenu(AddLightsMenuEndHandler);
	SetMenuTitle(menu, "Add Lights Menu");
	AddMenuItem(menu, "look", "Look at where you want to end adding the lights then push 2", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "lights", "End");
	SetMenuExitButton(menu, true);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 60);
}

public AddLightsMenuEndHandler(Handle:menu, MenuAction:action, client, buttonnum)
{
	if (action == MenuAction_Select)
	{
		if (buttonnum == 0 || buttonnum == 1)
		{
			TraceEye(client, endpoint);
			DrawLights();
			DecideLightsMenuEnd(client);
		}
		
	}
	else if (action == MenuAction_Cancel)
	{
		if (buttonnum == MenuCancel_ExitBack)
		{
			AddLightsMenu(client);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

DecideLightsMenuEnd(client)
{
	if (client == 0 || (!IsClientInGame(client)))
	{
		return;
	}
	
	new Handle:menu = CreateMenu(DecideLightsMenuHandler);
	SetMenuTitle(menu, "Decide Lights Menu");
	AddMenuItem(menu, "look", "Save");
	AddMenuItem(menu, "lights", "Undo");
	SetMenuExitButton(menu, true);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 60);
}

public DecideLightsMenuHandler(Handle:menu, MenuAction:action, client, buttonnum)
{
	if (action == MenuAction_Select)
	{
		if (buttonnum == 0)
		{
			Save(client);
			MainMenu(client);
		}
		else if (buttonnum == 1)
		{
			Undo(client);
			MainMenu(client);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (buttonnum == MenuCancel_ExitBack)
		{
			Undo(client);
			AddLightsMenuEnd(client);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

// This function is taken from Mitchell's LASERRRRRRRRSSSS plugin. All credits to him for it.
TraceEye(client, Float:pos[3])
{
	decl Float:vAngles[3], Float:vOrigin[3];
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	TR_TraceRayFilter(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	if(TR_DidHit(INVALID_HANDLE)) TR_GetEndPosition(pos, INVALID_HANDLE);
	return;
}

// This function is taken from Mitchell's LASERRRRRRRRSSSS plugin. All credits to him for it.
public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return (entity > GetMaxClients() || !entity);
}

DrawLights()
{
	new Float:direction[3];
	new Float:starting[3];
	
	starting[0] = startpoint[0];
	starting[1] = startpoint[1];
	starting[2] = startpoint[2];
	
	SubtractVectors(endpoint, startpoint, direction);
	NormalizeVector(direction, direction);
	ScaleVector(direction, 75.0);
	
	ClearUndo();
	
	new i = 0;
	new bool:loop = true;
	
	while(loop)
	{
		if (i % 2 == 0)
		{
			CreateSprite(starting, {255, 0, 0}); // red
		}
		else
		{
			CreateSprite(starting, {0, 255, 0}); // green
		}
		
		if (GetVectorDistance(endpoint, starting) < 75.0)
		{
			break;
		}
		
		AddVectors(starting, direction, starting);
		
		i++;
	}
}

CreateSprite(Float:position[3], color[3], bool:pushstack=true)
{
    new sprite = CreateEntityByName("env_sprite");

    if(sprite != -1)
    {
		decl String:colors[32];
		Format(colors, sizeof(colors), "%d %d %d", color[0], color[1], color[2]);
		DispatchKeyValue(sprite, "spawnflags", "1");
		DispatchKeyValue(sprite, "scale", "0.5");
		DispatchKeyValue(sprite, "rendermode", "9");
		DispatchKeyValue(sprite, "model", "sprites/greenglow1.vmt");
		DispatchKeyValue(sprite, "rendercolor", colors);
		DispatchSpawn(sprite);
		TeleportEntity(sprite, position, NULL_VECTOR, NULL_VECTOR);
		
		if (pushstack)
		{
			PushStackCell(undo, sprite);
		}
	}
} 

ClearUndo()
{
	if (undo == INVALID_HANDLE)
	{
		undo = CreateStack(1);
	}
	else
	{
		// if there's stuff within the stack, remove it all
		while(!IsStackEmpty(undo))
		{
			PopStack(undo);
		}
	}
}
