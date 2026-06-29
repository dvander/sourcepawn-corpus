#pragma semicolon 1
#include <sourcemod>
#pragma newdecls required

ConVar l4dConVarBoss; 
ConVar l4dConVarSurvivor; 
ConVar l4dConVarBossRenderNormal;

char s_ModelName[64]; 
char ModelName[64];

public Plugin myinfo = 
{
	name = "[L4D] attacking ghost",
	author = "AlexMy",
	description = "",
	version ="2.0",
	url = "https://forums.alliedmods.net/showthread.php?p=2413502",
}

public void OnPluginStart()
{
	l4dConVarBoss             = CreateConVar("l4dConVarBoss",             "10", "Прозрачность при атаке босса.",              0, true, 0.0, true, 255.0);
	l4dConVarSurvivor         = CreateConVar("l4dConVarSurvivor",         "10", "Прозрачность когда босс атакует.",           0, true, 0.0, true, 255.0);
	l4dConVarBossRenderNormal = CreateConVar("l4dConVarBossRenderNormal", "255","Прозрачность босса после завершение атаке.", 0, true, 0.0, true, 255.0);
	
	HookEvent("choke_start",              Event_TongueStart,  EventHookMode_Post);
	HookEvent("lunge_pounce",             Event_TongueStart,  EventHookMode_Post);
	
	HookEvent("choke_end",                Event_TongueTheEnd, EventHookMode_Post); 
	HookEvent("choke_stopped",            Event_TongueTheEnd, EventHookMode_Post); 
	HookEvent("tongue_pull_stopped",      Event_TongueTheEnd, EventHookMode_Post); 
	HookEvent("tongue_broke_bent",        Event_TongueTheEnd, EventHookMode_Post);  
	HookEvent("tongue_broke_victim_died", Event_TongueTheEnd, EventHookMode_Post);
	HookEvent("pounce_end",               Event_TongueTheEnd, EventHookMode_Post);
	HookEvent("pounce_stopped",           Event_TongueTheEnd, EventHookMode_Post);
	
	AutoExecConfig(true, "l4d_attacking ghost");
}

public void Event_TongueStart(Event event, const char[] name, bool dontBroadcast)
{
	int userid = GetClientOfUserId(event.GetInt("userid"));
	int victim = GetClientOfUserId(event.GetInt("victim"));
	{
		if(!userid == !victim)
		{
			GetClientName(userid, s_ModelName, sizeof(s_ModelName));
			GetClientName(victim, ModelName, sizeof(ModelName));
			PrintToChatAll("%s атакует персонажа %s.", s_ModelName, ModelName);
			SetEntityRenderMode(userid, RENDER_TRANSALPHA);
			SetEntityRenderColor(userid, 255, 255, 255, GetConVarInt(l4dConVarBoss));
			SetEntityRenderMode(victim, RENDER_TRANSALPHA);
			SetEntityRenderColor(victim, 255, 255, 255, GetConVarInt(l4dConVarSurvivor));
			Glow_Invisibility ();
		}
	}
}

stock void Glow_Invisibility()
{
	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i))
	{
		ClientCommand(i, "cl_glow_survivor_hurt_g 0.0");
		ClientCommand(i, "cl_glow_survivor_hurt_r 0.0");
		ClientCommand(i, "cl_glow_ability_r 0.0");
	}
}

public void Event_TongueTheEnd(Event event, const char[] name, bool dontBroadcast)
{
	int userid = GetClientOfUserId(event.GetInt("userid"));
	int victim = GetClientOfUserId(event.GetInt("victim"));
	{
		if((userid > 0) && (victim > 0) && GetClientTeam(victim) == 2 && GetClientTeam(userid) == 3)
		{
			GetClientName(userid, s_ModelName, sizeof(s_ModelName));
			GetClientName(victim, ModelName, sizeof(ModelName));
			PrintToChatAll("Персонаж %s спасен(а) от %s.", ModelName, s_ModelName);
			SetEntityRenderMode(userid, RENDER_NORMAL);
			SetEntityRenderColor(userid, 255, 255, 255, GetConVarInt(l4dConVarBossRenderNormal));
			SetEntityRenderMode(victim, RENDER_NORMAL);
			SetEntityRenderColor(victim, 255, 255, 255, 255);
			Glow_Reset();
		}
	}
}

stock void Glow_Reset()
{
	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i))
	{
		ClientCommand(i, "cl_glow_survivor_hurt_g 0.4");
		ClientCommand(i, "cl_glow_survivor_hurt_r 1.0");
		ClientCommand(i, "cl_glow_ability_r 1.0");
	}
}