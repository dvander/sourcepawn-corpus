/*
* Ubercharged Setup (TF2) 
* Author(s): retsam
* File: ubercharged_setup.sp
* Description: Gives all medics specified ubercharge amount during setup period!
*
*
* 1.2 - Fixed a big issue with accidentally restricting ubers from being deployed on non-setup maps for the first 52 seconds(length of restriction period). woops!
*     - Removed the #include sdktools as its part of tf2_stocks.
*      
* 1.1 - Added small check to make sure admin flag cvar isnt set to nothing.
* 1.0 - Added an alive check for playerspawn hook. (I guess I forgot playerspawn is called upon joining a server?) Removed the printtoserver gamecheck msg.
* 0.9 - Fixed restriction not working if duration cvar was ending the period early. Raised restriction period slightly. Raised execdelay cvar value limit to 60 instead of 50.
* 0.8 - Removed the limit cvar. Added an execution delay timer cvar which allows admins to edit the delay time of main function timer. Added a restriction cvar. This uses OnPlayerRunCmd to check buttons and restrict use a bit more efficiently.
* 0.7 - Changed limit cvar so that it now tracks players actually using ubercharges in the period and not respawning. More efficiently aimed at players abusing stats.
* 0.6 - Fixed issue of ubercharge function firing during "waitingforplayers" time.
* 0.5 - Added a ubercharged respawn limit cvar. This was done to prevent abuse with stats plugins. Raised delay of round_active function to 2 seconds.
* 0.4 - Added adminonly cvar and flag. Added a duration cvar and can now specify how long the ubercharge setup period lasts.      
* 0.3 - Fixed incorrect post hook callbacks. Few small code fixes.
* 0.2 - Added displaymode cvar for notification messages(hinttext and centertext). Raised minimum amount to 25.
* 0.1	- Initial release. 
*/

#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.2"

new Handle:Cvar_Uber_Enabled = INVALID_HANDLE;
new Handle:Cvar_Uber_AdminFlag = INVALID_HANDLE;
new Handle:Cvar_Uber_AdminOnly = INVALID_HANDLE;
new Handle:Cvar_Uber_Amount = INVALID_HANDLE;
new Handle:Cvar_Uber_Sound = INVALID_HANDLE;
new Handle:Cvar_Uber_Displaymode = INVALID_HANDLE;
new Handle:Cvar_Uber_Duration = INVALID_HANDLE;
new Handle:Cvar_Uber_TimerDelay = INVALID_HANDLE;
new Handle:Cvar_Uber_Restrict = INVALID_HANDLE;

new g_iUbersCount[MAXPLAYERS + 1] = { 0, ... };

new g_uberAmount;
new g_uberAdminOnly;
new g_uberSoundEnabled;
new g_uberDisplayMode;
new g_uberRestriction;

new Float:g_fuberDuration;
new Float:g_fuberTimerDelay;

new bool:bIsPlayerAdmin[MAXPLAYERS + 1] = { false, ... };
new bool:g_bIsEnabled = true;
new bool:g_bInSetup = false;
new bool:g_bInRestrict = false;
new bool:g_bMapStart = false;

new String:g_sCharAdminFlag[32];

public Plugin:myinfo = 
{
	name = "Ubercharged Setup",
	author = "retsam",
	description = "Gives all medics specified ubercharge amount during setup period!",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1107776"
}

//**Credit to naris for this snippet**
new const String:Charged[][] = { "vo/medic_autochargeready01.wav",
	"vo/medic_autochargeready02.wav",
	"vo/medic_autochargeready03.wav"};

public OnPluginStart()
{
	CheckGame();

	CreateConVar("sm_ubersetup_version", PLUGIN_VERSION, "Version of Ubercharged Setup", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	Cvar_Uber_Enabled = CreateConVar("sm_ubersetup_enabled", "1", "Enable ubercharged setup plugin?(1/0 = yes/no)");
	Cvar_Uber_AdminOnly = CreateConVar("sm_ubersetup_adminonly", "0", "Enable plugin for admins only? (1/0 = yes/no)");
	Cvar_Uber_AdminFlag = CreateConVar("sm_ubersetup_flag", "b", "Admin flag to use if adminonly is enabled (only one).  Must be a in char format.");
	Cvar_Uber_Amount = CreateConVar("sm_ubersetup_amount", "100.0", "Ubercharge percent amount to give medics in setup period.", _, true, 25.0, true, 100.0);
	Cvar_Uber_Sound = CreateConVar("sm_ubersetup_sound", "1", "Emit fully charged sound file from medic?(1/0 = yes/no) Note: Sound is only played if amount set to 100.");
	Cvar_Uber_Displaymode = CreateConVar("sm_ubersetup_displaymode", "1", "Display mode for notifying medics of uber amount.(0/1/2) 0=disabled, 1=hinttext(default), 2=centertext message.");
	Cvar_Uber_Duration = CreateConVar("sm_ubersetup_duration", "0.0", "Time in seconds after the execdelay cvar is fired, that the ubercharge setup period lasts. (0.0=disabled and will run length of default setup period, any number higher sets duration)", _, true, 0.0, true, 60.0);
	Cvar_Uber_TimerDelay = CreateConVar("sm_ubersetup_execdelay", "1.0", "Ubersetup execution delay timer. Time in seconds after setup starts to execute the main function.", _, true, 0.0, true, 60.0);
	Cvar_Uber_Restrict = CreateConVar("sm_ubersetup_restrict", "1", "Restrict ubercharge use during setup period to prevent abuse? (1/0 = yes/no)");

	HookEvent("player_spawn", hook_PlayerSpawn, EventHookMode_Post);
	HookEvent("teamplay_round_active", hook_RoundActive, EventHookMode_Post);
	HookEvent("teamplay_setup_finished", hook_SetupFinished, EventHookMode_Post);
	HookEvent("player_chargedeployed", hook_ChargeDeployed, EventHookMode_Post);
	
	HookConVarChange(Cvar_Uber_Enabled, Cvars_Changed);
	HookConVarChange(Cvar_Uber_AdminOnly, Cvars_Changed);
	HookConVarChange(Cvar_Uber_Amount, Cvars_Changed);
	HookConVarChange(Cvar_Uber_Sound, Cvars_Changed);
	HookConVarChange(Cvar_Uber_Displaymode, Cvars_Changed);
	HookConVarChange(Cvar_Uber_Duration, Cvars_Changed);
	HookConVarChange(Cvar_Uber_TimerDelay, Cvars_Changed);
	HookConVarChange(Cvar_Uber_Restrict, Cvars_Changed);

	AutoExecConfig(true, "plugin.ubercharged_setup");
}

public OnClientPostAdminCheck(client)
{
	if(IsValidAdmin(client, g_sCharAdminFlag))
	{
		bIsPlayerAdmin[client] = true;
	}
	else
	{
		bIsPlayerAdmin[client] = false;
	}
	
	g_iUbersCount[client] = 0;
}

public OnClientDisconnect(client)
{
	bIsPlayerAdmin[client] = false;
	g_iUbersCount[client] = 0;
}

public OnConfigsExecuted()
{
	g_bIsEnabled = GetConVarBool(Cvar_Uber_Enabled);
	GetConVarString(Cvar_Uber_AdminFlag, g_sCharAdminFlag, sizeof(g_sCharAdminFlag));

	g_uberAmount = GetConVarInt(Cvar_Uber_Amount);
	g_uberSoundEnabled = GetConVarInt(Cvar_Uber_Sound);
	g_uberDisplayMode = GetConVarInt(Cvar_Uber_Displaymode);
	g_uberAdminOnly = GetConVarInt(Cvar_Uber_AdminOnly);
	g_fuberDuration = GetConVarFloat(Cvar_Uber_Duration);
	g_fuberTimerDelay = GetConVarFloat(Cvar_Uber_TimerDelay);
	g_uberRestriction = GetConVarInt(Cvar_Uber_Restrict);
}

public OnMapStart()
{
	g_bInSetup = false;
	g_bInRestrict = false;
	g_bMapStart = true;

	for(new x = 0; x < sizeof(Charged); x++)
	PrecacheSound(Charged[x], true);
}

public hook_RoundActive(Handle:event, const String:name[], bool:dontBroadcast)
{
	//PrintToChatAll("Event: Round_Active Fired");
	//PrintToServer("Event: Round_Active Fired");

	if(!g_bIsEnabled)
	return;
	
	if(!g_bMapStart)
	{
		if(TF2_InSetup())
		{
			//PrintToServer("**Map HAS setup**");
			//PrintToChatAll("**Map HAS setup**");
			CreateTimer(g_fuberTimerDelay, Timer_EnableUberSetup, _, TIMER_FLAG_NO_MAPCHANGE);
			
			if(g_uberRestriction)
			{
				g_bInRestrict = true;
				CreateTimer(52.0, Timer_DisableRestriction, _, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		else
		{
			//PrintToServer("**Map DOES NOT HAVE setup**");
			//PrintToChatAll("**Map DOES NOT HAVE setup**");
			
			g_bInSetup = false;
		}
	}

	g_bMapStart = false;
}

public Action:Timer_EnableUberSetup(Handle:timer)
{
	g_bInSetup = true;
	
	if(g_fuberDuration > 0.0)
	{
		CreateTimer(g_fuberDuration, Timer_DisableUberSetup, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	for(new x = 1; x <= MaxClients; x++)
	{
		if(!IsClientInGame(x) || !IsPlayerAlive(x))
		{
			continue;
		}
		
		g_iUbersCount[x] = 0;
		//new TFClassType:class = TF2_GetPlayerClass(x);
		if(TF2_GetPlayerClass(x) != TFClass_Medic)
		{
			continue;
		}
		
		if((g_uberAdminOnly && !bIsPlayerAdmin[x]))
		{
			continue;
		}
		
		new uberchargeLevel = TF_GetUberLevel(x);
		if(uberchargeLevel >= g_uberAmount)
		{
			continue;
		}
		
		TF_SetUberLevel(x, g_uberAmount);
		
		if(g_uberSoundEnabled)
		{
			if(g_uberAmount == 100.0)
			{
				EmitSoundToAll(Charged[GetRandomInt(0,sizeof(Charged)-1)],x);
			}
		}
		
		switch(g_uberDisplayMode)
		{
		case 1:
			{
				if(g_uberAmount == 100.0)
				{
					PrintHintText(x, "Ubercharged!");
				}
				else
				{
					PrintHintText(x, "Ubercharge:  [ %i ]", g_uberAmount);
				}
			}
		case 2:
			{
				if(g_uberAmount == 100.0)
				{
					PrintCenterText(x, "Ubercharged!");
				}
				else
				{
					PrintCenterText(x, "Ubercharge:  [ %i ]", g_uberAmount);
				}
			}
		}
	}
}

public Action:Timer_DisableUberSetup(Handle:timer)
{
	//PrintToChatAll("Ubersetup Duration Timer Ended...");

	g_bInSetup = false;
}

public Action:Timer_DisableRestriction(Handle:timer)
{
	//PrintToChatAll("Ubersetup Restriction Period Ended.");

	g_bInRestrict = false;
}

public hook_SetupFinished(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bIsEnabled)
	return;

	//PrintToChatAll("Event: Setup_Finished Fired");

	g_bInSetup = false;
	g_bInRestrict = false;
	
	for(new x = 1; x <= MaxClients; x++)
	{
		if(!IsClientInGame(x))
		{
			continue;
		}
		
		if(g_iUbersCount[x] != 0)
		{
			g_iUbersCount[x] = 0;
		}
	}
}

public hook_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	//PrintToChatAll("Event: Spawn Fired");
	//PrintToServer("Event: Spawn Fired");

	if(!g_bIsEnabled || !g_bInSetup)
	return;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(client < 1 || !IsPlayerAlive(client))
	return;

	if((g_uberAdminOnly && !bIsPlayerAdmin[client]))
	return;

	//new TFClassType:class = TF2_GetPlayerClass(client);
	if(TF2_GetPlayerClass(client) == TFClass_Medic)
	{
		if(g_iUbersCount[client] == 0)
		{
			CreateTimer(0.5, Timer_GiveUberBuff, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			PrintToChat(client, "\x01[SM] Ubercharge setup abuse detected! You will not receive another uber!");
		}
	}
}

public hook_ChargeDeployed(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bInSetup || !g_uberRestriction)
	return;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(client < 1)
	return;

	g_iUbersCount[client]++;
}

public Action:Timer_GiveUberBuff(Handle:timer, any:client)
{
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
	return;
	
	//new TFClassType:class = TF2_GetPlayerClass(client);
	if(TF2_GetPlayerClass(client) != TFClass_Medic)
	return;
	
	TF_SetUberLevel(client, g_uberAmount);
	
	if(g_uberSoundEnabled)
	{
		if(g_uberAmount == 100.0)
		{
			EmitSoundToAll(Charged[GetRandomInt(0,sizeof(Charged)-1)],client);
		}
	}
	
	switch(g_uberDisplayMode)
	{
	case 1:
		{
			if(g_uberAmount == 100.0)
			{
				PrintHintText(client, "Ubercharged!");
			}
			else
			{
				PrintHintText(client, "Ubercharge:  [ %i ]", g_uberAmount);
			}
		}
	case 2:
		{
			if(g_uberAmount == 100.0)
			{
				PrintCenterText(client, "Ubercharged!");
			}
			else
			{
				PrintCenterText(client, "Ubercharge:  [ %i ]", g_uberAmount);
			}
		}
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{ 
	if(!g_bInRestrict || !g_uberRestriction)
	return Plugin_Continue;

	if(buttons & IN_ATTACK2)
	{
		if(TF2_GetPlayerClass(client) == TFClass_Medic)
		{
			if(TF_GetUberLevel(client) == 100.0)
			{
				TF_SetUberLevel(client, 99);
				PrintToChat(client, "\x01[SM] Deploying ubercharges during setup is NOT permitted!");
			}
		}
	}

	return Plugin_Continue;
}

stock TF_SetUberLevel(client, uberlevel)
{
	new index = GetPlayerWeaponSlot(client, 1);
	if(index > 0)
	{
		SetEntPropFloat(index, Prop_Send, "m_flChargeLevel", uberlevel*0.01);
	}
}

stock TF_GetUberLevel(client)
{
	new index = GetPlayerWeaponSlot(client, 1);
	if(index > 0)
	{
		return RoundFloat(GetEntPropFloat(index, Prop_Send, "m_flChargeLevel")*100);
	}
	else
	{
		return 0;
	}
}

//**Credit to Antithasys for map setup time detection!**
stock bool:TF2_InSetup()
{
	new iTimerEnt = FindEntityByClassname(-1, "team_round_timer");
	if(iTimerEnt != -1)
	{
		if(!GetEntProp(iTimerEnt, Prop_Send, "m_nState"))
		return true;
	}
	
	return false;
}

stock bool:IsValidAdmin(client, const String:flags[])
{
	if (!IsClientConnected(client))
	return false;
	
	new ibFlags = ReadFlagString(flags);
	if(!StrEqual(flags, ""))
	{
		if((GetUserFlagBits(client) & ibFlags) == ibFlags)
		{
			return true;
		}
	}
	
	if(GetUserFlagBits(client) & ADMFLAG_ROOT) 
	{
		return true;
	}
	
	return false;
}

CheckGame()
{
	new String:strGame[10];
	GetGameFolderName(strGame, sizeof(strGame));
	
	if(!StrEqual(strGame, "tf"))
	{
		SetFailState("[uberchargesetup] Detected game other than [TF2], plugin disabled.");
	}
}

public Cvars_Changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == Cvar_Uber_Enabled)
	{
		if(StringToInt(newValue) == 0)
		{
			g_bIsEnabled = false;
			g_bInSetup = false;
			UnhookEvent("player_spawn", hook_PlayerSpawn, EventHookMode_Post);
			UnhookEvent("teamplay_round_active", hook_RoundActive, EventHookMode_Post);
			UnhookEvent("teamplay_setup_finished", hook_SetupFinished, EventHookMode_Post);
			UnhookEvent("player_chargedeployed", hook_ChargeDeployed, EventHookMode_Post);
		}
		else
		{
			g_bIsEnabled = true;
			HookEvent("player_spawn", hook_PlayerSpawn, EventHookMode_Post);
			HookEvent("teamplay_round_active", hook_RoundActive, EventHookMode_Post);
			HookEvent("teamplay_setup_finished", hook_SetupFinished, EventHookMode_Post);
			HookEvent("player_chargedeployed", hook_ChargeDeployed, EventHookMode_Post);
		}
	}
	else if(convar == Cvar_Uber_Amount)
	{
		g_uberAmount = StringToInt(newValue);
	}
	else if(convar == Cvar_Uber_Sound)
	{
		g_uberSoundEnabled = StringToInt(newValue);
	}
	else if(convar == Cvar_Uber_Displaymode)
	{
		g_uberDisplayMode = StringToInt(newValue);
	}
	else if(convar == Cvar_Uber_AdminOnly)
	{
		g_uberAdminOnly = StringToInt(newValue);
	}
	else if(convar == Cvar_Uber_Duration)
	{
		g_fuberDuration = StringToFloat(newValue);
	}
	else if(convar == Cvar_Uber_TimerDelay)
	{
		g_fuberTimerDelay = StringToFloat(newValue);
	}
	else if(convar == Cvar_Uber_Restrict)
	{
		g_uberRestriction = StringToInt(newValue);
	}
}
