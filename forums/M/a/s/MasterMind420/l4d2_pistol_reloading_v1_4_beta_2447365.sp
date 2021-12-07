/*NOTES

*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

HintIndex[2048+1];
HintEntity[2048+1];

PistolIndex[2048+1][2];
TempPistolArray[2];

static int PistolClip;
static int PistolAmmo;
static int DualPistolClip;
static int DualPistolAmmo;
static int MagnumClip;
static int MagnumAmmo;

bool bWeaponDrop;
bool bMissionLost;
bool bReloading[2048+1];
bool bPickedUp[MAXPLAYERS+1];
bool bUpdateHud[MAXPLAYERS+1];

ConVar PistolHud;
ConVar PistolAmmoClip;
ConVar PistolAmmoReserve;
ConVar MagnumAmmoClip;
ConVar MagnumAmmoReserve;

static const char Slot0Class[5][32] = {"rifle", "smg", "shotgun", "sniper", "grenade_launcher"};
static const char Slot1Class[3][32] = {"pistol", "pistol_magnum", "melee"};
static const char Slot2Class[3][32] = {"molotov", "pipe_bomb", "vomitjar"};
static const char Slot3Class[4][32] = {"first_aid_kit", "defibrillator", "upgradepack_incendiary", "upgradepack_explosive"};
static const char Slot4Class[2][32] = {"pain_pills", "adrenaline"};

public Plugin myinfo =
{
	name = "[L4D2] Pistol Reloading",
	author = "MasterMind420",
	description = "Enables adjustable pistol & magnum clip & ammo as well as reloading at ammo piles",
	version = "1.4",
	url = ""
};

public void OnPluginStart()
{
	//PistolResetClip = CreateConVar("l4d_pistol_reset_clip", "1", "1=Set Pistol Clip To 0 When Reloading", FCVAR_NOTIFY);
	PistolAmmoClip = CreateConVar("l4d_pistol_ammo_clip", "15", "Pistol ammo clip amount", FCVAR_NOTIFY);
	PistolAmmoReserve = CreateConVar("l4d_pistol_ammo_reserve", "75", "Pistol ammo reserve amount", FCVAR_NOTIFY);
	MagnumAmmoClip = CreateConVar("l4d_magnum_ammo_clip", "8", "Magnum ammo clip amount", FCVAR_NOTIFY);
	MagnumAmmoReserve = CreateConVar("l4d_magnum_ammo_reserve", "88", "Magnum ammo reserve amount", FCVAR_NOTIFY);
	PistolHud = CreateConVar("l4d_pistol_hud", "1", "0=Disable Pistol Hud, 1=Enable Pistol Hud", FCVAR_NOTIFY);

	HookEvent("round_start", eRoundStart, EventHookMode_PostNoCopy);
	HookEvent("mission_lost", eMissionLost, EventHookMode_PostNoCopy);

	HookEvent("player_team", ePlayerTeam);
	HookEvent("bot_player_replace", ePlayerBotReplace);
	HookEvent("player_bot_replace", eBotPlayerReplace);

	HookEvent("player_use", ePlayerUse);
	HookEvent("weapon_fire", eWeaponFire);

	AutoExecConfig(true, "l4d_pistol_reloading");

	PistolClip = GetConVarInt(PistolAmmoClip);
	PistolAmmo = GetConVarInt(PistolAmmoReserve);
	DualPistolClip = (PistolClip * 2);
	DualPistolAmmo = (PistolAmmo * 2);
	MagnumClip = GetConVarInt(MagnumAmmoClip);
	MagnumAmmo = GetConVarInt(MagnumAmmoReserve);

	SetConVarInt(FindConVar("ammo_pistol_max"), 1);

	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			OnClientPutInServer(i);
		}
	}
}

public void OnClientPutInServer(int client)
{
	DestroyHintEntity(client);
	CreateHintEntity(client);

	SDKHook(client, SDKHook_WeaponDrop, OnWeaponDrop);
	SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);

	if(GetConVarInt(PistolHud) == 1 && !IsFakeClient(client))
	{
		SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
	}
}

public Action OnPostThinkPost(int client)
{
	if(IsValidClient(client))
	{
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

		if(weapon > -1)
		{
			char sWeapon[32];
			GetEntityClassname(weapon, sWeapon, sizeof(sWeapon));

			if(StrContains(sWeapon, "pistol") > -1)
			{
				if(bReloading[weapon])
				{
					int InReload = GetEntProp(weapon, Prop_Data, "m_bInReload");

					if(!InReload)
					{
						bReloading[weapon] = false;
						DisplayInstructorHint(client, 1, 0.0, 0.0, true, false, 0, "", "", "", true, {255, 25, 25});
/*
						if(StrEqual(sWeapon, "weapon_pistol") && GetEntProp(weapon, Prop_Send, "m_isDualWielding") > 0)
						{
							SetEntProp(weapon, Prop_Data, "m_iClip1", DualPistolClip);
							SetEntProp(weapon, Prop_Send, "m_iClip1", DualPistolClip);

							int AmmoType = GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType");
							if(AmmoType == -1)
								return;

							//int Clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
							int Ammo = GetEntProp(client, Prop_Data, "m_iAmmo", _, AmmoType);

							SetEntProp(client, Prop_Send, "m_iAmmo", (Ammo - DualPistolClip), _, AmmoType);
						}
						else if(StrEqual(sWeapon, "weapon_pistol"))
						{
							SetEntProp(weapon, Prop_Data, "m_iClip1", PistolClip);
							SetEntProp(weapon, Prop_Send, "m_iClip1", PistolClip);

							int AmmoType = GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType");
							if(AmmoType == -1)
								return;

							//int Clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
							int Ammo = GetEntProp(client, Prop_Data, "m_iAmmo", _, AmmoType);

							SetEntProp(client, Prop_Send, "m_iAmmo", (Ammo - PistolClip), _, AmmoType);
						}
						else if(StrEqual(sWeapon, "weapon_pistol_magnum"))
						{
							SetEntProp(weapon, Prop_Data, "m_iClip1", MagnumClip);
							SetEntProp(weapon, Prop_Send, "m_iClip1", MagnumClip);

							int AmmoType = GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType");
							if(AmmoType == -1)
								return;

							//int Clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
							int Ammo = GetEntProp(client, Prop_Data, "m_iAmmo", _, AmmoType);

							SetEntProp(client, Prop_Send, "m_iAmmo", (Ammo - MagnumClip), _, AmmoType);
						}
*/
					}
				}
/*
				if(StrEqual(sWeapon, "weapon_pistol") && GetEntProp(weapon, Prop_Send, "m_isDualWielding") > 0) //DONT TRACK DUALIES THIS WAY
					return;

				int AmmoType = GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType");

				if(AmmoType > -1)
				{
					PistolIndex[weapon][0] = GetEntProp(weapon, Prop_Send, "m_iClip1");
					PistolIndex[weapon][1] = GetEntProp(client, Prop_Data, "m_iAmmo", _, AmmoType);
				}
*/
			}
		}
	}
}

public Action OnWeaponDrop(int client, int weapon) 
{
	if(IsValidClient(client) && IsValidEntity(weapon))
	{
		char sWeapon[32];
		GetEntityClassname(weapon, sWeapon, sizeof(sWeapon));

		int AmmoType = GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType");

		if(AmmoType > -1)
		{
			int Clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
			int Ammo = GetEntProp(client, Prop_Data, "m_iAmmo", _, AmmoType);

			if(StrEqual(sWeapon, "weapon_pistol") && GetEntProp(weapon, Prop_Send, "m_isDualWielding") > 0)
			{
				if(IsOdd(Clip + Ammo))
				{
					PistolIndex[weapon][0] = (Clip / 2);
					PistolIndex[weapon][1] = ((Ammo / 2) + 1);

					TempPistolArray[0] = (Clip / 2);
					TempPistolArray[1] = (Ammo / 2);
				}
				else
				{
					PistolIndex[weapon][0] = (Clip / 2);
					PistolIndex[weapon][1] = (Ammo / 2);

					TempPistolArray[0] = (Clip / 2);
					TempPistolArray[1] = (Ammo / 2);
				}

				bWeaponDrop = true;
			}
		}
	}

	return Plugin_Continue;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(classname[0] != 'w' || StrContains(classname, "weapon_", false) != 0)
		return;

	if(StrContains(classname, "pistol") > -1)
	{
		if(StrContains(classname, "spawn") == -1)
			SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);

		if(StrEqual(classname, "weapon_pistol"))
		{
			if(bWeaponDrop)
			{
				bWeaponDrop = false;

				PistolIndex[entity][0] = TempPistolArray[0];
				PistolIndex[entity][1] = TempPistolArray[1];
			}
			else
			{
				PistolIndex[entity][0] = PistolClip;
				PistolIndex[entity][1] = PistolAmmo;
			}
		}
		else if(StrEqual(classname, "weapon_pistol_magnum"))
		{
			PistolIndex[entity][0] = MagnumClip;
			PistolIndex[entity][1] = MagnumAmmo;
		}
	}
}

public void OnSpawnPost(int entity)
{
	if(IsValidEntity(entity))
	{
		SDKUnhook(entity, SDKHook_SpawnPost, OnSpawnPost);
		SDKHook(entity, SDKHook_ReloadPost, OnReloadPost);
	}
}

public void OnReloadPost(int weapon, bool bSuccessful)
{
	if(bSuccessful)
		bReloading[weapon] = true;
}

public void ePlayerUse(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int entity = event.GetInt("targetid");

	if(IsValidClient(client) && GetClientTeam(client) == 2 && IsValidEntity(entity))
	{
		char sWeapon[32];
		GetEntityClassname(entity, sWeapon, sizeof(sWeapon));

		int weapon = GetPlayerWeaponSlot(client, 1);

		char sSlot[32];

		if(StrEqual(sWeapon, "weapon_ammo_spawn"))
		{
			if(weapon > -1)
			{
				GetEntityClassname(weapon, sSlot, sizeof(sSlot));

				if(StrContains(sSlot, "pistol") > -1)
				{
					int AmmoType = GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType");
					if (AmmoType == -1)
						return;

					int Clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
					int Ammo = GetEntProp(client, Prop_Data, "m_iAmmo", _, AmmoType);

					float cPos[3];
					GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", cPos);

					float aPos[3];
					GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", aPos);

					if(GetVectorDistance(cPos, aPos) <= 96)
					{
						if(StrEqual(sSlot, "weapon_pistol") && GetEntProp(weapon, Prop_Send, "m_isDualWielding") > 0)
						{
							if (Ammo >= DualPistolAmmo && Clip == DualPistolClip)
								return;
							else if (Ammo > DualPistolAmmo && Clip <= DualPistolClip)
								return;

							SetEntProp(weapon, Prop_Send, "m_iClip1", 0);
							SetEntProp(client, Prop_Send, "m_iAmmo", DualPistolAmmo + DualPistolClip, _, AmmoType);

							ClientCommand(client, "play items/itempickup.wav");
						}
						else if(StrEqual(sSlot, "weapon_pistol"))
						{
							if (Ammo >= PistolAmmo && Clip == PistolClip)
								return;
							else if (Ammo > PistolAmmo && Clip <= PistolClip)
								return;

							SetEntProp(weapon, Prop_Send, "m_iClip1", 0);
							SetEntProp(client, Prop_Send, "m_iAmmo", PistolAmmo + PistolClip, _, AmmoType);

							ClientCommand(client, "play items/itempickup.wav");
						}
						else if(StrEqual(sSlot, "weapon_pistol_magnum"))
						{
							if (Ammo >= MagnumAmmo && Clip == MagnumClip)
								return;
							else if (Ammo > MagnumAmmo && Clip <= MagnumClip)
								return;

							SetEntProp(weapon, Prop_Send, "m_iClip1", 0);
							SetEntProp(client, Prop_Send, "m_iAmmo", MagnumAmmo + MagnumClip, _, AmmoType);

							ClientCommand(client, "play items/itempickup.wav");
						}
					}
				}
			}
		}
		else if(StrContains(sWeapon, "spawn") > -1)
		{
			char sModel[64];
			GetEntPropString(entity, Prop_Data, "m_ModelName", sModel, sizeof(sModel));

			if(StrContains(sModel, "w_pistol_A") > -1 || StrContains(sModel, "w_desert_eagle") > -1)
			{
				int AmmoType = GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType");
				if (AmmoType == -1)
					return;

				if(weapon > -1)
				{
					//int Clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
					//int Ammo = GetEntProp(client, Prop_Data, "m_iAmmo", _, AmmoType);

					GetEntityClassname(weapon, sSlot, sizeof(sSlot));

					if(StrEqual(sSlot, "weapon_pistol") && GetEntProp(weapon, Prop_Send, "m_isDualWielding") > 0)
					{
						SetEntProp(weapon, Prop_Data, "m_iClip1", DualPistolClip);
						SetEntProp(weapon, Prop_Send, "m_iClip1", DualPistolClip);
						SetEntProp(client, Prop_Send, "m_iAmmo", DualPistolAmmo, _, AmmoType);

						//DO ACCEPTENTITYINPUT KILL HERE WITH PROPER CHECKING
					}
					else if(StrEqual(sSlot, "weapon_pistol"))
					{
						SetEntProp(weapon, Prop_Data, "m_iClip1", PistolClip);
						SetEntProp(weapon, Prop_Send, "m_iClip1", PistolClip);
						SetEntProp(client, Prop_Send, "m_iAmmo", PistolAmmo, _, AmmoType);
					}
					else if(StrEqual(sSlot, "weapon_pistol_magnum"))
					{
						SetEntProp(weapon, Prop_Data, "m_iClip1", MagnumClip);
						SetEntProp(weapon, Prop_Send, "m_iClip1", MagnumClip);
						SetEntProp(client, Prop_Send, "m_iAmmo", MagnumAmmo, _, AmmoType);
					}
				}
			}
		}
		else if(StrContains(sWeapon, "pistol") > -1)
		{
			bUpdateHud[client] = true;

			int AmmoType = GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType");
			if (AmmoType == -1)
				return;

			if(weapon > -1)
			{
				//int Clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
				//int Ammo = GetEntProp(client, Prop_Data, "m_iAmmo", _, AmmoType);

				GetEntityClassname(weapon, sSlot, sizeof(sSlot));

				if(StrEqual(sSlot, "weapon_pistol") && GetEntProp(weapon, Prop_Send, "m_isDualWielding") > 0)
				{
					SetEntProp(weapon, Prop_Data, "m_iClip1", (PistolIndex[weapon][0] + PistolIndex[entity][0]));
					SetEntProp(weapon, Prop_Send, "m_iClip1", (PistolIndex[weapon][0] + PistolIndex[entity][0]));
					SetEntProp(client, Prop_Send, "m_iAmmo", (PistolIndex[weapon][1] + PistolIndex[entity][1]), _, AmmoType);

					//DO ACCEPTENTITYINPUT KILL HERE WITH PROPER CHECKING
				}
				else if(StrEqual(sSlot, "weapon_pistol"))
				{
					SetEntProp(weapon, Prop_Data, "m_iClip1", PistolIndex[weapon][0]);
					SetEntProp(weapon, Prop_Send, "m_iClip1", PistolIndex[weapon][0]);
					SetEntProp(client, Prop_Send, "m_iAmmo", PistolIndex[weapon][1], _, AmmoType);
				}
				else if(StrEqual(sSlot, "weapon_pistol_magnum"))
				{
					SetEntProp(weapon, Prop_Data, "m_iClip1", PistolIndex[weapon][0]);
					SetEntProp(weapon, Prop_Send, "m_iClip1", PistolIndex[weapon][0]);
					SetEntProp(client, Prop_Send, "m_iAmmo", PistolIndex[weapon][1], _, AmmoType);
				}
			}
			else
			{
				SetEntProp(weapon, Prop_Data, "m_iClip1", PistolIndex[weapon][0]);
				SetEntProp(weapon, Prop_Send, "m_iClip1", PistolIndex[weapon][0]);
				SetEntProp(client, Prop_Send, "m_iAmmo", PistolIndex[weapon][1], _, AmmoType);
			}
		}
	}
}

//HUD SETUP//
public void eWeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	if(GetConVarInt(PistolHud) == 1)
	{
		int client = GetClientOfUserId(event.GetInt("userid"));

		if(IsValidClient(client))
		{
			char sClsName[32];
			event.GetString("weapon", sClsName, sizeof(sClsName));

			if(StrContains(sClsName, "pistol") > -1)
				bUpdateHud[client] = true;
		}
	}
}

public Action OnWeaponSwitchPost(int client, int weapon)
{
	if(IsValidClient(client) && GetClientTeam(client) == 2 && IsValidEntity(weapon))
	{
		weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");

		if(IsValidEntity(weapon))
		{
			char sClsName[32];
			GetEntityClassname(weapon, sClsName, sizeof(sClsName));

			if(StrContains(sClsName, "pistol") > -1)
			{
				CreateHintEntity(client);
				bUpdateHud[client] = true;
			}
			else
			{
				DestroyHintEntity(client);
			}
		}
	}
}

public void eRoundStart (Handle event, const char[] name, bool dontBroadcast)
{
	if(GetConVarInt(PistolHud) != 1)
		return;

	if(bMissionLost)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i) && GetClientTeam(i) != 3)
			{
				if(IsValidEntRef(HintIndex[i]))
				{
					AcceptEntityInput(HintIndex[i], "Kill");
					HintIndex[i] = -1;
				}

				HintEntity[i] = CreateEntityByName("env_instructor_hint");

				if(HintEntity[i] < 0)
					return;

				DispatchSpawn(HintEntity[i]);

				HintIndex[i] = EntIndexToEntRef(HintEntity[i]);
			}
		}
	}

	bMissionLost = false;
}

public void eMissionLost(Handle event, const char[] name, bool dontBroadcast)
{
	if(GetConVarInt(PistolHud) == 1)
		bMissionLost = true;
}

public void eBotPlayerReplace(Event event, const char[] name, bool dontBroadcast)
{
	if(GetConVarInt(PistolHud) == 1)
	{
		int bot = GetClientOfUserId(GetEventInt(event, "bot"));
		int player = GetClientOfUserId(GetEventInt(event, "player"));

		DestroyHintEntity(player);
		CreateHintEntity(bot);
	}
}

public void ePlayerBotReplace(Handle event, const char[] name, bool dontBroadcast)
{
	if(GetConVarInt(PistolHud) == 1)
	{
		int bot = GetClientOfUserId(GetEventInt(event, "bot"));
		int player = GetClientOfUserId(GetEventInt(event, "player"));

		DestroyHintEntity(bot);
		CreateHintEntity(player);
	}
}

public Action ePlayerTeam(Handle event, const char[] sEventName, bool bDontBroadcast)
{
	if(GetConVarInt(PistolHud) != 1)
		return;

	int team = GetEventInt(event, "team");
	int oldteam = GetEventInt(event, "oldteam");
	int disconnect = GetEventBool(event, "disconnect");
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(!IsValidClient(client))
		return;

	switch(oldteam)
	{
		case 0:
		{

		}
		case 1:
		{

		}
		case 2:
		{
			DestroyHintEntity(client);
		}
		case 3:
		{

		}
	}

	switch(team)
	{
		case 0:
		{

		}
		case 1:
		{

		}
		case 2:
		{
			CreateHintEntity(client);
		}
		case 3:
		{

		}
	}

	if(disconnect)
	{

	}
}

void DestroyHintEntity(int client)
{
	if(IsValidEntRef(HintIndex[client]))
	{
		AcceptEntityInput(HintIndex[client], "Kill");
		HintIndex[client] = -1;
	}
}

void CreateHintEntity(int client)
{
	if(IsValidEntRef(HintIndex[client]))
	{
		AcceptEntityInput(HintIndex[client], "Kill");
		HintIndex[client] = -1;
	}

	HintEntity[client] = CreateEntityByName("env_instructor_hint");

	if(HintEntity[client] < 0)
		return;

	DispatchSpawn(HintEntity[client]);

	HintIndex[client] = EntIndexToEntRef(HintEntity[client]);
}

public void OnGameFrame()
{
	if(!IsServerProcessing())
		return;

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			bPickedUp[i] = false; //FIXES ONPLAYER USE REPETETIVE PICKUP

			if(!IsFakeClient(i) && bUpdateHud[i])
			{
				bUpdateHud[i] = false;

				if(GetConVarInt(PistolHud) == 1)
				{
					int weapon = GetEntPropEnt(i, Prop_Data, "m_hActiveWeapon");

					if(weapon > -1)
					{
						char sClsName[32];
						GetEntityClassname(weapon, sClsName, sizeof(sClsName));

						if(StrContains(sClsName, "pistol") > -1)
						{
							DisplayInstructorHint(i, 1, 0.0, 0.0, true, false, 0, "", "", "", true, {255, 25, 25});

							int AmmoType = GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType");

							if(AmmoType > -1)
							{
								PistolIndex[weapon][0] = GetEntProp(weapon, Prop_Send, "m_iClip1");
								PistolIndex[weapon][1] = GetEntProp(i, Prop_Data, "m_iAmmo", _, AmmoType);
							}
						}
					}
				}
			}
			else if(IsFakeClient(i))
			{
				int weapon = GetEntPropEnt(i, Prop_Data, "m_hActiveWeapon");

				if(IsValidEntity(weapon))
				{
					char sClsName[32];
					GetEntityClassname(weapon, sClsName, sizeof(sClsName));

					if(StrContains(sClsName, "pistol") > -1)
					{
						int AmmoType = GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType");

						if(AmmoType > -1)
						{
							int Clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
							int Ammo = GetEntProp(i, Prop_Data, "m_iAmmo", _, AmmoType);

							if(Ammo <= 0 && Clip <= 1)
							{
								if(StrEqual(sClsName, "weapon_pistol"))
								{
									if(GetEntProp(weapon, Prop_Send, "m_isDualWielding") > 0)
									{
										SetEntProp(weapon, Prop_Send, "m_iClip1", 0);
										SetEntProp(i, Prop_Send, "m_iAmmo", DualPistolClip, _, AmmoType);
									}
									else
									{
										SetEntProp(weapon, Prop_Send, "m_iClip1", 0);
										SetEntProp(i, Prop_Send, "m_iAmmo", PistolClip, _, AmmoType);
									}
								}
								else if(StrEqual(sClsName, "weapon_pistol_magnum"))
								{
									SetEntProp(weapon, Prop_Send, "m_iClip1", 0);
									SetEntProp(i, Prop_Send, "m_iAmmo", MagnumClip, _, AmmoType);
								}
							}
						}
					}
				}
			}
		}
	}
}

stock void DisplayInstructorHint(int target, int iTimeout, float fHeight, float fRange, bool bFollow, bool bShowOffScreen, int flag, char[] sIconOnScreen, char[] sIconOffScreen, char[] sCmd, bool bShowTextAlways, int iColor[3])
{
	if(!IsValidEntity(target) || !IsValidEntity(HintEntity[target]))
		return;

	char sBuffer[32];

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && !IsFakeClient(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			if(i == target)
			{
				FormatEx(sBuffer, sizeof(sBuffer), "pistol_%d", target);
				DispatchKeyValue(target, "targetname", sBuffer);
				DispatchKeyValue(HintEntity[target], "hint_target", sBuffer);
				DispatchKeyValue(HintEntity[target], "hint_replace_key", sBuffer);

				DispatchKeyValue(HintEntity[target], "hint_instance_type", "2");
				DispatchKeyValue(HintEntity[target], "hint_display_limit", "0");
				DispatchKeyValue(HintEntity[target], "hint_suppress_rest", "1");
				DispatchKeyValue(HintEntity[target], "hint_auto_start", "false");
				DispatchKeyValue(HintEntity[target], "hint_local_player_only", "false");
				DispatchKeyValue(HintEntity[target], "hint_allow_nodraw_target", "true");

				int Weapon = GetEntPropEnt(i, Prop_Data, "m_hActiveWeapon");

				if (Weapon == -1)
					return;

				char sWeapon[32];
				GetEntityClassname(Weapon, sWeapon, sizeof(sWeapon));

				char Message[48];

				int AmmoType = GetEntProp(Weapon, Prop_Data, "m_iPrimaryAmmoType");

				if (AmmoType == -1)
					return;

				int Clip = GetEntProp(Weapon, Prop_Data, "m_iClip1");
				int Ammo = GetEntProp(i, Prop_Send, "m_iAmmo", _, AmmoType);

				if (StrEqual(sWeapon, "weapon_pistol", false))
				{
					if(GetEntProp(Weapon, Prop_Send, "m_isDualWielding") > 0)
					{
						if (Ammo == 0 && Clip <= 1)
							Format(Message, sizeof(Message), "EMPTY");
						else if (Ammo == (DualPistolAmmo + DualPistolClip) && Clip < 1)
							Format(Message, sizeof(Message), "RELOAD");
						else
							Format(Message, sizeof(Message), "%d/%d", Clip, Ammo);
					}
					else
					{
						if (Ammo == 0 && Clip <= 1)
							Format(Message, sizeof(Message), "EMPTY");
						else if (Ammo == (PistolAmmo + PistolClip) && Clip < 1)
							Format(Message, sizeof(Message), "RELOAD");
						else
							Format(Message, sizeof(Message), "%d/%d", Clip, Ammo);
					}
				}
				else if (StrEqual(sWeapon, "weapon_pistol_magnum", false))
				{
					if (Ammo == 0 && Clip <= 1)
						Format(Message, sizeof(Message), "EMPTY");
					else if (Ammo == (MagnumAmmo + MagnumClip) && Clip < 1)
						Format(Message, sizeof(Message), "RELOAD");
					else
						Format(Message, sizeof(Message), "%d/%d", Clip, Ammo);
				}
				else
					Format(Message, sizeof(Message), "%d/%d", Clip, Ammo);

				DispatchKeyValue(HintEntity[target], "hint_caption", Message);
				DispatchKeyValue(HintEntity[target], "hint_activator_caption", Message);
				DispatchKeyValue(HintEntity[target], "hint_color", "100 255 100");

				AcceptEntityInput(HintEntity[target], "ShowHint", i);
/*
				FormatEx(sBuffer, sizeof(sBuffer), "OnUser1 self:ShowHint");
				SetVariantString(sBuffer);
				AcceptEntityInput(HintEntity[target], "AddOutput");
				AcceptEntityInput(HintEntity[target], "FireUser1");
*/
			}
		}
	}
}

stock int DetectSlot(char[] sClassName)
{
    for (int i = 0; i < sizeof(Slot0Class); i++)
	{
        if (StrContains(sClassName, Slot0Class[i]) > -1)
            return 0;
    }

    for (int i = 0; i < sizeof(Slot1Class); i++)
	{
        if (StrContains(sClassName, Slot1Class[i]) > -1)
            return 1;
    }

    for (int i = 0; i < sizeof(Slot2Class); i++)
	{
        if (StrContains(sClassName, Slot2Class[i]) > -1)
            return 2;
    }

    for (int i = 0; i < sizeof(Slot3Class); i++)
	{
        if (StrContains(sClassName, Slot3Class[i]) > -1)
            return 3;
    }

    for (int i = 0; i < sizeof(Slot4Class); i++)
	{
        if (StrContains(sClassName, Slot4Class[i]) > -1)
            return 4;
    }

    return -1;
}


stock int GetEntityInArray(int entity)
{
	if(IsValidEntity(entity))
	{
		for(int i = MAXPLAYERS; i <= 2048; i++)
		{
			if(!IsValidEntity(i))
				continue;

			if(PistolIndex[entity][0] == PistolIndex[i][0])
				return i;
			else
				continue;
		}
	}

	return -1;
}

stock bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

stock bool IsValidEntRef(int iEntRef)
{
    int iEntity = EntRefToEntIndex(iEntRef);
    return (iEntRef && iEntity != INVALID_ENT_REFERENCE && IsValidEntity(iEntity));
}

stock bool IsEven(int number)
{
    return (number & 1) == 0;
}

stock bool IsOdd(int number)
{
    return (number & 1) == 1;
}