/*  SM Franug No Agents Models
 *
 *  Copyright (C) 2020 Francisco 'Franc1sco' García
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
#include <cstrike>

// Valve Agents models list
char Agents[][] = {
"models/player/custom_player/legacy/tm_phoenix_varianth.mdl",
"models/player/custom_player/legacy/tm_phoenix_variantg.mdl",
"models/player/custom_player/legacy/tm_phoenix_variantf.mdl",
"models/player/custom_player/legacy/tm_leet_varianti.mdl",
"models/player/custom_player/legacy/tm_leet_variantg.mdl",
"models/player/custom_player/legacy/tm_leet_varianth.mdl",
"models/player/custom_player/legacy/tm_balkan_variantj.mdl",
"models/player/custom_player/legacy/tm_balkan_varianti.mdl",
"models/player/custom_player/legacy/tm_balkan_varianth.mdl",
"models/player/custom_player/legacy/tm_balkan_variantg.mdl",
"models/player/custom_player/legacy/tm_balkan_variantf.mdl",
"models/player/custom_player/legacy/ctm_st6_variantm.mdl",
"models/player/custom_player/legacy/ctm_st6_varianti.mdl",
"models/player/custom_player/legacy/ctm_st6_variantg.mdl",
"models/player/custom_player/legacy/ctm_sas_variantf.mdl",
"models/player/custom_player/legacy/ctm_fbi_varianth.mdl",
"models/player/custom_player/legacy/ctm_fbi_variantg.mdl",
"models/player/custom_player/legacy/ctm_fbi_variantb.mdl",
"models/player/custom_player/legacy/tm_leet_variantf.mdl",
"models/player/custom_player/legacy/ctm_fbi_variantf.mdl",
"models/player/custom_player/legacy/ctm_st6_variante.mdl",
"models/player/custom_player/legacy/ctm_st6_variantk.mdl"
};

// default models for replace
char tmodel[128] = "models/player/custom_player/legacy/tm_phoenix_varianta.mdl";
char ctmodel[128] = "models/player/custom_player/legacy/ctm_sas_varianta.mdl";


#define DATA "2.0"

public Plugin myinfo = 
{
	name = "SM Franug No Agents Models",
	author = "Franc1sco franug",
	description = "",
	version = DATA,
	url = "http://steamcommunity.com/id/franug"
};

ConVar cv_ct, cv_tt, cv_time;
char g_ctmodel[128], g_ttmodel[128];
float g_time;

Handle timers[MAXPLAYERS];

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	cv_ct = CreateConVar("sm_noagents_ctmodel", "models/player/custom_player/legacy/ctm_sas_varianta.mdl", "Set the default ct models for apply to people that have a agent skin");
	cv_tt = CreateConVar("sm_noagents_ttmodel", "models/player/custom_player/legacy/tm_phoenix_varianta.mdl", "Set the default tt models for apply to people that have a agent skin");
	
	cv_time = CreateConVar("sm_noagents_timer", "1.2", "Timer on spawn for apply filter of no agents");
	
	HookConVarChange(cv_ct, CVarChanged);
	HookConVarChange(cv_tt, CVarChanged);
	HookConVarChange(cv_time, CVarChanged);
	
	GetConVarString(cv_ct, g_ctmodel, 128);
	GetConVarString(cv_tt, g_ttmodel, 128);
	g_time = GetConVarFloat(cv_time);
}

public void CVarChanged(ConVar hConvar, char[] oldV, char[] newV)
{
	if(cv_ct == hConvar)
	{
		strcopy(g_ctmodel, 128, newV);
		if(!IsModelPrecached(g_ctmodel))
			PrecacheModel(g_ctmodel);
	}
	else if(cv_tt == hConvar)
	{
		strcopy(g_ttmodel, 128, newV);
		if(!IsModelPrecached(g_ttmodel))
			PrecacheModel(g_ttmodel);
	}
}

public void OnClientDisconnect(int client)
{
	if(timers[client] != null)
		KillTimer(timers[client]);
		
	timers[client] = null;
}

public void OnMapStart()
{
	PrecacheModel(g_ttmodel);
	
	PrecacheModel(g_ctmodel);
}

public Action Event_PlayerSpawn(Handle event, char[] name, bool dontBroadcast)
{	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsFakeClient(client))return;
	
	if(timers[client] != null)
		KillTimer(timers[client]);
		
	timers[client] = CreateTimer(g_time, ReModel, client);
}

public Action ReModel(Handle timer, int client)
{
	timers[client] = null;
	
	if (!IsClientInGame(client) || !IsPlayerAlive(client))return;
	
	char model[128];
	GetClientModel(client, model, sizeof(model));
	
	if(StrContains(model, "models/player/custom_player/legacy/") == -1) // player use a custom model by other plugin
		return;
	
	int team = GetClientTeam(client);
	
	if (team < 2)return;
	
	for (int i = 0; i < sizeof(Agents); i++)
	{
		if(StrEqual(model, Agents[i]))
		{
			if (team == CS_TEAM_CT)SetEntityModel(client, ctmodel);
			else SetEntityModel(client, tmodel);
			
			break;
		}			
	}
}
