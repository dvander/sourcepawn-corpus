#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>
#include <sdkhooks>

new g_sprite;
new g_iVelocity;
new GameMode;
new L4D2Version;

#define LEN64 64

new String:ItemName[MAXPLAYERS+1][5][LEN64];
new ItemInfo[MAXPLAYERS+1][5][4];
new ItemAttachEnt[MAXPLAYERS+1][5];
new LastWeapon[MAXPLAYERS+1];
new LastButton[MAXPLAYERS+1];

static String:BackupItemName[MAXPLAYERS+1][5][LEN64];
static BackupItemInfo[MAXPLAYERS+1][5][4];

new Float:InHeal[MAXPLAYERS+1];
new Float:InRevive[MAXPLAYERS+1];
new Float:LastMeSwitchTime[MAXPLAYERS+1];
new Float:SwapTime[MAXPLAYERS+1];
new Float:PressingTime[MAXPLAYERS+1];
new Float:PressStartTime[MAXPLAYERS+1];
new Float:ThrowTime[MAXPLAYERS+1];
new Float:LastSwitchTime[MAXPLAYERS+1];

new bool:Self[MAXPLAYERS+1];
new bool:AfkFix[MAXPLAYERS+1];
new bool:MsgOn[MAXPLAYERS+1];
new bool:ViewOn[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "Multiple Equipment",
	author = "Pan Xiaohai & Marcus101RR & MasterMind420",
	description = "Carry 2 items in each slot",
	version = "3.0",
	url = ""
}

new Handle:l4d_me_slot[5];
new Handle:l4d_me_mode;
new Handle:l4d_me_view;
new Handle:l4d_me_afksave;
new Handle:l4d_me_custom_notify;
new Handle:l4d_me_custom_notify_msg;

new Handle:ME_Notify[MAXPLAYERS+1];
new Handle:Clipping_Fix[MAXPLAYERS+1];
new Handle:Auto_Thirdpersonshoulder_View[MAXPLAYERS+1];

public OnPluginStart()
{
	GameCheck();

	l4d_me_slot[0] = CreateConVar("l4d_me_slot0", "1", "(Primary), 0=Disable, 1=Enable");
	l4d_me_slot[1] = CreateConVar("l4d_me_slot1", "1", "(Secondary), 0=Disable, 1=Enable");
	l4d_me_slot[2] = CreateConVar("l4d_me_slot2", "1", "(Pipebomb), 0=Disable, 1=Enable");
	l4d_me_slot[3] = CreateConVar("l4d_me_slot3", "1", "(Medkit), 0=Disable, 1=Enable");
	l4d_me_slot[4] = CreateConVar("l4d_me_slot4", "1", "(Pills), 0=Disable, 1=Enable");

	l4d_me_mode = CreateConVar("l4d_me_mode", "1", "1=Single Tap Mode, 2=Double Tap Mode");
	l4d_me_view = CreateConVar("l4d_me_view", "1", "0=Disable extra equipment view in thirdpersonshoulder, 1=Enable extra equipment view in thirdpersonshoulder");
	l4d_me_afksave = CreateConVar("l4d_me_afksave", "1", "0=Disable AFK Save, 1=Enable AFK Save");
	l4d_me_custom_notify = CreateConVar("l4d_me_custom_notify", "1", "0=Disable Custom Message, 1=Enable Chat Message, 2=Enable Hint Message");
	l4d_me_custom_notify_msg = CreateConVar("l4d_me_custom_notify_msg", "| MULTIPLE EQUIPMENT || --->PRESS [H] FOR HELP<--- |", "Create a custom welcome message for your server.");

	HookEvent("item_pickup", item_pickup);
	HookEvent("ammo_pickup", ammo_pickup);
	HookEvent("weapon_fire", weapon_fire);
	HookEvent("player_spawn", player_spawn, EventHookMode_Pre);
	HookEvent("player_death", player_death, EventHookMode_Pre);
	HookEvent("player_bot_replace", enter_afk_pre_player_bot_replace, EventHookMode_Pre);
	HookEvent("bot_player_replace", exit_afk_post_bot_player_replace, EventHookMode_Post);
	HookEvent("map_transition", map_transition, EventHookMode_Pre);
	HookEvent("player_disconnect", player_disconnect, EventHookMode_Pre);
 	HookEvent("heal_begin", heal_begin);
	HookEvent("heal_end", heal_end);
	HookEvent("heal_success", heal_success);
 	HookEvent("revive_begin", revive_begin);
	HookEvent("revive_end", revive_end);
	HookEvent("pills_used", pills_used);
	
	if(L4D2Version)
	{
		HookEvent("adrenaline_used", adrenaline_used);
		HookEvent("molotov_thrown", molotov_thrown);
	}

	RegConsoleCmd("sm_s0", sm_s0);
	
	ResetAllState();

	g_sprite=g_sprite+0;
	g_iVelocity=g_iVelocity+0;
	
	AutoExecConfig(true, "l4d_multiple_equipment");
}

public void OnClientPostAdminCheck(client)
{
	MsgOn[client]=true;
	Self[client]=false;
	if (GetConVarInt(l4d_me_view) == 1)
	{
		AfkFix[client]=false
		if (client == 0) { return; }
		if (IsFakeClient(client)) { return; }
		Auto_Thirdpersonshoulder_View[client] = CreateTimer(0.1, AutoThirdpersonshoulderCheck, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
	Activate(client)
}

Activate(client)
{
	if (IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		ViewOn[client]=true;
		ViewOn[client]=false;
		LoadEquipment(client);
		RemoveItemAttach(client,-1);
		AttachAllEquipment(client);
	}
}

public Action:ME_Notify_Client(Handle:Timer, any:client)
{
	if (IsClientInGame(client) && GetClientTeam(client) == 2 && !IsFakeClient(client))
	{
		{
			new String:ME_Msg[99];
			GetConVarString(l4d_me_custom_notify_msg, ME_Msg, sizeof (ME_Msg));
			if (GetConVarInt(l4d_me_custom_notify) == 1)
			{
				PrintToChat(client, "%s", ME_Msg);
			}
			if (GetConVarInt(l4d_me_custom_notify) == 2)
			{
				PrintHintText(client, "%s", ME_Msg);
			}
			MsgOn[client]=false;
		}
	}
}

public Action:Clipping_Fix_Activate(Handle:Timer)
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client) == 2) // && !IsFakeClient(client))
		{
			ViewOn[client]=true;
			ViewOn[client]=false;
		}
	}
}

public Action:AutoThirdpersonshoulderCheck(Handle:Timer)
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client) == 2 && !IsFakeClient(client))
		{
			{
				QueryClientConVar(client, "c_thirdpersonshoulder", QueryClientConVarCallback);
			}
		}
	}
}

public QueryClientConVarCallback(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if (!StrEqual(cvarValue, "true") && !StrEqual(cvarValue, "1"))
	{
		ViewOn[client]=false;
		AfkFix[client]=false;
	}
	if (!StrEqual(cvarValue, "false") && !StrEqual(cvarValue, "0"))
	{
		if(AfkFix[client] == false)
		{
			ViewOn[client]=true;
		}
		if(AfkFix[client] == true)
		{
			ViewOn[client]=false;
		}
	}
}

public OnGameFrame()
{
	for(new client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && GetClientTeam(client) == 2) // && IsPlayerAlive(client))
		{
			new weapon = GetPlayerWeaponSlot(client, 0);
			if(IsValidEdict(weapon))
			{
				new String:sClassName[64];
				GetEdictClassname(weapon, sClassName, sizeof(sClassName));
				if (StrEqual(sClassName, "weapon_grenade_launcher"))
				{
					new Clip = GetEntProp(weapon, Prop_Data, "m_iClip1");
					new PrimType = GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType");
					new Ammo = GetEntProp(client, Prop_Data, "m_iAmmo", _, PrimType);
					if (Ammo < 1 && Clip == 1)
					{
						SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 1000.0);
					}
				}
				else
				{
					new Clip = GetEntProp(weapon, Prop_Data, "m_iClip1");
					new PrimType = GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType");
					new Ammo = GetEntProp(client, Prop_Data, "m_iAmmo", _, PrimType);
					if (Ammo <= 1 && Clip == 1)
					{
						SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 1000.0);
					}
				}
			}
		}
		if (IsClientInGame(client) && GetClientTeam(client) == 2) // && IsPlayerAlive(client))
		{
			if (!(GetEntityFlags(client) & FL_FROZEN) && IsValidEntity(client))
			{
				if (GetConVarInt(l4d_me_custom_notify) == 1 || GetConVarInt(l4d_me_custom_notify) == 2)
				{
					if (client == 0) { return; }
					if (IsFakeClient(client)) { return; }
					if (MsgOn[client] == false) { return; }
					ME_Notify[client] = CreateTimer(0.1, ME_Notify_Client, client, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}
}

public Action:ammo_pickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new weapon = GetPlayerWeaponSlot(client, 0);
	{
		if(IsValidEdict(weapon))
		{
			new String:sClassName[64];
			GetEdictClassname(weapon, sClassName, sizeof(sClassName));
			SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime());
		}
	}
	return Plugin_Handled;
}

public Action:sm_s0(client,args)
{
	if(IsValidClient(client, 2, true))
	{
		new Float:time=GetEngineTime();
		new buttons=GetClientButtons(client);
		if(time-PressStartTime[client]>0.18)
		{
			Process(client, time, buttons, true);
		}
		PressStartTime[client]=time;
	}
	return Plugin_Handled;
}

public Action:weapon_fire(Handle:event, const String:name[], bool:dontBroadcast)
{
 	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetClientTeam(client)==2)
	{
		decl String:item[65];
		GetEventString(event, "weapon", item, 65);
		if(StrEqual(item, "molotov"))
		{
			ThrowTime[client]=GetEngineTime();
		}
		else if(StrEqual(item, "vomitjar"))
		{
			ThrowTime[client]=GetEngineTime();
		}
		else if(StrEqual(item, "pipe_bomb"))
		{
			ThrowTime[client]=GetEngineTime();
		}
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impuls, Float:vel[3], Float:angles[3], &weapon)
{
	new lastButton=LastButton[client];
	LastButton[client]=buttons;
	new Float:time=GetEngineTime();
	if((buttons & IN_ATTACK2) && !(lastButton & IN_ATTACK2))
	{
		new w=Process(client, time, buttons, false);
		if(w>0)
		{
			LastSwitchTime[client]=time;
			LastWeapon[client]=w;
		}
	}
	else
	{
		if(weapon>0 && GetConVarInt(l4d_me_mode) == 1) //SINGLE TAP MODE
		{
			new newweapon=weapon;
			if(LastWeapon[client]==weapon)
			{
				new w=Process(client, time, buttons, true, weapon);
				if(w>0)newweapon=w;
			}
			else
			{
				Process(client, time, buttons, false);
			}
			LastSwitchTime[client]=time;
			LastWeapon[client]=newweapon;
		}
		if(weapon>0 && GetConVarInt(l4d_me_mode) == 2) //DOUBLE TAP MODE
		{
			new newweapon=weapon;
			if(LastWeapon[client]==weapon)
			{
				Process(client, time, buttons, true, weapon);
			}
			else
			{
				Process(client, time, buttons, false);
			}
			LastSwitchTime[client]=time;
			LastWeapon[client]=newweapon;
		}	
	}
	return Plugin_Continue;
}

public Action:DelayRestore(Handle:timer, any:client)
{
	Restore(client);
	return Plugin_Stop;
}

Restore(client)
{
	Process(client, GetEngineTime(), GetClientButtons(client), false);
}

Process(client, Float:time, button, bool:isSwitch, currentWeapon=0)
{
	new theNewWeapon=0;
	if(!IsValidClient(client, 2, true))return theNewWeapon;
	{
		new m_pounceAttacker=GetEntProp(client, Prop_Send, "m_pounceAttacker");
		new m_tongueOwner=GetEntProp(client, Prop_Send, "m_tongueOwner");
		new m_isIncapacitated=GetEntProp(client, Prop_Send, "m_isIncapacitated", 1);
		new m_isHangingFromLedge=GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1);
		if(L4D2Version)
		{
			new m_pummelAttacker=GetEntProp(client, Prop_Send, "m_pummelAttacker", 1);
			new m_jockeyAttacker=GetEntProp(client, Prop_Send, "m_jockeyAttacker", 1);
			if(m_pounceAttacker>0 || m_tongueOwner>0 || m_isHangingFromLedge>0 || m_isIncapacitated>0 || m_pummelAttacker>0 || m_jockeyAttacker>0 )return theNewWeapon;
		}
		else
		{
			if(m_pounceAttacker>0 || m_tongueOwner>0 || m_isHangingFromLedge>0 || m_isIncapacitated>0 )return theNewWeapon;
		}
	} 
	new activeWeapon=currentWeapon;
	if(activeWeapon==0)activeWeapon=GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if(activeWeapon<=0)	activeWeapon=0;
	new activeSlot=-1;
	for(new slot=0; slot<5; slot++)
	{
		if(!L4D2Version && slot==1)continue;
		if(GetConVarInt(l4d_me_slot[slot])==0)continue;
		if( slot==2 )
		{
			if(time-ThrowTime[client]<2.0)continue;
		}
		new ent=GetPlayerWeaponSlot(client, slot);
		if(activeWeapon==ent && ent>0 && activeWeapon>0)
		{
			activeSlot=slot;
		}
		else if(ent<=0)
		{
			theNewWeapon=SwapItem(client, slot, 0);
		}
	}
	if(activeSlot>=0 && isSwitch)
	{
		theNewWeapon=SwapItem(client, activeSlot, activeWeapon);
	}
	button=button+0;
	time+=0.0;
	if(!isSwitch && activeWeapon>0)
	{
		SetEntPropEnt(client, Prop_Data, "m_hActiveWeapon", activeWeapon);
		theNewWeapon=activeWeapon;
	}
	return theNewWeapon;
}

SwapItem(client, slot, oldweapon=0)
{
	new theNewWeapon=0;
	decl String:oldWeaponName[LEN64]="";
	new clip=0;
	new ammo=0;
	new upgradeBit=0;
	new upammo=0;
	if(oldweapon>0)
	{
		GetItemClass(oldweapon, oldWeaponName);
		if (StrEqual(oldWeaponName, ""))
		{
			return 0;
		}
		new bool:isPistol=false;
		if (StrEqual(oldWeaponName, "weapon_pistol"))isPistol=true;
		GetItemInfo(client, slot,oldweapon, ammo, clip, upgradeBit,upammo, isPistol);
		RemovePlayerItem(client, oldweapon);
		AcceptEntityInput(oldweapon, "kill");
	}
	new newweapon=0;
	if(!StrEqual(ItemName[client][slot], ""))
	{
		newweapon=CreateWeaponEnt(ItemName[client][slot]);
	}
	if(newweapon>0)
	{
		EquipPlayerWeapon(client, newweapon);
		SetEntPropEnt(client, Prop_Data, "m_hActiveWeapon" , newweapon);
		SetItemInfo(client, slot, newweapon , ItemInfo[client][slot][0], ItemInfo[client][slot][1],ItemInfo[client][slot][2],ItemInfo[client][slot][3]);
		theNewWeapon=newweapon;
	}
	ItemName[client][slot]=oldWeaponName;
	ItemInfo[client][slot][0]=ammo;
	ItemInfo[client][slot][1]=clip;
	ItemInfo[client][slot][2]=upgradeBit;
	ItemInfo[client][slot][3]=upammo;		
	RemoveItemAttach(client, slot);
	ItemAttachEnt[client][slot]=0;
	ItemAttachEnt[client][slot]=CreateItemAttach(client, oldWeaponName, slot);
	return theNewWeapon;
}

SetItemInfo (client, slot, weapon,  ammo, clip, upgradeBit, upammo)
{
	if(slot==0)
	{
		if(L4D2Version)SetClientWeaponInfo_l4d2(client, weapon, ammo, clip, upgradeBit, upammo);
		else SetClientWeaponInfo_l4d1(client, weapon, ammo, clip);
	}
	else
	{
		SetEntProp(weapon, Prop_Send, "m_iClip1",clip);
 		if(slot==1 && ammo>0)SetEntProp(weapon, Prop_Send, "m_hasDualWeapons" ,ammo);
	}
}

GetItemInfo(client, slot, weapon, &ammo, &clip,  &upgradeBit, &upammo, bool:isPistol)
{
	if(slot==0)
	{
		if(L4D2Version)GetClientWeaponInfo_l4d2(client, weapon, ammo, clip, upgradeBit, upammo);
		else GetClientWeaponInfo_l4d1(client,weapon, ammo, clip);
	}
	else
	{
		ammo=0;
		upgradeBit=0;
		upammo=0;
		clip = GetEntProp(weapon, Prop_Send, "m_iClip1" );
		if(isPistol)ammo = GetEntProp(weapon, Prop_Send, "m_hasDualWeapons" );
	}
}

RemoveItemAttach(client, slot)
{
	new startSlot = slot;
	new endSlot = slot;
	if (slot < 0 || slot > 4)
	{
		startSlot=0;
		endSlot=4;
	}
	for (new i = startSlot; i <= endSlot; i++)
	{
		new entity = ItemAttachEnt[client][i];
		ItemAttachEnt[client][i]=0;
		if(entity > 0 && IsValidEntS(entity ,"prop_dynamic"))
		{
			AcceptEntityInput(entity, "ClearParent");
			AcceptEntityInput(entity, "Kill");
		}
	}
}

CreateItemAttach(client, String:classname[], slot)
{
	if (GetConVarInt(l4d_me_view) == 0) return 0;
	if (IsFakeClient(client)) return 0;

	decl String:model[LEN64];
	
	if(L4D2Version)GetModelFromClass_l4d2(classname, model,slot);
	else GetModelFromClass_l4d1(classname, model,slot);
	
	if(StrEqual(classname, "")) return 0;
	if(StrEqual(model, "")) return 0;

	new iEnt = ItemAttachEnt[client][slot];
	if(IsValidEntRef(iEnt))return 0;
		
	iEnt = CreateEntityByName("prop_dynamic_override");
	if(!IsValidEntity(iEnt)) return 0;
	
	SetEntityModel(iEnt, model);
	DispatchSpawn(iEnt);
	//AcceptEntityInput(iEnt, "TurnOn");
	SetEntProp(iEnt, Prop_Data, "m_CollisionGroup", 2);
	
	//SetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity", client);
	//decl String:Player_Name[64];
	//Format(Player_Name, sizeof(Player_Name), "client%s", client);
	//DispatchKeyValue(client, "targetname", Player_Name);
	//SetVariantString(Player_Name);
	//SetVariantString("player");
	//SetVariantString("!pvsplayer");
	
	SetVariantString("!activator");
	AcceptEntityInput(iEnt, "SetParent", client, iEnt, 0);
	
	new Float:pos[3];
	new Float:ang[3];
	
	if(slot==0)
	{
		SetVariantString("medkit");
		AcceptEntityInput(iEnt, "SetParentAttachment", iEnt, iEnt, 0);
		if(L4D2Version)
		{
			SetVector(pos, 2.0, 0.0, -7.0);
			SetVector(ang, -22.0, 100.0, 180.0);
		}
		else
		{
			SetVector(pos, 2.0, -4.0, 5.0);
			SetVector(ang, -15.0, 90.0, 180.0);
		}
	}
	if(slot==1)
	{
		SetVariantString("molotov");
		AcceptEntityInput(iEnt, "SetParentAttachment", iEnt, iEnt, 0);
		if(L4D2Version)
		{
			SetVector(pos, 0.0,  0.0, 0.0);
			SetVector(ang, 120.0, 90.0, 0.0);
		}
		else
		{
			SetVector(pos, 2.0, -4.0, 5.0);
			SetVector(ang, -15.0, 90.0, 180.0);
		}
	}
	else if(slot==2)
	{
		SetVariantString("molotov");
		AcceptEntityInput(iEnt, "SetParentAttachment", iEnt, iEnt, 0);
		if(L4D2Version)
		{
			SetVector(pos, 0.0, 4.0,0.0);
			SetVector(ang, 0.0, 90.0, 0.0);
		}
		else
		{
			SetVector(pos, 0.0, 4.0,0.0);
			SetVector(ang, 0.0, 90.0, 0.0);
		}
	}
	else if(slot==3)
	{
		SetVariantString("medkit");
		AcceptEntityInput(iEnt, "SetParentAttachment", iEnt, iEnt, 0);
		if(L4D2Version)
		{
			SetVector(pos, -0.0, 10.0,0.0);
			SetVector(ang, 0.0, 0.0, 0.0);
		}
		else
		{
			SetVector(pos, -0.0, 10.0,0.0);
			SetVector(ang, 0.0, 0.0, 0.0);
		}
	}
	else if(slot==4)
	{
		SetVariantString("pills");
		AcceptEntityInput(iEnt, "SetParentAttachment", iEnt, iEnt, 0);
		if(L4D2Version)
		{
			SetVector(pos, 5.0, 3.0,0.0);
			SetVector(ang, 0.0, 90.0, 0.0);
		}
		else
		{
			SetVector(pos, 5.0, 3.0,0.0);
			SetVector(ang, 0.0, 90.0, 0.0);
		}
	}
	TeleportEntity(iEnt, pos, ang, NULL_VECTOR);
	Self[client]=true;
	SDKHook(iEnt, SDKHook_SetTransmit, Hook_Equipment_View);
	ItemAttachEnt[client][slot] = EntIndexToEntRef(iEnt);
	return iEnt;
}

public Action:Hook_Equipment_View(entity, client)
{
	//new bool:self=false;
	if(IsClientInGame(client))
	{
		for(new slot=0; slot<=4; slot++)
		{
			if(ItemAttachEnt[client][slot] == EntRefToEntIndex(entity))
			{
				//Self[client]=true:
				//self=true;
				break;
			}
		}
		if(Self[client] == true)
		//if(self)
		{
			new Float:t=GetEngineTime();
			if(t-InHeal[client]<5.0 || t-InRevive[client]<5.0) return Plugin_Continue;
			if(ViewOn[client]) return Plugin_Continue;
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

AttachAllEquipment(client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
	{
		for(new slot=0; slot<=4; slot++)
		{
			ItemAttachEnt[client][slot]=CreateItemAttach(client, ItemName[client][slot], slot);
		}
	}
}

DropSecondaryItem(client)
{
	new Float:origin[3];
	GetClientEyePosition(client,origin);
	for(new slot=0; slot<=4; slot++)
	{
		if(!StrEqual(ItemName[client][slot], ""))
		{			 
			new ammo=ItemInfo[client][slot][0];
			new clip=ItemInfo[client][slot][1];
			new info1=ItemInfo[client][slot][2];
			new info2=ItemInfo[client][slot][3];
			if(slot==0)
			{
				if(L4D2Version)DropPrimarayWeapon_l4d2(client,ItemName[client][slot], ammo, clip, info1, info2);
				else DropPrimarayWeapon_l4d1(client, ItemName[client][slot], ammo, clip);
			}
			else
			{
				new ent=CreateWeaponEnt(ItemName[client][slot]);
				TeleportEntity(ent, origin, NULL_VECTOR, NULL_VECTOR);
				ActivateEntity(ent);
			}
		}
	}
	new weapon = -1;
	for (new i = 0; i <= 5; i++)
	{
		if ((weapon = GetPlayerWeaponSlot(client, i)) != -1)
		{
			RemovePlayerItem(client, weapon);
		}
	} 
}

SaveEquipment(i)
{
	for(new slot=0; slot<=4; slot++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			BackupItemName[i][slot]=ItemName[i][slot];
			BackupItemInfo[i][slot][0]=ItemInfo[i][slot][0];
			BackupItemInfo[i][slot][1]=ItemInfo[i][slot][1];
			BackupItemInfo[i][slot][2]=ItemInfo[i][slot][2];
			BackupItemInfo[i][slot][3]=ItemInfo[i][slot][3];
		}
	}
}

SaveEquipmentAll()
{
	for(new i=1; i<=MaxClients; i++)
	{
		for(new slot=0; slot<=4; slot++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
			{
				BackupItemName[i][slot]=ItemName[i][slot];
				BackupItemInfo[i][slot][0]=ItemInfo[i][slot][0];
				BackupItemInfo[i][slot][1]=ItemInfo[i][slot][1];
				BackupItemInfo[i][slot][2]=ItemInfo[i][slot][2];
				BackupItemInfo[i][slot][3]=ItemInfo[i][slot][3];
			}
		}
	}
}

LoadEquipment(i)
{
	for(new slot=0; slot<=4; slot++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			ItemName[i][slot]=BackupItemName[i][slot];
			ItemInfo[i][slot][0]=BackupItemInfo[i][slot][0];
			ItemInfo[i][slot][1]=BackupItemInfo[i][slot][1];
			ItemInfo[i][slot][2]=BackupItemInfo[i][slot][2];
			ItemInfo[i][slot][3]=BackupItemInfo[i][slot][3];
		}
	}
}

IsValidEntS(ent, String:classname[LEN64])
{
	if(IsValidEnt(ent))
	{
		decl String:name[LEN64];
		GetEdictClassname(ent, name, LEN64);
		if(StrEqual(classname, name))
		{
			return true;
		}
	}
	return false;
}

IsValidEnt(ent)
{
	if(ent>0 && IsValidEdict(ent) && IsValidEntity(ent))
	{
		return true;
	}
	return false;
}

#define model_weapon_rifle "models/w_models/weapons/w_rifle_m16a2.mdl"
#define model_weapon_rifle_sg552 "models/w_models/weapons/w_rifle_sg552.mdl"
#define model_weapon_rifle_desert "models/w_models/weapons/w_desert_rifle.mdl"
#define model_weapon_rifle_ak47 "models/w_models/weapons/w_rifle_ak47.mdl"
#define model_weapon_smg "models/w_models/weapons/w_smg_uzi.mdl"
#define model_weapon_smg_silenced "models/w_models/weapons/w_smg_a.mdl"
#define model_weapon_smg_mp5 "models/w_models/weapons/w_smg_mp5.mdl"
#define model_weapon_pumpshotgun "models/w_models/weapons/w_shotgun.mdl"
#define model_weapon_shotgun_chrome "models/w_models/weapons/w_pumpshotgun_A.mdl"
#define model_weapon_autoshotgun "models/w_models/weapons/w_autoshot_m4super.mdl"
#define model_weapon_shotgun_spas "models/w_models/weapons/w_shotgun_spas.mdl"
#define model_weapon_hunting_rifle "models/w_models/weapons/w_sniper_mini14.mdl"
#define model_weapon_sniper_scout "models/w_models/weapons/w_sniper_scout.mdl"
#define model_weapon_sniper_military "models/w_models/weapons/w_sniper_military.mdl"
#define model_weapon_sniper_awp "models/w_models/weapons/w_sniper_awp.mdl"
#define model_weapon_rifle_m60 "models/w_models/weapons/w_m60.mdl"
#define model_weapon_grenade_launcher "models/w_models/weapons/w_grenade_launcher.mdl"
#define model_weapon_pistol "models/w_models/weapons/w_pistol_A.mdl"
#define model_weapon_pistol_magnum "models/w_models/weapons/w_desert_eagle.mdl"
#define model_weapon_chainsaw "models/weapons/melee/w_chainsaw.mdl"
#define model_weapon_melee_fireaxe "models/weapons/melee/w_fireaxe.mdl"
#define model_weapon_melee_baseball_bat "models/weapons/melee/w_bat.mdl"
#define model_weapon_melee_crowbar "models/weapons/melee/w_crowbar.mdl"
#define model_weapon_melee_electric_guitar "models/weapons/melee/w_electric_guitar.mdl"
#define model_weapon_melee_cricket_bat "models/weapons/melee/w_cricket_bat.mdl"
#define model_weapon_melee_frying_pan  "models/weapons/melee/w_frying_pan.mdl"
#define model_weapon_melee_golfclub  "models/weapons/melee/w_golfclub.mdl"
#define model_weapon_melee_machete  "models/weapons/melee/w_machete.mdl"
#define model_weapon_melee_katana  "models/weapons/melee/w_katana.mdl"
#define model_weapon_melee_tonfa  "models/weapons/melee/w_tonfa.mdl"
#define model_weapon_melee_riotshield  "models/weapons/melee/w_riotshield.mdl"
#define model_weapon_molotov "models/w_models/weapons/w_eq_molotov.mdl"
#define model_weapon_pipe_bomb "models/w_models/weapons/w_eq_pipebomb.mdl"
#define model_weapon_vomitjar "models/w_models/weapons/w_eq_bile_flask.mdl"
#define model_weapon_first_aid_kit "models/w_models/weapons/w_eq_Medkit.mdl"
#define model_weapon_defibrillator "models/w_models/weapons/w_eq_defibrillator.mdl"
#define model_weapon_upgradepack_explosive "models/w_models/weapons/w_eq_explosive_ammopack.mdl"
#define model_weapon_upgradepack_incendiary "models/w_models/weapons/w_eq_incendiary_ammopack.mdl"
#define model_weapon_pain_pills "models/w_models/weapons/w_eq_painpills.mdl"
#define model_weapon_adrenaline "models/w_models/weapons/w_eq_adrenaline.mdl"

GetModelFromClass_l4d2(String:weapon[], String:model[LEN64], slot=0)
{
	if(slot==0)
	{
		if (StrEqual(weapon, "weapon_rifle"))strcopy(model, LEN64, model_weapon_rifle);
		else if (StrEqual(weapon, "weapon_rifle_sg552"))strcopy(model, LEN64, model_weapon_rifle_sg552);
		else if (StrEqual(weapon, "weapon_rifle_desert"))strcopy(model, LEN64, model_weapon_rifle_desert);
		else if (StrEqual(weapon, "weapon_rifle_ak47"))strcopy(model, LEN64, model_weapon_rifle_ak47);
		else if (StrEqual(weapon, "weapon_rifle_m60"))strcopy(model, LEN64, model_weapon_rifle_m60);
		else if (StrEqual(weapon, "weapon_smg"))strcopy(model, LEN64, model_weapon_smg);
		else if (StrEqual(weapon, "weapon_smg_silenced"))strcopy(model, LEN64, model_weapon_smg_silenced);
		else if (StrEqual(weapon, "weapon_smg_mp5"))strcopy(model, LEN64, model_weapon_smg_mp5);
		else if (StrEqual(weapon, "weapon_pumpshotgun"))strcopy(model, LEN64, model_weapon_pumpshotgun);
		else if (StrEqual(weapon, "weapon_shotgun_chrome"))strcopy(model, LEN64, model_weapon_shotgun_chrome);
		else if (StrEqual(weapon, "weapon_autoshotgun"))strcopy(model, LEN64, model_weapon_autoshotgun);
		else if (StrEqual(weapon, "weapon_shotgun_spas"))strcopy(model, LEN64, model_weapon_shotgun_spas);
		else if (StrEqual(weapon, "weapon_hunting_rifle"))strcopy(model, LEN64, model_weapon_hunting_rifle);
		else if (StrEqual(weapon, "weapon_sniper_scout"))strcopy(model, LEN64, model_weapon_sniper_scout);
		else if (StrEqual(weapon, "weapon_sniper_military"))strcopy(model, LEN64, model_weapon_sniper_military);
		else if (StrEqual(weapon, "weapon_sniper_awp"))strcopy(model, LEN64, model_weapon_sniper_awp);
		else if (StrEqual(weapon, "weapon_grenade_launcher"))strcopy(model, LEN64, model_weapon_grenade_launcher);
		else model="";
	}
	else if(slot==1)
	{
		if (StrEqual(weapon, "weapon_pistol"))strcopy(model, LEN64, model_weapon_pistol);
		else if (StrEqual(weapon, "weapon_pistol_magnum"))strcopy(model, LEN64, model_weapon_pistol_magnum);
		else if (StrEqual(weapon, "weapon_chainsaw"))strcopy(model, LEN64, model_weapon_chainsaw);
		else if (StrEqual(weapon, "weapon_melee_fireaxe"))strcopy(model, LEN64, model_weapon_melee_fireaxe);
		else if (StrEqual(weapon, "weapon_melee_baseball_bat"))strcopy(model, LEN64, model_weapon_melee_baseball_bat);
		else if (StrEqual(weapon, "weapon_melee_crowbar"))strcopy(model, LEN64, model_weapon_melee_crowbar);
		else if (StrEqual(weapon, "weapon_melee_electric_guitar"))strcopy(model, LEN64, model_weapon_melee_electric_guitar);
		else if (StrEqual(weapon, "weapon_melee_cricket_bat"))strcopy(model, LEN64, model_weapon_melee_cricket_bat);
		else if (StrEqual(weapon, "weapon_melee_frying_pan"))strcopy(model, LEN64, model_weapon_melee_frying_pan);
		else if (StrEqual(weapon, "weapon_melee_golfclub"))strcopy(model, LEN64, model_weapon_melee_golfclub);
		else if (StrEqual(weapon, "weapon_melee_machete"))strcopy(model, LEN64, model_weapon_melee_machete);
		else if (StrEqual(weapon, "weapon_melee_katana"))strcopy(model, LEN64, model_weapon_melee_katana);
		else if (StrEqual(weapon, "weapon_melee_tonfa"))strcopy(model, LEN64, model_weapon_melee_tonfa);
		else if (StrEqual(weapon, "weapon_melee_riotshield"))strcopy(model, LEN64, model_weapon_melee_riotshield);
		else model="";
	}
	else if(slot==2)
	{
		if (StrEqual(weapon, "weapon_molotov"))strcopy(model, LEN64, model_weapon_molotov);
		else if (StrEqual(weapon, "weapon_pipe_bomb"))strcopy(model, LEN64, model_weapon_pipe_bomb);
		else if (StrEqual(weapon, "weapon_vomitjar"))strcopy(model, LEN64, model_weapon_vomitjar);
		else model="";
	}
	else if(slot==3)
	{
		if (StrEqual(weapon, "weapon_first_aid_kit"))strcopy(model, LEN64, model_weapon_first_aid_kit);
		else if (StrEqual(weapon, "weapon_defibrillator"))strcopy(model, LEN64, model_weapon_defibrillator);
		else if (StrEqual(weapon, "weapon_upgradepack_explosive"))strcopy(model, LEN64, model_weapon_upgradepack_explosive);
		else if (StrEqual(weapon, "weapon_upgradepack_incendiary"))strcopy(model, LEN64, model_weapon_upgradepack_incendiary);
		else model="";
	}
	else if(slot==4)
	{
		if (StrEqual(weapon, "weapon_pain_pills"))strcopy(model, LEN64, model_weapon_pain_pills);
		else if (StrEqual(weapon, "weapon_adrenaline"))strcopy(model, LEN64, model_weapon_adrenaline);
		else model="";
	}
}

#define model1_weapon_rifle "models/w_models/weapons/w_rifle_m16a2.mdl"
#define model1_weapon_autoshotgun "models/w_models/weapons/w_autoshot_m4super.mdl"
#define model1_weapon_pumpshotgun "models/w_models/Weapons/w_shotgun.mdl"
#define model1_weapon_hunting_rifle "models/w_models/weapons/w_sniper_mini14.mdl"
#define model1_weapon_smg "models/w_models/Weapons/w_smg_uzi.mdl"
#define model1_weapon_pistol "models/w_models/Weapons/w_pistol_1911.mdl"
#define model1_weapon_molotov "models/w_models/weapons/w_eq_molotov.mdl"
#define model1_weapon_pipe_bomb "models/w_models/weapons/w_eq_pipebomb.mdl"
#define model1_weapon_first_aid_kit "models/w_models/weapons/w_eq_Medkit.mdl"
#define model1_weapon_pain_pills "models/w_models/weapons/w_eq_painpills.mdl"

GetModelFromClass_l4d1(String:weapon[], String:model[LEN64],slot=0)
{
	if(slot==0)
	{
		if (StrEqual(weapon, "weapon_rifle"))strcopy(model, LEN64, model1_weapon_rifle);
		else if (StrEqual(weapon, "weapon_autoshotgun"))strcopy(model, LEN64, model1_weapon_autoshotgun);
		else if (StrEqual(weapon, "weapon_pumpshotgun"))strcopy(model, LEN64, model1_weapon_pumpshotgun);
		else if (StrEqual(weapon, "weapon_hunting_rifle"))strcopy(model, LEN64, model1_weapon_hunting_rifle);
		else if (StrEqual(weapon, "weapon_smg"))strcopy(model, LEN64, model1_weapon_smg);
		else model="";
	}
	else if(slot==1)
	{
		if (StrEqual(weapon, "weapon_pistol"))strcopy(model, LEN64, model1_weapon_pistol);
		else model="";
	}
	else if(slot==2)
	{
		if (StrEqual(weapon, "weapon_molotov"))strcopy(model, LEN64, model1_weapon_molotov);
		else if (StrEqual(weapon, "weapon_pipe_bomb"))strcopy(model, LEN64, model1_weapon_pipe_bomb);
		else model="";
	}
	else if(slot==3)
	{
		if (StrEqual(weapon, "weapon_first_aid_kit"))strcopy(model, LEN64, model1_weapon_first_aid_kit);
		else model="";
	}
	else if(slot==4)
	{
		if (StrEqual(weapon, "weapon_pain_pills"))strcopy(model, LEN64, model1_weapon_pain_pills);
		else model="";
	}
}

GetItemClass(ent, String:classname[LEN64])
{
	classname="";
	if(ent>0)
	{
		GetEdictClassname(ent, classname, LEN64);
		if(StrEqual(classname, "weapon_melee"))
		{
			decl String:model[128];
			GetEntPropString(ent, Prop_Data, "m_ModelName", model, sizeof(model));
			if(StrContains(model, "fireaxe")>=0)classname="weapon_melee_fireaxe";
			else if(StrContains(model, "v_bat")>=0)	classname="weapon_melee_baseball_bat";
			else if(StrContains(model, "crowbar")>=0)classname="weapon_melee_crowbar";
			else if(StrContains(model, "electric_guitar")>=0)classname="weapon_melee_electric_guitar";
			else if(StrContains(model, "cricket_bat")>=0)classname="weapon_melee_cricket_bat";
			else if(StrContains(model, "frying_pan")>=0)classname="weapon_melee_frying_pan";
			else if(StrContains(model, "golfclub")>=0)classname="weapon_melee_golfclub";
			else if(StrContains(model, "machete")>=0)classname="weapon_melee_machete";
			else if(StrContains(model, "katana")>=0)classname="weapon_melee_katana";
			else if(StrContains(model, "tonfa")>=0)classname="weapon_melee_tonfa";
			else if(StrContains(model, "riotshield")>=0)classname="weapon_melee_riotshield";
			else classname="";
		}
	}
}

CreateWeaponEnt(String:classname[])
{
	if(StrEqual(classname, "")) return 0;
	if(StrContains(classname, "weapon_melee_")<0)
	{
		new ent=CreateEntityByName(classname);
		DispatchSpawn(ent);
		return ent;
	}
	else
	{
		new ent=CreateEntityByName("weapon_melee");
		if(StrEqual(classname, "weapon_melee_fireaxe"))DispatchKeyValue( ent, "melee_script_name", "fireaxe");
		else if(StrEqual(classname, "weapon_melee_baseball_bat"))DispatchKeyValue( ent, "melee_script_name", "baseball_bat");
		else if(StrEqual(classname, "weapon_melee_crowbar"))DispatchKeyValue( ent, "melee_script_name", "crowbar");
		else if(StrEqual(classname, "weapon_melee_electric_guitar"))DispatchKeyValue( ent, "melee_script_name", "electric_guitar");
		else if(StrEqual(classname, "weapon_melee_cricket_bat"))DispatchKeyValue( ent, "melee_script_name", "cricket_bat");
		else if(StrEqual(classname, "weapon_melee_frying_pan"))DispatchKeyValue( ent, "melee_script_name", "frying_pan");
		else if(StrEqual(classname, "weapon_melee_golfclub"))DispatchKeyValue( ent, "melee_script_name", "golfclub");
		else if(StrEqual(classname, "weapon_melee_machete"))DispatchKeyValue( ent, "melee_script_name", "machete");
		else if(StrEqual(classname, "weapon_melee_katana"))DispatchKeyValue( ent, "melee_script_name", "katana");
		else if(StrEqual(classname, "weapon_melee_tonfa"))DispatchKeyValue( ent, "melee_script_name", "tonfa");
		else if(StrEqual(classname, "weapon_melee_riotshield"))DispatchKeyValue( ent, "melee_script_name", "riotshield");
		DispatchSpawn(ent);
		return ent;
	}
}

public OnMapStart()
{
	if(L4D2Version)
	{
		PrecacheModel(model_weapon_rifle);
		PrecacheModel(model_weapon_rifle_sg552);
		PrecacheModel(model_weapon_rifle_desert);
		PrecacheModel(model_weapon_rifle_ak47);
		PrecacheModel(model_weapon_rifle_m60);
		PrecacheModel(model_weapon_smg);
		PrecacheModel(model_weapon_smg_silenced);
		PrecacheModel(model_weapon_smg_mp5);
		PrecacheModel(model_weapon_pumpshotgun);
		PrecacheModel(model_weapon_shotgun_chrome);
		PrecacheModel(model_weapon_autoshotgun);
		PrecacheModel(model_weapon_shotgun_spas);
		PrecacheModel(model_weapon_hunting_rifle);
		PrecacheModel(model_weapon_sniper_scout);
		PrecacheModel(model_weapon_sniper_military);
		PrecacheModel(model_weapon_sniper_awp);
		PrecacheModel(model_weapon_grenade_launcher);
		
		PrecacheModel(model_weapon_pistol);
		PrecacheModel(model_weapon_pistol_magnum);
		PrecacheModel(model_weapon_chainsaw);
		
		PrecacheModel(model_weapon_melee_fireaxe);
		PrecacheModel(model_weapon_melee_baseball_bat);
		PrecacheModel(model_weapon_melee_crowbar);
		PrecacheModel(model_weapon_melee_electric_guitar);
		PrecacheModel(model_weapon_melee_cricket_bat);
		PrecacheModel(model_weapon_melee_frying_pan);
		PrecacheModel(model_weapon_melee_golfclub);
		PrecacheModel(model_weapon_melee_machete);
		PrecacheModel(model_weapon_melee_katana);
		PrecacheModel(model_weapon_melee_tonfa);
		PrecacheModel(model_weapon_melee_riotshield);
		
		PrecacheModel(model_weapon_molotov);
		PrecacheModel(model_weapon_pipe_bomb);
		PrecacheModel(model_weapon_vomitjar);
		
		PrecacheModel(model_weapon_first_aid_kit);
		PrecacheModel(model_weapon_defibrillator);
		PrecacheModel(model_weapon_upgradepack_explosive);
		PrecacheModel(model_weapon_upgradepack_incendiary);
		
		PrecacheModel(model_weapon_pain_pills);
		PrecacheModel(model_weapon_adrenaline);

		PrecacheGeneric( "scripts/melee/baseball_bat.txt", true);
		PrecacheGeneric( "scripts/melee/cricket_bat.txt", true);
		PrecacheGeneric( "scripts/melee/crowbar.txt", true);
		PrecacheGeneric( "scripts/melee/electric_guitar.txt", true);
		PrecacheGeneric( "scripts/melee/fireaxe.txt", true);
		PrecacheGeneric( "scripts/melee/frying_pan.txt", true);
		PrecacheGeneric( "scripts/melee/golfclub.txt", true);
		PrecacheGeneric( "scripts/melee/katana.txt", true);
		PrecacheGeneric( "scripts/melee/machete.txt", true);
		PrecacheGeneric( "scripts/melee/tonfa.txt", true);
		PrecacheGeneric( "scripts/melee/riotshield.txt", true);
	}
	else
	{
		PrecacheModel(model1_weapon_rifle);
		PrecacheModel(model1_weapon_autoshotgun);
		PrecacheModel(model1_weapon_pumpshotgun);
		PrecacheModel(model1_weapon_hunting_rifle);
		PrecacheModel(model1_weapon_smg);
		PrecacheModel(model1_weapon_pistol);
		PrecacheModel(model1_weapon_molotov);
		PrecacheModel(model1_weapon_pipe_bomb);
		PrecacheModel(model1_weapon_first_aid_kit);
		PrecacheModel(model1_weapon_pain_pills);
	}
}

SetVector(Float:target[3], Float:x, Float:y, Float:z)
{
	target[0]=x;
	target[1]=y;
	target[2]=z;
}

IsValidClient(client, team=0, bool:alive=true)
{
	if(client>0 && client<=MaxClients)
	{
		if(IsClientInGame(client))
		{
			if(GetClientTeam(client)!=team && team!=0)return false;
			if(!IsPlayerAlive(client) && alive)return false;
			return true;
		}
	}
	return false;
}

public enter_afk_pre_player_bot_replace(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(Spawn_Event, "player"));
	if (GetConVarInt(l4d_me_afksave) == 1)
	{
		SaveEquipment(client);
		RemoveItemAttach(client, -1);
		if (GetConVarInt(l4d_me_view) == 1)
		{
			AfkFix[client]=true
			if (IsFakeClient(client)) { return; }
			Clipping_Fix[client] = CreateTimer(0.1, Clipping_Fix_Activate, client, TIMER_FLAG_NO_MAPCHANGE); //Fixes clipping bug with your weapon when in afk.
		}

	}
	else
	{
		if (GetConVarInt(l4d_me_view) == 1)
		{
			AfkFix[client]=true
			if (IsFakeClient(client)) { return; }
			Clipping_Fix[client] = CreateTimer(0.1, Clipping_Fix_Activate, client, TIMER_FLAG_NO_MAPCHANGE); //Fixes clipping bug with your weapon when in afk.
		}
		ResetClientState(client);
	}
}

public exit_afk_post_bot_player_replace(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(Spawn_Event, "player"));
	if (GetConVarInt(l4d_me_afksave) == 1)
	{
		LoadEquipment(client);
		AttachAllEquipment(client);
		if (GetConVarInt(l4d_me_view) == 1)
		{
			if (IsFakeClient(client)) { return; }
			Clipping_Fix[client] = CreateTimer(0.1, Clipping_Fix_Activate, client, TIMER_FLAG_NO_MAPCHANGE); //Doesn't actually work here because of L4D2 thirdpersonshoulder convar bug.
		}
	}
	else
	{
		if (GetConVarInt(l4d_me_view) == 1)
		{
			if (IsFakeClient(client)) { return; }
			Clipping_Fix[client] = CreateTimer(0.1, Clipping_Fix_Activate, client, TIMER_FLAG_NO_MAPCHANGE); //Doesn't actually work here because of L4D2 thirdpersonshoulder convar bug.
		}
		ResetClientState(client);
	}
}

public Action:player_spawn(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	ViewOn[client] = true
	ViewOn[client] = false
}

public Action:player_death(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(client>0 && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		RemoveItemAttach(client, -1);
		DropSecondaryItem(client);
	}
	ResetClientState(client);
}

public Action:player_disconnect(Handle:event, const String:name[], bool:dont_broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	ResetClientState(client) //This removes all extra items from fully disconnected clients.
}

SetClientWeaponInfo_l4d1(client, ent, ammo, clip)
{
	if (ent>0)
	{
		new String:weapon[32];
		new ammoOffset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
		GetEdictClassname(ent, weapon, 32);
		SetEntProp(ent, Prop_Send, "m_iClip1", clip);
		if (StrEqual(weapon, "weapon_pumpshotgun") || StrEqual(weapon, "weapon_autoshotgun"))
		{
			SetEntData(client, ammoOffset+(6*4), ammo);
		}
		else if (StrEqual(weapon, "weapon_smg"))
		{
			SetEntData(client, ammoOffset+(5*4), ammo);
		}
		else if (StrEqual(weapon, "weapon_rifle"))
		{
			SetEntData(client, ammoOffset+(3*4), ammo);
		}
		else if (StrEqual(weapon, "weapon_hunting_rifle"))
		{
			SetEntData(client, ammoOffset+(2*4), ammo);
		}
		else if (StrEqual(weapon, "weapon_pistol"))
		{
			SetEntProp(ent, Prop_Send, "m_hasDualWeapons", ammo );
		}
	}
}

SetClientWeaponInfo_l4d2(client, ent ,  ammo,  clip, upgradeBit, upammo)
{
	if (ent>0)
	{
		new String:weapon[32];
		new ammoOffset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
		GetEdictClassname(ent, weapon, 32);
		SetEntProp(ent, Prop_Send, "m_iClip1", clip);
		SetEntProp(ent, Prop_Send, "m_upgradeBitVec", upgradeBit);
		SetEntProp(ent, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", upammo);
		if (StrEqual(weapon, "weapon_rifle") || StrEqual(weapon, "weapon_rifle_sg552") || StrEqual(weapon, "weapon_rifle_desert") || StrEqual(weapon, "weapon_rifle_ak47"))
		{
			SetEntData(client, ammoOffset+(12), ammo);
		}
		else if (StrEqual(weapon, "weapon_rifle_m60"))
		{
			SetEntData(client, ammoOffset+(12), ammo);
		}
		else if (StrEqual(weapon, "weapon_smg") || StrEqual(weapon, "weapon_smg_silenced") || StrEqual(weapon, "weapon_smg_mp5"))
		{
			SetEntData(client, ammoOffset+(20), ammo);
		}
		else if (StrEqual(weapon, "weapon_pumpshotgun") || StrEqual(weapon, "weapon_shotgun_chrome"))
		{
			SetEntData(client, ammoOffset+(28), ammo);
		}
		else if (StrEqual(weapon, "weapon_autoshotgun") || StrEqual(weapon, "weapon_shotgun_spas"))
		{
			SetEntData(client, ammoOffset+(32), ammo);
		}
		else if (StrEqual(weapon, "weapon_hunting_rifle"))
		{
			SetEntData(client, ammoOffset+(36), ammo);
		}
		else if (StrEqual(weapon, "weapon_sniper_scout") || StrEqual(weapon, "weapon_sniper_military") || StrEqual(weapon, "weapon_sniper_awp"))
		{
			SetEntData(client, ammoOffset+(40), ammo);
		}
		else if (StrEqual(weapon, "weapon_grenade_launcher"))
		{
			SetEntData(client, ammoOffset+(68), ammo);
		}
		else if (StrEqual(weapon, "weapon_pistol"))
		{
			SetEntProp(ent, Prop_Send, "m_hasDualWeapons", ammo );
		}
	}
}

GetClientWeaponInfo_l4d1(client ,ent, &ammo, &clip)
{
	if (ent > 0)
	{
		new String:weapon[32];
		new ammoOffset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
		GetEdictClassname(ent, weapon, 32);
		{
			clip = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iClip1");
			if (StrEqual(weapon, "weapon_pumpshotgun") || StrEqual(weapon, "weapon_autoshotgun"))
			{
				ammo = GetEntData(client, ammoOffset+(6*4));
			}
			else if (StrEqual(weapon, "weapon_smg"))
			{
				ammo = GetEntData(client, ammoOffset+(5*4));
			}
			else if (StrEqual(weapon, "weapon_rifle"))
			{
				ammo = GetEntData(client, ammoOffset+(3*4));
			}
			else if (StrEqual(weapon, "weapon_hunting_rifle"))
			{
				ammo = GetEntData(client, ammoOffset+(2*4));
			}
			else if (StrEqual(weapon, "weapon_pistol"))
			{
				ammo = GetEntProp(ent, Prop_Send, "m_hasDualWeapons" );
			}
		}
	}
}

GetClientWeaponInfo_l4d2(client, ent, &ammo, &clip, &upgradeBit, &upammo)
{
	if ( ent> 0)
	{
		new String:weapon[32];
		new ammoOffset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
		GetEdictClassname(ent, weapon, 32);
		upgradeBit = GetEntProp(ent, Prop_Send, "m_upgradeBitVec");
		upammo = GetEntProp(ent, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded");
		clip = GetEntProp(ent, Prop_Send, "m_iClip1");
		if (StrEqual(weapon, "weapon_rifle") || StrEqual(weapon, "weapon_rifle_sg552") || StrEqual(weapon, "weapon_rifle_desert") || StrEqual(weapon, "weapon_rifle_ak47"))
		{
			ammo = GetEntData(client, ammoOffset+(12));
		}
		else if (StrEqual(weapon, "weapon_rifle_m60"))
		{
			ammo = GetEntData(client, ammoOffset+(12));
		}
		else if (StrEqual(weapon, "weapon_smg") || StrEqual(weapon, "weapon_smg_silenced") || StrEqual(weapon, "weapon_smg_mp5"))
		{
			ammo = GetEntData(client, ammoOffset+(20));
		}
		else if (StrEqual(weapon, "weapon_pumpshotgun") || StrEqual(weapon, "weapon_shotgun_chrome"))
		{
			ammo = GetEntData(client, ammoOffset+(28));
		}
		else if (StrEqual(weapon, "weapon_autoshotgun") || StrEqual(weapon, "weapon_shotgun_spas"))
		{
			ammo = GetEntData(client, ammoOffset+(32));
		}
		else if (StrEqual(weapon, "weapon_hunting_rifle"))
		{
			ammo = GetEntData(client, ammoOffset+(36));
		}
		else if (StrEqual(weapon, "weapon_sniper_scout") || StrEqual(weapon, "weapon_sniper_military") || StrEqual(weapon, "weapon_sniper_awp"))
		{
			ammo = GetEntData(client, ammoOffset+(40));
		}
		else if (StrEqual(weapon, "weapon_grenade_launcher"))
		{
			ammo = GetEntData(client, ammoOffset+(68));
		}
		else if (StrEqual(weapon, "weapon_pistol"))
		{
			ammo = GetEntProp(ent, Prop_Send, "m_hasDualWeapons");
		}
	}
}

DropPrimarayWeapon_l4d1(client, String:weapon[LEN64] ,ammo, clip)
{
	new bool:cont=false;
	if (StrEqual(weapon, "weapon_pumpshotgun") || StrEqual(weapon, "weapon_autoshotgun"))
	{
		cont=true;
	}
	else if (StrEqual(weapon, "weapon_smg"))
	{
		cont=true;
	}
	else if (StrEqual(weapon, "weapon_rifle"))
	{
		cont=true;
	}
	else if (StrEqual(weapon, "weapon_hunting_rifle"))
	{
		cont=true;
	}
 	if(cont)
	{
		new index = CreateEntityByName(weapon);
		new Float:origin[3];
		GetClientEyePosition(client,origin);
		DispatchSpawn(index);
		TeleportEntity(index, origin, NULL_VECTOR, NULL_VECTOR);
		ActivateEntity(index);
		SetEntProp(index, Prop_Send, "m_iExtraPrimaryAmmo", ammo);
		SetEntProp(index, Prop_Send, "m_iClip1", clip);
	}
}

DropPrimarayWeapon_l4d2(client, String:weapon[LEN64] ,ammo, clip,  upgradeBit, upammo)
{
	new bool:cont=false;
	if (StrEqual(weapon, "weapon_rifle") || StrEqual(weapon, "weapon_rifle_sg552") || StrEqual(weapon, "weapon_rifle_desert") || StrEqual(weapon, "weapon_rifle_ak47"))
	{
		cont=true;
	}
	else if (StrEqual(weapon, "weapon_rifle_m60"))
	{
		cont=true;
	}
	else if (StrEqual(weapon, "weapon_smg") || StrEqual(weapon, "weapon_smg_silenced") || StrEqual(weapon, "weapon_smg_mp5"))
	{
		cont=true;
	}
	else if (StrEqual(weapon, "weapon_pumpshotgun") || StrEqual(weapon, "weapon_shotgun_chrome"))
	{
		cont=true;
	}
	else if (StrEqual(weapon, "weapon_autoshotgun") || StrEqual(weapon, "weapon_shotgun_spas"))
	{
		cont=true;
	}
	else if (StrEqual(weapon, "weapon_hunting_rifle"))
	{
		cont=true;
	}
	else if (StrEqual(weapon, "weapon_sniper_scout") || StrEqual(weapon, "weapon_sniper_military") || StrEqual(weapon, "weapon_sniper_awp"))
	{
		cont=true;
	}
	else if (StrEqual(weapon, "weapon_grenade_launcher"))
	{
		cont=true;
	}
	if(cont)
	{
		new index = CreateEntityByName(weapon);
		new Float:origin[3];
		GetClientEyePosition(client,origin);
		DispatchSpawn(index);
		TeleportEntity(index, origin, NULL_VECTOR, NULL_VECTOR);
		ActivateEntity(index);
		SetEntProp(index, Prop_Send, "m_iExtraPrimaryAmmo", ammo);
		SetEntProp(index, Prop_Send, "m_iClip1", clip);
		upgradeBit+=0;
		upammo+=0;
	}
}

public Action:map_transition(Handle:event, const String:name[], bool:dontBroadcast)
{
	SaveEquipmentAll();
}

ResetClientState(i)
{
	for(new slot=0; slot<=4; slot++)
	{
		ItemName[i][slot]="";
		ItemInfo[i][slot][0]=0;
		ItemInfo[i][slot][1]=0;
		ItemInfo[i][slot][2]=0;
		ItemInfo[i][slot][3]=0;
		ItemAttachEnt[i][slot]=0;
	}
	InHeal[i]=0.0;
	InRevive[i]=0.0;
	ViewOn[i]=false;
	LastButton[i]=0;
	SwapTime[i]=0.0;
	PressingTime[i]=0.0;
	PressStartTime[i]=0.0;
	LastMeSwitchTime[i]=0.0;
	LastSwitchTime[i]=0.0;
	ThrowTime[i]=0.0;
}

ResetAllState()
{
	for(new i=1; i<=MaxClients; i++)
	{
		ResetClientState(i);
	}
}

GameCheck()
{
	decl String:GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));
	if (StrEqual(GameName, "survival", false))
		GameMode = 3;
	else if (StrEqual(GameName, "versus", false) || StrEqual(GameName, "teamversus", false) || StrEqual(GameName, "scavenge", false) || StrEqual(GameName, "teamscavenge", false))
		GameMode = 2;
	else if (StrEqual(GameName, "coop", false) || StrEqual(GameName, "realism", false))
		GameMode = 1;
	else
	{
		GameMode = 0;
 	}
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrEqual(GameName, "left4dead2", false))
	{
		L4D2Version=true;
	}
	else
	{
		L4D2Version=false;
	}
	GameMode+=0;
}

public Action:heal_begin(Handle:event, const String:name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
 	InHeal[player]=GetEngineTime();
}

public Action:heal_end(Handle:event, const String:name[], bool:dontBroadcast)
{
 	new player = GetClientOfUserId(GetEventInt(event, "userid"));
 	InHeal[player]=0.0;
}

public Action:revive_begin(Handle:event, const String:name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
 	InRevive[player]=GetEngineTime();
}

public Action:revive_end(Handle:event, const String:name[], bool:dontBroadcast)
{
 	new player = GetClientOfUserId(GetEventInt(event, "userid"));
 	InRevive[player]=0.0;
}

public Action:heal_success(Handle:event, const String:name[], bool:dontBroadcast)
{
 	new player = GetClientOfUserId(GetEventInt(event, "userid"));
 	CreateTimer(0.1, DelayRestore, player, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:molotov_thrown(Handle:event, const String:name[], bool:dontBroadcast)
{
 	new player = GetClientOfUserId(GetEventInt(event, "userid"));
 	CreateTimer(1.5, DelayRestore, player, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:adrenaline_used(Handle:event, const String:name[], bool:dontBroadcast)
{
 	new player = GetClientOfUserId(GetEventInt(event, "userid"));
 	CreateTimer(0.1, DelayRestore, player, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:pills_used (Handle:event, const String:name[], bool:dontBroadcast)
{
 	new player = GetClientOfUserId(GetEventInt(event, "userid"));
 	CreateTimer(0.1, DelayRestore, player, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:item_pickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetConVarInt(l4d_me_view) == 1)
	{
		if (IsFakeClient(client)) { return; }
		Clipping_Fix[client] = CreateTimer(0.1, Clipping_Fix_Activate, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

bool:IsValidEntRef(entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}