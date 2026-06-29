#pragma semicolon 1
#pragma newdecls required //強制1.7以後的新語法
#include <sourcemod>
#include <sdktools>
#include <multicolors>

#define PLUGIN_VERSION "1.3"

#define SOUND_sWitchDeath	"npc/witch/voice/attack/female_distantscream1.wav"
#define SOUND_sWitchDeath2	"npc/witch/voice/attack/female_distantscream2.wav"

ConVar hCvar_HellWitch = null;
ConVar hCvar_MobCall = null;
ConVar hCvar_DirHint = null;

bool g_bHW = false;
bool g_bMobCall = false;
bool g_bDirHint = false;

public Plugin myinfo = 
{
	name = "Hell_Witch_Crys",
	author = "Lux, HarryPotter",
	description = "You'll think twice about messing with the witch c:",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/ArmonicJourney"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	EngineVersion test = GetEngineVersion();

	if( test != Engine_Left4Dead2 && test != Engine_Left4Dead )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	
	return APLRes_Success; 
}

public void OnPluginStart()
{	
	CreateConVar("Hell_Witch_Crys", PLUGIN_VERSION, " Version of Hell_Witch_Crys ", FCVAR_SPONLY|FCVAR_DONTRECORD);
	
	hCvar_HellWitch		=	CreateConVar("HW_Enable", "1", "Should We Enable the HellWitchCrys?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvar_MobCall		=	CreateConVar("HW_MobCall", "1", "Should We Enable Mobs?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvar_DirHint		=	CreateConVar("HW_DirectorHint", "1", "Should We Enable Announce?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	AutoExecConfig(true, "Hell_Witch_Crys");
	
	CvarsChanged();
	hCvar_HellWitch.AddChangeHook(eConvarChanged);
	hCvar_DirHint.AddChangeHook(eConvarChanged);

	HookEvent("witch_harasser_set", WitchHarasserSet_Event);
}

public void OnMapStart()
{
	PrecacheSound(SOUND_sWitchDeath, true);
	PrecacheSound(SOUND_sWitchDeath2, true);
	
	//SetConVarBounds(FindConVar("z_max_player_zombies"), ConVarBound_Upper, true, 32.0);
	//SetConVarBounds(FindConVar("z_minion_limit"), ConVarBound_Upper, true, 32.0);
	//SetConVarBounds(FindConVar("survivor_limit"), ConVarBound_Upper, true, 32.0);
	//SetConVarBounds(FindConVar("survival_max_specials"), ConVarBound_Upper, true, 32.0);
}

public void eConvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	CvarsChanged();
}

void CvarsChanged()
{
	g_bHW = hCvar_HellWitch.BoolValue;
	g_bMobCall = hCvar_MobCall.BoolValue;
	g_bDirHint = hCvar_DirHint.BoolValue;
}

public void WitchHarasserSet_Event(Event event, const char[] name, bool dontBroadcast)
{
	if(g_bHW == true && event.GetBool("oneshot") == false)
	{
		int userid = event.GetInt("userid");
		int iWitchWokeUp = GetClientOfUserId(userid);
		int iWitch = event.GetInt("witchid");

		if(iWitchWokeUp > 0 && iWitchWokeUp <= MaxClients && IsClientInGame(iWitchWokeUp) && GetClientTeam(iWitchWokeUp) == 2)
		{
			if(g_bHW) CreateTimer(3.0, PlayWitchScream, EntIndexToEntRef(iWitch), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action PlayWitchScream(Handle hTimer, int ref)
{
	if(g_bMobCall)
	{
		if(ref && EntRefToEntIndex(ref) != INVALID_ENT_REFERENCE)
		{
			int random;
			random = GetRandomInt(1, 2);
			switch(random)
			{
				case 1:
				{
					EmitSoundToAllClients(SOUND_sWitchDeath, SOUND_FROM_PLAYER, SNDCHAN_AUTO, 100, SND_NOFLAGS, 1.0, 100);
				}
				case 2:
				{
					EmitSoundToAllClients(SOUND_sWitchDeath2, SOUND_FROM_PLAYER, SNDCHAN_AUTO, 100, SND_NOFLAGS, 1.0, 100);
				}
			}

			ClientCheatCommand(GetAnyClient(), "z_spawn_old", "mob auto");
			if(g_bDirHint) CPrintToChatAll("[{olive}TS{default}] {olive}倖存者 {default}驚嚇到 {green}Witch {default}引發了{lightgreen}屍潮來臨{default}！");
		}
	}

	return Plugin_Continue;
}

int GetAnyClient() 
{ 
	for (int target = 1; target <= MaxClients; target++) 
	{ 
		if (IsClientInGame(target)) return target; 
	} 
	return -1; 
}

void ClientCheatCommand(int iClient, char[] sArg1, const char[] sArg2="", const char[] sArg3="", const char[] sArg4="")
{
    if(IsFakeClient(iClient)) {
        static int iCommandFlags;
        iCommandFlags = GetCommandFlags(sArg1);
        SetCommandFlags(sArg1, iCommandFlags & ~(1<<14));
 
        FakeClientCommand(iClient, "%s %s %s %s", sArg1, sArg2, sArg3, sArg4);
 
        SetCommandFlags(sArg1, iCommandFlags);
    }
    else {
        static int iUserFlags;
        iUserFlags = GetUserFlagBits(iClient);
        SetUserFlagBits(iClient, (1<<14));
 
        static int iCommandFlags;
        iCommandFlags = GetCommandFlags(sArg1);
        SetCommandFlags(sArg1, iCommandFlags & ~(1<<14));
 
        FakeClientCommand(iClient, "%s %s %s %s", sArg1, sArg2, sArg3, sArg4);
 
        SetCommandFlags(sArg1, iCommandFlags);
        SetUserFlagBits(iClient, iUserFlags);
    }
}

void EmitSoundToAllClients(const char[] sample, int entity = SOUND_FROM_PLAYER, int channel = SNDCHAN_AUTO, int level = SNDLEVEL_NORMAL, int flags = SND_NOFLAGS, float volume = SNDVOL_NORMAL, int pitch = SNDPITCH_NORMAL,int speakerentity = -1, const float origin[3] = NULL_VECTOR, const float dir[3] = NULL_VECTOR, bool updatePos = true, float soundtime = 0.0)
{
	for(int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && !IsFakeClient(i))
			EmitSoundToClient(i, sample, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);
}