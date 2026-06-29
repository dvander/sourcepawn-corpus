#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.3"

#define ACHIEVEMENT_SOUND 		"misc/achievement_earned.wav"
#define ACHIEVEMENT_PARTICLE 	"Achieved"
#define SCORED_SOUND			"player/taunt_bell.wav"

new Handle:cvURL = INVALID_HANDLE;
new Handle:cvDB = INVALID_HANDLE;
new Handle:cvTablePrefix = INVALID_HANDLE;

new Handle:hDatabaseConnection = INVALID_HANDLE;

new bool:bConnected = false;

new String:sTablePrefix[64];

new iPassInt[256][4];
new iCurPass = 0;

public Plugin:myinfo = 
{
	name = "Custom Achievements",
	author = "GachL, linux_lover",
	description = "Custom achievements",
	version = PLUGIN_VERSION,
	url = "http://bloodisgood.org"
}

public OnPluginStart()
{
	CreateConVar("sm_ca_version", PLUGIN_VERSION, "Custom Achievements Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvURL = CreateConVar("sm_ca_url", "http://bloodisgood.org/achievements/player.php", "Url to the php file that shows player achievements.");
	cvDB = CreateConVar("sm_ca_db", "default", "DB to use");
	cvTablePrefix = CreateConVar("sm_ca_prefix", "ach_", "Table prefix");
	
	RegConsoleCmd("achievements", cShowAchievements);
	RegConsoleCmd("achievement", cShowAchievements);
}

public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("ProcessAchievement", ProcessAchievement);
	return true;
}

public OnMapStart()
{
	PrecacheSound(ACHIEVEMENT_SOUND);
	PrecacheSound(SCORED_SOUND);
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
public ProcessAchievement(Handle:hPlugin, numParams)
{
	new iAchievementId = GetNativeCell(1);
	new hClient = GetNativeCell(2);
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

/**
 * linux_lover code
 */

AchievementEffect(client, const String:strName[])
{
	new Float:flVec[3];
	GetClientEyePosition(client, flVec);
	
	EmitAmbientSound(ACHIEVEMENT_SOUND, flVec, client, SNDLEVEL_RAIDSIREN);
	
	AttachAchievementParticle(client);
	
	new String:strMessage[200];
	Format(strMessage, sizeof(strMessage), "\x03%N\x01 has earned the achievement \x05%s", client, strName);
	
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
