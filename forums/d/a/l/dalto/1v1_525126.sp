/*
1v1.sp

Description:
	When a 1 v 1 battle occurs allow the players to choose how to fight

Versions:
	1.0
		* Initial Release
	
	1.1
		* Fixed an bug where sometimes the 1v1 would ativate when only one person had selected to fight.
		* Made it so you cannot pick up weapons after choosing to fight
		* Added notifications to let everyone know what each player selected
		* Added chat vote announcement
		* Added sm_1v1_winner_money cvar
		* Added sm_1v1_winner_health cvar
		* Added sm_1v1_loser_money cvar
		* Added sm_1v1_loser_health cvar
		* Added sm_1v1_chicken_money cvar
		* Added sm_1v1_chicken_health cvar
		* Fixed alternate not changing problem
		* Made menu close if the first player chickens out
		* Fixed handle leaks
		* Made config file autoload
		* Added autoloading config file
		* Added a configurable start vote sound
		* Added a configurable chicken sound
	
*/


#include <sourcemod>
#include <sdktools>
#include "weapons.inc"

#pragma semicolon 1

#define PLUGIN_VERSION "1.1"

#define BEACON_DELAY 2.0
#define MAX_FILE_LEN 80

// Plugin definitions
public Plugin:myinfo = 
{
	name = "1v1",
	author = "dalto",
	description = "When a 1 v 1 battle occurs allow the players to choose how to fight",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

new Handle:g_hBeaconList[MAXPLAYERS + 1];
new Handle:g_CvarEnable = INVALID_HANDLE;
new Handle:g_CvarBeaconSoundName = INVALID_HANDLE;
new Handle:g_CvarStartSoundName = INVALID_HANDLE;
new Handle:g_CvarChickenSoundName = INVALID_HANDLE;
new Handle:g_CvarBeacon = INVALID_HANDLE;
new Handle:g_CvarWinnerHealth = INVALID_HANDLE;
new Handle:g_CvarWinnerMoney = INVALID_HANDLE;
new Handle:g_CvarLoserHealth = INVALID_HANDLE;
new Handle:g_CvarLoserMoney = INVALID_HANDLE;
new Handle:g_CvarChickenHealth = INVALID_HANDLE;
new Handle:g_CvarChickenMoney = INVALID_HANDLE;
new String:g_soundBeaconName[MAX_FILE_LEN];
new String:g_soundStartName[MAX_FILE_LEN];
new String:g_soundChickenName[MAX_FILE_LEN];
new g_beamSprite;
new g_haloSprite;
new g_teamVote[4];
new Handle:hMenu = INVALID_HANDLE;
new iMyWeapons, iHealth, iAccount;
new winner, loser, chicken;
new Handle:hGameConf = INVALID_HANDLE;
new Handle:hEquipWeapon = INVALID_HANDLE;
new bool:g_fighting = false;

public OnPluginStart()
{
	CreateConVar("sm_1v1_version", PLUGIN_VERSION, "1v1 Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_CvarEnable = CreateConVar("sm_1v1_enable", "1", "Set to 0 to disable 1v1");
	g_CvarBeaconSoundName = CreateConVar("sm_1v1_beacon_sound", "ambient/tones/elev1.wav", "The sound to play for the beacon");
	g_CvarStartSoundName = CreateConVar("sm_1v1_start_sound", "", "The sound to play for the start");
	g_CvarChickenSoundName = CreateConVar("sm_1v1_chicken_sound", "1v1/chicken.wav", "The sound to play to the chicken");
	g_CvarBeacon = CreateConVar("sm_1v1_beacon", "1", "Set to 0 to disable the beacon");
	g_CvarWinnerHealth = CreateConVar("sm_1v1_winner_health", "120", "Set to the amount of health the winner should have when they spawn, 0 to disable");
	g_CvarWinnerMoney = CreateConVar("sm_1v1_winner_money", "16000", "Set to the amount of money the winner should have when they spawn, 0 to disable");
	g_CvarLoserHealth = CreateConVar("sm_1v1_loser_health", "0", "Set to the amount of health the loser should have when they spawn, 0 to disable");
	g_CvarLoserMoney = CreateConVar("sm_1v1_loser_money", "0", "Set to the amount of money the loser should have when they spawn, 0 to disable");
	g_CvarChickenHealth = CreateConVar("sm_1v1_chicken_health", "50", "Set to the amount of health a chicken should have when they spawn, 0 to disable");
	g_CvarChickenMoney = CreateConVar("sm_1v1_chicken_money", "0", "Set to the amount of money a chicken should have when they spawn, 0 to disable");
	
	// offsets
	iMyWeapons = FindSendPropOffs("CBasePlayer", "m_hMyWeapons");
	iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
	iHealth = FindSendPropOffs("CCSPlayer", "m_iHealth");
	
	// We keep a cached copy of this so we need to watch it for changes
	HookConVarChange(g_CvarBeaconSoundName, OnSoundChanged);
	HookConVarChange(g_CvarStartSoundName, OnSoundChanged);
	HookConVarChange(g_CvarChickenSoundName, OnSoundChanged);

	// Execute the config file
	AutoExecConfig(true, "1v1");
	
	// Load the gamedata file
	hGameConf = LoadGameConfigFile("1v1.games");
	if(hGameConf == INVALID_HANDLE)
	{
		SetFailState("gamedata/1v1.games.txt not loadable");
	}

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "Weapon_Equip");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	hEquipWeapon = EndPrepSDKCall();
	
	HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", EventPlayerDeath, EventHookMode_PostNoCopy);
	HookEvent("round_end", EventRoundEnd, EventHookMode_PostNoCopy);
}

public OnConfigsExecuted()
{
	decl String:buffer[MAX_FILE_LEN];
	GetConVarString(g_CvarBeaconSoundName, g_soundBeaconName, sizeof(g_soundBeaconName));
	if(strcmp(g_soundBeaconName, ""))
	{
		PrecacheSound(g_soundBeaconName, true);
		Format(buffer, MAX_FILE_LEN, "sound/%s", g_soundBeaconName);
		AddFileToDownloadsTable(buffer);
	}
	GetConVarString(g_CvarStartSoundName, g_soundStartName, sizeof(g_soundStartName));
	if(strcmp(g_soundStartName, ""))
	{
		PrecacheSound(g_soundStartName, true);
		Format(buffer, MAX_FILE_LEN, "sound/%s", g_soundStartName);
		AddFileToDownloadsTable(buffer);
	}
	GetConVarString(g_CvarChickenSoundName, g_soundChickenName, sizeof(g_soundChickenName));
	if(strcmp(g_soundChickenName, ""))
	{
		PrecacheSound(g_soundChickenName, true);
		Format(buffer, MAX_FILE_LEN, "sound/%s", g_soundChickenName);
		AddFileToDownloadsTable(buffer);
	}
	g_beamSprite = PrecacheModel("materials/sprites/laser.vmt");
	g_haloSprite = PrecacheModel("materials/sprites/halo01.vmt");
}

public OnSoundChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	decl String:buffer[MAX_FILE_LEN];
	if(convar == g_CvarChickenSoundName)
	{
		strcopy(g_soundChickenName, sizeof(g_soundChickenName), newValue);
		PrecacheSound(g_soundChickenName, true);
		Format(buffer, sizeof(buffer), "sound/%s", g_soundChickenName);
		AddFileToDownloadsTable(buffer);
	}
	if(convar == g_CvarStartSoundName)
	{
		strcopy(g_soundStartName, sizeof(g_soundStartName), newValue);
		PrecacheSound(g_soundStartName, true);
		Format(buffer, sizeof(buffer), "sound/%s", g_soundStartName);
		AddFileToDownloadsTable(buffer);
	}
	if(convar == g_CvarBeaconSoundName)
	{
		strcopy(g_soundBeaconName, sizeof(g_soundBeaconName), newValue);
		PrecacheSound(g_soundBeaconName, true);
		Format(buffer, sizeof(buffer), "sound/%s", g_soundBeaconName);
		AddFileToDownloadsTable(buffer);
	}
}

public Action:EventRoundEnd(Handle:event,const String:name[],bool:dontBroadcast)
{
	g_teamVote[2] = -1;
	g_teamVote[3] = -1;
	g_fighting = false;
	if(IsValidHandle(hMenu))
	{
		CloseHandle(hMenu);
	}
}
public Action:EventPlayerDeath(Handle:event,const String:name[],bool:dontBroadcast)
{
	if(!GetConVarBool(g_CvarEnable))
	{
		return Plugin_Continue;
	}
	
	// We check to see if there is only one person left.
	new playerTeam[4];
	for (new i = 1; i <= GetMaxClients(); i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			if(playerTeam[GetClientTeam(i)])
			{
				playerTeam[GetClientTeam(i)] = -1;
			} else {
				playerTeam[GetClientTeam(i)] = i;
			}
		}
	}
	
	if(playerTeam[2] > 1 && playerTeam[3] > 1 && !IsFakeClient(playerTeam[2]) && !IsFakeClient(playerTeam[3]))
	{
		InitiateVote(playerTeam[2], playerTeam[3]);
	}
	
	if(g_fighting)
	{
		winner = GetClientOfUserId(GetEventInt(event, "attacker"));
		loser = GetClientOfUserId(GetEventInt(event, "userid"));
	}
	return Plugin_Continue;
}

public Action:EventPlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{
	// get the client
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// check to see if there is an outstanding handle from last round
	if(IsValidHandle(g_hBeaconList[client]))
	{
		CloseHandle(g_hBeaconList[client]);
	}

	// check if we need to set health or money
	if(client == winner && client)
	{
		if(GetConVarInt(g_CvarWinnerHealth))
		{
			SetEntData(client, iHealth, GetConVarInt(g_CvarWinnerHealth));
		}
		if(GetConVarInt(g_CvarWinnerMoney))
		{
			SetEntData(client, iAccount, GetConVarInt(g_CvarWinnerMoney));
		}
		winner = 0;
	}
	if(client == loser && client)
	{
		if(GetConVarInt(g_CvarLoserHealth))
		{
			SetEntData(client, iHealth, GetConVarInt(g_CvarLoserHealth));
		}
		if(GetConVarInt(g_CvarLoserMoney))
		{
			SetEntData(client, iAccount, GetConVarInt(g_CvarLoserMoney));
		}
		loser = 0;
	}
	if(client == chicken && client)
	{
		if(GetConVarInt(g_CvarChickenHealth))
		{
			SetEntData(client, iHealth, GetConVarInt(g_CvarChickenHealth));
		}
		if(GetConVarInt(g_CvarChickenMoney))
		{
			SetEntData(client, iAccount, GetConVarInt(g_CvarChickenMoney));
		}
		chicken = 0;
	}
	return Plugin_Continue;
}

public Action:BeaconTimer(Handle:timer, any:client)
{
	new color[] = {255, 75, 75, 255};
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return Plugin_Handled;
	}
	
	// create a beam effect and the anothor one immediately after
	BeamRing(client, color);
	CreateTimer(0.2, BeaconTimer2, client);
	if(strcmp(g_soundBeaconName, ""))
	{
		new Float:vec[3];
		GetClientEyePosition(client, vec);
		EmitAmbientSound(g_soundBeaconName, vec, client, SNDLEVEL_RAIDSIREN);
	}
	if(IsValidHandle(g_hBeaconList[client]))
	{
		CloseHandle(g_hBeaconList[client]);
	}
	g_hBeaconList[client] = CreateTimer(BEACON_DELAY, BeaconTimer, client);
	return Plugin_Handled;
}

public Action:BeaconTimer2(Handle:timer, any:client)
{
	new color[] = {255, 0, 0, 255};
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return Plugin_Handled;
	}
	
	BeamRing(client, color);
	
	return Plugin_Handled;
}

public BeamRing(client, color[4])
{
	new Float:vec[3];
	GetClientAbsOrigin(client, vec);
	vec[2] += 5;

	TE_Start("BeamRingPoint");
	TE_WriteVector("m_vecCenter", vec);
	TE_WriteFloat("m_flStartRadius", 20.0);
	TE_WriteFloat("m_flEndRadius", 400.0);
	TE_WriteNum("m_nModelIndex", g_beamSprite);
	TE_WriteNum("m_nHaloIndex", g_haloSprite);
	TE_WriteNum("m_nStartFrame", 0);
	TE_WriteNum("m_nFrameRate", 0);
	TE_WriteFloat("m_fLife", 1.0);
	TE_WriteFloat("m_fWidth", 3.0);
	TE_WriteFloat("m_fEndWidth", 3.0);
	TE_WriteFloat("m_fAmplitude", 0.0);
	TE_WriteNum("r", color[0]);
	TE_WriteNum("g", color[1]);
	TE_WriteNum("b", color[2]);
	TE_WriteNum("a", color[3]);
	TE_WriteNum("m_nSpeed", 50);
	TE_WriteNum("m_nFlags", 0);
	TE_WriteNum("m_nFadeLength", 0);
	TE_SendToAll();
}

public InitiateVote(client1, client2)
{
	hMenu = CreateMenu(VoteMenuHandler);
	SetMenuTitle(hMenu, "1 v 1:Knife Fight?");
	AddMenuItem(hMenu, "yes", "Yes");
	AddMenuItem(hMenu, "no", "No");
	SetMenuExitButton(hMenu, false);
	DisplayMenu(hMenu, client1, 10);
	DisplayMenu(hMenu, client2, 10);
	PrintToChatAll("1v1 challenge initated");
	if(strcmp(g_soundChickenName, ""))
	{
		EmitSoundToClient(client1, g_soundChickenName);
		EmitSoundToClient(client2, g_soundChickenName);
	}
}

public VoteMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)	{
		decl String:name[30];
		if(param2 == 0)
		{
			// yes
			g_teamVote[GetClientTeam(param1)] = param1;
			GetClientName(param1, name, sizeof(name));
			PrintToChatAll("%s has accepted the challenge", name);
		} else {
			// no
			g_teamVote[GetClientTeam(param1)] = 0;
			GetClientName(param1, name, sizeof(name));
			PrintToChatAll("%s is too chicken", name);
			if(strcmp(g_soundChickenName, ""))
			{
				EmitSoundToClient(param1, g_soundChickenName);
			}
			chicken = param1;
			CloseHandle(menu);
		}
		if(g_teamVote[2] == -1 || g_teamVote[3] == -1)
		{
			// one of the players has not voted yet
			return;
		}
		if(g_teamVote[2] && g_teamVote[3])
		{
			DoKnifeFight(g_teamVote[2]);
			DoKnifeFight(g_teamVote[3]);
			g_fighting = true;
			CloseHandle(menu);
		}
	}
}

public DoKnifeFight(client)
{
	// The client needs to be valid or bad things could happen
	if(!(client && IsClientInGame(client)))
	{
		return;
	}
	
	// search through the players inventory for the weapon
	new weaponEntity;
	decl String:weapon[50];
	for(new i = 0; i < 32; i++)
	{
		weaponEntity = GetEntDataEnt(client, iMyWeapons + i * 4);
		if(weaponEntity && weaponEntity != -1)
		{
			GetEdictClassname(weaponEntity, weapon, sizeof(weapon));
			if(!IsKnife(weapon))
			{
				RemovePlayerItem(client, weaponEntity);
				RemoveEdict(weaponEntity);
			}
		}
	}
	EquipAvailableWeapon(client);
	
	if(GetConVarBool(g_CvarBeacon))
	{
		g_hBeaconList[client] = CreateTimer(0.2, BeaconTimer, client);
	}
}

public EquipAvailableWeapon(client)
{
	// Find a new weapon to equip
	new pos = 0;
	new weaponEntity = -1;
	do {
		weaponEntity = GetPlayerWeaponSlot(client, pos);
		pos++;
	} while(weaponEntity == -1 && pos < 5);
	if(weaponEntity != -1)
		SDKCall(hEquipWeapon, client, weaponEntity);
}

public IsKnife(const String:weapon[])
{
	// Counter Strike Knife
	if(StrEqual(weapon, "weapon_knife"))
		return 1;

	return 0;
}

public Action:Weapon_CanUse(client, const String:weapon[])
{
	if(g_fighting && !IsKnife(weapon))
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}