/*
		Freak Fortress Custom Attribute Adapter 2.0 for bosses. 
		
	THIS IS NOT A CUSTOM ATTRIBUTE. This exposes a convenient way of adding your own custom attributes 
	to boss weapons via their config files. This version allows you to apply custom attributes to any weapon the boss can potentially have/get.
	Custom attribute management is provided by the "TF2 Custom Attributes" framework by nosoop: 
	https://github.com/nosoop/SM-TFCustAttr 
	Please read it's wiki:
	https://github.com/nosoop/SM-TFCustAttr/wiki/Applying-Custom-Attributes
	
	After you have installed all prerequisites and attributes you would like to use,
	you can open a boss configuration file and add the following structure to the root "characters" section(alongside weapons, abilities, etc) in the following format:
////////////////////////////////////////////////////////////////////////////////////////////////////
	"Custom Attributes"
	{
		"Weapon Index"
		{
			"custom attribute" "value"
			"custom attribute" "value"
			...
		}
		"Weapon Index"
		{
			"custom attribute" "value"
		}
		...
	}
////////////////////////////////////////////////////////////////////////////////////////////////////
	Replace Weapon Index with the weapon index you want to apply custom attributes to.
	If you wish to have notifications about applying custom attributes, please activate the
	ff2_debug ConVar.
	
*/
#include <sourcemod>
#define REQUIRE_PLUGIN
#include <freak_fortress_2>
#include <tf_custom_attributes>
#include <tf2items>
#undef REQUIRE_PLUGIN
#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION "2.0"

public Plugin myinfo =
{
	name = "[FF2] Boss Custom Attribute Adapter",
	author = "Nolo001",
	description = "Custom Attributes Adapter for Freak Fortress bosses",
	version = PLUGIN_VERSION
}

public void OnPluginStart()
{
	LogMessage("[FF2] Boss Custom Attribute Adapter 2.0 has loaded in.");
}

public void OnAllPluginsLoaded() //Don't think this will ever happen, but just to make sure
{
    if(GetFeatureStatus(FeatureType_Native, "FF2_GetSpecialKV") != FeatureStatus_Available) //what FF2 version would that even be
		SetFailState("Your Freak Fortress 2 does not support \"FF2_GetSpecialKV\"! Please update to a more up to date version.");
}

public void TF2Items_OnGiveNamedItem_Post(int client,  char[] classname, int index, int level, int quality, int entity) //for some reason TF2CustAttr_OnKeyValuesAdded wasn't working
{
	if(!IsValidEntity(entity)) //bad entity
		return;
		
	if(!IsValidClient(client))//bad client
		return;		

	int boss = FF2_GetBossIndex(client);		
	if(boss == -1)//not a boss
		return;
		
	if(!HasEntProp(entity, Prop_Send, "m_iItemDefinitionIndex")) //something without index
		return;

	
	KeyValues BossConfig = view_as<KeyValues>(FF2_GetSpecialKV(boss, 0));//get the handle to boss KV
	if(BossConfig == null)//this should not be scientifically possible
		return;
		
	BossConfig.Rewind();//lets begin
	if(!BossConfig.JumpToKey("Custom Attributes", false))
		return;//No custom attribute section for us. If it exists, the parser automatically jumps there
		
	char buffer[8];	
	IntToString(index, buffer, sizeof(buffer));//convert our item def index to a string because JumpToKey asks for a string
	if(!BossConfig.JumpToKey(buffer, false))
		return; //we don't want custom attributes on that weapon
		
	FF2Dbg("[CUSTOM ATTRIBUTE ADAPTER] Found custom attributes for weapon index %s. Applying now.", buffer);
	TF2CustAttr_UseKeyValues(entity, BossConfig); //there we go
	return;
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