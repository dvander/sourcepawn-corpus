#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

new Float:g_pos[3];

new Handle:g_hMainMenu = INVALID_HANDLE;
new Handle:g_hSentryMenu = INVALID_HANDLE;
new Handle:g_hDispenserMenu = INVALID_HANDLE;
new Handle:g_hTeleporterMenu = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "[TF2] BuildingSpawnerExtreme",
	author = "Pelipoika",
	description = "Now just stop trying to mess with my contraptions!",
	version = "2.1.1",
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	RegAdminCmd("sm_sbuildex", BuildMenuCMD, ADMFLAG_ROOT);
//	RegAdminCmd("sm_pickup", Command_Aim, ADMFLAG_ROOT);
}

public OnConfigsExecuted()
{
	g_hMainMenu = CreateMenu(MenuMainHandler);
	SetMenuTitle(g_hMainMenu, "-- Building Spawner XTREME --");
	AddMenuItem(g_hMainMenu, "1", "Sentries");
	AddMenuItem(g_hMainMenu, "2", "Dispensers");
	AddMenuItem(g_hMainMenu, "3", "Teleporters");

	g_hSentryMenu = CreateMenu(MenuSentryHandler);
	SetMenuTitle(g_hSentryMenu, "-- Sentries --");
	AddMenuItem(g_hSentryMenu, "1", "Sentry Level 1");
	AddMenuItem(g_hSentryMenu, "2", "Sentry Level 2");
	AddMenuItem(g_hSentryMenu, "3", "Sentry Level 3");
	AddMenuItem(g_hSentryMenu, "4", "Mini Sentry Level 1");
	AddMenuItem(g_hSentryMenu, "5", "Mini Sentry Level 2");
	AddMenuItem(g_hSentryMenu, "6", "Mini Sentry Level 3");
	AddMenuItem(g_hSentryMenu, "7", "Disposable Sentry Level 1");
	AddMenuItem(g_hSentryMenu, "8", "Disposable Sentry Level 2");
	AddMenuItem(g_hSentryMenu, "9", "Disposable Sentry Level 3");
	SetMenuExitBackButton(g_hSentryMenu, true); 
	
	g_hDispenserMenu = CreateMenu(MenuDispenserHandler);
	SetMenuTitle(g_hDispenserMenu, "-- Dispensers --");
	AddMenuItem(g_hDispenserMenu, "1", "Dispenser Level 1");
	AddMenuItem(g_hDispenserMenu, "2", "Dispenser Level 2");
	AddMenuItem(g_hDispenserMenu, "3", "Dispenser Level 3");
	SetMenuExitBackButton(g_hDispenserMenu, true); 
	
	g_hTeleporterMenu = CreateMenu(MenuTeleportHandler);
	SetMenuTitle(g_hTeleporterMenu, "-- Teleporters --");
	AddMenuItem(g_hTeleporterMenu, "1", "Teleporter Entrance Level 1");
	AddMenuItem(g_hTeleporterMenu, "2", "Teleporter Entrance Level 2");
	AddMenuItem(g_hTeleporterMenu, "3", "Teleporter Entrance Level 3");
	AddMenuItem(g_hTeleporterMenu, "4", "Teleporter Exit Level 1");
	AddMenuItem(g_hTeleporterMenu, "5", "Teleporter Exit Level 2");
	AddMenuItem(g_hTeleporterMenu, "6", "Teleporter Exit Level 3");
	SetMenuExitBackButton(g_hTeleporterMenu, true); 
}

public MenuMainHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && IsClientInGame(param1))
	{
		switch (param2)
		{
			case 0:	DisplayMenuSafely(g_hSentryMenu, param1);
			case 1: DisplayMenuSafely(g_hDispenserMenu, param1);
			case 2: DisplayMenuSafely(g_hTeleporterMenu, param1);
		}
	}
}

public MenuSentryHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && IsClientInGame(param1))
	{
		new Float:flAng[3];
		GetClientEyeAngles(param1, flAng);
		
		if(!SetTeleportEndPoint(param1))
		{
			PrintToChat(param1, "[SM] Could not find spawn point.");
			return;
		}
	
		g_pos[2] -= 10.0;
		flAng[0] = 0.0;
		
		switch (param2)
		{
			case 0:	SpawnSentry(param1, g_pos, flAng, 1, false);
			case 1: SpawnSentry(param1, g_pos, flAng, 2, false);
			case 2: SpawnSentry(param1, g_pos, flAng, 3, false);
			
			case 3:	SpawnSentry(param1, g_pos, flAng, 1, true);
			case 4: SpawnSentry(param1, g_pos, flAng, 2, true);
			case 5: SpawnSentry(param1, g_pos, flAng, 3, true);
			
			case 6:	SpawnSentry(param1, g_pos, flAng, 1, false, true);
			case 7: SpawnSentry(param1, g_pos, flAng, 2, false, true);
			case 8: SpawnSentry(param1, g_pos, flAng, 3, false, true);
		}
		
		DisplayMenuSafely(g_hSentryMenu, param1);
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
    {
        DisplayMenuSafely(g_hMainMenu, param1);
    }
}

public MenuDispenserHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && IsClientInGame(param1))
	{
		new Float:flAng[3];
		GetClientEyeAngles(param1, flAng);
		
		if(!SetTeleportEndPoint(param1))
		{
			PrintToChat(param1, "[SM] Could not find spawn point.");
			return;
		}
	
		g_pos[2] -= 10.0;
		flAng[0] = 0.0;
		
		switch (param2)
		{
			case 0:	SpawnDispenser(param1, g_pos, flAng, 1);
			case 1: SpawnDispenser(param1, g_pos, flAng, 2);
			case 2: SpawnDispenser(param1, g_pos, flAng, 3);
		}
		
		DisplayMenuSafely(g_hDispenserMenu, param1);
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
    {
        DisplayMenuSafely(g_hMainMenu, param1);
    }
}

public MenuTeleportHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && IsClientInGame(param1))
	{
		new Float:flAng[3];
		GetClientEyeAngles(param1, flAng);
		
		if(!SetTeleportEndPoint(param1))
		{
			PrintToChat(param1, "[SM] Could not find spawn point.");
			return;
		}
	
		g_pos[2] -= 10.0;
		flAng[0] = 0.0;
		
		switch (param2)
		{
			case 0:	SpawnTeleporter(param1, g_pos, flAng, 1, TFObjectMode_Entrance);
			case 1: SpawnTeleporter(param1, g_pos, flAng, 2, TFObjectMode_Entrance);
			case 2: SpawnTeleporter(param1, g_pos, flAng, 3, TFObjectMode_Entrance);
			
			case 3:	SpawnTeleporter(param1, g_pos, flAng, 1, TFObjectMode_Exit);
			case 4: SpawnTeleporter(param1, g_pos, flAng, 2, TFObjectMode_Exit);
			case 5: SpawnTeleporter(param1, g_pos, flAng, 3, TFObjectMode_Exit);
		}
		
		DisplayMenuSafely(g_hTeleporterMenu, param1);
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
    {
        DisplayMenuSafely(g_hMainMenu, param1);
    }
}

public Action:BuildMenuCMD(client, args)
{
	if (client != 0)
		DisplayMenuSafely(g_hMainMenu, client);
}

stock SpawnSentry(builder, Float:Position[3], Float:Angle[3], level, bool:mini=false, bool:disposable=false, bool:carried=false, flags=4)
{
	static const Float:m_vecMinsMini[3] = {-15.0, -15.0, 0.0}, Float:m_vecMaxsMini[3] = {15.0, 15.0, 49.5};
	static const Float:m_vecMinsDisp[3] = {-13.0, -13.0, 0.0}, Float:m_vecMaxsDisp[3] = {13.0, 13.0, 42.9};
	
	new sentry = CreateEntityByName("obj_sentrygun");
	
	if(IsValidEntity(sentry))
	{
		AcceptEntityInput(sentry, "SetBuilder", builder);

		DispatchKeyValueVector(sentry, "origin", Position);
		DispatchKeyValueVector(sentry, "angles", Angle);
		
		if(mini)
		{
			SetEntProp(sentry, Prop_Send, "m_bMiniBuilding", 1);
			SetEntProp(sentry, Prop_Send, "m_iUpgradeLevel", level);
			SetEntProp(sentry, Prop_Send, "m_iHighestUpgradeLevel", level);
			SetEntProp(sentry, Prop_Data, "m_spawnflags", flags);
			SetEntProp(sentry, Prop_Send, "m_bBuilding", 1);
			SetEntProp(sentry, Prop_Send, "m_nSkin", level == 1 ? GetClientTeam(builder) : GetClientTeam(builder) - 2);
			DispatchSpawn(sentry);
			
			SetVariantInt(100);
			AcceptEntityInput(sentry, "SetHealth");
			
			SetEntPropFloat(sentry, Prop_Send, "m_flModelScale", 0.75);
			SetEntPropVector(sentry, Prop_Send, "m_vecMins", m_vecMinsMini);
			SetEntPropVector(sentry, Prop_Send, "m_vecMaxs", m_vecMaxsMini);
		}
		else if(disposable)
		{
			SetEntProp(sentry, Prop_Send, "m_bMiniBuilding", 1);
			SetEntProp(sentry, Prop_Send, "m_bDisposableBuilding", 1);
			SetEntProp(sentry, Prop_Send, "m_iUpgradeLevel", level);
			SetEntProp(sentry, Prop_Send, "m_iHighestUpgradeLevel", level);
			SetEntProp(sentry, Prop_Data, "m_spawnflags", flags);
			SetEntProp(sentry, Prop_Send, "m_bBuilding", 1);
			SetEntProp(sentry, Prop_Send, "m_nSkin", level == 1 ? GetClientTeam(builder) : GetClientTeam(builder) - 2);
			DispatchSpawn(sentry);
			
			SetVariantInt(100);
			AcceptEntityInput(sentry, "SetHealth");
			
			SetEntPropFloat(sentry, Prop_Send, "m_flModelScale", 0.60);
			SetEntPropVector(sentry, Prop_Send, "m_vecMins", m_vecMinsDisp);
			SetEntPropVector(sentry, Prop_Send, "m_vecMaxs", m_vecMaxsDisp);
		}
		else
		{
			SetEntProp(sentry, Prop_Send, "m_iUpgradeLevel", level);
			SetEntProp(sentry, Prop_Send, "m_iHighestUpgradeLevel", level);
			SetEntProp(sentry, Prop_Data, "m_spawnflags", flags);
			SetEntProp(sentry, Prop_Send, "m_bBuilding", 1);
			SetEntProp(sentry, Prop_Send, "m_nSkin", GetClientTeam(builder) - 2);
			DispatchSpawn(sentry);
		}
		
		if(carried)	//Doesnt work... yet.
		{
			/*
			//Change clients build tools properties to match things.
			new buildtool = GetPlayerWeaponSlot(builder, TFWeaponSlot_PDA);
			
			if(IsValidEntity(buildtool))
			{
				SetEntPropEnt(buildtool, Prop_Send, "m_hObjectBeingBuilt", sentry);
				SetEntProp(buildtool, Prop_Send, "m_iBuildState", 2);
				SetEntProp(buildtool, Prop_Send, "m_iState", 2);
				SetEntProp(buildtool, Prop_Send, "m_fEffects", 129);
				SetEntProp(buildtool, Prop_Send, "m_nSequence", 34);
				
				SetEntPropEnt(builder, Prop_Send, "m_hActiveWeapon", buildtool);
				SetEntProp(builder, Prop_Send, "m_hCarriedObject", sentry);
				SetEntProp(builder, Prop_Send, "m_bCarryingObject", 1);
			
				SetEntProp(sentry, Prop_Send, "m_iAmmoShells", 0);
				SetEntProp(sentry, Prop_Send, "m_iAmmoRockets", 0);
				SetEntProp(sentry, Prop_Send, "m_nNewSequenceParity", 5);
				SetEntProp(sentry, Prop_Send, "m_nResetEventsParity", 5);
				SetEntProp(sentry, Prop_Send, "m_usSolidFlags", 4);
				SetEntProp(sentry, Prop_Send, "m_bBuilding", 0);
				SetEntProp(sentry, Prop_Send, "m_bCarried", 1);
				SetEntProp(sentry, Prop_Send, "m_bPlacing", 1);
				SetEntProp(sentry, Prop_Send, "m_iState", 0);	//When building 1, When done 2.
				SetEntProp(sentry, Prop_Send, "m_bCarryDeploy", 0);
			}
			else
			{
				PrintToChat(builder, "Invalid entity");
			}*/
		}
	}
}

stock SpawnDispenser(builder, Float:Position[3], Float:Angle[3], level, flags=4)
{
	new dispenser = CreateEntityByName("obj_dispenser");
	
	if(IsValidEntity(dispenser))
	{
		DispatchKeyValueVector(dispenser, "origin", Position);
		DispatchKeyValueVector(dispenser, "angles", Angle);
		SetEntProp(dispenser, Prop_Send, "m_iHighestUpgradeLevel", level);
		SetEntProp(dispenser, Prop_Data, "m_spawnflags", flags);
		SetEntProp(dispenser, Prop_Send, "m_bBuilding", 1);
		DispatchSpawn(dispenser);

		SetVariantInt(GetClientTeam(builder));
		AcceptEntityInput(dispenser, "SetTeam");
		SetEntProp(dispenser, Prop_Send, "m_nSkin", GetClientTeam(builder) - 2);
		
		ActivateEntity(dispenser);	//fixes screen
		
		AcceptEntityInput(dispenser, "SetBuilder", builder);	//Gotta do dis after activation.
	}
}

stock SpawnTeleporter(builder, Float:Position[3], Float:Angle[3], level, TFObjectMode:mode, flags=4)
{
	new teleporter = CreateEntityByName("obj_teleporter");
	
	if(IsValidEntity(teleporter))
	{
		DispatchKeyValueVector(teleporter, "origin", Position);
		DispatchKeyValueVector(teleporter, "angles", Angle);
		
		SetEntProp(teleporter, Prop_Send, "m_iHighestUpgradeLevel", level);
		SetEntProp(teleporter, Prop_Data, "m_spawnflags", flags);
		SetEntProp(teleporter, Prop_Send, "m_bBuilding", 1);
		SetEntProp(teleporter, Prop_Data, "m_iTeleportType", mode);
		SetEntProp(teleporter, Prop_Send, "m_iObjectMode", mode);
		SetEntProp(teleporter, Prop_Send, "m_nSkin", GetClientTeam(builder) - 2);
		DispatchSpawn(teleporter);
		
		AcceptEntityInput(teleporter, "SetBuilder", builder);
		
		SetVariantInt(GetClientTeam(builder));
		AcceptEntityInput(teleporter, "SetTeam");
	}
}

/*
public Action:Command_Aim(client, args)
{
	new target = GetClientAimTarget(client, false);
	
	//Change clients build tools properties to match things.
	if(IsValidEntity(target))
	{
		new buildtool = GetPlayerWeaponSlot(client, TFWeaponSlot_PDA);
		
		if(IsValidEntity(buildtool))
		{
			SetEntPropEnt(buildtool, Prop_Send, "m_hObjectBeingBuilt", target);
		//	SetEntProp(buildtool, Prop_Send, "m_iState", 2);
			SetEntProp(buildtool, Prop_Send, "m_fEffects", 129);
			SetEntProp(buildtool, Prop_Send, "m_nSequence", 34);
			SetEntProp(buildtool, Prop_Send, "m_iBuildState", 2);
			
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", buildtool);
			SetEntProp(client, Prop_Send, "m_hCarriedObject", target);
			SetEntProp(client, Prop_Send, "m_bCarryingObject", 1);
		
			SetEntProp(target, Prop_Send, "m_iAmmoShells", 0);
			SetEntProp(target, Prop_Send, "m_iAmmoRockets", 0);
			SetEntProp(target, Prop_Send, "m_nNewSequenceParity", 5);
			SetEntProp(target, Prop_Send, "m_nResetEventsParity", 5);
			SetEntProp(target, Prop_Send, "m_usSolidFlags", 4);
			SetEntProp(target, Prop_Send, "m_bBuilding", 0);
			SetEntProp(target, Prop_Send, "m_bCarried", 1);
			SetEntProp(target, Prop_Send, "m_bPlacing", 1);
			SetEntProp(target, Prop_Send, "m_iState", 0);	//When building 1, When done 2.
			SetEntProp(target, Prop_Send, "m_bCarryDeploy", 0);
		
			SetEntProp(target, Prop_Send, "m_bDisposableBuilding", GetEntProp(target, Prop_Send, "m_bDisposableBuilding"));
		//	SetEntProp(target, Prop_Send, "m_biObjectMode", GetEntProp(target, Prop_Send, "m_biObjectMode"));
		//	SetEntProp(target, Prop_Send, "m_vecMins", GetEntProp(target, Prop_Send, "m_vecMins"));
		//	SetEntProp(target, Prop_Send, "m_vecMaxs", GetEntProp(target, Prop_Send, "m_vecMaxs"));
			SetEntProp(target, Prop_Send, "m_iHealth", GetEntProp(target, Prop_Send, "m_iHealth"));
			SetEntProp(target, Prop_Send, "m_iMaxHealth", GetEntProp(target, Prop_Send, "m_iMaxHealth"));
			SetEntProp(target, Prop_Send, "m_uInterpolationFrame", GetEntProp(target, Prop_Send, "m_uInterpolationFrame"));
			SetEntProp(target, Prop_Send, "m_nSequence", GetEntProp(target, Prop_Send, "m_nSequence"));
			SetEntProp(target, Prop_Send, "m_nNewSequenceParity", GetEntProp(target, Prop_Send, "m_nNewSequenceParity"));
			SetEntProp(target, Prop_Send, "m_nResetEventsParity", GetEntProp(target, Prop_Send, "m_nResetEventsParity"));
			SetEntProp(target, Prop_Send, "m_bCarryDeploy", GetEntProp(target, Prop_Send, "m_bCarryDeploy"));
			SetEntProp(target, Prop_Send, "m_bBuilding", GetEntProp(target, Prop_Send, "m_bBuilding"));
			SetEntProp(target, Prop_Send, "m_bPlacing", GetEntProp(target, Prop_Send, "m_bPlacing"));
			SetEntProp(target, Prop_Send, "m_bCarried", GetEntProp(target, Prop_Send, "m_bCarried"));
			SetEntProp(target, Prop_Send, "m_flPercentageConstructed", 0.0);
		}
		else
		{
			PrintToChat(client, "Invalid entity");
		}
	}
	else
	{
		PrintToChat(client, "Invalid target");
	}
	
	return Plugin_Handled;
}*/

stock DisplayMenuSafely(Handle:menu, client)
{
    if(IsValidClient(client))
    {
        if(menu == INVALID_HANDLE)
        {
            PrintToConsole(client, "ERROR: Unable to open Menu.");
        }
        else
        {
            DisplayMenu(menu, client, MENU_TIME_FOREVER);
        }
    }
}

public OnMapEnd()
{
	if(g_hMainMenu != INVALID_HANDLE)
	{
		CloseHandle(g_hMainMenu);
		g_hMainMenu = INVALID_HANDLE;
	}
	if(g_hSentryMenu != INVALID_HANDLE)
	{
		CloseHandle(g_hSentryMenu);
		g_hSentryMenu = INVALID_HANDLE;
	}
	if(g_hDispenserMenu != INVALID_HANDLE)
	{
		CloseHandle(g_hDispenserMenu);
		g_hDispenserMenu = INVALID_HANDLE;
	}
	if(g_hTeleporterMenu != INVALID_HANDLE)
	{
		CloseHandle(g_hTeleporterMenu);
		g_hTeleporterMenu = INVALID_HANDLE;
	}
}

SetTeleportEndPoint(client)
{
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:vBuffer[3];
	decl Float:vStart[3];
	decl Float:Distance;
	
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
    //get endpoint for teleport
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if(TR_DidHit(trace))
	{   	 
   	 	TR_GetEndPosition(vStart, trace);
		GetVectorDistance(vOrigin, vStart, false);
		Distance = -35.0;
   	 	GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		g_pos[0] = vStart[0] + (vBuffer[0]*Distance);
		g_pos[1] = vStart[1] + (vBuffer[1]*Distance);
		g_pos[2] = vStart[2] + (vBuffer[2]*Distance);
	}
	else
	{
		CloseHandle(trace);
		return false;
	}
	
	CloseHandle(trace);
	return true;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > GetMaxClients() || !entity;
}

stock bool:IsValidClient(client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	return IsClientInGame(client);
}