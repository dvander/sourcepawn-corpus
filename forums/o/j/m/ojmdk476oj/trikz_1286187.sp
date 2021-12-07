#pragma semicolon 1

//Include
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <smlib>
#undef REQUIRE_EXTENSIONS
#include <steamtools>
#undef REQUIRE_PLUGIN
#include <updater>

//Defines
#define MESS			"\x04[SM_Trikz] \x01%t"
#define GAMEDESC		"SM_Trikz/Trikz"
#define dGAMEDESC		"Counter-Strike: Source"
#define SERVERTAG		"Trikz"
#define PLUGIN_VERSION 	"0.6.6"
#define MAX_CLIENTS		64
#define MAX_BUFF		512
#define SMOKE_SPRITE	"materials/sprites/smoke.vmt"
#define EXPLOSION_SOUND	"/weapons/flashbang/flashbang_explode2.wav"
#define UPDATE_URL 		"http://dl.dropbox.com/u/19991857/trikz/update.txt"

//Client Things
new autoswitch[MAX_CLIENTS];
new autoflash[MAX_CLIENTS];
new autojump[MAX_CLIENTS];
new crespawns[MAX_CLIENTS];
new nteleport[MAXPLAYERS+1];
new jteleport[MAXPLAYERS+1];
new bteleport[MAXPLAYERS+1];
new Float:lastrespawn[MAX_CLIENTS];
new Float:coords1[MAX_CLIENTS][3];
new Float:coords2[MAX_CLIENTS][3];
new g_iSmokeSprite = -1;

//Trikz Cvars
new Handle:sm_trikz_enableautoflash				= INVALID_HANDLE;
new Handle:sm_trikz_enableautoflashswitch		= INVALID_HANDLE;
new Handle:sm_trikz_settings			 		= INVALID_HANDLE;
new Handle:sm_trikz_airaccelerate		 		= INVALID_HANDLE;
new Handle:sm_trikz_ignoreradio			 		= INVALID_HANDLE;
new Handle:sm_trikz_override_gamedesc	 		= INVALID_HANDLE;
new Handle:sm_trikz_add_servertag		 		= INVALID_HANDLE;
new Handle:sm_trikz_enableteleport				= INVALID_HANDLE;
new Handle:sm_trikz_enableblock				 	= INVALID_HANDLE;
new Handle:sm_trikz_enableblockinvis            = INVALID_HANDLE;
new Handle:sm_trikz_enablerespawn				= INVALID_HANDLE;
new Handle:sm_trikz_version				 		= INVALID_HANDLE;
new Handle:sm_trikz_effects			 			= INVALID_HANDLE;
new Handle:sm_trikz_nofall                      = INVALID_HANDLE;
new Handle:sm_trikz_autojump                    = INVALID_HANDLE;
new Handle:sm_trikz_autoupdate                  = INVALID_HANDLE;
new Handle:sm_trikz_respawnmin                  = INVALID_HANDLE;
new Handle:sm_trikz_enableteleporttp            = INVALID_HANDLE;
new Handle:sm_trikz_teleporttime               	= INVALID_HANDLE;

//Cvars
new enableautoflash;
new enableautoflashswitch;
new settings;
new airaccelerate;
new ignoreradio;
new override_gamedesc;
new add_servertag;
new enableteleport;
new enableblock;
new enableblockinvis;
new enablerespawn;
new effects;
new enablenofall;
new enableautojump;
new autoupdate;
new	respawnmin;
new	enableteleporttp;
new	Float:teleportinvis;

new ammoOffset = -1;
new m_hMyWeapons = -1;
new m_GroundEntity = -1;

new bool:g_UseSteamTools = false;

//Plugin Info
public Plugin:myinfo = 
{
	name = "Trikz",
	author = "johan123jo",
	description = "Trikz plugin",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=136826/"
};

//Plugin Load
public OnPluginStart ()
{
	LoadTranslations("common.phrases");
	LoadTranslations("trikz.phrases");
	
	RegConsoleCmd("sm_block",				Command_Block,			"Toggle blocking");
	RegConsoleCmd("sm_respawn",				Command_Respawn,		"Respawn player");
	RegConsoleCmd("sm_flash",				Command_Flash,			"Give 1 flashbang");
	RegConsoleCmd("sm_autoflash",			Command_AutoFlash,		"Autoflash");
	RegConsoleCmd("sm_autoflashswitch",		Command_AutoFlashSwitch,"Autoflash Switch");
	RegConsoleCmd("sm_autojump",			Command_Autojump,		"AutoJump");
	RegConsoleCmd("sm_save1",				Command_Save1,			"Save checkpoint 1");
	RegConsoleCmd("sm_tele1",				Command_tele1,			"Teleport to checkpoint 1");
	RegConsoleCmd("sm_save2",				Command_Save2,			"Save checkpoint 2");
	RegConsoleCmd("sm_tele2",				Command_tele2,			"Teleport to checkpoint 2");
	RegConsoleCmd("sm_teleport_noti", 		Command_TeleNoti);
	
	//Menus
	RegConsoleCmd("sm_trikz",				Command_trikz,			"Show trikz menu");
	RegConsoleCmd("sm_tpmenu",				Command_TPMenu,			"Show teleport menu");
	RegConsoleCmd("sm_automenu",			Command_AutoMenu,		"Show Auto menu");
	
	//Cvars
	sm_trikz_enableautoflash		= CreateConVar("sm_trikz_enableautoflash",		"1", 			"Enable or disable autoflash command: 0 - disable, 1 - enable");
	sm_trikz_enableautoflashswitch	= CreateConVar("sm_trikz_enableautoflashswitch","1", 			"Enable or disable autoflashswitch command (requires sm_trikz_enableautoflash to be 1): 0 - disable, 1 - enable");
	sm_trikz_settings 				= CreateConVar("sm_trikz_settings",				"1", 			"Enable or disable trikz settings (Airaccelerate, flashboost, friendlyfire and bhopenable): 0 - disable, 1 - enable");
	sm_trikz_airaccelerate 			= CreateConVar("sm_trikz_airaccelerate",		"150", 			"What should sv_airaccelerate  be (requires sm_trikz_settings to be 1)");
	sm_trikz_ignoreradio 			= CreateConVar("sm_trikz_ignoreradio",			"1", 			"Enable or disable grenade radio (Fire in the hole!): 1 - disable, 0 - enable");
	sm_trikz_override_gamedesc 		= CreateConVar("sm_trikz_override_gamedesc", 	"1", 			"Enable or disable override of the game description (standard Counter-Strike: Source, override to SM_Trikz/Trikz): 0 - disable, 1 - enable");
	sm_trikz_add_servertag 			= CreateConVar("sm_trikz_add_servertag", 		"1", 			"Enable or disable new server tag : \"Trikz\" : 0 - disable, 1 - enable");
	sm_trikz_enableteleport 		= CreateConVar("sm_trikz_enableteleport", 		"1", 			"Enable or disable teleport menu/commands: 0 - disable, 1 - enable");
	sm_trikz_enableblock 			= CreateConVar("sm_trikz_enableblock", 			"1", 			"Enable or disable block command (!trikz_block): 0 - disable, 1 - enable");
	sm_trikz_enableblockinvis 		= CreateConVar("sm_trikz_enableblockinvis", 	"1", 			"Enable or disable invisibility when ghost (requires sm_trikz_enableblock to be 1): 0 - disable, 1 - enable");
	sm_trikz_enablerespawn 			= CreateConVar("sm_trikz_enablerespawn", 		"1", 			"Enable or disable respawn command: 0 - disable, 1 - enable");
	sm_trikz_effects 				= CreateConVar("sm_trikz_effects",				"0", 			"Enable or disable effects on flashbang explosions: 0 - disable, 1 - enable sparks, 2 - enable sound, 3 - enable sparks & sound");
	sm_trikz_nofall                 = CreateConVar("sm_trikz_nofall", 				"1",            "Enable or disable no fall damage: 0 - disable, 1 - enable");
	sm_trikz_autojump 				= CreateConVar("sm_trikz_autojump", 			"1", 			"Enable or disable auto jump (!trikz_autojump): 0 - disable, 1 - enable");
	sm_trikz_autoupdate				= CreateConVar("sm_trikz_autoupdate", 			"1", 			"Enable or disable autoupdate: 0 - disable, 1 - enable");
	sm_trikz_respawnmin				= CreateConVar("sm_trikz_respawnmin", 			"2", 			"How many times a player can respawn pr. minute. default 2 times pr. minute (requires sm_trikz_enablerespawn to be 1): 0 - disabled");
	sm_trikz_enableteleporttp		= CreateConVar("sm_trikz_enableteleporttp",		"1", 			"Enable or disable that a player can teleport to another player (if the other player allows): 0 - disable, 1 - enable");
	sm_trikz_teleporttime			= CreateConVar("sm_trikz_teleporttime",			"5", 			"How much time after 2 players has teleport to each other they should not collide (block each other)");
	sm_trikz_version 				= CreateConVar("sm_trikz_version", 				PLUGIN_VERSION, "SM_Trikz plugin version (unchangeable)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	HookConVarChange(sm_trikz_enableautoflash, 			ConVarChange);
	HookConVarChange(sm_trikz_enableautoflashswitch, 	ConVarChange);
	HookConVarChange(sm_trikz_settings, 				ConVarChange);
	HookConVarChange(sm_trikz_airaccelerate, 			ConVarChange);
	HookConVarChange(sm_trikz_ignoreradio, 				ConVarChange);
	HookConVarChange(sm_trikz_override_gamedesc, 		ConVarChange);
	HookConVarChange(sm_trikz_add_servertag, 			ConVarChange);
	HookConVarChange(sm_trikz_enableteleport, 			ConVarChange);
	HookConVarChange(sm_trikz_enableblock, 				ConVarChange);
	HookConVarChange(sm_trikz_enableblockinvis, 		ConVarChange);
	HookConVarChange(sm_trikz_enablerespawn, 			ConVarChange);
	HookConVarChange(sm_trikz_effects, 					ConVarChange);
	HookConVarChange(sm_trikz_nofall, 					ConVarChange);
	HookConVarChange(sm_trikz_autojump, 				ConVarChange);
	HookConVarChange(sm_trikz_autoupdate, 				ConVarChange);
	HookConVarChange(sm_trikz_respawnmin, 				ConVarChange);
	HookConVarChange(sm_trikz_enableteleporttp, 		ConVarChange);
	HookConVarChange(sm_trikz_teleporttime, 			ConVarChange);
	
	HookConVarChange(sm_trikz_version, VersionChange);

	enableautoflash 		= GetConVarInt(sm_trikz_enableautoflash);
	enableautoflashswitch 	= GetConVarInt(sm_trikz_enableautoflashswitch);
	settings 				= GetConVarInt(sm_trikz_settings);
	airaccelerate 			= GetConVarInt(sm_trikz_airaccelerate);
	ignoreradio 			= GetConVarInt(sm_trikz_ignoreradio);
	override_gamedesc 		= GetConVarInt(sm_trikz_override_gamedesc);
	add_servertag 			= GetConVarInt(sm_trikz_add_servertag);
	enableteleport 			= GetConVarInt(sm_trikz_enableteleport);
	enableblock 			= GetConVarInt(sm_trikz_enableblock);
	enableblockinvis 		= GetConVarInt(sm_trikz_enableblockinvis);
	enablerespawn 			= GetConVarInt(sm_trikz_enablerespawn);
	effects 				= GetConVarInt(sm_trikz_effects);
	enablenofall 			= GetConVarInt(sm_trikz_nofall);
	enableautojump 			= GetConVarInt(sm_trikz_autojump);
	autoupdate 				= GetConVarInt(sm_trikz_autoupdate);
	respawnmin				= GetConVarInt(sm_trikz_respawnmin);
	enableteleporttp		= GetConVarInt(sm_trikz_enableteleporttp);
	teleportinvis			= GetConVarFloat(sm_trikz_teleporttime);
	
	AutoExecConfig(true, "trikz");
	
	HookEvent("player_spawn", Event_spawn);  
	HookEvent("weapon_fire", Event_WeaponFire);
	
	//Offsets
	ammoOffset = FindSendPropInfo("CCSPlayer", "m_iAmmo");
	
	if(ammoOffset == -1)
	{
		SetFailState("Failed to find m_iAmmo offset");
	}
	
	m_hMyWeapons = FindSendPropOffs("CBasePlayer", "m_hMyWeapons");  
	
	if(m_hMyWeapons == -1)
	{
		SetFailState("Failed to find m_hMyWeapons offset");
	}

	m_GroundEntity = FindSendPropOffs("CBasePlayer", "m_hGroundEntity");
	
	if(m_GroundEntity == -1)
	{
		SetFailState("Failed to find m_hGroundEntity offset");
	}
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("Steam_SetGameDescription");
	return APLRes_Success;
}

public Action:Command_TeleNoti(client, args)
{
	if(enableteleporttp == 1)
	{
		if(nteleport[client] == 0)
		{
			nteleport[client] = 1;
			
			PrintToChat(client, MESS, "TZ teleporttp no longer notified");
		}
		else if(nteleport[client] == 1)
		{
			nteleport[client] = 0;
			
			PrintToChat(client, MESS, "TZ teleporttp notify me");
		}
	}

	return Plugin_Handled;
}

public Action:Command_TeleporttpMenu(client, args)
{
	if(enableteleporttp == 1)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{
			decl String:name[32];
			decl String:identifier[32];
			
			new Handle:menu = CreateMenu(MenuHandler);
			
			if (args == -1)
			{
				SetMenuExitBackButton(menu,true);
			}
			
			SetMenuTitle(menu, "%t", "TZ menu teleporttp");
			
			new count = 0;
			
			for (new i = 1; i <= MaxClients; i++)
			{
				if (client != i && IsClientInGame(i) && IsPlayerAlive(client) && !IsFakeClient(i) && !IsClientSourceTV(i))  
				{
					GetClientName(i, name, sizeof(name));
					Format(identifier, sizeof(identifier), "%i", i);
					AddMenuItem(menu, identifier, name);
					
					count++;
				}
			}

			SetMenuExitButton(menu, true);
			
			if(count > 0)
			{
				DisplayMenu(menu, client, MENU_TIME_FOREVER);
			}
			else
			{
				PrintToChat(client, MESS, "TZ teleporttp no players");
			}
		}
		else
		{
			PrintToChat(client, MESS, "TZ Dead");
		}
	}
	else
	{
		PrintToChat(client, MESS, "TZ Command disabled");
	}

	return Plugin_Handled;
}

public MenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	decl String:info[32];
	decl String:name[32];
	
	GetMenuItem(menu, param2, info, sizeof(info), _, name, sizeof(name));
	
	new client = StringToInt(info);
	
	if(action == MenuAction_Select)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{
			if(nteleport[client] == 0)
			{
				askmenu(client, param1);
			}
			else
			{
				PrintToChat(param1, MESS, "TZ teleporttp not allowed");
			}
		}
		else
		{
			PrintToChat(param1, MESS, "TZ Dead");
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			Command_trikz(param1,0);
		}
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

askmenu(client, client2)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		decl String:buff[MAX_BUFF];
		new String:asker[255];
		Format(asker, sizeof(asker), "%i", client2);
		
		new Handle:menu = CreateMenu(handler_ask);
		
		SetMenuTitle(menu, "%t", "TZ menu teleporttp ask", client2);
		
		
		Format(buff, sizeof(buff), "%t", "TZ teleporttp menu allow",client);
		AddMenuItem(menu, asker, buff);
		
		Format(buff, sizeof(buff), "%t", "TZ teleporttp menu deny",client);
		AddMenuItem(menu, asker, buff);
		
		Format(buff, sizeof(buff), "%t", "TZ teleporttp menu allways deny",client);
		AddMenuItem(menu, asker, buff);

		SetMenuExitButton(menu, true);

		DisplayMenu(menu, client, 30);
	}
}

public handler_ask(Handle:menu, MenuAction:action, param1, param2)
{
	decl String:info[32];
	decl String:name[32];
	
	GetMenuItem(menu, param2, info, sizeof(info), _, name, sizeof(name));
	
	new client = StringToInt(info);
	
	if(action == MenuAction_Select)
	{
		if(IsClientInGame(param1) && IsPlayerAlive(param1))
		{
			switch(param2)
			{
				case 0:
				{
					new Float:coords[3];
					
					GetEntPropVector(param1, Prop_Send, "m_vecOrigin", coords);
					
					TeleportEntity(client, coords, NULL_VECTOR, NULL_VECTOR);
					
					jteleport[param1]++;
					jteleport[client]++;
					
					bteleport[client] = GetEntProp(client, Prop_Data, "m_CollisionGroup");
					bteleport[param1] = GetEntProp(param1, Prop_Data, "m_CollisionGroup");
					
					if(bteleport[client] != 2)
					{
						SetEntProp(client, Prop_Data, "m_CollisionGroup", 2);
					}
					
					if(bteleport[param1] != 2)
					{
						SetEntProp(param1, Prop_Data, "m_CollisionGroup", 2);
					}
					
					CreateTimer(teleportinvis, teleport_collide, client);
					CreateTimer(teleportinvis, teleport_collide, param1);
					
					new String:s_time[255];
					
					FloatToString(teleportinvis, s_time, sizeof(s_time));
					
					new time = StringToInt(s_time);
					
					PrintToChat(client, MESS, "TZ teleporttp collide for", time);
				}
				case 1:
				{
					PrintToChat(client, MESS, "TZ teleporttp request denied");
				}
				case 2:
				{
					nteleport[param1] = 1;
					
					PrintToChat(param1, MESS, "TZ teleporttp no longer notified");
				}
			}
		}
		else
		{
			PrintToChat(client, MESS, "TZ teleporttp asker no longer available");
		}
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}


public Action:teleport_collide(Handle:timer, any:client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(jteleport[client] == 1)
		{		
			SetEntProp(client, Prop_Data, "m_CollisionGroup", bteleport[client]);
			
			PrintToChat(client, MESS, "TZ teleporttp block setting reset");
			
			
			jteleport[client] = 0;
		}
		else
		{
			jteleport[client]--;
		}
	}
	else
	{
		jteleport[client]--;
	}
}

public OnLibraryAdded(const String:name[])
{
	if(autoupdate == 1 && StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	
	if (StrEqual(name, "SteamTools"))
	{
		g_UseSteamTools = true;
	}
}

public OnLibraryRemoved(const String:name[])
{
	if(autoupdate == 1 && StrEqual(name, "updater"))
	{
		Updater_RemovePlugin();
	}
	
	if (StrEqual(name, "SteamTools"))
	{
		g_UseSteamTools = false;
	}
}

public OnAllPluginsLoaded()
{
	g_UseSteamTools = LibraryExists("SteamTools");
}

//Convar Change
public ConVarChange(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	new nval = StringToInt(newValue);
	
	if(cvar == sm_trikz_enableautoflash)
	{
		enableautoflash = nval;
	}
	else if(cvar == sm_trikz_enableautoflashswitch)
	{
		enableautoflashswitch = nval;
	}
	else if(cvar == sm_trikz_settings)
	{
		if(nval == 1)
		{
			ServerCommand("sv_enablebunnyhopping 1");
			ServerCommand("sv_enableboost 1");
			ServerCommand("mp_friendlyfire 0");
			ServerCommand("sv_airaccelerate %i", airaccelerate);
		}
	}
	else if(cvar == sm_trikz_airaccelerate)
	{
		if(GetConVarInt(sm_trikz_settings) == 1)
		{
			ServerCommand("sv_airaccelerate %i", nval);
		}
	}
	else if(cvar == sm_trikz_ignoreradio)
	{
		if(nval == 1)
		{
			ServerCommand("sv_ignoregrenaderadio 1");
		}
	}
	else if(cvar == sm_trikz_override_gamedesc)
	{
		if(nval == 1)
		{
			override_gamedesc = 1;
			
			if(g_UseSteamTools)
			{
				new String:game_override[255];
				Format(game_override, sizeof(game_override), GAMEDESC);
				Steam_SetGameDescription(game_override);
			}
		}
		else
		{
			override_gamedesc = 0;
			
			if(g_UseSteamTools)
			{
				new String:game_override[255];
				Format(game_override, sizeof(game_override), dGAMEDESC);
				Steam_SetGameDescription(game_override);
			}
		}
	}
	else if(cvar == sm_trikz_add_servertag)
	{
		if(nval == 1)
		{
			ServerCommand("sv_tags %s\n", SERVERTAG);
		}
	}
	else if(cvar == sm_trikz_enableteleport)
	{
		enableteleport = nval;
	}
	else if(cvar == sm_trikz_enableblock)
	{
		enableblock = nval;
	}
	else if(cvar == sm_trikz_enableblockinvis)
	{
		enableblockinvis = nval;
		
		if(nval == 0)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i) && i != 0)
				{
					CreateInvis(i, 255);
				}
			}
		}
	}
	else if(cvar == sm_trikz_enablerespawn)
	{
		enablerespawn = nval;
	}
	else if(cvar == sm_trikz_effects)
	{
		effects = nval;
	}
	else if(cvar == sm_trikz_nofall)
	{
		enablenofall = nval;
	}
	else if(cvar == sm_trikz_autojump)
	{
		enableautojump = nval;
		
		if(nval == 0)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i) && i != 0)
				{
					autojump[i] = 0;
				}
			}
		}
	}
	else if(cvar == sm_trikz_autoupdate)
	{
		if(nval == 1)
		{
			if(autoupdate == 0)
			{
				Updater_AddPlugin(UPDATE_URL);
			}
		}
		else if(nval == 0)
		{
			if(autoupdate == 1)
			{
				Updater_RemovePlugin();
			}
		}
		
		autoupdate = nval;
	}
	else if(cvar == sm_trikz_respawnmin)
	{
		respawnmin = nval;
	}
	else if(cvar == sm_trikz_enableteleporttp)
	{
		enableteleporttp = nval;
	}
	else if(cvar == sm_trikz_teleporttime)
	{
		teleportinvis = StringToFloat(newValue);
	}
}

//Version Change
public VersionChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SetConVarString(convar, PLUGIN_VERSION);
}

//Configs load
public OnConfigsExecuted()
{	
	if(override_gamedesc == 1 && g_UseSteamTools)
	{
		new String:game_override[255];
		Format(game_override, sizeof(game_override), GAMEDESC);
		Steam_SetGameDescription(game_override);
	}
	
	if(ignoreradio == 1)
	{
		ServerCommand("sv_ignoregrenaderadio 1");
	}
	
	if(settings == 1)
	{
		ServerCommand("sv_enablebunnyhopping 1");
		ServerCommand("sv_enableboost 1");
		ServerCommand("mp_friendlyfire 0");
		ServerCommand("sv_airaccelerate %i", airaccelerate);
	}
	
	if(add_servertag == 1)
	{
		ServerCommand("sv_tags %s\n", SERVERTAG);
	}
}

//On Map Start
public OnMapStart()
{
	g_iSmokeSprite = PrecacheModel(SMOKE_SPRITE);
	
	PrecacheSound(EXPLOSION_SOUND, true);

	for (new i=1; i<=MaxClients; i++)
	{
		coords1[i][0] = 0.0;
		coords1[i][1] = 0.0;
		coords1[i][2] = 0.0;
		coords2[i][0] = 0.0;
		coords2[i][1] = 0.0;
		coords2[i][2] = 0.0;
	}
}

// Trikz Menu options?
public Action:Command_trikz(client, args)
{
	if (client && IsClientInGame(client) && !IsFakeClient(client))
	{
		decl String:buff[MAX_BUFF];
		
		new Handle:menu = CreateMenu(MenuHandler_trikz);
		
		SetMenuTitle(menu, "%t", "TZ menu title");
		
		Format(buff,sizeof(buff),"%t","TZ menu flash",client);
		AddMenuItem(menu,"sm_trikz_flash",buff);
		
		if(enableautoflash == 1)
		{
			Format(buff,sizeof(buff),"%t","TZ menu auto title",client);
			AddMenuItem(menu,"sm_trikz_automenu",buff);
		}
		else
		{
			Format(buff,sizeof(buff),"%t","TZ menu auto title disabled",client);
			AddMenuItem(menu,"sm_trikz_automenu",buff);
		}
		
		if(enableblock == 1)
		{
			Format(buff,sizeof(buff),"%t","TZ menu block",client);
			AddMenuItem(menu,"sm_trikz_block",buff);
		}
		else
		{
			Format(buff,sizeof(buff),"%t","TZ menu block disabled",client);
			AddMenuItem(menu,"sm_trikz_block",buff);
		}
		
		if(enableautojump == 1)
		{
			Format(buff,sizeof(buff),"%t","TZ menu autojump",client);
			AddMenuItem(menu,"sm_trikz_autojump",buff);
		}
		else
		{
			Format(buff,sizeof(buff),"%t","TZ menu autojump disabled",client);
			AddMenuItem(menu,"sm_trikz_autojump",buff);
		}
		
		if(enableteleport == 1)
		{
			Format(buff,sizeof(buff),"%t","TZ menu checkpoints",client);
			AddMenuItem(menu,"sm_trikz_tpmenu",buff);
		}
		else
		{
			Format(buff,sizeof(buff),"%t","TZ menu checkpoints disabled",client);
			AddMenuItem(menu,"sm_trikz_tpmenu",buff);
		}
		
		if(enableteleporttp == 1)
		{
			Format(buff,sizeof(buff),"%t","TZ menu teleporttp",client);
			AddMenuItem(menu,"sm_trikz_teleporttp",buff);
		}
		else
		{
			Format(buff,sizeof(buff),"%t","TZ menu teleporttp disabled",client);
			AddMenuItem(menu,"sm_trikz_teleporttp",buff);
		}
		
		if(enablerespawn == 1)
		{
			Format(buff,sizeof(buff),"%t","TZ menu respawn",client);
			AddMenuItem(menu,"sm_trikz_respawn",buff);
		}
		else
		{
			Format(buff,sizeof(buff),"%t","TZ menu respawn disabled",client);
			AddMenuItem(menu,"sm_trikz_respawn",buff);
		}
		
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
	
	return Plugin_Handled;
}

// Trikz Funcs
public MenuHandler_trikz(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
		switch (param2)
	{
		case 0:
		{
			Command_Flash(param1,0);
			Command_trikz(param1,-1);
		}
		case 1:
		{
			if(enableautoflash == 1)
			{
				Command_AutoMenu(param1,-1);
			}
			else
			{
				PrintToChat(param1, MESS, "TZ Command disabled");
			}
		}
		case 2:
		{
			if(enableautoflash == 1)
			{
				Command_Block(param1,-1);
				Command_trikz(param1,-1);
			}
			else
			{
				Command_trikz(param1,-1);
				PrintToChat(param1, MESS, "TZ Command disabled");
			}
		}
		case 3:
		{
			if(enableautojump == 1)
			{
				Command_Autojump(param1,-1);
				Command_trikz(param1,-1);
			}
			else
			{
				Command_trikz(param1,-1);
				PrintToChat(param1, MESS, "TZ Command disabled");
			}
		}
		case 4:
		{
			if(enableteleport == 1)
			{
				Command_TPMenu(param1,-1);
			}
			else
			{
				Command_trikz(param1,-1);
				PrintToChat(param1, MESS, "TZ Command disabled");
			}
		}
		case 5:
		{
			if(enableteleporttp == 1)
			{
				Command_TeleporttpMenu(param1,-1);
			}
			else
			{
				Command_trikz(param1,-1);
				PrintToChat(param1, MESS, "TZ Command disabled");
			}
		}
		case 6:
		{
			if(enablerespawn == 1)
			{
				Command_Respawn(param1,0);
				Command_trikz(param1,-1);
			}
			else
			{
				Command_trikz(param1,-1);
				PrintToChat(param1, MESS, "TZ Command disabled");
			}
		}
	} 
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

//AutoMenu
public Action:Command_AutoMenu(client, args)
{
	if (client && IsClientInGame(client) && !IsFakeClient(client))
	{
		if(enableautoflash == 1)
		{
			decl String:buff[MAX_BUFF];
			
			new Handle:menu = CreateMenu(MenuHandler_auto);
			if (args == -1) SetMenuExitBackButton(menu,true);
			
			SetMenuTitle(menu, "%t", "TZ menu auto title");
		
			Format(buff,sizeof(buff),"%t","TZ menu autoflash",client);
			AddMenuItem(menu,"sm_trikz_autoflash",buff);
			
			if(enableautoflashswitch == 1 && enableautoflash == 1)
			{
				Format(buff,sizeof(buff),"%t","TZ menu autoflash switch",client);
				AddMenuItem(menu,"sm_trikz_autoflashswitch",buff);
			}
			else
			{
				Format(buff,sizeof(buff),"%t","TZ menu autoflash switch disabled",client);
				AddMenuItem(menu,"sm_trikz_autoflashswitch",buff);
			}
		
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
		}
		else
		{
			PrintToChat(client, MESS, "TZ Command disabled");
		}
	}
	
	return Plugin_Handled;
}

//Auto Funcs
public MenuHandler_auto(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select :
		switch (param2)
		{
			case 0 :
			{
				if(enableautoflash == 1)
				{
					Command_AutoFlash(param1,0);
				}
				else
				{
					PrintToChat(param1, MESS, "TZ Command disabled");
				}
				
				Command_AutoMenu(param1,-1);
			}
			case 1 :
			{
				if(enableautoflashswitch == 1)
				{
					Command_AutoFlashSwitch(param1,0);
				}
				else
				{
					PrintToChat(param1, MESS, "TZ Command disabled");
				}
				
				Command_AutoMenu(param1,-1);
			}
		}
		case MenuAction_Cancel :
		if (param2 == MenuCancel_ExitBack) Command_trikz(param1,0);
		
		case MenuAction_End :
		CloseHandle(menu);
	}
}

public Action:Command_TPMenu(client, args)
{
	if(enableteleport == 1)
	{
		if (client && IsClientInGame(client) && !IsFakeClient(client))
		{
			decl String:buff[MAX_BUFF];
			
			new Handle:menu = CreateMenu(MenuHandler_TPMenu);
			if (args == -1) SetMenuExitBackButton(menu,true);
			
			SetMenuTitle(menu, "%t", "TZ menu checkpoints");
			
			if(enableteleport == 1)
			{
				Format(buff,sizeof(buff),"%t","TZ menu save 1",client);
				AddMenuItem(menu,"sm_save1",buff);
				
				Format(buff,sizeof(buff),"%t","TZ menu teleport 1",client);
				AddMenuItem(menu,"sm_tele1",buff);
			}
			else
			{
				Format(buff,sizeof(buff),"%t","TZ menu save 1 disabled",client);
				AddMenuItem(menu,"sm_save1",buff);
				
				Format(buff,sizeof(buff),"%t","TZ menu teleport 1 disabled",client);
				AddMenuItem(menu,"sm_tele1",buff);
			}
			
			
			AddMenuItem(menu,"sep","",ITEMDRAW_SPACER);
			
			
			if(enableteleport == 1)
			{
				Format(buff,sizeof(buff),"%t","TZ menu save 2",client);
				AddMenuItem(menu,"sm_save2",buff);
				
				Format(buff,sizeof(buff),"%t","TZ menu teleport 2",client);
				AddMenuItem(menu,"sm_tele2",buff);
			}
			else
			{
				Format(buff,sizeof(buff),"%t","TZ menu save 2 disabled",client);
				AddMenuItem(menu,"sm_save2",buff);
				
				Format(buff,sizeof(buff),"%t","TZ menu teleport 2 disabled",client);
				AddMenuItem(menu,"sm_tele2",buff);
			}
			
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
		}
	}
	else
	{
		PrintToChat(client, MESS, "TZ Command disabled");
	}
	
	return Plugin_Handled;
}

//Teleport Funcs
public MenuHandler_TPMenu(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select :
		switch (param2)
		{
			case 0 :
			{
				Command_Save1(param1,0);
				Command_TPMenu(param1,-1);
			}
			case 1 :
			{
				Command_tele1(param1,0);
				Command_TPMenu(param1,-1);
			}
			case 3 :
			{
				Command_Save2(param1,0);
				Command_TPMenu(param1,-1);
			}
			case 4 :
			{
				Command_tele2(param1,0);
				Command_TPMenu(param1,-1);
			}
		}
		case MenuAction_Cancel :
		if (param2 == MenuCancel_ExitBack) Command_trikz(param1,0);
		
		case MenuAction_End :
		CloseHandle(menu);
	}
}

//Autojump command
public Action:Command_Autojump(client, args)
{
	if(enableautojump == 1)
	{
		if(autojump[client] == 1)
		{
			autojump[client] = 0;
			PrintToChat(client, MESS, "TZ autojump off");
		}
		else if(autojump[client] == 0)
		{
			autojump[client] = 1;
			PrintToChat(client, MESS, "TZ autojump on");
		}
	}
	else
	{
		PrintToChat(client, MESS, "TZ Command disabled");
	}

	return Plugin_Handled;
}

//Block
public Action:Command_Block(client, args)
{
	if(enableblock == 1)
	{
		if (IsPlayerAlive(client))
		{
			new col = GetEntProp(client, Prop_Data, "m_CollisionGroup");
			
			if (col == 5)
			{
				if(jteleport[client] >= 1)
				{
					bteleport[client] = 2;
					
					PrintToChat(client, MESS, "TZ teleporttp block setting later");
				}
				else
				{
					SetEntProp(client, Prop_Data, "m_CollisionGroup", 2);
					PrintToChat(client, MESS, "TZ block off");
					
					if(enableblockinvis == 1)
					{
						CreateInvis(client, 100);
					}
				}
			}
			else
			{
				if(jteleport[client] >= 1)
				{
					bteleport[client] = 5;
					
					PrintToChat(client, MESS, "TZ teleporttp block setting later");
				}
				else
				{
					SetEntProp(client, Prop_Data, "m_CollisionGroup", 5);
					PrintToChat(client, MESS, "TZ block on");
						
					if(enableblockinvis == 1)
					{
						CreateInvis(client, 255);
					}
				}
			}
		}
		else
		{
			PrintToChat(client, MESS, "TZ Dead");
		}
	}
	else
	{
		PrintToChat(client, MESS, "TZ Command disabled");
	}
	
	return Plugin_Handled;
}

// Respawn
public Action:Command_Respawn(client, args)
{
	if(enablerespawn == 1)
	{
		if (IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) > 1)
		{
			if(respawnmin != 0)
			{
				if(crespawns[client] >= respawnmin)
				{
					new Float:currenttime = lastrespawn[client] + 60.0;
					
					if(currenttime > GetTickedTime())
					{
						PrintToChat(client, MESS, "TZ respawn min", respawnmin);
						
						return Plugin_Handled;
					}
					else
					{
						lastrespawn[client] = GetTickedTime();
						crespawns[client] 	= 1;
					}
				}
				else
				{
					lastrespawn[client] = GetTickedTime();
					crespawns[client]++;
				}
			}
				
			CS_RespawnPlayer(client);
			PrintToChat(client, MESS, "TZ respawn");
		}
		else
		{
			PrintToChat(client, MESS, "TZ Spec respawn");
		}
		return Plugin_Handled;
	}
	else
	{
		PrintToChat(client, MESS, "TZ Command disabled");
	}
	
	return Plugin_Handled;
}

//Weapon Fire
public Action:Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	decl String:weapon[MAX_BUFF];
	GetEventString(event,"weapon",weapon,sizeof(weapon));
	
	if (StrEqual(weapon,"flashbang"))
	{
		if(autoflash[client])
		{
			give(client);
			
			if(autoswitch[client] == 1)
			{
				CreateTimer(0.15, selectf, client);
			}
		}
	}
}

public Action:selectf(Handle:timer, any:client)
{
	FakeClientCommand(client, "use weapon_knife");
	FakeClientCommand(client, "use weapon_flashbang");
}

//Flashbang created
public OnEntityCreated(edict, const String:classname[])
{
	if (IsValidEdict(edict) && IsValidEntity(edict) && StrEqual(classname, "flashbang_projectile"))
	{
		CreateTimer(1.2, Timer_RemoveFlashbang, edict);
	}
}

//Remove Flashbang
public Action:Timer_RemoveFlashbang(Handle:timer, any:edict)
{
	decl String:classname[MAX_BUFF];
	GetEdictClassname(edict,classname,sizeof(classname));
	if (!IsValidEdict(edict) || !IsValidEntity(edict) || !StrEqual(classname, "flashbang_projectile"))
	{
		return Plugin_Stop;
	}
	if(effects != 0)
	{
		new Float:fPos[3];
		GetEntPropVector(edict, Prop_Send, "m_vecOrigin", fPos);
		
		if(effects == 1)
		{
			TE_SetupSparks(fPos, NULL_VECTOR, 1, 2);
			TE_SendToAll();
			TE_SetupSmoke(fPos, g_iSmokeSprite, 1.0, 15);
			TE_SendToAll();
		}
		else if(effects == 2)	
		{
			EmitAmbientSound(EXPLOSION_SOUND, fPos);
		}
		else if(effects == 3)
		{
			TE_SetupSparks(fPos, NULL_VECTOR, 1, 2);
			TE_SendToAll();
			TE_SetupSmoke(fPos, g_iSmokeSprite, 1.0, 15);
			TE_SendToAll();
			
			EmitAmbientSound(EXPLOSION_SOUND, fPos);
		}
	}
	
	AcceptEntityInput(edict, "Kill");
	return Plugin_Stop;
}

//Command Flash
public Action:Command_Flash(client, args)
{
	if (IsPlayerAlive(client))
	{
		if (client && IsClientInGame(client) && !IsFakeClient(client))
		{
			if(autoflash[client])
			{
				PrintToChat(client, MESS, "TZ autoflash flash");
			}
			else
			{
				new flashbangs = GetClientFlashBangs(client);
				
				if(flashbangs >= 2)
				{
					PrintToChat(client, MESS, "TZ flashbangs");
				}
				else
				{
					PrintToChat(client, MESS, "TZ flash");
					give(client);
				}
			}
		}
	}
	else
	{
		PrintToChat(client, MESS, "TZ Dead");
	}
	return Plugin_Handled;
}

//Autoflash
public Action:Command_AutoFlash(client, args)
{
	if(enableautoflash == 1)
	{
		auto(client, 0);
		return Plugin_Handled;
	}
	else
	{
		PrintToChat(client, MESS, "TZ Command disabled");
	}
	
	return Plugin_Handled;
}

//AutoflashSwitch
public Action:Command_AutoFlashSwitch(client, args)
{
	if(enableautoflashswitch == 1 && enableautoflash == 1)
	{
		auto(client, 1);
		return Plugin_Handled;
	}
	else
	{
		PrintToChat(client, MESS, "TZ Command disabled");
	}
	
	return Plugin_Handled;
}

auto(client, opt)
{
	if(IsPlayerAlive(client))
	{
		if(opt == 1)
		{
			if(autoswitch[client] == 1)
			{
				autoswitch[client] = 0;
				
				PrintToChat(client, MESS, "TZ autoflashswitch off");
			}
			else
			{
				autoswitch[client] = 1;
				
				PrintToChat(client, MESS, "TZ autoflashswitch on");
				
				if(autoflash[client] == 0)
				{
					autoflash[client] = 1;
					PrintToChat(client, MESS, "TZ autoflash on");
				
					if(GetClientFlashBangs(client) == 0)
					{
						give(client);
					}
				}
				
				new String:weapon_name[255];
	
				GetClientWeapon(client, weapon_name, sizeof(weapon_name));
					
				if(strcmp(weapon_name, "weapon_flashbang") == 1)
				{
					CreateTimer(0.15, selectf, client);
				}
			}
		}
		else
		{
			if(autoflash[client] == 1)
			{
				autoflash[client] = 0;
				PrintToChat(client, MESS, "TZ autoflash off");
				
				if(autoswitch[client] == 1)
				{
					autoswitch[client] = 0;
					PrintToChat(client, MESS, "TZ autoflashswitch off");
				}
			}
			else
			{
				autoflash[client] = 1;
				PrintToChat(client, MESS, "TZ autoflash on");
				
				if(GetClientFlashBangs(client) == 0)
				{
					give(client);
				}
			}
		}
	}
	else
	{
		PrintToChat(client, MESS, "TZ Dead");
	}
}

//Client Put Server
public OnClientPutInServer(client)
{
	if(enablenofall == 1)
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
	
	CreateTimer(5.0, welcome, client);
}

//Welcome
public Action:welcome(Handle:timer, any:client)
{
	if(IsClientInGame(client) && !IsFakeClient(client))
	{
		PrintToChat(client, MESS, "TZ autohi");
	}
	
	return Plugin_Stop;
}

//Spawn
public Action:Event_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	
	if(GetClientTeam(client) >= 2)
	{
		strip(client);
	}
}

//Save1 Loc
public Action:Command_Save1(client, args)
{
	if(enableteleport == 1)
	{
		if (IsPlayerAlive(client))
		{
			if (GetEntDataEnt2(client, m_GroundEntity) != -1)
			{
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", coords1[client]);
				PrintToChat(client, MESS, "TZ save 1");
			}
			else
			{
				PrintToChat(client, MESS, "TZ Ground");
			}
		}
		else
		{
			PrintToChat(client, MESS, "TZ Dead");
		}
	}
	
	
	return Plugin_Handled;
}

//Teleport1
public Action:Command_tele1(client, args)
{	if(enableteleport == 1)
	{
		if (IsPlayerAlive(client))
		{
			if(!(coords1[client][0] == 0.0 && coords1[client][1] == 0.0 && coords1[client][2] == 0.0))
			{
				TeleportEntity(client, coords1[client], NULL_VECTOR, NULL_VECTOR);
				PrintToChat(client, MESS, "TZ teleport 1");
			}
			else
			{
				PrintToChat(client, MESS,"TZ no teleport");
			}
		}
		else
		{
			PrintToChat(client, MESS, "TZ Dead");
		}
	}
	
	return Plugin_Handled;
}

//Save2 Loc
public Action:Command_Save2(client, args)
{	if(enableteleport == 1)
	{
		if (IsPlayerAlive(client))
		{
			if (GetEntDataEnt2(client, m_GroundEntity) != -1)
			{
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", coords2[client]);
				PrintToChat(client, MESS, "TZ save 2");
			}
			else
			{
				PrintToChat(client, MESS, "TZ Ground");
			}
		}
		else
		{
			PrintToChat(client, MESS, "TZ Dead");
		}
	}
	
	return Plugin_Handled;
}

//Teleport2
public Action:Command_tele2(client, args)
{	if(enableteleport == 1)
	{
		if (IsPlayerAlive(client))
		{
			if(!(coords1[client][0] == 0.0 && coords1[client][1] == 0.0 && coords2[client][2] == 0.0))
			{
				TeleportEntity(client, coords2[client], NULL_VECTOR, NULL_VECTOR);
				PrintToChat(client, MESS, "TZ teleport 2");
			}
			else
			{
				PrintToChat(client, MESS,"TZ no teleport");
			}
		}
		else
		{
			PrintToChat(client, MESS, "TZ Dead");
		}
	}
	
	return Plugin_Handled;
}

//On Take Damage
public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(enablenofall == 1)
	{
		if (damagetype & DMG_FALL)
		{
			return Plugin_Stop;
		}
	}
	
	return Plugin_Continue;
}

//When player runs CMD (AutoJump)
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(Client_IsOnLadder(client) || Client_GetWaterLevel(client) > Water_Level:WATER_LEVEL_FEET_IN_WATER)
	{
		return Plugin_Continue;
	}

	if(enableautojump && IsPlayerAlive(client) && autojump[client] == 1)
	{
		if (buttons & IN_JUMP)
		{
			if (!(GetEntityFlags(client) & FL_ONGROUND))
			{
				buttons &= ~IN_JUMP;
			}
		}
	}
	
	return Plugin_Continue;
}


//Give
give(client)
{
	GivePlayerItem(client, "weapon_flashbang");
}

stock GetClientFlashBangs(client)
{
	new String:weaponn[255];
	
	for(new i = 0, weapon; i < 128; i += 4)
	{
		weapon = GetEntDataEnt2(client, m_hMyWeapons + i);
		
		if(weapon != -1)
		{
			GetEdictClassname(weapon, weaponn, sizeof(weaponn));
			
			if(StrEqual(weaponn, "weapon_flashbang"))
			{
				new iPrimaryAmmoType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 4);
				new ammo = GetEntData(client, ammoOffset+(iPrimaryAmmoType*4));
				
				return ammo;
			}
		}
	}
	
	return 0;
}

//Strip
strip(client)
{
	for(new i = 0, weapon; i < 128; i += 4)
	{
		weapon = GetEntDataEnt2(client, m_hMyWeapons + i);
		
		if(weapon != -1)
		{
			RemovePlayerItem(client, weapon);
		}
	}
	
	GivePlayerItem(client, "weapon_knife");
	GivePlayerItem(client, "weapon_usp");
	GivePlayerItem(client, "weapon_flashbang");
}

//Start Creating Invis
CreateInvis(target, alpha)    
{
	SetAlpha(target,alpha);
}

//Player Invis
SetAlpha(target, alpha)
{        
	SetWeaponsAlpha(target,alpha);
	SetEntityRenderMode(target, RENDER_TRANSCOLOR);
	SetEntityRenderColor(target, 255, 255, 255, alpha);    
}

//Weapon Invis
SetWeaponsAlpha(target, alpha)
{
	if(IsPlayerAlive(target))
	{
		for(new i = 0, weapon; i < 47; i += 4)
		{
			weapon = GetEntDataEnt2(target, m_hMyWeapons + i);
			
			if(weapon > -1 )
			{
				SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
				SetEntityRenderColor(weapon, 255, 255, 255, alpha);
			}
		}
	}
}