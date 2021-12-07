#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <regex>

new const String:g_RegexGetFileName[] = ".*[/\\\\](.*?)$";

new Handle:g_hSoundsOverrideTrie = INVALID_HANDLE;
new bool:g_bShouldRun = false;
new Handle:g_hGetFileName = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Sounds Override",
	author = "Dr!fter",
	description = "Allows overriding some game sounds",
	version = "1.0.0",
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	g_hSoundsOverrideTrie = CreateTrie();
	g_hGetFileName = CompileRegex(g_RegexGetFileName);
	
	AddNormalSoundHook(SoundHookHandler);
}

public OnMapStart()
{
	ClearTrie(g_hSoundsOverrideTrie);
	g_bShouldRun = false;
	g_bShouldRun = ParseSoundsKeyValues();
}

public Action:SoundHookHandler(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if(g_bShouldRun)
	{
		new String:filename[PLATFORM_MAX_PATH];
		if(MatchRegex(g_hGetFileName, sample) == 2 && GetRegexSubString(g_hGetFileName, 1, filename, sizeof(filename)))
		{
			new String:replace_string[PLATFORM_MAX_PATH];
			if(GetTrieString(g_hSoundsOverrideTrie, sample, replace_string, sizeof(replace_string)) || GetTrieString(g_hSoundsOverrideTrie, filename, replace_string, sizeof(replace_string)))
			{
				Format(sample, sizeof(sample), "*%s", replace_string);
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

bool:ParseSoundsKeyValues()
{
	new String:path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/sounds_override.cfg");
	
	new Handle:kv = CreateKeyValues("SoundsOverride");
	
	if(!FileToKeyValues(kv, path))
	{
		LogError("Failed to load %s", path);
		CloseHandle(kv);
		return false;
	}
	
	if(!KvGotoFirstSubKey(kv))
	{
		LogError("Failed to jump to first sub key");
		CloseHandle(kv);
		return false;
	}
	
	new String:name[PLATFORM_MAX_PATH];
	new String:replace[PLATFORM_MAX_PATH];
	new String:sound_path[PLATFORM_MAX_PATH];
	
	do
	{
		KvGetSectionName(kv, name, sizeof(name));
		
		KvGetString(kv, "replace", replace, sizeof(replace));
		
		Format(sound_path, sizeof(sound_path), "sound/%s", replace);
		
		if(!FileExists(sound_path, true))
		{
			LogError("Failed to locate sound %s - skipping", sound_path);
			continue;
		}
		
		AddFileToDownloadsTable(sound_path);
		PrecacheSoundEx(replace);
		
		SetTrieString(g_hSoundsOverrideTrie, name, replace);
		
	}while(KvGotoNextKey(kv));
	
	CloseHandle(kv);
	
	return true;
}

PrecacheSoundEx(const String:sound[])
{
	static EngineVersion:iEngine = Engine_Unknown;
	
	if(iEngine == Engine_Unknown)
	{
		iEngine = GetEngineVersion();
	}
	
	if(iEngine == Engine_CSGO || iEngine == Engine_DOTA)
	{
		new String:sound_fake[PLATFORM_MAX_PATH];
		Format(sound_fake, sizeof(sound_fake), "*%s", sound);
	
		AddToStringTable(FindStringTable("soundprecache"), sound_fake);
	}
	
	PrecacheSound(sound);
}