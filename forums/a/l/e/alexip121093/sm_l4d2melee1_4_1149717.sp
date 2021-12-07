#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#define PLUGIN_VERSION "1.2"
new melee[4096];
new Float:g_flMANextTime[64] = -1.0;
new g_iMAEntid[64] = -1;
new g_iMAEntid_notmelee[64] = -1;
//this tracks the attack count, similar to twinSF
new g_iMAAttCount[64] = -1;
new bool:g_bSurvivorisEnsnared[MAXPLAYERS+1];
new bool:g_bSurvivorisRidden[MAXPLAYERS+1];
new g_GameInstructor[MAXPLAYERS+1];
new Handle:cvar_ammolower = INVALID_HANDLE;
new Handle:cvar_ammoupper = INVALID_HANDLE;
new Handle:cvar_escapeammo = INVALID_HANDLE;
new Handle:cvar_notice = INVALID_HANDLE;
new Handle:cvar_MA = INVALID_HANDLE;
new Handle:cvar_pistol = INVALID_HANDLE;
new g_ActiveWeaponOffset,	g_iMeleeFatigueO,g_iNextPAttO, g_iMA_maxpenalty;
new bool:g_bIsLoading;

public Plugin:myinfo = 
{
	name = "L4D2 Melee  Mod",
	author = "hihi1210",
	description = "Melee weapons will breaks",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	decl String:s_Game[12];
	GetGameFolderName(s_Game, sizeof(s_Game));
	if (!StrEqual(s_Game, "left4dead2"))
	{
		SetFailState("L4D2 Melee  Mod will only work with Left 4 Dead 2!");
	}
	CreateConVar("sm_l4d2meleemod_version", PLUGIN_VERSION, "L4D2 Melee  Mod version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	HookEvent("item_pickup", Event_ItemPickup);
	cvar_ammolower = CreateConVar("sm_l4d2meleemod_ammo_lower", "150", "After How many times of attack, the melee weapons breaks (lower limit)");
	cvar_ammoupper = CreateConVar("sm_l4d2meleemod_ammo_upper", "250", "After How many times of attack, the melee weapons breaks (upper limit)");
	cvar_notice = CreateConVar("sm_l4d2meleemod_notice", "2", "Show After how many attacks the melee weapon breaks ( 0 = disable ,1 = display numbers ,2 = bar");
	cvar_pistol = CreateConVar("sm_l4d2meleemod_pistol", "0", "after the melee weapon breaks , which secondary weapon will give out .(0: single pistol 1:double pistol 2:magnum 3:chainsaw");
	cvar_escapeammo = CreateConVar("sm_l4d2meleemod_ammo_escape", "100", "number of melee weapon ammo needed to escape from special infected");
	cvar_MA = CreateConVar("sm_l4d2meleemod_MA", "1", "Show After how many attacks the melee weapon breaks ( 0 = disable ,1 = display numbers ,2 = bar");
	HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Post);
	g_ActiveWeaponOffset = FindSendPropInfo("CBasePlayer", "m_hActiveWeapon");
	HookEvent("choke_start", Event_ChokeStart);
	HookEvent("lunge_pounce", Event_LungePounce);
	HookEvent("tongue_pull_stopped", event_Save);
	HookEvent("choke_stopped", event_Save);
	HookEvent("pounce_stopped", event_Save);
	HookEvent("jockey_ride_end", event_Save);
	HookEvent("charger_carry_end", event_Save);
	HookEvent("charger_pummel_end", event_Save);
	HookEvent("player_spawn", UnPwnUserid);
	HookEvent("player_death", UnPwnUserid);
	HookEvent("player_connect_full", UnPwnUserid);
	HookEvent("player_disconnect", UnPwnUserid);
	HookEvent("revive_success", UnPwnUserid1);
	HookEvent("jockey_ride", Event_JockeyRide);
	HookEvent("round_start", event_RoundStart);
	HookEvent("charger_pummel_start", Event_ChargerPummel);
	g_iMeleeFatigueO	=	FindSendPropInfo("CTerrorPlayer","m_iShovePenalty");
	g_iNextPAttO		=	FindSendPropInfo("CBaseCombatWeapon","m_flNextPrimaryAttack");
	g_bIsLoading = true;
	g_iMA_maxpenalty = 4;	

}
public OnMapStart()
{
	new max_entities = GetMaxEntities();

	for (new i = 0; i < max_entities; i++)
	{
		melee[i]= 0;
	}
}
public OnClientPostAdminCheck(client)
{
	g_bSurvivorisEnsnared[client] = false;
	g_bSurvivorisRidden[client] = false;
	g_GameInstructor[client] = -1;
}
public Action:MeleeCheck(client)
{
	new Melee = GetPlayerWeaponSlot(client, 1);
	if (Melee > 0)
	{
		new String:sweapon[32];
		GetEdictClassname(Melee, sweapon, 32);
		if (StrContains(sweapon, "weapon_melee", false) >= 0)
		{
			if (melee[Melee] >= GetConVarInt(cvar_escapeammo))
			{
				QueryClientConVar(client, "gameinstructor_enable", ConVarQueryFinished:GameInstructor, client);
				ClientCommand(client, "gameinstructor_enable 1");
				CreateTimer(0.1, DisplayInstructorHint, client);
			}
		}
	}
}
public Action:DisplayInstructorHint(Handle:h_Timer, any:i_Client)
{
	decl i_Ent, String:s_TargetName[32], String:s_Message[256], Handle:h_Pack

	i_Ent = CreateEntityByName("env_instructor_hint")
	FormatEx(s_TargetName, sizeof(s_TargetName), "hint%d", i_Client)
	FormatEx(s_Message, sizeof(s_Message), "You can press ATTACK button to use your melee weapon to escape!!!")
	ReplaceString(s_Message, sizeof(s_Message), "\n", " ")
	DispatchKeyValue(i_Client, "targetname", s_TargetName)
	DispatchKeyValue(i_Ent, "hint_target", s_TargetName)
	DispatchKeyValue(i_Ent, "hint_timeout", "5")
	DispatchKeyValue(i_Ent, "hint_range", "0.01")
	DispatchKeyValue(i_Ent, "hint_icon_onscreen", "use_binding")
	DispatchKeyValue(i_Ent, "hint_caption", s_Message)
	DispatchKeyValue(i_Ent, "hint_color", "255 255 255")
	DispatchKeyValue(i_Ent, "hint_binding", "+attack")
	DispatchSpawn(i_Ent)
	AcceptEntityInput(i_Ent, "ShowHint")
	
	h_Pack = CreateDataPack()
	WritePackCell(h_Pack, i_Client)
	WritePackCell(h_Pack, i_Ent)
	CreateTimer(5.0, RemoveInstructorHint, h_Pack)
}


public GameInstructor(QueryCookie:q_Cookie, i_Client, ConVarQueryResult:c_Result, const String:s_CvarName[], const String:s_CvarValue[])
{
	g_GameInstructor[i_Client] = StringToInt(s_CvarValue);
}

public Action:RemoveInstructorHint(Handle:h_Timer, Handle:h_Pack)
{
	decl i_Ent, i_Client
	
	ResetPack(h_Pack, false)
	i_Client = ReadPackCell(h_Pack)
	i_Ent = ReadPackCell(h_Pack)
	CloseHandle(h_Pack)
	
	if (IsValidEntity(i_Ent))
	RemoveEdict(i_Ent)
	
	if (!g_GameInstructor[i_Client])
	ClientCommand(i_Client, "gameinstructor_enable 0")
}
public Action:Event_ChokeStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if (victim == 0 || !IsClientInGame(victim) || IsFakeClient(victim)) return;
	g_bSurvivorisEnsnared[victim] = true;
	MeleeCheck(victim);
}

public Action:Event_LungePounce(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if (victim == 0 || !IsClientInGame(victim) || IsFakeClient(victim)) return;
	g_bSurvivorisEnsnared[victim] = true;
	MeleeCheck(victim);
}

public Action:Event_JockeyRide(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if (victim == 0 || !IsClientInGame(victim) || IsFakeClient(victim)) return;
	g_bSurvivorisEnsnared[victim] = true;
	g_bSurvivorisRidden[victim] = true;
	MeleeCheck(victim);
}

public Action:Event_ChargerPummel(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if (victim == 0 || !IsClientInGame(victim) || IsFakeClient(victim)) return;
	g_bSurvivorisEnsnared[victim] = true;
	MeleeCheck(victim);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip)
}
public Action:Event_WeaponFire(Handle:event, const String:ename[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsClientInGame(client)) return;
	if (!IsPlayerAlive(client)) return;
	if (GetClientTeam(client) !=2) return;
	if (IsFakeClient(client)) return;
	if (IsPlayerIncapped(client)) return;
	new i_Weapon = GetEntDataEnt2(client, g_ActiveWeaponOffset)
	decl String:s_Weapon[32]
	if (IsValidEntity(i_Weapon))
	{
		GetEdictClassname(i_Weapon, s_Weapon, sizeof(s_Weapon))
		if (StrContains(s_Weapon, "weapon_melee", false) >= 0)
		{
			if (melee[i_Weapon] > 0)
			{
				melee[i_Weapon]--;
				if (GetConVarInt(cvar_notice) == 1)
				{
					PrintHintText(client,"Melee Weapon strength: %d",melee[i_Weapon]);
				}
				else if (GetConVarInt(cvar_notice) == 2)
				{
					decl String:gauge[30] = "[====|=====|=====|====]";
					new Float:percent = float(melee[i_Weapon]) / float(GetConVarInt(cvar_ammoupper));
					new pos = RoundFloat(percent * 20.0)+1;
					if (pos < 21)
					{
						gauge{pos} = ']';
						gauge{pos+1} = 0;
					}
					PrintHintText(client,"Melee Weapon strength: \n %s",gauge);
				}
			}
			else if (melee[i_Weapon] <=0)
			{
				melee[i_Weapon] = 0;
				RemoveEdict(i_Weapon);
				new String:command[] = "give";
				if (GetConVarInt(cvar_pistol) == 0)
				{
					StripAndExecuteClientCommand(client, command, "pistol","","");
				}
				else if (GetConVarInt(cvar_pistol) == 1)
				{
					StripAndExecuteClientCommand(client, command, "pistol","","");
					StripAndExecuteClientCommand(client, command, "pistol","","");
				}
				else if (GetConVarInt(cvar_pistol) == 2)
				{
					StripAndExecuteClientCommand(client, command, "pistol_magnum","","");
				}
				else if (GetConVarInt(cvar_pistol) == 3)
				{
					StripAndExecuteClientCommand(client, command, "chainsaw","","");
				}
				PrintHintText(client,"Your Melee Weapon Breaks!!!");
			}
		}
	}
}
public Action:Event_ItemPickup (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId( GetEventInt(event,"userid") );
	if ( !IsPlayerAlive(client) || GetClientTeam(client) == 3 ) return;
	new String:stWpn[24], String:stWpn2[32];
	GetEventString( event, "item", stWpn, sizeof(stWpn) );
	
	Format( stWpn2, sizeof( stWpn2 ), "weapon_%s", stWpn);
	if (StrContains(stWpn2, "weapon_melee", false) >= 0)
	{
		new Melee = GetPlayerWeaponSlot(client, 1);
		if (Melee > 0)
		{
			new String:sweapon[32];
			GetEdictClassname(Melee, sweapon, 32);
			if (StrContains(sweapon, "weapon_melee", false) >= 0)
			{
				if (melee[Melee] <= 0)
				{
					new ammo = GetRandomInt(GetConVarInt(cvar_ammolower), GetConVarInt(cvar_ammoupper))
					melee[Melee] = ammo;
				}
			}
		}
	}
}
public Action:OnWeaponEquip(client, weapon)
{
	if ( !IsPlayerAlive(client) || IsFakeClient(client) || GetClientTeam(client) == 3 )
	return Plugin_Continue;

	decl String:sWeapon[32];
	GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));
	if (StrContains(sWeapon, "weapon_melee", false) >= 0)
	{
		if (weapon > 0)
		{
			if (melee[weapon] <= 0)
			{
				new ammo = GetRandomInt(GetConVarInt(cvar_ammolower), GetConVarInt(cvar_ammoupper))
				melee[weapon] = ammo;
			}
		}
	}
	return Plugin_Continue;
}
StripAndExecuteClientCommand(client, String:command[], String:param1[], String:param2[], String:param3[])
{
	if(client == 0) return;
	if(!IsClientInGame(client)) return;
	if(IsFakeClient(client)) return;
	new admindata = GetUserFlagBits(client);
	new flags = GetCommandFlags(command);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s %s %s", command, param1, param2, param3);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, admindata);
}
stock bool:IsPlayerIncapped(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
	return false;
}
public Action:event_Save(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if (Victim == 0 || !IsClientInGame(Victim) || IsFakeClient(Victim)) return;
	g_bSurvivorisEnsnared[Victim] = false;
	g_bSurvivorisRidden[Victim] = false;
}
public UnPwnUserid (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client) return;
	g_bSurvivorisEnsnared[client] = false;
	g_bSurvivorisRidden[client] = false;
}
public UnPwnUserid1 (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "subject"));
	if (!client) return;
	g_bSurvivorisEnsnared[client] = false;
	g_bSurvivorisRidden[client] = false;
}
public Action:OnPlayerRunCmd(client, &i_Buttons, &i_Impulse, Float:f_Velocity[3], Float:f_Angles[3], &i_Weapon)
{
	if (IsFakeClient(client)) return;
	if (!IsPlayerAlive(client)) return;
	if (GetClientTeam(client) !=2) return;
	if (!g_bSurvivorisEnsnared[client]) return;
	if (IsPlayerIncapped(client)) return;
	if (i_Buttons & IN_ATTACK)
	{
		new Melee = GetPlayerWeaponSlot(client, 1);
		if (Melee > 0)
		{
			new String:sweapon[32];
			GetEdictClassname(Melee, sweapon, 32);
			if (StrContains(sweapon, "weapon_melee", false) >= 0)
			{
				if (melee[Melee] == GetConVarInt(cvar_escapeammo))
				{
					SaveHIM(client);
					melee[Melee] = 0;
					RemoveEdict(Melee);
					CreateTimer(0.7,Timer_RestoreWeapon, client);
				}
				else if (melee[Melee] > GetConVarInt(cvar_escapeammo))
				{
					SaveHIM(client);
					melee[Melee] = melee[Melee] - GetConVarInt(cvar_escapeammo);
				}
				else
				{
					return;
				}
			}
		}
	}
}


public Action:SaveHIM(Client)
{
	// Check if its a valid player
	if (Client == 0 || !IsClientInGame(Client) || IsFakeClient(Client)) return;
	if (g_bSurvivorisEnsnared[Client])
	{
		g_bSurvivorisEnsnared[Client] = false;
		if (g_bSurvivorisRidden[Client] == true)
		SetEntData(Client, FindSendPropInfo("CTerrorPlayer", "m_isIncapacitated"), 1, 1, true);
		else
		SetEntData(Client, FindSendPropInfo("CTerrorPlayer", "m_lifeState"), 2, 1, true);

		CreateTimer(0.5,Timer_RestoreState, Client);
		CallOnPummelEnded(Client);
		PrintHintText(Client, "You have escaped using your melee weapon!");

	}
}
public Action:Timer_RestoreState(Handle:timer, any:client)
{
	SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_isIncapacitated"), 0, 1, true);
	SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_lifeState"), 0, 1, true);
	if (g_bSurvivorisRidden[client] == true)
	g_bSurvivorisRidden[client] = false;
}
public Action:Timer_RestoreWeapon(Handle:timer, any:client)
{
	new String:command[] = "give";
	if (GetConVarInt(cvar_pistol) == 0)
	{
		StripAndExecuteClientCommand(client, command, "pistol","","");
	}
	else if (GetConVarInt(cvar_pistol) == 1)
	{
		StripAndExecuteClientCommand(client, command, "pistol","","");
		StripAndExecuteClientCommand(client, command, "pistol","","");
	}
	else if (GetConVarInt(cvar_pistol) == 2)
	{
		StripAndExecuteClientCommand(client, command, "pistol_magnum","","");
	}
	else if (GetConVarInt(cvar_pistol) == 3)
	{
		StripAndExecuteClientCommand(client, command, "chainsaw","","");
	}
	PrintHintText(client,"Your Melee Weapon Breaks!!!");
}
CallOnPummelEnded(client)
{
	static Handle:hOnPummelEnded=INVALID_HANDLE;
	if (hOnPummelEnded==INVALID_HANDLE){
		new Handle:hConf = INVALID_HANDLE;
		hConf = LoadGameConfigFile("l4dl1d");
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, "CTerrorPlayer::OnPummelEnded");
		PrepSDKCall_AddParameter(SDKType_Bool,SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_CBasePlayer,SDKPass_Pointer,VDECODE_FLAG_ALLOWNULL);
		hOnPummelEnded = EndPrepSDKCall();
		CloseHandle(hConf);
		if (hOnPummelEnded == INVALID_HANDLE){
			SetFailState("Can't get CTerrorPlayer::OnPummelEnded SDKCall!");
			return;
		}
	}
	SDKCall(hOnPummelEnded,client,true,-1);
}
public OnGameFrame()
{
	//if frames aren't being processed,
	//don't bother - otherwise we get LAG
	//or even disconnects on map changes, etc...
	
	if (IsServerProcessing()==false|| g_bIsLoading == true)return;

	MA_OnGameFrame();

}
public OnMapEnd()
{	
	g_bIsLoading = true;
}
public event_RoundStart (Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bIsLoading = false;
}
MA_OnGameFrame()
{
	new surbotcount = 0;
	if (GetConVarInt(cvar_MA)==0)
	return 0;
	new maxplayers = GetMaxClients();
	for (new i = 1; i <= maxplayers; i++)
	{
		if(!IsClientInGame(i)) continue;
		surbotcount++;
	}
	//or if no one has DT, don't bother either
	if (surbotcount==0)
	return 0;

	decl iCid;
	//this tracks the player's ability id
	decl iEntid;
	//this tracks the calculated next attack
	decl Float:flNextTime_calc;
	//this, on the other hand, tracks the current next attack
	decl Float:flNextTime_ret;
	//and this tracks the game time
	new Float:flGameTime=GetGameTime();

	for (new iI=1; iI<=maxplayers; iI++)
	{
		//PRE-CHECKS 1: RETRIEVE VARS
		//---------------------------

		iCid = iI;
		//stop on this client
		//when the next client id is null
		if (iCid <= 0) return 0;
		//skip this client if they're disabled, or, you know, dead

		if (IsPlayerAlive(iCid)==false) continue;
		if(IsPlayerIncapped(iCid)) continue;
		if(GetClientTeam(iCid) != 2) continue;
		iEntid = GetEntDataEnt2(iCid,g_ActiveWeaponOffset);
		//if the retrieved gun id is -1, then...
		//wtf mate? just move on
		if (iEntid == -1) continue;
		//and here is the retrieved next attack time
		flNextTime_ret = GetEntDataFloat(iEntid,g_iNextPAttO);

		//----DEBUG----
		//PrintToChat(iCid,"\x03shove penalty \x01%i\x03, max penalty \x01%i",GetEntData(iCid,g_iMeleeFatigueO), g_iMA_maxpenalty);

		//PRE-CHECKS 2: MOD SHOVE FATIGUE
		//-------------------------------
		if ( GetEntData(iCid,g_iMeleeFatigueO) > g_iMA_maxpenalty )
		{
			SetEntData(iCid, g_iMeleeFatigueO, g_iMA_maxpenalty);
		}





		//CHECK 1: IS PLAYER USING A KNOWN NON-MELEE WEAPON?
		//--------------------------------------------------
		//as the title states... to conserve processing power,
		//if the player's holding a gun for a prolonged time
		//then we want to be able to track that kind of state
		//and not bother with any checks
		//checks: weapon is non-melee weapon
		//actions: do nothing
		if (iEntid == g_iMAEntid_notmelee[iCid])
		{
			//----DEBUG----
			//PrintToChatAll("\x03MA client \x01%i\x03; non melee weapon, ignoring",iCid );

			continue;
		}



		//CHECK 1.5: THE PLAYER HASN'T SWUNG HIS WEAPON FOR A WHILE
		//-------------------------------------------------------
		//in this case, if the player made 1 swing of his 2 strikes,
		//and then paused long enough, we should reset his strike count
		//so his next attack will allow him to strike twice
		//checks: is the delay between attacks greater than 1.5s?
		//actions: set attack count to 0, and CONTINUE CHECKS
		if (g_iMAEntid[iCid] == iEntid
				&& g_iMAAttCount[iCid]!=0
				&& (flGameTime - flNextTime_ret) > 1.0)
		{
			//----DEBUG----
			//PrintToChatAll("\x03MA client \x01%i\x03; hasn't swung weapon",iCid );

			g_iMAAttCount[iCid]=0;
		}



		//CHECK 2: BEFORE ADJUSTED ATT IS MADE
		//------------------------------------
		//since this will probably be the case most of
		//the time, we run this first
		//checks: weapon is unchanged; time of shot has not passed
		//actions: do nothing
		if (g_iMAEntid[iCid] == iEntid
				&& g_flMANextTime[iCid]>=flNextTime_ret)
		{
			//----DEBUG----
			//PrintToChatAll("\x03DT client \x01%i\x03; before shot made",iCid );

			continue;
		}



		//CHECK 3: AFTER ADJUSTED ATT IS MADE
		//------------------------------------
		//at this point, either a gun was swapped, or
		//the attack time needs to be adjusted
		//checks: stored gun id same as retrieved gun id,
		// and retrieved next attack time is after stored value
		//actions: adjusts next attack time
		if (g_iMAEntid[iCid] == iEntid
				&& g_flMANextTime[iCid] < flNextTime_ret)
		{
			//----DEBUG----
			//PrintToChatAll("\x03DT after adjusted shot\n-pre, client \x01%i\x03; entid \x01%i\x03; enginetime\x01 %f\x03; NextTime_orig \x01 %f\x03; interval \x01%f",iCid,iEntid,flGameTime,flNextTime_ret, flNextTime_ret-flGameTime );

			g_iMAAttCount[iCid]++;
			if (g_iMAAttCount[iCid]>1)
			g_iMAAttCount[iCid]=0;

			//> MOD ATTACK
			//------------
			if (g_iMAAttCount[iCid]==1)
			{
				//this is a calculation of when the next primary attack
				//will be after applying double tap values
				//flNextTime_calc = ( flNextTime_ret - flGameTime ) * g_flMA_attrate + flGameTime;
				flNextTime_calc = flGameTime + 0.3 ;

				//then we store the value
				g_flMANextTime[iCid] = flNextTime_calc;

				//and finally adjust the value in the gun
				SetEntDataFloat(iEntid, g_iNextPAttO, flNextTime_calc, true);

				//----DEBUG----
				//PrintToChatAll("\x03-post, NextTime_calc \x01 %f\x03; new interval \x01%f",GetEntDataFloat(iEntid,g_iNextPAttO), GetEntDataFloat(iEntid,g_iNextPAttO)-flGameTime );

				continue;
			}

			//> DON'T MOD ATTACK
			//------------------
			if (g_iMAAttCount[iCid]==0)
			{
				g_flMANextTime[iCid] = flNextTime_ret;
				continue;
			}
		}



		//CHECK 4: CHECK THE WEAPON
		//-------------------------
		//lastly, at this point we need to check if we are, in fact,
		//using a melee weapon =P we check if the current weapon is
		//the same one stored in memory; if it is, move on;
		//otherwise, check if it's a melee weapon - if it is,
		//store and continue; else, continue.
		//checks: if the active weapon is a melee weapon
		//actions: store the weapon's entid into either
		// the known-melee or known-non-melee variable

		//----DEBUG----
		//PrintToChatAll("\x03DT client \x01%i\x03; weapon switch inferred",iCid );

		//check if the weapon is a melee
		decl String:stName[32];
		GetEntityNetClass(iEntid,stName,32);
		if (StrEqual(stName,"CTerrorMeleeWeapon",false)==true)
		{
			//if yes, then store in known-melee var
			g_iMAEntid[iCid]=iEntid;
			g_flMANextTime[iCid]=flNextTime_ret;
			continue;
		}
		else
		{
			//if no, then store in known-non-melee var
			g_iMAEntid_notmelee[iCid]=iEntid;
			continue;
		}
	}

	return 0;
}