/*
               █▓▓▄  █▌                        ╔▓         ▀▓▌                   
     █▄██▄▄▄  ╔▓▀▓▓▄▐▓  ▄▄A&▄▄▄ ▄▄▓▄M▓▓╗  ▄▄&A▓▓▌  ▄▄▀▀▓▄ '  ▄▓▓▀▀  ▄▄▄██▄█,    
  ▀▀████████  ▓▌ ▐█▓▓▌╒▓▓Ü  ▓▓▌  ▓▓▌ ▓▓▓ ▓▓  ▐▓▓  ▓▓▌  █▓▓  ,▐▀▓▓╕  ████████▀▀  
    ▀▀▀▀▀   ,▄█▄   ▓▓ "▀█▓▄Æ▓▓▀ ▄▓█ ,▓▀  ▀█▓▄▀██╝ ▀▓█▄▄▓▀  '▓▄▄█▀      ▀▀▀▀▀    
                                                                                
*/

#define PLUGIN_AUTHOR "vitaliy_valve"
#define PLUGIN_VERSION "0.1"

#include <sdkhooks>

#pragma newdecls required
#pragma semicolon 1

int iExtraCheekyNandos[] =  {
	42, 
	59, 
	500, 
	505, 
	506, 
	507, 
	508, 
	509, 
	512, 
	515, 
	516
};

public Plugin myinfo = 
{
	name = "Cheeky Nandos", 
	author = PLUGIN_AUTHOR, 
	description = "Blacklist Inc", 
	version = PLUGIN_VERSION, 
	url = "www.google.com"
};

public void OnPluginStart()
{
	if (GetEngineVersion() != Engine_CSGO) {
		SetFailState("This plugin is for CSGO/CSS only.");
	}
}

public void OnClientPostAdminCheck(int iCustomer)
{
	SDKHook(iCustomer, SDKHook_WeaponEquip, OnCheekyNandos);
}

public Action OnCheekyNandos(int iCustomer, int iCookedCheekyNando)
{
	if (!IsExtraCheeky(iCookedCheekyNando)) {
		return;
	}
	
	SetEntProp(iCookedCheekyNando, Prop_Send, "m_iItemDefinitionIndex", 516);
	SetEntProp(iCookedCheekyNando, Prop_Send, "m_iItemIDLow", -1);
	SetEntProp(iCookedCheekyNando, Prop_Send, "m_nFallbackPaintKit", 413);
	
	SetEntPropFloat(iCookedCheekyNando, Prop_Send, "m_flFallbackWear", 0.000001);
	
	PrintToChat(iCustomer, "Cheeky Nandos");
}

stock bool IsExtraCheeky(int iNando)
{
	int iNandoType = GetEntProp(iNando, Prop_Send, "m_iItemDefinitionIndex");
	
	for (int Nando; Nando < sizeof(iExtraCheekyNandos); Nando++) {
		if (iNandoType == iExtraCheekyNandos[Nando]) {
			return true;
		}
	}
	
	return false;
}