/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <sdktools>

#define CLASS_SMOKER	1
#define CLASS_BOOMER	2
#define CLASS_HUNTER	3
#define CLASS_SPITTER	4
#define CLASS_JOCKEY	5
#define CLASS_CHARGER	6
new CLASS_TANK=	5;
#define CLASS_EXPLODED	10
#define CLASS_INCAP	12
#define CLASS_HURT	13
#define CLASS_HURT_BY_SURVIVOR	14
#define CLASS_SHOVE_BY_INFECTED	15
#define CLASS_SHOVE_BY_SURVIVOR	16
#define CLASS_LEDGE_GRAB	17

new Handle:l4d_drop_probability[20];
new Handle:l4d_drop_enable= INVALID_HANDLE;
new bool:l4d2=false;
new GameMode;
public Plugin:myinfo = 
{
	name = "L4D & L4D2 item drop",
	author = "Pan Xiaohai & Frustian & kwski43",
	description = "<- Description ->",
	version = "1.1",
	url = "<- URL ->"
}

public OnPluginStart()
{
	GameCheck(); 	
	l4d_drop_enable = CreateConVar("l4d_drop_enable", "1", "0 : Disable Item Drop, 1: Enable Item Drop");
	l4d_drop_probability[CLASS_HUNTER] = CreateConVar("l4d_drop_hunter", "10.0", "Drop probability by Hunter Pounce");
	l4d_drop_probability[CLASS_BOOMER] = CreateConVar("l4d_drop_boomer", "10.0", "Drop probability by Boomer Explosion");
	l4d_drop_probability[CLASS_SMOKER] = CreateConVar("l4d_drop_smoker", "10.0", "Drop probability by Smoker Tongue");	
	l4d_drop_probability[CLASS_JOCKEY] = CreateConVar("l4d_drop_jockey", "10.0", "Drop probability by Jockey Ride");	
	l4d_drop_probability[CLASS_CHARGER] = CreateConVar("l4d_drop_charger", "10.0", "Drop probability by Charger Charge");	
	l4d_drop_probability[CLASS_TANK] = CreateConVar("l4d_drop_tank", "10.0", "Drop probability by Tank Attacks");	
	l4d_drop_probability[CLASS_LEDGE_GRAB] = CreateConVar("l4d_drop_ledge_grab", "10.0", "Drop probability by Ledge Incapacitation");	
	l4d_drop_probability[CLASS_INCAP] = CreateConVar("l4d_drop_incap", "20.0", "Drop probability by Incapacitation");	
	l4d_drop_probability[CLASS_EXPLODED] = CreateConVar("l4d_drop_explode", "10.0", "Drop probability by Explosives");	
	l4d_drop_probability[CLASS_HURT] = CreateConVar("l4d_drop_hurt", "0.0", "Drop probability by Common infected");	
	l4d_drop_probability[CLASS_HURT_BY_SURVIVOR] = CreateConVar("l4d_drop_hurt_by_survivor", "0.0", "Drop probability by Survivor Friendly Fire");	
	l4d_drop_probability[CLASS_SHOVE_BY_INFECTED] = CreateConVar("l4d_drop_shove_by_infected", "5.0", "Drop probability by Special Infected Secondary Attack");	
	l4d_drop_probability[CLASS_SHOVE_BY_SURVIVOR] = CreateConVar("l4d_drop_shove_by_survivor", "0.0", "Drop probability by Survivor Shoves");	

	RegConsoleCmd("sm_drop", Command_Drop);
	
	if(GameMode!=2)
	{
		if(l4d2)
		{
			HookEvent("jockey_ride", infected_ablility);
			HookEvent("charger_carry_start", infected_ablility);
		}
		HookEvent("tongue_grab",  infected_ablility);
		HookEvent("player_ledge_grab",  player_ledge_grab);
		HookEvent("lunge_pounce", infected_ablility);
		HookEvent("player_now_it", player_now_it );
		HookEvent("player_shoved", player_shoved);
		HookEvent("player_incapacitated_start", player_incapacitated_start); 
		HookEvent("player_hurt", player_hurt);  
		 
		AutoExecConfig(true, "l4d12_drop"); 
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
		CLASS_TANK=8;
		l4d2=true;
	}	
	else
	{
		CLASS_TANK=5;
		l4d2=false;
	}
}
 
public infected_ablility(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(l4d_drop_enable)==0)return;
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new class = GetEntProp(client, Prop_Send, "m_zombieClass");	
	SetupDrop(victim, client, class, true);
}
public player_ledge_grab(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(l4d_drop_enable)==0)return;
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	SetupDrop(victim, 0, CLASS_LEDGE_GRAB, true);
}
public player_now_it(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(l4d_drop_enable)==0)return;
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new exploded = GetEventBool(event, "exploded") ;
	 
	if(exploded)
	{
		SetupDrop(victim, attacker,CLASS_BOOMER, false);
		
	}
}
public player_incapacitated_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(l4d_drop_enable)==0)return;
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	SetupDrop(client, attacker, CLASS_INCAP, false);
}
public player_shoved(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(l4d_drop_enable)==0)return;
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (GetClientTeam(victim) == 2)
	{
		if(GetClientTeam(attacker)==2)SetupDrop(victim, attacker, CLASS_SHOVE_BY_SURVIVOR,false);
		else SetupDrop(victim, attacker, CLASS_SHOVE_BY_INFECTED, false);
	}
}
public player_hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(l4d_drop_enable)==0)return;
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new type =GetEventInt(event, "type");
	//PrintToChatAll (" type %d", type);
	if(victim>0 && GetClientTeam(victim)==2)
	{
		if((l4d2 && (type==134217792 || type==1107296256)) || (!l4d2 && (type==64 || type==1107296256)))
		{
			//PrintToChatAll ("You lost something by explosion!");
			SetupDrop(victim, attacker, CLASS_EXPLODED, false);
		}
		else if(attacker>0 && victim!=attacker)
		{
			if(GetClientTeam(attacker)==3)
			{
				//PrintToChatAll ("You lost something by Infected!");
				new class = GetEntProp(victim, Prop_Send, "m_zombieClass");				
				if(class==CLASS_TANK)SetupDrop(victim, attacker, CLASS_TANK, false);	
				else SetupDrop(victim, attacker, CLASS_HURT, false); 
			}
			else
			{
				//PrintToChatAll ("You lost something by Survivor!");
				SetupDrop(victim, attacker, CLASS_HURT_BY_SURVIVOR, false);
			}
		}
		else 
		{
			//PrintToChatAll ("You lost something!");
			SetupDrop(victim, attacker, CLASS_HURT, false); 
		}
	}
 
}
public Action:Command_Drop(client, args)
{
	if (client == 0 || GetClientTeam(client) != 2 || !IsPlayerAlive(client))return Plugin_Handled;
	new accepter=0;
	accepter=GetClientAimTarget(client);
	if(accepter<0)accepter=0;
	if(accepter>0)
	{
		new Float:pos1[3];
		new Float:pos2[3];
		GetClientEyePosition(client,pos1);
		GetClientEyePosition(accepter,pos2);
		if(GetVectorDistance(pos1, pos2)>500.0)accepter=0;
	}
	Drop(client, true, 0,true, accepter);
	return Plugin_Handled;
}
SetupDrop(victim, client, class, bool:dropcurrent)
{
	client=client*2;
	if(victim>0 && IsPlayerAlive(victim))
	{
		//PrintToChatAll("%f", GetConVarFloat( l4d_drop_probability[class] ));
		if(GetRandomFloat(0.0, 100.0)<GetConVarFloat( l4d_drop_probability[class] ))
		{
			Drop(victim, dropcurrent, GetRandomInt(0,1), false);
		}
	}
}
GetCurrentWeaponSlot(client)
{
	new slot=-1; 
	
	decl String:weapon[32];
	GetClientWeapon(client,weapon , 32);
	//PrintToChatAll("%s",weapon);
	
	if (StrEqual(weapon, "weapon_pumpshotgun") || StrEqual(weapon, "weapon_autoshotgun") || StrEqual(weapon, "weapon_rifle") || StrEqual(weapon, "weapon_smg") || StrEqual(weapon, "weapon_hunting_rifle") || StrEqual(weapon, "weapon_sniper_scout") || StrEqual(weapon, "weapon_sniper_military") || StrEqual(weapon, "weapon_sniper_awp") || StrEqual(weapon, "weapon_smg_silenced") || StrEqual(weapon, "weapon_smg_mp5") || StrEqual(weapon, "weapon_shotgun_spas") || StrEqual(weapon, "weapon_shotgun_chrome") || StrEqual(weapon, "weapon_rifle_sg552") || StrEqual(weapon, "weapon_rifle_desert") || StrEqual(weapon, "weapon_rifle_ak47") || StrEqual(weapon, "weapon_grenade_launcher") || StrEqual(weapon, "weapon_rifle_m60"))
		slot=0;
	else if (StrEqual(weapon, "weapon_pistol") || StrEqual(weapon, "weapon_pistol_magnum") || StrEqual(weapon, "weapon_chainsaw") || StrEqual(weapon, "weapon_melee"))
		slot=1;
	else if (StrEqual(weapon, "weapon_pipe_bomb") || StrEqual(weapon, "weapon_molotov") || StrEqual(weapon, "weapon_vomitjar"))
		slot=2;
	else if (StrEqual(weapon, "weapon_first_aid_kit") || StrEqual(weapon, "weapon_defibrillator") || StrEqual(weapon, "weapon_upgradepack_explosive") || StrEqual(weapon, "weapon_upgradepack_incendiary"))
		slot=3;
	else if (StrEqual(weapon, "weapon_pain_pills") || StrEqual(weapon, "weapon_adrenaline"))
		slot=4;
 
	if(slot	<0 )
	{
	 
		for(new i=0; i<5; i++)
		{
			new s=GetPlayerWeaponSlot(client, i);
			if(s>0)
			{
				slot=i;
				break;
			}
		} 
	}
	return slot;
}
Drop(client, bool:dropcurrent, count, bool:throww, receiver=0)
{
	new bool:msg=false;
	if(dropcurrent)
	{
		new s=GetCurrentWeaponSlot(client);
		if(s>=0)
		{
			msg=true;
			DropSlot(client, s, throww, receiver); 
		}
		
	}
	if(count==0 && !dropcurrent)count=1;
	if(count>0)
	{
		new slot[5];
		new m=0;
		for(new i=0; i<5; i++)
		{
			if (GetPlayerWeaponSlot(client, i) > 0)
			{
				slot[m++]=i;
			}
		}
		if(m<=count)count=m;
		for(new i=0; i<count && m>0; i++)
		{
			new r=GetRandomInt(0, m-1);
			DropSlot(client, slot[r], throww,receiver);
			slot[r]=slot[m-1];
			msg=true;
			m--;
		}
	}
	if(msg)
	{
		PrintHintText(client, "You dropped something!");
	}
}

DropSlot(client, slot, bool:throww=false, receiver=0)
{
	if (HasEntProp(slot, Prop_Data, "m_bInReload") && GetEntProp(slot, Prop_Data, "m_bInReload") > 0)
		return;
	
	if(l4d2)DropSlot_l4d2(client, slot, throww, receiver);
	else DropSlot_l4d1(client, slot, throww, receiver);
}
 

#define MODEL_V_FIREAXE "models/weapons/melee/v_fireaxe.mdl"
#define MODEL_V_FRYING_PAN "models/weapons/melee/v_frying_pan.mdl"
#define MODEL_V_MACHETE "models/weapons/melee/v_machete.mdl"
#define MODEL_V_BASEBALL_BAT "models/weapons/melee/v_bat.mdl"
#define MODEL_V_CROWBAR "models/weapons/melee/v_crowbar.mdl"
#define MODEL_V_CRICKET_BAT "models/weapons/melee/v_cricket_bat.mdl"
#define MODEL_V_TONFA "models/weapons/melee/v_tonfa.mdl"
#define MODEL_V_KATANA "models/weapons/melee/v_katana.mdl"
#define MODEL_V_ELECTRIC_GUITAR "models/weapons/melee/v_electric_guitar.mdl"
#define MODEL_V_GOLFCLUB "models/weapons/melee/v_golfclub.mdl"
#define MODEL_V_SHIELD "models/weapons/melee/v_riotshield.mdl"
#define MODEL_V_KNIFE "models/v_models/v_knife_t.mdl"


// code from kwski43 [L4D2] Caught Item Drop http://forums.alliedmods.net/showthread.php?t=133610
DropSlot_l4d2(client, slot, bool:throww=false, receiver=0)
{
	new oldweapon=GetPlayerWeaponSlot(client, slot);
	if (oldweapon > 0)
	{
		new String:weapon[32];
		new ammo;
		new clip;
		new upgrade;
		new upammo;
		new ammoOffset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
		GetEdictClassname(oldweapon, weapon, 32);

		if (slot == 0)
		{
			clip = GetEntProp(oldweapon, Prop_Send, "m_iClip1");
			upgrade = GetEntProp(oldweapon, Prop_Send, "m_upgradeBitVec");
			upammo = GetEntProp(oldweapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded");
			if (StrEqual(weapon, "weapon_rifle") || StrEqual(weapon, "weapon_rifle_sg552") || StrEqual(weapon, "weapon_rifle_desert") || StrEqual(weapon, "weapon_rifle_ak47"))
			{
				ammo = GetEntData(client, ammoOffset+(12));
				SetEntData(client, ammoOffset+(12), 0);
			}
			else if (StrEqual(weapon, "weapon_smg") || StrEqual(weapon, "weapon_smg_silenced") || StrEqual(weapon, "weapon_smg_mp5"))
			{
				ammo = GetEntData(client, ammoOffset+(20));
				SetEntData(client, ammoOffset+(20), 0);
			}
			else if (StrEqual(weapon, "weapon_pumpshotgun") || StrEqual(weapon, "weapon_shotgun_chrome"))
			{
				ammo = GetEntData(client, ammoOffset+(28));
				SetEntData(client, ammoOffset+(28), 0);
			}
			else if (StrEqual(weapon, "weapon_autoshotgun") || StrEqual(weapon, "weapon_shotgun_spas"))
			{
				ammo = GetEntData(client, ammoOffset+(32));
				SetEntData(client, ammoOffset+(32), 0);
			}
			else if (StrEqual(weapon, "weapon_hunting_rifle"))
			{
				ammo = GetEntData(client, ammoOffset+(36));
				SetEntData(client, ammoOffset+(36), 0);
			}
			else if (StrEqual(weapon, "weapon_sniper_scout") || StrEqual(weapon, "weapon_sniper_military") || StrEqual(weapon, "weapon_sniper_awp"))
			{
				ammo = GetEntData(client, ammoOffset+(40));
				SetEntData(client, ammoOffset+(40), 0);
			}
			else if (StrEqual(weapon, "weapon_grenade_launcher"))
			{
				ammo = GetEntData(client, ammoOffset+(68));
				SetEntData(client, ammoOffset+(68), 0);
			}
			else if (StrEqual(weapon, "weapon_rifle_m60"))
			{
				clip = GetEntProp(oldweapon, Prop_Send, "m_iClip1");
			}
			else return;
		}
		new index = CreateEntityByName(weapon); 
		//index=oldweapon;
		new bool:dual=false;
		if (slot == 1)
		{
			if (StrEqual(weapon, "weapon_melee"))
			{
				
				new String:item[150];
				GetEntPropString(oldweapon , Prop_Data, "m_ModelName", item, sizeof(item));
				//PrintToChat(client, "%s", item);
				if (StrEqual(item, MODEL_V_FIREAXE))
				{
					//DispatchKeyValue(index, "model", MODEL_V_FIREAXE);
					DispatchKeyValue(index, "melee_script_name", "fireaxe")
;
				}
				else if (StrEqual(item, MODEL_V_FRYING_PAN))
				{
					//DispatchKeyValue(index, "model", MODEL_V_FRYING_PAN);
					DispatchKeyValue(index, "melee_script_name", "frying_pan")
;
				}
				else if (StrEqual(item, MODEL_V_MACHETE))
				{
					//DispatchKeyValue(index, "model", MODEL_V_MACHETE);
					DispatchKeyValue(index, "melee_script_name", "machete")
;
				}
				else if (StrEqual(item, MODEL_V_BASEBALL_BAT))
				{
					//DispatchKeyValue(index, "model", MODEL_V_BASEBALL_BAT);
					DispatchKeyValue(index, "melee_script_name", "baseball_bat")
;
				}
				else if (StrEqual(item, MODEL_V_CROWBAR))
				{
					//DispatchKeyValue(index, "model", MODEL_V_CROWBAR);
					DispatchKeyValue(index, "melee_script_name", "crowbar")
;
				}
				else if (StrEqual(item, MODEL_V_CRICKET_BAT))
				{
					//DispatchKeyValue(index, "model", MODEL_V_CRICKET_BAT);
					DispatchKeyValue(index, "melee_script_name", "cricket_bat")
;
				}
				else if (StrEqual(item, MODEL_V_TONFA))
				{
					//DispatchKeyValue(index, "model", MODEL_V_TONFA);
					DispatchKeyValue(index, "melee_script_name", "tonfa")
;
				}
				else if (StrEqual(item, MODEL_V_KATANA))
				{
					//DispatchKeyValue(index, "model", MODEL_V_KATANA);
					DispatchKeyValue(index, "melee_script_name", "katana")
;
				}
				else if (StrEqual(item, MODEL_V_ELECTRIC_GUITAR))
				{
					//DispatchKeyValue(index, "model", MODEL_V_ELECTRIC_GUITAR);
					DispatchKeyValue(index, "melee_script_name", "electric_guitar")
;
				}
				else if (StrEqual(item, MODEL_V_GOLFCLUB))
				{
					//DispatchKeyValue(index, "model", MODEL_V_GOLFCLUB);
					DispatchKeyValue(index, "melee_script_name", "golfclub")
;
				}
				else if (StrEqual(item, MODEL_V_SHIELD))
				{
					//DispatchKeyValue(index, "model", MODEL_V_SHIELD);
					DispatchKeyValue(index, "melee_script_name", "riotshield")
;
				}
				else if (StrEqual(item, MODEL_V_KNIFE))
				{
					//DispatchKeyValue(index, "model", MODEL_V_KNIFE);
					DispatchKeyValue(index, "melee_script_name", "knife")
;
				}	
				else return;
			}
			else if (StrEqual(weapon, "weapon_chainsaw"))
			{
				clip = GetEntProp(oldweapon, Prop_Send, "m_iClip1");
			}
			else if (StrEqual(weapon, "weapon_pistol_magnum"))
			{
				clip = GetEntProp(oldweapon, Prop_Send, "m_iClip1");
			}
			else if (StrEqual(weapon, "weapon_pistol"))
			{
				clip = GetEntProp(oldweapon, Prop_Send, "m_iClip1");
				dual = GetEntProp(oldweapon, Prop_Send, "m_hasDualWeapons"); 
				if(dual)clip=0;
			}
			else return;
		}
		
		RemovePlayerItem(client, oldweapon);
		
		new Float:origin[3];
		new Float:ang[3];
		GetClientEyePosition(client,origin);
		GetClientEyeAngles(client, ang);
		GetAngleVectors(ang, ang, NULL_VECTOR,NULL_VECTOR);
		NormalizeVector(ang,ang);
		if(throww)ScaleVector(ang, 500.0);
		else ScaleVector(ang, 300.0);
		
		DispatchSpawn(index);
		TeleportEntity(index, origin, NULL_VECTOR, ang);		
		ActivateEntity(index); 		
		

		if (slot == 0)
		{
			SetEntProp(index, Prop_Send, "m_iExtraPrimaryAmmo", ammo);
			SetEntProp(index, Prop_Send, "m_iClip1", clip);
			SetEntProp(index, Prop_Send, "m_upgradeBitVec", upgrade);
			SetEntProp(index, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", upammo);
		}

		if (slot == 1)
		{
			if (StrEqual(weapon, "weapon_chainsaw"))
			{
				SetEntProp(index, Prop_Send, "m_iClip1", clip);
			}
			if (StrEqual(weapon, "weapon_pistol_magnum"))
			{
				SetEntProp(index, Prop_Send, "m_iClip1", clip);
			}
			if (StrEqual(weapon, "weapon_pistol"))
			{
				SetEntProp(index, Prop_Send, "m_iClip1", clip);
			}
			if(dual)
			{
				SetCommandFlags("give", GetCommandFlags("give") & ~FCVAR_CHEAT);
				FakeClientCommand(client, "give pistol");
				SetCommandFlags("give", GetCommandFlags("give") | FCVAR_CHEAT);
			}
		}
		if(receiver>0)
		{	
			new Handle:h=CreateDataPack();
			WritePackCell(h, client);
			WritePackCell(h, receiver);
			WritePackCell(h, index);
			WritePackCell(h, slot);
			CreateTimer(0.5, AccepteItem, h, TIMER_FLAG_NO_MAPCHANGE);			
		}
	}
	
}
 
public Action:AccepteItem(Handle:timer, Handle:h)
{
	ResetPack(h);
 	new client=ReadPackCell(h);
	new receiver=ReadPackCell(h);
	new weapon=ReadPackCell(h);
	new slot=ReadPackCell(h);
	CloseHandle(h);
	if(receiver>0 && IsClientInGame(receiver) && IsPlayerAlive(receiver))
	{
		if(weapon>0 && IsValidEntity(weapon) && IsValidEdict(weapon))
		{
			new owner=GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
			if(owner < 0)
			{
				
				//PrintToChatAll("slot %d", slot);
				if (GetPlayerWeaponSlot(receiver, slot) > 0)
				{
					if(client>0 && IsClientInGame(client))
					{
						PrintHintText(receiver, "%N give item to you", client);
					}
				}
				else
				{
					EquipPlayerWeapon(receiver, weapon);
					if(client>0 && IsClientInGame(client))
					{
						PrintHintText(client, "you give item to %N", receiver);
						
					}
				}
			}
			else 
			{
				//PrintToChatAll("owner %N", owner);			
			}
		}
	}
}


#define FL_PISTOL_PRIMARY (1<<6) //Is 1 when you have a primary weapon and dual pistols
#define FL_PISTOL (1<<7) //Is 1 when you have dual pistols

//code from Frustian L4D Drop Weapon http://forums.alliedmods.net/showthread.php?t=104114
DropSlot_l4d1(client, slot,  bool:throww=false, receiver=0)
{
	if (GetPlayerWeaponSlot(client, slot) > 0)
	{
		new String:sWeapon[32];
		new ammo;
		new clip;
		new ammoOffset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
		GetEdictClassname(GetPlayerWeaponSlot(client, slot), sWeapon, 32);
		new bool:remove=false;
		if (slot == 0)
		{
			clip = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iClip1")
			if (StrEqual(sWeapon, "weapon_pumpshotgun") || StrEqual(sWeapon, "weapon_autoshotgun"))
			{
				ammo = GetEntData(client, ammoOffset+(6*4));
				SetEntData(client, ammoOffset+(6*4), 0);
			}
			else if (StrEqual(sWeapon, "weapon_smg"))
			{
				ammo = GetEntData(client, ammoOffset+(5*4));
				SetEntData(client, ammoOffset+(5*4), 0);
			}
			else if (StrEqual(sWeapon, "weapon_rifle"))
			{
				ammo = GetEntData(client, ammoOffset+(3*4));
				SetEntData(client, ammoOffset+(3*4), 0);
			}
			else if (StrEqual(sWeapon, "weapon_hunting_rifle"))
			{
				ammo = GetEntData(client, ammoOffset+(2*4));
				SetEntData(client, ammoOffset+(2*4), 0);
			}
			else if (StrContains(sWeapon, "claw") != -1)
			{
				 remove=true;
			}
		}
		if (slot == 1)
		{
			if ((GetEntProp(client, Prop_Send, "m_iAddonBits") & (FL_PISTOL|FL_PISTOL_PRIMARY)) > 0)
			//if ((GetEntProp(client, Prop_Send, "m_iAddonBits") ) > 0)
			{
				clip = GetEntProp(GetPlayerWeaponSlot(client, 1), Prop_Send, "m_iClip1")
				RemovePlayerItem(client, GetPlayerWeaponSlot(client, 1));
				SetCommandFlags("give", GetCommandFlags("give") & ~FCVAR_CHEAT);
				FakeClientCommand(client, "give pistol", sWeapon);
				SetCommandFlags("give", GetCommandFlags("give") | FCVAR_CHEAT);
				if (clip < 15)
					SetEntProp(GetPlayerWeaponSlot(client, 1), Prop_Send, "m_iClip1", 0);
				else
					SetEntProp(GetPlayerWeaponSlot(client, 1), Prop_Send, "m_iClip1", clip-15);
				new index = CreateEntityByName(sWeapon);

 
				new Float:origin[3];

				new Float:ang[3];
				GetClientEyePosition(client,origin);
				GetClientEyeAngles(client, ang);
				GetAngleVectors(ang, ang, NULL_VECTOR,NULL_VECTOR);
				NormalizeVector(ang,ang);
				if(throww)ScaleVector(ang, 500.0);
				else ScaleVector(ang, 300.0);
 				
				DispatchSpawn(index);                                         
				TeleportEntity(index, origin, NULL_VECTOR, ang);
				ActivateEntity(index);
			}
			else
			{
				clip = GetEntProp(GetPlayerWeaponSlot(client, 1), Prop_Send, "m_iClip1")
				RemovePlayerItem(client, GetPlayerWeaponSlot(client, 1)); 
				new index = CreateEntityByName(sWeapon);  
				new Float:origin[3];

				new Float:ang[3];
				GetClientEyePosition(client,origin);
				GetClientEyeAngles(client, ang);
				GetAngleVectors(ang, ang, NULL_VECTOR,NULL_VECTOR);
				NormalizeVector(ang,ang);
				if(throww)ScaleVector(ang, 500.0);
				else ScaleVector(ang, 300.0);
				
				DispatchSpawn(index);
				TeleportEntity(index, origin, NULL_VECTOR, ang);		
				ActivateEntity(index); 

			}
			return;
		}
		new index = CreateEntityByName(sWeapon);
		 
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, slot));

		new Float:origin[3];

		new Float:ang[3];
		GetClientEyePosition(client,origin);
		GetClientEyeAngles(client, ang);
		GetAngleVectors(ang, ang, NULL_VECTOR,NULL_VECTOR);
		NormalizeVector(ang,ang);
		if(throww)ScaleVector(ang, 500.0);
		else ScaleVector(ang, 300.0);
		
		DispatchSpawn(index);
		TeleportEntity(index, origin, NULL_VECTOR, ang);		
		ActivateEntity(index); 
 
		
		if(remove )RemoveEdict(index);
		
		if (slot == 0)
		{
			SetEntProp(index, Prop_Send, "m_iExtraPrimaryAmmo", ammo);
			SetEntProp(index, Prop_Send, "m_iClip1", clip);
		}

		if(receiver>0)
		{	
			new Handle:h=CreateDataPack();
			WritePackCell(h, client);
			WritePackCell(h, receiver);
			WritePackCell(h, index);
			WritePackCell(h, slot);
			CreateTimer(0.5, AccepteItem, h, TIMER_FLAG_NO_MAPCHANGE);			
		}
		
	}
 }