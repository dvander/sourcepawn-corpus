
/********************************************
*
* Tick 100 Map Fix Version "1.4.37"
*
* Description:
* This plugin fixes maps which are made only for tick 66 servers to
* work under tick 100 servers.
*
*
* What it does:
* On a map start this plugin searches for all func_doors and prop_door_rotating and removes
* the damage and makes them 5% faster to open.
*
*
* Note:
* Developed for HL2:DM but should work with all mods.
*
* Install:
* Put the tick100mapfix.smx into your plugins folder there is no need
* to config anything, but you can change the
* sm_doorspeed (default: 1.05 - means the plugin makes all doors 5% faster).
*
*
* Dependencies:
* none
*
*
* Changelog:
* v1.4.37 - Lite version for Left 4 Dead/2
*		  - Compiled with sourcemod 1.9.0
*
* v1.4.36 - Fixed an error with the datamap value m_bForceClosed which does not exist for func_movelinear.
*         - Fixed a rare error where not cleared variables could mess up some entitys after mapchange.
* 
* v1.4.35 - Rewrite of some functions to improve them
*         - Added a config file see: cfg/sourcemod/tick100mapfix
* 
* v1.3.30 - Changed default sm_doorspeed back to 1.05 since 1.44 does not bring better results
* 
* v1.3.25 - Now the plugin can differ between func_doors as elevator and as normal door
*         - Added support for prop_door_rotating
*         - Normal func_door's (not elevators) and prop_door_rotating's are double as fast as elevators
* 
* v1.2.14 - Code improvement/fix
*         - better support/savely for the convar change on map start
*         - check the tickrate if its not 100 fail plugin load with errmsg
*         - changed standard speed to +44% instead of +5% (since we need 44 ticks from 66 to 100)
*         - On plugin end all doors get their normal speed back
*
* v1.0.4  - Added Convar
* 
* v1.0.3  - Code improvement/fix
* 
* v1.0.0  - First Public Release
*
*
* Thank you Berni, Manni, Mannis FUN House Community and SourceMod/AlliedModders-Team
*
*
* *************************************************/

/****************************************************************
P R E C O M P I L E R   D E F I N I T I O N S
*****************************************************************/

// enforce semicolons after each code statement

#pragma semicolon 1
#pragma newdecls required

/****************************************************************
I N C L U D E S
*****************************************************************/

#include <sourcemod>
#include <sdktools>

/****************************************************************
P L U G I N   C O N S T A N T S
*****************************************************************/

#define PLUGIN_VERSION	"1.4.37"
#define PLUGIN_NAME "Tick 100 Map Fix"
#define MAX_ENTITYS 2048
#define DEFAULT_SPEED "1.05"
#define DEFAULT_SPEED_NOELV "2.00"
#define DEFAULT_SPEED_PROP "2.00"

ConVar tick100mapfix_version, cvar_Speed, cvar_SpeedNoElv, cvar_SpeedProp, cvar_enable;

float doorspeed[MAX_ENTITYS], doordamage[MAX_ENTITYS];

bool doorforceclosed[MAX_ENTITYS] = false, isGetSettingsDone = false;

char doorlist[][32] = 
{
	
	"func_door",
	"func_door_rotating",
	"func_movelinear",
	"prop_door",
	"prop_door_rotating",
	"\0"
};

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = "Chanz [Edited by Dosergen]",
	description = "This plugin fixes maps which are made only for tick 66 servers to work under tick 100 servers",
	version = PLUGIN_VERSION,
	url = "www.mannisfunhouse.eu"
}

public void OnPluginStart(){
	
	PrintToServer("[%s] Loading plugin...",PLUGIN_NAME);
	
	cvar_enable = CreateConVar("sm_tick100mapfix_enable", "1", "Switches the mapfix on and off (1=on/0=off)", 0);
	cvar_Speed = CreateConVar("sm_doorspeed", DEFAULT_SPEED, "Sets the speed of func_door elevators on the map (default=1.05 means orginalspeed+5%", 0);
	cvar_SpeedNoElv = CreateConVar("sm_doorspeed_noelevator", DEFAULT_SPEED_NOELV, "Sets the speed of func_doors that are not elevators on the map (default=2.00 means orginalspeed+100%", 0);
	cvar_SpeedProp = CreateConVar("sm_doorspeed_prop", DEFAULT_SPEED_PROP, "Sets the speed of prop_doors on the map (default=2.00 means orginalspeed+100%", 0);
	tick100mapfix_version = CreateConVar("sm_tick100mapfix_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	AutoExecConfig(true, "tick100mapfix");
	
	HookConVarChange(cvar_enable,CvarEnableHook);
	HookConVarChange(cvar_Speed,CvarSpeedHook);
	HookConVarChange(cvar_SpeedNoElv,CvarSpeedHook);
	HookConVarChange(cvar_SpeedProp,CvarSpeedHook);
	
	HookEvent("round_start",Event_Round_Start,EventHookMode_Post);

}

public void OnPluginEnd()
{
	
	PrintToServer("[%s] Unloading plugin...",PLUGIN_NAME);
	ResetDoorSettingsAll();
}

public void OnConfigsExecuted()
{
	
	SetConVarString(tick100mapfix_version, PLUGIN_VERSION);		
}
	
public void OnMapStart() 
{

	CreateTimer(1.0, Timer_OnMapStart_Delayed);
}

public Action Timer_OnMapStart_Delayed(Handle timer) 
{
	
//	GetDoorSettingsAll();
//	SetDoorSettingsAll();
}

public Action Event_Round_Start(Event event, const char[] name, bool dontBroadcast)
{

	ResetDoorSettingsAll();
	GetDoorSettingsAll();
	SetDoorSettingsAll();
}

public void OnMapEnd()
{
	
	isGetSettingsDone = false;
	
	for(int entity=0;entity<MAX_ENTITYS;entity++)
	{
		doorspeed[entity] = 0.0;
		doordamage[entity] = 0.0;
		doorforceclosed[entity] = false;
	}
}

void Addoutput(int entity, char[]output) 
{
	SetVariantString(output);
	AcceptEntityInput(entity, "addoutput");
}

void SetDoorSettingsAll()
{
	
	if(GetConVarBool(cvar_enable))
	{
		
		int i=0;
		int j=0;
		int ent = -1;
		
		while (!StrEqual(doorlist[j],"\0",false))
		{
			
			while ((ent = FindEntityByClassname(ent, doorlist[j])) != -1)
			{
				
				ApplyDoorSettings(ent,doorlist[j]);
				i++;
			}
			
			ent = -1;
			j++;
		}
		
		PrintToServer("[%s] Affected %i doors",PLUGIN_NAME,i);
	}
}

void ApplyDoorSettings(int ent, char[] classname)
{
	
	if(StrContains(classname,"prop",false) == -1)
	{
		
		float m_vecMoveDir[3];
		GetEntPropVector(ent,Prop_Data,"m_vecMoveDir",m_vecMoveDir);
		
		if(m_vecMoveDir[2] == 1.0){
			
			SetDoorSettings(ent,true,0.0,doorspeed[ent]*GetConVarFloat(cvar_Speed),classname);
			
		}
		else 
		{
			
			SetDoorSettings(ent,true,0.0,doorspeed[ent]*GetConVarFloat(cvar_SpeedNoElv),classname);
		}
	}
	else 
	{
		
		SetDoorSettings(ent,true,0.0,doorspeed[ent]*GetConVarFloat(cvar_SpeedProp),classname);
	}
}

void SetDoorSettings(int ent, bool forceclosed, float damage, float speed, char[] classname)
{
	
	char buffer[32];
	
	if(!StrEqual(classname,"func_movelinear",false))
	{
		Format(buffer, sizeof(buffer), "forceclosed %d",forceclosed);
		Addoutput(ent, buffer);
	}
	
	if(StrContains(classname,"prop",false) == -1)
	{
		
		Format(buffer, sizeof(buffer), "dmg %fl",damage);
		Addoutput(ent, buffer);
	}
	
	if(speed != 0.0){
		Format(buffer, sizeof(buffer), "speed %fl",speed);
		Addoutput(ent, buffer);
	}
	
	if(StrContains(classname,"prop",false) == -1)
	{
		PrintToServer("[%s] Set settings of a func_* door (%d): forceclosed: %d - damage: %f - speed: %f",PLUGIN_NAME,ent,forceclosed,damage,speed);
	}
	else 
	{
		PrintToServer("[%s] Set settings of a prop_* door (%d): forceclosed: %d - damage: %f - speed: %f",PLUGIN_NAME,ent,forceclosed,damage,speed);
	}
}

void ResetDoorSettingsAll()
{
	
	if(isGetSettingsDone)
	{
		
		int i=0;
		int j=0;
		int ent = -1;
		
		while (!StrEqual(doorlist[j],"\0",false))
		{
			
			while ((ent = FindEntityByClassname(ent, doorlist[j])) != -1)
			{
				SetDoorSettings(ent,doorforceclosed[ent],doordamage[ent],doorspeed[ent],doorlist[j]);
				i++;
			}
			
			ent = -1;
			j++;
		}
		
		PrintToServer("[%s] Affected %i doors",PLUGIN_NAME,i);
	}
}

void GetDoorSettingsAll()
{
	
	if(GetConVarBool(cvar_enable))
	{
		
		int ent = -1;
		int j=0;
		
		while (!StrEqual(doorlist[j],"\0",false))
		{
			
			while ((ent = FindEntityByClassname(ent, doorlist[j])) != -1)
			{
				GetDoorSettings(ent,doorlist[j]);
			}
			
			ent = -1;
			j++;
		}
		
		isGetSettingsDone = true;
	}
}

void GetDoorSettings(int ent, char[] classname)
{
	
	if(StrContains(classname,"prop",false) == -1)
	{
		doordamage[ent] = GetEntPropFloat(ent, Prop_Data, "m_flBlockDamage");
	}
	
	if(!StrEqual(classname,"func_movelinear",false))
	{
		doorforceclosed[ent] = view_as<bool>(GetEntProp(ent,Prop_Data,"m_bForceClosed"));
	}
	
	doorspeed[ent] = GetEntPropFloat(ent, Prop_Data, "m_flSpeed");
	
	if(StrContains(classname,"prop",false) == -1){
		PrintToServer("[%s] Get settings of a func_* door (%d): forceclosed: %d - damage: %f - speed: %f",PLUGIN_NAME,ent,doorforceclosed[ent],doordamage[ent],doorspeed[ent]);
	}
	else 
	{
		PrintToServer("[%s] Get settings of a prop_* door (%d): forceclosed: %d - damage: %f - speed: %f",PLUGIN_NAME,ent,doorforceclosed[ent],doordamage[ent],doorspeed[ent]);
	}
}

public void CvarSpeedHook(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	
	if(isGetSettingsDone)
	{
		
		SetDoorSettingsAll();
	}
}

public void CvarEnableHook(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	
	if(StringToInt(newVal) == 0)
	{
		
		ResetDoorSettingsAll();
	}
	else 
	{
		
		GetDoorSettingsAll();
		SetDoorSettingsAll();
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error , int err_max) 
{
	
	if(((1.0/GetTickInterval()) < 90.0) || ((1.0/GetTickInterval()) > 110.0))
	{
		
		strcopy(error,err_max,"This server is not a tick 100 server. (put into your commandline: \"-tickrate 100\" without quotes)");
		return APLRes_SilentFailure;
	}
	
	return APLRes_Success;
}
