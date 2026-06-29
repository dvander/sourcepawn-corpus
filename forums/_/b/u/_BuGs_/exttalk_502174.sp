/**
 * ===============================================================
 * External Talk, Copyright (C) 2007
 * Released under the Steamfriends.com Brand
 * All rights reserved.
 * ===============================================================
 *	
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * To view the latest information, see:  http://forums.alliedmods.net/showthread.php?p=502174
 * 	Author(s):	Shane A. ^BuGs^ Froebel
 *
 *
 *	Use at your OWN risk! Please submit your changes of this
 *	script to Shane. Known issues/Submit bug reports at:
 *	
 *		http://bugs.alliedmods.net/?project=9&do=index
 *	
 *	
 *	Usage:
 *
 *	This script requires some client "setup" for this script to work.
 *	Using the "bind" command they need to bind "sm_exttalk" to their TeamSpeak or Vent
 *  push to talk key so when they do press it from within the game, it toggles this function
 *	to show that the user is talking.
 *
 *	"Active Talkers" only goto users who have the "Acess_Reservation" flag (a).
 *	This allows only those people to see the messages and to see who is talking.
 *	This is good for game matchs as you want to know who is currently speaking on
 *	Teamspeak or Vent.
 *	
 *	I use "bind MOUSE4 sm_exttalk" and what will show up to all users who have the flag is:
 *		<name> is talking...
 *	
 *	
 *	If you post bug reports over the forums, they will not be taken.
 *
 *	Thanks...                 
 *	  -- Shane A. Froebel
 *
 *
**/ 

#pragma semicolon 1

#include <sourcemod>

#define EXTERNALTALK_VERSION "1.0.0.0"
#define BUILDD __DATE__
#define BUILDT __TIME__

#define YELLOW				0x01
#define LIGHTGREEN			0x03
#define GREEN				0x04

/*****************************************************************
*                      BASE INFORMATION                          * 
******************************************************************/

public Plugin:myinfo = 
{
	name = "External Talk",
	author = "Shane A. ^BuGs^ Froebel",
	description = "This plugin will show all users with Access_Reservation flag who is talking in vent.",
	version = EXTERNALTALK_VERSION,
	url = "http://www.steamfriends.com/"
};

public OnPluginStart() 
{
	
	LoadTranslations("plugin.exttalk");
	
	CreateConVar("sm_exttalk_version",EXTERNALTALK_VERSION,"The version of 'External Talk' running.",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	CreateConVar("sm_exttalk_build",SOURCEMOD_VERSION,"The version of 'External Talk' was built on.",FCVAR_PLUGIN);
	
	RegAdminCmd("sm_exttalk", Command_Exttalk, ADMFLAG_RESERVATION, "sm_exttalk");
		
}


public Action:Command_Exttalk(client, args)
{
	if (!args)
	{
		new String:Usertalking[255];
		GetClientName(client, Usertalking, sizeof(Usertalking));
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if ((IsClientInGame(i)) && (!IsFakeClient(i)))
			{
				new AdminId:aid = GetUserAdmin(i);
				if (GetAdminFlag(aid, Admin_Reservation, Access_Effective))
				{
					PrintToChat(i, "%c %s %t", LIGHTGREEN, Usertalking, "Client is talking");
				}
			}	
		}
	} else {
		ReplyToCommand(client, "%c[ET]%c %t", GREEN, YELLOW, "No variables should be passed with this command");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}