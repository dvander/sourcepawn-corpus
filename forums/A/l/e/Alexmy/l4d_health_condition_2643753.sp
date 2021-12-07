#pragma semicolon 1
#include <sourcemod>
#pragma newdecls required

ConVar sm_info_revive_count;
ConVar sm_info_incapacitated;
ConVar sm_info_going_to_die;
ConVar sm_info_health_buffer;

bool speed[MAXPLAYERS + 1];
bool GoingToDie[MAXPLAYERS + 1];
bool isIncapacitated[MAXPLAYERS + 1];
bool currentReviveCount[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "[L4D] Health Condition", 
	author = "AlexMy", 
	description = "", 
	version = "1.0",
	url = "https://forums.alliedmods.net/index.php"
};

public void OnPluginStart()
{
	LoadTranslations("health_condition.phrases");
	
	sm_info_revive_count  = CreateConVar("sm_info_revive_count",  "2", "Черно-Белый экран 0:Выкл. 1:Chat. 2:HintText", 0, true, 1.0, true, 2.0);
	sm_info_incapacitated = CreateConVar("sm_info_incapacitated", "2", "Выведен из строя  0:Выкл. 1:Chat. 2:HintText", 0, true, 1.0, true, 2.0);
	sm_info_going_to_die  = CreateConVar("sm_info_going_to_die",  "2", "Угроза жизни      0:Выкл. 1:Chat. 2:HintText", 0, true, 1.0, true, 2.0);
	sm_info_health_buffer = CreateConVar("sm_info_health_buffer", "2", "Хромает           0:Выкл. 1:Chat. 2:HintText", 0, true, 1.0, true, 2.0);
	
	AutoExecConfig(true, "l4d_health_Condition"); 
	
	HookEvent("player_hurt",    eventPlayerHurt);
	HookEvent("heal_success",   eventHealSuccess);
	HookEvent("revive_success", eventReviveSuccess);
	
	HookEvent("round_start",    eventResetBool);
	HookEvent("round_end",      eventResetBool);
	HookEvent("map_transition", eventResetBool);
	HookEvent("mission_lost",   eventResetBool); 
}

public Action eventReviveSuccess(Event event, const char [] name, bool dontBroadcast)
{
	isIncapacitated[GetClientOfUserId(event.GetInt("subject"))] = false;
	isIncapacitated[event.GetBool("ledge_hang")] = false;
}
public Action eventHealSuccess(Event event, const char [] name, bool dontBroadcast)
{
	reset_bool(GetClientOfUserId(event.GetInt("subject")));
}
public Action eventResetBool(Event event, const char [] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++) if (IsClientInGame(i)) reset_bool(i);
}
stock void reset_bool(int client)
{
	speed[client] = false, GoingToDie[client] = false, isIncapacitated[client] = false, currentReviveCount[client] = false;
}

public Action eventPlayerHurt(Event event, const char [] name, bool dontBroadcast)
{
	int target = GetClientOfUserId(event.GetInt("userid"));
	if(IsClientInGame(target) && GetClientTeam(target) == 2 && IsPlayerAlive(target))
	{
		if(!currentReviveCount[target])
		{
			if(GetEntProp(target, Prop_Send, "m_currentReviveCount") == 2)
			{
				currentReviveCount[target] = true;
				if(GetConVarInt(sm_info_revive_count) == 1) PrintToChatAll("%t", "black_white", target);
				else if(GetConVarInt(sm_info_revive_count) == 2) PrintHintTextToAll("%t", "black_white", target);
			}
		}
		if(!isIncapacitated[target])
		{
			if(GetEntProp(target, Prop_Send, "m_isIncapacitated") == 1)
			{
				isIncapacitated[target] = true;
				if(GetConVarInt(sm_info_incapacitated) == 1) PrintToChatAll("%t", "incapacitated", target);
				else if(GetConVarInt(sm_info_incapacitated) == 2) PrintHintTextToAll("%t", "incapacitated", target);
			}
		}
		if(!GoingToDie[target]) 
		{
			if(GetEntProp(target, Prop_Send, "m_isGoingToDie") == 1)
			{
				GoingToDie[target] = true;
				if(GetConVarInt(sm_info_going_to_die) == 1) PrintToChatAll("%t", "isGoingToDie", target);
				else if(GetConVarInt(sm_info_going_to_die) == 2) PrintHintTextToAll("%t", "isGoingToDie", target);
			}
		}
		if(!speed[target])
		{
			if(GetEntPropFloat(target, Prop_Send, "m_flMaxspeed") == 150.0)
			{
				speed[target] = true;
				if(GetConVarInt(sm_info_health_buffer) == 1) PrintToChatAll("%t", "limp", target);
				else if(GetConVarInt(sm_info_health_buffer) == 2) PrintHintTextToAll("%t", "limp", target);
			}
		}
	}	
}
