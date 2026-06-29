/*

	Version history
	---------------
	1.05	- Added auto-detection of the ZombieMod addon with help of a cvar (removed NAME_COUNTERS & NAME_TERRORS therefore)
	1.04	- Fixed bug were AdminId wasn't set while finding a free slot
	1.03	- Replaced MAX_PLAYERS with GetMaxClients() because the server-side upper client index were out of bounds and caused an error
	1.02	- Minor code optimization
	1.01	- Fixed bug where the three loops for #all, #ct, #t where limited to MAX_SLOTS instead of MAX_PLAYERS
	1.0		- Initial release	

*/

// Includes
#include <sourcemod>
#include <sdktools>

// Plugin definitions
#define PLUGIN_NAME					"i3D-Teleport"
#define PLUGIN_AUTHOR				"Tony G."
#define PLUGIN_DESCRIPTION	"Simple SourceMod replacement for the Mani teleport functionality."
#define PLUGIN_VERSION			"1.05"
#define PLUGIN_URL					"http://www.i3d.net/"

// Chat settings
#define	CHAT_PREFIX		"[i3D-Teleport]: "

// Log settings (comment this to disable logging)
#define LOG_ENABLED

// Hardcoded limit (don't touch)
#define MAX_SLOTS			16

// Globals
new String:CountersTeamName[] = "counter-terrorists";
new String:TerrorsTeamName[] = "terrorists";
new AdminId:AdminSlots[MAX_SLOTS];
new Float:PositionSlots[MAX_SLOTS][3];

public Plugin:myinfo = {name = PLUGIN_NAME, author = PLUGIN_AUTHOR, description = PLUGIN_DESCRIPTION, version = PLUGIN_VERSION, url = PLUGIN_URL};

public OnPluginStart()
{

	LoadTranslations("common.phrases");
	
	RegAdminCmd("sm_saveloc", SaveLocation, ADMFLAG_KICK, "Saves the current location for teleport commands.");
	RegAdminCmd("sm_teleport", TeleportToLocation, ADMFLAG_KICK, "sm_teleport <#id|name>");

	DetectZombieMod();
	ResetSlots();

}

public OnMapStart()
{
	ResetSlots();
}

public DetectZombieMod()
{

	if (FindConVar("zombie_health") != INVALID_HANDLE)
	{
		CountersTeamName = "humans";
		TerrorsTeamName = "zombies";
	}

}

public ResetSlots()
{

	for (new slot = 0; slot < MAX_SLOTS; slot++)
	{
		AdminSlots[slot] = INVALID_ADMIN_ID;
		PositionSlots[slot][0] = 0.0;
		PositionSlots[slot][1] = 0.0;
		PositionSlots[slot][2] = 0.0;
	}

}

public GetSlot(client)
{

	new AdminId:adminid = GetUserAdmin(client);

	for (new slot = 0; slot < MAX_SLOTS; slot++)
	{
		if (AdminSlots[slot] == adminid)
		{
			return slot;
		}
	}

	for (new slot = 0; slot < MAX_SLOTS; slot++)
	{
		if (AdminSlots[slot] == INVALID_ADMIN_ID)
		{
			AdminSlots[slot] = adminid;
			return slot;
		}
	}
	
	return -1;

}

public IsClientTeleportable(client)
{
	return (IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client));
}

public HasSavedPosition(slot)
{
	return (PositionSlots[slot][0] != 0.0 && PositionSlots[slot][1] != 0.0 && PositionSlots[slot][2] != 0.0);
}

public TriggerNoMatchingTarget(client)
{
	PrintToChat(client, "%s%s", CHAT_PREFIX, "Couldn't find any matching target");
}

public Action:SaveLocation(client, args)
{

	new slot = GetSlot(client);
	
	if (slot == -1)
	{
		PrintToChat(client, "%s%s", CHAT_PREFIX, "No free slot found - please report to server admin");
		return Plugin_Handled;
	}

	GetClientAbsOrigin(client, PositionSlots[slot]);
	
	PrintToChat(client, "%s%s", CHAT_PREFIX, "Current position saved");

	return Plugin_Handled;

}

public Action:TeleportToLocation(client, args)
{

	if (args < 1)
	{
		PrintToChat(client, "%s%s", CHAT_PREFIX, "Please define a target first (sm_teleport <#id|name>)");
		return Plugin_Handled;
	}
	
	new slot = GetSlot(client);
	
	if (slot == -1)
	{
		PrintToChat(client, "%s%s", CHAT_PREFIX, "No free slot found - please report to server admin");
		return Plugin_Handled;
	}
	
	if (!HasSavedPosition(slot))
	{
		PrintToChat(client, "%s%s", CHAT_PREFIX, "Please save a location first (sm_saveloc)");
		return Plugin_Handled;
	}

	new String:admin[MAX_NAME_LENGTH];
	GetClientName(client, admin, sizeof(admin));

	new String:arguments[64];
	GetCmdArgString(arguments, sizeof(arguments));
	
	new String:argument[MAX_NAME_LENGTH];
	BreakString(arguments, argument, sizeof(argument));
	
	if (strcmp(argument, "#all") == 0)
	{
	
		new counter = 0;
		new players = GetMaxClients();
	
		for (new i = 1; i <= players; i++)
		{
		
			if (IsClientTeleportable(i))
			{
				TeleportEntity(i, PositionSlots[slot], NULL_VECTOR, NULL_VECTOR);
				counter++;
			}
		
		}

		if (counter == 0)
		{
			TriggerNoMatchingTarget(client);
		}
		else
		{
			
			ShowActivity2(client, CHAT_PREFIX, "%s%s", admin, " teleported all players");
			
			#if defined LOG_ENABLED
				new String:adminauth[21];
				GetClientAuthString(client, adminauth, sizeof(adminauth));
				LogAction(client, -1, "%s%s%s%s%d%s%f%s%f%s%f%s", admin, " (", adminauth, ") teleported all players (count: ", counter, ", location: ", PositionSlots[slot][0], " ", PositionSlots[slot][1], " ", PositionSlots[slot][2], ")");
			#endif
			
		}

	}
	else if (strcmp(argument, "#ct") == 0)
	{
	
		new counter = 0;
		new players = GetMaxClients();
		
		for (new i = 1; i <= players; i++)
		{
		
			if (IsClientTeleportable(i))
			{
				if (GetClientTeam(i) == 3)
				{
					TeleportEntity(i, PositionSlots[slot], NULL_VECTOR, NULL_VECTOR);
					counter++;
				}
			}
		
		}

		if (counter == 0)
		{
			TriggerNoMatchingTarget(client);
		}
		else
		{
		
			ShowActivity2(client, CHAT_PREFIX, "%s%s%s", admin, " teleported all ", CountersTeamName);
		
			#if defined LOG_ENABLED
				new String:adminauth[21];
				GetClientAuthString(client, adminauth, sizeof(adminauth));
				LogAction(client, -1, "%s%s%s%s%d%s%f%s%f%s%f%s", admin, " (", adminauth, ") teleported all ct's (count: ", counter, ", location: ", PositionSlots[slot][0], " ", PositionSlots[slot][1], " ", PositionSlots[slot][2], ")");
			#endif
		
		}
	
	}
	else if (strcmp(argument, "#t") == 0)
	{
	
		new counter = 0;
		new players = GetMaxClients();
		
		for (new i = 1; i <= players; i++)
		{
		
			if (IsClientTeleportable(i))
			{
				if (GetClientTeam(i) == 2)
				{
					TeleportEntity(i, PositionSlots[slot], NULL_VECTOR, NULL_VECTOR);
					counter++;
				}
			}
		
		}
		
		if (counter == 0)
		{
			TriggerNoMatchingTarget(client);
		}
		else
		{
		
			ShowActivity2(client, CHAT_PREFIX, "%s%s%s", admin, " teleported all ", TerrorsTeamName);
			
			#if defined LOG_ENABLED
				new String:adminauth[21];
				GetClientAuthString(client, adminauth, sizeof(adminauth));
				LogAction(client, -1, "%s%s%s%s%d%s%f%s%f%s%f%s", admin, " (", adminauth, ") teleported all t's (count: ", counter, ", location: ", PositionSlots[slot][0], " ", PositionSlots[slot][1], " ", PositionSlots[slot][2], ")");
			#endif
			
		}
	
	}
	else
	{
	
		new target = FindTarget(client, argument);
	
		if (target == -1)
		{
			TriggerNoMatchingTarget(client);
		}
		else
		{
		
			new String:name[MAX_NAME_LENGTH];
			GetClientName(target, name, sizeof(name));
		
			if (IsClientTeleportable(target))
			{
			
				TeleportEntity(target, PositionSlots[slot], NULL_VECTOR, NULL_VECTOR);
				
				if (client == target)
				{
				
					ShowActivity2(client, CHAT_PREFIX, "%s%s", admin, " teleported himself/herself");
					
					#if defined LOG_ENABLED
						new String:adminauth[21];
						GetClientAuthString(client, adminauth, sizeof(adminauth));
						LogAction(client, -1, "%s%s%s%s%f%s%f%s%f%s", admin, " (", adminauth, ") teleported himself/herself (location: ", PositionSlots[slot][0], " ", PositionSlots[slot][1], " ", PositionSlots[slot][2], ")");
					#endif
					
				}
				else
				{
				
					ShowActivity2(client, CHAT_PREFIX, "%s%s%s", admin, " teleported player ", name);
					
					#if defined LOG_ENABLED
						new String:adminauth[21];
						GetClientAuthString(client, adminauth, sizeof(adminauth));
						new String:clientauth[21];
						GetClientAuthString(target, clientauth, sizeof(clientauth));
						LogAction(client, target, "%s%s%s%s%s%s%s%s%f%s%f%s%f%s", admin, " (", adminauth, ") teleported player ", name, " (", clientauth, ") (location: ", PositionSlots[slot][0], " ", PositionSlots[slot][1], " ", PositionSlots[slot][2], ")");
					#endif
					
				}
				
			}
		
		}
	
	}

	return Plugin_Handled;

}