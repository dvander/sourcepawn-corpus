#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

#define NO_POINT 0
#define FIRST_POINT 1
#define SECOND_POINT 2

#define PREFIX "\x04NoBuild Zones \x01> \x03"

new Handle:g_hZones;

new g_iPlayerCreatesZone[MAXPLAYERS+2] = {NO_POINT,...};
new bool:g_bPlayerPressesUse[MAXPLAYERS+2] = {false,...};

new g_iPlayerEditsZone[MAXPLAYERS+2] = {-1,...};
new g_iPlayerEditsVector[MAXPLAYERS+2] = {-1,...};

new Float:g_fTempZoneVector1[MAXPLAYERS+2][3];
new Float:g_fTempZoneVector2[MAXPLAYERS+2][3];

new g_iLaserMaterial = -1;
new g_iHaloMaterial = -1;
new g_iGlowSprite = -1;

public Plugin:myinfo = 
{
	name = "NoBuild Zones",
	author = "Jannik 'Peace-Maker' Hartung",
	description = "Defines zones dynamically where engineers aren't allowed to build",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
	new Handle:hVersion = CreateConVar("sm_nobuildzones_version", PLUGIN_VERSION, "Anti Rush Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if(hVersion != INVALID_HANDLE)
		SetConVarString(hVersion, PLUGIN_VERSION);
	
	g_hZones = CreateArray();
	
	HookEvent("bullet_impact", Event_OnBulletImpact);
	HookEvent("teamplay_round_start", Event_OnRoundStart);
	
	RegAdminCmd("sm_nobuild", Command_SetupZones, ADMFLAG_CONFIG, "Sets up nobuild zones");
}

/**
 * Events
 */
public OnMapStart()
{
	g_iLaserMaterial = PrecacheModel("materials/sprites/laser.vmt");
	g_iHaloMaterial = PrecacheModel("materials/sprites/halo01.vmt");
	g_iGlowSprite = PrecacheModel("sprites/blueglow2.vmt", true);
	
	PrecacheModel("models/items/car_battery01.mdl", true);
	
	ParseZoneConfig();
}
public OnClientDisconnect(client)
{
	g_iPlayerCreatesZone[client] = NO_POINT;
	g_iPlayerEditsZone[client] = -1;
	g_iPlayerEditsVector[client] = -1;
	
	g_bPlayerPressesUse[client] = false;
}

// When adding a new zone, players can push +use to save a location at their feet
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(buttons & IN_USE)
	{
		if(!g_bPlayerPressesUse[client] && g_iPlayerCreatesZone[client] != NO_POINT)
		{
			new Float:fOrigin[3];
			GetClientAbsOrigin(client, fOrigin);
			
			// Player is creating a zone
			if(g_iPlayerCreatesZone[client] == FIRST_POINT)
			{
				g_fTempZoneVector1[client][0] = fOrigin[0];
				g_fTempZoneVector1[client][1] = fOrigin[1];
				g_fTempZoneVector1[client][2] = fOrigin[2];
				g_iPlayerCreatesZone[client] = SECOND_POINT;
				PrintToChat(client, "%sNow shoot the other diagonally opposite corner of the cube or press e to set it at your feet.", PREFIX);
			}
			else if(g_iPlayerCreatesZone[client] == SECOND_POINT)
			{
				g_fTempZoneVector2[client][0] = fOrigin[0];
				g_fTempZoneVector2[client][1] = fOrigin[1];
				g_fTempZoneVector2[client][2] = fOrigin[2];
				g_iPlayerCreatesZone[client] = NO_POINT;
			
				// Display the zone for now
				TE_SendBeamBoxToClient(client, g_fTempZoneVector1[client], g_fTempZoneVector2[client], g_iLaserMaterial, g_iHaloMaterial, 0, 30, 5.0, 5.0, 5.0, 2, 1.0, {255,0,0,255}, 0);
				
				// Confirm the new zone
				new Handle:menu = CreateMenu(MenuHandler_SaveNewZone);
				SetMenuTitle(menu, "Add this new nobuild zone?");
				SetMenuExitButton(menu, false);
				
				AddMenuItem(menu, "save", "Save");
				AddMenuItem(menu, "discard", "Discard");
				
				DisplayMenu(menu, client, MENU_TIME_FOREVER);
			}
		}
		g_bPlayerPressesUse[client] = true;
	}
	else
	{
		g_bPlayerPressesUse[client] = false;
	}
	return Plugin_Continue;
}

// When adding a new zone, player shots are saved as positions
public Action:Event_OnBulletImpact(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new Float:x = GetEventFloat(event, "x");
	new Float:y = GetEventFloat(event, "y");
	new Float:z = GetEventFloat(event, "z");
	
	// Player is creating a zone
	if(g_iPlayerCreatesZone[client] == FIRST_POINT)
	{
		g_fTempZoneVector1[client][0] = x;
		g_fTempZoneVector1[client][1] = y;
		g_fTempZoneVector1[client][2] = z;
		g_iPlayerCreatesZone[client] = SECOND_POINT;
		PrintToChat(client, "%sNow shoot the other diagonally opposite corner of the cube or press e to set it at your feet.", PREFIX);
	}
	else if(g_iPlayerCreatesZone[client] == SECOND_POINT)
	{
		g_fTempZoneVector2[client][0] = x;
		g_fTempZoneVector2[client][1] = y;
		g_fTempZoneVector2[client][2] = z;
		g_iPlayerCreatesZone[client] = NO_POINT;
		
		// Display the zone for now
		TE_SendBeamBoxToClient(client, g_fTempZoneVector1[client], g_fTempZoneVector2[client], g_iLaserMaterial, g_iHaloMaterial, 0, 30, 5.0, 5.0, 5.0, 2, 1.0, {255,0,0,255}, 0);
		
		// Confirm the new zone
		new Handle:menu = CreateMenu(MenuHandler_SaveNewZone);
		SetMenuTitle(menu, "Add this new nobuild zone?");
		SetMenuExitButton(menu, false);
		
		AddMenuItem(menu, "save", "Save");
		AddMenuItem(menu, "discard", "Discard");
		
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
	
	return Plugin_Continue;
}

public Action:Event_OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	// First remove any old zone triggers
	new iEnts = GetMaxEntities();
	decl String:sClassName[64];
	for(new i=MaxClients;i<iEnts;i++)
	{
		if(IsValidEntity(i)
		&& IsValidEdict(i)
		&& GetEdictClassname(i, sClassName, sizeof(sClassName))
		&& StrContains(sClassName, "trigger_multiple") != -1
		&& GetEntPropString(i, Prop_Data, "m_iName", sClassName, sizeof(sClassName))
		&& StrContains(sClassName, "sm_nobuild") != -1)
		{
			AcceptEntityInput(i, "Kill");
		}
	}
	
	// Create the func_nobuilds
	new iSize = GetArraySize(g_hZones);
	for(new i=0;i<iSize;i++)
	{
		SpawnFuncNoBuild(i);
	}
	
	return Plugin_Continue;
}

/**
 * Command Callbacks
 */
public Action:Command_SetupZones(client, args)
{
	if(!client)
	{
		ReplyToCommand(client, "NoBuild Zones > Command is in-game only.");
		return Plugin_Handled;
	}

	g_iPlayerCreatesZone[client] = NO_POINT;
	ClearVector(g_fTempZoneVector1[client]);
	ClearVector(g_fTempZoneVector2[client]);
	
	decl String:sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	
	new Handle:menu = CreateMenu(MenuHandler_Zones);
	SetMenuTitle(menu, "NoBuild Zones on %s:", sMap);
	SetMenuExitButton(menu, true);
	
	AddMenuItem(menu, "add_zone", "Add Zones");
	
	AddMenuItem(menu, "", "", ITEMDRAW_SPACER);
	
	new iSize = GetArraySize(g_hZones);
	decl String:sBuffer[256], String:sNum[3];
	for(new i=0;i<iSize;i++)
	{
		Format(sBuffer, sizeof(sBuffer), "Zone %d", i);
		IntToString(i, sNum, sizeof(sNum));
		AddMenuItem(menu, sNum, sBuffer);
	}
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	
	return  Plugin_Handled;
}

/**
 * Menu Handlers
 */

public MenuHandler_Zones(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if(StrEqual(info, "add_zone"))
		{
			PrintToChat(param1, "%sShoot at the first corner of your cube or press e to set it at your feet.", PREFIX);
			g_iPlayerCreatesZone[param1] = FIRST_POINT;
		}
		else
		{
			// Store the zone index for further reference
			new iZone = StringToInt(info);
			g_iPlayerEditsZone[param1] = iZone;
			
			ShowZoneOptionMenu(param1);
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_ExitBack)
		{
			Command_SetupZones(param1, 0);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_SelectZone(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		// Store the zone index for further reference
		new iZone = StringToInt(info);
		g_iPlayerEditsZone[param1] = iZone;
		
		ShowZoneOptionMenu(param1);
	}
	else if(action == MenuAction_Cancel)
	{
		// Player isn't editing this zone anymore
		g_iPlayerEditsZone[param1] = -1;
		if(param2 == MenuCancel_ExitBack)
		{
			Command_SetupZones(param1, 0);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_SelectVector(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		new Handle:hZone, Float:fVec1[3], Float:fVec2[3];
		// Show the box, if teleporting to it, show it either
		if(StrEqual(info, "show") || StrEqual(info, "teleport"))
		{
			hZone = GetArrayCell(g_hZones, g_iPlayerEditsZone[param1]);
			GetArrayArray(hZone, 0, fVec1, 3);
			GetArrayArray(hZone, 1, fVec2, 3);
			
			TE_SendBeamBoxToClient(param1, fVec1, fVec2, g_iLaserMaterial, g_iHaloMaterial, 0, 30, 5.0, 5.0, 5.0, 2, 1.0, {255,0,0,255}, 0);
			
			if(!StrEqual(info, "teleport"))
				// Redisplay the menu
				ShowZoneOptionMenu(param1);
		}
		
		// Teleport to position
		if(StrEqual(info, "teleport"))
		{
			new Float:fOrigin[3];
			hZone = GetArrayCell(g_hZones, g_iPlayerEditsZone[param1]);
			
			GetArrayArray(hZone, 0, fVec1, 3);
			GetArrayArray(hZone, 1, fVec2, 3);
			GetMiddleOfABox(fVec1, fVec2, fOrigin);
			TeleportEntity(param1, fOrigin, NULL_VECTOR, Float:{0.0,0.0,0.0});
			
			// Redisplay the menu
			ShowZoneOptionMenu(param1);
		}
		// Start editing the zone
		else if(StrEqual(info, "vec1") || StrEqual(info, "vec2"))
		{
			if(StrEqual(info, "vec1"))
				g_iPlayerEditsVector[param1] = 1;
			else
				g_iPlayerEditsVector[param1] = 2;
			
			hZone = GetArrayCell(g_hZones, g_iPlayerEditsZone[param1]);
			GetArrayArray(hZone, 0, fVec1, 3);
			GetArrayArray(hZone, 1, fVec2, 3);
			
			// Display the zone for now
			TE_SendBeamBoxToClient(param1, fVec1, fVec2, g_iLaserMaterial, g_iHaloMaterial, 0, 30, 5.0, 5.0, 5.0, 2, 1.0, {255,0,0,255}, 0);
			
			// Highlight the currently edited edge for players editing a zone
			if(g_iPlayerEditsVector[param1] == 1)
			{
				TE_SetupGlowSprite(fVec1, g_iGlowSprite, 5.0, 1.0, 100);
				TE_SendToClient(param1);
			}
			else if(g_iPlayerEditsVector[param1] == 2)
			{
				TE_SetupGlowSprite(fVec2, g_iGlowSprite, 5.0, 1.0, 100);
				TE_SendToClient(param1);
			}
			
			ShowZoneVectorEditMenu(param1);
		}
		// Delete
		else if(StrEqual(info, "delete"))
		{
			new Handle:panel = CreatePanel();
			
			decl String:sBuffer[256];
			
			Format(sBuffer, sizeof(sBuffer), "Do you really want to delete zone %d", g_iPlayerEditsZone[param1]);
			
			SetPanelTitle(panel, sBuffer);
			DrawPanelItem(panel, "Yes");
			DrawPanelItem(panel, "No");
			
			SendPanelToClient(panel, param1, PanelHandler_ConfirmDelete, 20);
			
			CloseHandle(panel);
		}
	}
	else if(action == MenuAction_Cancel)
	{
		g_iPlayerEditsZone[param1] = -1;
		g_iPlayerEditsVector[param1] = -1;
		
		if(param2 == MenuCancel_ExitBack)
		{
			Command_SetupZones(param1, 0);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_EditVector(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new Handle:hZone = GetArrayCell(g_hZones, g_iPlayerEditsZone[param1]);
		new Float:fVec1[3], Float:fVec2[3];
		// Add to the x axis
		if(StrEqual(info, "ax"))
		{
			if(g_iPlayerEditsVector[param1] == 1)
			{
				GetArrayArray(hZone, 0, fVec1, 3);
				fVec1[0] += 5.0;
				SetArrayArray(hZone, 0, fVec1, 3);
			}
			else if(g_iPlayerEditsVector[param1] == 2)
			{
				GetArrayArray(hZone, 1, fVec2, 3);
				fVec2[0] += 5.0;
				SetArrayArray(hZone, 1, fVec2, 3);
			}
		}
		// Add to the y axis
		else if(StrEqual(info, "ay"))
		{
			if(g_iPlayerEditsVector[param1] == 1)
			{
				GetArrayArray(hZone, 0, fVec1, 3);
				fVec1[1] += 5.0;
				SetArrayArray(hZone, 0, fVec1, 3);
			}
			else if(g_iPlayerEditsVector[param1] == 2)
			{
				GetArrayArray(hZone, 1, fVec2, 3);
				fVec2[1] += 5.0;
				SetArrayArray(hZone, 1, fVec2, 3);
			}
		}
		// Add to the z axis
		else if(StrEqual(info, "az"))
		{
			if(g_iPlayerEditsVector[param1] == 1)
			{
				GetArrayArray(hZone, 0, fVec1, 3);
				fVec1[2] += 5.0;
				SetArrayArray(hZone, 0, fVec1, 3);
			}
			else if(g_iPlayerEditsVector[param1] == 2)
			{
				GetArrayArray(hZone, 1, fVec2, 3);
				fVec2[2] += 5.0;
				SetArrayArray(hZone, 1, fVec2, 3);
			}
		}
		// Subtract from the x axis
		else if(StrEqual(info, "sx"))
		{
			if(g_iPlayerEditsVector[param1] == 1)
			{
				GetArrayArray(hZone, 0, fVec1, 3);
				fVec1[0] -= 5.0;
				SetArrayArray(hZone, 0, fVec1, 3);
			}
			else if(g_iPlayerEditsVector[param1] == 2)
			{
				GetArrayArray(hZone, 1, fVec2, 3);
				fVec2[0] -= 5.0;
				SetArrayArray(hZone, 1, fVec2, 3);
			}
		}
		// Subtract from the y axis
		else if(StrEqual(info, "sy"))
		{
			if(g_iPlayerEditsVector[param1] == 1)
			{
				GetArrayArray(hZone, 0, fVec1, 3);
				fVec1[1] -= 5.0;
				SetArrayArray(hZone, 0, fVec1, 3);
			}
			else if(g_iPlayerEditsVector[param1] == 2)
			{
				GetArrayArray(hZone, 1, fVec2, 3);
				fVec2[1] -= 5.0;
				SetArrayArray(hZone, 1, fVec2, 3);
			}
		}
		// Subtract from the z axis
		else if(StrEqual(info, "sz"))
		{
			if(g_iPlayerEditsVector[param1] == 1)
			{
				GetArrayArray(hZone, 0, fVec1, 3);
				fVec1[2] -= 5.0;
				SetArrayArray(hZone, 0, fVec1, 3);
			}
			else if(g_iPlayerEditsVector[param1] == 2)
			{
				GetArrayArray(hZone, 1, fVec2, 3);
				fVec2[2] -= 5.0;
				SetArrayArray(hZone, 1, fVec2, 3);
			}
		}

		ApplyNewBoundsToZone(g_iPlayerEditsZone[param1]);
		
		SaveZonesToConfig();
		
		GetArrayArray(hZone, 0, fVec1, 3);
		GetArrayArray(hZone, 1, fVec2, 3);
		
		TE_SendBeamBoxToClient(param1, fVec1, fVec2, g_iLaserMaterial, g_iHaloMaterial, 0, 30, 5.0, 5.0, 5.0, 2, 1.0, {255,0,0,255}, 0);
		
		// Highlight the currently edited edge for players editing a zone
		if(g_iPlayerEditsVector[param1] == 1)
		{
			TE_SetupGlowSprite(fVec1, g_iGlowSprite, 5.0, 1.0, 100);
			TE_SendToClient(param1);
		}
		else if(g_iPlayerEditsVector[param1] == 2)
		{
			TE_SetupGlowSprite(fVec2, g_iGlowSprite, 5.0, 1.0, 100);
			TE_SendToClient(param1);
		}
		
		// Redisplay the menu
		ShowZoneVectorEditMenu(param1);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_ExitBack)
			ShowZoneOptionMenu(param1);
		else
			g_iPlayerEditsZone[param1] = -1;
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_SaveNewZone(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		// Don't save the new zone
		if(StrEqual(info, "discard"))
		{
			ClearVector(g_fTempZoneVector1[param1]);
			ClearVector(g_fTempZoneVector2[param1]);
			
			PrintToChat(param1, "%sDiscarded", PREFIX);
		}
		// Save the new zone
		else if(StrEqual(info, "save"))
		{
			// Store the current vectors to the array
			new Handle:hZone = CreateArray(3);
			
			// set the vec1
			PushArrayArray(hZone, g_fTempZoneVector1[param1], 3);
			
			// set the vec2
			PushArrayArray(hZone, g_fTempZoneVector2[param1], 3);
			
			// save the new zone for editing
			g_iPlayerEditsZone[param1] = PushArrayCell(g_hZones, hZone);
			
			// Save to config file
			SaveZonesToConfig();
			
			// Spawn the func_nobuild
			SpawnFuncNoBuild(g_iPlayerEditsZone[param1]);
			
			PrintToChat(param1, "%sSaved new nobuild zone", PREFIX);
			
			ShowZoneOptionMenu(param1);
		}
	}
	else if(action == MenuAction_Cancel)
	{
		g_iPlayerEditsZone[param1] = -1;
		g_iPlayerEditsVector[param1] = -1;
		ClearVector(g_fTempZoneVector1[param1]);
		ClearVector(g_fTempZoneVector2[param1]);
			
		if(param2 == MenuCancel_ExitBack)
		{
			Command_SetupZones(param1, 0);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public PanelHandler_ConfirmDelete(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		// Selected yes
		if(param2 == 1)
		{
			// Kill the trigger_multiple if zone
			KillNoBuildEntity(g_iPlayerEditsZone[param1]);
			
			// Delete from cache array
			new Handle:hZone = GetArrayCell(g_hZones, g_iPlayerEditsZone[param1]);
			CloseHandle(hZone);
			
			RemoveFromArray(g_hZones, g_iPlayerEditsZone[param1]);
			
			new iSize = GetArraySize(g_hZones);
			if(g_iPlayerEditsZone[param1] < iSize)
			{
				// Adjust the targetnames to the new array indexes
				new iEnts = GetMaxEntities();
				decl String:sClassName[256];
				new iIndex;
				for(new i=MaxClients+1;i<iEnts;i++)
				{
					if(IsValidEntity(i)
					&& IsValidEdict(i)
					&& GetEdictClassname(i, sClassName, sizeof(sClassName))
					&& StrContains(sClassName, "func_nobuild") != -1
					&& GetEntPropString(i, Prop_Data, "m_iName", sClassName, sizeof(sClassName))
					&& StrContains(sClassName, "sm_nobuild_") != -1)
					{
						iIndex = StringToInt(sClassName[11]);
						if(iIndex > g_iPlayerEditsZone[param1])
						{
							Format(sClassName, sizeof(sClassName), "sm_nobuild_%d", --iIndex);
							DispatchKeyValue(i, "targetname", sClassName);
						}
					}
				}
			}
			
			// Correct the indexes for other admins editing a zone currently.
			for(new i=1;i<=MaxClients;i++)
			{
				if(i == param1)
					continue;
				
				if(g_iPlayerEditsZone[i] == g_iPlayerEditsZone[param1])
					g_iPlayerEditsZone[i] = -1;
				else if(g_iPlayerEditsZone[i] != -1 && g_iPlayerEditsZone[i] > g_iPlayerEditsZone[param1])
					g_iPlayerEditsZone[i]--;
			}
			
			g_iPlayerEditsZone[param1] = -1;
			
			// Delete from config file
			SaveZonesToConfig();
			
			PrintToChat(param1, "%sDeleted Zone", PREFIX);
			Command_SetupZones(param1, 0);
		}
		else
		{
			PrintToChat(param1, "%sCanceled Zone Deletion", PREFIX);
			ShowZoneOptionMenu(param1);
		}
	} else if (action == MenuAction_Cancel) {
		PrintToChat(param1, "%sCanceled Zone Deletion", PREFIX);

		ShowZoneOptionMenu(param1);
	}
}

ShowZoneOptionMenu(client)
{
	if(g_iPlayerEditsZone[client] == -1)
		return;
	
	new Handle:menu = CreateMenu(MenuHandler_SelectVector);
	
	SetMenuTitle(menu, "Manage Zone %d", g_iPlayerEditsZone[client]);
	SetMenuExitBackButton(menu, true);
	
	AddMenuItem(menu, "show", "Show Zone");
	AddMenuItem(menu, "vec1", "Edit First Point");
	AddMenuItem(menu, "vec2", "Edit Second Point");
	
	AddMenuItem(menu, "teleport", "Teleport To");
	
	AddMenuItem(menu, "delete", "Delete Zone");
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

ShowZoneVectorEditMenu(client)
{
	if(g_iPlayerEditsZone[client] == -1 || g_iPlayerEditsVector[client] == -1)
		return;
	
	new Handle:menu = CreateMenu(MenuHandler_EditVector);
	SetMenuTitle(menu, "Edit Zone %d | Point %d", g_iPlayerEditsZone[client], g_iPlayerEditsVector[client]);
	SetMenuExitBackButton(menu, true);
	
	AddMenuItem(menu, "ax", "Add to X");
	AddMenuItem(menu, "sx", "Subtract from X");
	AddMenuItem(menu, "ay", "Add to Y");
	AddMenuItem(menu, "sy", "Subtract from Y");
	AddMenuItem(menu, "az", "Add to Z");
	AddMenuItem(menu, "sz", "Subtract from Z");
	
	AddMenuItem(menu, "show", "Show Zone");
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

ParseZoneConfig()
{
	// Clear previous info
	new iSize = GetArraySize(g_hZones);
	new Handle:hZone;
	for(new i=0;i<iSize;i++)
	{
		hZone = GetArrayCell(g_hZones, i);
		CloseHandle(hZone);
	}
	ClearArray(g_hZones);
	
	decl String:sConfigFile[PLATFORM_MAX_PATH], String:sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	BuildPath(Path_SM, sConfigFile, sizeof(sConfigFile), "configs/nobuildzones/%s.cfg", sMap);
	
	if(!FileExists(sConfigFile))
	{
		//SetFailState("Can't find configfile: %s", sConfigFile);
		return;
	}
	
	new Handle:kv = CreateKeyValues("NoBuildZones");
	FileToKeyValues(kv, sConfigFile);
	if(!KvGotoFirstSubKey(kv))
	{
		CloseHandle(kv);
		//SetFailState("Error parsing config file: %s", sConfigFile);
		return;
	}
	
	new Float:fVec[3];
	new iZoneIndex;
	do
	{
		hZone = CreateArray(3);
		
		KvGetVector(kv, "vec1", fVec);
		PushArrayArray(hZone, fVec, 3);
		
		KvGetVector(kv, "vec2", fVec);
		PushArrayArray(hZone, fVec, 3);
		
		iZoneIndex = PushArrayCell(g_hZones, hZone);
		
		SpawnFuncNoBuild(iZoneIndex);
	} while (KvGotoNextKey(kv));
	
	CloseHandle(kv);
}

SaveZonesToConfig()
{
	// Delete from config file
	decl String:sConfigFile[PLATFORM_MAX_PATH], String:sMap[64];
	BuildPath(Path_SM, sConfigFile, sizeof(sConfigFile), "configs/nobuildzones");
	
	if(!DirExists(sConfigFile))
		CreateDirectory(sConfigFile, 511);
	
	GetCurrentMap(sMap, sizeof(sMap));
	BuildPath(Path_SM, sConfigFile, sizeof(sConfigFile), "configs/nobuildzones/%s.cfg", sMap);
	
	new Handle:kv = CreateKeyValues("NoBuildZones");
	
	decl String:sBuffer[64];
	new iSize = GetArraySize(g_hZones);
	new Handle:hZone, Float:fVec[3];
	for(new i=0;i<iSize;i++)
	{
		hZone = GetArrayCell(g_hZones, i);
		
		IntToString(i, sBuffer, sizeof(sBuffer));
		KvJumpToKey(kv, sBuffer, true);
		
		GetArrayArray(hZone, 0, fVec, 3);
		KvSetVector(kv, "vec1", fVec);
		
		GetArrayArray(hZone, 1, fVec, 3);
		KvSetVector(kv, "vec2", fVec);
		
		KvGoBack(kv);
	}
	
	KvRewind(kv);
	KeyValuesToFile(kv, sConfigFile);
	CloseHandle(kv);
}

stock ClearVector(Float:vec[3])
{
	vec[0] = 0.0;
	vec[1] = 0.0;
	vec[2] = 0.0;
}

stock bool:IsNullVector(const Float:vec[3])
{
	if(vec[0] == 0.0 && vec[1] == 0.0 && vec[2] == 0.0)
		return true;
	return false;
}

stock GetMiddleOfABox(const Float:vec1[3], const Float:vec2[3], Float:buffer[3])
{
	new Float:mid[3];
	MakeVectorFromPoints(vec1, vec2, mid);
	mid[0] = mid[0] / 2.0;
	mid[1] = mid[1] / 2.0;
	mid[2] = mid[2] / 2.0;
	AddVectors(vec1, mid, buffer);
}

SpawnFuncNoBuild(iZoneIndex)
{
	new Float:fMiddle[3], Float:fMins[3], Float:fMaxs[3];
	
	new Handle:hZone = GetArrayCell(g_hZones, iZoneIndex);
	GetArrayArray(hZone, 0, fMins, 3);
	GetArrayArray(hZone, 1, fMaxs, 3);
	
	new iEnt = CreateEntityByName("func_nobuild");
	
	decl String:sZoneName[32];
	DispatchKeyValue(iEnt, "spawnflags", "64");
	Format(sZoneName, sizeof(sZoneName), "sm_nobuild_%d", iZoneIndex);
	DispatchKeyValue(iEnt, "targetname", sZoneName);
	
	DispatchSpawn(iEnt);
	ActivateEntity(iEnt);
	SetEntProp(iEnt, Prop_Data, "m_spawnflags", 64 );
	
	GetMiddleOfABox(fMins, fMaxs, fMiddle);
	
	TeleportEntity(iEnt, fMiddle, NULL_VECTOR, NULL_VECTOR);
	SetEntityModel(iEnt, "models/items/car_battery01.mdl");
	
	// Have the mins always be negative
	fMins[0] = fMins[0] - fMiddle[0];
	if(fMins[0] > 0.0)
		fMins[0] *= -1.0;
	fMins[1] = fMins[1] - fMiddle[1];
	if(fMins[1] > 0.0)
		fMins[1] *= -1.0;
	fMins[2] = fMins[2] - fMiddle[2];
	if(fMins[2] > 0.0)
		fMins[2] *= -1.0;
	
	// And the maxs always be positive
	fMaxs[0] = fMaxs[0] - fMiddle[0];
	if(fMaxs[0] < 0.0)
		fMaxs[0] *= -1.0;
	fMaxs[1] = fMaxs[1] - fMiddle[1];
	if(fMaxs[1] < 0.0)
		fMaxs[1] *= -1.0;
	fMaxs[2] = fMaxs[2] - fMiddle[2];
	if(fMaxs[2] < 0.0)
		fMaxs[2] *= -1.0;
	
	SetEntPropVector(iEnt, Prop_Send, "m_vecMins", fMins);
	SetEntPropVector(iEnt, Prop_Send, "m_vecMaxs", fMaxs);
	SetEntProp(iEnt, Prop_Send, "m_nSolidType", 2);
	
	new iEffects = GetEntProp(iEnt, Prop_Send, "m_fEffects");
	iEffects |= 32;
	SetEntProp(iEnt, Prop_Send, "m_fEffects", iEffects);
	
	AcceptEntityInput(iEnt, "SetActive");
}

KillNoBuildEntity(iZoneIndex)
{
	decl String:sZoneName[128];
	Format(sZoneName, sizeof(sZoneName), "sm_nobuild_%d", iZoneIndex);
	
	new iEnts = GetMaxEntities();
	decl String:sClassName[256];
	for(new i=MaxClients+1;i<iEnts;i++)
	{
		if(IsValidEntity(i)
		&& IsValidEdict(i)
		&& GetEdictClassname(i, sClassName, sizeof(sClassName))
		&& StrContains(sClassName, "func_nobuild") != -1
		&& GetEntPropString(i, Prop_Data, "m_iName", sClassName, sizeof(sClassName))
		&& StrEqual(sClassName, sZoneName, false))
		{
			AcceptEntityInput(i, "Kill");
			break;
		}
	}
}

ApplyNewBoundsToZone(iZoneIndex)
{
	decl String:sZoneName[128];
	new Float:fMiddle[3], Float:fMins[3], Float:fMaxs[3];
	
	new Handle:hZone = GetArrayCell(g_hZones, iZoneIndex);
	GetArrayArray(hZone, 0, fMins, 3);
	GetArrayArray(hZone, 1, fMaxs, 3);
	
	GetMiddleOfABox(fMins, fMaxs, fMiddle);
	
	// Have the mins always be negative
	fMins[0] = fMins[0] - fMiddle[0];
	if(fMins[0] > 0.0)
		fMins[0] *= -1.0;
	fMins[1] = fMins[1] - fMiddle[1];
	if(fMins[1] > 0.0)
		fMins[1] *= -1.0;
	fMins[2] = fMins[2] - fMiddle[2];
	if(fMins[2] > 0.0)
		fMins[2] *= -1.0;
	
	// And the maxs always be positive
	fMaxs[0] = fMaxs[0] - fMiddle[0];
	if(fMaxs[0] < 0.0)
		fMaxs[0] *= -1.0;
	fMaxs[1] = fMaxs[1] - fMiddle[1];
	if(fMaxs[1] < 0.0)
		fMaxs[1] *= -1.0;
	fMaxs[2] = fMaxs[2] - fMiddle[2];
	if(fMaxs[2] < 0.0)
		fMaxs[2] *= -1.0;
	
	Format(sZoneName, sizeof(sZoneName), "sm_nobuild_%d", iZoneIndex);
	
	new iEnts = GetMaxEntities();
	decl String:sClassName[256];
	for(new i=MaxClients+1;i<iEnts;i++)
	{
		if(IsValidEntity(i)
		&& IsValidEdict(i)
		&& GetEdictClassname(i, sClassName, sizeof(sClassName))
		&& StrContains(sClassName, "func_nobuild") != -1
		&& GetEntPropString(i, Prop_Data, "m_iName", sClassName, sizeof(sClassName))
		&& StrEqual(sClassName, sZoneName, false))
		{
			// Set the new bounds
			SetEntPropVector(i, Prop_Send, "m_vecMins", fMins);
			SetEntPropVector(i, Prop_Send, "m_vecMaxs", fMaxs);
			break;
		}
	}
}

/**
 * Sets up a boxed beam effect.
 * 
 * Ported from eventscripts vecmath library
 *
 * @param client		The client to show the box to.
 * @param uppercorner	One upper corner of the box.
 * @param bottomcorner	One bottom corner of the box.
 * @param ModelIndex	Precached model index.
 * @param HaloIndex		Precached model index.
 * @param StartFrame	Initital frame to render.
 * @param FrameRate		Beam frame rate.
 * @param Life			Time duration of the beam.
 * @param Width			Initial beam width.
 * @param EndWidth		Final beam width.
 * @param FadeLength	Beam fade time duration.
 * @param Amplitude		Beam amplitude.
 * @param color			Color array (r, g, b, a).
 * @param Speed			Speed of the beam.
 * @noreturn
 */
stock TE_SendBeamBoxToClient(client, const Float:uppercorner[3], const Float:bottomcorner[3], ModelIndex, HaloIndex, StartFrame, FrameRate, Float:Life, Float:Width, Float:EndWidth, FadeLength, Float:Amplitude, const Color[4], Speed)
{
	// Create the additional corners of the box
	new Float:tc1[3];
	AddVectors(tc1, uppercorner, tc1);
	tc1[0] = bottomcorner[0];
	new Float:tc2[3];
	AddVectors(tc2, uppercorner, tc2);
	tc2[1] = bottomcorner[1];
	new Float:tc3[3];
	AddVectors(tc3, uppercorner, tc3);
	tc3[2] = bottomcorner[2];
	new Float:tc4[3];
	AddVectors(tc4, bottomcorner, tc4);
	tc4[0] = uppercorner[0];
	new Float:tc5[3];
	AddVectors(tc5, bottomcorner, tc5);
	tc5[1] = uppercorner[1];
	new Float:tc6[3];
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