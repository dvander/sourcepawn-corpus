/* Crimson's Realtime Environmental Mod Tools */

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"
#define WORLDINDEX 0

new FogControllerIndex;

new Handle:cvarEnabled;
new Handle:cvarSkybox;

new Handle:cvarFogDensity;
new Handle:cvarFogStartDist;
new Handle:cvarFogEndDist;
new Handle:cvarFogColor;
new Handle:cvarFogZPlane;
new Handle:cvarBrightness;

public Plugin:myinfo = 
{
	name = "TF2 Environmental Tools",
	author = "Crimson",
	description = "Allows for the client to modify the game world in realtime",
	version = PLUGIN_VERSION,
	url = "http://www.TF2RocketArena.com"
}

public OnPluginStart()
{
	CreateConVar("sm_envtools_version", PLUGIN_VERSION, "SM Environmental Tools Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	cvarEnabled = CreateConVar("sm_envtools_enable", "1.0", "Toggle Realtime Skybox Change", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarSkybox = CreateConVar("sm_envtools_skybox", "sky_borealis01", "Toggle Realtime Skybox Change", FCVAR_PLUGIN);

	cvarFogDensity = CreateConVar("sm_envtools_fogdensity", "0.6", "Toggle the density of the fog effects", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarFogStartDist = CreateConVar("sm_envtools_fogstart", "0", "Toggle how far away the fog starts", FCVAR_PLUGIN, true, 0.0, true, 8000.0);
	cvarFogEndDist = CreateConVar("sm_envtools_fogend", "500", "Toggle how far away the fog is at its peak", FCVAR_PLUGIN, true, 0.0, true, 8000.0);
	cvarFogColor = CreateConVar("sm_envtools_fogcolor", "200 200 200", "Modify the color of the fog", FCVAR_PLUGIN);
	cvarFogZPlane = CreateConVar("sm_envtools_zplane", "4000", "Change the Z clipping plane", FCVAR_PLUGIN, true, 0.0, true, 8000.0);
	cvarBrightness = CreateConVar("sm_envtools_brightness", "a", "Toggle the brightness of the world (a-z)", FCVAR_PLUGIN);

	RegAdminCmd("sm_envtools_update", Command_Update, ADMFLAG_KICK, "Updates all lighting and fog convar settings");
	
	HookConVarChange(cvarFogColor, ConvarChange_FogColor);
}

public OnMapStart()
{
	FogControllerIndex = FindEntityByClassname(-1, "env_fog_controller");
	
	if(FogControllerIndex == -1)
	{
		PrintToServer("[ET] No Fog Controller Exists. This Entity is either unsupported by this Game, or this Level Does not Include it.");
	}
	
	if(GetConVarBool(cvarEnabled))
	{
		//Loads a new skybox texture in on mapstart.
		ChangeSkyboxTexture();
		//Loads the settings for the Fog
		ChangeFogSettings();
		//Loads the fog colors
		ChangeFogColors();
		//Changes the brightness of the world
		//GetConVarString(cvarBrightness, Brightness, sizeof(Brightness));
		decl String:szLightStyle[6];
		GetConVarString(cvarBrightness, szLightStyle, sizeof(szLightStyle));
		SetLightStyle(0, szLightStyle);
	}
}

public ChangeSkyboxTexture()
{
	if(GetConVarBool(cvarEnabled))
	{
		decl String:newskybox[32];
		GetConVarString(cvarSkybox, newskybox, sizeof(newskybox));

		//If there is a convar set, change the skybox to it
		if(strcmp(newskybox, "", false)!=0)
		{
			PrintToServer("[ET] Changing the Skybox to %s", newskybox);
			DispatchKeyValue(WORLDINDEX, "skyname", newskybox);
		}
	}
}

public Action:Command_Update(client, args)
{
	ChangeFogSettings();
}

public ChangeFogSettings()
{
	new Float:FogDensity = GetConVarFloat(cvarFogDensity);
	new FogStartDist = GetConVarInt(cvarFogStartDist);
	new FogEndDist = GetConVarInt(cvarFogEndDist);
	new FogZPlane = GetConVarInt(cvarFogZPlane);

	if(FogControllerIndex != -1)
	{
		DispatchKeyValueFloat(FogControllerIndex, "fogmaxdensity", FogDensity);

		SetVariantInt(FogStartDist);
		AcceptEntityInput(FogControllerIndex, "SetStartDist");
		
		SetVariantInt(FogEndDist);
		AcceptEntityInput(FogControllerIndex, "SetEndDist");
		
		SetVariantInt(FogZPlane);
		AcceptEntityInput(FogControllerIndex, "SetFarZ");
	}
}

public ConvarChange_FogColor(Handle:convar, const String:oldValue[], const String:newValue[])
{
	ChangeFogColors();
}

public ChangeFogColors()
{
	decl String:FogColor[32];
	GetConVarString(cvarFogColor, FogColor, sizeof(FogColor));

	SetVariantString(FogColor);
	AcceptEntityInput(FogControllerIndex, "SetColor");

	SetVariantString(FogColor);
	AcceptEntityInput(FogControllerIndex, "SetColorSecondary");
}