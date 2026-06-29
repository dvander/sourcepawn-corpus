#pragma semicolon 1 

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
bool isMapRunning;
public Plugin myinfo = 
{
	name = "The Witch turn back when melee bug",
	author = "Hoangzp",
	description = "",
	version = "0.96",
	url = ""
};

public void OnMapStart()
{
	isMapRunning = true;
	for(int i = 1; i <= GetEntityCount(); i++)
	{
		if(IsValidEdict(i) && IsValidEntity(i) )
		{
			if(IsValidWitch(i))
			{
			SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}
	
	}	
}
public void OnMapEnd(){
isMapRunning = false;
}
public void OnEntityCreated(int entity)
{
	if (!isMapRunning || IsServerProcessing() == false) return;
	if(entity == INVALID_ENT_REFERENCE || !IsValidEntity(entity) || !IsValidEdict(entity))
		{
			return ;
		}
	if(IsValidWitch(entity))	
	{
	SDKUnhook(entity, SDKHook_OnTakeDamage, OnTakeDamage);	
	SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);//SDKHook_TraceAttack SDKHook_OnTakeDamage
	}
}
public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if( weapon == -1){
		return Plugin_Continue;
	}
	if(attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker) && GetEntProp(attacker, Prop_Send, "m_zombieClass") == 9 ){
	if(weapon != -1)
	{
		char Weaponclassname[128];
		GetEdictClassname(weapon, Weaponclassname, sizeof(Weaponclassname));
		if(StrEqual(Weaponclassname, "weapon_melee") && IsValidWitch(victim)){
			float Toadosur[3],Toadowitch[3],fFinalPos[3],fFinalwitch[3];
			GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", Toadosur);
			GetEntPropVector(victim, Prop_Send, "m_vecOrigin", Toadowitch);
			MakeVectorFromPoints(Toadowitch, Toadosur, fFinalPos);
			GetVectorAngles(fFinalPos, fFinalwitch);
			fFinalwitch[0] = 0.0;
			SetEntPropVector(victim, Prop_Send, "m_angRotation", fFinalwitch);
			}
		}
	}
	return Plugin_Continue;
}

stock IsValidWitch(common)
{
	if(common > MaxClients && IsValidEdict(common) && IsValidEntity(common))
	{
		char classname[32];
		GetEdictClassname(common, classname, sizeof(classname));
		if(StrEqual(classname, "witch"))
		{
			return true;
		}
	}
	
	return false;
}