

KeyValues kv;

#include <sdktools>
#include <sdkhooks>


ArrayList sounds;


public void OnPluginStart()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i)) OnClientPutInServer(i);
	}

	HookEventEx("player_hurt", player_hurt);
}

public void player_hurt(Event event, const char[] name, bool dontBroadcast)
{
/*
 player_hurt
  userid       short   3
  attacker     short   0
  health       byte    63
  priority     short   5
  damagetype   long    32
*/

	if(event.GetInt("attacker") != 0)
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));

	if(client)
	{
		OnTakeDamagePost(client, 0, 0, 0.0, event.GetInt("damagetype"));
	}

}


public void OnConfigsExecuted()
{
	if(sounds != null)
	{
		delete sounds;
	}

	sounds = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));

	if(kv != null)
		delete kv;

	kv = new KeyValues("sample");

	char soundfile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, soundfile, sizeof(soundfile), "configs/falldamagesound.txt");

	if(!kv.ImportFromFile(soundfile))
	{
		SetFailState("Missing KeyValue file: \"configs/falldamagesound.txt\"");
	}
	
	kv.Rewind();

	if(!kv.GotoFirstSubKey(false))
	{
		SetFailState("could'nt enter in first subkey")
	}

	char buffer[PLATFORM_MAX_PATH];

	do
	{
		kv.GetString(NULL_STRING, buffer, sizeof(buffer));
		//PrintToServer("%s %i", buffer, sounds.Length);

		if(strlen(buffer) < 5)
			continue;

		sounds.PushString(buffer);

		PrecacheSound(buffer);

		Format(buffer, sizeof(buffer), "sound/%s", buffer);
		AddFileToDownloadsTable(buffer);
	}
	while(kv.GotoNextKey(false))
}

public void OnClientPutInServer(int client)
{
	//SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
}

public void OnTakeDamagePost(int victim, int attacker, int inflictor, float damage, int damagetype)
{
	if(damagetype == DMG_FALL)
	{
		int random = GetRandomInt(1, sounds.Length-1);

		if(sounds.Length <= 1)
		{
			random = 0;
		}

		char buffer[PLATFORM_MAX_PATH];
		sounds.GetString(random, buffer, sizeof(buffer));
		//PrintToServer("array random %i %s", random, buffer);
		EmitSoundToAll(buffer, victim);
	}
}

