#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define Pai 3.14159265358979323846

#define ShieldMode_None 0
#define ShieldMode_Side 8
#define ShieldMode_Front 2
#define ShieldMode_Back 4

new ZOMBIECLASS_TANK=	8;
#define ArraySize MAXPLAYERS+1

new ShieldMode[ArraySize];
new ShieldWeaopn[ArraySize];
new MeleeEnt[ArraySize];
new MeleeEnt2[ArraySize];
new LastButton[ArraySize];

public Plugin:myinfo =
{
	name = "Shield",
	author = "Pan XiaoHai & raziEiL [disawar1]",
	description = "l4d2",
	version = "1.3",
	url = "<- URL ->"
}
new Handle:l4d_shield_chance_tank;
new Handle:l4d_shield_chance_drop;
new Handle:l4d_shield_password;
new	bool:ismenu[MAXPLAYERS+1];
new afk[MAXPLAYERS+1];
new block[MAXPLAYERS+1];
new iShieldEnt[MAXPLAYERS+1];
new Handle:l4d_shield_damage_totank;
new Handle:l4d_shield_damage_from_ci;
new Handle:l4d_shield_damage_from_si;
new Handle:l4d_shield_damage_from_tankwitch;
new Handle:g_RemoveShield;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	if (!IsDedicatedServer()) 
		return APLRes_Failure;

	decl String:buffer[12];
	GetGameFolderName(buffer, sizeof(buffer));

	if (strcmp(buffer, "left4dead2") == 0)
		return APLRes_Success;
	
	Format(buffer, sizeof(buffer), "Plugin not support \"%s\" game", buffer);
	strcopy(error, err_max, buffer);
	return APLRes_Failure;
}

public OnPluginStart()
{
 	l4d_shield_chance_tank = CreateConVar("l4d_shield_chance_tank", "100",  "chance of shield tank[0.0, 100.0]" );
  	l4d_shield_chance_drop = CreateConVar("l4d_shield_chance_drop", "100", "chance of drop from dead one who have shield[0.0, 100.0]" );

  	l4d_shield_damage_totank = CreateConVar("l4d_shield_damage_totank", "20.0", "damage to tank with shield [0.0, 100.0]" );
  	l4d_shield_password = CreateConVar("l4d_shield_password", "qwqaz1", "!shield + password" );

  	l4d_shield_damage_from_ci = CreateConVar("l4d_shield_damage_from_ci", "0.0", "ci damage to survivor with shield[0.0, 100.0]" );
  	l4d_shield_damage_from_si = CreateConVar("l4d_shield_damage_from_si", "10.0", "si damage to survivor with shield[0.0, 100.0]" );
  	l4d_shield_damage_from_tankwitch = CreateConVar("l4d_shield_damage_from_tankwitch", "20.0", "tank or witch damage to survivor with shield[0.0, 100.0]" );
	g_RemoveShield = CreateConVar("l4d_shield_remove", "1", "Find all shields and remove them from map");

	AutoExecConfig(true, "l4d_shield");

	HookEvent("player_spawn", player_spawn);
	HookEvent("player_use", player_use);

	HookEvent("player_death", player_death);
	HookEvent("player_bot_replace", player_bot_replace );
	HookEvent("bot_player_replace", bot_player_replace );

	HookEvent("round_start", round_end);
	HookEvent("round_end", round_end);
	HookEvent("map_transition", round_end);

	RegConsoleCmd("sm_shield", sm_shield);
	ResetAllState();
}

public Action:sm_shield(client,args)
{
	if(client>0 && GetClientTeam(client)==2 && IsPlayerAlive(client))
	{
		decl String:password[20]="";
		decl String:arg[20];
		GetConVarString(l4d_shield_password, password, sizeof(password));
		GetCmdArg(1, arg, sizeof(arg));
		//PrintToChatAll("arg %s", arg);
		if(StrEqual(arg, password))BuildShieldMenu_2(client ,true);
		else BuildShieldMenu_2(client, false );
 	}
}

public Action:player_use(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new ent = GetEventInt(hEvent, "targetid");

	//PrintToChatAll("%d", ent);

	if(client && !IsFakeClient(client) && IsValidEntity(ent)){
		if (ismenu[client] == true)
			ClientCommand(client, "slot10");

		decl String:item[64];
		GetEntPropString(ent, Prop_Data, "m_ModelName", item, sizeof(item));
		//PrintToChatAll("Valid %s", item);

		if (StrContains(item, "_riotshield.mdl", false) != -1 && !IsClientShield(ent)){

			if (ShieldMode[client] & ShieldMode_Back)
				DropBackShield(client, true)

			CreateShield_Front(client);
			BuildShieldMenu(client);
		}
	}
}

bool:IsClientShield(ent)
{
	for (new i = 1; i <= MaxClients; i++)
		if (iShieldEnt[i] == ent) return true;
	return false;
}

public Action:BuildShieldMenu_2( client , bool:give )
{
	new Handle:menu = CreateMenu(MenuSelector2);

	ismenu[client] = true;

	SetMenuTitle(menu, "Shield Menu");

	if(HaveShieldWeapon(client)>0)
		AddMenuItem(menu, "Build", "Build a shield");
	if(ShieldMode[client] & ShieldMode_Back)
		AddMenuItem(menu, "DropBack", "Drop Shield on back");
	if(ShieldMode[client] & ShieldMode_Front)
		AddMenuItem(menu, "DropFront", "Drop Shield on front");
	if(give)
		AddMenuItem(menu, "Give", "Give me a shield on back");

	CreateTimer(10.0, Timer, client);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 15);
}
public Action:Timer(Handle:timer, any:client)
{
    ismenu[client] = false;
}

public Action:BuildShieldMenu(client)
{
	new Handle:menu = CreateMenu(MenuSelector1);

	SetMenuTitle(menu, "Do you want to build a shield?");
	AddMenuItem(menu, "Front", "Shield on front");
	AddMenuItem(menu, "Back", "Shield on back");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 10);
}
public MenuSelector2(Handle:menu, MenuAction:action, client, param2)
{
	if(client>0 && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client)==2)
	{
		ismenu[client] = false;
		if (action == MenuAction_Select)
		{
			decl String:item[256], String:display[256];
			GetMenuItem(menu, param2, item, sizeof(item), _, display, sizeof(display));
			if (StrEqual(item, "DropBack"))
			{
				DropBackShield(client, true)
			}
			else if(StrEqual(item, "DropFront"))
			{
				ShieldMode[client] &= ~ ShieldMode_Front;
				ShieldWeaopn[client]=0;
			}
			else if(StrEqual(item, "Build"))
			{
				BuildShieldMenu(client);
			}
			else if(StrEqual(item, "Give"))
			{
				CreateShield(client);
			}
		}
		else PrintToChat(client, "You don't have a shield.");
	}
}

DropBackShield(client, bool:Scale=false)
{
	DeleteBackShield(client);
	new Float:pos[3];
	new Float:angle[3];
	GetClientEyePosition(client, pos);
	GetClientAbsAngles(client, angle);

	new ent=CreateEntityByName("weapon_melee");
	DispatchKeyValue( ent, "melee_script_name", "riotshield");
	DispatchSpawn(ent);
	TeleportEntity(ent, pos, angle, NULL_VECTOR);

	if (!Scale)
		SetEntPropFloat(ent , Prop_Send,"m_flModelScale", 1.5);
}

new Float:TimerIndicator[MAXPLAYERS+1];
public MenuSelector1(Handle:menu, MenuAction:action, client, param2)
{
	if(client>0 && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client)==2)
	{
		if (action == MenuAction_Select)
		{
			decl String:item[256], String:display[256];
			GetMenuItem(menu, param2, item, sizeof(item), _, display, sizeof(display));
			if (StrEqual(item, "Front"))
			{
				if(!(ShieldMode[client] & ShieldMode_Back))
					CreateShield_Front(client);
				else PrintToChat(client, "You already have a shield on your back.");
			}
			else if(StrEqual(item, "Back"))
			{
				if(!(ShieldMode[client] & ShieldMode_Back))
				{
					SetupProgressBar(client, 5.0);
					TimerIndicator[client]=GetEngineTime()+5.0;
					CreateTimer(0.1, BuildShieldTimer, client, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
				}
				else PrintToChat(client, "You already have a shield on your back.");
			}
		}
	}
}

public Action:BuildShieldTimer(Handle:timer, any:client)
{
	if(!(IsClientInGame(client) && IsPlayerAlive(client)))
	{
		return Plugin_Stop;
	}
	if(HaveShieldWeapon(client) && MeleeEnt[client]==0)
	{
		if(GetEngineTime()>=TimerIndicator[client])
		{
			CreateShield(client);
			RemoveShieldWeapon(client);
			return Plugin_Stop;
		}
	}
	else
	{

		KillProgressBar(client);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:player_spawn(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(client>0)
	{
		CreateTimer(1.0, CheckShield, client);

		ResetClientState(client);
		if(GetClientTeam(client)==3)SpawnShieldTank(client);
	}
}

public Action:CheckShield(Handle:timer, any:client)
{
	if (IsClientInGame(client) && GetClientTeam(client) == 2 && ShieldMode[client] == ShieldMode_None)
		CreateShield_Front(client);
}

public Action:player_death(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(client>0 && client<=MaxClients)
	{
		if(IsMelee(MeleeEnt[client]) && GetRandomFloat(0.0, 100.0)<GetConVarFloat(l4d_shield_chance_drop))
		{
			new Float:pos[3];
			new Float:angle[3];
			GetClientEyePosition(client, pos);
			GetClientAbsAngles(client, angle);

			new ent=CreateEntityByName("weapon_melee");
			DispatchKeyValue( ent, "melee_script_name", "riotshield");
			DispatchSpawn(ent);
			TeleportEntity(ent, pos, angle, NULL_VECTOR);
			SetEntPropFloat(ent , Prop_Send,"m_flModelScale", 1.5);
		}
		DeleteBackShield(client);
		ResetClientState(client);
	}

}


public player_bot_replace(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
 	new client = GetClientOfUserId(GetEventInt(Spawn_Event, "player"));
	new bot = GetClientOfUserId(GetEventInt(Spawn_Event, "bot"));

	if(client)
	{
		if (ShieldMode[client] == 0) return;

		//PrintToChatAll("%N (%d) idle, buld shield to %N (%d) [MODE %s]", client, client, bot, bot, ShieldMode[client] == 4 ? "Back" : "Front");

		if (ShieldMode[client] == 4){
			afk[client] = 4;
			CreateShield(bot);
		}
		else if (ShieldMode[client] == 2){
			afk[client] = 2;
			CreateShield_Front(bot);
		}

		DeleteBackShield(client);
		ResetClientState(client);
	}
}

public bot_player_replace(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
 	new client = GetClientOfUserId(GetEventInt(Spawn_Event, "player"));
	new bot = GetClientOfUserId(GetEventInt(Spawn_Event, "bot"));


	if(client)
	{
		if (HaveShieldWeapon(client) !=0 && afk[client] == 0){
			CreateShield_Front(client);
			//PrintToChatAll("%N back and have a shield but not equiped", client);
		}

		if (afk[client] == 0) return;

		//PrintToChatAll("%N (%d) back, remove shield from %N (%d) [MODE %s]", client, client, bot, bot, ShieldMode[client] == 4 ? "Back" : "Front");

		DeleteBackShield(bot);
		ResetClientState(bot);

		if (afk[client] == 4)
		{
			CreateShield(client);
			afk[client] = 0;
		}
		else if (afk[client] == 2){

			CreateShield_Front(client);
			afk[client] = 0;
		}
	}
}

DeleteBackShield(client)
{
	if(client<=0)return;
	if(IsMelee(MeleeEnt[client]))
	{
		AcceptEntityInput(MeleeEnt[client], "ClearParent");
		AcceptEntityInput(MeleeEnt[client], "kill");
		//SDKUnhook(MeleeEnt[client], SDKHook_SetTransmit, Hook_SetTransmit);
	}
	if(IsMelee(MeleeEnt2[client]))
	{
		AcceptEntityInput(MeleeEnt2[client], "ClearParent");
		AcceptEntityInput(MeleeEnt2[client], "kill");
		//SDKUnhook(MeleeEnt2[client], SDKHook_SetTransmit, Hook_SetTransmit);
	}
	MeleeEnt[client]=0;
	MeleeEnt2[client]=0;
	ShieldMode[client] =ShieldMode[client] & ~ShieldMode_Back;
	ShieldMode[client] =ShieldMode[client] & ~ShieldMode_Side;
	if(ShieldMode[client]== ShieldMode_None)SDKUnhook(client, SDKHook_OnTakeDamage,  PlayerOnTakeDamage);

}

public Action:OnPlayerRunCmd(client, &buttons, &impuls, Float:vel[3], Float:angles[3], &weapon)
{
    if(ShieldMode[client] & ShieldMode_Front)
	{
		new b=buttons;
		if(ShieldWeaopn[client]==GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon" ))
		{
			//buttons &=~IN_ATTACK;
			//buttons &=~IN_ATTACK2;
		}
		LastButton[client]=b;
	}
}

public Action:PlayerOnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(victim<=0)return Plugin_Continue;
	new mode=ShieldMode[victim];
	if(mode==ShieldMode_None)
	{
		SDKUnhook(victim, SDKHook_OnTakeDamage,  PlayerOnTakeDamage);
		return Plugin_Continue;
	}
	if(mode & ShieldMode_Front)
	{
		new ent=HoldShieldWeapon(victim);
		if(ent<=0)
		{
			mode =mode & ~ShieldMode_Front;
		}
		else ShieldWeaopn[victim]=ent;
	}
	if(mode==ShieldMode_None)return Plugin_Continue;
	decl Float:attackerPos[3];
	new Float:damageFactor=100.0;
	if(attacker>0 && attacker<=MaxClients)
	{
		GetClientAbsOrigin(attacker, attackerPos);
		if(GetEntProp(attacker, Prop_Send, "m_zombieClass")==ZOMBIECLASS_TANK)damageFactor=GetConVarFloat(l4d_shield_damage_from_tankwitch);
		else damageFactor=GetConVarFloat(l4d_shield_damage_from_si);
		//PrintToChatAll("si");
	}
	else
	{
		decl String:name[64];
		GetEdictClassname(attacker, name, 64);
		if(StrEqual(name, "infected"))
		{
			GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", attackerPos);
			damageFactor=GetConVarFloat(l4d_shield_damage_from_ci);
			//PrintToChatAll("infected");
		}
		else if(StrEqual(name, "witch"))
		{
			GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", attackerPos);
			damageFactor=GetConVarFloat(l4d_shield_damage_from_tankwitch);
			//PrintToChatAll("witch");
		}
		else if(StrEqual(name, "tank_rock"))
		{
			GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", attackerPos);
			damageFactor=GetConVarFloat(l4d_shield_damage_from_tankwitch);
			//PrintToChatAll("rock");
		}
		else return Plugin_Continue;
	}
	decl Float:playerPos[3];
	decl Float:playerAngle[3];

	GetClientAbsOrigin(victim, playerPos);
	GetClientEyeAngles(victim, playerAngle);
	playerAngle[0]=0.0;

	if(mode==ShieldMode_Side)
	{
		decl Float:right[3], Float:dir[3];
		SubtractVectors(playerPos, attackerPos, dir);
		NormalizeVector(dir, dir);
		GetAngleVectors(playerAngle, NULL_VECTOR, right, NULL_VECTOR);
		NormalizeVector(right,right);
		new Float:a=GetAngle(dir, right)*180.0/Pai;

		if(a<45.0 || a>135.0 )
		{
			damage=damage*GetConVarFloat(l4d_shield_damage_totank)*0.01;
			if (!block[attacker] && IsClientAndInGame(attacker) && IsClientAndInGame(victim)){
				block[attacker] = 1;
				CreateTimer(2.0, Unlcok, attacker);
				PrintToChat(attacker, "The shield protects from side attack!");
			}
			return Plugin_Handled;
		}

	}
	else
	{
		damageFactor=damageFactor*0.01;

		decl Float:front[3];
		decl Float:dir[3];

		SubtractVectors(playerPos, attackerPos, dir);
		NormalizeVector(dir, dir);
		GetAngleVectors(playerAngle, front, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(front,front);

		new Float:a=GetAngle(dir, front)*180.0/Pai;
		if((mode & ShieldMode_Back) && a<90.0)
		{
			damage =damage*damageFactor;
			//PrintToChatAll("damage %f factor %f  ",damage, damageFactor );
			return Plugin_Handled;
		}
		if((mode & ShieldMode_Front) && a>90.0)
		{
			damage=damage*damageFactor;
			//PrintToChatAll("damage %f factor %f ",damage, damageFactor );

			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

bool:IsClientAndInGame(index)
{
	return (index && index <= MaxClients && IsClientInGame(index));
}

public Action:Unlcok(Handle:timer, any:attacker)
{
	block[attacker] = 0;
}

Float:GetAngle(Float:x1[3], Float:x2[3])
{
	return ArcCosine(GetVectorDotProduct(x1, x2)/(GetVectorLength(x1)*GetVectorLength(x2)));
}

SpawnShieldTank(client)
{
 	if(client>0 && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client)==3 && IsInfected(client, ZOMBIECLASS_TANK))
	{
		new Float:c=GetConVarFloat(l4d_shield_chance_tank);
		if(GetRandomFloat(0.0, 100.0)<c)
		{
			CreateTimer(1.0, TimerCreateShield, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}
CreateShield_Front(client)
{
	new ent =HaveShieldWeapon(client);
	if(ent>0)
	{
		ShieldMode[client] |= ShieldMode_Front;
		ShieldWeaopn[client]=ent;
		SDKUnhook(client, SDKHook_OnTakeDamage,  PlayerOnTakeDamage);
		SDKHook(client, SDKHook_OnTakeDamage,  PlayerOnTakeDamage);
		PrintToChat(client, "You will not be hurt from front if you hold a shield.");
	}
}
CreateShieldTank(client)
{
	DeleteBackShield(client);
	new Float:scale=1.7;
	new Float:ang[3];
	new Float:pos[3];

	new melee=0;
	melee=CreateEntityByName("prop_dynamic_override");
	SetEntityModel(melee, "models/weapons/melee/w_riotshield.mdl");
	DispatchSpawn(melee);
	SetEntPropFloat(melee , Prop_Send,"m_flModelScale", scale);

	SetVector(pos, -5.0, 1.0,  11.0);
	SetVector(ang, 180.0, -60.0,  90.0);

	SetEntityMoveType(melee, MOVETYPE_NONE);
	SetEntProp(melee, Prop_Data, "m_CollisionGroup", 2);
	AttachEnt(client, melee, "relbow", pos, ang);

	new melee2=CreateEntityByName("prop_dynamic_override");
	SetEntityModel(melee2, "models/weapons/melee/w_riotshield.mdl");
	DispatchSpawn(melee2);
	SetEntPropFloat(melee2 , Prop_Send,"m_flModelScale", scale);

	SetVector(pos, -5.0, 1.0,  11.0);
	SetVector(ang, 180.0, -60.0,  90.0);

	SetEntityMoveType(melee2, MOVETYPE_NONE);
	SetEntProp(melee2, Prop_Data, "m_CollisionGroup", 2);
	AttachEnt(client, melee2, "lelbow", pos, ang);

	MeleeEnt[client]=melee;
	MeleeEnt2[client]=melee2;
	ShieldMode[client]=ShieldMode_Side;
	SDKUnhook(client, SDKHook_OnTakeDamage,  PlayerOnTakeDamage);
	SDKHook(client, SDKHook_OnTakeDamage,  PlayerOnTakeDamage);
}
CreateShield(client)
{
	DeleteBackShield(client);
	new Float:scale=1.0;
	new melee=CreateEntityByName("prop_dynamic_override");

	iShieldEnt[client] = melee;

	SetEntityModel(melee, "models/weapons/melee/w_riotshield.mdl");
	DispatchSpawn(melee);
	SetEntPropFloat(melee , Prop_Send,"m_flModelScale",scale);

	new Float:ang[3];
	new Float:pos[3];
	SetVector(pos, 0.0, 14.0,  7.0);
	SetVector(ang, 180.0, 0.0,  90.0);

	SetEntityMoveType(melee, MOVETYPE_NONE);
	SetEntProp(melee, Prop_Data, "m_CollisionGroup", 2);
	AttachEnt(client, melee, "medkit", pos, ang);

	MeleeEnt[client]=melee;
	MeleeEnt2[client]=0;
	ShieldMode[client]|=ShieldMode_Back;

	SDKUnhook(client, SDKHook_OnTakeDamage,  PlayerOnTakeDamage);
	SDKHook(client, SDKHook_OnTakeDamage,  PlayerOnTakeDamage);

	if (ShieldMode[client] & ShieldMode_Front){
		ShieldMode[client] &= ~ ShieldMode_Front;
		ShieldWeaopn[client]=0;
	}

	PrintToChat(client, "Build Shield Successfully, you will not be hurt from your back.");
}
public Action:round_end(Handle:event, const String:Name[], bool:dontBroadcast)
{
	ResetAllState();

	// remove shield from map
	if (GetConVarBool(g_RemoveShield))
		CreateTimer(0.5, FindMeleeShield)
}
public Action:FindMeleeShield(Handle:timer)
{
	decl String:name[64];
	new entity = -1;
	while ((entity = FindEntityByClassname(entity , "weapon_melee")) != INVALID_ENT_REFERENCE){

		GetEntPropString(entity, Prop_Data, "m_ModelName", name, sizeof(name));

		if (StrContains(name, "_riotshield.mdl", false) != -1)
			AcceptEntityInput(entity, "Kill");
	}
	while ((entity = FindEntityByClassname(entity , "weapon_melee_spawn")) != INVALID_ENT_REFERENCE){

		GetEntPropString(entity, Prop_Data, "m_ModelName", name, sizeof(name));

		if (StrContains(name, "_riotshield.mdl", false) != -1)
			AcceptEntityInput(entity, "Kill");
	}
}

ResetAllState()
{
	for(new i=1; i<=MaxClients; i++)
	{
		afk[i] = 0;
		ResetClientState(i);
	}
}

ResetClientState(i)
{
	iShieldEnt[i]=0;
	MeleeEnt[i]=0;
	MeleeEnt2[i]=0;
	ShieldMode[i]=ShieldMode_None;
	ShieldWeaopn[i]=0;
}

bool:IsMelee(ent)
{
	if(ent>0 && IsValidEdict(ent) && IsValidEntity(ent))
	{
		return true;
	}
	else return false;
}

HaveShieldWeapon(client)
{
	new ent=GetPlayerWeaponSlot(client, 1);
	if(ent>0)
	{
		decl String:item[64];
		GetEntPropString(ent, Prop_Data, "m_ModelName", item, sizeof(item));

		if(StrEqual(item, "models/weapons/melee/v_riotshield.mdl"))
			return ent;
	}
	return 0;
}
HoldShieldWeapon(client)
{
	new ent=GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(ent>0)
	{
		decl String:item[64];
		GetEdictClassname(ent,  item, sizeof(item));
		if(StrEqual(item, "weapon_melee"))
		{
			GetEntPropString(ent, Prop_Data, "m_ModelName", item, sizeof(item));
			if(StrContains(item, "shield")>0)
			{
				return ent;
			}
		}
	}
	return 0;
}
RemoveShieldWeapon(client)
{
	new ent=GetPlayerWeaponSlot(client, 1);
	if(ent>0)
	{
		decl String:item[64];
		GetEdictClassname(ent,  item, sizeof(item));
		if(StrEqual(item, "weapon_melee"))
		{
			GetEntPropString(ent, Prop_Data, "m_ModelName", item, sizeof(item));
			if(StrContains(item, "shield")>0)
			{
				RemovePlayerItem(client, ent);
				AcceptEntityInput(ent, "kill");
			}
		}
	}
}
AttachEnt(owner, ent, String:positon[]="medkit", Float:pos[3]=NULL_VECTOR,Float:ang[3]=NULL_VECTOR)
{
	decl String:tname[60];
	Format(tname, sizeof(tname), "target%d", owner);
	DispatchKeyValue(owner, "targetname", tname);
	DispatchKeyValue(ent, "parentname", tname);

	SetVariantString(tname);
	AcceptEntityInput(ent, "SetParent",ent, ent, 0);
	if(strlen(positon)!=0)
	{
		SetVariantString(positon);
		AcceptEntityInput(ent, "SetParentAttachment");
	}
	TeleportEntity(ent, pos, ang, NULL_VECTOR);
}

public Action:TimerCreateShield(Handle:timer, any:client)
{
	if(client>0 && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client)==3 && IsInfected(client, ZOMBIECLASS_TANK))
	{
		CreateShieldTank(client);
	}
}

SetVector(Float:target[3], Float:x, Float:y, Float:z)
{
	target[0]=x;
	target[1]=y;
	target[2]=z;
}
IsInfected(client, type)
{
	new class = GetEntProp(client, Prop_Send, "m_zombieClass");
	if(type==class)return true;
	else return false;
}
public OnMapStart()
{
	AddFileToDownloadsTable("scripts/melee/riotshield.txt");

	PrecacheModel("models/weapons/melee/v_riotshield.mdl", true );
	PrecacheModel("models/weapons/melee/w_riotshield.mdl",true);

	PrecacheGeneric( "scripts/melee/riotshield.txt", true );
}

stock SetupProgressBar(client, Float:time)
{
	//KillProgressBar(client);
	//SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", time);
	//SetEntPropEnt(client, Prop_Send, "m_reviveOwner", client);
	//SetEntPropEnt(client, Prop_Send, "m_reviveTarget", client);

}

stock KillProgressBar(client)
{
	//SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);
	//SetEntityMoveType(client, MOVETYPE_WALK);
	//SetEntPropEnt(client, Prop_Send, "m_reviveTarget", 0);
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
	//SetEntPropEnt(client, Prop_Send, "m_reviveOwner", 0);
}