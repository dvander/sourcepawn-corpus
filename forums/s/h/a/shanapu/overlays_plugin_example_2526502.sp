/*
 * Overlays - Example File.
 * by: shanapu
 * https://github.com/shanapu/overlays.inc
 * 
 * Version: 1.1
 * 
 * Copyright (C) 2017 Thomas Schmidt (shanapu)
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http:// www.gnu.org/licenses/>.
 */

//Includes
#include <sourcemod>
#include <sdktools>   //need for adding files to download table

#include <overlays>


//Compiler Options   //Optional, but please keep your code clean!
#pragma semicolon 1
#pragma newdecls required


//use a define or if needed (for cvars) a string
#define OVERLAYPATH "overlays/test"   //Path to the overlay relative to materials/.. - no need for extentions like .vmt or .vft


//Start
public void OnPluginStart()
{
	RegConsoleCmd("sm_testoverlay", Command_TestOverlay, "Show overlay to client");
	RegConsoleCmd("sm_testoverlayall", Command_TestOverlayAll, "Show overlay to all clients for 5 seconds");
	RegConsoleCmd("sm_testremoveoverlay", Command_TestRemoveOverlay, "Remove overlay of all clients");
}


//MapStart
public void OnMapStart()
{
	PrecacheDecalAnyDownload(OVERLAYPATH);   //Stock for adding overlay to download table and precaching.
}


//Show overlay to client
public Action Command_TestOverlay(int client, int args)
{
	ShowOverlay(client, OVERLAYPATH, 0.0);   //Show the overlay to the client - 0.0 as lifetime will show the overlay constant.

	return Plugin_Handled;
}


//Show overlay to all clients
public Action Command_TestOverlayAll(int client, int args)
{
	ShowOverlayAll(OVERLAYPATH, 5.0);   //Show the overlay to the all clients - 5.0 as lifetime will delete the overlay after 5 seconds.

	return Plugin_Handled;
}


//Show overlay to client
public Action Command_TestRemoveOverlay(int client, int args)
{
	for (int i = 1; i <= MaxClients; i++)   //Loop through all clients. Client validation in stock function
	{
		CreateTimer(0.0, DeleteOverlay, GetClientUserId(i));   //We use a timer to remove the overlay.
	}

	return Plugin_Handled;
}
