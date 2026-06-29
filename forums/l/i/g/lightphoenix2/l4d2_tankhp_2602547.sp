#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "2.0"
native int LMC_GetClientOverlayModel(int iClient);
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY

new Float:MaxHealth[MAXPLAYERS+1];
new bool:CheckHealth[MAXPLAYERS+1];
new Float:TankID[MAXPLAYERS+1];
ConVar TankAnnounce, TankGauge, LogTankKills;
int TH_iHint, totaltank=0, tankkilled = 0;
bool TH_CvarAllow, tankalive, TH_Logging;
public Plugin:myinfo = 
{
	name = "[L4D2] Tank health gauge",
	author = "Lightphoenix2, Orignal: ztar",
	description = "Show Tank's health bar. Multitank is also supported.",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	TankAnnounce =		CreateConVar(	"l4d2_tankhp_announce",			"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS);
	TankGauge	 =		CreateConVar(	"l4d2_tankhp_gaugetype",			"1",			"0=Center text, 1=Hint text.", CVAR_FLAGS);
	LogTankKills =		CreateConVar(	"l4d2_tank_logging",			"1",			"0=no display on server, 1=on Logging.", CVAR_FLAGS);
	CreateConVar("l4d2_tankhp",	PLUGIN_VERSION, "Tank Hp plugin version.", CVAR_FLAGS|FCVAR_DONTRECORD);
	AutoExecConfig(true,"l4d2_tankhp");
	
	TankAnnounce.AddChangeHook(ConVarChanged_Cvars);
	TankGauge.AddChangeHook(ConVarChanged_Cvars);
	LogTankKills.AddChangeHook(ConVarChanged_Cvars);
	GetCvars();
	
	HookEvent("tank_spawn", Event_Tank_Spawn);
	HookEvent("tank_killed", Event_Tank_Killed);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	int client = attacker;
	int target = victim;
	
	if(client <= 0 || client > GetMaxClients())
		return Plugin_Continue;
	if(target <= 0 || target > GetMaxClients())
		return Plugin_Continue; 
	
	/* Notify Tank health */
	if(GetEntProp(target, Prop_Send, "m_zombieClass") == 8 && TH_CvarAllow && IsPlayerAlive(client))
	{
		new i, j;
		new Float:Health = float(GetClientHealth(target));	
		decl String:HealthBar[80+1];
		new Float:GaugeNum = ((Health / MaxHealth[target]) * 100.0)*0.8;		
		for(i=0; i<80; i++)
			HealthBar[i] = '|';
		for(j=RoundToCeil(GaugeNum); j<80; j++)
			HealthBar[j] = ' ';
		HealthBar[80] = '\0';
		if(Health <= 4500.0)
			CheckHealth[target] = true;
		if(Health >= 4501 && CheckHealth[target])
		{
			Health = 0.0;
			HealthBar = " ";
		}
		if(tankalive  && Health <= MaxHealth[target])
		{
			if(totaltank > 1)
			{
				if(TH_iHint == 0)
					PrintCenterTextAll("(%d) TANK %4.0f/%4.0f  %s",RoundToZero(TankID[target]), Health, MaxHealth[target], HealthBar);
				else
					PrintHintTextToAll("(%d) TANK %4.0f/%4.0f  %s",RoundToZero(TankID[target]) ,Health, MaxHealth[target], HealthBar);
			}
			else
			{
				/* Gauge type(0:Center 1:Hint) */
				if(TH_iHint == 0)
					PrintCenterTextAll("TANK %4.0f/%4.0f  %s", Health, MaxHealth[target], HealthBar);
				else
					PrintHintTextToAll("TANK %4.0f/%4.0f  %s", Health, MaxHealth[target], HealthBar);
			}
		}
	}
	return Plugin_Continue;
}  

public Action Event_Tank_Spawn(Event event, const char[] name, bool:dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsClientInGame(client) || !IsValidEntity(client))
		return Plugin_Continue;
	
	/* Get MAX health of Tank */
	if(GetEntProp(client, Prop_Send, "m_zombieClass") == 8 && IsPlayerAlive(client))
	{
		CreateTimer(0.1, GetTankHealth, client, TIMER_FLAG_NO_MAPCHANGE);
		tankalive = true;
		TankID[client] = float(totaltank++);
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
	return Plugin_Continue;
}

public Action Event_Tank_Killed(Event event, const char[] name, bool:dontBroadcast)
{
	if(totaltank <= 0)
	{
		tankalive = false;
		totaltank = 0;
	}
	else
	{
		totaltank--;
		tankkilled++;
	}
	if(TH_CvarAllow && totaltank <= 0)
	{
		if(tankkilled > 1)
		{
			PrintHintTextToAll("%d TANKS KILLED", tankkilled);
		}
		else
		{
			PrintHintTextToAll("TANK KILLED");
		}
		if(TH_Logging)
		{
			PrintToServer("%d Tanks Killed", tankkilled);
		}
		tankkilled = 0;
	}
	return Plugin_Continue; 
}

public Action GetTankHealth(Handle timer, any client)
{
	if(IsValidEntity(client) && IsClientInGame(client))
	{
		MaxHealth[client] = float(GetClientHealth(client));
		CheckHealth[client] = false;
	}
	return Plugin_Stop;
}

// ====================================================================================================
//					CVARS
// ====================================================================================================
public void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

GetCvars()
{
	TH_CvarAllow = TankAnnounce.BoolValue;
	TH_iHint = TankGauge.IntValue;
	TH_Logging = LogTankKills.BoolValue;
}
