/*
#############################################
#	Credits for Ammo pack spawning code:	#
#	TF2 Ammo-packs by [NATO]Hunter			#
#############################################
*/
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0.0"

new g_FilteredEntity = -1;
new Float:g_ClientPosition[MAXPLAYERS+1][3];

public Plugin:myinfo = 
{
    name = "[TF2] Ammopack Spawner",
    author = "DarthNinja",
    description = "Need some ammopacks hea!",
    version = PLUGIN_VERSION,
    url = "DarthNinja.com"
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");

	CreateConVar("sm_ammopackspawner_version", PLUGIN_VERSION, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)

	RegAdminCmd("sm_spawnammo", Boolet, ADMFLAG_BAN);
}

public Action:Boolet(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "Usage: sm_spawnammo <full / medium / small>");
		return Plugin_Handled;
	}
	if (client < 1)
	{
		ReplyToCommand(client, "This command must be used ingame");
		return Plugin_Handled;
	}
	
	
	decl String:buffer[128];
	GetCmdArg(1, buffer, sizeof(buffer));
	
	if (StrEqual(buffer, "full", false))
	{
		ShowActivity2(client, "\x04[Ammo\x04]\x01 ","spawned a \x04Full\x01 ammo pack!", client);
		LogAction(client, -1, "[Ammo] %L spawned a Full ammo pack.", client);
		TF_SpawnAmmopack(client, "item_ammopack_full", true);
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "medium", false))
	{
		ShowActivity2(client, "\x04[Ammo\x04]\x01 ","spawned a \x04Medium\x01 ammo pack!", client);
		LogAction(client, -1, "[Ammo] %L spawned a Medium ammo pack.", client);
		TF_SpawnAmmopack(client, "item_ammopack_medium", true);
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "small", false))
	{
		ShowActivity2(client, "\x04[Ammo\x04]\x01 ","spawned a \x04Small\x01 ammo pack!", client);
		LogAction(client, -1, "[Ammo] %L spawned a Small ammo pack.", client);
		TF_SpawnAmmopack(client, "item_ammopack_small", true);
		return Plugin_Handled;
	}
	
	ReplyToCommand(client, "Usage: sm_spawnammo <full / medium / small>");
	return Plugin_Handled;
}

stock TF_SpawnAmmopack(client, String:name[], bool:cmd)
{
    new Float:PlayerPosition[3];
    if (cmd)
        GetClientAbsOrigin(client, PlayerPosition);
    else
        PlayerPosition = g_ClientPosition[client];

    if (PlayerPosition[0] != 0.0 && PlayerPosition[1] != 0.0 && PlayerPosition[2] != 0.0 && IsEntLimitReached() == false)
    {
        PlayerPosition[2] += 4;
        g_FilteredEntity = client;
        if (cmd)
        {
            new Float:PlayerPosEx[3], Float:PlayerAngle[3], Float:PlayerPosAway[3];
            GetClientEyeAngles(client, PlayerAngle);
            PlayerPosEx[0] = Cosine((PlayerAngle[1]/180)*FLOAT_PI);
            PlayerPosEx[1] = Sine((PlayerAngle[1]/180)*FLOAT_PI);
            PlayerPosEx[2] = 0.0;
            ScaleVector(PlayerPosEx, 75.0);
            AddVectors(PlayerPosition, PlayerPosEx, PlayerPosAway);

            new Handle:TraceEx = TR_TraceRayFilterEx(PlayerPosition, PlayerPosAway, MASK_SOLID, RayType_EndPoint, AmmopackTraceFilter);
            TR_GetEndPosition(PlayerPosition, TraceEx);
            CloseHandle(TraceEx);
        }

        new Float:Direction[3];
        Direction[0] = PlayerPosition[0];
        Direction[1] = PlayerPosition[1];
        Direction[2] = PlayerPosition[2]-1024;
        new Handle:Trace = TR_TraceRayFilterEx(PlayerPosition, Direction, MASK_SOLID, RayType_EndPoint, AmmopackTraceFilter);

        new Float:AmmoPos[3];
        TR_GetEndPosition(AmmoPos, Trace);
        CloseHandle(Trace);
        AmmoPos[2] += 4;

        new Ammopack = CreateEntityByName(name);
        DispatchKeyValue(Ammopack, "OnPlayerTouch", "!self,Kill,,0,-1");
        if (DispatchSpawn(Ammopack))
        {
            new team = 0;
            SetEntProp(Ammopack, Prop_Send, "m_iTeamNum", team, 4);
            TeleportEntity(Ammopack, AmmoPos, NULL_VECTOR, NULL_VECTOR);
        }
    }
}

public bool:AmmopackTraceFilter(ent, contentMask)
{
    return (ent != g_FilteredEntity);
}

stock bool:IsEntLimitReached()
{
    if (GetEntityCount() >= (GetMaxEntities()-30))
    {
        PrintToServer("Warning: Entity limit is nearly reached! Please switch or reload the map!");
        LogError("Entity limit is nearly reached: %d/%d", GetEntityCount(), GetMaxEntities());
        return true;
    }
    else
        return false;
}