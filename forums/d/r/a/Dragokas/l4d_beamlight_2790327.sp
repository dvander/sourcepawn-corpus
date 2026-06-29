#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
    name = "[L4D] Beam Light",
    author = "Dragokas",
    description = "Light color effects",
    version = "1.0",
    url = "https://dragokas.com/"
}

bool g_bFogInProgress;
bool g_bRoundStart;

public void OnPluginStart()
{
	HookEvent("round_end", 				Event_RoundEnd,		EventHookMode_PostNoCopy);
	HookEvent("finale_win", 			Event_RoundEnd,		EventHookMode_PostNoCopy);
	HookEvent("mission_lost", 			Event_RoundEnd,		EventHookMode_PostNoCopy);
	HookEvent("map_transition", 		Event_RoundEnd,		EventHookMode_PostNoCopy);

	SetRandomSeed(GetTime());
}

public void Event_RoundFreezeEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bRoundStart)
		return;
	
	g_bRoundStart = true;
	
	char sBeamColor[32];
	
	switch (GetRandomInt(1, 5)) {
		case 1: Format(sBeamColor, sizeof(sBeamColor), "%i %i %i", GetRandomInt(200, 255), 0, 0);
		case 2: Format(sBeamColor, sizeof(sBeamColor), "%i %i %i", 0, GetRandomInt(200, 255), 0);
		case 3: Format(sBeamColor, sizeof(sBeamColor), "%i %i %i", 0, 0, GetRandomInt(200, 255));
		case 4: Format(sBeamColor, sizeof(sBeamColor), "%i %i %i", GetRandomInt(200, 255), GetRandomInt(200, 255), 0);
		case 5: Format(sBeamColor, sizeof(sBeamColor), "%i %i %i", 0, GetRandomInt(200, 255), GetRandomInt(200, 255));
	}
	
	SetBeamLight(sBeamColor);
}

void SetFog()
{
	static int r,g,b;
	static char sBeamColor[32];

	switch(GetRandomInt(1, 6))
	{
		case 1, 2, 3: {
			ServerCommand("sm_fog 0 0 50");
			ServerCommand("sm_sun 0 0 50");
			r = 0;
			g = GetRandomInt(0, 200);
			b = GetRandomInt(50, 250);
			ServerCommand("sm_background %i %i %i", r, g, b);
			
			switch (GetRandomInt(0, 5)) {
				case 0: Format(sBeamColor, sizeof(sBeamColor), "%i %i %i", 0, g / 200 * 128, (b-50) / 200 * 128 + 128 - 1);
				case 1: Format(sBeamColor, sizeof(sBeamColor), "%i %i %i", GetRandomInt(200, 255), 0, 0);
				case 2: Format(sBeamColor, sizeof(sBeamColor), "%i %i %i", 0, GetRandomInt(200, 255), 0);
				case 3: Format(sBeamColor, sizeof(sBeamColor), "%i %i %i", 0, 0, GetRandomInt(200, 255));
				case 4: Format(sBeamColor, sizeof(sBeamColor), "%i %i %i", GetRandomInt(200, 255), GetRandomInt(200, 255), 0);
				case 5: Format(sBeamColor, sizeof(sBeamColor), "%i %i %i", 0, GetRandomInt(200, 255), GetRandomInt(200, 255));
			}
			
			SetBeamLight(sBeamColor);
		}
		case 4: {
			ServerCommand("sm_fog 0 50 50");
			ServerCommand("sm_sun 0 50 50");
			r = 0;
			g = GetRandomInt(0, 200);
			b = GetRandomInt(50, 250);
			ServerCommand("sm_background %i %i %i", r, g, b);
			Format(sBeamColor, sizeof(sBeamColor), "%i %i %i", 0, g / 200 * 128 + 128 - 1, (b-50) / 200 * 128);
			SetBeamLight(sBeamColor);
		}
		case 5: {
			ServerCommand("sm_fog 50 0 0");
			ServerCommand("sm_sun 50 0 0");
			r = GetRandomInt(0, 100);
			g = GetRandomInt(0, 15);
			b = GetRandomInt(0, r / 2);
			ServerCommand("sm_background %i %i %i", r, g ,b);
			Format(sBeamColor, sizeof(sBeamColor), "%i %i %i", r / 100 * 55 + 200, b, g); // not mistake!
			SetBeamLight(sBeamColor);
		}
		case 6: {
			ServerCommand("sm_fog 50 0 50");
			ServerCommand("sm_sun 50 0 50");
			r = GetRandomInt(0, 150);
			g = GetRandomInt(0, r / 2);
			b = r;
			ServerCommand("sm_background %i %i %i", r, g ,b);
			r = r / 150 * 128 + 128 - 1;
			g = r;
			b = 0;
			Format(sBeamColor, sizeof(sBeamColor), "%i %i %i", r, g, b);
			SetBeamLight(sBeamColor);
		}
	}
}

public Action Event_RoundEnd(Event event, char[] name, bool dontBroadcast)
{
	OnMapEnd();
}
public void OnMapEnd()
{
	g_bRoundStart = false;
	g_bFogInProgress = false;
}

void StartFog()
{
	if (!g_bFogInProgress) {
		g_bFogInProgress = true;
	
		SetFog();
	}
}

public void OnMapStart()
{	
	StartFog();
}

void SetBeamLight(char[] sColor)
{
	static int ent;
	ent = -1;
	
	while ((ent = FindEntityByClassname(ent, "beam_spotlight")) != -1)
	{
		SetVariantString(sColor);
		AcceptEntityInput(ent, "Color");
	}
}