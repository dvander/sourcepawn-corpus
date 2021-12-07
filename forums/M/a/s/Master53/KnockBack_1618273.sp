
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

//Cvar Handle:
static Handle:CV_KNOCKBACKMULTIPLIER = INVALID_HANDLE;

//Misc:
static Float:KnockBack;

//Plugin Info:
public Plugin:myinfo = 
{
	name = "Any weapon Knockback",
	author = "MASTER(D)",
	description = "Players will get thrown back depending on the amount of damage",
	version = PLUGINVERSION,
	url = ""
};

//Initation:
public OnPluginStart()
{

	//Print Server If Plugin Start:
	PrintToConsole(0, "|SM| Knock Back Successfully Loaded (v%s)!", PLUGINVERSION);

	//ConVar Hooks:
	CV_KNOCKBACKMULTIPLIER = CreateConVar("sm_knock_back", "1.0", "enable/disable player connet announce default (1)");

	//Server Version:
	CreateConVar("sm_Knock_Back_version", PLUGINVERSION, "show the version of the zombie mod", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);

	//Create Auto Configurate File:
	AutoExecConfig(true, "Knock_Back");

	//Hook Cvar:
	HookConVarChange(CV_KNOCKBACKMULTIPLIER, KnockBackChanged);

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
			if(Client > 0 && IsClientConnected(Client) && IsClientInGame(Client) && IsSDKHook)
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

//Map Start:
public OnMapStart()
{

	//Set Values:
	KnockBack = GetConVarFloat(CV_KNOCKBACKMULTIPLIER);
}

//Max
public KnockBackChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{

	//Initulize:
	KnockBack = StringToFloat(newValue);
}

//public OnClientPutInServer(Client)
public OnClientPostAdminCheck(Client)
{

	//Connected:
	if(Client > 0 && IsClientConnected(Client) && IsSDKHook)
	{

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

		//Create Knock Back:
		InstantKnockBack(Client, attacker, damage);
	}

	//Return:
	return Plugin_Continue;
}

stock Float:CreateKnockBack(Client, attacker, Float:damage)
{

	//Delare:
  	decl Float:EyeAngles[3],Float:Push[3];

	//Initialize:
  	GetClientEyeAngles(Client, EyeAngles);

	Push[0] = (FloatMul(damage - damage - damage, Cosine(DegToRad(EyeAngles[1]))));

    	Push[1] = (FloatMul(damage - damage - damage, Sine(DegToRad(EyeAngles[1]))));

    	Push[2] = (FloatMul(-50.0, Sine(DegToRad(EyeAngles[0]))));

	//Multiply
	ScaleVector(Push, KnockBack);

	//Teleport:
    	TeleportEntity(Client, NULL_VECTOR, NULL_VECTOR, Push);
}

public Action:InstantKnockBack(Client, attacker, Float:damage)
{

	//Initulize:
	CreateKnockBack(Client, attacker, damage);

	//Return:
	return Plugin_Continue;
} 
