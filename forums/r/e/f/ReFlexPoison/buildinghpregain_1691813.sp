#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "2.4.1"

new Handle:cvarTime;
new Handle:cvarDispenser;
new Handle:cvarSentry;
new Handle:cvarTeleporter;
new Handle:Version;
new Handle:g_hTimer;

public Plugin:myinfo =
{
	name = "Buildings HP Regain",
	author = "ReFlexPoison",
	description = "Makes engineer buildings regain a set amount of hp overtime",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1691813#post1691813"
}

public OnPluginStart()
{
	Version = CreateConVar("sm_bhp_version", PLUGIN_VERSION, "Version of Building HP Regain", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_DONTRECORD);

	cvarTime = CreateConVar("sm_bhp_time", "1", "Amount of time between building hp regains\n0 = Disabled", FCVAR_NONE, true, 0.0);
	cvarDispenser = CreateConVar("sm_bhp_dispenser", "1", "Amount of hp dispensers regain\n0 = None", FCVAR_NONE, true, 0.0);
	cvarSentry = CreateConVar("sm_bhp_sentry", "1", "Amount of hp sentrys regain\n0 = None", FCVAR_NONE, true, 0.0);
	cvarTeleporter = CreateConVar("sm_bhp_teleporter", "1", "Amount of hp teleporters regain\n0 = None", FCVAR_NONE, true, 0.0);

	HookConVarChange(cvarTime, CVarChange);
	HookConVarChange(Version, CVarChange);

	AutoExecConfig(true, "plugin.buildinghpregain");
}

public CVarChange(Handle:convar, const String:oldVal[], const String:newVal[])
{
	if(convar == Version) SetConVarString(Version, PLUGIN_VERSION);
	else if(convar == cvarTime)
	{
		ClearTimer(g_hTimer);
		if(GetConVarFloat(cvarTime) > 0.0) g_hTimer = CreateTimer(GetConVarFloat(cvarTime), AddHealth, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}

public OnMapStart()
{
	if(GetConVarFloat(cvarTime) > 0.0) g_hTimer = CreateTimer(GetConVarFloat(cvarTime), AddHealth, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public OnMapEnd()
{
	ClearTimer(g_hTimer);
}

public Action:AddHealth(Handle:timer)
{
	if(GetConVarFloat(cvarTime) <= 0.0) return Plugin_Continue;

	new dispenser = -1;
	if(GetConVarInt(cvarDispenser) > 0)
	{
		while((dispenser = FindEntityByClassname(dispenser, "obj_dispenser")) != INVALID_ENT_REFERENCE)
		{
			SetVariantInt(GetConVarInt(cvarDispenser));
			AcceptEntityInput(dispenser, "AddHealth");
		}
	}
	new sentry = -1;
	if(GetConVarInt(cvarSentry) > 0)
	{
		while((sentry = FindEntityByClassname(sentry, "obj_sentrygun")) != INVALID_ENT_REFERENCE)
		{
			SetVariantInt(GetConVarInt(cvarSentry));
			AcceptEntityInput(sentry, "AddHealth");
		}
	}
	new teleporter = -1;
	if(GetConVarInt(cvarTeleporter) > 0)
	{
		while((teleporter = FindEntityByClassname(teleporter, "obj_teleporter")) != INVALID_ENT_REFERENCE)
		{
			SetVariantInt(GetConVarInt(cvarTeleporter));
			AcceptEntityInput(teleporter, "AddHealth");
		}
	}
	return Plugin_Continue;
}

stock ClearTimer(&Handle:timer)
{
	if(timer != INVALID_HANDLE)
	{
		KillTimer(timer);
		timer = INVALID_HANDLE;
	}
}