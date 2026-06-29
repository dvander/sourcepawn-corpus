#pragma semicolon 1
#include <sourcemod>
#pragma newdecls required

#include <sdktools_functions> 

char TankName[32];
char NameArsonist[32];

bool lock;

public Plugin myinfo = 
{
	name = "[L4D] Extinguishing Tank",
	author = "AlexMy",
	description = "",
	version = "1.0",
	url = "https://forums.alliedmods.net/showthread.php?t=306726"
};

public void OnPluginStart()
{
	HookEvent("zombie_ignited", EventZombieIgnited, EventHookMode_Post);
}

public void OnMapStart()
{
	SetConVarInt(FindConVar("tank_burn_duration_expert"), 999999);
	SetConVarInt(FindConVar("tank_burn_duration_hard"),   999999);
	SetConVarInt(FindConVar("tank_burn_duration_normal"), 999999);
	SetConVarInt(FindConVar("z_tank_burning_lifetime"),   999999);
}

public void EventZombieIgnited(Event event, const char[] name, bool dontBroadcast)
{
	int client =  GetClientOfUserId(event.GetInt("userid"));
	int tank = event.GetInt("entityid");
	if(!client == !tank)
	{
		GetClientName(client, NameArsonist, sizeof(NameArsonist));
		GetEntPropString(tank, Prop_Data, "m_ModelName", TankName, sizeof(TankName));
		if (StrContains(TankName, "hulk") != -1)
		{
			ExtinguishEntity(tank);
			if(!lock) 
			
			PrintToChatAll("%s пытался поджечь Танка. Танк потушен!!!", NameArsonist);
			lock = true;
		}
		CreateTimer(10.0, Reset, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Reset(Handle timer)
{
	lock = false;
	return Plugin_Stop;
}
