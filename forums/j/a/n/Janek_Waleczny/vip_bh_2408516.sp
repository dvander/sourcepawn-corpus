#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

#define PLUGIN_VERSION "1.5"

new Handle:hBhop;
new bool:BhopEnabled;

new Handle:hAutoBhop;
new bool:AutoBhopEnabled;

new bool:CSS = false;
new bool:CSGO = false;

#define WATER_LEVEL_FEET_IN_WATER   1

public Plugin:myinfo =
{
	name = "AutoBH for VIPs",
	author = "Janek",
	description = "Enables autoBH only for VIPs",
	version = PLUGIN_VERSION,
	url = "http://cs-serwer.pl"
}

stock Client_GetWaterLevel(client){
 
  return GetEntProp(client, Prop_Send, "m_nWaterLevel");
}

public OnPluginStart()
{       
	AutoExecConfig(true, "vipabh");
	CreateConVar("vbh_version", PLUGIN_VERSION, "Bhop Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	hBhop = CreateConVar("vbh_bhop", "1", "Enable/disable the bunny hopping");
	hAutoBhop = CreateConVar("vbh_autobhop", "1", "Enable/Disable the auto bunny hopping");
	
	HookConVarChange(hBhop, BhopChange);
	HookConVarChange(hAutoBhop, AutoBhopChange);

	BhopEnabled = GetConVarBool(hBhop);
	AutoBhopEnabled = GetConVarBool(hAutoBhop);
 
	decl String:theFolder[40];
	GetGameFolderName(theFolder, sizeof(theFolder));
	if(StrEqual(theFolder, "cstrike"))
	{
		CSS = true;
		CSGO = false;
	}
	else if(StrEqual(theFolder, "csgo"))
	{
		CSS = false;
		CSGO = true;
	}
	
	if (BhopEnabled)
	{
		BhopOn();
	}
	else
	{
		BhopOff();
	}

}

BhopOff()
{
	if(CSS)
	{
		SetCvar("sv_enablebunnyhopping", "0");
		SetCvar("sv_airaccelerate", "10");
		BhopEnabled = GetConVarBool(hBhop);
		PrintToServer("Bunny Hopping OFF");
	}

	else if(CSGO)
	{
		SetCvar("sv_enablebunnyhopping", "0"); 
		SetCvar("sv_staminamax", "80");
		SetCvar("sv_airaccelerate", "10");
		SetCvar("sv_staminajumpcost", ".1");
		SetCvar("sv_staminalandcost", ".1");
		BhopEnabled = GetConVarBool(hBhop);
		PrintToServer("Bunny Hopping OFF");
	}
}

BhopOn()
{
	if(CSS)
	{
		SetCvar("sv_enablebunnyhopping", "1");
		SetCvar("sv_airaccelerate", "2000");
		BhopEnabled = GetConVarBool(hBhop);
		PrintToServer("Bunny Hopping ON");
	}

	else if(CSGO)
	{
		SetCvar("sv_enablebunnyhopping", "1"); 
		SetCvar("sv_staminamax", "0");
		SetCvar("sv_airaccelerate", "2000");
		SetCvar("sv_staminajumpcost", "0");
		SetCvar("sv_staminalandcost", "0");
		BhopEnabled = GetConVarBool(hBhop);
		PrintToServer("Bunny Hopping ON");
	}
}


stock SetCvar(String:scvar[], String:svalue[])
{
	new Handle:cvar = FindConVar(scvar);
	SetConVarString(cvar, svalue, true);
}


public BhopChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{       
	if (StringToInt(oldVal) == 1 && StringToInt(newVal) == 0)
	{
		BhopOff();
	}

	if (StringToInt(oldVal) == 0 && StringToInt(newVal) == 1)
	{
		BhopOn();
	}
}

public AutoBhopChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{    
	AutoBhopEnabled = GetConVarBool(hAutoBhop);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	new index = GetEntProp(client, Prop_Data, "m_nWaterLevel");
	new water = EntIndexToEntRef(index);
	if (water != INVALID_ENT_REFERENCE)
	{
		if (IsPlayerAlive(client))
		{
			if (IsPlayerGenericAdmin(client))
			{
				if (buttons & IN_JUMP)
				{
					if (!(Client_GetWaterLevel(client) > WATER_LEVEL_FEET_IN_WATER))
					{
						if (!(GetEntityMoveType(client) & MOVETYPE_LADDER))
						{
							SetEntPropFloat(client, Prop_Send, "m_flStamina", 0.0);
							if (!(GetEntityFlags(client) & FL_ONGROUND))
							{
								if(BhopEnabled && AutoBhopEnabled)
								{
									buttons &= ~IN_JUMP;
								}
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

/*
@param client id

return bool
*/
bool:IsPlayerGenericAdmin(client)
{
	return CheckCommandAccess(client, "generic_admin", ADMFLAG_CUSTOM1, false);
}



