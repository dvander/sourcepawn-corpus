#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

#define PLUGIN_VERSION "1.0.1"


static float fGameTimeSave[MAXPLAYERS+1];
static Handle hCvar_Allow = INVALID_HANDLE;
static Handle hCvar_AnimSpeed = INVALID_HANDLE;

static bool bEnabled = false;
static float fAnimSpeed = 2.0;
static float fTickRate;


public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "[L4D2]Adrenaline_Recovery",
	author = "Lux",
	description = "Adrenaline makes you react faster to knockdowns and staggers",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2606439"
};

public void OnPluginStart()
{
	CreateConVar("l4d2_adrenaline_recovery_version", PLUGIN_VERSION, "[L4D2]Adrenaline_Recovery_version", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	hCvar_Allow = CreateConVar("ar_allow", "1", "(1 = [Enabled])  (0 = [Don't even ask xD])", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvar_AnimSpeed = CreateConVar("ar_animspeed", "2.0", "(1.0 = Minspeed(Default speed) 2.0 = 2x speed of recovery", FCVAR_NOTIFY, true, 1.0, true, 100.0);
	HookConVarChange(hCvar_Allow, eConvarChanged);
	HookConVarChange(hCvar_AnimSpeed, eConvarChanged);
	
	HookEvent("round_start", eRoundStart);
	
	AutoExecConfig(true, "[L4D2]Adrenaline_Recovery");
	CvarsChanged();
	HookAll();
}

public void OnMapStart()
{
	fTickRate = GetTickInterval();
	CvarsChanged();
}

public void hOnPostThinkPost(int iClient)
{
	if(IsFakeClient(iClient) && GetClientTeam(iClient) != 2)
	{
		SDKUnhook(iClient, SDKHook_PostThinkPost, hOnPostThinkPost);
		return;
	}
	
	if(!IsPlayerAlive(iClient) || GetClientTeam(iClient) != 2) 
		return;
	
	if(!GetEntProp(iClient, Prop_Send, "m_bAdrenalineActive", 1))
		return;
	
	if(ShouldGetUpFaster(iClient))
		SetEntPropFloat(iClient, Prop_Send, "m_flPlaybackRate", fAnimSpeed);
	else
	{
		float fGameTime;
		fGameTime = GetGameTime();
		if(fGameTimeSave[iClient] > fGameTime)
			return;
		
		float fStaggerTimer;
		fStaggerTimer = GetEntPropFloat(iClient, Prop_Send, "m_staggerTimer", 1);
		if(fStaggerTimer <= fGameTime + fTickRate)// ignore if stagger will last atleast 1 tick
			return;
		
		fStaggerTimer = (((fStaggerTimer - fGameTime) / fAnimSpeed) + fGameTime);
		SetEntPropFloat(iClient, Prop_Send, "m_staggerTimer", fStaggerTimer, 1);
		fGameTimeSave[iClient] = fStaggerTimer;
	}
	return;
}

static bool ShouldGetUpFaster(int iClient)
{
	static char sModel[31];
	GetEntPropString(iClient, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
	switch(sModel[29])
	{
		case 'b'://nick
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 680, 667, 671, 672, 630, 620, 627:
					return true;
			}
		}
		case 'd'://rochelle
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 687, 679, 678, 674, 638, 635, 629:
					return true;
			}
		}
		case 'c'://coach
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 669, 661, 660, 656, 630, 627, 621:
					return true;
			}
		}
		case 'h'://ellis
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 684, 676, 675, 671, 625, 635, 632:
					return true;
			}
		}
		case 'v'://bill
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 772, 764, 763, 759, 538, 535, 528:
					return true;
			}
		}
		case 'n'://zoey
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 824, 823, 819, 809, 547, 544, 537:
					return true;
			}
		}
		case 'e'://francis
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 775, 767, 766, 762, 541, 539, 531:
					return true;
			}
		}
		case 'a'://louis
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 772, 764, 763, 759, 538, 535, 528:
					return true;
			}
		}
		case 'w'://adawong
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 687, 679, 678, 674, 638, 635, 629:
					return true;
			}
		}
	}
	
	return false;
}

public void eConvarChanged(Handle hCvar, const char[] sOldVal, const char[] sNewVal)
{
	CvarsChanged();
}

void CvarsChanged()
{
	bEnabled = GetConVarInt(hCvar_Allow) > 0;
	fAnimSpeed = GetConVarFloat(hCvar_AnimSpeed);
	
	if(bEnabled)
		HookAll();
	else
		UnHookAll();
}

void HookAll()
{
	for(int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i))
			SDKHook(i, SDKHook_PostThinkPost, hOnPostThinkPost);
}

void UnHookAll()
{
	for(int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i))
			SDKUnhook(i, SDKHook_PostThinkPost, hOnPostThinkPost);
}

public void OnClientPutInServer(int iClient)
{
	SDKHook(iClient, SDKHook_PostThinkPost, hOnPostThinkPost);
}

public void eRoundStart(Handle hEvent, const char[] sEventName, bool bDontBroadcast)
{
	for(int i = 1; i <= MaxClients; i++)
		fGameTimeSave[i] = 0.0;
}
