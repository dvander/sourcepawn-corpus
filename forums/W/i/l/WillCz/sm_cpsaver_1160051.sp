#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

// Constants
#define PLUGIN_VERSION	 "1.01"

#define MESS			 "\x03[CheckpointSaver] \x01%t"
#define DEBUG_MESS		 "\x04[CheckpointSaver] \x01"

// Global vars
new Float:originSaves[MAXPLAYERS+1][3];
new Float:angleSaves[MAXPLAYERS+1][3];

new collisionGroup;

// ConVar-stuff
new Handle:sm_cpsaver_enable			 = INVALID_HANDLE;
new Handle:sm_cpsaver_version			 = INVALID_HANDLE;
new Handle:sm_cpsaver_block_falldamage	 = INVALID_HANDLE;
new Handle:sm_cpsaver_standard_hp		 = INVALID_HANDLE;
new Handle:sm_cpsaver_noblock_enable	 = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "SM_CheckpointSaver",
	author = "dataviruset",
	description = "A public checkpoint saving system for bhop/jump/etc servers",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	// Load translations
	LoadTranslations("cpsaver.phrases");

	// Console commands
	RegConsoleCmd("sm_cpsave", Command_Save);
	RegConsoleCmd("sm_cptele", Command_Teleport);
	RegConsoleCmd("sm_cpmenu", Command_CPmenu);

	// Events hooks
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_spawn", Event_PlayerSpawn);

	// Create ConVars
	sm_cpsaver_enable = CreateConVar("sm_cpsaver_enable", "1", "Enable or disable the plugin; 0 - disable, 1 - enable");
	sm_cpsaver_version = CreateConVar("sm_cpsaver_version", PLUGIN_VERSION, "SM_CheckpointSaver plugin version (unchangeable)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	sm_cpsaver_block_falldamage = CreateConVar("sm_cpsaver_block_falldamage", "1", "Enable/disable blocking of fall damage (resets hp to sm_cpsaver_standard_hp after a player gets hurt from falling unless the fall damage is enough to kill him); 0 - disable, 1 - enable");
	sm_cpsaver_standard_hp = CreateConVar("sm_cpsaver_standard_hp", "100", "Standard hp given to players on spawn; x - hp value");
	sm_cpsaver_noblock_enable = CreateConVar("sm_cpsaver_noblock_enable", "1", "Enable/disable player vs player collision blocking; 0 - disable, 1 - enable");

	SetConVarString(sm_cpsaver_version, PLUGIN_VERSION);
	AutoExecConfig(true, "sm_cpsaver");

	// Hook ConVar-changes
	HookConVarChange(sm_cpsaver_version, VersionChange);
	HookConVarChange(sm_cpsaver_noblock_enable, NoblockChange);

	collisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
	if (collisionGroup == -1)
	{
		SetFailState("[sm_cpsaver NoBlock] Failed to get offset for CBaseEntity::m_CollisionGroup.");
	}
}

public VersionChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SetConVarString(convar, PLUGIN_VERSION);
}

public OnMapEnd()
{
	for(new i = 1; i <= MAXPLAYERS; i++)
	{
		originSaves[i] = NULL_VECTOR;
		angleSaves[i] = NULL_VECTOR;
	}
}

public NoblockChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (StrEqual(newValue, "1"))
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if ( (IsClientInGame(i)) && (IsPlayerAlive(i)) )
				SetEntData(i, collisionGroup, 2, 4, true);
		}
	}
	else
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if ( (IsClientInGame(i)) && (IsPlayerAlive(i)) )
				SetEntData(i, collisionGroup, 5, 4, true);
		}
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
  if (GetConVarInt(sm_cpsaver_enable) == 1)
  {
  	new userid = GetEventInt(event, "userid");
	 new client = GetClientOfUserId(userid);
  
	 if (GetConVarInt(sm_cpsaver_standard_hp) != 100)
  	{
	  	SetEntData(client, FindSendPropOffs("CBasePlayer", "m_iHealth"), GetConVarInt(sm_cpsaver_standard_hp));
  	}  
    
  	if (GetConVarInt(sm_cpsaver_noblock_enable))
	 {
	   	SetEntData(client, collisionGroup, 2, 4, true);
	 }

  	//PrintToChatAll("%s Client %N has spawned.", DEBUG_MESS, client);
    
  	new Handle:panel = CreatePanel();
	  SetPanelTitle(panel, ":: SM_CheckpointSaver ::");

  	// Translation formatting
	  decl String:serverAdvert1[96];
  	Format(serverAdvert1, sizeof(serverAdvert1), "%T", "CheckpointSaver Spawn Ad", client);
	  decl String:serverAdvert2[64];
  	Format(serverAdvert2, sizeof(serverAdvert2), "%T", "Available Chat Commands", client);
  	decl String:serverAdvert3[64];
  	Format(serverAdvert3, sizeof(serverAdvert3), "%T", "Enjoy Your Stay", client);

  	DrawPanelItem(panel, "-", ITEMDRAW_SPACER);
  	DrawPanelItem(panel, serverAdvert1, ITEMDRAW_RAWLINE);
  	DrawPanelItem(panel, serverAdvert2, ITEMDRAW_RAWLINE);
  	DrawPanelItem(panel, "-", ITEMDRAW_SPACER);
  	DrawPanelItem(panel, "    * !cpmenu", ITEMDRAW_RAWLINE);
  	DrawPanelItem(panel, "    * !cpsave", ITEMDRAW_RAWLINE);
  	DrawPanelItem(panel, "    * !cptele", ITEMDRAW_RAWLINE);
  	DrawPanelItem(panel, "-", ITEMDRAW_SPACER);
  	DrawPanelItem(panel, serverAdvert3, ITEMDRAW_RAWLINE);
  
  	SendPanelToClient(panel, client, PanelHandler, 35);
  }
}

public PanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Cancel)
	{
		PrintToServer("Client %d's panel was cancelled.", param1);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
  if (GetConVarInt(sm_cpsaver_enable) == 1)
  {
  	if (GetConVarInt(sm_cpsaver_block_falldamage) == 1)
    {
  		new ev_attacker = GetEventInt(event, "attacker");
  		new ev_target = GetEventInt(event, "userid");
  		//new attacker = GetClientOfUserId(ev_attacker);
  		new target = GetClientOfUserId(ev_target);
  
  		if ( (ev_attacker == 0) && (IsPlayerAlive(target)) )
  		{
  			SetEntData(target, FindSendPropOffs("CBasePlayer", "m_iHealth"), GetConVarInt(sm_cpsaver_standard_hp));
  		}
  
  		//PrintToChatAll("%s %N (ev: %i cl: %i) hit %N (ev: %i cl: %i)", DEBUG_MESS, attacker, ev_attacker, attacker, target, ev_target, target);
  	}
  }
}

public Action:Command_Save(client, args)
{
	Save(client);
	return Plugin_Handled;
}

public Action:Command_Teleport(client, args)
{
	Teleport(client);
	return Plugin_Handled;
}

public Action:Command_CPmenu(client, args)
{
	CPmenu(client);
	return Plugin_Handled;
}

CPmenu(client)
{
  if (GetConVarInt(sm_cpsaver_enable) == 1)
  {
  	new Handle:menu = CreateMenu(MenuHandler);
  	SetMenuTitle(menu, ":: %T ::", "Menu", client);
  
  	// Translation formatting
  	decl String:CPmenuT1[64];
  	Format(CPmenuT1, sizeof(CPmenuT1), "%T", "Save Location", client);
  	decl String:CPmenuT2[64];
  	Format(CPmenuT2, sizeof(CPmenuT2), "%T", "Teleport", client);
  
  	AddMenuItem(menu, "cpsave", CPmenuT1);
  	AddMenuItem(menu, "cptele", CPmenuT2);
  
  	SetMenuExitButton(menu, true);
  	SetMenuOptionFlags(menu, MENUFLAG_NO_SOUND|MENUFLAG_BUTTON_EXIT);
  	DisplayMenu(menu, client, MENU_TIME_FOREVER);
  }
}

public MenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		switch(param2)
		{
			case 0:
			{
				Save(param1);
			}

			case 1:
			{
				Teleport(param1);
			}
		}

		CPmenu(param1);
	}
	else if (action == MenuAction_Cancel)
	{
		PrintToServer("Client %d's menu was cancelled.", param1);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

Save(client)
{
	if (GetConVarInt(sm_cpsaver_enable) == 1)
	{
		if (IsPlayerAlive(client))
		{
			if (GetEntDataEnt2(client, FindSendPropOffs("CBasePlayer", "m_hGroundEntity")) != -1)
			{
				GetClientAbsOrigin(client, originSaves[client]);
				GetClientAbsAngles(client, angleSaves[client]);
				EmitSoundToClient(client, "buttons/blip1.wav");
				PrintToChat(client, MESS, "Location Saved");
			}
			else
			{
				EmitSoundToClient(client, "buttons/button8.wav");
				PrintToChat(client, MESS, "Not On Ground");
			}
		}
		else
		{
			EmitSoundToClient(client, "buttons/button8.wav");
			PrintToChat(client, MESS, "Must Be Alive");
		}
	}
}

Teleport(client)
{
	if (GetConVarInt(sm_cpsaver_enable) == 1)
	{
		if (IsPlayerAlive(client))
		{
			if ( (GetVectorDistance(originSaves[client], NULL_VECTOR) > 0.00) && (GetVectorDistance(angleSaves[client], NULL_VECTOR) > 0.00) )
			{
				TeleportEntity(client, originSaves[client], angleSaves[client], NULL_VECTOR);
			}
			else
			{
				PrintToChat(client, MESS, "No Location Saved");
			}
		}
		else
		{
			EmitSoundToClient(client, "buttons/button8.wav");
			PrintToChat(client, MESS, "Must Be Alive");
		}
	}
}