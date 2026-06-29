#pragma semicolon 1

#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_VERSION "1.2.0"

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Strip Weapons from Player",
	author = "RedSword",
	description = "Remove weapons from a player.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

//Cache
int g_iDefaultStripSlots;
int g_iMaxStripEffectiveSlot;
char g_szDefaultSlots[ 32 ];//let's consider slot 10 as 0; allow some formatting if they want
TopMenu hTopMenu;// Admin Menu

//Convars
ConVar g_hIgnoreImmunity;
ConVar g_hLog;

// ========== FORWARDS ==========

public void OnPluginStart()
{
	CreateConVar( "stripweaponsfromplayerversion", PLUGIN_VERSION, "Strip Weapons from Player version.", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD );
	
	Handle hTmp = CreateConVar( "swfp_slot_max", "10", "Until which item slot (included) should the plugin end to remove weapons (sm_stripall and sm_stripbut only; 0=slot 10) 1-based. Def. 10.", FCVAR_PLUGIN, true, 0.0, true, 10.0 );
	
	HookConVarChange( hTmp, ConVarChange_MaxStripSlot );
	g_iMaxStripEffectiveSlot = GetConVarInt( hTmp ) - 1;
	if ( g_iMaxStripEffectiveSlot <= -1 )
		g_iMaxStripEffectiveSlot = 9;
	
	hTmp = CreateConVar( "swfp_slot_default", "1234", "Which slots should be stripped from their weapons by default ? (stick the slot digits together; sm_strip only; 0=slot 10; digits must all be below or equal swfp_slot_max)", FCVAR_PLUGIN );
	
	HookConVarChange( hTmp, ConVarChange_DefaultStripSlot );
	GetConVarString( hTmp, g_szDefaultSlots, sizeof(g_szDefaultSlots) );
	g_iDefaultStripSlots = getSlotFlagsFromString( g_szDefaultSlots );
	
	g_hIgnoreImmunity = CreateConVar( "swfp_ignore_immunity", "0.0", "Should immunity be ignored when striping ?, 0=No (Def.), 1=Yes.", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	
	g_hLog = CreateConVar( "swfp_log", "1.0", "Should the plugin log admin activity ? 1=Yes (Def.), 0=No.", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	
	//=== Admin commands
	
	RegAdminCmd( "sm_strip", AdminCommand_Strip, ADMFLAG_BAN, "<sm_strip|say !strip> <#userid|name|targets> <[slots]>; Remove weapons specified in 2nd arg, or in 'swfp_slot_default' if not present" );
	RegAdminCmd( "sm_stripall", AdminCommand_StripAll, ADMFLAG_BAN, "<sm_stripall|say !stripall> <#userid|name|targets> ; Remove all weapons with slot lower or equals swfp_slot_max" );
	RegAdminCmd( "sm_stripbut", AdminCommand_StripBut, ADMFLAG_BAN, "<sm_stripbut|say !stripbut> <#userid|name|targets> <slot> ; slot is 1-based ; Remove all weapons with slot lower or equals swfp_slot_max from target except those in 2nd-argument slot" );
	
	//=== Phrases
	
	LoadTranslations("stripweaponsfromplayer.phrases");
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases"); //"_s"
}

#pragma newdecls optional
//pretty much copied from funcommands.sp
public OnAdminMenuReady(Handle aTopMenu)
{
	TopMenu topmenu = TopMenu.FromHandle(aTopMenu);

	/* Block us from being called twice */
	if (topmenu == hTopMenu)
	{
		return;
	}
	
	/* Save the Handle */
	hTopMenu = topmenu;
	
	/* Find the "Player Commands" category */
	TopMenuObject player_commands = hTopMenu.FindCategory(ADMINMENU_PLAYERCOMMANDS);

	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		hTopMenu.AddItem("sm_strip", AdminMenu_Strip, player_commands, "sm_strip", ADMFLAG_BAN);
		hTopMenu.AddItem("sm_stripall", AdminMenu_StripAll, player_commands, "sm_stripall", ADMFLAG_BAN);
	}
}
#pragma newdecls required

// ========== END FORWARDS ==========

// ========== Cmd callbacks ==========

public Action AdminCommand_StripBut(int client, int args)
{
	if ( client == 0 )
	{
		ReplyToCommand( client, "Command is in-game only" );
		return Plugin_Handled;
	}
	
	char target_name[ MAX_TARGET_LENGTH ];
	int target_list[ MAXPLAYERS ];
	int target_count;
	bool tn_is_ml;
	
	int stripFlags;
	char szSecondArg[ 13 ];
	
	if (args < 3)
	{
		char targetArg[ 65 ];
		GetCmdArg(1, targetArg, sizeof(targetArg));
		
		if ((target_count = ProcessTargetString(
				targetArg,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_ALIVE | (g_hIgnoreImmunity.BoolValue ? COMMAND_FILTER_NO_IMMUNITY : 0),
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		
		GetCmdArg( 2, szSecondArg, sizeof(szSecondArg) );
		StripQuotes( szSecondArg );
		stripFlags = getSlotFlagsFromString( szSecondArg );
		if ( stripFlags <= 0 )
			target_count = 0;
	}
	
	if ( target_count < 1 )
	{
		ReplyToCommand(client, "\x04[SM] \x01Usage: <sm_stripbut|say !stripbut> <#userid|name|targets> <slot>");
		return Plugin_Handled;
	}
	
	stripPlayers( target_list, target_count, stripFlags, true );
	
	if ( tn_is_ml )
		ShowActivity2( client, "\x04[SM] \x03", "\x01%t", "AdminCmd Strip But", "\x04", target_name, "\x01", "\x04", szSecondArg, "\x01" );
	else
		ShowActivity2( client, "\x04[SM] \x03", "\x01%t", "AdminCmd Strip But", "\x04", "_s", target_name, "\x01", "\x04", szSecondArg, "\x01" );
	
	if ( g_hLog.BoolValue )
		LogAction( client, target_count == 1 ? target_list[ 0 ] : -1, 
			"\"%L\" stripped \"%s\" (%d affected clients).", client, target_name, target_count );
	
	return Plugin_Handled;
}
public Action AdminCommand_Strip(int client, int args)
{
	if ( client == 0 )
	{
		ReplyToCommand( client, "Command is in-game only" );
		return Plugin_Handled;
	}
	
	char target_name[ MAX_TARGET_LENGTH ];
	int target_list[ MAXPLAYERS ];
	int target_count;
	bool tn_is_ml;
	
	if (args < 3)
	{
		char targetArg[ 65 ];
		GetCmdArg(1, targetArg, sizeof(targetArg));
		
		if ((target_count = ProcessTargetString(
				targetArg,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_ALIVE | (g_hIgnoreImmunity.BoolValue ? COMMAND_FILTER_NO_IMMUNITY : 0),
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
	}
	
	if ( target_count < 1 )
	{
		ReplyToCommand( client, "\x04[SM] \x01Usage: <sm_strip|say !strip> <#userid|name|targets> <slots_optional>" );
		return Plugin_Handled;
	}
	
	int stripFlags = g_iDefaultStripSlots;
	int tmpFlags;
	char szArg2Buffer[ 13 ];
	if ( args < 3 )
	{
		GetCmdArg( 2, szArg2Buffer, sizeof(szArg2Buffer) );
		StripQuotes( szArg2Buffer );
		tmpFlags = getSlotFlagsFromString( szArg2Buffer );
		if ( tmpFlags > 0 )
			stripFlags = tmpFlags;
	}
	
	stripPlayers( target_list, target_count, stripFlags, false );
	
	if ( tn_is_ml )
		ShowActivity2( client, "\x04[SM] \x03", "\x01%t", "AdminCmd Strip", 
			"\x04", target_name, "\x01", "\x04", tmpFlags > 0 ? szArg2Buffer : g_szDefaultSlots, "\x01" );
	else
		ShowActivity2( client, "\x04[SM] \x03", "\x01%t", "AdminCmd Strip", 
			"\x04", "_s", target_name, "\x01", "\x04", tmpFlags > 0 ? szArg2Buffer : g_szDefaultSlots, "\x01" );
	
	if ( g_hLog.BoolValue )
		LogAction( client, target_count == 1 ? target_list[ 0 ] : -1, 
			"\"%L\" stripped \"%s\" (%d affected clients).", client, target_name, target_count );
	
	return Plugin_Handled;
}
public Action AdminCommand_StripAll(int client, int args)
{
	if ( client == 0 )
	{
		ReplyToCommand( client, "Command is in-game only" );
		return Plugin_Handled;
	}
	
	char target_name[ MAX_TARGET_LENGTH ];
	int target_list[ MAXPLAYERS ];
	int target_count;
	bool tn_is_ml;
	
	if (args < 2)
	{
		char targetArg[ 65 ];
		GetCmdArg(1, targetArg, sizeof(targetArg));
		
		if ((target_count = ProcessTargetString(
				targetArg,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_ALIVE | (g_hIgnoreImmunity.BoolValue ? COMMAND_FILTER_NO_IMMUNITY : 0),
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
	}
	
	if (target_count < 1)
	{
		ReplyToCommand(client, "\x04[SM] \x01Usage: <sm_stripall|say !stripall> <#userid|name|targets>");
		return Plugin_Handled;
	}
	
	stripPlayers( target_list, target_count, 0, true );
	
	if ( tn_is_ml )
		ShowActivity2( client, "\x04[SM] \x03", "\x01%t", "AdminCmd Strip All", "\x04", target_name, "\x01" );
	else
		ShowActivity2( client, "\x04[SM] \x03", "\x01%t", "AdminCmd Strip All", "\x04", "_s", target_name, "\x01" );
	
	if ( g_hLog.BoolValue )
		LogAction( client, target_count == 1 ? target_list[ 0 ] : -1, 
			"\"%L\" completely stripped \"%s\" (%d affected clients).", client, target_name, target_count );
	
	return Plugin_Handled;
}

// ========== END Cmd callbacks ==========

// ========== Menus ==========

public void AdminMenu_Strip(Handle topmenu, 
					  TopMenuAction action,
					  TopMenuObject object_id,
					  int param,
					  char[] buffer,
					  int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "%T", "Strip player", param);
	else if (action == TopMenuAction_SelectOption)
		DisplayStripMenu(param, "Strip player", MenuHandler_Strip);
}
public void AdminMenu_StripAll(Handle topmenu, 
					  TopMenuAction action,
					  TopMenuObject object_id,
					  int param,
					  char[] buffer,
					  int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "%T", "Stripall player", param);
	else if (action == TopMenuAction_SelectOption)
		DisplayStripMenu(param, "Stripall player", MenuHandler_StripAll);
}
void DisplayStripMenu(int client, char[] translation, MenuHandler menuHandler)
{
	Menu menu = CreateMenu(menuHandler);
	
	char title[100];
	Format(title, sizeof(title), "%T:", translation, client);
	menu.SetTitle(title);
	menu.ExitBackButton = true;
	
	AddTargetsToMenu(menu, g_hIgnoreImmunity.BoolValue ? 0 : client, true, true);
	
	menu.Display(client, MENU_TIME_FOREVER);
}
public int MenuHandler_Strip(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu)
		{
			hTopMenu.Display(param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		char info[32];
		int userid, target;
		
		menu.GetItem(param2, info, sizeof(info));
		userid = StringToInt(info);

		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "[SM] %t", "Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[SM] %t", "Unable to target");
		}
		else
		{
			char name[ MAX_TARGET_LENGTH ];
			GetClientName( target, name, sizeof(name) );
			
			int derpContainer[ 1 ];
			derpContainer[ 0 ] = target;
			stripPlayers( derpContainer, 1, g_iDefaultStripSlots, false );
			
			ShowActivity2( param1, "\x04[SM] \x03", "\x01%t", "AdminCmd Strip", 
				"\x04", "_s", name, "\x01", "\x04", g_szDefaultSlots, "\x01" );
		}
		
		/* Re-draw the menu if they're still valid */
		if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
		{
			DisplayStripMenu(param1, "Strip player", MenuHandler_Strip);
		}
	}
}
public int MenuHandler_StripAll(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu)
		{
			hTopMenu.Display(param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		char info[ MAX_TARGET_LENGTH ];
		int userid, target;
		
		menu.GetItem(param2, info, sizeof(info));
		userid = StringToInt(info);

		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "[SM] %t", "Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[SM] %t", "Unable to target");
		}
		else
		{
			char name[32];
			GetClientName( target, name, sizeof(name) );
			
			int derpContainer[ 1 ];
			derpContainer[ 0 ] = target;
			stripPlayers( derpContainer, 1, 0, true );
			
			ShowActivity2( param1, "\x04[SM] \x03", "\x01%t", "AdminCmd Strip All", "\x04", "_s", name, "\x01" );
		}
		
		/* Re-draw the menu if they're still valid */
		if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
		{
			DisplayStripMenu(param1, "Stripall player", MenuHandler_StripAll);
		}
	}
}

// ========== END Menus ==========

// ========== ConVar Changes ==========

public void ConVarChange_MaxStripSlot(Handle cvar, const char[] oldVal, const char[] newVal)
{
	g_iMaxStripEffectiveSlot = GetConVarInt( cvar ) - 1;
	if ( g_iMaxStripEffectiveSlot <= -1 )
		g_iMaxStripEffectiveSlot = 9;
}
public void ConVarChange_DefaultStripSlot(Handle cvar, const char[] oldVal, const char[] newVal)
{
	GetConVarString( cvar, g_szDefaultSlots, sizeof(g_szDefaultSlots) );
	g_iDefaultStripSlots = getSlotFlagsFromString( g_szDefaultSlots );//don't use newVal as we only check the 10 first + easier strlen
}

// ========== Privates ==========

void stripPlayers( const int[] iTargets, const int iTargetCount, const int iSlotFlags, const bool bAreFlagsExcluded/*else = only*/ )
{
	//We know they are alive @ COMMAND_FILTER_ALIVE
	int iCurrentTarget;
	int wpnEnt;
	int wpnSlotIndex;
	
	if ( bAreFlagsExcluded == true )
	{
		for ( int i; i < iTargetCount; ++i )
		{
			iCurrentTarget = iTargets[ i ];
			for ( wpnSlotIndex = g_iMaxStripEffectiveSlot; wpnSlotIndex >= 0; --wpnSlotIndex )
			{
				//Is slot excluded ?
				if ( ( 1 << wpnSlotIndex ) & iSlotFlags )
					continue;
				
				while ( -1 != ( wpnEnt = GetPlayerWeaponSlot( iCurrentTarget, wpnSlotIndex ) ) && 
					IsValidEntity( wpnEnt ) )
				{
					if ( false == RemovePlayerItem( iCurrentTarget, wpnEnt ) )
						break; //can't remove item, GTFO : change slotIndex
					AcceptEntityInput( wpnEnt, "kill" );
				}
			}
		}
	}
	else //stripOnly flags
	{
		int bitIterator;
		int flags;
		for ( int i; i < iTargetCount; ++i )
		{
			iCurrentTarget = iTargets[ i ];
			//here wpnSlotIndexis a ~~bitIterator
			for ( wpnSlotIndex = 0, bitIterator = 1, flags = iSlotFlags; flags != 0; bitIterator = ( 1 << ++wpnSlotIndex ) )
			{
				//Is slot excluded ?
				if ( bitIterator & flags == 0 )
					continue;
				
				flags &= ~bitIterator; //removed current flag
				
				while ( -1 != ( wpnEnt = GetPlayerWeaponSlot( iCurrentTarget, wpnSlotIndex ) ) && 
					IsValidEntity( wpnEnt ) )
				{
					if ( false == RemovePlayerItem( iCurrentTarget, wpnEnt ) )
						break; //can't remove item, GTFO : change slotIndex
					AcceptEntityInput( wpnEnt, "kill" );
				}
			}
		}
	}
}
int getSlotFlagsFromString( const char[] str )
{
	int retFlags;
	
	for ( int i = strlen( str ) - 1; i >= 0; --i )
	{
		if ( '1' <= str[ i ] <= '9' )
			retFlags |= ( 1 << ( str[ i ] - '1' ) );
		else if ( '0' == str[ i ] )
			retFlags |= ( 1 << 10 );
	}
	
	return retFlags;
}