#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS                   FCVAR_NOTIFY

static const char g_sModels[7][PLATFORM_MAX_PATH] =
{
	"models/props_interiors/book_gib01.mdl",
	"models/props_unique/doll01.mdl",
	"models/props_interiors/tv.mdl",
	"models/props_fairgrounds/elephant.mdl",
	"models/props_fairgrounds/giraffe.mdl",
	"models/props_fairgrounds/snake.mdl",
	"models/props_fairgrounds/alligator.mdl",
};

bool IsLeft4Dead2;

public Plugin myinfo =
{
	name = "[L4D & L4D2] Random Pipe Bomb",
	description = "....",
	author = "Joshe Gatito",
	version = "1.0",
	url = "https://github.com/JosheGatitoSpartankii09"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test == Engine_Left4Dead2) {
		IsLeft4Dead2 = true;		
	}
	else if (test != Engine_Left4Dead) {
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnMapStart()
{
	int max = 7 - 4;
	if( IsLeft4Dead2 ) max = 7;

	for( int i = 0; i < max; i++ )
		PrecacheModel(g_sModels[i], true);
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (StrEqual(classname, "weapon_pipe_bomb_spawn", false) || StrEqual(classname, "pipe_bomb_projectile", false))
        RequestFrame(OnPipeNextFrame, EntIndexToEntRef(entity));
}

void OnPipeNextFrame(int iEntRef)
{
	int iRandom;
	if(IsLeft4Dead2) iRandom = GetRandomInt(0, sizeof g_sModels - 1);
	else iRandom = GetRandomInt(0, sizeof g_sModels - 5);

	if (!IsValidEntRef(iEntRef))
        return;
		
	int entity = EntRefToEntIndex(iEntRef);
	SetEntityModel(entity, g_sModels[iRandom]);
}

bool IsValidEntRef(int iEntRef)
{
    return iEntRef != 0 && EntRefToEntIndex(iEntRef) != INVALID_ENT_REFERENCE;
}
