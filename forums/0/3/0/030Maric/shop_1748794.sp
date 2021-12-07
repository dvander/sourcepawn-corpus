#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>
#include <cstrike>
#include <sdkhooks>
#include <smlib>
#pragma semicolon 1

new bool:g_Fly[MAXPLAYERS+1] = {false, ...};
new bool:g_Godmode[MAXPLAYERS+1] = {false, ...};
new bool:g_AmmoInfi[MAXPLAYERS+1] = {false, ...};


#define VERSION "1.0 public version"

new g_iCredits[MAXPLAYERS+1];


new Handle:cvarCreditsMax = INVALID_HANDLE;
new Handle:cvarCreditsKill = INVALID_HANDLE;

new activeOffset = -1;
new clip1Offset = -1;
new clip2Offset = -1;
new secAmmoTypeOffset = -1;
new priAmmoTypeOffset = -1;

new Handle:cvarInterval;
new Handle:AmmoTimer;

public Plugin:myinfo =
{
    name = "SM Franug Jail Awards",
    author = "Franc1sco steam: franug",
    description = "credits for kill zombies",
    version = VERSION,
    url = "http://servers-cfg.foroactivo.com/"
};

public OnPluginStart()
{
    
    // ======================================================================
    
    HookEvent("player_spawn", PlayerSpawn);
    HookEvent("player_death", PlayerDeath);
    //HookEvent("player_hurt", Event_hurt);
    //HookEvent("player_jump", PlayerJump);
    
    // ======================================================================
    
    RegConsoleCmd("sm_shop", DOMenu);
    RegConsoleCmd("sm_credits", VerCreditos);
    RegConsoleCmd("sm_revive", Resucitar);
    RegConsoleCmd("sm_medic", Curarse);

    RegAdminCmd("sm_setcredits", FijarCreditos, ADMFLAG_ROOT);
    
    // ======================================================================
    
    // ======================================================================
    
    cvarCreditsMax = CreateConVar("awards_credits_max", "150", "max of credits allowed (0: No limit)");
    cvarCreditsKill = CreateConVar("awards_credits_kill", "1", "credits for kill");
    

    // unlimited ammo by http://forums.alliedmods.net/showthread.php?t=107900
    cvarInterval = CreateConVar("ammo_interval", "5", "How often to reset ammo (in seconds).", _, true, 1.0);

    activeOffset = FindSendPropOffs("CAI_BaseNPC", "m_hActiveWeapon");
    CreateConVar("sm_jailawards_version", VERSION, "plugin info", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
    clip1Offset = FindSendPropOffs("CBaseCombatWeapon", "m_iClip1");
    clip2Offset = FindSendPropOffs("CBaseCombatWeapon", "m_iClip2");
	
    priAmmoTypeOffset = FindSendPropOffs("CBaseCombatWeapon", "m_iPrimaryAmmoCount");
    secAmmoTypeOffset = FindSendPropOffs("CBaseCombatWeapon", "m_iSecondaryAmmoCount");
	

    LoadTranslations("common.phrases");
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
   PrintToChat(client, "\x04[O30Z->shop] \x05Kill Zombies to get credits.");
   PrintToChat(client, "\x04[O30Z->shop] \x05Type \x03!shop \x05to spend your credits on prizes for 1 Round!");
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
        Client_PrintKeyHintText(attacker, "!shop & !revive\n    Your credits:\n      %i (+%i)", g_iCredits[attacker],GetConVarInt(cvarCreditsKill));
    }
    else
    {
        g_iCredits[attacker] = GetConVarInt(cvarCreditsMax);
        Client_PrintKeyHintText(attacker, "Use !shop      \n    Your credits:\n  %i (Maximum allowed)", g_iCredits[attacker]);
    }
}

public Action:MensajesMuerte(Handle:timer, any:client)
{
 if (IsClientInGame(client))
 {
   PrintToChat(client, "\x04[shop] \x05You died, now you can use \x03!revive \x05for revive (35 credits required)");
 }
}

public Action:VerCreditos(client, args)
    if(GetClientTeam(client) != 3)
{
        PrintToChat(client, "\x04[shop] \x05Your current credits are: %i", g_iCredits[client]);
}

public Action:DOMenu(client,args)
{
    if(GetClientTeam(client) != 3)
    {
         PrintToChat(client, "\x04[shop] \x05This is only for humans");
         return;
    }

    DID(client);    PrintToChat(client, "\x04[shop] \x05Your credits: %i", g_iCredits[client]);
}

public Action:Resucitar(client,args)
{
	if (!IsPlayerAlive(client))
        {
              if (g_iCredits[client] >= 35)
              {

                      CS_RespawnPlayer(client);

                      g_iCredits[client] -= 35;

                      decl String:nombre[32];
                      GetClientName(client, nombre, sizeof(nombre));

                      PrintToChatAll("\x04[shop] \x05The player\x03 %s \x05has revived!", nombre);
                      PrintCenterTextAll("The player %s has revived!", nombre);

              }
              else
              {
                 PrintToChat(client, "\x04[shop] \x05Your credits: %i (Not have enough credit to revive! Need 35)", g_iCredits[client]);
              }
        }
        else
        {
            PrintToChat(client, "\x04[shop] \x05Must be dead to use!");
        }
}

public Action:Curarse(client,args)
{
	if (IsPlayerAlive(client))
        {
              if (g_iCredits[client] >= 15)
              {

                      SetEntityHealth(client, 100);

                      g_iCredits[client] -= 15;

                      //EmitSoundToAll("medicsound/medic.wav");


                      decl String:nombre[32];
                      GetClientName(client, nombre, sizeof(nombre));

                      PrintToChatAll("\x04[shop] \x05The player\x03 %s \x05has healed!", nombre);

                      PrintToChat(client, "\x04[shop] \x05You are cured. Your credits: %i (-15)", g_iCredits[client]);

              }
              else
              {
                 PrintToChat(client, "\x04[shop] \x05Your credits: %i (Not have enough credit to revive! Need 15)", g_iCredits[client]);
              }
        }
        else
        {
            PrintToChat(client, "\x04[shop] \x05But if you're dead...!!");
        }
}

public Action:DID(clientId) 
{
    new Handle:menu = CreateMenu(DIDMenuHandler);
    SetMenuTitle(menu, "[shop](ONLY 1 ROUND). Your credits: %i", g_iCredits[clientId]);
    AddMenuItem(menu, "option1", "View information on the plugin");
    AddMenuItem(menu, "option2", "Healing - 15  Credits");
    AddMenuItem(menu, "option3", "Be invisible - 25 Credits");
    AddMenuItem(menu, "option4", "Buy AWP - 5  Credits");
    AddMenuItem(menu, "option5", "Becoming a barrel skin  - 25 Credits");
    AddMenuItem(menu, "option6", "GodMode for 20 seconds - 35  Credits");
    AddMenuItem(menu, "option7", "Have 200 HP - 30  Credits");
    AddMenuItem(menu, "option8", "Buy Ak47 - 8  Credits");
    AddMenuItem(menu, "option9", "Buy Grenade - 15  Credits");
    AddMenuItem(menu, "option10", "Becoming a Zombie skin  - 80 Credits");
    AddMenuItem(menu, "option11", "FLY whit p90 - 100  Credits");
    AddMenuItem(menu, "option12", "Infinite ammo - 120  Credits");
    AddMenuItem(menu, "option13", "Molotov Cocktail - 25  Credits");
    AddMenuItem(menu, "option14", "T-Bighead model - 40  Credits");
    AddMenuItem(menu, "option15", "CT-Bighead model - 40  Credits");
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
              PrintToChat(client,"\x04[shop] \x05Kill Zombies for win credits.");
              //PrintToChat(client, "\x04[shop] \x05Version:\x03 %s \x05created for SourceMod.", VERSION);
            }
            
        }

        else if ( strcmp(info,"option2") == 0 ) 
        {
            {
              DID(client);
              if (g_iCredits[client] >= 20)
              {
                   if (IsPlayerAlive(client))
                   {

                      SetEntityHealth(client, 100);

                      g_iCredits[client] -= 20;

                      EmitSoundToAll("medicsound/medic.wav");


                      decl String:nombre[32];
                      GetClientName(client, nombre, sizeof(nombre));

                      PrintToChatAll("\x04[shop] \x05The player\x03 %s \x05has healed!", nombre);

                      PrintToChat(client, "\x04[shop] \x05You are cured. Your credits: %i (-20)", g_iCredits[client]);


                   }
                   else
                   {
                      PrintToChat(client, "\x04[shop] \x05You have to be alive to buy prizes");
                   }

              }
              else
              {
                 PrintToChat(client, "\x04[shop] \x05Your credits: %i (Not have enough credit! Need 20)", g_iCredits[client]);
              }
            }
            
        }
        
        else if ( strcmp(info,"option3") == 0 ) 
        {
            {
              DID(client);
              if (g_iCredits[client] >= 25)
              {
                   if (IsPlayerAlive(client))
                   {
                      SetEntityRenderMode(client, RENDER_TRANSCOLOR);
                      SetEntityRenderColor(client, 255, 255, 255, 0);

                      g_iCredits[client] -= 25;

                      PrintToChat(client, "\x04[shop] \x05Now you are invisible! Your credits: %i (-25)", g_iCredits[client]);
                   }
                   else
                   {
                      PrintToChat(client, "\x04[shop] \x05You have to be alive to buy prizes");
                   }
              }
              else
              {
                 PrintToChat(client, "\x04[shop] \x05Your credits: %i (Not have enough credit! Need 25)", g_iCredits[client]);
              }
            }
            
        }

        else if ( strcmp(info,"option4") == 0 ) 
        {
            {
              DID(client);
              if (g_iCredits[client] >= 5)
              {
                   if (IsPlayerAlive(client))
                   {

                      GivePlayerItem(client, "weapon_awp");

                      g_iCredits[client] -= 5;

                      PrintToChat(client, "\x04[shop] \x05Now you have a AWP! Your credits: %i (-5)", g_iCredits[client]);
                   }
                   else
                   {
                      PrintToChat(client, "\x04[shop] \x05You have to be alive to buy prizes");
                   }
              }
              else
              {
                 PrintToChat(client, "\x04[shop] \x05Your credits: %i (Not have enough credit! Need 5)", g_iCredits[client]);
              }
            }
            
        }

        else if ( strcmp(info,"option5") == 0 ) 
        {
            {
              DID(client);
              if (g_iCredits[client] >= 25)
              {
                   if (IsPlayerAlive(client))
                   {

                      SetEntityModel(client, "models/props/de_train/barrel.mdl");

                      g_iCredits[client] -= 25;

                      PrintToChat(client, "\x04[shop] \x05Now you are a Barrel! Your credits: %i (-25)", g_iCredits[client]);
                   }
                   else
                   {
                      PrintToChat(client, "\x04[shop] \x05You have to be alive to buy prizes");
                   }
              }
              else
              {
                 PrintToChat(client, "\x04[shop] \x05Your credits: %i (Not have enough credit! Need 25)", g_iCredits[client]);
              }
            }
            
        }

        else if ( strcmp(info,"option6") == 0 ) 
        {
            {
              DID(client);
              if (g_iCredits[client] >= 35)
              {
                   if (IsPlayerAlive(client))
                   {

                      g_Godmode[client] = true;
                      SetEntityRenderColor(client, 0, 255, 255, 255);
                      CreateTimer(10.0, OpcionNumero16b, client);

                      g_iCredits[client] -= 35;

                      PrintToChat(client, "\x04[shop] \x05Now you are in GODMODE for 20 seconds! Your credits: %i (-35)", g_iCredits[client]);
                   }
                   else
                   {
                      PrintToChat(client, "\x04[shop] \x05You have to be alive to buy prizes");
                   }
              }
              else
              {
                 PrintToChat(client, "\x04[shop] \x05Your credits: %i (Not have enough credit! Need 35)", g_iCredits[client]);
              }
            }
            
        }

        else if ( strcmp(info,"option7") == 0 ) 
        {
            {
              DID(client);
              if (g_iCredits[client] >= 30)
              {
                   if (IsPlayerAlive(client))
                   {

                      SetEntityHealth(client, 200);

                      g_iCredits[client] -= 30;

                      PrintToChat(client, "\x04[shop] \x05Now you have 200 HP! Your credits: %i (-30)", g_iCredits[client]);
                   }
                   else
                   {
                      PrintToChat(client, "\x04[shop] \x05You have to be alive to buy prizes");
                   }
              }
              else
              {
                 PrintToChat(client, "\x04[shop] \x05Your credits: %i (Not have enough credit! Need 30)", g_iCredits[client]);
              }
            }
            
        }

        else if ( strcmp(info,"option8") == 0 ) 
        {
            {
              DID(client);
              if (g_iCredits[client] >= 8)
              {
                   if (IsPlayerAlive(client))
                   {

                      GivePlayerItem(client, "weapon_ak47");

                      g_iCredits[client] -= 8;

                      PrintToChat(client, "\x04[shop] \x05You bought a Ak47! Your credits: %i (-8)", g_iCredits[client]);
                   }
                   else
                   {
                      PrintToChat(client, "\x04[shop] \x05You have to be alive to buy prizes");
                   }

              }
              else
              {
                 PrintToChat(client, "\x04[shop] \x05Your credits: %i (Not have enough credit! Need 8)", g_iCredits[client]);
              }
            }
            
        }

	 else if ( strcmp(info,"option9") == 0 ) 
        {
            {
              DID(client);
              if (g_iCredits[client] >= 15)
              {
                   if (IsPlayerAlive(client))
                   {

                      GivePlayerItem(client, "weapon_hegrenade");

                      g_iCredits[client] -= 15;

                      PrintToChat(client, "\x04[shop] \x05You bought a hegreande! Your credits: %i (-15)", g_iCredits[client]);
                   }
                   else
                   {
                      PrintToChat(client, "\x04[shop] \x05You have to be alive to buy prizes");
                   }

              }
              else
              {
                 PrintToChat(client, "\x04[shop] \x05Your credits: %i (Not have enough credit! Need 15)", g_iCredits[client]);
              }
            }
            
        }

	 else if ( strcmp(info,"option10") == 0 ) 
        {
            {
              DID(client);
              if (g_iCredits[client] >= 80)
              {
                   if (IsPlayerAlive(client))
                   {

                      SetEntityModel(client, "models/player/techknow/zp/z2.mdl");

                      g_iCredits[client] -= 80;

                      PrintToChat(client, "\x04[shop] \x05Now you are a Zombie! Your credits: %i (-80)", g_iCredits[client]);
                   }
                   else
                   {
                      PrintToChat(client, "\x04[shop] \x05You have to be alive to buy prizes");
                   }
              }
              else
              {
                 PrintToChat(client, "\x04[shop] \x05Your credits: %i (Not have enough credit! Need 80)", g_iCredits[client]);
              }
            }
            
        }

	 else if ( strcmp(info,"option11") == 0 ) 
        {
            {
              DID(client);
              if (g_iCredits[client] >= 120)
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

                      GivePlayerItem(client, "weapon_p90");

                      g_Fly[client] = true;

                      g_iCredits[client] -= 100;

                      PrintToChat(client, "\x04[shop] \x05Now you are a bird and you can fly! Your credits: %i (-100)", g_iCredits[client]);
                   }
                   else
                   {
                      PrintToChat(client, "\x04[shop] \x05You have to be alive to buy prizes");
                   }
              }
              else
              {
                 PrintToChat(client, "\x04[shop] \x05Your credits: %i (Not have enough credit! Need 100)", g_iCredits[client]);
              }
            }
            
        }

	 else if ( strcmp(info,"option12") == 0 ) 
        {
            {
              DID(client);
              if (g_iCredits[client] >= 120)
              {
                   if (IsPlayerAlive(client))
                   {

                      g_AmmoInfi[client] = true;

                      g_iCredits[client] -= 120;

                      PrintToChat(client, "\x04[shop] \x05Now you have infinite ammo! Your credits: %i (-120)", g_iCredits[client]);
                   }
                   else
                   {
                      PrintToChat(client, "\x04[shop] \x05You have to be alive to buy prizes");
                   }
              }
              else
              {
                 PrintToChat(client, "\x04[shop] \x05Your credits: %i (Not have enough credit! Need 120)", g_iCredits[client]);
              }
            }
            
        }

	 else if ( strcmp(info,"option13") == 0 ) 
        {
            {
              DID(client);
              if (g_iCredits[client] >= 25)
              {
                   if (IsPlayerAlive(client))
                   {

                      GivePlayerItem(client, "weapon_flashbang");

                      g_iCredits[client] -= 25;

                      PrintToChat(client, "\x04[shop] \x05You bought a MoletovCocktail! Your credits: %i (-25)", g_iCredits[client]);
                   }
                   else
                   {
                      PrintToChat(client, "\x04[shop] \x05You have to be alive to buy prizes");
                   }

              }
              else
              {
                 PrintToChat(client, "\x04[shop] \x05Your credits: %i (Not have enough credit! Need 25)", g_iCredits[client]);
              }
            }
            
        }

	 else if ( strcmp(info,"option14") == 0 ) 
        {
            {
              DID(client);
              if (g_iCredits[client] >= 40)
              {
                   if (IsPlayerAlive(client))
                   {

                      SetEntityModel(client, "models/player/knifelemon/bighead/t_phoenix.mdl");

                      g_iCredits[client] -= 40;

                      PrintToChat(client, "\x04[shop] \x05Now you are a Terrorist BigHead model! Your credits: %i (-40)", g_iCredits[client]);
                   }
                   else
                   {
                      PrintToChat(client, "\x04[shop] \x05You have to be alive to buy prizes");
                   }
              }
              else
              {
                 PrintToChat(client, "\x04[shop] \x05Your credits: %i (Not have enough credit! Need 40)", g_iCredits[client]);
              }
            }
            
        }

	 else if ( strcmp(info,"option15") == 0 ) 
        {
            {
              DID(client);
              if (g_iCredits[client] >= 40)
              {
                   if (IsPlayerAlive(client))
                   {

                      SetEntityModel(client, "models/player/knifelemon/bighead/ct_gign.mdl");

                      g_iCredits[client] -= 40;

                      PrintToChat(client, "\x04[shop] \x05Now you are a Couter Terrorist BigHEAD model! Your credits: %i (-40)", g_iCredits[client]);
                   }
                   else
                   {
                      PrintToChat(client, "\x04[shop] \x05You have to be alive to buy prizes");
                   }
              }
              else
              {
                 PrintToChat(client, "\x04[shop] \x05Your credits: %i (Not have enough credit! Need 40)", g_iCredits[client]);
              }
            }
            
        }

        else if ( strcmp(info,"option16") == 0 ) 
        {
            {
              DID(client);
              PrintToChat(client, "\x04[shop] \x05Your current credits are: %i", g_iCredits[client]);
            }
            
        }
       
    }
}
public Action:FijarCreditos(client, args)
{
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
              PrintToChat(client, "\x04[shop-admin] \x05Set %i credits in the player %N", amount, iClient);
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
    g_iCredits[client] = 0;
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
   PrintToChat(client, "\x04[Aw] \x05You have 10 seconds of invulnerability!");
   CreateTimer(10.0, OpcionNumero16c, client);
 }
}

public Action:OpcionNumero16c(Handle:timer, any:client)
{
 if ( (IsClientInGame(client)) && (IsPlayerAlive(client)) )
 {
   PrintToChat(client, "\x04[Aw \x05Now you are a mortal!");
   g_Godmode[client] = false;
   SetEntityRenderColor(client, 255, 255, 255, 255);
 }
}