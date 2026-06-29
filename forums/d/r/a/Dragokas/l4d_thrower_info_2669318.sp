#define PLUGIN_VERSION "1.2"

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

ConVar g_CvarEnabled;

char MODEL_GASCAN[] = "models/props_junk/gascan001a.mdl";
char MODEL_PROPANE[] = "models/props_junk/propanecanister001a.mdl";
char MODEL_OXYGENE[] = "models/props_equipment/oxygentank01.mdl";

bool g_bLate;

public Plugin myinfo =
{
	name = "[L4D] Molotov-Pipe bomb Thrown/Gascan Broken Announcer",
	author = "Alex Dragokas",
	description = "Makes an announcement when players throw a molotov/pipe-bomb or break a gascan.",
	version = PLUGIN_VERSION,
	url = "http://github.com/dragokas"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test != Engine_Left4Dead2 && test != Engine_Left4Dead) {
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	g_bLate = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("l4d_thrower_info.phrases");
	
	g_CvarEnabled = CreateConVar("l4d_thrower_info_enable", "1", "Enable the plugin? (0: OFF, 1: ON)", FCVAR_NOTIFY);
	CreateConVar("l4d_thrower_info_version", PLUGIN_VERSION, "Version of the plugin.", FCVAR_DONTRECORD);
	AutoExecConfig(true, "l4d_thrower_info");
	
	g_CvarEnabled.AddChangeHook(OnConVarChanged);
	
	InitHook();
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	InitHook();
	
	if (g_CvarEnabled.BoolValue)
		OnMapStart();
	else
		UnhookEntityOutput("prop_physics", "OnBreak", OnEntityOutput);
}

void InitHook()
{
	static bool bHooked;
	
	if (g_CvarEnabled.BoolValue) {
		if (!bHooked) {
			HookEvent("weapon_fire", OnWeaponFire);
		}
	} else {
		if (bHooked) {
			UnhookEvent("weapon_fire", OnWeaponFire);
		}
	}
}

public void OnMapStart()
{
	HookEntityOutput("prop_physics", "OnBreak", OnEntityOutput );
}

void OnEntityOutput (const char[] output, int broke, int breaker, float delay)
{
	static char sBrokeModel[PLATFORM_MAX_PATH];
	
	if (breaker >= 1 && breaker <= MaxClients && IsClientInGame(breaker)) {
		if (broke > MaxClients && IsValidEntity(broke))
		{
			GetEntPropString(broke, Prop_Data, "m_ModelName", sBrokeModel, sizeof(sBrokeModel));
			if(StrEqual(sBrokeModel, MODEL_GASCAN, false))
			{
				CPrintToChatAll("%t", "Gascan", breaker); // "\x04%N\x01 broke a \x05gascan!"
			}
			else if (StrEqual(sBrokeModel, MODEL_PROPANE, false))
			{
				CPrintToChatAll("%t", "Propane", breaker);
			}
			else if(StrEqual(sBrokeModel, MODEL_OXYGENE, false))
			{
				CPrintToChatAll("%t", "Oxygene", breaker);
			}
		}
	}
}

public void OnWeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	static char sWeapon[64];
	static int thrower;
	
	static float fLastTime, fNowTime;
	fNowTime = GetGameTime();
	if (fLastTime != 0.0 && FloatAbs(fNowTime - fLastTime) < 1.0) {
		return;
	}
	fLastTime = fNowTime;
	
	thrower = GetClientOfUserId(event.GetInt("userid"));
	if (IsClientInGame(thrower) && GetClientTeam(thrower) == 2)
	{
		event.GetString("weapon", sWeapon, sizeof(sWeapon));
		
		if (StrEqual(sWeapon, "molotov", true))
		{
			CPrintToChatAll("%t", "Molotov", thrower); // "\x04%N\x01 threw a \x05molotov!"
		}
		else if (StrEqual(sWeapon, "pipe_bomb", true))
		{
			CPrintToChatAll("%t", "Pipebomb", thrower); // "\x04%N\x01 threw a \x05pipe-bomb!"
		}
	}
}

stock void CPrintToChatAll(const char[] format, any ...)
{
    char buffer[192];
    for( int i = 1; i <= MaxClients; i++ )
    {
        if( IsClientInGame(i) && !IsFakeClient(i) )
        {
            SetGlobalTransTarget(i);
            VFormat(buffer, sizeof(buffer), format, 2);
            ReplaceColor(buffer, sizeof(buffer));
            PrintToChat(i, "\x01%s", buffer);
        }
    }
}

stock void ReplaceColor(char[] message, int maxLen)
{
    ReplaceString(message, maxLen, "{white}", "\x01", false);
    ReplaceString(message, maxLen, "{cyan}", "\x03", false);
    ReplaceString(message, maxLen, "{orange}", "\x04", false);
    ReplaceString(message, maxLen, "{green}", "\x05", false);
}