#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>


#define PLUGIN_VERSION "2.0.0"
#define MAX_FILE_LEN 128


public Plugin:myinfo = 
{
	name = "Welcome Sound",
	author = "Experto",
	description = "Toca som para o player quando ele entra no servidor",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.net"
};


new Handle:DB_WSOUND = INVALID_HANDLE;

new Handle:wsoundEnable = INVALID_HANDLE;
new Handle:wsoundFile = INVALID_HANDLE;
new String:soundFile[MAX_FILE_LEN];
new Handle:wstopSpawn = INVALID_HANDLE;
new Handle:wclientStop = INVALID_HANDLE;
new Handle:wsoundType = INVALID_HANDLE;
new Handle:wannounceStop = INVALID_HANDLE;


public OnPluginStart()
{
	ConnectDB();

	CreateConVar("sm_wsound_version", PLUGIN_VERSION, "Welcome Sound", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	wsoundEnable = CreateConVar("sm_wsound_enable", "1", "Liga/Desliga o Som de boas vindas. [0 = Desligado, 1 = Ligado]", _, true, 0.0, true, 1.0);
	wsoundFile = CreateConVar("sm_wsound_file", "ambient/music/dustmusic1.wav", "Endereco do arquivo de som");
	wstopSpawn = CreateConVar("sm_wsound_stop_spawn", "1", "Parar o Som quando o jogador escolher um time? [0 = Nao, 1 = Sim]", _, true, 0.0, true, 1.0);
	wclientStop = CreateConVar("sm_wsound_client_stop", "1", "Cliente pode usar o comando !stop e parar o Som? [0 = Nao, 1 = Sim]", _, true, 0.0, true, 1.0);
	wsoundType = CreateConVar("sm_wsound_type", "1", "Tipo de execução. [1 = Para Todos, 2 = Apenas para jogadores cadastrados]", _, true, 1.0, true, 2.0);
	wannounceStop = CreateConVar("sm_wsound_announce_stop", "1", "Anunciar o comando !stop? [0 = Nao, 1 = Sim]", _, true, 0.0, true, 1.0);

	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);

	RegConsoleCmd("say", CommandStop);
	RegConsoleCmd("say_team", CommandStop);

	RegAdminCmd("sm_wsound_add", SoundAdd, ADMFLAG_BAN, "Adiciona um som para tocar quando um jogador especifico entrar");
	RegAdminCmd("sm_wsound_del", SoundRemove, ADMFLAG_BAN, "Remove um jogador da lista de imunidade do Auto Swap Team");
	RegAdminCmd("sm_wsound_list", SoundList, ADMFLAG_BAN, "Exibe a lista de imunidade do Auto Swap Team");

	AutoExecConfig(true, "welcomesound");

	LoadTranslations("welcomesound.phrases");

	CacheSounds();
}


public OnConfigsExecuted()
{
	CacheSounds();
}


public OnMapStart()
{
	CacheSounds();
}


public OnClientPostAdminCheck(client)
{
	if (GetConVarBool(wsoundEnable))
	{
		PlaySoundClient(client);

		if (GetConVarBool(wannounceStop))
		{
			PrintToChat(client,"[W-Sound] %t","alert_stop");
		}
	}
}


public OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(wstopSpawn))
	{
		new clientId = GetEventInt(event, "userid");
		new client = GetClientOfUserId(clientId);

		new team = GetClientTeam(client);

		if(team > 0)
		{
			StopSoundClient(client);
		}
	}
}


public Action:CommandStop(client, args)
{
	if (!client)
	{
		return Plugin_Continue;
	}
	
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
	
	if (strcmp(text[startidx], "!stop", false) == 0)
	{
		if (GetConVarBool(wclientStop))
		{
			StopSoundClient(client);
		}
	}
	
	SetCmdReplySource(old);
	
	return Plugin_Continue;	
}


public CacheSounds()
{
	GetConVarString(wsoundFile, soundFile, sizeof(soundFile));

	if (GetConVarBool(wsoundEnable))
	{
		if (!StrEqual(soundFile, ""))
		{
			PrepareSound(soundFile);
		}

		new String:query[200];

		Format(query, sizeof(query), "SELECT soundFile FROM welcomesounds");

		new Handle:hQuery = SQL_Query(DB_WSOUND, query);

		if (hQuery != INVALID_HANDLE)
		{
			while (SQL_FetchRow(hQuery))
			{
				decl String:strSoundFile[MAX_FILE_LEN];

				SQL_FetchString(hQuery, 0, strSoundFile, sizeof(strSoundFile));

				PrepareSound(strSoundFile);
			}
		}

		CloseHandle(hQuery);

	}
}


public PrepareSound(String: sound[MAX_FILE_LEN])
{
	decl String:fileSound[MAX_FILE_LEN];

	Format(fileSound, MAX_FILE_LEN, "sound/%s", sound);

	if (FileExists(fileSound))
	{
		PrecacheSound(sound, true);
		AddFileToDownloadsTable(fileSound);
	}
	else
	{
		PrintToServer("[W-Sound] ERROR: Arquivo de som '%s' nao existe!",fileSound);
	}
}


PlaySoundClient(client)
{
	if(IsValidClient(client) && !IsBot(client))
	{
		decl String:clientSoundFile[MAX_FILE_LEN];
		clientSoundFile = GetSoundFileByIdClient(client);

		if (GetConVarInt(wsoundType) == 1)
		{
			if (!StrEqual(clientSoundFile, ""))
			{
				EmitSoundToClient(client,clientSoundFile);
			}
			else
			{
				EmitSoundToClient(client,soundFile);
			}
		}

		if (GetConVarInt(wsoundType) == 2)
		{
			if (!StrEqual(clientSoundFile, ""))
			{
				EmitSoundToClient(client,clientSoundFile);
			}
		}
	}
}


StopSoundClient(client)
{
	StopSound(client, SNDCHAN_AUTO,soundFile);
}


bool:IsValidClient(client)
{
	if (IsClientInGame(client) && !IsFakeClient(client) && IsClientAuthorized(client))
	{
		return true;
	}
	else
	{
		return false;
	}
}


bool:IsBot(client)
{
	if (IsClientInGame(client) && IsFakeClient(client))
	{
		return true;
	}
	else
	{
		return false;
	}
}


//---------------------------------------------------


ConnectDB()
{
	new String:error[255];

	DB_WSOUND = SQLite_UseDatabase("welcomesound", error, sizeof(error));

	if (DB_WSOUND == INVALID_HANDLE)
	{
		SetFailState("SQL error: %s", error);
	}

	SQL_LockDatabase(DB_WSOUND);

	SQL_FastQuery(DB_WSOUND, "CREATE TABLE IF NOT EXISTS welcomesounds (steamId TEXT, soundFile TEXT)");
	SQL_FastQuery(DB_WSOUND, "CREATE UNIQUE INDEX IF NOT EXISTS pk_steamId ON welcomesounds(steamId ASC)");

	SQL_UnlockDatabase(DB_WSOUND);
}



public Action:SoundAdd(client, args) 
{
	if (args < 2)
	{
		ReplyToCommand(client, "[W-Sound] Usage: sm_wsound_add <steamId> <soundFile>");
		return Plugin_Handled;
	}

	decl String:params[54];
	GetCmdArgString(params, sizeof(params));

	decl String:steamId[50];
	decl String:strSoundFile[MAX_FILE_LEN];

	new len = BreakString(params, steamId, sizeof(steamId));

	if (len > 0)
	{
		if (strncmp(steamId, "STEAM_", 6) != 0 || steamId[7] != ':')
		{
			ReplyToCommand(client, "[W-Sound] %t", "invalid_steamid");
			return Plugin_Handled;
		}
	}
	else
	{
		ReplyToCommand(client, "[W-Sound] Usage: sm_wsound_add <steamId> <soundFile>");
		return Plugin_Handled;
	}

	if (findSteamId(steamId))
	{
		ReplyToCommand(client, "[W-Sound] %t : %s", "sound_add_duplicate",steamId);
		return Plugin_Handled;
	}

	BreakString(params[len], strSoundFile, sizeof(strSoundFile));

	decl String:file[MAX_FILE_LEN];
	Format(file, MAX_FILE_LEN, "sound/%s", strSoundFile);

	if (!FileExists(file))
	{
		ReplyToCommand(client, "[W-Sound] %t %s", "file_not_found",file);
		return Plugin_Handled;
	}

	decl String:query[200];

	Format(query, sizeof(query), "INSERT INTO welcomesounds(steamId, soundFile) VALUES ('%s', '%s');", steamId, strSoundFile);

	if (SQL_FastQuery(DB_WSOUND, query))
	{
		ReplyToCommand(client, "[W-Sound] %t", "sound_add_success");
	}
	else
	{
		ReplyToCommand(client, "[W-Sound] %t", "sound_add_error");
	}

	return Plugin_Handled;
} 



public Action:SoundRemove(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[W-Sound] Usage: sm_wsound_del <steamId>");
		return Plugin_Handled;
	}

	decl String:params[54];
	GetCmdArgString(params, sizeof(params));

	decl String:steamId[50];
	BreakString(params, steamId, sizeof(steamId));

	if (findSteamId(steamId))
	{
		decl String:query[200];
		Format(query, sizeof(query), "DELETE FROM welcomesounds WHERE steamId = '%s';", steamId);

		if (SQL_FastQuery(DB_WSOUND, query))
		{
			ReplyToCommand(client, "[W-Sound] %t", "sound_del_success");
		}
		else
		{
			ReplyToCommand(client, "[W-Sound] %t", "sound_del_error");
		}
	}
	else
	{
		ReplyToCommand(client, "[W-Sound] %t", "sound_not_found");
	}

	return Plugin_Handled;
}



String:GetSoundFileByIdClient(client)
{
	decl String:strSoundFile[MAX_FILE_LEN];
	strSoundFile = "";

	if(IsValidClient(client))
	{
		if (findClientId(client))
		{
			decl String:steamId[50];
			GetClientAuthString(client, steamId, sizeof(steamId));

			new String:query[200];
			Format(query, sizeof(query), "SELECT soundFile FROM welcomesounds WHERE steamId = '%s'", steamId);
		 
			new Handle:hQuery = SQL_Query(DB_WSOUND, query);

			if ((hQuery != INVALID_HANDLE) && SQL_FetchRow(hQuery))
			{
				SQL_FetchString(hQuery, 0, strSoundFile, sizeof(strSoundFile));
			}

			CloseHandle(hQuery);
		}
	}

	return strSoundFile;
}



public Action:SoundList(client, args)
{
	new String:query[200];

	if (args < 1)
	{
		Format(query, sizeof(query), "SELECT steamId, soundFile FROM welcomesounds");
	}
	else
	{
		decl String:params[54];
		GetCmdArgString(params, sizeof(params));

		decl String:steamId[50];
		BreakString(params, steamId, sizeof(steamId));

		Format(query, sizeof(query), "SELECT steamId, soundFile FROM welcomesounds WHERE steamId = '%s'", steamId);
	}

	new Handle:hQuery = SQL_Query(DB_WSOUND, query);

	if (hQuery != INVALID_HANDLE)
	{
		ReplyToCommand(client, "[W-Sound] STEAM_ID | SOUND FILE");
		ReplyToCommand(client, "-----------------------------------------------------");

		while (SQL_FetchRow(hQuery))
		{
			decl String:steam[50];
			decl String:strSoundFile[MAX_FILE_LEN];

			SQL_FetchString(hQuery, 0, steam, sizeof(steam));
			SQL_FetchString(hQuery, 1, strSoundFile, sizeof(strSoundFile));

			ReplyToCommand(client, "[W-Sound] %s | %s", steam, strSoundFile);
		}

		ReplyToCommand(client, "-----------------------------------------------------");
	}

	CloseHandle(hQuery);

	return Plugin_Handled;
}


bool:findSteamId(String: steamId[50])
{
	decl String:strSteamId[50];
	strSteamId = "";

	new String:query[200];
	Format(query, sizeof(query), "SELECT steamId FROM welcomesounds WHERE steamId = '%s'", steamId);
	 
	new Handle:hQuery = SQL_Query(DB_WSOUND, query);

	if ((hQuery != INVALID_HANDLE) && SQL_FetchRow(hQuery))
	{
		SQL_FetchString(hQuery, 0, strSteamId, sizeof(strSteamId));
	}

	CloseHandle(hQuery);

	if (!StrEqual(strSteamId, ""))
	{
		return true;
	}

	return false;
}


bool:findClientId(client)
{
	decl String:steamId[50];
	GetClientAuthString(client, steamId, sizeof(steamId));

	decl String:strSteamId[50];
	strSteamId = "";

	new String:query[200];
	Format(query, sizeof(query), "SELECT steamId FROM welcomesounds WHERE steamId = '%s'", steamId);
	 
	new Handle:hQuery = SQL_Query(DB_WSOUND, query);

	if ((hQuery != INVALID_HANDLE) && SQL_FetchRow(hQuery))
	{
		SQL_FetchString(hQuery, 0, strSteamId, sizeof(strSteamId));
	}

	CloseHandle(hQuery);

	if (!StrEqual(strSteamId, ""))
	{
		return true;
	}

	return false;
}