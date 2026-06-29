#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.0.0"

new Handle:Version;
new Handle:gHud;

public Plugin:myinfo =
{
	name = "Hud Say",
	author = "ReFlexPoison",
	description = "Send user messages through hud text",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	Version = CreateConVar("sm_hudsay_version", PLUGIN_VERSION, "Hud Say Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_DONTRECORD);
	
	RegAdminCmd("sm_hudsay", HUDSay, ADMFLAG_GENERIC, "sm_outline <x> <y> <time> <red> <green> <blue> <alpha> <message> - Send user message to all players through hud text");
	
	HookConVarChange(Version, CVarChange);
	
	gHud = CreateHudSynchronizer();
	if(gHud == INVALID_HANDLE)
	{
		SetFailState("HUD synchronisation is not supported by this mod");
	}
}

public CVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == Version)
	{
		SetConVarString(Version, PLUGIN_VERSION);
	}
}

public Action:HUDSay(client, args)
{
	if(args != 8)
	{
		ReplyToCommand(client, "Usage: sm_hudsay <x> <y> <time> <red> <green> <blue> <alpha> <message>");
		return Plugin_Handled;
	}
	else
	{
		new String:arg1[64], String:arg2[64], String:arg3[64], String:arg4[64], String:arg5[64], String:arg6[64], String:arg7[64], String:arg8[64];
		GetCmdArg(1, arg1, sizeof(arg1));
		GetCmdArg(2, arg2, sizeof(arg2));
		GetCmdArg(3, arg3, sizeof(arg3));
		GetCmdArg(4, arg4, sizeof(arg4));
		GetCmdArg(5, arg5, sizeof(arg5));
		GetCmdArg(6, arg6, sizeof(arg6));
		GetCmdArg(7, arg7, sizeof(arg7));
		GetCmdArg(8, arg8, sizeof(arg8));
		new Float:x = StringToFloat(arg1);
		if(x < -1.0 || x > 1.0)
		{
			x = -1.0;
		}
		new Float:y = StringToFloat(arg2);
		if(y < -1.0 || y > 1.0)
		{
			y = -1.0;
		}
		new Float:t = StringToFloat(arg3);
		if(t <= 0.0 || y > 10.0)
		{
			y = 10.0;
		}
		new r = StringToInt(arg4);
		if(r < 0 || r > 255)
		{
			r = 255;
		}
		new g = StringToInt(arg5);
		if(g < 0 || g > 255)
		{
			g = 255;
		}
		new b = StringToInt(arg6);
		if(b < 0 || b > 255)
		{
			b = 255;
		}
		new a = StringToInt(arg7);
		if(a < 0 || a > 255)
		{
			a = 255;
		}
		SetHudTextParams(x, y, t, r, g, b, a);
		for(new i = 0; i < MaxClients; i++)
		{
			if(IsValidClient(i) && !IsFakeClient(i))
			{
				ShowSyncHudText(i, gHud, "%s", arg8);
			}
		}
		LogAction(client, -1, "\"%L\" triggered sm_hudsay (text %s)", client, arg8);
	}
	return Plugin_Handled;
}

stock IsValidClient(client)
{
	if(client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		return true;
	}
	return false;
}