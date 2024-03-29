/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define ACHIEVEMENT_SOUND 		"misc/achievement_earned.wav"
#define ACHIEVEMENT_PARTICLE 	"Achieved"
#define SCORED_SOUND			"player/taunt_bell.wav"

#define CUSTOMACHVERSION		"0.1"

#define CVAR_ACHIEVEMENTS		0
#define CVAR_VERSION			1
#define VAL_NUM_CVARS			2

//----------------------------------------CUSTOM ACHIVEMENTS-----------------------------------------
//Ce sont des variables n�cessaires au bon fonctionnement du plugins !
//Donnee du CustomAchivement.sp
new Handle:cvURL = INVALID_HANDLE;
new Handle:cvDB = INVALID_HANDLE;
new Handle:cvTablePrefix = INVALID_HANDLE;

new Handle:hDatabaseConnection = INVALID_HANDLE;

new bool:bConnected = false;

new String:sTablePrefix[64];

new iPassInt[256][4];
new iCurPass = 0;


new Handle:g_cvars[VAL_NUM_CVARS];
new g_maxAchievements;

//----------------------------------------ACHIVEMENT KILL BY MYSQL-----------------------------------------
//Donn�es pour la base de donn�e : ach_server : 19 champs multiples
//Ces packs sont un peu un comparatif avec une pile ou avec une arrayList en Java : 
//ils stockent des donn�es sans rien dire, sans demander le type de donn�es ou presque !

new Handle:g_bd_id;
new Handle:g_bd_ida;
new Handle:g_bd_victim_bool;
new Handle:g_bd_attacker_bool;
new Handle:g_bd_assister_bool;
new Handle:g_bd_victim_steamid;
new Handle:g_bd_attacker_steamid;
new Handle:g_bd_assister_steamid;
new Handle:g_bd_weapon;
new Handle:g_bd_map;
new Handle:g_bd_victim_name;
new Handle:g_bd_attacker_name;
new Handle:g_bd_assister_name;
new Handle:g_bd_domination;
new Handle:g_bd_revenge;
new Handle:g_bd_headshot;
new Handle:g_bd_backstab;
new Handle:g_bd_deadringer;
new Handle:g_bd_class;

//Donn�es pour le serveur.
//Ce sont les donn�es n�cessaires qui sont instanci� lors de l'�venement "Mort d'un joueur"
new g_victim;
new g_attacker;
new String:g_weapon[128];
new g_customkill;
new g_target;
new g_headshot;
new g_domination;
new g_revenge;
new g_assister;
new g_deadringer;
new TFClassType:g_class;
new String:g_map[64];


//----------------------------------------INFO OF PLUGINS----------------------------------------
//Le code a �t� g�n�r� via le logiciel Pawn Studio !
//Version 1 du plugins compatible sourcemod 1.4
public Plugin:myinfo = 
{
	name = "Custom Achievement Kill Manager With MYSQL",
	author = "Pfsm999, GachL, linux_lover & Jindo",
	description = "Manage achievements based on weapon + class based kills/deaths with creation by database.",
	version = CUSTOMACHVERSION,
	url = "http://www.chicken-team.com"
}

//----------------------------------------WHEN THE PLUGIN WAS CHARGED----------------------------
//Methode charg�e lors de l'instanciation du plugins par Sourcemod !
public OnPluginStart()
{
	
	g_cvars[CVAR_VERSION] = CreateConVar("sm_customach_version", CUSTOMACHVERSION, "Current version of the Kill-based Achievement Manager.");
	g_cvars[CVAR_ACHIEVEMENTS] = CreateConVar("sm_customach_num", "0", "Number of achievements according to the config.");
	
	cvURL = CreateConVar("sm_customach_url", "http://ns304110.ovh.net/achievements/player.php", "Url to the php file that shows player achievements.");
	cvDB = CreateConVar("sm_customach_db", "default", "DB to use");
	cvTablePrefix = CreateConVar("sm_customach_prefix", "ach_", "Table prefix");
	
	HookEvent("player_death", eCheckFile);
	
	//On verifie tout ce qui est tapper dans le chat (par le client et non par les autres)
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	//On cr�er des commandes pour les personnes qui ont la console ! 
	RegConsoleCmd("achievements", cShowAchievements);
	RegConsoleCmd("achievement", cShowAchievements);
	//On donne la possibilit� aux admins de refresh le plugins !
	RegAdminCmd("sm_customach_refresh", cConfig, ADMFLAG_SLAY);
	//On pr�cache les sons n�cessaires aux succ�s !
	PrecacheSound(ACHIEVEMENT_SOUND);
	PrecacheSound(SCORED_SOUND);
	//On lance le plugins !
	Initial();
	
}

public Action:cConfig(client, args)
{
	PrecacheSound(ACHIEVEMENT_SOUND);
	PrecacheSound(SCORED_SOUND);
	
	Initial();
	return Plugin_Handled;
}

//----------------------------------------CUSTOM ACHIVEMENTS-----------------------------------------
//----------------------------------------CODE OF GachL ---------------------------------------------
//Thanks for this code but i must have your code for test my plugins and i thinks that was bad to have
//this beautiful code ... but don't exploit it !
/*public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("ProcessAchievement", ProcessAchievement);
	return true;
}*/

public OnMapStart()
{
	PrecacheSound(ACHIEVEMENT_SOUND);
	PrecacheSound(SCORED_SOUND);
	Initial();
	
}

public OnConfigsExecuted()
{
	new String:sDB[128];
	GetConVarString(cvDB, sDB, sizeof(sDB));
	if (SQL_CheckConfig(sDB))
	{
		SQL_TConnect(cDatabaseConnect, sDB);
	}
	else
	{
		LogError("Unable to open %s: No such database configuration.", sDB);
		bConnected = false;
	}
}

public PassInts(i1, i2, i3, i4)
{
	if (iCurPass == 256)
		iCurPass = 0;
	iPassInt[iCurPass][0] = i1;
	iPassInt[iCurPass][1] = i2;
	iPassInt[iCurPass][2] = i3;
	iPassInt[iCurPass][3] = i4;
	iCurPass++;
	return iCurPass-1;
}

public cDatabaseConnect(Handle:hOwner, Handle:hQuery, const String:sError[], any:data) 
{
	new String:sDB[128];
	GetConVarString(cvDB, sDB, sizeof(sDB));
	GetConVarString(cvTablePrefix, sTablePrefix, sizeof(sTablePrefix));
	if (hQuery == INVALID_HANDLE)
	{
		LogError("Unable to connect to %s: %s", sDB, sError);
		bConnected = false;
	}
	else
	{
		if (!SQL_FastQuery(hQuery, "SET NAMES 'utf8'"))
		{
			LogError("Unable to change to utf8 mode.");
			bConnected = false;
		}
		else
		{
			hDatabaseConnection = hQuery;
			bConnected = true;
		}
	}
}

public bool:IsDatabaseClosed()
{
	return !bConnected;
}

public OnClientPostAdminCheck(hClient)
{
	SaveUser(hClient);
}

public SaveUser(hClient)
{
	if (IsDatabaseClosed())
		return;
	
	new String:sSteamId[128];
	new String:sName[128];
	new String:sEscapedName[128];
	GetClientAuthString(hClient, sSteamId, sizeof(sSteamId));
	GetClientName(hClient, sName, sizeof(sName));
	SQL_EscapeString(hDatabaseConnection, sName, sEscapedName, sizeof(sEscapedName));
	
	new String:sQuery[512];
	Format(sQuery, sizeof(sQuery), "INSERT INTO `%snames` (`steamid`, `name`) VALUES ('%s', '%s') ON DUPLICATE KEY UPDATE `name` = VALUES(`name`)", sTablePrefix, sSteamId, sEscapedName);
	
	SQL_TQuery(hDatabaseConnection, cDiscardSQL, sQuery);
}

public cDiscardSQL(Handle:hOwner, Handle:hQuery, const String:sError[], any:data) 
{
	if (hQuery == INVALID_HANDLE)
	{
		LogError("Error in sql query: %s", sError);
	}
}

/**
 * The API function
 */
public ProcessAchievement(idi, argClient)
{
	new iAchievementId = idi;
	new hClient = argClient;
	if (InvalidClient(hClient))
		return;
	if (IsDatabaseClosed())
		return;
	
	new String:sQuery[512];
	Format(sQuery, sizeof(sQuery), "SELECT * FROM `%sconfig` WHERE `id` = %i;", sTablePrefix, iAchievementId);
	SQL_TQuery(hDatabaseConnection, cCheckForValidAchievement, sQuery, PassInts(hClient, iAchievementId, -1, -1));
}

public cCheckForValidAchievement(Handle:hOwner, Handle:hQuery, const String:sError[], any:data) 
{
	if (hQuery == INVALID_HANDLE)
	{
		LogError("Error in sql query: %s", sError);
		return;
	}
	
	if (SQL_GetRowCount(hQuery) != 1)
	{
		LogError("Achievement %i does not exist!", iPassInt[data][1]);
		return;
	}
	SQL_FetchRow(hQuery);
	new String:sQuery[512];
	new iAchievementId = SQL_FetchInt(hQuery, 0);
	new String:sSteamId[32];
	GetClientAuthString(iPassInt[data][0], sSteamId, sizeof(sSteamId));
	Format(sQuery, sizeof(sQuery), "SELECT `c`.`name`, `u`.`interval` FROM `%sconfig` AS `c` LEFT JOIN `%susers` AS `u` ON `c`.`id` = `u`.`aid` WHERE `u`.`steamid` = '%s' AND `id` = %i;", sTablePrefix, sTablePrefix, sSteamId, iAchievementId);
	//PrintToServer("D E B U G : \"%s\"!", sQuery);
	SQL_TQuery(hDatabaseConnection, cProcessUserAchievement, sQuery, PassInts(iPassInt[data][0], iPassInt[data][1], SQL_FetchInt(hQuery, 4), -1));
}

public cProcessUserAchievement(Handle:hOwner, Handle:hQuery, const String:sError[], any:data) 
{
	if (hQuery == INVALID_HANDLE)
	{
		LogError("Error in sql query: %s", sError);
		return;
	}
	new iAchievementId = iPassInt[data][1];
	new iUser = iPassInt[data][0];
	new iAchCnt = iPassInt[data][2];
	new String:sSteamId[32];
	GetClientAuthString(iUser, sSteamId, sizeof(sSteamId));
	if (SQL_GetRowCount(hQuery) != 1)
	{
		new String:sQuery[512];
		Format(sQuery, sizeof(sQuery), "INSERT INTO `%susers` (`steamid`, `aid`, `interval`) VALUES ('%s', %i, 1);", sTablePrefix, sSteamId, iAchievementId);
		SQL_TQuery(hDatabaseConnection, cDiscardSQL, sQuery);
		if (iAchCnt == 1)
		{
			new String:sQuery2[512];
			Format(sQuery2, sizeof(sQuery2), "SELECT * FROM `%sconfig` WHERE `id` = %i;", sTablePrefix, iAchievementId);
			SQL_TQuery(hDatabaseConnection, cShowAchievement, sQuery2, iUser);
		}
		return;
	}
	
	SQL_FetchRow(hQuery);
	new iUserProc = SQL_FetchInt(hQuery, 1);
	if (iUserProc+1 == iAchCnt)
	{
		new String:sAchievementName[128];
		SQL_FetchString(hQuery, 0, sAchievementName, sizeof(sAchievementName));
		AchievementEffect(iUser, sAchievementName);
		new String:sQuery[512];
		Format(sQuery, sizeof(sQuery), "UPDATE `%susers` SET `interval` = %i WHERE `steamid` = '%s' AND `aid` = %i;", sTablePrefix, iAchCnt, sSteamId, iAchievementId);
		SQL_TQuery(hDatabaseConnection, cDiscardSQL, sQuery);
	}
	else if (iUserProc+1 < iAchCnt)
	{
		new String:sQuery[512];
		Format(sQuery, sizeof(sQuery), "UPDATE `%susers` SET `interval` = `interval`+1 WHERE `steamid` = '%s' AND `aid` = %i;", sTablePrefix, sSteamId, iAchievementId);
		SQL_TQuery(hDatabaseConnection, cDiscardSQL, sQuery);
	}
}

public cShowAchievement(Handle:hOwner, Handle:hQuery, const String:sError[], any:data) 
{
	if (hQuery == INVALID_HANDLE)
	{
		LogError("Error in sql query: %s", sError);
		return;
	}
	SQL_FetchRow(hQuery);
	new String:sAchievementName[128];
	SQL_FetchString(hQuery, 1, sAchievementName, sizeof(sAchievementName));
	AchievementEffect(data, sAchievementName);
}

public bool:InvalidClient(client)
{
	if (client < 1)
		return true;
	
	if (!IsClientConnected(client))
		return true;
	
	if (!IsClientInGame(client))
		return true;
	
	if (IsFakeClient(client))
		return true;
	
	return false;
}


//----------------------------------------CODE OF linux_lover code ---------------------------------------------


AchievementEffect(client, const String:strName[])
{
	new Float:flVec[3];
	GetClientEyePosition(client, flVec);
	
	EmitAmbientSound(ACHIEVEMENT_SOUND, flVec, client, SNDLEVEL_RAIDSIREN);
	
	AttachAchievementParticle(client);
	
	new String:strMessage[200];
	//Phrase en Fr !
	//TODO : Possibilit� de rajouter un fichier de traduction !
	Format(strMessage, sizeof(strMessage), "\x03%N\x01 has earned the Custom Achievement \x05%s", client, strName);
	
	SayText2(client, strMessage);
}

AttachAchievementParticle(client)
{
	new iParticle = CreateEntityByName("info_particle_system");
	
	new String:strName[128];
	if (IsValidEdict(iParticle))
	{
		new Float:flPos[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", flPos);
		TeleportEntity(iParticle, flPos, NULL_VECTOR, NULL_VECTOR);
		
		Format(strName, sizeof(strName), "target%i", client);
		DispatchKeyValue(client, "targetname", strName);
		
		DispatchKeyValue(iParticle, "targetname", "tf2particle");
		DispatchKeyValue(iParticle, "parentname", strName);
		DispatchKeyValue(iParticle, "effect_name", ACHIEVEMENT_PARTICLE);
		DispatchSpawn(iParticle);
		SetVariantString(strName);
		AcceptEntityInput(iParticle, "SetParent", iParticle, iParticle, 0);
		SetVariantString("head");
		AcceptEntityInput(iParticle, "SetParentAttachment", iParticle, iParticle, 0);
		ActivateEntity(iParticle);
		AcceptEntityInput(iParticle, "start");
		
		CreateTimer(5.0, Timer_DeleteParticles, iParticle);
	}
}

public Action:Timer_DeleteParticles(Handle:timer, any:iParticle)
{
    if (IsValidEntity(iParticle))
    {
        new String:strClassname[256];
        GetEdictClassname(iParticle, strClassname, sizeof(strClassname));
		
        if (StrEqual(strClassname, "info_particle_system", false))
        {
            RemoveEdict(iParticle);
        }
    }
}

stock SayText2(author_index , const String:message[] ) {
    new Handle:buffer = StartMessageAll("SayText2");
    if (buffer != INVALID_HANDLE) {
        BfWriteByte(buffer, author_index);
        BfWriteByte(buffer, true);
        BfWriteString(buffer, message);
        EndMessage();
    }
}

stock SayText2One( client_index , author_index , const String:message[] ) {
    new Handle:buffer = StartMessageOne("SayText2", client_index);
    if (buffer != INVALID_HANDLE) {
        BfWriteByte(buffer, author_index);
        BfWriteByte(buffer, true);
        BfWriteString(buffer, message);
        EndMessage();
    }
}

public Action:cShowAchievements(client, args)
{
	new String:strAuthId[50];
	GetClientAuthString(client, strAuthId, sizeof(strAuthId));
	
	new String:strUrl[255];
	GetConVarString(cvURL, strUrl, sizeof(strUrl));
	
	new String:strFinal[255];
	Format(strFinal, sizeof(strFinal), "%s?u=%s", strUrl, strAuthId);
	//PrintToServer("D E B U G : \"%s\"!", strFinal)
	ShowMOTDPanel(client, "_:", strFinal, MOTDPANEL_TYPE_URL);
	
	return Plugin_Handled;
}

//-------------------ADD BY PFSM999------------------------
cShowAchievements2(client)
{
	new String:strAuthId[50];
	GetClientAuthString(client, strAuthId, sizeof(strAuthId));
	
	new String:strUrl[255];
	GetConVarString(cvURL, strUrl, sizeof(strUrl));
	
	new String:strFinal[255];
	Format(strFinal, sizeof(strFinal), "%s?u=%s", strUrl, strAuthId);
	//PrintToServer("D E B U G : \"%s\"!", strFinal)
	ShowMOTDPanel(client, "_:", strFinal, MOTDPANEL_TYPE_URL);
	
}

//-------------------CODE OF ROCK TO THE VOTE AND MODIFY BY PFSM999------------------------
//WHEN A PERSON SAY ON THE CHAT BOX (In Team or for all) "achievements" or "achievement"
//We show thier achievement by the Metode : cShowAchievements2
public Action:Command_Say(client, args)
{
	decl String:text[192];
	if (!GetCmdArgString(text, sizeof(text)))
	{
		return Plugin_Continue;
	}
	
	new startidx = 0;
	if(text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
	
	new ReplySource:old = SetCmdReplySource(SM_REPLY_TO_CHAT);
	
	if (strcmp(text[startidx], "achievements", true) == 0 || strcmp(text[startidx], "achievement", true) == 0)
	{
		cShowAchievements2(client);
	}
	
	SetCmdReplySource(old);
	
	return Plugin_Continue;	
}

//----------------------------CODE OF PFSM999 and Jindo -----------------------------------

stock Initial()
{
	GetConVarString(cvTablePrefix, sTablePrefix, sizeof(sTablePrefix));
	// First try to get a database connection
	decl String:error[255];
	new Handle:db;
	
	new String:sDB[128];
	GetConVarString(cvDB, sDB, sizeof(sDB));
	db = SQL_Connect(sDB, true, error, sizeof(error));
	
	if (db == INVALID_HANDLE)
	{
		LogError("Could not connect to database \"%s\": %s", sDB, error);
		return;
	}
	//On creer les DataPacks qui vont tout recevoir de la BD !
	g_bd_id = CreateDataPack();
	g_bd_ida = CreateDataPack();
	g_bd_victim_bool = CreateDataPack();
	g_bd_attacker_bool = CreateDataPack();
	g_bd_assister_bool = CreateDataPack();
	g_bd_victim_steamid = CreateDataPack();
	g_bd_attacker_steamid= CreateDataPack();
	g_bd_assister_steamid= CreateDataPack();
	g_bd_weapon= CreateDataPack();
	g_bd_map= CreateDataPack();
	g_bd_victim_name= CreateDataPack();
	g_bd_attacker_name= CreateDataPack();
	g_bd_assister_name= CreateDataPack();
	g_bd_domination= CreateDataPack();
	g_bd_revenge= CreateDataPack();
	g_bd_headshot= CreateDataPack();
	g_bd_backstab= CreateDataPack();
	g_bd_deadringer= CreateDataPack();
	g_bd_class= CreateDataPack();
	
	decl String:query[255];
	new Handle:hQuery;
	Format(query, sizeof(query), "SELECT * FROM `%sserver`",sTablePrefix);
	if ((hQuery = SQL_Query(db, query)) == INVALID_HANDLE)
	{
		SQL_GetError(db, error, sizeof(error));
		LogError("'Count query' failed: %s", query);
		LogError("Query error: %s", error);
		return;
	}
	g_maxAchievements = 0;
	while (SQL_FetchRow(hQuery))
	{
		WritePackCell(g_bd_id,SQL_FetchInt(hQuery, 0));
		WritePackCell(g_bd_ida,SQL_FetchInt(hQuery, 1));
		WritePackCell(g_bd_victim_bool,SQL_FetchInt(hQuery, 2));
		WritePackCell(g_bd_attacker_bool,SQL_FetchInt(hQuery, 3));
		WritePackCell(g_bd_assister_bool,SQL_FetchInt(hQuery, 4));
		decl String:steamid[25];
		SQL_FetchString(hQuery, 5, steamid, sizeof(steamid));
		WritePackString(g_bd_victim_steamid,steamid);
		SQL_FetchString(hQuery, 6, steamid, sizeof(steamid));
		WritePackString(g_bd_attacker_steamid,steamid);
		SQL_FetchString(hQuery, 7, steamid, sizeof(steamid));
		WritePackString(g_bd_assister_steamid,steamid);
		decl String:weapon[128];
		SQL_FetchString(hQuery, 8, weapon, sizeof(weapon));
		WritePackString(g_bd_weapon,weapon);
		decl String:map[128];
		SQL_FetchString(hQuery, 9, map, sizeof(map));
		WritePackString(g_bd_map,map);
		decl String:victime[50];
		SQL_FetchString(hQuery, 10, victime, sizeof(victime));
		WritePackString(g_bd_victim_name,victime);
		SQL_FetchString(hQuery, 11, victime, sizeof(victime));
		WritePackString(g_bd_attacker_name,victime);
		SQL_FetchString(hQuery, 12, victime, sizeof(victime));
		WritePackString(g_bd_assister_name,victime);
		WritePackCell(g_bd_domination,SQL_FetchInt(hQuery, 13));
		WritePackCell(g_bd_revenge,SQL_FetchInt(hQuery, 14));
		WritePackCell(g_bd_headshot,SQL_FetchInt(hQuery, 15));
		WritePackCell(g_bd_backstab,SQL_FetchInt(hQuery, 16));
		WritePackCell(g_bd_deadringer,SQL_FetchInt(hQuery, 17));
		SQL_FetchString(hQuery, 18, victime, sizeof(victime));
		WritePackString(g_bd_class,victime);
		g_maxAchievements = g_maxAchievements +1;
	}
	LogMessage("%i achievements charged", g_maxAchievements);

	CloseHandle(db);
	
}

public Action:eCheckFile(Handle:event, const String:name[], bool:noBroadcast)
{
	
	g_victim = GetClientOfUserId(GetEventInt(event, "userid"));
	g_attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	GetEventString(event, "weapon_logclassname", g_weapon, sizeof(g_weapon));
	g_customkill = GetEventInt(event, "customkill");
	g_headshot = GetEventBool(event, "headshot");
	g_domination = GetEventBool(event, "dominated");
	g_revenge = GetEventBool(event, "revenge");
	g_assister = GetClientOfUserId(GetEventInt(event, "assister"));
	g_deadringer =  GetEventInt(event, "death_flags");
	
	
	if (g_deadringer & 32)
	{
		g_deadringer = 1;	
	}
	else
	{
		g_deadringer = 0;	
	}
	GetCurrentMap(g_map,sizeof(g_map));
		
	SetPackPosition(g_bd_id,0);
	SetPackPosition(g_bd_ida,0);
	SetPackPosition(g_bd_victim_bool,0);
	SetPackPosition(g_bd_attacker_bool,0);
	SetPackPosition(g_bd_assister_bool,0);
	SetPackPosition(g_bd_victim_steamid,0);
	SetPackPosition(g_bd_attacker_steamid,0);
	SetPackPosition(g_bd_assister_steamid,0);
	SetPackPosition(g_bd_weapon,0);
	SetPackPosition(g_bd_map,0);
	SetPackPosition(g_bd_victim_name,0);
	SetPackPosition(g_bd_attacker_name,0);
	SetPackPosition(g_bd_assister_name,0);
	SetPackPosition(g_bd_domination,0);
	SetPackPosition(g_bd_revenge,0);
	SetPackPosition(g_bd_headshot,0);
	SetPackPosition(g_bd_backstab,0);
	SetPackPosition(g_bd_deadringer,0);
	SetPackPosition(g_bd_class,0);
	
	
	for (new i = 0; i < g_maxAchievements; i++)
	{
		new ach_id = CompareConditions(i);
		if (ach_id != 0)
		{
			if (g_target == 0)
			{
				ProcessAchievement(ach_id, g_attacker);
				LogMessage("+1 of the achivement : %u",ach_id);
			} else {
				if(g_target == 1)
				{
					ProcessAchievement(ach_id, g_victim);
					LogMessage("+1 of the achivement : %u",ach_id);
				}
				else
				{
					ProcessAchievement(ach_id, g_assister);
					LogMessage("+1 of the achivement : %u",ach_id);
				}
			}
		}
		else
		{
				//LogMessage("Dommage");
		}
	}
	
	return Plugin_Handled;
}

stock CompareConditions(aid)
{
			
		// GENERAL
		//LogMessage("Achivement num�ro 1 : %i",aid);
		new aidi = ReadPackCell(g_bd_ida);
		//LogMessage("Achivement num�ro BD : %i",aidi);
		new attacker = g_attacker;
		new victim = g_victim;
		new assister = g_assister;
		new suicide = 0;
		// WEAPON DETAIL
		
		new customkill = g_customkill;
		new kvHeadshot = ReadPackCell(g_bd_headshot);
		new kvBackstab = ReadPackCell(g_bd_backstab);
		new kvDominated = ReadPackCell(g_bd_domination);
		new kvRevenge = ReadPackCell(g_bd_revenge);
		new kvTarget;
		
		if(attacker == 0 && assister == 0)
		{
			suicide=1;
		}
	
		if(ReadPackCell(g_bd_victim_bool)==1)
		{
			kvTarget=1;
			if (suicide==0)
				g_class =  TF2_GetPlayerClass(attacker);
		}else
		{
			if(ReadPackCell(g_bd_attacker_bool)==1)
			{
				kvTarget=0;
				if (suicide==0)
					g_class =  TF2_GetPlayerClass(victim);
			}
			else
			{
				if(ReadPackCell(g_bd_assister_bool)==1)
				{
					kvTarget=2;
					if(assister !=0)
						g_class =  TF2_GetPlayerClass(assister);
				}
			}
		}
		
		new kvdeadringer = ReadPackCell(g_bd_deadringer);
		g_target = kvTarget;
		
		// NAME STUFF
		
		decl String:victimName[256];
		GetClientName(victim, victimName, sizeof(victimName));
		decl String:attackName[256];
		GetClientName(attacker, attackName, sizeof(attackName));
		decl String:assisterName[256];
		GetClientName(assister, assisterName, sizeof(assisterName));
		
		decl String:kvVictName[50];
		ReadPackString(g_bd_victim_name,kvVictName,sizeof(kvVictName));

		decl String:kvAtckName[50];
		ReadPackString(g_bd_attacker_name,kvAtckName,sizeof(kvAtckName));
		
		decl String:kvAssistName[50];
		ReadPackString(g_bd_assister_name,kvAssistName,sizeof(kvAssistName));
		// STEAM ID STUFF
		
		decl String:victimID[256];
		GetClientAuthString(victim, victimID, sizeof(victimID));
		decl String:attackID[256];
		if(attacker !=0)
			GetClientAuthString(attacker, attackID, sizeof(attackID));
		decl String:assisteID[256];
		if(assister !=0)
			GetClientAuthString(assister, assisteID, sizeof(assisteID));
		
		
		decl String:kvVictimID[256];
		ReadPackString(g_bd_victim_steamid,kvVictimID,sizeof(kvVictimID));
		
		
		decl String:kvAtckerID[256];
		ReadPackString(g_bd_attacker_steamid,kvAtckerID,sizeof(kvAtckerID));
		
		decl String:kvAssisteID[256];
		if(assister !=0)
		{
			ReadPackString(g_bd_assister_steamid,kvAssisteID,sizeof(kvAssisteID));
		}
		
		// WEAPON STUFF
		decl String:weapon[128];
		strcopy(weapon, sizeof(weapon), g_weapon);
		decl String:kvWeapon[128];
		ReadPackString(g_bd_weapon,kvWeapon,sizeof(kvWeapon));
				
		// MAP NAME
		decl String:map[32];
		strcopy(map, sizeof(map), g_map);
		decl String:kvMap[32];
		ReadPackString(g_bd_map,kvMap,sizeof(kvMap));
		
		// CLASS NAME
		decl String:kvClass[32];
		ReadPackString(g_bd_class,kvClass,sizeof(kvClass));

		// THE COMPARISON
		
		if(attacker !=0)
		{
			if (attacker == victim)
			{
				//LogMessage("Dommage : 1");
				return 0;
			}
		}
		
		// WEAPONS
		
		if (!CompareWeapons(kvWeapon, weapon, customkill, kvHeadshot, kvBackstab))
		{
			//LogMessage("Dommage kvWeapon = %s, weapon= %s",kvWeapon,weapon);
			return 0;
		}
		
		//MAP
		if (!CompareMap(kvMap, map))
		{
			//LogMessage("Dommage : 3");
			return 0;
		}
		
		// STEAM ID

		if (!CompareSteamIDs(kvVictimID, victimID))
		{
			//LogMessage("Dommage : 5");
			return 0;
		}
		
		if(attacker !=0)
		{
			if (!CompareSteamIDs(kvAtckerID, victimID))
			{
				//LogMessage("Dommage : 4");
				return 0;
			}
		}
		
		if(assister !=0)
		{
			if (!CompareSteamIDs(kvAssisteID, assisteID))
			{
				//LogMessage("Dommage : 6");
				return 0;
			}
		}
		
		// NAME CONTAINS
		
		if (!CompareNames(kvVictName, victimName))
		{
			//LogMessage("Dommage : 7");
			return 0;
		}
		
		if(attacker !=0)
		{
			if (!CompareNames(kvAtckName, attackName))
			{
				//LogMessage("Dommage : 8");
				return 0;
			}
		}
		
		if(assister !=0)
		{
			if (!CompareNames(kvAssistName, assisterName))
			{
				//LogMessage("Dommage : 8");
				return 0;
			}
		}
		
		
		
		//DOMINATED
		
		if (!CompareDominated(kvDominated, g_domination))
		{
			//LogMessage("Dommage : 9");
			return 0;
		}
		
		//REVENGE
		
		if (!CompareRevenge(kvRevenge, g_revenge))
		{
			//LogMessage("Dommage : 10");
			return 0;
		}
		
		//DEAD RINGER
		if (g_deadringer != kvdeadringer)
		{
			//LogMessage("Dommage : 11");
			return 0;
		}
		
		if (g_deadringer == 1)
			g_target = 1;
		
		//CLASS
		if (!CompareClass(kvClass, g_class))
		{
			//LogMessage("Dommage : 12");
			return 0;
		}
		
		return aidi;
		
}

stock bool:CompareDominated(kv_domination,event_domination)
{
	if(kv_domination != event_domination)
	{
		return false;
	}
	return true;
}

stock bool:CompareMap(const String:kv_map[],const String:event_map[])
{
	if (!StrEqual(kv_map, "any", false))
	{
		
		if (!StrEqual(kv_map, event_map, false))
		{
			return false;
		}
		
	}
	return true;
}

stock bool:CompareClass(const String:kv_class[],const TFClassType:event_class)
{
	if (!StrEqual(kv_class, "any", false))
	{
		
		if (event_class == TF2_GetClass(kv_class))
		{
			return false;
		}
		
	}
	return true;
}


stock bool:CompareRevenge(kv_revenge,event_revenge)
{
	if(kv_revenge != event_revenge)
	{
		return false;
	}
	return true;
}


stock bool:CompareWeapons(const String:kv_weapon[], const String:event_weapon[], event_customkill, kv_headshot, kv_backstab)
{
	if (!StrEqual(kv_weapon, "any", false))
	{
		
		if (!StrEqual(kv_weapon, event_weapon, false))
		{
			return false;
		}
		
	}
	
	if (event_customkill != 0)
	{
		if (kv_headshot == 1)
		{
			if (event_customkill != 1 || !g_headshot)
			{
				return false;
			}
			return true;
		}
		if (kv_backstab == 1)
		{
			if (event_customkill != 2)
			{
				return false;
			}
			return true;
		}
	} else
	{
		if (kv_headshot == 2)
		{
			if (event_customkill != 0 || !g_headshot)
			{
				return false;
			}
			return true;
		}
		if (kv_backstab == 2)
		{
			if (event_customkill != 0)
			{
				return false;
			}
		}
	}
	
	return true;
}

stock bool:CompareSteamIDs(const String:kv_steamid[], const String:event_steamid[])
{
	if (!StrEqual(kv_steamid, "any", false))
	{
		if (!StrEqual(kv_steamid, event_steamid, false))
		{
			return false;
		}
		return true;
	}
	return true;
}

stock bool:CompareNames(const String:kv_namecon[], const String:event_name[])
{
	if (!StrEqual(kv_namecon, "any", false))
	{
		if (!StrContains(event_name, kv_namecon, true))
		{
			return false;
		}
		return true;
	}
	return true;
}
