/**
	Credits : 
	[v1.0.0]
	Nut / toazron1 - For his [TF2] Donator Recognition plugin from where I took the show-overhead-sprite code.
	
	exvel for his questions (which he himself answered in the scripting section of SM)
	
	Twisted|Panda for his buyzone / buytime restriction examples
	
	psychonic for his buttons press/release code thread
	
	swixel and psychonic (again) for irc help
	
	Fredd for his "Radio Help Icon" plugin for the overhead radio icon :).
	
	javalia for his(her ?) stock functions (stocklib.inc) for how to reproduce a radio command :)
	
	tuty for his sound (isn't it tf2 ?)
	
	[v1.2.0]
	smithy for his awesome models search. He tooks some models (including the used one below) and recompiled them server-side for my plugin <3
		he's also the one who suggested models to be implemented.
	
	S-LoW for his terrorist (well... HL2) medic model and his support that I appreciate at his forum :
	http://s-low.info/forum/viewtopic.php?f=11&t=103 (model link)
	http://s-low.info/forum/viewtopic.php?f=48&t=1516 (S-LoW helping me)
	
	d0nn for his great CT medic model (resizing 2048^2 to 1024^2 .vtf by smithy) :
	http://www.gamebanana.com/skins/26846
	
	[languages]
	- lokizito		: brazilian portuguese (+ his translation project)
	- Leonardo		: russian
	- Wuestenfuchs	: german
	- BrianGriffin	: german ("Startround announce" phrase)
	(french was made by me)
*/
/**
	Changes :
	[v1.1.0]
	Announce at the beginning of every X round possible. (new CVar : bemedic_announce)
	Possibility to remove buytime restriction. (new CVar : bemedic_buytime)
	Possibility to remove buyzone restriction. (new CVar : bemedic_buyzone)
	Renamed CVar "bemedic_cost" to "bemedic_buycost". (so we get all buy-related CVars with the same prefix)
	Possibility to remove over-head animation. (new CVar : bemedic_overtimeheal_animation)
	Sound over radio now uses the same channel. (less spam :D)
	Added CVar to chose sound volume. (new CVar : bemedic_callMedic_volume)
	Possibility to remove over-head icon. (new CVar : bemedic_icon)
	
	[v1.2.0]
	Added possibility to use model for medics. (new CVar : bemedic_model)
	
	[v1.3.0]
	Added possibility to restrict medic training to a specific teams. (new CVar : bemedic_team)
	
	[v1.3.1]
	Fixed the fact that people could call medic even if their team couldn't purchase medic training.
	
	[v1.3.2]
	Added CVar to allow medics to heal other team. 
	Verbose with "teammate" as word aren't displayed when healing a player of other team (so it keeps making sense).
		(new CVar : bemedic_target)
	
	[v.1.3.3]
	Fixed translations code (some phrases could be in another language).
	
	[v.1.3.4]
	Fixed plugin's config's version conflict
	Now uses SourceMod default behavior to become medic (bemedic --> sm_bemedic; say commands stay the same)
	
	[v.1.3.5]
	Fixed sm_bemedic in server console giving an error (1.3.4 bug).
	
	[v.1.4.0]
	Added sm_random to randomly select the medics. This prevent people from buying medic training.
	Off by default to keep previous behaviour.
	Fixed verbose always showing even if plugin was disabled.
	Fixed to be able to call medic if plugin is disabled.
	Changed some CVars' descriptions.
	
	[v.1.4.1]
	Fixed typo :$
	Removed 1 include
	
	[v.1.4.2]
	Removed bots from being randomly selected as medics
	Removed FCVAR_REPLICATED from version convar
	Changed the 'var' variable so it compiles fine with the new compiler
*/

#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION	"1.4.2"

public Plugin:myinfo = 
{
	name = "Be Medic",
	author = "RedSword / Bob Le Ponge",
	description = "Allows to buy medic training and heal people.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

//Supports multiple sprites
#define TOTAL_SPRITE_FILES 1

//NOTE: Path to the filename ONLY (vtf/vmt added in plugin)
new const String:szSpriteFiles[ TOTAL_SPRITE_FILES ][] = 
{
	"materials/custom/redcross"
};

#define SOUND_FILE	"misc/medic.wav"
#define MEDIC_WITHOUT_ICON -2

//ConVars
new Handle:g_beMedic;
new Handle:g_beMedic_random; //since 1.4.0
new Handle:g_beMedic_range;
new Handle:g_beMedic_time;
new Handle:g_beMedic_heal;
new Handle:g_beMedic_maxHealth;
new Handle:g_beMedic_announce;
new Handle:g_beMedic_icon;
new Handle:g_beMedic_model;
new Handle:g_beMedic_team;
new Handle:g_beMedic_target;

new Handle:g_beMedic_overtimeheal_amount;
new Handle:g_beMedic_overtimeheal_delay;
new Handle:g_beMedic_overtimeheal_number;
new Handle:g_beMedic_overtimeheal_intrpt;
new Handle:g_beMedic_overtimeheal_animtn;

new Handle:g_beMedic_buycost;
new Handle:g_beMedic_buytime;
new Handle:g_beMedic_buyzone;

new Handle:g_beMedic_callMedic_radio;
new Handle:g_beMedic_callMedic_sound; //0 = no sound; 1 = radio sound; 2 = ambient sound
new Handle:g_beMedic_callMedic_volume;
new Handle:g_beMedic_callMedic_cooldown; //Def : 1.0

//Prevent re-running a function
new g_iVelocityOffset; //Speed of the player
new g_iAccount; //Money of the player
new g_iBuyZone; //If the player is in a buyzone
new Float:g_fFrameTime; //Time it takes to run a frame (can't be changed without server restart)
new g_flProgressBarStartTime;
new g_iProgressBarDuration;

//Vars - main
new g_iEnts[ MAXPLAYERS + 1 ]; //If the player is medic; it contains the entity id related to the sprite
new g_iMedicNumber_T; //Redundant; but can save some OnGameFrame runs
new g_iMedicNumber_CT; //Redundant; but can save some OnGameFrame runs

//SideVars
new Float:g_fTimeLimit;
new Float:g_fBuytime;

new Float:g_fSquareRange;

//SideVars - sprites related
new g_iHealModel;

///SideVars - models related
new String:g_szCTModel[ 256 ]; //CT model path
new String:g_szTModel[ 256 ]; //T model path

//prevent spamming radio
new Float:g_fRadioCooldown[ MAXPLAYERS + 1 ];

//Vars - heal related
new g_iLastUseState[ MAXPLAYERS + 1 ];
new g_iTarget[ MAXPLAYERS + 1 ];

new bool:g_bIsChanneling[ MAXPLAYERS + 1 ]; 
new Float:g_fChannelingTime[ MAXPLAYERS + 1 ]; //So we can use OnGameFrame()
new g_iHealingCount[ MAXPLAYERS + 1 ]; //To count waves

new Handle:g_hHealingTimer[ MAXPLAYERS + 1 ]; //When being healed; destroy to interrupt healing

//=====Forwards=====

public OnPluginStart()
{
	CreateConVar( "bemedicversion", PLUGIN_VERSION, "Be Medic version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD );
	
	g_beMedic = CreateConVar( "bemedic", "1", "Maximum medics per team. 0 = disable plugin. Def. 1.", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0 );
	g_beMedic_random = CreateConVar( "bemedic_random", "0", "Are the medic training given to random people ? 1=Yes, 0=No. Def. 0.",
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	g_beMedic_range = CreateConVar( "bemedic_range", "100.0", "The maximum distance for a medic to heal someone. Def. 100.0.", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0 );
	g_beMedic_time = CreateConVar( "bemedic_time", "2", "How many seconds it takes for a medic to heal someone. Integer. Def. 2.", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0 );
	g_beMedic_maxHealth = CreateConVar( "bemedic_maxHealth", "100", "Maximum life of someone (for custom plugins/mods). Def. 100.", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 1.0 );
	g_beMedic_heal = CreateConVar( "bemedic_heal", "10", "How much direct healing a medic does. Def. 10.", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 1.0 );
	g_beMedic_announce = CreateConVar( "bemedic_announce", "2", "Announce at the beginning of every X rounds that people can be medic. (If bemedic_random = 1, then announces who are the medics) 0 = No, 1+ = Yes. Def. 2.",
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0 );
	g_beMedic_icon = CreateConVar( "bemedic_icon", "0", "Show over head icon red cross ? 0 = No, 1 = Yes. Def. 0.", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	g_beMedic_model = CreateConVar( "bemedic_model", "1", "Give medics specific models ? 0 = No, 1 = Yes (Default).", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	g_beMedic_team = CreateConVar( "bemedic_team", "0", "Resrict a certain team from becoming medic? 0 = No, 1 = Yes (restrict T), 2 = Yes (restrict CT). Def. 0.", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 2.0 );
	g_beMedic_target = CreateConVar( "bemedic_target", "1", "Medics can only target their teammates? 0 = No, 1 = Yes (Default).", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	
	g_beMedic_overtimeheal_amount = CreateConVar( "bemedic_overtimeheal_amount", "4", "How much a heal does per wave. Def. 4.", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0 );
	g_beMedic_overtimeheal_delay = CreateConVar( "bemedic_overtimeheal_delay", "2.0", "How much time it takes between two healing wave. 0.0 = Disable overtime heal. Def. 2.0.", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0 );
	g_beMedic_overtimeheal_number = CreateConVar( "bemedic_overtimeheal_number", "10", "How many waves will it takes before wearing off. 0 = Disable overtime heal. Def. 10.", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0 );
	g_beMedic_overtimeheal_intrpt = CreateConVar( "bemedic_overtimeheal_interrupt", "1", "Does damage breaks overtime healing ? 0 = No, 1 = Yes (Default).", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	g_beMedic_overtimeheal_animtn = CreateConVar( "bemedic_overtimeheal_animation", "1", "Show healing animation ? 0 = No, 1 = Yes (Default).", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	
	g_beMedic_buycost = CreateConVar( "bemedic_buycost", "1000", "How much it costs to become medic. Def. 1000.", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0 );
	g_beMedic_buytime = CreateConVar( "bemedic_buytime", "1", "Restrict medic training purchase with buytime. 0 = No, 1 = Yes (Default).", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	g_beMedic_buyzone = CreateConVar( "bemedic_buyzone", "1", "Restrict medic training purchase to buyzones. 0 = No, 1 = Yes (Default).", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	
	g_beMedic_callMedic_radio = CreateConVar( "bemedic_callmedic_radio", "1", "Handle medic shout like a radio command ? 0 = No, 1 = Yes (Default).", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	g_beMedic_callMedic_sound = CreateConVar( "bemedic_callmedic_sound", "1", "How will the sound be played ? 0 = No sound, 1 = Radio sound, 2 = Ambient sound. Def. 1.", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 2.0 );
	g_beMedic_callMedic_volume = CreateConVar( "bemedic_callmedic_volume", "1.0", "How strong will the sound be played. Min = 0.0, max = 1.0 (Default).", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	g_beMedic_callMedic_cooldown = CreateConVar( "bemedic_callmedic_cooldown", "1.0", "Minimum time required between two calls for a medic. Def. 1.0.",
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0 );
	
	//Config
	AutoExecConfig( true, "bemedic" );
	
	//Hook on event
	HookEvent( "player_death", Event_OnPlayerDeath );
	HookEvent( "round_start", Event_OnRoundStart );
	HookEvent( "round_freeze_end", Event_OnFreezeEnd );
	HookEvent( "round_end", Event_OnRoundEnd );
	HookEvent( "player_hurt", Event_OnPlayerHurt );
	HookEvent( "player_spawn", Event_PlayerSpawn ); //SetModels
	
	//Translation file
	LoadTranslations("common.phrases");
	LoadTranslations("bemedic.phrases");
	
	//On cmd
	RegConsoleCmd( "sm_bemedic", BeMedic, "sm_bemedic" );
	RegConsoleCmd( "sm_medic", CallMedic, "sm_medic" );
	
	//Hook ConVar changes
	HookConVarChange( g_beMedic, ConVarChange_beMedic );
	HookConVarChange( FindConVar( "mp_buytime" ), ConVarChange_BuyTime );
	HookConVarChange( g_beMedic_range, ConVarChange_HealRange );
	
	//Optimizations (avoid root square computing for healing range)
	g_fSquareRange = GetConVarFloat( g_beMedic_range );
	g_fSquareRange *= g_fSquareRange;
	
	//Prevent re-running functions
	g_iVelocityOffset	= FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
	g_iAccount			= FindSendPropOffs("CCSPlayer", "m_iAccount");
	g_iBuyZone			= FindSendPropOffs("CCSPlayer", "m_bInBuyZone");
	g_fBuytime			= GetConVarFloat( FindConVar( "mp_buytime" ) );
	g_fFrameTime		= GetTickInterval();
	g_flProgressBarStartTime = FindSendPropOffs("CCSPlayer", "m_flProgressBarStartTime");
	g_iProgressBarDuration = FindSendPropOffs("CCSPlayer", "m_iProgressBarDuration");
}

public OnConfigsExecuted()
{
	//Sprites
	decl String:szBuffer[128];
	for (new i = 0; i < TOTAL_SPRITE_FILES; ++i)
	{
		FormatEx(szBuffer, sizeof(szBuffer), "%s.vmt", szSpriteFiles[i]);
		AddFileToDownloadsTable(szBuffer);
		PrecacheGeneric(szBuffer, true);
		g_iHealModel = PrecacheModel(szBuffer, true);
		
		FormatEx(szBuffer, sizeof(szBuffer), "%s.vtf", szSpriteFiles[i]);
		AddFileToDownloadsTable(szBuffer);
		PrecacheGeneric(szBuffer, true);
	}
	
	//Sound
	decl String:MedicSound[ 256 ];
	FormatEx( MedicSound, 256, "sound/%s", SOUND_FILE );
	if( FileExists( MedicSound )  )
	{
		AddFileToDownloadsTable( MedicSound );
		PrecacheSound( SOUND_FILE, true );
	}
	
	//Reset medics
	if (g_iMedicNumber_T + g_iMedicNumber_CT > 0)
		killAllSprites();
	
	//Models
	if ( GetConVarInt( g_beMedic ) == 0 ||
			GetConVarInt( g_beMedic_model ) == 0 )
		return;
	
	//Precache/download model
	const numberFiles = 8 + 12;
	decl String:medicModelFiles[ numberFiles ][ 256 ];
	//CT
	medicModelFiles[ 0 ]	= "models/player/smithy/ct_medic_v2/ct_urban.mdl";
	medicModelFiles[ 1 ]	= "models/player/smithy/ct_medic_v2/ct_urban.phy";
	medicModelFiles[ 2 ]	= "models/player/smithy/ct_medic_v2/ct_urban.sw.vtx";
	medicModelFiles[ 3 ]	= "models/player/smithy/ct_medic_v2/ct_urban.vvd";
	medicModelFiles[ 4 ]	= "models/player/smithy/ct_medic_v2/ct_urban.dx80.vtx";
	medicModelFiles[ 5 ]	= "models/player/smithy/ct_medic_v2/ct_urban.dx90.vtx";
	medicModelFiles[ 6 ]	= "materials/models/player/smithy/ct_medic_v2/ct_urban.vmt";
	medicModelFiles[ 7 ]	= "materials/models/player/smithy/ct_medic_v2/ct_urban.vtf";
	//T
	medicModelFiles[ 8 ]	= "models/player/slow/hl2/medic_male/slow.mdl";
	medicModelFiles[ 9 ]	= "models/player/slow/hl2/medic_male/slow.phy";
	medicModelFiles[ 10 ]	= "models/player/slow/hl2/medic_male/slow.sw.vtx";
	medicModelFiles[ 11 ]	= "models/player/slow/hl2/medic_male/slow.vvd";
	medicModelFiles[ 12 ]	= "models/player/slow/hl2/medic_male/slow.dx80.vtx";
	medicModelFiles[ 13 ]	= "models/player/slow/hl2/medic_male/slow.dx90.vtx";
	medicModelFiles[ 14 ]	= "materials/models/player/slow/hl2/medic_male/eric_facemap.vmt";
	medicModelFiles[ 15 ]	= "materials/models/player/slow/hl2/medic_male/eric_facemap.vtf";
	medicModelFiles[ 16 ]	= "materials/models/player/slow/hl2/medic_male/eyeball_l.vmt";
	medicModelFiles[ 17 ]	= "materials/models/player/slow/hl2/medic_male/eyeball_l.vtf";
	medicModelFiles[ 18 ]	= "materials/models/player/slow/hl2/medic_male/eyeball_r.vmt";
	medicModelFiles[ 19 ]	= "materials/models/player/slow/hl2/medic_male/eyeball_r.vtf";
	
	for ( new i; i < numberFiles; ++i)
		if ( !FileExists( medicModelFiles[ i ] ) )
		{
			PrintToServer("\"%s\" is missing; models won't be precached.", medicModelFiles[ i ] );
			return;
		}
	
	for ( new i; i < numberFiles; ++i)
		AddFileToDownloadsTable( medicModelFiles[ i ] );
		
	//CT
	g_szCTModel = medicModelFiles[ 0 ];
	PrecacheModel( g_szCTModel, true );
	//T
	g_szTModel = medicModelFiles[ 8 ];
	PrecacheModel( g_szTModel, true );
}

public OnGameFrame()
{
	//If plugin is enabled
	if ( !GetConVarInt( g_beMedic ) )
		return;
	
	for ( new i = 1; i <= MaxClients; ++i )
	{
		if ( g_fRadioCooldown[ i ] > 0.0 )
			g_fRadioCooldown[ i ] -= g_fFrameTime;
	}
	
	//Concerning medic/sprites/heal
	if ( g_iMedicNumber_T + g_iMedicNumber_CT == 0 )
		return;
	
	for	( new i = 1; i <= MaxClients; ++i )
	{
		if ( !IsClientInGame( i ) )
			continue;
		
		//About sprites and channeling-heal
		if ( g_iEnts[ i ] != 0 ) //If the player is medic
		{
			//No team or spec
			if ( GetClientTeam(i) < 2 ) 
			{
				KillSprite( i );
				countMedics();
			}
			else if ( g_bIsChanneling[ i ] ) //Channeling heal
				channelingHeal( i );
		}
		
		if ( g_iEnts[ i ] > 0 ) //If the player is medic WITH an icon
		{
			new ent = g_iEnts[ i ];
			
			if ( !IsValidEntity( ent ) ) //New round; need to recreate the deleted sprite
			{
				decl String:szBuffer[ 128 ];
				FormatEx( szBuffer, sizeof( szBuffer ), "%s.vmt", szSpriteFiles[ 0 ] );
				CreateSprite( i, szBuffer, 25.0 );
			}
			//Team is spectator or none; remove entity
			else if ( ( ent = EntRefToEntIndex( ent ) ) > 0 ) //Move sprite
			{
				decl Float:vOrigin[ 3 ];
				
				GetClientEyePosition( i, vOrigin );
				vOrigin[ 2 ] += 25.0;
				
				decl Float:vVelocity[ 3 ];
				GetEntDataVector( i, g_iVelocityOffset, vVelocity );
				
				TeleportEntity( ent, vOrigin, NULL_VECTOR, vVelocity );
			}
		}
	}
}

public OnClientDisconnect(iClient)
{
	//If plugin is enabled
	if ( !GetConVarInt( g_beMedic ) )
		return;
	
	//Sprite related
	KillSprite( iClient );
	countMedics();
	
	//Healing related
	g_iLastUseState[ iClient ] = 0;
	
	g_iTarget[ iClient ] = 0;

	g_bIsChanneling[ iClient ] = false;
	g_fChannelingTime[ iClient ] = 0.0;
	g_iHealingCount[ iClient ] = 0;
	
	if ( g_hHealingTimer[ iClient ] != INVALID_HANDLE )
	{
		KillTimer( g_hHealingTimer[ iClient ] );
		g_hHealingTimer[ iClient ] = INVALID_HANDLE;
	}
}

public Action:OnPlayerRunCmd(iClient, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	//Plugin is on && iClient is a medic
	if ( !GetConVarInt( g_beMedic ) || g_iEnts[ iClient ] == 0 )
		return Plugin_Continue;
	
	if ( (buttons & IN_USE) && !(g_iLastUseState[ iClient ] & IN_USE) )
	{
		//START HEALING TIMER
		g_bIsChanneling[ iClient ] = true;
		g_fChannelingTime[ iClient ] = 0.0;
	}
	else if ( !( buttons & IN_USE ) && ( g_iLastUseState[ iClient ] & IN_USE ) )
	{
		//STOP HEALING TIMER
		g_iTarget[ iClient ] = 0;
			
		g_bIsChanneling[ iClient ] = false;
		g_fChannelingTime[ iClient ] = 0.0;
		
		SetEntDataFloat( iClient, g_flProgressBarStartTime, 0.0, true );
		SetEntData( iClient, g_iProgressBarDuration, 0, 4, true );
	}
	
	g_iLastUseState[ iClient ] = buttons & IN_USE;
	
	return Plugin_Continue;
}

//=====Callbacks (First are hooked events, then rest)

//ROUNDSTART + FREEZEEND : Assure possible buy
public Action:Event_OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	//If plugin is enabled
	if ( GetConVarInt( g_beMedic ) )
		g_fTimeLimit = -1.0;
	
	if ( GetTeamScore( 2 ) + GetTeamScore( 3 ) == 0 ) //If first round; kill all sprites
		killAllSprites();
	
	if ( GetConVarInt( g_beMedic ) )
	{
		new announce = GetConVarInt( g_beMedic_announce );
		
		if ( GetConVarBool( g_beMedic_random ) )
		{
			//Give random people medic and announce those people accordingly
			giveMedicTrainingToRandomPeopleAndAnnounce();
		}
		else
		{
			if ( announce && ( GetTeamScore( 2 ) + GetTeamScore( 3 ) ) % announce == 0)
				PrintToChatAll( "\x04[SM] \x01%t", "Startround announce", "\x04", "\x01", "\x04", "\x01", "\x04", "\x01" );
		}
	}
	
	return Plugin_Continue;
}
public Action:Event_OnFreezeEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	//If plugin is enabled
	if ( GetConVarInt( g_beMedic ) )
		g_fTimeLimit = GetEngineTime() + ( g_fBuytime * 60 );
	
	return Plugin_Continue;
}

public Action:Event_OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	//If plugin is enabled
	if ( GetConVarInt( g_beMedic ) && GetConVarInt( g_beMedic_random ) ) //if random, then we have to remove them
	{
		if ( g_iMedicNumber_T + g_iMedicNumber_CT > 0 )
			killAllSprites();
	}
	
	return Plugin_Continue;
}

public Action:Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	//If plugin is enabled
	if ( !GetConVarInt( g_beMedic ) )
		return Plugin_Continue;
		
	new iClient = GetClientOfUserId( GetEventInt( event, "userid" ) );
		
	KillSprite( iClient );
	countMedics();
	
	//Clean timer; if overtime delay is really long
	if ( iClient > 0 &&
			IsClientInGame( iClient ) &&
			g_hHealingTimer[ iClient ] != INVALID_HANDLE )
	{
		KillTimer( g_hHealingTimer[ iClient ] );
		g_hHealingTimer[ iClient ] = INVALID_HANDLE;
	}
	
	return Plugin_Continue;
}

public Action:Event_OnPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	//If plugin is enabled + heal is interruptable
	if ( !GetConVarInt( g_beMedic ) || !GetConVarBool( g_beMedic_overtimeheal_intrpt ) )
		return Plugin_Continue;
	
	new iClient = GetClientOfUserId( GetEventInt( event, "userid") );
	if ( iClient > 0 &&
			IsClientInGame( iClient ) &&
			IsPlayerAlive( iClient ) &&
			g_hHealingTimer[ iClient ] != INVALID_HANDLE )
	{
		KillTimer( g_hHealingTimer[ iClient ] );
		g_hHealingTimer[ iClient ] = INVALID_HANDLE;
	}
	
	return Plugin_Continue;
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( !GetConVarInt( g_beMedic ) )
		return bool:Plugin_Continue;
	
	new iClient = GetClientOfUserId( GetEventInt( event, "userid" ) );
	
	if ( g_iEnts[ iClient ] != 0 )
		setMedicModelIfEnabled ( iClient );
	
	return bool:Plugin_Continue;
}

public Action:BeMedic(iClient, args)
{
	//If plugin is enabled
	if ( !GetConVarInt( g_beMedic ) )
		return Plugin_Continue;
		
	//If access from server console
	if ( iClient == 0 )
	{
		ReplyToCommand( iClient, "[SM] %t", "Command is in-game only" );
		return Plugin_Handled;
	}
	
	if ( GetConVarBool( g_beMedic_random ) )
	{
		PrintToChat( iClient, "\x04[SM] \x01%t", "Random : BuyMedicDisabled" );
		return Plugin_Handled;
	}
	
	new iTeam = GetClientTeam( iClient );
	
	//Someone noteam/spec ask to be medic
	if ( !iClient || //Console
			( iTeam != 2 && iTeam != 3 ) || //Noteam/spec
			!IsPlayerAlive( iClient )) //Pas en vie
	{
		//ERROR : Not alive/connected
		PrintToChat( iClient, "\x04[SM] \x01%t", "Buy medic : be alive" );
		return Plugin_Handled;
	}
	
	if ( g_iEnts[iClient] != 0 )
	{
		//ERROR : Already medic
		PrintToChat( iClient, "\x04[SM] \x01%t", "Buy medic : already medic" );
		return Plugin_Handled;
	}
	
	//Team restriction
	if ( iTeam - 1 == GetConVarInt( g_beMedic_team ) )
	{
		//ERROR : Team is restricted
		PrintToChat( iClient, "\x04[SM] \x01%t", "Buy medic : team restrict" );
		return Plugin_Handled;
	}
	
	//BuyZone
	if ( !GetEntData( iClient, g_iBuyZone, 1 ) && GetConVarBool( g_beMedic_buyzone ) )
	{
		//ERROR : Not in buyzone
		PrintToChat( iClient, "\x04[SM] \x01%t", "Buy medic : be in buyzone");
		return Plugin_Handled;
	}
	
	//BuyTime
	if ( GetEngineTime() > g_fTimeLimit && g_fTimeLimit != -1.0 && GetConVarBool( g_beMedic_buytime ) )
	{
		//ERROR : Buytime elapsed
		PrintToChat( iClient, "\x04[SM] \x01%t", "Buy medic : buytime elapsed" );
		return Plugin_Handled;
	}
	
	new maxMedicNb = GetConVarInt( g_beMedic );
	if ( ( GetClientTeam( iClient ) == 2 && g_iMedicNumber_T == maxMedicNb ) ||
			( GetClientTeam( iClient ) == 3 && g_iMedicNumber_CT == maxMedicNb ) )
	{
		//ERROR : Too many medics
		PrintToChat( iClient, "\x04[SM] \x01%t", "Buy medic : too many medics", "\x04", maxMedicNb, "\x01" );
		return Plugin_Handled;
	}
	
	new money = GetEntData( iClient, g_iAccount );
	new cost = GetConVarInt( g_beMedic_buycost );
	if ( money < cost )
	{
		//ERROR : $$$
		PrintToChat( iClient, "\x04[SM] \x01%t", "Buy medic : insufficient funds", "\x04", cost, "\x01" );
		return Plugin_Handled;
	}
	
	//Now we know player can buy : Set him medic
	//Sprite
	if ( GetConVarBool( g_beMedic_icon ) )
	{
		decl String:szBuffer[ 128 ];
		FormatEx( szBuffer, sizeof( szBuffer ), "%s.vmt", szSpriteFiles[ 0 ] );
		CreateSprite( iClient, szBuffer, 25.0 );
	}
	else
	{
		g_iEnts[ iClient ] = MEDIC_WITHOUT_ICON;
	}
	
	//Model
	setMedicModelIfEnabled ( iClient );
	
	//Add medic to the count
	if ( GetClientTeam( iClient ) == 2 )
		++g_iMedicNumber_T;//TEAM
	else
		++g_iMedicNumber_CT;
	
	SetEntData( iClient, g_iAccount, money - cost );
	
	PrintToChat( iClient, "\x04[SM] \x01%t", "Buy medic : ready" );
	tellTeammatesMedic( iClient );
	
	return Plugin_Handled;
}

public Action:CallMedic(iClient, args)
{
	if ( !GetConVarInt( g_beMedic ) )
		return Plugin_Continue;
	
	//If access from server console
	if ( iClient == 0 )
	{
		ReplyToCommand( iClient, "[SM] %t", "Command is in-game only" );
		return Plugin_Handled;
	}
	
	new clientTeam = GetClientTeam( iClient );
	if ( clientTeam - 1 == GetConVarInt( g_beMedic_team ) )
		return Plugin_Handled;
	
	//Someone noteam/spec ask for a medic
	if ( !iClient || //Console
			( clientTeam != 2 && clientTeam != 3 ) || //Noteam/spec
			!IsPlayerAlive( iClient )) //Pas en vie
	{
		//ERROR : Pas vivant
		PrintToChat( iClient, "\x04[SM] \x01%t", "Call medic : be alive" );
		return Plugin_Handled;
	}
	
	if ( g_fRadioCooldown[ iClient ] > 0.0 )
	{
		PrintToChat( iClient, "\x04[SM] \x01%t", "Call medic : don't spam" );
		return Plugin_Handled;
	}
	
	if ( GetConVarBool( g_beMedic_callMedic_radio ) )
	{
		//Radio msg
		decl String:szBuffer[ 64 ];
		FormatEx( szBuffer, 64, "%T", "Call medic : radio message", LANG_SERVER ); //No [SM] prefixe
		sendRadioTextToTeam( iClient, clientTeam, szBuffer );
		
		//Radio "!"
		TE_Start( "RadioIcon" );
		TE_WriteNum( "m_iAttachToClient", iClient );
		TE_SendToAll();
	}
	
	new conVarSound = GetConVarInt ( g_beMedic_callMedic_sound );
	
	//Sound
	if ( conVarSound == 1 )
	{
		for ( new i = 1; i <= MaxClients; ++i)
			if ( IsClientInGame( i ) && GetClientTeam( i ) == clientTeam )
				EmitSoundToClient( i, SOUND_FILE, SOUND_FROM_PLAYER, SNDCHAN_VOICE, 
					SNDLEVEL_NORMAL, SND_NOFLAGS, GetConVarFloat( g_beMedic_callMedic_volume ) );
	}
	else if ( conVarSound == 2 )
	{
		decl Float:fOrigin[ 3 ];
		GetClientAbsOrigin( iClient, fOrigin );
		
		EmitAmbientSound( SOUND_FILE, fOrigin, iClient, SNDLEVEL_NORMAL, 
			SND_NOFLAGS, GetConVarFloat( g_beMedic_callMedic_volume ) );
	}
	
	g_fRadioCooldown[ iClient ] = GetConVarFloat( g_beMedic_callMedic_cooldown );
	
	return Plugin_Handled;
}

//=====ConVar hooks

//Clean array
public ConVarChange_beMedic(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if ( !StringToInt( newValue ) )
		if ( g_iMedicNumber_T + g_iMedicNumber_CT > 0 )
			killAllSprites();
}

public ConVarChange_BuyTime(Handle:conVar, const String:oldvalue[], const String:newvalue[])
{
	g_fBuytime = StringToFloat( newvalue );
	g_fTimeLimit = GetEngineTime() + ( g_fBuytime * 60 );
}

public ConVarChange_HealRange(Handle:conVar, const String:oldvalue[], const String:newvalue[])
{
	//Optimizations (avoid root square computing for healing range)
	g_fSquareRange = StringToFloat( newvalue );
	g_fSquareRange *= g_fSquareRange;
}

//=====Timer=====
public Action:OverTimeHeal(Handle:Timer, any:iClient) //iClient = healedClient
{
	//If client is ok & can be healed
	if ( IsClientInGame( iClient ) && IsPlayerAlive( iClient ) && 
			GetClientHealth( iClient ) < GetConVarInt( g_beMedic_maxHealth ) &&
			g_iHealingCount[ iClient ] < GetConVarInt( g_beMedic_overtimeheal_number )) //CONVAR
	{
		++g_iHealingCount[ iClient ];
		healTargetOfAmount( iClient, GetConVarInt( g_beMedic_overtimeheal_amount ) );
	}
	else
	{
		//Killtimer
		KillTimer( g_hHealingTimer[ iClient ] );
		g_hHealingTimer[ iClient ] = INVALID_HANDLE;
		g_iHealingCount[ iClient ] = 0;
	}
}

//=====Privates=====

//Medic related

countMedics()
{
	new tMedics;
	new ctMedics;
	
	for ( new i = 1; i <= MaxClients; ++i )
		if ( g_iEnts[ i ] != 0 )
			if ( IsClientConnected( i ) )
				if ( GetClientTeam( i ) == 2 )
					++tMedics;
				else if ( GetClientTeam( i ) == 3 )
					++ctMedics;
	
	g_iMedicNumber_T = tMedics;
	g_iMedicNumber_CT = ctMedics;
}

tellTeammatesMedic(any:idClient)
{
	new team = GetClientTeam( idClient );
	
	decl String:szBuffer[ 256 ];
	Format( szBuffer, sizeof( szBuffer), "\x04[SM] \x01%T", "Buy medic : teammate is", LANG_SERVER, "\x04", idClient, "\x01",
								"\x04", "\x01", "\x04", "\x01");
	
	for ( new i = 1; i <= MaxClients; ++i )
		if ( IsClientInGame( i ) )
			if ( GetClientTeam( i ) == team && i != idClient)
				PrintToChat( i, szBuffer);
}

//For giving random medic training; a subPrivate will take care of verbose
giveMedicTrainingToRandomPeopleAndAnnounce()
{
	//1st : get players
	new numberT;
	new numberCT;
	
	decl playersT[ MaxClients ];
	decl playersCT[ MaxClients ];
	
	getTandCTCountExcludingBots( playersT, numberT, playersCT, numberCT );
	
	//2nd : give medic training (verbose if given)
	if ( GetConVarInt( g_beMedic_team ) != 1 )
	{
		giveMedicTrainingToRandomPlayers( playersT, numberT );
	}
	if ( GetConVarInt( g_beMedic_team ) != 2 )
	{
		giveMedicTrainingToRandomPlayers( playersCT, numberCT );
	}
}
getTandCTCountExcludingBots(tPlayers[], &any:nbT, ctPlayers[], &any:nbCT)
{
	for ( new i = 1; i <= MaxClients; ++i )
	{
		if ( IsClientInGame( i ) == true && IsFakeClient( i ) == false )
		{
			switch( GetClientTeam( i ) )
			{
				case 2:
				{
					tPlayers[ nbT++ ] = i;
				}
				case 3:
				{
					ctPlayers[ nbCT++ ] = i;
				}
			}
		}
	}
}
giveMedicTrainingToRandomPlayers(players[], &any:size) // no need to be const as we change size
{
	if ( size == 0 )
		return;
	
	new numberOfTrainingToGive = GetConVarInt( g_beMedic );
	
	//more to give than we have; easy way
	if ( numberOfTrainingToGive >= size )
	{
		makeThosePlayersMedicAndVerbose( players, size );
	}
	else
	{
		decl playersGoingMedic[ MaxClients ];
		new numberGoingMedic;
		
		decl randomIndex;
		
		for ( new i; i < numberOfTrainingToGive; ++i )
		{
			randomIndex = GetRandomInt( 0, size - 1 );
			playersGoingMedic[ numberGoingMedic++ ] = players[ randomIndex ];
			removeIndexFromArray( players, size, randomIndex );
		}
		
		makeThosePlayersMedicAndVerbose( playersGoingMedic, numberGoingMedic );
		
		//verbose the other non-medic (players array)
		if ( GetConVarInt( g_beMedic_announce ) )
		{
			verboseRemainingPlayers( players, size, numberGoingMedic );
		}
	}
}
makeThosePlayersMedicAndVerbose(players[], &any:size)
{
	//Make the string for verbose now
	decl String:szBufferVerbose[ 128 ];
	FormatEx( szBufferVerbose, sizeof(szBufferVerbose), "\x04[SM] \x01%t", "Random : Chosen" );
	if ( GetConVarInt( g_beMedic ) > 1 )
	{
		Format( szBufferVerbose, sizeof(szBufferVerbose), "%s, %T.", szBufferVerbose, "Random : Chosen_p2", LANG_SERVER, "\x04", size - 1, "\x01" );
	}
	else
	{
		new bufferSize = strlen( szBufferVerbose );
		if ( bufferSize >= 128 )
		{
			LogMessage( "Translations too long for 'Random : Chosen'" );
		}
		//Format for lazy people :D
		szBufferVerbose[ bufferSize ] = '.';
		szBufferVerbose[ bufferSize + 1 ] = '\0';
	}
	
	//Make the string for icon
	new bool:thereAreIcons = GetConVarBool( g_beMedic_icon );
	decl String:szBufferIcons[ 128 ];	
	if ( thereAreIcons )
	{
		FormatEx( szBufferIcons, sizeof( szBufferIcons ), "%s.vmt", szSpriteFiles[ 0 ] );
	}
	
	//Give medic training
	for ( new i; i < size; ++i )
	{
		//Sprite
		if ( thereAreIcons )
		{
			CreateSprite( players[ i ], szBufferIcons, 25.0 );
		}
		else
		{
			g_iEnts[ players[ i ] ] = MEDIC_WITHOUT_ICON;
		}
		
		//Model
		setMedicModelIfEnabled ( players[ i ] );
		
		//Add medic to the count
		if ( GetClientTeam( players[ i ] ) == 2 )
			++g_iMedicNumber_T;//TEAM
		else
			++g_iMedicNumber_CT;//take for granted team = 2+
		
		PrintToChat( players[ i ], szBufferVerbose );
	}
}
removeIndexFromArray( array[], &any:size, indexToRemove )
{
	for ( new i = indexToRemove; i < size - 1; ++i )
	{
		array[ i ] = array[ i + 1 ];
	}
	--size;
}
verboseRemainingPlayers( players[], any:numberPlayers, any:amountOfPlayerBeingBeMedic )
{
	for ( new i; i < numberPlayers; ++i )
	{
		PrintToChat( players[ i ], "\x04[SM] \x01%t", "Random : Startround", "\x04", amountOfPlayerBeingBeMedic, "\x01" );
	}
}

killAllSprites()
{
	for ( new i = MaxClients; i >= 1; --i )
		KillSprite( i );
		
	g_iMedicNumber_T = 0;
	g_iMedicNumber_CT = 0;
}

//Heal related

healTargetOfAmount(any:idTarget, any:healAmount)
{
	new maxHealth = GetConVarInt( g_beMedic_maxHealth );
	new supposedNewHealth = GetClientHealth( idTarget ) + healAmount;
	
	//Don't push over the health limit
	if (supposedNewHealth > maxHealth )
	{
		SetEntityHealth( idTarget, maxHealth );
	}
	else
	{
		SetEntityHealth( idTarget, supposedNewHealth );
	}
	//Over head animation
	if ( GetConVarBool ( g_beMedic_overtimeheal_animtn ) )
		createHealedSprite( idTarget );
}

channelingHeal(any:iClient)
{
	new idTarget = GetClientAimTarget( iClient );
	
	if (idTarget <= 0 || 
			!IsPlayerAlive( iClient ) || !IsPlayerAlive( idTarget ) || 
			( GetClientTeam( iClient ) != GetClientTeam( idTarget ) &&
			GetConVarInt( g_beMedic_target ) == 1 ) ) //Disregard foe-healing
	{
		g_iTarget[ iClient ] = 0;
		g_bIsChanneling[ iClient ] = false;
		return;
	}
	
	//Weapon check
	decl String:wpn[ MAX_NAME_LENGTH ];
	GetClientWeapon( iClient, wpn, MAX_NAME_LENGTH );
	
	if ( !StrEqual( wpn, "weapon_knife" ) )
	{
		g_bIsChanneling[ iClient ] = false;
		SetEntDataFloat( iClient, g_flProgressBarStartTime, 0.0, true );
		SetEntData( iClient, g_iProgressBarDuration, 0, 4, true );
		return; //No msg if not holding a knife
	}
	
	//Distance check
	decl Float:clientPos[3];
	GetClientAbsOrigin( iClient, clientPos );
	
	decl Float:targetPos[3];
	GetClientAbsOrigin( idTarget, targetPos );
	
	if ( Float:GetVectorDistance( clientPos, targetPos, true ) > g_fSquareRange )
	{
		g_bIsChanneling[ iClient ] = false;
		SetEntDataFloat( iClient, g_flProgressBarStartTime, 0.0, true );
		SetEntData( iClient, g_iProgressBarDuration, 0, 4, true );
		
		PrintToChat( iClient, "\x04[SM] \x01%t", "Heal : target out of range" );
		return;
	}
	
	if ( GetClientHealth( idTarget ) >= GetConVarInt( g_beMedic_maxHealth ) )
	{
		g_bIsChanneling[ iClient ] = false;
		PrintToChat( iClient, "\x04[SM] \x01%t", "Heal : target full health" );
		return;
	}
	
	new channelTime = GetConVarInt( g_beMedic_time );
	
	//Target check
	if ( idTarget == g_iTarget[ iClient ] )
	{
		g_fChannelingTime[ iClient ] += g_fFrameTime;
	}
	else
	{
		g_fChannelingTime[ iClient ] = 0.0;
		g_iTarget[ iClient ] = idTarget;
		SetEntDataFloat( iClient, g_flProgressBarStartTime, GetGameTime(), true );
		SetEntData( iClient, g_iProgressBarDuration, channelTime, 4, true );
	}
	
	//Start timer check
	if ( g_hHealingTimer[ idTarget ] != INVALID_HANDLE ) //if unit is already healed
	{
		g_bIsChanneling[ iClient ] = false;
		SetEntDataFloat( iClient, g_flProgressBarStartTime, 0.0, true );
		SetEntData( iClient, g_iProgressBarDuration, 0, 4, true );
		
		if ( GetClientTeam( iClient ) == GetClientTeam( idTarget ) )
			PrintToChat( iClient, "\x04[SM] \x01%t", "Heal : already healing" );
	}
	else if ( RoundToFloor( g_fChannelingTime[ iClient ] ) >= channelTime ) //elapsed time is ok
	{
		g_bIsChanneling[ iClient ] = false;
		SetEntDataFloat( iClient, g_flProgressBarStartTime, 0.0, true );
		SetEntData( iClient, g_iProgressBarDuration, 0, 4, true );
		
		//Start heal
		healTargetOfAmount( idTarget, GetConVarInt( g_beMedic_heal ));
		g_iHealingCount[ iClient ] = 0;
		
		new Float:ot_delay = GetConVarFloat( g_beMedic_overtimeheal_delay );
		if ( GetConVarInt( g_beMedic_overtimeheal_number ) != 0 && ot_delay != 0.0)
			g_hHealingTimer[ idTarget ] = CreateTimer( ot_delay, 
				OverTimeHeal, idTarget, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE );
		
		PrintToChat( idTarget, "\x04[SM] \x01%t", "Heal : recovering", "\x04", iClient, "\x01" );
	}
}
//Create 3 little tempents so we have a cool heal-effect sprite
createHealedSprite( any:idTarget )
{
	decl Float:targetPos[ 3 ];
	GetClientEyePosition( idTarget, targetPos );
	
	targetPos[ 2 ] += 20.0;
	
	TE_SetupGlowSprite( targetPos, g_iHealModel, 1.0, 0.2, 1 );
	TE_SendToAll( 0.0 );
	
	targetPos[ 0 ] += 10.0;
	targetPos[ 2 ] += 10.0;
	
	TE_SetupGlowSprite( targetPos, g_iHealModel, 1.0, 0.15, 1 );
	TE_SendToAll( 0.7 );
	
	targetPos[ 1 ] += 10.0;
	targetPos[ 2 ] += 5.0;
	
	TE_SetupGlowSprite( targetPos, g_iHealModel, 1.0, 0.10, 1 );
	TE_SendToAll( 1.4 );
}

setMedicModelIfEnabled( any:idTarget )
{
	if ( !GetConVarInt( g_beMedic_model ) )
		return;
	
	new bool:shouldReturn = false;
	
	if ( !IsModelPrecached( g_szCTModel ) )
	{
		LogMessage( "CT medic model wasn't precache" );
		shouldReturn = true;
	}
	
	if ( !IsModelPrecached( g_szTModel ) )
	{
		LogMessage( "Terrorist medic model wasn't precache" );
		shouldReturn = true;
	}
	if ( shouldReturn )
		return;
	
	new targetTeam = GetClientTeam( idTarget );
	
	if ( idTarget != 0 )
		if ( targetTeam == 3 )
		{
			SetEntityModel( idTarget, g_szCTModel );
		}
		else if ( targetTeam == 2 )
		{
			SetEntityModel( idTarget, g_szTModel );
		}
}

//--------------------------------------------------------------------------------------------------
//Following code mainly done by "Nut" / "toazron1" (with some optimisations & comments; like new --> decl)

stock CreateSprite(iClient, String:sprite[], Float:offset)
{
	decl String:szTemp[ 64 ]; 
	Format( szTemp, sizeof( szTemp ), "client%i", iClient );
	DispatchKeyValue( iClient, "targetname", szTemp );

	decl Float:vOrigin[ 3 ];
	GetClientAbsOrigin( iClient, vOrigin );
	vOrigin[ 2 ] += offset;
	new ent = CreateEntityByName( "env_sprite_oriented" );
	SetEntityRenderMode( ent, RENDER_TRANSCOLOR );
	
	if ( ent > 0 ) //If we can create the entity (2048 max thing I guess)
	{
		DispatchKeyValue( ent, "model", sprite );
		DispatchKeyValue( ent, "classname", "env_sprite_oriented" );
		DispatchKeyValue( ent, "spawnflags", "1" );
		DispatchKeyValue( ent, "scale", "0.1" );
		DispatchKeyValue( ent, "rendermode", "1" );
		DispatchKeyValue( ent, "rendercolor", "255 255 255" );
		DispatchKeyValue( ent, "targetname", "redcross_spr" );
		DispatchKeyValue( ent, "parentname", szTemp );
		DispatchSpawn( ent );
		
		TeleportEntity( ent, vOrigin, NULL_VECTOR, NULL_VECTOR );

		g_iEnts[ iClient ] = ent;
		
	}
	else //Can't get a sprite (too many ent)
	{
		g_iEnts[ iClient ] = MEDIC_WITHOUT_ICON;
	}
}

//Remove the sprite if there's ones
stock KillSprite(iClient)
{
	if ( g_iEnts[ iClient ] > 0 && IsValidEntity( g_iEnts[ iClient ] ) )
	{
		AcceptEntityInput( g_iEnts[ iClient ], "kill" );
	}
	g_iEnts[ iClient ] = 0;
}

//--------------------------------------------------------------------------------------------------
//Following code mainly done by "javalia" (with some code changes)

//i dunno, what the hell is this magic number mean, i DUNNO!
#define RADIOTEXT_MAGIC_NUMBER 3

stock sendRadioTextToTeam(client, team, const String:sText[], any:...)
{
	if ( !IsClientInGame( client ) )
		return;
	
	decl String:sClientName[ MAX_NAME_LENGTH ];
	decl String:sPlaceName[ 256 ];
	decl String:msg[ 256 ];
	GetClientName( client, sClientName, MAX_NAME_LENGTH );
	GetEntPropString( client, Prop_Data, "m_szLastPlaceName", sPlaceName, 256 );
	
	for (new i = 1; i <= MaxClients; i++){
		
		if ( IsClientInGame( i ) && GetClientTeam( i ) == team)
		{
			SetGlobalTransTarget( i );
			VFormat( msg, 256, sText, 3 );    
			
			new Handle:buffer = StartMessageOne( "RadioText", i );
			
			if (buffer != INVALID_HANDLE)
			{
				BfWriteByte(buffer, RADIOTEXT_MAGIC_NUMBER);
				BfWriteByte(buffer, client);
				if ( StrEqual( sPlaceName, "", false ) )
					BfWriteString(buffer, "#Game_radio");
				else
					BfWriteString(buffer, "#Game_radio_location");
				
				BfWriteString(buffer, sClientName);
				
				if ( !StrEqual( sPlaceName, "", false ) )
					BfWriteString(buffer, sPlaceName);
				
				BfWriteString(buffer, msg);
				EndMessage(); 
			}
		}
	}
}