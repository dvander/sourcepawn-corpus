#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <adminmenu>
#include <sdkhooks>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

new ID,
	OffsetCollision,
	g_AFKwarnings[MAXPLAYERS+1],
	g_LastItem[MAXPLAYERS+1],
	g_TargetId[MAXPLAYERS+1],
	ClientTeam[MAXPLAYERS+1],
	Float:g_iAfkStartPositions[MAXPLAYERS+1][3],
	Float:g_iMyStartPositions[MAXPLAYERS+1][3],
	Float:g_iKillTimeVictim[MAXPLAYERS+1],
	Float:g_iPositionNow[MAXPLAYERS+1][3],	
	Float:AdminOldPos[MAXPLAYERS+1][3],
	Float:g_iParavozTimeProtect = 1.3,
	Float:g_fRemoveRadgollDelay,
	Float:g_fRespawnDelay,
	Float:g_fProtectTime,
	Handle:g_iActiveCollision = INVALID_HANDLE,
	Handle:g_iActiveFixer35hp = INVALID_HANDLE,	
	Handle:g_iActiveBlockBack = INVALID_HANDLE,
	Handle:g_iActiveBlockParo = INVALID_HANDLE,
	Handle:g_iActiveBlockTolp = INVALID_HANDLE,
	Handle:g_iActiveColorAFK = INVALID_HANDLE,
	Handle:g_iActiveColorPar = INVALID_HANDLE,
	Handle:g_iActiveKnifeDM = INVALID_HANDLE,
	Handle:Timer_Respawn[MAXPLAYERS+1] = {INVALID_HANDLE, ... },
	Handle:Timer_Protect[MAXPLAYERS+1] = {INVALID_HANDLE, ... },
	Handle:g_hPanel[MAXPLAYERS + 1] = {INVALID_HANDLE, ...},
	Handle:g_hPanelScripts[MAXPLAYERS + 1] = {INVALID_HANDLE, ...},	
	Handle:g_hTimer[MAXPLAYERS + 1] = {INVALID_HANDLE, ...},	
	Handle:g_iCheckAfkTimer[MAXPLAYERS+1],
	Handle:g_iRespawnTimer[MAXPLAYERS+1],
	Handle:g_iProtectTimer[MAXPLAYERS+1],
	bool:g_MyAFKprotectOn[MAXPLAYERS+1],
	bool:no_need_more[MAXPLAYERS + 1],
	bool:g_bRemoveRadgoll,
	String:Antiparavoz_sound[] = "resource/warning.wav",
	String:sClientVar[][] = 
{
	"rate",
	"cl_cmdrate",
	"cl_updaterate",
	"cl_interp",
	"cl_interp_ratio",
	"cl_interpolate",
	"cl_lagcompensation",
	"cl_predict",
	"cl_predictweapons",
	"cl_resend"
};


//============================================================================//


public Plugin:myinfo =
{
	name = "Knife Management",
	author = "raizo",
	version = PLUGIN_VERSION
};

public OnPluginStart()
{
	CreateConVar("sm_knife_management", PLUGIN_VERSION, "Knife Management Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);	
	
	g_iActiveCollision = CreateConVar("km_collision", "0", "enable / disable players collision");
	g_iActiveFixer35hp = CreateConVar("km_fixer35hp", "1", "enable / disable the issuance of 35 hp at spawn");
	g_iActiveBlockBack = CreateConVar("km_backstab", "1", "enable / disable the protection of the back players");
	g_iActiveBlockParo = CreateConVar("km_gangbang", "1", "enable / disable the protection against locomotive players");
	g_iActiveBlockTolp = CreateConVar("km_blocknoob", "0", "enable / disable the protection against mob players");
	g_iActiveColorAFK = CreateConVar("km_colorafk", "1", "enable / disable AFK render color");
	g_iActiveColorPar = CreateConVar("km_colorgang", "1", "enable / disable render after kill a enemy");	
	g_iActiveKnifeDM = CreateConVar("km_respawn", "0", "enable / disable KNIFE DEATHMATCH mode");

	new Handle:hCvar;	
	HookConVarChange((hCvar = CreateConVar("km_respawn_delay", "1.0", "After how many seconds a player reborn after death.")), OnRespawnDelayChange); 	g_fRespawnDelay = GetConVarFloat(hCvar);
	HookConVarChange((hCvar = CreateConVar("km_respawn_protect_time", "1.0", "How many seconds to protection after kill a enemy.")), OnProtectTimeChange);	g_fProtectTime = GetConVarFloat(hCvar);
	HookConVarChange((hCvar = CreateConVar("km_remove_bodie", "1", "Delete the bodies after death.")), OnRemoveRadgollChange);	g_bRemoveRadgoll = GetConVarBool(hCvar);
	HookConVarChange((hCvar = CreateConVar("km_remove_bodie_delay", "1.0", "After how many seconds remove bodies.")), OnRemoveRadgollDelayChange);	g_fRemoveRadgollDelay = GetConVarFloat(hCvar);
	CloseHandle(hCvar);
	
	AutoExecConfig(true, "knife_management");
	
	HookConVarChange(g_iActiveBlockTolp, Enable_Disable_BlockTolpa);
	HookEvent("player_hurt", ProtectClient, EventHookMode_Pre);	
	HookEvent("player_spawn", SpawnClient, EventHookMode_Post);
	HookEvent("player_death", DeathClient);
	HookEvent("player_team", PlayerTeam);	

	RegConsoleCmd("sm_rate", CheckManyRates);
	RegAdminCmd("sm_ratescr", CheckManyScripts, ADMFLAG_BAN);	
	RegAdminCmd("sm_knifebot", Knifebot, ADMFLAG_BAN);

	OffsetCollision = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
	
	if(OffsetCollision == -1)
	{
		SetFailState("[Knife Management] Failed to get OFFSet");
	}
}

public OnMapStart()
{
	PrecacheSound(Antiparavoz_sound, true);
}

public OnRespawnDelayChange(Handle:hCvar, const String:oldValue[], const String:newValue[])			g_fRespawnDelay = GetConVarFloat(hCvar);
public OnProtectTimeChange(Handle:hCvar, const String:oldValue[], const String:newValue[])			g_fProtectTime = GetConVarFloat(hCvar);
public OnRemoveRadgollChange(Handle:hCvar, const String:oldValue[], const String:newValue[])		g_bRemoveRadgoll = GetConVarBool(hCvar);
public OnRemoveRadgollDelayChange(Handle:hCvar, const String:oldValue[], const String:newValue[])	g_fRemoveRadgollDelay = GetConVarFloat(hCvar);
public Enable_Disable_BlockTolpa(Handle:hCvar, const String:oldValue[], const String:newValue[])
{
    if(GetConVarBool(hCvar))
    {
        for(new i = 1; i <= MaxClients; i++)
        {
            if(IsClientInGame(i)) 
			{
				SDKHook(i, SDKHook_PostThinkPost, OnPostThinkPost);
			}
        }
    }
    else
    {
        for(new i = 1; i <= MaxClients; i++)
        {
            SDKUnhook(i, SDKHook_PostThinkPost, OnPostThinkPost);
        }
    }
}  

public OnClientConnected(client)
{
	g_LastItem[client] = 0;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!no_need_more[client])
	{
		if ((buttons & IN_MOVELEFT)|(buttons & IN_MOVERIGHT)|(buttons & IN_BACK)|(buttons & IN_FORWARD))
		{
			no_need_more[client] = true;
			g_MyAFKprotectOn[client] = false;
			
			if(GetConVarBool(g_iActiveColorAFK) && !GetConVarBool(g_iActiveKnifeDM))
			{
				SetPlayerColor(client, 255, 255, 255, 255);
			}
		}
	}
	return Plugin_Continue;
}

public OnPostThinkPost(client)
{
    if(IsPlayerAlive(client))
    {
        GetClientAbsOrigin(client, g_iPositionNow[client]);
        static i, bool:respawn;
		
        for(i = respawn = true; i <= MaxClients; i++)
        {
            if(IsClientInGame(i) && IsPlayerAlive(i) && ClientTeam[client] != ClientTeam[i] && GetVectorDistance(g_iPositionNow[client], g_iPositionNow[i]) < 150)
            {
                if(respawn) respawn = false;
                else
				{
					respawn = true; 
					CS_RespawnPlayer(i); 
									}
            }
        }
    }
}  

SetPlayerColor(client, r, g, b, a)
{
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, r, g, b, a);
}

/*//============================================================================//
Knife Protection
*///============================================================================//

public Action:ProtectClient( Handle:event, const String:name[], bool:dontBroadcast )
{
	decl Float:GameTime, Float:origin[3];
	GameTime	= GetGameTime();

	new victim = GetClientOfUserId( GetEventInt( event, "userid" ) );
	new attacker = GetClientOfUserId( GetEventInt( event, "attacker" ) );
	
	decl String:weapon[64];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	
	if(StrEqual(weapon, "knife") || StrEqual(weapon, "knifegg"))
	{
		new Float:attacker_angles[3], Float:victim_angles[3], Float:back_angles[3];
	
		GetClientAbsAngles( victim, victim_angles );
		GetClientAbsAngles( attacker, attacker_angles );
	
		MakeVectorFromPoints( victim_angles, attacker_angles, back_angles );

		if(back_angles[1] > -90.0 && back_angles[1] < 90.0 && GetConVarBool(g_iActiveBlockBack))
		{
			EmitSoundToClient(attacker, Antiparavoz_sound);
			PrintCenterText(attacker, "[KNIFE MANAGEMENT] Do not hit in the back!");
			CS_RespawnPlayer(victim);
		}
		
		if(((GameTime - g_iKillTimeVictim[victim]) < g_iParavozTimeProtect) && GetConVarBool(g_iActiveBlockParo))
		{
			CS_RespawnPlayer(attacker);
			SetEntProp(victim, Prop_Data, "m_iHealth", 35);		
			PrintCenterText(attacker, "[KNIFE MANAGEMENT] No Locomotive!");
			EmitSoundToClient(attacker, Antiparavoz_sound);
		}		
	}
	
	if(g_MyAFKprotectOn[victim])
	{
		GetClientAbsOrigin(victim, origin);
		if (origin[0] == g_iMyStartPositions[victim][0] && origin[1] == g_iMyStartPositions[victim][1])
		{
			new victim_team = GetClientTeam(victim);
			for (new i = 1; i <= MaxClients; i++)
			{
				if (i != victim && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == victim_team && !g_MyAFKprotectOn[i] )
				{
					SetEntProp(victim, Prop_Data, "m_iHealth", 35);
					return Plugin_Continue;
				}
			}
		}
		g_MyAFKprotectOn[victim] = false;
	}

	if (g_MyAFKprotectOn[attacker])
	{
		g_MyAFKprotectOn[attacker] = false;

		GetClientAbsOrigin(attacker, origin);
		if (origin[0] == g_iMyStartPositions[attacker][0] && origin[1] == g_iMyStartPositions[attacker][1])
		{
			SetEntProp(victim, Prop_Data, "m_iHealth", 35);
			return Plugin_Continue;
		}
	}

	if (GetEventInt(event, "health") < 1) g_iKillTimeVictim[attacker] = GameTime;
	
	return Plugin_Continue;
}

public SpawnClient(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	g_iKillTimeVictim[client] = 0.0;
	g_MyAFKprotectOn[client] = true;
	no_need_more[client] = false;
	
	if(GetConVarBool(g_iActiveColorAFK))
	{
		SetPlayerColor(client, 0, 255, 0, 255);
	}
	
	// Fixer35hp
	GetClientAbsOrigin(client, g_iMyStartPositions[client]);
	
	if(GetConVarBool(g_iActiveFixer35hp))
	{	
		g_iRespawnTimer[client] = CreateTimer(0.2, Giver35hp, GetClientUserId(client));
	}
		
	// NoBlock	
	if(GetConVarBool(g_iActiveCollision))
	{
		SetEntData(client, OffsetCollision, 2, 4, true);
	}

	// KnifeDM by R1KO
	if(client > 0 && GetConVarBool(g_iActiveKnifeDM))
	{
		if(IsPlayerAlive(client))
		{
			SetEntProp(client, Prop_Data, "m_takedamage", 0);
			Timer_Protect[client] = CreateTimer(g_fProtectTime, ProtectTimer_CallBack, client);
		}
	}
}

public Action:Giver35hp(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	new m_iHealth = GetEntProp(client, Prop_Data, "m_iHealth");
	g_iRespawnTimer[client] = INVALID_HANDLE;
	
	if(m_iHealth > 35 && m_iHealth != 1000)
	{
		SetEntProp(client, Prop_Data, "m_iHealth", 35);
	}
}

public Action:DeathClient(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(attacker > 0)
	{
		new i = GetClientUserId(attacker);

		if (IsClientInGame(attacker) && GetConVarBool(g_iActiveColorPar))
		{
                if (GetClientTeam(attacker) == 2)  { 
                    SetEntityRenderColor(attacker, 255, 0, 0, 255);  
                }  
     
                if (GetClientTeam(attacker) == 3)  { 
                    SetEntityRenderColor(attacker, 0, 255, 0, 120);  
                }  

	        g_iProtectTimer[attacker] = CreateTimer(1.3, EndProtect, i);		
		}
	}

	if(IsClientInGame(client) && GetConVarBool(g_iActiveKnifeDM))
	{
		if(g_bRemoveRadgoll)
		{
			new iEntity = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
			if (iEntity > MaxClients && IsValidEdict(iEntity))  CreateTimer(g_fRemoveRadgollDelay, f_Dissolve, iEntity, TIMER_FLAG_NO_MAPCHANGE);
		}
		Timer_Respawn[client] = CreateTimer(g_fRespawnDelay, f_Respawn, client);
	}		
}

public Action:EndProtect(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	
	if(client > 0 && GetConVarBool(g_iActiveColorPar))
	{
		SetPlayerColor(client, 255, 255, 255, 255);
	}
}

public PlayerTeam(Handle:event, const String:name[], bool:silent)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	ClientTeam[client] = GetClientTeam(client);
	
	if (GetEventInt(event, "team") > 1)
	{
		if(Timer_Respawn[client] == INVALID_HANDLE) Timer_Respawn[client] = CreateTimer(g_fRespawnDelay, f_Respawn, client);
	}
	else KillTimerS(client);
}


//============================================================================//


public OnClientPostAdminCheck(client)
{
	g_AFKwarnings[client] = 0;
	g_iCheckAfkTimer[client] = CreateTimer(15.0, g_iCheckAfkTimer_CallBack, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	if(GetConVarBool(g_iActiveBlockTolp))
	{
		SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
	}
}

public Action:g_iCheckAfkTimer_CallBack(Handle:timer, any:client)
{
	if (!IsClientInGame(client))
	{
		g_iCheckAfkTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	if (!IsPlayerAlive(client))
	{
		g_AFKwarnings[client] = 0;
		return Plugin_Continue;
	}

	decl Float:x_vec[3]; 
	GetClientAbsOrigin(client, x_vec);
	
	if (x_vec[0] == g_iAfkStartPositions[client][0] && x_vec[1] == g_iAfkStartPositions[client][1])
	{
		if(++g_AFKwarnings[client] > 2)
		{
			g_iCheckAfkTimer[client] = INVALID_HANDLE; 
			ChangeClientTeam(client, 1);
			return Plugin_Stop;
		}

		else if(g_AFKwarnings[client] == 2)
		{
			PrintCenterText(client, "[KNIFE MANAGEMENT] Play or will be spectator!");
			EmitSoundToClient(client, Antiparavoz_sound);
		}
	}
	else
	{
		g_iAfkStartPositions[client][0] = x_vec[0];
		g_iAfkStartPositions[client][1] = x_vec[1];
		g_AFKwarnings[client] = 0;
	}

	return Plugin_Continue;
}

/*//============================================================================//
Check Rates
*///============================================================================//

public Action:CheckManyRates(client, args)
{
	if(client > 0)
	{
		g_LastItem[client] = 0;
		PlayersMenu(client);
	}
	return Plugin_Handled;
}

PlayersMenu(client)
{
	new Handle:menu = CreateMenu(PlayersMenu_CallBack);
	SetMenuTitle(menu, "Knife Management | Select Player\n \n");
	decl String:str_id[15], String:str_nick[32];
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			IntToString(GetClientUserId(i), str_id, 15);
			str_nick[0] = '\0';
			GetClientName(i, str_nick, 32);
			AddMenuItem(menu, str_id, str_nick, ITEMDRAW_DEFAULT);
		}
	}
	DisplayMenuAtItem(menu, client, g_LastItem[client], 0);
}

public PlayersMenu_CallBack(Handle:menu, MenuAction:action, client, item)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
		return;
	}

	if (action != MenuAction_Select)
		return;

	decl String:str_id[15];
	if (!GetMenuItem(menu, item, str_id, 15))
		return;

	g_TargetId[client] = StringToInt(str_id);
	new target = GetClientOfUserId(g_TargetId[client]);
	if (target < 1)
	{
		PlayersMenu(client);
		return;
	}

	g_LastItem[client] = GetMenuSelectionPosition();
	if (g_hPanel[client] != INVALID_HANDLE) CloseHandle(g_hPanel[client]);
	g_hPanel[client] = CreatePanel();
	
	decl String:title[65];
	Format(title, 65, "%N\n \n", target);
	SetPanelTitle(g_hPanel[client], title);
	
	new id = GetClientUserId(client);
	for (new i = 0; i < 10; i++) 
	{
		QueryClientConVar(target, sClientVar[i], RateQueryFinished, id);
	}
}

public RateQueryFinished(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[], any:x)
{
	if (client > 0 && (x = GetClientOfUserId(x)) > 0 && client == GetClientOfUserId(g_TargetId[x]))
	{
		decl String:info[100];
		Format(info, 100, "%s: %s", cvarName, cvarValue);
		DrawPanelText(g_hPanel[x], info);
		SendPanelToClient(g_hPanel[x], x, Panel_CallBack, 0);
	}
}

public Panel_CallBack(Handle:panel, MenuAction:action, client, item)
{
	if (action == MenuAction_Select)
	{
		PlayersMenu(client);
	}
}

/*//============================================================================//
Check Scripts
*///============================================================================//

public Action:CheckManyScripts(client, args)
{
	if(client > 0)
	{
		g_LastItem[client] = 0;
		PlayersMenuScripts(client);
	}
	return Plugin_Handled;
}

PlayersMenuScripts(client)
{
	new Handle:menu = CreateMenu(PlayersMenuScripts_CallBack);
	SetMenuTitle(menu, "Knife Management | Follow Cheater?\n \n");
	decl String:str_id[15], String:str_nick[32];
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			IntToString(GetClientUserId(i), str_id, 15);
			str_nick[0] = '\0';
			GetClientName(i, str_nick, 32);
			AddMenuItem(menu, str_id, str_nick, ITEMDRAW_DEFAULT);
		}
	}
	DisplayMenuAtItem(menu, client, g_LastItem[client], 0);
}

public PlayersMenuScripts_CallBack(Handle:menu, MenuAction:action, client, item)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
		return;
	}

	if (action != MenuAction_Select)
		return;

	decl String:str_id[15];
	if (!GetMenuItem(menu, item, str_id, 15))
		return;

	g_TargetId[client] = StringToInt(str_id);
	new target = GetClientOfUserId(g_TargetId[client]);
	if (target < 1)
	{
		PlayersMenu(client);
		return;
	}

	g_LastItem[client] = GetMenuSelectionPosition();
	if (g_hPanelScripts[client] != INVALID_HANDLE) CloseHandle(g_hPanelScripts[client]);
	g_hPanelScripts[client] = CreatePanel();
	decl String:title[65];
	Format(title, 65, "%N\n \n", target);
	SetPanelTitle(g_hPanelScripts[client], title);
	new id = GetClientUserId(client);
	for (new i = 0; i < 10; i++) QueryClientConVar(target, sClientVar[i], RateQueryFinishedScripts, id);
}

public RateQueryFinishedScripts(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[], any:x)
{
	if (client > 0 && (x = GetClientOfUserId(x)) > 0 && client == GetClientOfUserId(g_TargetId[x]))
	{
		decl String:info[100];
		Format(info, 100, "%s: %s", cvarName, cvarValue);
		DrawPanelText(g_hPanelScripts[x], info);
		SendPanelToClient(g_hPanelScripts[x], x, PanelScripts_CallBack, 0);
	}
}

public PanelScripts_CallBack(Handle:panel, MenuAction:action, client, item)
{
	if (action == MenuAction_Select)
	{
		PlayersMenuScripts(client);
	}
}

/*//============================================================================//
KnifeBot Detector (XS plugin)
*///============================================================================//

public Action:Knifebot(admin, args)
{
	ShowPlayers(admin);
	return Plugin_Handled;
}

stock ShowPlayers(admin, item = 0)
{
	new Handle:menu = CreateMenu(menu_CallBack);
	SetMenuTitle(menu, "Knife Management | Check for KnifeBot:\n \n");
	SetMenuExitBackButton(menu, true);
	decl String:str_id[15], String:str_nick[32];
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			IntToString(GetClientUserId(i), str_id, 15);
			str_nick[0] = '\0';
			GetClientName(i, str_nick, 32);
			AddMenuItem(menu, str_id, str_nick, i != admin ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		}
	}
	DisplayMenuAtItem(menu, admin, item, 0);
}

public menu_CallBack(Handle:menu, MenuAction:action, admin, item)
{
	if (action == MenuAction_End)
		CloseHandle(menu);

	else if (action == MenuAction_Cancel && item == MenuCancel_ExitBack)
	{
		new Handle:hAdminMenu = GetAdminTopMenu();
		if (hAdminMenu != INVALID_HANDLE) DisplayTopMenu(hAdminMenu, admin, TopMenuPosition_LastCategory);
	}

	else if (action == MenuAction_Select)
	{
		if (g_hTimer[admin] == INVALID_HANDLE)
		{
			decl String:str_id[15];
			if (!GetMenuItem(menu, item, str_id, 15))
				return;

			new target = GetClientOfUserId(StringToInt(str_id));
			ID = target;
			if (target > 0 && IsPlayerAlive(admin) && IsPlayerAlive(target))
			{
				SetEntProp(admin,  Prop_Data, "m_CollisionGroup", 2);
				SetEntProp(target, Prop_Data, "m_CollisionGroup", 2);
				SetColor(admin, 255, 255, 255, 0);
				decl Float:pos[3];
				GetClientAbsOrigin(target, pos);
				GetClientAbsOrigin(admin, AdminOldPos[admin]);
				
				SetEntProp(ID, Prop_Data, "m_iHealth", 1000);
				
				TeleportEntity(admin, pos, NULL_VECTOR, NULL_VECTOR);
				g_hTimer[admin] = CreateTimer(0.1, g_hTimer_CallBack, admin);
			}
			else
			{
				PrintCenterText(admin, "You and Objective must to be alive");
			}
		}
		
		ShowPlayers(admin, GetMenuSelectionPosition());
	}
}

public Action:g_hTimer_CallBack(Handle:timer, any:admin)
{
	g_hTimer[admin] = INVALID_HANDLE;
	
	if (IsClientInGame(admin))
	{
		SetColor(admin, 255, 255, 255, 255);
		if (IsPlayerAlive(admin))
		{
			PrintCenterText(admin, "Knifebot Not Found");
			
		
			SetEntProp(ID, Prop_Data, "m_iHealth", 35);
			
			TeleportEntity(admin, AdminOldPos[admin], NULL_VECTOR, NULL_VECTOR);
		}
		else
			PrintCenterText(admin, "Knifebot detected!");
	}
	return Plugin_Stop;
}

/*//============================================================================//
Knife DeathMatch by raizo
*///============================================================================//

public Action:ProtectTimer_CallBack(Handle:timer, any:iClient)
{
	if (IsClientInGame(iClient) && IsPlayerAlive(iClient) && GetConVarBool(g_iActiveKnifeDM))
	{
		SetEntProp(iClient, Prop_Data, "m_takedamage", 2);
		SetPlayerColor(iClient, 255, 255, 255, 255);
	}
	Timer_Protect[iClient] = INVALID_HANDLE;
	
	return Plugin_Stop;
}

public Action:f_Dissolve(Handle:hTimer, any:iEntity)  
{  
	if(GetConVarBool(g_iActiveKnifeDM))
	{
	if(!IsValidEdict(iEntity))
	{
		return;
	}

	decl String:sName[32];
	Format(sName, sizeof(sName), "target_%d", iEntity);
	new iDissolve = CreateEntityByName("env_entity_dissolver");
	
	if(iDissolve > 0)
	{  
        DispatchKeyValue(iEntity, "targetname", sName);
        DispatchKeyValue(iDissolve, "dissolvetype", "3");
        DispatchKeyValue(iDissolve, "target", sName);
        AcceptEntityInput(iDissolve, "Dissolve");
        AcceptEntityInput(iDissolve, "kill");
	}
	else 
	{
		AcceptEntityInput(iEntity, "Kill");
	}
	}
} 

public Action:f_Respawn(Handle:timer, any:iClient)
{
	if (iClient > 0 && IsClientInGame(iClient) && !IsPlayerAlive(iClient) && GetConVarBool(g_iActiveKnifeDM)) 
	{
		CS_RespawnPlayer(iClient);
	}
	
	Timer_Respawn[iClient] = INVALID_HANDLE;
}

/*//============================================================================//
End
*///============================================================================//

stock SetColor(entity, r, g, b, a)
{
	SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
	SetEntityRenderColor(entity, r, g, b, a);
}

public OnClientDisconnect(client)
{
	KillTimerS(client);
	SDKUnhook(client, SDKHook_PostThinkPost, OnPostThinkPost);
	
	if (g_iCheckAfkTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_iCheckAfkTimer[client]);
		g_iCheckAfkTimer[client] = INVALID_HANDLE;
	}
}

KillTimerS(client)
{
	if (Timer_Respawn[client] != INVALID_HANDLE)
	{
		KillTimer(Timer_Respawn[client]);
		Timer_Respawn[client] = INVALID_HANDLE;
	}
	
	if (Timer_Protect[client] != INVALID_HANDLE)
	{
		KillTimer(Timer_Protect[client]);
		Timer_Protect[client] = INVALID_HANDLE;
	}
}