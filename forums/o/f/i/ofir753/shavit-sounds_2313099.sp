
#include <sourcemod>
#include <sdktools>
#include <shavit>

public Plugin:myinfo = 
{
	name = "[shavit] World Records Sounds",
	author = "Ofir",
	description = "Play a random sound when player break world record",
	version = "1.0",
	url = ""
};

Handle gH_Sounds = null;

public void OnPluginStart()
{
	if(gH_Sounds == INVALID_HANDLE)
		gH_Sounds = CreateTrie();
	ClearTrie(gH_Sounds);
	//Build maplist trie
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/timer/sounds.cfg");

	if(FileExists(sPath))
	{
		Handle hFile = OpenFile(sPath, "r");
		char line[512];
		char sKey[16];
		int i = 0;
		while(!IsEndOfFile(hFile))
		{
			ReadFileLine(hFile, line, sizeof(line));
			FormatEx(sKey, 16, "%d", i);
			SplitString(line, "\n", line, sizeof(line));
			SetTrieString(gH_Sounds, sKey, line);
			i++;
			if(!IsSoundPrecached(line))
			{
				PrecacheSound(line);
			}
		}
		CloseHandle(hFile);
	}
}

public void Shavit_OnWorldRecord(int client, BhopStyle style, float time, int jumps)
{
	if(gH_Sounds != null)
	{
		int randomSound = GetRandomInt(0, GetTrieSize(gH_Sounds)-1);
		char sKey[16];
		FormatEx(sKey, 16, "%d", randomSound);

		char sRandomSoundFile[64];
		GetTrieString(gH_Sounds, sKey, sRandomSoundFile, sizeof(sRandomSoundFile));
		EmitSoundToAll(sRandomSoundFile);
	}
}