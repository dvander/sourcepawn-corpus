/* Door-Spawner by HyperKiLLeR */

#include <sourcemod>
#include <sdktools> 
#include "dbi.inc"
#include "menus.inc"

#define PLUGIN_VERSION	"1.4.1 (fixed by Grey83)"

new Handle:g_DoorMenu = INVALID_HANDLE

new g_BeamSprite;
new g_HaloSprite;

new greenColor[4]	= {75, 255, 75, 255};

public Plugin:myinfo = 
{
	name		= "Doorspawner",
	author		= "HyperKiLLeR",
	description	= "Spawns a door",
	version		= PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=114465"
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");

	decl String:GameDir[255];
	GetGameFolderName(GameDir, sizeof(GameDir));
	if(StrContains(GameDir, "left4dead", false) != -1)
		RegAdminCmd("sm_spawndoor", Command_DoorMenu, ADMFLAG_SLAY,"Spawns a door");
	else
		RegAdminCmd("sm_spawndoor", Command_Spawndoor, ADMFLAG_SLAY,"Spawns a door");
	RegAdminCmd("sm_lock", Command_LockDoor, ADMFLAG_SLAY,"Lock a door");
	RegAdminCmd("sm_unlock", Command_UnlockDoor, ADMFLAG_SLAY,"Unlock a door");
	RegAdminCmd("sm_removedoor", RemoveDoor, ADMFLAG_SLAY,"Remove a door");
	CreateConVar("spawndoor_version", PLUGIN_VERSION, "Dr. HyperKiLLeRs Doorspawner",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
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

	AddMenuItem(menu, "0", "Wooden Door");
	AddMenuItem(menu, "1", "Saferoom Door");
	AddMenuItem(menu, "2", "Metal Door");
	AddMenuItem(menu, "3", "Metal Door with window");

	SetMenuPagination(menu, MENU_NO_PAGINATION);
	SetMenuExitButton(menu, true);

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
		new item = StringToInt(info);

		switch(item)
		{
			case 0: SpawnDoor(param1, "models/props_doors/doormainmetal01.mdl", "Metaldoor", "metaldoor");
			case 1: SpawnDoor(param1, "models/props_doors/checkpoint_door_01.mdl", "Saferoom-Door", "saferoom-door");
			case 2: SpawnDoor(param1, "models/props_doors/doormain_rural01.mdl", "Wooden Door", "wooden door");
			case 3: SpawnDoor(param1, "models/props_doors/doormainmetalwindow01.mdl", "Metaldoor with Window", "metaldoor with window");
		}
		return true;
	}
	return true;
}


public Action:Command_DoorMenu(client, args)
{
	if (0 < client || client > MaxClients)  ReplyToCommand(client, "[SM] %t", "Command is in-game only");
	else DisplayMenu(g_DoorMenu, client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public Action:Command_LockDoor(client, args)
{
	if (0 < client || client > MaxClients)  ReplyToCommand(client, "[SM] %t", "Command is in-game only");
	else
	{
		new Ent = GetClientAimTarget(client, false);
	
		if (Ent >MaxClients)
		{
			AcceptEntityInput(Ent, "lock", -1);
			PrintToChat(client, "\x04You locked the door!");
		}
	}

	return Plugin_Handled;
}

public Action:RemoveDoor(client, args)
{
	if (0 < client || client > MaxClients)  ReplyToCommand(client, "[SM] %t", "Command is in-game only");
	else
	{
		new Ent = GetClientAimTarget(client, false);
	
		if (Ent >MaxClients)
		{
			decl String:ClassName[255];
	
			GetEdictClassname(Ent, ClassName, 255);
			if(StrEqual(ClassName, "prop_door_rotating"))
			{
				AcceptEntityInput(Ent, "Kill", client);
				PrintToChat(client, "\x04You removed the door!");
			}
		}
	}

	return Plugin_Handled;
}

public Action:Command_UnlockDoor(client, args)
{
	if (0 < client || client > MaxClients)  ReplyToCommand(client, "[SM] %t", "Command is in-game only");
	else
	{
		new Ent = GetClientAimTarget(client, false);
	
		if (Ent >MaxClients)
		{
			AcceptEntityInput(Ent, "unlock", -1);
			PrintToChat(client, "You unlocked the door!");
		}
	}

	return Plugin_Handled;
}

//Door-Command for Hl2-Based Games

public Action:Command_Spawndoor(client, args)
{
	if (!client || client > MaxClients)  ReplyToCommand(client, "[SM] %t", "Command is in-game only");
	else
	{
//		DispatchKeyValue(Door, "model", "models/props_doors/doormainmetal01.mdl");

		SpawnDoor(client, "models/props_c17/door01_left.mdl", "door", "door");
	}

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

SpawnDoor(client, String:sModel[], String:sChatDoor[], String:sLogDoor[])
{
	//Declare:
	decl Door;
	new Float:AbsAngles[3], Float:clientOrigin[3], Float:EyeAngles[3], Float:Origin[3], Float:pos[3], Float:beampos[3], Float:FurnitureOrigin[3];
	decl String:Name[255], String:SteamId[255];

	//Initialize:
	GetClientAbsOrigin(client, clientOrigin);
	GetClientEyeAngles(client, EyeAngles);
	GetClientAbsAngles(client, AbsAngles);

	GetCollisionPoint(client, pos);

	FurnitureOrigin[0] = pos[0];
	FurnitureOrigin[1] = pos[1];
	FurnitureOrigin[2] = (pos[2] + 50);

	beampos[0] = pos[0];
	beampos[1] = pos[1];
	beampos[2] = (FurnitureOrigin[2] + 20);

	//Spawn door:
	Door = CreateEntityByName("prop_door_rotating");
	TeleportEntity(Door, FurnitureOrigin, AbsAngles, NULL_VECTOR);

	DispatchKeyValue(Door, "model", sModel);
	DispatchKeyValue(Door, "hardware","1");
	DispatchKeyValue(Door, "distance","90");
	DispatchKeyValue(Door, "speed","100");
	DispatchKeyValue(Door, "returndelay","-1");
	DispatchKeyValue(Door, "spawnflags","8192");
	DispatchKeyValue(Door, "axis", "131.565 1302.86 2569, 131.565 1302.86 2569");
	DispatchSpawn(Door);
	ActivateEntity(Door);
	PrintToChat(client, "\x01You spawned a \x04%s!", sChatDoor);

	//Log
	GetClientAuthString(client, SteamId, 255);
	GetClientName(client, Name, 255);
	LogAction(client, client, "client %s <%s> spawned a %s!", SteamId, Name, sLogDoor);
	PrintToServer("client %s <%s> spawned a %s!", SteamId, Name, sLogDoor);

	//Send BeamRingPoint:
	GetEntPropVector(Door, Prop_Data, "m_vecOrigin", Origin);
	TE_SetupBeamRingPoint(FurnitureOrigin, 10.0, 150.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, greenColor, 20, 0);
	TE_SendToAll();
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > MaxClients;
}