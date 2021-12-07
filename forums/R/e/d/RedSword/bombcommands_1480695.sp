/**
	Credits : 
	dalto - botdropbomb plugin for drop bomb code
	http://forums.alliedmods.net/showthread.php?p=523188
	
	AltPluzF4 - for sig-scanning thread which helped me correct the sdk-call crash problem in botdropbomb plugin
	http://forums.alliedmods.net/archive/index.php/t-78309.html
	
	AtomicStryker - for having in the past the same problem as me and posting in forums :
	http://forums.alliedmods.net/showthread.php?t=121145
	
	Dr!fter - for his 2nd sig-function that help me get this to work with CSS:DM
	http://forums.alliedmods.net/showthread.php?t=153765
	https://bugs.alliedmods.net/show_bug.cgi?id=4732 (his bug report)
	and his Weapon Restriction plugin (drop is bombed further with 4th argument to TRUE)
	
	People of the following thread : for the code to browse entities (I know its commonly used ><)
	http://forums.alliedmods.net/showthread.php?t=143431
	
	People of the following thread : for the code to spectate someone specific
	https://forums.alliedmods.net/showthread.php?t=179757
*/
#pragma semicolon 1

#include <adminmenu>
#include <sdktools>
#include <cstrike>

#define PLUGIN_VERSION "2.1.0"

public Plugin:myinfo =
{
	name = "Bomb Commands",
	author = "RedSword / Bob Le Ponge",
	description = "Allow various bomb related commands.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

//Cvars
new Handle:g_bombCommands;
new Handle:g_bombCommands_verbose;
new Handle:g_bombCommands_log;

//For "spawnwithbomb" option
new g_iSpawnWithBombClient;

//Last bomber
new g_iLastBomber;
new String:g_szLastBomberName[MAX_NAME_LENGTH];
new String:g_szLastBomberSteamID[MAX_NAME_LENGTH];
//^values
#define ID_PLAYER_LEFT_GAME -1

//Menu
#define ADMINMENU_BOMBCOMMANDS		"BombCommandsCat"
#define ADMINMENU_BOMBCOMMANDS_STR	"Bomb Commands"
new Handle:hTopMenu = INVALID_HANDLE;
new TopMenuObject:obj_bombcmds = INVALID_TOPMENUOBJECT;

public OnPluginStart()
{
	//CVARs
	CreateConVar("bombcommandsversion", PLUGIN_VERSION, "Bomb Commands version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_bombCommands = CreateConVar("bombcommands", "1", "Is the plugin enabled ? 0=No, 1=Yes. Def. 1", 
		FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bombCommands_verbose = CreateConVar("bombcommands_verbose", "1", "Use new verbose system (show action to everyone) ? 0=No, 1=Yes. Def. 1.", 
		FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bombCommands_log = CreateConVar("bombcommands_log", "1", "Should the plugin log ? 0=No, 1=Yes. Def. 1.", 
		FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	//Commands
	RegAdminCmd("sm_dropbomb", Command_DropBomb, ADMFLAG_BAN, "sm_dropbomb");
	RegAdminCmd("sm_getbomb", Command_GetBomb, ADMFLAG_BAN, "sm_getbomb");
	RegAdminCmd("sm_givebomb", Command_GiveBomb, ADMFLAG_BAN, "sm_givebomb <#userid|name|[aimedTarget]>");
	RegAdminCmd("sm_lastbomber", Command_LastBomber, ADMFLAG_BAN, "sm_lastbomber");
	RegAdminCmd("sm_spawnwithbomb", Command_SpawnWithBomb, ADMFLAG_BAN, "sm_spawnwithbomb <#userid|name|[aimedTarget]>");
	RegAdminCmd("sm_stuckbomb", Command_StuckBomb, ADMFLAG_BAN, "sm_stuckbomb");
	RegAdminCmd("sm_spectatebomb", Command_SpectateBomb, ADMFLAG_BAN, "sm_spectatebomb");
	
	//Translation file
	LoadTranslations("common.phrases");
	LoadTranslations("adminmenu.phrases");
	LoadTranslations("bombcommands.phrases");
	
	//Hooks
	HookEvent("round_start", Round_Start);
	HookEvent("item_pickup", Item_Pickup);
	
	//Menu
	/* Account for late loading */
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuCreated(topmenu);
		OnAdminMenuReady(topmenu);
	}
}

/**
*	In order :
*	0- OnPluginStart()
*	1- Menu related
*	2- AdminMenu commands
*	3- Admin commands/actions
*	4- Hooks
*	5- Timers
*	6- Forwards
*	7- Privates
*/

//===== Menu
/**
*	Based on
*	- dynamicmenu.sp
*	- playercommands.sp
*	- slay.sp
*	- adminmenu.sp
*/

//OnMenuCreated --> Add categories
public OnAdminMenuCreated(Handle:topmenu)
{
	new String:szBuffer[32] = ADMINMENU_BOMBCOMMANDS;
	
	//Create category if it doesn't exist
	if ((obj_bombcmds = FindTopMenuCategory(topmenu, szBuffer)) == INVALID_TOPMENUOBJECT)
	{
		obj_bombcmds = AddToTopMenu(topmenu,
						szBuffer,
						TopMenuObject_Category,
						BombCommandsCategoryHandler,
						INVALID_TOPMENUOBJECT,
						"BombCommandsOverride",
						ADMFLAG_BAN,
						ADMINMENU_BOMBCOMMANDS_STR);

	}
}

//Seems required (http://wiki.alliedmods.net/Admin_Menu_(SourceMod_Scripting))
public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
	{
		hTopMenu = INVALID_HANDLE;
	}
}

//OnMenuReady --> Add sub-categories
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
	new TopMenuObject:bomb_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_BOMBCOMMANDS);

	if (bomb_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hTopMenu,
			"sm_dropbomb",
			TopMenuObject_Item,
			AdminMenu_DropBomb,
			bomb_commands,
			"sm_dropbomb",
			ADMFLAG_BAN);
			
		AddToTopMenu(hTopMenu,
			"sm_getbomb",
			TopMenuObject_Item,
			AdminMenu_GetBomb,
			bomb_commands,
			"sm_getbomb",
			ADMFLAG_BAN);
			
		AddToTopMenu(hTopMenu,
			"sm_givebomb",
			TopMenuObject_Item,
			AdminMenu_GiveBomb,
			bomb_commands,
			"sm_givebomb",
			ADMFLAG_BAN);
			
		AddToTopMenu(hTopMenu,
			"sm_lastbomber",
			TopMenuObject_Item,
			AdminMenu_LastBomber,
			bomb_commands,
			"sm_lastbomber",
			ADMFLAG_BAN);
			
		AddToTopMenu(hTopMenu,
			"sm_spawnwithbomb",
			TopMenuObject_Item,
			AdminMenu_SpawnWithBomb,
			bomb_commands,
			"sm_spawnwithbomb",
			ADMFLAG_BAN);
			
		AddToTopMenu(hTopMenu,
			"sm_stuckbomb",
			TopMenuObject_Item,
			AdminMenu_StuckBomb,
			bomb_commands,
			"sm_stuckbomb",
			ADMFLAG_BAN);
			
		AddToTopMenu(hTopMenu,
			"sm_spectatebomb",
			TopMenuObject_Item,
			AdminMenu_SpectateBomb,
			bomb_commands,
			"sm_spectatebomb",
			ADMFLAG_BAN);
	}
}

public BombCommandsCategoryHandler(Handle:topmenu, 
						TopMenuAction:action,
						TopMenuObject:object_id,
						param,
						String:buffer[],
						maxlength)
{
	if (action == TopMenuAction_DisplayTitle)
	{
		if (object_id == INVALID_TOPMENUOBJECT)
		{
			FormatEx(buffer, maxlength, "%T:", "Admin Menu", param);
		}
		else if (object_id == obj_bombcmds)
		{
			FormatEx(buffer, maxlength, ADMINMENU_BOMBCOMMANDS_STR);
		}
	}
	else if (action == TopMenuAction_DisplayOption)
	{
		if (object_id == obj_bombcmds)
		{
			FormatEx(buffer, maxlength, ADMINMENU_BOMBCOMMANDS_STR);
		}
	}
}

//Add all terrorists - private
//Flags :
#define	REMOVE_BOMBER	(1<<0)
#define	REMOVE_DEADS	(1<<1)
addTerroristsToMenu(Handle:menu, flags) //based on "stock UTIL_AddTargetsToMenu2" from adminmenu.sp
{
	decl String:user_id[12];
	decl String:name[MAX_NAME_LENGTH];
	decl String:display[MAX_NAME_LENGTH+12];
	
	for (new i = 1; i <= MaxClients; ++i)
	{
		//Normal checks
		if (!IsClientInGame(i)			|| 
				IsClientInKickQueue(i)	||
				GetClientTeam(i) != 2)
			continue;
		
		//Flag checks
		if (flags & REMOVE_BOMBER && IsPlayerAlive(i) && GetPlayerWeaponSlot(i, 4) != -1)
			continue;
		
		if (flags & REMOVE_DEADS && !IsPlayerAlive(i))
			continue;
		
		IntToString(GetClientUserId(i), user_id, sizeof(user_id));
		GetClientName(i, name, sizeof(name));
		FormatEx(display, sizeof(display), "%s (%s)", name, user_id);
		AddMenuItem(menu, user_id, display);
	}
}

//==== AdminMenu CMD
//DropBomb
public AdminMenu_DropBomb(Handle:topmenu, 
					  TopMenuAction:action,
					  TopMenuObject:object_id,
					  param,
					  String:buffer[],
					  maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		FormatEx(buffer, maxlength, "%T", "20 AdminMenu DropBomb", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		Command_DropBomb(param, 0);
	}
}
//GetBomb
public AdminMenu_GetBomb(Handle:topmenu, 
					  TopMenuAction:action,
					  TopMenuObject:object_id,
					  param,
					  String:buffer[],
					  maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		FormatEx(buffer, maxlength, "%T", "20 AdminMenu GetBomb", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		Command_GetBomb(param, 0);
	}
}
//GiveBomb
public AdminMenu_GiveBomb(Handle:topmenu, 
					  TopMenuAction:action,
					  TopMenuObject:object_id,
					  param,
					  String:buffer[],
					  maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		FormatEx(buffer, maxlength, "%T", "20 AdminMenu GiveBomb", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		new Handle:menu = CreateMenu(MenuHandler_GiveBomb);
		
		decl String:title[100];
		FormatEx(title, sizeof(title), "%T:", "20 AdminMenu GiveBomb", param);
		SetMenuTitle(menu, title);
		SetMenuExitBackButton(menu, true);
		
		addTerroristsToMenu(menu, REMOVE_BOMBER	| REMOVE_DEADS);
		
		DisplayMenu(menu, param, MENU_TIME_FOREVER);
	}
}
public MenuHandler_GiveBomb(Handle:menu, MenuAction:action, param1, param2)
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
		decl String:info[32];
		decl String:cmd[64];
		
		GetMenuItem(menu, param2, info, sizeof(info)); //info has userId
		
		new iClient = GetClientOfUserId(StringToInt(info));
		
		if (iClient == 0)
			PrintToChat(param1, "[SM] %t", "Player no longer available");
		else if (!IsPlayerAlive(iClient))
			ReplyToCommand(param1, "[SM] %t", "Player has since died");
		else
		{
			FormatEx(cmd, sizeof(cmd), "sm_givebomb #%s", info);
			FakeClientCommand(param1, cmd); //Can't reuse Command_GiveBomb since we need to put arguments... to lets use this :D
		}
	}
}
//LastBomber
public AdminMenu_LastBomber(Handle:topmenu, 
					  TopMenuAction:action,
					  TopMenuObject:object_id,
					  param,
					  String:buffer[],
					  maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		FormatEx(buffer, maxlength, "%T", "20 AdminMenu LastBomber", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		Command_LastBomber(param, 0);
	}
}
//SpawnWithBomb
public AdminMenu_SpawnWithBomb(Handle:topmenu, 
					  TopMenuAction:action,
					  TopMenuObject:object_id,
					  param,
					  String:buffer[],
					  maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		FormatEx(buffer, maxlength, "%T", "20 AdminMenu SpawnWithBomb", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		new Handle:menu = CreateMenu(MenuHandler_SpawnWithBomb);
		
		decl String:title[100];
		FormatEx(title, sizeof(title), "%T:", "20 AdminMenu SpawnWithBomb", param);
		SetMenuTitle(menu, title);
		SetMenuExitBackButton(menu, true);
		
		addTerroristsToMenu(menu, 0);
		
		DisplayMenu(menu, param, MENU_TIME_FOREVER);
	}
}
public MenuHandler_SpawnWithBomb(Handle:menu, MenuAction:action, param1, param2)
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
		decl String:info[32];
		decl String:cmd[64];
		
		GetMenuItem(menu, param2, info, sizeof(info)); //info has userId
		
		if (GetClientOfUserId(StringToInt(info)) == 0)
			PrintToChat(param1, "[SM] %t", "Player no longer available");
		else
		{
			FormatEx(cmd, sizeof(cmd), "sm_spawnwithbomb #%s", info);		
			FakeClientCommand(param1, cmd); //Can't reuse Command_GiveBomb since we need to put arguments... to lets use this :D
		}
	}
}
//StuckBomb
public AdminMenu_StuckBomb(Handle:topmenu, 
					  TopMenuAction:action,
					  TopMenuObject:object_id,
					  param,
					  String:buffer[],
					  maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		FormatEx(buffer, maxlength, "%T", "20 AdminMenu StuckBomb", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		Command_StuckBomb(param, 0);
	}
}
//SpectateBomb
public AdminMenu_SpectateBomb(Handle:topmenu, 
					  TopMenuAction:action,
					  TopMenuObject:object_id,
					  param,
					  String:buffer[],
					  maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		FormatEx(buffer, maxlength, "%T", "21 AdminMenu SpectateBomb", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		Command_SpectateBomb(param, 0);
	}
}

/**
*	ALL THE ABOVE IS SINCE 2.0
*	ALL BELOW IS BEFORE 2.0 (unless sm_lastbomber and possible corrections)
*/

//===== AdminAction CMD

public Action:Command_DropBomb(client, args)
{
	if (GetConVarInt(g_bombCommands) == 1 && !isBombPlanted())
	{
		//Prevent people from outside to run the command
		if (client == 0)
		{
			ReplyToCommand(client, "[SM] %t", "Command is in-game only");
			return Plugin_Handled;
		}
		
		new bomberId = getBomberId();
		if (bomberId != 0)
		{
			CS_DropWeapon(bomberId, GetPlayerWeaponSlot(bomberId, 4), true, true);
			
			if (GetConVarInt(g_bombCommands_verbose))
				ShowActivity2(client, "\x04[SM] \x03", "\x01%t", "15 Admin dropbomb", "\x04", bomberId, "\x01");
			else
				PrintToChat(bomberId, "\x04[SM] \x01%t", "Admin dropbomb", "\x04", client, "\x01");
			
			if (GetConVarInt(g_bombCommands_log))
				LogAction(client, bomberId, "\"%L\" made player \"%L\" drop bomb.", client, bomberId);
		}
		
		ReplyToCommand(client, "\x04[SM] \x01%t", "Bomb is dropped");
	}
	
	return Plugin_Handled;
}

public Action:Command_GetBomb(client, args)
{
	if (GetConVarInt(g_bombCommands) == 1 && !isBombPlanted() && GetClientTeam(client) == 2 &&
			IsPlayerAlive(client))
	{
		//Prevent people from outside to run the command
		if (client == 0)
		{
			ReplyToCommand(client, "[SM] %t", "Command is in-game only");
			return Plugin_Handled;
		}
		
		//Remove bomb
		new previousBomberId = removeBomb();
		
		//Give bomb
		GivePlayerItem(client, "weapon_c4");
			
		if (GetConVarInt(g_bombCommands_verbose))
		{
			if (previousBomberId)
				ShowActivity2(client, "\x04[SM] \x03", "\x01%t", "15 Admin steal player", "\x04", previousBomberId, "\x01");
			else
				ShowActivity2(client, "\x04[SM] \x03", "\x01%t", "15 Admin steal world");
		}
		else
		{
			PrintToChat(previousBomberId, "\x04[SM] \x01%t", "Admin steal", "\x04", client, "\x01");
			ReplyToCommand(client, "\x04[SM] \x01%t", "You receive the bomb");
		}
		
		if (GetConVarInt(g_bombCommands_log))
			LogAction(client, client, "\"%L\" got the bomb using this plugin : sm_getbomb.", client);
	}
	
	return Plugin_Handled;
}

public Action:Command_GiveBomb(client, args)
{
	if (GetConVarInt(g_bombCommands) == 1 && !isBombPlanted())
	{
		//Prevent people from outside to run the command
		if (client == 0)
		{
			ReplyToCommand(client, "[SM] %t", "Command is in-game only");
			return Plugin_Handled;
		}
		
		new String:targetArg[ MAX_NAME_LENGTH ];
		new targetId;
		
		if (args < 1) //If no arg; check target aimed at
		{
			targetId = GetClientAimTarget(client);
		}
		else if (args < 2)
		{
			GetCmdArg(1, targetArg, sizeof(targetArg));
			targetId = FindTarget(client, targetArg);
		}
		
		if (targetId < 1)
		{
			ReplyToCommand(client, "\x04[SM] \x01Usage: <sm_givebomb|say !givebomb> <#userid|name|[aimedTarget]>");
			return Plugin_Handled;
		}
		else if (GetClientTeam(targetId) == 2 && IsPlayerAlive(targetId))
		{
			//Remove bomb
			new previousBomberId = removeBomb();
			
			//Give bomb
			GivePlayerItem(targetId, "weapon_c4");
			
			if (GetConVarInt(g_bombCommands_verbose))
				ShowActivity2(client, "\x04[SM] \x03", "\x01%t", "15 Admin givebomb", "\x04", targetId, "\x01");
			else
			{
				PrintToChat(previousBomberId, "\x04[SM] \x01%t", "Admin steal to give", "\x04", client, "\x01", "\x04", targetId, "\x01");
				ReplyToCommand(client, "\x04[SM] \x01%t", "You give the bomb to player", "\x04", targetId, "\x01");
				PrintToChat(targetId, "\x04[SM] \x01%t", "Admin givebomb", "\x04", client, "\x01");
			}
			
			if (GetConVarInt(g_bombCommands_log))
				LogAction(client, targetId, "\"%L\" gave the bomb to \"%L\".", client, targetId);
		}
	}
	
	return Plugin_Handled;
}

public Action:Command_SpawnWithBomb(client, args)
{
	if (GetConVarInt(g_bombCommands) == 1)
	{
		//Prevent people from outside to run the command
		if (client == 0)
		{
			ReplyToCommand(client, "[SM] %t", "Command is in-game only");
			return Plugin_Handled;
		}
		
		new String:targetArg[ MAX_NAME_LENGTH ];
		new targetId;
		
		if (args < 1) //If no arg; check target aimed at
		{
			targetId = GetClientAimTarget(client);
		}
		else if (args < 2)
		{
			GetCmdArg(1, targetArg, sizeof(targetArg));
			targetId = FindTarget(client, targetArg);
		}
		
		if (targetId < 1)
		{
			ReplyToCommand(client, "\x04[SM] \x01Usage: <sm_spawnwithbomb|say !spawnwithbomb> <#userid|name|[aimedTarget]>");
			return Plugin_Handled;
		}
		else if (GetClientTeam(targetId) == 2)
		{
			g_iSpawnWithBombClient = targetId;
			
			if (GetConVarInt(g_bombCommands_verbose))
				ShowActivity2(client, "\x04[SM] \x03", "\x01%t", "15 Admin spawnwithbomb", "\x04", targetId, "\x01");
			else
			{
				ReplyToCommand(client, "\x04[SM] \x01%t", "You make player spawn with bomb", "\x04", targetId, "\x01");
				PrintToChat(targetId, "\x04[SM] \x01%t", "Admin spawnwithbomb", "\x04", client, "\x01");
			}
			
			if (GetConVarInt(g_bombCommands_log))
				LogAction(client, targetId, "\"%L\" makes player \"%L\" spawn with bomb for the upcoming round.", client, targetId);
		}
	}
	
	return Plugin_Handled;
}

public Action:Command_StuckBomb(client, args)
{
	if (GetConVarInt(g_bombCommands) == 1 && !isBombPlanted() && getBomberId() == 0)
	{
		//Prevent people from outside to run the command
		if (client == 0)
		{
			ReplyToCommand(client, "[SM] %t", "Command is in-game only");
			return Plugin_Handled;
		}
		
		//Get bomb position to compare it to the terrorists' positions
		decl Float:originVec[3];
		for (new iEntIndex = ( MaxClients + 1 ); iEntIndex < GetMaxEntities(); iEntIndex++)
		{
			if (IsValidEntity( iEntIndex ))  
			{  
				decl String:sClassName[128];  
				GetEdictClassname(iEntIndex, sClassName, sizeof(sClassName));
				
				if (StrEqual(sClassName, "weapon_c4", false))
				{
					GetEntPropVector(iEntIndex, Prop_Send, "m_vecOrigin", originVec);
					break;
				}
			}
		}
		
		new futureBomberId = getClosestT(originVec);
		if (futureBomberId > 0) //Could be not spawned
		{
			//Remove bomb
			removeBombFromWorld(); //We make sure to remove it
			
			//End of the "reply to cmd"
			decl String:szBuffer[128];
			FormatEx(szBuffer, sizeof(szBuffer), "\x01%T", "You give the bomb to player", LANG_SERVER, "\x04", futureBomberId, "\x01");
			
			if (g_iLastBomber == ID_PLAYER_LEFT_GAME)
				ReplyToCommand(client, "\x04[SM] \x01%t \x01%t \x01%s", 
					"Last bomber left", "\x04", g_szLastBomberName, "\x01", 
					"SteamID", "\x04", g_szLastBomberSteamID, "\x01",
					szBuffer);
			else
				ReplyToCommand(client, "\x04[SM] \x01%t %s", "Last bomber is", "\x04", g_iLastBomber, "\x01", szBuffer);
			
			//Give bomb
			GivePlayerItem(futureBomberId, "weapon_c4");
			
			if (GetConVarInt(g_bombCommands_verbose))
				ShowActivity2(client, "\x04[SM] \x03", "\x01%t", "15 Admin unstuckbomb", "\x04", futureBomberId, "\x01");
			else
				PrintToChat(futureBomberId, "\x04[SM] \x01%t", "Admin givebomb", "\x04", client, "\x01");
			
			if (GetConVarInt(g_bombCommands_log))
				LogAction(client, -1, "\"%L\" unstuck the bomb. \"%L\" happened to be the closest terrorist and got it.", client, futureBomberId);
		}
	}
	
	return Plugin_Handled;
}

public Action:Command_LastBomber(client, args)
{
	if (GetConVarInt(g_bombCommands) == 1 && getBomberId() == 0)
	{
		//Prevent people from outside to run the command
		if (client == 0)
		{
			ReplyToCommand(client, "[SM] %t", "Command is in-game only");
			return Plugin_Handled;
		}
		
		if (g_iLastBomber == ID_PLAYER_LEFT_GAME)
			ReplyToCommand(client, "\x04[SM] \x01%t \x01%t \x01", 
				"Last bomber left", "\x04", g_szLastBomberName, "\x01", 
				"SteamID", "\x04", g_szLastBomberSteamID, "\x01");
		else
			ReplyToCommand(client, "\x04[SM] \x01%t", "Last bomber is", "\x04", g_iLastBomber, "\x01");
	}
	
	return Plugin_Handled;
}

public Action:Command_SpectateBomb(client, args) //since 2.1
{
	if (GetConVarInt(g_bombCommands) == 1 && !isBombPlanted())
	{
		//Prevent people from outside to run the command
		if (client == 0)
		{
			ReplyToCommand(client, "[SM] %t", "Command is in-game only");
			return Plugin_Handled;
		}
		
		new bomberId = getBomberId();
		
		if (bomberId == 0)
		{
			ReplyToCommand(client, "[SM] %t", "No matching client");
		}
		else
		{
			SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", bomberId);
		}
	}
	
	return Plugin_Handled;
}

//===== Hooks 

public Round_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(g_bombCommands) == 1 && g_iSpawnWithBombClient != 0)
	{
		CreateTimer(0.1, GiveBombFromSpawn, g_iSpawnWithBombClient, TIMER_FLAG_NO_MAPCHANGE);
		
		g_iSpawnWithBombClient = 0;
	}
	
	return bool:Plugin_Continue;
}

public Item_Pickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(g_bombCommands) == 1)
	{
		decl String:szWpn[64];

		GetEventString(event, "item", szWpn, 64);
		
		if (StrEqual(szWpn, "c4"))
		{
			new bomberId = GetClientOfUserId(GetEventInt(event, "userid"));
			if (GetPlayerWeaponSlot(bomberId, 4) != -1)
				g_iLastBomber = bomberId;
		}
	}
	
	return bool:Plugin_Continue;
}

//===== Timers

public Action:GiveBombFromSpawn(Handle:timer, any:clientId)
{
	if (IsClientInGame(clientId) && 
			IsPlayerAlive(clientId) &&
			GetClientTeam(clientId) == 2)
	{
		removeBomb();
		
		GivePlayerItem(clientId, "weapon_c4");
	}
	
	return Plugin_Continue;
}

//===== Forwards

public OnClientDisconnect(clientId)
{
	if (clientId == g_iSpawnWithBombClient)
		g_iSpawnWithBombClient = 0;
	
	if (clientId == g_iLastBomber)
	{
		GetClientName(g_iLastBomber, g_szLastBomberName, sizeof(g_szLastBomberName));
		GetClientAuthString(g_iLastBomber, g_szLastBomberSteamID, sizeof(g_szLastBomberSteamID));
		g_iLastBomber = ID_PLAYER_LEFT_GAME;
	}
}

//===== Privates

bool:isBombPlanted()
{
	for (new iEntIndex = ( MaxClients + 1 ); iEntIndex < GetMaxEntities(); iEntIndex++)
	{
		if (IsValidEntity( iEntIndex ))  
		{  
			decl String:sClassName[128];  
			GetEdictClassname(iEntIndex, sClassName, sizeof(sClassName));  
			if (StrEqual(sClassName, "planted_c4", false))
			{
				return true;
			}
		}
	}
	
	return false;
}

//Remove the bomb from the game
any:removeBomb()
{
	new bomberId = getBomberId();
	
	if (bomberId != 0) //If bomber is a player
	{
		decl String:sClassName[128];  
		
		new iEntIndex = GetPlayerWeaponSlot(bomberId, 4);
		
		GetEdictClassname(iEntIndex, sClassName, sizeof(sClassName));  
		if ( StrEqual( sClassName, "weapon_c4", false ) )  
		{
			RemovePlayerItem(bomberId, iEntIndex); 
			AcceptEntityInput(iEntIndex, "kill");
		}
	}
	else //If it's the world
	{
		removeBombFromWorld();
	}
	
	return bomberId;
}

removeBombFromWorld()
{
	for (new iEntIndex = ( MaxClients + 1 ); iEntIndex < GetMaxEntities(); iEntIndex++)
	{
		if (IsValidEntity( iEntIndex ))  
		{  
			decl String:sClassName[128];  
			GetEdictClassname(iEntIndex, sClassName, sizeof(sClassName));  
			if (StrEqual(sClassName, "weapon_c4", false))
			{
				AcceptEntityInput(iEntIndex, "kill");
				break;
			}
		}
	}
}

//Return the bomberId
any:getBomberId()
{
	for (new idClient = MaxClients; idClient >= 1; --idClient)
	{
		if (IsClientInGame(idClient) && 
				IsPlayerAlive(idClient) &&
				GetPlayerWeaponSlot(idClient, 4) != -1) //if the player is carrying the bomb
		{
			return idClient; //We found the bomber, no need to continue in the loop
		}
	}
	return 0;
}

//Return the clientId of the closest terrorist to the bomb
any:getClosestT(Float:bombPos[3])
{
	new closestT = -1;
	new Float:distance = 999999999999999999.9;
	
	decl Float:playerPos[3];
	
	for (new i = MaxClients; i >= 1; --i)
	{
		if (IsClientConnected(i) &&
				IsClientInGame(i) && 
				IsPlayerAlive(i) &&
				GetClientTeam(i) == 2) //if terro
		{
			GetClientAbsOrigin(i, playerPos);
			
			new Float:tmpDistance = GetVectorDistance(bombPos, playerPos, true);
			if (tmpDistance < distance)
			{
				closestT = i;
				distance = tmpDistance;
			}
		}
	}
	
	return closestT;
}