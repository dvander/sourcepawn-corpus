#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = 
{
	
	name = "TF2 Spy Disguised Speed",
	
	author = "Tylerst",

	description = "Make Spys the same speed as their disguised class",

	version = PLUGIN_VERSION,
	
	url = "None"

};



new Handle:enabled = INVALID_HANDLE;
new Float:basespeed[10] = {0.0, 400.0, 300.0, 240.0, 280.0, 320.0, 230.0, 300.0, 300.0, 300.0};

public OnPluginStart()
{
	CreateConVar("sm_sds_version", PLUGIN_VERSION, "Make Spys the same speed as their disguised class", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);	
	enabled = CreateConVar("sm_sds_enabled", "1", "Enable/Disable Plugin");
}

public OnGameFrame()

{
	if(enabled)
	{
		for (new i = 1; i <= MaxClients; i++)
		
		{

			if (!IsClientInGame(i) || !IsPlayerAlive(i))
 return;
			new TFClassType:class = TF2_GetPlayerClass(i);
			if(class == TFClass_Spy && (TF2_GetPlayerConditionFlags(i)&TF_CONDFLAG_DISGUISED))		
			{
				new TFClassType:dclass = TFClassType:GetEntProp(i, Prop_Send, "m_nDisguiseClass");
				new Float:dspeed = basespeed[dclass];
				SetEntDataFloat(i, FindSendPropInfo("CTFPlayer", "m_flMaxspeed"), dspeed);
			}
		}
				
	}
	
}
