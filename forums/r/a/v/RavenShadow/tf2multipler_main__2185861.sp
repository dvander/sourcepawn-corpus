#include <sourcemod>
#include <tf2items>
#include <tf2_stocks>
#include <sdktools>
#include <sdkhooks>
#include <steamtools>
#define PLUGIN_VERSION "0.0.2"
new Handle:hItemInfoTrie = INVALID_HANDLE;
new Handle:cvarEnabled;
new Handle:cvarVersion;
new bool:g_bSteamTools = false;
new bool:Disguised[MAXPLAYERS + 1] = false;
public Plugin:myinfo = 
{
    name = "[TF2] XMultiplier",
    author = "RavenShadow(Zool and DS9 Team for tf2items config script)",
    description = "Testing my Sanity",
    version = PLUGIN_VERSION,
    url = "www.google.com"
}
public OnPluginStart()
{
	CreateItemInfoTrie();
	cvarEnabled = CreateConVar("tf2multiplier_enabled", "1", "Enable x10 Gamemode", FCVAR_PLUGIN|FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	cvarVersion = CreateConVar("tf2multiplier_version", PLUGIN_VERSION, "Mulitplier Version", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD);
}
public OnAllPluginsLoaded()
{
	g_bSteamTools = LibraryExists("SteamTools");
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "SteamTools", false))
	{
		g_bSteamTools = true;
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "SteamTools", false))
	{
		g_bSteamTools = false;
	}
}
public OnConfigsExecuted()
{	
	if(g_bSteamTools && GetConVarBool(cvarEnabled))
	{
		new String:gamemode[64];
		Format(gamemode, sizeof(gamemode), "TF2 Multipler(%s)", PLUGIN_VERSION);
		Steam_SetGameDescription(gamemode);
	}
}
public OnClientPutInServer(client)
{
	Disguised[client] = false;
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if(!GetConVarBool(cvarEnabled))
	{
		return Plugin_Continue;
	}
	static bool:foundDmgCustom, bool:dmgCustomInOTD;
	if(!foundDmgCustom)
	{
		dmgCustomInOTD=(GetFeatureStatus(FeatureType_Capability, "SDKHook_DmgCustomInOTD")==FeatureStatus_Available);
		foundDmgCustom=true;
	}
	if (victim > 0 && victim <= MaxClients && attacker > 0 && attacker <= MaxClients && victim != attacker)
	{
		new bool:bIsBackstab;
		if(dmgCustomInOTD)
		{
			if(damagecustom==TF_CUSTOM_BACKSTAB)
			{
				bIsBackstab=true;
			}
		}
		if(bIsBackstab)
		{
			new melee=GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Melee);
			if(melee == 356)
			{
				SetEntProp(attacker, Prop_Data, "m_iHealth", 1800);
				SetEntProp(attacker, Prop_Send, "m_iHealth", 1800);
			}
		}
		else
		{
			if(!Disguised[attacker])
			{
				new weaponindex = (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"));
				if(IsValidEdict(weapon))
				{
					if(weaponindex == 460)
					{
						SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime()+3.0);
						SetEntPropFloat(attacker, Prop_Send, "m_flNextAttack", GetGameTime()+3.0);
						SetEntPropFloat(attacker, Prop_Send, "m_flStealthNextChangeTime", GetGameTime()+3.0);
					}
				}
			}
		}
	}
	return Plugin_Continue;
}
CreateItemInfoTrie()
{
	if (hItemInfoTrie != INVALID_HANDLE)
	{
		CloseHandle(hItemInfoTrie);
	}
	hItemInfoTrie = CreateTrie();
	decl String:strBuffer[256];
	BuildPath(Path_SM, strBuffer, sizeof(strBuffer), "configs/tf2items.x10.txt");
	decl String:strBuffer2[256];
	decl String:strBuffer3[PLATFORM_MAX_PATH];
	new Handle:hKeyValues = CreateKeyValues("TF2Itemsx10");
	if(FileToKeyValues(hKeyValues, strBuffer) == true)
	{
		KvGetSectionName(hKeyValues, strBuffer, sizeof(strBuffer));
		if (StrEqual("x10_config", strBuffer) == true)
		{
			if (KvGotoFirstSubKey(hKeyValues))
			{
				do
				{
					KvGetSectionName(hKeyValues, strBuffer, sizeof(strBuffer));
					if (strBuffer[0] != '*')
					{
						Format(strBuffer2, 256, "%s_%s", strBuffer, "attribs");
						KvGetString(hKeyValues, "attribs", strBuffer3, sizeof(strBuffer3));
						SetTrieString(hItemInfoTrie, strBuffer2, strBuffer3);
					}
				}
				while (KvGotoNextKey(hKeyValues));
				KvGoBack(hKeyValues);
			}
		}
	}
	CloseHandle(hKeyValues);
}
public Action:TF2Items_OnGiveNamedItem(client, String:classname[], iItemDefinitionIndex, &Handle:item)
{
	if(!GetConVarBool(cvarEnabled))
	{
		return Plugin_Continue;
	}
	//should cover nearly everything.
	if(!StrContains(classname, "tf_weapon_", false))
	{
		item = PrepareItemHandle(iItemDefinitionIndex);
		return Plugin_Changed;
	}
	//since idk how to cover the wearable weapons(GunBoats etc) along with the weapons in one statements do it this way for now
	switch(iItemDefinitionIndex)
	{
		case 131,406,1099,57,231,642,405,608,444,133:
		{
			item = PrepareItemHandle(iItemDefinitionIndex);
			return Plugin_Changed;
		}
		case 1101:
		{
			return Plugin_Continue;
		}
		default:
		{
			return Plugin_Continue;
		}
	}
	return Plugin_Continue;
}
stock Handle:PrepareItemHandle(weaponLookupIndex)
{
	static Handle:hWeapon;
	new addattribs;
	
	new String:formatBuffer[32];
	Format(formatBuffer, 32, "%d_%s", weaponLookupIndex, "attribs");
	new String:weaponAttribs[256];
	GetTrieString(hItemInfoTrie, formatBuffer, weaponAttribs, 256);
	new String:weaponAttribsArray[32][32];
	new attribCount = ExplodeString(weaponAttribs, " ; ", weaponAttribsArray, 32, 32);
	if(attribCount % 2)
	{
		--attribCount;
	}

	new flags=OVERRIDE_ATTRIBUTES;
	if(hWeapon==INVALID_HANDLE) hWeapon=TF2Items_CreateItem(flags);
	else TF2Items_SetFlags(hWeapon, flags);
	if (attribCount > 1) {
		new attrIdx;
		new Float:attrVal;
		TF2Items_SetNumAttributes(hWeapon, attribCount/2);
		new i2 = 0;
		for (new i = 0; i < attribCount; i+=2) {
			attrIdx = StringToInt(weaponAttribsArray[i]);
			if (attrIdx <= 0)
			{
				LogError("Tried to set attribute index to %d on weapon of index %d, attrib string was '%s', count was %d", attrIdx, weaponLookupIndex, weaponAttribs, attribCount);
				continue;
			}
			switch (attrIdx)
			{
				case 133, 143, 147, 152, 184, 185, 186, 192, 193, 194, 198, 211, 214, 227, 228, 229, 262, 294, 302, 372, 373, 374, 379, 381, 383, 403, 420:
				{
					attrVal = Float:StringToInt(weaponAttribsArray[i+1]);
				}
				default:
				{
					attrVal = StringToFloat(weaponAttribsArray[i+1]);
				}
			}
			TF2Items_SetAttribute(hWeapon, i2, attrIdx, attrVal);
			i2++;
		}
	} else {
		TF2Items_SetNumAttributes(hWeapon, 0);
	}
	return hWeapon;
}
stock GetIndexOfWeaponSlot(client, slot)
{
	new weapon=GetPlayerWeaponSlot(client, slot);
	return (weapon>MaxClients && IsValidEntity(weapon) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
}
//to check for disguised spies
public TF2_OnConditionAdded(client, TFCond:condition)
{
	if(!IsPlayerAlive(client)) return;
	if(condition == TFCond_Disguised)
	{
		Disguised[client] = true;
	}
}
public TF2_OnConditionRemoved(client, TFCond:condition)
{
	if(!IsPlayerAlive(client)) return;
	if(condition == TFCond_Disguised)
	{
		Disguised[client] = false;
	}
}