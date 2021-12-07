#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>
#include <sdkhooks>
 
new g_sprite;
new g_iVelocity;
new GameMode;
new L4D2Version;

#define LEN64 64

new Float:InHeal[MAXPLAYERS+1];
new Float:InRevive[MAXPLAYERS+1]; 

new bool:ViewOn[MAXPLAYERS+1];
 
new String:ItemName[MAXPLAYERS+1][5][LEN64];
new ItemInfo[MAXPLAYERS+1][5][4];
new ItemAttachEnt[MAXPLAYERS+1][5];

new ControlMode[MAXPLAYERS+1];
new LastWeapon[MAXPLAYERS+1];

static String:BackupItemName[MAXPLAYERS+1][5][LEN64];
static BackupItemInfo[MAXPLAYERS+1][5][4];

new bool:DwEnable[MAXPLAYERS+1]; 
new bool:FirstRun[MAXPLAYERS+1]; 
new bool:g_gamestart=false;

new LastButton[MAXPLAYERS+1];  
new Float:LastDwSwitchTime[MAXPLAYERS+1];
new Float:SwapTime[MAXPLAYERS+1];
new Float:PressingTime[MAXPLAYERS+1];
new Float:PressStartTime[MAXPLAYERS+1];
new Float:ThrowTime[MAXPLAYERS+1];
new Float:LastSwitchTime[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "Multiple Equipments",
	author = "Pan Xiaohai, MasterMind",
	description = "Carry 2 items in each slot",
	version = "2.1",
	url = ""
}

new Handle:l4d2_dw_mode;
new Handle:l4d2_dw_msg;
new Handle:l4d2_dw_slot[5];

public OnPluginStart()
{
	GameCheck();
	
	l4d2_dw_mode=CreateConVar("multiple_equipments_mode", "0", "0:Mode Select Menu, 1:Mode 1 Single Tap, 2:Mode 2 Double Tap");
	l4d2_dw_msg=CreateConVar("multiple_equipments_notify", "1", "0:Disable, 1:Chat, 2:Hintbox");
	
	l4d2_dw_slot[0]=CreateConVar("multiple_equipments_slot0", "1", "0:Disable Slot0(Primary), 1:Enable");
	l4d2_dw_slot[1]=CreateConVar("multiple_equipments_slot1", "1", "0:Disable Slot1(Secondary), 1:Enable");	
	l4d2_dw_slot[2]=CreateConVar("multiple_equipments_slot2", "1", "0:Disable Slot2(Pipebomb), 1:Enable");
	l4d2_dw_slot[3]=CreateConVar("multiple_equipments_slot3", "1", "0:Disable Slot3(Medkits), 1:Enable");
	l4d2_dw_slot[4]=CreateConVar("multiple_equipments_slot4", "1", "0:Disable Slot4(Painpills), 1:Enable");
	
	HookEvent("player_spawn", player_spawn);	
	HookEvent("player_death", player_death); 
	HookEvent("player_bot_replace", player_bot_replace);	  
	HookEvent("bot_player_replace", bot_player_replace);	
 	
	HookEvent("round_start", round_start); 
	HookEvent("round_end", round_end);
	HookEvent("map_transition", map_transition, EventHookMode_Pre);	
	
	HookEvent("item_pickup", item_pickup);		 
	HookEvent("player_use", player_use);  
 
	RegConsoleCmd("sm_eview", sm_eview);  
 	
	HookEvent("heal_end", heal_end);
 	HookEvent("heal_begin", heal_begin);	
	
	HookEvent("revive_end", revive_end);
 	HookEvent("revive_begin", revive_begin); 
	HookEvent("weapon_fire", weapon_fire);
	HookEvent("heal_success", heal_success);
	if(L4D2Version)
	{
		HookEvent("molotov_thrown", molotov_thrown);
		HookEvent("adrenaline_used", adrenaline_used);		 
	}
	HookEvent("pills_used", pills_used);
	RegConsoleCmd("sm_s0", sm_s0); 
	RegConsoleCmd("sm_dw", sm_dw); 
	ResetAllState();
	DisableAllClient();
	DisableAllFirstRun();
	g_gamestart=false;
	g_sprite=g_sprite+0;
	g_iVelocity=g_iVelocity+0;
	AutoExecConfig(true, "l4d2_multiple_equipments"); 
}
 
public Action:sm_eview(client,args)
{ 
	if(client>0)
	{ 
		ViewOn[client]=!ViewOn[client];
 	} 
}

public Action:sm_s0(client,args)
{
	if(IsValidClient(client, 2, false, true) && DwEnable[client])
	{		 
		new Float:time=GetEngineTime();
		new buttons=GetClientButtons(client);
		if(time-PressStartTime[client]>0.01)
		{  
			Process(client, time, buttons, true);
		} 
		PressStartTime[client]=time;  
	}
	return Plugin_Handled;
}

public Action:sm_dw(client,args)
{
	if(IsValidClient(client, 2, false, true) && DwEnable[client])
	{
		ModeSelectMenu(client);
	}
	return Plugin_Handled;
}

ModeSelectMenu(client)
{
	new mode=GetConVarInt(l4d2_dw_mode);
	if(mode==0)
	{
		new Handle:menu = CreateMenu(MenuSelector1);
		SetMenuTitle(menu, "Select Control Mode for Multiple Equipments (!dw=Menu)");
		AddMenuItem(menu, "1", "Mode 1: Single press 1,2,3,4,5 to switch");
		AddMenuItem(menu, "2", "Mode 2: Double press 1,2,3,4,5 to switch"); 
		SetMenuExitButton(menu, true);
		
		DisplayMenu(menu, client, 15);
	}
	else
	{
		if(mode==1)ControlMode[client]=0;
		else ControlMode[client]=1;
	}
}

public MenuSelector1(Handle:menu, MenuAction:action, client, param2)
{	
	if (action == MenuAction_Select)
	{ 
		decl String:item[256], String:display[256];		
		GetMenuItem(menu, param2, item, sizeof(item), _, display, sizeof(display));		
		if (StrEqual(item, "1"))
		{
			ControlMode[client]=0;
			if(client>0 && IsClientInGame(client))ShowMsg(client, "Press keys 1,2 to switch main weapons+melee-pistols");
		}
		else if(StrEqual(item, "2"))
		{
			ControlMode[client]=1;
			if(client>0 && IsClientInGame(client))ShowMsg(client, "Double tap 1,2 to switch main weapons+melee-pistols");
		}
	}	 
}

public Action:weapon_fire(Handle:event, const String:name[], bool:dontBroadcast)
{ 
 	new client = GetClientOfUserId(GetEventInt(event, "userid")); 
	if(!DwEnable[client])return;
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
    if(!DwEnable[client])return Plugin_Continue; 
	if(ControlMode[client]==1)
	{ 
		new lastButton=LastButton[client];
		LastButton[client]=buttons;	
		new Float:time=GetEngineTime(); 
		if((buttons & IN_ATTACK2) && !(lastButton & IN_ATTACK2))
		{ 			 
			Process(client, time, buttons, false);		 
		} 
		else 
		{
			if(weapon>0)
			{  
				if(time-LastSwitchTime[client]<0.1)
				{				  
					Process(client, time, buttons, true, weapon); 
				} 
				else 
				{			 
					Process(client, time, buttons, false);				
				}
				LastSwitchTime[client]=time; 
			} 
		}
	}
	else if(ControlMode[client]==0)
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
			if(weapon>0)
			{  
				new newweapon=weapon;
				if(LastWeapon[client]==weapon)  //&& time-LastSwitchTime[client]<0.1)
				{ 			  
					new w=Process(client, time, buttons, true, weapon); 
					if(w>0)newweapon=w;
				}
				else 
				{			 
					new w=Process(client, time, buttons, false);
					if(w>0)newweapon=w;
				}
				LastSwitchTime[client]=time; 
				LastWeapon[client]=newweapon;
			} 
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
	if(!DwEnable[client])return;
	Process(client, GetEngineTime(), GetClientButtons(client), false);	
}

Process(client, Float:time, button, bool:isSwitch, currentWeapon=0)
{
	new theNewWeapon=0;
	if(!IsValidClient(client, 2, false, true))return theNewWeapon;  
	{
		new m_pounceAttacker=GetEntProp(client, Prop_Send, "m_pounceAttacker");
		new m_tongueOwner=GetEntProp(client, Prop_Send, "m_tongueOwner");
		new m_isIncapacitated=GetEntProp(client, Prop_Send, "m_isIncapacitated", 1);
		new m_isHangingFromLedge=GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1);
		if(L4D2Version)
		{
			new m_pummelAttacker=GetEntProp(client, Prop_Send, "m_pummelAttacker", 1);
			new m_jockeyAttacker=GetEntProp(client, Prop_Send, "m_jockeyAttacker", 1);
			if(m_pounceAttacker>0 || m_tongueOwner>0 || m_isHangingFromLedge>0 || m_isIncapacitated>0 || m_pummelAttacker>0 || m_jockeyAttacker>0)return theNewWeapon;
		}
		else
		{
			if(m_pounceAttacker>0 || m_tongueOwner>0 || m_isHangingFromLedge>0 || m_isIncapacitated>0)return theNewWeapon;
		}	
	} 
	new activeWeapon=currentWeapon;	if(activeWeapon==0)activeWeapon=GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if(activeWeapon<=0)	activeWeapon=0;	
	new activeSlot=-1; 
	for(new slot=0; slot<5; slot++)
	{
		if(!L4D2Version && slot==1)continue;
		if(GetConVarInt(l4d2_dw_slot[slot])==0)continue;
		if(slot==2)
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
	//// get weapon info
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
		GetItemInfo(client, slot, oldweapon, ammo, clip, upgradeBit, upammo, isPistol);	
		RemovePlayerItem(client, oldweapon);
		AcceptEntityInput(oldweapon, "kill");
	}	
	/////create new weapon
	new newweapon=0;
	if(!StrEqual(ItemName[client][slot], ""))
	{
		newweapon=CreateWeaponEnt(ItemName[client][slot]);			
	}
	if(newweapon>0)
	{
		EquipPlayerWeapon(client, newweapon);
		SetEntPropEnt(client, Prop_Data, "m_hActiveWeapon", newweapon);		
		SetItemInfo(client, slot, newweapon, ItemInfo[client][slot][0], ItemInfo[client][slot][1],ItemInfo[client][slot][2],ItemInfo[client][slot][3]);
		theNewWeapon=newweapon;
	}	
	/////save weapon info
	ItemName[client][slot]=oldWeaponName;
	ItemInfo[client][slot][0]=ammo; 
	ItemInfo[client][slot][1]=clip; 
	ItemInfo[client][slot][2]=upgradeBit; 
	ItemInfo[client][slot][3]=upammo;		
	RemoveItmeAttach(client, slot);
	ItemAttachEnt[client][slot]=0;
	ItemAttachEnt[client][slot]=CreateItemAttach(client, oldWeaponName, slot);
	return theNewWeapon;
}

SetItemInfo (client, slot, weapon, ammo, clip, upgradeBit, upammo)
{
	if(slot==0)
	{
		if(L4D2Version)SetClientWeaponInfo_l4d2(client, weapon, ammo, clip, upgradeBit, upammo);
	}
	else 
	{
		SetEntProp(weapon, Prop_Send, "m_iClip1",clip); 
 		if(slot==1 && ammo>0)SetEntProp(weapon, Prop_Send, "m_hasDualWeapons", ammo); 		 
	}	
}

GetItemInfo(client, slot, weapon, &ammo, &clip, &upgradeBit, &upammo, bool:isPistol)
{
	if(slot==0)
	{	 
		if(L4D2Version)GetClientWeaponInfo_l4d2(client, weapon, ammo, clip, upgradeBit, upammo);
	}
	else
	{		
		ammo=0;
		upgradeBit=0;
		upammo=0;
		clip = GetEntProp(weapon, Prop_Send, "m_iClip1"); 
		if(isPistol)ammo = GetEntProp(weapon, Prop_Send, "m_hasDualWeapons"); 		
	}
}
 
RemoveItmeAttach(client, slot)
{ 
	new startSlot=slot;
	new endSlot=slot;
	if(slot<0 || slot>4)
	{
		startSlot=0;
		endSlot=4;
	}		
	for(new i=startSlot; i<=endSlot; i++)
	{
		new attach=ItemAttachEnt[client][i];
		ItemAttachEnt[client][i]=0;		 
		if(attach>0 && IsValidEntS (attach, "prop_dynamic"))
		{  
			AcceptEntityInput(attach, "ClearParent");
			AcceptEntityInput(attach, "kill"); 
		}
	}  	
}
 
CreateItemAttach(client, String:classname[], slot)
{
	if(StrEqual(classname, ""))return 0;
	
	decl String:model[LEN64];
	if(L4D2Version)GetModelFromClass_l4d2(classname, model,slot);
	if(StrEqual(model, ""))return 0;	
	new ent=CreateEntityByName("prop_dynamic_override");
	SetEntityModel(ent, model);
	DispatchSpawn(ent); 	 
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 2); 
	decl String:sTemp[16];
	Format(sTemp, sizeof(sTemp), "target%d", client);
	DispatchKeyValue(client, "targetname", sTemp);
	SetVariantString(sTemp);
	AcceptEntityInput(ent, "SetParent", ent, ent, 0);	
	new Float:pos[3];
	new Float:ang[3];	
	if(slot==0)
	{
		SetVariantString("medkit");	
		AcceptEntityInput(ent, "SetParentAttachment"); 
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
		AcceptEntityInput(ent, "SetParentAttachment"); 
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
		AcceptEntityInput(ent, "SetParentAttachment"); 
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
		AcceptEntityInput(ent, "SetParentAttachment"); 
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
		AcceptEntityInput(ent, "SetParentAttachment"); 
		if(L4D2Version)
		{
			SetVector(pos, 5.0, 3.0, 0.0);
			SetVector(ang, 0.0, 90.0, 0.0);	
		}
		else 
		{
			SetVector(pos, 5.0, 3.0, 0.0);
			SetVector(ang, 0.0, 90.0, 0.0);			
		}
	}	
	TeleportEntity(ent, pos, ang, NULL_VECTOR);	
	SDKHook(ent, SDKHook_SetTransmit, Hook_SetTransmit);	 
	return ent;
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
				if(L4D2Version)DropPrimaryWeapon_l4d2(client, ItemName[client][slot], ammo, clip, info1, info2); 
			}
			else
			{
				new ent=CreateWeaponEnt(ItemName[client][slot]);
				TeleportEntity(ent, origin, NULL_VECTOR, NULL_VECTOR);		
				ActivateEntity(ent); 	
			}
		}
	}	 
}

SaveEquipmentAll()
{
	for(new i=1; i<=MaxClients; i++)
	{
		for(new slot=0; slot<=4; slot++)
		{
			BackupItemName[i][slot]=ItemName[i][slot];
			BackupItemInfo[i][slot][0]=ItemInfo[i][slot][0];
			BackupItemInfo[i][slot][1]=ItemInfo[i][slot][1];
			BackupItemInfo[i][slot][2]=ItemInfo[i][slot][2];
			BackupItemInfo[i][slot][3]=ItemInfo[i][slot][3];
		}
	}
}

LoadEquipment(i)
{	
 	for(new slot=0; slot<=4; slot++)
	{
		ItemName[i][slot]=BackupItemName[i][slot];
		ItemInfo[i][slot][0]=BackupItemInfo[i][slot][0];
		ItemInfo[i][slot][1]=BackupItemInfo[i][slot][1];
		ItemInfo[i][slot][2]=BackupItemInfo[i][slot][2];
		ItemInfo[i][slot][3]=BackupItemInfo[i][slot][3];
	}
}

AttachAllEquipment(client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client)==2 && !IsFakeClient(client))
	{	 		 
		for(new slot=0; slot<=4; slot++)
		{
			ItemAttachEnt[client][slot]=CreateItemAttach(client, ItemName[client][slot], slot);
		}
	}
}

public Action:Hook_SetTransmit(entity, client)
{  
	if(ViewOn[client])
	return Plugin_Continue;
	new bool:self=false; 
	{
		for(new slot=0; slot<=4; slot++)
		{
			if(entity==ItemAttachEnt[client][slot])
			{
				self=true;
				break;
			}
		}
	}
	if(self)
	{
		new Float:t=GetEngineTime();
		if(t-InHeal[client]<5.0 || t-InRevive[client]<5.0) return Plugin_Continue;
		return Plugin_Handled;
	}
	return Plugin_Continue;
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

/////////////////////primary weapon
#define model_weapon_rifle "models/w_models/weapons/w_rifle_m16a2.mdl" 
#define model_weapon_rifle_sg552 "models/w_models/weapons/w_rifle_sg552.mdl" 
#define model_weapon_rifle_desert "models/w_models/weapons/w_desert_rifle.mdl" 
#define model_weapon_rifle_ak47 "models/w_models/weapons/w_rifle_ak47.mdl"
#define model_weapon_rifle_m60 "models/w_models/weapons/w_m60.mdl"
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
#define model_weapon_grenade_launcher "models/w_models/weapons/w_grenade_launcher.mdl"

//////////////////////////slot 1
#define model_weapon_pistol "models/w_models/weapons/w_pistol_A.mdl" 
#define model_weapon_pistol_magnum "models/w_models/weapons/w_desert_eagle.mdl"  
#define model_weapon_chainsaw "models/weapons/melee/w_chainsaw.mdl"
#define model_weapon_melee_fireaxe "models/weapons/melee/w_fireaxe.mdl"  
#define model_weapon_melee_baseball_bat "models/weapons/melee/w_bat.mdl"  
#define model_weapon_melee_crowbar "models/weapons/melee/w_crowbar.mdl"  
#define model_weapon_melee_electric_guitar "models/weapons/melee/w_electric_guitar.mdl"  
#define model_weapon_melee_cricket_bat "models/weapons/melee/w_cricket_bat.mdl"  
#define model_weapon_melee_frying_pan "models/weapons/melee/w_frying_pan.mdl"  
#define model_weapon_melee_golfclub "models/weapons/melee/w_golfclub.mdl" 
#define model_weapon_melee_machete "models/weapons/melee/w_machete.mdl" 
#define model_weapon_melee_katana "models/weapons/melee/w_katana.mdl"
#define model_weapon_melee_tonfa "models/weapons/melee/w_tonfa.mdl"
#define model_weapon_melee_foamfinger "models/bunny/weapons/melee/w_b_foamfinger.mdl"
#define model_weapon_melee_sledgehammer "models/weapons/melee/w_sledgehammer.mdl"
#define model_weapon_melee_riotshield "models/weapons/melee/w_riotshield.mdl"
#define model_weapon_melee_paintrain "models/weapons/melee/w_paintrain.mdl"
#define model_weapon_melee_swordshield "models/weapons/melee/w_splinkswashereaswell.mdl"
#define model_weapon_melee_arm "models/weapons/melee/w_arm.mdl"
#define model_weapon_melee_foot "models/weapons/melee/w_foot.mdl"
#define model_weapon_melee_pickaxe "models/weapons/melee/w_pickaxe.mdl"

//////////////////////////slot 2
#define model_weapon_molotov "models/w_models/weapons/w_eq_molotov.mdl"  
#define model_weapon_pipe_bomb "models/w_models/weapons/w_eq_pipebomb.mdl" 
#define model_weapon_vomitjar "models/w_models/weapons/w_eq_bile_flask.mdl"

//////////////////////////slot 3
#define model_weapon_first_aid_kit "models/w_models/weapons/w_eq_Medkit.mdl"    
#define model_weapon_defibrillator "models/w_models/weapons/w_eq_defibrillator.mdl" 
#define model_weapon_upgradepack_explosive "models/w_models/weapons/w_eq_explosive_ammopack.mdl"   
#define model_weapon_upgradepack_incendiary "models/w_models/weapons/w_eq_incendiary_ammopack.mdl"

//////////////////////////slot 4
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
		else if (StrEqual(weapon, "weapon_melee_foamfinger"))strcopy(model, LEN64, model_weapon_melee_foamfinger);
		else if (StrEqual(weapon, "weapon_melee_sledgehammer"))strcopy(model, LEN64, model_weapon_melee_sledgehammer);
		else if (StrEqual(weapon, "weapon_melee_paintrain"))strcopy(model, LEN64, model_weapon_melee_paintrain);
		else if (StrEqual(weapon, "weapon_melee_swordshield"))strcopy(model, LEN64, model_weapon_melee_swordshield);
		else if (StrEqual(weapon, "weapon_melee_arm"))strcopy(model, LEN64, model_weapon_melee_arm);
		else if (StrEqual(weapon, "weapon_melee_foot"))strcopy(model, LEN64, model_weapon_melee_foot);
		else if (StrEqual(weapon, "weapon_melee_pickaxe"))strcopy(model, LEN64, model_weapon_melee_pickaxe);
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
			else if(StrContains(model, "foamfinger")>=0)classname="weapon_melee_foamfinger";
			else if(StrContains(model, "paintrain")>=0)classname="weapon_melee_paintrain";
			else if(StrContains(model, "swordshield")>=0)classname="weapon_melee_swordshield";
			else if(StrContains(model, "sledgehammer")>=0)classname="weapon_melee_sledgehammer";
			else if(StrContains(model, "arm")>=0)classname="weapon_melee_arm";
			else if(StrContains(model, "foot")>=0)classname="weapon_melee_pickaxe";				
			else classname="";
		}
	}
}

CreateWeaponEnt(String:classname[])
{
	if(StrEqual(classname, ""))return 0;
	if(StrContains(classname, "weapon_melee_")<0)
	{
		new ent=CreateEntityByName(classname);
		DispatchSpawn(ent); 
		return ent;
	}
	else
	{ 
		new ent=CreateEntityByName("weapon_melee"); 
		if(StrEqual(classname, "weapon_melee_fireaxe"))DispatchKeyValue(ent, "melee_script_name", "fireaxe"); 
		else if(StrEqual(classname, "weapon_melee_baseball_bat"))DispatchKeyValue(ent, "melee_script_name",  "baseball_bat");
		else if(StrEqual(classname, "weapon_melee_crowbar"))DispatchKeyValue(ent, "melee_script_name", "crowbar");		
		else if(StrEqual(classname, "weapon_melee_electric_guitar"))DispatchKeyValue(ent, "melee_script_name",  "electric_guitar");		
		else if(StrEqual(classname, "weapon_melee_cricket_bat"))DispatchKeyValue(ent, "melee_script_name", "cricket_bat");		
		else if(StrEqual(classname, "weapon_melee_frying_pan"))DispatchKeyValue(ent, "melee_script_name", "frying_pan");		
		else if(StrEqual(classname, "weapon_melee_golfclub"))DispatchKeyValue(ent, "melee_script_name", "golfclub");		
		else if(StrEqual(classname, "weapon_melee_machete"))DispatchKeyValue(ent, "melee_script_name", "machete");	
		else if(StrEqual(classname, "weapon_melee_katana"))DispatchKeyValue(ent, "melee_script_name", "katana");		
		else if(StrEqual(classname, "weapon_melee_tonfa"))DispatchKeyValue(ent, "melee_script_name", "tonfa"); 
		else if(StrEqual(classname, "weapon_melee_riotshield"))DispatchKeyValue(ent, "melee_script_name", "riotshield");
		else if(StrEqual(classname, "weapon_melee_foamfinger"))DispatchKeyValue(ent, "melee_script_name", "b_foamfinger");
		else if(StrEqual(classname, "weapon_melee_sledgehammer"))DispatchKeyValue(ent, "melee_script_name", "bt_sledge");
		else if(StrEqual(classname, "weapon_melee_paintrain"))DispatchKeyValue(ent, "melee_script_name", "bt_nail");
		else if(StrEqual(classname, "weapon_melee_swordshield"))DispatchKeyValue(ent, "melee_script_name", "helms_sword_and_shield");
		else if(StrEqual(classname, "weapon_melee_arm"))DispatchKeyValue(ent, "melee_script_name", "arm");
		else if(StrEqual(classname, "weapon_melee_foot"))DispatchKeyValue(ent, "melee_script_name", "foot");
		else if(StrEqual(classname, "weapon_melee_pickaxe"))DispatchKeyValue(ent, "melee_script_name", "pickaxe");		
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
		PrecacheModel(model_weapon_melee_pickaxe);
		PrecacheModel(model_weapon_melee_foot);
		PrecacheModel(model_weapon_melee_swordshield);
		PrecacheModel(model_weapon_melee_arm);
		PrecacheModel(model_weapon_melee_paintrain);
		PrecacheModel(model_weapon_melee_foamfinger);
		PrecacheModel(model_weapon_melee_sledgehammer);
		
		PrecacheModel(model_weapon_molotov);
		PrecacheModel(model_weapon_pipe_bomb);
		PrecacheModel(model_weapon_vomitjar);		
		
		PrecacheModel(model_weapon_first_aid_kit);
		PrecacheModel(model_weapon_defibrillator);
		PrecacheModel(model_weapon_upgradepack_explosive); 
		PrecacheModel(model_weapon_upgradepack_incendiary); 
		
		PrecacheModel(model_weapon_pain_pills);
		PrecacheModel(model_weapon_adrenaline); 

		PrecacheGeneric("scripts/melee/baseball_bat.txt", true);
		PrecacheGeneric("scripts/melee/cricket_bat.txt", true);
		PrecacheGeneric("scripts/melee/crowbar.txt", true);
		PrecacheGeneric("scripts/melee/electric_guitar.txt", true);
		PrecacheGeneric("scripts/melee/fireaxe.txt", true);
		PrecacheGeneric("scripts/melee/frying_pan.txt", true);
		PrecacheGeneric("scripts/melee/golfclub.txt", true);
		PrecacheGeneric("scripts/melee/katana.txt", true);
		PrecacheGeneric("scripts/melee/machete.txt", true);
		PrecacheGeneric("scripts/melee/tonfa.txt", true);		
		PrecacheGeneric("scripts/melee/riotshield.txt", true); 
		PrecacheGeneric("scripts/melee/bt_sledge.txt", true);
		PrecacheGeneric("scripts/melee/bt_nail.txt", true);
		PrecacheGeneric("scripts/melee/pickaxe.txt", true);
		PrecacheGeneric("scripts/melee/helms_sword_and_shield.txt", true);
		PrecacheGeneric("scripts/melee/foot.txt", true);
		PrecacheGeneric("scripts/melee/arm.txt", true);
		PrecacheGeneric("scripts/melee/b_foamfinger.txt", true);
	}
	DisableAllClient();
	DisableAllFirstRun();
}
 
SetVector(Float:target[3], Float:x, Float:y, Float:z)
{
	target[0]=x;
	target[1]=y;
	target[2]=z;
}
 
IsValidClient(client, team=0, bool:includeBot=true, bool:alive=true)
{
	if(client>0 && client<=MaxClients)
	{
		if(IsClientInGame(client))
		{
			if(GetClientTeam(client)!=team && team!=0)return false;
			if(IsFakeClient(client) && !includeBot)return false;			
			if(!IsPlayerAlive(client) && alive)return false;
			return true;
		}
	}
	return false;
}

public player_bot_replace(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(Spawn_Event, "player"));
	new bot = GetClientOfUserId(GetEventInt(Spawn_Event, "bot")); 	
	EnableClient(client, false);
	EnableClient(bot, false); 
	RemoveItmeAttach(client, -1);
	RemoveItmeAttach(bot, -1);	
	ResetClientState(client);
	ResetClientState(bot);
}

public bot_player_replace(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(Spawn_Event, "player"));
	new bot = GetClientOfUserId(GetEventInt(Spawn_Event, "bot"));	
	EnableClient(client, false);
	EnableClient(bot, false);		
	RemoveItmeAttach(client, -1);
	RemoveItmeAttach(bot, -1);	
	ResetClientState(client);
	ResetClientState(bot);
}

public Action:player_spawn(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	EnableClient(client, false);
	ResetClientState(client);	 	
}

public Action:player_death(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	EnableClient(client, false);
	if(client>0 && IsClientInGame(client) && GetClientTeam(client)==2)
	{		
		RemoveItmeAttach(client, -1);	 
		DropSecondaryItem(client); 		
	}
	ResetClientState(client); 
}
  
SetClientWeaponInfo_l4d2(client, ent , ammo, clip, upgradeBit, upammo)
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
			SetEntProp(ent, Prop_Send, "m_hasDualWeapons", ammo); 
		}		
	} 
}

GetClientWeaponInfo_l4d2(client, ent, &ammo, &clip, &upgradeBit, &upammo)
{ 
	if (ent> 0)
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
  
DropPrimaryWeapon_l4d2(client, String:weapon[LEN64], ammo, clip, upgradeBit, upammo)
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

public Action:round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_gamestart=false;  	
	DisableAllClient();
	DisableAllFirstRun(); 
}
 
public Action:round_end(Handle:event, const String:name[], bool:dontBroadcast)
{  
	UnHookAll();
	g_gamestart=false; 
	DisableAllClient();
	DisableAllFirstRun(); 
}

public Action:map_transition(Handle:event, const String:name[], bool:dontBroadcast)
{  
	UnHookAll();
	g_gamestart=false;
	SaveEquipmentAll(); 	
	DisableAllClient();
	DisableAllFirstRun();
}

EnableClient(client, bool:isenable)
{
	if(isenable)
	{
		if(IsValidClient(client, 2, false, true))DwEnable[client]=true;
		else DwEnable[client]=false;
	}
	else
	{
		DwEnable[client]=false;
	}
}

DisableAllClient()
{
	g_gamestart=false;
	for(new i=1; i<=MaxClients; i++)
	{
		DwEnable[i]=false;
	}
}

DisableAllFirstRun()
{	 
	for(new i=1; i<=MaxClients; i++)
	{
		FirstRun[i]=true;
	}
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
	DwEnable[i]=false;
	LastButton[i]=0;
	SwapTime[i]=0.0;
	PressingTime[i]=0.0;
	PressStartTime[i]=0.0;
	LastDwSwitchTime[i]=0.0;
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
 
UnHookAll()
{
	for(new i=0; i<=MaxClients; i++)
	{ 
		DwEnable[i]=false;
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
ShowMsg(client,String:msg[])
{
	new mode=GetConVarInt(l4d2_dw_msg);
	if(mode==0)return;
	if(mode==1)
	{
		if(client==0)PrintHintTextToAll(msg);
		else PrintHintText(client, msg);
	}
	if(mode==2)
	{
		if(client==0)PrintHintTextToAll(msg);
		else PrintHintText(client, msg);
	}
}

public Action:player_use(Handle:event, const String:name[], bool:dontBroadcast)
{  
	return;
}

public Action:item_pickup(Handle:event, const String:name[], bool:dontBroadcast) 
{  
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client==0)
		return;
	//if(!(GetClientButtons(client) & IN_USE))
	//	return;
	if(g_gamestart==false)
	{				
		g_gamestart=true;
		ShowMsg(0, "DON'T BE A HERO. Carry 2 main + secondary weapons");
	} 	 
	if(DwEnable[client]==false)
	{		
		EnableClient(client,true);
		ModeSelectMenu(client);
	}
	if(FirstRun[client]==true)
	{
		FirstRun[client]=false;
		LoadEquipment(client);
		AttachAllEquipment(client);
	}
	return;
}