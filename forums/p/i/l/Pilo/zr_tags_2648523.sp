#include <sourcemod>
#include <cstrike>
#include <zombiereloaded>
#include <scp>

#undef REQUIRE_PLUGIN
#include <leader>
#include <zrcommander>
#define REQUIRE_PLUGIN

#pragma newdecls required

ConVar g_CVAR_EnableChatTags;
ConVar g_CVAR_EnableClanTags;

ConVar g_CVAR_ZombieChatTag;
ConVar g_CVAR_ZombieClanTag;

ConVar g_CVAR_MotherZombieChatTag;
ConVar g_CVAR_MotherZombieClanTag;

ConVar g_CVAR_HumanChatTag;
ConVar g_CVAR_HumanClanTag;

ConVar g_CVAR_CommanderChatTag;
ConVar g_CVAR_CommanderClanTag;

ConVar g_CVAR_LeaderChatTag;
ConVar g_CVAR_LeaderClanTag;

int g_EnableChatTags;
int g_EnableClanTags;

bool MotherZombie[MAXPLAYERS+1];

bool leader = false;
bool commander = false;

public Plugin myinfo =
{
	name = "[CS:GO ZR] Tags for Zombie Reloaded",
	description = "Chat and Clan Tags for Zombie Reloaded",
	author = "Hallucinogenic Troll",
	version = "1.2",
	url = "PTFun.net"
};

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
	
	g_CVAR_EnableChatTags = CreateConVar("zr_chattags_enable", "1", "Enables the Chat Tags for Zombies, Mother Zombies, Humans, and possibly, Leader/Commander", _, true, 0.0, true, 1.0);
	g_CVAR_EnableClanTags = CreateConVar("zr_clantags_enable", "1", "Enables the Clan Tags for Zombies, Mother Zombies, Humans, and possibly, Leader/Commander", _, true, 0.0, true, 1.0);
	// Zombie Tag //
	g_CVAR_ZombieChatTag = CreateConVar("zr_zombie_chat_tag", "[Zombie]", "Change the 'Zombie' chat tag");
	g_CVAR_ZombieClanTag = CreateConVar("zr_zombie_chat_tag", "[Zombie]", "Change the 'Zombie' clan tag");
	
	// MotherZombie Tag //
	g_CVAR_ZombieChatTag = CreateConVar("zr_mother_zombie_chat_tag", "[MotherZombie]", "Change the 'Mother Zombie' chat tag");
	g_CVAR_ZombieClanTag = CreateConVar("zr_mother_zombie_clan_tag", "[MotherZombie]", "Change the 'Mother Zombie' clan tag");
	
	// Human Tag //
	
	g_CVAR_HumanChatTag = CreateConVar("zr_human_chat_tag", "[HUMAN]", "Change the human chat tag");
	g_CVAR_HumanClanTag = CreateConVar("zr_human_clan_tag", "[HUMAN]", "Change the human clan tag");
	
	// Commander Tag //
	g_CVAR_CommanderChatTag = CreateConVar("zr_commander_chat_tag", "[Commander]", "Change the 'Commander' chat tag");
	g_CVAR_CommanderClanTag = CreateConVar("zr_commander_clan_tag", "[Commander]", "Change the 'Commander' clan tag");
	
	// Commander Tag //
	g_CVAR_LeaderChatTag = CreateConVar("zr_leader_chat_tag", "[Leader]", "Change the 'Commander' chat tag");
	g_CVAR_LeaderClanTag = CreateConVar("zr_leader_clan_tag", "[Leader]", "Change the 'Commander' clan tag");
	
	AutoExecConfig(true, "zr_chat_clan_tags");
}

public void OnConfigsExecuted()
{
	g_EnableChatTags = g_CVAR_EnableChatTags.IntValue;
	g_EnableClanTags = g_CVAR_EnableClanTags.IntValue;
	
	if(g_EnableClanTags)
		CreateTimer(0.1, Timer_CheckDelay, _, TIMER_REPEAT);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	MarkNativeAsOptional("Leader_CurrentLeader");
	MarkNativeAsOptional("zrc_is");
	return APLRes_Success;
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "leader"))
		leader = false;
		
	if(StrEqual(name, "zrcommander"))
		commander = false;
}
 
public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "leader"))
		leader = true;
		
	if(StrEqual(name, "zrcommander"))
		commander = true;
}

public void OnClientPostAdminCheck(int client)
{
	if(!IsValidClient(client))
		return;
	
	MotherZombie[client] = false;
}

public Action Timer_CheckDelay(Handle timer)
{
	if(g_EnableClanTags)	
		for (int i = 0; i < MaxClients; i++)
			if(IsValidClient(i))
				CheckTag(i);
}

public void CheckTag(int client)
{
	char zombietag[64], motherzombietag[64], humantag[64], commandertag[64], leadertag[64];
	GetConVarString(g_CVAR_MotherZombieChatTag, motherzombietag, sizeof(motherzombietag));
	GetConVarString(g_CVAR_ZombieChatTag, zombietag, sizeof(zombietag));
	GetConVarString(g_CVAR_HumanChatTag, humantag, sizeof(humantag));
	GetConVarString(g_CVAR_CommanderChatTag, commandertag, sizeof(commandertag));
	GetConVarString(g_CVAR_LeaderChatTag, leadertag, sizeof(leadertag));
	if(IsValidClient(client) && IsPlayerAlive(client))
	{
		char tag[40];
		if(ZR_IsClientHuman(client))
		{
			if(leader && Leader_CurrentLeader() == client)
				Format(tag, sizeof(tag), "%s ", leadertag);	
			else if(commander && zrc_is(client))
				Format(tag, sizeof(tag), "%s ", commandertag);			
			else		
				Format(tag, sizeof(tag), "%s ", humantag);
		}
		else if(ZR_IsClientZombie(client))
		{
			if(MotherZombie[client])
				Format(tag, sizeof(tag), "%s ", motherzombietag)
			else	
				Format(tag, sizeof(tag), "%s ", zombietag);
		}
		
		CS_SetClientClanTag(client, tag);
	}
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for(int client = 0; client < MaxClients; client++)
		MotherZombie[client] = false;
}

public int ZR_OnClientInfected(int client, int attacker, bool motherInfect, bool respawnOverride, bool respawn)
{
	if(IsValidClient(client))
	{
		if(motherInfect)
			MotherZombie[client] = true;
		else
			MotherZombie[client] = false;
	}
}

public Action OnChatMessage(int &client, Handle hRecipients, char[] name, char[] message)
{
	char chatzombietag[64], chatmotherzombietag[64], chathumantag[64], chatcommandertag[64], chatleadertag[64];
	GetConVarString(g_CVAR_MotherZombieClanTag, chatmotherzombietag, sizeof(chatmotherzombietag));
	GetConVarString(g_CVAR_ZombieClanTag, chatzombietag, sizeof(chatzombietag));
	GetConVarString(g_CVAR_HumanClanTag, chathumantag, sizeof(chathumantag));
	GetConVarString(g_CVAR_CommanderClanTag, chatcommandertag, sizeof(chatcommandertag));
	GetConVarString(g_CVAR_LeaderClanTag, chatleadertag, sizeof(chatleadertag));
	if(g_EnableChatTags)
	{
		if(IsValidClient(client) && IsPlayerAlive(client))
		{
			char tag[40];
			if(ZR_IsClientHuman(client))
			{
				if(leader && Leader_CurrentLeader() == client)
					Format(tag, sizeof(tag), "\x0E%s\x01", chatleadertag);
				else if(commander && zrc_is(client))
					Format(tag, sizeof(tag), "\x0E%s\x01", chatcommandertag);				
				else
					Format(tag, sizeof(tag), "\x0B%s\x01", chathumantag);
			}
			else if(ZR_IsClientZombie(client))
			{
				if(MotherZombie[client])
					Format(tag, sizeof(tag), "\x07%s\x01", chatmotherzombietag)
				else	
					Format(tag, sizeof(tag), "\x02%s\x01", chatzombietag);
			}
			else
				return Plugin_Continue;
			
			Format(name, MAXLENGTH_MESSAGE, " %s %s", tag, name);
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}

stock bool IsValidClient(int client)
{
	if(client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client))
		return true;
	
	return false;
}
