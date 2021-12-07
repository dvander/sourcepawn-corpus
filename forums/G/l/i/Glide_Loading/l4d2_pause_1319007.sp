#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <colors>

#define VERSION "1.0.0"

new g_iYesCount = 0;
new g_iNoCount = 0;
new g_iVoters = 0;

new bool:g_bIsPause = false;
new bool:g_bAdminPause = false;
new bool:g_bAllowPause = false;
new bool:g_bAllVoted = false;
new bool:g_bToggleAllTalk = true;

new Handle:g_hTimout;
new Handle:g_hForcePauseOnly;
new Handle:g_hPauseAllTalk;

public Plugin:myinfo =
{
	name = "[L4D2] Pause",
	author = "N3wton",
	description = "Pauses the game",
	version = VERSION
};

public OnPluginStart()
{
	g_hTimout = CreateConVar( "l4d2_pause_request_timout", "10.0", "How long the pause request should be visable", FCVAR_PLUGIN, true, 5.0, true, 30.0 );
	g_hForcePauseOnly = CreateConVar( "l4d2_pause_force_only", "0", "Only allow force pauses", FCVAR_PLUGIN );
	g_hPauseAllTalk = CreateConVar( "l4d2_pause_alltalk", "1", "Turns Alltalk on when paused", FCVAR_PLUGIN );
	AutoExecConfig( true, "[L4D2]Pause" );

	SetConVarBool( FindConVar("sv_pausable"), false );
	
	RegConsoleCmd( "sm_pause", Command_SMPause, "Pauses the game" );
	RegConsoleCmd( "sm_unpause", Command_SMUnpause, "Unpauses the game" );
	RegAdminCmd( "sm_forcepause", Command_AdmForcePause, ADMFLAG_KICK, "Forces the game to pause" );
	
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
		
		if( GetClientTeam(client) == 2 ) CPrintToChatAll("{blue}%N :{default} %s", client, sText);
		if( GetClientTeam(client) == 3 ) CPrintToChatAll("{red}%N :{default} %s", client, sText);
		if( GetClientTeam(client) != 2 && GetClientTeam(client) != 3 ) CPrintToChatAll("%N : %s", client, sText);
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
		
		for( new i = 1; i < MaxClients; i++ )
		{
			if( IsClientInGame(i) && !IsFakeClient(i) )
			{
				if( GetClientTeam(client) == GetClientTeam(i) )
				{
					if( GetClientTeam(client) == 2 ) CPrintToChat( i, "{blue}%N :{default} %s", client, sText);
					if( GetClientTeam(client) == 3 ) CPrintToChat( i, "{red}%N :{default} %s", client, sText);
					if( GetClientTeam(client) != 2 && GetClientTeam(client) != 3 ) CPrintToChat( i, "%N : %s", client, sText);
				}
			}
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

stock GetValidClient()
{
	new client = 1;
	while( !IsClientInGame( client ) || IsFakeClient( client ) ) client++;
	return client;
}

stock ChatFloodOn()
{
	new Flags = GetConVarFlags( FindConVar("sm_flood_time") );
	SetConVarFlags( FindConVar("sm_flood_time"), (Flags & ~FCVAR_NOTIFY) );
	ResetConVar( FindConVar("sm_flood_time") );
	SetConVarFlags( FindConVar("sm_flood_time"), Flags );
}

stock ChatFloodOff()
{
	new Flags = GetConVarFlags( FindConVar("sm_flood_time") );
	SetConVarFlags( FindConVar("sm_flood_time"), (Flags & ~FCVAR_NOTIFY) );
	SetConVarFloat( FindConVar("sm_flood_time"), 0.0 );
	SetConVarFlags( FindConVar("sm_flood_time"), Flags ); 
}

stock AllTalkOn()
{
	if( GetConVarBool( g_hPauseAllTalk ) )
	{
		if( GetConVarBool(FindConVar("sv_alltalk")) ) g_bToggleAllTalk = false;
		if( g_bToggleAllTalk )
		{
			new Flags = GetConVarFlags(FindConVar("sv_alltalk"));
			SetConVarFlags(FindConVar("sv_alltalk"), (Flags & ~FCVAR_NOTIFY)); 
			SetConVarInt(FindConVar("sv_alltalk"), 1);
			SetConVarFlags(FindConVar("sv_alltalk"), Flags); 
			CPrintToChatAll( "{olive}[Pause]{default} Alltalk has been Enabled" );
		}
	}
}

stock AllTalkOff()
{
	if( GetConVarBool( g_hPauseAllTalk ) )
	{
		if( g_bToggleAllTalk )
		{
			new Flags = GetConVarFlags(FindConVar("sv_alltalk"));
			SetConVarFlags(FindConVar("sv_alltalk"), (Flags & ~FCVAR_NOTIFY)); 
			SetConVarInt(FindConVar("sv_alltalk"), 0);
			SetConVarFlags(FindConVar("sv_alltalk"), Flags); 
			CPrintToChatAll( "{olive}[Pause]{default} Alltalk has been Disabled" );
		}
	}
}

stock UnPauseGame()
{
	new client = GetValidClient();
	g_bAllowPause = true;
	SetConVarInt(FindConVar("sv_pausable"), 1); 
	FakeClientCommand( client, "unpause" );
	SetConVarInt(FindConVar("sv_pausable"), 0);
	g_bAllowPause = false;
	g_bIsPause = false;
}

stock PauseGame()
{
	new client = GetValidClient();
	g_bAllowPause = true;
	SetConVarInt(FindConVar("sv_pausable"), 1); 
	FakeClientCommand( client, "setpause" );
	SetConVarInt(FindConVar("sv_pausable"), 0);
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
				CPrintToChatAll( "{olive}[Pause]{default} 'Yes' was voted on pausing" );
				ChatFloodOff();
				AllTalkOn();
				CreateTimer( 0.5, Timer_PauseGame );
			} else {
				CPrintToChatAll( "{olive}[Pause]{default} 'No' was voted on pausing" );
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
				CPrintToChatAll( "{olive}[Pause]{default} 'Yes' was voted on unpausing" );
				CPrintToChatAll( "{olive}[Pause]{default} The game will continue in..." );
				CreateTimer( 1.0, Timer_UnPauseGame, 5 );
			} else {
				CPrintToChatAll( "{olive}[Pause]{default} 'No' was voted on unpausing" );
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
			CPrintToChatAll( "{olive}[Pause]{default} 'Yes' was voted on pausing" );
			ChatFloodOff();
			AllTalkOn();
			CreateTimer( 0.5, Timer_PauseGame );
		} else {
			CPrintToChatAll( "{olive}[Pause]{default} 'No' was voted on pausing" );
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
			CPrintToChatAll( "{olive}[Pause]{default} 'Yes' was voted on unpausing" );
			CPrintToChatAll( "{olive}[Pause]{default} The game will continue in..." );
			CreateTimer( 1.0, Timer_UnPauseGame, 5 );
		} else {
			CPrintToChatAll( "{olive}[Pause]{default} 'No' was voted on unpausing" );
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
		CPrintToChatAll( "%d", time );
		CreateTimer( 1.0, Timer_UnPauseGame, --time );
	} 
	else
	{
		CPrintToChatAll( "Game is live!" );
		UnPauseGame();
		ChatFloodOn();
		AllTalkOff();
	}
}

public Action:Command_SMUnpause(client, args)
{
	if( g_bAdminPause )
	{
		CPrintToChat( client, "{olive}[Pause]{default} The game was paused by an admin, Only an admin may unpause" );
		return;
	}
	if( !g_bIsPause )
	{
		CPrintToChat( client, "{olive}[Pause]{default} The game isn't paused, use '!pause' to vote for the pausing of the game." );
		return;
	}
	if( GetConVarBool( g_hForcePauseOnly ) )
	{
		CPrintToChat( client, "{olive}[Pause]{default} Only admins can unpause the game, using !forcepause" );
		return;
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
}

public Action:Command_SMPause(client, args)
{
	decl String:sReason[128];
	GetCmdArgString( sReason, 128 );
	
	if( g_bIsPause )
	{
		CPrintToChat( client, "{olive}[Pause]{default} The game is already paused, use '!unpause' to vote for the unpausing of the game." );
		return;
	}
	if( GetConVarBool( g_hForcePauseOnly ) )
	{
		CPrintToChat( client, "{olive}[Pause]{default} Only admins can pause the game, using !forcepause" );
		return;
	}
	
	if( strlen( sReason ) != 0 )	
		CPrintToChatAll( "{olive}[Pause]{default} %N wants to pause the game, because they %s", client, sReason );
	else
		CPrintToChatAll( "{olive}[Pause]{default} %N wants to pause the game", client );

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
}

public Action:Command_AdmForcePause(client,args)
{
	if (g_bAdminPause)
	{
		Command_SMForceUnpause(client, args);
	}
	else
	{
		Command_SMForcePause(client, args);
	}
	return Plugin_Handled;
}
Command_SMForceUnpause(client, args)
{
	if( !g_bIsPause )
	{
		if( client != 0 )CPrintToChat( client, "{olive}[Pause]{default} The game isn't paused, use !forcepause to pause the game" );
		return;
	}
	CPrintToChatAll( "{olive}[Pause]{default} An admin has unpaused the game" );
	CPrintToChatAll( "{olive}[Pause]{default} The game will continue in..." );
	CreateTimer( 1.0, Timer_UnPauseGame, 5 );	
	g_bAdminPause = false;
}

Command_SMForcePause(client, args)
{
	if( g_bIsPause )
	{
		if( client != 0 )CPrintToChat( client, "{olive}[Pause]{default} The game is already paused, use !forcepause to unpause the game" );
		return;
	}
	CPrintToChatAll( "{olive}[Pause]{default} An admin has paused the game" );
	g_bAdminPause = true;
	ChatFloodOff();
	AllTalkOn();
	CreateTimer( 1.0, Timer_PauseGame );	
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
		CPrintToChatAll( "{olive}[Pause]{default} %N is joining the game", client );
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