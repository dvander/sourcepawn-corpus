/*
* ********************************************************
*  EuroCSS.LT | Warning System  **************************
* ********************************************************
* This plugins is part of EuroCSS.LT Gaming community
* Please do not remove the copyrights of this plugin.
* ***************************************************************
* Please visit http://eurocss.com or http://eurocss.lt for more info. *
* ********************************************************************
*

Special Thanks to Peace-Maker, who helped me a lot in creating this plugin.

MYSQL tables:

CREATE TABLE user_warn (
  id int(10) unsigned NOT NULL auto_increment,
  nick varchar(65) NOT NULL,
  steam_id varchar(65) NOT NULL,
  warn int(10) NOT NULL,
  reason varchar(65) NOT NULL,
  admin varchar(65) NOT NULL,
  PRIMARY KEY (id)
);


*/

#pragma semicolon 1

#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#include <colors>
#include <sdktools>
#include <sourcebans>

#define PLUGIN_VERSION "v1.0b"
#define SOUND_FREEZE	"physics/glass/glass_impact_bullet4.wav"
#define SOUND_FREEZE_EXPLODE	"ui/freeze_cam.wav"

new Handle:hTopMenu = INVALID_HANDLE;
new g_WarnTarget[MAXPLAYERS+1];
new g_WarnTargetUserId[MAXPLAYERS+1];

new Handle:warn_sistema = INVALID_HANDLE;
new Handle:warn_max = INVALID_HANDLE;
new Handle:warn_punishment = INVALID_HANDLE;
new Handle:warn_breason = INVALID_HANDLE;
new Handle:warn_kreason = INVALID_HANDLE;
new Handle:warn_ban_time = INVALID_HANDLE;

// v1.0a

new Handle:warn_punish_every_warn = INVALID_HANDLE;
new Handle:warn_punish_sound = INVALID_HANDLE;
new Handle:warn_every_punishment = INVALID_HANDLE;
new Handle:warn_agreement_word = INVALID_HANDLE;

new Handle:warn_freeze_time = INVALID_HANDLE;
new Handle:warn_slap_damage = INVALID_HANDLE;

new Handle:warn_announce = INVALID_HANDLE;

new Handle:warn_every_warn_bantime = INVALID_HANDLE;
new Handle:warn_every_warn_bantime_double = INVALID_HANDLE;

new Handle:FreezeTimer[MAXPLAYERS+1];
new bool:IsFreezed[MAXPLAYERS+1];
new GlowSprite; 

new bool:warn_need_agreement[MAXPLAYERS+1] = false;

new Handle:db = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Warning system v1.0b",
	author = "MindziusLT",
	description = "Advanced Warning system for Admins.",
	version = PLUGIN_VERSION,
	url = "EuroCSS.LT"
};
public OnPluginStart()
{
	CreateConVar("warn_version", PLUGIN_VERSION, "Warn system version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	RegAdminCmd("sm_warn", Command_Warn, ADMFLAG_BAN, "Warn command. ADMFLAG_BAN");
	RegConsoleCmd("sm_mywarn", Command_MyWarn);
	warn_max = CreateConVar("warn_max", "3", "WARN skaicius, kuri surinkus zaidejui pritaikoma bausme.", FCVAR_PLUGIN);
	warn_punishment = CreateConVar("warn_punishment", "1", "Bausme: 1- KICK, 2-BAN", FCVAR_PLUGIN);	
	warn_breason = CreateConVar("warn_ban_reason", "[WARN] Buvai blogas, dabar pailsesi", "Warn BAN priezastis.", FCVAR_PLUGIN);	
	warn_kreason = CreateConVar("warn_kick_reason", "[WARN] Nuleisk gaza", "Warn kick priezastis", FCVAR_PLUGIN);	
	warn_ban_time = CreateConVar("warn_ban_time", "1440", "BAN trukme, minutemis. Permanently[0] 1Valanda[60min] 1Diena[1440min] 3Dienos[4320min] 5Dienos[7200min]", FCVAR_PLUGIN);	
	warn_sistema = CreateConVar("warn_system", "1", "1-ijungia. 0 = isjungia", FCVAR_PLUGIN);
	
	// v1.0a
	warn_punish_every_warn = CreateConVar("warn_punish_every", "1", "Ability to punisher client every warn they get <1-enable, 2-disable>", FCVAR_PLUGIN);	
	warn_punish_sound = CreateConVar("warn_punishment_sound", "1", "Punishment sound for client, every warn. <1-enable, 2-disable>", FCVAR_PLUGIN);	
	warn_every_warn_bantime = CreateConVar("warn_every_warn_bantime", "5", "How long to ban player every warn. Minutes.", FCVAR_PLUGIN);	
	warn_every_warn_bantime_double = CreateConVar("warn_every_warn_bantime_double", "1", "Double bantime then getting more warns.", FCVAR_PLUGIN);	
	warn_every_punishment = CreateConVar("warn_every_punishment", "5", "Punishment for every warn client gets. <1-kick, 2-freeze, 3-slap, 4-slay, 5-chat agreement(with freeze) 6- ban>.", FCVAR_PLUGIN);	
	warn_agreement_word = CreateConVar("warn_agreemen_word", "sutinku", "Agreement word, which must be typed. Required: <warn_every_punishment 5>", FCVAR_PLUGIN);	
	warn_freeze_time = CreateConVar("warn_freeze_time", "5.0", "Warn freeze time. Required: <warn_every_punishment 2>", FCVAR_PLUGIN);	
	warn_slap_damage = CreateConVar("warn_slap_damage", "30", "Warn slap time. Required: <warn_every_punishment 3>", FCVAR_PLUGIN);	
	warn_announce =  CreateConVar("warn_announce", "1", "Warning announcement.", FCVAR_PLUGIN);	
	RegConsoleCmd("say", SayHook);
	RegConsoleCmd("say_team", SayHook);
	
	//This starts the connection defines the callback to run once connected/error'd 
	SQL_TConnect(SQL_OnConnect, "default");

	AutoExecConfig(true, "eurocss_warn");
	LoadTranslations("common.phrases");
	LoadTranslations("plugin.warn_system");
	
	/* Account for late loading */
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
}
public OnMapStart()
{
	/* Prechacing sound */
	if(GetConVarBool(warn_punish_sound))
	{
		PrecacheSound("ambient/misc/brass_bell_C.wav",true);
	}
}


public SQL_OnConnect(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    //Since we are not guaranteed a connection, we make sure it actually worked 
	if (hndl == INVALID_HANDLE)
	{
		//It didn't work, so we log the error 
		LogError("Database failure: %s", error);
	} 
	else 
	{
		//It worked, so we set the global to the handle the callback provided for this connection 
		db = hndl;
		//db = SQLite_UseDatabase("yourdbhere",error,sizeof(error));  
	}
}



public Action:Command_MyWarn(client, args) // Let's check my warning level.
{
	if (GetConVarBool(warn_sistema)) // Warning system online?
	{    
		decl String:auth[64];
		GetClientAuthString(client,auth,sizeof(auth));
	
		decl String:query[100];
	
		Format(query,sizeof(query),"SELECT steam_id FROM user_warn WHERE steam_id='%s'", auth);
		SQL_TQuery(db,SQL_CheckWarnings, query, GetClientUserId(client)); // Callback to check warnings
	}
	else
	{
		PrintToChat(client, "\x03[WARN] Command: /mywarn");
	}
	
	return Plugin_Handled;
}

public Action:Command_Warn(client, args) // Let's add warning level to EMO.
{
	if (GetConVarBool(warn_sistema))
	{    
		if (args < 2)
		{
			PrintToChat(client, "\x03[WARN] Command: /warn <nick> <reason>");
			return Plugin_Handled;
		}
    
		decl String:query[512];
		decl String:arg1[32];
		decl String:reason[32];
		decl String:name[MAX_NAME_LENGTH];
    
	
		GetCmdArg(1, arg1, sizeof(arg1));
		new target = FindTarget(client, arg1,true,true); // Find target
		if(target > 0) // Let's check is target in game
		{
			GetClientName(target,name,sizeof(name)); // Get target name
		
			decl String:auth[64];
			GetClientAuthString(target,auth,sizeof(auth)); // Get target STEAM_ID
		
        
			GetCmdArg(2, reason, sizeof(reason)); // Get warn reason
		
			new Handle:dp = CreateDataPack(); // Creating DataPack for export
			WritePackCell(dp, GetClientUserId(target));
			WritePackCell(dp, GetClientUserId(client));
			WritePackString(dp, reason);
			ResetPack(dp);
        
			Format(query,sizeof(query),"SELECT steam_id FROM user_warn WHERE steam_id='%s'", auth);
        
			SQL_TQuery(db,SQL_AddWarnings,query, dp);
		}
		else
		{
			//PrintToChat(client, "\x03[WARN] Klaida.");
			CPrintToChat(client, "%T", "warn error"); // Return Error
		}

	}
	else
	{
		CPrintToChat(client, "%T", "warn offline"); // System offline
		//PrintToChat (client, "\x03[WARN] Warn system is offline.");
	}
	return Plugin_Handled;
}
public SQL_NothingCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{

	if(hndl == INVALID_HANDLE)
	{
		LogError("Could not connect to database: %s", error);
		return;
	}
	
	LogMessage("[WARN] - Connected Successfully to Database");
}

public SQL_CheckWarnings(Handle:owner, Handle:hndl, const String:error[], any:data) // Check warnings mysql callback
{
	new client;
	client = GetClientOfUserId(data);
	
	if(client == 0)
	return;
	
	if (hndl == INVALID_HANDLE)
	{
		LogError("Query error: %s", error);
		return;
	}
	
	new warn = SQL_GetRowCount(hndl);
	
	new iMax = GetConVarInt(warn_max);
	
	CPrintToChat(client, "%t", "warn check", warn, iMax); // Print warnings to client

}

public SQL_AddWarnings(Handle:owner, Handle:hndl, const String:error[], any:dp) // Add Warnings MySQL callback
{
	new target;
	new client;
	decl String:reason[32];
	if(dp != INVALID_HANDLE)
	{
		target = GetClientOfUserId(ReadPackCell(dp));
		client = GetClientOfUserId(ReadPackCell(dp));
		ReadPackString(dp, reason, sizeof(reason));
		CloseHandle(dp); 
	   // THIS IS MANDATORY!! After you're done with reading the info from the datapack, you have to close the handle to avoid memory leaks. 
		// You also have to close the handle, even if you don't need the info in it at the time due to sql error or something. 
		// That's why it's even before error checking.
	}
	
	if (hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("Query error: %s", error);
		return;
	}
	
	if(target == 0)
	return;
	
	decl String:query[512];
	decl String:name[MAX_NAME_LENGTH], String:auth[64], String:admin_name[MAX_NAME_LENGTH];
	GetClientName(target,name,sizeof(name)); // Get target name
	GetClientName(client,admin_name,sizeof(admin_name)); // Get admin name
	GetClientAuthString(target,auth,sizeof(auth)); // Get target STEAM_ID
	
	new iMax = GetConVarInt(warn_max); // Maximum warnings, client can get
	
	// This player wasn't warned before? Add him to the database!
	Format(query, sizeof(query), "INSERT INTO user_warn (nick, steam_id, warn, reason, admin) VALUES ('%s', '%s', 1, '%s', '%s')", name, auth, reason, admin_name);
	SQL_TQuery(db,SQL_NothingCallback,query);
	
	new iWarn = SQL_GetRowCount(hndl); // Let's count how many warnings player have
	
	//Increase the warn level
	iWarn++;
	if(GetConVarBool(warn_punish_every_warn)) // ConVar, punish player every warning?
	{
		if( target > 0 )
		{
			if(GetConVarInt(warn_every_punishment) == 1) // Reason 1
			{				
				new String:kick_reason[50];
				GetConVarString(warn_kreason, kick_reason, sizeof(kick_reason));
				
				if(GetConVarBool(warn_punish_sound))
				{
					// Cia grojamas garsas
					EmitSoundToClient(target, "ambient/misc/brass_bell_C.wav");
				}
				
				CPrintToChatAll("%t", "every punishment kick", name, iWarn, iMax, reason);
				
				ServerCommand("sm_kick %s %s", name, kick_reason);
			}
			else if(GetConVarInt(warn_every_punishment) == 2) // Reason 2
			{							
				if(GetConVarBool(warn_punish_sound))
				{
					// Cia grojamas garsas
					EmitSoundToClient(target, "ambient/misc/brass_bell_C.wav");
				}
				
				CPrintToChatAll("%t", "every punishment freeze", name, iWarn, iMax, reason);
				
				Freeze(target, GetConVarFloat(warn_freeze_time));
			}
			else if(GetConVarInt(warn_every_punishment) == 3) // Reason 3
			{							
				if(GetConVarBool(warn_punish_sound))
				{
					// Cia grojamas garsas
					EmitSoundToClient(target, "ambient/misc/brass_bell_C.wav");
				}
				
				CPrintToChatAll("%t", "every punishment slap", name, iWarn, iMax, reason);
				
				SlapPlayer(target, GetConVarInt(warn_slap_damage), true);
			}
			else if(GetConVarInt(warn_every_punishment) == 4) // Reason 4
			{							
				if(GetConVarBool(warn_punish_sound))
				{
					// Cia grojamas garsas
					EmitSoundToClient(target, "ambient/misc/brass_bell_C.wav");
				}
				
				CPrintToChatAll("%t", "every punishment slay", name, iWarn, iMax, reason);
				
				ForcePlayerSuicide(target);
				
			}
			
			else if(GetConVarInt(warn_every_punishment) == 5) // Reason 5
			{							
				if(GetConVarBool(warn_punish_sound))
				{
					// Cia grojamas garsas
					EmitSoundToClient(target, "ambient/misc/brass_bell_C.wav");
				}

				CPrintToChatAll("%t", "every punishment agreement", name, iWarn, iMax, reason);
				
				warn_need_agreement[target] = true; // Client need to agree, before continueing
				
				SetEntityMoveType(target, MOVETYPE_NONE); // Freeze him
				IsFreezed[client] = true;
				SetEntityRenderColor(target, 0, 128, 255, 192);

				new Float:vec[3];
				GetClientEyePosition(target, vec);
				EmitAmbientSound(SOUND_FREEZE, vec, target, SNDLEVEL_RAIDSIREN); // Freeze sound
				decl String:agreement_message[40];
				GetConVarString(warn_agreement_word, agreement_message, sizeof(agreement_message)); // Get agreement messege
				CPrintToChat(client, "%t", "agreement message", agreement_message);
			}
			else if(GetConVarInt(warn_every_punishment) == 6) // Reason 6
			{							
				if(GetConVarBool(warn_punish_sound))
				{
					// Cia grojamas garsas
					EmitSoundToClient(target, "ambient/misc/brass_bell_C.wav");
				}
				
				CPrintToChatAll("%t", "every punishment ban", name, iWarn, iMax, reason);
				new kBanTime; // This is bantime
				
				if(GetConVarInt(warn_every_warn_bantime_double))
				{
					kBanTime = iWarn * GetConVarInt(warn_every_warn_bantime); 
				}
				else
				{
					kBanTime = GetConVarInt(warn_every_warn_bantime);
				}
				
				SBBanPlayer(client, target, kBanTime, reason); // Ban him!
				
			}
			else
			{
				if(GetConVarBool(warn_punish_sound))
				{
					// Cia grojamas garsas
					EmitSoundToClient(target, "ambient/misc/brass_bell_C.wav");
				}
				
				CPrintToChatAll("%t", "every punishment", name, iWarn, iMax, reason);
			}
		}

		if(iWarn >= GetConVarInt(warn_max)) // Player reached warn thereshold, PUNISH HIM!
		{
			if(GetConVarInt(warn_punishment) == 1) // Reason 1
			{
				if( target > 0 )
				{
					//CPrintToChatAll("{red}[WARN]{green} %s {olive}ismestas. [{green}%d{olive}/{red}%d{olive}].", name, iMax, iWarn);
					CPrintToChatAll("%t", "punishment kick", name, iMax, iWarn);
					
					Format(query, sizeof(query), "DELETE FROM user_warn WHERE steam_id = '%s'", auth);
					SQL_TQuery(db,SQL_NothingCallback,query);
							
					new String:kick_reason[50];
					GetConVarString(warn_kreason, kick_reason, sizeof(kick_reason));
					
					ServerCommand("sm_kick %s %s", name, kick_reason); // Kick-ASS!
				}
			}
			else if(GetConVarInt(warn_punishment) == 2) // Reason 2
			{
				if( target > 0 )
				{
					new String:ban_reason[50];
					new iBanTime = GetConVarInt(warn_ban_time);
					GetConVarString(warn_breason, ban_reason, sizeof(ban_reason));
							
					//CPrintToChatAll("{red}[WARN]{green} %s {olive}baninamas [{green}%d{olive}/{red}%d{olive}]. {red}Trukme: {green}%d min", name, iWarn, iMax, bantime);
					CPrintToChatAll("%t", "punishment ban", name, iMax, iWarn, iBanTime);
					
					Format(query, sizeof(query), "DELETE FROM user_warn WHERE steam_id = '%s'", auth); // Delete all entrys of player from MySQL
					SQL_TQuery(db,SQL_NothingCallback,query);
					
					SBBanPlayer(client, target, iBanTime, ban_reason); // Ban him!
			
				}
			}
		}
	}
}

public Action:SayHook(client, args)
{ 
	new String:text[192];
	GetCmdArgString(text, sizeof(text));
	
	new startidx = 0;
	if (text[0] == '"')
	{
		startidx = 1;
		
		new len = strlen(text);
		if (text[len-1] == '"')
		{
			text[len-1] = '\0';
		}
	}
	
	if (GetConVarInt(warn_every_punishment) == 5) // Agreement
	{
		if(warn_need_agreement[client])
		{
			decl String:agreement_word[50];
			new agreement = GetConVarString(warn_agreement_word, agreement_word, sizeof(agreement_word));
			if(StrEqual(text[startidx], "%s"), agreement)
			{
				warn_need_agreement[client] = false;
				
				CPrintToChat(client, "%t", "warn agreed");
				CreateTimer(0.0, Unfreeze, client);
			}
		}
	}	
	return Plugin_Continue;
}
public OnClientPutInServer(client)
{
	if(warn_need_agreement[client])
	{
		if(IsPlayerAlive(client) && IsClientInGame(client))
		{
			SetEntityMoveType(client, MOVETYPE_NONE);
			SetEntityRenderColor(client, 0, 128, 255, 192);

			new Float:vec[3];
			GetClientEyePosition(client, vec);
			EmitAmbientSound(SOUND_FREEZE, vec, client, SNDLEVEL_RAIDSIREN);
			//CPrintToChat(client, " Tu buvai ispetas, ir neperskaitei taisykliu. Perskaite taisykles, rasykite 'atsiprasau' ");
			CPrintToChat(client, "%t", "warned before and left");
		}
	}
	else
	{
		warn_need_agreement[client] = false;
	}
	
	if(GetConVarBool(warn_announce))
	{
		CreateTimer(30.0, TimerAnnounce, client);
	}
}
public Action:TimerAnnounce(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		CPrintToChat(client, "%t", "warn announce");
	}
}

/*============================================*/
/*============= FREEEZE ======================*/
Freeze(client, Float:time)
{
	if (IsClientInGame(client) && IsClientConnected(client) && IsPlayerAlive(client))
	{
		if (FreezeTimer[client] != INVALID_HANDLE)
		{
			KillTimer(FreezeTimer[client]);
			FreezeTimer[client] = INVALID_HANDLE;
		}
		
		SetEntityMoveType(client, MOVETYPE_NONE);
	
		new Float:vec[3];
		GetClientEyePosition(client, vec);
		EmitAmbientSound(SOUND_FREEZE, vec, client, SNDLEVEL_RAIDSIREN);

		TE_SetupGlowSprite(vec, GlowSprite, time, 1.5, 50);
		TE_SendToAll();
		IsFreezed[client] = true;
		FreezeTimer[client] = CreateTimer(time, Unfreeze, client);
	}
}

public Action:Unfreeze(Handle:timer, any:client)
{
	if (IsFreezed[client])
	{
		SetEntityMoveType(client, MOVETYPE_WALK);
		IsFreezed[client] = false;
		FreezeTimer[client] = INVALID_HANDLE;
	}
}
public OnClientDisconnect_Post(client)
{
	IsFreezed[client] = false;
	if (FreezeTimer[client] != INVALID_HANDLE)
	{
		KillTimer(FreezeTimer[client]);
		FreezeTimer[client] = INVALID_HANDLE;
	}
}

/*=================================================*/

public OnAdminMenuReady(Handle:topmenu)
{
	/* Block us from being called twice */
	if (topmenu == hTopMenu)
	{
		return;
	}
	
	/* Save the Handle */
	hTopMenu = topmenu;
	
	/* Find the "Player Commands" category */
	new TopMenuObject:player_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_PLAYERCOMMANDS);

	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hTopMenu,
			"sm_warn",
			TopMenuObject_Item,
			AdminMenu_Warn,
			player_commands,
			"sm_warn",
			ADMFLAG_BAN);
			
	}
}

public AdminMenu_Warn(Handle:topmenu,
							  TopMenuAction:action,
							  TopMenuObject:object_id,
							  param,
							  String:buffer[],
							  maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "Warn menu", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayWarnTargetMenu(param);
	}
}

DisplayWarnTargetMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_WarnPlayerList);

	decl String:title[100];
	Format(title, sizeof(title), "%T:", "Warn player", client);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);

	AddTargetsToMenu2(menu, client, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED);

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_WarnPlayerList(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32], String:name[32];
		new userid, target;

		GetMenuItem(menu, param2, info, sizeof(info), _, name, sizeof(name));
		userid = StringToInt(info);

		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "[WARN] %t", "Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[WARN] %t", "Unable to target");
		}
		else
		{
			g_WarnTarget[param1] = target;
			g_WarnTargetUserId[param1] = userid;
			DisplayWarnReasonMenu(param1);
		}
	}
}

DisplayWarnReasonMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_WarnReasonList);

	decl String:title[100];
	Format(title, sizeof(title), "%T: %N", "Warn reason", client, g_WarnTarget[client]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);

	/* :TODO: we should either remove this or make it configurable */

	AddMenuItem(menu, "Abusive", "Abusive");
	AddMenuItem(menu, "Racism", "Racism");
	AddMenuItem(menu, "General cheating/exploits", "General cheating/exploits");
	AddMenuItem(menu, "Wallhack", "Wallhack");
	AddMenuItem(menu, "Aimbot", "Aimbot");
	AddMenuItem(menu, "Speedhacking", "Speedhacking");
	AddMenuItem(menu, "Mic spamming", "Mic spamming");
	AddMenuItem(menu, "Admin disrepect", "Admin disrepect");
	AddMenuItem(menu, "Camping", "Camping");
	AddMenuItem(menu, "Team killing", "Team killing");
	AddMenuItem(menu, "Unacceptable Spray", "Unacceptable Spray");
	AddMenuItem(menu, "Breaking Server Rules", "Breaking Server Rules");
	AddMenuItem(menu, "Other", "Other");

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_WarnReasonList(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[64];

		GetMenuItem(menu, param2, info, sizeof(info));

		ServerCommand("sm_warn %s %s", g_WarnTarget[param1], info);
	}
}
/*=================================================*/