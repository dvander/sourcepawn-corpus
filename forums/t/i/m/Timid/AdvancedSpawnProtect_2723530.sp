/*  [CS:GO] Advanced-Spawn-Protection pluins: Lightweight spawn protection plugin.
 *
 *  Copyright (C) 2021 Mr.Timid // timidexempt@gmail.com
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

#define DEBUG

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <timid>
//#include <redieFFA>


#define prefix "\x08[\x0CSpawn Protect\x08]"

Handle Timer_SP[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };
bool g_rainbowenabled[MAXPLAYERS + 1];

//ConVars
ConVar g_cvSPTime;
ConVar g_cvRainbowEnabled;
ConVar g_cvBotControl;
ConVar g_cvNotifyStart;
ConVar g_cvTeamOrFFA;
ConVar g_cvColorModels;
ConVar g_cvEndOnAttack;
ConVar g_cvAlpha;

//Int get 1++ value
int g_iSPTime;
int g_iSPTimeLeft[MAXPLAYERS + 1];

//Handles
Handle g_HudText;

//Bool get true or false
bool g_isEnabled;
bool g_isBotControled;
bool g_isNotifyEnabled;
bool g_isFFAEnabled;
bool g_isColorEnabled;
bool g_isAttackEnabled;


//Props
int g_bIsControllingBot = -1;


//Protected/UnProtecte colors
int g_ProtectedColor[4] = { 255, 255, 255, 120 };
int g_UnProtectedColorFFA[4] = { 255, 0, 0, 255 };
int g_UnProtectedColorT[4] = { 255, 0, 0, 255 };
int g_UnProtectedColorCT[4] = { 0, 0, 255, 255 };
int g_NoProtectedColor[4] = { 255, 255, 255, 255 };

public Plugin myinfo = 
{
	name = "Advanced Spawn Protection", 
	author = "Timid", 
	description = "Spawn protection for X seconds", 
	version = "4.2.5", 
	url = "https://steamcommunity.com/id/MrTimid/"
};


public void OnPluginStart()
{
	//ConVar List
	g_cvSPTime = CreateConVar("sm_spawnprotect_time", "14", "Sets how much time is left for spawn protection. (def, 14)");
	g_cvSPTime.AddChangeHook(OnCVarChanged);
	g_cvRainbowEnabled = CreateConVar("sm_spawnprotect_rainbowhud", "1", "Sets whether rainbow menu is enabled. (0 off, 1 on)");
	g_cvRainbowEnabled.AddChangeHook(OnCVarChanged);
	g_cvBotControl = CreateConVar("sm_spawnprotect_botcontrol", "1", "Should bots receive spawn protection if another player takes control of them. (0 off, 1 on)");
	g_cvBotControl.AddChangeHook(OnCVarChanged);
	g_cvNotifyStart = CreateConVar("sm_spawnprotect_notifystart", "1", "Should we notify users, in game chat, that they have spawnprotection. (0 off, 1 on)");
	g_cvNotifyStart.AddChangeHook(OnCVarChanged);
	g_cvTeamOrFFA = CreateConVar("sm_spawnprotect_ffamode", "1", "Should we set colors for ffa or teams. (0 teams, 1 ffa)");
	g_cvTeamOrFFA.AddChangeHook(OnCVarChanged);
	g_cvColorModels = CreateConVar("sm_spawnprotect_colormodels", "1", "Should we set colored player models. (0 off, 1 on)");
	g_cvColorModels.AddChangeHook(OnCVarChanged);
	g_cvEndOnAttack = CreateConVar("sm_spawnprotect_endonattack", "1", "Should we disable spawn protect on attack. (0 off, 1 on)");
	g_cvEndOnAttack.AddChangeHook(OnCVarChanged);
	g_cvAlpha = FindConVar("sv_disable_immunity_alpha");
	g_cvAlpha.IntValue = 1;
	g_cvAlpha.AddChangeHook(OnCVarChanged);
	
	//Cfg File
	AutoExecConfig(true, "AdvancedSpawnProtect");
	
	
	//Hook Events
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
	HookEvent("round_prestart", Event_RoundStart, EventHookMode_Pre);
	HookEvent("weapon_fire", Event_WeaponFire);
	
	//Admin CMD
	RegAdminCmd("sm_rainbow", CMD_OnRainbow, ADMFLAG_RCON);
	
	//Loop Event
	LoopIngamePlayers(x)
	{
		OnClientPutInServer(x);
		
	}
	//Int Values
	g_iSPTime = g_cvSPTime.IntValue;
	
	
	//Bool Vlaues
	g_isEnabled = g_cvRainbowEnabled.BoolValue;
	g_isBotControled = g_cvBotControl.BoolValue;
	g_isNotifyEnabled = g_cvNotifyStart.BoolValue;
	g_isFFAEnabled = g_cvTeamOrFFA.BoolValue;
	g_isColorEnabled = g_cvColorModels.BoolValue;
	g_isAttackEnabled = g_cvEndOnAttack.BoolValue;
	
	//Find props
	g_bIsControllingBot = FindSendPropInfo("CCSPlayer", "m_bIsControllingBot");
	
	//SyncHudText
	g_HudText = CreateHudSynchronizer();
	
}
//OnCVarChagned values
public void OnCVarChanged(ConVar convar, char[] oldValue, char[] newValue)
{
	if (convar == g_cvSPTime)
	{
		g_iSPTime = g_cvSPTime.IntValue;
	}
	if (convar == g_cvRainbowEnabled)
	{
		g_isEnabled = g_cvRainbowEnabled.BoolValue;
	}
	if (convar == g_cvBotControl)
	{
		g_isBotControled = g_cvBotControl.BoolValue;
	}
	if (convar == g_cvNotifyStart)
	{
		g_isNotifyEnabled = g_cvNotifyStart.BoolValue;
	}
	if (convar == g_cvTeamOrFFA)
	{
		g_isFFAEnabled = g_cvTeamOrFFA.BoolValue;
	}
	if (convar == g_cvColorModels)
	{
		g_isColorEnabled = g_cvColorModels.BoolValue;
	}
	if (convar == g_cvEndOnAttack)
	{
		g_isAttackEnabled = g_cvEndOnAttack.BoolValue;
	}
	if (strcmp(newValue, "1") != 0)
	{
		g_cvAlpha.IntValue = 1;
	}
}

public Action Event_WeaponFire(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(client) || !IsPlayerAlive(client))
		return Plugin_Stop;
	
	if (!g_isAttackEnabled)
		return Plugin_Continue;
	
	RemoveSpawnProtection(client);
	return Plugin_Continue;
}

public void RemoveSpawnProtection(int client)
{
	SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
	g_iSPTimeLeft[client] = 0;
	CheckTeamColor(client);
}

public Action CMD_OnRainbow(int client, int args)
{
	if (!IsValidClient(client))
		return Plugin_Handled;
	//if (!Redie_InDm(client))
	//return Plugin_Handled;
	CreateTimer(0.1, Timer_RainbowColor, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	g_rainbowenabled[client] = !g_rainbowenabled[client];
	PrintToChat(client, "%s Rainbow model %s!", prefix, g_rainbowenabled[client] ? "enabled":"disabled");
	return Plugin_Handled;
	
}
public Action Timer_RainbowColor(Handle timer, int client)
{
	if (!IsValidClient(client) || !g_rainbowenabled[client])
		return Plugin_Continue;
	int rbColor[4];
	DataPack dp_rbColor = GetRainbowColor(client, 0.3);
	dp_rbColor.Reset();
	rbColor[0] = dp_rbColor.ReadCell();
	rbColor[1] = dp_rbColor.ReadCell();
	rbColor[2] = dp_rbColor.ReadCell();
	rbColor[3] = 255;
	delete dp_rbColor;
	SetEntityRenderColor(client, rbColor[0], rbColor[1], rbColor[2], rbColor[3]);
	return Plugin_Continue;
}

public DataPack GetRainbowColor(int client, float flRate)
{
	DataPack rbColor = new DataPack();
	int color[3];
	color[0] = RoundToNearest(Cosine((GetGameTime() * flRate) + client + 0) * 127.5 + 127.5);
	color[1] = RoundToNearest(Cosine((GetGameTime() * flRate) + client + 2) * 127.5 + 127.5);
	color[2] = RoundToNearest(Cosine((GetGameTime() * flRate) + client + 4) * 127.5 + 127.5);
	rbColor.WriteCell(color[0]);
	rbColor.WriteCell(color[1]);
	rbColor.WriteCell(color[2]);
	return rbColor;
}


public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
	Timer_SP[client] = INVALID_HANDLE;
}

public Action OnTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if (victim == attacker)return Plugin_Continue;
	if (g_iSPTimeLeft[attacker] > 0 || IsWarmup())
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_TraceAttack, OnTraceAttack);
	g_rainbowenabled[client] = false;
}

public Action Event_PlayerSpawn(Handle event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(client))
		return Plugin_Handled;
	
	/* Disable shoting in warmup */
	if (IsWarmup())
		SetPlayerColor(client, g_ProtectedColor);
	
	if (g_isBotControled && IsPlayerControllingBot(client))
		return Plugin_Continue;
	
	if (g_isNotifyEnabled)
	{
		PrintToChat(client, "%s Spawn protection is now \x04ON.", prefix);
	}
	
	if (!IsWarmup() && g_iSPTimeLeft[client] <= 0)
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
		g_iSPTimeLeft[client] = g_iSPTime;
		//Might want to also display spawn prot hud message up here so clients dont get the 1 second delay due to using timers
		Timer_SP[client] = CreateTimer(1.0, Timer_SpawnProtection, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
		return Plugin_Continue;
	}
	
	return Plugin_Continue;
}

public Action Timer_SpawnProtection(Handle timer, int client)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client))
	{
		Timer_SP[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	if (g_isEnabled)
	{
		//Get rainbow color for msg
		int rbColor[4];
		DataPack dp_rbColor = GetRainbowColor(client, 0.2);
		dp_rbColor.Reset();
		rbColor[0] = dp_rbColor.ReadCell();
		rbColor[1] = dp_rbColor.ReadCell();
		rbColor[2] = dp_rbColor.ReadCell();
		rbColor[3] = 255;
		delete dp_rbColor;
		
		SetHudTextParams(-1.0, 0.1, 5.0, rbColor[0], rbColor[1], rbColor[2], rbColor[3], 0, 0.1, 0.1, 0.1);
		//    
		
	} else if (!g_isEnabled)
	{
		//Get normal hud colors
		int HudColor[4];
		
		HudColor[0] = 0;
		HudColor[1] = 255;
		HudColor[2] = 0;
		HudColor[3] = 255;
		
		SetHudTextParams(-1.0, 0.1, 5.0, HudColor[0], HudColor[1], HudColor[2], HudColor[3], 0, 0.1, 0.1, 0.1);
	}
	
	if (g_iSPTimeLeft[client] > 0)
	{
		ShowSyncHudText(client, g_HudText, "SPAWN PROTECTION\n%d seconds left", g_iSPTimeLeft[client]);
		SetPlayerColor(client, g_ProtectedColor);
		g_iSPTimeLeft[client] -= 1;
	}
	else if (g_iSPTimeLeft[client] <= 0)
	{
		ShowSyncHudText(client, g_HudText, "SPAWN PROTECTION\nis now off!");
		if (g_isNotifyEnabled)
			PrintToChat(client, "%s Spawn protection is now \x07OFF.", prefix);
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		CheckTeamColor(client);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action Event_RoundStart(Handle event, char[] name, bool dontBroadcast)
{
	//Nothing atm
	return Plugin_Continue;
}

public Action Event_RoundEnd(Handle event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	LoopAlivePlayers(x)
	{
		CheckTeamColor(client);
	}
	return Plugin_Continue;
}

public void SetPlayerColor(int client, int[] colorTarget)
{
	if (!IsValidClient(client))
		return;
	int rgba[4];
	GetEntityRenderColor(client, rgba[0], rgba[1], rgba[2], rgba[3]);
	if (!compare_arrays(rgba, colorTarget, sizeof(rgba)))
		SetEntityRenderColor(client, colorTarget[0], colorTarget[1], colorTarget[2], colorTarget[3]);
	SetEntityRenderMode(client, RENDER_TRANSALPHA);
}

stock bool compare_arrays(any[] array1, any[] array2, int size)
{
	for (int i = 0; i < size; i++)
	if (array1[i] != array2[i])
	{
		return false;
	}
	return true;
}

/* 
* Check if a player is controlling a bot
* Credit: TnTSCS
* Url: https://forums.alliedmods.net/showthread.php?t=188807&page=13
*/
stock bool IsPlayerControllingBot(int client)
{
	return view_as<bool>(GetEntData(client, g_bIsControllingBot, 1));
}

stock void CheckTeamColor(int client)
{
	
	if (!IsValidClient(client))
		return;
	if (!g_isColorEnabled)
	{
		SetPlayerColor(client, g_NoProtectedColor);
		return;
	}
	else if (g_isFFAEnabled)
	{
		SetPlayerColor(client, g_UnProtectedColorFFA);
	}
	else if (GetClientTeam(client) == CS_TEAM_T)
	{
		SetPlayerColor(client, g_UnProtectedColorT);
	}
	else
	{
		SetPlayerColor(client, g_UnProtectedColorCT);
	}
} 