#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>
#define PLUGIN_VERSION "0.0.1"

//#define MAX_PLAYERS 34
#define SCOUT 1
#define SNIPER 2
#define SOLDIER 3
#define DEMOMAN 4
#define MEDIC 5
#define HEAVY 6
#define PYRO 7
#define SPY 8
#define ENGINEER 9
#define CLS_MAX 10

#define DMG_ACID			(1 << 20)

public Plugin:myinfo = {
	name = "TF2 Armor",
	author = "CrancK",
	description = "Armor",
	version = PLUGIN_VERSION,
	url = ""
};

new maxHP[CLS_MAX] = {
	0, 
	185, 185, 300,
	260, 225, 450,
	260, 185, 185
};

new String:Classes[3][9][16];
new classAmounts[3];
new armorHP[MAXPLAYERS];
new bool:buffed[MAXPLAYERS];
new Float:PlayersInRange[MAXPLAYERS];
new disp[MAXPLAYERS];
new Float:dispLoc[MAXPLAYERS][3];
new bool:dispTime = true;

new Handle:cvArmorEnabled;
new Handle:cvArmorStart;
new Handle:cvArmorClass[3];
new Handle:cvArmorReduction[3];
new Handle:cvArmorMax[3];
new Handle:cvArmorAmounts[3];
new Handle:timerInterval;
new Handle:HudMessage;
new Handle:gTimer;
new Handle:cvArmorDispEnabled;
new Handle:cvArmorDispRad;
new Handle:cvArmorDispRate;
new Handle:cvArmorDispDelay;
new Handle:cvArmorType;

public OnPluginStart()
{
	HookEvent("player_hurt", EventPlayerHurt);
	HookEvent("player_spawn",PlayerSpawn);
	HookEvent("player_builtobject", ObjectBuilt);
	CreateConVar("sm_armor_version", PLUGIN_VERSION, "armor Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvArmorEnabled = CreateConVar("sm_armor_enabled", "1", "...");
	cvArmorStart = CreateConVar("sm_armor_start_amount", "2", "...");
	cvArmorMax[0] = CreateConVar("sm_armor_light_max", "100", "...");
	cvArmorMax[1] = CreateConVar("sm_armor_medium_max", "150", "...");
	cvArmorMax[2] = CreateConVar("sm_armor_heavy_max", "200", "...");
	cvArmorClass[2] = CreateConVar("sm_armor_heavy_classes", "heavy,soldier", "describes which classes have heavy armor");
	cvArmorClass[1] = CreateConVar("sm_armor_medium_classes", "pyro,demoman,medic,engineer", "describes which classes have medium armor");
	cvArmorClass[0] = CreateConVar("sm_armor_light_classes", "scout,spy,sniper", "describes which classes have light armor");
	cvArmorReduction[0] = CreateConVar("sm_armor_light_reduction", "0.4", "...");
	cvArmorReduction[1] = CreateConVar("sm_armor_medium_reduction", "0.6", "...");
	cvArmorReduction[2] = CreateConVar("sm_armor_heavy_reduction", "0.8", "...");
	cvArmorAmounts[0] = CreateConVar("sm_armor_pickup_small", "11.25", "...");
	cvArmorAmounts[1] = CreateConVar("sm_armor_pickup_medium", "25.0", "...");
	cvArmorAmounts[2] = CreateConVar("sm_armor_pickup_large", "50.0", "...");
	cvArmorType = CreateConVar("sm_armor_mode", "1", "mode 1 = die if hp goes under 1, mode 2 = if hp goes under 1 and player still has enough armor, the rest of the damage will be dealt to the armor");
	cvArmorDispEnabled = CreateConVar("sm_armor_dispenser_enabled", "1", "...");
	cvArmorDispRad = CreateConVar("sm_armor_dispenser_radius", "256.0", "...");
	cvArmorDispRate = CreateConVar("sm_armor_dispenser_rate", "5.0", "...");
	cvArmorDispDelay = CreateConVar("sm_armor_dispenser_delay", "5.0", "...");
	timerInterval = CreateConVar("sm_armor_info_interval", "5", "How often health timer is updated (in tenths of a second).");
	HookConVarChange(timerInterval, ConVarChange_Interval);
	HudMessage = CreateHudSynchronizer();
	
	HookEntityOutput("item_ammopack_full", "OnPlayerTouch", EntityOutput_OnPlayerTouch);
	HookEntityOutput("item_ammopack_medium", "OnPlayerTouch", EntityOutput_OnPlayerTouch);
	HookEntityOutput("item_ammopack_small", "OnPlayerTouch", EntityOutput_OnPlayerTouch);
	for(new i=0;i<MAXPLAYERS;i++)
	{
		disp[i] = -1;
		buffed[i] = false;
		for(new j=0;j<3;j++)
		{
			dispLoc[i][j] = 0.0;
		}
	}
}

public OnMapStart()
{
	gTimer = CreateTimer(GetConVarInt(timerInterval) * 0.1, Timer_ShowInfo, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public OnConfigsExecuted()
{
	//GetConVarString(cvArmorHClass, HeavyClasses, sizeof(HeavyClasses));
	//GetConVarString(cvArmorMClass, MediumClasses, sizeof(MediumClasses));
	//GetConVarString(cvArmorLClass, LightClasses, sizeof(LightClasses));
	if(GetConVarInt(cvArmorEnabled)==1)
	{
		for(new i=0;i<3;i++)
		{
			SetClassStrings(cvArmorClass[i], i);
		}
	}
}

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnGameFrame()
{
	if(GetConVarInt(cvArmorEnabled)==1 && dispTime && GetConVarInt(cvArmorDispEnabled)==1)
	{
		for(new i=0;i<MAXPLAYERS;i++)
		{
			if(disp[i] != -1 && dispLoc[i][0] != 0.0 && dispLoc[i][1] != 0.0 && dispLoc[i][2] != 0.0)
			{
				//PrintToChatAll("dispenser found in dispCycle");
				//new oteam;
				//if (GetClientTeam(i)==3) {oteam=2;} else {oteam=3;}
				FindPlayersInRange(dispLoc[i], GetConVarFloat(cvArmorDispRad), GetClientTeam(i), i, false, disp[i]);
				new maxplayers = GetMaxClients();
				new Float:amount = GetConVarFloat(cvArmorDispRate);
				for (new j=1;j<=maxplayers;j++)
				{
					if(PlayersInRange[j]>0.0)
					{
						//PrintToChat(j, "you're getting armor from %i's dispenser", i);
						new armorType = GetArmorType(j);
						if(armorType!=-1)
						{
							new max = GetConVarInt(cvArmorMax[armorType]);
							new tamount = RoundFloat(float(max)*(amount/100.0));
							if(armorHP[j] + tamount >= max)
							{
								armorHP[j] = max;
							}
							else
							{
								armorHP[j] += tamount;
							}
						}
					}
				}
			}
		}
		CreateTimer(GetConVarFloat(cvArmorDispDelay), Timer_Disp);
		dispTime = false;
	}
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(cvArmorEnabled)==1)
	{
		new client_id = GetEventInt(event, "userid");
		new client = GetClientOfUserId(client_id);
		if(client > 0 && client < MAXPLAYERS && !IsClientObserver(client) && !IsFakeClient(client))
		{
			new armorType = GetArmorType(client);
			SetArmorHP(client, armorType, 0, true);
		}
	}
	return Plugin_Continue;
}

public Action:ObjectBuilt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(cvArmorEnabled)==1)
	{
		new client_id = GetEventInt(event, "userid");
		new client = GetClientOfUserId(client_id);
		new building = GetEventInt(event, "object");
		new buildIdx = GetEventInt(event, "index");
		//PrintToChatAll("client: %i, building: %i, buildIdx: %i", client, building, buildIdx);
		if(building == 0)
		{
			disp[client] = buildIdx;
			GetEntPropVector(buildIdx, Prop_Send, "m_vecOrigin", dispLoc[client]);
		}
	}
}

public OnEntityDestroyed(ent)
{
	if(GetConVarInt(cvArmorEnabled)==1)
	{
		if(IsValidEntity(ent))
		{
			new String:classname[64];
			GetEdictClassname(ent, classname, sizeof(classname)); 
			if(strcmp(classname, "obj_dispenser")==0)
			{
				new client;
				for(new i=0;i<MAXPLAYERS;i++)
				{
					if(ent == disp[i])
					{
						client=i;
						break;
					}
				}
				disp[client] = -1;
				dispLoc[client][0] = 0.0;
				dispLoc[client][1] = 0.0;
				dispLoc[client][2] = 0.0;
			}
		}
	}
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(cvArmorEnabled)==1)
	{
		new client_id = GetEventInt(event, "userid");
		new client = GetClientOfUserId(client_id);
		armorHP[client] = 0;
	}
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(GetConVarInt(cvArmorEnabled)==1 && armorHP[victim]>0 && damagetype != DMG_ACID && !buffed[victim])
	{
		new curHealth = GetClientHealth(victim);
		new maxArmorUsed;
		new iDamage = RoundFloat(damage);
		new tempHP;
		new armorType = GetArmorType(victim);
		maxArmorUsed = RoundFloat(float(curHealth) * GetConVarFloat(cvArmorReduction[armorType]));
		if(GetConVarInt(cvArmorType)==1)
		{
			if(armorHP[victim] > maxArmorUsed)
			{
				tempHP = maxArmorUsed;
			}
			else
			{
				tempHP = armorHP[victim];
			}
			if(iDamage>curHealth && tempHP+curHealth>iDamage)
			{
				curHealth+=500;
				PrintToServer("%i hp = %i and type = 1", victim, curHealth);
				buffed[victim] = true;
				SetEntityHealth(victim, curHealth);
			}
		}
		else if(GetConVarInt(cvArmorType)==2)
		{
			tempHP = armorHP[victim];
			if(iDamage>curHealth && tempHP+curHealth>iDamage)
			{
				curHealth+=500;
				PrintToServer("%i hp = %i and type = 2", victim, curHealth);
				buffed[victim] = true;
				SetEntityHealth(victim, curHealth);
			}
		}
	}
}

public Action:EventPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(cvArmorEnabled)==1)
	{
		new victim_id = GetEventInt(event, "userid");
		new attacker_id = GetEventInt(event, "attacker");
		new victim = GetClientOfUserId(victim_id);
		new attacker = GetClientOfUserId(attacker_id);
		new health = GetEventInt(event, "health");
		new damage = GetEventInt(event, "damageamount");
		new bool:critical = GetEventBool(event, "crit");
		new weaponid = GetEventInt(event, "weaponid");
		if(health>0 && armorHP[victim]>0 && !critical) //17=sniper, 22=rl, 23 = pipes 24=stickies
		{
			//PrintToChat(victim, "hp: %i, attacker: %i, damage: %i, weaponid: %i, armor: %i", health, attacker, damage, weaponid, armorHP[victim]);
			new armorType = GetArmorType(victim);
			if(armorType!=-1)
			{
				DamageArmor(victim, armorType, damage, health);
				//PrintToChat(victim, "hp: %i, attacker: %i, damage: %i, weaponid: %i, armor: %i", health, attacker, damage, weaponid, armorHP[victim]);
			}
		}
		if(buffed[victim])
		{
			new curHP = GetClientHealth(victim);
			new class = int:TF2_GetPlayerClass(victim);
			if(curHP > 500+maxHP[class])
			{
				curHP = 0;
			}
			else
			{
				curHP -= 500;
			}
			buffed[victim] = false;
			if(curHP > 0)
			{
				SetEntityHealth(victim, curHP);
			}
			else
			{
				curHP = 0;
				SetEntityHealth(victim, curHP);
			}
		}
	}
	return Plugin_Continue;
}

public EntityOutput_OnPlayerTouch(const String:output[], caller, activator, Float:delay)
{
	if(GetConVarInt(cvArmorEnabled) == 1)
	{
		if(IsValidEntity(caller))
		{	
			
			new String:modelname[128];
			GetEntPropString(caller, Prop_Data, "m_ModelName", modelname, 128);
			if (StrEqual(modelname, "models/items/ammopack_large.mdl"))
			{
				new Float:pos[3];
				GetEntPropVector(caller, Prop_Send, "m_vecOrigin", pos);
				FindPlayersInRange(pos, 96.0, 0, -1, false, -1);
				new j;
				new maxplayers = GetMaxClients();
				new Float:amount = GetConVarFloat(cvArmorAmounts[2]);
				for (j=1;j<=maxplayers;j++)
				{
					if(PlayersInRange[j]>0.0)
					{
						new armorType = GetArmorType(j);
						if(armorType!=-1)
						{
							new max = GetConVarInt(cvArmorMax[armorType]);
							new tamount = RoundFloat(float(max)*(amount/100.0));
							if(armorHP[j] + tamount >= max)
							{
								armorHP[j] = max;
							}
							else
							{
								armorHP[j] += tamount;
							}
						}
					}
				}
			}
			else if(StrEqual(modelname, "models/items/ammopack_medium.mdl"))
			{
				new Float:pos[3];
				GetEntPropVector(caller, Prop_Send, "m_vecOrigin", pos);
				FindPlayersInRange(pos, 96.0, 0, -1, false, -1);
				new j;
				new maxplayers = GetMaxClients();
				new Float:amount = GetConVarFloat(cvArmorAmounts[1]);
				for (j=1;j<=maxplayers;j++)
				{
					if(PlayersInRange[j]>0.0)
					{
						new armorType = GetArmorType(j);
						if(armorType!=-1)
						{
							new max = GetConVarInt(cvArmorMax[armorType]);
							new tamount = RoundFloat(float(max)*(amount/100.0));
							if(armorHP[j] + tamount >= max)
							{
								armorHP[j] = max;
							}
							else
							{
								armorHP[j] += tamount;
							}
						}
					}
				}
			}
			else if(StrEqual(modelname, "models/items/ammopack_small.mdl"))
			{
				new Float:pos[3];
				GetEntPropVector(caller, Prop_Send, "m_vecOrigin", pos);
				FindPlayersInRange(pos, 96.0, 0, -1, false, -1);
				new j;
				new maxplayers = GetMaxClients();
				new Float:amount = GetConVarFloat(cvArmorAmounts[0]);
				for (j=1;j<=maxplayers;j++)
				{
					if(PlayersInRange[j]>0.0)
					{
						new armorType = GetArmorType(j);
						if(armorType!=-1)
						{
							new max = GetConVarInt(cvArmorMax[armorType]);
							new tamount = RoundFloat(float(max)*(amount/100.0));
							if(armorHP[j] + tamount >= max)
							{
								armorHP[j] = max;
							}
							else
							{
								armorHP[j] += tamount;
							}
						}
					}
				}
			}
		}
	}
}

/*public OnEntityCreated(ent, const String:classname[])
{
	if(GetConVarInt(cvArmorEnabled)==1 && strcmp(classname, "obj_dispenser") == 0)
	{
		
		new client = GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity");
		new Float:center[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", center);
		PrintToChatAll("dispenser created by %i on: %i %i %i", client, RoundFloat(center[0]),RoundFloat(center[1]),RoundFloat(center[2]));
		disp[client] = ent;
		dispLoc[client][0] = center[0];
		dispLoc[client][1] = center[1];
		dispLoc[client][2] = center[2];
	}
}*/

SetClassStrings(Handle:convar, type)
{
	if(GetConVarInt(cvArmorEnabled)==1)
	{
		new String:sKeywords[64];
		GetConVarString(convar, sKeywords, 64);
		classAmounts[type] = ExplodeString(sKeywords, ",", Classes[type], 9, sizeof(Classes[][]));
	}
}

DamageArmor(client, type, tdamage, curHP)
{
	if(GetConVarInt(cvArmorEnabled)==1)
	{
		new Float:dynDam = float(tdamage);
		new Float:dynArm = float(armorHP[client]);
		new Float:red = dynDam * GetConVarFloat(cvArmorReduction[type]);
		if(red < dynArm) 
		{ 
			dynArm -= red;
			//dynDam -= red; 
			SetArmorHP(client, type, RoundFloat(red));
			if(GetConVarInt(cvArmorType)==2 && buffed[client])
			{
				new rest = 500-(curHP+RoundFloat(red));
				if(rest >= 0 && armorHP[client] > 0 && (rest-armorHP[client] < 0) && (armorHP[client]-(rest+1) >= 0) )
				{
					armorHP[client] -= rest+1;
					curHP += rest+1;
				}
			}
		}
		else
		{
			new Float:temp;
			temp = red-dynArm;
			red -= temp;
			armorHP[client] = 0;
		}
		
		SetEntityHealth(client, curHP+RoundFloat(red));
	}
}

GetArmorType(client)
{
	if(GetConVarInt(cvArmorEnabled)==1)
	{
		new class = int:TF2_GetPlayerClass(client);
		new String:classString[16];
		new result = -1;
		switch(class)
		{
			case 1:	{ Format(classString, sizeof(classString), "scout"); }
			case 2: { Format(classString, sizeof(classString), "sniper"); }
			case 3: { Format(classString, sizeof(classString), "soldier"); }
			case 4: { Format(classString, sizeof(classString), "demoman"); }
			case 5: { Format(classString, sizeof(classString), "medic"); }
			case 6: { Format(classString, sizeof(classString), "heavy"); }
			case 7: { Format(classString, sizeof(classString), "pyro"); }
			case 8: { Format(classString, sizeof(classString), "spy"); }
			case 9: { Format(classString, sizeof(classString), "engineer"); }
		}
		for(new j=0;j<3;j++)
		{
			for(new i=0;i<classAmounts[j];i++)
			{
				if(strcmp(classString, Classes[j][i]) == 0)
				{
					result = j;
				}
			}
		}
		return result;
	}
	return -1;
}

SetArmorHP(client, type, damage, bool:start=false)
{
	if(GetConVarInt(cvArmorEnabled)==1)
	{
		if(start && GetConVarInt(cvArmorStart) > 0)
		{
			switch(GetConVarInt(cvArmorStart))
			{
				case 1:
				{
					armorHP[client] = GetConVarInt(cvArmorMax[type]);
				}
				case 2:
				{
					armorHP[client] = GetConVarInt(cvArmorMax[type])*3/4;
				}
				case 3:
				{	
					armorHP[client] = GetConVarInt(cvArmorMax[type])/2;
				}
				case 4:
				{
					armorHP[client] = GetConVarInt(cvArmorMax[type])/4;
				}
			}
		}
		else if(!start && damage > 1)
		{
			armorHP[client] -= damage;
		}
	}
}

public Action:Timer_Disp(Handle:timer) 
{
	dispTime = true;
}

public Action:Timer_ShowInfo(Handle:timer) 
{	
	if(GetConVarInt(cvArmorEnabled)==1)
	{
		for (new i = 1; i <= GetMaxClients(); i++) 
		{
			if (IsClientInGame(i) && !IsFakeClient(i)) 
			{
				SetHudTextParams(0.04, 0.27, 1.0, 255, 50, 50, 255);
				ShowSyncHudText(i, HudMessage, "Armor: %i", armorHP[i]);
			}
		}
	}
	return Plugin_Continue;
}

public ConVarChange_Interval(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
    if (gTimer != INVALID_HANDLE) 
	{
        KillTimer(gTimer);
    }
    
    gTimer          = CreateTimer(GetConVarInt(timerInterval) * 0.1, Timer_ShowInfo, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

FindPlayersInRange(Float:location[3], Float:radius, team, self, bool:trace, donthit)
{
	new Float:rsquare = radius*radius;
	new Float:orig[3];
	new Float:distance;
	new Handle:tr;
	new j;
	new maxplayers = GetMaxClients();
	//if(GetConVarInt(ff)==1){ team = 0; }
	for (j=1;j<=maxplayers;j++)
	{
		PlayersInRange[j] = 0.0;
		if (IsClientInGame(j))
		{
			if (IsPlayerAlive(j))
			{
				if ( (team>1 && GetClientTeam(j)==team) || team==0 || j==self)
				{
					GetClientAbsOrigin(j, orig);
					orig[0]-=location[0];
					orig[1]-=location[1];
					orig[2]-=location[2];
					orig[0]*=orig[0];
					orig[1]*=orig[1];
					orig[2]*=orig[2];
					distance = orig[0]+orig[1]+orig[2];
					if (distance < rsquare)
					{
						if (trace)
						{
							GetClientEyePosition(j, orig);
							tr = TR_TraceRayFilterEx(location, orig, MASK_SOLID, RayType_EndPoint, TraceRayDontHitSelfOrPlayers, donthit);
							if (tr!=INVALID_HANDLE)
							{
								if (TR_GetFraction(tr)>0.98)
								{
									PlayersInRange[j] = SquareRoot(distance)/radius;
								}
								CloseHandle(tr);
							}
							
						}
						else
						{
							PlayersInRange[j] = SquareRoot(distance)/radius;
						}
					}
				}
			}
		}
	}
}

public bool:TraceRayDontHitSelfOrPlayers(entity, mask, any:startent)
{
	if(entity == startent)
	{
		return false;
	}
	
	if (entity <= GetMaxClients())
	{
		return false;
	}
	
	return true; 
}
