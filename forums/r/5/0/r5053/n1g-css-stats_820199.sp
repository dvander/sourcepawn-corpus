

#include <sourcemod>
#include <sdktools>
#include <geoip>

#define PLUGIN_VERSION "0.4.1"
#define DBVERSION 3
#define MAX_LINE_WIDTH 60



new mapisset

new Handle:db = INVALID_HANDLE;			/** Database connection */

new Handle:diepoints = INVALID_HANDLE;

new Handle:removeoldplayers = INVALID_HANDLE;
new Handle:removeoldplayersdays = INVALID_HANDLE;

new Handle:removeoldmaps = INVALID_HANDLE;
new Handle:removeoldmapssdays = INVALID_HANDLE;

new Handle:showrankonconnect = INVALID_HANDLE;
new Handle:webrank = INVALID_HANDLE;
new Handle:webrankurl = INVALID_HANDLE;

new Handle:neededplayercount = INVALID_HANDLE;
new Handle:plgnversion = INVALID_HANDLE;
new Handle:showrankonroundend = INVALID_HANDLE;
new sqllite = 0
new bool:rankingactive = true

new onconrank[MAXPLAYERS + 1]
new onconpoints[MAXPLAYERS + 1]
new rankedclients = 0
new playerpoints[MAXPLAYERS + 1]
new playerrank[MAXPLAYERS + 1]
new String:ranksteamidreq[MAXPLAYERS + 1][25];
new String:ranknamereq[MAXPLAYERS + 1][32];
new reqplayerrankpoints[MAXPLAYERS + 1]
new reqplayerrank[MAXPLAYERS + 1]
new String:ranknametop[10][32];
new String:ranksteamidtop[10][32];

new sessionpoints[MAXPLAYERS + 1]
new sessionkills[MAXPLAYERS + 1]
new sessiondeath[MAXPLAYERS + 1]
new sessionheadshotkills[MAXPLAYERS + 1]

new bool:roundactive = true

new Handle:CV_m4a1 = INVALID_HANDLE;
new Handle:CV_ak47 = INVALID_HANDLE;
new Handle:CV_scout = INVALID_HANDLE;
new Handle:CV_hegrenade = INVALID_HANDLE;
new Handle:CV_deagle = INVALID_HANDLE;
new Handle:CV_knife = INVALID_HANDLE;
new Handle:CV_sg552 = INVALID_HANDLE;
new Handle:CV_p90 = INVALID_HANDLE;
new Handle:CV_aug = INVALID_HANDLE;
new Handle:CV_usp = INVALID_HANDLE;
new Handle:CV_famas = INVALID_HANDLE;
new Handle:CV_mp5navy = INVALID_HANDLE;
new Handle:CV_galil = INVALID_HANDLE;
new Handle:CV_m249 = INVALID_HANDLE;
new Handle:CV_m3 = INVALID_HANDLE;
new Handle:CV_glock = INVALID_HANDLE;
new Handle:CV_p228 = INVALID_HANDLE;
new Handle:CV_elite = INVALID_HANDLE;
new Handle:CV_xm1014 = INVALID_HANDLE;
new Handle:CV_fiveseven = INVALID_HANDLE;
new Handle:CV_tmp = INVALID_HANDLE;
new Handle:CV_ump45 = INVALID_HANDLE;
new Handle:CV_mac10 = INVALID_HANDLE;
new Handle:CV_sg550 = INVALID_HANDLE;
new Handle:CV_awp = INVALID_HANDLE;
new Handle:CV_g3sg9 = INVALID_HANDLE;


new Handle:CV_bomb_planted = INVALID_HANDLE;
new Handle:CV_bomb_defused = INVALID_HANDLE;
new Handle:CV_bomb_exploded = INVALID_HANDLE;
new Handle:CV_hostage_follows = INVALID_HANDLE;
new Handle:CV_hostage_rescued = INVALID_HANDLE;

new Handle:CV_chattag = INVALID_HANDLE;
new String:CHATTAG[MAX_LINE_WIDTH]
new Handle:pointmsg = INVALID_HANDLE;
public Plugin:myinfo = 
{
	name = "CS:S Stats",
	author = "R-Hehl",
	description = "CS:S Player Stats",
	version = PLUGIN_VERSION,
	url = "http://compactaim.de"
};
public OnPluginStart()
{
	LoadTranslations("cssstats.phrases");
	openDatabaseConnection()
	createdbtables()
	convarcreating()
	CreateConVar("sm_css_stats_version", PLUGIN_VERSION, "CSS Player Stats", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	starteventhooking()
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say2", Command_Say);
	/* RegAdminCmd("rank_admin", Menu_adm, ADMFLAG_CUSTOM1, "Open Rank Admin Menu"); */
	CreateTimer(60.0,sec60evnt,INVALID_HANDLE,TIMER_REPEAT);
	startconvarhooking()
	
}
public Action:sec60evnt(Handle:timer, Handle:hndl)
{
	playerstimeupdateondb()
	if (sqllite != 1)
{
	refreshmaptime()
}
	}
public refreshmaptime()
{
	new String:name[MAX_LINE_WIDTH];
	GetCurrentMap(name,MAX_LINE_WIDTH);
	new time = GetTime()
	new String:query[512];
	Format(query, sizeof(query), "UPDATE Map SET PLAYTIME = PLAYTIME + 1, LASTONTIME = %i WHERE NAME LIKE '%s'",time ,name);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
}
public playerstimeupdateondb()
{
	new String:clsteamId[MAX_LINE_WIDTH];
	new maxclients = GetMaxClients()
	new time = GetTime()
	for(new i=1; i <= maxclients; i++)
	{
	if(IsClientInGame(i) && !IsFakeClient(i))
	{
	GetClientAuthString(i, clsteamId, sizeof(clsteamId));
	new String:query[512];
	Format(query, sizeof(query), "UPDATE Player SET PLAYTIME = PLAYTIME + 1, LASTONTIME = %i WHERE STEAMID = '%s'",time ,clsteamId);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	}
	}
}
openDatabaseConnection()
{
	if (SQL_CheckConfig("cssstats"))
	{
	new String:error[255]
	db = SQL_Connect("cssstats",true,error, sizeof(error))
	if (db == INVALID_HANDLE)
	{
	PrintToServer("Failed to connect: %s", error)
	}
	else 
	{
	LogMessage("DatabaseInit (CONNECTED) with db config");
	/* Set codepage to utf8 */

	decl String:query[255];
	Format(query, sizeof(query), "SET NAMES 'utf8'");
	if (!SQL_FastQuery(db, query))
	{
	LogError("Can't select character set (%s)", query);
	}

	/* End of Set codepage to utf8 */
	}
	
	} 
	else 
	{
	new String:error[255]
	sqllite = 1
	db = SQL_ConnectEx(SQL_GetDriver("sqlite"), "", "", "", "cssstats", error, sizeof(error), true, 0);	
	if (db == INVALID_HANDLE)
	{
	LogMessage("Failed to connect: %s", error)
	}
	else 
	{
	LogMessage("DatabaseInit SQLLITE (CONNECTED)");
	}
	}
	
	
}
createdb()
{
if (sqllite != 1)
{
createdbplayer()
createdbmap()
}
else
{
createdbplayersqllite()
}
}

createdbplayer()
{
	new len = 0;
	decl String:query[2048];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `Player`");
	len += Format(query[len], sizeof(query)-len, " (`STEAMID` varchar(25) NOT NULL, `NAME` varchar(30) NOT NULL,");
	len += Format(query[len], sizeof(query)-len, "  `POINTS` int(25) NOT NULL,`PLAYTIME` int(25) NOT NULL, `LASTONTIME` int(25) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KILLS` int(11) NOT NULL , `Death` int(11) NOT NULL , `HeadshotKill` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KW_m4a1` int(11) NOT NULL , `KW_ak47` int(11) NOT NULL , `KW_scout` int(11) NOT NULL , `KW_hegrenade` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KW_deagle` int(11) NOT NULL , `KW_knife` int(11) NOT NULL , `KW_sg552` int(11) NOT NULL , `KW_p90` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KW_aug` int(11) NOT NULL , `KW_usp` int(11) NOT NULL , `KW_famas` int(11) NOT NULL , `KW_mp5navy` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KW_galil` int(11) NOT NULL , `KW_m249` int(11) NOT NULL , `KW_m3` int(11) NOT NULL , `KW_glock` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KW_p228` int(11) NOT NULL , `KW_elite` int(11) NOT NULL , `KW_xm1014` int(11) NOT NULL , `KW_fiveseven` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KW_tmp` int(11) NOT NULL , `KW_ump45` int(11) NOT NULL , `KW_mac10` int(11) NOT NULL , `bomb_planted` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `bomb_defused` int(11) NOT NULL , `bomb_exploded` int(11) NOT NULL , `hostage_follows` int(11) NOT NULL , `hostage_killed` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `hostage_rescued` int(11) NOT NULL , `KW_awp` int(11) NOT NULL , `KW_sg550` int(11) NOT NULL , `KW_g3sg9` int(11) NOT NULL , PRIMARY KEY (`NAME`));");

	SQL_FastQuery(db, query);
}
createdbplayersqllite()
{
	new len = 0;
	decl String:query[2048];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `Player`");
	len += Format(query[len], sizeof(query)-len, " (`STEAMID` TEXT, `NAME` TEXT,");
	len += Format(query[len], sizeof(query)-len, "  `POINTS` INTEGER,`PLAYTIME` INTEGER, `LASTONTIME` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `KILLS` INTEGER, `Death` INTEGER, `HeadshotKill` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `KW_m4a1` INTEGER, `KW_ak47` INTEGER, `KW_scout` INTEGER, `KW_hegrenade` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `KW_deagle` INTEGER, `KW_knife` INTEGER, `KW_sg552` INTEGER, `KW_p90` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `KW_aug` INTEGER, `KW_usp` INTEGER, `KW_famas` INTEGER, `KW_mp5navy` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `KW_galil` INTEGER, `KW_m249` INTEGER, `KW_m3` INTEGER, `KW_glock` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `KW_p228` INTEGER, `KW_elite` INTEGER, `KW_xm1014` INTEGER, `KW_fiveseven` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `KW_tmp` INTEGER, `KW_ump45` INTEGER, `KW_mac10` INTEGER, `bomb_planted` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `bomb_defused` INTEGER, `bomb_exploded` INTEGER, `hostage_follows` INTEGER, `hostage_killed` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `hostage_rescued` INTEGER, `KW_awp` INTEGER, `KW_sg550` INTEGER, `KW_g3sg9` INTEGER);");
	
	
	SQL_FastQuery(db, query);
}
createdbmap()
{
	new len = 0;
	decl String:query[2048];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `Map`");
	len += Format(query[len], sizeof(query)-len, " (`NAME` varchar(30) NOT NULL,");
	len += Format(query[len], sizeof(query)-len, "  `POINTS` int(25) NOT NULL,`PLAYTIME` int(25) NOT NULL, `LASTONTIME` int(25) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KILLS` int(11) NOT NULL , `Death` int(11) NOT NULL , `HeadshotKill` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KW_m4a1` int(11) NOT NULL , `KW_ak47` int(11) NOT NULL , `KW_scout` int(11) NOT NULL , `KW_hegrenade` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KW_deagle` int(11) NOT NULL , `KW_knife` int(11) NOT NULL , `KW_sg552` int(11) NOT NULL , `KW_p90` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KW_aug` int(11) NOT NULL , `KW_usp` int(11) NOT NULL , `KW_famas` int(11) NOT NULL , `KW_mp5navy` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KW_galil` int(11) NOT NULL , `KW_m249` int(11) NOT NULL , `KW_m3` int(11) NOT NULL , `KW_glock` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KW_p228` int(11) NOT NULL , `KW_elite` int(11) NOT NULL , `KW_xm1014` int(11) NOT NULL , `KW_fiveseven` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KW_tmp` int(11) NOT NULL , `KW_ump45` int(11) NOT NULL , `KW_mac10` int(11) NOT NULL , `bomb_planted` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `bomb_defused` int(11) NOT NULL , `bomb_exploded` int(11) NOT NULL , `hostage_follows` int(11) NOT NULL , `hostage_killed` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `hostage_rescued` int(11) NOT NULL , PRIMARY KEY (`NAME`));");

	SQL_FastQuery(db, query);
}

public convarcreating()
{
	diepoints = CreateConVar("rank_diepoints","3","Set the points a player lose on Death");
	removeoldplayers = CreateConVar("rank_removeoldplayers","1","Enable Automatic Removing Player who doesn't conect a specific time on every Roundend");
	removeoldplayersdays = CreateConVar("rank_removeoldplayersdays","14","The time in days after a player get removed if he doesn't connect min 1 day");
	removeoldmaps = CreateConVar("rank_removeoldmaps","1","Enable Automatic Removing Maps who wasn't played a specific time on every Roundend");
	removeoldmapssdays = CreateConVar("rank_removeoldmapsdays","14","The time in days after a map get removed, min 1 day");
	showrankonconnect = CreateConVar("rank_show","4","Show on connect, 0=disabled, 1=clientchat, 2=allchat, 3=panel, 4=panel + all chat");
	webrank = CreateConVar("rank_webrank","0","Enable/Disable Webrank");
	webrankurl = CreateConVar("rank_webrankurl","","Webrank url like http://compactaim.de/tf2stats/", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	neededplayercount = CreateConVar("rank_neededplayers","0","How many clients are needed to start ranking");
	showrankonroundend = CreateConVar("rank_showrankonroundend","1","Shows Top 10 on Roundend");
	
	CV_m4a1 = CreateConVar("rank_kill_m4a1","3","Set the points the attacker get");
	CV_ak47 = CreateConVar("rank_kill_ak47","3","Set the points the attacker get");
	CV_scout = CreateConVar("rank_kill_scout","3","Set the points the attacker get");
	CV_hegrenade = CreateConVar("rank_kill_hegrenade","3","Set the points the attacker get");
	CV_deagle = CreateConVar("rank_kill_deagle","3","Set the points the attacker get");
	CV_knife = CreateConVar("rank_kill_knife","3","Set the points the attacker get");
	CV_sg552 = CreateConVar("rank_kill_sg552","3","Set the points the attacker get");
	CV_p90 = CreateConVar("rank_kill_p90","3","Set the points the attacker get");
	CV_aug = CreateConVar("rank_kill_aug","3","Set the points the attacker get");
	CV_usp = CreateConVar("rank_kill_usp","3","Set the points the attacker get");
	CV_famas = CreateConVar("rank_kill_famas","3","Set the points the attacker get");
	CV_mp5navy = CreateConVar("rank_kill_mp5navy","3","Set the points the attacker get");
	CV_galil = CreateConVar("rank_kill_galil","3","Set the points the attacker get");
	CV_m249 = CreateConVar("rank_kill_m249","3","Set the points the attacker get");
	CV_m3 = CreateConVar("rank_kill_m3","3","Set the points the attacker get");
	CV_glock = CreateConVar("rank_kill_glock","3","Set the points the attacker get");
	CV_p228 = CreateConVar("rank_kill_p228","3","Set the points the attacker get");
	CV_elite = CreateConVar("rank_kill_elite","3","Set the points the attacker get");
	CV_xm1014 = CreateConVar("rank_kill_xm1014","3","Set the points the attacker get");
	CV_fiveseven = CreateConVar("rank_kill_fiveseven","3","Set the points the attacker get");
	CV_tmp = CreateConVar("rank_kill_tmp","3","Set the points the attacker get");
	CV_ump45 = CreateConVar("rank_kill_ump45","3","Set the points the attacker get");
	CV_mac10 = CreateConVar("rank_kill_mac10","3","Set the points the attacker get");
	CV_sg550 = CreateConVar("rank_kill_sg550","3","Set the points the attacker get");
	CV_awp = CreateConVar("rank_kill_awp","3","Set the points the attacker get");
	CV_g3sg9 = CreateConVar("rank_kill_g3sg9","3","Set the points the attacker get");
	
	CV_chattag = CreateConVar("rank_chattag","RANK","Set the Chattag");
	pointmsg = CreateConVar("rank_pointmsg","2","on point earned message 0 = disabled, 1 = all, 2 = only who earned");

	
	CV_bomb_planted = CreateConVar("rank_bomb_planted","3","Set the points");
	CV_bomb_defused = CreateConVar("rank_bomb_defused","5","Set the points");
	CV_bomb_exploded = CreateConVar("rank_bomb_exploded","3","Set the points");
	CV_hostage_follows = CreateConVar("rank_hostage_follows","1","Set the points");
	CV_hostage_rescued = CreateConVar("rank_hostage_rescued","3","Set the points");
	}
public starteventhooking() 
{
	HookEvent("player_death", Event_PlayerDeath)
	HookEvent("round_end", Event_round_end)
	HookEvent("bomb_defused", Event_bomb_defused)
	HookEvent("bomb_exploded", Event_bomb_exploded)
	HookEvent("bomb_planted", Event_bomb_planted)
	HookEvent("hostage_follows", Event_hostage_follows)
	HookEvent("hostage_killed", Event_hostage_killed)
	HookEvent("hostage_rescued", Event_hostage_rescued)

}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (rankingactive)
	{
	new victimId = GetEventInt(event, "userid")
	new attackerId = GetEventInt(event, "attacker")
	new victim = GetClientOfUserId(victimId)
	new attacker = GetClientOfUserId(attackerId)
	new bool:headshot = GetEventBool(event, "headshot")
	new String:weapon[64]
	GetEventString(event, "weapon", weapon, sizeof(weapon))
	PrintToConsole(attacker,"[N1G-Debug] Weapon: %s",weapon)
	if (attacker != 0)
	{
	if (attacker != victim && !IsFakeClient(victim))
	{
	decl String:query[512];
	new String:steamIdattacker[MAX_LINE_WIDTH];
	new String:steamIdavictim[MAX_LINE_WIDTH];
	GetClientAuthString(attacker, steamIdattacker, sizeof(steamIdattacker));
	GetClientAuthString(victim, steamIdavictim, sizeof(steamIdavictim));
	new pointvalue = GetConVarInt(diepoints)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS - %i, Death = Death + 1 WHERE STEAMID = '%s'",pointvalue ,steamIdavictim);
	sessiondeath[victim]++
	sessionpoints[victim] = sessionpoints[victim] - pointvalue
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	
	sessionkills[attacker]++
	pointvalue = 0
	if (!IsFakeClient(attacker)){
	if (strcmp(weapon[0], "m4a1", false) == 0)
	{
	pointvalue = GetConVarInt(CV_m4a1)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_m4a1 = KW_m4a1 + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "ak47", false) == 0)
	{
	pointvalue = GetConVarInt(CV_ak47)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_ak47 = KW_ak47 + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "scout", false) == 0)
	{
	pointvalue = GetConVarInt(CV_scout)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_scout = KW_scout + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "hegrenade", false) == 0)
	{
	pointvalue = GetConVarInt(CV_hegrenade)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_hegrenade = KW_hegrenade + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "deagle", false) == 0)
	{
	pointvalue = GetConVarInt(CV_deagle)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_deagle = KW_deagle + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "knife", false) == 0)
	{
	pointvalue = GetConVarInt(CV_knife)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_knife = KW_knife + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "sg552", false) == 0)
	{
	pointvalue = GetConVarInt(CV_sg552)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_sg552 = KW_sg552 + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "p90", false) == 0)
	{
	pointvalue = GetConVarInt(CV_p90)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_p90 = KW_p90 + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "aug", false) == 0)
	{
	pointvalue = GetConVarInt(CV_aug)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_aug = KW_aug + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "usp", false) == 0)
	{
	pointvalue = GetConVarInt(CV_usp)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_usp = KW_usp + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "famas", false) == 0)
	{
	pointvalue = GetConVarInt(CV_famas)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_famas = KW_famas + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "mp5navy", false) == 0)
	{
	pointvalue = GetConVarInt(CV_mp5navy)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_mp5navy = KW_mp5navy + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "galil", false) == 0)
	{
	pointvalue = GetConVarInt(CV_galil)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_galil = KW_galil + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "m249", false) == 0)
	{
	pointvalue = GetConVarInt(CV_m249)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_m249 = KW_m249 + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "m3", false) == 0)
	{
	pointvalue = GetConVarInt(CV_m3)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_m3 = KW_m3 + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "glock", false) == 0)
	{
	pointvalue = GetConVarInt(CV_glock)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_glock = KW_glock + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "p228", false) == 0)
	{
	pointvalue = GetConVarInt(CV_p228)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_p228 = KW_p228 + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "elite", false) == 0)
	{
	pointvalue = GetConVarInt(CV_elite)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_elite = KW_elite + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "xm1014", false) == 0)
	{
	pointvalue = GetConVarInt(CV_xm1014)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_xm1014 = KW_xm1014 + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "fiveseven", false) == 0)
	{
	pointvalue = GetConVarInt(CV_fiveseven)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_fiveseven = KW_fiveseven + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "tmp", false) == 0)
	{
	pointvalue = GetConVarInt(CV_tmp)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_tmp = KW_tmp + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "ump45", false) == 0)
	{
	pointvalue = GetConVarInt(CV_ump45)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_ump45 = KW_ump45 + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "mac10", false) == 0)
	{
	pointvalue = GetConVarInt(CV_mac10)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_mac10 = KW_mac10 + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "awp", false) == 0)
	{
	pointvalue = GetConVarInt(CV_awp)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_awp = KW_awp + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "sg550", false) == 0)
	{
	pointvalue = GetConVarInt(CV_sg550)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_sg550 = KW_sg550 + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "g3sg9", false) == 0)
	{
	pointvalue = GetConVarInt(CV_g3sg9)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_g3sg9 = KW_g3sg9 + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} 
	if(headshot)
	{
	Format(query, sizeof(query), "UPDATE Player SET HeadshotKill = HeadshotKill + 1 WHERE steamId = '%s'",steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	sessionheadshotkills[attacker]++
	}
	sessionpoints[attacker] = sessionpoints[attacker] + pointvalue
	new String:attackername[MAX_LINE_WIDTH];
	GetClientName(attacker,attackername, sizeof(attackername))
	
	new String:victimname[MAX_LINE_WIDTH];
	GetClientName(victim,victimname, sizeof(victimname))
	new pointmsgval = GetConVarInt(pointmsg)
	if (pointmsgval >= 1)
	{
	if (pointmsgval == 1)
	{
	PrintToChatAll("\x04[\x03%s\x04]\x01 %s got %i points for killing %s",CHATTAG,attackername,pointvalue,victimname)
	}else
	{
	PrintToChat(attacker,"\x04[\x03%s\x04]\x01 you got %i points for killing %s",CHATTAG,pointvalue,victimname)
	}
		

	}
	}
	}
	}
}
}

public Action:Command_Say(client, args){
	new String:text[192], String:command[64];

	new startidx = 0;

	GetCmdArgString(text, sizeof(text));

	if (text[strlen(text)-1] == '"')
	{		
	text[strlen(text)-1] = '\0';
	startidx = 1;	
	} 	
	if (strcmp(command, "say2", false) == 0)
	startidx += 4;
	if (strcmp(text[startidx], "!Rank", false) == 0)
{
	session(client)
}
	else if (strcmp(text[startidx], "Rank", false) == 0)
{
	/* echo_rank(client) */
	session(client)
}
	else if (strcmp(text[startidx], "Top10", false) == 0)
{
	top10pnl(client)
}
	else if (strcmp(text[startidx], "Top", false) == 0)
{
	top10pnl(client)
}
	else if (strcmp(text[startidx], "rankinfo", false) == 0)
{
	rankinfo(client)
}
	else if (strcmp(text[startidx], "players", false) == 0)
{
	listplayers(client)
}	
	else if (strcmp(text[startidx], "session", false) == 0)
{
	session(client)
}
	else if (strcmp(text[startidx], "webtop", false) == 0)
{
	webtop(client)
}
	else if (strcmp(text[startidx], "webrank", false) == 0)
{
	webranking(client)
}
	return Plugin_Continue;
}

public Action:rankinfo(client)
{
	new Handle:infopanel = CreatePanel();
	SetPanelTitle(infopanel, "About Rank:")
	DrawPanelText(infopanel, "Plugin Coded by R-Hehl")
	DrawPanelText(infopanel, "Visit CompactAim.de")
	DrawPanelText(infopanel, "Contact me for")
	DrawPanelText(infopanel, "Feature Requests or Bugreport")
	DrawPanelText(infopanel, "Icq 87-47-94")
	DrawPanelText(infopanel, "E-Mail cssstats@r-hehl.de")
	new String:value[128];
	Format(value, sizeof(value), "Version %s DB Typ %i",PLUGIN_VERSION ,sqllite);
	DrawPanelText(infopanel, value)
	DrawPanelItem(infopanel, "Close")
 
	SendPanelToClient(infopanel, client, InfoPanelHandler, 20)
 
	CloseHandle(infopanel)
 
	return Plugin_Handled
}
public InfoPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		
	} else if (action == MenuAction_Cancel) {
		
	}
}

public showeallrank()
{
	new l_maxplayers
	l_maxplayers = GetMaxClients()
	for (new i=1; i<=l_maxplayers; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		
		{
		new String:steamIdclient[MAX_LINE_WIDTH];
		GetClientAuthString(i, steamIdclient, sizeof(steamIdclient));
		rankpanel(i, steamIdclient)
		}
	}

}
public removetooldplayers()
{
new remdays = GetConVarInt(removeoldplayersdays)
if (remdays >= 1)
{
new timesec = GetTime() - (remdays * 86400)
new String:query[512];
Format(query, sizeof(query), "DELETE FROM Player WHERE LASTONTIME < '%i'",timesec);
SQL_TQuery(db,SQLErrorCheckCallback, query)
}
}

public OnMapStart()
{
	MapInit()
}
public OnMapEnd()
{
	mapisset = 0
}
public MapInit()
{
	if (mapisset == 0)
{
	InitializeMaponDB()
}
}
public InitializeMaponDB()
{
if (mapisset == 0)
{
	if (sqllite != 1)
{
new String:name[MAX_LINE_WIDTH];
GetCurrentMap(name,MAX_LINE_WIDTH);
new String:query[512];
Format(query, sizeof(query), "INSERT IGNORE INTO Map (`NAME`) VALUES ('%s')", name)
SQL_TQuery(db,SQLErrorCheckCallback, query)
mapisset = 1
}
}
}
public Action:Event_round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	roundactive = false

	if (GetConVarInt(showrankonroundend) == 1)
	{
	showeallrank()
	}
	if (GetConVarInt(removeoldplayers) == 1)
	{
	removetooldplayers()
	}
	if (sqllite == 0)
	{
	if (GetConVarInt(removeoldmaps) == 1)
	{
	removetooldmaps()
	}
	}
}
public removetooldmaps()
{
new remdays = GetConVarInt(removeoldmapssdays)
if (remdays >= 1)
{
new timesec = GetTime() - (remdays * 86400)
new String:query[512];
Format(query, sizeof(query), "DELETE FROM Map WHERE LASTONTIME < '%i'",timesec);
SQL_TQuery(db,SQLErrorCheckCallback, query)
}
}
public updateplayername(client)
{
	new String:steamId[MAX_LINE_WIDTH];
	GetClientAuthString(client, steamId, sizeof(steamId));
	new String:name[MAX_LINE_WIDTH];
	GetClientName( client, name, sizeof(name) );
	ReplaceString(name, sizeof(name), "'", "");
	ReplaceString(name, sizeof(name), "<?", "");
	ReplaceString(name, sizeof(name), "?>", "");
	ReplaceString(name, sizeof(name), "\"", "");
	ReplaceString(name, sizeof(name), "<?PHP", "");
	ReplaceString(name, sizeof(name), "<?php", "");
	new String:query[512];
	Format(query, sizeof(query), "UPDATE Player SET NAME = '%s' WHERE STEAMID = '%s'",name ,steamId);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
}
public initonlineplayers()
{
	
	new l_maxplayers
	l_maxplayers = GetMaxClients()
	for (new i=1; i<=l_maxplayers; i++)
	{
	if (IsClientInGame(i) && !IsFakeClient(i))
	{
	updateplayername(i)
	InitializeClientonDB(i)
	}
	}
}
public Action:Menu_adm(client, args)
{
	new Handle:menu = CreateMenu(MenuHandlerrnkadm)
	SetMenuTitle(menu, "Rank Admin Menu")
	AddMenuItem(menu, "reset", "Reset Rank")
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, client, 20)
 
	return Plugin_Handled
}
public MenuHandlerrnkadm(Handle:menu, MenuAction:action, param1, param2)
{
	/* Either Select or Cancel will ALWAYS be sent! */
	if (action == MenuAction_Select)
	{
	new String:info[32]
	GetMenuItem(menu, param2, info, sizeof(info))
	if (strcmp(info,"rank",false))
	{
	resetdb()
	}
	} 
	/* If the menu has ended, destroy it */
	if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
}
public resetdb()
{
	new String:query[512];
	Format(query, sizeof(query), "TRUNCATE TABLE Player");
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	if (sqllite == 0)
	{
	Format(query, sizeof(query), "TRUNCATE TABLE Map");
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	}
	initonlineplayers()
}

public listplayers(client)
{
	Menu_playerlist(client)
}

public Action:Menu_playerlist(client)
{
	new Handle:menu = CreateMenu(MenuHandlerplayerslist)
	SetMenuTitle(menu, "Online Players:")
	new maxClients = GetMaxClients();
	for (new i=1; i<=maxClients; i++)
		{
			if (!IsClientInGame(i) && !IsFakeClient(i))
			{
				continue;
			}
			new String:name[65];
			GetClientName(i, name, sizeof(name));
			new String:steamId[MAX_LINE_WIDTH];
			GetClientAuthString(i, steamId, sizeof(steamId));
			AddMenuItem(menu, steamId, name)
		}
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, client, 20)
	return Plugin_Handled
}
public MenuHandlerplayerslist(Handle:menu, MenuAction:action, param1, param2)
{
	/* Either Select or Cancel will ALWAYS be sent! */
	if (action == MenuAction_Select)
	{
	new String:info[32]
	GetMenuItem(menu, param2, info, sizeof(info))
	rankpanel(param1, info)
	}
	
	
	/* If the menu has ended, destroy it */
	if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
}
/* New Code Full Threaded SQL Clean Code ---------------------------------------*/
public OnClientPostAdminCheck(client)
{
InitializeClientonDB(client)
sessionpoints[client] = 0
sessionkills[client] = 0
sessiondeath[client] = 0
sessionheadshotkills[client] = 0
if (!rankingactive)
{
if (GetConVarInt(neededplayercount) <= GetClientCount(true))
{
	if (roundactive)
{
	rankingactive = true
	PrintToChatAll("\x04[\x03%s\x04]\x01 Ranking Enabled: enough players",CHATTAG)
}
}
}
}
public InitializeClientonDB(client)
{
new String:ConUsrSteamID[MAX_LINE_WIDTH];
new String:buffer[255];

GetClientAuthString(client, ConUsrSteamID, sizeof(ConUsrSteamID));
Format(buffer, sizeof(buffer), "SELECT POINTS FROM Player WHERE STEAMID = '%s'", ConUsrSteamID);
new conuserid
conuserid = GetClientUserId(client)
SQL_TQuery(db, T_CheckConnectingUsr, buffer, conuserid)	
}

public T_CheckConnectingUsr(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
 
	/* Make sure the client didn't disconnect while the thread was running */
	
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}
	
	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed! %s", error);
	} else 
	{
	new String:clientname[MAX_LINE_WIDTH];
	GetClientName( client, clientname, sizeof(clientname) );
	ReplaceString(clientname, sizeof(clientname), "'", "");
	ReplaceString(clientname, sizeof(clientname), "<?", "");
	ReplaceString(clientname, sizeof(clientname), "?>", "");
	ReplaceString(clientname, sizeof(clientname), "\"", "");
	ReplaceString(clientname, sizeof(clientname), "<?PHP", "");
	ReplaceString(clientname, sizeof(clientname), "<?php", "");
	new String:ClientSteamID[MAX_LINE_WIDTH];
	GetClientAuthString(client, ClientSteamID, sizeof(ClientSteamID));
	new String:buffer[255];
	if (!SQL_GetRowCount(hndl)) {
	/*insert user*/
	if (sqllite != 1)
	{
	Format(buffer, sizeof(buffer), "INSERT INTO Player (`NAME`,`STEAMID`) VALUES ('%s','%s')", clientname, ClientSteamID)
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	} else
	{
	Format(buffer, sizeof(buffer), "INSERT INTO Player VALUES('%s','%s',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);", ClientSteamID,clientname )
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	}
	PrintToChatAll("\x04[\x03%s\x04]\x01 Created New Profile: '%s'",CHATTAG, clientname)
	}else
	{
	/*update name*/
	Format(buffer, sizeof(buffer), "UPDATE Player SET NAME = '%s' WHERE STEAMID = '%s'", clientname, ClientSteamID);
	SQL_TQuery(db,SQLErrorCheckCallback, buffer)
	
	new clientpoints
	while (SQL_FetchRow(hndl))
	{
	clientpoints = SQL_FetchInt(hndl,0)
	onconpoints[client] = clientpoints
	Format(buffer, sizeof(buffer), "SELECT COUNT(*) FROM `Player` WHERE `POINTS` >=%i", clientpoints);
	new conuserid
	conuserid = GetClientUserId(client)
	SQL_TQuery(db, T_ShowrankConnectingUsr1, buffer, conuserid);
	}
	}
	
	}
}

public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(!StrEqual("", error))
	{
	LogMessage("SQL Error: %s", error);
	}
}

public T_ShowrankConnectingUsr1(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
 
	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}
 
	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed! %s", error);
	} else {
	new rank
	while (SQL_FetchRow(hndl))
	{
	rank = SQL_FetchInt(hndl,0)
	}
	onconrank[client] = rank
	if (GetConVarInt(showrankonconnect) != 0)
	{
	new String:buffer[255];
	Format(buffer, sizeof(buffer), "SELECT COUNT(*) FROM `Player`");
	new conuserid
	conuserid = GetClientUserId(client)
	SQL_TQuery(db, T_ShowrankConnectingUsr2, buffer, conuserid);
	}
	}
}
public T_ShowrankConnectingUsr2(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
 
	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}
 
	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed! %s", error);
	} else {
	while (SQL_FetchRow(hndl))
	{
	rankedclients = SQL_FetchInt(hndl,0)
	}
	new String:country[3]
	new String:ip[20]
	GetClientIP(client,ip,sizeof(ip),true)
	GeoipCode2(ip,country)
	if (GetConVarInt(showrankonconnect) == 1)
	{
	PrintToChat(client,"Your Rank: %i of %i", onconrank[client],rankedclients)
	}else if (GetConVarInt(showrankonconnect) == 2)
	{
	new String:clientname[MAX_LINE_WIDTH];
	GetClientName( client, clientname, sizeof(clientname) );
	PrintToChatAll("\x04[\x03%s\x04]\x01 %s connected from %s. \x04[\x03Rank: %i of %i\x04]",CHATTAG, clientname, country,onconrank[client],rankedclients)
	}else if (GetConVarInt(showrankonconnect) == 3)
	{ 
	ConRankPanel(client)
	}else if (GetConVarInt(showrankonconnect) == 4)
	{
	new String:clientname[MAX_LINE_WIDTH];
	GetClientName( client, clientname, sizeof(clientname) );
	PrintToChatAll("\x04[\x03%s\x04]\x01 %s connected from %s. \x04[\x03Rank: %i of %i\x04]",CHATTAG, clientname, country,onconrank[client],rankedclients)
	ConRankPanel(client)
	}
	}
}
public ConRankPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
}

public Action:ConRankPanel(client)
{
	new Handle:panel = CreatePanel();
	new String:clientname[MAX_LINE_WIDTH];
	GetClientName( client, clientname, sizeof(clientname) );
	new String:buffer[255];
	Format(buffer, sizeof(buffer), "Welcome back %s",clientname)
	DrawPanelText(panel, buffer)
	Format(buffer, sizeof(buffer), "Rank: %i of %i",onconrank[client],rankedclients)
	DrawPanelText(panel, buffer)
	Format(buffer, sizeof(buffer), "Points: %i",onconpoints[client])
	DrawPanelText(panel, buffer)
	DrawPanelItem(panel, "Close")
 
	SendPanelToClient(panel, client, ConRankPanelHandler, 20)
 
	CloseHandle(panel)
 
	return Plugin_Handled
}
public session(client)
{
	new String:buffer[255];
	Format(buffer, sizeof(buffer), "SELECT COUNT(*) FROM `Player`");
	new conuserid
	conuserid = GetClientUserId(client)
	SQL_TQuery(db, T_ShowSession1, buffer, conuserid);
}

public T_ShowSession1(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
 
	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}
 
	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed! %s", error);
	} else 
	{
	while (SQL_FetchRow(hndl))
	{
	rankedclients = SQL_FetchInt(hndl,0)
	new String:ConUsrSteamID[MAX_LINE_WIDTH];
	new String:buffer[255];
	GetClientAuthString(client, ConUsrSteamID, sizeof(ConUsrSteamID));
	Format(buffer, sizeof(buffer), "SELECT POINTS FROM Player WHERE STEAMID = '%s'", ConUsrSteamID);
	new conuserid
	conuserid = GetClientUserId(client)
	SQL_TQuery(db, T_ShowSession2, buffer, conuserid);
	}
	}
}
public T_ShowSession2(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
 
	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}
 
	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed! %s", error);
	} else 
	{
	new clientpoints
	while (SQL_FetchRow(hndl))
	{
	clientpoints = SQL_FetchInt(hndl,0)
	playerpoints[client] = clientpoints
	new String:buffer[255];
	Format(buffer, sizeof(buffer), "SELECT COUNT(*) FROM `Player` WHERE `POINTS` >=%i", clientpoints);
	new conuserid
	conuserid = GetClientUserId(client)
	SQL_TQuery(db, T_ShowSession3, buffer, conuserid);
	}
	}
}
public T_ShowSession3(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
 
	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}
 
	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed! %s", error);
	} else 
	{
	while (SQL_FetchRow(hndl))
	{
	playerrank[client] = SQL_FetchInt(hndl,0)
	}
	new String:ConUsrSteamID[MAX_LINE_WIDTH];
	new String:buffer[255];
	GetClientAuthString(client, ConUsrSteamID, sizeof(ConUsrSteamID));
	Format(buffer, sizeof(buffer), "SELECT `KILLS`, `Death`, `PLAYTIME` FROM `Player` WHERE STEAMID = '%s'", ConUsrSteamID);
	new conuserid
	conuserid = GetClientUserId(client)
	SQL_TQuery(db, T_ShowSession4, buffer, conuserid);
	}
}
public T_ShowSession4(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
 
	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}
 
	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed! %s", error);
	} else 
	{
	new kills,death, playtime
	while (SQL_FetchRow(hndl))
	{
	kills = SQL_FetchInt(hndl,0)
	death = SQL_FetchInt(hndl,1)
	playtime = SQL_FetchInt(hndl,2)
	}
	SessionPanel(client,kills,death,playtime)
	}
}
public Action:SessionPanel(client,kills,death,playtime)
{
	new Handle:panel = CreatePanel();
	new String:buffer[255];
	SetPanelTitle(panel, "Session Panel:")
	DrawPanelItem(panel, " - Total")
	Format(buffer, sizeof(buffer), " Rank %i of %i",playerrank[client],rankedclients)
	DrawPanelText(panel, buffer)
	Format(buffer, sizeof(buffer), " %i Points",playerpoints[client])
	DrawPanelText(panel, buffer)
	Format(buffer, sizeof(buffer), " %i:%i Frags", kills , death)
	DrawPanelText(panel, buffer)
 	Format(buffer, sizeof(buffer), " Playtime: %i min", playtime)
	DrawPanelText(panel, buffer)
	DrawPanelItem(panel, " - Session")
	/*
	Format(buffer, sizeof(buffer), " Rank %i of %i",playerrank[client],rankedclients)
	DrawPanelText(panel, buffer)
	*/
	Format(buffer, sizeof(buffer), " %i Points",sessionpoints[client])
	DrawPanelText(panel, buffer)
	Format(buffer, sizeof(buffer), " %i:%i Frags", sessionkills[client] , sessiondeath[client])
	DrawPanelText(panel, buffer)
	Format(buffer, sizeof(buffer), " %i Headshots",sessionheadshotkills[client])
	DrawPanelText(panel, buffer)
	Format(buffer, sizeof(buffer), " Playtime: %i min", RoundToZero(GetClientTime(client)/60))
	DrawPanelText(panel, buffer)
	
	
	SendPanelToClient(panel, client, SessionRankPanelHandler, 20)


	CloseHandle(panel)
 
	return Plugin_Handled
}
public SessionRankPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
}
public webranking(client)
{
	if (GetConVarInt(webrank) == 1)
	{
	new String:rankurl[255]
	GetConVarString(webrankurl,rankurl, sizeof(rankurl))
	new String:showrankurl[255]
	new String:UsrSteamID[MAX_LINE_WIDTH];
	GetClientAuthString(client, UsrSteamID, sizeof(UsrSteamID));

	Format(showrankurl, sizeof(showrankurl), "%splayer.php?steamid=%s&time=%i",rankurl,UsrSteamID,GetTime())
	PrintToConsole(client, "RANK MOTDURL %s", showrankurl)
	ShowMOTDPanel(client, "Your Rank:", showrankurl, 2)
	}
	
}
public webtop(client)
{
	if (GetConVarInt(webrank) == 1)
	{
	new String:rankurl[255]
	GetConVarString(webrankurl,rankurl, sizeof(rankurl))
	new String:showrankurl[255]
	new String:UsrSteamID[MAX_LINE_WIDTH];
	GetClientAuthString(client, UsrSteamID, sizeof(UsrSteamID));

	Format(showrankurl, sizeof(showrankurl), "%splayer_ranking.php?time=%i",rankurl,GetTime())
	PrintToConsole(client, "RANK MOTDURL %s", showrankurl)
	ShowMOTDPanel(client, "Rank:", showrankurl, 2)
	}
	
}


public rankpanel(client, const String:steamid[])
{
	new String:buffer[255];
	Format(buffer, sizeof(buffer), "SELECT COUNT(*) FROM `Player`");
	Format(ranksteamidreq[client],25, "%s" ,steamid)
	SQL_TQuery(db, T_ShowRank1, buffer, GetClientUserId(client));
}
public T_ShowRank1(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
 
	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}
 
	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed! %s", error);
	} else 
	{
	while (SQL_FetchRow(hndl))
	{
	rankedclients = SQL_FetchInt(hndl,0)
	new String:buffer[255];
	Format(buffer, sizeof(buffer), "SELECT POINTS FROM Player WHERE STEAMID = '%s'", ranksteamidreq[client]);
	SQL_TQuery(db, T_ShowRank2, buffer, data);
	}
	}
}
public T_ShowRank2(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
 
	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}
 
	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed! %s", error);
	} else 
	{
	while (SQL_FetchRow(hndl))
	{
	reqplayerrankpoints[client] = SQL_FetchInt(hndl,0)
	new String:buffer[255];
	Format(buffer, sizeof(buffer), "SELECT COUNT(*) FROM `Player` WHERE `POINTS` >=%i", reqplayerrankpoints[client]);
	SQL_TQuery(db, T_ShowRank3, buffer, data);
	}
	}
}
public T_ShowRank3(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
 
	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}
 
	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed! %s", error);
	} else 
	{
	while (SQL_FetchRow(hndl))
	{
	reqplayerrank[client] = SQL_FetchInt(hndl,0)
	}
	new String:ConUsrSteamID[MAX_LINE_WIDTH];
	new String:buffer[255];
	GetClientAuthString(client, ConUsrSteamID, sizeof(ConUsrSteamID));
	Format(buffer, sizeof(buffer), "SELECT `KILLS`, `Death`, `PLAYTIME`, `NAME` FROM `Player` WHERE STEAMID = '%s'", ranksteamidreq[client]);
	SQL_TQuery(db, T_ShowRank4, buffer, data);
	}
}
public T_ShowRank4(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
	
	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}
 
	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed! %s", error);
	} else 
	{
	new kills,death, playtime
	while (SQL_FetchRow(hndl))
	{
	kills = SQL_FetchInt(hndl,0)
	death = SQL_FetchInt(hndl,1)
	playtime = SQL_FetchInt(hndl,2)
	SQL_FetchString(hndl,3, ranknamereq[client] , 32)

	}
	RankPanel(client,kills,death,playtime)
	}
}
public Action:RankPanel(client,kills,death,playtime)
{
	
	new Handle:rnkpanel = CreatePanel();
	new String:value[MAX_LINE_WIDTH]
	SetPanelTitle(rnkpanel, "Rank Panel:")
	Format(value, sizeof(value), "%t", "Rank panel Name" , ranknamereq[client]);
	DrawPanelText(rnkpanel, value)
	Format(value, sizeof(value), "Rank: %i of %i", reqplayerrank[client],rankedclients);
	DrawPanelText(rnkpanel, value)
	Format(value, sizeof(value), "%t", "Rank panel Points" , reqplayerrankpoints[client]);
	DrawPanelText(rnkpanel, value)
	Format(value, sizeof(value), "%t", "Rank panel Playtime" , playtime);
	DrawPanelText(rnkpanel, value)
	Format(value, sizeof(value), "%t", "Rank panel Kills" , kills);
	DrawPanelText(rnkpanel, value)
	Format(value, sizeof(value), "%t", "Rank panel Deaths" , death);
	DrawPanelText(rnkpanel, value)
	if (GetConVarInt(webrank) == 1)
	{
	DrawPanelText(rnkpanel, "[TYPE webrank FOR MORE DETAILS]")
	}
	DrawPanelItem(rnkpanel, "Close")
	SendPanelToClient(rnkpanel, client, SessionRankPanelHandler, 20)


	CloseHandle(rnkpanel)
 
	return Plugin_Handled
}
	public RankPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
}
public echo_rank(client){
	if(IsClientInGame(client) && !IsFakeClient(client))
	{
	new String:steamId[MAX_LINE_WIDTH]
	GetClientAuthString(client, steamId, sizeof(steamId));
	rankpanel(client, steamId)
}
}
public top10pnl(client)
{
	new String:buffer[255];
	Format(buffer, sizeof(buffer), "SELECT NAME,steamId FROM `Player` ORDER BY POINTS DESC LIMIT 0,10");
	SQL_TQuery(db, T_ShowTOP1, buffer, GetClientUserId(client));
}
public T_ShowTOP1(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
	
	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}
 
	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed! %s", error);
	} else 
	{
	new i  = 0
	new Handle:rnktoppanel = CreatePanel();
	SetPanelTitle(rnktoppanel, "Top Menu:")
	while (SQL_FetchRow(hndl))
	{
	SQL_FetchString(hndl,0, ranknametop[i] , 32)
	SQL_FetchString(hndl,1, ranksteamidtop[i] , 32)
	DrawPanelItem(rnktoppanel, ranknametop[i])
	i++
	}
	if (GetConVarInt(webrank) == 1)
	{
	DrawPanelText(rnktoppanel, "[TYPE webrank FOR MORE DETAILS]")
	}
	SendPanelToClient(rnktoppanel, client, TopPanelHandler, 20)
	CloseHandle(rnktoppanel)
 
	
	}
	return
}

public TopPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	
	if (action == MenuAction_Select)
	{
	rankpanel(param1, ranksteamidtop[param2-1])
	}
	
}
public OnConfigsExecuted()
{

plgnversion = FindConVar("sm_css_stats_version")
SetConVarString(plgnversion,PLUGIN_VERSION,true,true)
readcvars()
}

createdbtables()
{
	new len = 0;
	decl String:query[2048];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `data`");
	len += Format(query[len], sizeof(query)-len, "(`name` TEXT, `datatxt` TEXT, `dataint` INTEGER);");
	SQL_TQuery(db, T_CheckDBUptodate1, query)
}
public T_CheckDBUptodate1(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed! %s", error);
	} else {
	new String:buffer[255];
	Format(buffer, sizeof(buffer), "SELECT dataint FROM `data` where `name` = 'dbversion'");
	SQL_TQuery(db, T_CheckDBUptodate2, buffer);
	}
	
}
public T_CheckDBUptodate2(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed! %s", error);
	} else {
	if (!SQL_GetRowCount(hndl)) {
	createdb()
	
	new String:buffer[255];
	Format(buffer, sizeof(buffer), "INSERT INTO data (`name`,`dataint`) VALUES ('dbversion',%i)", DBVERSION)
	SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	}else
{
	new tmpdbversion
	while (SQL_FetchRow(hndl))
	{
	tmpdbversion = SQL_FetchInt(hndl,0)
	}
	if (tmpdbversion <= 1)
	{
		if (sqllite <= 1)
		{
		new String:buffer[255];
		Format(buffer, sizeof(buffer), "ALTER table Player add KW_awp INTEGER;")
		SQL_TQuery(db, SQLErrorCheckCallback, buffer);
		Format(buffer, sizeof(buffer), "ALTER table Player add KW_sg550 INTEGER;")
		SQL_TQuery(db, SQLErrorCheckCallback, buffer);
		Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 2 where `name` = 'dbversion'");
		SQL_TQuery(db,SQLErrorCheckCallback, buffer)
		}
		else
		{
		new String:buffer[255];
		Format(buffer, sizeof(buffer), "ALTER table Player add KW_awp int(11);")
		SQL_TQuery(db, SQLErrorCheckCallback, buffer);
		Format(buffer, sizeof(buffer), "ALTER table Player add KW_sg550 int(11);")
		SQL_TQuery(db, SQLErrorCheckCallback, buffer);
		Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 2 where `name` = 'dbversion';");
		SQL_TQuery(db,SQLErrorCheckCallback, buffer)
		}
	}
	if (tmpdbversion <= 2)
	{
		if (sqllite <= 1)
		{
		new String:buffer[255];
		Format(buffer, sizeof(buffer), "ALTER table Player add KW_g3sg9 INTEGER;")
		SQL_TQuery(db, SQLErrorCheckCallback, buffer);
		Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 3 where `name` = 'dbversion'");
		SQL_TQuery(db,SQLErrorCheckCallback, buffer)
		}
		else
		{
		new String:buffer[255];
		Format(buffer, sizeof(buffer), "ALTER table Player add KW_g3sg9 int(11);")
		SQL_TQuery(db, SQLErrorCheckCallback, buffer);
		Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 3 where `name` = 'dbversion';");
		SQL_TQuery(db,SQLErrorCheckCallback, buffer)
		}
	}
}
	initonlineplayers()
	}
}
public OnClientDisconnect(client)
{
	if (rankingactive)
{
if (GetConVarInt(neededplayercount) > GetClientCount(true))
{
	rankingactive = false
	PrintToChatAll("\x04[\x03%s\x04]\x01 Ranking Disabled: not enough players",CHATTAG)
}
}
}
readcvars()
{
	GetConVarString(CV_chattag,CHATTAG, sizeof(CHATTAG))
}
startconvarhooking()
{
	HookConVarChange(CV_chattag,OnConVarChangechattag)
}
public OnConVarChangechattag(Handle:convar, const String:oldValue[], const String:newValue[])
{
	GetConVarString(CV_chattag,CHATTAG, sizeof(CHATTAG))
}

public Event_bomb_defused(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (rankingactive)
	{
	
	new userid = GetEventInt(event, "userid")
	new usercl = GetClientOfUserId(userid)
	if (IsClientInGame(usercl) && !IsFakeClient(usercl))
	{
	new pointvalue = GetConVarInt(CV_bomb_defused)
	sessionpoints[usercl] = sessionpoints[usercl] + pointvalue
	new String:userclname[MAX_LINE_WIDTH];
	GetClientName(usercl,userclname, sizeof(userclname))
	decl String:query[512];
	new String:steamIduser[MAX_LINE_WIDTH];
	GetClientAuthString(usercl, steamIduser, sizeof(steamIduser));
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, bomb_defused = bomb_defused + 1 WHERE steamId = '%s'",pointvalue ,steamIduser);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	new pointmsgval = GetConVarInt(pointmsg)
	if (pointmsgval >= 1)
	{
	if (pointmsgval == 1)
	{
	PrintToChatAll("\x04[\x03%s\x04]\x01 %s got %i points for defusing the bomb",CHATTAG,userclname,pointvalue)
	}else
	{
	PrintToChat(usercl,"\x04[\x03%s\x04]\x01 you got %i points for defusing the bomb",CHATTAG,pointvalue)
	}
}
}
}
}

public Event_bomb_exploded(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (rankingactive)
	{
	
	new userid = GetEventInt(event, "userid")
	new usercl = GetClientOfUserId(userid)
	if (IsClientInGame(usercl) && !IsFakeClient(usercl))
	{
	new pointvalue = GetConVarInt(CV_bomb_exploded)
	sessionpoints[usercl] = sessionpoints[usercl] + pointvalue
	new String:userclname[MAX_LINE_WIDTH];
	GetClientName(usercl,userclname, sizeof(userclname))
	decl String:query[512];
	new String:steamIduser[MAX_LINE_WIDTH];
	GetClientAuthString(usercl, steamIduser, sizeof(steamIduser));
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, bomb_exploded = bomb_exploded + 1 WHERE steamId = '%s'",pointvalue ,steamIduser);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	new pointmsgval = GetConVarInt(pointmsg)
	if (pointmsgval >= 1)
	{
	if (pointmsgval == 1)
	{
	PrintToChatAll("\x04[\x03%s\x04]\x01 %s got %i points for planting exploded bomb",CHATTAG,userclname,pointvalue)
	}else
	{
	PrintToChat(usercl,"\x04[\x03%s\x04]\x01 you got %i points for planting exploded bomb",CHATTAG,pointvalue)
	}
}
}
}
}
public Event_bomb_planted(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (rankingactive)
	{
	
	new userid = GetEventInt(event, "userid")
	new usercl = GetClientOfUserId(userid)
	if (IsClientInGame(usercl) && !IsFakeClient(usercl))
	{
	new pointvalue = GetConVarInt(CV_bomb_planted)
	sessionpoints[usercl] = sessionpoints[usercl] + pointvalue
	new String:userclname[MAX_LINE_WIDTH];
	GetClientName(usercl,userclname, sizeof(userclname))
	decl String:query[512];
	new String:steamIduser[MAX_LINE_WIDTH];
	GetClientAuthString(usercl, steamIduser, sizeof(steamIduser));
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, bomb_planted = bomb_planted + 1 WHERE steamId = '%s'",pointvalue ,steamIduser);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	new pointmsgval = GetConVarInt(pointmsg)
	if (pointmsgval >= 1)
	{
	if (pointmsgval == 1)
	{
	PrintToChatAll("\x04[\x03%s\x04]\x01 %s got %i points for planting bomb",CHATTAG,userclname,pointvalue)
	}else
	{
	PrintToChat(usercl,"\x04[\x03%s\x04]\x01 you got %i points for planting bomb",CHATTAG,pointvalue)
	}
}
}
}
}
public Event_hostage_follows(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (rankingactive)
	{
	
	new userid = GetEventInt(event, "userid")
	new usercl = GetClientOfUserId(userid)
	if (IsClientInGame(usercl) && !IsFakeClient(usercl))
	{
	new pointvalue = GetConVarInt(CV_hostage_follows)
	sessionpoints[usercl] = sessionpoints[usercl] + pointvalue
	new String:userclname[MAX_LINE_WIDTH];
	GetClientName(usercl,userclname, sizeof(userclname))
	decl String:query[512];
	new String:steamIduser[MAX_LINE_WIDTH];
	GetClientAuthString(usercl, steamIduser, sizeof(steamIduser));
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, hostage_follows = hostage_follows + 1 WHERE steamId = '%s'",pointvalue ,steamIduser);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	new pointmsgval = GetConVarInt(pointmsg)
	if (pointmsgval >= 1)
	{
	if (pointmsgval == 1)
	{
	PrintToChatAll("\x04[\x03%s\x04]\x01 %s got %i points for hostage follows",CHATTAG,userclname,pointvalue)
	}else
	{
	PrintToChat(usercl,"\x04[\x03%s\x04]\x01 you got %i points for hostage follows",CHATTAG,pointvalue)
	}
}
}
}
}
public Event_hostage_killed(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (rankingactive)
	{
	
	new userid = GetEventInt(event, "userid")
	new usercl = GetClientOfUserId(userid)
	if (IsClientInGame(usercl) && !IsFakeClient(usercl))
	{

	new String:userclname[MAX_LINE_WIDTH];
	GetClientName(usercl,userclname, sizeof(userclname))
	decl String:query[512];
	new String:steamIduser[MAX_LINE_WIDTH];
	GetClientAuthString(usercl, steamIduser, sizeof(steamIduser));
	Format(query, sizeof(query), "UPDATE Player SET hostage_killed = hostage_killed + 1 WHERE steamId = '%s'",steamIduser);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	
}
}
}
public Event_hostage_rescued(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (rankingactive)
	{
	
	new userid = GetEventInt(event, "userid")
	new usercl = GetClientOfUserId(userid)
	if (IsClientInGame(usercl) && !IsFakeClient(usercl))
	{
	new pointvalue = GetConVarInt(CV_hostage_rescued)
	sessionpoints[usercl] = sessionpoints[usercl] + pointvalue
	new String:userclname[MAX_LINE_WIDTH];
	GetClientName(usercl,userclname, sizeof(userclname))
	decl String:query[512];
	new String:steamIduser[MAX_LINE_WIDTH];
	GetClientAuthString(usercl, steamIduser, sizeof(steamIduser));
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, hostage_rescued = hostage_rescued + 1 WHERE steamId = '%s'",pointvalue ,steamIduser);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	new pointmsgval = GetConVarInt(pointmsg)
	if (pointmsgval >= 1)
	{
	if (pointmsgval == 1)
	{
	PrintToChatAll("\x04[\x03%s\x04]\x01 %s got %i points for hostage rescued",CHATTAG,userclname,pointvalue)
	}else
	{
	PrintToChat(usercl,"\x04[\x03%s\x04]\x01 you got %i points for hostage rescued",CHATTAG,pointvalue)
	}
}
}
}
}