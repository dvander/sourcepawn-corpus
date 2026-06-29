#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "1.1"

new Handle:timer = INVALID_HANDLE;
new bool:enabled;
new iTimer;
new iEnt;
new String:EntityList[][] = {"func_door", "func_movelinear", "func_door_rotating"};

public Plugin:myinfo = 
{
	name = "Advanced Jailbreak Hide and Seek",
	author = "TimeBomb",
	description = "Advanced Jailbreak Hide and Seek.",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	RegAdminCmd("sm_hns", HnsCommand, ADMFLAG_GENERIC, "HNS Menu");
	HookEvent("round_start", OnRoundStart);
	timer = CreateConVar("sm_jb_hns_time", "40", "Time That CT's have to Hide.");
	CreateConVar("sm_jb_hns_version", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true, "hns");
}

public OnMapStart()
{
	enabled = false;
	ServerCommand("sm_execcfg sourcemod/sourcemod.cfg");
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast) 
{
	if(enabled)
	{
		iTimer = GetConVarInt(timer); 
		CreateTimer(1.0, Timer_Delay, _, TIMER_REPEAT);
	}
}

public Action:Timer_Delay(Handle:hTimer, any:data) 
{
	if(timer)
	{
		if(iTimer == 0) 
		{
			PrintHintTextToAll("[HNS] T's Can go to Seek CTS!");
			PrintToChatAll("\x04[HNS]\x01 T's Can go to Seek CTS!");
			PrintCenterTextAll("[HNS] T's Can go to Seek CTS!");
			ServerCommand("sm_blind @all");
			for(new iClient = 1; iClient <= MaxClients; iClient++)
			{
				if(IsClientInGame(iClient) && IsPlayerAlive(iClient))
				{
					GivePlayerItem(iClient, "weapon_m4a1");
					GivePlayerItem(iClient, "weapon_deagle");
				}
			}
			opencells();
			return Plugin_Stop;
		}
		else
		{
			iTimer--;
			PrintHintTextToAll("[HNS] Time left to Hide %02i:%02i", iTimer / 60, iTimer % 60);
			PrintCenterTextAll("[HNS] Time left to Hide %02i:%02i", iTimer / 60, iTimer % 60);
			ServerCommand("sm_blind @t 5000");
			opencells();
			return Plugin_Continue;
		}
	}
	return Plugin_Stop;
}

public Action:HnsCommand(client, args)
{
	new Handle:HNS = CreateMenu(MenuHandler_HNS);
	SetMenuTitle(HNS, "Hide and Seek:");
	AddMenuItem(HNS, "on", "Enable");
	AddMenuItem(HNS, "off", "Disable");
	DisplayMenu(HNS, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public MenuHandler_HNS(Handle:HNS, MenuAction:action, iClient, iMenuItem)
{
	if(action == MenuAction_Select)
	{
		switch (iMenuItem)
		{
			case 0:
			{
				if(enabled)
				{
					PrintToChat(iClient, "\x04[HNS]\x01 Hide and Seek is already enabled.");
				}
				else
				{
					SetConVarInt(FindConVar("sm_show_activity"), 0);
					enabled = true;
					SetConVarInt(FindConVar("mp_restartgame"), 1);
					SetConVarInt(FindConVar("mp_forcecamera"), 1);
					SetConVarInt(FindConVar("sv_alltalk"), 0);
					SetConVarInt(FindConVar("sm_hosties_lr"), 0);
					PrintToChatAll("\x04[HNS]\x01 Hide and Seek is now Enabled.");
				}
			}
			case 1:
			{
				if(enabled)
				{
					enabled = false;
					SetConVarInt(FindConVar("mp_restartgame"), 1);
					SetConVarInt(FindConVar("mp_forcecamera"), 0);
					SetConVarInt(FindConVar("sv_alltalk"), 1);
					SetConVarInt(FindConVar("sm_hosties_lr"), 1);
					PrintToChatAll("\x04[HNS]\x01 Hide and Seek is now Disabled.");
					ServerCommand("exec sourcemod/sourcemod.cfg");
				}
				else
				{
					PrintToChat(iClient, "\x04[HNS]\x01 Hide and Seek is already disabled.");
				}
			}
		}
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(HNS);
	}
}

public Action:opencells()
{
	for(new i = 0; i < sizeof(EntityList); i++) 
	while((iEnt = FindEntityByClassname(iEnt, EntityList[i])) != -1)
	AcceptEntityInput(iEnt, "Open");
}