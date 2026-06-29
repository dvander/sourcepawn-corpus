#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <cstrike_weapons>
#include <restrict>
#pragma semicolon 1

#define WARMUP
#define CONFIGLOADER
#define STOCKMENU
#define PERPLAYER

#if defined STOCKMENU
#undef REQUIRE_PLUGIN
#include <adminmenu>
#endif

#define PLUGIN_VERSION "3.1.3"
#define ADMINCOMMANDTAG "\x01\x0B\x04[SM] "
#define MAXALIASES 8
#define MAXWEAPONGROUPS 7
enum GameType
{
	GAME_CSS,
	GAME_CSGO
};
/*new const String:g_WeaponAliasNames[][WEAPONARRAYSIZE] = {"flash", "sgren", "hegren", "assaultsuit", "kevlar", "mp5", "magnum", "nightvision"};
new const String:g_WeaponAliasReplace[][WEAPONARRAYSIZE] = {"flashbang", "smokegrenade", "hegrenade", "vesthelm", "vest", "mp5navy", "awp", "nvgs"};*/
new GameType:g_iGame;
new g_iMyWeaponsMax = 31;
new const String:g_WeaponGroupNames[][WEAPONARRAYSIZE] = {"pistols", "smgs", "shotguns", "rifles", "snipers", "grenades", "armor"};

new bool:g_bRestrictSound = false;
new String:g_sCachedSound[PLATFORM_MAX_PATH];
new bool:g_bLateLoaded = false;

new RoundType:g_nextRoundSpecial = RoundType_None;
new RoundType:g_currentRoundSpecial = RoundType_None;
#if defined STOCKMENU
new Handle:hAdminMenu = INVALID_HANDLE;
#endif

#include "restrictinc/cvars.sp"

#if defined WARMUP
#include "restrictinc/warmup.sp"
#endif

#if defined CONFIGLOADER
#include "restrictinc/configloader.sp"
#endif

#if defined STOCKMENU
#include "restrictinc/adminmenu.sp"
#endif

#if defined PERPLAYER
#include "restrictinc/perplayer.sp"
#endif

#include "restrictinc/weapon-tracking.sp"
#include "restrictinc/natives.sp"
#include "restrictinc/functions.sp"
#include "restrictinc/events.sp"
#include "restrictinc/admincmds.sp"

public Plugin:myinfo = 
{
	name = "Weapon Restrict",
	author = "Dr!fter",
	description = "Weapon restrict",
	version = PLUGIN_VERSION,
	url = "www.spawnpoint.com"
}
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:gamedir[PLATFORM_MAX_PATH];
	GetGameFolderName(gamedir, sizeof(gamedir));
	if(strcmp(gamedir, "cstrike") != 0 && strcmp(gamedir, "csgo") != 0)
	{
		strcopy(error, err_max, "This plugin is only supported on CS");
		return APLRes_Failure;
	}
	if(strcmp(gamedir, "cstrike") == 0)
	{
		g_iGame = GAME_CSS;
	}
	else
	{
		g_iMyWeaponsMax = 63;
		g_iGame = GAME_CSGO;
	}
	g_bLateLoaded = late;
	RegisterNatives();
	return APLRes_Success;
}
public OnPluginStart()
{	
	HookEvents();
	RegisterAdminCommands();
	RegisterForwards();
	
	#if defined WARMUP
	RegisterWarmup();
	#endif
	
	#if defined STOCKMENU
	//For late load 
	if(LibraryExists("adminmenu"))
	{
		new Handle:topmenu;
		topmenu = GetAdminTopMenu();
		
		if(topmenu != INVALID_HANDLE)
		OnAdminMenuReady(topmenu);
    }
	#endif
	
	LoadTranslations("common.phrases");
	LoadTranslations("WeaponRestrict.phrases");
	
	CreateConVars();
	CreateTimer(0.1, LateLoadExec, _, TIMER_FLAG_NO_MAPCHANGE);
}
public Action:LateLoadExec(Handle:timer)
{
	new String:file[] = "cfg/sourcemod/weapon_restrict.cfg";
	if(FileExists(file))
	{
		ServerCommand("exec sourcemod/weapon_restrict.cfg");
	}
}