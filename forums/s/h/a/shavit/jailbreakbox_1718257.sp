#include <sourcemod>
#include <sdkhooks>
#include <cstrike>
#include <hosties>
#include <lastrequest>

#pragma semicolon 1

#define PLUGIN_VERSION "1.5"

new Handle:gH_Enabled = INVALID_HANDLE;

new bool:gB_Enabled;
new bool:gB_Boxing;

new gI_LastUsed[MAXPLAYERS+1];

new Handle:gH_Cvars[7] = {INVALID_HANDLE, ...};

public Plugin:myinfo = 
{
	name = "Jailbreak Box",
	author = "shavit",
	description = "Oh my god they're boxing in Jailbreak",
	version = PLUGIN_VERSION
}

public OnPluginStart()
{
	CreateConVar("sm_box_version", PLUGIN_VERSION, "Jailbreak Box version", FCVAR_PLUGIN|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	
	gH_Enabled = CreateConVar("sm_box_enabled", "1", "Enable this plugin functionality?", FCVAR_PLUGIN);
	gB_Enabled = true;
	HookConVarChange(gH_Enabled, OnConvarChanged);
	
	HookEvent("round_end", Round_End);
	
	RegConsoleCmd("sm_box", Command_Box, "Toggle Jailbreak Box status, available for admins/CTs.");
	
	AutoExecConfig(true, "jailbreakbox");
	
	gH_Cvars[0] = FindConVar("ff_damage_reduction_bullets");
	gH_Cvars[1] = FindConVar("ff_damage_reduction_grenade");
	gH_Cvars[2] = FindConVar("ff_damage_reduction_grenade_self");
	gH_Cvars[3] = FindConVar("ff_damage_reduction_other");
	gH_Cvars[4] = FindConVar("mp_friendlyfire");
	gH_Cvars[5] = FindConVar("mp_autokick");
	gH_Cvars[6] = FindConVar("mp_tkpunish");
}

public OnAvailableLR(Announced)
{
	if(gB_Boxing)
	{
		gB_Boxing = false;
		
		for(new i; i <= MaxClients; i++)
		{
			if(IsValidClient(i))
			{
				PrintToConsole(i, "Jailbreak Box has automatically disabled due to an LR.");
			}
		}
	}
	
	if(gB_Enabled)
	{
		Disable();
	}
}

public OnConvarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(cvar == gH_Enabled)
	{
		gB_Enabled = bool:StringToInt(newVal);
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	gI_LastUsed[client] = 0;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(gB_Enabled && gB_Boxing)
	{
		if(IsValidClient(attacker) && IsValidClient(victim, true))
		{
			if(attacker != victim && GetClientTeam(attacker) == 3 && GetClientTeam(victim) == 3)
			{
				damage = 0.0;
				
				return Plugin_Changed;
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:Round_End(Handle:event, const String:name[], bool:dB)
{
	gB_Boxing = false;
	
	if(gB_Enabled)
	{
		Disable();
	}
	
	return Plugin_Continue;
}

public Action:Command_Box(client, args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Handled;
	}
	
	if(!HasAccess(client))
	{
		ReplyToCommand(client, "\x04[Box]\x01 This command is available for \x05admins \x01and \x05alive prison guards\x01.");
		
		return Plugin_Handled;
	}
	
	new Time = GetTime();
	
	if(Time - gI_LastUsed[client] < 15)
	{
		ReplyToCommand(client, "\x04[Box]\x01 You can't spam this command, time left - \x05[%d/15]\x01.", Time - gI_LastUsed[client]);
		
		return Plugin_Handled;
	}
	
	gI_LastUsed[client] = Time;
	
	new Handle:menu = CreateMenu(MenuHandler_Box, MENU_ACTIONS_ALL);
	SetMenuTitle(menu, "Jailbreak Box:");
	
	AddMenuItem(menu, "on", "Enable");
	AddMenuItem(menu, "off", "Disable");
	
	SetMenuExitButton(menu, true);
	
	DisplayMenu(menu, client, 20);
	
	return Plugin_Handled;
}

public MenuHandler_Box(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(!HasAccess(param1))
			{
				PrintToChat(param1, "\x04[Box]\x01 This command is available for \x05admins \x01and \x05alive prison guards\x01.");
				
				return 0;
			}
			
			new String:info[8];
			GetMenuItem(menu, param2, info, 8);
			
			new bool:enabled = StrEqual(info, "on");
			
			enabled? Enable():Disable();
			
			PrintToChatAll("\x04[Box]\x01 Jailbreak Box has been \x05%sabled\x01.", enabled? "en":"dis");
		}
		
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
	
	return 0;
}

void:Enable()
{
	for(new i; i < sizeof(gH_Cvars); i++)
	{
		if(gH_Cvars[i] != INVALID_HANDLE)
		{
			SetConVarBool(gH_Cvars[i], (i <= 4)? true:false);
		}
	}
}

void:Disable()
{
	for(new i; i < sizeof(gH_Cvars); i++)
	{
		if(gH_Cvars[i] != INVALID_HANDLE)
		{
			SetConVarBool(gH_Cvars[i], (i <= 4)? false:true);
		}
	}
}

stock bool:HasAccess(client)
{
	if(CheckCommandAccess(client, "jailbreakbox", ADMFLAG_SLAY))
	{
		return true;
	}
	
	if(GetClientTeam(client) == CS_TEAM_CT && IsPlayerAlive(client))
	{
		return true;
	}
	
	return false;
}

stock bool:IsValidClient(client, bool:alive = false)
{
	if(client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && (alive == false || IsPlayerAlive(client)))
	{
		return true;
	}
	
	return false;
}
