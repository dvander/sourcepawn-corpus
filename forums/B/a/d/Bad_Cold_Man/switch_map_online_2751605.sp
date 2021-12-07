#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define	PLUGIN_VERSION	"1.0.1"

new Handle:g_hCvarMinPlayers = INVALID_HANDLE, g_iMinPlayers, 
	Handle:g_hCvarSetMaps = INVALID_HANDLE, String:g_sSetMaps[256], g_iSetMaps = 0, String:g_sSetMapSelect[20][256], String:g_sSetMapChange[128],
	Handle:g_hCvarTimer = INVALID_HANDLE, Float:g_fCvarTimer,
	Handle:g_hTimer = INVALID_HANDLE,
	Handle:g_hCvarSoundFile = INVALID_HANDLE, bool:g_bSound = false, String:g_sSound[PLATFORM_MAX_PATH],
	Handle:g_hCvarIsAdmins = INVALID_HANDLE, bool:g_bIsAdmins = false,
	bool:g_bIsAdminInGame = false, bool:g_bCurrentMap = false, String:g_sLogPath[128];

public Plugin:myinfo = 
{
	name = "Switch to another map from the small online",
	author = "GoDtm666",
	description = "Switch to another map from the small online on the server",
	version = PLUGIN_VERSION,
	url = "www.SourceTM.com"
}

public OnPluginStart()
{
	g_hCvarMinPlayers = CreateConVar("sm_smo_minplayers", "11", "Минимальное количество игроков, для смены карты.\nThe minimum number of players to change the map.", FCVAR_PLUGIN, true, 1.0, true, 64.0);
	MinPlayers_OnSettingsChanged(g_hCvarMinPlayers, "", "");
	HookConVarChange(g_hCvarMinPlayers, MinPlayers_OnSettingsChanged);
	g_hCvarSetMaps = CreateConVar("sm_smo_setmaps", "de_dust2", "На какую(ие) карту(ы) менять. Пример: (de_dust2,de_nuke,cs_assault Максимум 20 карт.)\nWhat kind(s) map(s) change. Example: (de_dust2,de_nuke,cs_assault maximum of 20 maps.)", FCVAR_PLUGIN);
	SetMaps_OnSettingsChanged(g_hCvarSetMaps, "", "");
	HookConVarChange(g_hCvarSetMaps, SetMaps_OnSettingsChanged);
	g_hCvarTimer = CreateConVar("sm_smo_maptime", "120", "Время до смены карты при маленьком онлайне.\nTime to change the map with a small online.", FCVAR_PLUGIN, true, 10.0);
	Timer_OnSettingsChanged(g_hCvarTimer, "", "");
	HookConVarChange(g_hCvarTimer, Timer_OnSettingsChanged);
	g_hCvarSoundFile = CreateConVar("sm_smo_soundfile_annonce", "", "Воспроизводить звуковой файл перед сменой карт(ы). Пример: \"sound/buttons/blip1.wav\"\nPlay an audio file before changing map(s). Example: \"sound/buttons/blip1.wav\"", FCVAR_PLUGIN);
	SoundFile_OnSettingsChanged(g_hCvarSoundFile, "", "");
	HookConVarChange(g_hCvarSoundFile, SoundFile_OnSettingsChanged);
	g_hCvarIsAdmins = CreateConVar("sm_smo_isadmins", "0", "Менять карту когда администратор с флагом ChangeMap находится на сервере.\nChange the map with a flag when the admin ChangeMap on the server.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	IsAdmins_OnSettingsChanged(g_hCvarIsAdmins, "", "");
	HookConVarChange(g_hCvarIsAdmins, IsAdmins_OnSettingsChanged);
	CreateConVar("sm_smo_version", PLUGIN_VERSION, "Switch to another map from the small online version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	BuildPath(Path_SM, g_sLogPath, sizeof(g_sLogPath), "logs/smo_maps_online.log");
	LoadTranslations("switch_map_online.phrases");
	LoadTranslations("common.phrases");
}

public MinPlayers_OnSettingsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_iMinPlayers = GetConVarInt(convar);
}

public SetMaps_OnSettingsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	GetConVarString(convar, g_sSetMaps, sizeof(g_sSetMaps));
	g_iSetMaps = ExplodeString(g_sSetMaps, ",", g_sSetMapSelect, sizeof(g_sSetMapSelect), sizeof(g_sSetMapSelect[]));
	if (g_bCurrentMap)
	{
		g_bCurrentMap = false;
		CalculationOfPlayers();
	}
}

public Timer_OnSettingsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_fCvarTimer = GetConVarFloat(convar);
}

public SoundFile_OnSettingsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new String:g_sSoundFile[PLATFORM_MAX_PATH];
	if (g_bSound)
	{
		g_bSound = false;
	}
	GetConVarString(convar, g_sSoundFile, sizeof(g_sSoundFile));
	if (FileExists(g_sSoundFile) && strlen(g_sSoundFile) > 0)
	{
		AddFileToDownloadsTable(g_sSoundFile);
		if (StrContains(g_sSoundFile, "sound/", false) == 0)
		{
			ReplaceStringEx(g_sSoundFile, sizeof(g_sSoundFile), "sound/", "", -1, -1, false);
			strcopy(g_sSound, sizeof(g_sSound), g_sSoundFile);
		}
		if (PrecacheSound(g_sSound, true))
		{
			g_bSound = true;
		}
		else
		{
			LogError("Failed to precache sound please make sure path is correct in \"%s\" and sound is in the sounds folder", g_sSoundFile);
		}
	}
	else 
	{
		if (strlen(g_sSoundFile) > 0)
		{
			LogError("Sound \"%s\" dosnt exist", g_sSoundFile);
		}
	}
}

public IsAdmins_OnSettingsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new bool:bNewValue = GetConVarBool(convar);
	if (bNewValue && !g_bIsAdmins)
	{
		g_bIsAdmins = true;
	}
	else if (!bNewValue && g_bIsAdmins)
	{
		g_bIsAdmins = false;
	}
}

public OnAllPluginsLoaded()
{
	AutoExecConfig(true, "switch_map_online", "sourcemod");
}

public OnMapStart()
{
	if (g_bCurrentMap)
	{
		g_bCurrentMap = false;
	}
	CalculationOfPlayers();
}

public OnClientPutInServer(client)
{
	if (!g_bIsAdminInGame || !g_bCurrentMap)
	{
		CalculationOfPlayers();
	}
}

public OnClientDisconnect_Post(client)
{
	if (!g_bCurrentMap)
	{
		CalculationOfPlayers();
	}
}

public CalculationOfPlayers()
{
	decl String:g_sCurrentMap[256];
	new g_iPlayerInServer = 0;
	GetCurrentMap(g_sCurrentMap, sizeof(g_sCurrentMap));
	if (g_hTimer != INVALID_HANDLE)
	{
		KillTimer(g_hTimer);
		g_hTimer = INVALID_HANDLE;
	}
	for (new l = 0; l < g_iSetMaps; l++)
	{
		strcopy(g_sSetMapChange, sizeof(g_sSetMapChange), g_sSetMapSelect[l]);
		if (StrEqual(g_sCurrentMap, g_sSetMapChange, false))
		{
			g_bCurrentMap = true;
			break;
		}
	}
	if (g_bCurrentMap)
	{
		return;
	}
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			g_iPlayerInServer++;
		}
	}
	if (g_iMinPlayers > g_iPlayerInServer)
	{
		g_hTimer = CreateTimer(g_fCvarTimer, LoadMapTimer);
	}
}

public Action:LoadMapTimer(Handle:timer)
{
	g_hTimer = INVALID_HANDLE;
	decl String:g_sCurrentMap[256];
	new g_iRandomMap = 0, g_iPlayerInServer = 0;
	if (g_bIsAdmins)
	{
		if (g_bIsAdminInGame)
		{
			g_bIsAdminInGame = false;
		}
	}
	else
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				if (CheckCommandAccess(i, "sm_map", ADMFLAG_CHANGEMAP, true))
				{
					if (!g_bIsAdminInGame)
					{
						g_bIsAdminInGame = true;
					}
					return Plugin_Continue;
				}
				else
				{
					if (g_bIsAdminInGame)
					{
						g_bIsAdminInGame = false;
					}
				}
				g_iPlayerInServer++;
			}
		}
	}
	GetCurrentMap(g_sCurrentMap, sizeof(g_sCurrentMap));
	if (g_bSound)
	{
		EmitSoundToAll(g_sSound);
	}
	PrintToChatAll("\x01[SM]\x03 %t", "AnnonceTimeChangeMap", g_sCurrentMap, g_iMinPlayers);
	if (g_iSetMaps > 1)
	{
		g_iRandomMap = GetRandomInt(0, g_iSetMaps - 1);
	}
	strcopy(g_sSetMapChange, sizeof(g_sSetMapChange), g_sSetMapSelect[g_iRandomMap]);
	LogToFileEx(g_sLogPath, "map: \"%s\" is players in game: (%i/%i). Change another map: \"%s\"", g_sCurrentMap, g_iPlayerInServer, MaxClients, g_sSetMapChange);
	PrintToChatAll("[SM] %t", "Changing map", g_sSetMapChange);
	CreateTimer(7.5, MapTimerChangeMap);
	return Plugin_Continue;
}

public Action:MapTimerChangeMap(Handle:timer)
{
	InsertServerCommand("changelevel %s", g_sSetMapChange);
	return Plugin_Continue;
}
