#define PLUGIN_NAME "[TF2] Sentry Busters Drop Money"
#define PLUGIN_AUTHOR "Boyned, Shadowysn (edit)"
#define PLUGIN_DESC "Sentry Busters Drop Money on explosion."
#define PLUGIN_VERSION "1.1"
#define PLUGIN_URL "https://forums.alliedmods.net/showthread.php?t=239813"
#define PLUGIN_NAME_SHORT "Sentry Busters Drop Money"
#define PLUGIN_NAME_TECH "sbdm"

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define AUTOEXEC_CFG "sentrybuster_dropmoney"

static ConVar Cvar_CashSize, Cvar_Enabled, Cvar_Amount;
int g_iCashSize; bool g_bEnabled; int g_iAmount;
#define CASHSIZE_RAND 0
#define CASHSIZE_SMALL 1
#define CASHSIZE_MEDIUM 2
#define CASHSIZE_LARGE 3

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion ev = GetEngineVersion();
	if (ev == Engine_TF2)
	{
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Team Fortress 2.");
	return APLRes_SilentFailure;
}

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

public void OnPluginStart()
{
	static char desc_str[64];
	Format(desc_str, sizeof(desc_str), "%s version.", PLUGIN_NAME_SHORT);
	static char cmd_str[64];
	Format(cmd_str, sizeof(cmd_str), "sm_%s_version", PLUGIN_NAME_TECH);
	ConVar version_cvar = CreateConVar(cmd_str, PLUGIN_VERSION, desc_str, FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if (version_cvar != null)
		version_cvar.SetString(PLUGIN_VERSION);
	
	HookEvent("mvm_sentrybuster_detonate", Event_SentryBusterExplode, EventHookMode_Pre);
	
	Format(cmd_str, sizeof(cmd_str), "sm_%s_cashsize", PLUGIN_NAME_TECH);
	Cvar_CashSize = CreateConVar(cmd_str, "small", "Type of the cash dropped by Sentry Busters. Values: small, medium, large. Use rand value for random.", FCVAR_NONE);
	Cvar_CashSize.AddChangeHook(CC_SBDM_CashSize);
	
	Format(cmd_str, sizeof(cmd_str), "sm_%s_cashamount", PLUGIN_NAME_TECH);
	Cvar_Amount = CreateConVar(cmd_str, "4", "How much cash entities will be dropped.", FCVAR_NONE, true, 1.0);
	Cvar_Amount.AddChangeHook(CC_SBDM_Amount);
	
	Format(cmd_str, sizeof(cmd_str), "sm_%s_enable", PLUGIN_NAME_TECH);
	Cvar_Enabled = CreateConVar(cmd_str, "1", "Toggles Sentry Busters dropping money plugin.", FCVAR_NONE, true, 0.0, true, 1.0);
	Cvar_Enabled.AddChangeHook(CC_SBDM_Enabled);
	
	AutoExecConfig(true, AUTOEXEC_CFG);
	SetCvarValues();
}

void CC_SBDM_CashSize(ConVar convar, const char[] oldValue, const char[] newValue)
{
	static char cashSize[5];
	convar.GetString(cashSize, sizeof(cashSize));
	
	if (strncmp(cashSize, "large", 5, false) == 0) g_iCashSize = CASHSIZE_LARGE;
	else if (strncmp(cashSize, "medium", 6, false) == 0) g_iCashSize = CASHSIZE_MEDIUM;
	else if (strncmp(cashSize, "small", 5, false) == 0) g_iCashSize = CASHSIZE_SMALL;
	else g_iCashSize = CASHSIZE_RAND;
}
void CC_SBDM_Amount(ConVar convar, const char[] oldValue, const char[] newValue)	{ g_iAmount =		convar.IntValue;	}
void CC_SBDM_Enabled(ConVar convar, const char[] oldValue, const char[] newValue)	{ g_bEnabled =		convar.BoolValue;	}
void SetCvarValues()
{
	CC_SBDM_CashSize(Cvar_CashSize, "", "");
	CC_SBDM_Amount(Cvar_Amount, "", "");
	CC_SBDM_Enabled(Cvar_Enabled, "", "");
}

void Event_SentryBusterExplode(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bEnabled || g_iAmount < 1) return;
	
	int cashSize = g_iCashSize;
	for (int i; i <= g_iAmount; i++)
	{
		if (g_iCashSize == CASHSIZE_RAND)
			cashSize = GetRandomInt(CASHSIZE_SMALL, CASHSIZE_LARGE);
		
		float xyz[3];
		switch (cashSize)
		{
			case CASHSIZE_LARGE:
			{
				int cash = CreateEntityByName("item_currencypack_large");
				if (RealValidEntity(cash))
				{
					xyz[0] = GetEventFloat(event, "det_x");
					xyz[1] = GetEventFloat(event, "det_y");
					xyz[2] = GetEventFloat(event, "det_z");
					DispatchKeyValueVector(cash, "origin", xyz);
					DispatchSpawn(cash);
					ActivateEntity(cash);
				}
			}
			case CASHSIZE_MEDIUM:
			{
				int cash = CreateEntityByName("item_currencypack_medium");
				if (RealValidEntity(cash))
				{
					xyz[0] = GetEventFloat(event, "det_x");
					xyz[1] = GetEventFloat(event, "det_y");
					xyz[2] = GetEventFloat(event, "det_z");
					DispatchKeyValueVector(cash, "origin", xyz);
					DispatchSpawn(cash);
					ActivateEntity(cash);
				}
			}
			case CASHSIZE_SMALL:
			{
				int cash = CreateEntityByName("item_currencypack_small");
				if (RealValidEntity(cash))
				{
					xyz[0] = GetEventFloat(event, "det_x");
					xyz[1] = GetEventFloat(event, "det_y");
					xyz[2] = GetEventFloat(event, "det_z");
					DispatchKeyValueVector(cash, "origin", xyz);
					DispatchSpawn(cash);
					ActivateEntity(cash);
				}
			}
		}
	}
}

stock bool RealValidEntity(int entity)
{ return (entity > 0 && IsValidEntity(entity)); }
