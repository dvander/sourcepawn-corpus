// ////////////////////////////////////////////////////////////////////////
//
// PLUGIN NAME: l4d2_adren_reload
//
// CREDITS: -tPoncho - Huge props for the fast reload code
//			-AlliedModders Wiki - for all the references
//			-Testers - of this Plugin
//
// NOTES: -This plugin was written with Pawn Studio version 0.8.3
//
// VERSION: 1.0.5
//
// CHANGELOG: 1.0.0
//			  -Initial Release
//			  1.0.1
//			  -Added ConVar for toggling if adrenaline needed to be used
//			  1.0.2
//			  -Added a URL
//			  -Added support for giving Adrenaline at round start
//			  -Added an Admin command to give Adrenaline to everyone anytime
//			   (Requires CHEATS flag)
//			  1.0.3
//			  -Fixed the adrenaline toggling off not picking up
//			  1.0.4
//			  -I skipped it. Why? Because I can =D
//			  1.0.5
//			  -Added ConVar to toggle if plugin is active
//			  -Added ConVar to toggle if broadcasts will play on client connect
//			  -Added ConVar to toggle where broadcasts will play on client connect
//			  -Tweeked some commands to allow in-game changes
//			  -Fixed sm_giveadren showing up as an unknown command in console
//			  -Fixed the adrenaline toggling off (and on) not picking up *ahem* for real this time
//			  -Added convar to determine how long the duration of adrenaline reload lasts
//			   (This does not apply to the convar 'adrenaline_duration')
//			   (Will be adding one that affects that convar soon...)
//			  -Added a timer in hint box counting down how many seconds remains
//			  -Added a debugging definition for easier debugs
//
// TO DO: -Clean up my coding (about 50% done)
//		  -Fix those Tag mismatches somehow...
//		  -Add support for L4D1?
//		  -Add support for double melee swing?
//		  -Add support for faster weapon firing?
//		  -Add support for pills?
//
// ////////////////////////////////////////////////////////////////////////

#define PLUGIN_VERSION "1.0.5"
//Set this value to 1 to enable debugging
#define DEBUG 0

#include <sourcemod>
#include <sdktools>

// Reload rate
new Float:g_fl_reload_rate;
new Handle:g_h_reload_rate;

//This keeps track of the default values for
//reload speeds for the different shotgun types
//NOTE: I got these values from tPoncho's own source
//NOTE: Pump and Chrome have identical values
const Float:g_fl_AutoS = 0.666666;
const Float:g_fl_AutoI = 0.4;
const Float:g_fl_AutoE = 0.675;
const Float:g_fl_SpasS = 0.5;
const Float:g_fl_SpasI = 0.375;
const Float:g_fl_SpasE = 0.699999;
const Float:g_fl_PumpS = 0.5;
const Float:g_fl_PumpI = 0.5;
const Float:g_fl_PumpE = 0.6;

//tracks if the game is L4D 2 (Support for L4D1 pending...)
new g_i_L4D_12 = 0;

//offsets
new g_iNextPAttO		= -1;
new g_iActiveWO			= -1;
new g_iShotStartDurO	= -1;
new g_iShotInsertDurO	= -1;
new g_iShotEndDurO		= -1;
new g_iPlayRateO		= -1;
new g_iShotRelStateO	= -1;
new g_iNextAttO			= -1;
new g_iTimeIdleO		= -1;
new g_iVMStartTimeO		= -1;
new g_iViewModelO		= -1;

//tracks if the client has used an adrenaline for that duration
new g_usedadren[MAXPLAYERS + 1] = 0;

//Timer definitions
new Handle: WelcomeTimers[MAXPLAYERS + 1];
new Handle: g_adrentimer[MAXPLAYERS + 1];
new Handle: g_adrencountdown[MAXPLAYERS + 1];
new Handle: g_adrentimeleft[MAXPLAYERS + 1];

//Enables and Disables
new Handle: adren_plugin_on;
new Handle: adren_broadcast_on;
new Handle: adren_broadcast_type;
new Handle: adren_use_on;
new Handle: adren_give_on;

//Numbers
new Handle: adren_duration;

public Plugin:myinfo = 
{
	name = "[L4D2] Adrenaline reload",
	author = "Dusty1029 (a.k.a. {L.2.K} LOL)",
	description = "When a client pops an adrenaline, during the duration, the reload speed is increased",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=122474"
}

public OnPluginStart()
{
	decl String:stGame[32];
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
		SetFailState("Mod only supports Left 4 Dead 2.");
	
	//ConVars
	RegAdminCmd("sm_giveadren", Command_GiveAdrenaline, ADMFLAG_CHEATS, "Gives Adrenaline to all Survivors.");
	
	CreateConVar(
		"l4d_adren_reload_version", 
		PLUGIN_VERSION, 
		"The version of the Adrenaline Reload Plugin.", 
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	adren_plugin_on = CreateConVar(
		"l4d_adren_plugin_on",
		"1" ,
		"Is the Plugin active? ( 1 = ON  0 = OFF )",
		FCVAR_PLUGIN|FCVAR_SPONLY, true, 0.0, true, 1.0);
	
	adren_broadcast_on = CreateConVar(
		"l4d_adren_broadcast_on",
		"1" ,
		"Should clients be notified when connecting to server about adrenaline? ( 1 = ON  0 = OFF )",
		FCVAR_PLUGIN|FCVAR_SPONLY, true, 0.0, true, 1.0);
	
	adren_broadcast_type = CreateConVar(
		"l4d_adren_broadcast_type",
		"1" ,
		"How are clients notified? ( 0 = CHAT  1 = HINT  2 = BOTH )",
		FCVAR_PLUGIN|FCVAR_SPONLY, true, 0.0, true, 2.0);
	
	adren_use_on = CreateConVar(
		"l4d_adren_use_on", 
		"1" , 
		"Should clients use adrenaline to get super reload? ( 1 = ON  0 = OFF )", 
		FCVAR_PLUGIN|FCVAR_SPONLY, true, 0.0, true, 1.0);
	
	adren_give_on = CreateConVar(
		"l4d_adren_give_on",
		"1",
		"Should clients be given adrenaline at round start? ( 1 = ON  0 = OFF )",
		FCVAR_PLUGIN|FCVAR_SPONLY, true, 0.0, true, 1.0);
	
	adren_duration = CreateConVar(
		"l4d_adren_duration",
		"15",
		"How long should the adrenaline reload duration last?",
		FCVAR_PLUGIN|FCVAR_NOTIFY, true, 1.0);
	
	g_h_reload_rate = CreateConVar(
		"l4d_adren_reload_rate" ,
		"0.5714" ,
		"The interval incurred by reloading is multiplied by this value (clamped between 0.2 < 0.9)" ,
		FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.2, true, 0.9);
	HookConVarChange(g_h_reload_rate, Convar_Reload);
	g_fl_reload_rate = 0.5714;
	
	//Event Hooks
	HookEvent("weapon_reload", Event_Reload);
	HookEvent("adrenaline_used", Event_AdrenalineUsed);
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
	
	//Execute or create cfg
	AutoExecConfig(true, "l4d2_adren_reload")
}

public Convar_Reload (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new Float:flF=StringToFloat(newValue);
	if (flF<0.02)
		flF=0.02;
	else if (flF>0.9)
		flF=0.9;
	g_fl_reload_rate = flF;
}

public OnClientPutInServer(client)
{
	g_usedadren[client] = 0;
	if (GetConVarInt(adren_use_on) == 0)
	{
		g_usedadren[client] = 1;
	}
	if (client && !IsFakeClient(client))
	{
		WelcomeTimers[client] = CreateTimer(5.0, Timer_Notify, client)
	}
}

/*public OnClientDisconnect(client)
{
	if (WelcomeTimers[client] != INVALID_HANDLE)
	{
		KillTimer(WelcomeTimers[client])
		WelcomeTimers[client] = INVALID_HANDLE
	}
}*/

public Action:Timer_Notify(Handle:Timer, any:client)
{
	if (GetConVarBool(adren_plugin_on))
	{
		if (GetConVarBool(adren_broadcast_on))
		{
			if (GetConVarBool(adren_use_on))
			{
				if (GetConVarInt(adren_broadcast_type) == 0)
				{
					PrintToChat(client, "\x04[SM] \x01In this server, using the \x04Adrenaline \x01will grant a reload speed bonus during that duration");
				}
				else if (GetConVarInt(adren_broadcast_type) == 1)
				{
					PrintHintText(client, "In this server, using the Adrenaline will grant\na reload speed bonus during that duration");
				}
				else if (GetConVarInt(adren_broadcast_type) == 2)
				{
					PrintToChat(client, "\x04[SM] \x01In this server, using the \x04Adrenaline \x01will grant a reload speed bonus during that duration");
					PrintHintText(client, "In this server, using the Adrenaline will grant\na reload speed bonus during that duration");
				}
			}
			else if (!GetConVarBool(adren_use_on))
			{
				if (GetConVarInt(adren_broadcast_type) == 0)
				{
					PrintToChat(client, "\x04[SM] \x01In this server, reload speed is increased!");
				}
				else if (GetConVarInt(adren_broadcast_type) == 1)
				{
					PrintHintText(client, "In this server, reload speed is increased!");
				}
				else if (GetConVarInt(adren_broadcast_type) == 2)
				{
					PrintToChat(client, "\x04[SM] \x01In this server, reload speed is increased!");
					PrintHintText(client, "In this server, reload speed is increased!");
				}
			}
		}
	}
	
	return Plugin_Stop
}

//Round start
public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(30.0, Timer_GiveAdrenaline);
	#if DEBUG
	CreateTimer(2.0, Timer_Debugging);
	#endif
}

public Action:Timer_Debugging(Handle:timer)
{
	PrintToChatAll("\x04[DEBUG] \x03Debugging enabled!");
	if (GetConVarInt(adren_use_on) == 0)
	{
		PrintToChatAll("\x03Detected adrenaline usage: \x01Off");
	}
	if (GetConVarInt(adren_use_on) == 1)
	{
		PrintToChatAll("\x03Detected adrenaline usage: \x01On");
		PrintToChatAll("\x03Retrieving value of adrenaline duration: \x01%d", GetConVarInt(adren_duration));
	}
	if (GetConVarInt(adren_give_on) == 0)
	{
		PrintToChatAll("\x03Detected round start adrenaline giving: \x01Off");
	}
	if (GetConVarInt(adren_give_on) == 1)
	{
		PrintToChatAll("\x03Detected round start adrenaline giving: \x01On");
	}
}

public Action:Timer_GiveAdrenaline(Handle:timer)
{
	if (GetConVarBool(adren_plugin_on))
	{
		if (GetConVarInt(adren_give_on) == 1)
		{
			GiveAdrenalineToAll()
		}
	}
}

public Action:Command_GiveAdrenaline(client, args)
{
	GiveAdrenalineToAll()
	return Plugin_Handled;
}


public GiveAdrenalineToAll()
{
	new flags = GetCommandFlags("give");	
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			FakeClientCommand(i, "give adrenaline");
			PrintToChat(i, "\x04[SM] \x01Grabbin' \x04Adrenaline");
		}
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}

//Popping the Adrenaline
public Event_AdrenalineUsed (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(adren_plugin_on))
	{
		new client = GetClientOfUserId(GetEventInt(event,"userid"));
		if (client == 0)
		{
			return;
		}
		else
		{
			if (GetConVarBool(adren_use_on))
			{
				//We need to reset the timer in case the client decides to
				//use a second adrenaline while the first one is still active
				if (g_usedadren[client] == 1)
				{
					KillTimer(g_adrentimer[client])
					KillTimer(g_adrencountdown[client])
					#if DEBUG
					PrintToChat(client, "\x04[DEBUG] \x03Resetting adrenaline timers");
					#endif
					g_usedadren[client] = 0;
				}
				//A delay of 0.1 second to reset the reload speed. Not like
				//you'll be able to pull out your gun fast enough :P
				CreateTimer(0.1, Timer_AdrenUsed, client, TIMER_FLAG_NO_MAPCHANGE);
				g_adrencountdown[client] = CreateTimer(1.0, AdrenCountdown, client, TIMER_REPEAT);
				g_adrentimer[client] = CreateTimer(GetConVarInt(adren_duration) * 1.0, Timer_AdrenEnd, client, TIMER_FLAG_NO_MAPCHANGE);
				//Multiply by 1.0 to prevent tag mismatch
			}
		}
	}
}

public Action:Timer_AdrenUsed(Handle:Timer, any:client)
{
	if (GetConVarBool(adren_use_on))
	{
		PrintToChat(client, "\x04[SM] \x01Reload speed increased!");
		PrintHintText(client, "Reload speed time left: %d", GetConVarInt(adren_duration));
		g_adrentimeleft[client] = GetConVarInt(adren_duration);
		g_adrentimeleft[client] -= 1;
		g_usedadren[client] = 1
	}
}

public Action:Timer_AdrenEnd(Handle:Timer, any:client)
{
	if (GetConVarBool(adren_use_on))
	{
		PrintToChat(client, "\x04[SM] \x01Reload speed returning to normal...");
		g_usedadren[client] = 0
	}
}

public Action:AdrenCountdown(Handle:timer, any:client)
{
	if(g_adrentimeleft[client] == 0) //Adrenaline ran out
	{
		PrintHintText(client,"Reload speed returning to normal...");
		g_adrentimeleft[client] = GetConVarInt(adren_duration);
		return Plugin_Stop;
	}
	else //Countdown progress
	{
		PrintHintText(client,"Reload speed time left: %d", g_adrentimeleft[client]);
		g_adrentimeleft[client] -= 1;
		return Plugin_Continue;
	}
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.1, Timer_RoundEnd);
}

public Action:Timer_RoundEnd(Handle:Timer, any:client)
{
	if (GetConVarBool(adren_plugin_on))
	{
		if (GetConVarBool(adren_use_on))
		{
			if (g_usedadren[client] == 1)
			{
				KillTimer(g_adrencountdown[client])
				KillTimer(g_adrentimer[client])
				PrintToChat(client, "\x04[SM] \x01Reload speed returning to normal...");
				PrintHintText(client, "Reload speed returning to normal...");
				g_usedadren[client] = 0
			}
		}
	}
}

//Reloading weapon
public Event_Reload (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(adren_plugin_on))
	{
		new client = GetClientOfUserId(GetEventInt(event,"userid"));
		if (g_usedadren[client] == 1) //If client popped an Adrenaline
		{
			AdrenReload(client);
		}
		else //Obviously they haven't
		{
			return;
		}
	}
}

//On the start of a reload
AdrenReload (client)
{
	if (GetClientTeam(client) == 2)
	{
		#if DEBUG
		PrintToChatAll("\x03Client \x01%i\x03; start of reload detected",client );
		#endif

		new iEntid = GetEntDataEnt2(client, g_iActiveWO);
		if (IsValidEntity(iEntid)==false) return;

		decl String:stClass[32];
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

		//shotguns are a bit trickier since the game
		//tracks per shell inserted - and there's TWO
		//different shotguns with different values...
		else if (StrContains(stClass,"autoshotgun",false) != -1)
		{
			//crate a pack to send clientid and gunid through to the timer
			new Handle:hPack = CreateDataPack();
			WritePackCell(hPack, client);
			WritePackCell(hPack, iEntid);

			CreateTimer(0.1,Timer_AutoshotgunStart,hPack);
			return;
		}

		else if (StrContains(stClass,"shotgun_spas",false) != -1)
		{
			//crate a pack to send clientid and gunid through to the timer
			new Handle:hPack = CreateDataPack();
			WritePackCell(hPack, client);
			WritePackCell(hPack, iEntid);

			CreateTimer(0.1,Timer_SpasShotgunStart,hPack);
			return;
		}

		else if (StrContains(stClass,"pumpshotgun",false) != -1
			|| StrContains(stClass,"shotgun_chrome",false) != -1)
		{
			//crate a pack to send clientid and gunid through to the timer
			new Handle:hPack = CreateDataPack();
			WritePackCell(hPack, client);
			WritePackCell(hPack, iEntid);

			CreateTimer(0.1,Timer_PumpshotgunStart,hPack);
			return;
		}
	}
}

//called for mag loaders
MagStart (iEntid, client)
{
	#if DEBUG
	PrintToChatAll("\x05-magazine loader detected,\x03 gametime \x01%f", GetGameTime());
	#endif

	new Float:flGameTime = GetGameTime();
	new Float:flNextTime_ret = GetEntDataFloat(iEntid,g_iNextPAttO);

	#if DEBUG
	PrintToChatAll("\x03- pre, gametime \x01%f\x03, retrieved nextattack\x01 %i %f\x03, retrieved time idle \x01%i %f",
		flGameTime,
		g_iNextAttO,
		GetEntDataFloat(client,g_iNextAttO),
		g_iTimeIdleO,
		GetEntDataFloat(iEntid,g_iTimeIdleO)
		);
	#endif

	//this is a calculation of when the next primary attack
	//will be after applying reload values
	//NOTE: at this point, only calculate the interval itself,
	//without the actual game engine time factored in
	new Float:flNextTime_calc = ( flNextTime_ret - flGameTime ) * g_fl_reload_rate ;

	//we change the playback rate of the gun
	//just so the player can "see" the gun reloading faster
	SetEntDataFloat(iEntid, g_iPlayRateO, 1.0/g_fl_reload_rate, true);

	//create a timer to reset the playrate after
	//time equal to the modified attack interval
	CreateTimer( flNextTime_calc, Timer_MagEnd, iEntid);

	//experiment to remove double-playback bug
	new Handle:hPack = CreateDataPack();
	WritePackCell(hPack, client);
	//this calculates the equivalent time for the reload to end
	new Float:flStartTime_calc = flGameTime - ( flNextTime_ret - flGameTime ) * ( 1 - g_fl_reload_rate ) ;
	WritePackFloat(hPack, flStartTime_calc);
	//now we create the timer that will prevent the annoying double playback
	if ( (flNextTime_calc - 0.4) > 0 )
		CreateTimer( flNextTime_calc - 0.4 , Timer_MagEnd2, hPack);

	//and finally we set the end reload time into the gun
	//so the player can actually shoot with it at the end
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
public Action:Timer_AutoshotgunStart (Handle:timer, Handle:hPack)
{
	KillTimer(timer);
	if (IsServerProcessing()==false)
		return Plugin_Stop;

	ResetPack(hPack);
	new iCid = ReadPackCell(hPack);
	new iEntid = ReadPackCell(hPack);
	CloseHandle(hPack);
	hPack = CreateDataPack();
	WritePackCell(hPack, iCid);
	WritePackCell(hPack, iEntid);

	if (iCid <= 0
		|| iEntid <= 0
		|| IsValidEntity(iCid)==false
		|| IsValidEntity(iEntid)==false
		|| IsClientInGame(iCid)==false)
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

	//we change the playback rate of the gun
	//just so the player can "see" the gun reloading faster
	SetEntDataFloat(iEntid, g_iPlayRateO, 1.0/g_fl_reload_rate, true);

	//and then call a timer to periodically check whether the
	//gun is still reloading or not to reset the animation
	//but first check the reload state; if it's 2, then it
	//needs a pump/cock before it can shoot again, and thus
	//needs more time
	if (g_i_L4D_12 == 2)
		CreateTimer(0.3,Timer_ShotgunEnd,hPack,TIMER_REPEAT);
	else if (g_i_L4D_12 == 1)
	{
		if (GetEntData(iEntid,g_iShotRelStateO)==2)
			CreateTimer(0.3,Timer_ShotgunEndCock,hPack,TIMER_REPEAT);
		else
			CreateTimer(0.3,Timer_ShotgunEnd,hPack,TIMER_REPEAT);
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

public Action:Timer_SpasShotgunStart (Handle:timer, Handle:hPack)
{
	KillTimer(timer);
	if (IsServerProcessing()==false)
		return Plugin_Stop;

	ResetPack(hPack);
	new iCid = ReadPackCell(hPack);
	new iEntid = ReadPackCell(hPack);
	CloseHandle(hPack);
	hPack = CreateDataPack();
	WritePackCell(hPack, iCid);
	WritePackCell(hPack, iEntid);

	if (iCid <= 0
		|| iEntid <= 0
		|| IsValidEntity(iCid)==false
		|| IsValidEntity(iEntid)==false
		|| IsClientInGame(iCid)==false)
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

	//we change the playback rate of the gun
	//just so the player can "see" the gun reloading faster
	SetEntDataFloat(iEntid, g_iPlayRateO, 1.0/g_fl_reload_rate, true);

	//and then call a timer to periodically check whether the
	//gun is still reloading or not to reset the animation
	//but first check the reload state; if it's 2, then it
	//needs a pump/cock before it can shoot again, and thus
	//needs more time
	CreateTimer(0.3,Timer_ShotgunEnd,hPack,TIMER_REPEAT);

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
public Action:Timer_PumpshotgunStart (Handle:timer, Handle:hPack)
{
	KillTimer(timer);
	if (IsServerProcessing()==false)
		return Plugin_Stop;

	ResetPack(hPack);
	new iCid = ReadPackCell(hPack);
	new iEntid = ReadPackCell(hPack);
	CloseHandle(hPack);
	hPack = CreateDataPack();
	WritePackCell(hPack, iCid);
	WritePackCell(hPack, iEntid);

	if (iCid <= 0
		|| iEntid <= 0
		|| IsValidEntity(iCid)==false
		|| IsValidEntity(iEntid)==false
		|| IsClientInGame(iCid)==false)
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

	//we change the playback rate of the gun
	//just so the player can "see" the gun reloading faster
	SetEntDataFloat(iEntid, g_iPlayRateO, 1.0/g_fl_reload_rate, true);

	//and then call a timer to periodically check whether the
	//gun is still reloading or not to reset the animation
	if (g_i_L4D_12 == 2)
		CreateTimer(0.3,Timer_ShotgunEnd,hPack,TIMER_REPEAT);
	else if (g_i_L4D_12 == 1)
	{
		if (GetEntData(iEntid,g_iShotRelStateO)==2)
			CreateTimer(0.3,Timer_ShotgunEndCock,hPack,TIMER_REPEAT);
		else
			CreateTimer(0.3,Timer_ShotgunEnd,hPack,TIMER_REPEAT);
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

//this resets the playback rate on non-shotguns
public Action:Timer_MagEnd (Handle:timer, any:iEntid)
{
	KillTimer(timer);
	if (IsServerProcessing()==false)
		return Plugin_Stop;

	#if DEBUG
	PrintToChatAll("\x03Reset playback, magazine loader");
	#endif

	if (iEntid <= 0
		|| IsValidEntity(iEntid)==false)
		return Plugin_Stop;

	SetEntDataFloat(iEntid, g_iPlayRateO, 1.0, true);

	return Plugin_Stop;
}

public Action:Timer_MagEnd2 (Handle:timer, Handle:hPack)
{
	KillTimer(timer);
	if (IsServerProcessing()==false)
	{
		CloseHandle(hPack);
		return Plugin_Stop;
	}

	#if DEBUG
	PrintToChatAll("\x03Reset playback, magazine loader");
	#endif

	ResetPack(hPack);
	new iCid = ReadPackCell(hPack);
	new Float:flStartTime_calc = ReadPackFloat(hPack);
	CloseHandle(hPack);

	if (iCid <= 0
		|| IsValidEntity(iCid)==false
		|| IsClientInGame(iCid)==false)
		return Plugin_Stop;

	//experimental, remove annoying double-playback
	new iVMid = GetEntDataEnt2(iCid,g_iViewModelO);
	SetEntDataFloat(iVMid, g_iVMStartTimeO, flStartTime_calc, true);

	#if DEBUG
	PrintToChatAll("\x03- end mag loader, icid \x01%i\x03 starttime \x01%f\x03 gametime \x01%f", iCid, flStartTime_calc, GetGameTime());
	#endif

	return Plugin_Stop;
}

public Action:Timer_ShotgunEnd (Handle:timer, Handle:hPack)
{
	#if DEBUG
	PrintToChatAll("\x03-autoshotgun tick");
	#endif

	ResetPack(hPack);
	new iCid = ReadPackCell(hPack);
	new iEntid = ReadPackCell(hPack);

	if (IsServerProcessing()==false
		|| iCid <= 0
		|| iEntid <= 0
		|| IsValidEntity(iCid)==false
		|| IsValidEntity(iEntid)==false
		|| IsClientInGame(iCid)==false)
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

		//new iCid=GetEntPropEnt(iEntid,Prop_Data,"m_hOwner");
		new Float:flTime=GetGameTime()+0.2;
		SetEntDataFloat(iCid,	g_iNextAttO,	flTime,	true);
		SetEntDataFloat(iEntid,	g_iTimeIdleO,	flTime,	true);
		SetEntDataFloat(iEntid,	g_iNextPAttO,	flTime,	true);

		KillTimer(timer);
		CloseHandle(hPack);
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

//since cocking requires more time, this function does
//exactly as the above, except it adds slightly more time
public Action:Timer_ShotgunEndCock (Handle:timer, any:hPack)
{
	#if DEBUG
	PrintToChatAll("\x03-autoshotgun tick");
	#endif

	ResetPack(hPack);
	new iCid = ReadPackCell(hPack);
	new iEntid = ReadPackCell(hPack);

	if (IsServerProcessing()==false
		|| iCid <= 0
		|| iEntid <= 0
		|| IsValidEntity(iCid)==false
		|| IsValidEntity(iEntid)==false
		|| IsClientInGame(iCid)==false)
	{
		KillTimer(timer);
		return Plugin_Stop;
	}

	if (GetEntData(iEntid,g_iShotRelStateO)==0)
	{
		#if DEBUG
		PrintToChatAll("\x03-shotgun end reload + cock detected");
		#endif

		SetEntDataFloat(iEntid, g_iPlayRateO, 1.0, true);

		//new iCid=GetEntPropEnt(iEntid,Prop_Data,"m_hOwner");
		new Float:flTime= GetGameTime() + 1.0;
		SetEntDataFloat(iCid,	g_iNextAttO,	flTime,	true);
		SetEntDataFloat(iEntid,	g_iTimeIdleO,	flTime,	true);
		SetEntDataFloat(iEntid,	g_iNextPAttO,	flTime,	true);

		KillTimer(timer);
		CloseHandle(hPack);
		return Plugin_Stop;
	}

	return Plugin_Continue;
}