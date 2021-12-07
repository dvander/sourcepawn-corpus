#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1"

public Plugin:myinfo = 
{
	name = "[TF2] Spin the Wheel",
	author = "FlaminSarge",
	description = "Spins the Wheel of Fate if it exists on the map",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1828032"
}

new Float:flNextSpinTime = 0.0;
new Handle:hSpinTime;

public OnPluginStart()
{
	CreateConVar("tf_spinwheel_version", PLUGIN_VERSION, "[TF2] Spin the Wheel version", FCVAR_NOTIFY|FCVAR_PLUGIN);
	hSpinTime = CreateConVar("tf_spinwheel_time", "0.0", "Amount of time (seconds) enforced between Wheel spins. Changes to this cvar apply immediately.", FCVAR_PLUGIN, true, 0.0);
	HookConVarChange(hSpinTime, cvhSpinTime);
	RegAdminCmd("sm_spin", Cmd_Spin, ADMFLAG_CHEATS, "Spins the Wheel of Fate");
}
public cvhSpinTime(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	new Float:flOld = StringToFloat(oldVal);
	new Float:flNew = StringToFloat(newVal);
	flNextSpinTime += (flNew - flOld);
}
public OnMapStart()
{
	flNextSpinTime = 0.0;
}
public Action:Cmd_Spin(client, args)
{
	new i = -1;
	new found = false;
	new Float:flGameTime = GetGameTime();
	if (flNextSpinTime > flGameTime && !CheckCommandAccess(client, "tf_spinwheel_time_override", ADMFLAG_ROOT, true))
	{
		ReplyToCommand(client, "[SM] Cannot spin wheel for another %.1f second(s).", flNextSpinTime - flGameTime);
		return Plugin_Handled;
	}
	while ((i = FindEntityByClassname(i, "wheel_of_doom")) != -1)
	{
		AcceptEntityInput(i, "Spin");
		found = true;
	}
	if (found)
	{
		flNextSpinTime = flGameTime + GetConVarFloat(hSpinTime);
	}
	ReplyToCommand(client, "[SM] %s", found ? "Spun the Wheel of Fate." : "Error 404: Wheel not found.");
	return Plugin_Handled;
}