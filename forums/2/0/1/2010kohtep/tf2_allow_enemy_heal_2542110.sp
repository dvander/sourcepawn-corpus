#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.1.0"

public Plugin plugin = 
{
	name = "[TF2] Allow Enemy Heal",
	author = "2010kohtep",
	description = "Allows to heal enemy players.",
	version = PLUGIN_VERSION,
	url = "https://github.com/2010kohtep"
};

ConVar 	g_AnyHealEnabled;

Handle 	g_hConf;
Address g_pIsSameTeamCall;
bool 	g_bIsLinux;

int ReadByte(Address pAddr)
{
	if(pAddr == Address_Null)
	{
		return -1;
	}
	
	return LoadFromAddress(pAddr, NumberType_Int8);
}

void WriteData(Address pAddr, int[] Data, int iSize)
{
	if(pAddr == Address_Null)
	{
		return;
	}
	
	for (int i = 0; i < iSize; i++)
	{
		StoreToAddress(pAddr + view_as<Address>(i), Data[i], NumberType_Int8);
	}
}

// Return offsetted address
Address GameConfGetAddressEx(Handle h, const char[] patch, const char[] offset)
{
	Address pAddr = GameConfGetAddress(h, patch);
	
	if(pAddr == Address_Null)
	{
		return Address_Null;
	}
	
	int iOffset = GameConfGetOffset(h, offset);
	
	if(iOffset == -1)
	{
		return pAddr; // There's no offset, return just address
	}
	
	pAddr += view_as<Address>(iOffset);
	return pAddr;
}

void ToggleAnyHealMode(bool bEnable)
{
	if(bEnable)
	{
		if(g_bIsLinux)
		{
			WriteData(g_pIsSameTeamCall, {0x90, 0xE9}, 2);
		}
		else
		{
			WriteData(g_pIsSameTeamCall, {0xEB}, 1);
		}
	}
	else
	{
		if(g_bIsLinux)
		{
			WriteData(g_pIsSameTeamCall, {0x89, 0x74}, 2);
		}
		else
		{
			WriteData(g_pIsSameTeamCall, {0x75}, 1);
		}
	}
}

bool Patch_AllowedToHealTarget()
{
	Address pAddr = GameConfGetAddressEx(g_hConf, "Patch_AllowedToHealTarget", "CWeaponMedigun::AllowedToHealTarget");
	
	if(pAddr == Address_Null)
	{
		LogError("[ERROR] Failed to patch CWeaponMedigun::AllowedToHealTarget()");
		return false;
	}
	
	if(ReadByte(pAddr) == 0x75) // Windows
	{
		g_bIsLinux = false;
	}
	else if (ReadByte(pAddr) == 0x89) // Linux
	{
		g_bIsLinux = true;
	}
	else
	{
		// This situation probably never gonna happened, but just in case...
		
		LogError("[ERROR] Can't patch CWeaponMedigun::AllowedToHealTarget(), unknown signature.");
		return false;
	}
	
	g_pIsSameTeamCall = pAddr;
	ToggleAnyHealMode(true);
	
	return true;
}

public void OnPluginStart()
{
	g_hConf = LoadGameConfigFile("tf2.koh.enemyheal");
	if(g_hConf == null)
	{
		SetFailState("[ERROR] Can't find tf2.koh.enemyheal gamedata.");
		return;
	}

	if(Patch_AllowedToHealTarget())
	{
		g_AnyHealEnabled = CreateConVar("sm_anyheal_enabled", "1", "If non-zero, medic can heal enemy players.");
		g_AnyHealEnabled.AddChangeHook(OnAnyHealEnabledChange);
		
		CreateConVar("sm_anyheal_version", PLUGIN_VERSION, "Plugin version.", FCVAR_SPONLY);
	}
	
	delete g_hConf;
}

public void OnAnyHealEnabledChange(ConVar convar, char[] oldValue, char[] newValue)
{
	if (StringToInt(newValue) != 0)
	{
		ToggleAnyHealMode(true);
	}
	else
	{
		ToggleAnyHealMode(false);
	}
}