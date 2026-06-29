/**
* TF2 C L A S S  S P E E D
*
* Description:
*	This plugin allows you to alter the speed of different classes in TF2
*
* Notes
*	Setting a speed above 400 appears to make no effect
*
* Usage:
*	sm_csc_enabled	- Enable/Disable TF2 Class Speed, Deault = 1
*	sm_csc_adminonly	- Restricts the use to admins only, Default = 0
*	sm_csc_reset		- Resets the speeds back to their defaults
* 
* cvars
*	Use sm_cvar to check or set any of the following, rembering u can use sm_tcs_reset ro reset them back to the deafults
*
*	// Blue Team
* 	sm_csc_blue_demoman		- For the demoman
*	sm_csc_blue_engineer		- ''
*	sm_csc_blue_heavy		- ''
*	sm_csc_blue_medic		- ''
*	sm_csc_blue_pyro		- ''
*	sm_csc_blue_scout		- ''
*	sm_csc_blue_sniper		- ''
*	sm_csc_blue_soldier		- ''
*	sm_csc_blue_spy		- ''
*
*	// Red Team
* 	sm_csc_red_demoman		- For the demoman
*	sm_csc_red_engineer		- ''
*	sm_csc_red_heavy		- ''
*	sm_csc_red_medic		- ''
*	sm_csc_red_pyro		- ''
*	sm_csc_red_scout		- ''
*	sm_csc_red_sniper		- ''
*	sm_csc_red_soldier		- ''
*	sm_csc_red_spy		- ''
*
* Thanks to:
* 	Tsunami for my n00b questions
*	
* Based upon:
*	-
*  
* Last Update
* 	08 July 2009
*
* Known ToDos
*	Timers for Spy, Heavies and Sniper to set their speed as it can alter as there is no wepaon switch event to nab
*
*
* Version History
* 	1.0 - After a few attempts :-P
*	2.0 - Added ability to change per team speeds, altered cvars and handles to a better naming standard
* 	
*/

/**	// Admin Flags can be used

	ADMFLAG_RESERVATION
	ADMFLAG_GENERIC
	ADMFLAG_KICK
	ADMFLAG_BAN
	ADMFLAG_UNBAN
	ADMFLAG_SLAY
	ADMFLAG_CHANGEMAP
	ADMFLAG_CONVARS
	ADMFLAG_CONFIG
	ADMFLAG_CHAT
	ADMFLAG_VOTE
	ADMFLAG_PASSWORD
	ADMFLAG_RCON
	ADMFLAG_CHEATS
	ADMFLAG_ROOT
	ADMFLAG_CUSTOM1
	ADMFLAG_CUSTOM2
	ADMFLAG_CUSTOM3
	ADMFLAG_CUSTOM4
	ADMFLAG_CUSTOM5
	ADMFLAG_CUSTOM6
*/

#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#define PLUGIN_VERSION  	"2.0"

//Handles
new Handle:CSC_RED_DemoMan		= INVALID_HANDLE;
new Handle:CSC_RED_Engineer 	= INVALID_HANDLE;
new Handle:CSC_RED_Heavy 		= INVALID_HANDLE;
new Handle:CSC_RED_Medic 		= INVALID_HANDLE;
new Handle:CSC_RED_Pyro 		= INVALID_HANDLE;
new Handle:CSC_RED_Scout 		= INVALID_HANDLE;
new Handle:CSC_RED_Sniper		= INVALID_HANDLE;
new Handle:CSC_RED_Soldier 		= INVALID_HANDLE;
new Handle:CSC_RED_Spy 		= INVALID_HANDLE;

new Handle:CSC_BLUE_DemoMan		= INVALID_HANDLE;
new Handle:CSC_BLUE_Engineer 	= INVALID_HANDLE;
new Handle:CSC_BLUE_Heavy 		= INVALID_HANDLE;
new Handle:CSC_BLUE_Medic 		= INVALID_HANDLE;
new Handle:CSC_BLUE_Pyro 		= INVALID_HANDLE;
new Handle:CSC_BLUE_Scout 		= INVALID_HANDLE;
new Handle:CSC_BLUE_Sniper		= INVALID_HANDLE;
new Handle:CSC_BLUE_Soldier 	= INVALID_HANDLE;
new Handle:CSC_BLUE_Spy 		= INVALID_HANDLE;

new Handle:CSC_AdminOnly		= INVALID_HANDLE;
new Handle:CSC_Enabled		= INVALID_HANDLE;

new bool:g_isHooked			= false;
//new TFClassType;

public Plugin:myinfo = 
{
	name 		= "TF2 Class Speed Changer",
	author 	= "MoggieX",
	description 	= "Enables the ability to change the speed of the TF2 classes",
	version 	= PLUGIN_VERSION,
	url 		= "http://www.ukmandown.co.uk"
}


public OnPluginStart()
{
	CreateConVar("sm_csc_version", PLUGIN_VERSION, "The Zombie Fortress Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	// Red Team
	CSC_RED_DemoMan	= CreateConVar("sm_csc_red_demoman", 	"280.0", "Red Team: Alter the speed for the class: Demoman (Default = 280)");
	CSC_RED_Engineer	= CreateConVar("sm_csc_red_engineer", 	"300.0", "Red Team: Alter the speed for the class: Engineer (Default = 300)");
	CSC_RED_Heavy		= CreateConVar("sm_csc_red_heavy", 	"230.0", "Red Team: Alter the speed for the class: Engineer (Default = 230)");
	CSC_RED_Medic		= CreateConVar("sm_csc_red_medic", 	"320.0", "Red Team: Alter the speed for the class: Medic (Default = 320)");
	CSC_RED_Pyro		= CreateConVar("sm_csc_red_pyro", 		"300.0", "Red Team: Alter the speed for the class: Pyro (Default = 300)");
	CSC_RED_Scout		= CreateConVar("sm_csc_red_scout", 	"400.0", "Red Team: Alter the speed for the class: Scout (Default = 400)");
	CSC_RED_Sniper	= CreateConVar("sm_csc_red_sniper", 	"300.0", "Red Team: Alter the speed for the class: Sniper (Default= 300)");
	CSC_RED_Soldier	= CreateConVar("sm_csc_red_soldier", 	"240.0", "Red Team: Alter the speed for the class: Soldier (Default = 240)");
	CSC_RED_Spy		= CreateConVar("sm_csc_red_spy", 		"300.0", "Red Team: Alter the speed for the class: Spy (Default = 300)");

	// Blue Team
	CSC_BLUE_DemoMan	= CreateConVar("sm_csc_blue_demoman", 	"280.0", "Blue Team: Alter the speed for the class: Demoman (Default = 280)");
	CSC_BLUE_Engineer	= CreateConVar("sm_csc_blue_engineer", 	"300.0", "Blue Team: Alter the speed for the class: Engineer (Default = 300)");
	CSC_BLUE_Heavy	= CreateConVar("sm_csc_blue_heavy", 	"230.0", "Blue Team: Alter the speed for the class: Engineer (Default = 230)");
	CSC_BLUE_Medic	= CreateConVar("sm_csc_blue_medic", 	"320.0", "Blue Team: Alter the speed for the class: Medic (Default = 320)");
	CSC_BLUE_Pyro		= CreateConVar("sm_csc_blue_pyro", 	"300.0", "Blue Team: Alter the speed for the class: Pyro (Default = 300)");
	CSC_BLUE_Scout	= CreateConVar("sm_csc_blue_scout", 	"400.0", "Blue Team: Alter the speed for the class: Scout (Default = 400)");
	CSC_BLUE_Sniper	= CreateConVar("sm_csc_blue_sniper", 	"300.0", "Blue Team: Alter the speed for the class: Sniper (Default= 300)");
	CSC_BLUE_Soldier	= CreateConVar("sm_csc_blue_soldier", 	"240.0", "Blue Team: Alter the speed for the class: Soldier (Default = 240)");
	CSC_BLUE_Spy		= CreateConVar("sm_csc_blue_spy", 		"300.0", "Blue Team: Alter the speed for the class: Spy (Default = 300)");

	CSC_AdminOnly	= CreateConVar("sm_ccs_adminonly", "0", "Change speeds for Admins only 1= On 0= Off (Default = 0)");
	CSC_Enabled	= CreateConVar("sm_ccs_enabled", 	"1", "Enabled? 1= On 0= Off (Default = 1)");

	RegAdminCmd("sm_ccs_reset", Command_ResetSpeed, ADMFLAG_BAN, "Use to reset the class speeds back to defaults");

	// Load up
	CreateTimer(3.0, OnPluginStart_Delayed);
}

public Action:OnPluginStart_Delayed(Handle:timer){
	if(GetConVarInt(CSC_Enabled) == 1)
	{
		g_isHooked = true;
		HookEvent("player_spawn", 		event_Spawn);
		
		HookConVarChange(CSC_Enabled,	TFClassCvarChange);
		
		LogMessage("[TF2 Class Speed Changer] - Loaded");
	}
}

public TFClassCvarChange(Handle:convar, const String:oldValue[], const String:newValue[]){
	if(GetConVarInt(CSC_Enabled) <= 0){
		if(g_isHooked){
		g_isHooked = false;
		UnhookEvent("player_spawn", 	event_Spawn);
		}
	}else if(!g_isHooked){
		g_isHooked = true;
		HookEvent("player_spawn", 		event_Spawn);
	}
}

public Action:event_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{

	// Check if enabled
	if (GetConVarInt(CSC_Enabled) != 1)
	{
		return;
	}

	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsValidEntity(client))
	{
		if (IsClientInGame(client) && IsPlayerAlive(client)) 
		{
			new team 			= GetClientTeam(client);
			new TFClassType:class 	= TF2_GetPlayerClass(client);
			new clientFlags 		= GetUserFlagBits(client);

			if (team == 2)	// Red Team
			{
				// Start Switch Statement
				switch (class)
				{
					case TFClass_DemoMan:
					{

						// Do we need a cap ???
						if (GetConVarFloat(CSC_RED_DemoMan) < 0.0)
						{
																	// bail out speed was incorrect
							SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 280.0);
							LogMessage("[TF2 Class Speed Changer] Altering the speed failed due to invalid speed entered. Class: DemoMan. The speed was: %f", GetConVarFloat(CSC_RED_DemoMan));
													}
						
						if (GetConVarFloat(CSC_AdminOnly) == 1)
						{
							if (clientFlags & ADMFLAG_ROOT)
							{
								SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(CSC_RED_DemoMan));
								PrintToChat(client, "[TF2 Class Speed Changer] Your speed was altered to: %f", GetConVarFloat(CSC_RED_DemoMan));
							}
							else
							{
								// Do nothing
								return;
							}
						}	
						else
						{
							SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(CSC_RED_DemoMan));
							PrintToChat(client, "[TF2 Class Speed Changer] Your speed was altered to: %f", GetConVarFloat(CSC_RED_DemoMan));
						}
					}
					case TFClass_Engineer:
					{
						// Do we need a cap ???
						if (GetConVarFloat(CSC_RED_Engineer) < 0.0)
						{
							// bail out speed was incorrect
							SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 300.0);
							LogMessage("[TF2 Class Speed Changer] Altering the speed failed due to invalid speed entered. Class: Engineer. The speed was: %f", GetConVarFloat(CSC_RED_Engineer));
						}
						
						if (GetConVarFloat(CSC_AdminOnly) == 1)
						{
							if (clientFlags & ADMFLAG_ROOT)
							{
								SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(CSC_RED_Engineer));
								PrintToChat(client, "[TF2 Class Speed Changer] Your speed was altered to: %f", GetConVarFloat(CSC_RED_Engineer));
							}
							else
							{
								// Do nothing
								return;
							}
						}	
						else
						{
							SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(CSC_RED_Engineer));
							PrintToChat(client, "[TF2 Class Speed Changer] Your speed was altered to: %f", GetConVarFloat(CSC_RED_Engineer));
						}
					}
					case TFClass_Heavy:
					{

						// Do we need a cap ???
						if (GetConVarFloat(CSC_RED_Heavy) < 0.0)
						{
							// bail out speed was incorrect
							SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 230.0);
							LogMessage("[TF2 Class Speed Changer] Altering the speed failed due to invalid speed entered. Class: Heavy. The speed was: %f", GetConVarFloat(CSC_RED_Heavy));
						}
						
						if (GetConVarFloat(CSC_AdminOnly) == 1)
						{
							if (clientFlags & ADMFLAG_ROOT)
							{
								SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(CSC_RED_Heavy));
								PrintToChat(client, "[TF2 Class Speed Changer] Your speed was altered to: %f", GetConVarFloat(CSC_RED_Heavy));
							}
							else
							{
								// Do nothing
								return;
							}
						}	
						else
						{
							SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(CSC_RED_Heavy));
							PrintToChat(client, "[TF2 Class Speed Changer] Your speed was altered to: %f", GetConVarFloat(CSC_RED_Heavy));
						}
					}
					case TFClass_Medic:
					{
						// Do we need a cap ???
						if (GetConVarFloat(CSC_RED_Medic) < 0.0)
						{
							// bail out speed was incorrect
							SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 320.0);
							LogMessage("[TF2 Class Speed Changer] Altering the speed failed due to invalid speed entered. Class: Medic. The speed was: %f", GetConVarFloat(CSC_RED_Medic));
						}
						
						if (GetConVarFloat(CSC_AdminOnly) == 1)
						{
							if (clientFlags & ADMFLAG_ROOT)
							{
								SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(CSC_RED_Medic));
								PrintToChat(client, "[TF2 Class Speed Changer] Your speed was altered to: %f", GetConVarFloat(CSC_RED_Medic));
							}
							else
							{
								// Do nothing
								return;
							}
						}	
						else
						{
							SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(CSC_RED_Medic));
							PrintToChat(client, "[TF2 Class Speed Changer] Your speed was altered to: %f", GetConVarFloat(CSC_RED_Medic));
						}
					}
					case TFClass_Pyro:
					{
						// Do we need a cap ???
						if (GetConVarFloat(CSC_RED_Pyro) < 0.0)
						{
							// bail out speed was incorrect
							SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 300.0);
							LogMessage("[TF2 Class Speed Changer] Altering the speed failed due to invalid speed entered. Class: Pyro. The speed was: %f", GetConVarFloat(CSC_RED_Pyro));
						}
						
						if (GetConVarFloat(CSC_AdminOnly) == 1)
						{
							if (clientFlags & ADMFLAG_ROOT)
							{
								SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(CSC_RED_Pyro));
								PrintToChat(client, "[TF2 Class Speed Changer] Your speed was altered to: %f", GetConVarFloat(CSC_RED_Pyro));
							}
							else
							{
								// Do nothing
								return;
							}
						}	
						else
						{
							SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(CSC_RED_Pyro));
							PrintToChat(client, "[TF2 Class Speed Changer] Your speed was altered to: %f", GetConVarFloat(CSC_RED_Pyro));
						}
					}
					case TFClass_Scout:
					{
						// Do we need a cap ???
						if (GetConVarFloat(CSC_RED_Scout) < 0.0)
						{
							// bail out speed was incorrect
							SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 400.0);
							LogMessage("[TF2 Class Speed Changer] Altering the speed failed due to invalid speed entered. Class: Scout. The speed was: %f", GetConVarFloat(CSC_RED_Scout));
						}
						
						if (GetConVarFloat(CSC_AdminOnly) == 1)
						{
							if (clientFlags & ADMFLAG_ROOT)
							{
								SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(CSC_RED_Scout));
								PrintToChat(client, "[TF2 Class Speed Changer] Your speed was altered to: %f", GetConVarFloat(CSC_RED_Scout));
							}
							else
							{
								// Do nothing
								return;
							}
						}	
						else
						{
							SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(CSC_RED_Scout));
							PrintToChat(client, "[TF2 Class Speed Changer] Your speed was altered to: %f", GetConVarFloat(CSC_RED_Scout));
						}
					}
					case TFClass_Sniper:
					{
						// Do we need a cap ???
						if (GetConVarFloat(CSC_RED_Sniper) < 0.0)
						{
							// bail out speed was incorrect
							SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 300.0);
							LogMessage("[TF2 Class Speed Changer] Altering the speed failed due to invalid speed entered. Class: Sniper. The speed was: %f", GetConVarFloat(CSC_RED_Sniper));
						}
						
						if (GetConVarFloat(CSC_AdminOnly) == 1)
						{
							if (clientFlags & ADMFLAG_ROOT)
							{
								SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(CSC_RED_Sniper));
								PrintToChat(client, "[TF2 Class Speed Changer] Your speed was altered to: %f", GetConVarFloat(CSC_RED_Sniper));
							}
							else
							{
								// Do nothing
								return;
							}
						}	
						else
						{
							SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(CSC_RED_Sniper));
							PrintToChat(client, "[TF2 Class Speed Changer] Your speed was altered to: %f", GetConVarFloat(CSC_RED_Sniper));
						}
					}
					case TFClass_Soldier:
					{
						// Do we need a cap ???
						if (GetConVarFloat(CSC_RED_Soldier) < 0.0)
						{
							// bail out speed was incorrect
							SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 240.0);
							LogMessage("[TF2 Class Speed Changer] Altering the speed failed due to invalid speed entered. Class: Soldier. The speed was: %f", GetConVarFloat(CSC_RED_Soldier));
						}
						
						if (GetConVarFloat(CSC_AdminOnly) == 1)
						{
							if (clientFlags & ADMFLAG_ROOT)
							{
								SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(CSC_RED_Soldier));
								PrintToChat(client, "[TF2 Class Speed Changer] Your speed was altered to: %f", GetConVarFloat(CSC_RED_Soldier));
							}
							else
							{
								// Do nothing
								return;
							}
						}	
						else
						{
							SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(CSC_RED_Soldier));
							PrintToChat(client, "[TF2 Class Speed Changer] Your speed was altered to: %f", GetConVarFloat(CSC_RED_Soldier));
						}
					}
					case TFClass_Spy:
					{
						// Do we need a cap ???
						if (GetConVarFloat(CSC_RED_Spy) < 0.0)
						{
							// bail out speed was incorrect
							SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 300.0);
							LogMessage("[TF2 Class Speed Changer] Altering the speed failed due to invalid speed entered. Class: Spy. The speed was: %f", GetConVarFloat(CSC_RED_Spy));
						}
						
						if (GetConVarFloat(CSC_AdminOnly) == 1)
						{
							if (clientFlags & ADMFLAG_ROOT)
							{
								SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(CSC_RED_Spy));
								PrintToChat(client, "[TF2 Class Speed Changer] Your speed was altered to: %f", GetConVarFloat(CSC_RED_Spy));
							}
							else
							{
								// Do nothing
								return;
							}
						}	
						else
						{
							SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(CSC_RED_Spy));
							PrintToChat(client, "[TF2 Class Speed Changer] Your speed was altered to: %f", GetConVarFloat(CSC_RED_Spy));
						}
					}
					default:
					{
						LogMessage("[TF2 Class Speed Changer] Somethign really nasty happened here, they had no class!");
						return;
					}

				}
			}
			else if (team == 3)	// Blue Team			
			{
				// Start Switch Statement
				switch (class)
				{
					case TFClass_DemoMan:
					{

						// Do we need a cap ???
						if (GetConVarFloat(CSC_BLUE_DemoMan) < 0.0)
						{
																	// bail out speed was incorrect
							SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 280.0);
							LogMessage("[TF2 Class Speed Changer] Altering the speed failed due to invalid speed entered. Class: DemoMan. The speed was: %f", GetConVarFloat(CSC_BLUE_DemoMan));
													}
						
						if (GetConVarFloat(CSC_AdminOnly) == 1)
						{
							if (clientFlags & ADMFLAG_ROOT)
							{
								SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(CSC_BLUE_DemoMan));
								PrintToChat(client, "[TF2 Class Speed Changer] Your speed was altered to: %f", GetConVarFloat(CSC_BLUE_DemoMan));
							}
							else
							{
								// Do nothing
								return;
							}
						}	
						else
						{
							SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(CSC_BLUE_DemoMan));
							PrintToChat(client, "[TF2 Class Speed Changer] Your speed was altered to: %f", GetConVarFloat(CSC_BLUE_DemoMan));
						}
					}
					case TFClass_Engineer:
					{
						// Do we need a cap ???
						if (GetConVarFloat(CSC_BLUE_Engineer) < 0.0)
						{
							// bail out speed was incorrect
							SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 300.0);
							LogMessage("[TF2 Class Speed Changer] Altering the speed failed due to invalid speed entered. Class: Engineer. The speed was: %f", GetConVarFloat(CSC_BLUE_Engineer));
						}
						
						if (GetConVarFloat(CSC_AdminOnly) == 1)
						{
							if (clientFlags & ADMFLAG_ROOT)
							{
								SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(CSC_BLUE_Engineer));
								PrintToChat(client, "[TF2 Class Speed Changer] Your speed was altered to: %f", GetConVarFloat(CSC_BLUE_Engineer));
							}
							else
							{
								// Do nothing
								return;
							}
						}	
						else
						{
							SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(CSC_BLUE_Engineer));
							PrintToChat(client, "[TF2 Class Speed Changer] Your speed was altered to: %f", GetConVarFloat(CSC_BLUE_Engineer));
						}
					}
					case TFClass_Heavy:
					{

						// Do we need a cap ???
						if (GetConVarFloat(CSC_BLUE_Heavy) < 0.0)
						{
							// bail out speed was incorrect
							SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 230.0);
							LogMessage("[TF2 Class Speed Changer] Altering the speed failed due to invalid speed entered. Class: Heavy. The speed was: %f", GetConVarFloat(CSC_BLUE_Heavy));
						}
						
						if (GetConVarFloat(CSC_AdminOnly) == 1)
						{
							if (clientFlags & ADMFLAG_ROOT)
							{
								SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(CSC_BLUE_Heavy));
								PrintToChat(client, "[TF2 Class Speed Changer] Your speed was altered to: %f", GetConVarFloat(CSC_BLUE_Heavy));
							}
							else
							{
								// Do nothing
								return;
							}
						}	
						else
						{
							SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(CSC_BLUE_Heavy));
							PrintToChat(client, "[TF2 Class Speed Changer] Your speed was altered to: %f", GetConVarFloat(CSC_BLUE_Heavy));
						}
					}
					case TFClass_Medic:
					{
						// Do we need a cap ???
						if (GetConVarFloat(CSC_BLUE_Medic) < 0.0)
						{
							// bail out speed was incorrect
							SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 320.0);
							LogMessage("[TF2 Class Speed Changer] Altering the speed failed due to invalid speed entered. Class: Medic. The speed was: %f", GetConVarFloat(CSC_BLUE_Medic));
						}
						
						if (GetConVarFloat(CSC_AdminOnly) == 1)
						{
							if (clientFlags & ADMFLAG_ROOT)
							{
								SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(CSC_BLUE_Medic));
								PrintToChat(client, "[TF2 Class Speed Changer] Your speed was altered to: %f", GetConVarFloat(CSC_BLUE_Medic));
							}
							else
							{
								// Do nothing
								return;
							}
						}	
						else
						{
							SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(CSC_BLUE_Medic));
							PrintToChat(client, "[TF2 Class Speed Changer] Your speed was altered to: %f", GetConVarFloat(CSC_BLUE_Medic));
						}
					}
					case TFClass_Pyro:
					{
						// Do we need a cap ???
						if (GetConVarFloat(CSC_BLUE_Pyro) < 0.0)
						{
							// bail out speed was incorrect
							SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 300.0);
							LogMessage("[TF2 Class Speed Changer] Altering the speed failed due to invalid speed entered. Class: Pyro. The speed was: %f", GetConVarFloat(CSC_BLUE_Pyro));
						}
						
						if (GetConVarFloat(CSC_AdminOnly) == 1)
						{
							if (clientFlags & ADMFLAG_ROOT)
							{
								SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(CSC_BLUE_Pyro));
								PrintToChat(client, "[TF2 Class Speed Changer] Your speed was altered to: %f", GetConVarFloat(CSC_BLUE_Pyro));
							}
							else
							{
								// Do nothing
								return;
							}
						}	
						else
						{
							SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(CSC_BLUE_Pyro));
							PrintToChat(client, "[TF2 Class Speed Changer] Your speed was altered to: %f", GetConVarFloat(CSC_BLUE_Pyro));
						}
					}
					case TFClass_Scout:
					{
						// Do we need a cap ???
						if (GetConVarFloat(CSC_BLUE_Scout) < 0.0)
						{
							// bail out speed was incorrect
							SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 400.0);
							LogMessage("[TF2 Class Speed Changer] Altering the speed failed due to invalid speed entered. Class: Scout. The speed was: %f", GetConVarFloat(CSC_BLUE_Scout));
						}
						
						if (GetConVarFloat(CSC_AdminOnly) == 1)
						{
							if (clientFlags & ADMFLAG_ROOT)
							{
								SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(CSC_BLUE_Scout));
								PrintToChat(client, "[TF2 Class Speed Changer] Your speed was altered to: %f", GetConVarFloat(CSC_BLUE_Scout));
							}
							else
							{
								// Do nothing
								return;
							}
						}	
						else
						{
							SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(CSC_BLUE_Scout));
							PrintToChat(client, "[TF2 Class Speed Changer] Your speed was altered to: %f", GetConVarFloat(CSC_BLUE_Scout));
						}
					}
					case TFClass_Sniper:
					{
						// Do we need a cap ???
						if (GetConVarFloat(CSC_BLUE_Sniper) < 0.0)
						{
							// bail out speed was incorrect
							SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 300.0);
							LogMessage("[TF2 Class Speed Changer] Altering the speed failed due to invalid speed entered. Class: Sniper. The speed was: %f", GetConVarFloat(CSC_BLUE_Sniper));
						}
						
						if (GetConVarFloat(CSC_AdminOnly) == 1)
						{
							if (clientFlags & ADMFLAG_ROOT)
							{
								SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(CSC_BLUE_Sniper));
								PrintToChat(client, "[TF2 Class Speed Changer] Your speed was altered to: %f", GetConVarFloat(CSC_BLUE_Sniper));
							}
							else
							{
								// Do nothing
								return;
							}
						}	
						else
						{
							SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(CSC_BLUE_Sniper));
							PrintToChat(client, "[TF2 Class Speed Changer] Your speed was altered to: %f", GetConVarFloat(CSC_BLUE_Sniper));
						}
					}
					case TFClass_Soldier:
					{
						// Do we need a cap ???
						if (GetConVarFloat(CSC_BLUE_Soldier) < 0.0)
						{
							// bail out speed was incorrect
							SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 240.0);
							LogMessage("[TF2 Class Speed Changer] Altering the speed failed due to invalid speed entered. Class: Soldier. The speed was: %f", GetConVarFloat(CSC_BLUE_Soldier));
						}
						
						if (GetConVarFloat(CSC_AdminOnly) == 1)
						{
							if (clientFlags & ADMFLAG_ROOT)
							{
								SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(CSC_BLUE_Soldier));
								PrintToChat(client, "[TF2 Class Speed Changer] Your speed was altered to: %f", GetConVarFloat(CSC_BLUE_Soldier));
							}
							else
							{
								// Do nothing
								return;
							}
						}	
						else
						{
							SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(CSC_BLUE_Soldier));
							PrintToChat(client, "[TF2 Class Speed Changer] Your speed was altered to: %f", GetConVarFloat(CSC_BLUE_Soldier));
						}
					}
					case TFClass_Spy:
					{
						// Do we need a cap ???
						if (GetConVarFloat(CSC_BLUE_Spy) < 0.0)
						{
							// bail out speed was incorrect
							SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 300.0);
							LogMessage("[TF2 Class Speed Changer] Altering the speed failed due to invalid speed entered. Class: Spy. The speed was: %f", GetConVarFloat(CSC_BLUE_Spy));
						}
						
						if (GetConVarFloat(CSC_AdminOnly) == 1)
						{
							if (clientFlags & ADMFLAG_ROOT)
							{
								SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(CSC_BLUE_Spy));
								PrintToChat(client, "[TF2 Class Speed Changer] Your speed was altered to: %f", GetConVarFloat(CSC_BLUE_Spy));
							}
							else
							{
								// Do nothing
								return;
							}
						}	
						else
						{
							SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(CSC_BLUE_Spy));
							PrintToChat(client, "[TF2 Class Speed Changer] Your speed was altered to: %f", GetConVarFloat(CSC_BLUE_Spy));
						}
					}
					default:
					{
						LogMessage("[TF2 Class Speed Changer] Somethign really nasty happened here, they had no class!");
						return;
					}

				}			
			}

			// Do nothing
			return;

		}	
	}
}

public Action:Command_ResetSpeed(client, args)
{
	// Red Team
	SetConVarFloat(CSC_RED_DemoMan, 		280.0);
	SetConVarFloat(CSC_RED_Engineer, 		300.0);
	SetConVarFloat(CSC_RED_Heavy,		230.0);
	SetConVarFloat(CSC_RED_Medic,		320.0);
	SetConVarFloat(CSC_RED_Pyro,		300.0);
	SetConVarFloat(CSC_RED_Scout,		400.0);
	SetConVarFloat(CSC_RED_Sniper,		300.0);
	SetConVarFloat(CSC_RED_Soldier,		240.0);
	SetConVarFloat(CSC_RED_Spy,			300.0);

	// Blue Team
	SetConVarFloat(CSC_BLUE_DemoMan, 		280.0);
	SetConVarFloat(CSC_BLUE_Engineer, 		300.0);
	SetConVarFloat(CSC_BLUE_Heavy,		230.0);
	SetConVarFloat(CSC_BLUE_Medic,		320.0);
	SetConVarFloat(CSC_BLUE_Pyro,		300.0);
	SetConVarFloat(CSC_BLUE_Scout,		400.0);
	SetConVarFloat(CSC_BLUE_Sniper,		300.0);
	SetConVarFloat(CSC_BLUE_Soldier,		240.0);
	SetConVarFloat(CSC_BLUE_Spy,		300.0);

	ReplyToCommand(client, "[TF2 Class Speed Changer] Speeds reset to defaults");
	return Plugin_Handled;	
}	


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	