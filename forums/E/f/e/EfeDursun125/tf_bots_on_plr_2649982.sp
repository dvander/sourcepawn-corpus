#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>

new Float:flag_pos[3];
new Float:flag_pos2[3];
new Float:flag_pos3[3];
new Float:flag_pos4[3];

public Plugin:myinfo=
{
	name= "TFBots on PLR",
	author= "tRololo312312, edited by EfeDursun125",
	description= "Allows Bots to play Payload Race.",
	version= "1.4",
	url= "https://steamcommunity.com/id/EfeDursun91/"
}

public OnPluginStart()
{
	HookEvent("teamplay_round_start", RoundStarted);
}

public OnMapStart()
{
	char currentMap[PLATFORM_MAX_PATH];
	GetCurrentMap(currentMap, sizeof(currentMap));

	if(StrContains(currentMap, "plr_" , false) != -1)
	{
		CreateTimer(0.1, MoveTimer,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(0.1, FindFlag,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:OnFlagTouch(point, client)
{
	for(client=1;client<=MaxClients;client++)
	{
		if(IsClientInGame(client))
		{
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public Action:RoundStarted(Handle: event , const String: name[] , bool: dontBroadcast)
{
	char currentMap[PLATFORM_MAX_PATH];
	GetCurrentMap(currentMap, sizeof(currentMap));

	if(StrContains(currentMap, "plr_" , false) != -1)
	{
		CreateTimer(0.1, LoadStuff);
		CreateTimer(0.1, LoadStuff2);
	}
}

public Action:LoadStuff(Handle:timer)
{
	decl String:nameblue[] = "bluebotflag";
	decl String:classblue[] = "item_teamflag";
	new ent = FindEntityByTargetname(nameblue, classblue);
	if(ent != -1)
	{
		//Do nothing.
	}
	else
	{
		new teamflags = CreateEntityByName("item_teamflag");
		if(IsValidEntity(teamflags))
		{
			DispatchKeyValue(teamflags, "targetname", "bluebotflag");
			DispatchKeyValue(teamflags, "trail_effect", "0");
			DispatchKeyValue(teamflags, "ReturnTime", "1");
			DispatchKeyValue(teamflags, "flag_model", "models/empty.mdl");
			DispatchSpawn(teamflags);
			SetEntProp(teamflags, Prop_Send, "m_iTeamNum", 3);
		}
	}
}

public Action:LoadStuff2(Handle:timer)
{
	decl String:namered[] = "redbotflag";
	decl String:classred[] = "item_teamflag";
	new ent = FindEntityByTargetname(namered, classred);
	if(ent != -1)
	{
		//Do nothing.
	}
	else
	{
		new teamflags2 = CreateEntityByName("item_teamflag");
		if(IsValidEntity(teamflags2))
		{
			DispatchKeyValue(teamflags2, "targetname", "redbotflag");
			DispatchKeyValue(teamflags2, "trail_effect", "0");
			DispatchKeyValue(teamflags2, "ReturnTime", "1");
			DispatchKeyValue(teamflags2, "flag_model", "models/empty.mdl");
			DispatchSpawn(teamflags2);
			SetEntProp(teamflags2, Prop_Send, "m_iTeamNum", 2);
		}
	}
}

public Action:FindFlag(Handle:timer)
{
	new ent = -1;
	while ((ent = FindEntityByClassname(ent, "item_teamflag"))!=INVALID_ENT_REFERENCE)
	{
		SDKHook(ent, SDKHook_StartTouch, OnFlagTouch );
		SDKHook(ent, SDKHook_Touch, OnFlagTouch );
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3])
{
	if(IsValidClient(client))
	{
		if(IsFakeClient(client))
		{
			if(IsPlayerAlive(client))
			{
				char currentMap[PLATFORM_MAX_PATH];
				GetCurrentMap(currentMap, sizeof(currentMap));

				if(StrContains(currentMap, "plr_" , false) != -1)
				{
					new TFClassType:class3 = TF2_GetPlayerClass(client);
					decl Float:clientOrigin[3];
					GetClientAbsOrigin(client, clientOrigin);
					new CurrentHealth = GetEntProp(client, Prop_Send, "m_iHealth");
					new MaxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
					
					if(CurrentHealth < MaxHealth)
					{
						int healthkit = GetNearestEntity(client, "item_healthkit_*"); 
						
						if(healthkit != -1)
						{
							if(IsValidEntity(healthkit))
							{
								if (GetEntProp(healthkit, Prop_Send, "m_fEffects") != 0)
								{
									return Plugin_Continue;
								}
		
								new Float:healthkitorigin[3];
								GetEntPropVector(healthkit, Prop_Send, "m_vecOrigin", healthkitorigin);
								
								clientOrigin[2] += 5.0;
								healthkitorigin[2] += 5.0;
								
								if(IsPointVisible(clientOrigin, healthkitorigin))
								{
									TF2_MoveTo(client, healthkitorigin, vel, angles);
								}
							}
						}
					}
				
					if(class3 == TFClass_Spy && TF2_IsPlayerInCondition(client, TFCond_Disguised) && IsWeaponSlotActive(client, 0))
					{
						if(buttons & IN_ATTACK)
						{
							buttons &= ~IN_ATTACK;
						}
					}
				
					if(class3 == TFClass_Spy && GetHealth(client) > 100.0 && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
					{
						if(buttons & IN_ATTACK2)
						{
							buttons &= ~IN_ATTACK2;
						}
					}
					
					if(class3 == TFClass_Spy && GetHealth(client) < 75.0 && !TF2_IsPlayerInCondition(client, TFCond_Disguised) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
					{
						buttons |= IN_ATTACK2;
					}
					
					if(class3 == TFClass_Spy && GetHealth(client) < 35.0 && TF2_IsPlayerInCondition(client, TFCond_Disguising) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
					{
						buttons |= IN_ATTACK2;
					}
					
					if(class3 == TFClass_Spy && !IsWeaponSlotActive(client, 0))
					{
						TF2_RemoveWeaponSlot(client, 0);
					}
					
					if(class3 == TFClass_Spy && IsWeaponSlotActive(client, 2))
					{
						if(GetEntProp(GetPlayerWeaponSlot(client, TFWeaponSlot_Melee), Prop_Send, "m_bReadyToBackstab") && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
						{
							buttons |= IN_ATTACK;
						}
						else
						{
							if(buttons & IN_ATTACK)
							{
								buttons &= ~IN_ATTACK;
							}
						}
					}
				}
				
				if(StrContains(currentMap, "plr_hightower" , false) != -1)
				{
					new Cart;
					decl Float:clientEyes[3];
					GetClientEyePosition(client, clientEyes);
					while((Cart = FindEntityByClassname(Cart, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
					{
						new iTeamNumObj = GetEntProp(Cart, Prop_Send, "m_iTeamNum");
						if(IsValidEntity(Cart) && GetClientTeam(client) == iTeamNumObj)
						{
							new TFClassType:class3 = TF2_GetPlayerClass(client);
							new Float:CartPos2[3];
							GetEntPropVector(Cart, Prop_Data, "m_vecAbsOrigin", CartPos2);
							new Float:Distance3;
							Distance3 = GetVectorDistance(clientEyes, CartPos2);
							if(class3 != TFClass_Medic && class3 != TFClass_Spy && class3 != TFClass_Sniper && class3 != TFClass_Scout && class3 != TFClass_Engineer)
							{
								if(Distance3 < 300.0)
								{
									TF2_MoveTo(client, CartPos2, vel, angles);
									if(class3 == TFClass_Heavy)
									{
										buttons |= IN_ATTACK2;
									}
								}
							}
						}
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

stock int GetObjTeam(int entity)
{
	return GetEntProp(entity, Prop_Send, "m_iTeamNum");
}

stock bool:IsWeaponSlotActive(iClient, iSlot)
{
    return GetPlayerWeaponSlot(iClient, iSlot) == GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
}

stock GetHealth(client)
{
	return GetEntProp(client, Prop_Send, "m_iHealth");
}

bool:IsValidClient( client ) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}

public Action:MoveTimer(Handle:timer)
{
	decl String:namered[] = "redbotflag";
	decl String:classred[] = "item_teamflag";
	decl String:nameblue[] = "bluebotflag";
	decl String:classblue[] = "item_teamflag";
	new cartEnt2 = -1;
	new cartEnt = -1;
	new random = GetRandomInt(1,24);
	switch(random)
	{
		case 1:
		{
			while((cartEnt = FindEntityByClassname(cartEnt, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				new iTeamNumCart = GetEntProp(cartEnt, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 2)
				{
					GetEntPropVector(cartEnt, Prop_Data, "m_vecAbsOrigin", flag_pos);
					new ent = FindEntityByTargetname(nameblue, classblue);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
			while((cartEnt2 = FindEntityByClassname(cartEnt2, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				new iTeamNumCart = GetEntProp(cartEnt2, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 3)
				{
					GetEntPropVector(cartEnt2, Prop_Data, "m_vecAbsOrigin", flag_pos2);
					new ent = FindEntityByTargetname(namered, classred);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos2, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
		}
		case 2:
		{
			for(new client=1;client<=MaxClients;client++)
			{
				if(IsClientInGame(client))
				{
					if(IsPlayerAlive(client))
					{
						new ent = FindEntityByTargetname(nameblue, classblue);
						new ent2 = FindEntityByTargetname(namered, classred);
						new team = GetClientTeam(client);
						if(ent2 != -1)
						{
							if(team == 2)
							{
								GetClientAbsOrigin(client, flag_pos3);
								TeleportEntity(ent2, flag_pos3, NULL_VECTOR, NULL_VECTOR);
							}
						}
						if(ent != -1)
						{
							if(team == 3)
							{
								GetClientAbsOrigin(client, flag_pos4);
								TeleportEntity(ent, flag_pos4, NULL_VECTOR, NULL_VECTOR);
							}
						}
					}
				}
			}
		}
		case 3:
		{
			while((cartEnt = FindEntityByClassname(cartEnt, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				new iTeamNumCart = GetEntProp(cartEnt, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 2)
				{
					GetEntPropVector(cartEnt, Prop_Data, "m_vecAbsOrigin", flag_pos);
					new ent = FindEntityByTargetname(nameblue, classblue);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
			for(new client=1;client<=MaxClients;client++)
			{
				if(IsClientInGame(client))
				{
					if(IsPlayerAlive(client))
					{
						new ent2 = FindEntityByTargetname(namered, classred);
						new team = GetClientTeam(client);
						if(ent2 != -1)
						{
							if(team == 2)
							{
								GetClientAbsOrigin(client, flag_pos3);
								TeleportEntity(ent2, flag_pos3, NULL_VECTOR, NULL_VECTOR);
							}
						}
					}
				}
			}
		}
		case 4:
		{
			while((cartEnt2 = FindEntityByClassname(cartEnt2, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				new iTeamNumCart = GetEntProp(cartEnt2, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 3)
				{
					GetEntPropVector(cartEnt2, Prop_Data, "m_vecAbsOrigin", flag_pos2);
					new ent = FindEntityByTargetname(namered, classred);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos2, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
			for(new client=1;client<=MaxClients;client++)
			{
				if(IsClientInGame(client))
				{
					if(IsPlayerAlive(client))
					{
						new ent = FindEntityByTargetname(nameblue, classblue);
						new team = GetClientTeam(client);
						if(ent != -1)
						{
							if(team == 3)
							{
								GetClientAbsOrigin(client, flag_pos4);
								TeleportEntity(ent, flag_pos4, NULL_VECTOR, NULL_VECTOR);
							}
						}
					}
				}
			}
		}
		case 5:
		{
			while((cartEnt = FindEntityByClassname(cartEnt, "obj_dispenser")) != INVALID_ENT_REFERENCE)
			{
				new iTeamNumCart = GetEntProp(cartEnt, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 2)
				{
					GetEntPropVector(cartEnt, Prop_Data, "m_vecAbsOrigin", flag_pos);
					new ent = FindEntityByTargetname(nameblue, classblue);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
			while((cartEnt2 = FindEntityByClassname(cartEnt2, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				new iTeamNumCart = GetEntProp(cartEnt2, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 3)
				{
					GetEntPropVector(cartEnt2, Prop_Data, "m_vecAbsOrigin", flag_pos2);
					new ent2 = FindEntityByTargetname(namered, classred);
					if(ent2 != -1)
					{
						TeleportEntity(ent2, flag_pos2, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
		}
		case 6:
		{
			while((cartEnt = FindEntityByClassname(cartEnt, "obj_dispenser")) != INVALID_ENT_REFERENCE)
			{
				new iTeamNumCart = GetEntProp(cartEnt, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 3)
				{
					GetEntPropVector(cartEnt, Prop_Data, "m_vecAbsOrigin", flag_pos2);
					new ent = FindEntityByTargetname(namered, classred);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos2, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
			while((cartEnt2 = FindEntityByClassname(cartEnt2, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				new iTeamNumCart = GetEntProp(cartEnt2, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 2)
				{
					GetEntPropVector(cartEnt2, Prop_Data, "m_vecAbsOrigin", flag_pos);
					new ent2 = FindEntityByTargetname(nameblue, classblue);
					if(ent2 != -1)
					{
						TeleportEntity(ent2, flag_pos, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
		}
		case 7:
		{
			while((cartEnt = FindEntityByClassname(cartEnt, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				new iTeamNumCart = GetEntProp(cartEnt, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 3)
				{
					GetEntPropVector(cartEnt, Prop_Data, "m_vecAbsOrigin", flag_pos);
					new ent = FindEntityByTargetname(nameblue, classblue);
					flag_pos[0] += GetRandomFloat(-1000.0, 1000.0);
					flag_pos[1] += GetRandomFloat(-1000.0, 1000.0);
					flag_pos[2] += GetRandomFloat(-1000.0, 1000.0);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
			while((cartEnt2 = FindEntityByClassname(cartEnt2, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				new iTeamNumCart = GetEntProp(cartEnt2, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 3)
				{
					GetEntPropVector(cartEnt2, Prop_Data, "m_vecAbsOrigin", flag_pos2);
					new ent = FindEntityByTargetname(namered, classred);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos2, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
		}
		case 8:
		{
			while((cartEnt = FindEntityByClassname(cartEnt, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				new iTeamNumCart = GetEntProp(cartEnt, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 2)
				{
					GetEntPropVector(cartEnt, Prop_Data, "m_vecAbsOrigin", flag_pos);
					new ent = FindEntityByTargetname(nameblue, classblue);
					flag_pos[0] += GetRandomFloat(-1000.0, 1000.0);
					flag_pos[1] += GetRandomFloat(-1000.0, 1000.0);
					flag_pos[2] += GetRandomFloat(-1000.0, 1000.0);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
			while((cartEnt2 = FindEntityByClassname(cartEnt2, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				new iTeamNumCart = GetEntProp(cartEnt2, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 2)
				{
					GetEntPropVector(cartEnt2, Prop_Data, "m_vecAbsOrigin", flag_pos2);
					new ent = FindEntityByTargetname(namered, classred);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos2, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
		}
		case 9:
		{
			while((cartEnt = FindEntityByClassname(cartEnt, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				new iTeamNumCart = GetEntProp(cartEnt, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 3)
				{
					GetEntPropVector(cartEnt, Prop_Data, "m_vecAbsOrigin", flag_pos);
					new ent = FindEntityByTargetname(nameblue, classblue);
					flag_pos[0] += GetRandomFloat(-1000.0, 1000.0);
					flag_pos[1] += GetRandomFloat(-1000.0, 1000.0);
					flag_pos[2] += GetRandomFloat(-1000.0, 1000.0);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
			while((cartEnt2 = FindEntityByClassname(cartEnt2, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				new iTeamNumCart = GetEntProp(cartEnt2, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 2)
				{
					GetEntPropVector(cartEnt2, Prop_Data, "m_vecAbsOrigin", flag_pos2);
					new ent = FindEntityByTargetname(namered, classred);
					flag_pos2[0] += GetRandomFloat(-1000.0, 1000.0);
					flag_pos2[1] += GetRandomFloat(-1000.0, 1000.0);
					flag_pos2[2] += GetRandomFloat(-1000.0, 1000.0);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos2, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
		}
		case 10:
		{
			for(new client=1;client<=MaxClients;client++)
			{
				if(IsClientInGame(client))
				{
					if(IsPlayerAlive(client))
					{
						new ent = FindEntityByTargetname(nameblue, classblue);
						new ent2 = FindEntityByTargetname(namered, classred);
						new team = GetClientTeam(client);
						if(ent2 != -1)
						{
							if(team == 3)
							{
								GetClientAbsOrigin(client, flag_pos3);
								TeleportEntity(ent2, flag_pos3, NULL_VECTOR, NULL_VECTOR);
							}
						}
						if(ent != -1)
						{
							if(team == 3)
							{
								GetClientAbsOrigin(client, flag_pos3);
								TeleportEntity(ent, flag_pos3, NULL_VECTOR, NULL_VECTOR);
							}
						}
					}
				}
			}
		}
		case 11:
		{
			for(new client=1;client<=MaxClients;client++)
			{
				if(IsClientInGame(client))
				{
					if(IsPlayerAlive(client))
					{
						new ent = FindEntityByTargetname(nameblue, classblue);
						new ent2 = FindEntityByTargetname(namered, classred);
						new team = GetClientTeam(client);
						if(ent2 != -1)
						{
							if(team == 2)
							{
								GetClientAbsOrigin(client, flag_pos3);
								TeleportEntity(ent2, flag_pos3, NULL_VECTOR, NULL_VECTOR);
							}
						}
						if(ent != -1)
						{
							if(team == 2)
							{
								GetClientAbsOrigin(client, flag_pos3);
								TeleportEntity(ent2, flag_pos3, NULL_VECTOR, NULL_VECTOR);
							}
						}
					}
				}
			}
		}
		case 12:
		{
			while((cartEnt = FindEntityByClassname(cartEnt, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				new iTeamNumCart = GetEntProp(cartEnt, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 2)
				{
					GetEntPropVector(cartEnt, Prop_Data, "m_vecAbsOrigin", flag_pos);
					new ent = FindEntityByTargetname(nameblue, classblue);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
			while((cartEnt2 = FindEntityByClassname(cartEnt2, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				new iTeamNumCart = GetEntProp(cartEnt2, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 3)
				{
					GetEntPropVector(cartEnt2, Prop_Data, "m_vecAbsOrigin", flag_pos2);
					new ent = FindEntityByTargetname(namered, classred);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos2, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
		}
		case 13:
		{
			for(new client=1;client<=MaxClients;client++)
			{
				if(IsClientInGame(client))
				{
					if(IsPlayerAlive(client))
					{
						new ent = FindEntityByTargetname(nameblue, classblue);
						new ent2 = FindEntityByTargetname(namered, classred);
						new team = GetClientTeam(client);
						if(ent2 != -1)
						{
							if(team == 2)
							{
								GetClientAbsOrigin(client, flag_pos3);
								TeleportEntity(ent2, flag_pos3, NULL_VECTOR, NULL_VECTOR);
							}
						}
						if(ent != -1)
						{
							if(team == 3)
							{
								GetClientAbsOrigin(client, flag_pos4);
								TeleportEntity(ent, flag_pos4, NULL_VECTOR, NULL_VECTOR);
							}
						}
					}
				}
			}
		}
		case 14:
		{
			while((cartEnt = FindEntityByClassname(cartEnt, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				new iTeamNumCart = GetEntProp(cartEnt, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 2)
				{
					GetEntPropVector(cartEnt, Prop_Data, "m_vecAbsOrigin", flag_pos);
					new ent = FindEntityByTargetname(nameblue, classblue);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
			while((cartEnt2 = FindEntityByClassname(cartEnt2, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				new iTeamNumCart = GetEntProp(cartEnt2, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 3)
				{
					GetEntPropVector(cartEnt2, Prop_Data, "m_vecAbsOrigin", flag_pos2);
					new ent = FindEntityByTargetname(namered, classred);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos2, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
		}
		case 15:
		{
			while((cartEnt = FindEntityByClassname(cartEnt, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				new iTeamNumCart = GetEntProp(cartEnt, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 2)
				{
					GetEntPropVector(cartEnt, Prop_Data, "m_vecAbsOrigin", flag_pos);
					new ent = FindEntityByTargetname(nameblue, classblue);
					flag_pos[0] += GetRandomFloat(-1000.0, 1000.0);
					flag_pos[1] += GetRandomFloat(-1000.0, 1000.0);
					flag_pos[2] += GetRandomFloat(-1000.0, 1000.0);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
			for(new client=1;client<=MaxClients;client++)
			{
				if(IsClientInGame(client))
				{
					if(IsPlayerAlive(client))
					{
						new ent2 = FindEntityByTargetname(namered, classred);
						new team = GetClientTeam(client);
						if(ent2 != -1)
						{
							if(team == 2)
							{
								GetClientAbsOrigin(client, flag_pos3);
								TeleportEntity(ent2, flag_pos3, NULL_VECTOR, NULL_VECTOR);
							}
						}
					}
				}
			}
		}
		case 16:
		{
			while((cartEnt = FindEntityByClassname(cartEnt, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				new iTeamNumCart = GetEntProp(cartEnt, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 2)
				{
					GetEntPropVector(cartEnt, Prop_Data, "m_vecAbsOrigin", flag_pos);
					new ent = FindEntityByTargetname(nameblue, classblue);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
			while((cartEnt2 = FindEntityByClassname(cartEnt2, "func_capturezone")) != INVALID_ENT_REFERENCE)
			{
				GetEntPropVector(cartEnt2, Prop_Data, "m_vecAbsOrigin", flag_pos2);
				new ent = FindEntityByTargetname(namered, classred);
				if(ent != -1)
				{
					TeleportEntity(ent, flag_pos2, NULL_VECTOR, NULL_VECTOR);
				}
			}
		}
		case 17:
		{
			while((cartEnt2 = FindEntityByClassname(cartEnt2, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				new iTeamNumCart = GetEntProp(cartEnt2, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 3)
				{
					GetEntPropVector(cartEnt2, Prop_Data, "m_vecAbsOrigin", flag_pos2);
					new ent = FindEntityByTargetname(namered, classred);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos2, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
			while((cartEnt = FindEntityByClassname(cartEnt, "func_capturezone")) != INVALID_ENT_REFERENCE)
			{
				GetEntPropVector(cartEnt, Prop_Data, "m_vecAbsOrigin", flag_pos2);
				new ent = FindEntityByTargetname(namered, classred);
				if(ent != -1)
				{
					TeleportEntity(ent, flag_pos, NULL_VECTOR, NULL_VECTOR);
				}
			}
		}
		case 18:
		{
			while((cartEnt = FindEntityByClassname(cartEnt, "obj_attachment_sapper")) != INVALID_ENT_REFERENCE)
			{
				new iTeamNumCart = GetEntProp(cartEnt, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 3)
				{
					GetEntPropVector(cartEnt, Prop_Data, "m_vecAbsOrigin", flag_pos);
					new ent = FindEntityByTargetname(nameblue, classblue);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
			while((cartEnt2 = FindEntityByClassname(cartEnt2, "obj_attachment_sapper")) != INVALID_ENT_REFERENCE)
			{
				new iTeamNumCart = GetEntProp(cartEnt2, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 2)
				{
					GetEntPropVector(cartEnt2, Prop_Data, "m_vecAbsOrigin", flag_pos2);
					new ent = FindEntityByTargetname(namered, classred);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos2, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
		}
		case 19:
		{
			while((cartEnt = FindEntityByClassname(cartEnt, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				new iTeamNumCart = GetEntProp(cartEnt, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 2)
				{
					GetEntPropVector(cartEnt, Prop_Data, "m_vecAbsOrigin", flag_pos);
					new ent = FindEntityByTargetname(nameblue, classblue);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
			while((cartEnt2 = FindEntityByClassname(cartEnt2, "item_healthkit_full")) != INVALID_ENT_REFERENCE)
			{
				GetEntPropVector(cartEnt2, Prop_Data, "m_vecAbsOrigin", flag_pos2);
				new ent = FindEntityByTargetname(namered, classred);
				if(ent != -1)
				{
					TeleportEntity(ent, flag_pos2, NULL_VECTOR, NULL_VECTOR);
				}
			}
		}
		case 20:
		{
			while((cartEnt = FindEntityByClassname(cartEnt, "item_healthkit_full")) != INVALID_ENT_REFERENCE)
			{
				GetEntPropVector(cartEnt, Prop_Data, "m_vecAbsOrigin", flag_pos);
				new ent = FindEntityByTargetname(nameblue, classblue);
				if(ent != -1)
				{
					TeleportEntity(ent, flag_pos, NULL_VECTOR, NULL_VECTOR);
				}
			}
			while((cartEnt2 = FindEntityByClassname(cartEnt2, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				new iTeamNumCart = GetEntProp(cartEnt2, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 3)
				{
					GetEntPropVector(cartEnt2, Prop_Data, "m_vecAbsOrigin", flag_pos2);
					new ent = FindEntityByTargetname(namered, classred);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos2, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
		}
		case 21:
		{
			while((cartEnt = FindEntityByClassname(cartEnt, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				new iTeamNumCart = GetEntProp(cartEnt, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 2)
				{
					GetEntPropVector(cartEnt, Prop_Data, "m_vecAbsOrigin", flag_pos);
					new ent = FindEntityByTargetname(nameblue, classblue);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
		}
		case 22:
		{
			while((cartEnt2 = FindEntityByClassname(cartEnt2, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				new iTeamNumCart = GetEntProp(cartEnt2, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 3)
				{
					GetEntPropVector(cartEnt2, Prop_Data, "m_vecAbsOrigin", flag_pos2);
					new ent = FindEntityByTargetname(namered, classred);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos2, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
		}
		case 23:
		{
			while((cartEnt = FindEntityByClassname(cartEnt, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				new iTeamNumCart = GetEntProp(cartEnt, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 2)
				{
					GetEntPropVector(cartEnt, Prop_Data, "m_vecAbsOrigin", flag_pos);
					new ent = FindEntityByTargetname(nameblue, classblue);
					flag_pos[0] += GetRandomFloat(-1000.0, 1000.0);
					flag_pos[1] += GetRandomFloat(-1000.0, 1000.0);
					flag_pos[2] += GetRandomFloat(-1000.0, 1000.0);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
		}
		case 24:
		{
			while((cartEnt2 = FindEntityByClassname(cartEnt2, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
			{
				new iTeamNumCart = GetEntProp(cartEnt2, Prop_Send, "m_iTeamNum");
				if (iTeamNumCart == 3)
				{
					GetEntPropVector(cartEnt2, Prop_Data, "m_vecAbsOrigin", flag_pos2);
					new ent = FindEntityByTargetname(namered, classred);
					flag_pos2[0] += GetRandomFloat(-1000.0, 1000.0);
					flag_pos2[1] += GetRandomFloat(-1000.0, 1000.0);
					flag_pos2[2] += GetRandomFloat(-1000.0, 1000.0);
					if(ent != -1)
					{
						TeleportEntity(ent, flag_pos2, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
		}
	}
}

public int GetNearestEntity(int client, char[] classname) // https://forums.alliedmods.net/showthread.php?t=318542
{
    int nearestEntity = -1;
    float clientVecOrigin[3], entityVecOrigin[3];
    
    //Get the distance between the first entity and client
    float distance, nearestDistance = -1.0;
    
    //Find all the entity and compare the distances
    int entity = -1;
    while ((entity = FindEntityByClassname(entity, classname)) != -1)
    {
        GetEntPropVector(entity, Prop_Data, "m_vecOrigin", entityVecOrigin);
        distance = GetVectorDistance(clientVecOrigin, entityVecOrigin);
        
        if (distance < nearestDistance || nearestDistance == -1.0)
        {
            nearestEntity = entity;
            nearestDistance = distance;
        }
    }
    
    return nearestEntity;
}

stock void TF2_MoveTo(int client, float flGoal[3], float fVel[3], float fAng[3]) // Stock By Pelipokia
{
    float flPos[3];
    GetClientAbsOrigin(client, flPos);

    float newmove[3];
    SubtractVectors(flGoal, flPos, newmove);
    
    newmove[1] = -newmove[1];
    
    float sin = Sine(fAng[1] * FLOAT_PI / 180.0);
    float cos = Cosine(fAng[1] * FLOAT_PI / 180.0);                        
    
    fVel[0] = cos * newmove[0] - sin * newmove[1];
    fVel[1] = sin * newmove[0] + cos * newmove[1];
    
    NormalizeVector(fVel, fVel);
    ScaleVector(fVel, 450.0);
}

stock bool:IsPointVisible(const Float:start[3], const Float:end[3])
{
	TR_TraceRayFilter(start, end, MASK_SOLID_BRUSHONLY, RayType_EndPoint, TraceEntityFilterStuff);
	return TR_GetFraction() >= 0.99;
}

public bool:TraceEntityFilterStuff(entity, mask)
{
	return entity > MaxClients;
}

stock FindEntityByTargetname(const String:targetname[], const String:classname[])
{
  decl String:namebuf[32];
  new index = -1;
  namebuf[0] = '\0';
 
  while(strcmp(namebuf, targetname) != 0
    && (index = FindEntityByClassname(index, classname)) != -1)
    GetEntPropString(index, Prop_Data, "m_iName", namebuf, sizeof(namebuf));
 
  return(index);
}