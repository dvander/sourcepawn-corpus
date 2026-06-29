/**
 * File: MedicInfect.sp
 * Description: Medic Infection for TF2
 * Author(s): Twilight Suzuka
 */

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

new ClientInfected[MAXPLAYERS + 1];
new bool:ClientFriendlyInfected[MAXPLAYERS + 1];

new bool:NativeControl = false;
new bool:NativeMedicArmed[MAXPLAYERS + 1] = { false, ...};
new NativeAmount[MAXPLAYERS + 1];

public Plugin:myinfo = 
{
	name = "Medic Infection",
	author = "Twilight Suzuka",
	description = "Allows medics to infect again",
	version = "Beta:1",
	url = "http://www.sourcemod.net/"
};

new Handle:Cvar_DmgAmount = INVALID_HANDLE;
new Handle:Cvar_DmgTime = INVALID_HANDLE;
new Handle:Cvar_DmgDistance = INVALID_HANDLE;

new Handle:Cvar_SpreadAll = INVALID_HANDLE;
new Handle:Cvar_SpreadSameTeam = INVALID_HANDLE;
new Handle:Cvar_SpreadOpposingTeam = INVALID_HANDLE;
new Handle:Cvar_SpreadDistance = INVALID_HANDLE

new Handle:Cvar_InfectSameTeam = INVALID_HANDLE;
new Handle:Cvar_InfectOpposingTeam = INVALID_HANDLE;
new Handle:Cvar_InfectInfector = INVALID_HANDLE;
new Handle:Cvar_InfectMedics = INVALID_HANDLE;
new Handle:Cvar_InfectDelay = INVALID_HANDLE;

new Handle:Cvar_InfectMedi = INVALID_HANDLE;
new Handle:Cvar_InfectSyringe = INVALID_HANDLE;

new Handle:CvarEnable = INVALID_HANDLE;
new Handle:CvarRed = INVALID_HANDLE;
new Handle:CvarBlue = INVALID_HANDLE;
new Handle:CvarGreen = INVALID_HANDLE;
new Handle:CvarTrans = INVALID_HANDLE;

new Handle:InfectionTimer = INVALID_HANDLE;

public bool:AskPluginLoad(Handle:myself,bool:late,String:error[],err_max)
{
	// Register Natives
	CreateNative("ControlMedicInfect",Native_ControlMedicInfect);
	CreateNative("SetMedicInfect",Native_SetMedicInfect);
	CreateNative("MedicInfect",Native_MedicInfect);
	CreateNative("HealInfect",Native_HealInfect);
	RegPluginLibrary("MedicInfect");
	return true;
}

public OnPluginStart()
{
	CvarEnable = CreateConVar("medic_infect_on", "1", "1 turns the plugin on 0 is off", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	CvarRed = CreateConVar("medic_infect_red", "0", "Amount of Red", FCVAR_NOTIFY);
	CvarGreen = CreateConVar("medic_infect_green", "255", "Amount of Green", FCVAR_NOTIFY);
	CvarBlue = CreateConVar("medic_infect_blue", "100", "Amount of Blue", FCVAR_NOTIFY);
	CvarTrans = CreateConVar("medic_infect_alpha", "255", "Amount of Transperency", FCVAR_NOTIFY);
	
	Cvar_DmgAmount = CreateConVar("sv_medic_infect_dmg_amount", "10", "Amount of damage medic infect does each heartbeat",FCVAR_PLUGIN);
	Cvar_DmgTime = CreateConVar("sv_medic_infect_dmg_time", "12", "Amount of time between infection heartbeats",FCVAR_PLUGIN);
	Cvar_DmgDistance = CreateConVar("sv_medic_infect_dmg_distance", "0.0", "Distance infection can spread",FCVAR_PLUGIN);

	Cvar_SpreadAll = CreateConVar("sv_medic_infect_spread_all", "0", "Allow medical infections to run rampant",FCVAR_PLUGIN);
	Cvar_SpreadSameTeam = CreateConVar("sv_medic_infect_spread_friendly", "1", "Allow medical infections to run rampant inside a team",FCVAR_PLUGIN);
	Cvar_SpreadOpposingTeam = CreateConVar("sv_medic_infect_spread_enemy", "0", "Allow medical infections to run rampant between teams",FCVAR_PLUGIN);		
	Cvar_SpreadDistance = CreateConVar("sv_medic_infect_spread_distance", "2000.0", "Distance infection can spread",FCVAR_PLUGIN);
	
	Cvar_InfectSameTeam = CreateConVar("sv_medic_infect_friendly", "1", "Allow medics to infect friends",FCVAR_PLUGIN);
	Cvar_InfectOpposingTeam = CreateConVar("sv_medic_infect_enemy", "1", "Allow medics to infect enemies",FCVAR_PLUGIN);
	
	Cvar_InfectInfector = CreateConVar("sv_medic_infect_infector", "0", "Allow reinfections",FCVAR_PLUGIN);
	Cvar_InfectMedics = CreateConVar("sv_medic_infect_medics", "0", "Allow medics to be infected",FCVAR_PLUGIN);
	Cvar_InfectDelay = CreateConVar("sv_medic_infect_delay", "1.0", "Delay between infections",FCVAR_PLUGIN);
	
	Cvar_InfectMedi = CreateConVar("sv_medic_infect_medi", "1", "Infect using medi gun",FCVAR_PLUGIN);
	Cvar_InfectSyringe = CreateConVar("sv_medic_infect_syringe", "1", "Infect using syringe gun",FCVAR_PLUGIN);
	
	HookEventEx("player_death", MedicModify, EventHookMode_Pre);
}

public OnConfigsExecuted()
{
	InfectionTimer = CreateTimer(GetConVarFloat(Cvar_DmgTime), HandleInfection,_,TIMER_REPEAT);
	HookConVarChange(Cvar_DmgTime, HandleInfectionChange);
}

public OnMapEnd()
{
	new maxplayers = GetMaxClients();
	for(new a = 1; a <= maxplayers; a++)
	{
		ClientInfected[a] = 0;
		ClientFriendlyInfected[a] = false;
	}
}

public HandleInfectionChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	CloseHandle(InfectionTimer);
	InfectionTimer = CreateTimer(StringToFloat(newValue), HandleInfection,_,TIMER_REPEAT);
}

public Action:HandleInfection(Handle:timer)
{
	if(!GetConVarInt(CvarEnable) && !NativeControl) return;
	
	new maxplayers = GetMaxClients();
	for(new a = 1; a <= maxplayers; a++)
	{
		if(!IsClientInGame(a) || !IsPlayerAlive(a) || ClientInfected[a] == 0) continue;
	
		new amt = NativeAmount[ClientInfected[a]];
		new hp = GetClientHealth(a);
		hp -= (amt > 0) ? amt : GetConVarInt(Cvar_DmgAmount);
		
		if(hp < 0)
			ForcePlayerSuicide(a);
		else
		{
			SetEntityHealth(a,hp);
			//SetEntProp(a, Prop_Send, "m_iHealth", hp, 1);
			//SetEntProp(a, Prop_Data, "m_iHealth", hp, 1);
		}
	}
}

public Action:MedicModify(Handle:event, const String:name[], bool:dontBroadcast)
{
	new id = GetClientOfUserId(GetEventInt(event,"userid"));
	if(!ClientInfected[id]) return Plugin_Continue;
	
	new infecter = ClientInfected[id];
	
	ClientInfected[id] = 0;
	ClientFriendlyInfected[id] = false;

	SetEntityRenderColor(id)
	SetEntityRenderMode(id, RENDER_NORMAL)

	new attacker = GetClientOfUserId(GetEventInt(event,"attacker"));
	if (attacker == id)
	{
		SetEventInt(event,"attacker",GetClientUserId(infecter));
		if(TF2_GetPlayerClass(infecter) != TFClass_Medic)
		{
			if(ClientInfected[infecter])
				SetEventInt(event,"assister",GetClientUserId(ClientInfected[infecter]));
		}
		//SetEventString(event,"weapon","infection");
		//SetEventInt(event,"customkill",1); // This makes the kill a Headshot!
	}
	else if (attacker != infecter)
	{
		if (GetEventInt(event,"assister") <= 0)
			SetEventInt(event,"assister",GetClientUserId(infecter));
	}

	return Plugin_Continue;
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	ClientInfected[client] = 0;
	ClientFriendlyInfected[client] = false;
	return true;
}

public OnGameFrame()
{
	if(!GetConVarInt(CvarEnable) && !NativeControl) return;

	if(GetConVarInt(Cvar_InfectMedi)) CheckMedics();
	RunInfection();
}

new Float:MedicDelay[MAXPLAYERS + 1];

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if(GetConVarInt(CvarEnable) && !NativeControl) return Plugin_Continue;
	if (NativeControl && !NativeMedicArmed[client]) return Plugin_Continue;

	if(
		GetConVarInt(Cvar_InfectSyringe) 
		|| (TF2_GetPlayerClass(client) != TFClass_Medic) 
		|| (MedicDelay[client] > GetGameTime())
		) 
		return Plugin_Continue;

	if(StrEqual(weaponname, "tf_weapon_syringegun_medic") )
	{
		new target = GetClientAimTarget(client);
		if(target > 0) 
		{
			MedicInfect(client,target,1)
			MedicDelay[client] = GetGameTime() + GetConVarFloat(Cvar_InfectDelay);
		}
	}

	return Plugin_Continue;
}

public CheckMedics()
{
	decl String:classname[32];
	new maxplayers = GetMaxClients();

	for(new i = 1; i <= maxplayers; i++)
	{
		if (NativeControl && !NativeMedicArmed[i])
			 continue;

		if( !IsClientInGame(i) 
			|| !IsPlayerAlive(i) 
			|| (TF2_GetPlayerClass(i) != TFClass_Medic) 
			|| (MedicDelay[i] > GetGameTime()) 
			) 
			continue;

		new weaponent = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");

		if(GetEdictClassname(weaponent, classname , sizeof(classname)) )
		{
			if(StrEqual(classname, "tf_weapon_medigun") )
			{
				new buttons = GetClientButtons(i);
				if(buttons & IN_ATTACK)
				{
					new target = GetClientAimTarget(i);
					if(target > 0) 
					{
						MedicInfect(i,target,0)
						MedicDelay[i] = GetGameTime() + GetConVarFloat(Cvar_InfectDelay);
					}
				}
				if(buttons & IN_RELOAD)
				{
					new target = GetClientAimTarget(i);
					if(target > 0) 
					{
						MedicInfect(i,target,1)
						MedicDelay[i] = GetGameTime() + GetConVarFloat(Cvar_InfectDelay);
					}
				}
			}
		}
	}
}

MedicInfect(a,b,allow)
{
	// Rukia: are the teams identical?
	new t_same = GetClientTeam(a) == GetClientTeam(b);
	if( t_same )
	{
		if( allow  )
		{
			// Rukia: Don't infect same team if not allowed
			if(  !GetConVarInt(Cvar_InfectSameTeam) )
				return;
			// Rukia: Don't reinfect!
			else if(ClientInfected[b])
				return;
		}
	}
	else
	{
		// Rukia: Don't infect opposing team if not allowed
		if(!GetConVarInt(Cvar_InfectOpposingTeam) )
			return;
		// Rukia: Don't reinfect!
		else if(ClientInfected[b])
			return;
	}

	decl Float:ori1[3], Float:ori2[3];
	GetClientAbsOrigin(a, ori1);
	GetClientAbsOrigin(b, ori2);

	if( (GetConVarFloat(Cvar_DmgDistance) == 0.0) || (GetVectorDistance(ori1, ori2, true) < GetConVarFloat(Cvar_DmgDistance)) )
	{
		if( t_same ) 
		{
			// Rukia: Infect same team if allowed is on
			if(allow)
			{
				SendInfection(b,a,true,true);
			}
			// Rukia: Heal if applicable.
			else if (ClientInfected[b] || ClientFriendlyInfected[b])
			{ 
				ClientInfected[b] = 0; 
				ClientFriendlyInfected[b] = false; 
				SetEntityRenderColor(b,255,255,255,255);

				PrintHintText(b,"You have been cured!");
				PrintHintText(a,"%N has been cured!", b);
			}
		}
		// Rukia: Infect the opposing team otherwise
		else if (!ClientInfected[b])
		{
			SendInfection(b,a,false,true);
		}
	}
}

public RunInfection()
{
	static Float:InfectedVec[MAXPLAYERS][3];
	static Float:NotInfectedVec[MAXPLAYERS][3];
	static PlayerVec[MAXPLAYERS]
	
	new InfectedCount, NotInfectedCount
	
	new maxplayers = GetMaxClients();
	new i = 1, a = 0
	for(; i <= maxplayers; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i)) continue;
		PlayerVec[a] = i;
		
		if(ClientInfected[i])
		{
			GetClientAbsOrigin(i, InfectedVec[a]);
			InfectedCount++;
		}
		else
		{
			GetClientAbsOrigin(i, NotInfectedVec[a]);
			NotInfectedCount++;
		}
		
		a++;
	}
	
	new k = 0, m = 0;
	for(i = 0; i < InfectedCount; i++)
	{
		for(k = 0; k < NotInfectedCount; k++)
		{
			if(GetVectorDistance(InfectedVec[i], NotInfectedVec[k], true) < GetConVarFloat(Cvar_SpreadDistance) )
			{
				a = PlayerVec[k];
				m = PlayerVec[i];
				TransmitInfection(a,m);
				
			}
		}
	}
}

TransmitInfection(from, to)
{
	// Rukia: Spread to all
	if(GetConVarInt(Cvar_SpreadAll) )
	{
		SendInfection(to,from,GetClientTeam(from) == GetClientTeam(to),false);
		return;
	}
	
	// Rukia: Don't spread to medics
	if(!GetConVarInt(Cvar_InfectMedics) && (TF2_GetPlayerClass(to) == TFClass_Medic) )
	{
		return;
	}
	
	if(!GetConVarInt(Cvar_InfectInfector))
	{
		new a = from;
		while(ClientInfected[a])
		{
			if(ClientInfected[a] == to) return;
			a = ClientInfected[a];
		}
	}

	// Rukia: are the teams identical?
	new t_same = GetClientTeam(from) == GetClientTeam(to);
	
	// Rukia: Spread to same team
	if(GetConVarInt(Cvar_SpreadSameTeam) && t_same )
	{
		SendInfection(to,from,true,false);
	}
	// Rukia: Spread to opposing team
	else if(GetConVarInt(Cvar_SpreadOpposingTeam) && !t_same )
	{
		SendInfection(to,from,false,false);
	}
	// Rukia: If a medic infects a friendly, allow the infection to spread across team boundaries
	else if(GetConVarInt(Cvar_InfectSameTeam) && !t_same && ClientFriendlyInfected[from])
	{
		SendInfection(to,from,false,false);
	}
}

SendInfection(to,from,bool:friendly,bool:infect)
{
	if (!ClientInfected[to])
	{
		ClientInfected[to] = from;
		ClientFriendlyInfected[to] = friendly;
		if (GetClientTeam(to) == _:TFTeam_Blue)
			SetEntityRenderColor(to,GetConVarInt(CvarRed),GetConVarInt(CvarGreen),GetConVarInt(CvarBlue),GetConVarInt(CvarTrans));
		else // Switch Red & Blue for Red Team.
			SetEntityRenderColor(to,GetConVarInt(CvarBlue),GetConVarInt(CvarGreen),GetConVarInt(CvarRed),GetConVarInt(CvarTrans));

		PrintHintText(to,"You have been infected!");

		if(IsClientInGame(from) && IsPlayerAlive(from))
		{
			if(infect) PrintHintText(from,"Virus administered!");
			else PrintHintText(from,"Virus spread!");
		}
	}
}

public Native_ControlMedicInfect(Handle:plugin,numParams)
{
	if (numParams == 0)
		NativeControl = true;
	else if(numParams == 1)
		NativeControl = GetNativeCell(1);
}

public Native_SetMedicInfect(Handle:plugin,numParams)
{
	if (numParams >= 1 && numParams <= 3)
	{
		new client = GetNativeCell(1);
		NativeMedicArmed[client] = (numParams >= 2) ? GetNativeCell(2) : true;
		NativeAmount[client] = (numParams >= 3) ? GetNativeCell(3) : 0;
	}
}

public Native_MedicInfect(Handle:plugin,numParams)
{
	if (numParams >= 2 && numParams <= 3)
	{
		new client = GetNativeCell(1);
		new target = GetNativeCell(2);
		new allow = (numParams >= 3) ? GetNativeCell(3) : 0;
		MedicInfect(client,target,allow)
	}
}

public Native_HealInfect(Handle:plugin,numParams)
{
	if (numParams >= 2 && numParams <= 2)
	{
		new client = GetNativeCell(1);
		new target = GetNativeCell(2);
		{ 
			if (ClientInfected[target] || ClientFriendlyInfected[target])
			{
				ClientInfected[target] = 0; 
				ClientFriendlyInfected[target] = false; 
				SetEntityRenderColor(target,255,255,255,255);
				PrintHintText(target,"You have been cured!");

				if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client))
					PrintHintText(client,"%N has been cured!", target);
			}
		}
	}
}
