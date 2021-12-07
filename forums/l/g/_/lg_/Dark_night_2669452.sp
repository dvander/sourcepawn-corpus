#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define WORLDINDEX 0
#undef REQUIRE_PLUGIN

int FogControllerIndex;

ConVar cvarEnabled;
ConVar cvarSkybox;
ConVar cvarFogDensity;
ConVar cvarFogStartDist;
ConVar cvarFogEndDist;
ConVar cvarFogColor;
ConVar cvarFogZPlane;
ConVar cvarBrightness;

public void OnPluginStart()
{	
    cvarEnabled = CreateConVar("sm_envtools_enable", "1.0", "开启or关闭", FCVAR_NONE, true, 0.0, true, 1.0);
    cvarSkybox = CreateConVar("sm_envtools_skybox", "cmutationLAST_hdr", "天空更改", FCVAR_NONE);
    cvarFogDensity = CreateConVar("sm_envtools_fogdensity", "1.0", "切换雾化效果的密度", FCVAR_NONE, true, 0.0, true, 1.0);
    cvarFogStartDist = CreateConVar("sm_envtools_fogstart", "8000.0", "切换雾开始到多远", FCVAR_NONE, true, 0.0, true, 8000.0);
    cvarFogEndDist = CreateConVar("sm_envtools_fogend", "0.0", "更改雾在其峰值处的距离", FCVAR_NONE, true, 0.0, true, 8000.0);
    cvarFogColor = CreateConVar("sm_envtools_fogcolor", "0 0 0", "修改雾的颜色", FCVAR_NONE);
    cvarFogZPlane = CreateConVar("sm_envtools_zplane", "8000.0", "更改平面Z切口", FCVAR_NONE, true, 0.0, true, 8000.0);
    cvarBrightness = CreateConVar("sm_envtools_brightness", "a", "改变世界的亮度(a-z)", FCVAR_NONE);
    HookConVarChange(cvarFogColor, ConvarChange_FogColor);			
}


public void OnMapStart()
{	
	FogControllerIndex = FindEntityByClassname(-1, "env_fog_controller");
	
	if(FogControllerIndex == -1)
	{
		PrintToServer("[ET] No Fog Controller Exists. This Entity is either unsupported by this Game, or this Level Does not Include it.");
	}
	
	if(GetConVarBool(cvarEnabled))
	{
		ChangeSkyboxTexture();
		ChangeFogSettings();
		ChangeFogColors();
		char szLightStyle[6];
		GetConVarString(cvarBrightness, szLightStyle, sizeof(szLightStyle));
		SetLightStyle(0, szLightStyle);
	}
}

public void ChangeSkyboxTexture()
{
	if(GetConVarBool(cvarEnabled))
	{
		char newskybox[32];
		GetConVarString(cvarSkybox, newskybox, sizeof(newskybox));

		if(strcmp(newskybox, "", false)!=0)
		{
			PrintToServer("[ET] Changing the Skybox to %s", newskybox);
			DispatchKeyValue(WORLDINDEX, "skyname", newskybox);
		}
	}
}

public Action Command_Update(int client, int args)
{
	ChangeFogSettings();
}

public void ChangeFogSettings()
{
	float FogDensity = GetConVarFloat(cvarFogDensity);
	int FogStartDist = GetConVarInt(cvarFogStartDist);
	int FogEndDist = GetConVarInt(cvarFogEndDist);
	int FogZPlane = GetConVarInt(cvarFogZPlane);

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

public void ConvarChange_FogColor(ConVar convar, const char[] oldValue, const char[] newValue)
{
	ChangeFogColors();
}

public void ChangeFogColors()
{
	char FogColor[32];
	GetConVarString(cvarFogColor, FogColor, sizeof(FogColor));

	SetVariantString(FogColor);
	AcceptEntityInput(FogControllerIndex, "SetColor");

	SetVariantString(FogColor);
	AcceptEntityInput(FogControllerIndex, "SetColorSecondary");
}
