#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0.1"


public Plugin:myinfo = 
{
	
	name = "[TF2] Ball Projectile Limit",
	
	author = "Tylerst",

	description = "Limits the number of ball projectiles allowed on the map at once",

	version = PLUGIN_VERSION,

}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf"))
	{
		Format(error, err_max, "This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}
	return APLRes_Success;
}


new Handle:g_hBallLimit = INVALID_HANDLE;
new g_iBallLimit = 32;
new g_iCount = 0;

public OnPluginStart()
{
	CreateConVar("sm_balllimit_version", PLUGIN_VERSION, "Ball Projectile Limit", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hBallLimit = CreateConVar("sm_balllimit", "32", "Limit the ball projectiles on the map to this amount", 0, true, 1.0);
	HookConVarChange(g_hBallLimit, CvarChange_BallLimit);
	RegAdminCmd("sm_clearballs", Command_ClearBalls, ADMFLAG_GENERIC, "Clear all ball projectiles on the map");
}

public OnConfigsExecuted()
{
	g_iBallLimit = GetConVarInt(g_hBallLimit);
}

public CvarChange_BallLimit(Handle:Cvar, const String:strOldValue[], const String:strNewValue[])
{
	g_iBallLimit = StringToInt(strNewValue);
	ClearAllBalls()
	g_iCount = 0;
}

public OnMapStart()
{
	g_iCount = 0;
}

public Action:Command_ClearBalls(client, args)
{
	ClearAllBalls();
	g_iCount = 0
	return Plugin_Handled;
}

public OnEntityCreated(entity, const String:classname[])
{
	if(!strcmp(classname, "tf_projectile_stun_ball") || !strcmp(classname, "tf_projectile_ball_ornament"))
	{
		SDKHook(entity, SDKHook_SpawnPost, BallSpawned);
	}
}


public OnEntityDestroyed(entity)
{
	if(entity > MaxClients && IsValidEntity(entity))
	{
		new String:classname[256];
		GetEntityClassname(entity, classname, sizeof(classname));
		if(!strcmp(classname, "tf_projectile_stun_ball") || !strcmp(classname, "tf_projectile_ball_ornament"))
		{
			if(g_iCount > 0) g_iCount--;
		}
	}
}


public BallSpawned(entity)
{
	if(++g_iCount > g_iBallLimit) KillABall()
}

ClearAllBalls()
{
	new SandmanBall = -1; 
	while((SandmanBall = FindEntityByClassname(SandmanBall, "tf_projectile_stun_ball"))!=INVALID_ENT_REFERENCE)
	{
		if(IsValidEntity(SandmanBall))
		{
			AcceptEntityInput(SandmanBall, "Kill");
		}
		else continue;	
	}

	new WrapAssassinBall = -1; 
	while((WrapAssassinBall = FindEntityByClassname(WrapAssassinBall, "tf_projectile_ball_ornament"))!=INVALID_ENT_REFERENCE)
	{
		if(IsValidEntity(WrapAssassinBall))
		{
			AcceptEntityInput(WrapAssassinBall, "Kill");
		}
		else continue;		
	}

}

KillABall()
{
	new SandmanBall = -1; 
	while((SandmanBall = FindEntityByClassname(SandmanBall, "tf_projectile_stun_ball"))!=INVALID_ENT_REFERENCE)
	{
		if(IsValidEntity(SandmanBall) && GetEntProp(SandmanBall, Prop_Send, "m_bTouched"))
		{
			AcceptEntityInput(SandmanBall, "Kill");
			return;
		}
		else continue;	
	}

	new WrapAssassinBall = -1; 
	while((WrapAssassinBall = FindEntityByClassname(WrapAssassinBall, "tf_projectile_ball_ornament"))!=INVALID_ENT_REFERENCE)
	{
		if(IsValidEntity(WrapAssassinBall) && GetEntProp(WrapAssassinBall, Prop_Send, "m_bTouched"))
		{
			AcceptEntityInput(WrapAssassinBall, "Kill");
			return;
		}
		else continue;		
	}	
}
