#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required


bool IsTarget[MAXPLAYERS + 1];

int iSound;

char SoundPath[30][PLATFORM_MAX_PATH + 1];
bool cankillteammate = true;

public Plugin myinfo =
{
	name = "FakeTaserSound",
	author = "bklol",
	description = "ChangeTaserScream",
	version = "0.1",
	url = "",
}

public void OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	
	for(int i = 1; i <= MaxClients; i++)
	{ 
		if(IsValidClient(i))
		{
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
	AddNormalSoundHook(OnNormalSoundPlayed);
}

public void OnMapStart()
{
	LoadSounds();
}

public void OnClientPutInServer(int client)
{
	if(IsValidClient(client))
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		IsTarget[client] = false;
	}
}

public Action OnNormalSoundPlayed(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &client, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{

	if(channel != SNDCHAN_VOICE || sample[0] != '~')
		return Plugin_Continue;

	if(!IsValidClient(client))
		return Plugin_Continue;
		
	if (strcmp(soundEntry, "Player.Death") == 0 && IsTarget[client])
	{
		IsTarget[client] = false;
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public void LoadSounds()
{
	iSound = 0;
	
	char szPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szPath,PLATFORM_MAX_PATH, "configs/tasersounds.txt");
	if (!FileExists(szPath))
		SetFailState("Couldn't find file: %s", szPath);
	
	KeyValues kConfig = new KeyValues("");
	kConfig.ImportFromFile(szPath);
	kConfig.JumpToKey("sound");
	kConfig.GotoFirstSubKey();
	
	do {
	
		char Buffer[PLATFORM_MAX_PATH];
		kConfig.GetString("path", Buffer, PLATFORM_MAX_PATH);
		strcopy(SoundPath[iSound], PLATFORM_MAX_PATH, Buffer);
		PrintToServer("Load %s",SoundPath[iSound]);
		PrecacheSound(SoundPath[iSound]);
		Format(Buffer, sizeof(Buffer), "sound/%s",Buffer);
		AddFileToDownloadsTable(Buffer);
		iSound++;

	} while (kConfig.GotoNextKey())
}

public Action OnTakeDamage (int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if(!IsValidClient(victim) || !IsValidClient(attacker))
	{
		return Plugin_Continue;
	}
	char sWeapon[64];
	if(!GetEdictClassname(weapon, sWeapon, sizeof(sWeapon)))
		return Plugin_Continue;
	if(StrEqual(sWeapon,"weapon_taser"))
	{	
		if(GetClientTeam(victim) == GetClientTeam(attacker) && !cankillteammate)
			return Plugin_Continue;
		
		int iDamage = RoundToZero(damage);
		int health = GetEntProp(victim, Prop_Data, "m_iHealth");
		if(iDamage < health)
			return Plugin_Continue;
		else
		{
			IsTarget[victim] = true;
			SetEntProp(attacker, Prop_Send, "m_iAccount", GetEntProp(attacker, Prop_Send, "m_iAccount") + 800);
			//ForcePlayerSuicide(victim);
			SetEntProp(victim, Prop_Send, "m_ArmorValue", 0);
			SetEntityHealth(victim, 1);
			SDKHooks_TakeDamage(victim, attacker, attacker, damage, damagetype, _, damageForce , damagePosition);
			CreateDeathEvent(victim, attacker);
			PlayTaserSound(victim);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public void PlayTaserSound(int client)
{
	if(!IsClientInGame(client))
		return;
	float fPos[3], fAgl[3];
	GetClientEyePosition(client, fPos);
	GetClientEyeAngles  (client, fAgl);
	int speaker = SpawnSpeakerEntity(fPos, fAgl, client, 3.0);
	int H = GetRandomInt(0 , iSound - 1);
	for(int i = 1; i <= MaxClients; i++)
	{ 
		if(IsValidClient(i) && !IsFakeClient(i))
		{
			EmitSoundToClient(i,SoundPath[H], speaker, SNDCHAN_VOICE, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.8, SNDPITCH_NORMAL, speaker, fPos, fAgl, true);
		}
	}
}


public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	
	if(IsTarget[victim])
	{
		SetEventBroadcast(event, true);
	}
}

public void CreateDeathEvent(int victim, int attacker)
{
	Event event = CreateEvent("player_death");
	event.SetInt("userid", GetClientUserId(victim));
	event.SetInt("attacker", GetClientUserId(attacker)); 
	event.SetString("weapon", "weapon_taser");
	event.SetBool("headshot", false);
	
	for(int i = 1; i <= MaxClients; i++)
	{ 
		if(IsValidClient(i) && !IsFakeClient(i))
		{
			event.FireToClient(i);
		}
	}
	
	delete event;
}

stock int SpawnSpeakerEntity(float fPos[3], float fAgl[3], int source, float removeDelay = 0.1)
{
    int speaker = CreateEntityByName("info_target");
    
    if(speaker == -1)
        return -1;

    DispatchSpawn(speaker);

    TeleportEntity(speaker, fPos, fAgl, NULL_VECTOR);

    SetVariantString("!activator");
    AcceptEntityInput(speaker, "SetParent", source, speaker, 0);

    if(removeDelay > 0.0)
    {
        char input[128];
        FormatEx(input, 128, "OnUser4 !self:Kill::%.2f:1", removeDelay);
        SetVariantString(input);
        AcceptEntityInput(speaker, "AddOutput");
        AcceptEntityInput(speaker, "FireUser4");
    }

    return speaker;
}

stock bool IsValidClient( int client )
{
	if ( client < 1 || client > MaxClients ) return false;
	if ( !IsClientConnected( client )) return false;
	if ( !IsClientInGame( client )) return false;
	return true;
}