////you should checkout http://downloadtzz.firewall-gateway.com/ for free programs and basicpawn autocomplete func ect
//This was Coded in BasicPawn!!!!!!!!!
#pragma semicolon 1
 
#define PLUGIN_VERSION "0.21"
 
#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <sdkhooks>

new Handle:hCvar_Throwables = INVALID_HANDLE;
new Handle:hCvar_FuseColour = INVALID_HANDLE;
new Handle:hCvar_FlashColour = INVALID_HANDLE;
new Handle:hCvar_LightDisPip = INVALID_HANDLE;

new String:g_sPipFuseColour[12];
new String:g_sPipFlashColour[12];
new Float:g_fLightDisPip;

new bool:g_bThrowables = false;
new bool:IsMapRunning = false;

static g_iLightIndex[MAXPLAYERS+1];
static g_iWeaponIndex[MAXPLAYERS+1];
static bool:g_bLightActive[MAXPLAYERS+1] = false;
static bool:g_bLeft4Dead2;

public Plugin:myinfo =
{
    name = "EnhancementThrowables",
    author = "Ludastar (Armonic), Silvers",
    description = "[L4D]EnhanceThrowables",
    version = PLUGIN_VERSION,
    url = "http://steamcommunity.com/id/ArmonicJourney"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)//silvers Game error
{
	decl String:sGameName[12];
	GetGameFolderName(sGameName, sizeof(sGameName));
	if( strcmp(sGameName, "left4dead", false) == 0 ) g_bLeft4Dead2 = false;
	else if( strcmp(sGameName, "left4dead2", false) == 0 ) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}
 
public OnPluginStart()
{
	CreateConVar("EnhanceThrowables_Version", PLUGIN_VERSION, "Enhancement System Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	
	hCvar_Throwables = CreateConVar("EnhanceThrowables", "1", "Enchance Pipebomb and MoloLighttov with dynamic light glow", FCVAR_PLUGIN, true, 0.0, true, 1.0); 
	hCvar_FuseColour = CreateConVar("EnhanceFuseColour", "215 215 1", "Enchance Pipebomb Fuse Colour (255 255 255) <---- MAX", FCVAR_PLUGIN);
	hCvar_FlashColour = CreateConVar("EnhanceFlashColour", "200 1 1", "Enchance Pipebomb Light Flash Colour (255 255 255) <--- MAX", FCVAR_PLUGIN);
	hCvar_LightDisPip = CreateConVar("EnhancePipeLightDist", "255.0", "Enchance Pipebomb Light Max Distance", FCVAR_PLUGIN, true, 0.1, true, 9999.0);
	
	HookConVarChange(hCvar_Throwables, eConvarChanged);
	HookConVarChange(hCvar_FuseColour, eConvarChanged);
	HookConVarChange(hCvar_FlashColour, eConvarChanged);
	HookConVarChange(hCvar_LightDisPip, eConvarChanged);
	
	HookEvents();
	CvarsChanged();
	AutoExecConfig(false, "EnhancementThrowables");
}

public OnMapStart()
{
	CvarsChanged();
	IsMapRunning = true;
}

public eConvarChanged(Handle:hCvar, const String:sOldVal[], const String:sNewVal[])
{
	CvarsChanged();
}

CvarsChanged()
{
	g_bThrowables = GetConVarInt(hCvar_Throwables) > 0;
	g_fLightDisPip = GetConVarFloat(hCvar_LightDisPip);
	GetConVarString(hCvar_FuseColour, g_sPipFuseColour, sizeof(g_sPipFuseColour));
	GetConVarString(hCvar_FlashColour, g_sPipFlashColour, sizeof(g_sPipFlashColour));
}

public Action:OnPlayerRunCmd(iClient, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(!g_bThrowables || !IsClientInGame(iClient))
		return Plugin_Continue;
	if(IsFakeClient(iClient))
		return Plugin_Continue;
		
	new iEntity = g_iLightIndex[iClient];
	
	if(GetClientTeam(iClient) != 2 || !IsPlayerAlive(iClient))
	{
		if(IsValidEntRef(iEntity))
		{
			AcceptEntityInput(iEntity, "Kill");
			g_iLightIndex[iClient] = 0;
			g_bLightActive[iClient] = false;
		}
		return Plugin_Continue;
	}
	
	new iPost = g_iWeaponIndex[iClient];
	new iCurrent = GetEntPropEnt(iClient, Prop_Data, "m_hActiveWeapon");

	if(iPost != iCurrent)
	{
		g_iWeaponIndex[iClient] = iCurrent;
		PrintToChatAll("new Weapon In WeaponIdex");
		
		if(iCurrent == -1)
		{
			PrintToChatAll("weapon == -1");
			if(IsValidEntRef(iEntity))
			{
				AcceptEntityInput(iEntity, "Kill");
				g_iLightIndex[iClient] = 0;
				g_bLightActive[iClient] = false;
				PrintToChatAll("Weapon == -1 Remove light %N", iClient);
			}
			
		}
		else
		{
			decl String:sClassname[32];
			GetEntityClassname(iCurrent, sClassname, sizeof(sClassname));
			PrintToChatAll("Else Statment for throwables [%s] == [%i]", sClassname, iCurrent);
			if(StrEqual(sClassname, "weapon_molotov"))
			{				
				HandLight(iClient, iCurrent, 2);
				g_bLightActive[iClient] = true;
				PrintToChatAll("Has molly %N", iClient);
			}
			else if(StrEqual(sClassname, "weapon_pipe_bomb"))
			{
				HandLight(iClient, iCurrent, 1);
				g_bLightActive[iClient] = true;
				PrintToChatAll("Has Pipebomb %N", iClient);
			}
			else
			{
				if(IsValidEntRef(iEntity))
				{
					AcceptEntityInput(iEntity, "Kill");
					g_iLightIndex[iClient] = 0;
					g_bLightActive[iClient] = false;
					PrintToChatAll("Killed Weapon non Throwable %N", iClient);
				}
			}
		}
	}
	
	return Plugin_Continue;
}
HandLight(iClient, Throwable, iLightMode)
{
	new iEntity = g_iLightIndex[iClient];
	
	if(!IsValidEntRef(iEntity))
		MakeLight(iClient);
	
	if(!IsValidEntity(iEntity))
		return;
	PrintToChatAll("LightIndex == %i iClient == %N == %i", g_iLightIndex[iClient], iClient, iClient);
	decl Float:fPos[3];
	Entity_GetAbsOrigin(iClient, fPos);
	TeleportEntity(iEntity ,fPos, NULL_VECTOR, NULL_VECTOR);
	Entity_SetParent(iEntity, iClient);
	
	
	switch(iLightMode)
	{
		case 1:
		{
			SetVariantString("armR_T");
			AcceptEntityInput(iEntity, "SetParentAttachment");
			TeleportEntity(iEntity ,Float:{13.0, -5.0, 0.0}, Float:{-90.0, -90.0, 0.0}, NULL_VECTOR);
		}
		case 2:
		{
			MoloLight(iEntity);
		//	SetVariantString("Wick");
		//	AcceptEntityInput(iEntity, "SetParentAttachment");
		}
	}
}

MoloLight(iLight)
{
	DispatchKeyValue(iLight, "brightness", "1");
	DispatchKeyValueFloat(iLight, "spotlight_radius", 32.0);
	DispatchKeyValueFloat(iLight, "distance", 20.0);
	DispatchKeyValue(iLight, "style", "6");
	DispatchKeyValue(iLight, "Light color", "255 50 0");
	DispatchSpawn(iLight);
	AcceptEntityInput(iLight, "TurnOff");
	  
	SetVariantString("255 50 0");
	AcceptEntityInput(iLight, "Color");
	AcceptEntityInput(iLight, "TurnOn");
}

public OnEntityCreated(iEntity, const String:sClassname[])
{
	if(!IsMapRunning || !IsServerProcessing())
		return;
	
	if(!g_bThrowables || (sClassname[0] != 'p' && sClassname[0] != 'm'))
		return;
		
	if(StrEqual(sClassname, "pipe_bomb_projectile"))
	{
		CreateLight(iEntity, 1);
	}
	else if(StrEqual(sClassname, "Molotov_projectile"))
	{
		CreateLight(iEntity, 2);
	}
}

CreateLight(iEntity, iLightMode)
{
	new iLight = CreateEntityByName("light_dynamic");
	if(!IsValidEntity(iLight))
		return;
	
	decl Float:fPos[3];
	Entity_GetAbsOrigin(iEntity, fPos);
	TeleportEntity(iLight, fPos, NULL_VECTOR, NULL_VECTOR);
	Entity_SetParent(iLight, iEntity);
	
	switch(iLightMode)
	{
		case 1:
		{
			decl String:sBuffer[64];
			
			DispatchKeyValue(iLight, "brightness", "1");
			DispatchKeyValueFloat(iLight, "spotlight_radius", 200.0);
			DispatchKeyValueFloat(iLight, "distance", g_fLightDisPip / 7);
			DispatchKeyValue(iLight, "style", "-1");
			DispatchKeyValue(iLight, "Light color", "215 215 1");
			DispatchSpawn(iLight);
			AcceptEntityInput(iLight, "TurnOff");
			
			Format(sBuffer, sizeof(sBuffer), g_sPipFuseColour);
			SetVariantString(sBuffer);
			AcceptEntityInput(iLight, "Color");
			AcceptEntityInput(iLight, "TurnOn");
			
			Format(sBuffer, sizeof(sBuffer), "OnUser1 !self:distance:%f:0.0167:-1", g_fLightDisPip / 5);
			SetVariantString(sBuffer);
			AcceptEntityInput(iLight, "AddOutput");
			Format(sBuffer, sizeof(sBuffer), "OnUser1 !self:Color:%s:0.0167:-1", g_sPipFlashColour);
			SetVariantString(sBuffer);
			AcceptEntityInput(iLight, "AddOutput");
			Format(sBuffer, sizeof(sBuffer), "OnUser1 !self:distance:%f:0.0344:-1", (g_fLightDisPip / 5) * 2);
			SetVariantString(sBuffer);
			AcceptEntityInput(iLight, "AddOutput");
			Format(sBuffer, sizeof(sBuffer), "OnUser1 !self:distance:%f:0.0501:-1", (g_fLightDisPip / 5) * 3);
			SetVariantString(sBuffer);
			AcceptEntityInput(iLight, "AddOutput");
			Format(sBuffer, sizeof(sBuffer), "OnUser1 !self:distance:%f:0.0668:-1", (g_fLightDisPip / 5) * 4);
			SetVariantString(sBuffer);
			AcceptEntityInput(iLight, "AddOutput");
			Format(sBuffer, sizeof(sBuffer), "OnUser1 !self:distance:%f:0.0835:-1", g_fLightDisPip);
			SetVariantString(sBuffer);
			AcceptEntityInput(iLight, "AddOutput");
			Format(sBuffer, sizeof(sBuffer), "OnUser1 !self:distance:%f:0.1002:-1", (g_fLightDisPip / 4) * 3);
			SetVariantString(sBuffer);
			AcceptEntityInput(iLight, "AddOutput");
			Format(sBuffer, sizeof(sBuffer), "OnUser1 !self:distance:%f.0:0.1169:-1", (g_fLightDisPip / 4) * 2);
			SetVariantString(sBuffer);
			AcceptEntityInput(iLight, "AddOutput");
			Format(sBuffer, sizeof(sBuffer), "OnUser1 !self:distance:%f.0:0.1336:-1", g_fLightDisPip / 4);
			SetVariantString(sBuffer);
			AcceptEntityInput(iLight, "AddOutput");
			Format(sBuffer, sizeof(sBuffer), "OnUser1 !self:distance:%f.0:0.1503:-1", g_fLightDisPip / 7);
			SetVariantString(sBuffer);
			AcceptEntityInput(iLight, "AddOutput");
			Format(sBuffer, sizeof(sBuffer), "OnUser1 !self:Color:%s:0.1503:-1", g_sPipFuseColour);
			SetVariantString(sBuffer);
			AcceptEntityInput(iLight, "AddOutput");
			SetVariantString("OnUser1 !self:FireUser1::0.20004:-1");
			AcceptEntityInput(iLight, "AddOutput");
			
			SetVariantString("OnUser2 !self:FireUser1::0.334:1");
			AcceptEntityInput(iLight, "AddOutput");
			AcceptEntityInput(iLight, "FireUser2");
		}
		case 2:
		{
			MoloLight(iLight);
		}
	}
}



MakeLight(iClient)
{
	new iEntity = g_iLightIndex[iClient];
	if(IsValidEntRef(iEntity))
		return 0;
		
	iEntity = CreateEntityByName("light_dynamic");
	if(!IsValidEntity(iEntity))
		return 0;
	
	DispatchKeyValue(iEntity, "brightness", "1");
	DispatchKeyValue(iEntity, "style", "6");
	DispatchSpawn(iEntity);
	AcceptEntityInput(iEntity, "TurnOff");
	
	g_iLightIndex[iClient] = EntRefToEntIndex(iEntity);
	return iEntity;
}

HookEvents()
{
	HookEvent("player_ledge_grab",		eLedgeGrab);
	HookEvent("player_incapacitated",		ePlayerIncapped);
	HookEvent("revive_begin",			eReviveStart);
	HookEvent("revive_end",				eReviveEnd);
	HookEvent("revive_success",			eReviveSuccess);
	HookEvent("lunge_pounce",			eBlockHunter);
	HookEvent("pounce_end",				eBlockEndHunt);
	HookEvent("tongue_grab",			eBlockStart);
	HookEvent("tongue_release",			eBlockEnd);

	if( g_bLeft4Dead2 ) 
	{
		HookEvent("charger_pummel_start",	eBlockStart);
		HookEvent("charger_carry_start",	eBlockStart);
		HookEvent("charger_carry_end",		eBlockEnd);
		HookEvent("charger_pummel_end",		eBlockEnd);
		HookEvent("jockey_ride",			eBlockStart);
		HookEvent("jockey_ride_end",		eBlockEnd);
	}
}

public eBlockStart(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "victim"));
	if(iClient > 0)
	{
		if(g_bLightActive[iClient])
		{
			new iLight = g_iLightIndex[iClient];
			AcceptEntityInput(iLight, "TurnOff");
		}
	}
}

public eBlockEnd(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "victim"));
	if(iClient > 0)
	{
		if(g_bLightActive[iClient])
		{
			new iLight = g_iLightIndex[iClient];
			AcceptEntityInput(iLight, "TurnOn");
		}
	}
}

public eBlockHunter(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "victim"));
	if(iClient > 0)
	{
		if(g_bLightActive[iClient])
		{
			new iLight = g_iLightIndex[iClient];
			AcceptEntityInput(iLight, "TurnOff");
		}
	}
}

public eBlockEndHunt(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "victim"));
	if(iClient > 0)
	{
		if(g_bLightActive[iClient])
		{
			new iLight = g_iLightIndex[iClient];
			AcceptEntityInput(iLight, "TurnOn");
		}
	}
}

public eLedgeGrab(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(iClient > 0)
	{
		if(g_bLightActive[iClient])
		{
			new iLight = g_iLightIndex[iClient];
			AcceptEntityInput(iLight, "TurnOff");
		}
	}
}

public ePlayerIncapped(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(iClient > 0)
	{
		if(g_bLightActive[iClient])
		{
			new iLight = g_iLightIndex[iClient];
			AcceptEntityInput(iLight, "TurnOff");
		}
	}
}

public eReviveStart(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(iClient > 0)
	{
		if(g_bLightActive[iClient])
		{
			new iLight = g_iLightIndex[iClient];
			AcceptEntityInput(iLight, "TurnOff");
		}
	}
}

public eReviveEnd(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(iClient > 0)
	{
		if(g_bLightActive[iClient])
		{
			new iLight = g_iLightIndex[iClient];
			AcceptEntityInput(iLight, "TurnOn");
		}
	}
}

public eReviveSuccess(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "subject"));
	if(iClient > 0)
	{
		if(g_bLightActive[iClient])
		{
			new iLight = g_iLightIndex[iClient];
			AcceptEntityInput(iLight, "TurnOn");
		}
	}

	iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(iClient > 0)
	{
		if(g_bLightActive[iClient])
		{
			new iLight = g_iLightIndex[iClient];
			AcceptEntityInput(iLight, "TurnOn");
		}
	}
}

stock bool:IsValidEntRef(iEntRef)
{
    new iEntity = EntRefToEntIndex(iEntRef);
    return (iEntRef && iEntity != INVALID_ENT_REFERENCE && IsValidEntity(iEntity));
}

public OnMapEnd()
{
	IsMapRunning = false;
}