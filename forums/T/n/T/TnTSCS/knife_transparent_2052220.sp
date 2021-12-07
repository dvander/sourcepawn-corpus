#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>

new Handle:RGBA = INVALID_HANDLE;
new PlayerIsTransparent[MAXPLAYERS+1];
new String:TmpRender[30];
new valRender[4];

public OnPluginStart()
{
	HookConVarChange((RGBA = CreateConVar("sm_kt_values", "255 255 255 100", 
	"Values for rendered color and alpha\nValues are in order Red Green Blue Alpha")), OnTempRenderChanged);
	GetConVarString(RGBA, TmpRender, sizeof(TmpRender));
	StringToRender(TmpRender);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	if (late)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				OnClientConnected(i);
				RenderClientColor(i, false);
			}
		}
	}
	
	return APLRes_Success;
}

public OnClientConnected(client)
{
	PlayerIsTransparent[client] = false;
	SDKHook(client, SDKHook_WeaponCanSwitchToPost, OnWeaponSwitchPost);
}

public OnClientDisconnect(client)
{
	PlayerIsTransparent[client] = false;
	SDKUnhook(client, SDKHook_WeaponCanSwitchToPost, OnWeaponSwitchPost);
}

public OnWeaponSwitchPost(client, weapon)
{
	new String:weaponName[80];
	if (GetEntityClassname(weapon, weaponName, sizeof(weaponName)))
	{
		if (StrEqual(weaponName, "weapon_knife", false))
		{
			if (!PlayerIsTransparent[client])
			{
				RenderClientColor(client, true);
				PlayerIsTransparent[client] = true;
			}
		}
		else
		{
			if (PlayerIsTransparent[client])
			{
				RenderClientColor(client, false);
				PlayerIsTransparent[client] = false;
			}
		}
	}
}

StringToRender(String:str[])
{
	new String:t_str[4][5];
	
	ReplaceString(str, sizeof(str[]), ",", " ", false);
	ReplaceString(str, sizeof(str[]), ";", " ", false);
	ReplaceString(str, sizeof(str[]), "  ", " ", false);
	TrimString(str);
	
	if (ExplodeString(str, " ", t_str, sizeof(t_str), sizeof(t_str[])) != 4)
	{
		LogError("There is a problem with the sm_kt_values, a correct value is something like: \"255 255 255 100\"");
		LogError("The current CVar value is: %s\nSetting back to default CVar setting", str);
		SetConVarString(RGBA, "255 255 255 100");
		valRender[0] = 255;
		valRender[1] = 255;
		valRender[2] = 255;
		valRender[3] = 100;
		return;
	}
	
	valRender[0] = StringToInt(t_str[0]);
	valRender[1] = StringToInt(t_str[1]);
	valRender[2] = StringToInt(t_str[2]);
	valRender[3] = StringToInt(t_str[3]);
}



RenderClientColor(client, bool:on)
{
	if (!IsClientInGame(client))
	{
		return;
	}
	
	if (on)
	{
		SetEntityRenderColor(client, valRender[0], valRender[1], valRender[2], valRender[3]);
		SetEntityRenderMode(client, RENDER_TRANSALPHA);
	}
	else
	{
		SetEntityRenderColor(client, 255, 255, 255, 255);
		SetEntityRenderMode(client, RENDER_NORMAL);
	}
}

public OnTempRenderChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	GetConVarString(cvar, TmpRender, sizeof(TmpRender));
	StringToRender(TmpRender);
}