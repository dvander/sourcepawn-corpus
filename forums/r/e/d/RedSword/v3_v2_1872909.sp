#include <sdktools>

public OnConfigsExecuted()
{
	AddFileToDownloadsTable("sound/music/redrage.mp3");
	//PrecacheSound("*music/redrage.mp3");
}

public OnClientPutInServer(client)
{
	//EmitSoundToClient(client, "*music/redrage.mp3");
	ClientCommand(client, "*music/redrage.mp3");
}