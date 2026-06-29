//Includes.
#include <sourcemod>
#include <sdktools>
#pragma semicolon 2 //Who doesn't like semicolons? :)
#define GETVERSION "1.0"
#define DEBUG 0


//Player yell sound file paths
#define YELLNICK_1 "player/survivor/voice/gambler/battlecry04.wav"
#define YELLNICK_2 "player/survivor/voice/gambler/battlecry01.wav"
#define YELLNICK_3 "player/survivor/voice/gambler/deathscream02.wav"
#define YELLRO_1 "player/survivor/voice/producer/battlecry01.wav"
#define YELLRO_2 "player/survivor/voice/producer/battlecry02.wav"
#define YELLRO_3 "player/survivor/voice/producer/hurtmajor01.wav"
#define YELLELLIS_1 "player/survivor/voice/mechanic/battlecry01.wav"
#define YELLELLIS_2 "player/survivor/voice/mechanic/battlecry03.wav"
#define YELLELLIS_3 "player/survivor/voice/mechanic/deathscream01.wav"
#define YELLCOACH_1 "player/survivor/voice/coach/battlecry09.wav"
#define YELLCOACH_2 "player/survivor/voice/coach/battlecry06.wav"
#define YELLCOACH_3 "player/survivor/voice/coach/battlecry04.wav"
#define YELLHUNTER_1 "player/hunter/voice/warn/hunter_warn_10.wav"
#define YELLHUNTER_2 "player/hunter/voice/warn/hunter_warn_14.wav"
#define YELLHUNTER_3 "player/hunter/voice/warn/hunter_warn_18.wav"
#define YELLSMOKER_1 "player/smoker/voice/warn/smoker_warn_01.wav"
#define YELLSMOKER_2 "player/smoker/voice/warn/smoker_warn_04.wav"
#define YELLSMOKER_3 "player/smoker/voice/warn/smoker_warn_05.wav"
#define YELLJOCKEY_1 "player/jockey/voice/warn/jockey_06.wav"
#define YELLJOCKEY_2 "player/jockey/voice/idle/jockey_lurk06.wav"
#define YELLJOCKEY_3 "player/jockey/voice/idle/jockey_lurk09"
#define YELLSPITTER_1 "player/spitter/voice/warn/spitter_warn_01.wav"
#define YELLSPITTER_2 "player/spitter/voice/warn/spitter_warn_02.wav"
#define YELLSPITTER_3 "player/spitter/voice/warn/spitter_warn_03.wav"
#define YELLBOOMER_1 "player/boomer/voice/action/male_zombie10_growl5.wav"
#define YELLBOOMER_2 "player/boomer/voice/action/male_zombie10_growl6.wav"
#define YELLBOOMER_3 "player/boomer/voice/alert/male_boomer_alert_05.wav"
#define YELLCHARGER_1 "player/charger/voice/warn/charger_warn_01.wav"
#define YELLCHARGER_2 "player/charger/voice/warn/charger_warn_02.wav"
#define YELLCHARGER_3 "player/charger/voice/warn/charger_warn_03.wav"
#define YELLBOOMETTE_1 "player/boomer/voice/action/female_zombie10_growl4.wav"
#define YELLBOOMETTE_2 "player/boomer/voice/action/female_zombie10_growl5.wav"
#define YELLBOOMETTE_3 "player/boomer/voice/action/female_zombie10_growl3.wav"
#define YELLTANK_1 "player/tank/voice/pain/tank_fire_01.wav"
#define YELLTANK_2 "player/tank/voice/pain/tank_fire_03.wav"
#define YELLTANK_3 "player/tank/voice/yell/tank_throw_04.wav"

//VARIABLES
new bool:g_bPounced[MAXPLAYERS+1]; //Is being pounced?
new bool:g_bChoked[MAXPLAYERS+1]; //Is being choked?
new bool:g_bRiden[MAXPLAYERS+1]; //Is being riden by a jockey?
new bool:g_bPummel[MAXPLAYERS+1]; //Is being pummeled?
new bool:g_bIncap[MAXPLAYERS+1]; //Is incapped?
new bool:g_bCdown[MAXPLAYERS+1]; //Cooldown
new bool:g_bYCdown[MAXPLAYERS+1]; 
new String:g_sKey[12]; //Key to bind

new bool:g_bExBoomer = false; //Are boomers excluded from yell?
new bool:g_bExTank = false; //Are tanks excluded from yell?
new bool:g_bExCharger = false; //Are Chargers excluded from yell?
new bool:g_bExSpitter = false; //Are Spitters excluded from yell?
new bool:g_bExHunter = false; //Are hunters excluded from yell?
new bool:g_bExJockey = false; //Are jockeys excluded from yell?
new bool:g_bExSmoker = false; //Are smokers excluded from yell?

new g_iYells = 0;
new g_iYellAttempts = 0;



//HANDLES
new Handle:g_cvarYellPounced = INVALID_HANDLE;
new Handle:g_cvarYellChoked = INVALID_HANDLE;
new Handle:g_cvarYellRiden = INVALID_HANDLE;
new Handle:g_cvarYellIncap = INVALID_HANDLE;
new Handle:g_cvarYellPummel = INVALID_HANDLE;
new Handle:g_cvarYellPower = INVALID_HANDLE;
new Handle:g_cvarYellRadius = INVALID_HANDLE;
new Handle:g_cvarYellInterval = INVALID_HANDLE;
new Handle:g_cvarYellLuck = INVALID_HANDLE;
new Handle:g_cvarYellExclude = INVALID_HANDLE;
new Handle:g_cvarYellDefault = INVALID_HANDLE;
new Handle:g_cvarYellBind = INVALID_HANDLE;
new Handle:g_cvarYellBindKey = INVALID_HANDLE;
new Handle:g_cvarYellAdvert = INVALID_HANDLE;
new Handle:g_cvarYellSurvivor =  INVALID_HANDLE;
new Handle:g_cvarYellInfected = INVALID_HANDLE;
new Handle:g_cvarYellCooldown = INVALID_HANDLE;
new Handle:g_cvarYellBurn = INVALID_HANDLE;
new Handle:g_cvarYellBurnLuck = INVALID_HANDLE;

new Handle:g_hGameConf = INVALID_HANDLE;
new Handle:sdkCallPushPlayer = INVALID_HANDLE;

//Plugin Info
public Plugin:myinfo = 
{
	name = "[L4D2] Last Resource",
	author = "honorcode23",
	description = "Allow survivors and infected to 'yell' as their last resource",
	version = "GETVERSION",
	url = "<-No url available yet->"
}

public OnPluginStart()
{
	//Left 4 dead 2 only
	decl String:sGame[256];
	GetGameFolderName(sGame, sizeof(sGame));
	if (!StrEqual(sGame, "left4dead2", false))
	{
		SetFailState("Last Resource supports Left 4 dead 2 only!");
	}
	
	//Configuration ConVars
	CreateConVar("l4d2_last_resource_version", GETVERSION, "Version of [L4D2] Last Resource Plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_cvarYellAdvert = CreateConVar("l4d2_last_resource_advert", "1", "Tell the players about the feature", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarYellSurvivor = CreateConVar("l4d2_last_resource_survivor", "1", "Enable yelling on survivors?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarYellInfected = CreateConVar("l4d2_last_resource_infected", "1", "Enable yelling on infected?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarYellPounced = CreateConVar("l4d2_last_resource_pounced", "1", "Enable yelling when pounced by hunter?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarYellChoked = CreateConVar("l4d2_last_resource_choked", "1", "Enable yelling when being choked by smoker?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarYellRiden = CreateConVar("l4d2_last_resource_jockeyed", "1", "Enable yelling when catched by a jockey?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarYellIncap = CreateConVar("l4d2_last_resource_incapped", "1", "Enable yelling when incapacitated?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarYellPummel = CreateConVar("l4d2_last_resource_pummel", "1", "Enable yelling when pummeled by charger?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarYellPower = CreateConVar("l4d2_last_resource_power", "500.0", "Power of every yell", FCVAR_PLUGIN, true, 0.0);
	g_cvarYellRadius = CreateConVar("l4d2_last_resource_radius", "180.0", "Maximum radius of every yell", FCVAR_PLUGIN, true, 0.0);
	g_cvarYellInterval = CreateConVar("l4d2_last_resource_interval", "1.0", "Interval or cooldown between tries to yell", FCVAR_PLUGIN, true, 0.1);
	g_cvarYellCooldown = CreateConVar("l4d2_last_resource_interval", "5.0", "Interval or cooldown between successfull yells", FCVAR_PLUGIN, true, 0.1);
	g_cvarYellLuck = CreateConVar("l4d2_last_resource_chance", "3", "Chance of gaining the yell power. (1: 100%, 2 : 50%, 3: 33%, etc)", FCVAR_PLUGIN, true, 1.0);
	g_cvarYellExclude = CreateConVar("l4d2_last_resource_exclude", "tank", "Infected not affected by the yell, separated by comas (tank, spitter, charger, jockey, hunter, smoker, boomer)", FCVAR_PLUGIN);
	g_cvarYellDefault = CreateConVar("l4d2_last_resource_default_key", "1", "Allow the SHIFT key to be the default key of yelling", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarYellBind = CreateConVar("l4d2_last_resource_radius_bind_key", "0", "Bind a secondary key for yelling?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarYellBindKey = CreateConVar("l4d2_last_resource_bind_key_string", "", "Specify the secondary key for yelling", FCVAR_PLUGIN);
	g_cvarYellBurn = CreateConVar("l4d2_last_resource_ignite", "1", "Ignite the special infected around when a survivor yells?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarYellBurnLuck = CreateConVar("l4d2_last_resource_ignite_chance", "3", "Chance to ignite the special infected when yelling", FCVAR_PLUGIN, true, 1.0);
	
	//Commads
	RegConsoleCmd("sm_yell", CmdYell, "Will yell only if it is possible");
	
	//Admin commands
	RegAdminCmd("sm_forceyell", CmdForceYell, ADMFLAG_SLAY, "Will force a yell even if it isn't enabled");
	
	//Create Config File
	AutoExecConfig(true, "l4d2_last_resource");
	
	//Get key
	GetConVarString(g_cvarYellBindKey, g_sKey, sizeof(g_sKey));
	
	//Hooking events
	HookEvent("round_start_post_nav", OnRoundStart); //ROUND START
	HookEvent("round_end", OnRoundEnd); //ROUND END
	HookEvent("jockey_ride", OnJockeyRideStart); //Anytime a jockey rides a survivor
	HookEvent("lunge_pounce", OnHunterPounceStart); //Everytime a hunter pounces a survivor
	HookEvent("choke_start", OnSmokerChokeStart); //When smoker starts choking. This is also called when the survivor gets stuck for a few seconds.
	HookEvent("jockey_ride_end", OnJockeyRideEnd); //When the jockey ride ends
	HookEvent("pounce_stopped", OnHunterPounceEnd); //When the hunter pounce ends
	HookEvent("choke_start", OnSmokerChokeEnd); //When the smoke choke ends. Tongue broke
	HookEvent("charger_pummel_start", OnPummelStart); //When a player gets pummeled
	HookEvent("charger_pummel_end", OnPummelEnd); //When a player is not pummeled anymore
	HookEvent("player_incapacitated", OnIncap); //Incapacitated
	HookEvent("revive_success", OnRevived); //Revived
	HookEvent("player_death", OnPlayerDeath); //died
	
	//SDKCALL
	g_hGameConf = LoadGameConfigFile("l4d2lastresource");
	if(g_hGameConf == INVALID_HANDLE)
	{
		SetFailState("Couldn't find the signatures file. Please, check that it is installed correctly.");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "CTerrorPlayer_Fling");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	sdkCallPushPlayer = EndPrepSDKCall();
	if(sdkCallPushPlayer == INVALID_HANDLE)
	{
		SetFailState("Unable to find the 'CTerrorPlayer_Fling' signature, check the file version!");
	}
}

public Action:CmdYell(client, args)
{
	if(TestPosibilities(client) && !g_bCdown[client])
	{
		g_iYellAttempts++;
		switch(GetRandomInt(1, GetConVarInt(g_cvarYellLuck)))
		{
			case 1:
			{
				Yell(client);
				g_iYells++;
				#if DEBUG
				decl String:name[256];
				GetClientName(client, name, sizeof(name));
				PrintToServer("[Last Resource] %s(%i) Yelled.", name, client);
				#endif
			}
		}
		g_bCdown[client] = true;
		CreateTimer(GetConVarFloat(g_cvarYellInterval), timerCooldown, client);
		#if DEBUG
		PrintToConsole(client, "[Last Resource] Cooldown in progress");
		#endif
	}
	
}

public Action:CmdForceYell(client, args)
{
	g_iYells++;
	Yell(client);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	//If the admin doesnt want this to be the default key, then dont even bother on doing anything.
	if(!GetConVarBool(g_cvarYellDefault))
	{
		return;
	}
	
	//If client index is equal to 0 (world), abort
	if(client == 0)
	{
		return;
	}
	
	if((buttons & IN_SPEED) && TestPosibilities(client) && !g_bCdown[client])
	{
		g_iYellAttempts++;
		switch(GetRandomInt(1, GetConVarInt(g_cvarYellLuck)))
		{
			case 1:
			{
				Yell(client);
				g_iYells++;
				g_bYCdown[client] = true;
				CreateTimer(GetConVarFloat(g_cvarYellCooldown), timerYellCooldown, client);
				#if DEBUG
				decl String:name[256];
				GetClientName(client, name, sizeof(name));
				PrintToServer("[Last Resource] %s(%i) Yelled.", name, client);
				#endif
			}
		}
		
		g_bCdown[client] = true;
		CreateTimer(GetConVarFloat(g_cvarYellInterval), timerCooldown, client);
		#if DEBUG
		PrintToConsole(client, "[Last Resource] Cooldown in progress");
		#endif
	}
}

public Action:timerCooldown(Handle:timer, any:client)
{
	g_bCdown[client] = false;
	#if DEBUG
	PrintToConsole(client, "[Last Resource] Cooldown is over");
	#endif
}

public Action:timerYellCooldown(Handle:timer, any:client)
{
	g_bYCdown[client] = false;
	#if DEBUG
	PrintToConsole(client, "[Last Resource] Yell cooldown is over");
	#endif
}

public OnMapStart()
{
	ResetStats();
	//Precache Sounds
	PrecacheSound(YELLNICK_1);
	PrecacheSound(YELLNICK_2);
	PrecacheSound(YELLNICK_3);
	PrecacheSound(YELLRO_1);
	PrecacheSound(YELLRO_2);
	PrecacheSound(YELLRO_3);
	PrecacheSound(YELLELLIS_1);
	PrecacheSound(YELLELLIS_2);
	PrecacheSound(YELLELLIS_3);
	PrecacheSound(YELLCOACH_1);
	PrecacheSound(YELLCOACH_2);
	PrecacheSound(YELLCOACH_3);
	PrecacheSound(YELLHUNTER_1);
	PrecacheSound(YELLHUNTER_2);
	PrecacheSound(YELLHUNTER_3);
	PrecacheSound(YELLSMOKER_1);
	PrecacheSound(YELLSMOKER_2);
	PrecacheSound(YELLSMOKER_3);
	PrecacheSound(YELLJOCKEY_1);
	PrecacheSound(YELLJOCKEY_2);
	PrecacheSound(YELLJOCKEY_3);
	PrecacheSound(YELLSPITTER_1);
	PrecacheSound(YELLSPITTER_2);
	PrecacheSound(YELLSPITTER_3);
	PrecacheSound(YELLBOOMER_1);
	PrecacheSound(YELLBOOMER_2);
	PrecacheSound(YELLBOOMER_3);
	PrecacheSound(YELLCHARGER_1);
	PrecacheSound(YELLCHARGER_2);
	PrecacheSound(YELLCHARGER_3);
	PrecacheSound(YELLBOOMETTE_1);
	PrecacheSound(YELLBOOMETTE_2);
	PrecacheSound(YELLBOOMETTE_3);
	PrecacheSound(YELLTANK_1);
	PrecacheSound(YELLTANK_2);
	PrecacheSound(YELLTANK_3);
	
	//Prefetch sounds
	PrefetchSound(YELLNICK_1);
	PrefetchSound(YELLNICK_2);
	PrefetchSound(YELLNICK_3);
	PrefetchSound(YELLRO_1);
	PrefetchSound(YELLRO_2);
	PrefetchSound(YELLRO_3);
	PrefetchSound(YELLELLIS_1);
	PrefetchSound(YELLELLIS_2);
	PrefetchSound(YELLELLIS_3);
	PrefetchSound(YELLCOACH_1);
	PrefetchSound(YELLCOACH_2);
	PrefetchSound(YELLCOACH_3);
	PrefetchSound(YELLHUNTER_1);
	PrefetchSound(YELLHUNTER_2);
	PrefetchSound(YELLHUNTER_3);
	PrefetchSound(YELLSMOKER_1);
	PrefetchSound(YELLSMOKER_2);
	PrefetchSound(YELLSMOKER_3);
	PrefetchSound(YELLJOCKEY_1);
	PrefetchSound(YELLJOCKEY_2);
	PrefetchSound(YELLJOCKEY_3);
	PrefetchSound(YELLSPITTER_1);
	PrefetchSound(YELLSPITTER_2);
	PrefetchSound(YELLSPITTER_3);
	PrefetchSound(YELLBOOMER_1);
	PrefetchSound(YELLBOOMER_2);
	PrefetchSound(YELLBOOMER_3);
	PrefetchSound(YELLCHARGER_1);
	PrefetchSound(YELLCHARGER_2);
	PrefetchSound(YELLCHARGER_3);
	PrefetchSound(YELLBOOMETTE_1);
	PrefetchSound(YELLBOOMETTE_2);
	PrefetchSound(YELLBOOMETTE_3);
	PrefetchSound(YELLTANK_1);
	PrefetchSound(YELLTANK_2);
	PrefetchSound(YELLTANK_3);
	
	#if DEBUG
	PrintToServer("Sounds have been precached and prefetched");
	#endif
}

//When a round begins
public OnRoundStart(Handle:event, String:event_name[], bool:dontBroadcast)
{
	#if DEBUG
	PrintToChatAll("\x04[Event]\x01 Round Started!");
	#endif
	ResetStats();
}

public OnRoundEnd(Handle:event, String:event_name[], bool:dontBroadcast)
{
	#if DEBUG
	PrintToChatAll("\x04[Event]\x01 Round Ended!");
	PrintToServer("[Last Resource] Total yell attempts: %i", g_iYellAttempts);
	PrintToServer("[Last Resource] Total successfull yells: %i", g_iYells);
	#endif
	ResetStats();
}
public OnMapEnd()
{
	#if DEBUG
	PrintToServer("[Last Resource] Total yell attempts: %i", g_iYellAttempts);
	PrintToServer("[Last Resource] Total successfull yells: %i", g_iYells);
	g_iYellAttempts = 0;
	g_iYells = 0;
	#endif
	ResetStats();
}

//When a client is putted in the server (joins)
public OnClientPutInServer(client)
{
	//If the client index is 0, do nothing
	if(client == 0)
	{
		return;
	}
	
	//If the admin wants to bind a secondary key, proceed
	if(GetConVarBool(g_cvarYellBind))
	{
		//Bind the client's key
		ClientCommand(client, "bind %s sm_yell", g_sKey);
		
		#if DEBUG
		PrintToConsole(client, "Your %s key will now yell", g_sKey);
		#endif
	}
	if(GetConVarBool(g_cvarYellAdvert))
	{
		RunAdvert(client);
	}
}

public Action:OnHunterPounceStart(Handle:event, String:event_name[], bool:dontBroadcast)
{
	#if DEBUG
	PrintToChatAll("\x04[Event]\x01 Hunter Pounce started");
	#endif
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	g_bPounced[victim] = true;
	TellToPress(victim);
}

public Action:OnHunterPounceEnd(Handle:event, String:event_name[], bool:dontBroadcast)
{
	#if DEBUG
	PrintToChatAll("\x04[Event]\x01 Hunter Pounce ended");
	#endif
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	g_bPounced[victim] = false;
}

public Action:OnSmokerChokeStart(Handle:event, String:event_name[], bool:dontBroadcast)
{
	#if DEBUG
	PrintToChatAll("\x04[Event]\x01A smoker is now choking somebody");
	#endif
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	g_bChoked[victim] = true;
	TellToPress(victim);
}

public Action:OnSmokerChokeEnd(Handle:event, String:event_name[], bool:dontBroadcast)
{
	#if DEBUG
	PrintToChatAll("\x04[Event]\x01 A smoker is no longer choking its victim");
	#endif
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	g_bChoked[victim] = false;
}

public Action:OnJockeyRideStart(Handle:event, String:event_name[], bool:dontBroadcast)
{
	#if DEBUG
	PrintToChatAll("\x04[Event]\x01A jockey is now riding somebody");
	#endif
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	g_bRiden[victim] = true;
	TellToPress(victim);
}

public Action:OnJockeyRideEnd(Handle:event, String:event_name[], bool:dontBroadcast)
{
	#if DEBUG
	PrintToChatAll("\x04[Event]\x01 A jockey is no longer riding its victim");
	#endif
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	g_bRiden[victim] = false;
}

public Action:OnPummelStart(Handle:event, String:event_name[], bool:dontBroadcast)
{
	#if DEBUG
	PrintToChatAll("\x04[Event]\x01A chargeris now pummeling somebody");
	#endif
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	g_bPummel[victim] = true;
	TellToPress(victim);
}

public Action:OnPummelEnd(Handle:event, String:event_name[], bool:dontBroadcast)
{
	#if DEBUG
	PrintToChatAll("\x04[Event]\x01 A charger is no longer pummeling its victim");
	#endif
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	g_bPummel[victim] = false;
}

public Action:OnIncap(Handle:event, String:event_name[], bool:dontBroadcast)
{
	#if DEBUG
	PrintToChatAll("\x04[Event]\x01 A player is now incapacitated");
	#endif
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_bIncap[client] = true;
	TellToPress(client);
}

public Action:OnRevived(Handle:event, String:event_name[], bool:dontBroadcast)
{
	#if DEBUG
	PrintToChatAll("\x04[Event]\x01 A player is no longer incapacitated");
	#endif
	new client = GetClientOfUserId(GetEventInt(event, "subject"));
	g_bIncap[client] = false;
}

public Action:OnPlayerDeath(Handle:event, String:event_name[], bool:dontBroadcast)
{
	#if DEBUG
	PrintToChatAll("\x04[Event]\x01 A player is death");
	#endif
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_bPounced[client] = false; //Is being pounced?
	g_bChoked[client] = false; //Is being choked?
	g_bRiden[client] = false; //Is being riden by a jockey?
	g_bPummel[client] = false; //Is being pummeled?
	g_bIncap[client] = false; //Is incapped?
	g_bCdown[client] = false; //Cooldown
	g_bYCdown[client] = false;
	if(GetConVarBool(g_cvarYellInfected) && client > 0 && GetClientTeam(client) == 3 && !IsFakeClient(client))
	{
		switch(GetRandomInt(1, GetConVarInt(g_cvarYellLuck)))
		{
			case 1:
			{
				Yell(client);
			}
		}
	}
}

ResetStats()
{
	for(new i=1; i<=MaxClients; i++)
	{
		g_bPounced[i] = false; //Is being pounced?
		g_bChoked[i] = false; //Is being choked?
		g_bRiden[i] = false; //Is being riden by a jockey?
		g_bPummel[i] = false; //Is being pummeled?
		g_bIncap[i] = false; //Is incapped?
		g_bCdown[i] = false; //Cooldown
		g_bYCdown[i] = false;
	}
	#if DEBUG
	PrintToChatAll("[Last Resource] Stats and counts have been reset");
	#endif
}

TestPosibilities(client)
{
	//Filter clients
	if(client > 0 && IsValidEntity(client) && IsClientConnected(client) && IsClientInGame(client))
	{
		//Get client team
		new team = GetClientTeam(client);
		
		//If survivor, proceed.
		if(team == 2)
		{
			if(!GetConVarBool(g_cvarYellSurvivor))
			{
				return false;
			}
			if(g_bPounced[client] && GetConVarBool(g_cvarYellPounced)
			|| g_bChoked[client] && GetConVarBool(g_cvarYellChoked)
			|| g_bRiden[client] && GetConVarBool(g_cvarYellRiden)
			|| g_bPummel[client] && GetConVarBool(g_cvarYellPummel)
			|| g_bIncap[client] && GetConVarBool(g_cvarYellIncap))
			{
				return true;
			}
			else
			{
				return false;
			}
		}
		
		//if infected proceed
		if(team == 3)
		{
			if(!GetConVarBool(g_cvarYellInfected))
			{
				return false;
			}
			else
			{
				return true;
			}
		}
	}
	return false;
}
			

Yell(client)
{
	CheckAffectedClasses();
	EmitYell(client);
	new Float:flMaxDistance = GetConVarFloat(g_cvarYellRadius);
	new Float:power = GetConVarFloat(g_cvarYellPower);
	//Get the client's userid for debuggin info
	new tcount = 0;
	#if DEBUG
	new userid = GetClientUserId(client);
	PrintToConsole(client, "Getting position from this client[Index :%i | User Id: %i]", client, userid);
	#endif
	
	//Declare the client's position and the target position as floats.
	decl Float:pos[3], Float:tpos[3], Float:distance[3];
	
	//Get the client's position and store it on the declared variable.
	GetClientAbsOrigin(client, pos);
	#if DEBUG
	PrintToConsole(client, "Position for (%i) is: %f, %f, %f", userid, pos[0], pos[1], pos[2]);
	#endif
	
	//If the client is an infected
	if(GetClientTeam(client) == 3)
	{
		//Find any possible colliding clients.
		for(new i=1; i<=MaxClients; i++)
		{
			if(i == 0 || !IsValidEntity(i) || !IsClientInGame(i) || !IsPlayerAlive(i))
			{
				continue;
			}
			if(GetClientTeam(client) == GetClientTeam(i))
			{
				continue;
			}
			tcount++;
			GetEntPropVector(i, Prop_Data, "m_vecOrigin", tpos);
			distance[0] = (pos[0] - tpos[0]);
			distance[1] = (pos[1] - tpos[1]);
			distance[2] = (pos[2] - tpos[2]);
			
			new Float:realdistance = SquareRoot(FloatMul(distance[0],distance[0])+FloatMul(distance[1],distance[1]));
			if(realdistance <= flMaxDistance && GetAbsoluteNumber(distance[2]) <= 50)
			{
				#if DEBUG
				PrintToConsole(client, "Got a matching target[id: %i | pos: %f, %f, %f", GetClientUserId(i), tpos[0], tpos[1], tpos[2]);
				PrintToConsole(client, "Distance is: %f, %f, %f", distance[0], distance[1], distance[2]);
				#endif
				decl Float:addVel[3], Float:final[3], Float:tvec[3], Float:ratio[3];
				
				ratio[0] =  FloatDiv(distance[0], SquareRoot(distance[1]*distance[1] + distance[0]*distance[0]));//Ratio x/hypo
				ratio[1] =  FloatDiv(distance[1], SquareRoot(distance[1]*distance[1] + distance[0]*distance[0]));//Ratio y/hypo
				
				GetEntPropVector(i, Prop_Data, "m_vecVelocity", tvec);
				
				addVel[0] = FloatMul(ratio[0]*-1, power);
				addVel[1] = FloatMul(ratio[1]*-1, power);
				addVel[2] = power;
				
				final[0] = FloatAdd(addVel[0], tvec[0]);
				final[1] = FloatAdd(addVel[1], tvec[1]);
				final[2] = power;
				#if DEBUG
				PrintToConsole(client, "Original target velocity: %f, %f, %f", tvec[0], tvec[1], tvec[2]);
				PrintToConsole(client, "Added target velocity: %f, %f, %f", addVel[0], addVel[1], addVel[2]);
				PrintToConsole(client, "Final target velocity: %f, %f, %f", final[0], final[1], final[2]);
				#endif
				FlingPlayer(i, addVel, client);
				#if DEBUG
				PrintToConsole(client, "Target %i got teleported!", GetClientUserId(i));
				#endif
			}
		}
	}
	
	if(GetClientTeam(client) == 2)
	{
		//Find any possible colliding clients.
		for(new i=1; i<=MaxClients; i++)
		{
			if(i == 0 || !IsValidEntity(i) || !IsClientInGame(i) || !IsPlayerAlive(i))
			{
				continue;
			}
			if(GetClientTeam(client) == GetClientTeam(i))
			{
				continue;
			}
			tcount++;
			GetEntPropVector(i, Prop_Data, "m_vecOrigin", tpos);
			distance[0] = (pos[0] - tpos[0]);
			distance[1] = (pos[1] - tpos[1]);
			distance[2] = (pos[2] - tpos[2]);
			
			new Float:realdistance = SquareRoot(FloatMul(distance[0],distance[0])+FloatMul(distance[1],distance[1]));
			if(realdistance <= flMaxDistance && GetAbsoluteNumber(distance[2]) <= 50)
			{
				#if DEBUG
				PrintToConsole(client, "Got a matching target[id: %i | pos: %f, %f, %f", GetClientUserId(i), tpos[0], tpos[1], tpos[2]);
				PrintToConsole(client, "Distance is: %f, %f, %f", distance[0], distance[1], distance[2]);
				#endif
				decl Float:addVel[3], Float:final[3], Float:tvec[3], Float:ratio[3];
				
				ratio[0] =  FloatDiv(distance[0], SquareRoot(distance[1]*distance[1] + distance[0]*distance[0]));//Ratio x/hypo
				ratio[1] =  FloatDiv(distance[1], SquareRoot(distance[1]*distance[1] + distance[0]*distance[0]));//Ratio y/hypo
				
				GetEntPropVector(i, Prop_Data, "m_vecVelocity", tvec);
				
				addVel[0] = FloatMul(ratio[0]*-1, power);
				addVel[1] = FloatMul(ratio[1]*-1, power);
				addVel[2] = power;
				
				final[0] = FloatAdd(addVel[0], tvec[0]);
				final[1] = FloatAdd(addVel[1], tvec[1]);
				final[2] = power;
				#if DEBUG
				PrintToConsole(client, "Original target velocity: %f, %f, %f", tvec[0], tvec[1], tvec[2]);
				PrintToConsole(client, "Added target velocity: %f, %f, %f", addVel[0], addVel[1], addVel[2]);
				PrintToConsole(client, "Final target velocity: %f, %f, %f", final[0], final[1], final[2]);
				#endif
				if(IsAffected(i))
				{
					TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, final);
				}
				if(GetConVarBool(g_cvarYellBurn))
				{
					switch(GetRandomInt(1, GetConVarInt(g_cvarYellBurnLuck)))
					{
						case 1:
						{
							IgniteEntity(i, 20.0);
						}
					}
				}
				#if DEBUG
				PrintToConsole(client, "Target %i got teleported!", GetClientUserId(i));
				#endif
			}
		}
	}
	#if DEBUG
	if(tcount > 0)
		PrintToConsole(client, "Targets found: %i", tcount);
	else
		PrintToConsole(client, "No targets matched");
	#endif
	tcount = 0;
}

stock EmitYell(client)
{
	decl String:model[256];
	GetClientModel(client, model, sizeof(model));
	
	//Survivor - Nick
	if(StrEqual(model, "models/survivors/survivor_gambler.mdl"))
	{
		switch(GetRandomInt(1,3))
		{
			case 1:
			EmitSoundToAll(YELLNICK_1, client);
			case 2:
			EmitSoundToAll(YELLNICK_2, client);
			case 3:
			EmitSoundToAll(YELLNICK_3, client);
		}
	}
	
	//Survivor - Rochelle
	if(StrEqual(model, "models/survivors/survivor_producer.mdl"))
	{
		switch(GetRandomInt(1,3))
		{
			case 1:
			EmitSoundToAll(YELLRO_1, client);
			case 2:
			EmitSoundToAll(YELLRO_2, client);
			case 3:
			EmitSoundToAll(YELLRO_3, client);
		}
	}
	
	//Survivor - Ellis
	if(StrEqual(model, "models/survivors/survivor_mechanic.mdl"))
	{
		switch(GetRandomInt(1,3))
		{
			case 1:
			EmitSoundToAll(YELLELLIS_1, client);
			case 2:
			EmitSoundToAll(YELLELLIS_2, client);
			case 3:
			EmitSoundToAll(YELLELLIS_3, client);
		}
	}
	
	//Survivor - Coach
	if(StrEqual(model, "models/survivors/survivor_coach.mdl"))
	{
		switch(GetRandomInt(1,3))
		{
			case 1:
			EmitSoundToAll(YELLCOACH_1, client);
			case 2:
			EmitSoundToAll(YELLCOACH_2, client);
			case 3:
			EmitSoundToAll(YELLCOACH_3, client);
		}
	}
	
	//Infected - Hunter
	if(StrEqual(model, "models/infected/hunter.mdl"))
	{
		switch(GetRandomInt(1,3))
		{
			case 1:
			EmitSoundToAll(YELLHUNTER_1, client);
			case 2:
			EmitSoundToAll(YELLHUNTER_2, client);
			case 3:
			EmitSoundToAll(YELLHUNTER_3, client);
		}
	}
	
	//Infected - Smoker
	if(StrEqual(model, "models/infected/smoker.mdl"))
	{
		switch(GetRandomInt(1,3))
		{
			case 1:
			EmitSoundToAll(YELLSMOKER_1, client);
			case 2:
			EmitSoundToAll(YELLSMOKER_2, client);
			case 3:
			EmitSoundToAll(YELLSMOKER_3, client);
		}
	}
	
	//Infected - Spitter
	if(StrEqual(model, "models/infected/spitter.mdl"))
	{
		switch(GetRandomInt(1,3))
		{
			case 1:
			EmitSoundToAll(YELLSPITTER_1, client);
			case 2:
			EmitSoundToAll(YELLSPITTER_2, client);
			case 3:
			EmitSoundToAll(YELLSPITTER_3, client);
		}
	}
	
	//Infected - Jockey
	if(StrEqual(model, "models/infected/jockey.mdl"))
	{
		switch(GetRandomInt(1,3))
		{
			case 1:
			EmitSoundToAll(YELLJOCKEY_1, client);
			case 2:
			EmitSoundToAll(YELLJOCKEY_2, client);
			case 3:
			EmitSoundToAll(YELLJOCKEY_3, client);
		}
	}
	
	//Infected - Charger
	if(StrEqual(model, "models/infected/charger.mdl"))
	{
		switch(GetRandomInt(1,3))
		{
			case 1:
			EmitSoundToAll(YELLCHARGER_1, client);
			case 2:
			EmitSoundToAll(YELLCHARGER_2, client);
			case 3:
			EmitSoundToAll(YELLCHARGER_3, client);
		}
	}
	
	//Infected - Male boomer 
	if(StrEqual(model, "models/infected/boomer.mdl"))
	{
		switch(GetRandomInt(1,3))
		{
			case 1:
			EmitSoundToAll(YELLBOOMER_1, client);
			case 2:
			EmitSoundToAll(YELLBOOMER_2, client);
			case 3:
			EmitSoundToAll(YELLBOOMER_3, client);
		}
	}
	
	//Infected - Female boomer
	if(StrEqual(model, "models/infected/boomette.mdl"))
	{
		switch(GetRandomInt(1,3))
		{
			case 1:
			EmitSoundToAll(YELLBOOMETTE_1, client);
			case 2:
			EmitSoundToAll(YELLBOOMETTE_2, client);
			case 3:
			EmitSoundToAll(YELLBOOMETTE_3, client);
		}
	}
	
	//Infected - Tank
	if(StrEqual(model, "models/infected/tank.mdl"))
	{
		switch(GetRandomInt(1,3))
		{
			case 1:
			EmitSoundToAll(YELLTANK_1, client);
			case 2:
			EmitSoundToAll(YELLTANK_2, client);
			case 3:
			EmitSoundToAll(YELLTANK_3, client);
		}
	}
	#if DEBUG
	PrintToChat(client, "ROAAAARRRR!");
	#endif
}
	
	

Float:GetAbsoluteNumber(Float:number)
{
	if(number < 0) 
	{
		return -number;
	}
	return number;
}

stock FlingPlayer(target, Float:vector[3], attacker, Float:stunTime = 3.0)
{

	SDKCall(sdkCallPushPlayer, target, vector, 96, attacker, stunTime);
}

TellToPress(client)
{
	if(GetConVarBool(g_cvarYellSurvivor) && GetConVarBool(g_cvarYellDefault) && GetConVarBool(g_cvarYellBind))
	{
		PrintHintText(client, "Press SHIFT or the %s key to yell as your last resource!!!", g_sKey);
	}
	if(GetConVarBool(g_cvarYellSurvivor) && GetConVarBool(g_cvarYellDefault) && !GetConVarBool(g_cvarYellBind))
	{
		PrintHintText(client, "Press SHIFT to yell as your last resource!!!");
	}
	if(GetConVarBool(g_cvarYellSurvivor) && !GetConVarBool(g_cvarYellDefault) && GetConVarBool(g_cvarYellBind))
	{
		PrintHintText(client, "Press the %s key to yell as your last resource!!!", g_sKey);
	}
}

RunAdvert(client)
{
	if(client > 0 && IsValidEntity(client) && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
	{
		if(GetConVarBool(g_cvarYellDefault) && GetConVarBool(g_cvarYellBind))
		{
			CreateTimer(15.0, timerDefaultBind, client);
		}
		if(GetConVarBool(g_cvarYellDefault) && !GetConVarBool(g_cvarYellBind))
		{
			CreateTimer(15.0, timerDefault, client);
		}
		if(!GetConVarBool(g_cvarYellDefault) && GetConVarBool(g_cvarYellBind))
		{
			CreateTimer(15.0, timerBind, client);
		}
	}
}

public Action:timerDefaultBind(Handle:timer, any:client)
{
	PrintToChat(client, "\x04[SM]\x03 If you are in trouble, press the SHIFT key as your last resource. As an alternative, you can press the %s key", g_sKey);
}

public Action:timerDefault(Handle:timer, any:client)
{
	PrintToChat(client, "\x04[SM]\x03 If you are in trouble, press the SHIFT key as your last resource!");
}

public Action:timerBind(Handle:timer, any:client)
{
	PrintToChat(client, "\x04[SM]\x03 If you are in trouble, you can press the %s key to try to release yourself from the problem", g_sKey);
}

CheckAffectedClasses()
{
	decl String:exinfected[256];
	GetConVarString(g_cvarYellExclude, exinfected, sizeof(exinfected));
	
	if( StrContains( exinfected, "boomer" ) != -1) 
	{
		g_bExBoomer = true;
	}
	else
	{
		g_bExBoomer = false;
	}
	if( StrContains( exinfected, "spitter" ) != -1)
	{
		g_bExSpitter = true;
	}
	else
	{
		g_bExSpitter = false;
	}
	if( StrContains( exinfected, "hunter" ) != -1)
	{
		g_bExHunter = true;
	}
	else
	{
		g_bExHunter = false;
	}
	if( StrContains( exinfected, "jockey" ) != -1) 
	{
		g_bExJockey = true;
	}
	else
	{
		g_bExJockey = false;
	}
	if( StrContains( exinfected, "charger" ) != -1) 
	{
		g_bExCharger = true;
	}
	else
	{
		g_bExCharger = false;
	}
	if( StrContains( exinfected, "smoker" ) != -1) 
	{
		g_bExSmoker = true;
	}
	else
	{
		g_bExSmoker = false;
	}
	if( StrContains( exinfected, "tank" ) != -1) 
	{
		g_bExTank = true;
	}
	else
	{
		g_bExTank = false;
	}
}

IsAffected(client)
{
	decl String:weapon[256]; 
	new entity = GetEntDataEnt2(client, FindSendPropInfo("CTerrorPlayer", "m_hActiveWeapon"));
	GetEntityNetClass(entity, weapon, sizeof(weapon));
	
	if(g_bExBoomer && StrEqual(weapon, "CBoomerClaw"))
	{
		return false;
	}
	
	if(g_bExSpitter && StrEqual(weapon, "CSpitterClaw"))
	{
		return false;
	}
	
	if(g_bExHunter && StrEqual(weapon, "CHunterClaw"))
	{
		return false;
	}
	
	if(g_bExSmoker && StrEqual(weapon, "CSmokerClaw"))
	{
		return false;
	}
	
	if(g_bExJockey && StrEqual(weapon, "CJockeyClaw"))
	{
		return false;
	}
	
	if(g_bExCharger && StrEqual(weapon, "CChargerClaw"))
	{
		return false;
	}
	
	if(g_bExTank && StrEqual(weapon, "CTankClaw"))
	{
		return false;
	}
	
	return true;
}