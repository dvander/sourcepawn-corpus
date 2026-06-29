/*
	LayerStrike

	Copyright (C) 2017 Christopher 'Chriz' Juerges

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
	
	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/


#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <emitsoundany>

#pragma semicolon 1
#pragma newdecls required

// Menu finalas
#define STARTMOD "#start"
#define RROUND "#rround"
#define CTKNIFE "#ctknife"
#define TKNIFE "#tknife"
#define DOBOOM "#doboom"
#define DOBING "#dobing"
// Menu finals end

#define SOUND_BING "misc/bing.mp3"
#define SOUND_VISIBLE "misc/allvisible.mp3"

int playerLayer[MAXPLAYERS+1] = {0, ...};
bool showClient[MAXPLAYERS+1] = {false, ...};

bool g_BombMakePlayerVisible;
bool g_BombPlanted;
bool g_DoBingSound;

// Timer related variables
Handle g_Timer;
Handle g_WeaponSwitchTimer[MAXPLAYERS+1];
int g_TimeCounter;
int g_TimeBombPLanted;

// ConVars
ConVar layerstrike_allsee_ct_knife = null;
ConVar layerstrike_allsee_t_knife = null;
ConVar layerstrike_enabled = null;
ConVar layerstrike_time_after_plant_visible = null;
ConVar layerstrike_layer_switch_sound = null;

public Plugin myinfo =
{
	name = "Layer Strike",
	author = "Christopher 'Chriz' Juerges",
	description = "Only enemies on the same layer are visible, but always hittable!",
	version = "1.0",
	url = "steamcommunity.com/groups/layerstrike"
};

public void OnMapStart() {
	AddFileToDownloadsTable("sound/misc/bing.mp3");
	AddFileToDownloadsTable("sound/misc/allvisible.mp3");
	
	PrecacheSoundAny(SOUND_BING, true);
	PrecacheSoundAny(SOUND_VISIBLE, true);
}

public void OnPluginStart()
{
	g_DoBingSound = false;

	layerstrike_allsee_ct_knife = CreateConVar("layerstrike_allsee_ct_knife", "0", "CTs see everything with knife if 1", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	layerstrike_allsee_t_knife = CreateConVar("layerstrike_allsee_t_knife", "0", "Ts see everything with knife if 1", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	layerstrike_enabled = CreateConVar("layerstrike_enabled", "1", "Enable Layer Strike mode with 1", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	layerstrike_time_after_plant_visible = CreateConVar("layerstrike_time_after_plant_visible", "15", "Time after bomb is planted that all players get visible", FCVAR_NOTIFY, true, 1.0, false, 999.0);
	layerstrike_layer_switch_sound = CreateConVar("layerstrike_layer_switch_sound", "1", "Performs a sound when switching layers if 1", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	AutoExecConfig(true, "plugin_LayerStrike");

	if (layerstrike_enabled.BoolValue) {
		ToggleLayerStrike(true);
	} else {
		ToggleLayerStrike(false);
	}

	RegAdminCmd("layerstrike", Command_LayerStrike, ADMFLAG_SLAY);

	HookEvent("bomb_planted", Event_BombPlanted, EventHookMode_PostNoCopy);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_freeze_end", Event_FreezeTimeEnd);

	LoadTranslations("layerstrike.phrases");
}

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
	SDKHook(client, SDKHook_WeaponCanSwitchTo, Hook_WeaponSwitchHook);
}

// Event hooks
public Action Event_FreezeTimeEnd(Event event, const char[] name, bool dontBroadcast) {
	g_DoBingSound = true;
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {
	g_TimeCounter = 0;
	g_TimeBombPLanted = 0;
	g_BombPlanted = false;
	g_BombMakePlayerVisible = false;
	g_DoBingSound = false;
	if (g_Timer) KillTimer(g_Timer);
	g_Timer = CreateTimer(1.0, Timer_OneSecond, _, TIMER_REPEAT);
}

public void Event_BombPlanted(Event event, const char[] name, bool dontBroadcast) {
	if (layerstrike_enabled.BoolValue) {
		g_BombPlanted = true;
		g_TimeBombPLanted = g_TimeCounter;
	}
}
// Event hooks end

// Player Hooks
public Action Hook_WeaponSwitchHook(int client, int weapon) {
	if (layerstrike_layer_switch_sound.BoolValue && layerstrike_enabled.BoolValue && g_DoBingSound) {
		PerformBingSound(client, client);
	}
	g_WeaponSwitchTimer[client] = CreateTimer(0.1, Timer_OnWeaponSwitch, client);
	showClient[client] = true;
	return Plugin_Continue;
}

public Action Hook_SetTransmit(int entity, int client) {
	// Show entity to client if LS is disabled, bomb lays for 15 sec or it should be shown based on showClient-array
	if (!layerstrike_enabled.BoolValue || g_BombMakePlayerVisible || showClient[entity]) {
		return Plugin_Continue;
	}
	// Show entity to client if the client or the entity is no real client
	if (!IsValidClient(entity) || !IsValidClient(client)) {
		return Plugin_Continue;
	}
	// Show entity to client if the entity is in the same team as the client
	if (GetClientTeam(entity) == GetClientTeam(client)) {
		return Plugin_Continue;
	}
	// Show entity to client if the entity or the client is dead
	if (!IsPlayerAlive(entity) || !IsPlayerAlive(client)) {
		return Plugin_Continue;
	}

	// Thanks to the user OSWO from AlliedMods for pointing that out for me
	// Link: https://forums.alliedmods.net/member.php?u=261698
	if (IsClientObserver(client)) {
		int specMode = GetEntProp(client, Prop_Send, "m_iObserverMode");
		// 4 = First person
		// 5 = Third person
		if (specMode == 4 || specMode == 5) {
			int target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
			if (target != -1 && IsValidClient(target)) {
				client = target;
			}
		}
	}

	AssignPlayerLayer(entity, client);

	// Check if the allsee knife is enabled for either the Ts or CTs and if they have knife equiped
	// If so, continue showing the enemies
	if (layerstrike_allsee_ct_knife.BoolValue && GetClientTeam(client) == CS_TEAM_CT && playerLayer[client] == 2) {
		return Plugin_Continue;
	}
	if (layerstrike_allsee_t_knife.BoolValue && GetClientTeam(client) == CS_TEAM_T && playerLayer[client] == 2) {
		return Plugin_Continue;
	}

	// If the active weapons are on different slots, do not show
	if (playerLayer[entity] != playerLayer[client]) {
		return Plugin_Stop;
	}
	return Plugin_Continue;
}
// Player hooks end 

// Timer functions
public Action Timer_OneSecond(Handle timer) {
	g_TimeCounter++;
	if (g_BombPlanted && ((g_TimeCounter - g_TimeBombPLanted) == (layerstrike_time_after_plant_visible.IntValue-1))) {
		EmitSoundToAllAny(SOUND_VISIBLE);
	}
	if (g_BombPlanted && ((g_TimeCounter - g_TimeBombPLanted) == layerstrike_time_after_plant_visible.IntValue)) {
		PrintCenterTextAll("%t", "Everyone_Visible");
		g_BombMakePlayerVisible = true;
		g_DoBingSound = false;
	}
} 

public Action Timer_OnWeaponSwitch(Handle timer, any client) {
	showClient[client] = false;
	g_WeaponSwitchTimer[client] = null;
}
//Timer functions end

// Commands
public Action Command_LayerStrike(int client, int args) {
	StartMenuOverview(client);
 
	return Plugin_Handled;
}
//Commands end

// Menu
public int MenuHandler1(Menu menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_DisplayItem) {
		char info[32];
		menu.GetItem(param2, info, sizeof(info));

		if (StrEqual(info, STARTMOD)) {
			if (layerstrike_enabled.BoolValue) {
				char stopLS[128];
				Format(stopLS, sizeof(stopLS), "%T Layer Strike", "LS_stop", param1);
				return RedrawMenuItem(stopLS);
			} else {
				char startLS[128];
				Format(startLS, sizeof(startLS), "%T Layer Strike", "LS_start", param1);
				return RedrawMenuItem(startLS);
			}
		} else if (StrEqual(info, CTKNIFE)) {
			if (layerstrike_allsee_ct_knife.BoolValue) {
				char knifeOn[128];
				Format(knifeOn, sizeof(knifeOn), "Mighty CT Knife: %T", "LS_on", param1);
				return RedrawMenuItem(knifeOn);
			} else {
				char knifeOff[128];
				Format(knifeOff, sizeof(knifeOff), "Mighty CT Knife: %T", "LS_off", param1);
				return RedrawMenuItem(knifeOff);
			}
		} else if (StrEqual(info, TKNIFE)) {
			if (layerstrike_allsee_t_knife.BoolValue) {
				char knifeOn[128];
				Format(knifeOn, sizeof(knifeOn), "Mighty T Knife: %T", "LS_on", param1);
				return RedrawMenuItem(knifeOn);
			} else {
				char knifeOff[128];
				Format(knifeOff, sizeof(knifeOff), "Mighty T Knife: %T", "LS_off", param1);
				return RedrawMenuItem(knifeOff);
			}
		} else if (StrEqual(info, DOBING)) {
			if (g_DoBingSound) {
				char bingOn[128];
				Format(bingOn, sizeof(bingOn), "Do bing sound on switch: %T", "LS_on", param1);
				return RedrawMenuItem(bingOn);
			} else {
				char bingOff[128];
				Format(bingOff, sizeof(bingOff), "Do bing sound on switch: %T", "LS_off", param1);
				return RedrawMenuItem(bingOff);
			}
		}
	}
	else if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param2, info, sizeof(info));
		if (StrEqual(info, STARTMOD)) {
			if (layerstrike_enabled.BoolValue) {
				ToggleLayerStrike(false);
			} else {
				ToggleLayerStrike(true);
			}
			StartMenuOverview(param1);
		} else if (StrEqual(info, RROUND)) {
			PrintToChatAll("%t", "Restarting_Game");
			ServerCommand("mp_restartgame 1");
			StartMenuOverview(param1);
		} else if (StrEqual(info, CTKNIFE)) {
			layerstrike_allsee_ct_knife.BoolValue = !layerstrike_allsee_ct_knife.BoolValue;
			StartMenuOverview(param1);
		} else if (StrEqual(info, TKNIFE)) {
			layerstrike_allsee_t_knife.BoolValue = !layerstrike_allsee_t_knife.BoolValue;
			StartMenuOverview(param1);
		} else if (StrEqual(info, DOBING)) {
			g_DoBingSound = !g_DoBingSound;
			StartMenuOverview(param1);
		}
	} else if (action == MenuAction_End) {
		delete menu;
	}
	return 0;
}

public void StartMenuOverview(int client) {
	Menu menu = new Menu(MenuHandler1, MenuAction_DisplayItem);
	menu.SetTitle("What do you want to do?");
	menu.AddItem(STARTMOD, "Start Layer Strike");
	menu.AddItem(CTKNIFE, "Mighty CT Knife: ON");
	menu.AddItem(TKNIFE, "Mighty T Knife: ON");
	menu.AddItem(DOBING, "Do bing on switch: OFF");
	menu.AddItem(RROUND, "Restart Game");
	menu.ExitButton = true;
	menu.Display(client, 20);
}
// Menu end

// Private methods
public void ToggleLayerStrike(bool enable) {
	if (layerstrike_enabled.BoolValue != enable) {
		if (enable) {
			layerstrike_enabled.BoolValue = true;
			PrintToChatAll("%t", "LS_enabled");
			PrintToChatAll("%t", "Initializing");
			LayerStrikeInit();
			PrintToChatAll("%t", "LS_loaded");
		} else {
			layerstrike_enabled.BoolValue = false;
			PrintToChatAll("%t", "LS_disabled");
		}
	}
}


// Took this method from Kinsi55's GhostStrike mod
// https://github.com/kinsi55/CSGO-GhostStrike/blob/master/GhostStrike.sp
public bool IsValidClient(int client) {
	return client <= MaxClients && client > 0 && IsClientConnected(client) && IsClientInGame(client);
}

public void LayerStrikeInit() {
	for(int i = 1; i <= MaxClients; i++) {
		if(IsValidClient(i)) {
			OnClientPutInServer(i);
		}
	}
}

public void PerformBingSound(int client, int target) {
	float location[3];
	GetClientAbsOrigin(target, location);

	EmitAmbientSoundAny(SOUND_BING, location);	
}

public void AssignPlayerLayer(int entity, int client) {
	int entitiesWeapon = GetEntPropEnt(entity, Prop_Send, "m_hActiveWeapon");
	int clientsActiveWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

	for (int slot = 0; slot < 3; slot++) {
		int clientsSlotWeapon = GetPlayerWeaponSlot(client, slot);
		int entitiesSlotWeapon = GetPlayerWeaponSlot(entity, slot);
		
		switch(slot) {
			case 0: {
				if (entitiesSlotWeapon == entitiesWeapon) {
					playerLayer[entity] = slot;
				}
				if (clientsSlotWeapon == clientsActiveWeapon) {
					playerLayer[client] = slot;
				}
			}
			case 1: {
				if (entitiesSlotWeapon == entitiesWeapon) {
					playerLayer[entity] = slot;
				}
				if (clientsSlotWeapon == clientsActiveWeapon) {
					playerLayer[client] = slot;
				}
			}
			case 2: {
				if (entitiesSlotWeapon == entitiesWeapon) {
					playerLayer[entity] = slot;
				}
				if (clientsSlotWeapon == clientsActiveWeapon) {
					playerLayer[client] = slot;
				}
			}
		}
	}
}
