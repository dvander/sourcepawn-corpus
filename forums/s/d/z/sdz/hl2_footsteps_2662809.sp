#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define HL2MP_TEAM_COMBINE		2
#define HL2MP_TEAM_REBEL		3

/*
enum 
{
	PLAYER_SOUNDS_CITIZEN = 0,
	PLAYER_SOUNDS_COMBINESOLDIER,
	PLAYER_SOUNDS_METROPOLICE,
	PLAYER_SOUNDS_MAX
};
*/

ConVar g_cvRebelSounds;
ConVar g_cvCombineSounds;

public void OnPluginStart()
{
	g_cvRebelSounds = CreateConVar("sm_rebel_sounds", "0", "What footstep sound should rebels use?");
	g_cvCombineSounds = CreateConVar("sm_combine_sounds", "2", "What footstep sound should combine use?");

	g_cvRebelSounds.AddChangeHook(OnRebelSoundChanged);
	g_cvCombineSounds.AddChangeHook(OnCombineSoundChanged);

	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	AutoExecConfig(true);
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
}

public void OnWeaponEquipPost(int client, int weapon)
{
	if(GetClientTeam(client) == HL2MP_TEAM_COMBINE)
	{
		char class[32]; GetEdictClassname(weapon, class, sizeof(class));
		if(StrEqual(class, "weapon_crowbar", false))
		{
			AcceptEntityInput(weapon, "Kill");
			GivePlayerItem(client, "weapon_stunstick");
		}
	}
}

public void Event_PlayerSpawn(Event e, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(e.GetInt("userid"));
	if(!client) return;

	switch(GetClientTeam(client))
	{
		case HL2MP_TEAM_REBEL: SetEntProp(client, Prop_Send, "m_iPlayerSoundType", g_cvRebelSounds.IntValue);
		case HL2MP_TEAM_COMBINE: SetEntProp(client, Prop_Send, "m_iPlayerSoundType", g_cvCombineSounds.IntValue);
		default: SetEntProp(client, Prop_Send, "m_iPlayerSoundType", g_cvRebelSounds.IntValue);
	}
}

public void OnRebelSoundChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i) && !IsClientObserver(i) && GetClientTeam(i) == HL2MP_TEAM_REBEL)
		{
			SetEntProp(i, Prop_Send, "m_iPlayerSoundType", StringToInt(newValue));
		}
	}
}

public void OnCombineSoundChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i) && !IsClientObserver(i) && GetClientTeam(i) == HL2MP_TEAM_COMBINE)
		{
			SetEntProp(i, Prop_Send, "m_iPlayerSoundType", StringToInt(newValue));
		}
	}
}

public Plugin myinfo = 
{
	name = "Footstep Control",
	author = "sdz",
	description = "Allows the manipulation of footstep sounds",
	version = "1",
	url = "https://www.sourcemod.net"
};