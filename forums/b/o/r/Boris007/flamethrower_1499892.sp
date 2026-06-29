#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>


new Float:g_vecHit[3]



new Float:g_Fuel[65]
new Float:g_Fuel_time[65]
new Handle:g_timer_FuelGauge[65]
new Float:g_max_fuel

new g_en_FlashLight[65]

new String:g_sPrev_Weapon[65][50]
new g_iPrev_Weapon_Ammo[65]


new g_iLightIndex[65]

new g_mountedgun[65]

new g_ind_Thrower[65]

new g_DisableFlame[65]

new g_hOwnerEntity[65]


new g_ent_PilotLight[65]
new Handle:g_timer_PLsfx[65]
new g_act_PilotLight[65]

new g_Thrower_inhands[65]

new g_eq_Thrower[65]

new Float:sfx_pl_offset[3]



new g_act_Thrower[65]
new g_ent_Thrower[65]
new Handle:g_timer_Thrower[65]
new Handle:g_timer_Throwersfx[65]




public Plugin:myinfo =
{
	name = "Flamethrower V1",
	author = "Stay Puft aka Boris007",
	description = "This plugin belongs with the custom flamethrower model",
	version = "1.0.0.0",
	url = "http://www.sourcemod.net/"
};




public Action:Command_debug(client, args)
{
	/*decl String:ent[12]
	decl String:alpha[12]
	
	GetCmdArg(1, ent, 64)
	GetCmdArg(2, alpha, 64)
	SetAlpha(StringToInt(ent),StringToInt(alpha))*/
	
	//PrintToChatAll("g_ent_PilotLight[i] = %i", g_ent_PilotLight[client])
	//PrintToChatAll("g_ent_Thrower[i] = %i", g_ent_Thrower[client])
	//PrintToChatAll("g_timer_Thrower[i] = %i", g_timer_Thrower[client])
	//PrintToChatAll("g_timer_Throwersfx[i] = %i", g_timer_Throwersfx[client])
	//PrintToChatAll("g_timer_PLsfx[i] = %i", g_timer_PLsfx[client])
	//PrintToChatAll("g_timer_FuelGauge[i] = %i", g_timer_FuelGauge[client])
	//PrintToChatAll("g_act_Thrower[i] = %i", g_act_Thrower[client])
	//PrintToChatAll("g_act_PilotLight[i] = %i", g_act_PilotLight[client])
	//PrintToChatAll("g_eq_Thrower[i] = %i", g_eq_Thrower[client])
	//PrintToChatAll("g_Fuel[i]= %f", g_Fuel[client])
	//PrintToChatAll("g_Fuel_time[i]= %f", g_Fuel_time[client])
	//PrintToChatAll("g_Thrower_inhands[i]= %i", g_Thrower_inhands[client])
	//PrintToChatAll("g_ind_Thrower[i]= %i",g_ind_Thrower[client])
	//PrintToChatAll("g_DisableFlame[i] = %i",g_DisableFlame[client])
	//PrintToChatAll("g_en_FlashLight[i] = %i",g_en_FlashLight[client])
	//PrintToChatAll("g_sPrev_Weapon[i] = %s",g_sPrev_Weapon[client])
	//PrintToChatAll("g_iPrev_Weapon_Ammo[i]= %i",g_iPrev_Weapon_Ammo[client])
	//PrintToChatAll("g_hOwnerEntity[i]= %i",g_hOwnerEntity[client])
	return Plugin_Continue
}

public OnPluginStart()
{
	// Perform one-time startup tasks ...
	RegAdminCmd("sm_ftdebug", Command_debug, ADMFLAG_SLAY, "sm_vis <#userid|name> [0/1]")
	
	
	g_max_fuel=60.000000
	
	sfx_pl_offset[0]=0.0
	sfx_pl_offset[1]=5.0
	sfx_pl_offset[2]=40.0
	
	/*g_vecViewOffset[0]=20.000000
	g_vecViewOffset[1]=15.000000
	g_vecViewOffset[2]=34.000000*/
	
	
	/*hGameConf = LoadGameConfigFile("sdktools.games/plugin.l4d2funcs");

	StartPrepSDKCall(SDKCall_Player);
	PrintToServer("blarg: %i",PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "SelectItem"))
	//PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	hSelectItem = EndPrepSDKCall();*/
	
	/*hGameConf = LoadGameConfigFile("plugin.l4d2funcs");

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "SetViewOffset");
	
	hSetViewOffset = EndPrepSDKCall();*/
	
	//SetCommandFlags("thirdpersonshoulder", (GetCommandFlags("thirdpersonshoulder") & ~FCVAR_SPONLY))
	//HookEvent("weapon_fire", Event_weapon_fire, EventHookMode_Pre)
	//HookEvent("player_hurt", Event_playerhurt, EventHookMode_Pre)
	//HookEvent("bullet_impact", Event_bulletimpact, EventHookMode_Pre)
	HookEvent("player_death", Event_playerdead, EventHookMode_Pre)
	//HookEvent("charger_carry_start", Event_carrystart, EventHookMode_Post)
	//HookEvent("charger_carry_end", Event_carryend, EventHookMode_Post)
	HookEvent("charger_pummel_start", Event_pummelstart, EventHookMode_Post)
	HookEvent("charger_pummel_end", Event_pummelend, EventHookMode_Post)
	HookEvent("jockey_ride", Event_jockeyride, EventHookMode_Post)
	HookEvent("jockey_ride_end", Event_jockeyrideend, EventHookMode_Post)
	HookEvent("pounce_end", Event_pounceend, EventHookMode_Post)
	HookEvent("lunge_pounce", Event_lungepounce, EventHookMode_Post)
	//HookEvent("player_incapacitated", Event_incap, EventHookMode_Post)
	HookEvent("tongue_grab", Event_tonguegrab, EventHookMode_Post)
	HookEvent("choke_stopped", Event_chokestop, EventHookMode_Post)
	HookEvent("mounted_gun_start", Event_mountedgun, EventHookMode_Pre)
	//HookEvent("player_use", Event_playeruse)
}

public Event_playeruse(Handle:event, const String:name[], bool:dontBroadcast)
{
	new temp=GetClientOfUserId(GetEventInt(event, "userid"))
	if(temp!=0){
		if(IsClientInGame(temp)){
			//PrintToChatAll("Player use!")
			if(g_Thrower_inhands[temp]==1 && g_mountedgun[temp]==1){
				ActivatePilotLight(temp)
				g_DisableFlame[temp]=0
				SetThirdPerson(temp)
				g_mountedgun[temp]=0
			}

		}
	}
}

public Event_mountedgun(Handle:event, const String:name[], bool:dontBroadcast)
{
	new temp=GetClientOfUserId(GetEventInt(event, "userid"))
	if(temp!=0){
		if(IsClientInGame(temp)){
			if(g_Thrower_inhands[temp]==1){
				DeactivatePilotLight(temp)
				SetFirstPerson(temp)
				g_Thrower_inhands[temp]=0		
				
				new weapon_ind=GetPlayerWeaponSlot(temp,1)
				Client_GiveWeapon(temp,"weapon_pistol") 
				
				AcceptEntityInput(weapon_ind, "Kill")
			}
		}
	}
}


public Event_incap(Handle:event, const String:name[], bool:dontBroadcast)
{
	new temp=GetClientOfUserId(GetEventInt(event, "victim"))
	if(temp!=0){
		if(IsClientInGame(temp)){
			//PrintToChatAll("Client %i incapped", temp)
			g_DisableFlame[temp]=1
		}
	}
}

public Event_pounceend(Handle:event, const String:name[], bool:dontBroadcast)
{
	new temp=GetClientOfUserId(GetEventInt(event, "victim"))
	if(temp!=0){
		if(IsClientInGame(temp)){
			//PrintToChatAll("Pounce over for Client %i", temp)
			g_DisableFlame[temp]=0
			if(g_Thrower_inhands[temp]==1){
				ActivatePilotLight(temp)
				
				SetThirdPerson(temp)
			}
		}
	}
}

public Event_chokestop(Handle:event, const String:name[], bool:dontBroadcast)
{
	new temp=GetClientOfUserId(GetEventInt(event, "victim"))
	if(temp!=0){
		if(IsClientInGame(temp)){
			//PrintToChatAll("Tongue released for Client %i", temp)
			g_DisableFlame[temp]=0
			if(g_Thrower_inhands[temp]==1){
				ActivatePilotLight(temp)
				
				SetThirdPerson(temp)
			}
		}
	}
}

public Event_tonguegrab(Handle:event, const String:name[], bool:dontBroadcast)
{
	new temp=GetClientOfUserId(GetEventInt(event, "victim"))
	if(temp!=0){
		if(IsClientInGame(temp)){
			if(g_Thrower_inhands[temp]==1){
				KillThrower(temp)
				//SetFirstPerson(temp)
				g_Thrower_inhands[temp]=0		
				
				new weapon_ind=GetPlayerWeaponSlot(temp,1)
				Client_GiveWeapon(temp,"weapon_pistol") 
				
				AcceptEntityInput(weapon_ind, "Kill")
			}
		}
	}
}

public Event_lungepounce(Handle:event, const String:name[], bool:dontBroadcast)
{
	new temp=GetClientOfUserId(GetEventInt(event, "victim"))
	if(temp!=0){
		if(IsClientInGame(temp)){
			//PrintToChatAll("Lunged on Client %i", temp)
			KillThrower(temp)
		}
	}
}

public Event_jockeyride(Handle:event, const String:name[], bool:dontBroadcast)
{
	new temp=GetClientOfUserId(GetEventInt(event, "victim"))
	if(temp!=0){
		if(IsClientInGame(temp)){
			//PrintToChatAll("Jockey start for Client %i", temp)
			KillThrower(temp)
		}
	}
}

public Event_jockeyrideend(Handle:event, const String:name[], bool:dontBroadcast)
{
	new temp=GetClientOfUserId(GetEventInt(event, "victim"))
	if(temp!=0){
		if(IsClientInGame(temp)){
			//PrintToChatAll("Jockey ride over for Client %i", temp)
			g_DisableFlame[temp]=0
			if(g_Thrower_inhands[temp]==1){
				ActivatePilotLight(temp)
				
				SetThirdPerson(temp)
			}
		}
	}
}

public Event_carrystart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new temp=GetClientOfUserId(GetEventInt(event, "victim"))
	if(temp!=0){
		if(IsClientInGame(temp)){
			//PrintToChatAll("Carry started for Client %i", temp)
			KillThrower(temp)
		}
	}
}

public Event_carryend(Handle:event, const String:name[], bool:dontBroadcast)
{
	new temp=GetClientOfUserId(GetEventInt(event, "victim"))
	if(temp!=0){
		if(IsClientInGame(temp)){
			//PrintToChatAll("Carry ended for Client %i", temp)
			g_DisableFlame[temp]=0
			if(g_Thrower_inhands[temp]==1){
				ActivatePilotLight(temp)
				
				SetThirdPerson(temp)
			}
		}
	}
}

public Event_pummelstart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new temp=GetClientOfUserId(GetEventInt(event, "victim"))
	if(temp!=0){
		if(IsClientInGame(temp)){
			//PrintToChatAll("Pummel started for Client %i", temp)
			KillThrower(temp)
		}
	}
}

public Event_pummelend(Handle:event, const String:name[], bool:dontBroadcast)
{
	new temp=GetClientOfUserId(GetEventInt(event, "victim"))
	if(temp!=0){
		if(IsClientInGame(temp)){
			//PrintToChatAll("Pummel over for Client %i", temp)
			g_DisableFlame[temp]=0
			if(g_Thrower_inhands[temp]==1){
				ActivatePilotLight(temp)
				
				SetThirdPerson(temp)
			}
		}
	}
}

public Event_playerdead(Handle:event, const String:name[], bool:dontBroadcast)
{
	new temp=GetClientOfUserId(GetEventInt(event, "userid"))
	if(temp!=0){
		if(IsClientInGame(temp)){
			//PrintToChatAll("Client %i dead", temp)
			g_eq_Thrower[temp]=0
			KillThrower(temp)
		}
	}
}

public KillThrower(client)
{
	//PrintToChatAll("THROWER DISABLED")
	if(g_act_PilotLight[client]==1){
		DeactivatePilotLight(client)	
		
	}
	if(g_act_Thrower[client]==1){
		//PrintToChatAll("Thrower timer init")
		g_timer_Thrower[client]=CreateTimer(0.1, Timer_Thrower, client)		
		
	}
	SetFirstPerson(client)
	g_DisableFlame[client]=1
}

public OnMapStart()
{
	
	PrecacheSound("pilotlight.mp3")
	PrecacheSound("fire.mp3")
	


	
}

public OnClientDisconnect(client)
{
	if(g_timer_Thrower[client] != INVALID_HANDLE){
		CloseHandle(g_timer_Thrower[client])
	}
	if(g_timer_Throwersfx[client] != INVALID_HANDLE){		
		CloseHandle(g_timer_Throwersfx[client])
	}
	if(g_timer_PLsfx[client] != INVALID_HANDLE){
		CloseHandle(g_timer_PLsfx[client])
	}
	if(g_timer_FuelGauge[client] != INVALID_HANDLE){
		CloseHandle(g_timer_FuelGauge[client])
	}
	
	//DeleteLight(client)
}

public OnClientPutInServer(client)
{
	
    
	SDKHook(client, SDKHook_PreThink, OnPreThink)
	SDKHook(client, SDKHook_WeaponSwitchPost, WeaponEquipped)
	//SDKHook(client, SDKHook_WeaponEquip, Equip)
	//AddNormalSoundHook(NormalSHook:HookSound_Callback)
	//AddAmbientSoundHook(AmbientSHook:HookAmbient_Callback)
	//SDKHook(client, SDKHook_SelectItem, SelectItem)
	
	g_ent_PilotLight[client] = 0
	g_ent_Thrower[client] = 0
	g_timer_Thrower[client] = INVALID_HANDLE	
	g_timer_Throwersfx[client] = INVALID_HANDLE			
	g_timer_PLsfx[client] = INVALID_HANDLE
	g_timer_FuelGauge[client] = INVALID_HANDLE
	g_hOwnerEntity[client] = 0
	g_act_Thrower[client] = 0
	g_act_PilotLight[client] = 0
	g_eq_Thrower[client] = 0
	g_Thrower_inhands[client] = 0
	g_Fuel[client]=60.000000
	g_Fuel_time[client]=0.000000
	g_DisableFlame[client]=0
	g_ind_Thrower[client]=0
	g_mountedgun[client]=0
	g_iLightIndex[client]=-1
	
	//CreateLight(client)
}

public Action:Equip(client, weapon)
{
	//PrintToChatAll("EQUIPPED!")
	if(g_act_Thrower[client]==1 || g_act_PilotLight[client]==1)
	{
		//PrintToChatAll("BLOCKED?")
		return Plugin_Handled
	}
	return Plugin_Continue
}

public WeaponEquipped(client, weapon)
{
	new weapon_ind=-1
	new String:weapon_s[50]
	new String:client_weapon_s[50]
	
	////PrintToChatAll("Test")
	
	GetClientWeapon(client,client_weapon_s,sizeof(client_weapon_s))
	weapon_ind=GetPlayerWeaponSlot(client,1)
	if(IsValidEntity(weapon_ind)){
		GetEntPropString(weapon_ind, Prop_Data, "m_iClassname", weapon_s, sizeof(weapon_s))
		if(!strcmp("weapon_melee", weapon_s, false) && !strcmp("weapon_melee", client_weapon_s, false))
		{
			GetEntPropString(weapon_ind, Prop_Data, "m_strMapSetScriptName", weapon_s, sizeof(weapon_s))
			if(!strcmp("thrower", weapon_s, false)){
				
				if(g_act_PilotLight[client]==0){
					
					if(g_eq_Thrower[client]==0){
						g_eq_Thrower[client]=1
						g_Fuel[client]=g_max_fuel
					}
					g_ind_Thrower[client]=weapon_ind
					g_Thrower_inhands[client]=1
					g_DisableFlame[client]=0
					//PrintToChatAll("Weapon edict flags: %i",GetEdictFlags(weapon_ind))
					
					ActivatePilotLight(client)
					//PrintToChatAll("Weapon index: %i",weapon_ind)					
					
					//CreateLight(client)
					CreateFlashLight(client)
					g_hOwnerEntity[client] = GetEntProp(weapon_ind,Prop_Send,"m_hOwnerEntity")
					SetThirdPerson(client)
					
					
				}
				
				
			} else if(g_act_PilotLight[client]==1){
				DeactivatePilotLight(client)
				g_Thrower_inhands[client]=0
				SetFirstPerson(client)
				
				
			} else if(g_eq_Thrower[client]==1){
				PrintHintText(client, "Switch to secondary weapon and press zoom to equip Flamethrower")
			}
		}else if(g_act_PilotLight[client]==1){
			//DeactivatePilotLight(client)
			KillThrower(client)
			g_Thrower_inhands[client]=0
			SetFirstPerson(client)
			
		}else if(g_eq_Thrower[client]==1){
			PrintHintText(client, "Switch to secondary weapon and press zoom to equip Flamethrower")
		}
	}
}

public CreateFlashLight(client)
{
	if(g_en_FlashLight[client]==1 && g_Thrower_inhands[client]==1){
		/*new String:sWeapon[32];
		GetEdictClassname(GetPlayerWeaponSlot(client, 1), sWeapon, 32);
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, 1));*/
		new String:targetName[36];
		Format(targetName, sizeof(targetName), "flashlight%d", client);
		SetCommandFlags("create_flashlight", GetCommandFlags("create_flashlight") & ~FCVAR_CHEAT);
		FakeClientCommand(client, "create_flashlight %s 1", targetName);
		SetCommandFlags("create_flashlight", GetCommandFlags("create_flashlight") | FCVAR_CHEAT);
		CreateTimer(0.1, Timer_FlashLight, client)
	}
}

public CreateLight(client)
{
	if(g_en_FlashLight[client]==1 && g_Thrower_inhands[client]==1){

		// Declares
		new iEnt
		//decl String:sTemp[16];
		if(IsValidEntity(g_iLightIndex[client])==false){
			iEnt = CreateEntityByName("env_projectedtexture");
			
			if( iEnt == -1)
			{
				LogError("Failed to create 'env_projectedtexture'");
			}
			else
			{
				new String:targetName[36];
				new Float:vecClientEyePos[3], Float:vecClientEyeAng[3]
				Format(targetName, sizeof(targetName), "dynlight%d", client);
				GetClientEyePosition(client, vecClientEyePos) // Get the position of the player's eyes
				GetClientEyeAngles(client, vecClientEyeAng) // Get the angle the player is looking
				TeleportEntity(iEnt, vecClientEyePos, vecClientEyeAng, NULL_VECTOR)
				DispatchKeyValue(iEnt, "targetname", targetName);
							
				DispatchSpawn(iEnt);
				
				ActivateEntity(iEnt)
				
				AcceptEntityInput(iEnt, "TurnOn");				
				
				g_iLightIndex[client]=iEnt
				CreateTimer(0.1, Timer_FlashLight, client, TIMER_REPEAT)
				//PrintToChatAll("Light Index: %i Loc: %f %f %f Ang: %f %f %f",g_iLightIndex[client],vecClientEyePos[0],vecClientEyePos[1],vecClientEyePos[2],vecClientEyeAng[0],vecClientEyeAng[1],vecClientEyeAng[2])
			}
		}
	}
}

public Action:Timer_FlashLight(Handle:timer, any:client)
{
	new String:targetName[36];
	Format(targetName, sizeof(targetName), "flashlight%d", client);
	
	new ent
	ent=FindEntityByTargetname("env_projectedtexture",targetName)
	if(ent!=-1){
		AcceptEntityInput(ent,"Kill")
	}
	CreateFlashLight(client)
}

public FindEntityByTargetname(String:Classname[],String:Targetname[])
{
	new entfound=0, ent=-1, String:sTarget[36]
	while(entfound==0){
		////PrintToChatAll("Looking for ent with class: %s and name: %s",Classname,Targetname)
		ent=FindEntityByClassname(ent,Classname)
		////PrintToChatAll("Found ent: %i",ent)
		////PrintToChatAll("Edict? %b Networkable? %b", IsEntNetworkable(ent),IsValidEdict(ent))
		if(ent==-1){
			entfound=-1
		}
		else{
		//DispatchKeyValue(ent, "targetname", Targetname);
		GetEntPropString(ent, Prop_Data, "m_iName", sTarget, sizeof(sTarget))
		////PrintToChatAll("Target: %s",sTarget)
		if(!strcmp(sTarget,Targetname,false) || ent==-1){
			entfound=1
		}
		}
	}
	return ent
}

/*public MakeLightDynamic(Float:fOrigin[3], Float:fAngles[3], client, const String:sAttachment[])
{
	new iEnt = CreateEntityByName("light_dynamic");
	if( iEnt == -1)
	{
		LogError("Failed to create 'light_dynamic'");
		return 0;
	}

	

	decl String:sTemp[16];
	Format(sTemp, sizeof(sTemp), "%s 255", "255 255 255");
	DispatchKeyValue(iEnt, "_light", "72 205 255 50");
	DispatchKeyValue(iEnt, "brightness", "0");
	DispatchKeyValueFloat(iEnt, "spotlight_radius", 32.0);
	DispatchKeyValueFloat(iEnt, "distance", 255.0);
	//DispatchKeyValue(iEnt, "style", sStyle);
	DispatchSpawn(iEnt);
	AcceptEntityInput(iEnt, "TurnOn");

	// Attach to survivor
	new len = strlen(sAttachment);
	if( client )
	{
		if( len == 0 )
		Format(sTemp, sizeof(sTemp), "FLRG%i%i", iEnt, client);
		else
		Format(sTemp, sizeof(sTemp), "FLRL%i%i", iEnt, client);
		DispatchKeyValue(iEnt, "targetname", sTemp);
		ActivateEntity(iEnt)			
		SetVariantString("!activator");
		AcceptEntityInput(iEnt, "SetParent", client, iEnt, 0);

		if( len != 0 )
		{
			SetVariantString("grenade");
			AcceptEntityInput(iEnt, "SetParentAttachment",client, iEnt, 0)
		}
	}

	TeleportEntity(iEnt, fOrigin, fAngles, NULL_VECTOR);
	return iEnt;
}*/

public SetThirdPerson(client)
{
	SetEntProp(client, Prop_Send, "m_hViewEntity",g_hOwnerEntity[client])
	SetEntProp(client, Prop_Send, "m_iObserverMode", 1)
	
}

public ActivatePilotLight(client)
{
	////////////////////////////////////////////////////////////////////
	if(g_ent_PilotLight[client]==0){
		decl String:ModelName[128]
		GetEntPropString(client, Prop_Data, "m_ModelName", ModelName, sizeof(ModelName))
		
		g_ent_PilotLight[client] = CreateEntityByName("info_particle_system");
		
		DispatchKeyValue(g_ent_PilotLight[client], "targetname", "particle_PL");
		
		if(!strcmp("models/survivors/survivor_manager.mdl",ModelName,false)){
			DispatchKeyValue(g_ent_PilotLight[client], "effect_name", "pilot_light_l");
		}else if(!strcmp("models/survivors/survivor_teenangst.mdl",ModelName,false)){
			DispatchKeyValue(g_ent_PilotLight[client], "effect_name", "pilot_light_z");
		}else{		
			DispatchKeyValue(g_ent_PilotLight[client], "effect_name", "pilot_light");
		}
		
		DispatchSpawn(g_ent_PilotLight[client]);
		
		ActivateEntity(g_ent_PilotLight[client])
		
		
		
		
		SetVariantString("!activator")
		AcceptEntityInput(g_ent_PilotLight[client], "SetParent", client, g_ent_PilotLight[client], 0)
		
		//PrintToChatAll("Model name: %s",ModelName)
		
		
		if(!strcmp("models/survivors/survivor_manager.mdl",ModelName,false)){
			SetVariantString("muzzle_flash")
		}else if(!strcmp("models/survivors/survivor_teenangst.mdl",ModelName,false)){
			SetVariantString("weaponbone")
		}else{
			SetVariantString("weapon_bone")
		}
		AcceptEntityInput(g_ent_PilotLight[client], "SetParentAttachment", client, g_ent_PilotLight[client], 0)
		
		/*SetVariantString("weapon_bone")
		AcceptEntityInput(g_ent_PilotLight[client], "SetParentAttachmentMaintainOffset", client, g_ent_PilotLight[client], 0)*/
		AcceptEntityInput(g_ent_PilotLight[client], "Start")
		g_act_PilotLight[client] = 1
		///////////////////////////////////////////////////////////////////
		////////////////////////////////////////////////////////////////////
		
		//GetClientEyePosition(client, sfx_pl_offset)
		if(g_timer_PLsfx[client]==INVALID_HANDLE){
			EmitAmbientSound("pilotlight.mp3",sfx_pl_offset,g_ent_PilotLight[client])
			
			g_timer_PLsfx[client]=CreateTimer(15.0, Timer_PLsfx, client, TIMER_REPEAT)
		}
		///////////////////////////////////////////////////////////////////
		//PrintToChatAll("Pilot Light generated")
	}
}

public DeactivatePilotLight(client)
{
	g_act_PilotLight[client]=0
	StopSound(g_ent_PilotLight[client], SNDCHAN_STATIC, "pilotlight.mp3")
	AcceptEntityInput(g_ent_PilotLight[client], "Kill")
	//PrintToChatAll("Pilot Light killed")
	
	CloseHandle(g_timer_PLsfx[client])
	g_ent_PilotLight[client]=0
	
	g_timer_PLsfx[client]=INVALID_HANDLE
	
}



public SetAlpha(target, alpha)
{
	SetEntityRenderMode(target, RENDER_TRANSCOLOR)
	SetEntityRenderColor(target, 255, 255, 255, alpha)
}



public OnPreThink(client)
{
	new iButtons = GetClientButtons(client);
	
	
	if(iButtons & IN_ATTACK)
	{
		
		new weapon_ind=-1
		new String:weapon_s[50]
		new String:client_weapon_s[50]
		
		GetClientWeapon(client,client_weapon_s,sizeof(client_weapon_s))
		weapon_ind=GetPlayerWeaponSlot(client,1)
		if(IsValidEntity(weapon_ind) && g_DisableFlame[client]==0){
			GetEntPropString(weapon_ind, Prop_Data, "m_iClassname", weapon_s, sizeof(weapon_s))
			if(!strcmp("weapon_melee", weapon_s, false) && !strcmp("weapon_melee", client_weapon_s, false))
			{
				GetEntPropString(weapon_ind, Prop_Data, "m_strMapSetScriptName", weapon_s, sizeof(weapon_s))
				if(!strcmp("thrower", weapon_s, false)){
					if(g_act_Thrower[client]==0){
						decl String:ModelName[128]
						GetEntPropString(client, Prop_Data, "m_ModelName", ModelName, sizeof(ModelName))
					
						g_ent_Thrower[client] = CreateEntityByName("info_particle_system")
						DispatchKeyValue(g_ent_Thrower[client], "targetname", "particle_Thrower")
						if(!strcmp("models/survivors/survivor_manager.mdl",ModelName,false)){
							DispatchKeyValue(g_ent_Thrower[client], "effect_name", "flamethrower_l")
						}else if(!strcmp("models/survivors/survivor_teenangst.mdl",ModelName,false)){
							DispatchKeyValue(g_ent_Thrower[client], "effect_name", "flamethrower_z")
						}else{
							DispatchKeyValue(g_ent_Thrower[client], "effect_name", "flamethrower")
						}
						DispatchSpawn(g_ent_Thrower[client])
						ActivateEntity(g_ent_Thrower[client])
						SetVariantString("!activator")
						AcceptEntityInput(g_ent_Thrower[client], "SetParent", client, g_ent_Thrower[client], 0)
						if(!strcmp("models/survivors/survivor_manager.mdl",ModelName,false)){
							SetVariantString("muzzle_flash")
						}else if(!strcmp("models/survivors/survivor_teenangst.mdl",ModelName,false)){
							SetVariantString("weaponbone")
						}else{
							SetVariantString("weapon_bone")
						}
						AcceptEntityInput(g_ent_Thrower[client], "SetParentAttachment", client, g_ent_Thrower[client], 0)
						//SetVariantString("weapon_bone")
						//AcceptEntityInput(g_ent_Thrower[client], "SetParentAttachmentMaintainOffset", client, g_ent_Thrower[client], 0)
						AcceptEntityInput(g_ent_Thrower[client], "Start")
						g_act_Thrower[client]=1
						//PrintToChatAll("Thrower active")
						DeactivatePilotLight(client)
						
						EmitAmbientSound("fire.mp3",sfx_pl_offset,g_ent_Thrower[client])
						g_timer_Throwersfx[client]=CreateTimer(20.0, Timer_Throwersfx, client, TIMER_REPEAT)
						
						g_timer_FuelGauge[client]=CreateTimer(0.6, Timer_FuelGauge, client, TIMER_REPEAT)
						
						g_Fuel_time[client]=GetTickedTime()
					}
					
					
					TraceSomething(client)
					if(g_timer_Thrower[client]!=INVALID_HANDLE){
						KillTimer(g_timer_Thrower[client])
						g_timer_Thrower[client]=INVALID_HANDLE
						//PrintToChatAll("Thrower timer handle closed")
					}
				} else if(g_act_Thrower[client]==1 && g_timer_Thrower[client]==INVALID_HANDLE){
					//PrintToChatAll("Thrower timer init")
					g_timer_Thrower[client]=CreateTimer(0.1, Timer_Thrower, client)
				}
			} else if(g_act_Thrower[client]==1 && g_timer_Thrower[client]==INVALID_HANDLE){
				//PrintToChatAll("Thrower timer init")
				g_timer_Thrower[client]=CreateTimer(0.1, Timer_Thrower, client)
			}
		}
	} else if(g_act_Thrower[client]==1 && g_timer_Thrower[client]==INVALID_HANDLE){
		//PrintToChatAll("Thrower timer init")
		g_timer_Thrower[client]=CreateTimer(0.1, Timer_Thrower, client)
		
	} else if((iButtons & IN_RELOAD) && g_act_PilotLight[client]==1  && g_Thrower_inhands[client]==1){
		
		HolsterThrower(client)
		
		
		
		/*new String:sWeapon[32];
		GetEdictClassname(GetPlayerWeaponSlot(client, 1), sWeapon, 32);
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, 1));
		SetCommandFlags("give", GetCommandFlags("give") & ~FCVAR_CHEAT);
		FakeClientCommand(client, "give pistol", sWeapon);
		SetCommandFlags("give", GetCommandFlags("give") | FCVAR_CHEAT);		*/

	} else if((iButtons & IN_ZOOM) && g_eq_Thrower[client]==1 && g_Thrower_inhands[client]==0){
		
		new String:cl_weapon_s[50]	
		new String:weapon_s[50]
		GetClientWeapon(client,cl_weapon_s,sizeof(cl_weapon_s))
		new weapon_ind=GetPlayerWeaponSlot(client,1)
		GetEntPropString(weapon_ind, Prop_Data, "m_iClassname", weapon_s, sizeof(weapon_s))
		//PrintToChatAll("Equipped: %s", cl_weapon_s)
		if(!strcmp(weapon_s, cl_weapon_s, false))
		{
			if(g_DisableFlame[client]==0){
				
				
				
				new String:sWeapon[32];
				GetEdictClassname(GetPlayerWeaponSlot(client, 1), sWeapon, 32);
				RemovePlayerItem(client, GetPlayerWeaponSlot(client, 1));
				SetCommandFlags("give", GetCommandFlags("give") & ~FCVAR_CHEAT);
				FakeClientCommand(client, "give thrower", sWeapon);
				SetCommandFlags("give", GetCommandFlags("give") | FCVAR_CHEAT);
				
				
				//Client_EquipWeapon(client,g_ind_Thrower[client],true)
				//Client_SetActiveWeapon(client,g_ind_Thrower[client])
				/*GetEdictClassname(g_ind_Thrower[client], sWeapon, 32)
			//PrintToChatAll("sWeapon: %s", sWeapon)
			GivePlayerItem(client,sWeapon)*/
				
				
				if(!strcmp("weapon_chainsaw",cl_weapon_s,false))
				{
					g_iPrev_Weapon_Ammo[client]=GetEntProp(weapon_ind,Prop_Data,"m_iClip1")
					g_sPrev_Weapon[client]="weapon_chainsaw"
				}else{
					new String:sTemp[50]
					if(!strcmp("weapon_melee",cl_weapon_s,false)){
					GetEntPropString(weapon_ind, Prop_Data, "m_strMapSetScriptName", sTemp, sizeof(sTemp))
					}
					g_sPrev_Weapon[client]=sTemp
					g_iPrev_Weapon_Ammo[client]=0
				}
				AcceptEntityInput(weapon_ind,"Kill")
				g_Thrower_inhands[client]=1
				//PrintToChatAll("Previous weapon: %s with ammo: %i",g_sPrev_Weapon[client],g_iPrev_Weapon_Ammo[client])
			}
		}
	}
}

public HolsterThrower(client)
{
		new weapon_ind
		KillThrower(client)
		g_DisableFlame[client]=0
		SetFirstPerson(client)
		g_Thrower_inhands[client]=0

		weapon_ind=GetPlayerWeaponSlot(client,1)
		if(!strcmp("weapon_chainsaw",g_sPrev_Weapon[client],false)){
			new temp_weapon=Client_GiveWeapon(client,"weapon_chainsaw")
			
			SetEntProp(temp_weapon,Prop_Data,"m_iClip1",g_iPrev_Weapon_Ammo[client])
		}else if(!strcmp("",g_sPrev_Weapon[client],false)){
			
			Client_GiveWeapon(client,"weapon_pistol") 
			
		}else{
			GiveWeapon(client,g_sPrev_Weapon[client])
		}
		AcceptEntityInput(weapon_ind, "Kill")
}

public CreatePropDyn(client, String:strModel[])
{

	new Ent = CreateEntityByName("prop_dynamic_override");
	SetEntityModel(Ent,"models/props_junk/gnome.mdl");
	DispatchSpawn(Ent)
	SetVariantString("!activator")
	AcceptEntityInput(Ent, "SetParent", client, Ent, 0)
	SetVariantString("medkit")
	AcceptEntityInput(Ent, "SetParentAttachment", client, Ent, 0)
	return Ent
}

public GiveWeapon(client, String:str_Weapon[])
{
	new String:sWeapon[32];
	GetEdictClassname(GetPlayerWeaponSlot(client, 1), sWeapon, 32);
	RemovePlayerItem(client, GetPlayerWeaponSlot(client, 1));
	SetCommandFlags("give", GetCommandFlags("give") & ~FCVAR_CHEAT);
	FakeClientCommand(client, "give %s",str_Weapon, sWeapon);
	SetCommandFlags("give", GetCommandFlags("give") | FCVAR_CHEAT);
}

public SetFirstPerson(client)
{
	SetEntProp(client, Prop_Send, "m_hViewEntity", -1)
	SetEntProp(client, Prop_Send, "m_iObserverMode", 0)
}

public Action:Timer_PLsfx(Handle:timer, any:client)
{
	StopSound(g_ent_PilotLight[client], SNDCHAN_STATIC, "pilotlight.mp3")
	EmitAmbientSound("pilotlight.mp3",sfx_pl_offset,g_ent_PilotLight[client])	
	
	//PrintToChatAll("PLsfx init")
	return Plugin_Continue
}

public Action:Timer_Throwersfx(Handle:timer, any:client)
{
	StopSound(g_ent_Thrower[client], SNDCHAN_STATIC, "fire.mp3")
	EmitAmbientSound("fire.mp3",sfx_pl_offset,g_ent_Thrower[client])	
	
	//PrintToChatAll("Throwersfx init")
	return Plugin_Continue
}

public Action:Timer_FuelGauge(Handle:timer, any:client)
{
	AdjustFuel(client)
}
public Action:Timer_Thrower(Handle:timer, any:client)
{
	g_act_Thrower[client]=0
	
	AcceptEntityInput(g_ent_Thrower[client], "Kill")
	//PrintToChatAll("Thrower killed")	
	g_timer_Thrower[client]=INVALID_HANDLE
	StopSound(g_ent_Thrower[client], SNDCHAN_STATIC, "fire.mp3")
	CloseHandle(g_timer_Throwersfx[client])
	g_timer_Throwersfx[client]=INVALID_HANDLE
	
	
	CloseHandle(g_timer_FuelGauge[client])
	g_timer_FuelGauge[client]=INVALID_HANDLE
	if(g_eq_Thrower[client]==1){
		AdjustFuel(client)
		ActivatePilotLight(client)
	}
}

public Action:OnPlayerRunCmd(client, &i_Buttons, &i_Impulse, Float:f_Velocity[3], Float:f_Angles[3], &i_Weapon)
{
	/*if(client==1){
	new Float:Pos[3];
	GetEntPropVector(client, Prop_Data, "m_vecCameraPVSOrigin", Pos);
	PrintToChatAll("Cam PVS origin: %f %f %f",Pos[0],Pos[1],Pos[2])
	PrintToChatAll("Angles: %f %f %f",f_Angles[0],f_Angles[1],f_Angles[2])
	new Float:vecClientEyeAng[3]
	GetClientEyeAngles(client, vecClientEyeAng)
	PrintToChatAll("View Angle: %f %f %f",vecClientEyeAng[0],vecClientEyeAng[1],vecClientEyeAng[2])
	}*/
	if(g_act_Thrower[client]==1 || g_act_PilotLight[client]==1)
	{
		////PrintToChatAll("Buttons: %i",i_Buttons)
		i_Buttons|=IN_SPEED
		i_Buttons&=~IN_USE
		////PrintToChatAll("Buttons modified: %i",i_Buttons)
		
		if(i_Impulse==100 && g_Thrower_inhands[client]==1){
		if(g_en_FlashLight[client]==0)
		g_en_FlashLight[client]=1
		else
		g_en_FlashLight[client]=0
		//CreateLight(client)
		CreateFlashLight(client)
	}
		
		return Plugin_Changed
	}/*
	if(i_Impulse==100 && g_Thrower_inhands[client]==1){
		if(g_en_FlashLight[client]==0)
		g_en_FlashLight[client]=1
		else
		g_en_FlashLight[client]=0
		//CreateLight(client)
		CreateFlashLight(client)
	}*/
	
	return Plugin_Continue
	
}

public AdjustFuel(client)
{	
	g_Fuel[client]-=GetTickedTime()-g_Fuel_time[client]
	new temp=CalculateFuelPercent(client)
	//PrintToChatAll("Current Fuel: %f seconds or %i percent", g_Fuel[client], temp)
	PrintHintText(client,"Flamethrower Fuel: %i percent (Press reload to switch weapons)", temp)
	if(temp<=0){
		HolsterThrower(client)
		//DeactivatePilotLight(client)
		/*SetFirstPerson(client)
		
		g_Fuel[client]=g_max_fuel
		new String:sWeapon[32];
		GetEdictClassname(GetPlayerWeaponSlot(client, 1), sWeapon, 32);
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, 1));
		SetCommandFlags("give", GetCommandFlags("give") & ~FCVAR_CHEAT);
		FakeClientCommand(client, "give pistol", sWeapon);
		SetCommandFlags("give", GetCommandFlags("give") | FCVAR_CHEAT);	*/
		
		g_eq_Thrower[client]=0
		
		
	}else{
		g_Fuel_time[client]=GetTickedTime()
	}
	
}

public CalculateFuelPercent(client)
{
	new Float:temp=FloatDiv(g_Fuel[client],60.000000)
	////PrintToChatAll("Fuel ration: %i",temp)
	temp=FloatMul(temp, 100.000000)
	////PrintToChatAll("Fuel percent: %i",temp)
	return RoundFloat(temp)
}

public TraceSomething(client)
{
	decl Float:vecClientEyePos[3], Float:vecClientEyeAng[3]
	decl String:strName[50]

	GetClientEyePosition(client, vecClientEyePos) // Get the position of the player's eyes
	GetClientEyeAngles(client, vecClientEyeAng) // Get the angle the player is looking
	
	////PrintToChatAll("Running Code %f %f %f | %f %f %f", vecClientEyePos[0], vecClientEyePos[1], vecClientEyePos[2], vecClientEyeAng[0], vecClientEyeAng[1], vecClientEyeAng[2])    

	//Check for colliding entities
	TR_TraceRayFilter(vecClientEyePos, vecClientEyeAng, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitSelf, client)	
	TR_GetEndPosition(g_vecHit, INVALID_HANDLE)
	if (TR_DidHit(INVALID_HANDLE))
	{
		new TRIndex = TR_GetEntityIndex(INVALID_HANDLE)
		////PrintToChatAll("Entity Found %i", TRIndex)
		GetEntPropString(TRIndex, Prop_Data, "m_iClassname", strName, sizeof(strName))
		
		////PrintToChatAll("Entity Name %s", strName)
		////PrintToChatAll("Entity Name %s", strName)
		
		new Float:diff[3]
		diff[0]=g_vecHit[0]-vecClientEyePos[0]
		diff[1]=g_vecHit[1]-vecClientEyePos[1]
		diff[2]=g_vecHit[2]-vecClientEyePos[2]
		if(diff[0]>1024.0 || diff[0]<-1024.0
				|| diff[1]>1024.0 || diff[1]<-1024.0
				|| diff[2]>1024.0 || diff[2]<-1024.0)
		{
			////PrintToChatAll("Entity out of bounds")
		}
		else{
			if(!strcmp("infected", strName, false) || !strcmp("player", strName, false) )
			{	
				////PrintToChatAll("IGNITION!!!")
				CreateTimer(0.4, Timer_Ignite, TRIndex)
				
			}
		}
	}

}

public Action:Timer_Ignite(Handle:timer, any:TRIndex)
{
	IgniteEntity(TRIndex, 60.0)
}

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	if(entity == data) // Check if the TraceRay hit the itself.
	{
		return false // Don't let the entity be hit
	}
	return true // It didn't hit itself
}


/*public Action:Event_playerhurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	////PrintToChatAll("Ouch!")
	return Plugin_Continue
}*/

/*public Action:Event_bulletimpact(Handle:event, const String:name[], bool:dontBroadcast)
{
	//PrintToChatAll("Something has been hit")
	PrintToServer("Select item: %i",hSelectItem)
	PrintToServer("Game conf: %i",hGameConf)
	SDKCall(hSelectItem, GetClientOfUserId(GetEventInt(event, "userid")), "weapon_first_aid_kit", 0);
	return Plugin_Continue
}*/

/*public OnClientPostAdminCheck(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}*/

/*public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	////PrintToChatAll("Something has been damaged")
	return Plugin_Continue
}*/

//unused function
/*public Action:Event_weapon_fire(Handle:event, const String:name[], bool:dontBroadcast)
{
	//decl String:strName[50]
	//new target=GetClientAimTarget(GetEventInt(event, "userid"),false)
	////PrintToChatAll("Entity Found %i", target)
	//GetEntPropString(target, Prop_Data, "m_iClassname", strName, sizeof(strName));
	////PrintToChatAll("Entity Name %s", strName)
	//if(!strcmp("infected", strName, false)){
	//	IgniteEntity(target, 60)
	//}
	new weapon_ind=-1
	new String:weapon_s[50]
	new String:client_weapon_s[50]	
	new Client = GetClientOfUserId(GetEventInt(event, "userid"))
	
	
	GetClientWeapon(Client,client_weapon_s,sizeof(client_weapon_s))
	weapon_ind=GetPlayerWeaponSlot(Client,1)
	if(IsValidEntity(weapon_ind)){
		GetEntPropString(weapon_ind, Prop_Data, "m_iClassname", weapon_s, sizeof(weapon_s))
		if(!strcmp("weapon_melee", weapon_s, false) && !strcmp("weapon_melee", client_weapon_s, false))
		{
			GetEntPropString(weapon_ind, Prop_Data, "m_strMapSetScriptName", weapon_s, sizeof(weapon_s))
			if(!strcmp("thrower", weapon_s, false)){
				
				
				decl String:ModelName[128];
				GetEntPropString(weapon_ind, Prop_Data, "m_ModelName", ModelName, sizeof(ModelName));
				//PrintToChatAll("Weapon model name: %s",ModelName)
				//////////////////////////////
				new Ent = CreateEntityByName("prop_dynamic_override");
				SetEntityModel(Ent,"models/props_junk/gnome.mdl");
				DispatchSpawn(Ent)
				SetVariantString("!activator")
				AcceptEntityInput(Ent, "SetParent", Client, Ent, 0)
				SetVariantString("medkit")
				AcceptEntityInput(Ent, "SetParentAttachment", Client, Ent, 0)
				////////////////////////////////////////
				if(g_weaponind!=weapon_ind){
					CreateTimer(0.1, Timer_FThrower, Client, TIMER_REPEAT)
				}
				g_weaponind=weapon_ind
				GetEntPropVector(weapon_ind, Prop_Data, "m_vecOrigin", g_vecWeap)
				////PrintToChatAll("Weapon Origin: %f %f %f",g_vecWeap[0],g_vecWeap[1],g_vecWeap[2])
				TraceSomething(Client)
				new Float:vec[3]
				GetClientAbsOrigin(Client, vec)
				vec[2] += 10
				TE_SetupBeamRingPoint(vec, 10.0, 375.0, g_BSprite, g_HSprite, 0, 10, 0.6, 10.0, 0.5, redC, 10, 0)
				TE_SendToAll()
				////PrintToChatAll("Weapon: %s",weapon_s)
				new m_Offset=FindSendPropOffs("CTerrorMeleeWeapon","m_hEffectEntity")
				new flame=GetEntData(weapon_ind, m_Offset, 4)
				////PrintToChatAll("Flame entity: %i",flame)
				new Float:data
				//data=GetEntPropFloat(weapon_ind, Prop_Data, "m_flTimeWeaponIdle")
				////PrintToChatAll("Weapon: %f",data)
				data=GetEntPropFloat(weapon_ind, Prop_Data, "m_flNextPrimaryAttack")
				////PrintToChatAll("Weapon time: %f",data)
				
				
				////PrintToChatAll("Weapon range max1: %f", GetEntPropFloat(weapon_ind, Prop_Data, "m_fMaxRange1"))
				////PrintToChatAll("Weapon range max2: %f", GetEntPropFloat(weapon_ind, Prop_Data, "m_fMaxRange2"))
				////PrintToChatAll("Weapon range min1: %f", GetEntPropFloat(weapon_ind, Prop_Data, "m_fMinRange1"))
				////PrintToChatAll("Weapon range min2: %f", GetEntPropFloat(weapon_ind, Prop_Data, "m_fMinRange2"))
				//SetEntPropFloat(weapon_ind, Prop_Data, "m_fMinRange1", GetEntPropFloat(weapon_ind, Prop_Data, "m_fMaxRange1"))
				//SetEntPropFloat(weapon_ind, Prop_Data, "m_fMinRange2", GetEntPropFloat(weapon_ind, Prop_Data, "m_fMaxRange1"))
				////PrintToChatAll("Game time: %f",GetGameTime())
				////PrintToChatAll("Weapon speed: %f",GetEntPropFloat(weapon_ind, Prop_Data, "m_flSpeed"))
				//new Float:attackdata=GetGameTime()+1.0
				////PrintToChatAll("Weapon new time: %f",attackdata)
				//SetEntPropFloat(weapon_ind, Prop_Data, "m_flNextPrimaryAttack", attackdata)
			}
		}
	}
	if(!IsClientInGame(Client)){
		//PrintToChatAll("Client not in game")
	} 
	//FindEntities(GetEventInt(event, "userid"))
	
	return Plugin_Continue
} */

/*public Action:HookAmbient_Callback(String:sample[PLATFORM_MAX_PATH], &entity, &Float:volume, &level, &pitch, Float:pos[3], &flags, &Float:delay)
{
	//PrintToChatAll("Playing ambient: %s",sample)
	return Plugin_Continue
}*/

/*public Action:HookSound_Callback(Clients[64], &NumClients, String:StrSample[PLATFORM_MAX_PATH], &Entity)
{
	//PrintToChatAll("Playing sound: %s",StrSample)
	return Plugin_Continue
}*/


/*public RemoveCamera(client)
{
	//SetEntProp(client, Prop_Send, "m_iObserverMode", 0)
	SetClientViewEntity(client, client)
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1)
	AcceptEntityInput(ClientCamera[client], "Kill")
}*/




/*public SetClientCameraStatic(client)
{
	//SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
	//SetEntProp(client, Prop_Send, "m_iObserverMode", 0);

	// Create the Camera Entity
	new entCamera = CreateEntityByName("point_viewcontrol");

	

	// Sets the clients Targetname to their Index 
	//DispatchKeyValue(client, "targetname", sWatcher);

	if(IsValidEntity(entCamera))
	{
		decl Float:vecClientEyePos[3], Float:vecClientEyeAng[3]
		
		GetClientEyePosition(client, vecClientEyePos) // Get the position of the player's eyes
		GetClientEyeAngles(client, vecClientEyeAng) // Get the angle the player is looking
		//Name of the Camera Entity
		DispatchKeyValue(entCamera, "targetname", "playercam");
		//DispatchKeyValue(entCamera, "target", sWatcher);
		//Amount of time to stay active
		DispatchKeyValue(entCamera, "wait", "3600");
		DispatchSpawn(entCamera);

		TeleportEntity(entCamera, vecClientEyePos, vecClientEyeAng, NULL_VECTOR);

		//SetVariantString(sWatcher);
		//AcceptEntityInput(entCamera, "SetParent", client, entCamera, 0);

		//SetVariantString(sWatcher);
		

		SetVariantString("!activator");
		AcceptEntityInput(entCamera, "SetParent", client, entCamera, 0)
		SetEntProp(client, Prop_Send, "m_hViewEntity",entCamera)
		//AcceptEntityInput(entCamera, "Enable", client, entCamera, 0);
		//SetVariantString("forward");
		//AcceptEntityInput(entCamera, "SetParentAttachment", client, entCamera, 0);
		// Stores the Camera index to the client 
		ClientCamera[client] = entCamera;
	}
	
}*/

//unused function
/*public DistanceOffset(client)
{
	decl Float:vecClientEyePos[3], Float:vecClientEyeAng[3]
	new Float:Distance=60.000000
	new vecThrowerMuzzle[3]
	new Float:Angle
	GetClientEyePosition(client, vecClientEyePos) // Get the position of the player's eyes
	GetClientEyeAngles(client, vecClientEyeAng) // Get the angle the player is looking
	if(vecClientEyeAng[1]<0){
		Angle=vecClientEyeAng[1]+360.000
	}else{
		Angle=vecClientEyeAng[1]
	}
	////PrintToChatAll("Angle in degrees: %f",Angle)
	Angle=DegToRad(Angle)
	vecThrowerMuzzle[0]=(Distance*Cosine(Angle))
	vecThrowerMuzzle[1]=(Distance*Sine(Angle))
	vecThrowerMuzzle[0]=FloatAdd(vecClientEyePos[0],vecThrowerMuzzle[0])
	vecThrowerMuzzle[1]=FloatAdd(vecClientEyePos[1],vecThrowerMuzzle[1])
	
	Angle=vecClientEyeAng[0]
	if(Angle>45.000){
		Angle=45.000
	}	
	Angle=DegToRad(Angle)	
	vecThrowerMuzzle[2]=vecClientEyePos[2]+(Distance*Sine(Angle)*-1.000)
}*/