#include <sourcemod>
#include <cstrike>
#include <sdkhooks>
#include <sdktools>

#pragma newdecls required

#define PLUGIN_VERSION "1.1"

public Plugin myinfo = 
{
	name = "[CS:GO] Start Health Manager",
	author = "Eyal282",
	description = "Sets each team's starting health on player spawn, by VIP.",
	version = PLUGIN_VERSION,
	url = "N/A"
}

Handle hcv_SetMaxHealth = INVALID_HANDLE;
Handle hcv_HealthT = INVALID_HANDLE;
Handle hcv_HealthCT = INVALID_HANDLE;
Handle hcv_HealthTVIP = INVALID_HANDLE;
Handle hcv_HealthCTVIP = INVALID_HANDLE;
Handle hcv_VIPCommand = INVALID_HANDLE;

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	
	hcv_SetMaxHealth = CreateConVar("sm_max_health_set", "1", "1 = Set max health. 0 = just set health. -1 = set neither. 1 will allow players to heal back above or below 100");
	hcv_HealthT = CreateConVar("sm_max_health_t", "200", "Amount of HP the T start with.");
	hcv_HealthCT = CreateConVar("sm_max_health_ct", "200", "Amount of HP the CT start with.")
	hcv_HealthTVIP = CreateConVar("sm_max_health_t_vip", "200", "Amount of HP a VIP T start with.");
	hcv_HealthCTVIP = CreateConVar("sm_max_health_ct_vip", "200", "Amount of HP a VIP CT start with.")
	hcv_VIPCommand = CreateConVar("sm_vip_command", "sm_vip", "If a player has access to this command, he is VIP.");
	
	AutoExecConfig();
}

public Action Event_PlayerSpawn(Handle hEvent, const char[] Name, bool dontBroadcast)
{
	int UserId = GetEventInt(hEvent, "userid");
	
	RequestFrame(Frame_SetHP, UserId);
}

public void Frame_SetHP(int UserId)
{
	int client = GetClientOfUserId(UserId);
	
	if(client == 0)
		return;
		
	else if(GetConVarInt(hcv_SetMaxHealth) == -1)
		return;
	
	
	int HP;
	
	char sValue[64];
	GetConVarString(hcv_VIPCommand, sValue, sizeof(sValue));
	
	bool bVIP;
	
	bVIP = CheckCommandAccess(client, sValue, ADMFLAG_CUSTOM2);
	
	switch(GetClientTeam(client))
	{
		case CS_TEAM_CT:
		{	
			if(bVIP)
				HP = GetConVarInt(hcv_HealthCTVIP);
				
			else
				HP = GetConVarInt(hcv_HealthCT);
		}
		case CS_TEAM_T:
		{	
			if(bVIP)
				HP = GetConVarInt(hcv_HealthTVIP);
				
			else
				HP = GetConVarInt(hcv_HealthT);
		}
	}
		
	SetEntityHealth(client, HP);
	
	if(GetConVarInt(hcv_SetMaxHealth) == 1)
	{
		SetEntityMaxHealth(client, HP);
	}
}
stock void SetEntityMaxHealth(int client, int amount)
{
	SetEntProp(client, Prop_Data, "m_iMaxHealth", amount);
}

stock int GetEntityMaxHealth(int client)
{
	return GetEntProp(client, Prop_Data, "m_iMaxHealth");
}

stock int GetEntityHealth(int client)
{
	return GetEntProp(client, Prop_Data, "m_iHealth");
}