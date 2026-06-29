// #include <tf2_stocks>

#include <sdktools>
#include <morecolors>

#pragma newdecls required // New 2015 rules

int customizingsounds[MAXPLAYERS + 1] = 0;
char plugintag[50] = "{pink}[SoundsEditor] {default}"; //Yeah, I didn't get any better idea for color...

char original_sound[255];
char custom_sound[255];
char mvolume[255];
char looping[255];
char time_of_loop[255];

bool loop = false;

Handle EXECUTING_SOMETHING;
Handle g_Cvar_Debug;
Handle g_Cvar_AutoLoad;
Handle array_sounds;

//Some public var (beta)
int mlevel;
int mchannel;
int mflag;
int mpitch;
float mvolume2;

char publicsample[PLATFORM_MAX_PATH];
//CSGOADD
bool IsCSGO // Boolean value for check: is game csgo or not
//CSGOEND

public Plugin myinfo = {
	name = "Sounds Editor",
		author = "Arkarr",
		description = "Allows to play other sounds.",
		version = "1.0",
		url = "http://www.sourcemod.net/"
};

public void OnPluginStart()
{
	//CSGOADD
	char sBuffer[32]
	GetGameFolderName(sBuffer, 32)
	if(!strcmp(sBuffer, "csgo")) // Check CSGO
		IsCSGO = true
	//CSGOEND
	
	RegAdminCmd("sm_customsounds", Custom_Sound, ADMFLAG_CHEATS);
	RegAdminCmd("sm_cs", Custom_Sound, ADMFLAG_CHEATS);
	RegAdminCmd("sm_cuso", Custom_Sound, ADMFLAG_CHEATS);
	RegAdminCmd("sm_reloadsounds", Reload_sounds, ADMFLAG_CHEATS);

	g_Cvar_Debug = CreateConVar("sm_customsounds_debug", "0", "Display in tchat the currennt sounds");
	g_Cvar_AutoLoad = CreateConVar("sm_customsounds_auto_load", "0", "Activate the custom sounds directly after joining server. WARNING: It will activate even if the player don't have access to 'sm_customsounds' !");

	array_sounds = CreateArray(200);
	AddNormalSoundHook(MySoundHook);
}

public void OnMapStart()
{
	PrecacheSounds(-1);
}

public void OnClientConnected(int client)
{
	if (GetConVarBool(g_Cvar_AutoLoad))
	{
		customizingsounds[client] = 1;
	}
}

public void OnClientDisconnect(int client)
{
	customizingsounds[client] = 0;
}

public Action Custom_Sound(int client, int args)
{
	if (customizingsounds[client] == 1)
	{
		CPrintToChat(client, "%sCustom sound(s) successfull unloaded !", plugintag);
		customizingsounds[client] = 0;
	}
	else
	{
		CPrintToChat(client, "%sCustom sound(s) successfull loaded !", plugintag);
		customizingsounds[client] = 1;
	}
}

public Action Reload_sounds(int client, int args)
{
	if(client != 0)
		PrecacheSounds(true);
}

public Action MySoundHook(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags)
{
	//BETA RELEASE : I know it's a lot of test and I can do some on on line.
	if (entity > 0 && entity <= MaxClients)
	{
		if (IsClientInGame(entity) && IsPlayerAlive(entity) && customizingsounds[entity] == 1)
		{
			if (GetConVarInt(g_Cvar_Debug) == 1)
			{
				CPrintToChat(entity, "%sPlaying now : {green}%s", plugintag, sample);
			}

			publicsample = sample;
			if (ReadSounds() == true)
			{
				sample = custom_sound;
				volume = StringToFloat(mvolume);

				if (StringToInt(looping) == 1)
				{
					if (loop == true)
					{
						if (EXECUTING_SOMETHING != INVALID_HANDLE)
						{
							KillTimer(EXECUTING_SOMETHING);
							EXECUTING_SOMETHING = INVALID_HANDLE;
						}
						loop = false;
					}
					else
					{
						mlevel = level;
						mchannel = channel;
						mflag = flags;
						mpitch = pitch;
						mvolume2 = volume;

						EXECUTING_SOMETHING = CreateTimer(StringToFloat(time_of_loop), callback, _, TIMER_REPEAT);
						loop = true;
					}
				}
				return Plugin_Changed;
			}
			else
				return Plugin_Continue;
		}
		else
			return Plugin_Continue;
	}
	else
		return Plugin_Continue;
}

public void PrecacheSounds(int client)
{
	char downloadpath[255];
	Handle kv = CreateKeyValues("CustomSounds");
	FileToKeyValues(kv, "addons/sourcemod/configs/CustomSounds.cfg");

	if (!KvGotoFirstSubKey(kv))
	{
		return;
	}

	do {
		KvGetString(kv, "custom_sound", custom_sound, sizeof(custom_sound));
		KvGetString(kv, "volume", mvolume, sizeof(mvolume));
		KvGetString(kv, "original_sound", original_sound, sizeof(original_sound));
		KvGetString(kv, "looping", looping, sizeof(looping));
		KvGetString(kv, "time_of_loop", time_of_loop, sizeof(time_of_loop));
		Format(downloadpath, sizeof(downloadpath), "sound/%s", custom_sound);
		AddFileToDownloadsTable(downloadpath);
		
		//CSGOADD
		if(IsCSGO)
		{
			int table = FindStringTable("soundprecache")
			AddToStringTable(table, custom_sound)
		}
		else
			PrecacheSound(custom_sound, true);
		//CSGOEND
		
		//Store data in array
		PushArrayString(array_sounds, original_sound);
		PushArrayString(array_sounds, custom_sound);
		PushArrayString(array_sounds, mvolume);
		PushArrayString(array_sounds, looping);
		PushArrayString(array_sounds, time_of_loop);
	} while (KvGotoNextKey(kv));

	CloseHandle(kv);
	
	if(client != -1)
		CPrintToChat(client, "%sSounds reloaded !", plugintag);
		
}

bool ReadSounds()
{
	int index = 0;
	int row = GetArraySize(array_sounds) / 5 - 1;
	while (row != 0)
	{
		GetArrayString(array_sounds, index, original_sound, sizeof(original_sound));
		if (StrContains(publicsample, original_sound, false) != -1)
		{
			GetArrayString(array_sounds, index + 1, custom_sound, sizeof(custom_sound));
			GetArrayString(array_sounds, index + 2, mvolume, sizeof(mvolume));
			GetArrayString(array_sounds, index + 3, looping, sizeof(looping));
			GetArrayString(array_sounds, index + 4, time_of_loop, sizeof(time_of_loop));
			return true;
		}
		index += 5;
		row--;
	}

	return false;
}

public Action callback(Handle timer, any client)
{
	EmitSoundToAll(custom_sound, client, mchannel, mlevel, mflag, mvolume2, mpitch, _, _, _, true, _);
}