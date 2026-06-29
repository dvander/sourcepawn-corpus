#pragma semicolon 1

#define DEV_KICK_FORWARD_INTERFACE

#define PLUGIN_VERSION "1.5.0"

public Plugin:myinfo = 
{
	name = "Server Whitelist Advanced",
	author = "RedSword ; forked & rewrote from Stevo.TVR 'Server whitelist'",
	description = "Restricts server to SteamIDs, IPs and SteamGroups' members/officers listed in the whitelist",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

#undef REQUIRE_PLUGIN
#include <tidykick>
#define REQUIRE_PLUGIN

#undef REQUIRE_EXTENSIONS
#include <steamtools>
#include <steamworks>
#define REQUIRE_EXTENSIONS

#include <serverwhitelistadvanced>

// Format of the time; change if you wish
#define DATETIMEFORMAT "%x, %X"
// Max Number of Steam Groups. It is recommended to not put a big number, as each group is queried to Valve server (It is unknown what would happen if you spam from your server; I expect the server would then not receive the groups status, and therefore everyone would be free to enter; depending on your whitelist_steamgroup_retry value)
#define MAXIMUM_STEAMGROUPS 8

#define UNKNOWN_STEAMID "UNKNOWN_STEAMID"
#define UNKNOWN_IP "UNKNOWN_IP"

#define CAN_USE_STEAMTOOLS	(1 << 0)
#define CAN_USE_STEAMWORKS	(1 << 1)

//Really nice to know UserId range zzz
#define NO_USER_ID -1

//#define DEBUG_MODE

//Convar values
new bool:g_bWhitelist_enable;
new bool:g_bWhitelist_immunity;
new g_iWhitelist_useSteamGroup;
new bool:g_bWhitelist_useTidyKick;
new Float:g_bWhitelist_steamgroup_timeout;
new g_iWhitelist_steamgroup_nbRetry;
new g_iWhitelist_autovouch; //1.3.0
new Float:g_fWhitelist_autovouch_timeout; //1.3.0
new bool:g_bWhitelist_removeinstant;
new String:g_szWhitelist_fileName[ 64 ];
new String:g_szKickMessage[ 256 ];
new g_iLogKick;

//Vars
new Handle:g_hWhitelistSteamIdTrie = INVALID_HANDLE;
new Handle:g_hWhitelistIPTrie = INVALID_HANDLE;

new bool:g_bWhitelist_ClientIsVoucher[ MAXPLAYERS + 1 ]; //1.3.0
new g_iWhitelist_ClientIsVoucherCount;
new Float:g_fWhitelist_ClientIsVoucherTimeAtShouldKick[ MAXPLAYERS + 1 ]; //1.3.0
new g_iWhitelist_ClientBecameVoucherUserId[ MAXPLAYERS + 1 ]; //1.3.1 ; by g_iWhitelist_autovouch == 3

new g_iWhitelistSteamGroupId[ MAXIMUM_STEAMGROUPS ];
new g_iWhitelistSteamGroupIdCount;
new bool:g_bClientCheckedSteamGroupId[ MAXPLAYERS + 1 ][ MAXIMUM_STEAMGROUPS ];
new g_iRemainingGroupCheck[ MAXPLAYERS + 1 ]; //to do countdown
new Handle:g_hClientTimeoutTimers[ MAXPLAYERS + 1 ];
new bool:g_bWhitelist_ClientIsBeingGroupValidated[ MAXPLAYERS + 1 ]; //1.4.0; to avoid calling GetSteamAccountID too much

new Handle:g_hWhitelistRemoveTrie = INVALID_HANDLE;
new Handle:g_hBlacklistCache = INVALID_HANDLE; //to prevent massive reconnect from sending requests to valve
new Handle:g_hWhitelistCache = INVALID_HANDLE; //OnMapChange save users ; never cleared automatically (good thing ?; I guess most server reboot once a day ? :$)

new bool:g_bShouldUpdateFile;

//Forwards, native, 3rd party
new g_iCanUseSteamGroup;
new bool:g_bCanUseTidyKick;
#if defined DEV_KICK_FORWARD_INTERFACE
new Handle:g_hForwardOnClientKicked;
#endif

//===== Forwards =====

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("Steam_RequestGroupStatus");
	
	CreateNative( "IsClientWhitelistStatusPending", Native_IsClientWhitelistStatusPending );//str, ret@bool ; only happen with groups
	
	CreateNative( "IsSteamIdWhitelisted", Native_IsSteamIdWhitelisted );//str, bool, ret@bool
	CreateNative( "IsIPWhitelisted", Native_IsIPWhitelisted );//str, bool, ret@bool
	CreateNative( "IsSteamGroupWhitelisted", Native_IsSteamGroupWhitelisted );//int, bool, ret@bool
	
	CreateNative( "IsSteamIdWhitelistCached", Native_IsSteamIdWhitelistCached );//str, ret@bool
	CreateNative( "IsSteamIdBlacklistCached", Native_IsSteamIdBlacklistCached );//str, ret@bool
	
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar( "serverwhitelistadvancedversion", PLUGIN_VERSION, "Server Whitelist plugin version", 
		FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD );
	
	decl Handle:convar;
	
	convar = CreateConVar( "whitelist", "1", "Enable server whitelist", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	HookConVarChange( convar, ConVarChange_Enable );
	g_bWhitelist_enable = GetConVarBool( convar );
	
	convar = CreateConVar( "whitelist_immunity", "1", "Automatically grant admins access. Required for _autovouch = 2.", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	HookConVarChange( convar, ConVarChange_Immunity );
	g_bWhitelist_immunity = GetConVarBool( convar );
	
	convar = CreateConVar( "whitelist_filename", "whitelist.txt", 
		"File name to use for the whitelist, in the sourcemod/configs/whitelist/ folder. Can't use '/' or '\\'. With extension.", FCVAR_PLUGIN );
	HookConVarChange( convar, ConVarChange_FileName );
	GetConVarString( convar, g_szWhitelist_fileName, sizeof(g_szWhitelist_fileName) );
	
	convar = CreateConVar( "whitelist_kickmessage", "You are not in the server's whitelist", //since 1.1.0
		"Message to show to kicked clients.", FCVAR_PLUGIN );
	HookConVarChange( convar, ConVarChange_KickMessage );
	GetConVarString( convar, g_szKickMessage, sizeof(g_szKickMessage) );
	
	convar = CreateConVar( "whitelist_log", "1.0", //since 1.1.0
		"Log failed-attempts to join server. 0=No, 1=Yes (always), 2=Yes (not after first time)", FCVAR_PLUGIN );
	HookConVarChange( convar, ConVarChange_LogKick );
	g_iLogKick = GetConVarInt( convar ); //oops prior to 1.3.0 was GetConVarBool
	
	convar = CreateConVar( "whitelist_steamgroup", "2", //since 1.1.0
		"Also read SteamGroupIds from whitelist file ? 0=No. 1=Yes (SteamTools). 2=Yes (SteamWorks). Can fallback.", FCVAR_PLUGIN, true, 0.0, true, 2.0 );
	HookConVarChange( convar, ConVarChange_SteamGroup );
	g_iCanUseSteamGroup = 
		( GetFeatureStatus( FeatureType_Native, "Steam_RequestGroupStatus" ) == FeatureStatus_Available ? CAN_USE_STEAMTOOLS : 0 ) |
		( GetFeatureStatus( FeatureType_Native, "SteamWorks_GetUserGroupStatus" ) == FeatureStatus_Available ? CAN_USE_STEAMWORKS : 0 );
	g_iWhitelist_useSteamGroup = GetConVarInt( convar );
#if defined DEBUG_MODE
	PrintToServer( "\t OnPluginStart:: g_iCanUseSteamGroup = %d; g_iWhitelist_useSteamGroup = %d", g_iCanUseSteamGroup, g_iWhitelist_useSteamGroup );
#endif
	if ( g_iWhitelist_useSteamGroup > 0 )
	{
		if ( g_iCanUseSteamGroup == 0 )
		{
			LogMessage( "Both SteamTools and SteamWorks are not found : SteamGroups support is disabled." );
			SetConVarInt( convar, 0 );
		}
		else if ( g_iCanUseSteamGroup == CAN_USE_STEAMWORKS && //CAN_USE_STEAMTOOLS = false
			g_iWhitelist_useSteamGroup == 1 )
		{
			//Not "fallforwarding"
			LogMessage( "Trying to use SteamTools but only SteamWorks is present. Try 'whitelist_steamgroup 2'. SteamGroups support is disabled." );
			SetConVarInt( convar, 0 );
		}
		//possible fallbacks ; if we can't use SW but can use ST and if we want to use SW; we revert to ST
		//SW --> ST
		else if ( 
			( g_iCanUseSteamGroup & CAN_USE_STEAMWORKS == 0 ) && 
			( g_iCanUseSteamGroup & CAN_USE_STEAMTOOLS ) && 
			g_iWhitelist_useSteamGroup == 2 )
		{
			LogMessage( "Attempting to use SteamWorks but not found : Trying to revert to SteamTools." );
			SetConVarInt( convar, 1 );
		}
	}
	
	convar = CreateConVar( "whitelist_tidykick", "0", //since 1.1.0
		"Use whitelist_kickmessage through tidykick ? 0=No (Default; need TidyKick). 1=Yes.", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	HookConVarChange( convar, ConVarChange_TidyKick );
	g_bCanUseTidyKick = GetFeatureStatus( FeatureType_Native, "TidyKickClient" ) == FeatureStatus_Available;
	g_bWhitelist_useTidyKick = GetConVarBool( convar );
	if ( !g_bCanUseTidyKick && g_bWhitelist_useTidyKick )
	{
		LogMessage( "TidyKick not found, therefore kick via TidyKick support is disabled." );
		SetConVarBool( convar, false );
	}
	
	convar = CreateConVar( "whitelist_steamgroup_timeout", "0.34", //since 1.1.0
		"Time (in seconds) before re-requesting SteamGroups status from Valve's server (sometimes Valve doesn't answer).", FCVAR_PLUGIN, true, 0.01 );
	HookConVarChange( convar, ConVarChange_SteamGroup_Timeout );
	g_bWhitelist_steamgroup_timeout = GetConVarFloat( convar );
	
	convar = CreateConVar( "whitelist_steamgroup_retry", "-1", //since 1.1.0
		"Maximum number of retry to do before saying someone is blacklisted. 'whitelist_steamgroup_timeout' seconds between each retry. ; Put '-1' for unlimited retry. Doing so should make people not be kicked in case Valve never respond (i.e. they have technical problems).", FCVAR_PLUGIN, true, -1.0 );
	HookConVarChange( convar, ConVarChange_SteamGroup_NbRetry );
	g_iWhitelist_steamgroup_nbRetry = GetConVarInt( convar );
	
	convar = CreateConVar( "whitelist_autovouch", "0", //since 1.3.0
		"Allows people to join if they are not whitelisted under a certain condition. 0=Nop, 1=Someone is whitelisted, 2=An admin is present (_immunity needed), 3=Someone is present.", FCVAR_PLUGIN, true, 0.0, true, 3.0 );
	HookConVarChange( convar, ConVarChange_AutoVouch );
	g_iWhitelist_autovouch = GetConVarInt( convar );
	
	convar = CreateConVar( "whitelist_autovouch_mintimeout", "2.0", //since 1.3.0
		"Minimum time in seconds before a non-whitelisted first-time-in-map-user is kicked if no voucher (defined by _autovouch value) are present; to give time to voucher to join on mapchange. It is a minimum if Steam groups are used; if not it is a normal timeout(kick).", FCVAR_PLUGIN, true, 0.1 );
	HookConVarChange( convar, ConVarChange_AutoVouch_MinTimeout );
	g_fWhitelist_autovouch_timeout = GetConVarFloat( convar );
	
	convar = CreateConVar( "whitelist_removeinstant", "1", 
		"When removing someone from whitelist, update the .txt right away (expensive operation if big whitelist) ? 0= On map end. Def. 1=Yes.", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	HookConVarChange( convar, ConVarChange_RemoveInstant );
	g_bWhitelist_removeinstant = GetConVarBool( convar );
	
	
	AutoExecConfig(true, "serverwhitelistadvanced");
	
	
	//I did put ADMFLAG_CONVARS because reading / writing to a file massively could make the server lag
	RegAdminCmd("sm_whitelist_reload", CommandReload, ADMFLAG_CONVARS, "Reloads the whitelist file and invalidate the SteamGroups blacklist cache.");
	RegAdminCmd("sm_whitelist_rewrite", CommandRewrite, ADMFLAG_CONVARS, 
		"Rewrites the whitelist file to remove SteamId/IPs waiting for map end to be removed. No need if whitelist_removeinstant = 1.");
	RegAdminCmd("sm_whitelist_list", CommandList, ADMFLAG_CONVARS, "List all SteamIDs, IPs and SteamGroupIds in the whitelist file.");
	RegAdminCmd("sm_whitelist_exist", CommandExist, ADMFLAG_GENERIC, "Tell if the SteamID or IP is present in the currently loaded whitelist.");
	RegAdminCmd("sm_whitelist_add", CommandAdd, ADMFLAG_UNBAN, "Add a SteamID, IP or SteamGroupId to the whitelist file. If adding a SteamID, you should use double-quotes (\"\").");
	RegAdminCmd("sm_whitelist_remove", CommandRemove, ADMFLAG_UNBAN, 
		"Remove a SteamID, IP or SteamGroupId from the whitelist file. The change is made on map/plugin end (unless whitelist_removeinstant=1), but the loaded whitelist instance is updated instantly. If removing a SteamID, you should use double-quotes (\"\").");
	RegAdminCmd("sm_whitelist_resettodefault", CommandResetToDefault, ADMFLAG_UNBAN, "Delete the current whitelist and recreate the default one.");
	
	
	HookEvent("player_disconnect", Event_ClientDisconnect);
	
	
	for ( new i; i <= MAXPLAYERS; ++i )
		g_iWhitelist_ClientBecameVoucherUserId[ i ] = NO_USER_ID;
	
	
#if defined DEV_KICK_FORWARD_INTERFACE
	g_hForwardOnClientKicked = CreateGlobalForward("OnClientKickedPre_ServerWhitelistAdvanced", ET_Event, Param_Cell, Param_Cell, Param_String, Param_String);
#endif
	
	g_hWhitelistSteamIdTrie = CreateTrie();
	g_hWhitelistIPTrie = CreateTrie();
	g_hWhitelistRemoveTrie = CreateTrie();
	g_hBlacklistCache = CreateTrie();
	g_hWhitelistCache = CreateTrie();
	
	loadList();
}

public OnClientAuthorized(client, const String:szSteamId[])
{
#if defined DEBUG_MODE
	PrintToServer( "\t Begin OnClientAuthorized" );
#endif
	//1.3.0
	g_fWhitelist_ClientIsVoucherTimeAtShouldKick[ client ] = 0.0;
	
	g_iRemainingGroupCheck[ client ] = 0;
	
	g_bWhitelist_ClientIsBeingGroupValidated[ client ] = false; //1.4.0
	
	if ( g_hClientTimeoutTimers[ client ] != INVALID_HANDLE )
	{
		KillTimer( g_hClientTimeoutTimers[ client ] );
		g_hClientTimeoutTimers[ client ] = INVALID_HANDLE;
	}
	
	if ( !g_bWhitelist_enable )
		return;
	
	if ( IsFakeClient( client ) )
		return;
	
	if ( g_iWhitelist_autovouch == 3 )
	{
		//If same client (=UserId), reapply autovoucher
		if ( client == GetClientOfUserId( g_iWhitelist_ClientBecameVoucherUserId[ client ] ) )
		{
			g_bWhitelist_ClientIsVoucher[ client ] = true;
			g_iWhitelist_ClientIsVoucherCount++;
			return;
		}
	}
	
	decl useless;
	
	if ( GetTrieValue( g_hBlacklistCache, szSteamId, useless ) )
	{
#if defined DEBUG_MODE
		PrintToServer( "\t Kicking because blacklisted" );
#endif
		myKickClient( client, true );
		return;
	}
	
	//1.3.0 admin checks (STEAM + IP) done before whitelist cache
	if ( g_bWhitelist_immunity && FindAdminByIdentity("steam", szSteamId) != INVALID_ADMIN_ID )
	{
#if defined DEBUG_MODE
		PrintToServer( "\t Whitelisted %N ; admin (SteamID)", client );
#endif
		if ( g_iWhitelist_autovouch > 0 )
		{
			g_bWhitelist_ClientIsVoucher[ client ] = true;
			g_iWhitelist_ClientIsVoucherCount++;
		}
		return;
	}
	
	decl String:szIP[ 16 ];
	//szIP[ 0 ] = '\0';
	
	if ( !GetClientIP( client, szIP, sizeof(szIP) ) )
	{
		strcopy( szIP, sizeof(szIP), UNKNOWN_IP );
	}
	
	if ( g_bWhitelist_immunity && FindAdminByIdentity("ip", szIP) != INVALID_ADMIN_ID )
	{
#if defined DEBUG_MODE
		PrintToServer( "\t Whitelisted %N ; admin (IP)", client );
#endif
		if ( g_iWhitelist_autovouch > 0 )
		{
			g_bWhitelist_ClientIsVoucher[ client ] = true;
			g_iWhitelist_ClientIsVoucherCount++;
		}
		return;
	}
	
	if ( GetTrieValue( g_hWhitelistCache, szSteamId, useless ) )
	{
		if ( g_iWhitelist_autovouch == 1 || g_iWhitelist_autovouch == 3 )
		{
			g_bWhitelist_ClientIsVoucher[ client ] = true;
			g_iWhitelist_ClientIsVoucherCount++;
		}
		return;
	}
	
	new bool:shouldKick = !GetTrieValue( g_hWhitelistSteamIdTrie, szSteamId, useless );
	
	if( shouldKick )
	{
		shouldKick = !GetTrieValue( g_hWhitelistIPTrie, szIP, useless );
	}
	
	if ( shouldKick )
	{
		g_fWhitelist_ClientIsVoucherTimeAtShouldKick[ client ] = GetGameTime();
		
		if ( g_iWhitelist_useSteamGroup > 0 && g_iWhitelistSteamGroupIdCount != 0 ) //if there are SteamGroups to check, postpone possible kick
		{
			sendStatusRequests( client );
		}
		else
		{
#if defined DEBUG_MODE
			PrintToServer( "\t Kicking because not whitelisted SteamID or IP" );
#endif
			//1.3.0 We're possibly just after OnMapStart, so we need to delay the kick
			myKickClient( client );
		}
	}
	else //shouldKick == false --> should not kick --> whitelisted
	{
		if ( g_iWhitelist_autovouch == 1 || g_iWhitelist_autovouch == 3 )
		{
			g_bWhitelist_ClientIsVoucher[ client ] = true;
			g_iWhitelist_ClientIsVoucherCount++;
		}
	}
#if defined DEBUG_MODE
	PrintToServer( "\t End OnClientAuthorized" );
#endif
}
//Called when a player manually disconnect ; 1.4.0
public Event_ClientDisconnect(Handle:hEvent, const String:szEventName[], bool:bDontBroadcast) 
{
	new userId = GetEventInt( hEvent, "userid" );
	new client = GetClientOfUserId( userId );
	
	if ( client > 0 && IsFakeClient( client ) )
		return;
	
#if defined DEBUG_MODE
	PrintToServer( "\t Event_ClientDisconnect userId=%d, client=%d", userId, client );
#endif
	
	if ( client == 0 ) //on map change dc ; need to find previous Client Id
	{
		for ( int i = 1; i <= MaxClients; ++i )
		{
			if ( g_iWhitelist_ClientBecameVoucherUserId[ i ] == userId )
			{
				client = i;
				break;
			}
		}
	}
	
	//Clear last userId in a client slot when that client manually dc
	g_iWhitelist_ClientBecameVoucherUserId[ client ] = NO_USER_ID;
	
	g_bWhitelist_ClientIsBeingGroupValidated[ client ] = false; //1.4.0
}
public OnClientDisconnect( client ) //1.3.0
{
	if ( g_bWhitelist_ClientIsVoucher[ client ] == true )
	{
		g_bWhitelist_ClientIsVoucher[ client ] = false;
		g_iWhitelist_ClientIsVoucherCount--;
	}
	
	//1.4.1 ; also done here; I got an "invalid timer" OnClientAuth once in NMRIH; might be related to hibernation
	if ( g_hClientTimeoutTimers[ client ] != INVALID_HANDLE ) 
	{
		KillTimer( g_hClientTimeoutTimers[ client ] );
		g_hClientTimeoutTimers[ client ] = INVALID_HANDLE;
	}
}

public OnMapEnd()
{
	//No need to keep it big; avoid possible clash if someone was added to a steam group after being kicked
	ClearTrie( g_hBlacklistCache );
	
	if ( g_bShouldUpdateFile )
	{
		rewriteWhitelistFile();
	}
}
public OnPluginEnd()
{
	if ( g_bShouldUpdateFile )
	{
		rewriteWhitelistFile();
	}
}

public SteamWorks_OnClientGroupStatus(authid, groupAccountID, bool:groupMember, bool:groupOfficer)
{
#if defined DEBUG_MODE
	PrintToServer( "\t SW_OnClientGroupStatus authid=%d is member or officer of group %d = %d", authid, groupAccountID, groupMember );
#endif
	new clientId = -1;
	for ( new i = 1; i <= MaxClients; ++i )
	{
		if ( g_bWhitelist_ClientIsBeingGroupValidated[ i ] == true )
		{
			if ( authid == GetSteamAccountID ( i ) )
			{
				clientId = i;
				break;
			}
		}
	}
	
	Steam_GroupStatusResult( clientId, groupAccountID, groupMember, groupOfficer );
}
//SteamTools (swallowing SteamWorks_OnClientGroupStatus if both ST & SW are opened)
public Steam_GroupStatusResult(client, groupAccountID, bool:groupMember, bool:groupOfficer)
{
#if defined DEBUG_MODE
	PrintToServer( "\t SteamGroups_GroupStatusResult client=%d is member or officer of group %d = %d", client, groupAccountID, groupMember );
#endif
	//Why Asher, Whyyyyyyyyyyyy
	if ( client == USE_CUSTOM_STEAMID/*-1*/ )
		return;
	
	//0- is client to check ?
	if ( g_iRemainingGroupCheck[ client ] == 0 )
		return;
	
	//1- find group id in the array
	new idInArray = -1;
	for ( new i; i < g_iWhitelistSteamGroupIdCount; ++i )
	{
		if ( groupAccountID == g_iWhitelistSteamGroupId[ i ] )
		{
			idInArray = i;
			break;
		}
	}
	
	//Isn't related to this plugin
	if ( idInArray == -1 ) 
		return;
	
	//Already received
	if ( g_bClientCheckedSteamGroupId[ client ][ idInArray ] == true )
		return;
	
	g_bClientCheckedSteamGroupId[ client ][ idInArray ] = true;
	
	//Client is in whitelist (can be a 2nd time; if someone's in 2 groups)
	if ( groupMember || groupOfficer )
	{
		decl String:szSteamId[ 20 ];
		if ( !GetClientAuthId( client, AuthId_Engine, szSteamId, sizeof(szSteamId) ) )
		{
			strcopy( szSteamId, sizeof(szSteamId), UNKNOWN_STEAMID );
		}
		
		SetTrieValue( g_hWhitelistCache, szSteamId, 0 );
		
		g_iRemainingGroupCheck[ client ] = 0;
#if defined DEBUG_MODE
		PrintToServer( "\t Client %N is member or officer of group %d", client, groupAccountID );
#endif
		return;
	}
	
	//Client is not =( ; check all 
	if ( --g_iRemainingGroupCheck[ client ] == 0 )
	{
		decl String:szSteamId[ 20 ];
		if ( !GetClientAuthId( client, AuthId_Engine, szSteamId, sizeof(szSteamId) ) )
		{
			strcopy( szSteamId, sizeof(szSteamId), UNKNOWN_STEAMID );
		}
		
		SetTrieValue( g_hBlacklistCache, szSteamId, 0 );
#if defined DEBUG_MODE
		PrintToServer( "\t Kicking because not whitelisted SteamID, IP and not in any whitelisted groups" );
#endif
		myKickClient( client );
	}
#if defined DEBUG_MODE
	PrintToServer( "\t End Steam_GroupStatusResult" );
#endif
}

//===== Admin Commands =====

public Action:CommandReload(client, args)
{
	loadList();
	
	ReplyToCommand( client, "[Whitelist] %d SteamIDs, %d IPs and %d SteamGroups loaded from whitelist", 
		GetTrieSize( g_hWhitelistSteamIdTrie ),
		GetTrieSize( g_hWhitelistIPTrie ),
		g_iWhitelistSteamGroupIdCount );
		
	return Plugin_Handled;
}
public Action:CommandRewrite(client, args)
{
	if ( !g_bShouldUpdateFile )
	{
		ReplyToCommand( client, "[Whitelist] No SteamId or IP were removed, therefore nothing changes" );
		return Plugin_Handled;
	}
	
	rewriteWhitelistFile();
	
	ReplyToCommand( client, "[Whitelist] Whitelist file rewritten" );
		
	return Plugin_Handled;
}
public Action:CommandList(client, args)
{
	PrintToConsole( client, "[Whitelist] Listing all SteamIDs, IPs and SteamGroups in the whitelist file : " );
	
	readAndPrintToClientWhitelistedStuff( client );
	
	PrintToConsole( client, "[Whitelist] -- End -- " );
	
	return Plugin_Handled;
}
public Action:CommandAdd(client, args)
{
	if(args < 1)
	{
		ReplyToCommand( client, "[SM] Usage: sm_whitelist_add <steamid | ip | groupid>" );
		return Plugin_Handled;
	}
	decl String:szBuffer[ 20 ];
	GetCmdArg( 1, szBuffer, sizeof(szBuffer) );
	TrimString( szBuffer );
	
	new bool:failing = formatStrAndGetReducedSize( szBuffer ) < 7;
	new bool:isNumeric = strIsPositiveInt( szBuffer );
	
	if ( isNumeric && StringToInt( szBuffer ) == -1 )
	{
		ReplyToCommand(client, "[SM] Could not add %s ; integer is too big to be a small SteamGroup id.", szBuffer);
		return Plugin_Handled;
	}
	
	if ( failing && !isNumeric )
	{
		ReplyToCommand(client, "[SM] Could not add %s ; incorrect input.", szBuffer);
		return Plugin_Handled;
	}
	
	ClearTrie( g_hBlacklistCache );
	
	decl String:path[ PLATFORM_MAX_PATH ];
	BuildPath( PathType:Path_SM, path, sizeof(path), "configs/whitelist/%s", g_szWhitelist_fileName );
	
	new Handle:file = OpenFile( path, "a" );
	if( file != INVALID_HANDLE )
	{
		//1-Header
		//1a STEAM
		decl String:szSteamId[ 20 ];
		if ( client != 0 )
		{
			if ( !GetClientAuthId( client, AuthId_Engine, szSteamId, sizeof(szSteamId) ) )
			{
				strcopy( szSteamId, sizeof(szSteamId), UNKNOWN_STEAMID );
			}
		}
		else
		{
			strcopy( szSteamId, sizeof(szSteamId), "STEAM_ID_IS_SERVER" );
		}
		
		//1b IP
		decl String:szIp[ 16 ];
		
		if ( client != 0 )
		{
			if ( !GetClientIP( client, szIp, sizeof(szIp) ) )
			{
				strcopy( szIp, sizeof(szIp), UNKNOWN_IP );
			}
		}
		else
		{
			strcopy( szIp, sizeof(szIp), "SERVER" );
		}
		
		//1c Date
		decl String:szDate[ 32 ];
		FormatTime( szDate, sizeof(szDate), DATETIMEFORMAT, GetTime() );
		
		//1d Custom comment
		decl String:szCustomComment[ 96 ];
		GetCmdArg( 2, szCustomComment, sizeof(szCustomComment) );
		
		//Add \n to be sure we're not adding after a comment
		WriteFileLine( file, "\n;auto Added by <%N;%s;IP_%s> on %s ; %s", client, szSteamId, szIp, szDate, szCustomComment );
		//2-Information
		if ( WriteFileLine( file, szBuffer ) )
		{
			g_bShouldUpdateFile = true; //remove possible "\n" misplaced ; I know this is terrible; but needed (an append could be made on an used line)
			
			if ( isNumeric )//its a group; we know from above
			{
				addSteamGroup( szBuffer );
			}
			else if ( strStartsWith( szBuffer, "STEAM", false ) || strStartsWith( szBuffer, "[U:", false ) ) //1.3.0 rec. AuthId_Steam3
			{
				SetTrieValue( g_hWhitelistSteamIdTrie, szBuffer, 0 );
			}
			else if ( strIsIPv4( szBuffer ) )
			{
				SetTrieValue( g_hWhitelistIPTrie, szBuffer, 0 );
			}
			else
			{
				ReplyToCommand( client, "[SM] Wrote trash to whitelist file", szBuffer );
			}
			ReplyToCommand( client, "[SM] %s successfully added to both the whitelist file and the current whitelist", szBuffer );
		}
		else
		{
			ReplyToCommand( client, "[SM] Failed to add %s to whitelist", szBuffer );
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] Failed to open %s for writing", path);
	}
	CloseHandle(file);
	
	return Plugin_Handled;
}
public Action:CommandExist(client, args)
{
	if(args < 1)
	{
		ReplyToCommand( client, "[SM] Usage: sm_whitelist_exist <steamid | ip | groupid>" );
		return Plugin_Handled;
	}
	
	decl String:szBuffer[ 20 ];
	GetCmdArg( 1, szBuffer, sizeof(szBuffer) );
	TrimString( szBuffer );
	
	new bool:failing = formatStrAndGetReducedSize( szBuffer ) < 7;
	new bool:isNumeric = strIsPositiveInt( szBuffer );
	
	if ( isNumeric && StringToInt( szBuffer ) == -1 )
	{
		ReplyToCommand(client, "[SM] Could not verify %s ; integer is too big to be a small SteamGroup id", szBuffer);
		return Plugin_Handled;
	}
	
	if ( failing && !isNumeric )
	{
		ReplyToCommand(client, "[SM] Could not verify %s ; incorrect input.", szBuffer);
		return Plugin_Handled;
	}
	
	decl useless;
	
	new bool:found = GetTrieValue( g_hWhitelistSteamIdTrie, szBuffer, useless ) || 
		GetTrieValue( g_hWhitelistIPTrie, szBuffer, useless ) ||
		( isNumeric && StringToInt( szBuffer ) >= 0 ); //1.3.0 oops
	
	ReplyToCommand( client, "[SM] %s is %sin the current loaded whitelist", szBuffer, found ? "" : "not " );
	
	return Plugin_Handled;
}
public Action:CommandRemove(client, args)
{
	if(args < 1)
	{
		ReplyToCommand( client, "[SM] Usage: sm_whitelist_remove <steamid | ip | groupid>" );
		return Plugin_Handled;
	}
	
	decl String:szBuffer[ 20 ]; //IPv6 size (with \0) if someday...
	GetCmdArg( 1, szBuffer, sizeof(szBuffer) );
	TrimString( szBuffer );
	
	new bool:failing = formatStrAndGetReducedSize( szBuffer ) < 7;
	new bool:isNumeric = strIsPositiveInt( szBuffer );
	
	if ( isNumeric && StringToInt( szBuffer ) == -1 )
	{
		ReplyToCommand(client, "[SM] Could not remove %s ; integer is too big to be a small SteamGroup id", szBuffer);
		return Plugin_Handled;
	}
	
	if ( failing && !isNumeric )
	{
		ReplyToCommand(client, "[SM] Could not remove %s ; incorrect input.", szBuffer);
		return Plugin_Handled;
	}
	
	new bool:found;
	
	found = bool:RemoveFromTrie( g_hWhitelistSteamIdTrie, szBuffer );
	if ( !found )
	{
		found = bool:RemoveFromTrie( g_hWhitelistIPTrie, szBuffer );
	}
	
	if ( !found )
	{
		found = bool:removeFromGroupArray( StringToInt( szBuffer ) );
		if ( found )
		{
			ClearTrie( g_hWhitelistCache ); //1.3.0 we clear the whitelist since whitelisted player might have been in the group
		}
	}
	
	if ( found )
	{
		SetTrieValue( g_hWhitelistRemoveTrie, szBuffer, 0 );
		
		if ( g_bWhitelist_removeinstant )
		{
			rewriteWhitelistFile();
		}
		else
		{
			g_bShouldUpdateFile = true;
		}
	}
	
	if ( found )
	{
		ReplyToCommand( client, "[SM] %s has been removed from the current loaded whitelist.", szBuffer );
		if ( g_bWhitelist_removeinstant )
		{
			ReplyToCommand( client, "[SM] %s should have been removed from %s.", szBuffer, g_szWhitelist_fileName );
		}
		else
		{
			ReplyToCommand( client, "[SM] %s will be removed from %s on map change.", szBuffer, g_szWhitelist_fileName );
		}
	}
	else
	{
		ReplyToCommand( client, "[SM] %s was not found in the current loaded whitelist. Nothing changed. ", szBuffer );
	}
	
	return Plugin_Handled;
}
public Action:CommandResetToDefault(client, args)
{
	deleteList();
	loadList( true );
	
	ReplyToCommand( client, "[Whitelist] Whitelist deleted and recreated default one." );
		
	return Plugin_Handled;
}

//===== ConVarChange =====

public ConVarChange_Enable(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if( newVal[0] == '1' )
	{
		g_bWhitelist_enable = true;
		loadList();
	}
	else
	{
		g_bWhitelist_enable = false;
	}
}
public ConVarChange_Immunity(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_bWhitelist_immunity = newVal[ 0 ] == '1' ;
}
public ConVarChange_FileName(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	//if contains '\' or '/' --> cancel !
	if ( newVal[ 0 ] == '\0' || StrContains( newVal, "\\" ) != -1 || StrContains( newVal, "/" ) != -1 )
	{
		LogMessage( "Someone tried to set the server's whitelist file to : '%s'", newVal );
		SetConVarString( cvar, g_szWhitelist_fileName );
	}
	else
	{
		strcopy( g_szWhitelist_fileName, sizeof(g_szWhitelist_fileName), newVal );
		ClearTrie( g_hWhitelistRemoveTrie );
		loadList();
		LogMessage( "Changed current whitelist file to %s", g_szWhitelist_fileName );
	}
}
public ConVarChange_KickMessage(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	strcopy( g_szKickMessage, sizeof(g_szKickMessage), newVal );
	LogMessage( "Changed kick message to '%s'", g_szKickMessage );
}
public ConVarChange_LogKick(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_iLogKick = StringToInt( newVal );
}
public ConVarChange_SteamGroup(Handle:cvar, const String:oldVal[], const String:newVal[])
{
#if defined DEBUG_MODE
	PrintToServer( "\t ConVarChange_SteamGroup:: From %s to %s", oldVal, newVal );
#endif
	g_iWhitelist_useSteamGroup = StringToInt( newVal );
	if ( g_iWhitelist_useSteamGroup > 0 )
	{
		if ( g_iCanUseSteamGroup == 0 )
		{
			LogMessage( "Both SteamTools and SteamWorks are not found : SteamGroups support is disabled." );
			SetConVarInt( cvar, 0 );
		}
		else if ( g_iCanUseSteamGroup == CAN_USE_STEAMWORKS && //CAN_USE_STEAMTOOLS = false
			g_iWhitelist_useSteamGroup == 1 )
		{
			//Not "fallforwarding"
			LogMessage( "Trying to use SteamTools but only SteamWorks is present. Try 'whitelist_steamgroup 2'. SteamGroups support is disabled." );
			SetConVarInt( cvar, 0 );
		}
		//possible fallbacks ; if we can't use SW but can use ST and if we want to use SW; we revert to ST
		//SW --> ST
		else if ( 
			( g_iCanUseSteamGroup & CAN_USE_STEAMWORKS == 0 ) && 
			( g_iCanUseSteamGroup & CAN_USE_STEAMTOOLS ) && 
			g_iWhitelist_useSteamGroup == 2 )
		{
			LogMessage( "Attempting to use SteamWorks but not found : Trying to revert to SteamTools." );
			SetConVarInt( cvar, 1 );
		}
	}
}
public ConVarChange_TidyKick(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_bWhitelist_useTidyKick = newVal[ 0 ] == '1';
	if ( !g_bCanUseTidyKick && g_bWhitelist_useTidyKick )
	{
		LogMessage( "TidyKick not found, therefore kick via TidyKick support is disabled." );
		SetConVarBool( cvar, false );
	}
}
public ConVarChange_SteamGroup_Timeout(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_bWhitelist_steamgroup_timeout = StringToFloat( newVal );
}
public ConVarChange_SteamGroup_NbRetry(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_iWhitelist_steamgroup_nbRetry = StringToInt( newVal );
}
public ConVarChange_AutoVouch(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_iWhitelist_autovouch = StringToInt( newVal );
}
public ConVarChange_AutoVouch_MinTimeout(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_fWhitelist_autovouch_timeout = StringToFloat( newVal );
}
public ConVarChange_RemoveInstant(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_bWhitelist_removeinstant = newVal[ 0 ] == '1';
}

//===== Privates =====

//=== File related

loadList(bool:justDeleted=false)
{
	ClearTrie( g_hBlacklistCache );
	g_iWhitelistSteamGroupIdCount = 0;
	
	decl String:path[ PLATFORM_MAX_PATH ];
	BuildPath( PathType:Path_SM, path, sizeof(path), "configs/whitelist/%s", g_szWhitelist_fileName );
	
	if ( !FileExists( path ) )
	{
		if ( justDeleted == false )
		{
			LogMessage( "Could not find %s, it will be created", path );
		}
		createInitialFile( path );
	}
	
	new Handle:file = OpenFile( path, "r" );
	if(file == INVALID_HANDLE)
	{
		SetFailState("[Whitelist] Unable to read file %s", path);
	}
	
	//file is found; we add stuff, so we clean the past to move on !
	ClearTrie( g_hWhitelistSteamIdTrie );
	ClearTrie( g_hWhitelistIPTrie );
	
	new bool:failing;
	new bool:isNumeric;
	
	decl String:szLine[ 256 ];
	while( !IsEndOfFile( file ) && ReadFileLine( file, szLine, sizeof(szLine) ) )
	{
		failing = formatStrAndGetReducedSize( szLine ) < 7;
		if ( szLine[ 0 ] == '\0' )
			continue;
		
		isNumeric = strIsPositiveInt( szLine );
		
		if ( isNumeric && StringToInt( szLine ) == -1 )
		{
			LogMessage( "whitelist.txt : Could not load %s ; integer is too big to be a small SteamGroup id", szLine);
			continue;
		}
		
		if ( failing && !isNumeric )
		{
			LogMessage( "whitelist.txt : Unrecognized SteamId, IP or SteamGroupId : '%s'", szLine );
			continue;
		}
		
		if ( isNumeric )//its a group; we know from above
		{
			addSteamGroup( szLine );
		}
		else if ( strStartsWith( szLine, "STEAM", false ) || strStartsWith( szLine, "[U:", false ) )
		{
			SetTrieValue( g_hWhitelistSteamIdTrie, szLine, 0 );
		}
		else if ( strIsIPv4( szLine ) )
		{
			SetTrieValue( g_hWhitelistIPTrie, szLine, 0 );
		}
		else
		{
			PrintToServer( "Unrecognized SteamId, IP or SteamGroupId : %s", szLine );
		}
	}
	
	CloseHandle(file);
}
createInitialFile( String:unexistingFilePath[] )
{
	//1- CreateDir
	decl String:pathDir[ PLATFORM_MAX_PATH ];
	strcopy( pathDir, sizeof(pathDir), unexistingFilePath );
	
	new index = strlen( pathDir ) - 2;
	while ( pathDir[ index ] != '\\' && pathDir[ index ] != '/' )
		--index;
	
	pathDir[ index + 1 ] = '\0';
	
	CreateDirectory( pathDir, 0x01FF ); //Also return false if it can't be created =(
	
	//2- CreateFile
	new Handle:file = OpenFile( unexistingFilePath, "w" );
	
	if ( file == INVALID_HANDLE )
	{
		SetFailState( "[Whitelist] Unable to create file %s. Might be missing permission.", unexistingFilePath );
	}
	
	WriteFileLine( file, "; You can use ';' to have comments (not read by the plugin)" );
	WriteFileLine( file, "; Write directly to insert either a SteamID or an IP" );
	WriteFileLine( file, "; Don't put more than 250 char on a line" );
	WriteFileLine( file, "; ';auto' tags gives various information surrounding an added user" );
	WriteFileLine( file, "127.0.0.1 ; IP; and comments can continue after them" );
	WriteFileLine( file, "STEAM_0:1:23456789 ; SteamID" );
	WriteFileLine( file, "STEAM_9:8:76543210" );
	WriteFileLine( file, "[U:1:2345678] ; SteamId" );
	WriteFileLine( file, "876543210 ; this would be a small SteamGroupId (< 2^31); every member/officer will be whitelisted" );
	
	CloseHandle( file );
}
deleteList()
{
	decl String:path[ PLATFORM_MAX_PATH ];
	BuildPath( PathType:Path_SM, path, sizeof(path), "configs/whitelist/%s", g_szWhitelist_fileName );
	
	if ( !FileExists( path ) )
	{
		LogMessage( "Could not find %s to delete", path );
		return;
	}
	
	if ( !DeleteFile( path ) )
	{
		LogMessage( "Error when deleting %s to update the whitelist", path );
		SetFailState("[Whitelist] Unable to delete file %s", path);
	}
	
	g_iWhitelistSteamGroupIdCount = 0;
	ClearTrie( g_hWhitelistSteamIdTrie );
	ClearTrie( g_hWhitelistIPTrie );
}

readAndPrintToClientWhitelistedStuff( client )
{
	decl String:path[ PLATFORM_MAX_PATH ];
	BuildPath( PathType:Path_SM, path, sizeof(path), "configs/whitelist/%s", g_szWhitelist_fileName );
	
	new Handle:file = OpenFile( path, "r" );
	if(file == INVALID_HANDLE)
	{
		SetFailState("[Whitelist] Unable to read file %s", path);
	}
	
	new bool:failing;
	new bool:isNumeric;
	
	decl String:szLine[ 256 ]; //A file with char above 256 can screw the listing :$ (meaning no buffer of 40; since ReadFileLine does stop when the buffer is full)
	while( !IsEndOfFile( file ) && ReadFileLine( file, szLine, sizeof(szLine) ) )
	{
		failing = formatStrAndGetReducedSize( szLine ) < 7;
		if ( szLine[ 0 ] == '\0' )
			continue;
		
		isNumeric = strIsPositiveInt( szLine );
		
		if ( failing == true && isNumeric == false )
			continue;
		
		if ( isNumeric == true && StringToInt( szLine ) == -1 )
			continue;
		
		PrintToConsole( client, szLine );
	}
	
	CloseHandle(file);
}

rewriteWhitelistFile()
{
	//new fileWith random name
	//Read old
	//Write new as old is read
	//when reaching steam/IP to remove, don't add them
	//careful about comments
	//
	//1- Open ReadFrom
	decl String:pathReadFrom[ PLATFORM_MAX_PATH ];
	BuildPath( PathType:Path_SM, pathReadFrom, sizeof(pathReadFrom), "configs/whitelist/%s", g_szWhitelist_fileName );
	
	new Handle:fileReadFrom = OpenFile( pathReadFrom, "r" );
	if( fileReadFrom == INVALID_HANDLE )
	{
		SetFailState("[Whitelist] Unable to read file %s", pathReadFrom);
	}
	
	//2- Open WriteTo
	decl String:pathWriteTo[ PLATFORM_MAX_PATH ];
	BuildPath( PathType:Path_SM, pathWriteTo, sizeof(pathWriteTo), "configs/whitelist/%s_tmp", g_szWhitelist_fileName );
	
	new Handle:fileWriteTo = OpenFile( pathWriteTo, "w" );
	if( fileWriteTo == INVALID_HANDLE )
	{
		CloseHandle( fileReadFrom );
		SetFailState("[Whitelist] Unable to write to file %s", pathWriteTo);
	}
	
	//3- Read old and write one line retardedly
	
	decl String:lineOne[ 256 ];
	decl String:lineTwo[ 256 ];
	decl String:lineOneOriginal[ 256 ];
	decl String:lineTwoOriginal[ 256 ];
	
	//1 = write (String; \n present in the string; write str as it is), 2 = write (Line; \n not present; write str with adding \n)
	new bool:writeLineOne;
	new bool:writeLineTwo;
	
	decl useless;
	
	while ( !IsEndOfFile( fileReadFrom ) && ReadFileLine( fileReadFrom, lineOne, sizeof(lineOne) ) )
	{
		strcopy( lineOneOriginal, sizeof(lineOneOriginal), lineOne );
		writeLineOne = false;
		writeLineTwo = false;
		
		if ( strStartsWith( lineOne, ";auto" ) )
		{
			if ( !IsEndOfFile( fileReadFrom ) && ReadFileLine( fileReadFrom, lineTwo, sizeof(lineTwo) ) )
			{
				strcopy( lineTwoOriginal, sizeof(lineTwoOriginal), lineTwo );
				//if being removed --> don't write any line
				//else write both
				
				if ( formatStrAndGetReducedSize( lineTwo ) >= 7 || ( strIsPositiveInt( lineTwo ) && StringToInt( lineTwo ) != -1 ) )
				{
					//Should already be removed from current whitelist tries
					//Just remove it; if it was there, that's all, else, write to file
					//if ( !RemoveFromTrie( g_hWhitelistRemoveTrie, lineTwo ) ) //tempting; but if added twice...
					if ( !GetTrieValue( g_hWhitelistRemoveTrie, lineTwo, useless ) )
					{
						writeLineOne = true;
						writeLineTwo = true;
					}
				}
			}
			else
			{
				LogMessage( "End of whitelist file %s seems to be incorrect ", g_szWhitelist_fileName );
				writeLineOne = true;
			}
		}
		else //not an auto comment; check if comment or to delete
		{
			if ( lineOne[ 0 ] == ';' )
			{
				writeLineOne = true;
			}
			else if ( formatStrAndGetReducedSize( lineOne ) >= 7 || ( strIsPositiveInt( lineOne ) && StringToInt( lineOne ) != -1 ) )
			{
				//if ( !RemoveFromTrie( g_hWhitelistRemoveTrie, lineOne ) ) //tempting; but if added twice...
				if ( !GetTrieValue( g_hWhitelistRemoveTrie, lineOne, useless ) )
				{
					writeLineOne = true;
				}
			}
		}
		
		if ( writeLineOne )
		{
			WriteFileString( fileWriteTo, lineOneOriginal, false );
		}
		if ( writeLineTwo )
		{
			WriteFileString( fileWriteTo, lineTwoOriginal, false );
		}
	}
	
	//4- Close files
	CloseHandle( fileReadFrom );
	CloseHandle( fileWriteTo );
	
	//5- Delete file
	if ( !DeleteFile( pathReadFrom ) )
	{
		LogMessage( "Error when deleting %s to update the whitelist", pathReadFrom );
		SetFailState("[Whitelist] Unable to delete file %s", pathReadFrom);
	}
	//6- Rename
	if ( !RenameFile( pathReadFrom, pathWriteTo ) )
	{
		SetFailState("[Whitelist] Unable to rename file %s to %s", pathWriteTo, pathReadFrom );
	}
	
	ClearTrie( g_hWhitelistRemoveTrie );
	g_bShouldUpdateFile = false;
}

//=== Kick

myKickClient( client, bool:isFromBlacklistCache=false )
{
	//1.3.0 we never kick if someone is vouching; if timeout not reached --> delay
	if ( g_iWhitelist_autovouch > 0 )
	{
		if ( g_iWhitelist_ClientIsVoucherCount > 0 )
		{
			//Deny kick; we got a voucher
			if ( g_iWhitelist_autovouch == 3 ) //becomes a voucher : invasive mode D:
			{
				g_iWhitelist_ClientBecameVoucherUserId[ client ] = GetClientUserId( client ); //Serial changes between map; need to use UserId
				g_bWhitelist_ClientIsVoucher[ client ] = true;
				g_iWhitelist_ClientIsVoucherCount++;
			}
			return;
		}
		//wait for vouchers; delay kick
		else 
		{
			new Float:timeWeCanKick = g_fWhitelist_ClientIsVoucherTimeAtShouldKick[ client ] + g_fWhitelist_autovouch_timeout;
			new Float:gameTime = GetGameTime();
			if ( gameTime < timeWeCanKick )
			{
				//Launch timer
				CreateTimer( timeWeCanKick - gameTime, Timer_DelayedKick, GetClientUserId( client ) );
				return;
			}
		}
	}
	
	decl String:szSteamId[ 20 ];
	decl String:szIPv4[ 16 ];
	
	if ( !GetClientAuthId( client, AuthId_Engine, szSteamId, sizeof(szSteamId ) ) )
	{
		strcopy( szSteamId, sizeof(szSteamId), UNKNOWN_STEAMID );
	}
	
	if ( !GetClientIP( client, szIPv4, sizeof(szIPv4 ) ) )
	{
		strcopy( szIPv4, sizeof(szIPv4), UNKNOWN_IP );
	}
	
	new Action:retval = Plugin_Continue;
		
#if defined DEV_KICK_FORWARD_INTERFACE
	Call_StartForward( g_hForwardOnClientKicked );
	Call_PushCell( client );
	Call_PushCell( isFromBlacklistCache );
	Call_PushString( szSteamId );
	Call_PushString( szIPv4 );
	Call_Finish(retval);
#endif
	
	if ( retval != Plugin_Continue )
		return;
	
	if ( g_iLogKick == 1 || ( g_iLogKick == 2 && !isFromBlacklistCache ) )
	{
		LogMessage( "Kicked %N (%s, %s) for not being on the whitelist", client, szSteamId, szIPv4 );
	}
	
	if ( !g_bWhitelist_useTidyKick )
		KickClient( client, "%s", g_szKickMessage );
	else
		TidyKickClient( client, "%s", g_szKickMessage );
}
//Delayed kick 1.3.0
public Action:Timer_DelayedKick( Handle:Timer, any:clientUserId )
{
	new clientId = GetClientOfUserId( clientUserId );
	
	if ( clientId > 0 )
	{
		myKickClient( clientId );
	}
	
	return Plugin_Handled;
}
//=== SteamTools or Group Ids related

sendStatusRequests( iClient )
{
#if defined DEBUG_MODE
	PrintToServer( "\t sendStatusRequests for %N, SGCount = %d", iClient, g_iWhitelistSteamGroupIdCount );
#endif
	g_iRemainingGroupCheck[ iClient ] = g_iWhitelistSteamGroupIdCount;
	
	g_bWhitelist_ClientIsBeingGroupValidated[ iClient ] = true;
	
	if ( g_iWhitelist_useSteamGroup == 2 ) //don't loop first; save checks
	{
		for ( new i; i < g_iWhitelistSteamGroupIdCount; ++i )
		{
			g_bClientCheckedSteamGroupId[ iClient ][ i ] = false;
			SteamWorks_GetUserGroupStatus( iClient, g_iWhitelistSteamGroupId[ i ] );
		}
	}
	else if ( g_iWhitelist_useSteamGroup == 1 )
	{
		for ( new i; i < g_iWhitelistSteamGroupIdCount; ++i )
		{
			g_bClientCheckedSteamGroupId[ iClient ][ i ] = false;
			Steam_RequestGroupStatus( iClient, g_iWhitelistSteamGroupId[ i ] );
		}
	}
	else
	{
		LogError( "Shouldn't happen; g_iWhitelist_useSteamGroup = %d in sendStatusRequests", g_iWhitelist_useSteamGroup );
	}
	
	g_hClientTimeoutTimers[ iClient ] = CreateTimer( g_bWhitelist_steamgroup_timeout, Timer_CheckPlayerGroups, iClient );
}
//clientAndTryCount ; 8 clients, rest = tryCount
public Action:Timer_CheckPlayerGroups( Handle:Timer, any:clientAndTryCount )
{
	new iClient = clientAndTryCount & 0xFF;
	new tryCount = clientAndTryCount >> 8;
	
#if defined DEBUG_MODE
	PrintToServer( "\t Timer_CheckPlayerGroups for %d, TryCoutn = %d", iClient, tryCount );
#endif
	
	if ( !IsClientConnected( iClient ) || g_iRemainingGroupCheck[ iClient ] == 0 )
	{
		g_hClientTimeoutTimers[ iClient ] = INVALID_HANDLE;
		return Plugin_Handled;
	}
	
	new remainingGroupsToCheck = g_iRemainingGroupCheck[ iClient ];
	new bool:relaunchedAtLeastSomething = false;
	
	if ( g_iWhitelist_useSteamGroup == 2 ) //don't loop first; save checks
	{
		for ( new i; i < g_iWhitelistSteamGroupIdCount && remainingGroupsToCheck != 0; ++i )
		{
			if ( g_bClientCheckedSteamGroupId[ iClient ][ i ] == false )
			{
				SteamWorks_GetUserGroupStatus( iClient, g_iWhitelistSteamGroupId[ i ] );
				--remainingGroupsToCheck;
				relaunchedAtLeastSomething = true;
			}
		}
	}
	else if ( g_iWhitelist_useSteamGroup == 1 )
	{
		for ( new i; i < g_iWhitelistSteamGroupIdCount && remainingGroupsToCheck != 0; ++i )
		{
			if ( g_bClientCheckedSteamGroupId[ iClient ][ i ] == false )
			{
				Steam_RequestGroupStatus( iClient, g_iWhitelistSteamGroupId[ i ] );
				--remainingGroupsToCheck;
				relaunchedAtLeastSomething = true;
			}
		}
	}
	
	if ( relaunchedAtLeastSomething )
	{
		if ( g_iWhitelist_steamgroup_nbRetry == -1 || tryCount < g_iWhitelist_steamgroup_nbRetry )
		{
			g_hClientTimeoutTimers[ iClient ] = CreateTimer( g_bWhitelist_steamgroup_timeout, Timer_CheckPlayerGroups, iClient | ( ( tryCount + 1 ) << 8 ) );
		}
		else
		{
			myKickClient( iClient );
		}
#if defined DEBUG_MODE
		PrintToServer( "\t Some groups were forgotten; Relaunching timer to check groups" );
#endif
	}
	else
	{
#if defined DEBUG_MODE
		PrintToServer( "\t How is this even possible D: (remaining groups to check, but all were fine...)" );
#endif
	}
	
	return Plugin_Handled;
}
//Should ensure that str contains a int < 2^31 before calling
bool:addSteamGroup( String:str[] )
{
	new groupId = StringToInt( str );
	
	new i;
	while ( i < g_iWhitelistSteamGroupIdCount )
	{
		if ( g_iWhitelistSteamGroupId[ i ] == groupId )
		{
			LogMessage( "Tried to add a another time %s", str );
			return false;
		}
		
		++i;
	}
	
	if ( i < MAXIMUM_STEAMGROUPS )
	{
		g_iWhitelistSteamGroupId[ i ] = groupId;
	}
	else
	{
		LogMessage( "Tried to add too many groups ; %s won't be added", str );
		return false;
	}

#if defined DEBUG_MODE
	PrintToServer( "\t Added SteamGroup %s", str );
#endif	
	++g_iWhitelistSteamGroupIdCount;
	return true;
}
bool:removeFromGroupArray( groupId )
{
	new i;
	while ( i < g_iWhitelistSteamGroupIdCount )
	{
		if ( g_iWhitelistSteamGroupId[ i ] == groupId )
		{
			for ( new j = i; j < g_iWhitelistSteamGroupIdCount - 1; ++j )
			{
				g_iWhitelistSteamGroupId[ j ] = g_iWhitelistSteamGroupId[ j + 1 ];
			}
			
			--g_iWhitelistSteamGroupIdCount;
			return true;
		}
		
		++i;
	}
	
	return false;
}

//=== String related

formatStrAndGetReducedSize( String:str[] )
{
	new len = strlen( str );
	for ( new i; i < len; i++ )
	{
		if ( IsCharSpace( str[ i ] ) || str[ i ] == ';' ) //remove next line !
		{
			str[ i ] = '\0';
			return i;
		}
	}
	
	return len;
}
bool:strStartsWith( String:str[], String:strStart[], bool:alsoCheckSize=true )
{
	new lenStrStart = strlen( strStart );
	if ( alsoCheckSize && strlen( str ) < lenStrStart )
		return false;
	
	return strncmp( str, strStart, lenStrStart, true ) == 0;
}
bool:strIsIPv4( String:str[] )
{
	new len = strlen( str );
	
	if ( len < 7 || len > 15 )
		return false;
	
	new dotCount;
	new lastDotIndex = -1;
	new bool:lastThingIsChar;
	
	for ( new i; i < len; ++i )
	{
		if ( IsCharNumeric( str[ i ] ) )
		{
			lastThingIsChar = true;
		}
		else if ( str[ i ] == '.' )
		{
			if ( lastDotIndex + 1 == i )
				return false;
			
			lastThingIsChar = false;
			lastDotIndex = i;
			++dotCount;
		}
		else
		{
			return false;
		}
	}
	
	
	return dotCount == 3 && lastThingIsChar;
}
bool:strIsPositiveInt( String:str[] )
{
	new len = strlen( str );
	
	for ( new i; i < len; ++i )
	{
		if ( !IsCharNumeric( str[ i ] ) )
			return false;
	}
	
	return len != 0;
}

//===== Natives

public Native_IsClientWhitelistStatusPending(Handle:hPlugin, iNumParams)//str, ret@bool ; only happen with groups
{
	new client = GetNativeCell( 1 );
	
	if ( 0 < client <= MAXPLAYERS + 1 )
		return false;
	
	return g_iRemainingGroupCheck[ client ] != 0;
}
public Native_IsSteamIdWhitelisted(Handle:hPlugin, iNumParams)//str, bool, ret@bool
{
	decl String:szSteamId[ 20 ];
	GetNativeString( 1, szSteamId, sizeof(szSteamId) );
	
	new bool:currentOnly = GetNativeCell( 2 );
	
	decl useless;
	
	if ( !currentOnly )
	{
		return !GetTrieValue( g_hWhitelistRemoveTrie, szSteamId, useless ) && GetTrieValue( g_hWhitelistSteamIdTrie, szSteamId, useless );
	}
	else
	{
		return GetTrieValue( g_hWhitelistSteamIdTrie, szSteamId, useless );
	}
}
public Native_IsIPWhitelisted(Handle:hPlugin, iNumParams)//str, bool, ret@bool
{
	decl String:szIP[ 16 ];
	GetNativeString( 1, szIP, sizeof(szIP) );
	
	new bool:currentOnly = GetNativeCell( 2 );
	
	decl useless;
	
	if ( !currentOnly )
	{
		return !GetTrieValue( g_hWhitelistRemoveTrie, szIP, useless ) && GetTrieValue( g_hWhitelistIPTrie, szIP, useless );
	}
	else
	{
		return GetTrieValue( g_hWhitelistIPTrie, szIP, useless );
	}
}
public Native_IsSteamGroupWhitelisted(Handle:hPlugin, iNumParams)//int, bool, ret@bool
{
	new steamGroupId = GetNativeCell( 1 );
	
	new bool:currentOnly = GetNativeCell( 2 );
	
	decl String:szSteamGroupId[ 16 ];
	IntToString( steamGroupId, szSteamGroupId, sizeof(szSteamGroupId) );
	
	new exist = false;
	
	for ( new i; i < g_iWhitelistSteamGroupIdCount; ++i )
	{
		if ( g_iWhitelistSteamGroupId[ i ] == steamGroupId )
		{
			exist = true;
			break;
		}
	}
	
	decl useless;
	
	if ( !currentOnly )
	{
		return exist && !GetTrieValue( g_hWhitelistRemoveTrie, szSteamGroupId, useless );
	}
	else
	{
		return exist;
	}
}
public Native_IsSteamIdWhitelistCached(Handle:hPlugin, iNumParams)//str, ret@bool
{
	decl String:szSteamId[ 20 ];
	GetNativeString( 1, szSteamId, sizeof(szSteamId) );
	
	decl useless;
	return GetTrieValue( g_hWhitelistCache, szSteamId, useless );
}
public Native_IsSteamIdBlacklistCached(Handle:hPlugin, iNumParams)//str, ret@bool
{
	decl String:szSteamId[ 20 ];
	GetNativeString( 1, szSteamId, sizeof(szSteamId) );
	
	decl useless;
	return GetTrieValue( g_hBlacklistCache, szSteamId, useless );
}