
 /* =============================================================================
 * L4D Reserved Slots Plugin
 * Originally based on SourceMod Reserved Slots Plugin
 * Provides basic reserved slots without a wasted slot
 *
 * SourceMod (C)2004-2008 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 */


#include <sourcemod>
#include <adt_array>

#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_VERSION "1.0.109-L4D"

new Handle:g_Cvar_Slots = INVALID_HANDLE
new Handle:g_Cvar_AutoClose = INVALID_HANDLE
new Handle:hAdminMenu = INVALID_HANDLE
new Handle:sm_reserve_kicktype = INVALID_HANDLE
new Handle:g_lifo = INVALID_HANDLE

new g_lifo_index[MAXPLAYERS+1]

public Plugin:myinfo = 
{
	name = "L4D Reserved Slots",
	author = "<eVa>Dog/AlliedModders LLC",
	description = "Reserved Slots without a wasted slot",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org/"
}

//Players with ADM_RESERVATION can open slots
//Players with ADM_CUSTOM1 cannot open a slot but have immunity from being selected to kick

/* Maximum number of clients that can connect to server */
new g_MaxClients

public OnPluginStart()
{
	CreateConVar("l4d_reservedslots", PLUGIN_VERSION, "Version of L4D Reserved Slots", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	g_Cvar_Slots = CreateConVar("reservedslot", "0", " enabling this opens a reserved slot", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	g_Cvar_AutoClose = CreateConVar("sm_reservedslot_time", "40.0", " length of time before slot auto closes", FCVAR_PLUGIN)
	
	sm_reserve_kicktype = CreateConVar("sm_reserve_kicktype", "3", "How to select a client to kick (if appropriate)", 0, true, 0.0, true, 3.0);
	
	HookConVarChange(g_Cvar_Slots, OpenCloseSlot)	
	
	g_lifo = CreateArray(1, 0)
	
	new Handle:topmenu
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu)
	}
}

public OnPluginEnd()
{
    ClearArray(g_lifo)
    FreeHandle(g_lifo)
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
}

public OnMapEnd()
{
	ClearArray(g_lifo)
}

public OnClientPostAdminCheck(client)
{
	new String:authid[64]
	GetClientAuthString(client, authid, sizeof(authid))
	new AdminId:admin = FindAdminByIdentity(AUTHMETHOD_STEAM, authid)
		
	if (GetConVarInt(g_Cvar_Slots) == 1 && GetClientCount(false) == g_MaxClients)
	{
		if (!GetAdminFlag(admin, Admin_Reservation))
		{
			KickClient(client, "Slot reserved")
		}
	}
	else
	{
		if (!GetAdminFlag(admin, Admin_Reservation))
		{
			g_lifo_index[client] = PushArrayCell(g_lifo, client)
		}
		else
		{
			g_lifo_index[client] = 0
		}
	}
}

public OnClientDisconnect_Post(client)
{
	if (g_lifo_index[client] > 0)
	{
		RemoveFromArray(g_lifo, g_lifo_index[client])
		g_lifo_index[client] = 0
	}
}

public OpenCloseSlot(Handle:convar, const String:oldValue[], const String:newValue[])
{
    if (StringToInt(newValue) > 0)
    {
		new target = SelectKickClient()
						
		if ((target) && GetClientCount(false) >= g_MaxClients)
		{
			KickClient(target, "Slot reserved")
			PrintToServer("Slot opened")
			CreateTimer(GetConVarFloat(g_Cvar_AutoClose), CloseSlot, 0)
		}
		else
		{
			PrintToServer("Cannot open slot - not max clients (%i/%i)", GetClientCount(false), g_MaxClients)
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
		
	new Float:kickValue
	new kickValueId
	
	new Float:highestSpecValue
	new highestSpecValueId
	
	new bool:specFound
	
	new Float:value
		
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
		
		value = 0.0
			
		if (IsClientInGame(i))
		{
			if (type == 1)
			{
				value = GetClientAvgLatency(i, NetFlow_Outgoing)
			}
			else if (type == 2)
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
		
		if (value >= kickValue)
		{
			kickValue = value
			kickValueId = i
		}
	}
	
	if (specFound)
	{
		PrintToServer("Client Number: %i", highestSpecValueId)
		return highestSpecValueId
	}
	
	if (type == 3)
	{
		new number = GetArraySize(g_lifo) -1
		new kickId = GetArrayCell(g_lifo, number)
				
		return kickId
	}
	
	return kickValueId
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
			if (GetClientCount(false) >= g_MaxClients)
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

// From Dubbeh
FreeHandle(Handle:hHandle)
{
    if (hHandle != INVALID_HANDLE)
    {
        CloseHandle (hHandle);
        hHandle = INVALID_HANDLE;
    }
}
