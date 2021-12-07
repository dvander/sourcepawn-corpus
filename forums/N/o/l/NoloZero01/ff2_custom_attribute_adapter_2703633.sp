/*
		Freak Fortress Custom Attribute Adapter for bosses. 
		
	THIS IS NOT A CUSTOM ATTRIBUTE. This exposes a convenient way of adding your own custom attributes 
	to weapons that bosses spawn with via their config files.
	Custom attribute management is provided by the "TF2 Custom Attributes" framework by nosoop: 
	https://github.com/nosoop/SM-TFCustAttr 
	Please read it's wiki:
	https://github.com/nosoop/SM-TFCustAttr/wiki/Applying-Custom-Attributes
	
	After you have installed all prerequisites and attributes you would like to use,
	you can open a boss configuration file and add your desired attributes in the following format:
////////////////////////////////////////////////////////////////////////////////////////////////////
	"weapon1"
	{	//Main settings
		"name"		"tf_weapon_sapper"
		"index"		"1080"
		"show"		"1"
		"attributes"	"425 ; 1.2 ; 428 ; 1.2"
		
		//Custom Attribute section
		"customattributes"
		{
			"sapper reprograms buildings" "sap_time=5.0 self_destruct_time=15.0"
		} 
	}
////////////////////////////////////////////////////////////////////////////////////////////////////
	If you wish to have debug information about applying custom attributes to be shown, please activate
	ff2_debug ConVar.

	Known issues:
	Any boss ability that removes the weapons that FF2 gives on spawn will remove the attributes completely,
	for example Christian Brutal Sniper's multimelee ability. 
*/
#include <sourcemod>
#define REQUIRE_PLUGIN
#include <freak_fortress_2>
#include <tf_custom_attributes>
#undef REQUIRE_PLUGIN
#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

ConVar ApplyDelay;

public Plugin myinfo =
{
	name = "[FF2] Boss Custom Attribute Adapter",
	author = "Nolo001",
	description = "Custom Attributes Adapter for Freak Fortress bosses",
	version = PLUGIN_VERSION
}

public void OnPluginStart()
{
	LogMessage("[FF2] Boss Custom Attribute Adapter initializing.");
	HookEvent("post_inventory_application", OnPostInventoryApplication, EventHookMode_Post);
	ApplyDelay = CreateConVar("ff2_custom_attribute_delay", "1.5", "Delay between boss spawning in and attributes applying. Please do not set below 1.", _, true, 1.0);
}

public void OnAllPluginsLoaded() //Don't think this will ever happen, but just to make sure
{
    if(GetFeatureStatus(FeatureType_Native, "FF2_GetSpecialKV") != FeatureStatus_Available)
		SetFailState("Your Freak Fortress 2 does not support \"FF2_GetSpecialKV\"! Please update to a more up to date version.");
}

public void OnPostInventoryApplication(Event event, const char[] name, bool NoBroadcast)
{
	if(!FF2_IsFF2Enabled())
		return;
		
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!IsValidClient(client))
		return;
			//Sanity checks to make sure we work with a valid boss
	int boss = FF2_GetBossIndex(client);
	if(boss == -1)
		return;
		
	CreateTimer(ApplyDelay.FloatValue, Timer_CheckForCustomAttributes, client, TIMER_FLAG_NO_MAPCHANGE); //Timer to make sure FF2 does it's thing before us'
}

public Action Timer_CheckForCustomAttributes(Handle timer, int client)
{
	if(!IsValidClient(client)) 
		return Plugin_Continue;
								//Sanity checks to make sure we still work with a valid boss
	int boss = FF2_GetBossIndex(client);
	if(boss == -1)
		return Plugin_Continue;
		
	int weapons[12]; 
	for(int s = 0; s <= 8; s++)
	{ // Get all boss weapons from valid slots into an array
		int weapon = GetPlayerWeaponSlot(client, s);
		weapons[s] = CheckWeaponValidity(weapon) ? weapon : -1;
	}	
	
	KeyValues BossConfig = view_as<KeyValues>(FF2_GetSpecialKV(boss, 0));
	if(BossConfig == null) 
	{
		FF2Dbg("Failed to parse boss config file. Not Possible!");// Don't think this is possible
		return Plugin_Continue;
	}
		
	char key[16];
	for(int i = 1; ; i++)
	{
		BossConfig.Rewind();
		FormatEx(key, sizeof(key), "weapon%i", i);
		if(BossConfig.JumpToKey(key, false)) //Loop through all existing weapons in config
		{
			int weaponindex = BossConfig.GetNum("index");
			for(int slot = 0; slot <= 8; slot++)
			{
				if(weapons[slot] == -1) //If weapon in slot does not exist for boss, skip
					continue;	

				if(GetEntProp(weapons[slot], Prop_Send, "m_iItemDefinitionIndex") == weaponindex)//If our weapon slot def. index matches with config one
				{ 
					if(BossConfig.JumpToKey("customattributes", false)) //If the weapon has custom attributes section
					{
							BossConfig.GotoFirstSubKey(false);//Loop through and apply each 
							do
							{
								char kvname[256], kvvalue[256];
								BossConfig.GetSectionName(kvname, sizeof(kvname));
								BossConfig.GetString(NULL_STRING, kvvalue, sizeof(kvvalue));
								if(FF2_Debug())
								{
									char name[128];
									FF2_GetBossSpecial(boss, name, sizeof(name), 0);
									FF2Dbg("[Custom Attributes] [Boss %s]: [Name: \"%s\"], [Value: \"%s:\"]", name, kvname, kvvalue);
								}		
								TF2CustAttr_SetString(weapons[slot], kvname, kvvalue);
							}
							while(BossConfig.GotoNextKey(false));
					}	
				}
			}	
		}
		else
		{
			break;
		}
	}
	return Plugin_Continue;
}

stock bool CheckWeaponValidity(int entity)
{
	if(entity<=MaxClients || !IsValidEntity(entity) || !HasEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"))
		return false;
		
	return true;
}

stock bool IsValidClient(int client, bool replaycheck=true)
{
	if(client<=0 || client>MaxClients)
	{
		return false;
	}

	if(!IsClientInGame(client))
	{
		return false;
	}

	if(replaycheck)
	{
		if(IsClientSourceTV(client) || IsClientReplay(client))
		{
			return false;
		}
	}
	return true;
}