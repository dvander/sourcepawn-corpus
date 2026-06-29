#pragma semicolon 1

#define PLUGIN_AUTHOR "R3TROATTACK"
#define PLUGIN_VERSION "1.3"

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma newdecls required

EngineVersion g_Game;

ConVar g_cReviveMode = null;
ConVar g_cReviveDist = null;
ConVar g_cReviveDelay = null;
ConVar g_cReviveTimerDelay = null;
ConVar g_cReviveCostMode = null;
ConVar g_cReviveCost = null;
ConVar g_cReviveHealth = null;
ConVar g_cReviveLimitMode = null;
ConVar g_cReviveLimit = null;
ConVar g_cReviveTeam = null;

float g_fLastRevive[MAXPLAYERS + 1];
Handle g_hReviving[MAXPLAYERS + 1];
int g_iRevivingTarget[MAXPLAYERS + 1];
float g_fTimeOfDeath[MAXPLAYERS + 1];
int g_iReviveCount[MAXPLAYERS + 1];
bool g_bLimitReach[MAXPLAYERS + 1];

int g_iAccount = -1;

public Plugin myinfo = 
{
	name = "Revive", 
	author = PLUGIN_AUTHOR, 
	description = "Revives a player by pressing +use", 
	version = PLUGIN_VERSION, 
	url = "http://steamcommunity.com/profiles/76561198045363076/"
};

public void OnPluginStart()
{
	g_Game = GetEngineVersion();
	if (g_Game != Engine_CSGO && g_Game != Engine_CSS)
	{
		SetFailState("This plugin is for CSGO/CSS only.");
	}
	g_cReviveMode = CreateConVar("revive_mode", "0", "-1 = disabled, 0 = revive anyone, 1 = revive team");
	g_cReviveDist = CreateConVar("revive_distance", "150.0", "How close do you need to be to revive someone");
	g_cReviveDelay = CreateConVar("revive_delay", "15.0", "Time between revives");
	g_cReviveTimerDelay = CreateConVar("revive_timer_delay", "5.0", "How long must the player hold +use on the body for?");
	g_cReviveCostMode = CreateConVar("revive_cost_mode", "0", "0 - free, 1 - health, 2 - money");
	g_cReviveCost = CreateConVar("revive_cost", "10", "How much does it cost to revive someone");
	g_cReviveHealth = CreateConVar("revive_health", "100", "What health does the player revive on?");
	g_cReviveLimitMode = CreateConVar("revive_limit_mode", "0", "0 - Ignore this, 1 - time limit, 2 - revive limit");
	g_cReviveLimit = CreateConVar("revive_limit", "30.0", "The limit based on \"revive_limit_mode\"");
	g_cReviveTeam = CreateConVar("revive_team", "0", "Which teams can revive players, 0 = both, 2=Terrorist, 3=CT", FCVAR_NONE, true, 0.0, true, 3.0);
	AutoExecConfig(true, "revive");
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_end", Event_RoundEnd);
}

public void OnMapStart()
{
	g_iAccount = FindSendPropInfo("CCSPlayer", "m_iAccount");
	if (g_iAccount == -1)
		SetFailState("Unable to find 'm_iAccount' in class 'CCSPlayer'");
}

public void OnClientPostAdminCheck(int client)
{
	g_fLastRevive[client] = GetGameTime();
	if (g_hReviving[client] != null) {
		CloseHandle(g_hReviving[client]);
		g_hReviving[client] = null;
	}
	g_iRevivingTarget[client] = -1;
	g_fTimeOfDeath[client] = 0.0;
	g_iReviveCount[client] = 0;
	g_bLimitReach[client] = false;
}

public void OnClientDisconnect(int client)
{
	if (g_hReviving[client] != null) {
		CloseHandle(g_hReviving[client]);
		g_hReviving[client] = null;
	}
	g_iRevivingTarget[client] = -1;
	g_fTimeOfDeath[client] = 0.0;
	g_fLastRevive[client] = 0.0;
	g_iReviveCount[client] = 0;
	g_bLimitReach[client] = false;
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_hReviving[i] != null) {
			CloseHandle(g_hReviving[i]);
			g_hReviving[i] = null;
		}
		g_iRevivingTarget[i] = -1;
		g_fLastRevive[i] = GetGameTime();
		g_fTimeOfDeath[i] = 0.0;
		g_iReviveCount[i] = 0;
		g_bLimitReach[i] = false;
	}
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (g_cReviveMode.IntValue == -1)
		return;
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidClient(victim))
		return;
	int deathBody = GetEntPropEnt(victim, Prop_Send, "m_hRagdoll");
	if (deathBody > 0)
		AcceptEntityInput(deathBody, "kill", 0, 0);
	
	int ent = CreateEntityByName("prop_ragdoll");
	char sModel[PLATFORM_MAX_PATH];
	GetClientModel(victim, sModel, sizeof(sModel));
	DispatchKeyValue(ent, "model", sModel);
	
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", victim);
	SetEntProp(ent, Prop_Data, "m_nSolidType", 6);
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 5);
	
	ActivateEntity(ent);
	
	if (DispatchSpawn(ent))
	{
		float origin[3], angles[3], velocity[3];
		
		GetClientAbsOrigin(victim, origin);
		GetClientAbsAngles(victim, angles);
		GetEntPropVector(victim, Prop_Data, "m_vecAbsVelocity", velocity);
		float speed = GetVectorLength(velocity);
		if (speed >= 500)
		{
			TeleportEntity(ent, origin, angles, NULL_VECTOR);
		}
		else
		{
			TeleportEntity(ent, origin, angles, velocity);
		}
		g_fTimeOfDeath[victim] = GetGameTime();
	}
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 2);
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	if (g_cReviveMode.IntValue == -1)
		return Plugin_Continue;
	if (!IsValidClient(client))
		return Plugin_Continue;
	if (!IsPlayerAlive(client))
		return Plugin_Continue;
	if (!(buttons & IN_USE) && g_hReviving[client] != null)
	{
		ClearReviveStuff(client, " \x06[Revive] \x01You have stopped reviving your target.");
	}
	if (buttons & IN_USE)
	{
		int aim = GetClientAimTarget(client, false);
		if (aim > MaxClients)
		{
			if (aim != g_iRevivingTarget[client]) {
				if (g_hReviving[client] != null) {
					ClearReviveStuff(client, " \x06[Revive] \x01You have stopped looking at your target, reviving stopped.");
				}
			}
			char class[128];
			GetEntityClassname(aim, class, sizeof(class));
			if (!StrEqual(class, "prop_ragdoll", false)) {
				if (g_hReviving[client] != null) {
					ClearReviveStuff(client, " \x06[Revive] \x01You are no longer looking at a valid target to revive, reviving stopped.");
				}
				return Plugin_Continue;
			}
			
			float eyePos[3];
			GetClientEyePosition(client, eyePos);
			float bodyLoc[3];
			GetEntPropVector(aim, Prop_Data, "m_vecOrigin", bodyLoc);
			float vec[3];
			MakeVectorFromPoints(eyePos, bodyLoc, vec);
			if (GetVectorLength(vec) > g_cReviveDist.FloatValue) {
				
				if (g_hReviving[client] != null) {
					ClearReviveStuff(client, " \x06[Revive] \x01You have moved too far away from your target reviving stopped.");
				}
				return Plugin_Continue;
			}
			
			int owner = GetEntPropEnt(aim, Prop_Send, "m_hOwnerEntity");
			if (IsValidClient(owner))
			{
				switch(g_cReviveLimitMode.IntValue)
				{
					case 1:
					{
						float expire = g_fTimeOfDeath[owner] + g_cReviveLimit.FloatValue;
						float fin = GetGameTime() + g_cReviveTimerDelay.FloatValue;
						if(fin > expire)
						{
							if(!g_bLimitReach[client])
								PrintToChat(client, " \x06[Revive] \x01You will not be able to revive \x04%N \x01in time.", owner);
							g_bLimitReach[client] = true;
							return Plugin_Continue;
						}
					}
					case 2:
					{
						if(g_iReviveCount[owner] >= g_cReviveLimit.IntValue)
						{
							if(!g_bLimitReach[client])
								PrintToChat(client, " \x06[Revive] \x04%N has hit the maximum amount of times he could be revived this round.", owner);
							g_bLimitReach[client] = true;
							return Plugin_Continue;
						}
					}
				}
				if (((g_cReviveMode.IntValue == 1 && GetClientTeam(owner) == GetClientTeam(client)) || g_cReviveMode.IntValue == 0) && (GetGameTime() - g_fLastRevive[client] >= g_cReviveDelay.FloatValue) && g_hReviving[client] == null)
				{
					bool canRevive = false;
					if(g_cReviveTeam.IntValue == GetClientTeam(owner) || g_cReviveTeam.IntValue == 0){
						canRevive = true;
					}
					if(!canRevive)
						return Plugin_Continue;
					g_iRevivingTarget[client] = aim;
					g_hReviving[client] = CreateTimer(g_cReviveTimerDelay.FloatValue, Timer_Revive, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
					SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
					SetEntProp(client, Prop_Send, "m_iProgressBarDuration", g_cReviveTimerDelay.IntValue);
					PrintToChat(client, " \x06[Revive] \x01You have started to revive \x04%N\x01.", owner);
				}
			}
		}
	}
	return Plugin_Continue;
}

public void ClearReviveStuff(int client, const char[] format, any ...)
{
	if(g_hReviving[client] != null){
		CloseHandle(g_hReviving[client]);
		g_hReviving[client] = null;
	}
	g_iRevivingTarget[client] = -1;
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime()-g_cReviveTimerDelay.FloatValue);
	SetEntProp(client, Prop_Send, "m_iProgressBarDuration", 0);
	char sBuffer[128];
	VFormat(sBuffer, sizeof(sBuffer), format, 3);
	PrintToChat(client, sBuffer);
}

public Action Timer_Revive(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client))
		return Plugin_Handled;
	g_hReviving[client] = null;
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime()-g_cReviveTimerDelay.FloatValue);
	SetEntProp(client, Prop_Send, "m_iProgressBarDuration", 0);
	
	int ent = g_iRevivingTarget[client];
	g_iRevivingTarget[client] = -1;
	if (!IsValidEntity(ent))
		return Plugin_Handled;
	
	int aim = GetClientAimTarget(client, false);
	if (ent != aim)
		return Plugin_Handled;
	
	float eyePos[3];
	GetClientEyePosition(client, eyePos);
	float bodyLoc[3];
	GetEntPropVector(ent, Prop_Data, "m_vecOrigin", bodyLoc);
	float vec[3];
	MakeVectorFromPoints(eyePos, bodyLoc, vec);
	if (GetVectorLength(vec) > g_cReviveDist.FloatValue) {
		PrintToChat(client, " \x06[Revive] \x01You have moved too far away from your target reviving stopped.");
		return Plugin_Handled;
	}
	
	int target = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
	if (!IsValidClient(target))
		return Plugin_Handled;
	
	switch (g_cReviveCostMode.IntValue)
	{
		case 1:
		{
			int cost = g_cReviveCost.IntValue;
			int health = GetClientHealth(client);
			if (health - cost > 0)
			{
				SetEntityHealth(client, health - cost);
				PrintToChat(client, " \x06[Revive] \x01You have been charged \x02%d\x01hp to revive \x04%N\x01.", cost, target);
			} else {
				PrintToChat(client, " \x06[Revive] \x01You do not have enough health to revive \x04%N\x01.", target);
				return Plugin_Handled;
			}
		}
		case 2:
		{
			int cost = g_cReviveCost.IntValue;
			int money = GetEntData(client, g_iAccount);
			if (money - cost >= 0)
			{
				SetEntData(client, g_iAccount, money - cost);
				PrintToChat(client, " \x06[Revive] \x01You have been charged $\x02%d\x01 to revive \x04%N\x01.", cost, target);
			} else {
				PrintToChat(client, " \x06[Revive] \x01You do not have enough health to revive \x04%N\x01.", target);
				return Plugin_Handled;
			}
		}
		default:
		{
			PrintToChat(client, " \x06[Revive] \x01You have revived \x04%N\x01.", target);
		}
	}
	
	CS_RespawnPlayer(target);
	TeleportEntity(target, bodyLoc, NULL_VECTOR, NULL_VECTOR);
	SetEntityHealth(target, g_cReviveHealth.IntValue);
	g_iReviveCount[target]++;
	if (IsValidEntity(ent))
		AcceptEntityInput(ent, "kill", 0, 0);
	
	g_fLastRevive[client] = GetGameTime();
	PrintToChat(target, " \x06[Revive] \x04%N \x01has revived you.", client);
	return Plugin_Handled;
}

stock bool IsValidClient(int client, bool bots = false)
{
	if (client <= 0 || client > MaxClients)
		return false;
	if (!IsValidEntity(client))
		return false;
	if (!IsClientInGame(client))
		return false;
	if (!IsClientConnected(client))
		return false;
	if (bots && IsFakeClient(client))
		return false;
	return true;
} 