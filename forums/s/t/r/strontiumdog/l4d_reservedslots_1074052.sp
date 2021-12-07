//Ville Reserved Slots
//
//Written by <eVa>Dog
//October 2008

#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_VERSION "1.0.110-L4D"

new Handle:g_Cvar_Slots = INVALID_HANDLE
new Handle:g_Cvar_AutoClose = INVALID_HANDLE
new Handle:hAdminMenu = INVALID_HANDLE
new Handle:sm_reserve_kicktype

	// Kick_HighestPing 0
	// Kick_HighestTime 1
	// Kick_Random 2
	// Kick_LowestTime 3

new String:kicktype[4][16]


public Plugin:myinfo = 
{
	name = "Ville Reserved Slots",
	author = "<eVa>Dog",
	description = "Slots for Supporters and Admins at TheVille.Org",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org/"
}

//Gold and Silver Supporters have ADM_RESERVATION
//Bronze have ADM_CUSTOM1 meaning they cannot open a slot but have immunity from being selected to kick

/* Maximum number of clients that can connect to server */
new g_MaxClients

public OnPluginStart()
{
	CreateConVar("ville_reservedslots", PLUGIN_VERSION, "Version of Ville Reserved Slots", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	g_Cvar_Slots = CreateConVar("reservedslot", "0", " enabling this opens a reserved slot", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	g_Cvar_AutoClose = CreateConVar("sm_reservedslot_time", "40.0", " length of time before slot auto closes", FCVAR_PLUGIN)

	HookConVarChange(g_Cvar_Slots, OpenCloseSlot)
	
	sm_reserve_kicktype = CreateConVar("sm_reserve_kicktype", "3", "How to select a client to kick (if appropriate)", 0, true, 0.0, true, 2.0);
	
	new Handle:topmenu
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu)
	}
	
	kicktype[0] = "Highest Ping"
	kicktype[1] = "Highest Time"
	kicktype[2] = "Random"
	kicktype[3] = "Lowest Time"
}

public OnMapStart()
{
	new String:g_MapName[64]
	GetCurrentMap(g_MapName, sizeof(g_MapName))
	if (StrContains(g_MapName, "_vs_") != -1)
	{
		g_MaxClients = 8
	}
	else 
	{
		g_MaxClients = 4
	}
	PrintToServer("Reserved Slot Plugin initialized: Max Clients: %i", g_MaxClients)
}

public OnClientPostAdminCheck(client)
{
	if (GetConVarInt(g_Cvar_Slots) == 1 && GetClientCount(false) == g_MaxClients)
	{
		new String:authid[64]
		GetClientAuthString(client, authid, sizeof(authid))
		new AdminId:admin = FindAdminByIdentity(AUTHMETHOD_STEAM, authid)
		
		if (!GetAdminFlag(admin, Admin_Reservation))
		{
				KickClient(client, "Slot reserved")
		}
	}
}

public OpenCloseSlot(Handle:convar, const String:oldValue[], const String:newValue[])
{
    if (StringToInt(newValue) > 0)
    {
		new target = SelectKickClient()
						
		if ((target) && GetClientCount(false) == g_MaxClients)
		{
			KickClient(target, "Slot reserved")
			PrintToServer("Slot opened")
			CreateTimer(GetConVarFloat(g_Cvar_AutoClose), CloseSlot, 0)
		}
		else
		{
			PrintToServer("Cannot open slot - not max clients (%i)", g_MaxClients)
			ServerCommand("reservedslot 0")
		}
    }
}

public Action:CloseSlot(Handle:timer, any:client)
{
	ServerCommand("reservedslot 0")
	PrintToServer("Slot closed")
}

SelectKickClient()
{
	new type = GetConVarInt(sm_reserve_kicktype)
	
	new Float:bestValue
	new bestValueId
	
	new Float:highestSpecValue
	new highestSpecValueId
	
	new bool:specFound
	
	new Float:value
	
	PrintToServer("Kick Method: %s", kicktype[type])
	
	if (type <= 2)
	{
		for (new i=1; i<=g_MaxClients; i++)
		{	
			if (!IsClientConnected(i))
			{
				continue
			}
		
			new flags = GetUserFlagBits(i)
			
			if (flags & ADMFLAG_ROOT || flags & ADMFLAG_RESERVATION || flags & ADMFLAG_CUSTOM1)
			{
				continue
			}
				
			if (IsClientInGame(i))
			{
				if (IsFakeClient(i))
				{
					bestValueId = i
					return bestValueId
				}
				
				if (type == 0)
				{
					value = GetClientAvgLatency(i, NetFlow_Outgoing)
				}
				else if (type == 1)
				{
					value = GetClientTime(i)
				}
				else 
				{
					value = GetRandomFloat(0.0, 100.0)
				}

				if (IsClientObserver(i))
				{			
					specFound = true
					
					if (value > highestSpecValue)
					{
						highestSpecValue = value
						highestSpecValueId = i
					}
				}
			}
			
			if (value >= bestValue)
			{
				bestValue = value
				bestValueId = i
			}
		}
		
		if (specFound)
		{
			PrintToServer("Spectator Kicked: %i", highestSpecValueId)
			return highestSpecValueId
		}
	}
	else
	{
		// Find the longest time on the server
		new Float:mosttime, Float:playertime
		for (new i=1; i<=g_MaxClients; i++)
		{	
			if (!IsClientConnected(i) || IsFakeClient(i))
			{
				continue
			}
			
			if (IsClientInGame(i))
			{
				playertime = GetClientTime(i)
			}
			
			if (playertime >= mosttime)
			{
				mosttime = playertime
			}
		}
		
		bestValue = mosttime
		
		for (new i=1; i<=g_MaxClients; i++)
		{	
			if (!IsClientConnected(i))
			{
				continue
			}
		
			new flags = GetUserFlagBits(i)
			
			if (flags & ADMFLAG_ROOT || flags & ADMFLAG_RESERVATION || flags & ADMFLAG_CUSTOM1)
			{
				continue
			}
							
			if (IsClientInGame(i))
			{
				if (IsFakeClient(i))
				{
					bestValueId = i
					return bestValueId
				}
				
				value = GetClientTime(i)
			
				if (IsClientObserver(i))
				{			
					specFound = true
					
					if (value > highestSpecValue)
					{
						highestSpecValue = value
						highestSpecValueId = i
					}
				}
			}
			
			if (value <= bestValue)
			{
				bestValue = value
				bestValueId = i
			}
		}
		
		if (specFound)
		{
			PrintToServer("Spectator Kicked: %i", highestSpecValueId)
			return highestSpecValueId
		}
	}
	PrintToServer("Client Kicked: %i", bestValueId)
	return bestValueId
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu")) 
	{
		hAdminMenu = INVALID_HANDLE;
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == hAdminMenu)
	{
		return;
	}
	
	hAdminMenu = topmenu

	new TopMenuObject:player_commands = FindTopMenuCategory(hAdminMenu, ADMINMENU_SERVERCOMMANDS)

	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hAdminMenu,
			"reservedslot",
			TopMenuObject_Item,
			AdminMenu_OpenCloseReservedSlot,
			player_commands,
			"reservedslot",
			ADMFLAG_KICK)
	}
}
 
public AdminMenu_OpenCloseReservedSlot(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		if (GetConVarInt(g_Cvar_Slots) == 0) 
		{
			Format(buffer, maxlength, "Open Reserved Slot")
		}
		else 
		{
			Format(buffer, maxlength, "Close Reserved Slot")
		}
	}
	else if (action == TopMenuAction_SelectOption)
	{
		if (GetConVarInt(g_Cvar_Slots) == 0)
		{
			if (GetClientCount(false) == g_MaxClients)
			{
				ServerCommand("reservedslot 1")
			}
			else
			{
				PrintToChat(param, "[SM] Cannot open slot - server not full")
			}
		}
		else 
		{
			ServerCommand("reservedslot 0")
		}			
	}
}

