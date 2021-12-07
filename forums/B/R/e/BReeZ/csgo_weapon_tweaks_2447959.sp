#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

//You're welcome Mitch.
ConVar hConVar_NoSpread;
ConVar hConVar_Recoil_Cooldown;
ConVar hConVar_Recoil_Decay1Exp;
ConVar hConVar_Recoil_Decay2Exp;
ConVar hConVar_Recoil_Decay2Lin;
ConVar hConVar_Recoil_Scale;
ConVar hConVar_Recoil_SupressionShots;

//Cache if dropshot is enabled.
bool bDropShotEnabled[MAXPLAYERS + 1];

//Store weapon configurations
Handle hWeaponsArray_NoSpread;
Handle hWeaponsArray_NoRecoil;
Handle hWeaponsArray_Dropdown;
Handle hWeaponsTrie_Damage;

public Plugin myinfo =
{
	name = "CSGO Weapon Tweaks",
	author = "Keith Warren (Drixevel)",
	description = "Allows to tweak certain weapons while in use.",
	version = "1.0.3",
	url = "http://www.drixevel.com/"
};

public void OnPluginStart()
{
	//Hook the ConVar we need to edit and make sure It's set to 0.
	hConVar_NoSpread = FindConVar("weapon_accuracy_nospread");
	SetConVarInt(hConVar_NoSpread, 0);

	//No Recoil stuff.
	hConVar_Recoil_Cooldown = FindConVar("weapon_recoil_cooldown");
	hConVar_Recoil_Decay1Exp = FindConVar("weapon_recoil_decay1_exp");
	hConVar_Recoil_Decay2Exp = FindConVar("weapon_recoil_decay2_exp");
	hConVar_Recoil_Decay2Lin = FindConVar("weapon_recoil_decay2_lin");
	hConVar_Recoil_Scale = FindConVar("weapon_recoil_scale");
	hConVar_Recoil_SupressionShots = FindConVar("weapon_recoil_suppression_shots");

	//Load clients in already on the server.
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
	}

	//Hook the fire event since we'll need it.
	HookEvent("weapon_fire", OnWeaponFire, EventHookMode_Pre);

	//We need places to store weapon configurations.
	hWeaponsArray_NoSpread = CreateArray(ByteCountToCells(64));
	hWeaponsArray_NoRecoil = CreateArray(ByteCountToCells(64));
	hWeaponsArray_Dropdown = CreateArray(ByteCountToCells(64));
	hWeaponsTrie_Damage = CreateTrie();
}

public void OnConfigsExecuted()
{
	//Pull the weapon data we need.
	ParseWeaponsConfig("configs/csgo_weapon_tweaks.cfg");
}

void ParseWeaponsConfig(const char[] config)
{
	//Build the path to the configuration file.
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), config);

	//Create the Keyvalues and parse them.
	KeyValues hKV = CreateKeyValues("csgo_weapon_tweaks");

	if (!FileToKeyValues(hKV, sPath) || !KvGotoFirstSubKey(hKV))
	{
		LogError("Error loading weapon spread configurations.");
		return;
	}

	//Clear the arrays here so we have a valid list.
	ClearArray(hWeaponsArray_NoSpread);
	ClearArray(hWeaponsArray_NoRecoil);
	ClearArray(hWeaponsArray_Dropdown);
	ClearTrie(hWeaponsTrie_Damage);

	//DO WORK SON
	do {
		char sEntity[64];
		KvGetSectionName(hKV, sEntity, sizeof(sEntity));

		if (KvGetNum(hKV, "nospread") == 1)
		{
			PushArrayString(hWeaponsArray_NoSpread, sEntity);
		}

		if (KvGetNum(hKV, "norecoil") == 1)
		{
			PushArrayString(hWeaponsArray_NoRecoil, sEntity);
		}

		if (KvGetNum(hKV, "dropdown") == 1)
		{
			PushArrayString(hWeaponsArray_Dropdown, sEntity);
		}

		float fDamage = KvGetFloat(hKV, "damage");

		if (fDamage > 0.0)
		{
			SetTrieValue(hWeaponsTrie_Damage, sEntity, fDamage);
		}

	} while (KvGotoNextKey(hKV));

	//Good job son, proud of you.
	CloseHandle(hKV);
	LogMessage("Successfully parsed weapon spread configurations.");
}

//We do the dirty work of hooking when the weapon fires so we can enable/disable the spread ConVar the same frame.
//MESSY MESSY MESSY MESSY MESSY
public Action OnWeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (client == 0)
	{
		return;
	}

	char sWeapon[32];
	GetEventString(event, "weapon", sWeapon, sizeof(sWeapon));

	if (bDropShotEnabled[client] && GetEntProp(client, Prop_Send, "m_bIsScoped") || FindStringInArray(hWeaponsArray_NoSpread, sWeapon) != -1)
	{
		SetConVarInt(hConVar_NoSpread, 1);
		RequestFrame(Frame_DisableNoSpread);
	}
}

public void Frame_DisableNoSpread(any data)
{
	SetConVarInt(hConVar_NoSpread, 0);
}

public void OnClientPutInServer(int client)
{
	if (IsFakeClient(client))
	{
		return;
	}

	bDropShotEnabled[client] = false;
	SendConVarValue(client, hConVar_NoSpread, "0");

	SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);

	SDKHook(client, SDKHook_Touch, OnTouch);
}

public void OnClientDisconnect(int client)
{
	if (IsFakeClient(client))
	{
		return;
	}

	bDropShotEnabled[client] = false;
	SendConVarValue(client, hConVar_NoSpread, "0");

	//You don't have to unhook via SDK Hooks here but I do it anyways just in case.
	SDKUnhook(client, SDKHook_PostThinkPost, OnPostThinkPost);
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKUnhook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);

	SDKUnhook(client, SDKHook_Touch, OnTouch);
}

public void OnPostThinkPost(int client)
{
	if (!GetEntProp(client, Prop_Send, "m_bIsScoped") || GetSpeed(client) >= 50.0)
	{
		return;
	}

	int iActive = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	int flags = GetEntityFlags(client);

	if (IsValidEntity(iActive))
	{
		char sWeapon[32];
		GetEntityClassname(iActive, sWeapon, sizeof(sWeapon));

		if (!(flags & FL_ONGROUND) && FindStringInArray(hWeaponsArray_Dropdown, sWeapon) != -1)
		{
			SendConVarValue(client, hConVar_NoSpread, "1");
			SetEntPropFloat(iActive, Prop_Send, "m_fAccuracyPenalty", 0.0);

			/*float vel[3];
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", vel);

			float fTemp[3];
			fTemp[2] = vel[2];
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fTemp);*/

			bDropShotEnabled[client] = true;
		}
	}

	if (bDropShotEnabled[client] && flags & FL_ONGROUND || bDropShotEnabled[client] && flags & FL_INWATER)
	{
		SendConVarValue(client, hConVar_NoSpread, "0");
		bDropShotEnabled[client] = false;
	}
}

public void OnTouch(int client, int other)
{
	if (client > 0 && client <= MaxClients && bDropShotEnabled[client] && other == 0)
	{
		SendConVarValue(client, hConVar_NoSpread, "0");
		bDropShotEnabled[client] = false;
	}
}

//Hook this to add damage to shots done via dropdown.
public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (victim < 1 || victim > MaxClients || attacker < 1 || attacker > MaxClients)
	{
		return Plugin_Continue;
	}
	
	int actualweapon = GetEntPropEnt(attacker, Prop_Data, "m_hActiveWeapon");
	
	if (!IsValidEntity(actualweapon))
	{
		return Plugin_Continue;
	}
	
	char sWeapon[32];
	GetEntityClassname(actualweapon, sWeapon, sizeof(sWeapon));

	float fDamage;
	if (GetTrieValue(hWeaponsTrie_Damage, sWeapon, fDamage))
	{
		damage += fDamage;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

public Action OnWeaponSwitchPost(int client, int weapon)
{
	char sWeapon[32];
	GetEntityClassname(weapon, sWeapon, sizeof(sWeapon));

	if (FindStringInArray(hWeaponsArray_NoRecoil, sWeapon) != -1)
	{
		SendConVarValue(client, hConVar_Recoil_Cooldown, "0");
		SendConVarValue(client, hConVar_Recoil_Decay1Exp, "99999");
		SendConVarValue(client, hConVar_Recoil_Decay2Exp, "99999");
		SendConVarValue(client, hConVar_Recoil_Decay2Lin, "99999");
		SendConVarValue(client, hConVar_Recoil_Scale, "0");
		SendConVarValue(client, hConVar_Recoil_SupressionShots, "500");
	}
	else
	{
		SendConVarValue(client, hConVar_Recoil_Cooldown, "0.55");
		SendConVarValue(client, hConVar_Recoil_Decay1Exp, "3.5");
		SendConVarValue(client, hConVar_Recoil_Decay2Exp, "8");
		SendConVarValue(client, hConVar_Recoil_Decay2Lin, "18");
		SendConVarValue(client, hConVar_Recoil_Scale, "2");
		SendConVarValue(client, hConVar_Recoil_SupressionShots, "4");
	}
}

stock float GetSpeed(int client)
{
	float vel[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vel);
	return SquareRoot(vel[0] * vel[0] + vel[1] * vel[1]);
}
