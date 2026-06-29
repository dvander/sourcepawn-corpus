#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PL_VERSION "1.0.1"

new Handle:g_hLiveVoiceRadius = INVALID_HANDLE;
new Handle:g_hLiveHearDeadPlayers = INVALID_HANDLE;
new Handle:g_hLiveHearAllTalk = INVALID_HANDLE;

new Handle:g_hDeadVoiceRadius = INVALID_HANDLE;
new Handle:g_hDeadHearLivePlayers = INVALID_HANDLE;
new Handle:g_hDeadHearAllTalk = INVALID_HANDLE;

new Float:g_liveVoiceRadius = 1000.0;
new bool:g_liveHearDeadPlayers = false;
new bool:g_liveHearAllTalk = true;

new Float:g_deadVoiceRadius = 1000.0;
new bool:g_deadHearLivePlayers = true;
new bool:g_deadHearAllTalk = false;

public Plugin:myinfo =
{
    name        = "Voice Radius",
    author      = "alongub",
    description = "Forces voice communication only to players within a certain radius of the person who is speaking.",
    version     = PL_VERSION,
    url         = "http://steamcommunity.com/id/alon"
};

public OnPluginStart() 
{
	g_hLiveVoiceRadius = CreateConVar("sm_voiceradius_live_distance", "1000", "Sets the distance voices can be transmitted between alive players", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hLiveHearDeadPlayers = CreateConVar("sm_voiceradius_live_heardeadplayers", "0", "Sets whether live players can hear dead players", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hLiveHearAllTalk = CreateConVar("sm_voiceradius_live_alltalk", "1", "Sets whether live players can hear the opposite team players", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hDeadVoiceRadius = CreateConVar("sm_voiceradius_dead_distance", "1000", "Sets the distance voices can be transmitted between dead players", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hDeadHearLivePlayers = CreateConVar("sm_voiceradius_dead_hearliveplayers", "1", "Sets whether dead players can hear live players", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hDeadHearAllTalk = CreateConVar("sm_voiceradius_dead_alltalk", "0", "Sets whether live players can hear the opposite team players", FCVAR_PLUGIN|FCVAR_NOTIFY);
	
	HookConVarChange(g_hLiveVoiceRadius, Action_OnSettingsChange);
	HookConVarChange(g_hLiveHearDeadPlayers, Action_OnSettingsChange);
	HookConVarChange(g_hLiveHearAllTalk, Action_OnSettingsChange);
	HookConVarChange(g_hDeadVoiceRadius, Action_OnSettingsChange);
	HookConVarChange(g_hDeadHearLivePlayers, Action_OnSettingsChange);	
	HookConVarChange(g_hDeadHearAllTalk, Action_OnSettingsChange);	
	
	AutoExecConfig(true);
	
	CreateTimer(0.2, Timer_UpdateListeners, _, TIMER_REPEAT);
}

public Action_OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if (cvar == g_hLiveVoiceRadius)
		g_liveVoiceRadius = Float:StringToFloat(newvalue);
	else if (cvar == g_hLiveHearDeadPlayers)
		g_liveHearDeadPlayers = bool:StringToInt(newvalue);
	else if (cvar == g_hLiveHearAllTalk)
		g_liveHearAllTalk = bool:StringToInt(newvalue);	
	else if (cvar == g_hDeadVoiceRadius)
		g_deadVoiceRadius = Float:StringToFloat(newvalue);
	else if (cvar == g_hDeadHearLivePlayers)
		g_deadHearLivePlayers = bool:StringToInt(newvalue);
	else if (cvar == g_hDeadHearAllTalk)
		g_deadHearAllTalk = bool:StringToInt(newvalue);	
}

public Action:Timer_UpdateListeners(Handle:timer) 
{
	for (new receiver = 1; receiver <= MaxClients; receiver++)
	{
		if (!IsClientInGame(receiver))
			continue;
			
		for (new sender = 1; sender <= MaxClients; sender++)
		{
			if (!IsClientInGame(sender))
				continue;
				
			if (sender == receiver)
				continue;
							
			new Float:distance = 0.0;
			new cont = true;
		
			if (IsPlayerAlive(receiver))
			{
				if (IsPlayerAlive(sender))
				{
					if (g_liveHearAllTalk)
						distance = g_liveVoiceRadius;
					else
						if (GetClientTeam(receiver) == GetClientTeam(sender))
							distance = g_liveVoiceRadius;
						else
							cont = false;
				}
				else
				{
					if (g_liveHearDeadPlayers)
					{
						if (g_liveHearAllTalk)
							distance = g_liveVoiceRadius;
						else
							if (GetClientTeam(receiver) == GetClientTeam(sender))
								distance = g_liveVoiceRadius;
							else
								cont = false;
					}
					else
						cont = false;
				}
			}
			else
			{
				if (IsPlayerAlive(sender))
				{
					if (g_deadHearLivePlayers)
					{
						if (g_deadHearAllTalk)
							distance = g_deadVoiceRadius;
						else
							if (GetClientTeam(receiver) == GetClientTeam(sender))
								distance = g_deadVoiceRadius;
							else
								cont = false;									
					}
					else
						cont = false;
				}
				else
				{
					if (g_deadHearAllTalk)
						distance = g_deadVoiceRadius;
					else
						if (GetClientTeam(receiver) == GetClientTeam(sender))
							distance = g_deadVoiceRadius;
						else
							cont = false;	 
				}
			}
			
			if (cont)
			{
				if (distance != 0)
					SetListenOverride(receiver, sender, (GetEntitiesDistance(receiver, sender) > distance) ? Listen_No : Listen_Yes);
			}
			else
			{
				SetListenOverride(receiver, sender, Listen_No);
			}
		}
	}
}

stock Float:GetEntitiesDistance(ent1, ent2)
{
	new Float:orig1[3];
	GetEntPropVector(ent1, Prop_Send, "m_vecOrigin", orig1);
	
	new Float:orig2[3];
	GetEntPropVector(ent2, Prop_Send, "m_vecOrigin", orig2);

	return GetVectorDistance(orig1, orig2);
} 