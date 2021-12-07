/*
 *descriptions here
 */

new const String:PLUGIN_VERSION[60] = "1.0.2.13";

public Plugin:myinfo = {
	
	name = "RealisticReload",
	author = "javalia",
	description = "remove remaining bullets on magazine when reload for realistic reload",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
	
};

//uncomment if u wanna use function of these include file
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
//#include "vphysics"
//#include "stocklib"

//semicolon!!!!
#pragma semicolon 1

new bool:g_bReloadWithChamerBullet[2048];
new bool:g_bShotgun[2048];

public OnPluginStart(){

	CreateConVar("RealisticReload_version", PLUGIN_VERSION, "plugin info cvar", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	
}

public OnEntityCreated(entity, const String:classname[]){
	
	if(entity >= 0 && entity <= 2047){
	
		g_bReloadWithChamerBullet[entity] = false;
		
		if(StrEqual(classname, "weapon_shotgun_spas", false) || StrEqual(classname, "weapon_autoshotgun", false) || StrEqual(classname, "weapon_pumpshotgun", false) || StrEqual(classname, "weapon_chrome_shotgun", false)){
			
			g_bShotgun[entity] = true;
		
		}else{
		
			g_bShotgun[entity] = false;
		
		}
		
	}

}

public OnClientPutInServer(client){

	SDKHook(client, SDKHook_PreThink, PreThinkHook);

}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapontochange){

	if(IsPlayerAlive(client)){
			
		if(buttons & IN_RELOAD){
		
			new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			
			
				
				if(g_bShotgun[weapon]==false){
					
					new ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
					
					if(ammotype != -1){
					
						new reservedammo = GetEntProp(client, Prop_Send, "m_iAmmo", 4, ammotype);
						
						if(GetEntProp(weapon, Prop_Send, "m_iClip1") >= 1 && reservedammo >= 1){
						
							SetEntProp(weapon, Prop_Send, "m_iClip1", 1);//lets make our gun to reload.
							
						}
						
					}
					
				}
				
			
			
		}

	}
	
	return Plugin_Continue;

}

public PreThinkHook(client){
	
	if(IsPlayerAlive(client)){
	
		new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		
		if(weapon > 0){//this can looks odd cuz normaly programmers will intend to put != -1
		//but there was very odd bug that GetEntPropEnt returns some very low negative value.
		//i think that is problem that happend with bot. i hope so.
			
			if(GetEntProp(weapon, Prop_Send, "m_bInReload")){
				
				//in reloading, lets remove bullets on magazine.
				if(GetEntProp(weapon, Prop_Send, "m_iClip1") >= 1){
				
					SetEntProp(weapon, Prop_Send, "m_iClip1", 1);
					g_bReloadWithChamerBullet[weapon] = true;
				
				}else{
				
					g_bReloadWithChamerBullet[weapon] = false;
				
				}
				
			}else{
				
				//bullet has increased. it means reload has fully finished.
				if(g_bReloadWithChamerBullet[weapon] && GetEntProp(weapon, Prop_Send, "m_iClip1") > 1){
				
					new ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
					new reservedammo = GetEntProp(client, Prop_Send, "m_iAmmo", 4, ammotype);
					
					new gun = GetPlayerWeaponSlot(client, 0);
					new ammo = GetEntProp(gun, Prop_Send, "m_iClip1", 1);
					new ammo_override = ammo * 2;
					SetEntProp(gun, Prop_Send, "m_iClip1", ammo_override, 1);  
					
					if(reservedammo >= 1){
						
						SetEntProp(weapon, Prop_Send, "m_iClip1", GetEntProp(weapon, Prop_Send, "m_iClip1") + 1);
						new ammo = GetEntProp(weapon, Prop_Send, "m_iClip1", 1);
						new ammo_override = ammo + 1;
						SetEntProp(weapon, Prop_Send, "m_iClip1", ammo_override, 1);
						SetEntProp(client, Prop_Send, "m_iAmmo", reservedammo - 1, 4, ammotype);
						
					}
					
					g_bReloadWithChamerBullet[weapon] = false;
					
				}
			
			}
		
		}
		
	}

}