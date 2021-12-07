#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"
#define MAXSOUNDS 4

new SoundAlea

// Plugin definitions
public Plugin:myinfo = 
{
	name = "sm_ar_joinsound",
	author = "Glamorous",
	description = "Insurgency Arabic Radio Join Sound",
	version = PLUGIN_VERSION,
	url = "http://playboycyberclub@yandex.com"
};

new String:js_add_sounds_name[][] = {
	"sound/soundscape/emitters/loop/arabic_radio_01_outdoor.wav",
	"sound/soundscape/emitters/loop/arabic_radio_02.wav",
	"sound/soundscape/emitters/loop/arabic_radio_03.wav",
	"sound/soundscape/emitters/loop/arabic_radio_yaom_tajtho_room_loop.wav"
	}

new String:js_pre_sounds_name[][] = {
	"soundscape/emitters/loop/arabic_radio_01_outdoor.wav",
	"soundscape/emitters/loop/arabic_radio_02.wav",
	"soundscape/emitters/loop/arabic_radio_03.wav",
	"soundscape/emitters/loop/arabic_radio_yaom_tajtho_room_loop.wav"
	}

public OnPluginStart()
{
	CreateConVar("sm_ar_joinsound_version", PLUGIN_VERSION, "Insurgency Arabic Radio Join Sound Version")
}

public OnMapStart()
{
	//sounds add
	for (new i = 0; i < MAXSOUNDS; i++)
	{
		AddFileToDownloadsTable(js_add_sounds_name[i])
	}

	//sounds precache
	for (new j = 0; j < MAXSOUNDS; j++)
	{
		PrecacheSound(js_pre_sounds_name[j], true)
	}
}

public OnClientPutInServer(client)
{
	if ((client == 0) || !IsClientConnected (client))
	{
		return
	}
	
	SoundAlea = GetRandomInt(0, MAXSOUNDS - 1)
	
	EmitSoundToClient(client, js_pre_sounds_name[SoundAlea])
}