#include <sourcemod>
#include <sdktools>

public Plugin myinfo = {
	name="Block ambient/fire/fire_med_loop1.wav",
	author="flawlesskush",
	description="o fuck yea bud",
	url="?",
	version="0.1"
};

public OnPluginStart()
{
	AddNormalSoundHook(BlockSound);
}

public OnMapStart()
{
	AddNormalSoundHook(BlockSound);
}


public Action BlockSound(clients[64], &numClients, char sample[PLATFORM_MAX_PATH], &entity, &channel, float &volume, &level, &pitch, &flags)
{
	if(StrEqual(sample,"ambient/fire/fire_med_loop1.wav")){
		return(Plugin_Handled);
	}
	return(Plugin_Continue);

}