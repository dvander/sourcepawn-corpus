

#include <sourcemod>
#include <sdktools>
#include <geoip>

#define PLUGIN_VERSION "1.0.1"
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

new Handle:CV_870 = INVALID_HANDLE;
new Handle:CV_ak47 = INVALID_HANDLE;
new Handle:CV_frag = INVALID_HANDLE;
new Handle:CV_glock = INVALID_HANDLE;
new Handle:CV_glock18c = INVALID_HANDLE;
new Handle:CV_ied = INVALID_HANDLE;
new Handle:CV_m4 = INVALID_HANDLE;
new Handle:CV_mp5 = INVALID_HANDLE;
new Handle:CV_ppk = INVALID_HANDLE;
new Handle:CV_usp = INVALID_HANDLE;
new Handle:CV_revolver = INVALID_HANDLE;
new Handle:CV_arms = INVALID_HANDLE;
new Handle:CV_supershorty = INVALID_HANDLE;
new Handle:CV_winchester = INVALID_HANDLE;
new Handle:CV_axe = INVALID_HANDLE;
new Handle:CV_broom = INVALID_HANDLE;
new Handle:CV_chair = INVALID_HANDLE;
new Handle:CV_crowbar = INVALID_HANDLE;
new Handle:CV_fryingpan = INVALID_HANDLE;
new Handle:CV_golf = INVALID_HANDLE;
new Handle:CV_hammer = INVALID_HANDLE;
new Handle:CV_keyboard = INVALID_HANDLE;
new Handle:CV_machete = INVALID_HANDLE;
new Handle:CV_plank = INVALID_HANDLE;
new Handle:CV_pot = INVALID_HANDLE;
new Handle:CV_racket = INVALID_HANDLE;
new Handle:CV_shovel = INVALID_HANDLE;
new Handle:CV_sledgehammer = INVALID_HANDLE;
new Handle:CV_carrierarms = INVALID_HANDLE;
new Handle:CV_tireiron = INVALID_HANDLE;
new Handle:CV_torque = INVALID_HANDLE;

new Handle:CV_chattag = INVALID_HANDLE;
new String:CHATTAG[MAX_LINE_WIDTH]
new Handle:pointmsg = INVALID_HANDLE;
public Plugin:myinfo = 
{
	name = "ZP:S Stats",
	author = "Master DJ",
	description = "ZPS Player Stats And Ranking/Point System",
	version = PLUGIN_VERSION,
	url = "http://compactaim.de"
};
public OnPluginStart()
{
	LoadTranslations("zpsstats.phrases");
	openDatabaseConnection()
	createdbtables()
	convarcreating()
	CreateConVar("sm_zps_stats_version", PLUGIN_VERSION, "zps Player Stats", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
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
	if (SQL_CheckConfig("zpsstats"))
	{
	new String:error[255]
	db = SQL_Connect("zpsstats",true,error, sizeof(error))
	if (db == INVALID_HANDLE)
	{
	PrintToServer("Failed to connect: %s", error)
	}
	else 
	{
	LogMessage("Database Connection MYSQL (CONNECTED) with db config");
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
	db = SQL_ConnectEx(SQL_GetDriver("sqlite"), "", "", "", "zpsstats", error, sizeof(error), true, 0);	
	if (db == INVALID_HANDLE)
	{
	LogMessage("Failed to connect: %s", error)
	}
	else 
	{
	LogMessage("Database Connection SQLLITE (CONNECTED)");
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
	len += Format(query[len], sizeof(query)-len, " `KW_870` int(11) NOT NULL , `KW_ak47` int(11) NOT NULL , `KW_frag` int(11) NOT NULL , `KW_glock` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KW_glock18c` int(11) NOT NULL , `KW_ied` int(11) NOT NULL , `KW_m4` int(11) NOT NULL , `KW_mp5` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KW_ppk` int(11) NOT NULL , `KW_usp` int(11) NOT NULL , `KW_revolver` int(11) NOT NULL , `KW_arms` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KW_supershorty` int(11) NOT NULL , `KW_winchester` int(11) NOT NULL , `KW_axe` int(11) NOT NULL , `KW_broom` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KW_chair` int(11) NOT NULL , `KW_crowbar` int(11) NOT NULL , `KW_fryingpan` int(11) NOT NULL , `KW_golf` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KW_hammer` int(11) NOT NULL , `KW_keyboard` int(11) NOT NULL , `KW_machete` int(11) NOT NULL , `shovel` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `sledgehammer` int(11) NOT NULL , `carrierarms` int(11) NOT NULL , `tireiron` int(11) NOT NULL , `hostage_killed` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `torque` int(11) NOT NULL , `KW_pot` int(11) NOT NULL , `KW_plank` int(11) NOT NULL , `KW_racket` int(11) NOT NULL , PRIMARY KEY (`NAME`));");

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
	len += Format(query[len], sizeof(query)-len, " `KW_870` INTEGER, `KW_ak47` INTEGER, `KW_frag` INTEGER, `KW_glock` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `KW_glock18c` INTEGER, `KW_ied` INTEGER, `KW_m4` INTEGER, `KW_mp5` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `KW_ppk` INTEGER, `KW_usp` INTEGER, `KW_revolver` INTEGER, `KW_arms` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `KW_supershorty` INTEGER, `KW_winchester` INTEGER, `KW_axe` INTEGER, `KW_broom` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `KW_chair` INTEGER, `KW_crowbar` INTEGER, `KW_fryingpan` INTEGER, `KW_golf` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `KW_hammer` INTEGER, `KW_keyboard` INTEGER, `KW_machete` INTEGER, `shovel` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `sledgehammer` INTEGER, `carrierarms` INTEGER, `tireiron` INTEGER, `hostage_killed` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `torque` INTEGER, `KW_pot` INTEGER, `KW_plank` INTEGER, `KW_racket` INTEGER);");
	
	
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
	len += Format(query[len], sizeof(query)-len, " `KW_870` int(11) NOT NULL , `KW_ak47` int(11) NOT NULL , `KW_frag` int(11) NOT NULL , `KW_glock` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KW_glock18c` int(11) NOT NULL , `KW_ied` int(11) NOT NULL , `KW_m4` int(11) NOT NULL , `KW_mp5` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KW_ppk` int(11) NOT NULL , `KW_usp` int(11) NOT NULL , `KW_revolver` int(11) NOT NULL , `KW_arms` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KW_supershorty` int(11) NOT NULL , `KW_winchester` int(11) NOT NULL , `KW_axe` int(11) NOT NULL , `KW_broom` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KW_chair` int(11) NOT NULL , `KW_crowbar` int(11) NOT NULL , `KW_fryingpan` int(11) NOT NULL , `KW_golf` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `KW_hammer` int(11) NOT NULL , `KW_keyboard` int(11) NOT NULL , `KW_machete` int(11) NOT NULL , `shovel` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `sledgehammer` int(11) NOT NULL , `carrierarms` int(11) NOT NULL , `tireiron` int(11) NOT NULL , `hostage_killed` int(11) NOT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `torque` int(11) NOT NULL , PRIMARY KEY (`NAME`));");

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
	
	CV_870 = CreateConVar("rank_kill_870","3","Set the points the attacker get");
	CV_ak47 = CreateConVar("rank_kill_ak47","3","Set the points the attacker get");
	CV_frag = CreateConVar("rank_kill_frag","6","Set the points the attacker get");
	CV_glock = CreateConVar("rank_kill_glock","7","Set the points the attacker get");
	CV_glock18c = CreateConVar("rank_kill_glock18c","7","Set the points the attacker get");
	CV_ied = CreateConVar("rank_kill_ied","10","Set the points the attacker get");
	CV_m4 = CreateConVar("rank_kill_m4","3","Set the points the attacker get");
	CV_mp5 = CreateConVar("rank_kill_mp5","3","Set the points the attacker get");
	CV_ppk = CreateConVar("rank_kill_ppk","9","Set the points the attacker get");
	CV_usp = CreateConVar("rank_kill_usp","5","Set the points the attacker get");
	CV_revolver = CreateConVar("rank_kill_revolver","3","Set the points the attacker get");
	CV_arms = CreateConVar("rank_kill_arms","6","Set the points the attacker get");
	CV_supershorty = CreateConVar("rank_kill_supershorty","4","Set the points the attacker get");
	CV_winchester = CreateConVar("rank_kill_winchester","4","Set the points the attacker get");
	CV_axe = CreateConVar("rank_kill_axe","6","Set the points the attacker get");
	CV_broom = CreateConVar("rank_kill_broom","7","Set the points the attacker get");
	CV_chair = CreateConVar("rank_kill_chair","8","Set the points the attacker get");
	CV_crowbar = CreateConVar("rank_kill_crowbar","5","Set the points the attacker get");
	CV_fryingpan = CreateConVar("rank_kill_fryingpan","5","Set the points the attacker get");
	CV_golf = CreateConVar("rank_kill_golf","5","Set the points the attacker get");
	CV_hammer = CreateConVar("rank_kill_hammer","9","Set the points the attacker get");
	CV_keyboard = CreateConVar("rank_kill_keyboard","12","Set the points the attacker get");
	CV_machete = CreateConVar("rank_kill_machete","6","Set the points the attacker get");
	CV_plank = CreateConVar("rank_kill_plank","7","Set the points the attacker get");
	CV_pot = CreateConVar("rank_kill_pot","6","Set the points the attacker get");
	CV_racket = CreateConVar("rank_kill_racket","6","Set the points the attacker get");
	CV_chattag = CreateConVar("rank_chattag","RANK","Set the Chattag");
	CV_shovel = CreateConVar("rank_shovel","5","Set the points");
	CV_sledgehammer = CreateConVar("rank_sledgehammer","4","Set the points");
	CV_carrierarms = CreateConVar("rank_carrierarms","8","Set the points");
	CV_tireiron = CreateConVar("rank_tireiron","7","Set the points");
	CV_torque = CreateConVar("rank_torque","5","Set the points");
	}
public starteventhooking() 
{
	HookEvent("player_death", Event_PlayerDeath)
	HookEvent("round_end", Event_round_end)
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
	if (strcmp(weapon[0], "870", false) == 0)
	{
	pointvalue = GetConVarInt(CV_870)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_870 = KW_870 + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "ak47", false) == 0)
	{
	pointvalue = GetConVarInt(CV_ak47)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_ak47 = KW_ak47 + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "frag", false) == 0)
	{
	pointvalue = GetConVarInt(CV_frag)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_frag = KW_frag + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "glock", false) == 0)
	{
	pointvalue = GetConVarInt(CV_glock)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_glock = KW_glock + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "glock18c", false) == 0)
	{
	pointvalue = GetConVarInt(CV_glock18c)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_glock18c = KW_glock18c + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "ied", false) == 0)
	{
	pointvalue = GetConVarInt(CV_ied)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_ied = KW_ied + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "m4", false) == 0)
	{
	pointvalue = GetConVarInt(CV_m4)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_m4 = KW_m4 + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "mp5", false) == 0)
	{
	pointvalue = GetConVarInt(CV_mp5)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_mp5 = KW_mp5 + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "ppk", false) == 0)
	{
	pointvalue = GetConVarInt(CV_ppk)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_ppk = KW_ppk + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "usp", false) == 0)
	{
	pointvalue = GetConVarInt(CV_usp)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_usp = KW_usp + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "revolver", false) == 0)
	{
	pointvalue = GetConVarInt(CV_revolver)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_revolver = KW_revolver + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "arms", false) == 0)
	{
	pointvalue = GetConVarInt(CV_arms)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_arms = KW_arms + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "supershorty", false) == 0)
	{
	pointvalue = GetConVarInt(CV_supershorty)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_supershorty = KW_supershorty + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "winchester", false) == 0)
	{
	pointvalue = GetConVarInt(CV_winchester)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_winchester = KW_winchester + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "axe", false) == 0)
	{
	pointvalue = GetConVarInt(CV_axe)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_axe = KW_axe + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "broom", false) == 0)
	{
	pointvalue = GetConVarInt(CV_broom)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_broom = KW_broom + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "chair", false) == 0)
	{
	pointvalue = GetConVarInt(CV_chair)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_chair = KW_chair + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "crowbar", false) == 0)
	{
	pointvalue = GetConVarInt(CV_crowbar)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_crowbar = KW_crowbar + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "fryingpan", false) == 0)
	{
	pointvalue = GetConVarInt(CV_fryingpan)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_fryingpan = KW_fryingpan + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "golf", false) == 0)
	{
	pointvalue = GetConVarInt(CV_golf)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_golf = KW_golf + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "hammer", false) == 0)
	{
	pointvalue = GetConVarInt(CV_hammer)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_hammer = KW_hammer + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "keyboard", false) == 0)
	{
	pointvalue = GetConVarInt(CV_keyboard)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_keyboard = KW_keyboard + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "machete", false) == 0)
	{
	pointvalue = GetConVarInt(CV_machete)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_machete = KW_machete + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "pot", false) == 0)
	{
	pointvalue = GetConVarInt(CV_pot)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_pot = KW_pot + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "plank", false) == 0)
	{
	pointvalue = GetConVarInt(CV_plank)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_plank = KW_plank + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "racket", false) == 0)
	{
	pointvalue = GetConVarInt(CV_racket)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_racket = KW_racket + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "shovel", false) == 0)
	{
	pointvalue = GetConVarInt(CV_shovel)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_shovel = KW_shovel + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "sledgehammer", false) == 0)
	{
	pointvalue = GetConVarInt(CV_sledgehammer)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_sledgehammer = KW_sledgehammer + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "carrierarms", false) == 0)
	{
	pointvalue = GetConVarInt(CV_carrierarms)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_carrierarms = KW_carrierarms + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "tireiron", false) == 0)
	{
	pointvalue = GetConVarInt(CV_tireiron)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_tireiron = KW_tireiron + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	} else if (strcmp(weapon[0], "tireiron", false) == 0)
	{
	pointvalue = GetConVarInt(CV_torque)
	Format(query, sizeof(query), "UPDATE Player SET POINTS = POINTS + %i, KILLS = KILLS + 1, KW_torque = KW_torque + 1 WHERE steamId = '%s'",pointvalue ,steamIdattacker);
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
	DrawPanelText(infopanel, "E-Mail dj_jonezy@live.co.uk")
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
	Format(buffer, sizeof(buffer), "INSERT INTO Player VALUES('%s','%s',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);", ClientSteamID,clientname )
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
	PrintToChatAll("\x04[\x03%s\x04]\x01 %s connected from%s. \x04[\x03Rank: %i of %i\x04]",CHATTAG, clientname, country,onconrank[client],rankedclients)
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

plgnversion = FindConVar("sm_zps_stats_version")
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
		Format(buffer, sizeof(buffer), "ALTER table Player add KW_g3sg1 INTEGER;")
		SQL_TQuery(db, SQLErrorCheckCallback, buffer);
		Format(buffer, sizeof(buffer), "UPDATE data SET dataint = 3 where `name` = 'dbversion'");
		SQL_TQuery(db,SQLErrorCheckCallback, buffer)
		}
		else
		{
		new String:buffer[255];
		Format(buffer, sizeof(buffer), "ALTER table Player add KW_g3sg1 int(11);")
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