#include <sdktools>
#include <clientprefs>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME "Round End Sound"

ConVar g_cEnabled;
ConVar g_cDirPath;
ConVar g_cIgnoreRoundEnd;
Cookie g_cookieResPref;
ArrayList g_arrSoundsList;

char g_sDirPath[PLATFORM_MAX_PATH];
bool g_bToggleRes[MAXPLAYERS] = {true, ...};
char g_sSavedValue[5];

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "Yaser2007",
	description = "Plays sound when round end (if a team winning)",
	version = "2.4",
	url = "https://www.sourcemod.net/plugins.php?cat=0&mod=-1&title=&author=Yaser2007&description=&search=1"
};

public void OnPluginStart()
{
	g_cEnabled = CreateConVar("res_enabled", "1", "Enable/disable round end sound.", _, true, 0.0, true, 1.0);
	g_cDirPath = CreateConVar("res_path", "res", "sound folder path relative to the \"sound\" folder.");
	g_cIgnoreRoundEnd = FindConVar("mp_ignore_round_win_conditions");
	HookConVarChange(g_cDirPath, OnDirPathChanged);
	GetConVarString(g_cDirPath, g_sDirPath, sizeof(g_sDirPath));

	AutoExecConfig(true, "round_end_sound");

	RegConsoleCmd("res", Cmd_ToggleRes, "On/Off Round End Sounds");
	RegServerCmd("res_reload", Cmd_ResReload);

	g_arrSoundsList = CreateArray(32);

	PrecacheSound("radio/ctwin.wav");
	PrecacheSound("radio/terwin.wav");

	HookEvent("round_end", Event_RoundEnd);
}

public void OnDirPathChanged(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	strcopy(g_sDirPath, sizeof(g_sDirPath), newValue);
}

public void OnMapStart()
{
	LoadSounds();

	char buffer[32];
	int size = GetArraySize(g_arrSoundsList);
	for(int i; i < size; i++)
	{
		GetArrayString(g_arrSoundsList, i, buffer, sizeof(buffer));
		PrecacheSound(buffer, true);
		Format(buffer, sizeof(buffer), "sound/%s", buffer);
		AddFileToDownloadsTable(buffer);
	}
}

public void OnConfigsExecuted()
{
	if(GetConVarBool(g_cEnabled) && !GetConVarBool(g_cIgnoreRoundEnd))
	{
		g_cookieResPref = RegClientCookie(PLUGIN_NAME, "Round End Sound Cookie", CookieAccess_Private);
		SetCookieMenuItem(ResPrefSelected, 0, PLUGIN_NAME);
	}
}

public void OnClientPutInServer(int client)
{
	OnClientCookiesCached(client);
}

public void OnClientCookiesCached(int client)
{
	if(GetConVarBool(g_cEnabled) && !GetConVarBool(g_cIgnoreRoundEnd) && AreClientCookiesCached(client) && IsClientInGame(client) && !IsFakeClient(client))
	{
		char buffer[5];
		GetClientCookie(client, g_cookieResPref, buffer, sizeof(buffer));
		g_bToggleRes[client] = !StrEqual(buffer, NULL_STRING) ? view_as<bool>(StringToInt(buffer)) : true;
	}
}

public Action Cmd_ToggleRes(int client, int args)
{
	if(GetConVarBool(g_cEnabled) && !GetConVarBool(g_cIgnoreRoundEnd))
	{
		if(g_bToggleRes[client] != false)
		{
			g_bToggleRes[client] = false;
			PrintToChat(client, "\x04[\x01RoundEndSound\x04] You won't now hear round end sounds");
		}
		else
		{
			g_bToggleRes[client] = true;
			PrintToChat(client, "\x04[\x01RoundEndSound\x04] You will now hear round end sounds");
		}
	}

	IntToString(view_as<bool>(g_bToggleRes[client]), g_sSavedValue, sizeof(g_sSavedValue));
	SetClientCookie(client, g_cookieResPref, g_sSavedValue);

	return Plugin_Handled;
}

public Action Cmd_ResReload(int args)
{
	LoadSounds();
	PrintToServer("RES Reloaded.");
	return Plugin_Handled;
}

public void ResPrefSelected(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	if(action == CookieMenuAction_DisplayOption)
	{
		Format(buffer, maxlen, PLUGIN_NAME ... ": %s", g_bToggleRes[client] == true ? "On" : "Off", client);
	}
	else
	{
		g_bToggleRes[client] = !g_bToggleRes[client];
		IntToString(view_as<bool>(g_bToggleRes[client]), g_sSavedValue, sizeof(g_sSavedValue));
		SetClientCookie(client, g_cookieResPref, g_sSavedValue);
		ShowCookieMenu(client);
	}
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if(!GetConVarBool(g_cEnabled) && GetConVarBool(g_cIgnoreRoundEnd))
	{
		return Plugin_Continue;
	}

	int winner = GetEventInt(event, "winner");
	if(winner < 2)
	{
		return Plugin_Continue;
	}

	char buffer[32];
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || IsFakeClient(i) || !g_bToggleRes[i])
		{
			continue;
		}

		StopSound(i, SNDCHAN_STATIC, "radio/ctwin.wav");
		StopSound(i, SNDCHAN_STATIC, "radio/terwin.wav");

		GetArrayString(g_arrSoundsList, Math_GetRandomInt(0, GetArraySize(g_arrSoundsList) - 1), buffer, sizeof(buffer));
		EmitSoundToClient(i, buffer, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
	}

	return Plugin_Continue;
}

void LoadSounds()
{
	char buffer[64];
	FormatEx(buffer, sizeof(buffer), "sound/%s", g_sDirPath);
	DirectoryListing dir = OpenDirectory(buffer, true);

	if(dir == null)
	{
		SetFailState("directory '%s' doesn't exist!", buffer);
	}

	if(GetArraySize(g_arrSoundsList) > 0)
	{
		ClearArray(g_arrSoundsList);
	}

	char ext[4];
	FileType type;
	while(ReadDirEntry(dir, buffer, sizeof(buffer), type))
	{
		if(type != FileType_File)
		{
			continue;
		}

		GetFileExtension(buffer, ext, sizeof(ext));
		if(StrEqual(ext, "mp3") || StrEqual(ext, "wav"))
		{
			Format(buffer, sizeof(buffer), "%s/%s", g_sDirPath, buffer);
			PushArrayString(g_arrSoundsList, buffer);
		}
		else
		{
			LogError("Invalid sound: %s (Only mp3/wave)", buffer);
		}
	}

	LogMessage("%d sounds loaded.", GetArraySize(g_arrSoundsList));

	delete dir;
}

stock int Math_GetRandomInt(int min, int max)
{
	int random = GetURandomInt();

	if(random == 0)
	{
		random++;
	}

	return RoundToCeil(float(random) / (float(2147483647) / float(max - min + 1))) + min - 1;
}

stock void GetFileExtension(const char[] path, char[] buffer, int size)
{
	int extpos = FindCharInString(path, '.', true);

	if(extpos == -1)
	{
		buffer[0] = '\0';
		return;
	}

	strcopy(buffer, size, path[++extpos]);
}