#pragma semicolon 1
#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>

new bool:granada[MAXPLAYERS+1] = {false, ...};
new bool:humo[MAXPLAYERS+1] = {false, ...};
new bool:saltador[MAXPLAYERS+1] = {false, ...};
new bool:ammo[MAXPLAYERS+1] = {false, ...};
new bool:infiltrado[MAXPLAYERS+1] = {false, ...};
new bool:supercuchillo[MAXPLAYERS+1] = {false, ...};

new Handle:cvarInterval;
new Handle:AmmoTimer;
new Handle:cambio;

new activeOffset = -1;
new clip1Offset = -1;
new clip2Offset = -1;
new secAmmoTypeOffset = -1;
new priAmmoTypeOffset = -1;

new g_iCredits[MAXPLAYERS+1];

new Handle:cvarCreditsMax = INVALID_HANDLE;

#define VERSION2 "v2.2"


//Definitions:
#define Speed 200


new bool:g_Trepar[MAXPLAYERS+1] = {false, ...};

public OnPluginStart()
{
    CreateConVar("sm_furienmod_version", VERSION2, "plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

    HookEvent("player_spawn", Event_PlayerSpawn);

    RegConsoleCmd("buy", nobuy);
    RegConsoleCmd("drop", Trepando);
    RegConsoleCmd("rebuy", nobuy);

    cvarInterval = CreateConVar("sm_furienmod_ammo", "5", "How often to reset ammo (in seconds).", _, true, 1.0);

    cambio = CreateConVar("sm_furienmod_winchange", "0", "Switch teams only when furien team not win the round. 1 = yes, 0 = switch teams always", _, true, 1.0);

    //RegConsoleCmd("sm_premios", DOMenu);

    RegConsoleCmd("sm_shop", DOMenu);

    HookEvent("round_end", EventRoundEnd);

    RegConsoleCmd("sm_scream", PredatorA);


    //RegConsoleCmd("sm_creditos", VerCreditosClient);


    RegConsoleCmd("sm_credits", VerCreditosClient);
    RegAdminCmd("sm_setcredits", FijarCreditos, ADMFLAG_ROOT);

    HookEvent("player_death", PlayerDeath);
    HookEvent( "bomb_defused", Event_BombDefused );
    HookEvent( "bomb_exploded", Event_BombExploded );

    HookEvent("player_jump", PlayerJump);

    activeOffset = FindSendPropOffs("CAI_BaseNPC", "m_hActiveWeapon");
	
    clip1Offset = FindSendPropOffs("CBaseCombatWeapon", "m_iClip1");
    clip2Offset = FindSendPropOffs("CBaseCombatWeapon", "m_iClip2");
	
    priAmmoTypeOffset = FindSendPropOffs("CBaseCombatWeapon", "m_iPrimaryAmmoCount");
    secAmmoTypeOffset = FindSendPropOffs("CBaseCombatWeapon", "m_iSecondaryAmmoCount");

    cvarCreditsMax = CreateConVar("credits_max", "250", "Max credits (0: No limit)");


    LoadTranslations("common.phrases");
}


public OnMapStart()
{
	AddFileToDownloadsTable("models/mapeadores/kaem/predator/predator.mdl");
	AddFileToDownloadsTable("models/mapeadores/kaem/predator/predator.dx80.vtx");
	AddFileToDownloadsTable("models/mapeadores/kaem/predator/predator.dx90.vtx");
	AddFileToDownloadsTable("models/mapeadores/kaem/predator/predator.sw.vtx");
	AddFileToDownloadsTable("models/mapeadores/kaem/predator/predator.vvd");
	AddFileToDownloadsTable("models/mapeadores/kaem/predator/predator.xbox.vtx");
	AddFileToDownloadsTable("materials/mapeadores/kaem/predator/pred_body.vmt");
	AddFileToDownloadsTable("materials/mapeadores/kaem/predator/pred_body.vtf");
	AddFileToDownloadsTable("materials/mapeadores/kaem/predator/pred_body_n.vtf");
	AddFileToDownloadsTable("materials/mapeadores/kaem/predator/pred_face.vmt");
	AddFileToDownloadsTable("materials/mapeadores/kaem/predator/pred_face.vtf");
	AddFileToDownloadsTable("materials/mapeadores/kaem/predator/pred_face_n.vtf");
	AddFileToDownloadsTable("materials/mapeadores/kaem/predator/pred_gear.vmt");
	AddFileToDownloadsTable("materials/mapeadores/kaem/predator/pred_gear.vtf");
	AddFileToDownloadsTable("materials/mapeadores/kaem/predator/pred_gear_n.vtf");
	//AddFileToDownloadsTable("materials/mapeadores/kaem/predator/pred_Invi.vmt");
	AddFileToDownloadsTable("materials/mapeadores/kaem/predator/pred_mask.vmt");
	AddFileToDownloadsTable("materials/mapeadores/kaem/predator/pred_mask.vtf");
	AddFileToDownloadsTable("materials/mapeadores/kaem/predator/pred_mask_n.vtf");
	AddFileToDownloadsTable("materials/mapeadores/kaem/predator/pred_numbers.vmt");
	AddFileToDownloadsTable("materials/mapeadores/kaem/predator/pred_numbers.vtf");
	AddFileToDownloadsTable("models/mapeadores/kaem/predator/predator.phy");

	PrecacheModel("models/mapeadores/kaem/predator/predator.mdl");


	AddFileToDownloadsTable("materials/models/player/slow/umbrella_ct/ct_urban.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/umbrella_ct/ct_urban.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/umbrella_ct/ct_urban_glass.vmt");
	AddFileToDownloadsTable("materials/models/player/slow/umbrella_ct/ct_urban_glass.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/umbrella_ct/ct_urban_glass_spec.vtf");
	AddFileToDownloadsTable("materials/models/player/slow/umbrella_ct/ct_urban_normal.vtf");
	AddFileToDownloadsTable("models/player/slow/umbrella_ct/umbrella_ct.dx80.vtx");
	AddFileToDownloadsTable("models/player/slow/umbrella_ct/umbrella_ct.dx90.vtx");
	AddFileToDownloadsTable("models/player/slow/umbrella_ct/umbrella_ct.mdl");
	AddFileToDownloadsTable("models/player/slow/umbrella_ct/umbrella_ct.phy");
	AddFileToDownloadsTable("models/player/slow/umbrella_ct/umbrella_ct.sw.vtx");
	AddFileToDownloadsTable("models/player/slow/umbrella_ct/umbrella_ct.vvd");
	PrecacheModel("models/player/slow/umbrella_ct/umbrella_ct.mdl");

	AddFileToDownloadsTable("sound/predator/imhere.mp3");
	PrecacheSound("predator/imhere.mp3");



	if (AmmoTimer != INVALID_HANDLE) {
		KillTimer(AmmoTimer);
	}
	new Float:interval = GetConVarFloat(cvarInterval);
	AmmoTimer = CreateTimer(interval, ResetAmmo, _, TIMER_REPEAT);



}

public Action:FijarCreditos(client, args)
{
    if(args < 2) // Not enough parameters
    {
        ReplyToCommand(client, "[SM] Utiliza: sm_setcredits <#userid|name> [amount]");
        return Plugin_Handled;
    }

    decl String:arg2[10];
    //GetCmdArg(1, arg, sizeof(arg));
    GetCmdArg(2, arg2, sizeof(arg2));

    new amount = StringToInt(arg2);
    //new target;

    decl String:strTarget[32]; GetCmdArg(1, strTarget, sizeof(strTarget)); 

    // Process the targets 
    decl String:strTargetName[MAX_TARGET_LENGTH]; 
    decl TargetList[MAXPLAYERS], TargetCount; 
    decl bool:TargetTranslate; 

    if ((TargetCount = ProcessTargetString(strTarget, client, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED, 
                                           strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0) 
    { 
          ReplyToTargetError(client, TargetCount); 
          return Plugin_Handled; 
    } 

    // Apply to all targets 
    for (new i = 0; i < TargetCount; i++) 
    { 
        new iClient = TargetList[i]; 
        if (IsClientInGame(iClient)) 
        { 
              g_iCredits[iClient] = amount;
              PrintToChat(client, "\x04[SM_FurienMod] \x05Set %i credits in the player %N", amount, iClient);
        } 
    }

    return Plugin_Continue;
}  

public Action:VerCreditosClient(client, args)
{
        PrintToChat(client, "\x04[SM_FurienMod] \x05Your current credits: %i", g_iCredits[client]);
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    new client = GetClientOfUserId(GetEventInt(event, "userid"));

    if (!attacker)
        return;

    if (attacker == client)
        return;
    
    if(GetClientTeam(client) == 2)
    {
		g_iCredits[attacker] += 1;
    }
    else if(GetClientTeam(client) == 3)
    {
	    g_iCredits[attacker] += 2;
    }
    
    if (g_iCredits[attacker] < GetConVarInt(cvarCreditsMax))
    {
        PrintHintText(attacker, "[SM_FurienMod] Your credits: %i (+2)", g_iCredits[attacker]);
    }
    else
    {
        g_iCredits[attacker] = GetConVarInt(cvarCreditsMax);
        PrintToChat(attacker, "\x04[SM_FurienMod] \x05Your credits: %i (Max allowed)", g_iCredits[attacker]);
    }


}


public Action:nobuy(client, args)
{
  if (GetClientTeam(client) == 2)
  {
      PrintToChat(client, "\x04[SM_FurienMod] \x01You cannot buy being a Furien!");
      return Plugin_Handled;
  }
  return Plugin_Continue;

} 

public Action:Trepando(client, args)
{
  if (GetClientTeam(client) == 2)
  {
      if(!g_Trepar[client])
      {
         PrintToChat(client, "\x04[SM_FurienMod] \x01Mode climb: \x03ON");
         g_Trepar[client] = true;
      }
      else
      {
         PrintToChat(client, "\x04[SM_FurienMod] \x01Mode climb: \x03OFF");
         g_Trepar[client] = false;
         SetEntityGravity(client, 0.3);
         SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.4);
      }
  }

} 

public OnGameFrame() 
{
        OnGameFrame2();

	new keys;
	for (new i = 1; i <= MaxClients; i++) 
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2 && !infiltrado[i]) 
		{
			 keys = GetClientButtons(i);
                         if (keys & IN_FORWARD || keys & IN_BACK || keys & IN_MOVELEFT || keys & IN_MOVERIGHT)
                         {
							SetEntityRenderMode(i, RENDER_NORMAL);
							SetEntityRenderColor(i, 255, 255, 255, 255);
							
							new wepIdx;
							
							// strip all weapons
							for (new s = 0; s < 5; s++)
							{
								if ((wepIdx = GetPlayerWeaponSlot(i, s)) != -1)
								{
									SetEntityRenderMode(wepIdx, RENDER_NORMAL);
									SetEntityRenderColor(wepIdx, 255, 255, 255, 255);
								}
							}
							
                         }
			 else
			 {

							SetEntityRenderMode(i, RENDER_TRANSCOLOR);
							SetEntityRenderColor(i, 255, 255, 255, 0);
							
							new wepIdx;
							
							// strip all weapons
							for (new s = 0; s < 5; s++)
							{
								if ((wepIdx = GetPlayerWeaponSlot(i, s)) != -1)
								{
									SetEntityRenderMode(wepIdx, RENDER_TRANSCOLOR);
									SetEntityRenderColor(wepIdx, 255, 255, 255, 0);
								}
							}
			 }
			
		}
	}	
}

public OnClientPostAdminCheck(client)
{
    g_iCredits[client] = 0;
}


public Action:OnWeaponCanUse(client, weapon)
{

  if (GetClientTeam(client) == 2 && !infiltrado[client])
  {
      // block switching to weapon other than knife
      decl String:sClassname[32];
      GetEdictClassname(weapon, sClassname, sizeof(sClassname));

      if (StrEqual(sClassname, "weapon_knife") || StrEqual(sClassname, "weapon_c4"))
      {
          return Plugin_Continue;
      }
      else
      {
          return Plugin_Handled;
      }

  }
  else if(GetClientTeam(client) == 3)
  {
        // block switching to weapon other than knife
      decl String:sClassname[32];
      GetEdictClassname(weapon, sClassname, sizeof(sClassname));

      if (StrEqual(sClassname, "weapon_hegrenade"))
      {
	if(!granada[client])
          return Plugin_Handled;
      }
      else if (StrEqual(sClassname, "weapon_smokegrenade"))
      {
	if(!humo[client])
          return Plugin_Handled;
      }
  }
  return Plugin_Continue;
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) != 1)
	{

		humo[client] = false;
		saltador[client] = false;
		infiltrado[client] = false;
		granada[client] = false;
		ammo[client] = false;
                supercuchillo[client] = false;

                StripAllWeapons(client);

		// if player == T
		if (GetClientTeam(client) == 2)
		{
			GivePlayerItem(client, "weapon_knife");
	                SetEntityGravity(client, 0.3);
	                SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.4);
                        g_Trepar[client] = false;
                        SetEntityModel(client, "models/mapeadores/kaem/predator/predator.mdl");
		}
		//if player == CT
		else if (GetClientTeam(client) == 3)
		{
		           GivePlayerItem(client, "weapon_knife");
		           GivePlayerItem(client, "weapon_usp");
	                   SetEntityGravity(client, 1.0);
	                   SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
                           SetEntityModel(client, "models/player/slow/umbrella_ct/umbrella_ct.mdl");
                           //SetEntityHealth(client, 250);
						
		}
	}
}

public OnGameFrame2()
{

	//Declare:
	decl MaxPlayers;

	//Initialize:
	MaxPlayers = GetMaxClients();

	//Loop:
	for(new X = 1; X < MaxPlayers; X++)
	{

		//Connected:
		if(IsClientInGame(X) && GetClientTeam(X) == 2)
		{

			//Alive:
			if(IsPlayerAlive(X))
			{

                            
                            if(g_Trepar[X])
			    {

				//Wall?
				new bool:NearWall = false;

				//Circle:
				for(new AngleRotate = 0; AngleRotate < 360; AngleRotate += 30)
				{

					//Declare:
					decl Handle:TraceRay;
					decl Float:StartOrigin[3], Float:Angles[3];

					//Initialize:
					Angles[0] = 0.0;
					Angles[2] = 0.0;
					Angles[1] = float(AngleRotate);
					GetClientEyePosition(X, StartOrigin);

					//Ray:
					TraceRay = TR_TraceRayEx(StartOrigin, Angles, MASK_SOLID, RayType_Infinite);

					//Collision:
					if(TR_DidHit(TraceRay))
					{

						//Declare:
						decl Float:Distance;
						decl Float:EndOrigin[3];

						//Retrieve:
						TR_GetEndPosition(EndOrigin, TraceRay);

						//Distance:
						Distance = (GetVectorDistance(StartOrigin, EndOrigin));

						//Allowed:
						if(Distance < 50) NearWall = true;

					}

					//Close:
					CloseHandle(TraceRay);

				}

				//Ceiling:
				decl Handle:TraceRay;
				decl Float:StartOrigin[3];
				new Float:Angles[3] =  {270.0, 0.0, 0.0};

				//Initialize:
				GetClientEyePosition(X, StartOrigin);

				//Ray:
				TraceRay = TR_TraceRayEx(StartOrigin, Angles, MASK_SOLID, RayType_Infinite);

				//Collision:
				if(TR_DidHit(TraceRay))
				{
					//Declare:
					decl Float:Distance;
					decl Float:EndOrigin[3];

					//Retrieve:
					TR_GetEndPosition(EndOrigin, TraceRay);

					//Distance:
					Distance = (GetVectorDistance(StartOrigin, EndOrigin));

					//Allowed:
					if(Distance < 50) NearWall = true;
				}

				//Close:
				CloseHandle(TraceRay);

				//Near:
				if(NearWall)
				{ 
					
					//Almost Zero:
					SetEntityGravity(X, Pow(Pow(100.0, 3.0), -1.0));

					//Buttons:
					decl ButtonBitsum;
					ButtonBitsum = GetClientButtons(X);

					//Origin:
					decl Float:ClientOrigin[3];
					GetClientAbsOrigin(X, ClientOrigin);

					//Angles:
					decl Float:ClientEyeAngles[3];
					GetClientEyeAngles(X, ClientEyeAngles);

					//Declare:
					decl Float:VeloX, Float:VeloY, Float:VeloZ;

					//Initialize:
					VeloX = (Speed * Cosine(DegToRad(ClientEyeAngles[1])));
					VeloY = (Speed * Sine(DegToRad(ClientEyeAngles[1])));
					VeloZ = (Speed * Sine(DegToRad(ClientEyeAngles[0])));


					//Jumping:
					if(ButtonBitsum & IN_JUMP)
					{

						//Stop:
						new Float:Velocity[3] = {0.0, 0.0, 0.0};
						TeleportEntity(X, ClientOrigin, NULL_VECTOR, Velocity);
					}

					//Forward:
					if(ButtonBitsum & IN_FORWARD)
					{

						//Forward:
						new Float:Velocity[3];
						Velocity[0] = VeloX;
						Velocity[1] = VeloY;
						Velocity[2] = (VeloZ - (VeloZ * 2));
						TeleportEntity(X, ClientOrigin, NULL_VECTOR, Velocity);
					}

					//Backward:
					else if(ButtonBitsum & IN_BACK)
					{

						//Backward:
						new Float:Velocity[3];
						Velocity[0] = (VeloX - (VeloX * 2));
						Velocity[1] = (VeloY - (VeloY * 2));
						Velocity[2] = VeloZ;
						TeleportEntity(X, ClientOrigin, NULL_VECTOR, Velocity);
					}

					//Null:
					else 
					{

						//Stop:
						new Float:Velocity[3] = {0.0, 0.0, 0.0};
						TeleportEntity(X, ClientOrigin, NULL_VECTOR, Velocity);
					}

				}

				//Default:
				else SetEntityGravity(X, 0.3);	
			    }	
			}

		}

	}

}

public IsValidClient( client ) 
{ 
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}

public Action:EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
		     new winner = GetEventInt(event, "winner");
		     if(GetConVarInt(cambio) == 1 && winner == 2)
			return;

                     for(new i = 1; i <= MaxClients; i++) 
                     if(IsValidClient(i))
                     {
                         if (GetClientTeam(i) == CS_TEAM_T)
                         {
                             CS_SwitchTeam(i, 3);
                         }
                         else if (GetClientTeam(i) == CS_TEAM_CT)
                         {
                             CS_SwitchTeam(i, 2);
                         }
                     } 
                     ServerCommand("sm_disarm @all");

                
}

stock StripAllWeapons(iClient)
{
    new iEnt;
    for (new i = 0; i <= 4; i++)
    {
        while ((iEnt = GetPlayerWeaponSlot(iClient, i)) != -1)
        {
            RemovePlayerItem(iClient, iEnt);
            RemoveEdict(iEnt);
        }
    }
}

public OnClientPutInServer(client)
{
   SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
   SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost13);  
   SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnPostThinkPost13(client)  
{  
    if(IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
    {
        SetEntProp(client, Prop_Send, "m_iPrimaryAddon", 0);  
    }
} 


public OnEntityCreated(entity, const String:classname[])
{

    if (IsValidEntity(entity))
    {
	
	if (!strcmp(classname, "hegrenade_projectile"))
	{
                CreateTimer(0.1, timer1, entity);
	}
	else if (!strcmp(classname, "smokegrenade_projectile"))
	{
                CreateTimer(0.1, timer2, entity);
	}
    }
}

public Action:timer1(Handle:timer, any:entity)
{
    if (IsValidEntity(entity))
    {

      decl String:classname[32];
      GetEdictClassname(entity, classname, sizeof(classname));
    
      if (StrEqual(classname, "hegrenade_projectile"))
      {
	        new client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");


                if (IsValidClient(client) && IsPlayerAlive(client))
                {

					granada[client] = false;

                }
      }
    }
}  

public Action:timer2(Handle:timer, any:entity)
{
    if (IsValidEntity(entity))
    {

      decl String:classname[32];
      GetEdictClassname(entity, classname, sizeof(classname));
    
      if (StrEqual(classname, "smokegrenade_projectile"))
      {
	        new client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");


                if (IsValidClient(client) && IsPlayerAlive(client))
                {

					humo[client] = false;

                }
      }
    }

} 

public Action:Event_BombDefused( Handle:event, const String:name[], bool:dontBroadcast )
{

    new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	
    if(!IsValidClient(client))
		return;
		
    g_iCredits[client] += 2;
		
    if (g_iCredits[client] < GetConVarInt(cvarCreditsMax))
    {
        PrintHintText(client, "[SM_FurienMod] Your credits: %i (+3)", g_iCredits[client]);
    }
    else
    {
        g_iCredits[client] = GetConVarInt(cvarCreditsMax);
        PrintToChat(client, "\x04[SM_FurienMod] \x05Your credits: %i (Max allowed)", g_iCredits[client]);
    }
			
		
}

public Action:Event_BombExploded( Handle:event, const String:name[], bool:dontBroadcast )
{
    new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	
    if(!IsValidClient(client))
		return;
		
    g_iCredits[client] += 5;
		
    if (g_iCredits[client] < GetConVarInt(cvarCreditsMax))
    {
        PrintHintText(client, "[SM_FurienMod] Your credits: %i (+3)", g_iCredits[client]);
    }
    else
    {
        g_iCredits[client] = GetConVarInt(cvarCreditsMax);
        PrintToChat(client, "\x04[SM_FurienMod] \x05Your credits: %i (Max allowed)", g_iCredits[client]);
    }
}

public Action:DOMenu(client,args)
{
    DID(client);
    PrintToChat(client, "\x04[SM_FurienMod] \x05Your credits: %i", g_iCredits[client]);
}

public Action:DID(clientId) 
{
  if(GetClientTeam(clientId) == 2)
  {
    new Handle:menu = CreateMenu(DIDMenuHandler);
    SetMenuTitle(menu, "FurienMOD shop. Your credits: %i", g_iCredits[clientId]);
    AddMenuItem(menu, "option1", "Information of plugin");
    AddMenuItem(menu, "option2", "+50 HP - 3  Credits");
    AddMenuItem(menu, "option3", "127 Armor - 6 Credits");
    AddMenuItem(menu, "option4", "Infiltrate - 15  Credits");
    AddMenuItem(menu, "option5", "SuperKnife - 20  Credits");
    SetMenuExitButton(menu, true);
    DisplayMenu(menu, clientId, MENU_TIME_FOREVER);
  }
  else if(GetClientTeam(clientId) == 3)
  {
    new Handle:menu2 = CreateMenu(DIDMenuHandler2);
    SetMenuTitle(menu2, "FurienMOD shop. Your credits: %i", g_iCredits[clientId]);
    AddMenuItem(menu2, "option1", "Information of plugin");
    AddMenuItem(menu2, "option2", "+50 HP - 3  Credits");
    AddMenuItem(menu2, "option3", "127 Armor - 6 Credits");
    AddMenuItem(menu2, "option4", "Freezer grenade - 6  Credits");
    AddMenuItem(menu2, "option5", "Napalm grenade - 6  Credits");
    AddMenuItem(menu2, "option6", "Easy Bunny - 8  Credits");
    AddMenuItem(menu2, "option7", "Mode Rambo - 20  Credits");
    SetMenuExitButton(menu2, true);
    DisplayMenu(menu2, clientId, MENU_TIME_FOREVER);
  }

  return Plugin_Handled;
}

public DIDMenuHandler(Handle:menu, MenuAction:action, client, itemNum) 
{
    if ( action == MenuAction_Select ) 
    {



        new String:info[32];
        
        GetMenuItem(menu, itemNum, info, sizeof(info));

        if ( strcmp(info,"option1") == 0 ) 
        {

              PrintToChat(client, "\x04[SM_FurienMod] \x05Public Version:\x03 %s \x05created for SourceMod", VERSION2);
              DID(client);
        }

        else if ( strcmp(info,"option2") == 0 ) 
        {
              
              if (g_iCredits[client] >= 3)
              {
                   if (IsPlayerAlive(client))
                   {
                     if (GetClientTeam(client) == 2)
                     {

                      new vida = (GetClientHealth(client) + 50);

                      SetEntityHealth(client, vida);

                      g_iCredits[client] -= 3;



                      PrintToChat(client, "\x04[SM_FurienMod] \x05Now you have +50 HP. Your credits: %i (-3)", g_iCredits[client]);
                     }
                     else
                     {
                        PrintToChat(client, "\x04[SM_FurienMod] \x05You must be Furien (terrorist) for buy this item");
                     }

                   }
                   else
                   {
                      PrintToChat(client, "\x04[SM_FurienMod] \x05You must be alive for buy this item");
                   }

              }
              else
              {
                 PrintToChat(client, "\x04[SM_FurienMod] \x05Your credits: %i (You do not have enough Credits! needed 3)", g_iCredits[client]);
              }
              DID(client);
            
        }

        else if ( strcmp(info,"option3") == 0 ) 
        {


              if (g_iCredits[client] >= 6)
              {
                   if (IsPlayerAlive(client))
                   {
                     if (GetClientTeam(client) == 2)
                     {


                      SetEntProp(client, Prop_Send, "m_ArmorValue", 127, 1);

                      g_iCredits[client] -= 6;



                      PrintToChat(client, "\x04[SM_FurienMod] \x05Now you have 127 of armor. Your credits: %i (-6)", g_iCredits[client]);
                     }
                     else
                     {
                        PrintToChat(client, "\x04[SM_FurienMod] \x05You must be Furien (terrorist) for buy this item");
                     }


                   }
                   else
                   {
                      PrintToChat(client, "\x04[SM_FurienMod] \x05You must be alive for buy this item");
                   }

              }
              else
              {
                 PrintToChat(client, "\x04[SM_FurienMod] \x05Your credits: %i (You do not have enough Credits! needed 6)", g_iCredits[client]);
              }
              DID(client);
            
            
        }

        else if ( strcmp(info,"option4") == 0 ) 
        {
            
              if (g_iCredits[client] >= 15)
              {
                   if (IsPlayerAlive(client))
                   {
                     if (GetClientTeam(client) == 2)
                     {


                      SetEntityModel(client, "models/player/slow/umbrella_ct/umbrella_ct.mdl");
					  

                      g_iCredits[client] -= 15;

                      infiltrado[client] = true;

		      GivePlayerItem(client, "weapon_glock");

	              SetEntityGravity(client, 1.0);
	              SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);

		      SetEntityRenderMode(client, RENDER_NORMAL);
		      SetEntityRenderColor(client, 255, 255, 255, 255);
							
		      new wepIdx;
							
		      // strip all weapons
		      for (new s = 0; s < 5; s++)
		      {
								if ((wepIdx = GetPlayerWeaponSlot(client, s)) != -1)
								{
									SetEntityRenderMode(wepIdx, RENDER_NORMAL);
									SetEntityRenderColor(wepIdx, 255, 255, 255, 255);
								}
		      }



                      PrintToChat(client, "\x04[SM_FurienMod] \x05Now you are infiltrated of CT. Your credits: %i (-15)", g_iCredits[client]);
                     }
                     else
                     {
                        PrintToChat(client, "\x04[SM_FurienMod] \x05You must be Furien (terrorist) for buy this item");
                     }

                   }
                   else
                   {
                      PrintToChat(client, "\x04[SM_FurienMod] \x05You must be alive for buy this item");
                   }

              }
              else
              {
                 PrintToChat(client, "\x04[SM_FurienMod] \x05Your credits: %i (You do not have enough Credits! needed 15)", g_iCredits[client]);
              }
              DID(client);
            
            
        }

        else if ( strcmp(info,"option5") == 0 ) 
        {
            
              if (g_iCredits[client] >= 20)
              {
                   if (IsPlayerAlive(client))
                   {

                     if (GetClientTeam(client) == 2)
                     {


                      supercuchillo[client] = true;

                      g_iCredits[client] -= 20;



                      PrintToChat(client, "\x04[SM_FurienMod] \x05You have a superknife that make 1 death for 1 hit. Your credits: %i (-20)", g_iCredits[client]);
                     }
                     else
                     {
                        PrintToChat(client, "\x04[SM_FurienMod] \x05You must be Furien (terrorist) for buy this item");
                     }

                   }
                   else
                   {
                      PrintToChat(client, "\x04[SM_FurienMod] \x05You must be alive for buy this item");
                   }

              }
              else
              {
                 PrintToChat(client, "\x04[SM_FurienMod] \x05Your credits: %i (You do not have enough Credits! needed 20)", g_iCredits[client]);
              }
              DID(client);
            
            
        }
    }


    else if (action == MenuAction_Cancel) 
    { 
        PrintToServer("Client %d's menu was cancelled.  Reason: %d", client, itemNum); 
    } 

    else if (action == MenuAction_End)
    {
	CloseHandle(menu);
    }

}



public DIDMenuHandler2(Handle:menu, MenuAction:action, client, itemNum) 
{
    if ( action == MenuAction_Select ) 
    {



        new String:info[32];
        
        GetMenuItem(menu, itemNum, info, sizeof(info));

        if ( strcmp(info,"option1") == 0 ) 
        {

              PrintToChat(client, "\x04[SM_FurienMod] \x05Public Version:\x03 %s \x05created for SourceMod", VERSION2);
              DID(client);
        }

        else if ( strcmp(info,"option2") == 0 ) 
        {
              
              if (g_iCredits[client] >= 3)
              {
                   if (IsPlayerAlive(client))
                   {
                     if (GetClientTeam(client) == 3)
                     {

                      new vida = (GetClientHealth(client) + 50);

                      SetEntityHealth(client, vida);

                      g_iCredits[client] -= 3;



                      PrintToChat(client, "\x04[SM_FurienMod] \x05Now you have +50 HP. Your credits: %i (-3)", g_iCredits[client]);
                     }
                     else
                     {
                        PrintToChat(client, "\x04[SM_FurienMod] \x05You must be AntiFurien (ct) for buy this item");
                     }

                   }
                   else
                   {
                      PrintToChat(client, "\x04[SM_FurienMod] \x05You must be alive for buy this item");
                   }

              }
              else
              {
                 PrintToChat(client, "\x04[SM_FurienMod] \x05Your credits: %i (You do not have enough Credits! needed 3)", g_iCredits[client]);
              }
              DID(client);
            
        }

        else if ( strcmp(info,"option3") == 0 ) 
        {


              if (g_iCredits[client] >= 6)
              {
                   if (IsPlayerAlive(client))
                   {
                     if (GetClientTeam(client) == 3)
                     {


                      SetEntProp(client, Prop_Send, "m_ArmorValue", 127, 1);

                      g_iCredits[client] -= 6;



                      PrintToChat(client, "\x04[SM_FurienMod] \x05Now you have 127 of armor. Your credits: %i (-6)", g_iCredits[client]);
                     }
                     else
                     {
                        PrintToChat(client, "\x04[SM_FurienMod] \x05You must be AntiFurien (ct) for buy this item");
                     }


                   }
                   else
                   {
                      PrintToChat(client, "\x04[SM_FurienMod] \x05You must be alive for buy this item");
                   }

              }
              else
              {
                 PrintToChat(client, "\x04[SM_FurienMod] \x05Your credits: %i (You do not have enough Credits! needed 6)", g_iCredits[client]);
              }
              DID(client);
            
            
        }

        else if ( strcmp(info,"option4") == 0 ) 
        {
            
              if (g_iCredits[client] >= 6)
              {
                   if (IsPlayerAlive(client))
                   {
                     if (GetClientTeam(client) == 3)
                     {

					  

                      g_iCredits[client] -= 6;

                      humo[client] = true;

		      GivePlayerItem(client, "weapon_smokegrenade");



                      PrintToChat(client, "\x04[SM_FurienMod] \x05You have a freeze grenade. Your credits: %i (-6)", g_iCredits[client]);
                     }
                     else
                     {
                        PrintToChat(client, "\x04[SM_FurienMod] \x05You must be AntiFurien (ct) for buy this item");
                     }

                   }
                   else
                   {
                      PrintToChat(client, "\x04[SM_FurienMod] \x05You must be alive for buy items");
                   }

              }
              else
              {
                 PrintToChat(client, "\x04[SM_FurienMod] \x05Your credits: %i (You do not have enough Credits! needed 6)", g_iCredits[client]);
              }
              DID(client);
            
            
        }

        else if ( strcmp(info,"option5") == 0 ) 
        {
            
              if (g_iCredits[client] >= 6)
              {
                   if (IsPlayerAlive(client))
                   {

                     if (GetClientTeam(client) == 3)
                     {


                      granada[client] = true;

                      g_iCredits[client] -= 6;

		      GivePlayerItem(client, "weapon_hegrenade");



                      PrintToChat(client, "\x04[SM_FurienMod] \x05You have a napalm grenade. Your credits: %i (-6)", g_iCredits[client]);
                     }
                     else
                     {
                        PrintToChat(client, "\x04[SM_FurienMod] \x05You must be AntiFurien (ct) for buy this item");
                     }

                   }
                   else
                   {
                      PrintToChat(client, "\x04[SM_FurienMod] \x05You must be alive for buy this item");
                   }

              }
              else
              {
                 PrintToChat(client, "\x04[SM_FurienMod] \x05Your credits: %i (You do not have enough Credits! needed 6)", g_iCredits[client]);
              }
              DID(client);
            
            
        }
        else if ( strcmp(info,"option6") == 0 ) 
        {
            
              if (g_iCredits[client] >= 8)
              {
                   if (IsPlayerAlive(client))
                   {

                     if (GetClientTeam(client) == 3)
                     {


                      saltador[client] = true;

                      g_iCredits[client] -= 8;




                      PrintToChat(client, "\x04[SM_FurienMod] \x05You have easy bunny. Your credits: %i (-8)", g_iCredits[client]);
                     }
                     else
                     {
                        PrintToChat(client, "\x04[SM_FurienMod] \x05You must be AntiFurien (ct) for buy this item");
                     }

                   }
                   else
                   {
                      PrintToChat(client, "\x04[SM_FurienMod] \x05You must be alive for buy this item");
                   }

              }
              else
              {
                 PrintToChat(client, "\x04[SM_FurienMod] \x05Your credits: %i (You do not have enough Credits! needed 8)", g_iCredits[client]);
              }
              DID(client);
            
            
        }
        else if ( strcmp(info,"option7") == 0 ) 
        {
            
              if (g_iCredits[client] >= 20)
              {
                   if (IsPlayerAlive(client))
                   {

                     if (GetClientTeam(client) == 3)
                     {


                      ammo[client] = true;

                      g_iCredits[client] -= 20;

                      StripAllWeapons(client);

		      GivePlayerItem(client, "weapon_knife");
		      GivePlayerItem(client, "weapon_mp5navy");



                      PrintToChat(client, "\x04[SM_FurienMod] \x05You are a Rambo with infinite ammo. Your credits: %i (-20)", g_iCredits[client]);
                     }
                     else
                     {
                        PrintToChat(client, "\x04[SM_FurienMod] \x05You must be AntiFurien (ct) for buy this item");
                     }

                   }
                   else
                   {
                      PrintToChat(client, "\x04[SM_FurienMod] \x05You must be alive for buy this item");
                   }

              }
              else
              {
                 PrintToChat(client, "\x04[SM_FurienMod] \x05Your credits: %i (You do not have enough Credits! needed 20)", g_iCredits[client]);
              }
              DID(client);
            
            
        }
    }


    else if (action == MenuAction_Cancel) 
    { 
        PrintToServer("Client %d's menu was cancelled.  Reason: %d", client, itemNum); 
    } 

    else if (action == MenuAction_End)
    {
	CloseHandle(menu);
    }

}

public Action:ResetAmmo(Handle:timer)
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientConnected(client) && !IsFakeClient(client) && IsClientInGame(client) && IsPlayerAlive(client) && (ammo[client]))
		{
			Client_ResetAmmo(client);
		}
	}
}

public Client_ResetAmmo(client)
{
	new zomg = GetEntDataEnt2(client, activeOffset);
	if (clip1Offset != -1 && zomg != -1)
		SetEntData(zomg, clip1Offset, 999, 4, true);
	if (clip2Offset != -1 && zomg != -1)
		SetEntData(zomg, clip2Offset, 999, 4, true);
	if (priAmmoTypeOffset != -1 && zomg != -1)
		SetEntData(zomg, priAmmoTypeOffset, 999, 4, true);
	if (secAmmoTypeOffset != -1 && zomg != -1)
		SetEntData(zomg, secAmmoTypeOffset, 999, 4, true);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
      if (IsValidClient(attacker))
      {



        if (supercuchillo[attacker])
        {
          if (GetClientTeam(attacker) != GetClientTeam(victim))
          {
                        damage = (damage + 999999);
                        return Plugin_Changed;
	  }
        }

      }
      return Plugin_Continue;
}

public Action:PlayerJump(Handle:event, const String:name[], bool:dontBroadcast) 
{
      new client = GetClientOfUserId(GetEventInt(event, "userid"));

      if(!saltador[client]) return;

      SetEntPropFloat(client, Prop_Send, "m_flStamina", 0.0);
}


public Action:PredatorA(client, args)
{
    if(IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
    {
            		new Float:iVecg[ 3 ];
		        GetClientAbsOrigin( client, Float:iVecg );

	
			EmitAmbientSound("predator/imhere.mp3", iVecg, client, SNDLEVEL_NORMAL );
    }
    else
    {
           PrintToChat(client, "\x04[SM_FurienMod] \x05Tienes que estar vivo y ser predator para usar esto");
    }
}
