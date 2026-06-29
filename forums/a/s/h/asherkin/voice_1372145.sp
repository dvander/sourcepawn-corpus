#include <sourcemod>

forward OnClientSpeaking(client);

public Extension:__ext_voice = 
{
	name = "voice",
	file = "voiceannounce.ext",
	autoload = 1,
	required = 1,
}

public OnClientSpeaking(client) {
	PrintToServer("[SM] %N is talking.", client);
}