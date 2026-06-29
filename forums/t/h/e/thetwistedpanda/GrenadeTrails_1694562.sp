#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1

new g_iSprite, g_iFlashColor[4], g_iGrenadeColor[4], g_iSmokeColor[4];
new Handle:g_hEnabled, Handle:g_hFlashColor, Handle:g_hGrenadeColor, Handle:g_hSmokeColor, Handle:g_hSprite;
new bool:g_bEnabled;
new String:g_sSprite[PLATFORM_MAX_PATH];

public Plugin:myinfo =
{
	name = "Grenade Trails",
	author = "Fredd",
	description = "Adds a trail to grenades.",
	version = "1.3",
	url = "www.sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("gt_version", "1.3", "Grenade Trails Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_hEnabled = CreateConVar("gt_enables", "1", "Enables/Disables Grenade Trails", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hEnabled, OnSettingsChange);
	g_hSprite = CreateConVar("gt_sprite", "materials/sprites/combineball_trail_black_1.vmt", "The desired sprite to use for trails.", FCVAR_NONE);
	HookConVarChange(g_hSprite, OnSettingsChange);
	g_hFlashColor = CreateConVar("gt_color_flashbang", "0,0,255,255", "The color for flashbang trails.", FCVAR_NONE);
	HookConVarChange(g_hFlashColor, OnSettingsChange);
	g_hGrenadeColor = CreateConVar("gt_color_hegrenade", "255,0,0,255", "The color for he grenade trails.", FCVAR_NONE);
	HookConVarChange(g_hGrenadeColor, OnSettingsChange);
	g_hSmokeColor = CreateConVar("gt_color_smokegrenade", "0,255,0,255", "The color for smoke grenade trails.", FCVAR_NONE);
	HookConVarChange(g_hSmokeColor, OnSettingsChange);
	AutoExecConfig(true, "GrenadeTrails");
	
	decl String:_sTemp[16], String:_sColors[4][4];
	g_bEnabled = GetConVarBool(g_hEnabled);
	
	GetConVarString(g_hSprite, g_sSprite, sizeof(g_sSprite));

	GetConVarString(g_hFlashColor, _sTemp, sizeof(_sTemp));
	ExplodeString(_sTemp, ",", _sColors, 4, 4);
	for(new i = 0; i <= 3; i++)
		g_iFlashColor[i] = StringToInt(_sColors[i]);
		
	GetConVarString(g_hGrenadeColor, _sTemp, sizeof(_sTemp));
	ExplodeString(_sTemp, ",", _sColors, 4, 4);
	for(new i = 0; i <= 3; i++)
		g_iGrenadeColor[i] = StringToInt(_sColors[i]);
		
	GetConVarString(g_hSmokeColor, _sTemp, sizeof(_sTemp));
	ExplodeString(_sTemp, ",", _sColors, 4, 4);
	for(new i = 0; i <= 3; i++)
		g_iSmokeColor[i] = StringToInt(_sColors[i]);
}

public OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hEnabled)
		g_bEnabled = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hSprite)
	{
		strcopy(g_sSprite, sizeof(g_sSprite), newvalue);
		g_iSprite = PrecacheModel(g_sSprite);
	}
	else if(cvar == g_hFlashColor)
	{
		decl String:_sColors1[4][4];
		ExplodeString(newvalue, ",", _sColors1, 4, 4);
		for(new i = 0; i <= 3; i++)
			g_iFlashColor[i] = StringToInt(_sColors1[i]);
	}
	else if(cvar == g_hGrenadeColor)
	{
		decl String:_sColors2[4][4];
		ExplodeString(newvalue, ",", _sColors2, 4, 4);
		for(new i = 0; i <= 3; i++)
			g_iGrenadeColor[i] = StringToInt(_sColors2[i]);
	}
	else if(cvar == g_hSmokeColor)
	{
		decl String:_sColors3[4][4];
		ExplodeString(newvalue, ",", _sColors2, 4, 4);
		for(new i = 0; i <= 3; i++)
			g_iSmokeColor[i] = StringToInt(_sColors3[i]);
	}
}

public OnMapStart()
{
	g_iSprite = PrecacheModel(g_sSprite);
}

public OnEntityCreated(Entity, const String:Classname[])
{
	if(g_bEnabled)
	{
		if(StrEqual(Classname, "hegrenade_projectile"))
		{
			TE_SetupBeamFollow(Entity, g_iSprite, 0, 1.0, 10.0, 10.0, 5, g_iGrenadeColor);
			TE_SendToAll();
		} 
		else if(StrEqual(Classname, "flashbang_projectile"))
		{
			TE_SetupBeamFollow(Entity, g_iSprite, 0, 1.0, 10.0, 10.0, 5, g_iFlashColor);
			TE_SendToAll();
		} 
		else if(StrEqual(Classname, "smokegrenade_projectile"))
		{
			TE_SetupBeamFollow(Entity, g_iSprite, 0, 1.0, 10.0, 10.0, 5, g_iSmokeColor);
			TE_SendToAll();
		}
	}
}