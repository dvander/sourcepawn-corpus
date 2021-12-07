#include <tf2_stocks>
#include <morecolors>

new customizingsounds[MAXPLAYERS + 1] = 0;
new String: plugintag[50] = "{pink}[SoundsEditor] {default}"; //Yeah, I didn't get any better idea for color...

new String: original_sound[255];
new String: custom_sound[255];
new String: mvolume[255];
new String: looping[255];
new String: time_of_loop[255];

new bool: loop = false;

new Handle: EXECUTING_SOMETHING;
new Handle: g_Cvar_Debug;
new Handle: g_Cvar_AutoLoad;
new Handle: array_sounds;

//Some public var (beta)
new mlevel;
new mchannel;
new mflag;
new mpitch;
new Float: mvolume2;

new String: publicsample[PLATFORM_MAX_PATH];

public Plugin: myinfo = {
	name = "Sounds Editor",
		author = "Arkarr",
		description = "Allows to play other sounds.",
		version = "1.0",
		url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	RegAdminCmd("sm_customsounds", Custom_Sound, ADMFLAG_CHEATS);
	RegAdminCmd("sm_cs", Custom_Sound, ADMFLAG_CHEATS);
	RegAdminCmd("sm_cuso", Custom_Sound, ADMFLAG_CHEATS);
	RegAdminCmd("sm_reloadsounds", Reload_sounds, ADMFLAG_CHEATS);

	g_Cvar_Debug = CreateConVar("sm_customsounds_debug", "0", "Display in tchat the currennt sounds");
	g_Cvar_AutoLoad = CreateConVar("sm_customsounds_auto_load", "0", "Activate the custom sounds directly after joining server. WARNING: It will activate even if the player don't have access to 'sm_customsounds' !");

	array_sounds = CreateArray(200);
	AddNormalSoundHook(MySoundHook);
}

public OnMapStart()
{
	PrecacheSounds(-1);
}

public OnClientConnected(client)
{
	if (GetConVarBool(g_Cvar_AutoLoad))
	{
		customizingsounds[client] = 1;
	}
}

public OnClientDisconnect(client)
{
	customizingsounds[client] = 0;
}

public Action: Custom_Sound(client, args)
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

public Action:Reload_sounds(client, args)
{
	if(client != 0)
		PrecacheSounds(true);
}

public Action: MySoundHook(clients[64], & numClients, String: sample[PLATFORM_MAX_PATH], & entity, & channel, & Float: volume, & level, & pitch, & flags)
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

public PrecacheSounds(client)
{
	decl String: downloadpath[255];
	new Handle: kv = CreateKeyValues("CustomSounds");
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
		PrecacheSound(custom_sound, true);
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

bool: ReadSounds()
{
	new index = 0;
	new row = GetArraySize(array_sounds) / 5 - 1;
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

public Action: callback(Handle: timer, any: client)
{
	EmitSoundToAll(custom_sound, client, mchannel, mlevel, mflag, mvolume2, mpitch, _, _, _, true, _);
}