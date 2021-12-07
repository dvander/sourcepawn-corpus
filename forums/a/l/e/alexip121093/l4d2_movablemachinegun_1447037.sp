#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>

new parenting[MAXPLAYERS+1];
new bool:buttondelay[MAXPLAYERS+1];
new String:EntityName[MAXPLAYERS+1][64];
new bool:l4d2=false;
public Plugin:myinfo = 
{
	name = "Movable Machine Gun",
	author = "hihi1210",
	description = "Movable Machine Gun by pressing Shift + Mouse Right Click",
	version = "1.0.3",
	url = ""
}

public OnPluginStart()
{
	decl String:stGame[32];
	GetGameFolderName(stGame, 32);
	if (StrEqual(stGame, "left4dead2", false)==true )
	{
		l4d2=true;
	}
	else if (StrEqual(stGame, "left4dead", false)==true)
	{
		l4d2=false;
	}
	else
	{
		SetFailState("Movable Machine Gun only supports L4D 1 or 2.");
	}
	CreateConVar("l4d2_moveablemachinegun", "1.0.3", "L4D Movable Machine Gun Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_minigun", SpawnMini, ADMFLAG_GENERIC, "Allows admins to spawn a minigun sm_minigun <type> 0 for l4d1 minigun 1 for l4d2 minigun");
	RegAdminCmd("sm_removeminigun", RemoveMini, ADMFLAG_GENERIC, "Remove the minigun you aimed at");
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_bot_replace", Event_BotReplacedPlayer);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
}
public OnMapStart()
{
	if (l4d2)
	{
		PrecacheModel("models/w_models/weapons/50cal.mdl", true);
	}
	PrecacheModel("models/w_models/weapons/w_minigun.mdl", true);
}

public Action:SpawnMini(client, args) 
{
	if (IsDedicatedServer() && client ==0 ) return Plugin_Continue;
	new type;
	decl String:types[32];
	if (args ==1)
	{
		GetCmdArg(1, types, sizeof(types));
		type = StringToInt(types);
	}
	else
	{
		type=GetRandomInt(0,1)
	}
	if (!l4d2)
	{
		type = 0;
	}
	CreateMiniGun(client,type);
	return Plugin_Continue;
}
public Action:RemoveMini(client, args) 
{
	if (IsDedicatedServer() && client ==0 ) return Plugin_Continue;
	new target = GetClientAimTarget(client,false);
	decl String:item[64];
	if(target != -1) {
		if (IsValidEntRef(target))
		{
			GetEdictClassname(target, item, sizeof(item));
			if (StrEqual(item, "prop_minigun") || StrEqual(item, "prop_minigun_l4d1") )
			{
				AcceptEntityInput(target, "kill");
			}
		}
	}
	return Plugin_Continue;
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new iCid=1; iCid<=GetMaxClients(); iCid++)
	{
		if (parenting[iCid] !=0)
		{
			if( IsValidEntRef(parenting[iCid] ))
			AcceptEntityInput(parenting[iCid], "kill");
		}
		parenting[iCid]=0;
		Format(EntityName[iCid], 64, "");
	}
	return Plugin_Continue;
}
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsDedicatedServer() && client ==0 || client < 0) return Plugin_Continue;
	if (client >GetMaxClients()) return Plugin_Continue;
	if (parenting[client]!=0)
	{
		if (IsValidEntRef(parenting[client]))
		{
			AcceptEntityInput(parenting[client], "kill");
		}
		parenting[client]=0;
		Format(EntityName[client], 64, "");
	}
	return Plugin_Continue;
}
CreateMiniGun(client,type)
{
	new index;
	decl Float:VecOrigin[3], Float:VecAngles[3], Float:VecDirection[3];
	if (type == 1)
	{
		index = CreateEntityByName ("prop_minigun");
	}
	else if (type == 0)
	{
		if (!l4d2)
		{
			index = CreateEntityByName ("prop_minigun");
		}
		else
		{
			index = CreateEntityByName ("prop_minigun_l4d1");
		}
		
	}
	if (index == -1)
	{
		ReplyToCommand(client, "[SM] Failed to create minigun!");
		return;
	}
	DispatchKeyValue(index, "model", "Minigun_1");
	
	if (type==1)
	{
		SetEntityModel (index, "models/w_models/weapons/50cal.mdl");
	}
	else if (type==0)
	{
		SetEntityModel (index, "models/w_models/weapons/w_minigun.mdl");
	}


	DispatchKeyValueFloat (index, "MaxPitch", 360.00);
	DispatchKeyValueFloat (index, "MinPitch", -360.00);
	DispatchKeyValueFloat (index, "MaxYaw", 90.00);
	DispatchSpawn(index);
	GetClientAbsOrigin(client, VecOrigin);
	GetClientEyeAngles(client, VecAngles);
	GetAngleVectors(VecAngles, VecDirection, NULL_VECTOR, NULL_VECTOR);
	VecOrigin[0] += VecDirection[0] * 32;
	VecOrigin[1] += VecDirection[1] * 32;
	VecOrigin[2] += VecDirection[2] * 1;   
	VecAngles[0] = 0.0;
	VecAngles[2] = 0.0;
	DispatchKeyValueVector(index, "Angles", VecAngles);
	DispatchSpawn(index);
	TeleportEntity(index, VecOrigin, NULL_VECTOR, NULL_VECTOR);
	return;
}
public Action:Event_BotReplacedPlayer(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "player"));
	new bot = GetClientOfUserId(GetEventInt(event, "bot"));
	if (IsDedicatedServer() && client ==0 || client < 0) return Plugin_Continue;
	if (client >GetMaxClients()) return Plugin_Continue;
	if (parenting[client]!=0)
	{
		if (IsValidEntRef(parenting[client]))
		{
			AcceptEntityInput(parenting[client], "kill");
		}
		parenting[client]=0;
		if (StrEqual(EntityName[client], "prop_minigun") )
		{
			if (!l4d2)
			{
				CreateMiniGun(bot,0);
			}
			else
			{
				CreateMiniGun(bot,1);
			}
		}
		else
		{
			CreateMiniGun(bot,0);
		}
		Format(EntityName[client], 64, "");
		return Plugin_Continue;
	}
	return Plugin_Continue;
}
bool:IsValidEntRef(iEnt)
{
	if( iEnt && EntRefToEntIndex(iEnt) != INVALID_ENT_REFERENCE )
	return true;
	return false;
}

public Action:ResetDelay(Handle:Timer, any:client)
{
	buttondelay[client]=false;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (IsDedicatedServer() && client ==0 || client < 0) return Plugin_Continue;
	if (!IsClientConnected(client)) return Plugin_Continue;
	if (!IsClientInGame(client)) return Plugin_Continue;
	if (IsFakeClient(client)) return Plugin_Continue;
	if (GetClientTeam(client)!=2) return Plugin_Continue;
	if (buttons & IN_SPEED && buttons & IN_ATTACK2)
	{
		if (buttondelay[client]) return Plugin_Continue;
		buttondelay[client]=true;
		CreateTimer(1.0,ResetDelay,client);
		if (parenting[client]!=0)
		{
			if (!(GetEntityFlags(client) & (FL_ONGROUND))) return Plugin_Continue;
			if (IsValidEntRef(parenting[client]))
			{
				AcceptEntityInput(parenting[client], "kill");
			}
			parenting[client]=0;
			if (StrEqual(EntityName[client], "prop_minigun") )
			{
				if (!l4d2)
				{
					CreateMiniGun(client,0);
				}
				else
				{
					CreateMiniGun(client,1);
				}
			}
			else
			{
				CreateMiniGun(client,0);
			}
			Format(EntityName[client], 64, "");
			return Plugin_Continue;
		}
		new target = GetClientAimTarget(client,false);
		decl String:model[128];
		decl String:item[64];
		if(target != -1) {
			if (IsValidEntRef(target))
			{
				decl Float:PlayerVec[3];
				GetClientAbsOrigin(client, PlayerVec);
				decl Float:LockerVec[3];
				GetEntPropVector(target, Prop_Data, "m_vecOrigin", LockerVec);
				if (GetVectorDistance(PlayerVec, LockerVec) <= 100)
				{
					GetEntPropString(target, Prop_Data, "m_ModelName", model, sizeof(model));
					GetEdictClassname(target, item, sizeof(item));
					if (StrEqual(item, "prop_minigun") || StrEqual(item, "prop_minigun_l4d1") )
					{
						new Owner=GetEntPropEnt(target, Prop_Send, "m_owner");
						if (Owner ==0 && IsDedicatedServer() || Owner <0 ||Owner > GetMaxClients())
						{
							Format(EntityName[client], 64, item);
							if (parenting[client]!=0) return Plugin_Continue;
							AcceptEntityInput(target, "kill");
							decl Float:VecOrigin[3], Float:VecAngles[3], Float:VecDirection[3];
							new index = CreateEntityByName ( "prop_dynamic");
							if (index == -1)
							{
								ReplyToCommand(client, "[SM] Failed to create minigun!");
								return Plugin_Continue;
							}
							if (StrEqual(item, "prop_minigun") )
							{
								if (l4d2)
								{
									SetEntityModel (index, "models/w_models/weapons/50cal.mdl");
								}
								else
								{
									SetEntityModel (index, "models/w_models/weapons/w_minigun.mdl");
								}
							}
							else
							{
								SetEntityModel (index, "models/w_models/weapons/w_minigun.mdl");
							}
							DispatchSpawn(index);
							GetClientAbsOrigin(client, VecOrigin);
							GetClientEyeAngles(client, VecAngles);
							GetAngleVectors(VecAngles, VecDirection, NULL_VECTOR, NULL_VECTOR);
							VecOrigin[0] += VecDirection[0] * 32;
							VecOrigin[1] += VecDirection[1] * 32;
							VecOrigin[2] += VecDirection[2] * 1;   
							VecAngles[0] = 0.0;
							VecAngles[2] = 0.0;
							DispatchKeyValueVector(index, "Angles", VecAngles);
							TeleportEntity(index, VecOrigin, NULL_VECTOR, NULL_VECTOR);
							SetEntProp(index, Prop_Data, "m_CollisionGroup", 2);
							SetEntityRenderMode(index, RenderMode:3);
							SetEntityRenderColor(index, 255, 0, 0, 150);
							decl String:sTemp[64];
							Format(sTemp, sizeof(sTemp), "mmg%d%d", index, client);
							DispatchKeyValue(client, "targetname", sTemp);
							SetVariantString(sTemp);
							AcceptEntityInput(index, "SetParent", index, index, 0);
							SetVariantString("eyes");
							AcceptEntityInput(index, "SetParentAttachment");
							VecOrigin[0]=0.0;
							VecOrigin[1]=0.0;
							VecOrigin[2]=-10.0;
							TeleportEntity(index, VecOrigin, NULL_VECTOR, NULL_VECTOR);
							parenting[client]=index;
							return Plugin_Continue;
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}