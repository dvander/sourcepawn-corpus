/**
 * vim: set ts=4 :
 * =============================================================================
 * Ignite Player Source
 * Copyright (C) 2012 Ross Bemrose (Powerlord).  All rights reserved.
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
 * Version: $Id$
 */

#include <sourcemod>
#include <sdktools>

// Only here to prevent loading on non-TF2
#include <tf2>

public Plugin:myinfo = 
{
	name = "[TF2] Ignite with Weapon Source",
	author = "Powerlord",
	description = "Native to call CTFPlayerShared::Burn with a weapon index",
	version = "1.0",
	url = "<- URL ->"
}

new Handle:g_TF2GameConf;
new Handle:g_Burn;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("TF2_IgnitePlayerSource");
	CreateNative("TF2_IgnitePlayerSource", Native_IgnitePlayerSource);
	
	return APLRes_Success;
}

public OnPluginStart()
{
	g_TF2GameConf = LoadGameConfigFile("sm-tf2.games.txt");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_TF2GameConf, SDKConf_Signature, "Burn");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
	g_Burn = EndPrepSDKCall();
}

public Native_IgnitePlayerSource(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	if (client < 1 || client > MaxClients || !IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is not valid", client);
	}
	
	new target = GetNativeCell(2);

	if (target < 1 || target > MaxClients || !IsClientInGame(target))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is not valid", target);
	}
	
	new weapon = GetNativeCell(3);

	if (weapon == -1)
	{
		TF2_IgnitePlayer(client, target);
		return;
	}
	
	if (!IsValidEntity(weapon))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Entity index %d is not valid", weapon);
	}

	decl String:classname[64];
	GetEntityClassname(weapon, classname, sizeof(classname));
	
	if (!StrContains(classname, "tf_weapon", false) && !StrContains(classname, "saxxy", false))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Entity index %d is not a weapon", weapon);
	}
	
	IgnitePlayerSource(client, target, weapon);
}

IgnitePlayerSource(client, target, weapon)
{
	if (client < 1 || client > MaxClients || !IsClientInGame(client))
	{
		ThrowError("Client index %d is not valid", client);
	}
	
	if (target < 1 || target > MaxClients || !IsClientInGame(target))
	{
		ThrowError("Client index %d is not valid", target);
	}

	if (weapon == -1)
	{
		TF2_IgnitePlayer(client, target);
		return;
	}
	
	decl String:classname[64];
	GetEntityClassname(weapon, classname, sizeof(classname));
	
	if (!StrContains(classname, "tf_weapon", false) || !StrContains(classname, "saxxy", false))
	{
		ThrowError("Entity index %d is not a weapon", weapon);
	}

	SDKCall(g_Burn, client, target, weapon);
}
