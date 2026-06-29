#include <sourcemod>
#include <tf2items>
#include <tf2_stocks>
#include <sdktools>
#include <sdkhooks>
#undef REQUIRE_EXTENSIONS
#tryinclude <steamtools>
#define REQUIRE_EXTENSIONS
#define PLUGIN_VERSION "1.2.3"
#define CHAT_PREFIX_NOCOLOR "[XMult]"
new Handle:hItemInfoTrie = INVALID_HANDLE;
new Handle:cvarEnabled;
new Handle:cvarVersion;
new bool:g_bSteamTools = false;
new bool:g_bLateLoad = false;
public Plugin:myinfo = 
{
    name = "[TF2] XMultiplicator",
    author = "RavenShadow(Zool and DS9 Team for tf2items config script)",
    description = "Public alternative to x10",
    version = PLUGIN_VERSION,
    url = "www.google.com"
}
public OnPluginStart()
{
	CreateItemInfoTrie();
	cvarEnabled = CreateConVar("xmultiplicator_enabled", "1", "Enable XMultiplicator Gamemode", FCVAR_PLUGIN|FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	cvarVersion = CreateConVar("xmultiplicator_version", PLUGIN_VERSION, "XMultiplicator Version", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD);
	HookConVarChange(cvarEnabled, CvarChange);
	RegAdminCmd("sm_rebuildtrie", Command_RebuildTrie, ADMFLAG_ROOT, "sm_rebuildtrie clears the previous config and rebuilds it");
	if(g_bLateLoad)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				UpdateWeapon(i);
			}
		}
	}
}
public OnAllPluginsLoaded()
{
	g_bSteamTools = LibraryExists("SteamTools");
}
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("Steam_SetGameDescription");
	g_bLateLoad = late;
}
public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == cvarEnabled)
	{
		for(new i = 1;i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				UpdateWeapon(i);
			}
		}
	}
}
public OnConfigsExecuted()
{	
	if(g_bSteamTools && GetConVarBool(cvarEnabled))
	{
		new String:gamemode[64];
		Format(gamemode, sizeof(gamemode), "[TF2] XMultiplicator(%s)", PLUGIN_VERSION);
		Steam_SetGameDescription(gamemode);
	}
}
public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}
public Action:Command_RebuildTrie(client, args)
{
	if(client < 0 || client > MaxClients || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	if(hItemInfoTrie != INVALID_HANDLE)
	{
		ClearTrie(hItemInfoTrie);
		CreateItemInfoTrie();
		PrintToChat(client, "Rebuilding Item Config");
	}
	return Plugin_Handled;
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
			new meleeindex = (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"));
			if(meleeindex == 356)
			{
				SetEntProp(attacker, Prop_Data, "m_iHealth", 1800);
				SetEntProp(attacker, Prop_Send, "m_iHealth", 1800);
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
		new Handle:itemOverride=PrepareItemHandle(iItemDefinitionIndex);
		if(itemOverride != INVALID_HANDLE)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	//since idk how to cover the wearable weapons(GunBoats etc) along with the weapons in one statement have to do it this way for now
	switch(iItemDefinitionIndex)
	{
		case 131,406,1099,57,231,642,405,608,444,133:
		{
			new Handle:itemOverride=PrepareItemHandle(iItemDefinitionIndex);
			if(itemOverride != INVALID_HANDLE)
			{
				item=itemOverride;
				return Plugin_Changed;
			}
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
	new String:formatBuffer[32];
	Format(formatBuffer, 32, "%d_%s", weaponLookupIndex, "attribs");
	new String:weaponAttribs[256];
	GetTrieString(hItemInfoTrie, formatBuffer, weaponAttribs, 256);
	new String:weaponAttribsArray[32][32];
	new attribCount;
	if(weaponAttribs[0] != '\0')
	{
		attribCount = ExplodeString(weaponAttribs, " ; ", weaponAttribsArray, 32, 32);
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
	else
	{
		return INVALID_HANDLE;
	}
}
//stock from unusual effects plugin 
UpdateWeapon(iClient)
{
	new TFClassType:Class = TF2_GetPlayerClass(iClient);
	new SlotMax;
	if(Class == TFClassType:8)
		SlotMax = 4;
	else if(Class == TFClassType:9)
		SlotMax = 5;
	else
		SlotMax = 2;
		
	for(new i = 0; i<= SlotMax; i++)
		TF2_RemoveWeaponSlot(iClient,i);

	TF2_RegeneratePlayer(iClient);
}