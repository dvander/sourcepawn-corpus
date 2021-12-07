#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <tf2items>
#include <tf2items_giveweapon>

new Handle:g_HP_scout;
new Handle:g_HP_soldier;
new Handle:g_HP_pyro;
new Handle:g_HP_demo;
new Handle:g_HP_heavy;
new Handle:g_HP_engi;
new Handle:g_HP_medic;
new Handle:g_HP_sniper;
new Handle:g_HP_spy;

new done[MAXPLAYERS+1];

new Float:MaxHealth;

public Plugin:myinfo =  
{  
	name = "Default HP manager",  
	author = "Arkarr",  
	description = "Allow to change default HP of player.",  
	version = "1.0",  
	url = "http://www.sourcemod.net/"  
}; 


public OnPluginStart()  
{
	g_HP_scout = CreateConVar("default_HP_scout","100","A scout should spawn with how much HP ?");
	g_HP_soldier = CreateConVar("default_HP_soldier","100","A soldier should spawn with how much HP ?");
	g_HP_pyro = CreateConVar("default_HP_pyro","100","A pyro should spawn with how much HP ?");
	g_HP_demo = CreateConVar("defaultHP_demo","100","A demo should spawn with how much HP ?");
	g_HP_heavy = CreateConVar("defaultHP_heavy","100","A heavy should spawn with how much HP ?");
	g_HP_engi = CreateConVar("defaultHP_engi","100","A engi should spawn with how much HP ?");
	g_HP_medic = CreateConVar("defaultHP_medic","100","A medic should spawn with how much HP ?");
	g_HP_sniper = CreateConVar("defaultHP_sniper","100","A sniper should spawn with how much HP ?");
	g_HP_spy = CreateConVar("defaultHP_spy","100","A spy should spawn with how much HP ?");
	
	AutoExecConfig(true,"TF2_HP_Manager");
	
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre)
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	done[client] = 0;
}

public Action:TF2Items_OnGiveNamedItem(client, String:classname[], iItemDefinitionIndex, &Handle:hItem)
{
	if(client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && done[client] == 0)
	{		
		new TFClassType:class = TF2_GetPlayerClass(client);
		
		hItem = TF2Items_CreateItem(OVERRIDE_ATTRIBUTES|PRESERVE_ATTRIBUTES);
		
		if(class == TFClass_DemoMan)
		{
			MaxHealth = GetConVarFloat(g_HP_demo);
		}
		else if(class == TFClass_Sniper)
		{
			MaxHealth = GetConVarFloat(g_HP_sniper);
		}
		else if(class == TFClass_Scout)
		{
			MaxHealth = GetConVarFloat(g_HP_scout);
		}
		else if(class == TFClass_Spy)
		{
			MaxHealth = GetConVarFloat(g_HP_spy);
		}
		else if(class == TFClass_Heavy)
		{
			MaxHealth = GetConVarFloat(g_HP_heavy);
		}
		else if(class == TFClass_Soldier)
		{
			MaxHealth = GetConVarFloat(g_HP_soldier);
		}
		else if(class == TFClass_Pyro)
		{
			MaxHealth = GetConVarFloat(g_HP_pyro);
		}	
		else if(class == TFClass_Engineer)
		{
			MaxHealth = GetConVarFloat(g_HP_engi);
		}	
		else if(class == TFClass_Medic)
		{
			MaxHealth = GetConVarFloat(g_HP_medic);
		}
		
		TF2Items_SetAttribute(hItem, 0, 26, MaxHealth);
		TF2Items_SetClassname(hItem, classname);
		TF2Items_SetNumAttributes(hItem, 1);
		TF2Items_GiveNamedItem(client, hItem);
		
		done[client] = 1;
		
		return Plugin_Changed;	
	}
	else
	{
		return Plugin_Continue;
	}
}
