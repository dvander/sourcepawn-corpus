#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2attributes>

#pragma newdecls required

#define PLUGIN_VERSION "1.0"

#define SND_SPAWN		"Halloween.HeadlessBossSpawn"
#define SND_SPAWNRUMBLE	"Halloween.HeadlessBossSpawnRumble"
#define SPAWN	"/items/halloween/werewolf01.wav"
#define DEATH	"/ambient_mp3/wolf01.mp3"
#define SND_DEATH		"ui/halloween_boss_defeated_fx.wav"
#define SND_THUNDER1 "/ambient_mp3/lair/rolling_thunder1.mp3"
#define SND_THUNDER2 "/ambient_mp3/lair/rolling_thunder2.mp3"
#define SND_THUNDER3 "/ambient_mp3/lair/rolling_thunder3.mp3"
#define SND_THUNDER4 "/ambient_mp3/lair/rolling_thunder4.mp3"
#define SND_THUNDER5 "/ambient_mp3/medieval_thunder2.mp3"
#define SND_THUNDER6 "/ambient_mp3/medieval_thunder3.mp3"
#define SND_THUNDER7 "/ambient_mp3/medieval_thunder4.mp3"
#define SND_WOLF1 "/ambient_mp3/wolf01.mp3"
#define SND_WOLF2 "/ambient_mp3/wolf02.mp3"
#define SND_WOLF3 "/ambient_mp3/wolf03.mp3"
#define SND_WEREWOLF1 "/items/halloween/werewolf01.wav"
#define SND_WEREWOLF2 "/items/halloween/werewolf02.wav"
#define SND_WEREWOLF3 "/ambient_mp3/wolf03.mp3"
#define SND_BANCHEE "/items/halloween/banshee01.wav"
#define SND_SCREAM1 "/ambient_mp3/halloween/female_scream_10.mp3"
#define SND_SCREAM2 "/ambient_mp3/halloween/female_scream_01.mp3"
#define SND_SCREAM3 "/ambient_mp3/halloween/female_scream_03.mp3"
#define SND_SCREAM4 "/ambient_mp3/halloween/female_scream_04.mp3"
#define SND_YETI1 "/player/taunt_yeti_roar_first.wav"
#define SND_YETI2 "/player/taunt_yeti_roar_second.wav"

#define TEAM_CLASSNAME "tf_team"

#define FIREBALL	0 // Done
#define BATS 		1 // Done
#define PUMPKIN 	2 // Done
#define TELE 		3 // Done
#define LIGHTNING 	4 // Done
#define BOSS 		5 // Done
#define METEOR 		6 // Done
#define ZOMBIEH 	7 // Done
#define ZOMBIE 		8
#define PUMPKIN2 	9

public Plugin myinfo =
{
	name = "[TF2] Be the WolfMann BOSS",
	author = "PC Gamer",
	description = "Play as the WolfMann BOSS",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

bool g_bIsBossDemoWolf[MAXPLAYERS + 1];
bool g_wait[MAXPLAYERS + 1]; 
bool g_wait1[MAXPLAYERS + 1];
bool g_wait2[MAXPLAYERS + 1];
bool ambsounds = false;
int lastTeam[MAXPLAYERS + 1];
Handle g_hSDKTeamAddPlayer;
Handle g_hSDKTeamRemovePlayer;
Handle g_hEquipWearable;
Handle hGameData;

public void OnPluginStart()
{
	LoadTranslations("common.phrases");

	RegAdminCmd("sm_bewolfman", Command_opdemoman, ADMFLAG_SLAY, "It's a good time to run");
	RegAdminCmd("sm_bewolfmann", Command_opdemoman, ADMFLAG_SLAY, "It's a good time to run");
	
	HookEvent("post_inventory_application", EventInventoryApplication, EventHookMode_Post);
	HookEvent("player_death", Event_Death, EventHookMode_Post);

	hGameData = LoadGameConfigFile("bewolfmann");
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CTeam::AddPlayer");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	g_hSDKTeamAddPlayer = EndPrepSDKCall();
	if(g_hSDKTeamAddPlayer == INVALID_HANDLE)
	SetFailState("Could not find CTeam::AddPlayer! Update Gamedata");
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CTeam::RemovePlayer");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	g_hSDKTeamRemovePlayer = EndPrepSDKCall();
	if(g_hSDKTeamRemovePlayer == INVALID_HANDLE)
	SetFailState("Could not find CTeam::RemovePlayer! Update Gamedata");
	
	delete hGameData;

	GameData hTF2 = new GameData("sm-tf2.games"); // sourcemod's tf2 gamdata

	if (!hTF2)
	SetFailState("This plugin is designed for a TF2 dedicated server only.");

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetVirtual(hTF2.GetOffset("RemoveWearable") - 1);    // EquipWearable offset is always behind RemoveWearable, subtract its value by 1
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hEquipWearable = EndPrepSDKCall();

	if (!g_hEquipWearable)
	SetFailState("Failed to create call: CBasePlayer::EquipWearable");

	delete hTF2; 	
}

public void OnClientPutInServer(int client)
{
	OnClientDisconnect_Post(client);
}

public void OnClientDisconnect_Post(int client)
{
	if (g_bIsBossDemoWolf[client])
	{
		g_bIsBossDemoWolf[client] = false;
	}
}

public void OnMapStart()
{
	PrecacheSound(SPAWN);
	PrecacheScriptSound(SND_SPAWN);	
	PrecacheScriptSound(SND_SPAWNRUMBLE);	
	PrecacheSound(DEATH);
	PrecacheScriptSound(SND_DEATH);
	PrecacheSound(SND_THUNDER1);
	PrecacheSound(SND_THUNDER2);
	PrecacheSound(SND_THUNDER3);
	PrecacheSound(SND_THUNDER4);
	PrecacheSound(SND_THUNDER5);
	PrecacheSound(SND_THUNDER6);
	PrecacheSound(SND_THUNDER7);
	PrecacheSound(SND_WOLF1);
	PrecacheSound(SND_WOLF2);
	PrecacheSound(SND_WOLF3);
	PrecacheSound(SND_WEREWOLF1);
	PrecacheSound(SND_WEREWOLF2);
	PrecacheSound(SND_WEREWOLF3);
	PrecacheSound(SND_BANCHEE);
	PrecacheSound(SND_SCREAM1);
	PrecacheSound(SND_SCREAM2);	
	PrecacheSound(SND_SCREAM3);	
	PrecacheSound(SND_SCREAM4);
	PrecacheSound(SND_YETI1);
	PrecacheSound(SND_YETI2);		
}

public void EventInventoryApplication(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_bIsBossDemoWolf[client])
	{
		RemoveModel(client);

		SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0, 1);	
		ChangeClientTeamEx(client, lastTeam[client]);
		
		TF2Attrib_RemoveAll(client);		
		
		int weapon = GetPlayerWeaponSlot(client, 0); 
		if(IsValidEntity(weapon))
		{
			TF2Attrib_RemoveAll(weapon);
		}

		int weapon2 = GetPlayerWeaponSlot(client, 1); 
		if(IsValidEntity(weapon2))
		{
			TF2Attrib_RemoveAll(weapon2);
		}
		
		int weapon3 = GetPlayerWeaponSlot(client, 2); 
		if(IsValidEntity(weapon3))
		{
			TF2Attrib_RemoveAll(weapon3);
		}

		ambsounds = false;		

		g_bIsBossDemoWolf[client] = false;
		ForcePlayerSuicide(client);			
	}
}

public void Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int deathflags = GetEventInt(event, "death_flags");
	if (!(deathflags & TF_DEATHFLAG_DEADRINGER))
	{
		if (IsValidClient(client) && g_bIsBossDemoWolf[client])
		{
			RemoveModel(client);
			
			TF2Attrib_RemoveAll(client);		
			
			int weapon = GetPlayerWeaponSlot(client, 0); 
			if(IsValidEntity(weapon))
			{
				TF2Attrib_RemoveAll(weapon);
			}

			int weapon2 = GetPlayerWeaponSlot(client, 1); 
			if(IsValidEntity(weapon2))
			{
				TF2Attrib_RemoveAll(weapon2);
			}
			
			int weapon3 = GetPlayerWeaponSlot(client, 2); 
			if(IsValidEntity(weapon3))
			{
				TF2Attrib_RemoveAll(weapon3);
			}

			EmitSoundToAll(DEATH);
			EmitSoundToAll(SND_DEATH);
			ambsounds = false;				

			SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0, 1);	
			ChangeClientTeamEx(client, lastTeam[client]);
			
			g_bIsBossDemoWolf[client] = false;	

			float vecOrigin[3];
			GetClientAbsOrigin(client, vecOrigin);
			
			//Drop a Rare spellbook
			int spell = CreateEntityByName("tf_spell_pickup");
			if(IsValidEntity(spell))
			{
				DispatchKeyValueVector(spell, "origin", vecOrigin);
				DispatchKeyValueVector(spell, "basevelocity", view_as<float>({0.0, 0.0, 0.0}));
				DispatchKeyValueVector(spell, "velocity", view_as<float>({0.0, 0.0, 0.0}));
				DispatchKeyValue(spell, "powerup_model", "models/props_halloween/hwn_spellbook_upright_major.mdl");
				DispatchKeyValue(spell, "OnPlayerTouch", "!self,Kill,,0,-1");
				
				DispatchSpawn(spell);
				
				SetVariantString("OnUser1 !self:kill::60:1");
				AcceptEntityInput(spell, "AddOutput");
				AcceptEntityInput(spell, "FireUser1");
				
				SetEntPropEnt(spell, Prop_Send, "m_hOwnerEntity", client);
				SetEntProp(spell, Prop_Data, "m_nTier", 1);
			}			
		}
	}
}

public Action RemoveModel(int client)
{
	if (IsValidClient(client))
	{
		TF2Attrib_RemoveAll(client);		
		
		int weapon = GetPlayerWeaponSlot(client, 0); 
		if(IsValidEntity(weapon))
		{
			TF2Attrib_RemoveAll(weapon);
		}

		int weapon2 = GetPlayerWeaponSlot(client, 1); 
		if(IsValidEntity(weapon2))
		{
			TF2Attrib_RemoveAll(weapon2);
		}
		
		int weapon3 = GetPlayerWeaponSlot(client, 2); 
		if(IsValidEntity(weapon3))
		{
			TF2Attrib_RemoveAll(weapon3);
		}
		
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0);
		UpdatePlayerHitbox(client, 1.0);
	}
}

public Action Command_opdemoman(int client, int args)
{
	char arg1[32];
	if (args < 1)
	{
		arg1 = "@me";
	}
	else GetCmdArg(1, arg1, sizeof(arg1));
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
					arg1,
					client,
					target_list,
					MAXPLAYERS,
					COMMAND_FILTER_ALIVE|(args < 1 ? COMMAND_FILTER_NO_IMMUNITY : 0),
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (int i = 0; i < target_count; i++)
	{
		Makeopwolfmann(target_list[i]);
		LogAction(client, target_list[i], "\"%L\" made \"%L\" a WolfMann BOSS!", client, target_list[i]);
	}
	EmitSoundToAll(SPAWN);
	EmitGameSoundToAll(SND_SPAWNRUMBLE);
	EmitGameSoundToAll(SND_SPAWN);
	
	return Plugin_Handled;
}

Action Makeopwolfmann(int client)
{
	PrintToChat(client, "You are a WolfMann BOSS!");
	PrintToChat(client, "Magic Commands: Use Right-Click to cast FIREBALL spell,");
	PrintToChat(client, "Use Mouse3 button (press down on mousewheel) to cast LIGHTNING spell,");	
	PrintToChat(client, "Use 'H' or 'J' to cast METEOR spell.");
	PrintToChat(client, "You can attack BOTH teams!");

	Command_ambientsound1(client);	
	
	Handle hHudText = CreateHudSynchronizer();
	SetHudTextParams(-1.0, 0.2, 5.0, 255, 0, 0, 255);
	ShowSyncHudText(client, hHudText, "You are a WolfMann BOSS...  Read your Chat for instructions.");
	CloseHandle(hHudText);

	TF2_SetPlayerClass(client, TFClass_DemoMan);
	TF2_RegeneratePlayer(client);

	int ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll > MaxClients && IsValidEntity(ragdoll)) AcceptEntityInput(ragdoll, "Kill");
	char weaponname[32];
	GetClientWeapon(client, weaponname, sizeof(weaponname));
	if (strcmp(weaponname, "tf_weapon_", false) == 0)
	{
		SetEntProp(GetPlayerWeaponSlot(client, 2), Prop_Send, "m_iWeaponState", 0);
		TF2_RemoveCondition(client, TFCond_Slowed);
	}

	TF2_RemoveAllWearables(client);

	CreateHat(client, 543, 10, 6); //Hair of the Dog
	CreateHat(client, 544, 10, 6); //Scottish Snarl
	CreateHat(client, 545, 10, 6); //Pickled Paws
	
	SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1, 1);	

	TF2_RemoveWeaponSlot(client, 0);
	TF2_RemoveWeaponSlot(client, 1);
	TF2_RemoveWeaponSlot(client, 2);	
	CreateWeapon(client, "tf_weapon_bottle", 1013, 6); //Ham Shank

	TF2_SetHealth(client, 10000);

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.3);
	UpdatePlayerHitbox(client, 1.3);

	lastTeam[client] = GetClientTeam(client); 
	ChangeClientTeamEx(client, 0);
	
	g_bIsBossDemoWolf[client] = true;

	CreateTimer(0.1, Timer_Switch, client);
}

void UpdatePlayerHitbox(const int client, const float fScale) 
{ 
	static const float vecTF2PlayerMin[3] = { -24.5, -24.5, 0.0 };
	static const float vecTF2PlayerMax[3] = { 24.5,  24.5, 83.0 }; 
	
	float vecScaledPlayerMin[3];
	float vecScaledPlayerMax[3]; 

	vecScaledPlayerMin = vecTF2PlayerMin; 
	vecScaledPlayerMax = vecTF2PlayerMax; 
	
	ScaleVector(vecScaledPlayerMin, fScale); 
	ScaleVector(vecScaledPlayerMax, fScale); 
	
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMins", vecScaledPlayerMin); 
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxs", vecScaledPlayerMax); 
}

stock Action TF2_SetHealth(int client, int NewHealth)
{
	SetEntProp(client, Prop_Send, "m_iHealth", NewHealth, 1);
	SetEntProp(client, Prop_Data, "m_iHealth", NewHealth, 1);
}

public Action Timer_Switch(Handle timer, any client)
{
	if (IsValidClient(client))
	Giveopwolfman2(client);
}

Action Giveopwolfman2(int client)
{
	PrintToChat(client, "You are now the WolfMann BOSS");
	TF2Attrib_RemoveAll(client);

	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 1.0);

	TF2Attrib_SetByName(client, "max health additive bonus", 9825.0);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "cannot be backstabbed", 1.0);	
	TF2Attrib_SetByName(client, "major move speed bonus", 2.0);	
	TF2Attrib_SetByName(client, "dmg taken from blast reduced", 0.4);
	TF2Attrib_SetByName(client, "dmg taken from fire reduced", 0.4);
	TF2Attrib_SetByName(client, "dmg taken from bullets reduced", 0.4);
	TF2Attrib_SetByName(client, "dmg taken from crit reduced", 0.4);
	TF2Attrib_SetByName(client, "dmg from ranged reduced", 0.4);
	TF2Attrib_SetByName(client, "SET BONUS: dmg from sentry reduced", 0.4);	
	TF2Attrib_SetByName(client, "major increased jump height", 2.5);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.0);
	TF2Attrib_SetByName(client, "airblast vertical vulnerability multiplier", 0.0);
	TF2Attrib_SetByName(client, "health from packs decreased", 0.0);
	TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 13595446.0);
	TF2Attrib_SetByName(client, "attach particle effect", 13.0);	
	
	int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	if(IsValidEntity(Weapon3))
	{
		TF2Attrib_RemoveAll(Weapon3);
		
		TF2Attrib_SetByName(Weapon3, "melee attack rate bonus", 0.5);	
		TF2Attrib_SetByName(Weapon3, "melee bounds multiplier", 3.0);					
		TF2Attrib_SetByName(Weapon3, "melee range multiplier", 3.0);
		TF2Attrib_SetByName(Weapon3, "damage bonus", 12.0);
		TF2Attrib_SetByName(Weapon3, "armor piercing", 100.0);
		TF2Attrib_SetByName(Weapon3, "dmg pierces resists absorbs", 1.0);
		TF2Attrib_SetByName(Weapon3, "killstreak tier", 3.0);
		TF2Attrib_SetByName(Weapon3, "killstreak effect", 2005.0);
		TF2Attrib_SetByName(Weapon3, "killstreak idleeffect", 7.0);
		TF2Attrib_SetByName(Weapon3, "dmg bonus vs buildings", 3.0);
		TF2Attrib_SetByName(Weapon3, "attach particle effect", 13.0);		
	}
	TF2_SwitchtoSlot(client, 2);	
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{ 
	if (buttons & IN_ATTACK3 && g_bIsBossDemoWolf[client] == true && g_wait[client] == false)         
	{ 
		ShootProjectile(client, LIGHTNING);
		g_wait[client] = true;
		CreateTimer(2.0, Waiting, client);		
	}

	if (buttons & IN_ATTACK2 && g_bIsBossDemoWolf[client] == true && g_wait1[client] == false) 
	{  
		ShootProjectile(client, FIREBALL);
		g_wait1[client] = true;
		CreateTimer(1.0, Waiting1, client); 
	} 
	
	if (buttons & IN_USE && g_bIsBossDemoWolf[client] == true && g_wait2[client] == false) 
	{  
		ShootProjectile(client, METEOR);
		g_wait2[client] = true;
		CreateTimer(5.0, Waiting2, client); 
	} 	
	return Plugin_Continue;
}

public Action Command_ambientsound1(int client) 
{  
	int soundswitch1; 
	soundswitch1 = GetRandomInt(1, 7);     
	switch(soundswitch1) 
	{ 
	case 1: 
		{ 
			EmitSoundToAll(SND_THUNDER1); 
		} 
	case 2: 
		{ 
			EmitSoundToAll(SND_THUNDER2); 
		} 
	case 3: 
		{ 
			EmitSoundToAll(SND_THUNDER3); 
		} 
	case 4: 
		{ 
			EmitSoundToAll(SND_THUNDER4); 
		}
	case 5: 
		{ 
			EmitSoundToAll(SND_THUNDER5); 
		} 
	case 6: 
		{ 
			EmitSoundToAll(SND_THUNDER6); 
		} 
	case 7: 
		{ 
			EmitSoundToAll(SND_THUNDER7); 
		} 		
	} 
	ambsounds = true; 
	CreateTimer(10.0, Command_ambientsound2);     
}

public Action Command_ambientsound2(Handle timer) 
{  
	if (ambsounds == false) 
	{ 
		return Plugin_Handled; 
	} 
	int soundswitch2; 
	soundswitch2 = GetRandomInt(1, 3);     
	switch(soundswitch2) 
	{ 
	case 1: 
		{ 
			EmitSoundToAll(SND_WEREWOLF1); 
		} 
	case 2: 
		{ 
			EmitSoundToAll(SND_WEREWOLF2); 
		}
	case 3: 
		{ 
			EmitSoundToAll(SND_WEREWOLF3); 
		}		
	}     
	CreateTimer(10.0, Command_ambientsound3); 
	
	return Plugin_Handled; 
}

public Action Command_ambientsound3(Handle timer) 
{ 
	if (ambsounds == false) 
	{ 
		return Plugin_Handled; 
	} 
	
	int soundswitch3; 
	soundswitch3 = GetRandomInt(1, 11);     
	switch(soundswitch3) 
	{ 
	case 1: 
		{ 
			EmitSoundToAll(SND_BANCHEE); 
		} 
	case 2: 
		{ 
			EmitSoundToAll(SND_WOLF1);             
		} 
	case 3: 
		{ 
			EmitSoundToAll(SND_WOLF2);                 
		} 
	case 4: 
		{ 
			EmitSoundToAll(SND_YETI1);                 
		} 
	case 5: 
		{ 
			EmitSoundToAll(SND_YETI2);             
		} 
	case 6: 
		{ 
			EmitSoundToAll(SND_SCREAM1);                 
		} 
	case 7: 
		{ 
			EmitSoundToAll(SND_SCREAM2);                 
		} 
	case 8: 
		{ 
			EmitSoundToAll(SND_SCREAM3);                 
		} 
	case 9: 
		{ 
			EmitSoundToAll(SND_SCREAM4);             
		} 
	case 10: 
		{ 
			EmitSoundToAll(SND_BANCHEE);             
		} 
	case 11: 
		{ 
			EmitSoundToAll(SND_SCREAM1);         
		}             
	} 

	CreateTimer(10.0, Command_ambientsound4); 
	
	return Plugin_Handled; 
} 

public Action Command_ambientsound4(Handle timer) 
{  
	if (ambsounds == false) 
	{ 
		return Plugin_Handled; 
	} 
	int soundswitch1; 
	soundswitch1 = GetRandomInt(1, 7);     
	switch(soundswitch1) 
	{ 
	case 1: 
		{ 
			EmitSoundToAll(SND_THUNDER1); 
		} 
	case 2: 
		{ 
			EmitSoundToAll(SND_THUNDER2); 
		} 
	case 3: 
		{ 
			EmitSoundToAll(SND_THUNDER3); 
		} 
	case 4: 
		{ 
			EmitSoundToAll(SND_THUNDER4); 
		}
	case 5: 
		{ 
			EmitSoundToAll(SND_THUNDER5); 
		} 
	case 6: 
		{ 
			EmitSoundToAll(SND_THUNDER6); 
		} 
	case 7: 
		{ 
			EmitSoundToAll(SND_THUNDER7); 
		} 		
	} 

	CreateTimer(10.0, Command_ambientsound2);

	return Plugin_Handled;	
}

stock bool IsValidClient(int client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	return IsClientInGame(client);
}

stock bool IsValidWeapon(int weapon)
{
	if (!IsValidEntity(weapon))
	return false;
	
	decl String:class[64];
	GetEdictClassname(weapon, class, sizeof(class));
	
	if (strncmp(class, "tf_weapon_", 10) == 0 || strncmp(class, "tf_wearable_demoshield", 22) == 0)
	return true;
	
	return false;
}

void ChangeClientTeamEx(int iClient, int iNewTeamNum)
{
	int iTeamNum = GetEntProp(iClient, Prop_Send, "m_iTeamNum");
	
	// Safely swap team
	int iTeam = MaxClients+1;
	while ((iTeam = FindEntityByClassname(iTeam, TEAM_CLASSNAME)) != -1)
	{
		int iAssociatedTeam = GetEntProp(iTeam, Prop_Send, "m_iTeamNum");
		if (iAssociatedTeam == iTeamNum)
		SDK_Team_RemovePlayer(iTeam, iClient);
		else if (iAssociatedTeam == iNewTeamNum)
		SDK_Team_AddPlayer(iTeam, iClient);
	}
	
	SetEntProp(iClient, Prop_Send, "m_iTeamNum", iNewTeamNum);
}

void SDK_Team_AddPlayer(int iTeam, int iClient)
{
	if (g_hSDKTeamAddPlayer != INVALID_HANDLE)
	{
		SDKCall(g_hSDKTeamAddPlayer, iTeam, iClient);
	}
}

void SDK_Team_RemovePlayer(int iTeam, int iClient)
{
	if (g_hSDKTeamRemovePlayer != INVALID_HANDLE)
	{
		SDKCall(g_hSDKTeamRemovePlayer, iTeam, iClient);
	}
}

stock Action TF2_RemoveAllWearables(int client) 
{ 
	int wearable = -1; 
	while ((wearable = FindEntityByClassname(wearable, "tf_wearable*")) != -1) 
	{ 
		if (IsValidEntity(wearable)) 
		{ 
			int player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity"); 
			if (client == player) 
			{ 
				TF2_RemoveWearable(client, wearable); 
			} 
		} 
	} 

	while ((wearable = FindEntityByClassname(wearable, "tf_powerup_bottle")) != -1) 
	{ 
		if (IsValidEntity(wearable)) 
		{ 
			int player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity"); 
			if (client == player) 
			{ 
				TF2_RemoveWearable(client, wearable); 
			} 
		} 
	} 

	while ((wearable = FindEntityByClassname(wearable, "tf_weapon_spellbook")) != -1) 
	{ 
		if (IsValidEntity(wearable)) 
		{ 
			int player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity"); 
			if (client == player) 
			{ 
				TF2_RemoveWearable(client, wearable); 
			} 
		} 
	} 
}

bool CreateHat(int client, int itemindex, int level, int quality)
{
	int hat = CreateEntityByName("tf_wearable");
	
	if (!IsValidEntity(hat))
	{
		return false;
	}
	
	char entclass[64];
	GetEntityNetClass(hat, entclass, sizeof(entclass));
	SetEntData(hat, FindSendPropInfo(entclass, "m_iItemDefinitionIndex"), itemindex);
	SetEntData(hat, FindSendPropInfo(entclass, "m_bInitialized"), 1); 	
	SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), quality);
	SetEntProp(hat, Prop_Send, "m_bValidatedAttachedEntity", 1);

	if(itemindex == 543)
	{
		//TF2Attrib_SetByDefIndex(hat, 134, GetRandomInt(1,174) + 0.0);
		TF2Attrib_SetByDefIndex(hat, 134, 3036.0);		
	}
	
	//End Insert
	
	DispatchSpawn(hat);
	SDKCall(g_hEquipWearable, client, hat);
	return true;
}

int ShootProjectile(int client, int spell)
{
	float vAngles[3]; 
	float vPosition[3]; 
	GetClientEyeAngles(client, vAngles);
	GetClientEyePosition(client, vPosition);
	char strEntname[45] = "";
	switch(spell)
	{
	case FIREBALL: 		strEntname = "tf_projectile_spellfireball";
	case LIGHTNING: 	strEntname = "tf_projectile_lightningorb";
	case PUMPKIN: 		strEntname = "tf_projectile_spellmirv";
	case PUMPKIN2: 		strEntname = "tf_projectile_spellpumpkin";
	case BATS: 			strEntname = "tf_projectile_spellbats";
	case METEOR: 		strEntname = "tf_projectile_spellmeteorshower";
	case TELE: 			strEntname = "tf_projectile_spelltransposeteleport";
	case BOSS:			strEntname = "tf_projectile_spellspawnboss";
	case ZOMBIEH:		strEntname = "tf_projectile_spellspawnhorde";
	case ZOMBIE:		strEntname = "tf_projectile_spellspawnzombie";
	}
	int iTeam = GetClientTeam(client);
	int iSpell = CreateEntityByName(strEntname);
	
	if(!IsValidEntity(iSpell))
	return -1;
	
	float vVelocity[3];
	float vBuffer[3];
	
	GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
	
	vVelocity[0] = vBuffer[0]*1100.0; 
	vVelocity[1] = vBuffer[1]*1100.0;
	vVelocity[2] = vBuffer[2]*1100.0;
	
	SetEntPropEnt(iSpell, Prop_Send, "m_hOwnerEntity", client);
	SetEntProp(iSpell,    Prop_Send, "m_bCritical", (GetRandomInt(0, 100) <= 5)? 1 : 0, 1);
	SetEntProp(iSpell,    Prop_Send, "m_iTeamNum",     iTeam, 1);
	SetEntProp(iSpell,    Prop_Send, "m_nSkin", (iTeam-2));
	
	TeleportEntity(iSpell, vPosition, vAngles, NULL_VECTOR);
	
	SetVariantInt(iTeam);
	AcceptEntityInput(iSpell, "TeamNum", -1, -1, 0);
	SetVariantInt(iTeam);
	AcceptEntityInput(iSpell, "SetTeam", -1, -1, 0); 
	
	DispatchSpawn(iSpell);

	TeleportEntity(iSpell, NULL_VECTOR, NULL_VECTOR, vVelocity);
	
	return iSpell;
}

Action Waiting(Handle timer, any client) 
{
	g_wait[client] = false;
}

Action Waiting1(Handle timer, any client) 
{
	g_wait1[client] = false; 	
}

Action Waiting2(Handle timer, any client) 
{
	g_wait2[client] = false; 	
}

bool CreateWeapon(int client, char[] classname, int itemindex, int quality, int level = 0)
{
	int weapon = CreateEntityByName(classname);

	if (!IsValidEntity(weapon))
	{
		return false;
	}
	
	char entclass[64];
	GetEntityNetClass(weapon, entclass, sizeof(entclass));
	SetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex", itemindex);	 
	SetEntProp(weapon, Prop_Send, "m_bInitialized", 1);
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), quality);
	SetEntProp(weapon, Prop_Send, "m_bValidatedAttachedEntity", 1);	

	if (level)
	{
		SetEntProp(weapon, Prop_Send, "m_iEntityLevel", level);
	}
	else
	{
		SetEntProp(weapon, Prop_Send, "m_iEntityLevel", GetRandomInt(1,99));
	}

	switch (itemindex)
	{
	case 25, 26:
		{
			DispatchSpawn(weapon);
			EquipPlayerWeapon(client, weapon); 

			return true; 			
		}
	case 735, 736, 810, 933, 1080, 1102:
		{
			SetEntProp(weapon, Prop_Send, "m_iObjectType", 3);
			SetEntProp(weapon, Prop_Data, "m_iSubType", 3);
			SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 0);
			SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 1);
			SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 2);
			SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 3);
		}	
	case 998:
		{
			SetEntProp(weapon, Prop_Send, "m_nChargeResistType", GetRandomInt(0,2));
		}
	case 1071:
		{
			TF2Attrib_SetByName(weapon, "item style override", 0.0);
			TF2Attrib_SetByName(weapon, "loot rarity", 1.0);		
			TF2Attrib_SetByName(weapon, "turn to gold", 1.0);
			SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 11);			

			DispatchSpawn(weapon);
			EquipPlayerWeapon(client, weapon); 
			
			return true; 
		}
	}

	if(quality == 9)
	{
		TF2Attrib_SetByName(weapon, "is australium item", 1.0);
		TF2Attrib_SetByName(weapon, "item style override", 1.0);
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 11);
		
		TF2Attrib_SetByDefIndex(weapon, 2025, 1.0);

		if (GetRandomInt(1,5) == 1)
		{
			TF2Attrib_SetByDefIndex(weapon, 2025, 2.0);
			TF2Attrib_SetByDefIndex(weapon, 2014, GetRandomInt(1,7) + 0.0);
		}
		else if (GetRandomInt(1,5) == 2)
		{
			TF2Attrib_SetByDefIndex(weapon, 2025, 3.0);
			TF2Attrib_SetByDefIndex(weapon, 2014, GetRandomInt(1,7) + 0.0);
			TF2Attrib_SetByDefIndex(weapon, 2013, GetRandomInt(2002,2008) + 0.0);
		}
		
		TF2Attrib_SetByDefIndex(weapon, 214, view_as<float>(GetRandomInt(0, 9000)));		
	}

	if(itemindex == 200 || itemindex == 220 || itemindex == 448 || itemindex == 15002 || itemindex == 15015 || itemindex == 15021 || itemindex == 15029 || itemindex == 15036 || itemindex == 15053 || itemindex == 15065 || itemindex == 15069 || itemindex == 15106 || itemindex == 15107 || itemindex == 15108 || itemindex == 15131 || itemindex == 15151 || itemindex == 15157 || itemindex == 449 || itemindex == 15013 || itemindex == 15018 || itemindex == 15035 || itemindex == 15041 || itemindex == 15046 || itemindex == 15056 || itemindex == 15060 || itemindex == 15061 || itemindex == 15100 || itemindex == 15101
			|| itemindex == 15102 || itemindex == 15126 || itemindex == 15148 || itemindex == 44 || itemindex == 221 || itemindex == 205 || itemindex == 228 || itemindex == 1104 || itemindex == 15006 || itemindex == 15014 || itemindex == 15028 || itemindex == 15043 || itemindex == 15052 || itemindex == 15057 || itemindex == 15081 || itemindex == 15104 || itemindex == 15105 || itemindex == 15129 || itemindex == 15130 || itemindex == 15150 || itemindex == 196 || itemindex == 447 || itemindex == 208 || itemindex == 215 || itemindex == 1178 || itemindex == 15005 || itemindex == 15017 || itemindex == 15030 || itemindex == 15034
			|| itemindex == 15049 || itemindex == 15054 || itemindex == 15066 || itemindex == 15067 || itemindex == 15068 || itemindex == 15089 || itemindex == 15090 || itemindex == 15115 || itemindex == 15141 || itemindex == 351 || itemindex == 740 || itemindex == 192 || itemindex == 214 || itemindex == 326 || itemindex == 206 || itemindex == 308 || itemindex == 996 || itemindex == 1151 || itemindex == 15077 || itemindex == 15079 || itemindex == 15091 || itemindex == 15092 || itemindex == 15116 || itemindex == 15117 || itemindex == 15142 || itemindex == 15158 || itemindex == 207 || itemindex == 130 || itemindex == 15009
			|| itemindex == 15012 || itemindex == 15024 || itemindex == 15038 || itemindex == 15045 || itemindex == 15048 || itemindex == 15082 || itemindex == 15083 || itemindex == 15084 || itemindex == 15113 || itemindex == 15137 || itemindex == 15138 || itemindex == 15155 || itemindex == 172 || itemindex == 327 || itemindex == 404 || itemindex == 202 || itemindex == 41 || itemindex == 312 || itemindex == 424 || itemindex == 15004 || itemindex == 15020 || itemindex == 15026 || itemindex == 15031 || itemindex == 15040 || itemindex == 15055 || itemindex == 15086 || itemindex == 15087 || itemindex == 15088 || itemindex == 15098
			|| itemindex == 15099 || itemindex == 15123 || itemindex == 15124 || itemindex == 15125 || itemindex == 15147 || itemindex == 425 || itemindex == 997 || itemindex == 197 || itemindex == 329 || itemindex == 15073 || itemindex == 15074 || itemindex == 15075 || itemindex == 15139 || itemindex == 15140 || itemindex == 15114 || itemindex == 15156 || itemindex == 305 || itemindex == 211 || itemindex == 15008 || itemindex == 15010 || itemindex == 15025 || itemindex == 15039 || itemindex == 15050 || itemindex == 15078 || itemindex == 15097 || itemindex == 15121 || itemindex == 15122 || itemindex == 15123 || itemindex == 15145
			|| itemindex == 15146 || itemindex == 35 || itemindex == 411 || itemindex == 37 || itemindex == 304 || itemindex == 201 || itemindex == 402 || itemindex == 15000 || itemindex == 15007 || itemindex == 15019 || itemindex == 15023 || itemindex == 15033 || itemindex == 15059 || itemindex == 15070 || itemindex == 15071 || itemindex == 15072 || itemindex == 15111 || itemindex == 15112 || itemindex == 15135 || itemindex == 15136 || itemindex == 15154 || itemindex == 203 || itemindex == 15001 || itemindex == 15022 || itemindex == 15032 || itemindex == 15037 || itemindex == 15058 || itemindex == 15076 || itemindex == 15110
			|| itemindex == 15134 || itemindex == 15153 || itemindex == 193 || itemindex == 401 || itemindex == 210 || itemindex == 15011 || itemindex == 15027 || itemindex == 15042 || itemindex == 15051 || itemindex == 15062 || itemindex == 15063 || itemindex == 15064 || itemindex == 15103 || itemindex == 15128 || itemindex == 15129 || itemindex == 15149 || itemindex == 194 || itemindex == 649 || itemindex == 15062 || itemindex == 15094 || itemindex == 15095 || itemindex == 15096 || itemindex == 15118 || itemindex == 15119 || itemindex == 15143 || itemindex == 15144 || itemindex == 209 || itemindex == 15013 || itemindex == 15018
			|| itemindex == 15035 || itemindex == 15041 || itemindex == 15046 || itemindex == 15056 || itemindex == 15060 || itemindex == 15061 || itemindex == 15100 || itemindex == 15101 || itemindex == 15102 || itemindex == 15126 || itemindex == 15148 || itemindex == 415 || itemindex == 15003 || itemindex == 15016 || itemindex == 15044 || itemindex == 15047 || itemindex == 15085 || itemindex == 15109 || itemindex == 15132 || itemindex == 15133 || itemindex == 15152 || itemindex == 1153)
	{
		if(GetRandomInt(1,15) == 1)
		{
			TF2Attrib_SetByDefIndex(weapon, 2053, 1.0);
		}
	}
	
	if(quality == 11)
	{
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 11);
		
		TF2Attrib_SetByDefIndex(weapon, 2025, 1.0);

		if (GetRandomInt(1,5) == 1)
		{
			TF2Attrib_SetByDefIndex(weapon, 2025, 2.0);
			TF2Attrib_SetByDefIndex(weapon, 2014, GetRandomInt(1,7) + 0.0);
		}
		else if (GetRandomInt(1,5) == 2)
		{
			TF2Attrib_SetByDefIndex(weapon, 2025, 3.0);
			TF2Attrib_SetByDefIndex(weapon, 2014, GetRandomInt(1,7) + 0.0);
			TF2Attrib_SetByDefIndex(weapon, 2013, GetRandomInt(2002,2008) + 0.0);
		}
		
		TF2Attrib_SetByDefIndex(weapon, 214, view_as<float>(GetRandomInt(0, 9000)));
	}

	if (quality == 15)
	{
		switch(itemindex)
		{
		case 30665, 30666, 30667, 30668:
			{
				TF2Attrib_RemoveByDefIndex(weapon, 725);
			}
		default:
			{
				TF2Attrib_SetByDefIndex(weapon, 725, GetRandomFloat(0.0,1.0));
			}
		}
	}

	if (quality == 16)
	{
		quality = 14;
		int paint = GetRandomUInt(200, 283);
		if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274)
		{		
			paint = GetRandomUInt(300, 310);
		}
		TF2Attrib_SetByDefIndex(weapon, 834, view_as<float>(paint));

		if (GetRandomUInt(1,8) < 7)
		{
			TF2Attrib_SetByDefIndex(weapon, 725, GetRandomFloat(0.0,1.0));		
		}
		
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 14);		
	}
	
	if (quality >0 && quality < 9)
	{
		int rnd4 = GetRandomUInt(1,4);
		switch (rnd4)
		{
		case 1:
			{
				SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 1);
			}
		case 2:
			{
				SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 3);
			}
		case 3:
			{
				SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 7);
			}
		case 4:
			{
				SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 11);
				if (GetRandomInt(1,5) == 1)
				{
					TF2Attrib_SetByDefIndex(weapon, 2025, 1.0);
				}
				else if (GetRandomInt(1,5) == 2)
				{
					TF2Attrib_SetByDefIndex(weapon, 2025, 2.0);
					TF2Attrib_SetByDefIndex(weapon, 2014, GetRandomInt(1,7) + 0.0);
				}
				else if (GetRandomInt(1,5) == 3)
				{
					TF2Attrib_SetByDefIndex(weapon, 2025, 3.0);
					TF2Attrib_SetByDefIndex(weapon, 2014, GetRandomInt(1,7) + 0.0);
					TF2Attrib_SetByDefIndex(weapon, 2013, GetRandomInt(2002,2008) + 0.0);
				}
				
				TF2Attrib_SetByDefIndex(weapon, 214, view_as<float>(GetRandomInt(0, 9000)));
			}
		}
	}
	
	if (itemindex == 405 || itemindex == 608 || itemindex == 1101 || itemindex == 133 || itemindex == 444 || itemindex == 57 || itemindex == 231 || itemindex == 642 || itemindex == 131 || itemindex == 406 || itemindex == 1099 || itemindex == 1144)
	{
		DispatchSpawn(weapon);
		SDKCall(g_hEquipWearable, client, weapon);
	}

	else
	{
		DispatchSpawn(weapon);
		EquipPlayerWeapon(client, weapon); 
	}

	if (itemindex == 13
			|| itemindex == 200
			|| itemindex == 23
			|| itemindex == 209
			|| itemindex == 18
			|| itemindex == 205
			|| itemindex == 10
			|| itemindex == 199
			|| itemindex == 21
			|| itemindex == 208
			|| itemindex == 12
			|| itemindex == 19
			|| itemindex == 206
			|| itemindex == 20
			|| itemindex == 207
			|| itemindex == 15
			|| itemindex == 202
			|| itemindex == 11
			|| itemindex == 9
			|| itemindex == 22
			|| itemindex == 29
			|| itemindex == 211
			|| itemindex == 14
			|| itemindex == 201
			|| itemindex == 16
			|| itemindex == 203
			|| itemindex == 24
			|| itemindex == 210)	
	{
		if (GetRandomUInt(1,4) == 1)
		{
			TF2_SwitchtoSlot(client, 0);
			SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 5);			
			int iRand = GetRandomInt(1,4);
			if (iRand == 1)
			{
				TF2Attrib_SetByDefIndex(weapon, 134, 701.0);	
			}
			else if (iRand == 2)
			{
				TF2Attrib_SetByDefIndex(weapon, 134, 702.0);	
			}	
			else if (iRand == 3)
			{
				TF2Attrib_SetByDefIndex(weapon, 134, 703.0);	
			}
			else if (iRand == 4)
			{
				TF2Attrib_SetByDefIndex(weapon, 134, 704.0);	
			}
		}
		if (GetRandomUInt(1,4) == 1)
		{
			TF2_SwitchtoSlot(client, 1);
			SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 5);						
			int iRand2 = GetRandomInt(1,4);
			if (iRand2 == 1)
			{
				TF2Attrib_SetByDefIndex(weapon, 134, 701.0);	
			}
			else if (iRand2 == 2)
			{
				TF2Attrib_SetByDefIndex(weapon, 134, 702.0);	
			}	
			else if (iRand2 == 3)
			{
				TF2Attrib_SetByDefIndex(weapon, 134, 703.0);	
			}
			else if (iRand2 == 4)
			{
				TF2Attrib_SetByDefIndex(weapon, 134, 704.0);	
			}				
		}
	}
	TF2_SwitchtoSlot(client, 0);
	return true;
}

int GetRandomUInt(int min, int max)
{
	return RoundToFloor(GetURandomFloat() * (max - min + 1)) + min;
}

stock void TF2_SwitchtoSlot(int client, int slot)
{
	if (slot >= 0 && slot <= 5 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		char wepclassname[64];
		int wep = GetPlayerWeaponSlot(client, slot);
		if (wep > MaxClients && IsValidEdict(wep) && GetEdictClassname(wep, wepclassname, sizeof(wepclassname)))
		{
			FakeClientCommandEx(client, "use %s", wepclassname);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", wep);
		}
	}
}