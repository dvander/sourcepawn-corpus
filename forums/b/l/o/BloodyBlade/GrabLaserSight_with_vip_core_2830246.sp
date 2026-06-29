#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#undef REQUIRE_PLUGIN
#tryinclude <vip_core>

#define PLUGIN_VERSION "1.1.1"
#define CVAR_FLAGS FCVAR_NOTIFY
#define L4D2_WEPUPGFLAG_LASER (1 << 2)
#define VIP_AutoGrabLaserSight "AutoGrabLiserSight"

public Plugin myinfo =
{
    name = "Auto grab laser sight",
    author = "WolfGang(Edit. by BloodyBlade)",
    description = "Laser Sight on weapon pickup",
    version = PLUGIN_VERSION,
    url = ""
}

PluginData plugin;

enum struct PluginCvars
{
	ConVar hPluginEnabled;

	void Init()
	{
		CreateConVar("vip_autograblasersight_version", PLUGIN_VERSION, "AutoGrabLaserSight Version", CVAR_FLAGS|FCVAR_DONTRECORD);
		this.hPluginEnabled = CreateConVar("vip_autograblasersight_enable", "1", "Enable/Disable the plugin", CVAR_FLAGS, true, 0.0, true, 1.0);
		this.hPluginEnabled.AddChangeHook(ConVarPluginOnChanged);
		AutoExecConfig(true, "vip_autograblasersight");
	}
}

enum struct PluginData
{
	PluginCvars cvars;
	bool bPluginOn;
	bool bSDKHooked[MAXPLAYERS + 1];
	#if defined _vip_core_included
	bool bAGLS[MAXPLAYERS + 1];
	Cookie g_AGLSCookie;
	bool bVipCoreLib;
	#endif

	void Init()
	{
		this.cvars.Init();
		#if defined _vip_core_included
		this.g_AGLSCookie = new Cookie("VIP_AutoGrabLaserSight", "VIP_AutoGrabLaserSight", CookieAccess_Public);
		if(VIP_IsVIPLoaded())
		{
			VIP_OnVIPLoaded();
		}
		#endif
	}

	void GetCvarValues()
	{
		this.bPluginOn = this.cvars.hPluginEnabled.BoolValue;
	}
}

public void OnPluginStart()
{	
	plugin.Init();
}

#if defined _vip_core_included
public void VIP_OnVIPLoaded()
{
	plugin.bVipCoreLib = true;
	VIP_RegisterFeature(VIP_AutoGrabLaserSight, BOOL, TOGGLABLE, OnToggleAGLSItem);
}

public void OnLibraryRemoved(const char[] name)
{
	if(strcmp(name, "vip_core") == 0)
	{
		plugin.bVipCoreLib = false;
	}
}
#endif

public void OnConfigsExecuted()
{
	plugin.GetCvarValues();
}

void ConVarPluginOnChanged(ConVar cvar, char[] OldValue, char[] NewValue)
{
	plugin.GetCvarValues();
}

#if defined _vip_core_included
public Action OnToggleAGLSItem(int Client, const char[] sFeatureName, VIP_ToggleState OldStatus, VIP_ToggleState &NewStatus)
{
	if(NewStatus == ENABLED)
	{
		plugin.g_AGLSCookie.Set(Client, "1");
		plugin.bAGLS[Client] = true;
		int priWeapon = GetPlayerWeaponSlot(Client, 0); // Get primary weapon
		if (priWeapon > 0 && IsValidEntity(priWeapon))
		{
			char netclass[128];
			GetEntityNetClass(priWeapon, netclass, 128);
			if (FindSendPropInfo(netclass, "m_upgradeBitVec") > 0)
			{
				int upgrades = L4D2_GetWeaponUpgrades(priWeapon); // Get upgrades of primary weapon
				if (!(upgrades & L4D2_WEPUPGFLAG_LASER))
				{
					L4D2_SetWeaponUpgrades(priWeapon, upgrades | L4D2_WEPUPGFLAG_LASER); // Add laser sight to primary weapon
				}
			}
		}
	}
	else
	{
		plugin.g_AGLSCookie.Set(Client, "");
		plugin.bAGLS[Client] = false;
		int priWeapon = GetPlayerWeaponSlot(Client, 0); // Get primary weapon
		if (priWeapon > 0 && IsValidEntity(priWeapon))
		{
			char netclass[128];
			GetEntityNetClass(priWeapon, netclass, 128);
			if (FindSendPropInfo(netclass, "m_upgradeBitVec") > 0)
			{
				int upgrades = L4D2_GetWeaponUpgrades(priWeapon); // Get upgrades of dropped weapon
				if (upgrades & L4D2_WEPUPGFLAG_LASER)
				{
					L4D2_SetWeaponUpgrades(priWeapon, upgrades ^ L4D2_WEPUPGFLAG_LASER); // Remove laser sight from weapon
				}
			}
		}
	}
	return Plugin_Continue;
}
#endif

public void OnAllPluginsLoaded()
{
	if(plugin.bPluginOn)
	{
		/* For plugin reloading in mid game */
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsClientAuthorized(i))
			{
				SDKHook(i, SDKHook_WeaponEquipPost, OnClientWeaponEquip);
				SDKHook(i, SDKHook_WeaponDropPost, OnClientWeaponDrop);
				plugin.bSDKHooked[i] = true;
			}
		}
	}
}

#if defined _vip_core_included
public void OnClientCookiesCached(int Client)
{
	char cAGLS[8];
	plugin.g_AGLSCookie.Get(Client, cAGLS, sizeof(cAGLS));
	if(StringToInt(cAGLS) == 0) plugin.bAGLS[Client] = false;
	else plugin.bAGLS[Client] = view_as<bool>(StringToInt(cAGLS));
}
#endif

public void OnClientPutInServer(int client)
{
	if (plugin.bPluginOn && client > 0 && !plugin.bSDKHooked[client])
	{
		SDKHook(client, SDKHook_WeaponEquipPost, OnClientWeaponEquip);
		SDKHook(client, SDKHook_WeaponDropPost, OnClientWeaponDrop);
		plugin.bSDKHooked[client] = true;
	}
}

public void OnClientDisconnect(int client)
{
	if (client > 0 && plugin.bSDKHooked[client])
	{
		SDKUnhook(client, SDKHook_WeaponEquipPost, OnClientWeaponEquip);
		SDKUnhook(client, SDKHook_WeaponDropPost, OnClientWeaponDrop);
		plugin.bSDKHooked[client] = false;
	}
}

void OnClientWeaponEquip(int client, int weapon)
{
	if (plugin.bPluginOn && IsValidClient(client) && IsPlayerAlive(client))
	{
		int priWeapon = GetPlayerWeaponSlot(client, 0);
		#if defined _vip_core_included
		if(plugin.bVipCoreLib && VIP_IsClientVIP(client) && VIP_IsClientFeatureUse(client, VIP_AutoGrabLaserSight) && plugin.bAGLS[client] && priWeapon > 0 && IsValidEntity(priWeapon))
		#else
		if (priWeapon > 0 && IsValidEntity(priWeapon))
		#endif
		{
			char netclass[128];
			GetEntityNetClass(priWeapon, netclass, 128);
			if (FindSendPropInfo(netclass, "m_upgradeBitVec") > 0)
			{
				int upgrades = L4D2_GetWeaponUpgrades(priWeapon); // Get upgrades of primary weapon
				if (!(upgrades & L4D2_WEPUPGFLAG_LASER))
				{
					L4D2_SetWeaponUpgrades(priWeapon, upgrades | L4D2_WEPUPGFLAG_LASER); // Add laser sight to primary weapon
				}
			}
		}
	}
}

void OnClientWeaponDrop(int client, int weapon)
{
	if (plugin.bPluginOn && IsValidClient(client))
	{
		#if defined _vip_core_included
		if(plugin.bVipCoreLib && VIP_IsClientVIP(client) && VIP_IsClientFeatureUse(client, VIP_AutoGrabLaserSight) && plugin.bAGLS[client] && weapon > 0 && IsValidEntity(weapon))
		#else
		if (weapon > 0 && IsValidEntity(weapon))
		#endif
		{
			char netclass[128];
			GetEntityNetClass(weapon, netclass, 128);
			if (FindSendPropInfo(netclass, "m_upgradeBitVec") > 0)
			{
				int upgrades = L4D2_GetWeaponUpgrades(weapon); // Get upgrades of dropped weapon
				if (upgrades & L4D2_WEPUPGFLAG_LASER)
				{
					L4D2_SetWeaponUpgrades(weapon, upgrades ^ L4D2_WEPUPGFLAG_LASER); // Remove laser sight from weapon
				}
			}
		}
	}
}

stock int L4D2_GetWeaponUpgrades(int weapon)
{
	return GetEntProp(weapon, Prop_Send, "m_upgradeBitVec");
}

stock void L4D2_SetWeaponUpgrades(int weapon, int upgrades)
{
	SetEntProp(weapon, Prop_Send, "m_upgradeBitVec", upgrades);
}

stock bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}
