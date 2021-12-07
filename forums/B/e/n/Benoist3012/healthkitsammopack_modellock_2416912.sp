#include <sourcemod>
#include <sdkhooks>

#define PLUGIN_VERSION "0.0.2"

#define TFModel_Normal 0
#define TFModel_Pyrovision 1
#define TFModel_Halloween 2
#define TFModel_Birthday 3


public Plugin myinfo = 
{
    name = "[TF2] HealthKits/AmmoPacks model lock",
    author	= "Benoist3012",
    description	= "Block health kits and ammo packs from changing their model in pyrovision/halloween mode",
    version = PLUGIN_VERSION,
    url = "http://steamcommunity.com/id/Benoist3012/"
}

public void OnPluginStart()
{
	CreateConVar("healthkitammopack_model_lock", PLUGIN_VERSION, "The current version of plugin. DO NOT TOUCH!", FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD);
}

public void OnEntityCreated(int iEntity, const char[] classname)
{
	if(strncmp(classname, "item_healthkit_", 15) == 0 || strncmp(classname, "item_ammopack_", 14) == 0)
	{
		RequestFrame(NextFrame_PickupModelOverride, EntIndexToEntRef(iEntity));
	}
}

void NextFrame_PickupModelOverride(int iRef)
{
	int iPickup = EntRefToEntIndex(iRef);
	if(iPickup > MaxClients)
	{
		//Grab the model index in normal vision
		int index = GetEntProp(iPickup, Prop_Send, "m_nModelIndexOverrides",_,TFModel_Normal);
		//Override it for every vision
		SetEntProp(iPickup, Prop_Send, "m_nModelIndexOverrides",index,_,TFModel_Normal);
		SetEntProp(iPickup, Prop_Send, "m_nModelIndexOverrides",index,_,TFModel_Pyrovision);
		SetEntProp(iPickup, Prop_Send, "m_nModelIndexOverrides",index,_,TFModel_Halloween);
		//It seems unused unless it's birthday vision?
		SetEntProp(iPickup, Prop_Send, "m_nModelIndexOverrides",index,_,TFModel_Birthday);
	}
}