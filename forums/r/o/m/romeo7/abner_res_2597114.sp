#include <sourcemod>
#include <sdktools>
#include <colors>
#include <clientprefs>
#include <cstrike>
#include <emitsoundany>

#pragma newdecls required
#pragma semicolon 1
#define PLUGIN_VERSION "3.6"

//MapSounds Stuff
int g_iSoundEnts[2048];
int g_iNumSounds;

//Cvars
ConVar g_hCTPath;
ConVar g_hTRPath;
ConVar g_hDrawPath;
ConVar g_hPlayType;
ConVar g_hStop;
ConVar g_PlayPrint;
ConVar g_ClientSettings; 
ConVar g_SoundVolume;

bool SamePath = false;
bool CSGO;
Handle g_ResPlayCookie;
Handle g_ResVolumeCookie;

//Sounds Arrays
ArrayList ctSoundsArray;
ArrayList trSoundsArray;
ArrayList drawSoundsArray;
StringMap soundNames;

public Plugin myinfo =
{
	name 			= "[CS:GO/CSS] AbNeR Round End Sounds",
	author 			= "AbNeR_CSS",
	description 	= "Play cool musics when round ends!",
	version 		= PLUGIN_VERSION,
	url 			= "http://www.tecnohardclan.com/forum/"
}

public void OnPluginStart()
{  
	//Cvars
	CreateConVar("abner_res_version", PLUGIN_VERSION, "Plugin version", FCVAR_NOTIFY|FCVAR_REPLICATED);
	
	g_hTRPath                  = CreateConVar("res_tr_path", "misc/tecnohard", "Path of sounds played when Terrorists Win the round");
	g_hCTPath                  = CreateConVar("res_ct_path", "misc/tecnohard", "Path of sounds played when Counter-Terrorists Win the round");
	g_hDrawPath				   = CreateConVar("res_draw_path", "1", "Path of sounds played when Round Draw or 0 - Don´t play sounds, 1 - Play TR sounds, 2 - Play CT sounds");
		
	g_hPlayType                = CreateConVar("res_play_type", "1", "1 - Random, 2 - Play in queue");
	g_hStop                    = CreateConVar("res_stop_map_music", "1", "Stop map musics");	
	
	g_PlayPrint                = CreateConVar("res_print_to_chat_mp3_name", "1", "Print mp3 name in chat (Suggested by m22b)");
	g_ClientSettings	       = CreateConVar("res_client_preferences", "1", "Enable/Disable client preferences");

	g_SoundVolume 			   = CreateConVar("res_default_volume", "1.00", "Default sound volume.");
	
	//ClientPrefs
	g_ResPlayCookie = RegClientCookie("AbNeR Round End Sounds", "", CookieAccess_Private);
	g_ResVolumeCookie = RegClientCookie("abner_res_volume", "Round end sound volume", CookieAccess_Private);

	SetCookieMenuItem(SoundCookieHandler, 0, "AbNeR Round End Sounds");
	
	LoadTranslations("common.phrases");
	LoadTranslations("abner_res.phrases");
	AutoExecConfig(true, "abner_res");

	/* CMDS */
	RegAdminCmd("res_refresh", CommandLoad, ADMFLAG_SLAY);
	RegConsoleCmd("res", abnermenu);
		
	
	CSGO = GetEngineVersion() == Engine_CSGO;
	
	/* EVENTS */
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd);
	
	ctSoundsArray = new ArrayList(512);
	trSoundsArray = new ArrayList(512);
	drawSoundsArray = new ArrayList(512);
	soundNames = new StringMap();
}

stock bool IsValidClient(int client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}

public void StopMapMusic()
{
	char sSound[PLATFORM_MAX_PATH];
	int entity = INVALID_ENT_REFERENCE;
	for(int i=1;i<=MaxClients;i++){
		if(!IsClientInGame(i)){ continue; }
		for (int u=0; u<g_iNumSounds; u++){
			entity = EntRefToEntIndex(g_iSoundEnts[u]);
			if (entity != INVALID_ENT_REFERENCE){
				GetEntPropString(entity, Prop_Data, "m_iszSound", sSound, sizeof(sSound));
				Client_StopSound(i, entity, SNDCHAN_STATIC, sSound);
			}
		}
	}
}

void Client_StopSound(int client, int entity, int channel, const char[] name)
{
	EmitSoundToClient(client, name, entity, channel, SNDLEVEL_NONE, SND_STOP, 0.0, SNDPITCH_NORMAL, _, _, _, true);
}

public void Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	int winner = GetEventInt(event, "winner");
	
	bool Sucess = false;
	if((winner == CS_TEAM_CT && SamePath) || winner == CS_TEAM_T) Sucess = PlaySound(trSoundsArray, g_hTRPath);
	else if(winner == CS_TEAM_CT) Sucess = PlaySound(ctSoundsArray, g_hCTPath);
	else Sucess = PlaySound(drawSoundsArray, g_hDrawPath);
			
	if(GetConVarInt(g_hStop) == 1 && Sucess)
		StopMapMusic();
}

public void Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	if(GetConVarInt(g_hStop) == 1)
	{
		// Ents are recreated every round.
		g_iNumSounds = 0;
		
		// Find all ambient sounds played by the map.
		char sSound[PLATFORM_MAX_PATH];
		int entity = INVALID_ENT_REFERENCE;
		
		while ((entity = FindEntityByClassname(entity, "ambient_generic")) != INVALID_ENT_REFERENCE)
		{
			GetEntPropString(entity, Prop_Data, "m_iszSound", sSound, sizeof(sSound));
			
			int len = strlen(sSound);
			if (len > 4 && (StrEqual(sSound[len-3], "mp3") || StrEqual(sSound[len-3], "wav")))
			{
				g_iSoundEnts[g_iNumSounds++] = EntIndexToEntRef(entity);
			}
		}
	}
}

public void SoundCookieHandler(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	abnermenu(client, 0);
}

public void OnClientPutInServer(int client)
{
	if(GetConVarInt(g_ClientSettings) == 1)
	{
		CreateTimer(3.0, msg, client);
	}
}

public Action msg(Handle timer, any client)
{
	if(IsValidClient(client))
	{
		CPrintToChat(client, "{default}{green}[AbNeR RES] {default}%t", "JoinMsg");
	}
}

public Action abnermenu(int client, int args)
{
	if(GetConVarInt(g_ClientSettings) != 1)
	{
		return Plugin_Handled;
	}
	
	int cookievalue = GetIntCookie(client, g_ResPlayCookie);
	Handle g_CookieMenu = CreateMenu(AbNeRMenuHandler);
	SetMenuTitle(g_CookieMenu, "Round End Sounds by AbNeR_CSS");
	char Item[128];
	if(cookievalue == 0)
	{
		Format(Item, sizeof(Item), "%t %t", "RES_ON", "Selected"); 
		AddMenuItem(g_CookieMenu, "ON", Item);
		Format(Item, sizeof(Item), "%t", "RES_OFF"); 
		AddMenuItem(g_CookieMenu, "OFF", Item);
	}
	else
	{
		Format(Item, sizeof(Item), "%t", "RES_ON");
		AddMenuItem(g_CookieMenu, "ON", Item);
		Format(Item, sizeof(Item), "%t %t", "RES_OFF", "Selected"); 
		AddMenuItem(g_CookieMenu, "OFF", Item);
	}

	Format(Item, sizeof(Item), "%t", "VOLUME");
	AddMenuItem(g_CookieMenu, "volume", Item);


	SetMenuExitBackButton(g_CookieMenu, true);
	SetMenuExitButton(g_CookieMenu, true);
	DisplayMenu(g_CookieMenu, client, 30);
	return Plugin_Continue;
}

public int AbNeRMenuHandler(Handle menu, MenuAction action, int client, int param2)
{
	Handle g_CookieMenu = CreateMenu(AbNeRMenuHandler);
	if (action == MenuAction_DrawItem)
	{
		return ITEMDRAW_DEFAULT;
	}
	else if(param2 == MenuCancel_ExitBack)
	{
		ShowCookieMenu(client);
	}
	else if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 0:
			{
				SetClientCookie(client, g_ResPlayCookie, "0");
				abnermenu(client, 0);
			}
			case 1:
			{
				SetClientCookie(client, g_ResPlayCookie, "1");
				abnermenu(client, 0);
			}
			case 2: 
			{
				VolumeMenu(client);
			}
		}
		CloseHandle(g_CookieMenu);
	}
	return 0;
}

void VolumeMenu(int client){
	

	float volumeArray[] = { 1.0, 0.75, 0.50, 0.25, 0.10 };
	float selectedVolume = GetClientVolume(client);

	Menu volumeMenu = new Menu(VolumeMenuHandler);
	volumeMenu.SetTitle("%t", "Sound Menu Title");

	for(int i = 0; i < sizeof(volumeArray); i++)
	{
		char strInfo[10];
		Format(strInfo, sizeof(strInfo), "%0.2f", volumeArray[i]);

		char display[20], selected[5];
		if(volumeArray[i] == selectedVolume)
			Format(selected, sizeof(selected), "%t", "Selected");

		Format(display, sizeof(display), "%s %s", strInfo, selected);

		volumeMenu.AddItem(strInfo, display);
	}

	volumeMenu.Display(client, MENU_TIME_FOREVER);
}

public int VolumeMenuHandler(Menu menu, MenuAction action, int client, int param2)
{
	if(action == MenuAction_Select){
		char sInfo[10];
		GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
		SetClientCookie(client, g_ResVolumeCookie, sInfo);
		VolumeMenu(client);
	}
	else if(param2 == MenuCancel_ExitBack)
	{
		abnermenu(client, 0);
	}
}


public void OnMapStart()
{
	RefreshSounds(0);
}

void RefreshSounds(int client)
{
	char trSoundPath[PLATFORM_MAX_PATH];
	char ctSoundPath[PLATFORM_MAX_PATH];
	char drawSoundPath[PLATFORM_MAX_PATH];
	
	GetConVarString(g_hTRPath, trSoundPath, sizeof(trSoundPath));
	GetConVarString(g_hCTPath, ctSoundPath, sizeof(ctSoundPath));
	GetConVarString(g_hDrawPath, drawSoundPath, sizeof(drawSoundPath));
		
	SamePath = StrEqual(trSoundPath, ctSoundPath);

	if(SamePath)
	{
		ReplyToCommand(client, "[ZP] SOUNDS: %d sounds loaded from \"sound/%s\"", LoadSounds(trSoundsArray, g_hTRPath), trSoundPath);
	}
	else
	{
		ReplyToCommand(client, "[ZP] CT SOUNDS: %d sounds loaded from \"sound/%s\"", LoadSounds(ctSoundsArray, g_hCTPath), ctSoundPath);
		ReplyToCommand(client, "[ZP] TR SOUNDS: %d sounds loaded from \"sound/%s\"", LoadSounds(trSoundsArray, g_hTRPath), trSoundPath);
	}
	
	int RoundDrawOption = GetConVarInt(g_hDrawPath);
	if(RoundDrawOption != 0)
		switch(RoundDrawOption)
		{
			case 1:
			{
				drawSoundsArray = trSoundsArray;
				g_hDrawPath = g_hTRPath;
				ReplyToCommand(client, "[ZP] DRAW SOUNDS: %d sounds loaded from \"sound/%s\"", trSoundsArray.Length, trSoundPath);
			}
			case 2:
			{
				drawSoundsArray = ctSoundsArray;
				g_hDrawPath = g_hCTPath;
				ReplyToCommand(client, "[ZP] DRAW SOUNDS: %d sounds loaded from \"sound/%s\"", ctSoundsArray.Length, ctSoundPath);
			}
			default:
			{
				char drawSoundsPath[PLATFORM_MAX_PATH];
				GetConVarString(g_hDrawPath, drawSoundsPath, sizeof(drawSoundsPath));
				
				if(!StrEqual(drawSoundsPath, ""))
					ReplyToCommand(client, "[ZP] DRAW SOUNDS: %d sounds loaded from \"sound/%s\"", LoadSounds(drawSoundsArray, g_hDrawPath), drawSoundsPath);
			}
		}
	
	ParseSongNameKvFile();
}


public void ParseSongNameKvFile()
{
	soundNames.Clear();

	char sPath[PLATFORM_MAX_PATH];
	Format(sPath, sizeof(sPath), "configs/abner_res.txt");
	BuildPath(Path_SM, sPath, sizeof(sPath), sPath);

	if (!FileExists(sPath))
		return;

	KeyValues hKeyValues = CreateKeyValues("Abner Res");
	if (!hKeyValues.ImportFromFile(sPath))
		return;

	if(hKeyValues.GotoFirstSubKey())
	{
		do
		{
			char sSectionName[255];
			char sSongName[255];

			hKeyValues.GetSectionName(sSectionName, sizeof(sSectionName));
			hKeyValues.GetString("songname", sSongName, sizeof(sSongName));
			soundNames.SetString(sSectionName, sSongName);
		}
		while(hKeyValues.GotoNextKey(false));
	}
	hKeyValues.Close();
}
 
int LoadSounds(ArrayList arraySounds, ConVar pathConVar)
{
	arraySounds.Clear();
	
	char soundPath[PLATFORM_MAX_PATH];
	char soundPathFull[PLATFORM_MAX_PATH];
	GetConVarString(pathConVar, soundPath, sizeof(soundPath));
	
	Format(soundPathFull, sizeof(soundPathFull), "sound/%s/", soundPath);
	DirectoryListing pluginsDir = OpenDirectory(soundPathFull);
	
	if(pluginsDir != null)
	{
		char fileName[128];
		while(pluginsDir.GetNext(fileName, sizeof(fileName)))
		{
			int extPosition = strlen(fileName) - 4;
			if(StrContains(fileName,".mp3",false) == extPosition) //.mp3 Files Only
			{
				char soundName[512];
				Format(soundName, sizeof(soundName), "sound/%s/%s", soundPath, fileName);
				AddFileToDownloadsTable(soundName);
				
				Format(soundName, sizeof(soundName), "%s/%s", soundPath, fileName);
				PrecacheSoundAny(soundName);
				arraySounds.PushString(soundName);
			}
		}
	}
	return arraySounds.Length;
}
 
bool PlaySound(ArrayList arraySounds, ConVar pathConVar)
{
	if(arraySounds.Length <= 0)
		return false;
		
	int soundToPlay = 0;
	if(GetConVarInt(g_hPlayType) == 1)
	{
		soundToPlay = GetRandomInt(0, arraySounds.Length-1);
	}
	
	char szSound[128];
	arraySounds.GetString(soundToPlay, szSound, sizeof(szSound));
	arraySounds.Erase(soundToPlay);
	PlayMusicAll(szSound);
	if(arraySounds.Length == 0)
		LoadSounds(arraySounds, pathConVar);
		
	return true;
}

void PlayMusicAll(char[] szSound)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && (GetConVarInt(g_ClientSettings) == 0 || GetIntCookie(i, g_ResPlayCookie) == 0))
		{
			if(CSGO)
			{ 
				ClientCommand(i, "playgamesound Music.StopAllMusic");
			}
			
			float selectedVolume = GetClientVolume(i);
			EmitSoundToClientAny(i, szSound, _, _, _, _, selectedVolume);
		}
	}
	
	if(GetConVarInt(g_PlayPrint) == 1)
	{
		char soundKey[100];
		char soundPrint[512];
		char buffer[20][255];
		
		int numberRetrieved = ExplodeString(szSound, "/", buffer, sizeof(buffer), sizeof(buffer[]), false);
		if (numberRetrieved > 0)
			Format(soundKey, sizeof(soundKey), buffer[numberRetrieved - 1]);
		
		soundNames.GetString(soundKey, soundPrint, sizeof(soundPrint));
						
		CPrintToChatAll("{green}[ZP] {default}%t", "mp3 print", !StrEqual(soundPrint, "") ? soundPrint : szSound);
	}
}

public Action CommandLoad(int client, int args)
{   
	RefreshSounds(client);
	return Plugin_Handled;
}

float GetClientVolume(int client){
	float defaultVolume = GetConVarFloat(g_SoundVolume);

	char sCookieValue[11];
	GetClientCookie(client, g_ResVolumeCookie, sCookieValue, sizeof(sCookieValue));

	if(!GetConVarBool(g_ClientSettings) || StrEqual(sCookieValue, "") || StrEqual(sCookieValue, "0"))
		Format(sCookieValue , sizeof(sCookieValue), "%0.2f", defaultVolume);

	return StringToFloat(sCookieValue);
}

int GetIntCookie(int client, Handle handle)
{
	char sCookieValue[11];
	GetClientCookie(client, handle, sCookieValue, sizeof(sCookieValue));
	return StringToInt(sCookieValue);
}
