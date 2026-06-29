#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.1"
#define PLUGIN_TAG "infinite ammo"
#define sName "\x01[\x0700FF00Infinity\x01]"

new iAmmoOffset = -1;
new iClip1Offset = -1;
new Handle:hMaxStamina, Float:fMaxStamina,
	Handle:hInfAmmo, iInfAmmo,
	Handle:hInfStamina, bool:bInfStamina,
	bool:bTrue;

public Plugin:myinfo =
{
	name 		= "[NMRIH] Infinity",
	author 		= "Grey83",
	description 	= "Make endless clip/ammo & stamina in NMRiH",
	version 		= PLUGIN_VERSION,
	url 			= "https://forums.alliedmods.net/showthread.php?p=2378796"
}

public OnPluginStart()
{
	CreateConVar("nmrih_infinity_version", PLUGIN_VERSION, "[NMRIH] Infinity version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_DONTRECORD);
	hInfAmmo = CreateConVar("sm_inf_ammo", "1", "0 - Normal ammo/clip\n1 - Infinite ammo\n2 -  Infinite clip.", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	hInfStamina = CreateConVar("sm_inf_stamina", "1", "On/Off Infinite stamina.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hMaxStamina = FindConVar("sv_max_stamina");

	iInfAmmo = GetConVarInt(hInfAmmo);
	fMaxStamina = GetConVarFloat(hMaxStamina);
	bInfStamina= GetConVarBool(hInfStamina);

	HookConVarChange(hInfAmmo, OnConVarChange);
	HookConVarChange(hMaxStamina, OnConVarChange);
	HookConVarChange(hInfStamina, OnConVarChange);

	HookEvent("state_change", StateChange);

	iAmmoOffset = FindSendPropInfo("CNMRiH_Player", "m_iAmmo");
	iClip1Offset = FindSendPropInfo("CNMRiH_WeaponBase", "m_iClip1");

	AutoExecConfig(true, "nmrih_infinity");
}

public OnConfigsExecuted()
	Server_Tag(PLUGIN_TAG);

public OnConVarChange(Handle:hCvar, const String:oldValue[], const String:newValue[])
{
	if (hCvar == hInfAmmo)
	{
		iInfAmmo = StringToInt(newValue);
		OnConfigsExecuted();
	}
	else if (hCvar == hMaxStamina)
	{
		fMaxStamina = StringToFloat(newValue);
	}
	else if (hCvar == hInfStamina)
	{
		bInfStamina = bool:StringToInt(newValue);
	}
}

public StateChange(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iState = GetEventInt(event, "state");
	if (iState == 3 && iInfAmmo)
	{
		CreateTimer(10.0, RemoveAmmoBoxes, _, TIMER_REPEAT);
		bTrue = true;
	}
	else bTrue = false;
}

public Action:RemoveAmmoBoxes(Handle:timer)
{
	new maxent = GetMaxEntities(), String:item[64];
	for (new i = GetMaxClients(); i < maxent; i++)
	{
		if (IsValidEdict(i) && IsValidEntity(i))
		{
			GetEdictClassname(i, item, sizeof(item));
			if (StrEqual("item_ammo_box", item)) RemoveEdict(i);
		}
	}
	if (bTrue) return Plugin_Continue;
	else return Plugin_Stop;
}

public OnGameFrame()
{
	new iWeapon, iClip;
	for(new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			if (bInfStamina)
			{
				SetEntPropFloat(i, Prop_Send, "m_flStamina", fMaxStamina);
				SetEntProp(i, Prop_Send, "_bleedingOut", 0);
				SetEntProp(i, Prop_Send, "m_bSprintEnabled", 1);
				SetEntProp(i, Prop_Send, "m_bGrabbed", 0);
			}

			if (iInfAmmo == 2)
			{
				iWeapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
				if (IsValidEdict(iWeapon))
				{
					iClip = GetClipSize(i);
 					if (iClip >= 1 && iAmmoOffset > 0)
							SetEntData(iWeapon, iClip1Offset, iClip, _, true);
				}
			}
		}
	}
}

public Action:OnPlayerRunCmd(iClient, &iButtons, &iImpulse, Float:vecVelocity[3], Float:vecAngles[3], &iWeapon, &iWeaponSub, &nCommand, &nTick, &iRandomSeed, iMouseDir[2])
{
	if (0 < iClient <= MaxClients && IsClientInGame(iClient) && IsPlayerAlive(iClient) && (iInfAmmo))
	{
		if (iButtons & IN_RELOAD)
		{
			switch(iInfAmmo)
			{
				case 1:
					{
						new iAWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
						new iClip = GetClipSize(iClient);
						if (iAmmoOffset > 0 && iClip >= 1)
							{
								new iAmmoType = GetEntProp(iAWeapon, Prop_Send, "m_iPrimaryAmmoType");
								if (iClip1Offset > 0)
									iClip -= GetEntData(iAWeapon, iClip1Offset);
								new iBullets = GetEntData(iClient, iAmmoOffset + iAmmoType * 4);
								if (iBullets < iClip)
									SetEntData(iClient, iAmmoOffset + iAmmoType * 4, (iClip - iBullets), _, true);
							}
					}
				case 2:
					{
						iButtons &= ~IN_RELOAD; //Блочим ненужную кнопку при бесконечной обойме
					}
			}
		}
	}
	return Plugin_Continue;
}

stock GetClipSize(iClient)
{
	new String:sPlayerWeapon[32];
	GetClientWeapon(iClient, sPlayerWeapon, sizeof(sPlayerWeapon));

	if (StrEqual(sPlayerWeapon, "tool_flare_gun") || StrEqual(sPlayerWeapon, "tool_barricade") || StrContains(sPlayerWeapon, "exp_") == 0 || StrEqual(sPlayerWeapon, "bow_deerhunter"))
		return 1;
	else if (StrEqual(sPlayerWeapon, "fa_sv10"))
		return 2;
	else if (StrEqual(sPlayerWeapon, "fa_500a") || StrEqual(sPlayerWeapon, "fa_superx3") || StrContains(sPlayerWeapon, "fa_sako85") == 0)
		return 5;
	else if (StrEqual(sPlayerWeapon, "fa_sw686"))
		return 6;
	else if (StrEqual(sPlayerWeapon, "fa_1911"))
		return 7;
	else if (StrEqual(sPlayerWeapon, "fa_870"))
		return 8;
	else if (StrEqual(sPlayerWeapon, "fa_1022") || StrEqual(sPlayerWeapon, "fa_jae700") || StrEqual(sPlayerWeapon, "fa_mkiii") || StrContains(sPlayerWeapon, "fa_sks") == 0)
		return 10;
	else if (StrEqual(sPlayerWeapon, "fa_m92fs") || StrEqual(sPlayerWeapon, "fa_winchester1892"))
		return 15;
	else if (StrEqual(sPlayerWeapon, "fa_glock17"))
		return 17;
	else if (StrEqual(sPlayerWeapon, "fa_fnfal"))
		return 20;
	else if (StrEqual(sPlayerWeapon, "fa_1022_25mag"))
		return 25;
	else if (StrEqual(sPlayerWeapon, "fa_cz858") || StrContains(sPlayerWeapon, "fa_m16a4") == 0 || StrEqual(sPlayerWeapon, "fa_mac10") || StrEqual(sPlayerWeapon, "fa_mp5a3"))
		return 30;
	else if (StrEqual(sPlayerWeapon, "me_abrasivesaw"))
		return 80;
	else if (StrEqual(sPlayerWeapon, "me_chainsaw"))
		return 100;
	else return 0;
}

stock bool:Server_Tag(const String:tag[])
{
	static Handle:cvarTags = INVALID_HANDLE;
	if (cvarTags == INVALID_HANDLE)
	{
		cvarTags = FindConVar("sv_tags");
		if (cvarTags == INVALID_HANDLE)
			return false;
	}
	decl String:currentTags[255];
	GetConVarString(cvarTags, currentTags, sizeof(currentTags));
	if (StrContains(currentTags, tag, false) == -1)
	{
		Format(currentTags, sizeof(currentTags), "%s,%s", currentTags, tag);
		SetConVarString(cvarTags, currentTags);
	}
	return true;
}