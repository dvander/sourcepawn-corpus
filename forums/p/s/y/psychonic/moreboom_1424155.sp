/**
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
 */

public Plugin:myinfo =
{
	name = "MORE BOOM",
	author = "psychonic",
	description = "Resets the Ullapool Caber's detonation status",
	version = "1.0",
	url = "http://www.nicholashastings.com/"
};

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#if !defined ADMFLAG_NONE
	#define ADMFLAG_NONE 0
#endif

#define STICKBOMB_CLASS "CTFStickBomb"

new offsBroken = -1
new offsDetonated = -1;
new Handle:cvTime;
new Handle:zeTimers[MAXPLAYERS+1];

public OnPluginStart()
{
	HookEvent("player_hurt", Event_PlayerHurt);
	
	HookEvent("player_death", Event_DoKillTimer);
	HookEvent("player_changeclass", Event_DoKillTimer);
	HookEvent("post_inventory_application", Event_DoKillTimer);
	
	offsBroken = FindSendPropInfo(STICKBOMB_CLASS, "m_bBroken");
	offsDetonated = FindSendPropInfo(STICKBOMB_CLASS, "m_iDetonated");
	
	cvTime = CreateConVar("moreboom_refreshtime", "16", "Time, in seconds, until stickbomb is reset (for those with permission) Default: 16", 0, true, 0.0);
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (victim == 0 || attacker != victim || !IsClientInGame(victim)
		|| GetEventInt(event, "custom") != TF_CUSTOM_STICKBOMB_EXPLOSION)
	{
		return;
	}
	
	if (CheckCommandAccess(victim, "moreboom_instant", ADMFLAG_NONE, true))
	{
		RefreshStickBomb(victim, false);
	}
	else if (CheckCommandAccess(victim, "moreboom_timed", ADMFLAG_NONE, true))
	{
		zeTimers[victim] = CreateTimer(GetConVarFloat(cvTime), Timer_RefreshStickBomb, GetClientUserId(victim));
	}
}

public Event_DoKillTimer(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	KillStickBombTimer(client);
}

public OnClientDisconnect(client)
{
	KillStickBombTimer(client);
}

KillStickBombTimer(client)
{
	new Handle:timer = zeTimers[client];
	if (timer != INVALID_HANDLE)
	{
		KillTimer(timer);
		zeTimers[client] = INVALID_HANDLE;
	}
}

public Action:Timer_RefreshStickBomb(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client == 0)
	{
		return;
	}
	
	RefreshStickBomb(client);
	zeTimers[client] = INVALID_HANDLE;
}

RefreshStickBomb(client, bool:doWeaponCheck=true)
{
	new stickbomb = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	if (stickbomb <= MaxClients || !IsValidEdict(stickbomb))
	{
		return;
	}
	
	if (doWeaponCheck)
	{
		decl String:netclass[64];
		GetEntityNetClass(stickbomb, netclass, sizeof(netclass));
		if (!!strcmp(netclass, STICKBOMB_CLASS))
		{
			return;
		}
	}
	
	SetEntData(stickbomb, offsBroken, 0, 1, true);
	SetEntData(stickbomb, offsDetonated, 0, 1, true);
}
