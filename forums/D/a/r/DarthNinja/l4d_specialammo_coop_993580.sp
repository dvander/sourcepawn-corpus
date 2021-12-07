#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.7"
#define PLUGIN_NAME "L4D Special Ammo"


new Handle:AddUpgrade = INVALID_HANDLE;
new Handle:RemoveUpgrade = INVALID_HANDLE;

new bool:HasFieryAmmo[MAXPLAYERS+1];
new bool:HasHighdamageAmmo[MAXPLAYERS+1];
new bool:HasDumDumAmmo[MAXPLAYERS+1];
new Handle:SpecialAmmoAmount = INVALID_HANDLE;
new SpecialAmmoUsed[MAXPLAYERS+1];
new killcount[MAXPLAYERS+1];
new Handle:KillCountLimitSetting = INVALID_HANDLE;
new Handle:DumDumForce = INVALID_HANDLE;
new Handle:CanLightTank = INVALID_HANDLE;
new Handle:AutoRecoilReducer = INVALID_HANDLE;

new UserMsg:sayTextMsgId;


public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = " AtomicStryker ",
	description = " Dish out major damage with special ammo types ",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=98354"
}

public OnMapStart()
{
	decl String:gamemode[64];
	GetConVarString(FindConVar("mp_gamemode"), gamemode, 64);
	new Handle:CVAR = FindConVar("survivor_upgrades"); // in case the admin hasn't set this.
	SetConVarInt(CVAR, 1);
}

public OnMapEnd()
{
	PrintToServer("Map end, Special Ammo Plugin unloading.");
}

public OnPluginStart()
{
	HookEvent("infected_hurt", AnInfectedGotHurt);
	HookEvent("player_hurt", APlayerGotHurt);
	HookEvent("weapon_fire", WeaponFired);
	HookEvent("bullet_impact",BulletImpact);
	HookEvent("infected_death", KillCountUpgrade);
	HookEvent("round_end", RoundHasEnded);
	HookEvent("map_transition", RoundHasEnded);
	HookEvent("mission_lost", RoundHasEnded);

	sayTextMsgId = GetUserMessageId("SayText");
	HookUserMessage(sayTextMsgId, SayCommandExecuted, true);
	
	CreateConVar("l4d_specialammo_version", PLUGIN_VERSION, " The version of L4D Special Ammo running ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	SpecialAmmoAmount	= CreateConVar("l4d_specialammo_amount", "100", " How much special ammo a player gets. (default 50) ", FCVAR_PLUGIN|FCVAR_NOTIFY);
	CanLightTank = CreateConVar("l4d_specialammo_canlighttank", "0", " Does incendiary ammo set the Tank aflame? (default 0) ", FCVAR_PLUGIN|FCVAR_NOTIFY);
	AutoRecoilReducer = CreateConVar("l4d_specialammo_recoilreduction", "1", " Does special ammo have less recoil? (default 1) ", FCVAR_PLUGIN|FCVAR_NOTIFY);
	KillCountLimitSetting = CreateConVar("l4d_specialammo_killcountsetting", "50", " How much Infected a Player has to shoot to win special ammo. (default 120) ", FCVAR_PLUGIN|FCVAR_NOTIFY);
	DumDumForce = CreateConVar("l4d_specialammo_dumdumforce", "75.0", " How powerful the DumDum Kickback is. (default 75.0) ", FCVAR_PLUGIN|FCVAR_NOTIFY);
	
	RegAdminCmd("sm_givespecialammo", GiveSpecialAmmo, ADMFLAG_KICK, " sm_givespecialammo <1, 2 or 3> ");
	
	AutoExecConfig(true, "l4d_specialammo"); // an autoexec! ooooh shiny
	
	
	LoadTranslations("common.phrases"); // Needed for SDK Calls
	
	StartPrepSDKCall(SDKCall_Player);
	if (!PrepSDKCall_SetSignature(SDKLibrary_Server, "\xA1****\x83***\x57\x8B\xF9\x0F*****\x8B***\x56\x51\xE8****\x8B\xF0\x83\xC4\x04", 34))
	{
		PrepSDKCall_SetSignature(SDKLibrary_Server, "@_ZN13CTerrorPlayer10AddUpgradeE19SurvivorUpgradeType", 0);
	}
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue);
	AddUpgrade = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Player);
	if (!PrepSDKCall_SetSignature(SDKLibrary_Server, "\x51\x53\x55\x8B***\x8B\xD9\x56\x8B\xCD\x83\xE1\x1F\xBE\x01\x00\x00\x00\x57\xD3\xE6\x8B\xFD\xC1\xFF\x05\x89***", 32))
	{
		PrepSDKCall_SetSignature(SDKLibrary_Server, "@_ZN13CTerrorPlayer13RemoveUpgradeE19SurvivorUpgradeType", 0);
	}
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue);
	RemoveUpgrade = EndPrepSDKCall();
	
}

public Action:WeaponFired(Handle:event, const String:ename[], bool:dontBroadcast)
{
	// get client and used weapon
	new client=GetClientOfUserId(GetEventInt(event, "userid"));
	decl String: weapon[64];
	GetEventString(event, "weapon", weapon, 64)
	
	if(client && (HasFieryAmmo[client]==true || HasHighdamageAmmo[client]==true || HasDumDumAmmo[client]==true)) // if client hasnt special ammo, we dont care
	{
		if (StrContains(weapon, "shotgun", false)==-1) SpecialAmmoUsed[client]++; // if not a shotgun, one round per shot.
		if (StrContains(weapon, "shotgun", false)!=-1) SpecialAmmoUsed[client] = SpecialAmmoUsed[client]+5; // Five times the special rounds usage for shotguns.
		
		new SpecialAmmoLeft = GetConVarInt(SpecialAmmoAmount) - SpecialAmmoUsed[client]
		if((SpecialAmmoLeft % 10) == 0 && SpecialAmmoLeft != 0) // Display a center HUD message every round decimal value of leftover ammo (30, 20, 10...)
			PrintCenterText(client, "Special ammo rounds left: %d", SpecialAmmoLeft);
		
		if(SpecialAmmoUsed[client]>=GetConVarInt(SpecialAmmoAmount)) CreateTimer(0.3, OutOfAmmo, client); //to remove the toys
	}
	return Plugin_Continue;
}

public Action:APlayerGotHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetEventInt(event, "attacker");
	if(attacker == 0) return Plugin_Continue; // if hit by a zombie or anything, we dont care
	
	new client = GetClientOfUserId(attacker);
	if (!HasFieryAmmo[client] && !HasDumDumAmmo[client]==true) return Plugin_Continue; //this function only handles special ammo
	if (GetClientTeam(client) != 2) return Plugin_Continue; //if for some reason a Zombie ends up with incendiary ammo LOL
	
	new InfClient = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetClientTeam(InfClient) != 3) return Plugin_Continue; //no FF effects (or should we ;P )
	
	if (HasFieryAmmo[client])
	{
		decl String:class_string[64];
		GetClientModel(InfClient, class_string, 64);
		if(StrContains(class_string, "hulk", false)!=-1 && GetConVarInt(CanLightTank)==0) return Plugin_Continue; //only burn Playertanks if the convar is 1
		
		new damagetype = GetEventInt(event, "type");
		if(damagetype != 64 && damagetype != 128 && damagetype != 268435464)
		{
			IgniteEntity(InfClient, 120.0, false);
			if(StrContains(class_string, "hulk", false)!=-1) SetEntPropFloat(InfClient, Prop_Data, "m_flLaggedMovementValue", 1.3); // for a mad speed increase
		}
	}
	
	if (HasDumDumAmmo[client])
	{
		decl Float:FiringAngles[3];
		decl Float:PushforceAngles[3];
		new Float:force = GetConVarFloat(DumDumForce);
		
		GetClientEyeAngles(client, FiringAngles);
		
		PushforceAngles[0] = FloatMul(Cosine(DegToRad(FiringAngles[1])), force);
		PushforceAngles[1] = FloatMul(Sine(DegToRad(FiringAngles[1])), force);
		PushforceAngles[2] = FloatMul(Sine(DegToRad(FiringAngles[0])), force);
		
		decl Float:current[3];
		GetEntPropVector(InfClient, Prop_Data, "m_vecVelocity", current);
		
		decl Float:resulting[3];
		resulting[0] = FloatAdd(current[0], PushforceAngles[0]);
		resulting[1] = FloatAdd(current[1], PushforceAngles[1]);
		resulting[2] = FloatAdd(current[2], PushforceAngles[2]);
		
		TeleportEntity(InfClient, NULL_VECTOR, NULL_VECTOR, resulting);
	}
	
	return Plugin_Continue;
}

public Action:AnInfectedGotHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (!HasFieryAmmo[client] && !HasDumDumAmmo[client]==true) return Plugin_Continue; //this function only handles special ammo
	if (GetClientTeam(client) != 2) return Plugin_Continue; //if for some reason a Zombie ends up with incendiary ammo LOL
	
	new infectedentity = GetEventInt(event, "entityid");
	
	if (HasFieryAmmo[client])
	{
		decl String:class_string[64];
		GetEntityNetClass(infectedentity, class_string, 64); // witch has no client, so we cant use getclientmodel
		if(strcmp(class_string, "Witch")==0) return Plugin_Continue; // no witch burning
		
		new damagetype = GetEventInt(event, "type");
		if(damagetype != 64 && damagetype != 128 && damagetype != 268435464)
		{
			IgniteEntity(infectedentity, 120.0, false);
		}
	}
	
	if (HasDumDumAmmo[client])
	{
		decl Float:FiringAngles[3];
		decl Float:PushforceAngles[3];
		new Float:force = GetConVarFloat(DumDumForce);
		
		GetClientEyeAngles(client, FiringAngles);
		
		PushforceAngles[0] = FloatMul(Cosine(DegToRad(FiringAngles[1])), force);
		PushforceAngles[1] = FloatMul(Sine(DegToRad(FiringAngles[1])), force);
		PushforceAngles[2] = FloatMul(Sine(DegToRad(FiringAngles[0])), force);
		
		decl Float:current[3];
		GetEntPropVector(infectedentity, Prop_Data, "m_vecVelocity", current);
		
		decl Float:resulting[3];
		resulting[0] = FloatAdd(current[0], PushforceAngles[0])		
		resulting[1] = FloatAdd(current[1], PushforceAngles[1])
		resulting[2] = FloatAdd(current[2], PushforceAngles[2])
		
		TeleportEntity(infectedentity, NULL_VECTOR, NULL_VECTOR, resulting);
	}
	
	return Plugin_Continue;
}

public Action:OutOfAmmo(Handle:hTimer, any:client)
{
	if(HasFieryAmmo[client])
	{
		PrintToChat(client, "\x05You've run out of incendiary ammo.");
		HasFieryAmmo[client]=false;
		SDKCall(RemoveUpgrade, client, 19); // remove recoil dampener
	}
	if(HasHighdamageAmmo[client])
	{
		PrintToChat(client, "\x05You've run out of hollow-point ammo.");
		SDKCall(RemoveUpgrade, client, 21);
		HasHighdamageAmmo[client]=false;
		SDKCall(RemoveUpgrade, client, 19); // remove recoil dampener
	}
	if(HasDumDumAmmo[client])
	{
		PrintToChat(client, "\x05You've run out of DumDum ammo.");
		HasDumDumAmmo[client]=false;
		SDKCall(RemoveUpgrade, client, 19); // remove recoil dampener
	}
	
	SpecialAmmoUsed[client]=0;
}

public Action:KillCountUpgrade(Handle:event, String:ename[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	new bool:minigun = GetEventBool(event, "minigun");
	new bool:blast = GetEventBool(event, "blast");
	
	if (client)
	{
		if (!minigun && !blast) killcount[client] += 1;
		
		if ((killcount[client] % 20) == 0) PrintCenterText(client, "Infected killed: %d", killcount[client]);
		
		if ((killcount[client] % GetConVarInt(KillCountLimitSetting)) == 0 && killcount[client] > 1)
		{
			if(IsClientInGame(client)==true && GetClientTeam(client)==2)
			{
				
				decl String:ammotype[64];
				new luck = GetRandomInt(1,3) // wee randomness!!
				switch(luck)
				{
				case 1:
					{
						HasHighdamageAmmo[client] = false;
						HasFieryAmmo[client] = true;
						HasDumDumAmmo[client] = false;
						SpecialAmmoUsed[client]=0;
						ammotype = "Incendiary"
						if(GetConVarInt(AutoRecoilReducer)==1) SDKCall(AddUpgrade, client, 19); //add the Recoil dampener if demanded
					}
				case 2:
					{
						HasHighdamageAmmo[client] = true;
						SDKCall(AddUpgrade, client, 21); //add Hollowpoints
						HasFieryAmmo[client] = false;
						HasDumDumAmmo[client] = false;
						SpecialAmmoUsed[client]=0;
						ammotype = "Hollowpoint"
						if(GetConVarInt(AutoRecoilReducer)==1) SDKCall(AddUpgrade, client, 19); //add the Recoil dampener if demanded
					}
				case 3:
					{
						HasHighdamageAmmo[client] = false;
						HasFieryAmmo[client] = false;
						HasDumDumAmmo[client] = true;				
						SpecialAmmoUsed[client]=0;
						ammotype = "DumDum"
						if(GetConVarInt(AutoRecoilReducer)==1) SDKCall(AddUpgrade, client, 19); //add the Recoil dampener if demanded
					}
				}
				decl String:name[64];
				GetClientName(client, name, 64);
				PrintToChatAll("\x04%s\x01 won %s ammo for killing %d Infected!",name, ammotype, killcount[client]);
			}
		}
	}
	
	return Plugin_Continue;
}

public BulletImpact(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	decl Float:Origin[3];	
	Origin[0] = GetEventFloat(event,"x");
	Origin[1] = GetEventFloat(event,"y");
	Origin[2] = GetEventFloat(event,"z");
	
	if(HasHighdamageAmmo[client] || HasDumDumAmmo[client])
	{
		decl Float:Direction[3];
		Direction[0] = GetRandomFloat(-1.0, 1.0);
		Direction[1] = GetRandomFloat(-1.0, 1.0);
		Direction[2] = GetRandomFloat(-1.0, 1.0);
		
		TE_SetupSparks(Origin,Direction,1,3);
		TE_SendToAll();
	}
	
	if(HasFieryAmmo[client])
	{
		TE_SetupMuzzleFlash(Origin,Origin,1.5,1);
		TE_SendToAll();
		CreateParticleEffect(Origin, "Molotov_groundfire", 1.0);
	}
}

public Action:RoundHasEnded(Handle:event, const String:name[], bool:dontBroadcast)
{
	// One Function to control them all, one function to find them,
	// one function to find them all and in the dark null reset them
	// in the land of Sourcepawn where the memoryleaks lie
	
	for(new i=1; i<=MaxClients; ++i)
	{
		HasFieryAmmo[i]=false;
		HasHighdamageAmmo[i]=false;
		HasDumDumAmmo[i]=false;
		killcount[i]=0;
		if(IsClientInGame(i))
		{
			SDKCall(RemoveUpgrade, i, 21);
			SDKCall(RemoveUpgrade, i, 19);
		}
	}
	return Plugin_Continue;
}

public Action:GiveSpecialAmmo(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_givespecialammo <1, 2 or 3>");
		return Plugin_Handled;
	}
	
	decl String:setting[10];
	GetCmdArg(1, setting, sizeof(setting));
	decl String:ammotype[64];
	
	switch (StringToInt(setting))
	{
	case 1:
		{
			HasHighdamageAmmo[client] = false;
			HasFieryAmmo[client] = true;
			HasDumDumAmmo[client] = false;
			SpecialAmmoUsed[client]=0;
			ammotype = "Incendiary"
			if(GetConVarInt(AutoRecoilReducer)==1) SDKCall(AddUpgrade, client, 19); //add the Recoil dampener if demanded
		}
		
	case 2:
		{
			HasHighdamageAmmo[client] = true;
			SDKCall(AddUpgrade, client, 21); //add Hollowpoints
			HasFieryAmmo[client] = false;
			HasDumDumAmmo[client] = false;
			SpecialAmmoUsed[client]=0;
			ammotype = "Hollowpoint"
			if(GetConVarInt(AutoRecoilReducer)==1) SDKCall(AddUpgrade, client, 19); //add the Recoil dampener if demanded
		}
		
	case 3:
		{
			HasHighdamageAmmo[client] = false;
			HasFieryAmmo[client] = false;
			HasDumDumAmmo[client] = true;				
			SpecialAmmoUsed[client]=0;
			ammotype = "DumDum"
			if(GetConVarInt(AutoRecoilReducer)==1) SDKCall(AddUpgrade, client, 19); //add the Recoil dampener if demanded
		}
	}
	
	decl String:name[64];
	GetClientName(client, name, 64);
	PrintToChatAll("\x04%s\x01 cheated himself some  %s ammo",name, ammotype, killcount[client]);
	return Plugin_Handled;
}


public Action:SayCommandExecuted(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	decl String:containedtext[1024];
	BfReadByte(bf);
	BfReadByte(bf);
	BfReadString(bf, containedtext, 1024);
	
	if(StrContains(containedtext, "combat_sling")!= -1) return Plugin_Handled;

	if(StrContains(containedtext, "_expire")!= -1) return Plugin_Handled;

	if(StrContains(containedtext, "#L4D_Upgrade_")!=-1)
	{
		if(StrContains(containedtext, "description")!=-1)	return Plugin_Handled;
	}

	return Plugin_Continue;
}


public CreateParticleEffect(Float:pos[3], String:particlename[], Float:time)
{
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		
		DispatchKeyValue(particle, "effect_name", particlename);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "Start");
		CreateTimer(time, DeleteParticleEffect, particle);
	}
	else LogError("CreateParticleEffect: Could not create info_particle_system");
}

public Action:DeleteParticleEffect(Handle:timer, any:particle)
{
	if (IsValidEntity(particle))
	{
		decl String:classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false)) RemoveEdict(particle);
		else LogError("DeleteParticleEffect: Not removing entity - its not a particle '%s'", classname);
	}
}