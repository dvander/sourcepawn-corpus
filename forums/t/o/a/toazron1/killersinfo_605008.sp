/*	This is based loosely off of the now unsupported plugin hp_left(http://forums.alliedmods.net/showthread.php?t=57735) by TSCDan. 
*	Being written for CS:S severely limited it on our TF2 server and since I was looking for something closer to my Natural Selection plugin (http://www.nsmod.org/forums/index.php?showtopic=9663)
*	I used hp_left as a starting point to get me into TF2 and SM development, however the only thing that still remains the original code is the distance check. (now defunct)
* 
*	 Change log:
* 		0.1 - cleaned up unused code... recoded functions. fixed TF2 specific events, output looks better.
* 		0.2 - fixed distance (stupid error)
* 		0.3 - fix colors / fixed customkill check. Spelling errors on weapons (lol).
* 		0.4 - Killer already dead check to fix weird outputs
* 		0.5	- ability to disable output
* 		0.6 - merged changes for output saving (thanks urus)
* 		0.7	- better distance check, metric option
* 		0.8 - cleaned up some more code - added assist info
* 		0.8.1 - Medic/Pyro update support
* 		0.8.2 - Heavy update support - HUMILIATION
* 		0.8.3 - Merged multi-lang support (thanks Vader_666). Optimized.
* 		0.8.3a - Fixed a define I forgot to include :)
* 		0.8.4 - Added "finished off", minor optimizations
* 		0.8.5 - Reworked if elses, removed useless weapon loop, added humiliation
* 		0.9.0 - Scout update, crit alert, sentry levels
* 		1.0.0 - Spy/ Sniper update - updated for deathflag changes
* 		1.0.1 - Added crit in the output (thanks psychonic) fixed more Spy/Sniper update weapon changes
* 		1.0.2 - Updated translations - cleaned up code
* 		1.1.0 - Logic rework. Mini crits.  Removed assist/distance.  Colors.ini needed.  ClientPref storage rather than KV file.
* 		1.1.1 - Removed need for Colors.ini to fix format error. Easier to change colors (defines at the top)
* 		1.1.2 - Minor formatting fixes.
* 		1.2.0 - Reworked/cleaned up/updated translations.  Now using AddCommandListener. Support for colors :). Revenge notification.
* 		1.2.1 - Fixed minor error. Cleaned up again. Translations.
* 		1.2.2 - I'm dumb.
* 		1.3.0 - Polycount translations, added more customkill checks, using SM constants, code optimizations
* 		1.3.1 - Fixed potential clientpref error.
* 		1.4.0 - Check for translation errors and logging for missing weapon names
* 		1.4.1 - Minor optimizaion - log file error checking
*/

#include <sourcemod>
#include <clientprefs>
#include <tf2_stocks>

#pragma semicolon 1

/*
* Uncomment for color support in the chat messages.
*/
//#define USECOLORS	

/*
* Uncomment to enable logging of missing weapon translations.
* Make sure that LOG_WEAPON_ERRORS_FILE exists or plugin will fail to load.
*/
//#define LOG_WEAPON_ERRORS
#define LOG_WEAPON_ERRORS_FILE	"logs/weapon_errors.txt"

#if defined USECOLORS
#include <colors>
#endif

#define VERSION "1.4.1"

#define TF2_DAMAGEBIT_CRITS	(1<<20)		/* From SDK - DAMAGE_ACID (1048576) */

new g_bShowOutput[MAXPLAYERS + 1];

#if defined LOG_WEAPON_ERRORS
new String:g_szLogFile[128];
#endif

new Handle:g_hCvarDefaultSetting = INVALID_HANDLE;
new Handle:g_hCookie = INVALID_HANDLE;
new Handle:g_hKeyValues = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "TF2: Killer's Info",
	author = "Nut",
	description = "Shows the victim information about their killer.",
	version = VERSION,
	url = ""
}

public OnPluginStart()
{
	CreateConVar("sm_ki_version", VERSION, "TF2: Killer's Info", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	AddCommandListener(SayCallback, "sm_ki_toggle");
	HookEvent("player_death", event_player_death, EventHookMode_Post);
	LoadTranslations("killersinfo.phrases");
	
	g_hCvarDefaultSetting = CreateConVar("sm_ki_default", "1", "default output setting for new players");
	g_hCookie = RegClientCookie("killersinfo_display", "Shows info about your killing when you get killed.", CookieAccess_Public);
	
	g_hKeyValues = CreateKeyValues("Phrases");
	decl String:szBuffer[255];
	
	/*
	* Loads the translation file into a keyvalue - easy way to check if a weapon exists (no need for file check - plugin fails if translation file is not found)
	*/
	BuildPath(Path_SM, szBuffer, sizeof(szBuffer), "translations/killersinfo.phrases.txt");
	FileToKeyValues(g_hKeyValues, szBuffer);
	
	#if defined LOG_WEAPON_ERRORS
	BuildPath(Path_SM, g_szLogFile, sizeof(g_szLogFile), LOG_WEAPON_ERRORS_FILE);
	if (!FileExists(g_szLogFile))
		SetFailState("Weapon log file missing (%s)", g_szLogFile);		
	#endif
}

public OnClientPostAdminCheck(iClient)
{
	if (!IsClientInGame(iClient)) return;
	if (AreClientCookiesCached(iClient))
	{
		new String:szBuffer[2];
		GetClientCookie(iClient, g_hCookie, szBuffer, sizeof(szBuffer));
		if (strlen(szBuffer) < 1)	/* Cookie doesn't exist so set the bool to the cvar default */
			g_bShowOutput[iClient] = GetConVarInt(g_hCvarDefaultSetting);
		else
			g_bShowOutput[iClient] = StringToInt(szBuffer);
	}
}

public Action:event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iVictim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!g_bShowOutput[iVictim]) return Plugin_Continue;
	
	decl iAttacker, iCustomKill, iDeathFlags, iDamageBits;
	decl String:szKillType[32], String:szWeapon[64], String:szTrans[32];
	
	iAttacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	iCustomKill = GetEventInt(event, "customkill");
	iDeathFlags = GetEventInt(event, "death_flags");
	iDamageBits = GetEventInt(event, "damagebits");	
	
	GetEventString(event, "weapon_logclassname", szWeapon, sizeof(szWeapon));

	/* Skip over worldspawn, suicides and deadringer kills */
	if (!iAttacker || iAttacker == iVictim) return Plugin_Continue;
	if (iDeathFlags & TF_DEATHFLAG_DEADRINGER) return Plugin_Continue;

	SetGlobalTransTarget(iVictim);

	/* Attacker finished victim off */
	if(strcmp(szWeapon, "world", false) == 0 || strcmp(szWeapon, "player", false) == 0)
	{
		#if defined USECOLORS
		CPrintToChatEx(iVictim, iAttacker, "%t", "finished off", iAttacker);
		#else
		PrintToChat(iVictim, "%t", "finished off", iAttacker);
		#endif
		return Plugin_Continue;
	}
	
	/*
	* This is needed since we are assuming that the weapon name exists in the translation file.  Should work around the massive amount of errors when valve adds new weapons.
	*/
	new bool:bWeaponFound = false;
	if (TranslationExists(szWeapon))
		bWeaponFound = true;
	#if defined LOG_WEAPON_ERRORS
	else
		LogToFileEx(g_szLogFile, "Translation missing for weapon: %s", szWeapon);	
	#endif	
	
	/* 
	* Player died before killing you
	*/
	if (!IsPlayerAlive(iAttacker))
	{
		if (bWeaponFound)
			szTrans = "died before killing";
		else
			szTrans = "died before killing nowpn";
			
		#if defined USECOLORS
		CPrintToChatEx(iVictim, iAttacker, "%t", szTrans, iAttacker, szWeapon);
		#else
		PrintToChat(iVictim, "%t", szTrans, iAttacker, szWeapon);
		#endif
		return Plugin_Continue;
	}

	FormatEx(szKillType, sizeof(szKillType), "killed");

	/*
	* Kill was a crit - lets find out what kind
	*/
	if (iDamageBits & TF2_DAMAGEBIT_CRITS)
	{
		decl iAttackerCond, iVictimCond;
		iAttackerCond = TF2_GetPlayerConditionFlags(iAttacker);
		iVictimCond = TF2_GetPlayerConditionFlags(iVictim);
		
		if (iAttackerCond & TF_CONDFLAG_BUFFED)			//Buff Banner
			FormatEx(szKillType, sizeof(szKillType), "minicrit banner");
		else if (iVictimCond & TF_CONDFLAG_JARATED)		//Jarate
			FormatEx(szKillType, sizeof(szKillType), "minicrit jarate");
		else if (iAttackerCond & TF_CONDFLAG_CRITCOLA)	//Crit-a-Cola
			FormatEx(szKillType, sizeof(szKillType), "minicrit critcola");
		else
			FormatEx(szKillType, sizeof(szKillType), "crit");
	}
	/*
	* This kill was a special kill - lets find out which kind
	*/
	new bool:iIsTaunt = false;
	switch (iCustomKill)
	{
		case TF_CUSTOM_HEADSHOT:		FormatEx(szKillType, sizeof(szKillType), "headshot");
		case TF_CUSTOM_BACKSTAB:		FormatEx(szKillType, sizeof(szKillType), "backstabbed");
		case TF_CUSTOM_DECAPITATION: 	FormatEx(szKillType, sizeof(szKillType), "decapitated");
		case TF_CUSTOM_CHARGE_IMPACT:	FormatEx(szKillType, sizeof(szKillType), "trampled");
		case TF_CUSTOM_TAUNT_ARROW_STAB, TF_CUSTOM_TAUNT_BARBARIAN_SWING, TF_CUSTOM_TAUNT_ENGINEER_ARM, TF_CUSTOM_TAUNT_ENGINEER_SMASH, 
			 TF_CUSTOM_TAUNT_FENCING, TF_CUSTOM_TAUNT_GRAND_SLAM, TF_CUSTOM_TAUNT_GRENADE, TF_CUSTOM_TAUNT_HADOUKEN, 
			 TF_CUSTOM_TAUNT_HIGH_NOON, TF_CUSTOM_TAUNT_UBERSLICE: iIsTaunt = true;
	}
	
	if (iIsTaunt)
		FormatEx(szKillType, sizeof(szKillType), "humiliated");
	else
	{
		if (iDeathFlags & TF_DEATHFLAG_KILLERDOMINATION)
			FormatEx(szKillType, sizeof(szKillType), "dominated");
		else if (iDeathFlags & TF_DEATHFLAG_KILLERREVENGE)
			FormatEx(szKillType, sizeof(szKillType), "revenged");
	}

	if (bWeaponFound)
		szTrans = "killed you";
	else
		szTrans = "killed you nowpn";
	
	#if defined USECOLORS
	CPrintToChatEx(iVictim, iAttacker, "%t", szTrans, iAttacker, szKillType, szWeapon, GetClientHealth(iAttacker));
	#else
	PrintToChat(iVictim, "%t", szTrans, iAttacker, szKillType, szWeapon, GetClientHealth(iAttacker));
	#endif
	
	return Plugin_Continue;
}

public Action:SayCallback(iClient, const String:command[], argc)
{
	if(!iClient) return Plugin_Continue;
	
	if (g_bShowOutput[iClient])
	{
		SetClientCookie(iClient, g_hCookie, "1");
		g_bShowOutput[iClient] = false;
		ReplyToCommand(iClient, "[SM] %t", "output disabled");
	}
	else
	{
		SetClientCookie(iClient, g_hCookie, "0");
		g_bShowOutput[iClient] = true;
		ReplyToCommand(iClient, "[SM] %t", "output enabled");
	}
	return Plugin_Handled;
}

stock bool:TranslationExists(String:szString[]) 
{
	new bool:result = KvJumpToKey(g_hKeyValues, szString, false);
	KvRewind(g_hKeyValues);
	return result;
}
