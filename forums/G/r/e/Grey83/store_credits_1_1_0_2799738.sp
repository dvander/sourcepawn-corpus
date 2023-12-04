#pragma semicolon 1
#include <store>
#pragma newdecls required

Handle
	hHUD,
	hTimer;
int
	iColor;
float
	fCD,
	fPosX,
	fPosY;

public Plugin myinfo = 
{
	name	= "Store Credits",
	author	= "Pilo, Grey83",
	version	= "1.1.0",
	url		= "https://forums.alliedmods.net/member.php?u=290157"
}

public void OnPluginStart()
{
	hHUD = CreateHudSynchronizer();

	ConVar cvar;
	cvar = CreateConVar("sm_store_credits_hud_color",	"00f", "HUD info color. Set by HEX (RGB or RRGGBB, values 0 - F or 00 - FF, resp.). Wrong color code = blue", FCVAR_PRINTABLEONLY);
	cvar.AddChangeHook(CVarChanged_Color);
	CVarChanged_Color(cvar, NULL_STRING, NULL_STRING);

	cvar = CreateConVar("sm_store_credits_hud_update",	"1.0", "Update info every x seconds", _, true, 0.1, true, 5.0);
	cvar.AddChangeHook(CVarChanged_CD);
	CVarChanged_CD(cvar, NULL_STRING, NULL_STRING);

	cvar = CreateConVar("sm_store_credits_hud_x",		"-0.01", "HUD info position X (0.0 - 1.0 left to right or -1.0 for center)", _, true, -2.0, true, 1.0);
	cvar.AddChangeHook(CVarChanged_PosX);
	fPosX = cvar.FloatValue;

	cvar = CreateConVar("sm_store_credits_hud_y",		"1.0", "HUD info position Y (0.0 - 1.0 top to bottom or -1.0 for center)", _, true, -2.0, true, 1.0);
	cvar.AddChangeHook(CVarChanged_PosY);
	fPosY = cvar.FloatValue;

	AutoExecConfig(true, "store_credits_hud");
}

public void CVarChanged_Color(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	char clr[8];
	cvar.GetString(clr, sizeof(clr));
	clr[7] = 0;

	int i = -1;
	while(clr[++i])
		if(!(clr[i] >= '0' && clr[i] <= '9') && !(clr[i] >= 'A' && clr[i] <= 'F') && !(clr[i] >= 'a' && clr[i] <= 'f'))
		{
			iColor = 0x0000FF;
			return;
		}

	clr[6] = 0;
	if(i == 3)
	{
		clr[4] = clr[5] = clr[2];
		clr[2] = clr[3] = clr[1];
		clr[1] = clr[0];
		i = 6;
	}

	if(i != 6) iColor = 0x0000FF;
	else StringToIntEx(clr, iColor , 16);
}

public void CVarChanged_CD(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	fCD = cvar.FloatValue;
	OnMapEnd();
	OnMapStart();
	Timer_HUD(null);
}

public void CVarChanged_PosX(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	fPosX = cvar.FloatValue;
}

public void CVarChanged_PosY(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	fPosY = cvar.FloatValue;
}

public void OnMapStart()
{
	hTimer = CreateTimer(fCD, Timer_HUD, _, TIMER_REPEAT);
}

public void OnMapEnd()
{
	delete hTimer;
}

public Action Timer_HUD(Handle timer)
{
	if(GetFeatureStatus(FeatureType_Native, "Store_IsClientLoaded") != FeatureStatus_Available
	|| GetFeatureStatus(FeatureType_Native, "Store_GetClientCredits") != FeatureStatus_Available)
		return Plugin_Continue;

	SetHudTextParams(fPosX, fPosY, fCD+0.1, (iColor & 0xFF0000) >> 16, (iColor & 0xFF00) >> 8, iColor & 0xFF, 255, 0, 0.0, 0.0, 0.0);
	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i) && Store_IsClientLoaded(i))
		ShowSyncHudText(i, hHUD, "You have %i credits", Store_GetClientCredits(i));

	return Plugin_Continue;
}