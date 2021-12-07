/*-----------------------------------------------/
 G L O B A L  S T U F F
------------------------------------------------*/
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

new sprint[MAXPLAYERS+1];
new bool:timerExists[MAXPLAYERS+1];
new Handle:HudMessage;
new Handle:enabled;


/*-----------------------------------------------/
 P L U G I N  I N F O
------------------------------------------------*/
public Plugin:myinfo = 
{
	name = "[TF2] Heavy Sprint",
	author = "noodleboy347",
	description = "Allows Heavies to run fast",
	version = PLUGIN_VERSION,
	url = "http://www.frozencubes.com"
}

/*-----------------------------------------------/
 P L U G I N  S T A R T
------------------------------------------------*/
public OnPluginStart()
{
	PrecacheSound("vo/heavy_battlecry03.wav", true)
	PrecacheSound("player/pl_scout_jump1.wav", true)
	RegConsoleCmd("sprint", Command_Sprint)
	enabled = CreateConVar("sm_heavysprint_enable", "1", "Enables the Heavy Sprint plugin")
	CreateConVar("sm_heavysprint_version", PLUGIN_VERSION, "Heavy Sprint version")
	HudMessage = CreateHudSynchronizer();
	HookEvent("player_death", Event_Death)
}
/*-----------------------------------------------/
 E N T E R  S E R V E R
------------------------------------------------*/
public OnClientPutInServer(client)
{
	sprint[client] = 50;
	timerExists[client] = false;
}
/*-----------------------------------------------/
 S P R I N T  C O M M A N D
------------------------------------------------*/
public Action:Command_Sprint(client, args)
{
	if(GetConVarInt(enabled) == 1)
	{
		new TFClassType:playerClass = TF2_GetPlayerClass(client);
		if(timerExists[client] == false)
		{
			if(GetEntProp(client, Prop_Send, "m_nPlayerCond") & 1)
			{
				PrintToChat(client, "\x03You can only sprint when you're not spun up!")
			}
			else
			{
				if(playerClass == TFClass_Heavy)
				{
					if(sprint[client] == 50)
					{
						CreateTimer(0.1, Timer_Sprint, client)
						CreateTimer(2.0, Timer_Yell, client)
						EmitSoundToClient(client, "player/pl_scout_jump1.wav");
					}
					else
					{
						PrintToChat(client, "\x03You don't have enough stamina to sprint!")
					}
				}
				else
				{
					PrintToChat(client, "\x03You have to be a Heavy to sprint!")
				}
			}
		}
	}
	return Plugin_Handled;
}
/*-----------------------------------------------/
 S P R I N T  T I M E R
------------------------------------------------*/
public Action:Timer_Sprint(Handle:hTimer, any:client)
{
	new stamina = sprint[client] * 2
	sprint[client] --;
	if(sprint[client] > 0)
	{
		if(GetEntProp(client, Prop_Send, "m_nPlayerCond") & 1)
		{
			//Nothing
		}
		else
		{
			SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 300.0)
		}
		timerExists[client] = true;
		SetHudTextParams(0.2, 0.92, 0.25, 100, 255, 100, 255);
		ShowSyncHudText(client, HudMessage, "Stamina: %i%", stamina);
		CreateTimer(0.05, Timer_Sprint, client)
	}
	else
	{
		PrintToChat(client, "\x03You are out of stamina!")
		timerExists[client] = false;
		if(GetEntProp(client, Prop_Send, "m_nPlayerCond") & 1)
		{
			SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 80.0)
		}
		else
		{
			SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 230.0)
		}
		CreateTimer(8.0, Timer_Regen, client)
	}
}
/*-----------------------------------------------/
 H E A V Y  Y E L L  T I M E R
------------------------------------------------*/
public Action:Timer_Yell(Handle:hTimer, any:client)
{
	EmitSoundToClient(client, "vo/heavy_battlecry03.wav");
}
/*-----------------------------------------------/
 S T A M I N A  R E G E N E R A T I O N
------------------------------------------------*/
public Action:Timer_Regen(Handle:hTimer, any:client)
{
	sprint[client] = 50;
	PrintToChat(client, "\x03Stamina fully refilled!")
}
/*-----------------------------------------------/
 R E P L E N I S H  S T A M I N A  O N  K I L L
------------------------------------------------*/
public Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	new TFClassType:playerClass = TF2_GetPlayerClass(client);
	if(playerClass == TFClass_Heavy)
	{
		if(sprint[client] < 50)
		{
			sprint[client] = 50;
			PrintToChat(client, "\x03You killed someone! Your stamina was refilled!")
		}
	}
}