#pragma semicolon 1
#include <sourcemod>

new Handle:g_hFlashlight = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Allow Flashlight",
	author = "GoD-Tony",
	description = "Prevents maps from disabling the flashlight",
	version = "1.0.0",
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	if ((g_hFlashlight = FindConVar("mp_flashlight")) == INVALID_HANDLE)
		SetFailState("Failed to find mp_flashlight cvar.");
	
	OnCvarChange(g_hFlashlight, "", "");
	HookConVarChange(g_hFlashlight, OnCvarChange);
}

public OnCvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (GetConVarInt(convar) != 1)
		SetConVarInt(convar, 1);
}
