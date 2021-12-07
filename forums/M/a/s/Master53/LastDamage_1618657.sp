
//Included:
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

//Terminate:
#pragma semicolon		1
#pragma compress		0

//Definitions:
#define PLUGINVERSION "1.00.01"

//Miscs:
static bool:IsSDKHook;

//Misc:
static LastDamage[MAXPLAYERS + 1] = {0,...};

//Plugin Info:
public Plugin:myinfo = 
{
	name = "Any LastDamage",
	author = "MASTER(D)",
	description = "The last player who damaged a player will get the kill",
	version = PLUGINVERSION,
	url = ""
};

//Initation:
public OnPluginStart()
{

	//Print Server If Plugin Start:
	PrintToConsole(0, "|SM| Knock Back Successfully Loaded (v%s)!", PLUGINVERSION);

	//Server Version:
	CreateConVar("sm_Last_Damage_version", PLUGINVERSION, "show the version of the zombie mod", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);

	//Event Hooking:
	HookEvent("player_death", EventDeath_Forward);

	//Create Auto Configurate File:
	AutoExecConfig(true, "Knock_Back");

	//Hook:
	IsSDKHook = (GetExtensionFileStatus("sdkhooks.ext") == 1);
}

//Is Extension Loaded:
#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
#else
public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
#endif
{

	//Is SDKHOOKS Running
	if(IsSDKHook == true)
	{

		//Loop:
		for(new Client = 1; Client <= MaxClients; Client++)
		{

			//Connected:
			if(Client > 0 && IsClientConnected(Client) && IsClientInGame(Client))
			{

				//SDKHooks:
				SDKHook(Client, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}

		//Return:
		return APLRes_Success;
	}

	//Return:
	return APLRes_SilentFailure;
}

//SdkHooks:
public OnLibraryRemoved(const String:name[])
{

	//Is Extension Is Loaded:
	if(strcmp(name, "sdkhooks.ext") == 0)
	{

		//Print Fail State:
		IsSDKHook = false;
	}
}

//public OnClientPutInServer(Client)
public OnClientPostAdminCheck(Client)
{

	//Connected:
	if(Client > 0 && IsClientConnected(Client) && IsSDKHook)
	{

		//Initulize::
		LastDamage[Client] = 0;

		//SDKHooks:
		SDKHook(Client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

//Event Damage:
public Action:OnTakeDamage(Client, &attacker, &inflictor, &Float:damage, &damageType)
{

	//Is Player:
	if(attacker != Client && Client != 0 && attacker != 0 && Client > 0 && Client < MaxClients && attacker > 0 && attacker < MaxClients)
	{

		//Initulize:
		LastDamage[Client] = attacker;
	}

	//Return:
	return Plugin_Continue;
}

//EventDeath Farward:
public Action:EventDeath_Forward(Handle:Event, const String:name[], bool:dontBroadcast)
{

	//Get Id:
	new Client = GetClientOfUserId(GetEventInt(Event, "userid"));

	new Attacker = GetClientOfUserId(GetEventInt(Event, "attacker"));

	//Is Valid:
	if(Attacker < 1 && LastDamage[Client] != 0)
	{

		//Set Data:
		SetEventInt(Handle:Event, "attacker", LastDamage[Client]);

		//Switch Attacker:
		Attacker = LastDamage[Client];

		//Initulize:
		LastDamage[Client] = 0;
	}
}