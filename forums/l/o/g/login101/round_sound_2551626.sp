
#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define PLUGIN_VERSION "0.1"
#define SOUND_NONE "music/?"

new String:Start_Sound[256];
new String:End_Sound[256];



new Handle:RS = INVALID_HANDLE;
new Handle:RE = INVALID_HANDLE;


public OnPluginStart()
{	
	CreateConVar("sm_RoundSound_version", PLUGIN_VERSION, "Round Start&End Sound Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	HookEvent("round_freeze_end", roundfreezeend_event);
	HookEvent("round_end", roundend_event);
	
	RS = CreateConVar("rs_start", SOUND_NONE, "music/?");
	RE = CreateConVar("rs_end", SOUND_NONE, "music/?");

	
	AutoExecConfig();
}

public OnMapStart()
{
PrecacheSound("music/?");
	AutoExecConfig();
	
	GetConVarString(RS, Start_Sound, sizeof(Start_Sound));
	GetConVarString(RE, End_Sound, sizeof(End_Sound));

	
	if(!(StrEqual(Start_Sound, SOUND_NONE, true)))
	{
		PrecacheSound(Start_Sound, true);
		PrintToServer("[SM] %s Sound Precaching Complete", Start_Sound);
	}
	else
	{
		PrintToServer("[SM] None Round Start Sound");
	}
	
	if(!(StrEqual(End_Sound, SOUND_NONE, true)))
	{
		PrecacheSound(End_Sound, true);
		PrintToServer("[SM] %s Sound Precaching Complete", End_Sound);
	}
	else
	{
		PrintToServer("[SM] None Round End Sound");
	}
	

}

public Action:roundfreezeend_event(Handle:Event, const String:Name[], bool:Broadcast)
{
	if(!(StrEqual(Start_Sound, SOUND_NONE, true)))
		EmitSoundToAll(Start_Sound, SOUND_FROM_PLAYER, _, _, _, 18.0);
}

public Action:roundend_event(Handle:Event, const String:Name[], bool:Broadcast)
{
	if(!(StrEqual(End_Sound, SOUND_NONE, true)))
		EmitSoundToAll(End_Sound, SOUND_FROM_PLAYER, _, _, _, 18.0);	
}