#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

#define L4D2 DLRVicious
#define PLUGIN_VERSION "2.00"

#define ZOMBIECLASS_SMOKER 1
#define ZOMBIECLASS_BOOMER 2
#define ZOMBIECLASS_SPITTER 4
#define ZOMBIECLASS_JOCKEY 5

///Boomer
//Bools
new bool:isBoomer = false;
new bool:isBileFeet = false;
new bool:isBileMask = false;
new bool:isBileMaskTilDry = false;
new bool:isBileShower = false;
new bool:isBileShowerTimeout;
new bool:isBileSwipe = false;

//Handles
new Handle:cvarBoomer;
new Handle:cvarBileFeet;
new Handle:cvarBileFeetSpeed;
new Handle:cvarBileFeetTimer[MAXPLAYERS + 1] = INVALID_HANDLE;
new Handle:cvarBileMask;
new Handle:cvarBileMaskState;
new Handle:cvarBileMaskAmount;
new Handle:cvarBileMaskDuration;
new Handle:cvarBileMaskTimer[MAXPLAYERS + 1] = INVALID_HANDLE;
new Handle:cvarBileShower;
new Handle:cvarBileShowerTimeout;
new Handle:cvarBileShowerTimer[MAXPLAYERS + 1] = INVALID_HANDLE;
new Handle:cvarBileSwipe;
new Handle:cvarBileSwipeChance;
new Handle:cvarBileSwipeDuration;
new Handle:cvarBileSwipeTimer[MAXPLAYERS + 1] = INVALID_HANDLE;
new bileswipe[MAXPLAYERS+1];


//Jockey
//Bools
new bool:isJockey = false;
new bool:isBacterial = false;
new bool:isDerbyDaze = false;
new bool:isGhostStalker = false;
new bool:isRiding = false;

//Handles
new Handle:cvarJockey;
new Handle:cvarBacterial;
new Handle:cvarBacterialChance;
new Handle:cvarBacterialDuration;
new Handle:cvarBacterialTimer[MAXPLAYERS + 1] = INVALID_HANDLE;
new Handle:cvarDerbyDaze;
new Handle:cvarDerbyDazeAmount;
new Handle:cvarGhostStalker;
new Handle:cvarGhostStalkerChance;
new bacterial[MAXPLAYERS+1];


///Smoker
//Bools
new bool:isSmoker = false;
new bool:isCollapsedLung = false;
new bool:isMoonWalk = false;
new bool:moonwalk[MAXPLAYERS+1];

//Handles
new Handle:cvarSmoker;
new Handle:cvarCollapsedLung;
new Handle:cvarCollapsedLungChance;
new Handle:cvarCollapsedLungDuration;
new Handle:cvarCollapsedLungTimer[MAXPLAYERS + 1] = INVALID_HANDLE;
new Handle:cvarMoonWalk;
new Handle:cvarMoonWalkSpeed;
new Handle:cvarMoonWalkStretch;
new Handle:MoonWalkTimer[MAXPLAYERS+1] = INVALID_HANDLE;
new collapsedlung[MAXPLAYERS+1];


///Spitter
//Bools
new bool:isSpitter = false;
new bool:isAcidSwipe = false;
new bool:isStickyGoo = false;
new bool:isSupergirl = false;
new bool:isSupergirlSpeed = false;

//Handles
new Handle:cvarSpitter;
new Handle:cvarAcidSwipe;
new Handle:cvarAcidSwipeChance;
new Handle:cvarAcidSwipeDuration;
new Handle:cvarAcidSwipeTimer[MAXPLAYERS + 1] = INVALID_HANDLE;
new Handle:cvarStickyGoo;
new Handle:cvarStickyGooDuration;
new Handle:cvarStickyGooSpeed;
new Handle:cvarStickyGooJump;
new Handle:cvarStickyGooTimer[MAXPLAYERS + 1] = INVALID_HANDLE;
new Handle:cvarSupergirl;
new Handle:cvarSupergirlSpeed;
new Handle:cvarSupergirlDuration;
new Handle:cvarSupergirlSpeedDuration;
new Handle:cvarSupergirlTimer[MAXPLAYERS + 1] = INVALID_HANDLE;
new Handle:cvarSupergirlSpeedTimer[MAXPLAYERS + 1] = INVALID_HANDLE;
new acidswipe[MAXPLAYERS+1];


///Generic
static laggedMovementOffset = 0;
static velocityModifierOffset = 0;
static const		JUMPFLAG				= IN_JUMP;
new bool:isEnabled = false;
new bool:isAnnounce = false;
new bool:isSlowed[MAXPLAYERS+1] = false;

new Handle:PluginStartTimer = INVALID_HANDLE;
new Handle:cvarEnabled;
new Handle:cvarAnnounce;
new Handle:hBecomeGhost;
new Handle:hBecomeGhostAt;
new Handle:hGameConf;
new UserMsg:DerbyDazeMsgID;


public Plugin:myinfo = 
{
    name = "DLR Vicious",
    author = "Mortiegama, DLR.O Ken",
    description = "This is a universal plugin that will add special abilities to the Infected team.",
    version = PLUGIN_VERSION,
    url = ""
}


public OnPluginStart()
{
	CreateConVar("dlr_vts_version", PLUGIN_VERSION, "DLRVicious Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	//First we setup everything that we need for the Boomer
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_now_it", Event_PlayerNowIt);
	HookEvent("player_no_longer_it", Event_PlayerNotIt);

	cvarBoomer = CreateConVar("l4d_vts_boomer", "1", "Enables the Boomer abilities. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarBileFeet = CreateConVar("l4d_vts_bilefeet", "1", "Increases the movement speed of the Boomer. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarBileFeetSpeed = CreateConVar("l4d_vts_bilefeetspeed", "1.5", "How much does Bile Feet increase the Boomer movement speed. (Def 1.5)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarBileMask = CreateConVar("l4d_vts_bilemask", "1", "Boomer Bile will cover the Survivors entire HUD. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarBileMaskState = CreateConVar("l4d_vts_bilemaskstate", "1", "Duration HUD Remains Hidden (0 = Cvar Set Duration, 1 = Until Bile Dries). (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarBileMaskAmount = CreateConVar("l4d_vts_bilemaskamount", "200", "Amount of visibility covered by the Boomer's bile (0 = None, 255 = Total). (Def 200)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarBileMaskDuration = CreateConVar("l4d_vts_bilemaskduration", "-1", "How long is the HUD hidden for after vomit (-1 = Until Dry, 0< is period of time). (Def 200)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarBileShower = CreateConVar("l4d_vts_bileshower", "1", "Summons a mob when the Boomer vomits/explodes on a Survivor. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarBileShowerTimeout = CreateConVar("l4d_vts_bileshowertimeout", "10", "How many seconds must a Boomer wait before summoning another mob. (Def 10)", FCVAR_PLUGIN, true, 1.0, false, _);
	cvarBileSwipe = CreateConVar("l4d_vts_bileswipe", "1", "When a Boomer claws a Survivor they will take damage over time (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarBileSwipeChance = CreateConVar("l4d_vts_bileswipechance", "100", "Chance that when a Boomer claws a Survivor they will take damage over time (100 = 100%). (Def 100)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarBileSwipeDuration = CreateConVar("l4d_vts_bileswipeduration", "10", "For how many seconds does the Bile Swipe last. (Def 10)", FCVAR_PLUGIN, true, 1.0, false, _);
	CreateConVar("l4d_vts_bileswipedamage", "1", "How much damage is inflicted by Bile Swipe each second. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);


	//Next we setup everything that we need for the Jockey
	HookEvent("jockey_ride", Event_JockeyRideStart);
	HookEvent("jockey_ride_end", Event_JockeyRideEnd);

	cvarJockey = CreateConVar("l4d_vts_jockey", "1", "Enables the Jockey abilities. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarBacterial = CreateConVar("l4d_vts_bacterialinfection", "1", "After a ride ends the Survivor takes damage over time. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarBacterialChance = CreateConVar("l4d_vts_bacterialinfectionchance", "100", "Chance that after a ride ends the Survivor takes damage over time (100 = 100%). (Def 100)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarBacterialDuration = CreateConVar("l4d_vts_bacterialduration", "10", "For how many seconds does the Bacterial Infection last. (Def 10)", FCVAR_PLUGIN, true, 1.0, false, _);
	CreateConVar("l4d_vts_bacterialdamage", "1", "How much damage is inflicted by Bacterial Infection each second. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarDerbyDaze = CreateConVar("l4d_vts_derbydaze", "1", "Jockey covers the Survivors eyes during a ride reducing visibility. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarDerbyDazeAmount = CreateConVar("l4d_vts_derbydazeamount", "200", "Amount of visibility covered by the Jockey's hand (0 = None, 255 = Total). (Def 200)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarGhostStalker = CreateConVar("l4d_vts_ghoststalker", "0", "When damaged, Jockey has a chance to returning to Ghost mode unless riding. (Def 0)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarGhostStalkerChance = CreateConVar("l4d_vts_ghoststalkerchance", "5", "Chance that the Jockey will return to Ghost mode (5 = 5%). (Def 5)", FCVAR_PLUGIN, true, 0.0, false, _);


	//Next we setup everything that we need for the Smoker
	HookEvent("choke_end", Event_ChokeEnd);
	HookEvent("tongue_grab", Event_TongueGrab);
	HookEvent("tongue_release", Event_TongueRelease, EventHookMode_Pre);

	cvarSmoker = CreateConVar("l4d_vts_smoker", "1", "Enables the Smoker abilities. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarCollapsedLung = CreateConVar("l4d_vts_collapsedlung", "1", "After a ride ends the Survivor takes damage over time. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarCollapsedLungChance = CreateConVar("l4d_vts_collapsedlungchance", "100", "Chance that after a ride ends the Survivor takes damage over time (100 = 100%). (Def 100)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarCollapsedLungDuration = CreateConVar("l4d_vts_collapsedlungduration", "5", "For how many seconds does the Collapsed Lung last. (Def 5)", FCVAR_PLUGIN, true, 1.0, false, _);
	CreateConVar("l4d_vts_collapsedlungdamage", "1", "How much damage is inflicted by Collapsed Lung each second. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarMoonWalk = CreateConVar("l4d_vts_moonwalk", "1", "Smoker is able to move and drag Survivor after tongue grab. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarMoonWalkSpeed = CreateConVar("l4d_vts_moonwalkspeed", "0.4", "How fast will the Smoker move after a tongue grab and drag. (Def 0.4)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarMoonWalkStretch = CreateConVar("l4d_vts_moonwalkstretch", "2000", "How far the Smokers tongue can stretch before it snaps. (Def 2000)", FCVAR_PLUGIN, true, 0.0, false, _);


	//Next we setup everything that we need for the Spitter
	HookEvent("entered_spit", Event_EnteredSpit);
	HookEvent("spit_burst", Event_SpitBurst);

	cvarSpitter = CreateConVar("l4d_vts_spitter", "1", "Enables the Spitter abilities. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarAcidSwipe = CreateConVar("l4d_vts_acidswipe", "1", "When a Spitter claws a Survivor they will take damage over time (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarAcidSwipeChance = CreateConVar("l4d_vts_acidswipechance", "100", "Chance that when a Spitter claws a Survivor they will take damage over time (100 = 100%). (Def 100)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarAcidSwipeDuration = CreateConVar("l4d_vts_acidswipeduration", "10", "For how many seconds does the Acid Swipe last. (Def 10)", FCVAR_PLUGIN, true, 1.0, false, _);
	CreateConVar("l4d_vts_acidswipedamage", "1", "How much damage is inflicted by Acid Swipe each second. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarStickyGoo = CreateConVar("l4d_vts_stickygoo", "1", "Slows down Survivor when standing in spit. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarStickyGooDuration = CreateConVar("l4d_vts_stickygooduration", "6", "How long a Survivor is slowed for aftering entering spit. (Def 6)", FCVAR_PLUGIN, true, 1.0, false, _);
	cvarStickyGooSpeed = CreateConVar("l4d_vts_stickygoospeed", "0.5", "Speed reduction to Survivor. (Def 0.5)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarStickyGooJump = CreateConVar("l4d_vts_stickygoojump", "1", "Speed reduction to Survivor jumping. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarSupergirl = CreateConVar("l4d_vts_supergirl", "1", "Temporary invulnerability after Spitter spits. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarSupergirlSpeed = CreateConVar("l4d_vts_supergirlspeed", "1", "Removes speed loss after Spitter spits. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarSupergirlDuration = CreateConVar("l4d_vts_supergirlduration", "4", "How long the Spitter is invulnerable. (Def 4)", FCVAR_PLUGIN, true, 1.0, false, _);
	cvarSupergirlSpeedDuration = CreateConVar("l4d_vts_supergirlspeedduration", "4", "How long the Spitter is invulnerable. (Def 4)", FCVAR_PLUGIN, true, 1.0, false, _);


	//This area is for general information
	HookEvent("player_incapacitated", Event_PlayerIncapped);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("round_end", Event_RoundEnd);

	cvarEnabled = CreateConVar("l4d_vts_enable", "1", "Enables the Vicious Infected plugin.");

	laggedMovementOffset = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");
	velocityModifierOffset = FindSendPropInfo("CTerrorPlayer", "m_flVelocityModifier");
	
	AutoExecConfig(true, "plugin.L4D2.DLRVicious_SSHJ");
	PluginStartTimer = CreateTimer(3.0, OnPluginStart_Delayed);

	if (GetConVarInt(cvarEnabled))
	{
		isEnabled = true;
	}

	hGameConf = LoadGameConfigFile("l4d2_viciousinfected");
	if (hGameConf != INVALID_HANDLE)
	{	
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "BecomeGhost");
		PrepSDKCall_AddParameter(SDKType_PlainOldData , SDKPass_Plain);
		hBecomeGhost = EndPrepSDKCall();

		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "BecomeGhostAt");
		PrepSDKCall_AddParameter(SDKType_PlainOldData , SDKPass_Plain);
		hBecomeGhostAt = EndPrepSDKCall();
	}
}

public Action:OnPluginStart_Delayed(Handle:timer)
{
	if (isEnabled)
	{
	//First we setup the Bool for the Boomer

	if (GetConVarInt(cvarBoomer))
	{
		isBoomer = true;
	}

	if (GetConVarInt(cvarBileFeet))
	{
		isBileFeet = true;
	}

	if (GetConVarInt(cvarBileMask))
	{
		isBileMask = true;
	}

	if (GetConVarInt(cvarBileMaskState))
	{
		isBileMaskTilDry = true;
	}

	if (GetConVarInt(cvarBileShower))
	{
		isBileShower = true;
	}

	if (GetConVarInt(cvarBileSwipe))
	{
		isBileSwipe = true;
	}


	//Next we setup the Bool for the Jockey

	if (GetConVarInt(cvarJockey))
	{
		isJockey = true;
	}

	if (GetConVarInt(cvarBacterial))
	{
		isBacterial = true;
	}

	if (GetConVarInt(cvarDerbyDaze))
	{
		isDerbyDaze = true;
	}

	if (GetConVarInt(cvarGhostStalker))
	{
		isGhostStalker = true;
	}

	
	//Next we setup the Bool for the Smoker

	if (GetConVarInt(cvarSmoker))
	{
		isSmoker = true;
	}

	if (GetConVarInt(cvarCollapsedLung))
	{
		isCollapsedLung = true;
	}


	if (GetConVarInt(cvarMoonWalk))
	{
		isMoonWalk = true;
	}

	
	//Next we setup the Bool for the Spitter

	if (GetConVarInt(cvarSpitter))
	{
		isSpitter = true;
	}

	if (GetConVarInt(cvarAcidSwipe))
	{
		isAcidSwipe = true;
	}

	if (GetConVarInt(cvarStickyGoo))
	{
		isStickyGoo = true;
	}

	if (GetConVarInt(cvarSupergirl))
	{
		isSupergirl = true;
	}

	if (GetConVarInt(cvarSupergirlSpeed))
	{
		isSupergirlSpeed = true;
	}
	
	}

	//Finally we setup Generic Bools

	if (GetConVarInt(cvarAnnounce))
	{
		isAnnounce = true;
	}


	if(PluginStartTimer != INVALID_HANDLE)
		{
 		KillTimer(PluginStartTimer);
		PluginStartTimer = INVALID_HANDLE;
		}	
	
	return Plugin_Continue;
}

public OnMapStart()
{
	/* Precache Models */
	PrecacheModel("models/infected", true);
	PrecacheModel("models/infected", true);	

	decl String:GameMode[16];
	GetConVarString(FindConVar("mp_gamemode"), GameMode, sizeof(GameMode));
}


///Universal Events

//This will setup events that are required for more than one ability

public Event_PlayerSpawn (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));

	if (IsValidClient(client) && GetClientTeam(client) == 3)
	{
		new class = GetEntProp(client, Prop_Send, "m_zombieClass");
		if (class == ZOMBIECLASS_BOOMER)
		{
			if (isBoomer && isBileFeet)
			{
			cvarBileFeetTimer[client] = CreateTimer(0.5, Event_BoomerBileFeet, client);
			}
		}
	}
}

//This is a call for the Sticky Goo

public OnGameFrame()
{
    for (new client=1; client<=MaxClients; client++)
	{
	if (IsValidClient(client) && GetClientTeam(client) == 2 && isSlowed[client])
	{
		new flags = GetEntityFlags(client);
		
		if (flags & JUMPFLAG)
		{
		//PrintHintText(client, "JUMPER!");
		SetEntDataFloat(client, velocityModifierOffset, GetConVarFloat(cvarStickyGooJump), true); 
		}
	}
	}
}

public Event_PlayerHurt (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	decl String:weapon[64];
	GetEventString(event, "weapon", weapon, sizeof(weapon));

//This is the Hook for Acid Swipe - Survivor takes damage over time after being Spitter clawed

	if (isSpitter && isAcidSwipe)
	{
		if (IsValidClient(client) && GetClientTeam(client) == 2 && StrEqual(weapon, "spitter_claw"))
		{
			new AcidSwipeChance = GetRandomInt(0, 99);
			new AcidSwipePercent = (GetConVarInt(cvarAcidSwipeChance));

			if (AcidSwipeChance < AcidSwipePercent)
			{
			if (isAnnounce) {PrintHintText(client, "The Spitter has coated you with corrosive acid!");}
			if(acidswipe[client] <= 0)
				{
				acidswipe[client] = (GetConVarInt(cvarAcidSwipeDuration));
				cvarAcidSwipeTimer[client] = CreateTimer(1.0, Timer_AcidSwipe, client, TIMER_REPEAT);
				}
			}
		}
	}

//This is the Hook for Bile Swipe - Survivor takes damage over time after being Boomer clawed

	if (isBoomer && isBileSwipe)
	{
		if (IsValidClient(client) && GetClientTeam(client) == 2 && isBileSwipe && StrEqual(weapon, "boomer_claw"))
		{
			new BileSwipeChance = GetRandomInt(0, 99);
			new BileSwipePercent = (GetConVarInt(cvarBileSwipeChance));

			if (BileSwipeChance < BileSwipePercent)
			{
			if (isAnnounce) {PrintHintText(client, "The Boomer has coated you with stomach bile acid!");}
			if(bileswipe[client] <= 0)
				{
				bileswipe[client] = (GetConVarInt(cvarBileSwipeDuration));
				cvarBileSwipeTimer[client] = CreateTimer(1.0, Timer_BileSwipe, client, TIMER_REPEAT);
				}
			}
		}
	}

//This is the Hook for Ghost Stalker - Chance that when taking damage Jockey will return to Ghost mode

	if (isJockey && isGhostStalker && !isRiding)
	{
	new class = GetEntProp(client, Prop_Send, "m_zombieClass");

	if (class == ZOMBIECLASS_JOCKEY)
		{
		new GhostStalkerChance = GetRandomInt(0, 99);
		new GhostStalkerPercent = (GetConVarInt(cvarGhostStalkerChance));

		if (IsValidClient(client) && !IsPlayerGhost(client) && (GhostStalkerChance < GhostStalkerPercent))
			{
			SDKCall(hBecomeGhost, client, 1);
			SDKCall(hBecomeGhostAt, client, 0);	
			}
		}
	}
}



///Boomer

//This will setup the Bile Feet - Increases the Boomer movement speed

public Action:Event_BoomerBileFeet(Handle:timer, any:client) 
{
	if (IsValidClient(client))
	{
		if (isAnnounce) {PrintHintText(client, "Bile Feet has granted you increased movement speed!");}
		SetEntDataFloat(client, laggedMovementOffset, 1.0*GetConVarFloat(cvarBileFeetSpeed), true);
		SetConVarFloat(FindConVar("z_vomit_fatigue"),0.0,false,false);
	}
	
	if(cvarBileFeetTimer[client] != INVALID_HANDLE)
	{
 		KillTimer(cvarBileFeetTimer[client]);
		cvarBileFeetTimer[client] = INVALID_HANDLE;
	}
		
	return Plugin_Stop;	
}

//This will setup the Bile Mask - Hides the Survivor's HUD when vomited on

public Event_PlayerNotIt (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (isBoomer && isBileMask)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));

		if (IsValidClient(client))
		{	
			SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
		}
	}
}

public Action:Timer_BileMask(Handle:timer, any:client) 
{
	if (isBoomer && isBileMask)
	{
		if (IsValidClient(client))
		{	
			SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
		}
	}

	if(cvarBileMaskTimer[client] != INVALID_HANDLE)
	{
		KillTimer(cvarBileMaskTimer[client]);
		cvarBileMaskTimer[client] = INVALID_HANDLE;
	}	
	
	return Plugin_Stop;	
}

//This will setup the Bile Shower - Summons a mob when Boomer vomits/explodes on a Survivor

public Event_PlayerNowIt (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (isBoomer && isBileShower && !isBileShowerTimeout)
	{
		new client = GetClientOfUserId(GetEventInt(event, "attacker"));
		isBileShowerTimeout = true;
		cvarBileShowerTimer[client] = CreateTimer(GetConVarFloat(cvarBileShowerTimeout), BileShowerTimeout, client);
		new flags = GetCommandFlags("z_spawn_old");
		SetCommandFlags("z_spawn_old", flags & ~FCVAR_CHEAT);
		FakeClientCommand(client,"z_spawn_old mob auto");
		SetCommandFlags("z_spawn_old", flags|FCVAR_CHEAT);
	}

	if (isBoomer && isBileMask)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));

		if (IsValidClient(client))
		{	
			SetEntProp(client, Prop_Send, "m_iHideHUD", GetConVarInt(cvarBileMaskAmount));
			if (!isBileMaskTilDry)
			{
			cvarBileMaskTimer[client] = CreateTimer(GetConVarFloat(cvarBileMaskDuration), Timer_BileMask, client);
			}
		}
	}
}

public Action:BileShowerTimeout(Handle:timer, any:client)
{
	isBileShowerTimeout = false;
	
	if(cvarBileShowerTimer[client] != INVALID_HANDLE)
		{
		KillTimer(cvarBileShowerTimer[client]);
		cvarBileShowerTimer[client] = INVALID_HANDLE;
		}	

	return Plugin_Stop;	
}

//This will setup the Bile Swipe - Survivor takes damage over time after being Boomer clawed

public Action:Timer_BileSwipe(Handle:timer, any:client) 
{
	if (IsValidClient(client))
	{
	if(bileswipe[client] <= 0)
		{
			if (cvarBileSwipeTimer[client] != INVALID_HANDLE)
			{
				KillTimer(cvarBileSwipeTimer[client]);
				cvarBileSwipeTimer[client] = INVALID_HANDLE;
			}
			
			return Plugin_Stop;
		}

	Damage_BileSwipe(client);
	
	if(bileswipe[client] > 0) 
	{
		bileswipe[client] -= 1;
	}
	}
	
	return Plugin_Continue;
}

public Action:Damage_BileSwipe(client)
{
	new String:dmg_str[10];
	new String:dmg_type_str[10];
	IntToString((1 << 25),dmg_str,sizeof(dmg_type_str));
	GetConVarString(FindConVar("l4d_vts_bileswipedamage"), dmg_str, sizeof(dmg_str));
	new pointHurt=CreateEntityByName("point_hurt");
	DispatchKeyValue(client,"targetname","war3_hurtme");
	DispatchKeyValue(pointHurt,"DamageTarget","war3_hurtme");
	DispatchKeyValue(pointHurt,"Damage",dmg_str);
	DispatchKeyValue(pointHurt,"DamageType",dmg_type_str);
	DispatchSpawn(pointHurt);
	AcceptEntityInput(pointHurt,"Hurt", client);
	DispatchKeyValue(client,"targetname","war3_donthurtme");
	RemoveEdict(pointHurt);
}



///Jockey

//This will setup the Bacterial Infection - Deals damage over time after Jockey Ride ended

public Event_JockeyRideEnd (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (isJockey && isBacterial)
	{
	new client = GetClientOfUserId(GetEventInt(event,"victim"));

	if (IsValidClient(client) && GetClientTeam(client) == 2)
		{
		new BacterialChance = GetRandomInt(0, 99);
		new BacterialPercent = (GetConVarInt(cvarBacterialChance));

		if (BacterialChance < BacterialPercent)
			{
			if (isAnnounce) {PrintHintText(client, "The Jockey has caused a bacterial infection!");}
			if(bacterial[client] <= 0)
				{
				bacterial[client] = (GetConVarInt(cvarBacterialDuration));
				cvarBacterialTimer[client] = CreateTimer(1.0, Timer_Bacterial, client, TIMER_REPEAT);
				}
			}
		}
	}

	if (isJockey && isDerbyDaze)
	{
	new client = GetClientOfUserId( GetEventInt( event, "victim"));

	if (IsValidClient(client) && GetClientTeam(client) == 2)
		{	
		DerbyDaze(client, 0);
		SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
		}
	}

	if (isJockey && isGhostStalker)
	{
		isRiding = false;	
	}
}

public Action:Timer_Bacterial(Handle:timer, any:client) 
{
	if (IsValidClient(client))
	{
	if(bacterial[client] <= 0) 
		{
			if (cvarBacterialTimer[client] != INVALID_HANDLE)
			{
				KillTimer(cvarBacterialTimer[client]);
				cvarBacterialTimer[client] = INVALID_HANDLE;
			}
			
			return Plugin_Stop;
		}
		
	Damage_Bacterial(client);
	
	if(bacterial[client] > 0) 
	{
		bacterial[client] -= 1;
	}
	}
	
	return Plugin_Continue;
}

public Action:Damage_Bacterial(client)
{
	new String:dmg_str[10];
	new String:dmg_type_str[10];
	IntToString((1 << 25),dmg_str,sizeof(dmg_type_str));
	GetConVarString(FindConVar("l4d_vts_bacterialdamage"), dmg_str, sizeof(dmg_str));
	new pointHurt=CreateEntityByName("point_hurt");
	DispatchKeyValue(client,"targetname","war3_hurtme");
	DispatchKeyValue(pointHurt,"DamageTarget","war3_hurtme");
	DispatchKeyValue(pointHurt,"Damage",dmg_str);
	DispatchKeyValue(pointHurt,"DamageType",dmg_type_str);
	DispatchSpawn(pointHurt);
	AcceptEntityInput(pointHurt,"Hurt", client);
	DispatchKeyValue(client,"targetname","war3_donthurtme");
	RemoveEdict(pointHurt);
}

//This will setup Derby Daze - Blindfolds a Survivor during a Jockey ride

public Action:Event_JockeyRideStart( Handle:event, const String:name[], bool:dontBroadcast )
{
	if (isJockey && isDerbyDaze)
	{
		new client = GetClientOfUserId( GetEventInt( event, "victim"));

		if (IsValidClient(client))
		{	
			DerbyDaze(client, GetConVarInt(cvarDerbyDazeAmount));
			SetEntProp(client, Prop_Send, "m_iHideHUD", GetConVarInt(cvarDerbyDazeAmount));
		}
	}

//This will setup Ghost Stalker - Chance that when taking damage Jockey will return to Ghost mode

	if (isJockey && isGhostStalker)
	{
		isRiding = true;	
	}

	return Plugin_Stop;
}

DerbyDaze(client, amount)
{
	new clients[2];
	clients[0] = client;

	DerbyDazeMsgID = GetUserMessageId("Fade");
	new Handle:message = StartMessageEx(DerbyDazeMsgID, clients, 1);
	BfWriteShort(message, 1536);
	BfWriteShort(message, 1536);
	
	if (amount == 0)
	{
		BfWriteShort(message, (0x0001 | 0x0010));
	}
	else
	{
		BfWriteShort(message, (0x0002 | 0x0008));
	}
	
	BfWriteByte(message, 0);
	BfWriteByte(message, amount);
	
	EndMessage();
}


///Smoker

//This will setup Collapsed Lung - Survivor takes damage over time after Choke End

public Event_ChokeEnd (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (isSmoker && isCollapsedLung)
	{
	new client = GetClientOfUserId(GetEventInt(event,"victim"));

	if (IsValidClient(client) && GetClientTeam(client) == 2)
		{
		new CollapsedLungChance = GetRandomInt(0, 99);
		new CollapsedLungPercent = (GetConVarInt(cvarCollapsedLungChance));

		if (CollapsedLungChance < CollapsedLungPercent)
			{
			if (isAnnounce) {PrintHintText(client, "The Smoker has collapsed your lung!");}
			if(collapsedlung[client] <= 0)
				{
				collapsedlung[client] = (GetConVarInt(cvarCollapsedLungDuration));
				cvarCollapsedLungTimer[client] = CreateTimer(1.0, Timer_CollapsedLung, client, TIMER_REPEAT);
				}
			}
		}
	}
}

public Action:Timer_CollapsedLung(Handle:timer, any:client) 
{
	if (IsValidClient(client))
	{
	if(collapsedlung[client] <= 0) 
		{
			if (cvarCollapsedLungTimer[client] != INVALID_HANDLE)
			{
				KillTimer(cvarCollapsedLungTimer[client]);
				cvarCollapsedLungTimer[client] = INVALID_HANDLE;
			}
			
			return;
		}
		
	Damage_CollapsedLung(client);
	
	if(collapsedlung[client] > 0) 
	{
		collapsedlung[client] -= 1;
	}
	}
}

public Action:Damage_CollapsedLung(client)
{
	new String:dmg_str[10];
	new String:dmg_type_str[10];
	IntToString((1 << 25),dmg_str,sizeof(dmg_type_str));
	GetConVarString(FindConVar("l4d_vts_collapsedlungdamage"), dmg_str, sizeof(dmg_str));
	new pointHurt=CreateEntityByName("point_hurt");
	DispatchKeyValue(client,"targetname","war3_hurtme");
	DispatchKeyValue(pointHurt,"DamageTarget","war3_hurtme");
	DispatchKeyValue(pointHurt,"Damage",dmg_str);
	DispatchKeyValue(pointHurt,"DamageType",dmg_type_str);
	DispatchSpawn(pointHurt);
	AcceptEntityInput(pointHurt,"Hurt", client);
	DispatchKeyValue(client,"targetname","war3_donthurtme");
	RemoveEdict(pointHurt);
}

//This will setup the Moon Walk - Smoker is able to move and drag victims after ensnaring

public Event_TongueGrab (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (isSmoker && isMoonWalk)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new victim = GetClientOfUserId(GetEventInt(event, "victim"));
		new Handle:pack;

		if (IsValidClient(client))
			{
			moonwalk[client] = true;
			SetEntityMoveType(client, MOVETYPE_ISOMETRIC);
			SetEntDataFloat(client, laggedMovementOffset, 1.0*GetConVarFloat(cvarMoonWalkSpeed), true);
			MoonWalkTimer[client] = CreateDataTimer(0.2, Timer_MoonWalk, pack, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
			WritePackCell(pack, client);
			WritePackCell(pack, victim);
			}
	}
}

public Action:Timer_MoonWalk(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	if ((!IsValidClient(client))||(GetClientTeam(client)!=3)||(moonwalk[client] = false))
		{
		KillTimer(MoonWalkTimer[client]);
		MoonWalkTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
		}
			
	new Victim = ReadPackCell(pack);
	if ((!IsValidClient(Victim))||(GetClientTeam(Victim)!=2)||(moonwalk[client] = false))
		{
		KillTimer(MoonWalkTimer[client]);
		MoonWalkTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
		}
	
	new MoonWalkStretch = GetConVarInt(cvarMoonWalkStretch);
	new Float:SmokerPosition[3];
	new Float:VictimPosition[3];
	GetClientAbsOrigin(client,SmokerPosition);
	GetClientAbsOrigin(Victim,VictimPosition);
	new distance = RoundToNearest(GetVectorDistance(SmokerPosition, VictimPosition));

	if (distance > MoonWalkStretch)
		{
			SlapPlayer(client, 0, false);
			if (isAnnounce) {PrintHintText(client, "The Tongue has been stretched/bent and snapped!");}
		}

	return Plugin_Continue;
}

public Action:Event_TongueRelease(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (isSmoker && isMoonWalk)	
	{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsValidClient(client))
		{
		moonwalk[client] = false;
		SetEntityMoveType(client, MOVETYPE_CUSTOM);
		SetEntDataFloat(client, laggedMovementOffset, 1.0, true);
		if (MoonWalkTimer[client] != INVALID_HANDLE)
			{
			KillTimer(MoonWalkTimer[client]);
			MoonWalkTimer[client] = INVALID_HANDLE;
			}
		}
	}
}


///Spitter

//This will setup the Acid Swipe - Survivor takes damage over time after being Spitter clawed

public Action:Timer_AcidSwipe(Handle:timer, any:client) 
{
	if (IsValidClient(client))
	{
	if(acidswipe[client] <= 0)
		{
			if (cvarAcidSwipeTimer[client] != INVALID_HANDLE)
			{
				KillTimer(cvarAcidSwipeTimer[client]);
				cvarAcidSwipeTimer[client] = INVALID_HANDLE;
			}
			
			return Plugin_Stop;
		}

	Damage_AcidSwipe(client);
	
	if(acidswipe[client] > 0) 
	{
		acidswipe[client] -= 1;
	}
	}
	
	return Plugin_Continue;
}

public Action:Damage_AcidSwipe(client)
{
	new String:dmg_str[10];
	new String:dmg_type_str[10];
	IntToString((1 << 25),dmg_str,sizeof(dmg_type_str));
	GetConVarString(FindConVar("l4d_vts_acidswipedamage"), dmg_str, sizeof(dmg_str));
	new pointHurt=CreateEntityByName("point_hurt");
	DispatchKeyValue(client,"targetname","war3_hurtme");
	DispatchKeyValue(pointHurt,"DamageTarget","war3_hurtme");
	DispatchKeyValue(pointHurt,"Damage",dmg_str);
	DispatchKeyValue(pointHurt,"DamageType",dmg_type_str);
	DispatchSpawn(pointHurt);
	AcceptEntityInput(pointHurt,"Hurt", client);
	DispatchKeyValue(client,"targetname","war3_donthurtme");
	RemoveEdict(pointHurt);
}

//This will setup Sticky Goo - Reduce the speed of Survivors if they enter Spit

public Event_EnteredSpit (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (isSpitter && isStickyGoo)
	{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));

	if (IsValidClient(client) && GetClientTeam(client) == 2 && !isSlowed[client])
		{
		isSlowed[client] = true;
		if (isAnnounce) {PrintHintText(client, "Standing in the spit is slowing you down!");}
		cvarStickyGooTimer[client] = CreateTimer(GetConVarFloat(cvarStickyGooDuration), StickyGoo, client);
		SetEntDataFloat(client, laggedMovementOffset, GetConVarFloat(cvarStickyGooSpeed), true);
		}
	}
}

public Action:StickyGoo(Handle:timer, any:client)
{
	if (IsValidClient(client))
	{
		SetEntDataFloat(client, laggedMovementOffset, 1.0, true); //sets the survivors speed back to normal
		if (isAnnounce) {PrintHintText(client, "The spit is wearing off!");}
		isSlowed[client] = false;
		
		if (cvarStickyGooTimer[client] != INVALID_HANDLE)
			{
				KillTimer(cvarStickyGooTimer[client]);
				cvarStickyGooTimer[client] = INVALID_HANDLE;
			}
	}
	
	return Plugin_Stop;
}

//This will setup Supergirl - Makes the Spitter temporarily invulnerable after spitting
public Event_SpitBurst (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	
	if (isSpitter && isSupergirl && IsValidClient(client))
	{
		if (isAnnounce) {PrintHintText(client, "You are temporarily invulnerable!");}
		cvarSupergirlTimer[client] = CreateTimer(GetConVarFloat(cvarSupergirlDuration), Supergirl, client);	
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
	}
	
	if (isSpitter && isSupergirlSpeed && IsValidClient(client))
	{
		cvarSupergirlSpeedTimer[client] = CreateTimer(GetConVarFloat(cvarSupergirlSpeedDuration), SupergirlSpeed, client);	
		SetEntDataFloat(client, laggedMovementOffset, 2.0, true);
	}
}

public Action:Supergirl(Handle:timer, any:client)
{
	if (IsValidClient(client))
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		if (isAnnounce) {PrintHintText(client, "You are no longer invulnerable!");}
	}

	if (cvarSupergirlTimer[client] != INVALID_HANDLE)
	{
		KillTimer(cvarSupergirlTimer[client]);
		cvarSupergirlTimer[client] = INVALID_HANDLE;
	}
	
	return Plugin_Stop;
}

public Action:SupergirlSpeed(Handle:timer, any:client)
{
	if (IsValidClient(client))
	{
		SetEntDataFloat(client, laggedMovementOffset, 1.0, true);
	}
	
	if (cvarSupergirlSpeedTimer[client] != INVALID_HANDLE)
	{
		KillTimer(cvarSupergirlSpeedTimer[client]);
		cvarSupergirlSpeedTimer[client] = INVALID_HANDLE;
	}
		
	return Plugin_Stop;
}

///Finally we setup some reset variables

public Reset_Timers(client)
{
	//Boomer Timers
	if (cvarBileSwipeTimer[client] != INVALID_HANDLE)
	{
		KillTimer(cvarBileSwipeTimer[client]);
		cvarBileSwipeTimer[client] = INVALID_HANDLE;
	}
	
	//Jockey Timers
	if (cvarBacterialTimer[client] != INVALID_HANDLE)
	{
		KillTimer(cvarBacterialTimer[client]);
		cvarBacterialTimer[client] = INVALID_HANDLE;
	}
	
	//Smoker Timers
	if(cvarCollapsedLungTimer[client] != INVALID_HANDLE)
	{
 		KillTimer(cvarCollapsedLungTimer[client]);
		cvarCollapsedLungTimer[client] = INVALID_HANDLE;
	}	
	
	if(MoonWalkTimer[client] != INVALID_HANDLE)
	{
 		KillTimer(MoonWalkTimer[client]);
		MoonWalkTimer[client] = INVALID_HANDLE;
	}	
		
	//Spitter Timers
	if(cvarAcidSwipeTimer[client] != INVALID_HANDLE)
	{
		KillTimer(cvarAcidSwipeTimer[client]);
		cvarAcidSwipeTimer[client] = INVALID_HANDLE;
	}
	
}

public Event_PlayerIncapped (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (isJockey && isDerbyDaze)
	{
	new client = GetClientOfUserId( GetEventInt( event, "victim"));

	if (IsValidClient(client) && GetClientTeam(client) == 2)
		{	
		DerbyDaze(client, 0);
		SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
		}
	}
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsValidClient2(client) && GetClientTeam(client) == 2)
	{
		bacterial[client] = 0;
		collapsedlung[client] = 0;
		bileswipe[client] = 0;
		acidswipe[client] = 0;
		isSlowed[client] = false;
		DerbyDaze(client, 0);
		SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
		Reset_Timers(client);
	}
}

public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsValidClient2(client))
	{
		bacterial[client] = 0;
		collapsedlung[client] = 0;
		bileswipe[client] = 0;
		acidswipe[client] = 0;
		isSlowed[client] = false;
		DerbyDaze(client, 0);
		SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
		Reset_Timers(client);
	}
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsValidClient2(client) && GetClientTeam(client) == 2)
	{
		bacterial[client] = 0;
		collapsedlung[client] = 0;
		bileswipe[client] = 0;
		acidswipe[client] = 0;
		isSlowed[client] = false;
		DerbyDaze(client, 0);
		SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
	}
	Reset_Timers(client);
}

public IsValidClient(client)
{
	if (client == 0)
		return false;

	//if (IsFakeClient(client))
		//return false;
	
	if (!IsClientInGame(client))
		return false;
	
	if (!IsPlayerAlive(client))
		return false;

	return true;
}

public IsValidClient2(client)
{
	if (client == 0)
		return false;

	//if (IsFakeClient(client))
		//return false;
	
	if (!IsClientInGame(client))
		return false;
	
	return true;
}


public IsPlayerGhost(client)
{
	if (IsValidClient(client))
	{
		if (GetEntProp(client, Prop_Send, "m_isGhost")) return true;
		else return false;
	}
	return 1;
}