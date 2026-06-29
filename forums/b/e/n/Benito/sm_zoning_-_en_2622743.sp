#pragma semicolon 1


#define PLUGIN_AUTHOR "Benito"
#define PLUGIN_VERSION "1.00"
#define MaxEntities	2048

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <smlib>
#include <sdkhooks>

new Float:zoning[MAXPLAYERS+1][9][3];

public Plugin:myinfo =
{
	name = "Zoning Menu",
	author = PLUGIN_AUTHOR,
	description = "Get Coordinates of Zoning Points",
	version = PLUGIN_VERSION,
	url = "https://revolution-team.fr/"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_zoning", Command_AdminZone);
}

public Action:Command_AdminZone(client, args)
{
	if (IsValidAndAlive(client))
	{
		if (GetUserFlagBits(client) & ADMFLAG_ROOT)
		{
			BuildAdminZone(client);
		}
	}
	
	return Plugin_Handled;
}

BuildAdminZone(client)
{
	new Handle:zoneMenu = CreateMenu(Menu_Admin);
	
	SetMenuTitle(zoneMenu, "-=| ZONING |=- :");
	AddMenuItem(zoneMenu, "zone", "Zoning");
	
	DisplayMenu(zoneMenu, client, MENU_TIME_FOREVER);
}

public Menu_Admin(Handle:zoneMenu, MenuAction:action, client, param)
{
	if (action == MenuAction_Select)
	{
		decl String:info[32];
		GetMenuItem(zoneMenu, param, info, sizeof(info));
		
		if(StrEqual(info, "zone"))
			MenuZoning(client);
	}
	else
	{
		if (action == MenuAction_End)
		{
			CloseHandle(zoneMenu);
		}
	}
}

Handle:MenuZoning(client)
{
	new Handle:menuZoning = CreateMenu(DoMenuZoning);
	SetMenuTitle(menuZoning, "Zoning :");
	if(zoning[client][0][0] == 0.0)
		AddMenuItem(menuZoning, "spawn", "Créer un zoning");
	else
	{
		AddMenuItem(menuZoning, "up", "Ascend");
		AddMenuItem(menuZoning, "down", "Go down");
		AddMenuItem(menuZoning, "leftX", "Move X left");
		AddMenuItem(menuZoning, "rightX", "Move X right");
		AddMenuItem(menuZoning, "leftY", "Move Y left");
		AddMenuItem(menuZoning, "rightY", "Move Y right");
		AddMenuItem(menuZoning, "taille", "Change size");
		AddMenuItem(menuZoning, "inter+", "Add an interval", ITEMDRAW_DISABLED);
		AddMenuItem(menuZoning, "inter-", "Remove an interval", ITEMDRAW_DISABLED);
		AddMenuItem(menuZoning, "coord", "Coordinates");
		AddMenuItem(menuZoning, "delete", "Remove");
	}
	SetMenuExitBackButton(menuZoning, true);
	SetMenuExitButton(menuZoning, true);
	DisplayMenu(menuZoning, client, MENU_TIME_FOREVER);
}

Handle:MenuZoningTaille(client)
{
	if(zoning[client][0][0] == 0.0)
		MenuZoning(client);
	else
	{
		new Handle:menuZoningTaille = CreateMenu(DoMenuZoningTaille);
		SetMenuTitle(menuZoningTaille, "Size of the zoning :");
		AddMenuItem(menuZoningTaille, "up", "Grow");
		AddMenuItem(menuZoningTaille, "down", "Shrink");
		AddMenuItem(menuZoningTaille, "x+", "Grow X");
		AddMenuItem(menuZoningTaille, "x-", "Shrink X");
		AddMenuItem(menuZoningTaille, "y+", "Grow Y");
		AddMenuItem(menuZoningTaille, "y-", "Shrink Y");
		AddMenuItem(menuZoningTaille, "", "Back to move.", ITEMDRAW_DISABLED);
		SetMenuExitBackButton(menuZoningTaille, true);
		SetMenuExitButton(menuZoningTaille, true);
		DisplayMenu(menuZoningTaille, client, MENU_TIME_FOREVER);
	}
}

public DoMenuZoning(Handle:menuZoning, MenuAction:action, client, param)
{
	if(action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menuZoning, param, info, sizeof(info));
		
		if(StrEqual(info, "spawn"))
		{
			zoning[client][0][0] = 1.0; // Disable the spawn
			PointVision(client, zoning[client][1]);
			
			zoning[client][1][2] += 5.0; // Init Z
			
			zoning[client][2] = zoning[client][1];
			zoning[client][2][1] = zoning[client][2][1] + 5.0;
			
			zoning[client][3] = zoning[client][1];
			zoning[client][3][0] = zoning[client][1][0] + 5.0;
			
			zoning[client][4] = zoning[client][2];
			zoning[client][4][0] = zoning[client][1][0] + 5.0;
			
			zoning[client][5] = zoning[client][1];
			zoning[client][5][2] += 5.0;
			
			zoning[client][6] = zoning[client][2];
			zoning[client][6][2] += 5.0;
			
			zoning[client][7] = zoning[client][3];
			zoning[client][7][2] += 5.0;
			
			zoning[client][8] = zoning[client][4];
			zoning[client][8][2] += 5.0;
			
			new String:strName[16], String:strTarget[16];
			Format(strName, sizeof(strName), "laser|1|%i", client);
			Format(strTarget, sizeof(strTarget), "laser|3|%i", client);
			new ent = SpawnLaser(strName, strTarget, "102 204 0");
			TeleportEntity(ent, zoning[client][1], NULL_VECTOR, NULL_VECTOR);
			
			Format(strName, sizeof(strName), "laser|2|%i", client);
			Format(strTarget, sizeof(strTarget), "laser|1|%i", client);
			ent = SpawnLaser(strName, strTarget, "102 204 0");
			TeleportEntity(ent, zoning[client][2], NULL_VECTOR, NULL_VECTOR);
			
			Format(strName, sizeof(strName), "laser|3|%i", client);
			Format(strTarget, sizeof(strTarget), "laser|4|%i", client);
			ent = SpawnLaser(strName, strTarget, "102 204 0");
			TeleportEntity(ent, zoning[client][3], NULL_VECTOR, NULL_VECTOR);
			
			Format(strName, sizeof(strName), "laser|4|%i", client);
			Format(strTarget, sizeof(strTarget), "laser|2|%i", client);
			ent = SpawnLaser(strName, strTarget, "102 204 0");
			TeleportEntity(ent, zoning[client][4], NULL_VECTOR, NULL_VECTOR);
			// 
			Format(strName, sizeof(strName), "laser|5|%i", client);
			Format(strTarget, sizeof(strTarget), "laser|7|%i", client);
			ent = SpawnLaser(strName, strTarget, "102 204 0");
			TeleportEntity(ent, zoning[client][5], NULL_VECTOR, NULL_VECTOR);
			
			Format(strName, sizeof(strName), "laser|6|%i", client);
			Format(strTarget, sizeof(strTarget), "laser|5|%i", client);
			ent = SpawnLaser(strName, strTarget, "102 204 0");
			TeleportEntity(ent, zoning[client][6], NULL_VECTOR, NULL_VECTOR);
			
			Format(strName, sizeof(strName), "laser|7|%i", client);
			Format(strTarget, sizeof(strTarget), "laser|8|%i", client);
			ent = SpawnLaser(strName, strTarget, "102 204 0");
			TeleportEntity(ent, zoning[client][7], NULL_VECTOR, NULL_VECTOR);
			
			Format(strName, sizeof(strName), "laser|8|%i", client);
			Format(strTarget, sizeof(strTarget), "laser|6|%i", client);
			ent = SpawnLaser(strName, strTarget, "102 204 0");
			TeleportEntity(ent, zoning[client][8], NULL_VECTOR, NULL_VECTOR);
			//
			Format(strName, sizeof(strName), "laser|9|%i", client);
			Format(strTarget, sizeof(strTarget), "laser|1|%i", client);
			ent = SpawnLaser(strName, strTarget, "102 204 0");
			TeleportEntity(ent, zoning[client][5], NULL_VECTOR, NULL_VECTOR);
			
			Format(strName, sizeof(strName), "laser|10|%i", client);
			Format(strTarget, sizeof(strTarget), "laser|2|%i", client);
			ent = SpawnLaser(strName, strTarget, "102 204 0");
			TeleportEntity(ent, zoning[client][6], NULL_VECTOR, NULL_VECTOR);
			
			Format(strName, sizeof(strName), "laser|11|%i", client);
			Format(strTarget, sizeof(strTarget), "laser|3|%i", client);
			ent = SpawnLaser(strName, strTarget, "102 204 0");
			TeleportEntity(ent, zoning[client][7], NULL_VECTOR, NULL_VECTOR);
			
			Format(strName, sizeof(strName), "laser|12|%i", client);
			Format(strTarget, sizeof(strTarget), "laser|4|%i", client);
			ent = SpawnLaser(strName, strTarget, "102 204 0");
			TeleportEntity(ent, zoning[client][8], NULL_VECTOR, NULL_VECTOR);
			
			MenuZoning(client);
		}
		else if(StrEqual(info, "up") || StrEqual(info, "down")
		|| StrEqual(info, "leftX") || StrEqual(info, "rightX")
		|| StrEqual(info, "leftY") || StrEqual(info, "rightY"))
		{
			if(StrEqual(info, "up"))
			{
				for(new i = 1; i <= 8; i++)
					zoning[client][i][2] += 5.0;
			}
			else if(StrEqual(info, "down"))
			{
				for(new i = 1; i <= 8; i++)
					zoning[client][i][2] -= 5.0;
			}
			else if(StrEqual(info, "leftX"))
			{
				for(new i = 1; i <= 8; i++)
					zoning[client][i][0] += 5.0;
			}
			else if(StrEqual(info, "rightX"))
			{
				for(new i = 1; i <= 8; i++)
					zoning[client][i][0] -= 5.0;
			}
			else if(StrEqual(info, "leftY"))
			{
				for(new i = 1; i <= 8; i++)
					zoning[client][i][1] += 5.0;
			}
			else if(StrEqual(info, "rightY"))
			{
				for(new i = 1; i <= 8; i++)
					zoning[client][i][1] -= 5.0;
			}
			
			new String:entClass[64], String:entName[64], String:buffer[3][8];
			for(new i = MaxClients; i <= MaxEntities; i++)
			{
				if(IsValidEntity(i))
				{
					Entity_GetClassName(i, entClass, sizeof(entClass));
					if(StrEqual(entClass, "env_laser"))
					{
						Entity_GetName(i, entName, sizeof(entName));
						if(StrContains(entName, "laser") != -1)
						{
							ExplodeString(entName, "|", buffer, 3, 8);
							if(String_IsNumeric(buffer[2]))
							{
								if(StringToInt(buffer[2]) == client)
								{
									new num = StringToInt(buffer[1]);
									switch(num)
									{
										case 9:num = 5;
										case 10:num = 6;
										case 11:num = 7;
										case 12:num = 8;
									}
									if(num <= 12) TeleportEntity(i, zoning[client][num], NULL_VECTOR, NULL_VECTOR);
									else
									{
										new Float:position[3];
										GetEntPropVector(i, Prop_Send, "m_vecOrigin", position);
										
										if(StrEqual(info, "up"))
											position[2] += 5.0;
										else if(StrEqual(info, "down"))
											position[2] -= 5.0;
										else if(StrEqual(info, "leftX"))
											position[0] += 5.0;
										else if(StrEqual(info, "rightX"))
											position[0] -= 5.0;
										else if(StrEqual(info, "leftY"))
											position[1] += 5.0;
										else if(StrEqual(info, "rightY"))
											position[1] -= 5.0;
										TeleportEntity(i, position, NULL_VECTOR, NULL_VECTOR);
									}
								}
							}
						}
					}
				}
			}
			MenuZoning(client);
		}
		else if(StrEqual(info, "taille"))
			MenuZoningTaille(client);
		else if(StrEqual(info, "inter+"))
		{
			zoning[client][0][1] += 1.0;
			if(zoning[client][0][1] == 1.0)
			{
				new Float:position[3], String:strName[16], String:strTarget[16];
				position[0] = zoning[client][1][0];
				position[1] = zoning[client][1][1];
				position[2] = (zoning[client][1][2] + zoning[client][5][2]) / 2.0;
				
				Format(strName, sizeof(strName), "laser|13|%i", client);
				Format(strTarget, sizeof(strTarget), "laser|14|%i", client);
				new ent = SpawnLaser(strName, strTarget, "102 204 0");
				TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
				
				position[0] = zoning[client][2][0];
				position[1] = zoning[client][2][1];
				
				Format(strName, sizeof(strName), "laser|14|%i", client);
				Format(strTarget, sizeof(strTarget), "laser|15|%i", client);
				ent = SpawnLaser(strName, strTarget, "102 204 0");
				TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
				
				position[0] = zoning[client][4][0];
				position[1] = zoning[client][4][1];
				
				Format(strName, sizeof(strName), "laser|15|%i", client);
				Format(strTarget, sizeof(strTarget), "laser|16|%i", client);
				ent = SpawnLaser(strName, strTarget, "102 204 0");
				TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
				
				position[0] = zoning[client][3][0];
				position[1] = zoning[client][3][1];
				
				Format(strName, sizeof(strName), "laser|16|%i", client);
				Format(strTarget, sizeof(strTarget), "laser|13|%i", client);
				ent = SpawnLaser(strName, strTarget, "102 204 0");
				TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
				AcceptEntityInput(ent, "TurnOn");
				// haut :
				position[0] = zoning[client][5][0];
				position[1] = (zoning[client][5][1] + zoning[client][6][1]) / 2.0;
				position[2] = zoning[client][5][2];
				
				Format(strName, sizeof(strName), "laser|17|%i", client);
				Format(strTarget, sizeof(strTarget), "laser|18|%i", client);
				ent = SpawnLaser(strName, strTarget, "102 204 0");
				TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
				
				position[0] = zoning[client][7][0];
				position[2] = zoning[client][7][2];
				
				Format(strName, sizeof(strName), "laser|18|%i", client);
				Format(strTarget, sizeof(strTarget), "laser|17|%i", client);
				ent = SpawnLaser(strName, strTarget, "102 204 0", false);
				TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
				//AcceptEntityInput(ent, "TurnOn");
				// bas :
				position[0] = zoning[client][1][0];
				position[1] = (zoning[client][1][1] + zoning[client][2][1]) / 2.0;
				position[2] = zoning[client][1][2];
				
				Format(strName, sizeof(strName), "laser|19|%i", client);
				Format(strTarget, sizeof(strTarget), "laser|20|%i", client);
				ent = SpawnLaser(strName, strTarget, "102 204 0");
				TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
				
				position[0] = zoning[client][3][0];
				position[2] = zoning[client][3][2];
				
				Format(strName, sizeof(strName), "laser|20|%i", client);
				ent = SpawnLaser(strName, "", "102 204 0", false);
				TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
			}
			MenuZoning(client);
		}
		else if(StrEqual(info, "coord"))
		{
			new String:arg1[64], String:arg2[64],  String:arg3[64], String:arg4[64], String:arg5[64], String:arg6[64];
			if(zoning[client][1][0] < zoning[client][8][0])
			{
				Format(arg1, sizeof(arg1), "%f", zoning[client][1][0]);
				Format(arg2, sizeof(arg2), "%f", zoning[client][8][0]);
			}
			else
			{
				Format(arg1, sizeof(arg1), "%f", zoning[client][8][0]);
				Format(arg2, sizeof(arg2), "%f", zoning[client][1][0]);
			}
			if(zoning[client][1][1] < zoning[client][8][1])
			{
				Format(arg3, sizeof(arg3), "%f", zoning[client][1][1]);
				Format(arg4, sizeof(arg4), "%f", zoning[client][8][1]);
			}
			else
			{
				Format(arg3, sizeof(arg3), "%f", zoning[client][8][1]);
				Format(arg4, sizeof(arg4), "%f", zoning[client][1][1]);
			}
			if(zoning[client][1][2] < zoning[client][8][2])
			{
				Format(arg5, sizeof(arg5), "%f", zoning[client][1][2]);
				Format(arg6, sizeof(arg6), "%f", zoning[client][8][2]);
			}
			else
			{
				Format(arg5, sizeof(arg5), "%f", zoning[client][8][2]);
				Format(arg6, sizeof(arg6), "%f", zoning[client][1][2]);
			}
			
			PrintToChat(client, "position[0] >= %s && position[0] <= %s && position[1] >= %s && position[1] <= %s && position[2] >= %s && position[2] <= %s", arg1, arg2, arg3, arg4, arg5, arg6);
			PrintToConsole(client, "position[0] >= %s && position[0] <= %s && position[1] >= %s && position[1] <= %s && position[2] >= %s && position[2] <= %s", arg1, arg2, arg3, arg4, arg5, arg6);
			
			PrintHintText(client, "Displayed coordinates !\n> Chat & console.");
			MenuZoning(client);
		}
		else if(StrEqual(info, "delete"))
		{
			RemoveLaser(client);
			MenuZoning(client);
		}
	}
	else if(action == MenuAction_End)
		CloseHandle(menuZoning);
}

public DoMenuZoningTaille(Handle:menuZoningTaille, MenuAction:action, client, param)
{
	if(action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menuZoningTaille, param, info, sizeof(info));
		
		if(StrEqual(info, "up"))
		{
			for(new i = 5; i <= 8; i++)
				zoning[client][i][2] += 5.0;
		}
		else if(StrEqual(info, "down"))
		{
			for(new i = 5; i <= 8; i++)
				zoning[client][i][2] -= 5.0;
		}
		else if(StrEqual(info, "x+"))
		{
			zoning[client][1][0] -= 5.0;
			zoning[client][2][0] -= 5.0;
			zoning[client][5][0] -= 5.0;
			zoning[client][6][0] -= 5.0;
		}
		else if(StrEqual(info, "x-"))
		{
			zoning[client][1][0] += 5.0;
			zoning[client][2][0] += 5.0;
			zoning[client][5][0] += 5.0;
			zoning[client][6][0] += 5.0;
		}
		else if(StrEqual(info, "y+"))
		{
			zoning[client][1][1] -= 5.0;
			zoning[client][3][1] -= 5.0;
			zoning[client][5][1] -= 5.0;
			zoning[client][7][1] -= 5.0;
		}
		else if(StrEqual(info, "y-"))
		{
			zoning[client][1][1] += 5.0;
			zoning[client][3][1] += 5.0;
			zoning[client][5][1] += 5.0;
			zoning[client][7][1] += 5.0;
		}
		
		new String:entClass[64], String:entName[64], String:buffer[3][8];
		for(new i = MaxClients; i <= MaxEntities; i++)
		{
			if(IsValidEntity(i))
			{
				Entity_GetClassName(i, entClass, sizeof(entClass));
				if(StrEqual(entClass, "env_laser"))
				{
					Entity_GetName(i, entName, sizeof(entName));
					if(StrContains(entName, "laser") != -1)
					{
						ExplodeString(entName, "|", buffer, 3, 8);
						if(String_IsNumeric(buffer[2]))
						{
							if(StringToInt(buffer[2]) == client)
							{
								new num = StringToInt(buffer[1]);
								switch(num)
								{
									case 9:num = 5;
									case 10:num = 6;
									case 11:num = 7;
									case 12:num = 8;
								}
								if(num <= 12) TeleportEntity(i, zoning[client][num], NULL_VECTOR, NULL_VECTOR);
								else
								{
									new Float:position[3];
									GetEntPropVector(i, Prop_Send, "m_vecOrigin", position);
									
									if(StrEqual(info, "up"))
									{
										if(num == 17 || num == 18)
											position[2] += 5.0;
										else if(num >= 13 && num <= 16)
											position[2] = (zoning[client][1][2] + zoning[client][5][2]) / 2.0;
									}
									else if(StrEqual(info, "down"))
									{
										if(num == 17 || num == 18)
											position[2] -= 5.0;
										else if(num >= 13 && num <= 16)
											position[2] = (zoning[client][1][2] + zoning[client][5][2]) / 2.0;
									}
									else if(StrEqual(info, "x+"))
									{
										if(num == 13 || num == 14 || num == 17 || num == 19)
											position[0] -= 5.0;
									}
									else if(StrEqual(info, "x-"))
									{
										if(num == 13 || num == 14 || num == 17 || num == 19)
											position[0] += 5.0;
									}
									else if(StrEqual(info, "y+"))
									{
										if(num == 13 || num == 16)
											position[1] -= 5.0;
										else if(num == 17 || num == 18)
											position[1] = (zoning[client][5][1] + zoning[client][6][1]) / 2.0;
										else if(num == 19 || num == 20)
											position[1] = (zoning[client][1][1] + zoning[client][2][1]) / 2.0;
									}
									else if(StrEqual(info, "y-"))
									{
										if(num == 13 || num == 16)
											position[1] += 5.0;
										else if(num == 17 || num == 18)
											position[1] = (zoning[client][5][1] + zoning[client][6][1]) / 2.0;
										else if(num == 19 || num == 20)
											position[1] = (zoning[client][1][1] + zoning[client][2][1]) / 2.0;
									}
									TeleportEntity(i, position, NULL_VECTOR, NULL_VECTOR);
								}
							}
						}
					}
				}
			}
		}
		MenuZoningTaille(client);
	}
	else if(action == MenuAction_End)
		CloseHandle(menuZoningTaille);
}

SpawnLaser(String:entName[], String:targetName[], String:color[], bool:turnOn=true)
{
	new ent = CreateEntityByName("env_laser");
	Entity_SetName(ent, entName);
	DispatchKeyValue(ent, "texture", "sprites/laserbeam.vmt");
	DispatchKeyValue(ent, "rendercolor", color);
	DispatchKeyValue(ent, "width", "1");
	DispatchKeyValue(ent, "LaserTarget", targetName);
	DispatchSpawn(ent);
	if(turnOn) AcceptEntityInput(ent, "TurnOn");
	
	return ent;
}

RemoveLaser(client)
{
	for(new i; i <= 8; i++)
	{
		zoning[client][i][0] = 0.0;
		zoning[client][i][1] = 0.0;
		zoning[client][i][2] = 0.0;
	}
	
	new String:entClass2[64], String:entName2[64], String:buffer2[3][8];
	for(new i = MaxClients; i <= MaxEntities; i++)
	{
		if(IsValidEntity(i))
		{
			Entity_GetClassName(i, entClass2, sizeof(entClass2));
			if(StrEqual(entClass2, "env_laser"))
			{
				Entity_GetName(i, entName2, sizeof(entName2));
				if(StrContains(entName2, "laser") != -1)
				{
					ExplodeString(entName2, "|", buffer2, 3, 8);
					if(String_IsNumeric(buffer2[2]))
					{
						if(StringToInt(buffer2[2]) == client)
							AcceptEntityInput(i, "Kill");
					}
				}
			}
		}
	}
}

stock PointVision(client, Float:position[3])
{
	new Float:origin[3], Float:angles[3];
	GetClientEyePosition(client, origin);
	GetClientEyeAngles(client, angles);
	new Handle:trace = TR_TraceRayFilterEx(origin, angles, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer);
	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(position, trace);
		CloseHandle(trace);
		return;
	}
	CloseHandle(trace);
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
	return entity > MaxClients;

public IsValidAndAlive(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client))
		return true;
	else
		return false;
}
