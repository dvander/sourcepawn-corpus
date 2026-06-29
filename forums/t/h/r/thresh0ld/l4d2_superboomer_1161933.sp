/**
* SUPER BOOMER PLUGIN
* 
* Credits to: DJ_WEST for his Instructor Hint Code
* 			   ztar for his Particle Code
* 
* Version History
* ----------------------------------------
* 1.5 - Fixed Spacebar spam when charge has been activated. This prevents players from activating the charge multiple times, which can sometimes cause other clients to crash.
* 	  - Added new boomer ability to move while puking	
*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.5"
#define DEBUG_LOG 0
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

#define HINT_CROUCH 0
#define HINT_SPECIAL 1
//burning_character_e
//burning_wood_02
//env_fire_large
//gas_explosion_main
#define EFFECT_BOOMER_CHARGE 	"env_fire_large"
#define EFFECT_BOOMER_JUMP	 	"gas_explosion_pump"
#define EFFECT_BOOMER_LAND	 	"gas_explosion_main"
#define SOUND_CHARGE_SPECIALATK	"player/survivor/voice/mechanic/fall04.wav"
#define SOUND_CHARGE_FAIL		"plats/churchbell_end.wav"
#define SOUND_CHARGE_LAND 		"ambient/explosions/explode_3.wav"
#define SOUND_CHARGE_HANGTIME 	"player/survivor/voice/mechanic/fall02.wav"
#define SOUND_CHARGE_ACTIVATED 	"ambient/explosions/explode_1.wav"
#define SOUND_CHARGE_INIT 		"player/boomer/voice/warn/male_boomer_warning_13.wav"
#define SOUND_CHARGE_READY 		"player/boomer/voice/warn/male_boomer_warning_17.wav"

//#include "includes/constants.sp"
//#include "includes/functions.sp"

new Handle:g_hPEPathBoomerCharge = INVALID_HANDLE;
new Handle:g_hPEPathBoomerJump = INVALID_HANDLE;
new Handle:g_hPEPathBoomerLand = INVALID_HANDLE;
new Handle:g_hSEPathChargeSpecialatk = INVALID_HANDLE;
new Handle:g_hSEPathChargeFail = INVALID_HANDLE;
new Handle:g_hSEPathChargeLand = INVALID_HANDLE;
new Handle:g_hSEPathChargeHangtime = INVALID_HANDLE;
new Handle:g_hSEPathChargeActivated = INVALID_HANDLE;
new Handle:g_hSEPathChargeInit = INVALID_HANDLE;
new Handle:g_hSEPathChargeReady = INVALID_HANDLE;

new Handle:g_hDebug = INVALID_HANDLE;
new Handle:g_hChargeTime = INVALID_HANDLE;
new Handle:g_hChargeExpire = INVALID_HANDLE;
new Handle:g_hExplodeOnImpact = INVALID_HANDLE;
new Handle:g_hBoomTimer[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:g_hChargeEffects[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:g_hExpireCharge[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:g_hGravity = INVALID_HANDLE;
new Handle:g_hChargeEffectsEnabled = INVALID_HANDLE;
new Handle:g_hChargePEJump = INVALID_HANDLE;
new Handle:g_hChargePELand = INVALID_HANDLE;
new Handle:g_hChargePECharge = INVALID_HANDLE;
new Handle:g_hChargeSEJump = INVALID_HANDLE;
new Handle:g_hChargeSELand = INVALID_HANDLE;
new Handle:g_hChargeSECharge = INVALID_HANDLE;
new Handle:g_hChargeSEFail = INVALID_HANDLE;
new Handle:g_hChargeSESpecialAtk = INVALID_HANDLE;
new Handle:g_hChargeSEWarCry = INVALID_HANDLE;
new Handle:g_hHintType = INVALID_HANDLE;
new Handle:g_hSpecialAtkEnabled = INVALID_HANDLE;
new Handle:g_hPukeMoveEnabled = INVALID_HANDLE;

new bool:g_bIsHoldingSpecialAtk[MAXPLAYERS+1];
new bool:g_bIsHoldingJump[MAXPLAYERS+1];
new bool:g_bIsHoldingDuck[MAXPLAYERS+1];
new bool:g_bIsPlayerCharging[MAXPLAYERS+1];
new bool:g_bIsChargeActivated[MAXPLAYERS+1];
new bool:g_bIsPlayerCharged[MAXPLAYERS+1];
new bool:g_bPlayerJumped[MAXPLAYERS+1];
new bool:g_bChargeEffectsStarted[MAXPLAYERS+1];

new Float:g_flVomitFatigue= -1.0;
new g_iLaggedMovementO;
new g_GameInstructor[MAXPLAYERS+1];
new Float:g_iClientChargeDuration[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "Super Boomer",
	author = "thresh0ld [a.k.a SPOONMAN]",
	description = "Super Boomer",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1161933"
}

public OnPluginStart()
{
	decl String:gameInfo[12], Handle:l_hVersion;
	
	GetGameFolderName(gameInfo, sizeof(gameInfo))
	
	if (!StrEqual(gameInfo, "left4dead2"))
	{
		SetFailState("Super Boomer supports Left 4 Dead 2 only!")
	}
	
	//Convar Initialization
	l_hVersion = CreateConVar("sm_superboomer_version", PLUGIN_VERSION, "Super Boomer Version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|~FCVAR_NOTIFY);
	g_hDebug = CreateConVar("sm_sb_debug", "0", "Enable Debug Mode",_,true,0.0,true,2.0);
	g_hChargeTime = CreateConVar("sm_sb_chargetime", "5", "Number of seconds to wait before activating",_,true,0.0,true,60.0);
	g_hChargeExpire = CreateConVar("sm_sb_chargeexpire", "1.0", "Number of seconds to wait before charge expires",_,true,0.0,true,60.0);
	g_hExplodeOnImpact = CreateConVar("sm_sb_explode", "0", "Automatically Explode upon Impact",_,true,0.0,true,1.0);
	g_hChargeEffectsEnabled = CreateConVar("sm_sb_effects", "1", "Enable/Disable Charge Effects",_,true,0.0,true,1.0);
	g_hSpecialAtkEnabled = CreateConVar("sm_sb_specialattack", "1", "Enable/Disable Speed Drop",_,true,0.0,true,1.0);
	g_hPukeMoveEnabled = CreateConVar("sm_sb_pukemove", "1", "Enable/Disable Boomer moving while puking",_,true,0.0,true,1.0);
	
	g_hChargePEJump = CreateConVar("sm_sb_pejump", "1", "Enable/Disable Particle Effects when Jumping",_,true,0.0,true,1.0);
	g_hChargePELand = CreateConVar("sm_sb_peland", "1", "Enable/Disable Particle Effects when Landing",_,true,0.0,true,1.0);
	g_hChargePECharge = CreateConVar("sm_sb_pecharge", "0", "Enable/Disable Particle Effects when Charging",_,true,0.0,true,1.0);
	g_hChargeSEJump = CreateConVar("sm_sb_sejump", "1", "Enable/Disable Sound Effects when Jumping",_,true,0.0,true,1.0);
	g_hChargeSELand = CreateConVar("sm_sb_seland", "1", "Enable/Disable Sound Effects when Landing",_,true,0.0,true,1.0);
	g_hChargeSECharge = CreateConVar("sm_sb_secharge", "1", "Enable/Disable Sound Effects while Charging",_,true,0.0,true,1.0);
	g_hChargeSESpecialAtk = CreateConVar("sm_sb_sespecatk", "1", "Enable/Disable Sound Effects for Special Speed Attack",_,true,0.0,true,1.0);
	g_hGravity = CreateConVar("sm_sb_gravity", "0.06", "The gravity to set for the jump boost",_,true,0.0,true,100.0);
	g_hChargeSEFail = CreateConVar("sm_sb_sefail", "1", "Enable/Disable Sound Effects when a Charging attempt has failed",_,true,0.0,true,1.0);
	g_hHintType = CreateConVar("sm_sb_hint", "3", "Set which type of hints should be displayed for users (0 = Disable, 1 = Chat, 2 = Instructor Hint, 3 = Both)",_,true,0.0,true,3.0);
	g_hChargeSEWarCry = CreateConVar("sm_sb_sewarcry", "1", "Enable/Disable Sound Effects for War Cry (Occurs during the jump)",_,true,0.0,true,1.0);
	
	g_hPEPathBoomerCharge = CreateConVar("sm_sb_pathpe_charge", EFFECT_BOOMER_CHARGE, "Path of particle effect for Boomer Charge");
	g_hPEPathBoomerJump = CreateConVar("sm_sb_pathpe_jump", EFFECT_BOOMER_JUMP, "Path of particle effect for Boomer Jump");
	g_hPEPathBoomerLand = CreateConVar("sm_sb_pathpe_land", EFFECT_BOOMER_LAND, "Path of particle effect for Boomer Land");
	
	g_hSEPathChargeSpecialatk = CreateConVar("sm_sb_pathse_special", SOUND_CHARGE_SPECIALATK, "Path for sound effect on special attack ability");
	g_hSEPathChargeFail  = CreateConVar("sm_sb_pathse_fail", SOUND_CHARGE_FAIL, "Path for sound effect on charge fail");		
	g_hSEPathChargeLand  = CreateConVar("sm_sb_pathse_land", SOUND_CHARGE_LAND, "Path for sound effect on landing"); 		
	g_hSEPathChargeHangtime  = CreateConVar("sm_sb_pathse_warcry", SOUND_CHARGE_HANGTIME, "Path for sound effect on war cry"); 	
	g_hSEPathChargeActivated  = CreateConVar("sm_sb_pathse_jump", SOUND_CHARGE_ACTIVATED, "Path for sound effect on initial jump"); 	
	g_hSEPathChargeInit  = CreateConVar("sm_sb_pathse_charge", SOUND_CHARGE_INIT, "Path for sound effect on charging"); 		
	g_hSEPathChargeReady  = CreateConVar("sm_sb_pathse_ready", SOUND_CHARGE_READY, "Path for sound effect on charge ready indicator");
	g_flVomitFatigue	=	GetConVarFloat(FindConVar("z_vomit_fatigue"));
	
	//Entity Properties
	g_iLaggedMovementO = FindSendPropInfo("CTerrorPlayer","m_flLaggedMovementValue");
	
	//Event Hooks
	HookEvent("player_spawn",Event_PlayerSpawn);
	HookEvent("player_death",Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_jump",Event_PlayerJump, EventHookMode_Pre);
	HookEvent("player_team",Event_PlayerChangeTeam);
	HookEvent("player_bot_replace",Event_PlayerBotReplace);
	HookEvent("bot_player_replace",Event_BotPlayerReplace);	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	//HookEvent("player_hurt",Event_PlayerHurt);
	//HookEvent("ability_use", Event_AbilityUse);
	
	//Monitor Convar Changes
	HookConVarChange(g_hPukeMoveEnabled, ConVarChange_CallBack);
	
	SetConVarString(l_hVersion, PLUGIN_VERSION);
	
	AutoExecConfig(true, "l4d2_superboomer");
	
	Debug("Plugin has started");
}

public ConVarChange_CallBack(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (!StringToInt(newValue))
	{
		for (new i = 1; i < MaxClients; i++)
		{
			if (IsBoomer(i))
			{
				ResetVomitFatigueToClient(i);
			}
		}
	}
	else
	{
		for (new i = 1; i < MaxClients; i++)
		{
			if (IsBoomer(i))
			{
				ActivateMovePuke(i);
			}
		}		
	}
}

public OnMapStart()
{
	Debug("Map Started");
	InitPrecache();
	InitAll();
}

public OnClientDisconnect(client)
{
	Debug("Client Disconnected: %N", client);
	UnsetSuperBoomer(client);
}

InitAll()
{
	//Re-initialize super boomers when map has been re-started or plugin reloaded
	for (new i = 1; i < MaxClients; i++)
	{
		if (IsValidClient(i) && GetClientTeam(i) == TEAM_INFECTED)
		{
			InitSuperBoomer(i);
		}
	}	
}

UnsetAll()
{
	for (new i = 1; i < MaxClients; i++)
	{
		if (IsValidClient(i) && GetClientTeam(i) == TEAM_INFECTED)
		{
			UnsetSuperBoomer(i);
		}
	}		
}

InitSuperBoomer(client)
{
	if(IsValidEntity(client) && IsClientInGame(client))
	{
		if ((GetClientTeam(client) == 3) && (GetZombieClass(client) == 2))
		{		
			Debug("Initializing Super Boom for Player %N", client);
			
			UnsetSuperBoomer(client);
			
			g_iClientChargeDuration[client] = 0.0;
			g_hBoomTimer[client] = CreateTimer(1.0, ChargeTimer, client, TIMER_REPEAT);
			
			//Start hooking the client and monitor if the touches the ground, we reset the gravity
			SDKHook(client, SDKHook_StartTouch, SDKHook_Touch_Callback);
			
			Debug("+ Initialized Super boomer for client %N",client);
			
			if (GetConVarBool(g_hPukeMoveEnabled))
			{
				ActivateMovePuke(client);
			}
			else
			{
				ResetVomitFatigueToClient(client);
			}
		}
	}
	
	Debug("Super Boomer has been initialized for %N!", client);
}

ActivateMovePuke(client)
{
	Debug("Activating Move Puke to Client %N", client);
	SetConVarFloat(FindConVar("z_vomit_fatigue"),0.0,false,false);
	SetEntDataFloat(client,g_iLaggedMovementO, 1.0,true);	
}

ResetVomitFatigueToClient(client)
{
	new Handle:hCvar=FindConVar("z_vomit_fatigue");
	ResetConVar(hCvar,false,false);
	g_flVomitFatigue=GetConVarFloat(hCvar);
	Debug("Resetting Vomit Fatigue Value = %f", GetConVarFloat(hCvar));	
	Debug("Resetting lag movement");
	SetEntDataFloat(client,g_iLaggedMovementO, 1.0,true);
}

//Completly Remove Super Boom for Player
UnsetSuperBoomer(client)
{
	if (IsValidClient(client) && GetClientTeam(client) == TEAM_INFECTED && GetZombieClass(client) == 2)
	{
		ResetVomitFatigueToClient(client);
		Debug("Player %N...Unhooking Super Boomer",client);
		ResetCharge(client, true);
		if (g_hBoomTimer[client] != INVALID_HANDLE)
		{
			KillTimer(g_hBoomTimer[client]);
			g_hBoomTimer[client] = INVALID_HANDLE;
		}
		SDKUnhook(client,SDKHook_StartTouch,SDKHook_Touch_Callback);
		SetConVarFloat(FindConVar("z_vomit_fatigue"), g_flVomitFatigue ,false,false);
	}	
}

InitPrecache()
{	
	decl String:buffer[PLATFORM_MAX_PATH];
	
	GetConVarString(g_hPEPathBoomerCharge, buffer, sizeof(buffer));
	PrecacheParticle(buffer);
	GetConVarString(g_hPEPathBoomerJump, buffer, sizeof(buffer));
	PrecacheParticle(buffer);
	GetConVarString(g_hPEPathBoomerLand, buffer, sizeof(buffer));
	PrecacheParticle(buffer);
	
	GetConVarString(g_hSEPathChargeSpecialatk, buffer, sizeof(buffer));
	PrecacheSound(buffer,true);
	GetConVarString(g_hSEPathChargeFail, buffer, sizeof(buffer));
	PrecacheSound(buffer,true);
	GetConVarString(g_hSEPathChargeLand, buffer, sizeof(buffer));
	PrecacheSound(buffer,true);
	GetConVarString(g_hSEPathChargeHangtime, buffer, sizeof(buffer));
	PrecacheSound(buffer,true);
	GetConVarString(g_hSEPathChargeActivated, buffer, sizeof(buffer));
	PrecacheSound(buffer,true);
	GetConVarString(g_hSEPathChargeInit, buffer, sizeof(buffer));
	PrecacheSound(buffer,true);
	GetConVarString(g_hSEPathChargeReady, buffer, sizeof(buffer));
	PrecacheSound(buffer,true);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	Debug("Round Started");
	InitAll();
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	Debug("Round Ended");
	UnsetAll();
}

public Event_PlayerBotReplace(Handle:event, const String:name[], bool:dontBroadcast)
{
	new botId = GetClientOfUserId(GetEventInt(event,"bot"));
	new userId = GetClientOfUserId(GetEventInt(event,"player"));
	
	Debug("Bot [%d=%N] replaced a Player [%N/%d]. Zombie Class = %i",botId,botId,userId,userId, userId);
	
	//SetNextAvailableCharacter(botId,true);
}

public Event_BotPlayerReplace(Handle:event, const String:name[], bool:dontBroadcast)
{
	new botId = GetClientOfUserId(GetEventInt(event,"bot"));
	new userId = GetClientOfUserId(GetEventInt(event,"player"));
	
	Debug("Player [%N/%d] replaced a bot [%d=%N]. Zombie Class = %i",userId,userId,botId,botId,GetZombieClass(userId));
	
	if (!IsBoomer(userId)) 
		ResetCharge(userId,true);
}

public Event_PlayerChangeTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new clientId = GetClientOfUserId(GetEventInt(event, "userid"));
	//new oldTeamId = GetEventInt(event,"oldteam");
	//new newTeamId = GetEventInt(event,"team");
	//new bool:bDisconnect = GetEventBool(event,"disconnect");
	//new cChar = GetEntData(clientId, FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter"), 1);
	
	Debug("Player %N changed team. Zombie Class = %i",clientId, GetZombieClass(clientId));
	
	if (!IsBoomer(clientId))
	{
		UnsetSuperBoomer(clientId);
	}
	else
	{
		InitSuperBoomer(clientId);
	}
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	UnsetSuperBoomer(client);
}

public Action:Tick_DisplayChargeHint(Handle:timer, any:client)
{
	decl String:msg[256];
	Format(msg, sizeof(msg),"Hold Crouch for %d sec(s) then Press JUMP to activate a Charged Rocket Jump",GetConVarInt(g_hChargeTime))
	DisplayInstructorHint(client, msg, "+duck")	
}

public Action:Tick_DisplaySpecialHint(Handle:timer, any:client)
{
	decl String:msg[256];
	Format(msg, sizeof(msg),"Press your ATTACK key to descend faster",GetConVarInt(g_hChargeTime))
	DisplayInstructorHint(client, msg, "+attack")	
}

DisplayHint(client, hintType)
{
	Debug("Displaying Instructor Hint To Client...");
	
	new hintChoice = GetConVarInt(g_hHintType);
		
	if (hintChoice != 0)
	{
		QueryClientConVar(client, "gameinstructor_enable", ConVarQueryFinished:GameInstructor, client);
		ClientCommand(client, "gameinstructor_enable 1");
		
		switch (hintType)
		{
			case HINT_CROUCH:
			{
				if (hintChoice == 1 || hintChoice == 3)
					PrintToChat(client, "\x03%N:\n\x05Hold Crouch for %d sec(s) then Press JUMP to activate a Super Charged Rocket Jump\nNote: Timing of this ability is crucial", client,GetConVarInt(g_hChargeTime));
				if (hintChoice == 2 || hintChoice == 3)
					CreateTimer(0.2, Tick_DisplayChargeHint, client);
			}
			case HINT_SPECIAL:
			{
				if (hintChoice == 1 || hintChoice == 3)
					PrintToChat(client, "\x03%N:\n\x05Press your ATTACK key to descend to the ground faster", client);
				if (hintChoice == 2 || hintChoice == 3)
					CreateTimer(0.2, Tick_DisplaySpecialHint, client);
			}
		}
	}
	else
	{
		Debug("Skipping Hint...");
	}
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	Debug("Player %N has spawned",client);
	
	if (IsBoomer(client))
	{
		DisplayHint(client, HINT_CROUCH);
		InitSuperBoomer(client);
		//PrintToChat(client, "\x03[BOOMER HINT]: \x04Hold Crouch for %d sec(s) then Press JUMP to activate a Super Charged Rocket Jump\nNote: Timing of this ability is crucial",GetConVarInt(g_hChargeTime));
	}
	else
	{
		Debug("Player %N did not spawn as BOOMER...Skipping initialization", client);
	}
}

public Action:Event_PlayerJump(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));		
	g_bPlayerJumped[client] = true;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	//Applicable only for boomer
	if (IsBoomer(client))
	{
		if (buttons & IN_JUMP)
		{
			if (!g_bIsHoldingJump[client])
			{
				g_bIsHoldingJump[client] = true;
				
				if (g_bIsPlayerCharged[client] && !g_bIsChargeActivated[client])
				{
					Debug("Player %N has activated SUPER BOOMER!!",client);
					DisplayHint(client,HINT_SPECIAL);
					ActivateCharge(client);
				}
			}
		}
		else
		{
			g_bIsHoldingJump[client] = false;
		}
		
		if (buttons & IN_DUCK)
		{
			if (!g_bIsHoldingDuck[client])
			{
				g_bIsHoldingDuck[client] = true;
				
				Debug("Player %N Activated Duck", client);
			}
			else if (g_bIsHoldingDuck[client] && g_bIsHoldingJump[client])
			{
				g_iClientChargeDuration[client] = 0.0;
			}
		}
		else
		{
			g_bIsHoldingDuck[client] = false;
			g_iClientChargeDuration[client] = 0.0;
		}
		
		if ((buttons & IN_ATTACK) && (g_bIsChargeActivated[client] && !IsEntityOnGround(client)) && GetConVarBool(g_hSpecialAtkEnabled))
		{
			if (!g_bIsHoldingSpecialAtk[client])
			{
				g_bIsHoldingSpecialAtk[client] = true;
				Debug("Player %N issued a SPECIAL ATTACK!", client);
				if (GetConVarBool(g_hChargeSESpecialAtk)) 
				{
					EmitAmbientSoundEx(g_hSEPathChargeSpecialatk,client);
				}
				SetEntDataFloat(client,g_iLaggedMovementO, 10.0 ,true);
			}
		}
		else
		{
			g_bIsHoldingSpecialAtk[client] = false;
		}
	}
	
	return Plugin_Continue;
}

ActivateCharge(client)
{
	Debug("Super Boomer Activated for %N", client);
	
	StopChargingEffects(client);
	
	g_bIsChargeActivated[client] = true;
	
	StartChargeActivateEffects(client);
	
	SetEntDataFloat(client,g_iLaggedMovementO, 5.0 ,true);
	PerformGravity(client,GetConVarFloat(g_hGravity));
}

ResetCharge(client, bool:forceReset = false)
{
	//Reset the charge
	if ((g_bIsChargeActivated[client] || g_bIsPlayerCharged[client]) || forceReset)
	{
		Debug("Resetting Charge for %N", client);
		PerformGravity(client,0.0);
		g_iClientChargeDuration[client] = 0.0;
		g_bIsPlayerCharged[client] = false;
		g_bIsPlayerCharging[client] = false;
		g_bIsChargeActivated[client] = false;
		Debug("+ Resetting Lag Movement for %N", client);
		SetEntDataFloat(client,g_iLaggedMovementO, 1.0 ,true);
		StopChargingEffects(client);	
		
		if (g_hExpireCharge[client] != INVALID_HANDLE)
		{
			Debug("+ Killing Expiry Timer for Player %N",client);
			KillTimer(g_hExpireCharge[client]);
			g_hExpireCharge[client] = INVALID_HANDLE;
		}
	}
	//else
	//Debug("Will not reset charge...Player %N is either not charging or has not activated the charge", client);
}

PerformGravity(client, Float:amount)
{
	//new offset = FindDataMapOffs(client, "m_flGravity");
	//new Float:temp = GetEntDataFloat(client, offset);
	
	//Debug("Gravity check %f", temp);
	
	SetEntityGravity(client, amount);
	
	Debug("+ Set gravity on \"%N\" to %f.", client, amount);
}

public Action:ChargeTimer(Handle:timer, any:client)
{
	if (IsBoomer(client))
	{
		//Player is holding duck and is on the ground
		if (g_bIsHoldingDuck[client] && IsEntityOnGround(client))
		{
			//Increment Charge Progress Counter
			g_iClientChargeDuration[client] = g_iClientChargeDuration[client] + 1;
			
			Debug("Player %N is Charging [%1.2f]",client,g_iClientChargeDuration[client]);
			
			if (!g_bIsPlayerCharged[client] && g_iClientChargeDuration[client] >= GetConVarInt(g_hChargeTime))
			{
				Debug("PLAYER %N is NOW FULLY CHARGED",client);
				
				PrintHintText(client, "Boomer is now fully charged. Activate the Jump!", g_iClientChargeDuration[client]);
				
				g_bIsPlayerCharged[client] = true;
				
				//Give boomer a temporary speed boost
				SetEntDataFloat(client,g_iLaggedMovementO, 5.0 ,true);
				
				//Time to reset the charge
				Debug("Initialized Charge Timer Expiration for %f (s)", GetConVarFloat(g_hChargeExpire));
				g_hExpireCharge[client] = CreateTimer(GetConVarFloat(g_hChargeExpire),Tick_ExpireCharge,client,TIMER_REPEAT);
				
				//Set pre-charge effects
				StopChargingEffects(client);
				StartChargeReadyEffects(client);
			}
			//Player is still charging
			else if (!g_bIsPlayerCharged[client] && g_iClientChargeDuration[client] < GetConVarInt(g_hChargeTime))
			{
				g_bIsPlayerCharging[client] = true;
				
				PrintHintText(client, "Boomer Super Charging : %1.0f", ((g_iClientChargeDuration[client]/GetConVarInt(g_hChargeTime)) * 100));
				
				g_bIsPlayerCharged[client] = false;
				
				//Initialize Charging Effects
				StartChargingEffects(client);
			}
		}
		else
		{
			//Let us only reset once and only if the player was charging...
			if (g_bIsPlayerCharging[client] && (!g_bIsPlayerCharged[client] || !g_bIsChargeActivated[client]))
			{
				PrintHintText(client, "Charge Expired...Resetting...");
				Debug("Fail Charge");
				ResetCharge(client,true);
			}
		}
		
		if (g_bIsHoldingJump[client])
		{
			Debug("Client %N is holding jump",client);
		}
	}
	
	return Plugin_Continue;
}

public Action:Tick_ExpireCharge(Handle:timer, any:client)
{
	if (IsEntityOnGround(client))
	{
		PrintHintText(client, "Charge Expired...Resetting...");
		Debug("Expiring Charge...");
		ResetCharge(client, true);
		
		if (GetConVarBool(g_hChargeSEFail))
		{				
			//EmitSoundToClient(client,SOUND_CHARGE_FAIL);
			EmitSoundToClientEx(g_hSEPathChargeFail, client);
		}		
		
		if (g_hExpireCharge[client] != INVALID_HANDLE)
		{
			Debug("Killing Expiry Timer for Player %N",client);
			KillTimer(g_hExpireCharge[client]);
			g_hExpireCharge[client] = INVALID_HANDLE;
		}
		else
		{
			Debug("Handle is invalid...no need to kill %d", g_hExpireCharge[client]);
		}
	}
	else
	{
		Debug("Skipping Expiration...%N is still in-air",client);
	}
}

IsEntityOnGround(entity)
{
	if (IsValidEdict(entity) && IsValidEntity(entity) && GetEntityFlags(entity) & FL_ONGROUND) 
	{
		return true;
	}
	return false;
}

public SDKHook_Touch_Callback(entity, other)
{
	if (IsValidClient(entity))
	{
		//Debug("TW: Entity Index: %i, Is Charged: %i, Is Charge Activated: %i, Player Jumped: %i, Entity: %N", other,g_bIsPlayerCharged[entity],g_bIsChargeActivated[entity], g_bPlayerJumped[entity], entity);
		
		if ((other == 0 && IsEntityOnGround(entity)) && g_bIsChargeActivated[entity] == true)
		{
			Debug("Entity is on the ground %N and has activated the jump",entity);
			
			Debug("%N Completed the ROCKET BOOM",entity);
			
			StartLandEffect(entity);
			
			if (GetConVarBool(g_hExplodeOnImpact) && IsBoomer(entity) && IsPlayerAlive(entity))
			{
				Debug("Player %N exploded upon impact",entity);
				SetEntityHealth(entity,0);
				IgniteEntity(entity,0.1);
			}
			
			ResetCharge(entity);
			
			g_bPlayerJumped[entity] = false;
		}
		else if ((other == 0 && IsEntityOnGround(entity)) && g_bIsPlayerCharged[entity] && !g_bIsHoldingDuck[entity])
		{
			Debug("Player %N is on the ground and already charged and not holding duck anymore...RESETTING CHARGE", entity);
			ResetCharge(entity);
		}
		else if ((other == 0 && IsEntityOnGround(entity)) && !g_bIsPlayerCharged[entity])
		{
			Debug("Player %N is on the ground but has not activated the jump", entity);
		}
		
		g_bPlayerJumped[entity] = false;
	}
}

//Used when player has landed
StartLandEffect(client)
{
	decl Float:pos[3];	
	GetClientAbsOrigin(client, pos);
	
	if (GetConVarBool(g_hChargeSELand))
	{
		EmitAmbientSoundEx(g_hSEPathChargeLand, client);
	}
	
	if (GetConVarBool(g_hChargePELand))
	{
		ShowParticleEx(g_hPEPathBoomerLand, client, 1.5);
		RunCheatCmd(client,"shake");
		RunCheatCmd(client,"shake");
		RunCheatCmd(client,"shake");
	}
}

//Used when boomer has activated the jump after being fully charged
StartChargeActivateEffects(client)
{
	if (g_bIsChargeActivated[client])
	{
		decl Float:pos[3];	
		GetClientAbsOrigin(client, pos);
		
		if (GetConVarBool(g_hChargeSEJump))
			EmitAmbientSoundEx(g_hSEPathChargeActivated,client);			
		if (GetConVarBool(g_hChargeSEWarCry))
			EmitAmbientSoundEx(g_hSEPathChargeHangtime,client);	
		
		if (GetConVarBool(g_hChargePEJump))
		{
			ShowParticleEx(g_hPEPathBoomerJump,client, 5.0);
			RunCheatCmd(client,"shake");
		}
	}
}

StartChargeReadyEffects(client)
{
	if (g_bIsPlayerCharged[client])
	{
		if (GetConVarBool(g_hChargeSECharge))
			EmitAmbientSoundEx(g_hSEPathChargeReady, client);
		RunCheatCmd(client, "shake");
		RunCheatCmd(client, "shake");
		RunCheatCmd(client, "shake");
	}
}

StartChargingEffects(client)
{
	if (!g_bChargeEffectsStarted[client] && GetConVarBool(g_hChargeEffectsEnabled))
	{
		Debug("Charge Effects Started for %N",client);
		
		if (g_hChargeEffects[client] != INVALID_HANDLE)
		{
			CloseHandle(g_hChargeEffects[client]);
			g_hChargeEffects[client] = INVALID_HANDLE;
		}
		
		g_bChargeEffectsStarted[client] = true;
		
		g_hChargeEffects[client] = CreateTimer(1.5,Tick_ChargingEffects,client,TIMER_REPEAT);
	}
}

public Action:Tick_ChargingEffects(Handle:timer, any:client)
{
	if (IsBoomer(client) && g_bChargeEffectsStarted[client])
	{
		if (GetConVarBool(g_hChargeSECharge))
		{
			//EmitAmbientSound(SOUND_CHARGE_INIT, pos, client);
			EmitAmbientSoundEx(g_hSEPathChargeInit,client);
		}
		if (GetConVarBool(g_hChargePECharge))
		{
			//ShowParticle(pos, EFFECT_BOOMER_CHARGE, 1.5);
			ShowParticleEx(g_hPEPathBoomerCharge,client,1.5);
		}
	}
}

StopChargingEffects(client)
{
	if (g_bChargeEffectsStarted[client])
	{
		Debug("Charge Effects Stopped for %N",client);
		
		g_bChargeEffectsStarted[client] = false;
		
		if (g_hChargeEffects[client] != INVALID_HANDLE)
		{
			KillTimer(g_hChargeEffects[client]);
			g_hChargeEffects[client] = INVALID_HANDLE;
		}
	}
}


ShowParticleEx(Handle:cvar, client, Float:time)
{
	decl Float:pos[3], String:buffer[64];
	GetClientAbsOrigin(client, pos);
	GetConVarString(cvar, buffer, sizeof(buffer));
	TrimString(buffer);
	Debug("Displaying Particle Effect: %s",buffer);
	ShowParticle(pos,buffer,time);
}

EmitAmbientSoundEx(Handle:cvar, client)
{
	decl Float:pos[3], String:buffer[128];
	GetClientAbsOrigin(client, pos);
	GetConVarString(cvar, buffer, sizeof(buffer));
	TrimString(buffer);
	Debug("Playing Sound Effect: %s",buffer);
	EmitAmbientSound(buffer, pos, client);
}

EmitSoundToClientEx(Handle:cvar, client)
{
	decl Float:pos[3], String:buffer[128];
	GetClientAbsOrigin(client, pos);
	GetConVarString(cvar, buffer, sizeof(buffer));
	TrimString(buffer);
	Debug("Playing Sound Effect: %s",buffer);
	EmitSoundToClient(client,buffer);
}

IsBoomer(client)
{
	//Debug("Zombie Class: %b",GetZombieClass(client));
	return IsValidClient(client) && GetClientTeam(client) == TEAM_INFECTED && GetZombieClass(client) == 2 && !GetEntProp(client, Prop_Send, "m_isGhost");
}


GetZombieClass(client)
{
	if (IsValidClient(client) && GetClientTeam(client) == TEAM_INFECTED)
	{
		return GetEntProp(client, Prop_Send, "m_zombieClass");
	}
	return -1;
}

stock Debug(const String:format[], any:...)
{
	decl String:buffer[192];
	VFormat(buffer, sizeof(buffer), format, 2);	
	
	#if DEBUG_LOG
	LogMessage("[DEBUG]\x04 %s", buffer);
	PrintToServer("[DEBUG] %s", buffer);
	#endif
	
	if (GetConVarInt(g_hDebug) == 1)
	{
		PrintToChatAll("\x05[DEBUG]\x04 %s", buffer);
	}
	else if (GetConVarInt(g_hDebug) == 2)
	{
		for (new i = 1; i < MaxClients; i++)
		{
			if (IsValidClient(i) && CheckAdminFlags(i,ADMFLAG_BAN))
			{
				PrintToChat(i,"\x05[DEBUG:ADMIN]\x04 %s",buffer);
			}
		}
	}
	else
	{
		//suppress "format" never used warning
		if(format[0])
			return;
		else
		return;		
	}
}

ShowParticle(Float:pos[3], String:particlename[], Float:time)
{
	/* Show particle effect you like */
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, DeleteParticles, particle);
		
	}  
}

PrecacheParticle(String:particlename[])
{
	Debug("Precaching Particle %s",particlename);
	/* Precache particle */
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(0.01, DeleteParticles, particle);
	} 
	else
	{
		Debug("Not a valid edict: %s",particlename);
	}
}

public Action:DeleteParticles(Handle:timer, any:particle)
{
	/* Delete particle */
	if (IsValidEntity(particle))
	{
		new String:classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
			RemoveEdict(particle);
	}
}

public OnClientPutInServer(client)
{
	if (IsFakeClient(client))
		return
	
	g_GameInstructor[client] = -1
}

public DisplayInstructorHint(client, String:msg[256], String:s_Bind[])
{
	decl i_Ent, String:s_TargetName[32], Handle:h_RemovePack
	
	i_Ent = CreateEntityByName("env_instructor_hint")
	FormatEx(s_TargetName, sizeof(s_TargetName), "hint%d", client)
	ReplaceString(msg, sizeof(msg), "\n", " ")
	DispatchKeyValue(client, "targetname", s_TargetName)
	DispatchKeyValue(i_Ent, "hint_target", s_TargetName)
	DispatchKeyValue(i_Ent, "hint_timeout", "5")
	DispatchKeyValue(i_Ent, "hint_range", "0.01")
	DispatchKeyValue(i_Ent, "hint_color", "255 255 255")
	DispatchKeyValue(i_Ent, "hint_icon_onscreen", "use_binding")
	DispatchKeyValue(i_Ent, "hint_caption", msg)
	DispatchKeyValue(i_Ent, "hint_binding", s_Bind)
	DispatchSpawn(i_Ent)
	AcceptEntityInput(i_Ent, "ShowHint")
	
	h_RemovePack = CreateDataPack()
	WritePackCell(h_RemovePack, client)
	WritePackCell(h_RemovePack, i_Ent)
	
	CreateTimer(10.0, RemoveInstructorHint, h_RemovePack)
}

public Action:RemoveInstructorHint(Handle:h_Timer, Handle:h_Pack)
{
	decl i_Ent, i_Client
	
	ResetPack(h_Pack, false)
	i_Client = ReadPackCell(h_Pack)
	i_Ent = ReadPackCell(h_Pack)
	CloseHandle(h_Pack)
	
	if (!i_Client || !IsClientInGame(i_Client))
		return Plugin_Handled
	
	if (IsValidEntity(i_Ent))
		RemoveEdict(i_Ent)
	
	if (!g_GameInstructor[i_Client])
		ClientCommand(i_Client, "gameinstructor_enable 0")
	
	DispatchKeyValue(i_Client, "targetname", "")
	
	return Plugin_Continue
}

public GameInstructor(QueryCookie:q_Cookie, i_Client, ConVarQueryResult:c_Result, const String:s_CvarName[], const String:s_CvarValue[])
	g_GameInstructor[i_Client] = StringToInt(s_CvarValue)

RunCheatCmd(client,const String:cheatCmd[], any:...)
{
	decl String:buffer[192];
	VFormat(buffer, sizeof(buffer), cheatCmd, 2);
	
	new flags = GetCommandFlags(buffer);
	SetCommandFlags(buffer, flags & ~FCVAR_CHEAT);
	if (client > 0)
	{
		FakeClientCommand(client, buffer);
	}
	else
	{
		ServerCommand(buffer);
	}
	SetCommandFlags(buffer, flags|FCVAR_CHEAT);	
}

IsValidClient(client)
{
	if (client == 0)
		return false;
	
	if (!IsValidEntity(client)) return false;
	
	if (!IsClientConnected(client))
		return false;
	
	if (IsFakeClient(client))
		return false;
	
	if (!IsClientInGame(client))
		return false;
	
	/*if (!IsPlayerAlive(client))
	return false;*/
	return true;
}

stock bool:CheckAdminFlags(client, flags)
{
	new AdminId:admin = GetUserAdmin(client);
	if (admin != INVALID_ADMIN_ID)
	{
		new count, found;
		for (new i = 0; i <= 20; i++)
		{
			if (flags & (1<<i))
			{
				count++;
				
				if (GetAdminFlag(admin, AdminFlag:i))
				{
					found++;
				}
			}
		}
		
		if (count == found)
		{
			return true;
		}
	}
	
	return false;
}


stock Fling(target, Float:vector[3], attacker, Float:stunTime = 3.0)
{
	Debug("CALLING FLING");
	new Handle:sdkCall = INVALID_HANDLE;
	new Handle:configFile = LoadGameConfigFile("l4d2spooned");
	
	if (configFile == INVALID_HANDLE) Debug("ERROR LOADING GAME FILE");
	
	StartPrepSDKCall(SDKCall_Player);
	
	
	if(!PrepSDKCall_SetFromConf(configFile, SDKConf_Signature, "CTerrorPlayer_Fling"))
		Debug("Fling not found.");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);

	sdkCall = EndPrepSDKCall();
	
	if(sdkCall == INVALID_HANDLE)
	{
		Debug("ERRROR");
		return;
	}
	
	SDKCall(sdkCall, target, vector, 96, attacker, stunTime);//96
}