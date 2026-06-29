#define PLUGIN_VERSION "1.1"

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS FCVAR_NOTIFY

static const char g_SoundWeapon[][] =
{
	"weapons/fx/rics/ric1.wav",
	"weapons/fx/rics/ric2.wav",
	"weapons/fx/rics/ric3.wav",
	"weapons/fx/rics/ric4.wav",
	"weapons/fx/rics/ric5.wav",
	"weapons/fx/rics/ric6.wav",
	"weapons/fx/rics/ric7.wav",
	"weapons/fx/rics/ric8.wav",
	"weapons/fx/rics/ric9.wav"
};

ConVar l4d_custom_sound_fire;

public Plugin myinfo = 
{
	name = "[L4D] Silencer Weapon.",
	author = "Joshe Gatito",
	description = "",
	version = "1.0",
	url = "http://steamcommunity.com/id/AyaSupay/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test != Engine_Left4Dead)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
    CreateConVar("l4d_silencer_weapon", PLUGIN_VERSION, "[L4D] Silencer Weapon Version.", CVAR_FLAGS);

    l4d_custom_sound_fire = CreateConVar("l4d_custom_sound_fire", "0", "custom sounds", FCVAR_NONE);

    RegConsoleCmd("sm_silenceron", eSilencerOn, "");
    RegConsoleCmd("sm_silenceroff", eSilencerOff, "");

    AddNormalSoundHook(SoundHook);
	
    HookEvent("weapon_fire", eFire, EventHookMode_Pre);
}

public void OnMapStart()
{
	for(int i; i < sizeof g_SoundWeapon; i++)
	    PrecacheSound(g_SoundWeapon[i], true);
}

public Action SoundHook(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags)
{
    if (StrContains(sample, "weapons/smg/gunfire/smg_fire_1.wav") != -1)
    {
        numClients = 0;
    
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && !IsFakeClient(i))
            {
                if (i == entity)
                {
                    EmitSoundToClient(i, sample, _, _, _, _, (volume * 0.2));
                    continue;
                }
            
                clients[numClients] = i;
                numClients++;
            }
        }
        
        return Plugin_Changed;
    }
    
    return Plugin_Continue;
}

Action eSilencerOn(int client, int args)
{
    for(int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2)
        SetEntProp(i, Prop_Send, "m_upgradeBitVec", 262144);
    }
}
	
Action eSilencerOff(int client, int args)
{
    for(int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2)
        SetEntProp(i, Prop_Send, "m_upgradeBitVec", 0);
    }
}

Action eFire(Event event, const char[] name, bool dontbroadcast)
{
    char sWeapon[64];
    event.GetString("weapon", sWeapon, sizeof(sWeapon));
 
    int client = GetClientOfUserId(event.GetInt("userid")); 
    if (!IsValidClient(client) && !IsPlayerAlive(client) && GetClientTeam(client) != 2)	
        return Plugin_Handled;

    if(l4d_custom_sound_fire.IntValue)
    {
		switch(sWeapon[0])
		{
		    case 's':
		    {
			    if (StrEqual(sWeapon, "smg"))
					EmitSoundToAll(g_SoundWeapon[GetRandomInt(0, sizeof(g_SoundWeapon) - 1)], client, SNDCHAN_WEAPON, SNDLEVEL_GUNFIRE);
		    }
		    case 'p':
		    {
			    if (StrEqual(sWeapon, "pistol")) 
					EmitSoundToAll("weapons/fx/rics/ric4.wav", client, SNDCHAN_WEAPON, SNDLEVEL_GUNFIRE);
		    }
		    case 'a':
		    {
			    if (StrEqual(sWeapon, "autoshotgun"))
					EmitSoundToAll("weapons/fx/rics/ric4.wav", client, SNDCHAN_WEAPON, SNDLEVEL_GUNFIRE);
		    }
		    case 'r':
		    {
			    if (StrEqual(sWeapon, "rifle"))
					EmitSoundToAll("weapons/fx/rics/ric4.wav", client, SNDCHAN_WEAPON, SNDLEVEL_GUNFIRE);
		    }
		    case 'h':
		    {
			    if (StrEqual(sWeapon, "hunting_rifle"))
					EmitSoundToAll("weapons/fx/rics/ric4.wav", client, SNDCHAN_WEAPON, SNDLEVEL_GUNFIRE);
		    }
		}
    }
    return Plugin_Continue;
}

static bool IsValidClient(int client)
{
	return (0 < client <= MaxClients && IsClientInGame(client));
} 