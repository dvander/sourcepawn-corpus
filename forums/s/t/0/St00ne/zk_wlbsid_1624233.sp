/**
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <sourcemod>
#include <console>
#include <adt_array>
#include <sdktools>
#include <regex>

#define ZK_VERSION     "1.6.9b"
#define ZK_AUTHOR      ".:€S C 90 ZAP Killer.be:."
#define ZK_STEAMIDLIST "zk_wlbsid_players.txt"
#define ZK_WEAPONSLIST "zk_wlbsid_weapons.txt"
//#define ZK_WARMUPTIMER 60.0

//==================================================================================================
// Globals
//==================================================================================================

new Handle:Arr_SteamIDs 			 = INVALID_HANDLE ;
new Handle:Arr_Weapons 				 = INVALID_HANDLE ;

new Handle:zk_wlbsid_enabled 		 = INVALID_HANDLE ;
new Handle:zk_wlbsid_timer 			 = INVALID_HANDLE ;
new Handle:zk_wlbsid_timer_delay 	 = INVALID_HANDLE ;
new Handle:zk_wlbsid_load_details	 = INVALID_HANDLE ;

new Handle:RegEx_SteamID 			 = INVALID_HANDLE ;
//new Handle:zk_wlbsid_override;

new bool:allow_msg[MAXPLAYERS+2]	 = {false,...};

public Plugin:myinfo =
{
	name = "Weapon Limitation By SteamID",
	author = ZK_AUTHOR,
	description = "Regarding a list of the SteamIDs of some known players, slay them if there are using specific weapons.",
	version = ZK_VERSION,
	url = "http://www.esc90.fr/"
}

//==================================================================================================
// Functions
//==================================================================================================

public OnPluginStart ()
{
	RegAdminCmd ( "zk_wlbsid_load"        , ZKWLBSIDCommand_Load           , ADMFLAG_KICK, "zk_wlbsid_load"         ) ;
	RegAdminCmd ( "zk_wlbsid_stop"        , ZKWLBSIDCommand_Stop           , ADMFLAG_KICK, "zk_wlbsid_stop"         ) ;
	RegAdminCmd ( "zk_wlbsid_status"      , ZKWLBSIDCommand_Status         , ADMFLAG_KICK, "zk_wlbsid_status"       ) ;
	RegAdminCmd ( "zk_wlbsid_list_players", ZKWLBSIDCommand_ListPlayers    , ADMFLAG_KICK, "zk_wlbsid_list_players" ) ;
	RegAdminCmd ( "zk_wlbsid_add"         , ZKWLBSIDCommand_AddPlayerToList, ADMFLAG_KICK, "zk_wlbsid_add"          ) ;
	RegAdminCmd ( "zk_wlbsid_list_weapons", ZKWLBSIDCommand_ListWeapons    , ADMFLAG_KICK, "zk_wlbsid_list_weapons" ) ;
	
	zk_wlbsid_enabled = CreateConVar ( "zk_wlbsid_enabled", "0", "State of Weapon Limitation By SteamID. Will be turned to 1 after a few seconds if zk_wlbsid_timer_value is not 0.", 0, true, 0.0, true, 1.0 ) ;	
	new Handle:version_cvar = CreateConVar("zk_wlbsid_version", ZK_VERSION, "Version of zk_wlbsid plugin.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_PRINTABLEONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD) ;
	SetConVarString(version_cvar, ZK_VERSION, false, false);
	
	HookConVarChange ( zk_wlbsid_enabled, ZKWLBSID_ConVarChange ) ;
	
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	
	zk_wlbsid_load_details = CreateConVar ( "zk_wlbsid_load_details", "1", "Display the number of restricted players and credits at plugin load.", FCVAR_PLUGIN, true, 0.0, true, 1.0 ) ;	
	zk_wlbsid_timer_delay  = CreateConVar ( "zk_wlbsid_timer_value", "60", "Number of seconds after which the plugin is automatically loaded. Set to 0 to dsiable this plugin.", FCVAR_PLUGIN, true, 0.0 ) ;
}

//--------------------------------------------------------------------------------------------------

public OnConfigsExecuted ()
{
	if (GetConVarInt(zk_wlbsid_timer_delay) != 0)
	{
		zk_wlbsid_timer = CreateTimer ( GetConVarInt(zk_wlbsid_timer_delay) * 1.0, ZKWLBSIDTimer_Load, _, TIMER_FLAG_NO_MAPCHANGE ) ;
	}
}

//--------------------------------------------------------------------------------------------------

public OnMapEnd ()
{
	SetConVarBool ( zk_wlbsid_enabled, false, true, true ) ;
}

//--------------------------------------------------------------------------------------------------

public ZKWLBSID_ConVarChange ( Handle:convar, const String:oldValue[], const String:newValue[] )
{
	//new N_old = StringToInt ( oldValue ) ;
	new N_new = StringToInt ( newValue ) ;
	
	if ( N_new == 1 )
	{
		ShowActivity2 ( 0, "[ZK] ", "Weapon Limitation By SteamID has been started" ) ;
		ZKWLBSID_Load ()
	}

	if ( N_new == 0 )
	{
		ShowActivity2 ( 0, "[ZK] ", "Weapon Limitation By SteamID has been stopped" ) ;

		if ( zk_wlbsid_timer != INVALID_HANDLE )
		{
			KillTimer ( zk_wlbsid_timer ) ;
		}
	}
}

//--------------------------------------------------------------------------------------------------

public ZKWLBSID_Load ()
{
	new String:Str_RegExpCompileError[256] ;
	new RegexError:Num_RegExpError ;

	decl String:RegEx_SteamIDPattern[256] ;

	RegEx_SteamIDPattern = "^(STEAM_\\d:\\d:\\d+)$" ;

	RegEx_SteamID = CompileRegex ( RegEx_SteamIDPattern , 0, Str_RegExpCompileError, sizeof ( Str_RegExpCompileError ) , Num_RegExpError ) ;

	if ( RegEx_SteamID == INVALID_HANDLE )
	{
		ShowActivity2 ( 0, "[ZK] ", "WLBSID error %d : regexp not compiled : %s !", Num_RegExpError, Str_RegExpCompileError ) ;
	}

	// Ouverture des fichiers TXT
	new Handle:File_SteamIDList = OpenFile ( ZK_STEAMIDLIST, "rt" ) ;
	new Handle:File_WeaponsList = OpenFile ( ZK_WEAPONSLIST, "rt" ) ;

	// Vérifications
	if ( File_SteamIDList == INVALID_HANDLE )
	{
		ShowActivity2 ( 0, "[ZK] ", "WLBSID error : %s not found !", ZK_STEAMIDLIST ) ;

		return ;
	}

	if ( File_WeaponsList == INVALID_HANDLE )
	{
		ShowActivity2 ( 0, "[ZK] ", "WLBSID error : %s not found !", ZK_WEAPONSLIST ) ;

		return ;
	}

	// Création des tableaux dans lesquels on mémorise les listes
	Arr_SteamIDs = CreateArray ( 256 ) ;
	Arr_Weapons  = CreateArray ( 64 ) ;

	// Lectures des SteamIDs
	new String:Str_SteamID[256] ;

	while ( ! IsEndOfFile ( File_SteamIDList ) && ReadFileLine ( File_SteamIDList, Str_SteamID, sizeof ( Str_SteamID ) ) )
	{
		StripQuotes ( Str_SteamID ) ;
		ReplaceString ( Str_SteamID, sizeof ( Str_SteamID ), "\r", "" ) ;
		ReplaceString ( Str_SteamID, sizeof ( Str_SteamID ), "\n", "" ) ;

		new RegexError:Num_ErrCode ;

		if ( MatchRegex ( RegEx_SteamID, Str_SteamID, Num_ErrCode ) != -1 )
		{
			GetRegexSubString ( RegEx_SteamID, 0, Str_SteamID, sizeof ( Str_SteamID ) ) ;
//			ShowActivity2 ( 0, "[ZK] ", "Adding SteamID: %s !", Str_SteamID ) ;
			PushArrayString ( Arr_SteamIDs, Str_SteamID ) ;	
		}
		else
		{
			ShowActivity2 ( 0, "[ZK] ", "Invalid SteamID: %s (%d) !", Str_SteamID, Num_ErrCode ) ;
		}
	}

	// Lectures du nom des armes
	new String:Str_Weapon[64] ;

	while ( ! IsEndOfFile ( File_WeaponsList ) && ReadFileLine ( File_WeaponsList, Str_Weapon, sizeof ( Str_Weapon ) ) )
	{
		StripQuotes ( Str_Weapon ) ;
		ReplaceString ( Str_Weapon, sizeof ( Str_Weapon ), "\r", "" ) ;
		ReplaceString ( Str_Weapon, sizeof ( Str_Weapon ), "\n", "" ) ;

		PushArrayString ( Arr_Weapons, Str_Weapon ) ;
	}

	if (GetConVarInt(zk_wlbsid_load_details) == 1)
	{
		ShowActivity2 ( 0, "[ZK] ", "Weapon Limitation By SteamID loaded, (%d players)", GetArraySize ( Arr_SteamIDs ) ) ;
		ShowActivity2 ( 0, "[ZK] ", "Made by %s v%s", ZK_AUTHOR, ZK_VERSION ) ;
	}

	HookEvent ( "player_hurt", ZKBSID_Run ) ;

	CloseHandle ( File_SteamIDList ) ;
	CloseHandle ( File_WeaponsList ) ;
}

//--------------------------------------------------------------------------------------------------

public ZKBSID_Run ( Handle:event, const String:name[], bool:dontBroadcast )
{
	if ( GetConVarBool ( zk_wlbsid_enabled ) )
	{
		// Get player index of involved players
		new Var_AttackerClientID = GetClientOfUserId ( GetEventInt ( event, "attacker" ) ) ;
		new String:Str_AttackerName[MAX_NAME_LENGTH] ;
		GetClientName ( Var_AttackerClientID, Str_AttackerName, sizeof ( Str_AttackerName ) ) ;

		decl String:Str_AttackerSteamID[32] ;
		decl String:Str_AttackerWeapon[32] ;

		if ( Var_AttackerClientID > 0 )
		{
			if ( GetClientAuthString ( Var_AttackerClientID, Str_AttackerSteamID, sizeof ( Str_AttackerSteamID ) ) && GetEventString ( event, "weapon", Str_AttackerWeapon, sizeof ( Str_AttackerWeapon ) ) )
			{
				new Num_PlayerFound = FindStringInArray ( Arr_SteamIDs, Str_AttackerSteamID ) ;
				new Num_WeaponFound = FindStringInArray ( Arr_Weapons , Str_AttackerWeapon  ) ;

				if ( Num_PlayerFound >= 0 && Num_WeaponFound >= 0 )
				{
					ForcePlayerSuicide ( Var_AttackerClientID ) ;
					if (allow_msg[Var_AttackerClientID])
					{
						//LogAction(-1, -1, "[ZK] Player %s was slayed for not following the Weapon Limitation rule.", Str_AttackerName);
						PrintToChatAll ("[ZK] Player %s was slayed for not following the Weapon Limitation rule.", Str_AttackerName);
						allow_msg[Var_AttackerClientID] = false;
						//CreateTimer ( 0.5, Display_Slay_Msg, any: Var_AttackerClientID ) ;
					}
				}
			}
		}
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( GetConVarBool ( zk_wlbsid_enabled ) )
	{	
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if (client !=0)
		{
			allow_msg[client] = true;
		}
	}
}

//public Action:Display_Slay_Msg ( Handle:timer, any: Var_AttackerClientID)
//{
//	new String:Str_AttackerName[MAX_NAME_LENGTH] ;
//	GetClientName ( Var_AttackerClientID, Str_AttackerName, sizeof ( Str_AttackerName ) ) ;
//	PrintToChatAll ("[ZK] Player %s was slayed for not following the Weapon Limitation rule.", Str_AttackerName);
//}


//==================================================================================================
// Timers
//==================================================================================================

public Action:ZKWLBSIDTimer_Load ( Handle:timer )
{
	zk_wlbsid_timer = INVALID_HANDLE; // Thanks to Frenzzy for correcting this part
	SetConVarBool ( zk_wlbsid_enabled, true, true, true ) ;
}

//==================================================================================================
// Actions
//==================================================================================================

public Action:ZKWLBSIDCommand_Stop ( client, args )
{
	if ( GetConVarBool ( zk_wlbsid_enabled ) )
	{
		SetConVarBool ( zk_wlbsid_enabled, false, true, true ) ;
	}

	return Plugin_Handled ;
}

//--------------------------------------------------------------------------------------------------

public Action:ZKWLBSIDCommand_Status ( client, args )
{
	if ( GetConVarBool ( zk_wlbsid_enabled ) )
	{
		ShowActivity2 ( 0, "[ZK] ", "Weapon Limitation By SteamID is ON (%d players)", GetArraySize ( Arr_SteamIDs ) ) ;
	}
	else
	{
		ShowActivity2 ( 0, "[ZK] ", "Weapon Limitation By SteamID is OFF" ) ;
	}

	return Plugin_Handled ;
}

//--------------------------------------------------------------------------------------------------

public Action:ZKWLBSIDCommand_Load ( client, args )
{
	zk_wlbsid_timer = CreateTimer ( 0.1, ZKWLBSIDTimer_Load, _, TIMER_FLAG_NO_MAPCHANGE ) ;

	return Plugin_Handled ;
}

//--------------------------------------------------------------------------------------------------

public Action:ZKWLBSIDCommand_ListPlayers ( client, args )
{
	new i ;

	new String:buffer[256] ;

	for ( i=0 ; i < GetArraySize ( Arr_SteamIDs ) ; i++ )
	{
		GetArrayString ( Arr_SteamIDs, i, buffer, sizeof ( buffer ) ) ;
		ShowActivity2 ( 0, "[ZK] ", "Player %d: %s", i, buffer ) ;
	}

	return Plugin_Handled ;
}

//--------------------------------------------------------------------------------------------------

public Action:ZKWLBSIDCommand_AddPlayerToList ( client, args )
{
	new String:Str_SteamID[256] ;
	new Handle:File_SteamIDList = OpenFile ( ZK_STEAMIDLIST, "at" ) ;
	new AddCount = 0 ;
	new RegexError:Num_ErrCode ;
 
	GetCmdArgString ( Str_SteamID, sizeof ( Str_SteamID ) ) ;

	StripQuotes ( Str_SteamID ) ;
	ReplaceString ( Str_SteamID, sizeof ( Str_SteamID ), "\r", "" ) ;
	ReplaceString ( Str_SteamID, sizeof ( Str_SteamID ), "\n", "" ) ;

	if ( MatchRegex ( RegEx_SteamID, Str_SteamID, Num_ErrCode ) != -1 )
	{
		GetRegexSubString ( RegEx_SteamID, 0, Str_SteamID, sizeof ( Str_SteamID ) ) ;
		StrCat ( Str_SteamID, sizeof ( Str_SteamID ), "\n" ) ;

		if ( WriteFileString ( File_SteamIDList, Str_SteamID, false ) )
		{
			ReplaceString ( Str_SteamID, sizeof ( Str_SteamID ), "\n", "" ) ;
			PushArrayString ( Arr_SteamIDs, Str_SteamID ) ;
			AddCount++ ;
			ShowActivity2 ( 0, "[ZK] ", "New Player: %s", Str_SteamID ) ;
		}
		else
		{
			ShowActivity2 ( 0, "[ZK] ", "Problem with WriteFileString !" ) ;
		}
	}
	else
	{
		for ( new i=1 ; i <= args ; i++ )
		{
			GetCmdArg ( i, Str_SteamID, sizeof ( Str_SteamID ) )

			StripQuotes ( Str_SteamID ) ;
			ReplaceString ( Str_SteamID, sizeof ( Str_SteamID ), "\r", "" ) ;
			ReplaceString ( Str_SteamID, sizeof ( Str_SteamID ), "\n", "" ) ;

			if ( MatchRegex ( RegEx_SteamID, Str_SteamID, Num_ErrCode ) != -1 )
			{
				GetRegexSubString ( RegEx_SteamID, 0, Str_SteamID, sizeof ( Str_SteamID ) ) ;

				StrCat ( Str_SteamID, sizeof ( Str_SteamID ), "\n" ) ;

				if ( WriteFileString ( File_SteamIDList, Str_SteamID, false ) )
				{
					ReplaceString ( Str_SteamID, sizeof ( Str_SteamID ), "\n", "" ) ;
					PushArrayString ( Arr_SteamIDs, Str_SteamID ) ;
					AddCount++ ;
					ShowActivity2 ( 0, "[ZK] ", "New Player: %s", Str_SteamID ) ;
				}
				else
				{
					ShowActivity2 ( 0, "[ZK] ", "Problem with WriteFileString !" ) ;
				}
			}
			else
			{
				ShowActivity2 ( 0, "[ZK] ", "Invalid SteamID: %s (%d) !", Str_SteamID, Num_ErrCode ) ;
			}
		}
	}

	if ( AddCount )
	{
		if ( FlushFile ( File_SteamIDList ) )
		{
			ShowActivity2 ( 0, "[ZK] ", "File %s successfully written !", ZK_STEAMIDLIST ) ;
		}
		else
		{
			ShowActivity2 ( 0, "[ZK] ", "Problem with %s !", ZK_STEAMIDLIST ) ;
		}
	}

	return Plugin_Handled ;
}

//--------------------------------------------------------------------------------------------------

public Action:ZKWLBSIDCommand_ListWeapons ( client, args )
{
	new i ;

	new String:buffer[64] ;

	for ( i=0 ; i < GetArraySize ( Arr_Weapons ) ; i++ )
	{
		GetArrayString ( Arr_Weapons, i, buffer, sizeof ( buffer ) ) ;
		ShowActivity2 ( 0, "[ZK] ", "Weapon %d: %s", i, buffer ) ;
	}

	return Plugin_Handled ;
}

//================================================================================================
// THIS IS THE END BEAUTIFUL FRIEND
// THIS IS THE END MY ONLY FRIEND, THE END
// OF OUR ELABORATE PLANS, THE END
// OF EVERYTHING THAT STANDS, THE END
// NO SAFETY OR SURPRISE, THE END
//================================================================================================