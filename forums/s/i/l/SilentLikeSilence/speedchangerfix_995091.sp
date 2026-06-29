/*-----------------------------------------------/
 G L O B A L  S T U F F
------------------------------------------------*/
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.1"

#define SCOUT_SPEED "400.0"
#define SOLDIER_SPEED "240.0"
#define PYRO_SPEED "300.0"
#define DEMOMAN_SPEED "280.0"
#define HEAVY_SPEED "230.0"
#define ENGINEER_SPEED "300.0"
#define MEDIC_SPEED "320.0"
#define SNIPER_SPEED "300.0"
#define SPY_SPEED "300.0"

new Handle:scout;
new Handle:soldier;
new Handle:pyro;
new Handle:demoman;
new Handle:heavy;
new Handle:engineer;
new Handle:medic;
new Handle:sniper;
new Handle:spy;
new Handle:adminOnly;
new Handle:enabled;

new Handle:g_hSpeedTimer[MAXPLAYERS +1] = INVALID_HANDLE;

/*-----------------------------------------------/
 P L U G I N  I N F O
------------------------------------------------*/
public Plugin:myinfo = 
{
	name = "[TF2] Speed Changer",
	author = "noodleboy347",
	description = "Allows admins to set the speed of each class",
	version = PLUGIN_VERSION,
	url = "http://www.frozencubes.com"
}
/*-----------------------------------------------/
 P L U G I N  S T A R T
------------------------------------------------*/
public OnPluginStart()
{
	scout = CreateConVar("sm_speed_scout", SCOUT_SPEED, "Speed for Scouts");
	soldier = CreateConVar("sm_speed_soldier", SOLDIER_SPEED, "Speed for Soldiers");
	pyro =CreateConVar("sm_speed_pyro", PYRO_SPEED, "Speed for Pyros");
	demoman = CreateConVar("sm_speed_demoman", DEMOMAN_SPEED, "Speed for Demomen");
	heavy = CreateConVar("sm_speed_heavy", HEAVY_SPEED, "Speed for Heavies");
	engineer = CreateConVar("sm_speed_engineer", ENGINEER_SPEED, "Speed for Engineers");
	medic = CreateConVar("sm_speed_medic", MEDIC_SPEED, "Speed for Medics");
	sniper = CreateConVar("sm_speed_sniper", SNIPER_SPEED, "Speed for Snipers");
	spy = CreateConVar("sm_speed_spy", SPY_SPEED, "Speed for Spies");
	
	adminOnly = CreateConVar("sm_speed_adminonly", "0", "Speed is only changed for admins");
	enabled = CreateConVar("sm_speed_enabled", "1", "Allows speeds to be altered");
	CreateConVar("sm_speed_version", PLUGIN_VERSION, "Speed Changer version");
	
	RegAdminCmd("sm_speed_reset", Command_Reset, ADMFLAG_GENERIC);
	
	HookEvent("player_spawn", Event_Spawn);
	HookEvent("player_spawn", Event_Death);
	
	AutoExecConfig();
}
/*-----------------------------------------------/
 P L A Y E R  S P A W N
------------------------------------------------*/
public Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(enabled) == 1)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		CreateTimer(0.2, Timer_Message, client);
		g_hSpeedTimer[client] = CreateTimer(0.1, Timer_Speed, client, TIMER_REPEAT);
	}
}
/*-----------------------------------------------/
 P L A Y E R  D E A T H
------------------------------------------------*/
public Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(g_hSpeedTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hSpeedTimer[client]);
		g_hSpeedTimer[client] = INVALID_HANDLE;
	}
}
/*-----------------------------------------------/
 M E S S A G E  T I M E R
------------------------------------------------*/
public Action:Timer_Message(Handle:timer, any:client)
{
	if(GetConVarInt(adminOnly) == 0)
	{
		PrintToChat(client, "Your speed was set to %f", GetEntPropFloat(client, Prop_Data, "m_flMaxspeed"))
		LogMessage("%N's speed was set to %f", client, GetEntPropFloat(client, Prop_Data, "m_flMaxspeed"))
	}
	else
	{
		if(GetUserFlagBits(client) & ADMFLAG_GENERIC)
		{
			PrintToChat(client, "Your speed was set to %f", GetEntPropFloat(client, Prop_Data, "m_flMaxspeed"))
			LogMessage("%N's speed was set to %f", client, GetEntPropFloat(client, Prop_Data, "m_flMaxspeed"))
		}
	}
}
/*-----------------------------------------------/
 S P E E D  T I M E R
------------------------------------------------*/
public Action:Timer_Speed(Handle:timer, any:client)
{
	new TFClassType:playerClass = TF2_GetPlayerClass(client);
	if(GetEntProp(client, Prop_Send, "m_nPlayerCond") & 1)
	{
		//Nothing
	}
	else
	{
		if(GetConVarInt(adminOnly) == 0)
		{
			switch(playerClass)
			{
				case TFClass_Scout:
				{
					SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(scout))
				}
				case TFClass_Soldier:
				{
					SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(soldier))
				}
				case TFClass_Pyro:
				{
					SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(pyro))
				}
				case TFClass_DemoMan:
				{
					SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(demoman))
				}
				case TFClass_Heavy:
				{
					SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(heavy))
				}
				case TFClass_Engineer:
				{
					SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(engineer))
				}
				case TFClass_Medic:
				{
					SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(medic))
				}
				case TFClass_Sniper:
				{
					SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(sniper))
				}
				case TFClass_Spy:
				{
					SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(spy))
				}
			}
		}
		else
		{
			if(GetUserFlagBits(client) & ADMFLAG_GENERIC)
			{
				switch(playerClass)
				{
					case TFClass_Scout:
					{
						SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(scout))
					}
					case TFClass_Soldier:
					{
						SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(soldier))
					}
					case TFClass_Pyro:
					{
						SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(pyro))
					}
					case TFClass_DemoMan:
					{
						SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(demoman))
					}
					case TFClass_Heavy:
					{
						SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(heavy))
					}
					case TFClass_Engineer:
					{
						SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(engineer))
					}
					case TFClass_Medic:
					{
						SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(medic))
					}
					case TFClass_Sniper:
					{
						SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(sniper))
					}
					case TFClass_Spy:
					{
						SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(spy))
					}
				}
			}
		}
	}
}
/*-----------------------------------------------/
 R E S E T S P E E D
------------------------------------------------*/
public Action:Command_Reset(client, args)
{
	SetConVarFloat(scout, 400.0);
	SetConVarFloat(soldier, 240.0);
	SetConVarFloat(pyro, 300.0);
	SetConVarFloat(demoman, 280.0);
	SetConVarFloat(heavy, 230.0);
	SetConVarFloat(engineer, 300.0);
	SetConVarFloat(medic, 320.0);
	SetConVarFloat(sniper, 300.0);
	SetConVarFloat(spy, 300.0);
	ReplyToCommand(client, "Restored all class speeds to their default values.")
	LogMessage("Restored all class speeds to their default values.")
	return Plugin_Handled;
}
/*-----------------------------------------------/
 C L I E N T  D I S C O N N E C T
------------------------------------------------*/
public OnClientDisconnect(client)
{
	if(g_hSpeedTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(g_hSpeedTimer[client]);
		g_hSpeedTimer[client] = INVALID_HANDLE;
		LogMessage("%N disconnected. Closing handles...", client)
	}
}