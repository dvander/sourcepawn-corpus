#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.7"
#define PLUGIN_NAME "L4D Special Ammo"
#define CVAR_FLAGS FCVAR_NOTIFY

Handle AddUpgrade = null, RemoveUpgrade = null;
bool bMapStarted = false, bHooked = false, bCanLightTank = false, bAutoRecoilReducer = false, HasFieryAmmo[MAXPLAYERS + 1] = {false, ...}, HasHighdamageAmmo[MAXPLAYERS+1] = {false, ...}, HasDumDumAmmo[MAXPLAYERS + 1] = {false, ...};
ConVar SpecialAmmoPluginOn, SpecialAmmoAmount, KillCountLimitSetting, DumDumForce, CanLightTank, AutoRecoilReducer, hSurvivorUpgrades, Modes, MPGameMode, ModesOff, ModesTog;
int iSpecialAmmoAmount = 0, iKillCountLimitSetting = 0, SpecialAmmoUsed[MAXPLAYERS + 1] = {0, ...}, killcount[MAXPLAYERS + 1] = {0, ...};
UserMsg sayTextMsgId;
char weapon[64], class_string[64], ammotype[64], cName[64], cSetting[10], containedtext[1024], classname[64];
float fDumDumForce = 0.0;

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = " AtomicStryker ",
	description = " Dish out major damage with special ammo types ",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=98354"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test != Engine_Left4Dead)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	sayTextMsgId = GetUserMessageId("SayText");
	HookUserMessage(sayTextMsgId, SayCommandExecuted, true);

	CreateConVar("l4d_specialammo_version", PLUGIN_VERSION, " The version of L4D Special Ammo running ", CVAR_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);
	SpecialAmmoPluginOn	= CreateConVar("l4d_specialammo_on", "1", "Enable/Disable plugin. (default 1) ", CVAR_FLAGS);
	SpecialAmmoAmount	= CreateConVar("l4d_specialammo_amount", "100", " How much special ammo a player gets. (default 50) ", CVAR_FLAGS);
	CanLightTank = CreateConVar("l4d_specialammo_canlighttank", "0", " Does incendiary ammo set the Tank aflame? (default 0) ", CVAR_FLAGS);
	AutoRecoilReducer = CreateConVar("l4d_specialammo_recoilreduction", "1", " Does special ammo have less recoil? (default 1) ", CVAR_FLAGS);
	KillCountLimitSetting = CreateConVar("l4d_specialammo_killcountsetting", "50", " How much Infected a Player has to shoot to win special ammo. (default 120) ", CVAR_FLAGS);
	DumDumForce = CreateConVar("l4d_specialammo_dumdumforce", "75.0", " How powerful the DumDum Kickback is. (default 75.0) ", CVAR_FLAGS);
	Modes = CreateConVar("l4d_specialammo_modes", "", "Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	ModesOff = CreateConVar("l4d_specialammo_modes_off", "", "Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	ModesTog = CreateConVar("l4d_specialammo_tog", "0", "Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus. Add numbers together.", CVAR_FLAGS );
	
	RegAdminCmd("sm_givespecialammo", GiveSpecialAmmo, ADMFLAG_KICK, " sm_givespecialammo <1, 2 or 3> ");
	
	SpecialAmmoPluginOn.AddChangeHook(ConVarPluginOnChanged);
	SpecialAmmoAmount.AddChangeHook(ConVarsChanged);
	CanLightTank.AddChangeHook(ConVarsChanged);
	AutoRecoilReducer.AddChangeHook(ConVarsChanged);
	KillCountLimitSetting.AddChangeHook(ConVarsChanged);
	DumDumForce.AddChangeHook(ConVarsChanged);
	MPGameMode = FindConVar("mp_gamemode");
	MPGameMode.AddChangeHook(ConVarPluginOnChanged);
	ModesTog.AddChangeHook(ConVarPluginOnChanged);
	Modes.AddChangeHook(ConVarPluginOnChanged);
	ModesOff.AddChangeHook(ConVarPluginOnChanged);
	hSurvivorUpgrades = FindConVar("survivor_upgrades"); // in case the admin hasn't set this.

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

public void OnMapStart()
{
	bMapStarted = true;
}

public void OnConfigsExecuted()
{
    IsAllowed();
}

void ConVarPluginOnChanged(ConVar cvar, const char[] OldValue, const char[] NewValue)
{
    IsAllowed();
}

void ConVarsChanged(ConVar cvar, const char[] OldValue, const char[] NewValue)
{
    iSpecialAmmoAmount = SpecialAmmoAmount.IntValue;
    bCanLightTank = CanLightTank.BoolValue;
    fDumDumForce = DumDumForce.FloatValue;
    bAutoRecoilReducer = AutoRecoilReducer.BoolValue;
    iKillCountLimitSetting = KillCountLimitSetting.IntValue;
}

void IsAllowed()
{
	bool bPluginOn = SpecialAmmoPluginOn.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	if(!bHooked && bPluginOn && bAllowMode)
	{
		bHooked = true;
		ConVarsChanged(null, "", "");
		if(hSurvivorUpgrades.IntValue == 0)
		{
			hSurvivorUpgrades.SetInt(1);
		}
		HookEvent("infected_hurt", AnInfectedGotHurt);
		HookEvent("player_hurt", APlayerGotHurt);
		HookEvent("weapon_fire", WeaponFired);
		HookEvent("bullet_impact",BulletImpact);
		HookEvent("infected_death", KillCountUpgrade);
		HookEvent("round_end", RoundHasEnded);
		HookEvent("map_transition", RoundHasEnded);
		HookEvent("mission_lost", RoundHasEnded);
	}
	else if(bHooked && (!bPluginOn && bAllowMode))
	{
		bHooked = false;
		UnhookEvent("infected_hurt", AnInfectedGotHurt);
		UnhookEvent("player_hurt", APlayerGotHurt);
		UnhookEvent("weapon_fire", WeaponFired);
		UnhookEvent("bullet_impact",BulletImpact);
		UnhookEvent("infected_death", KillCountUpgrade);
		UnhookEvent("round_end", RoundHasEnded);
		UnhookEvent("map_transition", RoundHasEnded);
		UnhookEvent("mission_lost", RoundHasEnded);
	}
}

int g_iCurrentMode;
bool IsAllowedGameMode()
{
	if( MPGameMode == null )
		return false;

	int iCvarModesTog = ModesTog.IntValue;
	if( iCvarModesTog != 0 )
	{
		if(!bMapStarted)
			return false;

		g_iCurrentMode = 0;

		int entity = CreateEntityByName("info_gamemode");
		if( IsValidEntity(entity) )
		{
			DispatchSpawn(entity);
			HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
			ActivateEntity(entity);
			AcceptEntityInput(entity, "PostSpawnActivate");
			if( IsValidEntity(entity) ) // Because sometimes "PostSpawnActivate" seems to kill the ent.
				RemoveEdict(entity); // Because multiple plugins creating at once, avoid too many duplicate ents in the same frame
		}

		if( g_iCurrentMode == 0 )
			return false;

		if( !(iCvarModesTog & g_iCurrentMode) )
			return false;
	}

	char sGameModes[64], sGameMode[64];
	MPGameMode.GetString(sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	Modes.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) == -1 )
			return false;
	}

	ModesOff.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) != -1 )
			return false;
	}

	return true;
}

void OnGamemode(const char[] output, int caller, int activator, float delay)
{
	if( strcmp(output, "OnCoop") == 0 )
		g_iCurrentMode = 1;
	else if( strcmp(output, "OnSurvival") == 0 )
		g_iCurrentMode = 2;
	else if( strcmp(output, "OnVersus") == 0 )
		g_iCurrentMode = 4;
}

public void OnMapEnd()
{
	bMapStarted = false;
	PrintToServer("Map end, Special Ammo Plugin unloading.");
}

Action WeaponFired(Event event, const char[] name, bool dontBroadcast)
{
	// get client and used weapon
	int client = GetClientOfUserId(event.GetInt("userid"));
	event.GetString("weapon", weapon, 64);

	if(client && (HasFieryAmmo[client] || HasHighdamageAmmo[client] || HasDumDumAmmo[client])) // if client hasnt special ammo, we dont care
	{
		if (StrContains(weapon, "shotgun", false) == -1) SpecialAmmoUsed[client]++; // if not a shotgun, one round per shot.
		if (StrContains(weapon, "shotgun", false) != -1) SpecialAmmoUsed[client] = SpecialAmmoUsed[client] + 5; // Five times the special rounds usage for shotguns.

		int SpecialAmmoLeft = iSpecialAmmoAmount - SpecialAmmoUsed[client];
		if((SpecialAmmoLeft % 10) == 0 && SpecialAmmoLeft != 0) // Display a center HUD message every round decimal value of leftover ammo (30, 20, 10...)
			PrintCenterText(client, "Special ammo rounds left: %d", SpecialAmmoLeft);
		
		if(SpecialAmmoUsed[client] >= iSpecialAmmoAmount) CreateTimer(0.3, OutOfAmmo, client); //to remove the toys
	}
	return Plugin_Continue;
}

Action APlayerGotHurt(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(attacker > 0)
	{
		if (!HasFieryAmmo[attacker] && !HasDumDumAmmo[attacker]) return Plugin_Continue; //this function only handles special ammo
		if (GetClientTeam(attacker) == 2)
		{
			int InfClient = GetClientOfUserId(event.GetInt("userid"));
			if (GetClientTeam(InfClient) == 3)
			{
				if (HasFieryAmmo[attacker])
				{
					GetClientModel(InfClient, class_string, 64);
					if(StrContains(class_string, "hulk", false) != -1 && bCanLightTank)
					{
						int damagetype = event.GetInt("type");
						if(damagetype != 64 && damagetype != 128 && damagetype != 268435464)
						{
							IgniteEntity(InfClient, 120.0, false);
							if(StrContains(class_string, "hulk", false)!=-1) SetEntPropFloat(InfClient, Prop_Data, "m_flLaggedMovementValue", 1.3); // for a mad speed increase
						}
					}
				}

				if (HasDumDumAmmo[attacker])
				{
					float FiringAngles[3], PushforceAngles[3], force = fDumDumForce, current[3], resulting[3];
					GetClientEyeAngles(attacker, FiringAngles);
					PushforceAngles[0] = Cosine(DegToRad(FiringAngles[1])) * force;
					PushforceAngles[1] = Sine(DegToRad(FiringAngles[1])) * force;
					PushforceAngles[2] = Sine(DegToRad(FiringAngles[0])) * force;
					GetEntPropVector(InfClient, Prop_Data, "m_vecVelocity", current);
					resulting[0] = current[0] + PushforceAngles[0];
					resulting[1] = current[1] + PushforceAngles[1];
					resulting[2] = current[2] + PushforceAngles[2];
					TeleportEntity(InfClient, NULL_VECTOR, NULL_VECTOR, resulting);
				}
			}
		}
	}
	return Plugin_Continue;
}

Action AnInfectedGotHurt(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("attacker"));
	if (!HasFieryAmmo[client] && !HasDumDumAmmo[client]) return Plugin_Continue; //this function only handles special ammo
	if (GetClientTeam(client) == 2)
	{
		int infectedentity = event.GetInt("entityid");
		if (HasFieryAmmo[client])
		{
			GetEntityNetClass(infectedentity, class_string, 64); // witch has no client, so we cant use getclientmodel
			if(strcmp(class_string, "Witch") == 0) return Plugin_Continue; // no witch burning

			int damagetype = event.GetInt("type");
			if(damagetype != 64 && damagetype != 128 && damagetype != 268435464)
			{
				IgniteEntity(infectedentity, 120.0, false);
			}
		}

		if (HasDumDumAmmo[client])
		{
			float FiringAngles[3], PushforceAngles[3], force = fDumDumForce, current[3], resulting[3];
			GetClientEyeAngles(client, FiringAngles);
			PushforceAngles[0] = Cosine(DegToRad(FiringAngles[1])) * force;
			PushforceAngles[1] = Sine(DegToRad(FiringAngles[1])) * force;
			PushforceAngles[2] = Sine(DegToRad(FiringAngles[0])) * force;
			GetEntPropVector(infectedentity, Prop_Data, "m_vecVelocity", current);
			resulting[0] = current[0] + PushforceAngles[0];
			resulting[1] = current[1] + PushforceAngles[1];
			resulting[2] = current[2] + PushforceAngles[2];
			TeleportEntity(infectedentity, NULL_VECTOR, NULL_VECTOR, resulting);
		}
	}
	return Plugin_Continue;
}

Action OutOfAmmo(Handle hTimer, any client)
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
	SpecialAmmoUsed[client] = 0;
	return Plugin_Stop;
}

Action KillCountUpgrade(Event event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("attacker"));
	bool minigun = event.GetBool("minigun");
	bool blast = event.GetBool("blast");

	if (client > 0)
	{
		if (!minigun && !blast) killcount[client] += 1;
		if ((killcount[client] % 20) == 0) PrintCenterText(client, "Infected killed: %d", killcount[client]);
		if ((killcount[client] % iKillCountLimitSetting) == 0 && killcount[client] > 1)
		{
			if(IsClientInGame(client) && GetClientTeam(client) == 2)
			{
				int luck = GetRandomInt(1,3); // wee randomness!!
				switch(luck)
				{
					case 1:
					{
						HasHighdamageAmmo[client] = false;
						HasFieryAmmo[client] = true;
						HasDumDumAmmo[client] = false;
						SpecialAmmoUsed[client]=0;
						ammotype = "Incendiary";
						if(bAutoRecoilReducer) SDKCall(AddUpgrade, client, 19); //add the Recoil dampener if demanded
					}
					case 2:
					{
						HasHighdamageAmmo[client] = true;
						SDKCall(AddUpgrade, client, 21); //add Hollowpoints
						HasFieryAmmo[client] = false;
						HasDumDumAmmo[client] = false;
						SpecialAmmoUsed[client]=0;
						ammotype = "Hollowpoint";
						if(bAutoRecoilReducer) SDKCall(AddUpgrade, client, 19); //add the Recoil dampener if demanded
					}
					case 3:
					{
						HasHighdamageAmmo[client] = false;
						HasFieryAmmo[client] = false;
						HasDumDumAmmo[client] = true;				
						SpecialAmmoUsed[client]=0;
						ammotype = "DumDum";
						if(bAutoRecoilReducer) SDKCall(AddUpgrade, client, 19); //add the Recoil dampener if demanded
					}
				}
				GetClientName(client, cName, 64);
				PrintToChatAll("\x04%s\x01 won %s ammo for killing %d Infected!", cName, ammotype, killcount[client]);
			}
		}
	}
	return Plugin_Continue;
}

void BulletImpact(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	float Origin[3], Direction[3];
	Origin[0] = GetEventFloat(event,"x");
	Origin[1] = GetEventFloat(event,"y");
	Origin[2] = GetEventFloat(event,"z");

	if(HasHighdamageAmmo[client] || HasDumDumAmmo[client])
	{
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

Action RoundHasEnded(Event event, const char[] name, bool dontBroadcast)
{
	// One Function to control them all, one function to find them,
	// one function to find them all and in the dark null reset them
	// in the land of Sourcepawn where the memoryleaks lie
	for(int i = 1; i <= MaxClients; ++i)
	{
		HasFieryAmmo[i] = false;
		HasHighdamageAmmo[i] = false;
		HasDumDumAmmo[i] = false;
		killcount[i] = 0;
		if(IsClientInGame(i))
		{
			SDKCall(RemoveUpgrade, i, 21);
			SDKCall(RemoveUpgrade, i, 19);
		}
	}
	return Plugin_Continue;
}

Action GiveSpecialAmmo(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_givespecialammo <1, 2 or 3>");
		return Plugin_Handled;
	}

	GetCmdArg(1, cSetting, sizeof(cSetting));

	switch (StringToInt(cSetting))
	{
		case 1:
		{
			HasHighdamageAmmo[client] = false;
			HasFieryAmmo[client] = true;
			HasDumDumAmmo[client] = false;
			SpecialAmmoUsed[client]=0;
			ammotype = "Incendiary";
			if(bAutoRecoilReducer) SDKCall(AddUpgrade, client, 19); //add the Recoil dampener if demanded
		}
		case 2:
		{
			HasHighdamageAmmo[client] = true;
			SDKCall(AddUpgrade, client, 21); //add Hollowpoints
			HasFieryAmmo[client] = false;
			HasDumDumAmmo[client] = false;
			SpecialAmmoUsed[client]=0;
			ammotype = "Hollowpoint";
			if(bAutoRecoilReducer) SDKCall(AddUpgrade, client, 19); //add the Recoil dampener if demanded
		}
		case 3:
		{
			HasHighdamageAmmo[client] = false;
			HasFieryAmmo[client] = false;
			HasDumDumAmmo[client] = true;				
			SpecialAmmoUsed[client] = 0;
			ammotype = "DumDum";
			if(bAutoRecoilReducer) SDKCall(AddUpgrade, client, 19); //add the Recoil dampener if demanded
		}
	}

	GetClientName(client, cName, 64);
	PrintToChatAll("\x04%s\x01 cheated himself some  %s ammo", cName, ammotype, killcount[client]);
	return Plugin_Handled;
}

Action SayCommandExecuted(UserMsg msg_id, Handle bf, const int[] players, int playersNum, bool reliable, bool init)
{
	BfReadByte(bf);
	BfReadByte(bf);
	BfReadString(bf, containedtext, 1024);
	
	if(StrContains(containedtext, "combat_sling") != -1) return Plugin_Handled;
	if(StrContains(containedtext, "_expire") != -1) return Plugin_Handled;
	if(StrContains(containedtext, "#L4D_Upgrade_") != -1)
	{
		if(StrContains(containedtext, "description")!=-1)	return Plugin_Handled;
	}

	return Plugin_Continue;
}

void CreateParticleEffect(float pos[3], char[] particlename, float fTime)
{
	int particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", particlename);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "Start");
		CreateTimer(fTime, DeleteParticleEffect, particle);
	}
	else LogError("CreateParticleEffect: Could not create info_particle_system");
}

Action DeleteParticleEffect(Handle timer, any particle)
{
	if (IsValidEntity(particle))
	{
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false)) RemoveEdict(particle);
		else LogError("DeleteParticleEffect: Not removing entity - its not a particle '%s'", classname);
	}
	return Plugin_Stop;
}
