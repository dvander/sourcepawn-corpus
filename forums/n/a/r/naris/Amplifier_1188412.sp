#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <colors>

#tryinclude "ztf2grab"

#define MP 33
#define ME 2048

#define PLUGIN_VERSION "2.1"

new g_BeamSprite;
new g_HaloSprite;

new bool:UseAmplifier[MP]=false;
new bool:DontAsk[MP]=false;
new bool:NearAmplifier[MP]=false;
new bool:AmplifierOn[ME]=false;
new bool:AmplifierSapped[ME]=false;
new bool:ConditionApplied[ME][MP];
new Float:AmplifierDistance[ME];
new TFCond:AmplifierCondition[ME];
new AmplifierPercent[ME];
new AmplifierRef[ME];
new EngiAssists[MP]=0;
new GetPar[MP];

new Handle:cvarMetal = INVALID_HANDLE;
new Handle:cvarMetalMax = INVALID_HANDLE;
new Handle:cvarRegeneration = INVALID_HANDLE;
new Handle:cvarDistance = INVALID_HANDLE;
new Handle:cvarCondition = INVALID_HANDLE;
new Handle:cvarParticle = INVALID_HANDLE;
new Handle:cvarPercent = INVALID_HANDLE;

new Handle:fwdOnAmplify = INVALID_HANDLE;

new TFCond:DefaultCondition = TFCond_Kritzkrieged;
new Float:DefaultDistance = 200.0;
new bool:ShowParticle = true;
new DefaultPercent = 100;

new MetalRegeneration = 10;
new MetalPerPlayer = 5;
new MetalMax = 400;

new bool:NativeControl = false;
new TFCond:NativeCondition[MP];
new Float:NativeDistance[MP];
new NativePercent[MP];

#define AmplifierModel "models/buildables/amplifier_test/amplifier"
#define AMPgib "models/buildables/amplifier_test/gibs/amp_gib"

public Plugin:myinfo = {
	name = "The Amplifier",
	author = "Eggman",
	description = "Add The Amplifier (crit dispenser)",
	version = PLUGIN_VERSION,
};

/**
 * Description: Stocks to return information about TF2 player condition, etc.
 */
#tryinclude <tf2_player>
#if !defined _tf2_player_included
    enum TFPlayerCond (<<= 1)
    {
        TFPlayerCond_None = 0,
        TFPlayerCond_Slowed,
        TFPlayerCond_Zoomed,
        TFPlayerCond_Disguising,
        TFPlayerCond_Disguised,
        TFPlayerCond_Cloaked,
        TFPlayerCond_Ubercharged,
        TFPlayerCond_TeleportedGlow,
        TFPlayerCond_Taunting,
        TFPlayerCond_UberchargeFading,
        TFPlayerCond_Unknown1,
        TFPlayerCond_Teleporting,
        TFPlayerCond_Kritzkrieged,
        TFPlayerCond_Unknown2,
        TFPlayerCond_DeadRingered,
        TFPlayerCond_Bonked,
        TFPlayerCond_Dazed,
        TFPlayerCond_Buffed,
        TFPlayerCond_Charging,
        TFPlayerCond_DemoBuff,
	TFPlayerCond_CritCola,
        TFPlayerCond_Healing,
        TFPlayerCond_OnFire,
        TFPlayerCond_Overhealed,
        TFPlayerCond_Jarated
    };

    #define TF2_IsDisguised(%1)         (((%1) & TFPlayerCond_Disguised) != TFPlayerCond_None)
    #define TF2_IsCloaked(%1)           (((%1) & TFPlayerCond_Cloaked) != TFPlayerCond_None)

    stock TFPlayerCond:TF2_GetPlayerCond(client)
    {
        return TFPlayerCond:GetEntProp(client, Prop_Send, "m_nPlayerCond");
    }
#endif

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	// Register Natives
	CreateNative("ControlAmplifier",Native_ControlAmplifier);
	CreateNative("SetAmplifier",Native_SetAmplifier);
	CreateNative("HasAmplifier",Native_HasAmplifier);
	CreateNative("ConvertToAmplifier",Native_ConvertToAmplifier);

	fwdOnAmplify=CreateGlobalForward("OnAmplify",ET_Hook,Param_Cell,Param_Cell,Param_Cell);

	RegPluginLibrary("Amplifier");
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar("amplifier_version", PLUGIN_VERSION, "The Amplifier Version", FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarParticle = CreateConVar("amplifier_particle", "1", "Enable the Buffed Particle.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarCondition = CreateConVar("amplifier_condition", "16", "Condition that The amplifier dispenses (11=full crits, 16=mini crits, etc...).", FCVAR_PLUGIN, true, 0.0, true, 22.0);
	cvarPercent = CreateConVar("amplifier_percent", "100.0", "Percent chance of the amplifier applying the condition.", FCVAR_PLUGIN, true, 0.0, true, 100.0);
	cvarDistance = CreateConVar("amplifier_distance", "200.0", "Distance the amplifier works.", FCVAR_PLUGIN);
	cvarRegeneration = CreateConVar("amplifier_regeneration", "10.0", "Amount of metal to regenerate per second.", FCVAR_PLUGIN);
	cvarMetalMax = CreateConVar("amplifier_max", "400.0", "Maximum amount of metal an amplifier can hold.", FCVAR_PLUGIN);
	cvarMetal = CreateConVar("amplifier_metal", "5.0", "Amount of metal to use to apply a condition to a player (per second).", FCVAR_PLUGIN);

	HookEvent("player_builtobject", Event_Build);
	CreateTimer(1.0, Timer_amplifier, _, TIMER_REPEAT);
	//HookEvent("teamplay_round_start", event_RoundStart);
	HookEvent("player_spawn", Event_player_spawn);
	//HookEntityOutput("obj_dispenser", "OnObjectHealthChanged", objectHealthChanged);
	RegConsoleCmd("amplifier",        CallPanel, "Select 2nd engineer's building ");
	RegConsoleCmd("amp",        CallPanel, "Select 2nd engineer's building ");
	RegConsoleCmd("amp_help",        HelpPanel, "Show info Amplifier");
	AddToDownload();
	LoadTranslations("Amplifier");
	HookEvent("player_death", event_player_death);

	HookConVarChange(cvarRegeneration, CvarChange);
	HookConVarChange(cvarCondition, CvarChange);
	HookConVarChange(cvarParticle, CvarChange);
	HookConVarChange(cvarDistance, CvarChange);
	HookConVarChange(cvarMetalMax, CvarChange);
	HookConVarChange(cvarPercent, CvarChange);
	HookConVarChange(cvarMetal, CvarChange);
}

public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == cvarMetal)
        	MetalPerPlayer = StringToInt(newValue);
	else if (convar == cvarMetalMax)
        	MetalMax = StringToInt(newValue);
	else if (convar == cvarRegeneration)
        	MetalRegeneration = StringToInt(newValue);
	else if (convar == cvarDistance)
        	DefaultDistance = StringToFloat(newValue);
	else if (convar == cvarCondition)
        	DefaultCondition = TFCond:StringToInt(newValue);
	else if (convar == cvarParticle)
        	ShowParticle = bool:StringToInt(newValue);
	else if (convar == cvarPercent)
        	DefaultPercent = StringToInt(newValue);
}

public OnConfigsExecuted()
{
	DefaultCondition = TFCond:GetConVarInt(cvarCondition);
	DefaultDistance = GetConVarFloat(cvarDistance);
	DefaultPercent = GetConVarInt(cvarPercent);
	ShowParticle = bool:GetConVarInt(cvarParticle);

	MetalRegeneration = GetConVarInt(cvarRegeneration);
	MetalPerPlayer = GetConVarInt(cvarMetal);
	MetalMax = GetConVarInt(cvarMetalMax);
}

public OnMapStart()
{
	new String:strLine[256];
	Format(strLine,256,"%s.mdl",AmplifierModel);
	PrecacheModel(strLine, true);
	PrecacheModel(strLine, false);
	for (new i=1; i <=8; i++)
	{
		Format(strLine,256,"%s%i.mdl",AMPgib, i);
		PrecacheModel(strLine, true);
		PrecacheModel(strLine, false);
	}
	g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	AddToDownload();

	if (!NativeControl)
		CreateTimer(250.0, Timer_Announce, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public OnClientAuthorized(client, const String:auth[])
{
	UseAmplifier[client]=false;
	DontAsk[client]=false;
}

public Action:Timer_Announce(Handle:hTimer)
{
	CPrintToChatAll("%t", "AmplifierM");
	CPrintToChatAll("%t", "AmplifierN");

	return Plugin_Continue;
}

public AddToDownload()
{
	new String:strLine[256];
	new String:extensions[][] = {".mdl", ".dx80.vtx", ".dx90.vtx", ".sw.vtx", ".vvd", ".phy"};
	new String:extensionsb[][] = {".vtf", ".vmt"};
	for (new i=0; i < sizeof(extensions); i++)
	{
		Format(strLine,256,"%s%s",AmplifierModel,extensions[i]);
		AddFileToDownloadsTable(strLine);
		for (new j=1; j <=8; j++)
		{
			Format(strLine,256,"%s%i%s",AMPgib,j,extensions[i]);
			AddFileToDownloadsTable(strLine);
		}
	}
	for (new i=0; i < sizeof(extensionsb); i++)
	{
		Format(strLine,256,"materials/%s%s",AmplifierModel,extensionsb[i]);
		AddFileToDownloadsTable(strLine);
		Format(strLine,256,"materials/%s_blue%s",AmplifierModel,extensionsb[i]);
		AddFileToDownloadsTable(strLine);
		Format(strLine,256,"materials/%s_anim%s",AmplifierModel,extensionsb[i]);
		AddFileToDownloadsTable(strLine);
		Format(strLine,256,"materials/%s_anim_blue%s",AmplifierModel,extensionsb[i]);
		AddFileToDownloadsTable(strLine);
		Format(strLine,256,"materials/%s_anim2%s",AmplifierModel,extensionsb[i]);
		AddFileToDownloadsTable(strLine);
		Format(strLine,256,"materials/%s_anim2_blue%s",AmplifierModel,extensionsb[i]);
		AddFileToDownloadsTable(strLine);
		Format(strLine,256,"materials/%s_holo%s",AmplifierModel,extensionsb[i]);
		AddFileToDownloadsTable(strLine);
		Format(strLine,256,"materials/%s_bolt%s",AmplifierModel,extensionsb[i]);
		AddFileToDownloadsTable(strLine);
		Format(strLine,256,"materials/%s_holo_blue%s",AmplifierModel,extensionsb[i]);
		AddFileToDownloadsTable(strLine);
		Format(strLine,256,"materials/%s_radar%s",AmplifierModel,extensionsb[i]);
		AddFileToDownloadsTable(strLine);
	}
	Format(strLine,256,"%s.mdl",AmplifierModel);
	PrecacheModel(strLine, true);
	PrecacheModel(strLine, false);
	for (new i=1; i <=8; i++)
	{
		Format(strLine,256,"%s%i.mdl",AMPgib,i);
		PrecacheModel(strLine, true);
		PrecacheModel(strLine, false);
	}
}

//Clean all Amplifiers' Data
/*
public Action:event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i=1;i<GetClientCount();i++)
	{
		AmplifierEnt[i]=0;
		for(new j=0;j<3;j++) 
			AmplifierPos[j][i]=0.0;
	}
	return Plugin_Continue;
}

public objectHealthChanged(const String:output[], caller, activator, Float:delay)
{
	for (new i=1;i<MP;i++)
	if ((EntRefToEntIndex(AmplifierEnt[i])==caller) && UseAmplifier[i])
	{
		new String:s[256];
		Format(s,256,"%s%s",AmplifierModel,".mdl"); 
		SetEntityModel(caller,s);
		break;
	}
	return Plugin_Continue;
}
*/

//Show Panel to Engineer on spawn.
public Action:Event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!NativeControl)
	{
		new client=GetClientOfUserId(GetEventInt(event, "userid"));
		if (!DontAsk[client])
			AmpPanel(client);		
	}
	return Plugin_Continue;
}

public AmpHelpPanelH(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
		return;   
}
  
public Action:HelpPanel(client, Args)
{
	new Handle:panel = CreatePanel();
	new String:s[256];
	Format(s,256,"%t","Amplifier1");
	SetPanelTitle(panel, s);
	Format(s,256,"%t","Amplifier2");
	DrawPanelText(panel, s);
	Format(s,256,"%t","Amplifier3");
	DrawPanelText(panel, s);
	Format(s,256,"%t","Amplifier4");
	DrawPanelText(panel, s);
	Format(s,256,"%t","Amplifier5");
	DrawPanelText(panel, s);
	DrawPanelItem(panel, "Close Menu");  
	SendPanelToClient(panel, client, AmpHelpPanelH, 16);
	CloseHandle(panel);
}

//Show Panel to Enginner on command
public Action:CallPanel(client, Args)
{
	if (!NativeControl)
		AmpPanel(client);

	return Plugin_Continue;
}

//Panel's procedure
public AmpPanel(client)
{		
	if (NativeControl || TF2_GetPlayerClass(client) != TFClass_Engineer)
		return;// Plugin_Continue;
		
	new Handle:panel = CreatePanel();
	new String:str[256];
	Format(str,256,"%t","AmplifierA");
	//str="Selct your 2nd building";
	SetPanelTitle(panel, str);
	
	Format(str,256,"%t","AmplifierB");
	//str="Dispenser";
	DrawPanelItem(panel, str);
	
	Format(str,256,"%t","AmplifierC");
	//str="Amplifier";
	DrawPanelItem(panel, str); 
	
	Format(str,256,"%t","AmplifierD");
	//str="Dispenser, don't ask me again";
	DrawPanelItem(panel, str); 
	
	Format(str,256,"%t","AmplifierE");
	//str="Amplifier, don't ask me again";
	DrawPanelItem(panel, str); 
	
	SendPanelToClient(panel, client, AmpPanelH, 20);
	CloseHandle(panel); 
	//return Plugin_Continue;	
}

//Panel's Handle Procedure
public AmpPanelH(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 1:
			{
				UseAmplifier[param1]=false;
				DontAsk[param1]=false;
			}
			case 2:
			{
				UseAmplifier[param1]=true;
				DontAsk[param1]=false;
			}
			case 3:
			{
				UseAmplifier[param1]=false;
				DontAsk[param1]=true;
				CPrintToChat(param1,"%t", "AmplifierM");
			}
			case 4:
			{
				UseAmplifier[param1]=true;
				DontAsk[param1]=true;
				CPrintToChat(param1,"%t", "AmplifierM");
			}
		}
	}
}

//Main timer:
//--Detect players near (or not) Amplifiers.
//--Spawn (Remove) crit effects on players. 
//--Disable Amplifiers when they dying
//--WAVES
public Action:Timer_amplifier(Handle:hTimer)
{
	new Float:Pos[3];
	new Float:AmplifierPos[3];
	new TFTeam:clientTeam;
	new TFTeam:team;
	new i,client;
	new maxEntities = GetMaxEntities();
	for(client=1;client<=MaxClients;client++)
	{
		if (IsClientInGame(client)) 
		{
			NearAmplifier[client]=false;
			if (IsPlayerAlive(client) && IsValidEdict(client)) 
			{
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", Pos);  //Get player's position
				clientTeam=TFTeam:GetClientTeam(client);

				for(i=1;i<maxEntities;i++) //See all Amplifiers
				{
					//If Amplifier Exist, Active and not sapped
					new amp = EntRefToEntIndex(AmplifierRef[i]);
					if (amp > 0 && AmplifierOn[amp] && !AmplifierSapped[amp])
					{
						// Check Metal
						new metal = GetEntProp(amp, Prop_Send, "m_iAmmoMetal");
						if (metal < MetalPerPlayer && MetalPerPlayer > 0)
							continue;

						// Check Percent Chance
						new percent = AmplifierPercent[amp];
						if (percent < 100 && (ConditionApplied[amp][client] || GetRandomInt(1,100) > percent))
							continue;

						new bool:enableParticle;
						new TFCond:Condition = AmplifierCondition[amp];
						switch (Condition)
						{
							case TFCond_Ubercharged, TFCond_Kritzkrieged, TFCond_Buffed,
							     TFCond_DemoBuff, TFCond_Charging:
							{
								enableParticle = (Condition != TFCond_Buffed) && ShowParticle;
								team = TFTeam:GetEntProp(amp, Prop_Send, "m_iTeamNum");
							}
							case TFCond_Slowed, TFCond_Zoomed, TFCond_TeleportedGlow, TFCond_Taunting,
							     TFCond_Bonked, TFCond_Dazed, TFCond_OnFire, TFCond_Jarated,
							     TFCond_Disguised, TFCond_Cloaked:
							{
								enableParticle = false;
								team = (TFTeam:GetEntProp(amp, Prop_Send, "m_iTeamNum") == TFTeam_Red)
									? TFTeam_Blue : TFTeam_Red;
							}
							default:
							{
								enableParticle = false;
								team = TFTeam:GetEntProp(amp, Prop_Send, "m_iTeamNum");
							}
						}

						//Spy can use enemies' Amplifier
						new TFPlayerCond:pcond = TF2_GetPlayerCond(client);
						if ((TF2_GetPlayerClass(client) == TFClass_Spy) &&
						    TF2_IsDisguised(pcond) && !TF2_IsCloaked(pcond))
						{
							team=clientTeam;
						}
							
						//Brootforse heal bug fix
						if (GetEntProp(amp, Prop_Send, "m_bDisabled")==0)
							SetEntProp(amp, Prop_Send, "m_bDisabled", 1);
						
						GetEntPropVector(amp, Prop_Send, "m_vecOrigin", AmplifierPos);

						if (clientTeam==team &&
						    GetVectorDistance(Pos,AmplifierPos) <= AmplifierDistance[amp] &&
						    TraceTargetIndex(amp, client, AmplifierPos, Pos))
						{
							new Action:res = Plugin_Continue;
							new builder = GetEntPropEnt(amp, Prop_Send, "m_hBuilder");

							Call_StartForward(fwdOnAmplify);
							Call_PushCell(builder);
							Call_PushCell(client);
							Call_PushCell(Condition);
							Call_Finish(res);

							if (res != Plugin_Continue)
								continue;

							//If player in Amplifier's distance and on Amplifier's team
							if (enableParticle)
							{
								//If Crit Effect does NOT Exist
								new particle = EntRefToEntIndex(GetPar[client]);
								if (particle==0 || !IsValidEntity(particle))
								{
									//Create Buffed Effect
									if (team==TFTeam_Red)
										AttachParticle(client,"soldierbuff_red_buffed",particle);
									else
										AttachParticle(client,"soldierbuff_blue_buffed",particle);
									GetPar[client] = EntIndexToEntRef(particle);
								}
							}

							//Set condition to player
							if (Condition == TFCond_OnFire)
							{
								if (builder > 0)
									TF2_IgnitePlayer(client, builder);
							}
							else if (Condition == TFCond_Taunting)
								FakeClientCommand(client, "taunt");
							else if (Condition == TFCond_Disguised || Condition == TFCond_Cloaked)
								TF2_RemoveCondition(client, Condition);
							else
								TF2_AddCondition(client, Condition, 1.0);

							ConditionApplied[amp][client]=true;
							NearAmplifier[client]=true;

							if (MetalPerPlayer > 0)
							{
								metal -= MetalPerPlayer;
								SetEntProp(amp, Prop_Send, "m_iAmmoMetal", metal);
							}
							break;
						} 
					}

					// Only remove conditions that were set by the amplifier
					if (amp > 0 && !NearAmplifier[client] && ConditionApplied[amp][client])
					{
						ConditionApplied[amp][client]=false;
						TF2_RemoveCondition(client, AmplifierCondition[amp]);
					}
				}
			}

			//if Amplifiers on distance not found or client is dead
			if ((i==maxEntities) || !IsPlayerAlive(client))
			{
				//if player has crit effect - delete it
				new particle = EntRefToEntIndex(GetPar[client]);
				if (particle != 0 && IsValidEntity(particle))
				{
					RemoveEdict(particle);
				}
				GetPar[client]=0;
			}
		}
	}

	//Amplifier's waves
	for(i=1;i<maxEntities;i++)
	{
		new ref = AmplifierRef[i];
		if (ref != 0)
		{
			new ent = EntRefToEntIndex(ref);
			if (ent > 0)
			{
				if (AmplifierOn[ent] && !AmplifierSapped[ent])
				{
					new metal;
					if (MetalRegeneration > 0 || MetalPerPlayer > 0)
					{
						metal = GetEntProp(ent, Prop_Send, "m_iAmmoMetal") + MetalRegeneration;
						if (metal <= MetalMax)
							SetEntProp(ent, Prop_Send, "m_iAmmoMetal", metal);

						if (metal < MetalPerPlayer)
							continue;
					}
					else
						metal = 255;

					new beamColor[4];
					switch (AmplifierCondition[ent])
					{
						case TFCond_Slowed, TFCond_Zoomed, TFCond_TeleportedGlow, TFCond_Taunting,
						     TFCond_Bonked, TFCond_Dazed, TFCond_OnFire, TFCond_Jarated,
						     TFCond_Disguised, TFCond_Cloaked:
						{
							beamColor = {255, 255, 75, 255}; // Yellow
						}
						//case TFCond_Ubercharged, TFCond_Kritzkrieged, TFCond_Buffed,
						//     TFCond_DemoBuff, TFCond_Charging:
						default:
						{
							if (TFTeam:GetEntProp(ent, Prop_Send, "m_iTeamNum")==TFTeam_Red)
								beamColor = {255, 75, 75, 255}; // Red
							else
								beamColor = {75, 75, 255, 255}; // Blue
						}
					}

					if (metal < 255)
						beamColor[3] = metal;

					GetEntPropVector(ent, Prop_Send, "m_vecOrigin", Pos);
					Pos[2]+=90;

					TE_SetupBeamRingPoint(Pos, 10.0, AmplifierDistance[ent]+100.1, g_BeamSprite, g_HaloSprite,
							      0, 15, 3.0, 5.0, 0.0, beamColor, 3, 0);
					TE_SendToAll();		
				}
			}
			else
			{
				// The amplifier is no longer valid (was destroyed)
				AmplifierRef[i] = 0;

				// Remove any lingering conditions
				for(client=1;client<=MaxClients;client++)
				{
					if (ConditionApplied[i][client])
					{
						ConditionApplied[i][client]=false;
						if (IsClientInGame(client) && IsPlayerAlive(client)) 
							TF2_RemoveCondition(client, AmplifierCondition[i]);
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

//Add scores for engi for assist by Amplifier
public Action:event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	//new Float:Pos[3];
	//new Float:AmplifierPos[3];
	new Victim = GetClientOfUserId(GetEventInt(event,"userid"));
	new Attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (NearAmplifier[Attacker] || NearAmplifier[Victim])
	{
		new maxEntities = GetMaxEntities();
		for(new i=1;i<maxEntities;i++)
		{
			new ent = EntRefToEntIndex(AmplifierRef[i]);
			if (ent > 0 && AmplifierOn[ent] && !AmplifierSapped[ent] && (Attacker!=i))
			{
				//GetEntPropVector(Attacker, Prop_Send, "m_vecOrigin", Pos);
				//GetEntPropVector(ent, Prop_Send, "m_vecOrigin", AmplifierPos);
				//if (GetVectorDistance(Pos,AmplifierPos)<=AmplifierDistance[ent])
				new bool:assist;
				switch (AmplifierCondition[ent])
				{
					case TFCond_Slowed, TFCond_Zoomed, TFCond_TeleportedGlow, TFCond_Taunting,
					     TFCond_Bonked, TFCond_Dazed, TFCond_OnFire, TFCond_Jarated:
					{
						assist = ConditionApplied[ent][Victim];
					}
					default:
						assist = ConditionApplied[ent][Attacker];
				}

				if (assist)
				{
					new builder = GetEntPropEnt(ent, Prop_Send, "m_hBuilder");
					if (builder > 0)
					{
						EngiAssists[builder]++;
						if (EngiAssists[builder]>=4)
						{
							new Handle:aevent = CreateEvent("player_escort_score", true) ;
							SetEventInt(aevent, "player", builder);
							SetEventInt(aevent, "points", 1);
							FireEvent(aevent);
							EngiAssists[builder]=0;
						}
					}
					break;
				}
			}
		}
	}
	return Plugin_Continue;
}


//Detect building
public Action:Event_Build(Handle:event, const String:name[], bool:dontBroadcast)
{
	new ent = GetEventInt(event, "index");
	CheckDisp(ent, GetClientOfUserId(GetEventInt(event, "userid")));
	CheckSapper(ent);
	return Plugin_Continue;
}

//if building is dispenser
CheckDisp(ent, Client)
{
	if (Client <= 0 || !UseAmplifier[Client]) //Don't create Amplifier if player don't want it
		return;// Plugin_Continue;

	new String:classname[64];
	GetEdictClassname(ent, classname, sizeof(classname));
	if (!strcmp(classname, "obj_dispenser"))
	{
		new Float:pos[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);    
		SetEntProp(ent, Prop_Send, "m_bDisabled", 1);
		AmplifierRef[ent]=EntIndexToEntRef(ent);
		AmplifierOn[ent]=false;
		AmplifierSapped[ent]=false;
		AmplifierPercent[ent]=NativeControl ? NativePercent[Client] : DefaultPercent;
		AmplifierDistance[ent]=NativeControl ? NativeDistance[Client] : DefaultDistance;
		AmplifierCondition[ent]=NativeControl ? NativeCondition[Client] : DefaultCondition;
		new String:s[128];
		Format(s,128,"%s%s",AmplifierModel,".mdl");
		SetEntityModel(ent,s);
		SetEntProp(ent, Prop_Send, "m_nSkin", GetEntProp(ent, Prop_Send, "m_nSkin")+2);
		CreateTimer(4.0, DispCheckStage1, EntIndexToEntRef(ent));
	}
	return;// Plugin_Continue;
}


//Wait 3 seconds before check model to change
public Action:DispCheckStage1(Handle:hTimer,any:ref)
{
	if (EntRefToEntIndex(ref) > 0)
		CreateTimer(0.1, DispCheckStage2, ref, TIMER_REPEAT);
	return Plugin_Continue;
}

//Change model if it's not Amplifier's model
public Action:DispCheckStage2(Handle:hTimer,any:ref)
{
	new ent = EntRefToEntIndex(ref);
	if (ent > 0 && IsValidEntity(ent))
	{
		new String:modelname[128];

		/*
		GetEntPropString(ent, Prop_Data, "m_ModelName", modelname, 128);
		if (StrContains(modelname,"dispenser")==-1)
			return Plugin_Continue;
		*/

		if (GetEntPropFloat(ent, Prop_Send, "m_flPercentageConstructed") < 1.0)
			return Plugin_Continue;

		AmplifierOn[ent]=true;
		Format(modelname,128,"%s%s",AmplifierModel,".mdl");
		SetEntityModel(ent,modelname);
		KillTimer(hTimer);
		SetEntProp(ent, Prop_Send, "m_iUpgradeLevel",3);
		SetEntProp(ent, Prop_Send, "m_nSkin", GetEntProp(ent, Prop_Send, "m_nSkin")-2);

		new particle;
		if (TFTeam:GetEntProp(ent, Prop_Send, "m_iTeamNum")==TFTeam_Red)
			AttachParticle(ent,"teleported_red",particle); //Create Effect of TP
		else
			AttachParticle(ent,"teleported_blue",particle); //Create Effect of TP
		CreateTimer(2.0, DispCheckStage1a, EntIndexToEntRef(particle));
	}
	return Plugin_Continue;
}

//Wait for kill teleport effect
public Action:DispCheckStage1a(Handle:hTimer,any:ref)
{
	new ent = EntRefToEntIndex(ref);
	if (ent > 0 && IsValidEntity(ent))
		RemoveEdict(ent);

	return Plugin_Continue;
}

//Spa suppin' mah Amplifier!!!!11
CheckSapper(ent)
{
	CreateTimer(0.5, SapperCheckStage1,EntIndexToEntRef(ent));	
	//return Plugin_Continue;
}

public Action:SapperCheckStage1(Handle:hTimer,any:ref)
{
	new ent = EntRefToEntIndex(ref);
	if (ent > 0 && IsValidEntity(ent))
	{
		new String:classname[64];
		GetEdictClassname(ent, classname, sizeof(classname));
		if (!strcmp(classname, "obj_attachment_sapper"))
		{
			new maxEntities = GetMaxEntities();
			for (new i=1;i<maxEntities;i++)
			{
				new ampref = AmplifierRef[i];
				new ampent = EntRefToEntIndex(ampref);
				if (ampent > 0)
				{
					if ((GetEntProp(ampent, Prop_Send, "m_bHasSapper")==1) && !AmplifierSapped[ampent])
					{
						AmplifierSapped[ampent]=true;
						CreateTimer(0.2, SapperCheckStage2,ampref,TIMER_REPEAT);
						break;
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:SapperCheckStage2(Handle:hTimer,any:ref)
{
	new ent = EntRefToEntIndex(ref);
	if (ent > 0 && IsValidEntity(ent))
	{
		if ((GetEntProp(ent, Prop_Send, "m_bHasSapper")==0) && AmplifierSapped[ent])
		{
			SetEntProp(ent, Prop_Send, "m_bDisabled", 1);
			AmplifierSapped[ent]=false;
			KillTimer(hTimer);
		}		
	}		
	return Plugin_Continue;
}

/* With COND extension i can kill this bugged function
//Generate 100% crit if player near Amplifier 
public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if (!NearAmplifier[client])
		return Plugin_Continue;
	else
	{
		result = true;	
		return Plugin_Handled;
	}
}
*/

//Create Crit Particle
AttachParticle(ent, String:particleType[],&particle)
{
	particle = CreateEntityByName("info_particle_system");
	
	new String:tName[128];
	new Float:pos[3];
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
	TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
	
	Format(tName, sizeof(tName), "target%i", ent);
	DispatchKeyValue(ent, "targetname", tName);
	
	DispatchKeyValue(particle, "targetname", "tf2particle");
	DispatchKeyValue(particle, "parentname", tName);
	DispatchKeyValue(particle, "effect_name", particleType);
	DispatchSpawn(particle);
	SetVariantString(tName);
	AcceptEntityInput(particle, "SetParent", particle, particle, 0);
	//SetVariantString("none");
	//AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0);
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");
}

stock CleanString(String:strBuffer[])
{
	// Cleanup any illegal characters
	new Length = strlen(strBuffer);
	for (new i=0; i<Length; i++)
	{
		switch(strBuffer[i])
		{
			case '\r': strBuffer[i] = ' ';
			case '\n': strBuffer[i] = ' ';
			case '\t': strBuffer[i] = ' ';
		}
	}

	// Trim string
	TrimString(strBuffer);
}

/**
 * Description: Native Interface
 */

public Native_ControlAmplifier(Handle:plugin,numParams)
{
	NativeControl = GetNativeCell(1);
}

public Native_SetAmplifier(Handle:plugin,numParams)
{
	new client = GetNativeCell(1);
	UseAmplifier[client] = bool:GetNativeCell(2);

	new Float:distance = Float:GetNativeCell(3);
	NativeDistance[client] = (distance < 0.0) ? DefaultDistance : distance;

	new TFCond:condition = TFCond:GetNativeCell(4);
	NativeCondition[client] = (condition < TFCond_Slowed) ? DefaultCondition : condition;

	new percent = GetNativeCell(5);
	NativePercent[client] = (distance < 0) ? DefaultPercent : percent;
}

public Native_HasAmplifier(Handle:plugin,numParams)
{
	new count = 0;
	new client = GetNativeCell(1);
	new maxEntities = GetMaxEntities();
	for (new i=1;i<maxEntities;i++)
	{
		new ampref = AmplifierRef[i];
		new ampent = EntRefToEntIndex(ampref);
		if (ampent > 0)
		{
			if (GetEntPropEnt(ampent, Prop_Send, "m_hBuilder") == client)
				count++;
		}
	}
	return count;
}

public Native_ConvertToAmplifier(Handle:plugin,numParams)
{
	new ent = GetNativeCell(1);
	if (ent > 0 && IsValidEntity(ent))
	{
		new client = GetNativeCell(2);
		new bool:save = UseAmplifier[client];
		new Float:saveDist = NativeDistance[client];
		new TFCond:saveCond = NativeCondition[client];
		new savePercent = NativePercent[client];

		new Float:distance = Float:GetNativeCell(3);
		if (distance >= 0.0)
			NativeDistance[client] = distance;

		new TFCond:condition = TFCond:GetNativeCell(4);
		if (condition >= TFCond_Slowed)
			NativeCondition[client] = condition;

		new percent = GetNativeCell(5);
		if (percent >= 0)
			NativePercent[client] =  percent;

		UseAmplifier[client] = true;
		CheckDisp(ent, client);

		NativeCondition[client] = saveCond;
		NativeDistance[client] = saveDist;
		NativePercent[client] = savePercent;
		UseAmplifier[client] = save;
	}
}

#if defined _ztf2grab_included
	public Action:OnPickupObject(client, builder, ent)
	{
	    if (AmplifierRef[ent] != 0 && EntRefToEntIndex(AmplifierRef[ent]) == ent)
	    {
		switch (AmplifierCondition[ent])
		{
			case TFCond_Ubercharged, TFCond_Kritzkrieged, TFCond_Buffed:
				return Plugin_Stop;
		}
	    }
	    return Plugin_Continue;
	}
#endif

/**
 * Description: Ray Trace functions and variables
 */
#tryinclude <raytrace>
#if !defined _raytrace_included
    stock bool:TraceTargetIndex(client, target, Float:clientLoc[3], Float:targetLoc[3])
    {
        targetLoc[2] += 50.0; // Adjust trace position of target
        TR_TraceRayFilter(clientLoc, targetLoc, MASK_SOLID,
                          RayType_EndPoint, TraceRayDontHitSelf,
                          client);

        return (!TR_DidHit() || TR_GetEntityIndex() == target);
    }

    /***************
     *Trace Filters*
    ****************/

    public bool:TraceRayDontHitSelf(entity, mask, any:data)
    {
        return (entity != data); // Check if the TraceRay hit the owning entity.
    }
#endif

