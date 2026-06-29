//CSGO Support, setassists Support, fixed incorrect default for mvp
/**
	Credits : 
	
	thetwistedpanda for an appreciated global code review (which was needed) and 
	information about various things I didn't know.
	
	Hunter-Digital for 1.6 version (Didn't use, thought it exist).
	
	siangc for an awesome testing.
	
	kar0t for DoD:S testing help
	
	Dog for his DoD:S bots (great help for DoD:S testing)
	
	klausenbusk for his m_iMVPs (Stars) code (didn't think to sm_dump them to find those :o)
	
	Dr!fter for his CS_SetMVPCount function (update to SM !).
*/
#pragma semicolon 1

#define DEV_INTERFACE

#undef REQUIRE_EXTENSIONS
#include <cstrike>
#define REQUIRE_EXTENSIONS

#include <sdktools>
#include <sdkhooks>
#include <clientprefs>

#undef REQUIRE_PLUGIN
#include <rankme>
#define REQUIRE_PLUGIN

#define PLUGIN_VERSION "1.6.0"

#define LOGGING_BASIC (1 << 0)
#define LOGGING_ADVANCED (1 << 1)

public Plugin:myinfo =
{
	name = "Kill Assist",
	author = "RedSword",
	description = "Gives money and/or points and/or stars for assisting a teamate on a kill.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

//Register damage
new g_dmgToClient[ MAXPLAYERS + 1][MAXPLAYERS + 1 ]; //[victimId][attackId] , [0] is worthless =(
//Register assist (MVP system only at first, then to know if we have to add bonus points for assists);
new g_iAssists[ MAXPLAYERS + 1 ];

//CVars
new Handle:g_hEnabled; //bool 0/1
new Handle:g_hMinDmg; //Minimum dmg dealth required to get assist (Def. 25)
new Handle:g_hAddKillerScore; //Def. 0
new Handle:g_hAddAssisterScore; //Def. 0
new Handle:g_hAddRankMeScore; //Def. 0
new Handle:g_hVerbose; //Def. 1
new Handle:g_hVerboseCookie; //Def. 1
new Handle:g_hLog; //Def. 0
new Handle:g_hLogTeamKillAssist; //Def. 0

//CVars : CS:S & GO
new Handle:g_hSplit; //bool 0/1
new Handle:g_hReward; //Def. 150 (CSS) or 0.5 * reward (CSGO)
new Handle:g_hRewardType; //CSGO; 1= %, 0= Fixed value
new Handle:g_hUseInGameAssistSystem; //CSGO
new Handle:g_hUseInGameThreshold; //CSGO
new Handle:g_hEnforceMax;
new Handle:g_hUseMVPStars;

//Mod specific
enum Working_Mod
{
	GAME_CSS = 1,
	GAME_CSGO,
	GAME_DODS,
	GAME_ELSE
};

new Working_Mod:g_currentMod;

//Prevent re-running a function (CS:S Stuff)
new g_iAccountOffsets;
new g_iMVPs;
new bool:g_bUseRankMe;
new bool:g_bIsCS_SetMVPCountAvailable;
new g_iPMIndex;
new bool:g_bHasToUnhookSDK;
new Handle:g_hWeaponPriceTrie;
new Handle:g_hConVarCashFactor;
new Handle:g_hConVarAssistDamageThreshold;
new Handle:g_hConVarMaxMoney;

//Cookies
new Handle:g_hCookie;
#define PRINT_ONCE_PER_MAP 256
new g_iCookieValue[ MAXPLAYERS + 1 ]; //8 first bits = verbose values, 9th = should print once per map ?
new bool:g_bHasPrintedOnceThisMap[ MAXPLAYERS + 1 ];
//g_hVerbose @ default cookie value
//g_hVerboseCookie @ use or not
new g_iDefaultCookieValue;

//Forwards
#if defined DEV_INTERFACE
new Handle:g_hForwardKillAssist = INVALID_HANDLE;
#endif

public OnPluginStart()
{
	//Allow multiples mod
	decl String:szBuffer[16];
	GetGameFolderName(szBuffer, sizeof(szBuffer));
	
	if (StrEqual(szBuffer, "cstrike", false))
		g_currentMod = Working_Mod:GAME_CSS;
	else if (StrEqual(szBuffer, "csgo", false))
		g_currentMod = Working_Mod:GAME_CSGO;
	else if (StrEqual(szBuffer, "dod", false))
		g_currentMod = Working_Mod:GAME_DODS;
	else
		g_currentMod = Working_Mod:GAME_ELSE;
	
	//CVARs
	CreateConVar("killassistversion", PLUGIN_VERSION, "Kill Assist version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_hEnabled				= CreateConVar("kassist", "1.0", "If kill assist is enabled. 1=Yes, Def. 1", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hMinDmg				= CreateConVar("kassist_minDmg", "35.0", "Minimum damage required to assist a kill. Def. 35", FCVAR_PLUGIN, true, 1.0);
	g_hAddKillerScore		= CreateConVar("kassist_killValue", "0.0", "Bonus points/frags given to a killer. Integer. Def. 0 (disabled)", FCVAR_PLUGIN, true, 0.0);
	g_hAddAssisterScore		= CreateConVar("kassist_assistValue", "0.0", "Bonus points/frags given to an assister. Real. Def. 0.0 (disabled)", FCVAR_PLUGIN, true, 0.0);
	g_hAddRankMeScore		= CreateConVar("kassist_rankMeValue", "0.0", 
		"RankMe points given to an assister. Integer. Def. 0 (disabled). Only use other values if you have RankMe.", FCVAR_PLUGIN, true, 0.0);
	g_hVerbose				= CreateConVar("kassist_verbose", "2.0", "The default value of the verbose cookie. Tell players when they assist someone. 1=Yes (always), 2=Yes (when dead, def.).", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	g_hVerboseCookie		= CreateConVar("kassist_verbose_cookie", "1.0", "If verbose cookies are used. 0=No, 1=Yes (Def.), 2=Yes (remove the 'always' option).", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	g_iDefaultCookieValue = GetConVarInt( g_hVerbose ) | PRINT_ONCE_PER_MAP; //needed (if cfg differs from defaults)
	HookConVarChange( g_hVerbose, ConVarChange_Cookie );
	HookConVarChange( g_hVerboseCookie, ConVarChange_Cookie );
	g_hLog					= CreateConVar("kassist_log", "0.0", 
		"Write in logs that there is an assist. 1=Yes (basic, short, assister only), 2=Yes (advanced, short, assister, killer and victim), 3=Yes (basic, long, assister only), 4=Yes (advanced, long, assister, killer and victim). Def. 0 (disabled)", 
		FCVAR_PLUGIN, true, 0.0, true, 4.0);
	g_hLogTeamKillAssist	= CreateConVar("kassist_log_teamkill", "0.0", 
		"Write in logs that there is an assist even if the assister helped kill a teammate. 1=Yes, 0=No. Def. 0.", 
		FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	//Conditional CVars
	if ( g_currentMod == GAME_CSS || g_currentMod == GAME_CSGO )
	{
		g_hSplit			= CreateConVar("kassist_split", "1.0", "If kill assist cash is split amongst assisters. 1=Yes, Def. 1.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
		g_hEnforceMax		= CreateConVar("kassist_enfMax", "1.0", 
			"Prevent values from a cash kill to get over the $16000/mp_maxmoney limit. 1=Yes, Def. 1.", 
			FCVAR_PLUGIN, true, 0.0, true, 1.0);
	}
	if ( g_currentMod == GAME_CSS )
	{
		g_hReward			= CreateConVar("kassist_cash", "150.0", "Kill assist cash awarded to assisters. Def. 150.", FCVAR_PLUGIN, true, 0.0);
		g_hUseMVPStars		= CreateConVar("kassist_useMVPStars", "2.0", 
		"Override MVPs (Stars) system to show assists ? 1=Yes (SDKHooks), 2=Yes (CS_SetMVPCount if available, else SDKHooks), Def. 2.", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	}
	else if ( g_currentMod == GAME_CSGO )
	{
		g_hRewardType			= CreateConVar("kassist_cashType", "1.0", 
			"An assist reward amount is : 1= relative to the amount the killer receive (in %). 0= a fixed amount (in $). Def. 1.", 
			FCVAR_PLUGIN, true, 0.0, true, 1.0);
		g_hReward				= CreateConVar("kassist_cash", "0.5", 
			"The relative (fraction) or fixed ($) amount assisters get from a kill, depending on ConVar kassist_cashType. Default 50% (0.5) of killer cash.", 
			FCVAR_PLUGIN, true, 0.0);
		g_hUseInGameAssistSystem	= CreateConVar("kassist_useInGameAssists", "1.0", 
			"Use in-game CSGO assist system (instead of replicating something similar). This means cs_AssistDamageThreshold is used instead of kassist_minDmg. 0=No. 1=Yes. Def. 1.", 
			FCVAR_PLUGIN, true, 0.0, true, 1.0);
		g_hUseInGameThreshold	= CreateConVar("kassist_useInGameThreshold", "0.0", 
			"If kassist_useInGameAssists = 0, use cs_AssistDamageThreshold used by CSGO instead of kassist_minDmg ? 0=No (Def.). 1=Yes.", 
			FCVAR_PLUGIN, true, 0.0, true, 1.0);
	}
	
	//Config
	AutoExecConfig(true, "killassist");
	
	//Translation file
	LoadTranslations("common.phrases"); //"Off", "On"
	LoadTranslations("killassist.phrases");
	
	//Hooks on events
	HookEvent("player_spawn", Event_Spawn); //change arrays : some 0s
	HookEvent("player_death", Event_Death, EventHookMode_Pre); //check arrays : give assists / add money to players
	if ( g_currentMod != GAME_DODS ) //CSS, CSGO, possibly other
	{
		HookEvent("round_start", Event_RoundStart);
	}
	if ( g_currentMod == GAME_CSS )
	{
		HookEvent("round_mvp", Event_RoundMVP);
	}
	
	//Hook on kassist so we keep dmg array clean
	HookConVarChange(g_hEnabled, ConVarChange_kassist);
	
	//Prevent re-running a function / CS:S Stuff
	g_bUseRankMe = GetFeatureStatus( FeatureType_Native, "RankMe_GivePoint" ) == FeatureStatus_Available;
	
	g_bIsCS_SetMVPCountAvailable = false;
	if ( g_currentMod == GAME_CSS || g_currentMod == GAME_CSGO ) //CSS, CSGO
	{
		g_iAccountOffsets	= FindSendPropOffs("CCSPlayer", "m_iAccount");
		
		if ( g_currentMod == GAME_CSS )
		{
			g_iMVPs		= FindSendPropOffs("CCSPlayerResource", "m_iMVPs"); //klausenbusk ftw :D
			
			//To prevent wrong value on the MvpStars ConVar
			g_bIsCS_SetMVPCountAvailable = CanTestFeatures() && GetFeatureStatus( FeatureType_Native, "CS_SetMVPCount" ) == FeatureStatus_Available;
			
			if ( GetConVarInt( g_hUseMVPStars ) == 2 && !g_bIsCS_SetMVPCountAvailable )
			{
				SetConVarInt( g_hUseMVPStars, 1 );
				LogMessage( "Tried to use MVPStars; this feature isn't available so falling back to SDKHooks" );
			}
			
			//Hook on mvp so we prevent using MVPCount if not available
			HookConVarChange( g_hUseMVPStars, ConVarChange_usemvpstars );
		}
		else //CS:GO
		{
			g_hWeaponPriceTrie = CreateTrie();
			parseWeaponScriptsAndPutThemInTrie( g_hWeaponPriceTrie );
			
			g_hConVarCashFactor = FindConVar( "cash_player_killed_enemy_factor" );
			if ( g_hConVarCashFactor == INVALID_HANDLE )
				LogMessage("Couldn't find ConVar cash_player_killed_enemy_factor. Make sure you use 'kassist_cashType 0'.");
			
			g_hConVarAssistDamageThreshold = FindConVar( "cs_AssistDamageThreshold" );
			if ( g_hConVarAssistDamageThreshold == INVALID_HANDLE )
				LogMessage("Couldn't find ConVar cs_AssistDamageThreshold. You may want to use 'kassist_useInGameThreshold 0'.");
			
			g_hConVarMaxMoney = FindConVar( "mp_maxmoney" );
			if ( g_hConVarMaxMoney == INVALID_HANDLE )
				LogMessage("Couldn't find ConVar mp_maxmoney.");
		}
	}
	
	#if defined DEV_INTERFACE
	//assisters[], nbAssisters, killerId, victimId
	g_hForwardKillAssist = CreateGlobalForward("OnAssistedKill", ET_Ignore, Param_Array, Param_Cell, Param_Cell, Param_Cell);
	#endif
	
	//Menu title
	decl String:menutitle[ 64 ];
	FormatEx( menutitle, sizeof(menutitle), "%T", "MenuTitleAssist", LANG_SERVER );
	SetCookieMenuItem( PrefMenu, 0, menutitle );
	g_hCookie = RegClientCookie( "kassist_verbose_assist", "When is a client informed of an Assist", CookieAccess_Private );
	
	//Late hook & cookies
	for ( int i = 1; i <= MaxClients; ++i )
	{
		if ( IsClientInGame( i ) == true )
		{
			SDKHook( i, SDKHook_OnTakeDamageAlive, Event_SDKHook_OnTakeDamageAlive );
			if ( AreClientCookiesCached( i ) )
			{
				GetClientCookie( i, g_hCookie, menutitle, sizeof(menutitle) );
				g_iCookieValue[ i ] = StringToInt( menutitle );
			}
			else
				g_iCookieValue[ i ] = g_iDefaultCookieValue;
		}
	}
}
//==========Menu

public PrefMenu(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	if (action == CookieMenuAction_SelectOption)
	{
		decl String:menuItem[ 64 ];
		new Handle:prefmenu = CreateMenu( PrefMenuHandler );
		
		FormatEx( menuItem, sizeof(menuItem), "%T", "MenuTitleAssist", client );
		SetMenuTitle( prefmenu, menuItem );
		
		new verboseValue = g_iCookieValue[ client ] & 0xFF;
		
		FormatEx( menuItem, sizeof(menuItem), "%T%T", "MenuVerboseOff", client, verboseValue == 0 ? "(Selected)" : "space", client );
		AddMenuItem( prefmenu, "0", menuItem );
		if ( GetConVarInt( g_hVerboseCookie ) != 2 )
		{
			FormatEx( menuItem, sizeof(menuItem), "%T%T", "MenuVerboseAlways", client, verboseValue == 1 ? "(Selected)" : "space", client );
			AddMenuItem( prefmenu, "1", menuItem );
		}
		FormatEx( menuItem, sizeof(menuItem), "%T%T", "MenuVerboseDeadOnly", client, verboseValue == 2 ? "(Selected)" : "space", client );
		AddMenuItem( prefmenu, "2", menuItem );
		
		FormatEx( menuItem, sizeof(menuItem), "%T(%T)", "MenuVerboseInformAboutTheMenu", client, g_iCookieValue[ client ] & PRINT_ONCE_PER_MAP ? "On" : "Off", client );
		AddMenuItem( prefmenu, g_iCookieValue[ client ] & PRINT_ONCE_PER_MAP ? "-2" : "-3", menuItem );
		DisplayMenu( prefmenu, client, MENU_TIME_FOREVER );
	}
}

public PrefMenuHandler(Handle:prefmenu, MenuAction:action, client, item)
{
	if ( action == MenuAction_Select )
	{
		decl String:pref[8];
		GetMenuItem( prefmenu, item, pref, sizeof(pref) );
		new receivedValue = StringToInt( pref ); //don't use -1 as -1 happens with too big int
		if ( receivedValue == -2 )
		{
			g_iCookieValue[ client ] &= ~PRINT_ONCE_PER_MAP;
		}
		else if ( receivedValue == -3 )
		{
			g_iCookieValue[ client ] |= PRINT_ONCE_PER_MAP;
		}
		else if ( 0 <= receivedValue <= 2 )
		{
			g_iCookieValue[ client ] = ( g_iCookieValue[ client ] & PRINT_ONCE_PER_MAP ) | receivedValue;
		}
		else
		{
			LogMessage( "PrefMenuHandler::Trying to set cookie value with '%s'", pref );
			return;
		}
		IntToString( g_iCookieValue[ client ], pref, sizeof(pref) );
		SetClientCookie( client, g_hCookie, pref );
		//ShowCookieMenu( client );
		PrefMenu( client, CookieMenuAction_SelectOption, 0, "", 0 );
	}
	else if ( action == MenuAction_End )
		CloseHandle( prefmenu );
}

//==========Events

//Clean array
public Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(g_hEnabled) == 1)
	{
		new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
		if ( iClient != 0 )
		{
			CleanClientIdAsVictim( iClient );
		}
	}
	
	return bool:Plugin_Continue;
}

//Add to array dmg given
public Action Event_SDKHook_OnTakeDamageAlive(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if ( GetConVarInt(g_hEnabled) == 0 || attacker <= 0 || attacker > MaxClients || IsClientInGame(attacker) == false )
		return Plugin_Continue;
	
	if ( GetClientTeam( victim ) != GetClientTeam( attacker ) ) //We don't want our allies to assist killing ourself !
	{
		g_dmgToClient[victim][attacker] += RoundToFloor( damage );
	}
	
	return Plugin_Continue;
}

//Give bounty
public Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( GetConVarInt(g_hEnabled) == 1 )
	{
		new victimId = GetClientOfUserId( GetEventInt( event, "userid" ) );
		new killerId = GetClientOfUserId( GetEventInt( event, "attacker" ) );
		new csgoAssisterId;
		
		if ( IsClientInGame( victimId ) )
		{
			//Killer points bonus
			if (killerId != 0 && //The world can't gain points
					killerId <= MaxClients && //No random entities can be assisters (ex: barrel (:o))
					IsClientInGame(killerId) &&
					GetClientTeam(victimId) != GetClientTeam(killerId)) //We don't want our allies to gain points for killing us !
			{
				SetEntProp(killerId, Prop_Data, "m_iFrags", GetClientFrags(killerId) + GetConVarInt(g_hAddKillerScore));
			}
			
			//Assists ($ + points)
			decl assisters[ MaxClients ]; //Our assisters array
			new nbAssisters; //Its length
			
			new minDmgNeededForAssist = GetConVarInt(g_hMinDmg);
			if ( g_currentMod == GAME_CSGO && GetConVarInt( g_hUseInGameThreshold ) == 1 )
			{
				minDmgNeededForAssist = GetConVarInt( g_hConVarAssistDamageThreshold ) + 1; //by default it's 40 but you need 41 for a Kill Assist
			}
			
			//Get assisters
			if ( g_currentMod == GAME_CSGO )
				csgoAssisterId = GetClientOfUserId( GetEventInt( event, "assister" ) ); //to avoid overgiving assists
			
			if ( g_currentMod != GAME_CSGO || GetConVarInt( g_hUseInGameAssistSystem ) == 0 )
			{
				for ( new i = MaxClients; i >= 1; --i )
					if ( g_dmgToClient[ victimId ][ i ] >= minDmgNeededForAssist && killerId != i )//If the minimum dmg is done && the killer doesn't get assist cash
						assisters[ nbAssisters++ ] = i;
			}
			else //game is CSGO & we use the ingame assist system
			{
				if ( csgoAssisterId != 0 )
				{
					assisters[ nbAssisters++ ] = csgoAssisterId;
				}
			}
			
			if ( nbAssisters > 0 ) //If we have assisters, we calculate money & assists to give them
			{
				if ( g_currentMod == GAME_CSS || g_currentMod == GAME_CSGO ) //Money = CS:S/GO
				{
					decl moneyToGive;
					
					if ( g_currentMod == GAME_CSS || 
							( g_currentMod == GAME_CSGO && GetConVarInt( g_hRewardType ) == 0 ) )
					{
						moneyToGive = GetConVarInt(g_hReward);
					}
					else //CS:GO && fraction of killer gain
					{
						//DEPENDING ON THE WPN, GET $ GAINED
						decl String:wpn[ 32 ];
						GetEventString(event, "weapon", wpn, sizeof(wpn)); //3 other doesn't really help :/
						
						if ( StrContains( wpn, "knife", false ) == 0 ) //GG CSGO @ knife_t ; knife_default_ct ... seems to be the only exception
							wpn = "knife";
						
						decl moneyGainedByKiller;
						
						if ( !GetTrieValue( g_hWeaponPriceTrie, wpn, moneyGainedByKiller ) )
						{
							moneyGainedByKiller = 300; //seems to always be this when not defined
						}
						
						moneyToGive = RoundToFloor( float( moneyGainedByKiller ) * GetConVarFloat( g_hReward ) * GetConVarFloat( g_hConVarCashFactor ) );
					}
					
					if ( moneyToGive > 0 )
					{
						if ( GetConVarInt(g_hSplit) == 1 )
							moneyToGive /= nbAssisters;
						
						GiveMoney( assisters, nbAssisters, moneyToGive, GetClientTeam( victimId ) );
					}
				}
				
				GiveAssistPoints( assisters, nbAssisters, killerId, victimId, csgoAssisterId, GetClientTeam( victimId ) );
				
				#if defined DEV_INTERFACE
				Call_StartForward( g_hForwardKillAssist );
				Call_PushArray( assisters, nbAssisters );
				Call_PushCell( nbAssisters );
				Call_PushCell( killerId );
				Call_PushCell( victimId );
				Call_Finish();
				#endif
			}
		}
	}
	
	return bool:Plugin_Continue;
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( GetTeamScore(2) + GetTeamScore(3) == 0 )
	{
		for ( new i = 1; i <= MaxClients; ++i )
			g_iAssists[ i ] = 0;
	}
}

public Event_RoundMVP(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( GetConVarInt( g_hUseMVPStars ) == 2 )
	{
		new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
		CS_SetMVPCount( iClient, g_iAssists[ iClient ] );
	}
}

public OverrideMVP_OnThinkPost(PlayerManagerIndex) //==g_iPMIndex
{	
	if (GetConVarInt(g_hEnabled) == 1 &&
			GetConVarInt(g_hUseMVPStars) == 1)
	{
		for (new idClient = 1; idClient <= MaxClients; idClient++)
			if (IsClientInGame(idClient))
			{
				SetEntData(PlayerManagerIndex, g_iMVPs + ((idClient) * 4), g_iAssists[idClient], 4, true);
				/*if ( g_iAssists[idClient] > 10 )//wtf not always... :/
				{
					PrintToChatAll("Setting stars of %N to %d", idClient, g_iAssists[idClient]);
				}*/
			}
	}
}

//==========Forwards

public void OnClientPutInServer(int client)
{
	SDKHook( client, SDKHook_OnTakeDamageAlive, Event_SDKHook_OnTakeDamageAlive );
}
public OnMapStart()
{
	if (g_currentMod == GAME_CSS && GetConVarInt( g_hUseMVPStars ) == 1 )
	{
		g_iPMIndex = FindEntityByClassname(MaxClients + 1, "cs_player_manager");
		SDKHook(g_iPMIndex, SDKHook_ThinkPost, OverrideMVP_OnThinkPost);
		g_bHasToUnhookSDK = true;
	}
	for ( new i = 1; i <= MaxClients; ++i )
		g_bHasPrintedOnceThisMap[ i ] = false;
}
//Clean array
public OnClientDisconnect(clientId)
{
	if ( GetConVarInt(g_hEnabled) == 1 )
	{
		if ( IsClientInGame( clientId ) )
			CleanClientIdAsAttacker( clientId );
		
		g_iAssists[clientId] = 0;
	}
	g_bHasPrintedOnceThisMap[ clientId ] = false;
}
public OnClientConnected(clientId) //done before cookies cached
{
	g_iCookieValue[ clientId ] = g_iDefaultCookieValue;
}
public OnClientCookiesCached(client)
{
	if ( GetConVarInt( g_hVerboseCookie ) == 0 )
		return;
	
	decl String:pref[ 8 ];
	GetClientCookie( client, g_hCookie, pref, sizeof(pref) );
	
	if ( !StrEqual( pref, "" ) )
	{
		g_iCookieValue[ client ] = StringToInt( pref );
		//If the client cookie was set when the VerboseCookie convar value was different
		if ( g_iCookieValue[ client ] & 0xFF == 1/*always*/ && GetConVarInt( g_hVerboseCookie ) == 2 )
		{
			g_iCookieValue[ client ] = ( g_iCookieValue[ client ] & 0xFFFFFF00 ) | 2;
		}
	}
	else //play it safe
	{
		g_iCookieValue[ client ] = g_iDefaultCookieValue;
	}
}

//==========ConVars

//Clean array
public ConVarChange_kassist(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if ( newValue[ 0 ] == '1' )
		for ( new i = MaxClients; i >= 1; --i )
		{
			for ( new j = MaxClients; j >= 1; --j )
				g_dmgToClient[ i ][ j ] = 0;
			
			g_iAssists[ i ] = 0;
		}
}
//prevent using CS_SetMvpStars if not available
public ConVarChange_usemvpstars(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if ( g_bHasToUnhookSDK && oldValue[0] == '1' && !( newValue[0] == '2' && !g_bIsCS_SetMVPCountAvailable ) )
	{
		g_iPMIndex = FindEntityByClassname(MaxClients + 1, "cs_player_manager");
		SDKUnhook(g_iPMIndex, SDKHook_ThinkPost, OverrideMVP_OnThinkPost);
		g_bHasToUnhookSDK = false;
	}
	
	if ( newValue[0] == '2' )
	{
		if ( !g_bIsCS_SetMVPCountAvailable )
		{
			//Revert back to SDKHooks
			SetConVarInt( convar, 1 );
			LogMessage( "Tried to use MVPStars; this feature isn't available so falling back to SDKHooks" );
		}
		else
		{
			//Set MvpStars in memory to assists to all players
			for ( new i = 1; i <= MaxClients; ++i )
			{
				if ( IsClientInGame( i ) )
					CS_SetMVPCount( i, g_iAssists[i] );
			}
		}
	}
	else if ( newValue[ 0 ] == '0' )
	{
		//Set MvpStars in memory to 0 to all players
		for ( new i = 1; i <= MaxClients; ++i )
		{
			if ( IsClientInGame( i ) )
				CS_SetMVPCount( i, 0 );
		}
	}
	else if ( newValue[0] == '1' )
	{
		g_iPMIndex = FindEntityByClassname(MaxClients + 1, "cs_player_manager");
		SDKHook(g_iPMIndex, SDKHook_ThinkPost, OverrideMVP_OnThinkPost);
		g_bHasToUnhookSDK = true;
	}
}
public ConVarChange_Cookie(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new verbose = GetConVarInt( g_hVerbose );
	if ( verbose == 1/*always*/ && GetConVarInt( g_hVerboseCookie ) == 2/*prevent always*/ )
	{
		LogMessage( "Trying to always show assists while it is prevented by kassist_verbose_cookie" );
		SetConVarString( convar, oldValue );
		return;
	}
	g_iDefaultCookieValue = verbose | PRINT_ONCE_PER_MAP;
}

//==========Privates

//Set to 0 every damage dealt by that player (when a player disconnect; since he won't die we don't care about how he much did get hurt)
Action:CleanClientIdAsAttacker(any:clientId)
{
	for ( new i = MaxClients; i >= 1; --i )
		g_dmgToClient[ i ][ clientId ] = 0;
}

//Set to 0 only damage received (prevent useless iterations; at player_spawn; so a player in DM could have assist)
Action:CleanClientIdAsVictim(any:clientId)
{
	for ( new i = MaxClients; i >= 1; --i )
		g_dmgToClient[ clientId ][ i ] = 0;
}

//Give money to the clients in the array
Action:GiveMoney(assisters[], any:nbAssisters, any:cash, victimTeam)
{
	new enforcedMaxCash = GetConVarInt( g_hEnforceMax );
	
	new maxMoney = g_currentMod != GAME_CSGO ? 16000 : GetConVarInt( g_hConVarMaxMoney );
	
	for (new i; i < nbAssisters; ++i)
	{
		if ( victimTeam == GetClientTeam( assisters[ i ] ) ) //do not receive money for helping kill a teammate
			continue;
		
		new newClientCash = GetEntData( assisters[ i ], g_iAccountOffsets ) + cash;
		
		if ( newClientCash > maxMoney && enforcedMaxCash == 1 )
			newClientCash = maxMoney;
		
		SetEntData( assisters[ i ], g_iAccountOffsets, newClientCash );
	}
}

//Give points to the clients in the array & count assist
Action:GiveAssistPoints(assisters[], any:nbAssisters, any:killerId, victimId, csgoAssisterId/*to prevent adding assists*/, victimTeam )
{
	new Float:pointsForAssist = GetConVarFloat( g_hAddAssisterScore );
	decl additionnalPoints;
	new verbose = GetConVarInt( g_hVerbose );
	new bool:verboseOncePerMap = true;
	new verboseCookie = GetConVarInt( g_hVerboseCookie );
	new typeMVPStars;
	if (g_currentMod == GAME_CSS)
	{
		typeMVPStars = GetConVarInt(g_hUseMVPStars);
	}
	decl assisterId;
	
	for (new i; i < nbAssisters; ++i)
	{
		assisterId = assisters[i]; //avoid ptr deref
		
		if ( victimTeam != GetClientTeam( assisterId ) ) //the opposite should mostly happen in CSGO (or massive team swap stuff)
		{
			++g_iAssists[ assisterId ];
			
			if ( g_bUseRankMe )
			{
				new addRankMeScore = GetConVarInt( g_hAddRankMeScore );
				if ( addRankMeScore != 0 )
				{
					RankMe_GivePoint( assisterId, addRankMeScore, "Kill assist", 1, 0 );
				}
			}
			
			//always relative to THIS plugin only assists (not CSGO actual assists); so we might 'lose' points when modifying assists from outside
			additionnalPoints = 
				RoundToFloor( pointsForAssist * g_iAssists[assisterId] )
				- RoundToFloor( pointsForAssist * ( g_iAssists[assisterId] - 1 ) );
			
			SetEntProp(assisterId, Prop_Data, "m_iFrags", GetClientFrags(assisterId) + additionnalPoints);
			
			if (g_currentMod == GAME_CSS)
			{
				if ( typeMVPStars == 2 )
				{
					CS_SetMVPCount( assisterId, g_iAssists[ assisterId ] );
				}
			}
			else if (g_currentMod == GAME_CSGO) //allow many assiter per kill
			{
				//Games add assists by itself
				if ( assisterId != csgoAssisterId )
				{
					CS_SetClientAssists( assisterId, CS_GetClientAssists( assisterId ) + 1 );
				}
			}
		}
		
		//===== VERBOSE & LOGGING
		if ( verboseCookie != 0 ) //we use cookies
		{
			verbose = g_iCookieValue[ assisterId ] & 0xFF;
			verboseOncePerMap = g_iCookieValue[ assisterId ] & PRINT_ONCE_PER_MAP == PRINT_ONCE_PER_MAP;
		}
		if ( verbose == 1 || ( verbose == 2 && !IsPlayerAlive( assisterId ) ) )
		{
			PrintToChat( assisterId, "\x04[SM] \x01%t", "Assist", "\x03", killerId, "\x01", "\x05", victimId, "\x01" );
			if ( g_bHasPrintedOnceThisMap[ assisterId ] == false && verboseCookie != 0 && verboseOncePerMap == true )
			{
				PrintToChat( assisterId, "\x04[SM] \x01%t", "TellHowToChange", "\x03", "\x01", "\x03", "\x01" );
				g_bHasPrintedOnceThisMap[ assisterId ] = true;
			}
		}
		
		new iLog = GetConVarInt( g_hLog );
		if ( iLog != 0 && 
			( GetConVarInt( g_hLogTeamKillAssist ) == 1 || 
			( GetConVarInt( g_hLogTeamKillAssist ) == 0 && victimTeam != GetClientTeam( assisterId ) ) ) )
		{
			--iLog;
			
			new bool:longForStatsTrackLog = iLog / 2 == 1;
			new bool:advancedLog = iLog % 2 == 1;
			
			decl String:logString[ 256 ];
			decl String:steamId[ 20 ];
			decl String:teamName[ 16 ];
			
			//Assister
			GetClientAuthId( assisterId, AuthId_Engine, steamId, sizeof(steamId) );
			if ( !longForStatsTrackLog )
			{
				FormatEx( logString, sizeof(logString), "\"%N<%s>\" assisted on a kill", assisterId, steamId );
			}
			else
			{
				GetTeamName( GetClientTeam( assisterId ), teamName, sizeof(teamName) );
				FormatEx( logString, sizeof(logString), "\"%N<%d><%s><%s>\" triggered \"killassist\"", assisterId, GetClientUserId( assisterId ), steamId, teamName );
			}
			
			if ( advancedLog )
			{
				Format( logString, sizeof(logString), "%s. ", logString );
				
				//Killer
				GetClientAuthId( killerId, AuthId_Engine, steamId, sizeof(steamId) );
				if ( !longForStatsTrackLog )
				{
					Format( logString, sizeof(logString), "%s Killer : \"%N<%s>\"", logString, killerId, steamId );
				}
				else
				{
					GetTeamName( GetClientTeam( killerId ), teamName, sizeof(teamName) );
					Format( logString, sizeof(logString), "%s Killer : \"%N<%d><%s><%s>\"", logString, killerId, GetClientUserId( killerId ), steamId, teamName );
				}
				
				//Victim
				GetClientAuthId( victimId, AuthId_Engine, steamId, sizeof(steamId) );
				if ( !longForStatsTrackLog )
				{
					Format( logString, sizeof(logString), "%s Victim : \"%N<%s>\"", logString, victimId, steamId );
				}
				else
				{
					GetTeamName( GetClientTeam( victimId ), teamName, sizeof(teamName) );
					Format( logString, sizeof(logString), "%s Victim : \"%N<%d><%s><%s>\"", logString, victimId, GetClientUserId( victimId ), steamId, teamName );
				}
			}
			
			LogToGame( "%s", logString );
		}
	}
	
}

/**
 * CSGO PART
 */
parseWeaponScriptsAndPutThemInTrie( Handle:trieHandle )
{
	new Handle:file;
	new Handle:dir;
	
	dir = OpenDirectory( "scripts" );
	
	decl String:szPathToFilename[ 40 ];
	decl String:szWeaponFilename[ 32 ];
	decl String:szWeaponNameBuffer[ 16 ];
	decl String:szLine[ 128 ];
	
	while ( ReadDirEntry( dir, szWeaponFilename, sizeof(szWeaponFilename) ) )
	{
		if ( !strStartsWith( szWeaponFilename, "weapon_" ) )
			continue;
		
		FormatEx( szPathToFilename, sizeof(szPathToFilename), "scripts/%s", szWeaponFilename );
		
		file = OpenFile( szPathToFilename, "r" );
		
		while ( ReadFileLine( file, szLine, sizeof(szLine) ) )
		{
			new index;
			while ( szLine[ index ] != '\0' && szLine[ index ] != '\"' )
				++index;
			
			if ( !strStartsWithStrAtIndex( szLine, "\"KillAward\"", index ) )
				continue;
			
			index += 11; //strlen( "\"KillAward\"" );
			
			//Get to next '\"'
			while ( szLine[ index ] != '\0' && szLine[ index ] != '\"' )
				++index;
			
			decl String:szBuffer[ 8 ];
			new bufferIdx;
			new quoteEncountered;
			
			while ( quoteEncountered != 2 && szLine[ index + bufferIdx ] != '\0' && bufferIdx < 7)
			{
				if ( szLine[ index + bufferIdx ] == '\"' )
				{
					++quoteEncountered;
				}
				else
				{
					szBuffer[ bufferIdx - quoteEncountered ] = szLine[ index + bufferIdx ];
				}
				++bufferIdx;
			}
			
			new value = StringToInt( szBuffer );
			
			getWeaponNameFromFilename( szWeaponFilename, szWeaponNameBuffer );
			
			SetTrieValue( trieHandle, szWeaponNameBuffer, value );
			//PrintToServer("Found value for %s : %d", szWeaponNameBuffer, value); //dbg
			break;
		}
		
		CloseHandle( file );
	}
	
}
//String helpers
bool:strStartsWith( const String:szToCheck[], const String:szStart[] )
{
	new startLen = strlen( szStart );
	if ( startLen > strlen( szToCheck ) )
		return false;
	
	for ( new i; i < startLen; ++i )
	{
		if ( szStart [ i ] != szToCheck[ i ] )
			return false;
	}
	
	return true;
}
bool:strStartsWithStrAtIndex( const String:szToCheck[], const String:szStartAtIndex[], index )
{
	new szStartAtIndexLen = strlen( szStartAtIndex ) + index;
	if ( szStartAtIndexLen > strlen( szToCheck ) )
		return false;
	
	for ( new i = index; i < szStartAtIndexLen; ++i )
	{
		if ( szStartAtIndex[ i - index ] != szToCheck[ i ] )
			return false;
	}
	
	return true;
}
getWeaponNameFromFilename( const String:szFilename[], String:szWeaponname[] )
{
	//7 = strlen("weapon_")
	new i = 7;
	for ( ; szFilename[ i ] != '\0' && szFilename[ i ] != '.'; ++i )
	{
		szWeaponname[ i - 7 ] = szFilename[ i ];
	}
	szWeaponname[ i - 7 ] = '\0';
}
/**
* END CSGO PART
*/