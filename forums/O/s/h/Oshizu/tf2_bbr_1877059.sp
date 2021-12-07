#include <sdktools>
#include <betherobot>

new Handle:enabled
new bool:penabled;

new Handle:instantdisable
new bool:pinstantdisable;

new Handle:instantenable
new bool:pinstantenable;

public Plugin:myinfo =
{
    name        = "[TF2] Bots become Robots!",
    author      = "Oshizu / Kuchiki",
    description = "Changes bots appearence into Mann Vs Machine Robots",
    version     = "1.0.1",
    url         = "none",
};

public OnPluginStart()
{
	enabled = CreateConVar("sm_bbr_enabled", "1", "Enables / Disables plugin", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	penabled = GetConVarBool(enabled);
	
	instantdisable = CreateConVar("sm_bbr_instant_disable", "0", "Choose Method Bots act when plugin is disabled. 0 - Bots turn into humans after respawn 1 - Bots turn instantly into human after plugin is disabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	pinstantdisable = GetConVarBool(instantdisable);
	
	instantenable = CreateConVar("sm_bbr_instant_enable", "0", "Choose Method Bots act when plugin is enabled. 0 - Bots turn into robots after respawn 1 - Bots turn instantly into robots after plugin is enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	pinstantenable = GetConVarBool(instantenable);
	
	HookConVarChange(instantdisable, cvarinstantdisable);
	HookConVarChange(instantenable, cvarinstantenable);
	HookConVarChange(enabled, cvarEnable);
	
	HookEvent("player_spawn", apply_robot);
	HookEvent("post_inventory_application", apply_robot, EventHookMode_Post);
}

public cvarinstantenable(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (StringToInt(newValue) == 0)
	{
		pinstantenable = false
	}
	else if (StringToInt(newValue) == 1)
	{
		pinstantenable = true
	}
}

public cvarinstantdisable(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (StringToInt(newValue) == 0)
	{
		pinstantdisable = false
	}
	else if (StringToInt(newValue) == 1)
	{
		pinstantdisable = true
	}
}

public cvarEnable(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (StringToInt(newValue) == 1)
	{
		penabled = true
		if(pinstantenable)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					if(IsFakeClient(i))
					{
						BeTheRobot_SetRobot(i, true);
					}
				}
			}
		}
	}
	else if (StringToInt(newValue) == 0)
	{
		penabled = false
		if(pinstantdisable)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					if(IsFakeClient(i))
					{
						BeTheRobot_SetRobot(i, false);
					}
				}
			}
		}
	}
}

public Action:BecomeRobot(Handle:timer, any:bot)
{
	if(IsClientInGame(bot))
	{
		if(IsFakeClient(bot))
		{
			BeTheRobot_SetRobot(bot, true);
		}
	}
}

public Action:apply_robot(Handle:event, const String:name[], bool:dontBroadcast)
{
	new bot = GetClientOfUserId(GetEventInt(event, "userid"));
	if(penabled)
	{
		if(IsClientInGame(bot))
		{
			if(IsFakeClient(bot))
			{
				BeTheRobot_SetRobot(bot, true);
				CreateTimer(0.00, BecomeRobot, bot);
				CreateTimer(0.01, BecomeRobot, bot);
				CreateTimer(0.05, BecomeRobot, bot);
				CreateTimer(0.25, BecomeRobot, bot);
				CreateTimer(0.50, BecomeRobot, bot);
				CreateTimer(0.75, BecomeRobot, bot);
				CreateTimer(1.00, BecomeRobot, bot);
			}
		}
	}
}