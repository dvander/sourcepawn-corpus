/*
KillStats.sp

Description:
	Shows damage and kills done this round to and by player upon death

Versions:
	1.0
		* Initial Release

Author:
	Deception5 - thanks to Dalto/AMP
*/


#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0"
#define MAX_CLIENTS 64

#define MAX_LINE_WIDTH 128
#define MAX_MENU_ROWS 24

#define NEWLINE " "

/*****************************************************
					Translations
*****************************************************/

// cvars
#define CVAR_ENABLED "sm_killstats_enable"
#define CVAR_ENABLED_BY_DEFAULT "sm_killstats_enabled_by_default"
#define CVAR_VERSION "sm_killstats_version"
#define CVAR_DEATH "sm_killstats_death_time"
#define CVAR_VIEW "sm_killstats_view_time"
#define CVAR_ROUND_END "sm_killstats_round_end_time"

// console commands
#define CONSOLE_KILLSTATS "console_killstats"
#define CONSOLE_KILLSTATS_OPTIONS "console_killstats_options"

// console instructions
#define KILLSTATS_DISPLAY "killstats_display"
#define KILLSTATS_OPTIONS_DISPLAY "killstats_options_display"

// killstats screen
#define KILLSTATS "killstats"
#define PLAYERS_KILLED "players_killed"
#define KILLED_BY "killed_by"
#define DAMAGE_DONE "damage_done"
#define DAMAGE_TAKEN "damage_taken"
#define EXIT "exit"
#define NONE "none"

// killstats options screen
#define KILLSTATS_OPTIONS "killstats_options"
#define ENABLE "enable"
#define DISABLE "disable"
#define VIEW "view"

// damage strings
#define DAMAGE_MULTI_HEADSHOTS "damage_multi_headshots"
#define DAMAGE_ONE_HEADSHOT "damage_one_headshot"
#define DAMAGE_NO_HEADSHOTS "damage_no_headshots"

/*****************************************************
					End Translations
*****************************************************/

// Plugin definitions
public Plugin:myinfo = 
{
	name = "KillStats",
	author = "Deception5",
	description = "Kill Stats",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

// Whether the client would like to display kill stats or not
new StatPreference[MAX_CLIENTS+1];

// Stores the amount of damage done by each player to each player
new Damage[MAX_CLIENTS+1][MAX_CLIENTS+1];
// Stores number of headshots done to each player 
new HeadShots[MAX_CLIENTS+1][MAX_CLIENTS+1];
// Stores number of times each player has been hit by each player
new Hits[MAX_CLIENTS+1][MAX_CLIENTS+1];
// Stores who killed who
new Kills[MAX_CLIENTS+1][MAX_CLIENTS+1];

// Used for isAlive
new iLifeState = -1;

// cvars for panel timer display
new defaultEnableValue;
new deathTime;
new roundEndTime;
new viewTime;

public OnPluginStart()
{
	LoadTranslations("killstats.phrases");

	// This buffer will be used for all of the cvars/console commands as a temporary storage space for translations
	decl String:translationBuffer[MAX_LINE_WIDTH];
	
	// Set up enabled cvar	
	new Handle:cvarEnabled=INVALID_HANDLE;
	Format(translationBuffer, MAX_LINE_WIDTH, "%T", CVAR_ENABLED, LANG_SERVER);
	cvarEnabled = CreateConVar(CVAR_ENABLED, "1", translationBuffer);
	if(!GetConVarBool(cvarEnabled))
	{
		SetFailState("Plugin Disabled");
	}
	
	// Specify whether players see killstats by default or whether they have to enable them to see
	new Handle:cvarEnabledByDefault=INVALID_HANDLE;
	Format(translationBuffer, MAX_LINE_WIDTH, "%T", CVAR_ENABLED_BY_DEFAULT, LANG_SERVER);
	cvarEnabledByDefault = CreateConVar(CVAR_ENABLED_BY_DEFAULT, "1", translationBuffer);
	defaultEnableValue = GetConVarInt(cvarEnabledByDefault);
	
	// Set up version cvar
	Format(translationBuffer, MAX_LINE_WIDTH, "%T", CVAR_VERSION, LANG_SERVER);
	CreateConVar(CVAR_VERSION, PLUGIN_VERSION, translationBuffer, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	// Set up death time cvar
	new Handle:cvarDeathTime=INVALID_HANDLE;
	Format(translationBuffer, MAX_LINE_WIDTH, "%T", CVAR_DEATH, LANG_SERVER);
	cvarDeathTime = CreateConVar(CVAR_DEATH, "20", translationBuffer);
	deathTime = GetConVarInt(cvarDeathTime);
	
	// Set up round end time cvar
	new Handle:cvarRoundEndTime=INVALID_HANDLE;
	Format(translationBuffer, MAX_LINE_WIDTH, "%T", CVAR_ROUND_END, LANG_SERVER);
	cvarRoundEndTime = CreateConVar(CVAR_ROUND_END, "12", translationBuffer);
	roundEndTime = GetConVarInt(cvarRoundEndTime);
	
	// Set up view time cvar
	new Handle:cvarViewTime=INVALID_HANDLE;
	Format(translationBuffer, MAX_LINE_WIDTH, "%T", CVAR_VIEW, LANG_SERVER);
	cvarViewTime = CreateConVar(CVAR_VIEW, "20", translationBuffer);
	viewTime = GetConVarInt(cvarViewTime);

	iLifeState = FindSendPropOffs("CBasePlayer", "m_lifeState");

	// PostNoCopy can be used here for efficiency because none of the params to round_start are used
	HookEvent("round_start", EventRoundStart,EventHookMode_PostNoCopy);
	HookEvent("player_death", EventPlayerDeath);
	HookEvent("player_hurt", EventPlayerHurt);
	HookEvent("round_end", EventRoundEnd);
	
	Format(translationBuffer, MAX_LINE_WIDTH, "%T", CONSOLE_KILLSTATS_OPTIONS, LANG_SERVER);
	RegConsoleCmd(translationBuffer, PanelKillStatsOptions);
	
	Format(translationBuffer, MAX_LINE_WIDTH, "%T", CONSOLE_KILLSTATS, LANG_SERVER);
	RegConsoleCmd(translationBuffer, PanelKillStats);
	
	// Default to ON
	for(new i=0;i<=MAX_CLIENTS;i++)
	{
		StatPreference[i]=1;
	}
}

/****************************************************

				Events

*****************************************************/
public EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Reset PlayerDamage 
	for (new i=0; i<=MAX_CLIENTS; i++)
	{
		for (new j=0; j<=MAX_CLIENTS; j++)
		{
			Damage[i][j]=0;
			HeadShots[i][j]=0;
			Kills[i][j]=0;
			Hits[i][j]=0;
		}
	}
}

public EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new reasonId = GetEventInt(event,"reason");
	
	// If this is the end of the practice round, don't do this!
	if ( reasonId != 16 ) 
	{
		for (new player=1; player<=GetMaxClients(); player++)
		{
			if ( StatPreference[player] && IsClientInGame(player) && IsAlive(player) )
			{
				DisplayPlayerRoundStats(player,roundEndTime);
			}
		}
	}
}

// The hit event
public EventPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victimId = GetEventInt(event, "userid");
	new attackerId = GetEventInt(event, "attacker");
	new damage = GetEventInt(event,"dmg_health");
	new hitgroup = GetEventInt(event,"hitgroup");

	new victim = GetClientOfUserId(victimId);
	new attacker = GetClientOfUserId(attackerId);

	// Make sure attacker is valid (not world damage, self damage, etc)
	if ( ( attacker > 0 ) && ( attacker <= MAX_CLIENTS ) && ( victim != attacker ) )
	{
		// Store damage, number of hits, and number of headshots for later
		Damage[attacker][victim]+=damage;
		Hits[attacker][victim]++;
	
		if ( hitgroup == 1 )
		{
			HeadShots[attacker][victim]++;
		}
	}
}

// The death event
public EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victimId = GetEventInt(event, "userid");
	new attackerId = GetEventInt(event, "attacker");

	new victim = GetClientOfUserId(victimId);
	new attacker = GetClientOfUserId(attackerId);

	// Give the attacker credit for killing me
	if ( ( attacker > 0 ) && ( attacker <= MAX_CLIENTS ) && ( victim != attacker ) )
	{
		Kills[attacker][victim]++;
	
		if ( StatPreference[victim] && !IsFakeClient(victim) )
		{
			DisplayPlayerRoundStats(victim,deathTime);
		}
	}
}

/****************************************************

				Utility Functions

*****************************************************/

// When a new client is authorized we reset stats preferences
// and let them know how to turn the stats on and off
public OnClientAuthorized(client, const String:auth[])
{
	if ( ( client > 0 ) && ( client <= MAX_CLIENTS ) ) 
	{
		StatPreference[client] = defaultEnableValue;
		
		for ( new i=0; i<= MAX_CLIENTS ; i++ )
		{
			// Wipe any damage / stats from this round done by former client
			Damage[client][i]=0;
			HeadShots[client][i]=0;
			Kills[client][i]=0;
			Hits[client][i]=0;
			
			// Wipe any damage done to former client
			Damage[i][client]=0;
			HeadShots[i][client]=0;
			Kills[i][client]=0;
			Hits[i][client]=0;
		}
		
		CreateTimer(30.0, TimerAnnounce, client);
	}
}

// This function was stolen from ferret's teambet plugin
public bool:IsAlive(client)
{
    if (iLifeState != -1 && GetEntData(client, iLifeState, 1) == 0)
        return true;
 
    return false;
}

public Action:TimerAnnounce(Handle:timer, any:client)
{
	decl String:translationBuffer[MAX_LINE_WIDTH];
	decl String:translationConsoleCmd[MAX_LINE_WIDTH];	
	
	if ( IsClientInGame(client) )
	{
		// We have double translations here to translate the string used by the translation string since it translates the command referenced
		Format(translationConsoleCmd,MAX_LINE_WIDTH,"%T",CONSOLE_KILLSTATS,client);
		Format(translationBuffer,MAX_LINE_WIDTH,"%T",KILLSTATS_DISPLAY,client,translationConsoleCmd);
		PrintToChat(client, translationBuffer);
		
		Format(translationConsoleCmd,MAX_LINE_WIDTH,"%T",CONSOLE_KILLSTATS_OPTIONS,client);
		Format(translationBuffer,MAX_LINE_WIDTH,"%T",KILLSTATS_OPTIONS_DISPLAY,client,translationConsoleCmd);
		PrintToChat(client, translationBuffer);
	}
}

public CreateDamageString( client, String:strdamage[], maxlength, String:strname[], damage, hits, headshots )
{
	// Multiple headshots on target
	if ( headshots > 1 )
	{
		Format(
			strdamage, 
			maxlength, 
			"  %T",
			DAMAGE_MULTI_HEADSHOTS,
			client,
			strname,
			damage,
			hits,
			headshots
			);
	}

	// Single headshot on target
	else if ( headshots == 1 )
	{
		Format(
			strdamage, 
			maxlength, 
			"  %T",
			DAMAGE_ONE_HEADSHOT,
			client,
			strname,
			damage,
			hits
			);
	}
	// Damage Only
	else
	{
		Format(
			strdamage, 
			maxlength, 
			"  %T",
			DAMAGE_NO_HEADSHOTS,
			client,
			strname,
			damage, 
			hits
			);
	}
}								

// The comparison function used in the sort routine to show max damage first
// Use to sort an array of strings by damage descending
public SortDamageDesc(row1[], row2[], const array[][], Handle:hndl)
{
    if(row1[1] > row2[1])
    {
		return -1;
	}
    else if(row1[1] == row2[1])
	{
		return 0;
	}
    else
	{
    	return 1;
    }
}

/****************************************************

				Display Panels

*****************************************************/

//  This sets enables or disables the automatic popup
public PanelHandlerKillStatsOptions(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		switch ( param2 )
		{
			// Enable
			case 1:
				StatPreference[param1] = 1;
				//break;
				
			// Disable
			case 2:
				StatPreference[param1] = 0;
				//break;

			// View
			case 3:
				DisplayPlayerRoundStats(param1,deathTime);
				//break;
		}
	}
	else if (action == MenuAction_Cancel)
	{
		// Ignore
	}
}
 
//  This creates the kill stats options panel
public Action:PanelKillStatsOptions(client, args)
{
	decl String:translationBuffer[MAX_LINE_WIDTH];

	new Handle:panel = CreatePanel();
	
	Format(translationBuffer,MAX_LINE_WIDTH,"%T",KILLSTATS_OPTIONS,client);
	SetPanelTitle(panel, translationBuffer );
	
	Format(translationBuffer,MAX_LINE_WIDTH,"%T",ENABLE,client);
	DrawPanelItem(panel, translationBuffer);

	Format(translationBuffer,MAX_LINE_WIDTH,"%T",DISABLE,client);
	DrawPanelItem(panel, translationBuffer);

	Format(translationBuffer,MAX_LINE_WIDTH,"%T",VIEW,client);
	DrawPanelItem(panel, translationBuffer);

	Format(translationBuffer,MAX_LINE_WIDTH,"%T",EXIT,client);
	DrawPanelItem(panel, translationBuffer);
		
	SendPanelToClient(panel, client, PanelHandlerKillStatsOptions, viewTime );
 
	CloseHandle(panel);
 
	return Plugin_Handled;
}

public PanelHandlerKillStats(Handle:menu, MenuAction:action, param1, param2)
{
	// No matter what is selected, let it pass through so they exit the menu
}

// This displays the kill stats panel
public Action:PanelKillStats(client, args)
{
	DisplayPlayerRoundStats(client,viewTime);
 
	return Plugin_Handled;
}

public DisplayPlayerRoundStats(player,displayTime)
{
	decl String:translationBuffer[MAX_LINE_WIDTH];

	if ( IsClientInGame(player) )
	{
		decl String:strname[MAX_LINE_WIDTH];
		decl String:strkill[MAX_LINE_WIDTH];
		new Handle:panel = CreatePanel();
	
		// Kill Stat Panel
		Format(translationBuffer,MAX_LINE_WIDTH,"%T",KILLSTATS,player);
		SetPanelTitle(panel, translationBuffer );
		
		// 1 - Kills
		DrawPanelText(panel, NEWLINE);
		Format(translationBuffer,MAX_LINE_WIDTH,"%T",PLAYERS_KILLED,player);
		DrawPanelItem(panel, translationBuffer);
		
		new kills = 0;
	
		for (new i=0; i<=MAX_CLIENTS; i++)
		{
			if ( Kills[player][i] > 0 )
			{
				GetClientName(i, strname, sizeof(strname));
				Format(strkill,MAX_LINE_WIDTH,"  %s",strname);
				DrawPanelText(panel, strkill);
				kills=1;
			}
		}
		
		if ( kills == 0 )
		{
			Format(translationBuffer,MAX_LINE_WIDTH,"  %T",NONE,player);
			DrawPanelText(panel,translationBuffer);
		}
	
		// 2 - Deaths
		DrawPanelText(panel, NEWLINE);
		Format(translationBuffer,MAX_LINE_WIDTH,"%T",KILLED_BY,player);
		DrawPanelItem(panel, translationBuffer);
		new killed = 0;
		for (new i=0; i<=MAX_CLIENTS; i++)
	   	{
			if ( Kills[i][player] > 0 )
			{
				GetClientName(i, strname, sizeof(strname));
				Format(strkill,MAX_LINE_WIDTH,"  %s",strname);
				DrawPanelText(panel, strkill);
				killed = 1;
				break;
			}
		}
		
		if ( !killed )
		{
			Format(translationBuffer,MAX_LINE_WIDTH,"  %T",NONE,player);
			DrawPanelText(panel,translationBuffer);
		}
		
		// Move damage to temp arrays so they can be sorted
		decl String:DamageDoneStrings[MAX_CLIENTS+1][MAX_LINE_WIDTH];
		decl String:DamageTakenStrings[MAX_CLIENTS+1][MAX_LINE_WIDTH];
		
		// Array of Amounts of damage done.  0 is client id, 1 is damage
		new DamageDone[MAX_CLIENTS+1][2];
		new DamageTaken[MAX_CLIENTS+1][2];
		
		//decl String:strhits[MAX_LINE_WIDTH];
		
		// Whether any damage was dealt by this player this round - otherwise we will display "None"
		new damageDoneFlag = 0;

		// 3 - Damage Done
		DrawPanelText(panel, NEWLINE);
		Format(translationBuffer,MAX_LINE_WIDTH,"%T",DAMAGE_DONE,player);
		DrawPanelItem(panel, translationBuffer);
		
		for (new i=0; i<=MAX_CLIENTS; i++)
		{
			if ( Damage[player][i] > 0 )
			{
				// Name of target 
				GetClientName(i, strname, sizeof(strname));
				
				CreateDamageString( player, DamageDoneStrings[i], MAX_LINE_WIDTH, strname, Damage[player][i], Hits[player][i], HeadShots[player][i] );
	
				damageDoneFlag=1;
			}

			DamageDone[i][0] = i;
			DamageDone[i][1] = Damage[player][i];
		}
	
		if ( damageDoneFlag )
		{
			SortCustom2D(DamageDone, MAX_CLIENTS+1, SortDamageDesc);

			for ( new i=0 ; i<=MAX_CLIENTS && DamageDone[i][1] > 0 ; i++ )
			{
				DrawPanelText(panel,DamageDoneStrings[DamageDone[i][0]]);
			}
		}
		else
		{
			Format(translationBuffer,MAX_LINE_WIDTH,"  %T",NONE,player);
			DrawPanelText(panel,translationBuffer);
		}
		
		// 4 - Damage Taken
		DrawPanelText(panel, NEWLINE);
		Format(translationBuffer,MAX_LINE_WIDTH,"%T",DAMAGE_TAKEN,player);
		DrawPanelItem(panel, translationBuffer);
		new damageTakenFlag = 0;
		for (new i=0; i<=MAX_CLIENTS; i++)
		{
			if ( Damage[i][player] > 0 )
			{
				// Name of attacker 
				GetClientName(i, strname, sizeof(strname));
				CreateDamageString( player, DamageTakenStrings[i], MAX_LINE_WIDTH, strname, Damage[i][player], Hits[i][player], HeadShots[i][player] );
	
				damageTakenFlag=1;
			}

			DamageTaken[i][0] = i;
			DamageTaken[i][1] = Damage[i][player];
		}
		
		if ( damageTakenFlag )
		{
			SortCustom2D(DamageTaken, MAX_CLIENTS+1, SortDamageDesc);
	
			for ( new i=0 ; i<=MAX_CLIENTS && DamageTaken[i][1] > 0 ; i++ )
			{
				DrawPanelText(panel,DamageTakenStrings[DamageTaken[i][0]]);
			}
		}
		else
		{
			Format(translationBuffer,MAX_LINE_WIDTH,"  %T",NONE,player);
			DrawPanelText(panel,translationBuffer);
		}
	
		DrawPanelText(panel, NEWLINE);
		Format(translationBuffer,MAX_LINE_WIDTH,"%T",EXIT,player);
		DrawPanelItem(panel, translationBuffer);

		SendPanelToClient(panel, player, PanelHandlerKillStats, displayTime);
	
		CloseHandle(panel);
	}
}
