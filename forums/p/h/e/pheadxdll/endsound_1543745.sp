#include <sourcemod>
#include <sdktools>

#define SOUND		"endgame.mp3"
#define SOUND_FILE	"sound/endgame.mp3"

public OnPluginStart()
{
	HookEvent("teamplay_game_over", Event_Sound);
}

public OnMapStart()
{
	AddFileToDownloadsTable(SOUND_FILE);
	PrecacheSound(SOUND);
}

public Event_Sound(Handle:hEvent, const String:strName[], bool:bDontBroadcast)
{
	EmitSoundToAll(SOUND);
}
