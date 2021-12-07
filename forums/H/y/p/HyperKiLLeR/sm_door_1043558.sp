/* Door-Spawner by HyperKiLLeR */

#include <sourcemod>
#include <sdktools> 
#include "dbi.inc"
#include "menus.inc"

new Handle:g_DoorMenu = INVALID_HANDLE

new g_BeamSprite;
new g_HaloSprite;

new greenColor[4]	= {75, 255, 75, 255};

public Plugin:myinfo = 
{
	name = "Doorspawner",
	author = "HyperKiLLeR",
	description = "Spawns a door",
	version = "1.4.1",
	url = ""
}

public OnPluginStart()
{
	decl String:GameDir[255];
	GetGameFolderName(GameDir, sizeof(GameDir));
	if(StrContains(GameDir, "left4dead", false) != -1)
	{
		RegAdminCmd("sm_spawndoor", Command_DoorMenu, ADMFLAG_SLAY,"Spawns a door");
	} else {
		RegAdminCmd("sm_spawndoor", Command_Spawndoor, ADMFLAG_SLAY,"Spawns a door");
	}
	RegAdminCmd("sm_lock", Command_LockDoor, ADMFLAG_SLAY,"Lock a door");
	RegAdminCmd("sm_unlock", Command_UnlockDoor, ADMFLAG_SLAY,"Unlock a door");
	RegAdminCmd("sm_removedoor", RemoveDoor, ADMFLAG_SLAY,"Remove a door");
	CreateConVar("spawndoor_version", "1.4.1", "Dr. HyperKiLLeRs Doorspawner",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
}

//Map Start:
public OnMapStart()
{
	g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");	
	g_DoorMenu = BuildDoorMenu();
}

public OnMapEnd()
{
	if (g_DoorMenu != INVALID_HANDLE)
	{
		CloseHandle(g_DoorMenu);
		g_DoorMenu = INVALID_HANDLE;
	}
}

//Door-Menu for L4D/L4D2
Handle:BuildDoorMenu()
{
	
	
	/* Create the menu Handle */
	new Handle:menu = CreateMenu(Menu_SpawnDoor);
	
	
	AddMenuItem(menu, "wood", "Wooden Door");
	AddMenuItem(menu, "safe", "Saferoom Door");
	AddMenuItem(menu, "metal", "Metal Door");
	AddMenuItem(menu, "windowmtl", "Metal Door with window");
	
	
	/* Finally, set the title */
	SetMenuTitle(menu, "Select a Door to spawn:");
	
	return menu;
}

public Menu_SpawnDoor(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		
		GetMenuItem(menu, param2, info, sizeof(info));
		
		//Declare:
		decl Door;
		new Float:AbsAngles[3], Float:ClientOrigin[3], Float:pos[3], Float:beampos[3], Float:FurnitureOrigin[3], Float:EyeAngles[3];
		decl String:Name[255], String:SteamId[255];
		
		//Initialize:
		
		GetClientAbsOrigin(param1, ClientOrigin);
		GetClientEyeAngles(param1, EyeAngles);
		GetClientAbsAngles(param1, AbsAngles);
		
		
		
		GetCollisionPoint(param1, pos);
		
		FurnitureOrigin[0] = pos[0];
		FurnitureOrigin[1] = pos[1];
		FurnitureOrigin[2] = (pos[2] + 50);
		
		beampos[0] = pos[0];
		beampos[1] = pos[1];
		beampos[2] = (FurnitureOrigin[2] + 20);
		
		//Spawn door:
		Door = CreateEntityByName("prop_door_rotating");
		TeleportEntity(Door, FurnitureOrigin, AbsAngles, NULL_VECTOR);
		
		if(StrContains(info, "metal", false) != -1)
		{
			DispatchKeyValue(Door, "model", "models/props_doors/doormainmetal01.mdl");
			
			
			DispatchKeyValue(Door, "hardware","1");
			DispatchKeyValue(Door, "distance","90");
			DispatchKeyValue(Door, "speed","100");
			DispatchKeyValue(Door, "returndelay","-1");
			DispatchKeyValue(Door, "spawnflags","8192");
			DispatchKeyValue(Door, "axis", "131.565 1302.86 2569, 131.565 1302.86 2569");
			DispatchSpawn(Door);
			ActivateEntity(Door);
			
			PrintToChat(param1, "\x01You spawned a \x04Metaldoor!");
			
			//Log
			GetClientAuthString(param1, SteamId, 255);
			GetClientName(param1, Name, 255);
			LogAction(param1, param1, "Client %s <%s> spawned a metaldoor!", SteamId, Name);
			PrintToServer("Client %s <%s> spawned a metaldoor!", SteamId, Name);
		}
		if(StrContains(info, "safe", false) != -1)
		{
			DispatchKeyValue(Door, "model", "models/props_doors/checkpoint_door_01.mdl");
			
			
			DispatchKeyValue(Door, "hardware","1");
			DispatchKeyValue(Door, "distance","90");
			DispatchKeyValue(Door, "speed","100");
			DispatchKeyValue(Door, "returndelay","-1");
			DispatchKeyValue(Door, "spawnflags","8192");
			DispatchKeyValue(Door, "axis", "131.565 1302.86 2569, 131.565 1302.86 2569");
			DispatchSpawn(Door);
			ActivateEntity(Door);
			
			PrintToChat(param1, "\x01You spawned a \x04Saferoom-Door!");
			
			//Log
			GetClientAuthString(param1, SteamId, 255);
			GetClientName(param1, Name, 255);
			LogAction(param1, param1, "Client %s <%s> spawned a saferoom-door!", SteamId, Name);
			PrintToServer("Client %s <%s> spawned a saferoom-door!", SteamId, Name);
		}
		if(StrContains(info, "wood", false) != -1)
		{
			DispatchKeyValue(Door, "model", "models/props_doors/doormain_rural01.mdl");
			
			
			DispatchKeyValue(Door, "hardware","1");
			DispatchKeyValue(Door, "distance","90");
			DispatchKeyValue(Door, "speed","100");
			DispatchKeyValue(Door, "returndelay","-1");
			DispatchKeyValue(Door, "spawnflags","8192");
			DispatchKeyValue(Door, "axis", "131.565 1302.86 2569, 131.565 1302.86 2569");
			DispatchSpawn(Door);
			ActivateEntity(Door);
			
			PrintToChat(param1, "\x01You spawned a \x04Wooden Door!");
			
			//Log
			GetClientAuthString(param1, SteamId, 255);
			GetClientName(param1, Name, 255);
			LogAction(param1, param1, "Client %s <%s> spawned a wooden door!", SteamId, Name);
			PrintToServer("Client %s <%s> spawned a wooden door!", SteamId, Name);
		}
		if(StrContains(info, "window", false) != -1)
		{
			DispatchKeyValue(Door, "model", "models/props_doors/doormainmetalwindow01.mdl");
			
			
			DispatchKeyValue(Door, "hardware","1");
			DispatchKeyValue(Door, "distance","90");
			DispatchKeyValue(Door, "speed","100");
			DispatchKeyValue(Door, "returndelay","-1");
			DispatchKeyValue(Door, "spawnflags","8192");
			DispatchKeyValue(Door, "axis", "131.565 1302.86 2569, 131.565 1302.86 2569");
			DispatchSpawn(Door);
			ActivateEntity(Door);
			
			PrintToChat(param1, "\x01You spawned a \x04Metal-Door with Window!");
			
			//Log
			GetClientAuthString(param1, SteamId, 255);
			GetClientName(param1, Name, 255);
			LogAction(param1, param1, "Client %s <%s> spawned a Metal-Door with Window!", SteamId, Name);
			PrintToServer("Client %s <%s> spawned a Metal-Door with Window!", SteamId, Name);
		}
		return true;
	}
	return true;
}


public Action:Command_DoorMenu(client, args)
{
	
	DisplayMenu(g_DoorMenu, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public Action:Command_LockDoor(client, args)
{
	
	decl Ent;
	Ent = GetClientAimTarget(client, false);
	
	AcceptEntityInput(Ent, "lock", -1);
	PrintToChat(client, "\x04You locked the door!");
	
	return Plugin_Handled;
}

public Action:RemoveDoor(client, args)
{
	
	decl Ent;
	decl String:ClassName[255];
	Ent = GetClientAimTarget(client, false);
	
	GetEdictClassname(Ent, ClassName, 255);
	if(StrEqual(ClassName, "prop_door_rotating"))
	{
		AcceptEntityInput(Ent, "Kill", client);
		PrintToChat(client, "\x04You removed the door!");
	}
	return Plugin_Handled;
}

public Action:Command_UnlockDoor(client, args)
{
	
	decl Ent;
	Ent = GetClientAimTarget(client, false);
	
	AcceptEntityInput(Ent, "unlock", -1);
	PrintToChat(client, "You unlocked the door!");
	
	return Plugin_Handled;
}

//Door-Command for Hl2-Based Games

public Action:Command_Spawndoor(Client, args)
{
	//Declare:
	decl Door;
	new Float:AbsAngles[3], Float:ClientOrigin[3], Float:Origin[3], Float:pos[3], Float:beampos[3], Float:FurnitureOrigin[3], Float:EyeAngles[3];
	decl String:Name[255], String:SteamId[255];
	//Initialize:
	
	GetClientAbsOrigin(Client, ClientOrigin);
	GetClientEyeAngles(Client, EyeAngles);
	GetClientAbsAngles(Client, AbsAngles);
	
	
	
	GetCollisionPoint(Client, pos);
	
	FurnitureOrigin[0] = pos[0];
	FurnitureOrigin[1] = pos[1];
	FurnitureOrigin[2] = (pos[2] + 50);
	
	beampos[0] = pos[0];
	beampos[1] = pos[1];
	beampos[2] = (FurnitureOrigin[2] + 20);
	
	//Spawn door:
	Door = CreateEntityByName("prop_door_rotating");
	TeleportEntity(Door, FurnitureOrigin, AbsAngles, NULL_VECTOR);
	
	
	
	DispatchKeyValue(Door, "model", "models/props_doors/doormainmetal01.mdl");
	
	DispatchKeyValue(Door, "model", "models/props_c17/door01_left.mdl");
	
	
	DispatchKeyValue(Door, "hardware","1");
	DispatchKeyValue(Door, "distance","90");
	DispatchKeyValue(Door, "speed","100");
	DispatchKeyValue(Door, "returndelay","-1");
	DispatchKeyValue(Door, "spawnflags","8192");
	DispatchKeyValue(Door, "axis", "131.565 1302.86 2569, 131.565 1302.86 2569");
	DispatchSpawn(Door);
	ActivateEntity(Door);
	
	PrintToChat(Client, "\x01You spawned a \x04door!");
	
	//Log
	GetClientAuthString(Client, SteamId, 255);
	GetClientName(Client, Name, 255);
	LogAction(Client, Client, "Client %s <%s> spawned a door!", SteamId, Name);
	PrintToServer("Client %s <%s> spawned a door!", SteamId, Name);
	
	//Send BeamRingPoint:
	GetEntPropVector(Door, Prop_Data, "m_vecOrigin", Origin);
	TE_SetupBeamRingPoint(FurnitureOrigin, 10.0, 150.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, greenColor, 20, 0);
	TE_SendToAll();
	
	return Plugin_Handled;
}

stock GetCollisionPoint(client, Float:pos[3])
{
	decl Float:vOrigin[3], Float:vAngles[3];
	
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer);
	
	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(pos, trace);
		CloseHandle(trace);
		
		return;
	}
	
	CloseHandle(trace);
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > MaxClients;
}