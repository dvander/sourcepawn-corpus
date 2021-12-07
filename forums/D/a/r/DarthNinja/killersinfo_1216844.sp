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
*/

#include <sourcemod>
#include <clientprefs>

//#define USECOLORS			//UNCOMMENT FOR COLOR SUPPORT

#if defined USECOLORS
#include <colors>
#endif

#pragma semicolon 1

#define VERSION "1.2.0"

//death_flags
#define DF_DOMINATION			(1<<0)	//1
#define DF_ASSIST_DOMINATION	(1<<1)	//2
#define DF_REVENGE				(1<<2)	//4
#define DF_ASSIST_REVENGE		(1<<3)	//8
#define DF_FIRSTBLOOD			(1<<4)	//16
#define DF_FEIGNDEATH			(1<<5)	//32

//damagebits
#define DB_TRAIN	(1<<4)		//16 (DMG_VEHICLE)
#define DB_DROWNED	(1<<14)		//16384 (DMG_DROWN)
#define DB_CRITS	(1<<20)		//1048576 (DAMAGE_ACID)

//m_nPlayerCond
#define TF2_PLAYERCOND_BUFFBANNER	(1<<16)	//16
#define TF2_PLAYERCOND_JARATE		(1<<22)	//4194304

new bShowOutput[MAXPLAYERS + 1];

new Handle:g_CvarDefaultSetting = INVALID_HANDLE;
new Handle:g_Cookie = INVALID_HANDLE;

enum
{
	HEADSHOT = 1,
	BACKSTAB,
	FLAMETHROWER,
	BODYSHOT = 11
}

public Plugin:myinfo =
{
	name = "TF2: Killer's Info",
	author = "Nut",
	description = "Shows a victim information about their killer.",
	version = VERSION,
	url = "http://www.lolsup.com/tf2/"
}

public OnPluginStart()
{
	CreateConVar("sm_ki_version", VERSION, "TF2: Killer's Info", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	AddCommandListener(SayCallback, "sm_ki_toggle");
	HookEvent("player_death", event_player_death, EventHookMode_Post);
	LoadTranslations("killersinfo.phrases");
	
	g_CvarDefaultSetting = CreateConVar("sm_ki_default", "1", "default output setting for new players");
	g_Cookie = RegClientCookie("killersinfo_display", "Shows info about your killing when you get killed.", CookieAccess_Public);
}

public OnClientPostAdminCheck(client)
{
	if (!IsClientInGame(client)) return;
	if (AreClientCookiesCached(client))
	{
		new String:szBuffer[5];
		GetClientCookie(client, g_Cookie, szBuffer, sizeof(szBuffer));
		if (strlen(szBuffer) < 1)	//doesn't exist
			bShowOutput[client] = GetConVarInt(g_CvarDefaultSetting);
		else
			switch (StringToInt(szBuffer))
			{
				case 1: bShowOutput[client] = false;
				case 0: bShowOutput[client] = true;
				default: bShowOutput[client] = GetConVarInt(g_CvarDefaultSetting);
			}
	}
}

public Action:event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iVictim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!bShowOutput[iVictim]) return Plugin_Continue;
	
	decl iAttacker, iCustomKill, iDeathFlags, iDamageBits;

	iAttacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	iCustomKill = GetEventInt(event, "customkill");
	iDeathFlags = GetEventInt(event, "death_flags");
	iDamageBits = GetEventInt(event, "damagebits");

	if (!iAttacker || iAttacker == iVictim) return Plugin_Continue;		//skip worldspawn and suicides
	if (iDeathFlags & DF_FEIGNDEATH) return Plugin_Continue;			//skip dead ringer

	decl String:szKillType[32], String:szWeapon[64];
	GetEventString(event, "weapon_logclassname", szWeapon, sizeof(szWeapon));
	
	SetGlobalTransTarget(iVictim);

	if(strcmp(szWeapon, "world", false) == 0 || strcmp(szWeapon, "player", false) == 0)
	{
		#if defined USECOLORS
		CPrintToChatEx(iVictim, iAttacker, "%t", "finished off", iAttacker);
		#else
		PrintToChat(iVictim, "%t", "finished off", iAttacker);
		#endif
		return Plugin_Continue;
	}
	
	if (!IsPlayerAlive(iAttacker))
	{
		#if defined USECOLORS
		CPrintToChatEx(iVictim, iAttacker, "%t", "died before killing", iAttacker, szWeapon);
		#else
		PrintToChat(iVictim, "%t", "died before killing", iAttacker, szWeapon);
		#endif
		return Plugin_Continue;
	}

	FormatEx(szKillType, sizeof(szKillType), "killed");

	if (iDamageBits & DB_CRITS)
	{
		new iAttackerCond = GetEntProp(iAttacker, Prop_Send, "m_nPlayerCond");
		new iVictimCond = GetEntProp(iVictim, Prop_Send, "m_nPlayerCond");
		
		if (iAttackerCond & TF2_PLAYERCOND_BUFFBANNER)
			FormatEx(szKillType, sizeof(szKillType), "minicrit banner");
		else if (iVictimCond & TF2_PLAYERCOND_JARATE)
			FormatEx(szKillType, sizeof(szKillType), "minicrit jarate");
		else
			FormatEx(szKillType, sizeof(szKillType), "crit");
	}
	
	switch (iCustomKill)
	{
		case HEADSHOT:	FormatEx(szKillType, sizeof(szKillType), "headshot");
		case BACKSTAB:	FormatEx(szKillType, sizeof(szKillType), "backstabbed");
	}

	if (iDeathFlags & DF_DOMINATION)
		FormatEx(szKillType, sizeof(szKillType), "dominated");
	else if (iDeathFlags & DF_REVENGE)
		FormatEx(szKillType, sizeof(szKillType), "revenged");
	
	if(StrContains(szWeapon, "taunt", false) > -1)
		FormatEx(szKillType, sizeof(szKillType), "humiliated");
	
	#if defined USECOLORS
	CPrintToChatEx(iVictim, iAttacker, "%t", "killed you", iAttacker, szKillType, szWeapon, GetClientHealth(iAttacker));
	#else
	PrintToChat(iVictim, "%t", "killed you", iAttacker, szKillType, szWeapon, GetClientHealth(iAttacker));
	#endif
	
	return Plugin_Continue;
}

public Action:SayCallback(client, const String:command[], argc)
{
	if(!client) return Plugin_Continue;
	
	if (bShowOutput[client])
	{
		SetClientCookie(client, g_Cookie, "1");
		bShowOutput[client] = false;
		#if defined USECOLORS
		CPrintToChat(client, "[SM] %t", "output disabled");
		#else
		PrintToChat(client, "[SM] %t", "output disabled");
		#endif
	}
	else
	{
		SetClientCookie(client, g_Cookie, "0");
		bShowOutput[client] = true;
		#if defined USECOLORS
		CPrintToChat(client, "[SM] %t", "output enabled");
		#else
		PrintToChat(client, "[SM] %t", "output enabled");
		#endif
	}
	return Plugin_Handled;
}