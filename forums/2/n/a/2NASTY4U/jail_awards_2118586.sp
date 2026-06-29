#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>
#include <cstrike>
#include <sdkhooks>
#include <clientprefs>

#pragma semicolon 1

new bool:g_Fly[MAXPLAYERS+1] = {false, ...};
new bool:g_Godmode[MAXPLAYERS+1] = {false, ...};
new bool:g_AmmoInfi[MAXPLAYERS+1] = {false, ...};


#define VERSION "1.2 public version"

new g_iCredits[MAXPLAYERS+1];


new Handle:cvarCreditsMax = INVALID_HANDLE;
new Handle:cvarCreditsKill = INVALID_HANDLE;
new Handle:cvarCreditsSave = INVALID_HANDLE;

new activeOffset = -1;
new clip1Offset = -1;
new clip2Offset = -1;
new secAmmoTypeOffset = -1;
new priAmmoTypeOffset = -1;

new Handle:cvarInterval;
new Handle:AmmoTimer;


new Handle:c_GameCredits = INVALID_HANDLE;


public Plugin:myinfo =
{
    name = "SM Franug Jail Awards",
    author = "Franc1sco steam: franug",
    description = "For buy awards in jail",
    version = VERSION,
    url = "http://servers-cfg.foroactivo.com/"
};

public OnPluginStart()
{

    LoadTranslations("common.phrases");

    c_GameCredits = RegClientCookie("Credits", "Credits", CookieAccess_Private);
    
    // ======================================================================
    
    HookEvent("player_spawn", PlayerSpawn);
    HookEvent("player_death", PlayerDeath);
    //HookEvent("player_hurt", Event_hurt);
    //HookEvent("player_jump", PlayerJump);
    
    // ======================================================================
    
    RegConsoleCmd("sm_awards", DOMenu);
    RegConsoleCmd("sm_credits", VerCreditos);
    RegConsoleCmd("sm_revive", Resucitar);
    RegConsoleCmd("sm_medic", Curarse);

    RegAdminCmd("sm_setcredits", FijarCreditos, ADMFLAG_ROOT);
    
    // ======================================================================
    
    // ======================================================================
    
    cvarCreditsMax = CreateConVar("awards_credits_max", "100", "max of credits allowed (0: No limit)");
    cvarCreditsKill = CreateConVar("awards_credits_kill", "1", "credits for kill");
    cvarCreditsSave = CreateConVar("awards_credits_save", "1", "enable or disable that credits can be saved");
    

    // unlimited ammo by http://forums.alliedmods.net/showthread.php?t=107900
    cvarInterval = CreateConVar("ammo_interval", "5", "How often to reset ammo (in seconds).", _, true, 1.0);

    activeOffset = FindSendPropOffs("CAI_BaseNPC", "m_hActiveWeapon");
    CreateConVar("sm_jailawards_version", VERSION, "plugin info", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
    clip1Offset = FindSendPropOffs("CBaseCombatWeapon", "m_iClip1");
    clip2Offset = FindSendPropOffs("CBaseCombatWeapon", "m_iClip2");
	
    priAmmoTypeOffset = FindSendPropOffs("CBaseCombatWeapon", "m_iPrimaryAmmoCount");
    secAmmoTypeOffset = FindSendPropOffs("CBaseCombatWeapon", "m_iSecondaryAmmoCount");
	

    if(GetConVarBool(cvarCreditsSave))
    	for(new client = 1; client <= MaxClients; client++)
    	{
		if(IsClientInGame(client))
		{
			if(AreClientCookiesCached(client))
			{
				OnClientCookiesCached(client);
			}
		}
   	}
}

public OnPluginEnd()
{
	if(!GetConVarBool(cvarCreditsSave))
		return;

	for(new client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			OnClientDisconnect(client);
		}
	}
}

public OnClientCookiesCached(client)
{
	if(!GetConVarBool(cvarCreditsSave))
		return;

	new String:CreditsString[12];
	GetClientCookie(client, c_GameCredits, CreditsString, sizeof(CreditsString));
	g_iCredits[client]  = StringToInt(CreditsString);
}

public OnClientDisconnect(client)
{
	if(!GetConVarBool(cvarCreditsSave))
	{
		g_iCredits[client] = 0;
		return;
	}

	if(AreClientCookiesCached(client))
	{
		new String:CreditsString[12];
		Format(CreditsString, sizeof(CreditsString), "%i", g_iCredits[client]);
		SetClientCookie(client, c_GameCredits, CreditsString);
	}
}

public OnConfigsExecuted()
{


	PrecacheModel("models/props/de_train/barrel.mdl");

	PrecacheModel("models/pigeon.mdl");

	PrecacheModel("models/crow.mdl");


	if (AmmoTimer != INVALID_HANDLE) {
		KillTimer(AmmoTimer);
	}
	new Float:interval = GetConVarFloat(cvarInterval);
	AmmoTimer = CreateTimer(interval, ResetAmmo, _, TIMER_REPEAT);
}


public Action:MensajesSpawn(Handle:timer, any:client)
{
 if (IsClientInGame(client))
 {
   PrintToChat(client, "\x04[SM_JailAwards] \x05Kill players to get credits");
   PrintToChat(client, "\x04[SM_JailAwards] \x05Type \x03!awards \x05to spend your credits on prizes");
 }
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    new client = GetClientOfUserId(GetEventInt(event, "userid"));

    CreateTimer(2.0, MensajesMuerte, client);
    
    if (!attacker)
        return;

    if (attacker == client)
        return;
    
    g_iCredits[attacker] += GetConVarInt(cvarCreditsKill);
    
    if (g_iCredits[attacker] < GetConVarInt(cvarCreditsMax))
    {
        PrintToChat(attacker, "\x04[SM_JailAwards] \x05Your credits: %i (+%i)", g_iCredits[attacker],GetConVarInt(cvarCreditsKill));
    }
    else
    {
        g_iCredits[attacker] = GetConVarInt(cvarCreditsMax);
        PrintToChat(attacker, "\x04[SM_JailAwards] \x05Your credits: %i (Maximum allowed)", g_iCredits[attacker]);
    }
}

public Action:MensajesMuerte(Handle:timer, any:client)
{
 if (IsClientInGame(client))
 {
   PrintToChat(client, "\x04[SM_JailAwards] \x05You died, now you can use \x03!revive \x05for revive (4 credits required)");
 }
}

public Action:VerCreditos(client, args)
{
	if(client == 0)
	{
		PrintToServer("%t","Command is in-game only");
		return;
	}
        PrintToChat(client, "\x04[SM_JailAwards] \x05Your current credits are: %i", g_iCredits[client]);
}

public Action:DOMenu(client,args)
{
	if(client == 0)
	{
		PrintToServer("%t","Command is in-game only");
		return;
	}
    	DID(client);
   	PrintToChat(client, "\x04[SM_JailAwards] \x05Your credits: %i", g_iCredits[client]);
}

public Action:Resucitar(client,args)
{
	if(client == 0)
	{
		PrintToServer("%t","Command is in-game only");
		return;
	}

	if (GetClientTeam(client) == 2 || GetClientTeam(client) == 3)
		{
		if (!IsPlayerAlive(client))
			{
				if (g_iCredits[client] >= 4)
				{

						CS_RespawnPlayer(client);

						g_iCredits[client] -= 4;

						decl String:nombre[32];
						GetClientName(client, nombre, sizeof(nombre));

						PrintToChatAll("\x04[SM_JailAwards] \x05The player\x03 %s \x05has revived!", nombre);
						PrintCenterTextAll("The player %s has revived!", nombre);

				}
				else
				{
					PrintToChat(client, "\x04[SM_JailAwards] \x05Your credits: %i (Not have enough credit to revive! Need 4)", g_iCredits[client]);
				}
			}
			else
			{
				PrintToChat(client, "\x04[SM_JailAwards] \x05Must be dead to use!");
			}
		}
		else
		{
			PrintToChat(client, "\x04[SM_JailAwards] \x05Spectators can't revive!");
		}
}

public Action:Curarse(client,args)
{
	if(client == 0)
	{
		PrintToServer("%t","Command is in-game only");
		return;
	}

	if (IsPlayerAlive(client))
        {
              if (g_iCredits[client] >= 1)
              {

                      SetEntityHealth(client, 100);

                      g_iCredits[client] -= 1;

                      //EmitSoundToAll("medicsound/medic.wav");


                      decl String:nombre[32];
                      GetClientName(client, nombre, sizeof(nombre));

                      PrintToChatAll("\x04[SM_JailAwards] \x05The player\x03 %s \x05has healed!", nombre);

                      PrintToChat(client, "\x04[SM_JailAwards] \x05You are cured. Your credits: %i (-1)", g_iCredits[client]);

              }
              else
              {
                 PrintToChat(client, "\x04[SM_JailAwards] \x05Your credits: %i (Not have enough credit to revive! Need 1)", g_iCredits[client]);
              }
        }
        else
        {
            PrintToChat(client, "\x04[SM_JailAwards] \x05But if you're dead...!!");
        }
}

public Action:DID(clientId) 
{
    new Handle:menu = CreateMenu(DIDMenuHandler);
    SetMenuTitle(menu, "Awards of store. Your credits: %i", g_iCredits[clientId]);
    AddMenuItem(menu, "option1", "View information on the plugin");
    AddMenuItem(menu, "option5", "Be invisible - 10 Credits");
    AddMenuItem(menu, "option6", "Buy AWP - 9  Credits");
    AddMenuItem(menu, "option7", "Becoming a barrel  - 8 Credits");
    AddMenuItem(menu, "option8", "INMORTAL 20 seconds - 7  Credits");
    AddMenuItem(menu, "option9", "Infinite ammo - 6  Credits");
    AddMenuItem(menu, "option10", "More speed - 5  Credits");
    AddMenuItem(menu, "option11", "Becoming BIRD - 5  Credits");
    AddMenuItem(menu, "option12", "Have 200 HP - 4  Credits");
    AddMenuItem(menu, "option13", "Buy USP pistol - 2  Credits");
    AddMenuItem(menu, "option14", "Buy Flashbang - 1  Credits");
    AddMenuItem(menu, "option15", "Healing - 1  Credits");
    AddMenuItem(menu, "option16", "Buy knife - 1  Credits");
    SetMenuExitButton(menu, true);
    DisplayMenu(menu, clientId, MENU_TIME_FOREVER);
    
    
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
            {
              DID(client);
              PrintToChat(client,"\x04[SM_JailAwards] \x05Kill players for win credits.");
              //PrintToChat(client, "\x04[SM_JailAwards] \x05Version:\x03 %s \x05created for SourceMod.", VERSION);
            }
            
        }


        
        else if ( strcmp(info,"option5") == 0 ) 
        {
            {
              DID(client);
              if (g_iCredits[client] >= 10)
              {
                   if (IsPlayerAlive(client))
                   {
                      SetEntityRenderMode(client, RENDER_TRANSCOLOR);
                      SetEntityRenderColor(client, 255, 255, 255, 0);

                      g_iCredits[client] -= 10;

                      PrintToChat(client, "\x04[SM_JailAwards] \x05Now you are invisible! Your credits: %i (-10)", g_iCredits[client]);
                   }
                   else
                   {
                      PrintToChat(client, "\x04[SM_JailAwards] \x05You have to be alive to buy prizes");
                   }
              }
              else
              {
                 PrintToChat(client, "\x04[SM_JailAwards] \x05Your credits: %i (Not have enough credit! Need 10)", g_iCredits[client]);
              }
            }
            
        }

        else if ( strcmp(info,"option6") == 0 ) 
        {
            {
              DID(client);
              if (g_iCredits[client] >= 9)
              {
                   if (IsPlayerAlive(client))
                   {

                      GivePlayerItem(client, "weapon_awp");

                      g_iCredits[client] -= 9;

                      PrintToChat(client, "\x04[SM_JailAwards] \x05Now you have a AWP! Your credits: %i (-9)", g_iCredits[client]);
                   }
                   else
                   {
                      PrintToChat(client, "\x04[SM_JailAwards] \x05You have to be alive to buy prizes");
                   }
              }
              else
              {
                 PrintToChat(client, "\x04[SM_JailAwards] \x05Your credits: %i (Not have enough credit! Need 9)", g_iCredits[client]);
              }
            }
            
        }

        else if ( strcmp(info,"option7") == 0 ) 
        {
            {
              DID(client);
              if (g_iCredits[client] >= 8)
              {
                   if (IsPlayerAlive(client))
                   {

                      SetEntityModel(client, "models/props/de_train/barrel.mdl");

                      g_iCredits[client] -= 8;

                      PrintToChat(client, "\x04[SM_JailAwards] \x05Now you are a Barrel! Your credits: %i (-8)", g_iCredits[client]);
                   }
                   else
                   {
                      PrintToChat(client, "\x04[SM_JailAwards] \x05You have to be alive to buy prizes");
                   }
              }
              else
              {
                 PrintToChat(client, "\x04[SM_JailAwards] \x05Your credits: %i (Not have enough credit! Need 8)", g_iCredits[client]);
              }
            }
            
        }

        else if ( strcmp(info,"option8") == 0 ) 
        {
            {
              DID(client);
              if (g_iCredits[client] >= 7)
              {
                   if (IsPlayerAlive(client))
                   {

                      g_Godmode[client] = true;
                      SetEntityRenderColor(client, 0, 255, 255, 255);
                      CreateTimer(10.0, OpcionNumero16b, client);

                      g_iCredits[client] -= 7;

                      PrintToChat(client, "\x04[SM_JailAwards] \x05Now you are inmortal for 20 seconds! Your credits: %i (-7)", g_iCredits[client]);
                   }
                   else
                   {
                      PrintToChat(client, "\x04[SM_JailAwards] \x05You have to be alive to buy prizes");
                   }
              }
              else
              {
                 PrintToChat(client, "\x04[SM_JailAwards] \x05Your credits: %i (Not have enough credit! Need 7)", g_iCredits[client]);
              }
            }
            
        }

        else if ( strcmp(info,"option9") == 0 ) 
        {
            {
              DID(client);
              if (g_iCredits[client] >= 6)
              {
                   if (IsPlayerAlive(client))
                   {

                      g_AmmoInfi[client] = true;

                      g_iCredits[client] -= 6;

                      PrintToChat(client, "\x04[SM_JailAwards] \x05Now you have infinite ammo! Your credits: %i (-6)", g_iCredits[client]);
                   }
                   else
                   {
                      PrintToChat(client, "\x04[SM_JailAwards] \x05You have to be alive to buy prizes");
                   }
              }
              else
              {
                 PrintToChat(client, "\x04[SM_JailAwards] \x05Your credits: %i (Not have enough credit! Need 6)", g_iCredits[client]);
              }
            }
            
        }

        else if ( strcmp(info,"option10") == 0 ) 
        {
            {
              DID(client);
              if (g_iCredits[client] >= 5)
              {
                   if (IsPlayerAlive(client))
                   {

                      SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.3);

                      g_iCredits[client] -= 5;

                      PrintToChat(client, "\x04[SM_JailAwards] \x05Now you have more speed! Your credits: %i (-5)", g_iCredits[client]);
                   }
                   else
                   {
                      PrintToChat(client, "\x04[SM_JailAwards] \x05You have to be alive to buy prizes");
                   }
              }
              else
              {
                 PrintToChat(client, "\x04[SM_JailAwards] \x05Your credits: %i (Not have enough credit! Need 5)", g_iCredits[client]);
              }
            }
            
        }

        else if ( strcmp(info,"option11") == 0 ) 
        {
            {
              DID(client);
              if (g_iCredits[client] >= 5)
              {
                   if (IsPlayerAlive(client))
                   {

                      SetEntityMoveType(client, MOVETYPE_FLY);

                      if (GetClientTeam(client) == CS_TEAM_CT)
                      {
                          SetEntityModel(client, "models/pigeon.mdl");
                      }
                      else
                      {
                          SetEntityModel(client, "models/crow.mdl");
                      }

                      new wepIdx;

                      // strip all weapons
                      for (new s = 0; s < 4; s++)
                      {
	                 if ((wepIdx = GetPlayerWeaponSlot(client, s)) != -1)
	                 {
		                 RemovePlayerItem(client, wepIdx);
		                 RemoveEdict(wepIdx);
	                 }
                      }

                      GivePlayerItem(client, "weapon_knife");

                      g_Fly[client] = true;

                      g_iCredits[client] -= 5;

                      PrintToChat(client, "\x04[SM_JailAwards] \x05Now you are a bird and you can fly! Your credits: %i (-5)", g_iCredits[client]);
                   }
                   else
                   {
                      PrintToChat(client, "\x04[SM_JailAwards] \x05You have to be alive to buy prizes");
                   }
              }
              else
              {
                 PrintToChat(client, "\x04[SM_JailAwards] \x05Your credits: %i (Not have enough credit! Need 5)", g_iCredits[client]);
              }
            }
            
        }


        else if ( strcmp(info,"option12") == 0 ) 
        {
            {
              DID(client);
              if (g_iCredits[client] >= 4)
              {
                   if (IsPlayerAlive(client))
                   {

                      SetEntityHealth(client, 200);

                      g_iCredits[client] -= 4;

                      PrintToChat(client, "\x04[SM_JailAwards] \x05Now you have 200 HP! Your credits: %i (-4)", g_iCredits[client]);
                   }
                   else
                   {
                      PrintToChat(client, "\x04[SM_JailAwards] \x05You have to be alive to buy prizes");
                   }
              }
              else
              {
                 PrintToChat(client, "\x04[SM_JailAwards] \x05Your credits: %i (Not have enough credit! Need 4)", g_iCredits[client]);
              }
            }
            
        }


        else if ( strcmp(info,"option13") == 0 ) 
        {
            {
              DID(client);
              if (g_iCredits[client] >= 2)
              {
                   if (IsPlayerAlive(client))
                   {

                      GivePlayerItem(client, "weapon_usp");

                      g_iCredits[client] -= 2;

                      PrintToChat(client, "\x04[SM_JailAwards] \x05You bought a USP pistol! Your credits: %i (-2)", g_iCredits[client]);
                   }
                   else
                   {
                      PrintToChat(client, "\x04[SM_JailAwards] \x05You have to be alive to buy prizes");
                   }

              }
              else
              {
                 PrintToChat(client, "\x04[SM_JailAwards] \x05Your credits: %i (Not have enough credit! Need 2)", g_iCredits[client]);
              }
            }
            
        }

        else if ( strcmp(info,"option14") == 0 ) 
        {
            {
              DID(client);
              if (g_iCredits[client] >= 1)
              {
                   if (IsPlayerAlive(client))
                   {

                      GivePlayerItem(client, "weapon_flashbang");

                      g_iCredits[client] -= 1;

                      PrintToChat(client, "\x04[SM_JailAwards] \x05You bought a flashbang! Your credits: %i (-1)", g_iCredits[client]);
                   }
                   else
                   {
                      PrintToChat(client, "\x04[SM_JailAwards] \x05You have to be alive to buy prizes");
                   }

              }
              else
              {
                 PrintToChat(client, "\x04[SM_JailAwards] \x05Your credits: %i (Not have enough credit! Need 1)", g_iCredits[client]);
              }
            }
            
        }

        else if ( strcmp(info,"option15") == 0 ) 
        {
            {
              DID(client);
              if (g_iCredits[client] >= 1)
              {
                   if (IsPlayerAlive(client))
                   {

                      SetEntityHealth(client, 100);

                      g_iCredits[client] -= 1;

                      EmitSoundToAll("medicsound/medic.wav");


                      decl String:nombre[32];
                      GetClientName(client, nombre, sizeof(nombre));

                      PrintToChatAll("\x04[SM_JailAwards] \x05The player\x03 %s \x05has healed!", nombre);

                      PrintToChat(client, "\x04[SM_JailAwards] \x05You are cured. Your credits: %i (-1)", g_iCredits[client]);


                   }
                   else
                   {
                      PrintToChat(client, "\x04[SM_JailAwards] \x05You have to be alive to buy prizes");
                   }

              }
              else
              {
                 PrintToChat(client, "\x04[SM_JailAwards] \x05Your credits: %i (Not have enough credit! Need 1)", g_iCredits[client]);
              }
            }
            
        }

        else if ( strcmp(info,"option16") == 0 ) 
        {
            {
              DID(client);
              if (g_iCredits[client] >= 1)
              {
                   if (IsPlayerAlive(client))
                   {

                      GivePlayerItem(client, "weapon_knife");

                      g_iCredits[client] -= 1;

                      PrintToChat(client, "\x04[SM_JailAwards] \x05You bought a knife! Your credits: %i (-1)", g_iCredits[client]);
                   }
                   else
                   {
                      PrintToChat(client, "\x04[SM_JailAwards] \x05You have to be alive to buy prizes");
                   }

              }
              else
              {
                 PrintToChat(client, "\x04[SM_JailAwards] \x05Your credits: %i (Not have enough credit! Need 1)", g_iCredits[client]);
              }
            }
            
        }

        else if ( strcmp(info,"option17") == 0 ) 
        {
            {
              DID(client);
              PrintToChat(client, "\x04[SM_JailAwards] \x05Your current credits are: %i", g_iCredits[client]);
            }
            
        }
       
    }
}

public Action:FijarCreditos(client, args)
{
    if(client == 0)
    {
		PrintToServer("%t","Command is in-game only");
		return Plugin_Handled;
    }

    if(args < 2) // Not enough parameters
    {
        ReplyToCommand(client, "[SM] Use: sm_setcredits <#userid|name> [amount]");
        return Plugin_Handled;
    }

    decl String:arg2[10];
    //GetCmdArg(1, arg, sizeof(arg));
    GetCmdArg(2, arg2, sizeof(arg2));

    new amount = StringToInt(arg2);
    //new target;

    //decl String:patt[MAX_NAME]

    //if(args == 1) 
    //{ 
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
			PrintToChat(client, "\x04[SM_JailAwards] \x05Set %i credits in the player %N", amount, iClient);
			LogMessage("%L set credits of %N to %i", client, iClient, amount);
        }
    } 
    //}  



//    SetEntProp(target, Prop_Data, "m_iDeaths", amount);


    return Plugin_Continue;
}


public Action:ResetAmmo(Handle:timer)
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientConnected(client) && !IsFakeClient(client) && IsClientInGame(client) && IsPlayerAlive(client) && (g_AmmoInfi[client]))
		{
			Client_ResetAmmo(client);
		}
	}
}

public Client_ResetAmmo(client)
{
	new zomg = GetEntDataEnt2(client, activeOffset);
	if (clip1Offset != -1 && zomg != -1)
		SetEntData(zomg, clip1Offset, 200, 4, true);
	if (clip2Offset != -1 && zomg != -1)
		SetEntData(zomg, clip2Offset, 200, 4, true);
	if (priAmmoTypeOffset != -1 && zomg != -1)
		SetEntData(zomg, priAmmoTypeOffset, 200, 4, true);
	if (secAmmoTypeOffset != -1 && zomg != -1)
		SetEntData(zomg, secAmmoTypeOffset, 200, 4, true);
}


public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
      if (g_Godmode[victim])
      {
               damage = 0.0;
               return Plugin_Changed;
      }
      return Plugin_Continue;
}

public Action:OnWeaponCanUse(client, weapon)
{
  if (g_Fly[client])
  {
      decl String:sClassname[32];
      GetEdictClassname(weapon, sClassname, sizeof(sClassname));
      if (!StrEqual(sClassname, "weapon_knife"))
          return Plugin_Handled;
  }
  return Plugin_Continue;
}

public OnClientPutInServer(client)
{
   SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
   SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

public OnClientPostAdminCheck(client)
{
    g_Godmode[client] = false;
    g_Fly[client] = false;
    g_AmmoInfi[client] = false;
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
  new client = GetClientOfUserId(GetEventInt(event, "userid"));

  if (GetClientTeam(client) == 1 && !IsPlayerAlive(client))
  {
         return;
  }

  CreateTimer(1.0, MensajesSpawn, client);




  if (g_Fly[client])
  {
    g_Fly[client] = false;
    SetEntityMoveType(client, MOVETYPE_WALK);
  }
  if (g_Godmode[client])
  {
    g_Godmode[client] = false;
  }
  if (g_AmmoInfi[client])
  {
    g_AmmoInfi[client] = false;
  }
}


public Action:OpcionNumero16b(Handle:timer, any:client)
{
 if ( (IsClientInGame(client)) && (IsPlayerAlive(client)) )
 {
   PrintToChat(client, "\x04[SM_JailAwards] \x05You have 10 seconds of invulnerability!");
   CreateTimer(10.0, OpcionNumero16c, client);
 }
}

public Action:OpcionNumero16c(Handle:timer, any:client)
{
 if ( (IsClientInGame(client)) && (IsPlayerAlive(client)) )
 {
   PrintToChat(client, "\x04[SM_JailAwards] \x05Now you are a mortal!");
   g_Godmode[client] = false;
   SetEntityRenderColor(client, 255, 255, 255, 255);
 }
}