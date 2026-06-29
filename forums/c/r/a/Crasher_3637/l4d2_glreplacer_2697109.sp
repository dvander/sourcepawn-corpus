#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

public Plugin myinfo = 
{
	name = "[L4D2] Grenade Launcher Replacer",
	author = "AtomicStryker & Psyk0tik (Crasher_3637)",
	description = "Replace grenade launchers with M60s.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1020236"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "\"[L4D2] Grenade Launcher Replacer\" only supports Left 4 Dead 2.");

		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

ConVar g_cvReplaceGrenadeLaunchers;

public void OnPluginStart()
{
	CreateConVar("l4d2_glreplacer_version", PLUGIN_VERSION, "Version of Grenade Launcher Replacer", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_cvReplaceGrenadeLaunchers = CreateConVar("l4d2_glreplacer_chance", "50.0", "Chance to replace grenade launchers with M60s.", _, true, 0.0, true, 100.0);
	AutoExecConfig(true, "l4d2_glreplacer");

	HookEvent("round_start", eEventRoundStart);
}

public void OnMapStart()
{
	PrecacheModel("models/w_models/weapons/w_m60.mdl");
	PrecacheModel("models/v_models/v_m60.mdl");
}

public void eEventRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(10.0, tTimerReplace, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action tTimerReplace(Handle timer)
{
	vReplace();

	return Plugin_Continue;
}

static void vReplace()
{
	float flChance = g_cvReplaceGrenadeLaunchers.FloatValue, flOrigin[3], flAngles[3];
	int iWeapon = -1;
	while ((iWeapon = FindEntityByClassname(iWeapon, "weapon_grenade_launcher_spawn")) != INVALID_ENT_REFERENCE)
	{
		if (GetRandomFloat(0.0, 100.0) <= flChance)
		{
			GetEntPropVector(iWeapon, Prop_Send, "m_vecOrigin", flOrigin);
			GetEntPropVector(iWeapon, Prop_Send, "m_angRotation", flAngles);

			int iReplacement = CreateEntityByName("weapon_rifle_m60");
			if (IsValidEntity(iReplacement))
			{
				DispatchSpawn(iReplacement);
				TeleportEntity(iReplacement, flOrigin, flAngles, NULL_VECTOR);
				SetEntProp(iReplacement, Prop_Data, "m_iClip1", 150, 1);

				RemoveEntity(iWeapon);
			}
		}
	}
}