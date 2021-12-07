/* ***************************************************************************\
 * 
 * PLUGIN NAME: l4d(2)_powerups_rush
 * 
 * CREDITS: *tPoncho - Huge props for the fast reload, weapon firing, and melee swing codes
 *          *hihi1210 - for the formula for multiple melee swings
 *          *AlliedModders Wiki - for all the references
 *          *Testers - of this Plugin
 *          *dirka dirka - for fixing the tag mismatches
 * 
 * NOTES: *This plugin was written with Pawn Studio version 0.8.3
 *        *The previous version was named l4d2_adrenaline_reload and can be found at
 *         http://forums.alliedmods.net/showthread.php?t=122474
 * 
 * VERSION: 2.0.1
 * 
 * CHANGELOG: 1.0.0
 *            *Initial Release
 *            1.0.1
 *            *Added ConVar for toggling if adrenaline needed to be used
 *            1.0.2
 *            *Added a URL
 *            *Added support for giving Adrenaline at round start
 *            *Added an Admin command to give Adrenaline to everyone anytime
 *             (Requires CHEATS flag)
 *            1.0.3
 *            *Fixed the adrenaline toggling off not picking up
 *            1.0.4
 *            *I skipped it. Why? Because I can =D
 *            1.0.5
 *            *Added ConVar to toggle if plugin is active
 *            *Added ConVar to toggle if broadcasts will play on client connect
 *            *Added ConVar to toggle where broadcasts will play on client connect
 *            *Tweeked some commands to allow in-game changes
 *            *Fixed sm_giveadren showing up as an unknown command in console
 *            *Fixed the adrenaline toggling off (and on) not picking up *ahem* for real this time
 *            *Added convar to determine how long the duration of adrenaline reload lasts
 *             (This does not apply to the convar 'adrenaline_duration')
 *             (Will be adding one that affects that convar soon...)
 *            *Added a timer in hint box counting down how many seconds remains
 *            *Added a debugging definition for easier debugs
 * 
 *            2.0.0
 *            *Renamed file name from l4d2_adren_reload to l4d(2)_powerups_rush
 *            *Renamed more various handles, floats, etc.
 *            *Added support for faster melee swings
 *            *Added ConVar for melee swing rates
 *            *Added support for faster weapon firing speeds
 *            *Added ConVar for weapon firing rates
 *            *Added support for pills
 *            *Added ConVar to toggle what are the odds you will get the boosts
 *            *Added support for giving Pain Pills at round start
 *            *Added an Admin command 'sm_givepills' to give everybody Pain Pills, anytime
 *             (Requires CHEATS flag)
 *            *Added support for giving either Adrenaline or Pain Pills at round start
 *            *Added an Admin command 'sm_giverandom' to give everybody either Adrenaline or Pain Pills, anytime
 *             (Requires CHEATS flag)
 *            2.0.1
 *            *Fixed the Tag Mismatches
 *             (Thanks 'dirka dirka')!
 *            *Added a URL in plugin information
 *            *Changed the default 'l4d_powerups_weaponmelee_rate' from 0.5 to 0.45
 * 
 * TO DO: *Clean up my coding (about 75% done)
 *        *Add support for which catagory Adrenaline (or Pills) affects
 *         (At the moment, it toggles all 3...)
 *        *Add support for L4D1?
 *
\* ***************************************************************************/

#define PLUGIN_VERSION "2.0.1"
//Set this value to 1 to enable debugging
#define DEBUG 0

#pragma newdecls required
#include <sourcemod>
#include <sdktools>
/* ***************************************************************************/
//Used to track who has the weapon firing.
//Index goes up to 18, but each index has a value indicating a client index with
//DT so the plugin doesn't have to cycle a full 18 times per game frame
int g_iDTRegisterIndex[64] = -1;
//and this tracks how many have DT
int g_iDTRegisterCount = 0;
//this tracks the current active 'weapon id' in case the player changes guns
int g_iDTEntid[64] = -1;
//this tracks the engine time of the next attack for the weapon, after modification
//(modified interval + engine time)
float g_flDTNextTime[64] = -1.0;
/* ***************************************************************************/
//similar to Double Tap
int g_iMARegisterIndex[64] = -1;
//and this tracks how many have MA
int g_iMARegisterCount = 0;
//these are similar to those used by Double Tap
float g_flMANextTime[64] = -1.0;
int g_iMAEntid[64] = -1;
int g_iMAEntid_notmelee[64] = -1;
//this tracks the attack count, similar to twinSF
int g_iMAAttCount[64] = -1;
/* ***************************************************************************/
//Rates of the attacks
Handle g_hDT_rate;
float g_flDT_rate;
Handle g_h_reload_rate;
float g_fl_reload_rate;
/*float melee_speed[MAXPLAYERS+1];*/
Handle g_h_melee_rate;
//Make sure we stop activity on map changes or we can get disconnects
bool g_bIsLoading;
/* ***************************************************************************/
//This keeps track of the default values for reload speeds for the different shotgun types
//NOTE: I got these values from tPoncho's own source
//NOTE: Pump and Chrome have identical values
const float g_fl_AutoS = 0.4;
const float g_fl_AutoI = 0.4;
const float g_fl_AutoE = 0.4;
const float g_fl_SpasS = 0.4;
const float g_fl_SpasI = 0.4;
const float g_fl_SpasE = 0.4;
const float g_fl_PumpS = 0.4;
const float g_fl_PumpI = 0.4;
const float g_fl_PumpE = 0.4;
/* ***************************************************************************/
//tracks if the game is L4D 2 (Support for L4D1 pending...)
int g_i_L4D_12 = 0;
/* ***************************************************************************/
//offsets
int g_iNextPAttO		= -1;
int g_iActiveWO			= -1;
int g_iShotStartDurO	= -1;
int g_iShotInsertDurO	= -1;
int g_iShotEndDurO		= -1;
int g_iPlayRateO		= -1;
int g_iShotRelStateO	= -1;
int g_iNextAttO			= -1;
int g_iTimeIdleO		= -1;
int g_iVMStartTimeO		= -1;
int g_iViewModelO		= -1;
int g_iNextSAttO		= -1;
int g_ActiveWeaponOffset;
/* ***************************************************************************/
//tracks if the client has used an adrenaline (or pills) for that duration
int g_usedhealth[MAXPLAYERS + 1] = 0;
/* ***************************************************************************/
//Timer definitions
Handle WelcomeTimers[MAXPLAYERS + 1];
Handle g_powerups_timer[MAXPLAYERS + 1];
Handle g_powerups_countdown[MAXPLAYERS + 1];
int g_powerups_timeleft[MAXPLAYERS + 1];
/* ***************************************************************************/
//Enables and Disables
Handle powerups_plugin_on;
Handle  powerups_broadcast_on;
Handle powerups_broadcast_type;
Handle powerups_use_on;
Handle adren_give_on;
Handle pills_give_on;
Handle random_give_on;
//Numbers
Handle powerups_duration;
Handle pills_luck;
/* ***************************************************************************/
public Plugin myinfo = 
{
	name = "[L4D2] PowerUps rush",
	author = "Dusty1029 (a.k.a. {L.2.K} LOL)",
	description = "When a client pops an adrenaline (or pills), various actions are perform faster (reload, melee swings, firing rates)",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=127513"
}
/* ***************************************************************************/
public void OnPluginStart()
{
	char stGame[32];
	GetGameFolderName(stGame, 32);
	if (StrEqual(stGame, "left4dead2", false)==true)
	{
		g_i_L4D_12 = 2;
		// LogMessage("L4D 2 detected.");
	}
	/*else if (StrEqual(stGame, "left4dead", false)==true)
	{
		g_i_L4D_12 = 1;
		// LogMessage("L4D 1 detected.");
	}*/
	else
	{
		SetFailState("Mod only supports Left 4 Dead 2.");
	}
	
	//ConVars
	RegAdminCmd("sm_giveadren", Command_GiveAdrenaline, ADMFLAG_CHEATS, "Gives Adrenaline to all Survivors.");
	RegAdminCmd("sm_givepills", Command_GivePills, ADMFLAG_CHEATS, "Give Pills to all Survivors.");
	RegAdminCmd("sm_giverandom", Command_GiveRandom, ADMFLAG_CHEATS, "Give Random item (Adrenaline or Pills) to all Survivors.");
	CreateConVar("l4d_powerups_rush_version", PLUGIN_VERSION,"The version of the PowerUps plugin.", FCVAR_NONE|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	powerups_plugin_on = CreateConVar("l4d_powerups_plugin_on", "1", "Is the Plugin active? (1 = ON  0 = OFF)", FCVAR_NONE|FCVAR_SPONLY, true, 0.0, true, 1.0);
	powerups_broadcast_on = CreateConVar("l4d_powerups_broadcast_on", "1", "Should players be notified when connecting to server about the powerups? (1 = ON  0 = OFF)", FCVAR_NONE|FCVAR_SPONLY, true, 0.0, true, 1.0);
	powerups_broadcast_type = CreateConVar("l4d_powerups_broadcast_type", "1", "How are players notified? (0 = CHAT  1 = HINT  2 = BOTH)", FCVAR_NONE|FCVAR_SPONLY, true, 0.0, true, 2.0);
	powerups_use_on = CreateConVar("l4d_powerups_use_on", "1", "Should players use adrenaline (or pills) to get super reload, weapon firing, and melee swings? (1 = ON  0 = OFF)", FCVAR_NONE|FCVAR_SPONLY, true, 0.0, true, 1.0);
	adren_give_on = CreateConVar("l4d_powerups_adren_give_on", "0", "Should players be given adrenaline at round start? (1 = ON  0 = OFF)", FCVAR_NONE|FCVAR_SPONLY, true, 0.0, true, 1.0);
	pills_give_on = CreateConVar("l4d_powerups_pills_give_on", "0", "Should players be given pills at round start? (1 = ON  0 = OFF)", FCVAR_NONE|FCVAR_SPONLY, true, 0.0, true, 1.0);
	random_give_on = CreateConVar("l4d_powerups_random_give_on", "0", "Should players be given either adrenaline or pills at round start? (1 = ON  0 = OFF)", FCVAR_NONE|FCVAR_SPONLY, true, 0.0, true, 1.0);
	powerups_duration = CreateConVar("l4d_powerups_duration", "120", "How long should the duration of the boosts last?", FCVAR_NONE|FCVAR_NOTIFY, true, 1.0);
	pills_luck = CreateConVar("l4d_powerups_pills_luck", "3", "The luck factor for swallowing pills that will grant the boost(s). (1 = 1/1  2 = 1/2  3 = 1/3  4 = 1/4  etc.)", FCVAR_NONE|FCVAR_NOTIFY, true, 1.0);
	
	g_h_reload_rate = CreateConVar("l4d_powerups_weaponreload_rate", "0.4", "The interval incurred by reloading is multiplied by this value (clamped between 0.2 < 0.9)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.2, true, 0.9);
	HookConVarChange(g_h_reload_rate, Convar_Reload);
	g_fl_reload_rate = 0.4;
		
	g_h_melee_rate = CreateConVar("l4d_powerups_weaponmelee_rate", "0.4", "The interval for swinging melee weapon (clamped between 0.3 < 0.9)", FCVAR_NONE|FCVAR_NOTIFY, true, 0.3, true, 0.9);
		
	g_hDT_rate = CreateConVar("l4d_powerups_weaponfiring_rate", "0.02", "The interval between bullets fired is multiplied by this value. WARNING: a short enough interval will make SMGs' and rifles' firing accuracy distorted (clamped between 0.02 < 0.9)" , FCVAR_NONE|FCVAR_NOTIFY, true, 0.02, true, 0.9);
	HookConVarChange(g_hDT_rate, Convar_DT);
	g_flDT_rate = 0.9;
	
	//Event Hooks
	HookEvent("weapon_reload", Event_Reload);
	HookEvent("adrenaline_used", Event_AdrenalineUsed);
	HookEvent("pills_used", Event_PillsUsed);
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd);
	
	//get offsets
	g_iNextPAttO		=	FindSendPropInfo("CBaseCombatWeapon","m_flNextPrimaryAttack");
	g_iActiveWO			=	FindSendPropInfo("CBaseCombatCharacter","m_hActiveWeapon");
	g_iShotStartDurO	=	FindSendPropInfo("CBaseShotgun","m_reloadStartDuration");
	g_iShotInsertDurO	=	FindSendPropInfo("CBaseShotgun","m_reloadInsertDuration");
	g_iShotEndDurO		=	FindSendPropInfo("CBaseShotgun","m_reloadEndDuration");
	g_iPlayRateO		=	FindSendPropInfo("CBaseCombatWeapon","m_flPlaybackRate");
	g_iShotRelStateO	=	FindSendPropInfo("CBaseShotgun","m_reloadState");
	g_iNextAttO			=	FindSendPropInfo("CTerrorPlayer","m_flNextAttack");
	g_iTimeIdleO		=	FindSendPropInfo("CTerrorGun","m_flTimeWeaponIdle");
	g_iVMStartTimeO		=	FindSendPropInfo("CTerrorViewModel","m_flLayerStartTime");
	g_iViewModelO		=	FindSendPropInfo("CTerrorPlayer","m_hViewModel");
	
	g_ActiveWeaponOffset = FindSendPropInfo("CBasePlayer", "m_hActiveWeapon");
	g_iNextSAttO		=	FindSendPropInfo("CBaseCombatWeapon","m_flNextSecondaryAttack");
	
	g_bIsLoading = true;
	
	//Execute or create cfg
	AutoExecConfig(true, "l4d2_powerups_rush")
}
/* ***************************************************************************/
public void Convar_Reload (ConVar convar, const char[] oldValue, const char[] newValue)
{
	float flF = StringToFloat(newValue);
	if (flF < 0.02)
		flF = 0.02;
	else if (flF > 0.9)
		flF = 0.9;
	g_fl_reload_rate = flF;
}

public void Convar_DT (ConVar convar, const char[] oldValue, const char[] newValue)
{
	float flF = StringToFloat(newValue);
	if (flF < 0.02)
		flF = 0.02;
	else if (flF > 0.9)
		flF = 0.9;
	g_flDT_rate = flF;
}
/* ***************************************************************************/
public void OnClientPutInServer(int client)
{
	g_usedhealth[client] = 0;
	if (GetConVarBool(powerups_plugin_on))
	{
		if (GetConVarInt(powerups_use_on) == 0)
		{
			g_usedhealth[client] = 1;
			RebuildAll();
		}
	}
	if (client && !IsFakeClient(client))
	{
		WelcomeTimers[client] = CreateTimer(5.0, Timer_Notify, client)
	}
}

public void OnClientDisconnect(int client)
{
	if (g_usedhealth[client] == 1)
	{
		KillTimer(g_powerups_countdown[client])
		KillTimer(g_powerups_timer[client])
	}
	g_usedhealth[client] = 0;
	if (GetConVarBool(powerups_plugin_on))
	{
		// melee_speed[client] = 0.0;
		RebuildAll();
		/*if (WelcomeTimers[client] != INVALID_HANDLE)
		{
			KillTimer(WelcomeTimers[client])
			WelcomeTimers[client] = INVALID_HANDLE
		}*/
	}
}
/* ***************************************************************************/
public Action Timer_Notify(Handle Timer, any client)
{
	if (GetConVarBool(powerups_plugin_on) && IsInGame(client))
	{
		if (GetConVarBool(powerups_broadcast_on))
		{
			if (GetConVarBool(powerups_use_on))
			{
				if (GetConVarInt(powerups_broadcast_type) == 0)
				{
					PrintToChat(client, "\x04[SM] \x01In this server, using the \x04Adrenaline \x01(or \x04Pills\x01) will grant a \x04Reload, Firing, and Melee Swing bonus \x01during that duration");
				}
				else if (GetConVarInt(powerups_broadcast_type) == 1)
				{
					PrintHintText(client, "In this server, using the Adrenaline (or Pills) will grant a\nReload, Firing, and Melee Swing bonus during that duration");
				}
				else if (GetConVarInt(powerups_broadcast_type) == 2)
				{
					PrintToChat(client, "\x04[SM] \x01In this server, using the \x04Adrenaline \x01(or \x04Pills\x01) will grant a \x04Reload, Firing, and Melee Swing bonus \x01during that duration");
					PrintHintText(client, "In this server, using the Adrenaline (or Pills) will grant a\nReload, Firing, and Melee Swing bonus during that duration");
				}
			}
			else if (!GetConVarBool(powerups_use_on))
			{
				if (GetConVarInt(powerups_broadcast_type) == 0)
				{
					PrintToChat(client, "\x04[SM] \x01In this server, \x04Reload, Firing, and Melee Swing Rates \x01are increased!");
				}
				else if (GetConVarInt(powerups_broadcast_type) == 1)
				{
					PrintHintText(client, "In this server, Reload, Firing, and Melee Swing Rates are increased!");
				}
				else if (GetConVarInt(powerups_broadcast_type) == 2)
				{
					PrintToChat(client, "\x04[SM] \x01In this server, \x04Reload, Firing, and Melee Swing Rates \x01are increased!");
					PrintHintText(client, "In this server, Reload, Firing, and Melee Swing Rates are increased!");
				}
			}
		}
	}
	return Plugin_Stop
}
/* ***************************************************************************/
//Round start
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bIsLoading = false;
	ClearAll();
	CreateTimer(30.0, Timer_GiveAdrenaline);
	CreateTimer(30.1, Timer_GivePills);
	CreateTimer(30.2, Timer_GiveRandom);
}
/* ***************************************************************************/
public Action Timer_GiveAdrenaline(Handle timer)
{
	if (GetConVarBool(powerups_plugin_on))
	{
		if (GetConVarInt(adren_give_on) == 1)
		{
			GiveAdrenalineToAll()
		}
	}
}

public Action Command_GiveAdrenaline(int client, int args)
{
	GiveAdrenalineToAll()
	return Plugin_Handled;
}

public void GiveAdrenalineToAll()
{
	int flags = GetCommandFlags("give");	
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			FakeClientCommand(i, "give adrenaline");
			PrintToChat(i, "\x04[SM] \x01Grabbin' \x04Adrenaline");
		}
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}
// ////////////////////////////////////////////////////////////////////////////
public Action Timer_GivePills(Handle timer)
{
	if (GetConVarBool(powerups_plugin_on))
	{
		if (GetConVarInt(pills_give_on) == 1)
		{
			GivePillsToAll()
		}
	}
}

public Action Command_GivePills(int client, int args)
{
	GivePillsToAll()
	return Plugin_Handled;
}

public void GivePillsToAll()
{
	int flags = GetCommandFlags("give");	
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			FakeClientCommand(i, "give pain_pills");
			PrintToChat(i, "\x04[SM] \x01Grabbin' \x04Pills");
		}
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}
// ////////////////////////////////////////////////////////////////////////////
public Action Timer_GiveRandom(Handle timer)
{
	if (GetConVarBool(powerups_plugin_on))
	{
		if (GetConVarInt(random_give_on) == 1)
		{
			GiveRandomToAll()
		}
	}
}

public Action Command_GiveRandom(int client, int args)
{
	GiveRandomToAll()
	return Plugin_Handled;
}

public void GiveRandomToAll()
{
	int flags = GetCommandFlags("give");	
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			int luck = GetRandomInt(1, 2);
			if (luck == 1)
			{
				FakeClientCommand(i, "give adrenaline");
				PrintToChat(i, "\x04[SM] \x01Grabbin' \x04Adrenaline");
			}
			if (luck == 2)
			{
				FakeClientCommand(i, "give pain_pills");
				PrintToChat(i, "\x04[SM] \x01Grabbin' \x04Pills");
			}
		}
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}
/* ***************************************************************************/
//Popping the Adrenaline
public void Event_AdrenalineUsed (Event event, const char[] name, bool dontBroadcast)
{
	if (GetConVarBool(powerups_plugin_on))
	{
		int client = GetClientOfUserId(GetEventInt(event,"userid"));
		if (client == 0)
		{
			return;
		}
		else
		{
			if (GetConVarBool(powerups_use_on))
			{
				if (IsClientInGame(client) && GetClientTeam(client) == 2)
				{
					//We need to reset the timer in case the client decides to
					//use a second adrenaline while the first one is still active
					if (g_usedhealth[client] == 1)
					{
						KillTimer(g_powerups_timer[client])
						KillTimer(g_powerups_countdown[client])
						#if DEBUG
						PrintToChat(client, "\x04[DEBUG] \x03Resetting powerups timers");
						#endif
						g_usedhealth[client] = 0;
					}
					//A delay of 0.1 second to reset the reload speed. Not like
					//you'll be able to pull out your gun fast enough :P
					CreateTimer(0.1, Timer_UsedHealth, client, TIMER_FLAG_NO_MAPCHANGE);
					g_powerups_countdown[client] = CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT);
					g_powerups_timer[client] = CreateTimer(GetConVarInt(powerups_duration) * 1.0, Timer_EndPower, client, TIMER_FLAG_NO_MAPCHANGE);
					//Multiply by 1.0 to prevent tag mismatch
				}
			}
		}
	}
}
/* ***************************************************************************/
//Popping the Pills
public void Event_PillsUsed (Event event, const char[] name, bool dontBroadcast)
{
	if (GetConVarBool(powerups_plugin_on))
	{
		int client = GetClientOfUserId(GetEventInt(event,"subject"));
		if (client == 0)
		{
			return;
		}
		else
		{
			if (GetConVarBool(powerups_use_on))
			{
				if (IsClientInGame(client) && GetClientTeam(client) == 2)
				{
					int luck = GetRandomInt(1, GetConVarInt(pills_luck));
					if (luck == 1)
					{
						//We need to reset the timer in case the client decides to use
						//a second bottle of pills while the first one is still active
						if (g_usedhealth[client] == 1)
						{
							KillTimer(g_powerups_timer[client])
							KillTimer(g_powerups_countdown[client])
							#if DEBUG
							PrintToChat(client, "\x04[DEBUG] \x03Resetting powerups timers");
							#endif
							g_usedhealth[client] = 0;
						}
						//A delay of 0.1 second to reset the reload speed. Not like
						//you'll be able to pull out your gun fast enough :P
						CreateTimer(0.1, Timer_UsedHealth, client, TIMER_FLAG_NO_MAPCHANGE);
						g_powerups_countdown[client] = CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT);
						g_powerups_timer[client] = CreateTimer(GetConVarInt(powerups_duration) * 1.0, Timer_EndPower, client, TIMER_FLAG_NO_MAPCHANGE);
						//Multiply by 1.0 to prevent tag mismatch
					}
				}
			}
		}
	}
}
/* ***************************************************************************/
public Action Timer_UsedHealth(Handle Timer, any client)
{
	if (GetConVarBool(powerups_use_on))
	{
		PrintToChat(client, "\x04[SM] \x01Reload, Firing, and Melee Swing Rates increased!");
		PrintHintText(client, "Powerups time left: %d", GetConVarInt(powerups_duration));
		g_powerups_timeleft[client] = GetConVarInt(powerups_duration);
		g_powerups_timeleft[client] -= 1;
		g_usedhealth[client] = 1
		RebuildAll();
	}
}

public Action Timer_EndPower(Handle Timer, any client)
{
	if (GetConVarBool(powerups_use_on))
	{
		PrintToChat(client, "\x04[SM] \x01Reload, Firing, and Melee Swing Rates returning to normal...");
		g_usedhealth[client] = 0
		RebuildAll();
	}
}

public Action Timer_Countdown(Handle timer, any client)
{
	if(g_powerups_timeleft[client] == 0) //Powerups ran out
	{
		PrintHintText(client,"Reload, Firing, and Melee Swing Rates returning to normal...");
		g_powerups_timeleft[client] = GetConVarInt(powerups_duration);
		return Plugin_Stop;
	}
	else //Countdown progress
	{
		PrintHintText(client,"Powerups time left: %d", g_powerups_timeleft[client]);
		g_powerups_timeleft[client] -= 1;
		return Plugin_Continue;
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ClearAll();
	CreateTimer(0.1, Timer_RoundEnd);
}

public Action Timer_RoundEnd(Handle Timer, any client)
{
	if (GetConVarBool(powerups_plugin_on))
	{
		if (GetConVarBool(powerups_use_on))
		{
			if (g_usedhealth[client] == 1)
			{
				KillTimer(g_powerups_countdown[client])
				KillTimer(g_powerups_timer[client])
				PrintToChat(client, "\x04[SM] \x01Reload, Firing, and Melee Swing Rates returning to normal...");
				PrintHintText(client, "Reload, Firing, and Melee Swing Rates returning to normal...");
				g_usedhealth[client] = 0
			}
		}
	}
}
/* ***************************************************************************/
//Reloading weapon
public void Event_Reload (Event event, const char[] name, bool dontBroadcast)
{
	if (GetConVarBool(powerups_plugin_on))
	{
		int client = GetClientOfUserId(GetEventInt(event,"userid"));
		if (g_usedhealth[client] == 1) //If client got the boost(s)
		{
			AdrenReload(client);
		}
		else //Obviously they haven't
		{
			return;
		}
	}
}
// ////////////////////////////////////////////////////////////////////////////
//On the start of a reload
void AdrenReload (int client)
{
	if (GetClientTeam(client) == 2)
	{
		#if DEBUG
		PrintToChatAll("\x03Client \x01%i\x03; start of reload detected",client );
		#endif
		int iEntid = GetEntDataEnt2(client, g_iActiveWO);
		if (IsValidEntity(iEntid)==false) return;
	
		char stClass[32];
		GetEntityNetClass(iEntid,stClass,32);
		#if DEBUG
		PrintToChatAll("\x03-class of gun: \x01%s",stClass );
		#endif

		//for non-shotguns
		if (StrContains(stClass,"shotgun",false) == -1)
		{
			MagStart(iEntid, client);
			return;
		}
		//shotguns are a bit trickier since the game tracks per shell inserted
		//and there's TWO different shotguns with different values...
		else if (StrContains(stClass,"autoshotgun",false) != -1)
		{
			//create a pack to send clientid and gunid through to the timer
			Handle hPack = CreateDataPack();
			WritePackCell(hPack, client);
			WritePackCell(hPack, iEntid);
			CreateTimer(0.1,Timer_AutoshotgunStart,hPack);
			return;
		}
		else if (StrContains(stClass,"shotgun_spas",false) != -1)
		{
			//similar to the autoshotgun, create a pack to send
			Handle hPack = CreateDataPack();
			WritePackCell(hPack, client);
			WritePackCell(hPack, iEntid);
			CreateTimer(0.1,Timer_SpasShotgunStart,hPack);
			return;
		}
		else if (StrContains(stClass,"pumpshotgun",false) != -1 || StrContains(stClass,"shotgun_chrome",false) != -1)
		{
			Handle hPack = CreateDataPack();
			WritePackCell(hPack, client);
			WritePackCell(hPack, iEntid);
			CreateTimer(0.1,Timer_PumpshotgunStart,hPack);
			return;
		}
	}
}
// ////////////////////////////////////////////////////////////////////////////
//called for mag loaders
void MagStart (int iEntid, int client)
{
	#if DEBUG
	PrintToChatAll("\x05-magazine loader detected,\x03 gametime \x01%f", GetGameTime());
	#endif
	float flGameTime = GetGameTime();
	float flNextTime_ret = GetEntDataFloat(iEntid,g_iNextPAttO);
	#if DEBUG
	PrintToChatAll("\x03- pre, gametime \x01%f\x03, retrieved nextattack\x01 %i %f\x03, retrieved time idle \x01%i %f",
		flGameTime,
		g_iNextAttO,
		GetEntDataFloat(client,g_iNextAttO),
		g_iTimeIdleO,
		GetEntDataFloat(iEntid,g_iTimeIdleO)
		);
	#endif

	//this is a calculation of when the next primary attack will be after applying reload values
	//NOTE: at this point, only calculate the interval itself, without the actual game engine time factored in
	float flNextTime_calc = ( flNextTime_ret - flGameTime ) * g_fl_reload_rate ;
	//we change the playback rate of the gun, just so the player can "see" the gun reloading faster
	SetEntDataFloat(iEntid, g_iPlayRateO, 1.0/g_fl_reload_rate, true);
	//create a timer to reset the playrate after time equal to the modified attack interval
	CreateTimer( flNextTime_calc, Timer_MagEnd, iEntid);
	//experiment to remove double-playback bug
	Handle hPack = CreateDataPack();
	WritePackCell(hPack, client);
	//this calculates the equivalent time for the reload to end
	float flStartTime_calc = flGameTime - ( flNextTime_ret - flGameTime ) * ( 1 - g_fl_reload_rate ) ;
	WritePackFloat(hPack, flStartTime_calc);
	//now we create the timer that will prevent the annoying double playback
	if ( (flNextTime_calc - 0.4) > 0 )
		CreateTimer( flNextTime_calc - 0.4 , Timer_MagEnd2, hPack);
	//and finally we set the end reload time into the gun so the player can actually shoot with it at the end
	flNextTime_calc += flGameTime;
	SetEntDataFloat(iEntid, g_iTimeIdleO, flNextTime_calc, true);
	SetEntDataFloat(iEntid, g_iNextPAttO, flNextTime_calc, true);
	SetEntDataFloat(client, g_iNextAttO, flNextTime_calc, true);
	#if DEBUG
	PrintToChatAll("\x03- post, calculated nextattack \x01%f\x03, gametime \x01%f\x03, retrieved nextattack\x01 %i %f\x03, retrieved time idle \x01%i %f",
		flNextTime_calc,
		flGameTime,
		g_iNextAttO,
		GetEntDataFloat(client,g_iNextAttO),
		g_iTimeIdleO,
		GetEntDataFloat(iEntid,g_iTimeIdleO)
		);
	#endif
}

//called for autoshotguns
public Action Timer_AutoshotgunStart (Handle timer, Handle hPack)
{
	KillTimer(timer);
	if (IsServerProcessing() == false)
		return Plugin_Stop;

	ResetPack(hPack);
	int iCid = ReadPackCell(hPack);
	int iEntid = ReadPackCell(hPack);
	CloseHandle(hPack);
	hPack = CreateDataPack();
	WritePackCell(hPack, iCid);
	WritePackCell(hPack, iEntid);

	if (iCid <= 0
		|| iEntid <= 0
		|| IsValidEntity(iCid) == false
		|| IsValidEntity(iEntid) == false
		|| IsClientInGame(iCid) == false)
		return Plugin_Stop;

	#if DEBUG
	PrintToChatAll("\x03-autoshotgun detected, iEntid \x01%i\x03, startO \x01%i\x03, insertO \x01%i\x03, endO \x01%i",
		iEntid,
		g_iShotStartDurO,
		g_iShotInsertDurO,
		g_iShotEndDurO
		);
	PrintToChatAll("\x03- pre mod, start \x01%f\x03, insert \x01%f\x03, end \x01%f",
		g_fl_AutoS,
		g_fl_AutoI,
		g_fl_AutoE
		);
	#endif
		
	//then we set the new times in the gun
	SetEntDataFloat(iEntid,	g_iShotStartDurO,	g_fl_AutoS*g_fl_reload_rate,	true);
	SetEntDataFloat(iEntid,	g_iShotInsertDurO,	g_fl_AutoI*g_fl_reload_rate,	true);
	SetEntDataFloat(iEntid,	g_iShotEndDurO,		g_fl_AutoE*g_fl_reload_rate,	true);

	//we change the playback rate of the gun just so the player can "see" the gun reloading faster
	SetEntDataFloat(iEntid, g_iPlayRateO, 1.0/g_fl_reload_rate, true);

	//and then call a timer to periodically check whether the gun is still reloading or not to reset the animation
	//but first check the reload state; if it's 2, then it needs a pump/cock before it can shoot again, and thus needs more time
	if (g_i_L4D_12 == 2)
		CreateTimer(0.3,Timer_ShotgunEnd,hPack,TIMER_REPEAT);
	else if (g_i_L4D_12 == 1)
	{
		if (GetEntData(iEntid,g_iShotRelStateO)==2)
			CreateTimer(0.3, Timer_ShotgunEndCock, hPack, TIMER_REPEAT);
		else
			CreateTimer(0.3, Timer_ShotgunEnd, hPack, TIMER_REPEAT);
	}

	#if DEBUG
	PrintToChatAll("\x03- after mod, start \x01%f\x03, insert \x01%f\x03, end \x01%f",
		g_fl_AutoS,
		g_fl_AutoI,
		g_fl_AutoE
		);
	#endif

	return Plugin_Stop;
}

public Action Timer_SpasShotgunStart (Handle timer, Handle hPack)
{
	KillTimer(timer);
	if (IsServerProcessing() == false)
		return Plugin_Stop;

	ResetPack(hPack);
	int iCid = ReadPackCell(hPack);
	int iEntid = ReadPackCell(hPack);
	CloseHandle(hPack);
	hPack = CreateDataPack();
	WritePackCell(hPack, iCid);
	WritePackCell(hPack, iEntid);

	if (iCid <= 0
		|| iEntid <= 0
		|| IsValidEntity(iCid) == false
		|| IsValidEntity(iEntid) == false
		|| IsClientInGame(iCid) == false)
		return Plugin_Stop;

	#if DEBUG
	PrintToChatAll("\x03-autoshotgun detected, iEntid \x01%i\x03, startO \x01%i\x03, insertO \x01%i\x03, endO \x01%i",
		iEntid,
		g_iShotStartDurO,
		g_iShotInsertDurO,
		g_iShotEndDurO
		);
	PrintToChatAll("\x03- pre mod, start \x01%f\x03, insert \x01%f\x03, end \x01%f",
		g_fl_SpasS,
		g_fl_SpasI,
		g_fl_SpasE
		);
	#endif
		
	//then we set the new times in the gun
	SetEntDataFloat(iEntid,	g_iShotStartDurO,	g_fl_SpasS*g_fl_reload_rate,	true);
	SetEntDataFloat(iEntid,	g_iShotInsertDurO,	g_fl_SpasI*g_fl_reload_rate,	true);
	SetEntDataFloat(iEntid,	g_iShotEndDurO,		g_fl_SpasE*g_fl_reload_rate,	true);

	//we change the playback rate of the gun just so the player can "see" the gun reloading faster
	SetEntDataFloat(iEntid, g_iPlayRateO, 1.0/g_fl_reload_rate, true);

	//and then call a timer to periodically check whether the gun is still reloading or not to reset the animation
	//but first check the reload state; if it's 2, then it needs a pump/cock before it can shoot again, and thus needs more time
	CreateTimer(0.3, Timer_ShotgunEnd, hPack, TIMER_REPEAT);

	#if DEBUG
	PrintToChatAll("\x03- after mod, start \x01%f\x03, insert \x01%f\x03, end \x01%f",
		g_fl_SpasS,
		g_fl_SpasI,
		g_fl_SpasE
		);
	#endif

	return Plugin_Stop;
}

//called for pump/chrome shotguns
public Action Timer_PumpshotgunStart (Handle timer, Handle hPack)
{
	KillTimer(timer);
	if (IsServerProcessing() == false)
		return Plugin_Stop;

	ResetPack(hPack);
	int iCid = ReadPackCell(hPack);
	int iEntid = ReadPackCell(hPack);
	CloseHandle(hPack);
	hPack = CreateDataPack();
	WritePackCell(hPack, iCid);
	WritePackCell(hPack, iEntid);

	if (iCid <= 0
		|| iEntid <= 0
		|| IsValidEntity(iCid) == false
		|| IsValidEntity(iEntid) == false
		|| IsClientInGame(iCid) == false)
		return Plugin_Stop;

	#if DEBUG
	PrintToChatAll("\x03-pumpshotgun detected, iEntid \x01%i\x03, startO \x01%i\x03, insertO \x01%i\x03, endO \x01%i",
		iEntid,
		g_iShotStartDurO,
		g_iShotInsertDurO,
		g_iShotEndDurO
		);
	PrintToChatAll("\x03- pre mod, start \x01%f\x03, insert \x01%f\x03, end \x01%f",
		g_fl_PumpS,
		g_fl_PumpI,
		g_fl_PumpE
		);
	#endif

	//then we set the new times in the gun
	SetEntDataFloat(iEntid,	g_iShotStartDurO,	g_fl_PumpS*g_fl_reload_rate,	true);
	SetEntDataFloat(iEntid,	g_iShotInsertDurO,	g_fl_PumpI*g_fl_reload_rate,	true);
	SetEntDataFloat(iEntid,	g_iShotEndDurO,		g_fl_PumpE*g_fl_reload_rate,	true);

	//we change the playback rate of the gun just so the player can "see" the gun reloading faster
	SetEntDataFloat(iEntid, g_iPlayRateO, 1.0/g_fl_reload_rate, true);

	//and then call a timer to periodically check whether the gun is still reloading or not to reset the animation
	if (g_i_L4D_12 == 2)
		CreateTimer(0.3,Timer_ShotgunEnd,hPack,TIMER_REPEAT);
	else if (g_i_L4D_12 == 1)
	{
		if (GetEntData(iEntid,g_iShotRelStateO) == 2)
			CreateTimer(0.3, Timer_ShotgunEndCock, hPack, TIMER_REPEAT);
		else
			CreateTimer(0.3, Timer_ShotgunEnd, hPack, TIMER_REPEAT);
	}

	#if DEBUG
	PrintToChatAll("\x03- after mod, start \x01%f\x03, insert \x01%f\x03, end \x01%f",
		g_fl_PumpS,
		g_fl_PumpI,
		g_fl_PumpE
		);
	#endif

	return Plugin_Stop;
}
// ////////////////////////////////////////////////////////////////////////////
//this resets the playback rate on non-shotguns
public Action Timer_MagEnd (Handle timer, any iEntid)
{
	KillTimer(timer);
	if (IsServerProcessing() == false)
		return Plugin_Stop;

	#if DEBUG
	PrintToChatAll("\x03Reset playback, magazine loader");
	#endif

	if (iEntid <= 0
		|| IsValidEntity(iEntid) == false)
		return Plugin_Stop;

	SetEntDataFloat(iEntid, g_iPlayRateO, 1.0, true);

	return Plugin_Stop;
}

public Action Timer_MagEnd2 (Handle timer, Handle hPack)
{
	KillTimer(timer);
	if (IsServerProcessing() == false)
	{
		CloseHandle(hPack);
		return Plugin_Stop;
	}

	#if DEBUG
	PrintToChatAll("\x03Reset playback, magazine loader");
	#endif

	ResetPack(hPack);
	int iCid = ReadPackCell(hPack);
	float flStartTime_calc = ReadPackFloat(hPack);
	CloseHandle(hPack);

	if (iCid <= 0
		|| IsValidEntity(iCid) == false
		|| IsClientInGame(iCid) == false)
		return Plugin_Stop;

	//experimental, remove annoying double-playback
	int iVMid = GetEntDataEnt2(iCid,g_iViewModelO);
	SetEntDataFloat(iVMid, g_iVMStartTimeO, flStartTime_calc, true);

	#if DEBUG
	PrintToChatAll("\x03- end mag loader, icid \x01%i\x03 starttime \x01%f\x03 gametime \x01%f", iCid, flStartTime_calc, GetGameTime());
	#endif

	return Plugin_Stop;
}

public Action Timer_ShotgunEnd (Handle timer, Handle hPack)
{
	#if DEBUG
	PrintToChatAll("\x03-autoshotgun tick");
	#endif

	ResetPack(hPack);
	int iCid = ReadPackCell(hPack);
	int iEntid = ReadPackCell(hPack);

	if (IsServerProcessing() == false
		|| iCid <= 0
		|| iEntid <= 0
		|| IsValidEntity(iCid) == false
		|| IsValidEntity(iEntid) == false
		|| IsClientInGame(iCid) == false)
	{
		KillTimer(timer);
		return Plugin_Stop;
	}

	if (GetEntData(iEntid,g_iShotRelStateO)==0)
	{
		#if DEBUG
		PrintToChatAll("\x03-shotgun end reload detected");
		#endif

		SetEntDataFloat(iEntid, g_iPlayRateO, 1.0, true);

		//int iCid = GetEntPropEnt(iEntid,Prop_Data,"m_hOwner");
		float flTime = GetGameTime() + 0.2;
		SetEntDataFloat(iCid,	g_iNextAttO,	flTime,	true);
		SetEntDataFloat(iEntid,	g_iTimeIdleO,	flTime,	true);
		SetEntDataFloat(iEntid,	g_iNextPAttO,	flTime,	true);

		KillTimer(timer);
		CloseHandle(hPack);
		return Plugin_Stop;
	}

	return Plugin_Continue;
}
// ////////////////////////////////////////////////////////////////////////////
//since cocking requires more time, this function does
//exactly as the above, except it adds slightly more time
public Action Timer_ShotgunEndCock (Handle timer, any hPack)
{
	#if DEBUG
	PrintToChatAll("\x03-autoshotgun tick");
	#endif

	ResetPack(hPack);
	int iCid = ReadPackCell(hPack);
	int iEntid = ReadPackCell(hPack);

	if (IsServerProcessing() == false
		|| iCid <= 0
		|| iEntid <= 0
		|| IsValidEntity(iCid) == false
		|| IsValidEntity(iEntid) == false
		|| IsClientInGame(iCid) == false)
	{
		KillTimer(timer);
		return Plugin_Stop;
	}

	if (GetEntData(iEntid,g_iShotRelStateO) == 0)
	{
		#if DEBUG
		PrintToChatAll("\x03-shotgun end reload + cock detected");
		#endif

		SetEntDataFloat(iEntid, g_iPlayRateO, 1.0, true);

		//int iCid = GetEntPropEnt(iEntid,Prop_Data,"m_hOwner");
		float flTime = GetGameTime() + 1.0;
		SetEntDataFloat(iCid,	g_iNextAttO,	flTime,	true);
		SetEntDataFloat(iEntid,	g_iTimeIdleO,	flTime,	true);
		SetEntDataFloat(iEntid,	g_iNextPAttO,	flTime,	true);

		KillTimer(timer);
		CloseHandle(hPack);
		return Plugin_Stop;
	}

	return Plugin_Continue;
}
/* ***************************************************************************/
public void OnGameFrame()
{
	//If frames aren't being processed, don't bother.
	//Otherwise we get LAG or even disconnects on map changes, etc...
	if (IsServerProcessing() == false|| g_bIsLoading == true)
	{
		return;
	}
	else
	{
		MA_OnGameFrame();
		DT_OnGameFrame();
	}
}

public void OnMapEnd()
{
	ClearAll();
	g_bIsLoading = true;
}

void RebuildAll ()
{
	MA_Rebuild();
	DT_Rebuild();
}

void ClearAll ()
{
	MA_Clear();
	DT_Clear();
}
// ////////////////////////////////////////////////////////////////////////////
//called whenever the registry needs to be rebuilt to cull any players who have left or died, etc.
//resets survivor's speeds and reassigns speed boost
//(called on: player death, player disconnect, adrenaline popped, adrenaline ended, -> change teams, convar change)
void MA_Rebuild ()
{
	//clears all DT-related vars
	MA_Clear();
	//if the server's not running or is in the middle of loading, stop
	if (IsServerProcessing()==false)
		return;
	#if DEBUG
	PrintToChatAll("\x03Rebuilding melee registry");
	#endif
	for (int iI = 1 ; iI <= MaxClients ; iI++)
	{
		if (IsClientInGame(iI) == true && IsPlayerAlive(iI) == true && GetClientTeam(iI) == 2 && g_usedhealth[iI] == 1)
		{
			g_iMARegisterCount++;
			g_iMARegisterIndex[g_iMARegisterCount]=iI;
			#if DEBUG
			PrintToChatAll("\x03-registering \x01%i",iI);
			#endif
		}
	}
}

//called to clear out registry and reset movement speeds
//(called on: round start, round end, map end)
void MA_Clear ()
{
	g_iMARegisterCount=0;
	#if DEBUG
	PrintToChatAll("\x03Clearing melee registry");
	#endif
	for (int iI = 1 ; iI <= MaxClients ; iI++)
	{
		g_iMARegisterIndex[iI] = -1;
	}
}
// ////////////////////////////////////////////////////////////////////////////
//called whenever the registry needs to be rebuilt to cull any players who have left or died, etc.
//(called on: player death, player disconnect, closet rescue, change teams)
void DT_Rebuild ()
{
	//clears all DT-related vars
	DT_Clear();

	//if the server's not running or is in the middle of loading, stop
	if (IsServerProcessing()==false)
		return;
	#if DEBUG
	PrintToChatAll("\x03Rebuilding weapon firing registry");
	#endif
	for (int iI = 1 ; iI <= MaxClients ; iI++)
	{
		if (IsClientInGame(iI) == true && IsPlayerAlive(iI) == true && GetClientTeam(iI) == 2 && g_usedhealth[iI] == 1)
		{
			g_iDTRegisterCount++;
			g_iDTRegisterIndex[g_iDTRegisterCount]=iI;
			#if DEBUG
			PrintToChatAll("\x03-registering \x01%i",iI);
			#endif
		}
	}
}

//called to clear out DT registry
//(called on: round start, round end, map end)
void DT_Clear ()
{
	g_iDTRegisterCount=0;
	#if DEBUG
	PrintToChatAll("\x03Clearing weapon firing registry");
	#endif
	for (int iI = 1 ; iI <= MaxClients ; iI++)
	{
		g_iDTRegisterIndex[iI] = -1;
		g_iDTEntid[iI] = -1;
		g_flDTNextTime[iI] = -1.0;
	}
}
/* ***************************************************************************/
//Since this is called EVERY game frame, we need to be careful not to run too many functions
//kinda hard, though, considering how many things we have to check for =.=
int MA_OnGameFrame()
{
	// if plugin is disabled, don't bother
	if (GetConVarInt(powerups_plugin_on) == 0)
		return 0;
	// or if no one has MA, don't bother either
	if (g_iMARegisterCount == 0)
		return 0;

	int iCid;
	//this tracks the player's ability id
	int iEntid;
	//this tracks the calculated next attack
	float flNextTime_calc;
	//this, on the other hand, tracks the current next attack
	float flNextTime_ret;
	//and this tracks the game time
	float flGameTime=GetGameTime();

	//theoretically, to get on the MA registry, all the necessary checks would have already
	//been run, so we don't bother with any checks here
	for (int iI = 1; iI <= g_iMARegisterCount; iI++)
	{
		//PRE-CHECKS 1: RETRIEVE VARS
		//---------------------------
		iCid = g_iMARegisterIndex[iI];
		//stop on this client when the next client id is null
		if (iCid <= 0) continue;
		if(!IsClientInGame(iCid)) continue;
		if(!IsClientConnected(iCid)) continue; 
		if (!IsPlayerAlive(iCid)) continue;
		if(GetClientTeam(iCid) != 2) continue;
		iEntid = GetEntDataEnt2(iCid,g_ActiveWeaponOffset);
		//if the retrieved gun id is -1, then...
		//wtf mate? just move on
		if (iEntid == -1) continue;
		//and here is the retrieved next attack time
		flNextTime_ret = GetEntDataFloat(iEntid,g_iNextPAttO);

		//CHECK 1: IS PLAYER USING A KNOWN NON-MELEE WEAPON?
		//--------------------------------------------------
		//as the title states... to conserve processing power,
		//if the player's holding a gun for a prolonged time
		//then we want to be able to track that kind of state
		//and not bother with any checks
		//checks: weapon is non-melee weapon
		//actions: do nothing
		if (iEntid == g_iMAEntid_notmelee[iCid])
		{
			// PrintToChatAll("\x03Client \x01%i\x03; non melee weapon, ignoring",iCid );
			continue;
		}

		//CHECK 1.5: THE PLAYER HASN'T SWUNG HIS WEAPON FOR A WHILE
		//---------------------------------------------------------
		//in this case, if the player made 1 swing of his 2 strikes, and then paused long enough, 
		//we should reset his strike count so his next attack will allow him to strike twice
		//checks: is the delay between attacks greater than 1.5s?
		//actions: set attack count to 0, and CONTINUE CHECKS
		if (g_iMAEntid[iCid] == iEntid
				&& g_iMAAttCount[iCid]!=0
				&& (flGameTime - flNextTime_ret) > 1.0)
		{
			#if DEBUG
			PrintToChatAll("\x03Client \x01%i\x03; hasn't swung weapon",iCid );
			#endif
			g_iMAAttCount[iCid]=0;
		}

		//CHECK 2: BEFORE ADJUSTED ATT IS MADE
		//------------------------------------
		//since this will probably be the case most of the time, we run this first
		//checks: weapon is unchanged; time of shot has not passed
		//actions: do nothing
		if (g_iMAEntid[iCid] == iEntid
				&& g_flMANextTime[iCid] >= flNextTime_ret)
		{
			// PrintToChatAll("\x03DT client \x01%i\x03; before shot made",iCid );
			continue;
		}

		//CHECK 3: AFTER ADJUSTED ATT IS MADE
		//------------------------------------
		//at this point, either a gun was swapped, or the attack time needs to be adjusted
		//checks: stored gun id same as retrieved gun id,
		//        and retrieved next attack time is after stored value
		//actions: adjusts next attack time
		if (g_iMAEntid[iCid] == iEntid
				&& g_flMANextTime[iCid] < flNextTime_ret)
		{
			//----DEBUG----
			//PrintToChatAll("\x03DT after adjusted shot\n-pre, client \x01%i\x03; entid \x01%i\x03; enginetime\x01 %f\x03; NextTime_orig \x01 %f\x03; interval \x01%f",iCid,iEntid,flGameTime,flNextTime_ret, flNextTime_ret-flGameTime );

			//this is a calculation of when the next primary attack will be after applying double tap values
			//flNextTime_calc = ( flNextTime_ret - flGameTime ) * g_flMA_attrate + flGameTime;
			flNextTime_calc = flGameTime + GetConVarFloat(g_h_melee_rate) ;
			// flNextTime_calc = flGameTime + melee_speed[iCid] ;

			//then we store the value
			g_flMANextTime[iCid] = flNextTime_calc;

			//and finally adjust the value in the gun
			SetEntDataFloat(iEntid, g_iNextPAttO, flNextTime_calc, true);

			#if DEBUG
			PrintToChatAll("\x03-post, NextTime_calc \x01 %f\x03; new interval \x01%f", GetEntDataFloat(iEntid,g_iNextPAttO), GetEntDataFloat(iEntid,g_iNextPAttO)-flGameTime );
			#endif

			continue;
		}

		//CHECK 4: CHECK THE WEAPON
		//-------------------------
		//lastly, at this point we need to check if we are, in fact, using a melee weapon =P
		//we check if the current weapon is the same one stored in memory; if it is, move on;
		//otherwise, check if it's a melee weapon - if it is, store and continue; else, continue.
		//checks: if the active weapon is a melee weapon
		//actions: store the weapon's entid into either
		//         the known-melee or known-non-melee variable

		#if DEBUG
		PrintToChatAll("\x03DT client \x01%i\x03; weapon switch inferred",iCid );
		#endif

		//check if the weapon is a melee
		char stName[32];
		GetEntityNetClass(iEntid,stName,32);
		if (StrEqual(stName,"CTerrorMeleeWeapon",false)==true)
		{
			//if yes, then store in known-melee var
			g_iMAEntid[iCid]=iEntid;
			g_flMANextTime[iCid]=flNextTime_ret;
			continue;
		}
		else
		{
			//if no, then store in known-non-melee var
			g_iMAEntid_notmelee[iCid]=iEntid;
			continue;
		}
	}
	return 0;
}
// ////////////////////////////////////////////////////////////////////////////
int DT_OnGameFrame()
{
	// if plugin is disabled, don't bother
	if (GetConVarInt(powerups_plugin_on) == 0)
		return;
	// or if no one has DT, don't bother either
	if (g_iDTRegisterCount == 0)
		return;

	//this tracks the player's id, just to make life less painful...
	int iCid;
	//this tracks the player's gun id since we adjust numbers on the gun, not the player
	int iEntid;
	//this tracks the calculated next attack
	float flNextTime_calc;
	//this, on the other hand, tracks the current next attack
	float flNextTime_ret;
	//and this tracks next melee attack times
	float flNextTime2_ret;
	//and this tracks the game time
	float flGameTime=GetGameTime();

	//theoretically, to get on the DT registry all the necessary checks would have already
	//been run, so we don't bother with any checks here
	for (int iI = 1; iI <= g_iDTRegisterCount; iI++)
	{
		//PRE-CHECKS: RETRIEVE VARS
		//-------------------------
		iCid = g_iDTRegisterIndex[iI];
		//stop on this client when the next client id is null
		if (iCid <= 0) return;
		//skip this client if they're disabled
		//if (g_iPState[iCid] == 1) continue;

		//we have to adjust numbers on the gun, not the player so we get the active weapon id here
		iEntid = GetEntDataEnt2(iCid,g_iActiveWO);
		//if the retrieved gun id is -1, then...
		//wtf mate? just move on
		if (iEntid == -1) continue;
		//and here is the retrieved next attack time
		flNextTime_ret = GetEntDataFloat(iEntid,g_iNextPAttO);
		//and for retrieved next melee time
		flNextTime2_ret = GetEntDataFloat(iEntid,g_iNextSAttO);

		//DEBUG
		/*int iNextAttO = FindSendPropInfo("CTerrorPlayer","m_flNextAttack");
		int iIdleTimeO = FindSendPropInfo("CTerrorGun","m_flTimeWeaponIdle");
		PrintToChatAll("\x03DT, NextAttack \x01%i %f\x03, TimeIdle \x01%i %f",
			iNextAttO,
			GetEntDataFloat(iCid,iNextAttO),
			iIdleTimeO,
			GetEntDataFloat(iEntid,iIdleTimeO)
			);*/

		//CHECK 1: BEFORE ADJUSTED SHOT IS MADE
		//------------------------------------
		//since this will probably be the case most of the time, we run this first
		//checks: gun is unchanged; time of shot has not passed
		//actions: nothing
		if (g_iDTEntid[iCid] == iEntid
			&& g_flDTNextTime[iCid] >= flNextTime_ret)
		{
			//----DEBUG----
			//PrintToChatAll("\x03DT client \x01%i\x03; before shot made",iCid );
			continue;
		}

		//CHECK 2: INFER IF MELEEING
		//--------------------------
		//since we don't want to shorten the interval incurred after swinging, we try to guess when
		//a melee attack is made
		//checks: if melee attack time > engine time
		//actions: nothing
		if (flNextTime2_ret > flGameTime)
		{
			//----DEBUG----
			//PrintToChatAll("\x03DT client \x01%i\x03; melee attack inferred",iCid );
			continue;
		}

		//CHECK 3: AFTER ADJUSTED SHOT IS MADE
		//------------------------------------
		//at this point, either a gun was swapped, or the attack time needs to be adjusted
		//checks: stored gun id same as retrieved gun id, and retrieved next attack time is after stored value
		if (g_iDTEntid[iCid] == iEntid
			&& g_flDTNextTime[iCid] < flNextTime_ret)
		{
			#if DEBUG
			PrintToChatAll("\x03DT after adjusted shot\n-pre, client \x01%i\x03; entid \x01%i\x03; enginetime\x01 %f\x03; NextTime_orig \x01 %f\x03; interval \x01%f",iCid,iEntid,flGameTime,flNextTime_ret, flNextTime_ret-flGameTime );
			#endif
			//this is a calculation of when the next primary attack
			//will be after applying double tap values
			flNextTime_calc = ( flNextTime_ret - flGameTime ) * g_flDT_rate + flGameTime;

			//then we store the value
			g_flDTNextTime[iCid] = flNextTime_calc;

			//and finally adjust the value in the gun
			SetEntDataFloat(iEntid, g_iNextPAttO, flNextTime_calc, true);

			#if DEBUG
			PrintToChatAll("\x03-post, NextTime_calc \x01 %f\x03; new interval \x01%f",GetEntDataFloat(iEntid,g_iNextPAttO), GetEntDataFloat(iEntid,g_iNextPAttO)-flGameTime );
			#endif
			continue;
		}

		//CHECK 4: ON WEAPON SWITCH
		//-------------------------
		//at this point, the only reason DT hasn't fired should be that the weapon had switched
		//checks: retrieved gun id doesn't match stored id or stored id is null
		//actions: updates stored gun id and sets stored next attack time to retrieved value
		if (g_iDTEntid[iCid] != iEntid)
		{
			#if DEBUG
			PrintToChatAll("\x03DT client \x01%i\x03; weapon switch inferred", iCid );
			#endif
			//now we update the stored vars
			g_iDTEntid[iCid] = iEntid;
			g_flDTNextTime[iCid] = flNextTime_ret;
			continue;
		}
		#if DEBUG
		PrintToChatAll("\x03DT client \x01%i\x03; reached end of checklist...", iCid );
		#endif
	}
}

stock bool IsInGame(int client)
{
	if ( client < 1 || client > MaxClients ) return false;
	if ( !IsClientConnected( client )) return false;
	if ( !IsClientInGame( client )) return false;
	return true;
}