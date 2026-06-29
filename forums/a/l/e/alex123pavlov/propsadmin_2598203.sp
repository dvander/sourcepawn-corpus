#include <sourcemod>
#include <zombiereloaded>
#include <sdktools>
#pragma semicolon 1

#define MAX_MODELS 7

new String:models[MAX_MODELS][PLATFORM_MAX_PATH] = {
		"models/props/cs_office/vending_machine.mdl",
		"models/props/cs_militia/crate_extrasmallmill.mdl",
		"models/props/cs_militia/crate_extralargemill.mdl",
		"models/props/de_inferno/fountain.mdl",
		"models/props/de_inferno/de_inferno_boulder_01.mdl",
		"models/props_c17/lamppost03a_off.mdl",
		"models/props_vehicles/apc001.mdl"
	};
new String:modelsnames[MAX_MODELS][64] = {
		"Автомат с газировкой",
		"Маленькая коробка",
		"Большая коробка",
		"Фонтан",
		"Камень",
		"Фонарный столб",
		"Танк"
	};

public Plugin:myinfo = 
{
	name = "PropsAdmin",
	author = "WeSTMan, edit by KorDen",
	description = "Props Admin ;D",
	version = "1.2+1",
	url = ""
}

new Handle:hMenu;

public OnMapStart()
{
	for( new i = 0; i < MAX_MODELS; i++)
		PrecacheModel(models[i],true);
}

public OnPluginStart()
{
	RegAdminCmd("propsadmin", PropAdminMenu, ADMFLAG_CUSTOM4);
	RegAdminCmd("padmin", PropAdminMenu, ADMFLAG_CUSTOM4);
	
	hMenu = CreateMenu(Handle_PropAdminMenu);
	SetMenuTitle(hMenu, "PropMenu для модераторов \n \n-------------------------");
	AddMenuItem(hMenu, "", "Удалить предмет \n-------------------------\n \n");
	for( new i = 0; i < MAX_MODELS; i++)
		AddMenuItem(hMenu, "", modelsnames[i]);
}

public Action:PropAdminMenu(client, args)
{
	if(!IsPlayerAlive(client) || GetClientTeam(client) < 2 || ZR_IsClientZombie(client))
		PrintToChat(client, "\x01[PROPSADMIN] \x04Вы не можете открыть данное меню!");
	else
		ShowPropAdminMenu(client);

	return Plugin_Handled;
}

ShowPropAdminMenu(client)
{
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public Handle_PropAdminMenu(Handle:hMenuLocal, MenuAction:action, client, iSlot )
{
	if ( action == MenuAction_Select )
	{
		if (ZR_IsClientHuman(client))
		{
			if ( iSlot == 0 )
			{
				if(!IsPlayerAlive(client) || GetClientTeam(client) < 2)
				{
					PrintToChat(client, "\x04Невозможно");
				}
				else
				{
					new iViewEntity = GetClientAimTarget(client, false);
					if ( iViewEntity > MaxClients )
					{
						AcceptEntityInput(iViewEntity, "kill");
						PrintToChatAll("\x04[PROPSADMIN] \x01Модератор \x04%N \x01удалил предмет!", client);
					}
					else
					{
						PrintToChat(client, "\x04[PROPSADMIN] \x01Предмет не найден!");
					}
				}
			}
			else
			{
				prop_dynamic_create(client,models[iSlot-1]);
				PrintToChatAll("\x04[PROPSADMIN] \x01Модератор \x04%N \x01создал %s!", client, modelsnames[iSlot-1]);
			}
			ShowPropAdminMenu(client);
		}
		else
			PrintToChat(client, "\x04[PROPSADMIN] \x01Извините, \x04PROPSADMIN \x01доступен только живым людям!");
	}
}

stock prop_dynamic_create(client, const String:modelname[])
{
	decl Float:VecOrigin[3],
		Float:VecAngles[3],
		Float:normal[3];
	new prop = CreateEntityByName("prop_dynamic_override");
	if (prop != -1)
	{
		DispatchKeyValue(prop, "model", modelname);
		GetClientEyePosition(client, VecOrigin);
		GetClientEyeAngles(client, VecAngles);
		TR_TraceRayFilter(VecOrigin, VecAngles, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelf, client);
		TR_GetEndPosition(VecOrigin);
		TR_GetPlaneNormal(INVALID_HANDLE, normal);
		GetVectorAngles(normal, normal);
		normal[0] += 90.0;
		DispatchKeyValue(prop, "StartDisabled", "false");
		DispatchKeyValue(prop, "Solid", "6");
		DispatchKeyValue(prop, "spawnflags", "8"); 
		SetEntProp(prop, Prop_Data, "m_CollisionGroup", 5);
		TeleportEntity(prop, VecOrigin, normal, NULL_VECTOR);
		DispatchSpawn(prop);
		AcceptEntityInput(prop, "EnableCollision"); 
		AcceptEntityInput(prop, "TurnOn", prop, prop, 0);
	}
}

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	return (entity != data);
}