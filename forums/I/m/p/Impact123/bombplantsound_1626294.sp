#include <sourcemod>
#include <sdktools>
#pragma semicolon 1



new Handle:g_Adt;
new bool:g_SoundCanPlay = true;
new String:g_ActiveSound[PLATFORM_MAX_PATH];



#define SOUNDFOLDER "sound/plantsounds"
#define PRECACHE "plantsounds"
#define EMIT PRECACHE



public Plugin:myinfo = 
{
	name = "Bomb plant sounds",
	author = "Impact",
	description = "Plays a random sound by bomb planting",
	version = "0.1",
	url = "http://forums.alliedmods.net/showthread.php?t=175553"
}



public OnPluginStart()
{
	
	g_Adt = CreateArray(PLATFORM_MAX_PATH);
	
	// Fill our array with sounds
	GetAllSounds(g_Adt);
	
	HookEvent("bomb_planted", OnBombPlanted);
	HookEvent("bomb_exploded", OnBombExploded);
	HookEvent("bomb_defused", OnBombDefused);
}


public OnMapStart()
{
	GetAllSounds(g_Adt);
	PrecacheSounds(g_Adt);
}




// --------------------------------------- ONBOMBPLANTED ---------------------------------------
public Action:OnBombPlanted(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_SoundCanPlay)
	{
		new Random = GetRandomInt(0, GetArraySize(g_Adt)-1);
		new String:Buffer[PLATFORM_MAX_PATH];
		
		GetArrayString(g_Adt, Random, Buffer, sizeof(Buffer));
		Format(Buffer, sizeof(Buffer), "%s/%s", EMIT, Buffer);
		EmitSoundToAll(Buffer);
		Format(g_ActiveSound, sizeof(g_ActiveSound), "%s", Buffer);
		
		g_SoundCanPlay = false;
	}
}




// --------------------------------------- ONBOMBDETONATED ---------------------------------------
public Action:OnBombExploded(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_SoundCanPlay)
	{
		StopSounds();
		g_SoundCanPlay = true;
	}
}
// --------------------------------------- ONBOMBDETONATED ---------------------------------------




// --------------------------------------- ONBOMBDETONATED ---------------------------------------
public Action:OnBombDefused(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_SoundCanPlay)
	{
		StopSounds();
		g_SoundCanPlay = true;
	}
}
// --------------------------------------- ONBOMBDETONATED ---------------------------------------




// --------------------------------------- STOPSOUNDS ---------------------------------------
StopSounds()
{
	for(new i; i <= MaxClients; i++)
	{
		if(IsClientValid(i))
		{
			StopSound(i, SNDCHAN_AUTO, g_ActiveSound);
		}
	}
}
// --------------------------------------- STOPSOUNDS ---------------------------------------




// --------------------------------------- GETALLSOUNDS ---------------------------------------
GetAllSounds(&Handle:Array)
{
	ClearArray(Array);
	
	new String:Files[PLATFORM_MAX_PATH];
	new Handle:Dir = OpenDirectory(SOUNDFOLDER);
	
	new FileType:type;
	new FileType:file = FileType_File;
	while(ReadDirEntry(Dir, Files, sizeof(Files), type))
	{
		if(type == file)
		{
			if(StrContains(Files, ".mp3") || StrContains(Files, ".wav"))
			{
				PushArrayString(g_Adt, Files);
			}
		}
	}
	
	CloseHandle(Dir);
}


// --------------------------------------- GETALLSOUNDS ---------------------------------------




// --------------------------------------- PRECACHESOUNDS ---------------------------------------
PrecacheSounds(&Handle:Array)
{
	new arrsize = GetArraySize(Array);
	new String:Buffer[PLATFORM_MAX_PATH];
	for(new i; i < arrsize; i++)
	{
		GetArrayString(g_Adt, i, Buffer, sizeof(Buffer));	
		Format(Buffer, sizeof(Buffer), "%s/%s", PRECACHE, Buffer);
		PrecacheSound(Buffer, true);
	}
}
// --------------------------------------- PRECACHESOUNDS ---------------------------------------






// Ported stocks

stock bool:IsClientValid(id)
{
	if(id >0 && IsClientConnected(id) && IsClientInGame(id))
	{
		return true;
	}
	else
	{
		return false;
	}
}