#include <sourcemod>
#include <sdktools>
#include <regex>
//snd_disable_legacy_audio_cache

public Plugin myinfo = 
{
	name = "CSGO Fix old Sound",
	author = "bbs.93x.net",
	description = "Fix csgo after update 4/30/2018 [Sound] S_StartSound(): Failed to load sound File is missing from disk or is invalid.",
	version = "1.0",
	url = "<- URL ->"
}

public void OnPluginStart()
{
	AddNormalSoundHook(NormalSoundHook);
	AddAmbientSoundHook(AmbientSoundHook);
}

public void OnMapStart()
{
	char sSound[PLATFORM_MAX_PATH];
	
	int entity = INVALID_ENT_REFERENCE;
	while ((entity = FindEntityByClassname(entity, "ambient_generic")) != INVALID_ENT_REFERENCE) 
	{
		GetEntPropString(entity, Prop_Data, "m_iszSound", sSound, sizeof(sSound)); 
		
		if(sSound[0] != '*' && sSound[0] != '!' && sSound[0] != '~' && sSound[0] != '#' && StrContains(sSound,".mp3",false) != -1)
		{
			char samplePath[PLATFORM_MAX_PATH];
			Format(samplePath,PLATFORM_MAX_PATH,"*%s",sSound);
			AddToStringTable( FindStringTable( "soundprecache" ), samplePath );
			PrintToServer("FPrecache sound %s", samplePath);
		}
	}
}










public Action AmbientSoundHook(char sample[PLATFORM_MAX_PATH], int &entity, float &volume, int &level, int &pitch, float pos[3], int &flags, float &delay)
{
	if(entity > MaxClients)
	{		 
		if(sample[0] != '*' && sample[0] != '!' && sample[0] != '~' && sample[0] != '#' && StrContains(sample,".mp3",false) != -1)
		{
			char samplePath[PLATFORM_MAX_PATH];
			Format(samplePath,PLATFORM_MAX_PATH,"*%s",sample);
			strcopy(sample,PLATFORM_MAX_PATH,samplePath);
			
			if(FindSoundPrecacheAny(FindStringTable( "soundprecache" ),samplePath) == 0)
			{
				AddToStringTable( FindStringTable( "soundprecache" ), samplePath );
			}
			
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}

public Action NormalSoundHook(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags)
{
	if(entity > MaxClients)
	{
		if(sample[0] != '*' && sample[0] != '!' && sample[0] != '~'  && sample[0] != '#' && StrContains(sample,".mp3",false) != -1)
		{
			char samplePath[PLATFORM_MAX_PATH];
			Format(samplePath,PLATFORM_MAX_PATH,"*%s",sample);
			strcopy(sample,PLATFORM_MAX_PATH,samplePath);
			
			
			if(FindSoundPrecacheAny(FindStringTable( "soundprecache" ),samplePath) == 0)
			{
				AddToStringTable( FindStringTable( "soundprecache" ), samplePath );
			}
			
			return Plugin_Changed;
			
		}
	}
	return Plugin_Continue;
}

stock int FindSoundPrecacheAny(const table, const char[] sSoundName)
{
	char str[PLATFORM_MAX_PATH];
	for(int i=0;i<GetStringTableNumStrings(table);++i)
	{
		ReadStringTable(table, i,str,sizeof(str));
		if(strcmp(str, sSoundName)==0)
			return i;
	}
	return 0;
}

