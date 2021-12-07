#include <sourcemod>
#include <sdktools>

int g_MyBomb[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "Bomb",
	author = "cow",
	description = "Performs a bomb explosion on command",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	RegAdminCmd("sm_bomb", DoBomb, ADMFLAG_GENERIC, "explode");
}




public Action DoBomb(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_bomb <#userid|name>");
		return Plugin_Handled;
	}

	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg) );
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0 && IsPlayerAlive(client))
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		DropExplosion(client, target_list[i]);
	}
	
	return Plugin_Handled;
}


stock DropExplosion(client, target)
{
	decl Float:vecPosition[3];
	GetClientAbsOrigin(target, vecPosition); 
	g_MyBomb[client] = CreateEntityByName("info_particle_system");
	DispatchKeyValue(g_MyBomb[client], "start_active", "0");
	DispatchKeyValue(g_MyBomb[client], "effect_name", "explosion_c4_500");
	DispatchSpawn(g_MyBomb[client]);
	TeleportEntity(g_MyBomb[client], vecPosition, NULL_VECTOR, NULL_VECTOR);
	ActivateEntity(g_MyBomb[client]);
	SetVariantString("!activator");
	AcceptEntityInput(g_MyBomb[client], "SetParent", g_MyBomb[client], g_MyBomb[client], 0);
	ForcePlayerSuicide(target);
	EmitAmbientSound("weapons/c4/c4_explode1.wav", NULL_VECTOR, target);
	CreateTimer(0.25, Timer_Run, g_MyBomb[client]);
}

public Action Timer_Run(Handle timer, any ent)
{
	if(ent > 0 && IsValidEntity(ent))
	{
		AcceptEntityInput(ent, "Start");
		CreateTimer(7.0, Timer_Die, ent);
	}
}

public Action Timer_Die(Handle timer, any ent)
{
	if(ent > 0 && IsValidEntity(ent))
	{
		if(IsValidEdict(ent))
		{
			AcceptEntityInput(ent, "Kill");
		}
	}
}