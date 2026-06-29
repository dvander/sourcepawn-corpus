#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#define VERSION "1.1"

public Plugin:myinfo =
{
	name = "Only Taunt Kills",
	author = "Mitch.",
	description = "Allows players to kill each other only with taunt kills",
	version = VERSION,
	url = "http://snbx.info/"
}

public OnPluginStart()
{
	CreateConVar("onlytauntkills_version", VERSION, "Only Taunt Killing Version", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_CHEAT);
	for(new i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i))
			SDKHook(i, SDKHook_OnTakeDamage, TakeDamageHook);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, TakeDamageHook);
}

public Action:TakeDamageHook(client, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if ((client>=1) && (client<=MaxClients))
	{
		if(client != attacker)
		{
			if((attacker>=1) && (attacker<=MaxClients))
			{
				switch(damagecustom)
				{
					case TF_CUSTOM_TAUNT_GRAND_SLAM, TF_CUSTOM_PICKAXE,TF_CUSTOM_TAUNT_HADOUKEN,TF_CUSTOM_TAUNT_ARMAGEDDON,TF_CUSTOM_FLARE_PELLET,TF_CUSTOM_TAUNT_BARBARIAN_SWING,TF_CUSTOM_TAUNT_HIGH_NOON,TF_CUSTOM_TAUNT_ENGINEER_SMASH,TF_CUSTOM_TAUNT_ENGINEER_ARM,TF_CUSTOM_TAUNT_UBERSLICE,TF_CUSTOM_TAUNT_ARROW_STAB,TF_CUSTOM_TAUNT_FENCING:
						return Plugin_Continue;
					default:
						return Plugin_Handled;
				}
			}
		}
	}
	return Plugin_Continue;
}