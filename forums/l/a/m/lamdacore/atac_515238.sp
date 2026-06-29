// Force all lines to require a semi-colon to signify the end of the line
#pragma semicolon 1
// allows the use of more memory
#pragma dynamic 65536
// core includes
#define REQUIRE_PLUGIN
#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <ircrelay>
#define REQUIRE_EXTENSIONS
#include <sdktools>

// Colors
//GLOBAL DEFINES
#define YELLOW 0x01
#define TEAMCOLOR 0X03
#define GREEN 0x04
#define MAX_PLAYERS 64
#define ATAC_VERSION "1.3.3"

// Plugin definitions
public Plugin:myinfo = 
{
	name = "Advanced Team Attack Control",
	author = "FlyingMongoose",
	description = "Advanced Team Attack Control: Source",
	version = ATAC_VERSION,
	url = "http://www.steamfriends.com/"
};

// IRC Relay
new bool:g_ircRelay;

// Define cvars variable globals
new Handle:cvarATACOption;
new Handle:cvarATACAdminImmunity;
new Handle:cvarATACGlobalImmunity;
new Handle:cvarATACProtectionTimer;
new Handle:cvarATACAction;
new Handle:cvarATACTACount;
new Handle:cvarATACTKCount;
new Handle:cvarATACBanTime;
new Handle:cvarATACTakeNextAction;
new Handle:cvarATACSlayLimit;
new Handle:cvarATACKickLimit;
new Handle:cvarATACDefaultForgive;
new Handle:cvarATACMenuForgive;
new Handle:cvarATACMenuSlay;
new Handle:cvarATACMenuSlapDamage;
new Handle:cvarATACMenuUberSlap;
new Handle:cvarATACMenuBurn;
new Handle:cvarATACMenuFreeze;
new Handle:cvarATACNextSpawnPunishTime;
new Handle:cvarATACForgiveTimer;
new Handle:cvarATACResetTime;
new Handle:cvarATACMirrorDamage;
new Handle:cvarATACHealMirrorDamage;
new Handle:cvarATACIgnoreBots;
new Handle:cvarATACIrcRelay;
// BEGIN MOD BY LAMDACORE
new Handle:cvarATACKarmaCount;
// END MOD BY LAMDACORE

// Menu Handle
new Handle:atacMenu;
new Handle:atacImmuneMenu;

// Timer Defines
new Handle:ForgiveTimer[MAX_PLAYERS+1];
new TimeOfDeath;

// KeyValue and File globals for storing and loading player tk info
new String:atacFile[PLATFORM_MAX_PATH];
new Handle:atacKV;

// important other globals
new taCounter[MAX_PLAYERS+1];
new tkCounter[MAX_PLAYERS+1];
new slayCounter[MAX_PLAYERS+1];
new kickCounter[MAX_PLAYERS+1];
// BEGIN MOD BY LAMDACORE
new karmaCounter[MAX_PLAYERS+1];
// END MOD BY LAMDACORE

// used to slay a player the next time they spawn if they are dead when not forgiven
new bool:SlayNextSpawn[MAX_PLAYERS+1];

// menu punishment flags
new Handle:UberSlapTime[MAX_PLAYERS+1][MAX_PLAYERS+1];
new Handle:FreezeTime[MAX_PLAYERS+1][MAX_PLAYERS+1];
new bool:UberSlapNextSpawn[MAX_PLAYERS+1];
new bool:BeingUberSlapped[MAX_PLAYERS+1][MAX_PLAYERS+1];
new bool:MenuSlayNextSpawn[MAX_PLAYERS+1];
new bool:MenuSlapNextSpawn[MAX_PLAYERS+1];
new bool:BurnNextSpawn[MAX_PLAYERS+1];
new bool:FreezeNextSpawn[MAX_PLAYERS+1];
new bool:IsFrozen[MAX_PLAYERS+1];

// teamkilled players by which player
new bool:killed[MAX_PLAYERS+1][MAX_PLAYERS+1];

// global spawn 
new g_SpawnTime[MAX_PLAYERS+1];

// timer for spawn punishments
new Handle:g_SpawnPunishTimer[MAX_PLAYERS+1];

// damage time global
new g_DamageTime[MAX_PLAYERS+1][MAX_PLAYERS+1];

// movetype offset
new g_MoveTypeOffset;

// Effect globals
new g_Lightning;
new g_FreezeBeam;
new g_ExplosionFire;
new g_Smoke1;
new g_Smoke2;
new g_FireBurst;

// is hooked!?
new bool:g_isHooked;

// nifty pretties
stock SlayEffects(client)
{
	// get player position
	new Float:playerpos[3];
	GetClientAbsOrigin(client,playerpos);
	
	// set lightning settings
	// set the top coordinates of the lightning effect
	new Float:toppos[3];
	toppos[0] = playerpos[0];
	toppos[1] = playerpos[1];
	toppos[2] = playerpos[2]+1000;
	// set the color of the lightning
	new lightningcolor[4];
	lightningcolor[0] = 255;
	lightningcolor[1] = 255;
	lightningcolor[2] = 255;
	lightningcolor[3] = 255;
	// how long lightning lasts
	new Float:lightninglife = 2.0;
	// width of lightning at top
	new Float:lightningwidth = 5.0;
	// width of lightning at bottom
	new Float:lightningendwidth = 5.0;
	// lightning start frame
	new lightningstartframe = 0;
	// lightning frame rate
	new lightningframerate = 1;
	// how long it takes for lightning to fade
	new lightningfadelength = 1;
	// how bright lightning is
	new Float:lightningamplitude = 1.0;
	// how fast the effect is drawn
	new lightningspeed = 250;
	
	// set smoke settings
	// how wide a 360 degree radius of smoke should be used
	new Float:smokescale = 50.0;
	// frame rate for smoke
	new smokeframerate = 2;
	
	// coordinates for smoke effecet
	new Float:SmokePos[3];
	SmokePos[0] = playerpos[0];
	SmokePos[1] = playerpos[1];
	SmokePos[2] = playerpos[2] + 10;
	
	// coordinates for uppy body/head smoke efect
	new Float:PlayerHeadPos[3];
	PlayerHeadPos[0] = playerpos[0];
	PlayerHeadPos[1] = playerpos[1];
	PlayerHeadPos[2] = playerpos[2] + 100;
	
	// should the smoke be "blown" somewhere.
	new Float:direction[3];
	direction[0] = 0.0;
	direction[1] = 0.0;
	direction[2] = 0.0;
	
	new Float:sparkstart[3];
	sparkstart[0] = playerpos[0];
	sparkstart[1] = playerpos[1];
	sparkstart[2] = playerpos[2] + 13.0;
	
	new Float:sparkdir[3];
	sparkdir[0] = playerpos[0];
	sparkdir[1] = playerpos[1];
	sparkdir[2] = playerpos[2] + 23.0;
	
	// create lightning effects and sparks, and explosion
	TE_SetupBeamPoints(toppos, playerpos, g_Lightning, g_Lightning, lightningstartframe, lightningframerate, lightninglife, lightningwidth, lightningendwidth, lightningfadelength, lightningamplitude, lightningcolor, lightningspeed);
	TE_SetupExplosion(playerpos, g_ExplosionFire, 10.0, 10, TE_EXPLFLAG_NONE, 200, 255);
	TE_SetupSmoke(playerpos, g_Smoke1, smokescale, smokeframerate);
	TE_SetupSmoke(playerpos, g_Smoke2, smokescale, smokeframerate);
	TE_SetupMetalSparks(sparkstart,sparkdir);
	
	
	TE_SendToAll(0.0);
	EmitAmbientSound("ambient/explosions/explode_8.wav", playerpos, SOUND_FROM_WORLD, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, 0.0);
}

stock Lightning(client)
{
	// get player position
	new Float:playerpos[3];
	GetClientAbsOrigin(client,playerpos);
	
	// set lightning settings
	// set the top coordinates of the lightning effect
	new Float:toppos[3];
	toppos[0] = playerpos[0];
	toppos[1] = playerpos[1];
	toppos[2] = playerpos[2]+1000;
	// set the color of the lightning
	new lightningcolor[4];
	lightningcolor[0] = 255;
	lightningcolor[1] = 255;
	lightningcolor[2] = 255;
	lightningcolor[3] = 255;
	
	// how long lightning lasts
	new Float:lightninglife = 0.1;
	// width of lightning at top
	new Float:lightningwidth = 5.0;
	// width of lightning at bottom
	new Float:lightningendwidth = 5.0;
	// lightning start frame
	new lightningstartframe = 0;
	// lightning frame rate
	new lightningframerate = 1;
	// how long it takes for lightning to fade
	new lightningfadelength = 1;
	// how bright lightning is
	new Float:lightningamplitude = 1.0;
	// how fast the effect is drawn
	new lightningspeed = 250;
	
	TE_SetupBeamPoints(toppos, playerpos, g_Lightning, g_Lightning, lightningstartframe, lightningframerate, lightninglife, lightningwidth, lightningendwidth, lightningfadelength, lightningamplitude, lightningcolor, lightningspeed);
	
	TE_SendToAll(0.0);
}

stock FreezeBeam(client)
{
	// get player position
	new Float:playerpos[3];
	GetClientAbsOrigin(client,playerpos);
	
	// set lightning settings
	// set the top coordinates of the lightning effect
	new Float:toppos[3];
	toppos[0] = playerpos[0];
	toppos[1] = playerpos[1];
	toppos[2] = playerpos[2]+1000;
	// set the color of the lightning
	new lightningcolor[4];
	lightningcolor[0] = 255;
	lightningcolor[1] = 255;
	lightningcolor[2] = 255;
	lightningcolor[3] = 255;
	
	// how long lightning lasts
	new Float:lightninglife = 0.1;
	// width of lightning at top
	new Float:lightningwidth = 5.0;
	// width of lightning at bottom
	new Float:lightningendwidth = 50.0;
	// lightning start frame
	new lightningstartframe = 0;
	// lightning frame rate
	new lightningframerate = 1;
	// how long it takes for lightning to fade
	new lightningfadelength = 1;
	// how bright lightning is
	new Float:lightningamplitude = 1.0;
	// how fast the effect is drawn
	new lightningspeed = 250;
	
	TE_SetupBeamPoints(toppos, playerpos, g_FreezeBeam, g_FreezeBeam, lightningstartframe, lightningframerate, lightninglife, lightningwidth, lightningendwidth, lightningfadelength, lightningamplitude, lightningcolor, lightningspeed);
	
	TE_SendToAll(0.0);
}

// sets a player's health
stock SetClientHealth(client, amount)
{
	new HPOffs = FindDataMapOffs(client,"m_iHealth");
	SetEntData(client,HPOffs,amount,true);
}

public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("IrcMessage");
	MarkNativeAsOptional("RegisterIrcCommand");
	MarkNativeAsOptional("IrcGetCmdArgc");
	MarkNativeAsOptional("IrcGetCmdArgv");
	
	return true;
}

public OnPluginStart()
{
	LoadTranslations("atac.phrases");
	g_MoveTypeOffset = FindSendPropOffs("CBaseEntity","movetype");
	if(g_MoveTypeOffset == -1){
		LogError("* FATAL ERROR: Failed to get offset CBaseEntity::movetype");
		SetFailState("[ATAC] * FATAL ERROR: Failed to get offset CBaseEntity::movetype");
		g_isHooked = false;
	}else{
		// create server console variabls
		// version cvar
		CreateConVar("atac_version",ATAC_VERSION, _,FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY);
		// On/Off cvar
		cvarATACOption = CreateConVar("atac_option","1","Turns ATAC On/Off and makes it respond to FF",FCVAR_PLUGIN,true,0.0,true,1.0);
		// Immunity on/off cvar
		cvarATACAdminImmunity = CreateConVar("atac_immunity","1","Turns admin immunity On/Off",FCVAR_PLUGIN,true,0.0,true,1.0);
		// Immunity level cvar
		cvarATACGlobalImmunity = CreateConVar("atac_globalimmunity","0","Sets the type of immunity\n0 = All admins\n1 = Admins in groups with global immunity",FCVAR_PLUGIN,true,0.0,true,1.0);
		// Menu on/off cvar
		cvarATACMenuForgive = CreateConVar("atac_menuforgive","1","Turns the forgive menu on or off\n0 = Chat based\n1 = menu based",FCVAR_PLUGIN,true,0.0,true,1.0);
		// Slay option on/off cvar
		cvarATACMenuSlay = CreateConVar("atac_menuslay","1","Turns the slay option on/off on the menu for forgiveness\nThis does NOT count in the slaylimit",FCVAR_PLUGIN,true,0.0,true,1.0);
		// Slap damage option/setting cvar
		cvarATACMenuSlapDamage = CreateConVar("atac_menuslapdamage","50","How much damage the \"slap\" option in the menu does\n0 = off",FCVAR_PLUGIN,true,0.0,true,100.0);
		// UberSlap on/off cvar
		cvarATACMenuUberSlap = CreateConVar("atac_menuuberslap","1","If enabled it slaps the TKer continuously until they die",FCVAR_PLUGIN,true,0.0,true,1.0);
		// Burn on/off cvar
		cvarATACMenuBurn = CreateConVar("atac_menuburn","1","If enabled it will burn the TKer continuously until they die",FCVAR_PLUGIN,true,0.0,true,1.0);
		// Freeze on/off cvar
		cvarATACMenuFreeze = CreateConVar("atac_menufreeze","1","If enabled it will freeze the TKer",FCVAR_PLUGIN,true,0.0,true,1.0);
		// Delay before next spawn punishment occurs (must be higher than 3 to allow some sigscanned functions to work)
		cvarATACNextSpawnPunishTime = CreateConVar("atac_nextspawnpunishdelay","6","Number, in seconds, to delay, before a punishment takes place after a player spawns\nOnly applies when the player was dead during punishment selection\nMin: 3\nMax: 10",FCVAR_PLUGIN,true,3.0,true,10.0);
		// Time, in seconds, after spawn that a player is protected
		cvarATACProtectionTimer = CreateConVar("atac_spawnprotection","10","Number of seconds after a player spawns for spawn protection to be on\nCSS Users take mp_freezetime into consideration and add to the desired value\nMin: 0\nMax: 30",FCVAR_PLUGIN,true,0.0,true,30.0);
		// Action that is taken when atac_tklimit is reached
		cvarATACAction = CreateConVar("atac_action","2","What action is taken after TK limit is reached\n3 = ban for atac_bantime many minutes\n2 = kick\n1 = slay",FCVAR_PLUGIN,true,0.0,false);
		// How many minutes for a ban
		cvarATACBanTime = CreateConVar("atac_bantime","60","How many minutes a player is banned for too many TKs\n0 = permanent\n>0 = number of minutes",FCVAR_PLUGIN,true,0.0,false);
		// Team Attack Limit (reach this number and get +1/atac_tklimit)
		cvarATACTACount = CreateConVar("atac_talimit","10","Number of Team Attacks to equal a Team Kill\n0 = off",FCVAR_PLUGIN,true,0.0,false);
		// Team Kill Limit (reach this limit and atac_action is taken)
		cvarATACTKCount = CreateConVar("atac_tklimit","3","Number of Team Kills before action is taken",FCVAR_PLUGIN,true,0.0,false);
		// Well the next action after what atac_action occurs if atac_action occurs multiple times
		cvarATACTakeNextAction = CreateConVar("atac_nextaction","1","If set this will cause the plugin to take the next level of atac_action after a 'limit' is reached",FCVAR_PLUGIN,true,0.0,true,1.0);
		// Number of slays before a kick w/ atac_nextaction
		cvarATACSlayLimit = CreateConVar("atac_slaylimit","3","Number of slays until next level of atac_action is taken",FCVAR_PLUGIN,true,0.0,false);
		// Number of kicks before a ban w/ atac_nextaction
		cvarATACKickLimit = CreateConVar("atac_kicklimit","3","Number of kicks until next level of atac_action is taken",FCVAR_PLUGIN,true,0.0,false);
		// When using chat commands is forgiveness automatically taken or punishment automatically taken when no action is performed by the victim (default player is punished)
		cvarATACDefaultForgive = CreateConVar("atac_defaultpunish","1","If no action is taken by the end of atac_forgivetimer this happens\n1 = Punish\n0 = Forgive",FCVAR_PLUGIN,true,0.0,true,1.0);
		// Time, in seconds after a TK that the victim can choose to forgive or punish (based on atac_defaultpunish)
		cvarATACForgiveTimer = CreateConVar("atac_forgivetimer","10","Time, in seconds, in which a player can choose to forgive their team killer",FCVAR_PLUGIN,true,1.0,false);
		// How many hours before the keyvalues clears out any players past this time
		cvarATACResetTime = CreateConVar("atac_resettime","1","How many hours before a player's TK and TA info is reset\nMin: 1\nMax: 48",FCVAR_PLUGIN,true,1.0,true,48.0);
		// Mirror team-attack damage (using slap function)
		cvarATACMirrorDamage = CreateConVar("atac_mirrordamage","1","Mirror the damage done when a player is team attacked",FCVAR_PLUGIN,true,0.0,true,1.0);
		// Heal damage done due to team-attack
		cvarATACHealMirrorDamage = CreateConVar("atac_healmirrordamage","0","If mirror damage is on, this will also heal the damage done to the victim\nThis does not prevent headshot TKs",FCVAR_PLUGIN,true,0.0,true,1.0);
		// Ignore bots in team-attacks and team-kills (suggested be set to 1 at all times)
		cvarATACIgnoreBots = CreateConVar("atac_ignorebots","1","1 = TK/TA against bots counter, 0 = TK/TA against bots ignored",FCVAR_PLUGIN,true,0.0,true,1.0);
		// Turns IRC Relay on and off
		cvarATACIrcRelay = CreateConVar("atac_ircrelay","0","Display kicks and bans to IRC Relay",FCVAR_PLUGIN,true,0.0,true,1.0);
		// BEGIN MOD BY LAMDACORE
		cvarATACKarmaCount = CreateConVar("atac_karmacount", "6", "Number of points gained for TK reduction", FCVAR_PLUGIN,true,0.0,false);
		// END MOD BY LAMDACORE
		// build the path to the stored player information file
		BuildPath(Path_SM,atacFile,sizeof(atacFile),"data/atac_stored.txt");
		// create the keyvalues for the plugin
		atacKV = CreateKeyValues("atac");
		// load the stored player information file if it exists
		if(FileExists(atacFile)){
			FileToKeyValues(atacKV,atacFile);
		}
		// Create Config File Automatically
		AutoExecConfig(true,"atac","sourcemod");
		// Hooks the change of the the atac_action cvar
		HookConVarChange(cvarATACOption,ATACOptionChange);
				
		// If offsets are all found, start a timer to hook events
		CreateTimer(3.0, OnPluginStart_Delayed);
	}
}

// When hook timer is up this is called
public Action:OnPluginStart_Delayed(Handle:timer)
{
	if(GetConVarBool(cvarATACOption)){
		// Hook events and console commands
		g_isHooked = true;
		// Hooks the player_hurt event
		HookEvent("player_hurt",ev_PlayerHurt);
		// Hooks the player_death event
		HookEvent("player_death",ev_PlayerDeath);
		// Hooks the player_spawn event
		HookEvent("player_spawn",ev_PlayerSpawn);
		// Hooks the console command sm_tkcount, and the chat commands /tkcount and !tkcount
		RegConsoleCmd("sm_tkcount",Command_TKCount);
		// Hooks the console command sm_tacount, and the chat commands /tacount and !tacount
		RegConsoleCmd("sm_tacount",Command_TACount);
		// Hooks the console command sm_forgivetk, and the chat commands /forgivetk and !forgivetk
		RegConsoleCmd("sm_forgivetk",Command_ForgiveTK);
		// Hooks the console command sm_forgive, and the chat commands /forgive and !forgive
		RegConsoleCmd("sm_forgive",Command_ForgiveTK);
		// Hooks the console command sm_tk, and the chat commands /ftk and !ftk
		RegConsoleCmd("sm_ftk",Command_ForgiveTK);
		// Hooks the console command sm_punishtk, and the chat commands /punishtk and !punishtk
		RegConsoleCmd("sm_punishtk",Command_PunishTK);
		// Hooks the console command sm_punish, and the chat commands /punish and !punish
		RegConsoleCmd("sm_punish",Command_PunishTK);
		// Hooks the console command sm_ptk, and the chat commands /ptk and !ptk
		RegConsoleCmd("sm_ptk",Command_PunishTK);
		
		// Debugging command
		RegAdminCmd("sm_tkme",Command_TKMe,ADMFLAG_RCON);
		
		// Output to confirm load
		LogMessage("[ATAC] - Loaded");
	}
}

public Action:Command_TKMe(client,args){
	killed[client][client] = true;
	ForgiveMenu(client,client,"you");
	return Plugin_Handled;
}

// Handles console commands sm_punishtk, sm_ptk, sm_punish, and chat commands /punishtk, /ptk, /punish, !punishtk, !ptk, !punish
public Action:Command_PunishTK(client,args){
	// if the client is not the server
	if(client != 0){
		// check to see if the menu is on
		new bool:menuOn = GetConVarBool(cvarATACMenuForgive);
		if(!menuOn){
			// if the menu is not on continue
			// define string information
			decl String:clientName[64];
			GetClientName(client,clientName,64);
			new bool:DoNotForgive = GetConVarBool(cvarATACDefaultForgive);
			// if defaultpunish is set to 1 then allow the next itmes
			if(!DoNotForgive){
				// get the maximum number of tks
				new tkCount = GetConVarInt(cvarATACTKCount);
				// loop through all players
				for(new attacker = 1; attacker <= GetMaxClients(); ++ attacker){
					// if the attacker is connected, he team killed the client, the attacker is in game, and the attacker is not the server continue
					if(IsClientConnected(attacker) && killed[attacker][client] && IsClientInGame(attacker) && attacker != 0){
						// declare string for the attacker's name
						decl String:attackerName[64];
						// Get the attacker's name
						GetClientName(attacker,attackerName,64);
						// increate the player's number of TK's
						tkCounter[attacker]++;
						// if the maximum tk's isset
						// and the number of TK's is greater than or equal to the maximum
						// then take next action
						if(tkCount > 0 && tkCounter[attacker] >= tkCount){
							// call the subroutine that takes action when the tkcount has been reached
							if(TKAction(attacker)){
								return Plugin_Handled;
							}
							// reset the number of tk's
							tkCounter[attacker] = 0;
							// reset that the player tk'd was tk'd by this person
							killed[attacker][client] = false;
						}else{
							// even if the tkcount is not higher than or equal to the maximum tks
							// the attacker tk-ing the client gets reset
							killed[attacker][client] = false;
						}
						// loop through and output to all players that the attacker was not punished
						for(new i = 1; i <= GetMaxClients(); ++i){
							if(IsClientConnected(i) && IsClientInGame(i)){
								PrintToConsole(i,"[ATAC] %T","Not Forgiven",LANG_SERVER,attackerName,tkCounter[attacker],tkCount);
							}
						}
						PrintToChatAll("%c[ATAC]%c %T",GREEN,YELLOW,"Not Forgiven",LANG_SERVER,attackerName,tkCounter[attacker],tkCount);
						// end the timer that was started on the player's death
						CloseHandle(ForgiveTimer[client]);
					}
				}
			}
			return Plugin_Handled;
		}else{
			return Plugin_Continue;
		}
	}
	return Plugin_Continue;
}

public Action:Command_ForgiveTK(client,args){
	if(client != 0){
		new bool:menuOn = GetConVarBool(cvarATACMenuForgive);
		if(!menuOn){
			// define string information
			decl String:clientName[64];
			GetClientName(client,clientName,64);
			// if the menu option is not on then continue
			if(!menuOn){
				new bool:DoNotForgive = GetConVarBool(cvarATACDefaultForgive);
				// if defaultpunish is set to 1 then allow the next itmes
				if(DoNotForgive){
					// if the player says !forgivetk, !ftk, or !forgive then forgive the TK against them
					if(IsValidHandle(ForgiveTimer[client])){
						// loop through all the players in the server
						for(new i = 1; i <= GetMaxClients(); ++i){
							// if the client being forgiven is both in the server, and killed the person forgiving take the next step
							if(IsClientConnected(i) && IsClientInGame(i) && killed[i][client]){
								decl String:attackerName[64];
								GetClientName(i,attackerName,64);
								killed[i][client] = false;
								CloseHandle(ForgiveTimer[client]);
								// output to all players that the TK has been forgiven
								for(new players = 1; players <= GetMaxClients(); ++players){
									if(IsClientConnected(players) && IsClientInGame(players)){
										PrintToConsole(players,"[ATAC] %T","Forgiven",LANG_SERVER,clientName,attackerName);
									}
								}
								PrintToChatAll("%c[ATAC]%c %T",GREEN,YELLOW,"Forgiven",LANG_SERVER,clientName,attackerName);
							}
						}
					}
				}
			}
			return Plugin_Handled;
		}else{
			return Plugin_Continue;
		}
	}
	return Plugin_Continue;
}

public Action:Command_TACount(client,args){
	if(client != 0){
		// if the plugin is on continue
		new bool:OptionOn = GetConVarBool(cvarATACOption);
		if(OptionOn){
		// if the player says !tacount then output how many TA's they have
			new taCount = GetConVarInt(cvarATACTACount);
			ReplyToCommand(client,"%c[ATAC]%c %T",GREEN,YELLOW,"TA Count",LANG_SERVER,taCounter[client],taCount);
			// prevents the item from being displayed to the players
			return Plugin_Handled;
		}
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

// when a player uses chat this will be called
public Action:Command_TKCount(client,args){
	if(client != 0){
		// if the plugin is on continue
		new bool:OptionOn = GetConVarBool(cvarATACOption);
		if(OptionOn){
			// if the player says !tkcount then output how many TK's they have
			new tkCount = GetConVarInt(cvarATACTKCount);
			ReplyToCommand(client,"%c[ATAC]%c %T",GREEN,YELLOW,"TK Count",LANG_SERVER,tkCounter[client],tkCount);
			return Plugin_Handled;
		}
		return Plugin_Continue;
	}
	return Plugin_Continue;
}


// When the cvar for the plugin is changed this checks it's value and hooks or unhooks if it's turned on or off
public ATACOptionChange(Handle:convar, const String:oldValue[], const String:newValue[]){
// if the cvar is outside it's boundaries it will unhook
	if(GetConVarInt(cvarATACOption) != 1){
		if(g_isHooked == true){
			UnhookEvent("player_hurt",ev_PlayerHurt);
			UnhookEvent("player_death",ev_PlayerDeath);
			UnhookEvent("player_spawn",ev_PlayerSpawn);
			g_isHooked = false;
		}
// if the plugin is not already hooked this will hook the events
	}else if(g_isHooked == false){
		HookEvent("player_hurt",ev_PlayerHurt);
		HookEvent("player_death",ev_PlayerDeath);
		HookEvent("player_spawn",ev_PlayerSpawn);
		
		g_isHooked = true;
	}
}


public OnMapStart()
{
	// precache effects for slay
	// precache lightning texture
	g_Lightning = PrecacheModel("materials/sprites/tp_beam001.vmt", false);
	// precache freeze beam texture
	g_FreezeBeam = PrecacheModel("materials/sprites/plasmabeam.vmt",false);
	// Precache explosion
	g_ExplosionFire = PrecacheModel("materials/effects/fire_cloud1.vmt",false);
	// precache smoke
	g_Smoke1 = PrecacheModel("materials/effects/fire_cloud1.vmt",false);
	// precache another smoke
	g_Smoke2 = PrecacheModel("materials/effects/fire_cloud2.vmt",false);
	// precache a little fire
	g_FireBurst = PrecacheModel("materials/sprites/fireburst.vmt",false);
	// precache the explosion sound (used with slay)
	PrecacheSound("ambient/explosions/explode_8.wav",false);
	// precache slap sound.
	PrecacheSound("player/pl_fallpain1.wav",false);
	// precache ice/freeze sound
	PrecacheSound("ambient/atmosphere/terrain_rumble1.wav",false);
	// Check if precache fails
	if(g_Lightning == 0 || g_Smoke1 == 0 || g_Smoke2 == 0 || g_FireBurst == 0 || g_ExplosionFire == 0 || !IsSoundPrecached("player/pl_fallpain1.wav") || !IsSoundPrecached("ambient/explosions/explode_8.wav") || !IsSoundPrecached("ambient/atmosphere/terrain_rumble1.wav")){
		SetFailState("[ATAC] Precache Failed");
	}
	// calls the functions to pull players older than the hours set in atac_resettime from the keyvalues
	PrunePlayers(atacKV);
}

public PrunePlayers(Handle:kv){
	// prune information
	// puts current position at the root node
	KvRewind(kv);
	// gets the time of pruning
	new RightNow = GetTime();
	// if the plugin can't find the first subkey it then ignores the pruning altogether
	if(!KvGotoFirstSubKey(kv)){
		return;
	}
	// (seemingly) infinite loop
	for(;;){
		// get the player who might be pruned last play time (based on the first disconnect)
		new LastPlayTime = KvGetNum(kv,"time");
		// calculate the difference between now, and the last time played
		new TimeDifference = RightNow - LastPlayTime;
		// get the time for resetting (in hours)
		new ResetTime = GetConVarInt(cvarATACResetTime);
		// calculates the number of hours that have passed since the player's first disconnect
		new currentTime = RoundFloat(float(TimeDifference) / 3600.0);
		// if the time, in hours, is larger than or equal to the reset time, then delete the subkey
		if(currentTime >= ResetTime){
			// if the plugin can't get to the next item to delete then forget about it and leave
			if(KvDeleteThis(kv) < 1){
				return;
			}
			// if the plugin can't get to the next key forget about it and leave
		}else if(!KvGotoNextKey(kv)){
			return;
		}
	}
}

public OnMapEnd(){
	// go to the root node of the keyvalues for storing
	KvRewind(atacKV);
	// store the keyvalues for later use
	KeyValuesToFile(atacKV,atacFile);
	// start a loop for attackers
	for(new attacker = 1; attacker <= GetMaxClients(); ++attacker){
		// start a loop for victims
		for(new victim = 1; victim <= GetMaxClients(); ++victim){
			// check to see if someone is being uberslapped
			if(BeingUberSlapped[attacker][victim]){
				// change uberslap
				BeingUberSlapped[attacker][victim] = false;
			}
			// check to see if uberslap timers exist
			if(IsValidHandle(UberSlapTime[attacker][victim])){
				// close uberslap timers
				CloseHandle(UberSlapTime[attacker][victim]);
			}
			// check to see if freeze timers exist
			if(IsValidHandle(FreezeTime[attacker][victim])){
				// close freeze timer
				CloseHandle(FreezeTime[attacker][victim]);
			}
		}
		// check to see if forgiveness timer exists (for chat)
		if(IsValidHandle(ForgiveTimer[attacker])){
			// close forgiveness timer
			CloseHandle(ForgiveTimer[attacker]);
		}
		// check to see if spawn punish timer exists
		if(IsValidHandle(g_SpawnPunishTimer[attacker])){
			// close spawn punish timer
			CloseHandle(g_SpawnPunishTimer[attacker]);
		}
	}
	// check to see if atac menu exists
	if(IsValidHandle(atacMenu)){
		// close menu handle
		CloseHandle(atacMenu);
	}
	// check to see if atac immunity menu exists
	if(IsValidHandle(atacImmuneMenu)){
		// close immunity menu handle
		CloseHandle(atacImmuneMenu);
	}
}

StoreInfo(client){
		// if the player is not a bot continue
	if(!IsFakeClient(client)){
		// if the player index is not 0 (server) continue
		if(client != 0){
			// declare the client's steamid var
			decl String:SteamID[64];
			// get the current time
			new Time = GetTime();
			// get client steamid
			GetClientAuthString(client,SteamID,64);
			// go to the root node
			KvRewind(atacKV);
			// if the plugin fails to read an entry coinciding with the steamid
			if(!KvJumpToKey(atacKV,SteamID,false)){
				// go to root node
				KvRewind(atacKV);
				// create new entry
				KvJumpToKey(atacKV,SteamID,true);
				// set values
				KvSetNum(atacKV,"ta",taCounter[client]);
				KvSetNum(atacKV,"tk",tkCounter[client]);
				KvSetNum(atacKV,"slays",slayCounter[client]);
				KvSetNum(atacKV,"kicks",kickCounter[client]);
				KvSetNum(atacKV,"time",Time);
			}else{
				// otherwise, re-write the entry
				KvRewind(atacKV);
				KvJumpToKey(atacKV,SteamID);
				KvSetNum(atacKV,"ta",taCounter[client]);
				KvSetNum(atacKV,"tk",tkCounter[client]);
				KvSetNum(atacKV,"slays",slayCounter[client]);
				KvSetNum(atacKV,"kicks",kickCounter[client]);
				new LastPlayTime = KvGetNum(atacKV,"time");
				new TimeDifference = Time - LastPlayTime;
				new ResetTime = GetConVarInt(cvarATACResetTime);
				new currentTime = RoundFloat(float(TimeDifference) / 3600.0);
				// if the first disconnect is shorter than the resettime
				if(currentTime < ResetTime){
					// re-write the first disconnect
					KvSetNum(atacKV,"time",LastPlayTime);
				}else{
					// otherwise write a new time
					KvSetNum(atacKV,"time",Time);
				}
			}
			for(new i = 1; i <= GetMaxClients(); ++i){
				// make sure the player's index that a player was TK'd is cleared on disconnect no matter what
				// did the client kill i
				killed[client][i] = false;
				// is the client being uberslapped by i
				if(BeingUberSlapped[client][i]){
					// if so cancel it
					BeingUberSlapped[client][i] = false;
				}
				// if the client is being uberslapped and the timer is still going
				if(IsValidHandle(UberSlapTime[client][i])){
					// close the uberslap timer
					CloseHandle(UberSlapTime[client][i]);
				}
				// if the client is set for spawn punishment
				if(IsValidHandle(g_SpawnPunishTimer[client])){
					// close spawn punishment timer
					CloseHandle(g_SpawnPunishTimer[client]);
				}
				// if the client is frozen or freezetime is set for client
				if(IsValidHandle(FreezeTime[client][i])){
					// close freezetime
					CloseHandle(FreezeTime[client][i]);
				}
				// is the clien frozen
				if(IsFrozen[client]){
					// if so make it not so
					IsFrozen[client] = false;
				}
			}
			// if client is set for slap next spawn
			if(MenuSlapNextSpawn[client]){
				// make it not so
				MenuSlapNextSpawn[client] = false;
			}
			// if client is set for ubeslap next round
			if(UberSlapNextSpawn[client]){
				// make it not so
				UberSlapNextSpawn[client] = false;
			}
			// if client is set for slay next round
			if(MenuSlayNextSpawn[client]){
				// make it not so round
				MenuSlayNextSpawn[client] = false;
			}
			// if client is set for burn next round
			if(BurnNextSpawn[client]){
				// make it not so
				BurnNextSpawn[client] = false;
			}
		}
	}
}

public OnClientDisconnect(client){
	StoreInfo(client);
}

public OnClientAuthorized(client, const String:auth[]){
	// make sure the authorized client is not a bot
	if(!IsFakeClient(client)){
		// make sure the authorized client is not the server
		if(client != 0){
			// go to root node
			KvRewind(atacKV);
			// try to get to the sub key coinciding with the auth'd players steamid
			if(KvJumpToKey(atacKV,auth,false)){
				decl String:SteamID[64];
				// if the plugin can store the steamid then it will load the information to the player's index
				if(KvGetSectionName(atacKV,SteamID,64)){
					taCounter[client] = KvGetNum(atacKV,"ta");
					tkCounter[client] = KvGetNum(atacKV,"tk");
					slayCounter[client] = KvGetNum(atacKV,"slays");
					kickCounter[client] = KvGetNum(atacKV,"kicks");
				}
				// if the steamid doesn't exist, 0 out the client's index
			}else{
				taCounter[client] = 0;
				tkCounter[client] = 0;
				slayCounter[client] = 0;
				kickCounter[client] = 0;
			}
			// BEGIN MOD BY LAMDACORE
			karmaCounter[client] = 0;
			// END MOD BY LAMDACORE
		}
	}
}

// the next action taken when a slay or kick limit is reached
bool:NextAction(client){
	// get the client's steamid for banning later
	decl String:SteamID[64];
	GetClientAuthString(client,SteamID,64);
	// get the kick and slay limits as well as the ban time
	new SlayLimit = GetConVarInt(cvarATACSlayLimit);
	new KickLimit = GetConVarInt(cvarATACKickLimit);
	new BanTime = GetConVarInt(cvarATACBanTime);
	// get the player's name for output
	decl String:clientName[64];
	GetClientName(client,clientName,64);
	// get the action used by the server
	new ATACAction = GetConVarInt(cvarATACAction);
	if(ATACAction == 1){
		// don't allow the slay count to get higher than the slay limit
		if(slayCounter[client] > SlayLimit){
			slayCounter[client] = SlayLimit;
		}
		// if the slay counter is equal to the slay limit then kick
		if(slayCounter[client] >= SlayLimit){
			// add to the kick counter
			kickCounter[client]++;
			// don't allow the kickCounter to get higher than the kick limit
			if(kickCounter[client] > KickLimit){
				kickCounter[client] = KickLimit;
			}
			// if the kick limit is reached then kick and ban
			if(kickCounter[client] == KickLimit){
				slayCounter[client] = 0;
				tkCounter[client] = 0;
				taCounter[client] = 0;
				kickCounter[client] = 0;
				// kick and ban by steamid
				if(g_ircRelay){
					ServerCommand("irc_showbans 0; wait");
					decl String:IrcMsg[1600];
					Format(IrcMsg,sizeof(IrcMsg),"\x02[ATAC]\x0F %T","IRC TK Ban",LANG_SERVER,clientName,SteamID);
					PrintToServer(IrcMsg);
					IrcMessage(CHAN_MASTER,IrcMsg);
				}
				ServerCommand("banid %d %s",BanTime,SteamID);
				ServerCommand("writeid");
				KickClient(client,"[ATAC] %T","You Were Banned",LANG_SERVER);
				if(g_ircRelay){
					ServerCommand("wait; irc_showbans 1");
				}
				// display to all players that the player was banned
				for(new i = 1; i <= GetMaxClients(); ++i){
					if(IsClientConnected(i) && IsClientInGame(i)){
						PrintToConsole(i,"[ATAC] %T","TK Ban",LANG_SERVER,clientName);
					}
				}
				PrintToChatAll("%c[ATAC]%c %T",GREEN,YELLOW,"TK Ban",LANG_SERVER,clientName);
				// log that the player was banned
				LogMessage("[ATAC] %T","TK Ban",LANG_SERVER,clientName);
				// reset the player's index values
				return true;
			}else{
				slayCounter[client] = 0;
				tkCounter[client] = 0;
				taCounter[client] = 0;
				// if the player wasn't going to be banned they'd be kicked
				KickClient(client,"[ATAC] %T","You Were Kicked",LANG_SERVER);
				if(g_ircRelay){
					decl String:IrcMsg[1600];
					Format(IrcMsg,sizeof(IrcMsg),"\x02[ATAC]\x0F %T","IRC TK Kick",LANG_SERVER,clientName,SteamID);
					PrintToServer(IrcMsg);
					IrcMessage(CHAN_MASTER,IrcMsg);
				}
				// tells everyone the player was kicked
				for(new i = 1; i <= GetMaxClients(); ++i){
					if(IsClientConnected(i) && IsClientInGame(i)){
						PrintToConsole(i,"[ATAC] %T","TK Kick",LANG_SERVER,clientName);
					}
				}
				PrintToChatAll("%c[ATAC]%c %T",GREEN,YELLOW,"TK Kick",LANG_SERVER,clientName);
				LogMessage("[ATAC] %T","TK Kick",LANG_SERVER,clientName);
				return true;
			}
		}
	}else if(ATACAction == 2){
		// don't allow the kick count to be higher than the kick limit
		if(kickCounter[client] > KickLimit){
			kickCounter[client] = KickLimit;
		}
		if(kickCounter[client] == KickLimit){
			slayCounter[client] = 0;
			tkCounter[client] = 0;
			taCounter[client] = 0;
			kickCounter[client] = 0;
			// kick and ban by steamid
			if(g_ircRelay){
				ServerCommand("irc_showbans 0; wait");
				decl String:IrcMsg[1600];
				Format(IrcMsg,sizeof(IrcMsg),"\x02[ATAC]\x0F %T","IRC TK Ban",LANG_SERVER,clientName,SteamID);
				PrintToServer(IrcMsg);
				IrcMessage(CHAN_MASTER,IrcMsg);
			}
			ServerCommand("banid %d %s kick",BanTime,SteamID);
			ServerCommand("writeid");
			KickClient(client,"[ATAC] %T","You Were Banned",LANG_SERVER);
			if(g_ircRelay){
				ServerCommand("wait; irc_showbans 1");
			}
			// display to all players that the player was banned
			for(new i = 1; i <= GetMaxClients(); ++i){
				if(IsClientConnected(i) && IsClientInGame(i)){
					PrintToConsole(i,"[ATAC] %T","TK Ban",LANG_SERVER,clientName);
				}
			}
			PrintToChatAll("%c[ATAC]%c %T",GREEN,YELLOW,"TK Ban",LANG_SERVER,clientName);
			// log that the player was banned
			LogMessage("[ATAC] %T","TK Ban",LANG_SERVER,clientName);
			// reset the player's index values
			return true;
		}
	}
	return false;
}
	
// actions taken when tk limit is reached
bool:TKAction(client){
	decl String:SteamID[64];
	decl String:clientName[64];
	// grab the cvar whether the next action will be taken
	new TakeNextAction = GetConVarInt(cvarATACTakeNextAction);
	// grab the cvar for the default tk limit action
	new tkaction = GetConVarInt(cvarATACAction);
	// get the player's steamid for kicking or banning
	GetClientAuthString(client,SteamID,64);
	// get the player's name for output later
	GetClientName(client,clientName,64);
	// make sure action is set
	if(tkaction != 0){
		// if action is one then slay
		if(tkaction == 1){
			// if the server is set to take the next action then do so
			if(TakeNextAction == 1){
				if(NextAction(client)){
					return true;
				}
			}
			// check if the player is currently living
			if(IsPlayerAlive(client)){
				// Create lightning and smoke effects
				SlayEffects(client);
				// force commit suicide
				ForcePlayerSuicide(client);
				// increate the slay counter
				slayCounter[client]++;
				// log the slay to the game server
				LogMessage("[ATAC] %T","Too Many TK Slay",LANG_SERVER,clientName);
				// tell everyone that the player was slain
				for(new i = 1; i <= GetMaxClients(); ++i){
					if(IsClientConnected(i) && IsClientInGame(i)){
						PrintToConsole(i,"[ATAC] %T","Too Many TK Slay",LANG_SERVER,clientName);
					}
				}
				PrintToChatAll("%c[ATAC]%c %T",GREEN,YELLOW,"Too Many TK Slay",LANG_SERVER,clientName);
				return true;
			}else{
				// if the player was not alive mark for slay the next time they spawn
				SlayNextSpawn[client] = true;
			}
		}
		// if the tk action is 2 then it kicks
		if(tkaction == 2){
			// increase the number of kicks
			kickCounter[client]++;
			// next action is set then it takes the next action
			if(TakeNextAction == 1){
				if(NextAction(client)){
					return true;
				}
			}
			if(IsClientConnected(client)){
				slayCounter[client] = 0;
				tkCounter[client] = 0;
				taCounter[client] = 0;
				// kicks the player
				KickClient(client,"[ATAC] %T","You Were Kicked",LANG_SERVER);
				if(g_ircRelay){
					decl String:IrcMsg[1600];
					Format(IrcMsg,sizeof(IrcMsg),"\x02[ATAC]\x0F %T","IRC TK Kick",LANG_SERVER,clientName,SteamID);
					PrintToServer(IrcMsg);
					IrcMessage(CHAN_MASTER,IrcMsg);
				}
				// tells everyone the player was kicked
				for(new i = 1; i <= GetMaxClients(); ++i){
					if(IsClientConnected(i) && IsClientInGame(i)){
						PrintToConsole(i,"[ATAC] %T","TK Kick",LANG_SERVER,clientName);
					}
				}
				PrintToChatAll("%c[ATAC]%c %T",GREEN,YELLOW,"TK Kick",LANG_SERVER,clientName);
				LogMessage("[ATAC] %T","TK Kick",LANG_SERVER,clientName);
			}
			return true;
		}
		// it action is set to 3 then bans
		if(tkaction == 3){
			// gets the ban time (minutes)
			new BanTime = GetConVarInt(cvarATACBanTime);
			// kick and ban by steamid
			if(g_ircRelay){
				ServerCommand("irc_showbans 0; wait");
				decl String:IrcMsg[1600];
				Format(IrcMsg,sizeof(IrcMsg),"\x02[ATAC]\x0F %T","IRC TK Ban",LANG_SERVER,clientName,SteamID);
				PrintToServer(IrcMsg);
				IrcMessage(CHAN_MASTER,IrcMsg);
			}
			ServerCommand("banid %d %s kick",BanTime,SteamID);
			ServerCommand("writeid");
			KickClient(client,"[ATAC] %T","You Were Banned",LANG_SERVER);
			if(g_ircRelay){
				ServerCommand("wait; irc_showbans 1");
			}
			// tells everyone the player was banned
			for(new i = 1; i <= GetMaxClients(); ++i){
				if(IsClientConnected(i) && IsClientInGame(i)){
					PrintToConsole(i,"[ATAC] %T","TK Ban",LANG_SERVER,clientName);
				}
			}
			PrintToChatAll("%c[ATAC]%c %T",GREEN,YELLOW,"TK Ban",LANG_SERVER,clientName);
			// log that the player was banned
			LogMessage("[ATAC] %T","TK Ban",LANG_SERVER,clientName);
			return true;
		}
	}
	return false;
}

// handles player hurt event
public ev_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast){
	// declares the victim and attacker's name strings
	decl String:victimName[64];
	decl String:attackerName[64];
	// gets the victim and attacker's userids
	new userid = GetEventInt(event,"userid");
	new userid2 = GetEventInt(event,"attacker");
	// gets the index of the victim and attacker based on their userids
	new victim = GetClientOfUserId(userid);
	new attacker = GetClientOfUserId(userid2);
	// if the player is a "legitimate" player
	if(attacker != 0 && victim != 0 && IsClientConnected(attacker) && IsClientConnected(victim) && victim != attacker){
		// get the ignorebots cvar
		new bool:IgnoreBots = GetConVarBool(cvarATACIgnoreBots);
		// if the ignorebots cvar is on then don't handle anything
		if(IgnoreBots){
			// make sure they're bots before not doing anything
			if(IsFakeClient(victim) || IsFakeClient(attacker)){
				return;
			}
		}
		// gets the time when the player is hurt and checks if it's under or equal to the cvar time
		new victimTeam = GetClientTeam(victim);
		new attackerTeam = GetClientTeam(attacker);
		//checks if the victim and attackers teams are the same
		if(victimTeam==attackerTeam){
			// get's the victim's and attacker's name
			GetClientName(victim,victimName,64);
			GetClientName(attacker,attackerName,64);
			// get's the maximum team attack count
			new taCount = GetConVarInt(cvarATACTACount);
			// if the maximum team attacks is set continue
			if(taCount > 0){
				new currentTime = GetTime();
				if(currentTime - g_DamageTime[attacker][victim] > 0){
					g_DamageTime[attacker][victim] = currentTime;
					// increase the team attack count
					taCounter[attacker]++;
					// if the team attack count is higher than the limit
					if(taCounter[attacker] > taCount){
						// force the team attack count to be equivelant to the limit
						taCounter[attacker] = taCount;
					}
					// tell everyone the player now has a certain number of team attacks out of the total
					for(new i = 1; i <= GetMaxClients(); ++i){
						if(IsClientConnected(i) && IsClientInGame(i)){
							PrintToConsole(i,"[ATAC] %T","Team Attack",LANG_SERVER,attackerName,taCounter[attacker],taCount);
						}
					}
					PrintToChatAll("%c[ATAC]%c %T",GREEN,YELLOW,"Team Attack",LANG_SERVER,attackerName,taCounter[attacker],taCount);
					LogMessage("[ATAC] %T","Team Attack",LANG_SERVER,attackerName,taCounter[attacker],taCount);
					// if the total team attacks is greater than the limit
					if(taCounter[attacker] == taCount){
						// increase the number of tk's
						tkCounter[attacker]++;
						// get the max tks
						new tkCount = GetConVarInt(cvarATACTKCount);
						// if the number of tk's is greater than the limit
						if(tkCounter[attacker] > tkCount){
							// force the number of tk's to be equivelant to the limit
							tkCounter[attacker] = tkCount;
						}
						// tell everyone the current number of tk's out of the maximum the player has
						for(new i = 1; i <= GetMaxClients(); ++i){
						if(IsClientConnected(i) && IsClientInGame(i)){
								PrintToConsole(i,"[ATAC] %T","Team Kill",LANG_SERVER,attackerName,tkCounter[attacker],tkCount);
							}
						}
						PrintToChatAll("%c[ATAC]%c %T",GREEN,YELLOW,"Team Kill",LANG_SERVER,attackerName,tkCounter[attacker],tkCount);
						LogMessage("[ATAC] %T","Team Attack",LANG_SERVER,attackerName,taCounter[attacker],taCount);
						// if the max tk's is set and the number of tk's is equal to or greater than the max tk's
						if(tkCount > 0 && tkCounter[attacker] == tkCount){
							// take action against the tk-er
							TKAction(attacker);
							// reset the tk counter to 0
							tkCounter[attacker] = 0;
						}
						// reset the ta counter to 0
						taCounter[attacker] = 0;
					}
				}
			}
			// this is for the spawn protection
			// get the spawn protection time cvar
			new ProtectTime = GetConVarInt(cvarATACProtectionTimer);
			// make sure the protection time cvar is set
			if(ProtectTime>0){
				// get the time of the attack
				new queryTime = GetTime();
				// if the difference of the time of the attack is less than or equal to the difference of the end of the
				// current time - the end of the freeze time and both players are valid players then take action
				if((queryTime-g_SpawnTime[victim])<=ProtectTime && IsClientConnected(attacker) && IsClientConnected(victim)){
					// create's the lightning effect
					SlayEffects(attacker);
					// forces attacker to commit suicide
					ForcePlayerSuicide(attacker);
					
					// get damage done to health and armor
					new healthDmg = GetEventInt(event,"dmg_health");
					
					// get current health and armor
					new currentHealth = GetClientHealth(victim);
					
					// fix health and armor
					new fixedHealth = currentHealth + healthDmg;
					
					// makes sure the final fixed health isn't above 100 HP
					if(fixedHealth > 100){
						// set's the player's health to 100
						SetClientHealth(victim,100);
					}else{
						// set's the player's health to the fixed value
						SetClientHealth(victim,fixedHealth);
					}
					
					// tell everyone that the player was slain for spawn attacking
					for(new i = 1; i <= GetMaxClients(); ++i){
						if(IsClientConnected(i) && IsClientInGame(i)){
							PrintToConsole(i,"[ATAC] %T","Spawn Attack",LANG_SERVER,attackerName,victimName);
						}
					}
					PrintToChatAll("%c[ATAC]%c %T",GREEN,YELLOW,"Spawn Attack",LANG_SERVER,attackerName,victimName);
					// Log that the player was slain for spawn attacking
					LogMessage("[ATAC] %T","Spawn Attack",LANG_SERVER,attackerName,victimName);
				}
			}
			// if mirror damage is on then continue
			if(GetConVarBool(cvarATACMirrorDamage)){
				// check how much damage was done
				new healthLoss = GetEventInt(event,"dmg_health");
				// checks if the heal mirror damage cvar is turned on
				if(GetConVarBool(cvarATACHealMirrorDamage)){
					// get the victim's current health
					new victimHealth = GetClientHealth(victim);
					// calculate the fixed health value of the victim
					new newVictimHealth = victimHealth + healthLoss;
					// if the victim's HP ends up greater than 100
					if(newVictimHealth > 100){
						// force 100 hp
						SetClientHealth(victim,100);
					}else{
						// otherwise set the hp accordingly
						SetClientHealth(victim,newVictimHealth);
					}
				}
				SlapPlayer(attacker,healthLoss);
			}
		}
	}
}

// handle the player's spawn event
public ev_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast){
	// get the spawned player's userid
	new userid = GetEventInt(event,"userid");
	// get the spawned player's index based on the userid
	new client = GetClientOfUserId(userid);
	new ProtectTime = GetConVarInt(cvarATACProtectionTimer);
	if(ProtectTime>0){
		g_SpawnTime[client] = GetTime();
	}
	new Float:DelayTime = GetConVarFloat(cvarATACNextSpawnPunishTime);
	g_SpawnPunishTimer[client] = CreateTimer(DelayTime,AfterSpawnPunish,client);
}

public Action:AfterSpawnPunish(Handle:timer,any:client){
	// declare the player name variable
	decl String:clientName[64];
	// make sure the client is not the server, is connected, and exists
	if(client != 0 && IsClientConnected(client) && IsClientInGame(client)){
		new tkCount = GetConVarInt(cvarATACTKCount);
		GetClientName(client,clientName,64);
		if(MenuSlayNextSpawn[client]){
			SlayEffects(client);
			ForcePlayerSuicide(client);
			for(new i = 1; i <= GetMaxClients(); ++i){
				if(IsClientConnected(i) && IsClientInGame(i)){
					PrintToConsole(i,"[ATAC] %T","Punish Slay",LANG_SERVER,clientName,tkCounter[client],tkCount);
				}
			}
			PrintToChatAll("%c[ATAC]%c %T",GREEN,YELLOW,"Punish Slay",LANG_SERVER,clientName,tkCounter[client],tkCount);
			MenuSlayNextSpawn[client] = false;
		}
		if(MenuSlapNextSpawn[client]){
			SlapPlayer(client,GetConVarInt(cvarATACMenuSlapDamage));
			for(new i = 1; i <= GetMaxClients(); ++i){
				if(IsClientConnected(i) && IsClientInGame(i)){
					PrintToConsole(i,"[ATAC] %T","Punish Slap",LANG_SERVER,clientName,tkCounter[client],tkCount);
				}
			}
			PrintToChatAll("%c[ATAC]%c %T",GREEN,YELLOW,"Punish Slap",LANG_SERVER,clientName,tkCounter[client],tkCount);
			MenuSlapNextSpawn[client] = false;
		}
		GetClientName(client,clientName,64);
		if(BurnNextSpawn[client]){
			IgniteEntity(client, 120.0, false, 10.0, false);
			//BurnPlayer(client);
			BurnNextSpawn[client] = false;
			// loop through and output to all players that the attacker was not forgiven
			for(new i = 1; i <= GetMaxClients(); ++i){
				if(IsClientConnected(i) && IsClientInGame(i)){
					PrintToConsole(i,"[ATAC] %T","Punish Burn",LANG_SERVER,clientName,tkCounter[client],tkCount);
				}
			}
			PrintToChatAll("%c[ATAC]%c %T",GREEN,YELLOW,"Punish Burn",LANG_SERVER,clientName,tkCounter[client],tkCount);
		}
		// check to see if the client is suppose to be frozen the next time they spawn
		if(FreezeNextSpawn[client]){
			for(new i = 1; i <= GetMaxClients(); ++i){
				FreezePlayer(client,i);
			}
			FreezeNextSpawn[client] = false;
			// loop through and output to all players that the attacker was not forgiven
			for(new i = 1; i <= GetMaxClients(); ++i){
				if(IsClientConnected(i) && IsClientInGame(i)){
					PrintToConsole(i,"[ATAC] %T","Punish Freeze",LANG_SERVER,clientName,tkCounter[client],tkCount);
				}
			}
			PrintToChatAll("%c[ATAC]%c %T",GREEN,YELLOW,"Punish Freeze",LANG_SERVER,clientName,tkCounter[client],tkCount);
		}
		for(new i = 1; i <= GetMaxClients(); ++i){
			if(IsClientConnected(i) && IsClientInGame(i)){
				if(BeingUberSlapped[client][i]){
					BeingUberSlapped[client][i] = false;
					CloseHandle(UberSlapTime[client][i]);
				}
				if(IsValidHandle(UberSlapTime[client][i])){
					CloseHandle(UberSlapTime[client][i]);
				}
				if(IsValidHandle(FreezeTime[client][i])){
					CloseHandle(FreezeTime[client][i]);
				}
			}
		}
		if(UberSlapNextSpawn[client]){
			UberSlapNextSpawn[client] = false;
			for(new i = 1; i <= GetMaxClients(); ++i){
				UberSlap(client,i);
			}
			for(new i = 1; i <= GetMaxClients(); ++i){
				if(IsClientConnected(i) && IsClientInGame(i)){
					PrintToConsole(i,"[ATAC] %T","Punish UberSlap",LANG_SERVER,clientName,tkCounter[client],tkCount);
				}
			}
			PrintToChatAll("%c[ATAC]%c %T",GREEN,YELLOW,"Punish UberSlap",LANG_SERVER,clientName,tkCounter[client],tkCount);
		}
		// check to see if the client was flagged to be slain the the next time they spawn
		if(SlayNextSpawn[client]){
			// create lightning effect
			SlayEffects(client);
			// force the client to be slain
			ForcePlayerSuicide(client);
			// increase the slay count
			slayCounter[client]++;
			// reset the slay next roud
			SlayNextSpawn[client] = false;
			// tell everyong the player was slain and why
			LogMessage("[ATAC] %T","Too Many TK Slay",LANG_SERVER,clientName);
			// tell everyone that the player was slain
			for(new i = 1; i <= GetMaxClients(); ++i){
				if(IsClientConnected(i) && IsClientInGame(i)){
					PrintToConsole(i,"[ATAC] %T","Too Many TK Slay",LANG_SERVER,clientName);
				}
			}
			PrintToChatAll("%c[ATAC]%c %T",GREEN,YELLOW,"Too Many TK Slay",LANG_SERVER,clientName);
		}
	}
}
// handle's the player_death event
public ev_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast){
	// declare the variables for attacker name and victim name
	decl String:victimName[64];
	decl String:attackerName[64];
	// get the attacker and victim's userid
	new userid = GetEventInt(event,"userid");
	new userid2 = GetEventInt(event,"attacker");
	// get the index of the victim and the attacker based on the userid
	new victim = GetClientOfUserId(userid);
	new attacker = GetClientOfUserId(userid2);
	if(IsValidHandle(g_SpawnPunishTimer[victim])){
		CloseHandle(g_SpawnPunishTimer[victim]);
	}
	for(new i = 1; i <= GetMaxClients(); ++i){
		if(BeingUberSlapped[victim][i]){
			BeingUberSlapped[victim][i] = false;
		}
		if(IsValidHandle(UberSlapTime[victim][i])){
			CloseHandle(UberSlapTime[victim][i]);
		}
		if(IsValidHandle(FreezeTime[victim][i])){
			CloseHandle(FreezeTime[victim][i]);
		}
	}
	if(IsFrozen[victim]){
		IsFrozen[victim] = false;
	}
	// if the attacker and the victim are both real, both connected, and are not the same person then continue
	if(attacker != 0 && victim != 0 && IsClientConnected(attacker) && IsClientConnected(victim) && victim != attacker){
		// gets the ignorebots cvar
		new bool:IgnoreBots = GetConVarBool(cvarATACIgnoreBots);
		// if ignorebots is on continue
		if(IgnoreBots){
			// make sure at least one of the players is a bot
			if(IsFakeClient(victim) || IsFakeClient(attacker)){
				// ignore anything that happens below if either player is a bot
				return;
			}
		}
		// get's the team of the victim and the attacker
		new victimTeam = GetClientTeam(victim);
		new attackerTeam = GetClientTeam(attacker);
		//checks if the victim and attackers teams are the same
		if(victimTeam==attackerTeam){
			// get the names of the victim and attacker
			GetClientName(victim,victimName,64);
			GetClientName(attacker,attackerName,64);
			// sets the victim as being killed by the attacker
			killed[attacker][victim] = true;
			// tells the victim who they were killed by
			PrintToConsole(victim,"[ATAC] %T","You Were Team Killed",LANG_SERVER,attackerName);
			PrintToChat(victim,"%c[ATAC]%c %T",GREEN,YELLOW,"You Were Team Killed",LANG_SERVER,attackerName);
			// if the menu is disabled shows the necessary action for forgiveness
			if(GetConVarInt(cvarATACMenuForgive) != 1){
				// if defaultpunish is set or not display proper message
				// gets the defaultpunish cvar
				new bool:DoNotForgive = GetConVarBool(cvarATACDefaultForgive);
				if(DoNotForgive){
					PrintToChat(victim,"%c[ATAC]%c %T",GREEN,YELLOW,"Type Forgive",LANG_SERVER,GREEN,YELLOW,GREEN,YELLOW,GREEN,YELLOW);
				}else if(!DoNotForgive){
					PrintToChat(victim,"%c[ATAC]%c %T",GREEN,YELLOW,"Type Punish",LANG_SERVER,GREEN,YELLOW,GREEN,YELLOW,GREEN,YELLOW);
				}
				// grabs the cvar for the timer before forgiveness or not is taken care of
				new Float:Timer = GetConVarFloat(cvarATACForgiveTimer);
				// grabs the time of death for a global variable
				TimeOfDeath = GetTime();
				// creates the timer based on the victim
				ForgiveTimer[victim] = CreateTimer(Timer,ForgiveTimeUp);
			}
			ForgiveMenu(victim,attacker,attackerName);
		}
		// BEGIN MOD BY LAMDACORE
		else if (tkCounter[attacker] > 0)
		{
			new karmaCount = GetConVarInt(cvarATACKarmaCount);
			++karmaCounter[attacker];
			if (karmaCount > 0 && karmaCounter[attacker] >= karmaCount)
			{
				new tkCount = GetConVarInt(cvarATACTKCount);
				--tkCounter[attacker];
				karmaCounter[attacker] = 0;
				for(new i = 1; i <= GetMaxClients(); ++i)
				{
                       	        	if(IsClientConnected(i) && IsClientInGame(i))
					{
						PrintToConsole(i,"[ATAC] %s plays well and now has %d/%d team kills.",attackerName,tkCounter[attacker],tkCount);
              				}
				}
				PrintToChatAll("%c[ATAC]%c %s plays well and now has %d/%d team kills.",GREEN,YELLOW,attackerName,tkCounter[attacker],tkCount);
			}
		}
		// END MOD BY LAMDACORE
	}
}

public OnConfigsExecuted(){
	new bool:menuOn = GetConVarBool(cvarATACMenuForgive);
	if(menuOn){
		// creates the menu
		atacMenu = CreateMenu(MenuSelected);
		atacImmuneMenu = CreateMenu(MenuSelected);
		//	if the menu has an exit button remove it
		SetMenuExitButton(atacMenu,false);
		CreateATACMenu();
		CreateATACImmuneMenu();
	}
	g_ircRelay = GetConVarBool(cvarATACIrcRelay);
}

CreateATACImmuneMenu(){
	// add's forgive and punish options
	decl String:StrForgive[100];
	decl String:StrNotForgive[100];
	Format(StrForgive,sizeof(StrForgive),"%T","Menu Forgive",LANG_SERVER);
	AddMenuItem(atacImmuneMenu,"Forgive",StrForgive);
	Format(StrNotForgive,sizeof(StrNotForgive),"%T","Menu Do Not Forgive",LANG_SERVER);
	AddMenuItem(atacImmuneMenu,"Punish",StrNotForgive);
}

CreateATACMenu(){
	// add punishment options
	decl String:StrForgive[100];
	decl String:StrNotForgive[100];
	
	Format(StrForgive,sizeof(StrForgive),"%T","Menu Forgive",LANG_SERVER);
	AddMenuItem(atacMenu,"Forgive",StrForgive);
	
	Format(StrNotForgive,sizeof(StrNotForgive),"%T","Menu Do Not Forgive",LANG_SERVER);
	AddMenuItem(atacMenu,"Punish",StrNotForgive);
	
	if(GetConVarInt(cvarATACMenuSlay) == 1){
		decl String:StrSlay[100];
		Format(StrSlay,sizeof(StrSlay),"%T","Menu Slay",LANG_SERVER);
		AddMenuItem(atacMenu,"Slay",StrSlay);
	}
	new SlapDamage = GetConVarInt(cvarATACMenuSlapDamage);
	if(SlapDamage > 0){
		decl String:StrSlap[256];
		Format(StrSlap,sizeof(StrSlap),"%T","Menu Slap",LANG_SERVER,SlapDamage);
		AddMenuItem(atacMenu,"SlapDmg",StrSlap);
	}
	if(GetConVarInt(cvarATACMenuUberSlap) == 1){
		decl String:StrUberSlap[100];
		Format(StrUberSlap,sizeof(StrUberSlap),"%T","Menu UberSlap",LANG_SERVER);
		AddMenuItem(atacMenu,"UberSlap",StrUberSlap);
	}
	if(GetConVarInt(cvarATACMenuBurn) == 1){
		decl String:StrBurn[100];
		Format(StrBurn,sizeof(StrBurn),"%T","Menu Burn",LANG_SERVER);
		AddMenuItem(atacMenu,"Burn",StrBurn);
	}
	if(GetConVarInt(cvarATACMenuFreeze) == 1){
		decl String:StrFreeze[100];
		Format(StrFreeze,sizeof(StrFreeze),"%T","Menu Freeze",LANG_SERVER);
		AddMenuItem(atacMenu,"Freeze",StrFreeze);
	}
}

public Action:ForgiveMenu(victim,attacker,const String:attackerName[64]){
	// Check if the admin immunity is turned on
	if(GetConVarBool(cvarATACAdminImmunity)){
		// make sure the admin is not an invalid admin
		if(GetUserAdmin(attacker) != INVALID_ADMIN_ID){
			// define the variable for the admin group
			decl String:AdminGroup[255];
			// get the admin groupid
			new GroupId:Group = GetAdminGroup(GetUserAdmin(attacker),GetAdminGroupCount(GetUserAdmin(attacker)),AdminGroup,sizeof(AdminGroup));
			// check whether globalimmunity is turned on
			if(GetConVarBool(cvarATACGlobalImmunity)){
				// check if the group has global immunity
				if(GetAdmGroupImmunity(Group,Immunity_Global)){
					// sets the menu title
					SetMenuTitle(atacImmuneMenu,"[ATAC] %T","You Were Team Killed",LANG_SERVER,attackerName);
					// displays the menu for immune admins (Forgive or Not Forgive options only)
					DisplayMenu(atacImmuneMenu,victim,MENU_TIME_FOREVER);
				}else{
					// display the message that you have been team killed by a player as the title
					SetMenuTitle(atacMenu,"[ATAC] %T","You Were Team Killed",LANG_SERVER,attackerName);
					// display the menu to the killed player
					DisplayMenu(atacMenu,victim,MENU_TIME_FOREVER);
				}
				// check if global immunity is off
			}
			if(!GetConVarBool(cvarATACGlobalImmunity)){
				// check for default immunity
				if(GetAdmGroupImmunity(Group,Immunity_Default)){
					// set menu title
					SetMenuTitle(atacImmuneMenu,"[ATAC] %T","You Were Team Killed",LANG_SERVER,attackerName);
					DisplayMenu(atacImmuneMenu,victim,MENU_TIME_FOREVER);
				}else{
					// display the message that you have been team killed by a player as the title
					SetMenuTitle(atacMenu,"[ATAC] %T","You Were Team Killed",LANG_SERVER,attackerName);
					// display the menu to the killed player
					DisplayMenu(atacMenu,victim,MENU_TIME_FOREVER);
				}
			}
		}else{
			// display the message that you have been team killed by a player as the title
			SetMenuTitle(atacMenu,"[ATAC] %T","You Were Team Killed",LANG_SERVER,attackerName);
			// display the menu to the killed player
			DisplayMenu(atacMenu,victim,MENU_TIME_FOREVER);
		}
	}else{
		// display the message that you have been team killed by a player as the title
		SetMenuTitle(atacMenu,"[ATAC] %T","You Were Team Killed",LANG_SERVER,attackerName);
		// display the menu to the killed player
		DisplayMenu(atacMenu,victim,MENU_TIME_FOREVER);
	}
}

public MenuSelected(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select){
		decl String:SelectionInfo[64];
		decl String:SelectionDispText[256];
		new SelectionStyle;
		GetMenuItem(menu,param2,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
		decl String:clientName[64];
		decl String:attackerName[64];
		GetClientName(param1,clientName,64);
		if(strcmp(SelectionInfo,"Forgive") == 0){
			// loop through all the players in the server
			for(new i = 1; i <= GetMaxClients(); ++i){
				// if the client being forgiven is both in the server, and killed the person forgiving take the next step
				if(IsClientConnected(i) && IsClientInGame(i) && killed[i][param1] && i != 0){
					GetClientName(i,attackerName,64);
					killed[i][param1] = false;
					// output to all players that the TK has been forgiven
					for(new players = 1; players <= GetMaxClients(); ++players){
						if(IsClientConnected(players) && IsClientInGame(players)){
							PrintToConsole(players,"[ATAC] %T","Forgiven",LANG_SERVER,clientName,attackerName);
						}
					}
					PrintToChatAll("%c[ATAC]%c %T",GREEN,YELLOW,"Forgiven",LANG_SERVER,clientName,attackerName);
				}
			}
		}
		if(strcmp(SelectionInfo,"Punish") == 0){
			new tkCount = GetConVarInt(cvarATACTKCount);
			// loop through all players
			for(new attacker = 1; attacker <= GetMaxClients(); ++ attacker){
				if(IsClientConnected(attacker) && IsClientInGame(attacker) && killed[attacker][param1] && attacker != 0){
					GetClientName(attacker,attackerName,64);
					tkCounter[attacker]++;
					// if the maximum tk's isset
					// and the number of TK's is greater than or equal to the maximum
					// then take next action
					if(tkCount > 0 && tkCounter[attacker] >= tkCount){
					// call the subroutine that takes action when the tkcount has been reached
						if(TKAction(attacker)){
							return;
						}
						// reset the number of tk's
						tkCounter[attacker] = 0;
						// reset that the player tk'd was tk'd by this person
						killed[attacker][param1] = false;
					}else{
						// even if the tkcount is not higher than or equal to the maximum tks
						// the attacker tk-ing the client gets reset
						killed[attacker][param1] = false;
					}
					// loop through and output to all players that the attacker was not forgiven
					for(new i = 1; i <= GetMaxClients(); ++i){
						if(IsClientConnected(i) && IsClientInGame(i)){
							PrintToConsole(i,"[ATAC] %T","Not Forgiven",LANG_SERVER,attackerName,tkCounter[attacker],tkCount);
						}
					}
					PrintToChatAll("%c[ATAC]%c %T",GREEN,YELLOW,"Not Forgiven",LANG_SERVER,attackerName,tkCounter[attacker],tkCount);
				}
			}
		}
		if(strcmp(SelectionInfo,"Slay") == 0){
			new tkCount = GetConVarInt(cvarATACTKCount);
			// loop through all players
			for(new attacker = 1; attacker <= GetMaxClients(); ++ attacker){
				if(IsClientConnected(attacker) && IsClientInGame(attacker) && killed[attacker][param1] && attacker != 0){
					GetClientName(attacker,attackerName,64);
					tkCounter[attacker]++;
					// if the maximum tk's isset
					// and the number of TK's is greater than or equal to the maximum
					// then take next action
					if(tkCount > 0 && tkCounter[attacker] >= tkCount){
					// call the subroutine that takes action when the tkcount has been reached
						if(TKAction(attacker)){
							return;
						}
						// reset the number of tk's
						tkCounter[attacker] = 0;
						// reset that the player tk'd was tk'd by this person
						killed[attacker][param1] = false;
					}else{
						// even if the tkcount is not higher than or equal to the maximum tks
						// the attacker tk-ing the client gets reset
						killed[attacker][param1] = false;
					}
					if(!IsPlayerAlive(attacker)){
						MenuSlayNextSpawn[attacker] = true;
						PrintToConsole(param1,"[ATAC] %T","Slay Next Spawn",LANG_SERVER,attackerName);
						PrintToChat(param1,"%c[ATAC]%c %T",GREEN,YELLOW,"Slay Next Spawn",LANG_SERVER,attackerName);
						return;
					}
					SlayEffects(attacker);
					ForcePlayerSuicide(attacker);
					// loop through and output to all players that the attacker was not forgiven
					for(new i = 1; i <= GetMaxClients(); ++i){
						if(IsClientConnected(i) && IsClientInGame(i)){
							PrintToConsole(i,"[ATAC] %T","Punish Slay",LANG_SERVER,attackerName,tkCounter[attacker],tkCount);
						}
					}
					PrintToChatAll("%c[ATAC]%c %T",GREEN,YELLOW,"Punish Slay",LANG_SERVER,attackerName,tkCounter[attacker],tkCount);
				}
			}
		}
		if(strcmp(SelectionInfo,"SlapDmg") == 0){
			new tkCount = GetConVarInt(cvarATACTKCount);
			// loop through all players
			for(new attacker = 1; attacker <= GetMaxClients(); ++ attacker){
				if(IsClientConnected(attacker) && IsClientInGame(attacker) && killed[attacker][param1] && attacker != 0){
					GetClientName(attacker,attackerName,64);
					tkCounter[attacker]++;
					// if the maximum tk's isset
					// and the number of TK's is greater than or equal to the maximum
					// then take next action
					if(tkCount > 0 && tkCounter[attacker] >= tkCount){
					// call the subroutine that takes action when the tkcount has been reached
						if(TKAction(attacker)){
							return;
						}
						// reset the number of tk's
						tkCounter[attacker] = 0;
						// reset that the player tk'd was tk'd by this person
						killed[attacker][param1] = false;
					}else{
						// even if the tkcount is not higher than or equal to the maximum tks
						// the attacker tk-ing the client gets reset
						killed[attacker][param1] = false;
					}
					if(!IsPlayerAlive(attacker)){
						MenuSlapNextSpawn[attacker] = true;
						PrintToConsole(param1,"[ATAC] %T","Slap Next Spawn",LANG_SERVER,attackerName);
						PrintToChat(param1,"%c[ATAC]%c %T",GREEN,YELLOW,"Slap Next Spawn",LANG_SERVER,attackerName);
						return;
					}
					SlapPlayer(attacker,GetConVarInt(cvarATACMenuSlapDamage));
					// loop through and output to all players that the attacker was not forgiven
					for(new i = 1; i <= GetMaxClients(); ++i){
						if(IsClientConnected(i) && IsClientInGame(i)){
							PrintToConsole(i,"[ATAC] %T","Punish Slap",LANG_SERVER,attackerName,tkCounter[attacker],tkCount);
						}
					}
					PrintToChatAll("%c[ATAC]%c %T",GREEN,YELLOW,"Punish Slap",LANG_SERVER,attackerName,tkCounter[attacker],tkCount);
				}
			}
		}
		if(strcmp(SelectionInfo,"UberSlap") == 0){
			new tkCount = GetConVarInt(cvarATACTKCount);
			// loop through all players
			for(new attacker = 1; attacker <= GetMaxClients(); ++ attacker){
				if(IsClientConnected(attacker) && IsClientInGame(attacker) && killed[attacker][param1] && attacker != 0){
					GetClientName(attacker,attackerName,64);
					tkCounter[attacker]++;
					// if the maximum tk's isset
					// and the number of TK's is greater than or equal to the maximum
					// then take next action
					if(tkCount > 0 && tkCounter[attacker] >= tkCount){
					// call the subroutine that takes action when the tkcount has been reached
						if(TKAction(attacker)){
							return;
						}
						// reset the number of tk's
						tkCounter[attacker] = 0;
						// reset that the player tk'd was tk'd by this person
						killed[attacker][param1] = false;
					}else{
						// even if the tkcount is not higher than or equal to the maximum tks
						// the attacker tk-ing the client gets reset
						killed[attacker][param1] = false;
					}
					if(!IsPlayerAlive(attacker)){
						UberSlapNextSpawn[attacker] = true;
						PrintToConsole(param1,"[ATAC] %T","UberSlap Next Spawn",LANG_SERVER,attackerName);
						PrintToChat(param1,"%c[ATAC]%c %T",GREEN,YELLOW,"UberSlap Next Spawn",LANG_SERVER,attackerName);
						return;
					}
					UberSlap(attacker,param1);
					// loop through and output to all players that the attacker was not forgiven
					for(new i = 1; i <= GetMaxClients(); ++i){
						if(IsClientConnected(i) && IsClientInGame(i)){
							PrintToConsole(i,"[ATAC] %T","Punish UberSlap",LANG_SERVER,attackerName,tkCounter[attacker],tkCount);
						}
					}
					PrintToChatAll("%c[ATAC]%c %T",GREEN,YELLOW,"Punish UberSlap",LANG_SERVER,attackerName,tkCounter[attacker],tkCount);
				}
			}
		}
		if(strcmp(SelectionInfo,"Burn") == 0){
			new tkCount = GetConVarInt(cvarATACTKCount);
			// loop through all players
			for(new attacker = 1; attacker <= GetMaxClients(); ++ attacker){
				if(IsClientConnected(attacker) && IsClientInGame(attacker) && killed[attacker][param1] && attacker != 0){
					GetClientName(attacker,attackerName,64);
					tkCounter[attacker]++;
					// if the maximum tk's isset
					// and the number of TK's is greater than or equal to the maximum
					// then take next action
					if(tkCount > 0 && tkCounter[attacker] >= tkCount){
					// call the subroutine that takes action when the tkcount has been reached
						if(TKAction(attacker)){
							return;
						}
						// reset the number of tk's
						tkCounter[attacker] = 0;
						// reset that the player tk'd was tk'd by this person
						killed[attacker][param1] = false;
					}else{
						// even if the tkcount is not higher than or equal to the maximum tks
						// the attacker tk-ing the client gets reset
						killed[attacker][param1] = false;
					}
					if(!IsPlayerAlive(attacker)){
						BurnNextSpawn[attacker] = true;
						PrintToConsole(param1,"[ATAC] %T","Burn Next Spawn",LANG_SERVER,attackerName);
						PrintToChat(param1,"%c[ATAC]%c %T",GREEN,YELLOW,"Burn Next Spawn",LANG_SERVER,attackerName);
						return;
					}
					IgniteEntity(attacker, 120.0, false, 10.0, false);
					//BurnPlayer(attacker);
					// loop through and output to all players that the attacker was not forgiven
					for(new i = 1; i <= GetMaxClients(); ++i){
						if(IsClientConnected(i) && IsClientInGame(i)){
							PrintToConsole(i,"[ATAC] %T","Punish Burn",LANG_SERVER,attackerName,tkCounter[attacker],tkCount);
						}
					}
					PrintToChatAll("%c[ATAC]%c %T",GREEN,YELLOW,"Punish Burn",LANG_SERVER,attackerName,tkCounter[attacker],tkCount);
				}
			}
		}
		if(strcmp(SelectionInfo,"Freeze") == 0){
			new tkCount = GetConVarInt(cvarATACTKCount);
			// loop through all players
			for(new attacker = 1; attacker <= GetMaxClients(); ++ attacker){
				if(IsClientConnected(attacker) && IsClientInGame(attacker) && killed[attacker][param1] && attacker != 0){
					GetClientName(attacker,attackerName,64);
					tkCounter[attacker]++;
					// if the maximum tk's isset
					// and the number of TK's is greater than or equal to the maximum
					// then take next action
					if(tkCount > 0 && tkCounter[attacker] >= tkCount){
					// call the subroutine that takes action when the tkcount has been reached
						if(TKAction(attacker)){
							return;
						}
						// reset the number of tk's
						tkCounter[attacker] = 0;
						// reset that the player tk'd was tk'd by this person
						killed[attacker][param1] = false;
					}else{
						// even if the tkcount is not higher than or equal to the maximum tks
						// the attacker tk-ing the client gets reset
						killed[attacker][param1] = false;
					}
					if(!IsPlayerAlive(attacker)){
						FreezeNextSpawn[attacker] = true;
						PrintToConsole(param1,"[ATAC] %T","Freeze Next Spawn",LANG_SERVER,attackerName);
						PrintToChat(param1,"%c[ATAC]%c %T",GREEN,YELLOW,"Freeze Next Spawn",LANG_SERVER,attackerName);
						return;
					}
					FreezePlayer(attacker,param1);
					// loop through and output to all players that the attacker was not forgiven
					for(new i = 1; i <= GetMaxClients(); ++i){
				if(IsClientConnected(i) && IsClientInGame(i)){
							PrintToConsole(i,"[ATAC] %T","Punish Freeze",LANG_SERVER,attackerName,tkCounter[attacker],tkCount);
						}
					}
					PrintToChatAll("%c[ATAC]%c %T",GREEN,YELLOW,"Punish Freeze",LANG_SERVER,attackerName,tkCounter[attacker],tkCount);
				}
			}
		}
	}
}

public FreezePlayer(client,victim){
	new Float:playerpos[3];
	GetClientAbsOrigin(client,playerpos);
	EmitAmbientSound("ambient/atmosphere/terrain_rumble1.wav", playerpos, SOUND_FROM_WORLD, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, 0.0);
	new fFlagsOffset = FindDataMapOffs(client,"m_fFlags");
	new fFlags = GetEntData(client,fFlagsOffset);
	SetEntData(client,fFlagsOffset,fFlags |= (1<<5),true);
	SetEntData(client,g_MoveTypeOffset,0,true);
	IsFrozen[client] = true;
	FreezeTime[client][victim] = CreateTimer(0.1,FreezeTimer,client,TIMER_REPEAT);
}

public Action:FreezeTimer(Handle:timer,any:client)
{
	FreezeBeam(client);
}

UberSlap(client,victim){
	UberSlapTime[client][victim] = CreateTimer(0.1,UberSlapTimer,client,TIMER_REPEAT);
	BeingUberSlapped[client][victim] = true;
}

public Action:UberSlapTimer(Handle:timer, any:client){
	Lightning(client);
	SlapPlayer(client,1);
}

// once the forgive timer is up it takes the following action
public Action:ForgiveTimeUp(Handle:timer){
	// gets the time when the timer is up
	new timerTime = GetTime();
	// gets the cvar of the forgive timer
	new Timer = GetConVarInt(cvarATACForgiveTimer);
	// calculates the difference between the time of death and the timer's time
	new TimeCalc = timerTime - TimeOfDeath;
	// if the difference is greater than or equal to the cvar value then
	if(TimeCalc >= Timer){
		// get the maximum tk count
		new tkCount = GetConVarInt(cvarATACTKCount);
		// get the cvar for defaultpunish
		new bool:DoNotForgive = GetConVarBool(cvarATACDefaultForgive);
		// loop through every possible attacker of the victim(client)
		for(new attacker = 1; attacker <= GetMaxClients(); ++attacker){
			// define the attacker name string
			decl String:attackerName[64];
			// make sure the attacker is connected and is not the server
			if(IsClientConnected(attacker) && attacker != 0){
				// get's the attacker's name
				GetClientName(attacker,attackerName,64);
				// loops through the possible victims
				for(new victim = 1; victim <= GetMaxClients(); ++victim){
					// makes sure the victim is connected, was killed by the attacker, and is not the server
					if(IsClientConnected(victim) && killed[attacker][victim] && victim != 0){
						// if default punish is on continue
						if(DoNotForgive){
							// increase the number of tk's
							tkCounter[attacker]++;
							// force the tkCounter to be equal to the maximum if it's higher
							if(tkCounter[attacker] > tkCount){
								tkCounter[attacker] = tkCount;
							}
							// tell everyone that the player was not forgiven and now has a team kill on their hands
							for(new i = 1; i <= GetMaxClients(); ++i){
								if(IsClientConnected(i) && IsClientInGame(i)){
									PrintToConsole(i,"[ATAC] %T","Not Forgiven",LANG_SERVER,attackerName,tkCounter[attacker],tkCount);
								}
							}
							PrintToChatAll("%c[ATAC]%c %T",GREEN,YELLOW,"Not Forgiven",LANG_SERVER,attackerName,tkCounter[attacker],tkCount);
							// if the maximum tks is set and the count of tk's is greater than or equal to that
							if(tkCount > 0 && tkCounter[attacker] >= tkCount){
								// take action against the tk-er
								TKAction(attacker);
								// reset the tk count
								tkCounter[attacker] = 0;
								// mark that the victim is no longer "team killed"
								killed[attacker][victim] = false;
							}else{
								// mark that the victim is no longer "team killed"
								killed[attacker][victim] = false;
							}
							//if defaultpunish is 0 then do the following
						}else{
							new String:victimName[64];
							GetClientName(victim,victimName,64);
							// tell everyone that the attacker was forgiven
							for(new players = 1; players <= GetMaxClients(); ++players){
								if(IsClientConnected(players) && IsClientInGame(players)){
									PrintToConsole(players,"[ATAC] %T","Forgiven",LANG_SERVER,victimName,attackerName);
								}
							}
							PrintToChatAll("%c[ATAC]%c %T",GREEN,YELLOW,"Forgiven",LANG_SERVER,victimName,attackerName);
							// mark the victim as no longer "killed" by the attacker
							killed[attacker][victim] = false;
						}
					}
				}
			}
		}
	}
}