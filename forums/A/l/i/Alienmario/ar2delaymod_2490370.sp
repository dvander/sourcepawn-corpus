#include <sourcemod>
#include <sdkhooks>

public void OnEntityCreated(int entity, const char[] classname)
{
	if(StrEqual(classname, "prop_combine_ball"))
	{
		SDKHook(entity, SDKHook_SpawnPost, OnSpawn);
	}
}

public void OnSpawn(int entity){
	int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	if(0 < owner <= MAXPLAYERS)
	{
		int weapon = GetEntPropEnt(owner, Prop_Data, "m_hActiveWeapon");
		char sWeapon[32]; GetEntityClassname(weapon, sWeapon, sizeof(sWeapon));
		if(StrEqual(sWeapon, "weapon_ar2"))
		{
			SetEntPropFloat(owner, Prop_Send, "m_flNextAttack", GetGameTime()+0.85);
			CreateTimer(0.0, SetDelay, EntIndexToEntRef(weapon));
		}
	}	
}

public Action SetDelay(Handle timer, any entref){
	int ent = EntRefToEntIndex(entref);
	if(IsValidEntity(ent))
	{
		SetEntPropFloat(ent, Prop_Send, "m_flNextSecondaryAttack", GetGameTime());
	}
}