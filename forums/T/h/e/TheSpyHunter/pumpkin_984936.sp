#include <sourcemod>
#include <sdktools>

#define VERSION "1.1"

new Float:g_pos[3];
new bool:pluginEnabled = true;

public Plugin:myinfo = 
{
	name = "[TF2] Pumpkin",
	author = "linux_lover edited by TSH",
	description = "Spawns pumpkins to where your looking.",
	version = VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("sm_pumpkin_version", VERSION, "Pumpkin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	RegAdminCmd("sm_pumpkin", Command_Pumpkin, ADMFLAG_SLAY);
	RegAdminCmd("sm_givepumpkin", Command_GivePumpkin, ADMFLAG_SLAY);
	RegAdminCmd("sm_buypumpkin", Command_ShopPumkin, ADMFLAG_SLAY);
}

public Action:Command_Pumpkin(client, args)
{
	if(!SetTeleportEndPoint(client))
	{
		ReplyToCommand(client, "[SM] Could not find spawn point.");
		return Plugin_Handled;
	}
	
	if(GetEntityCount() >= GetMaxEntities()-16)
	{
		ReplyToCommand(client, "[SM] Entity limit is reached. Can't spawn anymore pumpkins. Change maps.");
		return Plugin_Handled;
	}
	
	new iPumpkin = CreateEntityByName("tf_pumpkin_bomb");
	
	if(IsValidEntity(iPumpkin))
	{		
		DispatchSpawn(iPumpkin);
		g_pos[2] -= 10.0;
		TeleportEntity(iPumpkin, g_pos, NULL_VECTOR, NULL_VECTOR);
	}
	
	return Plugin_Handled;
}

SetTeleportEndPoint(client)
{
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:vBuffer[3];
	decl Float:vStart[3];
	decl Float:Distance;
	
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
    //get endpoint for teleport
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if(TR_DidHit(trace))
	{   	 
   	 	TR_GetEndPosition(vStart, trace);
		GetVectorDistance(vOrigin, vStart, false);
		Distance = -35.0;
   	 	GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		g_pos[0] = vStart[0] + (vBuffer[0]*Distance);
		g_pos[1] = vStart[1] + (vBuffer[1]*Distance);
		g_pos[2] = vStart[2] + (vBuffer[2]*Distance);
	}
	else
	{
		CloseHandle(trace);
		return false;
	}
	
	CloseHandle(trace);
	return true;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > GetMaxClients() || !entity;
}

public Action:Command_ShopPumkin(client, args)
{	
	if (pluginEnabled)
	{
		new Handle:hMenu = CreateMenu(cShopPumkin);
		SetMenuTitle(hMenu, "Choose Player:");
		for (new i = 1; i <= GetClientCount(); i++)
		{
		if (IsClientConnected(i) && IsClientInGame(i))
			{
			new String:sName[255], String:sInfo[4];
			GetClientName(i, sName, sizeof(sName));
			IntToString(i, sInfo, sizeof(sInfo));
			AddMenuItem(hMenu, sInfo, sName);
			}
		}	
		DisplayMenu(hMenu, client, 20);
		return Plugin_Handled;
	} else {
		ReplyToCommand(client, "[SM] Pumpkin must be enabled to use Pumkin Bomb!");
		return Plugin_Handled;
	}
		
}

public cShopPumkin(Handle:menu, MenuAction:action, client, result)
{
	if (action == MenuAction_Select)
	{
		new String:info[32], String:sAName[255], String:sVName[255];
		GetMenuItem(menu, result, info, sizeof(info));
		new hTarget = StringToInt(info);
		GetClientName(client, sAName, sizeof(sAName));
		GetClientName(hTarget, sVName, sizeof(sVName));
		
		Command_Pumpkin(hTarget, 1); // Gives target a pumpkin
		PrintToChat(client, "You gave a pumpkin to %s", sVName);
		PrintToChat(hTarget, "%s gave you a pumpkin", sAName);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action:Command_GivePumpkin(client, args)
{
	if (pluginEnabled) {
		decl String:target[65];
		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[MAXPLAYERS];
		decl target_count;
		decl bool:tn_is_ml;
		
		if (args < 1) {
			return Command_ShopPumkin(client, args);
		}
		
		GetCmdArg(1, target, sizeof(target));
		
		if ((target_count = ProcessTargetString(
				target,
				client,
				target_list,
				MAXPLAYERS,
				0,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
			
		for (new i = 0; i < target_count; i++) {
			if (IsClientInGame(target_list[i])) {
				Command_Pumpkin(target_list[i], 1);
			}
		}
	} else {
		ReplyToCommand(client, "[SM] Pumpkin must be enabled to use Pumkin Bomb!");
		return Plugin_Handled;			
	}
	
	return Plugin_Handled;
}