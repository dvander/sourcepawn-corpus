#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#define PLUGIN_VERSION "1.1"

new Handle:WeaponsTrie = INVALID_HANDLE;

new Handle:hcv_Enabled = INVALID_HANDLE;
new Handle:hcv_BombDelay = INVALID_HANDLE;
new Handle:hcv_Delay = INVALID_HANDLE;

new Handle:TIMER_BOMBDELAY[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:TIMER_SPAMDELAY[MAXPLAYERS+1] = INVALID_HANDLE;

new bool:BlockBombDrop[MAXPLAYERS+1];
new bool:BlockSpamDrop[MAXPLAYERS+1];


public Plugin:myinfo = {
	name = "Bot drop weapons",
	author = "Eyal282 ( FuckTheSchool )",
	description = "Press E on a bot to force it to drop his main weapon.",
	version = PLUGIN_VERSION,
	url = "NULL"
};

public OnPluginStart()
{
	HookEvent("player_use", Event_PlayerUse, EventHookMode_Pre);
	
	SetUpWeaponsTrie();
	
	hcv_Enabled = CreateConVar("bot_drop_weapons_enabled", "1", "Allow forcing teammate bots to drop their weapons by pressing \"E\" on them");
	hcv_BombDelay = CreateConVar("bot_drop_weapons_bomb_delay", "1.2", "Block pressing \"E\" this long after you make a bot drop his bomb, to prevent accidentally taking both his gun and bomb.");
	hcv_Delay = CreateConVar("bot_drop_weapons_delay", "5.0", "Block pressing \"E\" this long after making the bot drop his weapon to prevent griefing.");
	SetConVarString(CreateConVar("bot_drop_weapons_version", PLUGIN_VERSION), PLUGIN_VERSION);
	
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
		
		else if(!IsFakeClient(i))
			continue;
			
		SDKHook(i, SDKHook_WeaponDropPost, Hook_WeaponDropPost)
	}
}

SetUpWeaponsTrie()
{
	WeaponsTrie = CreateTrie(); // This trie contains the buy menu names ( recognizable name ) of all weapons in-game. However I commented out unneeded ones.
	/*
	SetTrieString(WeaponsTrie, "weapon_glock", "Glock-18");
	SetTrieString(WeaponsTrie, "weapon_hkp2000", "P2000");
	SetTrieString(WeaponsTrie, "weapon_usp_silencer", "USP-S");
	SetTrieString(WeaponsTrie, "weapon_elite", "Dual Berettas");
	SetTrieString(WeaponsTrie, "weapon_p250", "P250");
	SetTrieString(WeaponsTrie, "weapon_tec9", "Tec-9");
	SetTrieString(WeaponsTrie, "weapon_fiveseven", "Five-Seven");
	SetTrieString(WeaponsTrie, "weapon_cz75a", "CZ75-Auto");
	SetTrieString(WeaponsTrie, "weapon_deagle", "Desert Eagle");
	SetTrieString(WeaponsTrie, "weapon_revolver", "R8 Revolver");
	*/
	SetTrieString(WeaponsTrie, "weapon_nova", "Nova");
	SetTrieString(WeaponsTrie, "weapon_xm1014", "XM1014");
	SetTrieString(WeaponsTrie, "weapon_sawedoff", "Sawed-Off");
	SetTrieString(WeaponsTrie, "weapon_mag7", "MAG-7");
	SetTrieString(WeaponsTrie, "weapon_m249", "M249");
	SetTrieString(WeaponsTrie, "weapon_negev", "Negev");
	SetTrieString(WeaponsTrie, "weapon_mac10", "MAC-10");
	SetTrieString(WeaponsTrie, "weapon_mp9", "MP9");
	SetTrieString(WeaponsTrie, "weapon_mp7", "MP7");
	SetTrieString(WeaponsTrie, "weapon_mp5sd", "MP5-SD");
	SetTrieString(WeaponsTrie, "weapon_ump45", "UMP-45");
	SetTrieString(WeaponsTrie, "weapon_p90", "P90");
	SetTrieString(WeaponsTrie, "weapon_bizon", "PP-Bizon");
	SetTrieString(WeaponsTrie, "weapon_galilar", "Galil AR");
	SetTrieString(WeaponsTrie, "weapon_famas", "FAMAS");
	SetTrieString(WeaponsTrie, "weapon_ak47", "AK-47");
	SetTrieString(WeaponsTrie, "weapon_m4a1", "M4A4");
	SetTrieString(WeaponsTrie, "weapon_m4a1_silencer", "M4A1-S");
	SetTrieString(WeaponsTrie, "weapon_ssg08", "SSG 08");
	SetTrieString(WeaponsTrie, "weapon_sg556", "SG 553");
	SetTrieString(WeaponsTrie, "weapon_aug", "AUG");
	SetTrieString(WeaponsTrie, "weapon_awp", "AWP");
	SetTrieString(WeaponsTrie, "weapon_g3sg1", "G3SG1");
	SetTrieString(WeaponsTrie, "weapon_scar20", "SCAR-20");
	/*
	SetTrieString(WeaponsTrie, "weapon_molotov", "Molotov");
	SetTrieString(WeaponsTrie, "weapon_incgrenade", "Incendiary Grenade");
	SetTrieString(WeaponsTrie, "weapon_decoy", "Decoy Grenade");
	SetTrieString(WeaponsTrie, "weapon_flashbang", "Flashbang");
	SetTrieString(WeaponsTrie, "weapon_hegrenade", "High Explosive Grenade");
	SetTrieString(WeaponsTrie, "weapon_smokegrenade", "Smoke Grenade");
	
	SetTrieString(WeaponsTrie, "weapon_taser", "C4");
	SetTrieString(WeaponsTrie, "weapon_taser", "Zeus x27");
	SetTrieString(WeaponsTrie, "weapon_healthshot", "Health Shot");
	*/
}

public OnClientConnected(client)
{
	BlockBombDrop[client] = false;
	BlockSpamDrop[client] = false;
	if(TIMER_BOMBDELAY[client] != INVALID_HANDLE)
	{
		CloseHandle(TIMER_BOMBDELAY[client]);
		TIMER_BOMBDELAY[client] = INVALID_HANDLE;
	}
	if(TIMER_SPAMDELAY[client] != INVALID_HANDLE)
	{
		CloseHandle(TIMER_SPAMDELAY[client]);
		TIMER_SPAMDELAY[client] = INVALID_HANDLE;
	}
}

public OnClientDisconnect(client)
{
	BlockBombDrop[client] = false;
	BlockSpamDrop[client] = false;
	if(TIMER_BOMBDELAY[client] != INVALID_HANDLE)
	{
		CloseHandle(TIMER_BOMBDELAY[client]);
		TIMER_BOMBDELAY[client] = INVALID_HANDLE;
	}
	if(TIMER_SPAMDELAY[client] != INVALID_HANDLE)
	{
		CloseHandle(TIMER_SPAMDELAY[client]);
		TIMER_SPAMDELAY[client] = INVALID_HANDLE;
	}
}

public OnClientPutInServer(client)
{
	if(!IsFakeClient(client))
		return;
		
	SDKHook(client, SDKHook_WeaponDrop, Hook_WeaponDropPost)
}

public Hook_WeaponDropPost(bot, weapon)
{
	if(!IsValidEdict(weapon))
		return;
		
	else if(!IsClientInGame(bot))
		return;
		
	else if(!IsFakeClient(bot))
		return;
		
	new String:Classname[50];
	GetEdictClassname(weapon, Classname, sizeof(Classname));
	
	if(!StrEqual(Classname, "weapon_c4"))
		return;
		
	BlockBombDrop[bot] = true;

	new Float:BombDelay = GetConVarFloat(hcv_BombDelay);
	if(BombDelay <= 0.0)
		RequestFrame(Frame_UndoBlockBombDrop, GetClientUserId(bot));
	
	else
		TIMER_BOMBDELAY[bot] = CreateTimer(BombDelay, Timer_UndoBlockBombDrop, GetClientUserId(bot));
}

public Frame_UndoBlockBombDrop(UserId)
{
	new bot = GetClientOfUserId(UserId);

	if(!IsValidPlayer(bot))
		return;
		
	BlockBombDrop[bot] = false;
}

public Action:Timer_UndoBlockBombDrop(Handle:hTimer, UserId)
{
	new bot = GetClientOfUserId(UserId);

	if(!IsValidPlayer(bot))
		return;
		
	BlockBombDrop[bot] = false;
	
	TIMER_BOMBDELAY[bot] = INVALID_HANDLE;
}
public Action:Event_PlayerUse(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{
	if(!GetConVarBool(hcv_Enabled))
		return;
		
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(!IsValidPlayer(client))
		return;
	
	new bot = GetEventInt(hEvent, "entity");
	
	if(!IsValidPlayer(bot))
		return;
		
	else if(!IsFakeClient(bot))
		return;
		
	else if(GetClientTeam(client) != GetClientTeam(bot))
		return;
		
	else if(BlockBombDrop[bot]) // Due to bomb, we want the bomb to be dropped first and then the weapon.
		return;
		
	new WeaponToDrop = GetPlayerWeaponSlot(bot, CS_SLOT_PRIMARY);
	
	if(WeaponToDrop == -1)
		return;
		
	else if(BlockSpamDrop[client])
	{
		PrintToChat(client, " \x01You can make bots drop their weapons once every %.1f seconds.", GetConVarFloat(hcv_Delay));
		return;
	}
		
	CS_DropWeapon(bot, WeaponToDrop, true, true);
	
	BlockSpamDrop[client] = true;
	TIMER_SPAMDELAY[client] = CreateTimer(GetConVarFloat(hcv_Delay), Timer_UndoBlockSpamDrop, GetClientUserId(client));
	new String:WeaponName[50], String:Classname[50];
	GetEdictClassname(WeaponToDrop, Classname, sizeof(Classname));
	
	GetTrieString(WeaponsTrie, Classname, WeaponName, sizeof(WeaponName));
	PrintToChatTeam(GetClientTeam(client), " \x03%N\x01 forced\x04 bot\x03 %N\x01 to throw away his\x05 %s", client, bot, WeaponName);
}

public Action:Timer_UndoBlockSpamDrop(Handle:hTimer, UserId)
{
	new client = GetClientOfUserId(UserId);

	if(!IsValidPlayer(client))
		return;
		
	BlockSpamDrop[client] = false;
	
	TIMER_SPAMDELAY[client] = INVALID_HANDLE;
}

stock bool:IsValidPlayer(client)
{
	if(client <= 0)
		return false;
		
	else if(client > MaxClients)
		return false;
		
	return IsClientInGame(client);
}

stock PrintToChatTeam(Team, const String:format[], any:...)
{
	new String:buffer[291];
	VFormat(buffer, sizeof(buffer), format, 3);
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
		
		else if(IsFakeClient(i))
			continue;
			
		else if(GetClientTeam(i) != Team)
			continue;
			
		PrintToChat(i, buffer);
	}
}
