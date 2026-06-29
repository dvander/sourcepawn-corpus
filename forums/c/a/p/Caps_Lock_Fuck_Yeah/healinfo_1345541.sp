#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION 	"1.2"

new Handle:g_enabled = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Survivor Heal Info",
	author = "CAPS LOCK FUCK YEAH",
	description = "SameAsName",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	HookEvent("heal_success", HealSuccess);
	CreateConVar("sm_healinfo_version", PLUGIN_VERSION,"Heal Info Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	g_enabled = CreateConVar("sm_healinfo_enabled","1","Is Heal Info Enabled?")
	LoadTranslations("healinfo.phrases.txt")
}

public HealSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	new UserId = GetEventInt(event, "userid")
	new Subject = GetEventInt(event, "subject")
	new HealthRestored = GetEventInt(event, "health_restored")
	new healee = GetClientOfUserId(Subject)
	new healer = GetClientOfUserId(UserId)
	new String:PName1[64]
	new String:PName2[64]
	if (GetConVarInt(g_enabled) == 1)
	{
		GetClientName(healer, PName1, sizeof(PName1))
		GetClientName(healee, PName2, sizeof(PName2))
		if (StrEqual(PName1,PName2))
		{
			PrintHintTextToAll("%T","healed_self",LANG_SERVER,PName1,HealthRestored)
		}
		else
		{
			PrintHintTextToAll("%T","healed_other",LANG_SERVER,PName1,PName2,HealthRestored)
		}
	}
	return
}