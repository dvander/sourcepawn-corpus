 //
// DoDs Speed Bonus Round
// -----------------------------
// Based form <eVa>Dog's Dog Bonus Round, Modified by vintage, Modified by Micmacx
// http://dodsplugins.mtxserv.fr/ and https://forums.alliedmods.net/showthread.php?p=2811152
//
// Based for handling precached and load sounds : Admin Sounds 1.2.2 by Cadav0r 
// https://forums.alliedmods.net/showthread.php?p=785989
//
// Based for loading file to  plugin : SM Skinchooser Version: 5.2 by Andi67
// https://forums.alliedmods.net/showthread.php?t=87597
//
// For DoD:Source
// This plugin beacon the losing Team and give speed to the Winners
// Just to have a funny moment at round end
// -----------------------------
// Plugin is enhanced by Micmacx.
// Fix Beacon not work.
// Fix for don't playing sound to player who not downloading sound files.
// Added the ability to create 99 different configurations and change the configuration file at map start.
// Added debug log file.
// -----------------------------

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1"
#define BEACON_DELAY 1.5

new g_beamSprite
new g_haloSprite

new bool:Download_sounds[MAXPLAYERS + 1];
new bool:roundwin = false;
new String:WpnMelee[4][] =  { "", "", "weapon_amerknife", "weapon_spade" }


new Handle:cvar_brc_kicknodl = INVALID_HANDLE;
new Handle:cvar_brc_SoundEnable = INVALID_HANDLE;
new Handle:cvar_brc_SpeedEnable = INVALID_HANDLE;
new Handle:cvar_brc_BeaconEnable = INVALID_HANDLE;
new Handle:cvar_brc_FilesEnable = INVALID_HANDLE;
new Handle:cvar_brc_NbreConfig = INVALID_HANDLE;
new Handle:cvar_brc_Skin = INVALID_HANDLE;
new Handle:cvar_brc_FilesDebug = INVALID_HANDLE;
new Handle:cvar_brc_Time = INVALID_HANDLE;
new Handle:hb_PrecacheTrie = INVALID_HANDLE;
char brc_ModelsWin[PLATFORM_MAX_PATH];
char brc_ModelsLoose[PLATFORM_MAX_PATH];
char brc_Sound[PLATFORM_MAX_PATH];
char path[PLATFORM_MAX_PATH];
new Numeroskin = 0;
public Plugin:myinfo = 
{
	name = "DoD Custum Bonus Round", 
	author = "<eVa>Dog's, Vintage, Micmacx", 
	description = "Beacon and skin Teams, give speed to the Winners", 
	version = PLUGIN_VERSION, 
	url = "https://dods.135db.fr/doku.php"
}

public OnPluginStart()
{
	CheckGame()
	
	CreateConVar("dod_b_r_custum", PLUGIN_VERSION, "Custum Bonus Round Version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	cvar_brc_kicknodl = CreateConVar("dod_b_r_custum_kicknodl", "1", "Enabled/Disabled Kick players who do not download skins", _, true, 0.0, true, 1.0)
	cvar_brc_SoundEnable = CreateConVar("dod_b_r_custum_sound_enable", "0", "1 : Enable / 0 : Disable Plugin Sound", _, true, 0.0, true, 1.0);
	cvar_brc_SpeedEnable = CreateConVar("dod_b_r_custum_speed_enable", "1", "1 : Enable / 0 : Disable Plugin speed", _, true, 0.0, true, 1.0);
	cvar_brc_BeaconEnable = CreateConVar("dod_b_r_custum_beacon_enable", "1", "1 : Enable / 0 : Disable Plugin beacon", _, true, 0.0, true, 1.0);
	cvar_brc_FilesEnable = CreateConVar("dod_b_r_custum_files", "0", "1 : Enable / 0 : Disable Plugin files skin and sound", _, true, 0.0, true, 1.0);
	cvar_brc_FilesDebug = CreateConVar("dod_b_r_custum_debug", "0", "1 : Enable / 0 : Disable Help Plugin Log for files skin and sound", _, true, 0.0, true, 1.0);
	cvar_brc_NbreConfig = CreateConVar("dod_b_r_custum_nbre_config", "0", "Number of Config File", _, true, 0.0, true, 99.0);
	cvar_brc_Skin = CreateConVar("dod_b_r_custum_skin", "0", "Number Skin", FCVAR_DONTRECORD, true, 0.0, true, 99.0);
	cvar_brc_Time = CreateConVar("dod_b_r_custum_time_enable", "15", "Time Bonus Round", _, true, 0.0, true, 30.0);
	HookEvent("dod_round_start", Hook_RoundStart, EventHookMode_Post)
	HookEvent("dod_round_win", Hook_RoundWin, EventHookMode_Post)
	AutoExecConfig(true, "dod_b_r_custum", "dod_b_r_custum")
	FormatTime(path, sizeof(path), "B_R_Custum%F %H-%M");
	BuildPath(Path_SM, path, sizeof(path), "logs/%s.log", path);
	LogToFileEx(path, "--------------------------------------------------------------------------------------------------------------------");
	LogToFileEx(path, "--------------------------------------------------------------------------------------------------------------------");
	LogToFileEx(path, ".:                                            Bonus Round Custum                                                  :.");
	LogToFileEx(path, "--------------------------------------------------------------------------------------------------------------------");
	LogToFileEx(path, "--------------------------------------------------------------------------------------------------------------------");
	
}

public OnMapStart()
{
	if (GetConVarBool(cvar_brc_FilesEnable))
	{
		if (GetConVarBool(cvar_brc_FilesDebug))LogToFileEx(path, "--------------------------------------------------------------------------------------------------------------------");
		Numeroskin = GetConVarInt(cvar_brc_Skin);
		if ((Numeroskin + 2) > GetConVarInt(cvar_brc_NbreConfig))
		{
			Numeroskin = 0;
		}
		else
		{
			Numeroskin++;
		}
		SetConVarInt(cvar_brc_Skin, Numeroskin);
		if (GetConVarBool(cvar_brc_FilesDebug))LogToFileEx(path, "Config File win%i.ini and loose%i.ini", Numeroskin, Numeroskin);
		
		char buffer[PLATFORM_MAX_PATH];
		new buffernum = Numeroskin + 1;
		Format(buffer, PLATFORM_MAX_PATH, "configs/dod_b_r_custum/win%i.ini", buffernum);
		LoadFiles(brc_ModelsWin, buffer);
		Format(buffer, PLATFORM_MAX_PATH, "configs/dod_b_r_custum/loose%i.ini", buffernum);
		LoadFiles(brc_ModelsLoose, buffer);
	}
	if (GetConVarBool(cvar_brc_BeaconEnable))
	{
		g_beamSprite = PrecacheModel("materials/sprites/laser.vmt")
		g_haloSprite = PrecacheModel("materials/sprites/halo01.vmt")
		PrecacheSound("buttons/button17.wav", true)
	}
	if (hb_PrecacheTrie == INVALID_HANDLE)
	{
		hb_PrecacheTrie = CreateTrie();
	}
	else
	{
		ClearTrie(hb_PrecacheTrie);
	}
	CreateTimer(10.0, ConfigTimer, _, TIMER_FLAG_NO_MAPCHANGE)
}

public OnClientAuthorized(client, const String:auth[])
{
	
	QueryClientConVar(client, "cl_downloadfilter", ConVarQueryFinished:dlfilter);
	
}

public dlfilter(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName1[], const String:cvarValue1[])
{
	if (IsClientConnected(client))
	{
		if (strcmp(cvarValue1, "none", true) == 0)
		{
			if (GetConVarInt(cvar_brc_kicknodl) == 1)
			{
				KickClient(client, "Please enable the option for skins - Allow custom files or nosounds - in Day of defeat:source-->options-->Multiplayer");
			}
		}
		if (strcmp(cvarValue1, "mapsonly", true) == 0)
		{
			if (GetConVarInt(cvar_brc_kicknodl) == 1)
			{
				KickClient(client, "Please enable the option for skins - Allow custom files or nosounds - in Day of defeat:source-->options-->Multiplayer");
			}
		}
		
		if (strcmp(cvarValue1, "all", true) == 0)
		{
			Download_sounds[client] = true;
		}
		else
		{
			Download_sounds[client] = false;
		}
	}
}

public Hook_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	roundwin = false;
}

public Hook_RoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	roundwin = true;
	
	if (GetConVarBool(cvar_brc_SoundEnable) && (!StrEqual(brc_Sound, "nosound", false)))
	{
		if (hb_PrecacheTrie == INVALID_HANDLE)
		{
			hb_PrecacheTrie = CreateTrie();
		}
		else
		{
			ClearTrie(hb_PrecacheTrie);
		}
		new clientlist[MAXPLAYERS + 1];
		new clientcount = 0;
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && !IsFakeClient(i))
			{
				if (Download_sounds[i])
				{
					clientlist[clientcount] = i;
					clientcount++
				}
			}
		}
		if (clientcount > 0)
		{
			if (PrepareSound(brc_Sound))
			{
				EmitSound(clientlist, clientcount, brc_Sound);
			}
		}
	}
	
	new winnerTeam = GetEventInt(event, "team")
	
	for (new x = 1; x <= MaxClients; x++)
	{
		if (!IsClientInGame(x) || !IsPlayerAlive(x))
		{
			continue
		}
		
		if (GetClientTeam(x) == winnerTeam)
		{
			StripWeapons(x)
			if (GetConVarBool(cvar_brc_SpeedEnable))
			{
				SetEntPropFloat(x, Prop_Data, "m_flLaggedMovementValue", 1.5)
				if (GetConVarBool(cvar_brc_FilesDebug))LogToFileEx(path, "Player %i : Speed Activated", x);
			}
			GivePlayerItem(x, WpnMelee[winnerTeam])
			if (GetConVarBool(cvar_brc_FilesEnable))
			{
				if (!StrEqual(brc_ModelsWin, "noskin", false))
				{
					SetEntityModel(x, brc_ModelsWin)
					if (GetConVarBool(cvar_brc_FilesDebug))LogToFileEx(path, "Player %i : Skin  : %s", x, brc_ModelsWin);
				}
				else
				{
					if (GetConVarBool(cvar_brc_FilesDebug))LogToFileEx(path, "Player %i : No Skin", x);
				}
			}
			
			continue
		}
		else
		{
			StripWeapons(x)
			if (GetConVarBool(cvar_brc_FilesEnable))
			{
				if (!StrEqual(brc_ModelsLoose, "noskin", false))
				{
					SetEntityModel(x, brc_ModelsLoose)
					if (GetConVarBool(cvar_brc_FilesDebug))LogToFileEx(path, "Player %i : Skin  : %s", x, brc_ModelsLoose);
				}
				else
				{
					if (GetConVarBool(cvar_brc_FilesDebug))LogToFileEx(path, "Player %i : No Skin", x);
				}
			}
			PrintCenterText(x, "DANGER! Run! Run! Run!")
			GivePlayerItem(x, WpnMelee[winnerTeam])
			if (GetConVarBool(cvar_brc_BeaconEnable))
			{
				CreateTimer(BEACON_DELAY, BeaconTimer, x, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE)
			}
		}
	}
}

public Action:ConfigTimer(Handle:timer)
{
	ServerCommand("dod_bonusround 1");
	ServerCommand("dod_bonusroundtime %i", GetConVarInt(cvar_brc_Time));
}

public Action:BeaconTimer(Handle:timer, any:client)
{
	if (!client || !IsClientInGame(client) || !IsClientConnected(client) || !IsPlayerAlive(client) || !roundwin)
	{
		return Plugin_Stop
	}
	else
	{
		BeamRing(client)
		new Float:vecPos[3]
		GetClientAbsOrigin(client, vecPos)
		EmitSoundToAll("buttons/button17.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, vecPos, NULL_VECTOR, true, 0.0)
	}
	return Plugin_Handled
}


CheckGame()
{
	new String:strGame[10]
	GetGameFolderName(strGame, sizeof(strGame))
	
	if (StrEqual(strGame, "dod"))
	{
		PrintToServer("[dod_bonusround_Custum] Version %s dod_bonusround_Custum loaded.", PLUGIN_VERSION)
	}
	else
	{
		SetFailState("[dod_bonusround_Custum] This plugin is made for DOD:S! Disabled.")
	}
}

BeamRing(client)
{
	new color[] =  { 248, 96, 244, 255 }
	
	new Float:vec[3]
	GetClientAbsOrigin(client, vec)
	
	vec[2] += 5;
	
	TE_Start("BeamRingPoint")
	TE_WriteVector("m_vecCenter", vec)
	TE_WriteFloat("m_flStartRadius", 20.0)
	TE_WriteFloat("m_flEndRadius", 440.0)
	TE_WriteNum("m_nModelIndex", g_beamSprite)
	TE_WriteNum("m_nHaloIndex", g_haloSprite)
	TE_WriteNum("m_nStartFrame", 0)
	TE_WriteNum("m_nFrameRate", 0)
	TE_WriteFloat("m_fLife", 1.0)
	TE_WriteFloat("m_fWidth", 6.0)
	TE_WriteFloat("m_fEndWidth", 6.0)
	TE_WriteFloat("m_fAmplitude", 0.0)
	TE_WriteNum("r", color[0])
	TE_WriteNum("g", color[1])
	TE_WriteNum("b", color[2])
	TE_WriteNum("a", color[3])
	TE_WriteNum("m_nSpeed", 50)
	TE_WriteNum("m_nFlags", 0)
	TE_WriteNum("m_nFadeLength", 0)
	TE_SendToAll()
}

public int LoadFiles(char[] models, char[] ini_file)
{
	char buffer[PLATFORM_MAX_PATH];
	char file[PLATFORM_MAX_PATH];
	
	BuildPath(Path_SM, file, PLATFORM_MAX_PATH, ini_file);
	
	Handle fileh = OpenFile(file, "r");
	if (GetConVarBool(cvar_brc_FilesDebug))LogToFileEx(path, "--------------------------------------------------------------------------------------------------------------------");
	while (ReadFileLine(fileh, buffer, PLATFORM_MAX_PATH))
	{
		TrimString(buffer);
		
		if (buffer[0] != '/')
		{
			if (FileExists(buffer))
			{
				AddFileToDownloadsTable(buffer);
				if (GetConVarBool(cvar_brc_FilesDebug))LogToFileEx(path, "AddFileToDownloadsTable : %s", buffer);
				if (StrEqual(buffer[strlen(buffer) - 4], ".mdl", false))
				{
					Format(models, PLATFORM_MAX_PATH, "%s", buffer);
					if (GetConVarBool(cvar_brc_FilesDebug))LogToFileEx(path, "Modif path model : %s", models);
					PrecacheModel(buffer, true);
					if (GetConVarBool(cvar_brc_FilesDebug))LogToFileEx(path, "Precache Model : %s", buffer);
				}
			}
			else
			{
				if ((StrEqual(buffer[strlen(buffer) - 4], ".mp3", false)) || (StrEqual(buffer[strlen(buffer) - 4], ".wav", false)))
				{
					if (GetConVarBool(cvar_brc_FilesDebug))LogToFileEx(path, "There is at least one sound file : ");
					if (GetConVarBool(cvar_brc_SoundEnable))
					{
						Format(brc_Sound, PLATFORM_MAX_PATH, "sound/%s", buffer);
						if (FileExists(brc_Sound))
						{
							AddFileToDownloadsTable(brc_Sound);
							if (GetConVarBool(cvar_brc_FilesDebug))LogToFileEx(path, "AddFileToDownloadsTable : %s", brc_Sound);
							Format(brc_Sound, PLATFORM_MAX_PATH, "%s", buffer);
							if (GetConVarBool(cvar_brc_FilesDebug))LogToFileEx(path, "Modif path Sound : %s", brc_Sound);
							PrecacheSound(brc_Sound, true)
							if (GetConVarBool(cvar_brc_FilesDebug))LogToFileEx(path, "PrecacheSound : %s", brc_Sound);
						}
						else
						{
							if (GetConVarBool(cvar_brc_FilesDebug))LogToFileEx(path, "Sound File doesn't Exist : %s", brc_Sound);
						}
					}
				}
				if (StrEqual(buffer[strlen(buffer) - 4], "nosk", false))
				{
					Format(models, PLATFORM_MAX_PATH, "noskin");
					if (GetConVarBool(cvar_brc_FilesDebug))LogToFileEx(path, "Modif du model : %s", models);
				}
				if (StrEqual(buffer[strlen(buffer) - 4], "noso", false))
				{
					Format(brc_Sound, PLATFORM_MAX_PATH, "nosound");
					if (GetConVarBool(cvar_brc_FilesDebug))LogToFileEx(path, "Modif path Sound : %s", brc_Sound);
				}
				if ((!StrEqual(buffer[strlen(buffer) - 4], ".mp3", false)) && (!StrEqual(buffer[strlen(buffer) - 4], ".wav", false)) && (!StrEqual(buffer[strlen(buffer) - 4], "nosk", false)) && (!StrEqual(buffer[strlen(buffer) - 4], "noso", false)))
				{
					if (GetConVarBool(cvar_brc_FilesDebug))LogToFileEx(path, "File doesn't exist : %s", buffer);
				}
			}
		}
	}
	if (GetConVarBool(cvar_brc_FilesDebug))LogToFileEx(path, "--------------------------------------------------------------------------------------------------------------------");
}

stock bool:PrepareSound(const String:sound[], bool:preload = true)
{
	if (PrecacheSound(sound, preload))
	{
		SetTrieValue(hb_PrecacheTrie, sound, true);
		return true;
	}
	else
	{
		return false;
	}
}

public Action:StripWeapons(x)
{
	for (new i = 0; i < 4; i++)
	{
		new weapon = GetPlayerWeaponSlot(x, i)
		if (weapon != -1)
		{
			RemovePlayerItem(x, weapon)
			RemoveEdict(weapon)
		}
	}
}

bool IsValidClient(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client)) {
		return true;
	} else {
		return false;
	}
}
