//Osaka: This plugin IS CPU INTENSIVE.
//	I will note the various optimizations, great and small, used to bring the intensiveness down as far as possible.
//	One optimization not used, but that is implimentable, is to cache ConVar's directly into variables.

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

new ClientInfected[MAXPLAYERS + 1];
new bool:ClientFriendlyInfected[MAXPLAYERS + 1];
new Float:MedicInfectDelay[MAXPLAYERS + 1];

// Osaka: Game Frame optimizations
new bool:GameFrameMedi = true;
new bool:GameFrameSpread = false;

public Plugin:myinfo = 
{
	name = "Medic Infection",
	author = "Twilight Suzuka",
	description = "Allows medics to infect again",
	version = "Gamma:7",
	url = "http://www.sourcemod.net/"
};

new Handle:CvarEnable = INVALID_HANDLE;

new Handle:Cvar_DmgAmount = INVALID_HANDLE;
new Handle:Cvar_DmgTime = INVALID_HANDLE;

new Handle:Cvar_InfectEnable = INVALID_HANDLE;
new Handle:Cvar_InfectDistance = INVALID_HANDLE;

new Handle:Cvar_InfectMedi = INVALID_HANDLE;
new Handle:Cvar_InfectMediCheckTime = INVALID_HANDLE;
new Handle:Cvar_InfectSyringe = INVALID_HANDLE;

new Handle:Cvar_InfectMedics = INVALID_HANDLE;
new Handle:Cvar_InfectHeal = INVALID_HANDLE
new Handle:Cvar_InfectSameTeam = INVALID_HANDLE;
new Handle:Cvar_InfectOpposingTeam = INVALID_HANDLE;

new Handle:Cvar_InfectFailedDelay = INVALID_HANDLE;
new Handle:Cvar_InfectSucceededDelay = INVALID_HANDLE;

new Handle:Cvar_SpreadEnable = INVALID_HANDLE;
new Handle:Cvar_SpreadDistance = INVALID_HANDLE;
new Handle:Cvar_SpreadCheckTime = INVALID_HANDLE;

new Handle:Cvar_SpreadAll = INVALID_HANDLE;
new Handle:Cvar_SpreadInfector = INVALID_HANDLE;
new Handle:Cvar_SpreadMedics = INVALID_HANDLE;
new Handle:Cvar_SpreadSameTeam = INVALID_HANDLE;
new Handle:Cvar_SpreadOpposingTeam = INVALID_HANDLE;

new Handle:Cvar_SameColors = INVALID_HANDLE;
new Handle:Cvar_GunColors = INVALID_HANDLE;
new Handle:Cvar_BothTeamsRed, Handle:Cvar_BothTeamsBlue, Handle:Cvar_BothTeamsGreen, Handle:Cvar_BothTeamsAlpha;
new Handle:Cvar_RTeamRed, Handle:Cvar_RTeamBlue, Handle:Cvar_RTeamGreen, Handle:Cvar_RTeamAlpha;
new Handle:Cvar_BTeamRed, Handle:Cvar_BTeamBlue, Handle:Cvar_BTeamGreen, Handle:Cvar_BTeamAlpha;

new Handle:InfectionTimer = INVALID_HANDLE;
new Handle:MediTimer = INVALID_HANDLE;
new Handle:SpreadTimer = INVALID_HANDLE;

public OnPluginStart()
{
	CvarEnable = CreateConVar("medic_infect_on", "1", "1 turns the plugin on 0 is off", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	Cvar_DmgAmount = CreateConVar("sv_medic_infect_dmg_amount", "10", "Amount of damage medic infect does each heartbeat", FCVAR_PLUGIN);
	Cvar_DmgTime = CreateConVar("sv_medic_infect_dmg_time", "12", "Amount of time between infection heartbeats", FCVAR_PLUGIN);
	
	Cvar_InfectEnable = CreateConVar("sv_medic_infect_allow_infect", "1", "Can medics infect?", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	Cvar_InfectDistance = CreateConVar("sv_medic_infect_infect_distance", "0.0", "Distance infection can be injected from", FCVAR_PLUGIN);
	
	Cvar_InfectMedi = CreateConVar("sv_medic_infect_medi", "1", "Infect using medi gun", FCVAR_PLUGIN);
	Cvar_InfectMediCheckTime = CreateConVar("sv_medic_infect_medi_check_time", "0.0", "Amount of time between checks, 0.0 for gameframe", FCVAR_PLUGIN);
	//Cvar_InfectSyringe = CreateConVar("sv_medic_infect_syringe", "0", "Infect using syringe gun", FCVAR_PLUGIN);

	Cvar_InfectHeal = CreateConVar("sv_medic_infect_heal", "1", "Allow medics to uninfect players", FCVAR_PLUGIN);
	Cvar_InfectFailedDelay = CreateConVar("sv_medic_failed_infect_delay", "1.0", "Delay between failed infections", FCVAR_PLUGIN);
	Cvar_InfectSucceededDelay = CreateConVar("sv_medic_succeeded_infect_delay", "5.0", "Delay between succeeded infections", FCVAR_PLUGIN);
	
	Cvar_InfectMedics = CreateConVar("sv_medic_infect_medics", "0", "Allow medics to be infected", FCVAR_PLUGIN);
	Cvar_InfectSameTeam = CreateConVar("sv_medic_infect_friendly", "1", "Allow medics to infect friends", FCVAR_PLUGIN);
	Cvar_InfectOpposingTeam = CreateConVar("sv_medic_infect_enemy", "1", "Allow medics to infect enemies", FCVAR_PLUGIN);
	
	Cvar_SpreadEnable = CreateConVar("sv_medic_infect_allow_spread", "1", "Can the infection spread?", FCVAR_PLUGIN);
	Cvar_SpreadDistance = CreateConVar("sv_medic_infect_spread_distance", "2000.0", "Distance infection can spread", FCVAR_PLUGIN);	
	Cvar_SpreadCheckTime = CreateConVar("sv_medic_infect_spread_check_time", "1.0", "Amount of time between checks, 0.0 for gameframe", FCVAR_PLUGIN);
	
	Cvar_SpreadAll = CreateConVar("sv_medic_infect_spread_all", "0", "Allow medical infections to run rampant", FCVAR_PLUGIN);
	Cvar_SpreadInfector = CreateConVar("sv_medic_infect_spread_infector", "0", "Should infectors be vaccinated?", FCVAR_PLUGIN);
	Cvar_SpreadMedics = CreateConVar("sv_medic_infect_spread_medics", "0", "Should medics be vaccinated?", FCVAR_PLUGIN);
	Cvar_SpreadSameTeam = CreateConVar("sv_medic_infect_spread_friendly", "1", "Allow medical infections to run rampant inside a team", FCVAR_PLUGIN);
	Cvar_SpreadOpposingTeam = CreateConVar("sv_medic_infect_spread_enemy", "0", "Allow medical infections to run rampant between teams", FCVAR_PLUGIN);	
	
	Cvar_SameColors = CreateConVar("medic_infect_same_colors", "1", "Infected from both teams use same colors", FCVAR_NOTIFY);
	Cvar_GunColors = CreateConVar("medic_infect_gun_colors", "1", "Infected players guns reflect teams", FCVAR_NOTIFY);

	Cvar_BothTeamsRed = CreateConVar("medic_infect_teams_red", "0", "[Both Teams Infected] Amount of Red", FCVAR_NOTIFY, true, 0.0, true, 255.0);
	Cvar_BothTeamsGreen = CreateConVar("medic_infect_teams_green", "255", "[Both Team Infected] Amount of Green", FCVAR_NOTIFY, true, 0.0, true, 255.0);
	Cvar_BothTeamsBlue = CreateConVar("medic_infect_teams_blue", "100", "[Both Team Infected] Amount of Blue", FCVAR_NOTIFY, true, 0.0, true, 255.0);
	Cvar_BothTeamsAlpha = CreateConVar("medic_infect_teams_alpha", "255", "[Both Team Infected] Amount of Transperency", FCVAR_NOTIFY, true, 0.0, true, 255.0);
	
	Cvar_RTeamRed = CreateConVar("medic_infect_redteam_red", "155", "[Red Team Infected] Amount of Red", FCVAR_NOTIFY, true, 0.0, true, 255.0);
	Cvar_RTeamGreen = CreateConVar("medic_infect_redteam_green", "255", "[Red Team Infected] Amount of Green", FCVAR_NOTIFY, true, 0.0, true, 255.0);
	Cvar_RTeamBlue = CreateConVar("medic_infect_redteam_blue", "100", "[Red Team Infected] Amount of Blue", FCVAR_NOTIFY, true, 0.0, true, 255.0);
	Cvar_RTeamAlpha = CreateConVar("medic_infect_redteam_alpha", "255", "[Red Team Infected] Amount of Transperency", FCVAR_NOTIFY, true, 0.0, true, 255.0);

	Cvar_BTeamBlue = CreateConVar("medic_infect_blueteam_blue", "0", "[Blue Team Infected] Amount of Blue", FCVAR_NOTIFY, true, 0.0, true, 255.0);
	Cvar_BTeamGreen = CreateConVar("medic_infect_blueteam_green", "255", "[Blue Team Infected] Amount of Green", FCVAR_NOTIFY, true, 0.0, true, 255.0);
	Cvar_BTeamBlue = CreateConVar("medic_infect_blueteam_blue", "255", "[Blue Team Infected] Amount of Blue", FCVAR_NOTIFY, true, 0.0, true, 255.0);
	Cvar_BTeamAlpha = CreateConVar("medic_infect_blueteam_alpha", "255", "[Blue Team Infected] Amount of Transperency", FCVAR_NOTIFY, true, 0.0, true, 255.0);

	HookEventEx("player_death", MedicModify, EventHookMode_Pre);
}

// Osaka: Start up the infection timer
public OnConfigsExecuted()
{
	InfectionTimer = CreateTimer(GetConVarFloat(Cvar_DmgTime), HandleInfection, _, TIMER_REPEAT);

	new Float:timeval = GetConVarFloat(Cvar_InfectMediCheckTime);
	if(timeval > 0.0) MediTimer = CreateTimer(timeval, HandleMediInfection, _, TIMER_REPEAT);
	else GameFrameMedi = true;
	
	timeval = GetConVarFloat(Cvar_SpreadCheckTime);
	if(timeval > 0.0) SpreadTimer = CreateTimer(timeval, HandleSpreadInfection, _, TIMER_REPEAT);
	else GameFrameSpread = true;
	
	
	HookConVarChange(Cvar_DmgTime, HandleInfectionChange);
	HookConVarChange(Cvar_InfectMediCheckTime, HandleMediChange);
	HookConVarChange(Cvar_SpreadCheckTime, HandleSpreadChange);
}

// Osaka: catching CVAR's is cheap; reallocating a timer is slower.
//	So catch the ConVar changes and change the timer only in those situations
public HandleInfectionChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	CloseHandle(InfectionTimer);
	InfectionTimer = CreateTimer(StringToFloat(newValue), HandleInfection, _, TIMER_REPEAT);
}

// Osaka: The timer which damages infected players
public Action:HandleInfection(Handle:timer)
{
	if(!GetConVarInt(CvarEnable)) return;
	
	new maxplayers = GetMaxClients();
	for(new a = 1; a <= maxplayers; a++)
	{
		// Osaka: Don't check to see if they are in game. Infected people must be in game.
		//	Doing this reduces the CPU usage significantly for high change rates, but requires testing.
		if(ClientInfected[a] == 0) continue;
		
		// Osaka: This is relatively expensive, but we need to keep them updated.
		InfectColors(a);
		
		new hp = GetClientHealth(a);
		hp -= GetConVarInt(Cvar_DmgAmount);
		
		if(hp <= 0) ForcePlayerSuicide(a);
		else
		{
			//SetEntityHealth(a,hp);
			SetEntProp(a, Prop_Send, "m_iHealth", hp, 1);
			SetEntProp(a, Prop_Data, "m_iHealth", hp, 1);
		}
	}	
}

// Osaka: Redundant, but allows us to skip checks
public OnMapEnd()
{
	new maxplayers = GetMaxClients();
	for(new a = 1; a <= maxplayers; a++)
	{
		ClientInfected[a] = 0;
		ClientFriendlyInfected[a] = false;
		MedicInfectDelay[a] = 0.0;
	}
}

// Osaka: Redundant, but allows us to skip checks
public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	ClientInfected[client] = 0;
	ClientFriendlyInfected[client] = false;
	MedicInfectDelay[client] = 0.0;
	
	return true;
}

// Osaka: Redundant, but allows us to skip checks
public OnClientDisconnect(client)
{
	ClientInfected[client] = 0;
	ClientFriendlyInfected[client] = false;
	MedicInfectDelay[client] = 0.0;
}

// Osaka: Modifies death message to give credit for infections
public Action:MedicModify(Handle:event, const String:name[], bool:dontBroadcast)
{
	new id = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!ClientInfected[id]) return Plugin_Continue;
	
	new infector = ClientInfected[id];
	
	ClientInfected[id] = 0;
	ClientFriendlyInfected[id] = false;

	SetEntityRenderColor(id)
	
	new attacker = GetEventInt(event, "attacker");
	new assister = GetEventInt(event, "assister");
	
	// Osaka: No attacker, give kill to infector
	if(!attacker)
	{
		SetEventString(event, "weapon", "infection");
		SetEventInt(event, "customkill", 1);

		SetEventInt(event, "attacker", GetClientUserId(infector));
		id = infector;
	}
	// Osaka: No assister? Pass it on!
	if(!assister)
	{
		assister = ClientInfected[id];
		if(assister) SetEventInt(event, "assister", GetClientUserId(assister));
	}
	
	return Plugin_Continue;
}

// Osaka: For Syringes, we use the critical attack function, and hope it works well enough. Time will tell.
public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if(!GetConVarInt(CvarEnable)) return Plugin_Continue;
	
	if(
		!GetConVarInt(Cvar_InfectSyringe) 
		|| (TF2_GetPlayerClass(client) != TFClass_Medic) 
		|| (MedicInfectDelay[client] > GetGameTime())
		) 
		return Plugin_Continue;
	
	if(StrEqual(weaponname, "tf_weapon_syringegun_medic") )
	{
		MedicInject(client);
	}
	
	return Plugin_Continue;
}

// Osaka: These checks are worth it if the variables are usually false
//	Spreading the infection need not be in game frame, but some people might want it to be.
public OnGameFrame()
{
	if(GameFrameMedi == true) MediInfection();
	if(GameFrameSpread == true) SpreadInfection();
	
}

public HandleMediChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	CloseHandle(MediTimer);
	new Float:val = StringToFloat(newValue);
	if(val > 0.0) MediTimer = CreateTimer(val, HandleMediInfection, _, TIMER_REPEAT);
	else GameFrameMedi = true;
}

// Osaka: There is no way around it; we need to check each medic and see if they are shooting.
//	I wish SP had an inline directive, but it doesn't. We'll suffer the cost of a function call for modularity
public Action:HandleMediInfection(Handle:timer)
{
	MediInfection();
}

public MediInfection()
{
	if(!GetConVarInt(CvarEnable)) return;
	if(!GetConVarInt(Cvar_InfectMedi)) return;
	
	decl String:classname[32];
	new maxplayers = GetMaxClients();

	for(new i = 1; i <= maxplayers; i++)
	{
		if( !IsClientInGame(i) 
			|| !IsPlayerAlive(i) 
			|| (TF2_GetPlayerClass(i) != TFClass_Medic) 
			|| (MedicInfectDelay[i] > GetGameTime()) 
			) 
			continue;
		
		new weaponent = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
		if(!weaponent) continue;

		if(GetEdictClassname(weaponent, classname , sizeof(classname)) )
		{
			if(StrEqual(classname, "tf_weapon_medigun") )
			{
				MedicInject(i);
			}
		}
	}
}

stock MedicInject(client)
{
	new buttons = GetClientButtons(client);
				
	if(buttons & (IN_ATTACK|IN_RELOAD) )
	{
		new target = GetClientAimTarget(client);
		if(target > 0) 
		{
			MedicInfect(target, client, (buttons & IN_RELOAD) != 0);
			MedicInfectDelay[client] = GetGameTime() + GetConVarFloat(Cvar_InfectSucceededDelay);
			
			return;
		}
	}
	MedicInfectDelay[client] = GetGameTime() + GetConVarFloat(Cvar_InfectFailedDelay); 
}

public MedicInfect(to, from, bool:friendlyInfect)
{
	if(!GetConVarInt(Cvar_InfectEnable)) return;
	
	if(TF2_GetPlayerClass(to) == TFClass_Medic && !GetConVarInt(Cvar_InfectMedics) )  return;
	new same = GetClientTeam(to) == GetClientTeam(from);
	
	if(!friendlyInfect && (same || !GetConVarInt(Cvar_InfectOpposingTeam) ) ) return;
	else if(friendlyInfect && (!same || !GetConVarInt(Cvar_InfectSameTeam) ) ) return;	
	else if(!friendlyInfect && same && GetConVarInt(Cvar_InfectHeal) ) UnInfect(to, from); 
	else
	{
		decl Float:ori1[3], Float:ori2[3], Float:distance;
		distance = GetConVarFloat(Cvar_InfectDistance);
		
		if(distance > 0.1)
		{
			GetClientAbsOrigin(to, ori1);
			GetClientAbsOrigin(from, ori2);

			if( GetVectorDistance(ori1, ori2, true) > distance )
			{
				return;
			}
		}
		
		Infect(to, from, friendlyInfect, true);
	}
}


// Osaka: Spread algorithm
//	The naive algorithm would check each player against every other player, resulting in n^2 behavior (32 * 32)
//	However, note that infected players need only check against uninfected players, and uninfected players need not check at all
//	This reduces the complexity to (n * m), where n = infected and m = uninfected. (16 * 16)

//	How does this improve anything? 
//	The worst case is actually significantly better. 
//	32 * 32 checks is enormous, and done for every single iteration.
//	The worst case for n * m is when n = m, at which case it reduces to n^2.
//	HOWEVER, note that in this case, n = all/2, not n = all such as in the first example.
//	This leads me to believe the n * m algorithm to perform, on average, logarithmically.
//	I cannot prove it, however, for our bounded example of 32 players, it is obvious that 16 * 16 for a worst case is better than 32 * 32.

public HandleSpreadChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	CloseHandle(SpreadTimer);
	new Float:val = StringToFloat(newValue);
	if(val > 0.0) SpreadTimer = CreateTimer(val, HandleSpreadInfection, _, TIMER_REPEAT);
	else GameFrameSpread = true;
}

public Action:HandleSpreadInfection(Handle:timer)
{
	SpreadInfection();
}

// Osaka: Enough of that, onto the function!
public SpreadInfection()
{
	if(!GetConVarInt(Cvar_SpreadEnable)) return;
	
	static Float:InfectedVec[MAXPLAYERS][3];
	static Float:NotInfectedVec[MAXPLAYERS][3];
	static PlayerVec[MAXPLAYERS];
	
	new InfectedCount, NotInfectedCount
	
	new maxplayers = GetMaxClients();
	new i = 1, a = 0;
	
	// Osaka: 
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
	
	// Osaka: InfectedCount is checked implicitly in the for loop below
	if(NotInfectedCount == 0 /*|| InfectedCount == 0*/) return;
	
	// Osaka: Check the infected against the uninfected
	new k = 0, Float:distance = GetConVarFloat(Cvar_SpreadDistance)
	for(i = 0; i < InfectedCount; i++)
	{
		for(k = 0; k < NotInfectedCount; k++)
		{
			// Osaka: We could gain speed by disabling those who are newly infected
			//	However, the common case is that players will NOT be infected via this method
			//	The reason for this is that there is a VERY LARGE amount of space where there ISN'T infected players
			//	Therefore, we reasonably optimize for the common case, and do not encumber the process
			//	This causes the worst case to be easier to predict, and makes certain we don't prematurely optimize
			
			if(GetVectorDistance(InfectedVec[i], NotInfectedVec[k], true) < distance )
			{
				TransmitInfection(PlayerVec[k],PlayerVec[i]);
			}
		}
	}
}

stock TransmitInfection(to,from)
{
	// Osaka: Don't allow infection at all if it is disabled
	if(!GetConVarInt(Cvar_SpreadEnable)) return;
	
	// Osaka: Ignore all other options if spread all is on
	if(GetConVarInt(Cvar_SpreadAll) )
	{
		Infect(to, from, GetClientTeam(from) == GetClientTeam(to), false);
		return;
	}
	
	if(!GetConVarInt(Cvar_SpreadMedics) && (TF2_GetPlayerClass(to) == TFClass_Medic)  )
	{
		return;
	}
	
	// Osaka: Scan back and see if the original infector is about to be infected
	if(!GetConVarInt(Cvar_SpreadInfector))
	{
		new a = from;
		while(ClientInfected[a])
		{
			if(ClientInfected[a] == to) return;
			a = ClientInfected[a];
		}
	}
	
	// Osaka: are the teams identical?
	new t_same = GetClientTeam(from) == GetClientTeam(to);
	
	// Osaka: Spread to same team
	if(GetConVarInt(Cvar_SpreadSameTeam) && t_same )
	{
		Infect(to, from, true, false);
	}
	// Osaka: Spread to opposing team
	else if(GetConVarInt(Cvar_SpreadOpposingTeam) && !t_same )
	{
		Infect(to, from, false, false);
	}
	// Osaka: If a medic infects a friendly, allow the infection to spread across team boundaries
	else if(GetConVarInt(Cvar_InfectSameTeam) && !t_same && ClientFriendlyInfected[from] )
	{
		Infect(to, from, false, false);
	}
}

// Osaka: The encapsulated base of the infection. Add checking layers on top of this.
stock Infect(to, from, bool:friendly, bool:infect)
{
	if(!GetConVarInt(CvarEnable)) return;
	if(ClientInfected[to]) return;
	
	ClientInfected[to] = from;
	ClientFriendlyInfected[to] = friendly;
	InfectColors(to);

	PrintHintText(to, "You have been infected!");
	
	if(infect) PrintHintText(from, "Virus administered!");
	else PrintHintText(from, "Virus spread!");
}

// Osaka: The encapsulated base of the uninfection. Add checking layers on top of this.
stock UnInfect(to, from=0)
{
	if(!GetConVarInt(CvarEnable)) return;
	if(!ClientInfected[to]) return;
	
	ClientInfected[to] = 0;
	ClientFriendlyInfected[to] = false;
	SetEntityRenderColor(to);

	if( IsPlayerAlive(to) ) PrintHintText(to, "You have been uninfected!");
	if(from) PrintHintText(from, "Anti-Virus administered!");
}

// Osaka: Change the colors of the infected player, and their gun, depending on ConVar's
stock InfectColors(client)
{
	new r, b, g, a;
	new TFTeam:team = TFTeam:GetClientTeam(client);
	new SameColors = GetConVarInt( Cvar_SameColors );
	
	// Osaka: This branch saves us two comparisons, and eliminates the need to check SameColors twice.
	if(SameColors > 1) team = TFTeam:SameColors;
	
	if( SameColors  == 1 )
	{
		r = GetConVarInt(Cvar_BothTeamsRed);
		b = GetConVarInt(Cvar_BothTeamsBlue);
		g = GetConVarInt(Cvar_BothTeamsGreen);
		a = GetConVarInt(Cvar_BothTeamsAlpha);
	}		
	else if( team == TFTeam_Red)
	{
		r = GetConVarInt(Cvar_RTeamRed);
		b = GetConVarInt(Cvar_RTeamBlue);
		g = GetConVarInt(Cvar_RTeamGreen);
		a = GetConVarInt(Cvar_RTeamAlpha);
	}
	else if( team == TFTeam_Blue)
	{
		r = GetConVarInt(Cvar_BTeamRed);
		b = GetConVarInt(Cvar_BTeamBlue);
		g = GetConVarInt(Cvar_BTeamGreen);
		a = GetConVarInt(Cvar_BTeamAlpha);
	}
	
	SetEntityRenderColor(client, r, b, g, a);
	
	// Osaka: Set their gun to their team color. Don't change alpha.
	if( GetConVarInt(Cvar_GunColors) || SameColors)
	{
		r = (team == TFTeam_Red) ? 255 : 0;
		b = (team == TFTeam_Blue) ? 255: 0;
		g = 0;
		
		new gun = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		SetEntityRenderColor(gun, r, b, g, a);
	}
}