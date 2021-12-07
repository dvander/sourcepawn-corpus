
/*  SM Show Damage as Fortnite
 *
 *  Copyright (C) 2018 Francisco 'Franc1sco' García
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */
 

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define SOUND "franug/ding.mp3"

#define DATA "1.2"

public Plugin myinfo =
{
	name = "SM Show iDamage as Fortnite",
	author = "Franc1sco Steam: franug", // Edited by Eyal282 to include ONLY the headshot sound
	description = "",
	version = DATA,
	url = "http://steamcommunity.com/id/franug"
};

public void OnPluginStart()
{
	CreateConVar("sm_showdamage_as_fortnite_version", DATA, "", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	HookEvent("player_hurt", Event_PlayerHurt);
}

public void OnMapStart()
{
	PrecacheSound(SOUND);
	
	char temp[128];
	Format(temp, sizeof(temp), "sound/%s", SOUND);
	
	AddFileToDownloadsTable(temp);
}

public Action Event_PlayerHurt(Handle event, const char[] name, bool dontBroadcast)
{	
	int iAttacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int iVictim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(iVictim == iAttacker || iAttacker == 0)
		return;

	int iDamage = GetEventInt(event, "dmg_health"); 
	int iHitgroup = GetEventInt(event, "hitgroup");
	
	if(iHitgroup == 1) // headshot
		EmitSoundToClient(iAttacker, SOUND); // emit sound
}
