/*

Reverse Friendly-Fire (l4d_reverse_ff) by Mystik Spiral

Left4Dead(2) SourceMod plugin that reverses friendly-fire.  
The attacker takes all of the damage and the victim takes none.  
This forces players to be more precise with their shots or they will spend a lot of time on the ground.

Although this plugin discourages griefers/team killers since they can only damage themselves and no one else...

- The first objective is to force players to improve their shooting tactics and aim.  
- The second objective is to encourage inexperienced players not to join Expert games.

This plugin reverses damage from the grenade launcher, but does not otherwise reverse explosion damage.  
It does not reverse burn/explosion damage (I have a separate plugin for that, see Suggestion section below).  
Reverses friendly-fire for survivors and team attacks for infected.  
Supports language translations using "l4d_reverse_ff.phrases.txt" file.

Please note the following for the true/false options below:  
Regardless of the setting, the victim never takes damage from the attacker.  
True means friendly-fire is reversed for that option and the attacker takes the damage they caused.  
False means friendy-fire is disabled for that option and the attacker does not take any damage.

- Option to ReverseFF when attacker is an admin. [reverseff_admin (default: 0/false)]  
- Option to ReverseFF when victim is a bot. [reverseff_bot (default: 0/false)]  
- Option to ReverseFF when victim is incapacitated. [reverseff_incapped (default: 0/false)]  
- Option to ReverseFF when attacker is incapacitated.  [reverseff_attackerincapped (default: 0/false)]  
- Option to ReverseFF when damage from mounted gun.  [reverseff_mountedgun (default: 1/true)]  
- Option to ReverseFF when damage from melee weapon.  [reverseff_melee (default: 1/true)]  
- Option to ReverseFF when damage from chainsaw.  [reverseff_chainsaw (default: 1/true)]  
- Option to ReverseFF during Smoker pull or Charger carry. [reverseff_pullcarry (default: 0/false)]  
- Option to specify extra damage if attacker used explosive/incendiary ammo. [reverseff_multiplier (default: 1.125 = 12.5%)]  
- Option to specify percentage of damage reversed. [reverseff_dmgmodifier (default: 1.0 = damage amount unmodified)]  
- Option to specify maximum survivor damage allowed per chapter before kick/ban (0=disable). [reverseff_survivormaxdmg (default: 200)]  
- Option to specify maximum infected damage allowed per chapter before kick/ban (0=disable). [reverseff_infectedmaxdmg (default: 50)]  
- Option to specify maximum tank damage allowed per chapter before kick/ban (0=disable).  [reverseff_tankmaxdmg (default: 300)]  
- Option to specify kick/ban duration in minutes. (0=permanent ban, -1=kick instead of ban). [reverseff_banduration (default: 10)]  
- Option to enable/disable plugin by game mode. [reverseff_modes_on, reverseff_modes_off, reverseff_modes_tog]


Suggestion:

To minimize griefer impact, use this plugin along with...

ReverseBurn and ExplosionAnnouncer (l4d_ReverseBurn_and_ExplosionAnnouncer)  
ReverseBurn and ThrowableAnnouncer (l4d_ReverseBurn_and_ThrowableAnnouncer)  
Command Block (l4d_command_block)  
Spray Block (l4d_spray_block)  
  
When these plugins are combined, griefers cannot inflict friendly-fire or explosion damage, burn damage for victims is minimal, a variety of exploits are blocked, and all player sprays are blocked.  
Although griefers will take significant damage, other players may not notice any difference in game play (other than laughing at stupid griefer fails).


Credits:  
Chainsaw damage bug fixed by pan0s

Want to contribute code enhancements?  
Create a pull request using this GitHub repository: https://github.com/Mystik-Spiral/l4d_reverse_ff

Plugin discussion: https://forums.alliedmods.net/showthread.php?t=329035

*/
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
////////////////////////////////////////////////////////////////
// #include <pan0s>
// pan0s.inc (Excerpt)
// Team define
#define TEAM_SPECTATOR       1
#define TEAM_SURVIVOR        2
#define TEAM_INFECTED        3
enum struct GameSetting
{
	char difficulty[24];
	void RefreshDifficulty()
	{
		ConVar cvar = FindConVar("z_difficulty");
		cvar.GetString(this.difficulty, 24);
	}
}

enum
{
	SERVER_INDEX	= 0,
	NO_INDEX		= -1,
	NO_PLAYER		= -2,
	BLUE_INDEX		= 2,
	RED_INDEX		= 3,
}

stock const char CTag[][] 				= { "{DEFAULT}", "{ORANGE}", "{CYAN}", "{RED}", "{BLUE}", "{GREEN}" };
stock const char CTagCode[][] 			= { "\x01", "\x04", "\x03", "\x03", "\x03", "\x05" };
stock const bool CTagReqSayText2[] 	= { false, false, true, true, true, false };
stock const int CProfile_TeamIndex[] 	= { NO_INDEX, NO_INDEX, SERVER_INDEX, RED_INDEX, BLUE_INDEX, NO_INDEX };

/**
 * @note Prints a message to a specific client in the chat area.
 * @note Supports color tags.
 *
 * @param client 		Client index.
 * @param sMessage 		Message (formatting rules).
 * @return 				No return
 * 
 * On error/Errors:   If the client is not connected an error will be thrown.
 */
stock void CPrintToChat( int client, const char[] sMessage, any ... )
{
	if ( client <= 0 || client > MaxClients )
		ThrowError( "Invalid client index %d", client );
	
	if ( !IsClientInGame( client ) )
		ThrowError( "Client %d is not in game", client );
	
	static char sBuffer[250];
	static char sCMessage[250];
	SetGlobalTransTarget(client);
	Format( sBuffer, sizeof( sBuffer ), "\x01%s", sMessage );
	VFormat( sCMessage, sizeof( sCMessage ), sBuffer, 3 );
	
	int index = CFormat( sCMessage, sizeof( sCMessage ) );
	if( index == NO_INDEX )
		PrintToChat( client, sCMessage );
	else
		CSayText2( client, index, sCMessage );
}

/**
 * @note Prints a message to all clients in the chat area.
 * @note Supports color tags.
 *
 * @param client		Client index.
 * @param sMessage 		Message (formatting rules)
 * @return 				No return
 */
stock void CPrintToChatAll( const char[] sMessage, any ... )
{
	static char sBuffer[250];
	
	for ( int i = 1; i <= MaxClients; i++ )
	{
		if ( IsClientInGame( i ) && !IsFakeClient( i ) )
		{
			SetGlobalTransTarget( i );
			VFormat( sBuffer, sizeof( sBuffer ), sMessage, 2 );
			CPrintToChat( i, sBuffer );
		}
	}
}

/**
 * @note Replaces color tags in a string with color codes
 *
 * @param sMessage    String.
 * @param maxlength   Maximum length of the string buffer.
 * @return			  Client index that can be used for SayText2 author index
 * 
 * On error/Errors:   If there is more then one team color is used an error will be thrown.
 */
stock int CFormat( char[] sMessage, int maxlength )
{	
	int iRandomPlayer = NO_INDEX;
	
	for ( int i = 0; i < sizeof(CTagCode); i++ )													//	Para otras etiquetas de color se requiere un bucle.
	{
		if ( StrContains( sMessage, CTag[i]) == -1 ) 										//	Si no se encuentra la etiqueta, omitir.
			continue;
		else if ( !CTagReqSayText2[i] )
			ReplaceString( sMessage, maxlength, CTag[i], CTagCode[i] ); 					//	Si la etiqueta no necesita Saytext2 simplemente reemplazará.
		else																				//	La etiqueta necesita Saytext2.
		{	
			if ( iRandomPlayer == NO_INDEX )												//	Si no se especificó un cliente aleatorio para la etiqueta, reemplaca la etiqueta y busca un cliente para la etiqueta.
			{
				iRandomPlayer = CFindRandomPlayerByTeam( CProfile_TeamIndex[i] ); 			//	Busca un cliente válido para la etiqueta, equipo de infectados oh supervivientes.
				if ( iRandomPlayer == NO_PLAYER ) 
					ReplaceString( sMessage, maxlength, CTag[i], CTagCode[5] ); 			//	Si no se encuentra un cliente valido, reemplasa la etiqueta con una etiqueta de color verde.
				else 
					ReplaceString( sMessage, maxlength, CTag[i], CTagCode[i] ); 			// 	Si el cliente fue encontrado simplemente reemplasa.
			}
			else 																			//	Si en caso de usar dos colores de equipo infectado y equipo de superviviente juntos se mandará un mensaje de error.
				ThrowError("Using two team colors in one message is not allowed"); 			//	Si se ha usadó una combinación de colores no validad se registrara en la carpeta logs.
		}
	}
	
	return iRandomPlayer;
}

/**
 * @note Founds a random player with specified team
 *
 * @param color_team  Client team.
 * @return			  Client index or NO_PLAYER if no player found
 */
stock int CFindRandomPlayerByTeam( int color_team )
{
	if ( color_team == SERVER_INDEX )
		return 0;
	else
		for ( int i = 1; i <= MaxClients; i ++ )
			if ( IsClientInGame( i ) && GetClientTeam( i ) == color_team )
				return i;

	return NO_PLAYER;
}

/**
 * @note Sends a SayText2 usermessage to a client
 *
 * @param sMessage 		Client index
 * @param maxlength 	Author index
 * @param sMessage 		Message
 * @return 				No return.
 */
stock void CSayText2( int client, int author, const char[] sMessage )
{
	Handle hBuffer = StartMessageOne( "SayText2", client );
	BfWriteByte( hBuffer, author );
	BfWriteByte( hBuffer, true );
	BfWriteString( hBuffer, sMessage );
	EndMessage();
}
/**
 * Validates if the client index is valid.
 *
 * @param client        Client index.
 * @return              True if client index is valid, false otherwise.
 */
stock bool IsValidClientIndex(int client)
{
    return (1 <= client <= MaxClients);
}

/****************************************************************************************************/

/**
 * Validates if the client is valid.
 *
 * @param client        Client index.
 * @return              True if client index is valid and client is in game, false otherwise.
 */
stock bool IsValidClient(int client)
{
    return IsValidClientIndex(client) && IsValidEntity(client) && IsClientConnected(client) && IsClientInGame(client);
}
/**
 * Validates if the client is a infected.
 *
 * @param client        Client index.
 * @return              True if client is valid and the team is infected.
 */
stock bool IsInfected(int client)
{
	return IsValidClient(client) && GetClientTeam(client) == TEAM_INFECTED;
}

stock int GetEventClient(Event event, const char[] id)
{
	return GetClientOfUserId(event.GetInt(id));
}
////////////////////////////////////////////////////////////////

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "2.7"
#define CVAR_FLAGS FCVAR_NOTIFY
#define TRANSLATION_FILENAME "l4d2_reverse_ff.phrases"

ConVar cvar_reverseff_admin;
ConVar cvar_reverseff_multiplier;
ConVar cvar_reverseff_dmgmodifier;
ConVar cvar_reverseff_bot;
ConVar cvar_reverseff_survivormaxdmg;
ConVar cvar_reverseff_infectedmaxdmg;
ConVar cvar_reverseff_tankmaxdmg;
ConVar cvar_reverseff_banduration;
ConVar cvar_reverseff_incapped;
ConVar cvar_reverseff_attackerincapped;
ConVar cvar_reverseff_mountedgun;
ConVar cvar_reverseff_melee;
ConVar cvar_reverseff_chainsaw;
ConVar cvar_reverseff_pullcarry;

///////////////////////////////////////////////////////////
// pan0s | 2021-04-20 | Add Chances for no reversing damage.
ConVar cvar_reverseff_noOfChances;
ConVar cvar_reverseff_cooldownReset;
ConVar cvar_reverseff_zero_damage_msg_on;

// pan0s | 2021-04-20 | Add minimun damage reverse
ConVar cvar_reverseff_minReverseDmg;
///////////////////////////////////////////////////////////
ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModesOn, g_hCvarModesOff, g_hCvarModesTog;

float g_fCvarDamageMultiplier;
float g_fCvarDamageModifier;
float g_fAccumDamage[MAXPLAYERS + 1];
float g_fAccumDamageAsTank[MAXPLAYERS + 1];
float g_fAccumDamageAsInfected[MAXPLAYERS + 1];
float g_fSurvivorMaxDamage;
float g_fInfectedMaxDamage;
float g_fTankMaxDamage;
float g_fDmgFrc[3] = {0.0, 0.0, 0.0};
float g_fDmgPos[3] = {0.0, 0.0, 0.0};

int g_iBanDuration;

bool g_bCvarReverseIfAdmin;
bool g_bCvarReverseIfBot;
bool g_bCvarReverseIfIncapped;
bool g_bCvarReverseIfAttackerIncapped;
bool g_bCvarReverseIfPullCarry;
bool g_bCvarReverseIfMountedgun;
bool g_bCvarReverseIfMelee;
bool g_bCvarReverseIfChainsaw;
bool g_bGrace[MAXPLAYERS + 1];
bool g_bToggle[MAXPLAYERS + 1];
bool g_bCvarAllow, g_bMapStarted;
bool g_bL4D2;
bool g_bAllReversePlugins;
bool g_bLateLoad;

Handle g_hEndGrace[MAXPLAYERS + 1];

///////////////////////////////////////////////////////////
// pan0s | 2021-04-20 | Add Chances for no reversing damage.
float g_fCountDamage[MAXPLAYERS + 1];
float g_fCvarResetTime;

bool g_bIsHurting[MAXPLAYERS + 1];
bool g_bNotice[MAXPLAYERS + 1]; // Prevent showing twice messages in the same time.

int g_iChances[MAXPLAYERS + 1];
int g_iCvarChances;
int g_iMinReverseDmg;

Handle g_hResetChanceTimer[MAXPLAYERS + 1];
Handle g_hReduceChanceTimer[MAXPLAYERS + 1];
Handle g_hDelayTextTimer[MAXPLAYERS + 1];
Handle g_hCountDamageTimer[MAXPLAYERS + 1];
///////////////////////////////////////////////////////////


public Plugin myinfo =
{
	name = "[L4D & L4D2] Reverse Friendly-Fire",
	author = "Mystic Spiral, chainsaw damange bug fixed by pan0s",
	description = "Reverses friendly-fire... attacker takes damage, victim does not.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=329035"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test == Engine_Left4Dead2)
	{
		g_bL4D2 = true;
		g_bLateLoad = late;
		return APLRes_Success;
	}
	if ( test == Engine_Left4Dead )
	{
		g_bL4D2 = false;
		g_bLateLoad = late;
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
	return APLRes_SilentFailure;
}

public void OnAllPluginsLoaded()
{
	if (FindConVar("RBaEA_version") != null)
	{
		if (FindConVar("RBaTA_version") != null)
		{
			g_bAllReversePlugins = true;
		}
	}
}

public void OnPluginStart()
{
	LoadPluginTranslations();
	
	CreateConVar("reverseff_version", PLUGIN_VERSION, "Reverse Friendly-Fire", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvar_reverseff_admin = CreateConVar("reverseff_admin", "1", "0=Do not ReverseFF if attacker is admin, 1=ReverseFF if attacker is admin", CVAR_FLAGS);
	cvar_reverseff_bot = CreateConVar("reverseff_bot", "1", "0=Do not ReverseFF if victim is bot, 1=ReverseFF if victim is bot", CVAR_FLAGS);
	cvar_reverseff_incapped = CreateConVar("reverseff_incapped", "1", "0=Do not ReverseFF if victim is incapped, 1=ReverseFF if victim is incapped", CVAR_FLAGS);
	cvar_reverseff_attackerincapped = CreateConVar("reverseff_attackerincapped", "1", "0=Do not ReverseFF if attacker is incapped, 1=ReverseFF if attacker is incapped", CVAR_FLAGS);
	cvar_reverseff_multiplier = CreateConVar("reverseff_multiplier", "1.125", "Special ammo damage multiplier (default=12.5%)", CVAR_FLAGS);
	cvar_reverseff_dmgmodifier = CreateConVar("reverseff_dmgmodifier", "1.0", "0.0=no dmg...effectively disables friendly-fire\n0.01=1% less dmg, 0.1=10% less dmg, 0.5=50% less dmg, 1.0=dmg amt unmodified\n1.01=1% more dmg, 1.1=10% more dmg, 1.5=50% more dmg, 2.0=dmg amt doubled", CVAR_FLAGS);
	cvar_reverseff_survivormaxdmg = CreateConVar("reverseff_survivormaxdmg", "0", "Maximum damage allowed before kick/ban survivor (0=disable)", CVAR_FLAGS);
	cvar_reverseff_infectedmaxdmg = CreateConVar("reverseff_infectedmaxdmg", "50", "Maximum damage allowed before kick/ban infected (0=disable)", CVAR_FLAGS);
	cvar_reverseff_tankmaxdmg = CreateConVar("reverseff_tankmaxdmg", "300", "Maximum damage allowed before kick/ban tank (0=disable)", CVAR_FLAGS);
	cvar_reverseff_banduration = CreateConVar("reverseff_banduration", "10", "Ban duration in minutes (0=permanent ban, -1=kick instead of ban)", CVAR_FLAGS);
	cvar_reverseff_mountedgun = CreateConVar("reverseff_mountedgun", "1", "0=Do not ReverseFF from mountedgun, 1=ReverseFF from mountedgun", CVAR_FLAGS);
	cvar_reverseff_melee = CreateConVar("reverseff_melee", "1", "0=Do not ReverseFF from melee, 1=ReverseFF from melee", CVAR_FLAGS);
	cvar_reverseff_chainsaw = CreateConVar("reverseff_chainsaw", "1", "0=Do not ReverseFF from chainsaw, 1=ReverseFF from chainsaw", CVAR_FLAGS);
	cvar_reverseff_pullcarry = CreateConVar("reverseff_pullcarry", "0", "0=Do not ReverseFF during Smoker pull or Charger carry, 1=ReverseFF from pull/carry", CVAR_FLAGS);
	///////////////////////////////////////////////////////////
	// pan0s | 2021-04-20 | Add Chances for no reversing damage.
	cvar_reverseff_noOfChances = CreateConVar("reverseff_number_of_chance", "30", "The number of chances avoids reserving damage. 0=No chance", CVAR_FLAGS, true, 0.0, true, 999.0);
	cvar_reverseff_cooldownReset = CreateConVar("reverseff_reset_cooldown_time", "15.0", "The cooldown time of resetting chances. 0=Nerver", CVAR_FLAGS, true, 1.0, true, 999.0 );
	cvar_reverseff_zero_damage_msg_on = CreateConVar("reverseff_zero_damage_msg_on", "1", "Show message if reverse damage is zero? 0=OFF 1=ON", CVAR_FLAGS);
	cvar_reverseff_minReverseDmg = CreateConVar("reverseff_min_reverse_damage", "5", "Minimum reverse damage if damage >0", CVAR_FLAGS);
	///////////////////////////////////////////////////////////
	g_hCvarAllow = CreateConVar("reverseff_enabled", "1", "0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModesOn = CreateConVar("reverseff_modes_on", "", "Game mode names on, comma separated, no spaces. (Empty=all).", CVAR_FLAGS );
	g_hCvarModesOff = CreateConVar("reverseff_modes_off", "", "Game mode names off, comma separated, no spaces. (Empty=none).", CVAR_FLAGS );
	g_hCvarModesTog = CreateConVar("reverseff_modes_tog", "0", "Game type bitflags on, add #s together. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge", CVAR_FLAGS );
	AutoExecConfig(true, "l4d2_reverse_ff");
	
	cvar_reverseff_admin.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_multiplier.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_dmgmodifier.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_bot.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_survivormaxdmg.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_infectedmaxdmg.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_tankmaxdmg.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_banduration.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_incapped.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_attackerincapped.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_mountedgun.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_melee.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_chainsaw.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_pullcarry.AddChangeHook(action_ConVarChanged);
	///////////////////////////////////////////////////////////
	// pan0s | 2021-04-20 | Add Chances for no reversing damage.	
	cvar_reverseff_noOfChances.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_cooldownReset.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_minReverseDmg.AddChangeHook(action_ConVarChanged);
	///////////////////////////////////////////////////////////
	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOn.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	
	HookEvent("choke_stopped", Event_StartGrace);
	HookEvent("tongue_release", Event_StartGrace);
	HookEvent("pounce_stopped", Event_StartGrace);
	HookEvent("tongue_grab", Event_PullCarry);
	HookEvent("lunge_pounce", Event_PounceRide);
	HookEvent("weapon_fire", Event_WeaponFire);
	if (g_bL4D2)
	{
		HookEvent("jockey_ride_end", Event_StartGrace);
		HookEvent("charger_pummel_end", Event_StartGrace);
		HookEvent("charger_carry_start", Event_PullCarry);
		HookEvent("jockey_ride", Event_PounceRide);
	}
	
	if (g_bLateLoad)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client))
				OnClientPutInServer(client);
		}
	}
}

public void LoadPluginTranslations()
{
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "translations/%s.txt", TRANSLATION_FILENAME);
    if (FileExists(path))
    {
    	LoadTranslations(TRANSLATION_FILENAME);
    }
    else
    {
    	if (g_bL4D2)
    	{
    		SetFailState("Missing required translation file \"<left4dead2>\\%s\", please download.", path, TRANSLATION_FILENAME);
    	}
    	else
    	{
    		SetFailState("Missing required translation file \"<left4dead>\\%s\", please download.", path, TRANSLATION_FILENAME);
    	}
    }
        
}

public void OnMapStart()
{
	g_bMapStarted = true;
}

public void OnMapEnd()
{
	g_bMapStarted = false;
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

public void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

public int action_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bCvarReverseIfAdmin = cvar_reverseff_admin.BoolValue;
	g_fCvarDamageMultiplier = cvar_reverseff_multiplier.FloatValue;
	g_fCvarDamageModifier = cvar_reverseff_dmgmodifier.FloatValue;
	g_bCvarReverseIfBot = cvar_reverseff_bot.BoolValue;
	g_fSurvivorMaxDamage = cvar_reverseff_survivormaxdmg.FloatValue;
	g_fInfectedMaxDamage = cvar_reverseff_infectedmaxdmg.FloatValue;
	g_fTankMaxDamage = cvar_reverseff_tankmaxdmg.FloatValue;
	g_iBanDuration = cvar_reverseff_banduration.IntValue;
	g_bCvarReverseIfIncapped = cvar_reverseff_incapped.BoolValue;
	g_bCvarReverseIfAttackerIncapped = cvar_reverseff_attackerincapped.BoolValue;
	g_bCvarReverseIfMountedgun = cvar_reverseff_mountedgun.BoolValue;
	g_bCvarReverseIfMelee = cvar_reverseff_melee.BoolValue;
	g_bCvarReverseIfChainsaw = cvar_reverseff_chainsaw.BoolValue;
	g_bCvarReverseIfPullCarry = cvar_reverseff_pullcarry.BoolValue;
	///////////////////////////////////////////////////////////
	// pan0s | 2021-04-20 | Add Chances for no reversing damage.	
	g_iCvarChances = cvar_reverseff_noOfChances.IntValue;
	g_fCvarResetTime = cvar_reverseff_cooldownReset.FloatValue;
	g_iMinReverseDmg = cvar_reverseff_minReverseDmg.IntValue;
	///////////////////////////////////////////////////////////
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if ( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
	}

	else if ( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
	}
}

int g_iCurrentMode;
bool IsAllowedGameMode()
{
	if ( g_hCvarMPGameMode == null )
		return false;

	int iCvarModesTog = g_hCvarModesTog.IntValue;
	if ( iCvarModesTog != 0 && iCvarModesTog != 15 )
	{
		if ( g_bMapStarted == false )
			return false;

		g_iCurrentMode = 0;

		int entity = CreateEntityByName("info_gamemode");
		if ( IsValidEntity(entity) )
		{
			DispatchSpawn(entity);
			HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
			ActivateEntity(entity);
			AcceptEntityInput(entity, "PostSpawnActivate");
			if ( IsValidEntity(entity) ) //Because sometimes "PostSpawnActivate" seems to kill the ent.
				RemoveEdict(entity); //Because multiple plugins creating at once, avoid too many duplicate ents in the same frame
		}

		if ( g_iCurrentMode == 0 )
			return false;

		if ( !(iCvarModesTog & g_iCurrentMode) )
			return false;
	}

	char sGameModes[64], sGameMode[64];
	g_hCvarMPGameMode.GetString(sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	g_hCvarModesOn.GetString(sGameModes, sizeof(sGameModes));
	if ( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if ( StrContains(sGameModes, sGameMode, false) == -1 )
			return false;
	}

	g_hCvarModesOff.GetString(sGameModes, sizeof(sGameModes));
	if ( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if ( StrContains(sGameModes, sGameMode, false) != -1 )
			return false;
	}

	return true;
}

public void OnGamemode(const char[] output, int caller, int activator, float delay)
{
	if ( strcmp(output, "OnCoop") == 0 )
		g_iCurrentMode = 1;
	else if ( strcmp(output, "OnSurvival") == 0 )
		g_iCurrentMode = 2;
	else if ( strcmp(output, "OnVersus") == 0 )
		g_iCurrentMode = 4;
	else if ( strcmp(output, "OnScavenge") == 0 )
		g_iCurrentMode = 8;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	g_bGrace[client] = false;
	g_fAccumDamage[client] = 0.0;
	g_fAccumDamageAsTank[client] = 0.0;
	g_fAccumDamageAsInfected[client] = 0.0;
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// pan0s | 2021-04-20 | Add Chances for no reversing damage.
	InitChances(client);
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

}

public void OnClientPostAdminCheck(int client)
{
	// CreateTimer(16.0, AnnouncePlugin, client);
}

public void OnClientDisconnect(int client)
{
	g_bGrace[client] = false;
	g_fAccumDamage[client] = 0.0;
	g_fAccumDamageAsTank[client] = 0.0;
	g_fAccumDamageAsInfected[client] = 0.0;
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// pan0s | 2021-04-20 | Add Chances for no reversing damage.
	InitChances(client);
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	//debug plugin enabled flag
	//PrintToServer("g_bCvarAllow: %b", g_bCvarAllow);
	if (!g_bCvarAllow)
	{
		return Plugin_Continue;
	}
	//debug damage
	//PrintToServer("Vic: %i, Atk: %i, Inf: %i, Dam: %f, DamTyp: %i, Wpn: %i", victim, attacker, inflictor, damage, damagetype, weapon);
	
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// pan0s | 2021-05-31 | Add minimum reverse damage
	float baseDamage = damage;
	damage = damage >= 1.0 && damage < g_iMinReverseDmg * 1.0? g_iMinReverseDmg * 1.0: damage; 

	// pan0s | 2021-04-25 | Add molotov damage message
	switch(damagetype)
	{
		case DMG_BURN, DMG_PREVENT_PHYSICS_FORCE + DMG_BURN, DMG_DIRECT + DMG_BURN:
		{
			if(damage >= 1.0 && (victim != attacker && !IsInfected(victim)))
				CPrintToChat(victim, "%T%T", "SYSTEM", victim, "BURN_HURT", victim, attacker, victim, baseDamage);
		}
	}
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	//attacker and victim survivor checks
	if (IsValidClientAndInGameAndSurvivor(attacker) && IsValidClientAndInGameAndSurvivor(victim) && victim != attacker)
	{
		if (IsFakeClient(attacker))
		{
			//ignore friendly-fire from bots which is 0 damage anyway
			return Plugin_Continue;
		}
		char sInflictorClass[64];
		if (inflictor > MaxClients)
		{
			GetEdictClassname(inflictor, sInflictorClass, sizeof(sInflictorClass));
		}
		//is weapon grenade launcher
		bool bWeaponGL = IsWeaponGrenadeLauncher(sInflictorClass);
		//is weapon minigun
		bool bWeaponMG = IsWeaponMinigun(sInflictorClass);
		bool ReverseIfMountedgun = false;
		if (bWeaponMG && !g_bCvarReverseIfMountedgun)
		{
			ReverseIfMountedgun = true;
		}
		bool bWeaponMelee = IsWeaponMelee(sInflictorClass);
		bool ReverseIfMelee = false;
		if (bWeaponMelee && !g_bCvarReverseIfMelee)
		{
			ReverseIfMelee = true;
		}
		bool bWeaponChainsaw = IsWeaponChainsaw(sInflictorClass);
		bool ReverseIfChainsaw = false;
		if (bWeaponChainsaw && !g_bCvarReverseIfChainsaw)
		{
			ReverseIfChainsaw = true;
		}
		//debug weapon
		//PrintToServer("GL: %b, MG: %b, InfCls: %s, weapon: %i", bWeaponGL, bWeaponMG, sInflictorClass, weapon);
		//if weapon caused damage
		if (weapon > 0 || bWeaponGL || bWeaponMG)
		{
			//check reverse friendly-fire parameters for: attacker=admin, victim=bot, victim=incapped, attacker=incapped, damage from mountedgun, melee, or chainsaw
			//regardless of the above settings, do not reverse friendly-fire during grace period after victim freed from SI
			if (!(ReverseIfAttackerAdmin(attacker) || ReverseIfVictimBot(victim) || ReverseIfVictimIncapped(victim) || ReverseIfAttackerIncapped(attacker) || ReverseIfMountedgun || ReverseIfMelee || ReverseIfChainsaw) && (!g_bGrace[victim]))
			{
				//special ammo checks
				if (IsSpecialAmmo(weapon, attacker, inflictor, damagetype, bWeaponGL))
				{
					//damage * "reverseff_multiplier"
					damage *= g_fCvarDamageMultiplier;
				}
				
				//apply damage modifier
				damage *= g_fCvarDamageModifier;
				
				//accumulate damage total for attacker
				g_fAccumDamage[attacker] += damage;

				//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
				// pan0s | 2021-04-20 | Add Chances for no reversing damage.
				if(UseChance(attacker, damage)) return Plugin_Handled;
				//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

				//debug acculated damage
				//PrintToServer("Survivor Atk: %N, Dmg: %f, AcmDmg: %f, SurvMaxDmg: %f", attacker, damage, g_fAccumDamage[attacker], g_fSurvivorMaxDamage);
				//does accumulated damage exceed "reverseff_survivormaxdamage"
				if (g_fSurvivorMaxDamage > 0 && (g_fAccumDamage[attacker] > g_fSurvivorMaxDamage) && !IsFakeClient(attacker))
				{
					if (g_iBanDuration == -1)
					{
						//kick attacker
						KickClient(attacker, "%T", "ExcessiveFF", attacker);
					}
					else
					{
						//ban attacker for "reverseff_banduration"
						char BanMsg[50];
						Format(BanMsg, sizeof(BanMsg), "%T", "ExcessiveFF", attacker, attacker);
						BanClient(attacker, g_iBanDuration, BANFLAG_AUTO, "ExcessiveFF", BanMsg, _, attacker);
					}
					//reset accumulated damage
					g_fAccumDamage[attacker] = 0.0;
					g_fAccumDamageAsTank[attacker] = 0.0;
					g_fAccumDamageAsInfected[attacker] = 0.0;
					//do not inflict damage since player was kicked/banned
					return Plugin_Handled;
				}

				//pan0s | 20-Apr-2021 | Fixed: Server crashes if reversing chainsaw damage makes the attacker incapacitated or dead.
				//pan0s | start chainsaw fix part 1
				if (bWeaponChainsaw)
				{
					//Create a DataPack to pass to ChainsawTakeDamageTimer.
					DataPack hPack = new DataPack();
					hPack.WriteCell(attacker);
					hPack.WriteCell(inflictor);
					hPack.WriteCell(victim);
					hPack.WriteFloat(damage);
					hPack.WriteCell(damagetype);
					hPack.WriteCell(weapon);
					for (int i=0; i<3; i++)
					{
						hPack.WriteFloat(damageForce[i]);
						hPack.WriteFloat(damagePosition[i]);
					}
					//adding a timer fixes the bug, reason unknown
					CreateTimer(0.01, ChainsawTakeDamageTimer, hPack);
				}
				//pan0s | end chainsaw fix part 1
				
				else
				{
					// pan0s | Count total damage
					CountTotalDamage(attacker, victim, damage);


					//inflict (non-chainsaw) damage to attacker
					//add 1HP to victim then damage them for 1HP so the displayed message and vocalization order are correct,
					//then damage attacker as self-inflicted for actual damage so there is no vocalization, just pain grunt.
					SetEntityHealth(victim, GetClientHealth(victim) + 1);
					SDKHooks_TakeDamage(victim, inflictor, attacker, 1.0, 0, weapon, g_fDmgFrc, g_fDmgPos);
					SDKHooks_TakeDamage(attacker, inflictor, attacker, damage, damagetype, weapon, damageForce, damagePosition);

				}

				if (damage > 0 && !IsFakeClient(attacker))
				{
					if (!g_bToggle[attacker])
					{
						//PrintToServer("%N %T %N", attacker, "Attacked", LANG_SERVER, victim);
						//CPrintToChat(attacker, "{orange}[ReverseFF]{lightgreen} %T", "DmgReversed", attacker, victim);
						g_bToggle[attacker] = true;
						CreateTimer(0.75, FlipToggle, attacker);
					}
				}
			}
			//no damage for victim
			return Plugin_Handled;
		}
	}
	else
	{
		//attacker and victim infected checks
		if (IsValidClientAndInGameAndInfected(attacker) && IsValidClientAndInGameAndInfected(victim) && victim != attacker)
		{
			//check reverse friendly-fire parameters for: attacker=admin, victim=bot
			if (!(ReverseIfAttackerAdmin(attacker) || ReverseIfVictimBot(victim)))
			{
				//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
				// pan0s | 2021-04-20 | Add Chances for no reversing damage.
				if(UseChance(attacker, damage)) return Plugin_Handled;
				//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

				//accumulate damage total for infected/tank attacker
				if (IsTank(attacker))
				{
					g_fAccumDamageAsTank[attacker] += damage;
				}
				else
				{
					g_fAccumDamageAsInfected[attacker] += damage;
				}
				//debug acculated damage
				//PrintToServer("Infected Atk: %N, Dmg: %f, AcmDmgTank: %f, TankMaxDmg %f, AcmDmgInf: %f, InfMaxDmg: %f", attacker, damage, g_fAccumDamageAsTank[attacker], g_fTankMaxDamage, g_fAccumDamageAsInfected[attacker], g_fInfectedMaxDamage);
				//does accumulated damage exceed "reverseff_tankmaxdamage" or "reverseff_infectedmaxdamage"
				if (((g_fTankMaxDamage > 0 && IsTank(attacker) && g_fAccumDamageAsTank[attacker] > g_fTankMaxDamage) || (g_fInfectedMaxDamage > 0 && !IsTank(attacker) && g_fAccumDamageAsInfected[attacker] > g_fInfectedMaxDamage)) && !IsFakeClient(attacker))
				{
					if (g_iBanDuration == -1)
					{
						//kick attacker
						KickClient(attacker, "%T", "ExcessiveTA", attacker);
					}
					else
					{
						//ban attacker for "reverseff_banduration"
						char BanMsg[50];
						Format(BanMsg, sizeof(BanMsg), "%T", "ExcessiveTA", attacker, attacker);
						BanClient(attacker, g_iBanDuration, BANFLAG_AUTO, "ExcessiveTA", BanMsg, _, attacker);
					}
					//reset accumulated damage
					g_fAccumDamage[attacker] = 0.0;
					g_fAccumDamageAsTank[attacker] = 0.0;
					g_fAccumDamageAsInfected[attacker] = 0.0;
					//do not inflict damage since player was kicked/banned
					return Plugin_Handled;
				}
				//inflict damage to attacker
				SDKHooks_TakeDamage(attacker, inflictor, victim, damage, damagetype, weapon, damageForce, damagePosition);
				//PrintToServer("%N %T %N", attacker, "Attacked", LANG_SERVER, victim);
				//CPrintToChat(attacker, "{orange}[ReverseFF]{lightgreen} %t {olive}%N{lightgreen}, %t.", "YouAttacked", victim, "InfectedFF");
			}
			//no damage for victim
			return Plugin_Handled;
		}
	}
	//all other damage behaves normal
	return Plugin_Continue;
}

//pan0s | 20-Apr-2021 | Fixed: Server crashes if reversing chainsaw damage makes the attacker incapacitated or dead.
//pan0s | start chainsaw fix part 2
public Action ChainsawTakeDamageTimer(Handle timer, DataPack hPack)
{
	//read the DataPack
	hPack.Reset();
	int attacker = hPack.ReadCell();
	int inflictor = hPack.ReadCell();
	int victim = hPack.ReadCell();
	float damage = hPack.ReadFloat();
	int damagetype = hPack.ReadCell();
	int weapon = hPack.ReadCell();
	float damageForce[3];
	float damagePosition[3];
	for (int i=0; i<3; i++)
	{
		damageForce[i] = hPack.ReadFloat();
		damagePosition[i] = hPack.ReadFloat();
	}
	delete hPack;
	//pan0s | end chainsaw fix part 2
	
	//inflict (chainsaw) damage to attacker
	//add 1HP to victim then damage them for 1HP so the displayed message and vocalization order are correct,
	//then damage attacker as self damage so there is no vocalization, just pain grunt.
	SetEntityHealth(victim, GetClientHealth(victim) + 1);
	SDKHooks_TakeDamage(victim, inflictor, attacker, 1.0, 0, weapon, g_fDmgFrc, g_fDmgPos);
	SDKHooks_TakeDamage(attacker, inflictor, attacker, damage, damagetype, weapon, damageForce, damagePosition);

	CountTotalDamage(attacker, victim, damage);
}

stock bool IsWeaponGrenadeLauncher(char[] sInflictorClass)
{
	return (StrEqual(sInflictorClass, "grenade_launcher_projectile"));
}

stock bool IsWeaponMinigun(char[] sInflictorClass)
{
	return (StrEqual(sInflictorClass, "prop_minigun") || StrEqual(sInflictorClass, "prop_minigun_l4d1") || StrEqual(sInflictorClass, "prop_mounted_machine_gun"));
}

stock bool IsWeaponMelee(char[] sInflictorClass)
{
	return (StrEqual(sInflictorClass, "weapon_melee"));
}

stock bool IsWeaponChainsaw(char[] sInflictorClass)
{
	return (StrEqual(sInflictorClass, "weapon_chainsaw"));
}

stock bool IsSpecialAmmo(int weapon, int attacker, int inflictor, int damagetype, bool bWeaponGL)
{
	//damage from gun with special ammo
	if ((weapon > 0 && attacker == inflictor) && (damagetype & DMG_BURN || damagetype & DMG_BLAST))
	{
		return true;
	}
	//damage from grenade launcher with incendiary ammo
	if ((bWeaponGL) && (damagetype & DMG_BURN))
	{
		return true;
	}
	//damage from melee weapon or weapon with regular ammo
	return false;
}

stock bool IsClientAdmin(int client)
{
    return CheckCommandAccess(client, "generic_admin", ADMFLAG_GENERIC, false);
}

stock bool IsValidClientAndInGameAndSurvivor(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}

stock bool IsValidClientAndInGameAndInfected(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3);
}

stock bool IsClientIncapped(int client)
{
	//convert integer to boolean for return value
	return !!GetEntProp(client, Prop_Send, "m_isIncapacitated", 1);
}

public Action AnnouncePlugin(Handle timer, int client)
{
	if (IsClientInGame(client) && g_bCvarAllow)
	{
		if (g_bAllReversePlugins)
		{
			CPrintToChat(client, "%T", "AnnounceAll", client);
		}
		else
		{
			CPrintToChat(client, "%T", "Announce", client);
		}
	}
}

public Action Event_StartGrace (Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if (client > 0)
	{
		if (g_bGrace[client])
		{
			if (g_hEndGrace[client] != INVALID_HANDLE)
			{
				KillTimer(g_hEndGrace[client]);
				g_hEndGrace[client] = INVALID_HANDLE;
			}
		}
		else
		{
			g_bGrace[client] = true;
		}
		g_hEndGrace[client] = CreateTimer(2.0, EndGrace, client);
		//PrintToServer("Event_StartGrace");
	}
}

public Action EndGrace (Handle timer, int client)
{
		g_bGrace[client] = false;
		g_hEndGrace[client] = INVALID_HANDLE;
		//PrintToServer("Event_EndGrace");
}

public Action Event_PullCarry (Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if (!g_bCvarReverseIfPullCarry)
	{
		g_bGrace[client] = true;
		//PrintToServer("Event_PullCarry");
	}
}

public Action Event_PounceRide (Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	g_bGrace[client] = true;
	//PrintToServer("Event_PounceRide");
}

public Action FlipToggle(Handle timer, int attacker)
{
  g_bToggle[attacker] = false;
}

stock bool IsTank(int client)
{
	char sNetClass[32];
	GetEntityNetClass(client, sNetClass, sizeof(sNetClass));
	return (StrEqual(sNetClass, "Tank", false));
}

stock bool ReverseIfAttackerAdmin(int attacker)
{
	return (IsClientAdmin(attacker) && !g_bCvarReverseIfAdmin);
}

stock bool ReverseIfVictimBot (int victim)
{
	return (IsFakeClient(victim) && !g_bCvarReverseIfBot);
}

stock bool ReverseIfVictimIncapped (int victim)
{
	return (IsClientIncapped(victim) && !g_bCvarReverseIfIncapped);
}

stock bool ReverseIfAttackerIncapped (int attacker)
{
	return (IsClientIncapped(attacker) && !g_bCvarReverseIfAttackerIncapped);
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// pan0s | 2021-04-20 | Add Chances for no reversing damage.
public void InitChances(int client)
{
	g_iChances[client] = g_iCvarChances;
}

public bool UseChance(int client, float damage)
{
	if(IsFakeClient(client)) return false; 
	if(damage > 0) g_bIsHurting[client] = true;
	else if(damage < 1.0)
	{
		delete g_hDelayTextTimer[client];
		g_hDelayTextTimer[client] = CreateTimer(0.01, HandleDelayTextTimer, client);
		return true;
	}	
	//Reset chances timer
	delete g_hResetChanceTimer[client];
	g_hResetChanceTimer[client] = CreateTimer(g_fCvarResetTime, HandleResetChanceTimer, client);

	if(g_iChances[client] > 0) 
	{
		delete g_hReduceChanceTimer[client];
		g_hReduceChanceTimer[client] = CreateTimer(0.01, HandleReduceChanceTimer, client);
		return true;
	}
	return false;
}

// pan0s | 31-05-2021 | Count total damage
public void CountTotalDamage(int attacker, int victim, float damage)
{
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// pan0s | 2021-05-31 | Count total damage which made in 0.1 second.
	g_fCountDamage[attacker] += damage;
	if(damage > 0)
	{
		DataPack hPack = new DataPack();
		delete g_hCountDamageTimer[attacker];
		g_hCountDamageTimer[attacker] = CreateTimer(0.01, HandleCountDamageTimer, hPack);
		hPack.WriteCell(attacker);
		hPack.WriteCell(victim);
	}
	/////////////////////////////////////////////////////////////////////////////////////////////
}

public Action Event_WeaponFire(Event event, char[] event_name, bool dontBroadcast)
{
	int client = GetEventClient(event, "userid");
	if(IsValidClient(client) && !IsFakeClient(client))
		g_bNotice[client] = false;
	return Plugin_Handled;
}

public Action HandleDelayTextTimer(Handle timer, int client)
{
	if(cvar_reverseff_zero_damage_msg_on.BoolValue && g_iChances[client] > 0 && !g_bIsHurting[client] && !g_bNotice[client])
	{
		GameSetting game;
		game.RefreshDifficulty();
		if(!StrEqual(game.difficulty, "easy", false))
		{
			CPrintToChat(client, "%T%T","SYSTEM", client,"NO_CHANCE_CONSUMED", client, g_iChances[client]);
			g_bNotice[client] = true;
		}
	}
	g_hDelayTextTimer[client] = null;
}

public Action HandleReduceChanceTimer(Handle timer, int client)
{
	g_bNotice[client] = true;
	if(--g_iChances[client] <= 0) CPrintToChat(client, "%T%T","SYSTEM", client,"NO_CHANCE", client);
	else CPrintToChat(client, "%T%T","SYSTEM", client,"REMAINING_CHANCES", client, g_iChances[client]);

	g_hReduceChanceTimer[client] = null;
	g_bIsHurting[client] = false;
}

public Action HandleResetChanceTimer(Handle timer, int client)
{
	InitChances(client);
	if(IsClientInGame(client)) CPrintToChat(client, "%T%T","SYSTEM", client,"RESET_CHANCES", client, g_iChances[client], g_fCvarResetTime);

	g_hResetChanceTimer[client] = null;
	g_bIsHurting[client] = false;
}

// pan0s | 2021-04-21 | Count total damage which made in 0.1 second.
public Action HandleCountDamageTimer(Handle timer, DataPack hPack)
{
	hPack.Reset();
	int attacker = hPack.ReadCell();
	int victim = hPack.ReadCell();
	for(int i = 1; i<=MaxClients; i++) if(IsValidClient(i) && !IsInfected(i)) 
		CPrintToChat(i, "%T%T", "SYSTEM", i, "REVERSE_DAMAGE_ATTACKED", i, attacker, victim, g_fCountDamage[attacker]);
	g_fCountDamage[attacker] = 0.0;

	g_hCountDamageTimer[attacker] = null;
	g_bIsHurting[attacker] = false;
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////