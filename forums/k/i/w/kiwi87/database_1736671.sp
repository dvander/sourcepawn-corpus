/*	Database Definitions	*/
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
new Handle:hDatabase = INVALID_HANDLE;

// Damage Carrier
new PistolDamage[MAXPLAYERS + 1][MAXPLAYERS + 1];
new MeleeDamage[MAXPLAYERS + 1][MAXPLAYERS + 1];
new UziDamage[MAXPLAYERS + 1][MAXPLAYERS + 1];
new ShotgunDamage[MAXPLAYERS + 1][MAXPLAYERS + 1];
new SniperDamage[MAXPLAYERS + 1][MAXPLAYERS + 1];
new RifleDamage[MAXPLAYERS + 1][MAXPLAYERS + 1];

new MountedGunsPurchased[MAXPLAYERS + 1];


// Survivor XP Levels
new Pi[MAXPLAYERS + 1][3];	// Pistol
new Me[MAXPLAYERS + 1][3];	// Melee
new Uz[MAXPLAYERS + 1][3];	// Uzi
new Sh[MAXPLAYERS + 1][3];	// Shotgun
new Sn[MAXPLAYERS + 1][3];	// Sniper
new Ri[MAXPLAYERS + 1][3];	// Rifle
new Gr[MAXPLAYERS + 1][3];	// Grenade
new It[MAXPLAYERS + 1][3];	// Item
new Ph[MAXPLAYERS + 1][3];	// Physical

// Infected XP Levels
new Hu[MAXPLAYERS + 1][3];	// Hunter
new Sm[MAXPLAYERS + 1][3];	// Smoker
new Bo[MAXPLAYERS + 1][3];	// Boomer
new Jo[MAXPLAYERS + 1][3];	// Jockey
new Ch[MAXPLAYERS + 1][3];	// Charger
new Sp[MAXPLAYERS + 1][3];	// Spitter
new Ta[MAXPLAYERS + 1][3];	// Tank
new In[MAXPLAYERS + 1][3];	// Infected

new SetHealthTimer[MAXPLAYERS + 1];

new AIHunter[3];
new AISmoker[3];
new AIBoomer[3];
new AIJockey[3];
new AICharger[3];
new AISpitter[3];
new AITank[3];
new AIInfected[3];

// Presets
new String:Mw[MAXPLAYERS + 1][5][64];
new String:Sw[MAXPLAYERS + 1][5][64];
new String:Hi[MAXPLAYERS + 1][5][64];
new String:Gi[MAXPLAYERS + 1][5][64];
new Ul[MAXPLAYERS + 1][2];

// Achievements
new Ach[MAXPLAYERS + 1][5];
new AchDate[MAXPLAYERS + 1];
new String:AchievementName[5][256];

new InfectedLevel[MAXPLAYERS + 1];
new SurvivorLevel[MAXPLAYERS + 1];

new cmds[MAXPLAYERS + 1];

new bool:DatabaseLoaded;


// Player chat colors
new String:ChatColor[MAXPLAYERS + 1][4][MAX_CHAT_LENGTH];

// Infected XP Levels

_Database_OnPluginStart()
{
	// So we only initialize it once.
	if (!DatabaseLoaded)
	{
		MySQL_Init();
		DatabaseLoaded = true;

		// Set the achievement texts
		decl String:DataInput[256];
		Format(DataInput, sizeof(DataInput), "Cure The Infection");
		AchievementName[0] = DataInput;
		Format(DataInput, sizeof(DataInput), "Special What?");
		AchievementName[1] = DataInput;
		Format(DataInput, sizeof(DataInput), "Playing Dress-Up");
		AchievementName[2] = DataInput;
		Format(DataInput, sizeof(DataInput), "Special Pain In The Ass");
		AchievementName[3] = DataInput;
		Format(DataInput, sizeof(DataInput), "The Flying Squirrel");
		AchievementName[4] = DataInput;
	}
}

MySQL_Init()
{
	new String:Error[255];
	//SQL_TConnect(hDatabase, "usepoints5");
	//hDatabase = SQL_DefConnect(Error, sizeof(Error));
	hDatabase = SQL_Connect("rpg5", false, Error, sizeof(Error));
	
	if (hDatabase == INVALID_HANDLE)
	{
		PrintToServer("Failed To Connect To Database: %s", Error);
		LogError("Failed To Connect To Database: %s", Error);
	}
	SQL_FastQuery(hDatabase, "SET NAMES \"UTF8\""); 
	decl String:TQuery[512];
	
	/*	Player STEAM_ID (How we identify the user)	*/
	
	Format(TQuery, sizeof(TQuery), "CREATE TABLE IF NOT EXISTS `slevels` (`steam_id` varchar(32) NOT NULL, PRIMARY KEY (`steam_id`)) ENGINE=MyISAM;");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "CREATE TABLE IF NOT EXISTS `ilevels` (`steam_id` varchar(32) NOT NULL, PRIMARY KEY (`steam_id`)) ENGINE=MyISAM;");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "CREATE TABLE IF NOT EXISTS `player_cat` (`steam_id` varchar(32) NOT NULL, PRIMARY KEY (`steam_id`)) ENGINE=MyISAM;");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);

	Format(TQuery, sizeof(TQuery), "CREATE TABLE IF NOT EXISTS `multiplier_cat` (`steam_id` varchar(32) NOT NULL, PRIMARY KEY (`steam_id`)) ENGINE=MyISAM;");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "CREATE TABLE IF NOT EXISTS `nemesis_cat` (`steam_id` varchar(32) NOT NULL, PRIMARY KEY (`steam_id`)) ENGINE=MyISAM;");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "CREATE TABLE IF NOT EXISTS `sky_store_cat` (`steam_id` varchar(32) NOT NULL, PRIMARY KEY (`steam_id`)) ENGINE=MyISAM;");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "CREATE TABLE IF NOT EXISTS `presets` (`steam_id` varchar(32) NOT NULL, PRIMARY KEY (`steam_id`)) ENGINE=MyISAM;");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "CREATE TABLE IF NOT EXISTS `map_records` (`map_name` varchar(32) NOT NULL, PRIMARY KEY (`map_name`)) ENGINE=MyISAM;");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "CREATE TABLE IF NOT EXISTS `mounted_cat` (`steam_id` varchar(32) NOT NULL, PRIMARY KEY (`steam_id`)) ENGINE=MyISAM;");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "CREATE TABLE IF NOT EXISTS `chat_color` (`steam_id` varchar(32) NOT NULL, PRIMARY KEY (`steam_id`)) ENGINE=MyISAM;");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "CREATE TABLE IF NOT EXISTS `time` (`steam_id` varchar(32) NOT NULL, PRIMARY KEY (`steam_id`)) ENGINE=MyISAM;");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "CREATE TABLE IF NOT EXISTS `daily_achieve` (`steam_id` varchar(32) NOT NULL, PRIMARY KEY (`steam_id`)) ENGINE=MyISAM;");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "CREATE TABLE IF NOT EXISTS `achieve` (`steam_id` varchar(32) NOT NULL, PRIMARY KEY (`steam_id`)) ENGINE=MyISAM;");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "CREATE TABLE IF NOT EXISTS `trails` (`steam_id` varchar(32) NOT NULL, PRIMARY KEY (`steam_id`)) ENGINE=MyISAM;");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);

	/*	Bullet Trails	*/

	Format(TQuery, sizeof(TQuery), "ALTER TABLE `trails` ADD IF NOT EXISTS `id` varchar(32) NOT NULL DEFAULT 'none';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `trails` ADD IF NOT EXISTS `enable` int(4) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);

	Format(TQuery, sizeof(TQuery), "ALTER TABLE `trails` ADD IF NOT EXISTS `pi0` int(4) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `trails` ADD IF NOT EXISTS `pi1` int(4) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `trails` ADD IF NOT EXISTS `pi2` int(4) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `trails` ADD IF NOT EXISTS `pi3` int(4) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);

	Format(TQuery, sizeof(TQuery), "ALTER TABLE `trails` ADD IF NOT EXISTS `uz0` int(4) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `trails` ADD IF NOT EXISTS `uz1` int(4) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `trails` ADD IF NOT EXISTS `uz2` int(4) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `trails` ADD IF NOT EXISTS `uz3` int(4) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);

	Format(TQuery, sizeof(TQuery), "ALTER TABLE `trails` ADD IF NOT EXISTS `sh0` int(4) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `trails` ADD IF NOT EXISTS `sh1` int(4) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `trails` ADD IF NOT EXISTS `sh2` int(4) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `trails` ADD IF NOT EXISTS `sh3` int(4) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);

	Format(TQuery, sizeof(TQuery), "ALTER TABLE `trails` ADD IF NOT EXISTS `ri0` int(4) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `trails` ADD IF NOT EXISTS `ri1` int(4) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `trails` ADD IF NOT EXISTS `ri2` int(4) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `trails` ADD IF NOT EXISTS `ri3` int(4) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);

	Format(TQuery, sizeof(TQuery), "ALTER TABLE `trails` ADD IF NOT EXISTS `sn0` int(4) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `trails` ADD IF NOT EXISTS `sn1` int(4) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `trails` ADD IF NOT EXISTS `sn2` int(4) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `trails` ADD IF NOT EXISTS `sn3` int(4) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);

	/*	Permanent Achievements	*/
	
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `achieve` ADD IF NOT EXISTS `id` varchar(32) NOT NULL DEFAULT 'none';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `achieve` ADD IF NOT EXISTS `cstm` int(4) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);

	/* Daily Achievements */

	Format(TQuery, sizeof(TQuery), "ALTER TABLE `daily_achieve` ADD IF NOT EXISTS `id` varchar(32) NOT NULL DEFAULT 'none';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `daily_achieve` ADD IF NOT EXISTS `ck` int(4) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `daily_achieve` ADD IF NOT EXISTS `sik` int(4) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `daily_achieve` ADD IF NOT EXISTS `sid` int(4) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `daily_achieve` ADD IF NOT EXISTS `hpd` int(4) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `daily_achieve` ADD IF NOT EXISTS `day` int(4) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);

	/*	Player Time Played	*/

	Format(TQuery, sizeof(TQuery), "ALTER TABLE `time` ADD IF NOT EXISTS `name` varchar(32) NOT NULL DEFAULT 'none';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);

	Format(TQuery, sizeof(TQuery), "ALTER TABLE `time` ADD IF NOT EXISTS `td` int(4) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `time` ADD IF NOT EXISTS `th` int(4) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `time` ADD IF NOT EXISTS `tm` int(4) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `time` ADD IF NOT EXISTS `ts` int(4) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);

	Format(TQuery, sizeof(TQuery), "ALTER TABLE `time` ADD IF NOT EXISTS `id` int(4) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `time` ADD IF NOT EXISTS `ih` int(4) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `time` ADD IF NOT EXISTS `im` int(4) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `time` ADD IF NOT EXISTS `is` int(4) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);

	Format(TQuery, sizeof(TQuery), "ALTER TABLE `time` ADD IF NOT EXISTS `sd` int(4) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `time` ADD IF NOT EXISTS `sh` int(4) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `time` ADD IF NOT EXISTS `sm` int(4) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `time` ADD IF NOT EXISTS `ss` int(4) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `time` ADD IF NOT EXISTS `infl` int(4) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `time` ADD IF NOT EXISTS `survl` int(4) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `time` ADD IF NOT EXISTS `bty` int(16) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);

	/*	Player Chat Colors	*/
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `chat_color` ADD IF NOT EXISTS `paranthesis` varchar(8) NOT NULL DEFAULT 'def';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `chat_color` ADD IF NOT EXISTS `team` varchar(8) NOT NULL DEFAULT 'def';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `chat_color` ADD IF NOT EXISTS `name` varchar(8) NOT NULL DEFAULT 'def';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `chat_color` ADD IF NOT EXISTS `text` varchar(8) NOT NULL DEFAULT 'def';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);

	Format(TQuery, sizeof(TQuery), "ALTER TABLE `player_cat` ADD IF NOT EXISTS `last_name_used` varchar(32) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `player_cat` ADD IF NOT EXISTS `micro_menu` int(32) NOT NULL DEFAULT '1';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `player_cat` ADD IF NOT EXISTS `points_display` int(32) NOT NULL DEFAULT '1';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `player_cat` ADD IF NOT EXISTS `cmds` int(32) NOT NULL DEFAULT '1';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);

	/*		SURVIVOR LEVEL STUFF		*/
	//NAME
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `slevels` ADD IF NOT EXISTS `id` varchar(32) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	//PHYSICAL
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `slevels` ADD IF NOT EXISTS `phx` int(16) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `slevels` ADD IF NOT EXISTS `phn` int(16) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `slevels` ADD IF NOT EXISTS `phl` int(16) NOT NULL DEFAULT '1';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	//PISTOL
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `slevels` ADD IF NOT EXISTS `pix` int(16) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `slevels` ADD IF NOT EXISTS `pin` int(16) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `slevels` ADD IF NOT EXISTS `pil` int(16) NOT NULL DEFAULT '1';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	//MELEE
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `slevels` ADD IF NOT EXISTS `mex` int(16) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `slevels` ADD IF NOT EXISTS `men` int(16) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `slevels` ADD IF NOT EXISTS `mel` int(16) NOT NULL DEFAULT '1';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	//UZI
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `slevels` ADD IF NOT EXISTS `uzx` int(16) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `slevels` ADD IF NOT EXISTS `uzn` int(16) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `slevels` ADD IF NOT EXISTS `uzl` int(16) NOT NULL DEFAULT '1';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	//SHOTGUN
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `slevels` ADD IF NOT EXISTS `shx` int(16) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `slevels` ADD IF NOT EXISTS `shn` int(16) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `slevels` ADD IF NOT EXISTS `shl` int(16) NOT NULL DEFAULT '1';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	//SNIPER
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `slevels` ADD IF NOT EXISTS `snx` int(16) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `slevels` ADD IF NOT EXISTS `snn` int(16) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `slevels` ADD IF NOT EXISTS `snl` int(16) NOT NULL DEFAULT '1';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	//RIFLE
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `slevels` ADD IF NOT EXISTS `rix` int(16) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `slevels` ADD IF NOT EXISTS `rin` int(16) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `slevels` ADD IF NOT EXISTS `ril` int(16) NOT NULL DEFAULT '1';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	//GRENADE
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `slevels` ADD IF NOT EXISTS `grx` int(16) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `slevels` ADD IF NOT EXISTS `grn` int(16) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `slevels` ADD IF NOT EXISTS `grl` int(16) NOT NULL DEFAULT '1';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	//ITEM
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `slevels` ADD IF NOT EXISTS `itx` int(16) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `slevels` ADD IF NOT EXISTS `itn` int(16) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `slevels` ADD IF NOT EXISTS `itl` int(16) NOT NULL DEFAULT '1';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);

	/*		INFECTED LEVEL STUFF		*/
	//NAME
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `ilevels` ADD IF NOT EXISTS `id` varchar(32) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	//INFECTED
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `ilevels` ADD IF NOT EXISTS `inx` int(16) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `ilevels` ADD IF NOT EXISTS `inn` int(16) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `ilevels` ADD IF NOT EXISTS `inl` int(16) NOT NULL DEFAULT '1';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	//HUNTER
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `ilevels` ADD IF NOT EXISTS `hux` int(16) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `ilevels` ADD IF NOT EXISTS `hun` int(16) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `ilevels` ADD IF NOT EXISTS `hul` int(16) NOT NULL DEFAULT '1';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `ilevels` ADD IF NOT EXISTS `huw` int(16) NOT NULL DEFAULT '1';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	//SMOKER
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `ilevels` ADD IF NOT EXISTS `smx` int(16) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `ilevels` ADD IF NOT EXISTS `smn` int(16) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `ilevels` ADD IF NOT EXISTS `sml` int(16) NOT NULL DEFAULT '1';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `ilevels` ADD IF NOT EXISTS `smw` int(16) NOT NULL DEFAULT '1';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	//BOOMER
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `ilevels` ADD IF NOT EXISTS `box` int(16) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `ilevels` ADD IF NOT EXISTS `bon` int(16) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `ilevels` ADD IF NOT EXISTS `bol` int(16) NOT NULL DEFAULT '1';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `ilevels` ADD IF NOT EXISTS `bow` int(16) NOT NULL DEFAULT '1';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	//JOCKEY
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `ilevels` ADD IF NOT EXISTS `jox` int(16) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `ilevels` ADD IF NOT EXISTS `jon` int(16) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `ilevels` ADD IF NOT EXISTS `jol` int(16) NOT NULL DEFAULT '1';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `ilevels` ADD IF NOT EXISTS `jow` int(16) NOT NULL DEFAULT '1';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	//CHARGER
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `ilevels` ADD IF NOT EXISTS `chx` int(16) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `ilevels` ADD IF NOT EXISTS `chn` int(16) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `ilevels` ADD IF NOT EXISTS `chl` int(16) NOT NULL DEFAULT '1';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `ilevels` ADD IF NOT EXISTS `chw` int(16) NOT NULL DEFAULT '1';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	//SPITTER
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `ilevels` ADD IF NOT EXISTS `spx` int(16) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `ilevels` ADD IF NOT EXISTS `spn` int(16) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `ilevels` ADD IF NOT EXISTS `spl` int(16) NOT NULL DEFAULT '1';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `ilevels` ADD IF NOT EXISTS `spw` int(16) NOT NULL DEFAULT '1';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	//TANK
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `ilevels` ADD IF NOT EXISTS `tax` int(16) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `ilevels` ADD IF NOT EXISTS `tan` int(16) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `ilevels` ADD IF NOT EXISTS `tal` int(16) NOT NULL DEFAULT '1';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `ilevels` ADD IF NOT EXISTS `taw` int(16) NOT NULL DEFAULT '1';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);

	/*	Survivor Persistent Information		*/

	Format(TQuery, sizeof(TQuery), "ALTER TABLE `multiplier_cat` ADD IF NOT EXISTS `xp_timer` int(32) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `nemesis_cat` ADD IF NOT EXISTS `nemesis_steamid` varchar(32) NOT NULL DEFAULT 'none';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `presets` ADD IF NOT EXISTS `id` varchar(32) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `presets` ADD IF NOT EXISTS `mw1` varchar(32) NOT NULL DEFAULT 'none';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `presets` ADD IF NOT EXISTS `mw2` varchar(32) NOT NULL DEFAULT 'none';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `presets` ADD IF NOT EXISTS `mw3` varchar(32) NOT NULL DEFAULT 'none';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `presets` ADD IF NOT EXISTS `mw4` varchar(32) NOT NULL DEFAULT 'none';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `presets` ADD IF NOT EXISTS `mw5` varchar(32) NOT NULL DEFAULT 'none';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `presets` ADD IF NOT EXISTS `sw1` varchar(32) NOT NULL DEFAULT 'none';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `presets` ADD IF NOT EXISTS `sw2` varchar(32) NOT NULL DEFAULT 'none';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `presets` ADD IF NOT EXISTS `sw3` varchar(32) NOT NULL DEFAULT 'none';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `presets` ADD IF NOT EXISTS `sw4` varchar(32) NOT NULL DEFAULT 'none';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `presets` ADD IF NOT EXISTS `sw5` varchar(32) NOT NULL DEFAULT 'none';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `presets` ADD IF NOT EXISTS `hi1` varchar(32) NOT NULL DEFAULT 'none';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `presets` ADD IF NOT EXISTS `hi2` varchar(32) NOT NULL DEFAULT 'none';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `presets` ADD IF NOT EXISTS `hi3` varchar(32) NOT NULL DEFAULT 'none';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `presets` ADD IF NOT EXISTS `hi4` varchar(32) NOT NULL DEFAULT 'none';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `presets` ADD IF NOT EXISTS `hi5` varchar(32) NOT NULL DEFAULT 'none';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `presets` ADD IF NOT EXISTS `gi1` varchar(32) NOT NULL DEFAULT 'none';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `presets` ADD IF NOT EXISTS `gi2` varchar(32) NOT NULL DEFAULT 'none';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `presets` ADD IF NOT EXISTS `gi3` varchar(32) NOT NULL DEFAULT 'none';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `presets` ADD IF NOT EXISTS `gi4` varchar(32) NOT NULL DEFAULT 'none';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `presets` ADD IF NOT EXISTS `gi5` varchar(32) NOT NULL DEFAULT 'none';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `presets` ADD IF NOT EXISTS `unlocked4` int(32) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `presets` ADD IF NOT EXISTS `unlocked5` int(32) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);

	Format(TQuery, sizeof(TQuery), "ALTER TABLE `map_records` ADD IF NOT EXISTS `best_kills` int(32) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `map_records` ADD IF NOT EXISTS `player_name` varchar(32) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `map_records` ADD IF NOT EXISTS `best_headshots` int(32) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `map_records` ADD IF NOT EXISTS `best_headshots_name` varchar(32) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `map_records` ADD IF NOT EXISTS `best_survivor_dmg` int(32) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `map_records` ADD IF NOT EXISTS `best_survivor_dmg_name` varchar(32) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `map_records` ADD IF NOT EXISTS `best_infected_damage` int(32) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `map_records` ADD IF NOT EXISTS `infected_name` varchar(32) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `map_records` ADD IF NOT EXISTS `best_healing` int(32) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `map_records` ADD IF NOT EXISTS `healing_name` varchar(32) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `map_records` ADD IF NOT EXISTS `best_rescuer` int(32) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `map_records` ADD IF NOT EXISTS `rescuer_name` varchar(32) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
	
	Format(TQuery, sizeof(TQuery), "ALTER TABLE `sky_store_cat` ADD IF NOT EXISTS `sky_points` int(32) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);

	Format(TQuery, sizeof(TQuery), "ALTER TABLE `mounted_cat` ADD IF NOT EXISTS `purchased` int(16) NOT NULL DEFAULT '0';");
	SQL_TQuery(hDatabase, QueryCreateTable, TQuery);
}

public QueryCreateTable( Handle:owner, Handle:hndl, const String:error[], any:data)
{ 
	if ( hndl == INVALID_HANDLE )
	{
		LogError( "%s", error ); 
		
		return;
	} 
}

public QuerySetData( Handle:owner, Handle:hndl, const String:error[], any:data)
{ 
	if ( hndl == INVALID_HANDLE )
	{
		LogError( "%s", error ); 
		
		return;
	} 
}

public QueryMapData( Handle:owner, Handle:hndl, const String:error[], any:data)
{ 
	if ( hndl != INVALID_HANDLE )
	{
		while ( SQL_FetchRow(hndl) ) 
		{
			MapBestKills = SQL_FetchInt(hndl, 0);
			SQL_FetchString(hndl, 1, MapBestKillsName, sizeof(MapBestKillsName));
			MapBestSurvivorHS = SQL_FetchInt(hndl, 2);
			SQL_FetchString(hndl, 3, MapBestSurvivorHSName, sizeof(MapBestSurvivorHSName));
			MapBestSurvivorDamage = SQL_FetchInt(hndl, 4);
			SQL_FetchString(hndl, 5, MapBestSurvivorDamageName, sizeof(MapBestSurvivorDamageName));
			MapBestInfectedDamage = SQL_FetchInt(hndl, 6);
			SQL_FetchString(hndl, 7, MapBestInfectedDamageName, sizeof(MapBestInfectedDamageName));
			MapBestHealing = SQL_FetchInt(hndl, 8);
			SQL_FetchString(hndl, 9, MapBestHealingName, sizeof(MapBestHealingName));
			MapBestRescuer = SQL_FetchInt(hndl, 10);
			SQL_FetchString(hndl, 11, MapBestHealingName, sizeof(MapBestRescuerName));
			
		}
	} 
	else
	{
		LogError( "%s", error ); 
		
		return;
	}
}

public QueryTimeData( Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl != INVALID_HANDLE )
	{
		while ( SQL_FetchRow(hndl) )
		{
			decl String:Name[MAX_NAME_LENGTH];
			SQL_FetchString(hndl, 0, Name, sizeof(Name));
			TimePlayed[data][0] = SQL_FetchInt(hndl, 1);
			TimePlayed[data][1] = SQL_FetchInt(hndl, 2);
			TimePlayed[data][2] = SQL_FetchInt(hndl, 3);
			TimePlayed[data][3] = SQL_FetchInt(hndl, 4);
			TimeInfectedPlayed[data][0] = SQL_FetchInt(hndl, 5);
			TimeInfectedPlayed[data][1] = SQL_FetchInt(hndl, 6);
			TimeInfectedPlayed[data][2] = SQL_FetchInt(hndl, 7);
			TimeInfectedPlayed[data][3] = SQL_FetchInt(hndl, 8);
			TimeSurvivorPlayed[data][0] = SQL_FetchInt(hndl, 9);
			TimeSurvivorPlayed[data][1] = SQL_FetchInt(hndl, 10);
			TimeSurvivorPlayed[data][2] = SQL_FetchInt(hndl, 11);
			TimeSurvivorPlayed[data][3] = SQL_FetchInt(hndl, 12);
			InfectedLevel[data] = SQL_FetchInt(hndl, 13);
			SurvivorLevel[data] = SQL_FetchInt(hndl, 14);
			Bounty[data] = SQL_FetchInt(hndl, 15);
		}
	}
}


public QuerySurvivorData( Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if ( hndl != INVALID_HANDLE )
	{
		while ( SQL_FetchRow(hndl) )
		{
			decl String:Name[MAX_NAME_LENGTH];
			SQL_FetchString(hndl, 0, Name, sizeof(Name));
			Ph[data][0] = SQL_FetchInt(hndl, 1);
			Ph[data][1] = SQL_FetchInt(hndl, 2);
			Ph[data][2] = SQL_FetchInt(hndl, 3);
			Pi[data][0] = SQL_FetchInt(hndl, 4);
			Pi[data][1] = SQL_FetchInt(hndl, 5);
			Pi[data][2] = SQL_FetchInt(hndl, 6);
			Me[data][0] = SQL_FetchInt(hndl, 7);
			Me[data][1] = SQL_FetchInt(hndl, 8);
			Me[data][2] = SQL_FetchInt(hndl, 9);
			Uz[data][0] = SQL_FetchInt(hndl, 10);
			Uz[data][1] = SQL_FetchInt(hndl, 11);
			Uz[data][2] = SQL_FetchInt(hndl, 12);
			Sh[data][0] = SQL_FetchInt(hndl, 13);
			Sh[data][1] = SQL_FetchInt(hndl, 14);
			Sh[data][2] = SQL_FetchInt(hndl, 15);
			Sn[data][0] = SQL_FetchInt(hndl, 16);
			Sn[data][1] = SQL_FetchInt(hndl, 17);
			Sn[data][2] = SQL_FetchInt(hndl, 18);
			Ri[data][0] = SQL_FetchInt(hndl, 19);
			Ri[data][1] = SQL_FetchInt(hndl, 20);
			Ri[data][2] = SQL_FetchInt(hndl, 21);
			Gr[data][0] = SQL_FetchInt(hndl, 22);
			Gr[data][1] = SQL_FetchInt(hndl, 23);
			Gr[data][2] = SQL_FetchInt(hndl, 24);
			It[data][0] = SQL_FetchInt(hndl, 25);
			It[data][1] = SQL_FetchInt(hndl, 26);
			It[data][2] = SQL_FetchInt(hndl, 27);
		}
	}
	else
	{
		LogError ( "%s", error );

		return;
	}
}

public QueryInfectedData( Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if ( hndl != INVALID_HANDLE )
	{
		while ( SQL_FetchRow(hndl) )
		{
			if (data != 0)
			{
				decl String:Name[MAX_NAME_LENGTH];
				SQL_FetchString(hndl, 0, Name, sizeof(Name));
				In[data][0] = SQL_FetchInt(hndl, 1);
				In[data][1] = SQL_FetchInt(hndl, 2);
				In[data][2] = SQL_FetchInt(hndl, 3);
				Hu[data][0] = SQL_FetchInt(hndl, 4);
				Hu[data][1] = SQL_FetchInt(hndl, 5);
				Hu[data][2] = SQL_FetchInt(hndl, 6);
				WOF[data][0] = SQL_FetchInt(hndl, 7);
				Sm[data][0] = SQL_FetchInt(hndl, 8);
				Sm[data][1] = SQL_FetchInt(hndl, 9);
				Sm[data][2] = SQL_FetchInt(hndl, 10);
				WOF[data][1] = SQL_FetchInt(hndl, 11);
				Bo[data][0] = SQL_FetchInt(hndl, 12);
				Bo[data][1] = SQL_FetchInt(hndl, 13);
				Bo[data][2] = SQL_FetchInt(hndl, 14);
				WOF[data][2] = SQL_FetchInt(hndl, 15);
				Jo[data][0] = SQL_FetchInt(hndl, 16);
				Jo[data][1] = SQL_FetchInt(hndl, 17);
				Jo[data][2] = SQL_FetchInt(hndl, 18);
				WOF[data][3] = SQL_FetchInt(hndl, 19);
				Ch[data][0] = SQL_FetchInt(hndl, 20);
				Ch[data][1] = SQL_FetchInt(hndl, 21);
				Ch[data][2] = SQL_FetchInt(hndl, 22);
				WOF[data][4] = SQL_FetchInt(hndl, 23);
				Sp[data][0] = SQL_FetchInt(hndl, 24);
				Sp[data][1] = SQL_FetchInt(hndl, 25);
				Sp[data][2] = SQL_FetchInt(hndl, 26);
				WOF[data][5] = SQL_FetchInt(hndl, 27);
				Ta[data][0] = SQL_FetchInt(hndl, 28);
				Ta[data][1] = SQL_FetchInt(hndl, 29);
				Ta[data][2] = SQL_FetchInt(hndl, 30);
				WOF[data][6] = SQL_FetchInt(hndl, 31);
			}
			else
			{
				decl String:Name[MAX_NAME_LENGTH];
				SQL_FetchString(hndl, 0, Name, sizeof(Name));
				AIInfected[0] = SQL_FetchInt(hndl, 1);
				AIInfected[1] = SQL_FetchInt(hndl, 2);
				AIInfected[2] = SQL_FetchInt(hndl, 3);
				AIHunter[0] = SQL_FetchInt(hndl, 4);
				AIHunter[1] = SQL_FetchInt(hndl, 5);
				AIHunter[2] = SQL_FetchInt(hndl, 6);
				AISmoker[0] = SQL_FetchInt(hndl, 7);
				AISmoker[1] = SQL_FetchInt(hndl, 8);
				AISmoker[2] = SQL_FetchInt(hndl, 9);
				AIBoomer[0] = SQL_FetchInt(hndl, 10);
				AIBoomer[1] = SQL_FetchInt(hndl, 11);
				AIBoomer[2] = SQL_FetchInt(hndl, 12);
				AIJockey[0] = SQL_FetchInt(hndl, 13);
				AIJockey[1] = SQL_FetchInt(hndl, 14);
				AIJockey[2] = SQL_FetchInt(hndl, 15);
				AICharger[0] = SQL_FetchInt(hndl, 16);
				AICharger[1] = SQL_FetchInt(hndl, 17);
				AICharger[2] = SQL_FetchInt(hndl, 18);
				AISpitter[0] = SQL_FetchInt(hndl, 19);
				AISpitter[1] = SQL_FetchInt(hndl, 20);
				AISpitter[2] = SQL_FetchInt(hndl, 21);
				AITank[0] = SQL_FetchInt(hndl, 22);
				AITank[1] = SQL_FetchInt(hndl, 23);
				AITank[2] = SQL_FetchInt(hndl, 24);
			}
		}
	}
	else
	{
		LogError ( "%s", error );

		return;
	}
}

public QuerySkyData( Handle:owner, Handle:hndl, const String:error[], any:data)
{ 
	if ( hndl != INVALID_HANDLE )
	{
		while ( SQL_FetchRow(hndl) ) 
		{
			decl String:Name[MAX_NAME_LENGTH];
			SQL_FetchString(hndl, 0, Name, sizeof(Name));
			//SetClientInfo(data, "name", Name);
			showinfo[data] = SQL_FetchInt(hndl, 1);
			showpoints[data] = SQL_FetchInt(hndl, 2);
			cmds[data] = SQL_FetchInt(hndl, 3);
		}
	} 
	else
	{
		LogError( "%s", error ); 
		
		return;
	}
}

public QueryPlayerChatTextData( Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if ( hndl != INVALID_HANDLE )
	{
		while ( SQL_FetchRow(hndl) )
		{
			decl String:DataString[32];
			for (new i = 0; i <= 3; i++)
			{
				SQL_FetchString(hndl, i, DataString, sizeof(DataString));
				ChatColor[data][i] = DataString;
			}
		}
	}
}

public QuerySkyPointsData( Handle:owner, Handle:hndl, const String:error[], any:data)
{ 
	if ( hndl != INVALID_HANDLE )
	{
		while ( SQL_FetchRow(hndl) ) 
		{
			SkyPoints[data] = SQL_FetchInt(hndl, 0);
		}
	} 
	else
	{
		LogError( "%s", error ); 
		
		return;
	}
}

public QueryMultiplierData( Handle:owner, Handle:hndl, const String:error[], any:data)
{ 
	if ( hndl != INVALID_HANDLE )
	{
		while ( SQL_FetchRow(hndl) ) 
		{
			XPMultiplierTime[data] = SQL_FetchInt(hndl, 0);
		}
	} 
	else
	{
		LogError( "%s", error ); 
		
		return;
	}
}

public QueryDailyAchievementData( Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if ( hndl != INVALID_HANDLE )
	{
		while ( SQL_FetchRow(hndl) )
		{
			decl String:Name[MAX_NAME_LENGTH];
			SQL_FetchString(hndl, 0, Name, sizeof(Name));

			// Get the achievement info
			Ach[data][0] = SQL_FetchInt(hndl, 1);
			Ach[data][1] = SQL_FetchInt(hndl, 2);
			Ach[data][3] = SQL_FetchInt(hndl, 3);
			Ach[data][4] = SQL_FetchInt(hndl, 4);
			AchDate[data] = SQL_FetchInt(hndl, 5);
		}
	}
}

public QueryAchievementData( Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if ( hndl != INVALID_HANDLE )
	{
		while ( SQL_FetchRow(hndl) )
		{
			decl String:Name[MAX_NAME_LENGTH];
			SQL_FetchString(hndl, 0, Name, sizeof(Name));

			// Get the achievement info
			Ach[data][2] = SQL_FetchInt(hndl, 1);
		}
	}
}

public QueryPresetData( Handle:owner, Handle:hndl, const String:error[], any:data)
{ 
	if ( hndl != INVALID_HANDLE )
	{
		while ( SQL_FetchRow(hndl) ) 
		{
			decl String:Name[MAX_NAME_LENGTH];
			SQL_FetchString(hndl, 0, Name, sizeof(Name));
			
			decl String:DataInput[64];
			for (new i = 0; i <= 4; i++)
			{
				SQL_FetchString(hndl, i + 1, DataInput, sizeof(DataInput));
				Mw[data][i] = DataInput;
			}
			for (new i = 0; i <= 4; i++)
			{
				SQL_FetchString(hndl, i + 6, DataInput, sizeof(DataInput));
				Sw[data][i] = DataInput;
			}
			for (new i = 0; i <= 4; i++)
			{
				SQL_FetchString(hndl, i + 11, DataInput, sizeof(DataInput));
				Hi[data][i] = DataInput;
			}
			for (new i = 0; i <= 4; i++)
			{
				SQL_FetchString(hndl, i + 16, DataInput, sizeof(DataInput));
				Gi[data][i] = DataInput;
			}
			Ul[data][0] = SQL_FetchInt(hndl, 21);
			Ul[data][1] = SQL_FetchInt(hndl, 22);
		}
	} 
	else
	{
		LogError( "%s", error ); 
		
		return;
	}
}

public QueryTrailsData( Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if ( hndl != INVALID_HANDLE )
	{
		while (SQL_FetchRow(hndl))
		{
			weaponTrails[data] = SQL_FetchInt(hndl, 0);

			PiTrail[data][0] = SQL_FetchInt(hndl, 1);
			PiTrail[data][1] = SQL_FetchInt(hndl, 2);
			PiTrail[data][2] = SQL_FetchInt(hndl, 3);
			PiTrail[data][3] = SQL_FetchInt(hndl, 4);

			UzTrail[data][0] = SQL_FetchInt(hndl, 5);
			UzTrail[data][1] = SQL_FetchInt(hndl, 6);
			UzTrail[data][2] = SQL_FetchInt(hndl, 7);
			UzTrail[data][3] = SQL_FetchInt(hndl, 8);

			ShTrail[data][0] = SQL_FetchInt(hndl, 9);
			ShTrail[data][1] = SQL_FetchInt(hndl, 10);
			ShTrail[data][2] = SQL_FetchInt(hndl, 11);
			ShTrail[data][3] = SQL_FetchInt(hndl, 12);

			RiTrail[data][0] = SQL_FetchInt(hndl, 13);
			RiTrail[data][1] = SQL_FetchInt(hndl, 14);
			RiTrail[data][2] = SQL_FetchInt(hndl, 15);
			RiTrail[data][3] = SQL_FetchInt(hndl, 16);

			SnTrail[data][0] = SQL_FetchInt(hndl, 17);
			SnTrail[data][1] = SQL_FetchInt(hndl, 18);
			SnTrail[data][2] = SQL_FetchInt(hndl, 19);
			SnTrail[data][3] = SQL_FetchInt(hndl, 20);
		}
	}
	else
	{
		LogError("%s", error);
		return;
	}
}

public QueryMountedGunsData( Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if ( hndl != INVALID_HANDLE )
	{
		while ( SQL_FetchRow(hndl) )
		{
			MountedGunsPurchased[data] = SQL_FetchInt(hndl, 0);
		}
	}
	else
	{
		LogError( "%s" , error );

		return;
	}
}

public QueryNemesisData( Handle:owner, Handle:hndl, const String:error[], any:data)
{ 
	if ( hndl != INVALID_HANDLE )
	{
		while ( SQL_FetchRow(hndl) ) 
		{
			decl String:DataInput[64];
			SQL_FetchString(hndl, 0, DataInput, sizeof(DataInput));
			Nemesis[data] = DataInput;
			decl String:Query[256];
			Format(Query, sizeof(Query), "SELECT `last_name_used` FROM `player_cat` WHERE (`steam_id` = '%s');", Nemesis[data]);
			SQL_TQuery(hDatabase, QueryNemesisNameData, Query, data);
		}
	} 
	else
	{
		LogError( "%s", error ); 
		
		return;
	}
}

public QueryNemesisNameData( Handle:owner, Handle:hndl, const String:error[], any:data)
{ 
	if ( hndl != INVALID_HANDLE )
	{
		while ( SQL_FetchRow(hndl) ) 
		{
			decl String:DataInput[256];
			SQL_FetchString(hndl, 0, DataInput, sizeof(DataInput));
			NemesisName[data] = DataInput;
		}
	} 
	else
	{
		LogError( "%s", error ); 
		
		return;
	}
}

SaveSkyPoints(client)
{
	decl String:Query[256];
	decl String:Key[64];
	decl String:Name[256];
	GetClientAuthString(client, Key, 65);
	GetClientName(client, Name, 257);
	if (StrEqual(Key, "BOT")) return;
	Format(Query, sizeof(Query), "REPLACE INTO `sky_store_cat` (`steam_id`, `sky_points`) VALUES ('%s', '%d');", Key, SkyPoints[client]);
	SQL_TQuery(hDatabase, QuerySetData, Query, client);
}

SaveData(client)
{
	decl String:Query[2048];
	decl String:Key[64];
	decl String:Name[256];
	GetClientAuthString(client, Key, 65);
	GetClientName(client, Name, 257);
	if (StrEqual(Key, "BOT")) return;		// BOT. Don't allow.
	Format(Query, sizeof(Query), "REPLACE INTO `mounted_cat` (`steam_id`, `purchased`) VALUES ('%s', '%d');", Key, MountedGunsPurchased[client]);
	SQL_TQuery(hDatabase, QuerySetData, Query, client);
	Format(Query, sizeof(Query), "REPLACE INTO `multiplier_cat` (`steam_id`, `xp_timer`) VALUES ('%s', '%d');", Key, XPMultiplierTime[client]);
	SQL_TQuery(hDatabase, QuerySetData, Query, client);
	Format(Query, sizeof(Query), "REPLACE INTO `nemesis_cat` (`steam_id`, `nemesis_steamid`) VALUES ('%s', '%s');", Key, Nemesis[client]);
	SQL_TQuery(hDatabase, QuerySetData, Query, client);

	Format(Query, sizeof(Query), "REPLACE INTO `player_cat` (`steam_id`, `last_name_used`, `micro_menu`, `points_display`, `cmds`) VALUES ('%s', '%s', '%d', '%d', '%d');", Key, Name, showinfo[client], showpoints[client], cmds[client]);
	SQL_TQuery(hDatabase, QuerySetData, Query, client);
	
	Format(Query, sizeof(Query), "REPLACE INTO `slevels` (`steam_id`, `id`, `phx`, `phn`, `phl`, `pix`, `pin`, `pil`, `mex`, `men`, `mel`, `uzx`, `uzn`, `uzl`, `shx`, `shn`, `shl`, `snx`, `snn`, `snl`, `rix`, `rin`, `ril`, `grx`, `grn`, `grl`, `itx`, `itn`, `itl`) VALUES ('%s', '%s', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d');", Key, Name, Ph[client][0], Ph[client][1], Ph[client][2], Pi[client][0], Pi[client][1], Pi[client][2], Me[client][0], Me[client][1], Me[client][2], Uz[client][0], Uz[client][1], Uz[client][2], Sh[client][0], Sh[client][1], Sh[client][2], Sn[client][0], Sn[client][1], Sn[client][2], Ri[client][0], Ri[client][1], Ri[client][2], Gr[client][0], Gr[client][1], Gr[client][2], It[client][0], It[client][1], It[client][2]);
	SQL_TQuery(hDatabase, QuerySetData, Query, client);
	Format(Query, sizeof(Query), "REPLACE INTO `ilevels` (`steam_id`, `id`, `inx`, `inn`, `inl`, `hux`, `hun`, `hul`, `huw`, `smx`, `smn`, `sml`, `smw`, `box`, `bon`, `bol`, `bow`, `jox`, `jon`, `jol`, `jow`, `chx`, `chn`, `chl`, `chw`, `spx`, `spn`, `spl`, `spw`, `tax`, `tan`, `tal`, `taw`) VALUES ('%s', '%s', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d');", Key, Name, In[client][0], In[client][1], In[client][2], Hu[client][0], Hu[client][1], Hu[client][2], WOF[client][0], Sm[client][0], Sm[client][1], Sm[client][2], WOF[client][1], Bo[client][0], Bo[client][1], Bo[client][2], WOF[client][2], Jo[client][0], Jo[client][1], Jo[client][2], WOF[client][3], Ch[client][0], Ch[client][1], Ch[client][2], WOF[client][4], Sp[client][0], Sp[client][1], Sp[client][2], WOF[client][5], Ta[client][0], Ta[client][1], Ta[client][2], WOF[client][6]);
	SQL_TQuery(hDatabase, QuerySetData, Query, client);
	Format(Query, sizeof(Query), "REPLACE INTO `presets` (`steam_id`, `id`, `mw1`, `mw2`, `mw3`, `mw4`, `mw5`, `sw1`, `sw2`, `sw3`, `sw4`, `sw5`, `hi1`, `hi2`, `hi3`, `hi4`, `hi5`, `gi1`, `gi2`, `gi3`, `gi4`, `gi5`, `unlocked4`, `unlocked5`) VALUES ('%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%d', '%d');", Key, Name, Mw[client][0], Mw[client][1], Mw[client][2], Mw[client][3], Mw[client][4], Sw[client][0], Sw[client][1], Sw[client][2], Sw[client][3], Sw[client][4], Hi[client][0], Hi[client][1], Hi[client][2], Hi[client][3], Hi[client][4], Gi[client][0], Gi[client][1], Gi[client][2], Gi[client][3], Gi[client][4], Ul[client][0], Ul[client][1]);
	SQL_TQuery(hDatabase, QuerySetData, Query, client);
	Format(Query, sizeof(Query), "REPLACE INTO `time` (`steam_id`, `name`, `td`, `th`, `tm`, `ts`, `id`, `ih`, `im`, `is`, `sd`, `sh`, `sm`, `ss`, `infl`, `survl`, `bty`) VALUES ('%s', '%s', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d');", Key, Name, TimePlayed[client][0], TimePlayed[client][1], TimePlayed[client][2], TimePlayed[client][3], TimeInfectedPlayed[client][0], TimeInfectedPlayed[client][1], TimeInfectedPlayed[client][2], TimeInfectedPlayed[client][3], TimeSurvivorPlayed[client][0], TimeSurvivorPlayed[client][1], TimeSurvivorPlayed[client][2], TimeSurvivorPlayed[client][3], In[client][2], Ph[client][2], Bounty[client]);
	SQL_TQuery(hDatabase, QuerySetData, Query, client);
	Format(Query, sizeof(Query), "REPLACE INTO `chat_color` (`steam_id`, `paranthesis`, `team`, `name`, `text`) VALUES ('%s', '%s', '%s', '%s', '%s');", Key, ChatColor[client][0], ChatColor[client][1], ChatColor[client][2], ChatColor[client][3]);
	SQL_TQuery(hDatabase, QuerySetData, Query, client);
	Format(Query, sizeof(Query), "REPLACE INTO `daily_achieve` (`steam_id`, `id`, `ck`, `sik`, `sid`, `hpd`, `day`) VALUES ('%s', '%s', '%d', '%d', '%d', '%d', '%d');", Key, Name, Ach[client][0], Ach[client][1], Ach[client][3], Ach[client][4], AchDate[client]);
	SQL_TQuery(hDatabase, QuerySetData, Query, client);
	Format(Query, sizeof(Query), "REPLACE INTO `achieve` (`steam_id`, `id`, `cstm`) VALUES ('%s', '%s', '%d');", Key, Name, Ach[client][2]);
	SQL_TQuery(hDatabase, QuerySetData, Query, client);

	Format(Query, sizeof(Query), "REPLACE INTO `trails` (`steam_id`, `id`, `enable`, `pi0`, `pi1`, `pi2`, `pi3`, `uz0`, `uz1`, `uz2`, `uz3`, `sh0`, `sh1`, `sh2`, `sh3`, `ri0`, `ri1`, `ri2`, `ri3`, `sn0`, `sn1`, `sn2`, `sn3`) VALUES ('%s', '%s', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d');", Key, Name, weaponTrails[client], PiTrail[client][0], PiTrail[client][1], PiTrail[client][2], PiTrail[client][3], UzTrail[client][0], UzTrail[client][1], UzTrail[client][2], UzTrail[client][3], ShTrail[client][0], ShTrail[client][1], ShTrail[client][2], ShTrail[client][3], RiTrail[client][0], RiTrail[client][1], RiTrail[client][2], RiTrail[client][3], SnTrail[client][0], SnTrail[client][1], SnTrail[client][2], SnTrail[client][3]);
	SQL_TQuery(hDatabase, QuerySetData, Query, client);

	/*		Notify the player that we saved their data		*/
}

SaveDirectorData()
{
	decl String:Key[256];
	Format(Key, sizeof(Key), "STEAM_0:0:0b0");
	decl String:Name[MAX_NAME_LENGTH];
	Format(Name, sizeof(Name), "INFECTED_BOT");
	decl String:Query[1024];
	Format(Query, sizeof(Query), "REPLACE INTO `ilevels` (`steam_id`, `id`, `inx`, `inn`, `inl`, `hux`, `hun`, `hul`, `smx`, `smn`, `sml`, `box`, `bon`, `bol`, `jox`, `jon`, `jol`, `chx`, `chn`, `chl`, `spx`, `spn`, `spl`, `tax`, `tan`, `tal`) VALUES ('%s', '%s', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d');", Key, Name, AIInfected[0], AIInfected[1], AIInfected[2], AIHunter[0], AIHunter[1], AIHunter[2], AISmoker[0], AISmoker[1], AISmoker[2], AIBoomer[0], AIBoomer[1], AIBoomer[2], AIJockey[0], AIJockey[1], AIJockey[2], AICharger[0], AICharger[1], AICharger[2], AISpitter[0], AISpitter[1], AISpitter[2], AITank[0], AITank[1], AITank[2]);
	SQL_TQuery(hDatabase, QuerySetData, Query, 0);
}

Load_MapRecords()
{
	decl String:MapName[256];
	decl String:Query[1024];
	GetCurrentMap(MapName, sizeof(MapName));
	Format(Query, sizeof(Query), "SELECT `best_kills`, `player_name`, `best_headshots`, `best_headshots_name`, `best_survivor_dmg`, `best_survivor_dmg_name`, `best_infected_damage`, `infected_name`, `best_healing`, `healing_name`, `best_rescuer`, `rescuer_name` FROM `map_records` WHERE (`map_name` = '%s');", MapName);
	SQL_TQuery(hDatabase, QueryMapData, Query, 0);
}

Save_MapRecords()
{
	// A map record has been beaten. Let's save it.
	
	decl String:MapName[256];
	decl String:Query[1024];
	GetCurrentMap(MapName, sizeof(MapName));
	Format(Query, sizeof(Query), "REPLACE INTO `map_records` (`map_name`, `best_kills`, `player_name`, `best_headshots`, `best_headshots_name`, `best_survivor_dmg`, `best_survivor_dmg_name`, `best_infected_damage`, `infected_name`, `best_healing`, `healing_name`, `best_rescuer`, `rescuer_name` ) VALUES ('%s', '%d', '%s', '%d', '%s', '%d', '%s', '%d', '%s', '%d', '%s', '%d', '%s');", MapName, MapBestKills, MapBestKillsName, MapBestSurvivorHS, MapBestSurvivorHSName, MapBestSurvivorDamage, MapBestSurvivorDamageName, MapBestInfectedDamage, MapBestInfectedDamageName, MapBestHealing, MapBestHealingName, MapBestRescuer, MapBestRescuerName);
	SQL_TQuery(hDatabase, QuerySetData, Query, 0);
	if (RoundEndCount == 3)
	{
		MapBestKills = 0;
		MapBestKillsName = "none";
		MapBestSurvivorHS = 0;
		MapBestSurvivorHSName = "none";
		MapBestSurvivorDamage = 0;
		MapBestSurvivorDamageName = "none";
		MapBestInfectedDamage = 0;
		MapBestInfectedDamageName = "none";
		MapBestHealing = 0;
		MapBestHealingName = "none";
		MapBestRescuer = 0;
		MapBestRescuerName = "none";
	}
}

AnnounceMapRecord()
{
	PrintToChatAll("%s \x04New Map Challenges \x03are now posted \x01on your menu's \x05Challenge Board\x01!", INFO);
}

LoadDirectorData()
{
	decl String:Key[256];
	Format(Key, sizeof(Key), "STEAM_0:0:0b0");
	decl String:Query[1024];
	Format(Query, sizeof(Query), "SELECT `id`, `inx`, `inn`, `inl`, `hux`, `hun`, `hul`, `smx`, `smn`, `sml`, `box`, `bon`, `bol`, `jox`, `jon`, `jol`, `chx`, `chn`, `chl`, `spx`, `spn`, `spl`, `tax`, `tan`, `tal` FROM `ilevels` WHERE (`steam_id` = '%s');", Key);
	SQL_TQuery(hDatabase, QueryInfectedData, Query, 0);
}

LoadData(client)
{
	if (IsClientIndexOutOfRange(client) || !IsClientInGame(client) || IsFakeClient(client)) return;
	decl String:Query[2048];
	decl String:Key[64];
	GetClientAuthString(client, Key, 65);

	for (new i = 0; i <= 3; i++) ChatColor[client][i] = "def";
	
	/*		LOAD SURVIVOR DATA		*/

	Format(Query, sizeof(Query), "SELECT `id`, `phx`, `phn`, `phl`, `pix`, `pin`, `pil`, `mex`, `men`, `mel`, `uzx`, `uzn`, `uzl`, `shx`, `shn`, `shl`, `snx`, `snn`, `snl`, `rix`, `rin`, `ril`, `grx`, `grn`, `grl`, `itx`, `itn`, `itl` FROM `slevels` WHERE (`steam_id` = '%s');", Key);
	SQL_TQuery(hDatabase, QuerySurvivorData, Query, client);

	Format(Query, sizeof(Query), "SELECT `id`, `inx`, `inn`, `inl`, `hux`, `hun`, `hul`, `huw`, `smx`, `smn`, `sml`, `smw`, `box`, `bon`, `bol`, `bow`, `jox`, `jon`, `jol`, `jow`, `chx`, `chn`, `chl`, `chw`, `spx`, `spn`, `spl`, `spw`, `tax`, `tan`, `tal`, `taw` FROM `ilevels` WHERE (`steam_id` = '%s');", Key);
	SQL_TQuery(hDatabase, QueryInfectedData, Query, client);

	Format(Query, sizeof(Query), "SELECT `name`, `td`, `th`, `tm`, `ts`, `id`, `ih`, `im`, `is`, `sd`, `sh`, `sm`, `ss`, `infl`, `survl`, `bty` FROM `time` WHERE (`steam_id` = '%s');", Key);
	SQL_TQuery(hDatabase, QueryTimeData, Query, client);

	Format(Query, sizeof(Query), "SELECT `id`, `ck`, `sik`, `sid`, `hpd`, `day` FROM `daily_achieve` WHERE (`steam_id` = '%s');", Key);
	SQL_TQuery(hDatabase, QueryDailyAchievementData, Query, client);

	Format(Query, sizeof(Query), "SELECT `id`, `cstm` FROM `achieve` WHERE (`steam_id` = '%s');", Key);
	SQL_TQuery(hDatabase, QueryAchievementData, Query, client);

	Format(Query, sizeof(Query), "SELECT `purchased` FROM `mounted_cat` WHERE (`steam_id` = '%s');", Key);
	SQL_TQuery(hDatabase, QueryMountedGunsData, Query, client);
	Format(Query, sizeof(Query), "SELECT `nemesis_steamid` FROM `nemesis_cat` WHERE (`steam_id` = '%s');", Key);
	SQL_TQuery(hDatabase, QueryNemesisData, Query, client);

	Format(Query, sizeof(Query), "SELECT `last_name_used`, `micro_menu`, `points_display`, `cmds` FROM `player_cat` WHERE (`steam_id` = '%s');", Key);
	SQL_TQuery(hDatabase, QuerySkyData, Query, client);
	Format(Query, sizeof(Query), "SELECT `id`, `mw1`, `mw2`, `mw3`, `mw4`, `mw5`, `sw1`, `sw2`, `sw3`, `sw4`, `sw5`, `hi1`, `hi2`, `hi3`, `hi4`, `hi5`, `gi1`, `gi2`, `gi3`, `gi4`, `gi5`, `unlocked4`, `unlocked5` FROM `presets` WHERE (`steam_id` = '%s');", Key);
	SQL_TQuery(hDatabase, QueryPresetData, Query, client);

	Format(Query, sizeof(Query), "SELECT `xp_timer` FROM `multiplier_cat` WHERE (`steam_id` = '%s');", Key);
	SQL_TQuery(hDatabase, QueryMultiplierData, Query, client);
	Format(Query, sizeof(Query), "SELECT `sky_points` FROM `sky_store_cat` WHERE (`steam_id` = '%s');", Key);
	SQL_TQuery(hDatabase, QuerySkyPointsData, Query, client);

	// Why is this duped?
	//Format(Query, sizeof(Query), "SELECT `last_name_used`, `micro_menu`, `points_display` FROM `player_cat` WHERE (`steam_id` = '%s');", Key);
	//SQL_TQuery(hDatabase, QuerySkyData, Query, client);


	Format(Query, sizeof(Query), "SELECT `paranthesis`, `team`, `name`, `text` FROM `chat_color` WHERE (`steam_id` = '%s');", Key);
	SQL_TQuery(hDatabase, QueryPlayerChatTextData, Query, client);

	Format(Query, sizeof(Query), "SELECT `enable`, `pi0`, `pi1`, `pi2`, `pi3`, `uz0`, `uz1`, `uz2`, `uz3`, `sh0`, `sh1`, `sh2`, `sh3`, `ri0`, `ri1`, `ri2`, `ri3`, `sn0`, `sn1`, `sn2`, `sn3` FROM `trails` WHERE (`steam_id` = '%s');", Key);
	SQL_TQuery(hDatabase, QueryTrailsData, Query, client);

	if (XPMultiplierTime[client] > 0 && !XPMultiplierTimer[client])
	{
		XPMultiplierTimer[client] = true;
		CreateTimer(1.0, DeductMultiplierTime, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

SetSurvivorHealth()
{
	// We're going to start timers that set health pools for each survivor.
	// There will be a time out stage if their physical level <= 1 for longer than x seconds.
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsHuman(i) && GetClientTeam(i) == 2 && Ph[i][2] > 1)
		{
			SetEntityHealth(i, 100 + Ph[i][2] + It[i][2]);
		}
		else if (IsHuman(i) && GetClientTeam(i) == 2 && Ph[i][2] <= 1)
		{
			SetHealthTimer[i] = 0;
			CreateTimer(1.0, Timer_SetSurvivorHealth, i, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action:Timer_SetSurvivorHealth(Handle:timer, any:i)
{
	if (!IsHuman(i)) return Plugin_Stop;
	if (Ph[i][2] > 1)
	{
		SetEntityHealth(i, 100 + Ph[i][2] + It[i][2]);
		return Plugin_Stop;
	}
	else if (Ph[i][2] <= 1)
	{
		// Run a timer to set health.
		SetHealthTimer[i]++;
		if (SetHealthTimer[i] >= GetConVarInt(SetHealthExpireTime)) return Plugin_Stop;
	}
	return Plugin_Continue;
}