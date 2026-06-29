/* 
* Godclip
* Author(s): -MCG-Retsam
* File: sm_godclip.sp
* Description: Gives admins/players godmode, invisibility, and noclip.
*
* 1.1 - Updated invisibility code slightly. New invis code could possibly fix some errors in tf2 as well as checking some spy stuff.
*       Added <tf2_stocks> because of tf2 class check for invis.
*       Added game MOD lookup for some additional checks as well.
*       Optional SDKhooks: Recoded plugin so it works with or without SDKhooks.
*       Few other minor things.
*       
* 1.0 - Fixed incorrect post hook callbacks.
* 0.9 - Added spawn hook to remove godclip that was leftover from the round-ending.
* 0.8 - Added a displaymode cvar for hit detection output. Can toggle between printtochat output or display panel. Added steamid info.
*       Changed ADMINFLAG to BAN access instead of SLAY.  Put Delaytimer on chat outout.
* 0.7 - Fixed demomans shield not being invisible. Recoded the method for getting convar changes.
* 0.6 - Fixed few coding mistakes.
* 0.5 - No longer shows activity to public(IE the enabled/disabled msg).
* 0.4 - Added and fixed a few of the checks in hurt hook. Removed the version cvar from the auto-created config.
* 0.3 - Removed cvar for hit detection. Removed checking for admins for hit detection. Added cvar for noclip.
* 0.2	- Removed class code so able to merge both versions. Removed a global var for hurt hook, used a client indexd value instead. Used a different method for godmode for mode 1.
* 0.1	- Initial Release
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools_functions>
#undef REQUIRE_EXTENSIONS
#include <sdkhooks>
#undef AUTOLOAD_EXTENSIONS
#include <tf2_stocks>
#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_VERSION "1.1"

//Define Invis stuff
#define INVIS					{255,255,255,0}
#define NORMAL					{255,255,255,255}

new Handle:hAdminMenu = INVALID_HANDLE;
new Handle:g_Cvar_GodMode = INVALID_HANDLE;
new Handle:g_Cvar_Invismode = INVALID_HANDLE;
new Handle:g_Cvar_Noclipmode = INVALID_HANDLE;
new Handle:g_Cvar_DisplayMode = INVALID_HANDLE;

enum e_SupportedMods
{
	Game_Unknown,
	Game_CSS,
	Game_DODS,
	Game_HL2MP,
	Game_FOF,
	Game_TF,
	Game_L4D,
	Game_INSMOD,
	Game_FF,
	GameType_L4D2,
	Game_ZPS,
	Game_AOC,
	Game_GES
};

new e_SupportedMods:g_CurrentMod;

new g_displayDelayChk[MAXPLAYERS+1] = { 0, ... };
new g_Target[MAXPLAYERS+1] = { 0, ... };
new targethealth[MAXPLAYERS+1] = { 0, ... };

new g_wearableOffset;
new g_shieldOffset;
new godclipmode;
new invismode;
new noclipmode;
new displaymode;

new bool:g_bUseSDKhooks;

public Plugin:myinfo = 
{
	name = "Godclip",
	author = "-MCG-retsam",
	description = "Gives admins/players godmode, invisibility, and noclip at the same time.",
	version = PLUGIN_VERSION,
	url = "www.multiclangaming.net"
};

public OnPluginStart()
{
	g_CurrentMod = GetGame();

	CreateConVar("sm_godclip_version", PLUGIN_VERSION, "Godclip Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_Cvar_GodMode = CreateConVar("sm_godclip_mode", "1", "Godmode type for godclip. (0/1/2) 0=no god, 1=return health lost/hit detection, 2=true godmode(take no dmg/no hit detection)");
	g_Cvar_Invismode = CreateConVar("sm_godclip_invis", "1", "Invisibility during godclip? (1/0 = yes/no)");
	g_Cvar_Noclipmode = CreateConVar("sm_godclip_noclip", "1", "Noclip during godclip? (1/0 = yes/no)");
	g_Cvar_DisplayMode = CreateConVar("sm_godclip_displaymode", "0", "Display mode for godmode(mode1). (0/1) 0=simple printtochat text of attacker name/steamid. 1=display panel with name/steamid.");

	RegAdminCmd("sm_godclip", Command_Godclip, ADMFLAG_BAN, "sm_godclip <#userid|name>");

	//HookEvent("player_hurt", Hook_PlayerHurt);
	HookEvent("player_death", Hook_PlayerDeath);
	HookEvent("player_spawn", Hook_PlayerSpawn);

	HookConVarChange(g_Cvar_GodMode, Cvars_Changed);
	HookConVarChange(g_Cvar_Invismode, Cvars_Changed);
	HookConVarChange(g_Cvar_Noclipmode, Cvars_Changed);
	HookConVarChange(g_Cvar_DisplayMode, Cvars_Changed);

	g_wearableOffset = FindSendPropInfo("CTFWearableItem", "m_hOwnerEntity");
	g_shieldOffset = FindSendPropInfo("CTFWearableItemDemoShield", "m_hOwnerEntity");

	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}

	AutoExecConfig(true, "sm_godclip");
}

public OnAllPluginsLoaded()
{
	new String:sExtError[256];
	new iExtStatus = GetExtensionFileStatus("sdkhooks.ext", sExtError, sizeof(sExtError));
	if (iExtStatus == -2)
	{
		PrintToServer("[sm_godclip.sp] SDK Hooks extension was not found.");
		PrintToServer("[sm_godclip.sp] Plugin continued to load, but will run in Non-SDKhooks mode.");
		HookEvent("player_hurt", Hook_PlayerHurt);
		g_bUseSDKhooks = false;
	}
	if (iExtStatus == -1 || iExtStatus == 0)
	{
		PrintToServer("[sm_godclip.sp] SDK Hooks extension is loaded with errors.");
		PrintToServer("[sm_godclip.sp] Status reported was [%s].", sExtError);
		PrintToServer("[sm_godclip.sp] Plugin continued to load, but will run in Non-SDKhooks mode.");
		HookEvent("player_hurt", Hook_PlayerHurt);
		g_bUseSDKhooks = false;
	}
	if (iExtStatus == 1)
	{
		PrintToServer("[sm_godclip.sp] SDK Hooks extension is loaded.");
		PrintToServer("[sm_godclip.sp] Plugin will use SDK Hooks.");
		g_bUseSDKhooks = true;
	}
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("SDKHook");

	return APLRes_Success;
}

public OnClientPostAdminCheck(client)
{
	g_Target[client] = 0;
	g_displayDelayChk[client] = 0;
	
	if(g_bUseSDKhooks)
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public OnConfigsExecuted()
{
	godclipmode = GetConVarInt(g_Cvar_GodMode);
	invismode = GetConVarInt(g_Cvar_Invismode);
	noclipmode = GetConVarInt(g_Cvar_Noclipmode);
	displaymode = GetConVarInt(g_Cvar_DisplayMode);
}

public OnClientDisconnect(client)
{
	g_Target[client] = 0;
}

public Action:Command_Godclip(client, args)
{
	decl String:target[65];
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;
	
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_godclip <#userid|name>");
		return Plugin_Handled;
	}
	
	GetCmdArg(1, target, sizeof(target));
	
	if((target_count = ProcessTargetString(
					target,
					client,
					target_list,
					MAXPLAYERS,
					0,
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for(new i = 0; i < target_count; i++)
	{
		if(IsClientInGame(target_list[i]) && IsPlayerAlive(target_list[i]))
		{
			PerformGodClip(client, target_list[i]);
		}
	}
	return Plugin_Handled;
}

PerformGodClip(client, target)
{
	if(g_Target[target] == 0)
	{
		targethealth[target] = GetClientHealth(target);
		g_displayDelayChk[target] = 0;
		g_Target[target] = 1;
		
		if(noclipmode != 0)
		SetEntityMoveType(target, MOVETYPE_NOCLIP);
		
		if(invismode != 0)
		Colorize(target, INVIS);

		if(godclipmode == 2)
		SetEntProp(target, Prop_Data, "m_takedamage", 0, 1);
		
		LogAction(client, target, "\"%L\" enabled godclip on \"%L\"", client, target);
		PrintToChat(client, "[SM] enabled godclip on %N", target);
	}
	else
	{
		g_Target[target] = 0;
		
		if(noclipmode != 0)
		SetEntityMoveType(target, MOVETYPE_WALK);
		
		if(invismode != 0)
		Colorize(target, NORMAL);
		
		if(godclipmode == 2)
		SetEntProp(target, Prop_Data, "m_takedamage", 2, 1);
		
		LogAction(client, target, "\"%L\" disabled godclip on \"%L\"", client, target);
		PrintToChat(client, "[SM] disabled godclip on %N", target);
	}
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{	
	if(godclipmode != 1)
	return Plugin_Continue;

	//PrintToChatAll("SDKhooks: OnTakeDamage fired");
	if(victim > 0 && victim <= MaxClients)
	{
		if(g_Target[victim] == 1)
		{						
			damage = 0.0;

			if(attacker > 0 && attacker <= MaxClients)
			{
				if(IsClientInGame(attacker) && attacker != victim)
				{
					if(displaymode == 0)
					{
						if(g_displayDelayChk[victim] == 0)
						{
							g_displayDelayChk[victim] = 1;
							decl String:sSteamID[64];
							GetClientAuthString(attacker, sSteamID, sizeof(sSteamID));
							
							PrintToChat(victim, "\x01[GODCLIP] Attacker:  \x04%N [\x01%s\x04]\x01", attacker, sSteamID);
							CreateTimer(1.0, Timer_DisplayDelay, victim, TIMER_FLAG_NO_MAPCHANGE);
						}
					}
					else
					{
						new Handle:hPanel = BuildPlayerHudPanel(victim, attacker);
						SendPanelToClient(hPanel, victim, Panel_PlayerHud, MENU_TIME_FOREVER);
						CloseHandle(hPanel);
					}
				}
			}

			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}

public Hook_PlayerHurt(Handle:event,  const String:name[], bool:dontBroadcast)
{
	//PrintToChatAll("Hook_PlayerHurt: fired");
	if(godclipmode != 1 || g_bUseSDKhooks)
	return;

	new client = GetClientOfUserId(GetEventInt(event,"userid"));

	if(client < 1 || client > MaxClients)
	return;

	if(IsPlayerAlive(client) && g_Target[client] == 1)
	{
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		new health   = GetEventInt(event, "health");
		
		new damage = targethealth[client] - health;
		targethealth[client]  = health + damage;
		
		SetEntityHealth(client, targethealth[client]);
		
		if(attacker > 0)
		{
			if(IsClientInGame(attacker) && client != attacker)
			{
				if(displaymode == 0)
				{
					if(g_displayDelayChk[client] == 0)
					{
						g_displayDelayChk[client] = 1;
						decl String:sSteamID[64];
						GetClientAuthString(attacker, sSteamID, sizeof(sSteamID));
						
						PrintToChat(client, "\x01[GODCLIP] Attacker:  \x04%N [\x01%s\x04]\x01", attacker, sSteamID);
						CreateTimer(1.0, Timer_DisplayDelay, client, TIMER_FLAG_NO_MAPCHANGE);
					}
				}
				else
				{
					new Handle:hPanel = BuildPlayerHudPanel(client, attacker);
					SendPanelToClient(hPanel, client, Panel_PlayerHud, MENU_TIME_FOREVER);
					CloseHandle(hPanel);
				}
			}
		}
	}  
}

public Hook_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(client < 1)
	return;

	if(g_Target[client] == 1)
	{
		Colorize(client, NORMAL);
		g_Target[client] = 0;
	}
}

public Hook_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(client < 1)
	return;

	if(g_Target[client] == 1)
	{
		Colorize(client, NORMAL);
		g_Target[client] = 0;
		
		if(GetEntProp(client, Prop_Data, "m_takedamage", 1) == 0)
		{
			SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		}
	}
}



public Action:Timer_DisplayDelay(Handle:timer, any:client)
{
	g_displayDelayChk[client] = 0;
}

stock Handle:BuildPlayerHudPanel(client, attacker)
{
	decl  String:sTargetName[MAX_NAME_LENGTH + 1],
String:sTargetID[64];
	
	decl  String:sDisplayName[MAX_NAME_LENGTH + 1],
String:sDisplayID[64];

	GetClientName(attacker, sTargetName, sizeof(sTargetName));
	GetClientAuthString(attacker, sTargetID, sizeof(sTargetID));

	Format(sDisplayName, sizeof(sDisplayName), "Name:  %s", sTargetName);
	Format(sDisplayID, sizeof(sDisplayID), "SteamID:  %s", sTargetID);

	new Handle:hPanel = CreatePanel();
	SetPanelTitle(hPanel, "Attacker Information:");
	DrawPanelText(hPanel, sDisplayName);
	DrawPanelText(hPanel, sDisplayID);
	
	DrawPanelItem(hPanel, "Close.");
	
	return hPanel;
}

public Panel_PlayerHud(Handle:menu, MenuAction:action, param1, param2)
{
	return;
}

public Colorize(client, color[4])
{
	new maxents = GetMaxEntities();
	// Colorize player and weapons
	new m_hMyWeapons = FindSendPropOffs("CBasePlayer", "m_hMyWeapons");	

	for(new i = 0, weapon; i < 47; i += 4)
	{
		weapon = GetEntDataEnt2(client, m_hMyWeapons + i);
		
		if(weapon > -1 )
		{
			decl String:strClassname[250];
			GetEdictClassname(weapon, strClassname, sizeof(strClassname));
			//PrintToChatAll("strClassname is: %s", strClassname);
			if(g_CurrentMod == Game_TF)
			{
				if(StrContains(strClassname, "tf_weapon") == -1) continue;
			}
			
			SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
			SetEntityRenderColor(weapon, color[0], color[1],color[2], color[3]);
		}
	}
	
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);	
	SetEntityRenderColor(client, color[0], color[1], color[2], color[3]);
	
	// Colorize any wearable items
	for(new i=MaxClients+1; i <= maxents; i++)
	{
		if(!IsValidEntity(i)) continue;
		
		decl String:netclass[32];
		GetEntityNetClass(i, netclass, sizeof(netclass));
		
		if(strcmp(netclass, "CTFWearableItem") == 0)
		{
			if(GetEntDataEnt2(i, g_wearableOffset) == client)
			{
				SetEntityRenderMode(i, RENDER_TRANSCOLOR);
				SetEntityRenderColor(i, color[0], color[1], color[2], color[3]);
			}
		}else if(strcmp(netclass, "CTFWearableItemDemoShield") == 0)
		{
			if(GetEntDataEnt2(i, g_shieldOffset) == client)
			{
				SetEntityRenderMode(i, RENDER_TRANSCOLOR);
				SetEntityRenderColor(i, color[0], color[1], color[2], color[3]);
			}
		}
	}
	
	if(g_CurrentMod == Game_TF)
	{
		if(TF2_GetPlayerClass(client) == TFClass_Spy)
		{
			new iWeapon = GetEntPropEnt(client, Prop_Send, "m_hDisguiseWeapon");
			if(iWeapon && IsValidEntity(iWeapon))
			{
				SetEntityRenderMode(iWeapon, RENDER_TRANSCOLOR);
				SetEntityRenderColor(iWeapon, color[0], color[1], color[2], color[3]);
			}
		}
	}
	
	return;
}

public OnLibraryAdded(const String:name[])
{
	//PrintToChatAll("OnLibraryAdded is: %s", name);
	if(StrEqual(name, "sdkhooks.ext"))
	{
		g_bUseSDKhooks = true;
		UnhookEvent("player_hurt", Hook_PlayerHurt);
	}
}

public OnLibraryRemoved(const String:name[])
{
	//PrintToChatAll("OnLibraryRemoved is: %s", name);
	if(StrEqual(name, "adminmenu")) 
	{
		hAdminMenu = INVALID_HANDLE;
	}
	
	if(StrEqual(name, "sdkhooks.ext"))
	{
		g_bUseSDKhooks = false;
		HookEvent("player_hurt", Hook_PlayerHurt);
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == hAdminMenu)
	{
		return;
	}
	
	hAdminMenu = topmenu;

	new TopMenuObject:player_commands = FindTopMenuCategory(hAdminMenu, ADMINMENU_PLAYERCOMMANDS);

	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hAdminMenu,
		"sm_godclip",
		TopMenuObject_Item,
		AdminMenu_Godclip, 
		player_commands,
		"sm_godclip",
		ADMFLAG_BAN);
	}
}

public AdminMenu_Godclip( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength )
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Godclip player");
	}
	else if( action == TopMenuAction_SelectOption)
	{
		DisplayPlayerMenu(param);
	}
}

DisplayPlayerMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_Players);
	
	decl String:title[100];
	Format(title, sizeof(title), "Choose Player:");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	AddTargetsToMenu(menu, client, true, true);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_Players(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		new userid, target;
		
		GetMenuItem(menu, param2, info, sizeof(info));
		userid = StringToInt(info);

		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "[SM] %s", "Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[SM] %s", "Unable to target");
		}
		else
		{					
			PerformGodClip(param1, target);
		}
		
		/* Re-draw the menu if they're still valid */
		if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
		{
			DisplayPlayerMenu(param1);
		}
	}
}

stock e_SupportedMods:GetGame()
{
	decl String:szGameDesc[64];
	GetGameDescription(szGameDesc, sizeof(szGameDesc), true);
	
	if (StrContains(szGameDesc, "Counter-Strike", false) != -1)
	{
		return Game_CSS;
	}
	if (StrContains(szGameDesc, "Day of Defeat", false) != -1)
	{
		return Game_DODS;
	}
	if (StrContains(szGameDesc, "Half-Life 2 Deathmatch", false) != -1)
	{
		return Game_HL2MP;
	}
	if (StrContains(szGameDesc, "Team Fortress", false) != -1)
	{
		return Game_TF;
	}
	if (StrContains(szGameDesc, "L4D", false) != -1 || StrContains(szGameDesc, "Left 4 D", false) != -1)
	{
		return Game_L4D;
	}
	if (StrContains(szGameDesc, "Insurgency", false) != -1)
	{
		return Game_INSMOD;
	}
	if (StrContains(szGameDesc, "Fortress Forever", false) != -1)
	{
		return Game_FF;
	}
	if (StrContains(szGameDesc, "ZPS", false) != -1)
	{
		return Game_ZPS;
	}
	if (StrContains(szGameDesc, "Age of Chivalry", false) != -1)
	{
		return Game_AOC;
	}
	
	// game mod could not detected, try further
	decl String: szGameDir[64];
	GetGameFolderName(szGameDir, sizeof(szGameDir));
	if (StrContains(szGameDir, "cstrike", false) != -1)
	{
		return Game_CSS;
	}
	if (strncmp(szGameDir, "dod", 3, false) == 0)
	{
		return Game_DODS;
	}
	if (StrContains(szGameDir, "hl2mp", false) != -1 || StrContains(szGameDir, "hl2ctf", false) != -1)
	{
		return Game_HL2MP;
	}
	if (StrContains(szGameDir, "fistful_of_frags", false) != -1)
	{
		return Game_FOF;
	}
	if (strncmp(szGameDir, "tf", 2, false) == 0)
	{
		return Game_TF;
	}
	if (StrContains(szGameDir, "left4dead", false) != -1)
	{
		return Game_L4D;
	}
	if (StrContains(szGameDir, "insurgency", false) != -1)
	{
		return Game_INSMOD;
	}
	if (StrContains(szGameDir, "FortressForever", false) != -1)
	{
		return Game_FF;
	}
	if (StrContains(szGameDir, "zps", false) != -1)
	{
		return Game_ZPS;
	}
	if (StrContains(szGameDir, "ageofchivalry", false) != -1)
	{
		return Game_AOC;
	}
	if (StrContains(szGameDir, "gesource", false) != -1)
	{
		return Game_GES;
	}
	
	return Game_Unknown;
}

public Cvars_Changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == g_Cvar_GodMode)
	{
		godclipmode = StringToInt(newValue);
	}
	else if(convar == g_Cvar_Invismode)
	{
		invismode = StringToInt(newValue);
	}
	else if(convar == g_Cvar_Noclipmode)
	{
		noclipmode = StringToInt(newValue);
	}
	else if(convar == g_Cvar_DisplayMode)
	{
		displaymode = StringToInt(newValue);
	}
}
