/**
 * vim: set ts=4 :
 * =============================================================================
 * SourceMod Auto-Alltalk Plugin
 * Automatically turns alltalk on and off based on player count.
 *
 * SourceMod (C)2004-2007 AlliedModders LLC.  All rights reserved.
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
 * Version: $Id: rockthevote.sp 1783 2007-12-09 21:45:23Z ferret $
 */

#include <sourcemod>

#pragma semicolon 1

public Plugin:myinfo =
{
	name = "Auto-Alltalk",
	author = "AlliedModders LLC",
	description = "Automatically turns alltalk on and off",
	version = SOURCEMOD_VERSION,
	url = "http://www.sourcemod.net/"
};

new Handle:g_Cvar_Limit = INVALID_HANDLE;
new Handle:g_Cvar_Mode = INVALID_HANDLE;
new Handle:g_Cvar_Alltalk = INVALID_HANDLE;

public OnPluginStart()
{
	g_Cvar_Limit = CreateConVar("sm_aatlimit", "10", "Number of players needed to toggle alltalk.", 0, true, 0.0, true, 64.0);
	g_Cvar_Mode = CreateConVar("sm_aatmode", "0", "When the limit is reached: 0 = turn off alltalk, 1 = turn on alltalk.", 0, true, 0.0, true, 1.0);
	g_Cvar_Alltalk = FindConVar("sv_alltalk");
	
	HookConVarChange(g_Cvar_Alltalk, ConVarChange_Alltalk);
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	if (GetConVarInt(g_Cvar_Limit))
	{
		new cur = GetClientCount(false);

		if (cur >= GetConVarInt(g_Cvar_Limit))
		{
			SetConVarBool(g_Cvar_Alltalk, GetConVarBool(g_Cvar_Mode));
		}		
	}

	return true;
}

public OnClientDisconnect(client)
{
	if (GetConVarInt(g_Cvar_Limit))
	{
		new cur = GetClientCount(false);

		if (cur < GetConVarInt(g_Cvar_Limit))
		{
			SetConVarBool(g_Cvar_Alltalk, GetConVarBool(g_Cvar_Mode));
		}		
	}
}

public ConVarChange_Alltalk(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (oldValue[0] == newValue[0])
	{
		return;
	}
	
	if (!GetConVarInt(g_Cvar_Limit))
	{
		return;
	}	

	new cur = GetClientCount(false);
	
	if (cur >= GetConVarInt(g_Cvar_Limit) && GetConVarBool(g_Cvar_Alltalk) != GetConVarBool(g_Cvar_Mode))
	{
		SetConVarBool(g_Cvar_Alltalk, GetConVarBool(g_Cvar_Mode));
	}
	else if (GetConVarBool(g_Cvar_Alltalk) == GetConVarBool(g_Cvar_Mode))
	{
		SetConVarBool(g_Cvar_Alltalk, !GetConVarBool(g_Cvar_Mode));
	}
}