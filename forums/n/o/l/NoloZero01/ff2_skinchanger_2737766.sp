#include <sourcemod>
#include <freak_fortress_2>
#define MAXTF2PLAYERS 33
#define plugin_name "ff2_skinchanger"
#pragma newdecls required

//Code literally rebuilt from the original version that I decompiled.
public Plugin myinfo =
{
	name = "Freak Fortress 2: Skin Changer",
	description = "I lost Naydef's source code that I swear I had in my archives tfw",
	author = "Nolo001",
	version = "1.0"
};

public void OnPluginStart()
{
	HookEvent("teamplay_round_win", RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("arena_round_start", RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_death", PlayerDeath, EventHookMode_Post);
}

void ChangePlayerSkin(int client, int skin_index) //do it the polite way. if it's used several times, make a function outta it, rite?
{
	if(!IsValidClient(client))
		return;
	int bossindex = FF2_GetBossIndex(client);
	if(bossindex == -1)
		return;	

	SetEntProp(client, Prop_Send, "m_bForcedSkin", (skin_index == 0) ? 0 : 1, 4, 0);
	SetEntProp(client, Prop_Send, "m_nForcedSkin", skin_index, 4, 0);
}

public void RoundStart(Event event, const char[] name, bool plsNoBroadcast)
{
	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client))
			continue;

		int bossindex = FF2_GetBossIndex(client);
		if(bossindex == -1)
			continue;
			
		if(FF2_HasAbility(bossindex, plugin_name, "ability_skinchange"))
			ChangePlayerSkin(client, FF2_GetAbilityArgument(bossindex, plugin_name, "ability_skinchange", 1, 0));
	}
}

public void PlayerDeath(Event event, const char[] name, bool plsNoBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid", 0));
	if (!IsValidClient(client))
		return;
		
	int bossindex = FF2_GetBossIndex(client);
	if(bossindex == -1)
		return;
		
	if (FF2_HasAbility(bossindex, plugin_name, "ability_skinchange"))
		ChangePlayerSkin(client, 0);
}

public void RoundEnd(Event event, const char[] name, bool plsNoBroadcast)
{
	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client))
			continue;

		int bossindex = FF2_GetBossIndex(client);
		if(bossindex == -1)
			continue;
			
		if(FF2_HasAbility(bossindex, plugin_name, "ability_skinchange"))
			ChangePlayerSkin(client, 0);
	}
}

stock bool IsValidClient(int client, bool replaycheck=true) //grabbed from Batfoxkid's code as it was the first thing that I could find
{
	if(client<=0 || client>MaxClients)
		return false;

	if(!IsClientInGame(client))
		return false;

	if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
		return false;

	if(replaycheck && (IsClientSourceTV(client) || IsClientReplay(client)))
		return false;

	return true;
}