#include <sourcemod>
#include <sdkhooks>
#include <emitsoundany>
#include <colors>

/*
	Utilisation :
	1- place your different sound into configs/welcome.txt like this :
	"STEAM_ID"
	{
		"music"	"music/blabla.mp3" (don't write sound/music/blabla.mp3)
		"message"	"{green} Hello Mr{blue}things{default} have a nice day !"	(to know which color use, refere to colors.inc.)
	}
	
	2- Enjoy =)


*/

public Plugin:myinfo =
{
	name = "Welcome",
	author = "Fraise",
	description = "play sound and custom message",
	version = "1.0",
	url = "involved-gaming.com"
};



public OnMapStart()
{
	new Handle:kv = CreateKeyValues("welcome");
	char path[64];
	char location[64];
	char dl_path[64];
	BuildPath(Path_SM, location, sizeof(location), "configs/welcome.txt");
	FileToKeyValues(kv, location);
	KvGotoFirstSubKey(kv);
	do
	{
		KvGetString(kv, "music", path, sizeof(path));
		Format(dl_path, sizeof(dl_path), "sound/%s", path);
		
		AddFileToDownloadsTable(dl_path);
		PrecacheSoundAny(path);	
	}
	while(KvGotoNextKey(kv));
	
}

public void OnClientAuthorized(client, const String:szAuthId[])
{
	char steamidjoueur[64];
	GetClientAuthId(client, AuthId_Steam2,steamidjoueur, sizeof(steamidjoueur));
	
	
	new Handle:kv = CreateKeyValues("welcome");
	char location[55];
	char path[55];
	char message[55];
	char section[55];
		
	BuildPath(Path_SM, location, sizeof(location), "configs/welcome.txt");
	FileToKeyValues(kv, location);
	KvGetSectionName(kv, section, sizeof(section));
	KvGotoFirstSubKey(kv);
	do
	{
		KvGetSectionName(kv, section, sizeof(section));
		if(StrEqual(section, steamidjoueur))
		{
			KvGetString(kv, "music", path, sizeof(path));
			KvGetString(kv, "message", message, sizeof(message));
				
			EmitSoundToAll(path);
			CPrintToChatAll(message);
			break;			
		}
	}
	while (KvGotoNextKey(kv));	
}

