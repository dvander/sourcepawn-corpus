/**
 * vim: set ts=4 :
 * =============================================================================
 * SourceMod Reserved Slots Plugin
 * Provides basic reserved slots.
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
 * Version: $Id: reservedslots.sp 1357 2007-08-18 22:51:25Z dvander $
 */

#pragma semicolon 1

#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Free Slots",
	author = "Lugavchik",
	description = "Provides basic slots reservation",
	version = SOURCEMOD_VERSION,
	url = "http://www.megatron.ws/"
};

/* Handles to convars used by plugin */
new Handle:sv_visiblemaxplayers;

public OnPluginStart()
{
	LoadTranslations("reservedslots.phrases");
	
	sv_visiblemaxplayers = FindConVar("sv_visiblemaxplayers");
}

public Action:OnTimedKick(Handle:timer, any:value)
{
	new client = GetClientOfUserId(value);
	
	if (!client || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	KickClient(client, "%T", "Slot reserved", client);
	
	return Plugin_Handled;
}

public OnClientPostAdminCheck(client)
{
	new visible = GetConVarInt(sv_visiblemaxplayers);
	
	new clients = GetClientCount(false);
	new flags = GetUserFlagBits(client);
		
	if (clients <= visible || IsFakeClient(client) || flags & ADMFLAG_ROOT || flags & ADMFLAG_RESERVATION)
	{
		return;
	}

	/* Kick player because there are no public slots left */
	CreateTimer(0.1, OnTimedKick, GetClientUserId(client));
}