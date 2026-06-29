#include <sourcemod>
#include <sdkhooks>

#define PLUGIN_VERSION "1.00"
public Plugin:myinfo = 
	{
	name = "Zero Ammo",
  author      = "Invex | Byte",
	description = "Set the ammo of every gun to 0.",
	version = PLUGIN_VERSION,
	url = "http://www.invexgaming.com.au"
};

public OnPluginStart()
{
  //Event hook
  HookEvent("item_purchase", Item_Purchased);
}

public OnClientPutInServer(client)
{
  if(!IsFakeClient(client)) {
    SDKHook(client, SDKHook_WeaponEquipPost, SetZeroAmmo);
    SDKHook(client, SDKHook_WeaponCanSwitchToPost, SetZeroAmmo);
  }
}

/*
* Strip ammo on item purchased
*/
public Item_Purchased(Handle:event, const String:name[], bool:dontBroadcast)
{
  //Get event vars
  new client = GetClientOfUserId(GetEventInt(event, "userid"));
  new weapon =  GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");

  SetZeroAmmo(client, weapon);
}

/*
* Strip ammo on guns
*/
public Action:SetZeroAmmo(client, weapon)
{ 
  if (IsValidEntity(weapon)) {
    //Primary ammo
    SetReserveAmmo(client, weapon, 0);
    
    //Clip
    SetClipAmmo(client, weapon, 0);
  }
}


stock SetReserveAmmo(client, weapon, ammo)
{
  SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", ammo); //set reserve to 0
    
  new ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
  if(ammotype == -1) return;
  
  SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, ammotype);
}


stock SetClipAmmo(client, weapon, ammo)
{
  SetEntProp(weapon, Prop_Send, "m_iClip1", ammo);
  SetEntProp(weapon, Prop_Send, "m_iClip2", ammo);
}