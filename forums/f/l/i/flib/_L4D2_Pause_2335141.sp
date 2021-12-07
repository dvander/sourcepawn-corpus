#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define VERSION "1.1.0-fixed"


static	g_iYesCount = 0,
		g_iNoCount = 0,
		g_iVoters = 0,

		bool:g_bIsPause = false,
		bool:g_bAdminPause = false,
		bool:g_bAllowPause = false,
		bool:g_bAllVoted = false,
		bool:g_bToggleAllTalk = true,
		g_iFlags[MAXPLAYERS+1],
		
		String:g_CurrentURL[192],

		Handle:g_hTimout,
		Handle:g_hForcePauseOnly,
		Handle:g_hPauseAllTalk,
		Handle:g_hRadioEnabled,
		Handle:g_hRadioURL,
		Handle:g_hRadioLoadingURL,
		Handle:g_hSbStop, 
		Handle:g_hNbStop, 
		Handle:g_hSvPausable, 
		Handle:g_hFloodTime, 
		Handle:g_hAllTalk;


public Plugin:myinfo =
{
	name = "[L4D2] Pause",
	author = "N3wton, SilverShot",
	description = "Pauses the game",
	version = VERSION
};

public OnPluginStart()
{
	g_hTimout = CreateConVar( "l4d2_pause_request_timout", "10.0", "How long the pause request should be visable", FCVAR_PLUGIN, true, 5.0, true, 30.0 );
	g_hForcePauseOnly = CreateConVar( "l4d2_pause_force_only", "0", "Only allow force pauses", FCVAR_PLUGIN );
	g_hPauseAllTalk = CreateConVar( "l4d2_pause_alltalk", "1", "Turns Alltalk on when paused", FCVAR_PLUGIN );
	g_hRadioEnabled = CreateConVar( "l4d2_pause_radio_enabled", "0", "Enable the playing of a radio station, whilst paused" );
	g_hRadioURL = CreateConVar( "l4d2_pause_radio_url", "www.radioparadise.com/flash_player.php", "The url of the streaming radio station to be used (do not include http://) e.g. www.mydomain/l4d2pauseradio.html" );
	g_hRadioLoadingURL = CreateConVar( "l4d2_pause_radio_loading_url",
	"www.valvesoftware.com", "The URL of the MOTD whilst the radio is loading e.g. www.mydomain/l4d2pauseradio-loading.html" );
	AutoExecConfig( true, "[L4D2]Pause" );

	if( (g_hSbStop = FindConVar("sb_stop")) == INVALID_HANDLE )
		SetFailState("Cannot find 'sb_stop' handle. Plugin will now unload.");
	if( (g_hNbStop = FindConVar("nb_stop")) == INVALID_HANDLE )
		SetFailState("Cannot find 'nb_stop' handle. Plugin will now unload.");
	if( (g_hSvPausable = FindConVar("sv_pausable")) == INVALID_HANDLE )
		SetFailState("Cannot find 'sv_pausable' handle. Plugin will now unload.");
	if( (g_hFloodTime = FindConVar("sm_flood_time")) == INVALID_HANDLE )
		SetFailState("Cannot find 'sm_flood_time' handle. Plugin will now unload.");
	if( (g_hAllTalk = FindConVar("sv_alltalk")) == INVALID_HANDLE )
		SetFailState("Cannot find 'sv_alltalk' handle. Plugin will now unload.");

	SetConVarBool( g_hSvPausable, false );
	
	RegConsoleCmd( "sm_pause", Command_SMPause, "Pauses the game" );
	RegConsoleCmd( "sm_unpause", Command_SMUnpause, "Unpauses the game" );
	RegAdminCmd( "sm_forcepause", Command_SMForcePause, ADMFLAG_KICK, "Forces the game to pause" );
	RegAdminCmd( "sm_forceunpause", Command_SMForceUnpause, ADMFLAG_KICK, "Forces the game to unpause" );
	
	RegConsoleCmd( "sm_radio_on", Command_SMRadio, "Starts the radio" );
	RegConsoleCmd( "sm_radio_off", Command_SMRadioOff, "Stops the radio" );
		
	AddCommandListener( Command_Say, "say" );
	AddCommandListener( Command_SayTeam, "say_team" );
	AddCommandListener( Command_Real_Pause, "pause");
	AddCommandListener( Command_Real_Pause, "setpause");
	AddCommandListener( Command_Real_Pause, "unpause");
	
	HookEvent("player_team", Event_PlayerChangeTeam, EventHookMode_Pre);
}

public Action:Command_Say(client, const String:command[], argc) 
{
	if (g_bIsPause)
	{
		decl String:sText[256];
		GetCmdArgString(sText, sizeof(sText));
		StripQuotes(sText);
		if(client == 0) return Plugin_Continue;
		
		if( GetClientTeam(client) == 2 )PrintToChatAll("\x03%N\x01 : %s", client, sText);
		if( GetClientTeam(client) == 3 )PrintToChatAll("\x05%N\x01 : %s", client, sText);
		if( GetClientTeam(client) != 2 && GetClientTeam(client) != 3 )PrintToChatAll("\x02%N\x01 : %s", client, sText);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:Command_SayTeam(client, const String:command[], argc) 
{
	if (g_bIsPause)
	{
		decl String:sText[256];
		GetCmdArgString(sText, sizeof(sText));
		StripQuotes(sText);
		if(client == 0) return Plugin_Continue;
		
		for( new i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) && !IsFakeClient(i) )
			{
				if( GetClientTeam(client) == GetClientTeam(i) )
				{
					if( GetClientTeam(client) == 2 ) PrintToChat( i, "\x01(Survivor) \x03%N\x01 : %s", client, sText);
					if( GetClientTeam(client) == 3 ) PrintToChat( i, "\x01(Infected) \x05%N\x01 : %s", client, sText);
					if( GetClientTeam(client) != 2 && GetClientTeam(client) != 3 ) PrintToChat( i, "\x01(Spec) \x02%N\x01 : %s", client, sText);
				}
			}
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

stock GetValidClient()
{
	for (new target = 1; target <= MaxClients; target++)
	{
		if( IsClientInGame(target) && !IsFakeClient(target) ) return target;
	}
	return 0;
}

stock ChatFloodOn()
{
	new Flags = GetConVarFlags( g_hFloodTime );
	SetConVarFlags( g_hFloodTime, (Flags & ~FCVAR_NOTIFY) );
	ResetConVar( g_hFloodTime );
	SetConVarFlags( g_hFloodTime, Flags );
}

stock ChatFloodOff()
{
	new Flags = GetConVarFlags( g_hFloodTime );
	SetConVarFlags( g_hFloodTime, (Flags & ~FCVAR_NOTIFY) );
	SetConVarFloat( g_hFloodTime, 0.0 );
	SetConVarFlags( g_hFloodTime, Flags ); 
}

stock AllTalkOn()
{
	if( GetConVarBool( g_hPauseAllTalk ) )
	{
		if( GetConVarBool(g_hAllTalk) ) g_bToggleAllTalk = false;
		if( g_bToggleAllTalk )
		{
			new Flags = GetConVarFlags(g_hAllTalk);
			SetConVarFlags(g_hAllTalk, (Flags & ~FCVAR_NOTIFY)); 
			SetConVarInt(g_hAllTalk, 1);
			SetConVarFlags(g_hAllTalk, Flags); 
			PrintToChatAll( "\x04[Pause] \x01Alltalk has been \x04Enabled" );
		}
	}
}

stock AllTalkOff()
{
	if( GetConVarBool( g_hPauseAllTalk ) )
	{
		if( g_bToggleAllTalk )
		{
			new Flags = GetConVarFlags(g_hAllTalk);
			SetConVarFlags(g_hAllTalk, (Flags & ~FCVAR_NOTIFY)); 
			SetConVarInt(g_hAllTalk, 0);
			SetConVarFlags(g_hAllTalk, Flags); 
			PrintToChatAll( "\x04[Pause] \x01Alltalk has been \x04Disabled" );
		}
	}
}

ExecuteCheatCommand(const String:sCmdName[], const String:sValue[]="")
{
	new iFlags = GetCommandFlags(sCmdName);
	if( iFlags & FCVAR_CHEAT )
	{
			SetCommandFlags(sCmdName, iFlags &~ FCVAR_CHEAT); // Remove cheat flag
			ServerCommand("%s%s", sCmdName, sValue);
			SetCommandFlags(sCmdName, iFlags | FCVAR_CHEAT); // Restore cheat flag
	}
	else
	{
			ServerCommand("%s%s", sCmdName, sValue);
	}
}

public Action:SoundHook(	clients[64], 
							&numClients, 
							String:sample[PLATFORM_MAX_PATH], 
							&entity, 
							&channel, 
							&Float:volume, 
							&level, 
							&pitch, 
							&flags) 
{
	volume = 0.0;
	level = 0;
	return Plugin_Changed;
}

public Action:AmbientHook(	String:sample[PLATFORM_MAX_PATH], 
								&entity, 
								&Float:volume, 
								&level, 
								&pitch, 
								Float:pos[3], 
								&flags, 
								&Float:delay)
{
	volume = 0.0;
	level = 0;
	return Plugin_Changed;
}

PauseFreeze()
{
	AddNormalSoundHook(NormalSHook:SoundHook);
	AddAmbientSoundHook(AmbientSHook:AmbientHook);
			
	SetConVarInt(g_hSbStop, 1);
	SetConVarInt(g_hNbStop, 1);
	ExecuteCheatCommand("director_stop");
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) )
		{
			SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
			SetEntityMoveType(i, MOVETYPE_NONE);
			g_iFlags[i] = GetEntProp(i, Prop_Send, "m_fFlags");
			SetEntProp(i, Prop_Send, "m_fFlags", 161);
		}
	}
}

PauseUnfreeze()
{
	RemoveNormalSoundHook(NormalSHook:SoundHook);
	RemoveAmbientSoundHook(AmbientSHook:AmbientHook);
	ExecuteCheatCommand("sv_soundemitter_flush");

	SetConVarInt(g_hSbStop, 0);
	SetConVarInt(g_hNbStop, 0);
	ExecuteCheatCommand("director_start");
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) )
		{
			SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
			SetEntityMoveType(i, MOVETYPE_WALK);
			SetEntProp(i, Prop_Send, "m_fFlags", g_iFlags[i]);
		}
	}
}

stock TurnRadioOn()
{
	if( GetConVarBool(g_hRadioEnabled) )
	{
		decl String:RadioURL[192];
		GetConVarString( g_hRadioURL, RadioURL, 192 );
		for( new client = 1; client < GetClientCount(false); client++ )
		{
			if( !IsFakeClient(client) )
			{
				PlayMOTDMusic( client, RadioURL );
				PrintToChat( client, "\x04[Pause] \x01Turning the radio on whilst you wait..." );
			}
		}
	}
}

stock TurnRadioOff()
{
	if( GetConVarBool(g_hRadioEnabled) )
	{
		for( new client = 1; client < GetClientCount(false); client++ )
		{
			if( !IsFakeClient(client) )
			{
				StopMOTDMusic( client );
			}
		}
	}
}

stock UnPauseGame()
{
	new client = GetValidClient();
	g_bAllowPause = true;
	SetConVarInt(g_hSvPausable, 1); 
	FakeClientCommand( client, "unpause" );
	SetConVarInt(g_hSvPausable, 0);
	g_bAllowPause = false;
	g_bIsPause = false;
}

stock PauseGame()
{
	ExecuteCheatCommand("soundscape_flush");
	
	new client = GetValidClient();
	g_bAllowPause = true;
	SetConVarInt(g_hSvPausable, 1); 
	FakeClientCommand( client, "setpause" );
	SetConVarInt(g_hSvPausable, 0);
	g_bAllowPause = false;
	g_bIsPause = true;
}

public PauseVoteHandler(Handle:menu, MenuAction:action, client, choice)
{
	if (action == MenuAction_Select)
	{
		if(choice == 1) //yes
		{
			g_iVoters--;
		}
		else //No
		{
			g_iNoCount++;
			g_iYesCount--;
			g_iVoters--;
		}
		if( g_iVoters == 0 ) //Everyone Has Voted
		{
			g_bAllVoted = true;
			if( g_iYesCount >= g_iNoCount )
			{
				PrintToChatAll( "\x04[Pause] \x01'Yes' was voted on pausing" );
				TurnRadioOn();
				ChatFloodOff();
				AllTalkOn();
				PauseFreeze();
				CreateTimer( 0.5, Timer_PauseGame );
			} else {
				PrintToChatAll( "\x04[Pause] \x01'No' was voted on pausing" );
			}
		}
	}
}

public UnPauseVoteHandler(Handle:menu, MenuAction:action, client, choice)
{
	if (action == MenuAction_Select)
	{
		if(choice == 1) //yes
		{
			g_iNoCount--;
			g_iYesCount++;
			g_iVoters--;
		}
		else //No
		{
			g_iVoters--;
		}
		if( g_iVoters == 0 ) //Everyone Has Voted
		{
			g_bAllVoted = true;
			if( g_iYesCount >= g_iNoCount )
			{
				PrintToChatAll( "\x04[Pause] \x01'Yes' was voted on unpausing" );
				PrintToChatAll( "\x04[Pause] \x01The game will continue in..." );
				TurnRadioOff();
				CreateTimer( 1.0, Timer_UnPauseGame, 5 );
			} else {
				PrintToChatAll( "\x04[Pause] \x01'No' was voted on unpausing" );
			}
		}
	}
}

public Action:Timer_VoteCheckPause(Handle:timer)
{
	if(!g_bAllVoted && !g_bIsPause)
	{
		g_bAllVoted = true;
		if( g_iYesCount >= g_iNoCount )
		{
			PrintToChatAll( "\x04[Pause] \x01'Yes' was voted on pausing" );
			TurnRadioOn();
			ChatFloodOff();
			AllTalkOn();	
			PauseFreeze();
			CreateTimer( 1.0, Timer_PauseGame );
		} else {
			PrintToChatAll( "\x04[Pause] \x01'No' was voted on pausing" );
		}
	}
}

public Action:Timer_VoteCheckUnpause(Handle:timer)
{
	if(!g_bAllVoted && g_bIsPause)
	{
		g_bAllVoted = true;
		if( g_iYesCount >= g_iNoCount )
		{
			PrintToChatAll( "\x04[Pause] \x01'Yes' was voted on unpausing" );
			PrintToChatAll( "\x04[Pause] \x01The game will continue in..." );
			TurnRadioOff();
			CreateTimer( 1.0, Timer_UnPauseGame, 5 );
		} else {
			PrintToChatAll( "\x04[Pause] \x01'No' was voted on unpausing" );
		}
	}
}

public Action:Timer_PauseGame(Handle:timer)
{
	PauseGame();
}

public Action:Timer_UnPauseGame(Handle:timer, any:time)
{
	if( time != 0 )
	{
		PrintToChatAll( "%d", time );
		CreateTimer( 1.0, Timer_UnPauseGame, --time );
	} 
	else
	{
		PrintToChatAll( "Game is live, Good Luck!" );
		UnPauseGame();
		ChatFloodOn();
		AllTalkOff();
		CreateTimer(1.0, tmrUnfreeze);
	}
}

public Action:tmrUnfreeze(Handle:timer)
	PauseUnfreeze();

public Action:Command_SMUnpause(client, args)
{
	if( g_bAdminPause )
	{
		PrintToChat( client, "\x04[Pause] \x01The game was paused by an admin, Only an admin may unpause" );
		return Plugin_Handled;
	}
	if( !g_bIsPause )
	{
		PrintToChat( client, "\x04[Pause] \x01The game isn't paused, use '!pause' to vote for the pausing of the game." );
		return Plugin_Handled;
	}
	if( GetConVarBool( g_hForcePauseOnly ) )
	{
		PrintToChat( client, "\x04[Pause] \x01Only admins can unpause the game, using !forceunpause" );
		return Plugin_Handled;
	}

	new Handle:panel = CreatePanel();
	SetPanelTitle( panel, "Unpause the Game?" );
	DrawPanelItem( panel, "Yes" );
	DrawPanelItem( panel, "No" );
	
	g_iYesCount = 0;
	g_iNoCount = 0;
	g_iVoters = 0;
	g_bAllVoted = false;
 
	UnPauseGame();
	for( new x = 1; x <= 16; x++ )
	{
		if( IsClientInGame( x ) && !IsFakeClient( x ) )
		{
			SendPanelToClient( panel, x, UnPauseVoteHandler, GetConVarInt( g_hTimout ) );
			g_iVoters++;
			g_iNoCount++;
		}
	}
	CreateTimer( 0.5, Timer_PauseGame );
	
	CreateTimer( GetConVarFloat( g_hTimout ) + 1.0, Timer_VoteCheckUnpause );
 
	CloseHandle(panel);
	return Plugin_Handled;
}

public Action:Command_SMPause(client, args)
{
	decl String:sReason[128];
	GetCmdArgString( sReason, 128 );
	
	if( g_bIsPause )
	{
		PrintToChat( client, "\x04[Pause] \x01The game is already paused, use '!unpause' to vote for the unpausing of the game." );
		return Plugin_Handled;
	}
	if( GetConVarBool( g_hForcePauseOnly ) )
	{
		PrintToChat( client, "\x04[Pause] \x01Only admins can pause the game, using !forcepause" );
		return Plugin_Handled;
	}
	
	if( strlen( sReason ) != 0 )	
		PrintToChatAll( "\x04[Pause] \x01%N wants to pause the game, because they %s", client, sReason );
	else
		PrintToChatAll( "\x04[Pause] \x01%N wants to pause the game", client );

	new Handle:panel = CreatePanel();
	SetPanelTitle( panel, "Pause the Game?" );
	DrawPanelItem( panel, "Yes" );
	DrawPanelItem( panel, "No" );
	
	g_iYesCount = 0;
	g_iNoCount = 0;
	g_iVoters = 0;
	g_bAllVoted = false;
 
	for( new x = 1; x <= 16; x++ )
	{
		if( IsClientInGame( x ) && !IsFakeClient( x ) )
		{
			SendPanelToClient( panel, x, PauseVoteHandler, GetConVarInt( g_hTimout ) );
			g_iVoters++;
			g_iYesCount++;
		}
	}
 
	CreateTimer( GetConVarFloat( g_hTimout ) + 1.0, Timer_VoteCheckPause );
 
	CloseHandle(panel);
	return Plugin_Handled;
}

public Action:Timer_HideMOTD(Handle:timer, any:client)
{
	new Handle:setup = CreateKeyValues("data");
	KvSetString(setup, "title", "GAME IS PAUSED");
	KvSetNum(setup, "type", MOTDPANEL_TYPE_URL);
	KvSetString(setup, "msg", g_CurrentURL);
	ShowVGUIPanel(client, "info", setup, false);
	CloseHandle(setup);	
}

public PlayMOTDMusic(client, String:url[192])
{
	Format( g_CurrentURL, 192, "%s", url );
	CreateTimer( 1.0, Timer_HideMOTD, client );
	
	decl String:LoadingURL[192];
	GetConVarString(g_hRadioLoadingURL, LoadingURL, 192);
	
	new Handle:setup = CreateKeyValues("data");
	KvSetString(setup, "title", "GAME IS PAUSED");
	KvSetNum(setup, "type", MOTDPANEL_TYPE_URL);
	KvSetString(setup, "msg", LoadingURL);
	ShowVGUIPanel(client, "info", setup, true);
	CloseHandle(setup);	
}

public StopMOTDMusic(client)
{
	new Handle:setup = CreateKeyValues("data");
	KvSetString(setup, "title", "GAME IS PAUSED");
	KvSetNum(setup, "type", MOTDPANEL_TYPE_URL);
	KvSetString(setup, "msg", "www.google.com");
	ShowVGUIPanel(client, "info", setup, false);
	CloseHandle(setup);	
}

public Action:Command_SMRadio(client, args)
{
	if( !GetConVarBool(g_hRadioEnabled) ) return Plugin_Handled;
	if( !g_bIsPause ) return Plugin_Handled;
	
	decl String:RadioURL[192];
	GetConVarString( g_hRadioURL, RadioURL, 192 );
	PlayMOTDMusic( client, RadioURL );
	PrintToChat( client, "\x04[Pause] \x01Turning the radio on whilst you wait..." );
		
	return Plugin_Handled;
}

public Action:Command_SMRadioOff(client, args)
{
	if( !GetConVarBool(g_hRadioEnabled) ) return Plugin_Handled;
	if( !g_bIsPause ) return Plugin_Handled;

	StopMOTDMusic( client );
	PrintToChat( client, "\x04[Pause] \x01Turning the radio off..." );
	
	return Plugin_Handled;
}

public Action:Command_SMForceUnpause(client, args)
{
	if( !g_bIsPause )
	{
		if( client != 0 )PrintToChat( client, "\x04[Pause] \x01The game isn't paused, use !forcepause to pause the game" );
		return Plugin_Handled;
	}
	PrintToChatAll( "\x04[Pause] \x01An admin has unpaused the game" );
	PrintToChatAll( "\x04[Pause] \x01The game will continue in..." );
	TurnRadioOff();
	CreateTimer( 1.0, Timer_UnPauseGame, 5 );	
	g_bAdminPause = false;
	return Plugin_Handled;
}

public Action:Command_SMForcePause(client, args)
{
	if( g_bIsPause )
	{
		if( client != 0 )PrintToChat( client, "\x04[Pause] \x01The game is already paused, use !forceunpause to unpause the game" );
		return Plugin_Handled;
	}
	PrintToChatAll( "\x04[Pause] \x01An admin has paused the game" );
	g_bAdminPause = true;
	TurnRadioOn();
	ChatFloodOff();
	AllTalkOn();
	PauseFreeze();
	CreateTimer( 1.0, Timer_PauseGame );
	return Plugin_Handled;
}

public OnClientDisconnect(client)
{
    if (g_bIsPause && !IsFakeClient(client))
    {
        UnPauseGame();
        CreateTimer(1.0, Timer_PauseGame);
    }
}

public OnClientPutInServer(client)
{
    if (g_bIsPause && !IsFakeClient(client))
    {
		PrintToChatAll( "\x04[Pause] \x01 %N is joining the game", client );
		UnPauseGame();
		CreateTimer(1.0, Timer_PauseGame);
	}
}

public OnClientConnected(client)
{
    if (g_bIsPause && !IsFakeClient(client))
    {
        UnPauseGame();
        CreateTimer(1.0, Timer_PauseGame);
    }
}

public Action:Event_PlayerChangeTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (g_bIsPause)
    {
        UnPauseGame();
        CreateTimer(1.0, Timer_PauseGame);
    }
}

public Action:Command_Real_Pause(client, const String:command[], argc) 
{
	if( g_bAllowPause )return Plugin_Continue;
	return Plugin_Handled;
}