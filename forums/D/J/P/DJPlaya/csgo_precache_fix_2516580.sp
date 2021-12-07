#define PLUGIN_VERSION "1.2"

#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name = "CS:GO Material Precache Fix",
	author = "Playa",
	description = "Creates Particle Entitys on Map start to prevent a Player Crash Issue",
	version = PLUGIN_VERSION,
	url = "FunForBattle"
};

public void OnMapStart()
{
	//int lightdynamic = CreateEntityByName("env_lightdynamic");

	int particlesmokegrenade = CreateEntityByName("env_particlesmokegrenade"); //No usefull Key Values?
	DispatchSpawn(particlesmokegrenade);
	ActivateEntity(particlesmokegrenade);
	
	int smokestack = CreateEntityByName("env_smokestack");
	DispatchKeyValue(smokestack, "InitialState", "1");
	DispatchKeyValue(smokestack, "SmokeMaterial", "");
	DispatchSpawn(smokestack);
	ActivateEntity(smokestack);
				
	int steam = CreateEntityByName("env_steam");
	DispatchKeyValue(steam, "InitialState", "1");
	DispatchKeyValue(steam, "Rate", "0");
	DispatchSpawn(steam);
	ActivateEntity(steam);
}