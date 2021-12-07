#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>


#define PLUGIN_NAME		 	"Weather"
#define PLUGIN_AUTHOR	   	"Erreur 500"
#define PLUGIN_DESCRIPTION	"Control map weather"
#define PLUGIN_VERSION	  	"1.0"
#define PLUGIN_CONTACT	  	"erreur500@hotmail.fr"

new Handle:c_density;

public Plugin:myinfo =
{
	name		= PLUGIN_NAME,
	author	  	= PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version	 	= PLUGIN_VERSION,
	url		 	= PLUGIN_CONTACT
};

public OnPluginStart()
{
	CreateConVar("weather_version", PLUGIN_VERSION, "weather version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	c_density = CreateConVar("weather_density", "255", "Density of the precipitation", FCVAR_PLUGIN, true, 1.0, true, 255.0);
	
	RegAdminCmd("weather", ConsoleCmdWeather, ADMFLAG_GENERIC);
}


/*************************************************************************************
*						WEATHER CONTROL
**************************************************************************************/


public Action:ConsoleCmdWeather(client, Args)
{
	if(!IsValidClient(client)) return;
	
	new Handle:menu = CreateMenu(Menu_Weather_Ans);

	SetMenuTitle(menu, "Select a sky:");

	AddMenuItem(menu, "0", "Normal");
	AddMenuItem(menu, "1", "Rain ");
	AddMenuItem(menu, "3", "Ash");

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public Menu_Weather_Ans(Handle:menu, MenuAction:action, client, args)
{
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if(action == MenuAction_Select)
	{
		new entity = -1;
		while( (entity = FindEntityByClassname(entity, "func_precipitation")) != INVALID_ENT_REFERENCE )
		{
			AcceptEntityInput(entity, "Kill");
		}
		
		if(args != 0)
		{
			decl String:WeatherID[2];
			GetMenuItem(menu, args, WeatherID, sizeof(WeatherID));
			
			ChangeWeather(WeatherID);
		}
	}
}

ChangeWeather(String:WeatherID[2])
{
	new value, entity = -1;
	while( (entity = FindEntityByClassname(entity, "func_precipitation")) != INVALID_ENT_REFERENCE )
	{
		value = GetEntProp(entity, Prop_Data, "m_nPrecipType");
		if( value < 0 || value == 4 || value > 5 )
			AcceptEntityInput(entity, "Kill");
	}
	
	decl String:Density[8];
	GetConVarString(c_density, Density, sizeof(Density));
	
	entity = CreateEntityByName("func_precipitation");
	if( entity != -1 )
	{
		decl String:buffer[128];
		GetCurrentMap(buffer, sizeof(buffer));
		Format(buffer, sizeof(buffer), "maps/%s.bsp", buffer);
		DispatchKeyValue(entity, "model", buffer);
		DispatchKeyValue(entity, "targetname", "silver_rain");
		DispatchKeyValue(entity, "preciptype", WeatherID);
		DispatchKeyValue(entity, "renderamt", Density);
		DispatchKeyValue(entity, "minSpeed", "25");
		DispatchKeyValue(entity, "maxSpeed", "35");

		new Float:vMins[3], Float:vMaxs[3];
		GetEntPropVector(0, Prop_Data, "m_WorldMins", vMins);
		GetEntPropVector(0, Prop_Data, "m_WorldMaxs", vMaxs);
		SetEntPropVector(entity, Prop_Send, "m_vecMins", vMins);
		SetEntPropVector(entity, Prop_Send, "m_vecMaxs", vMaxs);
		
		decl Float:vBuff[3];
		vBuff[0] = vMins[0] + vMaxs[0];
		vBuff[1] = vMins[1] + vMaxs[1];
		vBuff[2] = vMins[2] + vMaxs[2];
		
		DispatchSpawn(entity);
		ActivateEntity(entity);
		TeleportEntity(entity, vBuff, NULL_VECTOR, NULL_VECTOR);
	}
	else
		LogError("Failed to create 'func_precipitation'");
}

stock bool:IsValidClient(iClient)
{
	if (iClient <= 0) return false;
	if (iClient > MaxClients) return false;
	return IsClientInGame(iClient);
}