#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.5"
#define PLUGIN_NAME "L4D2 Special Ammo"

#define TEST_DEBUG 0
#define TEST_DEBUG_LOG 0

static bool:HasDumDumAmmo[MAXPLAYERS+1];

static Handle:SpecialAmmoAmount = INVALID_HANDLE;

static SpecialAmmoUsed[MAXPLAYERS+1];
static killcount[MAXPLAYERS+1];

static Handle:KillCountLimitSetting = INVALID_HANDLE;
static Handle:DumDumForce = INVALID_HANDLE;

static bool:NoDoubleEventFire;


public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = " AtomicStryker ",
	description = " Dish out major damage with special ammo types ",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=114210"
}

public OnPluginStart()
{
	// Requires Left 4 Dead 2
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false))
		SetFailState("Plugin supports Left 4 Dead 2 only.");
	
	HookEvent("infected_hurt", AnInfectedGotHurt);
	HookEvent("player_hurt", APlayerGotHurt);
	HookEvent("weapon_fire", WeaponFired);
	HookEvent("bullet_impact",BulletImpact);
	HookEvent("infected_death", KillCountUpgrade);
	HookEvent("round_start", RoundStartEvent);
	
	CreateConVar("l4d2_specialammo_version", PLUGIN_VERSION, " The version of L4D Special Ammo running ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	SpecialAmmoAmount	= CreateConVar("l4d2_specialammo_amount", "100", " How much special ammo a player gets. (default 50) ", FCVAR_PLUGIN|FCVAR_NOTIFY);
	KillCountLimitSetting = CreateConVar("l4d2_specialammo_killcountsetting", "50", " How much Infected a Player has to shoot to win special ammo. (default 120) ", FCVAR_PLUGIN|FCVAR_NOTIFY);
	DumDumForce = CreateConVar("l4d2_specialammo_dumdumforce", "75.0", " How powerful the DumDum Kickback is. (default 75.0) ", FCVAR_PLUGIN|FCVAR_NOTIFY);
	
	RegAdminCmd("sm_givespecialammo", GiveSpecialAmmo, ADMFLAG_KICK, " sm_givespecialammo <1, 2 or 3> ");
	
	AutoExecConfig(true, "l4d2_specialammo"); // an autoexec! ooooh shiny
}

public Action:RoundStartEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		killcount[i] = 0;
		SpecialAmmoUsed[i] = 0;
		HasDumDumAmmo[i] = false;
	}
}

public OnClientDisconnect(client)
{
	killcount[client] = 0;
	SpecialAmmoUsed[client] = 0;
	HasDumDumAmmo[client] = false;
}

public OnClientPostAdminCheck(client)
{
	killcount[client] = 0;
	SpecialAmmoUsed[client] = 0;
	HasDumDumAmmo[client] = false;
}

public Action:WeaponFired(Handle:event, const String:ename[], bool:dontBroadcast)
{
	// get client and used weapon
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String: weapon[64];
	GetEventString(event, "weapon", weapon, 64);
	
	if(client && (HasDumDumAmmo[client]==true))
	{
		if (StrContains(weapon, "shotgun", false) == -1) SpecialAmmoUsed[client]++; // if not a shotgun, one round per shot.
		else SpecialAmmoUsed[client] = SpecialAmmoUsed[client]+5; // Five times the special rounds usage for shotguns.
		
		new SpecialAmmoLeft = GetConVarInt(SpecialAmmoAmount) - SpecialAmmoUsed[client];
		if((SpecialAmmoLeft % 10) == 0 && SpecialAmmoLeft > 0) // Display a center HUD message every round decimal value of leftover ammo (30, 20, 10...)
			PrintCenterText(client, "DumDum ammo rounds left: %d", SpecialAmmoLeft);
		
		if(SpecialAmmoUsed[client] >= GetConVarInt(SpecialAmmoAmount)) CreateTimer(0.3, OutOfAmmo, client); //to remove the toys
	}
	return Plugin_Continue;
}

public Action:APlayerGotHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetEventInt(event, "attacker");
	if(!attacker) return Plugin_Continue; // if hit by a zombie or anything, we dont care
	
	new client = GetClientOfUserId(attacker);
	if (!HasDumDumAmmo[client] || GetClientTeam(client) != 2) return Plugin_Continue;
	
	new InfClient = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetClientTeam(InfClient) != 3) return Plugin_Continue; //no FF effects (or should we ;P )
	
	decl Float:FiringAngles[3], Float:PushforceAngles[3];
	new Float:force = GetConVarFloat(DumDumForce);
	
	GetClientEyeAngles(client, FiringAngles);
	
	PushforceAngles[0] = FloatMul(Cosine(DegToRad(FiringAngles[1])), force);
	PushforceAngles[1] = FloatMul(Sine(DegToRad(FiringAngles[1])), force);
	PushforceAngles[2] = FloatMul(Sine(DegToRad(FiringAngles[0])), force);
	
	decl Float:current[3], Float:resulting[3];
	GetEntPropVector(InfClient, Prop_Data, "m_vecVelocity", current);
	
	resulting[0] = FloatAdd(current[0], PushforceAngles[0]);
	resulting[1] = FloatAdd(current[1], PushforceAngles[1]);
	resulting[2] = FloatAdd(current[2], PushforceAngles[2]);
	
	TeleportEntity(InfClient, NULL_VECTOR, NULL_VECTOR, resulting);
	
	return Plugin_Continue;
}

public Action:AnInfectedGotHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (!HasDumDumAmmo[client] || GetClientTeam(client) != 2) return Plugin_Continue;
	
	new infectedentity = GetEventInt(event, "entityid");
	
	decl Float:FiringAngles[3], Float:PushforceAngles[3];
	new Float:force = GetConVarFloat(DumDumForce);
	
	GetClientEyeAngles(client, FiringAngles);
	
	PushforceAngles[0] = FloatMul(Cosine(DegToRad(FiringAngles[1])), force);
	PushforceAngles[1] = FloatMul(Sine(DegToRad(FiringAngles[1])), force);
	PushforceAngles[2] = FloatMul(Sine(DegToRad(FiringAngles[0])), force);
	
	decl Float:current[3], Float:resulting[3];
	GetEntPropVector(infectedentity, Prop_Data, "m_vecVelocity", current);
	
	resulting[0] = FloatAdd(current[0], PushforceAngles[0]);	
	resulting[1] = FloatAdd(current[1], PushforceAngles[1]);
	resulting[2] = FloatAdd(current[2], PushforceAngles[2]);
	
	TeleportEntity(infectedentity, NULL_VECTOR, NULL_VECTOR, resulting);
	
	return Plugin_Continue;
}

public Action:OutOfAmmo(Handle:hTimer, any:client)
{
	if (!HasDumDumAmmo[client]) return;

	PrintToChat(client, "\x05You've run out of DumDum ammo.");
	HasDumDumAmmo[client] = false;
	
	SpecialAmmoUsed[client] = 0;
}

public Action:KillCountUpgrade(Handle:event, String:ename[], bool:dontBroadcast)
{
	if (NoDoubleEventFire) return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	new bool:minigun = GetEventBool(event, "minigun");
	new bool:blast = GetEventBool(event, "blast");
	
	NoDoubleEventFire = true;
	
	if (client)
	{
		if (!minigun && !blast)
			killcount[client] += 1;
		else
		{
			NoDoubleEventFire = false;
			return Plugin_Continue;
		}
			
		DebugPrintToAll("Kill Count Upgrade %N, now %i", client, killcount[client]);
		
		if ((killcount[client] % 15) == 0) PrintCenterText(client, "Infected killed: %d", killcount[client]);
		
		if ((killcount[client] % GetConVarInt(KillCountLimitSetting)) == 0 && killcount[client] > 1)
		{
			if(IsClientInGame(client) && GetClientTeam(client) == 2)
			{
				decl String:ammotype[64];
				new luck = GetRandomInt(1,3); // wee randomness!!
				switch(luck)
				{
					case 1:
					{
						SetSpecialAmmoInPlayerGun(client, 0);
						HasDumDumAmmo[client] = false;
						SpecialAmmoUsed[client] = 0;
						ammotype = "Incendiary";
						CheatCommand(client, "upgrade_add", "INCENDIARY_AMMO");
						
						SetSpecialAmmoInPlayerGun(client, GetConVarInt(SpecialAmmoAmount));
					}
					
					case 2:
					{
						SetSpecialAmmoInPlayerGun(client, 0);
						HasDumDumAmmo[client] = false;
						SpecialAmmoUsed[client] = 0;
						ammotype = "Explosive";
						CheatCommand(client, "upgrade_add", "EXPLOSIVE_AMMO");
						
						SetSpecialAmmoInPlayerGun(client, GetConVarInt(SpecialAmmoAmount));
					}
					
					case 3:
					{
						HasDumDumAmmo[client] = true;				
						SpecialAmmoUsed[client]=0;
						ammotype = "DumDum";
					}
				}
				PrintToChatAll("\x04%N\x01 won %s ammo for killing %d Infected!",client, ammotype, killcount[client]);
			}
		}
	}
	
	NoDoubleEventFire = false;
	return Plugin_Continue;
}

public BulletImpact(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	decl Float:Origin[3];	
	Origin[0] = GetEventFloat(event,"x");
	Origin[1] = GetEventFloat(event,"y");
	Origin[2] = GetEventFloat(event,"z");
	
	if(HasDumDumAmmo[client])
	{
		decl Float:Direction[3];
		Direction[0] = GetRandomFloat(-1.0, 1.0);
		Direction[1] = GetRandomFloat(-1.0, 1.0);
		Direction[2] = GetRandomFloat(-1.0, 1.0);
		
		TE_SetupSparks(Origin,Direction,1,3);
		TE_SendToAll();
	}
}

public Action:GiveSpecialAmmo(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_givespecialammo <1, 2 or 3> for incendiary, explosive or dumdum ammo");
		return Plugin_Handled;
	}
	
	decl String:setting[10];
	GetCmdArg(1, setting, sizeof(setting));
	decl String:ammotype[64];
	
	switch (StringToInt(setting))
	{
		case 1:
		{
			SetSpecialAmmoInPlayerGun(client, 0);
			HasDumDumAmmo[client] = false;
			SpecialAmmoUsed[client] = 0;
			ammotype = "Incendiary";
			CheatCommand(client, "upgrade_add", "INCENDIARY_AMMO");
			
			SetSpecialAmmoInPlayerGun(client, GetConVarInt(SpecialAmmoAmount));
		}
		
		case 2:
		{
			SetSpecialAmmoInPlayerGun(client, 0);
			HasDumDumAmmo[client] = false;
			SpecialAmmoUsed[client] = 0;
			ammotype = "Explosive";
			CheatCommand(client, "upgrade_add", "EXPLOSIVE_AMMO");
			
			SetSpecialAmmoInPlayerGun(client, GetConVarInt(SpecialAmmoAmount));
		}
		
		case 3:
		{
			HasDumDumAmmo[client] = true;				
			SpecialAmmoUsed[client] = 0;
			ammotype = "DumDum";
		}
	}
	
	PrintToChatAll("\x04%N\x01 cheated himself some %s ammo", client, ammotype);
	return Plugin_Handled;
}

stock GetSpecialAmmoInPlayerGun(client) //returns the amount of special rounds in your gun
{
	if (!client) client = 1;
	new gunent = GetPlayerWeaponSlot(client, 0);
	if (IsValidEdict(gunent))
		return GetEntProp(gunent, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", 1);
	else return 0;
}

stock SetSpecialAmmoInPlayerGun(client, amount)
{
	if (!client) client = 1;
	
	if (HasPlayerShottie(client))
	{
		amount = amount / 5;
	}
	
	new gunent = GetPlayerWeaponSlot(client, 0);
	if (IsValidEdict(gunent) && amount > 0)
	{
		new Handle:datapack = CreateDataPack();
		WritePackCell(datapack, gunent);
		WritePackCell(datapack, amount);
		CreateTimer(0.2, SetGunSpecialAmmo, datapack);
	}
}

public Action:SetGunSpecialAmmo(Handle:timer, Handle:datapack)
{
	ResetPack(datapack);
	new ent = ReadPackCell(datapack);
	new amount = ReadPackCell(datapack);
	CloseHandle(datapack);
	
	DebugPrintToAll("Delayed ammo Setting in gun %i to %i", ent, amount);
	SetEntProp(ent, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", amount, 1);
}

stock bool:HasPlayerShottie(client)
{
	if (!client) client = 1;
	
	decl String: weapon[64];
	new gunent = GetPlayerWeaponSlot(client, 0);
	if (IsValidEdict(gunent))
	{
		GetEdictClassname(gunent, weapon, sizeof(weapon));
		if (StrContains(weapon, "shotgun", false) != -1)
			return true;
	}
	return false;
}

stock CheatCommand(client, String:command[], String:arguments[]="")
{
	new userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userflags);
}

stock DebugPrintToAll(const String:format[], any:...)
{
	#if TEST_DEBUG	|| TEST_DEBUG_LOG
	decl String:buffer[192];
	
	VFormat(buffer, sizeof(buffer), format, 2);
	
	#if TEST_DEBUG
	PrintToChatAll("[Specialammo] %s", buffer);
	PrintToConsole(0, "[Specialammo] %s", buffer);
	#endif
	
	LogMessage("%s", buffer);
	#else
	//suppress "format" never used warning
	if(format[0])
		return;
	else
		return;
	#endif
}